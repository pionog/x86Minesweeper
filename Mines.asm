use16							; 16-bitowy kod

org 7C00H						; ustawienie bootsectora w pamieci na pozycji 7C00H

setup:
	mov ax, 0003H					; ustawienie trybu graficznego. AH = 00 i AL = 03 to 16-kolorowy tryb VGA, gdzie mozna umiescic 80x25 znakow
	int 10h							; wywolanie przerwania

	; ustawianie pamieci wideo, by mozna bylo pisac na ekranie
	mov ax, 0B800H					; nie mozna bezposrednio przypisac stalej liczbowej do es, wiec trzeba najpierw do dostepnego rejestru
	mov es, ax						; ES:DI = B800:0000, gdzie DI bedzie wyzerowany w cyklu

	; ustawienie kursora na pozycji startowej
	mov ah, 0x2						; tryb ustawienia kursora
	mov dh, [currentRow]			; przypisanie do dh liczby obecnego wiersza
	mov dl, [currentColumn]			; przypisanie do dl liczby obecnej kolumny
	int 10h							; wywolanie odpowiedniego przerwania



	; glowna petla rysujaca tablice
	screen:
		mov ax, 2F20h				; AH = 20 - zielone tlo i czarny tekst AL = 0 
		xor di, di					; zerowanie di
		mov cx, 80*25				; wpisanie do rejestru licznika lacznej liczby znakow ile mozna przypisac w wybranym trybie graficznym
		rep stosw					; powtarzanie stosw tyle razy ile cx wynosi (liczba znakow w tym trybie grarficznym). objasnienie stosw nizej

		table:
			mov di, 80*2*2 + 30*2		; ustawienie pisania od drugiego wiersza z przesunieciem w prawo o 30 znakow.
										; Trzeba mnozyc oba skladniki razy dwa, bo pozycja znaku z tego co wywnioskowalem, znajduje sie na parzystych numerach w pamieci

			mov cx, 10					; ustawienie liczby powtorzen rysowania wierszy
			drawing:
				push cx					; wrzucenie na stos licznika wierszy
				; rysowanie kreski oddzielajacej kolejny wiersz
				mov ax, 2F2DH			; bialy znak na zielonym tle (2F), znak '-' (2D)
				mov cx, 21				; 21 znakow
				rep stosw				; zoptymalizowane uzycie instrukcji: mov [es:di], ax   oraz   inc di dwa razy

				; rysowanie wiersza tablicy
				mov cx, 10
				add di, (80-21)*2		; przejscie na poczatek kolejnej linii rysowanej tablicy ((szerokosc ekranu - 20 znakow) * 2)
				row:	
					mov ax, 2F7CH		; bialy znak na zielonym tle (2F), znak '|' (2D)
					stosw
					;inc di				; podwojny inc di, by przejsc dwie pozycje dalej
					;inc di
					mov ax, 2F23H		; bialy znak na zielonym tle (2F), znak '#' (23)
					stosw
					loop row
				mov ax, 2F7CH			; bialy znak na zielonym tle (2F), znak '|' (2D)
				stosw

				; przejscie do kolejnego wiersza
				add di, (80-21)*2		; przejscie na poczatek kolejnej linii rysowanej tablicy ((szerokosc ekranu - 20 znakow - 1 znak, by wyrownac) * 2)
				pop cx					; pobranie ze stosu licznika wierszy
				loop drawing

				;rysowanie ostatniego wiersza
				mov ax, 2F2DH				; bialy znak na zielonym tle (2F), znak '-' (2D)
				mov cx, 21					; 21 znakow
				rep stosw

				mov di, 80*3*2 + 31*2


		;; opoznianie czasu do nastepnego cyklu, dzieki czemu ekran nie miga zbyt czesto
		;cycle:
		;	mov bx, [046CH]				; pobranie wartosci tick od momentu uruchomienia programu
		;	inc bx
		;	inc bx
		;	inc bx
		;	delay:
		;		cmp [046CH], bx			; sprawdzanie czy minelo odpowiednio duzo zasu na odswiezenie ekranu
		;		jl delay
