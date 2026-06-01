# Phase 5 — Membership & User Interactions

> **Phase 5 rubric:** add **membership** (User Register, Login, Logout, Session
> management) and **user interactions** — when logged in, a user manages only
> their own data, can browse others' read-only, and the app supports social
> interactions like liking and commenting.
>
> Bedrock's take: every specimen now belongs to a **member**, members browse
> each other's **public collections**, and they interact through **likes** and
> **comments** ("where did you get this rock?").

This document is the written companion to
[`presentations/Phase5_Presentation_Guide.md`](../presentations/Phase5_Presentation_Guide.md).

---

## 1. What changed from Phase 4

Phase 4 was a single global `specimens` table behind an API + a Data Access
Layer. Phase 5 adds people and ownership, and moves the specimen UI from
client-side JSON fetching to **server-rendered ERB** (so sessions, CSRF, and
authorization are handled the conventional Rails way).

| Concern        | Phase 4                              | Phase 5                                                        |
| -------------- | ------------------------------------ | -------------------------------------------------------------- |
| Identity       | none                                 | `User` + `Session` (Rails 8 native auth, `has_secure_password`)|
| Specimen UI    | `/api/specimens` + vanilla JS render | server-rendered ERB via `SpecimensController`                  |
| Ownership      | global rows                          | `Specimen belongs_to :user`; edit/delete is owner-only         |
| Interactions   | none                                 | `Like` (toggle) and `Comment` on specimens                     |
| JSON API       | full CRUD                            | **read-only** (`index`/`show`) so it can't bypass auth         |

---

## 2. Authentication

Generated with `bin/rails generate authentication` (Rails 8 built-in), so it
ships no heavyweight dependencies beyond `bcrypt` — important on the 1 GB
e2-micro box.

- **`User`** — `has_secure_password`, `name`, unique normalized `email_address`,
  validations. `display_name` / `initials` power the UI avatars.
- **`Session`** — one row per logged-in session; the signed `session_id` cookie
  (httponly, `same_site: :lax`) points at it. See
  [`app/controllers/concerns/authentication.rb`](../app/controllers/concerns/authentication.rb).
- **`Current`** — `ActiveSupport::CurrentAttributes` exposing `Current.user`.
- Controllers: `SessionsController` (login/logout), `RegistrationsController`
  (sign-up — we added this; the generator omits it).
- **Policy:** the `Authentication` concern requires login for every action by
  default. Public actions opt out with `allow_unauthenticated_access`
  (`pages#*`, `specimens#index/#show`, `users#show`). Password reset was
  intentionally removed (no mailer on this deploy) to keep the demo bug-free.

```
browser ── signed session_id cookie ──> Session row ──> Current.user
                                          (httponly, lax)
```

---

## 3. Data model

```
User 1───* Specimen        (a member owns their collection)
User 1───* Comment *───1 Specimen   (thread on each specimen)
User 1───* Like    *───1 Specimen   (unique [user_id, specimen_id])
User 1───* Session
```

Migrations:
- `add_user_to_specimens` — nullable `user_id` (FK `on_delete: :nullify`).
  Nullable on purpose so the persistent production volume's existing rows don't
  break; `db/seeds.rb` backfills owners.
- `create_comments`, `create_likes` — the unique index on
  `[user_id, specimen_id]` is the real guard that enforces one like per pair.

---

## 4. Authorization (the "only edit your own stuff" rule)

- **Browse anyone:** `specimens#index` (with an "Everyone / Mine" filter),
  `specimens#show`, and `users#show` (a member's public collection) are open.
- **Create:** requires login; the specimen is built through
  `current_user.specimens` so it is always owned by its creator.
- **Edit / delete:** `require_owner!` in
  [`app/controllers/specimens_controller.rb`](../app/controllers/specimens_controller.rb)
  redirects with a flash unless `specimen.owned_by?(current_user)`. Owner-only
  buttons are also hidden in the views.
- **Comments:** removable by the comment author **or** the specimen owner
  (`Comment#editable_by?`).

---

## 5. Data Access Layer (still enforced)

Phase 4's repository pattern carries over to the new models:

| Repository                | Backs                                  |
| ------------------------- | -------------------------------------- |
| `SpecimenRepository`      | reads (`all_with_associations`, `for_user`, `find_with_associations`) eager-load owner/likes/comments to avoid N+1 |
| `CommentRepository`       | `for_specimen`, `create`, `destroy`    |
| `LikeRepository`          | idempotent `like` / `unlike`, `liked?` |

---

## 6. Production note — SSL / cookies

The VM serves plain **HTTP on port 80** with no TLS terminator. Rails'
`force_ssl`/`assume_ssl` would mark the session cookie `secure`, so the browser
would never send it back and **login would silently fail**. Phase 5 makes SSL
enforcement opt-in in [`config/environments/production.rb`](../config/environments/production.rb):

```ruby
config.assume_ssl = ENV["FORCE_SSL"] == "true"
config.force_ssl  = ENV["FORCE_SSL"] == "true"
```

Default (unset) = works over HTTP for the demo. Set `FORCE_SSL=true` only once a
real HTTPS front-end exists. Local development is unaffected.

---

## 7. Demo accounts (from `db/seeds.rb`)

| Email                | Password   |
| -------------------- | ---------- |
| `ada@bedrock.dev`    | `rockhound`|
| `linus@bedrock.dev`  | `rockhound`|
| `grace@bedrock.dev`  | `rockhound`|

Seeds also assign the six starter specimens across these members and add sample
likes and comments, so a fresh database demos with a populated community.
