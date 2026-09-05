# IDENTITY AND PROVENANCE REPORT

## 1. IDENTITY

### full contents of `/.e2b`
**MEASURED** `cat /.e2b`
```
ENV_ID=nlhz8vlwyupq845jsdg9
TEMPLATE_ID=nlhz8vlwyupq845jsdg9
BUILD_ID=f34a5416-ef30-4cb7-8e18-0fdecd6eb529
```

### every env var matching `^E2B_`
**MEASURED** `env | grep -E '^E2B_' | sort`
```
E2B_EVENTS_ADDRESS=http://192.0.2.1
E2B_SANDBOX=true
E2B_SANDBOX_ID=ibbwxrhn0lpoi9ybz9fru
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
```

### hostname; `/etc/hosts` entries containing e2b
**MEASURED** `hostname; grep -i e2b /etc/hosts`
```
e2b.local
127.0.1.1        e2b.local
192.0.2.1        events.e2b.local
```

### `/proc/sys/kernel/random/boot_id`
**MEASURED** `cat /proc/sys/kernel/random/boot_id`
```
2bb79165-136a-4b63-829d-17027b0a8e40
```

### `uptime -s` and `/proc/uptime`
**MEASURED** `uptime -s; cat /proc/uptime`
```
2026-09-04 19:16:12
12.82 16.45
```
(later re-read of `/proc/uptime` during probe write: `31.34 49.81`)

### machine-id
**MEASURED** `cat /etc/machine-id; cat /var/lib/dbus/machine-id`
```
67549745dd1a4564be928e47dca271fd
67549745dd1a4564be928e47dca271fd
```

---

## 2. IMAGE BUILD LINEAGE

### `stat -c '%y %n' /* | sort`
**MEASURED**
```
2026-07-04 09:05:00.000000000 +0000 /bin
2026-07-04 09:05:00.000000000 +0000 /boot
2026-07-04 09:05:00.000000000 +0000 /lib
2026-07-04 09:05:00.000000000 +0000 /lib64
2026-07-04 09:05:00.000000000 +0000 /sbin
2026-07-13 00:00:00.000000000 +0000 /media
2026-07-13 00:00:00.000000000 +0000 /mnt
2026-07-13 00:00:00.000000000 +0000 /opt
2026-07-13 00:00:00.000000000 +0000 /srv
2026-07-23 15:09:20.000000000 +0000 /lost+found
2026-07-23 15:09:31.833258320 +0000 /usr
2026-07-23 15:09:44.334200241 +0000 /var
2026-07-23 15:09:58.374180193 +0000 /home
2026-07-23 18:05:26.709167135 +0000 /root
2026-07-23 18:05:37.190886857 +0000 /proc
2026-07-23 18:05:37.190886857 +0000 /sys
2026-07-23 18:05:37.762886857 +0000 /dev
2026-07-23 18:05:37.976974292 +0000 /etc
2026-07-23 18:05:38.500974292 +0000 /run
2026-07-23 18:05:39.364974292 +0000 /code
2026-09-04 19:16:22.232646354 +0000 /tmp
```

### `stat -c '%y %s' /.e2b`
**MEASURED**
```
2026-07-23 18:05:37.836974292 +0000 107
```

### apt snapshot line in `/etc/apt/sources.list*`
**MEASURED** `grep -r snapshot.debian.org /etc/apt/sources.list /etc/apt/sources.list.d 2>&1`
```
grep: /etc/apt/sources.list: No such file or directory
/etc/apt/sources.list.d/debian.sources:# http://snapshot.debian.org/archive/debian/20260713T000000Z
/etc/apt/sources.list.d/debian.sources:# http://snapshot.debian.org/archive/debian-security/20260713T000000Z
```

**MEASURED** `cat /etc/apt/sources.list.d/debian.sources`
```
Types: deb
# http://snapshot.debian.org/archive/debian/20260713T000000Z
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp

Types: deb
# http://snapshot.debian.org/archive/debian-security/20260713T000000Z
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
```

