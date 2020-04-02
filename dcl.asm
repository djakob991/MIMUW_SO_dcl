;
; MIMUW, Systemy Operacyjne, zadanie 1: "DCL"
; autor: Jakub Organa
;

; UWAGA: kod ASCII znaku pomniejszony o 49 będę określał jako 'INDEKS' tego znaku.

; Tablice reprezentujące permutacje przechowują INDEKSY znaków.
; Mają one długość 126==3*42, przy czym obowiązywać
; będzie: tab[x] == tab[x+42] == tab[x+84] dla 0 <= x < 42.
; Dzięki temu uniknę obliczania reszty z dzielenia.

section .bss
        perm_L          resb 126 ; permutacja L
        perm_inv_L      resb 126 ; odwrotność L
        perm_R          resb 126 ; R
        perm_inv_R      resb 126 ; odwrotność R
        perm_T          resb 126 ; T
        buffer          resb 4096 ; bufor na dane czytane z wejścia


; Tablica w .data służy do walidowania permutacji.
; Będę w nich zaznaczał jedynkami lub dwójkami elementy będące w danym momencie
; w zbiorze wartości.
section .data
        check   times 42 db 0


section .text
        global  _start


; Kończy program z kodem 0.
_exit_0:
        mov     rax, 60
        mov     rdi, 0
        syscall


; Kończy program z kodem 1.
_exit_1:
        mov     rax, 60
        mov     rdi, 1
        syscall


; Kończy program z kodem 1, jeśli podany znak nie był z dozwolonego zakresu.
; ARGUMENTY:
; %1: kod znaku
%macro vchar 1
        cmp     %1, 49
        jl      _exit_1
        cmp     %1, 90
        jg      _exit_1
%endmacro

; Waliduje string reprezentujący permutację - sprawdza długość, poprawność
; znaków oraz czy jest to poprawna permutacja. Przepisuje permutację do wskazanego
; miejsca w pamięci. Wyznacza i zapisuje do wskazanego miejsca w pamięci odwrotność
; podanej permutacji (jeśli podany adres jest niezerowy).
; ARGUMENTY:
; rdi: wskaźnik na stringa
; rsi: wskaźnik na miejsce na odwrotność
; rdx: wskaźnik na docelowe miejsce w pamięci
; r8: wartość oznaczająca, że jeśli chceck[x] == r8, to x JEST już w zbiorze wartości.
; MODYFIKUJE REJESTRY:
; rdi, rbx, rcx
_validate:
        xor     ebx, ebx ; ebx: licznik

_loop__validate:
        cmp     ebx, 41
        jg      _case2__validate

_case1__validate: ; pierwszy przypadek: rozpatrywany znak ma indeks od 0 do 41
        movzx   ecx, BYTE [rdi] ; ecx: kod znaku
        vchar   ecx
        sub     ecx, 49 ; ecx: INDEKS znaku
        mov     [rdx + rbx], cl ; kopiuję INDEKS znaku do wskazanej tablicy
        mov     [rdx + rbx + 42], cl
        mov     [rdx + rbx + 84], cl    

        cmp     rsi, 0 ; Jeśli adres miejsca na odwrotność jest niezerowy ...
        je      _all

        ; ... będę wyznaczał odpowiednie pole odwrotności.
        ; permutacja(ebx) == ecx ==> odwrotność(ecx) == ebx
        cmp     BYTE [check + rcx], r8b ; Jeśli check[rcx] == r8b ...
        je     _exit_1 ; ... to znaczy, że funkcja nie jest różnowartościowa.         
        mov     [rsi + rcx], bl ; zapisuję wartość ebx pod indeksem ecx
        mov     [rsi + rcx + 42], bl
        mov     [rsi + rcx + 84], bl
        mov     BYTE [check + rcx], r8b

_all:
        inc     rdi
        inc     rbx
        jmp     _loop__validate

_case2__validate: ; drugi przypadek: znak o indeksie 42 ...
        cmp     BYTE [rdi], 0 ; ... musi być zerem
        jne     _exit_1
        ret


; Przesuwa bębenek.
; ARGUMENTY
; %1: aktualna pozycja bębenka (dopuszczalne jedynie r14d, r15d)
; MODYFIKUJE REJESTRY:
; ecx
%macro cshift 1
        inc     %1
        mov     ecx, 0
        cmp     %1, 41
        cmovg   %1, ecx ; Jeśli osiągnęliśmy 42, cofamy się do 0.
%endmacro


