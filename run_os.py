import pty
import os
import sys
import termios
import tty
import subprocess
import select

def main():
    print("==========================================================")
    print("  Starting OS with Log Keeper (Saving to os_system.log)")
    print("==========================================================")
    
    # Save current terminal settings
    old_tty = termios.tcgetattr(sys.stdin)
    # Set terminal to raw mode so shortcuts like Ctrl+C are passed to QEMU
    tty.setraw(sys.stdin.fileno())
    
    master, slave = pty.openpty()
    
    # Start QEMU attached to our virtual terminal (pty)
    p = subprocess.Popen(["make", "qemu"], stdin=slave, stdout=slave, stderr=slave, close_fds=True)
    os.close(slave)
    
    hidden = False
    
    with open("os_system.log", "a") as logfile:
        try:
            while p.poll() is None:
                # Wait for input from either user or QEMU
                r, w, e = select.select([master, sys.stdin], [], [], 0.1)
                
                # Forward user keystrokes to QEMU
                if sys.stdin in r:
                    inp = os.read(sys.stdin.fileno(), 1024)
                    os.write(master, inp)
                    
                # Process OS output
                if master in r:
                    out = os.read(master, 1024)
                    if not out: break
                    
                    text = out.decode('utf-8', errors='replace')
                    
                    for char in text:
                        if char == '\x01':
                            hidden = True   # Start hiding GC logs from screen
                        elif char == '\x02':
                            hidden = False  # Resume showing on screen
                        else:
                            # 1. ALWAYS write to the log file
                            logfile.write(char)
                            
                            # 2. Only write to the terminal screen if it's not a background log
                            if not hidden:
                                sys.stdout.write(char)
                                
                    logfile.flush()
                    sys.stdout.flush()
        except Exception as e:
            pass
        finally:
            # Restore terminal settings on exit
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_tty)

if __name__ == "__main__":
    main()
