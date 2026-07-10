require "faraday" # Necessary for rescues below

Circuitbox.configure do |config|
  config.default_circuit_store = Circuitbox::MemoryStore.new
end

shared_config = {
  volume_threshold: 10,
  error_threshold: 50, # failures/total %
  sleep_window: 60     # seconds
}

stripe_exceptions = [
  Stripe::APIConnectionError,
  Stripe::RateLimitError
]

STRIPE_CIRCUIT = Circuitbox.circuit(:stripe_api,
                                    exceptions: stripe_exceptions,
                                    **shared_config
)

twilio_exceptions = [
  Twilio::REST::RestError,
  Twilio::REST::TwilioError,
  Faraday::ConnectionFailed,
  Faraday::TimeoutError
]

TWILIO_CIRCUIT = Circuitbox.circuit(:twilio_api,
                                   exceptions: twilio_exceptions,
                                   **shared_config)
