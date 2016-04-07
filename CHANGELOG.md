# Change Log

This file summarises the most important changes that went live on each release
of Concierge. Please check the Wiki entry on the release process to understand
how this file is formatted and how the process works.

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
