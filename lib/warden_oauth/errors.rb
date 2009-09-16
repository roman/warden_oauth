module Warden
  module OAuth

    class ConfigError < ArgumentError; end
    class ServiceAlreadyRegistered < StandardError; end
    class AccessTokenFinderMissing < StandardError; end

  end
end
