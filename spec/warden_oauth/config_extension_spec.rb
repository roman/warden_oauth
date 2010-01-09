require File.dirname(__FILE__) + "/../spec_helper"

describe Warden::Config do 

  before(:each) do
    failure_app = lambda { |env| "Failure" }
    config = nil
    Warden::Manager.new(nil, :failure_app => failure_app) do |_config|
      config = _config
    end
    @config = config
  end
  
  it "should respond to an `oauth` message" do
    @config.should respond_to(:oauth)
  end

  describe "#oauth" do

    describe "when initialize" do

      it "should require setting the consumer_key" do
        lambda do
          @config.oauth(:service) do |service|
            service.consumer_secret "ABC"
          end
        end.should raise_error(Warden::OAuth::ConfigError,  "You need to specify the consumer key and the consumer secret")
      end

      it "should require setting the consumer_secret" do
        lambda do 
          @config.oauth(:service) do |service|
            service.consumer_key "ABC"
          end
        end.should raise_error(Warden::OAuth::ConfigError, "You need to specify the consumer key and the consumer secret")
      end

      it "should create a new instance of strategy" do
        @config.oauth(:service) do |service|
          service.consumer_key "ABC"
          service.consumer_secret "123"
        end
        lambda do
          Warden::OAuth::Strategy::Service
        end.should_not raise_error(NameError)
      end

    end

  end

end
