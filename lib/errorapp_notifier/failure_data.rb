require 'digest/md5'
require 'time'
require 'errorapp_notifier/exception_data'
require 'errorapp_notifier/application_environment_data'

module ErrorappNotifier
  class FailureData
    def initialize(exception, name = nil)
      @exception = exception
      @name = name
    end

    def to_hash
      hash = {}
      hash.merge!(ExceptionData.new(@exception).data)
      hash.merge!(ApplicationEnvironmentData.new(@exception).data)
      hash.merge!(extra_stuff)
      hash.merge!(context_stuff)
      hash.merge!(errorapp_client_data)
      rescue_sanitize_hash do
        Sanitizer.sanitize_hash(hash)
      end
    end

    def to_json
      begin
        to_hash.to_json
      rescue NoMethodError
        begin
          require 'json'
          return to_hash.to_json
        rescue StandardError => e
          ErrorappNotifier.logger.error(e.message)
          ErrorappNotifier.logger.error(e.backtrace)
          raise StandardError.new("You need a json gem/library installed to send errors to ErrorApp (Object.to_json not defined). \nInstall json_pure, yajl-ruby, json-jruby, or the c-based json gem")
        end
      end
    end

    def uniq_key
      return nil if (@exception.backtrace.nil? || @exception.backtrace.empty?)
      Digest::MD5.hexdigest(@exception.backtrace.join)
    end

    private

    def errorapp_client_data
      {
        :client =>
        {
          :name => ErrorappNotifier::CLIENT_NAME,
          :version => ErrorappNotifier::VERSION,
          :protocol_version => ErrorappNotifier::PROTOCOL_VERSION
        }
      }
    end

    def extra_stuff
      { :rescue_block => {:name => @name} }
    end

    def context_stuff
      context = Thread.current[:notifier_context]
      (context.nil? || context.empty?) ? {} : {'context'=> context}
    end

    def extract_http_headers(env)
      headers = {}
      env.select{|k, v| k =~ /^HTTP_/}.each do |name, value|
        proper_name = name.sub(/^HTTP_/, '').split('_').map{|upper_case| upper_case.capitalize}.join('-')
        headers[proper_name] = value
      end
      unless headers['Cookie'].nil?
        headers['Cookie'] = headers['Cookie'].sub(/_session=\S+/, '_session=[FILTERED]')
      end
      headers
    end

    def rescue_sanitize_hash
      begin
        yield
      rescue Exception
        {}
      end
    end
  end
end
