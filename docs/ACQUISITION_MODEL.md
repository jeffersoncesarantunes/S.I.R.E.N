# Acquisition Model

This breaks down the internals of how S.I.R.E.N actually acquires memory from a live Linux system.

---

## 1. Data Sources

S.I.R.E.N talks to two kernel interfaces:

| Interface | Purpose | Notes |
|---|---|---|
| `/proc/iomem` | Memory layout and classification | Read-only, no restrictions |
| `/proc/kcore` | Kernel virtual address space dump | ELF format, read-only |

### /proc/kcore in detail

`/proc/kcore` exports the kernel's virtual memory layout as an ELF core dump. It contains:

- An ELF header identifying it as an ELF dump
- Program headers (`PT_LOAD` segments) describing memory regions
- The actual data for each segment

S.I.R.E.N uses a Python script (`tools/kcore_extract.py`) to:

1. Parse the ELF header (32-bit or 64-bit)
2. Enumerate all `PT_LOAD` program headers
3. Read each segment's data from the correct file offset
4. Write concatenated segment data to the output file
5. Generate a sidecar JSON with segment metadata (vaddr, offset, filesz)

### Why not /dev/mem?

`/dev/mem` access is restricted by `CONFIG_STRICT_DEVMEM` on all modern Linux kernels. S.I.R.E.N no longer offers it as an interactive option, but may attempt it as a last-resort fallback if `/proc/kcore` is unavailable.

---

## 2. What the output represents

The concatenated dump contains kernel virtual address space segments, NOT raw physical RAM. This distinction matters:

- **Suitable for:** string extraction, indicator hunting, hexdump analysis, YARA scanning, SHA256 integrity verification
- **NOT suitable for:** Volatility/Rekall analysis (these tools expect LiME or raw physical dumps)
- **For proper physical acquisition:** use [LiME](https://github.com/504ensicsLabs/LiME) or [AVML](https://github.com/microsoft/avml)

---

## 3. Acquisition Modes

### Quick Triage (`--quick`)

- Reads the first 100MB of `/proc/kcore` via `dd`
- Fast, useful for initial assessment
- Best for: rapid indicator checking, string extraction

### Full Acquisition (`--full`)

- Uses Python ELF parser to extract all readable `PT_LOAD` segments
- Produces complete kernel virtual address space dump
- Generates segment metadata (vaddr/offset/size) as `.meta.json`
- Best for: comprehensive analysis, evidence preservation

### Test Mode (`--test`)

- Reads `/proc/cpuinfo` to verify the acquisition pipeline works
- Validates read/write permissions, directory structure, disk space
- Zero risk, instant feedback

---

## 4. Acquisition Workflow

```
1. Load LinSpec audit data (report.json)
2. Select acquisition mode (quick / full / test)
3. Check available disk space
4. Extract segment data from /proc/kcore
5. Validate dump content (size > 4KB, < 99% null bytes)
6. Compute SHA256 hash
7. Extract printable strings
8. Generate JSON report + CSV manifest
9. Write operation log
```

---

## 5. Kernel Restrictions

Modern Linux kernels restrict memory access through:

- **`CONFIG_STRICT_DEVMEM`**: blocks `/dev/mem` (S.I.R.E.N doesn't depend on it)
- **`kptr_restrict`**: controls kernel pointer visibility in `/proc` files (affects audit but not acquisition)
- **`/proc/kcore` permissions**: readable by root only (S.I.R.E.N requires root)

S.I.R.E.N respects all kernel restrictions and never attempts to bypass them.

---

## 6. Limitations

- Root privileges are mandatory
- Output is kernel virtual address space, not raw physical RAM
- Not a replacement for LiME or AVML when physical RAM acquisition is required
- Strings extraction from multi-GB dumps is I/O intensive
- The Python ELF parser reads all segments sequentially; very large dumps may take time
