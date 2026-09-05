import subprocess,time,json,pathlib,shutil,os
results=[]; raw=[]
def run(name,cmd,timeout=300):
 t=time.perf_counter_ns()
 try:
  p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout,env={**os.environ,'DEBIAN_FRONTEND':'noninteractive'})
  rc=p.returncode; out=p.stdout; status='ok' if rc==0 else 'failed'
 except Exception as e:
  rc=-1;out=f'{type(e).__name__}: {e}';status='error'
 sec=(time.perf_counter_ns()-t)/1e9
 results.append({'test':name,'status':status,'seconds':sec,'rc':rc,'command':' '.join(cmd)})
 raw.append(f'## {name}\nstatus={status} rc={rc} elapsed={sec:.6f} s\ncommand={cmd!r}\n--- output ---\n{out[-20000:]}\n')
 return rc,out
pre=shutil.which('tree')
raw.append(f'preexisting_tree_path={pre}\n')
# Sources are public package config; record noncomment lines, but redact URL userinfo just in case.
for p in list(pathlib.Path('/etc/apt').glob('sources.list'))+list(pathlib.Path('/etc/apt/sources.list.d').glob('*')):
 try:
  txt=p.read_text(errors='replace')
  raw.append(f'## apt source file {p}\n'+txt+'\n')
 except Exception as e: raw.append(f'cannot read {p}: {e}\n')
run('apt_get_update',['sudo','apt-get','-o','Acquire::Retries=0','update'],timeout=300)
rc,_=run('apt_install_tree',['sudo','apt-get','-o','Acquire::Retries=0','install','-y','--no-install-recommends','tree'],timeout=300)
if rc==0: run('apt_tree_verify',['tree','--version'])
if pre is None and shutil.which('tree'):
 run('apt_purge_tree',['sudo','apt-get','purge','-y','tree'],timeout=300)
 run('apt_autoremove_dry_run',['sudo','apt-get','-s','autoremove'],timeout=120)
pathlib.Path('/home/user/envchar_work/apt_install_results.json').write_text(json.dumps(results,indent=2))
pathlib.Path('/home/user/envchar_work/apt_install_notes.txt').write_text('\n'.join(raw))
print(json.dumps(results,indent=2)); print('\n'.join(raw))
