#!/usr/bin/env python3
import sys, os

file_path = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('PY_PATH', '')
if not file_path:
    print('FAIL: no path provided')
    sys.exit(1)

with open(file_path, 'rb') as f:
    sample = f.read(4096)
    non_zero = sum(1 for b in sample if b != 0)
    ratio = non_zero / len(sample)
    if ratio < 0.01:
        print('FAIL: dump is >99% null bytes (acquisition returned no data)')
        sys.exit(1)
    print(f'OK: {non_zero}/4096 non-null bytes ({ratio*100:.1f}%)')