### `dpkg-query -W --showformat='${Package} ${Version}\n' | wc -l`
**MEASURED**
```
650
```

### `pip list --format=freeze | wc -l` and full output
**MEASURED**
```
180
```
Full output:
```
aiohappyeyeballs==2.7.1
aiohttp==3.14.1
aiosignal==1.4.0
annotated-doc==0.0.4
annotated-types==0.7.0
anyio==4.14.2
argon2-cffi==25.1.0
argon2-cffi-bindings==25.1.0
arrow==1.4.0
asttokens==3.0.2
attrs==26.1.0
audioop-lts==0.2.2
audioread==3.1.0
bash_kernel==0.10.0
beautifulsoup4==4.15.0
bleach==6.4.0
blis==1.3.3
bokeh==3.9.1
catalogue==2.0.10
certifi==2026.7.22
cffi==2.1.0
charset-normalizer==3.4.9
choreographer==1.3.0
click==8.4.2
cloudpathlib==0.24.0
comm==0.2.3
confection==1.3.3
contourpy==1.3.3
cycler==0.12.1
cymem==2.0.13
debugpy==1.8.21
decorator==5.3.1
defusedxml==0.7.1
e2b-charts==1.0.0
et_xmlfile==2.0.0
executing==2.2.1
fastjsonschema==2.21.2
filetype==1.2.0
fonttools==4.63.0
fqdn==1.5.1
frozenlist==1.8.0
gensim==4.4.0
h11==0.16.0
httpcore==1.0.9
httpx==0.28.1
idna==3.18
ImageIO==2.37.3
iniconfig==2.3.0
ipykernel==6.31.0
ipython==9.15.0
ipython_pygments_lexers==1.1.1
isoduration==20.11.0
jedi==0.20.0
Jinja2==3.1.6
joblib==1.5.3
jsonpointer==3.1.1
jsonschema==4.26.0
jsonschema-specifications==2025.9.1
jupyter_client==8.9.1
jupyter_core==5.9.1
jupyter-events==0.12.1
jupyter_server==2.20.0
jupyter_server_terminals==0.5.4
jupyterlab_pygments==0.3.0
kaleido==1.3.0
kiwisolver==1.5.0
lark==1.3.1
lazy-loader==0.5
librosa==0.11.0
llvmlite==0.48.0
logistro==2.0.1
lxml==6.1.1
markdown-it-py==4.2.0
MarkupSafe==3.0.3
matplotlib==3.10.9
matplotlib-inline==0.2.2
mdurl==0.1.2
mistune==3.3.4
mpmath==1.3.0
msgpack==1.2.1
multidict==6.7.1
murmurhash==1.0.15
narwhals==2.24.0
nbclient==0.11.0
nbconvert==7.17.1
nbformat==5.10.4
nest-asyncio==1.6.0
networkx==3.6.1
nltk==3.10.0
numba==0.66.0
numpy==2.3.5
opencv-python==4.11.0.86
openpyxl==3.1.5
orjson==3.11.9
packaging==26.2
pandas==2.2.3
pandocfilters==1.5.1
parso==0.8.7
pexpect==4.9.0
pillow==12.3.0
pip==26.1.2
platformdirs==4.11.0
plotly==6.0.1
pluggy==1.6.0
pooch==1.9.0
preshed==3.0.13
prometheus_client==0.25.0
prompt_toolkit==3.0.52
propcache==0.5.2
psutil==7.2.2
ptyprocess==0.7.0
pure_eval==0.2.3
pycparser==3.0
pydantic==2.13.4
pydantic_core==2.46.4
Pygments==2.20.0
pyparsing==3.3.2
pytest==9.0.3
python-dateutil==2.9.0.post0
python-docx==1.1.2
python-json-logger==4.1.0
pytz==2025.2
PyYAML==6.0.3
pyzmq==27.1.0
referencing==0.37.0
regex==2026.7.19
requests==2.33.0
rfc3339-validator==0.1.4
rfc3986-validator==0.1.1
rfc3987-syntax==1.1.0
rich==15.0.0
rpds-py==2026.6.3
scikit-image==0.25.2
scikit-learn==1.6.1
scipy==1.17.1
seaborn==0.13.2
Send2Trash==2.1.0
setuptools==83.0.0
shellingham==1.5.4
simplejson==4.1.1
six==1.17.0
smart_open==8.0.1
soundfile==0.13.1
soupsieve==2.9.1
soxr==1.1.0
spacy==3.8.14
spacy-legacy==3.0.12
spacy-loggers==1.0.5
srsly==2.5.3
stack-data==0.6.3
standard-aifc==3.13.0
standard-chunk==3.13.0
standard-sunau==3.13.0
sympy==1.14.0
terminado==0.18.1
textblob==0.19.0
thinc==8.3.13
threadpoolctl==3.6.0
tifffile==2026.7.14
tinycss2==1.5.1
tornado==6.5.7
tqdm==4.69.0
traitlets==5.15.1
typer==0.27.0
typing_extensions==4.16.0
typing-inspection==0.4.2
tzdata==2026.3
uri-template==1.3.0
urllib3==2.7.0
wasabi==1.1.3
wcwidth==0.8.2
weasel==1.0.0
webcolors==25.10.0
webencodings==0.5.1
websocket-client==1.9.0
wrapt==2.2.2
xarray==2025.4.0
xlrd==2.0.2
xyzservices==2026.3.0
yarl==1.24.5
```

