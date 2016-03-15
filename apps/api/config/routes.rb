get '/atleisure/quote',   to: 'at_leisure#quote'
get '/jtb/quote',         to: API::Controllers::JTB::Quote
get '/kigo/quote',        to: 'kigo#quote'
get '/kigo/legacy/quote', to: 'kigo/legacy#quote'
get '/poplidays/quote',   to: 'poplidays#quote'

post '/jtb/booking',      to: API::Controllers::JTB::Booking
