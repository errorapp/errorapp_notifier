require 'spec_helper'
require 'digest/md5'
require 'time'

describe ErrorappNotifier::FailureData do
  describe "#to_hash" do
    before do
      @exception = ErrorappNotifier::FailureData.new(build_exception).to_hash
    end

    it "should get exception data" do
      expect(@exception[:exception][:exception_class]).to eq("TestException")
      expect(@exception[:exception][:message]).to match(/Something is not good/)
      expect(@exception[:exception][:backtrace]).not_to be_empty
      expect(@exception[:exception][:occurred_at]).to eq(Time.now.utc.iso8601)
    end

    it "should get application data" do
      expect(@exception[:application_environment][:environment]).to eq('test')

      expect(@exception[:application_environment][:env].class).to eq(Hash)
      expect(@exception[:application_environment][:env].keys).to include('PATH','HOME', 'GEM_HOME', 'BUNDLE_BIN_PATH')
    end
  end
end

def build_exception
  backtrace = ["errorapp/spec/helper.rb:8:in `deafult_message'",
               "errorapp/spec/spec_helper.rb:4:in `require'",
                 "lib/active_support/dependencies.rb:247:in `require'"]
  TestException.new(:backtrace => backtrace)
end
