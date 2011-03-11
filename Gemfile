source 'http://rubygems.org'

gem 'rails', '~>3.0.4'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'
if ENV['RAILS_ENV'] == "production"
  gem 'metamri'
else
  gem 'metamri', :path => '~/code/metamri'
end

gem 'builder', '~>2.1.2'
gem 'sqlite3', '~>1.3.3'
gem 'RedCloth', '4.0'
gem 'paperclip', '~>2.3.8'
gem 'ruport', '~>1.6.3'
gem 'acts_as_reportable'
gem 'kaminari'
gem 'meta_where'
gem 'meta_search'
gem 'rmagick'

# Use unicorn as the web server
# gem 'unicorn'

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
  gem 'rspec', '~>2.4'
  gem 'rspec-rails', '~>2.4'
  gem 'cucumber'
  gem 'cucumber-rails'
  gem 'webrat'
  gem 'pickle'
  gem 'autotest-rails'
  gem 'factory_girl_rails', '~>1.0.1'
  gem 'chronic'
  gem 'launchy'
end
