# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true

# If you would like to add custom email credentials, you can do it with environment variables.
# Set your login and password with DATAPANDA_EMAIL_LOGIN and DATAPANDA_EMAIL_PASSWORD
# The medicine server will send to @medicine.wisc.edu email addresses without credentials,
# but they are required to send mail to external email addresses.
begin 
  email_login = ENV['DATAPANDA_EMAIL_LOGIN']
  email_password = ENV['DATAPANDA_EMAIL_PASSWORD']
  raise(LoadError, "Missing email environment variables.") unless email_login && email_password
rescue LoadError => load_error
  puts "Warning: " + load_error.to_s
  puts """If you would like to send mail to external addresses (i.e. those not ending with @medicine.wisc.edu), 
set your login and password with: 
export DATAPANDA_EMAIL_LOGIN='noreply_johnson_lab@medicine.wisc.edu'; export DATAPANDA_EMAIL_PASSWORD='goodpassword')
----"""
end

config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :address        => 'pop.medicine.wisc.edu',
  :port           => 25,
  :authentication => :login,
  :user_name      => email_login,
  :password       => email_password,
  :tls            => true
}

# Tools for extracting imaging metadata
load '~/code/metamri/lib/metamri.rb'
# config.gem 'metamri'

