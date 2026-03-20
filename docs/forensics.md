# Forensic Methodology & Chain of Custody

This document outlines the forensic principles implemented in **S.I.R.E.N** to ensure data integrity and minimize the impact on the target system during live memory acquisition.

## 1. Minimal Footprint (Order of Volatility)
S.I.R.E.N follows the RFC 3227 guidelines regarding the order of volatility. Since RAM is the most volatile asset, our tool:
- Operates in **Pure Bash** to avoid loading external shared libraries into memory.
- Uses **Streaming Pipelines** to prevent writing large files to the local disk, which could overwrite unallocated space (potential evidence).

## 2. Integrity & Hashing
To maintain the **Chain of Custody**, S.I.R.E.N implements real-time cryptographic hashing:
- **Parallel Processing:** While data is being acquired from `/dev/mem`, it is simultaneously fed into `sha256sum` via process substitution.
- **Verification:** The resulting hash ensures that the remote dump exactly matches the source state at the time of acquisition.

## 3. Memory Mapping Logic
The tool parses `/proc/iomem` to identify "System RAM" ranges. This is critical because:
- Accessing reserved hardware memory offsets (MMIO) can cause **System Freezes** or hardware instability.
- S.I.R.E.N filters these offsets to perform a **Non-Destructive Acquisition**.

## 4. Live Acquisition Workflow
When an incident is detected, the recommended forensic workflow using S.I.R.E.N is:
1. **Network Validation:** Ensure a secure, dedicated path for data exfiltration.
2. **Pre-flight Check:** Identify kernel restrictions (e.g., `STRICT_DEVMEM`).
3. **Streaming:** Execute Option 5 to send raw data directly to a forensic workstation.
4. **Post-Analysis:** Use the generated SHA256 hash to validate the `received_dump.raw` file before starting analysis with Volatility or strings.

## 5. Potential Limitations
- **Kernel Anti-Forensics:** If a Rootkit is present, it may hook `/dev/mem` or `/proc/iomem` to hide its presence. 
- **Hardware Encryption:** Systems with active TME (Total Memory Encryption) may yield encrypted dumps if the acquisition is performed via raw offsets without kernel-level decryption keys.
