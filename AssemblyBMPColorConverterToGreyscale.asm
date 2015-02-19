.8086
.model small
.stack 2048

pilha			segment	para stack  ' stack '
			byte		100  dup(0)
pilha 		ends

dados		segment 	para	public 'data'

			contador			dw				0,'$'
			buffer			db				0,'$'
			
			stringFich			db				"Insira o Nome do Ficheiro Bitmap a Converter:",13,10,"$"
			erroAbrir			db				"ERRO: Ficheiro Nao Encontrado!",13,10,'$'
			erroCriar			db				"Erro a criar o novo ficheiro!",13,10,'$'
			erroLer			db				"Erro a  ler o ficheiro!",13,10,'$'
			erroEscrever		db				"Erro a escrever no ficheiro!",13,10,'$'
			erroFechar		db				"Erro a fechar o ficheiro!!",13,10,'$'
		
			nomefich			db				10, ?, 10 dup(0),0
			nomefichBW		db				"BW",10 dup(0),0
			handle			dw				0
			novohandle		dw				0
			byte1			db				0,'$'
			byte2			db				0,'$'
			byte3			db				0,'$'
			novopixel				db				0,'$'
		
		
dados 		ends


codigo		segment	para public 'code'
			assume	cs:codigo, ds:dados, ss:pilha
			
inicio:		mov		ax, dados
			mov		ds, ax
	
			xor		si, si

menu_inicial:

			mov		ah, 09			;
   			lea   		dx, stringFich		;
   			int   		21h				; pede o nome do ficheiro a ler
   	
   			mov 		ah, 0ah			;
			lea 		dx, nomefich		;
			int 		21h				; le o nome do ficheiro
		
			xor 		ah, ah			;
			mov 		al, nomefich+1		;
			mov 		si, ax			;
			add 		si, 2				;
			mov 		nomefich[si], 0		; coloca um zero no fim da string com o nome do ficheiro
		
			xor 		ch, ch			;
			mov 		cl, nomefich+1		;
			mov		si, 2				; 
			mov		di, 2				; mete si e di com valor 2, para começar a seguir ao BW ja existente na string
			
novonome:							
			mov		al, nomefich[di]		;
			mov		nomefichBW[si], al	;
			inc 		di				;
			inc 		si				;
			loop 		novonome		; constroi o nome do novo ficheiro, adicionando 'BW' ao inicio do nome do ficheiro lido
		
			mov		ah, 3dh			;
			mov		al, 00h			;
			lea		dx, nomefich+2		;
			int		21h				; abre o ficheiro
			
			mov		handle, ax			;
			jnc		crianovo			; verifica se o ficheiro foi aberto com sucesso

			mov		ah, 09h			;
			lea		dx, erroAbrir		;
			int		21h				; mostra a mensagem de erro
			
			jmp		menu_inicial		; volta para o menu inicial
		
crianovo:
		
			mov		ah, 3ch			;
			xor		cx, cx			;
			lea		dx, nomefichBW	;
			int		21h				; cria o novo ficheiro (nova imagem)
			
			mov		novohandle, ax		;
			jnc		abrenovo			; verifica se o ficheiro foi criado com sucesso
			
			mov		ah, 09h			;			
			lea		dx, erroCriar		;
			int		21h				; mostra msg de erro de criação
			
			jmp		menu_inicial		; volta para o menu inicial
		
abrenovo:	
			mov		ah, 3dh			; 
			mov		al, 01			;
			lea		dx, nomefichBW	;
			int		21h				; abre o novo ficheiro para escrita
			
			mov		novohandle, ax		;
			jnc		modifica 			; verifica se o ficheiro foi aberto com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroAbrir		;
			int		21h				; mostra mensagem de erro
			
			jmp		menu_inicial		; volta para o menu inicial
				
		
modifica:	

	copia_head:
	
	leitura:	mov		bx, handle			;
			mov		ah, 3fh			; 
			lea		dx, buffer			;
			mov		cx,1				;
			int		21h				; lê 1 byte do ficheiro original...
			
			jnc		escreve			; verifica se o ficheiro foi lido com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroLer		;
			int		21h				; mostra mensagem de erro de leitura
			
			jmp		menu_inicial		; volta para o menu inicial
			
	escreve:	mov		bx, novohandle 		; 
			lea		dx, buffer			;
			mov		ah, 40h			;
			mov		cx,1				;
			int		21h				; escreve o byte lido no novo ficheiro
			
			jnc		incrementa		; verifica se o ficheiro foi escrito com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroEscrever	;
			int		21h				; mostra mensagem de erro de escrita
			
			jmp		menu_inicial		; volta para o menu inicial
			
