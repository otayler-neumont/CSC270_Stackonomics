# Phase 2 - Presentation Guide

> **Phase 2 rubric (50 pts, due Mon 19 May 18:00):** zip the project, demo
> the app live, show a page that fetches data from a public API on load and
> then displays it. The hard requirements are *one* page using *one* API -
> we built two pages on two APIs to show off the pattern.

This is the script for the Phase 2 demo. The Phase 1 talk track still works
for the **stack** and **code tour** sections - this guide focuses on what
changed in Phase 2 (the API integration) and how to demo it cleanly.

---

## 1. The API choices - what to actually say

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

## 2. Demo flow - page by page

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
- **Reload a few times.** Each reload picks a different random commodity
  server-side, and *every* reload renders instantly. Point out:
  - The **hits count badge** next to the commodity name (changes per reload).
  - **One row in the table.** Pick anything: *"Real mine, real state,
    real status (Past Producer / Prospect / Current), real GPS coordinates
    pulled from the USGS catalog. Click the USGS ID column to jump to the
    upstream record page."*
  - *"USGS's own server takes 10-22 seconds to answer one of these
    queries - we measured it. The reason the page is snappy is that a
    background thread on server boot pre-fetches all 7 commodities into
    `Rails.cache`, so every request reads from process memory instead of
    hitting the wire. We'll show that in the code in a minute (see §3,
    steps 3 and 6)."*
- **(Optional)** Click a USGS ID link to show the upstream USGS record page
  opens in a new tab - confirms the data isn't fabricated.

That covers the rubric's "page fetches data from API and displays it"
requirement. **Total: ~1 minute 40 seconds of demo.**

---

## 3. Code tour - what to actually click

Stay shallow. Same principle as Phase 1.

1. **`app/services/api_client.rb`** (~20 s)
   - *"Our shared HTTP helper. `Net::HTTP` with a 4-second open timeout and
     30-second read timeout, plus rescue blocks that log a warning and return
     nil on any error. Every API call goes through here."*
   - The 30-second read timeout looks generous on purpose - we measured the
     USGS endpoint at 2-22 seconds depending on the commodity, so 30s gives
     even the slowest one (iron) clean headroom. End users almost never wait
     this long because the cache warmer (see step 6) populates Rails.cache
     before the first request arrives.

2. **`app/services/mineral_fyi_service.rb`** (~25 s)
   - Point at **`GEM_SLUGS`** - *"Mapping each of our 12 jewelry-trade names
     to the slug MineralFYI actually uses. Ruby → corundum, aquamarine →
     beryl, and so on. This is where we encoded the gem-to-mineral
     relationship the assignment let us discover."*
   - Point at **`find_for_gem`** and **`summarize_record`**. *"Pure
     functions. No state. Caller gives us a gem name, we give back a
     plain hash or nil."*

3. **`app/services/usgs_mines_service.rb`** (~50 s) - *the caching story*
   - Point at the **`COMMODITIES`** constant. *"This is the canonical list
     of commodities we rotate through on /mines. It lives on the service
     (not the controller) because the boot-time warmer needs the same
     list - single source of truth."*
   - Point at **`search_by_name`**. Walk through the three blocks:
     1. **Cache check** at the top. `Rails.cache.read(cache_key)` - if
        this commodity is in the cache, return it instantly without
        touching the network.
     2. **HTTP call** in the middle - hits the USGS search endpoint, gets
        back XML, and `parse_search_results` uses Ruby's stdlib REXML to walk
        it into hashes.
     3. **Cache write** at the bottom - `Rails.cache.write(..., expires_in:
        CACHE_TTL)` on any successful HTTP response. We deliberately do
        **not** write on HTTP failure (the `return [] if body.nil?` line
        skips the write), so a transient outage doesn't lock us into an
        empty banner for the full hour - but we *do* cache legitimately
        empty results (e.g. zinc returns 0 matches) so the random commodity
        picker can land on any of the 7 and still serve from memory.
   - Point at **`warm_cache!`** below `find`. *"This is what the
     initializer (step 6) calls on boot. It just walks `COMMODITIES` and
     calls `search_by_name` for each one - same code path the controller
     uses, so we know we're warming exactly what users will request."*
   - *"We did this because the USGS endpoint is honestly slow - we
     measured copper at 13 seconds, iron at 22 seconds. Without caching,
     every page load paid the full cost and four of our seven commodities
     consistently timed out. With a one-hour TTL in `Rails.cache` (which is
     a `:memory_store` in development - see
     `config/environments/development.rb`) plus boot-time warming, request
     time is essentially network-free."*
   - Optional aside: *"`Rails.logger.info` lines on cache HIT/MISS - if you
     watch the server window during the demo, you'll see every page load
     log a cache HIT because the warmer already populated all 7 entries."*
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

6. **`config/initializers/usgs_cache_warmer.rb`** (~30 s) - *the boot warmer*
   - Walk the file top to bottom; it's intentionally short.
   - Point at the **two guard clauses** at the top: *"We bail out in test
     (tests forbid real network calls) and we only run when `Rails::Server`
     is defined - so `rails console`, `db:migrate`, asset precompile, etc.
     don't trigger a 70-second warm. Only the actual web server does."*
   - Point at **`Rails.application.config.after_initialize` +
     `Thread.new`**. *"After Rails finishes booting, we kick off a
     background thread that calls `UsgsMinesService.warm_cache!`. The
     server is already accepting requests at this point - the warmer just
     runs alongside. Worst case for a user who hits /mines in the first
     few seconds after boot is the original slow uncached experience; from
     then on every request is a cache hit."*
   - *"Errors inside the thread are rescued and logged - a network blip
     at boot must never crash the server."*

---

## 4. Bonus: showing the graceful-failure path

If we have time and the demo is going well, this is the closer. Use the
**gems** page here, not the mines page - the gems page has no cache layer,
so an offline reload deterministically hits the failure path.

1. Open the **gems page** so the MineralFYI call has already happened and
   the page is rendered with the live spotlight.
2. **Disconnect Wi-Fi.** (Or turn airplane mode on. Or unplug the ethernet.)
3. **Reload the page.**
4. Same chrome, same curated cards below, but the spotlight section now
   shows an amber "API unavailable" banner with a plain-English explanation.
   No stack trace. No 500. **No runtime error.**
5. **Reconnect**, reload, live spotlight returns.

That demonstrates the "no runtime errors" rubric line - the page doesn't
just *work*, it works *even when the dependency it relies on is broken*.

**Bonus bonus** (if you want to show off the cache + warmer too): repeat
the demo on the **mines page**. With Wi-Fi off, reload as many times as you
like - **every random commodity still loads with real data**. That's the
boot-time warmer working in your favor: all 7 commodities were fetched
into `Rails.cache` before the server ever started serving requests, so an
upstream USGS outage (or your laptop going offline) is invisible to users
for the full one-hour TTL. The graceful-failure banner is the gems-page
story; the cache-survives-an-outage banner is the mines-page story.

---

## 5. The wrap-up - what's next

> "Phase 2 added dynamic external data. Phase 3 introduces persistence and
> authentication: we'll add user accounts, let logged-in users save
> favorite gems or mines, and back the tip form with a real model. Same
> stack, same views - just more layers behind them."

Take questions.
