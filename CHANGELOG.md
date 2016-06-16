# Change Log

This file summarises the most important changes that went live on each release
of Concierge. Please check the Wiki entry on the release process to understand
how this file is formatted and how the process works.

## Unreleased
### Changed
- Check-in/check-out dates consistency validation on quote/booking calls.
- Master process does not crash if child worker was manually killed.
- Fixed a bug with exceptions on startup because of not created log directory.
- HTTPStubbing supports matching by body and headers, by including `strict: true` option to `stub_call`
- Quotation total and fee changed from int to float

### Added
- `API::Support::OAuth2Client`, a wrapper around oauth2 calls, caching access token and returning +Result+ objects
- `Context::TokenRequest` and `Context::TokenReceived` events, which is announced around Oauth2 token requests
- Shared partner #quote and #book examples
- `Waytostay::Client` which implements quoting and booking with partner
- `waytostay#quote` and `waytostay#booking`, which calls the above client and respond accordingly
- `byebug` for test/development debugging
- `Concierge::SafeAccessHash#missing_any?` utils method


## [0.4.0] - 2016-06-13
### Added
- `AtLeisure::Booking`, implemented booking with partner
- Synchronisation process architecture, including many utility classes.

## Changed
- fixed a bug with timezone formatting by using %z directive for strftime() instead of %Z

## [0.3.0] - 2016-05-30
### Added
- `Concierge::Context`, tracking of events on API requests, reporting on the `web` app for external errors.

## [0.2.2] - 2016-05-23
### Added
- checking exceeded stay length for JTB

### Changed
- fixed a bug on JTB's response parser when a unit has only one rate plan

## [0.2.1] - 2016-05-20
### Changed
- fixes issue on external errors page where query string could cause a 500 error.
- change the way error notifications are handled on the `web` app to get Rollbar notifications.

## [0.2.0] - 2016-05-19
### Added
- support for request logging and health checking on the web app.
- new Hanami app: `web`. Builds a web interface for inspecting API status and external errors.

## [0.1.4] - 2016-04-21
- make Concierge operations resilient to database failures (introduces Emergency Log).
- time-of-check, time-of-use issue on Concierge's cache. Fixes [Rollbar #8](https://rollbar.com/Roomorama/Concierge/items/8/).
- valid name for customer with non-latin letters for JTB client

## [0.1.3] - 2016-04-07
### Changed
- fixed a bug on JTB's response parser when a unit is not available (no rate plans returned.)

## [0.1.2] - 2016-04-04
### Added
- database table to keep reservations while webhook doesn't support booking code

### Changed
- fix occasional non-iteratable rate plans on JTB response for checking price.
- caching for JTB fetching rate plan to avoid the same call to JTB::API
- support for cache serializers, allowing JTB to store cache responses as JSON.

## [0.1.1] - 2016-03-29
### Added
- Price check ability for:
  - AtLeisure
  - JTB
  - Kigo (and Kigo Legacy)
  - Poplidays
- Booking ability for JTB.
- `Result` objects and `InternalError` handling.
- Persistence with PostgreSQL.
- `Concierge::Cache`, using a relational store.
- `Concierge::SafeAccessHash` for navigating supplier's API responses safely.
- Credentials and environment variables management.
- Pub/Sub facility, `Announcer`.
- Authentication via the `Content-Signature` header.
- Transparent Roomorama Webhook compatibility with the `API::Middlewares::RoomoramaWebhook` middleware.
