#!/usr/bin/env python3
import json, os, struct, sys

ELFCLASS32 = 1
ELFCLASS64 = 2
PT_LOAD = 1

def read_ehdr(f):
    magic = f.read(4)
    if magic != b'\x7fELF':
        return None, None
    f.seek(4)
    elf_class = struct.unpack('B', f.read(1))[0]
    if elf_class == ELFCLASS64:
        f.seek(32)
        e_phoff = struct.unpack('<Q', f.read(8))[0]
        f.seek(54)
        e_phentsize = struct.unpack('<H', f.read(2))[0]
        e_phnum = struct.unpack('<H', f.read(2))[0]
    elif elf_class == ELFCLASS32:
        f.seek(28)
        e_phoff = struct.unpack('<I', f.read(4))[0]
        f.seek(42)
        e_phentsize = struct.unpack('<H', f.read(2))[0]
        e_phnum = struct.unpack('<H', f.read(2))[0]
    else:
        return None, None
    return (elf_class, e_phoff, e_phentsize, e_phnum)

def read_phdr64(f, offset):
    f.seek(offset)
    data = f.read(56)
    p_type = struct.unpack('<I', data[0:4])[0]
    p_offset = struct.unpack('<Q', data[8:16])[0]
    p_vaddr = struct.unpack('<Q', data[16:24])[0]
    p_filesz = struct.unpack('<Q', data[32:40])[0]
    p_memsz = struct.unpack('<Q', data[40:48])[0]
    return (p_type, p_offset, p_vaddr, p_filesz, p_memsz)

def read_phdr32(f, offset):
    f.seek(offset)
    data = f.read(32)
    p_type = struct.unpack('<I', data[0:4])[0]
    p_offset = struct.unpack('<I', data[4:8])[0]
    p_vaddr = struct.unpack('<I', data[8:12])[0]
    p_filesz = struct.unpack('<I', data[16:20])[0]
    p_memsz = struct.unpack('<I', data[20:24])[0]
    return (p_type, p_offset, p_vaddr, p_filesz, p_memsz)

def extract_kcore(output_path):
    kcore_path = '/proc/kcore'
    if not os.path.exists(kcore_path):
        print(f'Error: {kcore_path} not found', file=sys.stderr)
        return False

    with open(kcore_path, 'rb') as f:
        ehdr = read_ehdr(f)
        if ehdr[0] is None:
            print('Error: Not a valid ELF file', file=sys.stderr)
            return False

        elf_class, e_phoff, e_phentsize, e_phnum = ehdr
        if elf_class == ELFCLASS64:
            read_phdr = read_phdr64
        else:
            read_phdr = read_phdr32

        segments = []
        for i in range(e_phnum):
            phdr = read_phdr(f, e_phoff + i * e_phentsize)
            p_type, p_offset, p_vaddr, p_filesz, p_memsz = phdr
            if p_type != PT_LOAD or p_filesz == 0:
                continue
            segments.append({
                'vaddr': hex(p_vaddr),
                'offset': p_offset,
                'filesz': p_filesz,
                'memsz': p_memsz,
            })

        if not segments:
            print('Error: No PT_LOAD segments found in kcore', file=sys.stderr)
            return False

        with open(output_path, 'wb') as out:
            for seg in segments:
                f.seek(seg['offset'])
                data = f.read(seg['filesz'])
                out.write(data)

        total = sum(s['filesz'] for s in segments)
        meta_path = output_path + '.meta.json'
        with open(meta_path, 'w') as mf:
            json.dump({
                'source': kcore_path,
                'segments': segments,
                'total_bytes': total,
            }, mf, indent=2)

        print(f'Extracted {len(segments)} segments, {total} bytes')
        return True

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f'Usage: {sys.argv[0]} <output_path>', file=sys.stderr)
        sys.exit(1)
    sys.exit(0 if extract_kcore(sys.argv[1]) else 1)
