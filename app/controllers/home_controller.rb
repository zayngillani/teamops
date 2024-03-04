class HomeController < ApplicationController
     def index
          # allowed_ip = ENV["IP_ADDRESS"]
          # client_ip = request.remote_ip
          # unless allowed_ip.split(',').include?(client_ip)
          #      file_path = Rails.root.join('app', 'views', 'devise', 'invalid_ip.html.erb')
          #      html_content = File.read(file_path)
          #      render html: html_content.html_safe
          # else
               if current_user.admin?
                    redirect_to admin_users_path
               else
                    redirect_to attendance_index_path
               end
          # end
     end

     def change_password
     end

     def update_password
          if params[:user][:password] == params[:user][:password_confirmation]
               current_user.update(user_params)
               bypass_sign_in(current_user)
               redirect_to root_path
               flash[:success] = "Password Successfully Changed"
          else
               redirect_to change_password_path
               flash[:error] = "Passwords Don't Match"
          end
     end

     private
     
     def user_params
          params.require(:user).permit(:password, :password_confirmation)
     end
end
