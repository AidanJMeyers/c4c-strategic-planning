# C4C Strategic Planning — Feedback Log

A single-page, multi-user feedback board for the Counselors for Change strategic
planning session. Board members open one URL, enter a shared word, pick their
name, and log responses. Everyone sees everyone's answers in real time, and the
whole thing exports to one `.txt` at the end.

Static site (vanilla JS, no build step) → **GitHub Pages**.
Shared storage → **Supabase** (Postgres, free tier).

---

## One-time setup

### 1. Create the Supabase project
1. Go to <https://supabase.com>, sign in, **New project**. Any name/region; save the
   database password somewhere (you won't need it for this app).
2. When it finishes provisioning, open **SQL Editor → New query**, paste the entire
   contents of [`schema.sql`](schema.sql), and click **Run**. This creates the three
   tables, the row-level-security policies, the scoped self-delete function, and turns
   on realtime.

### 2. Paste your two values
1. Supabase → **Project Settings → API**.
2. Copy **Project URL** and the **anon / public** key.
3. Open [`config.js`](config.js) and replace the two placeholders:
   ```js
   SUPABASE_URL:      "https://YOURPROJECT.supabase.co",
   SUPABASE_ANON_KEY: "eyJhbGciOi...your anon key...",
   ```
   > The anon key is a **public** key — it is meant to ship to the browser and is safe
   > to commit. The data is protected by Row Level Security, not by hiding this key.
   > **Never** paste the `service_role` (secret) key here.

### 3. Set the access word
In [`config.js`](config.js), change `PASSPHRASE` to whatever single word you'll give
the board along with the URL:
```js
PASSPHRASE: "brevard"
```
This is a speed bump to keep stray crawlers out, not real security.

### 4. Push and turn on Pages
```bash
git add -A
git commit -m "Configure Supabase + passphrase"
git push
```
Then on GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions.**
The included workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml))
publishes on every push to `main`. The live URL appears in the Actions run and under
Settings → Pages — typically:

```
https://aidanjmeyers.github.io/c4c-strategic-planning/
```

Send the board that URL + the access word. Done.

---

## Run locally
It's a static site, but `config.js` and the Supabase client need to be served over
HTTP (not `file://`):
```bash
python -m http.server 8000
# then open http://localhost:8000
```

## During the session
Screen-share the live URL. As people submit, the view updates on its own (Supabase
realtime, with a 15-second poll as a fallback). The connection pill by the name
selector reads **Live** when it's connected.

## Export the merged responses
Click **Export all responses** at the bottom any time. It downloads
`C4C_Strategic_Planning_Feedback.txt` containing every person's priority ranking,
every scale pick, and every logged answer, grouped by block — the full packet.

## Reuse next year (wipe the data)
Supabase → SQL Editor → run:
```sql
truncate public.responses, public.scale_picks, public.rankings;
```
The structure stays; all responses are cleared.

---

## How it's protected
- **RLS is on** for all three tables. The anon key can **read**, **insert**, and
  **update** (updates are needed for scale-pick and ranking upserts), but has **no
  delete policy** — so it cannot bulk-delete rows through the table API.
- Deleting your own free-text answer goes through `delete_own_response(id, name)`, a
  `security definer` function that only removes a row when both the id and the
  respondent name match. The delete button is shown only on your own cards.
- The passphrase gate (client-side, `sessionStorage`) keeps casual crawlers from
  writing rows. It is intentionally lightweight.

## Files
| File | Purpose |
|------|---------|
| `index.html` | The whole app — UI, and Supabase read/write/realtime. |
| `config.js` | The three values you edit: URL, anon key, passphrase. |
| `schema.sql` | Run once in Supabase to create tables + policies + realtime. |
| `.github/workflows/deploy.yml` | Publishes to GitHub Pages on push to `main`. |
