# croaring-batch-lab

How much time can a bitmap index save when one filter intersects hundreds of posting lists? This independent experiment targets the crossover where grouping containers and reusing a filter tile begins to pay for its own setup.

## Run the dense intersection probe

On x86-64 Linux with GCC and C++17:

```sh
g++ -O2 -std=c++17 probe.cpp -o probe
./probe
```

The probe compares AVX-512 AND/popcount over two 8 KiB bitmaps against a scalar count on seeded input. It prints `ok` on a match, exits nonzero on a mismatch, and reports a skip on CPUs without the required vector popcount extension.

## Planned benchmark

Compare a loop over CRoaring's `roaring_bitmap_and_cardinality` with direct and grouped dispatch using identical compiler settings. Sweep batch widths from 1 to 256 with ordered and shuffled array, run and bitmap container pairs. Check each output against a sorted-vector oracle before timing. Include grouping and output writes in elapsed time.

The first benchmark release will include the harness, exact revisions, compiler flags, CPU model, workload seeds, Google Benchmark JSON and Linux perf counters. Report median nanoseconds per batch alongside cycles and branch misses per list. Publish losing cases along with winning cases. The initial probe exercises correctness only.

## License

MIT. See [LICENSE](LICENSE).
