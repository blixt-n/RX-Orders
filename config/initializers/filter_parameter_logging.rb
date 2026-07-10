# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]

# Filtering attributes
Rails.application.config.filter_parameters += [
  :email, :phone_number, :medication_name
]

# Filtering API
Rails.application.config.filter_parameters += [
  :api_key, :client_secret, :client_id, :bearer, :authorization, :auth_token, :access_token
]
