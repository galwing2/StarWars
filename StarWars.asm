IDEAL
MODEL small
STACK 100h
DATASEG
note dw 1809h
sqy dw ?
sqx dw 146
sqcolor dw 4
sqwidth dw 10
sqlength dw 10
randomx dw 20 dup(0)
randomy dw 20 dup(0)
squares_color dw 11
random_width dw 17
random_length dw 17
check dw 0 ;used to check the top row of character
lvl dw 0 ;where on y axis the first row is
lvl2 dw 0 ;where on y axis the second row is
falling_wait dw 7000 
num_of_sq dw 0
check1 dw 0 ;checks if setup of second row has happened so it can be skipped later
allign_row dw 0 ;where on x axis the left square starts
msg db "Game Over"
sq_wait dw 4000
restart db "Press enter to restart"
exitgame db "Press space to exit"
rounds db 2 dup(?) 
rounds_count db 01
divider db 10
msg2 db "Round"
CODESEG	
proc game_setup
	push bp
	mov bp,sp
	call round_count
	;לאפס את מערך הריבועים הרנדמליים
	mov cx,20
	xor di,di
dlt1:
	mov [randomx+di],0
	mov [randomy+di],0
	add di,2
	loop dlt1
	xor di,di
	mov [sq_wait],4000
	mov [check],0
	mov [check1],0
	mov [lvl],0
	mov [lvl2],0
	mov [allign_row],0
	; להגריל צבע לריבועים
	mov ax,40h
	mov es,ax
	mov ax,[es:6ch]
	and ax,15
	mov [squares_color],ax
	cmp [squares_color],0
	jnz continue6
	inc [squares_color]
continue6:
	;להגריל מספר ריבועים רנדומליים
	xor ax,ax
	mov ax,40h
	mov es,ax
	mov ax,[es:6ch]
	xor ah,ah
	and ax,5
	mov [num_of_sq],ax
	inc [num_of_sq]
	cmp [num_of_sq],5
	jl boo
	mov ax,40h
	mov es,ax
	mov ax,[es:6ch]
	and ax,64
	add ax,20
	mov [allign_row],ax
	jmp continue
boo:
	mov ax,40h
	mov es,ax
	mov ax,[es:6ch]
	and ax,127
	add ax,90
	mov [allign_row],ax
continue:
	xor ax,ax
	xor di,di
	mov ax,40h
	mov es,ax
	mov ax,[es:6ch]
	and ax,63
	mov [randomx],ax
	; לבנות את הריבועים הרנדומליים
	mov cx,[num_of_sq]
new_sq:
	push [random_width]
	push [random_length]
	push [squares_color]
	push [randomx+di]
	push [randomy+di]
	call square
	mov ax,[randomx+di]
	add di,2
	add [randomx+di],ax
	add [randomx+di],40 ;squares width + 2*character width
	loop new_sq
	xor di,di
	pop bp
	ret
endp game_setup


proc screen_sq_setup
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	;set squares falling speed
	mov [falling_wait],6000
	;print black on whole screen
	push 320
	push 200
	push 0
	push 0
	push 0
	call square
	;Making the initial character
	mov [sqx],146
	mov ax,200
	sub ax,[sqlength]
	mov [sqy],ax
	push [sqwidth]
	push [sqlength]
	push [sqcolor]
	push [sqx]
	push [sqy]
	call square
	xor ah,ah
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
endp screen_sq_setup

