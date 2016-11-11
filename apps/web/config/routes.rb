get "/sync_processes/:id/stats", to: "sync_processes#stats", as: :stats
post "/suppliers/worker_resync", to: "workers#resync",       as: :worker_resync
get "/",                         to: "dashboard#index",      as: :root

resources :errors,         only: [:index, :show], controller: "external_errors"
resources :reservations,   only: [:index]
resources :suppliers,      only: [:show]
resources :sync_processes, only: [:index]
