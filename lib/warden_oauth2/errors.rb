module Warden
  module OAuth2

    class ConfigError < ArgumentError; end
    class ServiceAlreadyRegistered < StandardError; end
    class AccessTokenFinderMissing < StandardError; end

  end
end
