class HomeController < ApplicationController
     def index
          if current_user.admin?
               @session = User.where(role: "user").order(created_at: :desc)
          else
               @session = current_user.attendances.order(created_at: :desc)
               @user = User.find(current_user.id)
          end
     end
end
