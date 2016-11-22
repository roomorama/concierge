Concierge::SupplierConfig.data.values.each do |config|
  subpath = config["path"]
  controller = config["controller"]
  post "/#{subpath}/quote",   to: "#{controller}#quote"
  post "/#{subpath}/booking", to: "#{controller}#booking"
  post "/#{subpath}/cancel",  to: "#{controller}#cancel"
end

post '/checkout', to: 'static#checkout'
get '/kigo/image/:property_id/:image_id', to: 'kigo#image'
