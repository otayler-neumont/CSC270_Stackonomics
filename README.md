# Stackonomics - CSC270 Phase 1

A small Ruby on Rails web app called **Bedrock**: a four-page reference site
about gems, metals, and the mines they come from, plus a demo tip-submission
form. This is our Phase 1 submission for CSC270.

## What's in the stack

| Layer            | Choice                                 |
| ---------------- | -------------------------------------- |
| Framework        | Ruby on Rails 8.1                      |
| Language         | Ruby 4.0.3                             |
| View layer       | Embedded Ruby (ERB)                    |
| Styling          | Tailwind CSS 4 (via tailwindcss-rails) |
| Asset pipeline   | Propshaft                              |
| Database         | SQLite 3                               |
| Web server       | Puma                                   |

## How to run it - from scratch on Windows

These are the exact steps to take a clean Windows machine (no Ruby installed,
nothing set up) all the way to a running server. If you'd rather skip past
all of this, see the **One-click shortcut** section at the bottom - it does
all of these steps automatically.

### Step 1 - Install Ruby 4.0.3 (with DevKit)

1. Go to <https://rubyinstaller.org/downloads/>.
2. Under **WITH DEVKIT**, download the installer for **Ruby+Devkit 4.0.3-1
   (x64)**.
3. Run the downloaded installer. Use the default options. When it finishes,
   leave the **"Run 'ridk install' to set up MSYS2"** checkbox **CHECKED**.
4. A black console window will pop up asking which components to install.
   Type `1 3` and press Enter. This installs the build toolchain Rails
   needs to compile the SQLite library. It takes a few minutes.
5. When it says "Press any key to continue", press a key. The console will
   close.

To confirm Ruby is installed, **close all command windows**, open a fresh
**PowerShell** window (Start menu -> type "powershell" -> Enter), and run:

```powershell
ruby -v
```

You should see a line beginning with `ruby 4.0.3`.

### Step 2 - Open this project folder in a terminal

