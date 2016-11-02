# Change Log

This file summarises the most important changes that went live on each release
of Concierge. Please check the Wiki entry on the release process to understand
how this file is formatted and how the process works.
## [0.13.0] - 2016-11-02
### Added
- Avantio integrations: quote, book, cancel and synchronisation

## [0.12.15] - 2016-11-01
### Added
- Streamlined errors from waytostay quote
- More detailed errors in quote response

### Changed
- Property synchronisation would not skip purging properties when 1 property fail in #start

## [0.12.14] - 2016-10-27
### Added
- Changed atleisure customer email
- Changed SAW customer email
- Kigo: add better error reporting by adding descriptions to response parser errors

## Fixed
- Kigo: Bug in availabilities min stay parsing

## [0.12.13] - 2016-10-24
### Added
- Rentals United: add translations for zh de es languages for late/early fees

## [0.12.12] - 2016-10-21
### Added
- Rentals United: add late check-in / early check-out fees to description_append

### Fixed
- Atleisure: set cleaning fee mapping logic according to #405
- `Kigo::Calendar` now respects to property's `minimum_stay` value if it's more stricter

## [0.12.11] - 2016-10-21
### Added
- Atleisure, Ciirus, Poplidays, Kigo, Waytostay, RentalsUnited: add error.data reporting to Rollbar
- Translations for title, description, t&c, check_in_instructions and
description_append on Roomorama::Property

## [0.12.10] - 2016-10-19
### Fixed
- Poplidays: metadata sync is safe for `nil` availabilities response

### Added
- Ability to retry for specific http codes by HttpClient
- Kigo rate limit would retry up to 8 times

## [0.12.9] - 2016-10-18
### Fixed
- Outdated method call when Kigo calendar checks if host is active
- Empty criteria for multiunit property's calendar

## [0.12.8] - 2016-10-17
### Added
- Rentals United: add number_of_bathrooms, number single, double, sofa beds fields
- Synchronisation#mark_as_processed

### Fixed
- Rentals United: fix exception which was raised while parsing multi-lang check-in instructions
- Kigo and Kigo Legacy metadata sync should not purge properties when rate limitted

## [0.12.7] - 2016-10-17
### Fixed
- Ensure synchronisation.finish! for Kigo host with empty properties
- Kigo legacy hosts should not be deleted from Concierge
- SAW: cleaning fee patch

### Changed
- Waytostay: return unavailable quotation instead error when max number of days before arrival reached
- order of events on error show page

## [0.12.6] - 2016-10-12
### Added
- Rollbar warning for external warnings

## [0.12.5] - 2016-10-11
### Fixed
- Fix crash when kigo pricing does not return MIN_STAY rules #430

## [0.12.4] - 2016-10-11
### Fixed
- uninitialized constant `API::Controllers::InternalError` for ubuntu 16.04

### Added
- Kigo min_stay validity check, returning an error Result if the promised MIN_STAY_RULES is not found
- Rentals United: add arrival instructions to Roomorama::Property

### Chagned
- Unavailable quotations are of status code 200
- Rentals United: support caching for needed fetcher classes

## [0.12.3] - 2016-10-07
### Fixed
- KigoLegacy metadata worker typo

### Added
- Ability to call `skip_property` from `start`'s block

## [0.12.2] - 2016-10-07
### Added
- Host id and property id in kigo legacy sync process to Rollbar scope

## [0.12.1] - 2016-10-06
## Fixed
- Kigo minimum stay is parsed from MIN_STAY_RULES
- SAW parse `no_allocation` and `fair_warning` flags

### Changed
- Atleisure: improved error code and message for quoting "on request only" period
- Move setting error message prefixes to controller-level

### Added
- SAW: parse owner information for Roomorama::Property

## [0.12.0] - 2016-10-05
### Added
- Rentals Untied sync, quote, book and cancel

### Changed
- Abstract host fee calculation from suppliers to entity level
- Return 404 for attempts to quote a property not in records

## [0.11.6] - 2016-10-03
### Fixed
- Proper order of table columns for sync_process/index page
- Poplidays: metadata sync is safe for `nil` availabilities

## [0.11.5] - 2016-09-28
### Changed
- Workers marked as `queued` to avoid duplicated messages on SQS.

## [0.11.4] - 2016-09-26
### Removed
- Requirement for workers to finish in 12h no longer exists

## [0.11.3] - 2016-09-23
### Fixed
- Kigo: set `minimum_stay` to `nil` instead of 1 for calendar entry when coming NUMBER is zero

## [0.11.2] - 2016-09-22
### Fixed
- Atleisure config being paresed as boolean by YAML

## [0.11.1] - 2016-09-22
### Added
- Add `rake hosts:create` to, well, create hosts

### Changed
- `Workers::CalendarSynchronisation` doesn't run operation for empty calendar

## [0.11.0] - 2016-09-21
### Added
- `ZendeskNotify` client with ticket creation on cancellation of bookings from Poplidays and AtLeisure

