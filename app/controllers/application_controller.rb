class ApplicationController < ActionController::Base
     before_action :authenticate_user!
   
     private
   
    def authenticate_user!
     unless user_signed_in? || devise_controller?
       redirect_to new_user_session_path, alert: 'You must be logged in to access this page.'
     end
   end
end
