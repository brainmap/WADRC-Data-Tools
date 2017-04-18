# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
WADRCDataTools::Application.initialize!

require 'ruport/acts_as_reportable'   
 ## not seem to do anything
ENV['PATH']="/usr/local/rvm/gems/ruby-2.2.3@global/bin:/usr/local/rvm/rubies/ruby-2.2.3/bin:/usr/local/rvm/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:~/bin:/bin:/sbin:/usr/local"
ENV['GEM_HOME']="/usr/local/rvm/gems/ruby-2.2.3@global"
ENV['GEM_PATH']="/usr/local/rvm/gems/ruby-2.2.3@global"
ENV['RUBY_VERSION']="ruby-2.2.3p173"
# Bundler depends on this to use the gem version of metamri
ENV['RAILS_ENV']="production" # development   
ENV['MY_RUBY_HOME']="/usr/local/rvm/rubies/ruby-2.2.3" 


