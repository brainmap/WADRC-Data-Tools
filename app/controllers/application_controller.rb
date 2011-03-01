class ApplicationController < ActionController::Base
  protect_from_forgery
  
  layout "app"

  include AuthenticatedSystem

  before_filter :login_required, :only => [:edit, :update, :new, :create ]
  #before_filter { |c| User.current_user = c.current_user }
  
end
