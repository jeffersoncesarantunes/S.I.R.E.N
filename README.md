# S.I.R.E.N

Linux memory acquisition tool with audit-aware forensic triage.

[![Platform-Linux](https://img.shields.io/badge/Platform-Linux-1793D1?style=flat-square&logo=linux&logoColor=white)](https://kernel.org)
[![Language-Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License-MIT](https://img.shields.io/badge/License-MIT-EE0000?style=flat-square&logo=license&logoColor=white)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-00FF41?style=flat-square)](#-roadmap)
[![Tested-on](https://img.shields.io/badge/Tested%20on-Arch%20Linux-1793D1?style=flat-square&logo=arch-linux)](https://security.archlinux.org/)
[![Domain](https://img.shields.io/badge/Domain-Digital%20Forensics-8A2BE2?style=flat-square)](./docs/SAFETY_MODEL.md)

---

## Etymology & Origin

**S.I.R.E.N** stands for **S**hell **I**nteractive **R**untime **E**ntity **N**otifier. The idea is pretty straightforward - it's a runtime memory acquisition tool that actively monitors, identifies, and notifies analysts about forensic entities during live system execution. Think of it like a siren going off when memory artifacts need attention.

---

## Overview

S.I.R.E.N is a specialized forensic utility built for controlled memory acquisition and integrity validation on Linux systems.

It hooks into **LinSpec** to run what we call **audit-aware acquisitions**. The extraction strategy adapts based on detected kernel hardening levels and runtime protections it finds.

**Core Capabilities:**

* **Audit-Aware Acquisition:** Reads LinSpec reports (`report.json`) to figure out the best extraction strategy
* **Safe Memory Mapping:** Finds valid System RAM regions by parsing `/proc/iomem`
* **Adaptive Source Selection:** Automatically picks between `/dev/mem` and `/proc/kcore`
* **Integrity Validation:** Catches restricted or null-filled memory regions
* **Forensic Artifacts:** Generates SHA256 hashes, strings, and structured reports

---

## Features

* SHA256 integrity verification
* Automatic JSON forensic reports
* CSV manifest logging
* On-demand string extraction
* Pre-acquisition disk space validation
* Safe-range mapping via `/proc/iomem`
* Support for `/dev/mem` and `/proc/kcore`

---

## Example Output

```bash
# SIREN Output: Mapping System RAM
[+] Mapping Physical System RAM regions...

--> Address: 00001000-0009efff : System RAM [VALID]
--> Address: 00100000-5aaeafff : System RAM [VALID]
```

---

## How It Works

S.I.R.E.N talks to three kernel interfaces:

* `/proc/iomem`
* `/dev/mem`
* `/proc/kcore`

Here's the acquisition flow:

1. Load LinSpec audit data (`report.json`)
2. Walk through `/proc/iomem` to map valid System RAM regions
3. Pick the right source (`/dev/mem` or `/proc/kcore`)
4. Check memory integrity with NULL-byte detection
5. Dump forensic artifacts (hashes, strings, reports)

---

## Execution

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

## Investigation & Post-Acquisition Workflow

### 1. Integrity Verification

```bash
sha256sum -c dumps/*.bin.sha256
```

### 2. Manual String Analysis (Optional)

```bash
strings dumps/*.bin | grep -Ei "pass|token|config|secret" | grep -v "/usr/" | head -n 50
```

### 3. Hexadecimal Inspection

```bash
hexdump -C dumps/*.bin | head -n 20
```

### 4. Manifest Inspection

```bash
column -s, -t < dumps/manifest.csv
```

### Generated Artifacts

Each run produces:

* Raw memory dump (`.bin`)
* SHA256 checksum (`.sha256`)
* Extracted strings
* CSV manifest log

---

## Why

Memory acquisition on Linux is a pain. Kernel protections get in the way, interfaces are inconsistent, and you never quite know what you're going to get.

S.I.R.E.N tries to standardize the whole thing by combining audit-aware acquisition with adaptive extraction methods and built-in integrity validation. You point it at a box and it figures out the rest.

---

## Project in Action

![Memory Mapping](./Images/siren1.png)
*Detection of valid System RAM regions via `/proc/iomem`.*

![Pipeline Validation](./Images/siren2.png)
*Controlled extraction and validation pipeline.*

![Full Memory Extraction](./Images/siren3.png)
*Full acquisition using `/proc/kcore` with integrity verification.*

---

## Operational Integrity

S.I.R.E.N was built for live-response work where you can't afford to mess things up:

* Read-only interaction with memory interfaces
* No kernel modification
* Minimal system interference
* Automatic evidence integrity validation
* Graceful failure on restricted access

---

## Deployment

### Requirements

* Linux OS with root privileges
* Bash 4.x+

---

## Troubleshooting

### System Freeze During Extraction (/dev/mem)
**Problem:** The system hangs or locks up during acquisition.
**Cause:** Direct access to restricted hardware or reserved memory regions on modern kernels (common on Arch Linux and Fedora).
**Solution:** 
* When the kernel prompts during **Option 3**, pick **'Ignore'** to skip the restricted region. S.I.R.E.N will carry on safely.
* Or just use **Option 4 (kcore)** instead - it gives you a much more stable abstraction for live memory.

### NULL Bytes Detected
**Problem:** The kernel hands back null-filled memory regions (00 00 00...).
**Cause:** Kernel protections like `CONFIG_STRICT_DEVMEM` or EFI Lockdown mode.
**Solution:**
* Add `iomem=relaxed` to your kernel boot parameters and reboot.
* Make sure S.I.R.E.N is running with full `sudo` privileges.

### No Valid Data from /dev/mem
**Cause:** Heavy kernel restriction or missing context.
**Solution:**
* Run **LinSpec** first to generate `report.json`. S.I.R.E.N will read that audit and automatically fall back to `/proc/kcore`.

---

## Forensic Ecosystem

LinSpec -- Kernel audit and baseline
S.I.R.E.N -- Memory acquisition
K-Scanner -- Post-acquisition analysis
SYNTROPY Scripts -- Automated pipeline (orchestrate, bind, offline-scan)

---

## Repository Structure

```text
├── docs/
│   ├── acquisition_model.md
│   ├── forensic_workflow.md
│   └── safety_model.md
├── dumps/
├── Images/
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

## Tech Stack

* **Language:** Bash 4.x+
* **Data Sources:** `/dev/mem`, `/proc/iomem`, `/proc/kcore`
* **Integration:** LinSpec (audit-aware parsing)
* **Core Utilities:** `dd`, `sha256sum`, `strings`, `grep`, `od`

---

## Roadmap

* [x] Safe-range extraction logic
* [x] Controlled memory acquisition pipeline
* [x] Full memory extraction via `kcore`
* [x] JSON forensic reports with metadata
* [x] CSV manifest logging
* [x] **LinSpec Integration (Adaptive Acquisition)**
* [x] **Real-time Integrity Validation**
* [x] **K-Scanner Integration** (post-acquisition analysis via SYNTROPY scripts)

---

## Documentation

[![Docs-Acquisition](https://img.shields.io/badge/Acquisition--Model-00599C?style=flat-square\&logo=linux\&logoColor=white)](./docs/ACQUISITION_MODEL.md)
[![Docs-Workflow](https://img.shields.io/badge/Forensic--Workflow-444444?style=flat-square\&logo=gnu-bash\&logoColor=white)](./docs/FORENSIC_WORKFLOW.md)
[![Docs-Safety](https://img.shields.io/badge/Safety--Model-CC0000?style=flat-square\&logo=opensourceinitiative\&logoColor=white)](./docs/SAFETY_MODEL.md)

---

## License

[![License-MIT](https://img.shields.io/badge/License-MIT-BD93F9?style=flat-square\&logo=opensourceinitiative\&logoColor=white)](./LICENSE)

*This project is licensed under the MIT License.*
