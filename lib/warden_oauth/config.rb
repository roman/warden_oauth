module Warden
  module OAuth
    
    class Config
      attr_accessor :provider_name
      
      def consumer_key(key = nil)
        @consumer_key ||= key
      end

      def consumer_secret(secret = nil)
        @consumer_secret ||= secret
      end

      def options(options = nil) 
        @options ||= options
      end

      def check_requirements
        if @consumer_key.nil? || @consumer_secret.nil?
          raise Warden::OAuth::ConfigError.new("You need to specify the consumer key and the consumer secret")
        end
      end

    end

  end
end
