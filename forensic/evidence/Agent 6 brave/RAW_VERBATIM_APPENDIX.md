# Raw Probe Transcripts — Verbatim Appendix (v2)

**Purpose:** primary evidence for `environment_characterization.md`. Every block below is the byte-for-byte content of a raw probe file from `/home/user/envprobe/`, html-escaped only for safe rendering (no summarisation, no editing).

**Integrity:** files were hashed at run-1 end and re-verified after snapshot restore (turn 2) — byte-identical:
```bash
cd /home/user/envprobe && sha256sum -c sha256sums.txt
```

**Run-1 metadata** (see `manifest.json` for full provenance):

- Run window: `2026-09-04T11:15:36Z` → `2026-09-04T11:23:05Z` (parsed from file contents; mtimes reflect snapshot materialization, not write time)
- Sandbox ID: `idxwgcmp6a9ioo1823yuk` · Template ID: `nlhz8vlwyupq845jsdg9` · boot_id: `2bb79165-136a-4b63-829d-17027b0a8e40` (template-constant: identical on a second VM instance)
- Verification session (manifest generated `2026-09-04T13:45:39Z`): sandbox `i9nxb4qydn3qmwway6hd3`, template `nlhz8vlwyupq845jsdg9` — same files, new VM instance; only /home/user persisted (measured)
- File count: 18 · total bytes: 45032

## File index (bytes · SHA-256)

| file | bytes | sha256 |
|---|---:|---|
| `01_runtime.txt` | 4416 | `41490d0ec9cff99079f450ca7064056caef5ffb40b35aa0ff4b2779b16d1a624` |
| `02_identity.txt` | 5648 | `715d6551dde1c300df0a2d6ea5191202fe90f59e4506e3c73fe83c1d276b4ea4` |
| `03_tools.txt` | 3609 | `9a2fa02d5f9d6b22653d7ff95e5b5270ff92ed6bb46a4c6fc738b23d4b90a438` |
| `04_fs.txt` | 2829 | `10eac5bf48afb9b88643361daf049b005968d6545ea16ff6918ea6cf36481858` |
| `05_cpu_mem.txt` | 1176 | `1a8e8f4d5b1c884c1613de30a61d8ab59cf111c93d8dc21e4b8c811d3da9a0b5` |
| `06_compilers_pkgs.txt` | 2652 | `2fc038ac0fd666c78a0fed7c4a38ec7248d76db8e576afe194db81d77b3625b0` |
| `07_cgroup_sudo.txt` | 4543 | `d81e818da04ef3a44a567e72b8aabaeb442288de6098739f880a1e0a5b51cd3b` |
| `09_net_matrix.txt` | 4200 | `2df76c1306f1052abe3f8f95666ef76f3c929b441ad53e1e51ec964d99a4de57` |
| `10_net_throughput.txt` | 2836 | `b36f15f978bfb78951777850e11129a99f4d2cc281a090806b3c7a149600b7b0` |
| `10b_net_throughput2.txt` | 1614 | `748b98e7270e9594529c481871e9809743f0bb12814ccca0bbfb33a24535a982` |
| `11_disk.txt` | 1512 | `e08542eed1485e2c1548361db83ea14005b9e444094f8e3263879fcde236b1f1` |
| `12_pip.txt` | 2132 | `8567335975028044c67238ed5955694d57ac1c1e0cb7cd7e3e0ea54cc28bda65` |
| `12b_pip2.txt` | 2649 | `9901556f0a0f4ccd9e4248d90f43c61c22a2e57c0d316b9e1188c1f6c154653b` |
| `13_bg_misc.txt` | 2432 | `5d9b91c8850d014d568aaa9dd114cbbf31d9c25c58e151a5ff65352235f0b352` |
| `14_final.txt` | 1853 | `e8d5837cb9eb5276b1deb334419359631bbea4e9617930e6fc8f76fd4ea23d52` |
| `15_process_demo.txt` | 625 | `302f1dcf9fb62eac00aedd012e4e475f6a33905e38e71653b7653d6d80ae1aff` |
| `bg_ticks.txt` | 273 | `0a592e54fbe6c772aff9a42d92eee6314023a2a2cba643ff78ac84a23b5fd0c0` |
| `.persist_marker` | 33 | `973bb258c943aacb33276c0927ab8c4a994785785699e2e459b9ca1557a98b1a` |

---

## `01_runtime.txt`  _(4416 bytes · sha256 `41490d0ec9`…`d1a624`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
### probe 01 timestamp: 2026-09-04T11:15:36Z | sandbox-local: 2026-09-04T11:15:36 UTC

== uname -a ==
Linux e2b.local 6.1.158+ #1 SMP PREEMPT_DYNAMIC Fri Jul 17 14:31:34 UTC 2026 x86_64 GNU/Linux

== /etc/os-release ==
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.6
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

== /etc/debian_version ==
13.6

== libc ==
ldd (Debian GLIBC 2.41-12+deb13u3) 2.41
-rwxr-xr-x 1 root root 1995216 Apr 27 20:09 /lib/x86_64-linux-gnu/libc.so.6

== container markers ==
  ls: cannot access '/.dockerenv': No such file or directory
no /run/.containerenv
  /proc/1/cgroup   : 0::/init.scope 
  /proc/self/cgroup: 0::/user 
  /proc/1/comm     : systemd
  /proc/1/cmdline  : /sbin/init 

== virtualization hints ==
kvm
cpuinfo: 'hypervisor' flag present (VM guest)

== /proc/mounts (full) ==
/dev/root / ext4 rw,relatime,discard 0 0
devtmpfs /dev devtmpfs rw,relatime,size=1013452k,nr_inodes=253363,mode=755 0 0
proc /proc proc rw,nosuid,nodev,noexec,relatime 0 0
sysfs /sys sysfs rw,nosuid,nodev,noexec,relatime 0 0
securityfs /sys/kernel/security securityfs rw,nosuid,nodev,noexec,relatime 0 0
selinuxfs /sys/fs/selinux selinuxfs rw,nosuid,noexec,relatime 0 0
tmpfs /dev/shm tmpfs rw,nosuid,nodev 0 0
devpts /dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=600,ptmxmode=000 0 0
tmpfs /run tmpfs rw,nosuid,nodev,size=406524k,nr_inodes=819200,mode=755 0 0
cgroup2 /sys/fs/cgroup cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot 0 0
pstore /sys/fs/pstore pstore rw,nosuid,nodev,noexec,relatime 0 0
bpf /sys/fs/bpf bpf rw,nosuid,nodev,noexec,relatime,mode=700 0 0
systemd-1 /proc/sys/fs/binfmt_misc autofs rw,relatime,fd=36,pgrp=1,timeout=0,minproto=5,maxproto=5,direct 0 0
mqueue /dev/mqueue mqueue rw,nosuid,nodev,noexec,relatime 0 0
debugfs /sys/kernel/debug debugfs rw,nosuid,nodev,noexec,relatime 0 0
tracefs /sys/kernel/tracing tracefs rw,nosuid,nodev,noexec,relatime 0 0
hugetlbfs /dev/hugepages hugetlbfs rw,nosuid,nodev,relatime,pagesize=2M 0 0
tmpfs /tmp tmpfs rw,nosuid,nodev,nr_inodes=1048576 0 0
tmpfs /run/lock tmpfs rw,nosuid,nodev,noexec,relatime,size=5120k 0 0
fusectl /sys/fs/fuse/connections fusectl rw,nosuid,nodev,noexec,relatime 0 0
ramfs /run/credentials/systemd-journald.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0
ramfs /run/credentials/systemd-networkd.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0
tmpfs /etc/ssl/certs tmpfs rw,nosuid,nodev,size=406524k,nr_inodes=819200,mode=755 0 0
sunrpc /run/rpc_pipefs rpc_pipefs rw,relatime 0 0
ramfs /run/credentials/getty@tty1.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0

