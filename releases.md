# Releases

## v0.4.0

  - Use consistent limit naming for multipart parser constraints.

## v0.3.0

  - Add a configurable `Protocol::Multipart::FormData::Parser` which parses a streaming body and explicit boundary into nested arguments.
  - Use `Protocol::URL::FormData::Nested` so URL-encoded and multipart forms share hierarchy semantics.
  - Allow `Protocol::Multipart::FormData::Parser#parse` to populate a supplied result object.

## v0.2.0

  - Add strict, policy-driven parsing for parameterized `Content-Type` and `Content-Disposition` fields using `Protocol::Multipart::Headers`.
  - Limit multipart preamble size, header size, header count and part count by default.
  - Add `Protocol::Multipart::ByteLimit` for limiting streamed multipart content.
  - Add streaming multipart form-data parsing with field, upload and total content limits.

## v0.1.0
