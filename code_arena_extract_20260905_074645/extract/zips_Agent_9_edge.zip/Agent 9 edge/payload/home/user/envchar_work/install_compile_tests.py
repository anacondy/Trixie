import subprocess, time, os, json, shutil, pathlib, textwrap, resource
base=pathlib.Path('/tmp/envchar_install_tests')
shutil.rmtree(base,ignore_errors=True); base.mkdir()
results=[]; notes=[]
def run(name,cmd,cwd=None,env=None,timeout=300):
    t=time.perf_counter_ns()
    try:
        p=subprocess.run(cmd,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
        status='ok' if p.returncode==0 else 'failed'
        rc=p.returncode; output=p.stdout
    except Exception as e:
        status='error';rc=-1;output=f'{type(e).__name__}: {e}'
    sec=(time.perf_counter_ns()-t)/1e9
    results.append(dict(test=name,status=status,seconds=sec,rc=rc,command=' '.join(cmd)))
    notes.append(f'## {name}\nstatus={status} rc={rc} elapsed={sec:.6f} s\ncommand={cmd!r}\n--- output ---\n{output[-12000:]}\n')
    return status,output,sec

# Isolated venv and no-cache pure-Python install.
venv=base/'venv'
run('python_venv_create',['python3','-m','venv',str(venv)])
run('pip_pure_python_install',[str(venv/'bin/python'),'-m','pip','install','--disable-pip-version-check','--no-cache-dir','pyfiglet==1.0.2'])
run('pip_import_verify',[str(venv/'bin/python'),'-c','import pyfiglet; print(pyfiglet.__version__); print(pyfiglet.figlet_format("OK", font="small"))'])

# npm local install only.
npm_dir=base/'npm';npm_dir.mkdir()
(npm_dir/'package.json').write_text('{"name":"envchar-test","version":"1.0.0","private":true}\n')
run('npm_local_install',['npm','install','--ignore-scripts','--no-audit','--no-fund','is-number@7.0.0'],cwd=npm_dir)
run('npm_require_verify',['node','-e','const f=require("is-number"); if(!f(42)||f("x"))process.exit(1); console.log("is-number verification OK")'],cwd=npm_dir)

# Native compile via direct gcc and via make.
cdir=base/'c';cdir.mkdir()
(cdir/'probe.c').write_text(textwrap.dedent(r'''
#include <stdio.h>
#include <stdint.h>
int main(void) { uint64_t x=0; for (uint64_t i=0;i<1000000;i++) x=x*33u+i; printf("%llu\n",(unsigned long long)x); return 0; }
'''))
(cdir/'Makefile').write_text('CC ?= gcc\nCFLAGS ?= -O2 -Wall -Wextra\nprobe: probe.c\n\t$(CC) $(CFLAGS) -o $@ $<\n')
run('gcc_native_compile',['gcc','-O2','-Wall','-Wextra','-o','probe-gcc','probe.c'],cwd=cdir)
run('gcc_binary_verify',[str(cdir/'probe-gcc')],cwd=cdir)
run('make_native_compile',['make','clean'],cwd=cdir) if False else None
run('make_native_compile',['make','CC=gcc'],cwd=cdir)
run('make_binary_verify',[str(cdir/'probe')],cwd=cdir)

pathlib.Path('/home/user/envchar_work/install_compile_results.json').write_text(json.dumps(results,indent=2))
pathlib.Path('/home/user/envchar_work/install_compile_notes.txt').write_text('\n'.join(notes))
print(json.dumps(results,indent=2))
print('\n'.join(notes))
# Measure temporary footprint before cleanup.
def tree_bytes(p):
    return sum(x.stat().st_size for x in p.rglob('*') if x.is_file())
print(f'temporary_test_tree_logical_file_bytes={tree_bytes(base)}')
shutil.rmtree(base)
