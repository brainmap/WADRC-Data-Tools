class ApplicationController < ActionController::Base
  include Clearance::Authentication
  protect_from_forgery

  include AuthenticatedSystem

  before_filter :authorize #, :only => [:edit, :update, :new, :create ]
  #before_filter { |c| User.current_user = c.current_user }
  
end
