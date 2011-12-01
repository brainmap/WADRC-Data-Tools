class ApplicationController < ActionController::Base
  protect_from_forgery

  include AuthenticatedSystem
  # deny_access unless signed_in? or format is "xml" 
  # list_visits from metamri doesn't have validation 
  # how can limit what the xml format can do? 

  # adding unless right after login_required
 # before_filter :login_required unless super params[:format] == 'xml' #, :only => [:edit, :update, :new, :create ]
   before_filter :login_required #, :only => [:edit, :update, :new, :create ]  
  #before_filter { |c| User.current_user = c.current_user }
  
  # without super getting error frm params
  # super has to be callled from in a procedure -- 
  # so can't just add unless after :login_required
  def login_required
      super unless params[:format] == 'xml'
  end
  
end
