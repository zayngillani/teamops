class ApplicationController < ActionController::Base
    #  before_action :authenticate_ip!
     before_action :authenticate_user!
   
     private
   
    def authenticate_user!
      unless user_signed_in? || devise_controller?
        redirect_to new_user_session_path
      end
    end
    
    # def authenticate_ip!
    #   allowed_ip = "182.187.138.87"
    #   client_ip = request.remote_ip
    #   if client_ip != allowed_ip
    #     file_path = Rails.root.join('app', 'views', 'devise', 'invalid_ip.html.erb')
    #     html_content = File.read(file_path)
    #     render html: html_content.html_safe
    #   end
    # end
end
