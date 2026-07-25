#!/usr/bin/env python3
import sys, json

report_path = sys.argv[1]
try:
    with open(report_path) as f:
        d = json.load(f)
    print(d.get('kptr_restrict', 1))
    print(d.get('ptrace_scope', 1))
    print(d.get('spectre_v2', 1))
    print(d.get('meltdown', 1))
    print(d.get('devmem_restrict', 1))
except Exception:
    print('1\n1\n1\n1\n1')
