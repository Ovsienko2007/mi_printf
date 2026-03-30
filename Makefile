all:

	nasm -f elf64 my_printf.asm -o my_printf.o

	ld my_printf.o -o my_printf

	./my_printf