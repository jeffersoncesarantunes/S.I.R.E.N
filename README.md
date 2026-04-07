# 🐧 S.I.R.E.N

Linux memory acquisition and forensic triage tool.

[![Platform-Linux](https://img.shields.io/badge/Platform-Linux-1793D1?style=flat-square&logo=linux&logoColor=white)](https://kernel.org)
[![Language-Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License-MIT](https://img.shields.io/badge/License-MIT-EE0000?style=flat-square&logo=license&logoColor=white)](LICENSE)
![Status](https://img.shields.io/badge/Status-Active-00FF41?style=flat-square)
![Tested on](https://img.shields.io/badge/Tested%20on-Arch%20Linux-1793D1?style=flat-square&logo=arch-linux)
![Domain](https://img.shields.io/badge/Domain-Digital%20Forensics-8A2BE2?style=flat-square)

---

## ● Etymology & Origin

The name **S.I.R.E.N** is a recursive acronym that reflects the tool's dual nature: an alert system and a data harvester.

In forensic mythology, the Siren calls for the truth hidden within the depths. In this context, it symbolizes the systematic notification (Entity Notifier) of memory states during runtime.

---

## ● Overview

S.I.R.E.N is a specialized forensic utility designed for controlled memory acquisition and integrity auditing.

**Core Capabilities:**
- **Low-Impact Acquisition:** Designed to minimize system interference during live memory collection
- **Post-Acquisition Processing:** Generates SHA256 hashes and extracts strings for forensic triage
- **Kernel Awareness:** Maps safe System RAM regions via /proc/iomem

---

## ● How It Works

S.I.R.E.N interfaces with the Linux Kernel through /proc/iomem, /dev/mem, and /proc/kcore.

The acquisition logic follows a structured and non-destructive path:

1. **Memory Mapping:** Parses /proc/iomem to identify valid System RAM regions  
2. **Controlled Extraction:** Uses /dev/mem for limited acquisition and /proc/kcore for full memory dumps  
3. **Post-Processing:** Generates SHA256 hashes, extracts strings, and produces forensic reports  

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

## ● Repository Structure

```text
├── docs/
├── dumps/
├── Imagens/
├── src/
│   └── siren.sh
├── LICENSE
└── README.md
```

---

## ● Troubleshooting: Kernel Restrictions

Modern Linux systems may enforce the CONFIG_STRICT_DEVMEM kernel restriction.

When enabled:

- Access to /dev/mem may be restricted or denied
- Memory extraction may return very small dumps or fail entirely

To handle this, S.I.R.E.N provides an alternative acquisition method:

- Use /proc/kcore for full memory extraction (Option 4)

This method allows access to the system’s physical memory representation even when /dev/mem is restricted.

---

## ● Tech Stack

- Language: Bash
- Data Source: /dev/mem, /proc/iomem, /proc/kcore
- Core Utilities: dd, sha256sum, strings

---

## ● Roadmap

- [x] Safe-range extraction
- [x] Controlled memory acquisition
- [x] Full memory extraction via kcore
- [x] JSON forensic reports

---

## ● Documentation

[![Docs-Acquisition](https://img.shields.io/badge/Acquisition--Model-00599C?style=flat-square&logo=linux&logoColor=white)](./docs/ACQUISITION_MODEL.md) 
[![Docs-Workflow](https://img.shields.io/badge/Forensic--Workflow-444444?style=flat-square&logo=gnu-bash&logoColor=white)](./docs/FORENSIC_WORKFLOW.md) 
[![Docs-Safety](https://img.shields.io/badge/Safety--Model-CC0000?style=flat-square&logo=opensourceinitiative&logoColor=white)](./docs/SAFETY_MODEL.md)

---

## ● License

[![License-MIT](https://img.shields.io/badge/License-MIT-EE0000?style=flat-square&logo=license&logoColor=white)](LICENSE)

*This project is licensed under the MIT License.*
