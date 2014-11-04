require 'errorapp_notifier'
require 'action_controller'
require 'json'
require 'webmock/rspec'
require 'helper'

ENV['RAILS_ENV'] = 'test'

WebMock.disable_net_connect!(:allow_localhost => true)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
