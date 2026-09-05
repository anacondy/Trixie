#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <pthread.h>
#include <time.h>
#include <sys/resource.h>

static volatile int done = 0;
static void *idle(void *a) {
    struct timespec ts = {0, 20000000L}; /* 20 ms */
    while (!done) nanosleep(&ts, NULL);
    return NULL;
}

int main(void) {
    struct rlimit rl;
    getrlimit(RLIMIT_NPROC, &rl);
    printf("RLIMIT_NPROC soft=%ld hard=%ld\n", (long)rl.rlim_cur, (long)rl.rlim_max);
    pthread_attr_t at;
    pthread_attr_init(&at);
    pthread_attr_setstacksize(&at, 128 * 1024);
    pthread_attr_setguardsize(&at, 4096);
    long n = 0, cap = 20000;
    pthread_t *ts = malloc(cap * sizeof(pthread_t));
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    while (1) {
        int rc = pthread_create(&ts[n], &at, idle, NULL);
        if (rc != 0) {
            printf("THREAD_FAIL after %ld threads: %d (%s)\n", n, rc, strerror(rc));
            break;
        }
        n++;
        if (n % 1000 == 0) {
            clock_gettime(CLOCK_MONOTONIC, &t1);
            double dt = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) / 1e9;
            printf("  %ld threads, elapsed %.1fs (%.2f ms/thread)\n", n, dt, dt / n * 1000);
            fflush(stdout);
        }
        if (n >= cap) { printf("cap reached\n"); break; }
    }
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double dt = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) / 1e9;
    printf("THREAD TOTAL %ld threads in %.1fs (avg %.2f ms/thread)\n", n, dt, dt / n * 1000);
    done = 1;
    for (long i = 0; i < n; i++) pthread_join(ts[i], NULL);
    printf("joined all %ld\n", n);
    return 0;
}
