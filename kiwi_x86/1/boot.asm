org 07c00h

    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    call    DisplayStr
    jmp     $;  loop forever

DisplayStr:
    mov     ax, String
    mov     bp, ax;     es:bp
    mov     cx, 16
    mov     ax, 01301h
    mov     bx, 000ch
    mov     dl, 0
    int     10h
    ret
    
String: db  "Hello, OS world!"
times   510-($-$$)  db 0
dw  0xaa55;     to make it a bootable
        
; 　　ES:BP = 串地址
; 　　CX = 串长度
; 　　DH， DL = 起始行列
; 　　BH = 页号
; 　　AL = 0，BL = 属性
; 　　串：Char，char，……，char
; 　　AL = 1，BL = 属性
; 　　串：Char，char，……，char
; 　　AL = 2
; 　　串：Char，attr，……，char，attr
; 　　AL = 3
; 　　串：Char，attr，……，char，attr        