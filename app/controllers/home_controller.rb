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
end