---

## 3. SERVICE FOOTPRINT

### `systemctl list-units --type=service --state=running --no-pager --no-legend`
**MEASURED**
```
  code-interpreter.service loaded active running Code Interpreter Server
  dbus.service             loaded active running D-Bus System Message Bus
  envd.service             loaded active running Env Daemon Service
  getty@tty1.service       loaded active running Getty on tty1
  jupyter.service          loaded active running Jupyter Server
  nfs-blkmap.service       loaded active running pNFS block layout mapping daemon
  rpcbind.service          loaded active running RPC bind portmap service
  ssh.service              loaded active running OpenBSD Secure Shell server
  systemd-journald.service loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-networkd.service loaded active running Network Configuration
```

### listening sockets: `ss -tlnp`
**MEASURED**
```
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      100        127.0.0.1:35769      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:47945      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:34675      0.0.0.0:*          
LISTEN 0      4096         0.0.0.0:111        0.0.0.0:*          
LISTEN 0      5       169.254.0.21:35769      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:47945      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:34675      0.0.0.0:*          
LISTEN 0      128        127.0.0.1:8888       0.0.0.0:*          
LISTEN 0      5       169.254.0.21:8888       0.0.0.0:*          
LISTEN 0      100        127.0.0.1:44461      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:35105      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:39379      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:41435      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:43501      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:35105      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:44461      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:39379      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:41435      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:43501      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:60465      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:53335      0.0.0.0:*          
LISTEN 0      5       169.254.0.21:60493      0.0.0.0:*          
LISTEN 0      2048         0.0.0.0:49999      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:60465      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:60493      0.0.0.0:*          
LISTEN 0      100        127.0.0.1:53335      0.0.0.0:*          
LISTEN 0      4096            [::]:111           [::]:*          
LISTEN 0      4096               *:22               *:*          
LISTEN 0      128            [::1]:8888          [::]:*          
LISTEN 0      4096               *:49983            *:*          
```
(Note: `ss` did not show process column content in this environment.)

### unit file path and ExecStart for envd / jupyter / code-interpreter
**MEASURED** `systemctl cat envd` / `jupyter` / `code-interpreter` and `systemctl show …`

**envd**
- FragmentPath: `/etc/systemd/system/envd.service`
- ExecStart: `/usr/bin/envd`
- ExecStartPre (verbatim from unit):  
  `/bin/sh -c 'mountpoint -q /etc/ssl/certs || { mkdir -p /run/e2b/certs && { tar -C /run/e2b/certs -xf /usr/local/share/e2b/ssl-certs.tar 2>/dev/null || cp -a /etc/ssl/certs/. /run/e2b/certs/ 2>/dev/null; }; mount --bind /run/e2b/certs /etc/ssl/certs; } && ([ -s /etc/ssl/certs/ca-certificates.crt ] || update-ca-certificates)'`

