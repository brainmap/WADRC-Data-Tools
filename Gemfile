source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
# Use Puma as the app server
gem 'puma', '3.8.2'  #'~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '5.0.6' # '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '3.1.7' #'>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '4.2.1' #'~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails','4.2.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '5.0.1' # '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.6.3' #'~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# 3.2-4.0 gems   
gem 'yaml_db' ,'0.4.2' 
# in production
# if ENV['RAILS_ENV'] == "production"
####NEED   MAKE LOCAL CHANGE gem 'metamri'  ,'~>0.2.24'  ####:path => '~>0.2.11'  # need to update metamri gem with local changes  
#metamri (~> 0.2.24) was resolved to 0.2.24, which depends on  activeresource (~> 3.0) was resolved to 3.0.0, which depends on  activemodel (= 3.0.0)
# else
#gem 'metamri', :path => '~/code/metamri' 
# added to get activeresource for metamri  # https://github.com/rails/activeresource/issues/213
gem 'rails-observers', github: 'rails/rails-observers'
gem 'activeresource', github: 'rails/activeresource'
 
gem 'metamri', '0.2.25'  # new gem version
#gem 'metamri', :path => '/Users/caillingworth/code/metamri_5_0_1/metamri'
# end
gem 'builder', '3.2.3'#, '~>2.1.2'
gem 'RedCloth','4.3.2'  #, "4.2.7"     
gem "cocaine"  , "0.5.3"   # need older version to work wityh paperclip
gem 'paperclip' , '4.2' # was 5.0.1 , '~>2.3.8'
# maybe move ruport, acts_as_reportatable, simple_form further down? get the version of depnedencies loaded for other gems first?
gem 'ruport' ###########, '~>1.6.3' 
#### get error about missing mysql2 gem - but seems to be ok now  
gem 'acts_as_reportable','1.1.1'
gem 'kaminari','1.0.1'  
gem 'exception_notification', :require => 'exception_notifier'      # "~> 2.4.1" ??
   #### get error about missing mysql2 gem -- but seems to be ok now
gem "devise","4.2.0" #, '> 3.4' # "3.1.1" #   ">= 1.4.9"   
#### get error about missing mysql2 gem  -- but seems to be ok now 
gem 'devise-encryptable','0.2.0' #, '0.1.2'
gem "devise_ldap_authenticatable","0.8.5" #, "0.8.1" 
   #### get error about missing mysql2 gem   -- a crash and then down styream things not happen 
gem "cancancan" ,"1.16.0"
gem 'hpricot' , "0.8.6" 
#gem 'rvm-capistrano','1.5.6' 
gem 'open4','1.3.4' 
gem 'bzip2-ruby', :git => 'https://github.com/chewi/bzip2-ruby.git'  
gem 'escoffier' , :path => '/Users/caillingworth/code/escoffier' 
#gem 'capistrano' ,'2.15.9'
gem 'capistrano', '3.8.0'
 gem 'capistrano-rails', '1.2.3'
 #gem 'capistrano-rvm', '0.1.2'
 gem 'rvm1-capistrano3', :require => false
 gem 'capistrano-bundler', '1.2.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri  
  gem 'database_cleaner' ,'1.5.3'
  gem 'chronic','0.10.2'
  gem 'launchy','2.4.3'
  gem 'timecop','0.8.1'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'hirb','0.7.3' #, '~>0.4.5'
  gem 'json','2.0.3'
  gem 'rack-mini-profiler' ,'0.10.2'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console','3.4.0' # '>= 3.3.0'
  gem 'listen', '3.0.8' #'~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring' ,'2.0.1'
  gem 'spring-watcher-listen', '2.0.1' #'~> 2.0.0' 
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
