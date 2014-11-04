require 'net/http'
require 'net/https'

module ErrorappNotifier
  class Notifier
    def initialize(data, uniq_key = nil)
      @uniq_key = uniq_key
      @data = data
    end

    def self.notify_error(exception_data)
      new(
        exception_data.to_json,
        exception_data.uniq_key
      ).notify_error
    end

    def notify_error
      log_and_send do
        client.post(url, data)
      end
    end

    private

    attr_reader :data, :uniq_key

    def url
      "/api/projects/#{config.api_key}/fails?protocol_version=#{PROTOCOL_VERSION}#{hash_param}"
    end

    def hash_param
      unless uniq_key.nil?
        "&hash=#{uniq_key}"
      end
    end

    def log_and_send
      begin
        response = yield
        case response
        when Net::HTTPSuccess
          ErrorappNotifier.logger.info("Error reported to Errorapp")
        else
          log_error(response.message)
        end
      rescue Exception => e
        log_error
        ErrorappNotifier.logger.error(e)
      end
    end

    def config
      ErrorappNotifier.configuration
    end

    def log_error(message = '')
      ErrorappNotifier.logger.error(
        "Problem notifying Errorapp about the error #{message}"
      )
    end

    def client
      client = optional_proxy.new(config.remote_host, config.remote_port)
      client.open_timeout = config.http_open_timeout
      client.read_timeout = config.http_read_timeout
      client.use_ssl = config.ssl?
      client.verify_mode = OpenSSL::SSL::VERIFY_NONE if config.ssl?
      client
    end

    def optional_proxy
      Net::HTTP::Proxy(config.http_proxy_host,
                       config.http_proxy_port,
                       config.http_proxy_username,
                       config.http_proxy_password
                      )
    end
  end
end
