import os,time,resource,json,gc,pathlib
CG=pathlib.Path('/sys/fs/cgroup/user')
def val(name):
 try:return (CG/name).read_text().strip()
 except Exception as e:return f'ERR:{e}'
def snapshot(label):
 return {'label':label,'monotonic_s':time.monotonic(),'memory.current':val('memory.current'),'memory.peak':val('memory.peak'),'memory.max':val('memory.max'),'memory.high':val('memory.high'),'memory.swap.current':val('memory.swap.current'),'memory.events':val('memory.events'),'ru_maxrss_KiB':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}
amount=512*1024*1024
out={'test_bytes':amount,'page_size':os.sysconf('SC_PAGE_SIZE'),'snapshots':[]}
out['snapshots'].append(snapshot('before'))
t=time.perf_counter_ns()
buf=bytearray(amount)
out['allocation_seconds']=(time.perf_counter_ns()-t)/1e9
t=time.perf_counter_ns()
page=os.sysconf('SC_PAGE_SIZE')
for i in range(0,amount,page): buf[i]=(i//page)&255
out['explicit_page_touch_seconds']=(time.perf_counter_ns()-t)/1e9
out['snapshots'].append(snapshot('allocated_and_touched'))
# Verify one byte every MiB to ensure pages remain addressable.
t=time.perf_counter_ns(); checksum=sum(buf[i] for i in range(0,amount,1024*1024));out['verification_checksum']=checksum;out['verification_seconds']=(time.perf_counter_ns()-t)/1e9
time.sleep(1)
out['snapshots'].append(snapshot('held_for_1s'))
del buf;gc.collect();time.sleep(0.5)
out['snapshots'].append(snapshot('freed_in_process'))
pathlib.Path('/home/user/envchar_work/memory_pressure_result.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
