
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
    800000ea:	3a8020ef          	jal	ra,80002492 <either_copyin>
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
    80000188:	19c020ef          	jal	ra,80002324 <killed>
    8000018c:	e125                	bnez	a0,800001ec <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    8000018e:	85a6                	mv	a1,s1
    80000190:	854a                	mv	a0,s2
    80000192:	543010ef          	jal	ra,80001ed4 <sleep>
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
    800001ca:	27e020ef          	jal	ra,80002448 <either_copyout>
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
    8000028a:	252020ef          	jal	ra,800024dc <procdump>
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
    800003c6:	35b010ef          	jal	ra,80001f20 <wakeup>
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
    80000872:	662010ef          	jal	ra,80001ed4 <sleep>
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
    80000980:	5a0010ef          	jal	ra,80001f20 <wakeup>
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
    80000f14:	700010ef          	jal	ra,80002614 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f18:	5fc040ef          	jal	ra,80005514 <plicinithart>
  }

  scheduler();        
    80000f1c:	166010ef          	jal	ra,80002082 <scheduler>
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
    80000f5c:	694010ef          	jal	ra,800025f0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f60:	6b4010ef          	jal	ra,80002614 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	59a040ef          	jal	ra,800054fe <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f68:	5ac040ef          	jal	ra,80005514 <plicinithart>
    binit();         // buffer cache
    80000f6c:	54f010ef          	jal	ra,80002cba <binit>
    iinit();         // inode table
    80000f70:	2c2020ef          	jal	ra,80003232 <iinit>
    fileinit();      // file table
    80000f74:	1a2030ef          	jal	ra,80004116 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f78:	68c040ef          	jal	ra,80005604 <virtio_disk_init>
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
    800019ae:	535010ef          	jal	ra,800036e2 <fsinit>

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
    800019d2:	5b9020ef          	jal	ra,8000478a <kexec>
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
    800019e4:	449000ef          	jal	ra,8000262c <prepare_return>
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
    80001c54:	78d010ef          	jal	ra,80003be0 <namei>
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
    80001d6e:	42a020ef          	jal	ra,80004198 <filedup>
    80001d72:	00a93023          	sd	a0,0(s2)
    80001d76:	b7f5                	j	80001d62 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001d78:	150ab503          	ld	a0,336(s5)
    80001d7c:	640010ef          	jal	ra,800033bc <idup>
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

0000000080001dee <sched>:
{
    80001dee:	7179                	addi	sp,sp,-48
    80001df0:	f406                	sd	ra,40(sp)
    80001df2:	f022                	sd	s0,32(sp)
    80001df4:	ec26                	sd	s1,24(sp)
    80001df6:	e84a                	sd	s2,16(sp)
    80001df8:	e44e                	sd	s3,8(sp)
    80001dfa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dfc:	b63ff0ef          	jal	ra,8000195e <myproc>
    80001e00:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e02:	dfdfe0ef          	jal	ra,80000bfe <holding>
    80001e06:	c92d                	beqz	a0,80001e78 <sched+0x8a>
    80001e08:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001e0a:	2781                	sext.w	a5,a5
    80001e0c:	079e                	slli	a5,a5,0x7
    80001e0e:	0022e717          	auipc	a4,0x22e
    80001e12:	bba70713          	addi	a4,a4,-1094 # 8022f9c8 <pid_lock>
    80001e16:	97ba                	add	a5,a5,a4
    80001e18:	0a87a703          	lw	a4,168(a5)
    80001e1c:	4785                	li	a5,1
    80001e1e:	06f71363          	bne	a4,a5,80001e84 <sched+0x96>
  if(p->state == RUNNING)
    80001e22:	4c98                	lw	a4,24(s1)
    80001e24:	4791                	li	a5,4
    80001e26:	06f70563          	beq	a4,a5,80001e90 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e2a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e2e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e30:	e7b5                	bnez	a5,80001e9c <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e32:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e34:	0022e917          	auipc	s2,0x22e
    80001e38:	b9490913          	addi	s2,s2,-1132 # 8022f9c8 <pid_lock>
    80001e3c:	2781                	sext.w	a5,a5
    80001e3e:	079e                	slli	a5,a5,0x7
    80001e40:	97ca                	add	a5,a5,s2
    80001e42:	0ac7a983          	lw	s3,172(a5)
    80001e46:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e48:	2781                	sext.w	a5,a5
    80001e4a:	079e                	slli	a5,a5,0x7
    80001e4c:	0022e597          	auipc	a1,0x22e
    80001e50:	bb458593          	addi	a1,a1,-1100 # 8022fa00 <cpus+0x8>
    80001e54:	95be                	add	a1,a1,a5
    80001e56:	06048513          	addi	a0,s1,96
    80001e5a:	72c000ef          	jal	ra,80002586 <swtch>
    80001e5e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e60:	2781                	sext.w	a5,a5
    80001e62:	079e                	slli	a5,a5,0x7
    80001e64:	97ca                	add	a5,a5,s2
    80001e66:	0b37a623          	sw	s3,172(a5)
}
    80001e6a:	70a2                	ld	ra,40(sp)
    80001e6c:	7402                	ld	s0,32(sp)
    80001e6e:	64e2                	ld	s1,24(sp)
    80001e70:	6942                	ld	s2,16(sp)
    80001e72:	69a2                	ld	s3,8(sp)
    80001e74:	6145                	addi	sp,sp,48
    80001e76:	8082                	ret
    panic("sched p->lock");
    80001e78:	00005517          	auipc	a0,0x5
    80001e7c:	35850513          	addi	a0,a0,856 # 800071d0 <digits+0x198>
    80001e80:	8ebfe0ef          	jal	ra,8000076a <panic>
    panic("sched locks");
    80001e84:	00005517          	auipc	a0,0x5
    80001e88:	35c50513          	addi	a0,a0,860 # 800071e0 <digits+0x1a8>
    80001e8c:	8dffe0ef          	jal	ra,8000076a <panic>
    panic("sched RUNNING");
    80001e90:	00005517          	auipc	a0,0x5
    80001e94:	36050513          	addi	a0,a0,864 # 800071f0 <digits+0x1b8>
    80001e98:	8d3fe0ef          	jal	ra,8000076a <panic>
    panic("sched interruptible");
    80001e9c:	00005517          	auipc	a0,0x5
    80001ea0:	36450513          	addi	a0,a0,868 # 80007200 <digits+0x1c8>
    80001ea4:	8c7fe0ef          	jal	ra,8000076a <panic>

0000000080001ea8 <yield>:
{
    80001ea8:	1101                	addi	sp,sp,-32
    80001eaa:	ec06                	sd	ra,24(sp)
    80001eac:	e822                	sd	s0,16(sp)
    80001eae:	e426                	sd	s1,8(sp)
    80001eb0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001eb2:	aadff0ef          	jal	ra,8000195e <myproc>
    80001eb6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001eb8:	db1fe0ef          	jal	ra,80000c68 <acquire>
  p->state = RUNNABLE;
    80001ebc:	478d                	li	a5,3
    80001ebe:	cc9c                	sw	a5,24(s1)
  sched();
    80001ec0:	f2fff0ef          	jal	ra,80001dee <sched>
  release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	e3bfe0ef          	jal	ra,80000d00 <release>
}
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6105                	addi	sp,sp,32
    80001ed2:	8082                	ret

0000000080001ed4 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ed4:	7179                	addi	sp,sp,-48
    80001ed6:	f406                	sd	ra,40(sp)
    80001ed8:	f022                	sd	s0,32(sp)
    80001eda:	ec26                	sd	s1,24(sp)
    80001edc:	e84a                	sd	s2,16(sp)
    80001ede:	e44e                	sd	s3,8(sp)
    80001ee0:	1800                	addi	s0,sp,48
    80001ee2:	89aa                	mv	s3,a0
    80001ee4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001ee6:	a79ff0ef          	jal	ra,8000195e <myproc>
    80001eea:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001eec:	d7dfe0ef          	jal	ra,80000c68 <acquire>
  release(lk);
    80001ef0:	854a                	mv	a0,s2
    80001ef2:	e0ffe0ef          	jal	ra,80000d00 <release>

  // Go to sleep.
  p->chan = chan;
    80001ef6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001efa:	4789                	li	a5,2
    80001efc:	cc9c                	sw	a5,24(s1)

  sched();
    80001efe:	ef1ff0ef          	jal	ra,80001dee <sched>

  // Tidy up.
  p->chan = 0;
    80001f02:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	df9fe0ef          	jal	ra,80000d00 <release>
  acquire(lk);
    80001f0c:	854a                	mv	a0,s2
    80001f0e:	d5bfe0ef          	jal	ra,80000c68 <acquire>
}
    80001f12:	70a2                	ld	ra,40(sp)
    80001f14:	7402                	ld	s0,32(sp)
    80001f16:	64e2                	ld	s1,24(sp)
    80001f18:	6942                	ld	s2,16(sp)
    80001f1a:	69a2                	ld	s3,8(sp)
    80001f1c:	6145                	addi	sp,sp,48
    80001f1e:	8082                	ret

0000000080001f20 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f20:	7139                	addi	sp,sp,-64
    80001f22:	fc06                	sd	ra,56(sp)
    80001f24:	f822                	sd	s0,48(sp)
    80001f26:	f426                	sd	s1,40(sp)
    80001f28:	f04a                	sd	s2,32(sp)
    80001f2a:	ec4e                	sd	s3,24(sp)
    80001f2c:	e852                	sd	s4,16(sp)
    80001f2e:	e456                	sd	s5,8(sp)
    80001f30:	0080                	addi	s0,sp,64
    80001f32:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	0022e497          	auipc	s1,0x22e
    80001f38:	ec448493          	addi	s1,s1,-316 # 8022fdf8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f3c:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f3e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	00234917          	auipc	s2,0x234
    80001f44:	cb890913          	addi	s2,s2,-840 # 80235bf8 <tickslock>
    80001f48:	a801                	j	80001f58 <wakeup+0x38>
      }
      release(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	db5fe0ef          	jal	ra,80000d00 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f50:	17848493          	addi	s1,s1,376
    80001f54:	03248263          	beq	s1,s2,80001f78 <wakeup+0x58>
    if(p != myproc()){
    80001f58:	a07ff0ef          	jal	ra,8000195e <myproc>
    80001f5c:	fea48ae3          	beq	s1,a0,80001f50 <wakeup+0x30>
      acquire(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	d07fe0ef          	jal	ra,80000c68 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001f66:	4c9c                	lw	a5,24(s1)
    80001f68:	ff3791e3          	bne	a5,s3,80001f4a <wakeup+0x2a>
    80001f6c:	709c                	ld	a5,32(s1)
    80001f6e:	fd479ee3          	bne	a5,s4,80001f4a <wakeup+0x2a>
        p->state = RUNNABLE;
    80001f72:	0154ac23          	sw	s5,24(s1)
    80001f76:	bfd1                	j	80001f4a <wakeup+0x2a>
    }
  }
}
    80001f78:	70e2                	ld	ra,56(sp)
    80001f7a:	7442                	ld	s0,48(sp)
    80001f7c:	74a2                	ld	s1,40(sp)
    80001f7e:	7902                	ld	s2,32(sp)
    80001f80:	69e2                	ld	s3,24(sp)
    80001f82:	6a42                	ld	s4,16(sp)
    80001f84:	6aa2                	ld	s5,8(sp)
    80001f86:	6121                	addi	sp,sp,64
    80001f88:	8082                	ret

