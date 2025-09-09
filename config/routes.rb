Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # Email preview in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication required pages
  authenticate :user do
    resource :short_urls, only: [ :new, :create ]
    get "test", to: "short_urls#test"
    get "qr/:short_code", to: "short_urls#qr_code", as: :qr_code
    get "dashboard", to: "short_urls#new", as: :dashboard
    get "mypage", to: "mypage#index", as: :mypage
    post "mypage/sync", to: "mypage#sync", as: :mypage_sync
    delete "short_urls/:short_code", to: "mypage#destroy", as: :delete_short_url

    # Account management
    resource :account, only: [ :show ], controller: :accounts
  end

  # Public pages
  get "home", to: "pages#home"
  root "pages#home"
end
