# Stackonomics - CSC270

A small Ruby on Rails web app called **Bedrock**: a four-page reference site
about gems, metals, and the mines they come from, plus a demo tip-submission
form. This is our team's project for CSC270, built up phase by phase.

| Phase   | What it adds                                                             | Status |
| ------- | ------------------------------------------------------------------------ | ------ |
| Phase 1 | Stack choice + static sample app (Home, Gems, Metals, Mines, tip form)   | Done (tagged `phase-1`) |
| Phase 2 | Dynamic content from two public APIs (USGS MRDS + MineralFYI)            | **Current** |

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

## How to set it up - from scratch on Windows

These are the exact steps to take a clean Windows machine all the way to
a running server. Do them once. After that, you can either repeat Step 8
each time you want to start the server, or just double-click `start-dev.bat`
(see the **One-click launch** section at the bottom).

### Step 1 - Install Ruby 4.0.3 (with DevKit)

1. Go to <https://rubyinstaller.org/downloads/>.
2. Under **WITH DEVKIT**, download the installer for
   **Ruby+Devkit 4.0.3-1 (x64)**.
3. Run the downloaded installer. Use the default options. When the
   installer finishes, leave the
   **"Run 'ridk install' to set up MSYS2"** checkbox **CHECKED**.
4. A black console window will pop up asking which components to install.
   Type `1 3` and press Enter. This installs the build toolchain Rails
   needs to compile native gems. It takes a few minutes.
5. When it says "Press any key to continue", press a key. The console
   will close.

To confirm Ruby is installed, **close every command window**, open a fresh
**PowerShell** (Start menu -> type "powershell" -> Enter), and run:

```powershell
ruby -v
```

You should see a line beginning with `ruby 4.0.3`.

### Step 2 - Initialize the MSYS2 keyring (required, one time)

Some of this project's gems contain native C code that gets compiled
during install. On Windows that compile goes through MSYS2's package
manager (`pacman`), which refuses to do anything until its keyring (the
local trust store) has been initialized. **This step is required even
if you used the RubyInstaller defaults**, because RubyInstaller does not
populate the keyring for you.

In your PowerShell window, run these two lines:

```powershell
ridk exec bash -lc "pacman-key --init"
ridk exec bash -lc "pacman-key --populate msys2"
```

The first line creates the keyring. The second line imports the MSYS2
project's signing keys into it. Each line takes about 15-30 seconds and
prints a small wall of text. Both should finish without errors.

(The `bash -lc "..."` wrapping is required because `ridk exec` by itself
does not put the MSYS2 binaries on the PATH for the subshell.)

### Step 3 - Open this project folder in PowerShell

