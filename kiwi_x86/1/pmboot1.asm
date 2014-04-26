%include "common.inc"

org 07c00h
    jmp LABEL_START
    
[section .gdt]    
LABEL_GDT:      Descriptor      0, 0, 0
LABEL_DESC_CODE32:  Descriptor  0, SegCode32Len-1, DA_C + DA_32
LABEL_DESC_VIDEO:   Descriptor  0b8000h, 0ffffh, DA_DRW

GdtLen  equ     $ - LABEL_GDT
GdtPtr  dw      GdtLen-1    ;; GDT 界限
        dd      0 ;
        
; GDT 选择子        
SelectorCode32      equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO - LABEL_GDT

; end of section .gdt

[section .s16]
[BITS 16]
LABEL_START:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 07c00h
    
    ; init 32bit code descriptor
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4      ; 16 + 4 == 20   20位物理地址, 用eax 是因为 ax 就16位 装不了
    add     eax, LABEL_SEG_CODE32
    mov     word [LABEL_DESC_CODE32 + 2], ax
    shr     eax, 16
    mov     byte [LABEL_DESC_CODE32 + 4], al
    mov     byte [LABEL_DESC_CODE32 + 7], ah
    
    ; 加载 gdtr
    xor     eax, eax
    mov     ax, ds
    shl     eax, 4
    add     eax, LABEL_GDT
    mov     dword [GdtPtr + 2], eax
    
    ; load gdtr
    lgdt    [GdtPtr]
    
    ; 关中断
    cli
    
    ; open address A20
    in      al, 92h
    or      al, 00000010b
    out     92h, al

    ;;;;;;;;;;;;;;;;;;;;;
    ; get ready for protect mode
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax
    
    ;; change to protect mode
    jmp     dword SelectorCode32:0
    
; end of section .16

[section .s32]
[bits 32]

LABEL_SEG_CODE32:
    mov     ax, SelectorVideo
    mov     gs, ax
    
    mov     edi, (80 * 10 + 0) * 2
    mov     ah, 0ch
    mov     al, 'p'
    mov     [gs:edi], ax
    
    jmp     $       ; loop forever
    
SegCode32Len    equ $ - LABEL_SEG_CODE32
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节