== cgroup v2 ==
controllers: cpuset cpu io memory hugetlb pids
subtree:     cpuset cpu io memory pids

== hostname / hosts / resolv.conf ==
e2b.local
127.0.0.1        localhost
::1              localhost ip6-localhost ip6-loopback
fe00::           ip6-localnet
ff00::           ip6-mcastprefix
ff02::1          ip6-allnodes
ff02::2          ip6-allrouters
127.0.1.1        e2b.local
192.0.2.1        events.e2b.local
nameserver 8.8.8.8
== ipv6 ==
IPv6 enabled
00000000000000000000000000000001 01 80 10 80       lo
fe8000000000000000fc00fffe000005 02 40 20 80     eth0

== net dev ==
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:   81120     621    0    0    0     0          0         0    81120     621    0    0    0     0       0          0
  eth0:  130881    1093    0    0    0     0          0         0   164375    1052    0    0    0     0       0          0

== route table (ipv4, hex) ==
Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT                                                       
eth0	00000000	1600FEA9	0003	0	0	0	00000000	0	0	0                                                                               
eth0	1400FEA9	00000000	0001	0	0	0	FCFFFFFF	0	0	0                                                                               

== misc kernel info ==
boot_id: 2bb79165-136a-4b63-829d-17027b0a8e40
clocksource: kvm-clock
timezone file: n/a

</pre>

</details>

## `02_identity.txt`  _(5648 bytes · sha256 `715d6551dd`…`6b4ea4`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== id / user ==
uid=1000(user) gid=1000(user) groups=1000(user),27(sudo),100(users)
whoami: user
uid=1000 gid=1000

== sudo test (non-interactive) ==
SUDO: passwordless root available

== /proc/self/status key lines ==
Uid:	1000	1000	1000	1000
Gid:	1000	1000	1000	1000
Groups:	27 100 1000 1000 
Threads:	1
SigQ:	0/7917
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	000001ffffffffff
NoNewPrivs:	0
Seccomp:	0
Seccomp_filters:	0
Cpus_allowed_list:	0-1
Mems_allowed_list:	0

== capability decode of self ==
CapEff = 0x0 ; set: NONE
CapBnd = 0x1ffffffffff ; set: ['chown', 'dac_override', 'dac_read_search', 'fowner', 'fsetid', 'kill', 'setgid', 'setuid', 'setpcap', 'linux_immutable', 'net_bind_service', 'net_broadcast', 'net_admin', 'net_raw', 'ipc_lock', 'ipc_owner', 'sys_module', 'sys_rawio', 'sys_chroot', 'sys_ptrace', 'sys_pacct', 'sys_admin', 'sys_boot', 'sys_nice', 'sys_resource', 'sys_time', 'sys_tty_config', 'mknod', 'lease', 'audit_write', 'audit_control', 'setfcap', 'mac_override', 'mac_admin', 'syslog', 'wake_alarm', 'block_suspend', 'audit_read', 'perfmon', 'bpf', 'checkpoint_restore']
CapPrm = 0x0 ; set: NONE

== LSM / seccomp ==
  Seccomp:	0
  Seccomp_filters:	0
/bin/bash: line 22: warning: command substitution: ignored null byte in input
  apparmor current: kernel

== ulimit -a ==
real-time non-blocking time  (microseconds, -R) unlimited
core file size              (blocks, -c) 0
data seg size               (kbytes, -d) unlimited
scheduling priority                 (-e) 0
file size                   (blocks, -f) unlimited
pending signals                     (-i) 7917
max locked memory           (kbytes, -l) 8192
max memory size             (kbytes, -m) unlimited
open files                          (-n) 1024
pipe size                (512 bytes, -p) 8
POSIX message queues         (bytes, -q) 819200
real-time priority                  (-r) 0
stack size                  (kbytes, -s) 8192
cpu time                   (seconds, -t) unlimited
max user processes                  (-u) 7917
virtual memory              (kbytes, -v) unlimited
file locks                          (-x) unlimited

== RLIMITs ==
Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        0                    0                    bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             7917                 7917                 processes 
Max open files            1024                 524288               files     
Max locked memory         8388608              8388608              bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       7917                 7917                 signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us        

== cgroup limits ==
memory.max:       n/a
memory.high:      n/a
memory.current:   n/a
memory.swap.max:  n/a
memory.peak:      n/a
memory.events:    n/a
cpu.max:          n/a
cpu.stat:         usage_usec 9105281
user_usec 5210468
system_usec 3894812
nr_periods 0
nr_throttled 0
throttled_usec 0
nr_bursts 0
burst_usec 0
pids.max:         n/a
pids.current:     n/a

== cpuset ==
effective cpus: 0-1
pid 1434's current affinity list: 0,1

== cpuinfo ==
logical CPUs: 2
model name	: Intel(R) Xeon(R) Processor @ 2.60GHz
cpu MHz		: 2600.028
simd flags: aes avx2 avx512f fma sse4_2 

== meminfo ==
MemTotal:        2032608 kB
MemFree:         1341136 kB
MemAvailable:    1524964 kB
Buffers:           60552 kB
Cached:           177132 kB
SwapTotal:             0 kB
SwapFree:              0 kB

== loadavg ==
0.06 0.02 0.00 1/143 1476

== top processes by mem ==
    PID    PPID USER     %CPU %MEM     ELAPSED COMMAND
    437       1 root      0.7  4.8       04:20 jupyter-server
    475     437 root      0.2  3.6       04:16 python3.13
    463       1 root      0.3  3.2       04:18 uvicorn
    490     437 root      0.1  2.8       04:16 node
    504     490 root      0.0  1.9       04:15 node
    359       1 root      0.6  1.2       04:21 envd
      1       0 root      0.0  0.6       04:22 systemd
    308       1 systemd+  0.0  0.5       04:21 systemd-network
    290       1 root      0.0  0.4       04:22 systemd-journal
    387       1 root      0.0  0.3       04:21 sshd
    341       1 root      0.0  0.3       04:21 systemd-logind