_start:
        pop     rax
        cmp     rax, 5
        jne     _exit_1; Zła liczba argumentów - exit 1
    
        pop     rax ; zdejmuję ze stosu wskaźnik na nazwę programu
    
        pop     rdi ; rdi: wskaźnik na 1 argument
        mov     rdx, perm_L
        mov     rsi, perm_inv_L
        mov     r8, 1
        call     _validate

        pop     rdi ; rdi: wskaźnik na 2 argument
        mov     rdx, perm_R
        mov     rsi, perm_inv_R
        inc     r8
        call    _validate

        pop     rdi ; rdi: wskaźnik na 3 argument
        mov     rdx, perm_T
        mov     rsi, 0
        call    _validate

        pop     rdi ; rdi: wskaźnik na 4 argument
        movzx   r14d, BYTE [rdi] ; r14d: kod ASCII początkowej pozycji bębenka L
        vchar   r14d
        sub     r14d, 49 ; r14d: INDEKS początkowej pozycji bębenka L
    
        inc     rdi ; rdi: wskazuje na drugi bajt klucza
        movzx   r15d, BYTE [rdi] ; r15d: ASCII
        vchar   r15d
        sub     r15d, 49 ; r15d: INDEKS
    
        inc     rdi ; rdi: wskazuje na bajt za drugim elementem klucza ...
        cmp     BYTE [rdi], 0 ; ... więc musi być zerem
        jne     _exit_1

        ; Teraz sprawdzę poprawność permutacji T.
        xor     ebx, ebx ; rbx: licznik

_loop__check_T:
        movzx   ecx, BYTE [perm_T + ebx] ; ecx := T(ebx)
        cmp     ebx, ecx ; sprawdzenie czy znak nie przechodzi sam na siebie
        je      _exit_1
        cmp     bl, BYTE [perm_T + ecx] ; sprawdzenie, czy ebx == T(T(ebx))
        jne     _exit_1

        inc     ebx
        cmp     ebx, 42
        jne     _loop__check_T

; W pętli czytam ze standardowego wejścia do 'buffer', szyfruję i wypisuję
_loop__read_and_process:  
        mov     rax, 0
        mov     rdi, 0
        mov     rsi, buffer
        mov     rdx, 4096
        syscall ; wczytanie ze standardowego wejścia

        cmp     rax, 0
        jl      _exit_1 ; sys_read zwrócił < 0, kończę program z kodem 1
        je      _exit_0 ; sys_read zwrócił 0, a zatem całe wejście zostało zaszyfrowane. Kończę z kodem 0.

        mov     r13d, eax ; zapisuję w r13d ilość wczytanych bajtów
        xor     ebx, ebx ; ebx: licznik

; Iteracja po wczytanym ciągu bajtów
_loop__validate_and_encrypt:
        movzx   eax, BYTE [buffer + ebx] ; eax: kod szyfrowanego znaku
        vchar   eax
    
        cshift  r15d  ; obracam bębenek R
        cmp     r15d, 27 ; bębenek R w pozycji 'L'?
        je      _rotary_position
        cmp     r15d, 33 ; 'R'
        je      _rotary_position
        cmp     r15d, 35 ; 'T'
        je      _rotary_position
        jmp     _common ; jeśli bębenek R nie był w żadnej z pozycji obrotowych, pomiń obracanie bębenka L

_rotary_position:
        cshift  r14d ; obracam bębenek L

_common:
        sub     eax, 49 ; eax: INDEKS szyfrowanego znaku

        ; SZYFROWANIE
        ; operacja Q: eax := eax + (INDEKS pozycji bębenka)
        ; operacja Q^-1: eax := eax + 42 - (INDEKS pozycji bębenka)
        ; Po wykonaniu którejś z tych operacji, właściwym INDEKSem szyfrowanego
        ; znaku w danym momencie jest eax modulo 42.
        ; Dzięki przedłużonym tablicom permutacji, aby wykonać odpowiednią operację
        ; (L,R,L_inv,R_inv,T), jedynie odczytujemy wartość z tablicy. Otrzymujemy wówaczas
        ; właściwy INDEKS szyfrowanego znaku po tej operacji.
        ;
        ; Ponieważ ostatnią operacją jest Q, na samym końcu musimy wykonać modulo.

        movzx   eax, BYTE [perm_R + eax + r15d]
        add     eax, 42
        sub     eax, r15d

        movzx   eax, BYTE [perm_L + eax + r14d]
        add     eax, 42
        sub     eax, r14d

        movzx   eax, BYTE [perm_T + eax]

        movzx   eax, BYTE [perm_inv_L + eax + r14d]
        add     eax, 42
        sub     eax, r14d

        movzx   eax, BYTE [perm_inv_R + eax + r15d]
        add     eax, 42
        sub     eax, r15d

        mov     edx, eax 
        sub     edx, 42
        cmp     eax, 41  ; Jeśli pod koniec INDEKS znaku >= 42 ...
        cmovg   eax, edx ; Wykonuję modulo 42 : odejmuję 42. (Mogę tak zrobić, bo
                         ; w tym przypadku INDEKS < 84)

        add     eax, 49 ; zamieniam INDEKS zaszyfrowanego znaku na kod znaku
        mov     BYTE [buffer + rbx], al ; zapisuję zaszyfrowany znak w buforze

        inc     ebx
        cmp     ebx, r13d
        jne     _loop__validate_and_encrypt

        ; W buforze znajdują się teraz zaszyfrowane bajty
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, buffer
        mov     rdx, r13
        syscall ; wypisuję na standardowe wyjście zaszyfrowane bajty

        cmp     rax, 0
        jl      _exit_1 ; sys_write zwrócił < 0, kończę program z kodem 1

        jmp     _loop__read_and_process ; skaczę, aby znowu wykonać sys_read


