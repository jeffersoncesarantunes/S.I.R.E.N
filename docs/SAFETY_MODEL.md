# Safety Model

This is the set of operational safety principles S.I.R.E.N follows. Nothing here is negotiable -- the tool is designed around these constraints.

---

## 1. Read-Only Operation

S.I.R.E.N does exactly three things and nothing else:

- No writes to system memory
- No kernel modifications
- No process interference

Everything is passive. If it can't read, it doesn't try to force its way in.

---

## 2. Controlled Memory Access

Access goes through two kernel interfaces:

- `/dev/mem` -- restricted access, good for targeted reads
- `/proc/kcore` -- alternative interface when you need broader access

When we use `/dev/mem`, only valid System RAM regions get touched. Anything unsafe is left alone.

---

## 3. System Stability

Nobody wants a blue screen (or whatever the Linux equivalent is). So before we do anything:

- Memory regions get validated before access
- Disk space is checked before any acquisition starts
- Kernel restrictions are respected, not circumvented

---

## 4. User Confirmation

Some operations need you to explicitly say "yes, do it":

- Direct memory extraction
- Full memory acquisition

This keeps you in the loop and makes sure nobody accidentally dumps a production box without meaning to.

---

## 5. Failure Handling

When access gets denied, the tool doesn't fight it. It stops gracefully and moves on. No forced reads, no crashing.

---

## 6. Forensic Integrity

After acquisition, the tool locks everything down:

- SHA256 hashing so you can verify nothing changed
- Structured JSON reporting for the record
- Persistent CSV logging so you have a manifest of everything that happened

---

*Safety and evidence integrity are prioritized over completeness.*
