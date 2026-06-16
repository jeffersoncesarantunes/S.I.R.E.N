# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | ✅       |

## Reporting a Vulnerability

This is a Linux memory acquisition tool for digital forensics. If you discover a security vulnerability, please do NOT open a public issue.

Contact the maintainer directly at jefferson.antunes@gmail.com with details about the issue.

We commit to acknowledging receipt within 48 hours and providing a fix timeline within 7 days.

## Security Features

- `set -euo pipefail` for fail-fast execution
- `umask 077` for restrictive file permissions
- Trap handler for clean interrupt handling
- Input validation on memory addresses (hex regex)
- No use of eval/exec in shell scripts
- All forensic artifacts are gitignored

## Known Limitations

- Requires root privileges for /proc/kcore access
- Tool runs with elevated privileges by design
