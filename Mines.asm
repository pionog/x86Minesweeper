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


		mines:
			push bx
			mov cx, 3		; ustawianie licznika petli na 3, beda generowane trzy miny
			generate:
				push cx			; zapisz na stosie stan licznika, bo cx bedzie uzyty przy generowaniu wspolrzednych
				mov dx, [046CH]				; pobranie wartosci tick od momentu uruchomienia programu
				inc dx						; zwiekszanie tickow trzy razy
				inc dx
				inc dx
				delay:
					cmp [046CH], dx			; sprawdzanie czy minelo odpowiednio duzo zasu na wpuszczenie do kolejnego etapu generowania
					jl delay

				mov ax, dx		; przeniesienie mlodszej czesci liczby z cx:dx
				; jako ze ax to 16 bitow, to od razu mozna uzyskac z niej wspolrzedna x i y, ktore mozna spokojnie zapisac na 8 bitach. mozna sie pokusic o zapisywanie obu wspolrzednych w jednej liczbie 8-bitowej, bo liczba 10 miesci sie na czterech bitach
				xor ah, ah		; zerowanie starszej czesci ax 
				mov cl, 8		; ustawienie dzielnika na 8 (plansza min jest 8x8, objasnienie na samym dole w sekcji "Optymalizacja"), by moc uzyskac liczbe modulo 8 w kolejnych krokach
				div cl			; dzielenie al przez 8, w ah bedzie liczba modulo 8
				shl ah, 1		; mnozenie razy dwa wspolrzednej x
				add ah, 31		; dopasowanie do tabelki poprzez dodanie pierwszej mozliwej kolumny
				mov bl, ah		; wrzucanie do rejestru bl wspolrzednej x
				mov ax, dx		; ponowne wpisanie liczby tickow zegara z dx do ax
				shr ah, 8		; zerowanie ah, tym razem w taki sposob, aby jej czesc znalazla sie w al
				div cl
				shl ah, 1		; mnozenie razy dwa wspolrzednej y
				add ah, 3		; dopasowanie wspolrzednej do tabelki poprzez dodanie pierwszego wiersza tablicy
				mov bh, ah		; wspolrzedna y do rejsetru bh
				pop cx			; przywracanie licznika petli
				push bx			; wpisanie wspolrzednych danej miny na stoie	
				loop generate
			pop bx				; pobierz pierwsza mine ze stosu
			mov [mine1X], bl	; przypisanie wspolrzednej x
			mov [mine1Y], bh	; przypisanie wspolrzednej y
			pop bx				; druga mina ze stosu
			mov [mine2X], bl
			mov [mine2Y], bh
			pop bx				; trzecia mina ze stosu
			mov [mine3X], bl
			mov [mine3Y], bh
			pop bx


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
				;cmp al, 'x' ;
				;je debugX
				;cmp al, 'c'
				;je debugC
				cmp al, 'v'
				je debugV
				cmp al, 0DH ; enter
				je enter
				cmp al, 20H
				je space
				jmp game


			; enter odslania dane pole
			enter:
				; zachowanie stanu bx

				; wrzucanie na stos poszczegolnych wspolrzednych min

				; mina pierwsza
				mov ax, [mine1Y]
				push ax
				mov ax, [mine1X]
				push ax

				; mina druga
				mov ax, [mine2Y]
				push ax
				mov ax, [mine2X]
				push ax

																										
				; mina trzecia
																										;mov ax, 9					;DEBUG
																										;mov [mine3Y], ax			;DEBUG
				mov ax, [mine3Y]
				push ax
																										;mov ax, 35					;DEBUG
																										;mov [mine3X], ax			;DEBUG
				mov ax, [mine3X]
				push ax

				; zerowanie cx, ktory bedzie licznikiem petli
				xor cx, cx
				; zmniejszanie cx do -1, by obieg petli mozna bylo zaczac od 0
				dec cx

				singleFieldLookUpDyn:
					xor ax, ax								; zerowanie reejstru ax, ktory posluzy za licznik wystapien min wokol danego pola
					mov [mineBool], ax
						horizontalDyn:
							inc cx							; nalezy juz za wczasu zwiekszyc licznik petli, gdyz jesli w trakcie sprawdzania warunkow wyjdzie, ze wspolrzedna x nie miesci sie w danym przedziale, to nie zwiekszyloby inaczej indeksu
							cmp cx, 3						; jesli petla wykonuje sie poraz 4, to znaczy, ze wspolrzedna x jakiejkolwiek miny nie miescila sie w przedziale <-1;1> wzgledem przeszukiwanego pola
							je verticalDynStart
						
							; w tym miejscu powinno wystapic adresowanie indeksowane ([sp+4cx]) lecz nie jest to mozliwe w 16 bitach, dlatego wystepuje tutaj obejscie
							mov si, cx						; do czystego bx dodac cx
							shl si, 2						; przesuniecie w lewo trzy razy powoduje pomnozenie 8 razy
							add si, sp						; dodanie sp, dzieki czemu jest sp+4cx

							
							mov dl, [currentColumn]			; przypisanie danej kolumny
							sub dl, 2						; zmniejszanie kolumny o jedna kolumne w tablicy - sprawdzanie poczatku przedzialu

							cmp [si], dl					; [si] to [sp+4cx]
							jl horizontalDyn
							
							; wspolrzedna x miny jest wieksza rowna (wspolrzednej x szukanego pola - 1)
							add dl, 4						; przesuniecie o dwa pola w tablicy w prawo
							cmp [si], dl

							jg horizontalDyn
							bts [mineBool], cx
							jmp horizontalDyn


							; przejscie do szukania w poprzek
						verticalDynStart:
							xor cx, cx						; zerowanie cx
							dec cx							; cx do -1, by petla zaczynala sie od 0
						verticalDyn:
							inc cx
							cmp cx, 3
							je endFind						; zakonczenie petli szukajacej liczby min blisko danego pola

							mov si, cx
							shl si, 2
							add si, sp
							add si, 2

						
							mov dh, [currentRow]
							sub dh, 2
							
							cmp [si], dh					; [bx] = [sp+4cx+2]
							jl verticalDyn
							
							
							; wspolrzedna y miny jest wieksza rowna (wspolrzednej y szukanego pola - 1)
							add dh, 4
							cmp [si], dh

							jg verticalDyn
							; wspolrzedna y sie zgadza, pora zobaczyc, czy wspolrzedna x danej miny rowniez sie zgadza

							bt [mineBool], cx				; jesli i wspolrzedna x, i wspolrzedna y mieszcza sie w danym przedziale, to mina jest blisko danego pola i w carry flag bedzie 1
							adc ax, 0						; zwiekszenie licznika min o jeden, jesli mina jest blisko
							jmp verticalDyn					; sprawdzanie kolejnych min, jesli jeszcze sa


				; zakoczono przeszukiwanie liczby min
				endFind:
					add sp, 12					; zwalnianie stosu ze wczesniej wrzuconych na niego wspolrzednych min (2*6 = 24)
					cmp ax, 0					; czy zliczono w danym polu jakiekolwiek miny w poblizu
					jne numberField 

					; nie znaleziono min, w takim razie puste pole
					mov ax, 2F00H				; bialy znak na zielonym tle (2F), znak ' ' (00)
					mov [es:di], ax				
					jmp moveCursor	

					; jest chociaz jedna mina w poblizu
					numberField:
					add ax, 2F30H				; bialy znak na zielonym tle (2F), znak '0' (30)
					mov [es:di], ax				
					jmp moveCursor	


			; spacja ustawia flage na danym polu
			space:
				mov ax, [es:di]			; pobierz znak z danego pola
				cmp ax, 2F00H			; jesli jest to puste pole, to nic nie rob
				je moveCursor
				cmp al, 0DH				; jesli to pole zawiera flage, to ja zdejmij
				je takeFlag
				; ustawienie danego pola jako oznaczonego flaga
				mov ax, 200DH			
				mov [es:di], ax
				jmp moveCursor
				; ponowne ustawienie "niewiadomego" pola
				takeFlag:
				mov ax, 2F23H
				mov [es:di], ax
				jmp moveCursor

			; pojscie w prawo
			right:
				cmp dl, 49						; sprawdzanie, czy kursor nie wykracza poza tabele z prawej strony
				je moveCursor
				inc byte [currentColumn]		; zwiekszenie obecnej kolumny o dwa - przesuniecie w prawo o dwa pola
				inc byte [currentColumn]
				add di, 4						; przesuniecie rysowania o dwa pola w prawo
				jmp moveCursor
	
			up:
				cmp dh, 3						; sprawdzanie, czy kursor nie wykracza poza tabele z gornej strony
				je moveCursor
				dec byte [currentRow]			; zmniejszenie obecnego wiersza o dwa - przesuniecie w gore o dwa pola
				dec byte [currentRow]
				sub di, 320						; przesuniecie rysowania w gore o dwa pola
				jmp moveCursor

			down:
				cmp dh, 21						; sprawdzanie, czy kursor nie wykracza poza tabele z dolnej strony
				je moveCursor
				inc byte [currentRow]			; zwiekszenie obecnego wiersza o dwa - przesuniecie w dol o dwa pola
				inc byte [currentRow]
				add di, 320						; przesuniecie rysowania w dol o dwa pola
				jmp moveCursor
	
			left:
				cmp dl, 31						; sprawdzanie, czy kursor nie wykracza poza tabele z lewej strony
				je moveCursor
				dec byte [currentColumn]		; zmniejszenie obecnej kolumny o dwa - przesuniecie w lewo o dwa pola
				dec byte [currentColumn]
				sub di, 4						; przesuniecie rysowania o dwa pola w lewo
				jmp moveCursor
			
			; komendy ktore ustawiaja kursor na pozycje poszczegolnych min
			;debugX:
			;	mov ah, 0x2
			;	mov dh, [mine1Y]
			;	mov dl, [mine1X]
			;	int 10h
			;	jmp game
			;debugC:
			;	mov ah, 0x2
			;	mov dh, [mine2Y]
			;	mov dl, [mine2X]
			;	int 10h
			;	jmp game
			debugV:
				mov ah, 0x2
				mov dh, [mine3Y]
				mov dl, [mine3X]
				int 10h
				jmp game

			moveCursor:
				mov ah, 0x2						; tryb ustawienia kursora
				mov dh, [currentRow]			; przypisanie do dh liczby obecnego wiersza
				mov dl, [currentColumn]			; przypisanie do dl liczby obecnej kolumny
				int 10h							; wywolanie odpowiedniego przerwania

	jmp game

currentRow db 3
currentColumn db 31

mine1X db 3
mine1Y db 31
mine2X db 0
mine2Y db 0
mine3X db 0
mine3Y db 0
mineBool db 0

times 510-($-$$) db 0			; zerowanie niewykorzystanego miejsca
dw 0AA55H						; zakonczenie pliku sygnatura 





; Optymalizacja:
;	Generowanie min:
;		Mimo ze gracz porusza sie po planszy 10x10, to miny moga byc generowane jedynie w polu 8x8 - nie mozna stawiac min przy krancach tablicy.
;		Dzieki temu zabiegowi nie trzeba pisac kodu dla warunkow brzegowych.
;		Jesli mina bylaby blisko gracza, to za sprawa tego ograniczenia "strefa zagroczenia" nie bedzie pokazywana poza plansza.
;