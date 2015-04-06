source 'http://rubygems.org'
gem 'rails', '~>3.2'


gem 'sqlite3', '~>1.3.3'  # need in metamri
gem 'mysql2'  # ,'~>0.3.13'  # not limiting version 20130314, '~>0.2.0'---# went back to limit ACtiveRecord adapter and rails 3.1
gem 'yaml_db'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# in production
# if ENV['RAILS_ENV'] == "production"
gem 'metamri'  ,'~>0.2.21'  ####:path => '~>0.2.11'  # need to update metamri gem with local changes
# else
#gem 'metamri', :path => '~/code/metamri'
#gem 'metamri', :path => '/Users/caillingworth/code/metamri'
# end

gem 'builder' #, '~>2.1.2'
## trying without just to get going gem 'RedCloth', '~>4.2.7'
# gem 'bluecloth', '~>2.1.0'
gem "cocaine", "0.3.2"   # need older version to work wityh paperclip
gem 'paperclip', '~>2.3.8'
# maybe move ruport, acts_as_reportatable, simple_form further down? get the version of depnedencies loaded for other gems first?
gem 'ruport' ###########, '~>1.6.3'
gem 'acts_as_reportable'
gem 'kaminari'
####### gem 'meta_search' # needs actionpack 3.0.2 ruby
####### gem 'meta_where'   # needs arel (2.0.7)  but arel is 3.0.2
##### gem 'rmagick'
###### hash out gem simple_form  when doing bundle update rails 
### then unhash and run bundle update rails again  -- different versions of action pack
gem 'simple_form'
gem 'exception_notification', "~> 2.4.1", :require => 'exception_notifier'

# Use unicorn as the web server
# gem 'unicorn'

########## default in 3.1 ?  gem 'jquery-rails'
gem "devise", ">= 1.4.9"
gem 'devise-encryptable'
gem "devise_ldap_authenticatable"
gem "cancan"
# gem "mechanize" # used in radiology model for scaping  # trying to remove nokogiri because of problems with xml lib versions on adrcdev/rvm
## trying without just to get going gem 'hpricot'

gem 'rvm-capistrano'
# gem 'mini_magick' # needs newer ruby 1.9.2 to work with ruby dicom
gem 'open4'
# gem 'POpen4', '~>0.1.4'
#gem 'bzip2-ruby' 
## trying without just to get going gem 'escoffier'
# Deploy with Capistrano
gem 'capistrano' #, '~>2.15.5' #~>3.0.1' #~>2.15.5' #, '~>2.5.19'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do

# gem 'capistrano'

  ######### gem 'rspec' #, '~>2.4.0'
  ######### gem 'rspec-rails' # ,  '~>2.4.0'
  # gem 'gherkin', '~>2.1.5' # trying to remove nokogiri because of problems with xml lib versions on adrcdev/rvm
  # gem 'cucumber', '~>0.7.3' # trying to remove nokogiri because of problems with xml lib versions on adrcdev/rvm
  # gem 'cucumber-rails', '~>0.4.1'
  # gem 'capybara'
  # gem 'webrat'  # trying to remove nokogiri because of problems with xml lib versions on adrcdev/rvm
  gem 'database_cleaner'
  # gem 'pickle'  # trying to remove nokogiri because of problems with xml lib versions on adrcdev/rvm
  ########## gem 'autotest-rails'
  # gem 'factory_girl_rails', '~>1.0.1'
  gem 'chronic'
  gem 'launchy'
  gem 'timecop'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'hirb', '~>0.4.5'
  gem 'json'
  gem 'rack-mini-profiler'
end
