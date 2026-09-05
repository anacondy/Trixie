import multiprocessing as mp, time, sys

DUR = float(sys.argv[1]) if len(sys.argv) > 1 else 60.0

def worker(q, dur):
    x = 0
    end = time.monotonic() + dur
    i = 0
    while time.monotonic() < end:
        for _ in range(200000):
            x = (x * 1103515245 + 12345) & 0x7fffffff
        i += 1
    q.put(i)

if __name__ == '__main__':
    mp.set_start_method('fork')
    q = mp.Queue()
    procs = [mp.Process(target=worker, args=(q, DUR)) for _ in range(2)]
    t0 = time.monotonic()
    for p in procs: p.start()
    for p in procs: p.join()
    wall = time.monotonic() - t0
    iters = [q.get() for _ in procs]
    print(f"2-core burn: wall={wall:.2f}s, loop-batches per core={iters}, total={sum(iters)}")
