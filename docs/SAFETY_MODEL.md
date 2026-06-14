# Safety Model

This is the set of operational safety principles S.I.R.E.N follows.

---

## 1. Read-Only Operation

S.I.R.E.N does exactly three things and nothing else:

- No writes to system memory
- No kernel modifications
- No process interference

Everything is passive. If it can't read, it doesn't try to force its way in.

---

## 2. Controlled Memory Access

Access goes through a single kernel interface:

- `/proc/kcore` -- read-only ELF core dump interface

When `/proc/kcore` is unavailable, the tool reports the error gracefully. No alternative interface is probed without the user's knowledge.

---

## 3. System Stability

Nobody wants a system crash during incident response. So before acquisition:

- Disk space is checked and the user is warned if RAM exceeds available storage
- Content is validated after dump (entropy sampling catches null-filled reads)
- Kernel restrictions are respected, not circumvented

---

## 4. User Confirmation

Full memory acquisition explicitly asks for confirmation if disk space is insufficient. Quick triage (100MB) skips the prompt since the risk is minimal.

---

## 5. Failure Handling

When access gets denied or a segment is unreadable:

- The tool stops gracefully and reports what failed
- No forced reads, no crashing
- Partial results are preserved with a warning

---

## 6. Forensic Integrity

After acquisition, the tool locks everything down:

- SHA256 hashing for integrity verification
- Structured JSON reporting with audit parameters
- Persistent CSV manifest
- Operation log with ISO-8601 timestamps for chain of custody

---

*Safety and evidence integrity are prioritized over completeness.*