== env (sorted, secrets redacted) ==
E2B_EVENTS_ADDRESS=http://192.0.2.1
E2B_SANDBOX=true
E2B_SANDBOX_ID=idxwgcmp6a9ioo1823yuk
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
HOME=/home/user
LOGNAME=user
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
PS1=\w $ 
PWD=/home/user
SHELL=/bin/bash
SHLVL=1
USER=user
_=/usr/bin/env

== k8s/sandbox env hints ==
E2B_TEMPLATE_ID=nlhz8vlwyupq845jsdg9
E2B_EVENTS_ADDRESS=http://192.0.2.1
E2B_SANDBOX_ID=idxwgcmp6a9ioo1823yuk
E2B_SANDBOX=true

== /var/run/secrets? ==
absent

== passwd users ==
root:0
daemon:1
bin:2
sys:3
sync:4
games:5
man:6
lp:7

== dotdirs in home ==

</pre>

</details>

## `03_tools.txt`  _(3609 bytes · sha256 `9a2fa02d5f`…`90a438`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== tool availability + versions (probed 2026-09-04T11:15:45Z) ==
python3        Python 3.13.14
python3.11     MISSING
python3.12     MISSING
python3.13     Python 3.13.14
pip            pip 26.1.2 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
pip3           pip 26.1.2 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
node           v20.20.2
npm            10.8.2
npx            10.8.2
yarn           MISSING
pnpm           MISSING
bun            MISSING
deno           MISSING
git            git version 2.47.3
curl           curl 8.14.1 (x86_64-pc-linux-gnu) libcurl/8.14.1 OpenSSL/3.5.6 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.8 libpsl/0.21.2 libssh2/1.11.1 nghttp2/1.64.0 nghttp3/1.8.0 librtmp/2.3 OpenLDAP/2.6.10
wget           GNU Wget 1.25.0 built on linux-gnu.
aria2c         MISSING
ffmpeg         MISSING
docker         MISSING
podman         MISSING
make           GNU Make 4.4.1
gcc            gcc (Debian 14.2.0-19) 14.2.0
g++            g++ (Debian 14.2.0-19) 14.2.0
cc             cc (Debian 14.2.0-19) 14.2.0
clang          MISSING
cmake          MISSING
ninja          MISSING
pkg-config     1.8.1
jq             jq-1.7
yq             MISSING
unzip          UnZip 6.00 of 20 April 2009, by Debian. Original by Info-ZIP.
zip            Copyright (c) 1990-2008 Info-ZIP - Type 'zip "-L"' for software license.
tar            tar (GNU tar) 1.35
xz             xz (XZ Utils) 5.8.1
gzip           gzip 1.13
bzip2          (runs, no --version output)
zstd           MISSING
rsync          MISSING
openssl        OpenSSL 3.5.6 7 Apr 2026 (Library: OpenSSL 3.5.6 7 Apr 2026)
ssh            (runs, no --version output)
scp            (runs, no --version output)
socat          socat by Gerhard Rieger and contributors - see www.dest-unreach.org
ncat           MISSING
dig            MISSING
nslookup       MISSING
host           MISSING
getent         getent (Debian GLIBC 2.41-12+deb13u3) 2.41
ping           ping from iputils 20240905
traceroute     MISSING
mtr            MISSING
htop           MISSING
strace         MISSING
ltrace         MISSING
perf           MISSING
file           file-5.46
sqlite3        MISSING
redis-cli      MISSING
go             MISSING
rustc          MISSING
cargo          MISSING
java           openjdk 11 2018-09-25
javac          javac 11
ruby           MISSING
perl           Summary of my perl5 (revision 5 version 40 subversion 1) configuration:
php            MISSING
Rscript        Rscript (R) version 4.5.0 (2025-04-11)
julia          MISSING
autoconf       autoconf (GNU Autoconf) 2.72
automake       automake (GNU automake) 1.17
libtool        MISSING
bison          MISSING
flex           MISSING
screen         MISSING
tmux           MISSING
vim            MISSING
nano           MISSING
xxd            MISSING
bc             MISSING
time           (runs, no --version output)
timeout        timeout (GNU coreutils) 9.7
setsid         setsid from util-linux 2.41
flock          flock from util-linux 2.41
vmstat         vmstat from procps-ng 4.0.4
iostat         MISSING
ifconfig       MISSING
ip             ip utility, iproute2-6.15.0, libbpf 1.5.0
busybox        (runs, no --version output)

== language runtime details ==
python: 3.13.14 (main, Jul 14 2026, 04:45:36) [GCC 14.2.0]
impl: CPython | bits: 64
pip 26.1.2 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
node: v20.20.2
npm: 10.8.2
git version 2.47.3

== docker daemon reachable? ==
timeout: failed to run command 'docker': No such file or directory

== registry defaults ==
no pip/npm registry env overrides
https://registry.npmjs.org/

</pre>

</details>

## `04_fs.txt`  _(2829 bytes · sha256 `10eac5bf48`…`481858`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== cwd/home ==
/home/user
HOME=/home/user
TMPDIR=&lt;unset&gt;
SHELL=/bin/bash

== workspace contents ==
total 0
drwx------ 4 user user 128 Sep  4 11:15 .
drwxr-xr-x 3 root root  60 Jul 23 15:09 ..
drwxr-xr-x 3 user user  60 Sep  4 11:15 .npm
-rw-r--r-- 1 user user   0 Sep  4 11:15 .sudo_as_admin_successful
drwxr-xr-x 2 user user 128 Sep  4 11:15 envprobe

== df -h ==
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        25G  4.1G   20G  17% /
devtmpfs        990M     0  990M   0% /dev
tmpfs           993M     0  993M   0% /dev/shm
tmpfs           397M  324K  397M   1% /run
tmpfs           993M  8.0K  993M   1% /tmp
tmpfs           5.0M     0  5.0M   0% /run/lock

== df -i (inodes) ==
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/root      6759792 136301 6623491    3% /
devtmpfs        253363    137  253226    1% /dev
tmpfs           254076      1  254075    1% /dev/shm
tmpfs           819200    436  818764    1% /run
tmpfs          1048576     11 1048565    1% /tmp
tmpfs           254076      2  254074    1% /run/lock

== read-only mounts ==
ramfs /run/credentials/systemd-journald.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0
ramfs /run/credentials/systemd-networkd.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0
ramfs /run/credentials/getty@tty1.service ramfs ro,nosuid,nodev,noexec,relatime,nosymfollow,mode=700 0 0
(ro count: 3 / total 25)

== fs type per path ==
  /            ext2/ext3
  /home        ext2/ext3
  /home/user   ext2/ext3
  /tmp         tmpfs
  /var/tmp     ext2/ext3
  /dev/shm     tmpfs
  /proc        proc
  /sys         sysfs
  /etc         ext2/ext3
  /run         tmpfs

