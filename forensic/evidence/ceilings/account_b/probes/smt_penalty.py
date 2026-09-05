import multiprocessing as mp, time, sys

DUR = float(sys.argv[1]) if len(sys.argv) > 1 else 30.0

def worker(q, dur):
    x = 0
    end = time.monotonic() + dur
    i = 0
    while time.monotonic() < end:
        for _ in range(200000):
            x = (x * 1103515245 + 12345) & 0x7fffffff
        i += 1
    q.put(i)

def run(nproc, dur):
    mp.set_start_method('fork', force=True)
    q = mp.Queue()
    procs = [mp.Process(target=worker, args=(q, dur)) for _ in range(nproc)]
    t0 = time.monotonic()
    for p in procs: p.start()
    for p in procs: p.join()
    wall = time.monotonic() - t0
    res = [q.get() for _ in procs]
    return wall, res

if __name__ == '__main__':
    w1, r1 = run(1, DUR)
    print(f"1 worker (pinned cpu0):        wall={w1:.2f}s batches={r1} total={sum(r1)}")
    w2, r2 = run(2, DUR)
    print(f"2 workers (cpu0+cpu1 SMT):     wall={w2:.2f}s batches={r2} total={sum(r2)}")
    print(f"SMT scaling: 2-thread total / 1-thread = {sum(r2)/sum(r1):.2f}x")
