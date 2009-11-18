# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
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