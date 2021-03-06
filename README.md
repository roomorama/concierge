# <img src="https://cloud.githubusercontent.com/assets/613784/13418979/98600198-dfb5-11e5-96fd-142dc2932b10.png" height="80" width="80" /> Concierge

<a href="https://circleci.com/gh/roomorama/concierge/tree/master">
  <img src="https://circleci.com/gh/roomorama/concierge.svg?style=shield&circle-token=bd8f156b6313c0c08cfd943593287516720250fb" />
</a>

![Concierge Web App](https://cloud.githubusercontent.com/assets/613784/17511395/40fa0f92-5e55-11e6-9d9e-a026cd4c6540.png)

`Concierge` performs calls to Roomorama suppliers. It is able to make booking quotations
and making actual bookings with partners.

### Concierge Apps

Concierge embraces the container architecture encouraged by the Hanami framework.
In that sense, Concierge is divided into two apps: `api` and `web`. The former is
responsible for being a provider for Roomorama webhooks; the latter is a web interface
for inspecting general runtime data from the API. See the [Wiki entry](https://github.com/roomorama/concierge/wiki/Concierge-Apps)
on the apps to understand how responsibility is divided.

Unless explicitly mentioned, all the documentation below refers to the API,
the most important component of Concierge, dealing with supplier integrations
and performing operations on behalf of Roomorama.

### Supplier Partners

Concierge communicates with a number of Roomorama suppliers. For a technical
description of the workings of each supplier API, check the project [Wiki](https://github.com/roomorama/concierge/wiki).

What follows below is a general overview on how to add support for a new
supplier on Concierge. Before starting, it is highly recommended to
read the [project goals](https://github.com/roomorama/concierge/wiki/Concierge-Service-Goals).

### Communication with Roomorama

Concierge was conceived as a _webhook provider_ for externally supplied properties.
This means that Concierge makes it possible to instantly book properties managed by
Roomorama's suppliers through the use of webhooks: endpoints associated with different
properties that allow Roomorama to check the price and availability of stays and to
confirm bookings on external platforms in a transparent manner.

Currently, Concierge is compatible with the format of Roomorama's webhooks through
the use of the `API::Middlewares::RoomoramaWebhook` Rack middleware. That format
is not ideal, and the use of the middleware makes straightforward to use a better,
default Concierge format when the time comes for Roomorama to support a simpler
webhook format.

### Authentication

By default, every request sent to Concierge is validated to make sure it comes from
a Roomorama webhook. That is done by checking if the `Content-Signature` HTTP header,
which must be present on every request, matches the given payload when signed with a
Roomorama secret.

Authentication is handled by the `API::Middlewares::Authentication` Rack middleware.
Each supplier has its own secret, which is configured on Roomorama and associated with
the supplier on Concierge. Secrets are supposed to live in environment variables on
production/staging environments. Check the aforementioned class to understand how
secrets are organised.

If you wish to test Concierge's API locally, either:

* Use `curl` or a browser extension that allows you to set HTTP request headers and set them
properly.

* Comment out the middleware inclusion on `apps/api/config/application.rb`. If you follow
this method, remember not to commit this change.

Note that the purpose of checking things out in a browser or `curl` is to make sure
things work on an integration level. If you wish to test the behaviour of a controller during
the development process, specs are the right tool for it.

### Database Access

Database access in Concierge exists as a means to provide extra functionality during
the execution of the operations provided. However, it is by no means a _required_
precondition for Concierge to work. Therefore, whenever possible, make database access
optional.

A convenience class - `Concierge::OptionalDatabaseAccess` - is provided so that
control can be regained even on the situation when the database is unaccessible.

The caching functionality provided by Concierge - `Concierge::Cache` already makes
use of such feature and therefore no changes are needed if the database is only
used for caching.

### API Context

During a request cycle, many events might happen: network calls (requests and responses),
cache lookups, SOAP operations, among others. Concierge defines the concept of the `context`
of a call being the set of events that happened in the lifecycle of a request. Data about
such events is collected so that, in the ocurrence of an error (that is, an `external error`),
events data can be serialized and later displayed in the `web` app for analysis.

### Required API endpoints for Suppliers

For an overview of the required endpoints supplier API implementations should provide
on Concierge as well as their implementation, check out the
[Required Supplier Webhooks](https://github.com/roomorama/concierge/wiki/Required-Supplier-Webhooks)
Wiki entry.

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

#### Environment Variables

Whenever the use of environment variables is necessary outside of the "supplier credentials"
context described above, make sure that the variable is properly declared in the
in the corresponding YML file. Variables required for the `api` app must be listed
on `apps/api/config/environment_variables.yml`. Similarly, variables required on the
`web` app must be declared on `apps/web/config/environment_variables.yml`. Variables
defined on `config/environment_variables.yml` will be required no matter what app
is being booted.

*****

Brought to you by [Roomorama](https://www.roomorama.com/).
