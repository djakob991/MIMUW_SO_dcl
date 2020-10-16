Implementation of an encryption machine.

### To compile:

```
nasm -f elf64 -w+all -w+error -o dcl.o dcl.asm
ld --fatal-warnings -o dcl dcl.o
```

### Usage:
```
./dcl L R T K

Where:
L, R, T - permutations of characters from [48, 90] ASCII range.
K - encryption key - pair of characters (the initial positions of cylinders)

```
The program reads the data from the standard input and prints encrypted data to the standard output.

