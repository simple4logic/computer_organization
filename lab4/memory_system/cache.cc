// ECE 430.322: Computer Organization
// Lab 4: Memory System Simulation

#include "cache.h"
#include <cassert>
#include <cmath>
#include <cstring>
#include <iostream>
#include <list>

cache_c::cache_c(std::string name, int level, int num_set, int assoc, int line_size, int latency)
    : cache_base_c(name, num_set, assoc, line_size)
{

    // instantiate queues
    m_in_queue = new queue_c();
    m_out_queue = new queue_c();
    m_fill_queue = new queue_c();
    m_wb_queue = new queue_c();

    m_in_flight_wb_queue = new queue_c();

    m_id = 0;

    m_prev_i = nullptr;
    m_prev_d = nullptr;
    m_next = nullptr;
    m_memory = nullptr;

    m_latency = latency;
    m_level = level;

    // clock cycle
    m_cycle = 0;

    m_num_backinvals = 0;
    m_num_writebacks_backinval = 0;
}

cache_c::~cache_c()
{
    delete m_in_queue;
    delete m_out_queue;
    delete m_fill_queue;
    delete m_wb_queue;
    delete m_in_flight_wb_queue;
}

/**
 * Run a cycle for cache (DO NOT CHANGE)
 */
void cache_c::run_a_cycle()
{
    // process the queues in the following order
    // wb -> fill -> out -> in
    process_wb_queue();
    process_fill_queue();
    process_out_queue();
    process_in_queue();

    ++m_cycle;
}

void cache_c::configure_neighbors(cache_c *prev_i, cache_c *prev_d, cache_c *next, simple_mem_c *memory)
{
    m_prev_i = prev_i;
    m_prev_d = prev_d;
    m_next = next;
    m_memory = memory;
}

/**
 *
 * [Cache Fill Flow]
 *
 * This function puts the memory request into fill_queue, so that the cache
 * line is to be filled or written-back.  When we fill or write-back the cache
 * line, it will take effect after the intrinsic cache latency.  Thus, this
 * function adjusts the ready cycle of the request; i.e., a new ready cycle
 * needs to be set for the request.
 *
 */
bool cache_c::fill(mem_req_s *req)
{
    req->m_rdy_cycle = m_cycle + m_latency;
    m_fill_queue->push(req);
    return true;
}

/**
 * [Cache Access Flow]
 *
 * This function puts the memory request into in_queue.  When accessing the
 * cache, the outcome (e.g., hit/miss) will be known after the intrinsic cache
 * latency.  Thus, this function adjusts the ready cycle of the request; i.e.,
 * a new ready cycle needs to be set for the request .
 */
bool cache_c::access(mem_req_s *req)
{
    // modified
    req->m_rdy_cycle = m_cycle + m_latency;
    m_in_queue->push(req);
    return true;
}

/**
 * This function processes the input queue.
 * What this function does are
 * 1. iterates the requests in the queue
 * 2. performs a cache lookup in the "cache base" after the intrinsic access time
 * 3. on a cache hit, forward the request to the prev's fill_queue or the processor depending on the cache level.
 * 4. on a cache miss, put the current requests into out_queue
 */