**Full unit file** (`systemctl cat envd`):
```
# /etc/systemd/system/envd.service
[Unit]
Description=Env Daemon Service
# Start as early as possible on cold boot: envd only needs journald's socket
# and a writable rootfs; networking is configured by the kernel (ip=) before
# userspace. Default dependencies would gate it on sysinit/basic.target
# (~0.5s), and the previous After=multi-user.target on chrony-wait (~8s).
DefaultDependencies=no
# Order after /tmp is finalized so envd doesn't answer before it's safe to stage
# files there: updateEnvd uploads an update binary to /tmp during early boot.
# On our base images (Ubuntu/Debian) /tmp is a plain rootfs dir, not a tmpfs
# mount, and systemd-tmpfiles-setup.service runs `systemd-tmpfiles --remove`
# with a `D /tmp` rule that wipes /tmp's contents at boot. That service is only
# ordered After=local-fs.target, so gating envd on local-fs.target alone leaves
# them unordered and the upload races the wipe (chmod/mv then fail ENOENT).
# Ordering after systemd-tmpfiles-setup.service closes that race.
After=systemd-journald.socket systemd-remount-fs.service local-fs.target systemd-tmpfiles-setup.service
Wants=systemd-journald.socket
Conflicts=shutdown.target
Before=shutdown.target
# Disable rate limiting; retry forever
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
User=root
Group=root
Environment=GOTRACEBACK=all
LimitCORE=infinity
# Seed the tmpfs from the tar packed as the build's last guest step — after all
# build steps, start_cmd, and ready_cmd, with update-ca-certificates run first
# (one sequential read); fall back to copying the cert dir, then to regenerating.
#
# Contract: the tar is the regenerated trust store captured at the end of the
# build, so it equals what update-ca-certificates would produce at boot —
# including CAs added in user layers or start/ready, registered or not. Seeding
# from it gives a complete ca-certificates.crt, so update-ca-certificates is
# skipped on cold boot (its scattered rootfs reads are the cost we avoid). It
# therefore does NOT re-merge a persisted egress-proxy CA
# (/usr/local/share/ca-certificates/e2b-ca.crt) into the bundle at boot. That CA
# is (re)installed by envd's POST /init for the current proxy, which runs before
# the orchestrator marks the sandbox running/routable — so the egress CA is
# guaranteed present for the sandbox's routable lifetime. The only gap is guest
# units that auto-start and egress over TLS before /init; that is accepted
# (revisit if a template needs boot-time egress).
ExecStartPre=/bin/sh -c 'mountpoint -q /etc/ssl/certs || { mkdir -p /run/e2b/certs && { tar -C /run/e2b/certs -xf /usr/local/share/e2b/ssl-certs.tar 2>/dev/null || cp -a /etc/ssl/certs/. /run/e2b/certs/ 2>/dev/null; }; mount --bind /run/e2b/certs /etc/ssl/certs; } && ([ -s /etc/ssl/certs/ca-certificates.crt ] || update-ca-certificates)'
ExecStart=/usr/bin/envd
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=4
OOMPolicy=continue
OOMScoreAdjust=-1000
Environment="GOMEMLIMIT=512MiB"

Delegate=yes
MemoryMin=50M
MemoryLow=100M
CPUAccounting=yes
CPUWeight=1000
IOAccounting=yes
IOWeight=10000

[Install]
WantedBy=multi-user.target
```

**jupyter**
- FragmentPath: `/etc/systemd/system/jupyter.service`
- ExecStart: `/usr/local/bin/jupyter server --IdentityProvider.token=""`

