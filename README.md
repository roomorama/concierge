# <img src="https://cloud.githubusercontent.com/assets/613784/13418979/98600198-dfb5-11e5-96fd-142dc2932b10.png" height="80" width="80" /> Concierge

<a href="https://circleci.com/gh/roomorama/concierge/tree/master">
  <img src="https://circleci.com/gh/roomorama/concierge.svg?style=shield&circle-token=bd8f156b6313c0c08cfd943593287516720250fb" />
</a>

`Concierge` performs calls to Roomorama suppliers. It is able to make booking quotations
and making actual bookings with partners.

### Supplier Partners

Concierge communicates with a number of Roomorama suppliers. For a technical
description of the workings of each supplier API, check the project [Wiki](https://github.com/roomorama/concierge/wiki).

What follows below is a general overview on how to add support for a new
supplier on Concierge. Before starting, it is highly recommended to
read the [project goals](https://github.com/roomorama/concierge/wiki/Concierge-Service-Goals).

### Authentication

By default, every request sent to Concierge is validated to make sure it comes from
a Roomorama webhook. That is done by checking if the `Content-Signature` HTTP header,
which must be present on every request, matches the given payload when signed with a
Roomorama secret.

Authentication is handled by the `API::Middlewares::Authentication` Rack middleware.

If you wish to test Concierge's API locally, either:

* Use `curl` or a browser extension that allows you to set HTTP request headers and set them
properly.

* Comment out the middleware inclusion on `apps/api/config/application.rb`. If you follow
this method, remember not to commit this change.

Note that the purpose of checking things out in a browser or `curl` is to make sure
things work on an integration level. If you wish to test the behaviour of a controller during
the development process, specs are the right tool for it.

### Quoting bookings

To add the capability of quoting a booking for a new supplier, create a new controller
as follows

~~~ruby
module API::Controllers::Supplier

  class Quote
    include API::Controllers::Quote

    # params API::Controllers::Params::MultiUnitQuote # uncomment for multi unit supplier

    def quote_price(params)
      Supplier::Client.new.quote(params)
    end

  end
end
~~~

`quote_price` is the only method whose implementation is necessary. You can assume
that the parameters at this point were already validated, so required parameters
will be present and valid.

In the code above, `Supplier::Client` is an implementation of a client library
for the supplier's API.

Note that the `quote_price` method:

* **must** return a `Quotation` object
* does not raise an exception if the supplier API is unavailable or errors out or any
network-related issue is happening.

If there are errors during the execution of the `quote_price` method, the `Quotation`
object returned must include a non-empty `errors` list to be returned to the caller,
which will receive a `503` HTTP status.

### Create bookings

To add the capability to create a booking for a new supplier, create a new controller
as follows

~~~ruby
module API::Controllers::Supplier

  class Booking
    include API::Controllers::Booking

    # params API::Controllers::Params::MultiUnitBooking # uncomment for multi unit supplier

    def create_booking(params)
      Supplier::Client.new.book(params)
    end

  end
end
~~~

`create_booking` is the only method whose implementation is necessary. You can assume
that the parameters at this point were already validated, so required parameters
will be present and valid.

In the code above, `Supplier::Client` is an implementation of a client library
for the supplier's API.

Note that the `create_booking` method:

* **must** return a `Reservation` object
* does not raise an exception if the supplier API is unavailable or errors out or any
network-related issue is happening.

If there are errors during the execution of the `create_booking` method, the `Reservation`
object returned must include a non-empty `errors` list to be returned to the caller,
which will receive a `503` HTTP status.

### Supplier Credentials

Oftentimes, supplier APIs requires some form of authentication in order to authenticate
requests coming from clients. It is highly recommended that such credentials do not
live in the codebase or under source control, but instead be declared as environment
variables that are going to be defined in the production environment. Credentials
are located at the `config/credentials` directory in files that match the running
environment.

It is equally important to make sure that all required credentials are defined by the
time the application boots in production environments. For such purpose, check the
`apps/api/config/initializers/validate_credentials.rb` file. For each supplier, there
is a list of required environment variables such that, if the application is booting
in production and one of the required credentials is not present or empty, it will raise
an exception and prevent the application from booting.


*****

Brought to you by [Roomorama](https://www.roomorama.com/).