incrementa:	inc		contador			;
			cmp		contador, 54		;
			je		copia_dados		; verifica se ja foram copiados todos os 54 bytes do header
				
			jmp		copia_head		; se nao, volta a ler o proximo byte do header
			
	copia_dados:						; inicio do ciclo que vai ler os pixeis de 3 em 3, alterá-los e escreve-los no ficheiro
			mov		bx, handle			;
			mov		ah, 3fh			; 
			lea		dx, byte1			;
			mov		cx, 1				;
			int		21h				; lê o 1º byte do pixel
			
			cmp 		ax, 0				; se num. de bytes lidos = 0
			je 		fechabwimg		; chegou ao fim
			
			jnc		le2;				; verifica se o ficheiro foi lido com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroLer		;
			int		21h				; mostra mensagem de erro de leitura
			
			jmp		menu_inicial		; volta para o menu inicial
				
	le2:		mov		bx, handle			;
			mov		ah, 3fh			; 
			lea		dx, byte2			;
			mov		cx, 1				;
			int		21h				; lê o 2º byte do pixel
			
			cmp 		ax, 0				; se num. de bytes lidos = 0
			je 		fechabwimg		; chegou ao fim
			
			jnc		le3				; verifica se o ficheiro foi lido com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroLer		;
			int		21h				; mostra mensagem de erro de leitura
			
			jmp		menu_inicial		; volta para o menu inicial
				
			mov		bx, handle			;
	le3:		mov		ah, 3fh			; 
			lea		dx, byte3			;
			mov		cx,1				;
			int		21h				; lê o 3º byte do pixel
			
			cmp 		ax, 0				; se num. de bytes lidos = 0
			je 		fechabwimg		; chegou ao fim
			
			jnc		med				; verifica se o ficheiro foi lido com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroLer		;
			int		21h				; mostra mensagem de erro de leitura
			
			jmp		menu_inicial		; volta para o menu inicial
				
	med:		call 		media  			; chamada do procedimento que calcula a media
				
			mov		bx, novohandle 		; 
			lea		dx, novopixel 		;
			mov		ah, 40h			;
			mov		cx, 1				;
			int		21h				; escreve o primeiro byte do pixel
			
			jnc		esc2 			; verifica se o ficheiro foi escrito com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroEscrever	;
			int		21h				; mostra mensagem de erro de escrita
			
			jmp		menu_inicial		; volta para o menu inicial
				
	esc2:	mov		bx, novohandle 		;
			lea		dx, novopixel 		; 
			mov		ah, 40h			;
			mov		cx,1				;
			int		21h				; escreve o segundo byte do pixel
			
			jnc		esc3 			; verifica se o ficheiro foi escrito com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroEscrever	;
			int		21h				; mostra mensagem de erro de escrita
			
			jmp	menu_inicial			; volta para o menu inicial
				
	esc3:	mov		bx, novohandle 		; 
			lea		dx, novopixel 		;
			mov		ah, 40h			;
			mov		cx, 1				;
			int		21h				; escreve o terceiro byte do pixel
			
			jnc		copia_dados		; verifica se o ficheiro foi escrito com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroEscrever	;
			int		21h				; mostra mensagem de erro de escrita
			
			jmp		menu_inicial		; volta para o menu inicial
	
	fechabwimg:
			mov 		bx, novohandle		;
			mov 		ah, 3eh			;
			int 		21h				; fecha a imagem convertida	
						
			jnc		fechaimg			; verifica se o ficheiro foi fechado com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroFechar		;
			int		21h				; mostra mensagem de erro de fecho
			
			jmp		menu_inicial		; volta para o menu inicial
			
	fechaimg:				
			mov 		bx, handle			;
			mov		ah, 3eh			;
			int 		21h				; fecha a imagem original
				
			jnc		fim				; verifica se o ficheiro foi fechado com sucesso
			
			mov		ah, 09h			;
			lea		dx, erroFechar		;
			int		21h				; mostra mensagem de erro de fecho
			
			jmp		menu_inicial		; volta para o menu inicial
			
fim:		
			mov		ax, 4C00h
			int 		21h				; fecha programa
			
media 	proc

			mov		ax, 0h			; mete ax a 0
			mov		bx, 0h			; mete bx a 0
			mov		dx, 0h			; mete dx a 0
			
			mov		al, byte1			; copia o primeiro byte do pixel lido para al
			mov		bl, byte2			; copia o segundo byte do pixel lido para bl
			add		ax, bx			; faz a soma dos dois primeiros bytes lidos
			mov		bl, byte3			; copia o terceiro byte do pixel lido para bl
			add		ax, bx			; soma o terceiro byte com o resultado da primeira soma
			
			mov		bl, 3h			; quociente da divisao = 3
			div		bx				; divide a soma dos 3 bytes por 3
			mov		novopixel, al		; guarda o resultado em novopixel (pixel convertido para tons de cinzento)
			
			ret
			
media 	endp

codigo		ends

end inicio