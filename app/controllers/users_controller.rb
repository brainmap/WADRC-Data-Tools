class UsersController < Clearance::UsersController
  # include Clearance::UsersController
  
    # Override and add in a check for invitation code
    def create
      @user = User.new params[:user]
      invite_code = params[:invite_code]
      @invite = Invite.find_redeemable(invite_code)

      if invite_code && @invite
        if @user.save
          @invite.redeemed!
          flash[:notice] = "Successfully signed up!. " <<
                           "Now all you have to do is sign in and Panda away!"
          redirect_to sign_in_path
        else
          render :action => "new"
        end
      else
        flash.now[:notice] = "Sorry, that code is not redeemable"
        render :action => "new"
      end
    end

end
