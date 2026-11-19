# When does batching bitmap intersections pay for itself?

One filter, many posting lists, one exact count per list. The baseline for this experiment is a loop over CRoaring's `roaring_bitmap_and_cardinality`. The question is how wide the batch has to get before sharing work across lists repays the cost of grouping them.

## What runs today

The [C++17 probe](../probe.cpp) intersects two 8 KiB bitmaps with AVX-512 AND and vector popcount. On a seeded input it returned the same count as the scalar reference on x86-64. The [build command](../README.md) reproduces that check on a machine with AVX512VPOPCNTDQ. That gives us a correctness check for one dense pair. The batch crossover and the speedup are still open questions.

## The first Devin worker assignment

Start with the dense case. Build two candidates from the same kernel. One processes a whole posting list at a time. The other loads a tile of the filter and reuses it across several lists before advancing. Both write counts to the original output slots. Width one is a control: there is no cross-list reuse there. A large difference at width one sends the worker back to the generated assembly and timing boundaries.

The coordinator will give each worker a baseline revision, a workload seed and a profiling budget. Workers can compile in parallel. Timed runs take turns on one pinned core. If a count differs, the worker saves the seed, shrinks the input against a sorted-vector oracle and adds the smallest failing case as a regression test before profiling again.

## Where mixed containers can lose

For a given high key the filter container type is fixed. A candidate can group matched posting containers by type and dispatch once per group. A short array may need only a handful of bit probes. For a run contained in one word, both endpoint masks must apply to that same word. Grouping adds a classification pass and scratch writes that a direct call avoids. We'll test identical pairs in both type-sorted and shuffled order and include setup and result writes in elapsed time.

## What gets published

The planned harness sweeps batch widths from 1 to 256. The release will record the CPU, compiler flags, exact revisions and seeds alongside Google Benchmark JSON and Linux perf counters. The headline is median nanoseconds per batch. Cycles and branch misses per list help explain the shape of the curve. Correctness checks include inputs around 4096 elements, runs crossing a high-key boundary and equal-length lists with different overlaps.

Each worker gets at most five profiling rounds. If none of the first three cuts either cycles per list or wall time per batch by 15% against stock on the assigned workload, the coordinator stops it and records the tactic and workload in SQLite. A merge requires a wall-time win on held-out batches. The first tagged result will also include the ranges where stock wins, even if that is the entire sweep.
