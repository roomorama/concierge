# Change Log

This file summarises the most important changes that went live on each release
of Concierge. Please check the Wiki entry on the release process to understand
how this file is formatted and how the process works.

## Unreleased
### Added
- Support for owner information when creating a `Roomorama::Property`

## [0.7.1] - 2016-08-17
### Changed
- Better error handling for 404 and 500 scenarios on Roomorama webhook
- Upgraded Rollbar to `2.12.0`

### Fixed
- Include CiiRUS `quote` endpoint in the routes file
- Pagination params validations
- `Roomorama::Calendar::StaysMapper` maps valid entries from tomorrow

## [0.7.0] - 2016-08-16
### Added
- Host fee percentage for AtLeisure
- External errors per supplier on the web ui
- Filter out AOA(allocation on arrival) properties for Ciirus supplier
- SAW integrations: quote, book, cancel and synchronisation

### Changed
- Do not store sync errors for Ciirus properties with bad permissions
- Use `MCPropertyName` to avoid empty property title during Ciirus sync
- Do not disable context during Ciirus sync processes
- SAW integrations: quote, book, cancel and synchronisation

### Fixed
- Dates not covered by stays wrongly sent as available to Roomorama
- Availabilities worker event name for Ciirus

## [0.6.0] - 2016-08-15
### Added
- Support for multi-unit availabilities on `Roomorama::Calendar`.
- `Roomorama::Calendar::Stay` and `StayMapper` to map supplier's format into `Roomorama::Calendar:Entry`
- Ciirus integrations: quote, book, cancel and synchronisation

### Changed
- Do not attempt to update calendar for properties not previously synchronised.

### Fixed
- error with saving response with ASCII-8BIT encoding type
- `Roomorama::Property.load` method incorrectly handled attributes set to `false`
- Room disable operation should be :put instead of :delete

## [0.5.5] - 2016-08-09
### Added
- Add check support for waytostay damage deposit
- Rake task to dispatch missing amenities as diff operation
- View suppliers, reservations and synchronisation process history on the `web` app

### Changed
- `Workers::PropertySynchronisation` doesn't update sync_processes' counters if Roomorama call failed

### Fixed
- amenities serialization for `Roomorama::Unit`.

## [0.5.4] - 2016-08-01
### Changed
- change request log name to `environment.log` (e.g., `staging.log`)

### Fixed
- Crash when a property isn't included in waytostay changes, but also not in concierge database

## [0.5.3] - 2016-07-28
### Added
- `net_rate`, `host_fee` and `host_fee_percentage` to quotation response
- `fee_percentage` column to `Host` entity
- Send inquiry id as `agent_reference` field to WayToStay
- Fee percentage for WayToStay
- `/checkout` endpoint which always returns a successful status.
- removed image presence validation for `Roomorama::Unit` entity

### Changed
- `Kigo::ResponseParser` set host's fee percentage to quotation
- Waytostay sync now loads properties in batches of 25

### Fixed
- Bug when integer timestamp is expected but Time is given instead

## [0.5.2] - 2016-07-21
### Changed
- `Roomorama::Calendar::Entry` now supports `minimum_stay` and synchronises that with Roomorama.
- Waytostay calendar client returns `minimum_stay` related to above

### Fixed
- Cancellation params name mismatch
- Wrong waytostay cancellation endpoint url

## [0.5.1] - 2016-07-21
### Added
- Cancellation webhook mappings
- Waytostay security deposit information

### Changed
- Waytostay `security_deposit` parses into either `cash` or `credit_card_auth` or nothing
- Waytostay images that has `is_visible=false` should not be imported
- Waytostay sync calls /calendar instead of /availabilities api
- `Reservation#code` is now `Reservation#reference_number`
- Do not process workers if there is already on instance running.

### Fixed
- Waytostay calendar crashes because there is no `start_date` for /rates api
- Calendar API call had wrong parameter name for prices.

