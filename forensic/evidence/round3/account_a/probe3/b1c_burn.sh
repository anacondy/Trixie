#!/bin/bash
# hold both vCPUs busy for N seconds, reporting measured busy% at the end
N=${1:-20}
python3 - "$N" <<'PY'
import os,sys,time
n=int(sys.argv[1])
for _ in range(2):
    if os.fork()==0:
        t=time.time(); x=1.0000001
        while time.time()-t<n:
            for _ in range(100000): x=(x*1.0000001)**0.5
        os._exit(0)
PY
read a b c d e f g h i j k <<< "$(grep '^cpu ' /proc/stat)"; idle0=$((e+f)); tot0=$((a+b+c+d+e+f+g+h+i+j+k))
sleep "$N"
read a b c d e f g h i j k <<< "$(grep '^cpu ' /proc/stat)"; idle1=$((e+f)); tot1=$((a+b+c+d+e+f+g+h+i+j+k))
echo "BURN: cpu_busy_pct=$(python3 -c "print('%.1f'%(100*(1-($idle1-$idle0)/max(1,($tot1-$tot0)))))") over ${N}s"