void cache_c::process_in_queue()
{
    // modified
    std::vector<mem_req_s *> to_remove;
    for (auto req : m_in_queue->m_entry) {
        if (req->m_rdy_cycle > m_cycle)
            continue; // not ready yet

        if (m_level == 1) {
            addr_t block_addr = req->m_addr / get_line_size();

            // check if current blk addr is in MSHR
            // count # of requests @ this address (block_addr)
            if (m_mshr.count(block_addr)) {
                // case 1 : in MSHR -> add to the waiting list (do not access cache)
                m_mshr[block_addr].push_back(req);
            }
            else {
                // case 2 : not in MSHR -> check cache hit or miss
                bool hit = cache_base_c::access(req->m_addr, req->m_type, /*is_fill=*/false);

                if (hit) {
                    // case 2-1 if hit, req done
                    done_func(req);
                }
                else {
                    // case 2-2 if miss, we need to fill the cache, make req
                    m_mshr[block_addr].push_back(req);
                    // send representative req to out_queue (will be sent to L2)
                    m_out_queue->push(req);
                }
            }
        }
        // m_level == 2
        else {
            int type = req->m_type;
            if (type == WRITE) {
                type = READ; // if req is write, change the type to read
            }

            bool hit = cache_base_c::access(req->m_addr, type, /*is_fill=*/false); // real access

            if (hit) {
                // if l2 hit, L2 -> L1I or L1D
                if (req->m_type == REQ_IFETCH) { // read instruction, To L1I
                    if (m_prev_i)
                        m_prev_i->fill(req);
                }
                else { // read or write To L1D
                    // though L2 access as read -> this write req will processed @ fill Q of L1D
                    if (m_prev_d)
                        m_prev_d->fill(req);
                }
            }
            else { // miss
                m_out_queue->push(req);
            }
        }

        to_remove.push_back(req);
    }
    // remove the requests which are processed
    for (auto req : to_remove) {
        m_in_queue->pop(req);
    }
}

/**
 * This function processes the output queue.
 * The function pops the requests from out_queue and accesses the next-level's cache or main memory.
 * CURRENT: There is no limit on the number of requests we can process in a cycle.
 */
void cache_c::process_out_queue()
{
    while (!m_out_queue->empty()) {
        mem_req_s *req = m_out_queue->m_entry.front();

        if (m_next) { // if next is L2
            if (req->m_type == REQ_WB) {
                m_next->fill(req); // L1 -> L2 fill, WB request
                m_in_flight_wb_queue->pop(req);
                // to manage wb req is in flight or not
                m_next->m_in_flight_wb_queue->push(req);
            }
            // if req is not write-back, access the next-level cache
            else {
                m_next->access(req);
            }
        }
        else if (m_memory) { // if next is memory
            if (req->m_type == REQ_WB) {
                m_memory->access(req); // L2 -> memory access, WB request
                m_in_flight_wb_queue->pop(req);
                // to manage wb req is in flight or not
                m_memory->m_in_flight_wb_queue->push(req);
            }
            // if req is not write-back, access the main memory
            else {
                m_memory->access(req);
            }
        }
        else {
            assert(false && "no next or memory");
        }
        m_out_queue->pop(req);
    }
}

/**
 * This function processes the fill queue.  The fill queue contains both the
 * data from the lower level and the dirty victim from the upper level.
 */

