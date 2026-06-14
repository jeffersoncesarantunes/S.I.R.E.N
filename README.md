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

**S.I.R.E.N** stands for **S**hell **I**nteractive **R**untime **E**ntity **N**otifier. It's a runtime memory acquisition tool for live forensic triage on Linux systems.

---

## Overview

S.I.R.E.N performs **audit-aware acquisitions** by reading LinSpec's `report.json` and adapting its extraction strategy based on kernel hardening levels. It supports both interactive and headless (CLI) operation.

**Core Capabilities:**

* **Audit-Aware Acquisition:** Reads LinSpec reports (`report.json`) to select the best extraction strategy
* **Safe Memory Mapping:** Parses `/proc/iomem` for valid System RAM regions
* **Adaptive Source Selection:** Prefers `/proc/kcore` with ELF-aware extraction (falls back to dd if needed)
* **Content Validation:** Post-dump entropy sampling and size verification
* **Forensic Artifacts:** SHA256 hashes, strings, JSON reports, CSV manifest, ELF segment metadata

---

## Features

* ELF-aware `/proc/kcore` extraction via Python (PT_LOAD segments)
* SHA256 integrity verification
* JSON forensic reports with audit parameters
* CSV manifest logging
* On-demand string extraction
* Pre-acquisition disk space validation
* Safe-range mapping via `/proc/iomem`
* Interactive menu and non-interactive CLI (`--quick`, `--full`, `--test`)
* Persistent operation log for chain of custody

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

S.I.R.E.N talks to two kernel interfaces:

* `/proc/iomem` -- memory layout classification
* `/proc/kcore` -- ELF-format kernel virtual address space

Here's the acquisition flow:

1. Load LinSpec audit data (`report.json`) via Python3
2. Walk through `/proc/iomem` to map valid System RAM regions
3. For `/proc/kcore`: parse ELF headers and extract readable PT_LOAD segments
4. Validate dump content (non-null sample, minimum size)
5. Generate forensic artifacts (hashes, strings, JSON, CSV, segment metadata)

### Important note on /proc/kcore

`/proc/kcore` exports the **kernel virtual address space** as an ELF core dump, not raw physical RAM. The extracted dump is suitable for:
- String extraction and indicator hunting
- SHA256 integrity verification
- Hexdump and binary inspection
- YARA scanning

For **physical RAM acquisition** suitable for Volatility and other forensic frameworks, use dedicated tools like [LiME](https://github.com/504ensicsLabs/LiME) or [AVML](https://github.com/microsoft/avml).

---

## Execution

### Interactive mode

```bash
sudo ./src/siren.sh
```

### Non-interactive (CLI) mode

```bash
# Quick triage: first 100MB of /proc/kcore
sudo ./src/siren.sh --quick

# Full acquisition: ELF-aware extraction
sudo ./src/siren.sh --full

# Test acquisition pipeline
sudo ./src/siren.sh --test

# Display System RAM map
sudo ./src/siren.sh --map

# Custom output directory
sudo ./src/siren.sh --full --output /evidence/case-001/
```

---

## Investigation & Post-Acquisition Workflow

### 1. Integrity Verification

```bash
sha256sum -c dumps/checksums/*.sha256
```

### 2. Manual String Analysis (Optional)

```bash
strings dumps/binaries/*.bin | grep -Ei "pass|token|config|secret" | grep -v "/usr/" | head -n 50
```

### 3. Hexadecimal Inspection

```bash
hexdump -C dumps/binaries/*.bin | head -n 20
```

### 4. Segment Metadata

```bash
cat dumps/binaries/*.meta.json
```

### 5. Manifest Inspection

```bash
column -s, -t < dumps/reports/manifest.csv
```

### Generated Artifacts

Each run produces:

* Raw memory dump (`.bin`)
* ELF segment metadata (`.meta.json`, when using Python extraction)
* SHA256 checksum (`.sha256`)
* Extracted strings (`.txt`)
* JSON forensic report
* CSV manifest log
* Persistent operation log (`siren.log`)

---

## Why

Memory acquisition on Linux is a pain. Kernel protections get in the way, interfaces are inconsistent, and you never quite know what you're going to get.

S.I.R.E.N standardizes the process by combining audit-aware acquisition with adaptive extraction methods and built-in integrity validation.

**What S.I.R.E.N is NOT:**
- It is NOT a replacement for LiME, AVML, or other dedicated physical memory acquisition frameworks
- The dumps produced are kernel virtual address space, NOT raw physical RAM
- Not intended for court-admissible forensic acquisition without additional tooling

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
* Python 3.x (recommended; falls back gracefully)
* `dd`, `sha256sum`, `strings`, `stat`

---

## Repository Structure

```text
├── docs/
│   ├── ACQUISITION_MODEL.md
│   ├── FORENSIC_WORKFLOW.md
│   └── SAFETY_MODEL.md
├── dumps/
├── Images/
├── lib/
│   ├── audit.sh          # LinSpec JSON parsing
│   ├── acquisition.sh    # kcore ELF + dd acquisition
│   ├── reporting.sh      # JSON/CSV/hash/strings
│   └── safety.sh         # storage check, validation, logging
├── src/
│   └── siren.sh          # Entry point
├── tools/
│   └── kcore_extract.py  # Python ELF segment extractor
├── .gitignore
├── LICENSE
└── README.md
```

---

## Tech Stack

* **Language:** Bash 4.x+ / Python 3.x (ELF parsing)
* **Data Sources:** `/proc/iomem`, `/proc/kcore`
* **Integration:** LinSpec (audit-aware parsing)
* **Core Utilities:** `dd`, `sha256sum`, `strings`, `python3`

---

## Roadmap

* [x] Safe-range extraction logic
* [x] ELF-aware /proc/kcore extraction (PT_LOAD segments)
* [x] JSON forensic reports with audit parameters
* [x] CSV manifest logging
* [x] LinSpec Integration (Adaptive Acquisition)
* [x] Content validation (entropy sampling, magic bytes)
* [x] Non-interactive CLI mode (`--quick`, `--full`, `--test`)
* [x] Persistent operation logging
* [ ] LiME integration as optional backend
* [ ] Automated Volatility profile matching
* [ ] Remote acquisition over SSH tunnel

---

## Documentation

[![Docs-Acquisition](https://img.shields.io/badge/Acquisition--Model-00599C?style=flat-square\&logo=linux\&logoColor=white)](./docs/ACQUISITION_MODEL.md)
[![Docs-Workflow](https://img.shields.io/badge/Forensic--Workflow-444444?style=flat-square\&logo=gnu-bash\&logoColor=white)](./docs/FORENSIC_WORKFLOW.md)
[![Docs-Safety](https://img.shields.io/badge/Safety--Model-CC0000?style=flat-square\&logo=opensourceinitiative\&logoColor=white)](./docs/SAFETY_MODEL.md)

---

## License

[![License-MIT](https://img.shields.io/badge/License-MIT-BD93F9?style=flat-square\&logo=opensourceinitiative\&logoColor=white)](./LICENSE)

*This project is licensed under the MIT License.*
