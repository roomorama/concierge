# Change Log

This file summarises the most important changes that went live on each release
of Concierge. Please check the Wiki entry on the release process to understand
how this file is formatted and how the process works.

## Unreleased
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
