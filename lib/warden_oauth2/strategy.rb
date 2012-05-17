module Warden
  module OAuth2

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
        (params.include?('warden_oauth2_provider') &&  params['warden_oauth2_provider'] == config.provider_name.to_s) ||
          params.include?('code')
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
        puts "Inside OAUTH2 authenticate!****^^^^^^^^^^^^^^^^^^^"
        if params.include?('warden_oauth2_provider')
          #store_request_token_url_on_session
          redirect!(consumer.authorize_url(:redirect_uri => config.options[:redirect_uri],:client_id => config.client_id,:scope => config.options[:scope]))
          throw(:warden)
        elsif params.include?('code')
          #load_request_token_from_session
          user = find_user_by_access_token(access_token)
          if user.nil?
            puts "got bad user"
            fail!("User with access token not found")
            throw_error_with_oauth_info
          else
            puts "Got success"
            success!(user)
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
        puts 'options - ' + config.options.inspect
        @consumer ||= ::OAuth2::Client.new(config.client_id, config.consumer_secret, config.options)
      end

      # def request_token
      #         #@request_token_url ||= consumer.get_request_token(:redirect_uri => config.options[:redirect_uri],:scope => config.options[:scope])
      #         @request_token_url ||= consumer.authorize_url
      #       end
      # 
      def access_token
        puts 'access_token_url = ' + consumer.access_token_url.inspect
        @access_token ||= consumer.web_server.get_access_token(params['code'],:redirect_uri => config.options[:redirect_uri])
      end

      protected

      def find_user_by_access_token(access_token)
        raise RuntimeError.new(<<-ERROR_MESSAGE) unless self.respond_to?(:_find_user_by_access_token)
        
You need to define a finder by access_token for this strategy.
Write on the warden initializer the following code:
Warden::OAuth2.access_token_user_finder(:#{config.provider_name}) do |access_token|
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

      # def store_request_token_on_session
      #         puts 'request_token - ' + request_token.inspect
      #         session[:request_token]  = request_token.token
      #         session[:request_secret] = request_token.secret
      #       end
      # 
      #       def load_request_token_from_session
      #         token  = session.delete(:request_token)
      #         secret = session.delete(:request_secret)
      #         @request_token = ::OAuth2::RequestToken.new(consumer, token, secret)
      #       end
      
      # def missing_stored_token? 
      #         !request_token
      #       end
      # 
      #       def stored_token_match_recieved_token?
      #         request_token.token == params['oauth_token']
      #       end

      def service_param_name
        '%s_oauth2' % config.provider_name
      end

      def config
        self.class::CONFIG
      end

    end

  end
end
