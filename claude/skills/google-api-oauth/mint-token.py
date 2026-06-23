#!/usr/bin/env python
# /// script
# requires-python = ">=3.10"
# dependencies = ["google-auth-oauthlib"]
# ///
"""Mint a Google OAuth user token via the installed-app (Desktop) flow.

    uv run python mint-token.py client_secret.json \
        --scope https://www.googleapis.com/auth/calendar.events \
        --out token.json

A browser opens for consent. It defaults to whatever Google account is already
signed in — if that is the wrong identity for the resource you intend to access,
click "Use another account" and sign in as the correct one. The resulting token
acts AS that account (see the google-api-oauth skill: authorization grants scopes,
not access). Pass --scope multiple times for multiple scopes.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("client_secret", help="Desktop OAuth client secret JSON from GCP.")
    p.add_argument(
        "--scope",
        action="append",
        required=True,
        help="OAuth scope URL. Repeat for multiple scopes. Pick the narrowest that "
        "covers your calls (e.g. .../auth/calendar.events to write events).",
    )
    p.add_argument("-o", "--out", default="token.json", help="Output token path.")
    args = p.parse_args()

    secret = Path(args.client_secret)
    if not secret.exists():
        print(f"client secret not found: {secret}", file=sys.stderr)
        return 1

    from google_auth_oauthlib.flow import InstalledAppFlow

    flow = InstalledAppFlow.from_client_secrets_file(str(secret), args.scope)
    creds = flow.run_local_server(port=0)

    out = Path(args.out)
    out.write_text(creds.to_json())
    print(f"wrote {out} (scopes: {' '.join(args.scope)})")
    if not creds.refresh_token:
        print(
            "WARNING: no refresh_token in the token — it will not survive expiry. "
            "Revoke the prior grant and re-mint, or pass prompt=consent.",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
