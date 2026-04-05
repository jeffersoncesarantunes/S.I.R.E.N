## ● Safety Model

This document defines the operational safety principles of S.I.R.E.N.

---

## 1. Read-Only Operation

S.I.R.E.N performs:

- No writes to system memory
- No kernel modifications
- No process interference

All operations are passive.

---

## 2. Controlled Memory Access

Access to `/dev/mem` is restricted to:

- Valid System RAM regions
- Verified safe offsets

This avoids:

- Hardware-mapped memory
- Kernel-critical regions

---

## 3. System Stability

To prevent system instability:

- Unsafe regions are skipped
- Non-responsive reads are avoided
- Kernel restrictions are respected

---

## 4. ACTION REQUIRED Mechanism

Certain operations require user confirmation:

- Direct memory extraction
- Potentially unsafe reads

This ensures:

- User awareness
- Explicit consent before risk

---

## 5. Failure Handling

If access is denied:

- Operation stops gracefully
- No forced reads are attempted

---

## 6. Forensic Integrity

The tool ensures:

- Real-time SHA256 hashing
- Immutable acquisition flow
- Verifiable output artifacts

---

*Safety is prioritized over completeness in all acquisition scenarios.*
