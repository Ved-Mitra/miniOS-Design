# 1. Assemble the bootloader
nasm -f elf32 boot.asm -o boot.o

# 2. Compile the kernel
gcc -m32 -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# 3. Link them into a single binary
ld -m elf_i386 -T linker.ld -o myos.bin boot.o kernel.o

# 4. Check if it's multiboot compatible
if grub-file --is-x86-multiboot myos.bin; then
  echo "Multiboot confirmed. Starting QEMU..."
  qemu-system-i386 -kernel myos.bin
else
  echo "Error: The file is not multiboot compatible."
fi