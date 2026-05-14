# Phase 2 - Presentation Guide

> **Phase 2 rubric (50 pts, due Mon 19 May 18:00):** zip the project, demo
> the app live, show a page that fetches data from a public API on load and
> then displays it. The hard requirements are *one* page using *one* API -
> we built two pages on two APIs to show off the pattern.

This is the script for the Phase 2 demo. The Phase 1 talk track still works
for the **stack** and **code tour** sections - this guide focuses on what
changed in Phase 2 (the API integration) and how to demo it cleanly.

---

## 1. Roles

| Role         | Who   | What they do                                                                 |
| ------------ | ----- | ---------------------------------------------------------------------------- |
| **Driver**   | _TBD_ | Mouse + keyboard. Clicks through pages, opens files in Cursor, reloads to show live data changing. |
| **Narrator** | _TBD_ | Walks through what just happened on screen and ties it back to the rubric.   |

Same swap pattern as Phase 1: Narrator owns the intro and "what's new",
Driver takes voice during the code tour.

---

## 2. The timeline

Phase 2 doesn't have an explicit time limit in the rubric, but plan for
about 4-5 minutes so we leave headroom for questions.

| Time        | Section                  | Who      | Beats                                                                        |
| ----------- | ------------------------ | -------- | ---------------------------------------------------------------------------- |
| 0:00 – 0:20 | Recap                    | Narrator | "Phase 1 was a static sample app. Phase 2 introduces dynamic content via 3rd-party APIs." |
| 0:20 – 0:40 | What we picked & why     | Narrator | Two APIs: MineralFYI (gems) + USGS MRDS (mines). Both public, no auth, both fit our theme. |
| 0:40 – 2:30 | Live demo               | Driver   | Open `/gems`, reload twice to show different spotlights. Open `/mines`, reload to show different commodities. (see §4) |
| 2:30 – 4:00 | Code tour                | Driver   | Service objects → controller wiring → view conditionals. (see §5)            |
| 4:00 – 4:30 | Resilience               | Driver   | Disconnect from the network and reload `/mines`. Page still renders with an "API unreachable" banner. (see §6) |
| 4:30 – 5:00 | Wrap & what's next       | Narrator | Phase 3 hook (auth + persistence), thanks, take questions.                   |

If the demo gods are unkind and the network is flaky, **swap §4 and §6**:
show the graceful-failure path first, then bring it back.

---

## 3. The API choices - what to actually say

**One-line pitch:**
> "Phase 2 asked us to make a page dynamic by talking to a 3rd-party API.
> We chose two APIs that fit Bedrock's gems-and-mines theme: **MineralFYI**
> for the mineral encyclopedia behind every gem, and the **USGS Mineral
> Resources Data System** for actual US mine records. Both are public, free,
> credential-free, and return clean structured data."

**Why these two (pick the two reasons that resonate):**

1. **They thematically fit the app.** We didn't bolt on a random API just
   to check a box - both APIs are about real-world minerals and mines, which
   is exactly what Bedrock is about.
2. **No credentials.** The assignment hint specifically said APIs that don't
   require credentials are better for grading. Both of ours work with plain
   HTTP GETs.
3. **One is JSON, one is XML.** MineralFYI returns clean JSON. USGS MRDS
   returns XML for the search endpoint and GeoJSON for record detail. Handling
   both with Ruby's stdlib (`net/http`, `JSON`, `REXML`) gave us better
   coverage of the assignment skill set than two JSON APIs would have.
4. **USGS is a government source.** It won't go away or change its
   pricing/auth model. Useful for a course project that we want graders to
   be able to run a week from now.

**How a request flows in 30 seconds:**
> "Browser hits `/mines`. The controller action calls
> `UsgsMinesService.search_by_name(commodity)`. That service does an HTTPS GET
> against `mrdata.usgs.gov`, parses the XML response into plain Ruby hashes,
> and hands the array to the view. The view loops through it and renders a
> table. If anything goes wrong - timeout, parse error, network down - the
> service returns `[]` and the view shows an honest 'API unavailable' banner
> instead of throwing a 500."

---

## 4. Demo flow - page by page

### `/gems` - Live spotlight from MineralFYI (≈ 50 s)

- Page opens. **Point at the top dark banner** with the green pulsing dot:
  *"Live · fetched on page load - source: MineralFYI."*
- *"This whole section was fetched from MineralFYI right when we hit the
  page. The gem name is picked at random server-side, so each reload could
  show a different one."*
