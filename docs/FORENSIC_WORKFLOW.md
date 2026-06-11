# Forensic Workflow

Here's how you'd typically use S.I.R.E.N in a real investigation. The steps are pretty straightforward.

---

## 1. Acquisition Phase

Fire up S.I.R.E.N and pick the mode that fits your needs:

- `/dev/mem` -- partial, controlled extraction when you just need a slice
- `/proc/kcore` -- full memory acquisition when you want everything

Example:

    sudo ./src/siren.sh

---

## 2. Integrity Verification

Once you've got your dump, check it hasn't been mangled during extraction:

    sha256sum -c dump_filename.sha256

If the hash matches, you're good to go.

---

## 3. Artifact Extraction

The strings file S.I.R.E.N generates is your friend here:

    grep -Ei "pass|user|config" mem_dump.txt

This is where you'll find things like:

- Credentials
- Configuration data
- Indicators of compromise

---

## 4. Data Inspection

Sometimes you need to get down to the byte level:

    hexdump -C mem_dump.bin | head -n 20

This lets you spot:

- Memory patterns
- Embedded structures
- Suspicious payloads that might not show up in a text search

---

## 5. Analysis Environment

For larger dumps, don't try to do everything on the target box. Transfer the files to a dedicated forensic workstation and work from there. Keeps things clean and safe.

---

## 6. Decision Making

What you do with the findings is up to you, but the usual playbook is:

- Escalate the investigation if you find something serious
- Isolate the compromised system
- Preserve the dump as forensic evidence

---

*This workflow is designed for controlled acquisition and rapid forensic triage.*
