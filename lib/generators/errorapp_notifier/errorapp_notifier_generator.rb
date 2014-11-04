require 'rails/generators'

class ErrorappNotifierGenerator < Rails::Generators::Base
  desc "Creates the ErrorApp initializer file at config/errorapp_notifier.rb"

  class_option :api_key, :aliases => "-k", :type => :string,
    :desc => "Your ErrorApp API key"

  def self.source_root
    @_errorapp_source_root ||= File.expand_path("../templates", __FILE__)
  end

  def install
    ensure_api_key_was_configured
    generate_initializer unless api_key_configured?
    test_errorapp
  end

  private

  def ensure_api_key_was_configured
    if !options[:api_key] && !api_key_configured?
      puts "Must pass --api_key or create config/initializers/errorapp_notifier.rb"
      exit
    end
  end

  def api_key
    if options[:api_key]
      "'#{options[:api_key]}'"
    end
  end

  def generate_initializer
    template 'errorapp_notifier.rb', 'config/initializers/errorapp_notifier.rb'
  end

  def api_key_configured?
    File.exists?('config/initializers/errorapp_notifier.rb')
  end

  def test_errorapp
    puts run("rails runner ErrorappNotifier::Integration.test")
  end

  def configuration_output
    output = <<-eos
ErrorappNotifier.configure do|config|
  config.api_key = '#{options[:api_key]}'
end
    eos
    output
  end
end
