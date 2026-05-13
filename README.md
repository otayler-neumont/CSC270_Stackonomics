# Stackonomics — CSC270 Team Project

> **Current phase: Phase 1 — Complete.** Stack chosen, themed sample Rails
> app — **Bedrock**, a four-page static field guide to gems, metals, and
> mines — is in place and ready to demo. See the [Phase status](#phase-status)
> table below for the roadmap.

Full-stack web app built across the CSC270 phase assignments. We chose
**Ruby on Rails** as our solution stack and treat the project as a single
evolving application — each phase adds new features on top of the previous
one rather than starting from scratch. The codename of the project on disk
is `Stackonomics`; the user-facing site itself is branded **Bedrock**.

> **Repo strategy:** one Rails app, one git history. Each phase is a set of
> commits (and a tag like `phase-1-submission`) on `main`. To produce a
> per-phase submission zip, we `git archive` from the matching tag.

## Repository layout

```
CSC270_Stackonomics/                   # repo root
├── Assignment_Refs/                   # original phase rubrics (PNG)
│   ├── Phase_1.png
│   ├── Phase_2.png
│   ├── Phase_3.png
│   ├── Phase_4.png
│   └── Phase_5.png
├── presentations/                     # demo / class presentations
│   └── Stackanomics.pptx
├── app/, bin/, config/, db/, ...      # the Rails 8 application
├── Gemfile / Gemfile.lock
├── .gitignore
└── README.md                          # this file
```

## Stack

| Layer            | Choice                                 |
| ---------------- | -------------------------------------- |
| Framework        | Ruby on Rails 8.1                      |
| Language         | Ruby 4.0                               |
| View layer       | Embedded Ruby (ERB)                    |
| Styling          | Tailwind CSS 4 (via tailwindcss-rails) |
| Asset pipeline   | Propshaft                              |
| Database         | SQLite 3 (planned for later phases)    |
| Web server       | Puma                                   |

## Phase status

| Phase | Status         | Tag                                           | What's included                                                                       |
| ----- | -------------- | --------------------------------------------- | ------------------------------------------------------------------------------------- |
| 1     | **Complete**   | `phase-1-submission` (tag at submission time) | Stack chosen; Bedrock — four-page mining-themed sample app (Home / Gems / Metals / Mines) with shared layout, Tailwind styling, and a demo tip-submission form |
| 2     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_2.png`)_                                             |
| 3     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_3.png`)_                                             |
| 4     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_4.png`)_                                             |
| 5     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_5.png`)_                                             |

### Phase 1 — Bedrock: Sample App / Stack Setup

**Bedrock** is a static, four-page field guide to the world's gems, metals,
and famous mines — built as our Phase 1 proof-of-concept on Rails 8 with
Tailwind CSS (Earth & Ore palette). All page data currently lives as
constants in `PagesController`; later phases will migrate it to real Active
Record models.

| Route          | Controller / Action  | What it does                                                                                            |
| -------------- | -------------------- | ------------------------------------------------------------------------------------------------------- |
| `/`            | `pages#home`         | Hero, three topic cards, a randomized "From the field" featured gem/metal/mine, and the demo tip form  |
| `/gems`        | `pages#gems`         | 12 gems with Mohs hardness, color, origins, and fun facts, plus a visual Mohs hardness scale            |
| `/metals`      | `pages#metals`       | 15 metals as periodic-style tiles, grouped Precious / Base / Light & Strategic                          |
| `/mines`       | `pages#mines`        | 10 landmark mines grouped by region (Africa, Americas, Asia, Asia-Pacific) with type/commodity/claim    |
| `POST /tips`   | `pages#submit_tip`   | Flashes a notice — non-functional Phase 1 form; will be wired to a model in a later phase               |

Shared layout (`app/views/layouts/application.html.erb`) provides the Bedrock
header/nav/footer. All imagery is hand-rolled inline SVG (no external image
files), so there's nothing for Propshaft to fingerprint and no licensing
risk in `app/assets/images/`.

## Running the app locally

Prereqs: Ruby 4.0, Bundler, and the user gem `bin` directory on `PATH`.

```bash
bundle install
bin/rails tailwindcss:build          # one-time CSS build
bin/rails server -p 3000             # or `bin/dev` for live CSS rebuild
```

Then open <http://localhost:3000>.

## Producing a phase submission zip

When a phase is finished and tagged (e.g. `phase-1-submission`), generate
the submission zip from the tag — no manual file copying required:

```powershell
git archive --format=zip phase-1-submission -o ..\Stackonomics_RubyOnRails_Phase1.zip
```

This produces a clean zip of the project at the tagged state, with no
`.git/` history baggage. Rename per the assignment convention
(`TeamName_SolutionStack_PhaseN.zip`).

## Working on a new phase

1. Pull latest `main`.
2. Branch off: `git checkout -b phase-N/<feature-name>`.
3. Implement and test locally.
4. Open a PR back into `main`. Squash or merge per team preference.
5. When the phase is complete and merged into `main`, tag the submission
   commit:
   ```bash
   git tag -a phase-N-submission -m "Phase N submission"
   git push origin phase-N-submission
   ```
