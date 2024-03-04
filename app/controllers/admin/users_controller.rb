class Admin::UsersController < ApplicationController

     def index
      @session = User.where(role: "user").order(created_at: :desc)
     end
     def new
       @user = User.new
     end
   
     def create
       @user = User.new(user_params)
       @user.ip_address = request.remote_ip
       @user.role = "user"
       if @user.save
         flash[:success] = "User created successfully"
         redirect_to root_path
       else
         render 'new'
       end
     end

     def generate_pdf
      @user = User.find(params[:id])
      @user_sessions = Attendance.where(user_id: params[:id]).order(created_at: :asc)
      respond_to do |format|
           format.html
           format.pdf { render pdf: "#{@user.name}", layout: false } # Specify view and disable layout
      end
 end

     
   
     private
   
     def user_params
       params.require(:user).permit(:email, :password, :password_confirmation, :name, :slack_member_id)
     end
   end
   