## x86Minesweeper
Simple version of Minesweeper written entirely in x86 assembly which can be run as a boot sector game.
<br>
<br>
Controls:
<br>
WASD - Move up, left, down, right
<br>
Enter - Discover field
<br>
Space - Set pole
<br>
<br>

This code has been tested on QEMU x86 System emulator.
<br>
To run it just type this command:
<br>
qemu-system-i386 -drive format=raw,file=Mines.bin
<br>
<br>
If you want to compile this code yourself, I recommend you to use nasm for this job.
<br>
Here it is a command to compile with nasm:
<br>
nasm -f bin Mines.asm -o Mines.bin
<br>
<br>
Screenshot of actual game:
<br>
![Screenshot](https://github.com/pionog/x86Minesweeper/blob/main/screen.png?raw=true)
