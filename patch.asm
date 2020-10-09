;Start of Patch.ASM 

Code    Segment Byte Public 
Assume  Cs:Code, Ds:Code 
Org     100h 

;
; California Games TSR Patch
; See problem statement here: http://www.vogons.org/viewtopic.php?t=12251
; Patch hooks INT21/25 and waits for game to try and hook INT16. It then saves 
; the game's INT16 location and doesn't really allow the hook.
; In parallel, patch hooks INT16, and if 0x10<=AH<=0x12, turns AH to 0x0/0x1/0x2 respectively,
; and calls the game's intended INT16.
;

Start: 
   mov  dx,Offset Welcome               ; Greets =) 
   call Print 

   ; INT16 hook must come before INT21 hook in this case,
   ; so that our new INT21 won't perform the "INT16 is being hooked" logic
   ; that should be executed only when the game tries to hook INT16
   
   mov  ax,3516h                        ; Get INT16 vector 
   int  21h 
   mov  word ptr Jmp16Nfo+1,bx          ; place IP of it in JMP 
   mov  word ptr Jmp16Nfo+3,es          ; place CS of it in JMP 
   mov  ax,2516h                        ; set new INT 16 
   mov  dx,offset myint16               ; pointer to new INT 16
   int  21h 
   
   mov  ax,3521h                        ; Get INT21 vector 
   int  21h 
   mov  word ptr Jmp21Nfo+1,bx          ; place IP of it in JMP 
   mov  word ptr Jmp21Nfo+3,es          ; place CS of it in JMP 
   mov  ax,2521h                        ; set new INT 21 
   mov  dx,offset myint21               ; pointer to new INT 21 
   int  21h 
   
   
   mov  dx,offset IntHooked             ; print success msg 
   call Print 
   mov  ah,31h                          ; TSR Function 
   mov  dx,40h                          ; reserve 40 paragraphs of mem 
   int  21h 

Print Proc 
   mov  ah,9 
   int  21h 
   ret 
Print EndP 

; New INT16 Procedure
myint16:

   ; Save the registers we will use
   push bx
   
   mov  bx,word ptr cs:[Thr16Nfo+1]     ; Read their IP for INT16
   cmp  bx, 0                           ; If 0, IP not set yet
   jz   restore16                       ; Just proceed with original INT 16
   
   cmp ah, 10h                          ; Only proceed for 0x10<=AH<=0x12
   jl  gotoTheirInt16
   cmp ah, 12h
   jg  gotoTheirInt16
   push cx                              ; AH -= 0x10
   xor cx, cx
   mov cl, ah
   sub cx, 10h
   mov ah, cl
   pop cx
   jmp gotoTheirInt16                   ; Call their INT16
   
gotoTheirInt16:
   pop bx                               ; Restore bx
   jmp their16                          ; Continue with their INT16 (they will IRET)
   
   ; Restore the registers used for the patch
restore16:
   pop bx
   jmp bye16                            ; Continue with original INT 16

; HERE'S THE START OF THE NEW INT21 
myint21: 
   cmp  ah,4Ch                          ; is it a terminate? 
   jnz  storetheir16                    ; if not, perhaps its a set interrupt command 

removehooks:
   push es                              ; save ES 
   push ax                              ; save AX 
   xor  di,di 
   mov  es,di                           ; set ES to 0 
   mov  di,84h                          ; 4 * 21h == 84h 
   mov  ax,word ptr cs:[Jmp21Nfo+1]       ; place IP of original INT21 in bx 
   stosw                                ; store AX at ES:DI and add 2 to DI 
   mov  ax,word ptr cs:[Jmp21Nfo+3]       ; place CS of original INT21 in bx 
   stosw                                ; store AX at ES:DI 
   
   mov  di,058h                          ; 4 * 16h == 58h 
   mov  ax,word ptr cs:[Jmp16Nfo+1]       ; place IP of original INT16 in bx 
   stosw                                ; store AX at ES:DI and add 2 to DI 
   mov  ax,word ptr cs:[Jmp16Nfo+3]       ; place CS of original INT16 in bx 
   stosw                                ; store AX at ES:DI 
   
   pop  ax                              ; restore ax 
   pop  es                              ; restore es 
   jmp  bye21                           ; jump to INT21 

storetheir16: 
   cmp  ah,25h                          ; is it a "Set Interrupt Vector" function? 
   jnz  bye21                           ; if not, goto original INT21 

   cmp al, 16h                          ; Trying to set interrupt for INT16?
   jnz  bye21                           ; if not, goto original INT21 
   
   ; Save registers that will be used
   push ds
   push bx
   
   mov bx, ds                            ; Move CS to DS, since upcoming MOVs use DS
   push cs
   pop  ds
   
   mov  word ptr Thr16Nfo+1,dx           ; place IP of their INT16 in Thr16Nfo 
   mov  word ptr Thr16Nfo+3,bx           ; place CS of their INT16 in Thr16Nfo 
   
   ; Restore used registers
   pop bx
   pop ds
   
   iret                                 ; don't actually set their hook
 

bye21: 
Jmp21Nfo  DB  0EAh,0,0,0,0 ; EA - jump far
bye16:
Jmp16Nfo  DB  0EAh,0,0,0,0 ; EA - jump far
their16:
Thr16Nfo  DB  0EAh,0,0,0,0 ; EA - jump far
Welcome   DB  13,10,'California Games TSR Patch by Gordi!',13,10,24h 
IntHooked DB  'Patch successfully installed.',13,10,24h 


Code Ends 
End Start 

; End of Patch.ASM