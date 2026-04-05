## ● Forensic Workflow

This document outlines the recommended workflow when using S.I.R.E.N in a forensic investigation.

---

## 1. Acquisition Phase

Run S.I.R.E.N and select the desired mode:

- Local memory acquisition
- Remote streaming (recommended for large dumps)

Example:

    sudo ./src/siren.sh

---

## 2. Integrity Verification

After acquisition, verify data integrity:

    sha256sum -c dump_filename.sha256

This ensures the dump was not corrupted during extraction or transfer.

---

## 3. Artifact Extraction

Use the generated strings file:

    grep -Ei "pass|user|config" mem_strings.txt

This helps identify:

- Credentials
- Configuration data
- Indicators of compromise

---

## 4. Data Inspection

Perform low-level inspection:

    hexdump -C mem_dump.bin | head -n 20

This allows identification of:

- Memory patterns
- Embedded structures
- Suspicious payloads

---

## 5. Remote Analysis

If using streaming:

- Validate hash on receiver side
- Analyze dump on isolated forensic workstation

---

## 6. Decision Making

Based on findings:

- Escalate investigation
- Isolate compromised system
- Preserve dump as forensic evidence

---

*This workflow is designed for rapid triage and incident response scenarios.*
