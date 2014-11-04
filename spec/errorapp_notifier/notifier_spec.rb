require 'spec_helper'

describe ErrorappNotifier::Notifier do
  before :each do
    ErrorappNotifier.configure do|config|
      config.api_key = 'api-key'
    end
  end

  it 'should call notify_error to send exception data' do
    ErrorappNotifier::Notifier.stub(:notify_error)
    exception_data = double(:uniq_key => 1, :to_json => 'something')

    ErrorappNotifier::Notifier.notify_error(exception_data)

    expect(ErrorappNotifier::Notifier).to have_received(:notify_error)
  end

  describe 'notify_error' do
    it 'should get 200 when sending exception' do
      exception_data = double(:uniq_key => 1, :to_json => 'something')

      stub_request(
        :post,
        "http://errorapp.com/api/projects/api-key/fails?hash=#{exception_data.uniq_key}&protocol_version=#{ErrorappNotifier::PROTOCOL_VERSION}"
      ).with(:body => exception_data.to_json).to_return(:status => 200, :body => "", :headers => {})

      ErrorappNotifier::Notifier.notify_error(exception_data)
    end
  end
end
