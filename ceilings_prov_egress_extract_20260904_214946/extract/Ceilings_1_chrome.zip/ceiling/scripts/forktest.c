#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <time.h>

static volatile sig_atomic_t gotsig = 0;
static long *g_n = NULL; static struct timespec *g_t0 = NULL;
static void onterm(int s) {
    gotsig = 1;
    struct timespec t1; clock_gettime(CLOCK_MONOTONIC, &t1);
    double dt = (t1.tv_sec - g_t0->tv_sec) + (t1.tv_nsec - g_t0->tv_nsec) / 1e9;
    printf("INTERRUPTED(%d) after %ld children this run, %.1fs (cum %.2f ms/fork)\n",
           s, *g_n, dt, dt / (*g_n ? *g_n : 1) * 1000);
    fflush(stdout);
    _exit(42);
}

int main(void) {
    struct rlimit rl;
    getrlimit(RLIMIT_NPROC, &rl);
    printf("RLIMIT_NPROC soft=%ld hard=%ld\n", (long)rl.rlim_cur, (long)rl.rlim_max);
    printf("pids.max=%s pids.current=%s\n",
           ({ FILE*f=fopen("/sys/fs/cgroup/user/pids.max","r"); static char b[64]; fgets(b,64,f); fclose(f); b; }),
           ({ FILE*f=fopen("/sys/fs/cgroup/user/pids.current","r"); static char c[64]; fgets(c,64,f); fclose(f); c; }));
    long cap = (rl.rlim_cur == RLIM_INFINITY) ? 20000 : (long)rl.rlim_cur + 16;
    pid_t *kids = malloc((size_t)cap * sizeof(pid_t));
    if (!kids) { printf("malloc fail\n"); return 1; }
    FILE *pf = fopen("/home/user/ceiling/out/fork_pids.txt", "w");
    long n = 0;
    struct timespec t0; clock_gettime(CLOCK_MONOTONIC, &t0);
    g_n = &n; g_t0 = &t0;
    signal(SIGTERM, onterm); signal(SIGINT, onterm);
    while (1) {
        pid_t p = fork();
        if (p == 0) { setsid(); pause(); _exit(0); }
        if (p < 0) {
            printf("FORK_FAIL after %ld children this run: errno=%d (%s)\n", n, errno, strerror(errno));
            break;
        }
        kids[n++] = p;
        fprintf(pf, "%d\n", p);
        if (n % 500 == 0) {
            struct timespec t1; clock_gettime(CLOCK_MONOTONIC, &t1);
            double dt = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) / 1e9;
            printf("  %ld children, elapsed %.1fs (cum %.2f ms/fork)\n", n, dt, dt / n * 1000);
            fflush(stdout); fflush(pf);
        }
    }
    struct timespec t1; clock_gettime(CLOCK_MONOTONIC, &t1);
    double dt = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) / 1e9;
    printf("FORK TOTAL %ld children this run in %.1fs (cum avg %.2f ms/fork)\n", n, dt, dt / n * 1000);
    fclose(pf);
    printf("parent exiting; %ld children remain (setsid'ed), pids in out/fork_pids.txt\n", n);
    return 0;
}