In File Explorer, navigate **into** the unzipped project folder
(the one that contains `Gemfile`, `bin\`, `config\`, etc.).

In the address bar at the top, type `powershell` and press Enter. A
PowerShell window will open with this folder as its working directory.

### Step 3 - Install Bundler (Ruby's dependency manager)

```powershell
gem install bundler
```

You can ignore the RDoc / "already initialized constant" warnings - those
are harmless on Ruby 4.0 and don't affect anything.

### Step 4 - Install the project's dependencies

```powershell
bundle install
```

This downloads and compiles all the gems the project uses (Rails,
tailwindcss-rails, sqlite3, puma, etc.). The first run takes 2-5 minutes.
When it finishes you should see something like *"Bundle complete! N Gemfile
dependencies, M gems now installed."*

### Step 5 - Create and migrate the database

```powershell
ruby bin\rails db:prepare
```

This creates `storage\development.sqlite3` and applies any migrations.
On Phase 1 there are no migrations yet, so this just creates an empty DB.
You should see *"Created database 'storage/development.sqlite3'"* (or
nothing at all if it already exists - both are fine).

### Step 6 - Build the Tailwind CSS

```powershell
ruby bin\rails tailwindcss:build
```

This compiles the site's stylesheet. You should see *"Done in NNNms"*.

### Step 7 - Start the web server

```powershell
ruby bin\dev
```

This starts the Rails server **and** the Tailwind CSS watcher together.
You'll see two streams of colored output prefixed with `[web]` and `[css]`.
When you see a line like:

```
[web] * Listening on http://127.0.0.1:3000
```

the app is ready.

### Step 8 - Open it in a browser

Go to <http://localhost:3000>.

You should land on the **Bedrock** home page. Use the top navigation
(Home / Gems / Metals / Mines) to visit the four pages, and try the demo
tip form at the bottom of the home page.

### Stopping the server

In the PowerShell window where you ran `ruby bin\dev`, press **Ctrl+C**.
Both the web server and the CSS watcher shut down cleanly. To start it
again later, just repeat Step 7 (you don't need to redo Steps 1-6 once
they're done).

## One-click shortcut

If you don't want to run those seven commands by hand, this project
includes a Windows batch file that automates every one of them:

> **Double-click `start-dev.bat` in the repo root.**

It runs each of Steps 1-7 above in sequence, skipping any step that's
already been done (so re-running it is safe and fast). The first run on a
truly clean machine takes about 10-15 minutes because it has to download
Ruby + DevKit (~150 MB), the build toolchain (~100 MB), and all the gems.
Every run after that launches in seconds.

When you see `Listening on http://127.0.0.1:3000` in the window, open
<http://localhost:3000> in your browser. Press **Ctrl+C** in the batch
window to stop everything.

A few things worth knowing about the shortcut:

- **Windows SmartScreen** may pop up the first time you double-click the
  file (*"Windows protected your PC"*). Click **More info -> Run anyway**.
  The batch file is plain text - you can open it in Notepad to see exactly
  what it does (it hands off to `scripts\setup-and-run.ps1`, also plain
  text and readable).
- **No admin / UAC prompt is needed.** Ruby is installed per-user under
  `%LOCALAPPDATA%\Programs\Ruby40-x64`.
- **If the automatic Ruby install fails** (corporate antivirus blocks the
  download, etc.), install Ruby manually using Step 1 above, then
  double-click `start-dev.bat` again - everything else will run
  automatically.

## What's in the app

| Page         | URL              | What it shows                                                                              |
| ------------ | ---------------- | ------------------------------------------------------------------------------------------ |
| Home         | `/`              | Hero, three topic cards, a randomized "Featured today" trio, and the demo tip form         |
| Gems         | `/gems`          | 12 gems with Mohs hardness, color, origins, and a Mohs hardness scale graphic              |
| Metals       | `/metals`        | 15 metals as periodic-table tiles, grouped Precious / Base / Light & Strategic             |
| Mines        | `/mines`         | 10 landmark mines grouped by region (Africa, Americas, Asia, Asia-Pacific)                 |
| Tip form     | `POST /tips`     | Phase 1 demo form. Submitting flashes a notice; nothing is actually saved. Will be wired   |
|              |                  | up to a real database in Phase 2.                                                          |

All page data currently lives as Ruby constants in
`app\controllers\pages_controller.rb`. All imagery is hand-rolled inline
SVG inside the ERB templates - there are no external image files.

## Project layout

```
Stackonomics/
|-- app/                 # the Rails application
|   |-- controllers/     # PagesController has the four page actions and tip form
|   |-- views/           # ERB templates for each page + shared layout
|   `-- assets/          # Tailwind input CSS + compiled output
|-- bin/                 # Ruby launcher scripts (rails, dev, setup, ...)
|-- config/              # Rails configuration (routes.rb, database.yml, ...)
|-- db/                  # database schema (empty in Phase 1, no migrations yet)
|-- scripts/             # setup-and-run.ps1 - what the .bat hands off to
|-- storage/             # SQLite database file lives here once db:prepare runs
|-- start-dev.bat        # the one-click launcher described above
|-- Gemfile              # Ruby gem dependencies
`-- README.md            # this file
```

## Troubleshooting

- **`ruby` is not recognized.** You either skipped Step 1 or didn't open a
  fresh PowerShell window after installing Ruby. Close every command
  window, open a new PowerShell, and try again.
- **`bundle install` fails on `sqlite3`.** The MSYS2 build toolchain isn't
  installed. Run `ridk install 1 3` in PowerShell, then re-run
  `bundle install`.
- **The page loads but looks unstyled (plain HTML).** Step 6 didn't run.
  Run `ruby bin\rails tailwindcss:build` then refresh the browser.
- **Port 3000 is in use.** Run `ruby bin\dev` with a different port:
  `$env:PORT=4000; ruby bin\dev`, then visit `http://localhost:4000`.
