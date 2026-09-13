# Browser Router

A tiny native macOS app that opens links in the right Chromium browser profile.
No Electron, no background service, and no browser extension for links opened
from Mail, Slack, Terminal, IDEs, and other apps.

## Features

- Routes by exact domain, subdomain, and path prefix
- Opens the matching Chromium profile directly
- First-run setup with automatic browser and profile discovery
- Plain JSON configuration at `~/.browser-router/config.json`
- Native menu-bar app with negligible idle CPU use
- Universal app for Apple Silicon and Intel Macs

## Supported browsers

The setup screen automatically detects:

- Helium
- Google Chrome
- Brave Browser
- Microsoft Edge
- Chromium
- Vivaldi

Other Chromium forks work by setting their application and user-data paths in
the JSON configuration.

## Install

### One command

```sh
curl -fsSL https://raw.githubusercontent.com/hmbakhsh/browser-router/main/scripts/install-release.sh | zsh
```

### Download

Download `Browser-Router.zip` from the
[latest release](https://github.com/hmbakhsh/browser-router/releases/latest),
unzip it, and move **Browser Router** to your Applications folder.

On first launch:

1. Choose your Chromium browser.
2. Choose the default and routed profiles.
3. Add matching domains, one per line.
4. Click **Save and make default**.

## Domain patterns

The setup screen accepts concise patterns:

```text
meet.google.com
*.example.com
github.com/your-organization/**
app.example.com/workspace/**
```

- `example.com` matches the exact host.
- `*.example.com` matches the apex and all subdomains.
- A path ending in `/**` matches that path and its descendants.

Rules are evaluated from top to bottom. The first enabled match wins; unmatched
links use `defaultProfile`.

## JSON configuration

Use **Open Configuration** in the menu bar, or edit:

```text
~/.browser-router/config.json
```

See [`config.example.json`](config.example.json) for the complete format. To use
another Chromium fork, set:

```json
{
  "browser": {
    "name": "My Chromium Fork",
    "applicationPath": "/Applications/My Browser.app",
    "userDataPath": "~/Library/Application Support/My Browser"
  }
}
```

Profile values are display names from the browser's profile menu, not directory
names. Reload after editing. Invalid JSON stops routing rather than opening a
link under the wrong identity.

## Build from source

Requires macOS 13 or later and Xcode 16 or later.

```sh
git clone https://github.com/hmbakhsh/browser-router.git
cd browser-router
./scripts/install.sh
```

Tests and release build:

```sh
swift test
./scripts/build-app.sh
```

## Limitations

- macOS only sends links from external apps to its default browser handler.
  Links clicked inside a browser require a browser extension.
- Release builds are currently ad-hoc signed rather than Apple-notarized.

## Privacy

Browser Router runs locally. It does not send URLs, configuration, or profile
data anywhere.

## License

[MIT](LICENSE)
