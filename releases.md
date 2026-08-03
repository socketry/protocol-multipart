# Releases

## v0.2.0

  - Add strict, policy-driven parsing for parameterized `Content-Type` and `Content-Disposition` fields using `Protocol::Multipart::Headers`.
  - Limit multipart preamble size, header size, header count and part count by default.
  - Add `Protocol::Multipart::ByteLimit` for limiting streamed multipart content.
  - Add streaming multipart form-data parsing with field, upload and total content limits.

## v0.1.0
