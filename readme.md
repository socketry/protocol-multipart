# `Protocol::Multipart`

[![Development Status](https://github.com/socketry/protocol-multipart/workflows/Test/badge.svg)](https://github.com/socketry/protocol-multipart/actions?workflow=Test)

## Releases

Please see the [project releases](https://socketry.github.io/protocol-multipart/releases/index) for all releases.

### v0.6.0

  - Rename `Protocol::Multipart::FormData::Parser::CONTENT_TYPE` to `MEDIA_TYPE`.

### v0.5.0

  - Add `Protocol::Multipart::LimitError` for configured processing limits.

### v0.4.0

  - Use consistent limit naming for multipart parser constraints.

### v0.3.0

  - Add a configurable `Protocol::Multipart::FormData::Parser` which parses a streaming body and explicit boundary into nested arguments.
  - Use `Protocol::URL::FormData::Nested` so URL-encoded and multipart forms share hierarchy semantics.
  - Allow `Protocol::Multipart::FormData::Parser#parse` to populate a supplied result object.

### v0.2.0

  - Add strict, policy-driven parsing for parameterized `Content-Type` and `Content-Disposition` fields using `Protocol::Multipart::Headers`.
  - Limit multipart preamble size, header size, header count and part count by default.
  - Add `Protocol::Multipart::ByteLimit` for limiting streamed multipart content.
  - Add streaming multipart form-data parsing with field, upload and total content limits.

### v0.1.0

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
