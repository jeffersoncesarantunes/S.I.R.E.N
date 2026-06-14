# Forensic Workflow

Here's how you'd typically use S.I.R.E.N in a real investigation.

---

## 1. Acquisition Phase

Fire up S.I.R.E.N and pick the mode that fits your needs:

**Quick Triage (Option 3 / `--quick`):**
First 100MB of `/proc/kcore`. Fast, for initial assessment.

**Full Acquisition (Option 4 / `--full`):**
Complete ELF-aware extraction of `/proc/kcore`. For comprehensive analysis.

Example:

```bash
# Interactive
sudo ./src/siren.sh

# Headless full acquisition
sudo ./src/siren.sh --full --output /evidence/case-001/
```

---

## 2. Integrity Verification

Once you've got your dump, check it hasn't been mangled during extraction:

```bash
sha256sum -c dumps/checksums/*.sha256
```

If the hash matches, you're good to go.

---

## 3. Segment Inspection

Check the ELF segment metadata to understand what was extracted:

```bash
cat dumps/binaries/*.meta.json
```

This shows each segment's virtual address, file offset, and size.

---

## 4. Artifact Extraction

The strings file S.I.R.E.N generates is your friend here:

```bash
grep -Ei "pass|user|config|token|secret" dumps/binaries/*.txt
```

This is where you'll find:

- Credentials and secrets
- Configuration data
- Indicators of compromise (C2 URLs, IPs, domain names)
- Command history

---

## 5. Data Inspection

Sometimes you need to get down to the byte level:

```bash
hexdump -C dumps/binaries/*.bin | head -n 20
```

This lets you spot:

- Memory patterns
- Embedded structures
- Suspicious payloads that might not show up in a text search

---

## 6. Analysis Environment

For larger dumps, don't try to do everything on the target box. Transfer the files to a dedicated forensic workstation and work from there.

```bash
# Copy artifacts off the target
scp -r dumps/ analyst@workstation:/cases/incident-001/
```

---

## 7. Third-Party Analysis

The raw `.bin` dump can be fed into other tools:

```bash
# YARA scanning (if rules file available)
yara -s /path/to/rules.yara dumps/binaries/*.bin

# Bulk extractor for automatic indicator extraction
bulk_extractor -o ./bulk_output/ dumps/binaries/*.bin
```

---

## 8. Decision Making

What you do with the findings is up to you, but the usual playbook is:

- Escalate the investigation if you find something serious
- Isolate the compromised system
- For proper physical RAM acquisition, use LiME or AVML
- Preserve the dump as forensic evidence

---

## Important Caveats

- S.I.R.E.N dumps kernel virtual address space, NOT raw physical RAM
- The dump is NOT compatible with Volatility or Rekall
- For court-admissible forensic acquisition, use dedicated hardware write-blockers and validated tools
- S.I.R.E.N is a triage tool, not a replacement for a full forensic toolkit
