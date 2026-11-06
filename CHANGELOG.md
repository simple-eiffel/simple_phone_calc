# Changelog

## [Unreleased]

### Changed
- The app target sets `exception_trace`, so a crash names its routines.
- `HOWTO.md`: `gec` is found on the `PATH`, and `GOBO` and `GOBO_LIBRARY` are gone. Says why there are two compilers. The crash trace is from a real run.

## [1.0.0] - 2026-11-05

### Added
- A four-function calculator for Android, written entirely in Eiffel with `simple_eif_phone` 0.5.3.
- `CALC_ENGINE`: the logic, with contracts and no phone code.
- `CALC_APP`: the screen.
- 26 tests that run on a PC.
- `HOWTO.md`: every step from an empty folder to a signed app.
