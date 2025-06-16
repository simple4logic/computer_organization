// ECE 430.322: Computer Organization
// Lab 4: Memory System Simulation

/**
 *
 * This is the base cache structure that maintains and updates the tag store
 * depending on a cache hit or a cache miss. Note that the implementation here
 * will be used throughout Lab 4.
 */

#include "cache_base.h"

#include <cassert>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>

/**
 * This allocates an "assoc" number of cache entries per a set
 * @param assoc - number of cache entries in a set
 */
cache_set_c::cache_set_c(int assoc)
{
    m_entry = new cache_entry_c[assoc];
    m_assoc = assoc;

    // init LRU list
    for (int i = 0; i < assoc; ++i)
        m_lru.push_back(i);
}

// cache_set_c destructor
cache_set_c::~cache_set_c() { delete[] m_entry; }

/**
 * This constructor initializes a cache structure based on the cache parameters.
 * @param name - cache name; use any name you want
 * @param num_sets - number of sets in a cache
 * @param assoc - number of cache entries in a set
 * @param line_size - cache block (line) size in bytes
 *
 * @note You do not have to modify this (other than for debugging purposes).
 */
cache_base_c::cache_base_c(std::string name, int num_sets, int assoc,
                           int line_size)
{
    m_name = name;
    m_num_sets = num_sets;
    m_line_size = line_size;

    m_set = new cache_set_c *[m_num_sets];

    for (int ii = 0; ii < m_num_sets; ++ii) {
        m_set[ii] = new cache_set_c(assoc);

        // initialize tag/valid/dirty bits
        for (int jj = 0; jj < assoc; ++jj) {
            m_set[ii]->m_entry[jj].m_valid = false;
            m_set[ii]->m_entry[jj].m_dirty = false;
            m_set[ii]->m_entry[jj].m_tag = 0;
        }
    }

    // init cache state
    is_writeback = false;
    is_evict = false;
    is_wb_by_backinval = false;
    evict_addr = 0;

    // initialize stats
    m_num_accesses = 0;
    m_num_hits = 0;
    m_num_misses = 0;
    m_num_writes = 0;
    m_num_writebacks = 0;
}

// cache_base_c destructor
cache_base_c::~cache_base_c()
{
    for (int ii = 0; ii < m_num_sets; ++ii) {
        delete m_set[ii];
    }
    delete[] m_set;
}

/**
 * This function looks up in the cache for a memory reference.
 * This needs to update all the necessary meta-data (e.g., tag/valid/dirty)
 * and the cache statistics, depending on a cache hit or a miss.
 * @param address - memory address
 * @param access_type - read (0), write (1), or instruction fetch (2)
 * @param is_fill - if the access is for a cache fill
 * @param return "true" on a hit; "false" otherwise.
 */
