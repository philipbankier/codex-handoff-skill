# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-10

### Added
- Progressive disclosure with `references/` subdirectory (prompt-templates, review-process, error-handling)
- `version` and `allowed-tools` fields in SKILL.md frontmatter
- OpenClaw compatibility with `openclaw.yaml` manifest
- Multi-platform install/uninstall scripts (`--platform` flag)
- `CLAUDE.md` for repo-level coding standards
- `scripts/verify-install.sh` diagnostic tool
- `resources/example-plan.md` showing expected plan format
- `CHANGELOG.md`
- `.gitignore`

### Changed
- SKILL.md restructured from monolithic (~6.3KB) to modular (~3.5KB) with reference files
- Install script now auto-detects Claude Code and OpenClaw platforms
- Command description improved for better keyword matching
- README overhauled with compatibility matrix, dual-platform docs, and troubleshooting

## [0.1.0] - 2026-03-07

### Added
- Initial release with Claude Code skill and command
- Supervisor loop for Codex CLI execution
- Symlink-based install/uninstall scripts
- MIT license
