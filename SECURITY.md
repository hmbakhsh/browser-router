# Security

Please report security issues privately through GitHub's security advisory form
instead of opening a public issue.

Rootie processes URLs and profile metadata locally. It does not collect
telemetry or transmit browsing data. When a user explicitly checks for an
update, Rootie contacts the GitHub-hosted Sparkle feed and release assets. It
does not perform periodic update checks.

Release apps are ad-hoc code-signed and are not Apple-notarized. Sparkle verifies
the signed appcast and EdDSA-signed update archive before replacing the installed
app. This authenticates Rootie updates but does not provide Apple's Developer ID
identity or Gatekeeper notarization assurances. Signed-feed failures do not
expire into an unsigned fallback.
