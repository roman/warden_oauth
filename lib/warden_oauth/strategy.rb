module Warden
  module OAuth

    #
    # Holds all the main logic of the OAuth authentication, all the generated
    # OAuth classes will extend from this class
    #
    class Strategy < Warden::Strategies::Base
      extend StrategyBuilder

      ######################
      ### Strategy Logic ###
      ######################


      def self.access_token_user_finders
        (@_user_token_finders ||= {})
      end

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
          throw(:warden)
        elsif params.include?('oauth_token')
          load_request_token_from_session
          if missing_stored_token?
            fail!("There is no OAuth authentication in progress")
          elsif !stored_token_match_recieved_token?
            fail!("Received OAuth token didn't match stored OAuth token")
          else
            user = find_user_by_access_token(access_token)
            if user.nil?
              fail!("User with access token not found")
              throw_error_with_oauth_info
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

      protected

      def find_user_by_access_token(access_token)
        raise RuntimeError.new(<<-ERROR_MESSAGE) unless self.respond_to?(:_find_user_by_access_token)
        
You need to define a finder by access_token for this strategy.
Write on the warden initializer the following code:
Warden::OAuth.access_token_user_finder(:#{config.provider_name}) do |access_token|
  # Logic to get your user from an access_token
end

ERROR_MESSAGE
        self._find_user_by_access_token(access_token)
      end

      def throw_error_with_oauth_info
        throw(:warden, :oauth => { 
          self.config.provider_name => {
            :provider => config.provider_name,
            :access_token => access_token,
            :consumer_key => config.consumer_key,
            :consumer_secret => config.consumer_secret
          }
        })
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
