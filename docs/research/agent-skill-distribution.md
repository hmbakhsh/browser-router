# Agent skill packaging and distribution

_Research current as of 14 September 2026. Primary/official sources only._

## Executive recommendation for Rootie

Keep one portable Agent Skill in this repository:

```text
rootie/
└── skills/
    └── rootie-routing/
        ├── SKILL.md
        └── references/          # optional; config schema/examples
```

`skills/<name>/SKILL.md` is both a conventional collection layout and a location the Vercel `skills` CLI searches. It avoids tying the skill itself to Claude Code, OpenCode, or Codex. Document this as the primary installation command:

```sh
npx skills add hmbakhsh/rootie --skill rootie-routing -g
```

The CLI detects installed agents and can install globally into their respective discovery locations. A deterministic alternative is:

```sh
npx skills add hmbakhsh/rootie --skill rootie-routing -g \
  -a claude-code -a opencode -a codex
```

This is the best initial distribution path because the [open Agent Skills specification](https://agentskills.io/specification) standardizes the artifact but not installation, while Vercel's open-source [`skills` CLI](https://github.com/vercel-labs/skills) supplies the missing multi-agent installer. [skills.sh](https://skills.sh/docs) is a directory/leaderboard around that installer, not the governing skill specification or a required package registry. Public GitHub skills [appear automatically after CLI installs produce telemetry](https://skills.sh/docs/faq#how-do-i-get-my-skill-listed-on-the-leaderboard); there is no separate publishing step.

Do not start by maintaining three copies under `.claude/`, `.opencode/`, and `.agents/`. If avoiding an `npx` prerequisite matters to Rootie's non-Node audience, add a later native `rootie skill install [--agent ...]` command which installs the exact same bundled skill directory into each host's documented global location. That would be a Rootie convenience installer, not a new format.

Claude Code and Codex marketplaces/plugins are useful optional second-stage channels if marketplace-native discovery becomes important. They add host-specific manifests and release mechanics, not portability to the core `SKILL.md`.

## 1. The interoperable standard: Agent Skills

Agent Skills is an open format originally developed by Anthropic and now maintained openly in [`agentskills/agentskills`](https://github.com/agentskills/agentskills). It standardizes a **directory**, not a package registry:

```text
skill-name/
├── SKILL.md          # required
├── scripts/          # optional executables
├── references/       # optional documentation
├── assets/           # optional templates/resources
└── ...
```

Per the [format specification](https://agentskills.io/specification):

- `SKILL.md` is Markdown with YAML frontmatter.
- `name` and `description` are required. The lowercase kebab-case `name` must match the parent directory; limits are 64 and 1,024 characters respectively.
- `license`, `compatibility`, and string-valued `metadata` are portable optional fields.
- `allowed-tools` exists but is experimental and client support varies.
- Supporting files are referenced with paths relative to the skill root. `scripts/`, `references/`, and `assets/` are conventions rather than required names.
- Agents are expected to use progressive disclosure: initially load metadata, load the body on activation, then read resources only as needed.
- `skills-ref validate ./path/to/skill` is the specification's reference validator.

The standard deliberately does **not** define a universal install command, global filesystem path, registry, marketplace, update protocol, permission model, or vendor-specific invocation controls. Those belong to clients and distributors. A repository collection commonly uses `skills/<skill-name>/SKILL.md`; an agent's own zero-install project discovery path may instead be `.agents/skills`, `.claude/skills`, or `.opencode/skills`.

## 2. skills.sh and Vercel's `skills` CLI

Vercel announced [`skills` and skills.sh](https://vercel.com/changelog/introducing-skills-the-open-agent-skills-ecosystem) in January 2026:

- **`skills` CLI**: open-source installer/manager for standard skill directories.
- **skills.sh**: discovery directory and install leaderboard.

The [official CLI repository](https://github.com/vercel-labs/skills#install-a-skill) supports GitHub shorthand, full Git/GitLab URLs, direct repository subdirectories, local paths, direct `SKILL.md` downloads, and archives. Relevant commands include:

```sh
npx skills add owner/repo
npx skills add owner/repo --list
npx skills add owner/repo --skill some-skill -g
npx skills add owner/repo -a claude-code -a opencode -a codex
npx skills list
npx skills find routing
npx skills update
npx skills remove some-skill
```

Project install is the default; `-g` installs for the user. Interactive installs normally put one canonical copy in place and symlink agent-specific locations to it; `--copy` requests copies. The CLI searches common collection locations including repository-root `skills/`, `.agents/skills/`, `.claude/skills/`, and `.opencode/skills/`. Its current support table includes Claude Code, OpenCode, and Codex.

Important distinctions and caveats:

- The CLI is a distributor, not part of the Agent Skills standard.
- skills.sh is not required to install a Git-hosted skill. `npx skills add hmbakhsh/rootie` can resolve the GitHub repository directly.
- The [skills.sh FAQ](https://skills.sh/docs/faq) says leaderboard listing is telemetry-driven. Installation telemetry can be disabled with `DISABLE_TELEMETRY=1` or `DO_NOT_TRACK=1`; users should review third-party skill contents before install.
- It requires a Node/npm environment (`npx`), which Rootie's Homebrew macOS audience may not otherwise have.

## 3. Claude Code distribution

Claude Code follows the open standard for skill content and adds vendor-specific frontmatter and behavior. Its [skills documentation](https://code.claude.com/docs/en/skills#where-skills-live) discovers standalone skills at:

| Scope | Location |
|---|---|
| Project | `.claude/skills/<name>/SKILL.md` |
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` |

Committing `.claude/skills` gives zero-install availability only while Claude works in that repository. That does not fit Rootie's main use case well: the routing skill modifies a user-level config and should be available from any working directory, so a global install is preferable.

For formal distribution, Claude Code's unit is a **plugin**. A plugin has `.claude-plugin/plugin.json` and puts skills at plugin-root `skills/<name>/SKILL.md`. Plugin skills are namespaced (for example `/rootie:rootie-routing`). Anthropic's [plugin guide](https://code.claude.com/docs/en/plugins#when-to-use-plugins-vs-standalone-configuration) recommends standalone `.claude` content for project/personal workflows and plugins for sharing, versioning, and reusable cross-project installation.

A **Claude plugin marketplace** is a catalog in `.claude-plugin/marketplace.json`, hosted in Git or another supported source. Users add the catalog and install its entry:

```text
/plugin marketplace add hmbakhsh/rootie
/plugin install rootie@rootie-plugins
```

The [marketplace documentation](https://code.claude.com/docs/en/plugin-marketplaces#overview) describes centralized discovery, version tracking, and updates, and supports plugin sources including GitHub/Git, git subdirectories, npm, and HTTPS archives. This is Claude-specific distribution layered around standard skills. Anthropic also documents a reviewed [`claude-community` marketplace submission route](https://code.claude.com/docs/en/plugins#submit-your-plugin-to-the-community-marketplace), while `claude-plugins-official` remains curated by Anthropic.

For Rootie, a Claude marketplace is optional. The generic `skills` CLI already installs the portable skill into `~/.claude/skills`; add a Claude plugin only if native `/plugin` discovery, namespaced invocation, or Claude-managed updates justify another manifest and release surface.

## 4. OpenCode V2

OpenCode V2 has first-party support for both native and compatibility locations. Its [V2 skills documentation](https://opencode.ai/v2/docs/skills/#discovery) searches:

| Scope | Locations |
|---|---|
| Project | `.opencode/skills`, plus `.claude/skills` and `.agents/skills` |
| Global | `~/.config/opencode/skills`, plus `~/.claude/skills` and `~/.agents/skills` |

OpenCode walks project locations from the current directory to the project root. It supports directory skills ending in `SKILL.md` and flat Markdown skills, but the directory form is the portable choice. File path determines the case-sensitive skill ID; frontmatter `name` is a display label. V2 accepts portability fields but does not enforce every Agent Skills naming/length rule, so validate against the stricter open spec.

OpenCode also has a documented distribution mechanism independent of filesystem copying: the `skills` array in `opencode.json(c)` can add local directories or an **HTTP catalog**. A catalog exposes `<base>/index.json` with skill names, versions, and file lists; OpenCode downloads same-origin files and refreshes cache when `version` changes. This is an OpenCode-specific catalog protocol, not the interoperable Agent Skills standard and not a general registry.

There is no official OpenCode marketplace/install command for standalone skills in the V2 page. For Rootie, either let Vercel's CLI install globally into OpenCode's path or, only if needed, host an OpenCode HTTP catalog and ask users to add its URL to `opencode.json`.

## 5. OpenAI Codex

Codex officially builds on the open Agent Skills standard. The [Codex skill guide](https://developers.openai.com/codex/skills) discovers local skills from:

| Scope | Location |
|---|---|
| Repository | `.agents/skills` from the current directory through repository root |
| User | `~/.agents/skills` |
| Admin | `/etc/codex/skills` |
| System | Skills bundled with Codex |

Codex supports explicit invocation (`$skill-name`) and description-based implicit invocation. It also provides `$skill-installer` for curated skills and for downloading skills from other repositories, but the official guidance positions that as local setup/experimentation.

For reusable distribution, OpenAI now recommends **plugins**. The [official plugin packaging guide](https://developers.openai.com/plugins/build/plugins) describes a portable Agent Plugins package with root `plugin.json` and standard skills in `skills/`; public plugins can be submitted to the universal plugin directory shared by ChatGPT and Codex. Local/repository catalogs live at `.agents/plugins/marketplace.json`, and `codex plugin marketplace add owner/repo` registers Git-backed catalogs. This plugin/package standard is broader than Agent Skills and remains a separate distribution layer.

For Rootie, the generic global install is simpler than an OpenAI plugin because no MCP connector or ChatGPT presentation layer is required. A plugin becomes attractive only if Rootie wants listing in OpenAI's install UI.

## 6. Rootie skill design and safety

The skill's job is unusually sensitive: it edits `~/.rootie/config.json`, which controls which browser identity receives a URL. Rootie's own documentation states that [rules are first-match-wins and invalid JSON stops routing](../../README.md#json-configuration). The checked-in [example configuration](../../config.example.json) defines the current schema.

The implemented skill remains instruction-first but delegates mutation to
Rootie's typed CLI instead of editing JSON itself:

1. Confirm Rootie and the `rules` command exist. Initialize missing configuration only through `rootie setup`.
2. Resolve destination profiles through `rootie profiles` and inspect first-match-wins precedence through `rootie rules list`.
3. Translate URLs into a strict lowercase hostname, optional subdomain matching, and an optional leading-slash path; never pass credentials, query strings, or fragments.
4. Preserve existing rule order. Supply `--position` only when an earlier broader rule would otherwise shadow the new rule.
5. Apply the rule through `rootie rules add`, whose typed configuration path validates before an atomic write.
6. Verify with `rootie validate` and `rootie rules list`. Rootie reloads configuration on its next incoming link.

The portable frontmatter should use only standard fields, for example:

```yaml
---
name: rootie-routing
description: Safely add and validate routing rules in ~/.rootie/config.json. Use when a user wants a domain, subdomain, or URL path to open in a particular Chromium profile through Rootie.
license: MIT
compatibility: macOS with Rootie installed
metadata:
  author: hmbakhsh
---
```

Avoid relying on Claude-only fields such as `disable-model-invocation` or `context: fork` in the canonical skill. Do not use `allowed-tools` as a safety boundary: the standard marks it experimental and implementations differ. Put confirmation, backup, atomic replacement, validation, and rollback requirements directly in the instructions.

Rootie now implements the stronger native interface: `rootie rules add` owns
normalization, profile lookup, validation, precedence insertion, and atomic
persistence. The skill gathers intent and invokes that deterministic command;
it explicitly declines to improvise direct JSON mutations when the installed
Rootie version lacks the command.

## Decision summary

| Layer | What it standardizes | Rootie choice |
|---|---|---|
| Agent Skills | Portable `SKILL.md` directory and metadata | **Adopt**; canonical `skills/rootie-routing/` |
| Vercel `skills` CLI | Cross-agent Git/local install, update, removal | **Primary installer**: `npx skills add hmbakhsh/rootie --skill rootie-routing -g` |
| skills.sh | Discovery/leaderboard built from installer activity | Allow automatic listing; not a publishing dependency |
| Claude plugin marketplace | Claude-specific package catalog and updates | Optional later channel |
| OpenCode HTTP catalog | OpenCode-specific remote discovery/cache | Unnecessary initially |
| Codex/OpenAI plugins | Codex/ChatGPT installable package and public directory | Optional later channel |
| Native `rootie rules` CLI | Safe, typed configuration mutation | **Adopted**; the skill delegates writes to it |
| Native `rootie skill install` | No-Node convenience installer | Consider later for Homebrew users; install the same standard artifact |