### Fixed
- Ciirus:: ignore permissions error about MC disabled clone properties
- SAW: return unavailable quotation instead of Result.error while quote price
- SAW: pass stay length = 2 days instead 1 so that API returns prices for a bit more properties
- SAW: add synchronisation.new_context for metadata worker
- SAW: renamed PropertyRate entity to UnitsPricing
- SAW: Skip invalid postal code "." #286

## [0.10.0] - 2016-09-20
### Added
- Atleisure:: calendar sync worker
- reason for all properties skipped during sync
- page for sync process stats

### Fixed
- Ciirus:: skip properties without images

## [0.9.2] - 2016-09-19
### Fixed
- Improper type/subtype combinations
- Ciirus:: skip properties with monthly rates

## [0.9.1] - 2016-09-15
### Added
- Ciirus (0, 0) coordinates validation
- skip Ciirus properties with demo images

### Changed
- `E_EMPTY` error for Kigo and KigoLegacy handled as unavailable, instead of saving an error
- Upgraded Ruby from 2.3.0 to 2.3.1

### Fixed
- Ciirus:: skip deleted properties during sync
- Ciirus:: skip mc disabled properties during sync
- Ciirus:: skip properties with empty description
- KigoLegacy calendar worker now finishes successfully when there are no identifiers to be updated

## [0.9.0] - 2016-09-13
### Added
- fee percentage for hosts on Web app on suppliers#show.
- `Workers::Suppliers::Kigo::Legacy::Calendar` skip process for deactivated hosts
- Poplidays integration: metadata sync, calendar sync, quoting, booking, cancelling support.

### Changed
- Lack of rates when quoting prices for Kigo and KigoLegacy no longer treated as an error

### Fixed
- Kigo property images with non-Latin characters

## [0.8.0] - 2016-09-08
### Added
- Kigo and KigoLegacy integration: metadata sync, calendar sync, quoting, booking, cancelling support.

### Changed
- SAW: return unavailable quotation instead of Result.error when rates are not returned for a unit.
- Increase SQS default visibility timeout to 12h.

### Fixed
- Cache hit rendering when the saved value is an array.

## [0.7.4] - 2016-09-05
### Added
- Support for the `aggregated` flag on `config/suppliers.yml`, allowing workers to run once per supplier.
- Allow worker implementation specify parameters for the next run.
- Better error message for unknown background worker IDs enqueued.
- Ability to filter by error code on the `web` app.
- Synchronisation with Kigo
- Synchronisation with KigoLegacy
- `CONCIERGE_API_SECRET` for signing `GET` requests
- `Kigo::ImageFetcher` - to download images by Kigo's API
- environment variable CONCIERGE_URL
- Kigo Legacy images fetching through controller
- host deletion flow
- Kigo cancellation

### Changed
- Rename class: `Workers::Suppliers::Ciirus::Calendar` -> `Workers::Suppliers::Ciirus::Availabilities`
- Rename spec file: `ciirus/calendar_worker_spec.rb` -> `ciirus/availabilities_spec.rb`
- Rename spec file: `ciirus/metadata_worker_spec.rb` -> `ciirus/metadata_spec.rb`

### Fixed
- SAW: ignore non-refundable prices for units while rates fetching
- Ignore unsupported ciirus property types until another review
- SAW: fixed `reference_number` parameter name for cancellation
- html escape for `event[:message]`

## [0.7.3] - 2016-08-25
### Changed
- Represent empty arrays as `[]` during formatting external errors' JSON
- Stop creating external errors for expected messages from Ciirus

### Fixed
- Waytostay property batch fetching should include disabled properties
- Backticks formatting for failure to quote price for SAW units.
- Missing images for unpublished properties

## [0.7.2] - 2016-08-23
### Added
- `Synchronisation#new_context` to contextualize work that may announce error in a supplier worker implementation
- Support for owner information when creating a `Roomorama::Property`
- Owner info for AtLeisure properties
- Skipped properties counters for metadata sync process
- Simple pagination widget for external errors UI table

### Changed
- Remove `Roomorama::Calendar::Stay.available` field
- Empty rates and ones with errors will be purged instead of raising an external error
- SAW: return error when rates are not found in the response for requested unit
- Make location info for Waytostay sync

### Fixed
- `Roomorama::Calendar::StaysMapper` maps valid entries from tomorrow
- `Roomorama::Calendar::StaysMapper` for empty stays case
- Room disable operation should actually be :delete instead of :put
- Send `[]` instead of `nil` for `Roomorama::Calendar::Entry.valid_stay_length`

## [0.7.1] - 2016-08-17
### Changed
- Better error handling for 404 and 500 scenarios on Roomorama webhook
- Upgraded Rollbar to `2.12.0`

### Fixed
- Include CiiRUS `quote` endpoint in the routes file
- Pagination params validations

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
- `API::Middlewares::Authentication` with get request condition
- `API::Middlewares::RoomoramaWebhook` with get request condition
- `SyncProcess.recent_successful_sync_for_host` separated on `.successful` and `.for_host` methods

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
- `Kigo::Request` and `Kigo::LegacyRequest` - changed optional settings for http client

### Fixed
- amenities serialization for `Roomorama::Unit`.
- `Concierge::Context::NetworkResponse` - convert response body in UTF-8 encoding type

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
