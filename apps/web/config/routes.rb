get "/",       to: "dashboard#index",       as: :root

resources :errors, only: [:index, :show], controller: "external_errors"
