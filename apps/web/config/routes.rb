get "/sync_processes/:id/stats", to: "sync_processes#stats", as: :stats
post "/suppliers/worker_resync", to: "workers#resync",       as: :worker_resync
get "/",                         to: "dashboard#index",      as: :root

resources :errors,         only: [:index, :show], controller: "external_errors"
resources :reservations,   only: [:index]
resources :suppliers,      only: [:show] do
  resources :hosts,        only: [:new, :create, :edit], controller: "hosts" do
    resources :overwrites, controller: "overwrites"
  end
end
resources :sync_processes, only: [:index]
