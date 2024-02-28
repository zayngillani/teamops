class Admin::UsersController < ApplicationController
     def new
       @user = User.new
     end
   
     def create
       @user = User.new(user_params)
       @user.role = "user"
       if @user.save
         flash[:success] = "User created successfully"
         redirect_to root_path
       else
         render 'new'
       end
     end

     
   
     private
   
     def user_params
       params.require(:user).permit(:email, :password, :password_confirmation, :name, :slack_member_id)
     end
   end
   