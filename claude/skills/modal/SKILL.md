---
name: modal
description: Use when writing, running, or deploying code on Modal — covers image building, functions, parallelism, GPUs, volumes, secrets, and web endpoints.
---

# Modal

## Overview

Reference for Modal's Python SDK with current API patterns. Training data contains stale Modal APIs — check current docs for anything non-trivial.

## When to Use

- Writing Modal scripts, configuring resources, building parallel pipelines, deploying web endpoints

**Not for:** General Python, Docker, or cloud questions unrelated to Modal.

## IMPORTANT: Check Docs Before Writing Modal Code

Fetch current docs from Context7 before writing non-trivial Modal code. Inline patterns below are a baseline, not a substitute for current docs.

### How to fetch Modal docs

Step 1 — find the library ID:

```bash
curl -s "https://context7.com/api/v2/libs/search?libraryName=modal&query=TOPIC" | jq '.results[0].id'
# Returns a library ID like "/websites/modal"
```

Step 2 — fetch docs using the library ID from step 1:

```bash
curl -s "https://context7.com/api/v2/context?libraryId=LIBRARY_ID&query=TOPIC&type=txt"
```

Do not hardcode the library ID — always search first, as it may change.

"Non-trivial" = anything beyond the patterns listed below (unfamiliar decorator, method, or configuration).

## Quick Reference — Current API Patterns

**App & Image:**
- `modal.App()` (not deprecated `modal.Stub()`)
- `modal.Image.debian_slim(python_version="3.13")` as base
- `.uv_pip_install()` for packages (preferred over `.pip_install()` on recent Modal client)
- `.add_local_python_source()` for local package injection
- Method chaining: `.apt_install()`, `.run_commands()`, `.env()`, image composition/layering

**Functions:**
- `@app.function(image=, gpu=, memory=, timeout=, volumes=, secrets=)` decorator
- `@app.local_entrypoint()` for orchestration entry point

**Parallelism:**
- `.map(inputs)` — single-arg parallel execution
- `.starmap([(a, b), ...])` — multi-arg parallel execution
- `.spawn_map()` — fire-and-forget parallel spawning
- `@modal.batched(max_batch_size=, wait_ms=)` — auto-batching for inference

**Classes:**
- `@app.cls(image=, gpu=, ...)` for stateful services
- `@modal.enter()` for container startup (load models, etc.)
- `@modal.method()` for callable methods
- `@modal.concurrent(target_inputs=, max_inputs=)` for concurrency control

**Web Endpoints:**
- `@modal.fastapi_endpoint()` or `@modal.web_endpoint()` — check Context7 for current decorators

**Resources:**
- GPU: `"T4"`, `"A10G"`, `"A100"`, `"H100"`, `"H100:2"` (multi-GPU)
- `memory=` (MB), `timeout=` (seconds), `cpu=`, `scaledown_window=`

**Volumes:**
- `modal.Volume.from_name("name", create_if_missing=True)`
- Attached via dict: `volumes={"/mount/path": my_volume}`

**Secrets:**
- `modal.Secret.from_name("secret-name")`
- `modal.Secret.from_name("secret-name", required_keys=["KEY"])`

## Example

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["modal"]
# ///
import modal

app = modal.App("batch-processing")
volume = modal.Volume.from_name("results", create_if_missing=True)
image = modal.Image.debian_slim(python_version="3.13").uv_pip_install("numpy")

@app.function(image=image, memory=8192, timeout=1800, volumes={"/out": volume})
def process(item: int) -> dict:
    import numpy as np
    result = np.random.default_rng(item).random(100).mean()
    return {"item": item, "result": float(result)}

@app.local_entrypoint()
def main():
    for r in process.map(range(100)):  # parallel, not sequential
        print(r)
```

Run: `uv run modal run --detach script.py`

## Red Flags — Anti-Patterns

**Sequential execution when parallelism is available:**
```python
# BAD
results = []
for item in items:
    results.append(process.remote(item))

# GOOD
results = list(process.map(items))
```

Before writing a `for` loop that calls `.remote()`, ask: can this be `.map()` or `.starmap()`?

**Forgetting detached mode:**
```bash
# BAD — terminal disconnect kills the job
modal run my_script.py

# GOOD — job survives disconnect
modal run --detach my_script.py
```

Any job >5 minutes should use `--detach`. Note: in detached mode with a local entrypoint, only the last triggered Modal function stays alive.

**Using outdated APIs:**
- `modal.Stub()` → `modal.App()`
- `.pip_install()` → `.uv_pip_install()` (requires recent Modal client; if pinned to an older version, `.pip_install()` is fine)
- If unsure, check Context7

**Not setting resource limits:**
Every `@app.function()` should explicitly set `memory=` and `timeout=`.

**Using `modal run` for persistent services:**
Use `modal run` for compute jobs, `modal deploy` for anything that needs to stay up (web endpoints, APIs).

## Cloud Integration (GCP)

### Canonical recipe: GCP service account → Modal secret

Use when you want a Modal function to read/write BigQuery or GCS under a dedicated SA (not your user creds).

```bash
# 1. Create a dedicated SA in the target GCP project
P=my-gcp-project
SA=modal-runner
gcloud iam service-accounts create $SA --project=$P \
  --display-name="Modal runner"

