class ApplicationController < ActionController::Base
    #  before_action :authenticate_ip!
    protect_from_forgery with: :null_session, if: -> { request.format.json? }
    before_action :authenticate_user!
    #  http_basic_authenticate_with name: "#{ENV["BASIC_HTTP_NAME"]}", password: "#{ENV["BASIC_HTTP_PASSWORD"]}", if: ->{ENV['BASIC_HTTP_AUTH'] == "true"}
     before_action :set_cache_buster

    def after_sign_out_path_for(resource_or_scope)
      request.referrer || root_path
    end
    
    private
    
    def authenticate_user!
      unless user_signed_in? || devise_controller?
        redirect_to new_user_session_path
      end
    end
    
    
    def set_cache_buster
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
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
