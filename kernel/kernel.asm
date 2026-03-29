
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00008117          	auipc	sp,0x8
    80000004:	8d010113          	addi	sp,sp,-1840 # 800078d0 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	02a000ef          	jal	ra,80000040 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000002e:	306027f3          	csrr	a5,mcounteren
  // NOTE: sstc extension (stimecmp) requires QEMU 7.2+.
  // local environment uses QEMU 6.2.0, so this is disabled.
  // w_menvcfg(r_menvcfg() | (1L << 63)); 
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000032:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000036:	30679073          	csrw	mcounteren,a5
  
  // w_stimecmp(r_time() + 1000000);
}
    8000003a:	6422                	ld	s0,8(sp)
    8000003c:	0141                	addi	sp,sp,16
    8000003e:	8082                	ret

0000000080000040 <start>:
{
    80000040:	1141                	addi	sp,sp,-16
    80000042:	e406                	sd	ra,8(sp)
    80000044:	e022                	sd	s0,0(sp)
    80000046:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000048:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000004c:	7779                	lui	a4,0xffffe
    8000004e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbd827>
    80000052:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000054:	6705                	lui	a4,0x1
    80000056:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000005a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000005c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000060:	00001797          	auipc	a5,0x1
    80000064:	e7e78793          	addi	a5,a5,-386 # 80000ede <main>
    80000068:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000006c:	4781                	li	a5,0
    8000006e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000072:	67c1                	lui	a5,0x10
    80000074:	17fd                	addi	a5,a5,-1
    80000076:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000007a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000007e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    80000082:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    80000086:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    8000008a:	57fd                	li	a5,-1
    8000008c:	83a9                	srli	a5,a5,0xa
    8000008e:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    80000092:	47bd                	li	a5,15
    80000094:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    80000098:	f85ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    8000009c:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000a0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000a2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000a4:	30200073          	mret
}
    800000a8:	60a2                	ld	ra,8(sp)
    800000aa:	6402                	ld	s0,0(sp)
    800000ac:	0141                	addi	sp,sp,16
    800000ae:	8082                	ret

00000000800000b0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000b0:	7159                	addi	sp,sp,-112
    800000b2:	f486                	sd	ra,104(sp)
    800000b4:	f0a2                	sd	s0,96(sp)
    800000b6:	eca6                	sd	s1,88(sp)
    800000b8:	e8ca                	sd	s2,80(sp)
    800000ba:	e4ce                	sd	s3,72(sp)
    800000bc:	e0d2                	sd	s4,64(sp)
    800000be:	fc56                	sd	s5,56(sp)
    800000c0:	f85a                	sd	s6,48(sp)
    800000c2:	f45e                	sd	s7,40(sp)
    800000c4:	f062                	sd	s8,32(sp)
    800000c6:	1880                	addi	s0,sp,112
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000c8:	04c05463          	blez	a2,80000110 <consolewrite+0x60>
    800000cc:	8a2a                	mv	s4,a0
    800000ce:	8aae                	mv	s5,a1
    800000d0:	89b2                	mv	s3,a2
  int i = 0;
    800000d2:	4901                	li	s2,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000d4:	4bfd                	li	s7,31
    int nn = sizeof(buf);
    800000d6:	02000c13          	li	s8,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000da:	5b7d                	li	s6,-1
    800000dc:	a025                	j	80000104 <consolewrite+0x54>
    800000de:	86a6                	mv	a3,s1
    800000e0:	01590633          	add	a2,s2,s5
    800000e4:	85d2                	mv	a1,s4
    800000e6:	f9040513          	addi	a0,s0,-112
    800000ea:	36e020ef          	jal	ra,80002458 <either_copyin>
    800000ee:	03650263          	beq	a0,s6,80000112 <consolewrite+0x62>
      break;
    uartwrite(buf, nn);
    800000f2:	85a6                	mv	a1,s1
    800000f4:	f9040513          	addi	a0,s0,-112
    800000f8:	71e000ef          	jal	ra,80000816 <uartwrite>
    i += nn;
    800000fc:	0124893b          	addw	s2,s1,s2
  while(i < n){
    80000100:	01395963          	bge	s2,s3,80000112 <consolewrite+0x62>
    if(nn > n - i)
    80000104:	412984bb          	subw	s1,s3,s2
    80000108:	fc9bdbe3          	bge	s7,s1,800000de <consolewrite+0x2e>
    int nn = sizeof(buf);
    8000010c:	84e2                	mv	s1,s8
    8000010e:	bfc1                	j	800000de <consolewrite+0x2e>
  int i = 0;
    80000110:	4901                	li	s2,0
  }

  return i;
}
    80000112:	854a                	mv	a0,s2
    80000114:	70a6                	ld	ra,104(sp)
    80000116:	7406                	ld	s0,96(sp)
    80000118:	64e6                	ld	s1,88(sp)
    8000011a:	6946                	ld	s2,80(sp)
    8000011c:	69a6                	ld	s3,72(sp)
    8000011e:	6a06                	ld	s4,64(sp)
    80000120:	7ae2                	ld	s5,56(sp)
    80000122:	7b42                	ld	s6,48(sp)
    80000124:	7ba2                	ld	s7,40(sp)
    80000126:	7c02                	ld	s8,32(sp)
    80000128:	6165                	addi	sp,sp,112
    8000012a:	8082                	ret

000000008000012c <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000012c:	7159                	addi	sp,sp,-112
    8000012e:	f486                	sd	ra,104(sp)
    80000130:	f0a2                	sd	s0,96(sp)
    80000132:	eca6                	sd	s1,88(sp)
    80000134:	e8ca                	sd	s2,80(sp)
    80000136:	e4ce                	sd	s3,72(sp)
    80000138:	e0d2                	sd	s4,64(sp)
    8000013a:	fc56                	sd	s5,56(sp)
    8000013c:	f85a                	sd	s6,48(sp)
    8000013e:	f45e                	sd	s7,40(sp)
    80000140:	f062                	sd	s8,32(sp)
    80000142:	ec66                	sd	s9,24(sp)
    80000144:	e86a                	sd	s10,16(sp)
    80000146:	1880                	addi	s0,sp,112
    80000148:	8aaa                	mv	s5,a0
    8000014a:	8a2e                	mv	s4,a1
    8000014c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000014e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000152:	0000f517          	auipc	a0,0xf
    80000156:	77e50513          	addi	a0,a0,1918 # 8000f8d0 <cons>
    8000015a:	30f000ef          	jal	ra,80000c68 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000015e:	0000f497          	auipc	s1,0xf
    80000162:	77248493          	addi	s1,s1,1906 # 8000f8d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000166:	00010917          	auipc	s2,0x10
    8000016a:	80290913          	addi	s2,s2,-2046 # 8000f968 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    8000016e:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000170:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    80000172:	4ca9                	li	s9,10
  while(n > 0){
    80000174:	07305363          	blez	s3,800001da <consoleread+0xae>
    while(cons.r == cons.w){
    80000178:	0984a783          	lw	a5,152(s1)
    8000017c:	09c4a703          	lw	a4,156(s1)
    80000180:	02f71163          	bne	a4,a5,800001a2 <consoleread+0x76>
      if(killed(myproc())){
    80000184:	7da010ef          	jal	ra,8000195e <myproc>
    80000188:	162020ef          	jal	ra,800022ea <killed>
    8000018c:	e125                	bnez	a0,800001ec <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    8000018e:	85a6                	mv	a1,s1
    80000190:	854a                	mv	a0,s2
    80000192:	721010ef          	jal	ra,800020b2 <sleep>
    while(cons.r == cons.w){
    80000196:	0984a783          	lw	a5,152(s1)
    8000019a:	09c4a703          	lw	a4,156(s1)
    8000019e:	fef703e3          	beq	a4,a5,80000184 <consoleread+0x58>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001a2:	0017871b          	addiw	a4,a5,1
    800001a6:	08e4ac23          	sw	a4,152(s1)
    800001aa:	07f7f713          	andi	a4,a5,127
    800001ae:	9726                	add	a4,a4,s1
    800001b0:	01874703          	lbu	a4,24(a4)
    800001b4:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001b8:	057d0f63          	beq	s10,s7,80000216 <consoleread+0xea>
    cbuf = c;
    800001bc:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c0:	4685                	li	a3,1
    800001c2:	f9f40613          	addi	a2,s0,-97
    800001c6:	85d2                	mv	a1,s4
    800001c8:	8556                	mv	a0,s5
    800001ca:	244020ef          	jal	ra,8000240e <either_copyout>
    800001ce:	01850663          	beq	a0,s8,800001da <consoleread+0xae>
    dst++;
    800001d2:	0a05                	addi	s4,s4,1
    --n;
    800001d4:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    800001d6:	f99d1fe3          	bne	s10,s9,80000174 <consoleread+0x48>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001da:	0000f517          	auipc	a0,0xf
    800001de:	6f650513          	addi	a0,a0,1782 # 8000f8d0 <cons>
    800001e2:	31f000ef          	jal	ra,80000d00 <release>

  return target - n;
    800001e6:	413b053b          	subw	a0,s6,s3
    800001ea:	a801                	j	800001fa <consoleread+0xce>
        release(&cons.lock);
    800001ec:	0000f517          	auipc	a0,0xf
    800001f0:	6e450513          	addi	a0,a0,1764 # 8000f8d0 <cons>
    800001f4:	30d000ef          	jal	ra,80000d00 <release>
        return -1;
    800001f8:	557d                	li	a0,-1
}
    800001fa:	70a6                	ld	ra,104(sp)
    800001fc:	7406                	ld	s0,96(sp)
    800001fe:	64e6                	ld	s1,88(sp)
    80000200:	6946                	ld	s2,80(sp)
    80000202:	69a6                	ld	s3,72(sp)
    80000204:	6a06                	ld	s4,64(sp)
    80000206:	7ae2                	ld	s5,56(sp)
    80000208:	7b42                	ld	s6,48(sp)
    8000020a:	7ba2                	ld	s7,40(sp)
    8000020c:	7c02                	ld	s8,32(sp)
    8000020e:	6ce2                	ld	s9,24(sp)
    80000210:	6d42                	ld	s10,16(sp)
    80000212:	6165                	addi	sp,sp,112
    80000214:	8082                	ret
      if(n < target){
    80000216:	0009871b          	sext.w	a4,s3
    8000021a:	fd6770e3          	bgeu	a4,s6,800001da <consoleread+0xae>
        cons.r--;
    8000021e:	0000f717          	auipc	a4,0xf
    80000222:	74f72523          	sw	a5,1866(a4) # 8000f968 <cons+0x98>
    80000226:	bf55                	j	800001da <consoleread+0xae>

0000000080000228 <consputc>:
{
    80000228:	1141                	addi	sp,sp,-16
    8000022a:	e406                	sd	ra,8(sp)
    8000022c:	e022                	sd	s0,0(sp)
    8000022e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000230:	10000793          	li	a5,256
    80000234:	00f50863          	beq	a0,a5,80000244 <consputc+0x1c>
    uartputc_sync(c);
    80000238:	67c000ef          	jal	ra,800008b4 <uartputc_sync>
}
    8000023c:	60a2                	ld	ra,8(sp)
    8000023e:	6402                	ld	s0,0(sp)
    80000240:	0141                	addi	sp,sp,16
    80000242:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000244:	4521                	li	a0,8
    80000246:	66e000ef          	jal	ra,800008b4 <uartputc_sync>
    8000024a:	02000513          	li	a0,32
    8000024e:	666000ef          	jal	ra,800008b4 <uartputc_sync>
    80000252:	4521                	li	a0,8
    80000254:	660000ef          	jal	ra,800008b4 <uartputc_sync>
    80000258:	b7d5                	j	8000023c <consputc+0x14>

000000008000025a <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    8000025a:	1101                	addi	sp,sp,-32
    8000025c:	ec06                	sd	ra,24(sp)
    8000025e:	e822                	sd	s0,16(sp)
    80000260:	e426                	sd	s1,8(sp)
    80000262:	e04a                	sd	s2,0(sp)
    80000264:	1000                	addi	s0,sp,32
    80000266:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000268:	0000f517          	auipc	a0,0xf
    8000026c:	66850513          	addi	a0,a0,1640 # 8000f8d0 <cons>
    80000270:	1f9000ef          	jal	ra,80000c68 <acquire>

  switch(c){
    80000274:	47d5                	li	a5,21
    80000276:	0af48063          	beq	s1,a5,80000316 <consoleintr+0xbc>
    8000027a:	0297c663          	blt	a5,s1,800002a6 <consoleintr+0x4c>
    8000027e:	47a1                	li	a5,8
    80000280:	0cf48f63          	beq	s1,a5,8000035e <consoleintr+0x104>
    80000284:	47c1                	li	a5,16
    80000286:	10f49063          	bne	s1,a5,80000386 <consoleintr+0x12c>
  case C('P'):  // Print process list.
    procdump();
    8000028a:	218020ef          	jal	ra,800024a2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000028e:	0000f517          	auipc	a0,0xf
    80000292:	64250513          	addi	a0,a0,1602 # 8000f8d0 <cons>
    80000296:	26b000ef          	jal	ra,80000d00 <release>
}
    8000029a:	60e2                	ld	ra,24(sp)
    8000029c:	6442                	ld	s0,16(sp)
    8000029e:	64a2                	ld	s1,8(sp)
    800002a0:	6902                	ld	s2,0(sp)
    800002a2:	6105                	addi	sp,sp,32
    800002a4:	8082                	ret
  switch(c){
    800002a6:	07f00793          	li	a5,127
    800002aa:	0af48a63          	beq	s1,a5,8000035e <consoleintr+0x104>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002ae:	0000f717          	auipc	a4,0xf
    800002b2:	62270713          	addi	a4,a4,1570 # 8000f8d0 <cons>
    800002b6:	0a072783          	lw	a5,160(a4)
    800002ba:	09872703          	lw	a4,152(a4)
    800002be:	9f99                	subw	a5,a5,a4
    800002c0:	07f00713          	li	a4,127
    800002c4:	fcf765e3          	bltu	a4,a5,8000028e <consoleintr+0x34>
      c = (c == '\r') ? '\n' : c;
    800002c8:	47b5                	li	a5,13
    800002ca:	0cf48163          	beq	s1,a5,8000038c <consoleintr+0x132>
      consputc(c);
    800002ce:	8526                	mv	a0,s1
    800002d0:	f59ff0ef          	jal	ra,80000228 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800002d4:	0000f797          	auipc	a5,0xf
    800002d8:	5fc78793          	addi	a5,a5,1532 # 8000f8d0 <cons>
    800002dc:	0a07a683          	lw	a3,160(a5)
    800002e0:	0016871b          	addiw	a4,a3,1
    800002e4:	0007061b          	sext.w	a2,a4
    800002e8:	0ae7a023          	sw	a4,160(a5)
    800002ec:	07f6f693          	andi	a3,a3,127
    800002f0:	97b6                	add	a5,a5,a3
    800002f2:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    800002f6:	47a9                	li	a5,10
    800002f8:	0af48f63          	beq	s1,a5,800003b6 <consoleintr+0x15c>
    800002fc:	4791                	li	a5,4
    800002fe:	0af48c63          	beq	s1,a5,800003b6 <consoleintr+0x15c>
    80000302:	0000f797          	auipc	a5,0xf
    80000306:	6667a783          	lw	a5,1638(a5) # 8000f968 <cons+0x98>
    8000030a:	9f1d                	subw	a4,a4,a5
    8000030c:	08000793          	li	a5,128
    80000310:	f6f71fe3          	bne	a4,a5,8000028e <consoleintr+0x34>
    80000314:	a04d                	j	800003b6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000316:	0000f717          	auipc	a4,0xf
    8000031a:	5ba70713          	addi	a4,a4,1466 # 8000f8d0 <cons>
    8000031e:	0a072783          	lw	a5,160(a4)
    80000322:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000326:	0000f497          	auipc	s1,0xf
    8000032a:	5aa48493          	addi	s1,s1,1450 # 8000f8d0 <cons>
    while(cons.e != cons.w &&
    8000032e:	4929                	li	s2,10
    80000330:	f4f70fe3          	beq	a4,a5,8000028e <consoleintr+0x34>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000334:	37fd                	addiw	a5,a5,-1
    80000336:	07f7f713          	andi	a4,a5,127
    8000033a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000033c:	01874703          	lbu	a4,24(a4)
    80000340:	f52707e3          	beq	a4,s2,8000028e <consoleintr+0x34>
      cons.e--;
    80000344:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000348:	10000513          	li	a0,256
    8000034c:	eddff0ef          	jal	ra,80000228 <consputc>
    while(cons.e != cons.w &&
    80000350:	0a04a783          	lw	a5,160(s1)
    80000354:	09c4a703          	lw	a4,156(s1)
    80000358:	fcf71ee3          	bne	a4,a5,80000334 <consoleintr+0xda>
    8000035c:	bf0d                	j	8000028e <consoleintr+0x34>
    if(cons.e != cons.w){
    8000035e:	0000f717          	auipc	a4,0xf
    80000362:	57270713          	addi	a4,a4,1394 # 8000f8d0 <cons>
    80000366:	0a072783          	lw	a5,160(a4)
    8000036a:	09c72703          	lw	a4,156(a4)
    8000036e:	f2f700e3          	beq	a4,a5,8000028e <consoleintr+0x34>
      cons.e--;
    80000372:	37fd                	addiw	a5,a5,-1
    80000374:	0000f717          	auipc	a4,0xf
    80000378:	5ef72e23          	sw	a5,1532(a4) # 8000f970 <cons+0xa0>
      consputc(BACKSPACE);
    8000037c:	10000513          	li	a0,256
    80000380:	ea9ff0ef          	jal	ra,80000228 <consputc>
    80000384:	b729                	j	8000028e <consoleintr+0x34>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000386:	f00484e3          	beqz	s1,8000028e <consoleintr+0x34>
    8000038a:	b715                	j	800002ae <consoleintr+0x54>
      consputc(c);
    8000038c:	4529                	li	a0,10
    8000038e:	e9bff0ef          	jal	ra,80000228 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000392:	0000f797          	auipc	a5,0xf
    80000396:	53e78793          	addi	a5,a5,1342 # 8000f8d0 <cons>
    8000039a:	0a07a703          	lw	a4,160(a5)
    8000039e:	0017069b          	addiw	a3,a4,1
    800003a2:	0006861b          	sext.w	a2,a3
    800003a6:	0ad7a023          	sw	a3,160(a5)
    800003aa:	07f77713          	andi	a4,a4,127
    800003ae:	97ba                	add	a5,a5,a4
    800003b0:	4729                	li	a4,10
    800003b2:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    800003b6:	0000f797          	auipc	a5,0xf
    800003ba:	5ac7ab23          	sw	a2,1462(a5) # 8000f96c <cons+0x9c>
        wakeup(&cons.r);
    800003be:	0000f517          	auipc	a0,0xf
    800003c2:	5aa50513          	addi	a0,a0,1450 # 8000f968 <cons+0x98>
    800003c6:	539010ef          	jal	ra,800020fe <wakeup>
    800003ca:	b5d1                	j	8000028e <consoleintr+0x34>

00000000800003cc <consoleinit>:

void
consoleinit(void)
{
    800003cc:	1141                	addi	sp,sp,-16
    800003ce:	e406                	sd	ra,8(sp)
    800003d0:	e022                	sd	s0,0(sp)
    800003d2:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    800003d4:	00007597          	auipc	a1,0x7
    800003d8:	c3c58593          	addi	a1,a1,-964 # 80007010 <etext+0x10>
    800003dc:	0000f517          	auipc	a0,0xf
    800003e0:	4f450513          	addi	a0,a0,1268 # 8000f8d0 <cons>
    800003e4:	005000ef          	jal	ra,80000be8 <initlock>

  uartinit();
    800003e8:	3e2000ef          	jal	ra,800007ca <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800003ec:	00240797          	auipc	a5,0x240
    800003f0:	a5478793          	addi	a5,a5,-1452 # 8023fe40 <devsw>
    800003f4:	00000717          	auipc	a4,0x0
    800003f8:	d3870713          	addi	a4,a4,-712 # 8000012c <consoleread>
    800003fc:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800003fe:	00000717          	auipc	a4,0x0
    80000402:	cb270713          	addi	a4,a4,-846 # 800000b0 <consolewrite>
    80000406:	ef98                	sd	a4,24(a5)
}
    80000408:	60a2                	ld	ra,8(sp)
    8000040a:	6402                	ld	s0,0(sp)
    8000040c:	0141                	addi	sp,sp,16
    8000040e:	8082                	ret

0000000080000410 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000410:	7139                	addi	sp,sp,-64
    80000412:	fc06                	sd	ra,56(sp)
    80000414:	f822                	sd	s0,48(sp)
    80000416:	f426                	sd	s1,40(sp)
    80000418:	f04a                	sd	s2,32(sp)
    8000041a:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    8000041c:	c219                	beqz	a2,80000422 <printint+0x12>
    8000041e:	06054f63          	bltz	a0,8000049c <printint+0x8c>
    x = -xx;
  else
    x = xx;
    80000422:	4881                	li	a7,0
    80000424:	fc840693          	addi	a3,s0,-56

  i = 0;
    80000428:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000042a:	00007617          	auipc	a2,0x7
    8000042e:	c0e60613          	addi	a2,a2,-1010 # 80007038 <digits>
    80000432:	883e                	mv	a6,a5
    80000434:	2785                	addiw	a5,a5,1
    80000436:	02b57733          	remu	a4,a0,a1
    8000043a:	9732                	add	a4,a4,a2
    8000043c:	00074703          	lbu	a4,0(a4)
    80000440:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000444:	872a                	mv	a4,a0
    80000446:	02b55533          	divu	a0,a0,a1
    8000044a:	0685                	addi	a3,a3,1
    8000044c:	feb773e3          	bgeu	a4,a1,80000432 <printint+0x22>

  if(sign)
    80000450:	00088b63          	beqz	a7,80000466 <printint+0x56>
    buf[i++] = '-';
    80000454:	fe040713          	addi	a4,s0,-32
    80000458:	97ba                	add	a5,a5,a4
    8000045a:	02d00713          	li	a4,45
    8000045e:	fee78423          	sb	a4,-24(a5)
    80000462:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    80000466:	02f05563          	blez	a5,80000490 <printint+0x80>
    8000046a:	fc840713          	addi	a4,s0,-56
    8000046e:	00f704b3          	add	s1,a4,a5
    80000472:	fff70913          	addi	s2,a4,-1
    80000476:	993e                	add	s2,s2,a5
    80000478:	37fd                	addiw	a5,a5,-1
    8000047a:	1782                	slli	a5,a5,0x20
    8000047c:	9381                	srli	a5,a5,0x20
    8000047e:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    80000482:	fff4c503          	lbu	a0,-1(s1)
    80000486:	da3ff0ef          	jal	ra,80000228 <consputc>
  while(--i >= 0)
    8000048a:	14fd                	addi	s1,s1,-1
    8000048c:	ff249be3          	bne	s1,s2,80000482 <printint+0x72>
}
    80000490:	70e2                	ld	ra,56(sp)
    80000492:	7442                	ld	s0,48(sp)
    80000494:	74a2                	ld	s1,40(sp)
    80000496:	7902                	ld	s2,32(sp)
    80000498:	6121                	addi	sp,sp,64
    8000049a:	8082                	ret
    x = -xx;
    8000049c:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004a0:	4885                	li	a7,1
    x = -xx;
    800004a2:	b749                	j	80000424 <printint+0x14>

00000000800004a4 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004a4:	7131                	addi	sp,sp,-192
    800004a6:	fc86                	sd	ra,120(sp)
    800004a8:	f8a2                	sd	s0,112(sp)
    800004aa:	f4a6                	sd	s1,104(sp)
    800004ac:	f0ca                	sd	s2,96(sp)
    800004ae:	ecce                	sd	s3,88(sp)
    800004b0:	e8d2                	sd	s4,80(sp)
    800004b2:	e4d6                	sd	s5,72(sp)
    800004b4:	e0da                	sd	s6,64(sp)
    800004b6:	fc5e                	sd	s7,56(sp)
    800004b8:	f862                	sd	s8,48(sp)
    800004ba:	f466                	sd	s9,40(sp)
    800004bc:	f06a                	sd	s10,32(sp)
    800004be:	ec6e                	sd	s11,24(sp)
    800004c0:	0100                	addi	s0,sp,128
    800004c2:	8a2a                	mv	s4,a0
    800004c4:	e40c                	sd	a1,8(s0)
    800004c6:	e810                	sd	a2,16(s0)
    800004c8:	ec14                	sd	a3,24(s0)
    800004ca:	f018                	sd	a4,32(s0)
    800004cc:	f41c                	sd	a5,40(s0)
    800004ce:	03043823          	sd	a6,48(s0)
    800004d2:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    800004d6:	00007797          	auipc	a5,0x7
    800004da:	3be7a783          	lw	a5,958(a5) # 80007894 <panicking>
    800004de:	cb9d                	beqz	a5,80000514 <printf+0x70>
    acquire(&pr.lock);

  va_start(ap, fmt);
    800004e0:	00840793          	addi	a5,s0,8
    800004e4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800004e8:	000a4503          	lbu	a0,0(s4)
    800004ec:	24050363          	beqz	a0,80000732 <printf+0x28e>
    800004f0:	4981                	li	s3,0
    if(cx != '%'){
    800004f2:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    800004f6:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    800004fa:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    800004fe:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000502:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    80000506:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000050a:	00007b97          	auipc	s7,0x7
    8000050e:	b2eb8b93          	addi	s7,s7,-1234 # 80007038 <digits>
    80000512:	a01d                	j	80000538 <printf+0x94>
    acquire(&pr.lock);
    80000514:	0000f517          	auipc	a0,0xf
    80000518:	46450513          	addi	a0,a0,1124 # 8000f978 <pr>
    8000051c:	74c000ef          	jal	ra,80000c68 <acquire>
    80000520:	b7c1                	j	800004e0 <printf+0x3c>
      consputc(cx);
    80000522:	d07ff0ef          	jal	ra,80000228 <consputc>
      continue;
    80000526:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000528:	0014899b          	addiw	s3,s1,1
    8000052c:	013a07b3          	add	a5,s4,s3
    80000530:	0007c503          	lbu	a0,0(a5)
    80000534:	1e050f63          	beqz	a0,80000732 <printf+0x28e>
    if(cx != '%'){
    80000538:	ff5515e3          	bne	a0,s5,80000522 <printf+0x7e>
    i++;
    8000053c:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    80000540:	009a07b3          	add	a5,s4,s1
    80000544:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000548:	1e090563          	beqz	s2,80000732 <printf+0x28e>
    8000054c:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    80000550:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    80000552:	c789                	beqz	a5,8000055c <printf+0xb8>
    80000554:	009a0733          	add	a4,s4,s1
    80000558:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    8000055c:	03690863          	beq	s2,s6,8000058c <printf+0xe8>
    } else if(c0 == 'l' && c1 == 'd'){
    80000560:	05890263          	beq	s2,s8,800005a4 <printf+0x100>
    } else if(c0 == 'u'){
    80000564:	0d990163          	beq	s2,s9,80000626 <printf+0x182>
    } else if(c0 == 'x'){
    80000568:	11a90863          	beq	s2,s10,80000678 <printf+0x1d4>
    } else if(c0 == 'p'){
    8000056c:	15b90163          	beq	s2,s11,800006ae <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    80000570:	06300793          	li	a5,99
    80000574:	16f90963          	beq	s2,a5,800006e6 <printf+0x242>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000578:	07300793          	li	a5,115
    8000057c:	16f90f63          	beq	s2,a5,800006fa <printf+0x256>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    80000580:	03591c63          	bne	s2,s5,800005b8 <printf+0x114>
      consputc('%');
    80000584:	8556                	mv	a0,s5
    80000586:	ca3ff0ef          	jal	ra,80000228 <consputc>
    8000058a:	bf79                	j	80000528 <printf+0x84>
      printint(va_arg(ap, int), 10, 1);
    8000058c:	f8843783          	ld	a5,-120(s0)
    80000590:	00878713          	addi	a4,a5,8
    80000594:	f8e43423          	sd	a4,-120(s0)
    80000598:	4605                	li	a2,1
    8000059a:	45a9                	li	a1,10
    8000059c:	4388                	lw	a0,0(a5)
    8000059e:	e73ff0ef          	jal	ra,80000410 <printint>
    800005a2:	b759                	j	80000528 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'd'){
    800005a4:	03678163          	beq	a5,s6,800005c6 <printf+0x122>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005a8:	03878d63          	beq	a5,s8,800005e2 <printf+0x13e>
    } else if(c0 == 'l' && c1 == 'u'){
    800005ac:	09978a63          	beq	a5,s9,80000640 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005b0:	03878b63          	beq	a5,s8,800005e6 <printf+0x142>
    } else if(c0 == 'l' && c1 == 'x'){
    800005b4:	0da78f63          	beq	a5,s10,80000692 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    800005b8:	8556                	mv	a0,s5
    800005ba:	c6fff0ef          	jal	ra,80000228 <consputc>
      consputc(c0);
    800005be:	854a                	mv	a0,s2
    800005c0:	c69ff0ef          	jal	ra,80000228 <consputc>
    800005c4:	b795                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    800005c6:	f8843783          	ld	a5,-120(s0)
    800005ca:	00878713          	addi	a4,a5,8
    800005ce:	f8e43423          	sd	a4,-120(s0)
    800005d2:	4605                	li	a2,1
    800005d4:	45a9                	li	a1,10
    800005d6:	6388                	ld	a0,0(a5)
    800005d8:	e39ff0ef          	jal	ra,80000410 <printint>
      i += 1;
    800005dc:	0029849b          	addiw	s1,s3,2
    800005e0:	b7a1                	j	80000528 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005e2:	03668463          	beq	a3,s6,8000060a <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005e6:	07968b63          	beq	a3,s9,8000065c <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    800005ea:	fda697e3          	bne	a3,s10,800005b8 <printf+0x114>
      printint(va_arg(ap, uint64), 16, 0);
    800005ee:	f8843783          	ld	a5,-120(s0)
    800005f2:	00878713          	addi	a4,a5,8
    800005f6:	f8e43423          	sd	a4,-120(s0)
    800005fa:	4601                	li	a2,0
    800005fc:	45c1                	li	a1,16
    800005fe:	6388                	ld	a0,0(a5)
    80000600:	e11ff0ef          	jal	ra,80000410 <printint>
      i += 2;
    80000604:	0039849b          	addiw	s1,s3,3
    80000608:	b705                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    8000060a:	f8843783          	ld	a5,-120(s0)
    8000060e:	00878713          	addi	a4,a5,8
    80000612:	f8e43423          	sd	a4,-120(s0)
    80000616:	4605                	li	a2,1
    80000618:	45a9                	li	a1,10
    8000061a:	6388                	ld	a0,0(a5)
    8000061c:	df5ff0ef          	jal	ra,80000410 <printint>
      i += 2;
    80000620:	0039849b          	addiw	s1,s3,3
    80000624:	b711                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint32), 10, 0);
    80000626:	f8843783          	ld	a5,-120(s0)
    8000062a:	00878713          	addi	a4,a5,8
    8000062e:	f8e43423          	sd	a4,-120(s0)
    80000632:	4601                	li	a2,0
    80000634:	45a9                	li	a1,10
    80000636:	0007e503          	lwu	a0,0(a5)
    8000063a:	dd7ff0ef          	jal	ra,80000410 <printint>
    8000063e:	b5ed                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    80000640:	f8843783          	ld	a5,-120(s0)
    80000644:	00878713          	addi	a4,a5,8
    80000648:	f8e43423          	sd	a4,-120(s0)
    8000064c:	4601                	li	a2,0
    8000064e:	45a9                	li	a1,10
    80000650:	6388                	ld	a0,0(a5)
    80000652:	dbfff0ef          	jal	ra,80000410 <printint>
      i += 1;
    80000656:	0029849b          	addiw	s1,s3,2
    8000065a:	b5f9                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4601                	li	a2,0
    8000066a:	45a9                	li	a1,10
    8000066c:	6388                	ld	a0,0(a5)
    8000066e:	da3ff0ef          	jal	ra,80000410 <printint>
      i += 2;
    80000672:	0039849b          	addiw	s1,s3,3
    80000676:	bd4d                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint32), 16, 0);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4601                	li	a2,0
    80000686:	45c1                	li	a1,16
    80000688:	0007e503          	lwu	a0,0(a5)
    8000068c:	d85ff0ef          	jal	ra,80000410 <printint>
    80000690:	bd61                	j	80000528 <printf+0x84>
      printint(va_arg(ap, uint64), 16, 0);
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	4601                	li	a2,0
    800006a0:	45c1                	li	a1,16
    800006a2:	6388                	ld	a0,0(a5)
    800006a4:	d6dff0ef          	jal	ra,80000410 <printint>
      i += 1;
    800006a8:	0029849b          	addiw	s1,s3,2
    800006ac:	bdb5                	j	80000528 <printf+0x84>
      printptr(va_arg(ap, uint64));
    800006ae:	f8843783          	ld	a5,-120(s0)
    800006b2:	00878713          	addi	a4,a5,8
    800006b6:	f8e43423          	sd	a4,-120(s0)
    800006ba:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006be:	03000513          	li	a0,48
    800006c2:	b67ff0ef          	jal	ra,80000228 <consputc>
  consputc('x');
    800006c6:	856a                	mv	a0,s10
    800006c8:	b61ff0ef          	jal	ra,80000228 <consputc>
    800006cc:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ce:	03c9d793          	srli	a5,s3,0x3c
    800006d2:	97de                	add	a5,a5,s7
    800006d4:	0007c503          	lbu	a0,0(a5)
    800006d8:	b51ff0ef          	jal	ra,80000228 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006dc:	0992                	slli	s3,s3,0x4
    800006de:	397d                	addiw	s2,s2,-1
    800006e0:	fe0917e3          	bnez	s2,800006ce <printf+0x22a>
    800006e4:	b591                	j	80000528 <printf+0x84>
      consputc(va_arg(ap, uint));
    800006e6:	f8843783          	ld	a5,-120(s0)
    800006ea:	00878713          	addi	a4,a5,8
    800006ee:	f8e43423          	sd	a4,-120(s0)
    800006f2:	4388                	lw	a0,0(a5)
    800006f4:	b35ff0ef          	jal	ra,80000228 <consputc>
    800006f8:	bd05                	j	80000528 <printf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    800006fa:	f8843783          	ld	a5,-120(s0)
    800006fe:	00878713          	addi	a4,a5,8
    80000702:	f8e43423          	sd	a4,-120(s0)
    80000706:	0007b903          	ld	s2,0(a5)
    8000070a:	00090d63          	beqz	s2,80000724 <printf+0x280>
      for(; *s; s++)
    8000070e:	00094503          	lbu	a0,0(s2)
    80000712:	e0050be3          	beqz	a0,80000528 <printf+0x84>
        consputc(*s);
    80000716:	b13ff0ef          	jal	ra,80000228 <consputc>
      for(; *s; s++)
    8000071a:	0905                	addi	s2,s2,1
    8000071c:	00094503          	lbu	a0,0(s2)
    80000720:	f97d                	bnez	a0,80000716 <printf+0x272>
    80000722:	b519                	j	80000528 <printf+0x84>
        s = "(null)";
    80000724:	00007917          	auipc	s2,0x7
    80000728:	8f490913          	addi	s2,s2,-1804 # 80007018 <etext+0x18>
      for(; *s; s++)
    8000072c:	02800513          	li	a0,40
    80000730:	b7dd                	j	80000716 <printf+0x272>
    }

  }
  va_end(ap);

  if(panicking == 0)
    80000732:	00007797          	auipc	a5,0x7
    80000736:	1627a783          	lw	a5,354(a5) # 80007894 <panicking>
    8000073a:	c38d                	beqz	a5,8000075c <printf+0x2b8>
    release(&pr.lock);

  return 0;
}
    8000073c:	4501                	li	a0,0
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	0000f517          	auipc	a0,0xf
    80000760:	21c50513          	addi	a0,a0,540 # 8000f978 <pr>
    80000764:	59c000ef          	jal	ra,80000d00 <release>
  return 0;
    80000768:	bfd1                	j	8000073c <printf+0x298>

000000008000076a <panic>:

void
panic(char *s)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	e04a                	sd	s2,0(sp)
    80000774:	1000                	addi	s0,sp,32
    80000776:	84aa                	mv	s1,a0
  panicking = 1;
    80000778:	4905                	li	s2,1
    8000077a:	00007797          	auipc	a5,0x7
    8000077e:	1127ad23          	sw	s2,282(a5) # 80007894 <panicking>
  printf("panic: ");
    80000782:	00007517          	auipc	a0,0x7
    80000786:	89e50513          	addi	a0,a0,-1890 # 80007020 <etext+0x20>
    8000078a:	d1bff0ef          	jal	ra,800004a4 <printf>
  printf("%s\n", s);
    8000078e:	85a6                	mv	a1,s1
    80000790:	00007517          	auipc	a0,0x7
    80000794:	89850513          	addi	a0,a0,-1896 # 80007028 <etext+0x28>
    80000798:	d0dff0ef          	jal	ra,800004a4 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000079c:	00007797          	auipc	a5,0x7
    800007a0:	0f27aa23          	sw	s2,244(a5) # 80007890 <panicked>
  for(;;)
    800007a4:	a001                	j	800007a4 <panic+0x3a>

00000000800007a6 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    800007ae:	00007597          	auipc	a1,0x7
    800007b2:	88258593          	addi	a1,a1,-1918 # 80007030 <etext+0x30>
    800007b6:	0000f517          	auipc	a0,0xf
    800007ba:	1c250513          	addi	a0,a0,450 # 8000f978 <pr>
    800007be:	42a000ef          	jal	ra,80000be8 <initlock>
}
    800007c2:	60a2                	ld	ra,8(sp)
    800007c4:	6402                	ld	s0,0(sp)
    800007c6:	0141                	addi	sp,sp,16
    800007c8:	8082                	ret

00000000800007ca <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    800007ca:	1141                	addi	sp,sp,-16
    800007cc:	e406                	sd	ra,8(sp)
    800007ce:	e022                	sd	s0,0(sp)
    800007d0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007d2:	100007b7          	lui	a5,0x10000
    800007d6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007da:	f8000713          	li	a4,-128
    800007de:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007e2:	470d                	li	a4,3
    800007e4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007e8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ec:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007f0:	469d                	li	a3,7
    800007f2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007f6:	00e780a3          	sb	a4,1(a5)

  initlock(&tx_lock, "uart");
    800007fa:	00007597          	auipc	a1,0x7
    800007fe:	85658593          	addi	a1,a1,-1962 # 80007050 <digits+0x18>
    80000802:	0000f517          	auipc	a0,0xf
    80000806:	18e50513          	addi	a0,a0,398 # 8000f990 <tx_lock>
    8000080a:	3de000ef          	jal	ra,80000be8 <initlock>
}
    8000080e:	60a2                	ld	ra,8(sp)
    80000810:	6402                	ld	s0,0(sp)
    80000812:	0141                	addi	sp,sp,16
    80000814:	8082                	ret

0000000080000816 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000816:	715d                	addi	sp,sp,-80
    80000818:	e486                	sd	ra,72(sp)
    8000081a:	e0a2                	sd	s0,64(sp)
    8000081c:	fc26                	sd	s1,56(sp)
    8000081e:	f84a                	sd	s2,48(sp)
    80000820:	f44e                	sd	s3,40(sp)
    80000822:	f052                	sd	s4,32(sp)
    80000824:	ec56                	sd	s5,24(sp)
    80000826:	e85a                	sd	s6,16(sp)
    80000828:	e45e                	sd	s7,8(sp)
    8000082a:	0880                	addi	s0,sp,80
    8000082c:	84aa                	mv	s1,a0
    8000082e:	8aae                	mv	s5,a1
  acquire(&tx_lock);
    80000830:	0000f517          	auipc	a0,0xf
    80000834:	16050513          	addi	a0,a0,352 # 8000f990 <tx_lock>
    80000838:	430000ef          	jal	ra,80000c68 <acquire>

  int i = 0;
  while(i < n){ 
    8000083c:	05505b63          	blez	s5,80000892 <uartwrite+0x7c>
    80000840:	8a26                	mv	s4,s1
    80000842:	0485                	addi	s1,s1,1
    80000844:	3afd                	addiw	s5,s5,-1
    80000846:	1a82                	slli	s5,s5,0x20
    80000848:	020ada93          	srli	s5,s5,0x20
    8000084c:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    8000084e:	00007497          	auipc	s1,0x7
    80000852:	04e48493          	addi	s1,s1,78 # 8000789c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000856:	0000f997          	auipc	s3,0xf
    8000085a:	13a98993          	addi	s3,s3,314 # 8000f990 <tx_lock>
    8000085e:	00007917          	auipc	s2,0x7
    80000862:	03a90913          	addi	s2,s2,58 # 80007898 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    80000866:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    8000086a:	4b05                	li	s6,1
    8000086c:	a005                	j	8000088c <uartwrite+0x76>
      sleep(&tx_chan, &tx_lock);
    8000086e:	85ce                	mv	a1,s3
    80000870:	854a                	mv	a0,s2
    80000872:	041010ef          	jal	ra,800020b2 <sleep>
    while(tx_busy != 0){
    80000876:	409c                	lw	a5,0(s1)
    80000878:	fbfd                	bnez	a5,8000086e <uartwrite+0x58>
    WriteReg(THR, buf[i]);
    8000087a:	000a4783          	lbu	a5,0(s4)
    8000087e:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    80000882:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    80000886:	0a05                	addi	s4,s4,1
    80000888:	015a0563          	beq	s4,s5,80000892 <uartwrite+0x7c>
    while(tx_busy != 0){
    8000088c:	409c                	lw	a5,0(s1)
    8000088e:	f3e5                	bnez	a5,8000086e <uartwrite+0x58>
    80000890:	b7ed                	j	8000087a <uartwrite+0x64>
  }

  release(&tx_lock);
    80000892:	0000f517          	auipc	a0,0xf
    80000896:	0fe50513          	addi	a0,a0,254 # 8000f990 <tx_lock>
    8000089a:	466000ef          	jal	ra,80000d00 <release>
}
    8000089e:	60a6                	ld	ra,72(sp)
    800008a0:	6406                	ld	s0,64(sp)
    800008a2:	74e2                	ld	s1,56(sp)
    800008a4:	7942                	ld	s2,48(sp)
    800008a6:	79a2                	ld	s3,40(sp)
    800008a8:	7a02                	ld	s4,32(sp)
    800008aa:	6ae2                	ld	s5,24(sp)
    800008ac:	6b42                	ld	s6,16(sp)
    800008ae:	6ba2                	ld	s7,8(sp)
    800008b0:	6161                	addi	sp,sp,80
    800008b2:	8082                	ret

00000000800008b4 <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800008b4:	1101                	addi	sp,sp,-32
    800008b6:	ec06                	sd	ra,24(sp)
    800008b8:	e822                	sd	s0,16(sp)
    800008ba:	e426                	sd	s1,8(sp)
    800008bc:	1000                	addi	s0,sp,32
    800008be:	84aa                	mv	s1,a0
  if(panicking == 0)
    800008c0:	00007797          	auipc	a5,0x7
    800008c4:	fd47a783          	lw	a5,-44(a5) # 80007894 <panicking>
    800008c8:	cb89                	beqz	a5,800008da <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ca:	00007797          	auipc	a5,0x7
    800008ce:	fc67a783          	lw	a5,-58(a5) # 80007890 <panicked>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008d2:	10000737          	lui	a4,0x10000
  if(panicked){
    800008d6:	c789                	beqz	a5,800008e0 <uartputc_sync+0x2c>
    for(;;)
    800008d8:	a001                	j	800008d8 <uartputc_sync+0x24>
    push_off();
    800008da:	34e000ef          	jal	ra,80000c28 <push_off>
    800008de:	b7f5                	j	800008ca <uartputc_sync+0x16>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008e0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800008e4:	0207f793          	andi	a5,a5,32
    800008e8:	dfe5                	beqz	a5,800008e0 <uartputc_sync+0x2c>
    ;
  WriteReg(THR, c);
    800008ea:	0ff4f513          	andi	a0,s1,255
    800008ee:	100007b7          	lui	a5,0x10000
    800008f2:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    800008f6:	00007797          	auipc	a5,0x7
    800008fa:	f9e7a783          	lw	a5,-98(a5) # 80007894 <panicking>
    800008fe:	c791                	beqz	a5,8000090a <uartputc_sync+0x56>
    pop_off();
}
    80000900:	60e2                	ld	ra,24(sp)
    80000902:	6442                	ld	s0,16(sp)
    80000904:	64a2                	ld	s1,8(sp)
    80000906:	6105                	addi	sp,sp,32
    80000908:	8082                	ret
    pop_off();
    8000090a:	3a2000ef          	jal	ra,80000cac <pop_off>
}
    8000090e:	bfcd                	j	80000900 <uartputc_sync+0x4c>

0000000080000910 <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000910:	1141                	addi	sp,sp,-16
    80000912:	e422                	sd	s0,8(sp)
    80000914:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000916:	100007b7          	lui	a5,0x10000
    8000091a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000091e:	8b85                	andi	a5,a5,1
    80000920:	cb91                	beqz	a5,80000934 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000922:	100007b7          	lui	a5,0x10000
    80000926:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000092a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000092e:	6422                	ld	s0,8(sp)
    80000930:	0141                	addi	sp,sp,16
    80000932:	8082                	ret
    return -1;
    80000934:	557d                	li	a0,-1
    80000936:	bfe5                	j	8000092e <uartgetc+0x1e>

0000000080000938 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000938:	1101                	addi	sp,sp,-32
    8000093a:	ec06                	sd	ra,24(sp)
    8000093c:	e822                	sd	s0,16(sp)
    8000093e:	e426                	sd	s1,8(sp)
    80000940:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    80000942:	100004b7          	lui	s1,0x10000
    80000946:	0024c783          	lbu	a5,2(s1) # 10000002 <_entry-0x6ffffffe>

  acquire(&tx_lock);
    8000094a:	0000f517          	auipc	a0,0xf
    8000094e:	04650513          	addi	a0,a0,70 # 8000f990 <tx_lock>
    80000952:	316000ef          	jal	ra,80000c68 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    80000956:	0054c783          	lbu	a5,5(s1)
    8000095a:	0207f793          	andi	a5,a5,32
    8000095e:	eb89                	bnez	a5,80000970 <uartintr+0x38>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    80000960:	0000f517          	auipc	a0,0xf
    80000964:	03050513          	addi	a0,a0,48 # 8000f990 <tx_lock>
    80000968:	398000ef          	jal	ra,80000d00 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000096c:	54fd                	li	s1,-1
    8000096e:	a831                	j	8000098a <uartintr+0x52>
    tx_busy = 0;
    80000970:	00007797          	auipc	a5,0x7
    80000974:	f207a623          	sw	zero,-212(a5) # 8000789c <tx_busy>
    wakeup(&tx_chan);
    80000978:	00007517          	auipc	a0,0x7
    8000097c:	f2050513          	addi	a0,a0,-224 # 80007898 <tx_chan>
    80000980:	77e010ef          	jal	ra,800020fe <wakeup>
    80000984:	bff1                	j	80000960 <uartintr+0x28>
      break;
    consoleintr(c);
    80000986:	8d5ff0ef          	jal	ra,8000025a <consoleintr>
    int c = uartgetc();
    8000098a:	f87ff0ef          	jal	ra,80000910 <uartgetc>
    if(c == -1)
    8000098e:	fe951ce3          	bne	a0,s1,80000986 <uartintr+0x4e>
  }
}
    80000992:	60e2                	ld	ra,24(sp)
    80000994:	6442                	ld	s0,16(sp)
    80000996:	64a2                	ld	s1,8(sp)
    80000998:	6105                	addi	sp,sp,32
    8000099a:	8082                	ret

000000008000099c <kfree>:
}

// Free the page of physical memory pointed at by pa.
void
kfree(void *pa)
{
    8000099c:	1101                	addi	sp,sp,-32
    8000099e:	ec06                	sd	ra,24(sp)
    800009a0:	e822                	sd	s0,16(sp)
    800009a2:	e426                	sd	s1,8(sp)
    800009a4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009a6:	03451793          	slli	a5,a0,0x34
    800009aa:	efb5                	bnez	a5,80000a26 <kfree+0x8a>
    800009ac:	84aa                	mv	s1,a0
    800009ae:	00240797          	auipc	a5,0x240
    800009b2:	62a78793          	addi	a5,a5,1578 # 80240fd8 <end>
    800009b6:	06f56863          	bltu	a0,a5,80000a26 <kfree+0x8a>
    800009ba:	47c5                	li	a5,17
    800009bc:	07ee                	slli	a5,a5,0x1b
    800009be:	06f57463          	bgeu	a0,a5,80000a26 <kfree+0x8a>
    panic("kfree");

  acquire(&kmem.lock);
    800009c2:	0000f517          	auipc	a0,0xf
    800009c6:	fe650513          	addi	a0,a0,-26 # 8000f9a8 <kmem>
    800009ca:	29e000ef          	jal	ra,80000c68 <acquire>

  int idx = PA2IDX(pa);
    800009ce:	00c4d793          	srli	a5,s1,0xc
    800009d2:	2781                	sext.w	a5,a5

  if(ref_count[idx] <= 0)
    800009d4:	00279693          	slli	a3,a5,0x2
    800009d8:	0000f717          	auipc	a4,0xf
    800009dc:	ff070713          	addi	a4,a4,-16 # 8000f9c8 <ref_count>
    800009e0:	9736                	add	a4,a4,a3
    800009e2:	4318                	lw	a4,0(a4)
    800009e4:	04e05763          	blez	a4,80000a32 <kfree+0x96>
    panic("kfree: ref_count already zero");

  ref_count[idx]--;
    800009e8:	377d                	addiw	a4,a4,-1
    800009ea:	0007061b          	sext.w	a2,a4
    800009ee:	078a                	slli	a5,a5,0x2
    800009f0:	0000f697          	auipc	a3,0xf
    800009f4:	fd868693          	addi	a3,a3,-40 # 8000f9c8 <ref_count>
    800009f8:	97b6                	add	a5,a5,a3
    800009fa:	c398                	sw	a4,0(a5)

  if(ref_count[idx] > 0){
    800009fc:	04c04163          	bgtz	a2,80000a3e <kfree+0xa2>
    release(&kmem.lock);
    return;
  }

  // 🔥 actually free now
  memset(pa, 1, PGSIZE);
    80000a00:	6605                	lui	a2,0x1
    80000a02:	4585                	li	a1,1
    80000a04:	8526                	mv	a0,s1
    80000a06:	336000ef          	jal	ra,80000d3c <memset>

  r = (struct run*)pa;
  r->next = kmem.freelist;
    80000a0a:	0000f517          	auipc	a0,0xf
    80000a0e:	f9e50513          	addi	a0,a0,-98 # 8000f9a8 <kmem>
    80000a12:	6d1c                	ld	a5,24(a0)
    80000a14:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a16:	ed04                	sd	s1,24(a0)

  release(&kmem.lock);
    80000a18:	2e8000ef          	jal	ra,80000d00 <release>
}
    80000a1c:	60e2                	ld	ra,24(sp)
    80000a1e:	6442                	ld	s0,16(sp)
    80000a20:	64a2                	ld	s1,8(sp)
    80000a22:	6105                	addi	sp,sp,32
    80000a24:	8082                	ret
    panic("kfree");
    80000a26:	00006517          	auipc	a0,0x6
    80000a2a:	63250513          	addi	a0,a0,1586 # 80007058 <digits+0x20>
    80000a2e:	d3dff0ef          	jal	ra,8000076a <panic>
    panic("kfree: ref_count already zero");
    80000a32:	00006517          	auipc	a0,0x6
    80000a36:	62e50513          	addi	a0,a0,1582 # 80007060 <digits+0x28>
    80000a3a:	d31ff0ef          	jal	ra,8000076a <panic>
    release(&kmem.lock);
    80000a3e:	0000f517          	auipc	a0,0xf
    80000a42:	f6a50513          	addi	a0,a0,-150 # 8000f9a8 <kmem>
    80000a46:	2ba000ef          	jal	ra,80000d00 <release>
    return;
    80000a4a:	bfc9                	j	80000a1c <kfree+0x80>

0000000080000a4c <freerange>:
{
    80000a4c:	7139                	addi	sp,sp,-64
    80000a4e:	fc06                	sd	ra,56(sp)
    80000a50:	f822                	sd	s0,48(sp)
    80000a52:	f426                	sd	s1,40(sp)
    80000a54:	f04a                	sd	s2,32(sp)
    80000a56:	ec4e                	sd	s3,24(sp)
    80000a58:	e852                	sd	s4,16(sp)
    80000a5a:	e456                	sd	s5,8(sp)
    80000a5c:	e05a                	sd	s6,0(sp)
    80000a5e:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a60:	6785                	lui	a5,0x1
    80000a62:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a66:	9526                	add	a0,a0,s1
    80000a68:	74fd                	lui	s1,0xfffff
    80000a6a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000a6c:	97a6                	add	a5,a5,s1
    80000a6e:	02f5e863          	bltu	a1,a5,80000a9e <freerange+0x52>
    80000a72:	892e                	mv	s2,a1
    ref_count[PA2IDX(p)] = 1;  // temporarily mark as used
    80000a74:	0000fb17          	auipc	s6,0xf
    80000a78:	f54b0b13          	addi	s6,s6,-172 # 8000f9c8 <ref_count>
    80000a7c:	4a85                	li	s5,1
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000a7e:	6a05                	lui	s4,0x1
    80000a80:	6989                	lui	s3,0x2
    ref_count[PA2IDX(p)] = 1;  // temporarily mark as used
    80000a82:	00c4d793          	srli	a5,s1,0xc
    80000a86:	078a                	slli	a5,a5,0x2
    80000a88:	97da                	add	a5,a5,s6
    80000a8a:	0157a023          	sw	s5,0(a5)
    kfree(p);                  // will decrement to 0 and add to freelist
    80000a8e:	8526                	mv	a0,s1
    80000a90:	f0dff0ef          	jal	ra,8000099c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000a94:	87a6                	mv	a5,s1
    80000a96:	94d2                	add	s1,s1,s4
    80000a98:	97ce                	add	a5,a5,s3
    80000a9a:	fef974e3          	bgeu	s2,a5,80000a82 <freerange+0x36>
}
    80000a9e:	70e2                	ld	ra,56(sp)
    80000aa0:	7442                	ld	s0,48(sp)
    80000aa2:	74a2                	ld	s1,40(sp)
    80000aa4:	7902                	ld	s2,32(sp)
    80000aa6:	69e2                	ld	s3,24(sp)
    80000aa8:	6a42                	ld	s4,16(sp)
    80000aaa:	6aa2                	ld	s5,8(sp)
    80000aac:	6b02                	ld	s6,0(sp)
    80000aae:	6121                	addi	sp,sp,64
    80000ab0:	8082                	ret

0000000080000ab2 <kinit>:
{
    80000ab2:	1141                	addi	sp,sp,-16
    80000ab4:	e406                	sd	ra,8(sp)
    80000ab6:	e022                	sd	s0,0(sp)
    80000ab8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aba:	00006597          	auipc	a1,0x6
    80000abe:	5c658593          	addi	a1,a1,1478 # 80007080 <digits+0x48>
    80000ac2:	0000f517          	auipc	a0,0xf
    80000ac6:	ee650513          	addi	a0,a0,-282 # 8000f9a8 <kmem>
    80000aca:	11e000ef          	jal	ra,80000be8 <initlock>
  for(int i = 0; i < PHYSTOP / PGSIZE; i++)
    80000ace:	0000f797          	auipc	a5,0xf
    80000ad2:	efa78793          	addi	a5,a5,-262 # 8000f9c8 <ref_count>
    80000ad6:	0022f717          	auipc	a4,0x22f
    80000ada:	ef270713          	addi	a4,a4,-270 # 8022f9c8 <pid_lock>
    ref_count[i] = 0;
    80000ade:	0007a023          	sw	zero,0(a5)
  for(int i = 0; i < PHYSTOP / PGSIZE; i++)
    80000ae2:	0791                	addi	a5,a5,4
    80000ae4:	fee79de3          	bne	a5,a4,80000ade <kinit+0x2c>
  freerange(end, (void*)PHYSTOP);
    80000ae8:	45c5                	li	a1,17
    80000aea:	05ee                	slli	a1,a1,0x1b
    80000aec:	00240517          	auipc	a0,0x240
    80000af0:	4ec50513          	addi	a0,a0,1260 # 80240fd8 <end>
    80000af4:	f59ff0ef          	jal	ra,80000a4c <freerange>
}
    80000af8:	60a2                	ld	ra,8(sp)
    80000afa:	6402                	ld	s0,0(sp)
    80000afc:	0141                	addi	sp,sp,16
    80000afe:	8082                	ret

0000000080000b00 <kalloc>:

// Allocate one 4096-byte page of physical memory.
void *
kalloc(void)
{
    80000b00:	1101                	addi	sp,sp,-32
    80000b02:	ec06                	sd	ra,24(sp)
    80000b04:	e822                	sd	s0,16(sp)
    80000b06:	e426                	sd	s1,8(sp)
    80000b08:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b0a:	0000f497          	auipc	s1,0xf
    80000b0e:	e9e48493          	addi	s1,s1,-354 # 8000f9a8 <kmem>
    80000b12:	8526                	mv	a0,s1
    80000b14:	154000ef          	jal	ra,80000c68 <acquire>
  r = kmem.freelist;
    80000b18:	6c84                	ld	s1,24(s1)
  if(r)
    80000b1a:	cc9d                	beqz	s1,80000b58 <kalloc+0x58>
    kmem.freelist = r->next;
    80000b1c:	609c                	ld	a5,0(s1)
    80000b1e:	0000f517          	auipc	a0,0xf
    80000b22:	e8a50513          	addi	a0,a0,-374 # 8000f9a8 <kmem>
    80000b26:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b28:	1d8000ef          	jal	ra,80000d00 <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2c:	6605                	lui	a2,0x1
    80000b2e:	4595                	li	a1,5
    80000b30:	8526                	mv	a0,s1
    80000b32:	20a000ef          	jal	ra,80000d3c <memset>
    ref_count[PA2IDX(r)] = 1;    // 🔥 new page has 1 reference
    80000b36:	00c4d793          	srli	a5,s1,0xc
    80000b3a:	00279713          	slli	a4,a5,0x2
    80000b3e:	0000f797          	auipc	a5,0xf
    80000b42:	e8a78793          	addi	a5,a5,-374 # 8000f9c8 <ref_count>
    80000b46:	97ba                	add	a5,a5,a4
    80000b48:	4705                	li	a4,1
    80000b4a:	c398                	sw	a4,0(a5)
  }

  return (void*)r;
}
    80000b4c:	8526                	mv	a0,s1
    80000b4e:	60e2                	ld	ra,24(sp)
    80000b50:	6442                	ld	s0,16(sp)
    80000b52:	64a2                	ld	s1,8(sp)
    80000b54:	6105                	addi	sp,sp,32
    80000b56:	8082                	ret
  release(&kmem.lock);
    80000b58:	0000f517          	auipc	a0,0xf
    80000b5c:	e5050513          	addi	a0,a0,-432 # 8000f9a8 <kmem>
    80000b60:	1a0000ef          	jal	ra,80000d00 <release>
  if(r){
    80000b64:	b7e5                	j	80000b4c <kalloc+0x4c>

0000000080000b66 <incref>:

// 🔥 Increment reference count
void
incref(uint64 pa)
{
    80000b66:	1101                	addi	sp,sp,-32
    80000b68:	ec06                	sd	ra,24(sp)
    80000b6a:	e822                	sd	s0,16(sp)
    80000b6c:	e426                	sd	s1,8(sp)
    80000b6e:	e04a                	sd	s2,0(sp)
    80000b70:	1000                	addi	s0,sp,32
    80000b72:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000b74:	0000f917          	auipc	s2,0xf
    80000b78:	e3490913          	addi	s2,s2,-460 # 8000f9a8 <kmem>
    80000b7c:	854a                	mv	a0,s2
    80000b7e:	0ea000ef          	jal	ra,80000c68 <acquire>
  ref_count[PA2IDX(pa)]++;
    80000b82:	80b1                	srli	s1,s1,0xc
    80000b84:	048a                	slli	s1,s1,0x2
    80000b86:	0000f797          	auipc	a5,0xf
    80000b8a:	e4278793          	addi	a5,a5,-446 # 8000f9c8 <ref_count>
    80000b8e:	94be                	add	s1,s1,a5
    80000b90:	409c                	lw	a5,0(s1)
    80000b92:	2785                	addiw	a5,a5,1
    80000b94:	c09c                	sw	a5,0(s1)
  release(&kmem.lock);
    80000b96:	854a                	mv	a0,s2
    80000b98:	168000ef          	jal	ra,80000d00 <release>
}
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6902                	ld	s2,0(sp)
    80000ba4:	6105                	addi	sp,sp,32
    80000ba6:	8082                	ret

0000000080000ba8 <getref>:

// 🔥 Get reference count
int
getref(uint64 pa)
{
    80000ba8:	1101                	addi	sp,sp,-32
    80000baa:	ec06                	sd	ra,24(sp)
    80000bac:	e822                	sd	s0,16(sp)
    80000bae:	e426                	sd	s1,8(sp)
    80000bb0:	e04a                	sd	s2,0(sp)
    80000bb2:	1000                	addi	s0,sp,32
    80000bb4:	84aa                	mv	s1,a0
  int count;
  acquire(&kmem.lock);
    80000bb6:	0000f917          	auipc	s2,0xf
    80000bba:	df290913          	addi	s2,s2,-526 # 8000f9a8 <kmem>
    80000bbe:	854a                	mv	a0,s2
    80000bc0:	0a8000ef          	jal	ra,80000c68 <acquire>
  count = ref_count[PA2IDX(pa)];
    80000bc4:	80b1                	srli	s1,s1,0xc
    80000bc6:	048a                	slli	s1,s1,0x2
    80000bc8:	0000f797          	auipc	a5,0xf
    80000bcc:	e0078793          	addi	a5,a5,-512 # 8000f9c8 <ref_count>
    80000bd0:	94be                	add	s1,s1,a5
    80000bd2:	4084                	lw	s1,0(s1)
  release(&kmem.lock);
    80000bd4:	854a                	mv	a0,s2
    80000bd6:	12a000ef          	jal	ra,80000d00 <release>
  return count;
    80000bda:	8526                	mv	a0,s1
    80000bdc:	60e2                	ld	ra,24(sp)
    80000bde:	6442                	ld	s0,16(sp)
    80000be0:	64a2                	ld	s1,8(sp)
    80000be2:	6902                	ld	s2,0(sp)
    80000be4:	6105                	addi	sp,sp,32
    80000be6:	8082                	ret

0000000080000be8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000be8:	1141                	addi	sp,sp,-16
    80000bea:	e422                	sd	s0,8(sp)
    80000bec:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bee:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bf0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bf4:	00053823          	sd	zero,16(a0)
}
    80000bf8:	6422                	ld	s0,8(sp)
    80000bfa:	0141                	addi	sp,sp,16
    80000bfc:	8082                	ret

0000000080000bfe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bfe:	411c                	lw	a5,0(a0)
    80000c00:	e399                	bnez	a5,80000c06 <holding+0x8>
    80000c02:	4501                	li	a0,0
  return r;
}
    80000c04:	8082                	ret
{
    80000c06:	1101                	addi	sp,sp,-32
    80000c08:	ec06                	sd	ra,24(sp)
    80000c0a:	e822                	sd	s0,16(sp)
    80000c0c:	e426                	sd	s1,8(sp)
    80000c0e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c10:	6904                	ld	s1,16(a0)
    80000c12:	531000ef          	jal	ra,80001942 <mycpu>
    80000c16:	40a48533          	sub	a0,s1,a0
    80000c1a:	00153513          	seqz	a0,a0
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret

0000000080000c28 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c32:	100024f3          	csrr	s1,sstatus
    80000c36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c3c:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000c40:	503000ef          	jal	ra,80001942 <mycpu>
    80000c44:	5d3c                	lw	a5,120(a0)
    80000c46:	cb99                	beqz	a5,80000c5c <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c48:	4fb000ef          	jal	ra,80001942 <mycpu>
    80000c4c:	5d3c                	lw	a5,120(a0)
    80000c4e:	2785                	addiw	a5,a5,1
    80000c50:	dd3c                	sw	a5,120(a0)
}
    80000c52:	60e2                	ld	ra,24(sp)
    80000c54:	6442                	ld	s0,16(sp)
    80000c56:	64a2                	ld	s1,8(sp)
    80000c58:	6105                	addi	sp,sp,32
    80000c5a:	8082                	ret
    mycpu()->intena = old;
    80000c5c:	4e7000ef          	jal	ra,80001942 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c60:	8085                	srli	s1,s1,0x1
    80000c62:	8885                	andi	s1,s1,1
    80000c64:	dd64                	sw	s1,124(a0)
    80000c66:	b7cd                	j	80000c48 <push_off+0x20>

0000000080000c68 <acquire>:
{
    80000c68:	1101                	addi	sp,sp,-32
    80000c6a:	ec06                	sd	ra,24(sp)
    80000c6c:	e822                	sd	s0,16(sp)
    80000c6e:	e426                	sd	s1,8(sp)
    80000c70:	1000                	addi	s0,sp,32
    80000c72:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c74:	fb5ff0ef          	jal	ra,80000c28 <push_off>
  if(holding(lk))
    80000c78:	8526                	mv	a0,s1
    80000c7a:	f85ff0ef          	jal	ra,80000bfe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7e:	4705                	li	a4,1
  if(holding(lk))
    80000c80:	e105                	bnez	a0,80000ca0 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c82:	87ba                	mv	a5,a4
    80000c84:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c88:	2781                	sext.w	a5,a5
    80000c8a:	ffe5                	bnez	a5,80000c82 <acquire+0x1a>
  __sync_synchronize();
    80000c8c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c90:	4b3000ef          	jal	ra,80001942 <mycpu>
    80000c94:	e888                	sd	a0,16(s1)
}
    80000c96:	60e2                	ld	ra,24(sp)
    80000c98:	6442                	ld	s0,16(sp)
    80000c9a:	64a2                	ld	s1,8(sp)
    80000c9c:	6105                	addi	sp,sp,32
    80000c9e:	8082                	ret
    panic("acquire");
    80000ca0:	00006517          	auipc	a0,0x6
    80000ca4:	3e850513          	addi	a0,a0,1000 # 80007088 <digits+0x50>
    80000ca8:	ac3ff0ef          	jal	ra,8000076a <panic>

0000000080000cac <pop_off>:

void
pop_off(void)
{
    80000cac:	1141                	addi	sp,sp,-16
    80000cae:	e406                	sd	ra,8(sp)
    80000cb0:	e022                	sd	s0,0(sp)
    80000cb2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb4:	48f000ef          	jal	ra,80001942 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cbc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cbe:	e78d                	bnez	a5,80000ce8 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc0:	5d3c                	lw	a5,120(a0)
    80000cc2:	02f05963          	blez	a5,80000cf4 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000cc6:	37fd                	addiw	a5,a5,-1
    80000cc8:	0007871b          	sext.w	a4,a5
    80000ccc:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cce:	eb09                	bnez	a4,80000ce0 <pop_off+0x34>
    80000cd0:	5d7c                	lw	a5,124(a0)
    80000cd2:	c799                	beqz	a5,80000ce0 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cd8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cdc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce0:	60a2                	ld	ra,8(sp)
    80000ce2:	6402                	ld	s0,0(sp)
    80000ce4:	0141                	addi	sp,sp,16
    80000ce6:	8082                	ret
    panic("pop_off - interruptible");
    80000ce8:	00006517          	auipc	a0,0x6
    80000cec:	3a850513          	addi	a0,a0,936 # 80007090 <digits+0x58>
    80000cf0:	a7bff0ef          	jal	ra,8000076a <panic>
    panic("pop_off");
    80000cf4:	00006517          	auipc	a0,0x6
    80000cf8:	3b450513          	addi	a0,a0,948 # 800070a8 <digits+0x70>
    80000cfc:	a6fff0ef          	jal	ra,8000076a <panic>

0000000080000d00 <release>:
{
    80000d00:	1101                	addi	sp,sp,-32
    80000d02:	ec06                	sd	ra,24(sp)
    80000d04:	e822                	sd	s0,16(sp)
    80000d06:	e426                	sd	s1,8(sp)
    80000d08:	1000                	addi	s0,sp,32
    80000d0a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d0c:	ef3ff0ef          	jal	ra,80000bfe <holding>
    80000d10:	c105                	beqz	a0,80000d30 <release+0x30>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	f8bff0ef          	jal	ra,80000cac <pop_off>
}
    80000d26:	60e2                	ld	ra,24(sp)
    80000d28:	6442                	ld	s0,16(sp)
    80000d2a:	64a2                	ld	s1,8(sp)
    80000d2c:	6105                	addi	sp,sp,32
    80000d2e:	8082                	ret
    panic("release");
    80000d30:	00006517          	auipc	a0,0x6
    80000d34:	38050513          	addi	a0,a0,896 # 800070b0 <digits+0x78>
    80000d38:	a33ff0ef          	jal	ra,8000076a <panic>

0000000080000d3c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d3c:	1141                	addi	sp,sp,-16
    80000d3e:	e422                	sd	s0,8(sp)
    80000d40:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d42:	ca19                	beqz	a2,80000d58 <memset+0x1c>
    80000d44:	87aa                	mv	a5,a0
    80000d46:	1602                	slli	a2,a2,0x20
    80000d48:	9201                	srli	a2,a2,0x20
    80000d4a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d4e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d52:	0785                	addi	a5,a5,1
    80000d54:	fee79de3          	bne	a5,a4,80000d4e <memset+0x12>
  }
  return dst;
}
    80000d58:	6422                	ld	s0,8(sp)
    80000d5a:	0141                	addi	sp,sp,16
    80000d5c:	8082                	ret

0000000080000d5e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d5e:	1141                	addi	sp,sp,-16
    80000d60:	e422                	sd	s0,8(sp)
    80000d62:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d64:	ca05                	beqz	a2,80000d94 <memcmp+0x36>
    80000d66:	fff6069b          	addiw	a3,a2,-1
    80000d6a:	1682                	slli	a3,a3,0x20
    80000d6c:	9281                	srli	a3,a3,0x20
    80000d6e:	0685                	addi	a3,a3,1
    80000d70:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d72:	00054783          	lbu	a5,0(a0)
    80000d76:	0005c703          	lbu	a4,0(a1)
    80000d7a:	00e79863          	bne	a5,a4,80000d8a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d7e:	0505                	addi	a0,a0,1
    80000d80:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d82:	fed518e3          	bne	a0,a3,80000d72 <memcmp+0x14>
  }

  return 0;
    80000d86:	4501                	li	a0,0
    80000d88:	a019                	j	80000d8e <memcmp+0x30>
      return *s1 - *s2;
    80000d8a:	40e7853b          	subw	a0,a5,a4
}
    80000d8e:	6422                	ld	s0,8(sp)
    80000d90:	0141                	addi	sp,sp,16
    80000d92:	8082                	ret
  return 0;
    80000d94:	4501                	li	a0,0
    80000d96:	bfe5                	j	80000d8e <memcmp+0x30>

0000000080000d98 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d98:	1141                	addi	sp,sp,-16
    80000d9a:	e422                	sd	s0,8(sp)
    80000d9c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d9e:	c205                	beqz	a2,80000dbe <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da0:	02a5e263          	bltu	a1,a0,80000dc4 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da4:	1602                	slli	a2,a2,0x20
    80000da6:	9201                	srli	a2,a2,0x20
    80000da8:	00c587b3          	add	a5,a1,a2
{
    80000dac:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dae:	0585                	addi	a1,a1,1
    80000db0:	0705                	addi	a4,a4,1
    80000db2:	fff5c683          	lbu	a3,-1(a1)
    80000db6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dba:	fef59ae3          	bne	a1,a5,80000dae <memmove+0x16>

  return dst;
}
    80000dbe:	6422                	ld	s0,8(sp)
    80000dc0:	0141                	addi	sp,sp,16
    80000dc2:	8082                	ret
  if(s < d && s + n > d){
    80000dc4:	02061693          	slli	a3,a2,0x20
    80000dc8:	9281                	srli	a3,a3,0x20
    80000dca:	00d58733          	add	a4,a1,a3
    80000dce:	fce57be3          	bgeu	a0,a4,80000da4 <memmove+0xc>
    d += n;
    80000dd2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dd4:	fff6079b          	addiw	a5,a2,-1
    80000dd8:	1782                	slli	a5,a5,0x20
    80000dda:	9381                	srli	a5,a5,0x20
    80000ddc:	fff7c793          	not	a5,a5
    80000de0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000de2:	177d                	addi	a4,a4,-1
    80000de4:	16fd                	addi	a3,a3,-1
    80000de6:	00074603          	lbu	a2,0(a4)
    80000dea:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dee:	fee79ae3          	bne	a5,a4,80000de2 <memmove+0x4a>
    80000df2:	b7f1                	j	80000dbe <memmove+0x26>

0000000080000df4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e406                	sd	ra,8(sp)
    80000df8:	e022                	sd	s0,0(sp)
    80000dfa:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dfc:	f9dff0ef          	jal	ra,80000d98 <memmove>
}
    80000e00:	60a2                	ld	ra,8(sp)
    80000e02:	6402                	ld	s0,0(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret

0000000080000e08 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e08:	1141                	addi	sp,sp,-16
    80000e0a:	e422                	sd	s0,8(sp)
    80000e0c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0e:	ce11                	beqz	a2,80000e2a <strncmp+0x22>
    80000e10:	00054783          	lbu	a5,0(a0)
    80000e14:	cf89                	beqz	a5,80000e2e <strncmp+0x26>
    80000e16:	0005c703          	lbu	a4,0(a1)
    80000e1a:	00f71a63          	bne	a4,a5,80000e2e <strncmp+0x26>
    n--, p++, q++;
    80000e1e:	367d                	addiw	a2,a2,-1
    80000e20:	0505                	addi	a0,a0,1
    80000e22:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e24:	f675                	bnez	a2,80000e10 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e26:	4501                	li	a0,0
    80000e28:	a809                	j	80000e3a <strncmp+0x32>
    80000e2a:	4501                	li	a0,0
    80000e2c:	a039                	j	80000e3a <strncmp+0x32>
  if(n == 0)
    80000e2e:	ca09                	beqz	a2,80000e40 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e30:	00054503          	lbu	a0,0(a0)
    80000e34:	0005c783          	lbu	a5,0(a1)
    80000e38:	9d1d                	subw	a0,a0,a5
}
    80000e3a:	6422                	ld	s0,8(sp)
    80000e3c:	0141                	addi	sp,sp,16
    80000e3e:	8082                	ret
    return 0;
    80000e40:	4501                	li	a0,0
    80000e42:	bfe5                	j	80000e3a <strncmp+0x32>

0000000080000e44 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e4a:	872a                	mv	a4,a0
    80000e4c:	8832                	mv	a6,a2
    80000e4e:	367d                	addiw	a2,a2,-1
    80000e50:	01005963          	blez	a6,80000e62 <strncpy+0x1e>
    80000e54:	0705                	addi	a4,a4,1
    80000e56:	0005c783          	lbu	a5,0(a1)
    80000e5a:	fef70fa3          	sb	a5,-1(a4)
    80000e5e:	0585                	addi	a1,a1,1
    80000e60:	f7f5                	bnez	a5,80000e4c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e62:	86ba                	mv	a3,a4
    80000e64:	00c05c63          	blez	a2,80000e7c <strncpy+0x38>
    *s++ = 0;
    80000e68:	0685                	addi	a3,a3,1
    80000e6a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e6e:	fff6c793          	not	a5,a3
    80000e72:	9fb9                	addw	a5,a5,a4
    80000e74:	010787bb          	addw	a5,a5,a6
    80000e78:	fef048e3          	bgtz	a5,80000e68 <strncpy+0x24>
  return os;
}
    80000e7c:	6422                	ld	s0,8(sp)
    80000e7e:	0141                	addi	sp,sp,16
    80000e80:	8082                	ret

0000000080000e82 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e88:	02c05363          	blez	a2,80000eae <safestrcpy+0x2c>
    80000e8c:	fff6069b          	addiw	a3,a2,-1
    80000e90:	1682                	slli	a3,a3,0x20
    80000e92:	9281                	srli	a3,a3,0x20
    80000e94:	96ae                	add	a3,a3,a1
    80000e96:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e98:	00d58963          	beq	a1,a3,80000eaa <safestrcpy+0x28>
    80000e9c:	0585                	addi	a1,a1,1
    80000e9e:	0785                	addi	a5,a5,1
    80000ea0:	fff5c703          	lbu	a4,-1(a1)
    80000ea4:	fee78fa3          	sb	a4,-1(a5)
    80000ea8:	fb65                	bnez	a4,80000e98 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eaa:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eae:	6422                	ld	s0,8(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret

0000000080000eb4 <strlen>:

int
strlen(const char *s)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eba:	00054783          	lbu	a5,0(a0)
    80000ebe:	cf91                	beqz	a5,80000eda <strlen+0x26>
    80000ec0:	0505                	addi	a0,a0,1
    80000ec2:	87aa                	mv	a5,a0
    80000ec4:	4685                	li	a3,1
    80000ec6:	9e89                	subw	a3,a3,a0
    80000ec8:	00f6853b          	addw	a0,a3,a5
    80000ecc:	0785                	addi	a5,a5,1
    80000ece:	fff7c703          	lbu	a4,-1(a5)
    80000ed2:	fb7d                	bnez	a4,80000ec8 <strlen+0x14>
    ;
  return n;
}
    80000ed4:	6422                	ld	s0,8(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eda:	4501                	li	a0,0
    80000edc:	bfe5                	j	80000ed4 <strlen+0x20>

0000000080000ede <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e406                	sd	ra,8(sp)
    80000ee2:	e022                	sd	s0,0(sp)
    80000ee4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ee6:	24d000ef          	jal	ra,80001932 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eea:	00007717          	auipc	a4,0x7
    80000eee:	9b670713          	addi	a4,a4,-1610 # 800078a0 <started>
  if(cpuid() == 0){
    80000ef2:	c51d                	beqz	a0,80000f20 <main+0x42>
    while(started == 0)
    80000ef4:	431c                	lw	a5,0(a4)
    80000ef6:	2781                	sext.w	a5,a5
    80000ef8:	dff5                	beqz	a5,80000ef4 <main+0x16>
      ;
    __sync_synchronize();
    80000efa:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000efe:	235000ef          	jal	ra,80001932 <cpuid>
    80000f02:	85aa                	mv	a1,a0
    80000f04:	00006517          	auipc	a0,0x6
    80000f08:	1cc50513          	addi	a0,a0,460 # 800070d0 <digits+0x98>
    80000f0c:	d98ff0ef          	jal	ra,800004a4 <printf>
    kvminithart();    // turn on paging
    80000f10:	080000ef          	jal	ra,80000f90 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f14:	6c6010ef          	jal	ra,800025da <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f18:	5cc040ef          	jal	ra,800054e4 <plicinithart>
  }

  scheduler();        
    80000f1c:	6d3000ef          	jal	ra,80001dee <scheduler>
    consoleinit();
    80000f20:	cacff0ef          	jal	ra,800003cc <consoleinit>
    printfinit();
    80000f24:	883ff0ef          	jal	ra,800007a6 <printfinit>
    printf("\n");
    80000f28:	00006517          	auipc	a0,0x6
    80000f2c:	1b850513          	addi	a0,a0,440 # 800070e0 <digits+0xa8>
    80000f30:	d74ff0ef          	jal	ra,800004a4 <printf>
    printf("xv6 kernel is booting\n");
    80000f34:	00006517          	auipc	a0,0x6
    80000f38:	18450513          	addi	a0,a0,388 # 800070b8 <digits+0x80>
    80000f3c:	d68ff0ef          	jal	ra,800004a4 <printf>
    printf("\n");
    80000f40:	00006517          	auipc	a0,0x6
    80000f44:	1a050513          	addi	a0,a0,416 # 800070e0 <digits+0xa8>
    80000f48:	d5cff0ef          	jal	ra,800004a4 <printf>
    kinit();         // physical page allocator
    80000f4c:	b67ff0ef          	jal	ra,80000ab2 <kinit>
    kvminit();       // create kernel page table
    80000f50:	2ca000ef          	jal	ra,8000121a <kvminit>
    kvminithart();   // turn on paging
    80000f54:	03c000ef          	jal	ra,80000f90 <kvminithart>
    procinit();      // process table
    80000f58:	133000ef          	jal	ra,8000188a <procinit>
    trapinit();      // trap vectors
    80000f5c:	65a010ef          	jal	ra,800025b6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f60:	67a010ef          	jal	ra,800025da <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	56a040ef          	jal	ra,800054ce <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f68:	57c040ef          	jal	ra,800054e4 <plicinithart>
    binit();         // buffer cache
    80000f6c:	515010ef          	jal	ra,80002c80 <binit>
    iinit();         // inode table
    80000f70:	288020ef          	jal	ra,800031f8 <iinit>
    fileinit();      // file table
    80000f74:	168030ef          	jal	ra,800040dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f78:	65c040ef          	jal	ra,800055d4 <virtio_disk_init>
    userinit();      // first user process
    80000f7c:	4b9000ef          	jal	ra,80001c34 <userinit>
    __sync_synchronize();
    80000f80:	0ff0000f          	fence
    started = 1;
    80000f84:	4785                	li	a5,1
    80000f86:	00007717          	auipc	a4,0x7
    80000f8a:	90f72d23          	sw	a5,-1766(a4) # 800078a0 <started>
    80000f8e:	b779                	j	80000f1c <main+0x3e>

0000000080000f90 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f90:	1141                	addi	sp,sp,-16
    80000f92:	e422                	sd	s0,8(sp)
    80000f94:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f96:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f9a:	00007797          	auipc	a5,0x7
    80000f9e:	90e7b783          	ld	a5,-1778(a5) # 800078a8 <kernel_pagetable>
    80000fa2:	83b1                	srli	a5,a5,0xc
    80000fa4:	577d                	li	a4,-1
    80000fa6:	177e                	slli	a4,a4,0x3f
    80000fa8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000faa:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fae:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb2:	6422                	ld	s0,8(sp)
    80000fb4:	0141                	addi	sp,sp,16
    80000fb6:	8082                	ret

0000000080000fb8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb8:	7139                	addi	sp,sp,-64
    80000fba:	fc06                	sd	ra,56(sp)
    80000fbc:	f822                	sd	s0,48(sp)
    80000fbe:	f426                	sd	s1,40(sp)
    80000fc0:	f04a                	sd	s2,32(sp)
    80000fc2:	ec4e                	sd	s3,24(sp)
    80000fc4:	e852                	sd	s4,16(sp)
    80000fc6:	e456                	sd	s5,8(sp)
    80000fc8:	e05a                	sd	s6,0(sp)
    80000fca:	0080                	addi	s0,sp,64
    80000fcc:	84aa                	mv	s1,a0
    80000fce:	89ae                	mv	s3,a1
    80000fd0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd2:	57fd                	li	a5,-1
    80000fd4:	83e9                	srli	a5,a5,0x1a
    80000fd6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fda:	02b7fc63          	bgeu	a5,a1,80001012 <walk+0x5a>
    panic("walk");
    80000fde:	00006517          	auipc	a0,0x6
    80000fe2:	10a50513          	addi	a0,a0,266 # 800070e8 <digits+0xb0>
    80000fe6:	f84ff0ef          	jal	ra,8000076a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fea:	060a8263          	beqz	s5,8000104e <walk+0x96>
    80000fee:	b13ff0ef          	jal	ra,80000b00 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c139                	beqz	a0,8000103a <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	d43ff0ef          	jal	ra,80000d3c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	d3f1                	beqz	a5,80000fea <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x82>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	f51ff0ef          	jal	ra,80000fb8 <walk>
  if(pte == 0)
    8000106c:	c105                	beqz	a0,8000108c <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    8000106e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001070:	0117f693          	andi	a3,a5,17
    80001074:	4745                	li	a4,17
    return 0;
    80001076:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001078:	00e68663          	beq	a3,a4,80001084 <walkaddr+0x32>
}
    8000107c:	60a2                	ld	ra,8(sp)
    8000107e:	6402                	ld	s0,0(sp)
    80001080:	0141                	addi	sp,sp,16
    80001082:	8082                	ret
  pa = PTE2PA(*pte);
    80001084:	00a7d513          	srli	a0,a5,0xa
    80001088:	0532                	slli	a0,a0,0xc
  return pa;
    8000108a:	bfcd                	j	8000107c <walkaddr+0x2a>
    return 0;
    8000108c:	4501                	li	a0,0
    8000108e:	b7fd                	j	8000107c <walkaddr+0x2a>

0000000080001090 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001090:	715d                	addi	sp,sp,-80
    80001092:	e486                	sd	ra,72(sp)
    80001094:	e0a2                	sd	s0,64(sp)
    80001096:	fc26                	sd	s1,56(sp)
    80001098:	f84a                	sd	s2,48(sp)
    8000109a:	f44e                	sd	s3,40(sp)
    8000109c:	f052                	sd	s4,32(sp)
    8000109e:	ec56                	sd	s5,24(sp)
    800010a0:	e85a                	sd	s6,16(sp)
    800010a2:	e45e                	sd	s7,8(sp)
    800010a4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800010a6:	03459793          	slli	a5,a1,0x34
    800010aa:	e7a9                	bnez	a5,800010f4 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    800010b0:	03461793          	slli	a5,a2,0x34
    800010b4:	e7b1                	bnez	a5,80001100 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    800010b6:	ca39                	beqz	a2,8000110c <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    800010b8:	79fd                	lui	s3,0xfffff
    800010ba:	964e                	add	a2,a2,s3
    800010bc:	00b609b3          	add	s3,a2,a1
  a = va;
    800010c0:	892e                	mv	s2,a1
    800010c2:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	ee7ff0ef          	jal	ra,80000fb8 <walk>
    800010d6:	c539                	beqz	a0,80001124 <mappages+0x94>
    if(*pte & PTE_V)
    800010d8:	611c                	ld	a5,0(a0)
    800010da:	8b85                	andi	a5,a5,1
    800010dc:	ef95                	bnez	a5,80001118 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010de:	80b1                	srli	s1,s1,0xc
    800010e0:	04aa                	slli	s1,s1,0xa
    800010e2:	0164e4b3          	or	s1,s1,s6
    800010e6:	0014e493          	ori	s1,s1,1
    800010ea:	e104                	sd	s1,0(a0)
    if(a == last)
    800010ec:	05390863          	beq	s2,s3,8000113c <mappages+0xac>
    a += PGSIZE;
    800010f0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f2:	bfd9                	j	800010c8 <mappages+0x38>
    panic("mappages: va not aligned");
    800010f4:	00006517          	auipc	a0,0x6
    800010f8:	ffc50513          	addi	a0,a0,-4 # 800070f0 <digits+0xb8>
    800010fc:	e6eff0ef          	jal	ra,8000076a <panic>
    panic("mappages: size not aligned");
    80001100:	00006517          	auipc	a0,0x6
    80001104:	01050513          	addi	a0,a0,16 # 80007110 <digits+0xd8>
    80001108:	e62ff0ef          	jal	ra,8000076a <panic>
    panic("mappages: size");
    8000110c:	00006517          	auipc	a0,0x6
    80001110:	02450513          	addi	a0,a0,36 # 80007130 <digits+0xf8>
    80001114:	e56ff0ef          	jal	ra,8000076a <panic>
      panic("mappages: remap");
    80001118:	00006517          	auipc	a0,0x6
    8000111c:	02850513          	addi	a0,a0,40 # 80007140 <digits+0x108>
    80001120:	e4aff0ef          	jal	ra,8000076a <panic>
      return -1;
    80001124:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001126:	60a6                	ld	ra,72(sp)
    80001128:	6406                	ld	s0,64(sp)
    8000112a:	74e2                	ld	s1,56(sp)
    8000112c:	7942                	ld	s2,48(sp)
    8000112e:	79a2                	ld	s3,40(sp)
    80001130:	7a02                	ld	s4,32(sp)
    80001132:	6ae2                	ld	s5,24(sp)
    80001134:	6b42                	ld	s6,16(sp)
    80001136:	6ba2                	ld	s7,8(sp)
    80001138:	6161                	addi	sp,sp,80
    8000113a:	8082                	ret
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	b7e5                	j	80001126 <mappages+0x96>

0000000080001140 <kvmmap>:
{
    80001140:	1141                	addi	sp,sp,-16
    80001142:	e406                	sd	ra,8(sp)
    80001144:	e022                	sd	s0,0(sp)
    80001146:	0800                	addi	s0,sp,16
    80001148:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000114a:	86b2                	mv	a3,a2
    8000114c:	863e                	mv	a2,a5
    8000114e:	f43ff0ef          	jal	ra,80001090 <mappages>
    80001152:	e509                	bnez	a0,8000115c <kvmmap+0x1c>
}
    80001154:	60a2                	ld	ra,8(sp)
    80001156:	6402                	ld	s0,0(sp)
    80001158:	0141                	addi	sp,sp,16
    8000115a:	8082                	ret
    panic("kvmmap");
    8000115c:	00006517          	auipc	a0,0x6
    80001160:	ff450513          	addi	a0,a0,-12 # 80007150 <digits+0x118>
    80001164:	e06ff0ef          	jal	ra,8000076a <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	addi	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	98dff0ef          	jal	ra,80000b00 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	bbfff0ef          	jal	ra,80000d3c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001182:	4719                	li	a4,6
    80001184:	6685                	lui	a3,0x1
    80001186:	10000637          	lui	a2,0x10000
    8000118a:	100005b7          	lui	a1,0x10000
    8000118e:	8526                	mv	a0,s1
    80001190:	fb1ff0ef          	jal	ra,80001140 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001194:	4719                	li	a4,6
    80001196:	6685                	lui	a3,0x1
    80001198:	10001637          	lui	a2,0x10001
    8000119c:	100015b7          	lui	a1,0x10001
    800011a0:	8526                	mv	a0,s1
    800011a2:	f9fff0ef          	jal	ra,80001140 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	040006b7          	lui	a3,0x4000
    800011ac:	0c000637          	lui	a2,0xc000
    800011b0:	0c0005b7          	lui	a1,0xc000
    800011b4:	8526                	mv	a0,s1
    800011b6:	f8bff0ef          	jal	ra,80001140 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ba:	00006917          	auipc	s2,0x6
    800011be:	e4690913          	addi	s2,s2,-442 # 80007000 <etext>
    800011c2:	4729                	li	a4,10
    800011c4:	80006697          	auipc	a3,0x80006
    800011c8:	e3c68693          	addi	a3,a3,-452 # 7000 <_entry-0x7fff9000>
    800011cc:	4605                	li	a2,1
    800011ce:	067e                	slli	a2,a2,0x1f
    800011d0:	85b2                	mv	a1,a2
    800011d2:	8526                	mv	a0,s1
    800011d4:	f6dff0ef          	jal	ra,80001140 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	46c5                	li	a3,17
    800011dc:	06ee                	slli	a3,a3,0x1b
    800011de:	412686b3          	sub	a3,a3,s2
    800011e2:	864a                	mv	a2,s2
    800011e4:	85ca                	mv	a1,s2
    800011e6:	8526                	mv	a0,s1
    800011e8:	f59ff0ef          	jal	ra,80001140 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00005617          	auipc	a2,0x5
    800011f4:	e1060613          	addi	a2,a2,-496 # 80006000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	f3fff0ef          	jal	ra,80001140 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001206:	8526                	mv	a0,s1
    80001208:	5f8000ef          	jal	ra,80001800 <proc_mapstacks>
}
    8000120c:	8526                	mv	a0,s1
    8000120e:	60e2                	ld	ra,24(sp)
    80001210:	6442                	ld	s0,16(sp)
    80001212:	64a2                	ld	s1,8(sp)
    80001214:	6902                	ld	s2,0(sp)
    80001216:	6105                	addi	sp,sp,32
    80001218:	8082                	ret

000000008000121a <kvminit>:
{
    8000121a:	1141                	addi	sp,sp,-16
    8000121c:	e406                	sd	ra,8(sp)
    8000121e:	e022                	sd	s0,0(sp)
    80001220:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001222:	f47ff0ef          	jal	ra,80001168 <kvmmake>
    80001226:	00006797          	auipc	a5,0x6
    8000122a:	68a7b123          	sd	a0,1666(a5) # 800078a8 <kernel_pagetable>
}
    8000122e:	60a2                	ld	ra,8(sp)
    80001230:	6402                	ld	s0,0(sp)
    80001232:	0141                	addi	sp,sp,16
    80001234:	8082                	ret

0000000080001236 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001236:	1101                	addi	sp,sp,-32
    80001238:	ec06                	sd	ra,24(sp)
    8000123a:	e822                	sd	s0,16(sp)
    8000123c:	e426                	sd	s1,8(sp)
    8000123e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001240:	8c1ff0ef          	jal	ra,80000b00 <kalloc>
    80001244:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001246:	c509                	beqz	a0,80001250 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001248:	6605                	lui	a2,0x1
    8000124a:	4581                	li	a1,0
    8000124c:	af1ff0ef          	jal	ra,80000d3c <memset>
  return pagetable;
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6105                	addi	sp,sp,32
    8000125a:	8082                	ret

000000008000125c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125c:	7139                	addi	sp,sp,-64
    8000125e:	fc06                	sd	ra,56(sp)
    80001260:	f822                	sd	s0,48(sp)
    80001262:	f426                	sd	s1,40(sp)
    80001264:	f04a                	sd	s2,32(sp)
    80001266:	ec4e                	sd	s3,24(sp)
    80001268:	e852                	sd	s4,16(sp)
    8000126a:	e456                	sd	s5,8(sp)
    8000126c:	e05a                	sd	s6,0(sp)
    8000126e:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e785                	bnez	a5,8000129c <uvmunmap+0x40>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    80001282:	6b05                	lui	s6,0x1
    80001284:	0335e763          	bltu	a1,s3,800012b2 <uvmunmap+0x56>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001288:	70e2                	ld	ra,56(sp)
    8000128a:	7442                	ld	s0,48(sp)
    8000128c:	74a2                	ld	s1,40(sp)
    8000128e:	7902                	ld	s2,32(sp)
    80001290:	69e2                	ld	s3,24(sp)
    80001292:	6a42                	ld	s4,16(sp)
    80001294:	6aa2                	ld	s5,8(sp)
    80001296:	6b02                	ld	s6,0(sp)
    80001298:	6121                	addi	sp,sp,64
    8000129a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000129c:	00006517          	auipc	a0,0x6
    800012a0:	ebc50513          	addi	a0,a0,-324 # 80007158 <digits+0x120>
    800012a4:	cc6ff0ef          	jal	ra,8000076a <panic>
    *pte = 0;
    800012a8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ac:	995a                	add	s2,s2,s6
    800012ae:	fd397de3          	bgeu	s2,s3,80001288 <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    800012b2:	4601                	li	a2,0
    800012b4:	85ca                	mv	a1,s2
    800012b6:	8552                	mv	a0,s4
    800012b8:	d01ff0ef          	jal	ra,80000fb8 <walk>
    800012bc:	84aa                	mv	s1,a0
    800012be:	d57d                	beqz	a0,800012ac <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    800012c0:	611c                	ld	a5,0(a0)
    800012c2:	0017f713          	andi	a4,a5,1
    800012c6:	d37d                	beqz	a4,800012ac <uvmunmap+0x50>
    if(do_free){
    800012c8:	fe0a80e3          	beqz	s5,800012a8 <uvmunmap+0x4c>
      uint64 pa = PTE2PA(*pte);
    800012cc:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012ce:	00c79513          	slli	a0,a5,0xc
    800012d2:	ecaff0ef          	jal	ra,8000099c <kfree>
    800012d6:	bfc9                	j	800012a8 <uvmunmap+0x4c>

00000000800012d8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800012d8:	1101                	addi	sp,sp,-32
    800012da:	ec06                	sd	ra,24(sp)
    800012dc:	e822                	sd	s0,16(sp)
    800012de:	e426                	sd	s1,8(sp)
    800012e0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800012e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800012e4:	00b67d63          	bgeu	a2,a1,800012fe <uvmdealloc+0x26>
    800012e8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800012ea:	6785                	lui	a5,0x1
    800012ec:	17fd                	addi	a5,a5,-1
    800012ee:	00f60733          	add	a4,a2,a5
    800012f2:	767d                	lui	a2,0xfffff
    800012f4:	8f71                	and	a4,a4,a2
    800012f6:	97ae                	add	a5,a5,a1
    800012f8:	8ff1                	and	a5,a5,a2
    800012fa:	00f76863          	bltu	a4,a5,8000130a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012fe:	8526                	mv	a0,s1
    80001300:	60e2                	ld	ra,24(sp)
    80001302:	6442                	ld	s0,16(sp)
    80001304:	64a2                	ld	s1,8(sp)
    80001306:	6105                	addi	sp,sp,32
    80001308:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000130a:	8f99                	sub	a5,a5,a4
    8000130c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000130e:	4685                	li	a3,1
    80001310:	0007861b          	sext.w	a2,a5
    80001314:	85ba                	mv	a1,a4
    80001316:	f47ff0ef          	jal	ra,8000125c <uvmunmap>
    8000131a:	b7d5                	j	800012fe <uvmdealloc+0x26>

000000008000131c <uvmalloc>:
  if(newsz < oldsz)
    8000131c:	08b66963          	bltu	a2,a1,800013ae <uvmalloc+0x92>
{
    80001320:	7139                	addi	sp,sp,-64
    80001322:	fc06                	sd	ra,56(sp)
    80001324:	f822                	sd	s0,48(sp)
    80001326:	f426                	sd	s1,40(sp)
    80001328:	f04a                	sd	s2,32(sp)
    8000132a:	ec4e                	sd	s3,24(sp)
    8000132c:	e852                	sd	s4,16(sp)
    8000132e:	e456                	sd	s5,8(sp)
    80001330:	e05a                	sd	s6,0(sp)
    80001332:	0080                	addi	s0,sp,64
    80001334:	8aaa                	mv	s5,a0
    80001336:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001338:	6985                	lui	s3,0x1
    8000133a:	19fd                	addi	s3,s3,-1
    8000133c:	95ce                	add	a1,a1,s3
    8000133e:	79fd                	lui	s3,0xfffff
    80001340:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001344:	06c9f763          	bgeu	s3,a2,800013b2 <uvmalloc+0x96>
    80001348:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000134a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000134e:	fb2ff0ef          	jal	ra,80000b00 <kalloc>
    80001352:	84aa                	mv	s1,a0
    if(mem == 0){
    80001354:	c11d                	beqz	a0,8000137a <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    80001356:	6605                	lui	a2,0x1
    80001358:	4581                	li	a1,0
    8000135a:	9e3ff0ef          	jal	ra,80000d3c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000135e:	875a                	mv	a4,s6
    80001360:	86a6                	mv	a3,s1
    80001362:	6605                	lui	a2,0x1
    80001364:	85ca                	mv	a1,s2
    80001366:	8556                	mv	a0,s5
    80001368:	d29ff0ef          	jal	ra,80001090 <mappages>
    8000136c:	e51d                	bnez	a0,8000139a <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000136e:	6785                	lui	a5,0x1
    80001370:	993e                	add	s2,s2,a5
    80001372:	fd496ee3          	bltu	s2,s4,8000134e <uvmalloc+0x32>
  return newsz;
    80001376:	8552                	mv	a0,s4
    80001378:	a039                	j	80001386 <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    8000137a:	864e                	mv	a2,s3
    8000137c:	85ca                	mv	a1,s2
    8000137e:	8556                	mv	a0,s5
    80001380:	f59ff0ef          	jal	ra,800012d8 <uvmdealloc>
      return 0;
    80001384:	4501                	li	a0,0
}
    80001386:	70e2                	ld	ra,56(sp)
    80001388:	7442                	ld	s0,48(sp)
    8000138a:	74a2                	ld	s1,40(sp)
    8000138c:	7902                	ld	s2,32(sp)
    8000138e:	69e2                	ld	s3,24(sp)
    80001390:	6a42                	ld	s4,16(sp)
    80001392:	6aa2                	ld	s5,8(sp)
    80001394:	6b02                	ld	s6,0(sp)
    80001396:	6121                	addi	sp,sp,64
    80001398:	8082                	ret
      kfree(mem);
    8000139a:	8526                	mv	a0,s1
    8000139c:	e00ff0ef          	jal	ra,8000099c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800013a0:	864e                	mv	a2,s3
    800013a2:	85ca                	mv	a1,s2
    800013a4:	8556                	mv	a0,s5
    800013a6:	f33ff0ef          	jal	ra,800012d8 <uvmdealloc>
      return 0;
    800013aa:	4501                	li	a0,0
    800013ac:	bfe9                	j	80001386 <uvmalloc+0x6a>
    return oldsz;
    800013ae:	852e                	mv	a0,a1
}
    800013b0:	8082                	ret
  return newsz;
    800013b2:	8532                	mv	a0,a2
    800013b4:	bfc9                	j	80001386 <uvmalloc+0x6a>

00000000800013b6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800013b6:	7179                	addi	sp,sp,-48
    800013b8:	f406                	sd	ra,40(sp)
    800013ba:	f022                	sd	s0,32(sp)
    800013bc:	ec26                	sd	s1,24(sp)
    800013be:	e84a                	sd	s2,16(sp)
    800013c0:	e44e                	sd	s3,8(sp)
    800013c2:	e052                	sd	s4,0(sp)
    800013c4:	1800                	addi	s0,sp,48
    800013c6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800013c8:	84aa                	mv	s1,a0
    800013ca:	6905                	lui	s2,0x1
    800013cc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013ce:	4985                	li	s3,1
    800013d0:	a811                	j	800013e4 <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800013d2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800013d4:	0532                	slli	a0,a0,0xc
    800013d6:	fe1ff0ef          	jal	ra,800013b6 <freewalk>
      pagetable[i] = 0;
    800013da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800013de:	04a1                	addi	s1,s1,8
    800013e0:	01248f63          	beq	s1,s2,800013fe <freewalk+0x48>
    pte_t pte = pagetable[i];
    800013e4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013e6:	00f57793          	andi	a5,a0,15
    800013ea:	ff3784e3          	beq	a5,s3,800013d2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800013ee:	8905                	andi	a0,a0,1
    800013f0:	d57d                	beqz	a0,800013de <freewalk+0x28>
      panic("freewalk: leaf");
    800013f2:	00006517          	auipc	a0,0x6
    800013f6:	d7e50513          	addi	a0,a0,-642 # 80007170 <digits+0x138>
    800013fa:	b70ff0ef          	jal	ra,8000076a <panic>
    }
  }
  kfree((void*)pagetable);
    800013fe:	8552                	mv	a0,s4
    80001400:	d9cff0ef          	jal	ra,8000099c <kfree>
}
    80001404:	70a2                	ld	ra,40(sp)
    80001406:	7402                	ld	s0,32(sp)
    80001408:	64e2                	ld	s1,24(sp)
    8000140a:	6942                	ld	s2,16(sp)
    8000140c:	69a2                	ld	s3,8(sp)
    8000140e:	6a02                	ld	s4,0(sp)
    80001410:	6145                	addi	sp,sp,48
    80001412:	8082                	ret

0000000080001414 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001414:	1101                	addi	sp,sp,-32
    80001416:	ec06                	sd	ra,24(sp)
    80001418:	e822                	sd	s0,16(sp)
    8000141a:	e426                	sd	s1,8(sp)
    8000141c:	1000                	addi	s0,sp,32
    8000141e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001420:	e989                	bnez	a1,80001432 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001422:	8526                	mv	a0,s1
    80001424:	f93ff0ef          	jal	ra,800013b6 <freewalk>
}
    80001428:	60e2                	ld	ra,24(sp)
    8000142a:	6442                	ld	s0,16(sp)
    8000142c:	64a2                	ld	s1,8(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001432:	6605                	lui	a2,0x1
    80001434:	167d                	addi	a2,a2,-1
    80001436:	962e                	add	a2,a2,a1
    80001438:	4685                	li	a3,1
    8000143a:	8231                	srli	a2,a2,0xc
    8000143c:	4581                	li	a1,0
    8000143e:	e1fff0ef          	jal	ra,8000125c <uvmunmap>
    80001442:	b7c5                	j	80001422 <uvmfree+0xe>

0000000080001444 <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001444:	c659                	beqz	a2,800014d2 <uvmcopy+0x8e>
{
    80001446:	7139                	addi	sp,sp,-64
    80001448:	fc06                	sd	ra,56(sp)
    8000144a:	f822                	sd	s0,48(sp)
    8000144c:	f426                	sd	s1,40(sp)
    8000144e:	f04a                	sd	s2,32(sp)
    80001450:	ec4e                	sd	s3,24(sp)
    80001452:	e852                	sd	s4,16(sp)
    80001454:	e456                	sd	s5,8(sp)
    80001456:	0080                	addi	s0,sp,64
    80001458:	8a2a                	mv	s4,a0
    8000145a:	8aae                	mv	s5,a1
    8000145c:	89b2                	mv	s3,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000145e:	4481                	li	s1,0
    80001460:	a831                	j	8000147c <uvmcopy+0x38>
    incref(pa);
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001462:	4685                	li	a3,1
    80001464:	00c4d613          	srli	a2,s1,0xc
    80001468:	4581                	li	a1,0
    8000146a:	8556                	mv	a0,s5
    8000146c:	df1ff0ef          	jal	ra,8000125c <uvmunmap>
  return -1;
    80001470:	557d                	li	a0,-1
    80001472:	a0b9                	j	800014c0 <uvmcopy+0x7c>
  for(i = 0; i < sz; i += PGSIZE){
    80001474:	6785                	lui	a5,0x1
    80001476:	94be                	add	s1,s1,a5
    80001478:	0534f363          	bgeu	s1,s3,800014be <uvmcopy+0x7a>
    if((pte = walk(old, i, 0)) == 0)
    8000147c:	4601                	li	a2,0
    8000147e:	85a6                	mv	a1,s1
    80001480:	8552                	mv	a0,s4
    80001482:	b37ff0ef          	jal	ra,80000fb8 <walk>
    80001486:	d57d                	beqz	a0,80001474 <uvmcopy+0x30>
    if((*pte & PTE_V) == 0)
    80001488:	6118                	ld	a4,0(a0)
    8000148a:	00177793          	andi	a5,a4,1
    8000148e:	d3fd                	beqz	a5,80001474 <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    80001490:	00a75913          	srli	s2,a4,0xa
    80001494:	0932                	slli	s2,s2,0xc
    *pte &= ~PTE_W;
    80001496:	ffb77793          	andi	a5,a4,-5
    *pte |= PTE_COW;
    8000149a:	1007e793          	ori	a5,a5,256
    8000149e:	e11c                	sd	a5,0(a0)
    if(mappages(new, i, PGSIZE, pa, (flags & ~PTE_W) | PTE_COW) != 0){
    800014a0:	2fb77713          	andi	a4,a4,763
    800014a4:	10076713          	ori	a4,a4,256
    800014a8:	86ca                	mv	a3,s2
    800014aa:	6605                	lui	a2,0x1
    800014ac:	85a6                	mv	a1,s1
    800014ae:	8556                	mv	a0,s5
    800014b0:	be1ff0ef          	jal	ra,80001090 <mappages>
    800014b4:	f55d                	bnez	a0,80001462 <uvmcopy+0x1e>
    incref(pa);
    800014b6:	854a                	mv	a0,s2
    800014b8:	eaeff0ef          	jal	ra,80000b66 <incref>
    800014bc:	bf65                	j	80001474 <uvmcopy+0x30>
  return 0;
    800014be:	4501                	li	a0,0
}
    800014c0:	70e2                	ld	ra,56(sp)
    800014c2:	7442                	ld	s0,48(sp)
    800014c4:	74a2                	ld	s1,40(sp)
    800014c6:	7902                	ld	s2,32(sp)
    800014c8:	69e2                	ld	s3,24(sp)
    800014ca:	6a42                	ld	s4,16(sp)
    800014cc:	6aa2                	ld	s5,8(sp)
    800014ce:	6121                	addi	sp,sp,64
    800014d0:	8082                	ret
  return 0;
    800014d2:	4501                	li	a0,0
}
    800014d4:	8082                	ret

00000000800014d6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800014d6:	1141                	addi	sp,sp,-16
    800014d8:	e406                	sd	ra,8(sp)
    800014da:	e022                	sd	s0,0(sp)
    800014dc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014de:	4601                	li	a2,0
    800014e0:	ad9ff0ef          	jal	ra,80000fb8 <walk>
  if(pte == 0)
    800014e4:	c901                	beqz	a0,800014f4 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014e6:	611c                	ld	a5,0(a0)
    800014e8:	9bbd                	andi	a5,a5,-17
    800014ea:	e11c                	sd	a5,0(a0)
}
    800014ec:	60a2                	ld	ra,8(sp)
    800014ee:	6402                	ld	s0,0(sp)
    800014f0:	0141                	addi	sp,sp,16
    800014f2:	8082                	ret
    panic("uvmclear");
    800014f4:	00006517          	auipc	a0,0x6
    800014f8:	c8c50513          	addi	a0,a0,-884 # 80007180 <digits+0x148>
    800014fc:	a6eff0ef          	jal	ra,8000076a <panic>

0000000080001500 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001500:	c2d5                	beqz	a3,800015a4 <copyinstr+0xa4>
{
    80001502:	715d                	addi	sp,sp,-80
    80001504:	e486                	sd	ra,72(sp)
    80001506:	e0a2                	sd	s0,64(sp)
    80001508:	fc26                	sd	s1,56(sp)
    8000150a:	f84a                	sd	s2,48(sp)
    8000150c:	f44e                	sd	s3,40(sp)
    8000150e:	f052                	sd	s4,32(sp)
    80001510:	ec56                	sd	s5,24(sp)
    80001512:	e85a                	sd	s6,16(sp)
    80001514:	e45e                	sd	s7,8(sp)
    80001516:	0880                	addi	s0,sp,80
    80001518:	8a2a                	mv	s4,a0
    8000151a:	8b2e                	mv	s6,a1
    8000151c:	8bb2                	mv	s7,a2
    8000151e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001520:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001522:	6985                	lui	s3,0x1
    80001524:	a035                	j	80001550 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001526:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000152a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000152c:	0017b793          	seqz	a5,a5
    80001530:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001534:	60a6                	ld	ra,72(sp)
    80001536:	6406                	ld	s0,64(sp)
    80001538:	74e2                	ld	s1,56(sp)
    8000153a:	7942                	ld	s2,48(sp)
    8000153c:	79a2                	ld	s3,40(sp)
    8000153e:	7a02                	ld	s4,32(sp)
    80001540:	6ae2                	ld	s5,24(sp)
    80001542:	6b42                	ld	s6,16(sp)
    80001544:	6ba2                	ld	s7,8(sp)
    80001546:	6161                	addi	sp,sp,80
    80001548:	8082                	ret
    srcva = va0 + PGSIZE;
    8000154a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000154e:	c4b9                	beqz	s1,8000159c <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    80001550:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001554:	85ca                	mv	a1,s2
    80001556:	8552                	mv	a0,s4
    80001558:	afbff0ef          	jal	ra,80001052 <walkaddr>
    if(pa0 == 0)
    8000155c:	c131                	beqz	a0,800015a0 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    8000155e:	41790833          	sub	a6,s2,s7
    80001562:	984e                	add	a6,a6,s3
    if(n > max)
    80001564:	0104f363          	bgeu	s1,a6,8000156a <copyinstr+0x6a>
    80001568:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000156a:	955e                	add	a0,a0,s7
    8000156c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001570:	fc080de3          	beqz	a6,8000154a <copyinstr+0x4a>
    80001574:	985a                	add	a6,a6,s6
    80001576:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001578:	41650633          	sub	a2,a0,s6
    8000157c:	14fd                	addi	s1,s1,-1
    8000157e:	9b26                	add	s6,s6,s1
    80001580:	00f60733          	add	a4,a2,a5
    80001584:	00074703          	lbu	a4,0(a4)
    80001588:	df59                	beqz	a4,80001526 <copyinstr+0x26>
        *dst = *p;
    8000158a:	00e78023          	sb	a4,0(a5)
      --max;
    8000158e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001592:	0785                	addi	a5,a5,1
    while(n > 0){
    80001594:	ff0796e3          	bne	a5,a6,80001580 <copyinstr+0x80>
      dst++;
    80001598:	8b42                	mv	s6,a6
    8000159a:	bf45                	j	8000154a <copyinstr+0x4a>
    8000159c:	4781                	li	a5,0
    8000159e:	b779                	j	8000152c <copyinstr+0x2c>
      return -1;
    800015a0:	557d                	li	a0,-1
    800015a2:	bf49                	j	80001534 <copyinstr+0x34>
  int got_null = 0;
    800015a4:	4781                	li	a5,0
  if(got_null){
    800015a6:	0017b793          	seqz	a5,a5
    800015aa:	40f00533          	neg	a0,a5
}
    800015ae:	8082                	ret

00000000800015b0 <vmfault>:
// that was lazily allocated in sys_sbrk().
// returns 0 if va is invalid or already mapped, or if
// out of physical memory, and physical address if successful.
uint64
vmfault(pagetable_t pagetable, uint64 va, int read)
{
    800015b0:	7179                	addi	sp,sp,-48
    800015b2:	f406                	sd	ra,40(sp)
    800015b4:	f022                	sd	s0,32(sp)
    800015b6:	ec26                	sd	s1,24(sp)
    800015b8:	e84a                	sd	s2,16(sp)
    800015ba:	e44e                	sd	s3,8(sp)
    800015bc:	e052                	sd	s4,0(sp)
    800015be:	1800                	addi	s0,sp,48
    800015c0:	8a2a                	mv	s4,a0
    800015c2:	84ae                	mv	s1,a1
  uint64 pa;
  pte_t *pte;
  struct proc *p = myproc();
    800015c4:	39a000ef          	jal	ra,8000195e <myproc>

  if (va >= p->sz)
    800015c8:	653c                	ld	a5,72(a0)
    return 0;
    800015ca:	4901                	li	s2,0
  if (va >= p->sz)
    800015cc:	00f4eb63          	bltu	s1,a5,800015e2 <vmfault+0x32>

    return PTE2PA(*pte);
  }

  return 0;
}
    800015d0:	854a                	mv	a0,s2
    800015d2:	70a2                	ld	ra,40(sp)
    800015d4:	7402                	ld	s0,32(sp)
    800015d6:	64e2                	ld	s1,24(sp)
    800015d8:	6942                	ld	s2,16(sp)
    800015da:	69a2                	ld	s3,8(sp)
    800015dc:	6a02                	ld	s4,0(sp)
    800015de:	6145                	addi	sp,sp,48
    800015e0:	8082                	ret
  va = PGROUNDDOWN(va);
    800015e2:	75fd                	lui	a1,0xfffff
    800015e4:	8ced                	and	s1,s1,a1
  pte = walk(pagetable, va, 0);
    800015e6:	4601                	li	a2,0
    800015e8:	85a6                	mv	a1,s1
    800015ea:	8552                	mv	a0,s4
    800015ec:	9cdff0ef          	jal	ra,80000fb8 <walk>
    800015f0:	89aa                	mv	s3,a0
  if(pte == 0 || (*pte & PTE_V) == 0){
    800015f2:	c509                	beqz	a0,800015fc <vmfault+0x4c>
    800015f4:	611c                	ld	a5,0(a0)
    800015f6:	0017f713          	andi	a4,a5,1
    800015fa:	eb05                	bnez	a4,8000162a <vmfault+0x7a>
    uint64 mem = (uint64)kalloc();
    800015fc:	d04ff0ef          	jal	ra,80000b00 <kalloc>
    80001600:	89aa                	mv	s3,a0
      return 0;
    80001602:	4901                	li	s2,0
    if(mem == 0)
    80001604:	d571                	beqz	a0,800015d0 <vmfault+0x20>
    uint64 mem = (uint64)kalloc();
    80001606:	892a                	mv	s2,a0
    memset((void*)mem, 0, PGSIZE);
    80001608:	6605                	lui	a2,0x1
    8000160a:	4581                	li	a1,0
    8000160c:	f30ff0ef          	jal	ra,80000d3c <memset>
    if(mappages(pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0){
    80001610:	4759                	li	a4,22
    80001612:	86ce                	mv	a3,s3
    80001614:	6605                	lui	a2,0x1
    80001616:	85a6                	mv	a1,s1
    80001618:	8552                	mv	a0,s4
    8000161a:	a77ff0ef          	jal	ra,80001090 <mappages>
    8000161e:	d94d                	beqz	a0,800015d0 <vmfault+0x20>
      kfree((void*)mem);
    80001620:	854e                	mv	a0,s3
    80001622:	b7aff0ef          	jal	ra,8000099c <kfree>
      return 0;
    80001626:	4901                	li	s2,0
    80001628:	b765                	j	800015d0 <vmfault+0x20>
  if((*pte & PTE_COW) && !(*pte & PTE_W)){
    8000162a:	1047f713          	andi	a4,a5,260
    8000162e:	10000693          	li	a3,256
  return 0;
    80001632:	4901                	li	s2,0
  if((*pte & PTE_COW) && !(*pte & PTE_W)){
    80001634:	f8d71ee3          	bne	a4,a3,800015d0 <vmfault+0x20>
    pa = PTE2PA(*pte);
    80001638:	83a9                	srli	a5,a5,0xa
    8000163a:	00c79493          	slli	s1,a5,0xc
    if(getref(pa) > 1){
    8000163e:	8526                	mv	a0,s1
    80001640:	d68ff0ef          	jal	ra,80000ba8 <getref>
    80001644:	4785                	li	a5,1
    80001646:	02a7d563          	bge	a5,a0,80001670 <vmfault+0xc0>
      char *mem = kalloc();
    8000164a:	cb6ff0ef          	jal	ra,80000b00 <kalloc>
    8000164e:	8a2a                	mv	s4,a0
      if(mem == 0)
    80001650:	d141                	beqz	a0,800015d0 <vmfault+0x20>
      memmove(mem, (char*)pa, PGSIZE);
    80001652:	6605                	lui	a2,0x1
    80001654:	85a6                	mv	a1,s1
    80001656:	f42ff0ef          	jal	ra,80000d98 <memmove>
      kfree((void*)pa);
    8000165a:	8526                	mv	a0,s1
    8000165c:	b40ff0ef          	jal	ra,8000099c <kfree>
      *pte = PA2PTE(mem) | PTE_W | PTE_U | PTE_R | PTE_V;
    80001660:	00ca5793          	srli	a5,s4,0xc
    80001664:	07aa                	slli	a5,a5,0xa
    80001666:	0177e793          	ori	a5,a5,23
    8000166a:	00f9b023          	sd	a5,0(s3) # 1000 <_entry-0x7ffff000>
    8000166e:	a809                	j	80001680 <vmfault+0xd0>
      *pte &= ~PTE_COW;
    80001670:	0009b783          	ld	a5,0(s3)
    80001674:	eff7f793          	andi	a5,a5,-257
    80001678:	0047e793          	ori	a5,a5,4
    8000167c:	00f9b023          	sd	a5,0(s3)
    return PTE2PA(*pte);
    80001680:	0009b903          	ld	s2,0(s3)
    80001684:	00a95913          	srli	s2,s2,0xa
    80001688:	0932                	slli	s2,s2,0xc
    8000168a:	b799                	j	800015d0 <vmfault+0x20>

000000008000168c <copyout>:
  while(len > 0){
    8000168c:	cec1                	beqz	a3,80001724 <copyout+0x98>
{
    8000168e:	711d                	addi	sp,sp,-96
    80001690:	ec86                	sd	ra,88(sp)
    80001692:	e8a2                	sd	s0,80(sp)
    80001694:	e4a6                	sd	s1,72(sp)
    80001696:	e0ca                	sd	s2,64(sp)
    80001698:	fc4e                	sd	s3,56(sp)
    8000169a:	f852                	sd	s4,48(sp)
    8000169c:	f456                	sd	s5,40(sp)
    8000169e:	f05a                	sd	s6,32(sp)
    800016a0:	ec5e                	sd	s7,24(sp)
    800016a2:	e862                	sd	s8,16(sp)
    800016a4:	e466                	sd	s9,8(sp)
    800016a6:	e06a                	sd	s10,0(sp)
    800016a8:	1080                	addi	s0,sp,96
    800016aa:	8c2a                	mv	s8,a0
    800016ac:	8b2e                	mv	s6,a1
    800016ae:	8bb2                	mv	s7,a2
    800016b0:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800016b2:	74fd                	lui	s1,0xfffff
    800016b4:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    800016b6:	57fd                	li	a5,-1
    800016b8:	83e9                	srli	a5,a5,0x1a
    800016ba:	0697e763          	bltu	a5,s1,80001728 <copyout+0x9c>
    800016be:	6d05                	lui	s10,0x1
    800016c0:	8cbe                	mv	s9,a5
    800016c2:	a015                	j	800016e6 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016c4:	409b0533          	sub	a0,s6,s1
    800016c8:	0009861b          	sext.w	a2,s3
    800016cc:	85de                	mv	a1,s7
    800016ce:	954a                	add	a0,a0,s2
    800016d0:	ec8ff0ef          	jal	ra,80000d98 <memmove>
    len -= n;
    800016d4:	413a0a33          	sub	s4,s4,s3
    src += n;
    800016d8:	9bce                	add	s7,s7,s3
  while(len > 0){
    800016da:	040a0363          	beqz	s4,80001720 <copyout+0x94>
    if(va0 >= MAXVA)
    800016de:	055ce763          	bltu	s9,s5,8000172c <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800016e2:	84d6                	mv	s1,s5
    dstva = va0 + PGSIZE;
    800016e4:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    800016e6:	85a6                	mv	a1,s1
    800016e8:	8562                	mv	a0,s8
    800016ea:	969ff0ef          	jal	ra,80001052 <walkaddr>
    800016ee:	892a                	mv	s2,a0
    if(pa0 == 0) {
    800016f0:	e901                	bnez	a0,80001700 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    800016f2:	4601                	li	a2,0
    800016f4:	85a6                	mv	a1,s1
    800016f6:	8562                	mv	a0,s8
    800016f8:	eb9ff0ef          	jal	ra,800015b0 <vmfault>
    800016fc:	892a                	mv	s2,a0
    800016fe:	c90d                	beqz	a0,80001730 <copyout+0xa4>
    pte = walk(pagetable, va0, 0);
    80001700:	4601                	li	a2,0
    80001702:	85a6                	mv	a1,s1
    80001704:	8562                	mv	a0,s8
    80001706:	8b3ff0ef          	jal	ra,80000fb8 <walk>
    if((*pte & PTE_W) == 0)
    8000170a:	611c                	ld	a5,0(a0)
    8000170c:	8b91                	andi	a5,a5,4
    8000170e:	c39d                	beqz	a5,80001734 <copyout+0xa8>
    n = PGSIZE - (dstva - va0);
    80001710:	01a48ab3          	add	s5,s1,s10
    80001714:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    80001718:	fb3a76e3          	bgeu	s4,s3,800016c4 <copyout+0x38>
    8000171c:	89d2                	mv	s3,s4
    8000171e:	b75d                	j	800016c4 <copyout+0x38>
  return 0;
    80001720:	4501                	li	a0,0
    80001722:	a811                	j	80001736 <copyout+0xaa>
    80001724:	4501                	li	a0,0
}
    80001726:	8082                	ret
      return -1;
    80001728:	557d                	li	a0,-1
    8000172a:	a031                	j	80001736 <copyout+0xaa>
    8000172c:	557d                	li	a0,-1
    8000172e:	a021                	j	80001736 <copyout+0xaa>
        return -1;
    80001730:	557d                	li	a0,-1
    80001732:	a011                	j	80001736 <copyout+0xaa>
      return -1;
    80001734:	557d                	li	a0,-1
}
    80001736:	60e6                	ld	ra,88(sp)
    80001738:	6446                	ld	s0,80(sp)
    8000173a:	64a6                	ld	s1,72(sp)
    8000173c:	6906                	ld	s2,64(sp)
    8000173e:	79e2                	ld	s3,56(sp)
    80001740:	7a42                	ld	s4,48(sp)
    80001742:	7aa2                	ld	s5,40(sp)
    80001744:	7b02                	ld	s6,32(sp)
    80001746:	6be2                	ld	s7,24(sp)
    80001748:	6c42                	ld	s8,16(sp)
    8000174a:	6ca2                	ld	s9,8(sp)
    8000174c:	6d02                	ld	s10,0(sp)
    8000174e:	6125                	addi	sp,sp,96
    80001750:	8082                	ret

0000000080001752 <copyin>:
  while(len > 0){
    80001752:	c6c9                	beqz	a3,800017dc <copyin+0x8a>
{
    80001754:	715d                	addi	sp,sp,-80
    80001756:	e486                	sd	ra,72(sp)
    80001758:	e0a2                	sd	s0,64(sp)
    8000175a:	fc26                	sd	s1,56(sp)
    8000175c:	f84a                	sd	s2,48(sp)
    8000175e:	f44e                	sd	s3,40(sp)
    80001760:	f052                	sd	s4,32(sp)
    80001762:	ec56                	sd	s5,24(sp)
    80001764:	e85a                	sd	s6,16(sp)
    80001766:	e45e                	sd	s7,8(sp)
    80001768:	e062                	sd	s8,0(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8baa                	mv	s7,a0
    8000176e:	8aae                	mv	s5,a1
    80001770:	8932                	mv	s2,a2
    80001772:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001774:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001776:	6b05                	lui	s6,0x1
    80001778:	a035                	j	800017a4 <copyin+0x52>
    8000177a:	412984b3          	sub	s1,s3,s2
    8000177e:	94da                	add	s1,s1,s6
    if(n > len)
    80001780:	009a7363          	bgeu	s4,s1,80001786 <copyin+0x34>
    80001784:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001786:	413905b3          	sub	a1,s2,s3
    8000178a:	0004861b          	sext.w	a2,s1
    8000178e:	95aa                	add	a1,a1,a0
    80001790:	8556                	mv	a0,s5
    80001792:	e06ff0ef          	jal	ra,80000d98 <memmove>
    len -= n;
    80001796:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000179a:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000179c:	01698933          	add	s2,s3,s6
  while(len > 0){
    800017a0:	020a0163          	beqz	s4,800017c2 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    800017a4:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    800017a8:	85ce                	mv	a1,s3
    800017aa:	855e                	mv	a0,s7
    800017ac:	8a7ff0ef          	jal	ra,80001052 <walkaddr>
    if(pa0 == 0) {
    800017b0:	f569                	bnez	a0,8000177a <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    800017b2:	4601                	li	a2,0
    800017b4:	85ce                	mv	a1,s3
    800017b6:	855e                	mv	a0,s7
    800017b8:	df9ff0ef          	jal	ra,800015b0 <vmfault>
    800017bc:	fd5d                	bnez	a0,8000177a <copyin+0x28>
        return -1;
    800017be:	557d                	li	a0,-1
    800017c0:	a011                	j	800017c4 <copyin+0x72>
  return 0;
    800017c2:	4501                	li	a0,0
}
    800017c4:	60a6                	ld	ra,72(sp)
    800017c6:	6406                	ld	s0,64(sp)
    800017c8:	74e2                	ld	s1,56(sp)
    800017ca:	7942                	ld	s2,48(sp)
    800017cc:	79a2                	ld	s3,40(sp)
    800017ce:	7a02                	ld	s4,32(sp)
    800017d0:	6ae2                	ld	s5,24(sp)
    800017d2:	6b42                	ld	s6,16(sp)
    800017d4:	6ba2                	ld	s7,8(sp)
    800017d6:	6c02                	ld	s8,0(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
  return 0;
    800017dc:	4501                	li	a0,0
}
    800017de:	8082                	ret

00000000800017e0 <ismapped>:

int
ismapped(pagetable_t pagetable, uint64 va)
{
    800017e0:	1141                	addi	sp,sp,-16
    800017e2:	e406                	sd	ra,8(sp)
    800017e4:	e022                	sd	s0,0(sp)
    800017e6:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    800017e8:	4601                	li	a2,0
    800017ea:	fceff0ef          	jal	ra,80000fb8 <walk>
  if (pte == 0) {
    800017ee:	c519                	beqz	a0,800017fc <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    800017f0:	6108                	ld	a0,0(a0)
    return 0;
    800017f2:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    800017f4:	60a2                	ld	ra,8(sp)
    800017f6:	6402                	ld	s0,0(sp)
    800017f8:	0141                	addi	sp,sp,16
    800017fa:	8082                	ret
    return 0;
    800017fc:	4501                	li	a0,0
    800017fe:	bfdd                	j	800017f4 <ismapped+0x14>

0000000080001800 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001800:	7139                	addi	sp,sp,-64
    80001802:	fc06                	sd	ra,56(sp)
    80001804:	f822                	sd	s0,48(sp)
    80001806:	f426                	sd	s1,40(sp)
    80001808:	f04a                	sd	s2,32(sp)
    8000180a:	ec4e                	sd	s3,24(sp)
    8000180c:	e852                	sd	s4,16(sp)
    8000180e:	e456                	sd	s5,8(sp)
    80001810:	e05a                	sd	s6,0(sp)
    80001812:	0080                	addi	s0,sp,64
    80001814:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001816:	0022e497          	auipc	s1,0x22e
    8000181a:	5e248493          	addi	s1,s1,1506 # 8022fdf8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000181e:	8b26                	mv	s6,s1
    80001820:	00005a97          	auipc	s5,0x5
    80001824:	7e0a8a93          	addi	s5,s5,2016 # 80007000 <etext>
    80001828:	04000937          	lui	s2,0x4000
    8000182c:	197d                	addi	s2,s2,-1
    8000182e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001830:	00234a17          	auipc	s4,0x234
    80001834:	3c8a0a13          	addi	s4,s4,968 # 80235bf8 <tickslock>
    char *pa = kalloc();
    80001838:	ac8ff0ef          	jal	ra,80000b00 <kalloc>
    8000183c:	862a                	mv	a2,a0
    if(pa == 0)
    8000183e:	c121                	beqz	a0,8000187e <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    80001840:	416485b3          	sub	a1,s1,s6
    80001844:	858d                	srai	a1,a1,0x3
    80001846:	000ab783          	ld	a5,0(s5)
    8000184a:	02f585b3          	mul	a1,a1,a5
    8000184e:	2585                	addiw	a1,a1,1
    80001850:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001854:	4719                	li	a4,6
    80001856:	6685                	lui	a3,0x1
    80001858:	40b905b3          	sub	a1,s2,a1
    8000185c:	854e                	mv	a0,s3
    8000185e:	8e3ff0ef          	jal	ra,80001140 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001862:	17848493          	addi	s1,s1,376
    80001866:	fd4499e3          	bne	s1,s4,80001838 <proc_mapstacks+0x38>
  }
}
    8000186a:	70e2                	ld	ra,56(sp)
    8000186c:	7442                	ld	s0,48(sp)
    8000186e:	74a2                	ld	s1,40(sp)
    80001870:	7902                	ld	s2,32(sp)
    80001872:	69e2                	ld	s3,24(sp)
    80001874:	6a42                	ld	s4,16(sp)
    80001876:	6aa2                	ld	s5,8(sp)
    80001878:	6b02                	ld	s6,0(sp)
    8000187a:	6121                	addi	sp,sp,64
    8000187c:	8082                	ret
      panic("kalloc");
    8000187e:	00006517          	auipc	a0,0x6
    80001882:	91250513          	addi	a0,a0,-1774 # 80007190 <digits+0x158>
    80001886:	ee5fe0ef          	jal	ra,8000076a <panic>

000000008000188a <procinit>:


// initialize the proc table.
void
procinit(void)
{
    8000188a:	7139                	addi	sp,sp,-64
    8000188c:	fc06                	sd	ra,56(sp)
    8000188e:	f822                	sd	s0,48(sp)
    80001890:	f426                	sd	s1,40(sp)
    80001892:	f04a                	sd	s2,32(sp)
    80001894:	ec4e                	sd	s3,24(sp)
    80001896:	e852                	sd	s4,16(sp)
    80001898:	e456                	sd	s5,8(sp)
    8000189a:	e05a                	sd	s6,0(sp)
    8000189c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000189e:	00006597          	auipc	a1,0x6
    800018a2:	8fa58593          	addi	a1,a1,-1798 # 80007198 <digits+0x160>
    800018a6:	0022e517          	auipc	a0,0x22e
    800018aa:	12250513          	addi	a0,a0,290 # 8022f9c8 <pid_lock>
    800018ae:	b3aff0ef          	jal	ra,80000be8 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018b2:	00006597          	auipc	a1,0x6
    800018b6:	8ee58593          	addi	a1,a1,-1810 # 800071a0 <digits+0x168>
    800018ba:	0022e517          	auipc	a0,0x22e
    800018be:	12650513          	addi	a0,a0,294 # 8022f9e0 <wait_lock>
    800018c2:	b26ff0ef          	jal	ra,80000be8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c6:	0022e497          	auipc	s1,0x22e
    800018ca:	53248493          	addi	s1,s1,1330 # 8022fdf8 <proc>
      initlock(&p->lock, "proc");
    800018ce:	00006b17          	auipc	s6,0x6
    800018d2:	8e2b0b13          	addi	s6,s6,-1822 # 800071b0 <digits+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    800018d6:	8aa6                	mv	s5,s1
    800018d8:	00005a17          	auipc	s4,0x5
    800018dc:	728a0a13          	addi	s4,s4,1832 # 80007000 <etext>
    800018e0:	04000937          	lui	s2,0x4000
    800018e4:	197d                	addi	s2,s2,-1
    800018e6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e8:	00234997          	auipc	s3,0x234
    800018ec:	31098993          	addi	s3,s3,784 # 80235bf8 <tickslock>
      initlock(&p->lock, "proc");
    800018f0:	85da                	mv	a1,s6
    800018f2:	8526                	mv	a0,s1
    800018f4:	af4ff0ef          	jal	ra,80000be8 <initlock>
      p->state = UNUSED;
    800018f8:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800018fc:	415487b3          	sub	a5,s1,s5
    80001900:	878d                	srai	a5,a5,0x3
    80001902:	000a3703          	ld	a4,0(s4)
    80001906:	02e787b3          	mul	a5,a5,a4
    8000190a:	2785                	addiw	a5,a5,1
    8000190c:	00d7979b          	slliw	a5,a5,0xd
    80001910:	40f907b3          	sub	a5,s2,a5
    80001914:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001916:	17848493          	addi	s1,s1,376
    8000191a:	fd349be3          	bne	s1,s3,800018f0 <procinit+0x66>
  }
}
    8000191e:	70e2                	ld	ra,56(sp)
    80001920:	7442                	ld	s0,48(sp)
    80001922:	74a2                	ld	s1,40(sp)
    80001924:	7902                	ld	s2,32(sp)
    80001926:	69e2                	ld	s3,24(sp)
    80001928:	6a42                	ld	s4,16(sp)
    8000192a:	6aa2                	ld	s5,8(sp)
    8000192c:	6b02                	ld	s6,0(sp)
    8000192e:	6121                	addi	sp,sp,64
    80001930:	8082                	ret

0000000080001932 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001932:	1141                	addi	sp,sp,-16
    80001934:	e422                	sd	s0,8(sp)
    80001936:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001938:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000193a:	2501                	sext.w	a0,a0
    8000193c:	6422                	ld	s0,8(sp)
    8000193e:	0141                	addi	sp,sp,16
    80001940:	8082                	ret

0000000080001942 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001942:	1141                	addi	sp,sp,-16
    80001944:	e422                	sd	s0,8(sp)
    80001946:	0800                	addi	s0,sp,16
    80001948:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000194a:	2781                	sext.w	a5,a5
    8000194c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000194e:	0022e517          	auipc	a0,0x22e
    80001952:	0aa50513          	addi	a0,a0,170 # 8022f9f8 <cpus>
    80001956:	953e                	add	a0,a0,a5
    80001958:	6422                	ld	s0,8(sp)
    8000195a:	0141                	addi	sp,sp,16
    8000195c:	8082                	ret

000000008000195e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    8000195e:	1101                	addi	sp,sp,-32
    80001960:	ec06                	sd	ra,24(sp)
    80001962:	e822                	sd	s0,16(sp)
    80001964:	e426                	sd	s1,8(sp)
    80001966:	1000                	addi	s0,sp,32
  push_off();
    80001968:	ac0ff0ef          	jal	ra,80000c28 <push_off>
    8000196c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000196e:	2781                	sext.w	a5,a5
    80001970:	079e                	slli	a5,a5,0x7
    80001972:	0022e717          	auipc	a4,0x22e
    80001976:	05670713          	addi	a4,a4,86 # 8022f9c8 <pid_lock>
    8000197a:	97ba                	add	a5,a5,a4
    8000197c:	7b84                	ld	s1,48(a5)
  pop_off();
    8000197e:	b2eff0ef          	jal	ra,80000cac <pop_off>
  return p;
}
    80001982:	8526                	mv	a0,s1
    80001984:	60e2                	ld	ra,24(sp)
    80001986:	6442                	ld	s0,16(sp)
    80001988:	64a2                	ld	s1,8(sp)
    8000198a:	6105                	addi	sp,sp,32
    8000198c:	8082                	ret

000000008000198e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000198e:	7179                	addi	sp,sp,-48
    80001990:	f406                	sd	ra,40(sp)
    80001992:	f022                	sd	s0,32(sp)
    80001994:	ec26                	sd	s1,24(sp)
    80001996:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001998:	fc7ff0ef          	jal	ra,8000195e <myproc>
    8000199c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000199e:	b62ff0ef          	jal	ra,80000d00 <release>

  if (first) {
    800019a2:	00006797          	auipc	a5,0x6
    800019a6:	ede7a783          	lw	a5,-290(a5) # 80007880 <first.1>
    800019aa:	cf8d                	beqz	a5,800019e4 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    800019ac:	4505                	li	a0,1
    800019ae:	4fb010ef          	jal	ra,800036a8 <fsinit>

    first = 0;
    800019b2:	00006797          	auipc	a5,0x6
    800019b6:	ec07a723          	sw	zero,-306(a5) # 80007880 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    800019ba:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    800019be:	00005517          	auipc	a0,0x5
    800019c2:	7fa50513          	addi	a0,a0,2042 # 800071b8 <digits+0x180>
    800019c6:	fca43823          	sd	a0,-48(s0)
    800019ca:	fc043c23          	sd	zero,-40(s0)
    800019ce:	fd040593          	addi	a1,s0,-48
    800019d2:	57f020ef          	jal	ra,80004750 <kexec>
    800019d6:	6cbc                	ld	a5,88(s1)
    800019d8:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    800019da:	6cbc                	ld	a5,88(s1)
    800019dc:	7bb8                	ld	a4,112(a5)
    800019de:	57fd                	li	a5,-1
    800019e0:	02f70d63          	beq	a4,a5,80001a1a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    800019e4:	40f000ef          	jal	ra,800025f2 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800019e8:	68a8                	ld	a0,80(s1)
    800019ea:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800019ec:	04000737          	lui	a4,0x4000
    800019f0:	00004797          	auipc	a5,0x4
    800019f4:	6ac78793          	addi	a5,a5,1708 # 8000609c <userret>
    800019f8:	00004697          	auipc	a3,0x4
    800019fc:	60868693          	addi	a3,a3,1544 # 80006000 <_trampoline>
    80001a00:	8f95                	sub	a5,a5,a3
    80001a02:	177d                	addi	a4,a4,-1
    80001a04:	0732                	slli	a4,a4,0xc
    80001a06:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001a08:	577d                	li	a4,-1
    80001a0a:	177e                	slli	a4,a4,0x3f
    80001a0c:	8d59                	or	a0,a0,a4
    80001a0e:	9782                	jalr	a5
}
    80001a10:	70a2                	ld	ra,40(sp)
    80001a12:	7402                	ld	s0,32(sp)
    80001a14:	64e2                	ld	s1,24(sp)
    80001a16:	6145                	addi	sp,sp,48
    80001a18:	8082                	ret
      panic("exec");
    80001a1a:	00005517          	auipc	a0,0x5
    80001a1e:	7a650513          	addi	a0,a0,1958 # 800071c0 <digits+0x188>
    80001a22:	d49fe0ef          	jal	ra,8000076a <panic>

0000000080001a26 <allocpid>:
{
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	e04a                	sd	s2,0(sp)
    80001a30:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a32:	0022e917          	auipc	s2,0x22e
    80001a36:	f9690913          	addi	s2,s2,-106 # 8022f9c8 <pid_lock>
    80001a3a:	854a                	mv	a0,s2
    80001a3c:	a2cff0ef          	jal	ra,80000c68 <acquire>
  pid = nextpid;
    80001a40:	00006797          	auipc	a5,0x6
    80001a44:	e4478793          	addi	a5,a5,-444 # 80007884 <nextpid>
    80001a48:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4a:	0014871b          	addiw	a4,s1,1
    80001a4e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a50:	854a                	mv	a0,s2
    80001a52:	aaeff0ef          	jal	ra,80000d00 <release>
}
    80001a56:	8526                	mv	a0,s1
    80001a58:	60e2                	ld	ra,24(sp)
    80001a5a:	6442                	ld	s0,16(sp)
    80001a5c:	64a2                	ld	s1,8(sp)
    80001a5e:	6902                	ld	s2,0(sp)
    80001a60:	6105                	addi	sp,sp,32
    80001a62:	8082                	ret

0000000080001a64 <proc_pagetable>:
{
    80001a64:	1101                	addi	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	e04a                	sd	s2,0(sp)
    80001a6e:	1000                	addi	s0,sp,32
    80001a70:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a72:	fc4ff0ef          	jal	ra,80001236 <uvmcreate>
    80001a76:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a78:	cd05                	beqz	a0,80001ab0 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a7a:	4729                	li	a4,10
    80001a7c:	00004697          	auipc	a3,0x4
    80001a80:	58468693          	addi	a3,a3,1412 # 80006000 <_trampoline>
    80001a84:	6605                	lui	a2,0x1
    80001a86:	040005b7          	lui	a1,0x4000
    80001a8a:	15fd                	addi	a1,a1,-1
    80001a8c:	05b2                	slli	a1,a1,0xc
    80001a8e:	e02ff0ef          	jal	ra,80001090 <mappages>
    80001a92:	02054663          	bltz	a0,80001abe <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a96:	4719                	li	a4,6
    80001a98:	05893683          	ld	a3,88(s2)
    80001a9c:	6605                	lui	a2,0x1
    80001a9e:	020005b7          	lui	a1,0x2000
    80001aa2:	15fd                	addi	a1,a1,-1
    80001aa4:	05b6                	slli	a1,a1,0xd
    80001aa6:	8526                	mv	a0,s1
    80001aa8:	de8ff0ef          	jal	ra,80001090 <mappages>
    80001aac:	00054f63          	bltz	a0,80001aca <proc_pagetable+0x66>
}
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	60e2                	ld	ra,24(sp)
    80001ab4:	6442                	ld	s0,16(sp)
    80001ab6:	64a2                	ld	s1,8(sp)
    80001ab8:	6902                	ld	s2,0(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret
    uvmfree(pagetable, 0);
    80001abe:	4581                	li	a1,0
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	953ff0ef          	jal	ra,80001414 <uvmfree>
    return 0;
    80001ac6:	4481                	li	s1,0
    80001ac8:	b7e5                	j	80001ab0 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aca:	4681                	li	a3,0
    80001acc:	4605                	li	a2,1
    80001ace:	040005b7          	lui	a1,0x4000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b2                	slli	a1,a1,0xc
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	f84ff0ef          	jal	ra,8000125c <uvmunmap>
    uvmfree(pagetable, 0);
    80001adc:	4581                	li	a1,0
    80001ade:	8526                	mv	a0,s1
    80001ae0:	935ff0ef          	jal	ra,80001414 <uvmfree>
    return 0;
    80001ae4:	4481                	li	s1,0
    80001ae6:	b7e9                	j	80001ab0 <proc_pagetable+0x4c>

0000000080001ae8 <proc_freepagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	84aa                	mv	s1,a0
    80001af6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af8:	4681                	li	a3,0
    80001afa:	4605                	li	a2,1
    80001afc:	040005b7          	lui	a1,0x4000
    80001b00:	15fd                	addi	a1,a1,-1
    80001b02:	05b2                	slli	a1,a1,0xc
    80001b04:	f58ff0ef          	jal	ra,8000125c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	020005b7          	lui	a1,0x2000
    80001b10:	15fd                	addi	a1,a1,-1
    80001b12:	05b6                	slli	a1,a1,0xd
    80001b14:	8526                	mv	a0,s1
    80001b16:	f46ff0ef          	jal	ra,8000125c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b1a:	85ca                	mv	a1,s2
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	8f7ff0ef          	jal	ra,80001414 <uvmfree>
}
    80001b22:	60e2                	ld	ra,24(sp)
    80001b24:	6442                	ld	s0,16(sp)
    80001b26:	64a2                	ld	s1,8(sp)
    80001b28:	6902                	ld	s2,0(sp)
    80001b2a:	6105                	addi	sp,sp,32
    80001b2c:	8082                	ret

0000000080001b2e <freeproc>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	1000                	addi	s0,sp,32
    80001b38:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b3a:	6d28                	ld	a0,88(a0)
    80001b3c:	c119                	beqz	a0,80001b42 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001b3e:	e5ffe0ef          	jal	ra,8000099c <kfree>
  p->trapframe = 0;
    80001b42:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b46:	68a8                	ld	a0,80(s1)
    80001b48:	c501                	beqz	a0,80001b50 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001b4a:	64ac                	ld	a1,72(s1)
    80001b4c:	f9dff0ef          	jal	ra,80001ae8 <proc_freepagetable>
  p->pagetable = 0;
    80001b50:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b54:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b58:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b5c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b60:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b64:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b68:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b6c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b70:	0004ac23          	sw	zero,24(s1)
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <allocproc>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	e04a                	sd	s2,0(sp)
    80001b88:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b8a:	0022e497          	auipc	s1,0x22e
    80001b8e:	26e48493          	addi	s1,s1,622 # 8022fdf8 <proc>
    80001b92:	00234917          	auipc	s2,0x234
    80001b96:	06690913          	addi	s2,s2,102 # 80235bf8 <tickslock>
    acquire(&p->lock);
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	8ccff0ef          	jal	ra,80000c68 <acquire>
    if(p->state == UNUSED) {
    80001ba0:	4c9c                	lw	a5,24(s1)
    80001ba2:	cb91                	beqz	a5,80001bb6 <allocproc+0x38>
      release(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	95aff0ef          	jal	ra,80000d00 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	17848493          	addi	s1,s1,376
    80001bae:	ff2496e3          	bne	s1,s2,80001b9a <allocproc+0x1c>
  return 0;
    80001bb2:	4481                	li	s1,0
    80001bb4:	a889                	j	80001c06 <allocproc+0x88>
  p->pid = allocpid();
    80001bb6:	e71ff0ef          	jal	ra,80001a26 <allocpid>
    80001bba:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bbc:	4785                	li	a5,1
    80001bbe:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bc0:	f41fe0ef          	jal	ra,80000b00 <kalloc>
    80001bc4:	892a                	mv	s2,a0
    80001bc6:	eca8                	sd	a0,88(s1)
    80001bc8:	c531                	beqz	a0,80001c14 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	e99ff0ef          	jal	ra,80001a64 <proc_pagetable>
    80001bd0:	892a                	mv	s2,a0
    80001bd2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bd4:	c921                	beqz	a0,80001c24 <allocproc+0xa6>
  memset(&p->context, 0, sizeof(p->context));
    80001bd6:	07000613          	li	a2,112
    80001bda:	4581                	li	a1,0
    80001bdc:	06048513          	addi	a0,s1,96
    80001be0:	95cff0ef          	jal	ra,80000d3c <memset>
  p->context.ra = (uint64)forkret;
    80001be4:	00000797          	auipc	a5,0x0
    80001be8:	daa78793          	addi	a5,a5,-598 # 8000198e <forkret>
    80001bec:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bee:	60bc                	ld	a5,64(s1)
    80001bf0:	6705                	lui	a4,0x1
    80001bf2:	97ba                	add	a5,a5,a4
    80001bf4:	f4bc                	sd	a5,104(s1)
  p->priority   = SCHED_DEFAULT;
    80001bf6:	03c00793          	li	a5,60
    80001bfa:	16f4a423          	sw	a5,360(s1)
  p->wait_ticks = 0;
    80001bfe:	1604a623          	sw	zero,364(s1)
  p->cpu_ticks  = 0;
    80001c02:	1604a823          	sw	zero,368(s1)
}
    80001c06:	8526                	mv	a0,s1
    80001c08:	60e2                	ld	ra,24(sp)
    80001c0a:	6442                	ld	s0,16(sp)
    80001c0c:	64a2                	ld	s1,8(sp)
    80001c0e:	6902                	ld	s2,0(sp)
    80001c10:	6105                	addi	sp,sp,32
    80001c12:	8082                	ret
    freeproc(p);
    80001c14:	8526                	mv	a0,s1
    80001c16:	f19ff0ef          	jal	ra,80001b2e <freeproc>
    release(&p->lock);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	8e4ff0ef          	jal	ra,80000d00 <release>
    return 0;
    80001c20:	84ca                	mv	s1,s2
    80001c22:	b7d5                	j	80001c06 <allocproc+0x88>
    freeproc(p);
    80001c24:	8526                	mv	a0,s1
    80001c26:	f09ff0ef          	jal	ra,80001b2e <freeproc>
    release(&p->lock);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	8d4ff0ef          	jal	ra,80000d00 <release>
    return 0;
    80001c30:	84ca                	mv	s1,s2
    80001c32:	bfd1                	j	80001c06 <allocproc+0x88>

0000000080001c34 <userinit>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c3e:	f41ff0ef          	jal	ra,80001b7e <allocproc>
    80001c42:	84aa                	mv	s1,a0
  initproc = p;
    80001c44:	00006797          	auipc	a5,0x6
    80001c48:	c6a7ba23          	sd	a0,-908(a5) # 800078b8 <initproc>
  p->cwd = namei("/");
    80001c4c:	00005517          	auipc	a0,0x5
    80001c50:	57c50513          	addi	a0,a0,1404 # 800071c8 <digits+0x190>
    80001c54:	753010ef          	jal	ra,80003ba6 <namei>
    80001c58:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c5c:	478d                	li	a5,3
    80001c5e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	89eff0ef          	jal	ra,80000d00 <release>
}
    80001c66:	60e2                	ld	ra,24(sp)
    80001c68:	6442                	ld	s0,16(sp)
    80001c6a:	64a2                	ld	s1,8(sp)
    80001c6c:	6105                	addi	sp,sp,32
    80001c6e:	8082                	ret

0000000080001c70 <growproc>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	e04a                	sd	s2,0(sp)
    80001c7a:	1000                	addi	s0,sp,32
    80001c7c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c7e:	ce1ff0ef          	jal	ra,8000195e <myproc>
    80001c82:	892a                	mv	s2,a0
  sz = p->sz;
    80001c84:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c86:	02905963          	blez	s1,80001cb8 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c8a:	00b48633          	add	a2,s1,a1
    80001c8e:	020007b7          	lui	a5,0x2000
    80001c92:	17fd                	addi	a5,a5,-1
    80001c94:	07b6                	slli	a5,a5,0xd
    80001c96:	02c7ea63          	bltu	a5,a2,80001cca <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c9a:	4691                	li	a3,4
    80001c9c:	6928                	ld	a0,80(a0)
    80001c9e:	e7eff0ef          	jal	ra,8000131c <uvmalloc>
    80001ca2:	85aa                	mv	a1,a0
    80001ca4:	c50d                	beqz	a0,80001cce <growproc+0x5e>
  p->sz = sz;
    80001ca6:	04b93423          	sd	a1,72(s2)
  return 0;
    80001caa:	4501                	li	a0,0
}
    80001cac:	60e2                	ld	ra,24(sp)
    80001cae:	6442                	ld	s0,16(sp)
    80001cb0:	64a2                	ld	s1,8(sp)
    80001cb2:	6902                	ld	s2,0(sp)
    80001cb4:	6105                	addi	sp,sp,32
    80001cb6:	8082                	ret
  } else if(n < 0){
    80001cb8:	fe04d7e3          	bgez	s1,80001ca6 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001cbc:	00b48633          	add	a2,s1,a1
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	e16ff0ef          	jal	ra,800012d8 <uvmdealloc>
    80001cc6:	85aa                	mv	a1,a0
    80001cc8:	bff9                	j	80001ca6 <growproc+0x36>
      return -1;
    80001cca:	557d                	li	a0,-1
    80001ccc:	b7c5                	j	80001cac <growproc+0x3c>
      return -1;
    80001cce:	557d                	li	a0,-1
    80001cd0:	bff1                	j	80001cac <growproc+0x3c>

0000000080001cd2 <kfork>:
{
    80001cd2:	7139                	addi	sp,sp,-64
    80001cd4:	fc06                	sd	ra,56(sp)
    80001cd6:	f822                	sd	s0,48(sp)
    80001cd8:	f426                	sd	s1,40(sp)
    80001cda:	f04a                	sd	s2,32(sp)
    80001cdc:	ec4e                	sd	s3,24(sp)
    80001cde:	e852                	sd	s4,16(sp)
    80001ce0:	e456                	sd	s5,8(sp)
    80001ce2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ce4:	c7bff0ef          	jal	ra,8000195e <myproc>
    80001ce8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001cea:	e95ff0ef          	jal	ra,80001b7e <allocproc>
    80001cee:	0e050e63          	beqz	a0,80001dea <kfork+0x118>
    80001cf2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001cf4:	048ab603          	ld	a2,72(s5)
    80001cf8:	692c                	ld	a1,80(a0)
    80001cfa:	050ab503          	ld	a0,80(s5)
    80001cfe:	f46ff0ef          	jal	ra,80001444 <uvmcopy>
    80001d02:	04054863          	bltz	a0,80001d52 <kfork+0x80>
  np->sz = p->sz;
    80001d06:	048ab783          	ld	a5,72(s5)
    80001d0a:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001d0e:	058ab683          	ld	a3,88(s5)
    80001d12:	87b6                	mv	a5,a3
    80001d14:	0589b703          	ld	a4,88(s3)
    80001d18:	12068693          	addi	a3,a3,288
    80001d1c:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001d20:	6788                	ld	a0,8(a5)
    80001d22:	6b8c                	ld	a1,16(a5)
    80001d24:	6f90                	ld	a2,24(a5)
    80001d26:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001d2a:	e708                	sd	a0,8(a4)
    80001d2c:	eb0c                	sd	a1,16(a4)
    80001d2e:	ef10                	sd	a2,24(a4)
    80001d30:	02078793          	addi	a5,a5,32
    80001d34:	02070713          	addi	a4,a4,32
    80001d38:	fed792e3          	bne	a5,a3,80001d1c <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001d3c:	0589b783          	ld	a5,88(s3)
    80001d40:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001d44:	0d0a8493          	addi	s1,s5,208
    80001d48:	0d098913          	addi	s2,s3,208
    80001d4c:	150a8a13          	addi	s4,s5,336
    80001d50:	a829                	j	80001d6a <kfork+0x98>
    freeproc(np);
    80001d52:	854e                	mv	a0,s3
    80001d54:	ddbff0ef          	jal	ra,80001b2e <freeproc>
    release(&np->lock);
    80001d58:	854e                	mv	a0,s3
    80001d5a:	fa7fe0ef          	jal	ra,80000d00 <release>
    return -1;
    80001d5e:	597d                	li	s2,-1
    80001d60:	a89d                	j	80001dd6 <kfork+0x104>
  for(i = 0; i < NOFILE; i++)
    80001d62:	04a1                	addi	s1,s1,8
    80001d64:	0921                	addi	s2,s2,8
    80001d66:	01448963          	beq	s1,s4,80001d78 <kfork+0xa6>
    if(p->ofile[i])
    80001d6a:	6088                	ld	a0,0(s1)
    80001d6c:	d97d                	beqz	a0,80001d62 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d6e:	3f0020ef          	jal	ra,8000415e <filedup>
    80001d72:	00a93023          	sd	a0,0(s2)
    80001d76:	b7f5                	j	80001d62 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001d78:	150ab503          	ld	a0,336(s5)
    80001d7c:	606010ef          	jal	ra,80003382 <idup>
    80001d80:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d84:	4641                	li	a2,16
    80001d86:	158a8593          	addi	a1,s5,344
    80001d8a:	15898513          	addi	a0,s3,344
    80001d8e:	8f4ff0ef          	jal	ra,80000e82 <safestrcpy>
  np->priority   = p->priority;
    80001d92:	168aa783          	lw	a5,360(s5)
    80001d96:	16f9a423          	sw	a5,360(s3)
  np->wait_ticks = 0;
    80001d9a:	1609a623          	sw	zero,364(s3)
  np->cpu_ticks  = 0;
    80001d9e:	1609a823          	sw	zero,368(s3)
  pid = np->pid;
    80001da2:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001da6:	854e                	mv	a0,s3
    80001da8:	f59fe0ef          	jal	ra,80000d00 <release>
  acquire(&wait_lock);
    80001dac:	0022e497          	auipc	s1,0x22e
    80001db0:	c3448493          	addi	s1,s1,-972 # 8022f9e0 <wait_lock>
    80001db4:	8526                	mv	a0,s1
    80001db6:	eb3fe0ef          	jal	ra,80000c68 <acquire>
  np->parent = p;
    80001dba:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	f41fe0ef          	jal	ra,80000d00 <release>
  acquire(&np->lock);
    80001dc4:	854e                	mv	a0,s3
    80001dc6:	ea3fe0ef          	jal	ra,80000c68 <acquire>
  np->state = RUNNABLE;
    80001dca:	478d                	li	a5,3
    80001dcc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001dd0:	854e                	mv	a0,s3
    80001dd2:	f2ffe0ef          	jal	ra,80000d00 <release>
}
    80001dd6:	854a                	mv	a0,s2
    80001dd8:	70e2                	ld	ra,56(sp)
    80001dda:	7442                	ld	s0,48(sp)
    80001ddc:	74a2                	ld	s1,40(sp)
    80001dde:	7902                	ld	s2,32(sp)
    80001de0:	69e2                	ld	s3,24(sp)
    80001de2:	6a42                	ld	s4,16(sp)
    80001de4:	6aa2                	ld	s5,8(sp)
    80001de6:	6121                	addi	sp,sp,64
    80001de8:	8082                	ret
    return -1;
    80001dea:	597d                	li	s2,-1
    80001dec:	b7ed                	j	80001dd6 <kfork+0x104>

0000000080001dee <scheduler>:
{
    80001dee:	711d                	addi	sp,sp,-96
    80001df0:	ec86                	sd	ra,88(sp)
    80001df2:	e8a2                	sd	s0,80(sp)
    80001df4:	e4a6                	sd	s1,72(sp)
    80001df6:	e0ca                	sd	s2,64(sp)
    80001df8:	fc4e                	sd	s3,56(sp)
    80001dfa:	f852                	sd	s4,48(sp)
    80001dfc:	f456                	sd	s5,40(sp)
    80001dfe:	f05a                	sd	s6,32(sp)
    80001e00:	ec5e                	sd	s7,24(sp)
    80001e02:	e862                	sd	s8,16(sp)
    80001e04:	e466                	sd	s9,8(sp)
    80001e06:	1080                	addi	s0,sp,96
    80001e08:	8792                	mv	a5,tp
  int id = r_tp();
    80001e0a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e0c:	00779c13          	slli	s8,a5,0x7
    80001e10:	0022e717          	auipc	a4,0x22e
    80001e14:	bb870713          	addi	a4,a4,-1096 # 8022f9c8 <pid_lock>
    80001e18:	9762                	add	a4,a4,s8
    80001e1a:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &best->context);
    80001e1e:	0022e717          	auipc	a4,0x22e
    80001e22:	be270713          	addi	a4,a4,-1054 # 8022fa00 <cpus+0x8>
    80001e26:	9c3a                	add	s8,s8,a4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e28:	00234997          	auipc	s3,0x234
    80001e2c:	dd098993          	addi	s3,s3,-560 # 80235bf8 <tickslock>
      c->proc = best;
    80001e30:	079e                	slli	a5,a5,0x7
    80001e32:	0022eb17          	auipc	s6,0x22e
    80001e36:	b96b0b13          	addi	s6,s6,-1130 # 8022f9c8 <pid_lock>
    80001e3a:	9b3e                	add	s6,s6,a5
      window_tick++;
    80001e3c:	00006b97          	auipc	s7,0x6
    80001e40:	a74b8b93          	addi	s7,s7,-1420 # 800078b0 <window_tick.2>
    80001e44:	a0b9                	j	80001e92 <scheduler+0xa4>
      release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	eb9fe0ef          	jal	ra,80000d00 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e4c:	17848493          	addi	s1,s1,376
    80001e50:	03348763          	beq	s1,s3,80001e7e <scheduler+0x90>
      acquire(&p->lock);
    80001e54:	8526                	mv	a0,s1
    80001e56:	e13fe0ef          	jal	ra,80000c68 <acquire>
      if(p->state == RUNNABLE) {
    80001e5a:	4c9c                	lw	a5,24(s1)
    80001e5c:	ff4795e3          	bne	a5,s4,80001e46 <scheduler+0x58>
        if(best == 0 || p->priority > best->priority){
    80001e60:	00090d63          	beqz	s2,80001e7a <scheduler+0x8c>
    80001e64:	1684a703          	lw	a4,360(s1)
    80001e68:	16892783          	lw	a5,360(s2)
    80001e6c:	fce7dde3          	bge	a5,a4,80001e46 <scheduler+0x58>
          if(best) release(&best->lock);
    80001e70:	854a                	mv	a0,s2
    80001e72:	e8ffe0ef          	jal	ra,80000d00 <release>
    80001e76:	8926                	mv	s2,s1
    80001e78:	bfd1                	j	80001e4c <scheduler+0x5e>
    80001e7a:	8926                	mv	s2,s1
    80001e7c:	bfc1                	j	80001e4c <scheduler+0x5e>
    if(best) {
    80001e7e:	02091063          	bnez	s2,80001e9e <scheduler+0xb0>
    release(&wait_lock);
    80001e82:	0022e517          	auipc	a0,0x22e
    80001e86:	b5e50513          	addi	a0,a0,-1186 # 8022f9e0 <wait_lock>
    80001e8a:	e77fe0ef          	jal	ra,80000d00 <release>
      asm volatile("wfi");
    80001e8e:	10500073          	wfi
    acquire(&wait_lock); // must be acquired before any p->lock.
    80001e92:	0022ea97          	auipc	s5,0x22e
    80001e96:	b4ea8a93          	addi	s5,s5,-1202 # 8022f9e0 <wait_lock>
      if(p->state == RUNNABLE) {
    80001e9a:	4a0d                	li	s4,3
    80001e9c:	a8c9                	j	80001f6e <scheduler+0x180>
      for(p = proc; p < &proc[NPROC]; p++){
    80001e9e:	0022e497          	auipc	s1,0x22e
    80001ea2:	f5a48493          	addi	s1,s1,-166 # 8022fdf8 <proc>
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    80001ea6:	06400c93          	li	s9,100
    80001eaa:	a811                	j	80001ebe <scheduler+0xd0>
    80001eac:	1794a423          	sw	s9,360(s1)
          release(&p->lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	e4ffe0ef          	jal	ra,80000d00 <release>
      for(p = proc; p < &proc[NPROC]; p++){
    80001eb6:	17848493          	addi	s1,s1,376
    80001eba:	03348963          	beq	s1,s3,80001eec <scheduler+0xfe>
        if(p != best){
    80001ebe:	fe990ce3          	beq	s2,s1,80001eb6 <scheduler+0xc8>
          acquire(&p->lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	da5fe0ef          	jal	ra,80000c68 <acquire>
          if(p->state == RUNNABLE){
    80001ec8:	4c9c                	lw	a5,24(s1)
    80001eca:	ff4793e3          	bne	a5,s4,80001eb0 <scheduler+0xc2>
            p->wait_ticks++;
    80001ece:	16c4a783          	lw	a5,364(s1)
    80001ed2:	2785                	addiw	a5,a5,1
    80001ed4:	16f4a623          	sw	a5,364(s1)
            p->priority += SCHED_ALPHA;
    80001ed8:	1684a783          	lw	a5,360(s1)
    80001edc:	2785                	addiw	a5,a5,1
    80001ede:	0007871b          	sext.w	a4,a5
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    80001ee2:	fcecc5e3          	blt	s9,a4,80001eac <scheduler+0xbe>
            p->priority += SCHED_ALPHA;
    80001ee6:	16f4a423          	sw	a5,360(s1)
    80001eea:	b7d9                	j	80001eb0 <scheduler+0xc2>
      printf("sched: pid=%d name=%s pri=%d wait=%d cpu=%d\n",
    80001eec:	17092783          	lw	a5,368(s2)
    80001ef0:	16c92703          	lw	a4,364(s2)
    80001ef4:	16892683          	lw	a3,360(s2)
    80001ef8:	15890613          	addi	a2,s2,344
    80001efc:	03092583          	lw	a1,48(s2)
    80001f00:	00005517          	auipc	a0,0x5
    80001f04:	2d050513          	addi	a0,a0,720 # 800071d0 <digits+0x198>
    80001f08:	d9cfe0ef          	jal	ra,800004a4 <printf>
      best->state = RUNNING;
    80001f0c:	4791                	li	a5,4
    80001f0e:	00f92c23          	sw	a5,24(s2)
      c->proc = best;
    80001f12:	032b3823          	sd	s2,48(s6)
      release(&wait_lock);
    80001f16:	8556                	mv	a0,s5
    80001f18:	de9fe0ef          	jal	ra,80000d00 <release>
      swtch(&c->context, &best->context);
    80001f1c:	06090593          	addi	a1,s2,96
    80001f20:	8562                	mv	a0,s8
    80001f22:	62a000ef          	jal	ra,8000254c <swtch>
      acquire(&wait_lock);
    80001f26:	8556                	mv	a0,s5
    80001f28:	d41fe0ef          	jal	ra,80000c68 <acquire>
      window_tick++;
    80001f2c:	000ba783          	lw	a5,0(s7)
    80001f30:	2785                	addiw	a5,a5,1
    80001f32:	0007871b          	sext.w	a4,a5
    80001f36:	00fba023          	sw	a5,0(s7)
      if(best->cpu_ticks > SCHED_TCPU_MAX){
    80001f3a:	17092683          	lw	a3,368(s2)
    80001f3e:	47a9                	li	a5,10
    80001f40:	00d7db63          	bge	a5,a3,80001f56 <scheduler+0x168>
        best->priority -= SCHED_BETA;
    80001f44:	16892783          	lw	a5,360(s2)
    80001f48:	37f9                	addiw	a5,a5,-2
    80001f4a:	0007869b          	sext.w	a3,a5
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80001f4e:	0406c463          	bltz	a3,80001f96 <scheduler+0x1a8>
        best->priority -= SCHED_BETA;
    80001f52:	16f92423          	sw	a5,360(s2)
      if(window_tick >= SCHED_W){
    80001f56:	03100793          	li	a5,49
    80001f5a:	04e7c163          	blt	a5,a4,80001f9c <scheduler+0x1ae>
      c->proc = 0;
    80001f5e:	020b3823          	sd	zero,48(s6)
      release(&best->lock);
    80001f62:	854a                	mv	a0,s2
    80001f64:	d9dfe0ef          	jal	ra,80000d00 <release>
    release(&wait_lock);
    80001f68:	8556                	mv	a0,s5
    80001f6a:	d97fe0ef          	jal	ra,80000d00 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f72:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f76:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001f7e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f80:	10079073          	csrw	sstatus,a5
    acquire(&wait_lock); // must be acquired before any p->lock.
    80001f84:	8556                	mv	a0,s5
    80001f86:	ce3fe0ef          	jal	ra,80000c68 <acquire>
    best = 0;
    80001f8a:	4901                	li	s2,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	0022e497          	auipc	s1,0x22e
    80001f90:	e6c48493          	addi	s1,s1,-404 # 8022fdf8 <proc>
    80001f94:	b5c1                	j	80001e54 <scheduler+0x66>
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80001f96:	16092423          	sw	zero,360(s2)
    80001f9a:	bf75                	j	80001f56 <scheduler+0x168>
        window_tick = 0;
    80001f9c:	000ba023          	sw	zero,0(s7)
        for(p = proc; p < &proc[NPROC]; p++){
    80001fa0:	0022e497          	auipc	s1,0x22e
    80001fa4:	e5848493          	addi	s1,s1,-424 # 8022fdf8 <proc>
    80001fa8:	a039                	j	80001fb6 <scheduler+0x1c8>
            p->cpu_ticks = 0;
    80001faa:	1604a823          	sw	zero,368(s1)
        for(p = proc; p < &proc[NPROC]; p++){
    80001fae:	17848493          	addi	s1,s1,376
    80001fb2:	fb3486e3          	beq	s1,s3,80001f5e <scheduler+0x170>
          if(p != best){
    80001fb6:	fe990ae3          	beq	s2,s1,80001faa <scheduler+0x1bc>
            acquire(&p->lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	cadfe0ef          	jal	ra,80000c68 <acquire>
            p->cpu_ticks = 0;
    80001fc0:	1604a823          	sw	zero,368(s1)
            release(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	d3bfe0ef          	jal	ra,80000d00 <release>
    80001fca:	b7d5                	j	80001fae <scheduler+0x1c0>

0000000080001fcc <sched>:
{
    80001fcc:	7179                	addi	sp,sp,-48
    80001fce:	f406                	sd	ra,40(sp)
    80001fd0:	f022                	sd	s0,32(sp)
    80001fd2:	ec26                	sd	s1,24(sp)
    80001fd4:	e84a                	sd	s2,16(sp)
    80001fd6:	e44e                	sd	s3,8(sp)
    80001fd8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fda:	985ff0ef          	jal	ra,8000195e <myproc>
    80001fde:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fe0:	c1ffe0ef          	jal	ra,80000bfe <holding>
    80001fe4:	c92d                	beqz	a0,80002056 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	0022e717          	auipc	a4,0x22e
    80001ff0:	9dc70713          	addi	a4,a4,-1572 # 8022f9c8 <pid_lock>
    80001ff4:	97ba                	add	a5,a5,a4
    80001ff6:	0a87a703          	lw	a4,168(a5)
    80001ffa:	4785                	li	a5,1
    80001ffc:	06f71363          	bne	a4,a5,80002062 <sched+0x96>
  if(p->state == RUNNING)
    80002000:	4c98                	lw	a4,24(s1)
    80002002:	4791                	li	a5,4
    80002004:	06f70563          	beq	a4,a5,8000206e <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002008:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000200c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000200e:	e7b5                	bnez	a5,8000207a <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002010:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002012:	0022e917          	auipc	s2,0x22e
    80002016:	9b690913          	addi	s2,s2,-1610 # 8022f9c8 <pid_lock>
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	97ca                	add	a5,a5,s2
    80002020:	0ac7a983          	lw	s3,172(a5)
    80002024:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002026:	2781                	sext.w	a5,a5
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	0022e597          	auipc	a1,0x22e
    8000202e:	9d658593          	addi	a1,a1,-1578 # 8022fa00 <cpus+0x8>
    80002032:	95be                	add	a1,a1,a5
    80002034:	06048513          	addi	a0,s1,96
    80002038:	514000ef          	jal	ra,8000254c <swtch>
    8000203c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0b37a623          	sw	s3,172(a5)
}
    80002048:	70a2                	ld	ra,40(sp)
    8000204a:	7402                	ld	s0,32(sp)
    8000204c:	64e2                	ld	s1,24(sp)
    8000204e:	6942                	ld	s2,16(sp)
    80002050:	69a2                	ld	s3,8(sp)
    80002052:	6145                	addi	sp,sp,48
    80002054:	8082                	ret
    panic("sched p->lock");
    80002056:	00005517          	auipc	a0,0x5
    8000205a:	1aa50513          	addi	a0,a0,426 # 80007200 <digits+0x1c8>
    8000205e:	f0cfe0ef          	jal	ra,8000076a <panic>
    panic("sched locks");
    80002062:	00005517          	auipc	a0,0x5
    80002066:	1ae50513          	addi	a0,a0,430 # 80007210 <digits+0x1d8>
    8000206a:	f00fe0ef          	jal	ra,8000076a <panic>
    panic("sched RUNNING");
    8000206e:	00005517          	auipc	a0,0x5
    80002072:	1b250513          	addi	a0,a0,434 # 80007220 <digits+0x1e8>
    80002076:	ef4fe0ef          	jal	ra,8000076a <panic>
    panic("sched interruptible");
    8000207a:	00005517          	auipc	a0,0x5
    8000207e:	1b650513          	addi	a0,a0,438 # 80007230 <digits+0x1f8>
    80002082:	ee8fe0ef          	jal	ra,8000076a <panic>

0000000080002086 <yield>:
{
    80002086:	1101                	addi	sp,sp,-32
    80002088:	ec06                	sd	ra,24(sp)
    8000208a:	e822                	sd	s0,16(sp)
    8000208c:	e426                	sd	s1,8(sp)
    8000208e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002090:	8cfff0ef          	jal	ra,8000195e <myproc>
    80002094:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002096:	bd3fe0ef          	jal	ra,80000c68 <acquire>
  p->state = RUNNABLE;
    8000209a:	478d                	li	a5,3
    8000209c:	cc9c                	sw	a5,24(s1)
  sched();
    8000209e:	f2fff0ef          	jal	ra,80001fcc <sched>
  release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	c5dfe0ef          	jal	ra,80000d00 <release>
}
    800020a8:	60e2                	ld	ra,24(sp)
    800020aa:	6442                	ld	s0,16(sp)
    800020ac:	64a2                	ld	s1,8(sp)
    800020ae:	6105                	addi	sp,sp,32
    800020b0:	8082                	ret

00000000800020b2 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020b2:	7179                	addi	sp,sp,-48
    800020b4:	f406                	sd	ra,40(sp)
    800020b6:	f022                	sd	s0,32(sp)
    800020b8:	ec26                	sd	s1,24(sp)
    800020ba:	e84a                	sd	s2,16(sp)
    800020bc:	e44e                	sd	s3,8(sp)
    800020be:	1800                	addi	s0,sp,48
    800020c0:	89aa                	mv	s3,a0
    800020c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c4:	89bff0ef          	jal	ra,8000195e <myproc>
    800020c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020ca:	b9ffe0ef          	jal	ra,80000c68 <acquire>
  release(lk);
    800020ce:	854a                	mv	a0,s2
    800020d0:	c31fe0ef          	jal	ra,80000d00 <release>

  // Go to sleep.
  p->chan = chan;
    800020d4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d8:	4789                	li	a5,2
    800020da:	cc9c                	sw	a5,24(s1)

  sched();
    800020dc:	ef1ff0ef          	jal	ra,80001fcc <sched>

  // Tidy up.
  p->chan = 0;
    800020e0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	c1bfe0ef          	jal	ra,80000d00 <release>
  acquire(lk);
    800020ea:	854a                	mv	a0,s2
    800020ec:	b7dfe0ef          	jal	ra,80000c68 <acquire>
}
    800020f0:	70a2                	ld	ra,40(sp)
    800020f2:	7402                	ld	s0,32(sp)
    800020f4:	64e2                	ld	s1,24(sp)
    800020f6:	6942                	ld	s2,16(sp)
    800020f8:	69a2                	ld	s3,8(sp)
    800020fa:	6145                	addi	sp,sp,48
    800020fc:	8082                	ret

00000000800020fe <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    800020fe:	7139                	addi	sp,sp,-64
    80002100:	fc06                	sd	ra,56(sp)
    80002102:	f822                	sd	s0,48(sp)
    80002104:	f426                	sd	s1,40(sp)
    80002106:	f04a                	sd	s2,32(sp)
    80002108:	ec4e                	sd	s3,24(sp)
    8000210a:	e852                	sd	s4,16(sp)
    8000210c:	e456                	sd	s5,8(sp)
    8000210e:	0080                	addi	s0,sp,64
    80002110:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002112:	0022e497          	auipc	s1,0x22e
    80002116:	ce648493          	addi	s1,s1,-794 # 8022fdf8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000211a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000211c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000211e:	00234917          	auipc	s2,0x234
    80002122:	ada90913          	addi	s2,s2,-1318 # 80235bf8 <tickslock>
    80002126:	a801                	j	80002136 <wakeup+0x38>
      }
      release(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	bd7fe0ef          	jal	ra,80000d00 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000212e:	17848493          	addi	s1,s1,376
    80002132:	03248263          	beq	s1,s2,80002156 <wakeup+0x58>
    if(p != myproc()){
    80002136:	829ff0ef          	jal	ra,8000195e <myproc>
    8000213a:	fea48ae3          	beq	s1,a0,8000212e <wakeup+0x30>
      acquire(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	b29fe0ef          	jal	ra,80000c68 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002144:	4c9c                	lw	a5,24(s1)
    80002146:	ff3791e3          	bne	a5,s3,80002128 <wakeup+0x2a>
    8000214a:	709c                	ld	a5,32(s1)
    8000214c:	fd479ee3          	bne	a5,s4,80002128 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002150:	0154ac23          	sw	s5,24(s1)
    80002154:	bfd1                	j	80002128 <wakeup+0x2a>
    }
  }
}
    80002156:	70e2                	ld	ra,56(sp)
    80002158:	7442                	ld	s0,48(sp)
    8000215a:	74a2                	ld	s1,40(sp)
    8000215c:	7902                	ld	s2,32(sp)
    8000215e:	69e2                	ld	s3,24(sp)
    80002160:	6a42                	ld	s4,16(sp)
    80002162:	6aa2                	ld	s5,8(sp)
    80002164:	6121                	addi	sp,sp,64
    80002166:	8082                	ret

0000000080002168 <reparent>:
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	e052                	sd	s4,0(sp)
    80002176:	1800                	addi	s0,sp,48
    80002178:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000217a:	0022e497          	auipc	s1,0x22e
    8000217e:	c7e48493          	addi	s1,s1,-898 # 8022fdf8 <proc>
      pp->parent = initproc;
    80002182:	00005a17          	auipc	s4,0x5
    80002186:	736a0a13          	addi	s4,s4,1846 # 800078b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000218a:	00234997          	auipc	s3,0x234
    8000218e:	a6e98993          	addi	s3,s3,-1426 # 80235bf8 <tickslock>
    80002192:	a029                	j	8000219c <reparent+0x34>
    80002194:	17848493          	addi	s1,s1,376
    80002198:	01348b63          	beq	s1,s3,800021ae <reparent+0x46>
    if(pp->parent == p){
    8000219c:	7c9c                	ld	a5,56(s1)
    8000219e:	ff279be3          	bne	a5,s2,80002194 <reparent+0x2c>
      pp->parent = initproc;
    800021a2:	000a3503          	ld	a0,0(s4)
    800021a6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021a8:	f57ff0ef          	jal	ra,800020fe <wakeup>
    800021ac:	b7e5                	j	80002194 <reparent+0x2c>
}
    800021ae:	70a2                	ld	ra,40(sp)
    800021b0:	7402                	ld	s0,32(sp)
    800021b2:	64e2                	ld	s1,24(sp)
    800021b4:	6942                	ld	s2,16(sp)
    800021b6:	69a2                	ld	s3,8(sp)
    800021b8:	6a02                	ld	s4,0(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret

00000000800021be <kexit>:
{
    800021be:	7179                	addi	sp,sp,-48
    800021c0:	f406                	sd	ra,40(sp)
    800021c2:	f022                	sd	s0,32(sp)
    800021c4:	ec26                	sd	s1,24(sp)
    800021c6:	e84a                	sd	s2,16(sp)
    800021c8:	e44e                	sd	s3,8(sp)
    800021ca:	e052                	sd	s4,0(sp)
    800021cc:	1800                	addi	s0,sp,48
    800021ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021d0:	f8eff0ef          	jal	ra,8000195e <myproc>
    800021d4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021d6:	00005797          	auipc	a5,0x5
    800021da:	6e27b783          	ld	a5,1762(a5) # 800078b8 <initproc>
    800021de:	0d050493          	addi	s1,a0,208
    800021e2:	15050913          	addi	s2,a0,336
    800021e6:	00a79f63          	bne	a5,a0,80002204 <kexit+0x46>
    panic("init exiting");
    800021ea:	00005517          	auipc	a0,0x5
    800021ee:	05e50513          	addi	a0,a0,94 # 80007248 <digits+0x210>
    800021f2:	d78fe0ef          	jal	ra,8000076a <panic>
      fileclose(f);
    800021f6:	7af010ef          	jal	ra,800041a4 <fileclose>
      p->ofile[fd] = 0;
    800021fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021fe:	04a1                	addi	s1,s1,8
    80002200:	01248563          	beq	s1,s2,8000220a <kexit+0x4c>
    if(p->ofile[fd]){
    80002204:	6088                	ld	a0,0(s1)
    80002206:	f965                	bnez	a0,800021f6 <kexit+0x38>
    80002208:	bfdd                	j	800021fe <kexit+0x40>
  begin_op();
    8000220a:	38d010ef          	jal	ra,80003d96 <begin_op>
  iput(p->cwd);
    8000220e:	1509b503          	ld	a0,336(s3)
    80002212:	324010ef          	jal	ra,80003536 <iput>
  end_op();
    80002216:	3f1010ef          	jal	ra,80003e06 <end_op>
  p->cwd = 0;
    8000221a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000221e:	0022d497          	auipc	s1,0x22d
    80002222:	7c248493          	addi	s1,s1,1986 # 8022f9e0 <wait_lock>
    80002226:	8526                	mv	a0,s1
    80002228:	a41fe0ef          	jal	ra,80000c68 <acquire>
  reparent(p);
    8000222c:	854e                	mv	a0,s3
    8000222e:	f3bff0ef          	jal	ra,80002168 <reparent>
  wakeup(p->parent);
    80002232:	0389b503          	ld	a0,56(s3)
    80002236:	ec9ff0ef          	jal	ra,800020fe <wakeup>
  acquire(&p->lock);
    8000223a:	854e                	mv	a0,s3
    8000223c:	a2dfe0ef          	jal	ra,80000c68 <acquire>
  p->xstate = status;
    80002240:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002244:	4795                	li	a5,5
    80002246:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000224a:	8526                	mv	a0,s1
    8000224c:	ab5fe0ef          	jal	ra,80000d00 <release>
  sched();
    80002250:	d7dff0ef          	jal	ra,80001fcc <sched>
  panic("zombie exit");
    80002254:	00005517          	auipc	a0,0x5
    80002258:	00450513          	addi	a0,a0,4 # 80007258 <digits+0x220>
    8000225c:	d0efe0ef          	jal	ra,8000076a <panic>

0000000080002260 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002260:	7179                	addi	sp,sp,-48
    80002262:	f406                	sd	ra,40(sp)
    80002264:	f022                	sd	s0,32(sp)
    80002266:	ec26                	sd	s1,24(sp)
    80002268:	e84a                	sd	s2,16(sp)
    8000226a:	e44e                	sd	s3,8(sp)
    8000226c:	1800                	addi	s0,sp,48
    8000226e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002270:	0022e497          	auipc	s1,0x22e
    80002274:	b8848493          	addi	s1,s1,-1144 # 8022fdf8 <proc>
    80002278:	00234997          	auipc	s3,0x234
    8000227c:	98098993          	addi	s3,s3,-1664 # 80235bf8 <tickslock>
    acquire(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	9e7fe0ef          	jal	ra,80000c68 <acquire>
    if(p->pid == pid){
    80002286:	589c                	lw	a5,48(s1)
    80002288:	01278b63          	beq	a5,s2,8000229e <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	a73fe0ef          	jal	ra,80000d00 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002292:	17848493          	addi	s1,s1,376
    80002296:	ff3495e3          	bne	s1,s3,80002280 <kkill+0x20>
  }
  return -1;
    8000229a:	557d                	li	a0,-1
    8000229c:	a819                	j	800022b2 <kkill+0x52>
      p->killed = 1;
    8000229e:	4785                	li	a5,1
    800022a0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a2:	4c98                	lw	a4,24(s1)
    800022a4:	4789                	li	a5,2
    800022a6:	00f70d63          	beq	a4,a5,800022c0 <kkill+0x60>
      release(&p->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	a55fe0ef          	jal	ra,80000d00 <release>
      return 0;
    800022b0:	4501                	li	a0,0
}
    800022b2:	70a2                	ld	ra,40(sp)
    800022b4:	7402                	ld	s0,32(sp)
    800022b6:	64e2                	ld	s1,24(sp)
    800022b8:	6942                	ld	s2,16(sp)
    800022ba:	69a2                	ld	s3,8(sp)
    800022bc:	6145                	addi	sp,sp,48
    800022be:	8082                	ret
        p->state = RUNNABLE;
    800022c0:	478d                	li	a5,3
    800022c2:	cc9c                	sw	a5,24(s1)
    800022c4:	b7dd                	j	800022aa <kkill+0x4a>

00000000800022c6 <setkilled>:

void
setkilled(struct proc *p)
{
    800022c6:	1101                	addi	sp,sp,-32
    800022c8:	ec06                	sd	ra,24(sp)
    800022ca:	e822                	sd	s0,16(sp)
    800022cc:	e426                	sd	s1,8(sp)
    800022ce:	1000                	addi	s0,sp,32
    800022d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d2:	997fe0ef          	jal	ra,80000c68 <acquire>
  p->killed = 1;
    800022d6:	4785                	li	a5,1
    800022d8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	a25fe0ef          	jal	ra,80000d00 <release>
}
    800022e0:	60e2                	ld	ra,24(sp)
    800022e2:	6442                	ld	s0,16(sp)
    800022e4:	64a2                	ld	s1,8(sp)
    800022e6:	6105                	addi	sp,sp,32
    800022e8:	8082                	ret

00000000800022ea <killed>:

int
killed(struct proc *p)
{
    800022ea:	1101                	addi	sp,sp,-32
    800022ec:	ec06                	sd	ra,24(sp)
    800022ee:	e822                	sd	s0,16(sp)
    800022f0:	e426                	sd	s1,8(sp)
    800022f2:	e04a                	sd	s2,0(sp)
    800022f4:	1000                	addi	s0,sp,32
    800022f6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800022f8:	971fe0ef          	jal	ra,80000c68 <acquire>
  k = p->killed;
    800022fc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	9fffe0ef          	jal	ra,80000d00 <release>
  return k;
}
    80002306:	854a                	mv	a0,s2
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6902                	ld	s2,0(sp)
    80002310:	6105                	addi	sp,sp,32
    80002312:	8082                	ret

0000000080002314 <kwait>:
{
    80002314:	715d                	addi	sp,sp,-80
    80002316:	e486                	sd	ra,72(sp)
    80002318:	e0a2                	sd	s0,64(sp)
    8000231a:	fc26                	sd	s1,56(sp)
    8000231c:	f84a                	sd	s2,48(sp)
    8000231e:	f44e                	sd	s3,40(sp)
    80002320:	f052                	sd	s4,32(sp)
    80002322:	ec56                	sd	s5,24(sp)
    80002324:	e85a                	sd	s6,16(sp)
    80002326:	e45e                	sd	s7,8(sp)
    80002328:	e062                	sd	s8,0(sp)
    8000232a:	0880                	addi	s0,sp,80
    8000232c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000232e:	e30ff0ef          	jal	ra,8000195e <myproc>
    80002332:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002334:	0022d517          	auipc	a0,0x22d
    80002338:	6ac50513          	addi	a0,a0,1708 # 8022f9e0 <wait_lock>
    8000233c:	92dfe0ef          	jal	ra,80000c68 <acquire>
    havekids = 0;
    80002340:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002342:	4a15                	li	s4,5
        havekids = 1;
    80002344:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002346:	00234997          	auipc	s3,0x234
    8000234a:	8b298993          	addi	s3,s3,-1870 # 80235bf8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000234e:	0022dc17          	auipc	s8,0x22d
    80002352:	692c0c13          	addi	s8,s8,1682 # 8022f9e0 <wait_lock>
    havekids = 0;
    80002356:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002358:	0022e497          	auipc	s1,0x22e
    8000235c:	aa048493          	addi	s1,s1,-1376 # 8022fdf8 <proc>
    80002360:	a899                	j	800023b6 <kwait+0xa2>
          pid = pp->pid;
    80002362:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002366:	000b0c63          	beqz	s6,8000237e <kwait+0x6a>
    8000236a:	4691                	li	a3,4
    8000236c:	02c48613          	addi	a2,s1,44
    80002370:	85da                	mv	a1,s6
    80002372:	05093503          	ld	a0,80(s2)
    80002376:	b16ff0ef          	jal	ra,8000168c <copyout>
    8000237a:	00054f63          	bltz	a0,80002398 <kwait+0x84>
          freeproc(pp);
    8000237e:	8526                	mv	a0,s1
    80002380:	faeff0ef          	jal	ra,80001b2e <freeproc>
          release(&pp->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	97bfe0ef          	jal	ra,80000d00 <release>
          release(&wait_lock);
    8000238a:	0022d517          	auipc	a0,0x22d
    8000238e:	65650513          	addi	a0,a0,1622 # 8022f9e0 <wait_lock>
    80002392:	96ffe0ef          	jal	ra,80000d00 <release>
          return pid;
    80002396:	a891                	j	800023ea <kwait+0xd6>
            release(&pp->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	967fe0ef          	jal	ra,80000d00 <release>
            release(&wait_lock);
    8000239e:	0022d517          	auipc	a0,0x22d
    800023a2:	64250513          	addi	a0,a0,1602 # 8022f9e0 <wait_lock>
    800023a6:	95bfe0ef          	jal	ra,80000d00 <release>
            return -1;
    800023aa:	59fd                	li	s3,-1
    800023ac:	a83d                	j	800023ea <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ae:	17848493          	addi	s1,s1,376
    800023b2:	03348063          	beq	s1,s3,800023d2 <kwait+0xbe>
      if(pp->parent == p){
    800023b6:	7c9c                	ld	a5,56(s1)
    800023b8:	ff279be3          	bne	a5,s2,800023ae <kwait+0x9a>
        acquire(&pp->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	8abfe0ef          	jal	ra,80000c68 <acquire>
        if(pp->state == ZOMBIE){
    800023c2:	4c9c                	lw	a5,24(s1)
    800023c4:	f9478fe3          	beq	a5,s4,80002362 <kwait+0x4e>
        release(&pp->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	937fe0ef          	jal	ra,80000d00 <release>
        havekids = 1;
    800023ce:	8756                	mv	a4,s5
    800023d0:	bff9                	j	800023ae <kwait+0x9a>
    if(!havekids || killed(p)){
    800023d2:	c709                	beqz	a4,800023dc <kwait+0xc8>
    800023d4:	854a                	mv	a0,s2
    800023d6:	f15ff0ef          	jal	ra,800022ea <killed>
    800023da:	c50d                	beqz	a0,80002404 <kwait+0xf0>
      release(&wait_lock);
    800023dc:	0022d517          	auipc	a0,0x22d
    800023e0:	60450513          	addi	a0,a0,1540 # 8022f9e0 <wait_lock>
    800023e4:	91dfe0ef          	jal	ra,80000d00 <release>
      return -1;
    800023e8:	59fd                	li	s3,-1
}
    800023ea:	854e                	mv	a0,s3
    800023ec:	60a6                	ld	ra,72(sp)
    800023ee:	6406                	ld	s0,64(sp)
    800023f0:	74e2                	ld	s1,56(sp)
    800023f2:	7942                	ld	s2,48(sp)
    800023f4:	79a2                	ld	s3,40(sp)
    800023f6:	7a02                	ld	s4,32(sp)
    800023f8:	6ae2                	ld	s5,24(sp)
    800023fa:	6b42                	ld	s6,16(sp)
    800023fc:	6ba2                	ld	s7,8(sp)
    800023fe:	6c02                	ld	s8,0(sp)
    80002400:	6161                	addi	sp,sp,80
    80002402:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002404:	85e2                	mv	a1,s8
    80002406:	854a                	mv	a0,s2
    80002408:	cabff0ef          	jal	ra,800020b2 <sleep>
    havekids = 0;
    8000240c:	b7a9                	j	80002356 <kwait+0x42>

000000008000240e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000240e:	7179                	addi	sp,sp,-48
    80002410:	f406                	sd	ra,40(sp)
    80002412:	f022                	sd	s0,32(sp)
    80002414:	ec26                	sd	s1,24(sp)
    80002416:	e84a                	sd	s2,16(sp)
    80002418:	e44e                	sd	s3,8(sp)
    8000241a:	e052                	sd	s4,0(sp)
    8000241c:	1800                	addi	s0,sp,48
    8000241e:	84aa                	mv	s1,a0
    80002420:	892e                	mv	s2,a1
    80002422:	89b2                	mv	s3,a2
    80002424:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002426:	d38ff0ef          	jal	ra,8000195e <myproc>
  if(user_dst){
    8000242a:	cc99                	beqz	s1,80002448 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000242c:	86d2                	mv	a3,s4
    8000242e:	864e                	mv	a2,s3
    80002430:	85ca                	mv	a1,s2
    80002432:	6928                	ld	a0,80(a0)
    80002434:	a58ff0ef          	jal	ra,8000168c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002438:	70a2                	ld	ra,40(sp)
    8000243a:	7402                	ld	s0,32(sp)
    8000243c:	64e2                	ld	s1,24(sp)
    8000243e:	6942                	ld	s2,16(sp)
    80002440:	69a2                	ld	s3,8(sp)
    80002442:	6a02                	ld	s4,0(sp)
    80002444:	6145                	addi	sp,sp,48
    80002446:	8082                	ret
    memmove((char *)dst, src, len);
    80002448:	000a061b          	sext.w	a2,s4
    8000244c:	85ce                	mv	a1,s3
    8000244e:	854a                	mv	a0,s2
    80002450:	949fe0ef          	jal	ra,80000d98 <memmove>
    return 0;
    80002454:	8526                	mv	a0,s1
    80002456:	b7cd                	j	80002438 <either_copyout+0x2a>

0000000080002458 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	892a                	mv	s2,a0
    8000246a:	84ae                	mv	s1,a1
    8000246c:	89b2                	mv	s3,a2
    8000246e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002470:	ceeff0ef          	jal	ra,8000195e <myproc>
  if(user_src){
    80002474:	cc99                	beqz	s1,80002492 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	ad4ff0ef          	jal	ra,80001752 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove(dst, (char*)src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	8fffe0ef          	jal	ra,80000d98 <memmove>
    return 0;
    8000249e:	8526                	mv	a0,s1
    800024a0:	b7cd                	j	80002482 <either_copyin+0x2a>

00000000800024a2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024a2:	715d                	addi	sp,sp,-80
    800024a4:	e486                	sd	ra,72(sp)
    800024a6:	e0a2                	sd	s0,64(sp)
    800024a8:	fc26                	sd	s1,56(sp)
    800024aa:	f84a                	sd	s2,48(sp)
    800024ac:	f44e                	sd	s3,40(sp)
    800024ae:	f052                	sd	s4,32(sp)
    800024b0:	ec56                	sd	s5,24(sp)
    800024b2:	e85a                	sd	s6,16(sp)
    800024b4:	e45e                	sd	s7,8(sp)
    800024b6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024b8:	00005517          	auipc	a0,0x5
    800024bc:	c2850513          	addi	a0,a0,-984 # 800070e0 <digits+0xa8>
    800024c0:	fe5fd0ef          	jal	ra,800004a4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024c4:	0022e497          	auipc	s1,0x22e
    800024c8:	a8c48493          	addi	s1,s1,-1396 # 8022ff50 <proc+0x158>
    800024cc:	00234917          	auipc	s2,0x234
    800024d0:	88490913          	addi	s2,s2,-1916 # 80235d50 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024d4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024d6:	00005997          	auipc	s3,0x5
    800024da:	d9298993          	addi	s3,s3,-622 # 80007268 <digits+0x230>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    800024de:	00005a97          	auipc	s5,0x5
    800024e2:	d92a8a93          	addi	s5,s5,-622 # 80007270 <digits+0x238>
           p->priority, p->wait_ticks, p->cpu_ticks);
    printf("\n");
    800024e6:	00005a17          	auipc	s4,0x5
    800024ea:	bfaa0a13          	addi	s4,s4,-1030 # 800070e0 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024ee:	00005b97          	auipc	s7,0x5
    800024f2:	dd2b8b93          	addi	s7,s7,-558 # 800072c0 <states.0>
    800024f6:	a00d                	j	80002518 <procdump+0x76>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    800024f8:	0186a803          	lw	a6,24(a3)
    800024fc:	4adc                	lw	a5,20(a3)
    800024fe:	4a98                	lw	a4,16(a3)
    80002500:	ed86a583          	lw	a1,-296(a3)
    80002504:	8556                	mv	a0,s5
    80002506:	f9ffd0ef          	jal	ra,800004a4 <printf>
    printf("\n");
    8000250a:	8552                	mv	a0,s4
    8000250c:	f99fd0ef          	jal	ra,800004a4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002510:	17848493          	addi	s1,s1,376
    80002514:	03248163          	beq	s1,s2,80002536 <procdump+0x94>
    if(p->state == UNUSED)
    80002518:	86a6                	mv	a3,s1
    8000251a:	ec04a783          	lw	a5,-320(s1)
    8000251e:	dbed                	beqz	a5,80002510 <procdump+0x6e>
      state = "???";
    80002520:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002522:	fcfb6be3          	bltu	s6,a5,800024f8 <procdump+0x56>
    80002526:	1782                	slli	a5,a5,0x20
    80002528:	9381                	srli	a5,a5,0x20
    8000252a:	078e                	slli	a5,a5,0x3
    8000252c:	97de                	add	a5,a5,s7
    8000252e:	6390                	ld	a2,0(a5)
    80002530:	f661                	bnez	a2,800024f8 <procdump+0x56>
      state = "???";
    80002532:	864e                	mv	a2,s3
    80002534:	b7d1                	j	800024f8 <procdump+0x56>
  }
}
    80002536:	60a6                	ld	ra,72(sp)
    80002538:	6406                	ld	s0,64(sp)
    8000253a:	74e2                	ld	s1,56(sp)
    8000253c:	7942                	ld	s2,48(sp)
    8000253e:	79a2                	ld	s3,40(sp)
    80002540:	7a02                	ld	s4,32(sp)
    80002542:	6ae2                	ld	s5,24(sp)
    80002544:	6b42                	ld	s6,16(sp)
    80002546:	6ba2                	ld	s7,8(sp)
    80002548:	6161                	addi	sp,sp,80
    8000254a:	8082                	ret

000000008000254c <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    8000254c:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002550:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002554:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002556:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002558:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    8000255c:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002560:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002564:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002568:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    8000256c:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002570:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002574:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002578:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    8000257c:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002580:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002584:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002588:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    8000258a:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    8000258c:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002590:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002594:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002598:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    8000259c:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800025a0:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800025a4:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800025a8:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800025ac:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800025b0:	0685bd83          	ld	s11,104(a1)
        
        ret
    800025b4:	8082                	ret

00000000800025b6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025b6:	1141                	addi	sp,sp,-16
    800025b8:	e406                	sd	ra,8(sp)
    800025ba:	e022                	sd	s0,0(sp)
    800025bc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025be:	00005597          	auipc	a1,0x5
    800025c2:	d3258593          	addi	a1,a1,-718 # 800072f0 <states.0+0x30>
    800025c6:	00233517          	auipc	a0,0x233
    800025ca:	63250513          	addi	a0,a0,1586 # 80235bf8 <tickslock>
    800025ce:	e1afe0ef          	jal	ra,80000be8 <initlock>
}
    800025d2:	60a2                	ld	ra,8(sp)
    800025d4:	6402                	ld	s0,0(sp)
    800025d6:	0141                	addi	sp,sp,16
    800025d8:	8082                	ret

00000000800025da <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025da:	1141                	addi	sp,sp,-16
    800025dc:	e422                	sd	s0,8(sp)
    800025de:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025e0:	00003797          	auipc	a5,0x3
    800025e4:	e9078793          	addi	a5,a5,-368 # 80005470 <kernelvec>
    800025e8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025ec:	6422                	ld	s0,8(sp)
    800025ee:	0141                	addi	sp,sp,16
    800025f0:	8082                	ret

00000000800025f2 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800025f2:	1141                	addi	sp,sp,-16
    800025f4:	e406                	sd	ra,8(sp)
    800025f6:	e022                	sd	s0,0(sp)
    800025f8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800025fa:	b64ff0ef          	jal	ra,8000195e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002602:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002604:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002608:	04000737          	lui	a4,0x4000
    8000260c:	00004797          	auipc	a5,0x4
    80002610:	9f478793          	addi	a5,a5,-1548 # 80006000 <_trampoline>
    80002614:	00004697          	auipc	a3,0x4
    80002618:	9ec68693          	addi	a3,a3,-1556 # 80006000 <_trampoline>
    8000261c:	8f95                	sub	a5,a5,a3
    8000261e:	177d                	addi	a4,a4,-1
    80002620:	0732                	slli	a4,a4,0xc
    80002622:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002624:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002628:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000262a:	18002773          	csrr	a4,satp
    8000262e:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002630:	6d38                	ld	a4,88(a0)
    80002632:	613c                	ld	a5,64(a0)
    80002634:	6685                	lui	a3,0x1
    80002636:	97b6                	add	a5,a5,a3
    80002638:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000263a:	6d3c                	ld	a5,88(a0)
    8000263c:	00000717          	auipc	a4,0x0
    80002640:	0f470713          	addi	a4,a4,244 # 80002730 <usertrap>
    80002644:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002646:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002648:	8712                	mv	a4,tp
    8000264a:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264c:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002650:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002654:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002658:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000265c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000265e:	6f9c                	ld	a5,24(a5)
    80002660:	14179073          	csrw	sepc,a5
}
    80002664:	60a2                	ld	ra,8(sp)
    80002666:	6402                	ld	s0,0(sp)
    80002668:	0141                	addi	sp,sp,16
    8000266a:	8082                	ret

000000008000266c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000266c:	1101                	addi	sp,sp,-32
    8000266e:	ec06                	sd	ra,24(sp)
    80002670:	e822                	sd	s0,16(sp)
    80002672:	e426                	sd	s1,8(sp)
    80002674:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002676:	abcff0ef          	jal	ra,80001932 <cpuid>
    8000267a:	cd19                	beqz	a0,80002698 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    8000267c:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002680:	000f4737          	lui	a4,0xf4
    80002684:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002688:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    8000268a:	14d79073          	csrw	0x14d,a5
}
    8000268e:	60e2                	ld	ra,24(sp)
    80002690:	6442                	ld	s0,16(sp)
    80002692:	64a2                	ld	s1,8(sp)
    80002694:	6105                	addi	sp,sp,32
    80002696:	8082                	ret
    acquire(&tickslock);
    80002698:	00233497          	auipc	s1,0x233
    8000269c:	56048493          	addi	s1,s1,1376 # 80235bf8 <tickslock>
    800026a0:	8526                	mv	a0,s1
    800026a2:	dc6fe0ef          	jal	ra,80000c68 <acquire>
    ticks++;
    800026a6:	00005517          	auipc	a0,0x5
    800026aa:	21a50513          	addi	a0,a0,538 # 800078c0 <ticks>
    800026ae:	411c                	lw	a5,0(a0)
    800026b0:	2785                	addiw	a5,a5,1
    800026b2:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800026b4:	a4bff0ef          	jal	ra,800020fe <wakeup>
    release(&tickslock);
    800026b8:	8526                	mv	a0,s1
    800026ba:	e46fe0ef          	jal	ra,80000d00 <release>
    800026be:	bf7d                	j	8000267c <clockintr+0x10>

00000000800026c0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026c0:	1101                	addi	sp,sp,-32
    800026c2:	ec06                	sd	ra,24(sp)
    800026c4:	e822                	sd	s0,16(sp)
    800026c6:	e426                	sd	s1,8(sp)
    800026c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026ca:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800026ce:	57fd                	li	a5,-1
    800026d0:	17fe                	slli	a5,a5,0x3f
    800026d2:	07a5                	addi	a5,a5,9
    800026d4:	00f70d63          	beq	a4,a5,800026ee <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800026d8:	57fd                	li	a5,-1
    800026da:	17fe                	slli	a5,a5,0x3f
    800026dc:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800026de:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800026e0:	04f70463          	beq	a4,a5,80002728 <devintr+0x68>
  }
}
    800026e4:	60e2                	ld	ra,24(sp)
    800026e6:	6442                	ld	s0,16(sp)
    800026e8:	64a2                	ld	s1,8(sp)
    800026ea:	6105                	addi	sp,sp,32
    800026ec:	8082                	ret
    int irq = plic_claim();
    800026ee:	62b020ef          	jal	ra,80005518 <plic_claim>
    800026f2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800026f4:	47a9                	li	a5,10
    800026f6:	02f50363          	beq	a0,a5,8000271c <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    800026fa:	4785                	li	a5,1
    800026fc:	02f50363          	beq	a0,a5,80002722 <devintr+0x62>
    return 1;
    80002700:	4505                	li	a0,1
    } else if(irq){
    80002702:	d0ed                	beqz	s1,800026e4 <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    80002704:	85a6                	mv	a1,s1
    80002706:	00005517          	auipc	a0,0x5
    8000270a:	bf250513          	addi	a0,a0,-1038 # 800072f8 <states.0+0x38>
    8000270e:	d97fd0ef          	jal	ra,800004a4 <printf>
      plic_complete(irq);
    80002712:	8526                	mv	a0,s1
    80002714:	625020ef          	jal	ra,80005538 <plic_complete>
    return 1;
    80002718:	4505                	li	a0,1
    8000271a:	b7e9                	j	800026e4 <devintr+0x24>
      uartintr();
    8000271c:	a1cfe0ef          	jal	ra,80000938 <uartintr>
    80002720:	bfcd                	j	80002712 <devintr+0x52>
      virtio_disk_intr();
    80002722:	286030ef          	jal	ra,800059a8 <virtio_disk_intr>
    80002726:	b7f5                	j	80002712 <devintr+0x52>
    clockintr();
    80002728:	f45ff0ef          	jal	ra,8000266c <clockintr>
    return 2;
    8000272c:	4509                	li	a0,2
    8000272e:	bf5d                	j	800026e4 <devintr+0x24>

0000000080002730 <usertrap>:
{
    80002730:	1101                	addi	sp,sp,-32
    80002732:	ec06                	sd	ra,24(sp)
    80002734:	e822                	sd	s0,16(sp)
    80002736:	e426                	sd	s1,8(sp)
    80002738:	e04a                	sd	s2,0(sp)
    8000273a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002740:	1007f793          	andi	a5,a5,256
    80002744:	eba5                	bnez	a5,800027b4 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002746:	00003797          	auipc	a5,0x3
    8000274a:	d2a78793          	addi	a5,a5,-726 # 80005470 <kernelvec>
    8000274e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002752:	a0cff0ef          	jal	ra,8000195e <myproc>
    80002756:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002758:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000275a:	14102773          	csrr	a4,sepc
    8000275e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002760:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002764:	47a1                	li	a5,8
    80002766:	04f70d63          	beq	a4,a5,800027c0 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000276a:	f57ff0ef          	jal	ra,800026c0 <devintr>
    8000276e:	892a                	mv	s2,a0
    80002770:	e945                	bnez	a0,80002820 <usertrap+0xf0>
    80002772:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002776:	47bd                	li	a5,15
    80002778:	08f70863          	beq	a4,a5,80002808 <usertrap+0xd8>
    8000277c:	14202773          	csrr	a4,scause
    80002780:	47b5                	li	a5,13
    80002782:	08f70363          	beq	a4,a5,80002808 <usertrap+0xd8>
    80002786:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000278a:	5890                	lw	a2,48(s1)
    8000278c:	00005517          	auipc	a0,0x5
    80002790:	bac50513          	addi	a0,a0,-1108 # 80007338 <states.0+0x78>
    80002794:	d11fd0ef          	jal	ra,800004a4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002798:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000279c:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800027a0:	00005517          	auipc	a0,0x5
    800027a4:	bc850513          	addi	a0,a0,-1080 # 80007368 <states.0+0xa8>
    800027a8:	cfdfd0ef          	jal	ra,800004a4 <printf>
    setkilled(p);
    800027ac:	8526                	mv	a0,s1
    800027ae:	b19ff0ef          	jal	ra,800022c6 <setkilled>
    800027b2:	a035                	j	800027de <usertrap+0xae>
    panic("usertrap: not from user mode");
    800027b4:	00005517          	auipc	a0,0x5
    800027b8:	b6450513          	addi	a0,a0,-1180 # 80007318 <states.0+0x58>
    800027bc:	faffd0ef          	jal	ra,8000076a <panic>
    if(killed(p))
    800027c0:	b2bff0ef          	jal	ra,800022ea <killed>
    800027c4:	ed15                	bnez	a0,80002800 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800027c6:	6cb8                	ld	a4,88(s1)
    800027c8:	6f1c                	ld	a5,24(a4)
    800027ca:	0791                	addi	a5,a5,4
    800027cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d6:	10079073          	csrw	sstatus,a5
    syscall();
    800027da:	25e000ef          	jal	ra,80002a38 <syscall>
  if(killed(p))
    800027de:	8526                	mv	a0,s1
    800027e0:	b0bff0ef          	jal	ra,800022ea <killed>
    800027e4:	e139                	bnez	a0,8000282a <usertrap+0xfa>
  prepare_return();
    800027e6:	e0dff0ef          	jal	ra,800025f2 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ea:	68a8                	ld	a0,80(s1)
    800027ec:	8131                	srli	a0,a0,0xc
    800027ee:	57fd                	li	a5,-1
    800027f0:	17fe                	slli	a5,a5,0x3f
    800027f2:	8d5d                	or	a0,a0,a5
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6902                	ld	s2,0(sp)
    800027fc:	6105                	addi	sp,sp,32
    800027fe:	8082                	ret
      kexit(-1);
    80002800:	557d                	li	a0,-1
    80002802:	9bdff0ef          	jal	ra,800021be <kexit>
    80002806:	b7c1                	j	800027c6 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002808:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280c:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002810:	164d                	addi	a2,a2,-13
    80002812:	00163613          	seqz	a2,a2
    80002816:	68a8                	ld	a0,80(s1)
    80002818:	d99fe0ef          	jal	ra,800015b0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000281c:	f169                	bnez	a0,800027de <usertrap+0xae>
    8000281e:	b7a5                	j	80002786 <usertrap+0x56>
  if(killed(p))
    80002820:	8526                	mv	a0,s1
    80002822:	ac9ff0ef          	jal	ra,800022ea <killed>
    80002826:	c511                	beqz	a0,80002832 <usertrap+0x102>
    80002828:	a011                	j	8000282c <usertrap+0xfc>
    8000282a:	4901                	li	s2,0
    kexit(-1);
    8000282c:	557d                	li	a0,-1
    8000282e:	991ff0ef          	jal	ra,800021be <kexit>
  if(which_dev == 2){
    80002832:	4789                	li	a5,2
    80002834:	faf919e3          	bne	s2,a5,800027e6 <usertrap+0xb6>
    if(p) p->cpu_ticks++;
    80002838:	1704a783          	lw	a5,368(s1)
    8000283c:	2785                	addiw	a5,a5,1
    8000283e:	16f4a823          	sw	a5,368(s1)
    yield();
    80002842:	845ff0ef          	jal	ra,80002086 <yield>
    80002846:	b745                	j	800027e6 <usertrap+0xb6>

0000000080002848 <kerneltrap>:
{
    80002848:	7179                	addi	sp,sp,-48
    8000284a:	f406                	sd	ra,40(sp)
    8000284c:	f022                	sd	s0,32(sp)
    8000284e:	ec26                	sd	s1,24(sp)
    80002850:	e84a                	sd	s2,16(sp)
    80002852:	e44e                	sd	s3,8(sp)
    80002854:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002856:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002862:	1004f793          	andi	a5,s1,256
    80002866:	c795                	beqz	a5,80002892 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000286c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000286e:	eb85                	bnez	a5,8000289e <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002870:	e51ff0ef          	jal	ra,800026c0 <devintr>
    80002874:	c91d                	beqz	a0,800028aa <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    80002876:	4789                	li	a5,2
    80002878:	04f50a63          	beq	a0,a5,800028cc <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000287c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002880:	10049073          	csrw	sstatus,s1
}
    80002884:	70a2                	ld	ra,40(sp)
    80002886:	7402                	ld	s0,32(sp)
    80002888:	64e2                	ld	s1,24(sp)
    8000288a:	6942                	ld	s2,16(sp)
    8000288c:	69a2                	ld	s3,8(sp)
    8000288e:	6145                	addi	sp,sp,48
    80002890:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002892:	00005517          	auipc	a0,0x5
    80002896:	afe50513          	addi	a0,a0,-1282 # 80007390 <states.0+0xd0>
    8000289a:	ed1fd0ef          	jal	ra,8000076a <panic>
    panic("kerneltrap: interrupts enabled");
    8000289e:	00005517          	auipc	a0,0x5
    800028a2:	b1a50513          	addi	a0,a0,-1254 # 800073b8 <states.0+0xf8>
    800028a6:	ec5fd0ef          	jal	ra,8000076a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028aa:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028ae:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800028b2:	85ce                	mv	a1,s3
    800028b4:	00005517          	auipc	a0,0x5
    800028b8:	b2450513          	addi	a0,a0,-1244 # 800073d8 <states.0+0x118>
    800028bc:	be9fd0ef          	jal	ra,800004a4 <printf>
    panic("kerneltrap");
    800028c0:	00005517          	auipc	a0,0x5
    800028c4:	b4050513          	addi	a0,a0,-1216 # 80007400 <states.0+0x140>
    800028c8:	ea3fd0ef          	jal	ra,8000076a <panic>
  if(which_dev == 2 && myproc() != 0){
    800028cc:	892ff0ef          	jal	ra,8000195e <myproc>
    800028d0:	d555                	beqz	a0,8000287c <kerneltrap+0x34>
    myproc()->cpu_ticks++;
    800028d2:	88cff0ef          	jal	ra,8000195e <myproc>
    800028d6:	17052783          	lw	a5,368(a0)
    800028da:	2785                	addiw	a5,a5,1
    800028dc:	16f52823          	sw	a5,368(a0)
    yield();
    800028e0:	fa6ff0ef          	jal	ra,80002086 <yield>
    800028e4:	bf61                	j	8000287c <kerneltrap+0x34>

00000000800028e6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800028e6:	1101                	addi	sp,sp,-32
    800028e8:	ec06                	sd	ra,24(sp)
    800028ea:	e822                	sd	s0,16(sp)
    800028ec:	e426                	sd	s1,8(sp)
    800028ee:	1000                	addi	s0,sp,32
    800028f0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028f2:	86cff0ef          	jal	ra,8000195e <myproc>
  switch (n) {
    800028f6:	4795                	li	a5,5
    800028f8:	0497e163          	bltu	a5,s1,8000293a <argraw+0x54>
    800028fc:	048a                	slli	s1,s1,0x2
    800028fe:	00005717          	auipc	a4,0x5
    80002902:	b3a70713          	addi	a4,a4,-1222 # 80007438 <states.0+0x178>
    80002906:	94ba                	add	s1,s1,a4
    80002908:	409c                	lw	a5,0(s1)
    8000290a:	97ba                	add	a5,a5,a4
    8000290c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000290e:	6d3c                	ld	a5,88(a0)
    80002910:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002912:	60e2                	ld	ra,24(sp)
    80002914:	6442                	ld	s0,16(sp)
    80002916:	64a2                	ld	s1,8(sp)
    80002918:	6105                	addi	sp,sp,32
    8000291a:	8082                	ret
    return p->trapframe->a1;
    8000291c:	6d3c                	ld	a5,88(a0)
    8000291e:	7fa8                	ld	a0,120(a5)
    80002920:	bfcd                	j	80002912 <argraw+0x2c>
    return p->trapframe->a2;
    80002922:	6d3c                	ld	a5,88(a0)
    80002924:	63c8                	ld	a0,128(a5)
    80002926:	b7f5                	j	80002912 <argraw+0x2c>
    return p->trapframe->a3;
    80002928:	6d3c                	ld	a5,88(a0)
    8000292a:	67c8                	ld	a0,136(a5)
    8000292c:	b7dd                	j	80002912 <argraw+0x2c>
    return p->trapframe->a4;
    8000292e:	6d3c                	ld	a5,88(a0)
    80002930:	6bc8                	ld	a0,144(a5)
    80002932:	b7c5                	j	80002912 <argraw+0x2c>
    return p->trapframe->a5;
    80002934:	6d3c                	ld	a5,88(a0)
    80002936:	6fc8                	ld	a0,152(a5)
    80002938:	bfe9                	j	80002912 <argraw+0x2c>
  panic("argraw");
    8000293a:	00005517          	auipc	a0,0x5
    8000293e:	ad650513          	addi	a0,a0,-1322 # 80007410 <states.0+0x150>
    80002942:	e29fd0ef          	jal	ra,8000076a <panic>

0000000080002946 <fetchaddr>:
{
    80002946:	1101                	addi	sp,sp,-32
    80002948:	ec06                	sd	ra,24(sp)
    8000294a:	e822                	sd	s0,16(sp)
    8000294c:	e426                	sd	s1,8(sp)
    8000294e:	e04a                	sd	s2,0(sp)
    80002950:	1000                	addi	s0,sp,32
    80002952:	84aa                	mv	s1,a0
    80002954:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002956:	808ff0ef          	jal	ra,8000195e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000295a:	653c                	ld	a5,72(a0)
    8000295c:	02f4f663          	bgeu	s1,a5,80002988 <fetchaddr+0x42>
    80002960:	00848713          	addi	a4,s1,8
    80002964:	02e7e463          	bltu	a5,a4,8000298c <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002968:	46a1                	li	a3,8
    8000296a:	8626                	mv	a2,s1
    8000296c:	85ca                	mv	a1,s2
    8000296e:	6928                	ld	a0,80(a0)
    80002970:	de3fe0ef          	jal	ra,80001752 <copyin>
    80002974:	00a03533          	snez	a0,a0
    80002978:	40a00533          	neg	a0,a0
}
    8000297c:	60e2                	ld	ra,24(sp)
    8000297e:	6442                	ld	s0,16(sp)
    80002980:	64a2                	ld	s1,8(sp)
    80002982:	6902                	ld	s2,0(sp)
    80002984:	6105                	addi	sp,sp,32
    80002986:	8082                	ret
    return -1;
    80002988:	557d                	li	a0,-1
    8000298a:	bfcd                	j	8000297c <fetchaddr+0x36>
    8000298c:	557d                	li	a0,-1
    8000298e:	b7fd                	j	8000297c <fetchaddr+0x36>

0000000080002990 <fetchstr>:
{
    80002990:	7179                	addi	sp,sp,-48
    80002992:	f406                	sd	ra,40(sp)
    80002994:	f022                	sd	s0,32(sp)
    80002996:	ec26                	sd	s1,24(sp)
    80002998:	e84a                	sd	s2,16(sp)
    8000299a:	e44e                	sd	s3,8(sp)
    8000299c:	1800                	addi	s0,sp,48
    8000299e:	892a                	mv	s2,a0
    800029a0:	84ae                	mv	s1,a1
    800029a2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800029a4:	fbbfe0ef          	jal	ra,8000195e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800029a8:	86ce                	mv	a3,s3
    800029aa:	864a                	mv	a2,s2
    800029ac:	85a6                	mv	a1,s1
    800029ae:	6928                	ld	a0,80(a0)
    800029b0:	b51fe0ef          	jal	ra,80001500 <copyinstr>
    800029b4:	00054c63          	bltz	a0,800029cc <fetchstr+0x3c>
  return strlen(buf);
    800029b8:	8526                	mv	a0,s1
    800029ba:	cfafe0ef          	jal	ra,80000eb4 <strlen>
}
    800029be:	70a2                	ld	ra,40(sp)
    800029c0:	7402                	ld	s0,32(sp)
    800029c2:	64e2                	ld	s1,24(sp)
    800029c4:	6942                	ld	s2,16(sp)
    800029c6:	69a2                	ld	s3,8(sp)
    800029c8:	6145                	addi	sp,sp,48
    800029ca:	8082                	ret
    return -1;
    800029cc:	557d                	li	a0,-1
    800029ce:	bfc5                	j	800029be <fetchstr+0x2e>

00000000800029d0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800029d0:	1101                	addi	sp,sp,-32
    800029d2:	ec06                	sd	ra,24(sp)
    800029d4:	e822                	sd	s0,16(sp)
    800029d6:	e426                	sd	s1,8(sp)
    800029d8:	1000                	addi	s0,sp,32
    800029da:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800029dc:	f0bff0ef          	jal	ra,800028e6 <argraw>
    800029e0:	c088                	sw	a0,0(s1)
}
    800029e2:	60e2                	ld	ra,24(sp)
    800029e4:	6442                	ld	s0,16(sp)
    800029e6:	64a2                	ld	s1,8(sp)
    800029e8:	6105                	addi	sp,sp,32
    800029ea:	8082                	ret

00000000800029ec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	1000                	addi	s0,sp,32
    800029f6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800029f8:	eefff0ef          	jal	ra,800028e6 <argraw>
    800029fc:	e088                	sd	a0,0(s1)
}
    800029fe:	60e2                	ld	ra,24(sp)
    80002a00:	6442                	ld	s0,16(sp)
    80002a02:	64a2                	ld	s1,8(sp)
    80002a04:	6105                	addi	sp,sp,32
    80002a06:	8082                	ret

0000000080002a08 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a08:	7179                	addi	sp,sp,-48
    80002a0a:	f406                	sd	ra,40(sp)
    80002a0c:	f022                	sd	s0,32(sp)
    80002a0e:	ec26                	sd	s1,24(sp)
    80002a10:	e84a                	sd	s2,16(sp)
    80002a12:	1800                	addi	s0,sp,48
    80002a14:	84ae                	mv	s1,a1
    80002a16:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002a18:	fd840593          	addi	a1,s0,-40
    80002a1c:	fd1ff0ef          	jal	ra,800029ec <argaddr>
  return fetchstr(addr, buf, max);
    80002a20:	864a                	mv	a2,s2
    80002a22:	85a6                	mv	a1,s1
    80002a24:	fd843503          	ld	a0,-40(s0)
    80002a28:	f69ff0ef          	jal	ra,80002990 <fetchstr>
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	6145                	addi	sp,sp,48
    80002a36:	8082                	ret

0000000080002a38 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	e426                	sd	s1,8(sp)
    80002a40:	e04a                	sd	s2,0(sp)
    80002a42:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002a44:	f1bfe0ef          	jal	ra,8000195e <myproc>
    80002a48:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002a4a:	05853903          	ld	s2,88(a0)
    80002a4e:	0a893783          	ld	a5,168(s2)
    80002a52:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002a56:	37fd                	addiw	a5,a5,-1
    80002a58:	4751                	li	a4,20
    80002a5a:	00f76f63          	bltu	a4,a5,80002a78 <syscall+0x40>
    80002a5e:	00369713          	slli	a4,a3,0x3
    80002a62:	00005797          	auipc	a5,0x5
    80002a66:	9ee78793          	addi	a5,a5,-1554 # 80007450 <syscalls>
    80002a6a:	97ba                	add	a5,a5,a4
    80002a6c:	639c                	ld	a5,0(a5)
    80002a6e:	c789                	beqz	a5,80002a78 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002a70:	9782                	jalr	a5
    80002a72:	06a93823          	sd	a0,112(s2)
    80002a76:	a829                	j	80002a90 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002a78:	15848613          	addi	a2,s1,344
    80002a7c:	588c                	lw	a1,48(s1)
    80002a7e:	00005517          	auipc	a0,0x5
    80002a82:	99a50513          	addi	a0,a0,-1638 # 80007418 <states.0+0x158>
    80002a86:	a1ffd0ef          	jal	ra,800004a4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002a8a:	6cbc                	ld	a5,88(s1)
    80002a8c:	577d                	li	a4,-1
    80002a8e:	fbb8                	sd	a4,112(a5)
  }
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6902                	ld	s2,0(sp)
    80002a98:	6105                	addi	sp,sp,32
    80002a9a:	8082                	ret

0000000080002a9c <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002aa4:	fec40593          	addi	a1,s0,-20
    80002aa8:	4501                	li	a0,0
    80002aaa:	f27ff0ef          	jal	ra,800029d0 <argint>
  kexit(n);
    80002aae:	fec42503          	lw	a0,-20(s0)
    80002ab2:	f0cff0ef          	jal	ra,800021be <kexit>
  return 0;  // not reached
}
    80002ab6:	4501                	li	a0,0
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ac0:	1141                	addi	sp,sp,-16
    80002ac2:	e406                	sd	ra,8(sp)
    80002ac4:	e022                	sd	s0,0(sp)
    80002ac6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ac8:	e97fe0ef          	jal	ra,8000195e <myproc>
}
    80002acc:	5908                	lw	a0,48(a0)
    80002ace:	60a2                	ld	ra,8(sp)
    80002ad0:	6402                	ld	s0,0(sp)
    80002ad2:	0141                	addi	sp,sp,16
    80002ad4:	8082                	ret

0000000080002ad6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ad6:	1141                	addi	sp,sp,-16
    80002ad8:	e406                	sd	ra,8(sp)
    80002ada:	e022                	sd	s0,0(sp)
    80002adc:	0800                	addi	s0,sp,16
  return kfork();
    80002ade:	9f4ff0ef          	jal	ra,80001cd2 <kfork>
}
    80002ae2:	60a2                	ld	ra,8(sp)
    80002ae4:	6402                	ld	s0,0(sp)
    80002ae6:	0141                	addi	sp,sp,16
    80002ae8:	8082                	ret

0000000080002aea <sys_wait>:

uint64
sys_wait(void)
{
    80002aea:	1101                	addi	sp,sp,-32
    80002aec:	ec06                	sd	ra,24(sp)
    80002aee:	e822                	sd	s0,16(sp)
    80002af0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002af2:	fe840593          	addi	a1,s0,-24
    80002af6:	4501                	li	a0,0
    80002af8:	ef5ff0ef          	jal	ra,800029ec <argaddr>
  return kwait(p);
    80002afc:	fe843503          	ld	a0,-24(s0)
    80002b00:	815ff0ef          	jal	ra,80002314 <kwait>
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	6105                	addi	sp,sp,32
    80002b0a:	8082                	ret

0000000080002b0c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002b16:	fd840593          	addi	a1,s0,-40
    80002b1a:	4501                	li	a0,0
    80002b1c:	eb5ff0ef          	jal	ra,800029d0 <argint>
  argint(1, &t);
    80002b20:	fdc40593          	addi	a1,s0,-36
    80002b24:	4505                	li	a0,1
    80002b26:	eabff0ef          	jal	ra,800029d0 <argint>
  addr = myproc()->sz;
    80002b2a:	e35fe0ef          	jal	ra,8000195e <myproc>
    80002b2e:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002b30:	fdc42703          	lw	a4,-36(s0)
    80002b34:	4785                	li	a5,1
    80002b36:	02f70763          	beq	a4,a5,80002b64 <sys_sbrk+0x58>
    80002b3a:	fd842783          	lw	a5,-40(s0)
    80002b3e:	0207c363          	bltz	a5,80002b64 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002b42:	97a6                	add	a5,a5,s1
    80002b44:	0297ee63          	bltu	a5,s1,80002b80 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002b48:	02000737          	lui	a4,0x2000
    80002b4c:	177d                	addi	a4,a4,-1
    80002b4e:	0736                	slli	a4,a4,0xd
    80002b50:	02f76a63          	bltu	a4,a5,80002b84 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002b54:	e0bfe0ef          	jal	ra,8000195e <myproc>
    80002b58:	fd842703          	lw	a4,-40(s0)
    80002b5c:	653c                	ld	a5,72(a0)
    80002b5e:	97ba                	add	a5,a5,a4
    80002b60:	e53c                	sd	a5,72(a0)
    80002b62:	a039                	j	80002b70 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002b64:	fd842503          	lw	a0,-40(s0)
    80002b68:	908ff0ef          	jal	ra,80001c70 <growproc>
    80002b6c:	00054863          	bltz	a0,80002b7c <sys_sbrk+0x70>
  }
  return addr;
}
    80002b70:	8526                	mv	a0,s1
    80002b72:	70a2                	ld	ra,40(sp)
    80002b74:	7402                	ld	s0,32(sp)
    80002b76:	64e2                	ld	s1,24(sp)
    80002b78:	6145                	addi	sp,sp,48
    80002b7a:	8082                	ret
      return -1;
    80002b7c:	54fd                	li	s1,-1
    80002b7e:	bfcd                	j	80002b70 <sys_sbrk+0x64>
      return -1;
    80002b80:	54fd                	li	s1,-1
    80002b82:	b7fd                	j	80002b70 <sys_sbrk+0x64>
      return -1;
    80002b84:	54fd                	li	s1,-1
    80002b86:	b7ed                	j	80002b70 <sys_sbrk+0x64>

0000000080002b88 <sys_pause>:

uint64
sys_pause(void)
{
    80002b88:	7139                	addi	sp,sp,-64
    80002b8a:	fc06                	sd	ra,56(sp)
    80002b8c:	f822                	sd	s0,48(sp)
    80002b8e:	f426                	sd	s1,40(sp)
    80002b90:	f04a                	sd	s2,32(sp)
    80002b92:	ec4e                	sd	s3,24(sp)
    80002b94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002b96:	fcc40593          	addi	a1,s0,-52
    80002b9a:	4501                	li	a0,0
    80002b9c:	e35ff0ef          	jal	ra,800029d0 <argint>
  if(n < 0)
    80002ba0:	fcc42783          	lw	a5,-52(s0)
    80002ba4:	0607c563          	bltz	a5,80002c0e <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002ba8:	00233517          	auipc	a0,0x233
    80002bac:	05050513          	addi	a0,a0,80 # 80235bf8 <tickslock>
    80002bb0:	8b8fe0ef          	jal	ra,80000c68 <acquire>
  ticks0 = ticks;
    80002bb4:	00005917          	auipc	s2,0x5
    80002bb8:	d0c92903          	lw	s2,-756(s2) # 800078c0 <ticks>
  while(ticks - ticks0 < n){
    80002bbc:	fcc42783          	lw	a5,-52(s0)
    80002bc0:	cb8d                	beqz	a5,80002bf2 <sys_pause+0x6a>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002bc2:	00233997          	auipc	s3,0x233
    80002bc6:	03698993          	addi	s3,s3,54 # 80235bf8 <tickslock>
    80002bca:	00005497          	auipc	s1,0x5
    80002bce:	cf648493          	addi	s1,s1,-778 # 800078c0 <ticks>
    if(killed(myproc())){
    80002bd2:	d8dfe0ef          	jal	ra,8000195e <myproc>
    80002bd6:	f14ff0ef          	jal	ra,800022ea <killed>
    80002bda:	ed0d                	bnez	a0,80002c14 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002bdc:	85ce                	mv	a1,s3
    80002bde:	8526                	mv	a0,s1
    80002be0:	cd2ff0ef          	jal	ra,800020b2 <sleep>
  while(ticks - ticks0 < n){
    80002be4:	409c                	lw	a5,0(s1)
    80002be6:	412787bb          	subw	a5,a5,s2
    80002bea:	fcc42703          	lw	a4,-52(s0)
    80002bee:	fee7e2e3          	bltu	a5,a4,80002bd2 <sys_pause+0x4a>
  }
  release(&tickslock);
    80002bf2:	00233517          	auipc	a0,0x233
    80002bf6:	00650513          	addi	a0,a0,6 # 80235bf8 <tickslock>
    80002bfa:	906fe0ef          	jal	ra,80000d00 <release>
  return 0;
    80002bfe:	4501                	li	a0,0
}
    80002c00:	70e2                	ld	ra,56(sp)
    80002c02:	7442                	ld	s0,48(sp)
    80002c04:	74a2                	ld	s1,40(sp)
    80002c06:	7902                	ld	s2,32(sp)
    80002c08:	69e2                	ld	s3,24(sp)
    80002c0a:	6121                	addi	sp,sp,64
    80002c0c:	8082                	ret
    n = 0;
    80002c0e:	fc042623          	sw	zero,-52(s0)
    80002c12:	bf59                	j	80002ba8 <sys_pause+0x20>
      release(&tickslock);
    80002c14:	00233517          	auipc	a0,0x233
    80002c18:	fe450513          	addi	a0,a0,-28 # 80235bf8 <tickslock>
    80002c1c:	8e4fe0ef          	jal	ra,80000d00 <release>
      return -1;
    80002c20:	557d                	li	a0,-1
    80002c22:	bff9                	j	80002c00 <sys_pause+0x78>

0000000080002c24 <sys_kill>:

uint64
sys_kill(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002c2c:	fec40593          	addi	a1,s0,-20
    80002c30:	4501                	li	a0,0
    80002c32:	d9fff0ef          	jal	ra,800029d0 <argint>
  return kkill(pid);
    80002c36:	fec42503          	lw	a0,-20(s0)
    80002c3a:	e26ff0ef          	jal	ra,80002260 <kkill>
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002c50:	00233517          	auipc	a0,0x233
    80002c54:	fa850513          	addi	a0,a0,-88 # 80235bf8 <tickslock>
    80002c58:	810fe0ef          	jal	ra,80000c68 <acquire>
  xticks = ticks;
    80002c5c:	00005497          	auipc	s1,0x5
    80002c60:	c644a483          	lw	s1,-924(s1) # 800078c0 <ticks>
  release(&tickslock);
    80002c64:	00233517          	auipc	a0,0x233
    80002c68:	f9450513          	addi	a0,a0,-108 # 80235bf8 <tickslock>
    80002c6c:	894fe0ef          	jal	ra,80000d00 <release>
  return xticks;
}
    80002c70:	02049513          	slli	a0,s1,0x20
    80002c74:	9101                	srli	a0,a0,0x20
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	64a2                	ld	s1,8(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002c80:	7179                	addi	sp,sp,-48
    80002c82:	f406                	sd	ra,40(sp)
    80002c84:	f022                	sd	s0,32(sp)
    80002c86:	ec26                	sd	s1,24(sp)
    80002c88:	e84a                	sd	s2,16(sp)
    80002c8a:	e44e                	sd	s3,8(sp)
    80002c8c:	e052                	sd	s4,0(sp)
    80002c8e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002c90:	00005597          	auipc	a1,0x5
    80002c94:	87058593          	addi	a1,a1,-1936 # 80007500 <syscalls+0xb0>
    80002c98:	00233517          	auipc	a0,0x233
    80002c9c:	f7850513          	addi	a0,a0,-136 # 80235c10 <bcache>
    80002ca0:	f49fd0ef          	jal	ra,80000be8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ca4:	0023b797          	auipc	a5,0x23b
    80002ca8:	f6c78793          	addi	a5,a5,-148 # 8023dc10 <bcache+0x8000>
    80002cac:	0023b717          	auipc	a4,0x23b
    80002cb0:	1cc70713          	addi	a4,a4,460 # 8023de78 <bcache+0x8268>
    80002cb4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002cb8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002cbc:	00233497          	auipc	s1,0x233
    80002cc0:	f6c48493          	addi	s1,s1,-148 # 80235c28 <bcache+0x18>
    b->next = bcache.head.next;
    80002cc4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002cc6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002cc8:	00005a17          	auipc	s4,0x5
    80002ccc:	840a0a13          	addi	s4,s4,-1984 # 80007508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002cd0:	2b893783          	ld	a5,696(s2)
    80002cd4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002cd6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002cda:	85d2                	mv	a1,s4
    80002cdc:	01048513          	addi	a0,s1,16
    80002ce0:	2fe010ef          	jal	ra,80003fde <initsleeplock>
    bcache.head.next->prev = b;
    80002ce4:	2b893783          	ld	a5,696(s2)
    80002ce8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002cea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002cee:	45848493          	addi	s1,s1,1112
    80002cf2:	fd349fe3          	bne	s1,s3,80002cd0 <binit+0x50>
  }
}
    80002cf6:	70a2                	ld	ra,40(sp)
    80002cf8:	7402                	ld	s0,32(sp)
    80002cfa:	64e2                	ld	s1,24(sp)
    80002cfc:	6942                	ld	s2,16(sp)
    80002cfe:	69a2                	ld	s3,8(sp)
    80002d00:	6a02                	ld	s4,0(sp)
    80002d02:	6145                	addi	sp,sp,48
    80002d04:	8082                	ret

0000000080002d06 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002d06:	7179                	addi	sp,sp,-48
    80002d08:	f406                	sd	ra,40(sp)
    80002d0a:	f022                	sd	s0,32(sp)
    80002d0c:	ec26                	sd	s1,24(sp)
    80002d0e:	e84a                	sd	s2,16(sp)
    80002d10:	e44e                	sd	s3,8(sp)
    80002d12:	1800                	addi	s0,sp,48
    80002d14:	892a                	mv	s2,a0
    80002d16:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002d18:	00233517          	auipc	a0,0x233
    80002d1c:	ef850513          	addi	a0,a0,-264 # 80235c10 <bcache>
    80002d20:	f49fd0ef          	jal	ra,80000c68 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002d24:	0023b497          	auipc	s1,0x23b
    80002d28:	1a44b483          	ld	s1,420(s1) # 8023dec8 <bcache+0x82b8>
    80002d2c:	0023b797          	auipc	a5,0x23b
    80002d30:	14c78793          	addi	a5,a5,332 # 8023de78 <bcache+0x8268>
    80002d34:	02f48b63          	beq	s1,a5,80002d6a <bread+0x64>
    80002d38:	873e                	mv	a4,a5
    80002d3a:	a021                	j	80002d42 <bread+0x3c>
    80002d3c:	68a4                	ld	s1,80(s1)
    80002d3e:	02e48663          	beq	s1,a4,80002d6a <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002d42:	449c                	lw	a5,8(s1)
    80002d44:	ff279ce3          	bne	a5,s2,80002d3c <bread+0x36>
    80002d48:	44dc                	lw	a5,12(s1)
    80002d4a:	ff3799e3          	bne	a5,s3,80002d3c <bread+0x36>
      b->refcnt++;
    80002d4e:	40bc                	lw	a5,64(s1)
    80002d50:	2785                	addiw	a5,a5,1
    80002d52:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002d54:	00233517          	auipc	a0,0x233
    80002d58:	ebc50513          	addi	a0,a0,-324 # 80235c10 <bcache>
    80002d5c:	fa5fd0ef          	jal	ra,80000d00 <release>
      acquiresleep(&b->lock);
    80002d60:	01048513          	addi	a0,s1,16
    80002d64:	2b0010ef          	jal	ra,80004014 <acquiresleep>
      return b;
    80002d68:	a889                	j	80002dba <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d6a:	0023b497          	auipc	s1,0x23b
    80002d6e:	1564b483          	ld	s1,342(s1) # 8023dec0 <bcache+0x82b0>
    80002d72:	0023b797          	auipc	a5,0x23b
    80002d76:	10678793          	addi	a5,a5,262 # 8023de78 <bcache+0x8268>
    80002d7a:	00f48863          	beq	s1,a5,80002d8a <bread+0x84>
    80002d7e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002d80:	40bc                	lw	a5,64(s1)
    80002d82:	cb91                	beqz	a5,80002d96 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d84:	64a4                	ld	s1,72(s1)
    80002d86:	fee49de3          	bne	s1,a4,80002d80 <bread+0x7a>
  panic("bget: no buffers");
    80002d8a:	00004517          	auipc	a0,0x4
    80002d8e:	78650513          	addi	a0,a0,1926 # 80007510 <syscalls+0xc0>
    80002d92:	9d9fd0ef          	jal	ra,8000076a <panic>
      b->dev = dev;
    80002d96:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002d9a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002d9e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002da2:	4785                	li	a5,1
    80002da4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002da6:	00233517          	auipc	a0,0x233
    80002daa:	e6a50513          	addi	a0,a0,-406 # 80235c10 <bcache>
    80002dae:	f53fd0ef          	jal	ra,80000d00 <release>
      acquiresleep(&b->lock);
    80002db2:	01048513          	addi	a0,s1,16
    80002db6:	25e010ef          	jal	ra,80004014 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002dba:	409c                	lw	a5,0(s1)
    80002dbc:	cb89                	beqz	a5,80002dce <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	70a2                	ld	ra,40(sp)
    80002dc2:	7402                	ld	s0,32(sp)
    80002dc4:	64e2                	ld	s1,24(sp)
    80002dc6:	6942                	ld	s2,16(sp)
    80002dc8:	69a2                	ld	s3,8(sp)
    80002dca:	6145                	addi	sp,sp,48
    80002dcc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002dce:	4581                	li	a1,0
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	1bb020ef          	jal	ra,8000578c <virtio_disk_rw>
    b->valid = 1;
    80002dd6:	4785                	li	a5,1
    80002dd8:	c09c                	sw	a5,0(s1)
  return b;
    80002dda:	b7d5                	j	80002dbe <bread+0xb8>

0000000080002ddc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	e426                	sd	s1,8(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002de8:	0541                	addi	a0,a0,16
    80002dea:	2a8010ef          	jal	ra,80004092 <holdingsleep>
    80002dee:	c911                	beqz	a0,80002e02 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002df0:	4585                	li	a1,1
    80002df2:	8526                	mv	a0,s1
    80002df4:	199020ef          	jal	ra,8000578c <virtio_disk_rw>
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret
    panic("bwrite");
    80002e02:	00004517          	auipc	a0,0x4
    80002e06:	72650513          	addi	a0,a0,1830 # 80007528 <syscalls+0xd8>
    80002e0a:	961fd0ef          	jal	ra,8000076a <panic>

0000000080002e0e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	e426                	sd	s1,8(sp)
    80002e16:	e04a                	sd	s2,0(sp)
    80002e18:	1000                	addi	s0,sp,32
    80002e1a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e1c:	01050913          	addi	s2,a0,16
    80002e20:	854a                	mv	a0,s2
    80002e22:	270010ef          	jal	ra,80004092 <holdingsleep>
    80002e26:	c13d                	beqz	a0,80002e8c <brelse+0x7e>
    panic("brelse");

  releasesleep(&b->lock);
    80002e28:	854a                	mv	a0,s2
    80002e2a:	230010ef          	jal	ra,8000405a <releasesleep>

  acquire(&bcache.lock);
    80002e2e:	00233517          	auipc	a0,0x233
    80002e32:	de250513          	addi	a0,a0,-542 # 80235c10 <bcache>
    80002e36:	e33fd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt--;
    80002e3a:	40bc                	lw	a5,64(s1)
    80002e3c:	37fd                	addiw	a5,a5,-1
    80002e3e:	0007871b          	sext.w	a4,a5
    80002e42:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002e44:	eb05                	bnez	a4,80002e74 <brelse+0x66>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002e46:	68bc                	ld	a5,80(s1)
    80002e48:	64b8                	ld	a4,72(s1)
    80002e4a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002e4c:	64bc                	ld	a5,72(s1)
    80002e4e:	68b8                	ld	a4,80(s1)
    80002e50:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002e52:	0023b797          	auipc	a5,0x23b
    80002e56:	dbe78793          	addi	a5,a5,-578 # 8023dc10 <bcache+0x8000>
    80002e5a:	2b87b703          	ld	a4,696(a5)
    80002e5e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002e60:	0023b717          	auipc	a4,0x23b
    80002e64:	01870713          	addi	a4,a4,24 # 8023de78 <bcache+0x8268>
    80002e68:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002e6a:	2b87b703          	ld	a4,696(a5)
    80002e6e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002e70:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002e74:	00233517          	auipc	a0,0x233
    80002e78:	d9c50513          	addi	a0,a0,-612 # 80235c10 <bcache>
    80002e7c:	e85fd0ef          	jal	ra,80000d00 <release>
}
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6902                	ld	s2,0(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret
    panic("brelse");
    80002e8c:	00004517          	auipc	a0,0x4
    80002e90:	6a450513          	addi	a0,a0,1700 # 80007530 <syscalls+0xe0>
    80002e94:	8d7fd0ef          	jal	ra,8000076a <panic>

0000000080002e98 <bpin>:

void
bpin(struct buf *b) {
    80002e98:	1101                	addi	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	e426                	sd	s1,8(sp)
    80002ea0:	1000                	addi	s0,sp,32
    80002ea2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ea4:	00233517          	auipc	a0,0x233
    80002ea8:	d6c50513          	addi	a0,a0,-660 # 80235c10 <bcache>
    80002eac:	dbdfd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt++;
    80002eb0:	40bc                	lw	a5,64(s1)
    80002eb2:	2785                	addiw	a5,a5,1
    80002eb4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002eb6:	00233517          	auipc	a0,0x233
    80002eba:	d5a50513          	addi	a0,a0,-678 # 80235c10 <bcache>
    80002ebe:	e43fd0ef          	jal	ra,80000d00 <release>
}
    80002ec2:	60e2                	ld	ra,24(sp)
    80002ec4:	6442                	ld	s0,16(sp)
    80002ec6:	64a2                	ld	s1,8(sp)
    80002ec8:	6105                	addi	sp,sp,32
    80002eca:	8082                	ret

0000000080002ecc <bunpin>:

void
bunpin(struct buf *b) {
    80002ecc:	1101                	addi	sp,sp,-32
    80002ece:	ec06                	sd	ra,24(sp)
    80002ed0:	e822                	sd	s0,16(sp)
    80002ed2:	e426                	sd	s1,8(sp)
    80002ed4:	1000                	addi	s0,sp,32
    80002ed6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ed8:	00233517          	auipc	a0,0x233
    80002edc:	d3850513          	addi	a0,a0,-712 # 80235c10 <bcache>
    80002ee0:	d89fd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt--;
    80002ee4:	40bc                	lw	a5,64(s1)
    80002ee6:	37fd                	addiw	a5,a5,-1
    80002ee8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002eea:	00233517          	auipc	a0,0x233
    80002eee:	d2650513          	addi	a0,a0,-730 # 80235c10 <bcache>
    80002ef2:	e0ffd0ef          	jal	ra,80000d00 <release>
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6105                	addi	sp,sp,32
    80002efe:	8082                	ret

0000000080002f00 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	e426                	sd	s1,8(sp)
    80002f08:	e04a                	sd	s2,0(sp)
    80002f0a:	1000                	addi	s0,sp,32
    80002f0c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002f0e:	00d5d59b          	srliw	a1,a1,0xd
    80002f12:	0023b797          	auipc	a5,0x23b
    80002f16:	3da7a783          	lw	a5,986(a5) # 8023e2ec <sb+0x1c>
    80002f1a:	9dbd                	addw	a1,a1,a5
    80002f1c:	debff0ef          	jal	ra,80002d06 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002f20:	0074f713          	andi	a4,s1,7
    80002f24:	4785                	li	a5,1
    80002f26:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002f2a:	14ce                	slli	s1,s1,0x33
    80002f2c:	90d9                	srli	s1,s1,0x36
    80002f2e:	00950733          	add	a4,a0,s1
    80002f32:	05874703          	lbu	a4,88(a4)
    80002f36:	00e7f6b3          	and	a3,a5,a4
    80002f3a:	c29d                	beqz	a3,80002f60 <bfree+0x60>
    80002f3c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002f3e:	94aa                	add	s1,s1,a0
    80002f40:	fff7c793          	not	a5,a5
    80002f44:	8ff9                	and	a5,a5,a4
    80002f46:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002f4a:	7d1000ef          	jal	ra,80003f1a <log_write>
  brelse(bp);
    80002f4e:	854a                	mv	a0,s2
    80002f50:	ebfff0ef          	jal	ra,80002e0e <brelse>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6902                	ld	s2,0(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret
    panic("freeing free block");
    80002f60:	00004517          	auipc	a0,0x4
    80002f64:	5d850513          	addi	a0,a0,1496 # 80007538 <syscalls+0xe8>
    80002f68:	803fd0ef          	jal	ra,8000076a <panic>

0000000080002f6c <balloc>:
{
    80002f6c:	711d                	addi	sp,sp,-96
    80002f6e:	ec86                	sd	ra,88(sp)
    80002f70:	e8a2                	sd	s0,80(sp)
    80002f72:	e4a6                	sd	s1,72(sp)
    80002f74:	e0ca                	sd	s2,64(sp)
    80002f76:	fc4e                	sd	s3,56(sp)
    80002f78:	f852                	sd	s4,48(sp)
    80002f7a:	f456                	sd	s5,40(sp)
    80002f7c:	f05a                	sd	s6,32(sp)
    80002f7e:	ec5e                	sd	s7,24(sp)
    80002f80:	e862                	sd	s8,16(sp)
    80002f82:	e466                	sd	s9,8(sp)
    80002f84:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002f86:	0023b797          	auipc	a5,0x23b
    80002f8a:	34e7a783          	lw	a5,846(a5) # 8023e2d4 <sb+0x4>
    80002f8e:	0e078163          	beqz	a5,80003070 <balloc+0x104>
    80002f92:	8baa                	mv	s7,a0
    80002f94:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002f96:	0023bb17          	auipc	s6,0x23b
    80002f9a:	33ab0b13          	addi	s6,s6,826 # 8023e2d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f9e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002fa0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fa2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002fa4:	6c89                	lui	s9,0x2
    80002fa6:	a0b5                	j	80003012 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002fa8:	974a                	add	a4,a4,s2
    80002faa:	8fd5                	or	a5,a5,a3
    80002fac:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002fb0:	854a                	mv	a0,s2
    80002fb2:	769000ef          	jal	ra,80003f1a <log_write>
        brelse(bp);
    80002fb6:	854a                	mv	a0,s2
    80002fb8:	e57ff0ef          	jal	ra,80002e0e <brelse>
  bp = bread(dev, bno);
    80002fbc:	85a6                	mv	a1,s1
    80002fbe:	855e                	mv	a0,s7
    80002fc0:	d47ff0ef          	jal	ra,80002d06 <bread>
    80002fc4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002fc6:	40000613          	li	a2,1024
    80002fca:	4581                	li	a1,0
    80002fcc:	05850513          	addi	a0,a0,88
    80002fd0:	d6dfd0ef          	jal	ra,80000d3c <memset>
  log_write(bp);
    80002fd4:	854a                	mv	a0,s2
    80002fd6:	745000ef          	jal	ra,80003f1a <log_write>
  brelse(bp);
    80002fda:	854a                	mv	a0,s2
    80002fdc:	e33ff0ef          	jal	ra,80002e0e <brelse>
}
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	60e6                	ld	ra,88(sp)
    80002fe4:	6446                	ld	s0,80(sp)
    80002fe6:	64a6                	ld	s1,72(sp)
    80002fe8:	6906                	ld	s2,64(sp)
    80002fea:	79e2                	ld	s3,56(sp)
    80002fec:	7a42                	ld	s4,48(sp)
    80002fee:	7aa2                	ld	s5,40(sp)
    80002ff0:	7b02                	ld	s6,32(sp)
    80002ff2:	6be2                	ld	s7,24(sp)
    80002ff4:	6c42                	ld	s8,16(sp)
    80002ff6:	6ca2                	ld	s9,8(sp)
    80002ff8:	6125                	addi	sp,sp,96
    80002ffa:	8082                	ret
    brelse(bp);
    80002ffc:	854a                	mv	a0,s2
    80002ffe:	e11ff0ef          	jal	ra,80002e0e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003002:	015c87bb          	addw	a5,s9,s5
    80003006:	00078a9b          	sext.w	s5,a5
    8000300a:	004b2703          	lw	a4,4(s6)
    8000300e:	06eaf163          	bgeu	s5,a4,80003070 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80003012:	41fad79b          	sraiw	a5,s5,0x1f
    80003016:	0137d79b          	srliw	a5,a5,0x13
    8000301a:	015787bb          	addw	a5,a5,s5
    8000301e:	40d7d79b          	sraiw	a5,a5,0xd
    80003022:	01cb2583          	lw	a1,28(s6)
    80003026:	9dbd                	addw	a1,a1,a5
    80003028:	855e                	mv	a0,s7
    8000302a:	cddff0ef          	jal	ra,80002d06 <bread>
    8000302e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003030:	004b2503          	lw	a0,4(s6)
    80003034:	000a849b          	sext.w	s1,s5
    80003038:	8662                	mv	a2,s8
    8000303a:	fca4f1e3          	bgeu	s1,a0,80002ffc <balloc+0x90>
      m = 1 << (bi % 8);
    8000303e:	41f6579b          	sraiw	a5,a2,0x1f
    80003042:	01d7d69b          	srliw	a3,a5,0x1d
    80003046:	00c6873b          	addw	a4,a3,a2
    8000304a:	00777793          	andi	a5,a4,7
    8000304e:	9f95                	subw	a5,a5,a3
    80003050:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003054:	4037571b          	sraiw	a4,a4,0x3
    80003058:	00e906b3          	add	a3,s2,a4
    8000305c:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003060:	00d7f5b3          	and	a1,a5,a3
    80003064:	d1b1                	beqz	a1,80002fa8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003066:	2605                	addiw	a2,a2,1
    80003068:	2485                	addiw	s1,s1,1
    8000306a:	fd4618e3          	bne	a2,s4,8000303a <balloc+0xce>
    8000306e:	b779                	j	80002ffc <balloc+0x90>
  printf("balloc: out of blocks\n");
    80003070:	00004517          	auipc	a0,0x4
    80003074:	4e050513          	addi	a0,a0,1248 # 80007550 <syscalls+0x100>
    80003078:	c2cfd0ef          	jal	ra,800004a4 <printf>
  return 0;
    8000307c:	4481                	li	s1,0
    8000307e:	b78d                	j	80002fe0 <balloc+0x74>

0000000080003080 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003080:	7179                	addi	sp,sp,-48
    80003082:	f406                	sd	ra,40(sp)
    80003084:	f022                	sd	s0,32(sp)
    80003086:	ec26                	sd	s1,24(sp)
    80003088:	e84a                	sd	s2,16(sp)
    8000308a:	e44e                	sd	s3,8(sp)
    8000308c:	e052                	sd	s4,0(sp)
    8000308e:	1800                	addi	s0,sp,48
    80003090:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003092:	47ad                	li	a5,11
    80003094:	02b7e563          	bltu	a5,a1,800030be <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003098:	02059493          	slli	s1,a1,0x20
    8000309c:	9081                	srli	s1,s1,0x20
    8000309e:	048a                	slli	s1,s1,0x2
    800030a0:	94aa                	add	s1,s1,a0
    800030a2:	0504a903          	lw	s2,80(s1)
    800030a6:	06091663          	bnez	s2,80003112 <bmap+0x92>
      addr = balloc(ip->dev);
    800030aa:	4108                	lw	a0,0(a0)
    800030ac:	ec1ff0ef          	jal	ra,80002f6c <balloc>
    800030b0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800030b4:	04090f63          	beqz	s2,80003112 <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    800030b8:	0524a823          	sw	s2,80(s1)
    800030bc:	a899                	j	80003112 <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    800030be:	ff45849b          	addiw	s1,a1,-12
    800030c2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800030c6:	0ff00793          	li	a5,255
    800030ca:	06e7eb63          	bltu	a5,a4,80003140 <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800030ce:	08052903          	lw	s2,128(a0)
    800030d2:	00091b63          	bnez	s2,800030e8 <bmap+0x68>
      addr = balloc(ip->dev);
    800030d6:	4108                	lw	a0,0(a0)
    800030d8:	e95ff0ef          	jal	ra,80002f6c <balloc>
    800030dc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800030e0:	02090963          	beqz	s2,80003112 <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800030e4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800030e8:	85ca                	mv	a1,s2
    800030ea:	0009a503          	lw	a0,0(s3)
    800030ee:	c19ff0ef          	jal	ra,80002d06 <bread>
    800030f2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800030f4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800030f8:	02049593          	slli	a1,s1,0x20
    800030fc:	9181                	srli	a1,a1,0x20
    800030fe:	058a                	slli	a1,a1,0x2
    80003100:	00b784b3          	add	s1,a5,a1
    80003104:	0004a903          	lw	s2,0(s1)
    80003108:	00090e63          	beqz	s2,80003124 <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000310c:	8552                	mv	a0,s4
    8000310e:	d01ff0ef          	jal	ra,80002e0e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003112:	854a                	mv	a0,s2
    80003114:	70a2                	ld	ra,40(sp)
    80003116:	7402                	ld	s0,32(sp)
    80003118:	64e2                	ld	s1,24(sp)
    8000311a:	6942                	ld	s2,16(sp)
    8000311c:	69a2                	ld	s3,8(sp)
    8000311e:	6a02                	ld	s4,0(sp)
    80003120:	6145                	addi	sp,sp,48
    80003122:	8082                	ret
      addr = balloc(ip->dev);
    80003124:	0009a503          	lw	a0,0(s3)
    80003128:	e45ff0ef          	jal	ra,80002f6c <balloc>
    8000312c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003130:	fc090ee3          	beqz	s2,8000310c <bmap+0x8c>
        a[bn] = addr;
    80003134:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003138:	8552                	mv	a0,s4
    8000313a:	5e1000ef          	jal	ra,80003f1a <log_write>
    8000313e:	b7f9                	j	8000310c <bmap+0x8c>
  panic("bmap: out of range");
    80003140:	00004517          	auipc	a0,0x4
    80003144:	42850513          	addi	a0,a0,1064 # 80007568 <syscalls+0x118>
    80003148:	e22fd0ef          	jal	ra,8000076a <panic>

000000008000314c <iget>:
{
    8000314c:	7179                	addi	sp,sp,-48
    8000314e:	f406                	sd	ra,40(sp)
    80003150:	f022                	sd	s0,32(sp)
    80003152:	ec26                	sd	s1,24(sp)
    80003154:	e84a                	sd	s2,16(sp)
    80003156:	e44e                	sd	s3,8(sp)
    80003158:	e052                	sd	s4,0(sp)
    8000315a:	1800                	addi	s0,sp,48
    8000315c:	89aa                	mv	s3,a0
    8000315e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003160:	0023b517          	auipc	a0,0x23b
    80003164:	19050513          	addi	a0,a0,400 # 8023e2f0 <itable>
    80003168:	b01fd0ef          	jal	ra,80000c68 <acquire>
  empty = 0;
    8000316c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000316e:	0023b497          	auipc	s1,0x23b
    80003172:	19a48493          	addi	s1,s1,410 # 8023e308 <itable+0x18>
    80003176:	0023d697          	auipc	a3,0x23d
    8000317a:	c2268693          	addi	a3,a3,-990 # 8023fd98 <log>
    8000317e:	a039                	j	8000318c <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003180:	02090963          	beqz	s2,800031b2 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003184:	08848493          	addi	s1,s1,136
    80003188:	02d48863          	beq	s1,a3,800031b8 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000318c:	449c                	lw	a5,8(s1)
    8000318e:	fef059e3          	blez	a5,80003180 <iget+0x34>
    80003192:	4098                	lw	a4,0(s1)
    80003194:	ff3716e3          	bne	a4,s3,80003180 <iget+0x34>
    80003198:	40d8                	lw	a4,4(s1)
    8000319a:	ff4713e3          	bne	a4,s4,80003180 <iget+0x34>
      ip->ref++;
    8000319e:	2785                	addiw	a5,a5,1
    800031a0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800031a2:	0023b517          	auipc	a0,0x23b
    800031a6:	14e50513          	addi	a0,a0,334 # 8023e2f0 <itable>
    800031aa:	b57fd0ef          	jal	ra,80000d00 <release>
      return ip;
    800031ae:	8926                	mv	s2,s1
    800031b0:	a02d                	j	800031da <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800031b2:	fbe9                	bnez	a5,80003184 <iget+0x38>
    800031b4:	8926                	mv	s2,s1
    800031b6:	b7f9                	j	80003184 <iget+0x38>
  if(empty == 0)
    800031b8:	02090a63          	beqz	s2,800031ec <iget+0xa0>
  ip->dev = dev;
    800031bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800031c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800031c4:	4785                	li	a5,1
    800031c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800031ca:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800031ce:	0023b517          	auipc	a0,0x23b
    800031d2:	12250513          	addi	a0,a0,290 # 8023e2f0 <itable>
    800031d6:	b2bfd0ef          	jal	ra,80000d00 <release>
}
    800031da:	854a                	mv	a0,s2
    800031dc:	70a2                	ld	ra,40(sp)
    800031de:	7402                	ld	s0,32(sp)
    800031e0:	64e2                	ld	s1,24(sp)
    800031e2:	6942                	ld	s2,16(sp)
    800031e4:	69a2                	ld	s3,8(sp)
    800031e6:	6a02                	ld	s4,0(sp)
    800031e8:	6145                	addi	sp,sp,48
    800031ea:	8082                	ret
    panic("iget: no inodes");
    800031ec:	00004517          	auipc	a0,0x4
    800031f0:	39450513          	addi	a0,a0,916 # 80007580 <syscalls+0x130>
    800031f4:	d76fd0ef          	jal	ra,8000076a <panic>

00000000800031f8 <iinit>:
{
    800031f8:	7179                	addi	sp,sp,-48
    800031fa:	f406                	sd	ra,40(sp)
    800031fc:	f022                	sd	s0,32(sp)
    800031fe:	ec26                	sd	s1,24(sp)
    80003200:	e84a                	sd	s2,16(sp)
    80003202:	e44e                	sd	s3,8(sp)
    80003204:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003206:	00004597          	auipc	a1,0x4
    8000320a:	38a58593          	addi	a1,a1,906 # 80007590 <syscalls+0x140>
    8000320e:	0023b517          	auipc	a0,0x23b
    80003212:	0e250513          	addi	a0,a0,226 # 8023e2f0 <itable>
    80003216:	9d3fd0ef          	jal	ra,80000be8 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000321a:	0023b497          	auipc	s1,0x23b
    8000321e:	0fe48493          	addi	s1,s1,254 # 8023e318 <itable+0x28>
    80003222:	0023d997          	auipc	s3,0x23d
    80003226:	b8698993          	addi	s3,s3,-1146 # 8023fda8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000322a:	00004917          	auipc	s2,0x4
    8000322e:	36e90913          	addi	s2,s2,878 # 80007598 <syscalls+0x148>
    80003232:	85ca                	mv	a1,s2
    80003234:	8526                	mv	a0,s1
    80003236:	5a9000ef          	jal	ra,80003fde <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000323a:	08848493          	addi	s1,s1,136
    8000323e:	ff349ae3          	bne	s1,s3,80003232 <iinit+0x3a>
}
    80003242:	70a2                	ld	ra,40(sp)
    80003244:	7402                	ld	s0,32(sp)
    80003246:	64e2                	ld	s1,24(sp)
    80003248:	6942                	ld	s2,16(sp)
    8000324a:	69a2                	ld	s3,8(sp)
    8000324c:	6145                	addi	sp,sp,48
    8000324e:	8082                	ret

0000000080003250 <ialloc>:
{
    80003250:	715d                	addi	sp,sp,-80
    80003252:	e486                	sd	ra,72(sp)
    80003254:	e0a2                	sd	s0,64(sp)
    80003256:	fc26                	sd	s1,56(sp)
    80003258:	f84a                	sd	s2,48(sp)
    8000325a:	f44e                	sd	s3,40(sp)
    8000325c:	f052                	sd	s4,32(sp)
    8000325e:	ec56                	sd	s5,24(sp)
    80003260:	e85a                	sd	s6,16(sp)
    80003262:	e45e                	sd	s7,8(sp)
    80003264:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003266:	0023b717          	auipc	a4,0x23b
    8000326a:	07672703          	lw	a4,118(a4) # 8023e2dc <sb+0xc>
    8000326e:	4785                	li	a5,1
    80003270:	04e7f663          	bgeu	a5,a4,800032bc <ialloc+0x6c>
    80003274:	8aaa                	mv	s5,a0
    80003276:	8bae                	mv	s7,a1
    80003278:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000327a:	0023ba17          	auipc	s4,0x23b
    8000327e:	056a0a13          	addi	s4,s4,86 # 8023e2d0 <sb>
    80003282:	00048b1b          	sext.w	s6,s1
    80003286:	0044d793          	srli	a5,s1,0x4
    8000328a:	018a2583          	lw	a1,24(s4)
    8000328e:	9dbd                	addw	a1,a1,a5
    80003290:	8556                	mv	a0,s5
    80003292:	a75ff0ef          	jal	ra,80002d06 <bread>
    80003296:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003298:	05850993          	addi	s3,a0,88
    8000329c:	00f4f793          	andi	a5,s1,15
    800032a0:	079a                	slli	a5,a5,0x6
    800032a2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800032a4:	00099783          	lh	a5,0(s3)
    800032a8:	cf85                	beqz	a5,800032e0 <ialloc+0x90>
    brelse(bp);
    800032aa:	b65ff0ef          	jal	ra,80002e0e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800032ae:	0485                	addi	s1,s1,1
    800032b0:	00ca2703          	lw	a4,12(s4)
    800032b4:	0004879b          	sext.w	a5,s1
    800032b8:	fce7e5e3          	bltu	a5,a4,80003282 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800032bc:	00004517          	auipc	a0,0x4
    800032c0:	2e450513          	addi	a0,a0,740 # 800075a0 <syscalls+0x150>
    800032c4:	9e0fd0ef          	jal	ra,800004a4 <printf>
  return 0;
    800032c8:	4501                	li	a0,0
}
    800032ca:	60a6                	ld	ra,72(sp)
    800032cc:	6406                	ld	s0,64(sp)
    800032ce:	74e2                	ld	s1,56(sp)
    800032d0:	7942                	ld	s2,48(sp)
    800032d2:	79a2                	ld	s3,40(sp)
    800032d4:	7a02                	ld	s4,32(sp)
    800032d6:	6ae2                	ld	s5,24(sp)
    800032d8:	6b42                	ld	s6,16(sp)
    800032da:	6ba2                	ld	s7,8(sp)
    800032dc:	6161                	addi	sp,sp,80
    800032de:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800032e0:	04000613          	li	a2,64
    800032e4:	4581                	li	a1,0
    800032e6:	854e                	mv	a0,s3
    800032e8:	a55fd0ef          	jal	ra,80000d3c <memset>
      dip->type = type;
    800032ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800032f0:	854a                	mv	a0,s2
    800032f2:	429000ef          	jal	ra,80003f1a <log_write>
      brelse(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	b17ff0ef          	jal	ra,80002e0e <brelse>
      return iget(dev, inum);
    800032fc:	85da                	mv	a1,s6
    800032fe:	8556                	mv	a0,s5
    80003300:	e4dff0ef          	jal	ra,8000314c <iget>
    80003304:	b7d9                	j	800032ca <ialloc+0x7a>

0000000080003306 <iupdate>:
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	e04a                	sd	s2,0(sp)
    80003310:	1000                	addi	s0,sp,32
    80003312:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003314:	415c                	lw	a5,4(a0)
    80003316:	0047d79b          	srliw	a5,a5,0x4
    8000331a:	0023b597          	auipc	a1,0x23b
    8000331e:	fce5a583          	lw	a1,-50(a1) # 8023e2e8 <sb+0x18>
    80003322:	9dbd                	addw	a1,a1,a5
    80003324:	4108                	lw	a0,0(a0)
    80003326:	9e1ff0ef          	jal	ra,80002d06 <bread>
    8000332a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000332c:	05850793          	addi	a5,a0,88
    80003330:	40c8                	lw	a0,4(s1)
    80003332:	893d                	andi	a0,a0,15
    80003334:	051a                	slli	a0,a0,0x6
    80003336:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003338:	04449703          	lh	a4,68(s1)
    8000333c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003340:	04649703          	lh	a4,70(s1)
    80003344:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003348:	04849703          	lh	a4,72(s1)
    8000334c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003350:	04a49703          	lh	a4,74(s1)
    80003354:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003358:	44f8                	lw	a4,76(s1)
    8000335a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000335c:	03400613          	li	a2,52
    80003360:	05048593          	addi	a1,s1,80
    80003364:	0531                	addi	a0,a0,12
    80003366:	a33fd0ef          	jal	ra,80000d98 <memmove>
  log_write(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	3af000ef          	jal	ra,80003f1a <log_write>
  brelse(bp);
    80003370:	854a                	mv	a0,s2
    80003372:	a9dff0ef          	jal	ra,80002e0e <brelse>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6902                	ld	s2,0(sp)
    8000337e:	6105                	addi	sp,sp,32
    80003380:	8082                	ret

0000000080003382 <idup>:
{
    80003382:	1101                	addi	sp,sp,-32
    80003384:	ec06                	sd	ra,24(sp)
    80003386:	e822                	sd	s0,16(sp)
    80003388:	e426                	sd	s1,8(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000338e:	0023b517          	auipc	a0,0x23b
    80003392:	f6250513          	addi	a0,a0,-158 # 8023e2f0 <itable>
    80003396:	8d3fd0ef          	jal	ra,80000c68 <acquire>
  ip->ref++;
    8000339a:	449c                	lw	a5,8(s1)
    8000339c:	2785                	addiw	a5,a5,1
    8000339e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033a0:	0023b517          	auipc	a0,0x23b
    800033a4:	f5050513          	addi	a0,a0,-176 # 8023e2f0 <itable>
    800033a8:	959fd0ef          	jal	ra,80000d00 <release>
}
    800033ac:	8526                	mv	a0,s1
    800033ae:	60e2                	ld	ra,24(sp)
    800033b0:	6442                	ld	s0,16(sp)
    800033b2:	64a2                	ld	s1,8(sp)
    800033b4:	6105                	addi	sp,sp,32
    800033b6:	8082                	ret

00000000800033b8 <ilock>:
{
    800033b8:	1101                	addi	sp,sp,-32
    800033ba:	ec06                	sd	ra,24(sp)
    800033bc:	e822                	sd	s0,16(sp)
    800033be:	e426                	sd	s1,8(sp)
    800033c0:	e04a                	sd	s2,0(sp)
    800033c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800033c4:	c105                	beqz	a0,800033e4 <ilock+0x2c>
    800033c6:	84aa                	mv	s1,a0
    800033c8:	451c                	lw	a5,8(a0)
    800033ca:	00f05d63          	blez	a5,800033e4 <ilock+0x2c>
  acquiresleep(&ip->lock);
    800033ce:	0541                	addi	a0,a0,16
    800033d0:	445000ef          	jal	ra,80004014 <acquiresleep>
  if(ip->valid == 0){
    800033d4:	40bc                	lw	a5,64(s1)
    800033d6:	cf89                	beqz	a5,800033f0 <ilock+0x38>
}
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6902                	ld	s2,0(sp)
    800033e0:	6105                	addi	sp,sp,32
    800033e2:	8082                	ret
    panic("ilock");
    800033e4:	00004517          	auipc	a0,0x4
    800033e8:	1d450513          	addi	a0,a0,468 # 800075b8 <syscalls+0x168>
    800033ec:	b7efd0ef          	jal	ra,8000076a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800033f0:	40dc                	lw	a5,4(s1)
    800033f2:	0047d79b          	srliw	a5,a5,0x4
    800033f6:	0023b597          	auipc	a1,0x23b
    800033fa:	ef25a583          	lw	a1,-270(a1) # 8023e2e8 <sb+0x18>
    800033fe:	9dbd                	addw	a1,a1,a5
    80003400:	4088                	lw	a0,0(s1)
    80003402:	905ff0ef          	jal	ra,80002d06 <bread>
    80003406:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003408:	05850593          	addi	a1,a0,88
    8000340c:	40dc                	lw	a5,4(s1)
    8000340e:	8bbd                	andi	a5,a5,15
    80003410:	079a                	slli	a5,a5,0x6
    80003412:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003414:	00059783          	lh	a5,0(a1)
    80003418:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000341c:	00259783          	lh	a5,2(a1)
    80003420:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003424:	00459783          	lh	a5,4(a1)
    80003428:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000342c:	00659783          	lh	a5,6(a1)
    80003430:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003434:	459c                	lw	a5,8(a1)
    80003436:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003438:	03400613          	li	a2,52
    8000343c:	05b1                	addi	a1,a1,12
    8000343e:	05048513          	addi	a0,s1,80
    80003442:	957fd0ef          	jal	ra,80000d98 <memmove>
    brelse(bp);
    80003446:	854a                	mv	a0,s2
    80003448:	9c7ff0ef          	jal	ra,80002e0e <brelse>
    ip->valid = 1;
    8000344c:	4785                	li	a5,1
    8000344e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003450:	04449783          	lh	a5,68(s1)
    80003454:	f3d1                	bnez	a5,800033d8 <ilock+0x20>
      panic("ilock: no type");
    80003456:	00004517          	auipc	a0,0x4
    8000345a:	16a50513          	addi	a0,a0,362 # 800075c0 <syscalls+0x170>
    8000345e:	b0cfd0ef          	jal	ra,8000076a <panic>

0000000080003462 <iunlock>:
{
    80003462:	1101                	addi	sp,sp,-32
    80003464:	ec06                	sd	ra,24(sp)
    80003466:	e822                	sd	s0,16(sp)
    80003468:	e426                	sd	s1,8(sp)
    8000346a:	e04a                	sd	s2,0(sp)
    8000346c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000346e:	c505                	beqz	a0,80003496 <iunlock+0x34>
    80003470:	84aa                	mv	s1,a0
    80003472:	01050913          	addi	s2,a0,16
    80003476:	854a                	mv	a0,s2
    80003478:	41b000ef          	jal	ra,80004092 <holdingsleep>
    8000347c:	cd09                	beqz	a0,80003496 <iunlock+0x34>
    8000347e:	449c                	lw	a5,8(s1)
    80003480:	00f05b63          	blez	a5,80003496 <iunlock+0x34>
  releasesleep(&ip->lock);
    80003484:	854a                	mv	a0,s2
    80003486:	3d5000ef          	jal	ra,8000405a <releasesleep>
}
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	64a2                	ld	s1,8(sp)
    80003490:	6902                	ld	s2,0(sp)
    80003492:	6105                	addi	sp,sp,32
    80003494:	8082                	ret
    panic("iunlock");
    80003496:	00004517          	auipc	a0,0x4
    8000349a:	13a50513          	addi	a0,a0,314 # 800075d0 <syscalls+0x180>
    8000349e:	accfd0ef          	jal	ra,8000076a <panic>

00000000800034a2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800034a2:	7179                	addi	sp,sp,-48
    800034a4:	f406                	sd	ra,40(sp)
    800034a6:	f022                	sd	s0,32(sp)
    800034a8:	ec26                	sd	s1,24(sp)
    800034aa:	e84a                	sd	s2,16(sp)
    800034ac:	e44e                	sd	s3,8(sp)
    800034ae:	e052                	sd	s4,0(sp)
    800034b0:	1800                	addi	s0,sp,48
    800034b2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800034b4:	05050493          	addi	s1,a0,80
    800034b8:	08050913          	addi	s2,a0,128
    800034bc:	a021                	j	800034c4 <itrunc+0x22>
    800034be:	0491                	addi	s1,s1,4
    800034c0:	01248b63          	beq	s1,s2,800034d6 <itrunc+0x34>
    if(ip->addrs[i]){
    800034c4:	408c                	lw	a1,0(s1)
    800034c6:	dde5                	beqz	a1,800034be <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800034c8:	0009a503          	lw	a0,0(s3)
    800034cc:	a35ff0ef          	jal	ra,80002f00 <bfree>
      ip->addrs[i] = 0;
    800034d0:	0004a023          	sw	zero,0(s1)
    800034d4:	b7ed                	j	800034be <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800034d6:	0809a583          	lw	a1,128(s3)
    800034da:	ed91                	bnez	a1,800034f6 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800034dc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800034e0:	854e                	mv	a0,s3
    800034e2:	e25ff0ef          	jal	ra,80003306 <iupdate>
}
    800034e6:	70a2                	ld	ra,40(sp)
    800034e8:	7402                	ld	s0,32(sp)
    800034ea:	64e2                	ld	s1,24(sp)
    800034ec:	6942                	ld	s2,16(sp)
    800034ee:	69a2                	ld	s3,8(sp)
    800034f0:	6a02                	ld	s4,0(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800034f6:	0009a503          	lw	a0,0(s3)
    800034fa:	80dff0ef          	jal	ra,80002d06 <bread>
    800034fe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003500:	05850493          	addi	s1,a0,88
    80003504:	45850913          	addi	s2,a0,1112
    80003508:	a021                	j	80003510 <itrunc+0x6e>
    8000350a:	0491                	addi	s1,s1,4
    8000350c:	01248963          	beq	s1,s2,8000351e <itrunc+0x7c>
      if(a[j])
    80003510:	408c                	lw	a1,0(s1)
    80003512:	dde5                	beqz	a1,8000350a <itrunc+0x68>
        bfree(ip->dev, a[j]);
    80003514:	0009a503          	lw	a0,0(s3)
    80003518:	9e9ff0ef          	jal	ra,80002f00 <bfree>
    8000351c:	b7fd                	j	8000350a <itrunc+0x68>
    brelse(bp);
    8000351e:	8552                	mv	a0,s4
    80003520:	8efff0ef          	jal	ra,80002e0e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003524:	0809a583          	lw	a1,128(s3)
    80003528:	0009a503          	lw	a0,0(s3)
    8000352c:	9d5ff0ef          	jal	ra,80002f00 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003530:	0809a023          	sw	zero,128(s3)
    80003534:	b765                	j	800034dc <itrunc+0x3a>

0000000080003536 <iput>:
{
    80003536:	1101                	addi	sp,sp,-32
    80003538:	ec06                	sd	ra,24(sp)
    8000353a:	e822                	sd	s0,16(sp)
    8000353c:	e426                	sd	s1,8(sp)
    8000353e:	e04a                	sd	s2,0(sp)
    80003540:	1000                	addi	s0,sp,32
    80003542:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003544:	0023b517          	auipc	a0,0x23b
    80003548:	dac50513          	addi	a0,a0,-596 # 8023e2f0 <itable>
    8000354c:	f1cfd0ef          	jal	ra,80000c68 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003550:	4498                	lw	a4,8(s1)
    80003552:	4785                	li	a5,1
    80003554:	02f70163          	beq	a4,a5,80003576 <iput+0x40>
  ip->ref--;
    80003558:	449c                	lw	a5,8(s1)
    8000355a:	37fd                	addiw	a5,a5,-1
    8000355c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000355e:	0023b517          	auipc	a0,0x23b
    80003562:	d9250513          	addi	a0,a0,-622 # 8023e2f0 <itable>
    80003566:	f9afd0ef          	jal	ra,80000d00 <release>
}
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	64a2                	ld	s1,8(sp)
    80003570:	6902                	ld	s2,0(sp)
    80003572:	6105                	addi	sp,sp,32
    80003574:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003576:	40bc                	lw	a5,64(s1)
    80003578:	d3e5                	beqz	a5,80003558 <iput+0x22>
    8000357a:	04a49783          	lh	a5,74(s1)
    8000357e:	ffe9                	bnez	a5,80003558 <iput+0x22>
    acquiresleep(&ip->lock);
    80003580:	01048913          	addi	s2,s1,16
    80003584:	854a                	mv	a0,s2
    80003586:	28f000ef          	jal	ra,80004014 <acquiresleep>
    release(&itable.lock);
    8000358a:	0023b517          	auipc	a0,0x23b
    8000358e:	d6650513          	addi	a0,a0,-666 # 8023e2f0 <itable>
    80003592:	f6efd0ef          	jal	ra,80000d00 <release>
    itrunc(ip);
    80003596:	8526                	mv	a0,s1
    80003598:	f0bff0ef          	jal	ra,800034a2 <itrunc>
    ip->type = 0;
    8000359c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800035a0:	8526                	mv	a0,s1
    800035a2:	d65ff0ef          	jal	ra,80003306 <iupdate>
    ip->valid = 0;
    800035a6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800035aa:	854a                	mv	a0,s2
    800035ac:	2af000ef          	jal	ra,8000405a <releasesleep>
    acquire(&itable.lock);
    800035b0:	0023b517          	auipc	a0,0x23b
    800035b4:	d4050513          	addi	a0,a0,-704 # 8023e2f0 <itable>
    800035b8:	eb0fd0ef          	jal	ra,80000c68 <acquire>
    800035bc:	bf71                	j	80003558 <iput+0x22>

00000000800035be <iunlockput>:
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	1000                	addi	s0,sp,32
    800035c8:	84aa                	mv	s1,a0
  iunlock(ip);
    800035ca:	e99ff0ef          	jal	ra,80003462 <iunlock>
  iput(ip);
    800035ce:	8526                	mv	a0,s1
    800035d0:	f67ff0ef          	jal	ra,80003536 <iput>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800035de:	0023b717          	auipc	a4,0x23b
    800035e2:	cfe72703          	lw	a4,-770(a4) # 8023e2dc <sb+0xc>
    800035e6:	4785                	li	a5,1
    800035e8:	0ae7ff63          	bgeu	a5,a4,800036a6 <ireclaim+0xc8>
{
    800035ec:	7139                	addi	sp,sp,-64
    800035ee:	fc06                	sd	ra,56(sp)
    800035f0:	f822                	sd	s0,48(sp)
    800035f2:	f426                	sd	s1,40(sp)
    800035f4:	f04a                	sd	s2,32(sp)
    800035f6:	ec4e                	sd	s3,24(sp)
    800035f8:	e852                	sd	s4,16(sp)
    800035fa:	e456                	sd	s5,8(sp)
    800035fc:	e05a                	sd	s6,0(sp)
    800035fe:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003600:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003602:	00050a1b          	sext.w	s4,a0
    80003606:	0023ba97          	auipc	s5,0x23b
    8000360a:	ccaa8a93          	addi	s5,s5,-822 # 8023e2d0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    8000360e:	00004b17          	auipc	s6,0x4
    80003612:	fcab0b13          	addi	s6,s6,-54 # 800075d8 <syscalls+0x188>
    80003616:	a099                	j	8000365c <ireclaim+0x7e>
    80003618:	85ce                	mv	a1,s3
    8000361a:	855a                	mv	a0,s6
    8000361c:	e89fc0ef          	jal	ra,800004a4 <printf>
      ip = iget(dev, inum);
    80003620:	85ce                	mv	a1,s3
    80003622:	8552                	mv	a0,s4
    80003624:	b29ff0ef          	jal	ra,8000314c <iget>
    80003628:	89aa                	mv	s3,a0
    brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	fe2ff0ef          	jal	ra,80002e0e <brelse>
    if (ip) {
    80003630:	00098f63          	beqz	s3,8000364e <ireclaim+0x70>
      begin_op();
    80003634:	762000ef          	jal	ra,80003d96 <begin_op>
      ilock(ip);
    80003638:	854e                	mv	a0,s3
    8000363a:	d7fff0ef          	jal	ra,800033b8 <ilock>
      iunlock(ip);
    8000363e:	854e                	mv	a0,s3
    80003640:	e23ff0ef          	jal	ra,80003462 <iunlock>
      iput(ip);
    80003644:	854e                	mv	a0,s3
    80003646:	ef1ff0ef          	jal	ra,80003536 <iput>
      end_op();
    8000364a:	7bc000ef          	jal	ra,80003e06 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000364e:	0485                	addi	s1,s1,1
    80003650:	00caa703          	lw	a4,12(s5)
    80003654:	0004879b          	sext.w	a5,s1
    80003658:	02e7fd63          	bgeu	a5,a4,80003692 <ireclaim+0xb4>
    8000365c:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003660:	0044d793          	srli	a5,s1,0x4
    80003664:	018aa583          	lw	a1,24(s5)
    80003668:	9dbd                	addw	a1,a1,a5
    8000366a:	8552                	mv	a0,s4
    8000366c:	e9aff0ef          	jal	ra,80002d06 <bread>
    80003670:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003672:	05850793          	addi	a5,a0,88
    80003676:	00f9f713          	andi	a4,s3,15
    8000367a:	071a                	slli	a4,a4,0x6
    8000367c:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    8000367e:	00079703          	lh	a4,0(a5)
    80003682:	c701                	beqz	a4,8000368a <ireclaim+0xac>
    80003684:	00679783          	lh	a5,6(a5)
    80003688:	dbc1                	beqz	a5,80003618 <ireclaim+0x3a>
    brelse(bp);
    8000368a:	854a                	mv	a0,s2
    8000368c:	f82ff0ef          	jal	ra,80002e0e <brelse>
    if (ip) {
    80003690:	bf7d                	j	8000364e <ireclaim+0x70>
}
    80003692:	70e2                	ld	ra,56(sp)
    80003694:	7442                	ld	s0,48(sp)
    80003696:	74a2                	ld	s1,40(sp)
    80003698:	7902                	ld	s2,32(sp)
    8000369a:	69e2                	ld	s3,24(sp)
    8000369c:	6a42                	ld	s4,16(sp)
    8000369e:	6aa2                	ld	s5,8(sp)
    800036a0:	6b02                	ld	s6,0(sp)
    800036a2:	6121                	addi	sp,sp,64
    800036a4:	8082                	ret
    800036a6:	8082                	ret

00000000800036a8 <fsinit>:
fsinit(int dev) {
    800036a8:	7179                	addi	sp,sp,-48
    800036aa:	f406                	sd	ra,40(sp)
    800036ac:	f022                	sd	s0,32(sp)
    800036ae:	ec26                	sd	s1,24(sp)
    800036b0:	e84a                	sd	s2,16(sp)
    800036b2:	e44e                	sd	s3,8(sp)
    800036b4:	1800                	addi	s0,sp,48
    800036b6:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800036b8:	4585                	li	a1,1
    800036ba:	e4cff0ef          	jal	ra,80002d06 <bread>
    800036be:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036c0:	0023b997          	auipc	s3,0x23b
    800036c4:	c1098993          	addi	s3,s3,-1008 # 8023e2d0 <sb>
    800036c8:	02000613          	li	a2,32
    800036cc:	05850593          	addi	a1,a0,88
    800036d0:	854e                	mv	a0,s3
    800036d2:	ec6fd0ef          	jal	ra,80000d98 <memmove>
  brelse(bp);
    800036d6:	854a                	mv	a0,s2
    800036d8:	f36ff0ef          	jal	ra,80002e0e <brelse>
  if(sb.magic != FSMAGIC)
    800036dc:	0009a703          	lw	a4,0(s3)
    800036e0:	102037b7          	lui	a5,0x10203
    800036e4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036e8:	02f71363          	bne	a4,a5,8000370e <fsinit+0x66>
  initlog(dev, &sb);
    800036ec:	0023b597          	auipc	a1,0x23b
    800036f0:	be458593          	addi	a1,a1,-1052 # 8023e2d0 <sb>
    800036f4:	8526                	mv	a0,s1
    800036f6:	616000ef          	jal	ra,80003d0c <initlog>
  ireclaim(dev);
    800036fa:	8526                	mv	a0,s1
    800036fc:	ee3ff0ef          	jal	ra,800035de <ireclaim>
}
    80003700:	70a2                	ld	ra,40(sp)
    80003702:	7402                	ld	s0,32(sp)
    80003704:	64e2                	ld	s1,24(sp)
    80003706:	6942                	ld	s2,16(sp)
    80003708:	69a2                	ld	s3,8(sp)
    8000370a:	6145                	addi	sp,sp,48
    8000370c:	8082                	ret
    panic("invalid file system");
    8000370e:	00004517          	auipc	a0,0x4
    80003712:	eea50513          	addi	a0,a0,-278 # 800075f8 <syscalls+0x1a8>
    80003716:	854fd0ef          	jal	ra,8000076a <panic>

000000008000371a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000371a:	1141                	addi	sp,sp,-16
    8000371c:	e422                	sd	s0,8(sp)
    8000371e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003720:	411c                	lw	a5,0(a0)
    80003722:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003724:	415c                	lw	a5,4(a0)
    80003726:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003728:	04451783          	lh	a5,68(a0)
    8000372c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003730:	04a51783          	lh	a5,74(a0)
    80003734:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003738:	04c56783          	lwu	a5,76(a0)
    8000373c:	e99c                	sd	a5,16(a1)
}
    8000373e:	6422                	ld	s0,8(sp)
    80003740:	0141                	addi	sp,sp,16
    80003742:	8082                	ret

0000000080003744 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003744:	457c                	lw	a5,76(a0)
    80003746:	0cd7ef63          	bltu	a5,a3,80003824 <readi+0xe0>
{
    8000374a:	7159                	addi	sp,sp,-112
    8000374c:	f486                	sd	ra,104(sp)
    8000374e:	f0a2                	sd	s0,96(sp)
    80003750:	eca6                	sd	s1,88(sp)
    80003752:	e8ca                	sd	s2,80(sp)
    80003754:	e4ce                	sd	s3,72(sp)
    80003756:	e0d2                	sd	s4,64(sp)
    80003758:	fc56                	sd	s5,56(sp)
    8000375a:	f85a                	sd	s6,48(sp)
    8000375c:	f45e                	sd	s7,40(sp)
    8000375e:	f062                	sd	s8,32(sp)
    80003760:	ec66                	sd	s9,24(sp)
    80003762:	e86a                	sd	s10,16(sp)
    80003764:	e46e                	sd	s11,8(sp)
    80003766:	1880                	addi	s0,sp,112
    80003768:	8b2a                	mv	s6,a0
    8000376a:	8bae                	mv	s7,a1
    8000376c:	8a32                	mv	s4,a2
    8000376e:	84b6                	mv	s1,a3
    80003770:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003772:	9f35                	addw	a4,a4,a3
    return 0;
    80003774:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003776:	08d76663          	bltu	a4,a3,80003802 <readi+0xbe>
  if(off + n > ip->size)
    8000377a:	00e7f463          	bgeu	a5,a4,80003782 <readi+0x3e>
    n = ip->size - off;
    8000377e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003782:	080a8f63          	beqz	s5,80003820 <readi+0xdc>
    80003786:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003788:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000378c:	5c7d                	li	s8,-1
    8000378e:	a80d                	j	800037c0 <readi+0x7c>
    80003790:	020d1d93          	slli	s11,s10,0x20
    80003794:	020ddd93          	srli	s11,s11,0x20
    80003798:	05890793          	addi	a5,s2,88
    8000379c:	86ee                	mv	a3,s11
    8000379e:	963e                	add	a2,a2,a5
    800037a0:	85d2                	mv	a1,s4
    800037a2:	855e                	mv	a0,s7
    800037a4:	c6bfe0ef          	jal	ra,8000240e <either_copyout>
    800037a8:	05850763          	beq	a0,s8,800037f6 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	e60ff0ef          	jal	ra,80002e0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037b2:	013d09bb          	addw	s3,s10,s3
    800037b6:	009d04bb          	addw	s1,s10,s1
    800037ba:	9a6e                	add	s4,s4,s11
    800037bc:	0559f163          	bgeu	s3,s5,800037fe <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800037c0:	00a4d59b          	srliw	a1,s1,0xa
    800037c4:	855a                	mv	a0,s6
    800037c6:	8bbff0ef          	jal	ra,80003080 <bmap>
    800037ca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800037ce:	c985                	beqz	a1,800037fe <readi+0xba>
    bp = bread(ip->dev, addr);
    800037d0:	000b2503          	lw	a0,0(s6)
    800037d4:	d32ff0ef          	jal	ra,80002d06 <bread>
    800037d8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800037da:	3ff4f613          	andi	a2,s1,1023
    800037de:	40cc87bb          	subw	a5,s9,a2
    800037e2:	413a873b          	subw	a4,s5,s3
    800037e6:	8d3e                	mv	s10,a5
    800037e8:	2781                	sext.w	a5,a5
    800037ea:	0007069b          	sext.w	a3,a4
    800037ee:	faf6f1e3          	bgeu	a3,a5,80003790 <readi+0x4c>
    800037f2:	8d3a                	mv	s10,a4
    800037f4:	bf71                	j	80003790 <readi+0x4c>
      brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	e16ff0ef          	jal	ra,80002e0e <brelse>
      tot = -1;
    800037fc:	59fd                	li	s3,-1
  }
  return tot;
    800037fe:	0009851b          	sext.w	a0,s3
}
    80003802:	70a6                	ld	ra,104(sp)
    80003804:	7406                	ld	s0,96(sp)
    80003806:	64e6                	ld	s1,88(sp)
    80003808:	6946                	ld	s2,80(sp)
    8000380a:	69a6                	ld	s3,72(sp)
    8000380c:	6a06                	ld	s4,64(sp)
    8000380e:	7ae2                	ld	s5,56(sp)
    80003810:	7b42                	ld	s6,48(sp)
    80003812:	7ba2                	ld	s7,40(sp)
    80003814:	7c02                	ld	s8,32(sp)
    80003816:	6ce2                	ld	s9,24(sp)
    80003818:	6d42                	ld	s10,16(sp)
    8000381a:	6da2                	ld	s11,8(sp)
    8000381c:	6165                	addi	sp,sp,112
    8000381e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003820:	89d6                	mv	s3,s5
    80003822:	bff1                	j	800037fe <readi+0xba>
    return 0;
    80003824:	4501                	li	a0,0
}
    80003826:	8082                	ret

0000000080003828 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003828:	457c                	lw	a5,76(a0)
    8000382a:	0ed7ea63          	bltu	a5,a3,8000391e <writei+0xf6>
{
    8000382e:	7159                	addi	sp,sp,-112
    80003830:	f486                	sd	ra,104(sp)
    80003832:	f0a2                	sd	s0,96(sp)
    80003834:	eca6                	sd	s1,88(sp)
    80003836:	e8ca                	sd	s2,80(sp)
    80003838:	e4ce                	sd	s3,72(sp)
    8000383a:	e0d2                	sd	s4,64(sp)
    8000383c:	fc56                	sd	s5,56(sp)
    8000383e:	f85a                	sd	s6,48(sp)
    80003840:	f45e                	sd	s7,40(sp)
    80003842:	f062                	sd	s8,32(sp)
    80003844:	ec66                	sd	s9,24(sp)
    80003846:	e86a                	sd	s10,16(sp)
    80003848:	e46e                	sd	s11,8(sp)
    8000384a:	1880                	addi	s0,sp,112
    8000384c:	8aaa                	mv	s5,a0
    8000384e:	8bae                	mv	s7,a1
    80003850:	8a32                	mv	s4,a2
    80003852:	8936                	mv	s2,a3
    80003854:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003856:	00e687bb          	addw	a5,a3,a4
    8000385a:	0cd7e463          	bltu	a5,a3,80003922 <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000385e:	00043737          	lui	a4,0x43
    80003862:	0cf76263          	bltu	a4,a5,80003926 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003866:	0a0b0a63          	beqz	s6,8000391a <writei+0xf2>
    8000386a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000386c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003870:	5c7d                	li	s8,-1
    80003872:	a825                	j	800038aa <writei+0x82>
    80003874:	020d1d93          	slli	s11,s10,0x20
    80003878:	020ddd93          	srli	s11,s11,0x20
    8000387c:	05848793          	addi	a5,s1,88
    80003880:	86ee                	mv	a3,s11
    80003882:	8652                	mv	a2,s4
    80003884:	85de                	mv	a1,s7
    80003886:	953e                	add	a0,a0,a5
    80003888:	bd1fe0ef          	jal	ra,80002458 <either_copyin>
    8000388c:	05850a63          	beq	a0,s8,800038e0 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003890:	8526                	mv	a0,s1
    80003892:	688000ef          	jal	ra,80003f1a <log_write>
    brelse(bp);
    80003896:	8526                	mv	a0,s1
    80003898:	d76ff0ef          	jal	ra,80002e0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000389c:	013d09bb          	addw	s3,s10,s3
    800038a0:	012d093b          	addw	s2,s10,s2
    800038a4:	9a6e                	add	s4,s4,s11
    800038a6:	0569f063          	bgeu	s3,s6,800038e6 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800038aa:	00a9559b          	srliw	a1,s2,0xa
    800038ae:	8556                	mv	a0,s5
    800038b0:	fd0ff0ef          	jal	ra,80003080 <bmap>
    800038b4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800038b8:	c59d                	beqz	a1,800038e6 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800038ba:	000aa503          	lw	a0,0(s5)
    800038be:	c48ff0ef          	jal	ra,80002d06 <bread>
    800038c2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038c4:	3ff97513          	andi	a0,s2,1023
    800038c8:	40ac87bb          	subw	a5,s9,a0
    800038cc:	413b073b          	subw	a4,s6,s3
    800038d0:	8d3e                	mv	s10,a5
    800038d2:	2781                	sext.w	a5,a5
    800038d4:	0007069b          	sext.w	a3,a4
    800038d8:	f8f6fee3          	bgeu	a3,a5,80003874 <writei+0x4c>
    800038dc:	8d3a                	mv	s10,a4
    800038de:	bf59                	j	80003874 <writei+0x4c>
      brelse(bp);
    800038e0:	8526                	mv	a0,s1
    800038e2:	d2cff0ef          	jal	ra,80002e0e <brelse>
  }

  if(off > ip->size)
    800038e6:	04caa783          	lw	a5,76(s5)
    800038ea:	0127f463          	bgeu	a5,s2,800038f2 <writei+0xca>
    ip->size = off;
    800038ee:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800038f2:	8556                	mv	a0,s5
    800038f4:	a13ff0ef          	jal	ra,80003306 <iupdate>

  return tot;
    800038f8:	0009851b          	sext.w	a0,s3
}
    800038fc:	70a6                	ld	ra,104(sp)
    800038fe:	7406                	ld	s0,96(sp)
    80003900:	64e6                	ld	s1,88(sp)
    80003902:	6946                	ld	s2,80(sp)
    80003904:	69a6                	ld	s3,72(sp)
    80003906:	6a06                	ld	s4,64(sp)
    80003908:	7ae2                	ld	s5,56(sp)
    8000390a:	7b42                	ld	s6,48(sp)
    8000390c:	7ba2                	ld	s7,40(sp)
    8000390e:	7c02                	ld	s8,32(sp)
    80003910:	6ce2                	ld	s9,24(sp)
    80003912:	6d42                	ld	s10,16(sp)
    80003914:	6da2                	ld	s11,8(sp)
    80003916:	6165                	addi	sp,sp,112
    80003918:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000391a:	89da                	mv	s3,s6
    8000391c:	bfd9                	j	800038f2 <writei+0xca>
    return -1;
    8000391e:	557d                	li	a0,-1
}
    80003920:	8082                	ret
    return -1;
    80003922:	557d                	li	a0,-1
    80003924:	bfe1                	j	800038fc <writei+0xd4>
    return -1;
    80003926:	557d                	li	a0,-1
    80003928:	bfd1                	j	800038fc <writei+0xd4>

000000008000392a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000392a:	1141                	addi	sp,sp,-16
    8000392c:	e406                	sd	ra,8(sp)
    8000392e:	e022                	sd	s0,0(sp)
    80003930:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003932:	4639                	li	a2,14
    80003934:	cd4fd0ef          	jal	ra,80000e08 <strncmp>
}
    80003938:	60a2                	ld	ra,8(sp)
    8000393a:	6402                	ld	s0,0(sp)
    8000393c:	0141                	addi	sp,sp,16
    8000393e:	8082                	ret

0000000080003940 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003940:	7139                	addi	sp,sp,-64
    80003942:	fc06                	sd	ra,56(sp)
    80003944:	f822                	sd	s0,48(sp)
    80003946:	f426                	sd	s1,40(sp)
    80003948:	f04a                	sd	s2,32(sp)
    8000394a:	ec4e                	sd	s3,24(sp)
    8000394c:	e852                	sd	s4,16(sp)
    8000394e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003950:	04451703          	lh	a4,68(a0)
    80003954:	4785                	li	a5,1
    80003956:	00f71a63          	bne	a4,a5,8000396a <dirlookup+0x2a>
    8000395a:	892a                	mv	s2,a0
    8000395c:	89ae                	mv	s3,a1
    8000395e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003960:	457c                	lw	a5,76(a0)
    80003962:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003964:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003966:	e39d                	bnez	a5,8000398c <dirlookup+0x4c>
    80003968:	a095                	j	800039cc <dirlookup+0x8c>
    panic("dirlookup not DIR");
    8000396a:	00004517          	auipc	a0,0x4
    8000396e:	ca650513          	addi	a0,a0,-858 # 80007610 <syscalls+0x1c0>
    80003972:	df9fc0ef          	jal	ra,8000076a <panic>
      panic("dirlookup read");
    80003976:	00004517          	auipc	a0,0x4
    8000397a:	cb250513          	addi	a0,a0,-846 # 80007628 <syscalls+0x1d8>
    8000397e:	dedfc0ef          	jal	ra,8000076a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003982:	24c1                	addiw	s1,s1,16
    80003984:	04c92783          	lw	a5,76(s2)
    80003988:	04f4f163          	bgeu	s1,a5,800039ca <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000398c:	4741                	li	a4,16
    8000398e:	86a6                	mv	a3,s1
    80003990:	fc040613          	addi	a2,s0,-64
    80003994:	4581                	li	a1,0
    80003996:	854a                	mv	a0,s2
    80003998:	dadff0ef          	jal	ra,80003744 <readi>
    8000399c:	47c1                	li	a5,16
    8000399e:	fcf51ce3          	bne	a0,a5,80003976 <dirlookup+0x36>
    if(de.inum == 0)
    800039a2:	fc045783          	lhu	a5,-64(s0)
    800039a6:	dff1                	beqz	a5,80003982 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800039a8:	fc240593          	addi	a1,s0,-62
    800039ac:	854e                	mv	a0,s3
    800039ae:	f7dff0ef          	jal	ra,8000392a <namecmp>
    800039b2:	f961                	bnez	a0,80003982 <dirlookup+0x42>
      if(poff)
    800039b4:	000a0463          	beqz	s4,800039bc <dirlookup+0x7c>
        *poff = off;
    800039b8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800039bc:	fc045583          	lhu	a1,-64(s0)
    800039c0:	00092503          	lw	a0,0(s2)
    800039c4:	f88ff0ef          	jal	ra,8000314c <iget>
    800039c8:	a011                	j	800039cc <dirlookup+0x8c>
  return 0;
    800039ca:	4501                	li	a0,0
}
    800039cc:	70e2                	ld	ra,56(sp)
    800039ce:	7442                	ld	s0,48(sp)
    800039d0:	74a2                	ld	s1,40(sp)
    800039d2:	7902                	ld	s2,32(sp)
    800039d4:	69e2                	ld	s3,24(sp)
    800039d6:	6a42                	ld	s4,16(sp)
    800039d8:	6121                	addi	sp,sp,64
    800039da:	8082                	ret

00000000800039dc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800039dc:	711d                	addi	sp,sp,-96
    800039de:	ec86                	sd	ra,88(sp)
    800039e0:	e8a2                	sd	s0,80(sp)
    800039e2:	e4a6                	sd	s1,72(sp)
    800039e4:	e0ca                	sd	s2,64(sp)
    800039e6:	fc4e                	sd	s3,56(sp)
    800039e8:	f852                	sd	s4,48(sp)
    800039ea:	f456                	sd	s5,40(sp)
    800039ec:	f05a                	sd	s6,32(sp)
    800039ee:	ec5e                	sd	s7,24(sp)
    800039f0:	e862                	sd	s8,16(sp)
    800039f2:	e466                	sd	s9,8(sp)
    800039f4:	1080                	addi	s0,sp,96
    800039f6:	84aa                	mv	s1,a0
    800039f8:	8aae                	mv	s5,a1
    800039fa:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800039fc:	00054703          	lbu	a4,0(a0)
    80003a00:	02f00793          	li	a5,47
    80003a04:	00f70f63          	beq	a4,a5,80003a22 <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003a08:	f57fd0ef          	jal	ra,8000195e <myproc>
    80003a0c:	15053503          	ld	a0,336(a0)
    80003a10:	973ff0ef          	jal	ra,80003382 <idup>
    80003a14:	89aa                	mv	s3,a0
  while(*path == '/')
    80003a16:	02f00913          	li	s2,47
  len = path - s;
    80003a1a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003a1c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003a1e:	4b85                	li	s7,1
    80003a20:	a861                	j	80003ab8 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003a22:	4585                	li	a1,1
    80003a24:	4505                	li	a0,1
    80003a26:	f26ff0ef          	jal	ra,8000314c <iget>
    80003a2a:	89aa                	mv	s3,a0
    80003a2c:	b7ed                	j	80003a16 <namex+0x3a>
      iunlockput(ip);
    80003a2e:	854e                	mv	a0,s3
    80003a30:	b8fff0ef          	jal	ra,800035be <iunlockput>
      return 0;
    80003a34:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003a36:	854e                	mv	a0,s3
    80003a38:	60e6                	ld	ra,88(sp)
    80003a3a:	6446                	ld	s0,80(sp)
    80003a3c:	64a6                	ld	s1,72(sp)
    80003a3e:	6906                	ld	s2,64(sp)
    80003a40:	79e2                	ld	s3,56(sp)
    80003a42:	7a42                	ld	s4,48(sp)
    80003a44:	7aa2                	ld	s5,40(sp)
    80003a46:	7b02                	ld	s6,32(sp)
    80003a48:	6be2                	ld	s7,24(sp)
    80003a4a:	6c42                	ld	s8,16(sp)
    80003a4c:	6ca2                	ld	s9,8(sp)
    80003a4e:	6125                	addi	sp,sp,96
    80003a50:	8082                	ret
      iunlock(ip);
    80003a52:	854e                	mv	a0,s3
    80003a54:	a0fff0ef          	jal	ra,80003462 <iunlock>
      return ip;
    80003a58:	bff9                	j	80003a36 <namex+0x5a>
      iunlockput(ip);
    80003a5a:	854e                	mv	a0,s3
    80003a5c:	b63ff0ef          	jal	ra,800035be <iunlockput>
      return 0;
    80003a60:	89e6                	mv	s3,s9
    80003a62:	bfd1                	j	80003a36 <namex+0x5a>
  len = path - s;
    80003a64:	40b48633          	sub	a2,s1,a1
    80003a68:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003a6c:	079c5c63          	bge	s8,s9,80003ae4 <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003a70:	4639                	li	a2,14
    80003a72:	8552                	mv	a0,s4
    80003a74:	b24fd0ef          	jal	ra,80000d98 <memmove>
  while(*path == '/')
    80003a78:	0004c783          	lbu	a5,0(s1)
    80003a7c:	01279763          	bne	a5,s2,80003a8a <namex+0xae>
    path++;
    80003a80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a82:	0004c783          	lbu	a5,0(s1)
    80003a86:	ff278de3          	beq	a5,s2,80003a80 <namex+0xa4>
    ilock(ip);
    80003a8a:	854e                	mv	a0,s3
    80003a8c:	92dff0ef          	jal	ra,800033b8 <ilock>
    if(ip->type != T_DIR){
    80003a90:	04499783          	lh	a5,68(s3)
    80003a94:	f9779de3          	bne	a5,s7,80003a2e <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003a98:	000a8563          	beqz	s5,80003aa2 <namex+0xc6>
    80003a9c:	0004c783          	lbu	a5,0(s1)
    80003aa0:	dbcd                	beqz	a5,80003a52 <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003aa2:	865a                	mv	a2,s6
    80003aa4:	85d2                	mv	a1,s4
    80003aa6:	854e                	mv	a0,s3
    80003aa8:	e99ff0ef          	jal	ra,80003940 <dirlookup>
    80003aac:	8caa                	mv	s9,a0
    80003aae:	d555                	beqz	a0,80003a5a <namex+0x7e>
    iunlockput(ip);
    80003ab0:	854e                	mv	a0,s3
    80003ab2:	b0dff0ef          	jal	ra,800035be <iunlockput>
    ip = next;
    80003ab6:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ab8:	0004c783          	lbu	a5,0(s1)
    80003abc:	05279363          	bne	a5,s2,80003b02 <namex+0x126>
    path++;
    80003ac0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ac2:	0004c783          	lbu	a5,0(s1)
    80003ac6:	ff278de3          	beq	a5,s2,80003ac0 <namex+0xe4>
  if(*path == 0)
    80003aca:	c78d                	beqz	a5,80003af4 <namex+0x118>
    path++;
    80003acc:	85a6                	mv	a1,s1
  len = path - s;
    80003ace:	8cda                	mv	s9,s6
    80003ad0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003ad2:	01278963          	beq	a5,s2,80003ae4 <namex+0x108>
    80003ad6:	d7d9                	beqz	a5,80003a64 <namex+0x88>
    path++;
    80003ad8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ada:	0004c783          	lbu	a5,0(s1)
    80003ade:	ff279ce3          	bne	a5,s2,80003ad6 <namex+0xfa>
    80003ae2:	b749                	j	80003a64 <namex+0x88>
    memmove(name, s, len);
    80003ae4:	2601                	sext.w	a2,a2
    80003ae6:	8552                	mv	a0,s4
    80003ae8:	ab0fd0ef          	jal	ra,80000d98 <memmove>
    name[len] = 0;
    80003aec:	9cd2                	add	s9,s9,s4
    80003aee:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003af2:	b759                	j	80003a78 <namex+0x9c>
  if(nameiparent){
    80003af4:	f40a81e3          	beqz	s5,80003a36 <namex+0x5a>
    iput(ip);
    80003af8:	854e                	mv	a0,s3
    80003afa:	a3dff0ef          	jal	ra,80003536 <iput>
    return 0;
    80003afe:	4981                	li	s3,0
    80003b00:	bf1d                	j	80003a36 <namex+0x5a>
  if(*path == 0)
    80003b02:	dbed                	beqz	a5,80003af4 <namex+0x118>
  while(*path != '/' && *path != 0)
    80003b04:	0004c783          	lbu	a5,0(s1)
    80003b08:	85a6                	mv	a1,s1
    80003b0a:	b7f1                	j	80003ad6 <namex+0xfa>

0000000080003b0c <dirlink>:
{
    80003b0c:	7139                	addi	sp,sp,-64
    80003b0e:	fc06                	sd	ra,56(sp)
    80003b10:	f822                	sd	s0,48(sp)
    80003b12:	f426                	sd	s1,40(sp)
    80003b14:	f04a                	sd	s2,32(sp)
    80003b16:	ec4e                	sd	s3,24(sp)
    80003b18:	e852                	sd	s4,16(sp)
    80003b1a:	0080                	addi	s0,sp,64
    80003b1c:	892a                	mv	s2,a0
    80003b1e:	8a2e                	mv	s4,a1
    80003b20:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003b22:	4601                	li	a2,0
    80003b24:	e1dff0ef          	jal	ra,80003940 <dirlookup>
    80003b28:	e52d                	bnez	a0,80003b92 <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2a:	04c92483          	lw	s1,76(s2)
    80003b2e:	c48d                	beqz	s1,80003b58 <dirlink+0x4c>
    80003b30:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b32:	4741                	li	a4,16
    80003b34:	86a6                	mv	a3,s1
    80003b36:	fc040613          	addi	a2,s0,-64
    80003b3a:	4581                	li	a1,0
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	c07ff0ef          	jal	ra,80003744 <readi>
    80003b42:	47c1                	li	a5,16
    80003b44:	04f51b63          	bne	a0,a5,80003b9a <dirlink+0x8e>
    if(de.inum == 0)
    80003b48:	fc045783          	lhu	a5,-64(s0)
    80003b4c:	c791                	beqz	a5,80003b58 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4e:	24c1                	addiw	s1,s1,16
    80003b50:	04c92783          	lw	a5,76(s2)
    80003b54:	fcf4efe3          	bltu	s1,a5,80003b32 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003b58:	4639                	li	a2,14
    80003b5a:	85d2                	mv	a1,s4
    80003b5c:	fc240513          	addi	a0,s0,-62
    80003b60:	ae4fd0ef          	jal	ra,80000e44 <strncpy>
  de.inum = inum;
    80003b64:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b68:	4741                	li	a4,16
    80003b6a:	86a6                	mv	a3,s1
    80003b6c:	fc040613          	addi	a2,s0,-64
    80003b70:	4581                	li	a1,0
    80003b72:	854a                	mv	a0,s2
    80003b74:	cb5ff0ef          	jal	ra,80003828 <writei>
    80003b78:	1541                	addi	a0,a0,-16
    80003b7a:	00a03533          	snez	a0,a0
    80003b7e:	40a00533          	neg	a0,a0
}
    80003b82:	70e2                	ld	ra,56(sp)
    80003b84:	7442                	ld	s0,48(sp)
    80003b86:	74a2                	ld	s1,40(sp)
    80003b88:	7902                	ld	s2,32(sp)
    80003b8a:	69e2                	ld	s3,24(sp)
    80003b8c:	6a42                	ld	s4,16(sp)
    80003b8e:	6121                	addi	sp,sp,64
    80003b90:	8082                	ret
    iput(ip);
    80003b92:	9a5ff0ef          	jal	ra,80003536 <iput>
    return -1;
    80003b96:	557d                	li	a0,-1
    80003b98:	b7ed                	j	80003b82 <dirlink+0x76>
      panic("dirlink read");
    80003b9a:	00004517          	auipc	a0,0x4
    80003b9e:	a9e50513          	addi	a0,a0,-1378 # 80007638 <syscalls+0x1e8>
    80003ba2:	bc9fc0ef          	jal	ra,8000076a <panic>

0000000080003ba6 <namei>:

struct inode*
namei(char *path)
{
    80003ba6:	1101                	addi	sp,sp,-32
    80003ba8:	ec06                	sd	ra,24(sp)
    80003baa:	e822                	sd	s0,16(sp)
    80003bac:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003bae:	fe040613          	addi	a2,s0,-32
    80003bb2:	4581                	li	a1,0
    80003bb4:	e29ff0ef          	jal	ra,800039dc <namex>
}
    80003bb8:	60e2                	ld	ra,24(sp)
    80003bba:	6442                	ld	s0,16(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret

0000000080003bc0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003bc0:	1141                	addi	sp,sp,-16
    80003bc2:	e406                	sd	ra,8(sp)
    80003bc4:	e022                	sd	s0,0(sp)
    80003bc6:	0800                	addi	s0,sp,16
    80003bc8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003bca:	4585                	li	a1,1
    80003bcc:	e11ff0ef          	jal	ra,800039dc <namex>
}
    80003bd0:	60a2                	ld	ra,8(sp)
    80003bd2:	6402                	ld	s0,0(sp)
    80003bd4:	0141                	addi	sp,sp,16
    80003bd6:	8082                	ret

0000000080003bd8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	e04a                	sd	s2,0(sp)
    80003be2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003be4:	0023c917          	auipc	s2,0x23c
    80003be8:	1b490913          	addi	s2,s2,436 # 8023fd98 <log>
    80003bec:	01892583          	lw	a1,24(s2)
    80003bf0:	02492503          	lw	a0,36(s2)
    80003bf4:	912ff0ef          	jal	ra,80002d06 <bread>
    80003bf8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003bfa:	02892683          	lw	a3,40(s2)
    80003bfe:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003c00:	02d05763          	blez	a3,80003c2e <write_head+0x56>
    80003c04:	0023c797          	auipc	a5,0x23c
    80003c08:	1c078793          	addi	a5,a5,448 # 8023fdc4 <log+0x2c>
    80003c0c:	05c50713          	addi	a4,a0,92
    80003c10:	36fd                	addiw	a3,a3,-1
    80003c12:	1682                	slli	a3,a3,0x20
    80003c14:	9281                	srli	a3,a3,0x20
    80003c16:	068a                	slli	a3,a3,0x2
    80003c18:	0023c617          	auipc	a2,0x23c
    80003c1c:	1b060613          	addi	a2,a2,432 # 8023fdc8 <log+0x30>
    80003c20:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003c22:	4390                	lw	a2,0(a5)
    80003c24:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c26:	0791                	addi	a5,a5,4
    80003c28:	0711                	addi	a4,a4,4
    80003c2a:	fed79ce3          	bne	a5,a3,80003c22 <write_head+0x4a>
  }
  bwrite(buf);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	9acff0ef          	jal	ra,80002ddc <bwrite>
  brelse(buf);
    80003c34:	8526                	mv	a0,s1
    80003c36:	9d8ff0ef          	jal	ra,80002e0e <brelse>
}
    80003c3a:	60e2                	ld	ra,24(sp)
    80003c3c:	6442                	ld	s0,16(sp)
    80003c3e:	64a2                	ld	s1,8(sp)
    80003c40:	6902                	ld	s2,0(sp)
    80003c42:	6105                	addi	sp,sp,32
    80003c44:	8082                	ret

0000000080003c46 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c46:	0023c797          	auipc	a5,0x23c
    80003c4a:	17a7a783          	lw	a5,378(a5) # 8023fdc0 <log+0x28>
    80003c4e:	0af05e63          	blez	a5,80003d0a <install_trans+0xc4>
{
    80003c52:	715d                	addi	sp,sp,-80
    80003c54:	e486                	sd	ra,72(sp)
    80003c56:	e0a2                	sd	s0,64(sp)
    80003c58:	fc26                	sd	s1,56(sp)
    80003c5a:	f84a                	sd	s2,48(sp)
    80003c5c:	f44e                	sd	s3,40(sp)
    80003c5e:	f052                	sd	s4,32(sp)
    80003c60:	ec56                	sd	s5,24(sp)
    80003c62:	e85a                	sd	s6,16(sp)
    80003c64:	e45e                	sd	s7,8(sp)
    80003c66:	0880                	addi	s0,sp,80
    80003c68:	8b2a                	mv	s6,a0
    80003c6a:	0023ca97          	auipc	s5,0x23c
    80003c6e:	15aa8a93          	addi	s5,s5,346 # 8023fdc4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c72:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c74:	00004b97          	auipc	s7,0x4
    80003c78:	9d4b8b93          	addi	s7,s7,-1580 # 80007648 <syscalls+0x1f8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003c7c:	0023ca17          	auipc	s4,0x23c
    80003c80:	11ca0a13          	addi	s4,s4,284 # 8023fd98 <log>
    80003c84:	a025                	j	80003cac <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c86:	000aa603          	lw	a2,0(s5)
    80003c8a:	85ce                	mv	a1,s3
    80003c8c:	855e                	mv	a0,s7
    80003c8e:	817fc0ef          	jal	ra,800004a4 <printf>
    80003c92:	a839                	j	80003cb0 <install_trans+0x6a>
    brelse(lbuf);
    80003c94:	854a                	mv	a0,s2
    80003c96:	978ff0ef          	jal	ra,80002e0e <brelse>
    brelse(dbuf);
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	972ff0ef          	jal	ra,80002e0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ca0:	2985                	addiw	s3,s3,1
    80003ca2:	0a91                	addi	s5,s5,4
    80003ca4:	028a2783          	lw	a5,40(s4)
    80003ca8:	04f9d663          	bge	s3,a5,80003cf4 <install_trans+0xae>
    if(recovering) {
    80003cac:	fc0b1de3          	bnez	s6,80003c86 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003cb0:	018a2583          	lw	a1,24(s4)
    80003cb4:	013585bb          	addw	a1,a1,s3
    80003cb8:	2585                	addiw	a1,a1,1
    80003cba:	024a2503          	lw	a0,36(s4)
    80003cbe:	848ff0ef          	jal	ra,80002d06 <bread>
    80003cc2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003cc4:	000aa583          	lw	a1,0(s5)
    80003cc8:	024a2503          	lw	a0,36(s4)
    80003ccc:	83aff0ef          	jal	ra,80002d06 <bread>
    80003cd0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003cd2:	40000613          	li	a2,1024
    80003cd6:	05890593          	addi	a1,s2,88
    80003cda:	05850513          	addi	a0,a0,88
    80003cde:	8bafd0ef          	jal	ra,80000d98 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ce2:	8526                	mv	a0,s1
    80003ce4:	8f8ff0ef          	jal	ra,80002ddc <bwrite>
    if(recovering == 0)
    80003ce8:	fa0b16e3          	bnez	s6,80003c94 <install_trans+0x4e>
      bunpin(dbuf);
    80003cec:	8526                	mv	a0,s1
    80003cee:	9deff0ef          	jal	ra,80002ecc <bunpin>
    80003cf2:	b74d                	j	80003c94 <install_trans+0x4e>
}
    80003cf4:	60a6                	ld	ra,72(sp)
    80003cf6:	6406                	ld	s0,64(sp)
    80003cf8:	74e2                	ld	s1,56(sp)
    80003cfa:	7942                	ld	s2,48(sp)
    80003cfc:	79a2                	ld	s3,40(sp)
    80003cfe:	7a02                	ld	s4,32(sp)
    80003d00:	6ae2                	ld	s5,24(sp)
    80003d02:	6b42                	ld	s6,16(sp)
    80003d04:	6ba2                	ld	s7,8(sp)
    80003d06:	6161                	addi	sp,sp,80
    80003d08:	8082                	ret
    80003d0a:	8082                	ret

0000000080003d0c <initlog>:
{
    80003d0c:	7179                	addi	sp,sp,-48
    80003d0e:	f406                	sd	ra,40(sp)
    80003d10:	f022                	sd	s0,32(sp)
    80003d12:	ec26                	sd	s1,24(sp)
    80003d14:	e84a                	sd	s2,16(sp)
    80003d16:	e44e                	sd	s3,8(sp)
    80003d18:	1800                	addi	s0,sp,48
    80003d1a:	892a                	mv	s2,a0
    80003d1c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003d1e:	0023c497          	auipc	s1,0x23c
    80003d22:	07a48493          	addi	s1,s1,122 # 8023fd98 <log>
    80003d26:	00004597          	auipc	a1,0x4
    80003d2a:	94258593          	addi	a1,a1,-1726 # 80007668 <syscalls+0x218>
    80003d2e:	8526                	mv	a0,s1
    80003d30:	eb9fc0ef          	jal	ra,80000be8 <initlock>
  log.start = sb->logstart;
    80003d34:	0149a583          	lw	a1,20(s3)
    80003d38:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003d3a:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	fc7fe0ef          	jal	ra,80002d06 <bread>
  log.lh.n = lh->n;
    80003d44:	4d34                	lw	a3,88(a0)
    80003d46:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003d48:	02d05563          	blez	a3,80003d72 <initlog+0x66>
    80003d4c:	05c50793          	addi	a5,a0,92
    80003d50:	0023c717          	auipc	a4,0x23c
    80003d54:	07470713          	addi	a4,a4,116 # 8023fdc4 <log+0x2c>
    80003d58:	36fd                	addiw	a3,a3,-1
    80003d5a:	1682                	slli	a3,a3,0x20
    80003d5c:	9281                	srli	a3,a3,0x20
    80003d5e:	068a                	slli	a3,a3,0x2
    80003d60:	06050613          	addi	a2,a0,96
    80003d64:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003d66:	4390                	lw	a2,0(a5)
    80003d68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d6a:	0791                	addi	a5,a5,4
    80003d6c:	0711                	addi	a4,a4,4
    80003d6e:	fed79ce3          	bne	a5,a3,80003d66 <initlog+0x5a>
  brelse(buf);
    80003d72:	89cff0ef          	jal	ra,80002e0e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003d76:	4505                	li	a0,1
    80003d78:	ecfff0ef          	jal	ra,80003c46 <install_trans>
  log.lh.n = 0;
    80003d7c:	0023c797          	auipc	a5,0x23c
    80003d80:	0407a223          	sw	zero,68(a5) # 8023fdc0 <log+0x28>
  write_head(); // clear the log
    80003d84:	e55ff0ef          	jal	ra,80003bd8 <write_head>
}
    80003d88:	70a2                	ld	ra,40(sp)
    80003d8a:	7402                	ld	s0,32(sp)
    80003d8c:	64e2                	ld	s1,24(sp)
    80003d8e:	6942                	ld	s2,16(sp)
    80003d90:	69a2                	ld	s3,8(sp)
    80003d92:	6145                	addi	sp,sp,48
    80003d94:	8082                	ret

0000000080003d96 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003d96:	1101                	addi	sp,sp,-32
    80003d98:	ec06                	sd	ra,24(sp)
    80003d9a:	e822                	sd	s0,16(sp)
    80003d9c:	e426                	sd	s1,8(sp)
    80003d9e:	e04a                	sd	s2,0(sp)
    80003da0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003da2:	0023c517          	auipc	a0,0x23c
    80003da6:	ff650513          	addi	a0,a0,-10 # 8023fd98 <log>
    80003daa:	ebffc0ef          	jal	ra,80000c68 <acquire>
  while(1){
    if(log.committing){
    80003dae:	0023c497          	auipc	s1,0x23c
    80003db2:	fea48493          	addi	s1,s1,-22 # 8023fd98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003db6:	4979                	li	s2,30
    80003db8:	a029                	j	80003dc2 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003dba:	85a6                	mv	a1,s1
    80003dbc:	8526                	mv	a0,s1
    80003dbe:	af4fe0ef          	jal	ra,800020b2 <sleep>
    if(log.committing){
    80003dc2:	509c                	lw	a5,32(s1)
    80003dc4:	fbfd                	bnez	a5,80003dba <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003dc6:	4cdc                	lw	a5,28(s1)
    80003dc8:	0017871b          	addiw	a4,a5,1
    80003dcc:	0007069b          	sext.w	a3,a4
    80003dd0:	0027179b          	slliw	a5,a4,0x2
    80003dd4:	9fb9                	addw	a5,a5,a4
    80003dd6:	0017979b          	slliw	a5,a5,0x1
    80003dda:	5498                	lw	a4,40(s1)
    80003ddc:	9fb9                	addw	a5,a5,a4
    80003dde:	00f95763          	bge	s2,a5,80003dec <begin_op+0x56>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003de2:	85a6                	mv	a1,s1
    80003de4:	8526                	mv	a0,s1
    80003de6:	accfe0ef          	jal	ra,800020b2 <sleep>
    80003dea:	bfe1                	j	80003dc2 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003dec:	0023c517          	auipc	a0,0x23c
    80003df0:	fac50513          	addi	a0,a0,-84 # 8023fd98 <log>
    80003df4:	cd54                	sw	a3,28(a0)
      release(&log.lock);
    80003df6:	f0bfc0ef          	jal	ra,80000d00 <release>
      break;
    }
  }
}
    80003dfa:	60e2                	ld	ra,24(sp)
    80003dfc:	6442                	ld	s0,16(sp)
    80003dfe:	64a2                	ld	s1,8(sp)
    80003e00:	6902                	ld	s2,0(sp)
    80003e02:	6105                	addi	sp,sp,32
    80003e04:	8082                	ret

0000000080003e06 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003e06:	7139                	addi	sp,sp,-64
    80003e08:	fc06                	sd	ra,56(sp)
    80003e0a:	f822                	sd	s0,48(sp)
    80003e0c:	f426                	sd	s1,40(sp)
    80003e0e:	f04a                	sd	s2,32(sp)
    80003e10:	ec4e                	sd	s3,24(sp)
    80003e12:	e852                	sd	s4,16(sp)
    80003e14:	e456                	sd	s5,8(sp)
    80003e16:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003e18:	0023c497          	auipc	s1,0x23c
    80003e1c:	f8048493          	addi	s1,s1,-128 # 8023fd98 <log>
    80003e20:	8526                	mv	a0,s1
    80003e22:	e47fc0ef          	jal	ra,80000c68 <acquire>
  log.outstanding -= 1;
    80003e26:	4cdc                	lw	a5,28(s1)
    80003e28:	37fd                	addiw	a5,a5,-1
    80003e2a:	0007891b          	sext.w	s2,a5
    80003e2e:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003e30:	509c                	lw	a5,32(s1)
    80003e32:	ef9d                	bnez	a5,80003e70 <end_op+0x6a>
    panic("log.committing");
  if(log.outstanding == 0){
    80003e34:	04091463          	bnez	s2,80003e7c <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003e38:	0023c497          	auipc	s1,0x23c
    80003e3c:	f6048493          	addi	s1,s1,-160 # 8023fd98 <log>
    80003e40:	4785                	li	a5,1
    80003e42:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003e44:	8526                	mv	a0,s1
    80003e46:	ebbfc0ef          	jal	ra,80000d00 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003e4a:	549c                	lw	a5,40(s1)
    80003e4c:	04f04b63          	bgtz	a5,80003ea2 <end_op+0x9c>
    acquire(&log.lock);
    80003e50:	0023c497          	auipc	s1,0x23c
    80003e54:	f4848493          	addi	s1,s1,-184 # 8023fd98 <log>
    80003e58:	8526                	mv	a0,s1
    80003e5a:	e0ffc0ef          	jal	ra,80000c68 <acquire>
    log.committing = 0;
    80003e5e:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003e62:	8526                	mv	a0,s1
    80003e64:	a9afe0ef          	jal	ra,800020fe <wakeup>
    release(&log.lock);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	e97fc0ef          	jal	ra,80000d00 <release>
}
    80003e6e:	a00d                	j	80003e90 <end_op+0x8a>
    panic("log.committing");
    80003e70:	00004517          	auipc	a0,0x4
    80003e74:	80050513          	addi	a0,a0,-2048 # 80007670 <syscalls+0x220>
    80003e78:	8f3fc0ef          	jal	ra,8000076a <panic>
    wakeup(&log);
    80003e7c:	0023c497          	auipc	s1,0x23c
    80003e80:	f1c48493          	addi	s1,s1,-228 # 8023fd98 <log>
    80003e84:	8526                	mv	a0,s1
    80003e86:	a78fe0ef          	jal	ra,800020fe <wakeup>
  release(&log.lock);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	e75fc0ef          	jal	ra,80000d00 <release>
}
    80003e90:	70e2                	ld	ra,56(sp)
    80003e92:	7442                	ld	s0,48(sp)
    80003e94:	74a2                	ld	s1,40(sp)
    80003e96:	7902                	ld	s2,32(sp)
    80003e98:	69e2                	ld	s3,24(sp)
    80003e9a:	6a42                	ld	s4,16(sp)
    80003e9c:	6aa2                	ld	s5,8(sp)
    80003e9e:	6121                	addi	sp,sp,64
    80003ea0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea2:	0023ca97          	auipc	s5,0x23c
    80003ea6:	f22a8a93          	addi	s5,s5,-222 # 8023fdc4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003eaa:	0023ca17          	auipc	s4,0x23c
    80003eae:	eeea0a13          	addi	s4,s4,-274 # 8023fd98 <log>
    80003eb2:	018a2583          	lw	a1,24(s4)
    80003eb6:	012585bb          	addw	a1,a1,s2
    80003eba:	2585                	addiw	a1,a1,1
    80003ebc:	024a2503          	lw	a0,36(s4)
    80003ec0:	e47fe0ef          	jal	ra,80002d06 <bread>
    80003ec4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003ec6:	000aa583          	lw	a1,0(s5)
    80003eca:	024a2503          	lw	a0,36(s4)
    80003ece:	e39fe0ef          	jal	ra,80002d06 <bread>
    80003ed2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003ed4:	40000613          	li	a2,1024
    80003ed8:	05850593          	addi	a1,a0,88
    80003edc:	05848513          	addi	a0,s1,88
    80003ee0:	eb9fc0ef          	jal	ra,80000d98 <memmove>
    bwrite(to);  // write the log
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	ef7fe0ef          	jal	ra,80002ddc <bwrite>
    brelse(from);
    80003eea:	854e                	mv	a0,s3
    80003eec:	f23fe0ef          	jal	ra,80002e0e <brelse>
    brelse(to);
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	f1dfe0ef          	jal	ra,80002e0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ef6:	2905                	addiw	s2,s2,1
    80003ef8:	0a91                	addi	s5,s5,4
    80003efa:	028a2783          	lw	a5,40(s4)
    80003efe:	faf94ae3          	blt	s2,a5,80003eb2 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003f02:	cd7ff0ef          	jal	ra,80003bd8 <write_head>
    install_trans(0); // Now install writes to home locations
    80003f06:	4501                	li	a0,0
    80003f08:	d3fff0ef          	jal	ra,80003c46 <install_trans>
    log.lh.n = 0;
    80003f0c:	0023c797          	auipc	a5,0x23c
    80003f10:	ea07aa23          	sw	zero,-332(a5) # 8023fdc0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003f14:	cc5ff0ef          	jal	ra,80003bd8 <write_head>
    80003f18:	bf25                	j	80003e50 <end_op+0x4a>

0000000080003f1a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003f1a:	1101                	addi	sp,sp,-32
    80003f1c:	ec06                	sd	ra,24(sp)
    80003f1e:	e822                	sd	s0,16(sp)
    80003f20:	e426                	sd	s1,8(sp)
    80003f22:	e04a                	sd	s2,0(sp)
    80003f24:	1000                	addi	s0,sp,32
    80003f26:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003f28:	0023c917          	auipc	s2,0x23c
    80003f2c:	e7090913          	addi	s2,s2,-400 # 8023fd98 <log>
    80003f30:	854a                	mv	a0,s2
    80003f32:	d37fc0ef          	jal	ra,80000c68 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003f36:	02892603          	lw	a2,40(s2)
    80003f3a:	47f5                	li	a5,29
    80003f3c:	04c7cc63          	blt	a5,a2,80003f94 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003f40:	0023c797          	auipc	a5,0x23c
    80003f44:	e747a783          	lw	a5,-396(a5) # 8023fdb4 <log+0x1c>
    80003f48:	04f05c63          	blez	a5,80003fa0 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003f4c:	4781                	li	a5,0
    80003f4e:	04c05f63          	blez	a2,80003fac <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003f52:	44cc                	lw	a1,12(s1)
    80003f54:	0023c717          	auipc	a4,0x23c
    80003f58:	e7070713          	addi	a4,a4,-400 # 8023fdc4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003f5c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003f5e:	4314                	lw	a3,0(a4)
    80003f60:	04b68663          	beq	a3,a1,80003fac <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003f64:	2785                	addiw	a5,a5,1
    80003f66:	0711                	addi	a4,a4,4
    80003f68:	fef61be3          	bne	a2,a5,80003f5e <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003f6c:	0621                	addi	a2,a2,8
    80003f6e:	060a                	slli	a2,a2,0x2
    80003f70:	0023c797          	auipc	a5,0x23c
    80003f74:	e2878793          	addi	a5,a5,-472 # 8023fd98 <log>
    80003f78:	963e                	add	a2,a2,a5
    80003f7a:	44dc                	lw	a5,12(s1)
    80003f7c:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	f19fe0ef          	jal	ra,80002e98 <bpin>
    log.lh.n++;
    80003f84:	0023c717          	auipc	a4,0x23c
    80003f88:	e1470713          	addi	a4,a4,-492 # 8023fd98 <log>
    80003f8c:	571c                	lw	a5,40(a4)
    80003f8e:	2785                	addiw	a5,a5,1
    80003f90:	d71c                	sw	a5,40(a4)
    80003f92:	a815                	j	80003fc6 <log_write+0xac>
    panic("too big a transaction");
    80003f94:	00003517          	auipc	a0,0x3
    80003f98:	6ec50513          	addi	a0,a0,1772 # 80007680 <syscalls+0x230>
    80003f9c:	fcefc0ef          	jal	ra,8000076a <panic>
    panic("log_write outside of trans");
    80003fa0:	00003517          	auipc	a0,0x3
    80003fa4:	6f850513          	addi	a0,a0,1784 # 80007698 <syscalls+0x248>
    80003fa8:	fc2fc0ef          	jal	ra,8000076a <panic>
  log.lh.block[i] = b->blockno;
    80003fac:	00878713          	addi	a4,a5,8
    80003fb0:	00271693          	slli	a3,a4,0x2
    80003fb4:	0023c717          	auipc	a4,0x23c
    80003fb8:	de470713          	addi	a4,a4,-540 # 8023fd98 <log>
    80003fbc:	9736                	add	a4,a4,a3
    80003fbe:	44d4                	lw	a3,12(s1)
    80003fc0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003fc2:	faf60ee3          	beq	a2,a5,80003f7e <log_write+0x64>
  }
  release(&log.lock);
    80003fc6:	0023c517          	auipc	a0,0x23c
    80003fca:	dd250513          	addi	a0,a0,-558 # 8023fd98 <log>
    80003fce:	d33fc0ef          	jal	ra,80000d00 <release>
}
    80003fd2:	60e2                	ld	ra,24(sp)
    80003fd4:	6442                	ld	s0,16(sp)
    80003fd6:	64a2                	ld	s1,8(sp)
    80003fd8:	6902                	ld	s2,0(sp)
    80003fda:	6105                	addi	sp,sp,32
    80003fdc:	8082                	ret

0000000080003fde <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003fde:	1101                	addi	sp,sp,-32
    80003fe0:	ec06                	sd	ra,24(sp)
    80003fe2:	e822                	sd	s0,16(sp)
    80003fe4:	e426                	sd	s1,8(sp)
    80003fe6:	e04a                	sd	s2,0(sp)
    80003fe8:	1000                	addi	s0,sp,32
    80003fea:	84aa                	mv	s1,a0
    80003fec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003fee:	00003597          	auipc	a1,0x3
    80003ff2:	6ca58593          	addi	a1,a1,1738 # 800076b8 <syscalls+0x268>
    80003ff6:	0521                	addi	a0,a0,8
    80003ff8:	bf1fc0ef          	jal	ra,80000be8 <initlock>
  lk->name = name;
    80003ffc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004000:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004004:	0204a423          	sw	zero,40(s1)
}
    80004008:	60e2                	ld	ra,24(sp)
    8000400a:	6442                	ld	s0,16(sp)
    8000400c:	64a2                	ld	s1,8(sp)
    8000400e:	6902                	ld	s2,0(sp)
    80004010:	6105                	addi	sp,sp,32
    80004012:	8082                	ret

0000000080004014 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004014:	1101                	addi	sp,sp,-32
    80004016:	ec06                	sd	ra,24(sp)
    80004018:	e822                	sd	s0,16(sp)
    8000401a:	e426                	sd	s1,8(sp)
    8000401c:	e04a                	sd	s2,0(sp)
    8000401e:	1000                	addi	s0,sp,32
    80004020:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004022:	00850913          	addi	s2,a0,8
    80004026:	854a                	mv	a0,s2
    80004028:	c41fc0ef          	jal	ra,80000c68 <acquire>
  while (lk->locked) {
    8000402c:	409c                	lw	a5,0(s1)
    8000402e:	c799                	beqz	a5,8000403c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004030:	85ca                	mv	a1,s2
    80004032:	8526                	mv	a0,s1
    80004034:	87efe0ef          	jal	ra,800020b2 <sleep>
  while (lk->locked) {
    80004038:	409c                	lw	a5,0(s1)
    8000403a:	fbfd                	bnez	a5,80004030 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    8000403c:	4785                	li	a5,1
    8000403e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004040:	91ffd0ef          	jal	ra,8000195e <myproc>
    80004044:	591c                	lw	a5,48(a0)
    80004046:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004048:	854a                	mv	a0,s2
    8000404a:	cb7fc0ef          	jal	ra,80000d00 <release>
}
    8000404e:	60e2                	ld	ra,24(sp)
    80004050:	6442                	ld	s0,16(sp)
    80004052:	64a2                	ld	s1,8(sp)
    80004054:	6902                	ld	s2,0(sp)
    80004056:	6105                	addi	sp,sp,32
    80004058:	8082                	ret

000000008000405a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000405a:	1101                	addi	sp,sp,-32
    8000405c:	ec06                	sd	ra,24(sp)
    8000405e:	e822                	sd	s0,16(sp)
    80004060:	e426                	sd	s1,8(sp)
    80004062:	e04a                	sd	s2,0(sp)
    80004064:	1000                	addi	s0,sp,32
    80004066:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004068:	00850913          	addi	s2,a0,8
    8000406c:	854a                	mv	a0,s2
    8000406e:	bfbfc0ef          	jal	ra,80000c68 <acquire>
  lk->locked = 0;
    80004072:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004076:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000407a:	8526                	mv	a0,s1
    8000407c:	882fe0ef          	jal	ra,800020fe <wakeup>
  release(&lk->lk);
    80004080:	854a                	mv	a0,s2
    80004082:	c7ffc0ef          	jal	ra,80000d00 <release>
}
    80004086:	60e2                	ld	ra,24(sp)
    80004088:	6442                	ld	s0,16(sp)
    8000408a:	64a2                	ld	s1,8(sp)
    8000408c:	6902                	ld	s2,0(sp)
    8000408e:	6105                	addi	sp,sp,32
    80004090:	8082                	ret

0000000080004092 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004092:	7179                	addi	sp,sp,-48
    80004094:	f406                	sd	ra,40(sp)
    80004096:	f022                	sd	s0,32(sp)
    80004098:	ec26                	sd	s1,24(sp)
    8000409a:	e84a                	sd	s2,16(sp)
    8000409c:	e44e                	sd	s3,8(sp)
    8000409e:	1800                	addi	s0,sp,48
    800040a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800040a2:	00850913          	addi	s2,a0,8
    800040a6:	854a                	mv	a0,s2
    800040a8:	bc1fc0ef          	jal	ra,80000c68 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800040ac:	409c                	lw	a5,0(s1)
    800040ae:	ef89                	bnez	a5,800040c8 <holdingsleep+0x36>
    800040b0:	4481                	li	s1,0
  release(&lk->lk);
    800040b2:	854a                	mv	a0,s2
    800040b4:	c4dfc0ef          	jal	ra,80000d00 <release>
  return r;
}
    800040b8:	8526                	mv	a0,s1
    800040ba:	70a2                	ld	ra,40(sp)
    800040bc:	7402                	ld	s0,32(sp)
    800040be:	64e2                	ld	s1,24(sp)
    800040c0:	6942                	ld	s2,16(sp)
    800040c2:	69a2                	ld	s3,8(sp)
    800040c4:	6145                	addi	sp,sp,48
    800040c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800040c8:	0284a983          	lw	s3,40(s1)
    800040cc:	893fd0ef          	jal	ra,8000195e <myproc>
    800040d0:	5904                	lw	s1,48(a0)
    800040d2:	413484b3          	sub	s1,s1,s3
    800040d6:	0014b493          	seqz	s1,s1
    800040da:	bfe1                	j	800040b2 <holdingsleep+0x20>

00000000800040dc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800040dc:	1141                	addi	sp,sp,-16
    800040de:	e406                	sd	ra,8(sp)
    800040e0:	e022                	sd	s0,0(sp)
    800040e2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800040e4:	00003597          	auipc	a1,0x3
    800040e8:	5e458593          	addi	a1,a1,1508 # 800076c8 <syscalls+0x278>
    800040ec:	0023c517          	auipc	a0,0x23c
    800040f0:	df450513          	addi	a0,a0,-524 # 8023fee0 <ftable>
    800040f4:	af5fc0ef          	jal	ra,80000be8 <initlock>
}
    800040f8:	60a2                	ld	ra,8(sp)
    800040fa:	6402                	ld	s0,0(sp)
    800040fc:	0141                	addi	sp,sp,16
    800040fe:	8082                	ret

0000000080004100 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004100:	1101                	addi	sp,sp,-32
    80004102:	ec06                	sd	ra,24(sp)
    80004104:	e822                	sd	s0,16(sp)
    80004106:	e426                	sd	s1,8(sp)
    80004108:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000410a:	0023c517          	auipc	a0,0x23c
    8000410e:	dd650513          	addi	a0,a0,-554 # 8023fee0 <ftable>
    80004112:	b57fc0ef          	jal	ra,80000c68 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004116:	0023c497          	auipc	s1,0x23c
    8000411a:	de248493          	addi	s1,s1,-542 # 8023fef8 <ftable+0x18>
    8000411e:	0023d717          	auipc	a4,0x23d
    80004122:	d7a70713          	addi	a4,a4,-646 # 80240e98 <disk>
    if(f->ref == 0){
    80004126:	40dc                	lw	a5,4(s1)
    80004128:	cf89                	beqz	a5,80004142 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000412a:	02848493          	addi	s1,s1,40
    8000412e:	fee49ce3          	bne	s1,a4,80004126 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004132:	0023c517          	auipc	a0,0x23c
    80004136:	dae50513          	addi	a0,a0,-594 # 8023fee0 <ftable>
    8000413a:	bc7fc0ef          	jal	ra,80000d00 <release>
  return 0;
    8000413e:	4481                	li	s1,0
    80004140:	a809                	j	80004152 <filealloc+0x52>
      f->ref = 1;
    80004142:	4785                	li	a5,1
    80004144:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004146:	0023c517          	auipc	a0,0x23c
    8000414a:	d9a50513          	addi	a0,a0,-614 # 8023fee0 <ftable>
    8000414e:	bb3fc0ef          	jal	ra,80000d00 <release>
}
    80004152:	8526                	mv	a0,s1
    80004154:	60e2                	ld	ra,24(sp)
    80004156:	6442                	ld	s0,16(sp)
    80004158:	64a2                	ld	s1,8(sp)
    8000415a:	6105                	addi	sp,sp,32
    8000415c:	8082                	ret

000000008000415e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	1000                	addi	s0,sp,32
    80004168:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000416a:	0023c517          	auipc	a0,0x23c
    8000416e:	d7650513          	addi	a0,a0,-650 # 8023fee0 <ftable>
    80004172:	af7fc0ef          	jal	ra,80000c68 <acquire>
  if(f->ref < 1)
    80004176:	40dc                	lw	a5,4(s1)
    80004178:	02f05063          	blez	a5,80004198 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000417c:	2785                	addiw	a5,a5,1
    8000417e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004180:	0023c517          	auipc	a0,0x23c
    80004184:	d6050513          	addi	a0,a0,-672 # 8023fee0 <ftable>
    80004188:	b79fc0ef          	jal	ra,80000d00 <release>
  return f;
}
    8000418c:	8526                	mv	a0,s1
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret
    panic("filedup");
    80004198:	00003517          	auipc	a0,0x3
    8000419c:	53850513          	addi	a0,a0,1336 # 800076d0 <syscalls+0x280>
    800041a0:	dcafc0ef          	jal	ra,8000076a <panic>

00000000800041a4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800041a4:	7139                	addi	sp,sp,-64
    800041a6:	fc06                	sd	ra,56(sp)
    800041a8:	f822                	sd	s0,48(sp)
    800041aa:	f426                	sd	s1,40(sp)
    800041ac:	f04a                	sd	s2,32(sp)
    800041ae:	ec4e                	sd	s3,24(sp)
    800041b0:	e852                	sd	s4,16(sp)
    800041b2:	e456                	sd	s5,8(sp)
    800041b4:	0080                	addi	s0,sp,64
    800041b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800041b8:	0023c517          	auipc	a0,0x23c
    800041bc:	d2850513          	addi	a0,a0,-728 # 8023fee0 <ftable>
    800041c0:	aa9fc0ef          	jal	ra,80000c68 <acquire>
  if(f->ref < 1)
    800041c4:	40dc                	lw	a5,4(s1)
    800041c6:	04f05963          	blez	a5,80004218 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){
    800041ca:	37fd                	addiw	a5,a5,-1
    800041cc:	0007871b          	sext.w	a4,a5
    800041d0:	c0dc                	sw	a5,4(s1)
    800041d2:	04e04963          	bgtz	a4,80004224 <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800041d6:	0004a903          	lw	s2,0(s1)
    800041da:	0094ca83          	lbu	s5,9(s1)
    800041de:	0104ba03          	ld	s4,16(s1)
    800041e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800041e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800041ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800041ee:	0023c517          	auipc	a0,0x23c
    800041f2:	cf250513          	addi	a0,a0,-782 # 8023fee0 <ftable>
    800041f6:	b0bfc0ef          	jal	ra,80000d00 <release>

  if(ff.type == FD_PIPE){
    800041fa:	4785                	li	a5,1
    800041fc:	04f90363          	beq	s2,a5,80004242 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004200:	3979                	addiw	s2,s2,-2
    80004202:	4785                	li	a5,1
    80004204:	0327e663          	bltu	a5,s2,80004230 <fileclose+0x8c>
    begin_op();
    80004208:	b8fff0ef          	jal	ra,80003d96 <begin_op>
    iput(ff.ip);
    8000420c:	854e                	mv	a0,s3
    8000420e:	b28ff0ef          	jal	ra,80003536 <iput>
    end_op();
    80004212:	bf5ff0ef          	jal	ra,80003e06 <end_op>
    80004216:	a829                	j	80004230 <fileclose+0x8c>
    panic("fileclose");
    80004218:	00003517          	auipc	a0,0x3
    8000421c:	4c050513          	addi	a0,a0,1216 # 800076d8 <syscalls+0x288>
    80004220:	d4afc0ef          	jal	ra,8000076a <panic>
    release(&ftable.lock);
    80004224:	0023c517          	auipc	a0,0x23c
    80004228:	cbc50513          	addi	a0,a0,-836 # 8023fee0 <ftable>
    8000422c:	ad5fc0ef          	jal	ra,80000d00 <release>
  }
}
    80004230:	70e2                	ld	ra,56(sp)
    80004232:	7442                	ld	s0,48(sp)
    80004234:	74a2                	ld	s1,40(sp)
    80004236:	7902                	ld	s2,32(sp)
    80004238:	69e2                	ld	s3,24(sp)
    8000423a:	6a42                	ld	s4,16(sp)
    8000423c:	6aa2                	ld	s5,8(sp)
    8000423e:	6121                	addi	sp,sp,64
    80004240:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004242:	85d6                	mv	a1,s5
    80004244:	8552                	mv	a0,s4
    80004246:	2ec000ef          	jal	ra,80004532 <pipeclose>
    8000424a:	b7dd                	j	80004230 <fileclose+0x8c>

000000008000424c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000424c:	715d                	addi	sp,sp,-80
    8000424e:	e486                	sd	ra,72(sp)
    80004250:	e0a2                	sd	s0,64(sp)
    80004252:	fc26                	sd	s1,56(sp)
    80004254:	f84a                	sd	s2,48(sp)
    80004256:	f44e                	sd	s3,40(sp)
    80004258:	0880                	addi	s0,sp,80
    8000425a:	84aa                	mv	s1,a0
    8000425c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000425e:	f00fd0ef          	jal	ra,8000195e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004262:	409c                	lw	a5,0(s1)
    80004264:	37f9                	addiw	a5,a5,-2
    80004266:	4705                	li	a4,1
    80004268:	02f76f63          	bltu	a4,a5,800042a6 <filestat+0x5a>
    8000426c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000426e:	6c88                	ld	a0,24(s1)
    80004270:	948ff0ef          	jal	ra,800033b8 <ilock>
    stati(f->ip, &st);
    80004274:	fb840593          	addi	a1,s0,-72
    80004278:	6c88                	ld	a0,24(s1)
    8000427a:	ca0ff0ef          	jal	ra,8000371a <stati>
    iunlock(f->ip);
    8000427e:	6c88                	ld	a0,24(s1)
    80004280:	9e2ff0ef          	jal	ra,80003462 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004284:	46e1                	li	a3,24
    80004286:	fb840613          	addi	a2,s0,-72
    8000428a:	85ce                	mv	a1,s3
    8000428c:	05093503          	ld	a0,80(s2)
    80004290:	bfcfd0ef          	jal	ra,8000168c <copyout>
    80004294:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004298:	60a6                	ld	ra,72(sp)
    8000429a:	6406                	ld	s0,64(sp)
    8000429c:	74e2                	ld	s1,56(sp)
    8000429e:	7942                	ld	s2,48(sp)
    800042a0:	79a2                	ld	s3,40(sp)
    800042a2:	6161                	addi	sp,sp,80
    800042a4:	8082                	ret
  return -1;
    800042a6:	557d                	li	a0,-1
    800042a8:	bfc5                	j	80004298 <filestat+0x4c>

00000000800042aa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800042aa:	7179                	addi	sp,sp,-48
    800042ac:	f406                	sd	ra,40(sp)
    800042ae:	f022                	sd	s0,32(sp)
    800042b0:	ec26                	sd	s1,24(sp)
    800042b2:	e84a                	sd	s2,16(sp)
    800042b4:	e44e                	sd	s3,8(sp)
    800042b6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800042b8:	00854783          	lbu	a5,8(a0)
    800042bc:	cbc1                	beqz	a5,8000434c <fileread+0xa2>
    800042be:	84aa                	mv	s1,a0
    800042c0:	89ae                	mv	s3,a1
    800042c2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800042c4:	411c                	lw	a5,0(a0)
    800042c6:	4705                	li	a4,1
    800042c8:	04e78363          	beq	a5,a4,8000430e <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800042cc:	470d                	li	a4,3
    800042ce:	04e78563          	beq	a5,a4,80004318 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800042d2:	4709                	li	a4,2
    800042d4:	06e79663          	bne	a5,a4,80004340 <fileread+0x96>
    ilock(f->ip);
    800042d8:	6d08                	ld	a0,24(a0)
    800042da:	8deff0ef          	jal	ra,800033b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800042de:	874a                	mv	a4,s2
    800042e0:	5094                	lw	a3,32(s1)
    800042e2:	864e                	mv	a2,s3
    800042e4:	4585                	li	a1,1
    800042e6:	6c88                	ld	a0,24(s1)
    800042e8:	c5cff0ef          	jal	ra,80003744 <readi>
    800042ec:	892a                	mv	s2,a0
    800042ee:	00a05563          	blez	a0,800042f8 <fileread+0x4e>
      f->off += r;
    800042f2:	509c                	lw	a5,32(s1)
    800042f4:	9fa9                	addw	a5,a5,a0
    800042f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800042f8:	6c88                	ld	a0,24(s1)
    800042fa:	968ff0ef          	jal	ra,80003462 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800042fe:	854a                	mv	a0,s2
    80004300:	70a2                	ld	ra,40(sp)
    80004302:	7402                	ld	s0,32(sp)
    80004304:	64e2                	ld	s1,24(sp)
    80004306:	6942                	ld	s2,16(sp)
    80004308:	69a2                	ld	s3,8(sp)
    8000430a:	6145                	addi	sp,sp,48
    8000430c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000430e:	6908                	ld	a0,16(a0)
    80004310:	34e000ef          	jal	ra,8000465e <piperead>
    80004314:	892a                	mv	s2,a0
    80004316:	b7e5                	j	800042fe <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004318:	02451783          	lh	a5,36(a0)
    8000431c:	03079693          	slli	a3,a5,0x30
    80004320:	92c1                	srli	a3,a3,0x30
    80004322:	4725                	li	a4,9
    80004324:	02d76663          	bltu	a4,a3,80004350 <fileread+0xa6>
    80004328:	0792                	slli	a5,a5,0x4
    8000432a:	0023c717          	auipc	a4,0x23c
    8000432e:	b1670713          	addi	a4,a4,-1258 # 8023fe40 <devsw>
    80004332:	97ba                	add	a5,a5,a4
    80004334:	639c                	ld	a5,0(a5)
    80004336:	cf99                	beqz	a5,80004354 <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);
    80004338:	4505                	li	a0,1
    8000433a:	9782                	jalr	a5
    8000433c:	892a                	mv	s2,a0
    8000433e:	b7c1                	j	800042fe <fileread+0x54>
    panic("fileread");
    80004340:	00003517          	auipc	a0,0x3
    80004344:	3a850513          	addi	a0,a0,936 # 800076e8 <syscalls+0x298>
    80004348:	c22fc0ef          	jal	ra,8000076a <panic>
    return -1;
    8000434c:	597d                	li	s2,-1
    8000434e:	bf45                	j	800042fe <fileread+0x54>
      return -1;
    80004350:	597d                	li	s2,-1
    80004352:	b775                	j	800042fe <fileread+0x54>
    80004354:	597d                	li	s2,-1
    80004356:	b765                	j	800042fe <fileread+0x54>

0000000080004358 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004358:	715d                	addi	sp,sp,-80
    8000435a:	e486                	sd	ra,72(sp)
    8000435c:	e0a2                	sd	s0,64(sp)
    8000435e:	fc26                	sd	s1,56(sp)
    80004360:	f84a                	sd	s2,48(sp)
    80004362:	f44e                	sd	s3,40(sp)
    80004364:	f052                	sd	s4,32(sp)
    80004366:	ec56                	sd	s5,24(sp)
    80004368:	e85a                	sd	s6,16(sp)
    8000436a:	e45e                	sd	s7,8(sp)
    8000436c:	e062                	sd	s8,0(sp)
    8000436e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004370:	00954783          	lbu	a5,9(a0)
    80004374:	0e078863          	beqz	a5,80004464 <filewrite+0x10c>
    80004378:	892a                	mv	s2,a0
    8000437a:	8aae                	mv	s5,a1
    8000437c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000437e:	411c                	lw	a5,0(a0)
    80004380:	4705                	li	a4,1
    80004382:	02e78263          	beq	a5,a4,800043a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004386:	470d                	li	a4,3
    80004388:	02e78463          	beq	a5,a4,800043b0 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000438c:	4709                	li	a4,2
    8000438e:	0ce79563          	bne	a5,a4,80004458 <filewrite+0x100>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004392:	0ac05163          	blez	a2,80004434 <filewrite+0xdc>
    int i = 0;
    80004396:	4981                	li	s3,0
    80004398:	6b05                	lui	s6,0x1
    8000439a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000439e:	6b85                	lui	s7,0x1
    800043a0:	c00b8b9b          	addiw	s7,s7,-1024
    800043a4:	a041                	j	80004424 <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);
    800043a6:	6908                	ld	a0,16(a0)
    800043a8:	1e2000ef          	jal	ra,8000458a <pipewrite>
    800043ac:	8a2a                	mv	s4,a0
    800043ae:	a071                	j	8000443a <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800043b0:	02451783          	lh	a5,36(a0)
    800043b4:	03079693          	slli	a3,a5,0x30
    800043b8:	92c1                	srli	a3,a3,0x30
    800043ba:	4725                	li	a4,9
    800043bc:	0ad76663          	bltu	a4,a3,80004468 <filewrite+0x110>
    800043c0:	0792                	slli	a5,a5,0x4
    800043c2:	0023c717          	auipc	a4,0x23c
    800043c6:	a7e70713          	addi	a4,a4,-1410 # 8023fe40 <devsw>
    800043ca:	97ba                	add	a5,a5,a4
    800043cc:	679c                	ld	a5,8(a5)
    800043ce:	cfd9                	beqz	a5,8000446c <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);
    800043d0:	4505                	li	a0,1
    800043d2:	9782                	jalr	a5
    800043d4:	8a2a                	mv	s4,a0
    800043d6:	a095                	j	8000443a <filewrite+0xe2>
    800043d8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800043dc:	9bbff0ef          	jal	ra,80003d96 <begin_op>
      ilock(f->ip);
    800043e0:	01893503          	ld	a0,24(s2)
    800043e4:	fd5fe0ef          	jal	ra,800033b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800043e8:	8762                	mv	a4,s8
    800043ea:	02092683          	lw	a3,32(s2)
    800043ee:	01598633          	add	a2,s3,s5
    800043f2:	4585                	li	a1,1
    800043f4:	01893503          	ld	a0,24(s2)
    800043f8:	c30ff0ef          	jal	ra,80003828 <writei>
    800043fc:	84aa                	mv	s1,a0
    800043fe:	00a05763          	blez	a0,8000440c <filewrite+0xb4>
        f->off += r;
    80004402:	02092783          	lw	a5,32(s2)
    80004406:	9fa9                	addw	a5,a5,a0
    80004408:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000440c:	01893503          	ld	a0,24(s2)
    80004410:	852ff0ef          	jal	ra,80003462 <iunlock>
      end_op();
    80004414:	9f3ff0ef          	jal	ra,80003e06 <end_op>

      if(r != n1){
    80004418:	009c1f63          	bne	s8,s1,80004436 <filewrite+0xde>
        // error from writei
        break;
      }
      i += r;
    8000441c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004420:	0149db63          	bge	s3,s4,80004436 <filewrite+0xde>
      int n1 = n - i;
    80004424:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004428:	84be                	mv	s1,a5
    8000442a:	2781                	sext.w	a5,a5
    8000442c:	fafb56e3          	bge	s6,a5,800043d8 <filewrite+0x80>
    80004430:	84de                	mv	s1,s7
    80004432:	b75d                	j	800043d8 <filewrite+0x80>
    int i = 0;
    80004434:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004436:	013a1f63          	bne	s4,s3,80004454 <filewrite+0xfc>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000443a:	8552                	mv	a0,s4
    8000443c:	60a6                	ld	ra,72(sp)
    8000443e:	6406                	ld	s0,64(sp)
    80004440:	74e2                	ld	s1,56(sp)
    80004442:	7942                	ld	s2,48(sp)
    80004444:	79a2                	ld	s3,40(sp)
    80004446:	7a02                	ld	s4,32(sp)
    80004448:	6ae2                	ld	s5,24(sp)
    8000444a:	6b42                	ld	s6,16(sp)
    8000444c:	6ba2                	ld	s7,8(sp)
    8000444e:	6c02                	ld	s8,0(sp)
    80004450:	6161                	addi	sp,sp,80
    80004452:	8082                	ret
    ret = (i == n ? n : -1);
    80004454:	5a7d                	li	s4,-1
    80004456:	b7d5                	j	8000443a <filewrite+0xe2>
    panic("filewrite");
    80004458:	00003517          	auipc	a0,0x3
    8000445c:	2a050513          	addi	a0,a0,672 # 800076f8 <syscalls+0x2a8>
    80004460:	b0afc0ef          	jal	ra,8000076a <panic>
    return -1;
    80004464:	5a7d                	li	s4,-1
    80004466:	bfd1                	j	8000443a <filewrite+0xe2>
      return -1;
    80004468:	5a7d                	li	s4,-1
    8000446a:	bfc1                	j	8000443a <filewrite+0xe2>
    8000446c:	5a7d                	li	s4,-1
    8000446e:	b7f1                	j	8000443a <filewrite+0xe2>

0000000080004470 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004470:	7179                	addi	sp,sp,-48
    80004472:	f406                	sd	ra,40(sp)
    80004474:	f022                	sd	s0,32(sp)
    80004476:	ec26                	sd	s1,24(sp)
    80004478:	e84a                	sd	s2,16(sp)
    8000447a:	e44e                	sd	s3,8(sp)
    8000447c:	e052                	sd	s4,0(sp)
    8000447e:	1800                	addi	s0,sp,48
    80004480:	84aa                	mv	s1,a0
    80004482:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004484:	0005b023          	sd	zero,0(a1)
    80004488:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000448c:	c75ff0ef          	jal	ra,80004100 <filealloc>
    80004490:	e088                	sd	a0,0(s1)
    80004492:	cd35                	beqz	a0,8000450e <pipealloc+0x9e>
    80004494:	c6dff0ef          	jal	ra,80004100 <filealloc>
    80004498:	00aa3023          	sd	a0,0(s4)
    8000449c:	c52d                	beqz	a0,80004506 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000449e:	e62fc0ef          	jal	ra,80000b00 <kalloc>
    800044a2:	892a                	mv	s2,a0
    800044a4:	cd31                	beqz	a0,80004500 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800044a6:	4985                	li	s3,1
    800044a8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800044ac:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800044b0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800044b4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800044b8:	00003597          	auipc	a1,0x3
    800044bc:	25058593          	addi	a1,a1,592 # 80007708 <syscalls+0x2b8>
    800044c0:	f28fc0ef          	jal	ra,80000be8 <initlock>
  (*f0)->type = FD_PIPE;
    800044c4:	609c                	ld	a5,0(s1)
    800044c6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800044ca:	609c                	ld	a5,0(s1)
    800044cc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800044d0:	609c                	ld	a5,0(s1)
    800044d2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800044d6:	609c                	ld	a5,0(s1)
    800044d8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800044dc:	000a3783          	ld	a5,0(s4)
    800044e0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800044e4:	000a3783          	ld	a5,0(s4)
    800044e8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800044ec:	000a3783          	ld	a5,0(s4)
    800044f0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800044f4:	000a3783          	ld	a5,0(s4)
    800044f8:	0127b823          	sd	s2,16(a5)
  return 0;
    800044fc:	4501                	li	a0,0
    800044fe:	a005                	j	8000451e <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004500:	6088                	ld	a0,0(s1)
    80004502:	e501                	bnez	a0,8000450a <pipealloc+0x9a>
    80004504:	a029                	j	8000450e <pipealloc+0x9e>
    80004506:	6088                	ld	a0,0(s1)
    80004508:	c11d                	beqz	a0,8000452e <pipealloc+0xbe>
    fileclose(*f0);
    8000450a:	c9bff0ef          	jal	ra,800041a4 <fileclose>
  if(*f1)
    8000450e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004512:	557d                	li	a0,-1
  if(*f1)
    80004514:	c789                	beqz	a5,8000451e <pipealloc+0xae>
    fileclose(*f1);
    80004516:	853e                	mv	a0,a5
    80004518:	c8dff0ef          	jal	ra,800041a4 <fileclose>
  return -1;
    8000451c:	557d                	li	a0,-1
}
    8000451e:	70a2                	ld	ra,40(sp)
    80004520:	7402                	ld	s0,32(sp)
    80004522:	64e2                	ld	s1,24(sp)
    80004524:	6942                	ld	s2,16(sp)
    80004526:	69a2                	ld	s3,8(sp)
    80004528:	6a02                	ld	s4,0(sp)
    8000452a:	6145                	addi	sp,sp,48
    8000452c:	8082                	ret
  return -1;
    8000452e:	557d                	li	a0,-1
    80004530:	b7fd                	j	8000451e <pipealloc+0xae>

0000000080004532 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
    80004540:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004542:	f26fc0ef          	jal	ra,80000c68 <acquire>
  if(writable){
    80004546:	02090763          	beqz	s2,80004574 <pipeclose+0x42>
    pi->writeopen = 0;
    8000454a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000454e:	21848513          	addi	a0,s1,536
    80004552:	badfd0ef          	jal	ra,800020fe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004556:	2204b783          	ld	a5,544(s1)
    8000455a:	e785                	bnez	a5,80004582 <pipeclose+0x50>
    release(&pi->lock);
    8000455c:	8526                	mv	a0,s1
    8000455e:	fa2fc0ef          	jal	ra,80000d00 <release>
    kfree((char*)pi);
    80004562:	8526                	mv	a0,s1
    80004564:	c38fc0ef          	jal	ra,8000099c <kfree>
  } else
    release(&pi->lock);
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6902                	ld	s2,0(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret
    pi->readopen = 0;
    80004574:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004578:	21c48513          	addi	a0,s1,540
    8000457c:	b83fd0ef          	jal	ra,800020fe <wakeup>
    80004580:	bfd9                	j	80004556 <pipeclose+0x24>
    release(&pi->lock);
    80004582:	8526                	mv	a0,s1
    80004584:	f7cfc0ef          	jal	ra,80000d00 <release>
}
    80004588:	b7c5                	j	80004568 <pipeclose+0x36>

000000008000458a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000458a:	711d                	addi	sp,sp,-96
    8000458c:	ec86                	sd	ra,88(sp)
    8000458e:	e8a2                	sd	s0,80(sp)
    80004590:	e4a6                	sd	s1,72(sp)
    80004592:	e0ca                	sd	s2,64(sp)
    80004594:	fc4e                	sd	s3,56(sp)
    80004596:	f852                	sd	s4,48(sp)
    80004598:	f456                	sd	s5,40(sp)
    8000459a:	f05a                	sd	s6,32(sp)
    8000459c:	ec5e                	sd	s7,24(sp)
    8000459e:	e862                	sd	s8,16(sp)
    800045a0:	1080                	addi	s0,sp,96
    800045a2:	84aa                	mv	s1,a0
    800045a4:	8aae                	mv	s5,a1
    800045a6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800045a8:	bb6fd0ef          	jal	ra,8000195e <myproc>
    800045ac:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800045ae:	8526                	mv	a0,s1
    800045b0:	eb8fc0ef          	jal	ra,80000c68 <acquire>
  while(i < n){
    800045b4:	09405c63          	blez	s4,8000464c <pipewrite+0xc2>
  int i = 0;
    800045b8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800045ba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800045bc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800045c0:	21c48b93          	addi	s7,s1,540
    800045c4:	a81d                	j	800045fa <pipewrite+0x70>
      release(&pi->lock);
    800045c6:	8526                	mv	a0,s1
    800045c8:	f38fc0ef          	jal	ra,80000d00 <release>
      return -1;
    800045cc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800045ce:	854a                	mv	a0,s2
    800045d0:	60e6                	ld	ra,88(sp)
    800045d2:	6446                	ld	s0,80(sp)
    800045d4:	64a6                	ld	s1,72(sp)
    800045d6:	6906                	ld	s2,64(sp)
    800045d8:	79e2                	ld	s3,56(sp)
    800045da:	7a42                	ld	s4,48(sp)
    800045dc:	7aa2                	ld	s5,40(sp)
    800045de:	7b02                	ld	s6,32(sp)
    800045e0:	6be2                	ld	s7,24(sp)
    800045e2:	6c42                	ld	s8,16(sp)
    800045e4:	6125                	addi	sp,sp,96
    800045e6:	8082                	ret
      wakeup(&pi->nread);
    800045e8:	8562                	mv	a0,s8
    800045ea:	b15fd0ef          	jal	ra,800020fe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800045ee:	85a6                	mv	a1,s1
    800045f0:	855e                	mv	a0,s7
    800045f2:	ac1fd0ef          	jal	ra,800020b2 <sleep>
  while(i < n){
    800045f6:	05495c63          	bge	s2,s4,8000464e <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    800045fa:	2204a783          	lw	a5,544(s1)
    800045fe:	d7e1                	beqz	a5,800045c6 <pipewrite+0x3c>
    80004600:	854e                	mv	a0,s3
    80004602:	ce9fd0ef          	jal	ra,800022ea <killed>
    80004606:	f161                	bnez	a0,800045c6 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004608:	2184a783          	lw	a5,536(s1)
    8000460c:	21c4a703          	lw	a4,540(s1)
    80004610:	2007879b          	addiw	a5,a5,512
    80004614:	fcf70ae3          	beq	a4,a5,800045e8 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004618:	4685                	li	a3,1
    8000461a:	01590633          	add	a2,s2,s5
    8000461e:	faf40593          	addi	a1,s0,-81
    80004622:	0509b503          	ld	a0,80(s3)
    80004626:	92cfd0ef          	jal	ra,80001752 <copyin>
    8000462a:	03650263          	beq	a0,s6,8000464e <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000462e:	21c4a783          	lw	a5,540(s1)
    80004632:	0017871b          	addiw	a4,a5,1
    80004636:	20e4ae23          	sw	a4,540(s1)
    8000463a:	1ff7f793          	andi	a5,a5,511
    8000463e:	97a6                	add	a5,a5,s1
    80004640:	faf44703          	lbu	a4,-81(s0)
    80004644:	00e78c23          	sb	a4,24(a5)
      i++;
    80004648:	2905                	addiw	s2,s2,1
    8000464a:	b775                	j	800045f6 <pipewrite+0x6c>
  int i = 0;
    8000464c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000464e:	21848513          	addi	a0,s1,536
    80004652:	aadfd0ef          	jal	ra,800020fe <wakeup>
  release(&pi->lock);
    80004656:	8526                	mv	a0,s1
    80004658:	ea8fc0ef          	jal	ra,80000d00 <release>
  return i;
    8000465c:	bf8d                	j	800045ce <pipewrite+0x44>

000000008000465e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000465e:	715d                	addi	sp,sp,-80
    80004660:	e486                	sd	ra,72(sp)
    80004662:	e0a2                	sd	s0,64(sp)
    80004664:	fc26                	sd	s1,56(sp)
    80004666:	f84a                	sd	s2,48(sp)
    80004668:	f44e                	sd	s3,40(sp)
    8000466a:	f052                	sd	s4,32(sp)
    8000466c:	ec56                	sd	s5,24(sp)
    8000466e:	e85a                	sd	s6,16(sp)
    80004670:	0880                	addi	s0,sp,80
    80004672:	84aa                	mv	s1,a0
    80004674:	892e                	mv	s2,a1
    80004676:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004678:	ae6fd0ef          	jal	ra,8000195e <myproc>
    8000467c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000467e:	8526                	mv	a0,s1
    80004680:	de8fc0ef          	jal	ra,80000c68 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004684:	2184a703          	lw	a4,536(s1)
    80004688:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000468c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004690:	02f71363          	bne	a4,a5,800046b6 <piperead+0x58>
    80004694:	2244a783          	lw	a5,548(s1)
    80004698:	cf99                	beqz	a5,800046b6 <piperead+0x58>
    if(killed(pr)){
    8000469a:	8552                	mv	a0,s4
    8000469c:	c4ffd0ef          	jal	ra,800022ea <killed>
    800046a0:	e149                	bnez	a0,80004722 <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800046a2:	85a6                	mv	a1,s1
    800046a4:	854e                	mv	a0,s3
    800046a6:	a0dfd0ef          	jal	ra,800020b2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800046aa:	2184a703          	lw	a4,536(s1)
    800046ae:	21c4a783          	lw	a5,540(s1)
    800046b2:	fef701e3          	beq	a4,a5,80004694 <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046b6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046b8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046ba:	05505263          	blez	s5,800046fe <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800046be:	2184a783          	lw	a5,536(s1)
    800046c2:	21c4a703          	lw	a4,540(s1)
    800046c6:	02f70c63          	beq	a4,a5,800046fe <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    800046ca:	1ff7f793          	andi	a5,a5,511
    800046ce:	97a6                	add	a5,a5,s1
    800046d0:	0187c783          	lbu	a5,24(a5)
    800046d4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046d8:	4685                	li	a3,1
    800046da:	fbf40613          	addi	a2,s0,-65
    800046de:	85ca                	mv	a1,s2
    800046e0:	050a3503          	ld	a0,80(s4)
    800046e4:	fa9fc0ef          	jal	ra,8000168c <copyout>
    800046e8:	05650263          	beq	a0,s6,8000472c <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800046ec:	2184a783          	lw	a5,536(s1)
    800046f0:	2785                	addiw	a5,a5,1
    800046f2:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046f6:	2985                	addiw	s3,s3,1
    800046f8:	0905                	addi	s2,s2,1
    800046fa:	fd3a92e3          	bne	s5,s3,800046be <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800046fe:	21c48513          	addi	a0,s1,540
    80004702:	9fdfd0ef          	jal	ra,800020fe <wakeup>
  release(&pi->lock);
    80004706:	8526                	mv	a0,s1
    80004708:	df8fc0ef          	jal	ra,80000d00 <release>
  return i;
}
    8000470c:	854e                	mv	a0,s3
    8000470e:	60a6                	ld	ra,72(sp)
    80004710:	6406                	ld	s0,64(sp)
    80004712:	74e2                	ld	s1,56(sp)
    80004714:	7942                	ld	s2,48(sp)
    80004716:	79a2                	ld	s3,40(sp)
    80004718:	7a02                	ld	s4,32(sp)
    8000471a:	6ae2                	ld	s5,24(sp)
    8000471c:	6b42                	ld	s6,16(sp)
    8000471e:	6161                	addi	sp,sp,80
    80004720:	8082                	ret
      release(&pi->lock);
    80004722:	8526                	mv	a0,s1
    80004724:	ddcfc0ef          	jal	ra,80000d00 <release>
      return -1;
    80004728:	59fd                	li	s3,-1
    8000472a:	b7cd                	j	8000470c <piperead+0xae>
      if(i == 0)
    8000472c:	fc0999e3          	bnez	s3,800046fe <piperead+0xa0>
        i = -1;
    80004730:	89aa                	mv	s3,a0
    80004732:	b7f1                	j	800046fe <piperead+0xa0>

0000000080004734 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004734:	1141                	addi	sp,sp,-16
    80004736:	e422                	sd	s0,8(sp)
    80004738:	0800                	addi	s0,sp,16
    8000473a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000473c:	8905                	andi	a0,a0,1
    8000473e:	c111                	beqz	a0,80004742 <flags2perm+0xe>
      perm = PTE_X;
    80004740:	4521                	li	a0,8
    if(flags & 0x2)
    80004742:	8b89                	andi	a5,a5,2
    80004744:	c399                	beqz	a5,8000474a <flags2perm+0x16>
      perm |= PTE_W;
    80004746:	00456513          	ori	a0,a0,4
    return perm;
}
    8000474a:	6422                	ld	s0,8(sp)
    8000474c:	0141                	addi	sp,sp,16
    8000474e:	8082                	ret

0000000080004750 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004750:	de010113          	addi	sp,sp,-544
    80004754:	20113c23          	sd	ra,536(sp)
    80004758:	20813823          	sd	s0,528(sp)
    8000475c:	20913423          	sd	s1,520(sp)
    80004760:	21213023          	sd	s2,512(sp)
    80004764:	ffce                	sd	s3,504(sp)
    80004766:	fbd2                	sd	s4,496(sp)
    80004768:	f7d6                	sd	s5,488(sp)
    8000476a:	f3da                	sd	s6,480(sp)
    8000476c:	efde                	sd	s7,472(sp)
    8000476e:	ebe2                	sd	s8,464(sp)
    80004770:	e7e6                	sd	s9,456(sp)
    80004772:	e3ea                	sd	s10,448(sp)
    80004774:	ff6e                	sd	s11,440(sp)
    80004776:	1400                	addi	s0,sp,544
    80004778:	892a                	mv	s2,a0
    8000477a:	dea43423          	sd	a0,-536(s0)
    8000477e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004782:	9dcfd0ef          	jal	ra,8000195e <myproc>
    80004786:	84aa                	mv	s1,a0

  begin_op();
    80004788:	e0eff0ef          	jal	ra,80003d96 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    8000478c:	854a                	mv	a0,s2
    8000478e:	c18ff0ef          	jal	ra,80003ba6 <namei>
    80004792:	c13d                	beqz	a0,800047f8 <kexec+0xa8>
    80004794:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004796:	c23fe0ef          	jal	ra,800033b8 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000479a:	04000713          	li	a4,64
    8000479e:	4681                	li	a3,0
    800047a0:	e5040613          	addi	a2,s0,-432
    800047a4:	4581                	li	a1,0
    800047a6:	8556                	mv	a0,s5
    800047a8:	f9dfe0ef          	jal	ra,80003744 <readi>
    800047ac:	04000793          	li	a5,64
    800047b0:	00f51a63          	bne	a0,a5,800047c4 <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800047b4:	e5042703          	lw	a4,-432(s0)
    800047b8:	464c47b7          	lui	a5,0x464c4
    800047bc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800047c0:	04f70063          	beq	a4,a5,80004800 <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800047c4:	8556                	mv	a0,s5
    800047c6:	df9fe0ef          	jal	ra,800035be <iunlockput>
    end_op();
    800047ca:	e3cff0ef          	jal	ra,80003e06 <end_op>
  }
  return -1;
    800047ce:	557d                	li	a0,-1
}
    800047d0:	21813083          	ld	ra,536(sp)
    800047d4:	21013403          	ld	s0,528(sp)
    800047d8:	20813483          	ld	s1,520(sp)
    800047dc:	20013903          	ld	s2,512(sp)
    800047e0:	79fe                	ld	s3,504(sp)
    800047e2:	7a5e                	ld	s4,496(sp)
    800047e4:	7abe                	ld	s5,488(sp)
    800047e6:	7b1e                	ld	s6,480(sp)
    800047e8:	6bfe                	ld	s7,472(sp)
    800047ea:	6c5e                	ld	s8,464(sp)
    800047ec:	6cbe                	ld	s9,456(sp)
    800047ee:	6d1e                	ld	s10,448(sp)
    800047f0:	7dfa                	ld	s11,440(sp)
    800047f2:	22010113          	addi	sp,sp,544
    800047f6:	8082                	ret
    end_op();
    800047f8:	e0eff0ef          	jal	ra,80003e06 <end_op>
    return -1;
    800047fc:	557d                	li	a0,-1
    800047fe:	bfc9                	j	800047d0 <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004800:	8526                	mv	a0,s1
    80004802:	a62fd0ef          	jal	ra,80001a64 <proc_pagetable>
    80004806:	8b2a                	mv	s6,a0
    80004808:	dd55                	beqz	a0,800047c4 <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000480a:	e7042783          	lw	a5,-400(s0)
    8000480e:	e8845703          	lhu	a4,-376(s0)
    80004812:	c325                	beqz	a4,80004872 <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004814:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004816:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000481a:	6a05                	lui	s4,0x1
    8000481c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004820:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004824:	6d85                	lui	s11,0x1
    80004826:	7d7d                	lui	s10,0xfffff
    80004828:	a411                	j	80004a2c <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000482a:	00003517          	auipc	a0,0x3
    8000482e:	ee650513          	addi	a0,a0,-282 # 80007710 <syscalls+0x2c0>
    80004832:	f39fb0ef          	jal	ra,8000076a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004836:	874a                	mv	a4,s2
    80004838:	009c86bb          	addw	a3,s9,s1
    8000483c:	4581                	li	a1,0
    8000483e:	8556                	mv	a0,s5
    80004840:	f05fe0ef          	jal	ra,80003744 <readi>
    80004844:	2501                	sext.w	a0,a0
    80004846:	18a91263          	bne	s2,a0,800049ca <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    8000484a:	009d84bb          	addw	s1,s11,s1
    8000484e:	013d09bb          	addw	s3,s10,s3
    80004852:	1b74fd63          	bgeu	s1,s7,80004a0c <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004856:	02049593          	slli	a1,s1,0x20
    8000485a:	9181                	srli	a1,a1,0x20
    8000485c:	95e2                	add	a1,a1,s8
    8000485e:	855a                	mv	a0,s6
    80004860:	ff2fc0ef          	jal	ra,80001052 <walkaddr>
    80004864:	862a                	mv	a2,a0
    if(pa == 0)
    80004866:	d171                	beqz	a0,8000482a <kexec+0xda>
      n = PGSIZE;
    80004868:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000486a:	fd49f6e3          	bgeu	s3,s4,80004836 <kexec+0xe6>
      n = sz - i;
    8000486e:	894e                	mv	s2,s3
    80004870:	b7d9                	j	80004836 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004872:	4901                	li	s2,0
  iunlockput(ip);
    80004874:	8556                	mv	a0,s5
    80004876:	d49fe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    8000487a:	d8cff0ef          	jal	ra,80003e06 <end_op>
  p = myproc();
    8000487e:	8e0fd0ef          	jal	ra,8000195e <myproc>
    80004882:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004884:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004888:	6785                	lui	a5,0x1
    8000488a:	17fd                	addi	a5,a5,-1
    8000488c:	993e                	add	s2,s2,a5
    8000488e:	77fd                	lui	a5,0xfffff
    80004890:	00f977b3          	and	a5,s2,a5
    80004894:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004898:	4691                	li	a3,4
    8000489a:	6609                	lui	a2,0x2
    8000489c:	963e                	add	a2,a2,a5
    8000489e:	85be                	mv	a1,a5
    800048a0:	855a                	mv	a0,s6
    800048a2:	a7bfc0ef          	jal	ra,8000131c <uvmalloc>
    800048a6:	8c2a                	mv	s8,a0
  ip = 0;
    800048a8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800048aa:	12050063          	beqz	a0,800049ca <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800048ae:	75f9                	lui	a1,0xffffe
    800048b0:	95aa                	add	a1,a1,a0
    800048b2:	855a                	mv	a0,s6
    800048b4:	c23fc0ef          	jal	ra,800014d6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048b8:	7afd                	lui	s5,0xfffff
    800048ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800048bc:	df043783          	ld	a5,-528(s0)
    800048c0:	6388                	ld	a0,0(a5)
    800048c2:	c135                	beqz	a0,80004926 <kexec+0x1d6>
    800048c4:	e9040993          	addi	s3,s0,-368
    800048c8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800048cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800048ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800048d0:	de4fc0ef          	jal	ra,80000eb4 <strlen>
    800048d4:	0015079b          	addiw	a5,a0,1
    800048d8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800048dc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800048e0:	11596a63          	bltu	s2,s5,800049f4 <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800048e4:	df043d83          	ld	s11,-528(s0)
    800048e8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800048ec:	8552                	mv	a0,s4
    800048ee:	dc6fc0ef          	jal	ra,80000eb4 <strlen>
    800048f2:	0015069b          	addiw	a3,a0,1
    800048f6:	8652                	mv	a2,s4
    800048f8:	85ca                	mv	a1,s2
    800048fa:	855a                	mv	a0,s6
    800048fc:	d91fc0ef          	jal	ra,8000168c <copyout>
    80004900:	0e054e63          	bltz	a0,800049fc <kexec+0x2ac>
    ustack[argc] = sp;
    80004904:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004908:	0485                	addi	s1,s1,1
    8000490a:	008d8793          	addi	a5,s11,8
    8000490e:	def43823          	sd	a5,-528(s0)
    80004912:	008db503          	ld	a0,8(s11)
    80004916:	c911                	beqz	a0,8000492a <kexec+0x1da>
    if(argc >= MAXARG)
    80004918:	09a1                	addi	s3,s3,8
    8000491a:	fb3c9be3          	bne	s9,s3,800048d0 <kexec+0x180>
  sz = sz1;
    8000491e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004922:	4a81                	li	s5,0
    80004924:	a05d                	j	800049ca <kexec+0x27a>
  sp = sz;
    80004926:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004928:	4481                	li	s1,0
  ustack[argc] = 0;
    8000492a:	00349793          	slli	a5,s1,0x3
    8000492e:	f9040713          	addi	a4,s0,-112
    80004932:	97ba                	add	a5,a5,a4
    80004934:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbdf28>
  sp -= (argc+1) * sizeof(uint64);
    80004938:	00148693          	addi	a3,s1,1
    8000493c:	068e                	slli	a3,a3,0x3
    8000493e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004942:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004946:	01597663          	bgeu	s2,s5,80004952 <kexec+0x202>
  sz = sz1;
    8000494a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000494e:	4a81                	li	s5,0
    80004950:	a8ad                	j	800049ca <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004952:	e9040613          	addi	a2,s0,-368
    80004956:	85ca                	mv	a1,s2
    80004958:	855a                	mv	a0,s6
    8000495a:	d33fc0ef          	jal	ra,8000168c <copyout>
    8000495e:	0a054363          	bltz	a0,80004a04 <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004962:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004966:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000496a:	de843783          	ld	a5,-536(s0)
    8000496e:	0007c703          	lbu	a4,0(a5)
    80004972:	cf11                	beqz	a4,8000498e <kexec+0x23e>
    80004974:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004976:	02f00693          	li	a3,47
    8000497a:	a039                	j	80004988 <kexec+0x238>
      last = s+1;
    8000497c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004980:	0785                	addi	a5,a5,1
    80004982:	fff7c703          	lbu	a4,-1(a5)
    80004986:	c701                	beqz	a4,8000498e <kexec+0x23e>
    if(*s == '/')
    80004988:	fed71ce3          	bne	a4,a3,80004980 <kexec+0x230>
    8000498c:	bfc5                	j	8000497c <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000498e:	4641                	li	a2,16
    80004990:	de843583          	ld	a1,-536(s0)
    80004994:	158b8513          	addi	a0,s7,344
    80004998:	ceafc0ef          	jal	ra,80000e82 <safestrcpy>
  oldpagetable = p->pagetable;
    8000499c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800049a0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800049a4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800049a8:	058bb783          	ld	a5,88(s7)
    800049ac:	e6843703          	ld	a4,-408(s0)
    800049b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800049b2:	058bb783          	ld	a5,88(s7)
    800049b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049ba:	85ea                	mv	a1,s10
    800049bc:	92cfd0ef          	jal	ra,80001ae8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049c0:	0004851b          	sext.w	a0,s1
    800049c4:	b531                	j	800047d0 <kexec+0x80>
    800049c6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800049ca:	df843583          	ld	a1,-520(s0)
    800049ce:	855a                	mv	a0,s6
    800049d0:	918fd0ef          	jal	ra,80001ae8 <proc_freepagetable>
  if(ip){
    800049d4:	de0a98e3          	bnez	s5,800047c4 <kexec+0x74>
  return -1;
    800049d8:	557d                	li	a0,-1
    800049da:	bbdd                	j	800047d0 <kexec+0x80>
    800049dc:	df243c23          	sd	s2,-520(s0)
    800049e0:	b7ed                	j	800049ca <kexec+0x27a>
    800049e2:	df243c23          	sd	s2,-520(s0)
    800049e6:	b7d5                	j	800049ca <kexec+0x27a>
    800049e8:	df243c23          	sd	s2,-520(s0)
    800049ec:	bff9                	j	800049ca <kexec+0x27a>
    800049ee:	df243c23          	sd	s2,-520(s0)
    800049f2:	bfe1                	j	800049ca <kexec+0x27a>
  sz = sz1;
    800049f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800049f8:	4a81                	li	s5,0
    800049fa:	bfc1                	j	800049ca <kexec+0x27a>
  sz = sz1;
    800049fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a00:	4a81                	li	s5,0
    80004a02:	b7e1                	j	800049ca <kexec+0x27a>
  sz = sz1;
    80004a04:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a08:	4a81                	li	s5,0
    80004a0a:	b7c1                	j	800049ca <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004a0c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a10:	e0843783          	ld	a5,-504(s0)
    80004a14:	0017869b          	addiw	a3,a5,1
    80004a18:	e0d43423          	sd	a3,-504(s0)
    80004a1c:	e0043783          	ld	a5,-512(s0)
    80004a20:	0387879b          	addiw	a5,a5,56
    80004a24:	e8845703          	lhu	a4,-376(s0)
    80004a28:	e4e6d6e3          	bge	a3,a4,80004874 <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004a2c:	2781                	sext.w	a5,a5
    80004a2e:	e0f43023          	sd	a5,-512(s0)
    80004a32:	03800713          	li	a4,56
    80004a36:	86be                	mv	a3,a5
    80004a38:	e1840613          	addi	a2,s0,-488
    80004a3c:	4581                	li	a1,0
    80004a3e:	8556                	mv	a0,s5
    80004a40:	d05fe0ef          	jal	ra,80003744 <readi>
    80004a44:	03800793          	li	a5,56
    80004a48:	f6f51fe3          	bne	a0,a5,800049c6 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004a4c:	e1842783          	lw	a5,-488(s0)
    80004a50:	4705                	li	a4,1
    80004a52:	fae79fe3          	bne	a5,a4,80004a10 <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004a56:	e4043483          	ld	s1,-448(s0)
    80004a5a:	e3843783          	ld	a5,-456(s0)
    80004a5e:	f6f4efe3          	bltu	s1,a5,800049dc <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004a62:	e2843783          	ld	a5,-472(s0)
    80004a66:	94be                	add	s1,s1,a5
    80004a68:	f6f4ede3          	bltu	s1,a5,800049e2 <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004a6c:	de043703          	ld	a4,-544(s0)
    80004a70:	8ff9                	and	a5,a5,a4
    80004a72:	fbbd                	bnez	a5,800049e8 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004a74:	e1c42503          	lw	a0,-484(s0)
    80004a78:	cbdff0ef          	jal	ra,80004734 <flags2perm>
    80004a7c:	86aa                	mv	a3,a0
    80004a7e:	8626                	mv	a2,s1
    80004a80:	85ca                	mv	a1,s2
    80004a82:	855a                	mv	a0,s6
    80004a84:	899fc0ef          	jal	ra,8000131c <uvmalloc>
    80004a88:	dea43c23          	sd	a0,-520(s0)
    80004a8c:	d12d                	beqz	a0,800049ee <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004a8e:	e2843c03          	ld	s8,-472(s0)
    80004a92:	e2042c83          	lw	s9,-480(s0)
    80004a96:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004a9a:	f60b89e3          	beqz	s7,80004a0c <kexec+0x2bc>
    80004a9e:	89de                	mv	s3,s7
    80004aa0:	4481                	li	s1,0
    80004aa2:	bb55                	j	80004856 <kexec+0x106>

0000000080004aa4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004aa4:	7179                	addi	sp,sp,-48
    80004aa6:	f406                	sd	ra,40(sp)
    80004aa8:	f022                	sd	s0,32(sp)
    80004aaa:	ec26                	sd	s1,24(sp)
    80004aac:	e84a                	sd	s2,16(sp)
    80004aae:	1800                	addi	s0,sp,48
    80004ab0:	892e                	mv	s2,a1
    80004ab2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004ab4:	fdc40593          	addi	a1,s0,-36
    80004ab8:	f19fd0ef          	jal	ra,800029d0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004abc:	fdc42703          	lw	a4,-36(s0)
    80004ac0:	47bd                	li	a5,15
    80004ac2:	02e7e963          	bltu	a5,a4,80004af4 <argfd+0x50>
    80004ac6:	e99fc0ef          	jal	ra,8000195e <myproc>
    80004aca:	fdc42703          	lw	a4,-36(s0)
    80004ace:	01a70793          	addi	a5,a4,26
    80004ad2:	078e                	slli	a5,a5,0x3
    80004ad4:	953e                	add	a0,a0,a5
    80004ad6:	611c                	ld	a5,0(a0)
    80004ad8:	c385                	beqz	a5,80004af8 <argfd+0x54>
    return -1;
  if(pfd)
    80004ada:	00090463          	beqz	s2,80004ae2 <argfd+0x3e>
    *pfd = fd;
    80004ade:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ae2:	4501                	li	a0,0
  if(pf)
    80004ae4:	c091                	beqz	s1,80004ae8 <argfd+0x44>
    *pf = f;
    80004ae6:	e09c                	sd	a5,0(s1)
}
    80004ae8:	70a2                	ld	ra,40(sp)
    80004aea:	7402                	ld	s0,32(sp)
    80004aec:	64e2                	ld	s1,24(sp)
    80004aee:	6942                	ld	s2,16(sp)
    80004af0:	6145                	addi	sp,sp,48
    80004af2:	8082                	ret
    return -1;
    80004af4:	557d                	li	a0,-1
    80004af6:	bfcd                	j	80004ae8 <argfd+0x44>
    80004af8:	557d                	li	a0,-1
    80004afa:	b7fd                	j	80004ae8 <argfd+0x44>

0000000080004afc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	1000                	addi	s0,sp,32
    80004b06:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004b08:	e57fc0ef          	jal	ra,8000195e <myproc>
    80004b0c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004b0e:	0d050793          	addi	a5,a0,208
    80004b12:	4501                	li	a0,0
    80004b14:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004b16:	6398                	ld	a4,0(a5)
    80004b18:	cb19                	beqz	a4,80004b2e <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004b1a:	2505                	addiw	a0,a0,1
    80004b1c:	07a1                	addi	a5,a5,8
    80004b1e:	fed51ce3          	bne	a0,a3,80004b16 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004b22:	557d                	li	a0,-1
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6105                	addi	sp,sp,32
    80004b2c:	8082                	ret
      p->ofile[fd] = f;
    80004b2e:	01a50793          	addi	a5,a0,26
    80004b32:	078e                	slli	a5,a5,0x3
    80004b34:	963e                	add	a2,a2,a5
    80004b36:	e204                	sd	s1,0(a2)
      return fd;
    80004b38:	b7f5                	j	80004b24 <fdalloc+0x28>

0000000080004b3a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004b3a:	715d                	addi	sp,sp,-80
    80004b3c:	e486                	sd	ra,72(sp)
    80004b3e:	e0a2                	sd	s0,64(sp)
    80004b40:	fc26                	sd	s1,56(sp)
    80004b42:	f84a                	sd	s2,48(sp)
    80004b44:	f44e                	sd	s3,40(sp)
    80004b46:	f052                	sd	s4,32(sp)
    80004b48:	ec56                	sd	s5,24(sp)
    80004b4a:	e85a                	sd	s6,16(sp)
    80004b4c:	0880                	addi	s0,sp,80
    80004b4e:	8b2e                	mv	s6,a1
    80004b50:	89b2                	mv	s3,a2
    80004b52:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004b54:	fb040593          	addi	a1,s0,-80
    80004b58:	868ff0ef          	jal	ra,80003bc0 <nameiparent>
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	10050b63          	beqz	a0,80004c74 <create+0x13a>
    return 0;

  ilock(dp);
    80004b62:	857fe0ef          	jal	ra,800033b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004b66:	4601                	li	a2,0
    80004b68:	fb040593          	addi	a1,s0,-80
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	dd3fe0ef          	jal	ra,80003940 <dirlookup>
    80004b72:	8aaa                	mv	s5,a0
    80004b74:	c521                	beqz	a0,80004bbc <create+0x82>
    iunlockput(dp);
    80004b76:	8526                	mv	a0,s1
    80004b78:	a47fe0ef          	jal	ra,800035be <iunlockput>
    ilock(ip);
    80004b7c:	8556                	mv	a0,s5
    80004b7e:	83bfe0ef          	jal	ra,800033b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004b82:	000b059b          	sext.w	a1,s6
    80004b86:	4789                	li	a5,2
    80004b88:	02f59563          	bne	a1,a5,80004bb2 <create+0x78>
    80004b8c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbe06c>
    80004b90:	37f9                	addiw	a5,a5,-2
    80004b92:	17c2                	slli	a5,a5,0x30
    80004b94:	93c1                	srli	a5,a5,0x30
    80004b96:	4705                	li	a4,1
    80004b98:	00f76d63          	bltu	a4,a5,80004bb2 <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004b9c:	8556                	mv	a0,s5
    80004b9e:	60a6                	ld	ra,72(sp)
    80004ba0:	6406                	ld	s0,64(sp)
    80004ba2:	74e2                	ld	s1,56(sp)
    80004ba4:	7942                	ld	s2,48(sp)
    80004ba6:	79a2                	ld	s3,40(sp)
    80004ba8:	7a02                	ld	s4,32(sp)
    80004baa:	6ae2                	ld	s5,24(sp)
    80004bac:	6b42                	ld	s6,16(sp)
    80004bae:	6161                	addi	sp,sp,80
    80004bb0:	8082                	ret
    iunlockput(ip);
    80004bb2:	8556                	mv	a0,s5
    80004bb4:	a0bfe0ef          	jal	ra,800035be <iunlockput>
    return 0;
    80004bb8:	4a81                	li	s5,0
    80004bba:	b7cd                	j	80004b9c <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004bbc:	85da                	mv	a1,s6
    80004bbe:	4088                	lw	a0,0(s1)
    80004bc0:	e90fe0ef          	jal	ra,80003250 <ialloc>
    80004bc4:	8a2a                	mv	s4,a0
    80004bc6:	cd1d                	beqz	a0,80004c04 <create+0xca>
  ilock(ip);
    80004bc8:	ff0fe0ef          	jal	ra,800033b8 <ilock>
  ip->major = major;
    80004bcc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004bd0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004bd4:	4905                	li	s2,1
    80004bd6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004bda:	8552                	mv	a0,s4
    80004bdc:	f2afe0ef          	jal	ra,80003306 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004be0:	000b059b          	sext.w	a1,s6
    80004be4:	03258563          	beq	a1,s2,80004c0e <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004be8:	004a2603          	lw	a2,4(s4)
    80004bec:	fb040593          	addi	a1,s0,-80
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	f1bfe0ef          	jal	ra,80003b0c <dirlink>
    80004bf6:	06054363          	bltz	a0,80004c5c <create+0x122>
  iunlockput(dp);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	9c3fe0ef          	jal	ra,800035be <iunlockput>
  return ip;
    80004c00:	8ad2                	mv	s5,s4
    80004c02:	bf69                	j	80004b9c <create+0x62>
    iunlockput(dp);
    80004c04:	8526                	mv	a0,s1
    80004c06:	9b9fe0ef          	jal	ra,800035be <iunlockput>
    return 0;
    80004c0a:	8ad2                	mv	s5,s4
    80004c0c:	bf41                	j	80004b9c <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004c0e:	004a2603          	lw	a2,4(s4)
    80004c12:	00003597          	auipc	a1,0x3
    80004c16:	b1e58593          	addi	a1,a1,-1250 # 80007730 <syscalls+0x2e0>
    80004c1a:	8552                	mv	a0,s4
    80004c1c:	ef1fe0ef          	jal	ra,80003b0c <dirlink>
    80004c20:	02054e63          	bltz	a0,80004c5c <create+0x122>
    80004c24:	40d0                	lw	a2,4(s1)
    80004c26:	00003597          	auipc	a1,0x3
    80004c2a:	b1258593          	addi	a1,a1,-1262 # 80007738 <syscalls+0x2e8>
    80004c2e:	8552                	mv	a0,s4
    80004c30:	eddfe0ef          	jal	ra,80003b0c <dirlink>
    80004c34:	02054463          	bltz	a0,80004c5c <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c38:	004a2603          	lw	a2,4(s4)
    80004c3c:	fb040593          	addi	a1,s0,-80
    80004c40:	8526                	mv	a0,s1
    80004c42:	ecbfe0ef          	jal	ra,80003b0c <dirlink>
    80004c46:	00054b63          	bltz	a0,80004c5c <create+0x122>
    dp->nlink++;  // for ".."
    80004c4a:	04a4d783          	lhu	a5,74(s1)
    80004c4e:	2785                	addiw	a5,a5,1
    80004c50:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004c54:	8526                	mv	a0,s1
    80004c56:	eb0fe0ef          	jal	ra,80003306 <iupdate>
    80004c5a:	b745                	j	80004bfa <create+0xc0>
  ip->nlink = 0;
    80004c5c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004c60:	8552                	mv	a0,s4
    80004c62:	ea4fe0ef          	jal	ra,80003306 <iupdate>
  iunlockput(ip);
    80004c66:	8552                	mv	a0,s4
    80004c68:	957fe0ef          	jal	ra,800035be <iunlockput>
  iunlockput(dp);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	951fe0ef          	jal	ra,800035be <iunlockput>
  return 0;
    80004c72:	b72d                	j	80004b9c <create+0x62>
    return 0;
    80004c74:	8aaa                	mv	s5,a0
    80004c76:	b71d                	j	80004b9c <create+0x62>

0000000080004c78 <sys_dup>:
{
    80004c78:	7179                	addi	sp,sp,-48
    80004c7a:	f406                	sd	ra,40(sp)
    80004c7c:	f022                	sd	s0,32(sp)
    80004c7e:	ec26                	sd	s1,24(sp)
    80004c80:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004c82:	fd840613          	addi	a2,s0,-40
    80004c86:	4581                	li	a1,0
    80004c88:	4501                	li	a0,0
    80004c8a:	e1bff0ef          	jal	ra,80004aa4 <argfd>
    return -1;
    80004c8e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004c90:	00054f63          	bltz	a0,80004cae <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)
    80004c94:	fd843503          	ld	a0,-40(s0)
    80004c98:	e65ff0ef          	jal	ra,80004afc <fdalloc>
    80004c9c:	84aa                	mv	s1,a0
    return -1;
    80004c9e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004ca0:	00054763          	bltz	a0,80004cae <sys_dup+0x36>
  filedup(f);
    80004ca4:	fd843503          	ld	a0,-40(s0)
    80004ca8:	cb6ff0ef          	jal	ra,8000415e <filedup>
  return fd;
    80004cac:	87a6                	mv	a5,s1
}
    80004cae:	853e                	mv	a0,a5
    80004cb0:	70a2                	ld	ra,40(sp)
    80004cb2:	7402                	ld	s0,32(sp)
    80004cb4:	64e2                	ld	s1,24(sp)
    80004cb6:	6145                	addi	sp,sp,48
    80004cb8:	8082                	ret

0000000080004cba <sys_read>:
{
    80004cba:	7179                	addi	sp,sp,-48
    80004cbc:	f406                	sd	ra,40(sp)
    80004cbe:	f022                	sd	s0,32(sp)
    80004cc0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004cc2:	fd840593          	addi	a1,s0,-40
    80004cc6:	4505                	li	a0,1
    80004cc8:	d25fd0ef          	jal	ra,800029ec <argaddr>
  argint(2, &n);
    80004ccc:	fe440593          	addi	a1,s0,-28
    80004cd0:	4509                	li	a0,2
    80004cd2:	cfffd0ef          	jal	ra,800029d0 <argint>
  if(argfd(0, 0, &f) < 0)
    80004cd6:	fe840613          	addi	a2,s0,-24
    80004cda:	4581                	li	a1,0
    80004cdc:	4501                	li	a0,0
    80004cde:	dc7ff0ef          	jal	ra,80004aa4 <argfd>
    80004ce2:	87aa                	mv	a5,a0
    return -1;
    80004ce4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004ce6:	0007ca63          	bltz	a5,80004cfa <sys_read+0x40>
  return fileread(f, p, n);
    80004cea:	fe442603          	lw	a2,-28(s0)
    80004cee:	fd843583          	ld	a1,-40(s0)
    80004cf2:	fe843503          	ld	a0,-24(s0)
    80004cf6:	db4ff0ef          	jal	ra,800042aa <fileread>
}
    80004cfa:	70a2                	ld	ra,40(sp)
    80004cfc:	7402                	ld	s0,32(sp)
    80004cfe:	6145                	addi	sp,sp,48
    80004d00:	8082                	ret

0000000080004d02 <sys_write>:
{
    80004d02:	7179                	addi	sp,sp,-48
    80004d04:	f406                	sd	ra,40(sp)
    80004d06:	f022                	sd	s0,32(sp)
    80004d08:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004d0a:	fd840593          	addi	a1,s0,-40
    80004d0e:	4505                	li	a0,1
    80004d10:	cddfd0ef          	jal	ra,800029ec <argaddr>
  argint(2, &n);
    80004d14:	fe440593          	addi	a1,s0,-28
    80004d18:	4509                	li	a0,2
    80004d1a:	cb7fd0ef          	jal	ra,800029d0 <argint>
  if(argfd(0, 0, &f) < 0)
    80004d1e:	fe840613          	addi	a2,s0,-24
    80004d22:	4581                	li	a1,0
    80004d24:	4501                	li	a0,0
    80004d26:	d7fff0ef          	jal	ra,80004aa4 <argfd>
    80004d2a:	87aa                	mv	a5,a0
    return -1;
    80004d2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d2e:	0007ca63          	bltz	a5,80004d42 <sys_write+0x40>
  return filewrite(f, p, n);
    80004d32:	fe442603          	lw	a2,-28(s0)
    80004d36:	fd843583          	ld	a1,-40(s0)
    80004d3a:	fe843503          	ld	a0,-24(s0)
    80004d3e:	e1aff0ef          	jal	ra,80004358 <filewrite>
}
    80004d42:	70a2                	ld	ra,40(sp)
    80004d44:	7402                	ld	s0,32(sp)
    80004d46:	6145                	addi	sp,sp,48
    80004d48:	8082                	ret

0000000080004d4a <sys_close>:
{
    80004d4a:	1101                	addi	sp,sp,-32
    80004d4c:	ec06                	sd	ra,24(sp)
    80004d4e:	e822                	sd	s0,16(sp)
    80004d50:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004d52:	fe040613          	addi	a2,s0,-32
    80004d56:	fec40593          	addi	a1,s0,-20
    80004d5a:	4501                	li	a0,0
    80004d5c:	d49ff0ef          	jal	ra,80004aa4 <argfd>
    return -1;
    80004d60:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004d62:	02054063          	bltz	a0,80004d82 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004d66:	bf9fc0ef          	jal	ra,8000195e <myproc>
    80004d6a:	fec42783          	lw	a5,-20(s0)
    80004d6e:	07e9                	addi	a5,a5,26
    80004d70:	078e                	slli	a5,a5,0x3
    80004d72:	97aa                	add	a5,a5,a0
    80004d74:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80004d78:	fe043503          	ld	a0,-32(s0)
    80004d7c:	c28ff0ef          	jal	ra,800041a4 <fileclose>
  return 0;
    80004d80:	4781                	li	a5,0
}
    80004d82:	853e                	mv	a0,a5
    80004d84:	60e2                	ld	ra,24(sp)
    80004d86:	6442                	ld	s0,16(sp)
    80004d88:	6105                	addi	sp,sp,32
    80004d8a:	8082                	ret

0000000080004d8c <sys_fstat>:
{
    80004d8c:	1101                	addi	sp,sp,-32
    80004d8e:	ec06                	sd	ra,24(sp)
    80004d90:	e822                	sd	s0,16(sp)
    80004d92:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004d94:	fe040593          	addi	a1,s0,-32
    80004d98:	4505                	li	a0,1
    80004d9a:	c53fd0ef          	jal	ra,800029ec <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004d9e:	fe840613          	addi	a2,s0,-24
    80004da2:	4581                	li	a1,0
    80004da4:	4501                	li	a0,0
    80004da6:	cffff0ef          	jal	ra,80004aa4 <argfd>
    80004daa:	87aa                	mv	a5,a0
    return -1;
    80004dac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004dae:	0007c863          	bltz	a5,80004dbe <sys_fstat+0x32>
  return filestat(f, st);
    80004db2:	fe043583          	ld	a1,-32(s0)
    80004db6:	fe843503          	ld	a0,-24(s0)
    80004dba:	c92ff0ef          	jal	ra,8000424c <filestat>
}
    80004dbe:	60e2                	ld	ra,24(sp)
    80004dc0:	6442                	ld	s0,16(sp)
    80004dc2:	6105                	addi	sp,sp,32
    80004dc4:	8082                	ret

0000000080004dc6 <sys_link>:
{
    80004dc6:	7169                	addi	sp,sp,-304
    80004dc8:	f606                	sd	ra,296(sp)
    80004dca:	f222                	sd	s0,288(sp)
    80004dcc:	ee26                	sd	s1,280(sp)
    80004dce:	ea4a                	sd	s2,272(sp)
    80004dd0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dd2:	08000613          	li	a2,128
    80004dd6:	ed040593          	addi	a1,s0,-304
    80004dda:	4501                	li	a0,0
    80004ddc:	c2dfd0ef          	jal	ra,80002a08 <argstr>
    return -1;
    80004de0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004de2:	0c054663          	bltz	a0,80004eae <sys_link+0xe8>
    80004de6:	08000613          	li	a2,128
    80004dea:	f5040593          	addi	a1,s0,-176
    80004dee:	4505                	li	a0,1
    80004df0:	c19fd0ef          	jal	ra,80002a08 <argstr>
    return -1;
    80004df4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004df6:	0a054c63          	bltz	a0,80004eae <sys_link+0xe8>
  begin_op();
    80004dfa:	f9dfe0ef          	jal	ra,80003d96 <begin_op>
  if((ip = namei(old)) == 0){
    80004dfe:	ed040513          	addi	a0,s0,-304
    80004e02:	da5fe0ef          	jal	ra,80003ba6 <namei>
    80004e06:	84aa                	mv	s1,a0
    80004e08:	c525                	beqz	a0,80004e70 <sys_link+0xaa>
  ilock(ip);
    80004e0a:	daefe0ef          	jal	ra,800033b8 <ilock>
  if(ip->type == T_DIR){
    80004e0e:	04449703          	lh	a4,68(s1)
    80004e12:	4785                	li	a5,1
    80004e14:	06f70263          	beq	a4,a5,80004e78 <sys_link+0xb2>
  ip->nlink++;
    80004e18:	04a4d783          	lhu	a5,74(s1)
    80004e1c:	2785                	addiw	a5,a5,1
    80004e1e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ce2fe0ef          	jal	ra,80003306 <iupdate>
  iunlock(ip);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	e38fe0ef          	jal	ra,80003462 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004e2e:	fd040593          	addi	a1,s0,-48
    80004e32:	f5040513          	addi	a0,s0,-176
    80004e36:	d8bfe0ef          	jal	ra,80003bc0 <nameiparent>
    80004e3a:	892a                	mv	s2,a0
    80004e3c:	c921                	beqz	a0,80004e8c <sys_link+0xc6>
  ilock(dp);
    80004e3e:	d7afe0ef          	jal	ra,800033b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004e42:	00092703          	lw	a4,0(s2)
    80004e46:	409c                	lw	a5,0(s1)
    80004e48:	02f71f63          	bne	a4,a5,80004e86 <sys_link+0xc0>
    80004e4c:	40d0                	lw	a2,4(s1)
    80004e4e:	fd040593          	addi	a1,s0,-48
    80004e52:	854a                	mv	a0,s2
    80004e54:	cb9fe0ef          	jal	ra,80003b0c <dirlink>
    80004e58:	02054763          	bltz	a0,80004e86 <sys_link+0xc0>
  iunlockput(dp);
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	f60fe0ef          	jal	ra,800035be <iunlockput>
  iput(ip);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ed2fe0ef          	jal	ra,80003536 <iput>
  end_op();
    80004e68:	f9ffe0ef          	jal	ra,80003e06 <end_op>
  return 0;
    80004e6c:	4781                	li	a5,0
    80004e6e:	a081                	j	80004eae <sys_link+0xe8>
    end_op();
    80004e70:	f97fe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    80004e74:	57fd                	li	a5,-1
    80004e76:	a825                	j	80004eae <sys_link+0xe8>
    iunlockput(ip);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	f44fe0ef          	jal	ra,800035be <iunlockput>
    end_op();
    80004e7e:	f89fe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    80004e82:	57fd                	li	a5,-1
    80004e84:	a02d                	j	80004eae <sys_link+0xe8>
    iunlockput(dp);
    80004e86:	854a                	mv	a0,s2
    80004e88:	f36fe0ef          	jal	ra,800035be <iunlockput>
  ilock(ip);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	d2afe0ef          	jal	ra,800033b8 <ilock>
  ip->nlink--;
    80004e92:	04a4d783          	lhu	a5,74(s1)
    80004e96:	37fd                	addiw	a5,a5,-1
    80004e98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	c68fe0ef          	jal	ra,80003306 <iupdate>
  iunlockput(ip);
    80004ea2:	8526                	mv	a0,s1
    80004ea4:	f1afe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    80004ea8:	f5ffe0ef          	jal	ra,80003e06 <end_op>
  return -1;
    80004eac:	57fd                	li	a5,-1
}
    80004eae:	853e                	mv	a0,a5
    80004eb0:	70b2                	ld	ra,296(sp)
    80004eb2:	7412                	ld	s0,288(sp)
    80004eb4:	64f2                	ld	s1,280(sp)
    80004eb6:	6952                	ld	s2,272(sp)
    80004eb8:	6155                	addi	sp,sp,304
    80004eba:	8082                	ret

0000000080004ebc <sys_unlink>:
{
    80004ebc:	7151                	addi	sp,sp,-240
    80004ebe:	f586                	sd	ra,232(sp)
    80004ec0:	f1a2                	sd	s0,224(sp)
    80004ec2:	eda6                	sd	s1,216(sp)
    80004ec4:	e9ca                	sd	s2,208(sp)
    80004ec6:	e5ce                	sd	s3,200(sp)
    80004ec8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004eca:	08000613          	li	a2,128
    80004ece:	f3040593          	addi	a1,s0,-208
    80004ed2:	4501                	li	a0,0
    80004ed4:	b35fd0ef          	jal	ra,80002a08 <argstr>
    80004ed8:	12054b63          	bltz	a0,8000500e <sys_unlink+0x152>
  begin_op();
    80004edc:	ebbfe0ef          	jal	ra,80003d96 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004ee0:	fb040593          	addi	a1,s0,-80
    80004ee4:	f3040513          	addi	a0,s0,-208
    80004ee8:	cd9fe0ef          	jal	ra,80003bc0 <nameiparent>
    80004eec:	84aa                	mv	s1,a0
    80004eee:	c54d                	beqz	a0,80004f98 <sys_unlink+0xdc>
  ilock(dp);
    80004ef0:	cc8fe0ef          	jal	ra,800033b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004ef4:	00003597          	auipc	a1,0x3
    80004ef8:	83c58593          	addi	a1,a1,-1988 # 80007730 <syscalls+0x2e0>
    80004efc:	fb040513          	addi	a0,s0,-80
    80004f00:	a2bfe0ef          	jal	ra,8000392a <namecmp>
    80004f04:	10050a63          	beqz	a0,80005018 <sys_unlink+0x15c>
    80004f08:	00003597          	auipc	a1,0x3
    80004f0c:	83058593          	addi	a1,a1,-2000 # 80007738 <syscalls+0x2e8>
    80004f10:	fb040513          	addi	a0,s0,-80
    80004f14:	a17fe0ef          	jal	ra,8000392a <namecmp>
    80004f18:	10050063          	beqz	a0,80005018 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004f1c:	f2c40613          	addi	a2,s0,-212
    80004f20:	fb040593          	addi	a1,s0,-80
    80004f24:	8526                	mv	a0,s1
    80004f26:	a1bfe0ef          	jal	ra,80003940 <dirlookup>
    80004f2a:	892a                	mv	s2,a0
    80004f2c:	0e050663          	beqz	a0,80005018 <sys_unlink+0x15c>
  ilock(ip);
    80004f30:	c88fe0ef          	jal	ra,800033b8 <ilock>
  if(ip->nlink < 1)
    80004f34:	04a91783          	lh	a5,74(s2)
    80004f38:	06f05463          	blez	a5,80004fa0 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004f3c:	04491703          	lh	a4,68(s2)
    80004f40:	4785                	li	a5,1
    80004f42:	06f70563          	beq	a4,a5,80004fac <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));
    80004f46:	4641                	li	a2,16
    80004f48:	4581                	li	a1,0
    80004f4a:	fc040513          	addi	a0,s0,-64
    80004f4e:	deffb0ef          	jal	ra,80000d3c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f52:	4741                	li	a4,16
    80004f54:	f2c42683          	lw	a3,-212(s0)
    80004f58:	fc040613          	addi	a2,s0,-64
    80004f5c:	4581                	li	a1,0
    80004f5e:	8526                	mv	a0,s1
    80004f60:	8c9fe0ef          	jal	ra,80003828 <writei>
    80004f64:	47c1                	li	a5,16
    80004f66:	08f51563          	bne	a0,a5,80004ff0 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004f6a:	04491703          	lh	a4,68(s2)
    80004f6e:	4785                	li	a5,1
    80004f70:	08f70663          	beq	a4,a5,80004ffc <sys_unlink+0x140>
  iunlockput(dp);
    80004f74:	8526                	mv	a0,s1
    80004f76:	e48fe0ef          	jal	ra,800035be <iunlockput>
  ip->nlink--;
    80004f7a:	04a95783          	lhu	a5,74(s2)
    80004f7e:	37fd                	addiw	a5,a5,-1
    80004f80:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004f84:	854a                	mv	a0,s2
    80004f86:	b80fe0ef          	jal	ra,80003306 <iupdate>
  iunlockput(ip);
    80004f8a:	854a                	mv	a0,s2
    80004f8c:	e32fe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    80004f90:	e77fe0ef          	jal	ra,80003e06 <end_op>
  return 0;
    80004f94:	4501                	li	a0,0
    80004f96:	a079                	j	80005024 <sys_unlink+0x168>
    end_op();
    80004f98:	e6ffe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    80004f9c:	557d                	li	a0,-1
    80004f9e:	a059                	j	80005024 <sys_unlink+0x168>
    panic("unlink: nlink < 1");
    80004fa0:	00002517          	auipc	a0,0x2
    80004fa4:	7a050513          	addi	a0,a0,1952 # 80007740 <syscalls+0x2f0>
    80004fa8:	fc2fb0ef          	jal	ra,8000076a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004fac:	04c92703          	lw	a4,76(s2)
    80004fb0:	02000793          	li	a5,32
    80004fb4:	f8e7f9e3          	bgeu	a5,a4,80004f46 <sys_unlink+0x8a>
    80004fb8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004fbc:	4741                	li	a4,16
    80004fbe:	86ce                	mv	a3,s3
    80004fc0:	f1840613          	addi	a2,s0,-232
    80004fc4:	4581                	li	a1,0
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	f7cfe0ef          	jal	ra,80003744 <readi>
    80004fcc:	47c1                	li	a5,16
    80004fce:	00f51b63          	bne	a0,a5,80004fe4 <sys_unlink+0x128>
    if(de.inum != 0)
    80004fd2:	f1845783          	lhu	a5,-232(s0)
    80004fd6:	ef95                	bnez	a5,80005012 <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004fd8:	29c1                	addiw	s3,s3,16
    80004fda:	04c92783          	lw	a5,76(s2)
    80004fde:	fcf9efe3          	bltu	s3,a5,80004fbc <sys_unlink+0x100>
    80004fe2:	b795                	j	80004f46 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004fe4:	00002517          	auipc	a0,0x2
    80004fe8:	77450513          	addi	a0,a0,1908 # 80007758 <syscalls+0x308>
    80004fec:	f7efb0ef          	jal	ra,8000076a <panic>
    panic("unlink: writei");
    80004ff0:	00002517          	auipc	a0,0x2
    80004ff4:	78050513          	addi	a0,a0,1920 # 80007770 <syscalls+0x320>
    80004ff8:	f72fb0ef          	jal	ra,8000076a <panic>
    dp->nlink--;
    80004ffc:	04a4d783          	lhu	a5,74(s1)
    80005000:	37fd                	addiw	a5,a5,-1
    80005002:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005006:	8526                	mv	a0,s1
    80005008:	afefe0ef          	jal	ra,80003306 <iupdate>
    8000500c:	b7a5                	j	80004f74 <sys_unlink+0xb8>
    return -1;
    8000500e:	557d                	li	a0,-1
    80005010:	a811                	j	80005024 <sys_unlink+0x168>
    iunlockput(ip);
    80005012:	854a                	mv	a0,s2
    80005014:	daafe0ef          	jal	ra,800035be <iunlockput>
  iunlockput(dp);
    80005018:	8526                	mv	a0,s1
    8000501a:	da4fe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    8000501e:	de9fe0ef          	jal	ra,80003e06 <end_op>
  return -1;
    80005022:	557d                	li	a0,-1
}
    80005024:	70ae                	ld	ra,232(sp)
    80005026:	740e                	ld	s0,224(sp)
    80005028:	64ee                	ld	s1,216(sp)
    8000502a:	694e                	ld	s2,208(sp)
    8000502c:	69ae                	ld	s3,200(sp)
    8000502e:	616d                	addi	sp,sp,240
    80005030:	8082                	ret

0000000080005032 <sys_open>:

uint64
sys_open(void)
{
    80005032:	7131                	addi	sp,sp,-192
    80005034:	fd06                	sd	ra,184(sp)
    80005036:	f922                	sd	s0,176(sp)
    80005038:	f526                	sd	s1,168(sp)
    8000503a:	f14a                	sd	s2,160(sp)
    8000503c:	ed4e                	sd	s3,152(sp)
    8000503e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005040:	f4c40593          	addi	a1,s0,-180
    80005044:	4505                	li	a0,1
    80005046:	98bfd0ef          	jal	ra,800029d0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000504a:	08000613          	li	a2,128
    8000504e:	f5040593          	addi	a1,s0,-176
    80005052:	4501                	li	a0,0
    80005054:	9b5fd0ef          	jal	ra,80002a08 <argstr>
    80005058:	87aa                	mv	a5,a0
    return -1;
    8000505a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000505c:	0807cd63          	bltz	a5,800050f6 <sys_open+0xc4>

  begin_op();
    80005060:	d37fe0ef          	jal	ra,80003d96 <begin_op>

  if(omode & O_CREATE){
    80005064:	f4c42783          	lw	a5,-180(s0)
    80005068:	2007f793          	andi	a5,a5,512
    8000506c:	c3c5                	beqz	a5,8000510c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    8000506e:	4681                	li	a3,0
    80005070:	4601                	li	a2,0
    80005072:	4589                	li	a1,2
    80005074:	f5040513          	addi	a0,s0,-176
    80005078:	ac3ff0ef          	jal	ra,80004b3a <create>
    8000507c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000507e:	c159                	beqz	a0,80005104 <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005080:	04449703          	lh	a4,68(s1)
    80005084:	478d                	li	a5,3
    80005086:	00f71763          	bne	a4,a5,80005094 <sys_open+0x62>
    8000508a:	0464d703          	lhu	a4,70(s1)
    8000508e:	47a5                	li	a5,9
    80005090:	0ae7e963          	bltu	a5,a4,80005142 <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005094:	86cff0ef          	jal	ra,80004100 <filealloc>
    80005098:	89aa                	mv	s3,a0
    8000509a:	0c050963          	beqz	a0,8000516c <sys_open+0x13a>
    8000509e:	a5fff0ef          	jal	ra,80004afc <fdalloc>
    800050a2:	892a                	mv	s2,a0
    800050a4:	0c054163          	bltz	a0,80005166 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800050a8:	04449703          	lh	a4,68(s1)
    800050ac:	478d                	li	a5,3
    800050ae:	0af70163          	beq	a4,a5,80005150 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800050b2:	4789                	li	a5,2
    800050b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800050b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800050bc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800050c0:	f4c42783          	lw	a5,-180(s0)
    800050c4:	0017c713          	xori	a4,a5,1
    800050c8:	8b05                	andi	a4,a4,1
    800050ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800050ce:	0037f713          	andi	a4,a5,3
    800050d2:	00e03733          	snez	a4,a4
    800050d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800050da:	4007f793          	andi	a5,a5,1024
    800050de:	c791                	beqz	a5,800050ea <sys_open+0xb8>
    800050e0:	04449703          	lh	a4,68(s1)
    800050e4:	4789                	li	a5,2
    800050e6:	06f70c63          	beq	a4,a5,8000515e <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    800050ea:	8526                	mv	a0,s1
    800050ec:	b76fe0ef          	jal	ra,80003462 <iunlock>
  end_op();
    800050f0:	d17fe0ef          	jal	ra,80003e06 <end_op>

  return fd;
    800050f4:	854a                	mv	a0,s2
}
    800050f6:	70ea                	ld	ra,184(sp)
    800050f8:	744a                	ld	s0,176(sp)
    800050fa:	74aa                	ld	s1,168(sp)
    800050fc:	790a                	ld	s2,160(sp)
    800050fe:	69ea                	ld	s3,152(sp)
    80005100:	6129                	addi	sp,sp,192
    80005102:	8082                	ret
      end_op();
    80005104:	d03fe0ef          	jal	ra,80003e06 <end_op>
      return -1;
    80005108:	557d                	li	a0,-1
    8000510a:	b7f5                	j	800050f6 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    8000510c:	f5040513          	addi	a0,s0,-176
    80005110:	a97fe0ef          	jal	ra,80003ba6 <namei>
    80005114:	84aa                	mv	s1,a0
    80005116:	c115                	beqz	a0,8000513a <sys_open+0x108>
    ilock(ip);
    80005118:	aa0fe0ef          	jal	ra,800033b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000511c:	04449703          	lh	a4,68(s1)
    80005120:	4785                	li	a5,1
    80005122:	f4f71fe3          	bne	a4,a5,80005080 <sys_open+0x4e>
    80005126:	f4c42783          	lw	a5,-180(s0)
    8000512a:	d7ad                	beqz	a5,80005094 <sys_open+0x62>
      iunlockput(ip);
    8000512c:	8526                	mv	a0,s1
    8000512e:	c90fe0ef          	jal	ra,800035be <iunlockput>
      end_op();
    80005132:	cd5fe0ef          	jal	ra,80003e06 <end_op>
      return -1;
    80005136:	557d                	li	a0,-1
    80005138:	bf7d                	j	800050f6 <sys_open+0xc4>
      end_op();
    8000513a:	ccdfe0ef          	jal	ra,80003e06 <end_op>
      return -1;
    8000513e:	557d                	li	a0,-1
    80005140:	bf5d                	j	800050f6 <sys_open+0xc4>
    iunlockput(ip);
    80005142:	8526                	mv	a0,s1
    80005144:	c7afe0ef          	jal	ra,800035be <iunlockput>
    end_op();
    80005148:	cbffe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    8000514c:	557d                	li	a0,-1
    8000514e:	b765                	j	800050f6 <sys_open+0xc4>
    f->type = FD_DEVICE;
    80005150:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005154:	04649783          	lh	a5,70(s1)
    80005158:	02f99223          	sh	a5,36(s3)
    8000515c:	b785                	j	800050bc <sys_open+0x8a>
    itrunc(ip);
    8000515e:	8526                	mv	a0,s1
    80005160:	b42fe0ef          	jal	ra,800034a2 <itrunc>
    80005164:	b759                	j	800050ea <sys_open+0xb8>
      fileclose(f);
    80005166:	854e                	mv	a0,s3
    80005168:	83cff0ef          	jal	ra,800041a4 <fileclose>
    iunlockput(ip);
    8000516c:	8526                	mv	a0,s1
    8000516e:	c50fe0ef          	jal	ra,800035be <iunlockput>
    end_op();
    80005172:	c95fe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    80005176:	557d                	li	a0,-1
    80005178:	bfbd                	j	800050f6 <sys_open+0xc4>

000000008000517a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000517a:	7175                	addi	sp,sp,-144
    8000517c:	e506                	sd	ra,136(sp)
    8000517e:	e122                	sd	s0,128(sp)
    80005180:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005182:	c15fe0ef          	jal	ra,80003d96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005186:	08000613          	li	a2,128
    8000518a:	f7040593          	addi	a1,s0,-144
    8000518e:	4501                	li	a0,0
    80005190:	879fd0ef          	jal	ra,80002a08 <argstr>
    80005194:	02054363          	bltz	a0,800051ba <sys_mkdir+0x40>
    80005198:	4681                	li	a3,0
    8000519a:	4601                	li	a2,0
    8000519c:	4585                	li	a1,1
    8000519e:	f7040513          	addi	a0,s0,-144
    800051a2:	999ff0ef          	jal	ra,80004b3a <create>
    800051a6:	c911                	beqz	a0,800051ba <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051a8:	c16fe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    800051ac:	c5bfe0ef          	jal	ra,80003e06 <end_op>
  return 0;
    800051b0:	4501                	li	a0,0
}
    800051b2:	60aa                	ld	ra,136(sp)
    800051b4:	640a                	ld	s0,128(sp)
    800051b6:	6149                	addi	sp,sp,144
    800051b8:	8082                	ret
    end_op();
    800051ba:	c4dfe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    800051be:	557d                	li	a0,-1
    800051c0:	bfcd                	j	800051b2 <sys_mkdir+0x38>

00000000800051c2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800051c2:	7135                	addi	sp,sp,-160
    800051c4:	ed06                	sd	ra,152(sp)
    800051c6:	e922                	sd	s0,144(sp)
    800051c8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800051ca:	bcdfe0ef          	jal	ra,80003d96 <begin_op>
  argint(1, &major);
    800051ce:	f6c40593          	addi	a1,s0,-148
    800051d2:	4505                	li	a0,1
    800051d4:	ffcfd0ef          	jal	ra,800029d0 <argint>
  argint(2, &minor);
    800051d8:	f6840593          	addi	a1,s0,-152
    800051dc:	4509                	li	a0,2
    800051de:	ff2fd0ef          	jal	ra,800029d0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051e2:	08000613          	li	a2,128
    800051e6:	f7040593          	addi	a1,s0,-144
    800051ea:	4501                	li	a0,0
    800051ec:	81dfd0ef          	jal	ra,80002a08 <argstr>
    800051f0:	02054563          	bltz	a0,8000521a <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800051f4:	f6841683          	lh	a3,-152(s0)
    800051f8:	f6c41603          	lh	a2,-148(s0)
    800051fc:	458d                	li	a1,3
    800051fe:	f7040513          	addi	a0,s0,-144
    80005202:	939ff0ef          	jal	ra,80004b3a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005206:	c911                	beqz	a0,8000521a <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005208:	bb6fe0ef          	jal	ra,800035be <iunlockput>
  end_op();
    8000520c:	bfbfe0ef          	jal	ra,80003e06 <end_op>
  return 0;
    80005210:	4501                	li	a0,0
}
    80005212:	60ea                	ld	ra,152(sp)
    80005214:	644a                	ld	s0,144(sp)
    80005216:	610d                	addi	sp,sp,160
    80005218:	8082                	ret
    end_op();
    8000521a:	bedfe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    8000521e:	557d                	li	a0,-1
    80005220:	bfcd                	j	80005212 <sys_mknod+0x50>

0000000080005222 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005222:	7135                	addi	sp,sp,-160
    80005224:	ed06                	sd	ra,152(sp)
    80005226:	e922                	sd	s0,144(sp)
    80005228:	e526                	sd	s1,136(sp)
    8000522a:	e14a                	sd	s2,128(sp)
    8000522c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000522e:	f30fc0ef          	jal	ra,8000195e <myproc>
    80005232:	892a                	mv	s2,a0
  
  begin_op();
    80005234:	b63fe0ef          	jal	ra,80003d96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005238:	08000613          	li	a2,128
    8000523c:	f6040593          	addi	a1,s0,-160
    80005240:	4501                	li	a0,0
    80005242:	fc6fd0ef          	jal	ra,80002a08 <argstr>
    80005246:	04054163          	bltz	a0,80005288 <sys_chdir+0x66>
    8000524a:	f6040513          	addi	a0,s0,-160
    8000524e:	959fe0ef          	jal	ra,80003ba6 <namei>
    80005252:	84aa                	mv	s1,a0
    80005254:	c915                	beqz	a0,80005288 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005256:	962fe0ef          	jal	ra,800033b8 <ilock>
  if(ip->type != T_DIR){
    8000525a:	04449703          	lh	a4,68(s1)
    8000525e:	4785                	li	a5,1
    80005260:	02f71863          	bne	a4,a5,80005290 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005264:	8526                	mv	a0,s1
    80005266:	9fcfe0ef          	jal	ra,80003462 <iunlock>
  iput(p->cwd);
    8000526a:	15093503          	ld	a0,336(s2)
    8000526e:	ac8fe0ef          	jal	ra,80003536 <iput>
  end_op();
    80005272:	b95fe0ef          	jal	ra,80003e06 <end_op>
  p->cwd = ip;
    80005276:	14993823          	sd	s1,336(s2)
  return 0;
    8000527a:	4501                	li	a0,0
}
    8000527c:	60ea                	ld	ra,152(sp)
    8000527e:	644a                	ld	s0,144(sp)
    80005280:	64aa                	ld	s1,136(sp)
    80005282:	690a                	ld	s2,128(sp)
    80005284:	610d                	addi	sp,sp,160
    80005286:	8082                	ret
    end_op();
    80005288:	b7ffe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    8000528c:	557d                	li	a0,-1
    8000528e:	b7fd                	j	8000527c <sys_chdir+0x5a>
    iunlockput(ip);
    80005290:	8526                	mv	a0,s1
    80005292:	b2cfe0ef          	jal	ra,800035be <iunlockput>
    end_op();
    80005296:	b71fe0ef          	jal	ra,80003e06 <end_op>
    return -1;
    8000529a:	557d                	li	a0,-1
    8000529c:	b7c5                	j	8000527c <sys_chdir+0x5a>

000000008000529e <sys_exec>:

uint64
sys_exec(void)
{
    8000529e:	7145                	addi	sp,sp,-464
    800052a0:	e786                	sd	ra,456(sp)
    800052a2:	e3a2                	sd	s0,448(sp)
    800052a4:	ff26                	sd	s1,440(sp)
    800052a6:	fb4a                	sd	s2,432(sp)
    800052a8:	f74e                	sd	s3,424(sp)
    800052aa:	f352                	sd	s4,416(sp)
    800052ac:	ef56                	sd	s5,408(sp)
    800052ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800052b0:	e3840593          	addi	a1,s0,-456
    800052b4:	4505                	li	a0,1
    800052b6:	f36fd0ef          	jal	ra,800029ec <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800052ba:	08000613          	li	a2,128
    800052be:	f4040593          	addi	a1,s0,-192
    800052c2:	4501                	li	a0,0
    800052c4:	f44fd0ef          	jal	ra,80002a08 <argstr>
    800052c8:	87aa                	mv	a5,a0
    return -1;
    800052ca:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800052cc:	0a07c463          	bltz	a5,80005374 <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    800052d0:	10000613          	li	a2,256
    800052d4:	4581                	li	a1,0
    800052d6:	e4040513          	addi	a0,s0,-448
    800052da:	a63fb0ef          	jal	ra,80000d3c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800052de:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800052e2:	89a6                	mv	s3,s1
    800052e4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800052e6:	02000a13          	li	s4,32
    800052ea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800052ee:	00391793          	slli	a5,s2,0x3
    800052f2:	e3040593          	addi	a1,s0,-464
    800052f6:	e3843503          	ld	a0,-456(s0)
    800052fa:	953e                	add	a0,a0,a5
    800052fc:	e4afd0ef          	jal	ra,80002946 <fetchaddr>
    80005300:	02054663          	bltz	a0,8000532c <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    80005304:	e3043783          	ld	a5,-464(s0)
    80005308:	cf8d                	beqz	a5,80005342 <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000530a:	ff6fb0ef          	jal	ra,80000b00 <kalloc>
    8000530e:	85aa                	mv	a1,a0
    80005310:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005314:	cd01                	beqz	a0,8000532c <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005316:	6605                	lui	a2,0x1
    80005318:	e3043503          	ld	a0,-464(s0)
    8000531c:	e74fd0ef          	jal	ra,80002990 <fetchstr>
    80005320:	00054663          	bltz	a0,8000532c <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    80005324:	0905                	addi	s2,s2,1
    80005326:	09a1                	addi	s3,s3,8
    80005328:	fd4911e3          	bne	s2,s4,800052ea <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000532c:	10048913          	addi	s2,s1,256
    80005330:	6088                	ld	a0,0(s1)
    80005332:	c121                	beqz	a0,80005372 <sys_exec+0xd4>
    kfree(argv[i]);
    80005334:	e68fb0ef          	jal	ra,8000099c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005338:	04a1                	addi	s1,s1,8
    8000533a:	ff249be3          	bne	s1,s2,80005330 <sys_exec+0x92>
  return -1;
    8000533e:	557d                	li	a0,-1
    80005340:	a815                	j	80005374 <sys_exec+0xd6>
      argv[i] = 0;
    80005342:	0a8e                	slli	s5,s5,0x3
    80005344:	fc040793          	addi	a5,s0,-64
    80005348:	9abe                	add	s5,s5,a5
    8000534a:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);
    8000534e:	e4040593          	addi	a1,s0,-448
    80005352:	f4040513          	addi	a0,s0,-192
    80005356:	bfaff0ef          	jal	ra,80004750 <kexec>
    8000535a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000535c:	10048993          	addi	s3,s1,256
    80005360:	6088                	ld	a0,0(s1)
    80005362:	c511                	beqz	a0,8000536e <sys_exec+0xd0>
    kfree(argv[i]);
    80005364:	e38fb0ef          	jal	ra,8000099c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005368:	04a1                	addi	s1,s1,8
    8000536a:	ff349be3          	bne	s1,s3,80005360 <sys_exec+0xc2>
  return ret;
    8000536e:	854a                	mv	a0,s2
    80005370:	a011                	j	80005374 <sys_exec+0xd6>
  return -1;
    80005372:	557d                	li	a0,-1
}
    80005374:	60be                	ld	ra,456(sp)
    80005376:	641e                	ld	s0,448(sp)
    80005378:	74fa                	ld	s1,440(sp)
    8000537a:	795a                	ld	s2,432(sp)
    8000537c:	79ba                	ld	s3,424(sp)
    8000537e:	7a1a                	ld	s4,416(sp)
    80005380:	6afa                	ld	s5,408(sp)
    80005382:	6179                	addi	sp,sp,464
    80005384:	8082                	ret

0000000080005386 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005386:	7139                	addi	sp,sp,-64
    80005388:	fc06                	sd	ra,56(sp)
    8000538a:	f822                	sd	s0,48(sp)
    8000538c:	f426                	sd	s1,40(sp)
    8000538e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005390:	dcefc0ef          	jal	ra,8000195e <myproc>
    80005394:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005396:	fd840593          	addi	a1,s0,-40
    8000539a:	4501                	li	a0,0
    8000539c:	e50fd0ef          	jal	ra,800029ec <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800053a0:	fc840593          	addi	a1,s0,-56
    800053a4:	fd040513          	addi	a0,s0,-48
    800053a8:	8c8ff0ef          	jal	ra,80004470 <pipealloc>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800053ae:	0a054463          	bltz	a0,80005456 <sys_pipe+0xd0>
  fd0 = -1;
    800053b2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800053b6:	fd043503          	ld	a0,-48(s0)
    800053ba:	f42ff0ef          	jal	ra,80004afc <fdalloc>
    800053be:	fca42223          	sw	a0,-60(s0)
    800053c2:	08054163          	bltz	a0,80005444 <sys_pipe+0xbe>
    800053c6:	fc843503          	ld	a0,-56(s0)
    800053ca:	f32ff0ef          	jal	ra,80004afc <fdalloc>
    800053ce:	fca42023          	sw	a0,-64(s0)
    800053d2:	06054063          	bltz	a0,80005432 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053d6:	4691                	li	a3,4
    800053d8:	fc440613          	addi	a2,s0,-60
    800053dc:	fd843583          	ld	a1,-40(s0)
    800053e0:	68a8                	ld	a0,80(s1)
    800053e2:	aaafc0ef          	jal	ra,8000168c <copyout>
    800053e6:	00054e63          	bltz	a0,80005402 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053ea:	4691                	li	a3,4
    800053ec:	fc040613          	addi	a2,s0,-64
    800053f0:	fd843583          	ld	a1,-40(s0)
    800053f4:	0591                	addi	a1,a1,4
    800053f6:	68a8                	ld	a0,80(s1)
    800053f8:	a94fc0ef          	jal	ra,8000168c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800053fc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053fe:	04055c63          	bgez	a0,80005456 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005402:	fc442783          	lw	a5,-60(s0)
    80005406:	07e9                	addi	a5,a5,26
    80005408:	078e                	slli	a5,a5,0x3
    8000540a:	97a6                	add	a5,a5,s1
    8000540c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005410:	fc042503          	lw	a0,-64(s0)
    80005414:	0569                	addi	a0,a0,26
    80005416:	050e                	slli	a0,a0,0x3
    80005418:	94aa                	add	s1,s1,a0
    8000541a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000541e:	fd043503          	ld	a0,-48(s0)
    80005422:	d83fe0ef          	jal	ra,800041a4 <fileclose>
    fileclose(wf);
    80005426:	fc843503          	ld	a0,-56(s0)
    8000542a:	d7bfe0ef          	jal	ra,800041a4 <fileclose>
    return -1;
    8000542e:	57fd                	li	a5,-1
    80005430:	a01d                	j	80005456 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005432:	fc442783          	lw	a5,-60(s0)
    80005436:	0007c763          	bltz	a5,80005444 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000543a:	07e9                	addi	a5,a5,26
    8000543c:	078e                	slli	a5,a5,0x3
    8000543e:	94be                	add	s1,s1,a5
    80005440:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005444:	fd043503          	ld	a0,-48(s0)
    80005448:	d5dfe0ef          	jal	ra,800041a4 <fileclose>
    fileclose(wf);
    8000544c:	fc843503          	ld	a0,-56(s0)
    80005450:	d55fe0ef          	jal	ra,800041a4 <fileclose>
    return -1;
    80005454:	57fd                	li	a5,-1
}
    80005456:	853e                	mv	a0,a5
    80005458:	70e2                	ld	ra,56(sp)
    8000545a:	7442                	ld	s0,48(sp)
    8000545c:	74a2                	ld	s1,40(sp)
    8000545e:	6121                	addi	sp,sp,64
    80005460:	8082                	ret
	...

0000000080005470 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005470:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005472:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005474:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005476:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005478:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000547a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000547c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000547e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005480:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005482:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005484:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005486:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005488:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000548a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000548c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000548e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005490:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005492:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005494:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005496:	bb2fd0ef          	jal	ra,80002848 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000549a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000549c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000549e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800054a0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800054a2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800054a4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800054a6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800054a8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800054aa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800054ac:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800054ae:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800054b0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800054b2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800054b4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800054b6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800054b8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800054ba:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800054bc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800054be:	10200073          	sret
	...

00000000800054ce <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800054ce:	1141                	addi	sp,sp,-16
    800054d0:	e422                	sd	s0,8(sp)
    800054d2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800054d4:	0c0007b7          	lui	a5,0xc000
    800054d8:	4705                	li	a4,1
    800054da:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800054dc:	c3d8                	sw	a4,4(a5)
}
    800054de:	6422                	ld	s0,8(sp)
    800054e0:	0141                	addi	sp,sp,16
    800054e2:	8082                	ret

00000000800054e4 <plicinithart>:

void
plicinithart(void)
{
    800054e4:	1141                	addi	sp,sp,-16
    800054e6:	e406                	sd	ra,8(sp)
    800054e8:	e022                	sd	s0,0(sp)
    800054ea:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054ec:	c46fc0ef          	jal	ra,80001932 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800054f0:	0085171b          	slliw	a4,a0,0x8
    800054f4:	0c0027b7          	lui	a5,0xc002
    800054f8:	97ba                	add	a5,a5,a4
    800054fa:	40200713          	li	a4,1026
    800054fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005502:	00d5151b          	slliw	a0,a0,0xd
    80005506:	0c2017b7          	lui	a5,0xc201
    8000550a:	953e                	add	a0,a0,a5
    8000550c:	00052023          	sw	zero,0(a0)
}
    80005510:	60a2                	ld	ra,8(sp)
    80005512:	6402                	ld	s0,0(sp)
    80005514:	0141                	addi	sp,sp,16
    80005516:	8082                	ret

0000000080005518 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005518:	1141                	addi	sp,sp,-16
    8000551a:	e406                	sd	ra,8(sp)
    8000551c:	e022                	sd	s0,0(sp)
    8000551e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005520:	c12fc0ef          	jal	ra,80001932 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005524:	00d5179b          	slliw	a5,a0,0xd
    80005528:	0c201537          	lui	a0,0xc201
    8000552c:	953e                	add	a0,a0,a5
  return irq;
}
    8000552e:	4148                	lw	a0,4(a0)
    80005530:	60a2                	ld	ra,8(sp)
    80005532:	6402                	ld	s0,0(sp)
    80005534:	0141                	addi	sp,sp,16
    80005536:	8082                	ret

0000000080005538 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005538:	1101                	addi	sp,sp,-32
    8000553a:	ec06                	sd	ra,24(sp)
    8000553c:	e822                	sd	s0,16(sp)
    8000553e:	e426                	sd	s1,8(sp)
    80005540:	1000                	addi	s0,sp,32
    80005542:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005544:	beefc0ef          	jal	ra,80001932 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005548:	00d5151b          	slliw	a0,a0,0xd
    8000554c:	0c2017b7          	lui	a5,0xc201
    80005550:	97aa                	add	a5,a5,a0
    80005552:	c3c4                	sw	s1,4(a5)
}
    80005554:	60e2                	ld	ra,24(sp)
    80005556:	6442                	ld	s0,16(sp)
    80005558:	64a2                	ld	s1,8(sp)
    8000555a:	6105                	addi	sp,sp,32
    8000555c:	8082                	ret

000000008000555e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000555e:	1141                	addi	sp,sp,-16
    80005560:	e406                	sd	ra,8(sp)
    80005562:	e022                	sd	s0,0(sp)
    80005564:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005566:	479d                	li	a5,7
    80005568:	04a7ca63          	blt	a5,a0,800055bc <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000556c:	0023c797          	auipc	a5,0x23c
    80005570:	92c78793          	addi	a5,a5,-1748 # 80240e98 <disk>
    80005574:	97aa                	add	a5,a5,a0
    80005576:	0187c783          	lbu	a5,24(a5)
    8000557a:	e7b9                	bnez	a5,800055c8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000557c:	00451613          	slli	a2,a0,0x4
    80005580:	0023c797          	auipc	a5,0x23c
    80005584:	91878793          	addi	a5,a5,-1768 # 80240e98 <disk>
    80005588:	6394                	ld	a3,0(a5)
    8000558a:	96b2                	add	a3,a3,a2
    8000558c:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005590:	6398                	ld	a4,0(a5)
    80005592:	9732                	add	a4,a4,a2
    80005594:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005598:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    8000559c:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800055a0:	953e                	add	a0,a0,a5
    800055a2:	4785                	li	a5,1
    800055a4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800055a8:	0023c517          	auipc	a0,0x23c
    800055ac:	90850513          	addi	a0,a0,-1784 # 80240eb0 <disk+0x18>
    800055b0:	b4ffc0ef          	jal	ra,800020fe <wakeup>
}
    800055b4:	60a2                	ld	ra,8(sp)
    800055b6:	6402                	ld	s0,0(sp)
    800055b8:	0141                	addi	sp,sp,16
    800055ba:	8082                	ret
    panic("free_desc 1");
    800055bc:	00002517          	auipc	a0,0x2
    800055c0:	1c450513          	addi	a0,a0,452 # 80007780 <syscalls+0x330>
    800055c4:	9a6fb0ef          	jal	ra,8000076a <panic>
    panic("free_desc 2");
    800055c8:	00002517          	auipc	a0,0x2
    800055cc:	1c850513          	addi	a0,a0,456 # 80007790 <syscalls+0x340>
    800055d0:	99afb0ef          	jal	ra,8000076a <panic>

00000000800055d4 <virtio_disk_init>:
{
    800055d4:	1101                	addi	sp,sp,-32
    800055d6:	ec06                	sd	ra,24(sp)
    800055d8:	e822                	sd	s0,16(sp)
    800055da:	e426                	sd	s1,8(sp)
    800055dc:	e04a                	sd	s2,0(sp)
    800055de:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800055e0:	00002597          	auipc	a1,0x2
    800055e4:	1c058593          	addi	a1,a1,448 # 800077a0 <syscalls+0x350>
    800055e8:	0023c517          	auipc	a0,0x23c
    800055ec:	9d850513          	addi	a0,a0,-1576 # 80240fc0 <disk+0x128>
    800055f0:	df8fb0ef          	jal	ra,80000be8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055f4:	100017b7          	lui	a5,0x10001
    800055f8:	4398                	lw	a4,0(a5)
    800055fa:	2701                	sext.w	a4,a4
    800055fc:	747277b7          	lui	a5,0x74727
    80005600:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005604:	14f71063          	bne	a4,a5,80005744 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005608:	100017b7          	lui	a5,0x10001
    8000560c:	43dc                	lw	a5,4(a5)
    8000560e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005610:	4709                	li	a4,2
    80005612:	12e79963          	bne	a5,a4,80005744 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005616:	100017b7          	lui	a5,0x10001
    8000561a:	479c                	lw	a5,8(a5)
    8000561c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000561e:	12e79363          	bne	a5,a4,80005744 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005622:	100017b7          	lui	a5,0x10001
    80005626:	47d8                	lw	a4,12(a5)
    80005628:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000562a:	554d47b7          	lui	a5,0x554d4
    8000562e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005632:	10f71963          	bne	a4,a5,80005744 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005636:	100017b7          	lui	a5,0x10001
    8000563a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000563e:	4705                	li	a4,1
    80005640:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005642:	470d                	li	a4,3
    80005644:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005646:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005648:	c7ffe737          	lui	a4,0xc7ffe
    8000564c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbd787>
    80005650:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005652:	2701                	sext.w	a4,a4
    80005654:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005656:	472d                	li	a4,11
    80005658:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000565a:	5bbc                	lw	a5,112(a5)
    8000565c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005660:	8ba1                	andi	a5,a5,8
    80005662:	0e078763          	beqz	a5,80005750 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005666:	100017b7          	lui	a5,0x10001
    8000566a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000566e:	43fc                	lw	a5,68(a5)
    80005670:	2781                	sext.w	a5,a5
    80005672:	0e079563          	bnez	a5,8000575c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005676:	100017b7          	lui	a5,0x10001
    8000567a:	5bdc                	lw	a5,52(a5)
    8000567c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000567e:	0e078563          	beqz	a5,80005768 <virtio_disk_init+0x194>
  if(max < NUM)
    80005682:	471d                	li	a4,7
    80005684:	0ef77863          	bgeu	a4,a5,80005774 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005688:	c78fb0ef          	jal	ra,80000b00 <kalloc>
    8000568c:	0023c497          	auipc	s1,0x23c
    80005690:	80c48493          	addi	s1,s1,-2036 # 80240e98 <disk>
    80005694:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005696:	c6afb0ef          	jal	ra,80000b00 <kalloc>
    8000569a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000569c:	c64fb0ef          	jal	ra,80000b00 <kalloc>
    800056a0:	87aa                	mv	a5,a0
    800056a2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800056a4:	6088                	ld	a0,0(s1)
    800056a6:	cd69                	beqz	a0,80005780 <virtio_disk_init+0x1ac>
    800056a8:	0023b717          	auipc	a4,0x23b
    800056ac:	7f873703          	ld	a4,2040(a4) # 80240ea0 <disk+0x8>
    800056b0:	cb61                	beqz	a4,80005780 <virtio_disk_init+0x1ac>
    800056b2:	c7f9                	beqz	a5,80005780 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800056b4:	6605                	lui	a2,0x1
    800056b6:	4581                	li	a1,0
    800056b8:	e84fb0ef          	jal	ra,80000d3c <memset>
  memset(disk.avail, 0, PGSIZE);
    800056bc:	0023b497          	auipc	s1,0x23b
    800056c0:	7dc48493          	addi	s1,s1,2012 # 80240e98 <disk>
    800056c4:	6605                	lui	a2,0x1
    800056c6:	4581                	li	a1,0
    800056c8:	6488                	ld	a0,8(s1)
    800056ca:	e72fb0ef          	jal	ra,80000d3c <memset>
  memset(disk.used, 0, PGSIZE);
    800056ce:	6605                	lui	a2,0x1
    800056d0:	4581                	li	a1,0
    800056d2:	6888                	ld	a0,16(s1)
    800056d4:	e68fb0ef          	jal	ra,80000d3c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800056d8:	100017b7          	lui	a5,0x10001
    800056dc:	4721                	li	a4,8
    800056de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800056e0:	4098                	lw	a4,0(s1)
    800056e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800056e6:	40d8                	lw	a4,4(s1)
    800056e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800056ec:	6498                	ld	a4,8(s1)
    800056ee:	0007069b          	sext.w	a3,a4
    800056f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800056f6:	9701                	srai	a4,a4,0x20
    800056f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800056fc:	6898                	ld	a4,16(s1)
    800056fe:	0007069b          	sext.w	a3,a4
    80005702:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005706:	9701                	srai	a4,a4,0x20
    80005708:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000570c:	4705                	li	a4,1
    8000570e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005710:	00e48c23          	sb	a4,24(s1)
    80005714:	00e48ca3          	sb	a4,25(s1)
    80005718:	00e48d23          	sb	a4,26(s1)
    8000571c:	00e48da3          	sb	a4,27(s1)
    80005720:	00e48e23          	sb	a4,28(s1)
    80005724:	00e48ea3          	sb	a4,29(s1)
    80005728:	00e48f23          	sb	a4,30(s1)
    8000572c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005730:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005734:	0727a823          	sw	s2,112(a5)
}
    80005738:	60e2                	ld	ra,24(sp)
    8000573a:	6442                	ld	s0,16(sp)
    8000573c:	64a2                	ld	s1,8(sp)
    8000573e:	6902                	ld	s2,0(sp)
    80005740:	6105                	addi	sp,sp,32
    80005742:	8082                	ret
    panic("could not find virtio disk");
    80005744:	00002517          	auipc	a0,0x2
    80005748:	06c50513          	addi	a0,a0,108 # 800077b0 <syscalls+0x360>
    8000574c:	81efb0ef          	jal	ra,8000076a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005750:	00002517          	auipc	a0,0x2
    80005754:	08050513          	addi	a0,a0,128 # 800077d0 <syscalls+0x380>
    80005758:	812fb0ef          	jal	ra,8000076a <panic>
    panic("virtio disk should not be ready");
    8000575c:	00002517          	auipc	a0,0x2
    80005760:	09450513          	addi	a0,a0,148 # 800077f0 <syscalls+0x3a0>
    80005764:	806fb0ef          	jal	ra,8000076a <panic>
    panic("virtio disk has no queue 0");
    80005768:	00002517          	auipc	a0,0x2
    8000576c:	0a850513          	addi	a0,a0,168 # 80007810 <syscalls+0x3c0>
    80005770:	ffbfa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk max queue too short");
    80005774:	00002517          	auipc	a0,0x2
    80005778:	0bc50513          	addi	a0,a0,188 # 80007830 <syscalls+0x3e0>
    8000577c:	feffa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk kalloc");
    80005780:	00002517          	auipc	a0,0x2
    80005784:	0d050513          	addi	a0,a0,208 # 80007850 <syscalls+0x400>
    80005788:	fe3fa0ef          	jal	ra,8000076a <panic>

000000008000578c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000578c:	7119                	addi	sp,sp,-128
    8000578e:	fc86                	sd	ra,120(sp)
    80005790:	f8a2                	sd	s0,112(sp)
    80005792:	f4a6                	sd	s1,104(sp)
    80005794:	f0ca                	sd	s2,96(sp)
    80005796:	ecce                	sd	s3,88(sp)
    80005798:	e8d2                	sd	s4,80(sp)
    8000579a:	e4d6                	sd	s5,72(sp)
    8000579c:	e0da                	sd	s6,64(sp)
    8000579e:	fc5e                	sd	s7,56(sp)
    800057a0:	f862                	sd	s8,48(sp)
    800057a2:	f466                	sd	s9,40(sp)
    800057a4:	f06a                	sd	s10,32(sp)
    800057a6:	ec6e                	sd	s11,24(sp)
    800057a8:	0100                	addi	s0,sp,128
    800057aa:	8aaa                	mv	s5,a0
    800057ac:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800057ae:	00c52d03          	lw	s10,12(a0)
    800057b2:	001d1d1b          	slliw	s10,s10,0x1
    800057b6:	1d02                	slli	s10,s10,0x20
    800057b8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800057bc:	0023c517          	auipc	a0,0x23c
    800057c0:	80450513          	addi	a0,a0,-2044 # 80240fc0 <disk+0x128>
    800057c4:	ca4fb0ef          	jal	ra,80000c68 <acquire>
  for(int i = 0; i < 3; i++){
    800057c8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800057ca:	44a1                	li	s1,8
      disk.free[i] = 0;
    800057cc:	0023bb97          	auipc	s7,0x23b
    800057d0:	6ccb8b93          	addi	s7,s7,1740 # 80240e98 <disk>
  for(int i = 0; i < 3; i++){
    800057d4:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800057d6:	0023bc97          	auipc	s9,0x23b
    800057da:	7eac8c93          	addi	s9,s9,2026 # 80240fc0 <disk+0x128>
    800057de:	a8a9                	j	80005838 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    800057e0:	00fb8733          	add	a4,s7,a5
    800057e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800057e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800057ea:	0207c563          	bltz	a5,80005814 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800057ee:	2905                	addiw	s2,s2,1
    800057f0:	0611                	addi	a2,a2,4
    800057f2:	05690863          	beq	s2,s6,80005842 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    800057f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800057f8:	0023b717          	auipc	a4,0x23b
    800057fc:	6a070713          	addi	a4,a4,1696 # 80240e98 <disk>
    80005800:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005802:	01874683          	lbu	a3,24(a4)
    80005806:	fee9                	bnez	a3,800057e0 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005808:	2785                	addiw	a5,a5,1
    8000580a:	0705                	addi	a4,a4,1
    8000580c:	fe979be3          	bne	a5,s1,80005802 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005810:	57fd                	li	a5,-1
    80005812:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005814:	01205b63          	blez	s2,8000582a <virtio_disk_rw+0x9e>
    80005818:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000581a:	000a2503          	lw	a0,0(s4)
    8000581e:	d41ff0ef          	jal	ra,8000555e <free_desc>
      for(int j = 0; j < i; j++)
    80005822:	2d85                	addiw	s11,s11,1
    80005824:	0a11                	addi	s4,s4,4
    80005826:	ffb91ae3          	bne	s2,s11,8000581a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000582a:	85e6                	mv	a1,s9
    8000582c:	0023b517          	auipc	a0,0x23b
    80005830:	68450513          	addi	a0,a0,1668 # 80240eb0 <disk+0x18>
    80005834:	87ffc0ef          	jal	ra,800020b2 <sleep>
  for(int i = 0; i < 3; i++){
    80005838:	f8040a13          	addi	s4,s0,-128
{
    8000583c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000583e:	894e                	mv	s2,s3
    80005840:	bf5d                	j	800057f6 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005842:	f8042583          	lw	a1,-128(s0)
    80005846:	00a58793          	addi	a5,a1,10
    8000584a:	0792                	slli	a5,a5,0x4

  if(write)
    8000584c:	0023b617          	auipc	a2,0x23b
    80005850:	64c60613          	addi	a2,a2,1612 # 80240e98 <disk>
    80005854:	00f60733          	add	a4,a2,a5
    80005858:	018036b3          	snez	a3,s8
    8000585c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000585e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005862:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005866:	f6078693          	addi	a3,a5,-160
    8000586a:	6218                	ld	a4,0(a2)
    8000586c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000586e:	00878513          	addi	a0,a5,8
    80005872:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005874:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005876:	6208                	ld	a0,0(a2)
    80005878:	96aa                	add	a3,a3,a0
    8000587a:	4741                	li	a4,16
    8000587c:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000587e:	4705                	li	a4,1
    80005880:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005884:	f8442703          	lw	a4,-124(s0)
    80005888:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000588c:	0712                	slli	a4,a4,0x4
    8000588e:	953a                	add	a0,a0,a4
    80005890:	058a8693          	addi	a3,s5,88
    80005894:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80005896:	6208                	ld	a0,0(a2)
    80005898:	972a                	add	a4,a4,a0
    8000589a:	40000693          	li	a3,1024
    8000589e:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800058a0:	001c3c13          	seqz	s8,s8
    800058a4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800058a6:	001c6c13          	ori	s8,s8,1
    800058aa:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800058ae:	f8842603          	lw	a2,-120(s0)
    800058b2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800058b6:	0023b697          	auipc	a3,0x23b
    800058ba:	5e268693          	addi	a3,a3,1506 # 80240e98 <disk>
    800058be:	00258713          	addi	a4,a1,2
    800058c2:	0712                	slli	a4,a4,0x4
    800058c4:	9736                	add	a4,a4,a3
    800058c6:	587d                	li	a6,-1
    800058c8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800058cc:	0612                	slli	a2,a2,0x4
    800058ce:	9532                	add	a0,a0,a2
    800058d0:	f9078793          	addi	a5,a5,-112
    800058d4:	97b6                	add	a5,a5,a3
    800058d6:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800058d8:	629c                	ld	a5,0(a3)
    800058da:	97b2                	add	a5,a5,a2
    800058dc:	4605                	li	a2,1
    800058de:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800058e0:	4509                	li	a0,2
    800058e2:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800058e6:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800058ea:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800058ee:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800058f2:	6698                	ld	a4,8(a3)
    800058f4:	00275783          	lhu	a5,2(a4)
    800058f8:	8b9d                	andi	a5,a5,7
    800058fa:	0786                	slli	a5,a5,0x1
    800058fc:	97ba                	add	a5,a5,a4
    800058fe:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005902:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005906:	6698                	ld	a4,8(a3)
    80005908:	00275783          	lhu	a5,2(a4)
    8000590c:	2785                	addiw	a5,a5,1
    8000590e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005912:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005916:	100017b7          	lui	a5,0x10001
    8000591a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000591e:	004aa783          	lw	a5,4(s5)
    80005922:	00c79f63          	bne	a5,a2,80005940 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005926:	0023b917          	auipc	s2,0x23b
    8000592a:	69a90913          	addi	s2,s2,1690 # 80240fc0 <disk+0x128>
  while(b->disk == 1) {
    8000592e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005930:	85ca                	mv	a1,s2
    80005932:	8556                	mv	a0,s5
    80005934:	f7efc0ef          	jal	ra,800020b2 <sleep>
  while(b->disk == 1) {
    80005938:	004aa783          	lw	a5,4(s5)
    8000593c:	fe978ae3          	beq	a5,s1,80005930 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005940:	f8042903          	lw	s2,-128(s0)
    80005944:	00290793          	addi	a5,s2,2
    80005948:	00479713          	slli	a4,a5,0x4
    8000594c:	0023b797          	auipc	a5,0x23b
    80005950:	54c78793          	addi	a5,a5,1356 # 80240e98 <disk>
    80005954:	97ba                	add	a5,a5,a4
    80005956:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000595a:	0023b997          	auipc	s3,0x23b
    8000595e:	53e98993          	addi	s3,s3,1342 # 80240e98 <disk>
    80005962:	00491713          	slli	a4,s2,0x4
    80005966:	0009b783          	ld	a5,0(s3)
    8000596a:	97ba                	add	a5,a5,a4
    8000596c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005970:	854a                	mv	a0,s2
    80005972:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005976:	be9ff0ef          	jal	ra,8000555e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000597a:	8885                	andi	s1,s1,1
    8000597c:	f0fd                	bnez	s1,80005962 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000597e:	0023b517          	auipc	a0,0x23b
    80005982:	64250513          	addi	a0,a0,1602 # 80240fc0 <disk+0x128>
    80005986:	b7afb0ef          	jal	ra,80000d00 <release>
}
    8000598a:	70e6                	ld	ra,120(sp)
    8000598c:	7446                	ld	s0,112(sp)
    8000598e:	74a6                	ld	s1,104(sp)
    80005990:	7906                	ld	s2,96(sp)
    80005992:	69e6                	ld	s3,88(sp)
    80005994:	6a46                	ld	s4,80(sp)
    80005996:	6aa6                	ld	s5,72(sp)
    80005998:	6b06                	ld	s6,64(sp)
    8000599a:	7be2                	ld	s7,56(sp)
    8000599c:	7c42                	ld	s8,48(sp)
    8000599e:	7ca2                	ld	s9,40(sp)
    800059a0:	7d02                	ld	s10,32(sp)
    800059a2:	6de2                	ld	s11,24(sp)
    800059a4:	6109                	addi	sp,sp,128
    800059a6:	8082                	ret

00000000800059a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800059a8:	1101                	addi	sp,sp,-32
    800059aa:	ec06                	sd	ra,24(sp)
    800059ac:	e822                	sd	s0,16(sp)
    800059ae:	e426                	sd	s1,8(sp)
    800059b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800059b2:	0023b497          	auipc	s1,0x23b
    800059b6:	4e648493          	addi	s1,s1,1254 # 80240e98 <disk>
    800059ba:	0023b517          	auipc	a0,0x23b
    800059be:	60650513          	addi	a0,a0,1542 # 80240fc0 <disk+0x128>
    800059c2:	aa6fb0ef          	jal	ra,80000c68 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800059c6:	10001737          	lui	a4,0x10001
    800059ca:	533c                	lw	a5,96(a4)
    800059cc:	8b8d                	andi	a5,a5,3
    800059ce:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800059d0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800059d4:	689c                	ld	a5,16(s1)
    800059d6:	0204d703          	lhu	a4,32(s1)
    800059da:	0027d783          	lhu	a5,2(a5)
    800059de:	04f70663          	beq	a4,a5,80005a2a <virtio_disk_intr+0x82>
    __sync_synchronize();
    800059e2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800059e6:	6898                	ld	a4,16(s1)
    800059e8:	0204d783          	lhu	a5,32(s1)
    800059ec:	8b9d                	andi	a5,a5,7
    800059ee:	078e                	slli	a5,a5,0x3
    800059f0:	97ba                	add	a5,a5,a4
    800059f2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800059f4:	00278713          	addi	a4,a5,2
    800059f8:	0712                	slli	a4,a4,0x4
    800059fa:	9726                	add	a4,a4,s1
    800059fc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005a00:	e321                	bnez	a4,80005a40 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a02:	0789                	addi	a5,a5,2
    80005a04:	0792                	slli	a5,a5,0x4
    80005a06:	97a6                	add	a5,a5,s1
    80005a08:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a0a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a0e:	ef0fc0ef          	jal	ra,800020fe <wakeup>

    disk.used_idx += 1;
    80005a12:	0204d783          	lhu	a5,32(s1)
    80005a16:	2785                	addiw	a5,a5,1
    80005a18:	17c2                	slli	a5,a5,0x30
    80005a1a:	93c1                	srli	a5,a5,0x30
    80005a1c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005a20:	6898                	ld	a4,16(s1)
    80005a22:	00275703          	lhu	a4,2(a4)
    80005a26:	faf71ee3          	bne	a4,a5,800059e2 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005a2a:	0023b517          	auipc	a0,0x23b
    80005a2e:	59650513          	addi	a0,a0,1430 # 80240fc0 <disk+0x128>
    80005a32:	acefb0ef          	jal	ra,80000d00 <release>
}
    80005a36:	60e2                	ld	ra,24(sp)
    80005a38:	6442                	ld	s0,16(sp)
    80005a3a:	64a2                	ld	s1,8(sp)
    80005a3c:	6105                	addi	sp,sp,32
    80005a3e:	8082                	ret
      panic("virtio_disk_intr status");
    80005a40:	00002517          	auipc	a0,0x2
    80005a44:	e2850513          	addi	a0,a0,-472 # 80007868 <syscalls+0x418>
    80005a48:	d23fa0ef          	jal	ra,8000076a <panic>
	...

0000000080006000 <_trampoline>:
        # user page table.
        #

        # save user a0 in sscratch so
        # a0 can be used to get at TRAPFRAME.
        csrw sscratch, a0
    80006000:	14051073          	csrw	sscratch,a0

        # each process has a separate p->trapframe memory area,
        # but it's mapped to the same virtual address
        # (TRAPFRAME) in every process's user page table.
        li a0, TRAPFRAME
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1
    8000600a:	0536                	slli	a0,a0,0xd
        
        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
    8000600c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
        sd sp, 48(a0)
    80006010:	02253823          	sd	sp,48(a0)
        sd gp, 56(a0)
    80006014:	02353c23          	sd	gp,56(a0)
        sd tp, 64(a0)
    80006018:	04453023          	sd	tp,64(a0)
        sd t0, 72(a0)
    8000601c:	04553423          	sd	t0,72(a0)
        sd t1, 80(a0)
    80006020:	04653823          	sd	t1,80(a0)
        sd t2, 88(a0)
    80006024:	04753c23          	sd	t2,88(a0)
        sd s0, 96(a0)
    80006028:	f120                	sd	s0,96(a0)
        sd s1, 104(a0)
    8000602a:	f524                	sd	s1,104(a0)
        sd a1, 120(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
        sd a2, 128(a0)
    8000602e:	e150                	sd	a2,128(a0)
        sd a3, 136(a0)
    80006030:	e554                	sd	a3,136(a0)
        sd a4, 144(a0)
    80006032:	e958                	sd	a4,144(a0)
        sd a5, 152(a0)
    80006034:	ed5c                	sd	a5,152(a0)
        sd a6, 160(a0)
    80006036:	0b053023          	sd	a6,160(a0)
        sd a7, 168(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
        sd s2, 176(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
        sd s3, 184(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
        sd s4, 192(a0)
    80006046:	0d453023          	sd	s4,192(a0)
        sd s5, 200(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
        sd s6, 208(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
        sd s7, 216(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
        sd s8, 224(a0)
    80006056:	0f853023          	sd	s8,224(a0)
        sd s9, 232(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
        sd s10, 240(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
        sd s11, 248(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
        sd t3, 256(a0)
    80006066:	11c53023          	sd	t3,256(a0)
        sd t4, 264(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
        sd t5, 272(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
        sd t6, 280(a0)
    80006072:	11f53c23          	sd	t6,280(a0)

	# save the user a0 in p->trapframe->a0
        csrr t0, sscratch
    80006076:	140022f3          	csrr	t0,sscratch
        sd t0, 112(a0)
    8000607a:	06553823          	sd	t0,112(a0)

        # initialize kernel stack pointer, from p->trapframe->kernel_sp
        ld sp, 8(a0)
    8000607e:	00853103          	ld	sp,8(a0)

        # make tp hold the current hartid, from p->trapframe->kernel_hartid
        ld tp, 32(a0)
    80006082:	02053203          	ld	tp,32(a0)

        # load the address of usertrap(), from p->trapframe->kernel_trap
        ld t0, 16(a0)
    80006086:	01053283          	ld	t0,16(a0)

        # fetch the kernel page table address, from p->trapframe->kernel_satp.
        ld t1, 0(a0)
    8000608a:	00053303          	ld	t1,0(a0)

        # wait for any previous memory operations to complete, so that
        # they use the user page table.
        sfence.vma zero, zero
    8000608e:	12000073          	sfence.vma

        # install the kernel page table.
        csrw satp, t1
    80006092:	18031073          	csrw	satp,t1

        # flush now-stale user entries from the TLB.
        sfence.vma zero, zero
    80006096:	12000073          	sfence.vma

        # call usertrap()
        jalr t0
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
userret:
        # usertrap() returns here, with user satp in a0.
        # return from kernel to user.

        # switch to the user page table.
        sfence.vma zero, zero
    8000609c:	12000073          	sfence.vma
        csrw satp, a0
    800060a0:	18051073          	csrw	satp,a0
        sfence.vma zero, zero
    800060a4:	12000073          	sfence.vma

        li a0, TRAPFRAME
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1
    800060ae:	0536                	slli	a0,a0,0xd

        # restore all but a0 from TRAPFRAME
        ld ra, 40(a0)
    800060b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
        ld sp, 48(a0)
    800060b4:	03053103          	ld	sp,48(a0)
        ld gp, 56(a0)
    800060b8:	03853183          	ld	gp,56(a0)
        ld tp, 64(a0)
    800060bc:	04053203          	ld	tp,64(a0)
        ld t0, 72(a0)
    800060c0:	04853283          	ld	t0,72(a0)
        ld t1, 80(a0)
    800060c4:	05053303          	ld	t1,80(a0)
        ld t2, 88(a0)
    800060c8:	05853383          	ld	t2,88(a0)
        ld s0, 96(a0)
    800060cc:	7120                	ld	s0,96(a0)
        ld s1, 104(a0)
    800060ce:	7524                	ld	s1,104(a0)
        ld a1, 120(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
        ld a2, 128(a0)
    800060d2:	6150                	ld	a2,128(a0)
        ld a3, 136(a0)
    800060d4:	6554                	ld	a3,136(a0)
        ld a4, 144(a0)
    800060d6:	6958                	ld	a4,144(a0)
        ld a5, 152(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
        ld a6, 160(a0)
    800060da:	0a053803          	ld	a6,160(a0)
        ld a7, 168(a0)
    800060de:	0a853883          	ld	a7,168(a0)
        ld s2, 176(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
        ld s3, 184(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
        ld s4, 192(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
        ld s5, 200(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
        ld s6, 208(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
        ld s7, 216(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
        ld s8, 224(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
        ld s9, 232(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
        ld s10, 240(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
        ld s11, 248(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
        ld t3, 256(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
        ld t4, 264(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
        ld t5, 272(a0)
    80006112:	11053f03          	ld	t5,272(a0)
        ld t6, 280(a0)
    80006116:	11853f83          	ld	t6,280(a0)

	# restore user a0
        ld a0, 112(a0)
    8000611a:	7928                	ld	a0,112(a0)
        
        # return to user mode and user pc.
        # usertrapret() set up sstatus and sepc.
        sret
    8000611c:	10200073          	sret
	...
