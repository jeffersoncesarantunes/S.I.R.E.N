#!/usr/bin/env python3
import json, sys, os

data = json.loads(sys.stdin.read())

report = {
    'timestamp': data.get('timestamp', ''),
    'hostname': data.get('hostname', ''),
    'kernel': data.get('kernel', ''),
    'method': data.get('method', ''),
    'audit_aware': data.get('audit_aware', False),
    'audit_params': {
        'kptr_restrict': int(data.get('audit_kptr', 1)),
        'ptrace_scope': int(data.get('audit_ptrace', 1)),
        'spectre_v2': int(data.get('audit_spectre', 1)),
        'meltdown': int(data.get('audit_meltdown', 1)),
    },
    'evidence': {
        'file': data.get('file', ''),
        'size_bytes': int(data.get('size', '0')),
        'sha256': data.get('hash', ''),
    },
    'volatility': {
        'profile': data.get('vol_profile', ''),
        'platform': data.get('vol_platform', ''),
        'version': int(data.get('vol_major', '0')),
    }
}

json.dump(report, sys.stdout, indent=2)