bool cache_base_c::access(addr_t address, int access_type, bool is_fill)
{
    ////////////////////////////////////////////////////////////////////
    // TODO: Write the code to implement this function
    ////////////////////////////////////////////////////////////////////
    // memory : request address from instructions

    addr_t block_num = address / m_line_size;
    int index = static_cast<int>(block_num % m_num_sets);
    addr_t tag = block_num / m_num_sets;
    cache_set_c *set = m_set[index];

    is_evict = false;           // set eviction flag
    is_writeback = false;       // reset writeback flag
    is_wb_by_backinval = false; // reset writeback by back invalidation flag

    /////////////////////////////////////
    /// Cache Access
    /////////////////////////////////////
    if (!is_fill) {
        m_num_accesses++;
        if (access_type == WRITE) {
            m_num_writes++;
        }

        int hit_way = -1;
        for (int way = 0; way < set->m_assoc; way++) {
            cache_entry_c &ent = set->m_entry[way];
            if (ent.m_valid && ent.m_tag == tag) {
                hit_way = way;
                break;
            }
        }

        //////////////////////// when cahce HIT
        if (hit_way >= 0) {
            m_num_hits++;

            cache_entry_c &ent = set->m_entry[hit_way];
            if (access_type == WRITE) {
                ent.m_dirty = true;
            }

            // LRU update
            set->m_lru.remove(hit_way);
            set->m_lru.push_front(hit_way); // mark as MRU

            return true;
        }

        //////////////////////// when cache MISS
        m_num_misses++;
        return false;
    }

    /////////////////////////////////////
    /// Cache Fill
    /////////////////////////////////////
    else {
        if (access_type == WRITE_BACK) {
            for (int way = 0; way < set->m_assoc; way++) {
                cache_entry_c &ent = set->m_entry[way];
                if (ent.m_valid && ent.m_tag == tag) {
                    set->m_entry[way].m_dirty = true;
                    return true;
                }
            }
            assert("wb is always hit");
        }

        // evict invalid victim first
        for (int way = 0; way < set->m_assoc; ++way) {
            if (!set->m_entry[way].m_valid) { // find invalid way

                // load into empty way
                set->m_entry[way].m_valid = true;
                set->m_entry[way].m_tag = tag;
                set->m_entry[way].m_dirty = (access_type == WRITE | access_type == WRITE_BACK);

                // renew LRU
                set->m_lru.remove(way);
                set->m_lru.push_front(way);

                return false;
            }
        } // when invalid evicted, no need to do left steps

        // if not, then Eviction using LRU policy
        int victim_way = set->m_lru.back();
        cache_entry_c &victim = set->m_entry[victim_way];
        evict_addr = (victim.m_tag * m_num_sets + index) * m_line_size;
        is_evict = true; // set eviction flag

        // valid & dirty -> write back
        if (victim.m_valid && victim.m_dirty) {
            m_num_writebacks++;
            is_writeback = true; // set writeback flag
        }

        // allocate new cache line to victim`
        victim.m_valid = true;
        victim.m_tag = tag;

        if (access_type == WRITE || access_type == WRITE_BACK) {
            victim.m_dirty = true;
        }
        else {
            victim.m_dirty = false;
        }

        // update LRU - victim = MRU
        set->m_lru.pop_back();
        set->m_lru.push_front(victim_way);

        return false; // Miss
    }
    assert("can not reach here");
    return false; // should not reach here
}

// added
/*
 * This function invalidates a cache entry based on the address.
 * 1. check if the address is in the cache (hit or not)
 * 2. if hit, invalidate the entry (if not, nothing)
 * 3. if the entry is dirty, return true (writeback needed)
 */
bool cache_base_c::try_invaildate(addr_t address)
{

    addr_t block_num = address / m_line_size;
    int index = static_cast<int>(block_num % m_num_sets);
    addr_t tag = block_num / m_num_sets;
    is_wb_by_backinval = false; // reset writeback by back invalidation flag

    cache_set_c *set = m_set[index];

    int hit_way = -1;
    for (int way = 0; way < set->m_assoc; way++) {
        cache_entry_c &ent = set->m_entry[way];

        if (ent.m_valid && ent.m_tag == tag) {
            // hit -> invalidate
            ent.m_valid = false;
            if (ent.m_dirty) {
                // writeback due to invalidation needed
                is_wb_by_backinval = true; // set writeback flag
            }
            return true; // not needed
        }
    }
    // miss -> nothing to invalidate
    return false;
}

/**
 * Print statistics (DO NOT CHANGE)
 */
void cache_base_c::print_stats()
{
    std::cout << "------------------------------" << "\n";
    std::cout << m_name
              << " Hit Rate: " << (double)m_num_hits / m_num_accesses * 100
              << " % \n";
    std::cout << "------------------------------" << "\n";
    std::cout << "number of accesses: " << m_num_accesses << "\n";
    std::cout << "number of hits: " << m_num_hits << "\n";
    std::cout << "number of misses: " << m_num_misses << "\n";
    std::cout << "number of writes: " << m_num_writes << "\n";
    std::cout << "number of writebacks: " << m_num_writebacks << "\n";
}

/**
 * Dump tag store (for debugging)
 * Modify this if it does not dump from the MRU to LRU positions in your
 * implementation.
 */
void cache_base_c::dump_tag_store(bool is_file)
{
    auto write = [&](std::ostream &os) {
        os << "------------------------------" << "\n";
        os << m_name << " Tag Store\n";
        os << "------------------------------" << "\n";

        for (int ii = 0; ii < m_num_sets; ii++) {
            for (int jj = 0; jj < m_set[0]->m_assoc; jj++) {
                os << "[" << (int)m_set[ii]->m_entry[jj].m_valid << ", ";
                os << (int)m_set[ii]->m_entry[jj].m_dirty << ", ";
                os << std::setw(10) << std::hex << m_set[ii]->m_entry[jj].m_tag
                   << std::dec << "] ";
            }
            os << "\n";
        }
    };

    if (is_file) {
        std::ofstream ofs(m_name + ".dump");
        write(ofs);
    }
    else {
        write(std::cout);
    }
}
