Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # API v1
  namespace :api do
    namespace :v1 do
      # Sleep Records API
      resources :users do
        resources :sleep_records, only: [:index] do
          collection do
            post :clock_in
            patch :wake_up
          end
        end
      end
    end
  end
end
