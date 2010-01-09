require "rack"
require "warden"
require "oauth"

module Warden
  module OAuth

    base_path = File.dirname(__FILE__) + "/warden_oauth"
    
    require base_path + "/base"
    require base_path + "/errors"
    autoload :Utils,           base_path + '/utils'
    autoload :StrategyBuilder, base_path + '/strategy_builder'
    autoload :Strategy,        base_path + '/strategy'
    autoload :Config,          base_path + "/config"
    require base_path + "/config_extension"
    

  end
end
