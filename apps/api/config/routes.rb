Concierge::SupplierRoutes.declared_suppliers.each do |supplier_name|
  subpath = Concierge::SupplierRoutes.sub_path(supplier_name)
  controller = Concierge::SupplierRoutes.controller_name(supplier_name)
  post "/#{subpath}/quote",   to: "#{controller}#quote"
  post "/#{subpath}/booking", to: "#{controller}#booking"
  post "/#{subpath}/cancel",  to: "#{controller}#cancel"
end

post '/checkout', to: 'static#checkout'
get '/kigo/image/:property_id/:image_id', to: 'kigo#image'
