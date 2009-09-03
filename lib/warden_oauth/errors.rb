module Warden
  module OAuth

    class ConfigError < ArgumentError; end
    class ServiceAlreadyRegistered < Exception; end
    class AccessTokenFinderMissing < Exception; end

  end
end