0000000080001f8a <reparent>:
{
    80001f8a:	7179                	addi	sp,sp,-48
    80001f8c:	f406                	sd	ra,40(sp)
    80001f8e:	f022                	sd	s0,32(sp)
    80001f90:	ec26                	sd	s1,24(sp)
    80001f92:	e84a                	sd	s2,16(sp)
    80001f94:	e44e                	sd	s3,8(sp)
    80001f96:	e052                	sd	s4,0(sp)
    80001f98:	1800                	addi	s0,sp,48
    80001f9a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f9c:	0022e497          	auipc	s1,0x22e
    80001fa0:	e5c48493          	addi	s1,s1,-420 # 8022fdf8 <proc>
      pp->parent = initproc;
    80001fa4:	00006a17          	auipc	s4,0x6
    80001fa8:	914a0a13          	addi	s4,s4,-1772 # 800078b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fac:	00234997          	auipc	s3,0x234
    80001fb0:	c4c98993          	addi	s3,s3,-948 # 80235bf8 <tickslock>
    80001fb4:	a029                	j	80001fbe <reparent+0x34>
    80001fb6:	17848493          	addi	s1,s1,376
    80001fba:	01348b63          	beq	s1,s3,80001fd0 <reparent+0x46>
    if(pp->parent == p){
    80001fbe:	7c9c                	ld	a5,56(s1)
    80001fc0:	ff279be3          	bne	a5,s2,80001fb6 <reparent+0x2c>
      pp->parent = initproc;
    80001fc4:	000a3503          	ld	a0,0(s4)
    80001fc8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001fca:	f57ff0ef          	jal	ra,80001f20 <wakeup>
    80001fce:	b7e5                	j	80001fb6 <reparent+0x2c>
}
    80001fd0:	70a2                	ld	ra,40(sp)
    80001fd2:	7402                	ld	s0,32(sp)
    80001fd4:	64e2                	ld	s1,24(sp)
    80001fd6:	6942                	ld	s2,16(sp)
    80001fd8:	69a2                	ld	s3,8(sp)
    80001fda:	6a02                	ld	s4,0(sp)
    80001fdc:	6145                	addi	sp,sp,48
    80001fde:	8082                	ret

0000000080001fe0 <kexit>:
{
    80001fe0:	7179                	addi	sp,sp,-48
    80001fe2:	f406                	sd	ra,40(sp)
    80001fe4:	f022                	sd	s0,32(sp)
    80001fe6:	ec26                	sd	s1,24(sp)
    80001fe8:	e84a                	sd	s2,16(sp)
    80001fea:	e44e                	sd	s3,8(sp)
    80001fec:	e052                	sd	s4,0(sp)
    80001fee:	1800                	addi	s0,sp,48
    80001ff0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001ff2:	96dff0ef          	jal	ra,8000195e <myproc>
    80001ff6:	89aa                	mv	s3,a0
  if(p == initproc)
    80001ff8:	00006797          	auipc	a5,0x6
    80001ffc:	8c07b783          	ld	a5,-1856(a5) # 800078b8 <initproc>
    80002000:	0d050493          	addi	s1,a0,208
    80002004:	15050913          	addi	s2,a0,336
    80002008:	00a79f63          	bne	a5,a0,80002026 <kexit+0x46>
    panic("init exiting");
    8000200c:	00005517          	auipc	a0,0x5
    80002010:	20c50513          	addi	a0,a0,524 # 80007218 <digits+0x1e0>
    80002014:	f56fe0ef          	jal	ra,8000076a <panic>
      fileclose(f);
    80002018:	1c6020ef          	jal	ra,800041de <fileclose>
      p->ofile[fd] = 0;
    8000201c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002020:	04a1                	addi	s1,s1,8
    80002022:	01248563          	beq	s1,s2,8000202c <kexit+0x4c>
    if(p->ofile[fd]){
    80002026:	6088                	ld	a0,0(s1)
    80002028:	f965                	bnez	a0,80002018 <kexit+0x38>
    8000202a:	bfdd                	j	80002020 <kexit+0x40>
  begin_op();
    8000202c:	5a5010ef          	jal	ra,80003dd0 <begin_op>
  iput(p->cwd);
    80002030:	1509b503          	ld	a0,336(s3)
    80002034:	53c010ef          	jal	ra,80003570 <iput>
  end_op();
    80002038:	609010ef          	jal	ra,80003e40 <end_op>
  p->cwd = 0;
    8000203c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002040:	0022e497          	auipc	s1,0x22e
    80002044:	9a048493          	addi	s1,s1,-1632 # 8022f9e0 <wait_lock>
    80002048:	8526                	mv	a0,s1
    8000204a:	c1ffe0ef          	jal	ra,80000c68 <acquire>
  reparent(p);
    8000204e:	854e                	mv	a0,s3
    80002050:	f3bff0ef          	jal	ra,80001f8a <reparent>
  wakeup(p->parent);
    80002054:	0389b503          	ld	a0,56(s3)
    80002058:	ec9ff0ef          	jal	ra,80001f20 <wakeup>
  acquire(&p->lock);
    8000205c:	854e                	mv	a0,s3
    8000205e:	c0bfe0ef          	jal	ra,80000c68 <acquire>
  p->xstate = status;
    80002062:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002066:	4795                	li	a5,5
    80002068:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000206c:	8526                	mv	a0,s1
    8000206e:	c93fe0ef          	jal	ra,80000d00 <release>
  sched();
    80002072:	d7dff0ef          	jal	ra,80001dee <sched>
  panic("zombie exit");
    80002076:	00005517          	auipc	a0,0x5
    8000207a:	1b250513          	addi	a0,a0,434 # 80007228 <digits+0x1f0>
    8000207e:	eecfe0ef          	jal	ra,8000076a <panic>

0000000080002082 <scheduler>:
{
    80002082:	711d                	addi	sp,sp,-96
    80002084:	ec86                	sd	ra,88(sp)
    80002086:	e8a2                	sd	s0,80(sp)
    80002088:	e4a6                	sd	s1,72(sp)
    8000208a:	e0ca                	sd	s2,64(sp)
    8000208c:	fc4e                	sd	s3,56(sp)
    8000208e:	f852                	sd	s4,48(sp)
    80002090:	f456                	sd	s5,40(sp)
    80002092:	f05a                	sd	s6,32(sp)
    80002094:	ec5e                	sd	s7,24(sp)
    80002096:	e862                	sd	s8,16(sp)
    80002098:	e466                	sd	s9,8(sp)
    8000209a:	1080                	addi	s0,sp,96
    8000209c:	8792                	mv	a5,tp
  int id = r_tp();
    8000209e:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020a0:	00779c13          	slli	s8,a5,0x7
    800020a4:	0022e717          	auipc	a4,0x22e
    800020a8:	92470713          	addi	a4,a4,-1756 # 8022f9c8 <pid_lock>
    800020ac:	9762                	add	a4,a4,s8
    800020ae:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &best->context);
    800020b2:	0022e717          	auipc	a4,0x22e
    800020b6:	94e70713          	addi	a4,a4,-1714 # 8022fa00 <cpus+0x8>
    800020ba:	9c3a                	add	s8,s8,a4
    for(p = proc; p < &proc[NPROC]; p++) {
    800020bc:	00234997          	auipc	s3,0x234
    800020c0:	b3c98993          	addi	s3,s3,-1220 # 80235bf8 <tickslock>
      c->proc = best;
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	0022eb97          	auipc	s7,0x22e
    800020ca:	902b8b93          	addi	s7,s7,-1790 # 8022f9c8 <pid_lock>
    800020ce:	9bbe                	add	s7,s7,a5
      ticks++;
    800020d0:	00005b17          	auipc	s6,0x5
    800020d4:	7f0b0b13          	addi	s6,s6,2032 # 800078c0 <ticks>
    800020d8:	a0b9                	j	80002126 <scheduler+0xa4>
      release(&p->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	c25fe0ef          	jal	ra,80000d00 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e0:	17848493          	addi	s1,s1,376
    800020e4:	03348763          	beq	s1,s3,80002112 <scheduler+0x90>
      acquire(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	b7ffe0ef          	jal	ra,80000c68 <acquire>
      if(p->state == RUNNABLE) {
    800020ee:	4c9c                	lw	a5,24(s1)
    800020f0:	ff4795e3          	bne	a5,s4,800020da <scheduler+0x58>
        if(best == 0 || p->priority > best->priority){
    800020f4:	00090d63          	beqz	s2,8000210e <scheduler+0x8c>
    800020f8:	1684a703          	lw	a4,360(s1)
    800020fc:	16892783          	lw	a5,360(s2)
    80002100:	fce7dde3          	bge	a5,a4,800020da <scheduler+0x58>
          if(best) release(&best->lock);
    80002104:	854a                	mv	a0,s2
    80002106:	bfbfe0ef          	jal	ra,80000d00 <release>
    8000210a:	8926                	mv	s2,s1
    8000210c:	bfd1                	j	800020e0 <scheduler+0x5e>
    8000210e:	8926                	mv	s2,s1
    80002110:	bfc1                	j	800020e0 <scheduler+0x5e>
    if(best) {
    80002112:	02091063          	bnez	s2,80002132 <scheduler+0xb0>
    release(&wait_lock);
    80002116:	0022e517          	auipc	a0,0x22e
    8000211a:	8ca50513          	addi	a0,a0,-1846 # 8022f9e0 <wait_lock>
    8000211e:	be3fe0ef          	jal	ra,80000d00 <release>
      asm volatile("wfi");
    80002122:	10500073          	wfi
    acquire(&wait_lock); // must be acquired before any p->lock.
    80002126:	0022ea97          	auipc	s5,0x22e
    8000212a:	8baa8a93          	addi	s5,s5,-1862 # 8022f9e0 <wait_lock>
      if(p->state == RUNNABLE) {
    8000212e:	4a0d                	li	s4,3
    80002130:	a221                	j	80002238 <scheduler+0x1b6>
      for(p = proc; p < &proc[NPROC]; p++){
    80002132:	0022e497          	auipc	s1,0x22e
    80002136:	cc648493          	addi	s1,s1,-826 # 8022fdf8 <proc>
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    8000213a:	06400c93          	li	s9,100
    8000213e:	a811                	j	80002152 <scheduler+0xd0>
    80002140:	1794a423          	sw	s9,360(s1)
          release(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	bbbfe0ef          	jal	ra,80000d00 <release>
      for(p = proc; p < &proc[NPROC]; p++){
    8000214a:	17848493          	addi	s1,s1,376
    8000214e:	03348963          	beq	s1,s3,80002180 <scheduler+0xfe>
        if(p != best){
    80002152:	fe990ce3          	beq	s2,s1,8000214a <scheduler+0xc8>
          acquire(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	b11fe0ef          	jal	ra,80000c68 <acquire>
          if(p->state == RUNNABLE){
    8000215c:	4c9c                	lw	a5,24(s1)
    8000215e:	ff4793e3          	bne	a5,s4,80002144 <scheduler+0xc2>
            p->wait_ticks++;
    80002162:	16c4a783          	lw	a5,364(s1)
    80002166:	2785                	addiw	a5,a5,1
    80002168:	16f4a623          	sw	a5,364(s1)
            p->priority += SCHED_ALPHA;
    8000216c:	1684a783          	lw	a5,360(s1)
    80002170:	2785                	addiw	a5,a5,1
    80002172:	0007871b          	sext.w	a4,a5
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    80002176:	fcecc5e3          	blt	s9,a4,80002140 <scheduler+0xbe>
            p->priority += SCHED_ALPHA;
    8000217a:	16f4a423          	sw	a5,360(s1)
    8000217e:	b7d9                	j	80002144 <scheduler+0xc2>
      printf("sched: pid=%d name=%s pri=%d wait=%d cpu=%d\n",
    80002180:	17092783          	lw	a5,368(s2)
    80002184:	16c92703          	lw	a4,364(s2)
    80002188:	16892683          	lw	a3,360(s2)
    8000218c:	15890613          	addi	a2,s2,344
    80002190:	03092583          	lw	a1,48(s2)
    80002194:	00005517          	auipc	a0,0x5
    80002198:	0a450513          	addi	a0,a0,164 # 80007238 <digits+0x200>
    8000219c:	b08fe0ef          	jal	ra,800004a4 <printf>
      best->state = RUNNING;
    800021a0:	4791                	li	a5,4
    800021a2:	00f92c23          	sw	a5,24(s2)
      c->proc = best;
    800021a6:	032bb823          	sd	s2,48(s7)
      release(&wait_lock);
    800021aa:	8556                	mv	a0,s5
    800021ac:	b55fe0ef          	jal	ra,80000d00 <release>
      swtch(&c->context, &best->context);
    800021b0:	06090593          	addi	a1,s2,96
    800021b4:	8562                	mv	a0,s8
    800021b6:	3d0000ef          	jal	ra,80002586 <swtch>
      acquire(&wait_lock);
    800021ba:	8556                	mv	a0,s5
    800021bc:	aadfe0ef          	jal	ra,80000c68 <acquire>
      best->cpu_ticks++;
    800021c0:	17092783          	lw	a5,368(s2)
    800021c4:	2785                	addiw	a5,a5,1
    800021c6:	16f92823          	sw	a5,368(s2)
      acquire(&tickslock);
    800021ca:	00234517          	auipc	a0,0x234
    800021ce:	a2e50513          	addi	a0,a0,-1490 # 80235bf8 <tickslock>
    800021d2:	a97fe0ef          	jal	ra,80000c68 <acquire>
      ticks++;
    800021d6:	000b2783          	lw	a5,0(s6)
    800021da:	2785                	addiw	a5,a5,1
    800021dc:	00fb2023          	sw	a5,0(s6)
      wakeup(&ticks);
    800021e0:	855a                	mv	a0,s6
    800021e2:	d3fff0ef          	jal	ra,80001f20 <wakeup>
      release(&tickslock);
    800021e6:	00234517          	auipc	a0,0x234
    800021ea:	a1250513          	addi	a0,a0,-1518 # 80235bf8 <tickslock>
    800021ee:	b13fe0ef          	jal	ra,80000d00 <release>
      window_tick++;
    800021f2:	00005717          	auipc	a4,0x5
    800021f6:	6be70713          	addi	a4,a4,1726 # 800078b0 <window_tick.2>
    800021fa:	431c                	lw	a5,0(a4)
    800021fc:	2785                	addiw	a5,a5,1
    800021fe:	0007869b          	sext.w	a3,a5
    80002202:	c31c                	sw	a5,0(a4)
      if(best->cpu_ticks > SCHED_TCPU_MAX){
    80002204:	17092703          	lw	a4,368(s2)
    80002208:	47a9                	li	a5,10
    8000220a:	00e7db63          	bge	a5,a4,80002220 <scheduler+0x19e>
        best->priority -= SCHED_BETA;
    8000220e:	16892783          	lw	a5,360(s2)
    80002212:	37f9                	addiw	a5,a5,-2
    80002214:	0007871b          	sext.w	a4,a5
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80002218:	04074463          	bltz	a4,80002260 <scheduler+0x1de>
        best->priority -= SCHED_BETA;
    8000221c:	16f92423          	sw	a5,360(s2)
      if(window_tick >= SCHED_W){
    80002220:	03100793          	li	a5,49
    80002224:	04d7c163          	blt	a5,a3,80002266 <scheduler+0x1e4>
      c->proc = 0;
    80002228:	020bb823          	sd	zero,48(s7)
      release(&best->lock);
    8000222c:	854a                	mv	a0,s2
    8000222e:	ad3fe0ef          	jal	ra,80000d00 <release>
    release(&wait_lock);
    80002232:	8556                	mv	a0,s5
    80002234:	acdfe0ef          	jal	ra,80000d00 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002238:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002240:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002244:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002248:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000224a:	10079073          	csrw	sstatus,a5
    acquire(&wait_lock); // must be acquired before any p->lock.
    8000224e:	8556                	mv	a0,s5
    80002250:	a19fe0ef          	jal	ra,80000c68 <acquire>
    best = 0;
    80002254:	4901                	li	s2,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002256:	0022e497          	auipc	s1,0x22e
    8000225a:	ba248493          	addi	s1,s1,-1118 # 8022fdf8 <proc>
    8000225e:	b569                	j	800020e8 <scheduler+0x66>
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80002260:	16092423          	sw	zero,360(s2)
    80002264:	bf75                	j	80002220 <scheduler+0x19e>
        window_tick = 0;
    80002266:	00005797          	auipc	a5,0x5
    8000226a:	6407a523          	sw	zero,1610(a5) # 800078b0 <window_tick.2>
        for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0022e497          	auipc	s1,0x22e
    80002272:	b8a48493          	addi	s1,s1,-1142 # 8022fdf8 <proc>
    80002276:	a039                	j	80002284 <scheduler+0x202>
            p->cpu_ticks = 0;
    80002278:	1604a823          	sw	zero,368(s1)
        for(p = proc; p < &proc[NPROC]; p++){
    8000227c:	17848493          	addi	s1,s1,376
    80002280:	fb3484e3          	beq	s1,s3,80002228 <scheduler+0x1a6>
          if(p != best){
    80002284:	fe990ae3          	beq	s2,s1,80002278 <scheduler+0x1f6>
            acquire(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	9dffe0ef          	jal	ra,80000c68 <acquire>
            p->cpu_ticks = 0;
    8000228e:	1604a823          	sw	zero,368(s1)
            release(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	a6dfe0ef          	jal	ra,80000d00 <release>
    80002298:	b7d5                	j	8000227c <scheduler+0x1fa>

000000008000229a <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    8000229a:	7179                	addi	sp,sp,-48
    8000229c:	f406                	sd	ra,40(sp)
    8000229e:	f022                	sd	s0,32(sp)
    800022a0:	ec26                	sd	s1,24(sp)
    800022a2:	e84a                	sd	s2,16(sp)
    800022a4:	e44e                	sd	s3,8(sp)
    800022a6:	1800                	addi	s0,sp,48
    800022a8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022aa:	0022e497          	auipc	s1,0x22e
    800022ae:	b4e48493          	addi	s1,s1,-1202 # 8022fdf8 <proc>
    800022b2:	00234997          	auipc	s3,0x234
    800022b6:	94698993          	addi	s3,s3,-1722 # 80235bf8 <tickslock>
    acquire(&p->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	9adfe0ef          	jal	ra,80000c68 <acquire>
    if(p->pid == pid){
    800022c0:	589c                	lw	a5,48(s1)
    800022c2:	01278b63          	beq	a5,s2,800022d8 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	a39fe0ef          	jal	ra,80000d00 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022cc:	17848493          	addi	s1,s1,376
    800022d0:	ff3495e3          	bne	s1,s3,800022ba <kkill+0x20>
  }
  return -1;
    800022d4:	557d                	li	a0,-1
    800022d6:	a819                	j	800022ec <kkill+0x52>
      p->killed = 1;
    800022d8:	4785                	li	a5,1
    800022da:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022dc:	4c98                	lw	a4,24(s1)
    800022de:	4789                	li	a5,2
    800022e0:	00f70d63          	beq	a4,a5,800022fa <kkill+0x60>
      release(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	a1bfe0ef          	jal	ra,80000d00 <release>
      return 0;
    800022ea:	4501                	li	a0,0
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret
        p->state = RUNNABLE;
    800022fa:	478d                	li	a5,3
    800022fc:	cc9c                	sw	a5,24(s1)
    800022fe:	b7dd                	j	800022e4 <kkill+0x4a>

0000000080002300 <setkilled>:

void
setkilled(struct proc *p)
{
    80002300:	1101                	addi	sp,sp,-32
    80002302:	ec06                	sd	ra,24(sp)
    80002304:	e822                	sd	s0,16(sp)
    80002306:	e426                	sd	s1,8(sp)
    80002308:	1000                	addi	s0,sp,32
    8000230a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000230c:	95dfe0ef          	jal	ra,80000c68 <acquire>
  p->killed = 1;
    80002310:	4785                	li	a5,1
    80002312:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	9ebfe0ef          	jal	ra,80000d00 <release>
}
    8000231a:	60e2                	ld	ra,24(sp)
    8000231c:	6442                	ld	s0,16(sp)
    8000231e:	64a2                	ld	s1,8(sp)
    80002320:	6105                	addi	sp,sp,32
    80002322:	8082                	ret

0000000080002324 <killed>:

int
killed(struct proc *p)
{
    80002324:	1101                	addi	sp,sp,-32
    80002326:	ec06                	sd	ra,24(sp)
    80002328:	e822                	sd	s0,16(sp)
    8000232a:	e426                	sd	s1,8(sp)
    8000232c:	e04a                	sd	s2,0(sp)
    8000232e:	1000                	addi	s0,sp,32
    80002330:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002332:	937fe0ef          	jal	ra,80000c68 <acquire>
  k = p->killed;
    80002336:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	9c5fe0ef          	jal	ra,80000d00 <release>
  return k;
}
    80002340:	854a                	mv	a0,s2
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <kwait>:
{
    8000234e:	715d                	addi	sp,sp,-80
    80002350:	e486                	sd	ra,72(sp)
    80002352:	e0a2                	sd	s0,64(sp)
    80002354:	fc26                	sd	s1,56(sp)
    80002356:	f84a                	sd	s2,48(sp)
    80002358:	f44e                	sd	s3,40(sp)
    8000235a:	f052                	sd	s4,32(sp)
    8000235c:	ec56                	sd	s5,24(sp)
    8000235e:	e85a                	sd	s6,16(sp)
    80002360:	e45e                	sd	s7,8(sp)
    80002362:	e062                	sd	s8,0(sp)
    80002364:	0880                	addi	s0,sp,80
    80002366:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002368:	df6ff0ef          	jal	ra,8000195e <myproc>
    8000236c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000236e:	0022d517          	auipc	a0,0x22d
    80002372:	67250513          	addi	a0,a0,1650 # 8022f9e0 <wait_lock>
    80002376:	8f3fe0ef          	jal	ra,80000c68 <acquire>
    havekids = 0;
    8000237a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000237c:	4a15                	li	s4,5
        havekids = 1;
    8000237e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002380:	00234997          	auipc	s3,0x234
    80002384:	87898993          	addi	s3,s3,-1928 # 80235bf8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002388:	0022dc17          	auipc	s8,0x22d
    8000238c:	658c0c13          	addi	s8,s8,1624 # 8022f9e0 <wait_lock>
    havekids = 0;
    80002390:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002392:	0022e497          	auipc	s1,0x22e
    80002396:	a6648493          	addi	s1,s1,-1434 # 8022fdf8 <proc>
    8000239a:	a899                	j	800023f0 <kwait+0xa2>
          pid = pp->pid;
    8000239c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a0:	000b0c63          	beqz	s6,800023b8 <kwait+0x6a>
    800023a4:	4691                	li	a3,4
    800023a6:	02c48613          	addi	a2,s1,44
    800023aa:	85da                	mv	a1,s6
    800023ac:	05093503          	ld	a0,80(s2)
    800023b0:	adcff0ef          	jal	ra,8000168c <copyout>
    800023b4:	00054f63          	bltz	a0,800023d2 <kwait+0x84>
          freeproc(pp);
    800023b8:	8526                	mv	a0,s1
    800023ba:	f74ff0ef          	jal	ra,80001b2e <freeproc>
          release(&pp->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	941fe0ef          	jal	ra,80000d00 <release>
          release(&wait_lock);
    800023c4:	0022d517          	auipc	a0,0x22d
    800023c8:	61c50513          	addi	a0,a0,1564 # 8022f9e0 <wait_lock>
    800023cc:	935fe0ef          	jal	ra,80000d00 <release>
          return pid;
    800023d0:	a891                	j	80002424 <kwait+0xd6>
            release(&pp->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	92dfe0ef          	jal	ra,80000d00 <release>
            release(&wait_lock);
    800023d8:	0022d517          	auipc	a0,0x22d
    800023dc:	60850513          	addi	a0,a0,1544 # 8022f9e0 <wait_lock>
    800023e0:	921fe0ef          	jal	ra,80000d00 <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a83d                	j	80002424 <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	17848493          	addi	s1,s1,376
    800023ec:	03348063          	beq	s1,s3,8000240c <kwait+0xbe>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <kwait+0x9a>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	871fe0ef          	jal	ra,80000c68 <acquire>
        if(pp->state == ZOMBIE){
    800023fc:	4c9c                	lw	a5,24(s1)
    800023fe:	f9478fe3          	beq	a5,s4,8000239c <kwait+0x4e>
        release(&pp->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	8fdfe0ef          	jal	ra,80000d00 <release>
        havekids = 1;
    80002408:	8756                	mv	a4,s5
    8000240a:	bff9                	j	800023e8 <kwait+0x9a>
    if(!havekids || killed(p)){
    8000240c:	c709                	beqz	a4,80002416 <kwait+0xc8>
    8000240e:	854a                	mv	a0,s2
    80002410:	f15ff0ef          	jal	ra,80002324 <killed>
    80002414:	c50d                	beqz	a0,8000243e <kwait+0xf0>
      release(&wait_lock);
    80002416:	0022d517          	auipc	a0,0x22d
    8000241a:	5ca50513          	addi	a0,a0,1482 # 8022f9e0 <wait_lock>
    8000241e:	8e3fe0ef          	jal	ra,80000d00 <release>
      return -1;
    80002422:	59fd                	li	s3,-1
}
    80002424:	854e                	mv	a0,s3
    80002426:	60a6                	ld	ra,72(sp)
    80002428:	6406                	ld	s0,64(sp)
    8000242a:	74e2                	ld	s1,56(sp)
    8000242c:	7942                	ld	s2,48(sp)
    8000242e:	79a2                	ld	s3,40(sp)
    80002430:	7a02                	ld	s4,32(sp)
    80002432:	6ae2                	ld	s5,24(sp)
    80002434:	6b42                	ld	s6,16(sp)
    80002436:	6ba2                	ld	s7,8(sp)
    80002438:	6c02                	ld	s8,0(sp)
    8000243a:	6161                	addi	sp,sp,80
    8000243c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243e:	85e2                	mv	a1,s8
    80002440:	854a                	mv	a0,s2
    80002442:	a93ff0ef          	jal	ra,80001ed4 <sleep>
    havekids = 0;
    80002446:	b7a9                	j	80002390 <kwait+0x42>

0000000080002448 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002448:	7179                	addi	sp,sp,-48
    8000244a:	f406                	sd	ra,40(sp)
    8000244c:	f022                	sd	s0,32(sp)
    8000244e:	ec26                	sd	s1,24(sp)
    80002450:	e84a                	sd	s2,16(sp)
    80002452:	e44e                	sd	s3,8(sp)
    80002454:	e052                	sd	s4,0(sp)
    80002456:	1800                	addi	s0,sp,48
    80002458:	84aa                	mv	s1,a0
    8000245a:	892e                	mv	s2,a1
    8000245c:	89b2                	mv	s3,a2
    8000245e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002460:	cfeff0ef          	jal	ra,8000195e <myproc>
  if(user_dst){
    80002464:	cc99                	beqz	s1,80002482 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002466:	86d2                	mv	a3,s4
    80002468:	864e                	mv	a2,s3
    8000246a:	85ca                	mv	a1,s2
    8000246c:	6928                	ld	a0,80(a0)
    8000246e:	a1eff0ef          	jal	ra,8000168c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002472:	70a2                	ld	ra,40(sp)
    80002474:	7402                	ld	s0,32(sp)
    80002476:	64e2                	ld	s1,24(sp)
    80002478:	6942                	ld	s2,16(sp)
    8000247a:	69a2                	ld	s3,8(sp)
    8000247c:	6a02                	ld	s4,0(sp)
    8000247e:	6145                	addi	sp,sp,48
    80002480:	8082                	ret
    memmove((char *)dst, src, len);
    80002482:	000a061b          	sext.w	a2,s4
    80002486:	85ce                	mv	a1,s3
    80002488:	854a                	mv	a0,s2
    8000248a:	90ffe0ef          	jal	ra,80000d98 <memmove>
    return 0;
    8000248e:	8526                	mv	a0,s1
    80002490:	b7cd                	j	80002472 <either_copyout+0x2a>

0000000080002492 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	892a                	mv	s2,a0
    800024a4:	84ae                	mv	s1,a1
    800024a6:	89b2                	mv	s3,a2
    800024a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024aa:	cb4ff0ef          	jal	ra,8000195e <myproc>
  if(user_src){
    800024ae:	cc99                	beqz	s1,800024cc <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800024b0:	86d2                	mv	a3,s4
    800024b2:	864e                	mv	a2,s3
    800024b4:	85ca                	mv	a1,s2
    800024b6:	6928                	ld	a0,80(a0)
    800024b8:	a9aff0ef          	jal	ra,80001752 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024bc:	70a2                	ld	ra,40(sp)
    800024be:	7402                	ld	s0,32(sp)
    800024c0:	64e2                	ld	s1,24(sp)
    800024c2:	6942                	ld	s2,16(sp)
    800024c4:	69a2                	ld	s3,8(sp)
    800024c6:	6a02                	ld	s4,0(sp)
    800024c8:	6145                	addi	sp,sp,48
    800024ca:	8082                	ret
    memmove(dst, (char*)src, len);
    800024cc:	000a061b          	sext.w	a2,s4
    800024d0:	85ce                	mv	a1,s3
    800024d2:	854a                	mv	a0,s2
    800024d4:	8c5fe0ef          	jal	ra,80000d98 <memmove>
    return 0;
    800024d8:	8526                	mv	a0,s1
    800024da:	b7cd                	j	800024bc <either_copyin+0x2a>

00000000800024dc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024dc:	715d                	addi	sp,sp,-80
    800024de:	e486                	sd	ra,72(sp)
    800024e0:	e0a2                	sd	s0,64(sp)
    800024e2:	fc26                	sd	s1,56(sp)
    800024e4:	f84a                	sd	s2,48(sp)
    800024e6:	f44e                	sd	s3,40(sp)
    800024e8:	f052                	sd	s4,32(sp)
    800024ea:	ec56                	sd	s5,24(sp)
    800024ec:	e85a                	sd	s6,16(sp)
    800024ee:	e45e                	sd	s7,8(sp)
    800024f0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024f2:	00005517          	auipc	a0,0x5
    800024f6:	bee50513          	addi	a0,a0,-1042 # 800070e0 <digits+0xa8>
    800024fa:	fabfd0ef          	jal	ra,800004a4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fe:	0022e497          	auipc	s1,0x22e
    80002502:	a5248493          	addi	s1,s1,-1454 # 8022ff50 <proc+0x158>
    80002506:	00234917          	auipc	s2,0x234
    8000250a:	84a90913          	addi	s2,s2,-1974 # 80235d50 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002510:	00005997          	auipc	s3,0x5
    80002514:	d5898993          	addi	s3,s3,-680 # 80007268 <digits+0x230>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    80002518:	00005a97          	auipc	s5,0x5
    8000251c:	d58a8a93          	addi	s5,s5,-680 # 80007270 <digits+0x238>
           p->priority, p->wait_ticks, p->cpu_ticks);
    printf("\n");
    80002520:	00005a17          	auipc	s4,0x5
    80002524:	bc0a0a13          	addi	s4,s4,-1088 # 800070e0 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002528:	00005b97          	auipc	s7,0x5
    8000252c:	d98b8b93          	addi	s7,s7,-616 # 800072c0 <states.0>
    80002530:	a00d                	j	80002552 <procdump+0x76>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    80002532:	0186a803          	lw	a6,24(a3)
    80002536:	4adc                	lw	a5,20(a3)
    80002538:	4a98                	lw	a4,16(a3)
    8000253a:	ed86a583          	lw	a1,-296(a3)
    8000253e:	8556                	mv	a0,s5
    80002540:	f65fd0ef          	jal	ra,800004a4 <printf>
    printf("\n");
    80002544:	8552                	mv	a0,s4
    80002546:	f5ffd0ef          	jal	ra,800004a4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000254a:	17848493          	addi	s1,s1,376
    8000254e:	03248163          	beq	s1,s2,80002570 <procdump+0x94>
    if(p->state == UNUSED)
    80002552:	86a6                	mv	a3,s1
    80002554:	ec04a783          	lw	a5,-320(s1)
    80002558:	dbed                	beqz	a5,8000254a <procdump+0x6e>
      state = "???";
    8000255a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	fcfb6be3          	bltu	s6,a5,80002532 <procdump+0x56>
    80002560:	1782                	slli	a5,a5,0x20
    80002562:	9381                	srli	a5,a5,0x20
    80002564:	078e                	slli	a5,a5,0x3
    80002566:	97de                	add	a5,a5,s7
    80002568:	6390                	ld	a2,0(a5)
    8000256a:	f661                	bnez	a2,80002532 <procdump+0x56>
      state = "???";
    8000256c:	864e                	mv	a2,s3
    8000256e:	b7d1                	j	80002532 <procdump+0x56>
  }
}
    80002570:	60a6                	ld	ra,72(sp)
    80002572:	6406                	ld	s0,64(sp)
    80002574:	74e2                	ld	s1,56(sp)
    80002576:	7942                	ld	s2,48(sp)
    80002578:	79a2                	ld	s3,40(sp)
    8000257a:	7a02                	ld	s4,32(sp)
    8000257c:	6ae2                	ld	s5,24(sp)
    8000257e:	6b42                	ld	s6,16(sp)
    80002580:	6ba2                	ld	s7,8(sp)
    80002582:	6161                	addi	sp,sp,80
    80002584:	8082                	ret

0000000080002586 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002586:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    8000258a:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    8000258e:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002590:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002592:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002596:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    8000259a:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    8000259e:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800025a2:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800025a6:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800025aa:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800025ae:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800025b2:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800025b6:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800025ba:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800025be:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800025c2:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800025c4:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800025c6:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800025ca:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    800025ce:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800025d2:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800025d6:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800025da:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800025de:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800025e2:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800025e6:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800025ea:	0685bd83          	ld	s11,104(a1)
        
        ret
    800025ee:	8082                	ret

00000000800025f0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025f0:	1141                	addi	sp,sp,-16
    800025f2:	e406                	sd	ra,8(sp)
    800025f4:	e022                	sd	s0,0(sp)
    800025f6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025f8:	00005597          	auipc	a1,0x5
    800025fc:	cf858593          	addi	a1,a1,-776 # 800072f0 <states.0+0x30>
    80002600:	00233517          	auipc	a0,0x233
    80002604:	5f850513          	addi	a0,a0,1528 # 80235bf8 <tickslock>
    80002608:	de0fe0ef          	jal	ra,80000be8 <initlock>
}
    8000260c:	60a2                	ld	ra,8(sp)
    8000260e:	6402                	ld	s0,0(sp)
    80002610:	0141                	addi	sp,sp,16
    80002612:	8082                	ret

0000000080002614 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e422                	sd	s0,8(sp)
    80002618:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000261a:	00003797          	auipc	a5,0x3
    8000261e:	e8678793          	addi	a5,a5,-378 # 800054a0 <kernelvec>
    80002622:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002626:	6422                	ld	s0,8(sp)
    80002628:	0141                	addi	sp,sp,16
    8000262a:	8082                	ret

000000008000262c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000262c:	1141                	addi	sp,sp,-16
    8000262e:	e406                	sd	ra,8(sp)
    80002630:	e022                	sd	s0,0(sp)
    80002632:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002634:	b2aff0ef          	jal	ra,8000195e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002638:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000263c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000263e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002642:	04000737          	lui	a4,0x4000
    80002646:	00004797          	auipc	a5,0x4
    8000264a:	9ba78793          	addi	a5,a5,-1606 # 80006000 <_trampoline>
    8000264e:	00004697          	auipc	a3,0x4
    80002652:	9b268693          	addi	a3,a3,-1614 # 80006000 <_trampoline>
    80002656:	8f95                	sub	a5,a5,a3
    80002658:	177d                	addi	a4,a4,-1
    8000265a:	0732                	slli	a4,a4,0xc
    8000265c:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265e:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002662:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002664:	18002773          	csrr	a4,satp
    80002668:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000266a:	6d38                	ld	a4,88(a0)
    8000266c:	613c                	ld	a5,64(a0)
    8000266e:	6685                	lui	a3,0x1
    80002670:	97b6                	add	a5,a5,a3
    80002672:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002674:	6d3c                	ld	a5,88(a0)
    80002676:	00000717          	auipc	a4,0x0
    8000267a:	0f470713          	addi	a4,a4,244 # 8000276a <usertrap>
    8000267e:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002680:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002682:	8712                	mv	a4,tp
    80002684:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002686:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000268a:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000268e:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002692:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002696:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002698:	6f9c                	ld	a5,24(a5)
    8000269a:	14179073          	csrw	sepc,a5
}
    8000269e:	60a2                	ld	ra,8(sp)
    800026a0:	6402                	ld	s0,0(sp)
    800026a2:	0141                	addi	sp,sp,16
    800026a4:	8082                	ret

00000000800026a6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026a6:	1101                	addi	sp,sp,-32
    800026a8:	ec06                	sd	ra,24(sp)
    800026aa:	e822                	sd	s0,16(sp)
    800026ac:	e426                	sd	s1,8(sp)
    800026ae:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800026b0:	a82ff0ef          	jal	ra,80001932 <cpuid>
    800026b4:	cd19                	beqz	a0,800026d2 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    800026b6:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800026ba:	000f4737          	lui	a4,0xf4
    800026be:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800026c2:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800026c4:	14d79073          	csrw	0x14d,a5
}
    800026c8:	60e2                	ld	ra,24(sp)
    800026ca:	6442                	ld	s0,16(sp)
    800026cc:	64a2                	ld	s1,8(sp)
    800026ce:	6105                	addi	sp,sp,32
    800026d0:	8082                	ret
    acquire(&tickslock);
    800026d2:	00233497          	auipc	s1,0x233
    800026d6:	52648493          	addi	s1,s1,1318 # 80235bf8 <tickslock>
    800026da:	8526                	mv	a0,s1
    800026dc:	d8cfe0ef          	jal	ra,80000c68 <acquire>
    ticks++;
    800026e0:	00005517          	auipc	a0,0x5
    800026e4:	1e050513          	addi	a0,a0,480 # 800078c0 <ticks>
    800026e8:	411c                	lw	a5,0(a0)
    800026ea:	2785                	addiw	a5,a5,1
    800026ec:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800026ee:	833ff0ef          	jal	ra,80001f20 <wakeup>
    release(&tickslock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	e0cfe0ef          	jal	ra,80000d00 <release>
    800026f8:	bf7d                	j	800026b6 <clockintr+0x10>

00000000800026fa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026fa:	1101                	addi	sp,sp,-32
    800026fc:	ec06                	sd	ra,24(sp)
    800026fe:	e822                	sd	s0,16(sp)
    80002700:	e426                	sd	s1,8(sp)
    80002702:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002704:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002708:	57fd                	li	a5,-1
    8000270a:	17fe                	slli	a5,a5,0x3f
    8000270c:	07a5                	addi	a5,a5,9
    8000270e:	00f70d63          	beq	a4,a5,80002728 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002712:	57fd                	li	a5,-1
    80002714:	17fe                	slli	a5,a5,0x3f
    80002716:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002718:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    8000271a:	04f70463          	beq	a4,a5,80002762 <devintr+0x68>
  }
}
    8000271e:	60e2                	ld	ra,24(sp)
    80002720:	6442                	ld	s0,16(sp)
    80002722:	64a2                	ld	s1,8(sp)
    80002724:	6105                	addi	sp,sp,32
    80002726:	8082                	ret
    int irq = plic_claim();
    80002728:	621020ef          	jal	ra,80005548 <plic_claim>
    8000272c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000272e:	47a9                	li	a5,10
    80002730:	02f50363          	beq	a0,a5,80002756 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    80002734:	4785                	li	a5,1
    80002736:	02f50363          	beq	a0,a5,8000275c <devintr+0x62>
    return 1;
    8000273a:	4505                	li	a0,1
    } else if(irq){
    8000273c:	d0ed                	beqz	s1,8000271e <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    8000273e:	85a6                	mv	a1,s1
    80002740:	00005517          	auipc	a0,0x5
    80002744:	bb850513          	addi	a0,a0,-1096 # 800072f8 <states.0+0x38>
    80002748:	d5dfd0ef          	jal	ra,800004a4 <printf>
      plic_complete(irq);
    8000274c:	8526                	mv	a0,s1
    8000274e:	61b020ef          	jal	ra,80005568 <plic_complete>
    return 1;
    80002752:	4505                	li	a0,1
    80002754:	b7e9                	j	8000271e <devintr+0x24>
      uartintr();
    80002756:	9e2fe0ef          	jal	ra,80000938 <uartintr>
    8000275a:	bfcd                	j	8000274c <devintr+0x52>
      virtio_disk_intr();
    8000275c:	27c030ef          	jal	ra,800059d8 <virtio_disk_intr>
    80002760:	b7f5                	j	8000274c <devintr+0x52>
    clockintr();
    80002762:	f45ff0ef          	jal	ra,800026a6 <clockintr>
    return 2;
    80002766:	4509                	li	a0,2
    80002768:	bf5d                	j	8000271e <devintr+0x24>

000000008000276a <usertrap>:
{
    8000276a:	1101                	addi	sp,sp,-32
    8000276c:	ec06                	sd	ra,24(sp)
    8000276e:	e822                	sd	s0,16(sp)
    80002770:	e426                	sd	s1,8(sp)
    80002772:	e04a                	sd	s2,0(sp)
    80002774:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002776:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000277a:	1007f793          	andi	a5,a5,256
    8000277e:	eba5                	bnez	a5,800027ee <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002780:	00003797          	auipc	a5,0x3
    80002784:	d2078793          	addi	a5,a5,-736 # 800054a0 <kernelvec>
    80002788:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000278c:	9d2ff0ef          	jal	ra,8000195e <myproc>
    80002790:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002792:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002794:	14102773          	csrr	a4,sepc
    80002798:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000279e:	47a1                	li	a5,8
    800027a0:	04f70d63          	beq	a4,a5,800027fa <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800027a4:	f57ff0ef          	jal	ra,800026fa <devintr>
    800027a8:	892a                	mv	s2,a0
    800027aa:	e945                	bnez	a0,8000285a <usertrap+0xf0>
    800027ac:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800027b0:	47bd                	li	a5,15
    800027b2:	08f70863          	beq	a4,a5,80002842 <usertrap+0xd8>
    800027b6:	14202773          	csrr	a4,scause
    800027ba:	47b5                	li	a5,13
    800027bc:	08f70363          	beq	a4,a5,80002842 <usertrap+0xd8>
    800027c0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800027c4:	5890                	lw	a2,48(s1)
    800027c6:	00005517          	auipc	a0,0x5
    800027ca:	b7250513          	addi	a0,a0,-1166 # 80007338 <states.0+0x78>
    800027ce:	cd7fd0ef          	jal	ra,800004a4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027d2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800027d6:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800027da:	00005517          	auipc	a0,0x5
    800027de:	b8e50513          	addi	a0,a0,-1138 # 80007368 <states.0+0xa8>
    800027e2:	cc3fd0ef          	jal	ra,800004a4 <printf>
    setkilled(p);
    800027e6:	8526                	mv	a0,s1
    800027e8:	b19ff0ef          	jal	ra,80002300 <setkilled>
    800027ec:	a035                	j	80002818 <usertrap+0xae>
    panic("usertrap: not from user mode");
    800027ee:	00005517          	auipc	a0,0x5
    800027f2:	b2a50513          	addi	a0,a0,-1238 # 80007318 <states.0+0x58>
    800027f6:	f75fd0ef          	jal	ra,8000076a <panic>
    if(killed(p))
    800027fa:	b2bff0ef          	jal	ra,80002324 <killed>
    800027fe:	ed15                	bnez	a0,8000283a <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002800:	6cb8                	ld	a4,88(s1)
    80002802:	6f1c                	ld	a5,24(a4)
    80002804:	0791                	addi	a5,a5,4
    80002806:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002808:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000280c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002810:	10079073          	csrw	sstatus,a5
    syscall();
    80002814:	25e000ef          	jal	ra,80002a72 <syscall>
  if(killed(p))
    80002818:	8526                	mv	a0,s1
    8000281a:	b0bff0ef          	jal	ra,80002324 <killed>
    8000281e:	e139                	bnez	a0,80002864 <usertrap+0xfa>
  prepare_return();
    80002820:	e0dff0ef          	jal	ra,8000262c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002824:	68a8                	ld	a0,80(s1)
    80002826:	8131                	srli	a0,a0,0xc
    80002828:	57fd                	li	a5,-1
    8000282a:	17fe                	slli	a5,a5,0x3f
    8000282c:	8d5d                	or	a0,a0,a5
}
    8000282e:	60e2                	ld	ra,24(sp)
    80002830:	6442                	ld	s0,16(sp)
    80002832:	64a2                	ld	s1,8(sp)
    80002834:	6902                	ld	s2,0(sp)
    80002836:	6105                	addi	sp,sp,32
    80002838:	8082                	ret
      kexit(-1);
    8000283a:	557d                	li	a0,-1
    8000283c:	fa4ff0ef          	jal	ra,80001fe0 <kexit>
    80002840:	b7c1                	j	80002800 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002842:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002846:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    8000284a:	164d                	addi	a2,a2,-13
    8000284c:	00163613          	seqz	a2,a2
    80002850:	68a8                	ld	a0,80(s1)
    80002852:	d5ffe0ef          	jal	ra,800015b0 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002856:	f169                	bnez	a0,80002818 <usertrap+0xae>
    80002858:	b7a5                	j	800027c0 <usertrap+0x56>
  if(killed(p))
    8000285a:	8526                	mv	a0,s1
    8000285c:	ac9ff0ef          	jal	ra,80002324 <killed>
    80002860:	c511                	beqz	a0,8000286c <usertrap+0x102>
    80002862:	a011                	j	80002866 <usertrap+0xfc>
    80002864:	4901                	li	s2,0
    kexit(-1);
    80002866:	557d                	li	a0,-1
    80002868:	f78ff0ef          	jal	ra,80001fe0 <kexit>
  if(which_dev == 2){
    8000286c:	4789                	li	a5,2
    8000286e:	faf919e3          	bne	s2,a5,80002820 <usertrap+0xb6>
    if(p) p->cpu_ticks++;
    80002872:	1704a783          	lw	a5,368(s1)
    80002876:	2785                	addiw	a5,a5,1
    80002878:	16f4a823          	sw	a5,368(s1)
    yield();
    8000287c:	e2cff0ef          	jal	ra,80001ea8 <yield>
    80002880:	b745                	j	80002820 <usertrap+0xb6>

0000000080002882 <kerneltrap>:
{
    80002882:	7179                	addi	sp,sp,-48
    80002884:	f406                	sd	ra,40(sp)
    80002886:	f022                	sd	s0,32(sp)
    80002888:	ec26                	sd	s1,24(sp)
    8000288a:	e84a                	sd	s2,16(sp)
    8000288c:	e44e                	sd	s3,8(sp)
    8000288e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002890:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002894:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002898:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000289c:	1004f793          	andi	a5,s1,256
    800028a0:	c795                	beqz	a5,800028cc <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028a6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028a8:	eb85                	bnez	a5,800028d8 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800028aa:	e51ff0ef          	jal	ra,800026fa <devintr>
    800028ae:	c91d                	beqz	a0,800028e4 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    800028b0:	4789                	li	a5,2
    800028b2:	04f50a63          	beq	a0,a5,80002906 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10049073          	csrw	sstatus,s1
}
    800028be:	70a2                	ld	ra,40(sp)
    800028c0:	7402                	ld	s0,32(sp)
    800028c2:	64e2                	ld	s1,24(sp)
    800028c4:	6942                	ld	s2,16(sp)
    800028c6:	69a2                	ld	s3,8(sp)
    800028c8:	6145                	addi	sp,sp,48
    800028ca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028cc:	00005517          	auipc	a0,0x5
    800028d0:	ac450513          	addi	a0,a0,-1340 # 80007390 <states.0+0xd0>
    800028d4:	e97fd0ef          	jal	ra,8000076a <panic>
    panic("kerneltrap: interrupts enabled");
    800028d8:	00005517          	auipc	a0,0x5
    800028dc:	ae050513          	addi	a0,a0,-1312 # 800073b8 <states.0+0xf8>
    800028e0:	e8bfd0ef          	jal	ra,8000076a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e8:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800028ec:	85ce                	mv	a1,s3
    800028ee:	00005517          	auipc	a0,0x5
    800028f2:	aea50513          	addi	a0,a0,-1302 # 800073d8 <states.0+0x118>
    800028f6:	baffd0ef          	jal	ra,800004a4 <printf>
    panic("kerneltrap");
    800028fa:	00005517          	auipc	a0,0x5
    800028fe:	b0650513          	addi	a0,a0,-1274 # 80007400 <states.0+0x140>
    80002902:	e69fd0ef          	jal	ra,8000076a <panic>
  if(which_dev == 2 && myproc() != 0){
    80002906:	858ff0ef          	jal	ra,8000195e <myproc>
    8000290a:	d555                	beqz	a0,800028b6 <kerneltrap+0x34>
    myproc()->cpu_ticks++;
    8000290c:	852ff0ef          	jal	ra,8000195e <myproc>
    80002910:	17052783          	lw	a5,368(a0)
    80002914:	2785                	addiw	a5,a5,1
    80002916:	16f52823          	sw	a5,368(a0)
    yield();
    8000291a:	d8eff0ef          	jal	ra,80001ea8 <yield>
    8000291e:	bf61                	j	800028b6 <kerneltrap+0x34>

0000000080002920 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
    8000292a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000292c:	832ff0ef          	jal	ra,8000195e <myproc>
  switch (n) {
    80002930:	4795                	li	a5,5
    80002932:	0497e163          	bltu	a5,s1,80002974 <argraw+0x54>
    80002936:	048a                	slli	s1,s1,0x2
    80002938:	00005717          	auipc	a4,0x5
    8000293c:	b0070713          	addi	a4,a4,-1280 # 80007438 <states.0+0x178>
    80002940:	94ba                	add	s1,s1,a4
    80002942:	409c                	lw	a5,0(s1)
    80002944:	97ba                	add	a5,a5,a4
    80002946:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002948:	6d3c                	ld	a5,88(a0)
    8000294a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000294c:	60e2                	ld	ra,24(sp)
    8000294e:	6442                	ld	s0,16(sp)
    80002950:	64a2                	ld	s1,8(sp)
    80002952:	6105                	addi	sp,sp,32
    80002954:	8082                	ret
    return p->trapframe->a1;
    80002956:	6d3c                	ld	a5,88(a0)
    80002958:	7fa8                	ld	a0,120(a5)
    8000295a:	bfcd                	j	8000294c <argraw+0x2c>
    return p->trapframe->a2;
    8000295c:	6d3c                	ld	a5,88(a0)
    8000295e:	63c8                	ld	a0,128(a5)
    80002960:	b7f5                	j	8000294c <argraw+0x2c>
    return p->trapframe->a3;
    80002962:	6d3c                	ld	a5,88(a0)
    80002964:	67c8                	ld	a0,136(a5)
    80002966:	b7dd                	j	8000294c <argraw+0x2c>
    return p->trapframe->a4;
    80002968:	6d3c                	ld	a5,88(a0)
    8000296a:	6bc8                	ld	a0,144(a5)
    8000296c:	b7c5                	j	8000294c <argraw+0x2c>
    return p->trapframe->a5;
    8000296e:	6d3c                	ld	a5,88(a0)
    80002970:	6fc8                	ld	a0,152(a5)
    80002972:	bfe9                	j	8000294c <argraw+0x2c>
  panic("argraw");
    80002974:	00005517          	auipc	a0,0x5
    80002978:	a9c50513          	addi	a0,a0,-1380 # 80007410 <states.0+0x150>
    8000297c:	deffd0ef          	jal	ra,8000076a <panic>

0000000080002980 <fetchaddr>:
{
    80002980:	1101                	addi	sp,sp,-32
    80002982:	ec06                	sd	ra,24(sp)
    80002984:	e822                	sd	s0,16(sp)
    80002986:	e426                	sd	s1,8(sp)
    80002988:	e04a                	sd	s2,0(sp)
    8000298a:	1000                	addi	s0,sp,32
    8000298c:	84aa                	mv	s1,a0
    8000298e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002990:	fcffe0ef          	jal	ra,8000195e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002994:	653c                	ld	a5,72(a0)
    80002996:	02f4f663          	bgeu	s1,a5,800029c2 <fetchaddr+0x42>
    8000299a:	00848713          	addi	a4,s1,8
    8000299e:	02e7e463          	bltu	a5,a4,800029c6 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029a2:	46a1                	li	a3,8
    800029a4:	8626                	mv	a2,s1
    800029a6:	85ca                	mv	a1,s2
    800029a8:	6928                	ld	a0,80(a0)
    800029aa:	da9fe0ef          	jal	ra,80001752 <copyin>
    800029ae:	00a03533          	snez	a0,a0
    800029b2:	40a00533          	neg	a0,a0
}
    800029b6:	60e2                	ld	ra,24(sp)
    800029b8:	6442                	ld	s0,16(sp)
    800029ba:	64a2                	ld	s1,8(sp)
    800029bc:	6902                	ld	s2,0(sp)
    800029be:	6105                	addi	sp,sp,32
    800029c0:	8082                	ret
    return -1;
    800029c2:	557d                	li	a0,-1
    800029c4:	bfcd                	j	800029b6 <fetchaddr+0x36>
    800029c6:	557d                	li	a0,-1
    800029c8:	b7fd                	j	800029b6 <fetchaddr+0x36>

00000000800029ca <fetchstr>:
{
    800029ca:	7179                	addi	sp,sp,-48
    800029cc:	f406                	sd	ra,40(sp)
    800029ce:	f022                	sd	s0,32(sp)
    800029d0:	ec26                	sd	s1,24(sp)
    800029d2:	e84a                	sd	s2,16(sp)
    800029d4:	e44e                	sd	s3,8(sp)
    800029d6:	1800                	addi	s0,sp,48
    800029d8:	892a                	mv	s2,a0
    800029da:	84ae                	mv	s1,a1
    800029dc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800029de:	f81fe0ef          	jal	ra,8000195e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800029e2:	86ce                	mv	a3,s3
    800029e4:	864a                	mv	a2,s2
    800029e6:	85a6                	mv	a1,s1
    800029e8:	6928                	ld	a0,80(a0)
    800029ea:	b17fe0ef          	jal	ra,80001500 <copyinstr>
    800029ee:	00054c63          	bltz	a0,80002a06 <fetchstr+0x3c>
  return strlen(buf);
    800029f2:	8526                	mv	a0,s1
    800029f4:	cc0fe0ef          	jal	ra,80000eb4 <strlen>
}
    800029f8:	70a2                	ld	ra,40(sp)
    800029fa:	7402                	ld	s0,32(sp)
    800029fc:	64e2                	ld	s1,24(sp)
    800029fe:	6942                	ld	s2,16(sp)
    80002a00:	69a2                	ld	s3,8(sp)
    80002a02:	6145                	addi	sp,sp,48
    80002a04:	8082                	ret
    return -1;
    80002a06:	557d                	li	a0,-1
    80002a08:	bfc5                	j	800029f8 <fetchstr+0x2e>

0000000080002a0a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	1000                	addi	s0,sp,32
    80002a14:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a16:	f0bff0ef          	jal	ra,80002920 <argraw>
    80002a1a:	c088                	sw	a0,0(s1)
}
    80002a1c:	60e2                	ld	ra,24(sp)
    80002a1e:	6442                	ld	s0,16(sp)
    80002a20:	64a2                	ld	s1,8(sp)
    80002a22:	6105                	addi	sp,sp,32
    80002a24:	8082                	ret

0000000080002a26 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002a26:	1101                	addi	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	1000                	addi	s0,sp,32
    80002a30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a32:	eefff0ef          	jal	ra,80002920 <argraw>
    80002a36:	e088                	sd	a0,0(s1)
}
    80002a38:	60e2                	ld	ra,24(sp)
    80002a3a:	6442                	ld	s0,16(sp)
    80002a3c:	64a2                	ld	s1,8(sp)
    80002a3e:	6105                	addi	sp,sp,32
    80002a40:	8082                	ret

0000000080002a42 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a42:	7179                	addi	sp,sp,-48
    80002a44:	f406                	sd	ra,40(sp)
    80002a46:	f022                	sd	s0,32(sp)
    80002a48:	ec26                	sd	s1,24(sp)
    80002a4a:	e84a                	sd	s2,16(sp)
    80002a4c:	1800                	addi	s0,sp,48
    80002a4e:	84ae                	mv	s1,a1
    80002a50:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002a52:	fd840593          	addi	a1,s0,-40
    80002a56:	fd1ff0ef          	jal	ra,80002a26 <argaddr>
  return fetchstr(addr, buf, max);
    80002a5a:	864a                	mv	a2,s2
    80002a5c:	85a6                	mv	a1,s1
    80002a5e:	fd843503          	ld	a0,-40(s0)
    80002a62:	f69ff0ef          	jal	ra,800029ca <fetchstr>
}
    80002a66:	70a2                	ld	ra,40(sp)
    80002a68:	7402                	ld	s0,32(sp)
    80002a6a:	64e2                	ld	s1,24(sp)
    80002a6c:	6942                	ld	s2,16(sp)
    80002a6e:	6145                	addi	sp,sp,48
    80002a70:	8082                	ret

0000000080002a72 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002a72:	1101                	addi	sp,sp,-32
    80002a74:	ec06                	sd	ra,24(sp)
    80002a76:	e822                	sd	s0,16(sp)
    80002a78:	e426                	sd	s1,8(sp)
    80002a7a:	e04a                	sd	s2,0(sp)
    80002a7c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002a7e:	ee1fe0ef          	jal	ra,8000195e <myproc>
    80002a82:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002a84:	05853903          	ld	s2,88(a0)
    80002a88:	0a893783          	ld	a5,168(s2)
    80002a8c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002a90:	37fd                	addiw	a5,a5,-1
    80002a92:	4751                	li	a4,20
    80002a94:	00f76f63          	bltu	a4,a5,80002ab2 <syscall+0x40>
    80002a98:	00369713          	slli	a4,a3,0x3
    80002a9c:	00005797          	auipc	a5,0x5
    80002aa0:	9b478793          	addi	a5,a5,-1612 # 80007450 <syscalls>
    80002aa4:	97ba                	add	a5,a5,a4
    80002aa6:	639c                	ld	a5,0(a5)
    80002aa8:	c789                	beqz	a5,80002ab2 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002aaa:	9782                	jalr	a5
    80002aac:	06a93823          	sd	a0,112(s2)
    80002ab0:	a829                	j	80002aca <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ab2:	15848613          	addi	a2,s1,344
    80002ab6:	588c                	lw	a1,48(s1)
    80002ab8:	00005517          	auipc	a0,0x5
    80002abc:	96050513          	addi	a0,a0,-1696 # 80007418 <states.0+0x158>
    80002ac0:	9e5fd0ef          	jal	ra,800004a4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ac4:	6cbc                	ld	a5,88(s1)
    80002ac6:	577d                	li	a4,-1
    80002ac8:	fbb8                	sd	a4,112(a5)
  }
}
    80002aca:	60e2                	ld	ra,24(sp)
    80002acc:	6442                	ld	s0,16(sp)
    80002ace:	64a2                	ld	s1,8(sp)
    80002ad0:	6902                	ld	s2,0(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret

0000000080002ad6 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ade:	fec40593          	addi	a1,s0,-20
    80002ae2:	4501                	li	a0,0
    80002ae4:	f27ff0ef          	jal	ra,80002a0a <argint>
  kexit(n);
    80002ae8:	fec42503          	lw	a0,-20(s0)
    80002aec:	cf4ff0ef          	jal	ra,80001fe0 <kexit>
  return 0;  // not reached
}
    80002af0:	4501                	li	a0,0
    80002af2:	60e2                	ld	ra,24(sp)
    80002af4:	6442                	ld	s0,16(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret

0000000080002afa <sys_getpid>:

uint64
sys_getpid(void)
{
    80002afa:	1141                	addi	sp,sp,-16
    80002afc:	e406                	sd	ra,8(sp)
    80002afe:	e022                	sd	s0,0(sp)
    80002b00:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b02:	e5dfe0ef          	jal	ra,8000195e <myproc>
}
    80002b06:	5908                	lw	a0,48(a0)
    80002b08:	60a2                	ld	ra,8(sp)
    80002b0a:	6402                	ld	s0,0(sp)
    80002b0c:	0141                	addi	sp,sp,16
    80002b0e:	8082                	ret

0000000080002b10 <sys_fork>:

uint64
sys_fork(void)
{
    80002b10:	1141                	addi	sp,sp,-16
    80002b12:	e406                	sd	ra,8(sp)
    80002b14:	e022                	sd	s0,0(sp)
    80002b16:	0800                	addi	s0,sp,16
  return kfork();
    80002b18:	9baff0ef          	jal	ra,80001cd2 <kfork>
}
    80002b1c:	60a2                	ld	ra,8(sp)
    80002b1e:	6402                	ld	s0,0(sp)
    80002b20:	0141                	addi	sp,sp,16
    80002b22:	8082                	ret

0000000080002b24 <sys_wait>:

uint64
sys_wait(void)
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002b2c:	fe840593          	addi	a1,s0,-24
    80002b30:	4501                	li	a0,0
    80002b32:	ef5ff0ef          	jal	ra,80002a26 <argaddr>
  return kwait(p);
    80002b36:	fe843503          	ld	a0,-24(s0)
    80002b3a:	815ff0ef          	jal	ra,8000234e <kwait>
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret

0000000080002b46 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002b46:	7179                	addi	sp,sp,-48
    80002b48:	f406                	sd	ra,40(sp)
    80002b4a:	f022                	sd	s0,32(sp)
    80002b4c:	ec26                	sd	s1,24(sp)
    80002b4e:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002b50:	fd840593          	addi	a1,s0,-40
    80002b54:	4501                	li	a0,0
    80002b56:	eb5ff0ef          	jal	ra,80002a0a <argint>
  argint(1, &t);
    80002b5a:	fdc40593          	addi	a1,s0,-36
    80002b5e:	4505                	li	a0,1
    80002b60:	eabff0ef          	jal	ra,80002a0a <argint>
  addr = myproc()->sz;
    80002b64:	dfbfe0ef          	jal	ra,8000195e <myproc>
    80002b68:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002b6a:	fdc42703          	lw	a4,-36(s0)
    80002b6e:	4785                	li	a5,1
    80002b70:	02f70763          	beq	a4,a5,80002b9e <sys_sbrk+0x58>
    80002b74:	fd842783          	lw	a5,-40(s0)
    80002b78:	0207c363          	bltz	a5,80002b9e <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002b7c:	97a6                	add	a5,a5,s1
    80002b7e:	0297ee63          	bltu	a5,s1,80002bba <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002b82:	02000737          	lui	a4,0x2000
    80002b86:	177d                	addi	a4,a4,-1
    80002b88:	0736                	slli	a4,a4,0xd
    80002b8a:	02f76a63          	bltu	a4,a5,80002bbe <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002b8e:	dd1fe0ef          	jal	ra,8000195e <myproc>
    80002b92:	fd842703          	lw	a4,-40(s0)
    80002b96:	653c                	ld	a5,72(a0)
    80002b98:	97ba                	add	a5,a5,a4
    80002b9a:	e53c                	sd	a5,72(a0)
    80002b9c:	a039                	j	80002baa <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002b9e:	fd842503          	lw	a0,-40(s0)
    80002ba2:	8ceff0ef          	jal	ra,80001c70 <growproc>
    80002ba6:	00054863          	bltz	a0,80002bb6 <sys_sbrk+0x70>
  }
  return addr;
}
    80002baa:	8526                	mv	a0,s1
    80002bac:	70a2                	ld	ra,40(sp)
    80002bae:	7402                	ld	s0,32(sp)
    80002bb0:	64e2                	ld	s1,24(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret
      return -1;
    80002bb6:	54fd                	li	s1,-1
    80002bb8:	bfcd                	j	80002baa <sys_sbrk+0x64>
      return -1;
    80002bba:	54fd                	li	s1,-1
    80002bbc:	b7fd                	j	80002baa <sys_sbrk+0x64>
      return -1;
    80002bbe:	54fd                	li	s1,-1
    80002bc0:	b7ed                	j	80002baa <sys_sbrk+0x64>

0000000080002bc2 <sys_pause>:

uint64
sys_pause(void)
{
    80002bc2:	7139                	addi	sp,sp,-64
    80002bc4:	fc06                	sd	ra,56(sp)
    80002bc6:	f822                	sd	s0,48(sp)
    80002bc8:	f426                	sd	s1,40(sp)
    80002bca:	f04a                	sd	s2,32(sp)
    80002bcc:	ec4e                	sd	s3,24(sp)
    80002bce:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002bd0:	fcc40593          	addi	a1,s0,-52
    80002bd4:	4501                	li	a0,0
    80002bd6:	e35ff0ef          	jal	ra,80002a0a <argint>
  if(n < 0)
    80002bda:	fcc42783          	lw	a5,-52(s0)
    80002bde:	0607c563          	bltz	a5,80002c48 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002be2:	00233517          	auipc	a0,0x233
    80002be6:	01650513          	addi	a0,a0,22 # 80235bf8 <tickslock>
    80002bea:	87efe0ef          	jal	ra,80000c68 <acquire>
  ticks0 = ticks;
    80002bee:	00005917          	auipc	s2,0x5
    80002bf2:	cd292903          	lw	s2,-814(s2) # 800078c0 <ticks>
  while(ticks - ticks0 < n){
    80002bf6:	fcc42783          	lw	a5,-52(s0)
    80002bfa:	cb8d                	beqz	a5,80002c2c <sys_pause+0x6a>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002bfc:	00233997          	auipc	s3,0x233
    80002c00:	ffc98993          	addi	s3,s3,-4 # 80235bf8 <tickslock>
    80002c04:	00005497          	auipc	s1,0x5
    80002c08:	cbc48493          	addi	s1,s1,-836 # 800078c0 <ticks>
    if(killed(myproc())){
    80002c0c:	d53fe0ef          	jal	ra,8000195e <myproc>
    80002c10:	f14ff0ef          	jal	ra,80002324 <killed>
    80002c14:	ed0d                	bnez	a0,80002c4e <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002c16:	85ce                	mv	a1,s3
    80002c18:	8526                	mv	a0,s1
    80002c1a:	abaff0ef          	jal	ra,80001ed4 <sleep>
  while(ticks - ticks0 < n){
    80002c1e:	409c                	lw	a5,0(s1)
    80002c20:	412787bb          	subw	a5,a5,s2
    80002c24:	fcc42703          	lw	a4,-52(s0)
    80002c28:	fee7e2e3          	bltu	a5,a4,80002c0c <sys_pause+0x4a>
  }
  release(&tickslock);
    80002c2c:	00233517          	auipc	a0,0x233
    80002c30:	fcc50513          	addi	a0,a0,-52 # 80235bf8 <tickslock>
    80002c34:	8ccfe0ef          	jal	ra,80000d00 <release>
  return 0;
    80002c38:	4501                	li	a0,0
}
    80002c3a:	70e2                	ld	ra,56(sp)
    80002c3c:	7442                	ld	s0,48(sp)
    80002c3e:	74a2                	ld	s1,40(sp)
    80002c40:	7902                	ld	s2,32(sp)
    80002c42:	69e2                	ld	s3,24(sp)
    80002c44:	6121                	addi	sp,sp,64
    80002c46:	8082                	ret
    n = 0;
    80002c48:	fc042623          	sw	zero,-52(s0)
    80002c4c:	bf59                	j	80002be2 <sys_pause+0x20>
      release(&tickslock);
    80002c4e:	00233517          	auipc	a0,0x233
    80002c52:	faa50513          	addi	a0,a0,-86 # 80235bf8 <tickslock>
    80002c56:	8aafe0ef          	jal	ra,80000d00 <release>
      return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bff9                	j	80002c3a <sys_pause+0x78>

0000000080002c5e <sys_kill>:

uint64
sys_kill(void)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002c66:	fec40593          	addi	a1,s0,-20
    80002c6a:	4501                	li	a0,0
    80002c6c:	d9fff0ef          	jal	ra,80002a0a <argint>
  return kkill(pid);
    80002c70:	fec42503          	lw	a0,-20(s0)
    80002c74:	e26ff0ef          	jal	ra,8000229a <kkill>
}
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002c8a:	00233517          	auipc	a0,0x233
    80002c8e:	f6e50513          	addi	a0,a0,-146 # 80235bf8 <tickslock>
    80002c92:	fd7fd0ef          	jal	ra,80000c68 <acquire>
  xticks = ticks;
    80002c96:	00005497          	auipc	s1,0x5
    80002c9a:	c2a4a483          	lw	s1,-982(s1) # 800078c0 <ticks>
  release(&tickslock);
    80002c9e:	00233517          	auipc	a0,0x233
    80002ca2:	f5a50513          	addi	a0,a0,-166 # 80235bf8 <tickslock>
    80002ca6:	85afe0ef          	jal	ra,80000d00 <release>
  return xticks;
}
    80002caa:	02049513          	slli	a0,s1,0x20
    80002cae:	9101                	srli	a0,a0,0x20
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	64a2                	ld	s1,8(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002cba:	7179                	addi	sp,sp,-48
    80002cbc:	f406                	sd	ra,40(sp)
    80002cbe:	f022                	sd	s0,32(sp)
    80002cc0:	ec26                	sd	s1,24(sp)
    80002cc2:	e84a                	sd	s2,16(sp)
    80002cc4:	e44e                	sd	s3,8(sp)
    80002cc6:	e052                	sd	s4,0(sp)
    80002cc8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002cca:	00005597          	auipc	a1,0x5
    80002cce:	83658593          	addi	a1,a1,-1994 # 80007500 <syscalls+0xb0>
    80002cd2:	00233517          	auipc	a0,0x233
    80002cd6:	f3e50513          	addi	a0,a0,-194 # 80235c10 <bcache>
    80002cda:	f0ffd0ef          	jal	ra,80000be8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002cde:	0023b797          	auipc	a5,0x23b
    80002ce2:	f3278793          	addi	a5,a5,-206 # 8023dc10 <bcache+0x8000>
    80002ce6:	0023b717          	auipc	a4,0x23b
    80002cea:	19270713          	addi	a4,a4,402 # 8023de78 <bcache+0x8268>
    80002cee:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002cf2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002cf6:	00233497          	auipc	s1,0x233
    80002cfa:	f3248493          	addi	s1,s1,-206 # 80235c28 <bcache+0x18>
    b->next = bcache.head.next;
    80002cfe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d00:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d02:	00005a17          	auipc	s4,0x5
    80002d06:	806a0a13          	addi	s4,s4,-2042 # 80007508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002d0a:	2b893783          	ld	a5,696(s2)
    80002d0e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d10:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002d14:	85d2                	mv	a1,s4
    80002d16:	01048513          	addi	a0,s1,16
    80002d1a:	2fe010ef          	jal	ra,80004018 <initsleeplock>
    bcache.head.next->prev = b;
    80002d1e:	2b893783          	ld	a5,696(s2)
    80002d22:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002d24:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d28:	45848493          	addi	s1,s1,1112
    80002d2c:	fd349fe3          	bne	s1,s3,80002d0a <binit+0x50>
  }
}
    80002d30:	70a2                	ld	ra,40(sp)
    80002d32:	7402                	ld	s0,32(sp)
    80002d34:	64e2                	ld	s1,24(sp)
    80002d36:	6942                	ld	s2,16(sp)
    80002d38:	69a2                	ld	s3,8(sp)
    80002d3a:	6a02                	ld	s4,0(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret

0000000080002d40 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	e84a                	sd	s2,16(sp)
    80002d4a:	e44e                	sd	s3,8(sp)
    80002d4c:	1800                	addi	s0,sp,48
    80002d4e:	892a                	mv	s2,a0
    80002d50:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002d52:	00233517          	auipc	a0,0x233
    80002d56:	ebe50513          	addi	a0,a0,-322 # 80235c10 <bcache>
    80002d5a:	f0ffd0ef          	jal	ra,80000c68 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002d5e:	0023b497          	auipc	s1,0x23b
    80002d62:	16a4b483          	ld	s1,362(s1) # 8023dec8 <bcache+0x82b8>
    80002d66:	0023b797          	auipc	a5,0x23b
    80002d6a:	11278793          	addi	a5,a5,274 # 8023de78 <bcache+0x8268>
    80002d6e:	02f48b63          	beq	s1,a5,80002da4 <bread+0x64>
    80002d72:	873e                	mv	a4,a5
    80002d74:	a021                	j	80002d7c <bread+0x3c>
    80002d76:	68a4                	ld	s1,80(s1)
    80002d78:	02e48663          	beq	s1,a4,80002da4 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002d7c:	449c                	lw	a5,8(s1)
    80002d7e:	ff279ce3          	bne	a5,s2,80002d76 <bread+0x36>
    80002d82:	44dc                	lw	a5,12(s1)
    80002d84:	ff3799e3          	bne	a5,s3,80002d76 <bread+0x36>
      b->refcnt++;
    80002d88:	40bc                	lw	a5,64(s1)
    80002d8a:	2785                	addiw	a5,a5,1
    80002d8c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002d8e:	00233517          	auipc	a0,0x233
    80002d92:	e8250513          	addi	a0,a0,-382 # 80235c10 <bcache>
    80002d96:	f6bfd0ef          	jal	ra,80000d00 <release>
      acquiresleep(&b->lock);
    80002d9a:	01048513          	addi	a0,s1,16
    80002d9e:	2b0010ef          	jal	ra,8000404e <acquiresleep>
      return b;
    80002da2:	a889                	j	80002df4 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002da4:	0023b497          	auipc	s1,0x23b
    80002da8:	11c4b483          	ld	s1,284(s1) # 8023dec0 <bcache+0x82b0>
    80002dac:	0023b797          	auipc	a5,0x23b
    80002db0:	0cc78793          	addi	a5,a5,204 # 8023de78 <bcache+0x8268>
    80002db4:	00f48863          	beq	s1,a5,80002dc4 <bread+0x84>
    80002db8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002dba:	40bc                	lw	a5,64(s1)
    80002dbc:	cb91                	beqz	a5,80002dd0 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002dbe:	64a4                	ld	s1,72(s1)
    80002dc0:	fee49de3          	bne	s1,a4,80002dba <bread+0x7a>
  panic("bget: no buffers");
    80002dc4:	00004517          	auipc	a0,0x4
    80002dc8:	74c50513          	addi	a0,a0,1868 # 80007510 <syscalls+0xc0>
    80002dcc:	99ffd0ef          	jal	ra,8000076a <panic>
      b->dev = dev;
    80002dd0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002dd4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002dd8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ddc:	4785                	li	a5,1
    80002dde:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002de0:	00233517          	auipc	a0,0x233
    80002de4:	e3050513          	addi	a0,a0,-464 # 80235c10 <bcache>
    80002de8:	f19fd0ef          	jal	ra,80000d00 <release>
      acquiresleep(&b->lock);
    80002dec:	01048513          	addi	a0,s1,16
    80002df0:	25e010ef          	jal	ra,8000404e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002df4:	409c                	lw	a5,0(s1)
    80002df6:	cb89                	beqz	a5,80002e08 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002df8:	8526                	mv	a0,s1
    80002dfa:	70a2                	ld	ra,40(sp)
    80002dfc:	7402                	ld	s0,32(sp)
    80002dfe:	64e2                	ld	s1,24(sp)
    80002e00:	6942                	ld	s2,16(sp)
    80002e02:	69a2                	ld	s3,8(sp)
    80002e04:	6145                	addi	sp,sp,48
    80002e06:	8082                	ret
    virtio_disk_rw(b, 0);
    80002e08:	4581                	li	a1,0
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	1b1020ef          	jal	ra,800057bc <virtio_disk_rw>
    b->valid = 1;
    80002e10:	4785                	li	a5,1
    80002e12:	c09c                	sw	a5,0(s1)
  return b;
    80002e14:	b7d5                	j	80002df8 <bread+0xb8>

0000000080002e16 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	1000                	addi	s0,sp,32
    80002e20:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e22:	0541                	addi	a0,a0,16
    80002e24:	2a8010ef          	jal	ra,800040cc <holdingsleep>
    80002e28:	c911                	beqz	a0,80002e3c <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002e2a:	4585                	li	a1,1
    80002e2c:	8526                	mv	a0,s1
    80002e2e:	18f020ef          	jal	ra,800057bc <virtio_disk_rw>
}
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret
    panic("bwrite");
    80002e3c:	00004517          	auipc	a0,0x4
    80002e40:	6ec50513          	addi	a0,a0,1772 # 80007528 <syscalls+0xd8>
    80002e44:	927fd0ef          	jal	ra,8000076a <panic>

0000000080002e48 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	e04a                	sd	s2,0(sp)
    80002e52:	1000                	addi	s0,sp,32
    80002e54:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e56:	01050913          	addi	s2,a0,16
    80002e5a:	854a                	mv	a0,s2
    80002e5c:	270010ef          	jal	ra,800040cc <holdingsleep>
    80002e60:	c13d                	beqz	a0,80002ec6 <brelse+0x7e>
    panic("brelse");

  releasesleep(&b->lock);
    80002e62:	854a                	mv	a0,s2
    80002e64:	230010ef          	jal	ra,80004094 <releasesleep>

  acquire(&bcache.lock);
    80002e68:	00233517          	auipc	a0,0x233
    80002e6c:	da850513          	addi	a0,a0,-600 # 80235c10 <bcache>
    80002e70:	df9fd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt--;
    80002e74:	40bc                	lw	a5,64(s1)
    80002e76:	37fd                	addiw	a5,a5,-1
    80002e78:	0007871b          	sext.w	a4,a5
    80002e7c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002e7e:	eb05                	bnez	a4,80002eae <brelse+0x66>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002e80:	68bc                	ld	a5,80(s1)
    80002e82:	64b8                	ld	a4,72(s1)
    80002e84:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002e86:	64bc                	ld	a5,72(s1)
    80002e88:	68b8                	ld	a4,80(s1)
    80002e8a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002e8c:	0023b797          	auipc	a5,0x23b
    80002e90:	d8478793          	addi	a5,a5,-636 # 8023dc10 <bcache+0x8000>
    80002e94:	2b87b703          	ld	a4,696(a5)
    80002e98:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002e9a:	0023b717          	auipc	a4,0x23b
    80002e9e:	fde70713          	addi	a4,a4,-34 # 8023de78 <bcache+0x8268>
    80002ea2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ea4:	2b87b703          	ld	a4,696(a5)
    80002ea8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002eaa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002eae:	00233517          	auipc	a0,0x233
    80002eb2:	d6250513          	addi	a0,a0,-670 # 80235c10 <bcache>
    80002eb6:	e4bfd0ef          	jal	ra,80000d00 <release>
}
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	64a2                	ld	s1,8(sp)
    80002ec0:	6902                	ld	s2,0(sp)
    80002ec2:	6105                	addi	sp,sp,32
    80002ec4:	8082                	ret
    panic("brelse");
    80002ec6:	00004517          	auipc	a0,0x4
    80002eca:	66a50513          	addi	a0,a0,1642 # 80007530 <syscalls+0xe0>
    80002ece:	89dfd0ef          	jal	ra,8000076a <panic>

0000000080002ed2 <bpin>:

void
bpin(struct buf *b) {
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	e426                	sd	s1,8(sp)
    80002eda:	1000                	addi	s0,sp,32
    80002edc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ede:	00233517          	auipc	a0,0x233
    80002ee2:	d3250513          	addi	a0,a0,-718 # 80235c10 <bcache>
    80002ee6:	d83fd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt++;
    80002eea:	40bc                	lw	a5,64(s1)
    80002eec:	2785                	addiw	a5,a5,1
    80002eee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ef0:	00233517          	auipc	a0,0x233
    80002ef4:	d2050513          	addi	a0,a0,-736 # 80235c10 <bcache>
    80002ef8:	e09fd0ef          	jal	ra,80000d00 <release>
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	64a2                	ld	s1,8(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <bunpin>:

void
bunpin(struct buf *b) {
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	e426                	sd	s1,8(sp)
    80002f0e:	1000                	addi	s0,sp,32
    80002f10:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002f12:	00233517          	auipc	a0,0x233
    80002f16:	cfe50513          	addi	a0,a0,-770 # 80235c10 <bcache>
    80002f1a:	d4ffd0ef          	jal	ra,80000c68 <acquire>
  b->refcnt--;
    80002f1e:	40bc                	lw	a5,64(s1)
    80002f20:	37fd                	addiw	a5,a5,-1
    80002f22:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002f24:	00233517          	auipc	a0,0x233
    80002f28:	cec50513          	addi	a0,a0,-788 # 80235c10 <bcache>
    80002f2c:	dd5fd0ef          	jal	ra,80000d00 <release>
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	64a2                	ld	s1,8(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	e426                	sd	s1,8(sp)
    80002f42:	e04a                	sd	s2,0(sp)
    80002f44:	1000                	addi	s0,sp,32
    80002f46:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002f48:	00d5d59b          	srliw	a1,a1,0xd
    80002f4c:	0023b797          	auipc	a5,0x23b
    80002f50:	3a07a783          	lw	a5,928(a5) # 8023e2ec <sb+0x1c>
    80002f54:	9dbd                	addw	a1,a1,a5
    80002f56:	debff0ef          	jal	ra,80002d40 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002f5a:	0074f713          	andi	a4,s1,7
    80002f5e:	4785                	li	a5,1
    80002f60:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002f64:	14ce                	slli	s1,s1,0x33
    80002f66:	90d9                	srli	s1,s1,0x36
    80002f68:	00950733          	add	a4,a0,s1
    80002f6c:	05874703          	lbu	a4,88(a4)
    80002f70:	00e7f6b3          	and	a3,a5,a4
    80002f74:	c29d                	beqz	a3,80002f9a <bfree+0x60>
    80002f76:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002f78:	94aa                	add	s1,s1,a0
    80002f7a:	fff7c793          	not	a5,a5
    80002f7e:	8ff9                	and	a5,a5,a4
    80002f80:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002f84:	7d1000ef          	jal	ra,80003f54 <log_write>
  brelse(bp);
    80002f88:	854a                	mv	a0,s2
    80002f8a:	ebfff0ef          	jal	ra,80002e48 <brelse>
}
    80002f8e:	60e2                	ld	ra,24(sp)
    80002f90:	6442                	ld	s0,16(sp)
    80002f92:	64a2                	ld	s1,8(sp)
    80002f94:	6902                	ld	s2,0(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret
    panic("freeing free block");
    80002f9a:	00004517          	auipc	a0,0x4
    80002f9e:	59e50513          	addi	a0,a0,1438 # 80007538 <syscalls+0xe8>
    80002fa2:	fc8fd0ef          	jal	ra,8000076a <panic>

0000000080002fa6 <balloc>:
{
    80002fa6:	711d                	addi	sp,sp,-96
    80002fa8:	ec86                	sd	ra,88(sp)
    80002faa:	e8a2                	sd	s0,80(sp)
    80002fac:	e4a6                	sd	s1,72(sp)
    80002fae:	e0ca                	sd	s2,64(sp)
    80002fb0:	fc4e                	sd	s3,56(sp)
    80002fb2:	f852                	sd	s4,48(sp)
    80002fb4:	f456                	sd	s5,40(sp)
    80002fb6:	f05a                	sd	s6,32(sp)
    80002fb8:	ec5e                	sd	s7,24(sp)
    80002fba:	e862                	sd	s8,16(sp)
    80002fbc:	e466                	sd	s9,8(sp)
    80002fbe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002fc0:	0023b797          	auipc	a5,0x23b
    80002fc4:	3147a783          	lw	a5,788(a5) # 8023e2d4 <sb+0x4>
    80002fc8:	0e078163          	beqz	a5,800030aa <balloc+0x104>
    80002fcc:	8baa                	mv	s7,a0
    80002fce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002fd0:	0023bb17          	auipc	s6,0x23b
    80002fd4:	300b0b13          	addi	s6,s6,768 # 8023e2d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fd8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002fda:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fdc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002fde:	6c89                	lui	s9,0x2
    80002fe0:	a0b5                	j	8000304c <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002fe2:	974a                	add	a4,a4,s2
    80002fe4:	8fd5                	or	a5,a5,a3
    80002fe6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002fea:	854a                	mv	a0,s2
    80002fec:	769000ef          	jal	ra,80003f54 <log_write>
        brelse(bp);
    80002ff0:	854a                	mv	a0,s2
    80002ff2:	e57ff0ef          	jal	ra,80002e48 <brelse>
  bp = bread(dev, bno);
    80002ff6:	85a6                	mv	a1,s1
    80002ff8:	855e                	mv	a0,s7
    80002ffa:	d47ff0ef          	jal	ra,80002d40 <bread>
    80002ffe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003000:	40000613          	li	a2,1024
    80003004:	4581                	li	a1,0
    80003006:	05850513          	addi	a0,a0,88
    8000300a:	d33fd0ef          	jal	ra,80000d3c <memset>
  log_write(bp);
    8000300e:	854a                	mv	a0,s2
    80003010:	745000ef          	jal	ra,80003f54 <log_write>
  brelse(bp);
    80003014:	854a                	mv	a0,s2
    80003016:	e33ff0ef          	jal	ra,80002e48 <brelse>
}
    8000301a:	8526                	mv	a0,s1
    8000301c:	60e6                	ld	ra,88(sp)
    8000301e:	6446                	ld	s0,80(sp)
    80003020:	64a6                	ld	s1,72(sp)
    80003022:	6906                	ld	s2,64(sp)
    80003024:	79e2                	ld	s3,56(sp)
    80003026:	7a42                	ld	s4,48(sp)
    80003028:	7aa2                	ld	s5,40(sp)
    8000302a:	7b02                	ld	s6,32(sp)
    8000302c:	6be2                	ld	s7,24(sp)
    8000302e:	6c42                	ld	s8,16(sp)
    80003030:	6ca2                	ld	s9,8(sp)
    80003032:	6125                	addi	sp,sp,96
    80003034:	8082                	ret
    brelse(bp);
    80003036:	854a                	mv	a0,s2
    80003038:	e11ff0ef          	jal	ra,80002e48 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000303c:	015c87bb          	addw	a5,s9,s5
    80003040:	00078a9b          	sext.w	s5,a5
    80003044:	004b2703          	lw	a4,4(s6)
    80003048:	06eaf163          	bgeu	s5,a4,800030aa <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    8000304c:	41fad79b          	sraiw	a5,s5,0x1f
    80003050:	0137d79b          	srliw	a5,a5,0x13
    80003054:	015787bb          	addw	a5,a5,s5
    80003058:	40d7d79b          	sraiw	a5,a5,0xd
    8000305c:	01cb2583          	lw	a1,28(s6)
    80003060:	9dbd                	addw	a1,a1,a5
    80003062:	855e                	mv	a0,s7
    80003064:	cddff0ef          	jal	ra,80002d40 <bread>
    80003068:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000306a:	004b2503          	lw	a0,4(s6)
    8000306e:	000a849b          	sext.w	s1,s5
    80003072:	8662                	mv	a2,s8
    80003074:	fca4f1e3          	bgeu	s1,a0,80003036 <balloc+0x90>
      m = 1 << (bi % 8);
    80003078:	41f6579b          	sraiw	a5,a2,0x1f
    8000307c:	01d7d69b          	srliw	a3,a5,0x1d
    80003080:	00c6873b          	addw	a4,a3,a2
    80003084:	00777793          	andi	a5,a4,7
    80003088:	9f95                	subw	a5,a5,a3
    8000308a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000308e:	4037571b          	sraiw	a4,a4,0x3
    80003092:	00e906b3          	add	a3,s2,a4
    80003096:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    8000309a:	00d7f5b3          	and	a1,a5,a3
    8000309e:	d1b1                	beqz	a1,80002fe2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030a0:	2605                	addiw	a2,a2,1
    800030a2:	2485                	addiw	s1,s1,1
    800030a4:	fd4618e3          	bne	a2,s4,80003074 <balloc+0xce>
    800030a8:	b779                	j	80003036 <balloc+0x90>
  printf("balloc: out of blocks\n");
    800030aa:	00004517          	auipc	a0,0x4
    800030ae:	4a650513          	addi	a0,a0,1190 # 80007550 <syscalls+0x100>
    800030b2:	bf2fd0ef          	jal	ra,800004a4 <printf>
  return 0;
    800030b6:	4481                	li	s1,0
    800030b8:	b78d                	j	8000301a <balloc+0x74>

00000000800030ba <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800030ba:	7179                	addi	sp,sp,-48
    800030bc:	f406                	sd	ra,40(sp)
    800030be:	f022                	sd	s0,32(sp)
    800030c0:	ec26                	sd	s1,24(sp)
    800030c2:	e84a                	sd	s2,16(sp)
    800030c4:	e44e                	sd	s3,8(sp)
    800030c6:	e052                	sd	s4,0(sp)
    800030c8:	1800                	addi	s0,sp,48
    800030ca:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800030cc:	47ad                	li	a5,11
    800030ce:	02b7e563          	bltu	a5,a1,800030f8 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    800030d2:	02059493          	slli	s1,a1,0x20
    800030d6:	9081                	srli	s1,s1,0x20
    800030d8:	048a                	slli	s1,s1,0x2
    800030da:	94aa                	add	s1,s1,a0
    800030dc:	0504a903          	lw	s2,80(s1)
    800030e0:	06091663          	bnez	s2,8000314c <bmap+0x92>
      addr = balloc(ip->dev);
    800030e4:	4108                	lw	a0,0(a0)
    800030e6:	ec1ff0ef          	jal	ra,80002fa6 <balloc>
    800030ea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800030ee:	04090f63          	beqz	s2,8000314c <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    800030f2:	0524a823          	sw	s2,80(s1)
    800030f6:	a899                	j	8000314c <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    800030f8:	ff45849b          	addiw	s1,a1,-12
    800030fc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003100:	0ff00793          	li	a5,255
    80003104:	06e7eb63          	bltu	a5,a4,8000317a <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003108:	08052903          	lw	s2,128(a0)
    8000310c:	00091b63          	bnez	s2,80003122 <bmap+0x68>
      addr = balloc(ip->dev);
    80003110:	4108                	lw	a0,0(a0)
    80003112:	e95ff0ef          	jal	ra,80002fa6 <balloc>
    80003116:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000311a:	02090963          	beqz	s2,8000314c <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000311e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003122:	85ca                	mv	a1,s2
    80003124:	0009a503          	lw	a0,0(s3)
    80003128:	c19ff0ef          	jal	ra,80002d40 <bread>
    8000312c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000312e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003132:	02049593          	slli	a1,s1,0x20
    80003136:	9181                	srli	a1,a1,0x20
    80003138:	058a                	slli	a1,a1,0x2
    8000313a:	00b784b3          	add	s1,a5,a1
    8000313e:	0004a903          	lw	s2,0(s1)
    80003142:	00090e63          	beqz	s2,8000315e <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003146:	8552                	mv	a0,s4
    80003148:	d01ff0ef          	jal	ra,80002e48 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000314c:	854a                	mv	a0,s2
    8000314e:	70a2                	ld	ra,40(sp)
    80003150:	7402                	ld	s0,32(sp)
    80003152:	64e2                	ld	s1,24(sp)
    80003154:	6942                	ld	s2,16(sp)
    80003156:	69a2                	ld	s3,8(sp)
    80003158:	6a02                	ld	s4,0(sp)
    8000315a:	6145                	addi	sp,sp,48
    8000315c:	8082                	ret
      addr = balloc(ip->dev);
    8000315e:	0009a503          	lw	a0,0(s3)
    80003162:	e45ff0ef          	jal	ra,80002fa6 <balloc>
    80003166:	0005091b          	sext.w	s2,a0
      if(addr){
    8000316a:	fc090ee3          	beqz	s2,80003146 <bmap+0x8c>
        a[bn] = addr;
    8000316e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003172:	8552                	mv	a0,s4
    80003174:	5e1000ef          	jal	ra,80003f54 <log_write>
    80003178:	b7f9                	j	80003146 <bmap+0x8c>
  panic("bmap: out of range");
    8000317a:	00004517          	auipc	a0,0x4
    8000317e:	3ee50513          	addi	a0,a0,1006 # 80007568 <syscalls+0x118>
    80003182:	de8fd0ef          	jal	ra,8000076a <panic>

0000000080003186 <iget>:
{
    80003186:	7179                	addi	sp,sp,-48
    80003188:	f406                	sd	ra,40(sp)
    8000318a:	f022                	sd	s0,32(sp)
    8000318c:	ec26                	sd	s1,24(sp)
    8000318e:	e84a                	sd	s2,16(sp)
    80003190:	e44e                	sd	s3,8(sp)
    80003192:	e052                	sd	s4,0(sp)
    80003194:	1800                	addi	s0,sp,48
    80003196:	89aa                	mv	s3,a0
    80003198:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000319a:	0023b517          	auipc	a0,0x23b
    8000319e:	15650513          	addi	a0,a0,342 # 8023e2f0 <itable>
    800031a2:	ac7fd0ef          	jal	ra,80000c68 <acquire>
  empty = 0;
    800031a6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800031a8:	0023b497          	auipc	s1,0x23b
    800031ac:	16048493          	addi	s1,s1,352 # 8023e308 <itable+0x18>
    800031b0:	0023d697          	auipc	a3,0x23d
    800031b4:	be868693          	addi	a3,a3,-1048 # 8023fd98 <log>
    800031b8:	a039                	j	800031c6 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800031ba:	02090963          	beqz	s2,800031ec <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800031be:	08848493          	addi	s1,s1,136
    800031c2:	02d48863          	beq	s1,a3,800031f2 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800031c6:	449c                	lw	a5,8(s1)
    800031c8:	fef059e3          	blez	a5,800031ba <iget+0x34>
    800031cc:	4098                	lw	a4,0(s1)
    800031ce:	ff3716e3          	bne	a4,s3,800031ba <iget+0x34>
    800031d2:	40d8                	lw	a4,4(s1)
    800031d4:	ff4713e3          	bne	a4,s4,800031ba <iget+0x34>
      ip->ref++;
    800031d8:	2785                	addiw	a5,a5,1
    800031da:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800031dc:	0023b517          	auipc	a0,0x23b
    800031e0:	11450513          	addi	a0,a0,276 # 8023e2f0 <itable>
    800031e4:	b1dfd0ef          	jal	ra,80000d00 <release>
      return ip;
    800031e8:	8926                	mv	s2,s1
    800031ea:	a02d                	j	80003214 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800031ec:	fbe9                	bnez	a5,800031be <iget+0x38>
    800031ee:	8926                	mv	s2,s1
    800031f0:	b7f9                	j	800031be <iget+0x38>
  if(empty == 0)
    800031f2:	02090a63          	beqz	s2,80003226 <iget+0xa0>
  ip->dev = dev;
    800031f6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800031fa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800031fe:	4785                	li	a5,1
    80003200:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003204:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003208:	0023b517          	auipc	a0,0x23b
    8000320c:	0e850513          	addi	a0,a0,232 # 8023e2f0 <itable>
    80003210:	af1fd0ef          	jal	ra,80000d00 <release>
}
    80003214:	854a                	mv	a0,s2
    80003216:	70a2                	ld	ra,40(sp)
    80003218:	7402                	ld	s0,32(sp)
    8000321a:	64e2                	ld	s1,24(sp)
    8000321c:	6942                	ld	s2,16(sp)
    8000321e:	69a2                	ld	s3,8(sp)
    80003220:	6a02                	ld	s4,0(sp)
    80003222:	6145                	addi	sp,sp,48
    80003224:	8082                	ret
    panic("iget: no inodes");
    80003226:	00004517          	auipc	a0,0x4
    8000322a:	35a50513          	addi	a0,a0,858 # 80007580 <syscalls+0x130>
    8000322e:	d3cfd0ef          	jal	ra,8000076a <panic>

0000000080003232 <iinit>:
{
    80003232:	7179                	addi	sp,sp,-48
    80003234:	f406                	sd	ra,40(sp)
    80003236:	f022                	sd	s0,32(sp)
    80003238:	ec26                	sd	s1,24(sp)
    8000323a:	e84a                	sd	s2,16(sp)
    8000323c:	e44e                	sd	s3,8(sp)
    8000323e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003240:	00004597          	auipc	a1,0x4
    80003244:	35058593          	addi	a1,a1,848 # 80007590 <syscalls+0x140>
    80003248:	0023b517          	auipc	a0,0x23b
    8000324c:	0a850513          	addi	a0,a0,168 # 8023e2f0 <itable>
    80003250:	999fd0ef          	jal	ra,80000be8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003254:	0023b497          	auipc	s1,0x23b
    80003258:	0c448493          	addi	s1,s1,196 # 8023e318 <itable+0x28>
    8000325c:	0023d997          	auipc	s3,0x23d
    80003260:	b4c98993          	addi	s3,s3,-1204 # 8023fda8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003264:	00004917          	auipc	s2,0x4
    80003268:	33490913          	addi	s2,s2,820 # 80007598 <syscalls+0x148>
    8000326c:	85ca                	mv	a1,s2
    8000326e:	8526                	mv	a0,s1
    80003270:	5a9000ef          	jal	ra,80004018 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003274:	08848493          	addi	s1,s1,136
    80003278:	ff349ae3          	bne	s1,s3,8000326c <iinit+0x3a>
}
    8000327c:	70a2                	ld	ra,40(sp)
    8000327e:	7402                	ld	s0,32(sp)
    80003280:	64e2                	ld	s1,24(sp)
    80003282:	6942                	ld	s2,16(sp)
    80003284:	69a2                	ld	s3,8(sp)
    80003286:	6145                	addi	sp,sp,48
    80003288:	8082                	ret

000000008000328a <ialloc>:
{
    8000328a:	715d                	addi	sp,sp,-80
    8000328c:	e486                	sd	ra,72(sp)
    8000328e:	e0a2                	sd	s0,64(sp)
    80003290:	fc26                	sd	s1,56(sp)
    80003292:	f84a                	sd	s2,48(sp)
    80003294:	f44e                	sd	s3,40(sp)
    80003296:	f052                	sd	s4,32(sp)
    80003298:	ec56                	sd	s5,24(sp)
    8000329a:	e85a                	sd	s6,16(sp)
    8000329c:	e45e                	sd	s7,8(sp)
    8000329e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800032a0:	0023b717          	auipc	a4,0x23b
    800032a4:	03c72703          	lw	a4,60(a4) # 8023e2dc <sb+0xc>
    800032a8:	4785                	li	a5,1
    800032aa:	04e7f663          	bgeu	a5,a4,800032f6 <ialloc+0x6c>
    800032ae:	8aaa                	mv	s5,a0
    800032b0:	8bae                	mv	s7,a1
    800032b2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800032b4:	0023ba17          	auipc	s4,0x23b
    800032b8:	01ca0a13          	addi	s4,s4,28 # 8023e2d0 <sb>
    800032bc:	00048b1b          	sext.w	s6,s1
    800032c0:	0044d793          	srli	a5,s1,0x4
    800032c4:	018a2583          	lw	a1,24(s4)
    800032c8:	9dbd                	addw	a1,a1,a5
    800032ca:	8556                	mv	a0,s5
    800032cc:	a75ff0ef          	jal	ra,80002d40 <bread>
    800032d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800032d2:	05850993          	addi	s3,a0,88
    800032d6:	00f4f793          	andi	a5,s1,15
    800032da:	079a                	slli	a5,a5,0x6
    800032dc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800032de:	00099783          	lh	a5,0(s3)
    800032e2:	cf85                	beqz	a5,8000331a <ialloc+0x90>
    brelse(bp);
    800032e4:	b65ff0ef          	jal	ra,80002e48 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800032e8:	0485                	addi	s1,s1,1
    800032ea:	00ca2703          	lw	a4,12(s4)
    800032ee:	0004879b          	sext.w	a5,s1
    800032f2:	fce7e5e3          	bltu	a5,a4,800032bc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800032f6:	00004517          	auipc	a0,0x4
    800032fa:	2aa50513          	addi	a0,a0,682 # 800075a0 <syscalls+0x150>
    800032fe:	9a6fd0ef          	jal	ra,800004a4 <printf>
  return 0;
    80003302:	4501                	li	a0,0
}
    80003304:	60a6                	ld	ra,72(sp)
    80003306:	6406                	ld	s0,64(sp)
    80003308:	74e2                	ld	s1,56(sp)
    8000330a:	7942                	ld	s2,48(sp)
    8000330c:	79a2                	ld	s3,40(sp)
    8000330e:	7a02                	ld	s4,32(sp)
    80003310:	6ae2                	ld	s5,24(sp)
    80003312:	6b42                	ld	s6,16(sp)
    80003314:	6ba2                	ld	s7,8(sp)
    80003316:	6161                	addi	sp,sp,80
    80003318:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000331a:	04000613          	li	a2,64
    8000331e:	4581                	li	a1,0
    80003320:	854e                	mv	a0,s3
    80003322:	a1bfd0ef          	jal	ra,80000d3c <memset>
      dip->type = type;
    80003326:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000332a:	854a                	mv	a0,s2
    8000332c:	429000ef          	jal	ra,80003f54 <log_write>
      brelse(bp);
    80003330:	854a                	mv	a0,s2
    80003332:	b17ff0ef          	jal	ra,80002e48 <brelse>
      return iget(dev, inum);
    80003336:	85da                	mv	a1,s6
    80003338:	8556                	mv	a0,s5
    8000333a:	e4dff0ef          	jal	ra,80003186 <iget>
    8000333e:	b7d9                	j	80003304 <ialloc+0x7a>

0000000080003340 <iupdate>:
{
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	e04a                	sd	s2,0(sp)
    8000334a:	1000                	addi	s0,sp,32
    8000334c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000334e:	415c                	lw	a5,4(a0)
    80003350:	0047d79b          	srliw	a5,a5,0x4
    80003354:	0023b597          	auipc	a1,0x23b
    80003358:	f945a583          	lw	a1,-108(a1) # 8023e2e8 <sb+0x18>
    8000335c:	9dbd                	addw	a1,a1,a5
    8000335e:	4108                	lw	a0,0(a0)
    80003360:	9e1ff0ef          	jal	ra,80002d40 <bread>
    80003364:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003366:	05850793          	addi	a5,a0,88
    8000336a:	40c8                	lw	a0,4(s1)
    8000336c:	893d                	andi	a0,a0,15
    8000336e:	051a                	slli	a0,a0,0x6
    80003370:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003372:	04449703          	lh	a4,68(s1)
    80003376:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000337a:	04649703          	lh	a4,70(s1)
    8000337e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003382:	04849703          	lh	a4,72(s1)
    80003386:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000338a:	04a49703          	lh	a4,74(s1)
    8000338e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003392:	44f8                	lw	a4,76(s1)
    80003394:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003396:	03400613          	li	a2,52
    8000339a:	05048593          	addi	a1,s1,80
    8000339e:	0531                	addi	a0,a0,12
    800033a0:	9f9fd0ef          	jal	ra,80000d98 <memmove>
  log_write(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	3af000ef          	jal	ra,80003f54 <log_write>
  brelse(bp);
    800033aa:	854a                	mv	a0,s2
    800033ac:	a9dff0ef          	jal	ra,80002e48 <brelse>
}
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	64a2                	ld	s1,8(sp)
    800033b6:	6902                	ld	s2,0(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <idup>:
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	e426                	sd	s1,8(sp)
    800033c4:	1000                	addi	s0,sp,32
    800033c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033c8:	0023b517          	auipc	a0,0x23b
    800033cc:	f2850513          	addi	a0,a0,-216 # 8023e2f0 <itable>
    800033d0:	899fd0ef          	jal	ra,80000c68 <acquire>
  ip->ref++;
    800033d4:	449c                	lw	a5,8(s1)
    800033d6:	2785                	addiw	a5,a5,1
    800033d8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033da:	0023b517          	auipc	a0,0x23b
    800033de:	f1650513          	addi	a0,a0,-234 # 8023e2f0 <itable>
    800033e2:	91ffd0ef          	jal	ra,80000d00 <release>
}
    800033e6:	8526                	mv	a0,s1
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <ilock>:
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	e04a                	sd	s2,0(sp)
    800033fc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800033fe:	c105                	beqz	a0,8000341e <ilock+0x2c>
    80003400:	84aa                	mv	s1,a0
    80003402:	451c                	lw	a5,8(a0)
    80003404:	00f05d63          	blez	a5,8000341e <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003408:	0541                	addi	a0,a0,16
    8000340a:	445000ef          	jal	ra,8000404e <acquiresleep>
  if(ip->valid == 0){
    8000340e:	40bc                	lw	a5,64(s1)
    80003410:	cf89                	beqz	a5,8000342a <ilock+0x38>
}
    80003412:	60e2                	ld	ra,24(sp)
    80003414:	6442                	ld	s0,16(sp)
    80003416:	64a2                	ld	s1,8(sp)
    80003418:	6902                	ld	s2,0(sp)
    8000341a:	6105                	addi	sp,sp,32
    8000341c:	8082                	ret
    panic("ilock");
    8000341e:	00004517          	auipc	a0,0x4
    80003422:	19a50513          	addi	a0,a0,410 # 800075b8 <syscalls+0x168>
    80003426:	b44fd0ef          	jal	ra,8000076a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000342a:	40dc                	lw	a5,4(s1)
    8000342c:	0047d79b          	srliw	a5,a5,0x4
    80003430:	0023b597          	auipc	a1,0x23b
    80003434:	eb85a583          	lw	a1,-328(a1) # 8023e2e8 <sb+0x18>
    80003438:	9dbd                	addw	a1,a1,a5
    8000343a:	4088                	lw	a0,0(s1)
    8000343c:	905ff0ef          	jal	ra,80002d40 <bread>
    80003440:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003442:	05850593          	addi	a1,a0,88
    80003446:	40dc                	lw	a5,4(s1)
    80003448:	8bbd                	andi	a5,a5,15
    8000344a:	079a                	slli	a5,a5,0x6
    8000344c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000344e:	00059783          	lh	a5,0(a1)
    80003452:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003456:	00259783          	lh	a5,2(a1)
    8000345a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000345e:	00459783          	lh	a5,4(a1)
    80003462:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003466:	00659783          	lh	a5,6(a1)
    8000346a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000346e:	459c                	lw	a5,8(a1)
    80003470:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003472:	03400613          	li	a2,52
    80003476:	05b1                	addi	a1,a1,12
    80003478:	05048513          	addi	a0,s1,80
    8000347c:	91dfd0ef          	jal	ra,80000d98 <memmove>
    brelse(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	9c7ff0ef          	jal	ra,80002e48 <brelse>
    ip->valid = 1;
    80003486:	4785                	li	a5,1
    80003488:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000348a:	04449783          	lh	a5,68(s1)
    8000348e:	f3d1                	bnez	a5,80003412 <ilock+0x20>
      panic("ilock: no type");
    80003490:	00004517          	auipc	a0,0x4
    80003494:	13050513          	addi	a0,a0,304 # 800075c0 <syscalls+0x170>
    80003498:	ad2fd0ef          	jal	ra,8000076a <panic>

000000008000349c <iunlock>:
{
    8000349c:	1101                	addi	sp,sp,-32
    8000349e:	ec06                	sd	ra,24(sp)
    800034a0:	e822                	sd	s0,16(sp)
    800034a2:	e426                	sd	s1,8(sp)
    800034a4:	e04a                	sd	s2,0(sp)
    800034a6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800034a8:	c505                	beqz	a0,800034d0 <iunlock+0x34>
    800034aa:	84aa                	mv	s1,a0
    800034ac:	01050913          	addi	s2,a0,16
    800034b0:	854a                	mv	a0,s2
    800034b2:	41b000ef          	jal	ra,800040cc <holdingsleep>
    800034b6:	cd09                	beqz	a0,800034d0 <iunlock+0x34>
    800034b8:	449c                	lw	a5,8(s1)
    800034ba:	00f05b63          	blez	a5,800034d0 <iunlock+0x34>
  releasesleep(&ip->lock);
    800034be:	854a                	mv	a0,s2
    800034c0:	3d5000ef          	jal	ra,80004094 <releasesleep>
}
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	64a2                	ld	s1,8(sp)
    800034ca:	6902                	ld	s2,0(sp)
    800034cc:	6105                	addi	sp,sp,32
    800034ce:	8082                	ret
    panic("iunlock");
    800034d0:	00004517          	auipc	a0,0x4
    800034d4:	10050513          	addi	a0,a0,256 # 800075d0 <syscalls+0x180>
    800034d8:	a92fd0ef          	jal	ra,8000076a <panic>

00000000800034dc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	e052                	sd	s4,0(sp)
    800034ea:	1800                	addi	s0,sp,48
    800034ec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800034ee:	05050493          	addi	s1,a0,80
    800034f2:	08050913          	addi	s2,a0,128
    800034f6:	a021                	j	800034fe <itrunc+0x22>
    800034f8:	0491                	addi	s1,s1,4
    800034fa:	01248b63          	beq	s1,s2,80003510 <itrunc+0x34>
    if(ip->addrs[i]){
    800034fe:	408c                	lw	a1,0(s1)
    80003500:	dde5                	beqz	a1,800034f8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003502:	0009a503          	lw	a0,0(s3)
    80003506:	a35ff0ef          	jal	ra,80002f3a <bfree>
      ip->addrs[i] = 0;
    8000350a:	0004a023          	sw	zero,0(s1)
    8000350e:	b7ed                	j	800034f8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003510:	0809a583          	lw	a1,128(s3)
    80003514:	ed91                	bnez	a1,80003530 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003516:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000351a:	854e                	mv	a0,s3
    8000351c:	e25ff0ef          	jal	ra,80003340 <iupdate>
}
    80003520:	70a2                	ld	ra,40(sp)
    80003522:	7402                	ld	s0,32(sp)
    80003524:	64e2                	ld	s1,24(sp)
    80003526:	6942                	ld	s2,16(sp)
    80003528:	69a2                	ld	s3,8(sp)
    8000352a:	6a02                	ld	s4,0(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003530:	0009a503          	lw	a0,0(s3)
    80003534:	80dff0ef          	jal	ra,80002d40 <bread>
    80003538:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000353a:	05850493          	addi	s1,a0,88
    8000353e:	45850913          	addi	s2,a0,1112
    80003542:	a021                	j	8000354a <itrunc+0x6e>
    80003544:	0491                	addi	s1,s1,4
    80003546:	01248963          	beq	s1,s2,80003558 <itrunc+0x7c>
      if(a[j])
    8000354a:	408c                	lw	a1,0(s1)
    8000354c:	dde5                	beqz	a1,80003544 <itrunc+0x68>
        bfree(ip->dev, a[j]);
    8000354e:	0009a503          	lw	a0,0(s3)
    80003552:	9e9ff0ef          	jal	ra,80002f3a <bfree>
    80003556:	b7fd                	j	80003544 <itrunc+0x68>
    brelse(bp);
    80003558:	8552                	mv	a0,s4
    8000355a:	8efff0ef          	jal	ra,80002e48 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000355e:	0809a583          	lw	a1,128(s3)
    80003562:	0009a503          	lw	a0,0(s3)
    80003566:	9d5ff0ef          	jal	ra,80002f3a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000356a:	0809a023          	sw	zero,128(s3)
    8000356e:	b765                	j	80003516 <itrunc+0x3a>

0000000080003570 <iput>:
{
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	e04a                	sd	s2,0(sp)
    8000357a:	1000                	addi	s0,sp,32
    8000357c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000357e:	0023b517          	auipc	a0,0x23b
    80003582:	d7250513          	addi	a0,a0,-654 # 8023e2f0 <itable>
    80003586:	ee2fd0ef          	jal	ra,80000c68 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000358a:	4498                	lw	a4,8(s1)
    8000358c:	4785                	li	a5,1
    8000358e:	02f70163          	beq	a4,a5,800035b0 <iput+0x40>
  ip->ref--;
    80003592:	449c                	lw	a5,8(s1)
    80003594:	37fd                	addiw	a5,a5,-1
    80003596:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003598:	0023b517          	auipc	a0,0x23b
    8000359c:	d5850513          	addi	a0,a0,-680 # 8023e2f0 <itable>
    800035a0:	f60fd0ef          	jal	ra,80000d00 <release>
}
    800035a4:	60e2                	ld	ra,24(sp)
    800035a6:	6442                	ld	s0,16(sp)
    800035a8:	64a2                	ld	s1,8(sp)
    800035aa:	6902                	ld	s2,0(sp)
    800035ac:	6105                	addi	sp,sp,32
    800035ae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800035b0:	40bc                	lw	a5,64(s1)
    800035b2:	d3e5                	beqz	a5,80003592 <iput+0x22>
    800035b4:	04a49783          	lh	a5,74(s1)
    800035b8:	ffe9                	bnez	a5,80003592 <iput+0x22>
    acquiresleep(&ip->lock);
    800035ba:	01048913          	addi	s2,s1,16
    800035be:	854a                	mv	a0,s2
    800035c0:	28f000ef          	jal	ra,8000404e <acquiresleep>
    release(&itable.lock);
    800035c4:	0023b517          	auipc	a0,0x23b
    800035c8:	d2c50513          	addi	a0,a0,-724 # 8023e2f0 <itable>
    800035cc:	f34fd0ef          	jal	ra,80000d00 <release>
    itrunc(ip);
    800035d0:	8526                	mv	a0,s1
    800035d2:	f0bff0ef          	jal	ra,800034dc <itrunc>
    ip->type = 0;
    800035d6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800035da:	8526                	mv	a0,s1
    800035dc:	d65ff0ef          	jal	ra,80003340 <iupdate>
    ip->valid = 0;
    800035e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800035e4:	854a                	mv	a0,s2
    800035e6:	2af000ef          	jal	ra,80004094 <releasesleep>
    acquire(&itable.lock);
    800035ea:	0023b517          	auipc	a0,0x23b
    800035ee:	d0650513          	addi	a0,a0,-762 # 8023e2f0 <itable>
    800035f2:	e76fd0ef          	jal	ra,80000c68 <acquire>
    800035f6:	bf71                	j	80003592 <iput+0x22>

00000000800035f8 <iunlockput>:
{
    800035f8:	1101                	addi	sp,sp,-32
    800035fa:	ec06                	sd	ra,24(sp)
    800035fc:	e822                	sd	s0,16(sp)
    800035fe:	e426                	sd	s1,8(sp)
    80003600:	1000                	addi	s0,sp,32
    80003602:	84aa                	mv	s1,a0
  iunlock(ip);
    80003604:	e99ff0ef          	jal	ra,8000349c <iunlock>
  iput(ip);
    80003608:	8526                	mv	a0,s1
    8000360a:	f67ff0ef          	jal	ra,80003570 <iput>
}
    8000360e:	60e2                	ld	ra,24(sp)
    80003610:	6442                	ld	s0,16(sp)
    80003612:	64a2                	ld	s1,8(sp)
    80003614:	6105                	addi	sp,sp,32
    80003616:	8082                	ret

0000000080003618 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003618:	0023b717          	auipc	a4,0x23b
    8000361c:	cc472703          	lw	a4,-828(a4) # 8023e2dc <sb+0xc>
    80003620:	4785                	li	a5,1
    80003622:	0ae7ff63          	bgeu	a5,a4,800036e0 <ireclaim+0xc8>
{
    80003626:	7139                	addi	sp,sp,-64
    80003628:	fc06                	sd	ra,56(sp)
    8000362a:	f822                	sd	s0,48(sp)
    8000362c:	f426                	sd	s1,40(sp)
    8000362e:	f04a                	sd	s2,32(sp)
    80003630:	ec4e                	sd	s3,24(sp)
    80003632:	e852                	sd	s4,16(sp)
    80003634:	e456                	sd	s5,8(sp)
    80003636:	e05a                	sd	s6,0(sp)
    80003638:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000363a:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000363c:	00050a1b          	sext.w	s4,a0
    80003640:	0023ba97          	auipc	s5,0x23b
    80003644:	c90a8a93          	addi	s5,s5,-880 # 8023e2d0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003648:	00004b17          	auipc	s6,0x4
    8000364c:	f90b0b13          	addi	s6,s6,-112 # 800075d8 <syscalls+0x188>
    80003650:	a099                	j	80003696 <ireclaim+0x7e>
    80003652:	85ce                	mv	a1,s3
    80003654:	855a                	mv	a0,s6
    80003656:	e4ffc0ef          	jal	ra,800004a4 <printf>
      ip = iget(dev, inum);
    8000365a:	85ce                	mv	a1,s3
    8000365c:	8552                	mv	a0,s4
    8000365e:	b29ff0ef          	jal	ra,80003186 <iget>
    80003662:	89aa                	mv	s3,a0
    brelse(bp);
    80003664:	854a                	mv	a0,s2
    80003666:	fe2ff0ef          	jal	ra,80002e48 <brelse>
    if (ip) {
    8000366a:	00098f63          	beqz	s3,80003688 <ireclaim+0x70>
      begin_op();
    8000366e:	762000ef          	jal	ra,80003dd0 <begin_op>
      ilock(ip);
    80003672:	854e                	mv	a0,s3
    80003674:	d7fff0ef          	jal	ra,800033f2 <ilock>
      iunlock(ip);
    80003678:	854e                	mv	a0,s3
    8000367a:	e23ff0ef          	jal	ra,8000349c <iunlock>
      iput(ip);
    8000367e:	854e                	mv	a0,s3
    80003680:	ef1ff0ef          	jal	ra,80003570 <iput>
      end_op();
    80003684:	7bc000ef          	jal	ra,80003e40 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003688:	0485                	addi	s1,s1,1
    8000368a:	00caa703          	lw	a4,12(s5)
    8000368e:	0004879b          	sext.w	a5,s1
    80003692:	02e7fd63          	bgeu	a5,a4,800036cc <ireclaim+0xb4>
    80003696:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000369a:	0044d793          	srli	a5,s1,0x4
    8000369e:	018aa583          	lw	a1,24(s5)
    800036a2:	9dbd                	addw	a1,a1,a5
    800036a4:	8552                	mv	a0,s4
    800036a6:	e9aff0ef          	jal	ra,80002d40 <bread>
    800036aa:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    800036ac:	05850793          	addi	a5,a0,88
    800036b0:	00f9f713          	andi	a4,s3,15
    800036b4:	071a                	slli	a4,a4,0x6
    800036b6:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    800036b8:	00079703          	lh	a4,0(a5)
    800036bc:	c701                	beqz	a4,800036c4 <ireclaim+0xac>
    800036be:	00679783          	lh	a5,6(a5)
    800036c2:	dbc1                	beqz	a5,80003652 <ireclaim+0x3a>
    brelse(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	f82ff0ef          	jal	ra,80002e48 <brelse>
    if (ip) {
    800036ca:	bf7d                	j	80003688 <ireclaim+0x70>
}
    800036cc:	70e2                	ld	ra,56(sp)
    800036ce:	7442                	ld	s0,48(sp)
    800036d0:	74a2                	ld	s1,40(sp)
    800036d2:	7902                	ld	s2,32(sp)
    800036d4:	69e2                	ld	s3,24(sp)
    800036d6:	6a42                	ld	s4,16(sp)
    800036d8:	6aa2                	ld	s5,8(sp)
    800036da:	6b02                	ld	s6,0(sp)
    800036dc:	6121                	addi	sp,sp,64
    800036de:	8082                	ret
    800036e0:	8082                	ret

00000000800036e2 <fsinit>:
fsinit(int dev) {
    800036e2:	7179                	addi	sp,sp,-48
    800036e4:	f406                	sd	ra,40(sp)
    800036e6:	f022                	sd	s0,32(sp)
    800036e8:	ec26                	sd	s1,24(sp)
    800036ea:	e84a                	sd	s2,16(sp)
    800036ec:	e44e                	sd	s3,8(sp)
    800036ee:	1800                	addi	s0,sp,48
    800036f0:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800036f2:	4585                	li	a1,1
    800036f4:	e4cff0ef          	jal	ra,80002d40 <bread>
    800036f8:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036fa:	0023b997          	auipc	s3,0x23b
    800036fe:	bd698993          	addi	s3,s3,-1066 # 8023e2d0 <sb>
    80003702:	02000613          	li	a2,32
    80003706:	05850593          	addi	a1,a0,88
    8000370a:	854e                	mv	a0,s3
    8000370c:	e8cfd0ef          	jal	ra,80000d98 <memmove>
  brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	f36ff0ef          	jal	ra,80002e48 <brelse>
  if(sb.magic != FSMAGIC)
    80003716:	0009a703          	lw	a4,0(s3)
    8000371a:	102037b7          	lui	a5,0x10203
    8000371e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003722:	02f71363          	bne	a4,a5,80003748 <fsinit+0x66>
  initlog(dev, &sb);
    80003726:	0023b597          	auipc	a1,0x23b
    8000372a:	baa58593          	addi	a1,a1,-1110 # 8023e2d0 <sb>
    8000372e:	8526                	mv	a0,s1
    80003730:	616000ef          	jal	ra,80003d46 <initlog>
  ireclaim(dev);
    80003734:	8526                	mv	a0,s1
    80003736:	ee3ff0ef          	jal	ra,80003618 <ireclaim>
}
    8000373a:	70a2                	ld	ra,40(sp)
    8000373c:	7402                	ld	s0,32(sp)
    8000373e:	64e2                	ld	s1,24(sp)
    80003740:	6942                	ld	s2,16(sp)
    80003742:	69a2                	ld	s3,8(sp)
    80003744:	6145                	addi	sp,sp,48
    80003746:	8082                	ret
    panic("invalid file system");
    80003748:	00004517          	auipc	a0,0x4
    8000374c:	eb050513          	addi	a0,a0,-336 # 800075f8 <syscalls+0x1a8>
    80003750:	81afd0ef          	jal	ra,8000076a <panic>

0000000080003754 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003754:	1141                	addi	sp,sp,-16
    80003756:	e422                	sd	s0,8(sp)
    80003758:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000375a:	411c                	lw	a5,0(a0)
    8000375c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000375e:	415c                	lw	a5,4(a0)
    80003760:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003762:	04451783          	lh	a5,68(a0)
    80003766:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000376a:	04a51783          	lh	a5,74(a0)
    8000376e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003772:	04c56783          	lwu	a5,76(a0)
    80003776:	e99c                	sd	a5,16(a1)
}
    80003778:	6422                	ld	s0,8(sp)
    8000377a:	0141                	addi	sp,sp,16
    8000377c:	8082                	ret

000000008000377e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000377e:	457c                	lw	a5,76(a0)
    80003780:	0cd7ef63          	bltu	a5,a3,8000385e <readi+0xe0>
{
    80003784:	7159                	addi	sp,sp,-112
    80003786:	f486                	sd	ra,104(sp)
    80003788:	f0a2                	sd	s0,96(sp)
    8000378a:	eca6                	sd	s1,88(sp)
    8000378c:	e8ca                	sd	s2,80(sp)
    8000378e:	e4ce                	sd	s3,72(sp)
    80003790:	e0d2                	sd	s4,64(sp)
    80003792:	fc56                	sd	s5,56(sp)
    80003794:	f85a                	sd	s6,48(sp)
    80003796:	f45e                	sd	s7,40(sp)
    80003798:	f062                	sd	s8,32(sp)
    8000379a:	ec66                	sd	s9,24(sp)
    8000379c:	e86a                	sd	s10,16(sp)
    8000379e:	e46e                	sd	s11,8(sp)
    800037a0:	1880                	addi	s0,sp,112
    800037a2:	8b2a                	mv	s6,a0
    800037a4:	8bae                	mv	s7,a1
    800037a6:	8a32                	mv	s4,a2
    800037a8:	84b6                	mv	s1,a3
    800037aa:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800037ac:	9f35                	addw	a4,a4,a3
    return 0;
    800037ae:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800037b0:	08d76663          	bltu	a4,a3,8000383c <readi+0xbe>
  if(off + n > ip->size)
    800037b4:	00e7f463          	bgeu	a5,a4,800037bc <readi+0x3e>
    n = ip->size - off;
    800037b8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037bc:	080a8f63          	beqz	s5,8000385a <readi+0xdc>
    800037c0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800037c2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800037c6:	5c7d                	li	s8,-1
    800037c8:	a80d                	j	800037fa <readi+0x7c>
    800037ca:	020d1d93          	slli	s11,s10,0x20
    800037ce:	020ddd93          	srli	s11,s11,0x20
    800037d2:	05890793          	addi	a5,s2,88
    800037d6:	86ee                	mv	a3,s11
    800037d8:	963e                	add	a2,a2,a5
    800037da:	85d2                	mv	a1,s4
    800037dc:	855e                	mv	a0,s7
    800037de:	c6bfe0ef          	jal	ra,80002448 <either_copyout>
    800037e2:	05850763          	beq	a0,s8,80003830 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	e60ff0ef          	jal	ra,80002e48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037ec:	013d09bb          	addw	s3,s10,s3
    800037f0:	009d04bb          	addw	s1,s10,s1
    800037f4:	9a6e                	add	s4,s4,s11
    800037f6:	0559f163          	bgeu	s3,s5,80003838 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    800037fa:	00a4d59b          	srliw	a1,s1,0xa
    800037fe:	855a                	mv	a0,s6
    80003800:	8bbff0ef          	jal	ra,800030ba <bmap>
    80003804:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003808:	c985                	beqz	a1,80003838 <readi+0xba>
    bp = bread(ip->dev, addr);
    8000380a:	000b2503          	lw	a0,0(s6)
    8000380e:	d32ff0ef          	jal	ra,80002d40 <bread>
    80003812:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003814:	3ff4f613          	andi	a2,s1,1023
    80003818:	40cc87bb          	subw	a5,s9,a2
    8000381c:	413a873b          	subw	a4,s5,s3
    80003820:	8d3e                	mv	s10,a5
    80003822:	2781                	sext.w	a5,a5
    80003824:	0007069b          	sext.w	a3,a4
    80003828:	faf6f1e3          	bgeu	a3,a5,800037ca <readi+0x4c>
    8000382c:	8d3a                	mv	s10,a4
    8000382e:	bf71                	j	800037ca <readi+0x4c>
      brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	e16ff0ef          	jal	ra,80002e48 <brelse>
      tot = -1;
    80003836:	59fd                	li	s3,-1
  }
  return tot;
    80003838:	0009851b          	sext.w	a0,s3
}
    8000383c:	70a6                	ld	ra,104(sp)
    8000383e:	7406                	ld	s0,96(sp)
    80003840:	64e6                	ld	s1,88(sp)
    80003842:	6946                	ld	s2,80(sp)
    80003844:	69a6                	ld	s3,72(sp)
    80003846:	6a06                	ld	s4,64(sp)
    80003848:	7ae2                	ld	s5,56(sp)
    8000384a:	7b42                	ld	s6,48(sp)
    8000384c:	7ba2                	ld	s7,40(sp)
    8000384e:	7c02                	ld	s8,32(sp)
    80003850:	6ce2                	ld	s9,24(sp)
    80003852:	6d42                	ld	s10,16(sp)
    80003854:	6da2                	ld	s11,8(sp)
    80003856:	6165                	addi	sp,sp,112
    80003858:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000385a:	89d6                	mv	s3,s5
    8000385c:	bff1                	j	80003838 <readi+0xba>
    return 0;
    8000385e:	4501                	li	a0,0
}
    80003860:	8082                	ret

0000000080003862 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003862:	457c                	lw	a5,76(a0)
    80003864:	0ed7ea63          	bltu	a5,a3,80003958 <writei+0xf6>
{
    80003868:	7159                	addi	sp,sp,-112
    8000386a:	f486                	sd	ra,104(sp)
    8000386c:	f0a2                	sd	s0,96(sp)
    8000386e:	eca6                	sd	s1,88(sp)
    80003870:	e8ca                	sd	s2,80(sp)
    80003872:	e4ce                	sd	s3,72(sp)
    80003874:	e0d2                	sd	s4,64(sp)
    80003876:	fc56                	sd	s5,56(sp)
    80003878:	f85a                	sd	s6,48(sp)
    8000387a:	f45e                	sd	s7,40(sp)
    8000387c:	f062                	sd	s8,32(sp)
    8000387e:	ec66                	sd	s9,24(sp)
    80003880:	e86a                	sd	s10,16(sp)
    80003882:	e46e                	sd	s11,8(sp)
    80003884:	1880                	addi	s0,sp,112
    80003886:	8aaa                	mv	s5,a0
    80003888:	8bae                	mv	s7,a1
    8000388a:	8a32                	mv	s4,a2
    8000388c:	8936                	mv	s2,a3
    8000388e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003890:	00e687bb          	addw	a5,a3,a4
    80003894:	0cd7e463          	bltu	a5,a3,8000395c <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003898:	00043737          	lui	a4,0x43
    8000389c:	0cf76263          	bltu	a4,a5,80003960 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800038a0:	0a0b0a63          	beqz	s6,80003954 <writei+0xf2>
    800038a4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800038a6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800038aa:	5c7d                	li	s8,-1
    800038ac:	a825                	j	800038e4 <writei+0x82>
    800038ae:	020d1d93          	slli	s11,s10,0x20
    800038b2:	020ddd93          	srli	s11,s11,0x20
    800038b6:	05848793          	addi	a5,s1,88
    800038ba:	86ee                	mv	a3,s11
    800038bc:	8652                	mv	a2,s4
    800038be:	85de                	mv	a1,s7
    800038c0:	953e                	add	a0,a0,a5
    800038c2:	bd1fe0ef          	jal	ra,80002492 <either_copyin>
    800038c6:	05850a63          	beq	a0,s8,8000391a <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800038ca:	8526                	mv	a0,s1
    800038cc:	688000ef          	jal	ra,80003f54 <log_write>
    brelse(bp);
    800038d0:	8526                	mv	a0,s1
    800038d2:	d76ff0ef          	jal	ra,80002e48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800038d6:	013d09bb          	addw	s3,s10,s3
    800038da:	012d093b          	addw	s2,s10,s2
    800038de:	9a6e                	add	s4,s4,s11
    800038e0:	0569f063          	bgeu	s3,s6,80003920 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    800038e4:	00a9559b          	srliw	a1,s2,0xa
    800038e8:	8556                	mv	a0,s5
    800038ea:	fd0ff0ef          	jal	ra,800030ba <bmap>
    800038ee:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800038f2:	c59d                	beqz	a1,80003920 <writei+0xbe>
    bp = bread(ip->dev, addr);
    800038f4:	000aa503          	lw	a0,0(s5)
    800038f8:	c48ff0ef          	jal	ra,80002d40 <bread>
    800038fc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800038fe:	3ff97513          	andi	a0,s2,1023
    80003902:	40ac87bb          	subw	a5,s9,a0
    80003906:	413b073b          	subw	a4,s6,s3
    8000390a:	8d3e                	mv	s10,a5
    8000390c:	2781                	sext.w	a5,a5
    8000390e:	0007069b          	sext.w	a3,a4
    80003912:	f8f6fee3          	bgeu	a3,a5,800038ae <writei+0x4c>
    80003916:	8d3a                	mv	s10,a4
    80003918:	bf59                	j	800038ae <writei+0x4c>
      brelse(bp);
    8000391a:	8526                	mv	a0,s1
    8000391c:	d2cff0ef          	jal	ra,80002e48 <brelse>
  }

  if(off > ip->size)
    80003920:	04caa783          	lw	a5,76(s5)
    80003924:	0127f463          	bgeu	a5,s2,8000392c <writei+0xca>
    ip->size = off;
    80003928:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000392c:	8556                	mv	a0,s5
    8000392e:	a13ff0ef          	jal	ra,80003340 <iupdate>

  return tot;
    80003932:	0009851b          	sext.w	a0,s3
}
    80003936:	70a6                	ld	ra,104(sp)
    80003938:	7406                	ld	s0,96(sp)
    8000393a:	64e6                	ld	s1,88(sp)
    8000393c:	6946                	ld	s2,80(sp)
    8000393e:	69a6                	ld	s3,72(sp)
    80003940:	6a06                	ld	s4,64(sp)
    80003942:	7ae2                	ld	s5,56(sp)
    80003944:	7b42                	ld	s6,48(sp)
    80003946:	7ba2                	ld	s7,40(sp)
    80003948:	7c02                	ld	s8,32(sp)
    8000394a:	6ce2                	ld	s9,24(sp)
    8000394c:	6d42                	ld	s10,16(sp)
    8000394e:	6da2                	ld	s11,8(sp)
    80003950:	6165                	addi	sp,sp,112
    80003952:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003954:	89da                	mv	s3,s6
    80003956:	bfd9                	j	8000392c <writei+0xca>
    return -1;
    80003958:	557d                	li	a0,-1
}
    8000395a:	8082                	ret
    return -1;
    8000395c:	557d                	li	a0,-1
    8000395e:	bfe1                	j	80003936 <writei+0xd4>
    return -1;
    80003960:	557d                	li	a0,-1
    80003962:	bfd1                	j	80003936 <writei+0xd4>

0000000080003964 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003964:	1141                	addi	sp,sp,-16
    80003966:	e406                	sd	ra,8(sp)
    80003968:	e022                	sd	s0,0(sp)
    8000396a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000396c:	4639                	li	a2,14
    8000396e:	c9afd0ef          	jal	ra,80000e08 <strncmp>
}
    80003972:	60a2                	ld	ra,8(sp)
    80003974:	6402                	ld	s0,0(sp)
    80003976:	0141                	addi	sp,sp,16
    80003978:	8082                	ret

000000008000397a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000397a:	7139                	addi	sp,sp,-64
    8000397c:	fc06                	sd	ra,56(sp)
    8000397e:	f822                	sd	s0,48(sp)
    80003980:	f426                	sd	s1,40(sp)
    80003982:	f04a                	sd	s2,32(sp)
    80003984:	ec4e                	sd	s3,24(sp)
    80003986:	e852                	sd	s4,16(sp)
    80003988:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000398a:	04451703          	lh	a4,68(a0)
    8000398e:	4785                	li	a5,1
    80003990:	00f71a63          	bne	a4,a5,800039a4 <dirlookup+0x2a>
    80003994:	892a                	mv	s2,a0
    80003996:	89ae                	mv	s3,a1
    80003998:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000399a:	457c                	lw	a5,76(a0)
    8000399c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000399e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039a0:	e39d                	bnez	a5,800039c6 <dirlookup+0x4c>
    800039a2:	a095                	j	80003a06 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800039a4:	00004517          	auipc	a0,0x4
    800039a8:	c6c50513          	addi	a0,a0,-916 # 80007610 <syscalls+0x1c0>
    800039ac:	dbffc0ef          	jal	ra,8000076a <panic>
      panic("dirlookup read");
    800039b0:	00004517          	auipc	a0,0x4
    800039b4:	c7850513          	addi	a0,a0,-904 # 80007628 <syscalls+0x1d8>
    800039b8:	db3fc0ef          	jal	ra,8000076a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039bc:	24c1                	addiw	s1,s1,16
    800039be:	04c92783          	lw	a5,76(s2)
    800039c2:	04f4f163          	bgeu	s1,a5,80003a04 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039c6:	4741                	li	a4,16
    800039c8:	86a6                	mv	a3,s1
    800039ca:	fc040613          	addi	a2,s0,-64
    800039ce:	4581                	li	a1,0
    800039d0:	854a                	mv	a0,s2
    800039d2:	dadff0ef          	jal	ra,8000377e <readi>
    800039d6:	47c1                	li	a5,16
    800039d8:	fcf51ce3          	bne	a0,a5,800039b0 <dirlookup+0x36>
    if(de.inum == 0)
    800039dc:	fc045783          	lhu	a5,-64(s0)
    800039e0:	dff1                	beqz	a5,800039bc <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    800039e2:	fc240593          	addi	a1,s0,-62
    800039e6:	854e                	mv	a0,s3
    800039e8:	f7dff0ef          	jal	ra,80003964 <namecmp>
    800039ec:	f961                	bnez	a0,800039bc <dirlookup+0x42>
      if(poff)
    800039ee:	000a0463          	beqz	s4,800039f6 <dirlookup+0x7c>
        *poff = off;
    800039f2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800039f6:	fc045583          	lhu	a1,-64(s0)
    800039fa:	00092503          	lw	a0,0(s2)
    800039fe:	f88ff0ef          	jal	ra,80003186 <iget>
    80003a02:	a011                	j	80003a06 <dirlookup+0x8c>
  return 0;
    80003a04:	4501                	li	a0,0
}
    80003a06:	70e2                	ld	ra,56(sp)
    80003a08:	7442                	ld	s0,48(sp)
    80003a0a:	74a2                	ld	s1,40(sp)
    80003a0c:	7902                	ld	s2,32(sp)
    80003a0e:	69e2                	ld	s3,24(sp)
    80003a10:	6a42                	ld	s4,16(sp)
    80003a12:	6121                	addi	sp,sp,64
    80003a14:	8082                	ret

0000000080003a16 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003a16:	711d                	addi	sp,sp,-96
    80003a18:	ec86                	sd	ra,88(sp)
    80003a1a:	e8a2                	sd	s0,80(sp)
    80003a1c:	e4a6                	sd	s1,72(sp)
    80003a1e:	e0ca                	sd	s2,64(sp)
    80003a20:	fc4e                	sd	s3,56(sp)
    80003a22:	f852                	sd	s4,48(sp)
    80003a24:	f456                	sd	s5,40(sp)
    80003a26:	f05a                	sd	s6,32(sp)
    80003a28:	ec5e                	sd	s7,24(sp)
    80003a2a:	e862                	sd	s8,16(sp)
    80003a2c:	e466                	sd	s9,8(sp)
    80003a2e:	1080                	addi	s0,sp,96
    80003a30:	84aa                	mv	s1,a0
    80003a32:	8aae                	mv	s5,a1
    80003a34:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003a36:	00054703          	lbu	a4,0(a0)
    80003a3a:	02f00793          	li	a5,47
    80003a3e:	00f70f63          	beq	a4,a5,80003a5c <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003a42:	f1dfd0ef          	jal	ra,8000195e <myproc>
    80003a46:	15053503          	ld	a0,336(a0)
    80003a4a:	973ff0ef          	jal	ra,800033bc <idup>
    80003a4e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003a50:	02f00913          	li	s2,47
  len = path - s;
    80003a54:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003a56:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003a58:	4b85                	li	s7,1
    80003a5a:	a861                	j	80003af2 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003a5c:	4585                	li	a1,1
    80003a5e:	4505                	li	a0,1
    80003a60:	f26ff0ef          	jal	ra,80003186 <iget>
    80003a64:	89aa                	mv	s3,a0
    80003a66:	b7ed                	j	80003a50 <namex+0x3a>
      iunlockput(ip);
    80003a68:	854e                	mv	a0,s3
    80003a6a:	b8fff0ef          	jal	ra,800035f8 <iunlockput>
      return 0;
    80003a6e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003a70:	854e                	mv	a0,s3
    80003a72:	60e6                	ld	ra,88(sp)
    80003a74:	6446                	ld	s0,80(sp)
    80003a76:	64a6                	ld	s1,72(sp)
    80003a78:	6906                	ld	s2,64(sp)
    80003a7a:	79e2                	ld	s3,56(sp)
    80003a7c:	7a42                	ld	s4,48(sp)
    80003a7e:	7aa2                	ld	s5,40(sp)
    80003a80:	7b02                	ld	s6,32(sp)
    80003a82:	6be2                	ld	s7,24(sp)
    80003a84:	6c42                	ld	s8,16(sp)
    80003a86:	6ca2                	ld	s9,8(sp)
    80003a88:	6125                	addi	sp,sp,96
    80003a8a:	8082                	ret
      iunlock(ip);
    80003a8c:	854e                	mv	a0,s3
    80003a8e:	a0fff0ef          	jal	ra,8000349c <iunlock>
      return ip;
    80003a92:	bff9                	j	80003a70 <namex+0x5a>
      iunlockput(ip);
    80003a94:	854e                	mv	a0,s3
    80003a96:	b63ff0ef          	jal	ra,800035f8 <iunlockput>
      return 0;
    80003a9a:	89e6                	mv	s3,s9
    80003a9c:	bfd1                	j	80003a70 <namex+0x5a>
  len = path - s;
    80003a9e:	40b48633          	sub	a2,s1,a1
    80003aa2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003aa6:	079c5c63          	bge	s8,s9,80003b1e <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003aaa:	4639                	li	a2,14
    80003aac:	8552                	mv	a0,s4
    80003aae:	aeafd0ef          	jal	ra,80000d98 <memmove>
  while(*path == '/')
    80003ab2:	0004c783          	lbu	a5,0(s1)
    80003ab6:	01279763          	bne	a5,s2,80003ac4 <namex+0xae>
    path++;
    80003aba:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003abc:	0004c783          	lbu	a5,0(s1)
    80003ac0:	ff278de3          	beq	a5,s2,80003aba <namex+0xa4>
    ilock(ip);
    80003ac4:	854e                	mv	a0,s3
    80003ac6:	92dff0ef          	jal	ra,800033f2 <ilock>
    if(ip->type != T_DIR){
    80003aca:	04499783          	lh	a5,68(s3)
    80003ace:	f9779de3          	bne	a5,s7,80003a68 <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003ad2:	000a8563          	beqz	s5,80003adc <namex+0xc6>
    80003ad6:	0004c783          	lbu	a5,0(s1)
    80003ada:	dbcd                	beqz	a5,80003a8c <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003adc:	865a                	mv	a2,s6
    80003ade:	85d2                	mv	a1,s4
    80003ae0:	854e                	mv	a0,s3
    80003ae2:	e99ff0ef          	jal	ra,8000397a <dirlookup>
    80003ae6:	8caa                	mv	s9,a0
    80003ae8:	d555                	beqz	a0,80003a94 <namex+0x7e>
    iunlockput(ip);
    80003aea:	854e                	mv	a0,s3
    80003aec:	b0dff0ef          	jal	ra,800035f8 <iunlockput>
    ip = next;
    80003af0:	89e6                	mv	s3,s9
  while(*path == '/')
    80003af2:	0004c783          	lbu	a5,0(s1)
    80003af6:	05279363          	bne	a5,s2,80003b3c <namex+0x126>
    path++;
    80003afa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003afc:	0004c783          	lbu	a5,0(s1)
    80003b00:	ff278de3          	beq	a5,s2,80003afa <namex+0xe4>
  if(*path == 0)
    80003b04:	c78d                	beqz	a5,80003b2e <namex+0x118>
    path++;
    80003b06:	85a6                	mv	a1,s1
  len = path - s;
    80003b08:	8cda                	mv	s9,s6
    80003b0a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003b0c:	01278963          	beq	a5,s2,80003b1e <namex+0x108>
    80003b10:	d7d9                	beqz	a5,80003a9e <namex+0x88>
    path++;
    80003b12:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003b14:	0004c783          	lbu	a5,0(s1)
    80003b18:	ff279ce3          	bne	a5,s2,80003b10 <namex+0xfa>
    80003b1c:	b749                	j	80003a9e <namex+0x88>
    memmove(name, s, len);
    80003b1e:	2601                	sext.w	a2,a2
    80003b20:	8552                	mv	a0,s4
    80003b22:	a76fd0ef          	jal	ra,80000d98 <memmove>
    name[len] = 0;
    80003b26:	9cd2                	add	s9,s9,s4
    80003b28:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003b2c:	b759                	j	80003ab2 <namex+0x9c>
  if(nameiparent){
    80003b2e:	f40a81e3          	beqz	s5,80003a70 <namex+0x5a>
    iput(ip);
    80003b32:	854e                	mv	a0,s3
    80003b34:	a3dff0ef          	jal	ra,80003570 <iput>
    return 0;
    80003b38:	4981                	li	s3,0
    80003b3a:	bf1d                	j	80003a70 <namex+0x5a>
  if(*path == 0)
    80003b3c:	dbed                	beqz	a5,80003b2e <namex+0x118>
  while(*path != '/' && *path != 0)
    80003b3e:	0004c783          	lbu	a5,0(s1)
    80003b42:	85a6                	mv	a1,s1
    80003b44:	b7f1                	j	80003b10 <namex+0xfa>

0000000080003b46 <dirlink>:
{
    80003b46:	7139                	addi	sp,sp,-64
    80003b48:	fc06                	sd	ra,56(sp)
    80003b4a:	f822                	sd	s0,48(sp)
    80003b4c:	f426                	sd	s1,40(sp)
    80003b4e:	f04a                	sd	s2,32(sp)
    80003b50:	ec4e                	sd	s3,24(sp)
    80003b52:	e852                	sd	s4,16(sp)
    80003b54:	0080                	addi	s0,sp,64
    80003b56:	892a                	mv	s2,a0
    80003b58:	8a2e                	mv	s4,a1
    80003b5a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003b5c:	4601                	li	a2,0
    80003b5e:	e1dff0ef          	jal	ra,8000397a <dirlookup>
    80003b62:	e52d                	bnez	a0,80003bcc <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b64:	04c92483          	lw	s1,76(s2)
    80003b68:	c48d                	beqz	s1,80003b92 <dirlink+0x4c>
    80003b6a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b6c:	4741                	li	a4,16
    80003b6e:	86a6                	mv	a3,s1
    80003b70:	fc040613          	addi	a2,s0,-64
    80003b74:	4581                	li	a1,0
    80003b76:	854a                	mv	a0,s2
    80003b78:	c07ff0ef          	jal	ra,8000377e <readi>
    80003b7c:	47c1                	li	a5,16
    80003b7e:	04f51b63          	bne	a0,a5,80003bd4 <dirlink+0x8e>
    if(de.inum == 0)
    80003b82:	fc045783          	lhu	a5,-64(s0)
    80003b86:	c791                	beqz	a5,80003b92 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b88:	24c1                	addiw	s1,s1,16
    80003b8a:	04c92783          	lw	a5,76(s2)
    80003b8e:	fcf4efe3          	bltu	s1,a5,80003b6c <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003b92:	4639                	li	a2,14
    80003b94:	85d2                	mv	a1,s4
    80003b96:	fc240513          	addi	a0,s0,-62
    80003b9a:	aaafd0ef          	jal	ra,80000e44 <strncpy>
  de.inum = inum;
    80003b9e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ba2:	4741                	li	a4,16
    80003ba4:	86a6                	mv	a3,s1
    80003ba6:	fc040613          	addi	a2,s0,-64
    80003baa:	4581                	li	a1,0
    80003bac:	854a                	mv	a0,s2
    80003bae:	cb5ff0ef          	jal	ra,80003862 <writei>
    80003bb2:	1541                	addi	a0,a0,-16
    80003bb4:	00a03533          	snez	a0,a0
    80003bb8:	40a00533          	neg	a0,a0
}
    80003bbc:	70e2                	ld	ra,56(sp)
    80003bbe:	7442                	ld	s0,48(sp)
    80003bc0:	74a2                	ld	s1,40(sp)
    80003bc2:	7902                	ld	s2,32(sp)
    80003bc4:	69e2                	ld	s3,24(sp)
    80003bc6:	6a42                	ld	s4,16(sp)
    80003bc8:	6121                	addi	sp,sp,64
    80003bca:	8082                	ret
    iput(ip);
    80003bcc:	9a5ff0ef          	jal	ra,80003570 <iput>
    return -1;
    80003bd0:	557d                	li	a0,-1
    80003bd2:	b7ed                	j	80003bbc <dirlink+0x76>
      panic("dirlink read");
    80003bd4:	00004517          	auipc	a0,0x4
    80003bd8:	a6450513          	addi	a0,a0,-1436 # 80007638 <syscalls+0x1e8>
    80003bdc:	b8ffc0ef          	jal	ra,8000076a <panic>

0000000080003be0 <namei>:

struct inode*
namei(char *path)
{
    80003be0:	1101                	addi	sp,sp,-32
    80003be2:	ec06                	sd	ra,24(sp)
    80003be4:	e822                	sd	s0,16(sp)
    80003be6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003be8:	fe040613          	addi	a2,s0,-32
    80003bec:	4581                	li	a1,0
    80003bee:	e29ff0ef          	jal	ra,80003a16 <namex>
}
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	6105                	addi	sp,sp,32
    80003bf8:	8082                	ret

0000000080003bfa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003bfa:	1141                	addi	sp,sp,-16
    80003bfc:	e406                	sd	ra,8(sp)
    80003bfe:	e022                	sd	s0,0(sp)
    80003c00:	0800                	addi	s0,sp,16
    80003c02:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003c04:	4585                	li	a1,1
    80003c06:	e11ff0ef          	jal	ra,80003a16 <namex>
}
    80003c0a:	60a2                	ld	ra,8(sp)
    80003c0c:	6402                	ld	s0,0(sp)
    80003c0e:	0141                	addi	sp,sp,16
    80003c10:	8082                	ret

0000000080003c12 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003c12:	1101                	addi	sp,sp,-32
    80003c14:	ec06                	sd	ra,24(sp)
    80003c16:	e822                	sd	s0,16(sp)
    80003c18:	e426                	sd	s1,8(sp)
    80003c1a:	e04a                	sd	s2,0(sp)
    80003c1c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003c1e:	0023c917          	auipc	s2,0x23c
    80003c22:	17a90913          	addi	s2,s2,378 # 8023fd98 <log>
    80003c26:	01892583          	lw	a1,24(s2)
    80003c2a:	02492503          	lw	a0,36(s2)
    80003c2e:	912ff0ef          	jal	ra,80002d40 <bread>
    80003c32:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003c34:	02892683          	lw	a3,40(s2)
    80003c38:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003c3a:	02d05763          	blez	a3,80003c68 <write_head+0x56>
    80003c3e:	0023c797          	auipc	a5,0x23c
    80003c42:	18678793          	addi	a5,a5,390 # 8023fdc4 <log+0x2c>
    80003c46:	05c50713          	addi	a4,a0,92
    80003c4a:	36fd                	addiw	a3,a3,-1
    80003c4c:	1682                	slli	a3,a3,0x20
    80003c4e:	9281                	srli	a3,a3,0x20
    80003c50:	068a                	slli	a3,a3,0x2
    80003c52:	0023c617          	auipc	a2,0x23c
    80003c56:	17660613          	addi	a2,a2,374 # 8023fdc8 <log+0x30>
    80003c5a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003c5c:	4390                	lw	a2,0(a5)
    80003c5e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c60:	0791                	addi	a5,a5,4
    80003c62:	0711                	addi	a4,a4,4
    80003c64:	fed79ce3          	bne	a5,a3,80003c5c <write_head+0x4a>
  }
  bwrite(buf);
    80003c68:	8526                	mv	a0,s1
    80003c6a:	9acff0ef          	jal	ra,80002e16 <bwrite>
  brelse(buf);
    80003c6e:	8526                	mv	a0,s1
    80003c70:	9d8ff0ef          	jal	ra,80002e48 <brelse>
}
    80003c74:	60e2                	ld	ra,24(sp)
    80003c76:	6442                	ld	s0,16(sp)
    80003c78:	64a2                	ld	s1,8(sp)
    80003c7a:	6902                	ld	s2,0(sp)
    80003c7c:	6105                	addi	sp,sp,32
    80003c7e:	8082                	ret

0000000080003c80 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c80:	0023c797          	auipc	a5,0x23c
    80003c84:	1407a783          	lw	a5,320(a5) # 8023fdc0 <log+0x28>
    80003c88:	0af05e63          	blez	a5,80003d44 <install_trans+0xc4>
{
    80003c8c:	715d                	addi	sp,sp,-80
    80003c8e:	e486                	sd	ra,72(sp)
    80003c90:	e0a2                	sd	s0,64(sp)
    80003c92:	fc26                	sd	s1,56(sp)
    80003c94:	f84a                	sd	s2,48(sp)
    80003c96:	f44e                	sd	s3,40(sp)
    80003c98:	f052                	sd	s4,32(sp)
    80003c9a:	ec56                	sd	s5,24(sp)
    80003c9c:	e85a                	sd	s6,16(sp)
    80003c9e:	e45e                	sd	s7,8(sp)
    80003ca0:	0880                	addi	s0,sp,80
    80003ca2:	8b2a                	mv	s6,a0
    80003ca4:	0023ca97          	auipc	s5,0x23c
    80003ca8:	120a8a93          	addi	s5,s5,288 # 8023fdc4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003cac:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003cae:	00004b97          	auipc	s7,0x4
    80003cb2:	99ab8b93          	addi	s7,s7,-1638 # 80007648 <syscalls+0x1f8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003cb6:	0023ca17          	auipc	s4,0x23c
    80003cba:	0e2a0a13          	addi	s4,s4,226 # 8023fd98 <log>
    80003cbe:	a025                	j	80003ce6 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003cc0:	000aa603          	lw	a2,0(s5)
    80003cc4:	85ce                	mv	a1,s3
    80003cc6:	855e                	mv	a0,s7
    80003cc8:	fdcfc0ef          	jal	ra,800004a4 <printf>
    80003ccc:	a839                	j	80003cea <install_trans+0x6a>
    brelse(lbuf);
    80003cce:	854a                	mv	a0,s2
    80003cd0:	978ff0ef          	jal	ra,80002e48 <brelse>
    brelse(dbuf);
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	972ff0ef          	jal	ra,80002e48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003cda:	2985                	addiw	s3,s3,1
    80003cdc:	0a91                	addi	s5,s5,4
    80003cde:	028a2783          	lw	a5,40(s4)
    80003ce2:	04f9d663          	bge	s3,a5,80003d2e <install_trans+0xae>
    if(recovering) {
    80003ce6:	fc0b1de3          	bnez	s6,80003cc0 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003cea:	018a2583          	lw	a1,24(s4)
    80003cee:	013585bb          	addw	a1,a1,s3
    80003cf2:	2585                	addiw	a1,a1,1
    80003cf4:	024a2503          	lw	a0,36(s4)
    80003cf8:	848ff0ef          	jal	ra,80002d40 <bread>
    80003cfc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003cfe:	000aa583          	lw	a1,0(s5)
    80003d02:	024a2503          	lw	a0,36(s4)
    80003d06:	83aff0ef          	jal	ra,80002d40 <bread>
    80003d0a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003d0c:	40000613          	li	a2,1024
    80003d10:	05890593          	addi	a1,s2,88
    80003d14:	05850513          	addi	a0,a0,88
    80003d18:	880fd0ef          	jal	ra,80000d98 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003d1c:	8526                	mv	a0,s1
    80003d1e:	8f8ff0ef          	jal	ra,80002e16 <bwrite>
    if(recovering == 0)
    80003d22:	fa0b16e3          	bnez	s6,80003cce <install_trans+0x4e>
      bunpin(dbuf);
    80003d26:	8526                	mv	a0,s1
    80003d28:	9deff0ef          	jal	ra,80002f06 <bunpin>
    80003d2c:	b74d                	j	80003cce <install_trans+0x4e>
}
    80003d2e:	60a6                	ld	ra,72(sp)
    80003d30:	6406                	ld	s0,64(sp)
    80003d32:	74e2                	ld	s1,56(sp)
    80003d34:	7942                	ld	s2,48(sp)
    80003d36:	79a2                	ld	s3,40(sp)
    80003d38:	7a02                	ld	s4,32(sp)
    80003d3a:	6ae2                	ld	s5,24(sp)
    80003d3c:	6b42                	ld	s6,16(sp)
    80003d3e:	6ba2                	ld	s7,8(sp)
    80003d40:	6161                	addi	sp,sp,80
    80003d42:	8082                	ret
    80003d44:	8082                	ret

0000000080003d46 <initlog>:
{
    80003d46:	7179                	addi	sp,sp,-48
    80003d48:	f406                	sd	ra,40(sp)
    80003d4a:	f022                	sd	s0,32(sp)
    80003d4c:	ec26                	sd	s1,24(sp)
    80003d4e:	e84a                	sd	s2,16(sp)
    80003d50:	e44e                	sd	s3,8(sp)
    80003d52:	1800                	addi	s0,sp,48
    80003d54:	892a                	mv	s2,a0
    80003d56:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003d58:	0023c497          	auipc	s1,0x23c
    80003d5c:	04048493          	addi	s1,s1,64 # 8023fd98 <log>
    80003d60:	00004597          	auipc	a1,0x4
    80003d64:	90858593          	addi	a1,a1,-1784 # 80007668 <syscalls+0x218>
    80003d68:	8526                	mv	a0,s1
    80003d6a:	e7ffc0ef          	jal	ra,80000be8 <initlock>
  log.start = sb->logstart;
    80003d6e:	0149a583          	lw	a1,20(s3)
    80003d72:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003d74:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003d78:	854a                	mv	a0,s2
    80003d7a:	fc7fe0ef          	jal	ra,80002d40 <bread>
  log.lh.n = lh->n;
    80003d7e:	4d34                	lw	a3,88(a0)
    80003d80:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003d82:	02d05563          	blez	a3,80003dac <initlog+0x66>
    80003d86:	05c50793          	addi	a5,a0,92
    80003d8a:	0023c717          	auipc	a4,0x23c
    80003d8e:	03a70713          	addi	a4,a4,58 # 8023fdc4 <log+0x2c>
    80003d92:	36fd                	addiw	a3,a3,-1
    80003d94:	1682                	slli	a3,a3,0x20
    80003d96:	9281                	srli	a3,a3,0x20
    80003d98:	068a                	slli	a3,a3,0x2
    80003d9a:	06050613          	addi	a2,a0,96
    80003d9e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003da0:	4390                	lw	a2,0(a5)
    80003da2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003da4:	0791                	addi	a5,a5,4
    80003da6:	0711                	addi	a4,a4,4
    80003da8:	fed79ce3          	bne	a5,a3,80003da0 <initlog+0x5a>
  brelse(buf);
    80003dac:	89cff0ef          	jal	ra,80002e48 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003db0:	4505                	li	a0,1
    80003db2:	ecfff0ef          	jal	ra,80003c80 <install_trans>
  log.lh.n = 0;
    80003db6:	0023c797          	auipc	a5,0x23c
    80003dba:	0007a523          	sw	zero,10(a5) # 8023fdc0 <log+0x28>
  write_head(); // clear the log
    80003dbe:	e55ff0ef          	jal	ra,80003c12 <write_head>
}
    80003dc2:	70a2                	ld	ra,40(sp)
    80003dc4:	7402                	ld	s0,32(sp)
    80003dc6:	64e2                	ld	s1,24(sp)
    80003dc8:	6942                	ld	s2,16(sp)
    80003dca:	69a2                	ld	s3,8(sp)
    80003dcc:	6145                	addi	sp,sp,48
    80003dce:	8082                	ret

0000000080003dd0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003dd0:	1101                	addi	sp,sp,-32
    80003dd2:	ec06                	sd	ra,24(sp)
    80003dd4:	e822                	sd	s0,16(sp)
    80003dd6:	e426                	sd	s1,8(sp)
    80003dd8:	e04a                	sd	s2,0(sp)
    80003dda:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003ddc:	0023c517          	auipc	a0,0x23c
    80003de0:	fbc50513          	addi	a0,a0,-68 # 8023fd98 <log>
    80003de4:	e85fc0ef          	jal	ra,80000c68 <acquire>
  while(1){
    if(log.committing){
    80003de8:	0023c497          	auipc	s1,0x23c
    80003dec:	fb048493          	addi	s1,s1,-80 # 8023fd98 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003df0:	4979                	li	s2,30
    80003df2:	a029                	j	80003dfc <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003df4:	85a6                	mv	a1,s1
    80003df6:	8526                	mv	a0,s1
    80003df8:	8dcfe0ef          	jal	ra,80001ed4 <sleep>
    if(log.committing){
    80003dfc:	509c                	lw	a5,32(s1)
    80003dfe:	fbfd                	bnez	a5,80003df4 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003e00:	4cdc                	lw	a5,28(s1)
    80003e02:	0017871b          	addiw	a4,a5,1
    80003e06:	0007069b          	sext.w	a3,a4
    80003e0a:	0027179b          	slliw	a5,a4,0x2
    80003e0e:	9fb9                	addw	a5,a5,a4
    80003e10:	0017979b          	slliw	a5,a5,0x1
    80003e14:	5498                	lw	a4,40(s1)
    80003e16:	9fb9                	addw	a5,a5,a4
    80003e18:	00f95763          	bge	s2,a5,80003e26 <begin_op+0x56>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003e1c:	85a6                	mv	a1,s1
    80003e1e:	8526                	mv	a0,s1
    80003e20:	8b4fe0ef          	jal	ra,80001ed4 <sleep>
    80003e24:	bfe1                	j	80003dfc <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003e26:	0023c517          	auipc	a0,0x23c
    80003e2a:	f7250513          	addi	a0,a0,-142 # 8023fd98 <log>
    80003e2e:	cd54                	sw	a3,28(a0)
      release(&log.lock);
    80003e30:	ed1fc0ef          	jal	ra,80000d00 <release>
      break;
    }
  }
}
    80003e34:	60e2                	ld	ra,24(sp)
    80003e36:	6442                	ld	s0,16(sp)
    80003e38:	64a2                	ld	s1,8(sp)
    80003e3a:	6902                	ld	s2,0(sp)
    80003e3c:	6105                	addi	sp,sp,32
    80003e3e:	8082                	ret

0000000080003e40 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003e40:	7139                	addi	sp,sp,-64
    80003e42:	fc06                	sd	ra,56(sp)
    80003e44:	f822                	sd	s0,48(sp)
    80003e46:	f426                	sd	s1,40(sp)
    80003e48:	f04a                	sd	s2,32(sp)
    80003e4a:	ec4e                	sd	s3,24(sp)
    80003e4c:	e852                	sd	s4,16(sp)
    80003e4e:	e456                	sd	s5,8(sp)
    80003e50:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003e52:	0023c497          	auipc	s1,0x23c
    80003e56:	f4648493          	addi	s1,s1,-186 # 8023fd98 <log>
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	e0dfc0ef          	jal	ra,80000c68 <acquire>
  log.outstanding -= 1;
    80003e60:	4cdc                	lw	a5,28(s1)
    80003e62:	37fd                	addiw	a5,a5,-1
    80003e64:	0007891b          	sext.w	s2,a5
    80003e68:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003e6a:	509c                	lw	a5,32(s1)
    80003e6c:	ef9d                	bnez	a5,80003eaa <end_op+0x6a>
    panic("log.committing");
  if(log.outstanding == 0){
    80003e6e:	04091463          	bnez	s2,80003eb6 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003e72:	0023c497          	auipc	s1,0x23c
    80003e76:	f2648493          	addi	s1,s1,-218 # 8023fd98 <log>
    80003e7a:	4785                	li	a5,1
    80003e7c:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003e7e:	8526                	mv	a0,s1
    80003e80:	e81fc0ef          	jal	ra,80000d00 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003e84:	549c                	lw	a5,40(s1)
    80003e86:	04f04b63          	bgtz	a5,80003edc <end_op+0x9c>
    acquire(&log.lock);
    80003e8a:	0023c497          	auipc	s1,0x23c
    80003e8e:	f0e48493          	addi	s1,s1,-242 # 8023fd98 <log>
    80003e92:	8526                	mv	a0,s1
    80003e94:	dd5fc0ef          	jal	ra,80000c68 <acquire>
    log.committing = 0;
    80003e98:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	882fe0ef          	jal	ra,80001f20 <wakeup>
    release(&log.lock);
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	e5dfc0ef          	jal	ra,80000d00 <release>
}
    80003ea8:	a00d                	j	80003eca <end_op+0x8a>
    panic("log.committing");
    80003eaa:	00003517          	auipc	a0,0x3
    80003eae:	7c650513          	addi	a0,a0,1990 # 80007670 <syscalls+0x220>
    80003eb2:	8b9fc0ef          	jal	ra,8000076a <panic>
    wakeup(&log);
    80003eb6:	0023c497          	auipc	s1,0x23c
    80003eba:	ee248493          	addi	s1,s1,-286 # 8023fd98 <log>
    80003ebe:	8526                	mv	a0,s1
    80003ec0:	860fe0ef          	jal	ra,80001f20 <wakeup>
  release(&log.lock);
    80003ec4:	8526                	mv	a0,s1
    80003ec6:	e3bfc0ef          	jal	ra,80000d00 <release>
}
    80003eca:	70e2                	ld	ra,56(sp)
    80003ecc:	7442                	ld	s0,48(sp)
    80003ece:	74a2                	ld	s1,40(sp)
    80003ed0:	7902                	ld	s2,32(sp)
    80003ed2:	69e2                	ld	s3,24(sp)
    80003ed4:	6a42                	ld	s4,16(sp)
    80003ed6:	6aa2                	ld	s5,8(sp)
    80003ed8:	6121                	addi	sp,sp,64
    80003eda:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003edc:	0023ca97          	auipc	s5,0x23c
    80003ee0:	ee8a8a93          	addi	s5,s5,-280 # 8023fdc4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003ee4:	0023ca17          	auipc	s4,0x23c
    80003ee8:	eb4a0a13          	addi	s4,s4,-332 # 8023fd98 <log>
    80003eec:	018a2583          	lw	a1,24(s4)
    80003ef0:	012585bb          	addw	a1,a1,s2
    80003ef4:	2585                	addiw	a1,a1,1
    80003ef6:	024a2503          	lw	a0,36(s4)
    80003efa:	e47fe0ef          	jal	ra,80002d40 <bread>
    80003efe:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003f00:	000aa583          	lw	a1,0(s5)
    80003f04:	024a2503          	lw	a0,36(s4)
    80003f08:	e39fe0ef          	jal	ra,80002d40 <bread>
    80003f0c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003f0e:	40000613          	li	a2,1024
    80003f12:	05850593          	addi	a1,a0,88
    80003f16:	05848513          	addi	a0,s1,88
    80003f1a:	e7ffc0ef          	jal	ra,80000d98 <memmove>
    bwrite(to);  // write the log
    80003f1e:	8526                	mv	a0,s1
    80003f20:	ef7fe0ef          	jal	ra,80002e16 <bwrite>
    brelse(from);
    80003f24:	854e                	mv	a0,s3
    80003f26:	f23fe0ef          	jal	ra,80002e48 <brelse>
    brelse(to);
    80003f2a:	8526                	mv	a0,s1
    80003f2c:	f1dfe0ef          	jal	ra,80002e48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f30:	2905                	addiw	s2,s2,1
    80003f32:	0a91                	addi	s5,s5,4
    80003f34:	028a2783          	lw	a5,40(s4)
    80003f38:	faf94ae3          	blt	s2,a5,80003eec <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003f3c:	cd7ff0ef          	jal	ra,80003c12 <write_head>
    install_trans(0); // Now install writes to home locations
    80003f40:	4501                	li	a0,0
    80003f42:	d3fff0ef          	jal	ra,80003c80 <install_trans>
    log.lh.n = 0;
    80003f46:	0023c797          	auipc	a5,0x23c
    80003f4a:	e607ad23          	sw	zero,-390(a5) # 8023fdc0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003f4e:	cc5ff0ef          	jal	ra,80003c12 <write_head>
    80003f52:	bf25                	j	80003e8a <end_op+0x4a>

0000000080003f54 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003f54:	1101                	addi	sp,sp,-32
    80003f56:	ec06                	sd	ra,24(sp)
    80003f58:	e822                	sd	s0,16(sp)
    80003f5a:	e426                	sd	s1,8(sp)
    80003f5c:	e04a                	sd	s2,0(sp)
    80003f5e:	1000                	addi	s0,sp,32
    80003f60:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003f62:	0023c917          	auipc	s2,0x23c
    80003f66:	e3690913          	addi	s2,s2,-458 # 8023fd98 <log>
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	cfdfc0ef          	jal	ra,80000c68 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003f70:	02892603          	lw	a2,40(s2)
    80003f74:	47f5                	li	a5,29
    80003f76:	04c7cc63          	blt	a5,a2,80003fce <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003f7a:	0023c797          	auipc	a5,0x23c
    80003f7e:	e3a7a783          	lw	a5,-454(a5) # 8023fdb4 <log+0x1c>
    80003f82:	04f05c63          	blez	a5,80003fda <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003f86:	4781                	li	a5,0
    80003f88:	04c05f63          	blez	a2,80003fe6 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003f8c:	44cc                	lw	a1,12(s1)
    80003f8e:	0023c717          	auipc	a4,0x23c
    80003f92:	e3670713          	addi	a4,a4,-458 # 8023fdc4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003f96:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003f98:	4314                	lw	a3,0(a4)
    80003f9a:	04b68663          	beq	a3,a1,80003fe6 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003f9e:	2785                	addiw	a5,a5,1
    80003fa0:	0711                	addi	a4,a4,4
    80003fa2:	fef61be3          	bne	a2,a5,80003f98 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003fa6:	0621                	addi	a2,a2,8
    80003fa8:	060a                	slli	a2,a2,0x2
    80003faa:	0023c797          	auipc	a5,0x23c
    80003fae:	dee78793          	addi	a5,a5,-530 # 8023fd98 <log>
    80003fb2:	963e                	add	a2,a2,a5
    80003fb4:	44dc                	lw	a5,12(s1)
    80003fb6:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	f19fe0ef          	jal	ra,80002ed2 <bpin>
    log.lh.n++;
    80003fbe:	0023c717          	auipc	a4,0x23c
    80003fc2:	dda70713          	addi	a4,a4,-550 # 8023fd98 <log>
    80003fc6:	571c                	lw	a5,40(a4)
    80003fc8:	2785                	addiw	a5,a5,1
    80003fca:	d71c                	sw	a5,40(a4)
    80003fcc:	a815                	j	80004000 <log_write+0xac>
    panic("too big a transaction");
    80003fce:	00003517          	auipc	a0,0x3
    80003fd2:	6b250513          	addi	a0,a0,1714 # 80007680 <syscalls+0x230>
    80003fd6:	f94fc0ef          	jal	ra,8000076a <panic>
    panic("log_write outside of trans");
    80003fda:	00003517          	auipc	a0,0x3
    80003fde:	6be50513          	addi	a0,a0,1726 # 80007698 <syscalls+0x248>
    80003fe2:	f88fc0ef          	jal	ra,8000076a <panic>
  log.lh.block[i] = b->blockno;
    80003fe6:	00878713          	addi	a4,a5,8
    80003fea:	00271693          	slli	a3,a4,0x2
    80003fee:	0023c717          	auipc	a4,0x23c
    80003ff2:	daa70713          	addi	a4,a4,-598 # 8023fd98 <log>
    80003ff6:	9736                	add	a4,a4,a3
    80003ff8:	44d4                	lw	a3,12(s1)
    80003ffa:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003ffc:	faf60ee3          	beq	a2,a5,80003fb8 <log_write+0x64>
  }
  release(&log.lock);
    80004000:	0023c517          	auipc	a0,0x23c
    80004004:	d9850513          	addi	a0,a0,-616 # 8023fd98 <log>
    80004008:	cf9fc0ef          	jal	ra,80000d00 <release>
}
    8000400c:	60e2                	ld	ra,24(sp)
    8000400e:	6442                	ld	s0,16(sp)
    80004010:	64a2                	ld	s1,8(sp)
    80004012:	6902                	ld	s2,0(sp)
    80004014:	6105                	addi	sp,sp,32
    80004016:	8082                	ret

0000000080004018 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	e04a                	sd	s2,0(sp)
    80004022:	1000                	addi	s0,sp,32
    80004024:	84aa                	mv	s1,a0
    80004026:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004028:	00003597          	auipc	a1,0x3
    8000402c:	69058593          	addi	a1,a1,1680 # 800076b8 <syscalls+0x268>
    80004030:	0521                	addi	a0,a0,8
    80004032:	bb7fc0ef          	jal	ra,80000be8 <initlock>
  lk->name = name;
    80004036:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000403a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000403e:	0204a423          	sw	zero,40(s1)
}
    80004042:	60e2                	ld	ra,24(sp)
    80004044:	6442                	ld	s0,16(sp)
    80004046:	64a2                	ld	s1,8(sp)
    80004048:	6902                	ld	s2,0(sp)
    8000404a:	6105                	addi	sp,sp,32
    8000404c:	8082                	ret

000000008000404e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000404e:	1101                	addi	sp,sp,-32
    80004050:	ec06                	sd	ra,24(sp)
    80004052:	e822                	sd	s0,16(sp)
    80004054:	e426                	sd	s1,8(sp)
    80004056:	e04a                	sd	s2,0(sp)
    80004058:	1000                	addi	s0,sp,32
    8000405a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000405c:	00850913          	addi	s2,a0,8
    80004060:	854a                	mv	a0,s2
    80004062:	c07fc0ef          	jal	ra,80000c68 <acquire>
  while (lk->locked) {
    80004066:	409c                	lw	a5,0(s1)
    80004068:	c799                	beqz	a5,80004076 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    8000406a:	85ca                	mv	a1,s2
    8000406c:	8526                	mv	a0,s1
    8000406e:	e67fd0ef          	jal	ra,80001ed4 <sleep>
  while (lk->locked) {
    80004072:	409c                	lw	a5,0(s1)
    80004074:	fbfd                	bnez	a5,8000406a <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004076:	4785                	li	a5,1
    80004078:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000407a:	8e5fd0ef          	jal	ra,8000195e <myproc>
    8000407e:	591c                	lw	a5,48(a0)
    80004080:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004082:	854a                	mv	a0,s2
    80004084:	c7dfc0ef          	jal	ra,80000d00 <release>
}
    80004088:	60e2                	ld	ra,24(sp)
    8000408a:	6442                	ld	s0,16(sp)
    8000408c:	64a2                	ld	s1,8(sp)
    8000408e:	6902                	ld	s2,0(sp)
    80004090:	6105                	addi	sp,sp,32
    80004092:	8082                	ret

0000000080004094 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004094:	1101                	addi	sp,sp,-32
    80004096:	ec06                	sd	ra,24(sp)
    80004098:	e822                	sd	s0,16(sp)
    8000409a:	e426                	sd	s1,8(sp)
    8000409c:	e04a                	sd	s2,0(sp)
    8000409e:	1000                	addi	s0,sp,32
    800040a0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800040a2:	00850913          	addi	s2,a0,8
    800040a6:	854a                	mv	a0,s2
    800040a8:	bc1fc0ef          	jal	ra,80000c68 <acquire>
  lk->locked = 0;
    800040ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800040b0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800040b4:	8526                	mv	a0,s1
    800040b6:	e6bfd0ef          	jal	ra,80001f20 <wakeup>
  release(&lk->lk);
    800040ba:	854a                	mv	a0,s2
    800040bc:	c45fc0ef          	jal	ra,80000d00 <release>
}
    800040c0:	60e2                	ld	ra,24(sp)
    800040c2:	6442                	ld	s0,16(sp)
    800040c4:	64a2                	ld	s1,8(sp)
    800040c6:	6902                	ld	s2,0(sp)
    800040c8:	6105                	addi	sp,sp,32
    800040ca:	8082                	ret

00000000800040cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800040cc:	7179                	addi	sp,sp,-48
    800040ce:	f406                	sd	ra,40(sp)
    800040d0:	f022                	sd	s0,32(sp)
    800040d2:	ec26                	sd	s1,24(sp)
    800040d4:	e84a                	sd	s2,16(sp)
    800040d6:	e44e                	sd	s3,8(sp)
    800040d8:	1800                	addi	s0,sp,48
    800040da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800040dc:	00850913          	addi	s2,a0,8
    800040e0:	854a                	mv	a0,s2
    800040e2:	b87fc0ef          	jal	ra,80000c68 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800040e6:	409c                	lw	a5,0(s1)
    800040e8:	ef89                	bnez	a5,80004102 <holdingsleep+0x36>
    800040ea:	4481                	li	s1,0
  release(&lk->lk);
    800040ec:	854a                	mv	a0,s2
    800040ee:	c13fc0ef          	jal	ra,80000d00 <release>
  return r;
}
    800040f2:	8526                	mv	a0,s1
    800040f4:	70a2                	ld	ra,40(sp)
    800040f6:	7402                	ld	s0,32(sp)
    800040f8:	64e2                	ld	s1,24(sp)
    800040fa:	6942                	ld	s2,16(sp)
    800040fc:	69a2                	ld	s3,8(sp)
    800040fe:	6145                	addi	sp,sp,48
    80004100:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004102:	0284a983          	lw	s3,40(s1)
    80004106:	859fd0ef          	jal	ra,8000195e <myproc>
    8000410a:	5904                	lw	s1,48(a0)
    8000410c:	413484b3          	sub	s1,s1,s3
    80004110:	0014b493          	seqz	s1,s1
    80004114:	bfe1                	j	800040ec <holdingsleep+0x20>

0000000080004116 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004116:	1141                	addi	sp,sp,-16
    80004118:	e406                	sd	ra,8(sp)
    8000411a:	e022                	sd	s0,0(sp)
    8000411c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000411e:	00003597          	auipc	a1,0x3
    80004122:	5aa58593          	addi	a1,a1,1450 # 800076c8 <syscalls+0x278>
    80004126:	0023c517          	auipc	a0,0x23c
    8000412a:	dba50513          	addi	a0,a0,-582 # 8023fee0 <ftable>
    8000412e:	abbfc0ef          	jal	ra,80000be8 <initlock>
}
    80004132:	60a2                	ld	ra,8(sp)
    80004134:	6402                	ld	s0,0(sp)
    80004136:	0141                	addi	sp,sp,16
    80004138:	8082                	ret

000000008000413a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000413a:	1101                	addi	sp,sp,-32
    8000413c:	ec06                	sd	ra,24(sp)
    8000413e:	e822                	sd	s0,16(sp)
    80004140:	e426                	sd	s1,8(sp)
    80004142:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004144:	0023c517          	auipc	a0,0x23c
    80004148:	d9c50513          	addi	a0,a0,-612 # 8023fee0 <ftable>
    8000414c:	b1dfc0ef          	jal	ra,80000c68 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004150:	0023c497          	auipc	s1,0x23c
    80004154:	da848493          	addi	s1,s1,-600 # 8023fef8 <ftable+0x18>
    80004158:	0023d717          	auipc	a4,0x23d
    8000415c:	d4070713          	addi	a4,a4,-704 # 80240e98 <disk>
    if(f->ref == 0){
    80004160:	40dc                	lw	a5,4(s1)
    80004162:	cf89                	beqz	a5,8000417c <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004164:	02848493          	addi	s1,s1,40
    80004168:	fee49ce3          	bne	s1,a4,80004160 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000416c:	0023c517          	auipc	a0,0x23c
    80004170:	d7450513          	addi	a0,a0,-652 # 8023fee0 <ftable>
    80004174:	b8dfc0ef          	jal	ra,80000d00 <release>
  return 0;
    80004178:	4481                	li	s1,0
    8000417a:	a809                	j	8000418c <filealloc+0x52>
      f->ref = 1;
    8000417c:	4785                	li	a5,1
    8000417e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004180:	0023c517          	auipc	a0,0x23c
    80004184:	d6050513          	addi	a0,a0,-672 # 8023fee0 <ftable>
    80004188:	b79fc0ef          	jal	ra,80000d00 <release>
}
    8000418c:	8526                	mv	a0,s1
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004198:	1101                	addi	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	1000                	addi	s0,sp,32
    800041a2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800041a4:	0023c517          	auipc	a0,0x23c
    800041a8:	d3c50513          	addi	a0,a0,-708 # 8023fee0 <ftable>
    800041ac:	abdfc0ef          	jal	ra,80000c68 <acquire>
  if(f->ref < 1)
    800041b0:	40dc                	lw	a5,4(s1)
    800041b2:	02f05063          	blez	a5,800041d2 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    800041b6:	2785                	addiw	a5,a5,1
    800041b8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800041ba:	0023c517          	auipc	a0,0x23c
    800041be:	d2650513          	addi	a0,a0,-730 # 8023fee0 <ftable>
    800041c2:	b3ffc0ef          	jal	ra,80000d00 <release>
  return f;
}
    800041c6:	8526                	mv	a0,s1
    800041c8:	60e2                	ld	ra,24(sp)
    800041ca:	6442                	ld	s0,16(sp)
    800041cc:	64a2                	ld	s1,8(sp)
    800041ce:	6105                	addi	sp,sp,32
    800041d0:	8082                	ret
    panic("filedup");
    800041d2:	00003517          	auipc	a0,0x3
    800041d6:	4fe50513          	addi	a0,a0,1278 # 800076d0 <syscalls+0x280>
    800041da:	d90fc0ef          	jal	ra,8000076a <panic>

00000000800041de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800041de:	7139                	addi	sp,sp,-64
    800041e0:	fc06                	sd	ra,56(sp)
    800041e2:	f822                	sd	s0,48(sp)
    800041e4:	f426                	sd	s1,40(sp)
    800041e6:	f04a                	sd	s2,32(sp)
    800041e8:	ec4e                	sd	s3,24(sp)
    800041ea:	e852                	sd	s4,16(sp)
    800041ec:	e456                	sd	s5,8(sp)
    800041ee:	0080                	addi	s0,sp,64
    800041f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800041f2:	0023c517          	auipc	a0,0x23c
    800041f6:	cee50513          	addi	a0,a0,-786 # 8023fee0 <ftable>
    800041fa:	a6ffc0ef          	jal	ra,80000c68 <acquire>
  if(f->ref < 1)
    800041fe:	40dc                	lw	a5,4(s1)
    80004200:	04f05963          	blez	a5,80004252 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){
    80004204:	37fd                	addiw	a5,a5,-1
    80004206:	0007871b          	sext.w	a4,a5
    8000420a:	c0dc                	sw	a5,4(s1)
    8000420c:	04e04963          	bgtz	a4,8000425e <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004210:	0004a903          	lw	s2,0(s1)
    80004214:	0094ca83          	lbu	s5,9(s1)
    80004218:	0104ba03          	ld	s4,16(s1)
    8000421c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004220:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004224:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004228:	0023c517          	auipc	a0,0x23c
    8000422c:	cb850513          	addi	a0,a0,-840 # 8023fee0 <ftable>
    80004230:	ad1fc0ef          	jal	ra,80000d00 <release>

  if(ff.type == FD_PIPE){
    80004234:	4785                	li	a5,1
    80004236:	04f90363          	beq	s2,a5,8000427c <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000423a:	3979                	addiw	s2,s2,-2
    8000423c:	4785                	li	a5,1
    8000423e:	0327e663          	bltu	a5,s2,8000426a <fileclose+0x8c>
    begin_op();
    80004242:	b8fff0ef          	jal	ra,80003dd0 <begin_op>
    iput(ff.ip);
    80004246:	854e                	mv	a0,s3
    80004248:	b28ff0ef          	jal	ra,80003570 <iput>
    end_op();
    8000424c:	bf5ff0ef          	jal	ra,80003e40 <end_op>
    80004250:	a829                	j	8000426a <fileclose+0x8c>
    panic("fileclose");
    80004252:	00003517          	auipc	a0,0x3
    80004256:	48650513          	addi	a0,a0,1158 # 800076d8 <syscalls+0x288>
    8000425a:	d10fc0ef          	jal	ra,8000076a <panic>
    release(&ftable.lock);
    8000425e:	0023c517          	auipc	a0,0x23c
    80004262:	c8250513          	addi	a0,a0,-894 # 8023fee0 <ftable>
    80004266:	a9bfc0ef          	jal	ra,80000d00 <release>
  }
}
    8000426a:	70e2                	ld	ra,56(sp)
    8000426c:	7442                	ld	s0,48(sp)
    8000426e:	74a2                	ld	s1,40(sp)
    80004270:	7902                	ld	s2,32(sp)
    80004272:	69e2                	ld	s3,24(sp)
    80004274:	6a42                	ld	s4,16(sp)
    80004276:	6aa2                	ld	s5,8(sp)
    80004278:	6121                	addi	sp,sp,64
    8000427a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000427c:	85d6                	mv	a1,s5
    8000427e:	8552                	mv	a0,s4
    80004280:	2ec000ef          	jal	ra,8000456c <pipeclose>
    80004284:	b7dd                	j	8000426a <fileclose+0x8c>

0000000080004286 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004286:	715d                	addi	sp,sp,-80
    80004288:	e486                	sd	ra,72(sp)
    8000428a:	e0a2                	sd	s0,64(sp)
    8000428c:	fc26                	sd	s1,56(sp)
    8000428e:	f84a                	sd	s2,48(sp)
    80004290:	f44e                	sd	s3,40(sp)
    80004292:	0880                	addi	s0,sp,80
    80004294:	84aa                	mv	s1,a0
    80004296:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004298:	ec6fd0ef          	jal	ra,8000195e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000429c:	409c                	lw	a5,0(s1)
    8000429e:	37f9                	addiw	a5,a5,-2
    800042a0:	4705                	li	a4,1
    800042a2:	02f76f63          	bltu	a4,a5,800042e0 <filestat+0x5a>
    800042a6:	892a                	mv	s2,a0
    ilock(f->ip);
    800042a8:	6c88                	ld	a0,24(s1)
    800042aa:	948ff0ef          	jal	ra,800033f2 <ilock>
    stati(f->ip, &st);
    800042ae:	fb840593          	addi	a1,s0,-72
    800042b2:	6c88                	ld	a0,24(s1)
    800042b4:	ca0ff0ef          	jal	ra,80003754 <stati>
    iunlock(f->ip);
    800042b8:	6c88                	ld	a0,24(s1)
    800042ba:	9e2ff0ef          	jal	ra,8000349c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800042be:	46e1                	li	a3,24
    800042c0:	fb840613          	addi	a2,s0,-72
    800042c4:	85ce                	mv	a1,s3
    800042c6:	05093503          	ld	a0,80(s2)
    800042ca:	bc2fd0ef          	jal	ra,8000168c <copyout>
    800042ce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800042d2:	60a6                	ld	ra,72(sp)
    800042d4:	6406                	ld	s0,64(sp)
    800042d6:	74e2                	ld	s1,56(sp)
    800042d8:	7942                	ld	s2,48(sp)
    800042da:	79a2                	ld	s3,40(sp)
    800042dc:	6161                	addi	sp,sp,80
    800042de:	8082                	ret
  return -1;
    800042e0:	557d                	li	a0,-1
    800042e2:	bfc5                	j	800042d2 <filestat+0x4c>

00000000800042e4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800042e4:	7179                	addi	sp,sp,-48
    800042e6:	f406                	sd	ra,40(sp)
    800042e8:	f022                	sd	s0,32(sp)
    800042ea:	ec26                	sd	s1,24(sp)
    800042ec:	e84a                	sd	s2,16(sp)
    800042ee:	e44e                	sd	s3,8(sp)
    800042f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800042f2:	00854783          	lbu	a5,8(a0)
    800042f6:	cbc1                	beqz	a5,80004386 <fileread+0xa2>
    800042f8:	84aa                	mv	s1,a0
    800042fa:	89ae                	mv	s3,a1
    800042fc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800042fe:	411c                	lw	a5,0(a0)
    80004300:	4705                	li	a4,1
    80004302:	04e78363          	beq	a5,a4,80004348 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004306:	470d                	li	a4,3
    80004308:	04e78563          	beq	a5,a4,80004352 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000430c:	4709                	li	a4,2
    8000430e:	06e79663          	bne	a5,a4,8000437a <fileread+0x96>
    ilock(f->ip);
    80004312:	6d08                	ld	a0,24(a0)
    80004314:	8deff0ef          	jal	ra,800033f2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004318:	874a                	mv	a4,s2
    8000431a:	5094                	lw	a3,32(s1)
    8000431c:	864e                	mv	a2,s3
    8000431e:	4585                	li	a1,1
    80004320:	6c88                	ld	a0,24(s1)
    80004322:	c5cff0ef          	jal	ra,8000377e <readi>
    80004326:	892a                	mv	s2,a0
    80004328:	00a05563          	blez	a0,80004332 <fileread+0x4e>
      f->off += r;
    8000432c:	509c                	lw	a5,32(s1)
    8000432e:	9fa9                	addw	a5,a5,a0
    80004330:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004332:	6c88                	ld	a0,24(s1)
    80004334:	968ff0ef          	jal	ra,8000349c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004338:	854a                	mv	a0,s2
    8000433a:	70a2                	ld	ra,40(sp)
    8000433c:	7402                	ld	s0,32(sp)
    8000433e:	64e2                	ld	s1,24(sp)
    80004340:	6942                	ld	s2,16(sp)
    80004342:	69a2                	ld	s3,8(sp)
    80004344:	6145                	addi	sp,sp,48
    80004346:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004348:	6908                	ld	a0,16(a0)
    8000434a:	34e000ef          	jal	ra,80004698 <piperead>
    8000434e:	892a                	mv	s2,a0
    80004350:	b7e5                	j	80004338 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004352:	02451783          	lh	a5,36(a0)
    80004356:	03079693          	slli	a3,a5,0x30
    8000435a:	92c1                	srli	a3,a3,0x30
    8000435c:	4725                	li	a4,9
    8000435e:	02d76663          	bltu	a4,a3,8000438a <fileread+0xa6>
    80004362:	0792                	slli	a5,a5,0x4
    80004364:	0023c717          	auipc	a4,0x23c
    80004368:	adc70713          	addi	a4,a4,-1316 # 8023fe40 <devsw>
    8000436c:	97ba                	add	a5,a5,a4
    8000436e:	639c                	ld	a5,0(a5)
    80004370:	cf99                	beqz	a5,8000438e <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);
    80004372:	4505                	li	a0,1
    80004374:	9782                	jalr	a5
    80004376:	892a                	mv	s2,a0
    80004378:	b7c1                	j	80004338 <fileread+0x54>
    panic("fileread");
    8000437a:	00003517          	auipc	a0,0x3
    8000437e:	36e50513          	addi	a0,a0,878 # 800076e8 <syscalls+0x298>
    80004382:	be8fc0ef          	jal	ra,8000076a <panic>
    return -1;
    80004386:	597d                	li	s2,-1
    80004388:	bf45                	j	80004338 <fileread+0x54>
      return -1;
    8000438a:	597d                	li	s2,-1
    8000438c:	b775                	j	80004338 <fileread+0x54>
    8000438e:	597d                	li	s2,-1
    80004390:	b765                	j	80004338 <fileread+0x54>

0000000080004392 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004392:	715d                	addi	sp,sp,-80
    80004394:	e486                	sd	ra,72(sp)
    80004396:	e0a2                	sd	s0,64(sp)
    80004398:	fc26                	sd	s1,56(sp)
    8000439a:	f84a                	sd	s2,48(sp)
    8000439c:	f44e                	sd	s3,40(sp)
    8000439e:	f052                	sd	s4,32(sp)
    800043a0:	ec56                	sd	s5,24(sp)
    800043a2:	e85a                	sd	s6,16(sp)
    800043a4:	e45e                	sd	s7,8(sp)
    800043a6:	e062                	sd	s8,0(sp)
    800043a8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800043aa:	00954783          	lbu	a5,9(a0)
    800043ae:	0e078863          	beqz	a5,8000449e <filewrite+0x10c>
    800043b2:	892a                	mv	s2,a0
    800043b4:	8aae                	mv	s5,a1
    800043b6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800043b8:	411c                	lw	a5,0(a0)
    800043ba:	4705                	li	a4,1
    800043bc:	02e78263          	beq	a5,a4,800043e0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800043c0:	470d                	li	a4,3
    800043c2:	02e78463          	beq	a5,a4,800043ea <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800043c6:	4709                	li	a4,2
    800043c8:	0ce79563          	bne	a5,a4,80004492 <filewrite+0x100>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800043cc:	0ac05163          	blez	a2,8000446e <filewrite+0xdc>
    int i = 0;
    800043d0:	4981                	li	s3,0
    800043d2:	6b05                	lui	s6,0x1
    800043d4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800043d8:	6b85                	lui	s7,0x1
    800043da:	c00b8b9b          	addiw	s7,s7,-1024
    800043de:	a041                	j	8000445e <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);
    800043e0:	6908                	ld	a0,16(a0)
    800043e2:	1e2000ef          	jal	ra,800045c4 <pipewrite>
    800043e6:	8a2a                	mv	s4,a0
    800043e8:	a071                	j	80004474 <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800043ea:	02451783          	lh	a5,36(a0)
    800043ee:	03079693          	slli	a3,a5,0x30
    800043f2:	92c1                	srli	a3,a3,0x30
    800043f4:	4725                	li	a4,9
    800043f6:	0ad76663          	bltu	a4,a3,800044a2 <filewrite+0x110>
    800043fa:	0792                	slli	a5,a5,0x4
    800043fc:	0023c717          	auipc	a4,0x23c
    80004400:	a4470713          	addi	a4,a4,-1468 # 8023fe40 <devsw>
    80004404:	97ba                	add	a5,a5,a4
    80004406:	679c                	ld	a5,8(a5)
    80004408:	cfd9                	beqz	a5,800044a6 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);
    8000440a:	4505                	li	a0,1
    8000440c:	9782                	jalr	a5
    8000440e:	8a2a                	mv	s4,a0
    80004410:	a095                	j	80004474 <filewrite+0xe2>
    80004412:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004416:	9bbff0ef          	jal	ra,80003dd0 <begin_op>
      ilock(f->ip);
    8000441a:	01893503          	ld	a0,24(s2)
    8000441e:	fd5fe0ef          	jal	ra,800033f2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004422:	8762                	mv	a4,s8
    80004424:	02092683          	lw	a3,32(s2)
    80004428:	01598633          	add	a2,s3,s5
    8000442c:	4585                	li	a1,1
    8000442e:	01893503          	ld	a0,24(s2)
    80004432:	c30ff0ef          	jal	ra,80003862 <writei>
    80004436:	84aa                	mv	s1,a0
    80004438:	00a05763          	blez	a0,80004446 <filewrite+0xb4>
        f->off += r;
    8000443c:	02092783          	lw	a5,32(s2)
    80004440:	9fa9                	addw	a5,a5,a0
    80004442:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004446:	01893503          	ld	a0,24(s2)
    8000444a:	852ff0ef          	jal	ra,8000349c <iunlock>
      end_op();
    8000444e:	9f3ff0ef          	jal	ra,80003e40 <end_op>

      if(r != n1){
    80004452:	009c1f63          	bne	s8,s1,80004470 <filewrite+0xde>
        // error from writei
        break;
      }
      i += r;
    80004456:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000445a:	0149db63          	bge	s3,s4,80004470 <filewrite+0xde>
      int n1 = n - i;
    8000445e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004462:	84be                	mv	s1,a5
    80004464:	2781                	sext.w	a5,a5
    80004466:	fafb56e3          	bge	s6,a5,80004412 <filewrite+0x80>
    8000446a:	84de                	mv	s1,s7
    8000446c:	b75d                	j	80004412 <filewrite+0x80>
    int i = 0;
    8000446e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004470:	013a1f63          	bne	s4,s3,8000448e <filewrite+0xfc>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004474:	8552                	mv	a0,s4
    80004476:	60a6                	ld	ra,72(sp)
    80004478:	6406                	ld	s0,64(sp)
    8000447a:	74e2                	ld	s1,56(sp)
    8000447c:	7942                	ld	s2,48(sp)
    8000447e:	79a2                	ld	s3,40(sp)
    80004480:	7a02                	ld	s4,32(sp)
    80004482:	6ae2                	ld	s5,24(sp)
    80004484:	6b42                	ld	s6,16(sp)
    80004486:	6ba2                	ld	s7,8(sp)
    80004488:	6c02                	ld	s8,0(sp)
    8000448a:	6161                	addi	sp,sp,80
    8000448c:	8082                	ret
    ret = (i == n ? n : -1);
    8000448e:	5a7d                	li	s4,-1
    80004490:	b7d5                	j	80004474 <filewrite+0xe2>
    panic("filewrite");
    80004492:	00003517          	auipc	a0,0x3
    80004496:	26650513          	addi	a0,a0,614 # 800076f8 <syscalls+0x2a8>
    8000449a:	ad0fc0ef          	jal	ra,8000076a <panic>
    return -1;
    8000449e:	5a7d                	li	s4,-1
    800044a0:	bfd1                	j	80004474 <filewrite+0xe2>
      return -1;
    800044a2:	5a7d                	li	s4,-1
    800044a4:	bfc1                	j	80004474 <filewrite+0xe2>
    800044a6:	5a7d                	li	s4,-1
    800044a8:	b7f1                	j	80004474 <filewrite+0xe2>

00000000800044aa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800044aa:	7179                	addi	sp,sp,-48
    800044ac:	f406                	sd	ra,40(sp)
    800044ae:	f022                	sd	s0,32(sp)
    800044b0:	ec26                	sd	s1,24(sp)
    800044b2:	e84a                	sd	s2,16(sp)
    800044b4:	e44e                	sd	s3,8(sp)
    800044b6:	e052                	sd	s4,0(sp)
    800044b8:	1800                	addi	s0,sp,48
    800044ba:	84aa                	mv	s1,a0
    800044bc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800044be:	0005b023          	sd	zero,0(a1)
    800044c2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800044c6:	c75ff0ef          	jal	ra,8000413a <filealloc>
    800044ca:	e088                	sd	a0,0(s1)
    800044cc:	cd35                	beqz	a0,80004548 <pipealloc+0x9e>
    800044ce:	c6dff0ef          	jal	ra,8000413a <filealloc>
    800044d2:	00aa3023          	sd	a0,0(s4)
    800044d6:	c52d                	beqz	a0,80004540 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800044d8:	e28fc0ef          	jal	ra,80000b00 <kalloc>
    800044dc:	892a                	mv	s2,a0
    800044de:	cd31                	beqz	a0,8000453a <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800044e0:	4985                	li	s3,1
    800044e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800044e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800044ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800044ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800044f2:	00003597          	auipc	a1,0x3
    800044f6:	21658593          	addi	a1,a1,534 # 80007708 <syscalls+0x2b8>
    800044fa:	eeefc0ef          	jal	ra,80000be8 <initlock>
  (*f0)->type = FD_PIPE;
    800044fe:	609c                	ld	a5,0(s1)
    80004500:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004504:	609c                	ld	a5,0(s1)
    80004506:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000450a:	609c                	ld	a5,0(s1)
    8000450c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004510:	609c                	ld	a5,0(s1)
    80004512:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004516:	000a3783          	ld	a5,0(s4)
    8000451a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000451e:	000a3783          	ld	a5,0(s4)
    80004522:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004526:	000a3783          	ld	a5,0(s4)
    8000452a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000452e:	000a3783          	ld	a5,0(s4)
    80004532:	0127b823          	sd	s2,16(a5)
  return 0;
    80004536:	4501                	li	a0,0
    80004538:	a005                	j	80004558 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000453a:	6088                	ld	a0,0(s1)
    8000453c:	e501                	bnez	a0,80004544 <pipealloc+0x9a>
    8000453e:	a029                	j	80004548 <pipealloc+0x9e>
    80004540:	6088                	ld	a0,0(s1)
    80004542:	c11d                	beqz	a0,80004568 <pipealloc+0xbe>
    fileclose(*f0);
    80004544:	c9bff0ef          	jal	ra,800041de <fileclose>
  if(*f1)
    80004548:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000454c:	557d                	li	a0,-1
  if(*f1)
    8000454e:	c789                	beqz	a5,80004558 <pipealloc+0xae>
    fileclose(*f1);
    80004550:	853e                	mv	a0,a5
    80004552:	c8dff0ef          	jal	ra,800041de <fileclose>
  return -1;
    80004556:	557d                	li	a0,-1
}
    80004558:	70a2                	ld	ra,40(sp)
    8000455a:	7402                	ld	s0,32(sp)
    8000455c:	64e2                	ld	s1,24(sp)
    8000455e:	6942                	ld	s2,16(sp)
    80004560:	69a2                	ld	s3,8(sp)
    80004562:	6a02                	ld	s4,0(sp)
    80004564:	6145                	addi	sp,sp,48
    80004566:	8082                	ret
  return -1;
    80004568:	557d                	li	a0,-1
    8000456a:	b7fd                	j	80004558 <pipealloc+0xae>

000000008000456c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000456c:	1101                	addi	sp,sp,-32
    8000456e:	ec06                	sd	ra,24(sp)
    80004570:	e822                	sd	s0,16(sp)
    80004572:	e426                	sd	s1,8(sp)
    80004574:	e04a                	sd	s2,0(sp)
    80004576:	1000                	addi	s0,sp,32
    80004578:	84aa                	mv	s1,a0
    8000457a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000457c:	eecfc0ef          	jal	ra,80000c68 <acquire>
  if(writable){
    80004580:	02090763          	beqz	s2,800045ae <pipeclose+0x42>
    pi->writeopen = 0;
    80004584:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004588:	21848513          	addi	a0,s1,536
    8000458c:	995fd0ef          	jal	ra,80001f20 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004590:	2204b783          	ld	a5,544(s1)
    80004594:	e785                	bnez	a5,800045bc <pipeclose+0x50>
    release(&pi->lock);
    80004596:	8526                	mv	a0,s1
    80004598:	f68fc0ef          	jal	ra,80000d00 <release>
    kfree((char*)pi);
    8000459c:	8526                	mv	a0,s1
    8000459e:	bfefc0ef          	jal	ra,8000099c <kfree>
  } else
    release(&pi->lock);
}
    800045a2:	60e2                	ld	ra,24(sp)
    800045a4:	6442                	ld	s0,16(sp)
    800045a6:	64a2                	ld	s1,8(sp)
    800045a8:	6902                	ld	s2,0(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret
    pi->readopen = 0;
    800045ae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800045b2:	21c48513          	addi	a0,s1,540
    800045b6:	96bfd0ef          	jal	ra,80001f20 <wakeup>
    800045ba:	bfd9                	j	80004590 <pipeclose+0x24>
    release(&pi->lock);
    800045bc:	8526                	mv	a0,s1
    800045be:	f42fc0ef          	jal	ra,80000d00 <release>
}
    800045c2:	b7c5                	j	800045a2 <pipeclose+0x36>

00000000800045c4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800045c4:	711d                	addi	sp,sp,-96
    800045c6:	ec86                	sd	ra,88(sp)
    800045c8:	e8a2                	sd	s0,80(sp)
    800045ca:	e4a6                	sd	s1,72(sp)
    800045cc:	e0ca                	sd	s2,64(sp)
    800045ce:	fc4e                	sd	s3,56(sp)
    800045d0:	f852                	sd	s4,48(sp)
    800045d2:	f456                	sd	s5,40(sp)
    800045d4:	f05a                	sd	s6,32(sp)
    800045d6:	ec5e                	sd	s7,24(sp)
    800045d8:	e862                	sd	s8,16(sp)
    800045da:	1080                	addi	s0,sp,96
    800045dc:	84aa                	mv	s1,a0
    800045de:	8aae                	mv	s5,a1
    800045e0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800045e2:	b7cfd0ef          	jal	ra,8000195e <myproc>
    800045e6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800045e8:	8526                	mv	a0,s1
    800045ea:	e7efc0ef          	jal	ra,80000c68 <acquire>
  while(i < n){
    800045ee:	09405c63          	blez	s4,80004686 <pipewrite+0xc2>
  int i = 0;
    800045f2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800045f4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800045f6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800045fa:	21c48b93          	addi	s7,s1,540
    800045fe:	a81d                	j	80004634 <pipewrite+0x70>
      release(&pi->lock);
    80004600:	8526                	mv	a0,s1
    80004602:	efefc0ef          	jal	ra,80000d00 <release>
      return -1;
    80004606:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004608:	854a                	mv	a0,s2
    8000460a:	60e6                	ld	ra,88(sp)
    8000460c:	6446                	ld	s0,80(sp)
    8000460e:	64a6                	ld	s1,72(sp)
    80004610:	6906                	ld	s2,64(sp)
    80004612:	79e2                	ld	s3,56(sp)
    80004614:	7a42                	ld	s4,48(sp)
    80004616:	7aa2                	ld	s5,40(sp)
    80004618:	7b02                	ld	s6,32(sp)
    8000461a:	6be2                	ld	s7,24(sp)
    8000461c:	6c42                	ld	s8,16(sp)
    8000461e:	6125                	addi	sp,sp,96
    80004620:	8082                	ret
      wakeup(&pi->nread);
    80004622:	8562                	mv	a0,s8
    80004624:	8fdfd0ef          	jal	ra,80001f20 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004628:	85a6                	mv	a1,s1
    8000462a:	855e                	mv	a0,s7
    8000462c:	8a9fd0ef          	jal	ra,80001ed4 <sleep>
  while(i < n){
    80004630:	05495c63          	bge	s2,s4,80004688 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    80004634:	2204a783          	lw	a5,544(s1)
    80004638:	d7e1                	beqz	a5,80004600 <pipewrite+0x3c>
    8000463a:	854e                	mv	a0,s3
    8000463c:	ce9fd0ef          	jal	ra,80002324 <killed>
    80004640:	f161                	bnez	a0,80004600 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004642:	2184a783          	lw	a5,536(s1)
    80004646:	21c4a703          	lw	a4,540(s1)
    8000464a:	2007879b          	addiw	a5,a5,512
    8000464e:	fcf70ae3          	beq	a4,a5,80004622 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004652:	4685                	li	a3,1
    80004654:	01590633          	add	a2,s2,s5
    80004658:	faf40593          	addi	a1,s0,-81
    8000465c:	0509b503          	ld	a0,80(s3)
    80004660:	8f2fd0ef          	jal	ra,80001752 <copyin>
    80004664:	03650263          	beq	a0,s6,80004688 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004668:	21c4a783          	lw	a5,540(s1)
    8000466c:	0017871b          	addiw	a4,a5,1
    80004670:	20e4ae23          	sw	a4,540(s1)
    80004674:	1ff7f793          	andi	a5,a5,511
    80004678:	97a6                	add	a5,a5,s1
    8000467a:	faf44703          	lbu	a4,-81(s0)
    8000467e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004682:	2905                	addiw	s2,s2,1
    80004684:	b775                	j	80004630 <pipewrite+0x6c>
  int i = 0;
    80004686:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004688:	21848513          	addi	a0,s1,536
    8000468c:	895fd0ef          	jal	ra,80001f20 <wakeup>
  release(&pi->lock);
    80004690:	8526                	mv	a0,s1
    80004692:	e6efc0ef          	jal	ra,80000d00 <release>
  return i;
    80004696:	bf8d                	j	80004608 <pipewrite+0x44>

0000000080004698 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004698:	715d                	addi	sp,sp,-80
    8000469a:	e486                	sd	ra,72(sp)
    8000469c:	e0a2                	sd	s0,64(sp)
    8000469e:	fc26                	sd	s1,56(sp)
    800046a0:	f84a                	sd	s2,48(sp)
    800046a2:	f44e                	sd	s3,40(sp)
    800046a4:	f052                	sd	s4,32(sp)
    800046a6:	ec56                	sd	s5,24(sp)
    800046a8:	e85a                	sd	s6,16(sp)
    800046aa:	0880                	addi	s0,sp,80
    800046ac:	84aa                	mv	s1,a0
    800046ae:	892e                	mv	s2,a1
    800046b0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800046b2:	aacfd0ef          	jal	ra,8000195e <myproc>
    800046b6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800046b8:	8526                	mv	a0,s1
    800046ba:	daefc0ef          	jal	ra,80000c68 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800046be:	2184a703          	lw	a4,536(s1)
    800046c2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800046c6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800046ca:	02f71363          	bne	a4,a5,800046f0 <piperead+0x58>
    800046ce:	2244a783          	lw	a5,548(s1)
    800046d2:	cf99                	beqz	a5,800046f0 <piperead+0x58>
    if(killed(pr)){
    800046d4:	8552                	mv	a0,s4
    800046d6:	c4ffd0ef          	jal	ra,80002324 <killed>
    800046da:	e149                	bnez	a0,8000475c <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800046dc:	85a6                	mv	a1,s1
    800046de:	854e                	mv	a0,s3
    800046e0:	ff4fd0ef          	jal	ra,80001ed4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800046e4:	2184a703          	lw	a4,536(s1)
    800046e8:	21c4a783          	lw	a5,540(s1)
    800046ec:	fef701e3          	beq	a4,a5,800046ce <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046f2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046f4:	05505263          	blez	s5,80004738 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    800046f8:	2184a783          	lw	a5,536(s1)
    800046fc:	21c4a703          	lw	a4,540(s1)
    80004700:	02f70c63          	beq	a4,a5,80004738 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    80004704:	1ff7f793          	andi	a5,a5,511
    80004708:	97a6                	add	a5,a5,s1
    8000470a:	0187c783          	lbu	a5,24(a5)
    8000470e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004712:	4685                	li	a3,1
    80004714:	fbf40613          	addi	a2,s0,-65
    80004718:	85ca                	mv	a1,s2
    8000471a:	050a3503          	ld	a0,80(s4)
    8000471e:	f6ffc0ef          	jal	ra,8000168c <copyout>
    80004722:	05650263          	beq	a0,s6,80004766 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004726:	2184a783          	lw	a5,536(s1)
    8000472a:	2785                	addiw	a5,a5,1
    8000472c:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004730:	2985                	addiw	s3,s3,1
    80004732:	0905                	addi	s2,s2,1
    80004734:	fd3a92e3          	bne	s5,s3,800046f8 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004738:	21c48513          	addi	a0,s1,540
    8000473c:	fe4fd0ef          	jal	ra,80001f20 <wakeup>
  release(&pi->lock);
    80004740:	8526                	mv	a0,s1
    80004742:	dbefc0ef          	jal	ra,80000d00 <release>
  return i;
}
    80004746:	854e                	mv	a0,s3
    80004748:	60a6                	ld	ra,72(sp)
    8000474a:	6406                	ld	s0,64(sp)
    8000474c:	74e2                	ld	s1,56(sp)
    8000474e:	7942                	ld	s2,48(sp)
    80004750:	79a2                	ld	s3,40(sp)
    80004752:	7a02                	ld	s4,32(sp)
    80004754:	6ae2                	ld	s5,24(sp)
    80004756:	6b42                	ld	s6,16(sp)
    80004758:	6161                	addi	sp,sp,80
    8000475a:	8082                	ret
      release(&pi->lock);
    8000475c:	8526                	mv	a0,s1
    8000475e:	da2fc0ef          	jal	ra,80000d00 <release>
      return -1;
    80004762:	59fd                	li	s3,-1
    80004764:	b7cd                	j	80004746 <piperead+0xae>
      if(i == 0)
    80004766:	fc0999e3          	bnez	s3,80004738 <piperead+0xa0>
        i = -1;
    8000476a:	89aa                	mv	s3,a0
    8000476c:	b7f1                	j	80004738 <piperead+0xa0>

000000008000476e <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000476e:	1141                	addi	sp,sp,-16
    80004770:	e422                	sd	s0,8(sp)
    80004772:	0800                	addi	s0,sp,16
    80004774:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004776:	8905                	andi	a0,a0,1
    80004778:	c111                	beqz	a0,8000477c <flags2perm+0xe>
      perm = PTE_X;
    8000477a:	4521                	li	a0,8
    if(flags & 0x2)
    8000477c:	8b89                	andi	a5,a5,2
    8000477e:	c399                	beqz	a5,80004784 <flags2perm+0x16>
      perm |= PTE_W;
    80004780:	00456513          	ori	a0,a0,4
    return perm;
}
    80004784:	6422                	ld	s0,8(sp)
    80004786:	0141                	addi	sp,sp,16
    80004788:	8082                	ret

000000008000478a <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000478a:	de010113          	addi	sp,sp,-544
    8000478e:	20113c23          	sd	ra,536(sp)
    80004792:	20813823          	sd	s0,528(sp)
    80004796:	20913423          	sd	s1,520(sp)
    8000479a:	21213023          	sd	s2,512(sp)
    8000479e:	ffce                	sd	s3,504(sp)
    800047a0:	fbd2                	sd	s4,496(sp)
    800047a2:	f7d6                	sd	s5,488(sp)
    800047a4:	f3da                	sd	s6,480(sp)
    800047a6:	efde                	sd	s7,472(sp)
    800047a8:	ebe2                	sd	s8,464(sp)
    800047aa:	e7e6                	sd	s9,456(sp)
    800047ac:	e3ea                	sd	s10,448(sp)
    800047ae:	ff6e                	sd	s11,440(sp)
    800047b0:	1400                	addi	s0,sp,544
    800047b2:	892a                	mv	s2,a0
    800047b4:	dea43423          	sd	a0,-536(s0)
    800047b8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800047bc:	9a2fd0ef          	jal	ra,8000195e <myproc>
    800047c0:	84aa                	mv	s1,a0

  begin_op();
    800047c2:	e0eff0ef          	jal	ra,80003dd0 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800047c6:	854a                	mv	a0,s2
    800047c8:	c18ff0ef          	jal	ra,80003be0 <namei>
    800047cc:	c13d                	beqz	a0,80004832 <kexec+0xa8>
    800047ce:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800047d0:	c23fe0ef          	jal	ra,800033f2 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800047d4:	04000713          	li	a4,64
    800047d8:	4681                	li	a3,0
    800047da:	e5040613          	addi	a2,s0,-432
    800047de:	4581                	li	a1,0
    800047e0:	8556                	mv	a0,s5
    800047e2:	f9dfe0ef          	jal	ra,8000377e <readi>
    800047e6:	04000793          	li	a5,64
    800047ea:	00f51a63          	bne	a0,a5,800047fe <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800047ee:	e5042703          	lw	a4,-432(s0)
    800047f2:	464c47b7          	lui	a5,0x464c4
    800047f6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800047fa:	04f70063          	beq	a4,a5,8000483a <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800047fe:	8556                	mv	a0,s5
    80004800:	df9fe0ef          	jal	ra,800035f8 <iunlockput>
    end_op();
    80004804:	e3cff0ef          	jal	ra,80003e40 <end_op>
  }
  return -1;
    80004808:	557d                	li	a0,-1
}
    8000480a:	21813083          	ld	ra,536(sp)
    8000480e:	21013403          	ld	s0,528(sp)
    80004812:	20813483          	ld	s1,520(sp)
    80004816:	20013903          	ld	s2,512(sp)
    8000481a:	79fe                	ld	s3,504(sp)
    8000481c:	7a5e                	ld	s4,496(sp)
    8000481e:	7abe                	ld	s5,488(sp)
    80004820:	7b1e                	ld	s6,480(sp)
    80004822:	6bfe                	ld	s7,472(sp)
    80004824:	6c5e                	ld	s8,464(sp)
    80004826:	6cbe                	ld	s9,456(sp)
    80004828:	6d1e                	ld	s10,448(sp)
    8000482a:	7dfa                	ld	s11,440(sp)
    8000482c:	22010113          	addi	sp,sp,544
    80004830:	8082                	ret
    end_op();
    80004832:	e0eff0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80004836:	557d                	li	a0,-1
    80004838:	bfc9                	j	8000480a <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    8000483a:	8526                	mv	a0,s1
    8000483c:	a28fd0ef          	jal	ra,80001a64 <proc_pagetable>
    80004840:	8b2a                	mv	s6,a0
    80004842:	dd55                	beqz	a0,800047fe <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004844:	e7042783          	lw	a5,-400(s0)
    80004848:	e8845703          	lhu	a4,-376(s0)
    8000484c:	c325                	beqz	a4,800048ac <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000484e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004850:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004854:	6a05                	lui	s4,0x1
    80004856:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000485a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000485e:	6d85                	lui	s11,0x1
    80004860:	7d7d                	lui	s10,0xfffff
    80004862:	a411                	j	80004a66 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004864:	00003517          	auipc	a0,0x3
    80004868:	eac50513          	addi	a0,a0,-340 # 80007710 <syscalls+0x2c0>
    8000486c:	efffb0ef          	jal	ra,8000076a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004870:	874a                	mv	a4,s2
    80004872:	009c86bb          	addw	a3,s9,s1
    80004876:	4581                	li	a1,0
    80004878:	8556                	mv	a0,s5
    8000487a:	f05fe0ef          	jal	ra,8000377e <readi>
    8000487e:	2501                	sext.w	a0,a0
    80004880:	18a91263          	bne	s2,a0,80004a04 <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004884:	009d84bb          	addw	s1,s11,s1
    80004888:	013d09bb          	addw	s3,s10,s3
    8000488c:	1b74fd63          	bgeu	s1,s7,80004a46 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004890:	02049593          	slli	a1,s1,0x20
    80004894:	9181                	srli	a1,a1,0x20
    80004896:	95e2                	add	a1,a1,s8
    80004898:	855a                	mv	a0,s6
    8000489a:	fb8fc0ef          	jal	ra,80001052 <walkaddr>
    8000489e:	862a                	mv	a2,a0
    if(pa == 0)
    800048a0:	d171                	beqz	a0,80004864 <kexec+0xda>
      n = PGSIZE;
    800048a2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800048a4:	fd49f6e3          	bgeu	s3,s4,80004870 <kexec+0xe6>
      n = sz - i;
    800048a8:	894e                	mv	s2,s3
    800048aa:	b7d9                	j	80004870 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800048ac:	4901                	li	s2,0
  iunlockput(ip);
    800048ae:	8556                	mv	a0,s5
    800048b0:	d49fe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    800048b4:	d8cff0ef          	jal	ra,80003e40 <end_op>
  p = myproc();
    800048b8:	8a6fd0ef          	jal	ra,8000195e <myproc>
    800048bc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800048be:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800048c2:	6785                	lui	a5,0x1
    800048c4:	17fd                	addi	a5,a5,-1
    800048c6:	993e                	add	s2,s2,a5
    800048c8:	77fd                	lui	a5,0xfffff
    800048ca:	00f977b3          	and	a5,s2,a5
    800048ce:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800048d2:	4691                	li	a3,4
    800048d4:	6609                	lui	a2,0x2
    800048d6:	963e                	add	a2,a2,a5
    800048d8:	85be                	mv	a1,a5
    800048da:	855a                	mv	a0,s6
    800048dc:	a41fc0ef          	jal	ra,8000131c <uvmalloc>
    800048e0:	8c2a                	mv	s8,a0
  ip = 0;
    800048e2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800048e4:	12050063          	beqz	a0,80004a04 <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800048e8:	75f9                	lui	a1,0xffffe
    800048ea:	95aa                	add	a1,a1,a0
    800048ec:	855a                	mv	a0,s6
    800048ee:	be9fc0ef          	jal	ra,800014d6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048f2:	7afd                	lui	s5,0xfffff
    800048f4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800048f6:	df043783          	ld	a5,-528(s0)
    800048fa:	6388                	ld	a0,0(a5)
    800048fc:	c135                	beqz	a0,80004960 <kexec+0x1d6>
    800048fe:	e9040993          	addi	s3,s0,-368
    80004902:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004906:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004908:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000490a:	daafc0ef          	jal	ra,80000eb4 <strlen>
    8000490e:	0015079b          	addiw	a5,a0,1
    80004912:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004916:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000491a:	11596a63          	bltu	s2,s5,80004a2e <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000491e:	df043d83          	ld	s11,-528(s0)
    80004922:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004926:	8552                	mv	a0,s4
    80004928:	d8cfc0ef          	jal	ra,80000eb4 <strlen>
    8000492c:	0015069b          	addiw	a3,a0,1
    80004930:	8652                	mv	a2,s4
    80004932:	85ca                	mv	a1,s2
    80004934:	855a                	mv	a0,s6
    80004936:	d57fc0ef          	jal	ra,8000168c <copyout>
    8000493a:	0e054e63          	bltz	a0,80004a36 <kexec+0x2ac>
    ustack[argc] = sp;
    8000493e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004942:	0485                	addi	s1,s1,1
    80004944:	008d8793          	addi	a5,s11,8
    80004948:	def43823          	sd	a5,-528(s0)
    8000494c:	008db503          	ld	a0,8(s11)
    80004950:	c911                	beqz	a0,80004964 <kexec+0x1da>
    if(argc >= MAXARG)
    80004952:	09a1                	addi	s3,s3,8
    80004954:	fb3c9be3          	bne	s9,s3,8000490a <kexec+0x180>
  sz = sz1;
    80004958:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000495c:	4a81                	li	s5,0
    8000495e:	a05d                	j	80004a04 <kexec+0x27a>
  sp = sz;
    80004960:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004962:	4481                	li	s1,0
  ustack[argc] = 0;
    80004964:	00349793          	slli	a5,s1,0x3
    80004968:	f9040713          	addi	a4,s0,-112
    8000496c:	97ba                	add	a5,a5,a4
    8000496e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbdf28>
  sp -= (argc+1) * sizeof(uint64);
    80004972:	00148693          	addi	a3,s1,1
    80004976:	068e                	slli	a3,a3,0x3
    80004978:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000497c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004980:	01597663          	bgeu	s2,s5,8000498c <kexec+0x202>
  sz = sz1;
    80004984:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004988:	4a81                	li	s5,0
    8000498a:	a8ad                	j	80004a04 <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000498c:	e9040613          	addi	a2,s0,-368
    80004990:	85ca                	mv	a1,s2
    80004992:	855a                	mv	a0,s6
    80004994:	cf9fc0ef          	jal	ra,8000168c <copyout>
    80004998:	0a054363          	bltz	a0,80004a3e <kexec+0x2b4>
  p->trapframe->a1 = sp;
    8000499c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800049a0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800049a4:	de843783          	ld	a5,-536(s0)
    800049a8:	0007c703          	lbu	a4,0(a5)
    800049ac:	cf11                	beqz	a4,800049c8 <kexec+0x23e>
    800049ae:	0785                	addi	a5,a5,1
    if(*s == '/')
    800049b0:	02f00693          	li	a3,47
    800049b4:	a039                	j	800049c2 <kexec+0x238>
      last = s+1;
    800049b6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800049ba:	0785                	addi	a5,a5,1
    800049bc:	fff7c703          	lbu	a4,-1(a5)
    800049c0:	c701                	beqz	a4,800049c8 <kexec+0x23e>
    if(*s == '/')
    800049c2:	fed71ce3          	bne	a4,a3,800049ba <kexec+0x230>
    800049c6:	bfc5                	j	800049b6 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    800049c8:	4641                	li	a2,16
    800049ca:	de843583          	ld	a1,-536(s0)
    800049ce:	158b8513          	addi	a0,s7,344
    800049d2:	cb0fc0ef          	jal	ra,80000e82 <safestrcpy>
  oldpagetable = p->pagetable;
    800049d6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800049da:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800049de:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800049e2:	058bb783          	ld	a5,88(s7)
    800049e6:	e6843703          	ld	a4,-408(s0)
    800049ea:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800049ec:	058bb783          	ld	a5,88(s7)
    800049f0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049f4:	85ea                	mv	a1,s10
    800049f6:	8f2fd0ef          	jal	ra,80001ae8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049fa:	0004851b          	sext.w	a0,s1
    800049fe:	b531                	j	8000480a <kexec+0x80>
    80004a00:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004a04:	df843583          	ld	a1,-520(s0)
    80004a08:	855a                	mv	a0,s6
    80004a0a:	8defd0ef          	jal	ra,80001ae8 <proc_freepagetable>
  if(ip){
    80004a0e:	de0a98e3          	bnez	s5,800047fe <kexec+0x74>
  return -1;
    80004a12:	557d                	li	a0,-1
    80004a14:	bbdd                	j	8000480a <kexec+0x80>
    80004a16:	df243c23          	sd	s2,-520(s0)
    80004a1a:	b7ed                	j	80004a04 <kexec+0x27a>
    80004a1c:	df243c23          	sd	s2,-520(s0)
    80004a20:	b7d5                	j	80004a04 <kexec+0x27a>
    80004a22:	df243c23          	sd	s2,-520(s0)
    80004a26:	bff9                	j	80004a04 <kexec+0x27a>
    80004a28:	df243c23          	sd	s2,-520(s0)
    80004a2c:	bfe1                	j	80004a04 <kexec+0x27a>
  sz = sz1;
    80004a2e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a32:	4a81                	li	s5,0
    80004a34:	bfc1                	j	80004a04 <kexec+0x27a>
  sz = sz1;
    80004a36:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a3a:	4a81                	li	s5,0
    80004a3c:	b7e1                	j	80004a04 <kexec+0x27a>
  sz = sz1;
    80004a3e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004a42:	4a81                	li	s5,0
    80004a44:	b7c1                	j	80004a04 <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004a46:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a4a:	e0843783          	ld	a5,-504(s0)
    80004a4e:	0017869b          	addiw	a3,a5,1
    80004a52:	e0d43423          	sd	a3,-504(s0)
    80004a56:	e0043783          	ld	a5,-512(s0)
    80004a5a:	0387879b          	addiw	a5,a5,56
    80004a5e:	e8845703          	lhu	a4,-376(s0)
    80004a62:	e4e6d6e3          	bge	a3,a4,800048ae <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004a66:	2781                	sext.w	a5,a5
    80004a68:	e0f43023          	sd	a5,-512(s0)
    80004a6c:	03800713          	li	a4,56
    80004a70:	86be                	mv	a3,a5
    80004a72:	e1840613          	addi	a2,s0,-488
    80004a76:	4581                	li	a1,0
    80004a78:	8556                	mv	a0,s5
    80004a7a:	d05fe0ef          	jal	ra,8000377e <readi>
    80004a7e:	03800793          	li	a5,56
    80004a82:	f6f51fe3          	bne	a0,a5,80004a00 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004a86:	e1842783          	lw	a5,-488(s0)
    80004a8a:	4705                	li	a4,1
    80004a8c:	fae79fe3          	bne	a5,a4,80004a4a <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004a90:	e4043483          	ld	s1,-448(s0)
    80004a94:	e3843783          	ld	a5,-456(s0)
    80004a98:	f6f4efe3          	bltu	s1,a5,80004a16 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004a9c:	e2843783          	ld	a5,-472(s0)
    80004aa0:	94be                	add	s1,s1,a5
    80004aa2:	f6f4ede3          	bltu	s1,a5,80004a1c <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004aa6:	de043703          	ld	a4,-544(s0)
    80004aaa:	8ff9                	and	a5,a5,a4
    80004aac:	fbbd                	bnez	a5,80004a22 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004aae:	e1c42503          	lw	a0,-484(s0)
    80004ab2:	cbdff0ef          	jal	ra,8000476e <flags2perm>
    80004ab6:	86aa                	mv	a3,a0
    80004ab8:	8626                	mv	a2,s1
    80004aba:	85ca                	mv	a1,s2
    80004abc:	855a                	mv	a0,s6
    80004abe:	85ffc0ef          	jal	ra,8000131c <uvmalloc>
    80004ac2:	dea43c23          	sd	a0,-520(s0)
    80004ac6:	d12d                	beqz	a0,80004a28 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ac8:	e2843c03          	ld	s8,-472(s0)
    80004acc:	e2042c83          	lw	s9,-480(s0)
    80004ad0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ad4:	f60b89e3          	beqz	s7,80004a46 <kexec+0x2bc>
    80004ad8:	89de                	mv	s3,s7
    80004ada:	4481                	li	s1,0
    80004adc:	bb55                	j	80004890 <kexec+0x106>

0000000080004ade <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ade:	7179                	addi	sp,sp,-48
    80004ae0:	f406                	sd	ra,40(sp)
    80004ae2:	f022                	sd	s0,32(sp)
    80004ae4:	ec26                	sd	s1,24(sp)
    80004ae6:	e84a                	sd	s2,16(sp)
    80004ae8:	1800                	addi	s0,sp,48
    80004aea:	892e                	mv	s2,a1
    80004aec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004aee:	fdc40593          	addi	a1,s0,-36
    80004af2:	f19fd0ef          	jal	ra,80002a0a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004af6:	fdc42703          	lw	a4,-36(s0)
    80004afa:	47bd                	li	a5,15
    80004afc:	02e7e963          	bltu	a5,a4,80004b2e <argfd+0x50>
    80004b00:	e5ffc0ef          	jal	ra,8000195e <myproc>
    80004b04:	fdc42703          	lw	a4,-36(s0)
    80004b08:	01a70793          	addi	a5,a4,26
    80004b0c:	078e                	slli	a5,a5,0x3
    80004b0e:	953e                	add	a0,a0,a5
    80004b10:	611c                	ld	a5,0(a0)
    80004b12:	c385                	beqz	a5,80004b32 <argfd+0x54>
    return -1;
  if(pfd)
    80004b14:	00090463          	beqz	s2,80004b1c <argfd+0x3e>
    *pfd = fd;
    80004b18:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004b1c:	4501                	li	a0,0
  if(pf)
    80004b1e:	c091                	beqz	s1,80004b22 <argfd+0x44>
    *pf = f;
    80004b20:	e09c                	sd	a5,0(s1)
}
    80004b22:	70a2                	ld	ra,40(sp)
    80004b24:	7402                	ld	s0,32(sp)
    80004b26:	64e2                	ld	s1,24(sp)
    80004b28:	6942                	ld	s2,16(sp)
    80004b2a:	6145                	addi	sp,sp,48
    80004b2c:	8082                	ret
    return -1;
    80004b2e:	557d                	li	a0,-1
    80004b30:	bfcd                	j	80004b22 <argfd+0x44>
    80004b32:	557d                	li	a0,-1
    80004b34:	b7fd                	j	80004b22 <argfd+0x44>

0000000080004b36 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004b36:	1101                	addi	sp,sp,-32
    80004b38:	ec06                	sd	ra,24(sp)
    80004b3a:	e822                	sd	s0,16(sp)
    80004b3c:	e426                	sd	s1,8(sp)
    80004b3e:	1000                	addi	s0,sp,32
    80004b40:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004b42:	e1dfc0ef          	jal	ra,8000195e <myproc>
    80004b46:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004b48:	0d050793          	addi	a5,a0,208
    80004b4c:	4501                	li	a0,0
    80004b4e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004b50:	6398                	ld	a4,0(a5)
    80004b52:	cb19                	beqz	a4,80004b68 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004b54:	2505                	addiw	a0,a0,1
    80004b56:	07a1                	addi	a5,a5,8
    80004b58:	fed51ce3          	bne	a0,a3,80004b50 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004b5c:	557d                	li	a0,-1
}
    80004b5e:	60e2                	ld	ra,24(sp)
    80004b60:	6442                	ld	s0,16(sp)
    80004b62:	64a2                	ld	s1,8(sp)
    80004b64:	6105                	addi	sp,sp,32
    80004b66:	8082                	ret
      p->ofile[fd] = f;
    80004b68:	01a50793          	addi	a5,a0,26
    80004b6c:	078e                	slli	a5,a5,0x3
    80004b6e:	963e                	add	a2,a2,a5
    80004b70:	e204                	sd	s1,0(a2)
      return fd;
    80004b72:	b7f5                	j	80004b5e <fdalloc+0x28>

0000000080004b74 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004b74:	715d                	addi	sp,sp,-80
    80004b76:	e486                	sd	ra,72(sp)
    80004b78:	e0a2                	sd	s0,64(sp)
    80004b7a:	fc26                	sd	s1,56(sp)
    80004b7c:	f84a                	sd	s2,48(sp)
    80004b7e:	f44e                	sd	s3,40(sp)
    80004b80:	f052                	sd	s4,32(sp)
    80004b82:	ec56                	sd	s5,24(sp)
    80004b84:	e85a                	sd	s6,16(sp)
    80004b86:	0880                	addi	s0,sp,80
    80004b88:	8b2e                	mv	s6,a1
    80004b8a:	89b2                	mv	s3,a2
    80004b8c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004b8e:	fb040593          	addi	a1,s0,-80
    80004b92:	868ff0ef          	jal	ra,80003bfa <nameiparent>
    80004b96:	84aa                	mv	s1,a0
    80004b98:	10050b63          	beqz	a0,80004cae <create+0x13a>
    return 0;

  ilock(dp);
    80004b9c:	857fe0ef          	jal	ra,800033f2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ba0:	4601                	li	a2,0
    80004ba2:	fb040593          	addi	a1,s0,-80
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	dd3fe0ef          	jal	ra,8000397a <dirlookup>
    80004bac:	8aaa                	mv	s5,a0
    80004bae:	c521                	beqz	a0,80004bf6 <create+0x82>
    iunlockput(dp);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	a47fe0ef          	jal	ra,800035f8 <iunlockput>
    ilock(ip);
    80004bb6:	8556                	mv	a0,s5
    80004bb8:	83bfe0ef          	jal	ra,800033f2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004bbc:	000b059b          	sext.w	a1,s6
    80004bc0:	4789                	li	a5,2
    80004bc2:	02f59563          	bne	a1,a5,80004bec <create+0x78>
    80004bc6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbe06c>
    80004bca:	37f9                	addiw	a5,a5,-2
    80004bcc:	17c2                	slli	a5,a5,0x30
    80004bce:	93c1                	srli	a5,a5,0x30
    80004bd0:	4705                	li	a4,1
    80004bd2:	00f76d63          	bltu	a4,a5,80004bec <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004bd6:	8556                	mv	a0,s5
    80004bd8:	60a6                	ld	ra,72(sp)
    80004bda:	6406                	ld	s0,64(sp)
    80004bdc:	74e2                	ld	s1,56(sp)
    80004bde:	7942                	ld	s2,48(sp)
    80004be0:	79a2                	ld	s3,40(sp)
    80004be2:	7a02                	ld	s4,32(sp)
    80004be4:	6ae2                	ld	s5,24(sp)
    80004be6:	6b42                	ld	s6,16(sp)
    80004be8:	6161                	addi	sp,sp,80
    80004bea:	8082                	ret
    iunlockput(ip);
    80004bec:	8556                	mv	a0,s5
    80004bee:	a0bfe0ef          	jal	ra,800035f8 <iunlockput>
    return 0;
    80004bf2:	4a81                	li	s5,0
    80004bf4:	b7cd                	j	80004bd6 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004bf6:	85da                	mv	a1,s6
    80004bf8:	4088                	lw	a0,0(s1)
    80004bfa:	e90fe0ef          	jal	ra,8000328a <ialloc>
    80004bfe:	8a2a                	mv	s4,a0
    80004c00:	cd1d                	beqz	a0,80004c3e <create+0xca>
  ilock(ip);
    80004c02:	ff0fe0ef          	jal	ra,800033f2 <ilock>
  ip->major = major;
    80004c06:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004c0a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004c0e:	4905                	li	s2,1
    80004c10:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004c14:	8552                	mv	a0,s4
    80004c16:	f2afe0ef          	jal	ra,80003340 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004c1a:	000b059b          	sext.w	a1,s6
    80004c1e:	03258563          	beq	a1,s2,80004c48 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c22:	004a2603          	lw	a2,4(s4)
    80004c26:	fb040593          	addi	a1,s0,-80
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	f1bfe0ef          	jal	ra,80003b46 <dirlink>
    80004c30:	06054363          	bltz	a0,80004c96 <create+0x122>
  iunlockput(dp);
    80004c34:	8526                	mv	a0,s1
    80004c36:	9c3fe0ef          	jal	ra,800035f8 <iunlockput>
  return ip;
    80004c3a:	8ad2                	mv	s5,s4
    80004c3c:	bf69                	j	80004bd6 <create+0x62>
    iunlockput(dp);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	9b9fe0ef          	jal	ra,800035f8 <iunlockput>
    return 0;
    80004c44:	8ad2                	mv	s5,s4
    80004c46:	bf41                	j	80004bd6 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004c48:	004a2603          	lw	a2,4(s4)
    80004c4c:	00003597          	auipc	a1,0x3
    80004c50:	ae458593          	addi	a1,a1,-1308 # 80007730 <syscalls+0x2e0>
    80004c54:	8552                	mv	a0,s4
    80004c56:	ef1fe0ef          	jal	ra,80003b46 <dirlink>
    80004c5a:	02054e63          	bltz	a0,80004c96 <create+0x122>
    80004c5e:	40d0                	lw	a2,4(s1)
    80004c60:	00003597          	auipc	a1,0x3
    80004c64:	ad858593          	addi	a1,a1,-1320 # 80007738 <syscalls+0x2e8>
    80004c68:	8552                	mv	a0,s4
    80004c6a:	eddfe0ef          	jal	ra,80003b46 <dirlink>
    80004c6e:	02054463          	bltz	a0,80004c96 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c72:	004a2603          	lw	a2,4(s4)
    80004c76:	fb040593          	addi	a1,s0,-80
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ecbfe0ef          	jal	ra,80003b46 <dirlink>
    80004c80:	00054b63          	bltz	a0,80004c96 <create+0x122>
    dp->nlink++;  // for ".."
    80004c84:	04a4d783          	lhu	a5,74(s1)
    80004c88:	2785                	addiw	a5,a5,1
    80004c8a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	eb0fe0ef          	jal	ra,80003340 <iupdate>
    80004c94:	b745                	j	80004c34 <create+0xc0>
  ip->nlink = 0;
    80004c96:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004c9a:	8552                	mv	a0,s4
    80004c9c:	ea4fe0ef          	jal	ra,80003340 <iupdate>
  iunlockput(ip);
    80004ca0:	8552                	mv	a0,s4
    80004ca2:	957fe0ef          	jal	ra,800035f8 <iunlockput>
  iunlockput(dp);
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	951fe0ef          	jal	ra,800035f8 <iunlockput>
  return 0;
    80004cac:	b72d                	j	80004bd6 <create+0x62>
    return 0;
    80004cae:	8aaa                	mv	s5,a0
    80004cb0:	b71d                	j	80004bd6 <create+0x62>

0000000080004cb2 <sys_dup>:
{
    80004cb2:	7179                	addi	sp,sp,-48
    80004cb4:	f406                	sd	ra,40(sp)
    80004cb6:	f022                	sd	s0,32(sp)
    80004cb8:	ec26                	sd	s1,24(sp)
    80004cba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004cbc:	fd840613          	addi	a2,s0,-40
    80004cc0:	4581                	li	a1,0
    80004cc2:	4501                	li	a0,0
    80004cc4:	e1bff0ef          	jal	ra,80004ade <argfd>
    return -1;
    80004cc8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004cca:	00054f63          	bltz	a0,80004ce8 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)
    80004cce:	fd843503          	ld	a0,-40(s0)
    80004cd2:	e65ff0ef          	jal	ra,80004b36 <fdalloc>
    80004cd6:	84aa                	mv	s1,a0
    return -1;
    80004cd8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004cda:	00054763          	bltz	a0,80004ce8 <sys_dup+0x36>
  filedup(f);
    80004cde:	fd843503          	ld	a0,-40(s0)
    80004ce2:	cb6ff0ef          	jal	ra,80004198 <filedup>
  return fd;
    80004ce6:	87a6                	mv	a5,s1
}
    80004ce8:	853e                	mv	a0,a5
    80004cea:	70a2                	ld	ra,40(sp)
    80004cec:	7402                	ld	s0,32(sp)
    80004cee:	64e2                	ld	s1,24(sp)
    80004cf0:	6145                	addi	sp,sp,48
    80004cf2:	8082                	ret

0000000080004cf4 <sys_read>:
{
    80004cf4:	7179                	addi	sp,sp,-48
    80004cf6:	f406                	sd	ra,40(sp)
    80004cf8:	f022                	sd	s0,32(sp)
    80004cfa:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004cfc:	fd840593          	addi	a1,s0,-40
    80004d00:	4505                	li	a0,1
    80004d02:	d25fd0ef          	jal	ra,80002a26 <argaddr>
  argint(2, &n);
    80004d06:	fe440593          	addi	a1,s0,-28
    80004d0a:	4509                	li	a0,2
    80004d0c:	cfffd0ef          	jal	ra,80002a0a <argint>
  if(argfd(0, 0, &f) < 0)
    80004d10:	fe840613          	addi	a2,s0,-24
    80004d14:	4581                	li	a1,0
    80004d16:	4501                	li	a0,0
    80004d18:	dc7ff0ef          	jal	ra,80004ade <argfd>
    80004d1c:	87aa                	mv	a5,a0
    return -1;
    80004d1e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d20:	0007ca63          	bltz	a5,80004d34 <sys_read+0x40>
  return fileread(f, p, n);
    80004d24:	fe442603          	lw	a2,-28(s0)
    80004d28:	fd843583          	ld	a1,-40(s0)
    80004d2c:	fe843503          	ld	a0,-24(s0)
    80004d30:	db4ff0ef          	jal	ra,800042e4 <fileread>
}
    80004d34:	70a2                	ld	ra,40(sp)
    80004d36:	7402                	ld	s0,32(sp)
    80004d38:	6145                	addi	sp,sp,48
    80004d3a:	8082                	ret

0000000080004d3c <sys_write>:
{
    80004d3c:	7179                	addi	sp,sp,-48
    80004d3e:	f406                	sd	ra,40(sp)
    80004d40:	f022                	sd	s0,32(sp)
    80004d42:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004d44:	fd840593          	addi	a1,s0,-40
    80004d48:	4505                	li	a0,1
    80004d4a:	cddfd0ef          	jal	ra,80002a26 <argaddr>
  argint(2, &n);
    80004d4e:	fe440593          	addi	a1,s0,-28
    80004d52:	4509                	li	a0,2
    80004d54:	cb7fd0ef          	jal	ra,80002a0a <argint>
  if(argfd(0, 0, &f) < 0)
    80004d58:	fe840613          	addi	a2,s0,-24
    80004d5c:	4581                	li	a1,0
    80004d5e:	4501                	li	a0,0
    80004d60:	d7fff0ef          	jal	ra,80004ade <argfd>
    80004d64:	87aa                	mv	a5,a0
    return -1;
    80004d66:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d68:	0007ca63          	bltz	a5,80004d7c <sys_write+0x40>
  return filewrite(f, p, n);
    80004d6c:	fe442603          	lw	a2,-28(s0)
    80004d70:	fd843583          	ld	a1,-40(s0)
    80004d74:	fe843503          	ld	a0,-24(s0)
    80004d78:	e1aff0ef          	jal	ra,80004392 <filewrite>
}
    80004d7c:	70a2                	ld	ra,40(sp)
    80004d7e:	7402                	ld	s0,32(sp)
    80004d80:	6145                	addi	sp,sp,48
    80004d82:	8082                	ret

0000000080004d84 <sys_close>:
{
    80004d84:	1101                	addi	sp,sp,-32
    80004d86:	ec06                	sd	ra,24(sp)
    80004d88:	e822                	sd	s0,16(sp)
    80004d8a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004d8c:	fe040613          	addi	a2,s0,-32
    80004d90:	fec40593          	addi	a1,s0,-20
    80004d94:	4501                	li	a0,0
    80004d96:	d49ff0ef          	jal	ra,80004ade <argfd>
    return -1;
    80004d9a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004d9c:	02054063          	bltz	a0,80004dbc <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004da0:	bbffc0ef          	jal	ra,8000195e <myproc>
    80004da4:	fec42783          	lw	a5,-20(s0)
    80004da8:	07e9                	addi	a5,a5,26
    80004daa:	078e                	slli	a5,a5,0x3
    80004dac:	97aa                	add	a5,a5,a0
    80004dae:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80004db2:	fe043503          	ld	a0,-32(s0)
    80004db6:	c28ff0ef          	jal	ra,800041de <fileclose>
  return 0;
    80004dba:	4781                	li	a5,0
}
    80004dbc:	853e                	mv	a0,a5
    80004dbe:	60e2                	ld	ra,24(sp)
    80004dc0:	6442                	ld	s0,16(sp)
    80004dc2:	6105                	addi	sp,sp,32
    80004dc4:	8082                	ret

0000000080004dc6 <sys_fstat>:
{
    80004dc6:	1101                	addi	sp,sp,-32
    80004dc8:	ec06                	sd	ra,24(sp)
    80004dca:	e822                	sd	s0,16(sp)
    80004dcc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004dce:	fe040593          	addi	a1,s0,-32
    80004dd2:	4505                	li	a0,1
    80004dd4:	c53fd0ef          	jal	ra,80002a26 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004dd8:	fe840613          	addi	a2,s0,-24
    80004ddc:	4581                	li	a1,0
    80004dde:	4501                	li	a0,0
    80004de0:	cffff0ef          	jal	ra,80004ade <argfd>
    80004de4:	87aa                	mv	a5,a0
    return -1;
    80004de6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004de8:	0007c863          	bltz	a5,80004df8 <sys_fstat+0x32>
  return filestat(f, st);
    80004dec:	fe043583          	ld	a1,-32(s0)
    80004df0:	fe843503          	ld	a0,-24(s0)
    80004df4:	c92ff0ef          	jal	ra,80004286 <filestat>
}
    80004df8:	60e2                	ld	ra,24(sp)
    80004dfa:	6442                	ld	s0,16(sp)
    80004dfc:	6105                	addi	sp,sp,32
    80004dfe:	8082                	ret

0000000080004e00 <sys_link>:
{
    80004e00:	7169                	addi	sp,sp,-304
    80004e02:	f606                	sd	ra,296(sp)
    80004e04:	f222                	sd	s0,288(sp)
    80004e06:	ee26                	sd	s1,280(sp)
    80004e08:	ea4a                	sd	s2,272(sp)
    80004e0a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004e0c:	08000613          	li	a2,128
    80004e10:	ed040593          	addi	a1,s0,-304
    80004e14:	4501                	li	a0,0
    80004e16:	c2dfd0ef          	jal	ra,80002a42 <argstr>
    return -1;
    80004e1a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004e1c:	0c054663          	bltz	a0,80004ee8 <sys_link+0xe8>
    80004e20:	08000613          	li	a2,128
    80004e24:	f5040593          	addi	a1,s0,-176
    80004e28:	4505                	li	a0,1
    80004e2a:	c19fd0ef          	jal	ra,80002a42 <argstr>
    return -1;
    80004e2e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004e30:	0a054c63          	bltz	a0,80004ee8 <sys_link+0xe8>
  begin_op();
    80004e34:	f9dfe0ef          	jal	ra,80003dd0 <begin_op>
  if((ip = namei(old)) == 0){
    80004e38:	ed040513          	addi	a0,s0,-304
    80004e3c:	da5fe0ef          	jal	ra,80003be0 <namei>
    80004e40:	84aa                	mv	s1,a0
    80004e42:	c525                	beqz	a0,80004eaa <sys_link+0xaa>
  ilock(ip);
    80004e44:	daefe0ef          	jal	ra,800033f2 <ilock>
  if(ip->type == T_DIR){
    80004e48:	04449703          	lh	a4,68(s1)
    80004e4c:	4785                	li	a5,1
    80004e4e:	06f70263          	beq	a4,a5,80004eb2 <sys_link+0xb2>
  ip->nlink++;
    80004e52:	04a4d783          	lhu	a5,74(s1)
    80004e56:	2785                	addiw	a5,a5,1
    80004e58:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	ce2fe0ef          	jal	ra,80003340 <iupdate>
  iunlock(ip);
    80004e62:	8526                	mv	a0,s1
    80004e64:	e38fe0ef          	jal	ra,8000349c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004e68:	fd040593          	addi	a1,s0,-48
    80004e6c:	f5040513          	addi	a0,s0,-176
    80004e70:	d8bfe0ef          	jal	ra,80003bfa <nameiparent>
    80004e74:	892a                	mv	s2,a0
    80004e76:	c921                	beqz	a0,80004ec6 <sys_link+0xc6>
  ilock(dp);
    80004e78:	d7afe0ef          	jal	ra,800033f2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004e7c:	00092703          	lw	a4,0(s2)
    80004e80:	409c                	lw	a5,0(s1)
    80004e82:	02f71f63          	bne	a4,a5,80004ec0 <sys_link+0xc0>
    80004e86:	40d0                	lw	a2,4(s1)
    80004e88:	fd040593          	addi	a1,s0,-48
    80004e8c:	854a                	mv	a0,s2
    80004e8e:	cb9fe0ef          	jal	ra,80003b46 <dirlink>
    80004e92:	02054763          	bltz	a0,80004ec0 <sys_link+0xc0>
  iunlockput(dp);
    80004e96:	854a                	mv	a0,s2
    80004e98:	f60fe0ef          	jal	ra,800035f8 <iunlockput>
  iput(ip);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ed2fe0ef          	jal	ra,80003570 <iput>
  end_op();
    80004ea2:	f9ffe0ef          	jal	ra,80003e40 <end_op>
  return 0;
    80004ea6:	4781                	li	a5,0
    80004ea8:	a081                	j	80004ee8 <sys_link+0xe8>
    end_op();
    80004eaa:	f97fe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80004eae:	57fd                	li	a5,-1
    80004eb0:	a825                	j	80004ee8 <sys_link+0xe8>
    iunlockput(ip);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	f44fe0ef          	jal	ra,800035f8 <iunlockput>
    end_op();
    80004eb8:	f89fe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80004ebc:	57fd                	li	a5,-1
    80004ebe:	a02d                	j	80004ee8 <sys_link+0xe8>
    iunlockput(dp);
    80004ec0:	854a                	mv	a0,s2
    80004ec2:	f36fe0ef          	jal	ra,800035f8 <iunlockput>
  ilock(ip);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	d2afe0ef          	jal	ra,800033f2 <ilock>
  ip->nlink--;
    80004ecc:	04a4d783          	lhu	a5,74(s1)
    80004ed0:	37fd                	addiw	a5,a5,-1
    80004ed2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	c68fe0ef          	jal	ra,80003340 <iupdate>
  iunlockput(ip);
    80004edc:	8526                	mv	a0,s1
    80004ede:	f1afe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    80004ee2:	f5ffe0ef          	jal	ra,80003e40 <end_op>
  return -1;
    80004ee6:	57fd                	li	a5,-1
}
    80004ee8:	853e                	mv	a0,a5
    80004eea:	70b2                	ld	ra,296(sp)
    80004eec:	7412                	ld	s0,288(sp)
    80004eee:	64f2                	ld	s1,280(sp)
    80004ef0:	6952                	ld	s2,272(sp)
    80004ef2:	6155                	addi	sp,sp,304
    80004ef4:	8082                	ret

0000000080004ef6 <sys_unlink>:
{
    80004ef6:	7151                	addi	sp,sp,-240
    80004ef8:	f586                	sd	ra,232(sp)
    80004efa:	f1a2                	sd	s0,224(sp)
    80004efc:	eda6                	sd	s1,216(sp)
    80004efe:	e9ca                	sd	s2,208(sp)
    80004f00:	e5ce                	sd	s3,200(sp)
    80004f02:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004f04:	08000613          	li	a2,128
    80004f08:	f3040593          	addi	a1,s0,-208
    80004f0c:	4501                	li	a0,0
    80004f0e:	b35fd0ef          	jal	ra,80002a42 <argstr>
    80004f12:	12054b63          	bltz	a0,80005048 <sys_unlink+0x152>
  begin_op();
    80004f16:	ebbfe0ef          	jal	ra,80003dd0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004f1a:	fb040593          	addi	a1,s0,-80
    80004f1e:	f3040513          	addi	a0,s0,-208
    80004f22:	cd9fe0ef          	jal	ra,80003bfa <nameiparent>
    80004f26:	84aa                	mv	s1,a0
    80004f28:	c54d                	beqz	a0,80004fd2 <sys_unlink+0xdc>
  ilock(dp);
    80004f2a:	cc8fe0ef          	jal	ra,800033f2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004f2e:	00003597          	auipc	a1,0x3
    80004f32:	80258593          	addi	a1,a1,-2046 # 80007730 <syscalls+0x2e0>
    80004f36:	fb040513          	addi	a0,s0,-80
    80004f3a:	a2bfe0ef          	jal	ra,80003964 <namecmp>
    80004f3e:	10050a63          	beqz	a0,80005052 <sys_unlink+0x15c>
    80004f42:	00002597          	auipc	a1,0x2
    80004f46:	7f658593          	addi	a1,a1,2038 # 80007738 <syscalls+0x2e8>
    80004f4a:	fb040513          	addi	a0,s0,-80
    80004f4e:	a17fe0ef          	jal	ra,80003964 <namecmp>
    80004f52:	10050063          	beqz	a0,80005052 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004f56:	f2c40613          	addi	a2,s0,-212
    80004f5a:	fb040593          	addi	a1,s0,-80
    80004f5e:	8526                	mv	a0,s1
    80004f60:	a1bfe0ef          	jal	ra,8000397a <dirlookup>
    80004f64:	892a                	mv	s2,a0
    80004f66:	0e050663          	beqz	a0,80005052 <sys_unlink+0x15c>
  ilock(ip);
    80004f6a:	c88fe0ef          	jal	ra,800033f2 <ilock>
  if(ip->nlink < 1)
    80004f6e:	04a91783          	lh	a5,74(s2)
    80004f72:	06f05463          	blez	a5,80004fda <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004f76:	04491703          	lh	a4,68(s2)
    80004f7a:	4785                	li	a5,1
    80004f7c:	06f70563          	beq	a4,a5,80004fe6 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));
    80004f80:	4641                	li	a2,16
    80004f82:	4581                	li	a1,0
    80004f84:	fc040513          	addi	a0,s0,-64
    80004f88:	db5fb0ef          	jal	ra,80000d3c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f8c:	4741                	li	a4,16
    80004f8e:	f2c42683          	lw	a3,-212(s0)
    80004f92:	fc040613          	addi	a2,s0,-64
    80004f96:	4581                	li	a1,0
    80004f98:	8526                	mv	a0,s1
    80004f9a:	8c9fe0ef          	jal	ra,80003862 <writei>
    80004f9e:	47c1                	li	a5,16
    80004fa0:	08f51563          	bne	a0,a5,8000502a <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004fa4:	04491703          	lh	a4,68(s2)
    80004fa8:	4785                	li	a5,1
    80004faa:	08f70663          	beq	a4,a5,80005036 <sys_unlink+0x140>
  iunlockput(dp);
    80004fae:	8526                	mv	a0,s1
    80004fb0:	e48fe0ef          	jal	ra,800035f8 <iunlockput>
  ip->nlink--;
    80004fb4:	04a95783          	lhu	a5,74(s2)
    80004fb8:	37fd                	addiw	a5,a5,-1
    80004fba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004fbe:	854a                	mv	a0,s2
    80004fc0:	b80fe0ef          	jal	ra,80003340 <iupdate>
  iunlockput(ip);
    80004fc4:	854a                	mv	a0,s2
    80004fc6:	e32fe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    80004fca:	e77fe0ef          	jal	ra,80003e40 <end_op>
  return 0;
    80004fce:	4501                	li	a0,0
    80004fd0:	a079                	j	8000505e <sys_unlink+0x168>
    end_op();
    80004fd2:	e6ffe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80004fd6:	557d                	li	a0,-1
    80004fd8:	a059                	j	8000505e <sys_unlink+0x168>
    panic("unlink: nlink < 1");
    80004fda:	00002517          	auipc	a0,0x2
    80004fde:	76650513          	addi	a0,a0,1894 # 80007740 <syscalls+0x2f0>
    80004fe2:	f88fb0ef          	jal	ra,8000076a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004fe6:	04c92703          	lw	a4,76(s2)
    80004fea:	02000793          	li	a5,32
    80004fee:	f8e7f9e3          	bgeu	a5,a4,80004f80 <sys_unlink+0x8a>
    80004ff2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ff6:	4741                	li	a4,16
    80004ff8:	86ce                	mv	a3,s3
    80004ffa:	f1840613          	addi	a2,s0,-232
    80004ffe:	4581                	li	a1,0
    80005000:	854a                	mv	a0,s2
    80005002:	f7cfe0ef          	jal	ra,8000377e <readi>
    80005006:	47c1                	li	a5,16
    80005008:	00f51b63          	bne	a0,a5,8000501e <sys_unlink+0x128>
    if(de.inum != 0)
    8000500c:	f1845783          	lhu	a5,-232(s0)
    80005010:	ef95                	bnez	a5,8000504c <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005012:	29c1                	addiw	s3,s3,16
    80005014:	04c92783          	lw	a5,76(s2)
    80005018:	fcf9efe3          	bltu	s3,a5,80004ff6 <sys_unlink+0x100>
    8000501c:	b795                	j	80004f80 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    8000501e:	00002517          	auipc	a0,0x2
    80005022:	73a50513          	addi	a0,a0,1850 # 80007758 <syscalls+0x308>
    80005026:	f44fb0ef          	jal	ra,8000076a <panic>
    panic("unlink: writei");
    8000502a:	00002517          	auipc	a0,0x2
    8000502e:	74650513          	addi	a0,a0,1862 # 80007770 <syscalls+0x320>
    80005032:	f38fb0ef          	jal	ra,8000076a <panic>
    dp->nlink--;
    80005036:	04a4d783          	lhu	a5,74(s1)
    8000503a:	37fd                	addiw	a5,a5,-1
    8000503c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005040:	8526                	mv	a0,s1
    80005042:	afefe0ef          	jal	ra,80003340 <iupdate>
    80005046:	b7a5                	j	80004fae <sys_unlink+0xb8>
    return -1;
    80005048:	557d                	li	a0,-1
    8000504a:	a811                	j	8000505e <sys_unlink+0x168>
    iunlockput(ip);
    8000504c:	854a                	mv	a0,s2
    8000504e:	daafe0ef          	jal	ra,800035f8 <iunlockput>
  iunlockput(dp);
    80005052:	8526                	mv	a0,s1
    80005054:	da4fe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    80005058:	de9fe0ef          	jal	ra,80003e40 <end_op>
  return -1;
    8000505c:	557d                	li	a0,-1
}
    8000505e:	70ae                	ld	ra,232(sp)
    80005060:	740e                	ld	s0,224(sp)
    80005062:	64ee                	ld	s1,216(sp)
    80005064:	694e                	ld	s2,208(sp)
    80005066:	69ae                	ld	s3,200(sp)
    80005068:	616d                	addi	sp,sp,240
    8000506a:	8082                	ret

000000008000506c <sys_open>:

uint64
sys_open(void)
{
    8000506c:	7131                	addi	sp,sp,-192
    8000506e:	fd06                	sd	ra,184(sp)
    80005070:	f922                	sd	s0,176(sp)
    80005072:	f526                	sd	s1,168(sp)
    80005074:	f14a                	sd	s2,160(sp)
    80005076:	ed4e                	sd	s3,152(sp)
    80005078:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000507a:	f4c40593          	addi	a1,s0,-180
    8000507e:	4505                	li	a0,1
    80005080:	98bfd0ef          	jal	ra,80002a0a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005084:	08000613          	li	a2,128
    80005088:	f5040593          	addi	a1,s0,-176
    8000508c:	4501                	li	a0,0
    8000508e:	9b5fd0ef          	jal	ra,80002a42 <argstr>
    80005092:	87aa                	mv	a5,a0
    return -1;
    80005094:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005096:	0807cd63          	bltz	a5,80005130 <sys_open+0xc4>

  begin_op();
    8000509a:	d37fe0ef          	jal	ra,80003dd0 <begin_op>

  if(omode & O_CREATE){
    8000509e:	f4c42783          	lw	a5,-180(s0)
    800050a2:	2007f793          	andi	a5,a5,512
    800050a6:	c3c5                	beqz	a5,80005146 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800050a8:	4681                	li	a3,0
    800050aa:	4601                	li	a2,0
    800050ac:	4589                	li	a1,2
    800050ae:	f5040513          	addi	a0,s0,-176
    800050b2:	ac3ff0ef          	jal	ra,80004b74 <create>
    800050b6:	84aa                	mv	s1,a0
    if(ip == 0){
    800050b8:	c159                	beqz	a0,8000513e <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800050ba:	04449703          	lh	a4,68(s1)
    800050be:	478d                	li	a5,3
    800050c0:	00f71763          	bne	a4,a5,800050ce <sys_open+0x62>
    800050c4:	0464d703          	lhu	a4,70(s1)
    800050c8:	47a5                	li	a5,9
    800050ca:	0ae7e963          	bltu	a5,a4,8000517c <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800050ce:	86cff0ef          	jal	ra,8000413a <filealloc>
    800050d2:	89aa                	mv	s3,a0
    800050d4:	0c050963          	beqz	a0,800051a6 <sys_open+0x13a>
    800050d8:	a5fff0ef          	jal	ra,80004b36 <fdalloc>
    800050dc:	892a                	mv	s2,a0
    800050de:	0c054163          	bltz	a0,800051a0 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800050e2:	04449703          	lh	a4,68(s1)
    800050e6:	478d                	li	a5,3
    800050e8:	0af70163          	beq	a4,a5,8000518a <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800050ec:	4789                	li	a5,2
    800050ee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800050f2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800050f6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800050fa:	f4c42783          	lw	a5,-180(s0)
    800050fe:	0017c713          	xori	a4,a5,1
    80005102:	8b05                	andi	a4,a4,1
    80005104:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005108:	0037f713          	andi	a4,a5,3
    8000510c:	00e03733          	snez	a4,a4
    80005110:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005114:	4007f793          	andi	a5,a5,1024
    80005118:	c791                	beqz	a5,80005124 <sys_open+0xb8>
    8000511a:	04449703          	lh	a4,68(s1)
    8000511e:	4789                	li	a5,2
    80005120:	06f70c63          	beq	a4,a5,80005198 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80005124:	8526                	mv	a0,s1
    80005126:	b76fe0ef          	jal	ra,8000349c <iunlock>
  end_op();
    8000512a:	d17fe0ef          	jal	ra,80003e40 <end_op>

  return fd;
    8000512e:	854a                	mv	a0,s2
}
    80005130:	70ea                	ld	ra,184(sp)
    80005132:	744a                	ld	s0,176(sp)
    80005134:	74aa                	ld	s1,168(sp)
    80005136:	790a                	ld	s2,160(sp)
    80005138:	69ea                	ld	s3,152(sp)
    8000513a:	6129                	addi	sp,sp,192
    8000513c:	8082                	ret
      end_op();
    8000513e:	d03fe0ef          	jal	ra,80003e40 <end_op>
      return -1;
    80005142:	557d                	li	a0,-1
    80005144:	b7f5                	j	80005130 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80005146:	f5040513          	addi	a0,s0,-176
    8000514a:	a97fe0ef          	jal	ra,80003be0 <namei>
    8000514e:	84aa                	mv	s1,a0
    80005150:	c115                	beqz	a0,80005174 <sys_open+0x108>
    ilock(ip);
    80005152:	aa0fe0ef          	jal	ra,800033f2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005156:	04449703          	lh	a4,68(s1)
    8000515a:	4785                	li	a5,1
    8000515c:	f4f71fe3          	bne	a4,a5,800050ba <sys_open+0x4e>
    80005160:	f4c42783          	lw	a5,-180(s0)
    80005164:	d7ad                	beqz	a5,800050ce <sys_open+0x62>
      iunlockput(ip);
    80005166:	8526                	mv	a0,s1
    80005168:	c90fe0ef          	jal	ra,800035f8 <iunlockput>
      end_op();
    8000516c:	cd5fe0ef          	jal	ra,80003e40 <end_op>
      return -1;
    80005170:	557d                	li	a0,-1
    80005172:	bf7d                	j	80005130 <sys_open+0xc4>
      end_op();
    80005174:	ccdfe0ef          	jal	ra,80003e40 <end_op>
      return -1;
    80005178:	557d                	li	a0,-1
    8000517a:	bf5d                	j	80005130 <sys_open+0xc4>
    iunlockput(ip);
    8000517c:	8526                	mv	a0,s1
    8000517e:	c7afe0ef          	jal	ra,800035f8 <iunlockput>
    end_op();
    80005182:	cbffe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80005186:	557d                	li	a0,-1
    80005188:	b765                	j	80005130 <sys_open+0xc4>
    f->type = FD_DEVICE;
    8000518a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000518e:	04649783          	lh	a5,70(s1)
    80005192:	02f99223          	sh	a5,36(s3)
    80005196:	b785                	j	800050f6 <sys_open+0x8a>
    itrunc(ip);
    80005198:	8526                	mv	a0,s1
    8000519a:	b42fe0ef          	jal	ra,800034dc <itrunc>
    8000519e:	b759                	j	80005124 <sys_open+0xb8>
      fileclose(f);
    800051a0:	854e                	mv	a0,s3
    800051a2:	83cff0ef          	jal	ra,800041de <fileclose>
    iunlockput(ip);
    800051a6:	8526                	mv	a0,s1
    800051a8:	c50fe0ef          	jal	ra,800035f8 <iunlockput>
    end_op();
    800051ac:	c95fe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    800051b0:	557d                	li	a0,-1
    800051b2:	bfbd                	j	80005130 <sys_open+0xc4>

00000000800051b4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800051b4:	7175                	addi	sp,sp,-144
    800051b6:	e506                	sd	ra,136(sp)
    800051b8:	e122                	sd	s0,128(sp)
    800051ba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800051bc:	c15fe0ef          	jal	ra,80003dd0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800051c0:	08000613          	li	a2,128
    800051c4:	f7040593          	addi	a1,s0,-144
    800051c8:	4501                	li	a0,0
    800051ca:	879fd0ef          	jal	ra,80002a42 <argstr>
    800051ce:	02054363          	bltz	a0,800051f4 <sys_mkdir+0x40>
    800051d2:	4681                	li	a3,0
    800051d4:	4601                	li	a2,0
    800051d6:	4585                	li	a1,1
    800051d8:	f7040513          	addi	a0,s0,-144
    800051dc:	999ff0ef          	jal	ra,80004b74 <create>
    800051e0:	c911                	beqz	a0,800051f4 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051e2:	c16fe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    800051e6:	c5bfe0ef          	jal	ra,80003e40 <end_op>
  return 0;
    800051ea:	4501                	li	a0,0
}
    800051ec:	60aa                	ld	ra,136(sp)
    800051ee:	640a                	ld	s0,128(sp)
    800051f0:	6149                	addi	sp,sp,144
    800051f2:	8082                	ret
    end_op();
    800051f4:	c4dfe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    800051f8:	557d                	li	a0,-1
    800051fa:	bfcd                	j	800051ec <sys_mkdir+0x38>

00000000800051fc <sys_mknod>:

uint64
sys_mknod(void)
{
    800051fc:	7135                	addi	sp,sp,-160
    800051fe:	ed06                	sd	ra,152(sp)
    80005200:	e922                	sd	s0,144(sp)
    80005202:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005204:	bcdfe0ef          	jal	ra,80003dd0 <begin_op>
  argint(1, &major);
    80005208:	f6c40593          	addi	a1,s0,-148
    8000520c:	4505                	li	a0,1
    8000520e:	ffcfd0ef          	jal	ra,80002a0a <argint>
  argint(2, &minor);
    80005212:	f6840593          	addi	a1,s0,-152
    80005216:	4509                	li	a0,2
    80005218:	ff2fd0ef          	jal	ra,80002a0a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000521c:	08000613          	li	a2,128
    80005220:	f7040593          	addi	a1,s0,-144
    80005224:	4501                	li	a0,0
    80005226:	81dfd0ef          	jal	ra,80002a42 <argstr>
    8000522a:	02054563          	bltz	a0,80005254 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000522e:	f6841683          	lh	a3,-152(s0)
    80005232:	f6c41603          	lh	a2,-148(s0)
    80005236:	458d                	li	a1,3
    80005238:	f7040513          	addi	a0,s0,-144
    8000523c:	939ff0ef          	jal	ra,80004b74 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005240:	c911                	beqz	a0,80005254 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005242:	bb6fe0ef          	jal	ra,800035f8 <iunlockput>
  end_op();
    80005246:	bfbfe0ef          	jal	ra,80003e40 <end_op>
  return 0;
    8000524a:	4501                	li	a0,0
}
    8000524c:	60ea                	ld	ra,152(sp)
    8000524e:	644a                	ld	s0,144(sp)
    80005250:	610d                	addi	sp,sp,160
    80005252:	8082                	ret
    end_op();
    80005254:	bedfe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    80005258:	557d                	li	a0,-1
    8000525a:	bfcd                	j	8000524c <sys_mknod+0x50>

000000008000525c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000525c:	7135                	addi	sp,sp,-160
    8000525e:	ed06                	sd	ra,152(sp)
    80005260:	e922                	sd	s0,144(sp)
    80005262:	e526                	sd	s1,136(sp)
    80005264:	e14a                	sd	s2,128(sp)
    80005266:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005268:	ef6fc0ef          	jal	ra,8000195e <myproc>
    8000526c:	892a                	mv	s2,a0
  
  begin_op();
    8000526e:	b63fe0ef          	jal	ra,80003dd0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005272:	08000613          	li	a2,128
    80005276:	f6040593          	addi	a1,s0,-160
    8000527a:	4501                	li	a0,0
    8000527c:	fc6fd0ef          	jal	ra,80002a42 <argstr>
    80005280:	04054163          	bltz	a0,800052c2 <sys_chdir+0x66>
    80005284:	f6040513          	addi	a0,s0,-160
    80005288:	959fe0ef          	jal	ra,80003be0 <namei>
    8000528c:	84aa                	mv	s1,a0
    8000528e:	c915                	beqz	a0,800052c2 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005290:	962fe0ef          	jal	ra,800033f2 <ilock>
  if(ip->type != T_DIR){
    80005294:	04449703          	lh	a4,68(s1)
    80005298:	4785                	li	a5,1
    8000529a:	02f71863          	bne	a4,a5,800052ca <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000529e:	8526                	mv	a0,s1
    800052a0:	9fcfe0ef          	jal	ra,8000349c <iunlock>
  iput(p->cwd);
    800052a4:	15093503          	ld	a0,336(s2)
    800052a8:	ac8fe0ef          	jal	ra,80003570 <iput>
  end_op();
    800052ac:	b95fe0ef          	jal	ra,80003e40 <end_op>
  p->cwd = ip;
    800052b0:	14993823          	sd	s1,336(s2)
  return 0;
    800052b4:	4501                	li	a0,0
}
    800052b6:	60ea                	ld	ra,152(sp)
    800052b8:	644a                	ld	s0,144(sp)
    800052ba:	64aa                	ld	s1,136(sp)
    800052bc:	690a                	ld	s2,128(sp)
    800052be:	610d                	addi	sp,sp,160
    800052c0:	8082                	ret
    end_op();
    800052c2:	b7ffe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    800052c6:	557d                	li	a0,-1
    800052c8:	b7fd                	j	800052b6 <sys_chdir+0x5a>
    iunlockput(ip);
    800052ca:	8526                	mv	a0,s1
    800052cc:	b2cfe0ef          	jal	ra,800035f8 <iunlockput>
    end_op();
    800052d0:	b71fe0ef          	jal	ra,80003e40 <end_op>
    return -1;
    800052d4:	557d                	li	a0,-1
    800052d6:	b7c5                	j	800052b6 <sys_chdir+0x5a>

00000000800052d8 <sys_exec>:

uint64
sys_exec(void)
{
    800052d8:	7145                	addi	sp,sp,-464
    800052da:	e786                	sd	ra,456(sp)
    800052dc:	e3a2                	sd	s0,448(sp)
    800052de:	ff26                	sd	s1,440(sp)
    800052e0:	fb4a                	sd	s2,432(sp)
    800052e2:	f74e                	sd	s3,424(sp)
    800052e4:	f352                	sd	s4,416(sp)
    800052e6:	ef56                	sd	s5,408(sp)
    800052e8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800052ea:	e3840593          	addi	a1,s0,-456
    800052ee:	4505                	li	a0,1
    800052f0:	f36fd0ef          	jal	ra,80002a26 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800052f4:	08000613          	li	a2,128
    800052f8:	f4040593          	addi	a1,s0,-192
    800052fc:	4501                	li	a0,0
    800052fe:	f44fd0ef          	jal	ra,80002a42 <argstr>
    80005302:	87aa                	mv	a5,a0
    return -1;
    80005304:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005306:	0a07c463          	bltz	a5,800053ae <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    8000530a:	10000613          	li	a2,256
    8000530e:	4581                	li	a1,0
    80005310:	e4040513          	addi	a0,s0,-448
    80005314:	a29fb0ef          	jal	ra,80000d3c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005318:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000531c:	89a6                	mv	s3,s1
    8000531e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005320:	02000a13          	li	s4,32
    80005324:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005328:	00391793          	slli	a5,s2,0x3
    8000532c:	e3040593          	addi	a1,s0,-464
    80005330:	e3843503          	ld	a0,-456(s0)
    80005334:	953e                	add	a0,a0,a5
    80005336:	e4afd0ef          	jal	ra,80002980 <fetchaddr>
    8000533a:	02054663          	bltz	a0,80005366 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    8000533e:	e3043783          	ld	a5,-464(s0)
    80005342:	cf8d                	beqz	a5,8000537c <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005344:	fbcfb0ef          	jal	ra,80000b00 <kalloc>
    80005348:	85aa                	mv	a1,a0
    8000534a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000534e:	cd01                	beqz	a0,80005366 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005350:	6605                	lui	a2,0x1
    80005352:	e3043503          	ld	a0,-464(s0)
    80005356:	e74fd0ef          	jal	ra,800029ca <fetchstr>
    8000535a:	00054663          	bltz	a0,80005366 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000535e:	0905                	addi	s2,s2,1
    80005360:	09a1                	addi	s3,s3,8
    80005362:	fd4911e3          	bne	s2,s4,80005324 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005366:	10048913          	addi	s2,s1,256
    8000536a:	6088                	ld	a0,0(s1)
    8000536c:	c121                	beqz	a0,800053ac <sys_exec+0xd4>
    kfree(argv[i]);
    8000536e:	e2efb0ef          	jal	ra,8000099c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005372:	04a1                	addi	s1,s1,8
    80005374:	ff249be3          	bne	s1,s2,8000536a <sys_exec+0x92>
  return -1;
    80005378:	557d                	li	a0,-1
    8000537a:	a815                	j	800053ae <sys_exec+0xd6>
      argv[i] = 0;
    8000537c:	0a8e                	slli	s5,s5,0x3
    8000537e:	fc040793          	addi	a5,s0,-64
    80005382:	9abe                	add	s5,s5,a5
    80005384:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);
    80005388:	e4040593          	addi	a1,s0,-448
    8000538c:	f4040513          	addi	a0,s0,-192
    80005390:	bfaff0ef          	jal	ra,8000478a <kexec>
    80005394:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005396:	10048993          	addi	s3,s1,256
    8000539a:	6088                	ld	a0,0(s1)
    8000539c:	c511                	beqz	a0,800053a8 <sys_exec+0xd0>
    kfree(argv[i]);
    8000539e:	dfefb0ef          	jal	ra,8000099c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800053a2:	04a1                	addi	s1,s1,8
    800053a4:	ff349be3          	bne	s1,s3,8000539a <sys_exec+0xc2>
  return ret;
    800053a8:	854a                	mv	a0,s2
    800053aa:	a011                	j	800053ae <sys_exec+0xd6>
  return -1;
    800053ac:	557d                	li	a0,-1
}
    800053ae:	60be                	ld	ra,456(sp)
    800053b0:	641e                	ld	s0,448(sp)
    800053b2:	74fa                	ld	s1,440(sp)
    800053b4:	795a                	ld	s2,432(sp)
    800053b6:	79ba                	ld	s3,424(sp)
    800053b8:	7a1a                	ld	s4,416(sp)
    800053ba:	6afa                	ld	s5,408(sp)
    800053bc:	6179                	addi	sp,sp,464
    800053be:	8082                	ret

00000000800053c0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800053c0:	7139                	addi	sp,sp,-64
    800053c2:	fc06                	sd	ra,56(sp)
    800053c4:	f822                	sd	s0,48(sp)
    800053c6:	f426                	sd	s1,40(sp)
    800053c8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800053ca:	d94fc0ef          	jal	ra,8000195e <myproc>
    800053ce:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800053d0:	fd840593          	addi	a1,s0,-40
    800053d4:	4501                	li	a0,0
    800053d6:	e50fd0ef          	jal	ra,80002a26 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800053da:	fc840593          	addi	a1,s0,-56
    800053de:	fd040513          	addi	a0,s0,-48
    800053e2:	8c8ff0ef          	jal	ra,800044aa <pipealloc>
    return -1;
    800053e6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800053e8:	0a054463          	bltz	a0,80005490 <sys_pipe+0xd0>
  fd0 = -1;
    800053ec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800053f0:	fd043503          	ld	a0,-48(s0)
    800053f4:	f42ff0ef          	jal	ra,80004b36 <fdalloc>
    800053f8:	fca42223          	sw	a0,-60(s0)
    800053fc:	08054163          	bltz	a0,8000547e <sys_pipe+0xbe>
    80005400:	fc843503          	ld	a0,-56(s0)
    80005404:	f32ff0ef          	jal	ra,80004b36 <fdalloc>
    80005408:	fca42023          	sw	a0,-64(s0)
    8000540c:	06054063          	bltz	a0,8000546c <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005410:	4691                	li	a3,4
    80005412:	fc440613          	addi	a2,s0,-60
    80005416:	fd843583          	ld	a1,-40(s0)
    8000541a:	68a8                	ld	a0,80(s1)
    8000541c:	a70fc0ef          	jal	ra,8000168c <copyout>
    80005420:	00054e63          	bltz	a0,8000543c <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005424:	4691                	li	a3,4
    80005426:	fc040613          	addi	a2,s0,-64
    8000542a:	fd843583          	ld	a1,-40(s0)
    8000542e:	0591                	addi	a1,a1,4
    80005430:	68a8                	ld	a0,80(s1)
    80005432:	a5afc0ef          	jal	ra,8000168c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005436:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005438:	04055c63          	bgez	a0,80005490 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000543c:	fc442783          	lw	a5,-60(s0)
    80005440:	07e9                	addi	a5,a5,26
    80005442:	078e                	slli	a5,a5,0x3
    80005444:	97a6                	add	a5,a5,s1
    80005446:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000544a:	fc042503          	lw	a0,-64(s0)
    8000544e:	0569                	addi	a0,a0,26
    80005450:	050e                	slli	a0,a0,0x3
    80005452:	94aa                	add	s1,s1,a0
    80005454:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005458:	fd043503          	ld	a0,-48(s0)
    8000545c:	d83fe0ef          	jal	ra,800041de <fileclose>
    fileclose(wf);
    80005460:	fc843503          	ld	a0,-56(s0)
    80005464:	d7bfe0ef          	jal	ra,800041de <fileclose>
    return -1;
    80005468:	57fd                	li	a5,-1
    8000546a:	a01d                	j	80005490 <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000546c:	fc442783          	lw	a5,-60(s0)
    80005470:	0007c763          	bltz	a5,8000547e <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005474:	07e9                	addi	a5,a5,26
    80005476:	078e                	slli	a5,a5,0x3
    80005478:	94be                	add	s1,s1,a5
    8000547a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000547e:	fd043503          	ld	a0,-48(s0)
    80005482:	d5dfe0ef          	jal	ra,800041de <fileclose>
    fileclose(wf);
    80005486:	fc843503          	ld	a0,-56(s0)
    8000548a:	d55fe0ef          	jal	ra,800041de <fileclose>
    return -1;
    8000548e:	57fd                	li	a5,-1
}
    80005490:	853e                	mv	a0,a5
    80005492:	70e2                	ld	ra,56(sp)
    80005494:	7442                	ld	s0,48(sp)
    80005496:	74a2                	ld	s1,40(sp)
    80005498:	6121                	addi	sp,sp,64
    8000549a:	8082                	ret
    8000549c:	0000                	unimp
	...

00000000800054a0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800054a0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800054a2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800054a4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800054a6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800054a8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800054aa:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800054ac:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800054ae:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800054b0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800054b2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800054b4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800054b6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800054b8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800054ba:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800054bc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800054be:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800054c0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800054c2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800054c4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800054c6:	bbcfd0ef          	jal	ra,80002882 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800054ca:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800054cc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800054ce:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800054d0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800054d2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800054d4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800054d6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800054d8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800054da:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800054dc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800054de:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800054e0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800054e2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800054e4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800054e6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800054e8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800054ea:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800054ec:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800054ee:	10200073          	sret
	...

00000000800054fe <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800054fe:	1141                	addi	sp,sp,-16
    80005500:	e422                	sd	s0,8(sp)
    80005502:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005504:	0c0007b7          	lui	a5,0xc000
    80005508:	4705                	li	a4,1
    8000550a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000550c:	c3d8                	sw	a4,4(a5)
}
    8000550e:	6422                	ld	s0,8(sp)
    80005510:	0141                	addi	sp,sp,16
    80005512:	8082                	ret

0000000080005514 <plicinithart>:

void
plicinithart(void)
{
    80005514:	1141                	addi	sp,sp,-16
    80005516:	e406                	sd	ra,8(sp)
    80005518:	e022                	sd	s0,0(sp)
    8000551a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000551c:	c16fc0ef          	jal	ra,80001932 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005520:	0085171b          	slliw	a4,a0,0x8
    80005524:	0c0027b7          	lui	a5,0xc002
    80005528:	97ba                	add	a5,a5,a4
    8000552a:	40200713          	li	a4,1026
    8000552e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005532:	00d5151b          	slliw	a0,a0,0xd
    80005536:	0c2017b7          	lui	a5,0xc201
    8000553a:	953e                	add	a0,a0,a5
    8000553c:	00052023          	sw	zero,0(a0)
}
    80005540:	60a2                	ld	ra,8(sp)
    80005542:	6402                	ld	s0,0(sp)
    80005544:	0141                	addi	sp,sp,16
    80005546:	8082                	ret

0000000080005548 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005548:	1141                	addi	sp,sp,-16
    8000554a:	e406                	sd	ra,8(sp)
    8000554c:	e022                	sd	s0,0(sp)
    8000554e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005550:	be2fc0ef          	jal	ra,80001932 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005554:	00d5179b          	slliw	a5,a0,0xd
    80005558:	0c201537          	lui	a0,0xc201
    8000555c:	953e                	add	a0,a0,a5
  return irq;
}
    8000555e:	4148                	lw	a0,4(a0)
    80005560:	60a2                	ld	ra,8(sp)
    80005562:	6402                	ld	s0,0(sp)
    80005564:	0141                	addi	sp,sp,16
    80005566:	8082                	ret

0000000080005568 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005568:	1101                	addi	sp,sp,-32
    8000556a:	ec06                	sd	ra,24(sp)
    8000556c:	e822                	sd	s0,16(sp)
    8000556e:	e426                	sd	s1,8(sp)
    80005570:	1000                	addi	s0,sp,32
    80005572:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005574:	bbefc0ef          	jal	ra,80001932 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005578:	00d5151b          	slliw	a0,a0,0xd
    8000557c:	0c2017b7          	lui	a5,0xc201
    80005580:	97aa                	add	a5,a5,a0
    80005582:	c3c4                	sw	s1,4(a5)
}
    80005584:	60e2                	ld	ra,24(sp)
    80005586:	6442                	ld	s0,16(sp)
    80005588:	64a2                	ld	s1,8(sp)
    8000558a:	6105                	addi	sp,sp,32
    8000558c:	8082                	ret

000000008000558e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000558e:	1141                	addi	sp,sp,-16
    80005590:	e406                	sd	ra,8(sp)
    80005592:	e022                	sd	s0,0(sp)
    80005594:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005596:	479d                	li	a5,7
    80005598:	04a7ca63          	blt	a5,a0,800055ec <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    8000559c:	0023c797          	auipc	a5,0x23c
    800055a0:	8fc78793          	addi	a5,a5,-1796 # 80240e98 <disk>
    800055a4:	97aa                	add	a5,a5,a0
    800055a6:	0187c783          	lbu	a5,24(a5)
    800055aa:	e7b9                	bnez	a5,800055f8 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800055ac:	00451613          	slli	a2,a0,0x4
    800055b0:	0023c797          	auipc	a5,0x23c
    800055b4:	8e878793          	addi	a5,a5,-1816 # 80240e98 <disk>
    800055b8:	6394                	ld	a3,0(a5)
    800055ba:	96b2                	add	a3,a3,a2
    800055bc:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800055c0:	6398                	ld	a4,0(a5)
    800055c2:	9732                	add	a4,a4,a2
    800055c4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800055c8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800055cc:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800055d0:	953e                	add	a0,a0,a5
    800055d2:	4785                	li	a5,1
    800055d4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800055d8:	0023c517          	auipc	a0,0x23c
    800055dc:	8d850513          	addi	a0,a0,-1832 # 80240eb0 <disk+0x18>
    800055e0:	941fc0ef          	jal	ra,80001f20 <wakeup>
}
    800055e4:	60a2                	ld	ra,8(sp)
    800055e6:	6402                	ld	s0,0(sp)
    800055e8:	0141                	addi	sp,sp,16
    800055ea:	8082                	ret
    panic("free_desc 1");
    800055ec:	00002517          	auipc	a0,0x2
    800055f0:	19450513          	addi	a0,a0,404 # 80007780 <syscalls+0x330>
    800055f4:	976fb0ef          	jal	ra,8000076a <panic>
    panic("free_desc 2");
    800055f8:	00002517          	auipc	a0,0x2
    800055fc:	19850513          	addi	a0,a0,408 # 80007790 <syscalls+0x340>
    80005600:	96afb0ef          	jal	ra,8000076a <panic>

0000000080005604 <virtio_disk_init>:
{
    80005604:	1101                	addi	sp,sp,-32
    80005606:	ec06                	sd	ra,24(sp)
    80005608:	e822                	sd	s0,16(sp)
    8000560a:	e426                	sd	s1,8(sp)
    8000560c:	e04a                	sd	s2,0(sp)
    8000560e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005610:	00002597          	auipc	a1,0x2
    80005614:	19058593          	addi	a1,a1,400 # 800077a0 <syscalls+0x350>
    80005618:	0023c517          	auipc	a0,0x23c
    8000561c:	9a850513          	addi	a0,a0,-1624 # 80240fc0 <disk+0x128>
    80005620:	dc8fb0ef          	jal	ra,80000be8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005624:	100017b7          	lui	a5,0x10001
    80005628:	4398                	lw	a4,0(a5)
    8000562a:	2701                	sext.w	a4,a4
    8000562c:	747277b7          	lui	a5,0x74727
    80005630:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005634:	14f71063          	bne	a4,a5,80005774 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005638:	100017b7          	lui	a5,0x10001
    8000563c:	43dc                	lw	a5,4(a5)
    8000563e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005640:	4709                	li	a4,2
    80005642:	12e79963          	bne	a5,a4,80005774 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005646:	100017b7          	lui	a5,0x10001
    8000564a:	479c                	lw	a5,8(a5)
    8000564c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000564e:	12e79363          	bne	a5,a4,80005774 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005652:	100017b7          	lui	a5,0x10001
    80005656:	47d8                	lw	a4,12(a5)
    80005658:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000565a:	554d47b7          	lui	a5,0x554d4
    8000565e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005662:	10f71963          	bne	a4,a5,80005774 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005666:	100017b7          	lui	a5,0x10001
    8000566a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000566e:	4705                	li	a4,1
    80005670:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005672:	470d                	li	a4,3
    80005674:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005676:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005678:	c7ffe737          	lui	a4,0xc7ffe
    8000567c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbd787>
    80005680:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005682:	2701                	sext.w	a4,a4
    80005684:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005686:	472d                	li	a4,11
    80005688:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000568a:	5bbc                	lw	a5,112(a5)
    8000568c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005690:	8ba1                	andi	a5,a5,8
    80005692:	0e078763          	beqz	a5,80005780 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005696:	100017b7          	lui	a5,0x10001
    8000569a:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000569e:	43fc                	lw	a5,68(a5)
    800056a0:	2781                	sext.w	a5,a5
    800056a2:	0e079563          	bnez	a5,8000578c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800056a6:	100017b7          	lui	a5,0x10001
    800056aa:	5bdc                	lw	a5,52(a5)
    800056ac:	2781                	sext.w	a5,a5
  if(max == 0)
    800056ae:	0e078563          	beqz	a5,80005798 <virtio_disk_init+0x194>
  if(max < NUM)
    800056b2:	471d                	li	a4,7
    800056b4:	0ef77863          	bgeu	a4,a5,800057a4 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    800056b8:	c48fb0ef          	jal	ra,80000b00 <kalloc>
    800056bc:	0023b497          	auipc	s1,0x23b
    800056c0:	7dc48493          	addi	s1,s1,2012 # 80240e98 <disk>
    800056c4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800056c6:	c3afb0ef          	jal	ra,80000b00 <kalloc>
    800056ca:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800056cc:	c34fb0ef          	jal	ra,80000b00 <kalloc>
    800056d0:	87aa                	mv	a5,a0
    800056d2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800056d4:	6088                	ld	a0,0(s1)
    800056d6:	cd69                	beqz	a0,800057b0 <virtio_disk_init+0x1ac>
    800056d8:	0023b717          	auipc	a4,0x23b
    800056dc:	7c873703          	ld	a4,1992(a4) # 80240ea0 <disk+0x8>
    800056e0:	cb61                	beqz	a4,800057b0 <virtio_disk_init+0x1ac>
    800056e2:	c7f9                	beqz	a5,800057b0 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800056e4:	6605                	lui	a2,0x1
    800056e6:	4581                	li	a1,0
    800056e8:	e54fb0ef          	jal	ra,80000d3c <memset>
  memset(disk.avail, 0, PGSIZE);
    800056ec:	0023b497          	auipc	s1,0x23b
    800056f0:	7ac48493          	addi	s1,s1,1964 # 80240e98 <disk>
    800056f4:	6605                	lui	a2,0x1
    800056f6:	4581                	li	a1,0
    800056f8:	6488                	ld	a0,8(s1)
    800056fa:	e42fb0ef          	jal	ra,80000d3c <memset>
  memset(disk.used, 0, PGSIZE);
    800056fe:	6605                	lui	a2,0x1
    80005700:	4581                	li	a1,0
    80005702:	6888                	ld	a0,16(s1)
    80005704:	e38fb0ef          	jal	ra,80000d3c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005708:	100017b7          	lui	a5,0x10001
    8000570c:	4721                	li	a4,8
    8000570e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005710:	4098                	lw	a4,0(s1)
    80005712:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005716:	40d8                	lw	a4,4(s1)
    80005718:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000571c:	6498                	ld	a4,8(s1)
    8000571e:	0007069b          	sext.w	a3,a4
    80005722:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005726:	9701                	srai	a4,a4,0x20
    80005728:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000572c:	6898                	ld	a4,16(s1)
    8000572e:	0007069b          	sext.w	a3,a4
    80005732:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005736:	9701                	srai	a4,a4,0x20
    80005738:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000573c:	4705                	li	a4,1
    8000573e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005740:	00e48c23          	sb	a4,24(s1)
    80005744:	00e48ca3          	sb	a4,25(s1)
    80005748:	00e48d23          	sb	a4,26(s1)
    8000574c:	00e48da3          	sb	a4,27(s1)
    80005750:	00e48e23          	sb	a4,28(s1)
    80005754:	00e48ea3          	sb	a4,29(s1)
    80005758:	00e48f23          	sb	a4,30(s1)
    8000575c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005760:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005764:	0727a823          	sw	s2,112(a5)
}
    80005768:	60e2                	ld	ra,24(sp)
    8000576a:	6442                	ld	s0,16(sp)
    8000576c:	64a2                	ld	s1,8(sp)
    8000576e:	6902                	ld	s2,0(sp)
    80005770:	6105                	addi	sp,sp,32
    80005772:	8082                	ret
    panic("could not find virtio disk");
    80005774:	00002517          	auipc	a0,0x2
    80005778:	03c50513          	addi	a0,a0,60 # 800077b0 <syscalls+0x360>
    8000577c:	feffa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005780:	00002517          	auipc	a0,0x2
    80005784:	05050513          	addi	a0,a0,80 # 800077d0 <syscalls+0x380>
    80005788:	fe3fa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk should not be ready");
    8000578c:	00002517          	auipc	a0,0x2
    80005790:	06450513          	addi	a0,a0,100 # 800077f0 <syscalls+0x3a0>
    80005794:	fd7fa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk has no queue 0");
    80005798:	00002517          	auipc	a0,0x2
    8000579c:	07850513          	addi	a0,a0,120 # 80007810 <syscalls+0x3c0>
    800057a0:	fcbfa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk max queue too short");
    800057a4:	00002517          	auipc	a0,0x2
    800057a8:	08c50513          	addi	a0,a0,140 # 80007830 <syscalls+0x3e0>
    800057ac:	fbffa0ef          	jal	ra,8000076a <panic>
    panic("virtio disk kalloc");
    800057b0:	00002517          	auipc	a0,0x2
    800057b4:	0a050513          	addi	a0,a0,160 # 80007850 <syscalls+0x400>
    800057b8:	fb3fa0ef          	jal	ra,8000076a <panic>

00000000800057bc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800057bc:	7119                	addi	sp,sp,-128
    800057be:	fc86                	sd	ra,120(sp)
    800057c0:	f8a2                	sd	s0,112(sp)
    800057c2:	f4a6                	sd	s1,104(sp)
    800057c4:	f0ca                	sd	s2,96(sp)
    800057c6:	ecce                	sd	s3,88(sp)
    800057c8:	e8d2                	sd	s4,80(sp)
    800057ca:	e4d6                	sd	s5,72(sp)
    800057cc:	e0da                	sd	s6,64(sp)
    800057ce:	fc5e                	sd	s7,56(sp)
    800057d0:	f862                	sd	s8,48(sp)
    800057d2:	f466                	sd	s9,40(sp)
    800057d4:	f06a                	sd	s10,32(sp)
    800057d6:	ec6e                	sd	s11,24(sp)
    800057d8:	0100                	addi	s0,sp,128
    800057da:	8aaa                	mv	s5,a0
    800057dc:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800057de:	00c52d03          	lw	s10,12(a0)
    800057e2:	001d1d1b          	slliw	s10,s10,0x1
    800057e6:	1d02                	slli	s10,s10,0x20
    800057e8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800057ec:	0023b517          	auipc	a0,0x23b
    800057f0:	7d450513          	addi	a0,a0,2004 # 80240fc0 <disk+0x128>
    800057f4:	c74fb0ef          	jal	ra,80000c68 <acquire>
  for(int i = 0; i < 3; i++){
    800057f8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800057fa:	44a1                	li	s1,8
      disk.free[i] = 0;
    800057fc:	0023bb97          	auipc	s7,0x23b
    80005800:	69cb8b93          	addi	s7,s7,1692 # 80240e98 <disk>
  for(int i = 0; i < 3; i++){
    80005804:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005806:	0023bc97          	auipc	s9,0x23b
    8000580a:	7bac8c93          	addi	s9,s9,1978 # 80240fc0 <disk+0x128>
    8000580e:	a8a9                	j	80005868 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005810:	00fb8733          	add	a4,s7,a5
    80005814:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005818:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000581a:	0207c563          	bltz	a5,80005844 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000581e:	2905                	addiw	s2,s2,1
    80005820:	0611                	addi	a2,a2,4
    80005822:	05690863          	beq	s2,s6,80005872 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005826:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005828:	0023b717          	auipc	a4,0x23b
    8000582c:	67070713          	addi	a4,a4,1648 # 80240e98 <disk>
    80005830:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005832:	01874683          	lbu	a3,24(a4)
    80005836:	fee9                	bnez	a3,80005810 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005838:	2785                	addiw	a5,a5,1
    8000583a:	0705                	addi	a4,a4,1
    8000583c:	fe979be3          	bne	a5,s1,80005832 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005840:	57fd                	li	a5,-1
    80005842:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005844:	01205b63          	blez	s2,8000585a <virtio_disk_rw+0x9e>
    80005848:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000584a:	000a2503          	lw	a0,0(s4)
    8000584e:	d41ff0ef          	jal	ra,8000558e <free_desc>
      for(int j = 0; j < i; j++)
    80005852:	2d85                	addiw	s11,s11,1
    80005854:	0a11                	addi	s4,s4,4
    80005856:	ffb91ae3          	bne	s2,s11,8000584a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000585a:	85e6                	mv	a1,s9
    8000585c:	0023b517          	auipc	a0,0x23b
    80005860:	65450513          	addi	a0,a0,1620 # 80240eb0 <disk+0x18>
    80005864:	e70fc0ef          	jal	ra,80001ed4 <sleep>
  for(int i = 0; i < 3; i++){
    80005868:	f8040a13          	addi	s4,s0,-128
{
    8000586c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000586e:	894e                	mv	s2,s3
    80005870:	bf5d                	j	80005826 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005872:	f8042583          	lw	a1,-128(s0)
    80005876:	00a58793          	addi	a5,a1,10
    8000587a:	0792                	slli	a5,a5,0x4

  if(write)
    8000587c:	0023b617          	auipc	a2,0x23b
    80005880:	61c60613          	addi	a2,a2,1564 # 80240e98 <disk>
    80005884:	00f60733          	add	a4,a2,a5
    80005888:	018036b3          	snez	a3,s8
    8000588c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000588e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005892:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005896:	f6078693          	addi	a3,a5,-160
    8000589a:	6218                	ld	a4,0(a2)
    8000589c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000589e:	00878513          	addi	a0,a5,8
    800058a2:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800058a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800058a6:	6208                	ld	a0,0(a2)
    800058a8:	96aa                	add	a3,a3,a0
    800058aa:	4741                	li	a4,16
    800058ac:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800058ae:	4705                	li	a4,1
    800058b0:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800058b4:	f8442703          	lw	a4,-124(s0)
    800058b8:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800058bc:	0712                	slli	a4,a4,0x4
    800058be:	953a                	add	a0,a0,a4
    800058c0:	058a8693          	addi	a3,s5,88
    800058c4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800058c6:	6208                	ld	a0,0(a2)
    800058c8:	972a                	add	a4,a4,a0
    800058ca:	40000693          	li	a3,1024
    800058ce:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800058d0:	001c3c13          	seqz	s8,s8
    800058d4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800058d6:	001c6c13          	ori	s8,s8,1
    800058da:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800058de:	f8842603          	lw	a2,-120(s0)
    800058e2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800058e6:	0023b697          	auipc	a3,0x23b
    800058ea:	5b268693          	addi	a3,a3,1458 # 80240e98 <disk>
    800058ee:	00258713          	addi	a4,a1,2
    800058f2:	0712                	slli	a4,a4,0x4
    800058f4:	9736                	add	a4,a4,a3
    800058f6:	587d                	li	a6,-1
    800058f8:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800058fc:	0612                	slli	a2,a2,0x4
    800058fe:	9532                	add	a0,a0,a2
    80005900:	f9078793          	addi	a5,a5,-112
    80005904:	97b6                	add	a5,a5,a3
    80005906:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005908:	629c                	ld	a5,0(a3)
    8000590a:	97b2                	add	a5,a5,a2
    8000590c:	4605                	li	a2,1
    8000590e:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005910:	4509                	li	a0,2
    80005912:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80005916:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000591a:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000591e:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005922:	6698                	ld	a4,8(a3)
    80005924:	00275783          	lhu	a5,2(a4)
    80005928:	8b9d                	andi	a5,a5,7
    8000592a:	0786                	slli	a5,a5,0x1
    8000592c:	97ba                	add	a5,a5,a4
    8000592e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005932:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005936:	6698                	ld	a4,8(a3)
    80005938:	00275783          	lhu	a5,2(a4)
    8000593c:	2785                	addiw	a5,a5,1
    8000593e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005942:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005946:	100017b7          	lui	a5,0x10001
    8000594a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000594e:	004aa783          	lw	a5,4(s5)
    80005952:	00c79f63          	bne	a5,a2,80005970 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005956:	0023b917          	auipc	s2,0x23b
    8000595a:	66a90913          	addi	s2,s2,1642 # 80240fc0 <disk+0x128>
  while(b->disk == 1) {
    8000595e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005960:	85ca                	mv	a1,s2
    80005962:	8556                	mv	a0,s5
    80005964:	d70fc0ef          	jal	ra,80001ed4 <sleep>
  while(b->disk == 1) {
    80005968:	004aa783          	lw	a5,4(s5)
    8000596c:	fe978ae3          	beq	a5,s1,80005960 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005970:	f8042903          	lw	s2,-128(s0)
    80005974:	00290793          	addi	a5,s2,2
    80005978:	00479713          	slli	a4,a5,0x4
    8000597c:	0023b797          	auipc	a5,0x23b
    80005980:	51c78793          	addi	a5,a5,1308 # 80240e98 <disk>
    80005984:	97ba                	add	a5,a5,a4
    80005986:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000598a:	0023b997          	auipc	s3,0x23b
    8000598e:	50e98993          	addi	s3,s3,1294 # 80240e98 <disk>
    80005992:	00491713          	slli	a4,s2,0x4
    80005996:	0009b783          	ld	a5,0(s3)
    8000599a:	97ba                	add	a5,a5,a4
    8000599c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800059a0:	854a                	mv	a0,s2
    800059a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800059a6:	be9ff0ef          	jal	ra,8000558e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800059aa:	8885                	andi	s1,s1,1
    800059ac:	f0fd                	bnez	s1,80005992 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800059ae:	0023b517          	auipc	a0,0x23b
    800059b2:	61250513          	addi	a0,a0,1554 # 80240fc0 <disk+0x128>
    800059b6:	b4afb0ef          	jal	ra,80000d00 <release>
}
    800059ba:	70e6                	ld	ra,120(sp)
    800059bc:	7446                	ld	s0,112(sp)
    800059be:	74a6                	ld	s1,104(sp)
    800059c0:	7906                	ld	s2,96(sp)
    800059c2:	69e6                	ld	s3,88(sp)
    800059c4:	6a46                	ld	s4,80(sp)
    800059c6:	6aa6                	ld	s5,72(sp)
    800059c8:	6b06                	ld	s6,64(sp)
    800059ca:	7be2                	ld	s7,56(sp)
    800059cc:	7c42                	ld	s8,48(sp)
    800059ce:	7ca2                	ld	s9,40(sp)
    800059d0:	7d02                	ld	s10,32(sp)
    800059d2:	6de2                	ld	s11,24(sp)
    800059d4:	6109                	addi	sp,sp,128
    800059d6:	8082                	ret

00000000800059d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800059d8:	1101                	addi	sp,sp,-32
    800059da:	ec06                	sd	ra,24(sp)
    800059dc:	e822                	sd	s0,16(sp)
    800059de:	e426                	sd	s1,8(sp)
    800059e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800059e2:	0023b497          	auipc	s1,0x23b
    800059e6:	4b648493          	addi	s1,s1,1206 # 80240e98 <disk>
    800059ea:	0023b517          	auipc	a0,0x23b
    800059ee:	5d650513          	addi	a0,a0,1494 # 80240fc0 <disk+0x128>
    800059f2:	a76fb0ef          	jal	ra,80000c68 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800059f6:	10001737          	lui	a4,0x10001
    800059fa:	533c                	lw	a5,96(a4)
    800059fc:	8b8d                	andi	a5,a5,3
    800059fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005a00:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005a04:	689c                	ld	a5,16(s1)
    80005a06:	0204d703          	lhu	a4,32(s1)
    80005a0a:	0027d783          	lhu	a5,2(a5)
    80005a0e:	04f70663          	beq	a4,a5,80005a5a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005a12:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005a16:	6898                	ld	a4,16(s1)
    80005a18:	0204d783          	lhu	a5,32(s1)
    80005a1c:	8b9d                	andi	a5,a5,7
    80005a1e:	078e                	slli	a5,a5,0x3
    80005a20:	97ba                	add	a5,a5,a4
    80005a22:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005a24:	00278713          	addi	a4,a5,2
    80005a28:	0712                	slli	a4,a4,0x4
    80005a2a:	9726                	add	a4,a4,s1
    80005a2c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005a30:	e321                	bnez	a4,80005a70 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a32:	0789                	addi	a5,a5,2
    80005a34:	0792                	slli	a5,a5,0x4
    80005a36:	97a6                	add	a5,a5,s1
    80005a38:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a3a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a3e:	ce2fc0ef          	jal	ra,80001f20 <wakeup>

    disk.used_idx += 1;
    80005a42:	0204d783          	lhu	a5,32(s1)
    80005a46:	2785                	addiw	a5,a5,1
    80005a48:	17c2                	slli	a5,a5,0x30
    80005a4a:	93c1                	srli	a5,a5,0x30
    80005a4c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005a50:	6898                	ld	a4,16(s1)
    80005a52:	00275703          	lhu	a4,2(a4)
    80005a56:	faf71ee3          	bne	a4,a5,80005a12 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005a5a:	0023b517          	auipc	a0,0x23b
    80005a5e:	56650513          	addi	a0,a0,1382 # 80240fc0 <disk+0x128>
    80005a62:	a9efb0ef          	jal	ra,80000d00 <release>
}
    80005a66:	60e2                	ld	ra,24(sp)
    80005a68:	6442                	ld	s0,16(sp)
    80005a6a:	64a2                	ld	s1,8(sp)
    80005a6c:	6105                	addi	sp,sp,32
    80005a6e:	8082                	ret
      panic("virtio_disk_intr status");
    80005a70:	00002517          	auipc	a0,0x2
    80005a74:	df850513          	addi	a0,a0,-520 # 80007868 <syscalls+0x418>
    80005a78:	cf3fa0ef          	jal	ra,8000076a <panic>
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
