# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout "app"

  include AuthenticatedSystem

  before_filter :login_required, :only => [:edit, :update, :new, :create ]
  #before_filter { |c| User.current_user = c.current_user }
  

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '63b28ff713c23b8986b1109623142bdc'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  # Note: current_user is defined by the AuthenticatedSystem in lib.

  
end
