Rails.application.routes.draw do
  devise_for :users
  root  "home#index"
  get '/invalid_ip', to: 'devise#invalid_ip'
  get 'change_password', to: 'home#change_password'
  patch 'update_password', to: 'home#update_password'
  
  
  namespace :admin do
    resources :users, only: [:new, :create, :index, :edit, :update, :destroy]
    get '/generate_pdf', :to => "users#generate_pdf", as: 'generate_pdf'
    get '/user_profile', :to => "users#user_profile", as: 'user_profile'
    put '/disable_user', :to => "users#disable_user", as: 'disable_user'
    get '/report', :to => "users#report", as: 'report'
    get '/user_detail', :to => "users#user_detail", as: 'user_detail'
    get '/user_leave', :to => "users#user_leave", as: 'user_leave'
    get '/leave_report', :to => "users#leave_report", as: 'leave_report'
    get '/monthly_report', :to => "users#monthly_report", as: 'monthly_report'
    get '/monthly_users_list', :to => "users#monthly_users_list", as: 'monthly_users_list'

  end
  
  resources :attendance, only: [:index]
  post '/create_session', :to => "attendance#create_session", as: 'create_session'
  post '/end_session', :to => "attendance#end_session", as: 'end_session'
  post '/break_session', :to => "attendance#break_session", as: 'break_session'
  post '/create_user', :to => "attendance#create_user", as: 'create_user'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
