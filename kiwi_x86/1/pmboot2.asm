%include "common.inc"

org 07c00h
    jmp LABEL_START
    
[section .gdt]    
LABEL_GDT:      Descriptor      0, 0, 0
LABEL_DESC_NORMAL:  Descriptor 0, 0ffffh, DA_DRW
LABEL_DESC_CODE32:  Descriptor  0, SegCode32Len-1, DA_C + DA_32
LABEL_DESC_CODE16:  Descriptor 0, 0ffffh, DA_C
LABEL_DESC_DATA:    Descriptor 0, DataLen - 1, DA_DRW
LABEL_DESC_TEST:    Descriptor 0500000h, 0ffffh, DA_DRW
LABEL_DESC_STACK:   Descriptor 0, TopOfStack, DA_DRWA + DA_32
LABEL_DESC_VIDEO:   Descriptor  0b8000h, 0ffffh, DA_DRW

GdtLen  equ     $ - LABEL_GDT
GdtPtr  dw      GdtLen-1    ;; GDT 界限
        dd      0 ;
        
; GDT 选择子        
SelectorCode32      equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO - LABEL_GDT
SelectorNormal      equ     LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode16      equ     LABEL_DESC_CODE16 - LABEL_GDT
SelectorTest        equ     LABEL_DESC_TEST - LABEL_GDT
SelectorData        equ     LABEL_DESC_DATA - LABEL_GDT
SelectorStack       equ     LABEL_DESC_STACK - LABEL_GDT


; end of section .gdt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[section .data1]
ALIGN 32
[bits 32]
LABEL_DATA:
SPValueInRealMode   dw   0
; 字符串
PMMessage:		db	"In Protect Mode now. ^-^", 0	; 进入保护模式后显示此字符串
OffsetPMMessage		equ	PMMessage - $$
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest - $$
DataLen			equ	$ - LABEL_DATA

;;; global stack
[section .gs]
ALIGN   32
[BITS 32]
LABEL_STACK:
    times 20   db 0
    
TopOfStack  equ $-LABEL_STACK-1    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


[section .s16]
[BITS 16]
LABEL_START:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 07c00h
    
    
    ;;
    
    ;; 不过我不打算回到实模式， 暂不打算
    
    
    ;;
    
    
    ; init 32bit code descriptor
    xor     eax, eax
    mov     ax, cs
    shl     eax, 4      ; 16 + 4 == 20   20位物理地址, 用eax 是因为 ax 就16位 装不了
    add     eax, LABEL_SEG_CODE32
    mov     word [LABEL_DESC_CODE32 + 2], ax
    shr     eax, 16
    mov     byte [LABEL_DESC_CODE32 + 4], al
    mov     byte [LABEL_DESC_CODE32 + 7], ah
    
    ; init data descriptor
    xor     eax, eax
    mov     ax, ds
    shl     eax, 4
    add     eax, LABEL_DATA
    mov     word [LABEL_DESC_DATA + 2], ax
    shr     eax, 16
    mov     byte [LABEL_DESC_DATA + 4], al
    mov     byte [LABEL_DESC_DATA + 7], ah
   
    
    
    ; init stack descriptor
    xor     eax, eax
    mov     ax, ds
    shl     eax, 4
    add     eax, LABEL_STACK
    mov     word [LABEL_DESC_STACK + 2], ax
    shr     eax, 16
    mov     byte [LABEL_DESC_STACK + 4], al
    mov     byte [LABEL_DESC_STACK + 7], ah
    
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
    mov     ax, SelectorData
    mov     ds, ax
    mov     ax, SelectorTest
    mov     es, ax
    
    ;; for stack
    mov     ax, SelectorStack
    mov     ss, ax
    mov     esp, TopOfStack
    
    ; display a string
    mov     ah, 0ch
    xor     esi, esi
    xor     edi, edi
    mov     esi, OffsetPMMessage
    mov     edi, (80*10 + 0) * 2
    cld
    
.1:
    lodsb
    test    al, al
    jz      .2
    mov     [gs:edi], ax
    add     edi, 2
    jmp     .1
.2: ; display over    
    
    jmp     $       ; loop forever
    
SegCode32Len    equ $ - LABEL_SEG_CODE32
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节

