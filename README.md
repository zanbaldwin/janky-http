# HTTP Status Codes

Demo project for [`janky`](https://github.com/zanbaldwin/janky): an Anki deck of HTTP status codes.

- `plugins/iana.lua`: enriches content with reason phrases and RFC references fetched from the
  [IANA HTTP status code registry](https://www.iana.org/assignments/http-status-codes/),
- `plugins/response.lua`: adds template filters that draw each code as a mock `curl -i` response, complete with a
  typical header,
- And `notetypes/status.toml`: makes three cards per code (code → phrase, phrase → code, and meaning → code).

> **Note:** This is a demo intended for reference. This repository will not be maintained.

## Quick Start

1. Build [`janky`](https://github.com/zanbaldwin/janky).
2. Run `janky generate` to fetch the IANA registry (no API key needed this time).
3. Run `janky build`.
4. Import `.janky/build/http-status-codes.apkg` into Anki.