== /tmp + /dev/shm sizing ==
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           993M  8.0K  993M   1% /tmp
tmpfs           993M     0  993M   0% /dev/shm
/dev/root        25G  4.1G   20G  17% /

== write/read/delete probes ==
  /home/user : write OK (1048576 B) + chmod OK
  /home/user : delete OK
  /tmp : write OK (1048576 B) + chmod OK
  /tmp : delete OK
  /dev/shm : write OK (1048576 B) + chmod OK
  /dev/shm : delete OK
  /var/tmp : write OK (1048576 B) + chmod OK
  /var/tmp : delete OK

== link/fallocate ops in /home/user ==
  hardlink OK
  symlink OK
  fallocate 10MiB OK
total 10241
-rw-r--r-- 2 user user        2 Sep  4 11:15 a
-rw-r--r-- 2 user user        2 Sep  4 11:15 b
lrwxrwxrwx 1 user user        1 Sep  4 11:15 c -&gt; a
-rw-r--r-- 1 user user 10485760 Sep  4 11:15 fall.bin
  cleanup OK

== overlay / backing store ==

== protected-path writability (as current user) ==
  /etc: not writable
  /usr: not writable
  /var/log: not writable
  /root: not writable
  /boot: not writable
  /proc/sys: not writable

== persistence markers ==
  wrote: HOME marker 2026-09-04T11:15:50Z | TMP marker 2026-09-04T11:15:50Z

</pre>

</details>

## `05_cpu_mem.txt`  _(1176 bytes · sha256 `1a8e8f4d5b`…`a9a0b5`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== CPU micro-benchmarks (python 3.13.14, perf_counter, medians of 3) ==
sum(range(10**7))          :    140.6 ms median of 3
int-loop 3e6 (mod+add)     :    341.1 ms median of 3
json.dumps x200k           :    539.2 ms median of 3

== parallel speedup probe: 4x sum(range(10**7)) in parallel ==
  4-parallel wall: 0.33 s  (2 vCPUs available)

== single sequential run reference ==
  1 run wall: 0.17 s

== memory allocation ceiling probe ==
MemTotal:        2032608 kB
MemAvailable:    1550164 kB
cgroup memory.max: 1947172864 (/sys/fs/cgroup/user/memory.max)
  -&gt; cgroup budget headroom ~1626 MiB (current=242049024)
target: 1024 MiB (MemAvailable=1513 MiB)
allocated+touched 1024 MiB OK; after: MemAvailable=492 MiB -&gt; process survived, no OOM

== memory.events ==
low 0
high 0
max 0
oom 0
oom_kill 0
oom_group_kill 0

== vmstat 1 2 ==
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 1  0      0 1247092  61940 411616    0    0  1060   170  185    1  2  1 97  1  0  0
 1  0      0 1242536  62088 414440    0    0  2800   340  708  660 42  5 51  3  0  0

</pre>

</details>

## `06_compilers_pkgs.txt`  _(2652 bytes · sha256 `2fc038ac0f`…`3625b0`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== gcc hello world ==
compiled-binary-ok
gcc compile+run: OK
gcc (Debian 14.2.0-19) 14.2.0

== python dev headers ==
sysconfig include: /usr/local/include/python3.13
/usr/local/include/python3.13/Python.h
Python.h PRESENT -&gt; C-ext builds possible
/usr/local/include/python3.13

== headers sample ==
present: /usr/include/stdio.h
present: /usr/include/openssl/ssl.h

== make ==
GNU Make 4.4.1

== apt (via passwordless sudo) ==
/usr/bin/apt-get
sudo-&gt;root: uid=0
CapEff:	000001ffffffffff
Seccomp:	0
Seccomp_filters:	0
-- apt-get update (timed, quiet) --
Hit:5 https://deb.nodesource.com/node_20.x nodistro InRelease
Fetched 342 kB in 0s (2111 kB/s)
Reading package lists...
apt-get update rc=0, 0.7 s

== apt-cache: is ffmpeg available? ==
ffmpeg:
  Installed: (none)
  Candidate: 7:7.1.5-0+deb13u1
  Version table:

== DEMO: install a small system package (sqlite3 CLI) ==
Preparing to unpack .../sqlite3_3.46.1-7+deb13u1_amd64.deb ...
Unpacking sqlite3 (3.46.1-7+deb13u1) ...
Setting up sqlite3 (3.46.1-7+deb13u1) ...
apt install sqlite3: 2.2 s
3.46.1 2024-08-13 09:16:08 c9c2ab54ba1f5f46360f1b4f35d849cd3f080e6fc2b6c60e91b16c63f69aalt1 (64-bit)
sqlite3 now available

== other pkg mgrs ==
apk: absent
yum: absent
dnf: absent
pacman: absent
zypper: absent
conda: absent
mamba: absent
brew: absent
dpkg: /usr/bin/dpkg
rpm: absent

== dpkg arch ==
amd64

== systemd units (sanity) ==
  UNIT                                        LOAD   ACTIVE SUB     DESCRIPTION
â chronyd-restricted.service                  loaded failed failed  NTP client (restricted)
  code-interpreter.service                    loaded active running Code Interpreter Server
  dbus.service                                loaded active running D-Bus System Message Bus
  envd.service                                loaded active running Env Daemon Service
  getty@tty1.service                          loaded active running Getty on tty1
  jupyter.service                             loaded active running Jupyter Server
  nfs-blkmap.service                          loaded active running pNFS block layout mapping daemon
â nftables.service                            loaded failed failed  nftables
  rpc-statd-notify.service                    loaded active exited  Notify NFS peers of a restart
  rpcbind.service                             loaded active running RPC bind portmap service
  ssh.service                                 loaded active running OpenBSD Secure Shell server
  systemd-journal-flush.service               loaded active exited  Flush Journal to Persistent Storage
  systemd-journald.service                    loaded active running Journal Service

</pre>

</details>

## `07_cgroup_sudo.txt`  _(4543 bytes · sha256 `d81e818da0`…`51cd3b`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== cgroup v2 tree (delegated view) ==
total 0
dr-xr-xr-x 13 root root 0 Jul 23 18:05 .
drwxr-xr-x 10 root root 0 Jul 23 18:05 ..
-r--r--r--  1 root root 0 Jul 23 18:05 cgroup.controllers
-rw-r--r--  1 root root 0 Sep  4 11:16 cgroup.max.depth
-rw-r--r--  1 root root 0 Sep  4 11:16 cgroup.max.descendants
-rw-r--r--  1 root root 0 Jul 23 18:05 cgroup.procs
-r--r--r--  1 root root 0 Sep  4 11:16 cgroup.stat
-rw-r--r--  1 root root 0 Jul 23 18:05 cgroup.subtree_control
-rw-r--r--  1 root root 0 Sep  4 11:16 cgroup.threads
-r--r--r--  1 root root 0 Sep  4 11:15 cpu.stat
-r--r--r--  1 root root 0 Sep  4 11:15 cpuset.cpus.effective

