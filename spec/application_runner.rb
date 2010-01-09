$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'warden_oauth'
require File.dirname(__FILE__) + "/application_scenario"

Warden::OAuth.access_token_user_finder(:example) do |access_token|
  nil
end

Rack::Handler::Mongrel.run $app, :Port => '4567'
