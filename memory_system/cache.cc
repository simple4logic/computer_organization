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

        bool hit = cache_base_c::access(req->m_addr, req->m_type, /*is_fill=*/false); // real access

        if (hit) { // if l1 hit, L1 -> core
            if (m_level == 1) {
                if (done_func) {
                    done_func(req);
                }
            }
            else {
                // if l2 hit, L2 -> L1I or L1D
                if (req->m_type == REQ_IFETCH) { // To L1I
                    if (m_prev_i)
                        m_prev_i->fill(req);
                }
                else { // To L1D
                    if (m_prev_d)
                        m_prev_d->fill(req);
                }
            }
        }
        else { // miss
            m_out_queue->push(req);
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
        mem_req_s *req = m_out_queue->m_entry[0];
        m_out_queue->pop(req);

        if (m_next) { // if next is L2
            m_next->access(req);
        }
        else if (m_memory) { // if next is memory
            m_memory->access(req);
        }
        else {
            assert(false && "no next or memory");
        }

        // to manage wb req is in flight or not
        if (req->m_type == REQ_WB) {
            m_in_flight_wb_queue->push(req);
        }
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

        // to access to fill (not counted as hit or miss)
        cache_base_c::access(req->m_addr, req->m_type, /*is_fill=*/true);

        // if this req is @ L1, we need to say that it is done
        if (m_level == 1 && done_func) {
            done_func(req);
        }

        // INCLUSIVE POLICY`: propagate mem -> L2 -> L1I or L1D
        // if this req is @ L2, we need to forward it to L1I or L1D as well
        if (m_level == 2) {
            if (req->m_type == REQ_IFETCH) {
                if (m_prev_i) {
                    m_prev_i->fill(req); // L2→L1I fill
                }
            }
            else {
                if (m_prev_d) {
                    m_prev_d->fill(req); // L2→L1D fill
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
