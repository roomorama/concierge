get "/", to: "dashboard#index",       as: :root

resources :errors,         only: [:index, :show], controller: "external_errors"
resources :reservations,   only: [:index]
resources :suppliers,      only: [:show]
resources :sync_processes, only: [:index]

get "/kigo_image/:property_id/:image_id", to: "kigo_image#show"