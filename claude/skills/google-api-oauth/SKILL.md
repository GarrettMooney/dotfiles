---
name: google-api-oauth
description: Use when integrating a Google API (Calendar, Gmail, Drive) into a script or worker via OAuth USER credentials — minting a token from a Desktop client_secret, choosing scopes, or debugging 403 "You need to have writer access"/"requiredAccessLevel", "insufficient authentication scopes", "access_denied" on the consent screen, or a refresh token that stops working after a week.
---

# Google API OAuth (user credentials)

## Overview

A Google OAuth user token acts **as one Google account**. Authorization grants
*scopes* (what kinds of calls), NOT *access* (which resources). The account the
token authorizes as must independently own, or have been granted a role on, the
target resource (a calendar, a file, a mailbox).

**The failure is almost never noticed at mint time — it surfaces as a 403 on the
first write.** So you run the account↔resource check as a pre-flight *because the
task involves a Google API*, not because you happened to spot a mismatch.

For server-to-server / no-human auth, use a **service account** instead (see the
`modal` skill's GCP section) — different mechanism, not this skill.

## Pre-flight (BEFORE minting the token)

1. **Identify the exact resource and its owner.** A `CALENDAR_ID` like
   `someone@gmail.com` is that account's *primary* calendar; only `someone@gmail.com`
   has writer access by default. A `...@group.calendar.google.com` id is a secondary
   calendar with its own sharing list. Don't treat the id as an opaque string —
   read it and know whose it is.
2. **Decide which account the token acts as**, then guarantee that account can write:
   - **Auth as the owner** (simplest): authorize the flow as the resource's owner.
     A primary calendar's owner always has writer access. No sharing needed.
   - **Share to the authorizer**: keep your own account's token, and have the owner
     share the resource with it ("Make changes to events" = writer for Calendar).
3. **"Testing" publishing status:** if the OAuth consent screen is in Testing mode,
   only listed **test users** can authorize, AND issued refresh tokens **expire after
   7 days**. For anything long-running, add the account as a test user; for a durable
   worker, publish the app (or accept weekly re-auth).

## Mint the token

Use a Desktop-type `client_secret.json`. An existing Desktop client from another
project in the **same GCP project** is reusable as long as that project has the
target API enabled and the account is a test user — no need to create a new one.

```bash
uv run python mint-token.py client_secret.json \
  --scope https://www.googleapis.com/auth/calendar.events --out token.json
```

At the browser consent screen it defaults to whatever account is already signed in.
If that is the wrong identity, click **"Use another account"** and sign in as the
account you chose in pre-flight. (`mint-token.py` is in this skill's directory.)

## Verify IMMEDIATELY (do not skip, do not defer)

Green unit tests mock the API and prove nothing about live creds. The moment a token
is minted, prove writer access with a **create-then-delete round-trip** against the
real resource — never leave the test artifact behind:

```python
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

svc = build("calendar", "v3",
            credentials=Credentials.from_authorized_user_file("token.json",
                ["https://www.googleapis.com/auth/calendar.events"]))
cal = "someone@gmail.com"
ev = svc.events().insert(calendarId=cal, body={
    "summary": "[setup test - safe to ignore]",
    "start": {"dateTime": "2099-01-01T00:00:00", "timeZone": "UTC"},
    "end":   {"dateTime": "2099-01-01T00:30:00", "timeZone": "UTC"}}).execute()
svc.events().delete(calendarId=cal, eventId=ev["id"]).execute()
print("writer access confirmed on", cal)
```

A 403 here, not in production, is the entire point.

## Gotchas

| Symptom | Cause | Fix |
|---------|-------|-----|
| 403 `requiredAccessLevel` / "need writer access" | Token's account isn't owner/writer on the resource | Re-auth as owner, or share resource to the token's account |
| 403 "insufficient authentication scopes" | Token minted with too-narrow scope for the call | Re-mint with the right scope; `calendar.events` can't list calendars (needs `calendar.readonly`) |
| `access_denied` at consent | App in Testing, account not a test user | Add account under OAuth consent → Test users |
| Refresh token dead after ~7 days | App in "Testing" publishing status | Publish the app, or accept weekly re-auth |
| Token has no `refresh_token` | Re-consent reused a grant | Revoke prior grant, or pass `prompt=consent`, then re-mint |

## Common mistakes

- **Minting before the pre-flight.** Whatever account the browser is signed into
  becomes the worker's identity — verify it's the right one *first*.
- **Least privilege backwards.** Pick the narrowest scope that still covers your
  calls (`calendar.events` to write events), not `calendar` reflexively — but know
  a write-only scope can't *list* calendars.
- **Trusting green tests as proof of live access.** Always round-trip + delete.
