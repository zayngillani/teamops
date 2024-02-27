class HomeController < ApplicationController
     def index
          if current_user.admin?
               @session = User.where(role: "user")
          else
               @session = current_user.attendances
               @user = User.find(current_user.id)
          end
     end
end