proc round_count
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	mov al,[rounds_count]
	xor ah,ah
	div [divider]
	mov [rounds],al ;תוצאה
	mov [rounds+1],ah ; שארית
	add [rounds],'0'
	add [rounds+1],'0'
	mov si,@data
	mov ah,13h
	xor al,al ;sub-service 0 all the characters will be in the same color
	xor bh,bh
	mov bl,00001111b ;left side is background and right side is color
	mov cx,5
	mov dh,10 ;row
	mov dl,16 ;column
	mov es,si
	mov bp,offset msg2
	int 10h
	mov si,@data
	mov ah,13h
	xor al,al
	xor bh,bh
	mov bl,00001111b
	mov cx,1
	mov dh,10 ; row
	mov dl,22 ; column
	mov es,si
	mov bp,offset rounds
	int 10h
	mov si,@data
	mov ah,13h
	xor al,al
	xor bh,bh
	mov bl,00001111b
	mov cx,1
	mov dh,10 ;row
	mov dl,23 ;column
	mov es,si
	mov bp,offset rounds
	inc bp
	int 10h
	mov cx,100
waitagain:
	push 16000
	call delay
	loop waitagain
	;delete the rounds message
	mov cx,50
	mov dx,50
	mov al,0
	xor bx,bx
column15:
line15:
	mov ah,0ch
	int 10h
	inc cx
	cmp cx,270
	jnz line15
	mov cx,50
	inc dx
	cmp dx,150
	jnz column15
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
endp round_count
	
proc delay
	push bp
	mov bp,sp
	push cx
	mov cx,[bp+4]
delay1:
	nop
	loop delay1
	pop cx
	pop bp
	ret 2
endp delay

proc delete_square
	push bp
	mov bp,sp
	push ax
	push cx
	push dx
	push bx
	push di
	mov cx,[bp+6] ;x coordinate
	mov dx,[bp+4] ; ycoordinate
	add [bp+10],cx ;square width
	add [bp+8],dx ;square height
	mov al,00h
	xor bh,bh
delete_column3:
delete_row3:
	mov ah,0ch
	int 10h
	inc cx
	cmp cx,[bp+10] ;square width
	jnz delete_row3
	mov cx,[bp+6] ;x coordinate
	inc dx
	cmp dx,[bp+8] ;y coordinate
	jnz delete_column3
	sub [bp+8],dx ;square height
	sub [bp+10],cx ;square width
	pop di
	add di,2
	pop bx
	pop dx
	pop cx
	pop ax
	pop bp
	ret 8
endp delete_square

proc input
	push bp
	mov bp,sp
	push bx
	in al,60h
	cmp al,04dh ;right arrow key
	jz right
	cmp al,04bh ;left arrow key
	jnz endproc
	call mov_left
	jmp endproc
right:
	call mov_right
endproc:
	pop bx
	pop bp
	ret
endp input

proc square
	push bp
	mov bp,sp
	push cx
	push dx
	push ax
	push bx
	mov cx,[bp+6] ;x coordinate
	mov dx,[bp+4] ;y coordinate
	mov ax,[bp+8] ; square color
	add [bp+10],dx ;square height
	inc [word ptr bp+10] ;square height
	add [bp+12],cx ;square width
	xor bh,bh
column:
line:
	mov ah,0ch
	int 10h
	inc cx
	cmp cx,[bp+12] ;;square width
	jnz line
	mov cx,[bp+6] ;x coordinate
	inc dx
	cmp dx,[bp+10] ;square height
	jnz column
	sub [bp+10],dx ; square height
	dec [word ptr bp+10] ;square height
	sub [bp+12],cx ;square width
end32:
	pop bx
	pop ax
	pop dx
	pop cx
	pop bp
	ret 10
endp square

proc mov_right
	push bx
	push cx
	push dx
	push ax
	push [sq_wait]
	call delay
	mov cx,[sqx]
	mov dx,[sqy]
	add cx,[sqwidth]
	inc cx
	cmp cx,321
	jae end1
	sub cx,[sqwidth]
	dec cx
	mov al,0
	xor bh,bh
delete_column:
	mov ah,0ch
	int 10h
	inc dx
	cmp dx,201
	jnz delete_column
	inc [sqx]
	add cx,[sqwidth]
	mov dx,[sqy]
	xor ah,ah
	mov ax,[sqcolor]
