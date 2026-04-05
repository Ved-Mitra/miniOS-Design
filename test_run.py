import pexpect
import sys

child = pexpect.spawn('make qemu', timeout=30)
child.logfile = sys.stdout.buffer

child.expect('init: starting sh')
child.sendline('memcomp_test')

child.expect('Memory compaction & best-fit test finished', timeout=30)
child.sendline(chr(1)) # Ctrl-A to exit qemu
child.sendline('x')
child.expect(pexpect.EOF)
