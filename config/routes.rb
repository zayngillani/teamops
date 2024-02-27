Rails.application.routes.draw do
  devise_for :users
  root  "home#index"
  post '/create_session', :to => "attendance#create_session", as: 'create_session'
  post '/end_session', :to => "attendance#end_session", as: 'end_session'
  post '/break_session', :to => "attendance#break_session", as: 'break_session'
  post '/create_user', :to => "attendance#create_user", as: 'create_user'
  get '/generate_pdf', :to => "attendance#generate_pdf", as: 'generate_pdf'


  namespace :admin do
    resources :users, only: [:new, :create]
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
