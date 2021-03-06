require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'devise'
#### require 'iconv'
####require 'rack/ssl-enforcer'
### require 'rack/ssl'
 




# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)  
if defined?(Bundler) 
    Bundler.require(*Rails.groups(:assets => %w(development test production)))  
end 
module WADRCDataTools
  class Application < Rails::Application     
    # paperclip path
    #### no difference Paperclip.options[:command_path] = "/usr/local/bin/identify"
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/forms)

    #also, the extensions that used to be in metamri, and now stay in Panda "for real life"
    config.autoload_paths += Dir[File.join(Rails.root, "lib", "extensions.rb")].each {|l| require l }
    config.autoload_paths += Dir[File.join(Rails.root, "lib", "exceptions.rb")].each {|l| require l }
    
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Central Time (US & Canada)" #'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    #tagging the user_id onto our logs, so that we can segment our log data for workflow analysis
    config.log_tags = [
        ->(req){
            if user_id = WardenTaggedLogger.extract_user_id_from_request(req)
                "user: #{user_id.to_s}"
            else
                "?"
            end
        }
    ]

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
      
    # added for 3.2 to 4.0
    config.paths['config/routes.rb'] # add .rb
    #config.assets.precompile += %w( index.js )  
    config.assets.initialize_on_precompile = false
    config.assets.version = '1.0'
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
  end
end
