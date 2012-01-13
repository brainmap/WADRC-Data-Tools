class UsersController < ApplicationController

  #skip_before_filter :username_required
    before_filter :authenticate_user!
     


  def index 
    @users = User.all
  end
  def show
    @user = User.find(params[:id])
  end
  
  def self.find_for_authentication(conditions)
    login = conditions.delete(:login)
    where(conditions).where(["login = :value OR email = :value", { :value => login }]).first
  end

  # render new.rhtml
  def new
  end
  
=begin
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      self.current_user = @user
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end

  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    
    respond_to do |format|
       if @user.update_attributes(params[:user])
         flash[:notice] = 'User was successfully updated.'
         format.html { redirect_to(@user) }
         format.xml  { head :ok }
       else
         format.html { render :action => "edit" }
         format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
       end
     end
  end
=end

end
