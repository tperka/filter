section .data
    BaseMatrix dq 5, -1, 0, 0, -1, -1, 0, -1, 0
    AddMatrix dq -4, 2, 1, 1, 2, 2, 1, 2, 1
    Pixels times 9 db 0
    ;macierze zapisane od dolnego lewego rogu
section .text

global filter
    ; rsi- kopia bufora, rdi - właściwy bufor, rdx - szerokość z paddingiem
    ; rcx - wysokość, r8 - x kliknięcia, r9 - y kliknięcia
filter:
    push r12
    push r13
    push r14
    push r15
    push rbx
    push rbp
    mov rbp, rsp

    countPadding:
    ;rejestry zachowywane na cały program
    mov r10, rdx ;szerokość w pixelach 
    mov r11, rcx ;wysokość  w pixelach
    ;--------------
    xor rax, rax
    lea rax, [rdx+2*rdx]; rax posiada szerokość samego obrazu
    ;w bajtach
    mov [rbp-8], rax ;szerokość w bajtach zapisujemy w rbp-8

    and rax, 3 ;reszta z dzielenia szerokości w bajtach przez 4
    mov rbx, 4
    sub rbx, rax    
    and rbx,3 ; właściwy padding, eliminacja dopisywania 4 bajtów dla 0
    mov [rbp-16], rbx ; padding w rbp-16 oraz chwilowo w rbx
    mov rax, [rbp-8]
    add rax, rbx; do szerokości w bajtach dodajemy padding
    mov [rbp-8], rax ; w rbp - 8 mamy szerokość razem z paddingiem
    sub rcx, 2 ;pierwszą i ostatnią linijkę wczytujemy ręcznie
    mov [rbp - 24], rcx ; licznik linijek pozostałych w rbp - 24
    mov rcx, [rbp-8] ; rcx będzie zliczało szerokość linijki nr 1
    shr rcx, 2 ; rcx- licznik czwórek pixeli pozostałych do przepisania
    mov [rbp-32], rsi ;zachowuję początek tablicy pixeli
rewriteFirstLine:
   
    mov rdx, [rsi] ; w rdx obecnie przepisywana czwórka
    mov [rdi], rdx  ;zapisujemy do rdi
    add rdi, 4
    add rsi, 4  ;przechodzimy na kolejną czwórkę
    loop rewriteFirstLine; robimy tak dopóki nie skończą nam się czwórki
    
processLine:
    mov rax, [rbp - 8]; rax- rozmiar wiersza z paddingiem
    sub rax, [rbp-16]; odejmujemy padding
    sub rax, 6  ;odległość pierwszej składowaej pixela przedostatniego od początku linii
    mov [rbp-40], rax ; liczba pixeli pozostałych do wczytania

writeFirstPixel:
    mov dx, word[rsi]
    mov [rdi], dx
    add rsi, 2
    add rdi, 2
    mov dl, byte[rsi]
    mov [rdi], dl
    inc rsi
    inc rdi
fillPixelArray:
    mov rbx, Pixels ;wskaźnik na tablicę (macierz)
    mov dl, byte[rsi]   ; pozycja względem środka macierzy: (0,0)
    mov [rbx], dl
    inc rbx
    sub rsi, [rbp-8]
    

    mov dl, byte[rsi] ; (0,-1)
    mov [rbx], dl
    inc rbx
    sub rsi, 3

    mov dl, byte[rsi] ; (-1,-1)
    mov [rbx], dl
    inc rbx
    add rsi, 6

    mov dl, byte[rsi] ; (1,-1)
    mov [rbx], dl
    inc rbx
    add rsi, [rbp-8]

    mov dl, byte[rsi] ; (1,0)
    mov[rbx], dl
    inc rbx
    sub rsi, 6

    mov dl, byte[rsi] ;(-1,0)
    mov [rbx], dl
    inc rbx
    add rsi, [rbp-8]

    mov dl, byte[rsi] ; (-1,1)
    mov [rbx], dl
    inc rbx
    add rsi, 3

    mov dl, byte[rsi] ;(0,1)
    mov [rbx], dl
    inc rbx
    add rsi, 3

    mov dl, byte[rsi] ; (1,1)
    mov [rbx], dl
    sub rbx, 8 ;wracamy na początek tablicy pixeli
    sub rsi, 3  ;w lewo o jeden pixel
    sub rsi, [rbp-8]   ;w dół o jeden pixel
calculate_coordinates:
    mov rax, rsi
    sub rax, [rbp-32] ; w rax mam odległość od początku
    mov r14, rax ;kopia odległości od początku
    xor rdx, rdx ; do dzielenia całkowitego
    mov r13, [rbp-8] ; wczytuję długość wiersza
    div r13    ;dzielę całkowicie przez długość wiersza, uzyskując tym samym wysokość przetwarzanego pixela
    mov r15, rax ;współrzędna y pixela w r15
    mul r13 ;mnożę wysokość przez długość wiersza
    sub r14, rax ; mam współrzędną x pomnożoną przez 3 w r14
   
    mov rax, r14 ; kopiuję dzielną
    mov r14, 3 ; ładuję dzielnik
    xor rdx, rdx ;czyścimy przed dzieleniem całkowitym (tu jest przechowywana reszta)
    div r14 ; dzielę rax przez 3 (potrzebna tylko część całkowita)
    mov r14, rax ;współrzędna x znajduje się w r 14
