require "rubygems"
$:.unshift << File.dirname(__FILE__) + "/../../lib"
require "warden"
require "warden_oauth"


# You need to specify the following URL in the browser to run the twitter authentication
# http://localhost:4567/?warden_oauth_provider=twitter


class ClientApp

  def self.call(env)
    env['warden'].authenticate!
    [200, {"Content-Type" => 'text/plain'}, "Welcome"]
  end

end

class ErrorApp
  
  def self.call(env)
    if env['warden.options'][:oauth].nil?
      [401, {'Content-Type' => 'text/plain'}, "You are not authenticated"]
    else
      access_token = env['warden.options'][:oauth][:access_token]
      [401, {'Content-Type' => 'text/plain'}, "No user with the given access token"]
    end
  end

end

class User
  attr_accessor :token
  attr_accessor :secret
  def initialize(token, secret)
    @token = token
    @secret = secret
  end
end

Warden::OAuth.access_token_user_finder(:twitter) do |access_token|
  # NOTE: Normally here you use AR/DM to fetch up the user given an access_token and an access_secret
  User.new(access_token.token, access_token.secret)
end

app = Rack::Builder.new do
  use Rack::Session::Cookie
  use Warden::Manager do |config|
    config.oauth(:twitter) do |twitter|
      # If you want this example to work, you need to specify both consumer_key and consumer_secret
      twitter.consumer_key ""
      twitter.consumer_secret ""
      twitter.options :site => 'http://twitter.com'
    end
    config.default_strategies :twitter_oauth
    config.failure_app = ErrorApp
  end
  run ClientApp
end

Rack::Handler::Mongrel.run app, :Port => '4567'
