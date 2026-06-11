# Acquisition Model

This breaks down the internals of how S.I.R.E.N actually grabs physical memory from a live Linux system. It's worth understanding if you're trying to figure out why something worked -- or why it didn't.

---

## 1. Data Sources

S.I.R.E.N talks to three kernel interfaces. Each one serves a different purpose:

- `/proc/iomem` -- tells the tool how memory is laid out and classified
- `/dev/mem` -- gives partial raw physical memory access when you need a controlled read
- `/proc/kcore` -- the go-to for full memory acquisition

---

## 2. Memory Classification

The tool parses `/proc/iomem` to figure out which memory regions are fair game. It looks for two categories:

- System RAM -- these are safe to read
- Reserved or Hardware-mapped regions -- these get skipped

When using `/dev/mem`, only **System RAM** ranges are touched. Everything else is off limits.

---

## 3. Acquisition Modes

S.I.R.E.N gives you two strategies depending on what you're after:

### a) Controlled Extraction (`/dev/mem`)

- Grabs a limited chunk of memory with a default cap on size
- Good for safe testing and validation runs
- Kernel protections might shut this down on modern systems

### b) Full Memory Extraction (`/proc/kcore`)

- Reads memory based on total physical RAM size
- Falls back to this when `/dev/mem` won't cooperate
- Produces large-scale dumps -- make sure you have disk space

---

## 4. Acquisition Workflow

The pipeline is straightforward:

1. Read data from whichever source was selected
2. Write the raw memory out to a dump file
3. Generate a SHA256 hash so you can verify it later
4. Extract strings for quick analysis
5. Dump a JSON report and CSV manifest for your records

---

## 5. Kernel Restrictions

Modern Linux kernels don't exactly hand out memory for free. The main thing that gets in the way is `CONFIG_STRICT_DEVMEM`.

When that's enabled:

- `/dev/mem` access gets heavily restricted
- You'll probably need to switch to `/proc/kcore` for anything useful

---

## 6. Limitations

Some things you should know before relying on this in a real case:

- Root privileges are mandatory -- no way around it
- `/dev/mem` may be locked down tight depending on the kernel config
- `/proc/kcore` output includes kernel abstractions, not pure physical memory
- This is not a replacement for dedicated frameworks like LiME when you need proper forensic-grade acquisition

---

*This model prioritizes safety, traceability, and controlled acquisition.*
