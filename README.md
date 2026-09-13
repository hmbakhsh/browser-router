# Browser Router

A tiny native macOS app that opens links in the right Chromium browser profile.
No Electron, no background service, and no browser extension for links opened
from Mail, Slack, Terminal, IDEs, and other apps.

**Website:** [rootie.hbak.co](https://rootie.hbak.co)

## Features

- Routes by exact domain, subdomain, and path prefix
- Opens the matching Chromium profile directly
- Automatic starter configuration based on installed browsers and profiles
- Plain JSON configuration at `~/.browser-router/config.json`
- CLI for setup, discovery, and validation
- Native menu-bar app with negligible idle CPU use
- Universal app for Apple Silicon and Intel Macs

## Supported browsers

Browser Router automatically detects:

- Helium
- Google Chrome
- Brave Browser
- Microsoft Edge
- Chromium
- Vivaldi

Other Chromium forks work by setting their application and user-data paths in
the JSON configuration.

## Install

### Homebrew

```sh
brew install --cask hmbakhsh/tap/browser-router
```

This installs both **Browser Router.app** and the `browser-router` command.

### Install script

```sh
curl -fsSL https://raw.githubusercontent.com/hmbakhsh/browser-router/main/scripts/install-release.sh | zsh
```

### Download

Download `Browser-Router.zip` from the
[latest release](https://github.com/hmbakhsh/browser-router/releases/latest),
unzip it, and move **Browser Router** to your Applications folder.

On first launch, Browser Router creates `~/.browser-router/config.json` using an
installed browser and profile, then opens it in your text editor. Add your rules,
save the file, choose **Reload Configuration**, then choose **Make Default
Browser** from the menu-bar icon.

You can instead configure it from Terminal:

```sh
browser-router setup
browser-router config
browser-router validate
browser-router default
```

Run `browser-router help` for browser and profile discovery commands or use
`--browser` and `--profile` with `setup` for non-interactive configuration.

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

Set `includeSubdomains` to match an apex domain and its subdomains. Set an
optional `pathPrefix` to limit a rule to one URL path. Rules are evaluated from
top to bottom; the first enabled match wins, and unmatched links use
`defaultProfile`.

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
