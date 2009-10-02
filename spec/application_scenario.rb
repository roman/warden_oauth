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

$app = Rack::Builder.new do
  use Rack::Session::Cookie
  use Warden::Manager do |manager|
    manager.oauth(:example) do |example|
      example.consumer_key "aCOTnTeKniyifcwwF3Mo"
      example.consumer_secret  "dEu91qxWfO0Z4Be1tHGuZ63FzHoUm9mk4Z8rzKa8"
      example.options :site => 'http://localhost:3000'
    end
    manager.default_strategies :example_oauth
    manager.failure_app = ErrorApp
  end
  run ClientApp
end if $app.nil?

