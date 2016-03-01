# <img src="https://cloud.githubusercontent.com/assets/613784/13418979/98600198-dfb5-11e5-96fd-142dc2932b10.png" height="80" width="80" /> Concierge

`Concierge` performs calls to Roomorama suppliers. It is able to make booking quotations
and making actual bookings with partners.

### Quoting bookings

To add the capability of quoting a booking for a new supplier, create a new controller
as follows

~~~ruby
module API::Controllers::Partner

  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      Partner::Client.new.quote(params)
    end

  end
end
~~~

`quote_price` is the only method whose implementation is necessary. You can assume
that the parameters at this point were already validated, so required parameters
will be present and valid.

In the code above, `Partner::Client` is an implementation of a client library
for the supplier's API.

Note that the `quote_price` method:

* **must** return a `Quotation` object
* does not raise an exception if the supplier API is unavailable or errors out or any
network-related issue is happening.

If there are errors during the execution of the `quote_price` method, the `Quotation`
object returned must include a non-empty `errors` list to be returned to the caller,
which will receive a `503` HTTP status.

*****

Brought to you by [Roomorama](https://www.roomorama.com/).