print_column:
	mov ah,0ch
	int 10h
	inc dx
	cmp dx,201
	jnz print_column
	jmp end2
end1:
	mov [sqx],320
	mov ax,[sqwidth]
	sub [sqx],ax
end2:
	pop ax
	pop dx
	pop cx
	pop bx
	ret 
endp mov_right

proc mov_left
	push cx
	push dx
	push ax
	push bx
	push [sq_wait]
	call delay
	mov cx,[sqx]
	mov dx,[sqy]
	xor al,al
	xor bh,bh
	dec cx
	cmp cx,0
	jnge skip1
	;inc cx
	mov cx,[sqx]
	add cx,[sqwidth]
	dec cx
delete_column1:
	mov ah,0ch
	int 10h
	inc dx
	cmp dx,201
	jnz delete_column1
	sub cx,[sqwidth]
	xor ah,ah
	mov ax,[sqcolor]
	mov dx,[sqy]
print_column1:
	mov ah,0ch
	int 10h
	inc dx
	cmp dx,201
	jnz print_column1
	dec [sqx]
	jmp skip2
skip1:
	mov [sqx],0
skip2:
	pop bx
	pop ax
	pop dx
	pop cx
	ret 
endp mov_left

proc falling
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	call game_over?
	push [falling_wait]
	call delay
	mov cx,[bp+6] ;x coordinate
	mov dx,[bp+4] ;y coordinate
	add [bp+12],cx ;square width
	mov al,00h
	xor bh,bh
delete_row:
	mov ah,0ch
	int 10h
	inc cx
	cmp cx,[bp+12] ;square width
	jnz delete_row
	mov cx,[bp+6] ; x coordinate
	add dx,[bp+10] ;square height
	cmp dx,201
	jz end45
	mov ax,[bp+8] ; square color
print_row:
	mov ah,0ch
	int 10h
	inc cx
	cmp cx,[bp+12] ;square width
	jnz print_row
	sub [bp+12],cx ;square width
	inc [randomy+di]
end45:
	call game_over?
	pop dx
	pop cx
	pop ax
	pop bx
	pop bp
	ret 10
endp falling

proc game_over?
	push cx
	push dx
	push ax
	push bx
	mov cx,[sqx]
	add cx,[sqwidth]
	mov [check],cx
	sub cx,[sqwidth]
    mov dx,[sqy]
game:
	xor bh,bh
	mov ah,0Dh
	int 10h
	xor ah,ah
	cmp ax,[sqcolor]
	jnz end111
	inc cx
	cmp cx,[check]
	jnz game
	jmp end11
end111:
	mov bx,3
sound:
	; open speaker
	in al, 61h
	or al, 00000011b
	out 61h, al
	; send control word to change frequency
	mov al, 0B6h
	out 43h, al
	; play frequency 131Hz
	mov ax, [note]
	out 42h, al ; Sending lower byte
	mov al, ah
	out 42h, al ; Sending upper byte
	mov cx,10
soundloop2:
	push cx
	xor cx,cx
soundloop:
	mov cx,cx
	loop soundloop
	pop cx
	loop soundloop2
	; close the speaker
	in al, 61h
	and al, 11111100b
	out 61h, al
	push 16400
	call delay
	push 16400
	call delay
	dec bx
	jnz sound
	mov [rounds_count],01
	push 220
	push 100
	push 15
	push 50
	push 50
	call square
	mov si,@data ;moves to si the location in memory of the data segment
	mov ah,13h ;service to print string in graphic mode
	xor al,al ;sub-service 0 all the characters will be in the same color
	mov bl,00001110b ;left side is background and right side is color
	mov cx,9 ;length of string
	mov dh,8 ;row
	mov dl,15 ;column
	mov es,si ;moves to es the location in memory of the data segment
	mov bp,offset msg ;mov bp the offset of the string
	int 10h
	mov bl,00001101b ;left side is background and right side is color
	mov cx,22 ;length of string
	mov dl,9 ;column
	mov dh,15 ;row
	mov bp,offset restart ;mov bp the offset of the string
	int 10h
	mov dh,17 ;row
	mov cx,19 ;length of string
	mov bp,offset exitgame ;mov bp the offset of the string
	int 10h
