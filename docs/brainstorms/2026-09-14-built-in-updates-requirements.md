---
date: 2026-09-14
topic: built-in-updates
---

# Built-in Rootie Updates

## Summary

Rootie will provide user-triggered update checks from both the CLI and menu bar,
using Sparkle 2 to provide one confirmed, verifiable upgrade flow for both
Homebrew and manual installations.

---

## Problem Frame

Rootie can currently be updated through Homebrew or by reinstalling a release,
but users must know which command or installation path to use. The app does not
surface update availability, explain what will change, or guide users through
the correct mechanism. This leaves installed versions behind newly released
CLI and routing capabilities.

---

## Actors

- A1. Rootie user: checks for and approves an available update.
- A2. Rootie: presents the appropriate CLI or native interface and coordinates
  the Sparkle update lifecycle.
- A3. Release provider: GitHub Releases supplies the ad-hoc-signed app, Sparkle
  appcast, release notes, and EdDSA-signed update archive.

---

## Key Flows

- F1. CLI update
  - **Trigger:** A1 runs the Rootie update command.
  - **Actors:** A1, A2, A3
  - **Steps:** Rootie checks the latest official release, reports whether an
    update exists, shows the version and release notes, asks permission, and
    invokes Sparkle's trusted installation path.
  - **Outcome:** Rootie is upgraded and relaunched, or exits unchanged with a
    clear cancelled, current, offline, or failed status.
  - **Covered by:** R1, R3, R4, R5, R6, R7
- F2. Menu-bar update
  - **Trigger:** A1 chooses **Check for Updates…**.
  - **Actors:** A1, A2, A3
  - **Steps:** Rootie checks the latest official release, presents the result in
    native UI, asks permission when an update exists, and coordinates the same
    installation behavior as the CLI.
  - **Outcome:** The app is upgraded and running again, or remains unchanged
    with clear feedback.
  - **Covered by:** R2, R3, R4, R5, R6, R7

---

## Requirements

**Entry points and presentation**

- R1. The CLI provides a user-triggered update command.
- R2. The menu bar provides a user-triggered **Check for Updates…** action.
- R3. Both entry points report the installed and latest versions and show
  release notes before requesting installation approval.
- R4. Rootie must require explicit confirmation before installing an available
  update; cancellation leaves the current installation unchanged.

**Installation paths and safety**

- R5. Rootie uses Sparkle 2 for both Homebrew and manual installations; the
  Homebrew cask declares that Rootie updates itself so Homebrew does not compete
  with the in-app updater.
- R6. Rootie updates from the official GitHub release appcast, verifies the
  downloaded archive using Sparkle's EdDSA signature before replacement,
  preserves user configuration, and relaunches successfully.
- R7. Update failures must leave a working prior installation whenever
  replacement has begun and provide an actionable error rather than reporting
  success.

**Status handling**

- R8. Rootie clearly distinguishes already-current, update-available,
  cancelled, offline, metadata-invalid, verification-failed, install-failed,
  and successful states.
- R9. Update checks are user-triggered only and do not run periodically or
  silently in the background.

---

## Acceptance Examples

- AE1. **Covers R3, R4, R5.** Given a Homebrew-installed older version, when the
  user checks from either entry point, Rootie shows the newer version and notes;
  after approval, Sparkle performs the upgrade and Rootie relaunches without
  breaking the Homebrew-managed command symlink.
- AE2. **Covers R4.** Given an available update, when the user declines, no app
  files or configuration change.
- AE3. **Covers R6, R7.** Given a manual installation and a valid newer release,
  when the user approves, Sparkle verifies the asset before replacement,
  preserves configuration, and relaunches the new version.
- AE4. **Covers R7, R8.** Given a downloaded asset whose EdDSA signature is
  invalid, when Sparkle verifies it, installation stops, the current app remains
  usable, and Rootie reports verification failure.
- AE5. **Covers R8.** Given the installed version is latest, when the user checks,
  Rootie reports that it is current and does not ask to install.
- AE6. **Covers R8.** Given GitHub is unavailable, when the user checks, Rootie
  reports a connectivity failure without changing the installation.

---

## Success Criteria

- Users can update Rootie without knowing whether Homebrew or a manual install
  originally placed the app.
- Neither entry point can replace Rootie without explicit user approval and a
  verified source.
- Failed and cancelled updates leave Rootie and `~/.rootie/config.json` usable.
- CLI and menu behavior share the same update states and outcomes.

---

## Scope Boundaries

- No periodic checks, automatic downloads, or silent background installation.
- No custom app-replacement helper or Homebrew-specific update orchestration;
  Sparkle 2 owns update verification, replacement, rollback, and relaunch.
- No separately hosted update service; the appcast and archives live in GitHub
  Releases.
- No update channels, prerelease opt-in, or downgrade flow in the first version.
- The Agent Skill remains independently updated through the skills installer.
- Automating Homebrew tap publication is separate from the client upgrade flow.

---

## Key Decisions

- GitHub Releases is the authoritative source for update availability and
  release details because it already owns Rootie's published artifacts.
- Sparkle 2 owns updates for both Homebrew and manual installations, following
  the established Homebrew `auto_updates true` convention used by apps such as
  Hex.
- Rootie uses Sparkle's standard native update UI from the menu bar and a custom
  terminal user driver for the CLI so both entry points share Sparkle's update
  engine while preserving interface-appropriate output and confirmation.
- Checks remain user-triggered to avoid background network behavior in a small,
  privacy-focused utility.

---

## Dependencies / Assumptions

- Rootie releases remain ad-hoc code-signed and unnotarized. Sparkle EdDSA
  signatures are the update authenticity boundary.
- Official releases publish a universal Sparkle-compatible archive, an appcast,
  and an EdDSA signature through GitHub Releases.
- The release workflow has access to a protected Sparkle private key; the app
  contains only the public key.
- System-managed or otherwise unwritable installations may require an
  actionable manual fallback when Sparkle cannot obtain authorization.

---

## Outstanding Questions

### Resolved During Planning

- [Affects R5] Homebrew ownership detection is unnecessary. The cask declares
  `auto_updates true`, and Sparkle replaces the stable app path used by both the
  Caskroom and command symlinks.
- [Affects R6, R7] Sparkle's updater, installer launcher, and relaunch machinery
  replace the proposed custom helper and rollback implementation.
- [Affects R3, R8] Sparkle owns appcast version selection and native release-note
  presentation. The CLI uses a custom Sparkle user driver to present equivalent
  information and outcomes in the terminal.