**Full unit file** (`systemctl cat jupyter`):
```
# /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Server
Documentation=https://jupyter-server.readthedocs.io
Wants=code-interpreter.service
StartLimitBurst=0

[Service]
Type=simple
Environment=MATPLOTLIBRC=/root/.config/matplotlib/.matplotlibrc
ExecStart=/usr/local/bin/jupyter server --IdentityProvider.token=""
ExecStartPost=-/usr/bin/systemctl reset-failed code-interpreter
Restart=on-failure
RestartSec=1
StandardOutput=null
StandardError=journal
```

**code-interpreter**
- FragmentPath: `/etc/systemd/system/code-interpreter.service`
- ExecStart: `/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640`
- WorkingDirectory: `/root/.server`
- Documentation=https://github.com/e2b-dev/code-interpreter

**Full unit file** (`systemctl cat code-interpreter`):
```
# /etc/systemd/system/code-interpreter.service
[Unit]
Description=Code Interpreter Server
Documentation=https://github.com/e2b-dev/code-interpreter
Requires=jupyter.service
After=jupyter.service
PartOf=jupyter.service
StartLimitBurst=0

[Service]
Type=simple
WorkingDirectory=/root/.server
ExecStartPre=/root/.jupyter/jupyter-healthcheck.sh
ExecStart=/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640
Restart=on-failure
RestartSec=1
StandardOutput=journal
StandardError=journal
```

### `systemctl show … -p ActiveEnterTimestamp` vs boot
**MEASURED**
```
envd ActiveEnterTimestamp=Thu 2026-07-23 18:05:37 UTC
jupyter ActiveEnterTimestamp=Thu 2026-07-23 18:05:39 UTC
code-interpreter ActiveEnterTimestamp=Thu 2026-07-23 18:05:41 UTC
```

**MEASURED** full `systemctl show` details:
```
UNIT=envd
ExecStart={ path=/usr/bin/envd ; argv[]=/usr/bin/envd ; ignore_errors=no ; start_time=[Thu 2026-07-23 18:05:37 UTC] ; stop_time=[n/a] ; pid=359 ; code=(null) ; status=0/0 }
ActiveState=active
FragmentPath=/etc/systemd/system/envd.service
ActiveEnterTimestamp=Thu 2026-07-23 18:05:37 UTC
---
UNIT=jupyter
ExecStart={ path=/usr/local/bin/jupyter ; argv[]=/usr/local/bin/jupyter server --IdentityProvider.token= ; ignore_errors=no ; start_time=[Thu 2026-07-23 18:05:39 UTC] ; stop_time=[n/a] ; pid=437 ; code=(null) ; status=0/0 }
ActiveState=active
FragmentPath=/etc/systemd/system/jupyter.service
ActiveEnterTimestamp=Thu 2026-07-23 18:05:39 UTC
---
UNIT=code-interpreter
ExecStart={ path=/root/.server/.venv/bin/uvicorn ; argv[]=/root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640 ; ignore_errors=no ; start_time=[Thu 2026-07-23 18:05:41 UTC] ; stop_time=[n/a] ; pid=463 ; code=(null) ; status=0/0 }
ActiveState=active
FragmentPath=/etc/systemd/system/code-interpreter.service
ActiveEnterTimestamp=Thu 2026-07-23 18:05:41 UTC
```

**MEASURED** current boot start: `uptime -s` → `2026-09-04 19:16:12`  
**MEASURED** `/proc/uptime` at first sample ≈ `12.82` seconds since boot.

**INFERRED** (comparison only, as requested):  
ActiveEnterTimestamp for envd / jupyter / code-interpreter is `2026-07-23 18:05:3x UTC`.  
Current boot began `2026-09-04 19:16:12`.  
`2026-07-23` is earlier than `2026-09-04`, therefore **all three service ActiveEnterTimestamps predate the current boot** (timestamps were not reset on this boot; they retain the earlier image/snapshot time).

---

## 4. SELF-DESCRIPTION

