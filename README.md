# CSC270 Phase 1 — Ruby on Rails Sample App

Phase 1 proof-of-concept for our CSC270 project. We chose **Ruby on Rails** as
our full-stack solution. This Phase 1 deliverable is a small Rails app with a
shared layout and three styled static pages — Home, About the Team, and
Contact Us.

## Stack

| Layer            | Choice                              |
| ---------------- | ----------------------------------- |
| Framework        | Ruby on Rails 8.1                   |
| Language         | Ruby 4.0                            |
| View layer       | Embedded Ruby (ERB)                 |
| Styling          | Tailwind CSS 4 (via tailwindcss-rails) |
| Asset pipeline   | Propshaft                           |
| Database         | SQLite 3 (default; not yet used)    |
| Web server       | Puma                                |

## Pages

| Route       | Controller / Action          | What it does                                              |
| ----------- | ---------------------------- | --------------------------------------------------------- |
| `/`         | `pages#home`                 | Landing page introducing the chosen stack                 |
| `/about`    | `pages#about`                | Team bios with portrait images                            |
| `/contact`  | `pages#contact`              | Non-functional contact form (renders + posts to itself)   |
| `POST /contact` | `pages#submit_contact`   | Just shows a flash notice; nothing is persisted           |

Every page includes:

- A shared header / nav / footer (`app/views/layouts/application.html.erb`)
- At least a couple of paragraphs of body copy
- At least one image (SVG, in `app/assets/images/`)
- Tailwind-based responsive styling

## Project layout (the files we wrote/edited)

```
sample_app/
├── app/
│   ├── controllers/pages_controller.rb       # Home / About / Contact actions
│   ├── views/
│   │   ├── layouts/application.html.erb      # Shared nav + footer + Tailwind
│   │   └── pages/
│   │       ├── home.html.erb
│   │       ├── about.html.erb
│   │       └── contact.html.erb
│   └── assets/
│       ├── images/                           # SVG hero, team, contact illustrations
│       └── tailwind/application.css          # Tailwind v4 entry point
├── config/routes.rb                          # Maps URLs to PagesController
└── README.md
```

## Running the app locally

Prereqs: Ruby 4.0, Bundler, and the user gem `bin` directory on `PATH`.

```bash
cd sample_app
bundle install
bin/rails tailwindcss:build          # one-time CSS build
bin/rails server -p 3000
```

Then open <http://localhost:3000>.

For an auto-rebuilding dev workflow you can use `bin/dev` instead, which runs
both Puma and `tailwindcss:watch` via Foreman.

## Submission

Per the assignment, zip the project root using the naming convention
`TeamName_RubyOnRails_Phase1.zip` (e.g. `Team1_RubyOnRails_Phase1.zip`).

From PowerShell, in the `Phase_1` folder:

```powershell
Compress-Archive -Path .\sample_app\* -DestinationPath .\Team#_RubyOnRails_Phase1.zip
```

## Phase 1 rubric checklist

- [x] Stack chosen and set up (Ruby on Rails)
- [x] At least 2–3 working static pages (Home, About, Contact)
- [x] Pages styled with CSS (Tailwind CSS)
- [x] Each page includes a couple of paragraphs of text
- [x] Each page includes at least one image
- [x] Home page = landing/info about the stack
- [x] About page = team member bios + pictures
- [x] Contact page = non-functional web form
- [x] App boots cleanly with no crashes
