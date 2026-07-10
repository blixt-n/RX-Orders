# NOTE: These are fake since no Twilio account was created
TWILIO_ACCOUNT_SID  = ENV.fetch("TWILIO_ACCOUNT_SID", "AC#{'0' * 32}")
TWILIO_AUTH_TOKEN   = ENV.fetch("TWILIO_AUTH_TOKEN", "0" * 32)
TWILIO_PHONE_NUMBER = ENV.fetch("TWILIO_PHONE_NUMBER", "+15555555555")
