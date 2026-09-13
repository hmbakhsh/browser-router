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
