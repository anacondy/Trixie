import csv, shutil, subprocess, shlex
from pathlib import Path

tools = [
 ('python3',['python3','--version']), ('python',['python','--version']),
 ('pip3',['pip3','--version']), ('pip',['pip','--version']),
 ('uv',['uv','--version']), ('pipx',['pipx','--version']), ('poetry',['poetry','--version']),
 ('conda',['conda','--version']), ('mamba',['mamba','--version']), ('micromamba',['micromamba','--version']),
 ('node',['node','--version']), ('npm',['npm','--version']), ('npx',['npx','--version']),
 ('corepack',['corepack','--version']), ('yarn',['yarn','--version']), ('pnpm',['pnpm','--version']),
 ('bun',['bun','--version']), ('deno',['deno','--version']),
 ('git',['git','--version']), ('curl',['curl','--version']), ('wget',['wget','--version']),
 ('ffmpeg',['ffmpeg','-version']), ('ffprobe',['ffprobe','-version']),
 ('docker',['docker','--version']), ('podman',['podman','--version']),
 ('make',['make','--version']), ('gcc',['gcc','--version']), ('g++',['g++','--version']),
 ('clang',['clang','--version']), ('clang++',['clang++','--version']),
 ('cmake',['cmake','--version']), ('ninja',['ninja','--version']), ('pkg-config',['pkg-config','--version']),
 ('jq',['jq','--version']), ('sqlite3',['sqlite3','--version']),
 ('apt',['apt','--version']), ('apt-get',['apt-get','--version']), ('dpkg',['dpkg','--version']),
 ('apk',['apk','--version']), ('yum',['yum','--version']), ('dnf',['dnf','--version']),
 ('go',['go','version']), ('rustc',['rustc','--version']), ('cargo',['cargo','--version']),
 ('java',['java','-version']), ('javac',['javac','-version']), ('R',['R','--version']),
 ('ruby',['ruby','--version']), ('perl',['perl','-v']), ('php',['php','--version']),
 ('tar',['tar','--version']), ('unzip',['unzip','-v']), ('7z',['7z']), ('rsync',['rsync','--version']),
 ('aria2c',['aria2c','--version']), ('ssh',['ssh','-V']), ('openssl',['openssl','version']),
 ('ping',['ping','-V']), ('dig',['dig','-v']), ('host',['host','-V']), ('nslookup',['nslookup','-version']),
 ('nc',['nc','-h']), ('socat',['socat','-V']), ('time',['/usr/bin/time','--version']),
 ('fio',['fio','--version']), ('hyperfine',['hyperfine','--version']), ('stress-ng',['stress-ng','--version']),
 ('nvidia-smi',['nvidia-smi','--version']), ('pandoc',['pandoc','--version']),
]
rows=[]
for name, cmd in tools:
    path=shutil.which(name) if cmd[0] == name else (cmd[0] if Path(cmd[0]).exists() else None)
    if not path:
        rows.append([name,'no','',''])
        continue
    try:
        p=subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=8)
        lines=[ln.strip() for ln in p.stdout.splitlines() if ln.strip()]
        version=(lines[0] if lines else '(no version text)')
        if len(version)>220: version=version[:217]+'...'
        rows.append([name,'yes',path,f'{version} [rc={p.returncode}]'])
    except Exception as e:
        rows.append([name,'yes',path,f'version probe error: {type(e).__name__}: {e}'])
out=Path('/home/user/envchar_work/tool_inventory.tsv')
with out.open('w', newline='') as f:
    w=csv.writer(f, delimiter='\t'); w.writerow(['tool','available','path','version_probe']); w.writerows(rows)
print(out.read_text())
