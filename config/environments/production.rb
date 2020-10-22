WADRCDataTools::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  #config.gem 'RedCloth', :lib => 'redcloth'
  
  # If you would like to add custom email credentials, you can do it with environment variables.
  # Set your login and password with DATAPANDA_EMAIL_LOGIN and DATAPANDA_EMAIL_PASSWORD
  # The medicine server will send to @medicine.wisc.edu email addresses without credentials,
  # but they are required to send mail to external email addresses.
  begin 
    email_login = ENV['DATAPANDA_EMAIL_LOGIN']
    email_password = ENV['DATAPANDA_EMAIL_PASSWORD']
    raise(LoadError, "Missing email environment variables.") unless email_login && email_password
  rescue LoadError => load_error
    puts load_error
    puts """If you would like to customize your email settings, set your login and password with:
    export DATAPANDA_EMAIL_LOGIN='yourlogin@medicine.wisc.edu'; export DATAPANDA_EMAIL_PASSWORD='yourpassword')"""
  end

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address        => 'mailgate.medicine.wisc.edu',
    :port           => 25,
    :authentication => :username,
    :user_name      => email_login,
    :password       => email_password,
    :tls            => false,
    :enable_starttls_auto => true
  }
config.action_mailer.default_url_options = {:host => 'adrcdev2.dom.wisc.edu'}  
  ####config.action_mailer.perform_deliveries = true
  ####config.action_mailer.raise_delivery_errors = true
  
 ##### seems to make everyone go to https:// -- but not in ror-- 
 ### config.middleware.use Rack::SslEnforcer
 #  or ?
# ? causing error ?  config.middleware.insert_before ActionDispatch::Static, "Rack::SSL"
 #### config.force_ssl = true
  
  #configuration syntax change
 # config.middleware.use ExceptionNotifier,
 #   :email_prefix => "[Panda Exception] ",
 #   :sender_address => %{"Exception Notifier" <noreply_johnson_lab@medicine.wisc.edu>},
 #   :exception_recipients => %w{noreply_johnson_lab@medicine.wisc.edu}   
    
 config.middleware.use ExceptionNotifier,
   :email_prefix => "[Panda Exception] ",
   :sender_address => %{"Exception Notifier" <noreply_johnson_lab@medicine.wisc.edu>},
   :exception_recipients => %w{noreply_johnson_lab@medicine.wisc.edu}
 #??? NEW SYNTAX???
# Rails.application.config.middleware.use ExceptionNotification::Rack,
#   :email => {
#     :deliver_with => :deliver, # Rails >= 4.2.1 do not need this option since it defaults to :deliver_now
#     :email_prefix => "[Panda Exception] ",
#     :sender_address => %{"Exception Notifier" <noreply_johnson_lab@medicine.wisc.edu>},
#     :exception_recipients => %w{noreply_johnson_lab@medicine.wisc.edu}
#   }


  config.radiology_pass = begin IO.read("/home/panda_user/.radiology").gsub(/\n/,'') rescue "" end
  config.adrc_neuropathology_token = begin IO.read("/home/panda_user/.neuropathology").gsub(/\n/,'') rescue "" end
  config.wrap_neuropathology_token = begin IO.read("/home/panda_user/.wrap_neuropathology").gsub(/\n/,'') rescue "" end
    
end