## [0.5.0] - 2016-07-19
### Added
- added `currency_code` to the list of supported attributes for booking webhook and for `API::Controllers::Params::Booking` object
- added `get_active_properties` by Waytostay::Client, for first time import
- add `BackgroundWorker` and related refactor on queue processing.
- add `Workers::CalendarSynchronisation` to deal with updating the calendar of availabilities.
- `Concierge::Cache#invalidate` and the counterpart context event.

### Changed
- determine Roomorama API environment according to value in environment variable.
- fixed `SafeAccessHash#get` method to return `nil` for nonexistent keys
- fixed `SafeAccessHash#missing_keys_from` method to check for empty strings as well
- new structure for the `config/suppliers.yml` file.
- `Workers::Synchronisation` is now `Workers::PropertySynchronisation`.
- OAuth2Client invalidates cache if token is expired
- `Waytostay::Client#update_availability` to `#get_availability`, and the client use the info
- Fix issue on amenities when extracting diffs, by comparing properties in their serialized forms.

### Removed
- `update_calendar` method removed from `Roomorama::Property`.

## [0.4.4] - 2016-07-07
### Added
- Synchronisation with AtLeisure
- Ability to enable or disable context tracking at certain points in time.
- `Concierge::SafeAccessHash#merge` utils method
- `waytostay#get_changes` returns changes from waytostay api
- `waytostay#get_property` returns a roomorama property from waytostay api
- `waytostay#update_media` sets images to all the new images from waytostay
- `waytostay#update_availability` sets availability to all the new availability from waytostay
- Waytostay synchronisation worker
- `Kigo::Booking` - implemented booking with supplier

### Changed
- moved `JSONRPC` to `lib` folder
- customized timeout option for `HTTPClient`
- all clients return `Result` for both `quote` and `book` methods
- fixed an issue when declaring boolean values on the `credentials.yml` file.
- do not display response body on the `web` app if it is empty.
- fix issue when updating JSON fields using `Concierge::PGJSON`.

### Removed
- removed `fee` field from `Quotation`. Fees should be included in the total.
- removed `errors` field from `Quotation` and `Reservation`
- removed `successful?` method from `Quotation` and `Reservation`

## [0.4.3] - 2016-06-29
### Changed
- Waytostay treats a few cases as unavailable quotation, rather than an error

## [0.4.2] - 2016-06-28
### Added
- `API::Support::OAuth2Client`, a wrapper around oauth2 calls, caching access token and returning +Result+ objects
- `Context::TokenRequest` and `Context::TokenReceived` events, which is announced around Oauth2 token requests
- Shared partner #quote and #book examples
- `Waytostay::Client` which implements quoting and booking with partner
- `waytostay#quote` and `waytostay#booking`, which calls the above client and respond accordingly
- `byebug` for test/development debugging
- `Concierge::SafeAccessHash#missing_keys_from?` utils method
- `SyncProcess` entity and database, recording every synchronisation process run on Concierge.
- `SyncProcess#last_successful_sync_for_host` returns the last successful SyncProcess entity for a host

### Changed
- HTTPStubbing supports matching by body and headers, by including `strict: true` option to `stub_call`
- Quotation total and fee changed from int to float
- Register HTTP response when OAuth2 errors happen.
- Identify content-type more accurately on context view by normalizing header names.
- Ignore `price_check` event on webhooks, to avoid quoting stays twice.

### Removed
- removed the `message` column from the `external_errors` table, as well as related code.

## [0.4.1] - 2016-06-15
### Changed
- Check-in/check-out dates consistency validation on quote/booking calls.
- Master process does not crash if child worker was manually killed.
- Fixed a bug with exceptions on startup because of not created log directory.

## [0.4.0] - 2016-06-13
### Added
- `AtLeisure::Booking`, implemented booking with partner
- Synchronisation process architecture, including many utility classes.

### Changed
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
