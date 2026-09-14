---
name: rootie-routing
description: Safely manage Rootie rules that open domains, subdomains, or URL paths in particular Chromium profiles. Use when a user wants a link or website routed to a personal, work, client, or other browser profile through Rootie.
license: MIT
compatibility: macOS with Rootie installed
metadata:
  author: hmbakhsh
  project: https://github.com/hmbakhsh/rootie
---

# Rootie routing

Turn the user's routing intent into a validated Rootie rule. Rootie rules are
first-match-wins, so preserve existing precedence unless the new rule would be
shadowed.

## Add a rule

1. Run `command -v rootie`, `rootie profiles`, and `rootie rules list`. If the
   `rules` command is unavailable, tell the user to upgrade Rootie rather than
   editing its JSON directly. If configuration is missing, run `rootie setup`;
   ask the user to choose from its detected browsers or profiles when needed.
2. Resolve only missing intent:
   - Use the exact profile display name returned by `rootie profiles`.
   - Convert a URL to its lowercase hostname. Never include credentials, port,
     query parameters, or fragments.
   - Add `--path-prefix` only when the user wants a path-scoped rule. It must
     begin with `/`.
   - Add `--include-subdomains` only when the user asks to include subdomains.
     An exact-host rule is the narrow default.
3. Check precedence. Normally append the new rule. If an earlier rule already
   matches the requested URL scope and routes it elsewhere, use `--position N`
   to insert immediately before that rule. Keep existing rule order unchanged.
4. Show the proposed scope, profile, and precedence position. Treat a request
   that already states all three as approval; otherwise ask one concise
   confirmation question.
5. Run:

   ```sh
   rootie rules add \
     --host HOST \
     --profile PROFILE \
     --name NAME \
     [--include-subdomains] \
     [--path-prefix /PATH] \
     [--position N]
   ```

   Quote every user-derived argument as a separate shell argument.
6. Run `rootie validate` and `rootie rules list`. Report the added rule and its
   precedence. The running app reloads configuration when it receives the next
   link.

## Scope examples

- `https://docs.example.com/a?token=x#top` becomes host `docs.example.com`.
- “All of example.com, including subdomains” becomes host `example.com` with
  `--include-subdomains`.
- “Only Acme on GitHub” becomes host `github.com` with a path such as
  `--path-prefix /acme`; confirm the organization path when it is not explicit.

Prefer the narrowest rule that satisfies the request. Never broaden a hostname
or path based only on a guess.
