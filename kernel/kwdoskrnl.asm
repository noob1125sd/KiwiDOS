format binary as "img"
use16
org 0x7C00

jmp short initdisk
nop
 
; FAT SIGNATURE 

oem_name        db "MSWIN4.1"
bytes_per_sec   dw 512
sec_per_cluster db 1
reserved_sec    dw 1
fat_count       db 2
root_entries    dw 224
total_sectors   dw 2880
media_type      db 0xF0 
sec_per_fat     dw 9
sec_per_track   dw 18
head_count      dw 2
hidden_sectors  dd 0
large_sectors   dd 0

drive_no        db 0
nt_flags        db 0
signature       db 0x29
serial_no       dd 0x12345678
volume_label    db "MY_DOS     "
system_id       db "FAT12   "

drive db 0

initdisk:

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [drive], dl

    mov ah, 02h

    mov al, 2
    mov ch, 0
    mov cl, 2
    mov dl, [drive]
    mov bx, 0x7E00
    int 13h
    
    jc disk_error
    jmp 0:initkrnl

disk_error:
    mov ax, 0x0E21
    int 10h
    hlt
    
dsker db "Disk Error", 0
times 510-($-$$) db 0
dw 0xAA55
db ".KERNELINIT"

initkrnl:

    mov di, cmd_buffer
    mov si, main_hello
    call print
    mov si, cmd_hello
    call print

    jmp main


db ".KERNELCYCLE"

main:
    mov ah, 00h
    int 16h

    cmp al, 13
    jz newline
    cmp al, 10
    jz newline

    sub ah, 48h
    cmp ah, 8h
    jbe main


    cmp al, 8
    mov cx, 1
    jz backspace
    cmp al, 127
    mov cx, cmd_len
    jz backspace

    cmp [cmd_len], 69
    jae main
    inc [cmd_len]

    mov ah, 0Eh    
    int 10h

    stosb

    hlt
    jmp main


db ".ENTERHANDLER"


newline:
    mov [cmd_len], 0

    mov ah, 0Eh
    mov al, 13
    int 10h

    mov al, 10
    int 10h

    call cmdhandler
    call clearbuf

    mov si, cmd_hello
    call print

    jmp main


db ".BACKSPACEHANDLER"


backspace:
    cmp [cmd_len], 0 
    je main
    dec [cmd_len]

    mov di, cmd_buffer   
    add di, [cmd_len]
    mov al, 0
    mov [di], al       
    
    mov ah, 0Eh
    mov al, 8
    int 10h

    mov al, 32
    int 10h

    mov al, 8
    int 10h

    loop backspace
    xor al, al
    jmp main


print:
    lodsb
    test al, al
    jz exit
    xor bx, bx
    mov ah, 0Eh
    int 10h
    jmp print

exit:
    ret
    

clearbuf:
    xor ax, ax
    mov di, cmd_buffer  
    mov cx, 40       
    cld               
    rep stosw         
    mov di, cmd_buffer  
    ret

db ".CMDHANDLER"

cmdhandler:
    cld

    mov si, cmd_buffer
    mov di, clear
    mov cx, 4
    repe cmpsb
    je .cls
    
    mov si, cmd_buffer
    mov di, osver
    mov cx, 4
    repe cmpsb
    je .ver

    mov si, cmd_buffer
    mov di, reset
    mov cx, 6
    repe cmpsb
    je .reboot

    mov si, cmd_buffer
    mov di, shtdwn
    mov cx, 8
    repe cmpsb
    je .exit

    mov si, cmd_buffer
    mov di, help
    mov cx, 4
    repe cmpsb
    je .help

    jmp .uncmd
    ret

 .reboot:
    jmp 0FFFFh:0000h

 .exit:
    mov ax, 5301h
    xor bx, bx
    int 15h

    mov ax, 530eh
    xor bx, bx
    mov cx, 0102h
    int 15h

    mov ax, 5307h
    mov bx, 0001h
    mov cx, 0003h
    int 15h


 .cls:
    mov ax, 0600h
    mov bh, 07h
    mov cx, 0000h
    mov dx, 184Fh
    int 10h

    mov ah, 02h
    mov bh, 00h
    mov dx, 0000h  
    int 10h

    ret

 .ver:
    mov si, version
    call print
    ret
 .help:
    mov si, helpstr
    call print
    ret

 .uncmd:
    mov si, unknowncmd0
    call print
    mov si, cmd_buffer
    call print
    mov si, unknowncmd1
    call print
    mov al, 10
    int 10h
    int 10h
    mov al, 13
    int 10h
    ret


db 16 dup(0)
db ".DATA"
db 16 dup(0)

strdata:
    cmd_hello db "user@kiwi>", 0
    cmd_len dw 0
    main_hello db "HELLO FROM KiwI-DOS(TRULY MONOLITHIC DISK OPERATING SYSTEM)", 10, 13, "WRITTEN ON FASM", 10,13, "ATTENTION: THIS OS RUNNING IN REAL-MODE, DISK OPERATIONS MAY BE DANGEROUS", 10,13, "NICE TIP: THINK BEFORE EXECUTION",10,13,10,13,0
    version db 13,10,"KiwI-DOS v0.1", 13, 10, 13, 10, 0
    helpstr db 13, 10, "help - show this", 13, 10, "cls - clear console", 13, 10, "ver - view DOS version", 13, 10, "reboot - reboot PC", 13, 10, "shutdown - turn off PC", 13, 10, 13, 10, 0
    cmd_buffer db 80 dup(0)

cmds:
    unknowncmd0 db 13,10,"Unknown command: ", 0
    unknowncmd1 db 13,10, 13, 10, 'Type "help" for view command list', 0
    help db "help", 0
    clear db "cls", 0
    osver db "ver", 0
    reset db "reboot", 0
    shtdwn db "shutdown", 0

times 1536-($-$$) db 0
