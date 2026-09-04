I’m setting up a long-running research + data pipeline that will involve mixed CPU work, network I/O, package installs, and some file processing. Before I commit any real code or data, I need a clear picture of what this environment can actually sustain.

Please treat this as serious environment characterization work. Do the following thoroughly and keep notes as you go (you can use temporary files or just track things in memory, but be systematic).

Required checks

**1. Runtime & Isolation**

- Exact OS, kernel version, architecture, libc
- Clear signals of containerization / VM / restricted sandbox (cgroup, /.dockerenv, mount info, process tree, capabilities, seccomp, etc.)
- Current user, uid/gid, sudo/root status
- Any obvious resource limits (ulimit, cgroup memory/cpu, process limits)

**2. Tooling & Language Runtimes**

- Availability + versions of: python3, pip, node, npm, git, curl, wget, ffmpeg, docker, make, gcc/clang, jq, etc.
- Which package managers work (apt, apk, yum, pip, conda, npm…) and whether they can actually install things
- Can you install pure-python packages? System packages? Compile anything?

**3. Filesystem & Persistence**

- Working directory, home, /tmp behavior
- Free disk space and inode situation
- Read-only mounts or protected paths
- Simple write + read + delete test in a few locations
- Whether files survive across “sessions” if possible to test

**4. Network Characterization (important)**  
Run real measurements, not just “can I connect”:

- DNS resolution speed
- Latency + rough throughput to several endpoints (at minimum):
  - [google.com](http://google.com) / 8.8.8.8
  - [github.com](http://github.com)
  - [pypi.org](http://pypi.org)
  - [huggingface.co](http://huggingface.co)
  - A large file download (e.g. a few MB from a reliable CDN or GitHub release)
- Note any timeouts, blocks, captive portals, or asymmetric performance
- Outbound ports / protocols that appear restricted

**5. Performance Micro-benchmarks**  
Keep them short but timed accurately:

- Pure Python CPU: sum(range(10**7)) and a slightly heavier loop or numpy if available
- Disk sequential write + read of a 50–100 MB file
- Small package install time (if pip works)
- Any other operation that feels unusually fast or slow

**6. Other observations**

- Memory pressure behavior
- Ability to run background processes or long-running tasks
- Anything that breaks, hangs, or is surprisingly restricted
- Any environment variables or injected configuration that looks sandbox-related

Deliverable

After finishing the checks, create a clean, well-structured Markdown file named something like environment_[characterization.md](http://characterization.md) that contains:

- Executive summary (2–4 sentences)
- Detailed sections matching the categories above
- Tables for:
  - Tool availability + versions
  - Network latency / throughput results
  - Benchmark timings
- Raw notes or command outputs in collapsible sections or clearly marked appendix if useful
- Clear statements of what is fast, what is slow, and hard limitations

Be precise with numbers (include units and how you measured). Prefer real measured data over guesses.

Start whenever you’re ready and produce the final Markdown report when done.
