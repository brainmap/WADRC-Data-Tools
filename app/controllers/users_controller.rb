# encoding: utf-8
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
  
  def update_role

   if !params[:user].nil? 
    @user = User.find(params[:user][:id])
    var = "update users set role='"+params[:user][:role]+"' where id="+params[:user][:id]
    connection = ActiveRecord::Base.connection();
    results = connection.execute("update users set role='"+params[:user][:role]+"' where id="+params[:user][:id])
  
    respond_to do |format|
         flash[:notice] = 'User was successfully updated.'
         format.html { redirect_to('/users/update_role') }
         format.xml  { head :ok }
     end
   end

  end
  
  def control
      render :template => "users/control"
  end
  
  def questionformbase
      render :template => "users/questionform"
  end
  
  def cgbase
      render :template => "users/cgbase"
  end

  def add_user
    if !params[:user].nil? 
     var = "insert into users(username,email,last_name,first_name,role) values('"+params[:user][:username]+"','"+params[:user][:email]+"','"+params[:user][:last_name]+"','"+params[:user][:first_name]+"','"+params[:user][:role]+"')"
    connection = ActiveRecord::Base.connection();
     results = connection.execute(var)

     respond_to do |format|
          flash[:notice] = 'User was successfully updated.'
          format.html { redirect_to('/protocol_roles') }
          format.xml  { head :ok }
      end
    end
     # render :template => "/users/add_user"
  end  

  def edit_user
    if !params[:user].nil?   && params[:user][:last_name].blank?
      @user = User.find(params[:user][:id])
         render :template => "/users/edit_user"  
    elsif !params[:user].nil?  && !params[:user][:last_name].nil? 
     var = "update users set email='"+params[:user][:email]+"',last_name='"+params[:user][:last_name]+"',first_name='"+params[:user][:first_name]+"' where id = "+params[:user][:id]+" "
    connection = ActiveRecord::Base.connection();
     results = connection.execute(var)

     respond_to do |format|
          flash[:notice] = 'User was successfully updated.'
          format.html { redirect_to('/users/control') }
          format.xml  { head :ok }
      end
    end

     # render :template => "/users/add_user"
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
