module Warden
  module OAuth

    #
    # Handles the creation an registration of OAuth strategies based on configuration parameters
    # via the Warden::Manager.oauth method
    #
    module StrategyBuilder
      extend self


      #
      # Defines the user finder from the access_token for the strategy, receives a block
      # that will be invoked each time you want to find an user via an access_token in your
      # system.
      #
      # @param blk Block that recieves the access_token as a parameter and will return a user or nil
      # 
      def access_token_user_finder(&blk)
        define_method(:_find_user_by_access_token, &blk)
      end

      #
      # Manages the creation and registration of the OAuth strategy specified
      # on the keyword
      #
      # @param [Symbol] name of the oauth service
      # @param [Walruz::Config] configuration specified on the declaration of the oauth service
      #
      def build(keyword, config)
        strategy_class = self.create_oauth_strategy_class(keyword)
        self.register_oauth_strategy_class(keyword, strategy_class)
        self.set_oauth_service_info(strategy_class, config)
        # adding the access_token_user_finder to the strategy
        if self.access_token_user_finders.include?(keyword)
          strategy_class.access_token_user_finder(&self.access_token_user_finders[keyword])
        end
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
      def create_oauth_strategy_class(keyword)
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
      def register_oauth_strategy_class(keyword, strategy_class)
        keyword_name = "%s_oauth" % keyword.to_s
        if Warden::Strategies[keyword_name.to_sym].nil?
          Warden::Strategies.add(keyword_name.to_sym, strategy_class) 
        end
      end

      #
      # Defines a CONFIG constant in the generated class that will hold the configuration information 
      # (consumer_key, consumer_secret and options) of the oauth service.
      #
      # @param [Class] strategy class that will hold the configuration info
      # @param [Warden::OAuth::Config] configuration info of the oauth service
      #
      def set_oauth_service_info(strategy_class, config)
        strategy_class.const_set("CONFIG", config) unless strategy_class.const_defined?("CONFIG")
      end

      protected :create_oauth_strategy_class,
                :register_oauth_strategy_class,
                :set_oauth_service_info

    end

  end
end
