# Phase 5 — Presentation Guide

> **Phase 5 rubric:** add **membership** — User **Register**, **Login**,
> **Logout**, **Session management** — and **user interactions**: a logged-in
> user manages only **their own** data, can **browse others' read-only**, and
> the app supports interactions like **liking** and **adding messages/comments**.
>
> Bedrock's take: **public collections** owned by members, plus **likes** and
> **comments** ("where did you get this rock?") on every specimen.
>
> **Written notes:** [`docs/PHASE5_MEMBERSHIP.md`](../docs/PHASE5_MEMBERSHIP.md)
> (auth, data model, authorization, DAL, prod SSL note).

This talk is about **people and ownership**. Phases 3–4 (CRUD + DAL) still run
underneath; this is the membership layer on top.

---

## 1. Roles

| Role         | Who   | What they do                                                        |
| ------------ | ----- | ------------------------------------------------------------------- |
| **Driver**   | _TBD_ | Browser (register/login/like/comment) + code files in editor       |
| **Narrator** | _TBD_ | Auth flow, ownership rule, interactions, data model                 |

Use **two browsers** (or one normal + one incognito) so two members are logged
in at once — it makes the "browse someone else's collection" beat instant.

---

## 2. Suggested timeline (4½–5½ minutes)

| Time          | Section            | Beats                                                              |
| ------------- | ------------------ | ------------------------------------------------------------------ |
| 0:00 – 0:30   | Intro              | Phase 5 goal: **membership + interactions** on top of the DAL      |
| 0:30 – 1:45   | **Live: auth**     | Register a new member → land logged in → logout → login (see §4)    |
| 1:45 – 3:00   | **Live: ownership**| Add a specimen; switch users; others' cards are read-only (see §5) |
| 3:00 – 4:00   | **Live: interact** | Like a rock; comment "where'd you get this?"; see counts (see §6)   |
| 4:00 – 4:45   | Code tour          | Auth concern, ownership check, models + repositories (see §7)      |
| 4:45 – 5:15   | Wrap               | Rubric checklist aloud, zip name (see §8–9)                        |

**If short on time:** the auth + ownership + one like/comment is the rubric core;
the code tour can shrink to the `require_owner!` method and the data model.

---

## 3. One-line pitch (say at the top)

> "Phase 5 adds **membership** with Rails 8's built-in authentication, and turns
> Bedrock into a **community of collectors**. Every specimen now **belongs to a
> user**. You can browse everyone's collection, but you can only **edit your
> own**. Members **like** specimens and leave **comments** asking where a rock
> came from."

---

## 4. Live demo — membership (~75 s)

1. **Register** — top-right **Sign up** → name, email, password → submit.
   - Say: *"Rails 8 native auth, `has_secure_password` + bcrypt. On submit we
     start a session and land logged in."*
2. Point at the **nav**: avatar with initials, "My Collection", **Sign out**.
3. **Logout** (Sign out) → lands on the sign-in page.
4. **Login** as a seeded member: `ada@bedrock.dev` / `rockhound`.
   - Say: *"Sessions are server-side rows; the browser holds a signed,
     http-only cookie pointing at the session — that's the session management
     the rubric asks for."*

---

## 5. Live demo — ownership (~75 s)

1. As Ada, open **Explore** (`/specimens`) — all members' specimens, each with
   an **owner badge**.
2. Toggle **Mine** — only Ada's specimens. **Add specimen** → fill the form →
   it appears in her collection.
   - Say: *"It's built through `current_user.specimens`, so it's always owned by
     whoever created it."*
3. Open **someone else's** specimen (e.g. one of Linus's). Note: **no Edit/Delete
   buttons** — just like and comment.
   - Say: *"Edit and delete are owner-only — hidden in the view and enforced in
     the controller. If you hit the edit URL directly, `require_owner!` bounces
     you back with a flash."*
   - Optional: paste another user's `/specimens/:id/edit` URL → redirected with
     "You can only edit specimens in your own collection."

---

## 6. Live demo — interactions (~60 s)

