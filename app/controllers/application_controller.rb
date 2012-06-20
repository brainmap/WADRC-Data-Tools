class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

#   include AuthenticatedSystem
   # need to skip if json and search and path_contains -- set a userid
   before_filter :authenticate_user! 

 
# respond_to do |format|
#   format.html  before_filter :authenticate_user!
#    format.xml  {      }
# end
 
# rescue_from CanCan::AccessDenied do |exception|
#   flash[:error] = exception.message
#   redirect_to root_url
# end 
  # deny_access unless signed_in? or format is "xml" 
  # list_visits from metamri doesn't have validation 
  # how can limit what the xml format can do? 

  # adding unless right after login_required
 # before_filter :username_required unless super params[:format] == 'xml' #, :only => [:edit, :update, :new, :create ]
####   before_filter :username_required #, :only => [:edit, :update, :new, :create ]  
  #before_filter { |c| User.current_user = c.current_user }
  
  # without super getting error frm params
  # super has to be callled from in a procedure -- 


end
