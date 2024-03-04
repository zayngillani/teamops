Rails.application.routes.draw do
  devise_for :users
  root  "home#index"
  get '/invalid_ip', to: 'devise#invalid_ip'
  get 'change_password', to: 'home#change_password'
  patch 'update_password', to: 'home#update_password'
  
  
  namespace :admin do
    resources :users, only: [:new, :create, :index]
    get '/generate_pdf', :to => "users#generate_pdf", as: 'generate_pdf'
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