;r14- x aktualnego pixela, r15- y aktualnego pixela
;r8 - x kliknięcia, r9 - y kliknięcia
calculate_distance:
    sub r14, r8 ; różnica w dystansie x
    imul r14, r14 ;podnoszę do kwadratu
    sub r15, r9 ;różnica w dystansie y
    imul r15, r15 ; podnoszę do kwadratu
    add r15, r14 ; W R15 MAM R^2
    ;w r10 szerokosc, w r11 wysokosc
    cmp r10, r11    ;porównanie liczb bez znaku 
    cmova r10, r11 ; przenosimy minimalną wartość do r10, jeśli r10 było niższe, zostaje
calculate_W_factor:
    cvtsi2ss xmm0, r15 ; ładujemy r^2 do xmm0
    sqrtss xmm0, xmm0 ; pierwiastkujemy
    cvtsi2ss xmm1, r10 ;w xmm1 mamy min(szer, wys)
    mov r15, 2 ;zastępujemy niepotrzebne już r^2
    cvtsi2ss xmm2, r15 ; ładujemy float 2 do xmm2
    divss xmm1, xmm2 ;w xmm1 min(szer, wys)/2
    divss xmm0, xmm1 ; w xmm0 mamy r/(min(szer,wys)/2)
    mov r15, 1; ponownie pomagamy sobie przy przenoszeniu
    cvtsi2ss xmm1, r15 ; w xmm1 mamy jedynkę do porównania
    comiss xmm0, xmm1 ;porównujemy
    jb calculate_pixel 
    movss xmm0, xmm1

; w xmm0 mamy Wfactor do mnożenia macierzy
calculate_pixel:
    ;xmm0 zawiera mnożnik ADDMATRIX
    ; r14, r15 wolne, użyjemy do śledzenia tablic AddMatrix i BaseMatrix
    ;rbx ma wskaźnik na początek tablicy Pixels
    mov r14, BaseMatrix
    mov r15, AddMatrix
    
    xor rax, rax    ;zerujemy rax
    cvtsi2ss xmm5, rax ;w xmm5 będziemy trzymać sumę wag do normalizacji
    movss xmm4, xmm5 ; w xmm4 będziemy trzymać nieznormalizowaną wartość koloru pixela
    mov cl, 9   ;ładowanie licznika pętli kalkulacyjnej
calculate_loop:
    
    cvtsi2ss xmm1, [r15] ;kopiujemy do xmm1 pierwszy z addmatrix
    mulss xmm1, xmm0 ;mnożymy go przez W
    cvtsi2ss xmm2, [r14] ;kopiujemy do xmm2 pierwszy z base
    addss xmm1, xmm2 
    ; w xmm1 mamy mnożnik pierwszego pixela
    addss xmm5, xmm1 ;dodajemy do sumy wag
    xor rdx, rdx ;zerujemy rdx
    mov dl, [rbx] ;przenosimy pixel do dl
    cvtsi2ss xmm3, rdx ;konwertujemy do floata
    mulss xmm3, xmm1 ; w xmm3 mamy pixel razy waga
    addss xmm4, xmm3 ; dodajemy do nieznormalizowanego pixela
    inc rbx     ;przechodzimy do następnych wartości
    add r14, 8  ;następny element BaseMatrix
    add r15, 8  ;następny element AddMatrix
    loop calculate_loop

normalization_and_overwrite:
    divss xmm4, xmm5 ;normalizacja wartości pixela
    cvtss2si rdx, xmm4 ; w rdx mamy zaokrągloną wartość pixela do najbliższej liczby całkowitej
    mov [rdi], dl ; nadpisanie
    inc rdi
    inc rsi
    dec qword[rbp-40] ; dekrementujemy liczbę pixeli do wczytania
    jnz fillPixelArray

write_last_pixel:
    mov dx, word[rsi] ;dwa bajty ostatniego pixela przepisujemy
    mov [rdi], dx   
    add rsi, 2  ;przesuwamy o dwa bajty
    add rdi, 2  ;przesuwamy o dwa bajty
    mov dl, byte[rsi]   ;ostatni bajt ostatniego pixela
    mov [rdi], dl   ;także przepisujemy
    inc rsi         ;inkrementujemy kopię i właściwy
    inc rdi         
    mov rax, [rbp-16] ; ile paddingu do dopisania
    cmp rax, 0;
    je after_padding
add_padd:
    mov byte[rdi], 0    ;w ramach paddingu dopisujemy 0
    inc rdi
    dec rax
    jnz add_padd    ;dopisujemy do końca paddingu
    add rsi, [rbp-8] ; przesuwamy rsi do następnej linii

after_padding:
    dec dword [rbp-24] ;przeszliśmy do następnej linijki, dekrementujemy liczbę pozostałych linii
    jnz processLine ; jeśli nie zero to przetwarzamy następną linię
    
;jeśli zero to oznacza, że jesteśmy na ostatniej linii
last_line:
    mov rcx, [rbp-8]   ;szerokość linii
    shr rcx, 2  ;licznik czwórek pikseli do przepisania
process_last_line:
    mov rdx, [rsi]
    mov[rdi], rdx   ;zapisujemy do rdi
    add rdi, 4  ;przesuwamy o 4 bajty
    add rsi, 4  ;przesuwamy o 4 bajty
    loop process_last_line ;jeśli rcx nie zero, to przepisujemy dalej
end:
   
    mov rsp, rbp
    pop rbp
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

