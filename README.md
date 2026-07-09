# RX Orders

RX Orders is a headless Rails API designed to demonstrate a robust, asynchronous payment processing architecture 
using Stripe. By decoupling the checkout process and relying entirely on Stripe Webhooks as the source of truth, 
this project showcases how to safely handle payment state, prevent race conditions, and offload PCI compliance. 
Background processing is handled via Sidekiq and Redis.

## Out of Scope for Project (Handled in Production)
- Authentication
- Frontend
- Lograge (adding would be preferred for JSON logs that are easy to read)
- Sentry (error capturing would be mandatory)

## Getting Started

This application is fully containerized. You do not need Ruby, Redis, or Sidekiq installed on your host machine to run this project—everything is orchestrated via Docker.

### Prerequisites
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

### 1. Initial Setup
Create your local environment variables file by copying the provided example template:
```bash
cp .env.example .env
```
*(Note: You will need to fill in your actual Stripe credentials in the `.env` file before processing payments. See the Stripe Setup section below.)*

Build the Docker images and install the Ruby gems. *(This may take a few minutes the first time as it downloads the base images).*
```bash
docker compose build
```

### 2. Database Creation
Once the images are built, initialize the PostgreSQL database:
```bash
docker compose run --rm web bin/rails db:setup
```

Note that a custom rake task enhances `db:seed` to reseed fake local data.  The database can be reseeded at any time 
by running:
```bash
docker compose run --rm web bin/rails db:seed
``` 

### 3. Running the Application
Start the entire local development stack:
```bash
docker compose up
```

This command spins up the following services simultaneously:
* **web:** The main Rails API server (running on `localhost:3000`).
* **db:** The PostgreSQL database.
* **redis:** The in-memory data store required for background jobs.
* **sidekiq:** The background job processor (handles async webhook processing).
* **stripe-cli:** The headless webhook listener (requires `.env` configuration).

To stop the server, press `CTRL+C` in your terminal, or run `docker compose down` in a separate tab to cleanly spin down all containers.

## Payment Architecture: Stripe PaymentIntents

This project uses a decoupled integration with Stripe's modern PaymentIntents API. This architecture ensures our backend remains highly available, prevents web workers from hanging on third-party network requests, and entirely offloads PCI compliance to Stripe.

The checkout lifecycle follows a strict three-step async flow:

### 1. Intent Initiation
* **Action:** The React frontend (does not exist in this project) requests a checkout session via `POST 
/api/v1/orders/:id/checkout`.
* **Backend:** The Rails API initiates a `Stripe::PaymentIntent` and returns a secure `client_secret`.
* **Result:** The web worker completes the request in milliseconds and is immediately freed to serve other users.

### 2. Client-Side Processing (Zero Backend Load)
* **Action:** The frontend uses Stripe Elements to securely mount the payment UI.
* **Processing:** The user inputs their card details, and the React app communicates *directly* with Stripe using the `client_secret`. Our Rails backend is completely bypassed during this step, meaning no sensitive card data ever touches our servers.
* **Authentication:** Any bank-mandated 2FA or 3D Secure challenges are handled securely in the browser between Stripe and the customer.

### 3. Asynchronous Fulfillment (Source of Truth)
* **Action:** Upon successful payment, Stripe fires a `payment_intent.succeeded` webhook to our API.
* **Backend:** The Rails app receives the webhook, cryptographically verifies the signature to prevent spoofing, and immediately returns a `200 OK` to Stripe.
* **Fulfillment:** The order is handed off to a Sidekiq background job for fulfillment (inventory adjustments, emails, etc.). Using the webhook as the single source of truth ensures that even if the user closes their browser during the final redirect, the order is still reliably processed.

## Stripe Setup and Configuration

This application relies on Stripe for payment processing and Stripe Webhooks to asynchronously update order statuses 
(e.g., transitioning an order to `paid` or `failed`). Everything runs entirely in Stripe's "Test Mode", allowing us 
to safely simulate full payment lifecycles using test credit card numbers without incurring real charges.

### 1. Create a Free Stripe Test Account
You do not need a real business or bank account to develop with Stripe. You can do everything in "Test Mode" for free.

1. Go to [dashboard.stripe.com/register](https://dashboard.stripe.com/register) and create an account.
2. Verify your email address.
3. When you log in, you will see a prompt to "Activate your account" or add business details. **Ignore this.**
4. Look at the top right of the dashboard and ensure the **Test mode** toggle is switched on. As long as you are in test mode, you can use all of Stripe's API features safely with fake credit cards.

### 2. Configure your Stripe API Key
Because the Stripe CLI runs headlessly in Docker for this project, you will need to generate a Restricted API Key instead of using the browser-based `stripe login` flow.

1. In your Stripe Dashboard, go to **Developers > API keys**.
2. Click **Create restricted key**. Give it "Write" permissions for Webhooks.
3. Add this key to your project's `.env` file:
   ```env
   STRIPE_API_KEY=rk_test_your_restricted_key_here
   ```

### 3. Webhook Listener (Stripe CLI)
To keep the host machine clean and perfectly simulate webhook events, the official Stripe CLI is bundled directly into our `docker compose.yml` stack.

When you run `docker compose up`, the CLI container automatically starts, authenticates using your `.env` key, and forwards all test-mode webhook events directly to the Rails `web` container at `/api/v1/webhooks/stripe`.

**Important First-Time Setup:**
1. Check the logs of the `stripe-cli` container when it first boots. It will output a webhook signing secret (`whsec_...`).
2. Add this secret to your `.env` file as `STRIPE_WEBHOOK_SECRET`.
3. Restart the web container (`docker compose restart web`) so Rails can load the secret into memory and successfully verify the incoming payload signatures.

## Testing Payments
### Checkout
Find a pending order in the Rails console using `Order.pending.ids` and submit a curl command from a terminal for 
one of the pending orders.
```bash
curl -X POST http://localhost:3000/api/v1/orders/:id/checkout \
  -H "Accept: application/json"
```
This will submit a request to Stripe to return a client secret, which would be used in the frontend app, and it will 
also trigger a webhook.  The traffic can be seen both in the web container logs and the stripe-cli logs.  The 
stripe-cli logs look like this:
```
2026-07-10 12:18:11   --> payment_intent.created [evt_3TrdNeK5PJtLkbsN1yuUcju4]
2026-07-10 12:18:11  <--  [200] POST http://web:3000/api/v1/webhooks/stripe [evt_3TrdNeK5PJtLkbsN1yuUcju4]
```

## Stripe References
- [Webhook Best Practices](https://docs.stripe.com/webhooks)
- [Stripe CLI](https://docs.stripe.com/cli)
- [Payment Intents API](https://docs.stripe.com/api/payment_intents)
- [API Limits](https://docs.stripe.com/rate-limits)
