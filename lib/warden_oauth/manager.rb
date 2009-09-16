module Warden
  module OAuth

    #
    # Holds all the extensions made to Warden::Manager in order to create OAuth
    # consumers.
    #
    module Manager

      def self.included(base) #:nodoc:
        base.extend(ClassMethods)
      end

      #
      # Helps to setup a new OAuth client authentication, to get started you need to define
      # a service name, and then on the block assign the different values required in order
      # to boot the OAuth process.
      # @param [Symbol] service An identifier of the OAuth service
      # 
      # @example
      #
      #   Warden::Manager.oauth(:twitter) do
      #     consumer_key "<YOUR CONSUMER KEY>"
      #     consumer_secret "<YOUR CONSUMER SECRET>"
      #     options :site => 'http://twitter.com'
      #   end
      #
      def oauth(service, &block)
        config = Warden::OAuth::Config.new
        if block_given?
          if block.arity == 1 
            yield config 
          else
            config.instance_eval(&block)
          end
        end
        config.check_requirements
        config.provider_name = service
        Warden::OAuth::Strategy.build(service, config)
      end

      module ClassMethods

        #
        # Assigns a block that handles how to find a User given an access_token.
        # @param [Symbol] oauth_service The identifier specified on Warden::Manager.oauth
        # 
        # @example
        #   Warden::Manager.access_token_user_finder(:twitter) do |access_token|
        #     # Find user with access_token
        #   end
        #
        def access_token_user_finder(oauth_service, &block)
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.acess_token_user_finder") unless block_given?
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.access_token_user_finder, this must receive one parameter") if block.arity != 1
          @find_user_by_access_token ||= {}
          @find_user_by_access_token[oauth_service] = block
        end

        def find_user_by_access_token(oauth_service, access_token) #:nodoc:
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.acess_token_user_finder") if @find_user_by_access_token.nil?
          @find_user_by_access_token[oauth_service].call(access_token)
        end

      end
    
    end

  end
end

Warden::Manager.send(:include, Warden::OAuth::Manager)
