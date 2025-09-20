Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Two-Factor Authentication routes
  namespace :users do
    resource :two_factor_authentications, only: [ :show, :new, :create, :destroy ] do
      collection do
        post :verify
        post :backup_codes
      end
    end

    # WebAuthn routes
    resources :webauthn_credentials, only: [ :create, :update, :destroy ] do
      collection do
        get :registration_options
        get :authentication_options
        get :login_options
      end
    end
  end

  # Email preview in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check endpoint for Docker/Caddy (alias for /up)
  get "health" => "rails/health#show", as: :health_check

  # Version info endpoint for deployment verification
  get "version", to: "pages#version"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication required pages
  authenticate :user do
    resource :short_urls, only: [ :new, :create ]
    resources :short_urls, param: :short_code, only: [ :edit, :update ]
    get "test", to: "short_urls#test"
    get "qr/:short_code", to: "short_urls#qr_code", as: :qr_code
    get "dashboard", to: "short_urls#new", as: :dashboard
    get "mypage", to: "mypage#index", as: :mypage
    post "mypage/sync", to: "mypage#sync", as: :mypage_sync
    delete "short_urls/:short_code", to: "mypage#destroy", as: :delete_short_url

    # Account management
    resource :account, only: [ :show, :update ], controller: :accounts

    # Statistics API
    namespace :statistics do
      get :overall, to: "overall#index"
      get :url_list, to: "individual#url_list"
      get "individual/:short_code", to: "individual#show", as: :individual
    end
  end

  # Admin routes (authentication handled in AdminController)
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    root "dashboard#index"

    # ユーザー管理
    resources :users, only: [ :index, :show, :update, :destroy ] do
      member do
        patch :toggle_role
        patch :lock_user
        patch :unlock_user
      end
    end

    # システム設定
    resource :settings, only: [ :show, :update ] do
      collection do
        get :category
        post :reset
        post :test
      end
    end

    # 法的文書編集
    resources :legal_documents, only: [ :index, :show, :edit, :update ]


    # Solid Queue 詳細ダッシュボード
    resources :solid_queue, only: [ :index, :destroy ] do
      member do
        post :retry
      end
      collection do
        get :workers
        get :processes
        get :failed_jobs
        post :retry_all
        delete :clear_all
        delete :clear_finished
      end
    end
  end

  # Legal pages
  get "terms", to: "legal#terms_of_service", as: :terms_of_service
  get "privacy", to: "legal#privacy_policy", as: :privacy_policy

  # Public pages
  get "home", to: "pages#home"
  root "pages#home"

  # Easter egg: RFC 2324 - Hyper Text Coffee Pot Control Protocol
  get "teapot", to: "pages#teapot"
  get "coffee", to: "pages#teapot" # Coffee requests also redirect to teapot
  get "brew", to: "pages#teapot"   # Brew requests also redirect to teapot
end
