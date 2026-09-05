#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>

static volatile int stop = 0;
static volatile uint64_t total_iters = 0;
static void *work(void *a) {
    uint64_t acc = (uintptr_t)a;
    volatile uint64_t x = acc ^ 0x9e3779b97f4a7c15ULL;
    uint64_t n = 0;
    while (!stop) {
        for (int i = 0; i < 4096; i++) {
            x ^= x << 13; x ^= x >> 7; x ^= x << 17;
            acc += x;
        }
        n += 4096;
        __atomic_add_fetch(&total_iters, 4096, __ATOMIC_RELAXED);
    }
    (void)acc;
    return NULL;
}
int main(int argc, char **argv) {
    int nthreads = argc > 1 ? atoi(argv[1]) : 1;
    int secs = argc > 2 ? atoi(argv[2]) : 10;
    pthread_t *t = calloc(nthreads, sizeof(pthread_t));
    struct timespec t0, t1; clock_gettime(CLOCK_MONOTONIC, &t0);
    for (int i = 0; i < nthreads; i++) pthread_create(&t[i], NULL, work, (void*)(intptr_t)i);
    sleep(secs);
    stop = 1;
    for (int i = 0; i < nthreads; i++) pthread_join(t[i], NULL);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double dt = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) / 1e9;
    printf("iters=%lu dt=%.1fs rate=%.0f iters/s (nthreads=%d secs=%d)\n",
           (unsigned long)total_iters, dt, total_iters / dt, nthreads, secs);
    return 0;
}
