post '/atleisure/quote',     to: 'at_leisure#quote'
post '/jtb/quote',           to: 'j_t_b#quote'
post '/kigo/quote',          to: 'kigo#quote'
post '/kigo/legacy/quote',   to: 'kigo/legacy#quote'
post '/poplidays/quote',     to: 'poplidays#quote'
post '/waytostay/quote',     to: 'waytostay#quote'

post '/jtb/booking',         to: 'j_t_b#booking'
post '/atleisure/booking',   to: 'at_leisure#booking'
post '/waytostay/booking',   to: 'waytostay#booking'
post '/kigo/booking',        to: 'kigo#booking'
post '/kigo/legacy/booking', to: 'kigo/legacy#booking'

post 'waytostay/cancel', to: 'waytostay#cancel'

post 'checkout', to: 'static#checkout'
