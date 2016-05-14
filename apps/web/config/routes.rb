get "/",       to: "dashboard#index",       as: :root
get "/errors", to: "external_errors#index", as: :external_errors
