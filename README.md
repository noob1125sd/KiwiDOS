# 🥝 Kiwi-DOS

A minimalist, lightweight 16-bit real-mode operating system written from scratch in Flat Assembler (FASM). 

Unlike many hobbyist operating systems that only run in emulators, Kiwi-DOS is fully compatible with **real modern hardware**. It has been successfully tested on an **AMD Ryzen 5 5600** processor running on an **ASUS Prime B550-Plus** motherboard (loaded via Compatibility Support Module / Legacy Boot).

---

## ⚡ Features

* **Bare-Metal Booting:** Runs directly on x86 hardware in 16-bit Real Mode without any underlying operating system or GRUB.
* **Robust Bootloader:** Features a custom-aligned BPB (BIOS Parameter Block) dummy structure. This prevents modern, strict UEFI/BIOS motherboards from rejecting the flash drive as "unformatted" or "corrupted".
* **Dynamic Drive Detection:** Safely preserves the boot drive index passed by the BIOS in the `DL` register, ensuring reliable read operations regardless of whether the boot medium is recognized as a floppy, HDD, or USB-HDD.
* **Secure Initialization Sequence:** Configures all critical segment registers (`CS`, `DS`, `ES`, `SS`) and sets up the stack pointer (`SP`) with interrupts disabled (`cli`/`sti`) to guarantee hardware stability on startup.
* **Shell & Command Processor:** Includes a built-in command interpreter handling cleanups, system reboots, and terminal diagnostics.

---

## 🛠️ How It Works (Boot Sequence)

1. **Stage 1 (Boot Sector):** * The BIOS loads the first 512-byte sector to physical address `0x7C00`.
   * Segment registers and stack are initialized.
   * Using `int 13h` (AH=02h), the bootloader reads the subsequent sectors (the Kernel) from the boot drive directly to `0x7E00`.
   * A far jump (`jmp 0:initkrnl`) is executed to normalize the `CS` register to `0x0000`.
  
   **Init example:**

   ```assembly 
    initdisk:

      cli ; stack init
      xor ax, ax
      mov ds, ax
      mov es, ax
      mov ss, ax
      mov sp, 0x7C00
      sti
      mov [drive], dl
      mov ah, 02h  ; drive reading
      mov al, 2
      mov ch, 0
      mov cl, 2
      mov dl, [drive]
      mov bx, 0x7E00
      int 13h
      jc disk_error
      jmp 0:initkrnl
   ```

3. **Stage 2 (Kernel):**
   * The system clears the command buffer.
   * Prints the welcome greeting and initializes the interactive command prompt (`user@kiwi>`).
   * Listens to keyboard input via BIOS `int 16h`.
  
   **Kernel-cycle example:**

   ```assembly
    mov ah, 00h
    int 16h
   
    cmp al, 13
    jz newline
    cmp al, 10
    jz newline
   
    sub ah, 48h   ; arrow blocking 
    cmp ah, 8h
    jbe main
   
    cmp al, 8
    mov cx, 1
    jz backspace
    cmp al, 127
    mov cx, cmd_len
    jz backspace

    cmp [cmd_len], 69 ; stack overflow blocking
    jae main
    inc [cmd_len]
   ```
---

## 💾 Compilation

To compile the project into a raw bootable disk image, use the Flat Assembler (FASM):

```bash
fasm kernel.asm
