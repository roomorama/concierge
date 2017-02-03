get "/sync_processes/:id/stats", to: "sync_processes#stats", as: :stats
post "/suppliers/worker_resync", to: "workers#resync",       as: :worker_resync
get "/",                         to: "dashboard#index",      as: :root

resources :errors,         only: [:index, :show], controller: "external_errors"
resources :reservations,   only: [:index]
resources :suppliers,      only: [:show] do
  resources :hosts,        controller: "hosts" do
    resources :overwrites, controller: "overwrites"
    member do
      get '/properties', to: "hosts#properties", as: :properties
      post '/properties_push', to: "hosts#properties_push", as: :properties_push
    end
  end
end
resources :sync_processes, only: [:index]