In File Explorer, navigate **into** the unzipped project folder
(the one that contains `Gemfile`, `bin\`, `config\`, etc.).

In the address bar at the top of File Explorer, type `powershell` and
press Enter. A PowerShell window will open with this folder as its
working directory.

### Step 4 - Install Bundler (Ruby's dependency manager)

```powershell
gem install bundler
```

You can ignore the RDoc / "already initialized constant" warnings - those
are harmless on Ruby 4.0 and don't affect anything.

### Step 5 - Install the project's gems

```powershell
bundle install
```

This downloads and compiles all the gems the project uses (Rails,
tailwindcss-rails, sqlite3, puma, web-console, etc.). The first run takes
2-5 minutes. When it finishes you should see something like
*"Bundle complete! N Gemfile dependencies, M gems now installed."*

If `bundle install` fails on a native gem with a "public keyring not
found" or "unknown trust" error, you skipped Step 2. Run Step 2, then
re-run `bundle install`.

### Step 6 - Create the database

```powershell
ruby bin\rails db:prepare
```

This creates `storage\development.sqlite3`. Phase 1 has no migrations,
so this just creates an empty SQLite file. You should see
*"Created database 'storage/development.sqlite3'"* (or no output at all
if it already exists - both are fine).

### Step 7 - Build the Tailwind CSS

```powershell
ruby bin\rails tailwindcss:build
```

This compiles the site's stylesheet. You should see *"Done in NNNms"*.

### Step 8 - Start the web server

```powershell
ruby bin\dev
```

This starts the Rails server **and** the Tailwind CSS watcher together.
You'll see two streams of colored output prefixed with `[web]` and `[css]`.
When you see a line like:

```
[web] * Listening on http://127.0.0.1:3000
```

the app is ready. Open <http://localhost:3000> in your browser. Use the
top navigation (Home / Gems / Metals / Mines) to visit the four pages,
and try the demo tip form at the bottom of the home page.

To stop the server, press **Ctrl+C** in the PowerShell window where you
ran `ruby bin\dev`. Both the web server and the CSS watcher shut down
cleanly.

## One-click launch (after the steps above are done)

Once Steps 1-7 above have been completed on a machine, you don't need
to retype Step 8 every time. Just **double-click `start-dev.bat`** in
the repo root. It runs `ruby bin\dev` for you and prints the same
colored `[web]` / `[css]` output. Press **Ctrl+C** in the window to stop.

`start-dev.bat` does **not** install Ruby, gems, or the toolchain for
you - those steps must be done by hand using the instructions above.
The batch file is just a convenience wrapper around `ruby bin\dev`.

If `start-dev.bat` complains that something isn't installed yet, finish
the corresponding step from the setup section above and try again.

> **Windows SmartScreen** may pop up the first time you double-click
> the file (*"Windows protected your PC"*). Click
> **More info -> Run anyway**. The batch file is plain text - you can
> open it in Notepad to see exactly what it runs.

## What's in the app

| Page         | URL              | What it shows                                                                              |
| ------------ | ---------------- | ------------------------------------------------------------------------------------------ |
| Home         | `/`              | Hero, three topic cards, a randomized "Featured today" trio, and the demo tip form         |
| Gems         | `/gems`          | A **live spotlight gem** fetched from MineralFYI on page load, the Mohs hardness scale, and 12 curated gem cards |
| Metals       | `/metals`        | 15 metals as periodic-table tiles, grouped Precious / Base / Light & Strategic             |
| Mines        | `/mines`         | A **live table of real US mine records** pulled from the USGS MRDS database on page load, plus 10 curated landmark mines grouped by region |
| Tip form     | `POST /tips`     | Demo form. Submitting flashes a notice; nothing is actually saved. Will be wired up to a real database in a later phase. |

Most page data still lives as Ruby constants in
`app/controllers/pages_controller.rb`. The new live sections on `/gems` and
`/mines` come from public APIs at request time - see **Phase 2: live API
integration** below. All imagery is hand-rolled inline SVG inside the ERB
templates - no external image files.

## Phase 2: live API integration

Two pages now fetch dynamic content from public, credential-free APIs at
request time:

| Page    | API                                                                | What we render                                                                        |
| ------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `/gems` | **MineralFYI** ([docs](https://mineralfyi.com/developers/))        | Random spotlight gem's full encyclopedia entry: formula, Mohs hardness, color, luster, cleavage, description |
| `/mines`| **USGS MRDS** ([docs](https://mrdata.usgs.gov/catalog/api.php))    | Real US mine records matching a rotating commodity (gold, copper, silver, ...) with state, status, coordinates, USGS ID |

The integration lives in three service objects:

```
app/services/
  api_client.rb          # tiny Net::HTTP wrapper with timeouts and JSON parsing
  mineral_fyi_service.rb # MineralFYI client (returns Hash / nil on failure)
  usgs_mines_service.rb  # USGS MRDS client (XML search + GeoJSON detail, returns Array / nil)
```

Both services return `nil` (or `[]`) on any network or parse failure, and
both views check for that and render an honest "API unavailable" banner
instead of crashing - so the page never throws a runtime error even if the
upstream API is down.

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
|-- storage/             # SQLite database file lives here once db:prepare runs
|-- start-dev.bat        # one-click launcher (only runs the server, see above)
|-- Gemfile              # Ruby gem dependencies
`-- README.md            # this file
```

## Troubleshooting

- **`ruby` is not recognized.** You either skipped Step 1 or didn't open
  a fresh PowerShell window after installing Ruby. Close every command
  window, open a new PowerShell, and try again.
- **`bundle install` fails with "public keyring not found, have you run
  pacman init"** (or any "unknown trust" / signature error). You skipped
  Step 2. Run these two lines, then re-run `bundle install`:
  ```powershell
  ridk exec bash -lc "pacman-key --init"
  ridk exec bash -lc "pacman-key --populate msys2"
  ```
- **`bundle install` fails on `sqlite3` with a compile error like
  "cannot find -lsqlite3" or "make: gcc not found".** The MSYS2 build
  toolchain isn't installed. Run `ridk install 3` in PowerShell, then
  re-run `bundle install`.
- **`bundle install` fails on `psych` with "yaml.h not found".** Install
  libyaml into MSYS2 (Ruby 4 + Rails needs it for YAML), then bundle again:
  ```powershell
  ridk exec bash -lc "rm -f /var/lib/pacman/db.lck"
  ridk exec bash -lc "pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-libyaml"
  bundle install
  ```
  Current `start-dev.bat` tries this automatically before `bundle install`.
- **`bundle install` fails on `nokogiri` with "Failed to build gem native
  extension" or "An error occurred while installing nokogiri (1.19.3)".**
  Bundler fell back to the source-only nokogiri gem instead of using the
  precompiled `x64-mingw-ucrt` binary. Fix it by telling bundler to prefer
  platform-specific gems and installing the nokogiri C library deps:
  ```powershell
  bundle config set --local force_ruby_platform false
  bundle lock --add-platform x64-mingw-ucrt
  ridk exec bash -lc "rm -f /var/lib/pacman/db.lck && pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-libxml2 mingw-w64-ucrt-x86_64-libxslt mingw-w64-ucrt-x86_64-zlib mingw-w64-ucrt-x86_64-libiconv"
  bundle install
  ```
  Current `start-dev.bat` does both of these automatically before `bundle install`.
- **Launcher aborts with `Ruby platform mismatch: this Ruby reports
  'aarch64-mingw-ucrt'`** (or any non-`x64-mingw-ucrt` platform). You're on
  a Windows 11 ARM machine (Surface Pro X / Surface Pro 9 / 11 ARM / etc.)
  and winget auto-installed the ARM-native Ruby. The project's precompiled
  gems (nokogiri, sqlite3, tailwindcss-ruby) are all x64-only, so the ARM
  Ruby falls back to source compile and fails. Switch to the x64 Ruby
  (Windows 11 ARM emulates x64 transparently):
  ```powershell
  winget uninstall RubyInstallerTeam.RubyWithDevKit.4.0
  winget install --id RubyInstallerTeam.RubyWithDevKit.4.0 -e --architecture x64 --scope user --accept-package-agreements --accept-source-agreements
  ```
  Close every PowerShell/cmd window, open a fresh one, then double-click
  `start-dev.bat` again. The current `start-dev.bat` already passes
  `--architecture x64` to winget, so a clean run on a brand-new machine
  picks the right build automatically.
- **`error: could not lock database` / `db.lck` during gem install.** Another
  MSYS2 window is using pacman, or a previous run left a stale lock. Close all
  MSYS2 terminals, then remove the lock and retry (same `rm` line as above).
- **`bundle install` hangs for several minutes on a single gem.** It's
  almost always compiling a native extension (sqlite3, bindex,
  websocket-driver). 3-5 minutes per gem on first run is normal. If it
  has been stuck >10 minutes on the same gem, press Ctrl+C, run Step 2
  again, then re-run `bundle install`.
- **The page loads but looks unstyled (plain HTML).** You skipped Step 7.
  Run `ruby bin\rails tailwindcss:build` then refresh the browser.
- **Port 3000 is already in use.** Start the server on a different port
  by setting `PORT` first:
  ```powershell
  $env:PORT = "4000"
  ruby bin\dev
  ```
  Then visit <http://localhost:4000> instead.
