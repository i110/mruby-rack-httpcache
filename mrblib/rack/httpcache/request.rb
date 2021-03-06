module Rack
  class HTTPCache
    class Request < Rack::Request
      include Utils

      attr_reader :time

      def initialize(env, options = {})
        super(env)
        @options = options
        @trace = []
        @time = options[:time] ? Time.at(options[:time]) : Time.now
        @private_header_keys = (options[:private_headers] || []).map{|h| env_key(h) }
        @cache_key = options[:cache_key]
      end
    
      def cache_control
        @cache_control ||= CacheControl.new(env['HTTP_CACHE_CONTROL'])
      end
      def no_cache?
        cache_control.no_cache? || env['HTTP_PRAGMA'] == 'no-cache'
      end
      def private?
        @private_header_keys.any? {|key| env.include?(key) }
      end
      def record(value)
        @trace << value
      end
      def recorded
        @trace.join(',')
      end
      def headers
        @headers ||= env_to_headers(env)
      end
      def cache_key
        if @cache_key
          if @cache_key.respond_to?(:call)
            @cache_key.call(self)
          else
            @cache_key
          end
        else
          url
        end
      end
    end
  end

end