void cache_c::process_fill_queue()
{
    // modified
    // wait
    std::vector<mem_req_s *> to_remove;
    for (auto req : m_fill_queue->m_entry) {
        if (req->m_rdy_cycle > m_cycle)
            continue; // not ready yet

        // if this req is @ L1, we need to say that it is done
        if (m_level == 1) {
            /***  do filling cache for representative request ***/
            // when L1 get a block from L2 or mem
            cache_base_c::access(req->m_addr, req->m_type, /*is_fill=*/true);

            // issue writeback request
            if (is_evict && is_writeback) {
                mem_req_s *wb_req = new mem_req_s(evict_addr, REQ_WB);
                wb_req->m_in_cycle = req->m_in_cycle;
                m_in_flight_wb_queue->push(wb_req); // for wb tracking
                m_wb_queue->push(wb_req);           // push it to L1 wb queue
            }

            // process MSHR using this filling above
            addr_t block_addr = req->m_addr / get_line_size();
            if (m_mshr.count(block_addr)) {
                auto &waiting_reqs = m_mshr[block_addr];

                for (auto waiting_req : waiting_reqs) {
                    // these requests should be hit as their representative request is filled
                    if (waiting_req != req) {
                        // to skip the representative request
                        cache_base_c::access(waiting_req->m_addr, waiting_req->m_type, /*is_fill=*/false);
                    }
                    done_func(waiting_req);
                }
                // delete after done
                m_mshr.erase(block_addr);
            }
            // done_func(req);
        }

        else if (m_level == 2) {
            // request = REQ_WB from L1 or REQ_IFETCH/DFETCH/DSTORE from MEM

            // wb req from L1
            // will be done here -> pop from tracking list
            if (req->m_type == REQ_WB) {
                m_in_flight_wb_queue->pop(req);
            }

            int type = req->m_type;
            if (type == WRITE) { // only when REQ_DSTORE
                type = READ;     // if the request is a write, change the type to read
            }

            cache_base_c::access(req->m_addr, type, /*is_fill=*/true);

            /*
            About back invalidation & writeback
            L2 dirty -> when evict, put the block in L2 object's wb Q
            L2 evict sth -> check if backinval is needed
                if needed + dirty => writeback due to backinval
                1. L2$ already evicted the block
                2. therefore should be directed to memory
                -> put it to L2's wb queue
             */

            // do back invalidation
            if (is_evict) {
                // is evict true == that block should be invalidated
                // can miss (since L2 is bigger than L1)

                // when L2 evict & dirty -> wb to memory
                if (is_writeback) {
                    // when L2 evicts a block & it was dirty, we need to write it back to memory
                    mem_req_s *wb_req = new mem_req_s(evict_addr, REQ_WB);
                    wb_req->m_in_cycle = req->m_in_cycle;
                    m_in_flight_wb_queue->push(wb_req); // for wb tracking
                    m_wb_queue->push(wb_req);           // push it to L2 wb queue
                }

                // try back invalidation
                if (m_prev_i->try_invaildate(evict_addr)) { // L2 -> L1I
                    // return true mean hit & invalidate
                    m_prev_i->num_backinvals_inc();
                }
                if (m_prev_d->try_invaildate(evict_addr)) { // L2 -> L1D

                    m_prev_d->num_backinvals_inc();

                    if (m_prev_d->is_wb_by_backinval) {
                        m_prev_d->num_writebacks_backinval_inc();

                        mem_req_s *wb_req = new mem_req_s(evict_addr, REQ_WB);
                        wb_req->m_in_cycle = req->m_in_cycle;
                        m_in_flight_wb_queue->push(wb_req); // L1 -> L2 wb queue
                        m_wb_queue->push(wb_req);
                    }
                };
            }

            // INCLUSIVE POLICY`: propagate mem -> L2 -> L1I or L1D
            // if this req is @ L2, we need to forward it to L1I or L1D as well
            if (req->m_type != REQ_WB) {
                if (req->m_type == REQ_IFETCH) {
                    if (m_prev_i) {
                        m_prev_i->fill(req); // L2→L1I fill
                    }
                }
                else { // REQ_DFETCH or REQ_DSTORE
                    if (m_prev_d) {
                        m_prev_d->fill(req); // L2→L1D fill
                    }
                }
            }
        }

        to_remove.push_back(req);
    }
    // remove the requests which are processed
    for (auto req : to_remove) {
        m_fill_queue->pop(req);
    }
}

/**
 * This function processes the write-back queue.
 * The function basically moves the requests from wb_queue to out_queue.
 * CURRENT: There is no limit on the number of requests we can process in a cycle.
 */
void cache_c::process_wb_queue()
{
    // modified
    // move all the requests from wb_queue to out_queue
    while (!m_wb_queue->empty()) {
        mem_req_s *req = m_wb_queue->m_entry[0];
        m_wb_queue->pop(req);
        m_out_queue->push(req);
    }
}

/**
 * Print statistics (DO NOT CHANGE)
 */
void cache_c::print_stats()
{
    cache_base_c::print_stats();
    std::cout << "number of back invalidations: " << m_num_backinvals << "\n";
    std::cout << "number of writebacks due to back invalidations: " << m_num_writebacks_backinval << "\n";
}