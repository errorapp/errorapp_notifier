module ErrorappNotifier
  class Sanitizer
    def self.sanitize_hash(hash)
      case hash
      when Hash
        hash.inject({}) do |result, (key, value)|
          result.update(key => sanitize_hash(value))
        end
      when Array
        hash.collect{|value| sanitize_hash(value)}
      when Fixnum, String, Bignum
        hash
      else
        hash.to_s
      end
    end

    def self.filter_hash(keys_to_filter, hash)
      keys_to_filter.map!{ |key| key.to_s }
      if keys_to_filter.is_a?(Array) && !keys_to_filter.empty?
        hash.each do |key, value|
          if key_match?(key, keys_to_filter)
            hash[key] = '[FILTERED]'
          elsif value.respond_to?(:to_hash)
            filter_hash(keys_to_filter, hash[key])
          end
        end
      end
      hash
    end

    def self.sanitize_session(request)
      session_hash = {'session_id' => "", 'data' => {}}

      if request.respond_to?(:session)
        session = request.session
        session_hash['session_id'] = request.session_options ? request.session_options[:id] : nil
        session_hash['session_id'] ||= session.respond_to?(:session_id) ? session.session_id : session.instance_variable_get("@session_id")
        session_hash['data'] = session.respond_to?(:to_hash) ? session.to_hash : session.instance_variable_get("@data") || {}
        session_hash['session_id'] ||= session_hash['data'][:session_id]
        session_hash['data'].delete(:session_id)
      end

      sanitize_hash(session_hash)
    end

    private

    def self.key_match?(key, keys_to_filter)
      keys_to_filter.any? do |k|
        regexp = k.is_a?(Regexp)? k : Regexp.new(k.to_s, true)
        key =~ regexp
      end
    end
  end
end