game:			
	move:
		
		mov dh, [currentRow]			; pobieranie obecnej wartosci wiersza
		mov dl, [currentColumn]			; pobieranie obecnej wartosci kolumny

		xor ah,ah						; zerowanie ah
		int 16h					; pobranie klawisza

		cursor:
			direction:
				cmp al, 'w' ; 'w' - up
				je up
				cmp al, 'a' ; 'a' - left
				je left
				cmp al, 's' ; 's' - down
				je down
				cmp al, 'd' ; 'd' - right
				je right
				cmp al, 0DH ; enter
				je enter
				cmp al, 20H
				je space
				jmp game

			; TODO: sprawdzanie bomby w poblizu

			; enter odslania dane pole
			enter:
				mov ax, 2F00H				; bialy znak na zielonym tle (2F), znak ' ' (00)
				mov [es:di], ax				
				jmp nofail	

			; spacja ustawia flage na danym polu
			space:
				mov ax, [es:di]			; pobierz znak z danego pola
				cmp ax, 2F00H			; jesli jest to puste pole, to nic nie rob
				je nofail
				cmp al, 0DH				; jesli to pole zawiera flage, to ja zdejmij
				je takeFlag
				; ustawienie danego pola jako oznaczonego flaga
				mov ax, 200DH			
				mov [es:di], ax
				jmp nofail
				; ponowne ustawienie "niewiadomego" pola
				takeFlag:
				mov ax, 2F23H
				mov [es:di], ax
				jmp nofail

			; pojscie w prawo
			right:
				cmp dl, 49						; sprawdzanie, czy kursor nie wykracza poza tabele z prawej strony
				je failRight
				inc byte [currentColumn]		; zwiekszenie obecnej kolumny o dwa - przesuniecie w prawo o dwa pola
				inc byte [currentColumn]
				add di, 4						; przesuniecie rysowania o dwa pola w prawo
				and byte [boundary], 00001010b	; resetowanie horyzontalnej pozycji kursora przy granicy
				jmp nofail
	
			up:
				cmp dh, 3						; sprawdzanie, czy kursor nie wykracza poza tabele z gornej strony
				je fail
				dec byte [currentRow]			; zmniejszenie obecnego wiersza o dwa - przesuniecie w gore o dwa pola
				dec byte [currentRow]
				sub di, 320						; przesuniecie rysowania w gore o dwa pola
				and byte [boundary], 00000101b	; resetowanie wertykalnej pozycji kursora przy granicy
				jmp nofail

			down:
				cmp dh, 21						; sprawdzanie, czy kursor nie wykracza poza tabele z dolnej strony
				je fail
				inc byte [currentRow]			; zwiekszenie obecnego wiersza o dwa - przesuniecie w dol o dwa pola
				inc byte [currentRow]
				add di, 320						; przesuniecie rysowania w dol o dwa pola
				and byte [boundary], 00000101b	; resetowanie wertykalnej pozycji kursora przy granicy
				jmp nofail
	
			left:
				cmp dl, 31						; sprawdzanie, czy kursor nie wykracza poza tabele z lewej strony
				je fail
				dec byte [currentColumn]		; zmniejszenie obecnej kolumny o dwa - przesuniecie w lewo o dwa pola
				dec byte [currentColumn]
				sub di, 4						; przesuniecie rysowania o dwa pola w lewo
				and byte [boundary], 00001010b	; resetowanie horyzontalnej pozycji kursora przy granicy
				jmp nofail
			

			failRight:
				or byte [boundary], 00000001b	; ustawianie, ze kursor jest przy prawej granicy tablicy
				jmp game
			failDown:
				or byte [boundary], 00000010b	; ustawianie, ze kursor jest przy dolnej granicy tablicy
				jmp game
			failLeft:
				or byte [boundary], 00000100b	; ustawianie, ze kursor jest przy lewej granicy tablicy
				jmp game
			failUp:
				or byte [boundary], 00001000b	; ustawianie, ze kursor jest przy gornej granicy tablicy
				jmp game

			nofail:
				mov ah, 0x2						; tryb ustawienia kursora
				mov dh, [currentRow]			; przypisanie do dh liczby obecnego wiersza
				mov dl, [currentColumn]			; przypisanie do dl liczby obecnej kolumny
				int 10h							; wywolanie odpowiedniego przerwania

	jmp game

currentRow db 3
currentColumn db 31
boundary db	12				; pozycja kursora wzgledem granic tablicy. jesli jest przy danej granicy, to trzeba ustawic odpowiwedni bit na 1. 00001111b 0x15
							; w kolejnosci LSB: prawo, dol, lewo, gora. w poczatkowej pozycji kursor jest w lewym gornym rogu, zatem bedzie to 00001100b czyli 0x12


times 510-($-$$) db 0			; zerowanie niewykorzystanego miejsca
dw 0AA55H						; zakonczenie pliku sygnatura 