### `grep -rIl -m1 -iE 'arena|lmarena|e2b' /etc /opt /usr/local 2>/dev/null | head -50`
**MEASURED** (file list):
```
/etc/apt/trusted.gpg.d/debian-archive-bullseye-automatic.asc
/etc/apt/trusted.gpg.d/debian-archive-trixie-security-automatic.asc
/etc/ssh/moduli
/etc/ssl/certs/ca-certificates.crt
/etc/systemd/system/envd.service
/etc/systemd/system/code-interpreter.service
/etc/hostname
/etc/hosts
/etc/inittab
/usr/local/include/python3.13/cpython/objimpl.h
/usr/local/include/python3.13/internal/mimalloc/mimalloc/internal.h
/usr/local/include/python3.13/internal/mimalloc/mimalloc/types.h
/usr/local/include/python3.13/internal/mimalloc/mimalloc.h
/usr/local/include/python3.13/internal/pycore_asdl.h
/usr/local/include/python3.13/internal/pycore_ast.h
/usr/local/include/python3.13/internal/pycore_ceval_state.h
/usr/local/include/python3.13/internal/pycore_compile.h
/usr/local/include/python3.13/internal/pycore_interp.h
/usr/local/include/python3.13/internal/pycore_obmalloc.h
/usr/local/include/python3.13/internal/pycore_optimizer.h
/usr/local/include/python3.13/internal/pycore_parser.h
/usr/local/include/python3.13/internal/pycore_pyarena.h
/usr/local/include/python3.13/internal/pycore_pymem.h
/usr/local/include/python3.13/internal/pycore_pymem_init.h
/usr/local/include/python3.13/internal/pycore_runtime_init.h
/usr/local/lib/R/site-library/jsonlite/doc/json-aaquickstart.html
/usr/local/lib/R/site-library/jsonlite/doc/json-apis.html
/usr/local/lib/R/site-library/jsonlite/doc/json-paging.html
/usr/local/lib/R/site-library/vctrs/doc/type-size.html
/usr/local/lib/python3.13/config-3.13-x86_64-linux-gnu/Makefile
/usr/local/lib/python3.13/config-3.13-x86_64-linux-gnu/Setup
/usr/local/lib/python3.13/config-3.13-x86_64-linux-gnu/Setup.stdlib
/usr/local/lib/python3.13/encodings/cp874.py
/usr/local/lib/python3.13/encodings/iso8859_11.py
/usr/local/lib/python3.13/encodings/tis_620.py
/usr/local/lib/python3.13/multiprocessing/heap.py
/usr/local/lib/python3.13/site-packages/pip-26.1.2.dist-info/licenses/AUTHORS.txt
/usr/local/lib/python3.13/site-packages/pip/_vendor/certifi/cacert.pem
/usr/local/lib/python3.13/site-packages/pip/_vendor/idna/idnadata.py
/usr/local/lib/python3.13/site-packages/pip/_vendor/idna/uts46data.py
/usr/local/lib/python3.13/site-packages/pip/_vendor/pygments/unistring.py
/usr/local/lib/python3.13/site-packages/pytz/__init__.py
/usr/local/lib/python3.13/site-packages/pytz/zoneinfo/tzdata.zi
/usr/local/lib/python3.13/site-packages/pytz/zoneinfo/zone.tab
/usr/local/lib/python3.13/site-packages/pytz/zoneinfo/zone1970.tab
/usr/local/lib/python3.13/site-packages/pytz-2025.2.dist-info/RECORD
/usr/local/lib/python3.13/site-packages/tzdata/zones
/usr/local/lib/python3.13/site-packages/tzdata/zoneinfo/tzdata.zi
/usr/local/lib/python3.13/site-packages/tzdata/zoneinfo/zone.tab
/usr/local/lib/python3.13/site-packages/tzdata/zoneinfo/zone1970.tab
```

### matching lines for anything that is not an E2B library
**MEASURED** (non-noise / non-library product hits only):

`/etc/systemd/system/envd.service`:
```
# (/usr/local/share/ca-certificates/e2b-ca.crt) into the bundle at boot. That CA
ExecStartPre=... /run/e2b/certs ... /usr/local/share/e2b/ssl-certs.tar ...
```

`/etc/systemd/system/code-interpreter.service`:
```
Documentation=https://github.com/e2b-dev/code-interpreter
```

