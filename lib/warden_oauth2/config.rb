module Warden
  module OAuth2
  
    #
    # Holds all the information of the OAuth service.
    #
    class Config
      attr_accessor :provider_name
      
      def consumer_key(key = nil)
        unless key.nil?
          @consumer_key = key
        end
        @consumer_key
      end
      alias_method :consumer_key=, :consumer_key

      def consumer_secret(secret = nil)
        unless secret.nil?
          @consumer_secret = secret
        end
        @consumer_secret
      end
      alias_method :consumer_secret=, :consumer_secret
      
      def client_id(client_id = nil)
        unless client_id.nil?
          @client_id = client_id
        end
        @client_id
      end
      alias_method :client_id=, :client_id

      def options(options = nil) 
        unless options.nil?
          @options = options
        end
        @options
      end
      alias_method :options=, :options

      def check_requirements
        if @consumer_key.nil? || @consumer_secret.nil? || @client_id.nil?
          raise Warden::OAuth2::ConfigError.new("You need to specify the consumer key, consumer secret, and client id")
        end
      end

    end

  end
end
