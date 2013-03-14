source 'http://rubygems.org'
gem 'rails', '~>3.0.4'

# gem 'sqlite3', '~>1.3.3'
gem 'mysql2', '~>0.2.0'
gem 'yaml_db'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# in production
#### if ENV['RAILS_ENV'] == "production"
  gem 'metamri','~>0.2.11'  ####:path => '~>0.2.11'
####else
####  gem 'metamri', :path => '~/code/metamri'
#### end

gem 'builder', '~>2.1.2'
gem 'RedCloth', '~>4.2.7'
# gem 'bluecloth', '~>2.1.0'
gem 'paperclip', '~>2.3.8'
gem 'ruport', '~>1.6.3'
gem 'acts_as_reportable'
gem 'kaminari'
gem 'meta_where'
gem 'meta_search'
 if ENV['RAILS_ENV'] == "production"
gem 'rmagick', :path => "/Users/panda_admin/.rvm/gems/ruby-1.8.7-p371/gems/rmagick-2.13.1"  # metamri had s.add_runtime_dependency('rmagick', "~> 2.13.1")
 else
   gem 'rmagick'
  end
gem 'simple_form'
gem 'exception_notification', "~> 2.4.1", :require => 'exception_notifier'

# Use unicorn as the web server
# gem 'unicorn'

gem 'jquery-rails'
gem "devise", ">= 1.4.9"
gem "devise_ldap_authenticatable"
gem "cancan"
gem "mechanize"
gem "hpricot"

gem 'rvm-capistrano'
gem 'mini_magick'
gem 'open4'
# gem 'POpen4', '~>0.1.4'

# Deploy with Capistrano
gem 'capistrano', '~>2.5.19'

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
  gem 'rspec', '~>2.4.0'
  gem 'rspec-rails', '~>2.4.0'
  # gem 'gherkin', '~>2.1.5'
  # gem 'cucumber', '~>0.7.3'
  # gem 'cucumber-rails', '~>0.4.1'
  # gem 'capybara'
  gem 'webrat'
  gem 'database_cleaner'
  gem 'pickle'
  gem 'autotest-rails'
  gem 'factory_girl_rails', '~>1.0.1'
  gem 'chronic'
  gem 'launchy'
  gem 'timecop'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'hirb', '~>0.4.5'
  gem 'rack-mini-profiler'
end
