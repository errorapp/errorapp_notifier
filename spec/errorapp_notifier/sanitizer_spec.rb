require 'spec_helper'

describe ErrorappNotifier::Sanitizer do
  describe '.sanitize_hash' do
    it "filter out objects that aren't jsonable" do
      class Crazy
        def initialize
          @bar = self
        end
      end
      crazy = Crazy.new
      input = {'crazy' => crazy, :simple => '123',
               :some_hash => {'1' => '2'}, :array => ['1', '2']}
      ErrorappNotifier::Sanitizer.sanitize_hash(input).should == {'crazy' => crazy.to_s,
                                                                  :simple => '123', :some_hash => {'1' => '2'}, :array => ['1', '2']}
    end

    it "to_strings regex because JSON.parse(/aa/.to_json) doesn't work" do
      input = {'crazy' => /abc.*/}
      ErrorappNotifier::Sanitizer.sanitize_hash(input).should == {'crazy' => /abc.*/.to_s}
    end

    it "handles session objects with various interfaces" do
      class SessionWithInstanceVariables
        def initialize
          @data = {'a' => '1', 'b' => /hello there Im a regex/i}
          @session_id = '123'
        end
      end

      request = ActionDispatch::TestRequest.new
      session = SessionWithInstanceVariables.new
      request.stub(:session).and_return(session)
      request.stub(:session_options).and_return({})
      ErrorappNotifier::Sanitizer.sanitize_session(request).should == {'session_id' => '123', 'data' => {'a' => '1', 'b' => "(?i-mx:hello there Im a regex)"}}
      session = double('session', :session_id => '123', :instance_variable_get => {'a' => '1', 'b' => /another(.+) regex/mx})
      request.stub(:session).and_return(session)
      ErrorappNotifier::Sanitizer.sanitize_session(request).should == {'session_id' => '123', 'data' => {'a' => '1', 'b' => "(?mx-i:another(.+) regex)"}}
      session = double('session', :session_id => nil, :to_hash => {:session_id => '123', 'a' => '1'})
      request.stub(:session).and_return(session)
      ErrorappNotifier::Sanitizer.sanitize_session(request).should == {'session_id' => '123', 'data' => {'a' => '1'}}
      request.stub(:session_options).and_return({:id => 'xyz'})
      ErrorappNotifier::Sanitizer.sanitize_session(request).should == {'session_id' => 'xyz', 'data' => {'a' => '1'}}
    end

    it "allow if non jsonable objects are hidden in an array" do
      class Bonkers
        def to_json
          no.can.do!
        end
      end
      crazy = Bonkers.new
      input = {'crazy' => [crazy]}
      ErrorappNotifier::Sanitizer.sanitize_hash(input).should == {'crazy' => [crazy.to_s]}
    end
  end
end
