namespace :errorapp_notifier do
  desc "Send a test exception to Errorapp."
  task :test_exception => :environment do
    ErrorappNotifier::Integration.test
  end
end
