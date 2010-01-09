module Warden
  module OAuth

    #
    # Holds all the extensions made to Warden::Config in order to create OAuth
    # consumers.
    #
    module ConfigExtension

      #
      # Helps to setup a new OAuth client authentication, to get started you need to define
      # a service name, and then on the block assign the different values required in order
      # to boot the OAuth process.
      # @param [Symbol] service An identifier of the OAuth service
      # 
      # @example
      #   use Warden::Manager do |config|
      #     config.oauth(:twitter) do
      #       consumer_key "<YOUR CONSUMER KEY>"
      #       consumer_secret "<YOUR CONSUMER SECRET>"
      #       options :site => 'http://twitter.com'
      #     end
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
    
    end

  end
end

Warden::Config.send(:include, Warden::OAuth::ConfigExtension)

