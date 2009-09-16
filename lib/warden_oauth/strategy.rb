module Warden
  module OAuth

    class Strategy < Warden::Strategies::Base

      ############################################
      ### section: Setup and Subclass Creation ###
      ############################################

      #
      # Manages the creation and registration of the OAuth strategy specified
      # on the keyword
      #
      # @param [Symbol] name of the oauth service
      # @param [Walruz::Config] configuration specified on the declaration of the oauth service
      #
      def self.build(keyword, config)
        strategy_class = self.create_oauth_strategy_class(keyword)
        self.register_oauth_strategy_class(keyword, strategy_class)
        self.set_oauth_service_info(strategy_class, config)
      end

      #
      # Creates the OAuth Strategy class from the keyword specified on the declaration of the 
      # oauth service. This class will be namespaced inside Warden::OAuth::Strategy
      #
      # @param [Symbol] name of the OAuth service 
      # @return [Class] The class representing the Warden strategy
      #
      # @example
      # 
      #   self.create_oauth_strategy_class(:twitter) #=> Warden::OAuth::Strategy::Twitter
      #   # will create a class Warden::OAuth::Strategy::Twitter that extends from 
      #   # Warden::OAuth::Strategy
      #
      def self.create_oauth_strategy_class(keyword)
        class_name = Warden::OAuth::Utils.camelize(keyword.to_s) 
        if self.const_defined?(class_name)
          self.const_get(class_name) 
        else
          self.const_set(class_name, Class.new(self))
        end
      end

      #
      # Registers the generated OAuth Strategy in the Warden::Strategies collection, the label
      # of the strategy will be the given oauth service name plus an '_oauth' postfix
      #
      # @param [Symbol] name of the OAuth service
      #
      # @example
      #   manager.oauth(:twitter) { |twitter| ... } # will register a strategy :twitter_oauth
      #
      def self.register_oauth_strategy_class(keyword, strategy_class)
        keyword_name = "%s_oauth" % keyword.to_s
        if Warden::Strategies[keyword_name.to_sym].nil?
          Warden::Strategies.add(keyword_name.to_sym, strategy_class) 
        end
      end

      #
      # Defines a CONFIG constant in the generated class that will hold the configuration information 
      # (consumer_token, consumer_secret and options) of the oauth service.
      #
      # @param [Class] strategy class that will hold the configuration info
      # @param [Warden::OAuth::Config] configuration info of the oauth service
      #
      def self.set_oauth_service_info(strategy_class, config)
        strategy_class.const_set("CONFIG", config) unless strategy_class.const_defined?("CONFIG")
      end

      class << self
        protected :create_oauth_strategy_class,
                  :register_oauth_strategy_class,
                  :set_oauth_service_info
      end

      ######################
      ### Strategy Logic ###
      ######################

      #
      # An OAuth strategy will be valid to execute if:
      # * A 'warden_oauth_provider' parameter is given, with the name of the OAuth service
      # * A 'oauth_token' is being receive on the request (response from an OAuth provider)
      #
      def valid?
        (params.include?('warden_oauth_provider') &&  params['warden_oauth_provider'] == config.provider_name.to_s) ||
          params.include?('oauth_token') 
      end


      #
      # Manages the OAuth authentication process, there can be 3 outcomes from this Strategy:
      # 1. The OAuth credentials are invalid and the FailureApp is called
      # 2. The OAuth credentials are valid, but there is no user associated to them. In this case
      #    the FailureApp is called, but the env['warden.options'][:oauth][:access_token] will be 
      #    available.
      # 3. The OAuth credentials are valid, and the user is authenticated successfuly
      #
      # @note
      # If you want to signup users with the twitter credentials, you can manage the creation of a new 
      # user in the FailureApp with the given access_token
      #
      def authenticate!
        if params.include?('warden_oauth_provider')
          store_request_token_on_session
          redirect!(request_token.authorize_url)

        elsif params.include?('oauth_token')
          load_request_token_from_session
          if missing_stored_token?
            fail!("There is no OAuth authentication in progress")
          elsif !stored_token_match_recieved_token?
            fail!("Received OAuth token didn't match stored OAuth token")
          else
            user = Warden::Manager.find_user_by_access_token(config.provider_name , access_token)
            if user.nil?
              fail!("User with access token not found")
              throw(:warden, :oauth => { :access_token => access_token })
            else
              success!(user)
            end
          end
        end

      end

      def fail!(msg) #:nodoc:
        self.errors.add(service_param_name.to_sym, msg)
        super
      end
      
      ###################
      ### OAuth Logic ###
      ###################

      def consumer
        @consumer ||= ::OAuth::Consumer.new(config.consumer_key, config.consumer_secret, config.options)
      end

      def request_token
        host_with_port = Warden::OAuth::Utils.host_with_port(request)
        @request_token ||= consumer.get_request_token(:oauth_callback => host_with_port)
      end

      def access_token
        @access_token ||= request_token.get_access_token(:oauth_verifier => params['oauth_verifier'])
      end

      def store_request_token_on_session
        session[:request_token]  = request_token.token
        session[:request_secret] = request_token.secret
      end

      def load_request_token_from_session
        token  = session.delete(:request_token)
        secret = session.delete(:request_secret)
        @request_token = ::OAuth::RequestToken.new(consumer, token, secret)
      end

      def missing_stored_token? 
        !request_token
      end

      def stored_token_match_recieved_token?
        request_token.token == params['oauth_token']
      end

      def service_param_name
        '%s_oauth' % config.provider_name
      end

      def config
        self.class::CONFIG
      end

    end

  end
end
