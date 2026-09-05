Characterise the IDENTITY and PROVENANCE of this sandbox. Do not benchmark anything.

Report, with the exact command used for each line, and no interpretation:

1. IDENTITY
   - full contents of /.e2b (it is a FILE, not a directory: `cat /.e2b`)
   - every env var matching ^E2B_ (verbatim)
   - hostname; /etc/hosts entries containing e2b
   - /proc/sys/kernel/random/boot_id
   - VM-CLASS LOCK: `grep PRETTY_NAME /etc/os-release`; `uname -v`; `python3 -V`.
     Classify: T = trixie/3.13/stamp "Fri Jul 17 14:31:34 UTC 2026"; B = bookworm/3.11/
     stamp "Mon May 11 18:48:24 UTC 2026"/~3.8 GiB; else NEW CLASS, report full lock.
   - `uptime -s` and /proc/uptime
   - machine-id: /etc/machine-id and /var/lib/dbus/machine-id

2. IMAGE BUILD LINEAGE
   - `stat -c '%y %n' /* | sort` — every top-level entry with its mtime
   - `stat -c '%y %s' /.e2b`
   - the apt snapshot line in /etc/apt/sources.list* (grep snapshot.debian.org)
   - `dpkg-query -W --showformat='${Package} ${Version}\n' | wc -l`
   - `pip list --format=freeze | wc -l` and its full output

3. SERVICE FOOTPRINT
   - `systemctl list-units --type=service --state=running --no-pager --no-legend`
   - listening sockets: `ss -tlnp` (or /proc/net/tcp if ss absent)
   - for envd / jupyter / code-interpreter: unit file path and ExecStart
   - `systemctl show envd -p ActiveEnterTimestamp` (and same for jupyter) —
     compare each against /proc/uptime and state explicitly whether any service
     predates the current boot

4. SELF-DESCRIPTION
   - any file under / mentioning the hosting product: `grep -rIl -m1 -iE 'arena|lmarena|e2b' /etc /opt /usr/local 2>/dev/null | head -50`
     then print the matching lines for anything that is not an E2B library
   - $HOME contents including dotfiles: `ls -la ~`
   - /code directory contents if present

5. STABILITY ACROSS TURNS
   - write /home/user/prov_probe.txt containing: boot_id, E2B_SANDBOX_ID, /.e2b contents,
     and `date -u +%FT%TZ`. Print it. I will ask you to re-read it in a later turn.

Mark every line MEASURED (you ran it) or INFERRED (you reasoned it). If a command
fails, print the error verbatim rather than substituting a guess.
