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

#config.action_mailer.delivery_method = :sendmail
begin 
  email_login = ENV['DATAPANDA_EMAIL_LOGIN']
  email_password = ENV['DATAPANDA_EMAIL_PASSWORD']
  raise(LoadError, "Missing email environment variables.") unless email_login && email_password
rescue LoadError => load_error
  puts load_error
  puts "(in bash, set your login and password with: export DATAPANDA_EMAIL_LOGIN='ekk@medicine.wisc.edu'; export DATAPANDA_EMAIL_PASSWORD='yourpassword')"
  puts "Sending Email will not be available until you export these variables and restart the server."
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