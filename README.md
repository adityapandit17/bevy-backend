# BevyHR Backend

Rails 8.1 API for the BevyHR tenant app, platform admin (`bevy-admin`), and public signup/pricing endpoints.

## Prerequisites

- Ruby 3.x (see `.ruby-version`)
- PostgreSQL
- Bundler

## Setup

```bash
cd backend
bundle install
cp .env.example .env   # then edit .env
bin/rails db:create db:migrate db:seed
bin/rails server -p 3000
```

Default tenant login (after seed): `admin@hrms.com` / `admin123`

Platform admin (bevy-admin): `admin@bevyhr.com` / `admin123`

---

## Stripe billing setup

Tenant subscriptions use **Stripe** for recurring per-seat billing. The payment layer is gateway-based (`PAYMENT_GATEWAY=stripe`); additional gateways can be added without changing billing controllers.

### 1. Create a Stripe account

1. Sign up at [https://dashboard.stripe.com/register](https://dashboard.stripe.com/register)
2. Stay in **Test mode** for local development (toggle in the Stripe Dashboard)

### 2. Get API keys

In Stripe Dashboard → **Developers → API keys**:

| Key | Env variable | Notes |
|-----|--------------|--------|
| Secret key | `STRIPE_SECRET_KEY` | Starts with `sk_test_` (test) or `sk_live_` (production) |
| Publishable key | `STRIPE_PUBLISHABLE_KEY` | Starts with `pk_test_` or `pk_live_`; exposed to tenant frontend via billing summary API |

### 3. Configure backend environment

Add to `backend/.env`:

```bash
PAYMENT_GATEWAY=stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Also ensure the tenant app URL is set (used for Stripe Checkout success/cancel redirects):

```bash
FRONTEND_URL=http://localhost:3001
```

Restart the Rails server after changing `.env`.

### 4. Run migrations

Billing tables and company gateway fields are created by standard migrations:

```bash
cd backend
bundle exec rails db:migrate
```

If setting up a fresh database:

```bash
bundle exec rails db:create db:migrate db:seed
```

Seeds include published pricing plans (`db/seeds/platform_saas.rb`).

### 5. Install Stripe CLI (local webhooks)

Webhooks activate subscriptions and sync invoices after checkout. For local development, use the [Stripe CLI](https://stripe.com/docs/stripe-cli):

```bash
# macOS
brew install stripe/stripe-cli/stripe

# Login once
stripe login
```

Forward events to the Rails webhook endpoint:

```bash
stripe listen --forward-to localhost:3000/api/v1/webhooks/payment/stripe
```

The CLI prints a webhook signing secret like `whsec_...`. Copy it into `STRIPE_WEBHOOK_SECRET` in `.env` and restart Rails.

**Handled webhook events:**

- `checkout.session.completed` — activates subscription after first purchase
- `invoice.paid` — records invoice / receipt
- `invoice.payment_failed` — marks company past due
- `customer.subscription.updated` — syncs renewal date and status
- `customer.subscription.deleted` — handles cancellation

### 6. Test the flow

1. Start backend (`bin/rails server -p 3000`) and frontend (`yarn dev:3001` in `frontend/`)
2. Run `stripe listen --forward-to localhost:3000/api/v1/webhooks/payment/stripe` in a separate terminal
3. Log into the tenant app as a **Super Admin** on a trial company
4. Go to **Settings → Billing** (or `/billing` when locked)
5. Click **Purchase subscription** / **Upgrade now** → complete Stripe Checkout with a [test card](https://stripe.com/docs/testing#cards) (e.g. `4242 4242 4242 4242`)
6. Confirm the webhook fires and company status becomes `active`

Use Stripe Dashboard → **Developers → Events** to debug webhook delivery.

### 7. Production notes

- Switch Stripe Dashboard to **Live mode** and use `sk_live_` / `pk_live_` keys
- Create a **live** webhook endpoint in Stripe Dashboard pointing to:
  `https://your-api-domain.com/api/v1/webhooks/payment/stripe`
- Subscribe to the events listed above; set the live signing secret as `STRIPE_WEBHOOK_SECRET`
- Set `FRONTEND_URL` to your production tenant app URL

---

## Billing API (tenant)

All routes require JWT auth. Accessible even when subscription is locked (for checkout).

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/billing/summary` | Plan, status, invoices, gateway config |
| POST | `/api/v1/billing/checkout` | Create Stripe Checkout session |
| POST | `/api/v1/billing/change_plan` | Change plan with Stripe proration |
| POST | `/api/v1/billing/portal` | Stripe Customer Portal URL |
| GET | `/api/v1/billing/invoices` | Invoice history |

Webhook (no auth — verified by Stripe signature):

| Method | Path |
|--------|------|
| POST | `/api/v1/webhooks/payment/stripe` |

---

## Tests

```bash
bin/rails test
bin/rubocop
bin/brakeman
```

---

## Other configuration

See `.env.example` for database, mail, Google Calendar, and `FRONTEND_URL`.

After deploy, run:

```bash
bin/rails roles:sync_employee_self_service
```

so Employee roles get attendance/leave permissions in production databases.
