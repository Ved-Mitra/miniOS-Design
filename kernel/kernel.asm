
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
    80000004:	93010113          	addi	sp,sp,-1744 # 80007930 <stack0>
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
    80000016:	04a000ef          	jal	ra,80000060 <start>

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
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	0x14d,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff53207>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	ec878793          	addi	a5,a5,-312 # 80000f48 <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7159                	addi	sp,sp,-112
    800000d2:	f486                	sd	ra,104(sp)
    800000d4:	f0a2                	sd	s0,96(sp)
    800000d6:	eca6                	sd	s1,88(sp)
    800000d8:	e8ca                	sd	s2,80(sp)
    800000da:	e4ce                	sd	s3,72(sp)
    800000dc:	e0d2                	sd	s4,64(sp)
    800000de:	fc56                	sd	s5,56(sp)
    800000e0:	f85a                	sd	s6,48(sp)
    800000e2:	f45e                	sd	s7,40(sp)
    800000e4:	f062                	sd	s8,32(sp)
    800000e6:	1880                	addi	s0,sp,112
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000e8:	04c05463          	blez	a2,80000130 <consolewrite+0x60>
    800000ec:	8a2a                	mv	s4,a0
    800000ee:	8aae                	mv	s5,a1
    800000f0:	89b2                	mv	s3,a2
  int i = 0;
    800000f2:	4901                	li	s2,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f4:	4bfd                	li	s7,31
    int nn = sizeof(buf);
    800000f6:	02000c13          	li	s8,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fa:	5b7d                	li	s6,-1
    800000fc:	a025                	j	80000124 <consolewrite+0x54>
    800000fe:	86a6                	mv	a3,s1
    80000100:	01590633          	add	a2,s2,s5
    80000104:	85d2                	mv	a1,s4
    80000106:	f9040513          	addi	a0,s0,-112
    8000010a:	420020ef          	jal	ra,8000252a <either_copyin>
    8000010e:	03650263          	beq	a0,s6,80000132 <consolewrite+0x62>
      break;
    uartwrite(buf, nn);
    80000112:	85a6                	mv	a1,s1
    80000114:	f9040513          	addi	a0,s0,-112
    80000118:	71e000ef          	jal	ra,80000836 <uartwrite>
    i += nn;
    8000011c:	0124893b          	addw	s2,s1,s2
  while(i < n){
    80000120:	01395963          	bge	s2,s3,80000132 <consolewrite+0x62>
    if(nn > n - i)
    80000124:	412984bb          	subw	s1,s3,s2
    80000128:	fc9bdbe3          	bge	s7,s1,800000fe <consolewrite+0x2e>
    int nn = sizeof(buf);
    8000012c:	84e2                	mv	s1,s8
    8000012e:	bfc1                	j	800000fe <consolewrite+0x2e>
  int i = 0;
    80000130:	4901                	li	s2,0
  }

  return i;
}
    80000132:	854a                	mv	a0,s2
    80000134:	70a6                	ld	ra,104(sp)
    80000136:	7406                	ld	s0,96(sp)
    80000138:	64e6                	ld	s1,88(sp)
    8000013a:	6946                	ld	s2,80(sp)
    8000013c:	69a6                	ld	s3,72(sp)
    8000013e:	6a06                	ld	s4,64(sp)
    80000140:	7ae2                	ld	s5,56(sp)
    80000142:	7b42                	ld	s6,48(sp)
    80000144:	7ba2                	ld	s7,40(sp)
    80000146:	7c02                	ld	s8,32(sp)
    80000148:	6165                	addi	sp,sp,112
    8000014a:	8082                	ret

000000008000014c <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000014c:	7159                	addi	sp,sp,-112
    8000014e:	f486                	sd	ra,104(sp)
    80000150:	f0a2                	sd	s0,96(sp)
    80000152:	eca6                	sd	s1,88(sp)
    80000154:	e8ca                	sd	s2,80(sp)
    80000156:	e4ce                	sd	s3,72(sp)
    80000158:	e0d2                	sd	s4,64(sp)
    8000015a:	fc56                	sd	s5,56(sp)
    8000015c:	f85a                	sd	s6,48(sp)
    8000015e:	f45e                	sd	s7,40(sp)
    80000160:	f062                	sd	s8,32(sp)
    80000162:	ec66                	sd	s9,24(sp)
    80000164:	e86a                	sd	s10,16(sp)
    80000166:	1880                	addi	s0,sp,112
    80000168:	8aaa                	mv	s5,a0
    8000016a:	8a2e                	mv	s4,a1
    8000016c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000016e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000172:	0000f517          	auipc	a0,0xf
    80000176:	7be50513          	addi	a0,a0,1982 # 8000f930 <cons>
    8000017a:	359000ef          	jal	ra,80000cd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000017e:	0000f497          	auipc	s1,0xf
    80000182:	7b248493          	addi	s1,s1,1970 # 8000f930 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000186:	00010917          	auipc	s2,0x10
    8000018a:	84290913          	addi	s2,s2,-1982 # 8000f9c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    8000018e:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000190:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    80000192:	4ca9                	li	s9,10
  while(n > 0){
    80000194:	07305363          	blez	s3,800001fa <consoleread+0xae>
    while(cons.r == cons.w){
    80000198:	0984a783          	lw	a5,152(s1)
    8000019c:	09c4a703          	lw	a4,156(s1)
    800001a0:	02f71163          	bne	a4,a5,800001c2 <consoleread+0x76>
      if(killed(myproc())){
    800001a4:	097010ef          	jal	ra,80001a3a <myproc>
    800001a8:	214020ef          	jal	ra,800023bc <killed>
    800001ac:	e125                	bnez	a0,8000020c <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    800001ae:	85a6                	mv	a1,s1
    800001b0:	854a                	mv	a0,s2
    800001b2:	7d3010ef          	jal	ra,80002184 <sleep>
    while(cons.r == cons.w){
    800001b6:	0984a783          	lw	a5,152(s1)
    800001ba:	09c4a703          	lw	a4,156(s1)
    800001be:	fef703e3          	beq	a4,a5,800001a4 <consoleread+0x58>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001c2:	0017871b          	addiw	a4,a5,1
    800001c6:	08e4ac23          	sw	a4,152(s1)
    800001ca:	07f7f713          	andi	a4,a5,127
    800001ce:	9726                	add	a4,a4,s1
    800001d0:	01874703          	lbu	a4,24(a4)
    800001d4:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001d8:	057d0f63          	beq	s10,s7,80000236 <consoleread+0xea>
    cbuf = c;
    800001dc:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001e0:	4685                	li	a3,1
    800001e2:	f9f40613          	addi	a2,s0,-97
    800001e6:	85d2                	mv	a1,s4
    800001e8:	8556                	mv	a0,s5
    800001ea:	2f6020ef          	jal	ra,800024e0 <either_copyout>
    800001ee:	01850663          	beq	a0,s8,800001fa <consoleread+0xae>
    dst++;
    800001f2:	0a05                	addi	s4,s4,1
    --n;
    800001f4:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    800001f6:	f99d1fe3          	bne	s10,s9,80000194 <consoleread+0x48>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001fa:	0000f517          	auipc	a0,0xf
    800001fe:	73650513          	addi	a0,a0,1846 # 8000f930 <cons>
    80000202:	369000ef          	jal	ra,80000d6a <release>

  return target - n;
    80000206:	413b053b          	subw	a0,s6,s3
    8000020a:	a801                	j	8000021a <consoleread+0xce>
        release(&cons.lock);
    8000020c:	0000f517          	auipc	a0,0xf
    80000210:	72450513          	addi	a0,a0,1828 # 8000f930 <cons>
    80000214:	357000ef          	jal	ra,80000d6a <release>
        return -1;
    80000218:	557d                	li	a0,-1
}
    8000021a:	70a6                	ld	ra,104(sp)
    8000021c:	7406                	ld	s0,96(sp)
    8000021e:	64e6                	ld	s1,88(sp)
    80000220:	6946                	ld	s2,80(sp)
    80000222:	69a6                	ld	s3,72(sp)
    80000224:	6a06                	ld	s4,64(sp)
    80000226:	7ae2                	ld	s5,56(sp)
    80000228:	7b42                	ld	s6,48(sp)
    8000022a:	7ba2                	ld	s7,40(sp)
    8000022c:	7c02                	ld	s8,32(sp)
    8000022e:	6ce2                	ld	s9,24(sp)
    80000230:	6d42                	ld	s10,16(sp)
    80000232:	6165                	addi	sp,sp,112
    80000234:	8082                	ret
      if(n < target){
    80000236:	0009871b          	sext.w	a4,s3
    8000023a:	fd6770e3          	bgeu	a4,s6,800001fa <consoleread+0xae>
        cons.r--;
    8000023e:	0000f717          	auipc	a4,0xf
    80000242:	78f72523          	sw	a5,1930(a4) # 8000f9c8 <cons+0x98>
    80000246:	bf55                	j	800001fa <consoleread+0xae>

0000000080000248 <consputc>:
{
    80000248:	1141                	addi	sp,sp,-16
    8000024a:	e406                	sd	ra,8(sp)
    8000024c:	e022                	sd	s0,0(sp)
    8000024e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000250:	10000793          	li	a5,256
    80000254:	00f50863          	beq	a0,a5,80000264 <consputc+0x1c>
    uartputc_sync(c);
    80000258:	67c000ef          	jal	ra,800008d4 <uartputc_sync>
}
    8000025c:	60a2                	ld	ra,8(sp)
    8000025e:	6402                	ld	s0,0(sp)
    80000260:	0141                	addi	sp,sp,16
    80000262:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000264:	4521                	li	a0,8
    80000266:	66e000ef          	jal	ra,800008d4 <uartputc_sync>
    8000026a:	02000513          	li	a0,32
    8000026e:	666000ef          	jal	ra,800008d4 <uartputc_sync>
    80000272:	4521                	li	a0,8
    80000274:	660000ef          	jal	ra,800008d4 <uartputc_sync>
    80000278:	b7d5                	j	8000025c <consputc+0x14>

000000008000027a <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    8000027a:	1101                	addi	sp,sp,-32
    8000027c:	ec06                	sd	ra,24(sp)
    8000027e:	e822                	sd	s0,16(sp)
    80000280:	e426                	sd	s1,8(sp)
    80000282:	e04a                	sd	s2,0(sp)
    80000284:	1000                	addi	s0,sp,32
    80000286:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000288:	0000f517          	auipc	a0,0xf
    8000028c:	6a850513          	addi	a0,a0,1704 # 8000f930 <cons>
    80000290:	243000ef          	jal	ra,80000cd2 <acquire>

  switch(c){
    80000294:	47d5                	li	a5,21
    80000296:	0af48063          	beq	s1,a5,80000336 <consoleintr+0xbc>
    8000029a:	0297c663          	blt	a5,s1,800002c6 <consoleintr+0x4c>
    8000029e:	47a1                	li	a5,8
    800002a0:	0cf48f63          	beq	s1,a5,8000037e <consoleintr+0x104>
    800002a4:	47c1                	li	a5,16
    800002a6:	10f49063          	bne	s1,a5,800003a6 <consoleintr+0x12c>
  case C('P'):  // Print process list.
    procdump();
    800002aa:	2ca020ef          	jal	ra,80002574 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ae:	0000f517          	auipc	a0,0xf
    800002b2:	68250513          	addi	a0,a0,1666 # 8000f930 <cons>
    800002b6:	2b5000ef          	jal	ra,80000d6a <release>
}
    800002ba:	60e2                	ld	ra,24(sp)
    800002bc:	6442                	ld	s0,16(sp)
    800002be:	64a2                	ld	s1,8(sp)
    800002c0:	6902                	ld	s2,0(sp)
    800002c2:	6105                	addi	sp,sp,32
    800002c4:	8082                	ret
  switch(c){
    800002c6:	07f00793          	li	a5,127
    800002ca:	0af48a63          	beq	s1,a5,8000037e <consoleintr+0x104>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002ce:	0000f717          	auipc	a4,0xf
    800002d2:	66270713          	addi	a4,a4,1634 # 8000f930 <cons>
    800002d6:	0a072783          	lw	a5,160(a4)
    800002da:	09872703          	lw	a4,152(a4)
    800002de:	9f99                	subw	a5,a5,a4
    800002e0:	07f00713          	li	a4,127
    800002e4:	fcf765e3          	bltu	a4,a5,800002ae <consoleintr+0x34>
      c = (c == '\r') ? '\n' : c;
    800002e8:	47b5                	li	a5,13
    800002ea:	0cf48163          	beq	s1,a5,800003ac <consoleintr+0x132>
      consputc(c);
    800002ee:	8526                	mv	a0,s1
    800002f0:	f59ff0ef          	jal	ra,80000248 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800002f4:	0000f797          	auipc	a5,0xf
    800002f8:	63c78793          	addi	a5,a5,1596 # 8000f930 <cons>
    800002fc:	0a07a683          	lw	a3,160(a5)
    80000300:	0016871b          	addiw	a4,a3,1
    80000304:	0007061b          	sext.w	a2,a4
    80000308:	0ae7a023          	sw	a4,160(a5)
    8000030c:	07f6f693          	andi	a3,a3,127
    80000310:	97b6                	add	a5,a5,a3
    80000312:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000316:	47a9                	li	a5,10
    80000318:	0af48f63          	beq	s1,a5,800003d6 <consoleintr+0x15c>
    8000031c:	4791                	li	a5,4
    8000031e:	0af48c63          	beq	s1,a5,800003d6 <consoleintr+0x15c>
    80000322:	0000f797          	auipc	a5,0xf
    80000326:	6a67a783          	lw	a5,1702(a5) # 8000f9c8 <cons+0x98>
    8000032a:	9f1d                	subw	a4,a4,a5
    8000032c:	08000793          	li	a5,128
    80000330:	f6f71fe3          	bne	a4,a5,800002ae <consoleintr+0x34>
    80000334:	a04d                	j	800003d6 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000336:	0000f717          	auipc	a4,0xf
    8000033a:	5fa70713          	addi	a4,a4,1530 # 8000f930 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000346:	0000f497          	auipc	s1,0xf
    8000034a:	5ea48493          	addi	s1,s1,1514 # 8000f930 <cons>
    while(cons.e != cons.w &&
    8000034e:	4929                	li	s2,10
    80000350:	f4f70fe3          	beq	a4,a5,800002ae <consoleintr+0x34>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000354:	37fd                	addiw	a5,a5,-1
    80000356:	07f7f713          	andi	a4,a5,127
    8000035a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000035c:	01874703          	lbu	a4,24(a4)
    80000360:	f52707e3          	beq	a4,s2,800002ae <consoleintr+0x34>
      cons.e--;
    80000364:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000368:	10000513          	li	a0,256
    8000036c:	eddff0ef          	jal	ra,80000248 <consputc>
    while(cons.e != cons.w &&
    80000370:	0a04a783          	lw	a5,160(s1)
    80000374:	09c4a703          	lw	a4,156(s1)
    80000378:	fcf71ee3          	bne	a4,a5,80000354 <consoleintr+0xda>
    8000037c:	bf0d                	j	800002ae <consoleintr+0x34>
    if(cons.e != cons.w){
    8000037e:	0000f717          	auipc	a4,0xf
    80000382:	5b270713          	addi	a4,a4,1458 # 8000f930 <cons>
    80000386:	0a072783          	lw	a5,160(a4)
    8000038a:	09c72703          	lw	a4,156(a4)
    8000038e:	f2f700e3          	beq	a4,a5,800002ae <consoleintr+0x34>
      cons.e--;
    80000392:	37fd                	addiw	a5,a5,-1
    80000394:	0000f717          	auipc	a4,0xf
    80000398:	62f72e23          	sw	a5,1596(a4) # 8000f9d0 <cons+0xa0>
      consputc(BACKSPACE);
    8000039c:	10000513          	li	a0,256
    800003a0:	ea9ff0ef          	jal	ra,80000248 <consputc>
    800003a4:	b729                	j	800002ae <consoleintr+0x34>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003a6:	f00484e3          	beqz	s1,800002ae <consoleintr+0x34>
    800003aa:	b715                	j	800002ce <consoleintr+0x54>
      consputc(c);
    800003ac:	4529                	li	a0,10
    800003ae:	e9bff0ef          	jal	ra,80000248 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003b2:	0000f797          	auipc	a5,0xf
    800003b6:	57e78793          	addi	a5,a5,1406 # 8000f930 <cons>
    800003ba:	0a07a703          	lw	a4,160(a5)
    800003be:	0017069b          	addiw	a3,a4,1
    800003c2:	0006861b          	sext.w	a2,a3
    800003c6:	0ad7a023          	sw	a3,160(a5)
    800003ca:	07f77713          	andi	a4,a4,127
    800003ce:	97ba                	add	a5,a5,a4
    800003d0:	4729                	li	a4,10
    800003d2:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    800003d6:	0000f797          	auipc	a5,0xf
    800003da:	5ec7ab23          	sw	a2,1526(a5) # 8000f9cc <cons+0x9c>
        wakeup(&cons.r);
    800003de:	0000f517          	auipc	a0,0xf
    800003e2:	5ea50513          	addi	a0,a0,1514 # 8000f9c8 <cons+0x98>
    800003e6:	5eb010ef          	jal	ra,800021d0 <wakeup>
    800003ea:	b5d1                	j	800002ae <consoleintr+0x34>

00000000800003ec <consoleinit>:

void
consoleinit(void)
{
    800003ec:	1141                	addi	sp,sp,-16
    800003ee:	e406                	sd	ra,8(sp)
    800003f0:	e022                	sd	s0,0(sp)
    800003f2:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    800003f4:	00007597          	auipc	a1,0x7
    800003f8:	c1c58593          	addi	a1,a1,-996 # 80007010 <etext+0x10>
    800003fc:	0000f517          	auipc	a0,0xf
    80000400:	53450513          	addi	a0,a0,1332 # 8000f930 <cons>
    80000404:	04f000ef          	jal	ra,80000c52 <initlock>

  uartinit();
    80000408:	3e2000ef          	jal	ra,800007ea <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000040c:	000aa797          	auipc	a5,0xaa
    80000410:	05478793          	addi	a5,a5,84 # 800aa460 <devsw>
    80000414:	00000717          	auipc	a4,0x0
    80000418:	d3870713          	addi	a4,a4,-712 # 8000014c <consoleread>
    8000041c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000041e:	00000717          	auipc	a4,0x0
    80000422:	cb270713          	addi	a4,a4,-846 # 800000d0 <consolewrite>
    80000426:	ef98                	sd	a4,24(a5)
}
    80000428:	60a2                	ld	ra,8(sp)
    8000042a:	6402                	ld	s0,0(sp)
    8000042c:	0141                	addi	sp,sp,16
    8000042e:	8082                	ret

0000000080000430 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000430:	7139                	addi	sp,sp,-64
    80000432:	fc06                	sd	ra,56(sp)
    80000434:	f822                	sd	s0,48(sp)
    80000436:	f426                	sd	s1,40(sp)
    80000438:	f04a                	sd	s2,32(sp)
    8000043a:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    8000043c:	c219                	beqz	a2,80000442 <printint+0x12>
    8000043e:	06054f63          	bltz	a0,800004bc <printint+0x8c>
    x = -xx;
  else
    x = xx;
    80000442:	4881                	li	a7,0
    80000444:	fc840693          	addi	a3,s0,-56

  i = 0;
    80000448:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000044a:	00007617          	auipc	a2,0x7
    8000044e:	bee60613          	addi	a2,a2,-1042 # 80007038 <digits>
    80000452:	883e                	mv	a6,a5
    80000454:	2785                	addiw	a5,a5,1
    80000456:	02b57733          	remu	a4,a0,a1
    8000045a:	9732                	add	a4,a4,a2
    8000045c:	00074703          	lbu	a4,0(a4)
    80000460:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000464:	872a                	mv	a4,a0
    80000466:	02b55533          	divu	a0,a0,a1
    8000046a:	0685                	addi	a3,a3,1
    8000046c:	feb773e3          	bgeu	a4,a1,80000452 <printint+0x22>

  if(sign)
    80000470:	00088b63          	beqz	a7,80000486 <printint+0x56>
    buf[i++] = '-';
    80000474:	fe040713          	addi	a4,s0,-32
    80000478:	97ba                	add	a5,a5,a4
    8000047a:	02d00713          	li	a4,45
    8000047e:	fee78423          	sb	a4,-24(a5)
    80000482:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    80000486:	02f05563          	blez	a5,800004b0 <printint+0x80>
    8000048a:	fc840713          	addi	a4,s0,-56
    8000048e:	00f704b3          	add	s1,a4,a5
    80000492:	fff70913          	addi	s2,a4,-1
    80000496:	993e                	add	s2,s2,a5
    80000498:	37fd                	addiw	a5,a5,-1
    8000049a:	1782                	slli	a5,a5,0x20
    8000049c:	9381                	srli	a5,a5,0x20
    8000049e:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004a2:	fff4c503          	lbu	a0,-1(s1)
    800004a6:	da3ff0ef          	jal	ra,80000248 <consputc>
  while(--i >= 0)
    800004aa:	14fd                	addi	s1,s1,-1
    800004ac:	ff249be3          	bne	s1,s2,800004a2 <printint+0x72>
}
    800004b0:	70e2                	ld	ra,56(sp)
    800004b2:	7442                	ld	s0,48(sp)
    800004b4:	74a2                	ld	s1,40(sp)
    800004b6:	7902                	ld	s2,32(sp)
    800004b8:	6121                	addi	sp,sp,64
    800004ba:	8082                	ret
    x = -xx;
    800004bc:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004c0:	4885                	li	a7,1
    x = -xx;
    800004c2:	b749                	j	80000444 <printint+0x14>

00000000800004c4 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004c4:	7131                	addi	sp,sp,-192
    800004c6:	fc86                	sd	ra,120(sp)
    800004c8:	f8a2                	sd	s0,112(sp)
    800004ca:	f4a6                	sd	s1,104(sp)
    800004cc:	f0ca                	sd	s2,96(sp)
    800004ce:	ecce                	sd	s3,88(sp)
    800004d0:	e8d2                	sd	s4,80(sp)
    800004d2:	e4d6                	sd	s5,72(sp)
    800004d4:	e0da                	sd	s6,64(sp)
    800004d6:	fc5e                	sd	s7,56(sp)
    800004d8:	f862                	sd	s8,48(sp)
    800004da:	f466                	sd	s9,40(sp)
    800004dc:	f06a                	sd	s10,32(sp)
    800004de:	ec6e                	sd	s11,24(sp)
    800004e0:	0100                	addi	s0,sp,128
    800004e2:	8a2a                	mv	s4,a0
    800004e4:	e40c                	sd	a1,8(s0)
    800004e6:	e810                	sd	a2,16(s0)
    800004e8:	ec14                	sd	a3,24(s0)
    800004ea:	f018                	sd	a4,32(s0)
    800004ec:	f41c                	sd	a5,40(s0)
    800004ee:	03043823          	sd	a6,48(s0)
    800004f2:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    800004f6:	00007797          	auipc	a5,0x7
    800004fa:	3fe7a783          	lw	a5,1022(a5) # 800078f4 <panicking>
    800004fe:	cb9d                	beqz	a5,80000534 <printf+0x70>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000500:	00840793          	addi	a5,s0,8
    80000504:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000508:	000a4503          	lbu	a0,0(s4)
    8000050c:	24050363          	beqz	a0,80000752 <printf+0x28e>
    80000510:	4981                	li	s3,0
    if(cx != '%'){
    80000512:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    80000516:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000051a:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    8000051e:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000522:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    80000526:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000052a:	00007b97          	auipc	s7,0x7
    8000052e:	b0eb8b93          	addi	s7,s7,-1266 # 80007038 <digits>
    80000532:	a01d                	j	80000558 <printf+0x94>
    acquire(&pr.lock);
    80000534:	0000f517          	auipc	a0,0xf
    80000538:	4a450513          	addi	a0,a0,1188 # 8000f9d8 <pr>
    8000053c:	796000ef          	jal	ra,80000cd2 <acquire>
    80000540:	b7c1                	j	80000500 <printf+0x3c>
      consputc(cx);
    80000542:	d07ff0ef          	jal	ra,80000248 <consputc>
      continue;
    80000546:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000548:	0014899b          	addiw	s3,s1,1
    8000054c:	013a07b3          	add	a5,s4,s3
    80000550:	0007c503          	lbu	a0,0(a5)
    80000554:	1e050f63          	beqz	a0,80000752 <printf+0x28e>
    if(cx != '%'){
    80000558:	ff5515e3          	bne	a0,s5,80000542 <printf+0x7e>
    i++;
    8000055c:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    80000560:	009a07b3          	add	a5,s4,s1
    80000564:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000568:	1e090563          	beqz	s2,80000752 <printf+0x28e>
    8000056c:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    80000570:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    80000572:	c789                	beqz	a5,8000057c <printf+0xb8>
    80000574:	009a0733          	add	a4,s4,s1
    80000578:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    8000057c:	03690863          	beq	s2,s6,800005ac <printf+0xe8>
    } else if(c0 == 'l' && c1 == 'd'){
    80000580:	05890263          	beq	s2,s8,800005c4 <printf+0x100>
    } else if(c0 == 'u'){
    80000584:	0d990163          	beq	s2,s9,80000646 <printf+0x182>
    } else if(c0 == 'x'){
    80000588:	11a90863          	beq	s2,s10,80000698 <printf+0x1d4>
    } else if(c0 == 'p'){
    8000058c:	15b90163          	beq	s2,s11,800006ce <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    80000590:	06300793          	li	a5,99
    80000594:	16f90963          	beq	s2,a5,80000706 <printf+0x242>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000598:	07300793          	li	a5,115
    8000059c:	16f90f63          	beq	s2,a5,8000071a <printf+0x256>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005a0:	03591c63          	bne	s2,s5,800005d8 <printf+0x114>
      consputc('%');
    800005a4:	8556                	mv	a0,s5
    800005a6:	ca3ff0ef          	jal	ra,80000248 <consputc>
    800005aa:	bf79                	j	80000548 <printf+0x84>
      printint(va_arg(ap, int), 10, 1);
    800005ac:	f8843783          	ld	a5,-120(s0)
    800005b0:	00878713          	addi	a4,a5,8
    800005b4:	f8e43423          	sd	a4,-120(s0)
    800005b8:	4605                	li	a2,1
    800005ba:	45a9                	li	a1,10
    800005bc:	4388                	lw	a0,0(a5)
    800005be:	e73ff0ef          	jal	ra,80000430 <printint>
    800005c2:	b759                	j	80000548 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'd'){
    800005c4:	03678163          	beq	a5,s6,800005e6 <printf+0x122>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005c8:	03878d63          	beq	a5,s8,80000602 <printf+0x13e>
    } else if(c0 == 'l' && c1 == 'u'){
    800005cc:	09978a63          	beq	a5,s9,80000660 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005d0:	03878b63          	beq	a5,s8,80000606 <printf+0x142>
    } else if(c0 == 'l' && c1 == 'x'){
    800005d4:	0da78f63          	beq	a5,s10,800006b2 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    800005d8:	8556                	mv	a0,s5
    800005da:	c6fff0ef          	jal	ra,80000248 <consputc>
      consputc(c0);
    800005de:	854a                	mv	a0,s2
    800005e0:	c69ff0ef          	jal	ra,80000248 <consputc>
    800005e4:	b795                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    800005e6:	f8843783          	ld	a5,-120(s0)
    800005ea:	00878713          	addi	a4,a5,8
    800005ee:	f8e43423          	sd	a4,-120(s0)
    800005f2:	4605                	li	a2,1
    800005f4:	45a9                	li	a1,10
    800005f6:	6388                	ld	a0,0(a5)
    800005f8:	e39ff0ef          	jal	ra,80000430 <printint>
      i += 1;
    800005fc:	0029849b          	addiw	s1,s3,2
    80000600:	b7a1                	j	80000548 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000602:	03668463          	beq	a3,s6,8000062a <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000606:	07968b63          	beq	a3,s9,8000067c <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000060a:	fda697e3          	bne	a3,s10,800005d8 <printf+0x114>
      printint(va_arg(ap, uint64), 16, 0);
    8000060e:	f8843783          	ld	a5,-120(s0)
    80000612:	00878713          	addi	a4,a5,8
    80000616:	f8e43423          	sd	a4,-120(s0)
    8000061a:	4601                	li	a2,0
    8000061c:	45c1                	li	a1,16
    8000061e:	6388                	ld	a0,0(a5)
    80000620:	e11ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000624:	0039849b          	addiw	s1,s3,3
    80000628:	b705                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    8000062a:	f8843783          	ld	a5,-120(s0)
    8000062e:	00878713          	addi	a4,a5,8
    80000632:	f8e43423          	sd	a4,-120(s0)
    80000636:	4605                	li	a2,1
    80000638:	45a9                	li	a1,10
    8000063a:	6388                	ld	a0,0(a5)
    8000063c:	df5ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000640:	0039849b          	addiw	s1,s3,3
    80000644:	b711                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint32), 10, 0);
    80000646:	f8843783          	ld	a5,-120(s0)
    8000064a:	00878713          	addi	a4,a5,8
    8000064e:	f8e43423          	sd	a4,-120(s0)
    80000652:	4601                	li	a2,0
    80000654:	45a9                	li	a1,10
    80000656:	0007e503          	lwu	a0,0(a5)
    8000065a:	dd7ff0ef          	jal	ra,80000430 <printint>
    8000065e:	b5ed                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4601                	li	a2,0
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	dbfff0ef          	jal	ra,80000430 <printint>
      i += 1;
    80000676:	0029849b          	addiw	s1,s3,2
    8000067a:	b5f9                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	6388                	ld	a0,0(a5)
    8000068e:	da3ff0ef          	jal	ra,80000430 <printint>
      i += 2;
    80000692:	0039849b          	addiw	s1,s3,3
    80000696:	bd4d                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint32), 16, 0);
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	4601                	li	a2,0
    800006a6:	45c1                	li	a1,16
    800006a8:	0007e503          	lwu	a0,0(a5)
    800006ac:	d85ff0ef          	jal	ra,80000430 <printint>
    800006b0:	bd61                	j	80000548 <printf+0x84>
      printint(va_arg(ap, uint64), 16, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45c1                	li	a1,16
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	d6dff0ef          	jal	ra,80000430 <printint>
      i += 1;
    800006c8:	0029849b          	addiw	s1,s3,2
    800006cc:	bdb5                	j	80000548 <printf+0x84>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	b67ff0ef          	jal	ra,80000248 <consputc>
  consputc('x');
    800006e6:	856a                	mv	a0,s10
    800006e8:	b61ff0ef          	jal	ra,80000248 <consputc>
    800006ec:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ee:	03c9d793          	srli	a5,s3,0x3c
    800006f2:	97de                	add	a5,a5,s7
    800006f4:	0007c503          	lbu	a0,0(a5)
    800006f8:	b51ff0ef          	jal	ra,80000248 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006fc:	0992                	slli	s3,s3,0x4
    800006fe:	397d                	addiw	s2,s2,-1
    80000700:	fe0917e3          	bnez	s2,800006ee <printf+0x22a>
    80000704:	b591                	j	80000548 <printf+0x84>
      consputc(va_arg(ap, uint));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	4388                	lw	a0,0(a5)
    80000714:	b35ff0ef          	jal	ra,80000248 <consputc>
    80000718:	bd05                	j	80000548 <printf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    8000071a:	f8843783          	ld	a5,-120(s0)
    8000071e:	00878713          	addi	a4,a5,8
    80000722:	f8e43423          	sd	a4,-120(s0)
    80000726:	0007b903          	ld	s2,0(a5)
    8000072a:	00090d63          	beqz	s2,80000744 <printf+0x280>
      for(; *s; s++)
    8000072e:	00094503          	lbu	a0,0(s2)
    80000732:	e0050be3          	beqz	a0,80000548 <printf+0x84>
        consputc(*s);
    80000736:	b13ff0ef          	jal	ra,80000248 <consputc>
      for(; *s; s++)
    8000073a:	0905                	addi	s2,s2,1
    8000073c:	00094503          	lbu	a0,0(s2)
    80000740:	f97d                	bnez	a0,80000736 <printf+0x272>
    80000742:	b519                	j	80000548 <printf+0x84>
        s = "(null)";
    80000744:	00007917          	auipc	s2,0x7
    80000748:	8d490913          	addi	s2,s2,-1836 # 80007018 <etext+0x18>
      for(; *s; s++)
    8000074c:	02800513          	li	a0,40
    80000750:	b7dd                	j	80000736 <printf+0x272>
    }

  }
  va_end(ap);

  if(panicking == 0)
    80000752:	00007797          	auipc	a5,0x7
    80000756:	1a27a783          	lw	a5,418(a5) # 800078f4 <panicking>
    8000075a:	c38d                	beqz	a5,8000077c <printf+0x2b8>
    release(&pr.lock);

  return 0;
}
    8000075c:	4501                	li	a0,0
    8000075e:	70e6                	ld	ra,120(sp)
    80000760:	7446                	ld	s0,112(sp)
    80000762:	74a6                	ld	s1,104(sp)
    80000764:	7906                	ld	s2,96(sp)
    80000766:	69e6                	ld	s3,88(sp)
    80000768:	6a46                	ld	s4,80(sp)
    8000076a:	6aa6                	ld	s5,72(sp)
    8000076c:	6b06                	ld	s6,64(sp)
    8000076e:	7be2                	ld	s7,56(sp)
    80000770:	7c42                	ld	s8,48(sp)
    80000772:	7ca2                	ld	s9,40(sp)
    80000774:	7d02                	ld	s10,32(sp)
    80000776:	6de2                	ld	s11,24(sp)
    80000778:	6129                	addi	sp,sp,192
    8000077a:	8082                	ret
    release(&pr.lock);
    8000077c:	0000f517          	auipc	a0,0xf
    80000780:	25c50513          	addi	a0,a0,604 # 8000f9d8 <pr>
    80000784:	5e6000ef          	jal	ra,80000d6a <release>
  return 0;
    80000788:	bfd1                	j	8000075c <printf+0x298>

000000008000078a <panic>:

void
panic(char *s)
{
    8000078a:	1101                	addi	sp,sp,-32
    8000078c:	ec06                	sd	ra,24(sp)
    8000078e:	e822                	sd	s0,16(sp)
    80000790:	e426                	sd	s1,8(sp)
    80000792:	e04a                	sd	s2,0(sp)
    80000794:	1000                	addi	s0,sp,32
    80000796:	84aa                	mv	s1,a0
  panicking = 1;
    80000798:	4905                	li	s2,1
    8000079a:	00007797          	auipc	a5,0x7
    8000079e:	1527ad23          	sw	s2,346(a5) # 800078f4 <panicking>
  printf("panic: ");
    800007a2:	00007517          	auipc	a0,0x7
    800007a6:	87e50513          	addi	a0,a0,-1922 # 80007020 <etext+0x20>
    800007aa:	d1bff0ef          	jal	ra,800004c4 <printf>
  printf("%s\n", s);
    800007ae:	85a6                	mv	a1,s1
    800007b0:	00007517          	auipc	a0,0x7
    800007b4:	87850513          	addi	a0,a0,-1928 # 80007028 <etext+0x28>
    800007b8:	d0dff0ef          	jal	ra,800004c4 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007bc:	00007797          	auipc	a5,0x7
    800007c0:	1327aa23          	sw	s2,308(a5) # 800078f0 <panicked>
  for(;;)
    800007c4:	a001                	j	800007c4 <panic+0x3a>

00000000800007c6 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007c6:	1141                	addi	sp,sp,-16
    800007c8:	e406                	sd	ra,8(sp)
    800007ca:	e022                	sd	s0,0(sp)
    800007cc:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    800007ce:	00007597          	auipc	a1,0x7
    800007d2:	86258593          	addi	a1,a1,-1950 # 80007030 <etext+0x30>
    800007d6:	0000f517          	auipc	a0,0xf
    800007da:	20250513          	addi	a0,a0,514 # 8000f9d8 <pr>
    800007de:	474000ef          	jal	ra,80000c52 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    800007ea:	1141                	addi	sp,sp,-16
    800007ec:	e406                	sd	ra,8(sp)
    800007ee:	e022                	sd	s0,0(sp)
    800007f0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007f2:	100007b7          	lui	a5,0x10000
    800007f6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007fa:	f8000713          	li	a4,-128
    800007fe:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000802:	470d                	li	a4,3
    80000804:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000808:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000810:	469d                	li	a3,7
    80000812:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000816:	00e780a3          	sb	a4,1(a5)

  initlock(&tx_lock, "uart");
    8000081a:	00007597          	auipc	a1,0x7
    8000081e:	83658593          	addi	a1,a1,-1994 # 80007050 <digits+0x18>
    80000822:	0000f517          	auipc	a0,0xf
    80000826:	1ce50513          	addi	a0,a0,462 # 8000f9f0 <tx_lock>
    8000082a:	428000ef          	jal	ra,80000c52 <initlock>
}
    8000082e:	60a2                	ld	ra,8(sp)
    80000830:	6402                	ld	s0,0(sp)
    80000832:	0141                	addi	sp,sp,16
    80000834:	8082                	ret

0000000080000836 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000836:	715d                	addi	sp,sp,-80
    80000838:	e486                	sd	ra,72(sp)
    8000083a:	e0a2                	sd	s0,64(sp)
    8000083c:	fc26                	sd	s1,56(sp)
    8000083e:	f84a                	sd	s2,48(sp)
    80000840:	f44e                	sd	s3,40(sp)
    80000842:	f052                	sd	s4,32(sp)
    80000844:	ec56                	sd	s5,24(sp)
    80000846:	e85a                	sd	s6,16(sp)
    80000848:	e45e                	sd	s7,8(sp)
    8000084a:	0880                	addi	s0,sp,80
    8000084c:	84aa                	mv	s1,a0
    8000084e:	8aae                	mv	s5,a1
  acquire(&tx_lock);
    80000850:	0000f517          	auipc	a0,0xf
    80000854:	1a050513          	addi	a0,a0,416 # 8000f9f0 <tx_lock>
    80000858:	47a000ef          	jal	ra,80000cd2 <acquire>

  int i = 0;
  while(i < n){ 
    8000085c:	05505b63          	blez	s5,800008b2 <uartwrite+0x7c>
    80000860:	8a26                	mv	s4,s1
    80000862:	0485                	addi	s1,s1,1
    80000864:	3afd                	addiw	s5,s5,-1
    80000866:	1a82                	slli	s5,s5,0x20
    80000868:	020ada93          	srli	s5,s5,0x20
    8000086c:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    8000086e:	00007497          	auipc	s1,0x7
    80000872:	08e48493          	addi	s1,s1,142 # 800078fc <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000876:	0000f997          	auipc	s3,0xf
    8000087a:	17a98993          	addi	s3,s3,378 # 8000f9f0 <tx_lock>
    8000087e:	00007917          	auipc	s2,0x7
    80000882:	07a90913          	addi	s2,s2,122 # 800078f8 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    80000886:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    8000088a:	4b05                	li	s6,1
    8000088c:	a005                	j	800008ac <uartwrite+0x76>
      sleep(&tx_chan, &tx_lock);
    8000088e:	85ce                	mv	a1,s3
    80000890:	854a                	mv	a0,s2
    80000892:	0f3010ef          	jal	ra,80002184 <sleep>
    while(tx_busy != 0){
    80000896:	409c                	lw	a5,0(s1)
    80000898:	fbfd                	bnez	a5,8000088e <uartwrite+0x58>
    WriteReg(THR, buf[i]);
    8000089a:	000a4783          	lbu	a5,0(s4)
    8000089e:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008a2:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008a6:	0a05                	addi	s4,s4,1
    800008a8:	015a0563          	beq	s4,s5,800008b2 <uartwrite+0x7c>
    while(tx_busy != 0){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	f3e5                	bnez	a5,8000088e <uartwrite+0x58>
    800008b0:	b7ed                	j	8000089a <uartwrite+0x64>
  }

  release(&tx_lock);
    800008b2:	0000f517          	auipc	a0,0xf
    800008b6:	13e50513          	addi	a0,a0,318 # 8000f9f0 <tx_lock>
    800008ba:	4b0000ef          	jal	ra,80000d6a <release>
}
    800008be:	60a6                	ld	ra,72(sp)
    800008c0:	6406                	ld	s0,64(sp)
    800008c2:	74e2                	ld	s1,56(sp)
    800008c4:	7942                	ld	s2,48(sp)
    800008c6:	79a2                	ld	s3,40(sp)
    800008c8:	7a02                	ld	s4,32(sp)
    800008ca:	6ae2                	ld	s5,24(sp)
    800008cc:	6b42                	ld	s6,16(sp)
    800008ce:	6ba2                	ld	s7,8(sp)
    800008d0:	6161                	addi	sp,sp,80
    800008d2:	8082                	ret

00000000800008d4 <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800008d4:	1101                	addi	sp,sp,-32
    800008d6:	ec06                	sd	ra,24(sp)
    800008d8:	e822                	sd	s0,16(sp)
    800008da:	e426                	sd	s1,8(sp)
    800008dc:	1000                	addi	s0,sp,32
    800008de:	84aa                	mv	s1,a0
  if(panicking == 0)
    800008e0:	00007797          	auipc	a5,0x7
    800008e4:	0147a783          	lw	a5,20(a5) # 800078f4 <panicking>
    800008e8:	cb89                	beqz	a5,800008fa <uartputc_sync+0x26>
    push_off();

  if(panicked){
    800008ea:	00007797          	auipc	a5,0x7
    800008ee:	0067a783          	lw	a5,6(a5) # 800078f0 <panicked>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800008f6:	c789                	beqz	a5,80000900 <uartputc_sync+0x2c>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc_sync+0x24>
    push_off();
    800008fa:	398000ef          	jal	ra,80000c92 <push_off>
    800008fe:	b7f5                	j	800008ea <uartputc_sync+0x16>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000900:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000904:	0207f793          	andi	a5,a5,32
    80000908:	dfe5                	beqz	a5,80000900 <uartputc_sync+0x2c>
    ;
  WriteReg(THR, c);
    8000090a:	0ff4f513          	andi	a0,s1,255
    8000090e:	100007b7          	lui	a5,0x10000
    80000912:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000916:	00007797          	auipc	a5,0x7
    8000091a:	fde7a783          	lw	a5,-34(a5) # 800078f4 <panicking>
    8000091e:	c791                	beqz	a5,8000092a <uartputc_sync+0x56>
    pop_off();
}
    80000920:	60e2                	ld	ra,24(sp)
    80000922:	6442                	ld	s0,16(sp)
    80000924:	64a2                	ld	s1,8(sp)
    80000926:	6105                	addi	sp,sp,32
    80000928:	8082                	ret
    pop_off();
    8000092a:	3ec000ef          	jal	ra,80000d16 <pop_off>
}
    8000092e:	bfcd                	j	80000920 <uartputc_sync+0x4c>

0000000080000930 <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000930:	1141                	addi	sp,sp,-16
    80000932:	e422                	sd	s0,8(sp)
    80000934:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000936:	100007b7          	lui	a5,0x10000
    8000093a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000093e:	8b85                	andi	a5,a5,1
    80000940:	cb91                	beqz	a5,80000954 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000942:	100007b7          	lui	a5,0x10000
    80000946:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000094a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000094e:	6422                	ld	s0,8(sp)
    80000950:	0141                	addi	sp,sp,16
    80000952:	8082                	ret
    return -1;
    80000954:	557d                	li	a0,-1
    80000956:	bfe5                	j	8000094e <uartgetc+0x1e>

0000000080000958 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000958:	1101                	addi	sp,sp,-32
    8000095a:	ec06                	sd	ra,24(sp)
    8000095c:	e822                	sd	s0,16(sp)
    8000095e:	e426                	sd	s1,8(sp)
    80000960:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    80000962:	100004b7          	lui	s1,0x10000
    80000966:	0024c783          	lbu	a5,2(s1) # 10000002 <_entry-0x6ffffffe>

  acquire(&tx_lock);
    8000096a:	0000f517          	auipc	a0,0xf
    8000096e:	08650513          	addi	a0,a0,134 # 8000f9f0 <tx_lock>
    80000972:	360000ef          	jal	ra,80000cd2 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    80000976:	0054c783          	lbu	a5,5(s1)
    8000097a:	0207f793          	andi	a5,a5,32
    8000097e:	eb89                	bnez	a5,80000990 <uartintr+0x38>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    80000980:	0000f517          	auipc	a0,0xf
    80000984:	07050513          	addi	a0,a0,112 # 8000f9f0 <tx_lock>
    80000988:	3e2000ef          	jal	ra,80000d6a <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098c:	54fd                	li	s1,-1
    8000098e:	a831                	j	800009aa <uartintr+0x52>
    tx_busy = 0;
    80000990:	00007797          	auipc	a5,0x7
    80000994:	f607a623          	sw	zero,-148(a5) # 800078fc <tx_busy>
    wakeup(&tx_chan);
    80000998:	00007517          	auipc	a0,0x7
    8000099c:	f6050513          	addi	a0,a0,-160 # 800078f8 <tx_chan>
    800009a0:	031010ef          	jal	ra,800021d0 <wakeup>
    800009a4:	bff1                	j	80000980 <uartintr+0x28>
      break;
    consoleintr(c);
    800009a6:	8d5ff0ef          	jal	ra,8000027a <consoleintr>
    int c = uartgetc();
    800009aa:	f87ff0ef          	jal	ra,80000930 <uartgetc>
    if(c == -1)
    800009ae:	fe951ce3          	bne	a0,s1,800009a6 <uartintr+0x4e>
  }
}
    800009b2:	60e2                	ld	ra,24(sp)
    800009b4:	6442                	ld	s0,16(sp)
    800009b6:	64a2                	ld	s1,8(sp)
    800009b8:	6105                	addi	sp,sp,32
    800009ba:	8082                	ret

00000000800009bc <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009bc:	1101                	addi	sp,sp,-32
    800009be:	ec06                	sd	ra,24(sp)
    800009c0:	e822                	sd	s0,16(sp)
    800009c2:	e426                	sd	s1,8(sp)
    800009c4:	e04a                	sd	s2,0(sp)
    800009c6:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009c8:	03451793          	slli	a5,a0,0x34
    800009cc:	efb5                	bnez	a5,80000a48 <kfree+0x8c>
    800009ce:	84aa                	mv	s1,a0
    800009d0:	000ab797          	auipc	a5,0xab
    800009d4:	c2878793          	addi	a5,a5,-984 # 800ab5f8 <end>
    800009d8:	06f56863          	bltu	a0,a5,80000a48 <kfree+0x8c>
    800009dc:	47c5                	li	a5,17
    800009de:	07ee                	slli	a5,a5,0x1b
    800009e0:	06f57463          	bgeu	a0,a5,80000a48 <kfree+0x8c>
    panic("kfree");

  // MiniOS: Only free the page if the reference count drops to 0.
  acquire(&kmem.lock);
    800009e4:	0000f517          	auipc	a0,0xf
    800009e8:	02450513          	addi	a0,a0,36 # 8000fa08 <kmem>
    800009ec:	2e6000ef          	jal	ra,80000cd2 <acquire>
  if (kmem.ref_count[(uint64)pa / PGSIZE] > 1) {
    800009f0:	00c4d793          	srli	a5,s1,0xc
    800009f4:	0000f717          	auipc	a4,0xf
    800009f8:	01470713          	addi	a4,a4,20 # 8000fa08 <kmem>
    800009fc:	973e                	add	a4,a4,a5
    800009fe:	02074703          	lbu	a4,32(a4)
    80000a02:	4685                	li	a3,1
    80000a04:	04e6e863          	bltu	a3,a4,80000a54 <kfree+0x98>
    kmem.ref_count[(uint64)pa / PGSIZE] -= 1;
    release(&kmem.lock);
    return;
  }
  kmem.ref_count[(uint64)pa / PGSIZE] = 0;
    80000a08:	0000f917          	auipc	s2,0xf
    80000a0c:	00090913          	mv	s2,s2
    80000a10:	97ca                	add	a5,a5,s2
    80000a12:	02078023          	sb	zero,32(a5)
  release(&kmem.lock);
    80000a16:	854a                	mv	a0,s2
    80000a18:	352000ef          	jal	ra,80000d6a <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a1c:	6605                	lui	a2,0x1
    80000a1e:	4585                	li	a1,1
    80000a20:	8526                	mv	a0,s1
    80000a22:	384000ef          	jal	ra,80000da6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	2aa000ef          	jal	ra,80000cd2 <acquire>
  r->next = kmem.freelist;
    80000a2c:	01893783          	ld	a5,24(s2) # 8000fa20 <kmem+0x18>
    80000a30:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a32:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a36:	854a                	mv	a0,s2
    80000a38:	332000ef          	jal	ra,80000d6a <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00006517          	auipc	a0,0x6
    80000a4c:	61050513          	addi	a0,a0,1552 # 80007058 <digits+0x20>
    80000a50:	d3bff0ef          	jal	ra,8000078a <panic>
    kmem.ref_count[(uint64)pa / PGSIZE] -= 1;
    80000a54:	0000f517          	auipc	a0,0xf
    80000a58:	fb450513          	addi	a0,a0,-76 # 8000fa08 <kmem>
    80000a5c:	97aa                	add	a5,a5,a0
    80000a5e:	377d                	addiw	a4,a4,-1
    80000a60:	02e78023          	sb	a4,32(a5)
    release(&kmem.lock);
    80000a64:	306000ef          	jal	ra,80000d6a <release>
    return;
    80000a68:	bfd1                	j	80000a3c <kfree+0x80>

0000000080000a6a <freerange>:
{
    80000a6a:	7179                	addi	sp,sp,-48
    80000a6c:	f406                	sd	ra,40(sp)
    80000a6e:	f022                	sd	s0,32(sp)
    80000a70:	ec26                	sd	s1,24(sp)
    80000a72:	e84a                	sd	s2,16(sp)
    80000a74:	e44e                	sd	s3,8(sp)
    80000a76:	e052                	sd	s4,0(sp)
    80000a78:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7a:	6785                	lui	a5,0x1
    80000a7c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a80:	94aa                	add	s1,s1,a0
    80000a82:	757d                	lui	a0,0xfffff
    80000a84:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	94be                	add	s1,s1,a5
    80000a88:	0095ec63          	bltu	a1,s1,80000aa0 <freerange+0x36>
    80000a8c:	892e                	mv	s2,a1
    kfree(p);
    80000a8e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	6985                	lui	s3,0x1
    kfree(p);
    80000a92:	01448533          	add	a0,s1,s4
    80000a96:	f27ff0ef          	jal	ra,800009bc <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94ce                	add	s1,s1,s3
    80000a9c:	fe997be3          	bgeu	s2,s1,80000a92 <freerange+0x28>
}
    80000aa0:	70a2                	ld	ra,40(sp)
    80000aa2:	7402                	ld	s0,32(sp)
    80000aa4:	64e2                	ld	s1,24(sp)
    80000aa6:	6942                	ld	s2,16(sp)
    80000aa8:	69a2                	ld	s3,8(sp)
    80000aaa:	6a02                	ld	s4,0(sp)
    80000aac:	6145                	addi	sp,sp,48
    80000aae:	8082                	ret

0000000080000ab0 <kinit>:
{
    80000ab0:	1141                	addi	sp,sp,-16
    80000ab2:	e406                	sd	ra,8(sp)
    80000ab4:	e022                	sd	s0,0(sp)
    80000ab6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab8:	00006597          	auipc	a1,0x6
    80000abc:	5a858593          	addi	a1,a1,1448 # 80007060 <digits+0x28>
    80000ac0:	0000f517          	auipc	a0,0xf
    80000ac4:	f4850513          	addi	a0,a0,-184 # 8000fa08 <kmem>
    80000ac8:	18a000ef          	jal	ra,80000c52 <initlock>
  for (int i = 0; i < PHYSTOP / PGSIZE; i++)
    80000acc:	0000f797          	auipc	a5,0xf
    80000ad0:	f5c78793          	addi	a5,a5,-164 # 8000fa28 <kmem+0x20>
    80000ad4:	00097717          	auipc	a4,0x97
    80000ad8:	f5470713          	addi	a4,a4,-172 # 80097a28 <pid_lock>
    kmem.ref_count[i] = 0;
    80000adc:	00078023          	sb	zero,0(a5)
  for (int i = 0; i < PHYSTOP / PGSIZE; i++)
    80000ae0:	0785                	addi	a5,a5,1
    80000ae2:	fee79de3          	bne	a5,a4,80000adc <kinit+0x2c>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	000ab517          	auipc	a0,0xab
    80000aee:	b0e50513          	addi	a0,a0,-1266 # 800ab5f8 <end>
    80000af2:	f79ff0ef          	jal	ra,80000a6a <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	0000f517          	auipc	a0,0xf
    80000b0c:	f0050513          	addi	a0,a0,-256 # 8000fa08 <kmem>
    80000b10:	1c2000ef          	jal	ra,80000cd2 <acquire>
  r = kmem.freelist;
    80000b14:	0000f497          	auipc	s1,0xf
    80000b18:	f0c4b483          	ld	s1,-244(s1) # 8000fa20 <kmem+0x18>
  if(r) {
    80000b1c:	c895                	beqz	s1,80000b50 <kalloc+0x52>
    kmem.freelist = r->next;
    80000b1e:	609c                	ld	a5,0(s1)
    80000b20:	0000f517          	auipc	a0,0xf
    80000b24:	ee850513          	addi	a0,a0,-280 # 8000fa08 <kmem>
    80000b28:	ed1c                	sd	a5,24(a0)
    // MiniOS: Freshly allocated page starts with 1 reference.
    kmem.ref_count[(uint64)r / PGSIZE] = 1;
    80000b2a:	00c4d793          	srli	a5,s1,0xc
    80000b2e:	97aa                	add	a5,a5,a0
    80000b30:	4705                	li	a4,1
    80000b32:	02e78023          	sb	a4,32(a5)
  }
  release(&kmem.lock);
    80000b36:	234000ef          	jal	ra,80000d6a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b3a:	6605                	lui	a2,0x1
    80000b3c:	4595                	li	a1,5
    80000b3e:	8526                	mv	a0,s1
    80000b40:	266000ef          	jal	ra,80000da6 <memset>
  return (void*)r;
}
    80000b44:	8526                	mv	a0,s1
    80000b46:	60e2                	ld	ra,24(sp)
    80000b48:	6442                	ld	s0,16(sp)
    80000b4a:	64a2                	ld	s1,8(sp)
    80000b4c:	6105                	addi	sp,sp,32
    80000b4e:	8082                	ret
  release(&kmem.lock);
    80000b50:	0000f517          	auipc	a0,0xf
    80000b54:	eb850513          	addi	a0,a0,-328 # 8000fa08 <kmem>
    80000b58:	212000ef          	jal	ra,80000d6a <release>
  if(r)
    80000b5c:	b7e5                	j	80000b44 <kalloc+0x46>

0000000080000b5e <kref>:

// MiniOS: Increment reference count for a physical page (COW).
void
kref(uint64 pa)
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  if (((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b68:	03451793          	slli	a5,a0,0x34
    80000b6c:	ebb1                	bnez	a5,80000bc0 <kref+0x62>
    80000b6e:	84aa                	mv	s1,a0
    80000b70:	000ab797          	auipc	a5,0xab
    80000b74:	a8878793          	addi	a5,a5,-1400 # 800ab5f8 <end>
    80000b78:	04f56463          	bltu	a0,a5,80000bc0 <kref+0x62>
    80000b7c:	47c5                	li	a5,17
    80000b7e:	07ee                	slli	a5,a5,0x1b
    80000b80:	04f57063          	bgeu	a0,a5,80000bc0 <kref+0x62>
    panic("kref");

  acquire(&kmem.lock);
    80000b84:	0000f517          	auipc	a0,0xf
    80000b88:	e8450513          	addi	a0,a0,-380 # 8000fa08 <kmem>
    80000b8c:	146000ef          	jal	ra,80000cd2 <acquire>
  if (kmem.ref_count[pa / PGSIZE] < 1)
    80000b90:	80b1                	srli	s1,s1,0xc
    80000b92:	0000f797          	auipc	a5,0xf
    80000b96:	e7678793          	addi	a5,a5,-394 # 8000fa08 <kmem>
    80000b9a:	97a6                	add	a5,a5,s1
    80000b9c:	0207c783          	lbu	a5,32(a5)
    80000ba0:	c795                	beqz	a5,80000bcc <kref+0x6e>
    panic("kref: ref_count < 1");
  kmem.ref_count[pa / PGSIZE] += 1;
    80000ba2:	0000f517          	auipc	a0,0xf
    80000ba6:	e6650513          	addi	a0,a0,-410 # 8000fa08 <kmem>
    80000baa:	94aa                	add	s1,s1,a0
    80000bac:	2785                	addiw	a5,a5,1
    80000bae:	02f48023          	sb	a5,32(s1)
  release(&kmem.lock);
    80000bb2:	1b8000ef          	jal	ra,80000d6a <release>
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    panic("kref");
    80000bc0:	00006517          	auipc	a0,0x6
    80000bc4:	4a850513          	addi	a0,a0,1192 # 80007068 <digits+0x30>
    80000bc8:	bc3ff0ef          	jal	ra,8000078a <panic>
    panic("kref: ref_count < 1");
    80000bcc:	00006517          	auipc	a0,0x6
    80000bd0:	4a450513          	addi	a0,a0,1188 # 80007070 <digits+0x38>
    80000bd4:	bb7ff0ef          	jal	ra,8000078a <panic>

0000000080000bd8 <kunref>:

// MiniOS: Decrement reference count for a physical page (COW).
// Note: This does NOT free the page. Use kfree for that.
void
kunref(uint64 pa)
{
    80000bd8:	1101                	addi	sp,sp,-32
    80000bda:	ec06                	sd	ra,24(sp)
    80000bdc:	e822                	sd	s0,16(sp)
    80000bde:	e426                	sd	s1,8(sp)
    80000be0:	1000                	addi	s0,sp,32
  if (((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000be2:	03451793          	slli	a5,a0,0x34
    80000be6:	ebb1                	bnez	a5,80000c3a <kunref+0x62>
    80000be8:	84aa                	mv	s1,a0
    80000bea:	000ab797          	auipc	a5,0xab
    80000bee:	a0e78793          	addi	a5,a5,-1522 # 800ab5f8 <end>
    80000bf2:	04f56463          	bltu	a0,a5,80000c3a <kunref+0x62>
    80000bf6:	47c5                	li	a5,17
    80000bf8:	07ee                	slli	a5,a5,0x1b
    80000bfa:	04f57063          	bgeu	a0,a5,80000c3a <kunref+0x62>
    panic("kunref");

  acquire(&kmem.lock);
    80000bfe:	0000f517          	auipc	a0,0xf
    80000c02:	e0a50513          	addi	a0,a0,-502 # 8000fa08 <kmem>
    80000c06:	0cc000ef          	jal	ra,80000cd2 <acquire>
  if (kmem.ref_count[pa / PGSIZE] < 1)
    80000c0a:	80b1                	srli	s1,s1,0xc
    80000c0c:	0000f797          	auipc	a5,0xf
    80000c10:	dfc78793          	addi	a5,a5,-516 # 8000fa08 <kmem>
    80000c14:	97a6                	add	a5,a5,s1
    80000c16:	0207c783          	lbu	a5,32(a5)
    80000c1a:	c795                	beqz	a5,80000c46 <kunref+0x6e>
    panic("kunref: ref_count < 1");
  kmem.ref_count[pa / PGSIZE] -= 1;
    80000c1c:	0000f517          	auipc	a0,0xf
    80000c20:	dec50513          	addi	a0,a0,-532 # 8000fa08 <kmem>
    80000c24:	94aa                	add	s1,s1,a0
    80000c26:	37fd                	addiw	a5,a5,-1
    80000c28:	02f48023          	sb	a5,32(s1)
  release(&kmem.lock);
    80000c2c:	13e000ef          	jal	ra,80000d6a <release>
}
    80000c30:	60e2                	ld	ra,24(sp)
    80000c32:	6442                	ld	s0,16(sp)
    80000c34:	64a2                	ld	s1,8(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret
    panic("kunref");
    80000c3a:	00006517          	auipc	a0,0x6
    80000c3e:	44e50513          	addi	a0,a0,1102 # 80007088 <digits+0x50>
    80000c42:	b49ff0ef          	jal	ra,8000078a <panic>
    panic("kunref: ref_count < 1");
    80000c46:	00006517          	auipc	a0,0x6
    80000c4a:	44a50513          	addi	a0,a0,1098 # 80007090 <digits+0x58>
    80000c4e:	b3dff0ef          	jal	ra,8000078a <panic>

0000000080000c52 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e422                	sd	s0,8(sp)
    80000c56:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c58:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c5a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c5e:	00053823          	sd	zero,16(a0)
}
    80000c62:	6422                	ld	s0,8(sp)
    80000c64:	0141                	addi	sp,sp,16
    80000c66:	8082                	ret

0000000080000c68 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c68:	411c                	lw	a5,0(a0)
    80000c6a:	e399                	bnez	a5,80000c70 <holding+0x8>
    80000c6c:	4501                	li	a0,0
  return r;
}
    80000c6e:	8082                	ret
{
    80000c70:	1101                	addi	sp,sp,-32
    80000c72:	ec06                	sd	ra,24(sp)
    80000c74:	e822                	sd	s0,16(sp)
    80000c76:	e426                	sd	s1,8(sp)
    80000c78:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c7a:	6904                	ld	s1,16(a0)
    80000c7c:	5a3000ef          	jal	ra,80001a1e <mycpu>
    80000c80:	40a48533          	sub	a0,s1,a0
    80000c84:	00153513          	seqz	a0,a0
}
    80000c88:	60e2                	ld	ra,24(sp)
    80000c8a:	6442                	ld	s0,16(sp)
    80000c8c:	64a2                	ld	s1,8(sp)
    80000c8e:	6105                	addi	sp,sp,32
    80000c90:	8082                	ret

0000000080000c92 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c92:	1101                	addi	sp,sp,-32
    80000c94:	ec06                	sd	ra,24(sp)
    80000c96:	e822                	sd	s0,16(sp)
    80000c98:	e426                	sd	s1,8(sp)
    80000c9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100024f3          	csrr	s1,sstatus
    80000ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca6:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000caa:	575000ef          	jal	ra,80001a1e <mycpu>
    80000cae:	5d3c                	lw	a5,120(a0)
    80000cb0:	cb99                	beqz	a5,80000cc6 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb2:	56d000ef          	jal	ra,80001a1e <mycpu>
    80000cb6:	5d3c                	lw	a5,120(a0)
    80000cb8:	2785                	addiw	a5,a5,1
    80000cba:	dd3c                	sw	a5,120(a0)
}
    80000cbc:	60e2                	ld	ra,24(sp)
    80000cbe:	6442                	ld	s0,16(sp)
    80000cc0:	64a2                	ld	s1,8(sp)
    80000cc2:	6105                	addi	sp,sp,32
    80000cc4:	8082                	ret
    mycpu()->intena = old;
    80000cc6:	559000ef          	jal	ra,80001a1e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cca:	8085                	srli	s1,s1,0x1
    80000ccc:	8885                	andi	s1,s1,1
    80000cce:	dd64                	sw	s1,124(a0)
    80000cd0:	b7cd                	j	80000cb2 <push_off+0x20>

0000000080000cd2 <acquire>:
{
    80000cd2:	1101                	addi	sp,sp,-32
    80000cd4:	ec06                	sd	ra,24(sp)
    80000cd6:	e822                	sd	s0,16(sp)
    80000cd8:	e426                	sd	s1,8(sp)
    80000cda:	1000                	addi	s0,sp,32
    80000cdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cde:	fb5ff0ef          	jal	ra,80000c92 <push_off>
  if(holding(lk))
    80000ce2:	8526                	mv	a0,s1
    80000ce4:	f85ff0ef          	jal	ra,80000c68 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ce8:	4705                	li	a4,1
  if(holding(lk))
    80000cea:	e105                	bnez	a0,80000d0a <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cec:	87ba                	mv	a5,a4
    80000cee:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cf2:	2781                	sext.w	a5,a5
    80000cf4:	ffe5                	bnez	a5,80000cec <acquire+0x1a>
  __sync_synchronize();
    80000cf6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cfa:	525000ef          	jal	ra,80001a1e <mycpu>
    80000cfe:	e888                	sd	a0,16(s1)
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    panic("acquire");
    80000d0a:	00006517          	auipc	a0,0x6
    80000d0e:	39e50513          	addi	a0,a0,926 # 800070a8 <digits+0x70>
    80000d12:	a79ff0ef          	jal	ra,8000078a <panic>

0000000080000d16 <pop_off>:

void
pop_off(void)
{
    80000d16:	1141                	addi	sp,sp,-16
    80000d18:	e406                	sd	ra,8(sp)
    80000d1a:	e022                	sd	s0,0(sp)
    80000d1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d1e:	501000ef          	jal	ra,80001a1e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d26:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d28:	e78d                	bnez	a5,80000d52 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d2a:	5d3c                	lw	a5,120(a0)
    80000d2c:	02f05963          	blez	a5,80000d5e <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000d30:	37fd                	addiw	a5,a5,-1
    80000d32:	0007871b          	sext.w	a4,a5
    80000d36:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d38:	eb09                	bnez	a4,80000d4a <pop_off+0x34>
    80000d3a:	5d7c                	lw	a5,124(a0)
    80000d3c:	c799                	beqz	a5,80000d4a <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d46:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d4a:	60a2                	ld	ra,8(sp)
    80000d4c:	6402                	ld	s0,0(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
    panic("pop_off - interruptible");
    80000d52:	00006517          	auipc	a0,0x6
    80000d56:	35e50513          	addi	a0,a0,862 # 800070b0 <digits+0x78>
    80000d5a:	a31ff0ef          	jal	ra,8000078a <panic>
    panic("pop_off");
    80000d5e:	00006517          	auipc	a0,0x6
    80000d62:	36a50513          	addi	a0,a0,874 # 800070c8 <digits+0x90>
    80000d66:	a25ff0ef          	jal	ra,8000078a <panic>

0000000080000d6a <release>:
{
    80000d6a:	1101                	addi	sp,sp,-32
    80000d6c:	ec06                	sd	ra,24(sp)
    80000d6e:	e822                	sd	s0,16(sp)
    80000d70:	e426                	sd	s1,8(sp)
    80000d72:	1000                	addi	s0,sp,32
    80000d74:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d76:	ef3ff0ef          	jal	ra,80000c68 <holding>
    80000d7a:	c105                	beqz	a0,80000d9a <release+0x30>
  lk->cpu = 0;
    80000d7c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d80:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d84:	0f50000f          	fence	iorw,ow
    80000d88:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d8c:	f8bff0ef          	jal	ra,80000d16 <pop_off>
}
    80000d90:	60e2                	ld	ra,24(sp)
    80000d92:	6442                	ld	s0,16(sp)
    80000d94:	64a2                	ld	s1,8(sp)
    80000d96:	6105                	addi	sp,sp,32
    80000d98:	8082                	ret
    panic("release");
    80000d9a:	00006517          	auipc	a0,0x6
    80000d9e:	33650513          	addi	a0,a0,822 # 800070d0 <digits+0x98>
    80000da2:	9e9ff0ef          	jal	ra,8000078a <panic>

0000000080000da6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e422                	sd	s0,8(sp)
    80000daa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dac:	ca19                	beqz	a2,80000dc2 <memset+0x1c>
    80000dae:	87aa                	mv	a5,a0
    80000db0:	1602                	slli	a2,a2,0x20
    80000db2:	9201                	srli	a2,a2,0x20
    80000db4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000db8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dbc:	0785                	addi	a5,a5,1
    80000dbe:	fee79de3          	bne	a5,a4,80000db8 <memset+0x12>
  }
  return dst;
}
    80000dc2:	6422                	ld	s0,8(sp)
    80000dc4:	0141                	addi	sp,sp,16
    80000dc6:	8082                	ret

0000000080000dc8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dc8:	1141                	addi	sp,sp,-16
    80000dca:	e422                	sd	s0,8(sp)
    80000dcc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dce:	ca05                	beqz	a2,80000dfe <memcmp+0x36>
    80000dd0:	fff6069b          	addiw	a3,a2,-1
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ddc:	00054783          	lbu	a5,0(a0)
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00e79863          	bne	a5,a4,80000df4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000de8:	0505                	addi	a0,a0,1
    80000dea:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dec:	fed518e3          	bne	a0,a3,80000ddc <memcmp+0x14>
  }

  return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a019                	j	80000df8 <memcmp+0x30>
      return *s1 - *s2;
    80000df4:	40e7853b          	subw	a0,a5,a4
}
    80000df8:	6422                	ld	s0,8(sp)
    80000dfa:	0141                	addi	sp,sp,16
    80000dfc:	8082                	ret
  return 0;
    80000dfe:	4501                	li	a0,0
    80000e00:	bfe5                	j	80000df8 <memcmp+0x30>

0000000080000e02 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e08:	c205                	beqz	a2,80000e28 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e0a:	02a5e263          	bltu	a1,a0,80000e2e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e0e:	1602                	slli	a2,a2,0x20
    80000e10:	9201                	srli	a2,a2,0x20
    80000e12:	00c587b3          	add	a5,a1,a2
{
    80000e16:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e18:	0585                	addi	a1,a1,1
    80000e1a:	0705                	addi	a4,a4,1
    80000e1c:	fff5c683          	lbu	a3,-1(a1)
    80000e20:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e24:	fef59ae3          	bne	a1,a5,80000e18 <memmove+0x16>

  return dst;
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret
  if(s < d && s + n > d){
    80000e2e:	02061693          	slli	a3,a2,0x20
    80000e32:	9281                	srli	a3,a3,0x20
    80000e34:	00d58733          	add	a4,a1,a3
    80000e38:	fce57be3          	bgeu	a0,a4,80000e0e <memmove+0xc>
    d += n;
    80000e3c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e3e:	fff6079b          	addiw	a5,a2,-1
    80000e42:	1782                	slli	a5,a5,0x20
    80000e44:	9381                	srli	a5,a5,0x20
    80000e46:	fff7c793          	not	a5,a5
    80000e4a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e4c:	177d                	addi	a4,a4,-1
    80000e4e:	16fd                	addi	a3,a3,-1
    80000e50:	00074603          	lbu	a2,0(a4)
    80000e54:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e58:	fee79ae3          	bne	a5,a4,80000e4c <memmove+0x4a>
    80000e5c:	b7f1                	j	80000e28 <memmove+0x26>

0000000080000e5e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e5e:	1141                	addi	sp,sp,-16
    80000e60:	e406                	sd	ra,8(sp)
    80000e62:	e022                	sd	s0,0(sp)
    80000e64:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e66:	f9dff0ef          	jal	ra,80000e02 <memmove>
}
    80000e6a:	60a2                	ld	ra,8(sp)
    80000e6c:	6402                	ld	s0,0(sp)
    80000e6e:	0141                	addi	sp,sp,16
    80000e70:	8082                	ret

0000000080000e72 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e422                	sd	s0,8(sp)
    80000e76:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e78:	ce11                	beqz	a2,80000e94 <strncmp+0x22>
    80000e7a:	00054783          	lbu	a5,0(a0)
    80000e7e:	cf89                	beqz	a5,80000e98 <strncmp+0x26>
    80000e80:	0005c703          	lbu	a4,0(a1)
    80000e84:	00f71a63          	bne	a4,a5,80000e98 <strncmp+0x26>
    n--, p++, q++;
    80000e88:	367d                	addiw	a2,a2,-1
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e8e:	f675                	bnez	a2,80000e7a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e90:	4501                	li	a0,0
    80000e92:	a809                	j	80000ea4 <strncmp+0x32>
    80000e94:	4501                	li	a0,0
    80000e96:	a039                	j	80000ea4 <strncmp+0x32>
  if(n == 0)
    80000e98:	ca09                	beqz	a2,80000eaa <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e9a:	00054503          	lbu	a0,0(a0)
    80000e9e:	0005c783          	lbu	a5,0(a1)
    80000ea2:	9d1d                	subw	a0,a0,a5
}
    80000ea4:	6422                	ld	s0,8(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret
    return 0;
    80000eaa:	4501                	li	a0,0
    80000eac:	bfe5                	j	80000ea4 <strncmp+0x32>

0000000080000eae <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e422                	sd	s0,8(sp)
    80000eb2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eb4:	872a                	mv	a4,a0
    80000eb6:	8832                	mv	a6,a2
    80000eb8:	367d                	addiw	a2,a2,-1
    80000eba:	01005963          	blez	a6,80000ecc <strncpy+0x1e>
    80000ebe:	0705                	addi	a4,a4,1
    80000ec0:	0005c783          	lbu	a5,0(a1)
    80000ec4:	fef70fa3          	sb	a5,-1(a4)
    80000ec8:	0585                	addi	a1,a1,1
    80000eca:	f7f5                	bnez	a5,80000eb6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ecc:	86ba                	mv	a3,a4
    80000ece:	00c05c63          	blez	a2,80000ee6 <strncpy+0x38>
    *s++ = 0;
    80000ed2:	0685                	addi	a3,a3,1
    80000ed4:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ed8:	fff6c793          	not	a5,a3
    80000edc:	9fb9                	addw	a5,a5,a4
    80000ede:	010787bb          	addw	a5,a5,a6
    80000ee2:	fef048e3          	bgtz	a5,80000ed2 <strncpy+0x24>
  return os;
}
    80000ee6:	6422                	ld	s0,8(sp)
    80000ee8:	0141                	addi	sp,sp,16
    80000eea:	8082                	ret

0000000080000eec <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eec:	1141                	addi	sp,sp,-16
    80000eee:	e422                	sd	s0,8(sp)
    80000ef0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ef2:	02c05363          	blez	a2,80000f18 <safestrcpy+0x2c>
    80000ef6:	fff6069b          	addiw	a3,a2,-1
    80000efa:	1682                	slli	a3,a3,0x20
    80000efc:	9281                	srli	a3,a3,0x20
    80000efe:	96ae                	add	a3,a3,a1
    80000f00:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f02:	00d58963          	beq	a1,a3,80000f14 <safestrcpy+0x28>
    80000f06:	0585                	addi	a1,a1,1
    80000f08:	0785                	addi	a5,a5,1
    80000f0a:	fff5c703          	lbu	a4,-1(a1)
    80000f0e:	fee78fa3          	sb	a4,-1(a5)
    80000f12:	fb65                	bnez	a4,80000f02 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f14:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret

0000000080000f1e <strlen>:

int
strlen(const char *s)
{
    80000f1e:	1141                	addi	sp,sp,-16
    80000f20:	e422                	sd	s0,8(sp)
    80000f22:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f24:	00054783          	lbu	a5,0(a0)
    80000f28:	cf91                	beqz	a5,80000f44 <strlen+0x26>
    80000f2a:	0505                	addi	a0,a0,1
    80000f2c:	87aa                	mv	a5,a0
    80000f2e:	4685                	li	a3,1
    80000f30:	9e89                	subw	a3,a3,a0
    80000f32:	00f6853b          	addw	a0,a3,a5
    80000f36:	0785                	addi	a5,a5,1
    80000f38:	fff7c703          	lbu	a4,-1(a5)
    80000f3c:	fb7d                	bnez	a4,80000f32 <strlen+0x14>
    ;
  return n;
}
    80000f3e:	6422                	ld	s0,8(sp)
    80000f40:	0141                	addi	sp,sp,16
    80000f42:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f44:	4501                	li	a0,0
    80000f46:	bfe5                	j	80000f3e <strlen+0x20>

0000000080000f48 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f48:	1141                	addi	sp,sp,-16
    80000f4a:	e406                	sd	ra,8(sp)
    80000f4c:	e022                	sd	s0,0(sp)
    80000f4e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f50:	2bf000ef          	jal	ra,80001a0e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f54:	00007717          	auipc	a4,0x7
    80000f58:	9ac70713          	addi	a4,a4,-1620 # 80007900 <started>
  if(cpuid() == 0){
    80000f5c:	c51d                	beqz	a0,80000f8a <main+0x42>
    while(started == 0)
    80000f5e:	431c                	lw	a5,0(a4)
    80000f60:	2781                	sext.w	a5,a5
    80000f62:	dff5                	beqz	a5,80000f5e <main+0x16>
      ;
    __sync_synchronize();
    80000f64:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f68:	2a7000ef          	jal	ra,80001a0e <cpuid>
    80000f6c:	85aa                	mv	a1,a0
    80000f6e:	00006517          	auipc	a0,0x6
    80000f72:	18250513          	addi	a0,a0,386 # 800070f0 <digits+0xb8>
    80000f76:	d4eff0ef          	jal	ra,800004c4 <printf>
    kvminithart();    // turn on paging
    80000f7a:	080000ef          	jal	ra,80000ffa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f7e:	3b7010ef          	jal	ra,80002b34 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f82:	2b3040ef          	jal	ra,80005a34 <plicinithart>
  }

  scheduler();        
    80000f86:	747000ef          	jal	ra,80001ecc <scheduler>
    consoleinit();
    80000f8a:	c62ff0ef          	jal	ra,800003ec <consoleinit>
    printfinit();
    80000f8e:	839ff0ef          	jal	ra,800007c6 <printfinit>
    printf("\n");
    80000f92:	00006517          	auipc	a0,0x6
    80000f96:	16e50513          	addi	a0,a0,366 # 80007100 <digits+0xc8>
    80000f9a:	d2aff0ef          	jal	ra,800004c4 <printf>
    printf("xv6 kernel is booting\n");
    80000f9e:	00006517          	auipc	a0,0x6
    80000fa2:	13a50513          	addi	a0,a0,314 # 800070d8 <digits+0xa0>
    80000fa6:	d1eff0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    80000faa:	00006517          	auipc	a0,0x6
    80000fae:	15650513          	addi	a0,a0,342 # 80007100 <digits+0xc8>
    80000fb2:	d12ff0ef          	jal	ra,800004c4 <printf>
    kinit();         // physical page allocator
    80000fb6:	afbff0ef          	jal	ra,80000ab0 <kinit>
    kvminit();       // create kernel page table
    80000fba:	2ca000ef          	jal	ra,80001284 <kvminit>
    kvminithart();   // turn on paging
    80000fbe:	03c000ef          	jal	ra,80000ffa <kvminithart>
    procinit();      // process table
    80000fc2:	139000ef          	jal	ra,800018fa <procinit>
    trapinit();      // trap vectors
    80000fc6:	34b010ef          	jal	ra,80002b10 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fca:	36b010ef          	jal	ra,80002b34 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fce:	251040ef          	jal	ra,80005a1e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fd2:	263040ef          	jal	ra,80005a34 <plicinithart>
    binit();         // buffer cache
    80000fd6:	204020ef          	jal	ra,800031da <binit>
    iinit();         // inode table
    80000fda:	778020ef          	jal	ra,80003752 <iinit>
    fileinit();      // file table
    80000fde:	658030ef          	jal	ra,80004636 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fe2:	343040ef          	jal	ra,80005b24 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	52d000ef          	jal	ra,80001d12 <userinit>
    __sync_synchronize();
    80000fea:	0ff0000f          	fence
    started = 1;
    80000fee:	4785                	li	a5,1
    80000ff0:	00007717          	auipc	a4,0x7
    80000ff4:	90f72823          	sw	a5,-1776(a4) # 80007900 <started>
    80000ff8:	b779                	j	80000f86 <main+0x3e>

0000000080000ffa <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000ffa:	1141                	addi	sp,sp,-16
    80000ffc:	e422                	sd	s0,8(sp)
    80000ffe:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001000:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001004:	00007797          	auipc	a5,0x7
    80001008:	9047b783          	ld	a5,-1788(a5) # 80007908 <kernel_pagetable>
    8000100c:	83b1                	srli	a5,a5,0xc
    8000100e:	577d                	li	a4,-1
    80001010:	177e                	slli	a4,a4,0x3f
    80001012:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001014:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001018:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000101c:	6422                	ld	s0,8(sp)
    8000101e:	0141                	addi	sp,sp,16
    80001020:	8082                	ret

0000000080001022 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001022:	7139                	addi	sp,sp,-64
    80001024:	fc06                	sd	ra,56(sp)
    80001026:	f822                	sd	s0,48(sp)
    80001028:	f426                	sd	s1,40(sp)
    8000102a:	f04a                	sd	s2,32(sp)
    8000102c:	ec4e                	sd	s3,24(sp)
    8000102e:	e852                	sd	s4,16(sp)
    80001030:	e456                	sd	s5,8(sp)
    80001032:	e05a                	sd	s6,0(sp)
    80001034:	0080                	addi	s0,sp,64
    80001036:	84aa                	mv	s1,a0
    80001038:	89ae                	mv	s3,a1
    8000103a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000103c:	57fd                	li	a5,-1
    8000103e:	83e9                	srli	a5,a5,0x1a
    80001040:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001042:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001044:	02b7fc63          	bgeu	a5,a1,8000107c <walk+0x5a>
    panic("walk");
    80001048:	00006517          	auipc	a0,0x6
    8000104c:	0c050513          	addi	a0,a0,192 # 80007108 <digits+0xd0>
    80001050:	f3aff0ef          	jal	ra,8000078a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001054:	060a8263          	beqz	s5,800010b8 <walk+0x96>
    80001058:	aa7ff0ef          	jal	ra,80000afe <kalloc>
    8000105c:	84aa                	mv	s1,a0
    8000105e:	c139                	beqz	a0,800010a4 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001060:	6605                	lui	a2,0x1
    80001062:	4581                	li	a1,0
    80001064:	d43ff0ef          	jal	ra,80000da6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001068:	00c4d793          	srli	a5,s1,0xc
    8000106c:	07aa                	slli	a5,a5,0xa
    8000106e:	0017e793          	ori	a5,a5,1
    80001072:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001076:	3a5d                	addiw	s4,s4,-9
    80001078:	036a0063          	beq	s4,s6,80001098 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    8000107c:	0149d933          	srl	s2,s3,s4
    80001080:	1ff97913          	andi	s2,s2,511
    80001084:	090e                	slli	s2,s2,0x3
    80001086:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001088:	00093483          	ld	s1,0(s2)
    8000108c:	0014f793          	andi	a5,s1,1
    80001090:	d3f1                	beqz	a5,80001054 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001092:	80a9                	srli	s1,s1,0xa
    80001094:	04b2                	slli	s1,s1,0xc
    80001096:	b7c5                	j	80001076 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80001098:	00c9d513          	srli	a0,s3,0xc
    8000109c:	1ff57513          	andi	a0,a0,511
    800010a0:	050e                	slli	a0,a0,0x3
    800010a2:	9526                	add	a0,a0,s1
}
    800010a4:	70e2                	ld	ra,56(sp)
    800010a6:	7442                	ld	s0,48(sp)
    800010a8:	74a2                	ld	s1,40(sp)
    800010aa:	7902                	ld	s2,32(sp)
    800010ac:	69e2                	ld	s3,24(sp)
    800010ae:	6a42                	ld	s4,16(sp)
    800010b0:	6aa2                	ld	s5,8(sp)
    800010b2:	6b02                	ld	s6,0(sp)
    800010b4:	6121                	addi	sp,sp,64
    800010b6:	8082                	ret
        return 0;
    800010b8:	4501                	li	a0,0
    800010ba:	b7ed                	j	800010a4 <walk+0x82>

00000000800010bc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010bc:	57fd                	li	a5,-1
    800010be:	83e9                	srli	a5,a5,0x1a
    800010c0:	00b7f463          	bgeu	a5,a1,800010c8 <walkaddr+0xc>
    return 0;
    800010c4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c6:	8082                	ret
{
    800010c8:	1141                	addi	sp,sp,-16
    800010ca:	e406                	sd	ra,8(sp)
    800010cc:	e022                	sd	s0,0(sp)
    800010ce:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d0:	4601                	li	a2,0
    800010d2:	f51ff0ef          	jal	ra,80001022 <walk>
  if(pte == 0)
    800010d6:	c105                	beqz	a0,800010f6 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    800010d8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010da:	0117f693          	andi	a3,a5,17
    800010de:	4745                	li	a4,17
    return 0;
    800010e0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e2:	00e68663          	beq	a3,a4,800010ee <walkaddr+0x32>
}
    800010e6:	60a2                	ld	ra,8(sp)
    800010e8:	6402                	ld	s0,0(sp)
    800010ea:	0141                	addi	sp,sp,16
    800010ec:	8082                	ret
  pa = PTE2PA(*pte);
    800010ee:	00a7d513          	srli	a0,a5,0xa
    800010f2:	0532                	slli	a0,a0,0xc
  return pa;
    800010f4:	bfcd                	j	800010e6 <walkaddr+0x2a>
    return 0;
    800010f6:	4501                	li	a0,0
    800010f8:	b7fd                	j	800010e6 <walkaddr+0x2a>

00000000800010fa <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010fa:	715d                	addi	sp,sp,-80
    800010fc:	e486                	sd	ra,72(sp)
    800010fe:	e0a2                	sd	s0,64(sp)
    80001100:	fc26                	sd	s1,56(sp)
    80001102:	f84a                	sd	s2,48(sp)
    80001104:	f44e                	sd	s3,40(sp)
    80001106:	f052                	sd	s4,32(sp)
    80001108:	ec56                	sd	s5,24(sp)
    8000110a:	e85a                	sd	s6,16(sp)
    8000110c:	e45e                	sd	s7,8(sp)
    8000110e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001110:	03459793          	slli	a5,a1,0x34
    80001114:	e7a9                	bnez	a5,8000115e <mappages+0x64>
    80001116:	8aaa                	mv	s5,a0
    80001118:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000111a:	03461793          	slli	a5,a2,0x34
    8000111e:	e7b1                	bnez	a5,8000116a <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001120:	ca39                	beqz	a2,80001176 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001122:	79fd                	lui	s3,0xfffff
    80001124:	964e                	add	a2,a2,s3
    80001126:	00b609b3          	add	s3,a2,a1
  a = va;
    8000112a:	892e                	mv	s2,a1
    8000112c:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001130:	6b85                	lui	s7,0x1
    80001132:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001136:	4605                	li	a2,1
    80001138:	85ca                	mv	a1,s2
    8000113a:	8556                	mv	a0,s5
    8000113c:	ee7ff0ef          	jal	ra,80001022 <walk>
    80001140:	c539                	beqz	a0,8000118e <mappages+0x94>
    if(*pte & PTE_V)
    80001142:	611c                	ld	a5,0(a0)
    80001144:	8b85                	andi	a5,a5,1
    80001146:	ef95                	bnez	a5,80001182 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001148:	80b1                	srli	s1,s1,0xc
    8000114a:	04aa                	slli	s1,s1,0xa
    8000114c:	0164e4b3          	or	s1,s1,s6
    80001150:	0014e493          	ori	s1,s1,1
    80001154:	e104                	sd	s1,0(a0)
    if(a == last)
    80001156:	05390863          	beq	s2,s3,800011a6 <mappages+0xac>
    a += PGSIZE;
    8000115a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115c:	bfd9                	j	80001132 <mappages+0x38>
    panic("mappages: va not aligned");
    8000115e:	00006517          	auipc	a0,0x6
    80001162:	fb250513          	addi	a0,a0,-78 # 80007110 <digits+0xd8>
    80001166:	e24ff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size not aligned");
    8000116a:	00006517          	auipc	a0,0x6
    8000116e:	fc650513          	addi	a0,a0,-58 # 80007130 <digits+0xf8>
    80001172:	e18ff0ef          	jal	ra,8000078a <panic>
    panic("mappages: size");
    80001176:	00006517          	auipc	a0,0x6
    8000117a:	fda50513          	addi	a0,a0,-38 # 80007150 <digits+0x118>
    8000117e:	e0cff0ef          	jal	ra,8000078a <panic>
      panic("mappages: remap");
    80001182:	00006517          	auipc	a0,0x6
    80001186:	fde50513          	addi	a0,a0,-34 # 80007160 <digits+0x128>
    8000118a:	e00ff0ef          	jal	ra,8000078a <panic>
      return -1;
    8000118e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001190:	60a6                	ld	ra,72(sp)
    80001192:	6406                	ld	s0,64(sp)
    80001194:	74e2                	ld	s1,56(sp)
    80001196:	7942                	ld	s2,48(sp)
    80001198:	79a2                	ld	s3,40(sp)
    8000119a:	7a02                	ld	s4,32(sp)
    8000119c:	6ae2                	ld	s5,24(sp)
    8000119e:	6b42                	ld	s6,16(sp)
    800011a0:	6ba2                	ld	s7,8(sp)
    800011a2:	6161                	addi	sp,sp,80
    800011a4:	8082                	ret
  return 0;
    800011a6:	4501                	li	a0,0
    800011a8:	b7e5                	j	80001190 <mappages+0x96>

00000000800011aa <kvmmap>:
{
    800011aa:	1141                	addi	sp,sp,-16
    800011ac:	e406                	sd	ra,8(sp)
    800011ae:	e022                	sd	s0,0(sp)
    800011b0:	0800                	addi	s0,sp,16
    800011b2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011b4:	86b2                	mv	a3,a2
    800011b6:	863e                	mv	a2,a5
    800011b8:	f43ff0ef          	jal	ra,800010fa <mappages>
    800011bc:	e509                	bnez	a0,800011c6 <kvmmap+0x1c>
}
    800011be:	60a2                	ld	ra,8(sp)
    800011c0:	6402                	ld	s0,0(sp)
    800011c2:	0141                	addi	sp,sp,16
    800011c4:	8082                	ret
    panic("kvmmap");
    800011c6:	00006517          	auipc	a0,0x6
    800011ca:	faa50513          	addi	a0,a0,-86 # 80007170 <digits+0x138>
    800011ce:	dbcff0ef          	jal	ra,8000078a <panic>

00000000800011d2 <kvmmake>:
{
    800011d2:	1101                	addi	sp,sp,-32
    800011d4:	ec06                	sd	ra,24(sp)
    800011d6:	e822                	sd	s0,16(sp)
    800011d8:	e426                	sd	s1,8(sp)
    800011da:	e04a                	sd	s2,0(sp)
    800011dc:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011de:	921ff0ef          	jal	ra,80000afe <kalloc>
    800011e2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011e4:	6605                	lui	a2,0x1
    800011e6:	4581                	li	a1,0
    800011e8:	bbfff0ef          	jal	ra,80000da6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	6685                	lui	a3,0x1
    800011f0:	10000637          	lui	a2,0x10000
    800011f4:	100005b7          	lui	a1,0x10000
    800011f8:	8526                	mv	a0,s1
    800011fa:	fb1ff0ef          	jal	ra,800011aa <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011fe:	4719                	li	a4,6
    80001200:	6685                	lui	a3,0x1
    80001202:	10001637          	lui	a2,0x10001
    80001206:	100015b7          	lui	a1,0x10001
    8000120a:	8526                	mv	a0,s1
    8000120c:	f9fff0ef          	jal	ra,800011aa <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	040006b7          	lui	a3,0x4000
    80001216:	0c000637          	lui	a2,0xc000
    8000121a:	0c0005b7          	lui	a1,0xc000
    8000121e:	8526                	mv	a0,s1
    80001220:	f8bff0ef          	jal	ra,800011aa <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001224:	00006917          	auipc	s2,0x6
    80001228:	ddc90913          	addi	s2,s2,-548 # 80007000 <etext>
    8000122c:	4729                	li	a4,10
    8000122e:	80006697          	auipc	a3,0x80006
    80001232:	dd268693          	addi	a3,a3,-558 # 7000 <_entry-0x7fff9000>
    80001236:	4605                	li	a2,1
    80001238:	067e                	slli	a2,a2,0x1f
    8000123a:	85b2                	mv	a1,a2
    8000123c:	8526                	mv	a0,s1
    8000123e:	f6dff0ef          	jal	ra,800011aa <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001242:	4719                	li	a4,6
    80001244:	46c5                	li	a3,17
    80001246:	06ee                	slli	a3,a3,0x1b
    80001248:	412686b3          	sub	a3,a3,s2
    8000124c:	864a                	mv	a2,s2
    8000124e:	85ca                	mv	a1,s2
    80001250:	8526                	mv	a0,s1
    80001252:	f59ff0ef          	jal	ra,800011aa <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001256:	4729                	li	a4,10
    80001258:	6685                	lui	a3,0x1
    8000125a:	00005617          	auipc	a2,0x5
    8000125e:	da660613          	addi	a2,a2,-602 # 80006000 <_trampoline>
    80001262:	040005b7          	lui	a1,0x4000
    80001266:	15fd                	addi	a1,a1,-1
    80001268:	05b2                	slli	a1,a1,0xc
    8000126a:	8526                	mv	a0,s1
    8000126c:	f3fff0ef          	jal	ra,800011aa <kvmmap>
  proc_mapstacks(kpgtbl);
    80001270:	8526                	mv	a0,s1
    80001272:	5fe000ef          	jal	ra,80001870 <proc_mapstacks>
}
    80001276:	8526                	mv	a0,s1
    80001278:	60e2                	ld	ra,24(sp)
    8000127a:	6442                	ld	s0,16(sp)
    8000127c:	64a2                	ld	s1,8(sp)
    8000127e:	6902                	ld	s2,0(sp)
    80001280:	6105                	addi	sp,sp,32
    80001282:	8082                	ret

0000000080001284 <kvminit>:
{
    80001284:	1141                	addi	sp,sp,-16
    80001286:	e406                	sd	ra,8(sp)
    80001288:	e022                	sd	s0,0(sp)
    8000128a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000128c:	f47ff0ef          	jal	ra,800011d2 <kvmmake>
    80001290:	00006797          	auipc	a5,0x6
    80001294:	66a7bc23          	sd	a0,1656(a5) # 80007908 <kernel_pagetable>
}
    80001298:	60a2                	ld	ra,8(sp)
    8000129a:	6402                	ld	s0,0(sp)
    8000129c:	0141                	addi	sp,sp,16
    8000129e:	8082                	ret

00000000800012a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800012a0:	1101                	addi	sp,sp,-32
    800012a2:	ec06                	sd	ra,24(sp)
    800012a4:	e822                	sd	s0,16(sp)
    800012a6:	e426                	sd	s1,8(sp)
    800012a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800012aa:	855ff0ef          	jal	ra,80000afe <kalloc>
    800012ae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800012b0:	c509                	beqz	a0,800012ba <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800012b2:	6605                	lui	a2,0x1
    800012b4:	4581                	li	a1,0
    800012b6:	af1ff0ef          	jal	ra,80000da6 <memset>
  return pagetable;
}
    800012ba:	8526                	mv	a0,s1
    800012bc:	60e2                	ld	ra,24(sp)
    800012be:	6442                	ld	s0,16(sp)
    800012c0:	64a2                	ld	s1,8(sp)
    800012c2:	6105                	addi	sp,sp,32
    800012c4:	8082                	ret

00000000800012c6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c6:	7139                	addi	sp,sp,-64
    800012c8:	fc06                	sd	ra,56(sp)
    800012ca:	f822                	sd	s0,48(sp)
    800012cc:	f426                	sd	s1,40(sp)
    800012ce:	f04a                	sd	s2,32(sp)
    800012d0:	ec4e                	sd	s3,24(sp)
    800012d2:	e852                	sd	s4,16(sp)
    800012d4:	e456                	sd	s5,8(sp)
    800012d6:	e05a                	sd	s6,0(sp)
    800012d8:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012da:	03459793          	slli	a5,a1,0x34
    800012de:	e785                	bnez	a5,80001306 <uvmunmap+0x40>
    800012e0:	8a2a                	mv	s4,a0
    800012e2:	892e                	mv	s2,a1
    800012e4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	0632                	slli	a2,a2,0xc
    800012e8:	00b609b3          	add	s3,a2,a1
    800012ec:	6b05                	lui	s6,0x1
    800012ee:	0335e763          	bltu	a1,s3,8000131c <uvmunmap+0x56>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012f2:	70e2                	ld	ra,56(sp)
    800012f4:	7442                	ld	s0,48(sp)
    800012f6:	74a2                	ld	s1,40(sp)
    800012f8:	7902                	ld	s2,32(sp)
    800012fa:	69e2                	ld	s3,24(sp)
    800012fc:	6a42                	ld	s4,16(sp)
    800012fe:	6aa2                	ld	s5,8(sp)
    80001300:	6b02                	ld	s6,0(sp)
    80001302:	6121                	addi	sp,sp,64
    80001304:	8082                	ret
    panic("uvmunmap: not aligned");
    80001306:	00006517          	auipc	a0,0x6
    8000130a:	e7250513          	addi	a0,a0,-398 # 80007178 <digits+0x140>
    8000130e:	c7cff0ef          	jal	ra,8000078a <panic>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	fd397de3          	bgeu	s2,s3,800012f2 <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	d01ff0ef          	jal	ra,80001022 <walk>
    80001326:	84aa                	mv	s1,a0
    80001328:	d57d                	beqz	a0,80001316 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    8000132a:	611c                	ld	a5,0(a0)
    8000132c:	0017f713          	andi	a4,a5,1
    80001330:	d37d                	beqz	a4,80001316 <uvmunmap+0x50>
    if(do_free){
    80001332:	fe0a80e3          	beqz	s5,80001312 <uvmunmap+0x4c>
      uint64 pa = PTE2PA(*pte);
    80001336:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001338:	00c79513          	slli	a0,a5,0xc
    8000133c:	e80ff0ef          	jal	ra,800009bc <kfree>
    80001340:	bfc9                	j	80001312 <uvmunmap+0x4c>

0000000080001342 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000134c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000134e:	00b67d63          	bgeu	a2,a1,80001368 <uvmdealloc+0x26>
    80001352:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001354:	6785                	lui	a5,0x1
    80001356:	17fd                	addi	a5,a5,-1
    80001358:	00f60733          	add	a4,a2,a5
    8000135c:	767d                	lui	a2,0xfffff
    8000135e:	8f71                	and	a4,a4,a2
    80001360:	97ae                	add	a5,a5,a1
    80001362:	8ff1                	and	a5,a5,a2
    80001364:	00f76863          	bltu	a4,a5,80001374 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001368:	8526                	mv	a0,s1
    8000136a:	60e2                	ld	ra,24(sp)
    8000136c:	6442                	ld	s0,16(sp)
    8000136e:	64a2                	ld	s1,8(sp)
    80001370:	6105                	addi	sp,sp,32
    80001372:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001374:	8f99                	sub	a5,a5,a4
    80001376:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001378:	4685                	li	a3,1
    8000137a:	0007861b          	sext.w	a2,a5
    8000137e:	85ba                	mv	a1,a4
    80001380:	f47ff0ef          	jal	ra,800012c6 <uvmunmap>
    80001384:	b7d5                	j	80001368 <uvmdealloc+0x26>

0000000080001386 <uvmalloc>:
  if(newsz < oldsz)
    80001386:	08b66963          	bltu	a2,a1,80001418 <uvmalloc+0x92>
{
    8000138a:	7139                	addi	sp,sp,-64
    8000138c:	fc06                	sd	ra,56(sp)
    8000138e:	f822                	sd	s0,48(sp)
    80001390:	f426                	sd	s1,40(sp)
    80001392:	f04a                	sd	s2,32(sp)
    80001394:	ec4e                	sd	s3,24(sp)
    80001396:	e852                	sd	s4,16(sp)
    80001398:	e456                	sd	s5,8(sp)
    8000139a:	e05a                	sd	s6,0(sp)
    8000139c:	0080                	addi	s0,sp,64
    8000139e:	8aaa                	mv	s5,a0
    800013a0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800013a2:	6985                	lui	s3,0x1
    800013a4:	19fd                	addi	s3,s3,-1
    800013a6:	95ce                	add	a1,a1,s3
    800013a8:	79fd                	lui	s3,0xfffff
    800013aa:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800013ae:	06c9f763          	bgeu	s3,a2,8000141c <uvmalloc+0x96>
    800013b2:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800013b4:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800013b8:	f46ff0ef          	jal	ra,80000afe <kalloc>
    800013bc:	84aa                	mv	s1,a0
    if(mem == 0){
    800013be:	c11d                	beqz	a0,800013e4 <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    800013c0:	6605                	lui	a2,0x1
    800013c2:	4581                	li	a1,0
    800013c4:	9e3ff0ef          	jal	ra,80000da6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800013c8:	875a                	mv	a4,s6
    800013ca:	86a6                	mv	a3,s1
    800013cc:	6605                	lui	a2,0x1
    800013ce:	85ca                	mv	a1,s2
    800013d0:	8556                	mv	a0,s5
    800013d2:	d29ff0ef          	jal	ra,800010fa <mappages>
    800013d6:	e51d                	bnez	a0,80001404 <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800013d8:	6785                	lui	a5,0x1
    800013da:	993e                	add	s2,s2,a5
    800013dc:	fd496ee3          	bltu	s2,s4,800013b8 <uvmalloc+0x32>
  return newsz;
    800013e0:	8552                	mv	a0,s4
    800013e2:	a039                	j	800013f0 <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    800013e4:	864e                	mv	a2,s3
    800013e6:	85ca                	mv	a1,s2
    800013e8:	8556                	mv	a0,s5
    800013ea:	f59ff0ef          	jal	ra,80001342 <uvmdealloc>
      return 0;
    800013ee:	4501                	li	a0,0
}
    800013f0:	70e2                	ld	ra,56(sp)
    800013f2:	7442                	ld	s0,48(sp)
    800013f4:	74a2                	ld	s1,40(sp)
    800013f6:	7902                	ld	s2,32(sp)
    800013f8:	69e2                	ld	s3,24(sp)
    800013fa:	6a42                	ld	s4,16(sp)
    800013fc:	6aa2                	ld	s5,8(sp)
    800013fe:	6b02                	ld	s6,0(sp)
    80001400:	6121                	addi	sp,sp,64
    80001402:	8082                	ret
      kfree(mem);
    80001404:	8526                	mv	a0,s1
    80001406:	db6ff0ef          	jal	ra,800009bc <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000140a:	864e                	mv	a2,s3
    8000140c:	85ca                	mv	a1,s2
    8000140e:	8556                	mv	a0,s5
    80001410:	f33ff0ef          	jal	ra,80001342 <uvmdealloc>
      return 0;
    80001414:	4501                	li	a0,0
    80001416:	bfe9                	j	800013f0 <uvmalloc+0x6a>
    return oldsz;
    80001418:	852e                	mv	a0,a1
}
    8000141a:	8082                	ret
  return newsz;
    8000141c:	8532                	mv	a0,a2
    8000141e:	bfc9                	j	800013f0 <uvmalloc+0x6a>

0000000080001420 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001420:	7179                	addi	sp,sp,-48
    80001422:	f406                	sd	ra,40(sp)
    80001424:	f022                	sd	s0,32(sp)
    80001426:	ec26                	sd	s1,24(sp)
    80001428:	e84a                	sd	s2,16(sp)
    8000142a:	e44e                	sd	s3,8(sp)
    8000142c:	e052                	sd	s4,0(sp)
    8000142e:	1800                	addi	s0,sp,48
    80001430:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001432:	84aa                	mv	s1,a0
    80001434:	6905                	lui	s2,0x1
    80001436:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001438:	4985                	li	s3,1
    8000143a:	a811                	j	8000144e <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000143c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000143e:	0532                	slli	a0,a0,0xc
    80001440:	fe1ff0ef          	jal	ra,80001420 <freewalk>
      pagetable[i] = 0;
    80001444:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001448:	04a1                	addi	s1,s1,8
    8000144a:	01248f63          	beq	s1,s2,80001468 <freewalk+0x48>
    pte_t pte = pagetable[i];
    8000144e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001450:	00f57793          	andi	a5,a0,15
    80001454:	ff3784e3          	beq	a5,s3,8000143c <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001458:	8905                	andi	a0,a0,1
    8000145a:	d57d                	beqz	a0,80001448 <freewalk+0x28>
      panic("freewalk: leaf");
    8000145c:	00006517          	auipc	a0,0x6
    80001460:	d3450513          	addi	a0,a0,-716 # 80007190 <digits+0x158>
    80001464:	b26ff0ef          	jal	ra,8000078a <panic>
    }
  }
  kfree((void*)pagetable);
    80001468:	8552                	mv	a0,s4
    8000146a:	d52ff0ef          	jal	ra,800009bc <kfree>
}
    8000146e:	70a2                	ld	ra,40(sp)
    80001470:	7402                	ld	s0,32(sp)
    80001472:	64e2                	ld	s1,24(sp)
    80001474:	6942                	ld	s2,16(sp)
    80001476:	69a2                	ld	s3,8(sp)
    80001478:	6a02                	ld	s4,0(sp)
    8000147a:	6145                	addi	sp,sp,48
    8000147c:	8082                	ret

000000008000147e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000147e:	1101                	addi	sp,sp,-32
    80001480:	ec06                	sd	ra,24(sp)
    80001482:	e822                	sd	s0,16(sp)
    80001484:	e426                	sd	s1,8(sp)
    80001486:	1000                	addi	s0,sp,32
    80001488:	84aa                	mv	s1,a0
  if(sz > 0)
    8000148a:	e989                	bnez	a1,8000149c <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000148c:	8526                	mv	a0,s1
    8000148e:	f93ff0ef          	jal	ra,80001420 <freewalk>
}
    80001492:	60e2                	ld	ra,24(sp)
    80001494:	6442                	ld	s0,16(sp)
    80001496:	64a2                	ld	s1,8(sp)
    80001498:	6105                	addi	sp,sp,32
    8000149a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000149c:	6605                	lui	a2,0x1
    8000149e:	167d                	addi	a2,a2,-1
    800014a0:	962e                	add	a2,a2,a1
    800014a2:	4685                	li	a3,1
    800014a4:	8231                	srli	a2,a2,0xc
    800014a6:	4581                	li	a1,0
    800014a8:	e1fff0ef          	jal	ra,800012c6 <uvmunmap>
    800014ac:	b7c5                	j	8000148c <uvmfree+0xe>

00000000800014ae <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    800014ae:	c641                	beqz	a2,80001536 <uvmcopy+0x88>
{
    800014b0:	7139                	addi	sp,sp,-64
    800014b2:	fc06                	sd	ra,56(sp)
    800014b4:	f822                	sd	s0,48(sp)
    800014b6:	f426                	sd	s1,40(sp)
    800014b8:	f04a                	sd	s2,32(sp)
    800014ba:	ec4e                	sd	s3,24(sp)
    800014bc:	e852                	sd	s4,16(sp)
    800014be:	e456                	sd	s5,8(sp)
    800014c0:	0080                	addi	s0,sp,64
    800014c2:	8a2a                	mv	s4,a0
    800014c4:	8aae                	mv	s5,a1
    800014c6:	89b2                	mv	s3,a2
  for(i = 0; i < sz; i += PGSIZE){
    800014c8:	4481                	li	s1,0
    800014ca:	a831                	j	800014e6 <uvmcopy+0x38>
    kref(pa);
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800014cc:	4685                	li	a3,1
    800014ce:	00c4d613          	srli	a2,s1,0xc
    800014d2:	4581                	li	a1,0
    800014d4:	8556                	mv	a0,s5
    800014d6:	df1ff0ef          	jal	ra,800012c6 <uvmunmap>
  return -1;
    800014da:	557d                	li	a0,-1
    800014dc:	a0a1                	j	80001524 <uvmcopy+0x76>
  for(i = 0; i < sz; i += PGSIZE){
    800014de:	6785                	lui	a5,0x1
    800014e0:	94be                	add	s1,s1,a5
    800014e2:	0534f063          	bgeu	s1,s3,80001522 <uvmcopy+0x74>
    if((pte = walk(old, i, 0)) == 0)
    800014e6:	4601                	li	a2,0
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	b37ff0ef          	jal	ra,80001022 <walk>
    800014f0:	d57d                	beqz	a0,800014de <uvmcopy+0x30>
    if((*pte & PTE_V) == 0)
    800014f2:	6118                	ld	a4,0(a0)
    800014f4:	00177793          	andi	a5,a4,1
    800014f8:	d3fd                	beqz	a5,800014de <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    800014fa:	00a75913          	srli	s2,a4,0xa
    800014fe:	0932                	slli	s2,s2,0xc
    *pte &= ~PTE_W;     // Clear Write bit
    80001500:	9b6d                	andi	a4,a4,-5
    *pte |= PTE_COW;    // Set COW bit
    80001502:	10076713          	ori	a4,a4,256
    80001506:	e118                	sd	a4,0(a0)
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001508:	3fb77713          	andi	a4,a4,1019
    8000150c:	86ca                	mv	a3,s2
    8000150e:	6605                	lui	a2,0x1
    80001510:	85a6                	mv	a1,s1
    80001512:	8556                	mv	a0,s5
    80001514:	be7ff0ef          	jal	ra,800010fa <mappages>
    80001518:	f955                	bnez	a0,800014cc <uvmcopy+0x1e>
    kref(pa);
    8000151a:	854a                	mv	a0,s2
    8000151c:	e42ff0ef          	jal	ra,80000b5e <kref>
    80001520:	bf7d                	j	800014de <uvmcopy+0x30>
  return 0;
    80001522:	4501                	li	a0,0
}
    80001524:	70e2                	ld	ra,56(sp)
    80001526:	7442                	ld	s0,48(sp)
    80001528:	74a2                	ld	s1,40(sp)
    8000152a:	7902                	ld	s2,32(sp)
    8000152c:	69e2                	ld	s3,24(sp)
    8000152e:	6a42                	ld	s4,16(sp)
    80001530:	6aa2                	ld	s5,8(sp)
    80001532:	6121                	addi	sp,sp,64
    80001534:	8082                	ret
  return 0;
    80001536:	4501                	li	a0,0
}
    80001538:	8082                	ret

000000008000153a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000153a:	1141                	addi	sp,sp,-16
    8000153c:	e406                	sd	ra,8(sp)
    8000153e:	e022                	sd	s0,0(sp)
    80001540:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001542:	4601                	li	a2,0
    80001544:	adfff0ef          	jal	ra,80001022 <walk>
  if(pte == 0)
    80001548:	c901                	beqz	a0,80001558 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000154a:	611c                	ld	a5,0(a0)
    8000154c:	9bbd                	andi	a5,a5,-17
    8000154e:	e11c                	sd	a5,0(a0)
}
    80001550:	60a2                	ld	ra,8(sp)
    80001552:	6402                	ld	s0,0(sp)
    80001554:	0141                	addi	sp,sp,16
    80001556:	8082                	ret
    panic("uvmclear");
    80001558:	00006517          	auipc	a0,0x6
    8000155c:	c4850513          	addi	a0,a0,-952 # 800071a0 <digits+0x168>
    80001560:	a2aff0ef          	jal	ra,8000078a <panic>

0000000080001564 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001564:	c2d5                	beqz	a3,80001608 <copyinstr+0xa4>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8a2a                	mv	s4,a0
    8000157e:	8b2e                	mv	s6,a1
    80001580:	8bb2                	mv	s7,a2
    80001582:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001584:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001586:	6985                	lui	s3,0x1
    80001588:	a035                	j	800015b4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000158a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000158e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001590:	0017b793          	seqz	a5,a5
    80001594:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001598:	60a6                	ld	ra,72(sp)
    8000159a:	6406                	ld	s0,64(sp)
    8000159c:	74e2                	ld	s1,56(sp)
    8000159e:	7942                	ld	s2,48(sp)
    800015a0:	79a2                	ld	s3,40(sp)
    800015a2:	7a02                	ld	s4,32(sp)
    800015a4:	6ae2                	ld	s5,24(sp)
    800015a6:	6b42                	ld	s6,16(sp)
    800015a8:	6ba2                	ld	s7,8(sp)
    800015aa:	6161                	addi	sp,sp,80
    800015ac:	8082                	ret
    srcva = va0 + PGSIZE;
    800015ae:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800015b2:	c4b9                	beqz	s1,80001600 <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    800015b4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800015b8:	85ca                	mv	a1,s2
    800015ba:	8552                	mv	a0,s4
    800015bc:	b01ff0ef          	jal	ra,800010bc <walkaddr>
    if(pa0 == 0)
    800015c0:	c131                	beqz	a0,80001604 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    800015c2:	41790833          	sub	a6,s2,s7
    800015c6:	984e                	add	a6,a6,s3
    if(n > max)
    800015c8:	0104f363          	bgeu	s1,a6,800015ce <copyinstr+0x6a>
    800015cc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800015ce:	955e                	add	a0,a0,s7
    800015d0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800015d4:	fc080de3          	beqz	a6,800015ae <copyinstr+0x4a>
    800015d8:	985a                	add	a6,a6,s6
    800015da:	87da                	mv	a5,s6
      if(*p == '\0'){
    800015dc:	41650633          	sub	a2,a0,s6
    800015e0:	14fd                	addi	s1,s1,-1
    800015e2:	9b26                	add	s6,s6,s1
    800015e4:	00f60733          	add	a4,a2,a5
    800015e8:	00074703          	lbu	a4,0(a4)
    800015ec:	df59                	beqz	a4,8000158a <copyinstr+0x26>
        *dst = *p;
    800015ee:	00e78023          	sb	a4,0(a5)
      --max;
    800015f2:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800015f6:	0785                	addi	a5,a5,1
    while(n > 0){
    800015f8:	ff0796e3          	bne	a5,a6,800015e4 <copyinstr+0x80>
      dst++;
    800015fc:	8b42                	mv	s6,a6
    800015fe:	bf45                	j	800015ae <copyinstr+0x4a>
    80001600:	4781                	li	a5,0
    80001602:	b779                	j	80001590 <copyinstr+0x2c>
      return -1;
    80001604:	557d                	li	a0,-1
    80001606:	bf49                	j	80001598 <copyinstr+0x34>
  int got_null = 0;
    80001608:	4781                	li	a5,0
  if(got_null){
    8000160a:	0017b793          	seqz	a5,a5
    8000160e:	40f00533          	neg	a0,a5
}
    80001612:	8082                	ret

0000000080001614 <vmfault>:
// that was lazily allocated in sys_sbrk().
// returns 0 if va is invalid or already mapped, or if
// out of physical memory, and physical address if successful.
uint64
vmfault(pagetable_t pagetable, uint64 va, int read)
{
    80001614:	7139                	addi	sp,sp,-64
    80001616:	fc06                	sd	ra,56(sp)
    80001618:	f822                	sd	s0,48(sp)
    8000161a:	f426                	sd	s1,40(sp)
    8000161c:	f04a                	sd	s2,32(sp)
    8000161e:	ec4e                	sd	s3,24(sp)
    80001620:	e852                	sd	s4,16(sp)
    80001622:	e456                	sd	s5,8(sp)
    80001624:	e05a                	sd	s6,0(sp)
    80001626:	0080                	addi	s0,sp,64
    80001628:	8aaa                	mv	s5,a0
    8000162a:	84ae                	mv	s1,a1
    8000162c:	8a32                	mv	s4,a2
  pte_t *pte;
  uint64 pa, mem;
  struct proc *p = myproc();
    8000162e:	40c000ef          	jal	ra,80001a3a <myproc>

  if (va >= p->sz)
    80001632:	653c                	ld	a5,72(a0)
    return 0;
    80001634:	4901                	li	s2,0
  if (va >= p->sz)
    80001636:	00f4ed63          	bltu	s1,a5,80001650 <vmfault+0x3c>
  if (mappages(pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    kfree((void *)mem);
    return 0;
  }
  return mem;
}
    8000163a:	854a                	mv	a0,s2
    8000163c:	70e2                	ld	ra,56(sp)
    8000163e:	7442                	ld	s0,48(sp)
    80001640:	74a2                	ld	s1,40(sp)
    80001642:	7902                	ld	s2,32(sp)
    80001644:	69e2                	ld	s3,24(sp)
    80001646:	6a42                	ld	s4,16(sp)
    80001648:	6aa2                	ld	s5,8(sp)
    8000164a:	6b02                	ld	s6,0(sp)
    8000164c:	6121                	addi	sp,sp,64
    8000164e:	8082                	ret
  va = PGROUNDDOWN(va);
    80001650:	75fd                	lui	a1,0xfffff
    80001652:	8ced                	and	s1,s1,a1
  if((pte = walk(pagetable, va, 0)) != 0 && (*pte & PTE_V)) {
    80001654:	4601                	li	a2,0
    80001656:	85a6                	mv	a1,s1
    80001658:	8556                	mv	a0,s5
    8000165a:	9c9ff0ef          	jal	ra,80001022 <walk>
    8000165e:	89aa                	mv	s3,a0
    80001660:	c929                	beqz	a0,800016b2 <vmfault+0x9e>
    80001662:	00053b03          	ld	s6,0(a0)
    80001666:	001b7793          	andi	a5,s6,1
    8000166a:	c7a1                	beqz	a5,800016b2 <vmfault+0x9e>
    return 0;
    8000166c:	4901                	li	s2,0
    if(!read && (*pte & PTE_COW)) {
    8000166e:	fc0a16e3          	bnez	s4,8000163a <vmfault+0x26>
    80001672:	100b7913          	andi	s2,s6,256
    80001676:	fc0902e3          	beqz	s2,8000163a <vmfault+0x26>
      if((mem = (uint64)kalloc()) == 0)
    8000167a:	c84ff0ef          	jal	ra,80000afe <kalloc>
    8000167e:	84aa                	mv	s1,a0
        return 0;
    80001680:	4901                	li	s2,0
      if((mem = (uint64)kalloc()) == 0)
    80001682:	dd45                	beqz	a0,8000163a <vmfault+0x26>
    80001684:	892a                	mv	s2,a0
      pa = PTE2PA(*pte);
    80001686:	00ab5b13          	srli	s6,s6,0xa
    8000168a:	0b32                	slli	s6,s6,0xc
      memmove((void*)mem, (void*)pa, PGSIZE);
    8000168c:	6605                	lui	a2,0x1
    8000168e:	85da                	mv	a1,s6
    80001690:	f72ff0ef          	jal	ra,80000e02 <memmove>
      uint flags = PTE_FLAGS(*pte);
    80001694:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
      flags &= ~PTE_COW;
    80001698:	2ff7f793          	andi	a5,a5,767
      *pte = PA2PTE(mem) | flags;
    8000169c:	0047e793          	ori	a5,a5,4
    800016a0:	80b1                	srli	s1,s1,0xc
    800016a2:	04aa                	slli	s1,s1,0xa
    800016a4:	8cdd                	or	s1,s1,a5
    800016a6:	0099b023          	sd	s1,0(s3)
      kfree((void*)pa);
    800016aa:	855a                	mv	a0,s6
    800016ac:	b10ff0ef          	jal	ra,800009bc <kfree>
      return mem;
    800016b0:	b769                	j	8000163a <vmfault+0x26>
  mem = (uint64) kalloc();
    800016b2:	c4cff0ef          	jal	ra,80000afe <kalloc>
    800016b6:	89aa                	mv	s3,a0
    return 0;
    800016b8:	4901                	li	s2,0
  if(mem == 0)
    800016ba:	d141                	beqz	a0,8000163a <vmfault+0x26>
  mem = (uint64) kalloc();
    800016bc:	892a                	mv	s2,a0
  memset((void *) mem, 0, PGSIZE);
    800016be:	6605                	lui	a2,0x1
    800016c0:	4581                	li	a1,0
    800016c2:	ee4ff0ef          	jal	ra,80000da6 <memset>
  if (mappages(pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800016c6:	4759                	li	a4,22
    800016c8:	86ce                	mv	a3,s3
    800016ca:	6605                	lui	a2,0x1
    800016cc:	85a6                	mv	a1,s1
    800016ce:	8556                	mv	a0,s5
    800016d0:	a2bff0ef          	jal	ra,800010fa <mappages>
    800016d4:	d13d                	beqz	a0,8000163a <vmfault+0x26>
    kfree((void *)mem);
    800016d6:	854e                	mv	a0,s3
    800016d8:	ae4ff0ef          	jal	ra,800009bc <kfree>
    return 0;
    800016dc:	4901                	li	s2,0
    800016de:	bfb1                	j	8000163a <vmfault+0x26>

00000000800016e0 <copyout>:
  while(len > 0){
    800016e0:	c6e9                	beqz	a3,800017aa <copyout+0xca>
{
    800016e2:	711d                	addi	sp,sp,-96
    800016e4:	ec86                	sd	ra,88(sp)
    800016e6:	e8a2                	sd	s0,80(sp)
    800016e8:	e4a6                	sd	s1,72(sp)
    800016ea:	e0ca                	sd	s2,64(sp)
    800016ec:	fc4e                	sd	s3,56(sp)
    800016ee:	f852                	sd	s4,48(sp)
    800016f0:	f456                	sd	s5,40(sp)
    800016f2:	f05a                	sd	s6,32(sp)
    800016f4:	ec5e                	sd	s7,24(sp)
    800016f6:	e862                	sd	s8,16(sp)
    800016f8:	e466                	sd	s9,8(sp)
    800016fa:	e06a                	sd	s10,0(sp)
    800016fc:	1080                	addi	s0,sp,96
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8bae                	mv	s7,a1
    80001702:	8c32                	mv	s8,a2
    80001704:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	797d                	lui	s2,0xfffff
    80001708:	0125f933          	and	s2,a1,s2
    if(va0 >= MAXVA)
    8000170c:	57fd                	li	a5,-1
    8000170e:	83e9                	srli	a5,a5,0x1a
    80001710:	0927ef63          	bltu	a5,s2,800017ae <copyout+0xce>
    80001714:	6d05                	lui	s10,0x1
    80001716:	8cbe                	mv	s9,a5
    80001718:	a015                	j	8000173c <copyout+0x5c>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000171a:	412b8533          	sub	a0,s7,s2
    8000171e:	0009861b          	sext.w	a2,s3
    80001722:	85e2                	mv	a1,s8
    80001724:	9526                	add	a0,a0,s1
    80001726:	edcff0ef          	jal	ra,80000e02 <memmove>
    len -= n;
    8000172a:	413a8ab3          	sub	s5,s5,s3
    src += n;
    8000172e:	9c4e                	add	s8,s8,s3
  while(len > 0){
    80001730:	040a8e63          	beqz	s5,8000178c <copyout+0xac>
    if(va0 >= MAXVA)
    80001734:	074cef63          	bltu	s9,s4,800017b2 <copyout+0xd2>
    va0 = PGROUNDDOWN(dstva);
    80001738:	8952                	mv	s2,s4
    dstva = va0 + PGSIZE;
    8000173a:	8bd2                	mv	s7,s4
    pa0 = walkaddr(pagetable, va0);
    8000173c:	85ca                	mv	a1,s2
    8000173e:	855a                	mv	a0,s6
    80001740:	97dff0ef          	jal	ra,800010bc <walkaddr>
    80001744:	84aa                	mv	s1,a0
    if(pa0 == 0) {
    80001746:	e901                	bnez	a0,80001756 <copyout+0x76>
      if((pa0 = vmfault(pagetable, va0, 1)) == 0) {
    80001748:	4605                	li	a2,1
    8000174a:	85ca                	mv	a1,s2
    8000174c:	855a                	mv	a0,s6
    8000174e:	ec7ff0ef          	jal	ra,80001614 <vmfault>
    80001752:	84aa                	mv	s1,a0
    80001754:	c12d                	beqz	a0,800017b6 <copyout+0xd6>
    pte = walk(pagetable, va0, 0);
    80001756:	4601                	li	a2,0
    80001758:	85ca                	mv	a1,s2
    8000175a:	855a                	mv	a0,s6
    8000175c:	8c7ff0ef          	jal	ra,80001022 <walk>
    if((*pte & PTE_W) == 0) {
    80001760:	611c                	ld	a5,0(a0)
    80001762:	0047f713          	andi	a4,a5,4
    80001766:	eb19                	bnez	a4,8000177c <copyout+0x9c>
      if(*pte & PTE_COW) {
    80001768:	1007f793          	andi	a5,a5,256
    8000176c:	c7b9                	beqz	a5,800017ba <copyout+0xda>
        if((pa0 = vmfault(pagetable, va0, 0)) == 0)
    8000176e:	4601                	li	a2,0
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	ea1ff0ef          	jal	ra,80001614 <vmfault>
    80001778:	84aa                	mv	s1,a0
    8000177a:	c131                	beqz	a0,800017be <copyout+0xde>
    n = PGSIZE - (dstva - va0);
    8000177c:	01a90a33          	add	s4,s2,s10
    80001780:	417a09b3          	sub	s3,s4,s7
    if(n > len)
    80001784:	f93afbe3          	bgeu	s5,s3,8000171a <copyout+0x3a>
    80001788:	89d6                	mv	s3,s5
    8000178a:	bf41                	j	8000171a <copyout+0x3a>
  return 0;
    8000178c:	4501                	li	a0,0
}
    8000178e:	60e6                	ld	ra,88(sp)
    80001790:	6446                	ld	s0,80(sp)
    80001792:	64a6                	ld	s1,72(sp)
    80001794:	6906                	ld	s2,64(sp)
    80001796:	79e2                	ld	s3,56(sp)
    80001798:	7a42                	ld	s4,48(sp)
    8000179a:	7aa2                	ld	s5,40(sp)
    8000179c:	7b02                	ld	s6,32(sp)
    8000179e:	6be2                	ld	s7,24(sp)
    800017a0:	6c42                	ld	s8,16(sp)
    800017a2:	6ca2                	ld	s9,8(sp)
    800017a4:	6d02                	ld	s10,0(sp)
    800017a6:	6125                	addi	sp,sp,96
    800017a8:	8082                	ret
  return 0;
    800017aa:	4501                	li	a0,0
}
    800017ac:	8082                	ret
      return -1;
    800017ae:	557d                	li	a0,-1
    800017b0:	bff9                	j	8000178e <copyout+0xae>
    800017b2:	557d                	li	a0,-1
    800017b4:	bfe9                	j	8000178e <copyout+0xae>
        return -1;
    800017b6:	557d                	li	a0,-1
    800017b8:	bfd9                	j	8000178e <copyout+0xae>
        return -1;
    800017ba:	557d                	li	a0,-1
    800017bc:	bfc9                	j	8000178e <copyout+0xae>
          return -1;
    800017be:	557d                	li	a0,-1
    800017c0:	b7f9                	j	8000178e <copyout+0xae>

00000000800017c2 <copyin>:
  while(len > 0){
    800017c2:	c6c9                	beqz	a3,8000184c <copyin+0x8a>
{
    800017c4:	715d                	addi	sp,sp,-80
    800017c6:	e486                	sd	ra,72(sp)
    800017c8:	e0a2                	sd	s0,64(sp)
    800017ca:	fc26                	sd	s1,56(sp)
    800017cc:	f84a                	sd	s2,48(sp)
    800017ce:	f44e                	sd	s3,40(sp)
    800017d0:	f052                	sd	s4,32(sp)
    800017d2:	ec56                	sd	s5,24(sp)
    800017d4:	e85a                	sd	s6,16(sp)
    800017d6:	e45e                	sd	s7,8(sp)
    800017d8:	e062                	sd	s8,0(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8baa                	mv	s7,a0
    800017de:	8aae                	mv	s5,a1
    800017e0:	8932                	mv	s2,a2
    800017e2:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800017e6:	6b05                	lui	s6,0x1
    800017e8:	a035                	j	80001814 <copyin+0x52>
    800017ea:	412984b3          	sub	s1,s3,s2
    800017ee:	94da                	add	s1,s1,s6
    if(n > len)
    800017f0:	009a7363          	bgeu	s4,s1,800017f6 <copyin+0x34>
    800017f4:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017f6:	413905b3          	sub	a1,s2,s3
    800017fa:	0004861b          	sext.w	a2,s1
    800017fe:	95aa                	add	a1,a1,a0
    80001800:	8556                	mv	a0,s5
    80001802:	e00ff0ef          	jal	ra,80000e02 <memmove>
    len -= n;
    80001806:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000180a:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000180c:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001810:	020a0163          	beqz	s4,80001832 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001814:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ce                	mv	a1,s3
    8000181a:	855e                	mv	a0,s7
    8000181c:	8a1ff0ef          	jal	ra,800010bc <walkaddr>
    if(pa0 == 0) {
    80001820:	f569                	bnez	a0,800017ea <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 1)) == 0) {
    80001822:	4605                	li	a2,1
    80001824:	85ce                	mv	a1,s3
    80001826:	855e                	mv	a0,s7
    80001828:	dedff0ef          	jal	ra,80001614 <vmfault>
    8000182c:	fd5d                	bnez	a0,800017ea <copyin+0x28>
        return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	a011                	j	80001834 <copyin+0x72>
  return 0;
    80001832:	4501                	li	a0,0
}
    80001834:	60a6                	ld	ra,72(sp)
    80001836:	6406                	ld	s0,64(sp)
    80001838:	74e2                	ld	s1,56(sp)
    8000183a:	7942                	ld	s2,48(sp)
    8000183c:	79a2                	ld	s3,40(sp)
    8000183e:	7a02                	ld	s4,32(sp)
    80001840:	6ae2                	ld	s5,24(sp)
    80001842:	6b42                	ld	s6,16(sp)
    80001844:	6ba2                	ld	s7,8(sp)
    80001846:	6c02                	ld	s8,0(sp)
    80001848:	6161                	addi	sp,sp,80
    8000184a:	8082                	ret
  return 0;
    8000184c:	4501                	li	a0,0
}
    8000184e:	8082                	ret

0000000080001850 <ismapped>:

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001850:	1141                	addi	sp,sp,-16
    80001852:	e406                	sd	ra,8(sp)
    80001854:	e022                	sd	s0,0(sp)
    80001856:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001858:	4601                	li	a2,0
    8000185a:	fc8ff0ef          	jal	ra,80001022 <walk>
  if (pte == 0) {
    8000185e:	c519                	beqz	a0,8000186c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001860:	6108                	ld	a0,0(a0)
    return 0;
    80001862:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001864:	60a2                	ld	ra,8(sp)
    80001866:	6402                	ld	s0,0(sp)
    80001868:	0141                	addi	sp,sp,16
    8000186a:	8082                	ret
    return 0;
    8000186c:	4501                	li	a0,0
    8000186e:	bfdd                	j	80001864 <ismapped+0x14>

0000000080001870 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001870:	7139                	addi	sp,sp,-64
    80001872:	fc06                	sd	ra,56(sp)
    80001874:	f822                	sd	s0,48(sp)
    80001876:	f426                	sd	s1,40(sp)
    80001878:	f04a                	sd	s2,32(sp)
    8000187a:	ec4e                	sd	s3,24(sp)
    8000187c:	e852                	sd	s4,16(sp)
    8000187e:	e456                	sd	s5,8(sp)
    80001880:	e05a                	sd	s6,0(sp)
    80001882:	0080                	addi	s0,sp,64
    80001884:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	00099497          	auipc	s1,0x99
    8000188a:	b9248493          	addi	s1,s1,-1134 # 8009a418 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000188e:	8b26                	mv	s6,s1
    80001890:	00005a97          	auipc	s5,0x5
    80001894:	770a8a93          	addi	s5,s5,1904 # 80007000 <etext>
    80001898:	04000937          	lui	s2,0x4000
    8000189c:	197d                	addi	s2,s2,-1
    8000189e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	0009fa17          	auipc	s4,0x9f
    800018a4:	978a0a13          	addi	s4,s4,-1672 # 800a0218 <tickslock>
    char *pa = kalloc();
    800018a8:	a56ff0ef          	jal	ra,80000afe <kalloc>
    800018ac:	862a                	mv	a2,a0
    if(pa == 0)
    800018ae:	c121                	beqz	a0,800018ee <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	416485b3          	sub	a1,s1,s6
    800018b4:	858d                	srai	a1,a1,0x3
    800018b6:	000ab783          	ld	a5,0(s5)
    800018ba:	02f585b3          	mul	a1,a1,a5
    800018be:	2585                	addiw	a1,a1,1
    800018c0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c4:	4719                	li	a4,6
    800018c6:	6685                	lui	a3,0x1
    800018c8:	40b905b3          	sub	a1,s2,a1
    800018cc:	854e                	mv	a0,s3
    800018ce:	8ddff0ef          	jal	ra,800011aa <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d2:	17848493          	addi	s1,s1,376
    800018d6:	fd4499e3          	bne	s1,s4,800018a8 <proc_mapstacks+0x38>
  }
}
    800018da:	70e2                	ld	ra,56(sp)
    800018dc:	7442                	ld	s0,48(sp)
    800018de:	74a2                	ld	s1,40(sp)
    800018e0:	7902                	ld	s2,32(sp)
    800018e2:	69e2                	ld	s3,24(sp)
    800018e4:	6a42                	ld	s4,16(sp)
    800018e6:	6aa2                	ld	s5,8(sp)
    800018e8:	6b02                	ld	s6,0(sp)
    800018ea:	6121                	addi	sp,sp,64
    800018ec:	8082                	ret
      panic("kalloc");
    800018ee:	00006517          	auipc	a0,0x6
    800018f2:	8c250513          	addi	a0,a0,-1854 # 800071b0 <digits+0x178>
    800018f6:	e95fe0ef          	jal	ra,8000078a <panic>

00000000800018fa <procinit>:
struct shm_region shm_regions[MAX_SHM];

// initialize the proc table.
void
procinit(void)
{
    800018fa:	7139                	addi	sp,sp,-64
    800018fc:	fc06                	sd	ra,56(sp)
    800018fe:	f822                	sd	s0,48(sp)
    80001900:	f426                	sd	s1,40(sp)
    80001902:	f04a                	sd	s2,32(sp)
    80001904:	ec4e                	sd	s3,24(sp)
    80001906:	e852                	sd	s4,16(sp)
    80001908:	e456                	sd	s5,8(sp)
    8000190a:	e05a                	sd	s6,0(sp)
    8000190c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000190e:	00006597          	auipc	a1,0x6
    80001912:	8aa58593          	addi	a1,a1,-1878 # 800071b8 <digits+0x180>
    80001916:	00096517          	auipc	a0,0x96
    8000191a:	11250513          	addi	a0,a0,274 # 80097a28 <pid_lock>
    8000191e:	b34ff0ef          	jal	ra,80000c52 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001922:	00006597          	auipc	a1,0x6
    80001926:	89e58593          	addi	a1,a1,-1890 # 800071c0 <digits+0x188>
    8000192a:	00096517          	auipc	a0,0x96
    8000192e:	11650513          	addi	a0,a0,278 # 80097a40 <wait_lock>
    80001932:	b20ff0ef          	jal	ra,80000c52 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	00099497          	auipc	s1,0x99
    8000193a:	ae248493          	addi	s1,s1,-1310 # 8009a418 <proc>
      initlock(&p->lock, "proc");
    8000193e:	00006b17          	auipc	s6,0x6
    80001942:	892b0b13          	addi	s6,s6,-1902 # 800071d0 <digits+0x198>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001946:	8aa6                	mv	s5,s1
    80001948:	00005a17          	auipc	s4,0x5
    8000194c:	6b8a0a13          	addi	s4,s4,1720 # 80007000 <etext>
    80001950:	04000937          	lui	s2,0x4000
    80001954:	197d                	addi	s2,s2,-1
    80001956:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	0009f997          	auipc	s3,0x9f
    8000195c:	8c098993          	addi	s3,s3,-1856 # 800a0218 <tickslock>
      initlock(&p->lock, "proc");
    80001960:	85da                	mv	a1,s6
    80001962:	8526                	mv	a0,s1
    80001964:	aeeff0ef          	jal	ra,80000c52 <initlock>
      p->state = UNUSED;
    80001968:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	878d                	srai	a5,a5,0x3
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	17848493          	addi	s1,s1,376
    8000198a:	fd349be3          	bne	s1,s3,80001960 <procinit+0x66>
    8000198e:	00096497          	auipc	s1,0x96
    80001992:	60a48493          	addi	s1,s1,1546 # 80097f98 <mailboxes>
    80001996:	00099997          	auipc	s3,0x99
    8000199a:	a8298993          	addi	s3,s3,-1406 # 8009a418 <proc>
  }

  // MiniOS: Initialize IPC mailboxes and shared memory regions.
  for(int i = 0; i < MAX_MBX; i++){
    initlock(&mailboxes[i].lock, "mailbox");
    8000199e:	00006917          	auipc	s2,0x6
    800019a2:	83a90913          	addi	s2,s2,-1990 # 800071d8 <digits+0x1a0>
    800019a6:	85ca                	mv	a1,s2
    800019a8:	8526                	mv	a0,s1
    800019aa:	aa8ff0ef          	jal	ra,80000c52 <initlock>
    mailboxes[i].owner_pid = 0;
    800019ae:	2404a223          	sw	zero,580(s1)
    mailboxes[i].head = mailboxes[i].tail = mailboxes[i].count = 0;
    800019b2:	2404a023          	sw	zero,576(s1)
    800019b6:	2204ae23          	sw	zero,572(s1)
    800019ba:	2204ac23          	sw	zero,568(s1)
  for(int i = 0; i < MAX_MBX; i++){
    800019be:	24848493          	addi	s1,s1,584
    800019c2:	ff3492e3          	bne	s1,s3,800019a6 <procinit+0xac>
    800019c6:	00096497          	auipc	s1,0x96
    800019ca:	0a248493          	addi	s1,s1,162 # 80097a68 <shm_regions+0x10>
    800019ce:	00096997          	auipc	s3,0x96
    800019d2:	1da98993          	addi	s3,s3,474 # 80097ba8 <cpus+0x10>
  }
  for(int i = 0; i < MAX_SHM; i++){
    initlock(&shm_regions[i].lock, "shm_region");
    800019d6:	00006917          	auipc	s2,0x6
    800019da:	80a90913          	addi	s2,s2,-2038 # 800071e0 <digits+0x1a8>
    800019de:	85ca                	mv	a1,s2
    800019e0:	8526                	mv	a0,s1
    800019e2:	a70ff0ef          	jal	ra,80000c52 <initlock>
    shm_regions[i].ref_cnt = 0;
    800019e6:	fe04ae23          	sw	zero,-4(s1)
    shm_regions[i].pa = 0;
    800019ea:	fe04b823          	sd	zero,-16(s1)
    shm_regions[i].key = 0;
    800019ee:	fe04ac23          	sw	zero,-8(s1)
  for(int i = 0; i < MAX_SHM; i++){
    800019f2:	02848493          	addi	s1,s1,40
    800019f6:	ff3494e3          	bne	s1,s3,800019de <procinit+0xe4>
  }
}
    800019fa:	70e2                	ld	ra,56(sp)
    800019fc:	7442                	ld	s0,48(sp)
    800019fe:	74a2                	ld	s1,40(sp)
    80001a00:	7902                	ld	s2,32(sp)
    80001a02:	69e2                	ld	s3,24(sp)
    80001a04:	6a42                	ld	s4,16(sp)
    80001a06:	6aa2                	ld	s5,8(sp)
    80001a08:	6b02                	ld	s6,0(sp)
    80001a0a:	6121                	addi	sp,sp,64
    80001a0c:	8082                	ret

0000000080001a0e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a0e:	1141                	addi	sp,sp,-16
    80001a10:	e422                	sd	s0,8(sp)
    80001a12:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a14:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a16:	2501                	sext.w	a0,a0
    80001a18:	6422                	ld	s0,8(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret

0000000080001a1e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
    80001a24:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a26:	2781                	sext.w	a5,a5
    80001a28:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a2a:	00096517          	auipc	a0,0x96
    80001a2e:	16e50513          	addi	a0,a0,366 # 80097b98 <cpus>
    80001a32:	953e                	add	a0,a0,a5
    80001a34:	6422                	ld	s0,8(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret

0000000080001a3a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a3a:	1101                	addi	sp,sp,-32
    80001a3c:	ec06                	sd	ra,24(sp)
    80001a3e:	e822                	sd	s0,16(sp)
    80001a40:	e426                	sd	s1,8(sp)
    80001a42:	1000                	addi	s0,sp,32
  push_off();
    80001a44:	a4eff0ef          	jal	ra,80000c92 <push_off>
    80001a48:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a4a:	2781                	sext.w	a5,a5
    80001a4c:	079e                	slli	a5,a5,0x7
    80001a4e:	00096717          	auipc	a4,0x96
    80001a52:	fda70713          	addi	a4,a4,-38 # 80097a28 <pid_lock>
    80001a56:	97ba                	add	a5,a5,a4
    80001a58:	1707b483          	ld	s1,368(a5)
  pop_off();
    80001a5c:	abaff0ef          	jal	ra,80000d16 <pop_off>
  return p;
}
    80001a60:	8526                	mv	a0,s1
    80001a62:	60e2                	ld	ra,24(sp)
    80001a64:	6442                	ld	s0,16(sp)
    80001a66:	64a2                	ld	s1,8(sp)
    80001a68:	6105                	addi	sp,sp,32
    80001a6a:	8082                	ret

0000000080001a6c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a6c:	7179                	addi	sp,sp,-48
    80001a6e:	f406                	sd	ra,40(sp)
    80001a70:	f022                	sd	s0,32(sp)
    80001a72:	ec26                	sd	s1,24(sp)
    80001a74:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001a76:	fc5ff0ef          	jal	ra,80001a3a <myproc>
    80001a7a:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001a7c:	aeeff0ef          	jal	ra,80000d6a <release>

  if (first) {
    80001a80:	00006797          	auipc	a5,0x6
    80001a84:	e607a783          	lw	a5,-416(a5) # 800078e0 <first.1>
    80001a88:	cf8d                	beqz	a5,80001ac2 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001a8a:	4505                	li	a0,1
    80001a8c:	176020ef          	jal	ra,80003c02 <fsinit>

    first = 0;
    80001a90:	00006797          	auipc	a5,0x6
    80001a94:	e407a823          	sw	zero,-432(a5) # 800078e0 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001a98:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001a9c:	00005517          	auipc	a0,0x5
    80001aa0:	75450513          	addi	a0,a0,1876 # 800071f0 <digits+0x1b8>
    80001aa4:	fca43823          	sd	a0,-48(s0)
    80001aa8:	fc043c23          	sd	zero,-40(s0)
    80001aac:	fd040593          	addi	a1,s0,-48
    80001ab0:	1fa030ef          	jal	ra,80004caa <kexec>
    80001ab4:	6cbc                	ld	a5,88(s1)
    80001ab6:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001ab8:	6cbc                	ld	a5,88(s1)
    80001aba:	7bb8                	ld	a4,112(a5)
    80001abc:	57fd                	li	a5,-1
    80001abe:	02f70d63          	beq	a4,a5,80001af8 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001ac2:	08a010ef          	jal	ra,80002b4c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001ac6:	68a8                	ld	a0,80(s1)
    80001ac8:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001aca:	04000737          	lui	a4,0x4000
    80001ace:	00004797          	auipc	a5,0x4
    80001ad2:	5ce78793          	addi	a5,a5,1486 # 8000609c <userret>
    80001ad6:	00004697          	auipc	a3,0x4
    80001ada:	52a68693          	addi	a3,a3,1322 # 80006000 <_trampoline>
    80001ade:	8f95                	sub	a5,a5,a3
    80001ae0:	177d                	addi	a4,a4,-1
    80001ae2:	0732                	slli	a4,a4,0xc
    80001ae4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001ae6:	577d                	li	a4,-1
    80001ae8:	177e                	slli	a4,a4,0x3f
    80001aea:	8d59                	or	a0,a0,a4
    80001aec:	9782                	jalr	a5
}
    80001aee:	70a2                	ld	ra,40(sp)
    80001af0:	7402                	ld	s0,32(sp)
    80001af2:	64e2                	ld	s1,24(sp)
    80001af4:	6145                	addi	sp,sp,48
    80001af6:	8082                	ret
      panic("exec");
    80001af8:	00005517          	auipc	a0,0x5
    80001afc:	70050513          	addi	a0,a0,1792 # 800071f8 <digits+0x1c0>
    80001b00:	c8bfe0ef          	jal	ra,8000078a <panic>

0000000080001b04 <allocpid>:
{
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b10:	00096917          	auipc	s2,0x96
    80001b14:	f1890913          	addi	s2,s2,-232 # 80097a28 <pid_lock>
    80001b18:	854a                	mv	a0,s2
    80001b1a:	9b8ff0ef          	jal	ra,80000cd2 <acquire>
  pid = nextpid;
    80001b1e:	00006797          	auipc	a5,0x6
    80001b22:	dc678793          	addi	a5,a5,-570 # 800078e4 <nextpid>
    80001b26:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b28:	0014871b          	addiw	a4,s1,1
    80001b2c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b2e:	854a                	mv	a0,s2
    80001b30:	a3aff0ef          	jal	ra,80000d6a <release>
}
    80001b34:	8526                	mv	a0,s1
    80001b36:	60e2                	ld	ra,24(sp)
    80001b38:	6442                	ld	s0,16(sp)
    80001b3a:	64a2                	ld	s1,8(sp)
    80001b3c:	6902                	ld	s2,0(sp)
    80001b3e:	6105                	addi	sp,sp,32
    80001b40:	8082                	ret

0000000080001b42 <proc_pagetable>:
{
    80001b42:	1101                	addi	sp,sp,-32
    80001b44:	ec06                	sd	ra,24(sp)
    80001b46:	e822                	sd	s0,16(sp)
    80001b48:	e426                	sd	s1,8(sp)
    80001b4a:	e04a                	sd	s2,0(sp)
    80001b4c:	1000                	addi	s0,sp,32
    80001b4e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b50:	f50ff0ef          	jal	ra,800012a0 <uvmcreate>
    80001b54:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b56:	cd05                	beqz	a0,80001b8e <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b58:	4729                	li	a4,10
    80001b5a:	00004697          	auipc	a3,0x4
    80001b5e:	4a668693          	addi	a3,a3,1190 # 80006000 <_trampoline>
    80001b62:	6605                	lui	a2,0x1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	d8eff0ef          	jal	ra,800010fa <mappages>
    80001b70:	02054663          	bltz	a0,80001b9c <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b74:	4719                	li	a4,6
    80001b76:	05893683          	ld	a3,88(s2)
    80001b7a:	6605                	lui	a2,0x1
    80001b7c:	020005b7          	lui	a1,0x2000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b6                	slli	a1,a1,0xd
    80001b84:	8526                	mv	a0,s1
    80001b86:	d74ff0ef          	jal	ra,800010fa <mappages>
    80001b8a:	00054f63          	bltz	a0,80001ba8 <proc_pagetable+0x66>
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6902                	ld	s2,0(sp)
    80001b98:	6105                	addi	sp,sp,32
    80001b9a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b9c:	4581                	li	a1,0
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	8dfff0ef          	jal	ra,8000147e <uvmfree>
    return 0;
    80001ba4:	4481                	li	s1,0
    80001ba6:	b7e5                	j	80001b8e <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	040005b7          	lui	a1,0x4000
    80001bb0:	15fd                	addi	a1,a1,-1
    80001bb2:	05b2                	slli	a1,a1,0xc
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	f10ff0ef          	jal	ra,800012c6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bba:	4581                	li	a1,0
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	8c1ff0ef          	jal	ra,8000147e <uvmfree>
    return 0;
    80001bc2:	4481                	li	s1,0
    80001bc4:	b7e9                	j	80001b8e <proc_pagetable+0x4c>

0000000080001bc6 <proc_freepagetable>:
{
    80001bc6:	1101                	addi	sp,sp,-32
    80001bc8:	ec06                	sd	ra,24(sp)
    80001bca:	e822                	sd	s0,16(sp)
    80001bcc:	e426                	sd	s1,8(sp)
    80001bce:	e04a                	sd	s2,0(sp)
    80001bd0:	1000                	addi	s0,sp,32
    80001bd2:	84aa                	mv	s1,a0
    80001bd4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bd6:	4681                	li	a3,0
    80001bd8:	4605                	li	a2,1
    80001bda:	040005b7          	lui	a1,0x4000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b2                	slli	a1,a1,0xc
    80001be2:	ee4ff0ef          	jal	ra,800012c6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001be6:	4681                	li	a3,0
    80001be8:	4605                	li	a2,1
    80001bea:	020005b7          	lui	a1,0x2000
    80001bee:	15fd                	addi	a1,a1,-1
    80001bf0:	05b6                	slli	a1,a1,0xd
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	ed2ff0ef          	jal	ra,800012c6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bf8:	85ca                	mv	a1,s2
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	883ff0ef          	jal	ra,8000147e <uvmfree>
}
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6902                	ld	s2,0(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret

0000000080001c0c <freeproc>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	1000                	addi	s0,sp,32
    80001c16:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c18:	6d28                	ld	a0,88(a0)
    80001c1a:	c119                	beqz	a0,80001c20 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001c1c:	da1fe0ef          	jal	ra,800009bc <kfree>
  p->trapframe = 0;
    80001c20:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c24:	68a8                	ld	a0,80(s1)
    80001c26:	c501                	beqz	a0,80001c2e <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001c28:	64ac                	ld	a1,72(s1)
    80001c2a:	f9dff0ef          	jal	ra,80001bc6 <proc_freepagetable>
  p->pagetable = 0;
    80001c2e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c32:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c36:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c3a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c3e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c42:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c46:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c4a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c4e:	0004ac23          	sw	zero,24(s1)
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00098497          	auipc	s1,0x98
    80001c6c:	7b048493          	addi	s1,s1,1968 # 8009a418 <proc>
    80001c70:	0009e917          	auipc	s2,0x9e
    80001c74:	5a890913          	addi	s2,s2,1448 # 800a0218 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	858ff0ef          	jal	ra,80000cd2 <acquire>
    if(p->state == UNUSED) {
    80001c7e:	4c9c                	lw	a5,24(s1)
    80001c80:	cb91                	beqz	a5,80001c94 <allocproc+0x38>
      release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	8e6ff0ef          	jal	ra,80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c88:	17848493          	addi	s1,s1,376
    80001c8c:	ff2496e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c90:	4481                	li	s1,0
    80001c92:	a889                	j	80001ce4 <allocproc+0x88>
  p->pid = allocpid();
    80001c94:	e71ff0ef          	jal	ra,80001b04 <allocpid>
    80001c98:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c9a:	4785                	li	a5,1
    80001c9c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c9e:	e61fe0ef          	jal	ra,80000afe <kalloc>
    80001ca2:	892a                	mv	s2,a0
    80001ca4:	eca8                	sd	a0,88(s1)
    80001ca6:	c531                	beqz	a0,80001cf2 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	e99ff0ef          	jal	ra,80001b42 <proc_pagetable>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb2:	c921                	beqz	a0,80001d02 <allocproc+0xa6>
  memset(&p->context, 0, sizeof(p->context));
    80001cb4:	07000613          	li	a2,112
    80001cb8:	4581                	li	a1,0
    80001cba:	06048513          	addi	a0,s1,96
    80001cbe:	8e8ff0ef          	jal	ra,80000da6 <memset>
  p->context.ra = (uint64)forkret;
    80001cc2:	00000797          	auipc	a5,0x0
    80001cc6:	daa78793          	addi	a5,a5,-598 # 80001a6c <forkret>
    80001cca:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ccc:	60bc                	ld	a5,64(s1)
    80001cce:	6705                	lui	a4,0x1
    80001cd0:	97ba                	add	a5,a5,a4
    80001cd2:	f4bc                	sd	a5,104(s1)
  p->priority   = SCHED_DEFAULT;
    80001cd4:	03c00793          	li	a5,60
    80001cd8:	16f4a423          	sw	a5,360(s1)
  p->wait_ticks = 0;
    80001cdc:	1604a623          	sw	zero,364(s1)
  p->cpu_ticks  = 0;
    80001ce0:	1604a823          	sw	zero,368(s1)
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    freeproc(p);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	f19ff0ef          	jal	ra,80001c0c <freeproc>
    release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	870ff0ef          	jal	ra,80000d6a <release>
    return 0;
    80001cfe:	84ca                	mv	s1,s2
    80001d00:	b7d5                	j	80001ce4 <allocproc+0x88>
    freeproc(p);
    80001d02:	8526                	mv	a0,s1
    80001d04:	f09ff0ef          	jal	ra,80001c0c <freeproc>
    release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	860ff0ef          	jal	ra,80000d6a <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bfd1                	j	80001ce4 <allocproc+0x88>

0000000080001d12 <userinit>:
{
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d1c:	f41ff0ef          	jal	ra,80001c5c <allocproc>
    80001d20:	84aa                	mv	s1,a0
  initproc = p;
    80001d22:	00006797          	auipc	a5,0x6
    80001d26:	bea7bb23          	sd	a0,-1034(a5) # 80007918 <initproc>
  p->cwd = namei("/");
    80001d2a:	00005517          	auipc	a0,0x5
    80001d2e:	4d650513          	addi	a0,a0,1238 # 80007200 <digits+0x1c8>
    80001d32:	3ce020ef          	jal	ra,80004100 <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	478d                	li	a5,3
    80001d3c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	82aff0ef          	jal	ra,80000d6a <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5c:	cdfff0ef          	jal	ra,80001a3a <myproc>
    80001d60:	892a                	mv	s2,a0
  sz = p->sz;
    80001d62:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d64:	02905963          	blez	s1,80001d96 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001d68:	00b48633          	add	a2,s1,a1
    80001d6c:	020007b7          	lui	a5,0x2000
    80001d70:	17fd                	addi	a5,a5,-1
    80001d72:	07b6                	slli	a5,a5,0xd
    80001d74:	02c7ea63          	bltu	a5,a2,80001da8 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d78:	4691                	li	a3,4
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	e0aff0ef          	jal	ra,80001386 <uvmalloc>
    80001d80:	85aa                	mv	a1,a0
    80001d82:	c50d                	beqz	a0,80001dac <growproc+0x5e>
  p->sz = sz;
    80001d84:	04b93423          	sd	a1,72(s2)
  return 0;
    80001d88:	4501                	li	a0,0
}
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6902                	ld	s2,0(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret
  } else if(n < 0){
    80001d96:	fe04d7e3          	bgez	s1,80001d84 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9a:	00b48633          	add	a2,s1,a1
    80001d9e:	6928                	ld	a0,80(a0)
    80001da0:	da2ff0ef          	jal	ra,80001342 <uvmdealloc>
    80001da4:	85aa                	mv	a1,a0
    80001da6:	bff9                	j	80001d84 <growproc+0x36>
      return -1;
    80001da8:	557d                	li	a0,-1
    80001daa:	b7c5                	j	80001d8a <growproc+0x3c>
      return -1;
    80001dac:	557d                	li	a0,-1
    80001dae:	bff1                	j	80001d8a <growproc+0x3c>

0000000080001db0 <kfork>:
{
    80001db0:	7139                	addi	sp,sp,-64
    80001db2:	fc06                	sd	ra,56(sp)
    80001db4:	f822                	sd	s0,48(sp)
    80001db6:	f426                	sd	s1,40(sp)
    80001db8:	f04a                	sd	s2,32(sp)
    80001dba:	ec4e                	sd	s3,24(sp)
    80001dbc:	e852                	sd	s4,16(sp)
    80001dbe:	e456                	sd	s5,8(sp)
    80001dc0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc2:	c79ff0ef          	jal	ra,80001a3a <myproc>
    80001dc6:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dc8:	e95ff0ef          	jal	ra,80001c5c <allocproc>
    80001dcc:	0e050e63          	beqz	a0,80001ec8 <kfork+0x118>
    80001dd0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd2:	048ab603          	ld	a2,72(s5)
    80001dd6:	692c                	ld	a1,80(a0)
    80001dd8:	050ab503          	ld	a0,80(s5)
    80001ddc:	ed2ff0ef          	jal	ra,800014ae <uvmcopy>
    80001de0:	04054863          	bltz	a0,80001e30 <kfork+0x80>
  np->sz = p->sz;
    80001de4:	048ab783          	ld	a5,72(s5)
    80001de8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dec:	058ab683          	ld	a3,88(s5)
    80001df0:	87b6                	mv	a5,a3
    80001df2:	0589b703          	ld	a4,88(s3)
    80001df6:	12068693          	addi	a3,a3,288
    80001dfa:	0007b803          	ld	a6,0(a5) # 2000000 <_entry-0x7e000000>
    80001dfe:	6788                	ld	a0,8(a5)
    80001e00:	6b8c                	ld	a1,16(a5)
    80001e02:	6f90                	ld	a2,24(a5)
    80001e04:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001e08:	e708                	sd	a0,8(a4)
    80001e0a:	eb0c                	sd	a1,16(a4)
    80001e0c:	ef10                	sd	a2,24(a4)
    80001e0e:	02078793          	addi	a5,a5,32
    80001e12:	02070713          	addi	a4,a4,32
    80001e16:	fed792e3          	bne	a5,a3,80001dfa <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001e1a:	0589b783          	ld	a5,88(s3)
    80001e1e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e22:	0d0a8493          	addi	s1,s5,208
    80001e26:	0d098913          	addi	s2,s3,208
    80001e2a:	150a8a13          	addi	s4,s5,336
    80001e2e:	a829                	j	80001e48 <kfork+0x98>
    freeproc(np);
    80001e30:	854e                	mv	a0,s3
    80001e32:	ddbff0ef          	jal	ra,80001c0c <freeproc>
    release(&np->lock);
    80001e36:	854e                	mv	a0,s3
    80001e38:	f33fe0ef          	jal	ra,80000d6a <release>
    return -1;
    80001e3c:	597d                	li	s2,-1
    80001e3e:	a89d                	j	80001eb4 <kfork+0x104>
  for(i = 0; i < NOFILE; i++)
    80001e40:	04a1                	addi	s1,s1,8
    80001e42:	0921                	addi	s2,s2,8
    80001e44:	01448963          	beq	s1,s4,80001e56 <kfork+0xa6>
    if(p->ofile[i])
    80001e48:	6088                	ld	a0,0(s1)
    80001e4a:	d97d                	beqz	a0,80001e40 <kfork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4c:	06d020ef          	jal	ra,800046b8 <filedup>
    80001e50:	00a93023          	sd	a0,0(s2)
    80001e54:	b7f5                	j	80001e40 <kfork+0x90>
  np->cwd = idup(p->cwd);
    80001e56:	150ab503          	ld	a0,336(s5)
    80001e5a:	283010ef          	jal	ra,800038dc <idup>
    80001e5e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e62:	4641                	li	a2,16
    80001e64:	158a8593          	addi	a1,s5,344
    80001e68:	15898513          	addi	a0,s3,344
    80001e6c:	880ff0ef          	jal	ra,80000eec <safestrcpy>
  np->priority   = p->priority;
    80001e70:	168aa783          	lw	a5,360(s5)
    80001e74:	16f9a423          	sw	a5,360(s3)
  np->wait_ticks = 0;
    80001e78:	1609a623          	sw	zero,364(s3)
  np->cpu_ticks  = 0;
    80001e7c:	1609a823          	sw	zero,368(s3)
  pid = np->pid;
    80001e80:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e84:	854e                	mv	a0,s3
    80001e86:	ee5fe0ef          	jal	ra,80000d6a <release>
  acquire(&wait_lock);
    80001e8a:	00096497          	auipc	s1,0x96
    80001e8e:	bb648493          	addi	s1,s1,-1098 # 80097a40 <wait_lock>
    80001e92:	8526                	mv	a0,s1
    80001e94:	e3ffe0ef          	jal	ra,80000cd2 <acquire>
  np->parent = p;
    80001e98:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	ecdfe0ef          	jal	ra,80000d6a <release>
  acquire(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	e2ffe0ef          	jal	ra,80000cd2 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	ebbfe0ef          	jal	ra,80000d6a <release>
}
    80001eb4:	854a                	mv	a0,s2
    80001eb6:	70e2                	ld	ra,56(sp)
    80001eb8:	7442                	ld	s0,48(sp)
    80001eba:	74a2                	ld	s1,40(sp)
    80001ebc:	7902                	ld	s2,32(sp)
    80001ebe:	69e2                	ld	s3,24(sp)
    80001ec0:	6a42                	ld	s4,16(sp)
    80001ec2:	6aa2                	ld	s5,8(sp)
    80001ec4:	6121                	addi	sp,sp,64
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	597d                	li	s2,-1
    80001eca:	b7ed                	j	80001eb4 <kfork+0x104>

0000000080001ecc <scheduler>:
{
    80001ecc:	711d                	addi	sp,sp,-96
    80001ece:	ec86                	sd	ra,88(sp)
    80001ed0:	e8a2                	sd	s0,80(sp)
    80001ed2:	e4a6                	sd	s1,72(sp)
    80001ed4:	e0ca                	sd	s2,64(sp)
    80001ed6:	fc4e                	sd	s3,56(sp)
    80001ed8:	f852                	sd	s4,48(sp)
    80001eda:	f456                	sd	s5,40(sp)
    80001edc:	f05a                	sd	s6,32(sp)
    80001ede:	ec5e                	sd	s7,24(sp)
    80001ee0:	e862                	sd	s8,16(sp)
    80001ee2:	e466                	sd	s9,8(sp)
    80001ee4:	1080                	addi	s0,sp,96
    80001ee6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eea:	00779c13          	slli	s8,a5,0x7
    80001eee:	00096717          	auipc	a4,0x96
    80001ef2:	b3a70713          	addi	a4,a4,-1222 # 80097a28 <pid_lock>
    80001ef6:	9762                	add	a4,a4,s8
    80001ef8:	16073823          	sd	zero,368(a4)
      swtch(&c->context, &best->context);
    80001efc:	00096717          	auipc	a4,0x96
    80001f00:	ca470713          	addi	a4,a4,-860 # 80097ba0 <cpus+0x8>
    80001f04:	9c3a                	add	s8,s8,a4
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f06:	0009e997          	auipc	s3,0x9e
    80001f0a:	31298993          	addi	s3,s3,786 # 800a0218 <tickslock>
      c->proc = best;
    80001f0e:	079e                	slli	a5,a5,0x7
    80001f10:	00096b17          	auipc	s6,0x96
    80001f14:	b18b0b13          	addi	s6,s6,-1256 # 80097a28 <pid_lock>
    80001f18:	9b3e                	add	s6,s6,a5
      window_tick++;
    80001f1a:	00006b97          	auipc	s7,0x6
    80001f1e:	9f6b8b93          	addi	s7,s7,-1546 # 80007910 <window_tick.2>
    80001f22:	a0b9                	j	80001f70 <scheduler+0xa4>
      release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	e45fe0ef          	jal	ra,80000d6a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f2a:	17848493          	addi	s1,s1,376
    80001f2e:	03348763          	beq	s1,s3,80001f5c <scheduler+0x90>
      acquire(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	d9ffe0ef          	jal	ra,80000cd2 <acquire>
      if(p->state == RUNNABLE) {
    80001f38:	4c9c                	lw	a5,24(s1)
    80001f3a:	ff4795e3          	bne	a5,s4,80001f24 <scheduler+0x58>
        if(best == 0 || p->priority > best->priority){
    80001f3e:	00090d63          	beqz	s2,80001f58 <scheduler+0x8c>
    80001f42:	1684a703          	lw	a4,360(s1)
    80001f46:	16892783          	lw	a5,360(s2)
    80001f4a:	fce7dde3          	bge	a5,a4,80001f24 <scheduler+0x58>
          if(best) release(&best->lock);
    80001f4e:	854a                	mv	a0,s2
    80001f50:	e1bfe0ef          	jal	ra,80000d6a <release>
    80001f54:	8926                	mv	s2,s1
    80001f56:	bfd1                	j	80001f2a <scheduler+0x5e>
    80001f58:	8926                	mv	s2,s1
    80001f5a:	bfc1                	j	80001f2a <scheduler+0x5e>
    if(best) {
    80001f5c:	02091063          	bnez	s2,80001f7c <scheduler+0xb0>
    release(&wait_lock);
    80001f60:	00096517          	auipc	a0,0x96
    80001f64:	ae050513          	addi	a0,a0,-1312 # 80097a40 <wait_lock>
    80001f68:	e03fe0ef          	jal	ra,80000d6a <release>
      asm volatile("wfi");
    80001f6c:	10500073          	wfi
    acquire(&wait_lock); // must be acquired before any p->lock.
    80001f70:	00096a97          	auipc	s5,0x96
    80001f74:	ad0a8a93          	addi	s5,s5,-1328 # 80097a40 <wait_lock>
      if(p->state == RUNNABLE) {
    80001f78:	4a0d                	li	s4,3
    80001f7a:	a0d9                	j	80002040 <scheduler+0x174>
      for(p = proc; p < &proc[NPROC]; p++){
    80001f7c:	00098497          	auipc	s1,0x98
    80001f80:	49c48493          	addi	s1,s1,1180 # 8009a418 <proc>
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    80001f84:	06400c93          	li	s9,100
    80001f88:	a811                	j	80001f9c <scheduler+0xd0>
    80001f8a:	1794a423          	sw	s9,360(s1)
          release(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	ddbfe0ef          	jal	ra,80000d6a <release>
      for(p = proc; p < &proc[NPROC]; p++){
    80001f94:	17848493          	addi	s1,s1,376
    80001f98:	03348963          	beq	s1,s3,80001fca <scheduler+0xfe>
        if(p != best){
    80001f9c:	fe990ce3          	beq	s2,s1,80001f94 <scheduler+0xc8>
          acquire(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	d31fe0ef          	jal	ra,80000cd2 <acquire>
          if(p->state == RUNNABLE){
    80001fa6:	4c9c                	lw	a5,24(s1)
    80001fa8:	ff4793e3          	bne	a5,s4,80001f8e <scheduler+0xc2>
            p->wait_ticks++;
    80001fac:	16c4a783          	lw	a5,364(s1)
    80001fb0:	2785                	addiw	a5,a5,1
    80001fb2:	16f4a623          	sw	a5,364(s1)
            p->priority += SCHED_ALPHA;
    80001fb6:	1684a783          	lw	a5,360(s1)
    80001fba:	2785                	addiw	a5,a5,1
    80001fbc:	0007871b          	sext.w	a4,a5
            if(p->priority > SCHED_MAX) p->priority = SCHED_MAX;
    80001fc0:	fcecc5e3          	blt	s9,a4,80001f8a <scheduler+0xbe>
            p->priority += SCHED_ALPHA;
    80001fc4:	16f4a423          	sw	a5,360(s1)
    80001fc8:	b7d9                	j	80001f8e <scheduler+0xc2>
      printf("sched: pid=%d name=%s pri=%d wait=%d cpu=%d\n",
    80001fca:	17092783          	lw	a5,368(s2)
    80001fce:	16c92703          	lw	a4,364(s2)
    80001fd2:	16892683          	lw	a3,360(s2)
    80001fd6:	15890613          	addi	a2,s2,344
    80001fda:	03092583          	lw	a1,48(s2)
    80001fde:	00005517          	auipc	a0,0x5
    80001fe2:	22a50513          	addi	a0,a0,554 # 80007208 <digits+0x1d0>
    80001fe6:	cdefe0ef          	jal	ra,800004c4 <printf>
      best->state = RUNNING;
    80001fea:	4791                	li	a5,4
    80001fec:	00f92c23          	sw	a5,24(s2)
      c->proc = best;
    80001ff0:	172b3823          	sd	s2,368(s6)
      swtch(&c->context, &best->context);
    80001ff4:	06090593          	addi	a1,s2,96
    80001ff8:	8562                	mv	a0,s8
    80001ffa:	2ad000ef          	jal	ra,80002aa6 <swtch>
      window_tick++;
    80001ffe:	000ba783          	lw	a5,0(s7)
    80002002:	2785                	addiw	a5,a5,1
    80002004:	0007871b          	sext.w	a4,a5
    80002008:	00fba023          	sw	a5,0(s7)
      if(best->cpu_ticks > SCHED_TCPU_MAX){
    8000200c:	17092683          	lw	a3,368(s2)
    80002010:	47a9                	li	a5,10
    80002012:	00d7db63          	bge	a5,a3,80002028 <scheduler+0x15c>
        best->priority -= SCHED_BETA;
    80002016:	16892783          	lw	a5,360(s2)
    8000201a:	37f9                	addiw	a5,a5,-2
    8000201c:	0007869b          	sext.w	a3,a5
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80002020:	0406c463          	bltz	a3,80002068 <scheduler+0x19c>
        best->priority -= SCHED_BETA;
    80002024:	16f92423          	sw	a5,360(s2)
      if(window_tick >= SCHED_W){
    80002028:	03100793          	li	a5,49
    8000202c:	04e7c163          	blt	a5,a4,8000206e <scheduler+0x1a2>
      c->proc = 0;
    80002030:	160b3823          	sd	zero,368(s6)
      release(&best->lock);
    80002034:	854a                	mv	a0,s2
    80002036:	d35fe0ef          	jal	ra,80000d6a <release>
    release(&wait_lock);
    8000203a:	8556                	mv	a0,s5
    8000203c:	d2ffe0ef          	jal	ra,80000d6a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002040:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002044:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002048:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000204c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002050:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002052:	10079073          	csrw	sstatus,a5
    acquire(&wait_lock); // must be acquired before any p->lock.
    80002056:	8556                	mv	a0,s5
    80002058:	c7bfe0ef          	jal	ra,80000cd2 <acquire>
    best = 0;
    8000205c:	4901                	li	s2,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000205e:	00098497          	auipc	s1,0x98
    80002062:	3ba48493          	addi	s1,s1,954 # 8009a418 <proc>
    80002066:	b5f1                	j	80001f32 <scheduler+0x66>
        if(best->priority < SCHED_MIN) best->priority = SCHED_MIN;
    80002068:	16092423          	sw	zero,360(s2)
    8000206c:	bf75                	j	80002028 <scheduler+0x15c>
        window_tick = 0;
    8000206e:	000ba023          	sw	zero,0(s7)
        for(p = proc; p < &proc[NPROC]; p++){
    80002072:	00098497          	auipc	s1,0x98
    80002076:	3a648493          	addi	s1,s1,934 # 8009a418 <proc>
    8000207a:	a039                	j	80002088 <scheduler+0x1bc>
            p->cpu_ticks = 0;
    8000207c:	1604a823          	sw	zero,368(s1)
        for(p = proc; p < &proc[NPROC]; p++){
    80002080:	17848493          	addi	s1,s1,376
    80002084:	fb3486e3          	beq	s1,s3,80002030 <scheduler+0x164>
          if(p != best){
    80002088:	fe990ae3          	beq	s2,s1,8000207c <scheduler+0x1b0>
            acquire(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	c45fe0ef          	jal	ra,80000cd2 <acquire>
            p->cpu_ticks = 0;
    80002092:	1604a823          	sw	zero,368(s1)
            release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	cd3fe0ef          	jal	ra,80000d6a <release>
    8000209c:	b7d5                	j	80002080 <scheduler+0x1b4>

000000008000209e <sched>:
{
    8000209e:	7179                	addi	sp,sp,-48
    800020a0:	f406                	sd	ra,40(sp)
    800020a2:	f022                	sd	s0,32(sp)
    800020a4:	ec26                	sd	s1,24(sp)
    800020a6:	e84a                	sd	s2,16(sp)
    800020a8:	e44e                	sd	s3,8(sp)
    800020aa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020ac:	98fff0ef          	jal	ra,80001a3a <myproc>
    800020b0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020b2:	bb7fe0ef          	jal	ra,80000c68 <holding>
    800020b6:	c92d                	beqz	a0,80002128 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ba:	2781                	sext.w	a5,a5
    800020bc:	079e                	slli	a5,a5,0x7
    800020be:	00096717          	auipc	a4,0x96
    800020c2:	96a70713          	addi	a4,a4,-1686 # 80097a28 <pid_lock>
    800020c6:	97ba                	add	a5,a5,a4
    800020c8:	1e87a703          	lw	a4,488(a5)
    800020cc:	4785                	li	a5,1
    800020ce:	06f71363          	bne	a4,a5,80002134 <sched+0x96>
  if(p->state == RUNNING)
    800020d2:	4c98                	lw	a4,24(s1)
    800020d4:	4791                	li	a5,4
    800020d6:	06f70563          	beq	a4,a5,80002140 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020da:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020de:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020e0:	e7b5                	bnez	a5,8000214c <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020e4:	00096917          	auipc	s2,0x96
    800020e8:	94490913          	addi	s2,s2,-1724 # 80097a28 <pid_lock>
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	97ca                	add	a5,a5,s2
    800020f2:	1ec7a983          	lw	s3,492(a5)
    800020f6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f8:	2781                	sext.w	a5,a5
    800020fa:	079e                	slli	a5,a5,0x7
    800020fc:	00096597          	auipc	a1,0x96
    80002100:	aa458593          	addi	a1,a1,-1372 # 80097ba0 <cpus+0x8>
    80002104:	95be                	add	a1,a1,a5
    80002106:	06048513          	addi	a0,s1,96
    8000210a:	19d000ef          	jal	ra,80002aa6 <swtch>
    8000210e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	97ca                	add	a5,a5,s2
    80002116:	1f37a623          	sw	s3,492(a5)
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6145                	addi	sp,sp,48
    80002126:	8082                	ret
    panic("sched p->lock");
    80002128:	00005517          	auipc	a0,0x5
    8000212c:	11050513          	addi	a0,a0,272 # 80007238 <digits+0x200>
    80002130:	e5afe0ef          	jal	ra,8000078a <panic>
    panic("sched locks");
    80002134:	00005517          	auipc	a0,0x5
    80002138:	11450513          	addi	a0,a0,276 # 80007248 <digits+0x210>
    8000213c:	e4efe0ef          	jal	ra,8000078a <panic>
    panic("sched RUNNING");
    80002140:	00005517          	auipc	a0,0x5
    80002144:	11850513          	addi	a0,a0,280 # 80007258 <digits+0x220>
    80002148:	e42fe0ef          	jal	ra,8000078a <panic>
    panic("sched interruptible");
    8000214c:	00005517          	auipc	a0,0x5
    80002150:	11c50513          	addi	a0,a0,284 # 80007268 <digits+0x230>
    80002154:	e36fe0ef          	jal	ra,8000078a <panic>

0000000080002158 <yield>:
{
    80002158:	1101                	addi	sp,sp,-32
    8000215a:	ec06                	sd	ra,24(sp)
    8000215c:	e822                	sd	s0,16(sp)
    8000215e:	e426                	sd	s1,8(sp)
    80002160:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002162:	8d9ff0ef          	jal	ra,80001a3a <myproc>
    80002166:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002168:	b6bfe0ef          	jal	ra,80000cd2 <acquire>
  p->state = RUNNABLE;
    8000216c:	478d                	li	a5,3
    8000216e:	cc9c                	sw	a5,24(s1)
  sched();
    80002170:	f2fff0ef          	jal	ra,8000209e <sched>
  release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	bf5fe0ef          	jal	ra,80000d6a <release>
}
    8000217a:	60e2                	ld	ra,24(sp)
    8000217c:	6442                	ld	s0,16(sp)
    8000217e:	64a2                	ld	s1,8(sp)
    80002180:	6105                	addi	sp,sp,32
    80002182:	8082                	ret

0000000080002184 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002184:	7179                	addi	sp,sp,-48
    80002186:	f406                	sd	ra,40(sp)
    80002188:	f022                	sd	s0,32(sp)
    8000218a:	ec26                	sd	s1,24(sp)
    8000218c:	e84a                	sd	s2,16(sp)
    8000218e:	e44e                	sd	s3,8(sp)
    80002190:	1800                	addi	s0,sp,48
    80002192:	89aa                	mv	s3,a0
    80002194:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002196:	8a5ff0ef          	jal	ra,80001a3a <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219c:	b37fe0ef          	jal	ra,80000cd2 <acquire>
  release(lk);
    800021a0:	854a                	mv	a0,s2
    800021a2:	bc9fe0ef          	jal	ra,80000d6a <release>

  // Go to sleep.
  p->chan = chan;
    800021a6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021aa:	4789                	li	a5,2
    800021ac:	cc9c                	sw	a5,24(s1)

  sched();
    800021ae:	ef1ff0ef          	jal	ra,8000209e <sched>

  // Tidy up.
  p->chan = 0;
    800021b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	bb3fe0ef          	jal	ra,80000d6a <release>
  acquire(lk);
    800021bc:	854a                	mv	a0,s2
    800021be:	b15fe0ef          	jal	ra,80000cd2 <acquire>
}
    800021c2:	70a2                	ld	ra,40(sp)
    800021c4:	7402                	ld	s0,32(sp)
    800021c6:	64e2                	ld	s1,24(sp)
    800021c8:	6942                	ld	s2,16(sp)
    800021ca:	69a2                	ld	s3,8(sp)
    800021cc:	6145                	addi	sp,sp,48
    800021ce:	8082                	ret

00000000800021d0 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    800021d0:	7139                	addi	sp,sp,-64
    800021d2:	fc06                	sd	ra,56(sp)
    800021d4:	f822                	sd	s0,48(sp)
    800021d6:	f426                	sd	s1,40(sp)
    800021d8:	f04a                	sd	s2,32(sp)
    800021da:	ec4e                	sd	s3,24(sp)
    800021dc:	e852                	sd	s4,16(sp)
    800021de:	e456                	sd	s5,8(sp)
    800021e0:	0080                	addi	s0,sp,64
    800021e2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021e4:	00098497          	auipc	s1,0x98
    800021e8:	23448493          	addi	s1,s1,564 # 8009a418 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021ec:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021ee:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f0:	0009e917          	auipc	s2,0x9e
    800021f4:	02890913          	addi	s2,s2,40 # 800a0218 <tickslock>
    800021f8:	a801                	j	80002208 <wakeup+0x38>
      }
      release(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	b6ffe0ef          	jal	ra,80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002200:	17848493          	addi	s1,s1,376
    80002204:	03248263          	beq	s1,s2,80002228 <wakeup+0x58>
    if(p != myproc()){
    80002208:	833ff0ef          	jal	ra,80001a3a <myproc>
    8000220c:	fea48ae3          	beq	s1,a0,80002200 <wakeup+0x30>
      acquire(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	ac1fe0ef          	jal	ra,80000cd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002216:	4c9c                	lw	a5,24(s1)
    80002218:	ff3791e3          	bne	a5,s3,800021fa <wakeup+0x2a>
    8000221c:	709c                	ld	a5,32(s1)
    8000221e:	fd479ee3          	bne	a5,s4,800021fa <wakeup+0x2a>
        p->state = RUNNABLE;
    80002222:	0154ac23          	sw	s5,24(s1)
    80002226:	bfd1                	j	800021fa <wakeup+0x2a>
    }
  }
}
    80002228:	70e2                	ld	ra,56(sp)
    8000222a:	7442                	ld	s0,48(sp)
    8000222c:	74a2                	ld	s1,40(sp)
    8000222e:	7902                	ld	s2,32(sp)
    80002230:	69e2                	ld	s3,24(sp)
    80002232:	6a42                	ld	s4,16(sp)
    80002234:	6aa2                	ld	s5,8(sp)
    80002236:	6121                	addi	sp,sp,64
    80002238:	8082                	ret

000000008000223a <reparent>:
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	e052                	sd	s4,0(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000224c:	00098497          	auipc	s1,0x98
    80002250:	1cc48493          	addi	s1,s1,460 # 8009a418 <proc>
      pp->parent = initproc;
    80002254:	00005a17          	auipc	s4,0x5
    80002258:	6c4a0a13          	addi	s4,s4,1732 # 80007918 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225c:	0009e997          	auipc	s3,0x9e
    80002260:	fbc98993          	addi	s3,s3,-68 # 800a0218 <tickslock>
    80002264:	a029                	j	8000226e <reparent+0x34>
    80002266:	17848493          	addi	s1,s1,376
    8000226a:	01348b63          	beq	s1,s3,80002280 <reparent+0x46>
    if(pp->parent == p){
    8000226e:	7c9c                	ld	a5,56(s1)
    80002270:	ff279be3          	bne	a5,s2,80002266 <reparent+0x2c>
      pp->parent = initproc;
    80002274:	000a3503          	ld	a0,0(s4)
    80002278:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000227a:	f57ff0ef          	jal	ra,800021d0 <wakeup>
    8000227e:	b7e5                	j	80002266 <reparent+0x2c>
}
    80002280:	70a2                	ld	ra,40(sp)
    80002282:	7402                	ld	s0,32(sp)
    80002284:	64e2                	ld	s1,24(sp)
    80002286:	6942                	ld	s2,16(sp)
    80002288:	69a2                	ld	s3,8(sp)
    8000228a:	6a02                	ld	s4,0(sp)
    8000228c:	6145                	addi	sp,sp,48
    8000228e:	8082                	ret

0000000080002290 <kexit>:
{
    80002290:	7179                	addi	sp,sp,-48
    80002292:	f406                	sd	ra,40(sp)
    80002294:	f022                	sd	s0,32(sp)
    80002296:	ec26                	sd	s1,24(sp)
    80002298:	e84a                	sd	s2,16(sp)
    8000229a:	e44e                	sd	s3,8(sp)
    8000229c:	e052                	sd	s4,0(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022a2:	f98ff0ef          	jal	ra,80001a3a <myproc>
    800022a6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022a8:	00005797          	auipc	a5,0x5
    800022ac:	6707b783          	ld	a5,1648(a5) # 80007918 <initproc>
    800022b0:	0d050493          	addi	s1,a0,208
    800022b4:	15050913          	addi	s2,a0,336
    800022b8:	00a79f63          	bne	a5,a0,800022d6 <kexit+0x46>
    panic("init exiting");
    800022bc:	00005517          	auipc	a0,0x5
    800022c0:	fc450513          	addi	a0,a0,-60 # 80007280 <digits+0x248>
    800022c4:	cc6fe0ef          	jal	ra,8000078a <panic>
      fileclose(f);
    800022c8:	436020ef          	jal	ra,800046fe <fileclose>
      p->ofile[fd] = 0;
    800022cc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022d0:	04a1                	addi	s1,s1,8
    800022d2:	01248563          	beq	s1,s2,800022dc <kexit+0x4c>
    if(p->ofile[fd]){
    800022d6:	6088                	ld	a0,0(s1)
    800022d8:	f965                	bnez	a0,800022c8 <kexit+0x38>
    800022da:	bfdd                	j	800022d0 <kexit+0x40>
  begin_op();
    800022dc:	014020ef          	jal	ra,800042f0 <begin_op>
  iput(p->cwd);
    800022e0:	1509b503          	ld	a0,336(s3)
    800022e4:	7ac010ef          	jal	ra,80003a90 <iput>
  end_op();
    800022e8:	078020ef          	jal	ra,80004360 <end_op>
  p->cwd = 0;
    800022ec:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022f0:	00095497          	auipc	s1,0x95
    800022f4:	75048493          	addi	s1,s1,1872 # 80097a40 <wait_lock>
    800022f8:	8526                	mv	a0,s1
    800022fa:	9d9fe0ef          	jal	ra,80000cd2 <acquire>
  reparent(p);
    800022fe:	854e                	mv	a0,s3
    80002300:	f3bff0ef          	jal	ra,8000223a <reparent>
  wakeup(p->parent);
    80002304:	0389b503          	ld	a0,56(s3)
    80002308:	ec9ff0ef          	jal	ra,800021d0 <wakeup>
  acquire(&p->lock);
    8000230c:	854e                	mv	a0,s3
    8000230e:	9c5fe0ef          	jal	ra,80000cd2 <acquire>
  p->xstate = status;
    80002312:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002316:	4795                	li	a5,5
    80002318:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	a4dfe0ef          	jal	ra,80000d6a <release>
  sched();
    80002322:	d7dff0ef          	jal	ra,8000209e <sched>
  panic("zombie exit");
    80002326:	00005517          	auipc	a0,0x5
    8000232a:	f6a50513          	addi	a0,a0,-150 # 80007290 <digits+0x258>
    8000232e:	c5cfe0ef          	jal	ra,8000078a <panic>

0000000080002332 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002332:	7179                	addi	sp,sp,-48
    80002334:	f406                	sd	ra,40(sp)
    80002336:	f022                	sd	s0,32(sp)
    80002338:	ec26                	sd	s1,24(sp)
    8000233a:	e84a                	sd	s2,16(sp)
    8000233c:	e44e                	sd	s3,8(sp)
    8000233e:	1800                	addi	s0,sp,48
    80002340:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002342:	00098497          	auipc	s1,0x98
    80002346:	0d648493          	addi	s1,s1,214 # 8009a418 <proc>
    8000234a:	0009e997          	auipc	s3,0x9e
    8000234e:	ece98993          	addi	s3,s3,-306 # 800a0218 <tickslock>
    acquire(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	97ffe0ef          	jal	ra,80000cd2 <acquire>
    if(p->pid == pid){
    80002358:	589c                	lw	a5,48(s1)
    8000235a:	01278b63          	beq	a5,s2,80002370 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	a0bfe0ef          	jal	ra,80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002364:	17848493          	addi	s1,s1,376
    80002368:	ff3495e3          	bne	s1,s3,80002352 <kkill+0x20>
  }
  return -1;
    8000236c:	557d                	li	a0,-1
    8000236e:	a819                	j	80002384 <kkill+0x52>
      p->killed = 1;
    80002370:	4785                	li	a5,1
    80002372:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002374:	4c98                	lw	a4,24(s1)
    80002376:	4789                	li	a5,2
    80002378:	00f70d63          	beq	a4,a5,80002392 <kkill+0x60>
      release(&p->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	9edfe0ef          	jal	ra,80000d6a <release>
      return 0;
    80002382:	4501                	li	a0,0
}
    80002384:	70a2                	ld	ra,40(sp)
    80002386:	7402                	ld	s0,32(sp)
    80002388:	64e2                	ld	s1,24(sp)
    8000238a:	6942                	ld	s2,16(sp)
    8000238c:	69a2                	ld	s3,8(sp)
    8000238e:	6145                	addi	sp,sp,48
    80002390:	8082                	ret
        p->state = RUNNABLE;
    80002392:	478d                	li	a5,3
    80002394:	cc9c                	sw	a5,24(s1)
    80002396:	b7dd                	j	8000237c <kkill+0x4a>

0000000080002398 <setkilled>:

void
setkilled(struct proc *p)
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	1000                	addi	s0,sp,32
    800023a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023a4:	92ffe0ef          	jal	ra,80000cd2 <acquire>
  p->killed = 1;
    800023a8:	4785                	li	a5,1
    800023aa:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	9bdfe0ef          	jal	ra,80000d6a <release>
}
    800023b2:	60e2                	ld	ra,24(sp)
    800023b4:	6442                	ld	s0,16(sp)
    800023b6:	64a2                	ld	s1,8(sp)
    800023b8:	6105                	addi	sp,sp,32
    800023ba:	8082                	ret

00000000800023bc <killed>:

int
killed(struct proc *p)
{
    800023bc:	1101                	addi	sp,sp,-32
    800023be:	ec06                	sd	ra,24(sp)
    800023c0:	e822                	sd	s0,16(sp)
    800023c2:	e426                	sd	s1,8(sp)
    800023c4:	e04a                	sd	s2,0(sp)
    800023c6:	1000                	addi	s0,sp,32
    800023c8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023ca:	909fe0ef          	jal	ra,80000cd2 <acquire>
  k = p->killed;
    800023ce:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	997fe0ef          	jal	ra,80000d6a <release>
  return k;
}
    800023d8:	854a                	mv	a0,s2
    800023da:	60e2                	ld	ra,24(sp)
    800023dc:	6442                	ld	s0,16(sp)
    800023de:	64a2                	ld	s1,8(sp)
    800023e0:	6902                	ld	s2,0(sp)
    800023e2:	6105                	addi	sp,sp,32
    800023e4:	8082                	ret

00000000800023e6 <kwait>:
{
    800023e6:	715d                	addi	sp,sp,-80
    800023e8:	e486                	sd	ra,72(sp)
    800023ea:	e0a2                	sd	s0,64(sp)
    800023ec:	fc26                	sd	s1,56(sp)
    800023ee:	f84a                	sd	s2,48(sp)
    800023f0:	f44e                	sd	s3,40(sp)
    800023f2:	f052                	sd	s4,32(sp)
    800023f4:	ec56                	sd	s5,24(sp)
    800023f6:	e85a                	sd	s6,16(sp)
    800023f8:	e45e                	sd	s7,8(sp)
    800023fa:	e062                	sd	s8,0(sp)
    800023fc:	0880                	addi	s0,sp,80
    800023fe:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002400:	e3aff0ef          	jal	ra,80001a3a <myproc>
    80002404:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002406:	00095517          	auipc	a0,0x95
    8000240a:	63a50513          	addi	a0,a0,1594 # 80097a40 <wait_lock>
    8000240e:	8c5fe0ef          	jal	ra,80000cd2 <acquire>
    havekids = 0;
    80002412:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002414:	4a15                	li	s4,5
        havekids = 1;
    80002416:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002418:	0009e997          	auipc	s3,0x9e
    8000241c:	e0098993          	addi	s3,s3,-512 # 800a0218 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002420:	00095c17          	auipc	s8,0x95
    80002424:	620c0c13          	addi	s8,s8,1568 # 80097a40 <wait_lock>
    havekids = 0;
    80002428:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	00098497          	auipc	s1,0x98
    8000242e:	fee48493          	addi	s1,s1,-18 # 8009a418 <proc>
    80002432:	a899                	j	80002488 <kwait+0xa2>
          pid = pp->pid;
    80002434:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002438:	000b0c63          	beqz	s6,80002450 <kwait+0x6a>
    8000243c:	4691                	li	a3,4
    8000243e:	02c48613          	addi	a2,s1,44
    80002442:	85da                	mv	a1,s6
    80002444:	05093503          	ld	a0,80(s2)
    80002448:	a98ff0ef          	jal	ra,800016e0 <copyout>
    8000244c:	00054f63          	bltz	a0,8000246a <kwait+0x84>
          freeproc(pp);
    80002450:	8526                	mv	a0,s1
    80002452:	fbaff0ef          	jal	ra,80001c0c <freeproc>
          release(&pp->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	913fe0ef          	jal	ra,80000d6a <release>
          release(&wait_lock);
    8000245c:	00095517          	auipc	a0,0x95
    80002460:	5e450513          	addi	a0,a0,1508 # 80097a40 <wait_lock>
    80002464:	907fe0ef          	jal	ra,80000d6a <release>
          return pid;
    80002468:	a891                	j	800024bc <kwait+0xd6>
            release(&pp->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	8fffe0ef          	jal	ra,80000d6a <release>
            release(&wait_lock);
    80002470:	00095517          	auipc	a0,0x95
    80002474:	5d050513          	addi	a0,a0,1488 # 80097a40 <wait_lock>
    80002478:	8f3fe0ef          	jal	ra,80000d6a <release>
            return -1;
    8000247c:	59fd                	li	s3,-1
    8000247e:	a83d                	j	800024bc <kwait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002480:	17848493          	addi	s1,s1,376
    80002484:	03348063          	beq	s1,s3,800024a4 <kwait+0xbe>
      if(pp->parent == p){
    80002488:	7c9c                	ld	a5,56(s1)
    8000248a:	ff279be3          	bne	a5,s2,80002480 <kwait+0x9a>
        acquire(&pp->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	843fe0ef          	jal	ra,80000cd2 <acquire>
        if(pp->state == ZOMBIE){
    80002494:	4c9c                	lw	a5,24(s1)
    80002496:	f9478fe3          	beq	a5,s4,80002434 <kwait+0x4e>
        release(&pp->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	8cffe0ef          	jal	ra,80000d6a <release>
        havekids = 1;
    800024a0:	8756                	mv	a4,s5
    800024a2:	bff9                	j	80002480 <kwait+0x9a>
    if(!havekids || killed(p)){
    800024a4:	c709                	beqz	a4,800024ae <kwait+0xc8>
    800024a6:	854a                	mv	a0,s2
    800024a8:	f15ff0ef          	jal	ra,800023bc <killed>
    800024ac:	c50d                	beqz	a0,800024d6 <kwait+0xf0>
      release(&wait_lock);
    800024ae:	00095517          	auipc	a0,0x95
    800024b2:	59250513          	addi	a0,a0,1426 # 80097a40 <wait_lock>
    800024b6:	8b5fe0ef          	jal	ra,80000d6a <release>
      return -1;
    800024ba:	59fd                	li	s3,-1
}
    800024bc:	854e                	mv	a0,s3
    800024be:	60a6                	ld	ra,72(sp)
    800024c0:	6406                	ld	s0,64(sp)
    800024c2:	74e2                	ld	s1,56(sp)
    800024c4:	7942                	ld	s2,48(sp)
    800024c6:	79a2                	ld	s3,40(sp)
    800024c8:	7a02                	ld	s4,32(sp)
    800024ca:	6ae2                	ld	s5,24(sp)
    800024cc:	6b42                	ld	s6,16(sp)
    800024ce:	6ba2                	ld	s7,8(sp)
    800024d0:	6c02                	ld	s8,0(sp)
    800024d2:	6161                	addi	sp,sp,80
    800024d4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	cabff0ef          	jal	ra,80002184 <sleep>
    havekids = 0;
    800024de:	b7a9                	j	80002428 <kwait+0x42>

00000000800024e0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024e0:	7179                	addi	sp,sp,-48
    800024e2:	f406                	sd	ra,40(sp)
    800024e4:	f022                	sd	s0,32(sp)
    800024e6:	ec26                	sd	s1,24(sp)
    800024e8:	e84a                	sd	s2,16(sp)
    800024ea:	e44e                	sd	s3,8(sp)
    800024ec:	e052                	sd	s4,0(sp)
    800024ee:	1800                	addi	s0,sp,48
    800024f0:	84aa                	mv	s1,a0
    800024f2:	892e                	mv	s2,a1
    800024f4:	89b2                	mv	s3,a2
    800024f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f8:	d42ff0ef          	jal	ra,80001a3a <myproc>
  if(user_dst){
    800024fc:	cc99                	beqz	s1,8000251a <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    800024fe:	86d2                	mv	a3,s4
    80002500:	864e                	mv	a2,s3
    80002502:	85ca                	mv	a1,s2
    80002504:	6928                	ld	a0,80(a0)
    80002506:	9daff0ef          	jal	ra,800016e0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000250a:	70a2                	ld	ra,40(sp)
    8000250c:	7402                	ld	s0,32(sp)
    8000250e:	64e2                	ld	s1,24(sp)
    80002510:	6942                	ld	s2,16(sp)
    80002512:	69a2                	ld	s3,8(sp)
    80002514:	6a02                	ld	s4,0(sp)
    80002516:	6145                	addi	sp,sp,48
    80002518:	8082                	ret
    memmove((char *)dst, src, len);
    8000251a:	000a061b          	sext.w	a2,s4
    8000251e:	85ce                	mv	a1,s3
    80002520:	854a                	mv	a0,s2
    80002522:	8e1fe0ef          	jal	ra,80000e02 <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	b7cd                	j	8000250a <either_copyout+0x2a>

000000008000252a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	e052                	sd	s4,0(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	892a                	mv	s2,a0
    8000253c:	84ae                	mv	s1,a1
    8000253e:	89b2                	mv	s3,a2
    80002540:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002542:	cf8ff0ef          	jal	ra,80001a3a <myproc>
  if(user_src){
    80002546:	cc99                	beqz	s1,80002564 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002548:	86d2                	mv	a3,s4
    8000254a:	864e                	mv	a2,s3
    8000254c:	85ca                	mv	a1,s2
    8000254e:	6928                	ld	a0,80(a0)
    80002550:	a72ff0ef          	jal	ra,800017c2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6a02                	ld	s4,0(sp)
    80002560:	6145                	addi	sp,sp,48
    80002562:	8082                	ret
    memmove(dst, (char*)src, len);
    80002564:	000a061b          	sext.w	a2,s4
    80002568:	85ce                	mv	a1,s3
    8000256a:	854a                	mv	a0,s2
    8000256c:	897fe0ef          	jal	ra,80000e02 <memmove>
    return 0;
    80002570:	8526                	mv	a0,s1
    80002572:	b7cd                	j	80002554 <either_copyin+0x2a>

0000000080002574 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002574:	715d                	addi	sp,sp,-80
    80002576:	e486                	sd	ra,72(sp)
    80002578:	e0a2                	sd	s0,64(sp)
    8000257a:	fc26                	sd	s1,56(sp)
    8000257c:	f84a                	sd	s2,48(sp)
    8000257e:	f44e                	sd	s3,40(sp)
    80002580:	f052                	sd	s4,32(sp)
    80002582:	ec56                	sd	s5,24(sp)
    80002584:	e85a                	sd	s6,16(sp)
    80002586:	e45e                	sd	s7,8(sp)
    80002588:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000258a:	00005517          	auipc	a0,0x5
    8000258e:	b7650513          	addi	a0,a0,-1162 # 80007100 <digits+0xc8>
    80002592:	f33fd0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002596:	00098497          	auipc	s1,0x98
    8000259a:	fda48493          	addi	s1,s1,-38 # 8009a570 <proc+0x158>
    8000259e:	0009e917          	auipc	s2,0x9e
    800025a2:	dd290913          	addi	s2,s2,-558 # 800a0370 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a8:	00005997          	auipc	s3,0x5
    800025ac:	cf898993          	addi	s3,s3,-776 # 800072a0 <digits+0x268>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    800025b0:	00005a97          	auipc	s5,0x5
    800025b4:	cf8a8a93          	addi	s5,s5,-776 # 800072a8 <digits+0x270>
           p->priority, p->wait_ticks, p->cpu_ticks);
    printf("\n");
    800025b8:	00005a17          	auipc	s4,0x5
    800025bc:	b48a0a13          	addi	s4,s4,-1208 # 80007100 <digits+0xc8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c0:	00005b97          	auipc	s7,0x5
    800025c4:	d38b8b93          	addi	s7,s7,-712 # 800072f8 <states.0>
    800025c8:	a00d                	j	800025ea <procdump+0x76>
    printf("%d %s %s pri=%d wait=%d cpu=%d", p->pid, state, p->name,
    800025ca:	0186a803          	lw	a6,24(a3)
    800025ce:	4adc                	lw	a5,20(a3)
    800025d0:	4a98                	lw	a4,16(a3)
    800025d2:	ed86a583          	lw	a1,-296(a3)
    800025d6:	8556                	mv	a0,s5
    800025d8:	eedfd0ef          	jal	ra,800004c4 <printf>
    printf("\n");
    800025dc:	8552                	mv	a0,s4
    800025de:	ee7fd0ef          	jal	ra,800004c4 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e2:	17848493          	addi	s1,s1,376
    800025e6:	03248163          	beq	s1,s2,80002608 <procdump+0x94>
    if(p->state == UNUSED)
    800025ea:	86a6                	mv	a3,s1
    800025ec:	ec04a783          	lw	a5,-320(s1)
    800025f0:	dbed                	beqz	a5,800025e2 <procdump+0x6e>
      state = "???";
    800025f2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	fcfb6be3          	bltu	s6,a5,800025ca <procdump+0x56>
    800025f8:	1782                	slli	a5,a5,0x20
    800025fa:	9381                	srli	a5,a5,0x20
    800025fc:	078e                	slli	a5,a5,0x3
    800025fe:	97de                	add	a5,a5,s7
    80002600:	6390                	ld	a2,0(a5)
    80002602:	f661                	bnez	a2,800025ca <procdump+0x56>
      state = "???";
    80002604:	864e                	mv	a2,s3
    80002606:	b7d1                	j	800025ca <procdump+0x56>
  }
}
    80002608:	60a6                	ld	ra,72(sp)
    8000260a:	6406                	ld	s0,64(sp)
    8000260c:	74e2                	ld	s1,56(sp)
    8000260e:	7942                	ld	s2,48(sp)
    80002610:	79a2                	ld	s3,40(sp)
    80002612:	7a02                	ld	s4,32(sp)
    80002614:	6ae2                	ld	s5,24(sp)
    80002616:	6b42                	ld	s6,16(sp)
    80002618:	6ba2                	ld	s7,8(sp)
    8000261a:	6161                	addi	sp,sp,80
    8000261c:	8082                	ret

000000008000261e <sys_send>:
extern struct mailbox mailboxes[MAX_MBX];
extern struct shm_region shm_regions[MAX_SHM];

uint64
sys_send(void)
{
    8000261e:	7139                	addi	sp,sp,-64
    80002620:	fc06                	sd	ra,56(sp)
    80002622:	f822                	sd	s0,48(sp)
    80002624:	f426                	sd	s1,40(sp)
    80002626:	f04a                	sd	s2,32(sp)
    80002628:	ec4e                	sd	s3,24(sp)
    8000262a:	e852                	sd	s4,16(sp)
    8000262c:	0080                	addi	s0,sp,64
  int dest_pid;
  uint64 msg_addr;
  struct proc *p = myproc();
    8000262e:	c0cff0ef          	jal	ra,80001a3a <myproc>
    80002632:	89aa                	mv	s3,a0

  argint(0, &dest_pid);
    80002634:	fcc40593          	addi	a1,s0,-52
    80002638:	4501                	li	a0,0
    8000263a:	0f1000ef          	jal	ra,80002f2a <argint>
  argaddr(1, &msg_addr);
    8000263e:	fc040593          	addi	a1,s0,-64
    80002642:	4505                	li	a0,1
    80002644:	103000ef          	jal	ra,80002f46 <argaddr>

  struct mailbox *mbx = 0;
  for(int i = 0; i < MAX_MBX; i++){
    80002648:	00096497          	auipc	s1,0x96
    8000264c:	95048493          	addi	s1,s1,-1712 # 80097f98 <mailboxes>
    80002650:	00098a17          	auipc	s4,0x98
    80002654:	dc8a0a13          	addi	s4,s4,-568 # 8009a418 <proc>
    acquire(&mailboxes[i].lock);
    80002658:	8926                	mv	s2,s1
    8000265a:	8526                	mv	a0,s1
    8000265c:	e76fe0ef          	jal	ra,80000cd2 <acquire>
    if(mailboxes[i].owner_pid == dest_pid){
    80002660:	2444a703          	lw	a4,580(s1)
    80002664:	fcc42783          	lw	a5,-52(s0)
    80002668:	02f70c63          	beq	a4,a5,800026a0 <sys_send+0x82>
      mbx = &mailboxes[i];
      break;
    }
    release(&mailboxes[i].lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	efcfe0ef          	jal	ra,80000d6a <release>
  for(int i = 0; i < MAX_MBX; i++){
    80002672:	24848493          	addi	s1,s1,584
    80002676:	ff4491e3          	bne	s1,s4,80002658 <sys_send+0x3a>
  }

  if(!mbx) return -1;
    8000267a:	557d                	li	a0,-1
  mbx->count++;

  wakeup(mbx); // Wake up receiver
  release(&mbx->lock);
  return 0;
}
    8000267c:	70e2                	ld	ra,56(sp)
    8000267e:	7442                	ld	s0,48(sp)
    80002680:	74a2                	ld	s1,40(sp)
    80002682:	7902                	ld	s2,32(sp)
    80002684:	69e2                	ld	s3,24(sp)
    80002686:	6a42                	ld	s4,16(sp)
    80002688:	6121                	addi	sp,sp,64
    8000268a:	8082                	ret
      release(&mbx->lock);
    8000268c:	854a                	mv	a0,s2
    8000268e:	edcfe0ef          	jal	ra,80000d6a <release>
      return -1;
    80002692:	557d                	li	a0,-1
    80002694:	b7e5                	j	8000267c <sys_send+0x5e>
    release(&mbx->lock);
    80002696:	854a                	mv	a0,s2
    80002698:	ed2fe0ef          	jal	ra,80000d6a <release>
    return -1;
    8000269c:	557d                	li	a0,-1
    8000269e:	bff9                	j	8000267c <sys_send+0x5e>
  while(mbx->count == MBX_SIZE){
    800026a0:	2404a703          	lw	a4,576(s1)
    800026a4:	47a1                	li	a5,8
    800026a6:	44a1                	li	s1,8
    800026a8:	00f71e63          	bne	a4,a5,800026c4 <sys_send+0xa6>
    if(killed(p)){
    800026ac:	854e                	mv	a0,s3
    800026ae:	d0fff0ef          	jal	ra,800023bc <killed>
    800026b2:	fd69                	bnez	a0,8000268c <sys_send+0x6e>
    sleep(mbx, &mbx->lock);
    800026b4:	85ca                	mv	a1,s2
    800026b6:	854a                	mv	a0,s2
    800026b8:	acdff0ef          	jal	ra,80002184 <sleep>
  while(mbx->count == MBX_SIZE){
    800026bc:	24092783          	lw	a5,576(s2)
    800026c0:	fe9786e3          	beq	a5,s1,800026ac <sys_send+0x8e>
  struct msg *m = &mbx->msgs[mbx->tail];
    800026c4:	23c92583          	lw	a1,572(s2)
  m->sender_pid = p->pid;
    800026c8:	0309a683          	lw	a3,48(s3)
    800026cc:	00459793          	slli	a5,a1,0x4
    800026d0:	00b78733          	add	a4,a5,a1
    800026d4:	070a                	slli	a4,a4,0x2
    800026d6:	974a                	add	a4,a4,s2
    800026d8:	cf14                	sw	a3,24(a4)
  if(copyin(p->pagetable, m->data, msg_addr, sizeof(m->data)) < 0){
    800026da:	95be                	add	a1,a1,a5
    800026dc:	058a                	slli	a1,a1,0x2
    800026de:	05f1                	addi	a1,a1,28
    800026e0:	04000693          	li	a3,64
    800026e4:	fc043603          	ld	a2,-64(s0)
    800026e8:	95ca                	add	a1,a1,s2
    800026ea:	0509b503          	ld	a0,80(s3)
    800026ee:	8d4ff0ef          	jal	ra,800017c2 <copyin>
    800026f2:	fa0542e3          	bltz	a0,80002696 <sys_send+0x78>
  mbx->tail = (mbx->tail + 1) % MBX_SIZE;
    800026f6:	23c92783          	lw	a5,572(s2)
    800026fa:	2785                	addiw	a5,a5,1
    800026fc:	41f7d71b          	sraiw	a4,a5,0x1f
    80002700:	01d7571b          	srliw	a4,a4,0x1d
    80002704:	9fb9                	addw	a5,a5,a4
    80002706:	8b9d                	andi	a5,a5,7
    80002708:	9f99                	subw	a5,a5,a4
    8000270a:	22f92e23          	sw	a5,572(s2)
  mbx->count++;
    8000270e:	24092783          	lw	a5,576(s2)
    80002712:	2785                	addiw	a5,a5,1
    80002714:	24f92023          	sw	a5,576(s2)
  wakeup(mbx); // Wake up receiver
    80002718:	854a                	mv	a0,s2
    8000271a:	ab7ff0ef          	jal	ra,800021d0 <wakeup>
  release(&mbx->lock);
    8000271e:	854a                	mv	a0,s2
    80002720:	e4afe0ef          	jal	ra,80000d6a <release>
  return 0;
    80002724:	4501                	li	a0,0
    80002726:	bf99                	j	8000267c <sys_send+0x5e>

0000000080002728 <sys_recv>:

uint64
sys_recv(void)
{
    80002728:	715d                	addi	sp,sp,-80
    8000272a:	e486                	sd	ra,72(sp)
    8000272c:	e0a2                	sd	s0,64(sp)
    8000272e:	fc26                	sd	s1,56(sp)
    80002730:	f84a                	sd	s2,48(sp)
    80002732:	f44e                	sd	s3,40(sp)
    80002734:	f052                	sd	s4,32(sp)
    80002736:	ec56                	sd	s5,24(sp)
    80002738:	0880                	addi	s0,sp,80
  uint64 msg_addr;
  struct proc *p = myproc();
    8000273a:	b00ff0ef          	jal	ra,80001a3a <myproc>
    8000273e:	8a2a                	mv	s4,a0

  argaddr(0, &msg_addr);
    80002740:	fb840593          	addi	a1,s0,-72
    80002744:	4501                	li	a0,0
    80002746:	001000ef          	jal	ra,80002f46 <argaddr>

  struct mailbox *mbx = 0;
  // Find own mailbox or a new one
  for(int i = 0; i < MAX_MBX; i++){
    8000274a:	00096917          	auipc	s2,0x96
    8000274e:	84e90913          	addi	s2,s2,-1970 # 80097f98 <mailboxes>
    80002752:	4981                	li	s3,0
    80002754:	4ac1                	li	s5,16
    acquire(&mailboxes[i].lock);
    80002756:	84ca                	mv	s1,s2
    80002758:	854a                	mv	a0,s2
    8000275a:	d78fe0ef          	jal	ra,80000cd2 <acquire>
    if(mailboxes[i].owner_pid == p->pid){
    8000275e:	24492783          	lw	a5,580(s2)
    80002762:	030a2703          	lw	a4,48(s4)
    80002766:	02e78e63          	beq	a5,a4,800027a2 <sys_recv+0x7a>
      mbx = &mailboxes[i];
      break;
    }
    if(mbx == 0 && mailboxes[i].owner_pid == 0){
    8000276a:	cb99                	beqz	a5,80002780 <sys_recv+0x58>
      mailboxes[i].owner_pid = p->pid;
      mailboxes[i].head = mailboxes[i].tail = mailboxes[i].count = 0;
      mbx = &mailboxes[i];
      break;
    }
    release(&mailboxes[i].lock);
    8000276c:	854a                	mv	a0,s2
    8000276e:	dfcfe0ef          	jal	ra,80000d6a <release>
  for(int i = 0; i < MAX_MBX; i++){
    80002772:	2985                	addiw	s3,s3,1
    80002774:	24890913          	addi	s2,s2,584
    80002778:	fd599fe3          	bne	s3,s5,80002756 <sys_recv+0x2e>
  }

  if(!mbx) return -1;
    8000277c:	557d                	li	a0,-1
    8000277e:	a879                	j	8000281c <sys_recv+0xf4>
      mailboxes[i].owner_pid = p->pid;
    80002780:	24800793          	li	a5,584
    80002784:	02f989b3          	mul	s3,s3,a5
    80002788:	00096797          	auipc	a5,0x96
    8000278c:	81078793          	addi	a5,a5,-2032 # 80097f98 <mailboxes>
    80002790:	99be                	add	s3,s3,a5
    80002792:	24e9a223          	sw	a4,580(s3)
      mailboxes[i].head = mailboxes[i].tail = mailboxes[i].count = 0;
    80002796:	2409a023          	sw	zero,576(s3)
    8000279a:	2209ae23          	sw	zero,572(s3)
    8000279e:	2209ac23          	sw	zero,568(s3)

  while(mbx->count == 0){
    800027a2:	2404a783          	lw	a5,576(s1)
    800027a6:	ef81                	bnez	a5,800027be <sys_recv+0x96>
    if(killed(p)){
    800027a8:	8552                	mv	a0,s4
    800027aa:	c13ff0ef          	jal	ra,800023bc <killed>
    800027ae:	e13d                	bnez	a0,80002814 <sys_recv+0xec>
      release(&mbx->lock);
      return -1;
    }
    sleep(mbx, &mbx->lock);
    800027b0:	85a6                	mv	a1,s1
    800027b2:	8526                	mv	a0,s1
    800027b4:	9d1ff0ef          	jal	ra,80002184 <sleep>
  while(mbx->count == 0){
    800027b8:	2404a783          	lw	a5,576(s1)
    800027bc:	d7f5                	beqz	a5,800027a8 <sys_recv+0x80>
  }

  struct msg *m = &mbx->msgs[mbx->head];
  if(copyout(p->pagetable, msg_addr, m->data, sizeof(m->data)) < 0){
    800027be:	2384a783          	lw	a5,568(s1)
    800027c2:	00479613          	slli	a2,a5,0x4
    800027c6:	963e                	add	a2,a2,a5
    800027c8:	060a                	slli	a2,a2,0x2
    800027ca:	0671                	addi	a2,a2,28
    800027cc:	04000693          	li	a3,64
    800027d0:	9626                	add	a2,a2,s1
    800027d2:	fb843583          	ld	a1,-72(s0)
    800027d6:	050a3503          	ld	a0,80(s4)
    800027da:	f07fe0ef          	jal	ra,800016e0 <copyout>
    800027de:	04054863          	bltz	a0,8000282e <sys_recv+0x106>
    release(&mbx->lock);
    return -1;
  }

  mbx->head = (mbx->head + 1) % MBX_SIZE;
    800027e2:	2384a783          	lw	a5,568(s1)
    800027e6:	2785                	addiw	a5,a5,1
    800027e8:	41f7d71b          	sraiw	a4,a5,0x1f
    800027ec:	01d7571b          	srliw	a4,a4,0x1d
    800027f0:	9fb9                	addw	a5,a5,a4
    800027f2:	8b9d                	andi	a5,a5,7
    800027f4:	9f99                	subw	a5,a5,a4
    800027f6:	22f4ac23          	sw	a5,568(s1)
  mbx->count--;
    800027fa:	2404a783          	lw	a5,576(s1)
    800027fe:	37fd                	addiw	a5,a5,-1
    80002800:	24f4a023          	sw	a5,576(s1)

  wakeup(mbx); // Wake up sender
    80002804:	8526                	mv	a0,s1
    80002806:	9cbff0ef          	jal	ra,800021d0 <wakeup>
  release(&mbx->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	d5efe0ef          	jal	ra,80000d6a <release>
  return 0;
    80002810:	4501                	li	a0,0
    80002812:	a029                	j	8000281c <sys_recv+0xf4>
      release(&mbx->lock);
    80002814:	8526                	mv	a0,s1
    80002816:	d54fe0ef          	jal	ra,80000d6a <release>
      return -1;
    8000281a:	557d                	li	a0,-1
}
    8000281c:	60a6                	ld	ra,72(sp)
    8000281e:	6406                	ld	s0,64(sp)
    80002820:	74e2                	ld	s1,56(sp)
    80002822:	7942                	ld	s2,48(sp)
    80002824:	79a2                	ld	s3,40(sp)
    80002826:	7a02                	ld	s4,32(sp)
    80002828:	6ae2                	ld	s5,24(sp)
    8000282a:	6161                	addi	sp,sp,80
    8000282c:	8082                	ret
    release(&mbx->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	d3afe0ef          	jal	ra,80000d6a <release>
    return -1;
    80002834:	557d                	li	a0,-1
    80002836:	b7dd                	j	8000281c <sys_recv+0xf4>

0000000080002838 <sys_shmget>:

uint64
sys_shmget(void)
{
    80002838:	715d                	addi	sp,sp,-80
    8000283a:	e486                	sd	ra,72(sp)
    8000283c:	e0a2                	sd	s0,64(sp)
    8000283e:	fc26                	sd	s1,56(sp)
    80002840:	f84a                	sd	s2,48(sp)
    80002842:	f44e                	sd	s3,40(sp)
    80002844:	f052                	sd	s4,32(sp)
    80002846:	ec56                	sd	s5,24(sp)
    80002848:	e85a                	sd	s6,16(sp)
    8000284a:	0880                	addi	s0,sp,80
  int key;
  argint(0, &key);
    8000284c:	fbc40593          	addi	a1,s0,-68
    80002850:	4501                	li	a0,0
    80002852:	6d8000ef          	jal	ra,80002f2a <argint>
  struct proc *p = myproc();
    80002856:	9e4ff0ef          	jal	ra,80001a3a <myproc>
    8000285a:	8b2a                	mv	s6,a0
  struct shm_region *shm = 0;

  for(int i = 0; i < MAX_SHM; i++){
    8000285c:	00095917          	auipc	s2,0x95
    80002860:	20c90913          	addi	s2,s2,524 # 80097a68 <shm_regions+0x10>
  struct proc *p = myproc();
    80002864:	84ca                	mv	s1,s2
  for(int i = 0; i < MAX_SHM; i++){
    80002866:	4981                	li	s3,0
    80002868:	4aa1                	li	s5,8
    8000286a:	a809                	j	8000287c <sys_shmget+0x44>
    acquire(&shm_regions[i].lock);
    if(shm_regions[i].ref_cnt > 0 && shm_regions[i].key == key){
      shm = &shm_regions[i];
      goto found;
    }
    release(&shm_regions[i].lock);
    8000286c:	8552                	mv	a0,s4
    8000286e:	cfcfe0ef          	jal	ra,80000d6a <release>
  for(int i = 0; i < MAX_SHM; i++){
    80002872:	2985                	addiw	s3,s3,1
    80002874:	02848493          	addi	s1,s1,40
    80002878:	07598b63          	beq	s3,s5,800028ee <sys_shmget+0xb6>
    acquire(&shm_regions[i].lock);
    8000287c:	8a26                	mv	s4,s1
    8000287e:	8526                	mv	a0,s1
    80002880:	c52fe0ef          	jal	ra,80000cd2 <acquire>
    if(shm_regions[i].ref_cnt > 0 && shm_regions[i].key == key){
    80002884:	ffc4a783          	lw	a5,-4(s1)
    80002888:	fef052e3          	blez	a5,8000286c <sys_shmget+0x34>
    8000288c:	ff84a703          	lw	a4,-8(s1)
    80002890:	fbc42783          	lw	a5,-68(s0)
    80002894:	fcf71ce3          	bne	a4,a5,8000286c <sys_shmget+0x34>
      shm = &shm_regions[i];
    80002898:	00299913          	slli	s2,s3,0x2
    8000289c:	99ca                	add	s3,s3,s2
    8000289e:	098e                	slli	s3,s3,0x3
    800028a0:	00095917          	auipc	s2,0x95
    800028a4:	1b890913          	addi	s2,s2,440 # 80097a58 <shm_regions>
    800028a8:	994e                	add	s2,s2,s3
    release(&shm_regions[i].lock);
  }
  return -1;

found:
  shm->ref_cnt++;
    800028aa:	00c92783          	lw	a5,12(s2)
    800028ae:	2785                	addiw	a5,a5,1
    800028b0:	00f92623          	sw	a5,12(s2)
  uint64 va = PGROUNDUP(p->sz);
    800028b4:	048b3483          	ld	s1,72(s6)
    800028b8:	6785                	lui	a5,0x1
    800028ba:	17fd                	addi	a5,a5,-1
    800028bc:	94be                	add	s1,s1,a5
    800028be:	77fd                	lui	a5,0xfffff
    800028c0:	8cfd                	and	s1,s1,a5
  if(mappages(p->pagetable, va, PGSIZE, shm->pa, PTE_W|PTE_R|PTE_U) < 0){
    800028c2:	4759                	li	a4,22
    800028c4:	00093683          	ld	a3,0(s2)
    800028c8:	6605                	lui	a2,0x1
    800028ca:	85a6                	mv	a1,s1
    800028cc:	050b3503          	ld	a0,80(s6)
    800028d0:	82bfe0ef          	jal	ra,800010fa <mappages>
    800028d4:	0a054a63          	bltz	a0,80002988 <sys_shmget+0x150>
    shm->ref_cnt--;
    if(shm->ref_cnt == 0) kfree((void*)shm->pa);
    release(&shm->lock);
    return -1;
  }
  p->sz += PGSIZE;
    800028d8:	048b3783          	ld	a5,72(s6)
    800028dc:	6705                	lui	a4,0x1
    800028de:	97ba                	add	a5,a5,a4
    800028e0:	04fb3423          	sd	a5,72(s6)
  release(&shm->lock);
    800028e4:	01090513          	addi	a0,s2,16
    800028e8:	c82fe0ef          	jal	ra,80000d6a <release>
  return va;
    800028ec:	a01d                	j	80002912 <sys_shmget+0xda>
  for(int i = 0; i < MAX_SHM; i++){
    800028ee:	4481                	li	s1,0
    800028f0:	49a1                	li	s3,8
    acquire(&shm_regions[i].lock);
    800028f2:	8a4a                	mv	s4,s2
    800028f4:	854a                	mv	a0,s2
    800028f6:	bdcfe0ef          	jal	ra,80000cd2 <acquire>
    if(shm_regions[i].ref_cnt == 0){
    800028fa:	ffc92783          	lw	a5,-4(s2)
    800028fe:	c78d                	beqz	a5,80002928 <sys_shmget+0xf0>
    release(&shm_regions[i].lock);
    80002900:	854a                	mv	a0,s2
    80002902:	c68fe0ef          	jal	ra,80000d6a <release>
  for(int i = 0; i < MAX_SHM; i++){
    80002906:	2485                	addiw	s1,s1,1
    80002908:	02890913          	addi	s2,s2,40
    8000290c:	ff3493e3          	bne	s1,s3,800028f2 <sys_shmget+0xba>
  return -1;
    80002910:	54fd                	li	s1,-1
}
    80002912:	8526                	mv	a0,s1
    80002914:	60a6                	ld	ra,72(sp)
    80002916:	6406                	ld	s0,64(sp)
    80002918:	74e2                	ld	s1,56(sp)
    8000291a:	7942                	ld	s2,48(sp)
    8000291c:	79a2                	ld	s3,40(sp)
    8000291e:	7a02                	ld	s4,32(sp)
    80002920:	6ae2                	ld	s5,24(sp)
    80002922:	6b42                	ld	s6,16(sp)
    80002924:	6161                	addi	sp,sp,80
    80002926:	8082                	ret
      shm->key = key;
    80002928:	00249793          	slli	a5,s1,0x2
    8000292c:	97a6                	add	a5,a5,s1
    8000292e:	078e                	slli	a5,a5,0x3
    80002930:	00095917          	auipc	s2,0x95
    80002934:	0f890913          	addi	s2,s2,248 # 80097a28 <pid_lock>
    80002938:	993e                	add	s2,s2,a5
    8000293a:	fbc42783          	lw	a5,-68(s0)
    8000293e:	02f92c23          	sw	a5,56(s2)
      shm->pa = (uint64)kalloc();
    80002942:	9bcfe0ef          	jal	ra,80000afe <kalloc>
    80002946:	02a93823          	sd	a0,48(s2)
      if(shm->pa == 0){
    8000294a:	c915                	beqz	a0,8000297e <sys_shmget+0x146>
      shm = &shm_regions[i];
    8000294c:	00249993          	slli	s3,s1,0x2
    80002950:	00998933          	add	s2,s3,s1
    80002954:	00391793          	slli	a5,s2,0x3
    80002958:	00095917          	auipc	s2,0x95
    8000295c:	10090913          	addi	s2,s2,256 # 80097a58 <shm_regions>
    80002960:	993e                	add	s2,s2,a5
      memset((void*)shm->pa, 0, PGSIZE);
    80002962:	6605                	lui	a2,0x1
    80002964:	4581                	li	a1,0
    80002966:	c40fe0ef          	jal	ra,80000da6 <memset>
      shm->ref_cnt = 0;
    8000296a:	94ce                	add	s1,s1,s3
    8000296c:	048e                	slli	s1,s1,0x3
    8000296e:	00095797          	auipc	a5,0x95
    80002972:	0ba78793          	addi	a5,a5,186 # 80097a28 <pid_lock>
    80002976:	94be                	add	s1,s1,a5
    80002978:	0204ae23          	sw	zero,60(s1)
      goto found;
    8000297c:	b73d                	j	800028aa <sys_shmget+0x72>
        release(&shm_regions[i].lock);
    8000297e:	8552                	mv	a0,s4
    80002980:	beafe0ef          	jal	ra,80000d6a <release>
        return -1;
    80002984:	54fd                	li	s1,-1
    80002986:	b771                	j	80002912 <sys_shmget+0xda>
    shm->ref_cnt--;
    80002988:	00c92783          	lw	a5,12(s2)
    8000298c:	37fd                	addiw	a5,a5,-1
    8000298e:	0007871b          	sext.w	a4,a5
    80002992:	00f92623          	sw	a5,12(s2)
    if(shm->ref_cnt == 0) kfree((void*)shm->pa);
    80002996:	c719                	beqz	a4,800029a4 <sys_shmget+0x16c>
    release(&shm->lock);
    80002998:	01090513          	addi	a0,s2,16
    8000299c:	bcefe0ef          	jal	ra,80000d6a <release>
    return -1;
    800029a0:	54fd                	li	s1,-1
    800029a2:	bf85                	j	80002912 <sys_shmget+0xda>
    if(shm->ref_cnt == 0) kfree((void*)shm->pa);
    800029a4:	00093503          	ld	a0,0(s2)
    800029a8:	814fe0ef          	jal	ra,800009bc <kfree>
    800029ac:	b7f5                	j	80002998 <sys_shmget+0x160>

00000000800029ae <sys_shmrelease>:

uint64
sys_shmrelease(void)
{
    800029ae:	715d                	addi	sp,sp,-80
    800029b0:	e486                	sd	ra,72(sp)
    800029b2:	e0a2                	sd	s0,64(sp)
    800029b4:	fc26                	sd	s1,56(sp)
    800029b6:	f84a                	sd	s2,48(sp)
    800029b8:	f44e                	sd	s3,40(sp)
    800029ba:	f052                	sd	s4,32(sp)
    800029bc:	ec56                	sd	s5,24(sp)
    800029be:	0880                	addi	s0,sp,80
  uint64 va;
  argaddr(0, &va);
    800029c0:	fb840593          	addi	a1,s0,-72
    800029c4:	4501                	li	a0,0
    800029c6:	580000ef          	jal	ra,80002f46 <argaddr>
  struct proc *p = myproc();
    800029ca:	870ff0ef          	jal	ra,80001a3a <myproc>
    800029ce:	8a2a                	mv	s4,a0
  va = PGROUNDDOWN(va);
    800029d0:	75fd                	lui	a1,0xfffff
    800029d2:	fb843783          	ld	a5,-72(s0)
    800029d6:	8dfd                	and	a1,a1,a5
    800029d8:	fab43c23          	sd	a1,-72(s0)

  pte_t *pte = walk(p->pagetable, va, 0);
    800029dc:	4601                	li	a2,0
    800029de:	6928                	ld	a0,80(a0)
    800029e0:	e42fe0ef          	jal	ra,80001022 <walk>
  if(!pte || !(*pte & PTE_V)) return -1;
    800029e4:	cd5d                	beqz	a0,80002aa2 <sys_shmrelease+0xf4>
    800029e6:	00053983          	ld	s3,0(a0)
    800029ea:	0019f793          	andi	a5,s3,1
    800029ee:	557d                	li	a0,-1
    800029f0:	cfb5                	beqz	a5,80002a6c <sys_shmrelease+0xbe>
  uint64 pa = PTE2PA(*pte);
    800029f2:	00a9d993          	srli	s3,s3,0xa
    800029f6:	09b2                	slli	s3,s3,0xc

  struct shm_region *shm = 0;
  for(int i = 0; i < MAX_SHM; i++){
    800029f8:	00095497          	auipc	s1,0x95
    800029fc:	07048493          	addi	s1,s1,112 # 80097a68 <shm_regions+0x10>
    80002a00:	4901                	li	s2,0
    80002a02:	4aa1                	li	s5,8
    acquire(&shm_regions[i].lock);
    80002a04:	8526                	mv	a0,s1
    80002a06:	accfe0ef          	jal	ra,80000cd2 <acquire>
    if(shm_regions[i].pa == pa){
    80002a0a:	ff04b783          	ld	a5,-16(s1)
    80002a0e:	01378c63          	beq	a5,s3,80002a26 <sys_shmrelease+0x78>
      shm = &shm_regions[i];
      break;
    }
    release(&shm_regions[i].lock);
    80002a12:	8526                	mv	a0,s1
    80002a14:	b56fe0ef          	jal	ra,80000d6a <release>
  for(int i = 0; i < MAX_SHM; i++){
    80002a18:	2905                	addiw	s2,s2,1
    80002a1a:	02848493          	addi	s1,s1,40
    80002a1e:	ff5913e3          	bne	s2,s5,80002a04 <sys_shmrelease+0x56>
  }

  if(!shm) return -1;
    80002a22:	557d                	li	a0,-1
    80002a24:	a0a1                	j	80002a6c <sys_shmrelease+0xbe>

  uvmunmap(p->pagetable, va, 1, 0); // Unmap but don't free pa here
    80002a26:	4681                	li	a3,0
    80002a28:	4605                	li	a2,1
    80002a2a:	fb843583          	ld	a1,-72(s0)
    80002a2e:	050a3503          	ld	a0,80(s4)
    80002a32:	895fe0ef          	jal	ra,800012c6 <uvmunmap>
  shm->ref_cnt--;
    80002a36:	00291793          	slli	a5,s2,0x2
    80002a3a:	97ca                	add	a5,a5,s2
    80002a3c:	078e                	slli	a5,a5,0x3
    80002a3e:	00095717          	auipc	a4,0x95
    80002a42:	fea70713          	addi	a4,a4,-22 # 80097a28 <pid_lock>
    80002a46:	97ba                	add	a5,a5,a4
    80002a48:	5fd8                	lw	a4,60(a5)
    80002a4a:	377d                	addiw	a4,a4,-1
    80002a4c:	0007069b          	sext.w	a3,a4
    80002a50:	dfd8                	sw	a4,60(a5)
  if(shm->ref_cnt == 0){
    80002a52:	c695                	beqz	a3,80002a7e <sys_shmrelease+0xd0>
    kfree((void*)shm->pa);
    shm->pa = 0;
    shm->key = 0;
  }
  release(&shm->lock);
    80002a54:	00291513          	slli	a0,s2,0x2
    80002a58:	992a                	add	s2,s2,a0
    80002a5a:	090e                	slli	s2,s2,0x3
    80002a5c:	00095517          	auipc	a0,0x95
    80002a60:	00c50513          	addi	a0,a0,12 # 80097a68 <shm_regions+0x10>
    80002a64:	954a                	add	a0,a0,s2
    80002a66:	b04fe0ef          	jal	ra,80000d6a <release>
  return 0;
    80002a6a:	4501                	li	a0,0
}
    80002a6c:	60a6                	ld	ra,72(sp)
    80002a6e:	6406                	ld	s0,64(sp)
    80002a70:	74e2                	ld	s1,56(sp)
    80002a72:	7942                	ld	s2,48(sp)
    80002a74:	79a2                	ld	s3,40(sp)
    80002a76:	7a02                	ld	s4,32(sp)
    80002a78:	6ae2                	ld	s5,24(sp)
    80002a7a:	6161                	addi	sp,sp,80
    80002a7c:	8082                	ret
    kfree((void*)shm->pa);
    80002a7e:	00291493          	slli	s1,s2,0x2
    80002a82:	94ca                	add	s1,s1,s2
    80002a84:	00349793          	slli	a5,s1,0x3
    80002a88:	00095497          	auipc	s1,0x95
    80002a8c:	fa048493          	addi	s1,s1,-96 # 80097a28 <pid_lock>
    80002a90:	94be                	add	s1,s1,a5
    80002a92:	7888                	ld	a0,48(s1)
    80002a94:	f29fd0ef          	jal	ra,800009bc <kfree>
    shm->pa = 0;
    80002a98:	0204b823          	sd	zero,48(s1)
    shm->key = 0;
    80002a9c:	0204ac23          	sw	zero,56(s1)
    80002aa0:	bf55                	j	80002a54 <sys_shmrelease+0xa6>
  if(!pte || !(*pte & PTE_V)) return -1;
    80002aa2:	557d                	li	a0,-1
    80002aa4:	b7e1                	j	80002a6c <sys_shmrelease+0xbe>

0000000080002aa6 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002aa6:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002aaa:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002aae:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002ab0:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002ab2:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002ab6:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002aba:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002abe:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002ac2:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002ac6:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002aca:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002ace:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002ad2:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002ad6:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002ada:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ff53a08>
        ld sp, 8(a1)
    80002ade:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002ae2:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002ae4:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002ae6:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002aea:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002aee:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002af2:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002af6:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002afa:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002afe:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002b02:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002b06:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002b0a:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002b0e:	8082                	ret

0000000080002b10 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b10:	1141                	addi	sp,sp,-16
    80002b12:	e406                	sd	ra,8(sp)
    80002b14:	e022                	sd	s0,0(sp)
    80002b16:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b18:	00005597          	auipc	a1,0x5
    80002b1c:	81058593          	addi	a1,a1,-2032 # 80007328 <states.0+0x30>
    80002b20:	0009d517          	auipc	a0,0x9d
    80002b24:	6f850513          	addi	a0,a0,1784 # 800a0218 <tickslock>
    80002b28:	92afe0ef          	jal	ra,80000c52 <initlock>
}
    80002b2c:	60a2                	ld	ra,8(sp)
    80002b2e:	6402                	ld	s0,0(sp)
    80002b30:	0141                	addi	sp,sp,16
    80002b32:	8082                	ret

0000000080002b34 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b34:	1141                	addi	sp,sp,-16
    80002b36:	e422                	sd	s0,8(sp)
    80002b38:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3a:	00003797          	auipc	a5,0x3
    80002b3e:	e8678793          	addi	a5,a5,-378 # 800059c0 <kernelvec>
    80002b42:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b46:	6422                	ld	s0,8(sp)
    80002b48:	0141                	addi	sp,sp,16
    80002b4a:	8082                	ret

0000000080002b4c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002b4c:	1141                	addi	sp,sp,-16
    80002b4e:	e406                	sd	ra,8(sp)
    80002b50:	e022                	sd	s0,0(sp)
    80002b52:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b54:	ee7fe0ef          	jal	ra,80001a3a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b62:	04000737          	lui	a4,0x4000
    80002b66:	00003797          	auipc	a5,0x3
    80002b6a:	49a78793          	addi	a5,a5,1178 # 80006000 <_trampoline>
    80002b6e:	00003697          	auipc	a3,0x3
    80002b72:	49268693          	addi	a3,a3,1170 # 80006000 <_trampoline>
    80002b76:	8f95                	sub	a5,a5,a3
    80002b78:	177d                	addi	a4,a4,-1
    80002b7a:	0732                	slli	a4,a4,0xc
    80002b7c:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b7e:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b82:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b84:	18002773          	csrr	a4,satp
    80002b88:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b8a:	6d38                	ld	a4,88(a0)
    80002b8c:	613c                	ld	a5,64(a0)
    80002b8e:	6685                	lui	a3,0x1
    80002b90:	97b6                	add	a5,a5,a3
    80002b92:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	00000717          	auipc	a4,0x0
    80002b9a:	0f470713          	addi	a4,a4,244 # 80002c8a <usertrap>
    80002b9e:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ba0:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ba2:	8712                	mv	a4,tp
    80002ba4:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba6:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002baa:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bae:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb2:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bb6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bb8:	6f9c                	ld	a5,24(a5)
    80002bba:	14179073          	csrw	sepc,a5
}
    80002bbe:	60a2                	ld	ra,8(sp)
    80002bc0:	6402                	ld	s0,0(sp)
    80002bc2:	0141                	addi	sp,sp,16
    80002bc4:	8082                	ret

0000000080002bc6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002bd0:	e3ffe0ef          	jal	ra,80001a0e <cpuid>
    80002bd4:	cd19                	beqz	a0,80002bf2 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002bd6:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002bda:	000f4737          	lui	a4,0xf4
    80002bde:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002be2:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002be4:	14d79073          	csrw	0x14d,a5
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret
    acquire(&tickslock);
    80002bf2:	0009d497          	auipc	s1,0x9d
    80002bf6:	62648493          	addi	s1,s1,1574 # 800a0218 <tickslock>
    80002bfa:	8526                	mv	a0,s1
    80002bfc:	8d6fe0ef          	jal	ra,80000cd2 <acquire>
    ticks++;
    80002c00:	00005517          	auipc	a0,0x5
    80002c04:	d2050513          	addi	a0,a0,-736 # 80007920 <ticks>
    80002c08:	411c                	lw	a5,0(a0)
    80002c0a:	2785                	addiw	a5,a5,1
    80002c0c:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002c0e:	dc2ff0ef          	jal	ra,800021d0 <wakeup>
    release(&tickslock);
    80002c12:	8526                	mv	a0,s1
    80002c14:	956fe0ef          	jal	ra,80000d6a <release>
    80002c18:	bf7d                	j	80002bd6 <clockintr+0x10>

0000000080002c1a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c24:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002c28:	57fd                	li	a5,-1
    80002c2a:	17fe                	slli	a5,a5,0x3f
    80002c2c:	07a5                	addi	a5,a5,9
    80002c2e:	00f70d63          	beq	a4,a5,80002c48 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002c32:	57fd                	li	a5,-1
    80002c34:	17fe                	slli	a5,a5,0x3f
    80002c36:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002c38:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002c3a:	04f70463          	beq	a4,a5,80002c82 <devintr+0x68>
  }
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret
    int irq = plic_claim();
    80002c48:	621020ef          	jal	ra,80005a68 <plic_claim>
    80002c4c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c4e:	47a9                	li	a5,10
    80002c50:	02f50363          	beq	a0,a5,80002c76 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    80002c54:	4785                	li	a5,1
    80002c56:	02f50363          	beq	a0,a5,80002c7c <devintr+0x62>
    return 1;
    80002c5a:	4505                	li	a0,1
    } else if(irq){
    80002c5c:	d0ed                	beqz	s1,80002c3e <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c5e:	85a6                	mv	a1,s1
    80002c60:	00004517          	auipc	a0,0x4
    80002c64:	6d050513          	addi	a0,a0,1744 # 80007330 <states.0+0x38>
    80002c68:	85dfd0ef          	jal	ra,800004c4 <printf>
      plic_complete(irq);
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	61b020ef          	jal	ra,80005a88 <plic_complete>
    return 1;
    80002c72:	4505                	li	a0,1
    80002c74:	b7e9                	j	80002c3e <devintr+0x24>
      uartintr();
    80002c76:	ce3fd0ef          	jal	ra,80000958 <uartintr>
    80002c7a:	bfcd                	j	80002c6c <devintr+0x52>
      virtio_disk_intr();
    80002c7c:	27c030ef          	jal	ra,80005ef8 <virtio_disk_intr>
    80002c80:	b7f5                	j	80002c6c <devintr+0x52>
    clockintr();
    80002c82:	f45ff0ef          	jal	ra,80002bc6 <clockintr>
    return 2;
    80002c86:	4509                	li	a0,2
    80002c88:	bf5d                	j	80002c3e <devintr+0x24>

0000000080002c8a <usertrap>:
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	e04a                	sd	s2,0(sp)
    80002c94:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c96:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c9a:	1007f793          	andi	a5,a5,256
    80002c9e:	eba5                	bnez	a5,80002d0e <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca0:	00003797          	auipc	a5,0x3
    80002ca4:	d2078793          	addi	a5,a5,-736 # 800059c0 <kernelvec>
    80002ca8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cac:	d8ffe0ef          	jal	ra,80001a3a <myproc>
    80002cb0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cb2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb4:	14102773          	csrr	a4,sepc
    80002cb8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cba:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cbe:	47a1                	li	a5,8
    80002cc0:	04f70d63          	beq	a4,a5,80002d1a <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    80002cc4:	f57ff0ef          	jal	ra,80002c1a <devintr>
    80002cc8:	892a                	mv	s2,a0
    80002cca:	e945                	bnez	a0,80002d7a <usertrap+0xf0>
    80002ccc:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002cd0:	47bd                	li	a5,15
    80002cd2:	08f70863          	beq	a4,a5,80002d62 <usertrap+0xd8>
    80002cd6:	14202773          	csrr	a4,scause
    80002cda:	47b5                	li	a5,13
    80002cdc:	08f70363          	beq	a4,a5,80002d62 <usertrap+0xd8>
    80002ce0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002ce4:	5890                	lw	a2,48(s1)
    80002ce6:	00004517          	auipc	a0,0x4
    80002cea:	68a50513          	addi	a0,a0,1674 # 80007370 <states.0+0x78>
    80002cee:	fd6fd0ef          	jal	ra,800004c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cf2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cf6:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002cfa:	00004517          	auipc	a0,0x4
    80002cfe:	6a650513          	addi	a0,a0,1702 # 800073a0 <states.0+0xa8>
    80002d02:	fc2fd0ef          	jal	ra,800004c4 <printf>
    setkilled(p);
    80002d06:	8526                	mv	a0,s1
    80002d08:	e90ff0ef          	jal	ra,80002398 <setkilled>
    80002d0c:	a035                	j	80002d38 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002d0e:	00004517          	auipc	a0,0x4
    80002d12:	64250513          	addi	a0,a0,1602 # 80007350 <states.0+0x58>
    80002d16:	a75fd0ef          	jal	ra,8000078a <panic>
    if(killed(p))
    80002d1a:	ea2ff0ef          	jal	ra,800023bc <killed>
    80002d1e:	ed15                	bnez	a0,80002d5a <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002d20:	6cb8                	ld	a4,88(s1)
    80002d22:	6f1c                	ld	a5,24(a4)
    80002d24:	0791                	addi	a5,a5,4
    80002d26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d30:	10079073          	csrw	sstatus,a5
    syscall();
    80002d34:	25e000ef          	jal	ra,80002f92 <syscall>
  if(killed(p))
    80002d38:	8526                	mv	a0,s1
    80002d3a:	e82ff0ef          	jal	ra,800023bc <killed>
    80002d3e:	e139                	bnez	a0,80002d84 <usertrap+0xfa>
  prepare_return();
    80002d40:	e0dff0ef          	jal	ra,80002b4c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d44:	68a8                	ld	a0,80(s1)
    80002d46:	8131                	srli	a0,a0,0xc
    80002d48:	57fd                	li	a5,-1
    80002d4a:	17fe                	slli	a5,a5,0x3f
    80002d4c:	8d5d                	or	a0,a0,a5
}
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	64a2                	ld	s1,8(sp)
    80002d54:	6902                	ld	s2,0(sp)
    80002d56:	6105                	addi	sp,sp,32
    80002d58:	8082                	ret
      kexit(-1);
    80002d5a:	557d                	li	a0,-1
    80002d5c:	d34ff0ef          	jal	ra,80002290 <kexit>
    80002d60:	b7c1                	j	80002d20 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d62:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d66:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002d6a:	164d                	addi	a2,a2,-13
    80002d6c:	00163613          	seqz	a2,a2
    80002d70:	68a8                	ld	a0,80(s1)
    80002d72:	8a3fe0ef          	jal	ra,80001614 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002d76:	f169                	bnez	a0,80002d38 <usertrap+0xae>
    80002d78:	b7a5                	j	80002ce0 <usertrap+0x56>
  if(killed(p))
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	e40ff0ef          	jal	ra,800023bc <killed>
    80002d80:	c511                	beqz	a0,80002d8c <usertrap+0x102>
    80002d82:	a011                	j	80002d86 <usertrap+0xfc>
    80002d84:	4901                	li	s2,0
    kexit(-1);
    80002d86:	557d                	li	a0,-1
    80002d88:	d08ff0ef          	jal	ra,80002290 <kexit>
  if(which_dev == 2){
    80002d8c:	4789                	li	a5,2
    80002d8e:	faf919e3          	bne	s2,a5,80002d40 <usertrap+0xb6>
    if(p) p->cpu_ticks++;
    80002d92:	1704a783          	lw	a5,368(s1)
    80002d96:	2785                	addiw	a5,a5,1
    80002d98:	16f4a823          	sw	a5,368(s1)
    yield();
    80002d9c:	bbcff0ef          	jal	ra,80002158 <yield>
    80002da0:	b745                	j	80002d40 <usertrap+0xb6>

0000000080002da2 <kerneltrap>:
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	e84a                	sd	s2,16(sp)
    80002dac:	e44e                	sd	s3,8(sp)
    80002dae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002db0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002dbc:	1004f793          	andi	a5,s1,256
    80002dc0:	c795                	beqz	a5,80002dec <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dc6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002dc8:	eb85                	bnez	a5,80002df8 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002dca:	e51ff0ef          	jal	ra,80002c1a <devintr>
    80002dce:	c91d                	beqz	a0,80002e04 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    80002dd0:	4789                	li	a5,2
    80002dd2:	04f50a63          	beq	a0,a5,80002e26 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dd6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dda:	10049073          	csrw	sstatus,s1
}
    80002dde:	70a2                	ld	ra,40(sp)
    80002de0:	7402                	ld	s0,32(sp)
    80002de2:	64e2                	ld	s1,24(sp)
    80002de4:	6942                	ld	s2,16(sp)
    80002de6:	69a2                	ld	s3,8(sp)
    80002de8:	6145                	addi	sp,sp,48
    80002dea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dec:	00004517          	auipc	a0,0x4
    80002df0:	5dc50513          	addi	a0,a0,1500 # 800073c8 <states.0+0xd0>
    80002df4:	997fd0ef          	jal	ra,8000078a <panic>
    panic("kerneltrap: interrupts enabled");
    80002df8:	00004517          	auipc	a0,0x4
    80002dfc:	5f850513          	addi	a0,a0,1528 # 800073f0 <states.0+0xf8>
    80002e00:	98bfd0ef          	jal	ra,8000078a <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e04:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e08:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002e0c:	85ce                	mv	a1,s3
    80002e0e:	00004517          	auipc	a0,0x4
    80002e12:	60250513          	addi	a0,a0,1538 # 80007410 <states.0+0x118>
    80002e16:	eaefd0ef          	jal	ra,800004c4 <printf>
    panic("kerneltrap");
    80002e1a:	00004517          	auipc	a0,0x4
    80002e1e:	61e50513          	addi	a0,a0,1566 # 80007438 <states.0+0x140>
    80002e22:	969fd0ef          	jal	ra,8000078a <panic>
  if(which_dev == 2 && myproc() != 0){
    80002e26:	c15fe0ef          	jal	ra,80001a3a <myproc>
    80002e2a:	d555                	beqz	a0,80002dd6 <kerneltrap+0x34>
    myproc()->cpu_ticks++;
    80002e2c:	c0ffe0ef          	jal	ra,80001a3a <myproc>
    80002e30:	17052783          	lw	a5,368(a0)
    80002e34:	2785                	addiw	a5,a5,1
    80002e36:	16f52823          	sw	a5,368(a0)
    yield();
    80002e3a:	b1eff0ef          	jal	ra,80002158 <yield>
    80002e3e:	bf61                	j	80002dd6 <kerneltrap+0x34>

0000000080002e40 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e40:	1101                	addi	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	e426                	sd	s1,8(sp)
    80002e48:	1000                	addi	s0,sp,32
    80002e4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e4c:	beffe0ef          	jal	ra,80001a3a <myproc>
  switch (n) {
    80002e50:	4795                	li	a5,5
    80002e52:	0497e163          	bltu	a5,s1,80002e94 <argraw+0x54>
    80002e56:	048a                	slli	s1,s1,0x2
    80002e58:	00004717          	auipc	a4,0x4
    80002e5c:	61870713          	addi	a4,a4,1560 # 80007470 <states.0+0x178>
    80002e60:	94ba                	add	s1,s1,a4
    80002e62:	409c                	lw	a5,0(s1)
    80002e64:	97ba                	add	a5,a5,a4
    80002e66:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e68:	6d3c                	ld	a5,88(a0)
    80002e6a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	64a2                	ld	s1,8(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret
    return p->trapframe->a1;
    80002e76:	6d3c                	ld	a5,88(a0)
    80002e78:	7fa8                	ld	a0,120(a5)
    80002e7a:	bfcd                	j	80002e6c <argraw+0x2c>
    return p->trapframe->a2;
    80002e7c:	6d3c                	ld	a5,88(a0)
    80002e7e:	63c8                	ld	a0,128(a5)
    80002e80:	b7f5                	j	80002e6c <argraw+0x2c>
    return p->trapframe->a3;
    80002e82:	6d3c                	ld	a5,88(a0)
    80002e84:	67c8                	ld	a0,136(a5)
    80002e86:	b7dd                	j	80002e6c <argraw+0x2c>
    return p->trapframe->a4;
    80002e88:	6d3c                	ld	a5,88(a0)
    80002e8a:	6bc8                	ld	a0,144(a5)
    80002e8c:	b7c5                	j	80002e6c <argraw+0x2c>
    return p->trapframe->a5;
    80002e8e:	6d3c                	ld	a5,88(a0)
    80002e90:	6fc8                	ld	a0,152(a5)
    80002e92:	bfe9                	j	80002e6c <argraw+0x2c>
  panic("argraw");
    80002e94:	00004517          	auipc	a0,0x4
    80002e98:	5b450513          	addi	a0,a0,1460 # 80007448 <states.0+0x150>
    80002e9c:	8effd0ef          	jal	ra,8000078a <panic>

0000000080002ea0 <fetchaddr>:
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	e426                	sd	s1,8(sp)
    80002ea8:	e04a                	sd	s2,0(sp)
    80002eaa:	1000                	addi	s0,sp,32
    80002eac:	84aa                	mv	s1,a0
    80002eae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eb0:	b8bfe0ef          	jal	ra,80001a3a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002eb4:	653c                	ld	a5,72(a0)
    80002eb6:	02f4f663          	bgeu	s1,a5,80002ee2 <fetchaddr+0x42>
    80002eba:	00848713          	addi	a4,s1,8
    80002ebe:	02e7e463          	bltu	a5,a4,80002ee6 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ec2:	46a1                	li	a3,8
    80002ec4:	8626                	mv	a2,s1
    80002ec6:	85ca                	mv	a1,s2
    80002ec8:	6928                	ld	a0,80(a0)
    80002eca:	8f9fe0ef          	jal	ra,800017c2 <copyin>
    80002ece:	00a03533          	snez	a0,a0
    80002ed2:	40a00533          	neg	a0,a0
}
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	64a2                	ld	s1,8(sp)
    80002edc:	6902                	ld	s2,0(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret
    return -1;
    80002ee2:	557d                	li	a0,-1
    80002ee4:	bfcd                	j	80002ed6 <fetchaddr+0x36>
    80002ee6:	557d                	li	a0,-1
    80002ee8:	b7fd                	j	80002ed6 <fetchaddr+0x36>

0000000080002eea <fetchstr>:
{
    80002eea:	7179                	addi	sp,sp,-48
    80002eec:	f406                	sd	ra,40(sp)
    80002eee:	f022                	sd	s0,32(sp)
    80002ef0:	ec26                	sd	s1,24(sp)
    80002ef2:	e84a                	sd	s2,16(sp)
    80002ef4:	e44e                	sd	s3,8(sp)
    80002ef6:	1800                	addi	s0,sp,48
    80002ef8:	892a                	mv	s2,a0
    80002efa:	84ae                	mv	s1,a1
    80002efc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002efe:	b3dfe0ef          	jal	ra,80001a3a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f02:	86ce                	mv	a3,s3
    80002f04:	864a                	mv	a2,s2
    80002f06:	85a6                	mv	a1,s1
    80002f08:	6928                	ld	a0,80(a0)
    80002f0a:	e5afe0ef          	jal	ra,80001564 <copyinstr>
    80002f0e:	00054c63          	bltz	a0,80002f26 <fetchstr+0x3c>
  return strlen(buf);
    80002f12:	8526                	mv	a0,s1
    80002f14:	80afe0ef          	jal	ra,80000f1e <strlen>
}
    80002f18:	70a2                	ld	ra,40(sp)
    80002f1a:	7402                	ld	s0,32(sp)
    80002f1c:	64e2                	ld	s1,24(sp)
    80002f1e:	6942                	ld	s2,16(sp)
    80002f20:	69a2                	ld	s3,8(sp)
    80002f22:	6145                	addi	sp,sp,48
    80002f24:	8082                	ret
    return -1;
    80002f26:	557d                	li	a0,-1
    80002f28:	bfc5                	j	80002f18 <fetchstr+0x2e>

0000000080002f2a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f2a:	1101                	addi	sp,sp,-32
    80002f2c:	ec06                	sd	ra,24(sp)
    80002f2e:	e822                	sd	s0,16(sp)
    80002f30:	e426                	sd	s1,8(sp)
    80002f32:	1000                	addi	s0,sp,32
    80002f34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f36:	f0bff0ef          	jal	ra,80002e40 <argraw>
    80002f3a:	c088                	sw	a0,0(s1)
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	64a2                	ld	s1,8(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	e426                	sd	s1,8(sp)
    80002f4e:	1000                	addi	s0,sp,32
    80002f50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f52:	eefff0ef          	jal	ra,80002e40 <argraw>
    80002f56:	e088                	sd	a0,0(s1)
}
    80002f58:	60e2                	ld	ra,24(sp)
    80002f5a:	6442                	ld	s0,16(sp)
    80002f5c:	64a2                	ld	s1,8(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret

0000000080002f62 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f62:	7179                	addi	sp,sp,-48
    80002f64:	f406                	sd	ra,40(sp)
    80002f66:	f022                	sd	s0,32(sp)
    80002f68:	ec26                	sd	s1,24(sp)
    80002f6a:	e84a                	sd	s2,16(sp)
    80002f6c:	1800                	addi	s0,sp,48
    80002f6e:	84ae                	mv	s1,a1
    80002f70:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f72:	fd840593          	addi	a1,s0,-40
    80002f76:	fd1ff0ef          	jal	ra,80002f46 <argaddr>
  return fetchstr(addr, buf, max);
    80002f7a:	864a                	mv	a2,s2
    80002f7c:	85a6                	mv	a1,s1
    80002f7e:	fd843503          	ld	a0,-40(s0)
    80002f82:	f69ff0ef          	jal	ra,80002eea <fetchstr>
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6942                	ld	s2,16(sp)
    80002f8e:	6145                	addi	sp,sp,48
    80002f90:	8082                	ret

0000000080002f92 <syscall>:
[SYS_shmrelease] sys_shmrelease,
};

void
syscall(void)
{
    80002f92:	1101                	addi	sp,sp,-32
    80002f94:	ec06                	sd	ra,24(sp)
    80002f96:	e822                	sd	s0,16(sp)
    80002f98:	e426                	sd	s1,8(sp)
    80002f9a:	e04a                	sd	s2,0(sp)
    80002f9c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f9e:	a9dfe0ef          	jal	ra,80001a3a <myproc>
    80002fa2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fa4:	05853903          	ld	s2,88(a0)
    80002fa8:	0a893783          	ld	a5,168(s2)
    80002fac:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fb0:	37fd                	addiw	a5,a5,-1
    80002fb2:	4761                	li	a4,24
    80002fb4:	00f76f63          	bltu	a4,a5,80002fd2 <syscall+0x40>
    80002fb8:	00369713          	slli	a4,a3,0x3
    80002fbc:	00004797          	auipc	a5,0x4
    80002fc0:	4cc78793          	addi	a5,a5,1228 # 80007488 <syscalls>
    80002fc4:	97ba                	add	a5,a5,a4
    80002fc6:	639c                	ld	a5,0(a5)
    80002fc8:	c789                	beqz	a5,80002fd2 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fca:	9782                	jalr	a5
    80002fcc:	06a93823          	sd	a0,112(s2)
    80002fd0:	a829                	j	80002fea <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fd2:	15848613          	addi	a2,s1,344
    80002fd6:	588c                	lw	a1,48(s1)
    80002fd8:	00004517          	auipc	a0,0x4
    80002fdc:	47850513          	addi	a0,a0,1144 # 80007450 <states.0+0x158>
    80002fe0:	ce4fd0ef          	jal	ra,800004c4 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fe4:	6cbc                	ld	a5,88(s1)
    80002fe6:	577d                	li	a4,-1
    80002fe8:	fbb8                	sd	a4,112(a5)
  }
}
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	64a2                	ld	s1,8(sp)
    80002ff0:	6902                	ld	s2,0(sp)
    80002ff2:	6105                	addi	sp,sp,32
    80002ff4:	8082                	ret

0000000080002ff6 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ffe:	fec40593          	addi	a1,s0,-20
    80003002:	4501                	li	a0,0
    80003004:	f27ff0ef          	jal	ra,80002f2a <argint>
  kexit(n);
    80003008:	fec42503          	lw	a0,-20(s0)
    8000300c:	a84ff0ef          	jal	ra,80002290 <kexit>
  return 0;  // not reached
}
    80003010:	4501                	li	a0,0
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000301a:	1141                	addi	sp,sp,-16
    8000301c:	e406                	sd	ra,8(sp)
    8000301e:	e022                	sd	s0,0(sp)
    80003020:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003022:	a19fe0ef          	jal	ra,80001a3a <myproc>
}
    80003026:	5908                	lw	a0,48(a0)
    80003028:	60a2                	ld	ra,8(sp)
    8000302a:	6402                	ld	s0,0(sp)
    8000302c:	0141                	addi	sp,sp,16
    8000302e:	8082                	ret

0000000080003030 <sys_fork>:

uint64
sys_fork(void)
{
    80003030:	1141                	addi	sp,sp,-16
    80003032:	e406                	sd	ra,8(sp)
    80003034:	e022                	sd	s0,0(sp)
    80003036:	0800                	addi	s0,sp,16
  return kfork();
    80003038:	d79fe0ef          	jal	ra,80001db0 <kfork>
}
    8000303c:	60a2                	ld	ra,8(sp)
    8000303e:	6402                	ld	s0,0(sp)
    80003040:	0141                	addi	sp,sp,16
    80003042:	8082                	ret

0000000080003044 <sys_wait>:

uint64
sys_wait(void)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000304c:	fe840593          	addi	a1,s0,-24
    80003050:	4501                	li	a0,0
    80003052:	ef5ff0ef          	jal	ra,80002f46 <argaddr>
  return kwait(p);
    80003056:	fe843503          	ld	a0,-24(s0)
    8000305a:	b8cff0ef          	jal	ra,800023e6 <kwait>
}
    8000305e:	60e2                	ld	ra,24(sp)
    80003060:	6442                	ld	s0,16(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80003070:	fd840593          	addi	a1,s0,-40
    80003074:	4501                	li	a0,0
    80003076:	eb5ff0ef          	jal	ra,80002f2a <argint>
  argint(1, &t);
    8000307a:	fdc40593          	addi	a1,s0,-36
    8000307e:	4505                	li	a0,1
    80003080:	eabff0ef          	jal	ra,80002f2a <argint>
  addr = myproc()->sz;
    80003084:	9b7fe0ef          	jal	ra,80001a3a <myproc>
    80003088:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    8000308a:	fdc42703          	lw	a4,-36(s0)
    8000308e:	4785                	li	a5,1
    80003090:	02f70763          	beq	a4,a5,800030be <sys_sbrk+0x58>
    80003094:	fd842783          	lw	a5,-40(s0)
    80003098:	0207c363          	bltz	a5,800030be <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    8000309c:	97a6                	add	a5,a5,s1
    8000309e:	0297ee63          	bltu	a5,s1,800030da <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    800030a2:	02000737          	lui	a4,0x2000
    800030a6:	177d                	addi	a4,a4,-1
    800030a8:	0736                	slli	a4,a4,0xd
    800030aa:	02f76a63          	bltu	a4,a5,800030de <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    800030ae:	98dfe0ef          	jal	ra,80001a3a <myproc>
    800030b2:	fd842703          	lw	a4,-40(s0)
    800030b6:	653c                	ld	a5,72(a0)
    800030b8:	97ba                	add	a5,a5,a4
    800030ba:	e53c                	sd	a5,72(a0)
    800030bc:	a039                	j	800030ca <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    800030be:	fd842503          	lw	a0,-40(s0)
    800030c2:	c8dfe0ef          	jal	ra,80001d4e <growproc>
    800030c6:	00054863          	bltz	a0,800030d6 <sys_sbrk+0x70>
  }
  return addr;
}
    800030ca:	8526                	mv	a0,s1
    800030cc:	70a2                	ld	ra,40(sp)
    800030ce:	7402                	ld	s0,32(sp)
    800030d0:	64e2                	ld	s1,24(sp)
    800030d2:	6145                	addi	sp,sp,48
    800030d4:	8082                	ret
      return -1;
    800030d6:	54fd                	li	s1,-1
    800030d8:	bfcd                	j	800030ca <sys_sbrk+0x64>
      return -1;
    800030da:	54fd                	li	s1,-1
    800030dc:	b7fd                	j	800030ca <sys_sbrk+0x64>
      return -1;
    800030de:	54fd                	li	s1,-1
    800030e0:	b7ed                	j	800030ca <sys_sbrk+0x64>

00000000800030e2 <sys_pause>:

uint64
sys_pause(void)
{
    800030e2:	7139                	addi	sp,sp,-64
    800030e4:	fc06                	sd	ra,56(sp)
    800030e6:	f822                	sd	s0,48(sp)
    800030e8:	f426                	sd	s1,40(sp)
    800030ea:	f04a                	sd	s2,32(sp)
    800030ec:	ec4e                	sd	s3,24(sp)
    800030ee:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030f0:	fcc40593          	addi	a1,s0,-52
    800030f4:	4501                	li	a0,0
    800030f6:	e35ff0ef          	jal	ra,80002f2a <argint>
  if(n < 0)
    800030fa:	fcc42783          	lw	a5,-52(s0)
    800030fe:	0607c563          	bltz	a5,80003168 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80003102:	0009d517          	auipc	a0,0x9d
    80003106:	11650513          	addi	a0,a0,278 # 800a0218 <tickslock>
    8000310a:	bc9fd0ef          	jal	ra,80000cd2 <acquire>
  ticks0 = ticks;
    8000310e:	00005917          	auipc	s2,0x5
    80003112:	81292903          	lw	s2,-2030(s2) # 80007920 <ticks>
  while(ticks - ticks0 < n){
    80003116:	fcc42783          	lw	a5,-52(s0)
    8000311a:	cb8d                	beqz	a5,8000314c <sys_pause+0x6a>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000311c:	0009d997          	auipc	s3,0x9d
    80003120:	0fc98993          	addi	s3,s3,252 # 800a0218 <tickslock>
    80003124:	00004497          	auipc	s1,0x4
    80003128:	7fc48493          	addi	s1,s1,2044 # 80007920 <ticks>
    if(killed(myproc())){
    8000312c:	90ffe0ef          	jal	ra,80001a3a <myproc>
    80003130:	a8cff0ef          	jal	ra,800023bc <killed>
    80003134:	ed0d                	bnez	a0,8000316e <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80003136:	85ce                	mv	a1,s3
    80003138:	8526                	mv	a0,s1
    8000313a:	84aff0ef          	jal	ra,80002184 <sleep>
  while(ticks - ticks0 < n){
    8000313e:	409c                	lw	a5,0(s1)
    80003140:	412787bb          	subw	a5,a5,s2
    80003144:	fcc42703          	lw	a4,-52(s0)
    80003148:	fee7e2e3          	bltu	a5,a4,8000312c <sys_pause+0x4a>
  }
  release(&tickslock);
    8000314c:	0009d517          	auipc	a0,0x9d
    80003150:	0cc50513          	addi	a0,a0,204 # 800a0218 <tickslock>
    80003154:	c17fd0ef          	jal	ra,80000d6a <release>
  return 0;
    80003158:	4501                	li	a0,0
}
    8000315a:	70e2                	ld	ra,56(sp)
    8000315c:	7442                	ld	s0,48(sp)
    8000315e:	74a2                	ld	s1,40(sp)
    80003160:	7902                	ld	s2,32(sp)
    80003162:	69e2                	ld	s3,24(sp)
    80003164:	6121                	addi	sp,sp,64
    80003166:	8082                	ret
    n = 0;
    80003168:	fc042623          	sw	zero,-52(s0)
    8000316c:	bf59                	j	80003102 <sys_pause+0x20>
      release(&tickslock);
    8000316e:	0009d517          	auipc	a0,0x9d
    80003172:	0aa50513          	addi	a0,a0,170 # 800a0218 <tickslock>
    80003176:	bf5fd0ef          	jal	ra,80000d6a <release>
      return -1;
    8000317a:	557d                	li	a0,-1
    8000317c:	bff9                	j	8000315a <sys_pause+0x78>

000000008000317e <sys_kill>:

uint64
sys_kill(void)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003186:	fec40593          	addi	a1,s0,-20
    8000318a:	4501                	li	a0,0
    8000318c:	d9fff0ef          	jal	ra,80002f2a <argint>
  return kkill(pid);
    80003190:	fec42503          	lw	a0,-20(s0)
    80003194:	99eff0ef          	jal	ra,80002332 <kkill>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031aa:	0009d517          	auipc	a0,0x9d
    800031ae:	06e50513          	addi	a0,a0,110 # 800a0218 <tickslock>
    800031b2:	b21fd0ef          	jal	ra,80000cd2 <acquire>
  xticks = ticks;
    800031b6:	00004497          	auipc	s1,0x4
    800031ba:	76a4a483          	lw	s1,1898(s1) # 80007920 <ticks>
  release(&tickslock);
    800031be:	0009d517          	auipc	a0,0x9d
    800031c2:	05a50513          	addi	a0,a0,90 # 800a0218 <tickslock>
    800031c6:	ba5fd0ef          	jal	ra,80000d6a <release>
  return xticks;
}
    800031ca:	02049513          	slli	a0,s1,0x20
    800031ce:	9101                	srli	a0,a0,0x20
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031da:	7179                	addi	sp,sp,-48
    800031dc:	f406                	sd	ra,40(sp)
    800031de:	f022                	sd	s0,32(sp)
    800031e0:	ec26                	sd	s1,24(sp)
    800031e2:	e84a                	sd	s2,16(sp)
    800031e4:	e44e                	sd	s3,8(sp)
    800031e6:	e052                	sd	s4,0(sp)
    800031e8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031ea:	00004597          	auipc	a1,0x4
    800031ee:	36e58593          	addi	a1,a1,878 # 80007558 <syscalls+0xd0>
    800031f2:	0009d517          	auipc	a0,0x9d
    800031f6:	03e50513          	addi	a0,a0,62 # 800a0230 <bcache>
    800031fa:	a59fd0ef          	jal	ra,80000c52 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031fe:	000a5797          	auipc	a5,0xa5
    80003202:	03278793          	addi	a5,a5,50 # 800a8230 <bcache+0x8000>
    80003206:	000a5717          	auipc	a4,0xa5
    8000320a:	29270713          	addi	a4,a4,658 # 800a8498 <bcache+0x8268>
    8000320e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003212:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003216:	0009d497          	auipc	s1,0x9d
    8000321a:	03248493          	addi	s1,s1,50 # 800a0248 <bcache+0x18>
    b->next = bcache.head.next;
    8000321e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003220:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003222:	00004a17          	auipc	s4,0x4
    80003226:	33ea0a13          	addi	s4,s4,830 # 80007560 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000322a:	2b893783          	ld	a5,696(s2)
    8000322e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003230:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003234:	85d2                	mv	a1,s4
    80003236:	01048513          	addi	a0,s1,16
    8000323a:	2fe010ef          	jal	ra,80004538 <initsleeplock>
    bcache.head.next->prev = b;
    8000323e:	2b893783          	ld	a5,696(s2)
    80003242:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003244:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003248:	45848493          	addi	s1,s1,1112
    8000324c:	fd349fe3          	bne	s1,s3,8000322a <binit+0x50>
  }
}
    80003250:	70a2                	ld	ra,40(sp)
    80003252:	7402                	ld	s0,32(sp)
    80003254:	64e2                	ld	s1,24(sp)
    80003256:	6942                	ld	s2,16(sp)
    80003258:	69a2                	ld	s3,8(sp)
    8000325a:	6a02                	ld	s4,0(sp)
    8000325c:	6145                	addi	sp,sp,48
    8000325e:	8082                	ret

0000000080003260 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003260:	7179                	addi	sp,sp,-48
    80003262:	f406                	sd	ra,40(sp)
    80003264:	f022                	sd	s0,32(sp)
    80003266:	ec26                	sd	s1,24(sp)
    80003268:	e84a                	sd	s2,16(sp)
    8000326a:	e44e                	sd	s3,8(sp)
    8000326c:	1800                	addi	s0,sp,48
    8000326e:	892a                	mv	s2,a0
    80003270:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003272:	0009d517          	auipc	a0,0x9d
    80003276:	fbe50513          	addi	a0,a0,-66 # 800a0230 <bcache>
    8000327a:	a59fd0ef          	jal	ra,80000cd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000327e:	000a5497          	auipc	s1,0xa5
    80003282:	26a4b483          	ld	s1,618(s1) # 800a84e8 <bcache+0x82b8>
    80003286:	000a5797          	auipc	a5,0xa5
    8000328a:	21278793          	addi	a5,a5,530 # 800a8498 <bcache+0x8268>
    8000328e:	02f48b63          	beq	s1,a5,800032c4 <bread+0x64>
    80003292:	873e                	mv	a4,a5
    80003294:	a021                	j	8000329c <bread+0x3c>
    80003296:	68a4                	ld	s1,80(s1)
    80003298:	02e48663          	beq	s1,a4,800032c4 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    8000329c:	449c                	lw	a5,8(s1)
    8000329e:	ff279ce3          	bne	a5,s2,80003296 <bread+0x36>
    800032a2:	44dc                	lw	a5,12(s1)
    800032a4:	ff3799e3          	bne	a5,s3,80003296 <bread+0x36>
      b->refcnt++;
    800032a8:	40bc                	lw	a5,64(s1)
    800032aa:	2785                	addiw	a5,a5,1
    800032ac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032ae:	0009d517          	auipc	a0,0x9d
    800032b2:	f8250513          	addi	a0,a0,-126 # 800a0230 <bcache>
    800032b6:	ab5fd0ef          	jal	ra,80000d6a <release>
      acquiresleep(&b->lock);
    800032ba:	01048513          	addi	a0,s1,16
    800032be:	2b0010ef          	jal	ra,8000456e <acquiresleep>
      return b;
    800032c2:	a889                	j	80003314 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c4:	000a5497          	auipc	s1,0xa5
    800032c8:	21c4b483          	ld	s1,540(s1) # 800a84e0 <bcache+0x82b0>
    800032cc:	000a5797          	auipc	a5,0xa5
    800032d0:	1cc78793          	addi	a5,a5,460 # 800a8498 <bcache+0x8268>
    800032d4:	00f48863          	beq	s1,a5,800032e4 <bread+0x84>
    800032d8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032da:	40bc                	lw	a5,64(s1)
    800032dc:	cb91                	beqz	a5,800032f0 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032de:	64a4                	ld	s1,72(s1)
    800032e0:	fee49de3          	bne	s1,a4,800032da <bread+0x7a>
  panic("bget: no buffers");
    800032e4:	00004517          	auipc	a0,0x4
    800032e8:	28450513          	addi	a0,a0,644 # 80007568 <syscalls+0xe0>
    800032ec:	c9efd0ef          	jal	ra,8000078a <panic>
      b->dev = dev;
    800032f0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032f4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032fc:	4785                	li	a5,1
    800032fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003300:	0009d517          	auipc	a0,0x9d
    80003304:	f3050513          	addi	a0,a0,-208 # 800a0230 <bcache>
    80003308:	a63fd0ef          	jal	ra,80000d6a <release>
      acquiresleep(&b->lock);
    8000330c:	01048513          	addi	a0,s1,16
    80003310:	25e010ef          	jal	ra,8000456e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003314:	409c                	lw	a5,0(s1)
    80003316:	cb89                	beqz	a5,80003328 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003318:	8526                	mv	a0,s1
    8000331a:	70a2                	ld	ra,40(sp)
    8000331c:	7402                	ld	s0,32(sp)
    8000331e:	64e2                	ld	s1,24(sp)
    80003320:	6942                	ld	s2,16(sp)
    80003322:	69a2                	ld	s3,8(sp)
    80003324:	6145                	addi	sp,sp,48
    80003326:	8082                	ret
    virtio_disk_rw(b, 0);
    80003328:	4581                	li	a1,0
    8000332a:	8526                	mv	a0,s1
    8000332c:	1b1020ef          	jal	ra,80005cdc <virtio_disk_rw>
    b->valid = 1;
    80003330:	4785                	li	a5,1
    80003332:	c09c                	sw	a5,0(s1)
  return b;
    80003334:	b7d5                	j	80003318 <bread+0xb8>

0000000080003336 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003342:	0541                	addi	a0,a0,16
    80003344:	2a8010ef          	jal	ra,800045ec <holdingsleep>
    80003348:	c911                	beqz	a0,8000335c <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000334a:	4585                	li	a1,1
    8000334c:	8526                	mv	a0,s1
    8000334e:	18f020ef          	jal	ra,80005cdc <virtio_disk_rw>
}
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret
    panic("bwrite");
    8000335c:	00004517          	auipc	a0,0x4
    80003360:	22450513          	addi	a0,a0,548 # 80007580 <syscalls+0xf8>
    80003364:	c26fd0ef          	jal	ra,8000078a <panic>

0000000080003368 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003368:	1101                	addi	sp,sp,-32
    8000336a:	ec06                	sd	ra,24(sp)
    8000336c:	e822                	sd	s0,16(sp)
    8000336e:	e426                	sd	s1,8(sp)
    80003370:	e04a                	sd	s2,0(sp)
    80003372:	1000                	addi	s0,sp,32
    80003374:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003376:	01050913          	addi	s2,a0,16
    8000337a:	854a                	mv	a0,s2
    8000337c:	270010ef          	jal	ra,800045ec <holdingsleep>
    80003380:	c13d                	beqz	a0,800033e6 <brelse+0x7e>
    panic("brelse");

  releasesleep(&b->lock);
    80003382:	854a                	mv	a0,s2
    80003384:	230010ef          	jal	ra,800045b4 <releasesleep>

  acquire(&bcache.lock);
    80003388:	0009d517          	auipc	a0,0x9d
    8000338c:	ea850513          	addi	a0,a0,-344 # 800a0230 <bcache>
    80003390:	943fd0ef          	jal	ra,80000cd2 <acquire>
  b->refcnt--;
    80003394:	40bc                	lw	a5,64(s1)
    80003396:	37fd                	addiw	a5,a5,-1
    80003398:	0007871b          	sext.w	a4,a5
    8000339c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000339e:	eb05                	bnez	a4,800033ce <brelse+0x66>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033a0:	68bc                	ld	a5,80(s1)
    800033a2:	64b8                	ld	a4,72(s1)
    800033a4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033a6:	64bc                	ld	a5,72(s1)
    800033a8:	68b8                	ld	a4,80(s1)
    800033aa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033ac:	000a5797          	auipc	a5,0xa5
    800033b0:	e8478793          	addi	a5,a5,-380 # 800a8230 <bcache+0x8000>
    800033b4:	2b87b703          	ld	a4,696(a5)
    800033b8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ba:	000a5717          	auipc	a4,0xa5
    800033be:	0de70713          	addi	a4,a4,222 # 800a8498 <bcache+0x8268>
    800033c2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033c4:	2b87b703          	ld	a4,696(a5)
    800033c8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033ca:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033ce:	0009d517          	auipc	a0,0x9d
    800033d2:	e6250513          	addi	a0,a0,-414 # 800a0230 <bcache>
    800033d6:	995fd0ef          	jal	ra,80000d6a <release>
}
    800033da:	60e2                	ld	ra,24(sp)
    800033dc:	6442                	ld	s0,16(sp)
    800033de:	64a2                	ld	s1,8(sp)
    800033e0:	6902                	ld	s2,0(sp)
    800033e2:	6105                	addi	sp,sp,32
    800033e4:	8082                	ret
    panic("brelse");
    800033e6:	00004517          	auipc	a0,0x4
    800033ea:	1a250513          	addi	a0,a0,418 # 80007588 <syscalls+0x100>
    800033ee:	b9cfd0ef          	jal	ra,8000078a <panic>

00000000800033f2 <bpin>:

void
bpin(struct buf *b) {
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	1000                	addi	s0,sp,32
    800033fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033fe:	0009d517          	auipc	a0,0x9d
    80003402:	e3250513          	addi	a0,a0,-462 # 800a0230 <bcache>
    80003406:	8cdfd0ef          	jal	ra,80000cd2 <acquire>
  b->refcnt++;
    8000340a:	40bc                	lw	a5,64(s1)
    8000340c:	2785                	addiw	a5,a5,1
    8000340e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003410:	0009d517          	auipc	a0,0x9d
    80003414:	e2050513          	addi	a0,a0,-480 # 800a0230 <bcache>
    80003418:	953fd0ef          	jal	ra,80000d6a <release>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <bunpin>:

void
bunpin(struct buf *b) {
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	e426                	sd	s1,8(sp)
    8000342e:	1000                	addi	s0,sp,32
    80003430:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003432:	0009d517          	auipc	a0,0x9d
    80003436:	dfe50513          	addi	a0,a0,-514 # 800a0230 <bcache>
    8000343a:	899fd0ef          	jal	ra,80000cd2 <acquire>
  b->refcnt--;
    8000343e:	40bc                	lw	a5,64(s1)
    80003440:	37fd                	addiw	a5,a5,-1
    80003442:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003444:	0009d517          	auipc	a0,0x9d
    80003448:	dec50513          	addi	a0,a0,-532 # 800a0230 <bcache>
    8000344c:	91ffd0ef          	jal	ra,80000d6a <release>
}
    80003450:	60e2                	ld	ra,24(sp)
    80003452:	6442                	ld	s0,16(sp)
    80003454:	64a2                	ld	s1,8(sp)
    80003456:	6105                	addi	sp,sp,32
    80003458:	8082                	ret

000000008000345a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	e426                	sd	s1,8(sp)
    80003462:	e04a                	sd	s2,0(sp)
    80003464:	1000                	addi	s0,sp,32
    80003466:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003468:	00d5d59b          	srliw	a1,a1,0xd
    8000346c:	000a5797          	auipc	a5,0xa5
    80003470:	4a07a783          	lw	a5,1184(a5) # 800a890c <sb+0x1c>
    80003474:	9dbd                	addw	a1,a1,a5
    80003476:	debff0ef          	jal	ra,80003260 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000347a:	0074f713          	andi	a4,s1,7
    8000347e:	4785                	li	a5,1
    80003480:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003484:	14ce                	slli	s1,s1,0x33
    80003486:	90d9                	srli	s1,s1,0x36
    80003488:	00950733          	add	a4,a0,s1
    8000348c:	05874703          	lbu	a4,88(a4)
    80003490:	00e7f6b3          	and	a3,a5,a4
    80003494:	c29d                	beqz	a3,800034ba <bfree+0x60>
    80003496:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003498:	94aa                	add	s1,s1,a0
    8000349a:	fff7c793          	not	a5,a5
    8000349e:	8ff9                	and	a5,a5,a4
    800034a0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034a4:	7d1000ef          	jal	ra,80004474 <log_write>
  brelse(bp);
    800034a8:	854a                	mv	a0,s2
    800034aa:	ebfff0ef          	jal	ra,80003368 <brelse>
}
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	64a2                	ld	s1,8(sp)
    800034b4:	6902                	ld	s2,0(sp)
    800034b6:	6105                	addi	sp,sp,32
    800034b8:	8082                	ret
    panic("freeing free block");
    800034ba:	00004517          	auipc	a0,0x4
    800034be:	0d650513          	addi	a0,a0,214 # 80007590 <syscalls+0x108>
    800034c2:	ac8fd0ef          	jal	ra,8000078a <panic>

00000000800034c6 <balloc>:
{
    800034c6:	711d                	addi	sp,sp,-96
    800034c8:	ec86                	sd	ra,88(sp)
    800034ca:	e8a2                	sd	s0,80(sp)
    800034cc:	e4a6                	sd	s1,72(sp)
    800034ce:	e0ca                	sd	s2,64(sp)
    800034d0:	fc4e                	sd	s3,56(sp)
    800034d2:	f852                	sd	s4,48(sp)
    800034d4:	f456                	sd	s5,40(sp)
    800034d6:	f05a                	sd	s6,32(sp)
    800034d8:	ec5e                	sd	s7,24(sp)
    800034da:	e862                	sd	s8,16(sp)
    800034dc:	e466                	sd	s9,8(sp)
    800034de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034e0:	000a5797          	auipc	a5,0xa5
    800034e4:	4147a783          	lw	a5,1044(a5) # 800a88f4 <sb+0x4>
    800034e8:	0e078163          	beqz	a5,800035ca <balloc+0x104>
    800034ec:	8baa                	mv	s7,a0
    800034ee:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034f0:	000a5b17          	auipc	s6,0xa5
    800034f4:	400b0b13          	addi	s6,s6,1024 # 800a88f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034fa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034fe:	6c89                	lui	s9,0x2
    80003500:	a0b5                	j	8000356c <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003502:	974a                	add	a4,a4,s2
    80003504:	8fd5                	or	a5,a5,a3
    80003506:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000350a:	854a                	mv	a0,s2
    8000350c:	769000ef          	jal	ra,80004474 <log_write>
        brelse(bp);
    80003510:	854a                	mv	a0,s2
    80003512:	e57ff0ef          	jal	ra,80003368 <brelse>
  bp = bread(dev, bno);
    80003516:	85a6                	mv	a1,s1
    80003518:	855e                	mv	a0,s7
    8000351a:	d47ff0ef          	jal	ra,80003260 <bread>
    8000351e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003520:	40000613          	li	a2,1024
    80003524:	4581                	li	a1,0
    80003526:	05850513          	addi	a0,a0,88
    8000352a:	87dfd0ef          	jal	ra,80000da6 <memset>
  log_write(bp);
    8000352e:	854a                	mv	a0,s2
    80003530:	745000ef          	jal	ra,80004474 <log_write>
  brelse(bp);
    80003534:	854a                	mv	a0,s2
    80003536:	e33ff0ef          	jal	ra,80003368 <brelse>
}
    8000353a:	8526                	mv	a0,s1
    8000353c:	60e6                	ld	ra,88(sp)
    8000353e:	6446                	ld	s0,80(sp)
    80003540:	64a6                	ld	s1,72(sp)
    80003542:	6906                	ld	s2,64(sp)
    80003544:	79e2                	ld	s3,56(sp)
    80003546:	7a42                	ld	s4,48(sp)
    80003548:	7aa2                	ld	s5,40(sp)
    8000354a:	7b02                	ld	s6,32(sp)
    8000354c:	6be2                	ld	s7,24(sp)
    8000354e:	6c42                	ld	s8,16(sp)
    80003550:	6ca2                	ld	s9,8(sp)
    80003552:	6125                	addi	sp,sp,96
    80003554:	8082                	ret
    brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	e11ff0ef          	jal	ra,80003368 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000355c:	015c87bb          	addw	a5,s9,s5
    80003560:	00078a9b          	sext.w	s5,a5
    80003564:	004b2703          	lw	a4,4(s6)
    80003568:	06eaf163          	bgeu	s5,a4,800035ca <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    8000356c:	41fad79b          	sraiw	a5,s5,0x1f
    80003570:	0137d79b          	srliw	a5,a5,0x13
    80003574:	015787bb          	addw	a5,a5,s5
    80003578:	40d7d79b          	sraiw	a5,a5,0xd
    8000357c:	01cb2583          	lw	a1,28(s6)
    80003580:	9dbd                	addw	a1,a1,a5
    80003582:	855e                	mv	a0,s7
    80003584:	cddff0ef          	jal	ra,80003260 <bread>
    80003588:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000358a:	004b2503          	lw	a0,4(s6)
    8000358e:	000a849b          	sext.w	s1,s5
    80003592:	8662                	mv	a2,s8
    80003594:	fca4f1e3          	bgeu	s1,a0,80003556 <balloc+0x90>
      m = 1 << (bi % 8);
    80003598:	41f6579b          	sraiw	a5,a2,0x1f
    8000359c:	01d7d69b          	srliw	a3,a5,0x1d
    800035a0:	00c6873b          	addw	a4,a3,a2
    800035a4:	00777793          	andi	a5,a4,7
    800035a8:	9f95                	subw	a5,a5,a3
    800035aa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035ae:	4037571b          	sraiw	a4,a4,0x3
    800035b2:	00e906b3          	add	a3,s2,a4
    800035b6:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    800035ba:	00d7f5b3          	and	a1,a5,a3
    800035be:	d1b1                	beqz	a1,80003502 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035c0:	2605                	addiw	a2,a2,1
    800035c2:	2485                	addiw	s1,s1,1
    800035c4:	fd4618e3          	bne	a2,s4,80003594 <balloc+0xce>
    800035c8:	b779                	j	80003556 <balloc+0x90>
  printf("balloc: out of blocks\n");
    800035ca:	00004517          	auipc	a0,0x4
    800035ce:	fde50513          	addi	a0,a0,-34 # 800075a8 <syscalls+0x120>
    800035d2:	ef3fc0ef          	jal	ra,800004c4 <printf>
  return 0;
    800035d6:	4481                	li	s1,0
    800035d8:	b78d                	j	8000353a <balloc+0x74>

00000000800035da <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	e052                	sd	s4,0(sp)
    800035e8:	1800                	addi	s0,sp,48
    800035ea:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035ec:	47ad                	li	a5,11
    800035ee:	02b7e563          	bltu	a5,a1,80003618 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    800035f2:	02059493          	slli	s1,a1,0x20
    800035f6:	9081                	srli	s1,s1,0x20
    800035f8:	048a                	slli	s1,s1,0x2
    800035fa:	94aa                	add	s1,s1,a0
    800035fc:	0504a903          	lw	s2,80(s1)
    80003600:	06091663          	bnez	s2,8000366c <bmap+0x92>
      addr = balloc(ip->dev);
    80003604:	4108                	lw	a0,0(a0)
    80003606:	ec1ff0ef          	jal	ra,800034c6 <balloc>
    8000360a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000360e:	04090f63          	beqz	s2,8000366c <bmap+0x92>
        return 0;
      ip->addrs[bn] = addr;
    80003612:	0524a823          	sw	s2,80(s1)
    80003616:	a899                	j	8000366c <bmap+0x92>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003618:	ff45849b          	addiw	s1,a1,-12
    8000361c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003620:	0ff00793          	li	a5,255
    80003624:	06e7eb63          	bltu	a5,a4,8000369a <bmap+0xc0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003628:	08052903          	lw	s2,128(a0)
    8000362c:	00091b63          	bnez	s2,80003642 <bmap+0x68>
      addr = balloc(ip->dev);
    80003630:	4108                	lw	a0,0(a0)
    80003632:	e95ff0ef          	jal	ra,800034c6 <balloc>
    80003636:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000363a:	02090963          	beqz	s2,8000366c <bmap+0x92>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000363e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003642:	85ca                	mv	a1,s2
    80003644:	0009a503          	lw	a0,0(s3)
    80003648:	c19ff0ef          	jal	ra,80003260 <bread>
    8000364c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000364e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003652:	02049593          	slli	a1,s1,0x20
    80003656:	9181                	srli	a1,a1,0x20
    80003658:	058a                	slli	a1,a1,0x2
    8000365a:	00b784b3          	add	s1,a5,a1
    8000365e:	0004a903          	lw	s2,0(s1)
    80003662:	00090e63          	beqz	s2,8000367e <bmap+0xa4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003666:	8552                	mv	a0,s4
    80003668:	d01ff0ef          	jal	ra,80003368 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000366c:	854a                	mv	a0,s2
    8000366e:	70a2                	ld	ra,40(sp)
    80003670:	7402                	ld	s0,32(sp)
    80003672:	64e2                	ld	s1,24(sp)
    80003674:	6942                	ld	s2,16(sp)
    80003676:	69a2                	ld	s3,8(sp)
    80003678:	6a02                	ld	s4,0(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret
      addr = balloc(ip->dev);
    8000367e:	0009a503          	lw	a0,0(s3)
    80003682:	e45ff0ef          	jal	ra,800034c6 <balloc>
    80003686:	0005091b          	sext.w	s2,a0
      if(addr){
    8000368a:	fc090ee3          	beqz	s2,80003666 <bmap+0x8c>
        a[bn] = addr;
    8000368e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003692:	8552                	mv	a0,s4
    80003694:	5e1000ef          	jal	ra,80004474 <log_write>
    80003698:	b7f9                	j	80003666 <bmap+0x8c>
  panic("bmap: out of range");
    8000369a:	00004517          	auipc	a0,0x4
    8000369e:	f2650513          	addi	a0,a0,-218 # 800075c0 <syscalls+0x138>
    800036a2:	8e8fd0ef          	jal	ra,8000078a <panic>

00000000800036a6 <iget>:
{
    800036a6:	7179                	addi	sp,sp,-48
    800036a8:	f406                	sd	ra,40(sp)
    800036aa:	f022                	sd	s0,32(sp)
    800036ac:	ec26                	sd	s1,24(sp)
    800036ae:	e84a                	sd	s2,16(sp)
    800036b0:	e44e                	sd	s3,8(sp)
    800036b2:	e052                	sd	s4,0(sp)
    800036b4:	1800                	addi	s0,sp,48
    800036b6:	89aa                	mv	s3,a0
    800036b8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036ba:	000a5517          	auipc	a0,0xa5
    800036be:	25650513          	addi	a0,a0,598 # 800a8910 <itable>
    800036c2:	e10fd0ef          	jal	ra,80000cd2 <acquire>
  empty = 0;
    800036c6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c8:	000a5497          	auipc	s1,0xa5
    800036cc:	26048493          	addi	s1,s1,608 # 800a8928 <itable+0x18>
    800036d0:	000a7697          	auipc	a3,0xa7
    800036d4:	ce868693          	addi	a3,a3,-792 # 800aa3b8 <log>
    800036d8:	a039                	j	800036e6 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036da:	02090963          	beqz	s2,8000370c <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036de:	08848493          	addi	s1,s1,136
    800036e2:	02d48863          	beq	s1,a3,80003712 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036e6:	449c                	lw	a5,8(s1)
    800036e8:	fef059e3          	blez	a5,800036da <iget+0x34>
    800036ec:	4098                	lw	a4,0(s1)
    800036ee:	ff3716e3          	bne	a4,s3,800036da <iget+0x34>
    800036f2:	40d8                	lw	a4,4(s1)
    800036f4:	ff4713e3          	bne	a4,s4,800036da <iget+0x34>
      ip->ref++;
    800036f8:	2785                	addiw	a5,a5,1
    800036fa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036fc:	000a5517          	auipc	a0,0xa5
    80003700:	21450513          	addi	a0,a0,532 # 800a8910 <itable>
    80003704:	e66fd0ef          	jal	ra,80000d6a <release>
      return ip;
    80003708:	8926                	mv	s2,s1
    8000370a:	a02d                	j	80003734 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000370c:	fbe9                	bnez	a5,800036de <iget+0x38>
    8000370e:	8926                	mv	s2,s1
    80003710:	b7f9                	j	800036de <iget+0x38>
  if(empty == 0)
    80003712:	02090a63          	beqz	s2,80003746 <iget+0xa0>
  ip->dev = dev;
    80003716:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000371a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000371e:	4785                	li	a5,1
    80003720:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003724:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003728:	000a5517          	auipc	a0,0xa5
    8000372c:	1e850513          	addi	a0,a0,488 # 800a8910 <itable>
    80003730:	e3afd0ef          	jal	ra,80000d6a <release>
}
    80003734:	854a                	mv	a0,s2
    80003736:	70a2                	ld	ra,40(sp)
    80003738:	7402                	ld	s0,32(sp)
    8000373a:	64e2                	ld	s1,24(sp)
    8000373c:	6942                	ld	s2,16(sp)
    8000373e:	69a2                	ld	s3,8(sp)
    80003740:	6a02                	ld	s4,0(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret
    panic("iget: no inodes");
    80003746:	00004517          	auipc	a0,0x4
    8000374a:	e9250513          	addi	a0,a0,-366 # 800075d8 <syscalls+0x150>
    8000374e:	83cfd0ef          	jal	ra,8000078a <panic>

0000000080003752 <iinit>:
{
    80003752:	7179                	addi	sp,sp,-48
    80003754:	f406                	sd	ra,40(sp)
    80003756:	f022                	sd	s0,32(sp)
    80003758:	ec26                	sd	s1,24(sp)
    8000375a:	e84a                	sd	s2,16(sp)
    8000375c:	e44e                	sd	s3,8(sp)
    8000375e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003760:	00004597          	auipc	a1,0x4
    80003764:	e8858593          	addi	a1,a1,-376 # 800075e8 <syscalls+0x160>
    80003768:	000a5517          	auipc	a0,0xa5
    8000376c:	1a850513          	addi	a0,a0,424 # 800a8910 <itable>
    80003770:	ce2fd0ef          	jal	ra,80000c52 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003774:	000a5497          	auipc	s1,0xa5
    80003778:	1c448493          	addi	s1,s1,452 # 800a8938 <itable+0x28>
    8000377c:	000a7997          	auipc	s3,0xa7
    80003780:	c4c98993          	addi	s3,s3,-948 # 800aa3c8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003784:	00004917          	auipc	s2,0x4
    80003788:	e6c90913          	addi	s2,s2,-404 # 800075f0 <syscalls+0x168>
    8000378c:	85ca                	mv	a1,s2
    8000378e:	8526                	mv	a0,s1
    80003790:	5a9000ef          	jal	ra,80004538 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003794:	08848493          	addi	s1,s1,136
    80003798:	ff349ae3          	bne	s1,s3,8000378c <iinit+0x3a>
}
    8000379c:	70a2                	ld	ra,40(sp)
    8000379e:	7402                	ld	s0,32(sp)
    800037a0:	64e2                	ld	s1,24(sp)
    800037a2:	6942                	ld	s2,16(sp)
    800037a4:	69a2                	ld	s3,8(sp)
    800037a6:	6145                	addi	sp,sp,48
    800037a8:	8082                	ret

00000000800037aa <ialloc>:
{
    800037aa:	715d                	addi	sp,sp,-80
    800037ac:	e486                	sd	ra,72(sp)
    800037ae:	e0a2                	sd	s0,64(sp)
    800037b0:	fc26                	sd	s1,56(sp)
    800037b2:	f84a                	sd	s2,48(sp)
    800037b4:	f44e                	sd	s3,40(sp)
    800037b6:	f052                	sd	s4,32(sp)
    800037b8:	ec56                	sd	s5,24(sp)
    800037ba:	e85a                	sd	s6,16(sp)
    800037bc:	e45e                	sd	s7,8(sp)
    800037be:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037c0:	000a5717          	auipc	a4,0xa5
    800037c4:	13c72703          	lw	a4,316(a4) # 800a88fc <sb+0xc>
    800037c8:	4785                	li	a5,1
    800037ca:	04e7f663          	bgeu	a5,a4,80003816 <ialloc+0x6c>
    800037ce:	8aaa                	mv	s5,a0
    800037d0:	8bae                	mv	s7,a1
    800037d2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037d4:	000a5a17          	auipc	s4,0xa5
    800037d8:	11ca0a13          	addi	s4,s4,284 # 800a88f0 <sb>
    800037dc:	00048b1b          	sext.w	s6,s1
    800037e0:	0044d793          	srli	a5,s1,0x4
    800037e4:	018a2583          	lw	a1,24(s4)
    800037e8:	9dbd                	addw	a1,a1,a5
    800037ea:	8556                	mv	a0,s5
    800037ec:	a75ff0ef          	jal	ra,80003260 <bread>
    800037f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037f2:	05850993          	addi	s3,a0,88
    800037f6:	00f4f793          	andi	a5,s1,15
    800037fa:	079a                	slli	a5,a5,0x6
    800037fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037fe:	00099783          	lh	a5,0(s3)
    80003802:	cf85                	beqz	a5,8000383a <ialloc+0x90>
    brelse(bp);
    80003804:	b65ff0ef          	jal	ra,80003368 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003808:	0485                	addi	s1,s1,1
    8000380a:	00ca2703          	lw	a4,12(s4)
    8000380e:	0004879b          	sext.w	a5,s1
    80003812:	fce7e5e3          	bltu	a5,a4,800037dc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003816:	00004517          	auipc	a0,0x4
    8000381a:	de250513          	addi	a0,a0,-542 # 800075f8 <syscalls+0x170>
    8000381e:	ca7fc0ef          	jal	ra,800004c4 <printf>
  return 0;
    80003822:	4501                	li	a0,0
}
    80003824:	60a6                	ld	ra,72(sp)
    80003826:	6406                	ld	s0,64(sp)
    80003828:	74e2                	ld	s1,56(sp)
    8000382a:	7942                	ld	s2,48(sp)
    8000382c:	79a2                	ld	s3,40(sp)
    8000382e:	7a02                	ld	s4,32(sp)
    80003830:	6ae2                	ld	s5,24(sp)
    80003832:	6b42                	ld	s6,16(sp)
    80003834:	6ba2                	ld	s7,8(sp)
    80003836:	6161                	addi	sp,sp,80
    80003838:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000383a:	04000613          	li	a2,64
    8000383e:	4581                	li	a1,0
    80003840:	854e                	mv	a0,s3
    80003842:	d64fd0ef          	jal	ra,80000da6 <memset>
      dip->type = type;
    80003846:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000384a:	854a                	mv	a0,s2
    8000384c:	429000ef          	jal	ra,80004474 <log_write>
      brelse(bp);
    80003850:	854a                	mv	a0,s2
    80003852:	b17ff0ef          	jal	ra,80003368 <brelse>
      return iget(dev, inum);
    80003856:	85da                	mv	a1,s6
    80003858:	8556                	mv	a0,s5
    8000385a:	e4dff0ef          	jal	ra,800036a6 <iget>
    8000385e:	b7d9                	j	80003824 <ialloc+0x7a>

0000000080003860 <iupdate>:
{
    80003860:	1101                	addi	sp,sp,-32
    80003862:	ec06                	sd	ra,24(sp)
    80003864:	e822                	sd	s0,16(sp)
    80003866:	e426                	sd	s1,8(sp)
    80003868:	e04a                	sd	s2,0(sp)
    8000386a:	1000                	addi	s0,sp,32
    8000386c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000386e:	415c                	lw	a5,4(a0)
    80003870:	0047d79b          	srliw	a5,a5,0x4
    80003874:	000a5597          	auipc	a1,0xa5
    80003878:	0945a583          	lw	a1,148(a1) # 800a8908 <sb+0x18>
    8000387c:	9dbd                	addw	a1,a1,a5
    8000387e:	4108                	lw	a0,0(a0)
    80003880:	9e1ff0ef          	jal	ra,80003260 <bread>
    80003884:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003886:	05850793          	addi	a5,a0,88
    8000388a:	40c8                	lw	a0,4(s1)
    8000388c:	893d                	andi	a0,a0,15
    8000388e:	051a                	slli	a0,a0,0x6
    80003890:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003892:	04449703          	lh	a4,68(s1)
    80003896:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000389a:	04649703          	lh	a4,70(s1)
    8000389e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038a2:	04849703          	lh	a4,72(s1)
    800038a6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038aa:	04a49703          	lh	a4,74(s1)
    800038ae:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038b2:	44f8                	lw	a4,76(s1)
    800038b4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038b6:	03400613          	li	a2,52
    800038ba:	05048593          	addi	a1,s1,80
    800038be:	0531                	addi	a0,a0,12
    800038c0:	d42fd0ef          	jal	ra,80000e02 <memmove>
  log_write(bp);
    800038c4:	854a                	mv	a0,s2
    800038c6:	3af000ef          	jal	ra,80004474 <log_write>
  brelse(bp);
    800038ca:	854a                	mv	a0,s2
    800038cc:	a9dff0ef          	jal	ra,80003368 <brelse>
}
    800038d0:	60e2                	ld	ra,24(sp)
    800038d2:	6442                	ld	s0,16(sp)
    800038d4:	64a2                	ld	s1,8(sp)
    800038d6:	6902                	ld	s2,0(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret

00000000800038dc <idup>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	1000                	addi	s0,sp,32
    800038e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038e8:	000a5517          	auipc	a0,0xa5
    800038ec:	02850513          	addi	a0,a0,40 # 800a8910 <itable>
    800038f0:	be2fd0ef          	jal	ra,80000cd2 <acquire>
  ip->ref++;
    800038f4:	449c                	lw	a5,8(s1)
    800038f6:	2785                	addiw	a5,a5,1
    800038f8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038fa:	000a5517          	auipc	a0,0xa5
    800038fe:	01650513          	addi	a0,a0,22 # 800a8910 <itable>
    80003902:	c68fd0ef          	jal	ra,80000d6a <release>
}
    80003906:	8526                	mv	a0,s1
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret

0000000080003912 <ilock>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000391e:	c105                	beqz	a0,8000393e <ilock+0x2c>
    80003920:	84aa                	mv	s1,a0
    80003922:	451c                	lw	a5,8(a0)
    80003924:	00f05d63          	blez	a5,8000393e <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003928:	0541                	addi	a0,a0,16
    8000392a:	445000ef          	jal	ra,8000456e <acquiresleep>
  if(ip->valid == 0){
    8000392e:	40bc                	lw	a5,64(s1)
    80003930:	cf89                	beqz	a5,8000394a <ilock+0x38>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
    panic("ilock");
    8000393e:	00004517          	auipc	a0,0x4
    80003942:	cd250513          	addi	a0,a0,-814 # 80007610 <syscalls+0x188>
    80003946:	e45fc0ef          	jal	ra,8000078a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000394a:	40dc                	lw	a5,4(s1)
    8000394c:	0047d79b          	srliw	a5,a5,0x4
    80003950:	000a5597          	auipc	a1,0xa5
    80003954:	fb85a583          	lw	a1,-72(a1) # 800a8908 <sb+0x18>
    80003958:	9dbd                	addw	a1,a1,a5
    8000395a:	4088                	lw	a0,0(s1)
    8000395c:	905ff0ef          	jal	ra,80003260 <bread>
    80003960:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003962:	05850593          	addi	a1,a0,88
    80003966:	40dc                	lw	a5,4(s1)
    80003968:	8bbd                	andi	a5,a5,15
    8000396a:	079a                	slli	a5,a5,0x6
    8000396c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000396e:	00059783          	lh	a5,0(a1)
    80003972:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003976:	00259783          	lh	a5,2(a1)
    8000397a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000397e:	00459783          	lh	a5,4(a1)
    80003982:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003986:	00659783          	lh	a5,6(a1)
    8000398a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000398e:	459c                	lw	a5,8(a1)
    80003990:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003992:	03400613          	li	a2,52
    80003996:	05b1                	addi	a1,a1,12
    80003998:	05048513          	addi	a0,s1,80
    8000399c:	c66fd0ef          	jal	ra,80000e02 <memmove>
    brelse(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	9c7ff0ef          	jal	ra,80003368 <brelse>
    ip->valid = 1;
    800039a6:	4785                	li	a5,1
    800039a8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039aa:	04449783          	lh	a5,68(s1)
    800039ae:	f3d1                	bnez	a5,80003932 <ilock+0x20>
      panic("ilock: no type");
    800039b0:	00004517          	auipc	a0,0x4
    800039b4:	c6850513          	addi	a0,a0,-920 # 80007618 <syscalls+0x190>
    800039b8:	dd3fc0ef          	jal	ra,8000078a <panic>

00000000800039bc <iunlock>:
{
    800039bc:	1101                	addi	sp,sp,-32
    800039be:	ec06                	sd	ra,24(sp)
    800039c0:	e822                	sd	s0,16(sp)
    800039c2:	e426                	sd	s1,8(sp)
    800039c4:	e04a                	sd	s2,0(sp)
    800039c6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039c8:	c505                	beqz	a0,800039f0 <iunlock+0x34>
    800039ca:	84aa                	mv	s1,a0
    800039cc:	01050913          	addi	s2,a0,16
    800039d0:	854a                	mv	a0,s2
    800039d2:	41b000ef          	jal	ra,800045ec <holdingsleep>
    800039d6:	cd09                	beqz	a0,800039f0 <iunlock+0x34>
    800039d8:	449c                	lw	a5,8(s1)
    800039da:	00f05b63          	blez	a5,800039f0 <iunlock+0x34>
  releasesleep(&ip->lock);
    800039de:	854a                	mv	a0,s2
    800039e0:	3d5000ef          	jal	ra,800045b4 <releasesleep>
}
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	64a2                	ld	s1,8(sp)
    800039ea:	6902                	ld	s2,0(sp)
    800039ec:	6105                	addi	sp,sp,32
    800039ee:	8082                	ret
    panic("iunlock");
    800039f0:	00004517          	auipc	a0,0x4
    800039f4:	c3850513          	addi	a0,a0,-968 # 80007628 <syscalls+0x1a0>
    800039f8:	d93fc0ef          	jal	ra,8000078a <panic>

00000000800039fc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039fc:	7179                	addi	sp,sp,-48
    800039fe:	f406                	sd	ra,40(sp)
    80003a00:	f022                	sd	s0,32(sp)
    80003a02:	ec26                	sd	s1,24(sp)
    80003a04:	e84a                	sd	s2,16(sp)
    80003a06:	e44e                	sd	s3,8(sp)
    80003a08:	e052                	sd	s4,0(sp)
    80003a0a:	1800                	addi	s0,sp,48
    80003a0c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a0e:	05050493          	addi	s1,a0,80
    80003a12:	08050913          	addi	s2,a0,128
    80003a16:	a021                	j	80003a1e <itrunc+0x22>
    80003a18:	0491                	addi	s1,s1,4
    80003a1a:	01248b63          	beq	s1,s2,80003a30 <itrunc+0x34>
    if(ip->addrs[i]){
    80003a1e:	408c                	lw	a1,0(s1)
    80003a20:	dde5                	beqz	a1,80003a18 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	a35ff0ef          	jal	ra,8000345a <bfree>
      ip->addrs[i] = 0;
    80003a2a:	0004a023          	sw	zero,0(s1)
    80003a2e:	b7ed                	j	80003a18 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a30:	0809a583          	lw	a1,128(s3)
    80003a34:	ed91                	bnez	a1,80003a50 <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a3a:	854e                	mv	a0,s3
    80003a3c:	e25ff0ef          	jal	ra,80003860 <iupdate>
}
    80003a40:	70a2                	ld	ra,40(sp)
    80003a42:	7402                	ld	s0,32(sp)
    80003a44:	64e2                	ld	s1,24(sp)
    80003a46:	6942                	ld	s2,16(sp)
    80003a48:	69a2                	ld	s3,8(sp)
    80003a4a:	6a02                	ld	s4,0(sp)
    80003a4c:	6145                	addi	sp,sp,48
    80003a4e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a50:	0009a503          	lw	a0,0(s3)
    80003a54:	80dff0ef          	jal	ra,80003260 <bread>
    80003a58:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a5a:	05850493          	addi	s1,a0,88
    80003a5e:	45850913          	addi	s2,a0,1112
    80003a62:	a021                	j	80003a6a <itrunc+0x6e>
    80003a64:	0491                	addi	s1,s1,4
    80003a66:	01248963          	beq	s1,s2,80003a78 <itrunc+0x7c>
      if(a[j])
    80003a6a:	408c                	lw	a1,0(s1)
    80003a6c:	dde5                	beqz	a1,80003a64 <itrunc+0x68>
        bfree(ip->dev, a[j]);
    80003a6e:	0009a503          	lw	a0,0(s3)
    80003a72:	9e9ff0ef          	jal	ra,8000345a <bfree>
    80003a76:	b7fd                	j	80003a64 <itrunc+0x68>
    brelse(bp);
    80003a78:	8552                	mv	a0,s4
    80003a7a:	8efff0ef          	jal	ra,80003368 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a7e:	0809a583          	lw	a1,128(s3)
    80003a82:	0009a503          	lw	a0,0(s3)
    80003a86:	9d5ff0ef          	jal	ra,8000345a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a8a:	0809a023          	sw	zero,128(s3)
    80003a8e:	b765                	j	80003a36 <itrunc+0x3a>

0000000080003a90 <iput>:
{
    80003a90:	1101                	addi	sp,sp,-32
    80003a92:	ec06                	sd	ra,24(sp)
    80003a94:	e822                	sd	s0,16(sp)
    80003a96:	e426                	sd	s1,8(sp)
    80003a98:	e04a                	sd	s2,0(sp)
    80003a9a:	1000                	addi	s0,sp,32
    80003a9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a9e:	000a5517          	auipc	a0,0xa5
    80003aa2:	e7250513          	addi	a0,a0,-398 # 800a8910 <itable>
    80003aa6:	a2cfd0ef          	jal	ra,80000cd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aaa:	4498                	lw	a4,8(s1)
    80003aac:	4785                	li	a5,1
    80003aae:	02f70163          	beq	a4,a5,80003ad0 <iput+0x40>
  ip->ref--;
    80003ab2:	449c                	lw	a5,8(s1)
    80003ab4:	37fd                	addiw	a5,a5,-1
    80003ab6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ab8:	000a5517          	auipc	a0,0xa5
    80003abc:	e5850513          	addi	a0,a0,-424 # 800a8910 <itable>
    80003ac0:	aaafd0ef          	jal	ra,80000d6a <release>
}
    80003ac4:	60e2                	ld	ra,24(sp)
    80003ac6:	6442                	ld	s0,16(sp)
    80003ac8:	64a2                	ld	s1,8(sp)
    80003aca:	6902                	ld	s2,0(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad0:	40bc                	lw	a5,64(s1)
    80003ad2:	d3e5                	beqz	a5,80003ab2 <iput+0x22>
    80003ad4:	04a49783          	lh	a5,74(s1)
    80003ad8:	ffe9                	bnez	a5,80003ab2 <iput+0x22>
    acquiresleep(&ip->lock);
    80003ada:	01048913          	addi	s2,s1,16
    80003ade:	854a                	mv	a0,s2
    80003ae0:	28f000ef          	jal	ra,8000456e <acquiresleep>
    release(&itable.lock);
    80003ae4:	000a5517          	auipc	a0,0xa5
    80003ae8:	e2c50513          	addi	a0,a0,-468 # 800a8910 <itable>
    80003aec:	a7efd0ef          	jal	ra,80000d6a <release>
    itrunc(ip);
    80003af0:	8526                	mv	a0,s1
    80003af2:	f0bff0ef          	jal	ra,800039fc <itrunc>
    ip->type = 0;
    80003af6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	d65ff0ef          	jal	ra,80003860 <iupdate>
    ip->valid = 0;
    80003b00:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b04:	854a                	mv	a0,s2
    80003b06:	2af000ef          	jal	ra,800045b4 <releasesleep>
    acquire(&itable.lock);
    80003b0a:	000a5517          	auipc	a0,0xa5
    80003b0e:	e0650513          	addi	a0,a0,-506 # 800a8910 <itable>
    80003b12:	9c0fd0ef          	jal	ra,80000cd2 <acquire>
    80003b16:	bf71                	j	80003ab2 <iput+0x22>

0000000080003b18 <iunlockput>:
{
    80003b18:	1101                	addi	sp,sp,-32
    80003b1a:	ec06                	sd	ra,24(sp)
    80003b1c:	e822                	sd	s0,16(sp)
    80003b1e:	e426                	sd	s1,8(sp)
    80003b20:	1000                	addi	s0,sp,32
    80003b22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b24:	e99ff0ef          	jal	ra,800039bc <iunlock>
  iput(ip);
    80003b28:	8526                	mv	a0,s1
    80003b2a:	f67ff0ef          	jal	ra,80003a90 <iput>
}
    80003b2e:	60e2                	ld	ra,24(sp)
    80003b30:	6442                	ld	s0,16(sp)
    80003b32:	64a2                	ld	s1,8(sp)
    80003b34:	6105                	addi	sp,sp,32
    80003b36:	8082                	ret

0000000080003b38 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003b38:	000a5717          	auipc	a4,0xa5
    80003b3c:	dc472703          	lw	a4,-572(a4) # 800a88fc <sb+0xc>
    80003b40:	4785                	li	a5,1
    80003b42:	0ae7ff63          	bgeu	a5,a4,80003c00 <ireclaim+0xc8>
{
    80003b46:	7139                	addi	sp,sp,-64
    80003b48:	fc06                	sd	ra,56(sp)
    80003b4a:	f822                	sd	s0,48(sp)
    80003b4c:	f426                	sd	s1,40(sp)
    80003b4e:	f04a                	sd	s2,32(sp)
    80003b50:	ec4e                	sd	s3,24(sp)
    80003b52:	e852                	sd	s4,16(sp)
    80003b54:	e456                	sd	s5,8(sp)
    80003b56:	e05a                	sd	s6,0(sp)
    80003b58:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003b5a:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003b5c:	00050a1b          	sext.w	s4,a0
    80003b60:	000a5a97          	auipc	s5,0xa5
    80003b64:	d90a8a93          	addi	s5,s5,-624 # 800a88f0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003b68:	00004b17          	auipc	s6,0x4
    80003b6c:	ac8b0b13          	addi	s6,s6,-1336 # 80007630 <syscalls+0x1a8>
    80003b70:	a099                	j	80003bb6 <ireclaim+0x7e>
    80003b72:	85ce                	mv	a1,s3
    80003b74:	855a                	mv	a0,s6
    80003b76:	94ffc0ef          	jal	ra,800004c4 <printf>
      ip = iget(dev, inum);
    80003b7a:	85ce                	mv	a1,s3
    80003b7c:	8552                	mv	a0,s4
    80003b7e:	b29ff0ef          	jal	ra,800036a6 <iget>
    80003b82:	89aa                	mv	s3,a0
    brelse(bp);
    80003b84:	854a                	mv	a0,s2
    80003b86:	fe2ff0ef          	jal	ra,80003368 <brelse>
    if (ip) {
    80003b8a:	00098f63          	beqz	s3,80003ba8 <ireclaim+0x70>
      begin_op();
    80003b8e:	762000ef          	jal	ra,800042f0 <begin_op>
      ilock(ip);
    80003b92:	854e                	mv	a0,s3
    80003b94:	d7fff0ef          	jal	ra,80003912 <ilock>
      iunlock(ip);
    80003b98:	854e                	mv	a0,s3
    80003b9a:	e23ff0ef          	jal	ra,800039bc <iunlock>
      iput(ip);
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	ef1ff0ef          	jal	ra,80003a90 <iput>
      end_op();
    80003ba4:	7bc000ef          	jal	ra,80004360 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003ba8:	0485                	addi	s1,s1,1
    80003baa:	00caa703          	lw	a4,12(s5)
    80003bae:	0004879b          	sext.w	a5,s1
    80003bb2:	02e7fd63          	bgeu	a5,a4,80003bec <ireclaim+0xb4>
    80003bb6:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003bba:	0044d793          	srli	a5,s1,0x4
    80003bbe:	018aa583          	lw	a1,24(s5)
    80003bc2:	9dbd                	addw	a1,a1,a5
    80003bc4:	8552                	mv	a0,s4
    80003bc6:	e9aff0ef          	jal	ra,80003260 <bread>
    80003bca:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003bcc:	05850793          	addi	a5,a0,88
    80003bd0:	00f9f713          	andi	a4,s3,15
    80003bd4:	071a                	slli	a4,a4,0x6
    80003bd6:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003bd8:	00079703          	lh	a4,0(a5)
    80003bdc:	c701                	beqz	a4,80003be4 <ireclaim+0xac>
    80003bde:	00679783          	lh	a5,6(a5)
    80003be2:	dbc1                	beqz	a5,80003b72 <ireclaim+0x3a>
    brelse(bp);
    80003be4:	854a                	mv	a0,s2
    80003be6:	f82ff0ef          	jal	ra,80003368 <brelse>
    if (ip) {
    80003bea:	bf7d                	j	80003ba8 <ireclaim+0x70>
}
    80003bec:	70e2                	ld	ra,56(sp)
    80003bee:	7442                	ld	s0,48(sp)
    80003bf0:	74a2                	ld	s1,40(sp)
    80003bf2:	7902                	ld	s2,32(sp)
    80003bf4:	69e2                	ld	s3,24(sp)
    80003bf6:	6a42                	ld	s4,16(sp)
    80003bf8:	6aa2                	ld	s5,8(sp)
    80003bfa:	6b02                	ld	s6,0(sp)
    80003bfc:	6121                	addi	sp,sp,64
    80003bfe:	8082                	ret
    80003c00:	8082                	ret

0000000080003c02 <fsinit>:
fsinit(int dev) {
    80003c02:	7179                	addi	sp,sp,-48
    80003c04:	f406                	sd	ra,40(sp)
    80003c06:	f022                	sd	s0,32(sp)
    80003c08:	ec26                	sd	s1,24(sp)
    80003c0a:	e84a                	sd	s2,16(sp)
    80003c0c:	e44e                	sd	s3,8(sp)
    80003c0e:	1800                	addi	s0,sp,48
    80003c10:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003c12:	4585                	li	a1,1
    80003c14:	e4cff0ef          	jal	ra,80003260 <bread>
    80003c18:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c1a:	000a5997          	auipc	s3,0xa5
    80003c1e:	cd698993          	addi	s3,s3,-810 # 800a88f0 <sb>
    80003c22:	02000613          	li	a2,32
    80003c26:	05850593          	addi	a1,a0,88
    80003c2a:	854e                	mv	a0,s3
    80003c2c:	9d6fd0ef          	jal	ra,80000e02 <memmove>
  brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	f36ff0ef          	jal	ra,80003368 <brelse>
  if(sb.magic != FSMAGIC)
    80003c36:	0009a703          	lw	a4,0(s3)
    80003c3a:	102037b7          	lui	a5,0x10203
    80003c3e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c42:	02f71363          	bne	a4,a5,80003c68 <fsinit+0x66>
  initlog(dev, &sb);
    80003c46:	000a5597          	auipc	a1,0xa5
    80003c4a:	caa58593          	addi	a1,a1,-854 # 800a88f0 <sb>
    80003c4e:	8526                	mv	a0,s1
    80003c50:	616000ef          	jal	ra,80004266 <initlog>
  ireclaim(dev);
    80003c54:	8526                	mv	a0,s1
    80003c56:	ee3ff0ef          	jal	ra,80003b38 <ireclaim>
}
    80003c5a:	70a2                	ld	ra,40(sp)
    80003c5c:	7402                	ld	s0,32(sp)
    80003c5e:	64e2                	ld	s1,24(sp)
    80003c60:	6942                	ld	s2,16(sp)
    80003c62:	69a2                	ld	s3,8(sp)
    80003c64:	6145                	addi	sp,sp,48
    80003c66:	8082                	ret
    panic("invalid file system");
    80003c68:	00004517          	auipc	a0,0x4
    80003c6c:	9e850513          	addi	a0,a0,-1560 # 80007650 <syscalls+0x1c8>
    80003c70:	b1bfc0ef          	jal	ra,8000078a <panic>

0000000080003c74 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c74:	1141                	addi	sp,sp,-16
    80003c76:	e422                	sd	s0,8(sp)
    80003c78:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c7a:	411c                	lw	a5,0(a0)
    80003c7c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c7e:	415c                	lw	a5,4(a0)
    80003c80:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c82:	04451783          	lh	a5,68(a0)
    80003c86:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c8a:	04a51783          	lh	a5,74(a0)
    80003c8e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c92:	04c56783          	lwu	a5,76(a0)
    80003c96:	e99c                	sd	a5,16(a1)
}
    80003c98:	6422                	ld	s0,8(sp)
    80003c9a:	0141                	addi	sp,sp,16
    80003c9c:	8082                	ret

0000000080003c9e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	0cd7ef63          	bltu	a5,a3,80003d7e <readi+0xe0>
{
    80003ca4:	7159                	addi	sp,sp,-112
    80003ca6:	f486                	sd	ra,104(sp)
    80003ca8:	f0a2                	sd	s0,96(sp)
    80003caa:	eca6                	sd	s1,88(sp)
    80003cac:	e8ca                	sd	s2,80(sp)
    80003cae:	e4ce                	sd	s3,72(sp)
    80003cb0:	e0d2                	sd	s4,64(sp)
    80003cb2:	fc56                	sd	s5,56(sp)
    80003cb4:	f85a                	sd	s6,48(sp)
    80003cb6:	f45e                	sd	s7,40(sp)
    80003cb8:	f062                	sd	s8,32(sp)
    80003cba:	ec66                	sd	s9,24(sp)
    80003cbc:	e86a                	sd	s10,16(sp)
    80003cbe:	e46e                	sd	s11,8(sp)
    80003cc0:	1880                	addi	s0,sp,112
    80003cc2:	8b2a                	mv	s6,a0
    80003cc4:	8bae                	mv	s7,a1
    80003cc6:	8a32                	mv	s4,a2
    80003cc8:	84b6                	mv	s1,a3
    80003cca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ccc:	9f35                	addw	a4,a4,a3
    return 0;
    80003cce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cd0:	08d76663          	bltu	a4,a3,80003d5c <readi+0xbe>
  if(off + n > ip->size)
    80003cd4:	00e7f463          	bgeu	a5,a4,80003cdc <readi+0x3e>
    n = ip->size - off;
    80003cd8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cdc:	080a8f63          	beqz	s5,80003d7a <readi+0xdc>
    80003ce0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ce6:	5c7d                	li	s8,-1
    80003ce8:	a80d                	j	80003d1a <readi+0x7c>
    80003cea:	020d1d93          	slli	s11,s10,0x20
    80003cee:	020ddd93          	srli	s11,s11,0x20
    80003cf2:	05890793          	addi	a5,s2,88
    80003cf6:	86ee                	mv	a3,s11
    80003cf8:	963e                	add	a2,a2,a5
    80003cfa:	85d2                	mv	a1,s4
    80003cfc:	855e                	mv	a0,s7
    80003cfe:	fe2fe0ef          	jal	ra,800024e0 <either_copyout>
    80003d02:	05850763          	beq	a0,s8,80003d50 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d06:	854a                	mv	a0,s2
    80003d08:	e60ff0ef          	jal	ra,80003368 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0c:	013d09bb          	addw	s3,s10,s3
    80003d10:	009d04bb          	addw	s1,s10,s1
    80003d14:	9a6e                	add	s4,s4,s11
    80003d16:	0559f163          	bgeu	s3,s5,80003d58 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    80003d1a:	00a4d59b          	srliw	a1,s1,0xa
    80003d1e:	855a                	mv	a0,s6
    80003d20:	8bbff0ef          	jal	ra,800035da <bmap>
    80003d24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d28:	c985                	beqz	a1,80003d58 <readi+0xba>
    bp = bread(ip->dev, addr);
    80003d2a:	000b2503          	lw	a0,0(s6)
    80003d2e:	d32ff0ef          	jal	ra,80003260 <bread>
    80003d32:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d34:	3ff4f613          	andi	a2,s1,1023
    80003d38:	40cc87bb          	subw	a5,s9,a2
    80003d3c:	413a873b          	subw	a4,s5,s3
    80003d40:	8d3e                	mv	s10,a5
    80003d42:	2781                	sext.w	a5,a5
    80003d44:	0007069b          	sext.w	a3,a4
    80003d48:	faf6f1e3          	bgeu	a3,a5,80003cea <readi+0x4c>
    80003d4c:	8d3a                	mv	s10,a4
    80003d4e:	bf71                	j	80003cea <readi+0x4c>
      brelse(bp);
    80003d50:	854a                	mv	a0,s2
    80003d52:	e16ff0ef          	jal	ra,80003368 <brelse>
      tot = -1;
    80003d56:	59fd                	li	s3,-1
  }
  return tot;
    80003d58:	0009851b          	sext.w	a0,s3
}
    80003d5c:	70a6                	ld	ra,104(sp)
    80003d5e:	7406                	ld	s0,96(sp)
    80003d60:	64e6                	ld	s1,88(sp)
    80003d62:	6946                	ld	s2,80(sp)
    80003d64:	69a6                	ld	s3,72(sp)
    80003d66:	6a06                	ld	s4,64(sp)
    80003d68:	7ae2                	ld	s5,56(sp)
    80003d6a:	7b42                	ld	s6,48(sp)
    80003d6c:	7ba2                	ld	s7,40(sp)
    80003d6e:	7c02                	ld	s8,32(sp)
    80003d70:	6ce2                	ld	s9,24(sp)
    80003d72:	6d42                	ld	s10,16(sp)
    80003d74:	6da2                	ld	s11,8(sp)
    80003d76:	6165                	addi	sp,sp,112
    80003d78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7a:	89d6                	mv	s3,s5
    80003d7c:	bff1                	j	80003d58 <readi+0xba>
    return 0;
    80003d7e:	4501                	li	a0,0
}
    80003d80:	8082                	ret

0000000080003d82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d82:	457c                	lw	a5,76(a0)
    80003d84:	0ed7ea63          	bltu	a5,a3,80003e78 <writei+0xf6>
{
    80003d88:	7159                	addi	sp,sp,-112
    80003d8a:	f486                	sd	ra,104(sp)
    80003d8c:	f0a2                	sd	s0,96(sp)
    80003d8e:	eca6                	sd	s1,88(sp)
    80003d90:	e8ca                	sd	s2,80(sp)
    80003d92:	e4ce                	sd	s3,72(sp)
    80003d94:	e0d2                	sd	s4,64(sp)
    80003d96:	fc56                	sd	s5,56(sp)
    80003d98:	f85a                	sd	s6,48(sp)
    80003d9a:	f45e                	sd	s7,40(sp)
    80003d9c:	f062                	sd	s8,32(sp)
    80003d9e:	ec66                	sd	s9,24(sp)
    80003da0:	e86a                	sd	s10,16(sp)
    80003da2:	e46e                	sd	s11,8(sp)
    80003da4:	1880                	addi	s0,sp,112
    80003da6:	8aaa                	mv	s5,a0
    80003da8:	8bae                	mv	s7,a1
    80003daa:	8a32                	mv	s4,a2
    80003dac:	8936                	mv	s2,a3
    80003dae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003db0:	00e687bb          	addw	a5,a3,a4
    80003db4:	0cd7e463          	bltu	a5,a3,80003e7c <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003db8:	00043737          	lui	a4,0x43
    80003dbc:	0cf76263          	bltu	a4,a5,80003e80 <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dc0:	0a0b0a63          	beqz	s6,80003e74 <writei+0xf2>
    80003dc4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dca:	5c7d                	li	s8,-1
    80003dcc:	a825                	j	80003e04 <writei+0x82>
    80003dce:	020d1d93          	slli	s11,s10,0x20
    80003dd2:	020ddd93          	srli	s11,s11,0x20
    80003dd6:	05848793          	addi	a5,s1,88
    80003dda:	86ee                	mv	a3,s11
    80003ddc:	8652                	mv	a2,s4
    80003dde:	85de                	mv	a1,s7
    80003de0:	953e                	add	a0,a0,a5
    80003de2:	f48fe0ef          	jal	ra,8000252a <either_copyin>
    80003de6:	05850a63          	beq	a0,s8,80003e3a <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dea:	8526                	mv	a0,s1
    80003dec:	688000ef          	jal	ra,80004474 <log_write>
    brelse(bp);
    80003df0:	8526                	mv	a0,s1
    80003df2:	d76ff0ef          	jal	ra,80003368 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df6:	013d09bb          	addw	s3,s10,s3
    80003dfa:	012d093b          	addw	s2,s10,s2
    80003dfe:	9a6e                	add	s4,s4,s11
    80003e00:	0569f063          	bgeu	s3,s6,80003e40 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003e04:	00a9559b          	srliw	a1,s2,0xa
    80003e08:	8556                	mv	a0,s5
    80003e0a:	fd0ff0ef          	jal	ra,800035da <bmap>
    80003e0e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e12:	c59d                	beqz	a1,80003e40 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003e14:	000aa503          	lw	a0,0(s5)
    80003e18:	c48ff0ef          	jal	ra,80003260 <bread>
    80003e1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e1e:	3ff97513          	andi	a0,s2,1023
    80003e22:	40ac87bb          	subw	a5,s9,a0
    80003e26:	413b073b          	subw	a4,s6,s3
    80003e2a:	8d3e                	mv	s10,a5
    80003e2c:	2781                	sext.w	a5,a5
    80003e2e:	0007069b          	sext.w	a3,a4
    80003e32:	f8f6fee3          	bgeu	a3,a5,80003dce <writei+0x4c>
    80003e36:	8d3a                	mv	s10,a4
    80003e38:	bf59                	j	80003dce <writei+0x4c>
      brelse(bp);
    80003e3a:	8526                	mv	a0,s1
    80003e3c:	d2cff0ef          	jal	ra,80003368 <brelse>
  }

  if(off > ip->size)
    80003e40:	04caa783          	lw	a5,76(s5)
    80003e44:	0127f463          	bgeu	a5,s2,80003e4c <writei+0xca>
    ip->size = off;
    80003e48:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e4c:	8556                	mv	a0,s5
    80003e4e:	a13ff0ef          	jal	ra,80003860 <iupdate>

  return tot;
    80003e52:	0009851b          	sext.w	a0,s3
}
    80003e56:	70a6                	ld	ra,104(sp)
    80003e58:	7406                	ld	s0,96(sp)
    80003e5a:	64e6                	ld	s1,88(sp)
    80003e5c:	6946                	ld	s2,80(sp)
    80003e5e:	69a6                	ld	s3,72(sp)
    80003e60:	6a06                	ld	s4,64(sp)
    80003e62:	7ae2                	ld	s5,56(sp)
    80003e64:	7b42                	ld	s6,48(sp)
    80003e66:	7ba2                	ld	s7,40(sp)
    80003e68:	7c02                	ld	s8,32(sp)
    80003e6a:	6ce2                	ld	s9,24(sp)
    80003e6c:	6d42                	ld	s10,16(sp)
    80003e6e:	6da2                	ld	s11,8(sp)
    80003e70:	6165                	addi	sp,sp,112
    80003e72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e74:	89da                	mv	s3,s6
    80003e76:	bfd9                	j	80003e4c <writei+0xca>
    return -1;
    80003e78:	557d                	li	a0,-1
}
    80003e7a:	8082                	ret
    return -1;
    80003e7c:	557d                	li	a0,-1
    80003e7e:	bfe1                	j	80003e56 <writei+0xd4>
    return -1;
    80003e80:	557d                	li	a0,-1
    80003e82:	bfd1                	j	80003e56 <writei+0xd4>

0000000080003e84 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e84:	1141                	addi	sp,sp,-16
    80003e86:	e406                	sd	ra,8(sp)
    80003e88:	e022                	sd	s0,0(sp)
    80003e8a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e8c:	4639                	li	a2,14
    80003e8e:	fe5fc0ef          	jal	ra,80000e72 <strncmp>
}
    80003e92:	60a2                	ld	ra,8(sp)
    80003e94:	6402                	ld	s0,0(sp)
    80003e96:	0141                	addi	sp,sp,16
    80003e98:	8082                	ret

0000000080003e9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e9a:	7139                	addi	sp,sp,-64
    80003e9c:	fc06                	sd	ra,56(sp)
    80003e9e:	f822                	sd	s0,48(sp)
    80003ea0:	f426                	sd	s1,40(sp)
    80003ea2:	f04a                	sd	s2,32(sp)
    80003ea4:	ec4e                	sd	s3,24(sp)
    80003ea6:	e852                	sd	s4,16(sp)
    80003ea8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eaa:	04451703          	lh	a4,68(a0)
    80003eae:	4785                	li	a5,1
    80003eb0:	00f71a63          	bne	a4,a5,80003ec4 <dirlookup+0x2a>
    80003eb4:	892a                	mv	s2,a0
    80003eb6:	89ae                	mv	s3,a1
    80003eb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eba:	457c                	lw	a5,76(a0)
    80003ebc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ebe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec0:	e39d                	bnez	a5,80003ee6 <dirlookup+0x4c>
    80003ec2:	a095                	j	80003f26 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003ec4:	00003517          	auipc	a0,0x3
    80003ec8:	7a450513          	addi	a0,a0,1956 # 80007668 <syscalls+0x1e0>
    80003ecc:	8bffc0ef          	jal	ra,8000078a <panic>
      panic("dirlookup read");
    80003ed0:	00003517          	auipc	a0,0x3
    80003ed4:	7b050513          	addi	a0,a0,1968 # 80007680 <syscalls+0x1f8>
    80003ed8:	8b3fc0ef          	jal	ra,8000078a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003edc:	24c1                	addiw	s1,s1,16
    80003ede:	04c92783          	lw	a5,76(s2)
    80003ee2:	04f4f163          	bgeu	s1,a5,80003f24 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	4741                	li	a4,16
    80003ee8:	86a6                	mv	a3,s1
    80003eea:	fc040613          	addi	a2,s0,-64
    80003eee:	4581                	li	a1,0
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	dadff0ef          	jal	ra,80003c9e <readi>
    80003ef6:	47c1                	li	a5,16
    80003ef8:	fcf51ce3          	bne	a0,a5,80003ed0 <dirlookup+0x36>
    if(de.inum == 0)
    80003efc:	fc045783          	lhu	a5,-64(s0)
    80003f00:	dff1                	beqz	a5,80003edc <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003f02:	fc240593          	addi	a1,s0,-62
    80003f06:	854e                	mv	a0,s3
    80003f08:	f7dff0ef          	jal	ra,80003e84 <namecmp>
    80003f0c:	f961                	bnez	a0,80003edc <dirlookup+0x42>
      if(poff)
    80003f0e:	000a0463          	beqz	s4,80003f16 <dirlookup+0x7c>
        *poff = off;
    80003f12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f16:	fc045583          	lhu	a1,-64(s0)
    80003f1a:	00092503          	lw	a0,0(s2)
    80003f1e:	f88ff0ef          	jal	ra,800036a6 <iget>
    80003f22:	a011                	j	80003f26 <dirlookup+0x8c>
  return 0;
    80003f24:	4501                	li	a0,0
}
    80003f26:	70e2                	ld	ra,56(sp)
    80003f28:	7442                	ld	s0,48(sp)
    80003f2a:	74a2                	ld	s1,40(sp)
    80003f2c:	7902                	ld	s2,32(sp)
    80003f2e:	69e2                	ld	s3,24(sp)
    80003f30:	6a42                	ld	s4,16(sp)
    80003f32:	6121                	addi	sp,sp,64
    80003f34:	8082                	ret

0000000080003f36 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f36:	711d                	addi	sp,sp,-96
    80003f38:	ec86                	sd	ra,88(sp)
    80003f3a:	e8a2                	sd	s0,80(sp)
    80003f3c:	e4a6                	sd	s1,72(sp)
    80003f3e:	e0ca                	sd	s2,64(sp)
    80003f40:	fc4e                	sd	s3,56(sp)
    80003f42:	f852                	sd	s4,48(sp)
    80003f44:	f456                	sd	s5,40(sp)
    80003f46:	f05a                	sd	s6,32(sp)
    80003f48:	ec5e                	sd	s7,24(sp)
    80003f4a:	e862                	sd	s8,16(sp)
    80003f4c:	e466                	sd	s9,8(sp)
    80003f4e:	1080                	addi	s0,sp,96
    80003f50:	84aa                	mv	s1,a0
    80003f52:	8aae                	mv	s5,a1
    80003f54:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f56:	00054703          	lbu	a4,0(a0)
    80003f5a:	02f00793          	li	a5,47
    80003f5e:	00f70f63          	beq	a4,a5,80003f7c <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f62:	ad9fd0ef          	jal	ra,80001a3a <myproc>
    80003f66:	15053503          	ld	a0,336(a0)
    80003f6a:	973ff0ef          	jal	ra,800038dc <idup>
    80003f6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f70:	02f00913          	li	s2,47
  len = path - s;
    80003f74:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f76:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f78:	4b85                	li	s7,1
    80003f7a:	a861                	j	80004012 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    80003f7c:	4585                	li	a1,1
    80003f7e:	4505                	li	a0,1
    80003f80:	f26ff0ef          	jal	ra,800036a6 <iget>
    80003f84:	89aa                	mv	s3,a0
    80003f86:	b7ed                	j	80003f70 <namex+0x3a>
      iunlockput(ip);
    80003f88:	854e                	mv	a0,s3
    80003f8a:	b8fff0ef          	jal	ra,80003b18 <iunlockput>
      return 0;
    80003f8e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f90:	854e                	mv	a0,s3
    80003f92:	60e6                	ld	ra,88(sp)
    80003f94:	6446                	ld	s0,80(sp)
    80003f96:	64a6                	ld	s1,72(sp)
    80003f98:	6906                	ld	s2,64(sp)
    80003f9a:	79e2                	ld	s3,56(sp)
    80003f9c:	7a42                	ld	s4,48(sp)
    80003f9e:	7aa2                	ld	s5,40(sp)
    80003fa0:	7b02                	ld	s6,32(sp)
    80003fa2:	6be2                	ld	s7,24(sp)
    80003fa4:	6c42                	ld	s8,16(sp)
    80003fa6:	6ca2                	ld	s9,8(sp)
    80003fa8:	6125                	addi	sp,sp,96
    80003faa:	8082                	ret
      iunlock(ip);
    80003fac:	854e                	mv	a0,s3
    80003fae:	a0fff0ef          	jal	ra,800039bc <iunlock>
      return ip;
    80003fb2:	bff9                	j	80003f90 <namex+0x5a>
      iunlockput(ip);
    80003fb4:	854e                	mv	a0,s3
    80003fb6:	b63ff0ef          	jal	ra,80003b18 <iunlockput>
      return 0;
    80003fba:	89e6                	mv	s3,s9
    80003fbc:	bfd1                	j	80003f90 <namex+0x5a>
  len = path - s;
    80003fbe:	40b48633          	sub	a2,s1,a1
    80003fc2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fc6:	079c5c63          	bge	s8,s9,8000403e <namex+0x108>
    memmove(name, s, DIRSIZ);
    80003fca:	4639                	li	a2,14
    80003fcc:	8552                	mv	a0,s4
    80003fce:	e35fc0ef          	jal	ra,80000e02 <memmove>
  while(*path == '/')
    80003fd2:	0004c783          	lbu	a5,0(s1)
    80003fd6:	01279763          	bne	a5,s2,80003fe4 <namex+0xae>
    path++;
    80003fda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	ff278de3          	beq	a5,s2,80003fda <namex+0xa4>
    ilock(ip);
    80003fe4:	854e                	mv	a0,s3
    80003fe6:	92dff0ef          	jal	ra,80003912 <ilock>
    if(ip->type != T_DIR){
    80003fea:	04499783          	lh	a5,68(s3)
    80003fee:	f9779de3          	bne	a5,s7,80003f88 <namex+0x52>
    if(nameiparent && *path == '\0'){
    80003ff2:	000a8563          	beqz	s5,80003ffc <namex+0xc6>
    80003ff6:	0004c783          	lbu	a5,0(s1)
    80003ffa:	dbcd                	beqz	a5,80003fac <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ffc:	865a                	mv	a2,s6
    80003ffe:	85d2                	mv	a1,s4
    80004000:	854e                	mv	a0,s3
    80004002:	e99ff0ef          	jal	ra,80003e9a <dirlookup>
    80004006:	8caa                	mv	s9,a0
    80004008:	d555                	beqz	a0,80003fb4 <namex+0x7e>
    iunlockput(ip);
    8000400a:	854e                	mv	a0,s3
    8000400c:	b0dff0ef          	jal	ra,80003b18 <iunlockput>
    ip = next;
    80004010:	89e6                	mv	s3,s9
  while(*path == '/')
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	05279363          	bne	a5,s2,8000405c <namex+0x126>
    path++;
    8000401a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	ff278de3          	beq	a5,s2,8000401a <namex+0xe4>
  if(*path == 0)
    80004024:	c78d                	beqz	a5,8000404e <namex+0x118>
    path++;
    80004026:	85a6                	mv	a1,s1
  len = path - s;
    80004028:	8cda                	mv	s9,s6
    8000402a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000402c:	01278963          	beq	a5,s2,8000403e <namex+0x108>
    80004030:	d7d9                	beqz	a5,80003fbe <namex+0x88>
    path++;
    80004032:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004034:	0004c783          	lbu	a5,0(s1)
    80004038:	ff279ce3          	bne	a5,s2,80004030 <namex+0xfa>
    8000403c:	b749                	j	80003fbe <namex+0x88>
    memmove(name, s, len);
    8000403e:	2601                	sext.w	a2,a2
    80004040:	8552                	mv	a0,s4
    80004042:	dc1fc0ef          	jal	ra,80000e02 <memmove>
    name[len] = 0;
    80004046:	9cd2                	add	s9,s9,s4
    80004048:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000404c:	b759                	j	80003fd2 <namex+0x9c>
  if(nameiparent){
    8000404e:	f40a81e3          	beqz	s5,80003f90 <namex+0x5a>
    iput(ip);
    80004052:	854e                	mv	a0,s3
    80004054:	a3dff0ef          	jal	ra,80003a90 <iput>
    return 0;
    80004058:	4981                	li	s3,0
    8000405a:	bf1d                	j	80003f90 <namex+0x5a>
  if(*path == 0)
    8000405c:	dbed                	beqz	a5,8000404e <namex+0x118>
  while(*path != '/' && *path != 0)
    8000405e:	0004c783          	lbu	a5,0(s1)
    80004062:	85a6                	mv	a1,s1
    80004064:	b7f1                	j	80004030 <namex+0xfa>

0000000080004066 <dirlink>:
{
    80004066:	7139                	addi	sp,sp,-64
    80004068:	fc06                	sd	ra,56(sp)
    8000406a:	f822                	sd	s0,48(sp)
    8000406c:	f426                	sd	s1,40(sp)
    8000406e:	f04a                	sd	s2,32(sp)
    80004070:	ec4e                	sd	s3,24(sp)
    80004072:	e852                	sd	s4,16(sp)
    80004074:	0080                	addi	s0,sp,64
    80004076:	892a                	mv	s2,a0
    80004078:	8a2e                	mv	s4,a1
    8000407a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000407c:	4601                	li	a2,0
    8000407e:	e1dff0ef          	jal	ra,80003e9a <dirlookup>
    80004082:	e52d                	bnez	a0,800040ec <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	04c92483          	lw	s1,76(s2)
    80004088:	c48d                	beqz	s1,800040b2 <dirlink+0x4c>
    8000408a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000408c:	4741                	li	a4,16
    8000408e:	86a6                	mv	a3,s1
    80004090:	fc040613          	addi	a2,s0,-64
    80004094:	4581                	li	a1,0
    80004096:	854a                	mv	a0,s2
    80004098:	c07ff0ef          	jal	ra,80003c9e <readi>
    8000409c:	47c1                	li	a5,16
    8000409e:	04f51b63          	bne	a0,a5,800040f4 <dirlink+0x8e>
    if(de.inum == 0)
    800040a2:	fc045783          	lhu	a5,-64(s0)
    800040a6:	c791                	beqz	a5,800040b2 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a8:	24c1                	addiw	s1,s1,16
    800040aa:	04c92783          	lw	a5,76(s2)
    800040ae:	fcf4efe3          	bltu	s1,a5,8000408c <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    800040b2:	4639                	li	a2,14
    800040b4:	85d2                	mv	a1,s4
    800040b6:	fc240513          	addi	a0,s0,-62
    800040ba:	df5fc0ef          	jal	ra,80000eae <strncpy>
  de.inum = inum;
    800040be:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c2:	4741                	li	a4,16
    800040c4:	86a6                	mv	a3,s1
    800040c6:	fc040613          	addi	a2,s0,-64
    800040ca:	4581                	li	a1,0
    800040cc:	854a                	mv	a0,s2
    800040ce:	cb5ff0ef          	jal	ra,80003d82 <writei>
    800040d2:	1541                	addi	a0,a0,-16
    800040d4:	00a03533          	snez	a0,a0
    800040d8:	40a00533          	neg	a0,a0
}
    800040dc:	70e2                	ld	ra,56(sp)
    800040de:	7442                	ld	s0,48(sp)
    800040e0:	74a2                	ld	s1,40(sp)
    800040e2:	7902                	ld	s2,32(sp)
    800040e4:	69e2                	ld	s3,24(sp)
    800040e6:	6a42                	ld	s4,16(sp)
    800040e8:	6121                	addi	sp,sp,64
    800040ea:	8082                	ret
    iput(ip);
    800040ec:	9a5ff0ef          	jal	ra,80003a90 <iput>
    return -1;
    800040f0:	557d                	li	a0,-1
    800040f2:	b7ed                	j	800040dc <dirlink+0x76>
      panic("dirlink read");
    800040f4:	00003517          	auipc	a0,0x3
    800040f8:	59c50513          	addi	a0,a0,1436 # 80007690 <syscalls+0x208>
    800040fc:	e8efc0ef          	jal	ra,8000078a <panic>

0000000080004100 <namei>:

struct inode*
namei(char *path)
{
    80004100:	1101                	addi	sp,sp,-32
    80004102:	ec06                	sd	ra,24(sp)
    80004104:	e822                	sd	s0,16(sp)
    80004106:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004108:	fe040613          	addi	a2,s0,-32
    8000410c:	4581                	li	a1,0
    8000410e:	e29ff0ef          	jal	ra,80003f36 <namex>
}
    80004112:	60e2                	ld	ra,24(sp)
    80004114:	6442                	ld	s0,16(sp)
    80004116:	6105                	addi	sp,sp,32
    80004118:	8082                	ret

000000008000411a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000411a:	1141                	addi	sp,sp,-16
    8000411c:	e406                	sd	ra,8(sp)
    8000411e:	e022                	sd	s0,0(sp)
    80004120:	0800                	addi	s0,sp,16
    80004122:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004124:	4585                	li	a1,1
    80004126:	e11ff0ef          	jal	ra,80003f36 <namex>
}
    8000412a:	60a2                	ld	ra,8(sp)
    8000412c:	6402                	ld	s0,0(sp)
    8000412e:	0141                	addi	sp,sp,16
    80004130:	8082                	ret

0000000080004132 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004132:	1101                	addi	sp,sp,-32
    80004134:	ec06                	sd	ra,24(sp)
    80004136:	e822                	sd	s0,16(sp)
    80004138:	e426                	sd	s1,8(sp)
    8000413a:	e04a                	sd	s2,0(sp)
    8000413c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000413e:	000a6917          	auipc	s2,0xa6
    80004142:	27a90913          	addi	s2,s2,634 # 800aa3b8 <log>
    80004146:	01892583          	lw	a1,24(s2)
    8000414a:	02492503          	lw	a0,36(s2)
    8000414e:	912ff0ef          	jal	ra,80003260 <bread>
    80004152:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004154:	02892683          	lw	a3,40(s2)
    80004158:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000415a:	02d05763          	blez	a3,80004188 <write_head+0x56>
    8000415e:	000a6797          	auipc	a5,0xa6
    80004162:	28678793          	addi	a5,a5,646 # 800aa3e4 <log+0x2c>
    80004166:	05c50713          	addi	a4,a0,92
    8000416a:	36fd                	addiw	a3,a3,-1
    8000416c:	1682                	slli	a3,a3,0x20
    8000416e:	9281                	srli	a3,a3,0x20
    80004170:	068a                	slli	a3,a3,0x2
    80004172:	000a6617          	auipc	a2,0xa6
    80004176:	27660613          	addi	a2,a2,630 # 800aa3e8 <log+0x30>
    8000417a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000417c:	4390                	lw	a2,0(a5)
    8000417e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004180:	0791                	addi	a5,a5,4
    80004182:	0711                	addi	a4,a4,4
    80004184:	fed79ce3          	bne	a5,a3,8000417c <write_head+0x4a>
  }
  bwrite(buf);
    80004188:	8526                	mv	a0,s1
    8000418a:	9acff0ef          	jal	ra,80003336 <bwrite>
  brelse(buf);
    8000418e:	8526                	mv	a0,s1
    80004190:	9d8ff0ef          	jal	ra,80003368 <brelse>
}
    80004194:	60e2                	ld	ra,24(sp)
    80004196:	6442                	ld	s0,16(sp)
    80004198:	64a2                	ld	s1,8(sp)
    8000419a:	6902                	ld	s2,0(sp)
    8000419c:	6105                	addi	sp,sp,32
    8000419e:	8082                	ret

00000000800041a0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a0:	000a6797          	auipc	a5,0xa6
    800041a4:	2407a783          	lw	a5,576(a5) # 800aa3e0 <log+0x28>
    800041a8:	0af05e63          	blez	a5,80004264 <install_trans+0xc4>
{
    800041ac:	715d                	addi	sp,sp,-80
    800041ae:	e486                	sd	ra,72(sp)
    800041b0:	e0a2                	sd	s0,64(sp)
    800041b2:	fc26                	sd	s1,56(sp)
    800041b4:	f84a                	sd	s2,48(sp)
    800041b6:	f44e                	sd	s3,40(sp)
    800041b8:	f052                	sd	s4,32(sp)
    800041ba:	ec56                	sd	s5,24(sp)
    800041bc:	e85a                	sd	s6,16(sp)
    800041be:	e45e                	sd	s7,8(sp)
    800041c0:	0880                	addi	s0,sp,80
    800041c2:	8b2a                	mv	s6,a0
    800041c4:	000a6a97          	auipc	s5,0xa6
    800041c8:	220a8a93          	addi	s5,s5,544 # 800aa3e4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041cc:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800041ce:	00003b97          	auipc	s7,0x3
    800041d2:	4d2b8b93          	addi	s7,s7,1234 # 800076a0 <syscalls+0x218>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041d6:	000a6a17          	auipc	s4,0xa6
    800041da:	1e2a0a13          	addi	s4,s4,482 # 800aa3b8 <log>
    800041de:	a025                	j	80004206 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800041e0:	000aa603          	lw	a2,0(s5)
    800041e4:	85ce                	mv	a1,s3
    800041e6:	855e                	mv	a0,s7
    800041e8:	adcfc0ef          	jal	ra,800004c4 <printf>
    800041ec:	a839                	j	8000420a <install_trans+0x6a>
    brelse(lbuf);
    800041ee:	854a                	mv	a0,s2
    800041f0:	978ff0ef          	jal	ra,80003368 <brelse>
    brelse(dbuf);
    800041f4:	8526                	mv	a0,s1
    800041f6:	972ff0ef          	jal	ra,80003368 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fa:	2985                	addiw	s3,s3,1
    800041fc:	0a91                	addi	s5,s5,4
    800041fe:	028a2783          	lw	a5,40(s4)
    80004202:	04f9d663          	bge	s3,a5,8000424e <install_trans+0xae>
    if(recovering) {
    80004206:	fc0b1de3          	bnez	s6,800041e0 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420a:	018a2583          	lw	a1,24(s4)
    8000420e:	013585bb          	addw	a1,a1,s3
    80004212:	2585                	addiw	a1,a1,1
    80004214:	024a2503          	lw	a0,36(s4)
    80004218:	848ff0ef          	jal	ra,80003260 <bread>
    8000421c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000421e:	000aa583          	lw	a1,0(s5)
    80004222:	024a2503          	lw	a0,36(s4)
    80004226:	83aff0ef          	jal	ra,80003260 <bread>
    8000422a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000422c:	40000613          	li	a2,1024
    80004230:	05890593          	addi	a1,s2,88
    80004234:	05850513          	addi	a0,a0,88
    80004238:	bcbfc0ef          	jal	ra,80000e02 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000423c:	8526                	mv	a0,s1
    8000423e:	8f8ff0ef          	jal	ra,80003336 <bwrite>
    if(recovering == 0)
    80004242:	fa0b16e3          	bnez	s6,800041ee <install_trans+0x4e>
      bunpin(dbuf);
    80004246:	8526                	mv	a0,s1
    80004248:	9deff0ef          	jal	ra,80003426 <bunpin>
    8000424c:	b74d                	j	800041ee <install_trans+0x4e>
}
    8000424e:	60a6                	ld	ra,72(sp)
    80004250:	6406                	ld	s0,64(sp)
    80004252:	74e2                	ld	s1,56(sp)
    80004254:	7942                	ld	s2,48(sp)
    80004256:	79a2                	ld	s3,40(sp)
    80004258:	7a02                	ld	s4,32(sp)
    8000425a:	6ae2                	ld	s5,24(sp)
    8000425c:	6b42                	ld	s6,16(sp)
    8000425e:	6ba2                	ld	s7,8(sp)
    80004260:	6161                	addi	sp,sp,80
    80004262:	8082                	ret
    80004264:	8082                	ret

0000000080004266 <initlog>:
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	1800                	addi	s0,sp,48
    80004274:	892a                	mv	s2,a0
    80004276:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004278:	000a6497          	auipc	s1,0xa6
    8000427c:	14048493          	addi	s1,s1,320 # 800aa3b8 <log>
    80004280:	00003597          	auipc	a1,0x3
    80004284:	44058593          	addi	a1,a1,1088 # 800076c0 <syscalls+0x238>
    80004288:	8526                	mv	a0,s1
    8000428a:	9c9fc0ef          	jal	ra,80000c52 <initlock>
  log.start = sb->logstart;
    8000428e:	0149a583          	lw	a1,20(s3)
    80004292:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80004294:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004298:	854a                	mv	a0,s2
    8000429a:	fc7fe0ef          	jal	ra,80003260 <bread>
  log.lh.n = lh->n;
    8000429e:	4d34                	lw	a3,88(a0)
    800042a0:	d494                	sw	a3,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042a2:	02d05563          	blez	a3,800042cc <initlog+0x66>
    800042a6:	05c50793          	addi	a5,a0,92
    800042aa:	000a6717          	auipc	a4,0xa6
    800042ae:	13a70713          	addi	a4,a4,314 # 800aa3e4 <log+0x2c>
    800042b2:	36fd                	addiw	a3,a3,-1
    800042b4:	1682                	slli	a3,a3,0x20
    800042b6:	9281                	srli	a3,a3,0x20
    800042b8:	068a                	slli	a3,a3,0x2
    800042ba:	06050613          	addi	a2,a0,96
    800042be:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042c0:	4390                	lw	a2,0(a5)
    800042c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042c4:	0791                	addi	a5,a5,4
    800042c6:	0711                	addi	a4,a4,4
    800042c8:	fed79ce3          	bne	a5,a3,800042c0 <initlog+0x5a>
  brelse(buf);
    800042cc:	89cff0ef          	jal	ra,80003368 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042d0:	4505                	li	a0,1
    800042d2:	ecfff0ef          	jal	ra,800041a0 <install_trans>
  log.lh.n = 0;
    800042d6:	000a6797          	auipc	a5,0xa6
    800042da:	1007a523          	sw	zero,266(a5) # 800aa3e0 <log+0x28>
  write_head(); // clear the log
    800042de:	e55ff0ef          	jal	ra,80004132 <write_head>
}
    800042e2:	70a2                	ld	ra,40(sp)
    800042e4:	7402                	ld	s0,32(sp)
    800042e6:	64e2                	ld	s1,24(sp)
    800042e8:	6942                	ld	s2,16(sp)
    800042ea:	69a2                	ld	s3,8(sp)
    800042ec:	6145                	addi	sp,sp,48
    800042ee:	8082                	ret

00000000800042f0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	e426                	sd	s1,8(sp)
    800042f8:	e04a                	sd	s2,0(sp)
    800042fa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042fc:	000a6517          	auipc	a0,0xa6
    80004300:	0bc50513          	addi	a0,a0,188 # 800aa3b8 <log>
    80004304:	9cffc0ef          	jal	ra,80000cd2 <acquire>
  while(1){
    if(log.committing){
    80004308:	000a6497          	auipc	s1,0xa6
    8000430c:	0b048493          	addi	s1,s1,176 # 800aa3b8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004310:	4979                	li	s2,30
    80004312:	a029                	j	8000431c <begin_op+0x2c>
      sleep(&log, &log.lock);
    80004314:	85a6                	mv	a1,s1
    80004316:	8526                	mv	a0,s1
    80004318:	e6dfd0ef          	jal	ra,80002184 <sleep>
    if(log.committing){
    8000431c:	509c                	lw	a5,32(s1)
    8000431e:	fbfd                	bnez	a5,80004314 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004320:	4cdc                	lw	a5,28(s1)
    80004322:	0017871b          	addiw	a4,a5,1
    80004326:	0007069b          	sext.w	a3,a4
    8000432a:	0027179b          	slliw	a5,a4,0x2
    8000432e:	9fb9                	addw	a5,a5,a4
    80004330:	0017979b          	slliw	a5,a5,0x1
    80004334:	5498                	lw	a4,40(s1)
    80004336:	9fb9                	addw	a5,a5,a4
    80004338:	00f95763          	bge	s2,a5,80004346 <begin_op+0x56>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000433c:	85a6                	mv	a1,s1
    8000433e:	8526                	mv	a0,s1
    80004340:	e45fd0ef          	jal	ra,80002184 <sleep>
    80004344:	bfe1                	j	8000431c <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80004346:	000a6517          	auipc	a0,0xa6
    8000434a:	07250513          	addi	a0,a0,114 # 800aa3b8 <log>
    8000434e:	cd54                	sw	a3,28(a0)
      release(&log.lock);
    80004350:	a1bfc0ef          	jal	ra,80000d6a <release>
      break;
    }
  }
}
    80004354:	60e2                	ld	ra,24(sp)
    80004356:	6442                	ld	s0,16(sp)
    80004358:	64a2                	ld	s1,8(sp)
    8000435a:	6902                	ld	s2,0(sp)
    8000435c:	6105                	addi	sp,sp,32
    8000435e:	8082                	ret

0000000080004360 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004360:	7139                	addi	sp,sp,-64
    80004362:	fc06                	sd	ra,56(sp)
    80004364:	f822                	sd	s0,48(sp)
    80004366:	f426                	sd	s1,40(sp)
    80004368:	f04a                	sd	s2,32(sp)
    8000436a:	ec4e                	sd	s3,24(sp)
    8000436c:	e852                	sd	s4,16(sp)
    8000436e:	e456                	sd	s5,8(sp)
    80004370:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004372:	000a6497          	auipc	s1,0xa6
    80004376:	04648493          	addi	s1,s1,70 # 800aa3b8 <log>
    8000437a:	8526                	mv	a0,s1
    8000437c:	957fc0ef          	jal	ra,80000cd2 <acquire>
  log.outstanding -= 1;
    80004380:	4cdc                	lw	a5,28(s1)
    80004382:	37fd                	addiw	a5,a5,-1
    80004384:	0007891b          	sext.w	s2,a5
    80004388:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    8000438a:	509c                	lw	a5,32(s1)
    8000438c:	ef9d                	bnez	a5,800043ca <end_op+0x6a>
    panic("log.committing");
  if(log.outstanding == 0){
    8000438e:	04091463          	bnez	s2,800043d6 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80004392:	000a6497          	auipc	s1,0xa6
    80004396:	02648493          	addi	s1,s1,38 # 800aa3b8 <log>
    8000439a:	4785                	li	a5,1
    8000439c:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000439e:	8526                	mv	a0,s1
    800043a0:	9cbfc0ef          	jal	ra,80000d6a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043a4:	549c                	lw	a5,40(s1)
    800043a6:	04f04b63          	bgtz	a5,800043fc <end_op+0x9c>
    acquire(&log.lock);
    800043aa:	000a6497          	auipc	s1,0xa6
    800043ae:	00e48493          	addi	s1,s1,14 # 800aa3b8 <log>
    800043b2:	8526                	mv	a0,s1
    800043b4:	91ffc0ef          	jal	ra,80000cd2 <acquire>
    log.committing = 0;
    800043b8:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    800043bc:	8526                	mv	a0,s1
    800043be:	e13fd0ef          	jal	ra,800021d0 <wakeup>
    release(&log.lock);
    800043c2:	8526                	mv	a0,s1
    800043c4:	9a7fc0ef          	jal	ra,80000d6a <release>
}
    800043c8:	a00d                	j	800043ea <end_op+0x8a>
    panic("log.committing");
    800043ca:	00003517          	auipc	a0,0x3
    800043ce:	2fe50513          	addi	a0,a0,766 # 800076c8 <syscalls+0x240>
    800043d2:	bb8fc0ef          	jal	ra,8000078a <panic>
    wakeup(&log);
    800043d6:	000a6497          	auipc	s1,0xa6
    800043da:	fe248493          	addi	s1,s1,-30 # 800aa3b8 <log>
    800043de:	8526                	mv	a0,s1
    800043e0:	df1fd0ef          	jal	ra,800021d0 <wakeup>
  release(&log.lock);
    800043e4:	8526                	mv	a0,s1
    800043e6:	985fc0ef          	jal	ra,80000d6a <release>
}
    800043ea:	70e2                	ld	ra,56(sp)
    800043ec:	7442                	ld	s0,48(sp)
    800043ee:	74a2                	ld	s1,40(sp)
    800043f0:	7902                	ld	s2,32(sp)
    800043f2:	69e2                	ld	s3,24(sp)
    800043f4:	6a42                	ld	s4,16(sp)
    800043f6:	6aa2                	ld	s5,8(sp)
    800043f8:	6121                	addi	sp,sp,64
    800043fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fc:	000a6a97          	auipc	s5,0xa6
    80004400:	fe8a8a93          	addi	s5,s5,-24 # 800aa3e4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004404:	000a6a17          	auipc	s4,0xa6
    80004408:	fb4a0a13          	addi	s4,s4,-76 # 800aa3b8 <log>
    8000440c:	018a2583          	lw	a1,24(s4)
    80004410:	012585bb          	addw	a1,a1,s2
    80004414:	2585                	addiw	a1,a1,1
    80004416:	024a2503          	lw	a0,36(s4)
    8000441a:	e47fe0ef          	jal	ra,80003260 <bread>
    8000441e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004420:	000aa583          	lw	a1,0(s5)
    80004424:	024a2503          	lw	a0,36(s4)
    80004428:	e39fe0ef          	jal	ra,80003260 <bread>
    8000442c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000442e:	40000613          	li	a2,1024
    80004432:	05850593          	addi	a1,a0,88
    80004436:	05848513          	addi	a0,s1,88
    8000443a:	9c9fc0ef          	jal	ra,80000e02 <memmove>
    bwrite(to);  // write the log
    8000443e:	8526                	mv	a0,s1
    80004440:	ef7fe0ef          	jal	ra,80003336 <bwrite>
    brelse(from);
    80004444:	854e                	mv	a0,s3
    80004446:	f23fe0ef          	jal	ra,80003368 <brelse>
    brelse(to);
    8000444a:	8526                	mv	a0,s1
    8000444c:	f1dfe0ef          	jal	ra,80003368 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004450:	2905                	addiw	s2,s2,1
    80004452:	0a91                	addi	s5,s5,4
    80004454:	028a2783          	lw	a5,40(s4)
    80004458:	faf94ae3          	blt	s2,a5,8000440c <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000445c:	cd7ff0ef          	jal	ra,80004132 <write_head>
    install_trans(0); // Now install writes to home locations
    80004460:	4501                	li	a0,0
    80004462:	d3fff0ef          	jal	ra,800041a0 <install_trans>
    log.lh.n = 0;
    80004466:	000a6797          	auipc	a5,0xa6
    8000446a:	f607ad23          	sw	zero,-134(a5) # 800aa3e0 <log+0x28>
    write_head();    // Erase the transaction from the log
    8000446e:	cc5ff0ef          	jal	ra,80004132 <write_head>
    80004472:	bf25                	j	800043aa <end_op+0x4a>

0000000080004474 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	e04a                	sd	s2,0(sp)
    8000447e:	1000                	addi	s0,sp,32
    80004480:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004482:	000a6917          	auipc	s2,0xa6
    80004486:	f3690913          	addi	s2,s2,-202 # 800aa3b8 <log>
    8000448a:	854a                	mv	a0,s2
    8000448c:	847fc0ef          	jal	ra,80000cd2 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80004490:	02892603          	lw	a2,40(s2)
    80004494:	47f5                	li	a5,29
    80004496:	04c7cc63          	blt	a5,a2,800044ee <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000449a:	000a6797          	auipc	a5,0xa6
    8000449e:	f3a7a783          	lw	a5,-198(a5) # 800aa3d4 <log+0x1c>
    800044a2:	04f05c63          	blez	a5,800044fa <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044a6:	4781                	li	a5,0
    800044a8:	04c05f63          	blez	a2,80004506 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ac:	44cc                	lw	a1,12(s1)
    800044ae:	000a6717          	auipc	a4,0xa6
    800044b2:	f3670713          	addi	a4,a4,-202 # 800aa3e4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    800044b6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b8:	4314                	lw	a3,0(a4)
    800044ba:	04b68663          	beq	a3,a1,80004506 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    800044be:	2785                	addiw	a5,a5,1
    800044c0:	0711                	addi	a4,a4,4
    800044c2:	fef61be3          	bne	a2,a5,800044b8 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044c6:	0621                	addi	a2,a2,8
    800044c8:	060a                	slli	a2,a2,0x2
    800044ca:	000a6797          	auipc	a5,0xa6
    800044ce:	eee78793          	addi	a5,a5,-274 # 800aa3b8 <log>
    800044d2:	963e                	add	a2,a2,a5
    800044d4:	44dc                	lw	a5,12(s1)
    800044d6:	c65c                	sw	a5,12(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044d8:	8526                	mv	a0,s1
    800044da:	f19fe0ef          	jal	ra,800033f2 <bpin>
    log.lh.n++;
    800044de:	000a6717          	auipc	a4,0xa6
    800044e2:	eda70713          	addi	a4,a4,-294 # 800aa3b8 <log>
    800044e6:	571c                	lw	a5,40(a4)
    800044e8:	2785                	addiw	a5,a5,1
    800044ea:	d71c                	sw	a5,40(a4)
    800044ec:	a815                	j	80004520 <log_write+0xac>
    panic("too big a transaction");
    800044ee:	00003517          	auipc	a0,0x3
    800044f2:	1ea50513          	addi	a0,a0,490 # 800076d8 <syscalls+0x250>
    800044f6:	a94fc0ef          	jal	ra,8000078a <panic>
    panic("log_write outside of trans");
    800044fa:	00003517          	auipc	a0,0x3
    800044fe:	1f650513          	addi	a0,a0,502 # 800076f0 <syscalls+0x268>
    80004502:	a88fc0ef          	jal	ra,8000078a <panic>
  log.lh.block[i] = b->blockno;
    80004506:	00878713          	addi	a4,a5,8
    8000450a:	00271693          	slli	a3,a4,0x2
    8000450e:	000a6717          	auipc	a4,0xa6
    80004512:	eaa70713          	addi	a4,a4,-342 # 800aa3b8 <log>
    80004516:	9736                	add	a4,a4,a3
    80004518:	44d4                	lw	a3,12(s1)
    8000451a:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000451c:	faf60ee3          	beq	a2,a5,800044d8 <log_write+0x64>
  }
  release(&log.lock);
    80004520:	000a6517          	auipc	a0,0xa6
    80004524:	e9850513          	addi	a0,a0,-360 # 800aa3b8 <log>
    80004528:	843fc0ef          	jal	ra,80000d6a <release>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	e426                	sd	s1,8(sp)
    80004540:	e04a                	sd	s2,0(sp)
    80004542:	1000                	addi	s0,sp,32
    80004544:	84aa                	mv	s1,a0
    80004546:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004548:	00003597          	auipc	a1,0x3
    8000454c:	1c858593          	addi	a1,a1,456 # 80007710 <syscalls+0x288>
    80004550:	0521                	addi	a0,a0,8
    80004552:	f00fc0ef          	jal	ra,80000c52 <initlock>
  lk->name = name;
    80004556:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000455a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000455e:	0204a423          	sw	zero,40(s1)
}
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6902                	ld	s2,0(sp)
    8000456a:	6105                	addi	sp,sp,32
    8000456c:	8082                	ret

000000008000456e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
    8000457a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000457c:	00850913          	addi	s2,a0,8
    80004580:	854a                	mv	a0,s2
    80004582:	f50fc0ef          	jal	ra,80000cd2 <acquire>
  while (lk->locked) {
    80004586:	409c                	lw	a5,0(s1)
    80004588:	c799                	beqz	a5,80004596 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    8000458a:	85ca                	mv	a1,s2
    8000458c:	8526                	mv	a0,s1
    8000458e:	bf7fd0ef          	jal	ra,80002184 <sleep>
  while (lk->locked) {
    80004592:	409c                	lw	a5,0(s1)
    80004594:	fbfd                	bnez	a5,8000458a <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004596:	4785                	li	a5,1
    80004598:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000459a:	ca0fd0ef          	jal	ra,80001a3a <myproc>
    8000459e:	591c                	lw	a5,48(a0)
    800045a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045a2:	854a                	mv	a0,s2
    800045a4:	fc6fc0ef          	jal	ra,80000d6a <release>
}
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6902                	ld	s2,0(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret

00000000800045b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b4:	1101                	addi	sp,sp,-32
    800045b6:	ec06                	sd	ra,24(sp)
    800045b8:	e822                	sd	s0,16(sp)
    800045ba:	e426                	sd	s1,8(sp)
    800045bc:	e04a                	sd	s2,0(sp)
    800045be:	1000                	addi	s0,sp,32
    800045c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c2:	00850913          	addi	s2,a0,8
    800045c6:	854a                	mv	a0,s2
    800045c8:	f0afc0ef          	jal	ra,80000cd2 <acquire>
  lk->locked = 0;
    800045cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d4:	8526                	mv	a0,s1
    800045d6:	bfbfd0ef          	jal	ra,800021d0 <wakeup>
  release(&lk->lk);
    800045da:	854a                	mv	a0,s2
    800045dc:	f8efc0ef          	jal	ra,80000d6a <release>
}
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6902                	ld	s2,0(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ec:	7179                	addi	sp,sp,-48
    800045ee:	f406                	sd	ra,40(sp)
    800045f0:	f022                	sd	s0,32(sp)
    800045f2:	ec26                	sd	s1,24(sp)
    800045f4:	e84a                	sd	s2,16(sp)
    800045f6:	e44e                	sd	s3,8(sp)
    800045f8:	1800                	addi	s0,sp,48
    800045fa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045fc:	00850913          	addi	s2,a0,8
    80004600:	854a                	mv	a0,s2
    80004602:	ed0fc0ef          	jal	ra,80000cd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004606:	409c                	lw	a5,0(s1)
    80004608:	ef89                	bnez	a5,80004622 <holdingsleep+0x36>
    8000460a:	4481                	li	s1,0
  release(&lk->lk);
    8000460c:	854a                	mv	a0,s2
    8000460e:	f5cfc0ef          	jal	ra,80000d6a <release>
  return r;
}
    80004612:	8526                	mv	a0,s1
    80004614:	70a2                	ld	ra,40(sp)
    80004616:	7402                	ld	s0,32(sp)
    80004618:	64e2                	ld	s1,24(sp)
    8000461a:	6942                	ld	s2,16(sp)
    8000461c:	69a2                	ld	s3,8(sp)
    8000461e:	6145                	addi	sp,sp,48
    80004620:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004622:	0284a983          	lw	s3,40(s1)
    80004626:	c14fd0ef          	jal	ra,80001a3a <myproc>
    8000462a:	5904                	lw	s1,48(a0)
    8000462c:	413484b3          	sub	s1,s1,s3
    80004630:	0014b493          	seqz	s1,s1
    80004634:	bfe1                	j	8000460c <holdingsleep+0x20>

0000000080004636 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004636:	1141                	addi	sp,sp,-16
    80004638:	e406                	sd	ra,8(sp)
    8000463a:	e022                	sd	s0,0(sp)
    8000463c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000463e:	00003597          	auipc	a1,0x3
    80004642:	0e258593          	addi	a1,a1,226 # 80007720 <syscalls+0x298>
    80004646:	000a6517          	auipc	a0,0xa6
    8000464a:	eba50513          	addi	a0,a0,-326 # 800aa500 <ftable>
    8000464e:	e04fc0ef          	jal	ra,80000c52 <initlock>
}
    80004652:	60a2                	ld	ra,8(sp)
    80004654:	6402                	ld	s0,0(sp)
    80004656:	0141                	addi	sp,sp,16
    80004658:	8082                	ret

000000008000465a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000465a:	1101                	addi	sp,sp,-32
    8000465c:	ec06                	sd	ra,24(sp)
    8000465e:	e822                	sd	s0,16(sp)
    80004660:	e426                	sd	s1,8(sp)
    80004662:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004664:	000a6517          	auipc	a0,0xa6
    80004668:	e9c50513          	addi	a0,a0,-356 # 800aa500 <ftable>
    8000466c:	e66fc0ef          	jal	ra,80000cd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004670:	000a6497          	auipc	s1,0xa6
    80004674:	ea848493          	addi	s1,s1,-344 # 800aa518 <ftable+0x18>
    80004678:	000a7717          	auipc	a4,0xa7
    8000467c:	e4070713          	addi	a4,a4,-448 # 800ab4b8 <disk>
    if(f->ref == 0){
    80004680:	40dc                	lw	a5,4(s1)
    80004682:	cf89                	beqz	a5,8000469c <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004684:	02848493          	addi	s1,s1,40
    80004688:	fee49ce3          	bne	s1,a4,80004680 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000468c:	000a6517          	auipc	a0,0xa6
    80004690:	e7450513          	addi	a0,a0,-396 # 800aa500 <ftable>
    80004694:	ed6fc0ef          	jal	ra,80000d6a <release>
  return 0;
    80004698:	4481                	li	s1,0
    8000469a:	a809                	j	800046ac <filealloc+0x52>
      f->ref = 1;
    8000469c:	4785                	li	a5,1
    8000469e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046a0:	000a6517          	auipc	a0,0xa6
    800046a4:	e6050513          	addi	a0,a0,-416 # 800aa500 <ftable>
    800046a8:	ec2fc0ef          	jal	ra,80000d6a <release>
}
    800046ac:	8526                	mv	a0,s1
    800046ae:	60e2                	ld	ra,24(sp)
    800046b0:	6442                	ld	s0,16(sp)
    800046b2:	64a2                	ld	s1,8(sp)
    800046b4:	6105                	addi	sp,sp,32
    800046b6:	8082                	ret

00000000800046b8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046b8:	1101                	addi	sp,sp,-32
    800046ba:	ec06                	sd	ra,24(sp)
    800046bc:	e822                	sd	s0,16(sp)
    800046be:	e426                	sd	s1,8(sp)
    800046c0:	1000                	addi	s0,sp,32
    800046c2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046c4:	000a6517          	auipc	a0,0xa6
    800046c8:	e3c50513          	addi	a0,a0,-452 # 800aa500 <ftable>
    800046cc:	e06fc0ef          	jal	ra,80000cd2 <acquire>
  if(f->ref < 1)
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	02f05063          	blez	a5,800046f2 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    800046d6:	2785                	addiw	a5,a5,1
    800046d8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046da:	000a6517          	auipc	a0,0xa6
    800046de:	e2650513          	addi	a0,a0,-474 # 800aa500 <ftable>
    800046e2:	e88fc0ef          	jal	ra,80000d6a <release>
  return f;
}
    800046e6:	8526                	mv	a0,s1
    800046e8:	60e2                	ld	ra,24(sp)
    800046ea:	6442                	ld	s0,16(sp)
    800046ec:	64a2                	ld	s1,8(sp)
    800046ee:	6105                	addi	sp,sp,32
    800046f0:	8082                	ret
    panic("filedup");
    800046f2:	00003517          	auipc	a0,0x3
    800046f6:	03650513          	addi	a0,a0,54 # 80007728 <syscalls+0x2a0>
    800046fa:	890fc0ef          	jal	ra,8000078a <panic>

00000000800046fe <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046fe:	7139                	addi	sp,sp,-64
    80004700:	fc06                	sd	ra,56(sp)
    80004702:	f822                	sd	s0,48(sp)
    80004704:	f426                	sd	s1,40(sp)
    80004706:	f04a                	sd	s2,32(sp)
    80004708:	ec4e                	sd	s3,24(sp)
    8000470a:	e852                	sd	s4,16(sp)
    8000470c:	e456                	sd	s5,8(sp)
    8000470e:	0080                	addi	s0,sp,64
    80004710:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004712:	000a6517          	auipc	a0,0xa6
    80004716:	dee50513          	addi	a0,a0,-530 # 800aa500 <ftable>
    8000471a:	db8fc0ef          	jal	ra,80000cd2 <acquire>
  if(f->ref < 1)
    8000471e:	40dc                	lw	a5,4(s1)
    80004720:	04f05963          	blez	a5,80004772 <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){
    80004724:	37fd                	addiw	a5,a5,-1
    80004726:	0007871b          	sext.w	a4,a5
    8000472a:	c0dc                	sw	a5,4(s1)
    8000472c:	04e04963          	bgtz	a4,8000477e <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004730:	0004a903          	lw	s2,0(s1)
    80004734:	0094ca83          	lbu	s5,9(s1)
    80004738:	0104ba03          	ld	s4,16(s1)
    8000473c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004740:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004744:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004748:	000a6517          	auipc	a0,0xa6
    8000474c:	db850513          	addi	a0,a0,-584 # 800aa500 <ftable>
    80004750:	e1afc0ef          	jal	ra,80000d6a <release>

  if(ff.type == FD_PIPE){
    80004754:	4785                	li	a5,1
    80004756:	04f90363          	beq	s2,a5,8000479c <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000475a:	3979                	addiw	s2,s2,-2
    8000475c:	4785                	li	a5,1
    8000475e:	0327e663          	bltu	a5,s2,8000478a <fileclose+0x8c>
    begin_op();
    80004762:	b8fff0ef          	jal	ra,800042f0 <begin_op>
    iput(ff.ip);
    80004766:	854e                	mv	a0,s3
    80004768:	b28ff0ef          	jal	ra,80003a90 <iput>
    end_op();
    8000476c:	bf5ff0ef          	jal	ra,80004360 <end_op>
    80004770:	a829                	j	8000478a <fileclose+0x8c>
    panic("fileclose");
    80004772:	00003517          	auipc	a0,0x3
    80004776:	fbe50513          	addi	a0,a0,-66 # 80007730 <syscalls+0x2a8>
    8000477a:	810fc0ef          	jal	ra,8000078a <panic>
    release(&ftable.lock);
    8000477e:	000a6517          	auipc	a0,0xa6
    80004782:	d8250513          	addi	a0,a0,-638 # 800aa500 <ftable>
    80004786:	de4fc0ef          	jal	ra,80000d6a <release>
  }
}
    8000478a:	70e2                	ld	ra,56(sp)
    8000478c:	7442                	ld	s0,48(sp)
    8000478e:	74a2                	ld	s1,40(sp)
    80004790:	7902                	ld	s2,32(sp)
    80004792:	69e2                	ld	s3,24(sp)
    80004794:	6a42                	ld	s4,16(sp)
    80004796:	6aa2                	ld	s5,8(sp)
    80004798:	6121                	addi	sp,sp,64
    8000479a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000479c:	85d6                	mv	a1,s5
    8000479e:	8552                	mv	a0,s4
    800047a0:	2ec000ef          	jal	ra,80004a8c <pipeclose>
    800047a4:	b7dd                	j	8000478a <fileclose+0x8c>

00000000800047a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a6:	715d                	addi	sp,sp,-80
    800047a8:	e486                	sd	ra,72(sp)
    800047aa:	e0a2                	sd	s0,64(sp)
    800047ac:	fc26                	sd	s1,56(sp)
    800047ae:	f84a                	sd	s2,48(sp)
    800047b0:	f44e                	sd	s3,40(sp)
    800047b2:	0880                	addi	s0,sp,80
    800047b4:	84aa                	mv	s1,a0
    800047b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047b8:	a82fd0ef          	jal	ra,80001a3a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047bc:	409c                	lw	a5,0(s1)
    800047be:	37f9                	addiw	a5,a5,-2
    800047c0:	4705                	li	a4,1
    800047c2:	02f76f63          	bltu	a4,a5,80004800 <filestat+0x5a>
    800047c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800047c8:	6c88                	ld	a0,24(s1)
    800047ca:	948ff0ef          	jal	ra,80003912 <ilock>
    stati(f->ip, &st);
    800047ce:	fb840593          	addi	a1,s0,-72
    800047d2:	6c88                	ld	a0,24(s1)
    800047d4:	ca0ff0ef          	jal	ra,80003c74 <stati>
    iunlock(f->ip);
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	9e2ff0ef          	jal	ra,800039bc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047de:	46e1                	li	a3,24
    800047e0:	fb840613          	addi	a2,s0,-72
    800047e4:	85ce                	mv	a1,s3
    800047e6:	05093503          	ld	a0,80(s2)
    800047ea:	ef7fc0ef          	jal	ra,800016e0 <copyout>
    800047ee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047f2:	60a6                	ld	ra,72(sp)
    800047f4:	6406                	ld	s0,64(sp)
    800047f6:	74e2                	ld	s1,56(sp)
    800047f8:	7942                	ld	s2,48(sp)
    800047fa:	79a2                	ld	s3,40(sp)
    800047fc:	6161                	addi	sp,sp,80
    800047fe:	8082                	ret
  return -1;
    80004800:	557d                	li	a0,-1
    80004802:	bfc5                	j	800047f2 <filestat+0x4c>

0000000080004804 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004804:	7179                	addi	sp,sp,-48
    80004806:	f406                	sd	ra,40(sp)
    80004808:	f022                	sd	s0,32(sp)
    8000480a:	ec26                	sd	s1,24(sp)
    8000480c:	e84a                	sd	s2,16(sp)
    8000480e:	e44e                	sd	s3,8(sp)
    80004810:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004812:	00854783          	lbu	a5,8(a0)
    80004816:	cbc1                	beqz	a5,800048a6 <fileread+0xa2>
    80004818:	84aa                	mv	s1,a0
    8000481a:	89ae                	mv	s3,a1
    8000481c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000481e:	411c                	lw	a5,0(a0)
    80004820:	4705                	li	a4,1
    80004822:	04e78363          	beq	a5,a4,80004868 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004826:	470d                	li	a4,3
    80004828:	04e78563          	beq	a5,a4,80004872 <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000482c:	4709                	li	a4,2
    8000482e:	06e79663          	bne	a5,a4,8000489a <fileread+0x96>
    ilock(f->ip);
    80004832:	6d08                	ld	a0,24(a0)
    80004834:	8deff0ef          	jal	ra,80003912 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004838:	874a                	mv	a4,s2
    8000483a:	5094                	lw	a3,32(s1)
    8000483c:	864e                	mv	a2,s3
    8000483e:	4585                	li	a1,1
    80004840:	6c88                	ld	a0,24(s1)
    80004842:	c5cff0ef          	jal	ra,80003c9e <readi>
    80004846:	892a                	mv	s2,a0
    80004848:	00a05563          	blez	a0,80004852 <fileread+0x4e>
      f->off += r;
    8000484c:	509c                	lw	a5,32(s1)
    8000484e:	9fa9                	addw	a5,a5,a0
    80004850:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004852:	6c88                	ld	a0,24(s1)
    80004854:	968ff0ef          	jal	ra,800039bc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004858:	854a                	mv	a0,s2
    8000485a:	70a2                	ld	ra,40(sp)
    8000485c:	7402                	ld	s0,32(sp)
    8000485e:	64e2                	ld	s1,24(sp)
    80004860:	6942                	ld	s2,16(sp)
    80004862:	69a2                	ld	s3,8(sp)
    80004864:	6145                	addi	sp,sp,48
    80004866:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004868:	6908                	ld	a0,16(a0)
    8000486a:	34e000ef          	jal	ra,80004bb8 <piperead>
    8000486e:	892a                	mv	s2,a0
    80004870:	b7e5                	j	80004858 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004872:	02451783          	lh	a5,36(a0)
    80004876:	03079693          	slli	a3,a5,0x30
    8000487a:	92c1                	srli	a3,a3,0x30
    8000487c:	4725                	li	a4,9
    8000487e:	02d76663          	bltu	a4,a3,800048aa <fileread+0xa6>
    80004882:	0792                	slli	a5,a5,0x4
    80004884:	000a6717          	auipc	a4,0xa6
    80004888:	bdc70713          	addi	a4,a4,-1060 # 800aa460 <devsw>
    8000488c:	97ba                	add	a5,a5,a4
    8000488e:	639c                	ld	a5,0(a5)
    80004890:	cf99                	beqz	a5,800048ae <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);
    80004892:	4505                	li	a0,1
    80004894:	9782                	jalr	a5
    80004896:	892a                	mv	s2,a0
    80004898:	b7c1                	j	80004858 <fileread+0x54>
    panic("fileread");
    8000489a:	00003517          	auipc	a0,0x3
    8000489e:	ea650513          	addi	a0,a0,-346 # 80007740 <syscalls+0x2b8>
    800048a2:	ee9fb0ef          	jal	ra,8000078a <panic>
    return -1;
    800048a6:	597d                	li	s2,-1
    800048a8:	bf45                	j	80004858 <fileread+0x54>
      return -1;
    800048aa:	597d                	li	s2,-1
    800048ac:	b775                	j	80004858 <fileread+0x54>
    800048ae:	597d                	li	s2,-1
    800048b0:	b765                	j	80004858 <fileread+0x54>

00000000800048b2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048b2:	715d                	addi	sp,sp,-80
    800048b4:	e486                	sd	ra,72(sp)
    800048b6:	e0a2                	sd	s0,64(sp)
    800048b8:	fc26                	sd	s1,56(sp)
    800048ba:	f84a                	sd	s2,48(sp)
    800048bc:	f44e                	sd	s3,40(sp)
    800048be:	f052                	sd	s4,32(sp)
    800048c0:	ec56                	sd	s5,24(sp)
    800048c2:	e85a                	sd	s6,16(sp)
    800048c4:	e45e                	sd	s7,8(sp)
    800048c6:	e062                	sd	s8,0(sp)
    800048c8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048ca:	00954783          	lbu	a5,9(a0)
    800048ce:	0e078863          	beqz	a5,800049be <filewrite+0x10c>
    800048d2:	892a                	mv	s2,a0
    800048d4:	8aae                	mv	s5,a1
    800048d6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d8:	411c                	lw	a5,0(a0)
    800048da:	4705                	li	a4,1
    800048dc:	02e78263          	beq	a5,a4,80004900 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e0:	470d                	li	a4,3
    800048e2:	02e78463          	beq	a5,a4,8000490a <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e6:	4709                	li	a4,2
    800048e8:	0ce79563          	bne	a5,a4,800049b2 <filewrite+0x100>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ec:	0ac05163          	blez	a2,8000498e <filewrite+0xdc>
    int i = 0;
    800048f0:	4981                	li	s3,0
    800048f2:	6b05                	lui	s6,0x1
    800048f4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048f8:	6b85                	lui	s7,0x1
    800048fa:	c00b8b9b          	addiw	s7,s7,-1024
    800048fe:	a041                	j	8000497e <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);
    80004900:	6908                	ld	a0,16(a0)
    80004902:	1e2000ef          	jal	ra,80004ae4 <pipewrite>
    80004906:	8a2a                	mv	s4,a0
    80004908:	a071                	j	80004994 <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000490a:	02451783          	lh	a5,36(a0)
    8000490e:	03079693          	slli	a3,a5,0x30
    80004912:	92c1                	srli	a3,a3,0x30
    80004914:	4725                	li	a4,9
    80004916:	0ad76663          	bltu	a4,a3,800049c2 <filewrite+0x110>
    8000491a:	0792                	slli	a5,a5,0x4
    8000491c:	000a6717          	auipc	a4,0xa6
    80004920:	b4470713          	addi	a4,a4,-1212 # 800aa460 <devsw>
    80004924:	97ba                	add	a5,a5,a4
    80004926:	679c                	ld	a5,8(a5)
    80004928:	cfd9                	beqz	a5,800049c6 <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);
    8000492a:	4505                	li	a0,1
    8000492c:	9782                	jalr	a5
    8000492e:	8a2a                	mv	s4,a0
    80004930:	a095                	j	80004994 <filewrite+0xe2>
    80004932:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004936:	9bbff0ef          	jal	ra,800042f0 <begin_op>
      ilock(f->ip);
    8000493a:	01893503          	ld	a0,24(s2)
    8000493e:	fd5fe0ef          	jal	ra,80003912 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004942:	8762                	mv	a4,s8
    80004944:	02092683          	lw	a3,32(s2)
    80004948:	01598633          	add	a2,s3,s5
    8000494c:	4585                	li	a1,1
    8000494e:	01893503          	ld	a0,24(s2)
    80004952:	c30ff0ef          	jal	ra,80003d82 <writei>
    80004956:	84aa                	mv	s1,a0
    80004958:	00a05763          	blez	a0,80004966 <filewrite+0xb4>
        f->off += r;
    8000495c:	02092783          	lw	a5,32(s2)
    80004960:	9fa9                	addw	a5,a5,a0
    80004962:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004966:	01893503          	ld	a0,24(s2)
    8000496a:	852ff0ef          	jal	ra,800039bc <iunlock>
      end_op();
    8000496e:	9f3ff0ef          	jal	ra,80004360 <end_op>

      if(r != n1){
    80004972:	009c1f63          	bne	s8,s1,80004990 <filewrite+0xde>
        // error from writei
        break;
      }
      i += r;
    80004976:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000497a:	0149db63          	bge	s3,s4,80004990 <filewrite+0xde>
      int n1 = n - i;
    8000497e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004982:	84be                	mv	s1,a5
    80004984:	2781                	sext.w	a5,a5
    80004986:	fafb56e3          	bge	s6,a5,80004932 <filewrite+0x80>
    8000498a:	84de                	mv	s1,s7
    8000498c:	b75d                	j	80004932 <filewrite+0x80>
    int i = 0;
    8000498e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004990:	013a1f63          	bne	s4,s3,800049ae <filewrite+0xfc>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004994:	8552                	mv	a0,s4
    80004996:	60a6                	ld	ra,72(sp)
    80004998:	6406                	ld	s0,64(sp)
    8000499a:	74e2                	ld	s1,56(sp)
    8000499c:	7942                	ld	s2,48(sp)
    8000499e:	79a2                	ld	s3,40(sp)
    800049a0:	7a02                	ld	s4,32(sp)
    800049a2:	6ae2                	ld	s5,24(sp)
    800049a4:	6b42                	ld	s6,16(sp)
    800049a6:	6ba2                	ld	s7,8(sp)
    800049a8:	6c02                	ld	s8,0(sp)
    800049aa:	6161                	addi	sp,sp,80
    800049ac:	8082                	ret
    ret = (i == n ? n : -1);
    800049ae:	5a7d                	li	s4,-1
    800049b0:	b7d5                	j	80004994 <filewrite+0xe2>
    panic("filewrite");
    800049b2:	00003517          	auipc	a0,0x3
    800049b6:	d9e50513          	addi	a0,a0,-610 # 80007750 <syscalls+0x2c8>
    800049ba:	dd1fb0ef          	jal	ra,8000078a <panic>
    return -1;
    800049be:	5a7d                	li	s4,-1
    800049c0:	bfd1                	j	80004994 <filewrite+0xe2>
      return -1;
    800049c2:	5a7d                	li	s4,-1
    800049c4:	bfc1                	j	80004994 <filewrite+0xe2>
    800049c6:	5a7d                	li	s4,-1
    800049c8:	b7f1                	j	80004994 <filewrite+0xe2>

00000000800049ca <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049ca:	7179                	addi	sp,sp,-48
    800049cc:	f406                	sd	ra,40(sp)
    800049ce:	f022                	sd	s0,32(sp)
    800049d0:	ec26                	sd	s1,24(sp)
    800049d2:	e84a                	sd	s2,16(sp)
    800049d4:	e44e                	sd	s3,8(sp)
    800049d6:	e052                	sd	s4,0(sp)
    800049d8:	1800                	addi	s0,sp,48
    800049da:	84aa                	mv	s1,a0
    800049dc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049de:	0005b023          	sd	zero,0(a1)
    800049e2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049e6:	c75ff0ef          	jal	ra,8000465a <filealloc>
    800049ea:	e088                	sd	a0,0(s1)
    800049ec:	cd35                	beqz	a0,80004a68 <pipealloc+0x9e>
    800049ee:	c6dff0ef          	jal	ra,8000465a <filealloc>
    800049f2:	00aa3023          	sd	a0,0(s4)
    800049f6:	c52d                	beqz	a0,80004a60 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049f8:	906fc0ef          	jal	ra,80000afe <kalloc>
    800049fc:	892a                	mv	s2,a0
    800049fe:	cd31                	beqz	a0,80004a5a <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    80004a00:	4985                	li	s3,1
    80004a02:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a06:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a0a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a0e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a12:	00003597          	auipc	a1,0x3
    80004a16:	d4e58593          	addi	a1,a1,-690 # 80007760 <syscalls+0x2d8>
    80004a1a:	a38fc0ef          	jal	ra,80000c52 <initlock>
  (*f0)->type = FD_PIPE;
    80004a1e:	609c                	ld	a5,0(s1)
    80004a20:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a24:	609c                	ld	a5,0(s1)
    80004a26:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a2a:	609c                	ld	a5,0(s1)
    80004a2c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a30:	609c                	ld	a5,0(s1)
    80004a32:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a36:	000a3783          	ld	a5,0(s4)
    80004a3a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a3e:	000a3783          	ld	a5,0(s4)
    80004a42:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a46:	000a3783          	ld	a5,0(s4)
    80004a4a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a4e:	000a3783          	ld	a5,0(s4)
    80004a52:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a56:	4501                	li	a0,0
    80004a58:	a005                	j	80004a78 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a5a:	6088                	ld	a0,0(s1)
    80004a5c:	e501                	bnez	a0,80004a64 <pipealloc+0x9a>
    80004a5e:	a029                	j	80004a68 <pipealloc+0x9e>
    80004a60:	6088                	ld	a0,0(s1)
    80004a62:	c11d                	beqz	a0,80004a88 <pipealloc+0xbe>
    fileclose(*f0);
    80004a64:	c9bff0ef          	jal	ra,800046fe <fileclose>
  if(*f1)
    80004a68:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a6c:	557d                	li	a0,-1
  if(*f1)
    80004a6e:	c789                	beqz	a5,80004a78 <pipealloc+0xae>
    fileclose(*f1);
    80004a70:	853e                	mv	a0,a5
    80004a72:	c8dff0ef          	jal	ra,800046fe <fileclose>
  return -1;
    80004a76:	557d                	li	a0,-1
}
    80004a78:	70a2                	ld	ra,40(sp)
    80004a7a:	7402                	ld	s0,32(sp)
    80004a7c:	64e2                	ld	s1,24(sp)
    80004a7e:	6942                	ld	s2,16(sp)
    80004a80:	69a2                	ld	s3,8(sp)
    80004a82:	6a02                	ld	s4,0(sp)
    80004a84:	6145                	addi	sp,sp,48
    80004a86:	8082                	ret
  return -1;
    80004a88:	557d                	li	a0,-1
    80004a8a:	b7fd                	j	80004a78 <pipealloc+0xae>

0000000080004a8c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a8c:	1101                	addi	sp,sp,-32
    80004a8e:	ec06                	sd	ra,24(sp)
    80004a90:	e822                	sd	s0,16(sp)
    80004a92:	e426                	sd	s1,8(sp)
    80004a94:	e04a                	sd	s2,0(sp)
    80004a96:	1000                	addi	s0,sp,32
    80004a98:	84aa                	mv	s1,a0
    80004a9a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a9c:	a36fc0ef          	jal	ra,80000cd2 <acquire>
  if(writable){
    80004aa0:	02090763          	beqz	s2,80004ace <pipeclose+0x42>
    pi->writeopen = 0;
    80004aa4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aa8:	21848513          	addi	a0,s1,536
    80004aac:	f24fd0ef          	jal	ra,800021d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ab0:	2204b783          	ld	a5,544(s1)
    80004ab4:	e785                	bnez	a5,80004adc <pipeclose+0x50>
    release(&pi->lock);
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ab2fc0ef          	jal	ra,80000d6a <release>
    kfree((char*)pi);
    80004abc:	8526                	mv	a0,s1
    80004abe:	efffb0ef          	jal	ra,800009bc <kfree>
  } else
    release(&pi->lock);
}
    80004ac2:	60e2                	ld	ra,24(sp)
    80004ac4:	6442                	ld	s0,16(sp)
    80004ac6:	64a2                	ld	s1,8(sp)
    80004ac8:	6902                	ld	s2,0(sp)
    80004aca:	6105                	addi	sp,sp,32
    80004acc:	8082                	ret
    pi->readopen = 0;
    80004ace:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ad2:	21c48513          	addi	a0,s1,540
    80004ad6:	efafd0ef          	jal	ra,800021d0 <wakeup>
    80004ada:	bfd9                	j	80004ab0 <pipeclose+0x24>
    release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	a8cfc0ef          	jal	ra,80000d6a <release>
}
    80004ae2:	b7c5                	j	80004ac2 <pipeclose+0x36>

0000000080004ae4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae4:	711d                	addi	sp,sp,-96
    80004ae6:	ec86                	sd	ra,88(sp)
    80004ae8:	e8a2                	sd	s0,80(sp)
    80004aea:	e4a6                	sd	s1,72(sp)
    80004aec:	e0ca                	sd	s2,64(sp)
    80004aee:	fc4e                	sd	s3,56(sp)
    80004af0:	f852                	sd	s4,48(sp)
    80004af2:	f456                	sd	s5,40(sp)
    80004af4:	f05a                	sd	s6,32(sp)
    80004af6:	ec5e                	sd	s7,24(sp)
    80004af8:	e862                	sd	s8,16(sp)
    80004afa:	1080                	addi	s0,sp,96
    80004afc:	84aa                	mv	s1,a0
    80004afe:	8aae                	mv	s5,a1
    80004b00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b02:	f39fc0ef          	jal	ra,80001a3a <myproc>
    80004b06:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	9c8fc0ef          	jal	ra,80000cd2 <acquire>
  while(i < n){
    80004b0e:	09405c63          	blez	s4,80004ba6 <pipewrite+0xc2>
  int i = 0;
    80004b12:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b14:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b16:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b1a:	21c48b93          	addi	s7,s1,540
    80004b1e:	a81d                	j	80004b54 <pipewrite+0x70>
      release(&pi->lock);
    80004b20:	8526                	mv	a0,s1
    80004b22:	a48fc0ef          	jal	ra,80000d6a <release>
      return -1;
    80004b26:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b28:	854a                	mv	a0,s2
    80004b2a:	60e6                	ld	ra,88(sp)
    80004b2c:	6446                	ld	s0,80(sp)
    80004b2e:	64a6                	ld	s1,72(sp)
    80004b30:	6906                	ld	s2,64(sp)
    80004b32:	79e2                	ld	s3,56(sp)
    80004b34:	7a42                	ld	s4,48(sp)
    80004b36:	7aa2                	ld	s5,40(sp)
    80004b38:	7b02                	ld	s6,32(sp)
    80004b3a:	6be2                	ld	s7,24(sp)
    80004b3c:	6c42                	ld	s8,16(sp)
    80004b3e:	6125                	addi	sp,sp,96
    80004b40:	8082                	ret
      wakeup(&pi->nread);
    80004b42:	8562                	mv	a0,s8
    80004b44:	e8cfd0ef          	jal	ra,800021d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b48:	85a6                	mv	a1,s1
    80004b4a:	855e                	mv	a0,s7
    80004b4c:	e38fd0ef          	jal	ra,80002184 <sleep>
  while(i < n){
    80004b50:	05495c63          	bge	s2,s4,80004ba8 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    80004b54:	2204a783          	lw	a5,544(s1)
    80004b58:	d7e1                	beqz	a5,80004b20 <pipewrite+0x3c>
    80004b5a:	854e                	mv	a0,s3
    80004b5c:	861fd0ef          	jal	ra,800023bc <killed>
    80004b60:	f161                	bnez	a0,80004b20 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b62:	2184a783          	lw	a5,536(s1)
    80004b66:	21c4a703          	lw	a4,540(s1)
    80004b6a:	2007879b          	addiw	a5,a5,512
    80004b6e:	fcf70ae3          	beq	a4,a5,80004b42 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b72:	4685                	li	a3,1
    80004b74:	01590633          	add	a2,s2,s5
    80004b78:	faf40593          	addi	a1,s0,-81
    80004b7c:	0509b503          	ld	a0,80(s3)
    80004b80:	c43fc0ef          	jal	ra,800017c2 <copyin>
    80004b84:	03650263          	beq	a0,s6,80004ba8 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b88:	21c4a783          	lw	a5,540(s1)
    80004b8c:	0017871b          	addiw	a4,a5,1
    80004b90:	20e4ae23          	sw	a4,540(s1)
    80004b94:	1ff7f793          	andi	a5,a5,511
    80004b98:	97a6                	add	a5,a5,s1
    80004b9a:	faf44703          	lbu	a4,-81(s0)
    80004b9e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ba2:	2905                	addiw	s2,s2,1
    80004ba4:	b775                	j	80004b50 <pipewrite+0x6c>
  int i = 0;
    80004ba6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ba8:	21848513          	addi	a0,s1,536
    80004bac:	e24fd0ef          	jal	ra,800021d0 <wakeup>
  release(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	9b8fc0ef          	jal	ra,80000d6a <release>
  return i;
    80004bb6:	bf8d                	j	80004b28 <pipewrite+0x44>

0000000080004bb8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb8:	715d                	addi	sp,sp,-80
    80004bba:	e486                	sd	ra,72(sp)
    80004bbc:	e0a2                	sd	s0,64(sp)
    80004bbe:	fc26                	sd	s1,56(sp)
    80004bc0:	f84a                	sd	s2,48(sp)
    80004bc2:	f44e                	sd	s3,40(sp)
    80004bc4:	f052                	sd	s4,32(sp)
    80004bc6:	ec56                	sd	s5,24(sp)
    80004bc8:	e85a                	sd	s6,16(sp)
    80004bca:	0880                	addi	s0,sp,80
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	892e                	mv	s2,a1
    80004bd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd2:	e69fc0ef          	jal	ra,80001a3a <myproc>
    80004bd6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	8f8fc0ef          	jal	ra,80000cd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bde:	2184a703          	lw	a4,536(s1)
    80004be2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bea:	02f71363          	bne	a4,a5,80004c10 <piperead+0x58>
    80004bee:	2244a783          	lw	a5,548(s1)
    80004bf2:	cf99                	beqz	a5,80004c10 <piperead+0x58>
    if(killed(pr)){
    80004bf4:	8552                	mv	a0,s4
    80004bf6:	fc6fd0ef          	jal	ra,800023bc <killed>
    80004bfa:	e149                	bnez	a0,80004c7c <piperead+0xc4>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfc:	85a6                	mv	a1,s1
    80004bfe:	854e                	mv	a0,s3
    80004c00:	d84fd0ef          	jal	ra,80002184 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	2184a703          	lw	a4,536(s1)
    80004c08:	21c4a783          	lw	a5,540(s1)
    80004c0c:	fef701e3          	beq	a4,a5,80004bee <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004c12:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c14:	05505263          	blez	s5,80004c58 <piperead+0xa0>
    if(pi->nread == pi->nwrite)
    80004c18:	2184a783          	lw	a5,536(s1)
    80004c1c:	21c4a703          	lw	a4,540(s1)
    80004c20:	02f70c63          	beq	a4,a5,80004c58 <piperead+0xa0>
    ch = pi->data[pi->nread % PIPESIZE];
    80004c24:	1ff7f793          	andi	a5,a5,511
    80004c28:	97a6                	add	a5,a5,s1
    80004c2a:	0187c783          	lbu	a5,24(a5)
    80004c2e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004c32:	4685                	li	a3,1
    80004c34:	fbf40613          	addi	a2,s0,-65
    80004c38:	85ca                	mv	a1,s2
    80004c3a:	050a3503          	ld	a0,80(s4)
    80004c3e:	aa3fc0ef          	jal	ra,800016e0 <copyout>
    80004c42:	05650263          	beq	a0,s6,80004c86 <piperead+0xce>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004c46:	2184a783          	lw	a5,536(s1)
    80004c4a:	2785                	addiw	a5,a5,1
    80004c4c:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c50:	2985                	addiw	s3,s3,1
    80004c52:	0905                	addi	s2,s2,1
    80004c54:	fd3a92e3          	bne	s5,s3,80004c18 <piperead+0x60>
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c58:	21c48513          	addi	a0,s1,540
    80004c5c:	d74fd0ef          	jal	ra,800021d0 <wakeup>
  release(&pi->lock);
    80004c60:	8526                	mv	a0,s1
    80004c62:	908fc0ef          	jal	ra,80000d6a <release>
  return i;
}
    80004c66:	854e                	mv	a0,s3
    80004c68:	60a6                	ld	ra,72(sp)
    80004c6a:	6406                	ld	s0,64(sp)
    80004c6c:	74e2                	ld	s1,56(sp)
    80004c6e:	7942                	ld	s2,48(sp)
    80004c70:	79a2                	ld	s3,40(sp)
    80004c72:	7a02                	ld	s4,32(sp)
    80004c74:	6ae2                	ld	s5,24(sp)
    80004c76:	6b42                	ld	s6,16(sp)
    80004c78:	6161                	addi	sp,sp,80
    80004c7a:	8082                	ret
      release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	8ecfc0ef          	jal	ra,80000d6a <release>
      return -1;
    80004c82:	59fd                	li	s3,-1
    80004c84:	b7cd                	j	80004c66 <piperead+0xae>
      if(i == 0)
    80004c86:	fc0999e3          	bnez	s3,80004c58 <piperead+0xa0>
        i = -1;
    80004c8a:	89aa                	mv	s3,a0
    80004c8c:	b7f1                	j	80004c58 <piperead+0xa0>

0000000080004c8e <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004c8e:	1141                	addi	sp,sp,-16
    80004c90:	e422                	sd	s0,8(sp)
    80004c92:	0800                	addi	s0,sp,16
    80004c94:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c96:	8905                	andi	a0,a0,1
    80004c98:	c111                	beqz	a0,80004c9c <flags2perm+0xe>
      perm = PTE_X;
    80004c9a:	4521                	li	a0,8
    if(flags & 0x2)
    80004c9c:	8b89                	andi	a5,a5,2
    80004c9e:	c399                	beqz	a5,80004ca4 <flags2perm+0x16>
      perm |= PTE_W;
    80004ca0:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ca4:	6422                	ld	s0,8(sp)
    80004ca6:	0141                	addi	sp,sp,16
    80004ca8:	8082                	ret

0000000080004caa <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004caa:	de010113          	addi	sp,sp,-544
    80004cae:	20113c23          	sd	ra,536(sp)
    80004cb2:	20813823          	sd	s0,528(sp)
    80004cb6:	20913423          	sd	s1,520(sp)
    80004cba:	21213023          	sd	s2,512(sp)
    80004cbe:	ffce                	sd	s3,504(sp)
    80004cc0:	fbd2                	sd	s4,496(sp)
    80004cc2:	f7d6                	sd	s5,488(sp)
    80004cc4:	f3da                	sd	s6,480(sp)
    80004cc6:	efde                	sd	s7,472(sp)
    80004cc8:	ebe2                	sd	s8,464(sp)
    80004cca:	e7e6                	sd	s9,456(sp)
    80004ccc:	e3ea                	sd	s10,448(sp)
    80004cce:	ff6e                	sd	s11,440(sp)
    80004cd0:	1400                	addi	s0,sp,544
    80004cd2:	892a                	mv	s2,a0
    80004cd4:	dea43423          	sd	a0,-536(s0)
    80004cd8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cdc:	d5ffc0ef          	jal	ra,80001a3a <myproc>
    80004ce0:	84aa                	mv	s1,a0

  begin_op();
    80004ce2:	e0eff0ef          	jal	ra,800042f0 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004ce6:	854a                	mv	a0,s2
    80004ce8:	c18ff0ef          	jal	ra,80004100 <namei>
    80004cec:	c13d                	beqz	a0,80004d52 <kexec+0xa8>
    80004cee:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf0:	c23fe0ef          	jal	ra,80003912 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cf4:	04000713          	li	a4,64
    80004cf8:	4681                	li	a3,0
    80004cfa:	e5040613          	addi	a2,s0,-432
    80004cfe:	4581                	li	a1,0
    80004d00:	8556                	mv	a0,s5
    80004d02:	f9dfe0ef          	jal	ra,80003c9e <readi>
    80004d06:	04000793          	li	a5,64
    80004d0a:	00f51a63          	bne	a0,a5,80004d1e <kexec+0x74>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004d0e:	e5042703          	lw	a4,-432(s0)
    80004d12:	464c47b7          	lui	a5,0x464c4
    80004d16:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d1a:	04f70063          	beq	a4,a5,80004d5a <kexec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d1e:	8556                	mv	a0,s5
    80004d20:	df9fe0ef          	jal	ra,80003b18 <iunlockput>
    end_op();
    80004d24:	e3cff0ef          	jal	ra,80004360 <end_op>
  }
  return -1;
    80004d28:	557d                	li	a0,-1
}
    80004d2a:	21813083          	ld	ra,536(sp)
    80004d2e:	21013403          	ld	s0,528(sp)
    80004d32:	20813483          	ld	s1,520(sp)
    80004d36:	20013903          	ld	s2,512(sp)
    80004d3a:	79fe                	ld	s3,504(sp)
    80004d3c:	7a5e                	ld	s4,496(sp)
    80004d3e:	7abe                	ld	s5,488(sp)
    80004d40:	7b1e                	ld	s6,480(sp)
    80004d42:	6bfe                	ld	s7,472(sp)
    80004d44:	6c5e                	ld	s8,464(sp)
    80004d46:	6cbe                	ld	s9,456(sp)
    80004d48:	6d1e                	ld	s10,448(sp)
    80004d4a:	7dfa                	ld	s11,440(sp)
    80004d4c:	22010113          	addi	sp,sp,544
    80004d50:	8082                	ret
    end_op();
    80004d52:	e0eff0ef          	jal	ra,80004360 <end_op>
    return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	bfc9                	j	80004d2a <kexec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	de7fc0ef          	jal	ra,80001b42 <proc_pagetable>
    80004d60:	8b2a                	mv	s6,a0
    80004d62:	dd55                	beqz	a0,80004d1e <kexec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d64:	e7042783          	lw	a5,-400(s0)
    80004d68:	e8845703          	lhu	a4,-376(s0)
    80004d6c:	c325                	beqz	a4,80004dcc <kexec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d6e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d70:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d74:	6a05                	lui	s4,0x1
    80004d76:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d7a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d7e:	6d85                	lui	s11,0x1
    80004d80:	7d7d                	lui	s10,0xfffff
    80004d82:	a411                	j	80004f86 <kexec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d84:	00003517          	auipc	a0,0x3
    80004d88:	9e450513          	addi	a0,a0,-1564 # 80007768 <syscalls+0x2e0>
    80004d8c:	9fffb0ef          	jal	ra,8000078a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d90:	874a                	mv	a4,s2
    80004d92:	009c86bb          	addw	a3,s9,s1
    80004d96:	4581                	li	a1,0
    80004d98:	8556                	mv	a0,s5
    80004d9a:	f05fe0ef          	jal	ra,80003c9e <readi>
    80004d9e:	2501                	sext.w	a0,a0
    80004da0:	18a91263          	bne	s2,a0,80004f24 <kexec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004da4:	009d84bb          	addw	s1,s11,s1
    80004da8:	013d09bb          	addw	s3,s10,s3
    80004dac:	1b74fd63          	bgeu	s1,s7,80004f66 <kexec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    80004db0:	02049593          	slli	a1,s1,0x20
    80004db4:	9181                	srli	a1,a1,0x20
    80004db6:	95e2                	add	a1,a1,s8
    80004db8:	855a                	mv	a0,s6
    80004dba:	b02fc0ef          	jal	ra,800010bc <walkaddr>
    80004dbe:	862a                	mv	a2,a0
    if(pa == 0)
    80004dc0:	d171                	beqz	a0,80004d84 <kexec+0xda>
      n = PGSIZE;
    80004dc2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dc4:	fd49f6e3          	bgeu	s3,s4,80004d90 <kexec+0xe6>
      n = sz - i;
    80004dc8:	894e                	mv	s2,s3
    80004dca:	b7d9                	j	80004d90 <kexec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dcc:	4901                	li	s2,0
  iunlockput(ip);
    80004dce:	8556                	mv	a0,s5
    80004dd0:	d49fe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    80004dd4:	d8cff0ef          	jal	ra,80004360 <end_op>
  p = myproc();
    80004dd8:	c63fc0ef          	jal	ra,80001a3a <myproc>
    80004ddc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dde:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de2:	6785                	lui	a5,0x1
    80004de4:	17fd                	addi	a5,a5,-1
    80004de6:	993e                	add	s2,s2,a5
    80004de8:	77fd                	lui	a5,0xfffff
    80004dea:	00f977b3          	and	a5,s2,a5
    80004dee:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004df2:	4691                	li	a3,4
    80004df4:	6609                	lui	a2,0x2
    80004df6:	963e                	add	a2,a2,a5
    80004df8:	85be                	mv	a1,a5
    80004dfa:	855a                	mv	a0,s6
    80004dfc:	d8afc0ef          	jal	ra,80001386 <uvmalloc>
    80004e00:	8c2a                	mv	s8,a0
  ip = 0;
    80004e02:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004e04:	12050063          	beqz	a0,80004f24 <kexec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004e08:	75f9                	lui	a1,0xffffe
    80004e0a:	95aa                	add	a1,a1,a0
    80004e0c:	855a                	mv	a0,s6
    80004e0e:	f2cfc0ef          	jal	ra,8000153a <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004e12:	7afd                	lui	s5,0xfffff
    80004e14:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e16:	df043783          	ld	a5,-528(s0)
    80004e1a:	6388                	ld	a0,0(a5)
    80004e1c:	c135                	beqz	a0,80004e80 <kexec+0x1d6>
    80004e1e:	e9040993          	addi	s3,s0,-368
    80004e22:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e26:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e28:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e2a:	8f4fc0ef          	jal	ra,80000f1e <strlen>
    80004e2e:	0015079b          	addiw	a5,a0,1
    80004e32:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e36:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e3a:	11596a63          	bltu	s2,s5,80004f4e <kexec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e3e:	df043d83          	ld	s11,-528(s0)
    80004e42:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e46:	8552                	mv	a0,s4
    80004e48:	8d6fc0ef          	jal	ra,80000f1e <strlen>
    80004e4c:	0015069b          	addiw	a3,a0,1
    80004e50:	8652                	mv	a2,s4
    80004e52:	85ca                	mv	a1,s2
    80004e54:	855a                	mv	a0,s6
    80004e56:	88bfc0ef          	jal	ra,800016e0 <copyout>
    80004e5a:	0e054e63          	bltz	a0,80004f56 <kexec+0x2ac>
    ustack[argc] = sp;
    80004e5e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e62:	0485                	addi	s1,s1,1
    80004e64:	008d8793          	addi	a5,s11,8
    80004e68:	def43823          	sd	a5,-528(s0)
    80004e6c:	008db503          	ld	a0,8(s11)
    80004e70:	c911                	beqz	a0,80004e84 <kexec+0x1da>
    if(argc >= MAXARG)
    80004e72:	09a1                	addi	s3,s3,8
    80004e74:	fb3c9be3          	bne	s9,s3,80004e2a <kexec+0x180>
  sz = sz1;
    80004e78:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e7c:	4a81                	li	s5,0
    80004e7e:	a05d                	j	80004f24 <kexec+0x27a>
  sp = sz;
    80004e80:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e82:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e84:	00349793          	slli	a5,s1,0x3
    80004e88:	f9040713          	addi	a4,s0,-112
    80004e8c:	97ba                	add	a5,a5,a4
    80004e8e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ff53908>
  sp -= (argc+1) * sizeof(uint64);
    80004e92:	00148693          	addi	a3,s1,1
    80004e96:	068e                	slli	a3,a3,0x3
    80004e98:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e9c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ea0:	01597663          	bgeu	s2,s5,80004eac <kexec+0x202>
  sz = sz1;
    80004ea4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ea8:	4a81                	li	s5,0
    80004eaa:	a8ad                	j	80004f24 <kexec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eac:	e9040613          	addi	a2,s0,-368
    80004eb0:	85ca                	mv	a1,s2
    80004eb2:	855a                	mv	a0,s6
    80004eb4:	82dfc0ef          	jal	ra,800016e0 <copyout>
    80004eb8:	0a054363          	bltz	a0,80004f5e <kexec+0x2b4>
  p->trapframe->a1 = sp;
    80004ebc:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004ec0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec4:	de843783          	ld	a5,-536(s0)
    80004ec8:	0007c703          	lbu	a4,0(a5)
    80004ecc:	cf11                	beqz	a4,80004ee8 <kexec+0x23e>
    80004ece:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ed0:	02f00693          	li	a3,47
    80004ed4:	a039                	j	80004ee2 <kexec+0x238>
      last = s+1;
    80004ed6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004eda:	0785                	addi	a5,a5,1
    80004edc:	fff7c703          	lbu	a4,-1(a5)
    80004ee0:	c701                	beqz	a4,80004ee8 <kexec+0x23e>
    if(*s == '/')
    80004ee2:	fed71ce3          	bne	a4,a3,80004eda <kexec+0x230>
    80004ee6:	bfc5                	j	80004ed6 <kexec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ee8:	4641                	li	a2,16
    80004eea:	de843583          	ld	a1,-536(s0)
    80004eee:	158b8513          	addi	a0,s7,344
    80004ef2:	ffbfb0ef          	jal	ra,80000eec <safestrcpy>
  oldpagetable = p->pagetable;
    80004ef6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004efa:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004efe:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004f02:	058bb783          	ld	a5,88(s7)
    80004f06:	e6843703          	ld	a4,-408(s0)
    80004f0a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f0c:	058bb783          	ld	a5,88(s7)
    80004f10:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f14:	85ea                	mv	a1,s10
    80004f16:	cb1fc0ef          	jal	ra,80001bc6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f1a:	0004851b          	sext.w	a0,s1
    80004f1e:	b531                	j	80004d2a <kexec+0x80>
    80004f20:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f24:	df843583          	ld	a1,-520(s0)
    80004f28:	855a                	mv	a0,s6
    80004f2a:	c9dfc0ef          	jal	ra,80001bc6 <proc_freepagetable>
  if(ip){
    80004f2e:	de0a98e3          	bnez	s5,80004d1e <kexec+0x74>
  return -1;
    80004f32:	557d                	li	a0,-1
    80004f34:	bbdd                	j	80004d2a <kexec+0x80>
    80004f36:	df243c23          	sd	s2,-520(s0)
    80004f3a:	b7ed                	j	80004f24 <kexec+0x27a>
    80004f3c:	df243c23          	sd	s2,-520(s0)
    80004f40:	b7d5                	j	80004f24 <kexec+0x27a>
    80004f42:	df243c23          	sd	s2,-520(s0)
    80004f46:	bff9                	j	80004f24 <kexec+0x27a>
    80004f48:	df243c23          	sd	s2,-520(s0)
    80004f4c:	bfe1                	j	80004f24 <kexec+0x27a>
  sz = sz1;
    80004f4e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f52:	4a81                	li	s5,0
    80004f54:	bfc1                	j	80004f24 <kexec+0x27a>
  sz = sz1;
    80004f56:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f5a:	4a81                	li	s5,0
    80004f5c:	b7e1                	j	80004f24 <kexec+0x27a>
  sz = sz1;
    80004f5e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f62:	4a81                	li	s5,0
    80004f64:	b7c1                	j	80004f24 <kexec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f66:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6a:	e0843783          	ld	a5,-504(s0)
    80004f6e:	0017869b          	addiw	a3,a5,1
    80004f72:	e0d43423          	sd	a3,-504(s0)
    80004f76:	e0043783          	ld	a5,-512(s0)
    80004f7a:	0387879b          	addiw	a5,a5,56
    80004f7e:	e8845703          	lhu	a4,-376(s0)
    80004f82:	e4e6d6e3          	bge	a3,a4,80004dce <kexec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f86:	2781                	sext.w	a5,a5
    80004f88:	e0f43023          	sd	a5,-512(s0)
    80004f8c:	03800713          	li	a4,56
    80004f90:	86be                	mv	a3,a5
    80004f92:	e1840613          	addi	a2,s0,-488
    80004f96:	4581                	li	a1,0
    80004f98:	8556                	mv	a0,s5
    80004f9a:	d05fe0ef          	jal	ra,80003c9e <readi>
    80004f9e:	03800793          	li	a5,56
    80004fa2:	f6f51fe3          	bne	a0,a5,80004f20 <kexec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004fa6:	e1842783          	lw	a5,-488(s0)
    80004faa:	4705                	li	a4,1
    80004fac:	fae79fe3          	bne	a5,a4,80004f6a <kexec+0x2c0>
    if(ph.memsz < ph.filesz)
    80004fb0:	e4043483          	ld	s1,-448(s0)
    80004fb4:	e3843783          	ld	a5,-456(s0)
    80004fb8:	f6f4efe3          	bltu	s1,a5,80004f36 <kexec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fbc:	e2843783          	ld	a5,-472(s0)
    80004fc0:	94be                	add	s1,s1,a5
    80004fc2:	f6f4ede3          	bltu	s1,a5,80004f3c <kexec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    80004fc6:	de043703          	ld	a4,-544(s0)
    80004fca:	8ff9                	and	a5,a5,a4
    80004fcc:	fbbd                	bnez	a5,80004f42 <kexec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fce:	e1c42503          	lw	a0,-484(s0)
    80004fd2:	cbdff0ef          	jal	ra,80004c8e <flags2perm>
    80004fd6:	86aa                	mv	a3,a0
    80004fd8:	8626                	mv	a2,s1
    80004fda:	85ca                	mv	a1,s2
    80004fdc:	855a                	mv	a0,s6
    80004fde:	ba8fc0ef          	jal	ra,80001386 <uvmalloc>
    80004fe2:	dea43c23          	sd	a0,-520(s0)
    80004fe6:	d12d                	beqz	a0,80004f48 <kexec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fe8:	e2843c03          	ld	s8,-472(s0)
    80004fec:	e2042c83          	lw	s9,-480(s0)
    80004ff0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ff4:	f60b89e3          	beqz	s7,80004f66 <kexec+0x2bc>
    80004ff8:	89de                	mv	s3,s7
    80004ffa:	4481                	li	s1,0
    80004ffc:	bb55                	j	80004db0 <kexec+0x106>

0000000080004ffe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ffe:	7179                	addi	sp,sp,-48
    80005000:	f406                	sd	ra,40(sp)
    80005002:	f022                	sd	s0,32(sp)
    80005004:	ec26                	sd	s1,24(sp)
    80005006:	e84a                	sd	s2,16(sp)
    80005008:	1800                	addi	s0,sp,48
    8000500a:	892e                	mv	s2,a1
    8000500c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000500e:	fdc40593          	addi	a1,s0,-36
    80005012:	f19fd0ef          	jal	ra,80002f2a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005016:	fdc42703          	lw	a4,-36(s0)
    8000501a:	47bd                	li	a5,15
    8000501c:	02e7e963          	bltu	a5,a4,8000504e <argfd+0x50>
    80005020:	a1bfc0ef          	jal	ra,80001a3a <myproc>
    80005024:	fdc42703          	lw	a4,-36(s0)
    80005028:	01a70793          	addi	a5,a4,26
    8000502c:	078e                	slli	a5,a5,0x3
    8000502e:	953e                	add	a0,a0,a5
    80005030:	611c                	ld	a5,0(a0)
    80005032:	c385                	beqz	a5,80005052 <argfd+0x54>
    return -1;
  if(pfd)
    80005034:	00090463          	beqz	s2,8000503c <argfd+0x3e>
    *pfd = fd;
    80005038:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000503c:	4501                	li	a0,0
  if(pf)
    8000503e:	c091                	beqz	s1,80005042 <argfd+0x44>
    *pf = f;
    80005040:	e09c                	sd	a5,0(s1)
}
    80005042:	70a2                	ld	ra,40(sp)
    80005044:	7402                	ld	s0,32(sp)
    80005046:	64e2                	ld	s1,24(sp)
    80005048:	6942                	ld	s2,16(sp)
    8000504a:	6145                	addi	sp,sp,48
    8000504c:	8082                	ret
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	bfcd                	j	80005042 <argfd+0x44>
    80005052:	557d                	li	a0,-1
    80005054:	b7fd                	j	80005042 <argfd+0x44>

0000000080005056 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005056:	1101                	addi	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	1000                	addi	s0,sp,32
    80005060:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005062:	9d9fc0ef          	jal	ra,80001a3a <myproc>
    80005066:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005068:	0d050793          	addi	a5,a0,208
    8000506c:	4501                	li	a0,0
    8000506e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005070:	6398                	ld	a4,0(a5)
    80005072:	cb19                	beqz	a4,80005088 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80005074:	2505                	addiw	a0,a0,1
    80005076:	07a1                	addi	a5,a5,8
    80005078:	fed51ce3          	bne	a0,a3,80005070 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000507c:	557d                	li	a0,-1
}
    8000507e:	60e2                	ld	ra,24(sp)
    80005080:	6442                	ld	s0,16(sp)
    80005082:	64a2                	ld	s1,8(sp)
    80005084:	6105                	addi	sp,sp,32
    80005086:	8082                	ret
      p->ofile[fd] = f;
    80005088:	01a50793          	addi	a5,a0,26
    8000508c:	078e                	slli	a5,a5,0x3
    8000508e:	963e                	add	a2,a2,a5
    80005090:	e204                	sd	s1,0(a2)
      return fd;
    80005092:	b7f5                	j	8000507e <fdalloc+0x28>

0000000080005094 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005094:	715d                	addi	sp,sp,-80
    80005096:	e486                	sd	ra,72(sp)
    80005098:	e0a2                	sd	s0,64(sp)
    8000509a:	fc26                	sd	s1,56(sp)
    8000509c:	f84a                	sd	s2,48(sp)
    8000509e:	f44e                	sd	s3,40(sp)
    800050a0:	f052                	sd	s4,32(sp)
    800050a2:	ec56                	sd	s5,24(sp)
    800050a4:	e85a                	sd	s6,16(sp)
    800050a6:	0880                	addi	s0,sp,80
    800050a8:	8b2e                	mv	s6,a1
    800050aa:	89b2                	mv	s3,a2
    800050ac:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ae:	fb040593          	addi	a1,s0,-80
    800050b2:	868ff0ef          	jal	ra,8000411a <nameiparent>
    800050b6:	84aa                	mv	s1,a0
    800050b8:	10050b63          	beqz	a0,800051ce <create+0x13a>
    return 0;

  ilock(dp);
    800050bc:	857fe0ef          	jal	ra,80003912 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050c0:	4601                	li	a2,0
    800050c2:	fb040593          	addi	a1,s0,-80
    800050c6:	8526                	mv	a0,s1
    800050c8:	dd3fe0ef          	jal	ra,80003e9a <dirlookup>
    800050cc:	8aaa                	mv	s5,a0
    800050ce:	c521                	beqz	a0,80005116 <create+0x82>
    iunlockput(dp);
    800050d0:	8526                	mv	a0,s1
    800050d2:	a47fe0ef          	jal	ra,80003b18 <iunlockput>
    ilock(ip);
    800050d6:	8556                	mv	a0,s5
    800050d8:	83bfe0ef          	jal	ra,80003912 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050dc:	000b059b          	sext.w	a1,s6
    800050e0:	4789                	li	a5,2
    800050e2:	02f59563          	bne	a1,a5,8000510c <create+0x78>
    800050e6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ff53a4c>
    800050ea:	37f9                	addiw	a5,a5,-2
    800050ec:	17c2                	slli	a5,a5,0x30
    800050ee:	93c1                	srli	a5,a5,0x30
    800050f0:	4705                	li	a4,1
    800050f2:	00f76d63          	bltu	a4,a5,8000510c <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800050f6:	8556                	mv	a0,s5
    800050f8:	60a6                	ld	ra,72(sp)
    800050fa:	6406                	ld	s0,64(sp)
    800050fc:	74e2                	ld	s1,56(sp)
    800050fe:	7942                	ld	s2,48(sp)
    80005100:	79a2                	ld	s3,40(sp)
    80005102:	7a02                	ld	s4,32(sp)
    80005104:	6ae2                	ld	s5,24(sp)
    80005106:	6b42                	ld	s6,16(sp)
    80005108:	6161                	addi	sp,sp,80
    8000510a:	8082                	ret
    iunlockput(ip);
    8000510c:	8556                	mv	a0,s5
    8000510e:	a0bfe0ef          	jal	ra,80003b18 <iunlockput>
    return 0;
    80005112:	4a81                	li	s5,0
    80005114:	b7cd                	j	800050f6 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005116:	85da                	mv	a1,s6
    80005118:	4088                	lw	a0,0(s1)
    8000511a:	e90fe0ef          	jal	ra,800037aa <ialloc>
    8000511e:	8a2a                	mv	s4,a0
    80005120:	cd1d                	beqz	a0,8000515e <create+0xca>
  ilock(ip);
    80005122:	ff0fe0ef          	jal	ra,80003912 <ilock>
  ip->major = major;
    80005126:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000512a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000512e:	4905                	li	s2,1
    80005130:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005134:	8552                	mv	a0,s4
    80005136:	f2afe0ef          	jal	ra,80003860 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000513a:	000b059b          	sext.w	a1,s6
    8000513e:	03258563          	beq	a1,s2,80005168 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80005142:	004a2603          	lw	a2,4(s4)
    80005146:	fb040593          	addi	a1,s0,-80
    8000514a:	8526                	mv	a0,s1
    8000514c:	f1bfe0ef          	jal	ra,80004066 <dirlink>
    80005150:	06054363          	bltz	a0,800051b6 <create+0x122>
  iunlockput(dp);
    80005154:	8526                	mv	a0,s1
    80005156:	9c3fe0ef          	jal	ra,80003b18 <iunlockput>
  return ip;
    8000515a:	8ad2                	mv	s5,s4
    8000515c:	bf69                	j	800050f6 <create+0x62>
    iunlockput(dp);
    8000515e:	8526                	mv	a0,s1
    80005160:	9b9fe0ef          	jal	ra,80003b18 <iunlockput>
    return 0;
    80005164:	8ad2                	mv	s5,s4
    80005166:	bf41                	j	800050f6 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005168:	004a2603          	lw	a2,4(s4)
    8000516c:	00002597          	auipc	a1,0x2
    80005170:	61c58593          	addi	a1,a1,1564 # 80007788 <syscalls+0x300>
    80005174:	8552                	mv	a0,s4
    80005176:	ef1fe0ef          	jal	ra,80004066 <dirlink>
    8000517a:	02054e63          	bltz	a0,800051b6 <create+0x122>
    8000517e:	40d0                	lw	a2,4(s1)
    80005180:	00002597          	auipc	a1,0x2
    80005184:	61058593          	addi	a1,a1,1552 # 80007790 <syscalls+0x308>
    80005188:	8552                	mv	a0,s4
    8000518a:	eddfe0ef          	jal	ra,80004066 <dirlink>
    8000518e:	02054463          	bltz	a0,800051b6 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80005192:	004a2603          	lw	a2,4(s4)
    80005196:	fb040593          	addi	a1,s0,-80
    8000519a:	8526                	mv	a0,s1
    8000519c:	ecbfe0ef          	jal	ra,80004066 <dirlink>
    800051a0:	00054b63          	bltz	a0,800051b6 <create+0x122>
    dp->nlink++;  // for ".."
    800051a4:	04a4d783          	lhu	a5,74(s1)
    800051a8:	2785                	addiw	a5,a5,1
    800051aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051ae:	8526                	mv	a0,s1
    800051b0:	eb0fe0ef          	jal	ra,80003860 <iupdate>
    800051b4:	b745                	j	80005154 <create+0xc0>
  ip->nlink = 0;
    800051b6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051ba:	8552                	mv	a0,s4
    800051bc:	ea4fe0ef          	jal	ra,80003860 <iupdate>
  iunlockput(ip);
    800051c0:	8552                	mv	a0,s4
    800051c2:	957fe0ef          	jal	ra,80003b18 <iunlockput>
  iunlockput(dp);
    800051c6:	8526                	mv	a0,s1
    800051c8:	951fe0ef          	jal	ra,80003b18 <iunlockput>
  return 0;
    800051cc:	b72d                	j	800050f6 <create+0x62>
    return 0;
    800051ce:	8aaa                	mv	s5,a0
    800051d0:	b71d                	j	800050f6 <create+0x62>

00000000800051d2 <sys_dup>:
{
    800051d2:	7179                	addi	sp,sp,-48
    800051d4:	f406                	sd	ra,40(sp)
    800051d6:	f022                	sd	s0,32(sp)
    800051d8:	ec26                	sd	s1,24(sp)
    800051da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051dc:	fd840613          	addi	a2,s0,-40
    800051e0:	4581                	li	a1,0
    800051e2:	4501                	li	a0,0
    800051e4:	e1bff0ef          	jal	ra,80004ffe <argfd>
    return -1;
    800051e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ea:	00054f63          	bltz	a0,80005208 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)
    800051ee:	fd843503          	ld	a0,-40(s0)
    800051f2:	e65ff0ef          	jal	ra,80005056 <fdalloc>
    800051f6:	84aa                	mv	s1,a0
    return -1;
    800051f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051fa:	00054763          	bltz	a0,80005208 <sys_dup+0x36>
  filedup(f);
    800051fe:	fd843503          	ld	a0,-40(s0)
    80005202:	cb6ff0ef          	jal	ra,800046b8 <filedup>
  return fd;
    80005206:	87a6                	mv	a5,s1
}
    80005208:	853e                	mv	a0,a5
    8000520a:	70a2                	ld	ra,40(sp)
    8000520c:	7402                	ld	s0,32(sp)
    8000520e:	64e2                	ld	s1,24(sp)
    80005210:	6145                	addi	sp,sp,48
    80005212:	8082                	ret

0000000080005214 <sys_read>:
{
    80005214:	7179                	addi	sp,sp,-48
    80005216:	f406                	sd	ra,40(sp)
    80005218:	f022                	sd	s0,32(sp)
    8000521a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000521c:	fd840593          	addi	a1,s0,-40
    80005220:	4505                	li	a0,1
    80005222:	d25fd0ef          	jal	ra,80002f46 <argaddr>
  argint(2, &n);
    80005226:	fe440593          	addi	a1,s0,-28
    8000522a:	4509                	li	a0,2
    8000522c:	cfffd0ef          	jal	ra,80002f2a <argint>
  if(argfd(0, 0, &f) < 0)
    80005230:	fe840613          	addi	a2,s0,-24
    80005234:	4581                	li	a1,0
    80005236:	4501                	li	a0,0
    80005238:	dc7ff0ef          	jal	ra,80004ffe <argfd>
    8000523c:	87aa                	mv	a5,a0
    return -1;
    8000523e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005240:	0007ca63          	bltz	a5,80005254 <sys_read+0x40>
  return fileread(f, p, n);
    80005244:	fe442603          	lw	a2,-28(s0)
    80005248:	fd843583          	ld	a1,-40(s0)
    8000524c:	fe843503          	ld	a0,-24(s0)
    80005250:	db4ff0ef          	jal	ra,80004804 <fileread>
}
    80005254:	70a2                	ld	ra,40(sp)
    80005256:	7402                	ld	s0,32(sp)
    80005258:	6145                	addi	sp,sp,48
    8000525a:	8082                	ret

000000008000525c <sys_write>:
{
    8000525c:	7179                	addi	sp,sp,-48
    8000525e:	f406                	sd	ra,40(sp)
    80005260:	f022                	sd	s0,32(sp)
    80005262:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005264:	fd840593          	addi	a1,s0,-40
    80005268:	4505                	li	a0,1
    8000526a:	cddfd0ef          	jal	ra,80002f46 <argaddr>
  argint(2, &n);
    8000526e:	fe440593          	addi	a1,s0,-28
    80005272:	4509                	li	a0,2
    80005274:	cb7fd0ef          	jal	ra,80002f2a <argint>
  if(argfd(0, 0, &f) < 0)
    80005278:	fe840613          	addi	a2,s0,-24
    8000527c:	4581                	li	a1,0
    8000527e:	4501                	li	a0,0
    80005280:	d7fff0ef          	jal	ra,80004ffe <argfd>
    80005284:	87aa                	mv	a5,a0
    return -1;
    80005286:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005288:	0007ca63          	bltz	a5,8000529c <sys_write+0x40>
  return filewrite(f, p, n);
    8000528c:	fe442603          	lw	a2,-28(s0)
    80005290:	fd843583          	ld	a1,-40(s0)
    80005294:	fe843503          	ld	a0,-24(s0)
    80005298:	e1aff0ef          	jal	ra,800048b2 <filewrite>
}
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret

00000000800052a4 <sys_close>:
{
    800052a4:	1101                	addi	sp,sp,-32
    800052a6:	ec06                	sd	ra,24(sp)
    800052a8:	e822                	sd	s0,16(sp)
    800052aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052ac:	fe040613          	addi	a2,s0,-32
    800052b0:	fec40593          	addi	a1,s0,-20
    800052b4:	4501                	li	a0,0
    800052b6:	d49ff0ef          	jal	ra,80004ffe <argfd>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052bc:	02054063          	bltz	a0,800052dc <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    800052c0:	f7afc0ef          	jal	ra,80001a3a <myproc>
    800052c4:	fec42783          	lw	a5,-20(s0)
    800052c8:	07e9                	addi	a5,a5,26
    800052ca:	078e                	slli	a5,a5,0x3
    800052cc:	97aa                	add	a5,a5,a0
    800052ce:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052d2:	fe043503          	ld	a0,-32(s0)
    800052d6:	c28ff0ef          	jal	ra,800046fe <fileclose>
  return 0;
    800052da:	4781                	li	a5,0
}
    800052dc:	853e                	mv	a0,a5
    800052de:	60e2                	ld	ra,24(sp)
    800052e0:	6442                	ld	s0,16(sp)
    800052e2:	6105                	addi	sp,sp,32
    800052e4:	8082                	ret

00000000800052e6 <sys_fstat>:
{
    800052e6:	1101                	addi	sp,sp,-32
    800052e8:	ec06                	sd	ra,24(sp)
    800052ea:	e822                	sd	s0,16(sp)
    800052ec:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052ee:	fe040593          	addi	a1,s0,-32
    800052f2:	4505                	li	a0,1
    800052f4:	c53fd0ef          	jal	ra,80002f46 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052f8:	fe840613          	addi	a2,s0,-24
    800052fc:	4581                	li	a1,0
    800052fe:	4501                	li	a0,0
    80005300:	cffff0ef          	jal	ra,80004ffe <argfd>
    80005304:	87aa                	mv	a5,a0
    return -1;
    80005306:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005308:	0007c863          	bltz	a5,80005318 <sys_fstat+0x32>
  return filestat(f, st);
    8000530c:	fe043583          	ld	a1,-32(s0)
    80005310:	fe843503          	ld	a0,-24(s0)
    80005314:	c92ff0ef          	jal	ra,800047a6 <filestat>
}
    80005318:	60e2                	ld	ra,24(sp)
    8000531a:	6442                	ld	s0,16(sp)
    8000531c:	6105                	addi	sp,sp,32
    8000531e:	8082                	ret

0000000080005320 <sys_link>:
{
    80005320:	7169                	addi	sp,sp,-304
    80005322:	f606                	sd	ra,296(sp)
    80005324:	f222                	sd	s0,288(sp)
    80005326:	ee26                	sd	s1,280(sp)
    80005328:	ea4a                	sd	s2,272(sp)
    8000532a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000532c:	08000613          	li	a2,128
    80005330:	ed040593          	addi	a1,s0,-304
    80005334:	4501                	li	a0,0
    80005336:	c2dfd0ef          	jal	ra,80002f62 <argstr>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533c:	0c054663          	bltz	a0,80005408 <sys_link+0xe8>
    80005340:	08000613          	li	a2,128
    80005344:	f5040593          	addi	a1,s0,-176
    80005348:	4505                	li	a0,1
    8000534a:	c19fd0ef          	jal	ra,80002f62 <argstr>
    return -1;
    8000534e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005350:	0a054c63          	bltz	a0,80005408 <sys_link+0xe8>
  begin_op();
    80005354:	f9dfe0ef          	jal	ra,800042f0 <begin_op>
  if((ip = namei(old)) == 0){
    80005358:	ed040513          	addi	a0,s0,-304
    8000535c:	da5fe0ef          	jal	ra,80004100 <namei>
    80005360:	84aa                	mv	s1,a0
    80005362:	c525                	beqz	a0,800053ca <sys_link+0xaa>
  ilock(ip);
    80005364:	daefe0ef          	jal	ra,80003912 <ilock>
  if(ip->type == T_DIR){
    80005368:	04449703          	lh	a4,68(s1)
    8000536c:	4785                	li	a5,1
    8000536e:	06f70263          	beq	a4,a5,800053d2 <sys_link+0xb2>
  ip->nlink++;
    80005372:	04a4d783          	lhu	a5,74(s1)
    80005376:	2785                	addiw	a5,a5,1
    80005378:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ce2fe0ef          	jal	ra,80003860 <iupdate>
  iunlock(ip);
    80005382:	8526                	mv	a0,s1
    80005384:	e38fe0ef          	jal	ra,800039bc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005388:	fd040593          	addi	a1,s0,-48
    8000538c:	f5040513          	addi	a0,s0,-176
    80005390:	d8bfe0ef          	jal	ra,8000411a <nameiparent>
    80005394:	892a                	mv	s2,a0
    80005396:	c921                	beqz	a0,800053e6 <sys_link+0xc6>
  ilock(dp);
    80005398:	d7afe0ef          	jal	ra,80003912 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000539c:	00092703          	lw	a4,0(s2)
    800053a0:	409c                	lw	a5,0(s1)
    800053a2:	02f71f63          	bne	a4,a5,800053e0 <sys_link+0xc0>
    800053a6:	40d0                	lw	a2,4(s1)
    800053a8:	fd040593          	addi	a1,s0,-48
    800053ac:	854a                	mv	a0,s2
    800053ae:	cb9fe0ef          	jal	ra,80004066 <dirlink>
    800053b2:	02054763          	bltz	a0,800053e0 <sys_link+0xc0>
  iunlockput(dp);
    800053b6:	854a                	mv	a0,s2
    800053b8:	f60fe0ef          	jal	ra,80003b18 <iunlockput>
  iput(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ed2fe0ef          	jal	ra,80003a90 <iput>
  end_op();
    800053c2:	f9ffe0ef          	jal	ra,80004360 <end_op>
  return 0;
    800053c6:	4781                	li	a5,0
    800053c8:	a081                	j	80005408 <sys_link+0xe8>
    end_op();
    800053ca:	f97fe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800053ce:	57fd                	li	a5,-1
    800053d0:	a825                	j	80005408 <sys_link+0xe8>
    iunlockput(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	f44fe0ef          	jal	ra,80003b18 <iunlockput>
    end_op();
    800053d8:	f89fe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800053dc:	57fd                	li	a5,-1
    800053de:	a02d                	j	80005408 <sys_link+0xe8>
    iunlockput(dp);
    800053e0:	854a                	mv	a0,s2
    800053e2:	f36fe0ef          	jal	ra,80003b18 <iunlockput>
  ilock(ip);
    800053e6:	8526                	mv	a0,s1
    800053e8:	d2afe0ef          	jal	ra,80003912 <ilock>
  ip->nlink--;
    800053ec:	04a4d783          	lhu	a5,74(s1)
    800053f0:	37fd                	addiw	a5,a5,-1
    800053f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053f6:	8526                	mv	a0,s1
    800053f8:	c68fe0ef          	jal	ra,80003860 <iupdate>
  iunlockput(ip);
    800053fc:	8526                	mv	a0,s1
    800053fe:	f1afe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    80005402:	f5ffe0ef          	jal	ra,80004360 <end_op>
  return -1;
    80005406:	57fd                	li	a5,-1
}
    80005408:	853e                	mv	a0,a5
    8000540a:	70b2                	ld	ra,296(sp)
    8000540c:	7412                	ld	s0,288(sp)
    8000540e:	64f2                	ld	s1,280(sp)
    80005410:	6952                	ld	s2,272(sp)
    80005412:	6155                	addi	sp,sp,304
    80005414:	8082                	ret

0000000080005416 <sys_unlink>:
{
    80005416:	7151                	addi	sp,sp,-240
    80005418:	f586                	sd	ra,232(sp)
    8000541a:	f1a2                	sd	s0,224(sp)
    8000541c:	eda6                	sd	s1,216(sp)
    8000541e:	e9ca                	sd	s2,208(sp)
    80005420:	e5ce                	sd	s3,200(sp)
    80005422:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005424:	08000613          	li	a2,128
    80005428:	f3040593          	addi	a1,s0,-208
    8000542c:	4501                	li	a0,0
    8000542e:	b35fd0ef          	jal	ra,80002f62 <argstr>
    80005432:	12054b63          	bltz	a0,80005568 <sys_unlink+0x152>
  begin_op();
    80005436:	ebbfe0ef          	jal	ra,800042f0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000543a:	fb040593          	addi	a1,s0,-80
    8000543e:	f3040513          	addi	a0,s0,-208
    80005442:	cd9fe0ef          	jal	ra,8000411a <nameiparent>
    80005446:	84aa                	mv	s1,a0
    80005448:	c54d                	beqz	a0,800054f2 <sys_unlink+0xdc>
  ilock(dp);
    8000544a:	cc8fe0ef          	jal	ra,80003912 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000544e:	00002597          	auipc	a1,0x2
    80005452:	33a58593          	addi	a1,a1,826 # 80007788 <syscalls+0x300>
    80005456:	fb040513          	addi	a0,s0,-80
    8000545a:	a2bfe0ef          	jal	ra,80003e84 <namecmp>
    8000545e:	10050a63          	beqz	a0,80005572 <sys_unlink+0x15c>
    80005462:	00002597          	auipc	a1,0x2
    80005466:	32e58593          	addi	a1,a1,814 # 80007790 <syscalls+0x308>
    8000546a:	fb040513          	addi	a0,s0,-80
    8000546e:	a17fe0ef          	jal	ra,80003e84 <namecmp>
    80005472:	10050063          	beqz	a0,80005572 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005476:	f2c40613          	addi	a2,s0,-212
    8000547a:	fb040593          	addi	a1,s0,-80
    8000547e:	8526                	mv	a0,s1
    80005480:	a1bfe0ef          	jal	ra,80003e9a <dirlookup>
    80005484:	892a                	mv	s2,a0
    80005486:	0e050663          	beqz	a0,80005572 <sys_unlink+0x15c>
  ilock(ip);
    8000548a:	c88fe0ef          	jal	ra,80003912 <ilock>
  if(ip->nlink < 1)
    8000548e:	04a91783          	lh	a5,74(s2)
    80005492:	06f05463          	blez	a5,800054fa <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005496:	04491703          	lh	a4,68(s2)
    8000549a:	4785                	li	a5,1
    8000549c:	06f70563          	beq	a4,a5,80005506 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));
    800054a0:	4641                	li	a2,16
    800054a2:	4581                	li	a1,0
    800054a4:	fc040513          	addi	a0,s0,-64
    800054a8:	8fffb0ef          	jal	ra,80000da6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ac:	4741                	li	a4,16
    800054ae:	f2c42683          	lw	a3,-212(s0)
    800054b2:	fc040613          	addi	a2,s0,-64
    800054b6:	4581                	li	a1,0
    800054b8:	8526                	mv	a0,s1
    800054ba:	8c9fe0ef          	jal	ra,80003d82 <writei>
    800054be:	47c1                	li	a5,16
    800054c0:	08f51563          	bne	a0,a5,8000554a <sys_unlink+0x134>
  if(ip->type == T_DIR){
    800054c4:	04491703          	lh	a4,68(s2)
    800054c8:	4785                	li	a5,1
    800054ca:	08f70663          	beq	a4,a5,80005556 <sys_unlink+0x140>
  iunlockput(dp);
    800054ce:	8526                	mv	a0,s1
    800054d0:	e48fe0ef          	jal	ra,80003b18 <iunlockput>
  ip->nlink--;
    800054d4:	04a95783          	lhu	a5,74(s2)
    800054d8:	37fd                	addiw	a5,a5,-1
    800054da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054de:	854a                	mv	a0,s2
    800054e0:	b80fe0ef          	jal	ra,80003860 <iupdate>
  iunlockput(ip);
    800054e4:	854a                	mv	a0,s2
    800054e6:	e32fe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    800054ea:	e77fe0ef          	jal	ra,80004360 <end_op>
  return 0;
    800054ee:	4501                	li	a0,0
    800054f0:	a079                	j	8000557e <sys_unlink+0x168>
    end_op();
    800054f2:	e6ffe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800054f6:	557d                	li	a0,-1
    800054f8:	a059                	j	8000557e <sys_unlink+0x168>
    panic("unlink: nlink < 1");
    800054fa:	00002517          	auipc	a0,0x2
    800054fe:	29e50513          	addi	a0,a0,670 # 80007798 <syscalls+0x310>
    80005502:	a88fb0ef          	jal	ra,8000078a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005506:	04c92703          	lw	a4,76(s2)
    8000550a:	02000793          	li	a5,32
    8000550e:	f8e7f9e3          	bgeu	a5,a4,800054a0 <sys_unlink+0x8a>
    80005512:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005516:	4741                	li	a4,16
    80005518:	86ce                	mv	a3,s3
    8000551a:	f1840613          	addi	a2,s0,-232
    8000551e:	4581                	li	a1,0
    80005520:	854a                	mv	a0,s2
    80005522:	f7cfe0ef          	jal	ra,80003c9e <readi>
    80005526:	47c1                	li	a5,16
    80005528:	00f51b63          	bne	a0,a5,8000553e <sys_unlink+0x128>
    if(de.inum != 0)
    8000552c:	f1845783          	lhu	a5,-232(s0)
    80005530:	ef95                	bnez	a5,8000556c <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005532:	29c1                	addiw	s3,s3,16
    80005534:	04c92783          	lw	a5,76(s2)
    80005538:	fcf9efe3          	bltu	s3,a5,80005516 <sys_unlink+0x100>
    8000553c:	b795                	j	800054a0 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    8000553e:	00002517          	auipc	a0,0x2
    80005542:	27250513          	addi	a0,a0,626 # 800077b0 <syscalls+0x328>
    80005546:	a44fb0ef          	jal	ra,8000078a <panic>
    panic("unlink: writei");
    8000554a:	00002517          	auipc	a0,0x2
    8000554e:	27e50513          	addi	a0,a0,638 # 800077c8 <syscalls+0x340>
    80005552:	a38fb0ef          	jal	ra,8000078a <panic>
    dp->nlink--;
    80005556:	04a4d783          	lhu	a5,74(s1)
    8000555a:	37fd                	addiw	a5,a5,-1
    8000555c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005560:	8526                	mv	a0,s1
    80005562:	afefe0ef          	jal	ra,80003860 <iupdate>
    80005566:	b7a5                	j	800054ce <sys_unlink+0xb8>
    return -1;
    80005568:	557d                	li	a0,-1
    8000556a:	a811                	j	8000557e <sys_unlink+0x168>
    iunlockput(ip);
    8000556c:	854a                	mv	a0,s2
    8000556e:	daafe0ef          	jal	ra,80003b18 <iunlockput>
  iunlockput(dp);
    80005572:	8526                	mv	a0,s1
    80005574:	da4fe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    80005578:	de9fe0ef          	jal	ra,80004360 <end_op>
  return -1;
    8000557c:	557d                	li	a0,-1
}
    8000557e:	70ae                	ld	ra,232(sp)
    80005580:	740e                	ld	s0,224(sp)
    80005582:	64ee                	ld	s1,216(sp)
    80005584:	694e                	ld	s2,208(sp)
    80005586:	69ae                	ld	s3,200(sp)
    80005588:	616d                	addi	sp,sp,240
    8000558a:	8082                	ret

000000008000558c <sys_open>:

uint64
sys_open(void)
{
    8000558c:	7131                	addi	sp,sp,-192
    8000558e:	fd06                	sd	ra,184(sp)
    80005590:	f922                	sd	s0,176(sp)
    80005592:	f526                	sd	s1,168(sp)
    80005594:	f14a                	sd	s2,160(sp)
    80005596:	ed4e                	sd	s3,152(sp)
    80005598:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000559a:	f4c40593          	addi	a1,s0,-180
    8000559e:	4505                	li	a0,1
    800055a0:	98bfd0ef          	jal	ra,80002f2a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800055a4:	08000613          	li	a2,128
    800055a8:	f5040593          	addi	a1,s0,-176
    800055ac:	4501                	li	a0,0
    800055ae:	9b5fd0ef          	jal	ra,80002f62 <argstr>
    800055b2:	87aa                	mv	a5,a0
    return -1;
    800055b4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800055b6:	0807cd63          	bltz	a5,80005650 <sys_open+0xc4>

  begin_op();
    800055ba:	d37fe0ef          	jal	ra,800042f0 <begin_op>

  if(omode & O_CREATE){
    800055be:	f4c42783          	lw	a5,-180(s0)
    800055c2:	2007f793          	andi	a5,a5,512
    800055c6:	c3c5                	beqz	a5,80005666 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800055c8:	4681                	li	a3,0
    800055ca:	4601                	li	a2,0
    800055cc:	4589                	li	a1,2
    800055ce:	f5040513          	addi	a0,s0,-176
    800055d2:	ac3ff0ef          	jal	ra,80005094 <create>
    800055d6:	84aa                	mv	s1,a0
    if(ip == 0){
    800055d8:	c159                	beqz	a0,8000565e <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055da:	04449703          	lh	a4,68(s1)
    800055de:	478d                	li	a5,3
    800055e0:	00f71763          	bne	a4,a5,800055ee <sys_open+0x62>
    800055e4:	0464d703          	lhu	a4,70(s1)
    800055e8:	47a5                	li	a5,9
    800055ea:	0ae7e963          	bltu	a5,a4,8000569c <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ee:	86cff0ef          	jal	ra,8000465a <filealloc>
    800055f2:	89aa                	mv	s3,a0
    800055f4:	0c050963          	beqz	a0,800056c6 <sys_open+0x13a>
    800055f8:	a5fff0ef          	jal	ra,80005056 <fdalloc>
    800055fc:	892a                	mv	s2,a0
    800055fe:	0c054163          	bltz	a0,800056c0 <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005602:	04449703          	lh	a4,68(s1)
    80005606:	478d                	li	a5,3
    80005608:	0af70163          	beq	a4,a5,800056aa <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000560c:	4789                	li	a5,2
    8000560e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005612:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005616:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000561a:	f4c42783          	lw	a5,-180(s0)
    8000561e:	0017c713          	xori	a4,a5,1
    80005622:	8b05                	andi	a4,a4,1
    80005624:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005628:	0037f713          	andi	a4,a5,3
    8000562c:	00e03733          	snez	a4,a4
    80005630:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005634:	4007f793          	andi	a5,a5,1024
    80005638:	c791                	beqz	a5,80005644 <sys_open+0xb8>
    8000563a:	04449703          	lh	a4,68(s1)
    8000563e:	4789                	li	a5,2
    80005640:	06f70c63          	beq	a4,a5,800056b8 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80005644:	8526                	mv	a0,s1
    80005646:	b76fe0ef          	jal	ra,800039bc <iunlock>
  end_op();
    8000564a:	d17fe0ef          	jal	ra,80004360 <end_op>

  return fd;
    8000564e:	854a                	mv	a0,s2
}
    80005650:	70ea                	ld	ra,184(sp)
    80005652:	744a                	ld	s0,176(sp)
    80005654:	74aa                	ld	s1,168(sp)
    80005656:	790a                	ld	s2,160(sp)
    80005658:	69ea                	ld	s3,152(sp)
    8000565a:	6129                	addi	sp,sp,192
    8000565c:	8082                	ret
      end_op();
    8000565e:	d03fe0ef          	jal	ra,80004360 <end_op>
      return -1;
    80005662:	557d                	li	a0,-1
    80005664:	b7f5                	j	80005650 <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80005666:	f5040513          	addi	a0,s0,-176
    8000566a:	a97fe0ef          	jal	ra,80004100 <namei>
    8000566e:	84aa                	mv	s1,a0
    80005670:	c115                	beqz	a0,80005694 <sys_open+0x108>
    ilock(ip);
    80005672:	aa0fe0ef          	jal	ra,80003912 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005676:	04449703          	lh	a4,68(s1)
    8000567a:	4785                	li	a5,1
    8000567c:	f4f71fe3          	bne	a4,a5,800055da <sys_open+0x4e>
    80005680:	f4c42783          	lw	a5,-180(s0)
    80005684:	d7ad                	beqz	a5,800055ee <sys_open+0x62>
      iunlockput(ip);
    80005686:	8526                	mv	a0,s1
    80005688:	c90fe0ef          	jal	ra,80003b18 <iunlockput>
      end_op();
    8000568c:	cd5fe0ef          	jal	ra,80004360 <end_op>
      return -1;
    80005690:	557d                	li	a0,-1
    80005692:	bf7d                	j	80005650 <sys_open+0xc4>
      end_op();
    80005694:	ccdfe0ef          	jal	ra,80004360 <end_op>
      return -1;
    80005698:	557d                	li	a0,-1
    8000569a:	bf5d                	j	80005650 <sys_open+0xc4>
    iunlockput(ip);
    8000569c:	8526                	mv	a0,s1
    8000569e:	c7afe0ef          	jal	ra,80003b18 <iunlockput>
    end_op();
    800056a2:	cbffe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800056a6:	557d                	li	a0,-1
    800056a8:	b765                	j	80005650 <sys_open+0xc4>
    f->type = FD_DEVICE;
    800056aa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056ae:	04649783          	lh	a5,70(s1)
    800056b2:	02f99223          	sh	a5,36(s3)
    800056b6:	b785                	j	80005616 <sys_open+0x8a>
    itrunc(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	b42fe0ef          	jal	ra,800039fc <itrunc>
    800056be:	b759                	j	80005644 <sys_open+0xb8>
      fileclose(f);
    800056c0:	854e                	mv	a0,s3
    800056c2:	83cff0ef          	jal	ra,800046fe <fileclose>
    iunlockput(ip);
    800056c6:	8526                	mv	a0,s1
    800056c8:	c50fe0ef          	jal	ra,80003b18 <iunlockput>
    end_op();
    800056cc:	c95fe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800056d0:	557d                	li	a0,-1
    800056d2:	bfbd                	j	80005650 <sys_open+0xc4>

00000000800056d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056d4:	7175                	addi	sp,sp,-144
    800056d6:	e506                	sd	ra,136(sp)
    800056d8:	e122                	sd	s0,128(sp)
    800056da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056dc:	c15fe0ef          	jal	ra,800042f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800056e0:	08000613          	li	a2,128
    800056e4:	f7040593          	addi	a1,s0,-144
    800056e8:	4501                	li	a0,0
    800056ea:	879fd0ef          	jal	ra,80002f62 <argstr>
    800056ee:	02054363          	bltz	a0,80005714 <sys_mkdir+0x40>
    800056f2:	4681                	li	a3,0
    800056f4:	4601                	li	a2,0
    800056f6:	4585                	li	a1,1
    800056f8:	f7040513          	addi	a0,s0,-144
    800056fc:	999ff0ef          	jal	ra,80005094 <create>
    80005700:	c911                	beqz	a0,80005714 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005702:	c16fe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    80005706:	c5bfe0ef          	jal	ra,80004360 <end_op>
  return 0;
    8000570a:	4501                	li	a0,0
}
    8000570c:	60aa                	ld	ra,136(sp)
    8000570e:	640a                	ld	s0,128(sp)
    80005710:	6149                	addi	sp,sp,144
    80005712:	8082                	ret
    end_op();
    80005714:	c4dfe0ef          	jal	ra,80004360 <end_op>
    return -1;
    80005718:	557d                	li	a0,-1
    8000571a:	bfcd                	j	8000570c <sys_mkdir+0x38>

000000008000571c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000571c:	7135                	addi	sp,sp,-160
    8000571e:	ed06                	sd	ra,152(sp)
    80005720:	e922                	sd	s0,144(sp)
    80005722:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005724:	bcdfe0ef          	jal	ra,800042f0 <begin_op>
  argint(1, &major);
    80005728:	f6c40593          	addi	a1,s0,-148
    8000572c:	4505                	li	a0,1
    8000572e:	ffcfd0ef          	jal	ra,80002f2a <argint>
  argint(2, &minor);
    80005732:	f6840593          	addi	a1,s0,-152
    80005736:	4509                	li	a0,2
    80005738:	ff2fd0ef          	jal	ra,80002f2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000573c:	08000613          	li	a2,128
    80005740:	f7040593          	addi	a1,s0,-144
    80005744:	4501                	li	a0,0
    80005746:	81dfd0ef          	jal	ra,80002f62 <argstr>
    8000574a:	02054563          	bltz	a0,80005774 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000574e:	f6841683          	lh	a3,-152(s0)
    80005752:	f6c41603          	lh	a2,-148(s0)
    80005756:	458d                	li	a1,3
    80005758:	f7040513          	addi	a0,s0,-144
    8000575c:	939ff0ef          	jal	ra,80005094 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005760:	c911                	beqz	a0,80005774 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005762:	bb6fe0ef          	jal	ra,80003b18 <iunlockput>
  end_op();
    80005766:	bfbfe0ef          	jal	ra,80004360 <end_op>
  return 0;
    8000576a:	4501                	li	a0,0
}
    8000576c:	60ea                	ld	ra,152(sp)
    8000576e:	644a                	ld	s0,144(sp)
    80005770:	610d                	addi	sp,sp,160
    80005772:	8082                	ret
    end_op();
    80005774:	bedfe0ef          	jal	ra,80004360 <end_op>
    return -1;
    80005778:	557d                	li	a0,-1
    8000577a:	bfcd                	j	8000576c <sys_mknod+0x50>

000000008000577c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000577c:	7135                	addi	sp,sp,-160
    8000577e:	ed06                	sd	ra,152(sp)
    80005780:	e922                	sd	s0,144(sp)
    80005782:	e526                	sd	s1,136(sp)
    80005784:	e14a                	sd	s2,128(sp)
    80005786:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005788:	ab2fc0ef          	jal	ra,80001a3a <myproc>
    8000578c:	892a                	mv	s2,a0
  
  begin_op();
    8000578e:	b63fe0ef          	jal	ra,800042f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005792:	08000613          	li	a2,128
    80005796:	f6040593          	addi	a1,s0,-160
    8000579a:	4501                	li	a0,0
    8000579c:	fc6fd0ef          	jal	ra,80002f62 <argstr>
    800057a0:	04054163          	bltz	a0,800057e2 <sys_chdir+0x66>
    800057a4:	f6040513          	addi	a0,s0,-160
    800057a8:	959fe0ef          	jal	ra,80004100 <namei>
    800057ac:	84aa                	mv	s1,a0
    800057ae:	c915                	beqz	a0,800057e2 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800057b0:	962fe0ef          	jal	ra,80003912 <ilock>
  if(ip->type != T_DIR){
    800057b4:	04449703          	lh	a4,68(s1)
    800057b8:	4785                	li	a5,1
    800057ba:	02f71863          	bne	a4,a5,800057ea <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	9fcfe0ef          	jal	ra,800039bc <iunlock>
  iput(p->cwd);
    800057c4:	15093503          	ld	a0,336(s2)
    800057c8:	ac8fe0ef          	jal	ra,80003a90 <iput>
  end_op();
    800057cc:	b95fe0ef          	jal	ra,80004360 <end_op>
  p->cwd = ip;
    800057d0:	14993823          	sd	s1,336(s2)
  return 0;
    800057d4:	4501                	li	a0,0
}
    800057d6:	60ea                	ld	ra,152(sp)
    800057d8:	644a                	ld	s0,144(sp)
    800057da:	64aa                	ld	s1,136(sp)
    800057dc:	690a                	ld	s2,128(sp)
    800057de:	610d                	addi	sp,sp,160
    800057e0:	8082                	ret
    end_op();
    800057e2:	b7ffe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800057e6:	557d                	li	a0,-1
    800057e8:	b7fd                	j	800057d6 <sys_chdir+0x5a>
    iunlockput(ip);
    800057ea:	8526                	mv	a0,s1
    800057ec:	b2cfe0ef          	jal	ra,80003b18 <iunlockput>
    end_op();
    800057f0:	b71fe0ef          	jal	ra,80004360 <end_op>
    return -1;
    800057f4:	557d                	li	a0,-1
    800057f6:	b7c5                	j	800057d6 <sys_chdir+0x5a>

00000000800057f8 <sys_exec>:

uint64
sys_exec(void)
{
    800057f8:	7145                	addi	sp,sp,-464
    800057fa:	e786                	sd	ra,456(sp)
    800057fc:	e3a2                	sd	s0,448(sp)
    800057fe:	ff26                	sd	s1,440(sp)
    80005800:	fb4a                	sd	s2,432(sp)
    80005802:	f74e                	sd	s3,424(sp)
    80005804:	f352                	sd	s4,416(sp)
    80005806:	ef56                	sd	s5,408(sp)
    80005808:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000580a:	e3840593          	addi	a1,s0,-456
    8000580e:	4505                	li	a0,1
    80005810:	f36fd0ef          	jal	ra,80002f46 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005814:	08000613          	li	a2,128
    80005818:	f4040593          	addi	a1,s0,-192
    8000581c:	4501                	li	a0,0
    8000581e:	f44fd0ef          	jal	ra,80002f62 <argstr>
    80005822:	87aa                	mv	a5,a0
    return -1;
    80005824:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005826:	0a07c463          	bltz	a5,800058ce <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    8000582a:	10000613          	li	a2,256
    8000582e:	4581                	li	a1,0
    80005830:	e4040513          	addi	a0,s0,-448
    80005834:	d72fb0ef          	jal	ra,80000da6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005838:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000583c:	89a6                	mv	s3,s1
    8000583e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005840:	02000a13          	li	s4,32
    80005844:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005848:	00391793          	slli	a5,s2,0x3
    8000584c:	e3040593          	addi	a1,s0,-464
    80005850:	e3843503          	ld	a0,-456(s0)
    80005854:	953e                	add	a0,a0,a5
    80005856:	e4afd0ef          	jal	ra,80002ea0 <fetchaddr>
    8000585a:	02054663          	bltz	a0,80005886 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    8000585e:	e3043783          	ld	a5,-464(s0)
    80005862:	cf8d                	beqz	a5,8000589c <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005864:	a9afb0ef          	jal	ra,80000afe <kalloc>
    80005868:	85aa                	mv	a1,a0
    8000586a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000586e:	cd01                	beqz	a0,80005886 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005870:	6605                	lui	a2,0x1
    80005872:	e3043503          	ld	a0,-464(s0)
    80005876:	e74fd0ef          	jal	ra,80002eea <fetchstr>
    8000587a:	00054663          	bltz	a0,80005886 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000587e:	0905                	addi	s2,s2,1
    80005880:	09a1                	addi	s3,s3,8
    80005882:	fd4911e3          	bne	s2,s4,80005844 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005886:	10048913          	addi	s2,s1,256
    8000588a:	6088                	ld	a0,0(s1)
    8000588c:	c121                	beqz	a0,800058cc <sys_exec+0xd4>
    kfree(argv[i]);
    8000588e:	92efb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005892:	04a1                	addi	s1,s1,8
    80005894:	ff249be3          	bne	s1,s2,8000588a <sys_exec+0x92>
  return -1;
    80005898:	557d                	li	a0,-1
    8000589a:	a815                	j	800058ce <sys_exec+0xd6>
      argv[i] = 0;
    8000589c:	0a8e                	slli	s5,s5,0x3
    8000589e:	fc040793          	addi	a5,s0,-64
    800058a2:	9abe                	add	s5,s5,a5
    800058a4:	e80ab023          	sd	zero,-384(s5)
  int ret = kexec(path, argv);
    800058a8:	e4040593          	addi	a1,s0,-448
    800058ac:	f4040513          	addi	a0,s0,-192
    800058b0:	bfaff0ef          	jal	ra,80004caa <kexec>
    800058b4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058b6:	10048993          	addi	s3,s1,256
    800058ba:	6088                	ld	a0,0(s1)
    800058bc:	c511                	beqz	a0,800058c8 <sys_exec+0xd0>
    kfree(argv[i]);
    800058be:	8fefb0ef          	jal	ra,800009bc <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058c2:	04a1                	addi	s1,s1,8
    800058c4:	ff349be3          	bne	s1,s3,800058ba <sys_exec+0xc2>
  return ret;
    800058c8:	854a                	mv	a0,s2
    800058ca:	a011                	j	800058ce <sys_exec+0xd6>
  return -1;
    800058cc:	557d                	li	a0,-1
}
    800058ce:	60be                	ld	ra,456(sp)
    800058d0:	641e                	ld	s0,448(sp)
    800058d2:	74fa                	ld	s1,440(sp)
    800058d4:	795a                	ld	s2,432(sp)
    800058d6:	79ba                	ld	s3,424(sp)
    800058d8:	7a1a                	ld	s4,416(sp)
    800058da:	6afa                	ld	s5,408(sp)
    800058dc:	6179                	addi	sp,sp,464
    800058de:	8082                	ret

00000000800058e0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800058e0:	7139                	addi	sp,sp,-64
    800058e2:	fc06                	sd	ra,56(sp)
    800058e4:	f822                	sd	s0,48(sp)
    800058e6:	f426                	sd	s1,40(sp)
    800058e8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800058ea:	950fc0ef          	jal	ra,80001a3a <myproc>
    800058ee:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800058f0:	fd840593          	addi	a1,s0,-40
    800058f4:	4501                	li	a0,0
    800058f6:	e50fd0ef          	jal	ra,80002f46 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800058fa:	fc840593          	addi	a1,s0,-56
    800058fe:	fd040513          	addi	a0,s0,-48
    80005902:	8c8ff0ef          	jal	ra,800049ca <pipealloc>
    return -1;
    80005906:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005908:	0a054463          	bltz	a0,800059b0 <sys_pipe+0xd0>
  fd0 = -1;
    8000590c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005910:	fd043503          	ld	a0,-48(s0)
    80005914:	f42ff0ef          	jal	ra,80005056 <fdalloc>
    80005918:	fca42223          	sw	a0,-60(s0)
    8000591c:	08054163          	bltz	a0,8000599e <sys_pipe+0xbe>
    80005920:	fc843503          	ld	a0,-56(s0)
    80005924:	f32ff0ef          	jal	ra,80005056 <fdalloc>
    80005928:	fca42023          	sw	a0,-64(s0)
    8000592c:	06054063          	bltz	a0,8000598c <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005930:	4691                	li	a3,4
    80005932:	fc440613          	addi	a2,s0,-60
    80005936:	fd843583          	ld	a1,-40(s0)
    8000593a:	68a8                	ld	a0,80(s1)
    8000593c:	da5fb0ef          	jal	ra,800016e0 <copyout>
    80005940:	00054e63          	bltz	a0,8000595c <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005944:	4691                	li	a3,4
    80005946:	fc040613          	addi	a2,s0,-64
    8000594a:	fd843583          	ld	a1,-40(s0)
    8000594e:	0591                	addi	a1,a1,4
    80005950:	68a8                	ld	a0,80(s1)
    80005952:	d8ffb0ef          	jal	ra,800016e0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005956:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005958:	04055c63          	bgez	a0,800059b0 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000595c:	fc442783          	lw	a5,-60(s0)
    80005960:	07e9                	addi	a5,a5,26
    80005962:	078e                	slli	a5,a5,0x3
    80005964:	97a6                	add	a5,a5,s1
    80005966:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000596a:	fc042503          	lw	a0,-64(s0)
    8000596e:	0569                	addi	a0,a0,26
    80005970:	050e                	slli	a0,a0,0x3
    80005972:	94aa                	add	s1,s1,a0
    80005974:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005978:	fd043503          	ld	a0,-48(s0)
    8000597c:	d83fe0ef          	jal	ra,800046fe <fileclose>
    fileclose(wf);
    80005980:	fc843503          	ld	a0,-56(s0)
    80005984:	d7bfe0ef          	jal	ra,800046fe <fileclose>
    return -1;
    80005988:	57fd                	li	a5,-1
    8000598a:	a01d                	j	800059b0 <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000598c:	fc442783          	lw	a5,-60(s0)
    80005990:	0007c763          	bltz	a5,8000599e <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005994:	07e9                	addi	a5,a5,26
    80005996:	078e                	slli	a5,a5,0x3
    80005998:	94be                	add	s1,s1,a5
    8000599a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000599e:	fd043503          	ld	a0,-48(s0)
    800059a2:	d5dfe0ef          	jal	ra,800046fe <fileclose>
    fileclose(wf);
    800059a6:	fc843503          	ld	a0,-56(s0)
    800059aa:	d55fe0ef          	jal	ra,800046fe <fileclose>
    return -1;
    800059ae:	57fd                	li	a5,-1
}
    800059b0:	853e                	mv	a0,a5
    800059b2:	70e2                	ld	ra,56(sp)
    800059b4:	7442                	ld	s0,48(sp)
    800059b6:	74a2                	ld	s1,40(sp)
    800059b8:	6121                	addi	sp,sp,64
    800059ba:	8082                	ret
    800059bc:	0000                	unimp
	...

00000000800059c0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800059c0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800059c2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800059c4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800059c6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800059c8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800059ca:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800059cc:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800059ce:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800059d0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800059d2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800059d4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800059d6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800059d8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800059da:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800059dc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800059de:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800059e0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800059e2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800059e4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800059e6:	bbcfd0ef          	jal	ra,80002da2 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800059ea:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800059ec:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800059ee:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800059f0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800059f2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800059f4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800059f6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800059f8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800059fa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800059fc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800059fe:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005a00:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005a02:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005a04:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005a06:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005a08:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80005a0a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    80005a0c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    80005a0e:	10200073          	sret
	...

0000000080005a1e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005a1e:	1141                	addi	sp,sp,-16
    80005a20:	e422                	sd	s0,8(sp)
    80005a22:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005a24:	0c0007b7          	lui	a5,0xc000
    80005a28:	4705                	li	a4,1
    80005a2a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005a2c:	c3d8                	sw	a4,4(a5)
}
    80005a2e:	6422                	ld	s0,8(sp)
    80005a30:	0141                	addi	sp,sp,16
    80005a32:	8082                	ret

0000000080005a34 <plicinithart>:

void
plicinithart(void)
{
    80005a34:	1141                	addi	sp,sp,-16
    80005a36:	e406                	sd	ra,8(sp)
    80005a38:	e022                	sd	s0,0(sp)
    80005a3a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005a3c:	fd3fb0ef          	jal	ra,80001a0e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005a40:	0085171b          	slliw	a4,a0,0x8
    80005a44:	0c0027b7          	lui	a5,0xc002
    80005a48:	97ba                	add	a5,a5,a4
    80005a4a:	40200713          	li	a4,1026
    80005a4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005a52:	00d5151b          	slliw	a0,a0,0xd
    80005a56:	0c2017b7          	lui	a5,0xc201
    80005a5a:	953e                	add	a0,a0,a5
    80005a5c:	00052023          	sw	zero,0(a0)
}
    80005a60:	60a2                	ld	ra,8(sp)
    80005a62:	6402                	ld	s0,0(sp)
    80005a64:	0141                	addi	sp,sp,16
    80005a66:	8082                	ret

0000000080005a68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005a68:	1141                	addi	sp,sp,-16
    80005a6a:	e406                	sd	ra,8(sp)
    80005a6c:	e022                	sd	s0,0(sp)
    80005a6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005a70:	f9ffb0ef          	jal	ra,80001a0e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005a74:	00d5179b          	slliw	a5,a0,0xd
    80005a78:	0c201537          	lui	a0,0xc201
    80005a7c:	953e                	add	a0,a0,a5
  return irq;
}
    80005a7e:	4148                	lw	a0,4(a0)
    80005a80:	60a2                	ld	ra,8(sp)
    80005a82:	6402                	ld	s0,0(sp)
    80005a84:	0141                	addi	sp,sp,16
    80005a86:	8082                	ret

0000000080005a88 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005a88:	1101                	addi	sp,sp,-32
    80005a8a:	ec06                	sd	ra,24(sp)
    80005a8c:	e822                	sd	s0,16(sp)
    80005a8e:	e426                	sd	s1,8(sp)
    80005a90:	1000                	addi	s0,sp,32
    80005a92:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005a94:	f7bfb0ef          	jal	ra,80001a0e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005a98:	00d5151b          	slliw	a0,a0,0xd
    80005a9c:	0c2017b7          	lui	a5,0xc201
    80005aa0:	97aa                	add	a5,a5,a0
    80005aa2:	c3c4                	sw	s1,4(a5)
}
    80005aa4:	60e2                	ld	ra,24(sp)
    80005aa6:	6442                	ld	s0,16(sp)
    80005aa8:	64a2                	ld	s1,8(sp)
    80005aaa:	6105                	addi	sp,sp,32
    80005aac:	8082                	ret

0000000080005aae <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005aae:	1141                	addi	sp,sp,-16
    80005ab0:	e406                	sd	ra,8(sp)
    80005ab2:	e022                	sd	s0,0(sp)
    80005ab4:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ab6:	479d                	li	a5,7
    80005ab8:	04a7ca63          	blt	a5,a0,80005b0c <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005abc:	000a6797          	auipc	a5,0xa6
    80005ac0:	9fc78793          	addi	a5,a5,-1540 # 800ab4b8 <disk>
    80005ac4:	97aa                	add	a5,a5,a0
    80005ac6:	0187c783          	lbu	a5,24(a5)
    80005aca:	e7b9                	bnez	a5,80005b18 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005acc:	00451613          	slli	a2,a0,0x4
    80005ad0:	000a6797          	auipc	a5,0xa6
    80005ad4:	9e878793          	addi	a5,a5,-1560 # 800ab4b8 <disk>
    80005ad8:	6394                	ld	a3,0(a5)
    80005ada:	96b2                	add	a3,a3,a2
    80005adc:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ae0:	6398                	ld	a4,0(a5)
    80005ae2:	9732                	add	a4,a4,a2
    80005ae4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ae8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005aec:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005af0:	953e                	add	a0,a0,a5
    80005af2:	4785                	li	a5,1
    80005af4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005af8:	000a6517          	auipc	a0,0xa6
    80005afc:	9d850513          	addi	a0,a0,-1576 # 800ab4d0 <disk+0x18>
    80005b00:	ed0fc0ef          	jal	ra,800021d0 <wakeup>
}
    80005b04:	60a2                	ld	ra,8(sp)
    80005b06:	6402                	ld	s0,0(sp)
    80005b08:	0141                	addi	sp,sp,16
    80005b0a:	8082                	ret
    panic("free_desc 1");
    80005b0c:	00002517          	auipc	a0,0x2
    80005b10:	ccc50513          	addi	a0,a0,-820 # 800077d8 <syscalls+0x350>
    80005b14:	c77fa0ef          	jal	ra,8000078a <panic>
    panic("free_desc 2");
    80005b18:	00002517          	auipc	a0,0x2
    80005b1c:	cd050513          	addi	a0,a0,-816 # 800077e8 <syscalls+0x360>
    80005b20:	c6bfa0ef          	jal	ra,8000078a <panic>

0000000080005b24 <virtio_disk_init>:
{
    80005b24:	1101                	addi	sp,sp,-32
    80005b26:	ec06                	sd	ra,24(sp)
    80005b28:	e822                	sd	s0,16(sp)
    80005b2a:	e426                	sd	s1,8(sp)
    80005b2c:	e04a                	sd	s2,0(sp)
    80005b2e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005b30:	00002597          	auipc	a1,0x2
    80005b34:	cc858593          	addi	a1,a1,-824 # 800077f8 <syscalls+0x370>
    80005b38:	000a6517          	auipc	a0,0xa6
    80005b3c:	aa850513          	addi	a0,a0,-1368 # 800ab5e0 <disk+0x128>
    80005b40:	912fb0ef          	jal	ra,80000c52 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005b44:	100017b7          	lui	a5,0x10001
    80005b48:	4398                	lw	a4,0(a5)
    80005b4a:	2701                	sext.w	a4,a4
    80005b4c:	747277b7          	lui	a5,0x74727
    80005b50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005b54:	14f71063          	bne	a4,a5,80005c94 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005b58:	100017b7          	lui	a5,0x10001
    80005b5c:	43dc                	lw	a5,4(a5)
    80005b5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005b60:	4709                	li	a4,2
    80005b62:	12e79963          	bne	a5,a4,80005c94 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005b66:	100017b7          	lui	a5,0x10001
    80005b6a:	479c                	lw	a5,8(a5)
    80005b6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005b6e:	12e79363          	bne	a5,a4,80005c94 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005b72:	100017b7          	lui	a5,0x10001
    80005b76:	47d8                	lw	a4,12(a5)
    80005b78:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005b7a:	554d47b7          	lui	a5,0x554d4
    80005b7e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005b82:	10f71963          	bne	a4,a5,80005c94 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b86:	100017b7          	lui	a5,0x10001
    80005b8a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b8e:	4705                	li	a4,1
    80005b90:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b92:	470d                	li	a4,3
    80005b94:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005b96:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005b98:	c7ffe737          	lui	a4,0xc7ffe
    80005b9c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f53167>
    80005ba0:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ba2:	2701                	sext.w	a4,a4
    80005ba4:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ba6:	472d                	li	a4,11
    80005ba8:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005baa:	5bbc                	lw	a5,112(a5)
    80005bac:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005bb0:	8ba1                	andi	a5,a5,8
    80005bb2:	0e078763          	beqz	a5,80005ca0 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005bb6:	100017b7          	lui	a5,0x10001
    80005bba:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005bbe:	43fc                	lw	a5,68(a5)
    80005bc0:	2781                	sext.w	a5,a5
    80005bc2:	0e079563          	bnez	a5,80005cac <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005bc6:	100017b7          	lui	a5,0x10001
    80005bca:	5bdc                	lw	a5,52(a5)
    80005bcc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005bce:	0e078563          	beqz	a5,80005cb8 <virtio_disk_init+0x194>
  if(max < NUM)
    80005bd2:	471d                	li	a4,7
    80005bd4:	0ef77863          	bgeu	a4,a5,80005cc4 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    80005bd8:	f27fa0ef          	jal	ra,80000afe <kalloc>
    80005bdc:	000a6497          	auipc	s1,0xa6
    80005be0:	8dc48493          	addi	s1,s1,-1828 # 800ab4b8 <disk>
    80005be4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005be6:	f19fa0ef          	jal	ra,80000afe <kalloc>
    80005bea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005bec:	f13fa0ef          	jal	ra,80000afe <kalloc>
    80005bf0:	87aa                	mv	a5,a0
    80005bf2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005bf4:	6088                	ld	a0,0(s1)
    80005bf6:	cd69                	beqz	a0,80005cd0 <virtio_disk_init+0x1ac>
    80005bf8:	000a6717          	auipc	a4,0xa6
    80005bfc:	8c873703          	ld	a4,-1848(a4) # 800ab4c0 <disk+0x8>
    80005c00:	cb61                	beqz	a4,80005cd0 <virtio_disk_init+0x1ac>
    80005c02:	c7f9                	beqz	a5,80005cd0 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    80005c04:	6605                	lui	a2,0x1
    80005c06:	4581                	li	a1,0
    80005c08:	99efb0ef          	jal	ra,80000da6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005c0c:	000a6497          	auipc	s1,0xa6
    80005c10:	8ac48493          	addi	s1,s1,-1876 # 800ab4b8 <disk>
    80005c14:	6605                	lui	a2,0x1
    80005c16:	4581                	li	a1,0
    80005c18:	6488                	ld	a0,8(s1)
    80005c1a:	98cfb0ef          	jal	ra,80000da6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005c1e:	6605                	lui	a2,0x1
    80005c20:	4581                	li	a1,0
    80005c22:	6888                	ld	a0,16(s1)
    80005c24:	982fb0ef          	jal	ra,80000da6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005c28:	100017b7          	lui	a5,0x10001
    80005c2c:	4721                	li	a4,8
    80005c2e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005c30:	4098                	lw	a4,0(s1)
    80005c32:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005c36:	40d8                	lw	a4,4(s1)
    80005c38:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005c3c:	6498                	ld	a4,8(s1)
    80005c3e:	0007069b          	sext.w	a3,a4
    80005c42:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005c46:	9701                	srai	a4,a4,0x20
    80005c48:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005c4c:	6898                	ld	a4,16(s1)
    80005c4e:	0007069b          	sext.w	a3,a4
    80005c52:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005c56:	9701                	srai	a4,a4,0x20
    80005c58:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005c5c:	4705                	li	a4,1
    80005c5e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005c60:	00e48c23          	sb	a4,24(s1)
    80005c64:	00e48ca3          	sb	a4,25(s1)
    80005c68:	00e48d23          	sb	a4,26(s1)
    80005c6c:	00e48da3          	sb	a4,27(s1)
    80005c70:	00e48e23          	sb	a4,28(s1)
    80005c74:	00e48ea3          	sb	a4,29(s1)
    80005c78:	00e48f23          	sb	a4,30(s1)
    80005c7c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005c80:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c84:	0727a823          	sw	s2,112(a5)
}
    80005c88:	60e2                	ld	ra,24(sp)
    80005c8a:	6442                	ld	s0,16(sp)
    80005c8c:	64a2                	ld	s1,8(sp)
    80005c8e:	6902                	ld	s2,0(sp)
    80005c90:	6105                	addi	sp,sp,32
    80005c92:	8082                	ret
    panic("could not find virtio disk");
    80005c94:	00002517          	auipc	a0,0x2
    80005c98:	b7450513          	addi	a0,a0,-1164 # 80007808 <syscalls+0x380>
    80005c9c:	aeffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ca0:	00002517          	auipc	a0,0x2
    80005ca4:	b8850513          	addi	a0,a0,-1144 # 80007828 <syscalls+0x3a0>
    80005ca8:	ae3fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk should not be ready");
    80005cac:	00002517          	auipc	a0,0x2
    80005cb0:	b9c50513          	addi	a0,a0,-1124 # 80007848 <syscalls+0x3c0>
    80005cb4:	ad7fa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk has no queue 0");
    80005cb8:	00002517          	auipc	a0,0x2
    80005cbc:	bb050513          	addi	a0,a0,-1104 # 80007868 <syscalls+0x3e0>
    80005cc0:	acbfa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk max queue too short");
    80005cc4:	00002517          	auipc	a0,0x2
    80005cc8:	bc450513          	addi	a0,a0,-1084 # 80007888 <syscalls+0x400>
    80005ccc:	abffa0ef          	jal	ra,8000078a <panic>
    panic("virtio disk kalloc");
    80005cd0:	00002517          	auipc	a0,0x2
    80005cd4:	bd850513          	addi	a0,a0,-1064 # 800078a8 <syscalls+0x420>
    80005cd8:	ab3fa0ef          	jal	ra,8000078a <panic>

0000000080005cdc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005cdc:	7119                	addi	sp,sp,-128
    80005cde:	fc86                	sd	ra,120(sp)
    80005ce0:	f8a2                	sd	s0,112(sp)
    80005ce2:	f4a6                	sd	s1,104(sp)
    80005ce4:	f0ca                	sd	s2,96(sp)
    80005ce6:	ecce                	sd	s3,88(sp)
    80005ce8:	e8d2                	sd	s4,80(sp)
    80005cea:	e4d6                	sd	s5,72(sp)
    80005cec:	e0da                	sd	s6,64(sp)
    80005cee:	fc5e                	sd	s7,56(sp)
    80005cf0:	f862                	sd	s8,48(sp)
    80005cf2:	f466                	sd	s9,40(sp)
    80005cf4:	f06a                	sd	s10,32(sp)
    80005cf6:	ec6e                	sd	s11,24(sp)
    80005cf8:	0100                	addi	s0,sp,128
    80005cfa:	8aaa                	mv	s5,a0
    80005cfc:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005cfe:	00c52d03          	lw	s10,12(a0)
    80005d02:	001d1d1b          	slliw	s10,s10,0x1
    80005d06:	1d02                	slli	s10,s10,0x20
    80005d08:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005d0c:	000a6517          	auipc	a0,0xa6
    80005d10:	8d450513          	addi	a0,a0,-1836 # 800ab5e0 <disk+0x128>
    80005d14:	fbffa0ef          	jal	ra,80000cd2 <acquire>
  for(int i = 0; i < 3; i++){
    80005d18:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005d1a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005d1c:	000a5b97          	auipc	s7,0xa5
    80005d20:	79cb8b93          	addi	s7,s7,1948 # 800ab4b8 <disk>
  for(int i = 0; i < 3; i++){
    80005d24:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005d26:	000a6c97          	auipc	s9,0xa6
    80005d2a:	8bac8c93          	addi	s9,s9,-1862 # 800ab5e0 <disk+0x128>
    80005d2e:	a8a9                	j	80005d88 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005d30:	00fb8733          	add	a4,s7,a5
    80005d34:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005d38:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005d3a:	0207c563          	bltz	a5,80005d64 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005d3e:	2905                	addiw	s2,s2,1
    80005d40:	0611                	addi	a2,a2,4
    80005d42:	05690863          	beq	s2,s6,80005d92 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005d46:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005d48:	000a5717          	auipc	a4,0xa5
    80005d4c:	77070713          	addi	a4,a4,1904 # 800ab4b8 <disk>
    80005d50:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005d52:	01874683          	lbu	a3,24(a4)
    80005d56:	fee9                	bnez	a3,80005d30 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005d58:	2785                	addiw	a5,a5,1
    80005d5a:	0705                	addi	a4,a4,1
    80005d5c:	fe979be3          	bne	a5,s1,80005d52 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005d60:	57fd                	li	a5,-1
    80005d62:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005d64:	01205b63          	blez	s2,80005d7a <virtio_disk_rw+0x9e>
    80005d68:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005d6a:	000a2503          	lw	a0,0(s4)
    80005d6e:	d41ff0ef          	jal	ra,80005aae <free_desc>
      for(int j = 0; j < i; j++)
    80005d72:	2d85                	addiw	s11,s11,1
    80005d74:	0a11                	addi	s4,s4,4
    80005d76:	ffb91ae3          	bne	s2,s11,80005d6a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005d7a:	85e6                	mv	a1,s9
    80005d7c:	000a5517          	auipc	a0,0xa5
    80005d80:	75450513          	addi	a0,a0,1876 # 800ab4d0 <disk+0x18>
    80005d84:	c00fc0ef          	jal	ra,80002184 <sleep>
  for(int i = 0; i < 3; i++){
    80005d88:	f8040a13          	addi	s4,s0,-128
{
    80005d8c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005d8e:	894e                	mv	s2,s3
    80005d90:	bf5d                	j	80005d46 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005d92:	f8042583          	lw	a1,-128(s0)
    80005d96:	00a58793          	addi	a5,a1,10
    80005d9a:	0792                	slli	a5,a5,0x4

  if(write)
    80005d9c:	000a5617          	auipc	a2,0xa5
    80005da0:	71c60613          	addi	a2,a2,1820 # 800ab4b8 <disk>
    80005da4:	00f60733          	add	a4,a2,a5
    80005da8:	018036b3          	snez	a3,s8
    80005dac:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005dae:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005db2:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005db6:	f6078693          	addi	a3,a5,-160
    80005dba:	6218                	ld	a4,0(a2)
    80005dbc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005dbe:	00878513          	addi	a0,a5,8
    80005dc2:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005dc4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005dc6:	6208                	ld	a0,0(a2)
    80005dc8:	96aa                	add	a3,a3,a0
    80005dca:	4741                	li	a4,16
    80005dcc:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005dce:	4705                	li	a4,1
    80005dd0:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80005dd4:	f8442703          	lw	a4,-124(s0)
    80005dd8:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005ddc:	0712                	slli	a4,a4,0x4
    80005dde:	953a                	add	a0,a0,a4
    80005de0:	058a8693          	addi	a3,s5,88
    80005de4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80005de6:	6208                	ld	a0,0(a2)
    80005de8:	972a                	add	a4,a4,a0
    80005dea:	40000693          	li	a3,1024
    80005dee:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80005df0:	001c3c13          	seqz	s8,s8
    80005df4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005df6:	001c6c13          	ori	s8,s8,1
    80005dfa:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005dfe:	f8842603          	lw	a2,-120(s0)
    80005e02:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005e06:	000a5697          	auipc	a3,0xa5
    80005e0a:	6b268693          	addi	a3,a3,1714 # 800ab4b8 <disk>
    80005e0e:	00258713          	addi	a4,a1,2
    80005e12:	0712                	slli	a4,a4,0x4
    80005e14:	9736                	add	a4,a4,a3
    80005e16:	587d                	li	a6,-1
    80005e18:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005e1c:	0612                	slli	a2,a2,0x4
    80005e1e:	9532                	add	a0,a0,a2
    80005e20:	f9078793          	addi	a5,a5,-112
    80005e24:	97b6                	add	a5,a5,a3
    80005e26:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005e28:	629c                	ld	a5,0(a3)
    80005e2a:	97b2                	add	a5,a5,a2
    80005e2c:	4605                	li	a2,1
    80005e2e:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005e30:	4509                	li	a0,2
    80005e32:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80005e36:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005e3a:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005e3e:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005e42:	6698                	ld	a4,8(a3)
    80005e44:	00275783          	lhu	a5,2(a4)
    80005e48:	8b9d                	andi	a5,a5,7
    80005e4a:	0786                	slli	a5,a5,0x1
    80005e4c:	97ba                	add	a5,a5,a4
    80005e4e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005e52:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005e56:	6698                	ld	a4,8(a3)
    80005e58:	00275783          	lhu	a5,2(a4)
    80005e5c:	2785                	addiw	a5,a5,1
    80005e5e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005e62:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005e66:	100017b7          	lui	a5,0x10001
    80005e6a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005e6e:	004aa783          	lw	a5,4(s5)
    80005e72:	00c79f63          	bne	a5,a2,80005e90 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005e76:	000a5917          	auipc	s2,0xa5
    80005e7a:	76a90913          	addi	s2,s2,1898 # 800ab5e0 <disk+0x128>
  while(b->disk == 1) {
    80005e7e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005e80:	85ca                	mv	a1,s2
    80005e82:	8556                	mv	a0,s5
    80005e84:	b00fc0ef          	jal	ra,80002184 <sleep>
  while(b->disk == 1) {
    80005e88:	004aa783          	lw	a5,4(s5)
    80005e8c:	fe978ae3          	beq	a5,s1,80005e80 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005e90:	f8042903          	lw	s2,-128(s0)
    80005e94:	00290793          	addi	a5,s2,2
    80005e98:	00479713          	slli	a4,a5,0x4
    80005e9c:	000a5797          	auipc	a5,0xa5
    80005ea0:	61c78793          	addi	a5,a5,1564 # 800ab4b8 <disk>
    80005ea4:	97ba                	add	a5,a5,a4
    80005ea6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005eaa:	000a5997          	auipc	s3,0xa5
    80005eae:	60e98993          	addi	s3,s3,1550 # 800ab4b8 <disk>
    80005eb2:	00491713          	slli	a4,s2,0x4
    80005eb6:	0009b783          	ld	a5,0(s3)
    80005eba:	97ba                	add	a5,a5,a4
    80005ebc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005ec6:	be9ff0ef          	jal	ra,80005aae <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005eca:	8885                	andi	s1,s1,1
    80005ecc:	f0fd                	bnez	s1,80005eb2 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005ece:	000a5517          	auipc	a0,0xa5
    80005ed2:	71250513          	addi	a0,a0,1810 # 800ab5e0 <disk+0x128>
    80005ed6:	e95fa0ef          	jal	ra,80000d6a <release>
}
    80005eda:	70e6                	ld	ra,120(sp)
    80005edc:	7446                	ld	s0,112(sp)
    80005ede:	74a6                	ld	s1,104(sp)
    80005ee0:	7906                	ld	s2,96(sp)
    80005ee2:	69e6                	ld	s3,88(sp)
    80005ee4:	6a46                	ld	s4,80(sp)
    80005ee6:	6aa6                	ld	s5,72(sp)
    80005ee8:	6b06                	ld	s6,64(sp)
    80005eea:	7be2                	ld	s7,56(sp)
    80005eec:	7c42                	ld	s8,48(sp)
    80005eee:	7ca2                	ld	s9,40(sp)
    80005ef0:	7d02                	ld	s10,32(sp)
    80005ef2:	6de2                	ld	s11,24(sp)
    80005ef4:	6109                	addi	sp,sp,128
    80005ef6:	8082                	ret

0000000080005ef8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005ef8:	1101                	addi	sp,sp,-32
    80005efa:	ec06                	sd	ra,24(sp)
    80005efc:	e822                	sd	s0,16(sp)
    80005efe:	e426                	sd	s1,8(sp)
    80005f00:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005f02:	000a5497          	auipc	s1,0xa5
    80005f06:	5b648493          	addi	s1,s1,1462 # 800ab4b8 <disk>
    80005f0a:	000a5517          	auipc	a0,0xa5
    80005f0e:	6d650513          	addi	a0,a0,1750 # 800ab5e0 <disk+0x128>
    80005f12:	dc1fa0ef          	jal	ra,80000cd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005f16:	10001737          	lui	a4,0x10001
    80005f1a:	533c                	lw	a5,96(a4)
    80005f1c:	8b8d                	andi	a5,a5,3
    80005f1e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005f20:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005f24:	689c                	ld	a5,16(s1)
    80005f26:	0204d703          	lhu	a4,32(s1)
    80005f2a:	0027d783          	lhu	a5,2(a5)
    80005f2e:	04f70663          	beq	a4,a5,80005f7a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005f32:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005f36:	6898                	ld	a4,16(s1)
    80005f38:	0204d783          	lhu	a5,32(s1)
    80005f3c:	8b9d                	andi	a5,a5,7
    80005f3e:	078e                	slli	a5,a5,0x3
    80005f40:	97ba                	add	a5,a5,a4
    80005f42:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005f44:	00278713          	addi	a4,a5,2
    80005f48:	0712                	slli	a4,a4,0x4
    80005f4a:	9726                	add	a4,a4,s1
    80005f4c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005f50:	e321                	bnez	a4,80005f90 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005f52:	0789                	addi	a5,a5,2
    80005f54:	0792                	slli	a5,a5,0x4
    80005f56:	97a6                	add	a5,a5,s1
    80005f58:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005f5a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005f5e:	a72fc0ef          	jal	ra,800021d0 <wakeup>

    disk.used_idx += 1;
    80005f62:	0204d783          	lhu	a5,32(s1)
    80005f66:	2785                	addiw	a5,a5,1
    80005f68:	17c2                	slli	a5,a5,0x30
    80005f6a:	93c1                	srli	a5,a5,0x30
    80005f6c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005f70:	6898                	ld	a4,16(s1)
    80005f72:	00275703          	lhu	a4,2(a4)
    80005f76:	faf71ee3          	bne	a4,a5,80005f32 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    80005f7a:	000a5517          	auipc	a0,0xa5
    80005f7e:	66650513          	addi	a0,a0,1638 # 800ab5e0 <disk+0x128>
    80005f82:	de9fa0ef          	jal	ra,80000d6a <release>
}
    80005f86:	60e2                	ld	ra,24(sp)
    80005f88:	6442                	ld	s0,16(sp)
    80005f8a:	64a2                	ld	s1,8(sp)
    80005f8c:	6105                	addi	sp,sp,32
    80005f8e:	8082                	ret
      panic("virtio_disk_intr status");
    80005f90:	00002517          	auipc	a0,0x2
    80005f94:	93050513          	addi	a0,a0,-1744 # 800078c0 <syscalls+0x438>
    80005f98:	ff2fa0ef          	jal	ra,8000078a <panic>
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
