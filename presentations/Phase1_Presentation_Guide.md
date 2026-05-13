# Phase 1 - Presentation Guide

> **Hard limits from the rubric:** under 5 minutes, must show every page,
> must show some code/structure, no runtime or compile errors during the
> demo. Points split: Technical 70 / Content 20 / Time 10.

This is the script we'll work from for the Phase 1 demo. The goal is to land
a calm, rehearsed five minutes that covers stack → demo → code → wrap-up,
with one of us driving and the other narrating at any given time.

---

## 1. Roles

| Role         | Who   | What they do                                                                 |
| ------------ | ----- | ---------------------------------------------------------------------------- |
| **Driver**   | _TBD_ | Mouse + keyboard. Clicks through pages, opens files in Cursor, runs the app. |
| **Narrator** | _TBD_ | Talks through the slides/talking points while the Driver clicks.             |

We swap once: Narrator owns the **stack choice** intro, Driver takes over
voice for the **code tour** because they're the one moving around files.

---

## 2. The 5-minute timeline

| Time        | Section             | Who      | Beats                                                                        |
| ----------- | ------------------- | -------- | ---------------------------------------------------------------------------- |
| 0:00 – 0:30 | Intro               | Narrator | Team name, project codename "Stackonomics", site name "Bedrock", what it is. |
| 0:30 – 1:30 | Stack choice        | Narrator | What stack, why we picked it, how the pieces fit together (see §3).          |
| 1:30 – 3:15 | Live demo           | Driver   | Home → Gems → Metals → Mines → tip form (see §5).                            |
| 3:15 – 4:30 | Code/structure tour | Driver   | Routes → controller → one view → layout → Tailwind config (see §6).          |
| 4:30 – 5:00 | Wrap & what's next  | Narrator | Phase 2 hook (move data into a real DB), thanks, take questions.             |

Practice once with a phone timer. If we hit 4:30 and haven't started wrap-up,
**skip the code tour deep-dive** and jump to the wrap.

---

## 3. The stack choice - what to actually say

**One-line pitch:**
> "We built Bedrock on **Ruby on Rails 8.1** with **Tailwind CSS 4** for
> styling, **Propshaft** as the asset pipeline, **Puma** as the web server,
> and **SQLite** queued up for later phases. We picked Rails because none of
> us had used it, it's a true full-stack solution out of the box, and it
> scales naturally into the auth + database work coming in Phase 2 and 3."

**Why this stack (pick the two reasons that resonate, don't list all four):**

1. **It's new to the team.** The rubric explicitly rewards picking something
   "new and interesting." None of us came in with Rails experience, so this
   is real learning, not a victory lap on something we already knew.
2. **Full-stack in one box.** Rails ships with the web layer
   (ActionController), the view layer (ERB + Propshaft), the ORM
   (ActiveRecord), and a job system. We don't need to glue 3–4 npm
   packages together to get a working app - that lets us spend our class
   time on features instead of plumbing.
3. **The "convention over configuration" payoff.** Once you know where
   things live (`app/controllers`, `app/views`, `config/routes.rb`),
   navigating *any* Rails project becomes the same exercise. That pays off
   over five phases.
4. **Clean upgrade path for later phases.** Today, Bedrock is static - the
   data lives as Ruby constants in the controller. In Phase 2 we replace
   those constants with ActiveRecord models backed by SQLite, **without
   changing the views or routes**. That's the point of MVC.

**How it works in 30 seconds:**
> "Browser hits a URL. `config/routes.rb` maps it to a controller action.
> The action loads data and hands it to an ERB view. The view renders
> inside our shared layout, which pulls in a Tailwind-compiled stylesheet
> served by Propshaft. Puma is the web server in front of all of it."

That's the whole loop. Don't overshoot it.

## 5. Demo flow - page by page

Click through in this exact order. Each page has **one thing to point out**
so we don't ramble.

### `/` - Home (≈ 25 s)
- Point out the **hero**, the **three topic cards** (Gems / Metals / Mines),
  and the **"From the field" featured trio**.
- Say: *"That featured block is randomized server-side in the controller -
  reload to confirm."* Then reload once. Different gem/metal/mine appears.
- Scroll to the **tip form** at the bottom (don't submit yet).

### `/gems` - Gems (≈ 25 s)
- Point at the **Mohs hardness scale** down the side and say one fact:
  *"Diamond at 10 scratches everything else; talc at 1 you can scratch with
  your fingernail."*
- Note that every gem card has an inline SVG icon - *"no external images,
  nothing for the asset pipeline to fingerprint, no licensing risk."*

### `/metals` - Metals (≈ 25 s)
- Point at the **periodic-tile look** and the three groups: Precious / Base
  / Light & Strategic.
- Quick fact to drop: *"Rare earths aren't actually rare - China just
  refines about 85% of the supply."* (It's on the page; reading it shows
  we wrote real content.)

### `/mines` - Mines (≈ 25 s)
- Point at the **regional grouping** (Africa, Americas, Asia, Asia-Pacific).
- Quick fact: *"Mponeng in South Africa is the deepest mine on Earth - the
  working face is about 4 km down."*

### Tip form (≈ 15 s)
- Type any text → submit. Get redirected to Home with the green flash.
- Say: *"Phase 1 doesn't persist anything - that's deliberate. The form
  posts to `pages#submit_tip`, which currently just flashes a notice. In
  Phase 2 we'll wire it to a `Tip` model so submissions actually save."*

That covers the rubric's "present all pages and some code/structure"
requirement on the page side. Total: ~1m 45s of demo.

---

## 6. Code/structure tour - what to actually click

Stay shallow. The rubric says **"some code/structure"**, not all of it.

1. **`config/routes.rb`** (~15 s)
   - Five lines do all the routing. Read them aloud:
     `root "pages#home"` plus the three GETs and one POST.
   - *"This is the URL → controller mapping for the entire app."*

2. **`app/controllers/pages_controller.rb`** (~25 s)
   - Scroll to the **`GEMS = [ ... ]`** constant near the top.
   - *"Right now our data is just Ruby constants. In Phase 2 these become
     ActiveRecord models - same shape, different storage."*
   - Then jump to the bottom (`def home`, `def gems`, `def metals`,
     `def mines`) and point out that each action is 1–3 lines: load data,
     hand it to the view.

3. **`app/views/pages/gems.html.erb`** (~15 s)
   - Show one `<%= ... %>` Ruby tag and one Tailwind class string.
   - *"ERB is HTML with Ruby tags. Tailwind classes do all our styling - no
     custom CSS files for layout."*

4. **`app/views/layouts/application.html.erb`** (~15 s)
   - Point at the header / nav / footer.
   - *"This is the shared chrome - every page renders inside this layout
     via `yield`. One file, four pages, consistent look."*

5. **`app/assets/tailwind/application.css`** (~10 s)
   - Just show that it exists.
   - *"This is the Tailwind 4 entry point. `bin/rails tailwindcss:watch`
     rebuilds it whenever we save a view."*
