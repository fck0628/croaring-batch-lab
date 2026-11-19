#include <immintrin.h>
#include <cstdint>
#include <cstdio>
#include <random>
using word = std::uint64_t;
using block = word[1024];
__attribute__((target("avx512f,avx512vpopcntdq")))
unsigned dense_count(const block& a, const block& b) {
    auto sum = _mm512_setzero_si512();
    for (unsigned i = 0; i < 1024; i += 8) {
        auto x = _mm512_loadu_si512(a + i), y = _mm512_loadu_si512(b + i);
        sum = _mm512_add_epi64(sum, _mm512_popcnt_epi64(_mm512_and_si512(x, y)));
    }
    return static_cast<unsigned>(_mm512_reduce_add_epi64(sum));
}
int main() {
    if (!__builtin_cpu_supports("avx512vpopcntdq")) return std::puts("skip: no vpopcntdq"), 0;
    std::mt19937_64 rng(42);
    block a, b;
    unsigned ref = 0;
    for (unsigned i = 0; i < 1024; ++i) {
        a[i] = rng(); b[i] = rng(); ref += __builtin_popcountll(a[i] & b[i]);
    }
    return dense_count(a, b) == ref ? (std::puts("ok"), 0) : 1;
}
