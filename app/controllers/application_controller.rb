class ApplicationController < ActionController::Base
    #  before_action :authenticate_ip!
     protect_from_forgery with: :null_session
     before_action :authenticate_user!
    #  http_basic_authenticate_with name: "#{ENV["BASIC_HTTP_NAME"]}", password: "#{ENV["BASIC_HTTP_PASSWORD"]}", if: ->{ENV['BASIC_HTTP_AUTH'] == "true"}
   
     private
   
    def authenticate_user!
      unless user_signed_in? || devise_controller?
        redirect_to new_user_session_path
      end
    end
    
    # def authenticate_ip!
    #   allowed_ip = ENV["IP_ADDRESS"]
    #   client_ip = request.remote_ip
    #   unless allowed_ip.split(',').include?(client_ip)
    #     file_path = Rails.root.join('app', 'views', 'devise', 'invalid_ip.html.erb')
    #     html_content = File.read(file_path)
    #     render html: html_content.html_safe
    #   end
    # end
end
