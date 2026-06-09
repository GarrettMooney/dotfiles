---
name: researching-vehicle-purchases
description: Use when someone shares a car/SUV listing or link (Carvana, cars.com, Autotrader, CarGurus, dealer page), asks whether a used vehicle is a good deal, wants to compare vehicles or find better options near a city, checks a VIN or a recall, or is deciding on a car purchase. Also when a spouse/family member sends a "should we buy this?" car link.
---

# Researching Vehicle Purchases

## Overview

Price and mileage are the easy axis and the wrong place to stop. A good answer evaluates the vehicle on the dimensions the *buyer* actually cares about, verifies claims against primary sources, and is honest about what only the buyer can confirm. The cheapest car that fails the buyer's real requirement is the wrong car.

## Workflow

1. **Anchor to the buyer first — before searching.** Check `~/personal` and any project dir for prior planning (a car tracker, notes, family-meeting docs): `mgrep "car buying priorities requirements what we want"`. Then ask the 2-3 constraints that change the search: budget ceiling, must-have features, intended use, and **who rides** (infant/kids → car-seat fit + rear-seat safety become top criteria). Use AskUserQuestion.
2. **Identify the exact car.** Listing sites (Carvana, cars.com, Autotrader) block automation: `WebFetch` returns **403**, a headless browser hits **Cloudflare "Just a moment"**. Don't fight it. Identify by stock number with web search instead, then get ground truth from the VIN (listing trim labels are often wrong).
3. **Run the comparison as a research sweep, not site-by-site scraping.** Use the deep-research workflow (multi-source + adversarial verification) for "best-value alternatives near <city>" — it catches stale/conflated facts (e.g., mismatched IIHS award cycles, wrong cargo specs).
4. **Evaluate on multiple dimensions** (see table). Always include: price-vs-local-market, history (accidents/owners/title), reliability for that model-year, **recalls**, **safety** (IIHS + NHTSA), fit-for-use (AWD for snow regions; car-seat fit for families), and **total cost** (fees + tax/title + delivery, not the sticker).
5. **Recall check — decode the powertrain FIRST** (see Gotchas). Match each recall to this car's engine before reporting anything alarming.
6. **Deliver anchored to the buyer's criteria**, not generic ones. State plainly which option wins on *their* priorities and what only they can verify in person.

## Quick reference — free, scriptable sources

| Need | Command / source |
|---|---|
| Identify a bot-blocked listing | `mgrep --web "Carvana stock <id> year make model trim price mileage"` (web search by stock #; the page itself 403s) |
| VIN → engine/trim/drivetrain | `curl -s "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/<VIN>?format=json"` → read `DisplacementL`, `EngineModel`, `ElectrificationLevel`, `DriveType`, `Trim` |
| Recalls for a model | `curl -s "https://api.nhtsa.gov/recalls/recallsByVehicle?make=<m>&model=<mdl>&modelYear=<yr>"` — read each `Summary` for the affected engine. **The `vin=` param is ignored; this is model-level only.** |
| NHTSA crash stars | `https://api.nhtsa.gov/SafetyRatings/...` or the `nhtsa.gov/vehicle/...` page |
| IIHS ratings | `iihs.org` — the **updated moderate-overlap front test adds a rear-seat dummy**; that subscore is the one that matters for a car-seat family (a nameplate can be roomy yet rate Poor on rear-occupant protection) |
| Local market price / deal rating | CarGurus / cars.com via the research sweep (deal rating + area average) |

## Gotchas (the non-obvious learnings)

- **Recalls are per-powertrain.** Decode the engine before sounding the alarm. Many headline "fire" recalls on a nameplate apply to only one engine (e.g., 1.5L EcoBoost fuel-injector recalls do **not** apply to the 2.5L hybrid). Read each recall `Summary` and match it to this VIN's engine.
- **VIN-level recall *completion* status is not retrievable by automation.** NHTSA's VIN tool and OEM recall lookups block bots (Akamai "Access Denied"). Hand the VIN to the human to check at `nhtsa.gov/recalls` or the OEM site, or call the selling dealer. Used dealers may legally sell with **open** recalls, so never assume it's done; make closing it a written condition of sale.
- **Don't stop at price/mileage.** Anchor to the buyer's stated criteria. A loaded-but-worn or cheap-but-too-small car can lose to a pricier one that fits their actual life.
- **Verify, don't trust aggregators.** Live prices, award years, and spec figures drift and conflict across sites — that's what the adversarial research sweep is for.

## Common mistakes

| Mistake | Do instead |
|---|---|
| Give up identifying a car when the listing 403s | `mgrep --web` by stock number, then VIN-decode |
| Fight Cloudflare/bot blocks with the browser | Use web search + the research workflow |
| Compare only price and mileage | Score on the buyer's dimensions (safety, space, fit, total cost, reliability) |
| Alarm about a recall by nameplate | Decode the powertrain, match recall → engine first |
| Claim a recall is "done" from an API | Completion is human-verified only; say so |
| Use generic criteria | Read the buyer's own planning notes; ask what matters to them |
