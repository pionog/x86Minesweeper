use16							; 16-bitowy kod

org 7C00H						; ustawienie bootsectora w pamieci na pozycji 7C00H

setup:
	mov ax, 0003H					; ustawienie trybu graficznego. AH = 00 i AL = 03 to 16-kolorowy tryb VGA, gdzie mozna umiescic 80x25 znakow
	int 10h							; wywolanie przerwania

	; ustawianie pamieci wideo, by mozna bylo pisac na ekranie
	mov ax, 0B800H					; nie mozna bezposrednio przypisac stalej liczbowej do es, wiec trzeba najpierw do dostepnego rejestru
	mov es, ax						; ES:DI = B800:0000, gdzie DI bedzie wyzerowany w cyklu

game:

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
					inc di				; podwojny inc di, by przejsc dwie pozycje dalej
					inc di
					;mov ax, 2F23H		; bialy znak na zielonym tle (2F), znak '#' (23)
					;stosw
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

		; opoznianie czasu do nastepnego cyklu, dzieki czemu ekran nie miga zbyt czesto
		cycle:
			mov bx, [046CH]				; pobranie wartosci tick od momentu uruchomienia programu
			inc bx
			inc bx
			inc bx
			.delay:
				cmp [046CH], bx			; sprawdzanie czy minelo odpowiednio duzo zasu na odswiezenie ekranu
				jl .delay

	jmp game

times 510-($-$$) db 0			; zerowanie niewykorzystanego miejsca
dw 0AA55H						; zakonczenie pliku sygnatura 