`/etc/hostname`:
```
e2b.local
```

`/etc/hosts`:
```
127.0.1.1        e2b.local
192.0.2.1        events.e2b.local
```

`/etc/inittab`:
```
::wait:/bin/sh -c 'echo "E2B_PROVISIONING_EXIT:$(cat /provision.result || printf 1)"'
```

**MEASURED** additional e2b paths:
```
/usr/local/share/ca-certificates/e2b-ca.crt
/usr/local/share/e2b/ssl-certs.tar
/usr/local/lib/python3.13/site-packages/e2b_charts
/usr/local/lib/python3.13/site-packages/e2b_charts-1.0.0.dist-info
/usr/bin/envd
```

**MEASURED** `ls -la /usr/local/share/e2b`:
```
total 620
drwxr-xr-x 2 root root     60 Jul 23 18:05 .
drwxrwxrwx 8 root root    128 Jul 23 18:05 ..
-rw-r--r-- 1 root root 634880 Jul 23 18:05 ssl-certs.tar
```

**MEASURED** `ls -la /usr/bin/envd`:
```
-rwxr-xr-x 1 root root 12800126 Jul 23 17:59 /usr/bin/envd
```

**MEASURED** `grep -rI -m1 -iE 'lmarena|arena\.ai|/arena' /etc /opt /usr/local 2>/dev/null | head -30`:
```
/usr/local/lib/python3.13/config-3.13-x86_64-linux-gnu/Makefile:		$(srcdir)/Objects/mimalloc/arena.c \
```
(no `lmarena` / `arena.ai` product string found under those trees)

### `$HOME` contents including dotfiles: `ls -la ~`
**MEASURED** (before probe write):
```
total 0
drwx------ 2 user user 128 Sep  4 19:16 .
drwxr-xr-x 3 root root  60 Jul 23 15:09 ..
```
**MEASURED** (after probe write):
```
total 5
drwx------ 2 user user 128 Sep  4 19:17 .
drwxr-xr-x 3 root root  60 Jul 23 15:09 ..
-rw-r--r-- 1 user user 242 Sep  4 19:17 prov_probe.txt
```

### `/code` directory contents if present
**MEASURED** `ls -la /code`
```
total 4
drwxrwxrwx  2 root root   60 Jul 23 18:05 .
drwxr-xr-x 19 root root 4096 Jul 23 18:05 ..
```
(empty directory)

---

## 5. STABILITY ACROSS TURNS

**MEASURED** wrote `/home/user/prov_probe.txt` and printed it:

**Command used:**
```sh
BOOT_ID=$(cat /proc/sys/kernel/random/boot_id)
SANDBOX_ID=$(printenv E2B_SANDBOX_ID)
E2B_CONTENTS=$(cat /.e2b)
TS=$(date -u +%FT%TZ)
printf '%s\n' "boot_id=$BOOT_ID" "E2B_SANDBOX_ID=$SANDBOX_ID" "=== /.e2b ===" "$E2B_CONTENTS" "=== timestamp ===" "$TS" > /home/user/prov_probe.txt
cat /home/user/prov_probe.txt
```

**Contents of `/home/user/prov_probe.txt`:**
```
boot_id=2bb79165-136a-4b63-829d-17027b0a8e40
E2B_SANDBOX_ID=ibbwxrhn0lpoi9ybz9fru
=== /.e2b ===
ENV_ID=nlhz8vlwyupq845jsdg9
TEMPLATE_ID=nlhz8vlwyupq845jsdg9
BUILD_ID=f34a5416-ef30-4cb7-8e18-0fdecd6eb529
=== timestamp ===
2026-09-04T19:17:02Z
```

---

## Notes on labeling

- **MEASURED**: command was run in this sandbox; output is verbatim from stdout/stderr.
- **INFERRED**: only the ActiveEnterTimestamp vs current-boot comparison in section 3, as explicitly requested by the original brief.
- Failed command fragments are included verbatim (e.g. missing `/etc/apt/sources.list`).
