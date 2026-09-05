Run this in Code Arena (arena.ai/code), NOT Agent Mode. Build a trivial app so a sandbox
is provisioned, then characterise the environment the app runs in.

1. Which template was selected? Report the UI label and any template identifier visible.
2. From the agent's own tools (bash if available, else via generated server-side code):
   - `cat /.e2b` and `env | grep ^E2B_`  — COMPARE the template ID against
     nlhz8vlwyupq845jsdg9. Same or different? This is the key question.
   - uname -a; hostname; systemd-detect-virt; nproc; grep MemTotal /proc/meminfo
   - `cat /sys/fs/cgroup/user/memory.max` (note: the /user slice, not the cgroup root)
3. The database:
   - is DATABASE_URL set? Report its SCHEME and HOST ONLY — never print credentials
   - `psql "$DATABASE_URL" -c 'select version();'` and `-c 'select current_database(), current_user;'`
   - is Postgres in the same VM (`ss -tlnp | grep 5432`) or remote?
   - can the app reach the internet from a server route?
4. Preview surface:
   - the preview URL's hostname (strip any token) — is it an e2b domain, an Arena domain, or Vercel?
   - response headers of the preview URL
5. Persistence: does a file written by the agent survive a redeploy? A new message? A new session?

If bash is unavailable in this template, generate a Next.js API route that runs these
commands and returns the output, and report that you did so.
