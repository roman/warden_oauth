module Warden
  module OAuth

    def self.access_token_user_finder(key, &block)
      Strategy.access_token_user_finders[key] = block
    end

    def self.clear_access_token_user_finders
      Strategy.access_token_user_finders.clear
    end

  end
end
