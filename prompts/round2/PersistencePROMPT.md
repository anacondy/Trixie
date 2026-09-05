We are testing what survives. This is a multi-turn experiment; do not conclude anything
until I say "FINAL TURN".

TURN 1 — establish baseline and plant markers:
  - record: boot_id, E2B_SANDBOX_ID, `date -u +%FT%TZ`, /proc/uptime,
    `systemctl show ssh -p ActiveEnterTimestamp`
  - write these files, each containing the turn-1 timestamp:
      /home/user/persist_home.txt
      /home/user/.persist_dot.txt
      /home/user/persist_dir/nested.txt
      /tmp/persist_tmp.txt
      /dev/shm/persist_shm.txt
  - install something NOT preinstalled and record it: `pip install --quiet cowsay && pip show cowsay | head -3`
  - `sudo apt-get install -y -qq sqlite3` then `which sqlite3`
  - create a large file to probe the snapshot budget:
      `dd if=/dev/zero of=/home/user/big.bin bs=1M count=140` then `ls -l /home/user/`
      (140 MiB deliberately exceeds the ~128 MiB budget — record what happens)
  - start a background process and record its PID: `nohup sleep 3600 & echo $!`
  - print a manifest: `cd /home/user && find . -type f | sort | head -50` plus `du -sh /home/user`

TURN 2 (new message, same session) — verify within-session survival:
  - re-read all five marker files; report which exist
  - is the sleep process still alive? (`ps -p <PID>`)
  - has boot_id changed?

TURN 3 (NEW session — start a fresh chat) — this is the real test:
  - re-read all five markers; report existence AND contents (does the timestamp match turn 1?)
  - has E2B_SANDBOX_ID changed? has boot_id changed? has /proc/uptime reset?
  - is cowsay still installed? is sqlite3 still installed?
  - does /home/user/big.bin still exist?
  - is the sleep process alive?
  - FINAL TURN: produce a table of {artifact, planted turn, survived to turn 3, evidence}

Do not infer any answer. Only report what you observe. If you cannot perform a step,
say "NOT PERFORMED" and why.
