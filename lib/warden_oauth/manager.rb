module Warden
  module OAuth

    module Manager

      def self.included(base)
        base.extend(ClassMethods)
      end

      def oauth(service)
        #@config[:oauth_services] ||= {}
        config = Warden::OAuth::Config.new
        yield config
        config.check_requirements
        config.provider_name = service
        Warden::OAuth::Strategy.build(service, config)
        #@config[:oauth_services][service] = config
      end

      module ClassMethods

        def access_token_user_finder(&block)
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.acess_token_user_finder") unless block_given?
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.access_token_user_finder, this must receive one parameter") if block.arity != 1
          @find_user_by_access_token = block
        end

        def find_user_by_access_token(access_token)
          raise Warden::OAuth::AccessTokenFinderMissing.new("You need to specify a block for Warden::Manager.acess_token_user_finder") if @find_user_by_access_token.nil?
          @find_user_by_access_token.call(access_token)
        end

      end
    
    end

  end
end

Warden::Manager.send(:include, Warden::OAuth::Manager)
