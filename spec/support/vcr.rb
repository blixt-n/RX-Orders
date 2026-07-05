require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  # Add `vcr: true` to an RSpec block to record the request.  If you need to repeat this, delete the resulting YAML file to trigger it again.
  config.configure_rspec_metadata!

  # Scrub data so we don't commit prod data.
  config.before_record do |interaction|
    if interaction.response.body.is_a?(String)
      # Add more lines as necessary
      # interaction.response.body.gsub!("Sensitive Data", "Fake Data")
    end
  end
end