waitmore:
	xor ah,ah
	int 16h
	cmp al,20h
	jz exit1
	cmp al,0Dh
	jnz waitmore
	jmp start
	jmp end11
exit1:
	jmp exit
end11:
	pop bx
	pop ax
	pop dx
	pop cx
	ret 
endp game_over?


start:
	Mov ax , @data
	Mov ds , ax
	;graphic mode
	mov ax,13h
	int 10h
	call screen_sq_setup
big_game:
	call game_setup
game1:
	call input
	;falling square sequence
	mov cx,[num_of_sq]
falling_sequence:
	push [random_width]
	push [random_length]
	push [squares_color]
	push [randomx+di]
	push [randomy+di]
	call falling
	call input
	call game_over?
	add di,2
	loop falling_sequence
	inc [lvl] ;indicates where on y axis the first row is
	xor di,di
	call input
	call game_over? ;check if the game ended
	cmp [lvl],90 ; check if new row should start falling
	je new_game ;new row of squares
	; check if delete square sequence should start
	cmp [lvl],200
	jz dlt
	; check if setup of second row should be skipped so setup doesn't happen everytime
	cmp [check1],1
	jae new_game3
	;check if firsrt row has reached bottom
	cmp [lvl],200
	jnz game1
	;delete first row of squares sequence
dlt:
	xor di,di
	mov cx,[num_of_sq]
delete_squares:
	push [random_width]
	push [random_length]
	push [randomx+di]
	push [randomy+di]
	call delete_square
	loop delete_squares
	add [falling_wait],1250 ;slows down the falling squares speed
	jmp new_game3 
go_up2:
	jmp big_game
new_game:
	inc [check1] ;indicates that setup of second row has occurred
	;skips the part in the sq array of the first row
	mov di,[num_of_sq]
	add di,[num_of_sq]
	mov cx,[num_of_sq] 
	;alligns the row of squares
	mov ax,[allign_row]
	mov [randomx+di],ax
	;builds the second row of squares
	new_game2:
	push [random_width]
	push [random_length]
	push [squares_color]
	push [randomx+di]
	push [randomy+di]
	call square
	mov ax,[randomx+di]
	add di,2
	add [randomx+di],ax
	add [randomx+di],40; רוחב הריבוע שנופל ועוד פעמיים רוחב הדמות
	loop new_game2
	sub [falling_wait],1250
	;second row of squares falling sequence
new_game3:
	mov di,[num_of_sq]
	add di,[num_of_sq]
	mov cx,[num_of_sq]
falling_sequence2:
	push [random_width]
	push [random_length]
	push [squares_color]
	push [randomx+di]
	push [randomy+di]
	call falling
	call game_over?
	call input
	add di,2
	loop falling_sequence2
	inc [lvl2] ; indicates where on y axis the second row is
	cmp [lvl2],200
	jz end34567 ;second row has reached the bottom
	xor di,di
	jmp game1
	jmp end34567
go_up:
	jmp go_up2 ;***
	;delete second row of squares sequence
end34567:
	mov di,[num_of_sq]
	add di,[num_of_sq]
	mov cx,[num_of_sq]
delete_squares3:
	push [random_width]
	push [random_length]
	push [randomx+di]
	push [randomy+di]
	call delete_square
	loop delete_squares3
	
	cmp [falling_wait],2000 ;checks if falling speed has reached max speed
	jz skip
	sub [falling_wait],250 ;increases falling speed
skip:
	inc [rounds_count] 
	jmp go_up ; *** = jumps in order to reach the beginning of the game
exit:
	;back to text mode
	mov ax,02h
	int 10h
	
	mov ax, 4c00h
	int 21h
END start












