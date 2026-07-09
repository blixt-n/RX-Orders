module StructuredLogging
  extend ActiveSupport::Concern

  private

  def log_event(event, level: :info, payload: {})
    context = prepare_context(payload: payload, to_merge: { event: event })

    Rails.logger.public_send(level, context.to_json)
  end

  def report_exception(exception, level: :error, custom_message: nil, payload: {})
    exception_data = {
      custom_message: custom_message,
      error_class: exception.class.name,
      error_message: exception.message
    }.compact
    context = prepare_context(payload: payload, to_merge: exception_data)

    Rails.logger.public_send(level, context.to_json)

    Rails.error.report(exception, handled: true, severity: :error, context: context)
  end

  def prepare_context(payload: payload, to_merge: {})
    filtered_payload = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
                                                     .filter(payload)
    context = { tag: "[#{self.class.name}]" }
                .merge(to_merge)
                .merge(filtered_payload)

    context[:job_id] = job_id if respond_to?(:job_id)
    context
  end
end
