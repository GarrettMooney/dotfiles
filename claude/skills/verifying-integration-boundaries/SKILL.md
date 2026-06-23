---
name: verifying-integration-boundaries
description: Use when finishing or reviewing glue/wrapper code over an external system (cloud SDK like BigQuery/GCS/Vertex/google-genai/boto3, a query engine like DuckDB, or a dataframe UDF boundary like Polars map_batches / pandas apply) where the unit tests inject fakes or mocks for that boundary. Symptoms: all tests green and ty/ruff clean and review approved, but no code has run against the real engine or real service; an SDK call shape or response field was written from memory; auth/credentials are only ever exercised through a fake client. Use before declaring such work done, ready to merge, or verified.
---

# Verifying Integration Boundaries

## Core principle

A mocked test at an external boundary proves your **orchestration wiring**, not the **boundary contract**. When the fake and the code-under-test were written by the same person from the same mental model, a green suite only proves they are self-consistent. The real engine or service is the only thing that can disprove a wrong assumption.

**Green mocked tests + clean types + approved review is NOT "verified" for boundary code.** It is "wired." Verified requires one real run.

## When this applies

The tests `monkeypatch` the client / inject a `FakeClient`, or feed a dataframe UDF (`map_batches`, `apply`, `udf`) canned data; the SDK call shapes came from memory; auth runs only through the fake; and nothing in this change has touched the real engine, service, or project.

## Bug classes that survive a green mocked suite

| Class | Why the mock misses it | Real example |
|---|---|---|
| UDF return-type / schema inference | The engine probes the UDF (sometimes with an empty input) to infer output dtype under real `.collect()`; a fake-fed eager test never triggers that path | Polars `map_batches` with no `return_dtype` → empty-series probe → invalid zero-width `Array` → `InvalidOperationError` at runtime. **The mocked test passed.** |
| SDK call shape / response fields | The fake mirrors your memory of the API, so a wrong method name or field key type-checks and passes | wrong `client.aio.models.generate_content` arg, wrong `resp.embeddings[0].values` path |
| Auth / credential materialization | Every test uses a fake client, so no real `ADC` / secret-materialization path runs; one entry point can silently skip it | `scan_parquet` and `_vertex_client` skipped creds materialization → broken on Modal/CI, passed locally and in CI tests |
| dtype precision / width | Fake returns clean float64; real returns float32 or a different dimensionality | `0.1` vs `0.10000000149`, embed width 3 in test vs 3072 live |
| Server-side enforcement | The fake can't enforce caps/quotas the real service does | `maximum_bytes_billed` set in config but never applied to the real job |

`ty`/`ruff` cannot catch any of these: the fakes type-check fine and the code is lint-clean.

## The discipline (before declaring done)

1. **Run one real smoke test.** Exercise each boundary path once against the real engine/service with a trivial payload. For a dataframe UDF, that means a real `.with_columns(...).collect()` on a real (or real-engine) frame, not a faked batch. For an SDK, one live call per method. This single run collapses wrong-shape, wrong-dtype, schema-inference, and auth bugs into one check.
2. **Verify SDK shapes against the installed package, not memory.** `python -c "import pkg; help(pkg.Thing.method)"` or read the type stubs. Confirm constructor args, method names, and response field paths.
3. **Seam review, not just unit review.** Read every boundary entry point and ask: does auth/creds run on *this* path too? Is a public param accepted but never threaded through (a signature that lies)? Is a UDF return type declared? Is the server-side guard actually applied to the real call?

## Red flags — you are about to ship unverified boundary code

- "All tests pass, ready to merge" — for code whose tests all mock the boundary.
- "The reviewer approved the diff" — static review cannot see runtime engine behavior.
- "`ty` is clean" — fakes type-check; that is not boundary verification.
- "The map/UDF test passes, so the column op works" — it works *with the fake*. Run the engine.
- "I'll smoke-test it after merge" — the bug ships to the default branch; this exact sequence shipped a broken `embed` to `main`.

**All of these mean: run it once for real before calling it done.**

If you genuinely cannot reach the real service, downgrade the claim instead of overstating it: "wired and unit-tested; NOT verified against real <service>," and schedule the live smoke test as the first thing the owner runs. Never report a green mocked suite as "verified" or "working."
