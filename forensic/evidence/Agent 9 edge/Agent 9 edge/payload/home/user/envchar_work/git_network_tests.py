import subprocess,time,json,pathlib,os
probes=[
 ('git_https_ls_remote',['git','-c','credential.helper=','ls-remote','https://github.com/git/git.git','HEAD'],30),
 ('git_native_9418_ls_remote',['git','ls-remote','git://github.com/git/git.git','HEAD'],30),
 ('ssh_github_banner',['ssh','-4','-o','BatchMode=yes','-o','StrictHostKeyChecking=no','-o','UserKnownHostsFile=/dev/null','-o','ConnectTimeout=5','-T','git@github.com'],15),
]
rows=[];notes=[]
for name,cmd,timeout in probes:
 t=time.perf_counter_ns()
 try:
  p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout,env={**os.environ,'GIT_TERMINAL_PROMPT':'0'})
  rc=p.returncode;out=p.stdout;status='transport_reached' if (name=='ssh_github_banner' and ('successfully authenticated' in out or 'Permission denied' in out)) else ('ok' if rc==0 else 'failed')
 except Exception as e:rc=-1;out=f'{type(e).__name__}: {e}';status='error'
 sec=(time.perf_counter_ns()-t)/1e9
 rows.append({'test':name,'status':status,'seconds':sec,'rc':rc})
 notes.append(f'## {name}\ncommand={cmd!r}\nstatus={status} rc={rc} elapsed={sec:.6f}s\n{out[-5000:]}')
pathlib.Path('/home/user/envchar_work/git_network_results.json').write_text(json.dumps(rows,indent=2))
pathlib.Path('/home/user/envchar_work/git_network_notes.txt').write_text('\n\n'.join(notes)+'\n')
print(json.dumps(rows,indent=2));print('\n\n'.join(notes))
