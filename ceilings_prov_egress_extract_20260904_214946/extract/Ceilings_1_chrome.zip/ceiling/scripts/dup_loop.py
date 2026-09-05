import os
n = 0
try:
    while True:
        os.dup(1); n += 1
except OSError as e:
    print(f"COUNT {n} errno={e.errno} {e.strerror}", flush=True)