# 2. Grant least-privilege roles on that project
SA_EMAIL=$SA@$P.iam.gserviceaccount.com
for R in roles/bigquery.user roles/bigquery.dataEditor roles/storage.objectAdmin; do
  gcloud projects add-iam-policy-binding $P \
    --member="serviceAccount:$SA_EMAIL" --role="$R" --condition=None
done

# 3. Generate a JSON key to a temp file with restrictive perms
KEYFILE=$(mktemp -t sa-key.XXXXXX.json); chmod 600 "$KEYFILE"
gcloud iam service-accounts keys create "$KEYFILE" \
  --iam-account="$SA_EMAIL" --project=$P

# 4. Build a KEY=VALUE JSON mapping file. The *value* is the entire SA JSON
#    as a single string — `modal secret create --from-json` reads KEY→VALUE pairs.
SECRETFILE=$(mktemp -t secret.XXXXXX.json); chmod 600 "$SECRETFILE"
python3 -c "
import json
sa = open('$KEYFILE').read()
json.dump({'GOOGLE_APPLICATION_CREDENTIALS_JSON': sa, 'GCP_PROJECT_ID': '$P'},
          open('$SECRETFILE', 'w'))
"

# 5. Create the Modal secret
modal secret create my-gcp-secret --from-json "$SECRETFILE"

# 6. Shred both local files — Modal now holds the only copy
shred -u "$KEYFILE" "$SECRETFILE" 2>/dev/null || rm -P "$KEYFILE" "$SECRETFILE"
```

**Why `--from-json` and not positional `KEY=VALUE`:** the SA JSON is multi-line and contains characters that don't survive shell quoting. `--from-json` takes a `{"KEY": "VALUE"}` mapping file, which handles it cleanly.

### Using the secret in a Modal function

```python
@app.function(
    image=modal.Image.debian_slim().uv_pip_install(
        "google-cloud-bigquery", "google-cloud-bigquery-storage", "google-cloud-storage"
    ),
    secrets=[modal.Secret.from_name("my-gcp-secret")],
)
def f():
    import json, os
    from google.oauth2 import service_account
    from google.cloud import bigquery, storage

    creds = service_account.Credentials.from_service_account_info(
        json.loads(os.environ["GOOGLE_APPLICATION_CREDENTIALS_JSON"])
    )
    project = os.environ["GCP_PROJECT_ID"]
    bq = bigquery.Client(credentials=creds, project=project)
    gcs = storage.Client(credentials=creds, project=project)
    # ... use bq, gcs ...
```

### Gotchas

- **`storage.objectAdmin` ≠ bucket listing.** It grants read/write on objects in any bucket in the project but NOT `storage.buckets.list`. `client.list_buckets()` will 403. Pass bucket names explicitly, or grant `roles/storage.admin` if you truly need enumeration.
- **Always smoke-test before depending on the secret.** Run a Modal function that loads the creds, executes one BQ query (`SELECT 1`) and does one GCS object write/read/delete round-trip. Creating the secret doesn't verify the SA has the roles you think it does.
- **Cross-project reads from a project-scoped SA.** If your Modal SA is scoped to project A but source data lives in B, stage data into A under *your* user creds (which already read B via group membership), then Modal reads from A. `bq cp`, destination-table queries, and `bq extract` all work.
- **Key rotation/revocation.** `gcloud iam service-accounts keys list --iam-account=$SA_EMAIL` shows active keys; `...keys delete KEY_ID --iam-account=$SA_EMAIL` removes them. Keys don't expire by default.

### Alternative data-plane options

Thin pointers — fetch current docs via Context7 before using:
- **BigQuery Storage API** — `google-cloud-bigquery-storage` for fast Arrow transfers from BQ into Modal.
- **`CloudBucketMount`** — mount a GCS bucket as a filesystem path inside Modal containers. Check Modal docs for current syntax.
- **`gcsfs`** — fsspec-compatible GCS client, nice for polars/pandas `read_parquet("gs://...")` patterns.

## Debugging & Operations

**Exit Code Reference:**

| Code | Signal | Meaning | Common Fix |
|------|--------|---------|------------|
| 132 | SIGILL | Illegal CPU instruction | Use source build or fork, not PyPI binary |
| 137 | SIGKILL | Out of memory | Increase `memory=` in decorator |
| 139 | SIGSEGV | Segmentation fault | Check array bounds, memory access |
| 143 | SIGTERM | Terminated | Client disconnect — use `--detach` |

**Monitoring:**
```bash
modal app list              # List all apps with status
modal app logs <app-id>     # Stream logs from running app
modal app stop <app-id>     # Stop a running app
```

**Image Building:** Add `.apt_install("git")` if using `git+https://` dependencies. Pin versions for reproducibility.

**Memory Guidelines:**
- Data loading: `memory=8192` (8GB)
- Training: `memory=16384` (16GB)
- Large models: `memory=32768` (32GB)

**Timeout Guidelines:**
- Quick tasks: `timeout=1800` (30min)
- Training: `timeout=3600` (1hr)
- Full pipeline: `timeout=7200` (2hr)
