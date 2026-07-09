Circuitbox.configure do |config|
  config.default_circuit_store = Circuitbox::MemoryStore.new
end

stripe_exceptions = [
  Stripe::APIConnectionError,
  Stripe::RateLimitError
]

STRIPE_CIRCUIT = Circuitbox.circuit(:stripe_api,
                                    exceptions: stripe_exceptions,
                                    volume_threshold: 10,
                                    error_threshold: 50, # failures/total %
                                    sleep_window: 60     # seconds
)
