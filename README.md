# Stackonomics — CSC270 Team Project

> **Current phase: Phase 1 — Complete.** Stack chosen, sample Rails app
> with styled Home / About / Contact pages is in place and ready to demo.
> See the [Phase status](#phase-status) table below for the roadmap.

Full-stack web app built across the CSC270 phase assignments. We chose
**Ruby on Rails** as our solution stack and treat the project as a single
evolving application — each phase adds new features on top of the previous
one rather than starting from scratch.

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

| Phase | Status         | Tag                                           | What's included                                                                |
| ----- | -------------- | --------------------------------------------- | ------------------------------------------------------------------------------ |
| 1     | **Complete**   | `phase-1-submission` (tag at submission time) | Stack chosen, sample app with Home / About / Contact pages, Tailwind styling   |
| 2     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_2.png`)_                                      |
| 3     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_3.png`)_                                      |
| 4     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_4.png`)_                                      |
| 5     | Not started    | _tbd_                                         | _tbd (see `Assignment_Refs/Phase_5.png`)_                                      |

### Phase 1 — Sample App / Stack Setup

| Route           | Controller / Action      | What it does                                              |
| --------------- | ------------------------ | --------------------------------------------------------- |
| `/`             | `pages#home`             | Landing page introducing the chosen stack                 |
| `/about`        | `pages#about`            | Team bios with portrait images                            |
| `/contact`      | `pages#contact`          | Non-functional contact form                               |
| `POST /contact` | `pages#submit_contact`   | Flashes a notice; nothing is persisted                    |

Each page has a shared header / footer (`app/views/layouts/application.html.erb`),
a couple of paragraphs of body copy, and at least one image
(`app/assets/images/`).

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