== /sys/fs/cgroup/user/* limits ==
cgroup.procs:     2016 2071 2072 
cgroup.controllers:cpuset cpu io memory pids 
memory.max:       1947172864 
memory.current:   337137664 
memory.high:      1947172864 
memory.swap.max:  max 
memory.peak:      1345413120 
cpu.max:          max 100000 
cpu.stat:         usage_usec 11804838 user_usec 8842647 system_usec 2962191 
pids.max:         max 
pids.current:     10 
io.max:           

== our position in cgroup tree ==
0::/user

== which python / symlinks ==
/usr/local/bin/python3
/usr/bin/python3
/bin/python3
/usr/local/bin/python3.13
/usr/bin/python3.13
/bin/python3.13
/usr/local/bin/pip
/usr/local/bin/pip3
lrwxrwxrwx 1 root root    10 Jul 14 04:47 /usr/local/bin/python3 -&gt; python3.13
lrwxrwxrwx 1 root root    17 Jul 14 04:47 /usr/local/bin/python3-config -&gt; python3.13-config
-rwxrwxrwx 1 root root 18440 Jul 14 04:47 /usr/local/bin/python3.13
-rwxrwxrwx 1 root root  3127 Jul 14 04:47 /usr/local/bin/python3.13-config

== locale / arch / uptime ==
LANG=
LANGUAGE=
LC_CTYPE="POSIX"
LANG= LC_ALL=unset
amd64
 11:16:34 up 5 min,  0 users,  load average: 0.17, 0.04, 0.01

== systemd user session? ==
Failed to connect to user scope bus via local transport: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=&lt;user&gt;@.host --user to connect to bus of other user)

== listening sockets (ss) ==
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

== events endpoint reachability (192.0.2.1) ==
http_code=404 time=0.002385s

== nproc / cpu info cache ==
2
Architecture:                            x86_64
CPU op-mode(s):                          32-bit, 64-bit
Address sizes:                           46 bits physical, 48 bits virtual
Byte Order:                              Little Endian
CPU(s):                                  2
On-line CPU(s) list:                     0,1
Vendor ID:                               GenuineIntel
Model name:                              Intel(R) Xeon(R) Processor @ 2.60GHz
CPU family:                              6
Model:                                   106
Thread(s) per core:                      2
Core(s) per socket:                      1
Socket(s):                               1
Stepping:                                6
BogoMIPS:                                5200.05
Flags:                                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single ssbd ibrs ibpb stibp ibrs_enhanced fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm avx512f avx512dq rdseed adx smap avx512ifma clflushopt clwb avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves arat avx512vbmi umip avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq rdpid fsrm md_clear arch_capabilities
Hypervisor vendor:                       KVM
Virtualization type:                     full

</pre>

</details>

## `09_net_matrix.txt`  _(4200 bytes · sha256 `2df76c1306`…`a4de57`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== DNS timing: raw-UDP stub queries to 8.8.8.8  (5 reps, median) ==
  google.com                                   median    2.3 ms   min   1.1  max   18.8  (reps n=5)
  github.com                                   median    9.0 ms   min   1.1  max   19.7  (reps n=5)
  pypi.org                                     median    0.7 ms   min   0.5  max    0.8  (reps n=5)
  huggingface.co                               median   15.0 ms   min   0.9  max   23.3  (reps n=5)
  files.pythonhosted.org                       median    1.4 ms   min   1.1  max   10.2  (reps n=5)
  registry.npmjs.org                           median    0.7 ms   min   0.6  max    0.8  (reps n=5)
  deb.debian.org                               median    1.1 ms   min   1.1  max    1.3  (reps n=5)
  nonexistent-domain-xyzabc123.example.com     median   21.8 ms   min   1.4  max   26.4  (reps n=5)

== TCP connect RTT (7 reps, median) and UDP probes ==
  -- TCP connect RTT --
  8.8.8.8:443                               0.21 ms median  min   0.13  max   0.25  (7/7 ok)
  1.1.1.1:443                               0.16 ms median  min   0.14  max   0.32  (7/7 ok)
  google.com:443                            0.20 ms median  min   0.17  max   0.22  (7/7 ok)
  github.com:443                            0.16 ms median  min   0.12  max   0.19  (7/7 ok)
  github.com:22                             0.16 ms median  min   0.14  max   0.20  (7/7 ok)
  pypi.org:443                              0.17 ms median  min   0.12  max   0.29  (7/7 ok)
  huggingface.co:443                        0.17 ms median  min   0.14  max   0.31  (7/7 ok)
  registry.npmjs.org:443                    0.17 ms median  min   0.12  max   0.28  (7/7 ok)
  deb.debian.org:443                        0.17 ms median  min   0.15  max   0.20  (7/7 ok)
  files.pythonhosted.org:443                0.17 ms median  min   0.13  max   0.25  (7/7 ok)
  1.1.1.1:53                                0.14 ms median  min   0.14  max   0.17  (7/7 ok)
  -- UDP probes (send, wait 1.2s for any reply) --
  UDP 53 8.8.8.8 (valid DNS q) : reply 61B in 20.6 ms
  UDP 53 1.1.1.1 (valid DNS q) : reply 61B in 18.1 ms
  UDP 443 1.1.1.1 (QUIC-ish)   : no reply in 1.2s
  UDP 123 time.google.com (NTP): reply 48B in 0.7 ms

== ICMP ping 8.8.8.8 (sudo, 3 pings) ==
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2100ms
rtt min/avg/max/mdev = 0.406/0.529/0.617/0.089 ms

== IPv6 reachability ==
curl: (7) Failed to connect to www.google.com port 443 after 3 ms: Could not connect to server
  https://www.google.com over IPv6: http 000, 0.003102s

== TCP 443 matrix via curl (2 runs each: dns/conn/tls/ttfb/total) ==
  -- https://www.google.com/
    run1: code=200 dns=0.002440 conn=0.002676 tls=0.012553 ttfb=0.048977 total=0.050139 spd=1665789B/s
    run2: code=200 dns=0.001740 conn=0.002125 tls=0.011817 ttfb=0.047403 total=0.048470 spd=1720033B/s
  -- https://github.com/
    run1: code=200 dns=0.001222 conn=0.001464 tls=0.027772 ttfb=0.041212 total=0.103187 spd=5583377B/s
    run2: code=200 dns=0.001491 conn=0.001731 tls=0.017931 ttfb=0.025404 total=0.062892 spd=9160576B/s
  -- https://pypi.org/
    run1: code=200 dns=0.001115 conn=0.001372 tls=0.024378 ttfb=0.034294 total=0.036354 spd=769241B/s
    run2: code=200 dns=0.001156 conn=0.001394 tls=0.020432 ttfb=0.028950 total=0.030950 spd=903554B/s
  -- https://huggingface.co/
    run1: code=200 dns=0.019248 conn=0.019596 tls=0.039366 ttfb=0.049690 total=0.066301 spd=2745886B/s
    run2: code=200 dns=0.022293 conn=0.022660 tls=0.042057 ttfb=0.051678 total=0.068594 spd=2654095B/s
  -- https://registry.npmjs.org/
    run1: code=200 dns=0.001772 conn=0.002110 tls=0.062349 ttfb=0.088040 total=0.088126 spd=22B/s
    run2: code=200 dns=0.002752 conn=0.003088 tls=0.064261 ttfb=0.089578 total=0.089662 spd=22B/s
  -- https://deb.debian.org/
    run1: code=200 dns=0.001544 conn=0.001852 tls=0.019272 ttfb=0.027677 total=0.027742 spd=67623B/s
    run2: code=200 dns=0.001875 conn=0.002170 tls=0.024192 ttfb=0.037098 total=0.037162 spd=50481B/s

== plaintext HTTP ==
  http://google.com/ code=301 ttfb=0.011473s total=0.011504s
  http://deb.debian.org/ code=200 ttfb=0.018578s total=0.018697s

</pre>

</details>

## `10_net_throughput.txt`  _(2836 bytes · sha256 `b36f15f978`…`00b7b0`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== Throughput: real downloads (curl -w, HTTP/1.1, timed 11:18:51Z) ==
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    sz=52428800; sp=19279908; print(f'  {name:34s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {float(2.719349):6.2f}s  ttfb {float(0.179280)*1000:6.0f}ms  code=200')
                                         ^^^^
NameError: name 'name' is not defined
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    sz=52428800; sp=120402806; print(f'  {name:34s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {float(0.435445):6.2f}s  ttfb {float(0.117837)*1000:6.0f}ms  code=200')
                                          ^^^^
NameError: name 'name' is not defined
  File "&lt;string&gt;", line 1
    sz=curl: (6) Could not resolve host: speed.hetzner.de; sp=; print(f'  {name:34s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {float():6.2f}s  ttfb {float()*1000:6.0f}ms  code=')
           ^
SyntaxError: invalid syntax
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    sz=11370360; sp=6169819; print(f'  {name:34s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {float(1.842900):6.2f}s  ttfb {float(0.261816)*1000:6.0f}ms  code=200')
                                        ^^^^
NameError: name 'name' is not defined
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    sz=941; sp=8915; print(f'  {name:34s} {sz/1048576:8.2f} MiB  {sp/1048576:7.2f} MiB/s  total {float(0.105548):6.2f}s  ttfb {float(0.105382)*1000:6.0f}ms  code=302')
                                ^^^^
NameError: name 'name' is not defined

== upload test: cloudflare __up 20MiB ==
  upload 20MiB: speed=15580230B/s total=1.346034s code=200

== egress location probe (ipinfo; non-fatal) ==
{
  "ip": "34.143.70.112",
  "hostname": "112.70.143.34.bc.googleusercontent.com",
  "city": "The Dalles",
  "region": "Oregon",
  "country": "US",
  "loc": "45.5946,-121.1787",
  "org": "AS396982 Google LLC",
  "postal": "97058",
  "timezone": "America/Los_Angeles",
  "readme": "https://ipinfo.io/missingauth"
}

== ssh handshake egress test (port 22, github) ==
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).

== git clone (shallow, https) ==
  clone ok, 28 KiB in 0.70s

== node/npm registry install test (express, small tree) ==
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    sz=sum(os.path.getsize(os.path.join(r,f)) for r,_,fs in os.walk('/tmp/npmtest/node_modules') for f in fs) if os.path.isdir('/tmp/npmtest/node_modules') else 0
                                                                                                                 ^^
NameError: name 'os' is not defined. Did you forget to import 'os'?

</pre>

</details>

## `10b_net_throughput2.txt`  _(1614 bytes · sha256 `748b98e727`…`35a982`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== Throughput round 2 (fixed) 11:19:38Z ==
-- cloudflare __down 50 MiB, 3 runs --
  cloudflare 50MiB run1                       50.00 MiB    84.91 MiB/s  total   0.59s  ttfb    158 ms  code=200
  cloudflare 50MiB run2                       50.00 MiB   102.99 MiB/s  total   0.49s  ttfb    129 ms  code=200
  cloudflare 50MiB run3                       50.00 MiB   106.39 MiB/s  total   0.47s  ttfb     91 ms  code=200
-- huggingface with -L (gpt2 pytorch_model.bin, 5 MiB range) --
  HF gpt2 model.bin range5MiB                  5.00 MiB     9.96 MiB/s  total   0.50s  ttfb    255 ms  code=206
-- GCS bucket 100 MiB (googleapis; same-cloud) --
  GCS benchmark file 100MiB                    0.00 MiB     0.00 MiB/s  total   0.04s  ttfb     36 ms  code=404
-- hetzner retry + raw DNS checks --
  hetzner 100MB.bin retry                  FAILED: curl: (6) Could not resolve host: speed.hetzner.de
0|0|0.128030|0.000000|000
  raw DNS speed.hetzner.de: rcode=0 answers=0 in 155.0 ms
  raw DNS www.hetzner.com: rcode=0 answers=1 in 1.3 ms
  raw DNS pypi.org: rcode=0 answers=4 in 1.1 ms
-- pypi JSON + files.pythonhosted.org direct wheel --
  wheel: numpy-2.5.2-cp313-cp313-macosx_10_13_x86_64.whl
  pypi numpy wheel (~18MiB)                   16.10 MiB    51.98 MiB/s  total   0.31s  ttfb     40 ms  code=200
-- OVH (EU CDN) 100 MiB --
  OVH 100Mb.dat                              100.00 MiB    14.51 MiB/s  total   6.89s  ttfb    860 ms  code=200
-- npm install express result (re-measure) --
  express tree present: 2.2 MiB (installed 11:19:04)
-- APT effective rate (fresh update, timed) --
  apt-get update: 0.83s

</pre>

</details>

## `11_disk.txt`  _(1512 bytes · sha256 `e08542eed1`…`36b1f1`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== disk backend ==
  /sys/block/loop0/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop1/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop2/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop3/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop4/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop5/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop6/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/loop7/queue/rotational -&gt; 1 (0=SSD,1=HDD)
  /sys/block/vda/queue/rotational -&gt; 1 (0=SSD,1=HDD)
21 1 254:0 / / rw,relatime shared:1 - ext4 /dev/root rw,discard

== sequential write 100 MiB (python, 1 MiB blocks, buffered+fsync) ==
  write 100MiB: 1467 MiB/s wall (0.07s) ; fsync 0.078s ; total w/ fsync 0.15s

== dd O_DIRECT write 100 MiB ==
104857600 bytes (105 MB, 100 MiB) copied, 0.217344 s, 482 MB/s

== warm read (page cache) ==
  read 100MiB warm: 3991 MiB/s (0.03s)

== COLD read (after sudo drop_caches) ==
  dropped caches
  read 100MiB cold:  1318 MiB/s (0.08s)

== dd O_DIRECT read 100 MiB ==
104857600 bytes (105 MB, 100 MiB) copied, 0.0501176 s, 2.1 GB/s
  (bench files removed)

== tmpfs (RAM) 500 MiB write+read in /tmp and /dev/shm ==
  /tmp: write 2395 MiB/s, read 4629 MiB/s (incl fsync on write)
  /dev/shm: write 3318 MiB/s, read 5591 MiB/s (incl fsync on write)

== small-file inode ops: create/delete 20k files (ext4) ==
  create 20k files: 151,420 files/s ; delete: 476,802 files/s

== page-cache pressure note: df after benches ==
/dev/root        25G  4.1G   20G  17% /

</pre>

</details>

## `12_pip.txt`  _(2132 bytes · sha256 `8567335975`…`8bda65`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== pip/package-manager capability suite ==
== global site-packages perms (default pip target for /usr/local python) ==
drwxrwxrwx  41 root root  4096 Jul 23 15:09 /usr/local/lib/python3.13
drwxrwxrwx 369 root root 12288 Jul 23 18:05 /usr/local/lib/python3.13/site-packages
site-packages WRITABLE by user

== python 3.13 build flags ==
Py_GIL_DISABLED: 0
SOABI: cpython-313-x86_64-linux-gnu

== venv creation + timing ==
  venv created in 2.14s
pip 26.1.2 from /tmp/vptest/lib/python3.13/site-packages/pip (python 3.13)

== wheel installs (timed, quiet) ==
         ~^
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    print(f'  {pkg:16s} rc=1 in {(1788520787.298882456-1788520787.004983689):6.2f}s')
               ^^^
NameError: name 'pkg' is not defined
           ~^
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    print(f'  {pkg:16s} rc=1 in {(1788520787.618295698-1788520787.329165272):6.2f}s')
               ^^^
NameError: name 'pkg' is not defined
          ~^
Traceback (most recent call last):
  File "&lt;string&gt;", line 1, in &lt;module&gt;
    print(f'  {pkg:16s} rc=1 in {(1788520787.932171604-1788520787.647463525):6.2f}s')
               ^^^
NameError: name 'pkg' is not defined
== sdist builds ==
  markupsafe sdist (C ext compile, build isolation): rc=0 in   3.72s
  six (pure sdist, legacy setup.py): rc=0 in   0.42s

== import + version sanity ==
Traceback (most recent call last):
  File "&lt;stdin&gt;", line 1, in &lt;module&gt;
ModuleNotFoundError: No module named 'rich'

== numpy micro-benches (from /usr/local python? use venv numpy) ==
  File "&lt;stdin&gt;", line 4
    t0=time.perf_counter(); for _ in range(200): np.dot(A,B); print(f"  np.dot warm x200        = {(time.perf_counter()-t0)*1000/200:.1f} ms/op")
                            ^^^
SyntaxError: invalid syntax

== pip --user install test (outside venv, default interpreter) ==
  idna importable from default python (user site) â pip --user rc=0 in 1.11s
  user site: /home/user/.local/lib/python3.13/site-packages
total 8
drwxr-xr-x 4 user user   60 Sep  4 11:19 .
drwxr-xr-x 3 user user   60 Sep  4 11:19 ..

</pre>

</details>

## `12b_pip2.txt`  _(2649 bytes · sha256 `9901556f0a`…`54653b`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== pip wheel install rerun with FULL output ==
--- pip install rich ---
Collecting rich
  Downloading rich-15.0.0-py3-none-any.whl.metadata (18 kB)
Collecting markdown-it-py&gt;=2.2.0 (from rich)
  Downloading markdown_it_py-4.2.0-py3-none-any.whl.metadata (7.4 kB)
Collecting pygments&lt;3.0.0,&gt;=2.13.0 (from rich)
  Downloading pygments-2.21.0-py3-none-any.whl.metadata (2.5 kB)
  &gt;&gt;&gt; rich took 1.41s
--- pip install orjson ---
Collecting orjson
  Downloading orjson-3.12.0-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (41 kB)
Downloading orjson-3.12.0-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (131 kB)
Installing collected packages: orjson
Successfully installed orjson-3.12.0
  &gt;&gt;&gt; orjson took 0.67s

== numpy: linux wheel direct download then install ==
wheel: 
curl: option : blank argument where content is expected
curl: try 'curl --help' or 'curl --manual' for more information
WARNING: Requirement '/tmp/np.whl' looks like a filename, but the file does not exist
ERROR: Invalid wheel filename (wrong number of parts): 'np'
  &gt;&gt;&gt; numpy install took 1788520849.4144053s
  &gt;&gt;&gt; download+install total 0.29s

== numpy bench (fixed syntax) ==
Traceback (most recent call last):
  File "&lt;stdin&gt;", line 1, in &lt;module&gt;
ModuleNotFoundError: No module named 'numpy'

== HF multi-connection throughput (4 parallel 5MiB ranges) ==
  File "&lt;string&gt;", line 1
    print(f'  4x5MiB parallel: {1788520850.657532453-1788520849.741720654:.2f}s wall, aggregate 20971520 bytes -&gt; {20971520/1048576/(1788520850.658753473-1788520849.741720654):.1f} MiB/s (file count 4))
          ^
SyntaxError: unterminated f-string literal (detected at line 1)

== hetzner DNS follow-up (rcode/an/type) ==
  speed.hetzner.de             rcode=0 answers=0 ips=[] 1.7 ms
  speed.hetzner.de             rcode=0 answers=0 ips=[] 155.6 ms
  random123.hetzner.de         rcode=3 answers=0 ips=[] 215.8 ms
  www.hetzner.com              rcode=0 answers=1 ips=['0.4.213.133'] 179.8 ms
  www.python.org               rcode=0 answers=5 ips=['0.33.9.100', '104.111.110.3', '101.116.0.192', '101.64.223.192'] 10.5 ms
  pypi.org                     rcode=0 answers=4 ips=['0.4.151.101', '0.4.151.101', '0.4.151.101', '0.4.151.101'] 0.8 ms
  download.hetzner.de          rcode=0 answers=1 ips=['0.4.213.239'] 155.9 ms
  dl.google.com                rcode=0 answers=4 ips=['0.4.74.125', '0.4.74.125', '0.4.74.125', '0.4.74.125'] 2.5 ms
  speedtest.net                rcode=0 answers=4 ips=['0.4.151.101', '0.4.151.101', '0.4.151.101', '0.4.151.101'] 1.4 ms
  speed.hetzner.de             rcode=0 answers=0 ips=[] 1.2 ms

== net hostname sanity ==
e2b.local

</pre>

</details>

## `13_bg_misc.txt`  _(2432 bytes · sha256 `5d9b91c885`…`f0b352`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== numpy via pip download+install (linux cp313 wheel) ==
Successfully downloaded numpy
-rw-r--r-- 1 user user 16709995 Sep  4 11:21 numpy-2.5.2-cp313-cp313-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl
Successfully installed numpy-2.5.2
  download 0.84s, install 2.33s

== numpy + orjson micro-bench ==
  numpy 2.5.2 | orjson 3.12.0
  arange(1e7,f64).sum()  = 49999995000000 in   47.5 ms (incl alloc)
  2048x2048 matmul       =  192.5 ms (incl rng+alloc)
  np.dot warm x100       = 125.94 ms/op
  json.dumps x200k       =  480.8 ms | orjson.dumps x200k =   36.2 ms

== spawn detached background ticker (cross-call survival test) ==
  spawned pid=2626 (setsid, detached), ticks every 5s -&gt; bg_ticks.txt
  initial tick count: 1

== GPU / special devices ==
ls: cannot access '/dev/dri': No such file or directory
ls: cannot access '/dev/nvidia*': No such file or directory
ls: cannot access '/dev/kvm': No such file or directory
autofs
console
core
cpu
cpu_dma_latency
fd
full
fuse
hugepages
hwrng
initctl
kmsg
log
loop-control
loop0
loop1
loop2
loop3
loop4
loop5
loop6
loop7
mem
mqueue
net
null
ptmx
ptp0
pts
random

== kernel modules loaded? ==

== sysctl highlights ==
  kernel.hostname         n/a
  kernel.pid_max          n/a
  vm.swappiness           n/a
  fs.file-max             n/a
  net.ipv4.ip_forward     n/a
  kernel.random.boot_id   n/a

== git local demo (init/commit in /tmp) ==
cf5575b init

== jupyter/code-interpreter context ==
    359 envd            /usr/bin/envd
    437 jupyter-server  /usr/local/bin/python3.13 /usr/local/bin/jupyter-server --IdentityProvider.token=
    463 uvicorn         /root/.server/.venv/bin/python /root/.server/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 49999 --workers 1 --no-access-log --no-use-colors --timeout-keep-alive 640
    475 python3.13      /usr/local/bin/python3.13 -Xfrozen_modules=off -m ipykernel_launcher -f /root/.local/share/jupyter/runtime/kernel-6bd8c74e-fd89-448c-9e6a-22de9783e8b5.json
    490 node            node /usr/bin/ijskernel --hide-undefined /root/.local/share/jupyter/runtime/kernel-1fe44cf5-e7f2-4ee3-82b8-24ac60d6d93f.json --protocol=5.1

== final: free + df + load ==
               total        used        free      shared  buff/cache   available
Mem:            1984         568        1292         115         380        1416
/dev/root        25G  4.1G   20G  18% /
tmpfs           993M  115M  878M  12% /tmp
0.41 0.14 0.04 1/139 2665

</pre>

</details>

## `14_final.txt`  _(1853 bytes · sha256 `e8d5837cb9`…`a23d52`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== BG TICKER survival check (spawned in previous tool call) ==
  process alive:     PID     ELAPSED 
   2626       00:22 bash
   2626       1       00:22 bash
  ticks recorded: 5
  first tick: 2026-09-04T11:22:05Z
  last tick:  2026-09-04T11:22:25Z
  (&gt;=2 ticks separated by &gt;5s spanning a tool-call boundary =&gt; survived)

== persistence markers from round 1 ==
  /home/user/.persist_marker: PRESENT -&gt; HOME marker 2026-09-04T11:15:50Z
  /tmp/.persist_marker: PRESENT -&gt; TMP marker 2026-09-04T11:15:50Z

== VM session state ==
  uptime: up 11 minutes (started 2026-09-04 11:11:19)
  boot_id: 2bb79165-136a-4b63-829d-17027b0a8e40
  hostname: e2b.local
  threads: 142
hostname e2b.local
pid_max 4194304
file-max 9223372036854775807
ip_forward 0

== load + memory now ==
0.29 0.13 0.03 1/139 2704
               total        used        free      shared  buff/cache   available
Mem:            1984         569        1289         115         381        1414

== envprobe raw-notes inventory ==
  .persist_marker                33 B
  01_runtime.txt               4416 B
  02_identity.txt              5648 B
  03_tools.txt                 3609 B
  04_fs.txt                    2829 B
  05_cpu_mem.txt               1176 B
  06_compilers_pkgs.txt        2652 B
  07_cgroup_sudo.txt           4543 B
  09_net_matrix.txt            4200 B
  10_net_throughput.txt        2836 B
  10b_net_throughput2.txt      1614 B
  11_disk.txt                  1512 B
  12_pip.txt                   2132 B
  12b_pip2.txt                 2649 B
  13_bg_misc.txt               2432 B
  14_final.txt                  992 B
  bg_ticks.txt                  105 B

== total workspace size ==
29M	/home/user

== /proc/1 sanity: container re-check ==
  dockerenv+containerenv absent count (expect 2): 2

== jupyter health (service on 8888/49999) ==
  jupyter 127.0.0.1:8888 -&gt; 200

</pre>

</details>

## `15_process_demo.txt`  _(625 bytes · sha256 `302f1dcf9f`…`ae1aff`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
== supervised long-running process check (start_process) ==
  http://127.0.0.1:8800/ -&gt; HTTP 200 in 0.001140s
  &lt;!DOCTYPE HTML&gt;
  &lt;html lang="en"&gt;
  &lt;head&gt;
  &lt;meta charset="utf-8"&gt;
  &lt;title&gt;Directory listing for /&lt;/title&gt;
  &lt;/head&gt;
   2738       1       00:04 bash -c bash -l "$0/run.cmd" &gt; "$0/out.log" 2&gt;&amp;1; echo $? &gt; "$0/exit" /tmp/arena-workspace/procs/bench-static-file-server-0c5b38b4

== ticker final count before cleanup ==
  pid 2626 alive: yes
  ticks: 13
  span: 2026-09-04T11:22:05Z .. 2026-09-04T11:23:05Z
  elapsed: 63s since first tick
  -&gt; detached process ran across 70 tool-call boundaries
  ticker stopped

</pre>

</details>

## `bg_ticks.txt`  _(273 bytes · sha256 `0a592e54fb`…`5fd0c0`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
2026-09-04T11:22:05Z
2026-09-04T11:22:10Z
2026-09-04T11:22:15Z
2026-09-04T11:22:20Z
2026-09-04T11:22:25Z
2026-09-04T11:22:30Z
2026-09-04T11:22:35Z
2026-09-04T11:22:40Z
2026-09-04T11:22:45Z
2026-09-04T11:22:50Z
2026-09-04T11:22:55Z
2026-09-04T11:23:00Z
2026-09-04T11:23:05Z

</pre>

</details>

## `.persist_marker`  _(33 bytes · sha256 `973bb258c9`…`a98b1a`)_

<details open><summary>verbatim transcript</summary>

<pre style="white-space:pre-wrap;font-family:monospace;font-size:12px;line-height:1.35;">
HOME marker 2026-09-04T11:15:50Z

</pre>

</details>

