class HomeController < ApplicationController
     def index
          allowed_ip = "182.187.138.87"
          client_ip = request.remote_ip
          if client_ip != allowed_ip
               file_path = Rails.root.join('app', 'views', 'devise', 'invalid_ip.html.erb')
               html_content = File.read(file_path)
               render html: html_content.html_safe
          else
               if current_user.admin?
                    @session = User.where(role: "user").order(created_at: :desc)
               else
                    @session = current_user.attendances.order(created_at: :desc)
                    @user = User.find(current_user.id)
               end
          end
     end
end
