# 🐧 S.I.R.E.N

Linux memory acquisition and forensic triage tool.

[![Platform-Linux](https://img.shields.io/badge/Platform-Linux-1793D1?style=flat-square&logo=linux&logoColor=white)](https://kernel.org)
[![Language-Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License-MIT](https://img.shields.io/badge/License-MIT-EE0000?style=flat-square&logo=license&logoColor=white)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-00FF41?style=flat-square)](#-roadmap)
[![Tested-on](https://img.shields.io/badge/Tested%20on-Arch%20Linux-1793D1?style=flat-square&logo=arch-linux)](https://security.archlinux.org/)
[![Domain](https://img.shields.io/badge/Domain-Digital%20Forensics-8A2BE2?style=flat-square)](./docs/SAFETY_MODEL.md)

---

## ● Etymology & Origin

The name **S.I.R.E.N** is a recursive acronym that reflects the tool's dual nature: an alert system and a data harvester.

**S**hell **I**nteractive **R**untime **E**ntity **N**otifier

In a low-level forensic context, **S.I.R.E.N** targets the extraction of raw data from volatile memory layers. It symbolizes the systematic notification of memory states and the acquisition of critical evidence during system runtime.

---

## ● Overview

S.I.R.E.N is a specialized forensic utility designed for controlled memory acquisition and integrity auditing.

**Core Capabilities:**
- **Adaptive Forensics:** Integrates with **LinSpec** to perform audit-aware acquisitions based on system hardening.
- **Low-Impact Acquisition:** Designed to minimize system interference during live memory collection.
- **Post-Acquisition Processing:** Generates SHA256 hashes and performs real-time integrity validation.
- **Kernel Awareness:** Maps safe System RAM regions via `/proc/iomem` and detects kernel protection levels.

---

## ● How It Works

S.I.R.E.N interfaces with the Linux Kernel through `/proc/iomem`, `/dev/mem`, and `/proc/kcore`. 

The acquisition logic now follows an **Audit-Aware** path:

1. **Audit Synchronization:** Automatically detects and parses LinSpec reports (`report.json`) to adjust acquisition methods based on kernel vulnerability status (e.g., `kptr_restrict`).
2. **Memory Mapping:** Parses `/proc/iomem` to identify valid System RAM regions and alerts if sensitive pointers are leaking.
3. **Controlled Extraction:** Selects between `/dev/mem` or `/proc/kcore` automatically based on the audit results to ensure the highest data resolution.
4. **Integrity Validation:** Performs real-time NULL-byte detection to verify if the kernel is providing legitimate data or restricted null-filled pages (protection bypass check).
5. **Post-Processing:** Generates SHA256 hashes, extracts strings, and produces detailed forensic JSON/CSV reports.

---

## ● Example Output

```bash
# SIREN Output: Mapping System RAM
[+] Mapping Physical System RAM regions...

--> Address: 00001000-0009efff : System RAM [VALID]
--> Address: 00100000-5aaeafff : System RAM [VALID]
```

---

## ● Project in Action

![Memory Mapping](./Imagens/siren1.png)  
*1 - Detection of safe System RAM regions using /proc/iomem.*

![Pipeline Validation](./Imagens/siren2.png)  
*2 - Pipeline validation using controlled data extraction and report generation.*

![Full Memory Extraction](./Imagens/siren3.png)  
*3 - Full memory acquisition using /proc/kcore with integrity verification.*

---

## ● Features

- SHA256 integrity verification
- Automatic JSON forensic reports
- CSV manifest logging
- On-demand string extraction
- Pre-acquisition disk space validation
- Safe-range mapping via /proc/iomem
- Support for /dev/mem and /proc/kcore

---

## ● Operational Integrity

S.I.R.E.N is designed for forensic stability:

- Read-only interaction with memory interfaces  
- No kernel modification  
- Minimal system interference  
- Structured evidence generation  
- Graceful failure on restricted access  

---

## ● Execution

```bash
# 1. Clone the repository
git clone https://github.com/jeffersoncesarantunes/S.I.R.E.N.git

# 2. Enter the directory
cd S.I.R.E.N

# 3. Grant execution permissions
chmod +x src/siren.sh

# 4. Run with root privileges
sudo ./src/siren.sh
```

---

## ● Investigation Workflow

### 1. Integrity Verification

```bash
sha256sum -c dumps/*.bin.sha256
```

### 2. Optional String Extraction (On-Demand)

```bash
strings dumps/*.bin | grep -Ei "pass|token|config|secret" | grep -v "/usr/" | head -n 50
```

### 3. Hexadecimal Inspection

```bash
hexdump -C dumps/*.bin | head -n 20
```

#### 4. Audit Log Inspection

```bash
column -s, -t < dumps/manifest.csv
```

---

## ● Deployment

### Requirements

- Linux OS with root privileges
- Bash 4.x+

---

## ● Repository Structure

```text
├── docs/
│   ├── acquisition_model.md
│   ├── forensic_workflow.md
│   └── safety_model.md
├── dumps/
├── Imagens/
│   ├── siren1.png
│   ├── siren2.png
│   └── siren3.png
├── src/
│   └── siren.sh
├── .gitignore
├── LICENSE
└── README.md
```

---

## ● Troubleshooting: Kernel Restrictions

Modern Linux systems may enforce strict memory protections like `CONFIG_STRICT_DEVMEM` or `Kernel Lockdown`.

### ⚠️ ACTION REQUIRED: NULL Bytes Detected
If S.I.R.E.N reports **`[!] WARNING: Kernel is returning NULL bytes`**, your dump contains no usable data because the kernel is blocking access to physical memory.

**To resolve this and obtain a valid forensic dump:**

1. **Reboot and Modify Kernel Parameters:** 
   - Access your GRUB configuration during boot.
   - Add **`iomem=relaxed`** to the kernel parameters line.
   - This allows the tool to read memory ranges usually locked by the OS.

2. **Bypass System Freezing:**
   - If the system hangs during extraction, use **Option 3 (Ignore)** in the S.I.R.E.N menu. 
   - This bypasses restricted hardware regions that cause the system to freeze when accessed directly.

3. **Method Fallback:**
   - Always check the S.I.R.E.N header for `[Audit Loaded]`. If `/dev/mem` is failing, ensure LinSpec has been executed to allow S.I.R.E.N to attempt a fallback to `/proc/kcore`.

---

## ● Tech Stack

- **Language:** Bash 4.x+
- **Data Source:** `/dev/mem`, `/proc/iomem`, `/proc/kcore`
- **Integration:** **LinSpec** (Audit-Aware JSON parsing)
- **Core Utilities:** `dd`, `sha256sum`, `strings`, `grep`, `od`

---

## ● Roadmap

- [x] Safe-range extraction logic
- [x] Controlled memory acquisition pipeline
- [x] Full memory extraction via `kcore`
- [x] JSON forensic reports with metadata
- [x] CSV manifest logging for evidence tracking
- [x] **LinSpec Symbiosis (Adaptive Forensic Logic)**
- [x] **Real-time Integrity NULL-check validation**
- [ ] K-Scanner Integration (Post-acquisition automated analysis)

---

## ● Documentation

[![Docs-Acquisition](https://img.shields.io/badge/Acquisition--Model-00599C?style=flat-square&logo=linux&logoColor=white)](./docs/ACQUISITION_MODEL.md) 
[![Docs-Workflow](https://img.shields.io/badge/Forensic--Workflow-444444?style=flat-square&logo=gnu-bash&logoColor=white)](./docs/FORENSIC_WORKFLOW.md) 
[![Docs-Safety](https://img.shields.io/badge/Safety--Model-CC0000?style=flat-square&logo=opensourceinitiative&logoColor=white)](./docs/SAFETY_MODEL.md)

---

## ● License

[![License-MIT](https://img.shields.io/badge/License-MIT-BD93F9?style=flat-square&logo=opensourceinitiative&logoColor=white)](./LICENSE)

*This project is licensed under the MIT License.*
