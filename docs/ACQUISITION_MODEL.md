## ● Acquisition Model

This document describes the internal logic used by S.I.R.E.N to safely acquire physical memory from a live Linux system.

---

## 1. Data Sources

S.I.R.E.N relies on two kernel-exposed interfaces:

- `/proc/iomem` → memory map classification
- `/dev/mem` → raw physical memory access

---

## 2. Memory Classification

The tool parses `/proc/iomem` to identify memory regions labeled as:

- System RAM (safe for acquisition)
- Reserved / Hardware-mapped regions (unsafe)

Only **System RAM** ranges are selected for extraction.

---

## 3. Safe Range Extraction

Each valid region is processed as:

- Start address → End address
- Converted into block ranges
- Sequentially read using controlled offsets

This ensures:

- No access to restricted hardware zones
- Reduced risk of kernel-triggered faults

---

## 4. Streaming Pipeline

Instead of writing raw dumps first, S.I.R.E.N uses a pipeline:

- Memory → `dd`
- Stream → `sha256sum`
- Stream → `strings`
- Optional → `nc` (network transmission)

This allows:

- Real-time integrity validation
- Simultaneous artifact extraction
- Reduced disk footprint

---

## 5. Kernel Restrictions

Modern Linux systems may enforce:

- `CONFIG_STRICT_DEVMEM`

When enabled:

- Access is limited to first 1MB of memory
- Remaining reads return denied or zeroed data

---

## 6. Limitations

- Requires root privileges
- May be restricted by kernel hardening
- Not suitable for full forensic imaging in hardened systems

---

*This model prioritizes safety, speed, and minimal system impact.*

