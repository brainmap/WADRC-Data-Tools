# encoding: utf-8
class UsersController < ApplicationController

  #skip_before_filter :username_required
    before_action :authenticate_user!
    before_action :set_user, only: [:show, :edit, :update, :destroy]  
  	respond_to :html    

  def participant_missing
      sql ="select p.id, p.dob,p.gender from participants p where dob is null or dob ='' or gender is null or gender = '' and p.id in ( select participant_id from vgroups)"
     connection = ActiveRecord::Base.connection();
     @participants = connection.execute(sql)

     render :template => "users/participant_missing"
  end

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
      connection = ActiveRecord::Base.connection();
      users = User.where("username in (?)",params[:user][:username])
      if !users[0].nil?
          flash[:notice] = params[:user][:username]+' User already exists!!!!!.'
       else
        var = "insert into users(username,email,last_name,first_name,role,description) values('"+params[:user][:username]+"','"+params[:user][:email]+"','"+params[:user][:last_name].gsub("'","''")+"','"+params[:user][:first_name].gsub("'","''")+"','"+params[:user][:role]+"','"+params[:user][:username]+"')"
        results = connection.execute(var)
        user = User.where(:username => params[:user][:username]).first

        if !user.nil?

          flash[:notice] = 'User was successfully updated.'
          api_key = ApiKey.new(:user => user)
          api_key.save
        else
          flash[:notice] = 'Something went wrong.'
        end

       end
        respond_to do |format|
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
     
     var = "update users set email='"+params[:user][:email]+"',last_name='"+params[:user][:last_name].gsub("'","''")+"',first_name='"+params[:user][:first_name].gsub("'","''")+"' where id = "+params[:user][:id]+" "
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
  
  def user_protocol_role_summary
    sql = "select protocols.name,protocols.path, users.last_name, users.first_name,users.username
    from protocols, protocol_roles, users
    where protocols.id = protocol_roles.protocol_id
    and protocol_roles.user_id =  users.id
    order by protocols.name, users.last_name, users.first_name,users.username"
    connection = ActiveRecord::Base.connection();
     @results = connection.execute(sql)
     t = Time.now 
     @export_file_title ="Protocol/User Panda permission summary "+t.strftime("%m/%d/%Y %I:%M%p")
     @column_headers = ["Protocol","-","Last Name","First Name","Username"]
     @column_number =   @column_headers.size
     respond_to do |format|
       format.xls # ids_search.xls.erb
     end
  end   
  private
    def set_user 
       @user = User.find(params[:id]) 
    end
   def user_params
          params.require(:user).permit(:view_low_scan_procedure_array,:edit_low_scan_procedure_array,:description,:role,:last_sign_in_ip,:current_sign_in_ip,:edit_low_protocol_array,:view_low_protocol_array,:admin_low_scan_procedure_array,:admin_high_scan_procedure_array,:edit_high_protocol_array,:admin_low_protocol_array,:admin_high_protocol_array,:edit_medium_scan_procedure_array,:edit_medium_protocol_array,:hide_date_flag_array,:last_sign_in_at,:current_sign_in_at,:id,:username,:crypted_password,:salt,:remember_token,:remember_token_expires_at,:first_name,:last_name,:sign_in_count,:remember_created_at,:reset_password_sent_at,:reset_password_token,:encrypted_password,:email)
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
       if @user.update(params[:user], :without_protection => true)
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
