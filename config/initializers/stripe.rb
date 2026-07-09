Stripe.api_key = ENV["STRIPE_API_KEY"]
Stripe.api_version = "2026-06-24.dahlia"
Stripe.max_network_retries = 3 # Handles exponential backoff and jitter
Stripe.logger = Rails.logger
