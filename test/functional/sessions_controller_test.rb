require File.expand_path('../../test_helper', __FILE__)

describe "On the", SessionsController, "a visitor" do
  it "should see a login form" do
    get :new
    status.should.be :success
    template.should.be 'sessions/new'
    assert_select 'form'
  end
  
  it "should keep the url to return to after authentication" do
    url = member_url(members(:alloy))
    get :new, {}, {}, { :after_authentication => { :redirect_to => url }}
    controller.after_authentication[:redirect_to].should == url
  end
  
  it "should be able to create a new session" do
    post :create, :member => valid_credentials
    assigns(:unauthenticated).should == members(:alloy)
    should.be.authenticated
    should.redirect_to root_url
  end
  
  it "should redirect the user back to the page he originally requested" do
    url = edit_member_url(members(:alloy))
    post :create, { :member => valid_credentials }, {}, { :after_authentication => { :redirect_to => url }}
    should.redirect_to url
  end
  
  it "should see an explanation if the password was wrong" do
    post :create, :member => valid_credentials.merge(:password => 'wrong')
    should.not.be.authenticated
    status.should.be :success
    assert_select 'div.errorExplanation'
  end
  
  it "should not default the wrong password in the form after a failed login" do
    post :create, :member => valid_credentials.merge(:password => 'wrong')
    assert_select 'input[id="member_password"]'
    assert_select 'input[id="member_password"][value]', false
  end
  
  it "should see an explanation when the email does not exist" do
    post :create, :member => valid_credentials.merge(:email => 'unknown@example.com')
    should.not.be.authenticated
    status.should.be :success
    assert_select 'div.errorExplanation'
  end
  
  it "should default the email in the form after a failed login" do
    post :create, :member => valid_credentials.merge(:email => 'unknown@example.com')
    assert_select 'input[id="member_email"][value="unknown@example.com"]'
  end
  
  it "should keep the url to return to if the password or email was wrong" do
    url = member_url(members(:alloy))
    post :create, { :member => valid_credentials.merge(:password => 'wrong') }, {}, { :after_authentication => { :redirect_to => url }}
    should.not.be.authenticated
    controller.after_authentication[:redirect_to].should == url
  end
  
  private
  
  def valid_credentials
    { :email => members(:alloy).email, :password => 'secret' }
  end
end

describe "On the", SessionsController, "a member" do
  before do
    login members(:alloy)
  end
  
  it "should be able to clear the logged in session" do
    get :clear
    should.not.be.authenticated
    should.redirect_to root_url
  end
  
  it "should make sure the member is marked as logged out" do
    memberships(:alloy_in_macruby).online!
    get :clear
    rooms(:macruby).should.be.empty
  end
end