1. On another member's specimen, click the **heart** — count goes up, button
   fills. Click again to **unlike**.
   - Say: *"A like is a unique `(user, specimen)` row — one per person, enforced
     by a unique index, so double-clicks can't duplicate it."*
2. **Comment**: *"Where did you find this one?"* → posts and appears in the
   thread with your name and avatar.
   - Say: *"Comments are the 'ask where they got their rocks' interaction. The
     author or the specimen's owner can remove a comment."*
3. (If two browsers) switch to the other member to show the like/comment landed.

---

## 7. Code tour (~45 s — pick 3 files)

1. **`app/controllers/concerns/authentication.rb`** — `require_authentication`
   runs by default; `allow_unauthenticated_access` opts public pages out;
   `current_user` from `Current.user`.
2. **`app/controllers/specimens_controller.rb`** — `require_owner!` is the
   "only your own stuff" rule; `create` uses `current_user.specimens`.
3. **Models + repositories** — `Specimen belongs_to :user`,
   `Like` unique `[user_id, specimen_id]`, `Comment#editable_by?`; the Phase 4
   DAL pattern continues as `CommentRepository` / `LikeRepository`.

> Tie-back: *"Same repository discipline as Phase 4 — new features, same clean
> data-access layer."*

---

## 8. Rubric checklist — say aloud (~15 s)

> "**Register / Login / Logout / Sessions:** Rails 8 native auth, server-side
> session rows + signed cookie. **See/edit only your own:** specimens belong to
> a user; edit and delete are owner-only, enforced in the controller. **Browse
> others:** every collection is public, read-only for non-owners.
> **Interactions:** likes (unique per user) and comments on each specimen."

---

## 9. Submission & grading tips

- Zip the **repo root** as `TeamName_Rails_Phase5.zip` (use your team identifier,
  e.g. `Team1_Rails_Phase5.zip` or `ApocaJamalypse_Rails_Phase5.zip`).
- Grader local path: **`start-dev.bat`** → migrate, seed, serve on port 3000.
  First boot prints **`Seeded 3 users, 6 specimens, 6 likes, 4 comments`** and
  the demo login.
- **Demo accounts:** `ada@bedrock.dev` / `linus@bedrock.dev` / `grace@bedrock.dev`,
  all password **`rockhound`** — or register a fresh one live.
- Production note (if asked): the deploy is HTTP-only, so SSL enforcement is
  opt-in via `FORCE_SSL=true`; login works over plain HTTP for the demo.

---

## 10. Likely questions

| Question | Short answer |
| -------- | ------------ |
| Why Rails native auth instead of Devise? | Lean — no heavyweight gem on a 1 GB e2-micro; `has_secure_password` + bcrypt + a `sessions` table cover the rubric. |
| Where's "session management"? | Each login creates a `Session` row; a signed, http-only cookie references it; logout destroys the row. |
| How do you stop me editing someone else's rock? | `require_owner!` before_action + owner-only buttons; the JSON API is read-only so it can't bypass it either. |
| Why comments instead of direct messages? | The interaction is about a specific rock ("where'd you get this?"), so it lives on the specimen. Simpler, contextual, and demos in one click. |
| Did you keep the DAL? | Yes — `SpecimenRepository` plus new `CommentRepository` / `LikeRepository`. |
| What about password reset? | Out of scope for the rubric and needs a mailer this deploy doesn't have, so it was removed to keep everything bug-free. |

---

## 11. Pre-demo checklist

- [ ] `start-dev.bat` finished; log shows **Seeded 3 users, 6 specimens, …**
- [ ] Can log in as `ada@bedrock.dev` / `rockhound`
- [ ] Two browsers ready (two members logged in) for the cross-user beat
- [ ] `/specimens` shows owner badges, like hearts, comment counts
- [ ] Confirm Edit/Delete are **hidden** on another member's specimen
- [ ] Files tabbed: `authentication.rb` → `specimens_controller.rb` → a model
- [ ] Phone timer rehearsed at **~5:00** (hard ceiling ~5:30)
