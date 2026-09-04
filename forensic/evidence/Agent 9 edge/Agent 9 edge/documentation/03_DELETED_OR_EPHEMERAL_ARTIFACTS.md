# Deleted or ephemeral artifacts

The archive contains every persistent workspace file attributable to this task that was present when packaging began. It cannot include objects deliberately removed earlier:

- `/tmp` network payloads (`envchar_google*`, GitHub tarball, NumPy wheel, Hugging Face model, Cloudflare download/upload payloads).
- Temporary venv, npm project, C sources/binaries, and install trees under `/tmp/envchar_*` and `/tmp/envprobe-*`.
- The 100 MiB temporary disk benchmark files, deleted after each benchmark.
- Transient Python `__pycache__` bytecode generated while syntax-checking archive/probe builders; source scripts are included instead.
- The `/tmp` persistence sentinel, deleted after the same-VM recheck.
- The Debian `tree` package, installed to prove apt capability and then purged.
- Managed/local heartbeat processes, intentionally stopped or allowed to exit after verification.
- Two development-only evidence runs (`20260904T141557Z-1419` and `20260904T141758Z-1924`) removed after they exposed quoting defects in early script revisions. The corrected canonical full run is `20260904T142002Z-2576`.
- One inaccessible Google Cloud Storage response body (HTTP 403); the successful Google Chrome range retry is retained as metrics/headers rather than as a 5 MB payload.

System package-manager state outside `/home/user`, live process state, and other VM-global mutations are not portable files and cannot be represented faithfully in a ZIP. Their direct transcripts are included.
