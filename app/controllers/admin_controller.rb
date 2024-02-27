class AdminController < ApplicationController
     before_action :authenticate_user!
     before_action :authorize_admin!
   
     private

     def authenticate_user!
       unless user_signed_in? || devise_controller?
         redirect_to new_user_session_path, alert: 'You must be logged in to access this page.'
       end
     end
   
     def authorize_admin!
       redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
     end
end