- **Reload twice.** Different gem appears each time. Point out:
  - The **chemical formula** badge next to the title.
  - The **"A variety of X" subtitle** when it appears (e.g. *Ruby - A
    variety of Corundum*). *"That's the relationship the API is teaching us
    - in jewelry it's 'ruby,' but in mineralogy it's chromium-colored
    corundum. We pull the parent mineral data and surface both names."*
  - The **right-hand property grid**: hardness, specific gravity, crystal
    system, luster, cleavage, etc. *"All of this came from one HTTP call."*
- **Click the "Full record on MineralFYI →" link** to show the page is
  linking back to the source. (Optional - skip if time is tight.)

### `/mines` - Live records from USGS MRDS (≈ 50 s)

- Page opens. **Point at the top dark banner** with the amber pulsing dot:
  *"Live · fetched on page load - source: USGS Mineral Resources Data System."*
- *"We picked one of seven commodities at random server-side - gold, copper,
  silver, iron, diamond, zinc, or lead - and asked USGS for matching mine
  records. Reload to see a different commodity each time."*
- **Reload once.** Commodity in the headline changes. Point out:
  - The **hits count badge** next to the commodity name.
  - **One row in the table.** Pick anything: *"Real mine, real state,
    real status (Past Producer / Prospect / Current), real GPS coordinates
    pulled from the USGS catalog. Click the USGS ID column to jump to the
    upstream record page."*
- **(Optional)** Click a USGS ID link to show the upstream USGS record page
  opens in a new tab - confirms the data isn't fabricated.

That covers the rubric's "page fetches data from API and displays it"
requirement. **Total: ~1 minute 40 seconds of demo.**

---

## 5. Code tour - what to actually click

Stay shallow. Same principle as Phase 1.

1. **`app/services/api_client.rb`** (~20 s)
   - *"Our shared HTTP helper. `Net::HTTP` with a 4-second open timeout and
     8-second read timeout, plus rescue blocks that log a warning and return
     nil on any error. Every API call goes through here."*

2. **`app/services/mineral_fyi_service.rb`** (~25 s)
   - Point at **`GEM_SLUGS`** - *"Mapping each of our 12 jewelry-trade names
     to the slug MineralFYI actually uses. Ruby → corundum, aquamarine →
     beryl, and so on. This is where we encoded the gem-to-mineral
     relationship the assignment let us discover."*
   - Point at **`find_for_gem`** and **`summarize_record`**. *"Pure
     functions. No state. Caller gives us a gem name, we give back a
     plain hash or nil."*

3. **`app/services/usgs_mines_service.rb`** (~25 s)
   - Point at **`search_by_name`** - hits the USGS search endpoint, gets
     back XML, and `parse_search_results` uses Ruby's stdlib REXML to walk
     it into hashes.
   - Mention **`find`** - GeoJSON detail endpoint, returns a single full
     record. We don't use it on the page today but it's there for any
     follow-up phase that wants per-mine drilldowns.

4. **`app/controllers/pages_controller.rb`** (~20 s)
   - Scroll to **`def gems`** and **`def mines`**. Three lines each:
     pick a random input, call the service, stash the result on `@`.
   - *"The controller doesn't care which API we're talking to. It just
     asks the service for data and hands it to the view. If we swapped
     MineralFYI for a different mineral API tomorrow, only the service
     file would change."*

5. **`app/views/pages/gems.html.erb`** (~15 s)
   - Find the **`<% if @spotlight_mineral.present? %> ... <% else %> ...`**
     block.
   - *"This is what keeps the page from crashing if the API is down. On
     success, we render the rich spotlight. On failure, we render an honest
     'API unavailable' banner. Either way, the user gets a working page."*

---

## 6. Bonus: showing the graceful-failure path

If we have time and the demo is going well, this is the closer.

1. Open the **mines page** so the network call has already happened and the
   page is rendered with live data.
2. **Disconnect Wi-Fi.** (Or turn airplane mode on. Or unplug the ethernet.)
3. **Reload the page.**
4. Same chrome, same curated mines below, but the live section now shows
   an amber "Live USGS data unavailable" banner with a plain-English
   explanation. No stack trace. No 500. **No runtime error.**
5. **Reconnect**, reload, live data returns.

That demonstrates the "no runtime errors" rubric line - the page doesn't
just *work*, it works *even when the dependency it relies on is broken*.

---

## 7. The wrap-up - what's next

> "Phase 2 added dynamic external data. Phase 3 introduces persistence and
> authentication: we'll add user accounts, let logged-in users save
> favorite gems or mines, and back the tip form with a real model. Same
> stack, same views - just more layers behind them."

Take questions.
