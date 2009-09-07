require File.dirname(__FILE__) + "/../spec_helper"
require "rack/test"

describe Warden::OAuth::Strategy do
  
  def fixture_response(name)
    filename = File.dirname(__FILE__) + "/../fixtures/%s.txt" % name
  end

  describe '.build' do
    before(:each) do
      @config = Warden::OAuth::Config.new
      @config.consumer_key "ABC"
      @config.consumer_secret "123"
      @config.options :site => 'http://service.com'
      Warden::OAuth::Strategy.send(:remove_const, "Service") if Warden::OAuth::Strategy.const_defined?("Service")
      Warden::Strategies.clear!
      Warden::OAuth::Strategy.build(:service, @config)
    end

    it "should create a new instance that extends from Warden::OAuth::Strategy" do
      Warden::OAuth::Strategy.const_defined?("Service").should be_true
      (Warden::OAuth::Strategy::Service < Warden::OAuth::Strategy).should be_true
    end

    it "should register the oauth service key on the Warden strategies with `_oauth` appended" do
      Warden::Strategies[:service_oauth].should_not be_nil
      Warden::OAuth::Strategy::Service.should_not be_nil
      Warden::Strategies[:service_oauth].should == Warden::OAuth::Strategy::Service
    end

    it "should assign the oauth_service config as a constant" do
      Warden::OAuth::Strategy::Service::CONFIG.should_not be_nil
      Warden::OAuth::Strategy::Service::CONFIG.should == @config 
    end

  end

  describe "when invoking the strategy" do
    
    before(:each) do
      @request  = Rack::MockRequest.new($app)
    end

    describe "without warden_oauth_service nor oauth_token parameter" do
      
      before(:each) do
        @response = @request.get("/")
      end

      it "should render the failure app response" do
        @response.body.should == "You are not authenticated"
      end

    end

    describe "with a warden_oauth_provider parameter" do

      before(:each) do
        FakeWeb.register_uri(:post, 'http://localhost:3000/oauth/request_token', 
                             :body => fixture_response("unauthorized_request_token"))
        @response = @request.get("/", :input => 'warden_oauth_provider=example')
      end

      it "should redirect to the authorize url" do
        @response.headers['Location'].should =~ %r"http://localhost:3000/oauth/authorize"
      end

    end

    describe "when receiving a valid oauth response" do
      include Rack::Test::Methods
      
      def app
        $app
      end

      before(:each) do
        Warden::Manager.access_token_user_finder(:example) do |access_token|
          Object.new if access_token.token == 'ABC' && access_token.secret == '123' 
        end
        FakeWeb.register_uri(:post, 'http://localhost:3000/oauth/request_token', 
                             :body => fixture_response("unauthorized_request_token"))
        get "/", 'warden_oauth_provider' => 'example'
      end

      describe "and the user is not found" do

        before(:each) do
          FakeWeb.register_uri(:post, 'http://localhost:3000/oauth/access_token', 
                               :body => 'oauth_token=ABD&oauth_token_secret=122')
          get "/", 'oauth_token' => "SylltB94pocC6hex8kr9",
                   'oauth_verifier' => "omPxEkKnnx9ygnu7dd6f"
        end
        
        it "should invoke the fail app" do
          last_response.body.should ==  "No user with the given access token"
        end

      end

      describe "and the user is found" do

        before(:each) do
          FakeWeb.register_uri(:post, 'http://localhost:3000/oauth/access_token', 
                               :body => 'oauth_token=ABC&oauth_token_secret=123')
          get "/", 'oauth_token' => "SylltB94pocC6hex8kr9",
                   'oauth_verifier' => "omPxEkKnnx9ygnu7dd6f"
        end
        
        it "should go to the desired app" do
          last_response.body.should == "Welcome" 
        end

      end

    end

  end

end
