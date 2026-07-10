class TwilioClient
  include StructuredLogging

  SERVICE_UNAVAILABLE_MSG = "SMS service temporarily unavailable. Please try again later.".freeze
  GENERIC_ERROR_MSG = "An unexpected error occurred while processing the SMS.".freeze

  def initialize
    @client = Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
  end

  def send_sms(phone_number:, body:)
    formatted_number = format_phone_number(phone_number)
    response = TWILIO_CIRCUIT.run { execute_api_request(formatted_number, body) }
    handle_api_response(response, formatted_number)

  rescue Circuitbox::OpenCircuitError, Circuitbox::ServiceFailureError, Twilio::REST::TwilioError, Faraday::Error => e
    handle_network_error(e, formatted_number)
  rescue => e
    handle_unexpected_error(e, formatted_number)
  end

  private

  def format_phone_number(number)
    clean_digits = number.to_s.gsub(/\D/, "")
    "+1#{clean_digits.last(10)}"
  end

  def execute_api_request(formatted_number, body)
    message = @client.messages.create(
      from: TWILIO_PHONE_NUMBER,
      to: formatted_number,
      body: body
    )
    { success: true, message_sid: message.sid }
  rescue Twilio::REST::RestError => e
    { success: false, type: :api_error, error: e.message, code: e.code, exception: e }
  end

  def handle_api_response(response, formatted_number)
    if response[:success]
      log_event("twilio_sms_sent", payload: { to: formatted_number, message_sid: response[:message_sid] })
      { success: true, message_sid: response[:message_sid] }
    elsif response[:type] == :api_error
      report_exception(response[:exception], custom_message: "Twilio Invalid Payload", payload: { to: formatted_number, twilio_code: response[:code] })
      { success: false, error: response[:error] }
    end
  end

  def handle_network_error(error, formatted_number)
    original = error.respond_to?(:original) ? error.original : (error.cause || error)
    report_exception(original, custom_message: "Twilio Network Error", payload: { to: formatted_number })
    { success: false, error: SERVICE_UNAVAILABLE_MSG }
  end

  def handle_unexpected_error(error, formatted_number)
    report_exception(error, custom_message: "Twilio Unexpected Error", payload: { to: formatted_number })
    { success: false, error: GENERIC_ERROR_MSG }
  end
end
