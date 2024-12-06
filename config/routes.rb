Rails.application.routes.draw do
  get 'public_links/show'
  resources :public_links, only: [:show], param: :token
  devise_for :users
  root  "home#index"
  get '/invalid_ip', to: 'devise#invalid_ip'
  get 'change_password', to: 'home#change_password'
  patch 'update_password', to: 'home#update_password'
  get 'view_resume', to: 'home#view_resume'
  post 'slack/actions', to: 'slack#actions', defaults: { format: :json }
  
  namespace :admin do
    resources :users, only: [:new, :create, :index, :edit, :update, :destroy] do
      member do
        patch 'update_ip_restriction'
      end
      collection do
        patch 'update_all_ip_restrictions'
      end
    end
    resources :ip_managements do
      member do
        patch :update_status
      end
    end
    resources :oncall_support, only: [:index, :show, :create, :update]
    resources :leaves, only: [:index, :show, :create, :update] do
      collection do
        get 'get_emergency_leaves'
        post 'create_emergency_leaves'
        get 'new_emergency_leaves'
      end
    end
    resources :daily_reports, only: [:index, :show] do
      collection do
        get :search
        get 'report', to:  'daily_reports#report'
      end
    end

    resources :job_applications, only: [:index]
    resources :interviews, only: [:new, :create] do
      member do
        get :generate_public_link
      end
    end

    resources :job_applications, only: [:index, :show] do 
      member do 
        get :reject_applicant
        get :download_resume
      end
    end

    resources :job_posts
    resources :contact_details, only: [:index, :show]
    #Users
    get '/generate_pdf', :to => "users#generate_pdf", as: 'generate_pdf'
    get '/user_profile', :to => "users#user_profile", as: 'user_profile'
    put '/disable_user', :to => "users#disable_user", as: 'disable_user'
    get '/report', :to => "users#report", as: 'report'
    get '/user_detail', :to => "users#user_detail", as: 'user_detail'
    get '/user_leave', :to => "users#user_leave", as: 'user_leave'
    get '/leave_report', :to => "users#leave_report", as: 'leave_report'
    get '/monthly_report', :to => "users#monthly_report", as: 'monthly_report'
    get '/monthly_users_list', :to => "users#monthly_users_list", as: 'monthly_users_list'
    get 'monthly_excel/:month/:year', to: 'users#monthly_excel', as: :users_monthly_excel, defaults: { format: :xlsx }
    get '/archived_user', :to => "users#archived_user", as: 'archived_user'

    #Daily Reports
  end
  
  resources :attendance, only: [:index]
  post '/create_session', :to => "attendance#create_session", as: 'create_session'
  post '/end_session', :to => "attendance#end_session", as: 'end_session'
  post '/break_in', :to => "attendance#break_in", as: 'break_in'
  post '/break_out', :to => "attendance#break_out", as: 'break_out'
  post '/create_user', :to => "attendance#create_user", as: 'create_user'
  put '/update_report', :to => "attendance#update_report", as: 'update_report'
  get '/show_report', :to => "attendance#show_report", as: 'show_report'
  get '/user_report', :to => "attendance#user_report", as: 'user_report'
  post '/create_oncall', :to => "oncall_support#create_oncall", as: 'create_oncall'
  get '/show_oncalls', :to => "oncall_support#show_oncalls", as: 'show_oncalls'
  get '/users_attendance', :to => "attendance#users_attendance", as: 'users_attendance'

  resources :dashboard, only: [:index], controller: 'attendance'

  resources :leaves, only: [:new, :create, :index, :edit, :update, :destroy, :show]
  get '/approve', :to => "leaves#approve", as: 'approve'
  get '/reject', :to => "leaves#reject", as: 'reject'

  resources :public_holidays, only: [:new, :create, :index, :destroy]

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'login', to: 'sessions#create'
        delete 'logout', to: 'sessions#destroy'
        post 'checkin_or_checkout', to: 'attendance#checkin_or_checkout'
        post 'break_action', to: 'attendance#break_action'
      end
      resources :job_applications, only: [:create]
      resources :contact_details, only: [:create]
      get '/job_posts', :to => "job_applications#get_job_post_list", as: 'job_post_list'
      get '/job_posts/:id', to: "job_applications#show_job_post", as: 'show_job_post'
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
