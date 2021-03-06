ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

require 'mocha'
require 'test/spec'
require 'test/spec/rails'
require 'test/spec/rails/macros'
require 'test/spec/share'

# require 'test/spec/add_allow_switch'
# Net::HTTP.add_allow_switch :start

FIXTURE_ROOT = (Rails.root + 'test/fixtures').to_s

class Test::Unit::TestCase
  def fixture(name)
    File.join(FIXTURE_ROOT, name)
  end
end

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all
  
  $:.unshift(File.expand_path('../', __FILE__))
  
  require 'ext/authentication'
  include TestHelpers::Authentication
  
  require 'ext/time'
  include TestHelpers::Time
  
  require 'ext/file_fixtures'
  include TestHelpers::FileFixtures
end

ActionMailer::Base.default_url_options[:host] = 'test.host'

Attachment.attachment_san_options[:base_path] = TMP = File.expand_path('../tmp', __FILE__)
def TMP.reset!
  FileUtils.rm_rf self
  FileUtils.mkdir_p self
end