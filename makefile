CC = gcc
CFLAGS = -Wall -m64

all: main.o filter.o
	$(CC) $(CFLAGS) -o runner.o main.o filter.o -lallegro -lallegro_image -lallegro_dialog

filter.o: filter.s
	nasm -f elf64 -o filter.o filter.s

main.o: main.c
	$(CC) $(CFLAGS) -c -o main.o main.c

clean:
	rm -f *.o

