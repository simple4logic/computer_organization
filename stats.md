# Stats

## Part 1

### direct-mapped

```bash
./run_base ../traces/sample.trace 16384 1 64
------------------------------
L1 Hit Rate: 95.1 %
------------------------------
number of accesses: 1000000
number of hits: 951000
number of misses: 49000
number of writes: 80669
number of writebacks: 5743
```

### 2-way set associative

```bash
./run_base ../traces/sample.trace 16384 2 64
------------------------------
L1 Hit Rate: 96.4078 %
------------------------------
number of accesses: 1000000
number of hits: 964078
number of misses: 35922
number of writes: 80669
number of writebacks: 4377
```

### 4-way set associative

```bash
./run_base ../traces/sample.trace 16384 4 64
------------------------------
L1 Hit Rate: 96.8525 %
------------------------------
number of accesses: 1000000
number of hits: 968525
number of misses: 31475
number of writes: 80669
number of writebacks: 2950
```

### 8-way set associative

```bash
./run_base ../traces/sample.trace 16384 8 64
------------------------------
L1 Hit Rate: 97.1274 %
------------------------------
number of accesses: 1000000
number of hits: 971274
number of misses: 28726
number of writes: 80669
number of writebacks: 2783
```

## part 2

single level, 4-way SA, 16KB, LRU, 4-cycle

```bash
./memory_sim ./traces/sample.trace ./configs/memory.cfg
------------------------------
Performance Stats
------------------------------
CPI:  10.5731
number of cycles: 8241925
number of insts: 779515
number of memory insts: 220485
------------------------------
L1 Hit Rate: 96.8525 %
------------------------------
number of accesses: 1000000
number of hits: 968525
number of misses: 31475
number of writes: 80669
number of writebacks: 2950
number of back invalidations: 0
number of writebacks due to back invalidations: 0
```
