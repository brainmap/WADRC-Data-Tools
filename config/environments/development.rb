WADRCDataTools::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false
  #config.eager_load = true


  #config.force_ssl = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
 #########  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # config.gem 'RedCloth', :lib => 'redcloth'

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
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

#### config.middleware.use Rack::SslEnforcer, :only_hosts => '144.92.151.228'
#### config.force_ssl = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address        => 'smtp.medicine.wisc.edu',
    :port           => 587,
    :authentication => :username,
    :user_name      => email_login,
    :password       => email_password,
    :tls            => false,
    :enable_starttls_auto =>true
  }
  
  config.action_mailer.default_url_options = {:host => 'localhost:3000'}
  
  config.radiology_pass = begin IO.read("/Users/panda_user/.radiology").gsub(/\n/,'') rescue "" end
  config.adrc_neuropathology_token = begin IO.read("/Users/panda_user/.neuropathology").gsub(/\n/,'') rescue "" end
  config.wrap_neuropathology_token = begin IO.read("/Users/panda_user/.wrap_neuropathology").gsub(/\n/,'') rescue "" end
  config.redcap_adrc_token = begin IO.read("/Users/panda_user/.redcap_adrc").gsub(/\n/,'') rescue "" end
    
end

