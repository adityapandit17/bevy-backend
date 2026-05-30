# Google Calendar — Single Gmail (Bevy platform account)

Use **one personal Gmail** for both Bevy outbound email (SMTP) and interview calendar events. Per-company / Google Workspace OAuth is planned later.

## Email vs calendar (same Gmail, two credentials)

| Feature | Credential | Config |
|--------|------------|--------|
| Send Bevy emails | Gmail **App Password** | `GMAIL_USERNAME`, `GMAIL_APP_PASSWORD` in `backend/.env` |
| Calendar events + invites | **OAuth 2.0** (Client ID, Secret, Refresh token) | `GOOGLE_CALENDAR_*` in `backend/.env` and/or Settings → Integrations |

The App Password does **not** work for Calendar API. You authorize the same Gmail once via OAuth.

---

## Quick start

### 1. Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) → **New project** (e.g. `BevyHR Calendar`).
2. **APIs & Services → Library** → enable **Google Calendar API**.
3. **OAuth consent screen**
   - User type: **External**
   - App name, support email, developer email
   - **Scopes**: `https://www.googleapis.com/auth/calendar`, `https://www.googleapis.com/auth/userinfo.email`
   - **Test users**: add your **exact** `@gmail.com` (required while app is in Testing)
4. **Credentials → Create credentials → OAuth client ID**
   - Type: **Web application**
   - **Authorized redirect URIs** (dev):
     ```
     http://localhost:3000/api/v1/google_calendar/callback
     ```
   - Copy **Client ID** and **Client secret**

### 2. Gmail App Password (for sending mail)

1. Google Account → **Security** → **2-Step Verification** (on).
2. **App passwords** → create for Mail → set `GMAIL_APP_PASSWORD` in `.env`.
3. Use the **same** address for `GMAIL_USERNAME`.

### 3. Connect BevyHR (choose one method)

#### Method A — Settings → Integrations (recommended)

`backend/.env`:

```bash
GMAIL_USERNAME="your@gmail.com"
GMAIL_APP_PASSWORD="your-16-char-app-password"

GOOGLE_CALENDAR_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_CALENDAR_CLIENT_SECRET=...
GOOGLE_CALENDAR_REDIRECT_URI=http://localhost:3000/api/v1/google_calendar/callback
APP_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3001
GOOGLE_CALENDAR_TIME_ZONE=Asia/Kolkata
```

Restart Rails + job worker. In the app: **Settings → Integrations → Google Workspace → Connect** → sign in with the same Gmail.

#### Method B — Platform account in `.env` only

Same Client ID/Secret, then get a refresh token via [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/) (gear → use your OAuth credentials, scope `calendar`).

```bash
GOOGLE_CALENDAR_ENABLED=true
GOOGLE_CALENDAR_REFRESH_TOKEN=...
GOOGLE_CALENDAR_PLATFORM_EMAIL=your@gmail.com
```

When `GOOGLE_CALENDAR_ENABLED=true`, the **platform account in env takes priority** over a company connection from Settings.

### 4. Verify

1. Solid Queue / `bin/jobs` running.
2. Schedule a **video** interview with candidate + interviewer emails.
3. Check interview row: `google_calendar_html_link`, `google_meet_link`.
4. Confirm event on your Gmail calendar and **invite emails** to attendees.
5. Cancel interview → event removed.

---

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_CALENDAR_CLIENT_ID` | Yes | OAuth Web client ID |
| `GOOGLE_CALENDAR_CLIENT_SECRET` | Yes | OAuth client secret |
| `GOOGLE_CALENDAR_REDIRECT_URI` | Dev | Defaults to `{APP_URL}/api/v1/google_calendar/callback` |
| `GOOGLE_CALENDAR_ENABLED` | Platform mode | `true` + refresh token → use env account first |
| `GOOGLE_CALENDAR_REFRESH_TOKEN` | Platform mode | Refresh token for platform Gmail |
| `GOOGLE_CALENDAR_PLATFORM_EMAIL` | Optional | Display email (defaults to `GMAIL_USERNAME`) |
| `GOOGLE_CALENDAR_ID` | Optional | Calendar ID (default `primary`) |
| `GOOGLE_CALENDAR_TIME_ZONE` | Optional | e.g. `Asia/Kolkata` |
| `GOOGLE_CALENDAR_EVENT_DURATION_MINUTES` | Optional | Default `60` |

---

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/google_calendar/status` | `mode`: `platform` \| `company` \| `disconnected` |
| GET | `/api/v1/google_calendar/authorize_url` | OAuth URL (company connect) |
| GET | `/api/v1/google_calendar/callback` | OAuth redirect |
| DELETE | `/api/v1/google_calendar/disconnect` | Clears **company** tokens only (not env platform) |

---

## Interview sync behavior

- **Scheduled** → create/update event; `send_updates: all` emails attendees
- **Video** → Google Meet link on event
- **Cancelled / completed / no_show** → delete event
- Async: `SyncInterviewCalendarJob`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Connect disabled in UI | Set `GOOGLE_CALENDAR_CLIENT_ID` and `CLIENT_SECRET`; restart server |
| `redirect_uri_mismatch` | See **Redirect URI mismatch** below |
| `access_denied` / can't sign in | Add your Gmail under OAuth consent **Test users** |
| No refresh token | Revoke app at [Google permissions](https://myaccount.google.com/permissions), reconnect with `prompt=consent` |
| Events not created | Platform: `GOOGLE_CALENDAR_ENABLED=true` + token; or Settings connected; check job worker and `[GoogleCalendar]` logs |
| Platform mode in UI but no events | Confirm `GOOGLE_CALENDAR_REFRESH_TOKEN` is valid |

---

## Redirect URI mismatch (`redirect_uri_mismatch`)

Google’s error page shows the exact URI BevyHR sends, e.g.:

`http://localhost:3000/api/v1/google_calendar/callback`

Fix it in **Credentials** (not the OAuth consent screen branding page):

1. [Google Cloud Console](https://console.cloud.google.com/) → select the **same project** where you created the OAuth client.
2. **APIs & Services → Credentials**.
3. Open your **OAuth 2.0 Client ID** — type must be **Web application** (Desktop / iOS / Android clients will not accept this redirect).
4. Under **Authorized redirect URIs**, click **Add URI** and paste **exactly** (no trailing slash):
   ```
   http://localhost:3000/api/v1/google_calendar/callback
   ```
5. **Save**. Wait 1–2 minutes for Google to propagate.
6. Confirm `GOOGLE_CALENDAR_CLIENT_ID` in `backend/.env` matches this client’s Client ID (numeric prefix before `-` should match).
7. Restart Rails (`bin/rails server`) and try **Connect** again.

**Authorized JavaScript origins** (optional for this flow): `http://localhost:3001` — this does **not** replace redirect URIs.

Settings → Integrations shows the redirect URI and client ID prefix to copy when not connected.

---

## Later (not implemented yet)

- Per-client company Google / Workspace accounts
- Domain-wide delegation for Workspace
- Replacing OAuth with `.ics`-only email invites
