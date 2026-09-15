# Contributing

Contributions are welcome. Please open an issue before starting a large change.

## Development

```sh
swift test
xcrun swift-format lint -r Sources Tests scripts/generate-icon.swift
./scripts/build-app.sh
```

Keep the routing core independent from AppKit where possible and add tests for
new matching, browser, profile, or configuration behavior.

Update behavior is split between Sparkle's standard native UI and Rootie's
terminal user driver. Keep feed parsing, signature validation, installation,
and relaunch behavior inside Sparkle rather than duplicating it in Rootie.

Production releases remain ad-hoc code-signed and use the Sparkle signing key
documented in [`docs/updater-release-runbook.md`](docs/updater-release-runbook.md).
