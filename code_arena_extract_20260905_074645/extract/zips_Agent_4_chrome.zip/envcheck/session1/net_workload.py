import urllib.request, time, statistics, concurrent.futures as cf, json
names=["numpy","pandas","scipy","requests","httpx","pydantic","sqlalchemy","celery","duckdb","polars","matplotlib","seaborn","scikit-learn","tensorflow","torch","flask","fastapi","uvicorn","pytest","black","ruff","mypy","jupyter","notebook","dask","ray","transformers","datasets","tokenizers","safetensors","pyarrow","numba","cython","openpyxl","lxml","beautifulsoup4","tqdm","yaml","click","rich"]
def get(n):
    t0=time.perf_counter()
    try:
        with urllib.request.urlopen(urllib.request.Request(f"https://pypi.org/pypi/{n}/json",headers={'User-Agent':'bench'}),timeout=30) as r:
            d=r.read(); j=json.loads(d); return (len(d), time.perf_counter()-t0, j["info"]["version"], None)
    except Exception as e: return (0, time.perf_counter()-t0, None, type(e).__name__)
for w in [1,8,16,32]:
    t0=time.perf_counter()
    with cf.ThreadPoolExecutor(w) as ex: res=list(ex.map(get,names))
    el=time.perf_counter()-t0
    lat=[r[1] for r in res if not r[3]]; ok=sum(1 for r in res if not r[3]); tot=sum(r[0] for r in res)
    print(f"  workers={w:<3} all 40 requests in {el:5.2f}s | {tot/el/1e6:5.2f} MB/s | req/latency med={statistics.median(lat)*1000:6.1f}ms p95={sorted(lat)[int(len(lat)*.95)]*1000:6.1f}ms | ok={ok}/40")
print("  sample versions:", [r[2] for r in res if r[2]][:4])
