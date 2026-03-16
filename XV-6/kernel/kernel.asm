
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	17813103          	ld	sp,376(sp) # 8000a178 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000016:	04a000ef          	jal	80000060 <start>

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
    80000056:	14d79073          	csrw	stimecmp,a5
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb327>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	e0478793          	addi	a5,a5,-508 # 80000e84 <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
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
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
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
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	1b4020ef          	jal	800022c6 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	03450513          	addi	a0,a0,52 # 800121c0 <cons>
    80000194:	283000ef          	jal	80000c16 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	02848493          	addi	s1,s1,40 # 800121c0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	0b890913          	addi	s2,s2,184 # 80012258 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	75e010ef          	jal	80001916 <myproc>
    800001bc:	79d010ef          	jal	80002158 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	55b010ef          	jal	80001f20 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00012717          	auipc	a4,0x12
    800001dc:	fe870713          	addi	a4,a4,-24 # 800121c0 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	072020ef          	jal	8000227c <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00012517          	auipc	a0,0x12
    80000226:	f9e50513          	addi	a0,a0,-98 # 800121c0 <cons>
    8000022a:	285000ef          	jal	80000cae <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00012717          	auipc	a4,0x12
    80000250:	00f72623          	sw	a5,12(a4) # 80012258 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00012517          	auipc	a0,0x12
    80000266:	f5e50513          	addi	a0,a0,-162 # 800121c0 <cons>
    8000026a:	245000ef          	jal	80000cae <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00012517          	auipc	a0,0x12
    800002ba:	f0a50513          	addi	a0,a0,-246 # 800121c0 <cons>
    800002be:	159000ef          	jal	80000c16 <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	038020ef          	jal	80002310 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	ee450513          	addi	a0,a0,-284 # 800121c0 <cons>
    800002e4:	1cb000ef          	jal	80000cae <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00012717          	auipc	a4,0x12
    800002fe:	ec670713          	addi	a4,a4,-314 # 800121c0 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00012797          	auipc	a5,0x12
    80000324:	ea078793          	addi	a5,a5,-352 # 800121c0 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	f0a7a783          	lw	a5,-246(a5) # 80012258 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00012717          	auipc	a4,0x12
    80000368:	e5c70713          	addi	a4,a4,-420 # 800121c0 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00012497          	auipc	s1,0x12
    80000378:	e4c48493          	addi	s1,s1,-436 # 800121c0 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00012717          	auipc	a4,0x12
    800003ba:	e0a70713          	addi	a4,a4,-502 # 800121c0 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00012717          	auipc	a4,0x12
    800003d0:	e8f72a23          	sw	a5,-364(a4) # 80012260 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00012797          	auipc	a5,0x12
    800003ee:	dd678793          	addi	a5,a5,-554 # 800121c0 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00012797          	auipc	a5,0x12
    80000412:	e4c7a723          	sw	a2,-434(a5) # 8001225c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00012517          	auipc	a0,0x12
    8000041a:	e4250513          	addi	a0,a0,-446 # 80012258 <cons+0x98>
    8000041e:	34f010ef          	jal	80001f6c <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	00012517          	auipc	a0,0x12
    80000438:	d8c50513          	addi	a0,a0,-628 # 800121c0 <cons>
    8000043c:	75a000ef          	jal	80000b96 <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00022797          	auipc	a5,0x22
    80000448:	efc78793          	addi	a5,a5,-260 # 80022340 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	29260613          	addi	a2,a2,658 # 80007710 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	c7c7a783          	lw	a5,-900(a5) # 8000a194 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	d0850513          	addi	a0,a0,-760 # 80012268 <pr>
    80000568:	6ae000ef          	jal	80000c16 <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	fe8b8b93          	addi	s7,s7,-24 # 80007710 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000a797          	auipc	a5,0xa
    800007c0:	9d87a783          	lw	a5,-1576(a5) # 8000a194 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00012517          	auipc	a0,0x12
    800007d6:	a9650513          	addi	a0,a0,-1386 # 80012268 <pr>
    800007da:	4d4000ef          	jal	80000cae <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000a797          	auipc	a5,0xa
    800007f4:	9b27a223          	sw	s2,-1628(a5) # 8000a194 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000a797          	auipc	a5,0xa
    80000816:	9727af23          	sw	s2,-1666(a5) # 8000a190 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	00012517          	auipc	a0,0x12
    80000830:	a3c50513          	addi	a0,a0,-1476 # 80012268 <pr>
    80000834:	362000ef          	jal	80000b96 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	00012517          	auipc	a0,0x12
    80000888:	9fc50513          	addi	a0,a0,-1540 # 80012280 <tx_lock>
    8000088c:	30a000ef          	jal	80000b96 <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00012517          	auipc	a0,0x12
    800008ac:	9d850513          	addi	a0,a0,-1576 # 80012280 <tx_lock>
    800008b0:	366000ef          	jal	80000c16 <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000a497          	auipc	s1,0xa
    800008ca:	8d648493          	addi	s1,s1,-1834 # 8000a19c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00012997          	auipc	s3,0x12
    800008d2:	9b298993          	addi	s3,s3,-1614 # 80012280 <tx_lock>
    800008d6:	0000a917          	auipc	s2,0xa
    800008da:	8c290913          	addi	s2,s2,-1854 # 8000a198 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	636010ef          	jal	80001f20 <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00012517          	auipc	a0,0x12
    80000918:	96c50513          	addi	a0,a0,-1684 # 80012280 <tx_lock>
    8000091c:	392000ef          	jal	80000cae <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000a797          	auipc	a5,0xa
    8000093c:	85c7a783          	lw	a5,-1956(a5) # 8000a194 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000a797          	auipc	a5,0xa
    80000946:	84e7a783          	lw	a5,-1970(a5) # 8000a190 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000a797          	auipc	a5,0xa
    8000096c:	82c7a783          	lw	a5,-2004(a5) # 8000a194 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	25a000ef          	jal	80000bd6 <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	2d6000ef          	jal	80000c5a <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00012517          	auipc	a0,0x12
    800009c8:	8bc50513          	addi	a0,a0,-1860 # 80012280 <tx_lock>
    800009cc:	24a000ef          	jal	80000c16 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00012517          	auipc	a0,0x12
    800009e4:	8a050513          	addi	a0,a0,-1888 # 80012280 <tx_lock>
    800009e8:	2c6000ef          	jal	80000cae <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	00009797          	auipc	a5,0x9
    800009f4:	7a07a623          	sw	zero,1964(a5) # 8000a19c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	00009517          	auipc	a0,0x9
    800009fc:	7a050513          	addi	a0,a0,1952 # 8000a198 <tx_chan>
    80000a00:	56c010ef          	jal	80001f6c <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	efb9                	bnez	a5,80000a8a <kfree+0x6e>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00023797          	auipc	a5,0x23
    80000a34:	aa878793          	addi	a5,a5,-1368 # 800234d8 <end>
    80000a38:	04f56963          	bltu	a0,a5,80000a8a <kfree+0x6e>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	04f57563          	bgeu	a0,a5,80000a8a <kfree+0x6e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	2a2000ef          	jal	80000cea <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00012917          	auipc	s2,0x12
    80000a50:	84c90913          	addi	s2,s2,-1972 # 80012298 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	1c0000ef          	jal	80000c16 <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  memstat.free_pages++;
    80000a64:	02492783          	lw	a5,36(s2)
    80000a68:	2785                	addiw	a5,a5,1
    80000a6a:	02f92223          	sw	a5,36(s2)
  memstat.allocated_pages--;
    80000a6e:	02892783          	lw	a5,40(s2)
    80000a72:	37fd                	addiw	a5,a5,-1
    80000a74:	02f92423          	sw	a5,40(s2)
  release(&kmem.lock);
    80000a78:	854a                	mv	a0,s2
    80000a7a:	234000ef          	jal	80000cae <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00006517          	auipc	a0,0x6
    80000a8e:	5ae50513          	addi	a0,a0,1454 # 80007038 <etext+0x38>
    80000a92:	d4fff0ef          	jal	800007e0 <panic>

0000000080000a96 <freerange>:
{
    80000a96:	7139                	addi	sp,sp,-64
    80000a98:	fc06                	sd	ra,56(sp)
    80000a9a:	f822                	sd	s0,48(sp)
    80000a9c:	f426                	sd	s1,40(sp)
    80000a9e:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aa0:	6785                	lui	a5,0x1
    80000aa2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aa6:	00e504b3          	add	s1,a0,a4
    80000aaa:	777d                	lui	a4,0xfffff
    80000aac:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	94be                	add	s1,s1,a5
    80000ab0:	0295ed63          	bltu	a1,s1,80000aea <freerange+0x54>
    80000ab4:	f04a                	sd	s2,32(sp)
    80000ab6:	ec4e                	sd	s3,24(sp)
    80000ab8:	e852                	sd	s4,16(sp)
    80000aba:	e456                	sd	s5,8(sp)
    80000abc:	89ae                	mv	s3,a1
  { memstat.total_pages++;
    80000abe:	00011917          	auipc	s2,0x11
    80000ac2:	7da90913          	addi	s2,s2,2010 # 80012298 <kmem>
    kfree(p);
    80000ac6:	7afd                	lui	s5,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac8:	6a05                	lui	s4,0x1
  { memstat.total_pages++;
    80000aca:	02092783          	lw	a5,32(s2)
    80000ace:	2785                	addiw	a5,a5,1
    80000ad0:	02f92023          	sw	a5,32(s2)
    kfree(p);
    80000ad4:	01548533          	add	a0,s1,s5
    80000ad8:	f45ff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	94d2                	add	s1,s1,s4
    80000ade:	fe99f6e3          	bgeu	s3,s1,80000aca <freerange+0x34>
    80000ae2:	7902                	ld	s2,32(sp)
    80000ae4:	69e2                	ld	s3,24(sp)
    80000ae6:	6a42                	ld	s4,16(sp)
    80000ae8:	6aa2                	ld	s5,8(sp)
}
    80000aea:	70e2                	ld	ra,56(sp)
    80000aec:	7442                	ld	s0,48(sp)
    80000aee:	74a2                	ld	s1,40(sp)
    80000af0:	6121                	addi	sp,sp,64
    80000af2:	8082                	ret

0000000080000af4 <kinit>:
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  initlock(&kmem.lock, "kmem");
    80000afe:	00011497          	auipc	s1,0x11
    80000b02:	79a48493          	addi	s1,s1,1946 # 80012298 <kmem>
    80000b06:	00006597          	auipc	a1,0x6
    80000b0a:	53a58593          	addi	a1,a1,1338 # 80007040 <etext+0x40>
    80000b0e:	8526                	mv	a0,s1
    80000b10:	086000ef          	jal	80000b96 <initlock>
  memstat.total_pages = 0;
    80000b14:	0204a023          	sw	zero,32(s1)
  memstat.free_pages = 0;
    80000b18:	0204a223          	sw	zero,36(s1)
  memstat.allocated_pages = 0;
    80000b1c:	0204a423          	sw	zero,40(s1)
  freerange(end, (void*)PHYSTOP);
    80000b20:	45c5                	li	a1,17
    80000b22:	05ee                	slli	a1,a1,0x1b
    80000b24:	00023517          	auipc	a0,0x23
    80000b28:	9b450513          	addi	a0,a0,-1612 # 800234d8 <end>
    80000b2c:	f6bff0ef          	jal	80000a96 <freerange>
}
    80000b30:	60e2                	ld	ra,24(sp)
    80000b32:	6442                	ld	s0,16(sp)
    80000b34:	64a2                	ld	s1,8(sp)
    80000b36:	6105                	addi	sp,sp,32
    80000b38:	8082                	ret

0000000080000b3a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b3a:	1101                	addi	sp,sp,-32
    80000b3c:	ec06                	sd	ra,24(sp)
    80000b3e:	e822                	sd	s0,16(sp)
    80000b40:	e426                	sd	s1,8(sp)
    80000b42:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b44:	00011497          	auipc	s1,0x11
    80000b48:	75448493          	addi	s1,s1,1876 # 80012298 <kmem>
    80000b4c:	8526                	mv	a0,s1
    80000b4e:	0c8000ef          	jal	80000c16 <acquire>
  r = kmem.freelist;
    80000b52:	6c84                	ld	s1,24(s1)
  if(r)
    80000b54:	c895                	beqz	s1,80000b88 <kalloc+0x4e>
  {kmem.freelist = r->next;
    80000b56:	609c                	ld	a5,0(s1)
    80000b58:	00011517          	auipc	a0,0x11
    80000b5c:	74050513          	addi	a0,a0,1856 # 80012298 <kmem>
    80000b60:	ed1c                	sd	a5,24(a0)
   memstat.free_pages--;
    80000b62:	515c                	lw	a5,36(a0)
    80000b64:	37fd                	addiw	a5,a5,-1
    80000b66:	d15c                	sw	a5,36(a0)
   memstat.allocated_pages++;
    80000b68:	551c                	lw	a5,40(a0)
    80000b6a:	2785                	addiw	a5,a5,1
    80000b6c:	d51c                	sw	a5,40(a0)
  }
  release(&kmem.lock);
    80000b6e:	140000ef          	jal	80000cae <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b72:	6605                	lui	a2,0x1
    80000b74:	4595                	li	a1,5
    80000b76:	8526                	mv	a0,s1
    80000b78:	172000ef          	jal	80000cea <memset>
  return (void*)r;
}
    80000b7c:	8526                	mv	a0,s1
    80000b7e:	60e2                	ld	ra,24(sp)
    80000b80:	6442                	ld	s0,16(sp)
    80000b82:	64a2                	ld	s1,8(sp)
    80000b84:	6105                	addi	sp,sp,32
    80000b86:	8082                	ret
  release(&kmem.lock);
    80000b88:	00011517          	auipc	a0,0x11
    80000b8c:	71050513          	addi	a0,a0,1808 # 80012298 <kmem>
    80000b90:	11e000ef          	jal	80000cae <release>
  if(r)
    80000b94:	b7e5                	j	80000b7c <kalloc+0x42>

0000000080000b96 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b96:	1141                	addi	sp,sp,-16
    80000b98:	e422                	sd	s0,8(sp)
    80000b9a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b9c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b9e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000ba2:	00053823          	sd	zero,16(a0)
}
    80000ba6:	6422                	ld	s0,8(sp)
    80000ba8:	0141                	addi	sp,sp,16
    80000baa:	8082                	ret

0000000080000bac <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bac:	411c                	lw	a5,0(a0)
    80000bae:	e399                	bnez	a5,80000bb4 <holding+0x8>
    80000bb0:	4501                	li	a0,0
  return r;
}
    80000bb2:	8082                	ret
{
    80000bb4:	1101                	addi	sp,sp,-32
    80000bb6:	ec06                	sd	ra,24(sp)
    80000bb8:	e822                	sd	s0,16(sp)
    80000bba:	e426                	sd	s1,8(sp)
    80000bbc:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	6904                	ld	s1,16(a0)
    80000bc0:	53b000ef          	jal	800018fa <mycpu>
    80000bc4:	40a48533          	sub	a0,s1,a0
    80000bc8:	00153513          	seqz	a0,a0
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6105                	addi	sp,sp,32
    80000bd4:	8082                	ret

0000000080000bd6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be0:	100024f3          	csrr	s1,sstatus
    80000be4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bea:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000bee:	50d000ef          	jal	800018fa <mycpu>
    80000bf2:	5d3c                	lw	a5,120(a0)
    80000bf4:	cb99                	beqz	a5,80000c0a <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf6:	505000ef          	jal	800018fa <mycpu>
    80000bfa:	5d3c                	lw	a5,120(a0)
    80000bfc:	2785                	addiw	a5,a5,1
    80000bfe:	dd3c                	sw	a5,120(a0)
}
    80000c00:	60e2                	ld	ra,24(sp)
    80000c02:	6442                	ld	s0,16(sp)
    80000c04:	64a2                	ld	s1,8(sp)
    80000c06:	6105                	addi	sp,sp,32
    80000c08:	8082                	ret
    mycpu()->intena = old;
    80000c0a:	4f1000ef          	jal	800018fa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c0e:	8085                	srli	s1,s1,0x1
    80000c10:	8885                	andi	s1,s1,1
    80000c12:	dd64                	sw	s1,124(a0)
    80000c14:	b7cd                	j	80000bf6 <push_off+0x20>

0000000080000c16 <acquire>:
{
    80000c16:	1101                	addi	sp,sp,-32
    80000c18:	ec06                	sd	ra,24(sp)
    80000c1a:	e822                	sd	s0,16(sp)
    80000c1c:	e426                	sd	s1,8(sp)
    80000c1e:	1000                	addi	s0,sp,32
    80000c20:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c22:	fb5ff0ef          	jal	80000bd6 <push_off>
  if(holding(lk))
    80000c26:	8526                	mv	a0,s1
    80000c28:	f85ff0ef          	jal	80000bac <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2c:	4705                	li	a4,1
  if(holding(lk))
    80000c2e:	e105                	bnez	a0,80000c4e <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c30:	87ba                	mv	a5,a4
    80000c32:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c36:	2781                	sext.w	a5,a5
    80000c38:	ffe5                	bnez	a5,80000c30 <acquire+0x1a>
  __sync_synchronize();
    80000c3a:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000c3e:	4bd000ef          	jal	800018fa <mycpu>
    80000c42:	e888                	sd	a0,16(s1)
}
    80000c44:	60e2                	ld	ra,24(sp)
    80000c46:	6442                	ld	s0,16(sp)
    80000c48:	64a2                	ld	s1,8(sp)
    80000c4a:	6105                	addi	sp,sp,32
    80000c4c:	8082                	ret
    panic("acquire");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	3fa50513          	addi	a0,a0,1018 # 80007048 <etext+0x48>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>

0000000080000c5a <pop_off>:

void
pop_off(void)
{
    80000c5a:	1141                	addi	sp,sp,-16
    80000c5c:	e406                	sd	ra,8(sp)
    80000c5e:	e022                	sd	s0,0(sp)
    80000c60:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c62:	499000ef          	jal	800018fa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c6a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c6c:	e78d                	bnez	a5,80000c96 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6e:	5d3c                	lw	a5,120(a0)
    80000c70:	02f05963          	blez	a5,80000ca2 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c74:	37fd                	addiw	a5,a5,-1
    80000c76:	0007871b          	sext.w	a4,a5
    80000c7a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c7c:	eb09                	bnez	a4,80000c8e <pop_off+0x34>
    80000c7e:	5d7c                	lw	a5,124(a0)
    80000c80:	c799                	beqz	a5,80000c8e <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c82:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c86:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c8a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8e:	60a2                	ld	ra,8(sp)
    80000c90:	6402                	ld	s0,0(sp)
    80000c92:	0141                	addi	sp,sp,16
    80000c94:	8082                	ret
    panic("pop_off - interruptible");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3ba50513          	addi	a0,a0,954 # 80007050 <etext+0x50>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000ca2:	00006517          	auipc	a0,0x6
    80000ca6:	3c650513          	addi	a0,a0,966 # 80007068 <etext+0x68>
    80000caa:	b37ff0ef          	jal	800007e0 <panic>

0000000080000cae <release>:
{
    80000cae:	1101                	addi	sp,sp,-32
    80000cb0:	ec06                	sd	ra,24(sp)
    80000cb2:	e822                	sd	s0,16(sp)
    80000cb4:	e426                	sd	s1,8(sp)
    80000cb6:	1000                	addi	s0,sp,32
    80000cb8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cba:	ef3ff0ef          	jal	80000bac <holding>
    80000cbe:	c105                	beqz	a0,80000cde <release+0x30>
  lk->cpu = 0;
    80000cc0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc4:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000cc8:	0310000f          	fence	rw,w
    80000ccc:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000cd0:	f8bff0ef          	jal	80000c5a <pop_off>
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret
    panic("release");
    80000cde:	00006517          	auipc	a0,0x6
    80000ce2:	39250513          	addi	a0,a0,914 # 80007070 <etext+0x70>
    80000ce6:	afbff0ef          	jal	800007e0 <panic>

0000000080000cea <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cea:	1141                	addi	sp,sp,-16
    80000cec:	e422                	sd	s0,8(sp)
    80000cee:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cf0:	ca19                	beqz	a2,80000d06 <memset+0x1c>
    80000cf2:	87aa                	mv	a5,a0
    80000cf4:	1602                	slli	a2,a2,0x20
    80000cf6:	9201                	srli	a2,a2,0x20
    80000cf8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x12>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	c205                	beqz	a2,80000d6c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	02a5e263          	bltu	a1,a0,80000d72 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d52:	1602                	slli	a2,a2,0x20
    80000d54:	9201                	srli	a2,a2,0x20
    80000d56:	00c587b3          	add	a5,a1,a2
{
    80000d5a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d5c:	0585                	addi	a1,a1,1
    80000d5e:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdbb29>
    80000d60:	fff5c683          	lbu	a3,-1(a1)
    80000d64:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d68:	feb79ae3          	bne	a5,a1,80000d5c <memmove+0x16>

  return dst;
}
    80000d6c:	6422                	ld	s0,8(sp)
    80000d6e:	0141                	addi	sp,sp,16
    80000d70:	8082                	ret
  if(s < d && s + n > d){
    80000d72:	02061693          	slli	a3,a2,0x20
    80000d76:	9281                	srli	a3,a3,0x20
    80000d78:	00d58733          	add	a4,a1,a3
    80000d7c:	fce57be3          	bgeu	a0,a4,80000d52 <memmove+0xc>
    d += n;
    80000d80:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d82:	fff6079b          	addiw	a5,a2,-1
    80000d86:	1782                	slli	a5,a5,0x20
    80000d88:	9381                	srli	a5,a5,0x20
    80000d8a:	fff7c793          	not	a5,a5
    80000d8e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d90:	177d                	addi	a4,a4,-1
    80000d92:	16fd                	addi	a3,a3,-1
    80000d94:	00074603          	lbu	a2,0(a4)
    80000d98:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9c:	fef71ae3          	bne	a4,a5,80000d90 <memmove+0x4a>
    80000da0:	b7f1                	j	80000d6c <memmove+0x26>

0000000080000da2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e406                	sd	ra,8(sp)
    80000da6:	e022                	sd	s0,0(sp)
    80000da8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000daa:	f9dff0ef          	jal	80000d46 <memmove>
}
    80000dae:	60a2                	ld	ra,8(sp)
    80000db0:	6402                	ld	s0,0(sp)
    80000db2:	0141                	addi	sp,sp,16
    80000db4:	8082                	ret

0000000080000db6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbc:	ce11                	beqz	a2,80000dd8 <strncmp+0x22>
    80000dbe:	00054783          	lbu	a5,0(a0)
    80000dc2:	cf89                	beqz	a5,80000ddc <strncmp+0x26>
    80000dc4:	0005c703          	lbu	a4,0(a1)
    80000dc8:	00f71a63          	bne	a4,a5,80000ddc <strncmp+0x26>
    n--, p++, q++;
    80000dcc:	367d                	addiw	a2,a2,-1
    80000dce:	0505                	addi	a0,a0,1
    80000dd0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd2:	f675                	bnez	a2,80000dbe <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	a801                	j	80000de6 <strncmp+0x30>
    80000dd8:	4501                	li	a0,0
    80000dda:	a031                	j	80000de6 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000ddc:	00054503          	lbu	a0,0(a0)
    80000de0:	0005c783          	lbu	a5,0(a1)
    80000de4:	9d1d                	subw	a0,a0,a5
}
    80000de6:	6422                	ld	s0,8(sp)
    80000de8:	0141                	addi	sp,sp,16
    80000dea:	8082                	ret

0000000080000dec <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e422                	sd	s0,8(sp)
    80000df0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df2:	87aa                	mv	a5,a0
    80000df4:	86b2                	mv	a3,a2
    80000df6:	367d                	addiw	a2,a2,-1
    80000df8:	02d05563          	blez	a3,80000e22 <strncpy+0x36>
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	0005c703          	lbu	a4,0(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	0585                	addi	a1,a1,1
    80000e08:	f775                	bnez	a4,80000df4 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e0a:	873e                	mv	a4,a5
    80000e0c:	9fb5                	addw	a5,a5,a3
    80000e0e:	37fd                	addiw	a5,a5,-1
    80000e10:	00c05963          	blez	a2,80000e22 <strncpy+0x36>
    *s++ = 0;
    80000e14:	0705                	addi	a4,a4,1
    80000e16:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e1a:	40e786bb          	subw	a3,a5,a4
    80000e1e:	fed04be3          	bgtz	a3,80000e14 <strncpy+0x28>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	86be                	mv	a3,a5
    80000e6c:	0785                	addi	a5,a5,1
    80000e6e:	fff7c703          	lbu	a4,-1(a5)
    80000e72:	ff65                	bnez	a4,80000e6a <strlen+0x10>
    80000e74:	40a6853b          	subw	a0,a3,a0
    80000e78:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	25f000ef          	jal	800018ea <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e90:	00009717          	auipc	a4,0x9
    80000e94:	31070713          	addi	a4,a4,784 # 8000a1a0 <started>
  if(cpuid() == 0){
    80000e98:	c51d                	beqz	a0,80000ec6 <main+0x42>
    while(started == 0)
    80000e9a:	431c                	lw	a5,0(a4)
    80000e9c:	2781                	sext.w	a5,a5
    80000e9e:	dff5                	beqz	a5,80000e9a <main+0x16>
      ;
    __sync_synchronize();
    80000ea0:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000ea4:	247000ef          	jal	800018ea <cpuid>
    80000ea8:	85aa                	mv	a1,a0
    80000eaa:	00006517          	auipc	a0,0x6
    80000eae:	1ee50513          	addi	a0,a0,494 # 80007098 <etext+0x98>
    80000eb2:	e48ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000eb6:	080000ef          	jal	80000f36 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eba:	588010ef          	jal	80002442 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ebe:	55a040ef          	jal	80005418 <plicinithart>
  }

  scheduler();        
    80000ec2:	6c7000ef          	jal	80001d88 <scheduler>
    consoleinit();
    80000ec6:	d5eff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000eca:	953ff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000ece:	00006517          	auipc	a0,0x6
    80000ed2:	1aa50513          	addi	a0,a0,426 # 80007078 <etext+0x78>
    80000ed6:	e24ff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000eda:	00006517          	auipc	a0,0x6
    80000ede:	1a650513          	addi	a0,a0,422 # 80007080 <etext+0x80>
    80000ee2:	e18ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000ee6:	00006517          	auipc	a0,0x6
    80000eea:	19250513          	addi	a0,a0,402 # 80007078 <etext+0x78>
    80000eee:	e0cff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000ef2:	c03ff0ef          	jal	80000af4 <kinit>
    kvminit();       // create kernel page table
    80000ef6:	2ca000ef          	jal	800011c0 <kvminit>
    kvminithart();   // turn on paging
    80000efa:	03c000ef          	jal	80000f36 <kvminithart>
    procinit();      // process table
    80000efe:	137000ef          	jal	80001834 <procinit>
    trapinit();      // trap vectors
    80000f02:	51c010ef          	jal	8000241e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f06:	53c010ef          	jal	80002442 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f0a:	4f4040ef          	jal	800053fe <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f0e:	50a040ef          	jal	80005418 <plicinithart>
    binit();         // buffer cache
    80000f12:	3c7010ef          	jal	80002ad8 <binit>
    iinit();         // inode table
    80000f16:	14c020ef          	jal	80003062 <iinit>
    fileinit();      // file table
    80000f1a:	03e030ef          	jal	80003f58 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f1e:	5ea040ef          	jal	80005508 <virtio_disk_init>
    userinit();      // first user process
    80000f22:	4bb000ef          	jal	80001bdc <userinit>
    __sync_synchronize();
    80000f26:	0330000f          	fence	rw,rw
    started = 1;
    80000f2a:	4785                	li	a5,1
    80000f2c:	00009717          	auipc	a4,0x9
    80000f30:	26f72a23          	sw	a5,628(a4) # 8000a1a0 <started>
    80000f34:	b779                	j	80000ec2 <main+0x3e>

0000000080000f36 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f36:	1141                	addi	sp,sp,-16
    80000f38:	e422                	sd	s0,8(sp)
    80000f3a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f3c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f40:	00009797          	auipc	a5,0x9
    80000f44:	2687b783          	ld	a5,616(a5) # 8000a1a8 <kernel_pagetable>
    80000f48:	83b1                	srli	a5,a5,0xc
    80000f4a:	577d                	li	a4,-1
    80000f4c:	177e                	slli	a4,a4,0x3f
    80000f4e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f50:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f54:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f58:	6422                	ld	s0,8(sp)
    80000f5a:	0141                	addi	sp,sp,16
    80000f5c:	8082                	ret

0000000080000f5e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f5e:	7139                	addi	sp,sp,-64
    80000f60:	fc06                	sd	ra,56(sp)
    80000f62:	f822                	sd	s0,48(sp)
    80000f64:	f426                	sd	s1,40(sp)
    80000f66:	f04a                	sd	s2,32(sp)
    80000f68:	ec4e                	sd	s3,24(sp)
    80000f6a:	e852                	sd	s4,16(sp)
    80000f6c:	e456                	sd	s5,8(sp)
    80000f6e:	e05a                	sd	s6,0(sp)
    80000f70:	0080                	addi	s0,sp,64
    80000f72:	84aa                	mv	s1,a0
    80000f74:	89ae                	mv	s3,a1
    80000f76:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f78:	57fd                	li	a5,-1
    80000f7a:	83e9                	srli	a5,a5,0x1a
    80000f7c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f7e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f80:	02b7fc63          	bgeu	a5,a1,80000fb8 <walk+0x5a>
    panic("walk");
    80000f84:	00006517          	auipc	a0,0x6
    80000f88:	12c50513          	addi	a0,a0,300 # 800070b0 <etext+0xb0>
    80000f8c:	855ff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f90:	060a8263          	beqz	s5,80000ff4 <walk+0x96>
    80000f94:	ba7ff0ef          	jal	80000b3a <kalloc>
    80000f98:	84aa                	mv	s1,a0
    80000f9a:	c139                	beqz	a0,80000fe0 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f9c:	6605                	lui	a2,0x1
    80000f9e:	4581                	li	a1,0
    80000fa0:	d4bff0ef          	jal	80000cea <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000fa4:	00c4d793          	srli	a5,s1,0xc
    80000fa8:	07aa                	slli	a5,a5,0xa
    80000faa:	0017e793          	ori	a5,a5,1
    80000fae:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000fb2:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    80000fb4:	036a0063          	beq	s4,s6,80000fd4 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000fb8:	0149d933          	srl	s2,s3,s4
    80000fbc:	1ff97913          	andi	s2,s2,511
    80000fc0:	090e                	slli	s2,s2,0x3
    80000fc2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fc4:	00093483          	ld	s1,0(s2)
    80000fc8:	0014f793          	andi	a5,s1,1
    80000fcc:	d3f1                	beqz	a5,80000f90 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fce:	80a9                	srli	s1,s1,0xa
    80000fd0:	04b2                	slli	s1,s1,0xc
    80000fd2:	b7c5                	j	80000fb2 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000fd4:	00c9d513          	srli	a0,s3,0xc
    80000fd8:	1ff57513          	andi	a0,a0,511
    80000fdc:	050e                	slli	a0,a0,0x3
    80000fde:	9526                	add	a0,a0,s1
}
    80000fe0:	70e2                	ld	ra,56(sp)
    80000fe2:	7442                	ld	s0,48(sp)
    80000fe4:	74a2                	ld	s1,40(sp)
    80000fe6:	7902                	ld	s2,32(sp)
    80000fe8:	69e2                	ld	s3,24(sp)
    80000fea:	6a42                	ld	s4,16(sp)
    80000fec:	6aa2                	ld	s5,8(sp)
    80000fee:	6b02                	ld	s6,0(sp)
    80000ff0:	6121                	addi	sp,sp,64
    80000ff2:	8082                	ret
        return 0;
    80000ff4:	4501                	li	a0,0
    80000ff6:	b7ed                	j	80000fe0 <walk+0x82>

0000000080000ff8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000ff8:	57fd                	li	a5,-1
    80000ffa:	83e9                	srli	a5,a5,0x1a
    80000ffc:	00b7f463          	bgeu	a5,a1,80001004 <walkaddr+0xc>
    return 0;
    80001000:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001002:	8082                	ret
{
    80001004:	1141                	addi	sp,sp,-16
    80001006:	e406                	sd	ra,8(sp)
    80001008:	e022                	sd	s0,0(sp)
    8000100a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000100c:	4601                	li	a2,0
    8000100e:	f51ff0ef          	jal	80000f5e <walk>
  if(pte == 0)
    80001012:	c105                	beqz	a0,80001032 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80001014:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001016:	0117f693          	andi	a3,a5,17
    8000101a:	4745                	li	a4,17
    return 0;
    8000101c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000101e:	00e68663          	beq	a3,a4,8000102a <walkaddr+0x32>
}
    80001022:	60a2                	ld	ra,8(sp)
    80001024:	6402                	ld	s0,0(sp)
    80001026:	0141                	addi	sp,sp,16
    80001028:	8082                	ret
  pa = PTE2PA(*pte);
    8000102a:	83a9                	srli	a5,a5,0xa
    8000102c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001030:	bfcd                	j	80001022 <walkaddr+0x2a>
    return 0;
    80001032:	4501                	li	a0,0
    80001034:	b7fd                	j	80001022 <walkaddr+0x2a>

0000000080001036 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001036:	715d                	addi	sp,sp,-80
    80001038:	e486                	sd	ra,72(sp)
    8000103a:	e0a2                	sd	s0,64(sp)
    8000103c:	fc26                	sd	s1,56(sp)
    8000103e:	f84a                	sd	s2,48(sp)
    80001040:	f44e                	sd	s3,40(sp)
    80001042:	f052                	sd	s4,32(sp)
    80001044:	ec56                	sd	s5,24(sp)
    80001046:	e85a                	sd	s6,16(sp)
    80001048:	e45e                	sd	s7,8(sp)
    8000104a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000104c:	03459793          	slli	a5,a1,0x34
    80001050:	e7a9                	bnez	a5,8000109a <mappages+0x64>
    80001052:	8aaa                	mv	s5,a0
    80001054:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001056:	03461793          	slli	a5,a2,0x34
    8000105a:	e7b1                	bnez	a5,800010a6 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    8000105c:	ca39                	beqz	a2,800010b2 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    8000105e:	77fd                	lui	a5,0xfffff
    80001060:	963e                	add	a2,a2,a5
    80001062:	00b609b3          	add	s3,a2,a1
  a = va;
    80001066:	892e                	mv	s2,a1
    80001068:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000106c:	6b85                	lui	s7,0x1
    8000106e:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001072:	4605                	li	a2,1
    80001074:	85ca                	mv	a1,s2
    80001076:	8556                	mv	a0,s5
    80001078:	ee7ff0ef          	jal	80000f5e <walk>
    8000107c:	c539                	beqz	a0,800010ca <mappages+0x94>
    if(*pte & PTE_V)
    8000107e:	611c                	ld	a5,0(a0)
    80001080:	8b85                	andi	a5,a5,1
    80001082:	ef95                	bnez	a5,800010be <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001084:	80b1                	srli	s1,s1,0xc
    80001086:	04aa                	slli	s1,s1,0xa
    80001088:	0164e4b3          	or	s1,s1,s6
    8000108c:	0014e493          	ori	s1,s1,1
    80001090:	e104                	sd	s1,0(a0)
    if(a == last)
    80001092:	05390863          	beq	s2,s3,800010e2 <mappages+0xac>
    a += PGSIZE;
    80001096:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001098:	bfd9                	j	8000106e <mappages+0x38>
    panic("mappages: va not aligned");
    8000109a:	00006517          	auipc	a0,0x6
    8000109e:	01e50513          	addi	a0,a0,30 # 800070b8 <etext+0xb8>
    800010a2:	f3eff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    800010a6:	00006517          	auipc	a0,0x6
    800010aa:	03250513          	addi	a0,a0,50 # 800070d8 <etext+0xd8>
    800010ae:	f32ff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    800010b2:	00006517          	auipc	a0,0x6
    800010b6:	04650513          	addi	a0,a0,70 # 800070f8 <etext+0xf8>
    800010ba:	f26ff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    800010be:	00006517          	auipc	a0,0x6
    800010c2:	04a50513          	addi	a0,a0,74 # 80007108 <etext+0x108>
    800010c6:	f1aff0ef          	jal	800007e0 <panic>
      return -1;
    800010ca:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010cc:	60a6                	ld	ra,72(sp)
    800010ce:	6406                	ld	s0,64(sp)
    800010d0:	74e2                	ld	s1,56(sp)
    800010d2:	7942                	ld	s2,48(sp)
    800010d4:	79a2                	ld	s3,40(sp)
    800010d6:	7a02                	ld	s4,32(sp)
    800010d8:	6ae2                	ld	s5,24(sp)
    800010da:	6b42                	ld	s6,16(sp)
    800010dc:	6ba2                	ld	s7,8(sp)
    800010de:	6161                	addi	sp,sp,80
    800010e0:	8082                	ret
  return 0;
    800010e2:	4501                	li	a0,0
    800010e4:	b7e5                	j	800010cc <mappages+0x96>

00000000800010e6 <kvmmap>:
{
    800010e6:	1141                	addi	sp,sp,-16
    800010e8:	e406                	sd	ra,8(sp)
    800010ea:	e022                	sd	s0,0(sp)
    800010ec:	0800                	addi	s0,sp,16
    800010ee:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010f0:	86b2                	mv	a3,a2
    800010f2:	863e                	mv	a2,a5
    800010f4:	f43ff0ef          	jal	80001036 <mappages>
    800010f8:	e509                	bnez	a0,80001102 <kvmmap+0x1c>
}
    800010fa:	60a2                	ld	ra,8(sp)
    800010fc:	6402                	ld	s0,0(sp)
    800010fe:	0141                	addi	sp,sp,16
    80001100:	8082                	ret
    panic("kvmmap");
    80001102:	00006517          	auipc	a0,0x6
    80001106:	01650513          	addi	a0,a0,22 # 80007118 <etext+0x118>
    8000110a:	ed6ff0ef          	jal	800007e0 <panic>

000000008000110e <kvmmake>:
{
    8000110e:	1101                	addi	sp,sp,-32
    80001110:	ec06                	sd	ra,24(sp)
    80001112:	e822                	sd	s0,16(sp)
    80001114:	e426                	sd	s1,8(sp)
    80001116:	e04a                	sd	s2,0(sp)
    80001118:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000111a:	a21ff0ef          	jal	80000b3a <kalloc>
    8000111e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001120:	6605                	lui	a2,0x1
    80001122:	4581                	li	a1,0
    80001124:	bc7ff0ef          	jal	80000cea <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001128:	4719                	li	a4,6
    8000112a:	6685                	lui	a3,0x1
    8000112c:	10000637          	lui	a2,0x10000
    80001130:	100005b7          	lui	a1,0x10000
    80001134:	8526                	mv	a0,s1
    80001136:	fb1ff0ef          	jal	800010e6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000113a:	4719                	li	a4,6
    8000113c:	6685                	lui	a3,0x1
    8000113e:	10001637          	lui	a2,0x10001
    80001142:	100015b7          	lui	a1,0x10001
    80001146:	8526                	mv	a0,s1
    80001148:	f9fff0ef          	jal	800010e6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    8000114c:	4719                	li	a4,6
    8000114e:	040006b7          	lui	a3,0x4000
    80001152:	0c000637          	lui	a2,0xc000
    80001156:	0c0005b7          	lui	a1,0xc000
    8000115a:	8526                	mv	a0,s1
    8000115c:	f8bff0ef          	jal	800010e6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001160:	00006917          	auipc	s2,0x6
    80001164:	ea090913          	addi	s2,s2,-352 # 80007000 <etext>
    80001168:	4729                	li	a4,10
    8000116a:	80006697          	auipc	a3,0x80006
    8000116e:	e9668693          	addi	a3,a3,-362 # 7000 <_entry-0x7fff9000>
    80001172:	4605                	li	a2,1
    80001174:	067e                	slli	a2,a2,0x1f
    80001176:	85b2                	mv	a1,a2
    80001178:	8526                	mv	a0,s1
    8000117a:	f6dff0ef          	jal	800010e6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000117e:	46c5                	li	a3,17
    80001180:	06ee                	slli	a3,a3,0x1b
    80001182:	4719                	li	a4,6
    80001184:	412686b3          	sub	a3,a3,s2
    80001188:	864a                	mv	a2,s2
    8000118a:	85ca                	mv	a1,s2
    8000118c:	8526                	mv	a0,s1
    8000118e:	f59ff0ef          	jal	800010e6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001192:	4729                	li	a4,10
    80001194:	6685                	lui	a3,0x1
    80001196:	00005617          	auipc	a2,0x5
    8000119a:	e6a60613          	addi	a2,a2,-406 # 80006000 <_trampoline>
    8000119e:	040005b7          	lui	a1,0x4000
    800011a2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800011a4:	05b2                	slli	a1,a1,0xc
    800011a6:	8526                	mv	a0,s1
    800011a8:	f3fff0ef          	jal	800010e6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800011ac:	8526                	mv	a0,s1
    800011ae:	5ee000ef          	jal	8000179c <proc_mapstacks>
}
    800011b2:	8526                	mv	a0,s1
    800011b4:	60e2                	ld	ra,24(sp)
    800011b6:	6442                	ld	s0,16(sp)
    800011b8:	64a2                	ld	s1,8(sp)
    800011ba:	6902                	ld	s2,0(sp)
    800011bc:	6105                	addi	sp,sp,32
    800011be:	8082                	ret

00000000800011c0 <kvminit>:
{
    800011c0:	1141                	addi	sp,sp,-16
    800011c2:	e406                	sd	ra,8(sp)
    800011c4:	e022                	sd	s0,0(sp)
    800011c6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011c8:	f47ff0ef          	jal	8000110e <kvmmake>
    800011cc:	00009797          	auipc	a5,0x9
    800011d0:	fca7be23          	sd	a0,-36(a5) # 8000a1a8 <kernel_pagetable>
}
    800011d4:	60a2                	ld	ra,8(sp)
    800011d6:	6402                	ld	s0,0(sp)
    800011d8:	0141                	addi	sp,sp,16
    800011da:	8082                	ret

00000000800011dc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011e6:	955ff0ef          	jal	80000b3a <kalloc>
    800011ea:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011ec:	c509                	beqz	a0,800011f6 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011ee:	6605                	lui	a2,0x1
    800011f0:	4581                	li	a1,0
    800011f2:	af9ff0ef          	jal	80000cea <memset>
  return pagetable;
}
    800011f6:	8526                	mv	a0,s1
    800011f8:	60e2                	ld	ra,24(sp)
    800011fa:	6442                	ld	s0,16(sp)
    800011fc:	64a2                	ld	s1,8(sp)
    800011fe:	6105                	addi	sp,sp,32
    80001200:	8082                	ret

0000000080001202 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001202:	7139                	addi	sp,sp,-64
    80001204:	fc06                	sd	ra,56(sp)
    80001206:	f822                	sd	s0,48(sp)
    80001208:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000120a:	03459793          	slli	a5,a1,0x34
    8000120e:	e38d                	bnez	a5,80001230 <uvmunmap+0x2e>
    80001210:	f04a                	sd	s2,32(sp)
    80001212:	ec4e                	sd	s3,24(sp)
    80001214:	e852                	sd	s4,16(sp)
    80001216:	e456                	sd	s5,8(sp)
    80001218:	e05a                	sd	s6,0(sp)
    8000121a:	8a2a                	mv	s4,a0
    8000121c:	892e                	mv	s2,a1
    8000121e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001220:	0632                	slli	a2,a2,0xc
    80001222:	00b609b3          	add	s3,a2,a1
    80001226:	6b05                	lui	s6,0x1
    80001228:	0535f963          	bgeu	a1,s3,8000127a <uvmunmap+0x78>
    8000122c:	f426                	sd	s1,40(sp)
    8000122e:	a015                	j	80001252 <uvmunmap+0x50>
    80001230:	f426                	sd	s1,40(sp)
    80001232:	f04a                	sd	s2,32(sp)
    80001234:	ec4e                	sd	s3,24(sp)
    80001236:	e852                	sd	s4,16(sp)
    80001238:	e456                	sd	s5,8(sp)
    8000123a:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    8000123c:	00006517          	auipc	a0,0x6
    80001240:	ee450513          	addi	a0,a0,-284 # 80007120 <etext+0x120>
    80001244:	d9cff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001248:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000124c:	995a                	add	s2,s2,s6
    8000124e:	03397563          	bgeu	s2,s3,80001278 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001252:	4601                	li	a2,0
    80001254:	85ca                	mv	a1,s2
    80001256:	8552                	mv	a0,s4
    80001258:	d07ff0ef          	jal	80000f5e <walk>
    8000125c:	84aa                	mv	s1,a0
    8000125e:	d57d                	beqz	a0,8000124c <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001260:	611c                	ld	a5,0(a0)
    80001262:	0017f713          	andi	a4,a5,1
    80001266:	d37d                	beqz	a4,8000124c <uvmunmap+0x4a>
    if(do_free){
    80001268:	fe0a80e3          	beqz	s5,80001248 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000126c:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000126e:	00c79513          	slli	a0,a5,0xc
    80001272:	faaff0ef          	jal	80000a1c <kfree>
    80001276:	bfc9                	j	80001248 <uvmunmap+0x46>
    80001278:	74a2                	ld	s1,40(sp)
    8000127a:	7902                	ld	s2,32(sp)
    8000127c:	69e2                	ld	s3,24(sp)
    8000127e:	6a42                	ld	s4,16(sp)
    80001280:	6aa2                	ld	s5,8(sp)
    80001282:	6b02                	ld	s6,0(sp)
  }
}
    80001284:	70e2                	ld	ra,56(sp)
    80001286:	7442                	ld	s0,48(sp)
    80001288:	6121                	addi	sp,sp,64
    8000128a:	8082                	ret

000000008000128c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000128c:	1101                	addi	sp,sp,-32
    8000128e:	ec06                	sd	ra,24(sp)
    80001290:	e822                	sd	s0,16(sp)
    80001292:	e426                	sd	s1,8(sp)
    80001294:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001296:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001298:	00b67d63          	bgeu	a2,a1,800012b2 <uvmdealloc+0x26>
    8000129c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	00f60733          	add	a4,a2,a5
    800012a6:	76fd                	lui	a3,0xfffff
    800012a8:	8f75                	and	a4,a4,a3
    800012aa:	97ae                	add	a5,a5,a1
    800012ac:	8ff5                	and	a5,a5,a3
    800012ae:	00f76863          	bltu	a4,a5,800012be <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012b2:	8526                	mv	a0,s1
    800012b4:	60e2                	ld	ra,24(sp)
    800012b6:	6442                	ld	s0,16(sp)
    800012b8:	64a2                	ld	s1,8(sp)
    800012ba:	6105                	addi	sp,sp,32
    800012bc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800012be:	8f99                	sub	a5,a5,a4
    800012c0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012c2:	4685                	li	a3,1
    800012c4:	0007861b          	sext.w	a2,a5
    800012c8:	85ba                	mv	a1,a4
    800012ca:	f39ff0ef          	jal	80001202 <uvmunmap>
    800012ce:	b7d5                	j	800012b2 <uvmdealloc+0x26>

00000000800012d0 <uvmalloc>:
  if(newsz < oldsz)
    800012d0:	08b66f63          	bltu	a2,a1,8000136e <uvmalloc+0x9e>
{
    800012d4:	7139                	addi	sp,sp,-64
    800012d6:	fc06                	sd	ra,56(sp)
    800012d8:	f822                	sd	s0,48(sp)
    800012da:	ec4e                	sd	s3,24(sp)
    800012dc:	e852                	sd	s4,16(sp)
    800012de:	e456                	sd	s5,8(sp)
    800012e0:	0080                	addi	s0,sp,64
    800012e2:	8aaa                	mv	s5,a0
    800012e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800012e6:	6785                	lui	a5,0x1
    800012e8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012ea:	95be                	add	a1,a1,a5
    800012ec:	77fd                	lui	a5,0xfffff
    800012ee:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012f2:	08c9f063          	bgeu	s3,a2,80001372 <uvmalloc+0xa2>
    800012f6:	f426                	sd	s1,40(sp)
    800012f8:	f04a                	sd	s2,32(sp)
    800012fa:	e05a                	sd	s6,0(sp)
    800012fc:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012fe:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001302:	839ff0ef          	jal	80000b3a <kalloc>
    80001306:	84aa                	mv	s1,a0
    if(mem == 0){
    80001308:	c515                	beqz	a0,80001334 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000130a:	6605                	lui	a2,0x1
    8000130c:	4581                	li	a1,0
    8000130e:	9ddff0ef          	jal	80000cea <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001312:	875a                	mv	a4,s6
    80001314:	86a6                	mv	a3,s1
    80001316:	6605                	lui	a2,0x1
    80001318:	85ca                	mv	a1,s2
    8000131a:	8556                	mv	a0,s5
    8000131c:	d1bff0ef          	jal	80001036 <mappages>
    80001320:	e915                	bnez	a0,80001354 <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001322:	6785                	lui	a5,0x1
    80001324:	993e                	add	s2,s2,a5
    80001326:	fd496ee3          	bltu	s2,s4,80001302 <uvmalloc+0x32>
  return newsz;
    8000132a:	8552                	mv	a0,s4
    8000132c:	74a2                	ld	s1,40(sp)
    8000132e:	7902                	ld	s2,32(sp)
    80001330:	6b02                	ld	s6,0(sp)
    80001332:	a811                	j	80001346 <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    80001334:	864e                	mv	a2,s3
    80001336:	85ca                	mv	a1,s2
    80001338:	8556                	mv	a0,s5
    8000133a:	f53ff0ef          	jal	8000128c <uvmdealloc>
      return 0;
    8000133e:	4501                	li	a0,0
    80001340:	74a2                	ld	s1,40(sp)
    80001342:	7902                	ld	s2,32(sp)
    80001344:	6b02                	ld	s6,0(sp)
}
    80001346:	70e2                	ld	ra,56(sp)
    80001348:	7442                	ld	s0,48(sp)
    8000134a:	69e2                	ld	s3,24(sp)
    8000134c:	6a42                	ld	s4,16(sp)
    8000134e:	6aa2                	ld	s5,8(sp)
    80001350:	6121                	addi	sp,sp,64
    80001352:	8082                	ret
      kfree(mem);
    80001354:	8526                	mv	a0,s1
    80001356:	ec6ff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000135a:	864e                	mv	a2,s3
    8000135c:	85ca                	mv	a1,s2
    8000135e:	8556                	mv	a0,s5
    80001360:	f2dff0ef          	jal	8000128c <uvmdealloc>
      return 0;
    80001364:	4501                	li	a0,0
    80001366:	74a2                	ld	s1,40(sp)
    80001368:	7902                	ld	s2,32(sp)
    8000136a:	6b02                	ld	s6,0(sp)
    8000136c:	bfe9                	j	80001346 <uvmalloc+0x76>
    return oldsz;
    8000136e:	852e                	mv	a0,a1
}
    80001370:	8082                	ret
  return newsz;
    80001372:	8532                	mv	a0,a2
    80001374:	bfc9                	j	80001346 <uvmalloc+0x76>

0000000080001376 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
    80001386:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001388:	84aa                	mv	s1,a0
    8000138a:	6905                	lui	s2,0x1
    8000138c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000138e:	4985                	li	s3,1
    80001390:	a819                	j	800013a6 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001392:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001394:	00c79513          	slli	a0,a5,0xc
    80001398:	fdfff0ef          	jal	80001376 <freewalk>
      pagetable[i] = 0;
    8000139c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800013a0:	04a1                	addi	s1,s1,8
    800013a2:	01248f63          	beq	s1,s2,800013c0 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    800013a6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013a8:	00f7f713          	andi	a4,a5,15
    800013ac:	ff3703e3          	beq	a4,s3,80001392 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800013b0:	8b85                	andi	a5,a5,1
    800013b2:	d7fd                	beqz	a5,800013a0 <freewalk+0x2a>
      panic("freewalk: leaf");
    800013b4:	00006517          	auipc	a0,0x6
    800013b8:	d8450513          	addi	a0,a0,-636 # 80007138 <etext+0x138>
    800013bc:	c24ff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    800013c0:	8552                	mv	a0,s4
    800013c2:	e5aff0ef          	jal	80000a1c <kfree>
}
    800013c6:	70a2                	ld	ra,40(sp)
    800013c8:	7402                	ld	s0,32(sp)
    800013ca:	64e2                	ld	s1,24(sp)
    800013cc:	6942                	ld	s2,16(sp)
    800013ce:	69a2                	ld	s3,8(sp)
    800013d0:	6a02                	ld	s4,0(sp)
    800013d2:	6145                	addi	sp,sp,48
    800013d4:	8082                	ret

00000000800013d6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013d6:	1101                	addi	sp,sp,-32
    800013d8:	ec06                	sd	ra,24(sp)
    800013da:	e822                	sd	s0,16(sp)
    800013dc:	e426                	sd	s1,8(sp)
    800013de:	1000                	addi	s0,sp,32
    800013e0:	84aa                	mv	s1,a0
  if(sz > 0)
    800013e2:	e989                	bnez	a1,800013f4 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013e4:	8526                	mv	a0,s1
    800013e6:	f91ff0ef          	jal	80001376 <freewalk>
}
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	addi	sp,sp,32
    800013f2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013f8:	95be                	add	a1,a1,a5
    800013fa:	4685                	li	a3,1
    800013fc:	00c5d613          	srli	a2,a1,0xc
    80001400:	4581                	li	a1,0
    80001402:	e01ff0ef          	jal	80001202 <uvmunmap>
    80001406:	bff9                	j	800013e4 <uvmfree+0xe>

0000000080001408 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001408:	ce49                	beqz	a2,800014a2 <uvmcopy+0x9a>
{
    8000140a:	715d                	addi	sp,sp,-80
    8000140c:	e486                	sd	ra,72(sp)
    8000140e:	e0a2                	sd	s0,64(sp)
    80001410:	fc26                	sd	s1,56(sp)
    80001412:	f84a                	sd	s2,48(sp)
    80001414:	f44e                	sd	s3,40(sp)
    80001416:	f052                	sd	s4,32(sp)
    80001418:	ec56                	sd	s5,24(sp)
    8000141a:	e85a                	sd	s6,16(sp)
    8000141c:	e45e                	sd	s7,8(sp)
    8000141e:	0880                	addi	s0,sp,80
    80001420:	8aaa                	mv	s5,a0
    80001422:	8b2e                	mv	s6,a1
    80001424:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001426:	4481                	li	s1,0
    80001428:	a029                	j	80001432 <uvmcopy+0x2a>
    8000142a:	6785                	lui	a5,0x1
    8000142c:	94be                	add	s1,s1,a5
    8000142e:	0544fe63          	bgeu	s1,s4,8000148a <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001432:	4601                	li	a2,0
    80001434:	85a6                	mv	a1,s1
    80001436:	8556                	mv	a0,s5
    80001438:	b27ff0ef          	jal	80000f5e <walk>
    8000143c:	d57d                	beqz	a0,8000142a <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    8000143e:	6118                	ld	a4,0(a0)
    80001440:	00177793          	andi	a5,a4,1
    80001444:	d3fd                	beqz	a5,8000142a <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001446:	00a75593          	srli	a1,a4,0xa
    8000144a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000144e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001452:	ee8ff0ef          	jal	80000b3a <kalloc>
    80001456:	89aa                	mv	s3,a0
    80001458:	c105                	beqz	a0,80001478 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	85de                	mv	a1,s7
    8000145e:	8e9ff0ef          	jal	80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001462:	874a                	mv	a4,s2
    80001464:	86ce                	mv	a3,s3
    80001466:	6605                	lui	a2,0x1
    80001468:	85a6                	mv	a1,s1
    8000146a:	855a                	mv	a0,s6
    8000146c:	bcbff0ef          	jal	80001036 <mappages>
    80001470:	dd4d                	beqz	a0,8000142a <uvmcopy+0x22>
      kfree(mem);
    80001472:	854e                	mv	a0,s3
    80001474:	da8ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001478:	4685                	li	a3,1
    8000147a:	00c4d613          	srli	a2,s1,0xc
    8000147e:	4581                	li	a1,0
    80001480:	855a                	mv	a0,s6
    80001482:	d81ff0ef          	jal	80001202 <uvmunmap>
  return -1;
    80001486:	557d                	li	a0,-1
    80001488:	a011                	j	8000148c <uvmcopy+0x84>
  return 0;
    8000148a:	4501                	li	a0,0
}
    8000148c:	60a6                	ld	ra,72(sp)
    8000148e:	6406                	ld	s0,64(sp)
    80001490:	74e2                	ld	s1,56(sp)
    80001492:	7942                	ld	s2,48(sp)
    80001494:	79a2                	ld	s3,40(sp)
    80001496:	7a02                	ld	s4,32(sp)
    80001498:	6ae2                	ld	s5,24(sp)
    8000149a:	6b42                	ld	s6,16(sp)
    8000149c:	6ba2                	ld	s7,8(sp)
    8000149e:	6161                	addi	sp,sp,80
    800014a0:	8082                	ret
  return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	8082                	ret

00000000800014a6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800014a6:	1141                	addi	sp,sp,-16
    800014a8:	e406                	sd	ra,8(sp)
    800014aa:	e022                	sd	s0,0(sp)
    800014ac:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014ae:	4601                	li	a2,0
    800014b0:	aafff0ef          	jal	80000f5e <walk>
  if(pte == 0)
    800014b4:	c901                	beqz	a0,800014c4 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014b6:	611c                	ld	a5,0(a0)
    800014b8:	9bbd                	andi	a5,a5,-17
    800014ba:	e11c                	sd	a5,0(a0)
}
    800014bc:	60a2                	ld	ra,8(sp)
    800014be:	6402                	ld	s0,0(sp)
    800014c0:	0141                	addi	sp,sp,16
    800014c2:	8082                	ret
    panic("uvmclear");
    800014c4:	00006517          	auipc	a0,0x6
    800014c8:	c8450513          	addi	a0,a0,-892 # 80007148 <etext+0x148>
    800014cc:	b14ff0ef          	jal	800007e0 <panic>

00000000800014d0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014d0:	c6dd                	beqz	a3,8000157e <copyinstr+0xae>
{
    800014d2:	715d                	addi	sp,sp,-80
    800014d4:	e486                	sd	ra,72(sp)
    800014d6:	e0a2                	sd	s0,64(sp)
    800014d8:	fc26                	sd	s1,56(sp)
    800014da:	f84a                	sd	s2,48(sp)
    800014dc:	f44e                	sd	s3,40(sp)
    800014de:	f052                	sd	s4,32(sp)
    800014e0:	ec56                	sd	s5,24(sp)
    800014e2:	e85a                	sd	s6,16(sp)
    800014e4:	e45e                	sd	s7,8(sp)
    800014e6:	0880                	addi	s0,sp,80
    800014e8:	8a2a                	mv	s4,a0
    800014ea:	8b2e                	mv	s6,a1
    800014ec:	8bb2                	mv	s7,a2
    800014ee:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014f0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014f2:	6985                	lui	s3,0x1
    800014f4:	a825                	j	8000152c <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014f6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014fa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014fc:	37fd                	addiw	a5,a5,-1
    800014fe:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001502:	60a6                	ld	ra,72(sp)
    80001504:	6406                	ld	s0,64(sp)
    80001506:	74e2                	ld	s1,56(sp)
    80001508:	7942                	ld	s2,48(sp)
    8000150a:	79a2                	ld	s3,40(sp)
    8000150c:	7a02                	ld	s4,32(sp)
    8000150e:	6ae2                	ld	s5,24(sp)
    80001510:	6b42                	ld	s6,16(sp)
    80001512:	6ba2                	ld	s7,8(sp)
    80001514:	6161                	addi	sp,sp,80
    80001516:	8082                	ret
    80001518:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    8000151c:	9742                	add	a4,a4,a6
      --max;
    8000151e:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    80001522:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001526:	04e58463          	beq	a1,a4,8000156e <copyinstr+0x9e>
{
    8000152a:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    8000152c:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001530:	85a6                	mv	a1,s1
    80001532:	8552                	mv	a0,s4
    80001534:	ac5ff0ef          	jal	80000ff8 <walkaddr>
    if(pa0 == 0)
    80001538:	cd0d                	beqz	a0,80001572 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000153a:	417486b3          	sub	a3,s1,s7
    8000153e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001540:	00d97363          	bgeu	s2,a3,80001546 <copyinstr+0x76>
    80001544:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001546:	955e                	add	a0,a0,s7
    80001548:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000154a:	c695                	beqz	a3,80001576 <copyinstr+0xa6>
    8000154c:	87da                	mv	a5,s6
    8000154e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001550:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001554:	96da                	add	a3,a3,s6
    80001556:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001558:	00f60733          	add	a4,a2,a5
    8000155c:	00074703          	lbu	a4,0(a4)
    80001560:	db59                	beqz	a4,800014f6 <copyinstr+0x26>
        *dst = *p;
    80001562:	00e78023          	sb	a4,0(a5)
      dst++;
    80001566:	0785                	addi	a5,a5,1
    while(n > 0){
    80001568:	fed797e3          	bne	a5,a3,80001556 <copyinstr+0x86>
    8000156c:	b775                	j	80001518 <copyinstr+0x48>
    8000156e:	4781                	li	a5,0
    80001570:	b771                	j	800014fc <copyinstr+0x2c>
      return -1;
    80001572:	557d                	li	a0,-1
    80001574:	b779                	j	80001502 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001576:	6b85                	lui	s7,0x1
    80001578:	9ba6                	add	s7,s7,s1
    8000157a:	87da                	mv	a5,s6
    8000157c:	b77d                	j	8000152a <copyinstr+0x5a>
  int got_null = 0;
    8000157e:	4781                	li	a5,0
  if(got_null){
    80001580:	37fd                	addiw	a5,a5,-1
    80001582:	0007851b          	sext.w	a0,a5
}
    80001586:	8082                	ret

0000000080001588 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001588:	1141                	addi	sp,sp,-16
    8000158a:	e406                	sd	ra,8(sp)
    8000158c:	e022                	sd	s0,0(sp)
    8000158e:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001590:	4601                	li	a2,0
    80001592:	9cdff0ef          	jal	80000f5e <walk>
  if (pte == 0) {
    80001596:	c519                	beqz	a0,800015a4 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001598:	6108                	ld	a0,0(a0)
    8000159a:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000159c:	60a2                	ld	ra,8(sp)
    8000159e:	6402                	ld	s0,0(sp)
    800015a0:	0141                	addi	sp,sp,16
    800015a2:	8082                	ret
    return 0;
    800015a4:	4501                	li	a0,0
    800015a6:	bfdd                	j	8000159c <ismapped+0x14>

00000000800015a8 <vmfault>:
{
    800015a8:	7179                	addi	sp,sp,-48
    800015aa:	f406                	sd	ra,40(sp)
    800015ac:	f022                	sd	s0,32(sp)
    800015ae:	ec26                	sd	s1,24(sp)
    800015b0:	e44e                	sd	s3,8(sp)
    800015b2:	1800                	addi	s0,sp,48
    800015b4:	89aa                	mv	s3,a0
    800015b6:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800015b8:	35e000ef          	jal	80001916 <myproc>
  if (va >= p->sz)
    800015bc:	653c                	ld	a5,72(a0)
    800015be:	00f4ea63          	bltu	s1,a5,800015d2 <vmfault+0x2a>
    return 0;
    800015c2:	4981                	li	s3,0
}
    800015c4:	854e                	mv	a0,s3
    800015c6:	70a2                	ld	ra,40(sp)
    800015c8:	7402                	ld	s0,32(sp)
    800015ca:	64e2                	ld	s1,24(sp)
    800015cc:	69a2                	ld	s3,8(sp)
    800015ce:	6145                	addi	sp,sp,48
    800015d0:	8082                	ret
    800015d2:	e84a                	sd	s2,16(sp)
    800015d4:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015d6:	77fd                	lui	a5,0xfffff
    800015d8:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015da:	85a6                	mv	a1,s1
    800015dc:	854e                	mv	a0,s3
    800015de:	fabff0ef          	jal	80001588 <ismapped>
    return 0;
    800015e2:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015e4:	c119                	beqz	a0,800015ea <vmfault+0x42>
    800015e6:	6942                	ld	s2,16(sp)
    800015e8:	bff1                	j	800015c4 <vmfault+0x1c>
    800015ea:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015ec:	d4eff0ef          	jal	80000b3a <kalloc>
    800015f0:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015f2:	c90d                	beqz	a0,80001624 <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015f4:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	4581                	li	a1,0
    800015fa:	ef0ff0ef          	jal	80000cea <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015fe:	4759                	li	a4,22
    80001600:	86d2                	mv	a3,s4
    80001602:	6605                	lui	a2,0x1
    80001604:	85a6                	mv	a1,s1
    80001606:	05093503          	ld	a0,80(s2)
    8000160a:	a2dff0ef          	jal	80001036 <mappages>
    8000160e:	e501                	bnez	a0,80001616 <vmfault+0x6e>
    80001610:	6942                	ld	s2,16(sp)
    80001612:	6a02                	ld	s4,0(sp)
    80001614:	bf45                	j	800015c4 <vmfault+0x1c>
    kfree((void *)mem);
    80001616:	8552                	mv	a0,s4
    80001618:	c04ff0ef          	jal	80000a1c <kfree>
    return 0;
    8000161c:	4981                	li	s3,0
    8000161e:	6942                	ld	s2,16(sp)
    80001620:	6a02                	ld	s4,0(sp)
    80001622:	b74d                	j	800015c4 <vmfault+0x1c>
    80001624:	6942                	ld	s2,16(sp)
    80001626:	6a02                	ld	s4,0(sp)
    80001628:	bf71                	j	800015c4 <vmfault+0x1c>

000000008000162a <copyout>:
  while(len > 0){
    8000162a:	c2cd                	beqz	a3,800016cc <copyout+0xa2>
{
    8000162c:	711d                	addi	sp,sp,-96
    8000162e:	ec86                	sd	ra,88(sp)
    80001630:	e8a2                	sd	s0,80(sp)
    80001632:	e4a6                	sd	s1,72(sp)
    80001634:	f852                	sd	s4,48(sp)
    80001636:	f05a                	sd	s6,32(sp)
    80001638:	ec5e                	sd	s7,24(sp)
    8000163a:	e862                	sd	s8,16(sp)
    8000163c:	1080                	addi	s0,sp,96
    8000163e:	8c2a                	mv	s8,a0
    80001640:	8b2e                	mv	s6,a1
    80001642:	8bb2                	mv	s7,a2
    80001644:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001646:	74fd                	lui	s1,0xfffff
    80001648:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    8000164a:	57fd                	li	a5,-1
    8000164c:	83e9                	srli	a5,a5,0x1a
    8000164e:	0897e163          	bltu	a5,s1,800016d0 <copyout+0xa6>
    80001652:	e0ca                	sd	s2,64(sp)
    80001654:	fc4e                	sd	s3,56(sp)
    80001656:	f456                	sd	s5,40(sp)
    80001658:	e466                	sd	s9,8(sp)
    8000165a:	e06a                	sd	s10,0(sp)
    8000165c:	6d05                	lui	s10,0x1
    8000165e:	8cbe                	mv	s9,a5
    80001660:	a015                	j	80001684 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001662:	409b0533          	sub	a0,s6,s1
    80001666:	0009861b          	sext.w	a2,s3
    8000166a:	85de                	mv	a1,s7
    8000166c:	954a                	add	a0,a0,s2
    8000166e:	ed8ff0ef          	jal	80000d46 <memmove>
    len -= n;
    80001672:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001676:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001678:	040a0363          	beqz	s4,800016be <copyout+0x94>
    if(va0 >= MAXVA)
    8000167c:	055cec63          	bltu	s9,s5,800016d4 <copyout+0xaa>
    80001680:	84d6                	mv	s1,s5
    80001682:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80001684:	85a6                	mv	a1,s1
    80001686:	8562                	mv	a0,s8
    80001688:	971ff0ef          	jal	80000ff8 <walkaddr>
    8000168c:	892a                	mv	s2,a0
    if(pa0 == 0) {
    8000168e:	e901                	bnez	a0,8000169e <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001690:	4601                	li	a2,0
    80001692:	85a6                	mv	a1,s1
    80001694:	8562                	mv	a0,s8
    80001696:	f13ff0ef          	jal	800015a8 <vmfault>
    8000169a:	892a                	mv	s2,a0
    8000169c:	c139                	beqz	a0,800016e2 <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    8000169e:	4601                	li	a2,0
    800016a0:	85a6                	mv	a1,s1
    800016a2:	8562                	mv	a0,s8
    800016a4:	8bbff0ef          	jal	80000f5e <walk>
    if((*pte & PTE_W) == 0)
    800016a8:	611c                	ld	a5,0(a0)
    800016aa:	8b91                	andi	a5,a5,4
    800016ac:	c3b1                	beqz	a5,800016f0 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    800016ae:	01a48ab3          	add	s5,s1,s10
    800016b2:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800016b6:	fb3a76e3          	bgeu	s4,s3,80001662 <copyout+0x38>
    800016ba:	89d2                	mv	s3,s4
    800016bc:	b75d                	j	80001662 <copyout+0x38>
  return 0;
    800016be:	4501                	li	a0,0
    800016c0:	6906                	ld	s2,64(sp)
    800016c2:	79e2                	ld	s3,56(sp)
    800016c4:	7aa2                	ld	s5,40(sp)
    800016c6:	6ca2                	ld	s9,8(sp)
    800016c8:	6d02                	ld	s10,0(sp)
    800016ca:	a80d                	j	800016fc <copyout+0xd2>
    800016cc:	4501                	li	a0,0
}
    800016ce:	8082                	ret
      return -1;
    800016d0:	557d                	li	a0,-1
    800016d2:	a02d                	j	800016fc <copyout+0xd2>
    800016d4:	557d                	li	a0,-1
    800016d6:	6906                	ld	s2,64(sp)
    800016d8:	79e2                	ld	s3,56(sp)
    800016da:	7aa2                	ld	s5,40(sp)
    800016dc:	6ca2                	ld	s9,8(sp)
    800016de:	6d02                	ld	s10,0(sp)
    800016e0:	a831                	j	800016fc <copyout+0xd2>
        return -1;
    800016e2:	557d                	li	a0,-1
    800016e4:	6906                	ld	s2,64(sp)
    800016e6:	79e2                	ld	s3,56(sp)
    800016e8:	7aa2                	ld	s5,40(sp)
    800016ea:	6ca2                	ld	s9,8(sp)
    800016ec:	6d02                	ld	s10,0(sp)
    800016ee:	a039                	j	800016fc <copyout+0xd2>
      return -1;
    800016f0:	557d                	li	a0,-1
    800016f2:	6906                	ld	s2,64(sp)
    800016f4:	79e2                	ld	s3,56(sp)
    800016f6:	7aa2                	ld	s5,40(sp)
    800016f8:	6ca2                	ld	s9,8(sp)
    800016fa:	6d02                	ld	s10,0(sp)
}
    800016fc:	60e6                	ld	ra,88(sp)
    800016fe:	6446                	ld	s0,80(sp)
    80001700:	64a6                	ld	s1,72(sp)
    80001702:	7a42                	ld	s4,48(sp)
    80001704:	7b02                	ld	s6,32(sp)
    80001706:	6be2                	ld	s7,24(sp)
    80001708:	6c42                	ld	s8,16(sp)
    8000170a:	6125                	addi	sp,sp,96
    8000170c:	8082                	ret

000000008000170e <copyin>:
  while(len > 0){
    8000170e:	c6c9                	beqz	a3,80001798 <copyin+0x8a>
{
    80001710:	715d                	addi	sp,sp,-80
    80001712:	e486                	sd	ra,72(sp)
    80001714:	e0a2                	sd	s0,64(sp)
    80001716:	fc26                	sd	s1,56(sp)
    80001718:	f84a                	sd	s2,48(sp)
    8000171a:	f44e                	sd	s3,40(sp)
    8000171c:	f052                	sd	s4,32(sp)
    8000171e:	ec56                	sd	s5,24(sp)
    80001720:	e85a                	sd	s6,16(sp)
    80001722:	e45e                	sd	s7,8(sp)
    80001724:	e062                	sd	s8,0(sp)
    80001726:	0880                	addi	s0,sp,80
    80001728:	8baa                	mv	s7,a0
    8000172a:	8aae                	mv	s5,a1
    8000172c:	8932                	mv	s2,a2
    8000172e:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001730:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001732:	6b05                	lui	s6,0x1
    80001734:	a035                	j	80001760 <copyin+0x52>
    80001736:	412984b3          	sub	s1,s3,s2
    8000173a:	94da                	add	s1,s1,s6
    if(n > len)
    8000173c:	009a7363          	bgeu	s4,s1,80001742 <copyin+0x34>
    80001740:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001742:	413905b3          	sub	a1,s2,s3
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	95aa                	add	a1,a1,a0
    8000174c:	8556                	mv	a0,s5
    8000174e:	df8ff0ef          	jal	80000d46 <memmove>
    len -= n;
    80001752:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001756:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001758:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000175c:	020a0163          	beqz	s4,8000177e <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001760:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001764:	85ce                	mv	a1,s3
    80001766:	855e                	mv	a0,s7
    80001768:	891ff0ef          	jal	80000ff8 <walkaddr>
    if(pa0 == 0) {
    8000176c:	f569                	bnez	a0,80001736 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000176e:	4601                	li	a2,0
    80001770:	85ce                	mv	a1,s3
    80001772:	855e                	mv	a0,s7
    80001774:	e35ff0ef          	jal	800015a8 <vmfault>
    80001778:	fd5d                	bnez	a0,80001736 <copyin+0x28>
        return -1;
    8000177a:	557d                	li	a0,-1
    8000177c:	a011                	j	80001780 <copyin+0x72>
  return 0;
    8000177e:	4501                	li	a0,0
}
    80001780:	60a6                	ld	ra,72(sp)
    80001782:	6406                	ld	s0,64(sp)
    80001784:	74e2                	ld	s1,56(sp)
    80001786:	7942                	ld	s2,48(sp)
    80001788:	79a2                	ld	s3,40(sp)
    8000178a:	7a02                	ld	s4,32(sp)
    8000178c:	6ae2                	ld	s5,24(sp)
    8000178e:	6b42                	ld	s6,16(sp)
    80001790:	6ba2                	ld	s7,8(sp)
    80001792:	6c02                	ld	s8,0(sp)
    80001794:	6161                	addi	sp,sp,80
    80001796:	8082                	ret
  return 0;
    80001798:	4501                	li	a0,0
}
    8000179a:	8082                	ret

000000008000179c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000179c:	7139                	addi	sp,sp,-64
    8000179e:	fc06                	sd	ra,56(sp)
    800017a0:	f822                	sd	s0,48(sp)
    800017a2:	f426                	sd	s1,40(sp)
    800017a4:	f04a                	sd	s2,32(sp)
    800017a6:	ec4e                	sd	s3,24(sp)
    800017a8:	e852                	sd	s4,16(sp)
    800017aa:	e456                	sd	s5,8(sp)
    800017ac:	e05a                	sd	s6,0(sp)
    800017ae:	0080                	addi	s0,sp,64
    800017b0:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800017b2:	00011497          	auipc	s1,0x11
    800017b6:	f4648493          	addi	s1,s1,-186 # 800126f8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800017ba:	8b26                	mv	s6,s1
    800017bc:	04fa5937          	lui	s2,0x4fa5
    800017c0:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    800017c4:	0932                	slli	s2,s2,0xc
    800017c6:	fa590913          	addi	s2,s2,-91
    800017ca:	0932                	slli	s2,s2,0xc
    800017cc:	fa590913          	addi	s2,s2,-91
    800017d0:	0932                	slli	s2,s2,0xc
    800017d2:	fa590913          	addi	s2,s2,-91
    800017d6:	040009b7          	lui	s3,0x4000
    800017da:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800017dc:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017de:	00017a97          	auipc	s5,0x17
    800017e2:	91aa8a93          	addi	s5,s5,-1766 # 800180f8 <tickslock>
    char *pa = kalloc();
    800017e6:	b54ff0ef          	jal	80000b3a <kalloc>
    800017ea:	862a                	mv	a2,a0
    if(pa == 0)
    800017ec:	cd15                	beqz	a0,80001828 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017ee:	416485b3          	sub	a1,s1,s6
    800017f2:	858d                	srai	a1,a1,0x3
    800017f4:	032585b3          	mul	a1,a1,s2
    800017f8:	2585                	addiw	a1,a1,1
    800017fa:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017fe:	4719                	li	a4,6
    80001800:	6685                	lui	a3,0x1
    80001802:	40b985b3          	sub	a1,s3,a1
    80001806:	8552                	mv	a0,s4
    80001808:	8dfff0ef          	jal	800010e6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000180c:	16848493          	addi	s1,s1,360
    80001810:	fd549be3          	bne	s1,s5,800017e6 <proc_mapstacks+0x4a>
  }
}
    80001814:	70e2                	ld	ra,56(sp)
    80001816:	7442                	ld	s0,48(sp)
    80001818:	74a2                	ld	s1,40(sp)
    8000181a:	7902                	ld	s2,32(sp)
    8000181c:	69e2                	ld	s3,24(sp)
    8000181e:	6a42                	ld	s4,16(sp)
    80001820:	6aa2                	ld	s5,8(sp)
    80001822:	6b02                	ld	s6,0(sp)
    80001824:	6121                	addi	sp,sp,64
    80001826:	8082                	ret
      panic("kalloc");
    80001828:	00006517          	auipc	a0,0x6
    8000182c:	93050513          	addi	a0,a0,-1744 # 80007158 <etext+0x158>
    80001830:	fb1fe0ef          	jal	800007e0 <panic>

0000000080001834 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001834:	7139                	addi	sp,sp,-64
    80001836:	fc06                	sd	ra,56(sp)
    80001838:	f822                	sd	s0,48(sp)
    8000183a:	f426                	sd	s1,40(sp)
    8000183c:	f04a                	sd	s2,32(sp)
    8000183e:	ec4e                	sd	s3,24(sp)
    80001840:	e852                	sd	s4,16(sp)
    80001842:	e456                	sd	s5,8(sp)
    80001844:	e05a                	sd	s6,0(sp)
    80001846:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001848:	00006597          	auipc	a1,0x6
    8000184c:	91858593          	addi	a1,a1,-1768 # 80007160 <etext+0x160>
    80001850:	00011517          	auipc	a0,0x11
    80001854:	a7850513          	addi	a0,a0,-1416 # 800122c8 <pid_lock>
    80001858:	b3eff0ef          	jal	80000b96 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000185c:	00006597          	auipc	a1,0x6
    80001860:	90c58593          	addi	a1,a1,-1780 # 80007168 <etext+0x168>
    80001864:	00011517          	auipc	a0,0x11
    80001868:	a7c50513          	addi	a0,a0,-1412 # 800122e0 <wait_lock>
    8000186c:	b2aff0ef          	jal	80000b96 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001870:	00011497          	auipc	s1,0x11
    80001874:	e8848493          	addi	s1,s1,-376 # 800126f8 <proc>
      initlock(&p->lock, "proc");
    80001878:	00006b17          	auipc	s6,0x6
    8000187c:	900b0b13          	addi	s6,s6,-1792 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001880:	8aa6                	mv	s5,s1
    80001882:	04fa5937          	lui	s2,0x4fa5
    80001886:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    8000188a:	0932                	slli	s2,s2,0xc
    8000188c:	fa590913          	addi	s2,s2,-91
    80001890:	0932                	slli	s2,s2,0xc
    80001892:	fa590913          	addi	s2,s2,-91
    80001896:	0932                	slli	s2,s2,0xc
    80001898:	fa590913          	addi	s2,s2,-91
    8000189c:	040009b7          	lui	s3,0x4000
    800018a0:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800018a2:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a4:	00017a17          	auipc	s4,0x17
    800018a8:	854a0a13          	addi	s4,s4,-1964 # 800180f8 <tickslock>
      initlock(&p->lock, "proc");
    800018ac:	85da                	mv	a1,s6
    800018ae:	8526                	mv	a0,s1
    800018b0:	ae6ff0ef          	jal	80000b96 <initlock>
      p->state = UNUSED;
    800018b4:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800018b8:	415487b3          	sub	a5,s1,s5
    800018bc:	878d                	srai	a5,a5,0x3
    800018be:	032787b3          	mul	a5,a5,s2
    800018c2:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdbb29>
    800018c4:	00d7979b          	slliw	a5,a5,0xd
    800018c8:	40f987b3          	sub	a5,s3,a5
    800018cc:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ce:	16848493          	addi	s1,s1,360
    800018d2:	fd449de3          	bne	s1,s4,800018ac <procinit+0x78>
  }
}
    800018d6:	70e2                	ld	ra,56(sp)
    800018d8:	7442                	ld	s0,48(sp)
    800018da:	74a2                	ld	s1,40(sp)
    800018dc:	7902                	ld	s2,32(sp)
    800018de:	69e2                	ld	s3,24(sp)
    800018e0:	6a42                	ld	s4,16(sp)
    800018e2:	6aa2                	ld	s5,8(sp)
    800018e4:	6b02                	ld	s6,0(sp)
    800018e6:	6121                	addi	sp,sp,64
    800018e8:	8082                	ret

00000000800018ea <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018ea:	1141                	addi	sp,sp,-16
    800018ec:	e422                	sd	s0,8(sp)
    800018ee:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018f0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018f2:	2501                	sext.w	a0,a0
    800018f4:	6422                	ld	s0,8(sp)
    800018f6:	0141                	addi	sp,sp,16
    800018f8:	8082                	ret

00000000800018fa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018fa:	1141                	addi	sp,sp,-16
    800018fc:	e422                	sd	s0,8(sp)
    800018fe:	0800                	addi	s0,sp,16
    80001900:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001902:	2781                	sext.w	a5,a5
    80001904:	079e                	slli	a5,a5,0x7
  return c;
}
    80001906:	00011517          	auipc	a0,0x11
    8000190a:	9f250513          	addi	a0,a0,-1550 # 800122f8 <cpus>
    8000190e:	953e                	add	a0,a0,a5
    80001910:	6422                	ld	s0,8(sp)
    80001912:	0141                	addi	sp,sp,16
    80001914:	8082                	ret

0000000080001916 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001916:	1101                	addi	sp,sp,-32
    80001918:	ec06                	sd	ra,24(sp)
    8000191a:	e822                	sd	s0,16(sp)
    8000191c:	e426                	sd	s1,8(sp)
    8000191e:	1000                	addi	s0,sp,32
  push_off();
    80001920:	ab6ff0ef          	jal	80000bd6 <push_off>
    80001924:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001926:	2781                	sext.w	a5,a5
    80001928:	079e                	slli	a5,a5,0x7
    8000192a:	00011717          	auipc	a4,0x11
    8000192e:	99e70713          	addi	a4,a4,-1634 # 800122c8 <pid_lock>
    80001932:	97ba                	add	a5,a5,a4
    80001934:	7b84                	ld	s1,48(a5)
  pop_off();
    80001936:	b24ff0ef          	jal	80000c5a <pop_off>
  return p;
}
    8000193a:	8526                	mv	a0,s1
    8000193c:	60e2                	ld	ra,24(sp)
    8000193e:	6442                	ld	s0,16(sp)
    80001940:	64a2                	ld	s1,8(sp)
    80001942:	6105                	addi	sp,sp,32
    80001944:	8082                	ret

0000000080001946 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001946:	7179                	addi	sp,sp,-48
    80001948:	f406                	sd	ra,40(sp)
    8000194a:	f022                	sd	s0,32(sp)
    8000194c:	ec26                	sd	s1,24(sp)
    8000194e:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001950:	fc7ff0ef          	jal	80001916 <myproc>
    80001954:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001956:	b58ff0ef          	jal	80000cae <release>

  if (first) {
    8000195a:	00009797          	auipc	a5,0x9
    8000195e:	8067a783          	lw	a5,-2042(a5) # 8000a160 <first.1>
    80001962:	cf8d                	beqz	a5,8000199c <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001964:	4505                	li	a0,1
    80001966:	3b9010ef          	jal	8000351e <fsinit>

    first = 0;
    8000196a:	00008797          	auipc	a5,0x8
    8000196e:	7e07ab23          	sw	zero,2038(a5) # 8000a160 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001972:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001976:	00006517          	auipc	a0,0x6
    8000197a:	80a50513          	addi	a0,a0,-2038 # 80007180 <etext+0x180>
    8000197e:	fca43823          	sd	a0,-48(s0)
    80001982:	fc043c23          	sd	zero,-40(s0)
    80001986:	fd040593          	addi	a1,s0,-48
    8000198a:	49f020ef          	jal	80004628 <kexec>
    8000198e:	6cbc                	ld	a5,88(s1)
    80001990:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001992:	6cbc                	ld	a5,88(s1)
    80001994:	7bb8                	ld	a4,112(a5)
    80001996:	57fd                	li	a5,-1
    80001998:	02f70d63          	beq	a4,a5,800019d2 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    8000199c:	2bf000ef          	jal	8000245a <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800019a0:	68a8                	ld	a0,80(s1)
    800019a2:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800019a4:	04000737          	lui	a4,0x4000
    800019a8:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800019aa:	0732                	slli	a4,a4,0xc
    800019ac:	00004797          	auipc	a5,0x4
    800019b0:	6f078793          	addi	a5,a5,1776 # 8000609c <userret>
    800019b4:	00004697          	auipc	a3,0x4
    800019b8:	64c68693          	addi	a3,a3,1612 # 80006000 <_trampoline>
    800019bc:	8f95                	sub	a5,a5,a3
    800019be:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019c0:	577d                	li	a4,-1
    800019c2:	177e                	slli	a4,a4,0x3f
    800019c4:	8d59                	or	a0,a0,a4
    800019c6:	9782                	jalr	a5
}
    800019c8:	70a2                	ld	ra,40(sp)
    800019ca:	7402                	ld	s0,32(sp)
    800019cc:	64e2                	ld	s1,24(sp)
    800019ce:	6145                	addi	sp,sp,48
    800019d0:	8082                	ret
      panic("exec");
    800019d2:	00005517          	auipc	a0,0x5
    800019d6:	7b650513          	addi	a0,a0,1974 # 80007188 <etext+0x188>
    800019da:	e07fe0ef          	jal	800007e0 <panic>

00000000800019de <allocpid>:
{
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	e04a                	sd	s2,0(sp)
    800019e8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019ea:	00011917          	auipc	s2,0x11
    800019ee:	8de90913          	addi	s2,s2,-1826 # 800122c8 <pid_lock>
    800019f2:	854a                	mv	a0,s2
    800019f4:	a22ff0ef          	jal	80000c16 <acquire>
  pid = nextpid;
    800019f8:	00008797          	auipc	a5,0x8
    800019fc:	76c78793          	addi	a5,a5,1900 # 8000a164 <nextpid>
    80001a00:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a02:	0014871b          	addiw	a4,s1,1
    80001a06:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a08:	854a                	mv	a0,s2
    80001a0a:	aa4ff0ef          	jal	80000cae <release>
}
    80001a0e:	8526                	mv	a0,s1
    80001a10:	60e2                	ld	ra,24(sp)
    80001a12:	6442                	ld	s0,16(sp)
    80001a14:	64a2                	ld	s1,8(sp)
    80001a16:	6902                	ld	s2,0(sp)
    80001a18:	6105                	addi	sp,sp,32
    80001a1a:	8082                	ret

0000000080001a1c <proc_pagetable>:
{
    80001a1c:	1101                	addi	sp,sp,-32
    80001a1e:	ec06                	sd	ra,24(sp)
    80001a20:	e822                	sd	s0,16(sp)
    80001a22:	e426                	sd	s1,8(sp)
    80001a24:	e04a                	sd	s2,0(sp)
    80001a26:	1000                	addi	s0,sp,32
    80001a28:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a2a:	fb2ff0ef          	jal	800011dc <uvmcreate>
    80001a2e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a30:	cd05                	beqz	a0,80001a68 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a32:	4729                	li	a4,10
    80001a34:	00004697          	auipc	a3,0x4
    80001a38:	5cc68693          	addi	a3,a3,1484 # 80006000 <_trampoline>
    80001a3c:	6605                	lui	a2,0x1
    80001a3e:	040005b7          	lui	a1,0x4000
    80001a42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a44:	05b2                	slli	a1,a1,0xc
    80001a46:	df0ff0ef          	jal	80001036 <mappages>
    80001a4a:	02054663          	bltz	a0,80001a76 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a4e:	4719                	li	a4,6
    80001a50:	05893683          	ld	a3,88(s2)
    80001a54:	6605                	lui	a2,0x1
    80001a56:	020005b7          	lui	a1,0x2000
    80001a5a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a5c:	05b6                	slli	a1,a1,0xd
    80001a5e:	8526                	mv	a0,s1
    80001a60:	dd6ff0ef          	jal	80001036 <mappages>
    80001a64:	00054f63          	bltz	a0,80001a82 <proc_pagetable+0x66>
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6902                	ld	s2,0(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret
    uvmfree(pagetable, 0);
    80001a76:	4581                	li	a1,0
    80001a78:	8526                	mv	a0,s1
    80001a7a:	95dff0ef          	jal	800013d6 <uvmfree>
    return 0;
    80001a7e:	4481                	li	s1,0
    80001a80:	b7e5                	j	80001a68 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a82:	4681                	li	a3,0
    80001a84:	4605                	li	a2,1
    80001a86:	040005b7          	lui	a1,0x4000
    80001a8a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a8c:	05b2                	slli	a1,a1,0xc
    80001a8e:	8526                	mv	a0,s1
    80001a90:	f72ff0ef          	jal	80001202 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a94:	4581                	li	a1,0
    80001a96:	8526                	mv	a0,s1
    80001a98:	93fff0ef          	jal	800013d6 <uvmfree>
    return 0;
    80001a9c:	4481                	li	s1,0
    80001a9e:	b7e9                	j	80001a68 <proc_pagetable+0x4c>

0000000080001aa0 <proc_freepagetable>:
{
    80001aa0:	1101                	addi	sp,sp,-32
    80001aa2:	ec06                	sd	ra,24(sp)
    80001aa4:	e822                	sd	s0,16(sp)
    80001aa6:	e426                	sd	s1,8(sp)
    80001aa8:	e04a                	sd	s2,0(sp)
    80001aaa:	1000                	addi	s0,sp,32
    80001aac:	84aa                	mv	s1,a0
    80001aae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab0:	4681                	li	a3,0
    80001ab2:	4605                	li	a2,1
    80001ab4:	040005b7          	lui	a1,0x4000
    80001ab8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aba:	05b2                	slli	a1,a1,0xc
    80001abc:	f46ff0ef          	jal	80001202 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ac0:	4681                	li	a3,0
    80001ac2:	4605                	li	a2,1
    80001ac4:	020005b7          	lui	a1,0x2000
    80001ac8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aca:	05b6                	slli	a1,a1,0xd
    80001acc:	8526                	mv	a0,s1
    80001ace:	f34ff0ef          	jal	80001202 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ad2:	85ca                	mv	a1,s2
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	901ff0ef          	jal	800013d6 <uvmfree>
}
    80001ada:	60e2                	ld	ra,24(sp)
    80001adc:	6442                	ld	s0,16(sp)
    80001ade:	64a2                	ld	s1,8(sp)
    80001ae0:	6902                	ld	s2,0(sp)
    80001ae2:	6105                	addi	sp,sp,32
    80001ae4:	8082                	ret

0000000080001ae6 <freeproc>:
{
    80001ae6:	1101                	addi	sp,sp,-32
    80001ae8:	ec06                	sd	ra,24(sp)
    80001aea:	e822                	sd	s0,16(sp)
    80001aec:	e426                	sd	s1,8(sp)
    80001aee:	1000                	addi	s0,sp,32
    80001af0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001af2:	6d28                	ld	a0,88(a0)
    80001af4:	c119                	beqz	a0,80001afa <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001af6:	f27fe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001afa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001afe:	68a8                	ld	a0,80(s1)
    80001b00:	c501                	beqz	a0,80001b08 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001b02:	64ac                	ld	a1,72(s1)
    80001b04:	f9dff0ef          	jal	80001aa0 <proc_freepagetable>
  p->pagetable = 0;
    80001b08:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b0c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b10:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b14:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b18:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b1c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b20:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b24:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b28:	0004ac23          	sw	zero,24(s1)
}
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6105                	addi	sp,sp,32
    80001b34:	8082                	ret

0000000080001b36 <allocproc>:
{
    80001b36:	1101                	addi	sp,sp,-32
    80001b38:	ec06                	sd	ra,24(sp)
    80001b3a:	e822                	sd	s0,16(sp)
    80001b3c:	e426                	sd	s1,8(sp)
    80001b3e:	e04a                	sd	s2,0(sp)
    80001b40:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b42:	00011497          	auipc	s1,0x11
    80001b46:	bb648493          	addi	s1,s1,-1098 # 800126f8 <proc>
    80001b4a:	00016917          	auipc	s2,0x16
    80001b4e:	5ae90913          	addi	s2,s2,1454 # 800180f8 <tickslock>
    acquire(&p->lock);
    80001b52:	8526                	mv	a0,s1
    80001b54:	8c2ff0ef          	jal	80000c16 <acquire>
    if(p->state == UNUSED) {
    80001b58:	4c9c                	lw	a5,24(s1)
    80001b5a:	cb91                	beqz	a5,80001b6e <allocproc+0x38>
      release(&p->lock);
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	950ff0ef          	jal	80000cae <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b62:	16848493          	addi	s1,s1,360
    80001b66:	ff2496e3          	bne	s1,s2,80001b52 <allocproc+0x1c>
  return 0;
    80001b6a:	4481                	li	s1,0
    80001b6c:	a089                	j	80001bae <allocproc+0x78>
  p->pid = allocpid();
    80001b6e:	e71ff0ef          	jal	800019de <allocpid>
    80001b72:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b74:	4785                	li	a5,1
    80001b76:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b78:	fc3fe0ef          	jal	80000b3a <kalloc>
    80001b7c:	892a                	mv	s2,a0
    80001b7e:	eca8                	sd	a0,88(s1)
    80001b80:	cd15                	beqz	a0,80001bbc <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b82:	8526                	mv	a0,s1
    80001b84:	e99ff0ef          	jal	80001a1c <proc_pagetable>
    80001b88:	892a                	mv	s2,a0
    80001b8a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001b8c:	c121                	beqz	a0,80001bcc <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001b8e:	07000613          	li	a2,112
    80001b92:	4581                	li	a1,0
    80001b94:	06048513          	addi	a0,s1,96
    80001b98:	952ff0ef          	jal	80000cea <memset>
  p->context.ra = (uint64)forkret;
    80001b9c:	00000797          	auipc	a5,0x0
    80001ba0:	daa78793          	addi	a5,a5,-598 # 80001946 <forkret>
    80001ba4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ba6:	60bc                	ld	a5,64(s1)
    80001ba8:	6705                	lui	a4,0x1
    80001baa:	97ba                	add	a5,a5,a4
    80001bac:	f4bc                	sd	a5,104(s1)
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret
    freeproc(p);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	f29ff0ef          	jal	80001ae6 <freeproc>
    release(&p->lock);
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	8eaff0ef          	jal	80000cae <release>
    return 0;
    80001bc8:	84ca                	mv	s1,s2
    80001bca:	b7d5                	j	80001bae <allocproc+0x78>
    freeproc(p);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	f19ff0ef          	jal	80001ae6 <freeproc>
    release(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	8daff0ef          	jal	80000cae <release>
    return 0;
    80001bd8:	84ca                	mv	s1,s2
    80001bda:	bfd1                	j	80001bae <allocproc+0x78>

0000000080001bdc <userinit>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001be6:	f51ff0ef          	jal	80001b36 <allocproc>
    80001bea:	84aa                	mv	s1,a0
  initproc = p;
    80001bec:	00008797          	auipc	a5,0x8
    80001bf0:	5ca7b223          	sd	a0,1476(a5) # 8000a1b0 <initproc>
  p->cwd = namei("/");
    80001bf4:	00005517          	auipc	a0,0x5
    80001bf8:	59c50513          	addi	a0,a0,1436 # 80007190 <etext+0x190>
    80001bfc:	645010ef          	jal	80003a40 <namei>
    80001c00:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c04:	478d                	li	a5,3
    80001c06:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	8a4ff0ef          	jal	80000cae <release>
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <growproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
    80001c24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c26:	cf1ff0ef          	jal	80001916 <myproc>
    80001c2a:	892a                	mv	s2,a0
  sz = p->sz;
    80001c2c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c2e:	02905963          	blez	s1,80001c60 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c32:	00b48633          	add	a2,s1,a1
    80001c36:	020007b7          	lui	a5,0x2000
    80001c3a:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c3c:	07b6                	slli	a5,a5,0xd
    80001c3e:	02c7ea63          	bltu	a5,a2,80001c72 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c42:	4691                	li	a3,4
    80001c44:	6928                	ld	a0,80(a0)
    80001c46:	e8aff0ef          	jal	800012d0 <uvmalloc>
    80001c4a:	85aa                	mv	a1,a0
    80001c4c:	c50d                	beqz	a0,80001c76 <growproc+0x5e>
  p->sz = sz;
    80001c4e:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c52:	4501                	li	a0,0
}
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
  } else if(n < 0){
    80001c60:	fe04d7e3          	bgez	s1,80001c4e <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c64:	00b48633          	add	a2,s1,a1
    80001c68:	6928                	ld	a0,80(a0)
    80001c6a:	e22ff0ef          	jal	8000128c <uvmdealloc>
    80001c6e:	85aa                	mv	a1,a0
    80001c70:	bff9                	j	80001c4e <growproc+0x36>
      return -1;
    80001c72:	557d                	li	a0,-1
    80001c74:	b7c5                	j	80001c54 <growproc+0x3c>
      return -1;
    80001c76:	557d                	li	a0,-1
    80001c78:	bff1                	j	80001c54 <growproc+0x3c>

0000000080001c7a <kfork>:
{
    80001c7a:	7139                	addi	sp,sp,-64
    80001c7c:	fc06                	sd	ra,56(sp)
    80001c7e:	f822                	sd	s0,48(sp)
    80001c80:	f04a                	sd	s2,32(sp)
    80001c82:	e456                	sd	s5,8(sp)
    80001c84:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c86:	c91ff0ef          	jal	80001916 <myproc>
    80001c8a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c8c:	eabff0ef          	jal	80001b36 <allocproc>
    80001c90:	0e050a63          	beqz	a0,80001d84 <kfork+0x10a>
    80001c94:	e852                	sd	s4,16(sp)
    80001c96:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c98:	048ab603          	ld	a2,72(s5)
    80001c9c:	692c                	ld	a1,80(a0)
    80001c9e:	050ab503          	ld	a0,80(s5)
    80001ca2:	f66ff0ef          	jal	80001408 <uvmcopy>
    80001ca6:	04054a63          	bltz	a0,80001cfa <kfork+0x80>
    80001caa:	f426                	sd	s1,40(sp)
    80001cac:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001cae:	048ab783          	ld	a5,72(s5)
    80001cb2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001cb6:	058ab683          	ld	a3,88(s5)
    80001cba:	87b6                	mv	a5,a3
    80001cbc:	058a3703          	ld	a4,88(s4)
    80001cc0:	12068693          	addi	a3,a3,288
    80001cc4:	0007b803          	ld	a6,0(a5)
    80001cc8:	6788                	ld	a0,8(a5)
    80001cca:	6b8c                	ld	a1,16(a5)
    80001ccc:	6f90                	ld	a2,24(a5)
    80001cce:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001cd2:	e708                	sd	a0,8(a4)
    80001cd4:	eb0c                	sd	a1,16(a4)
    80001cd6:	ef10                	sd	a2,24(a4)
    80001cd8:	02078793          	addi	a5,a5,32
    80001cdc:	02070713          	addi	a4,a4,32
    80001ce0:	fed792e3          	bne	a5,a3,80001cc4 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001ce4:	058a3783          	ld	a5,88(s4)
    80001ce8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001cec:	0d0a8493          	addi	s1,s5,208
    80001cf0:	0d0a0913          	addi	s2,s4,208
    80001cf4:	150a8993          	addi	s3,s5,336
    80001cf8:	a831                	j	80001d14 <kfork+0x9a>
    freeproc(np);
    80001cfa:	8552                	mv	a0,s4
    80001cfc:	debff0ef          	jal	80001ae6 <freeproc>
    release(&np->lock);
    80001d00:	8552                	mv	a0,s4
    80001d02:	fadfe0ef          	jal	80000cae <release>
    return -1;
    80001d06:	597d                	li	s2,-1
    80001d08:	6a42                	ld	s4,16(sp)
    80001d0a:	a0b5                	j	80001d76 <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001d0c:	04a1                	addi	s1,s1,8
    80001d0e:	0921                	addi	s2,s2,8
    80001d10:	01348963          	beq	s1,s3,80001d22 <kfork+0xa8>
    if(p->ofile[i])
    80001d14:	6088                	ld	a0,0(s1)
    80001d16:	d97d                	beqz	a0,80001d0c <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d18:	2c2020ef          	jal	80003fda <filedup>
    80001d1c:	00a93023          	sd	a0,0(s2)
    80001d20:	b7f5                	j	80001d0c <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d22:	150ab503          	ld	a0,336(s5)
    80001d26:	4ce010ef          	jal	800031f4 <idup>
    80001d2a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d2e:	4641                	li	a2,16
    80001d30:	158a8593          	addi	a1,s5,344
    80001d34:	158a0513          	addi	a0,s4,344
    80001d38:	8f0ff0ef          	jal	80000e28 <safestrcpy>
  pid = np->pid;
    80001d3c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001d40:	8552                	mv	a0,s4
    80001d42:	f6dfe0ef          	jal	80000cae <release>
  acquire(&wait_lock);
    80001d46:	00010497          	auipc	s1,0x10
    80001d4a:	59a48493          	addi	s1,s1,1434 # 800122e0 <wait_lock>
    80001d4e:	8526                	mv	a0,s1
    80001d50:	ec7fe0ef          	jal	80000c16 <acquire>
  np->parent = p;
    80001d54:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	f55fe0ef          	jal	80000cae <release>
  acquire(&np->lock);
    80001d5e:	8552                	mv	a0,s4
    80001d60:	eb7fe0ef          	jal	80000c16 <acquire>
  np->state = RUNNABLE;
    80001d64:	478d                	li	a5,3
    80001d66:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d6a:	8552                	mv	a0,s4
    80001d6c:	f43fe0ef          	jal	80000cae <release>
  return pid;
    80001d70:	74a2                	ld	s1,40(sp)
    80001d72:	69e2                	ld	s3,24(sp)
    80001d74:	6a42                	ld	s4,16(sp)
}
    80001d76:	854a                	mv	a0,s2
    80001d78:	70e2                	ld	ra,56(sp)
    80001d7a:	7442                	ld	s0,48(sp)
    80001d7c:	7902                	ld	s2,32(sp)
    80001d7e:	6aa2                	ld	s5,8(sp)
    80001d80:	6121                	addi	sp,sp,64
    80001d82:	8082                	ret
    return -1;
    80001d84:	597d                	li	s2,-1
    80001d86:	bfc5                	j	80001d76 <kfork+0xfc>

0000000080001d88 <scheduler>:
{
    80001d88:	715d                	addi	sp,sp,-80
    80001d8a:	e486                	sd	ra,72(sp)
    80001d8c:	e0a2                	sd	s0,64(sp)
    80001d8e:	fc26                	sd	s1,56(sp)
    80001d90:	f84a                	sd	s2,48(sp)
    80001d92:	f44e                	sd	s3,40(sp)
    80001d94:	f052                	sd	s4,32(sp)
    80001d96:	ec56                	sd	s5,24(sp)
    80001d98:	e85a                	sd	s6,16(sp)
    80001d9a:	e45e                	sd	s7,8(sp)
    80001d9c:	e062                	sd	s8,0(sp)
    80001d9e:	0880                	addi	s0,sp,80
    80001da0:	8792                	mv	a5,tp
  int id = r_tp();
    80001da2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001da4:	00779b13          	slli	s6,a5,0x7
    80001da8:	00010717          	auipc	a4,0x10
    80001dac:	52070713          	addi	a4,a4,1312 # 800122c8 <pid_lock>
    80001db0:	975a                	add	a4,a4,s6
    80001db2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001db6:	00010717          	auipc	a4,0x10
    80001dba:	54a70713          	addi	a4,a4,1354 # 80012300 <cpus+0x8>
    80001dbe:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001dc0:	4c11                	li	s8,4
        c->proc = p;
    80001dc2:	079e                	slli	a5,a5,0x7
    80001dc4:	00010a17          	auipc	s4,0x10
    80001dc8:	504a0a13          	addi	s4,s4,1284 # 800122c8 <pid_lock>
    80001dcc:	9a3e                	add	s4,s4,a5
        found = 1;
    80001dce:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dd0:	00016997          	auipc	s3,0x16
    80001dd4:	32898993          	addi	s3,s3,808 # 800180f8 <tickslock>
    80001dd8:	a83d                	j	80001e16 <scheduler+0x8e>
      release(&p->lock);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	ed3fe0ef          	jal	80000cae <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001de0:	16848493          	addi	s1,s1,360
    80001de4:	03348563          	beq	s1,s3,80001e0e <scheduler+0x86>
      acquire(&p->lock);
    80001de8:	8526                	mv	a0,s1
    80001dea:	e2dfe0ef          	jal	80000c16 <acquire>
      if(p->state == RUNNABLE) {
    80001dee:	4c9c                	lw	a5,24(s1)
    80001df0:	ff2795e3          	bne	a5,s2,80001dda <scheduler+0x52>
        p->state = RUNNING;
    80001df4:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001df8:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001dfc:	06048593          	addi	a1,s1,96
    80001e00:	855a                	mv	a0,s6
    80001e02:	5b2000ef          	jal	800023b4 <swtch>
        c->proc = 0;
    80001e06:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001e0a:	8ade                	mv	s5,s7
    80001e0c:	b7f9                	j	80001dda <scheduler+0x52>
    if(found == 0) {
    80001e0e:	000a9463          	bnez	s5,80001e16 <scheduler+0x8e>
      asm volatile("wfi");
    80001e12:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e1e:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001e26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e28:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001e2c:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e2e:	00011497          	auipc	s1,0x11
    80001e32:	8ca48493          	addi	s1,s1,-1846 # 800126f8 <proc>
      if(p->state == RUNNABLE) {
    80001e36:	490d                	li	s2,3
    80001e38:	bf45                	j	80001de8 <scheduler+0x60>

0000000080001e3a <sched>:
{
    80001e3a:	7179                	addi	sp,sp,-48
    80001e3c:	f406                	sd	ra,40(sp)
    80001e3e:	f022                	sd	s0,32(sp)
    80001e40:	ec26                	sd	s1,24(sp)
    80001e42:	e84a                	sd	s2,16(sp)
    80001e44:	e44e                	sd	s3,8(sp)
    80001e46:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e48:	acfff0ef          	jal	80001916 <myproc>
    80001e4c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e4e:	d5ffe0ef          	jal	80000bac <holding>
    80001e52:	c92d                	beqz	a0,80001ec4 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e54:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001e56:	2781                	sext.w	a5,a5
    80001e58:	079e                	slli	a5,a5,0x7
    80001e5a:	00010717          	auipc	a4,0x10
    80001e5e:	46e70713          	addi	a4,a4,1134 # 800122c8 <pid_lock>
    80001e62:	97ba                	add	a5,a5,a4
    80001e64:	0a87a703          	lw	a4,168(a5)
    80001e68:	4785                	li	a5,1
    80001e6a:	06f71363          	bne	a4,a5,80001ed0 <sched+0x96>
  if(p->state == RUNNING)
    80001e6e:	4c98                	lw	a4,24(s1)
    80001e70:	4791                	li	a5,4
    80001e72:	06f70563          	beq	a4,a5,80001edc <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e76:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e7a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e7c:	e7b5                	bnez	a5,80001ee8 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e7e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e80:	00010917          	auipc	s2,0x10
    80001e84:	44890913          	addi	s2,s2,1096 # 800122c8 <pid_lock>
    80001e88:	2781                	sext.w	a5,a5
    80001e8a:	079e                	slli	a5,a5,0x7
    80001e8c:	97ca                	add	a5,a5,s2
    80001e8e:	0ac7a983          	lw	s3,172(a5)
    80001e92:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e94:	2781                	sext.w	a5,a5
    80001e96:	079e                	slli	a5,a5,0x7
    80001e98:	00010597          	auipc	a1,0x10
    80001e9c:	46858593          	addi	a1,a1,1128 # 80012300 <cpus+0x8>
    80001ea0:	95be                	add	a1,a1,a5
    80001ea2:	06048513          	addi	a0,s1,96
    80001ea6:	50e000ef          	jal	800023b4 <swtch>
    80001eaa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001eac:	2781                	sext.w	a5,a5
    80001eae:	079e                	slli	a5,a5,0x7
    80001eb0:	993e                	add	s2,s2,a5
    80001eb2:	0b392623          	sw	s3,172(s2)
}
    80001eb6:	70a2                	ld	ra,40(sp)
    80001eb8:	7402                	ld	s0,32(sp)
    80001eba:	64e2                	ld	s1,24(sp)
    80001ebc:	6942                	ld	s2,16(sp)
    80001ebe:	69a2                	ld	s3,8(sp)
    80001ec0:	6145                	addi	sp,sp,48
    80001ec2:	8082                	ret
    panic("sched p->lock");
    80001ec4:	00005517          	auipc	a0,0x5
    80001ec8:	2d450513          	addi	a0,a0,724 # 80007198 <etext+0x198>
    80001ecc:	915fe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001ed0:	00005517          	auipc	a0,0x5
    80001ed4:	2d850513          	addi	a0,a0,728 # 800071a8 <etext+0x1a8>
    80001ed8:	909fe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001edc:	00005517          	auipc	a0,0x5
    80001ee0:	2dc50513          	addi	a0,a0,732 # 800071b8 <etext+0x1b8>
    80001ee4:	8fdfe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001ee8:	00005517          	auipc	a0,0x5
    80001eec:	2e050513          	addi	a0,a0,736 # 800071c8 <etext+0x1c8>
    80001ef0:	8f1fe0ef          	jal	800007e0 <panic>

0000000080001ef4 <yield>:
{
    80001ef4:	1101                	addi	sp,sp,-32
    80001ef6:	ec06                	sd	ra,24(sp)
    80001ef8:	e822                	sd	s0,16(sp)
    80001efa:	e426                	sd	s1,8(sp)
    80001efc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001efe:	a19ff0ef          	jal	80001916 <myproc>
    80001f02:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f04:	d13fe0ef          	jal	80000c16 <acquire>
  p->state = RUNNABLE;
    80001f08:	478d                	li	a5,3
    80001f0a:	cc9c                	sw	a5,24(s1)
  sched();
    80001f0c:	f2fff0ef          	jal	80001e3a <sched>
  release(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	d9dfe0ef          	jal	80000cae <release>
}
    80001f16:	60e2                	ld	ra,24(sp)
    80001f18:	6442                	ld	s0,16(sp)
    80001f1a:	64a2                	ld	s1,8(sp)
    80001f1c:	6105                	addi	sp,sp,32
    80001f1e:	8082                	ret

0000000080001f20 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f20:	7179                	addi	sp,sp,-48
    80001f22:	f406                	sd	ra,40(sp)
    80001f24:	f022                	sd	s0,32(sp)
    80001f26:	ec26                	sd	s1,24(sp)
    80001f28:	e84a                	sd	s2,16(sp)
    80001f2a:	e44e                	sd	s3,8(sp)
    80001f2c:	1800                	addi	s0,sp,48
    80001f2e:	89aa                	mv	s3,a0
    80001f30:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f32:	9e5ff0ef          	jal	80001916 <myproc>
    80001f36:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f38:	cdffe0ef          	jal	80000c16 <acquire>
  release(lk);
    80001f3c:	854a                	mv	a0,s2
    80001f3e:	d71fe0ef          	jal	80000cae <release>

  // Go to sleep.
  p->chan = chan;
    80001f42:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f46:	4789                	li	a5,2
    80001f48:	cc9c                	sw	a5,24(s1)

  sched();
    80001f4a:	ef1ff0ef          	jal	80001e3a <sched>

  // Tidy up.
  p->chan = 0;
    80001f4e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	d5bfe0ef          	jal	80000cae <release>
  acquire(lk);
    80001f58:	854a                	mv	a0,s2
    80001f5a:	cbdfe0ef          	jal	80000c16 <acquire>
}
    80001f5e:	70a2                	ld	ra,40(sp)
    80001f60:	7402                	ld	s0,32(sp)
    80001f62:	64e2                	ld	s1,24(sp)
    80001f64:	6942                	ld	s2,16(sp)
    80001f66:	69a2                	ld	s3,8(sp)
    80001f68:	6145                	addi	sp,sp,48
    80001f6a:	8082                	ret

0000000080001f6c <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f6c:	7139                	addi	sp,sp,-64
    80001f6e:	fc06                	sd	ra,56(sp)
    80001f70:	f822                	sd	s0,48(sp)
    80001f72:	f426                	sd	s1,40(sp)
    80001f74:	f04a                	sd	s2,32(sp)
    80001f76:	ec4e                	sd	s3,24(sp)
    80001f78:	e852                	sd	s4,16(sp)
    80001f7a:	e456                	sd	s5,8(sp)
    80001f7c:	0080                	addi	s0,sp,64
    80001f7e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	00010497          	auipc	s1,0x10
    80001f84:	77848493          	addi	s1,s1,1912 # 800126f8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f88:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f8a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00016917          	auipc	s2,0x16
    80001f90:	16c90913          	addi	s2,s2,364 # 800180f8 <tickslock>
    80001f94:	a801                	j	80001fa4 <wakeup+0x38>
      }
      release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	d17fe0ef          	jal	80000cae <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f9c:	16848493          	addi	s1,s1,360
    80001fa0:	03248263          	beq	s1,s2,80001fc4 <wakeup+0x58>
    if(p != myproc()){
    80001fa4:	973ff0ef          	jal	80001916 <myproc>
    80001fa8:	fea48ae3          	beq	s1,a0,80001f9c <wakeup+0x30>
      acquire(&p->lock);
    80001fac:	8526                	mv	a0,s1
    80001fae:	c69fe0ef          	jal	80000c16 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fb2:	4c9c                	lw	a5,24(s1)
    80001fb4:	ff3791e3          	bne	a5,s3,80001f96 <wakeup+0x2a>
    80001fb8:	709c                	ld	a5,32(s1)
    80001fba:	fd479ee3          	bne	a5,s4,80001f96 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001fbe:	0154ac23          	sw	s5,24(s1)
    80001fc2:	bfd1                	j	80001f96 <wakeup+0x2a>
    }
  }
}
    80001fc4:	70e2                	ld	ra,56(sp)
    80001fc6:	7442                	ld	s0,48(sp)
    80001fc8:	74a2                	ld	s1,40(sp)
    80001fca:	7902                	ld	s2,32(sp)
    80001fcc:	69e2                	ld	s3,24(sp)
    80001fce:	6a42                	ld	s4,16(sp)
    80001fd0:	6aa2                	ld	s5,8(sp)
    80001fd2:	6121                	addi	sp,sp,64
    80001fd4:	8082                	ret

0000000080001fd6 <reparent>:
{
    80001fd6:	7179                	addi	sp,sp,-48
    80001fd8:	f406                	sd	ra,40(sp)
    80001fda:	f022                	sd	s0,32(sp)
    80001fdc:	ec26                	sd	s1,24(sp)
    80001fde:	e84a                	sd	s2,16(sp)
    80001fe0:	e44e                	sd	s3,8(sp)
    80001fe2:	e052                	sd	s4,0(sp)
    80001fe4:	1800                	addi	s0,sp,48
    80001fe6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fe8:	00010497          	auipc	s1,0x10
    80001fec:	71048493          	addi	s1,s1,1808 # 800126f8 <proc>
      pp->parent = initproc;
    80001ff0:	00008a17          	auipc	s4,0x8
    80001ff4:	1c0a0a13          	addi	s4,s4,448 # 8000a1b0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ff8:	00016997          	auipc	s3,0x16
    80001ffc:	10098993          	addi	s3,s3,256 # 800180f8 <tickslock>
    80002000:	a029                	j	8000200a <reparent+0x34>
    80002002:	16848493          	addi	s1,s1,360
    80002006:	01348b63          	beq	s1,s3,8000201c <reparent+0x46>
    if(pp->parent == p){
    8000200a:	7c9c                	ld	a5,56(s1)
    8000200c:	ff279be3          	bne	a5,s2,80002002 <reparent+0x2c>
      pp->parent = initproc;
    80002010:	000a3503          	ld	a0,0(s4)
    80002014:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002016:	f57ff0ef          	jal	80001f6c <wakeup>
    8000201a:	b7e5                	j	80002002 <reparent+0x2c>
}
    8000201c:	70a2                	ld	ra,40(sp)
    8000201e:	7402                	ld	s0,32(sp)
    80002020:	64e2                	ld	s1,24(sp)
    80002022:	6942                	ld	s2,16(sp)
    80002024:	69a2                	ld	s3,8(sp)
    80002026:	6a02                	ld	s4,0(sp)
    80002028:	6145                	addi	sp,sp,48
    8000202a:	8082                	ret

000000008000202c <kexit>:
{
    8000202c:	7179                	addi	sp,sp,-48
    8000202e:	f406                	sd	ra,40(sp)
    80002030:	f022                	sd	s0,32(sp)
    80002032:	ec26                	sd	s1,24(sp)
    80002034:	e84a                	sd	s2,16(sp)
    80002036:	e44e                	sd	s3,8(sp)
    80002038:	e052                	sd	s4,0(sp)
    8000203a:	1800                	addi	s0,sp,48
    8000203c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000203e:	8d9ff0ef          	jal	80001916 <myproc>
    80002042:	89aa                	mv	s3,a0
  if(p == initproc)
    80002044:	00008797          	auipc	a5,0x8
    80002048:	16c7b783          	ld	a5,364(a5) # 8000a1b0 <initproc>
    8000204c:	0d050493          	addi	s1,a0,208
    80002050:	15050913          	addi	s2,a0,336
    80002054:	00a79f63          	bne	a5,a0,80002072 <kexit+0x46>
    panic("init exiting");
    80002058:	00005517          	auipc	a0,0x5
    8000205c:	18850513          	addi	a0,a0,392 # 800071e0 <etext+0x1e0>
    80002060:	f80fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    80002064:	7bd010ef          	jal	80004020 <fileclose>
      p->ofile[fd] = 0;
    80002068:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000206c:	04a1                	addi	s1,s1,8
    8000206e:	01248563          	beq	s1,s2,80002078 <kexit+0x4c>
    if(p->ofile[fd]){
    80002072:	6088                	ld	a0,0(s1)
    80002074:	f965                	bnez	a0,80002064 <kexit+0x38>
    80002076:	bfdd                	j	8000206c <kexit+0x40>
  begin_op();
    80002078:	39d010ef          	jal	80003c14 <begin_op>
  iput(p->cwd);
    8000207c:	1509b503          	ld	a0,336(s3)
    80002080:	32c010ef          	jal	800033ac <iput>
  end_op();
    80002084:	3fb010ef          	jal	80003c7e <end_op>
  p->cwd = 0;
    80002088:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000208c:	00010497          	auipc	s1,0x10
    80002090:	25448493          	addi	s1,s1,596 # 800122e0 <wait_lock>
    80002094:	8526                	mv	a0,s1
    80002096:	b81fe0ef          	jal	80000c16 <acquire>
  reparent(p);
    8000209a:	854e                	mv	a0,s3
    8000209c:	f3bff0ef          	jal	80001fd6 <reparent>
  wakeup(p->parent);
    800020a0:	0389b503          	ld	a0,56(s3)
    800020a4:	ec9ff0ef          	jal	80001f6c <wakeup>
  acquire(&p->lock);
    800020a8:	854e                	mv	a0,s3
    800020aa:	b6dfe0ef          	jal	80000c16 <acquire>
  p->xstate = status;
    800020ae:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800020b2:	4795                	li	a5,5
    800020b4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	bf5fe0ef          	jal	80000cae <release>
  sched();
    800020be:	d7dff0ef          	jal	80001e3a <sched>
  panic("zombie exit");
    800020c2:	00005517          	auipc	a0,0x5
    800020c6:	12e50513          	addi	a0,a0,302 # 800071f0 <etext+0x1f0>
    800020ca:	f16fe0ef          	jal	800007e0 <panic>

00000000800020ce <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800020ce:	7179                	addi	sp,sp,-48
    800020d0:	f406                	sd	ra,40(sp)
    800020d2:	f022                	sd	s0,32(sp)
    800020d4:	ec26                	sd	s1,24(sp)
    800020d6:	e84a                	sd	s2,16(sp)
    800020d8:	e44e                	sd	s3,8(sp)
    800020da:	1800                	addi	s0,sp,48
    800020dc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800020de:	00010497          	auipc	s1,0x10
    800020e2:	61a48493          	addi	s1,s1,1562 # 800126f8 <proc>
    800020e6:	00016997          	auipc	s3,0x16
    800020ea:	01298993          	addi	s3,s3,18 # 800180f8 <tickslock>
    acquire(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	b27fe0ef          	jal	80000c16 <acquire>
    if(p->pid == pid){
    800020f4:	589c                	lw	a5,48(s1)
    800020f6:	01278b63          	beq	a5,s2,8000210c <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	bb3fe0ef          	jal	80000cae <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002100:	16848493          	addi	s1,s1,360
    80002104:	ff3495e3          	bne	s1,s3,800020ee <kkill+0x20>
  }
  return -1;
    80002108:	557d                	li	a0,-1
    8000210a:	a819                	j	80002120 <kkill+0x52>
      p->killed = 1;
    8000210c:	4785                	li	a5,1
    8000210e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002110:	4c98                	lw	a4,24(s1)
    80002112:	4789                	li	a5,2
    80002114:	00f70d63          	beq	a4,a5,8000212e <kkill+0x60>
      release(&p->lock);
    80002118:	8526                	mv	a0,s1
    8000211a:	b95fe0ef          	jal	80000cae <release>
      return 0;
    8000211e:	4501                	li	a0,0
}
    80002120:	70a2                	ld	ra,40(sp)
    80002122:	7402                	ld	s0,32(sp)
    80002124:	64e2                	ld	s1,24(sp)
    80002126:	6942                	ld	s2,16(sp)
    80002128:	69a2                	ld	s3,8(sp)
    8000212a:	6145                	addi	sp,sp,48
    8000212c:	8082                	ret
        p->state = RUNNABLE;
    8000212e:	478d                	li	a5,3
    80002130:	cc9c                	sw	a5,24(s1)
    80002132:	b7dd                	j	80002118 <kkill+0x4a>

0000000080002134 <setkilled>:

void
setkilled(struct proc *p)
{
    80002134:	1101                	addi	sp,sp,-32
    80002136:	ec06                	sd	ra,24(sp)
    80002138:	e822                	sd	s0,16(sp)
    8000213a:	e426                	sd	s1,8(sp)
    8000213c:	1000                	addi	s0,sp,32
    8000213e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002140:	ad7fe0ef          	jal	80000c16 <acquire>
  p->killed = 1;
    80002144:	4785                	li	a5,1
    80002146:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	b65fe0ef          	jal	80000cae <release>
}
    8000214e:	60e2                	ld	ra,24(sp)
    80002150:	6442                	ld	s0,16(sp)
    80002152:	64a2                	ld	s1,8(sp)
    80002154:	6105                	addi	sp,sp,32
    80002156:	8082                	ret

0000000080002158 <killed>:

int
killed(struct proc *p)
{
    80002158:	1101                	addi	sp,sp,-32
    8000215a:	ec06                	sd	ra,24(sp)
    8000215c:	e822                	sd	s0,16(sp)
    8000215e:	e426                	sd	s1,8(sp)
    80002160:	e04a                	sd	s2,0(sp)
    80002162:	1000                	addi	s0,sp,32
    80002164:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002166:	ab1fe0ef          	jal	80000c16 <acquire>
  k = p->killed;
    8000216a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000216e:	8526                	mv	a0,s1
    80002170:	b3ffe0ef          	jal	80000cae <release>
  return k;
}
    80002174:	854a                	mv	a0,s2
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6902                	ld	s2,0(sp)
    8000217e:	6105                	addi	sp,sp,32
    80002180:	8082                	ret

0000000080002182 <kwait>:
{
    80002182:	715d                	addi	sp,sp,-80
    80002184:	e486                	sd	ra,72(sp)
    80002186:	e0a2                	sd	s0,64(sp)
    80002188:	fc26                	sd	s1,56(sp)
    8000218a:	f84a                	sd	s2,48(sp)
    8000218c:	f44e                	sd	s3,40(sp)
    8000218e:	f052                	sd	s4,32(sp)
    80002190:	ec56                	sd	s5,24(sp)
    80002192:	e85a                	sd	s6,16(sp)
    80002194:	e45e                	sd	s7,8(sp)
    80002196:	e062                	sd	s8,0(sp)
    80002198:	0880                	addi	s0,sp,80
    8000219a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000219c:	f7aff0ef          	jal	80001916 <myproc>
    800021a0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021a2:	00010517          	auipc	a0,0x10
    800021a6:	13e50513          	addi	a0,a0,318 # 800122e0 <wait_lock>
    800021aa:	a6dfe0ef          	jal	80000c16 <acquire>
    havekids = 0;
    800021ae:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800021b0:	4a15                	li	s4,5
        havekids = 1;
    800021b2:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b4:	00016997          	auipc	s3,0x16
    800021b8:	f4498993          	addi	s3,s3,-188 # 800180f8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021bc:	00010c17          	auipc	s8,0x10
    800021c0:	124c0c13          	addi	s8,s8,292 # 800122e0 <wait_lock>
    800021c4:	a871                	j	80002260 <kwait+0xde>
          pid = pp->pid;
    800021c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800021ca:	000b0c63          	beqz	s6,800021e2 <kwait+0x60>
    800021ce:	4691                	li	a3,4
    800021d0:	02c48613          	addi	a2,s1,44
    800021d4:	85da                	mv	a1,s6
    800021d6:	05093503          	ld	a0,80(s2)
    800021da:	c50ff0ef          	jal	8000162a <copyout>
    800021de:	02054b63          	bltz	a0,80002214 <kwait+0x92>
          freeproc(pp);
    800021e2:	8526                	mv	a0,s1
    800021e4:	903ff0ef          	jal	80001ae6 <freeproc>
          release(&pp->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	ac5fe0ef          	jal	80000cae <release>
          release(&wait_lock);
    800021ee:	00010517          	auipc	a0,0x10
    800021f2:	0f250513          	addi	a0,a0,242 # 800122e0 <wait_lock>
    800021f6:	ab9fe0ef          	jal	80000cae <release>
}
    800021fa:	854e                	mv	a0,s3
    800021fc:	60a6                	ld	ra,72(sp)
    800021fe:	6406                	ld	s0,64(sp)
    80002200:	74e2                	ld	s1,56(sp)
    80002202:	7942                	ld	s2,48(sp)
    80002204:	79a2                	ld	s3,40(sp)
    80002206:	7a02                	ld	s4,32(sp)
    80002208:	6ae2                	ld	s5,24(sp)
    8000220a:	6b42                	ld	s6,16(sp)
    8000220c:	6ba2                	ld	s7,8(sp)
    8000220e:	6c02                	ld	s8,0(sp)
    80002210:	6161                	addi	sp,sp,80
    80002212:	8082                	ret
            release(&pp->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	a99fe0ef          	jal	80000cae <release>
            release(&wait_lock);
    8000221a:	00010517          	auipc	a0,0x10
    8000221e:	0c650513          	addi	a0,a0,198 # 800122e0 <wait_lock>
    80002222:	a8dfe0ef          	jal	80000cae <release>
            return -1;
    80002226:	59fd                	li	s3,-1
    80002228:	bfc9                	j	800021fa <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222a:	16848493          	addi	s1,s1,360
    8000222e:	03348063          	beq	s1,s3,8000224e <kwait+0xcc>
      if(pp->parent == p){
    80002232:	7c9c                	ld	a5,56(s1)
    80002234:	ff279be3          	bne	a5,s2,8000222a <kwait+0xa8>
        acquire(&pp->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	9ddfe0ef          	jal	80000c16 <acquire>
        if(pp->state == ZOMBIE){
    8000223e:	4c9c                	lw	a5,24(s1)
    80002240:	f94783e3          	beq	a5,s4,800021c6 <kwait+0x44>
        release(&pp->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	a69fe0ef          	jal	80000cae <release>
        havekids = 1;
    8000224a:	8756                	mv	a4,s5
    8000224c:	bff9                	j	8000222a <kwait+0xa8>
    if(!havekids || killed(p)){
    8000224e:	cf19                	beqz	a4,8000226c <kwait+0xea>
    80002250:	854a                	mv	a0,s2
    80002252:	f07ff0ef          	jal	80002158 <killed>
    80002256:	e919                	bnez	a0,8000226c <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002258:	85e2                	mv	a1,s8
    8000225a:	854a                	mv	a0,s2
    8000225c:	cc5ff0ef          	jal	80001f20 <sleep>
    havekids = 0;
    80002260:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002262:	00010497          	auipc	s1,0x10
    80002266:	49648493          	addi	s1,s1,1174 # 800126f8 <proc>
    8000226a:	b7e1                	j	80002232 <kwait+0xb0>
      release(&wait_lock);
    8000226c:	00010517          	auipc	a0,0x10
    80002270:	07450513          	addi	a0,a0,116 # 800122e0 <wait_lock>
    80002274:	a3bfe0ef          	jal	80000cae <release>
      return -1;
    80002278:	59fd                	li	s3,-1
    8000227a:	b741                	j	800021fa <kwait+0x78>

000000008000227c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	e052                	sd	s4,0(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	84aa                	mv	s1,a0
    8000228e:	892e                	mv	s2,a1
    80002290:	89b2                	mv	s3,a2
    80002292:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002294:	e82ff0ef          	jal	80001916 <myproc>
  if(user_dst){
    80002298:	cc99                	beqz	s1,800022b6 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000229a:	86d2                	mv	a3,s4
    8000229c:	864e                	mv	a2,s3
    8000229e:	85ca                	mv	a1,s2
    800022a0:	6928                	ld	a0,80(a0)
    800022a2:	b88ff0ef          	jal	8000162a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6a02                	ld	s4,0(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret
    memmove((char *)dst, src, len);
    800022b6:	000a061b          	sext.w	a2,s4
    800022ba:	85ce                	mv	a1,s3
    800022bc:	854a                	mv	a0,s2
    800022be:	a89fe0ef          	jal	80000d46 <memmove>
    return 0;
    800022c2:	8526                	mv	a0,s1
    800022c4:	b7cd                	j	800022a6 <either_copyout+0x2a>

00000000800022c6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800022c6:	7179                	addi	sp,sp,-48
    800022c8:	f406                	sd	ra,40(sp)
    800022ca:	f022                	sd	s0,32(sp)
    800022cc:	ec26                	sd	s1,24(sp)
    800022ce:	e84a                	sd	s2,16(sp)
    800022d0:	e44e                	sd	s3,8(sp)
    800022d2:	e052                	sd	s4,0(sp)
    800022d4:	1800                	addi	s0,sp,48
    800022d6:	892a                	mv	s2,a0
    800022d8:	84ae                	mv	s1,a1
    800022da:	89b2                	mv	s3,a2
    800022dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022de:	e38ff0ef          	jal	80001916 <myproc>
  if(user_src){
    800022e2:	cc99                	beqz	s1,80002300 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800022e4:	86d2                	mv	a3,s4
    800022e6:	864e                	mv	a2,s3
    800022e8:	85ca                	mv	a1,s2
    800022ea:	6928                	ld	a0,80(a0)
    800022ec:	c22ff0ef          	jal	8000170e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800022f0:	70a2                	ld	ra,40(sp)
    800022f2:	7402                	ld	s0,32(sp)
    800022f4:	64e2                	ld	s1,24(sp)
    800022f6:	6942                	ld	s2,16(sp)
    800022f8:	69a2                	ld	s3,8(sp)
    800022fa:	6a02                	ld	s4,0(sp)
    800022fc:	6145                	addi	sp,sp,48
    800022fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002300:	000a061b          	sext.w	a2,s4
    80002304:	85ce                	mv	a1,s3
    80002306:	854a                	mv	a0,s2
    80002308:	a3ffe0ef          	jal	80000d46 <memmove>
    return 0;
    8000230c:	8526                	mv	a0,s1
    8000230e:	b7cd                	j	800022f0 <either_copyin+0x2a>

0000000080002310 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002310:	715d                	addi	sp,sp,-80
    80002312:	e486                	sd	ra,72(sp)
    80002314:	e0a2                	sd	s0,64(sp)
    80002316:	fc26                	sd	s1,56(sp)
    80002318:	f84a                	sd	s2,48(sp)
    8000231a:	f44e                	sd	s3,40(sp)
    8000231c:	f052                	sd	s4,32(sp)
    8000231e:	ec56                	sd	s5,24(sp)
    80002320:	e85a                	sd	s6,16(sp)
    80002322:	e45e                	sd	s7,8(sp)
    80002324:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002326:	00005517          	auipc	a0,0x5
    8000232a:	d5250513          	addi	a0,a0,-686 # 80007078 <etext+0x78>
    8000232e:	9ccfe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002332:	00010497          	auipc	s1,0x10
    80002336:	51e48493          	addi	s1,s1,1310 # 80012850 <proc+0x158>
    8000233a:	00016917          	auipc	s2,0x16
    8000233e:	f1690913          	addi	s2,s2,-234 # 80018250 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002342:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002344:	00005997          	auipc	s3,0x5
    80002348:	ebc98993          	addi	s3,s3,-324 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    8000234c:	00005a97          	auipc	s5,0x5
    80002350:	ebca8a93          	addi	s5,s5,-324 # 80007208 <etext+0x208>
    printf("\n");
    80002354:	00005a17          	auipc	s4,0x5
    80002358:	d24a0a13          	addi	s4,s4,-732 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000235c:	00005b97          	auipc	s7,0x5
    80002360:	3ccb8b93          	addi	s7,s7,972 # 80007728 <states.0>
    80002364:	a829                	j	8000237e <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002366:	ed86a583          	lw	a1,-296(a3)
    8000236a:	8556                	mv	a0,s5
    8000236c:	98efe0ef          	jal	800004fa <printf>
    printf("\n");
    80002370:	8552                	mv	a0,s4
    80002372:	988fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002376:	16848493          	addi	s1,s1,360
    8000237a:	03248263          	beq	s1,s2,8000239e <procdump+0x8e>
    if(p->state == UNUSED)
    8000237e:	86a6                	mv	a3,s1
    80002380:	ec04a783          	lw	a5,-320(s1)
    80002384:	dbed                	beqz	a5,80002376 <procdump+0x66>
      state = "???";
    80002386:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002388:	fcfb6fe3          	bltu	s6,a5,80002366 <procdump+0x56>
    8000238c:	02079713          	slli	a4,a5,0x20
    80002390:	01d75793          	srli	a5,a4,0x1d
    80002394:	97de                	add	a5,a5,s7
    80002396:	6390                	ld	a2,0(a5)
    80002398:	f679                	bnez	a2,80002366 <procdump+0x56>
      state = "???";
    8000239a:	864e                	mv	a2,s3
    8000239c:	b7e9                	j	80002366 <procdump+0x56>
  }
}
    8000239e:	60a6                	ld	ra,72(sp)
    800023a0:	6406                	ld	s0,64(sp)
    800023a2:	74e2                	ld	s1,56(sp)
    800023a4:	7942                	ld	s2,48(sp)
    800023a6:	79a2                	ld	s3,40(sp)
    800023a8:	7a02                	ld	s4,32(sp)
    800023aa:	6ae2                	ld	s5,24(sp)
    800023ac:	6b42                	ld	s6,16(sp)
    800023ae:	6ba2                	ld	s7,8(sp)
    800023b0:	6161                	addi	sp,sp,80
    800023b2:	8082                	ret

00000000800023b4 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800023b4:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800023b8:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800023bc:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800023be:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800023c0:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800023c4:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800023c8:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800023cc:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800023d0:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800023d4:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800023d8:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800023dc:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800023e0:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800023e4:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800023e8:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800023ec:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800023f0:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800023f2:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800023f4:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800023f8:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    800023fc:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002400:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002404:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002408:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    8000240c:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002410:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002414:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002418:	0685bd83          	ld	s11,104(a1)
        
        ret
    8000241c:	8082                	ret

000000008000241e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000241e:	1141                	addi	sp,sp,-16
    80002420:	e406                	sd	ra,8(sp)
    80002422:	e022                	sd	s0,0(sp)
    80002424:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002426:	00005597          	auipc	a1,0x5
    8000242a:	e2258593          	addi	a1,a1,-478 # 80007248 <etext+0x248>
    8000242e:	00016517          	auipc	a0,0x16
    80002432:	cca50513          	addi	a0,a0,-822 # 800180f8 <tickslock>
    80002436:	f60fe0ef          	jal	80000b96 <initlock>
}
    8000243a:	60a2                	ld	ra,8(sp)
    8000243c:	6402                	ld	s0,0(sp)
    8000243e:	0141                	addi	sp,sp,16
    80002440:	8082                	ret

0000000080002442 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002442:	1141                	addi	sp,sp,-16
    80002444:	e422                	sd	s0,8(sp)
    80002446:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002448:	00003797          	auipc	a5,0x3
    8000244c:	f5878793          	addi	a5,a5,-168 # 800053a0 <kernelvec>
    80002450:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002454:	6422                	ld	s0,8(sp)
    80002456:	0141                	addi	sp,sp,16
    80002458:	8082                	ret

000000008000245a <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000245a:	1141                	addi	sp,sp,-16
    8000245c:	e406                	sd	ra,8(sp)
    8000245e:	e022                	sd	s0,0(sp)
    80002460:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002462:	cb4ff0ef          	jal	80001916 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002466:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000246a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000246c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002470:	04000737          	lui	a4,0x4000
    80002474:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80002476:	0732                	slli	a4,a4,0xc
    80002478:	00004797          	auipc	a5,0x4
    8000247c:	b8878793          	addi	a5,a5,-1144 # 80006000 <_trampoline>
    80002480:	00004697          	auipc	a3,0x4
    80002484:	b8068693          	addi	a3,a3,-1152 # 80006000 <_trampoline>
    80002488:	8f95                	sub	a5,a5,a3
    8000248a:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000248c:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002490:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002492:	18002773          	csrr	a4,satp
    80002496:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002498:	6d38                	ld	a4,88(a0)
    8000249a:	613c                	ld	a5,64(a0)
    8000249c:	6685                	lui	a3,0x1
    8000249e:	97b6                	add	a5,a5,a3
    800024a0:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800024a2:	6d3c                	ld	a5,88(a0)
    800024a4:	00000717          	auipc	a4,0x0
    800024a8:	0f870713          	addi	a4,a4,248 # 8000259c <usertrap>
    800024ac:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800024ae:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800024b0:	8712                	mv	a4,tp
    800024b2:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024b4:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800024b8:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800024bc:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024c0:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800024c4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024c6:	6f9c                	ld	a5,24(a5)
    800024c8:	14179073          	csrw	sepc,a5
}
    800024cc:	60a2                	ld	ra,8(sp)
    800024ce:	6402                	ld	s0,0(sp)
    800024d0:	0141                	addi	sp,sp,16
    800024d2:	8082                	ret

00000000800024d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800024d4:	1101                	addi	sp,sp,-32
    800024d6:	ec06                	sd	ra,24(sp)
    800024d8:	e822                	sd	s0,16(sp)
    800024da:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800024dc:	c0eff0ef          	jal	800018ea <cpuid>
    800024e0:	cd11                	beqz	a0,800024fc <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    800024e2:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800024e6:	000f4737          	lui	a4,0xf4
    800024ea:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800024ee:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800024f0:	14d79073          	csrw	stimecmp,a5
}
    800024f4:	60e2                	ld	ra,24(sp)
    800024f6:	6442                	ld	s0,16(sp)
    800024f8:	6105                	addi	sp,sp,32
    800024fa:	8082                	ret
    800024fc:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    800024fe:	00016497          	auipc	s1,0x16
    80002502:	bfa48493          	addi	s1,s1,-1030 # 800180f8 <tickslock>
    80002506:	8526                	mv	a0,s1
    80002508:	f0efe0ef          	jal	80000c16 <acquire>
    ticks++;
    8000250c:	00008517          	auipc	a0,0x8
    80002510:	cac50513          	addi	a0,a0,-852 # 8000a1b8 <ticks>
    80002514:	411c                	lw	a5,0(a0)
    80002516:	2785                	addiw	a5,a5,1
    80002518:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    8000251a:	a53ff0ef          	jal	80001f6c <wakeup>
    release(&tickslock);
    8000251e:	8526                	mv	a0,s1
    80002520:	f8efe0ef          	jal	80000cae <release>
    80002524:	64a2                	ld	s1,8(sp)
    80002526:	bf75                	j	800024e2 <clockintr+0xe>

0000000080002528 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002528:	1101                	addi	sp,sp,-32
    8000252a:	ec06                	sd	ra,24(sp)
    8000252c:	e822                	sd	s0,16(sp)
    8000252e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002530:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002534:	57fd                	li	a5,-1
    80002536:	17fe                	slli	a5,a5,0x3f
    80002538:	07a5                	addi	a5,a5,9
    8000253a:	00f70c63          	beq	a4,a5,80002552 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    8000253e:	57fd                	li	a5,-1
    80002540:	17fe                	slli	a5,a5,0x3f
    80002542:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002544:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002546:	04f70763          	beq	a4,a5,80002594 <devintr+0x6c>
  }
}
    8000254a:	60e2                	ld	ra,24(sp)
    8000254c:	6442                	ld	s0,16(sp)
    8000254e:	6105                	addi	sp,sp,32
    80002550:	8082                	ret
    80002552:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002554:	6f9020ef          	jal	8000544c <plic_claim>
    80002558:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000255a:	47a9                	li	a5,10
    8000255c:	00f50963          	beq	a0,a5,8000256e <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80002560:	4785                	li	a5,1
    80002562:	00f50963          	beq	a0,a5,80002574 <devintr+0x4c>
    return 1;
    80002566:	4505                	li	a0,1
    } else if(irq){
    80002568:	e889                	bnez	s1,8000257a <devintr+0x52>
    8000256a:	64a2                	ld	s1,8(sp)
    8000256c:	bff9                	j	8000254a <devintr+0x22>
      uartintr();
    8000256e:	c42fe0ef          	jal	800009b0 <uartintr>
    if(irq)
    80002572:	a819                	j	80002588 <devintr+0x60>
      virtio_disk_intr();
    80002574:	39e030ef          	jal	80005912 <virtio_disk_intr>
    if(irq)
    80002578:	a801                	j	80002588 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    8000257a:	85a6                	mv	a1,s1
    8000257c:	00005517          	auipc	a0,0x5
    80002580:	cd450513          	addi	a0,a0,-812 # 80007250 <etext+0x250>
    80002584:	f77fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    80002588:	8526                	mv	a0,s1
    8000258a:	6e3020ef          	jal	8000546c <plic_complete>
    return 1;
    8000258e:	4505                	li	a0,1
    80002590:	64a2                	ld	s1,8(sp)
    80002592:	bf65                	j	8000254a <devintr+0x22>
    clockintr();
    80002594:	f41ff0ef          	jal	800024d4 <clockintr>
    return 2;
    80002598:	4509                	li	a0,2
    8000259a:	bf45                	j	8000254a <devintr+0x22>

000000008000259c <usertrap>:
{
    8000259c:	1101                	addi	sp,sp,-32
    8000259e:	ec06                	sd	ra,24(sp)
    800025a0:	e822                	sd	s0,16(sp)
    800025a2:	e426                	sd	s1,8(sp)
    800025a4:	e04a                	sd	s2,0(sp)
    800025a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800025ac:	1007f793          	andi	a5,a5,256
    800025b0:	eba5                	bnez	a5,80002620 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025b2:	00003797          	auipc	a5,0x3
    800025b6:	dee78793          	addi	a5,a5,-530 # 800053a0 <kernelvec>
    800025ba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800025be:	b58ff0ef          	jal	80001916 <myproc>
    800025c2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800025c4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025c6:	14102773          	csrr	a4,sepc
    800025ca:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025cc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800025d0:	47a1                	li	a5,8
    800025d2:	04f70d63          	beq	a4,a5,8000262c <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800025d6:	f53ff0ef          	jal	80002528 <devintr>
    800025da:	892a                	mv	s2,a0
    800025dc:	e945                	bnez	a0,8000268c <usertrap+0xf0>
    800025de:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800025e2:	47bd                	li	a5,15
    800025e4:	08f70863          	beq	a4,a5,80002674 <usertrap+0xd8>
    800025e8:	14202773          	csrr	a4,scause
    800025ec:	47b5                	li	a5,13
    800025ee:	08f70363          	beq	a4,a5,80002674 <usertrap+0xd8>
    800025f2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800025f6:	5890                	lw	a2,48(s1)
    800025f8:	00005517          	auipc	a0,0x5
    800025fc:	c9850513          	addi	a0,a0,-872 # 80007290 <etext+0x290>
    80002600:	efbfd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002604:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002608:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    8000260c:	00005517          	auipc	a0,0x5
    80002610:	cb450513          	addi	a0,a0,-844 # 800072c0 <etext+0x2c0>
    80002614:	ee7fd0ef          	jal	800004fa <printf>
    setkilled(p);
    80002618:	8526                	mv	a0,s1
    8000261a:	b1bff0ef          	jal	80002134 <setkilled>
    8000261e:	a035                	j	8000264a <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002620:	00005517          	auipc	a0,0x5
    80002624:	c5050513          	addi	a0,a0,-944 # 80007270 <etext+0x270>
    80002628:	9b8fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    8000262c:	b2dff0ef          	jal	80002158 <killed>
    80002630:	ed15                	bnez	a0,8000266c <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002632:	6cb8                	ld	a4,88(s1)
    80002634:	6f1c                	ld	a5,24(a4)
    80002636:	0791                	addi	a5,a5,4
    80002638:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000263e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002642:	10079073          	csrw	sstatus,a5
    syscall();
    80002646:	246000ef          	jal	8000288c <syscall>
  if(killed(p))
    8000264a:	8526                	mv	a0,s1
    8000264c:	b0dff0ef          	jal	80002158 <killed>
    80002650:	e139                	bnez	a0,80002696 <usertrap+0xfa>
  prepare_return();
    80002652:	e09ff0ef          	jal	8000245a <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002656:	68a8                	ld	a0,80(s1)
    80002658:	8131                	srli	a0,a0,0xc
    8000265a:	57fd                	li	a5,-1
    8000265c:	17fe                	slli	a5,a5,0x3f
    8000265e:	8d5d                	or	a0,a0,a5
}
    80002660:	60e2                	ld	ra,24(sp)
    80002662:	6442                	ld	s0,16(sp)
    80002664:	64a2                	ld	s1,8(sp)
    80002666:	6902                	ld	s2,0(sp)
    80002668:	6105                	addi	sp,sp,32
    8000266a:	8082                	ret
      kexit(-1);
    8000266c:	557d                	li	a0,-1
    8000266e:	9bfff0ef          	jal	8000202c <kexit>
    80002672:	b7c1                	j	80002632 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002674:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002678:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    8000267c:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    8000267e:	00163613          	seqz	a2,a2
    80002682:	68a8                	ld	a0,80(s1)
    80002684:	f25fe0ef          	jal	800015a8 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002688:	f169                	bnez	a0,8000264a <usertrap+0xae>
    8000268a:	b7a5                	j	800025f2 <usertrap+0x56>
  if(killed(p))
    8000268c:	8526                	mv	a0,s1
    8000268e:	acbff0ef          	jal	80002158 <killed>
    80002692:	c511                	beqz	a0,8000269e <usertrap+0x102>
    80002694:	a011                	j	80002698 <usertrap+0xfc>
    80002696:	4901                	li	s2,0
    kexit(-1);
    80002698:	557d                	li	a0,-1
    8000269a:	993ff0ef          	jal	8000202c <kexit>
  if(which_dev == 2)
    8000269e:	4789                	li	a5,2
    800026a0:	faf919e3          	bne	s2,a5,80002652 <usertrap+0xb6>
    yield();
    800026a4:	851ff0ef          	jal	80001ef4 <yield>
    800026a8:	b76d                	j	80002652 <usertrap+0xb6>

00000000800026aa <kerneltrap>:
{
    800026aa:	7179                	addi	sp,sp,-48
    800026ac:	f406                	sd	ra,40(sp)
    800026ae:	f022                	sd	s0,32(sp)
    800026b0:	ec26                	sd	s1,24(sp)
    800026b2:	e84a                	sd	s2,16(sp)
    800026b4:	e44e                	sd	s3,8(sp)
    800026b6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026bc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026c0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800026c4:	1004f793          	andi	a5,s1,256
    800026c8:	c795                	beqz	a5,800026f4 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026ce:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800026d0:	eb85                	bnez	a5,80002700 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800026d2:	e57ff0ef          	jal	80002528 <devintr>
    800026d6:	c91d                	beqz	a0,8000270c <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    800026d8:	4789                	li	a5,2
    800026da:	04f50a63          	beq	a0,a5,8000272e <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026de:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e2:	10049073          	csrw	sstatus,s1
}
    800026e6:	70a2                	ld	ra,40(sp)
    800026e8:	7402                	ld	s0,32(sp)
    800026ea:	64e2                	ld	s1,24(sp)
    800026ec:	6942                	ld	s2,16(sp)
    800026ee:	69a2                	ld	s3,8(sp)
    800026f0:	6145                	addi	sp,sp,48
    800026f2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800026f4:	00005517          	auipc	a0,0x5
    800026f8:	bf450513          	addi	a0,a0,-1036 # 800072e8 <etext+0x2e8>
    800026fc:	8e4fe0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002700:	00005517          	auipc	a0,0x5
    80002704:	c1050513          	addi	a0,a0,-1008 # 80007310 <etext+0x310>
    80002708:	8d8fe0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000270c:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002710:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002714:	85ce                	mv	a1,s3
    80002716:	00005517          	auipc	a0,0x5
    8000271a:	c1a50513          	addi	a0,a0,-998 # 80007330 <etext+0x330>
    8000271e:	dddfd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    80002722:	00005517          	auipc	a0,0x5
    80002726:	c3650513          	addi	a0,a0,-970 # 80007358 <etext+0x358>
    8000272a:	8b6fe0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    8000272e:	9e8ff0ef          	jal	80001916 <myproc>
    80002732:	d555                	beqz	a0,800026de <kerneltrap+0x34>
    yield();
    80002734:	fc0ff0ef          	jal	80001ef4 <yield>
    80002738:	b75d                	j	800026de <kerneltrap+0x34>

000000008000273a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000273a:	1101                	addi	sp,sp,-32
    8000273c:	ec06                	sd	ra,24(sp)
    8000273e:	e822                	sd	s0,16(sp)
    80002740:	e426                	sd	s1,8(sp)
    80002742:	1000                	addi	s0,sp,32
    80002744:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002746:	9d0ff0ef          	jal	80001916 <myproc>
  switch (n) {
    8000274a:	4795                	li	a5,5
    8000274c:	0497e163          	bltu	a5,s1,8000278e <argraw+0x54>
    80002750:	048a                	slli	s1,s1,0x2
    80002752:	00005717          	auipc	a4,0x5
    80002756:	00670713          	addi	a4,a4,6 # 80007758 <states.0+0x30>
    8000275a:	94ba                	add	s1,s1,a4
    8000275c:	409c                	lw	a5,0(s1)
    8000275e:	97ba                	add	a5,a5,a4
    80002760:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002762:	6d3c                	ld	a5,88(a0)
    80002764:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002766:	60e2                	ld	ra,24(sp)
    80002768:	6442                	ld	s0,16(sp)
    8000276a:	64a2                	ld	s1,8(sp)
    8000276c:	6105                	addi	sp,sp,32
    8000276e:	8082                	ret
    return p->trapframe->a1;
    80002770:	6d3c                	ld	a5,88(a0)
    80002772:	7fa8                	ld	a0,120(a5)
    80002774:	bfcd                	j	80002766 <argraw+0x2c>
    return p->trapframe->a2;
    80002776:	6d3c                	ld	a5,88(a0)
    80002778:	63c8                	ld	a0,128(a5)
    8000277a:	b7f5                	j	80002766 <argraw+0x2c>
    return p->trapframe->a3;
    8000277c:	6d3c                	ld	a5,88(a0)
    8000277e:	67c8                	ld	a0,136(a5)
    80002780:	b7dd                	j	80002766 <argraw+0x2c>
    return p->trapframe->a4;
    80002782:	6d3c                	ld	a5,88(a0)
    80002784:	6bc8                	ld	a0,144(a5)
    80002786:	b7c5                	j	80002766 <argraw+0x2c>
    return p->trapframe->a5;
    80002788:	6d3c                	ld	a5,88(a0)
    8000278a:	6fc8                	ld	a0,152(a5)
    8000278c:	bfe9                	j	80002766 <argraw+0x2c>
  panic("argraw");
    8000278e:	00005517          	auipc	a0,0x5
    80002792:	bda50513          	addi	a0,a0,-1062 # 80007368 <etext+0x368>
    80002796:	84afe0ef          	jal	800007e0 <panic>

000000008000279a <fetchaddr>:
{
    8000279a:	1101                	addi	sp,sp,-32
    8000279c:	ec06                	sd	ra,24(sp)
    8000279e:	e822                	sd	s0,16(sp)
    800027a0:	e426                	sd	s1,8(sp)
    800027a2:	e04a                	sd	s2,0(sp)
    800027a4:	1000                	addi	s0,sp,32
    800027a6:	84aa                	mv	s1,a0
    800027a8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800027aa:	96cff0ef          	jal	80001916 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800027ae:	653c                	ld	a5,72(a0)
    800027b0:	02f4f663          	bgeu	s1,a5,800027dc <fetchaddr+0x42>
    800027b4:	00848713          	addi	a4,s1,8
    800027b8:	02e7e463          	bltu	a5,a4,800027e0 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800027bc:	46a1                	li	a3,8
    800027be:	8626                	mv	a2,s1
    800027c0:	85ca                	mv	a1,s2
    800027c2:	6928                	ld	a0,80(a0)
    800027c4:	f4bfe0ef          	jal	8000170e <copyin>
    800027c8:	00a03533          	snez	a0,a0
    800027cc:	40a00533          	neg	a0,a0
}
    800027d0:	60e2                	ld	ra,24(sp)
    800027d2:	6442                	ld	s0,16(sp)
    800027d4:	64a2                	ld	s1,8(sp)
    800027d6:	6902                	ld	s2,0(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret
    return -1;
    800027dc:	557d                	li	a0,-1
    800027de:	bfcd                	j	800027d0 <fetchaddr+0x36>
    800027e0:	557d                	li	a0,-1
    800027e2:	b7fd                	j	800027d0 <fetchaddr+0x36>

00000000800027e4 <fetchstr>:
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	1800                	addi	s0,sp,48
    800027f2:	892a                	mv	s2,a0
    800027f4:	84ae                	mv	s1,a1
    800027f6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800027f8:	91eff0ef          	jal	80001916 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800027fc:	86ce                	mv	a3,s3
    800027fe:	864a                	mv	a2,s2
    80002800:	85a6                	mv	a1,s1
    80002802:	6928                	ld	a0,80(a0)
    80002804:	ccdfe0ef          	jal	800014d0 <copyinstr>
    80002808:	00054c63          	bltz	a0,80002820 <fetchstr+0x3c>
  return strlen(buf);
    8000280c:	8526                	mv	a0,s1
    8000280e:	e4cfe0ef          	jal	80000e5a <strlen>
}
    80002812:	70a2                	ld	ra,40(sp)
    80002814:	7402                	ld	s0,32(sp)
    80002816:	64e2                	ld	s1,24(sp)
    80002818:	6942                	ld	s2,16(sp)
    8000281a:	69a2                	ld	s3,8(sp)
    8000281c:	6145                	addi	sp,sp,48
    8000281e:	8082                	ret
    return -1;
    80002820:	557d                	li	a0,-1
    80002822:	bfc5                	j	80002812 <fetchstr+0x2e>

0000000080002824 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002824:	1101                	addi	sp,sp,-32
    80002826:	ec06                	sd	ra,24(sp)
    80002828:	e822                	sd	s0,16(sp)
    8000282a:	e426                	sd	s1,8(sp)
    8000282c:	1000                	addi	s0,sp,32
    8000282e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002830:	f0bff0ef          	jal	8000273a <argraw>
    80002834:	c088                	sw	a0,0(s1)
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret

0000000080002840 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002840:	1101                	addi	sp,sp,-32
    80002842:	ec06                	sd	ra,24(sp)
    80002844:	e822                	sd	s0,16(sp)
    80002846:	e426                	sd	s1,8(sp)
    80002848:	1000                	addi	s0,sp,32
    8000284a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000284c:	eefff0ef          	jal	8000273a <argraw>
    80002850:	e088                	sd	a0,0(s1)
}
    80002852:	60e2                	ld	ra,24(sp)
    80002854:	6442                	ld	s0,16(sp)
    80002856:	64a2                	ld	s1,8(sp)
    80002858:	6105                	addi	sp,sp,32
    8000285a:	8082                	ret

000000008000285c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000285c:	7179                	addi	sp,sp,-48
    8000285e:	f406                	sd	ra,40(sp)
    80002860:	f022                	sd	s0,32(sp)
    80002862:	ec26                	sd	s1,24(sp)
    80002864:	e84a                	sd	s2,16(sp)
    80002866:	1800                	addi	s0,sp,48
    80002868:	84ae                	mv	s1,a1
    8000286a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000286c:	fd840593          	addi	a1,s0,-40
    80002870:	fd1ff0ef          	jal	80002840 <argaddr>
  return fetchstr(addr, buf, max);
    80002874:	864a                	mv	a2,s2
    80002876:	85a6                	mv	a1,s1
    80002878:	fd843503          	ld	a0,-40(s0)
    8000287c:	f69ff0ef          	jal	800027e4 <fetchstr>
}
    80002880:	70a2                	ld	ra,40(sp)
    80002882:	7402                	ld	s0,32(sp)
    80002884:	64e2                	ld	s1,24(sp)
    80002886:	6942                	ld	s2,16(sp)
    80002888:	6145                	addi	sp,sp,48
    8000288a:	8082                	ret

000000008000288c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000288c:	1101                	addi	sp,sp,-32
    8000288e:	ec06                	sd	ra,24(sp)
    80002890:	e822                	sd	s0,16(sp)
    80002892:	e426                	sd	s1,8(sp)
    80002894:	e04a                	sd	s2,0(sp)
    80002896:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002898:	87eff0ef          	jal	80001916 <myproc>
    8000289c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000289e:	05853903          	ld	s2,88(a0)
    800028a2:	0a893783          	ld	a5,168(s2)
    800028a6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800028aa:	37fd                	addiw	a5,a5,-1
    800028ac:	4751                	li	a4,20
    800028ae:	00f76f63          	bltu	a4,a5,800028cc <syscall+0x40>
    800028b2:	00369713          	slli	a4,a3,0x3
    800028b6:	00005797          	auipc	a5,0x5
    800028ba:	eba78793          	addi	a5,a5,-326 # 80007770 <syscalls>
    800028be:	97ba                	add	a5,a5,a4
    800028c0:	639c                	ld	a5,0(a5)
    800028c2:	c789                	beqz	a5,800028cc <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800028c4:	9782                	jalr	a5
    800028c6:	06a93823          	sd	a0,112(s2)
    800028ca:	a829                	j	800028e4 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800028cc:	15848613          	addi	a2,s1,344
    800028d0:	588c                	lw	a1,48(s1)
    800028d2:	00005517          	auipc	a0,0x5
    800028d6:	a9e50513          	addi	a0,a0,-1378 # 80007370 <etext+0x370>
    800028da:	c21fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800028de:	6cbc                	ld	a5,88(s1)
    800028e0:	577d                	li	a4,-1
    800028e2:	fbb8                	sd	a4,112(a5)
  }
}
    800028e4:	60e2                	ld	ra,24(sp)
    800028e6:	6442                	ld	s0,16(sp)
    800028e8:	64a2                	ld	s1,8(sp)
    800028ea:	6902                	ld	s2,0(sp)
    800028ec:	6105                	addi	sp,sp,32
    800028ee:	8082                	ret

00000000800028f0 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    800028f0:	1101                	addi	sp,sp,-32
    800028f2:	ec06                	sd	ra,24(sp)
    800028f4:	e822                	sd	s0,16(sp)
    800028f6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800028f8:	fec40593          	addi	a1,s0,-20
    800028fc:	4501                	li	a0,0
    800028fe:	f27ff0ef          	jal	80002824 <argint>
  kexit(n);
    80002902:	fec42503          	lw	a0,-20(s0)
    80002906:	f26ff0ef          	jal	8000202c <kexit>
  return 0;  // not reached
}
    8000290a:	4501                	li	a0,0
    8000290c:	60e2                	ld	ra,24(sp)
    8000290e:	6442                	ld	s0,16(sp)
    80002910:	6105                	addi	sp,sp,32
    80002912:	8082                	ret

0000000080002914 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002914:	1141                	addi	sp,sp,-16
    80002916:	e406                	sd	ra,8(sp)
    80002918:	e022                	sd	s0,0(sp)
    8000291a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000291c:	ffbfe0ef          	jal	80001916 <myproc>
}
    80002920:	5908                	lw	a0,48(a0)
    80002922:	60a2                	ld	ra,8(sp)
    80002924:	6402                	ld	s0,0(sp)
    80002926:	0141                	addi	sp,sp,16
    80002928:	8082                	ret

000000008000292a <sys_fork>:

uint64
sys_fork(void)
{
    8000292a:	1141                	addi	sp,sp,-16
    8000292c:	e406                	sd	ra,8(sp)
    8000292e:	e022                	sd	s0,0(sp)
    80002930:	0800                	addi	s0,sp,16
  return kfork();
    80002932:	b48ff0ef          	jal	80001c7a <kfork>
}
    80002936:	60a2                	ld	ra,8(sp)
    80002938:	6402                	ld	s0,0(sp)
    8000293a:	0141                	addi	sp,sp,16
    8000293c:	8082                	ret

000000008000293e <sys_wait>:

uint64
sys_wait(void)
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002946:	fe840593          	addi	a1,s0,-24
    8000294a:	4501                	li	a0,0
    8000294c:	ef5ff0ef          	jal	80002840 <argaddr>
  return kwait(p);
    80002950:	fe843503          	ld	a0,-24(s0)
    80002954:	82fff0ef          	jal	80002182 <kwait>
}
    80002958:	60e2                	ld	ra,24(sp)
    8000295a:	6442                	ld	s0,16(sp)
    8000295c:	6105                	addi	sp,sp,32
    8000295e:	8082                	ret

0000000080002960 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002960:	7179                	addi	sp,sp,-48
    80002962:	f406                	sd	ra,40(sp)
    80002964:	f022                	sd	s0,32(sp)
    80002966:	ec26                	sd	s1,24(sp)
    80002968:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    8000296a:	fd840593          	addi	a1,s0,-40
    8000296e:	4501                	li	a0,0
    80002970:	eb5ff0ef          	jal	80002824 <argint>
  argint(1, &t);
    80002974:	fdc40593          	addi	a1,s0,-36
    80002978:	4505                	li	a0,1
    8000297a:	eabff0ef          	jal	80002824 <argint>
  addr = myproc()->sz;
    8000297e:	f99fe0ef          	jal	80001916 <myproc>
    80002982:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002984:	fdc42703          	lw	a4,-36(s0)
    80002988:	4785                	li	a5,1
    8000298a:	02f70763          	beq	a4,a5,800029b8 <sys_sbrk+0x58>
    8000298e:	fd842783          	lw	a5,-40(s0)
    80002992:	0207c363          	bltz	a5,800029b8 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002996:	97a6                	add	a5,a5,s1
    80002998:	0297ee63          	bltu	a5,s1,800029d4 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    8000299c:	02000737          	lui	a4,0x2000
    800029a0:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    800029a2:	0736                	slli	a4,a4,0xd
    800029a4:	02f76a63          	bltu	a4,a5,800029d8 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    800029a8:	f6ffe0ef          	jal	80001916 <myproc>
    800029ac:	fd842703          	lw	a4,-40(s0)
    800029b0:	653c                	ld	a5,72(a0)
    800029b2:	97ba                	add	a5,a5,a4
    800029b4:	e53c                	sd	a5,72(a0)
    800029b6:	a039                	j	800029c4 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    800029b8:	fd842503          	lw	a0,-40(s0)
    800029bc:	a5cff0ef          	jal	80001c18 <growproc>
    800029c0:	00054863          	bltz	a0,800029d0 <sys_sbrk+0x70>
  }
  return addr;
}
    800029c4:	8526                	mv	a0,s1
    800029c6:	70a2                	ld	ra,40(sp)
    800029c8:	7402                	ld	s0,32(sp)
    800029ca:	64e2                	ld	s1,24(sp)
    800029cc:	6145                	addi	sp,sp,48
    800029ce:	8082                	ret
      return -1;
    800029d0:	54fd                	li	s1,-1
    800029d2:	bfcd                	j	800029c4 <sys_sbrk+0x64>
      return -1;
    800029d4:	54fd                	li	s1,-1
    800029d6:	b7fd                	j	800029c4 <sys_sbrk+0x64>
      return -1;
    800029d8:	54fd                	li	s1,-1
    800029da:	b7ed                	j	800029c4 <sys_sbrk+0x64>

00000000800029dc <sys_pause>:

uint64
sys_pause(void)
{
    800029dc:	7139                	addi	sp,sp,-64
    800029de:	fc06                	sd	ra,56(sp)
    800029e0:	f822                	sd	s0,48(sp)
    800029e2:	f04a                	sd	s2,32(sp)
    800029e4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800029e6:	fcc40593          	addi	a1,s0,-52
    800029ea:	4501                	li	a0,0
    800029ec:	e39ff0ef          	jal	80002824 <argint>
  if(n < 0)
    800029f0:	fcc42783          	lw	a5,-52(s0)
    800029f4:	0607c763          	bltz	a5,80002a62 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    800029f8:	00015517          	auipc	a0,0x15
    800029fc:	70050513          	addi	a0,a0,1792 # 800180f8 <tickslock>
    80002a00:	a16fe0ef          	jal	80000c16 <acquire>
  ticks0 = ticks;
    80002a04:	00007917          	auipc	s2,0x7
    80002a08:	7b492903          	lw	s2,1972(s2) # 8000a1b8 <ticks>
  while(ticks - ticks0 < n){
    80002a0c:	fcc42783          	lw	a5,-52(s0)
    80002a10:	cf8d                	beqz	a5,80002a4a <sys_pause+0x6e>
    80002a12:	f426                	sd	s1,40(sp)
    80002a14:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a16:	00015997          	auipc	s3,0x15
    80002a1a:	6e298993          	addi	s3,s3,1762 # 800180f8 <tickslock>
    80002a1e:	00007497          	auipc	s1,0x7
    80002a22:	79a48493          	addi	s1,s1,1946 # 8000a1b8 <ticks>
    if(killed(myproc())){
    80002a26:	ef1fe0ef          	jal	80001916 <myproc>
    80002a2a:	f2eff0ef          	jal	80002158 <killed>
    80002a2e:	ed0d                	bnez	a0,80002a68 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002a30:	85ce                	mv	a1,s3
    80002a32:	8526                	mv	a0,s1
    80002a34:	cecff0ef          	jal	80001f20 <sleep>
  while(ticks - ticks0 < n){
    80002a38:	409c                	lw	a5,0(s1)
    80002a3a:	412787bb          	subw	a5,a5,s2
    80002a3e:	fcc42703          	lw	a4,-52(s0)
    80002a42:	fee7e2e3          	bltu	a5,a4,80002a26 <sys_pause+0x4a>
    80002a46:	74a2                	ld	s1,40(sp)
    80002a48:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002a4a:	00015517          	auipc	a0,0x15
    80002a4e:	6ae50513          	addi	a0,a0,1710 # 800180f8 <tickslock>
    80002a52:	a5cfe0ef          	jal	80000cae <release>
  return 0;
    80002a56:	4501                	li	a0,0
}
    80002a58:	70e2                	ld	ra,56(sp)
    80002a5a:	7442                	ld	s0,48(sp)
    80002a5c:	7902                	ld	s2,32(sp)
    80002a5e:	6121                	addi	sp,sp,64
    80002a60:	8082                	ret
    n = 0;
    80002a62:	fc042623          	sw	zero,-52(s0)
    80002a66:	bf49                	j	800029f8 <sys_pause+0x1c>
      release(&tickslock);
    80002a68:	00015517          	auipc	a0,0x15
    80002a6c:	69050513          	addi	a0,a0,1680 # 800180f8 <tickslock>
    80002a70:	a3efe0ef          	jal	80000cae <release>
      return -1;
    80002a74:	557d                	li	a0,-1
    80002a76:	74a2                	ld	s1,40(sp)
    80002a78:	69e2                	ld	s3,24(sp)
    80002a7a:	bff9                	j	80002a58 <sys_pause+0x7c>

0000000080002a7c <sys_kill>:

uint64
sys_kill(void)
{
    80002a7c:	1101                	addi	sp,sp,-32
    80002a7e:	ec06                	sd	ra,24(sp)
    80002a80:	e822                	sd	s0,16(sp)
    80002a82:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002a84:	fec40593          	addi	a1,s0,-20
    80002a88:	4501                	li	a0,0
    80002a8a:	d9bff0ef          	jal	80002824 <argint>
  return kkill(pid);
    80002a8e:	fec42503          	lw	a0,-20(s0)
    80002a92:	e3cff0ef          	jal	800020ce <kkill>
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret

0000000080002a9e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002aa8:	00015517          	auipc	a0,0x15
    80002aac:	65050513          	addi	a0,a0,1616 # 800180f8 <tickslock>
    80002ab0:	966fe0ef          	jal	80000c16 <acquire>
  xticks = ticks;
    80002ab4:	00007497          	auipc	s1,0x7
    80002ab8:	7044a483          	lw	s1,1796(s1) # 8000a1b8 <ticks>
  release(&tickslock);
    80002abc:	00015517          	auipc	a0,0x15
    80002ac0:	63c50513          	addi	a0,a0,1596 # 800180f8 <tickslock>
    80002ac4:	9eafe0ef          	jal	80000cae <release>
  return xticks;
}
    80002ac8:	02049513          	slli	a0,s1,0x20
    80002acc:	9101                	srli	a0,a0,0x20
    80002ace:	60e2                	ld	ra,24(sp)
    80002ad0:	6442                	ld	s0,16(sp)
    80002ad2:	64a2                	ld	s1,8(sp)
    80002ad4:	6105                	addi	sp,sp,32
    80002ad6:	8082                	ret

0000000080002ad8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ad8:	7179                	addi	sp,sp,-48
    80002ada:	f406                	sd	ra,40(sp)
    80002adc:	f022                	sd	s0,32(sp)
    80002ade:	ec26                	sd	s1,24(sp)
    80002ae0:	e84a                	sd	s2,16(sp)
    80002ae2:	e44e                	sd	s3,8(sp)
    80002ae4:	e052                	sd	s4,0(sp)
    80002ae6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ae8:	00005597          	auipc	a1,0x5
    80002aec:	8a858593          	addi	a1,a1,-1880 # 80007390 <etext+0x390>
    80002af0:	00015517          	auipc	a0,0x15
    80002af4:	62050513          	addi	a0,a0,1568 # 80018110 <bcache>
    80002af8:	89efe0ef          	jal	80000b96 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002afc:	0001d797          	auipc	a5,0x1d
    80002b00:	61478793          	addi	a5,a5,1556 # 80020110 <bcache+0x8000>
    80002b04:	0001e717          	auipc	a4,0x1e
    80002b08:	87470713          	addi	a4,a4,-1932 # 80020378 <bcache+0x8268>
    80002b0c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002b10:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b14:	00015497          	auipc	s1,0x15
    80002b18:	61448493          	addi	s1,s1,1556 # 80018128 <bcache+0x18>
    b->next = bcache.head.next;
    80002b1c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002b1e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002b20:	00005a17          	auipc	s4,0x5
    80002b24:	878a0a13          	addi	s4,s4,-1928 # 80007398 <etext+0x398>
    b->next = bcache.head.next;
    80002b28:	2b893783          	ld	a5,696(s2)
    80002b2c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002b2e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b32:	85d2                	mv	a1,s4
    80002b34:	01048513          	addi	a0,s1,16
    80002b38:	322010ef          	jal	80003e5a <initsleeplock>
    bcache.head.next->prev = b;
    80002b3c:	2b893783          	ld	a5,696(s2)
    80002b40:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b42:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b46:	45848493          	addi	s1,s1,1112
    80002b4a:	fd349fe3          	bne	s1,s3,80002b28 <binit+0x50>
  }
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	69a2                	ld	s3,8(sp)
    80002b58:	6a02                	ld	s4,0(sp)
    80002b5a:	6145                	addi	sp,sp,48
    80002b5c:	8082                	ret

0000000080002b5e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002b5e:	7179                	addi	sp,sp,-48
    80002b60:	f406                	sd	ra,40(sp)
    80002b62:	f022                	sd	s0,32(sp)
    80002b64:	ec26                	sd	s1,24(sp)
    80002b66:	e84a                	sd	s2,16(sp)
    80002b68:	e44e                	sd	s3,8(sp)
    80002b6a:	1800                	addi	s0,sp,48
    80002b6c:	892a                	mv	s2,a0
    80002b6e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002b70:	00015517          	auipc	a0,0x15
    80002b74:	5a050513          	addi	a0,a0,1440 # 80018110 <bcache>
    80002b78:	89efe0ef          	jal	80000c16 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002b7c:	0001e497          	auipc	s1,0x1e
    80002b80:	84c4b483          	ld	s1,-1972(s1) # 800203c8 <bcache+0x82b8>
    80002b84:	0001d797          	auipc	a5,0x1d
    80002b88:	7f478793          	addi	a5,a5,2036 # 80020378 <bcache+0x8268>
    80002b8c:	02f48b63          	beq	s1,a5,80002bc2 <bread+0x64>
    80002b90:	873e                	mv	a4,a5
    80002b92:	a021                	j	80002b9a <bread+0x3c>
    80002b94:	68a4                	ld	s1,80(s1)
    80002b96:	02e48663          	beq	s1,a4,80002bc2 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002b9a:	449c                	lw	a5,8(s1)
    80002b9c:	ff279ce3          	bne	a5,s2,80002b94 <bread+0x36>
    80002ba0:	44dc                	lw	a5,12(s1)
    80002ba2:	ff3799e3          	bne	a5,s3,80002b94 <bread+0x36>
      b->refcnt++;
    80002ba6:	40bc                	lw	a5,64(s1)
    80002ba8:	2785                	addiw	a5,a5,1
    80002baa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bac:	00015517          	auipc	a0,0x15
    80002bb0:	56450513          	addi	a0,a0,1380 # 80018110 <bcache>
    80002bb4:	8fafe0ef          	jal	80000cae <release>
      acquiresleep(&b->lock);
    80002bb8:	01048513          	addi	a0,s1,16
    80002bbc:	2d4010ef          	jal	80003e90 <acquiresleep>
      return b;
    80002bc0:	a889                	j	80002c12 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bc2:	0001d497          	auipc	s1,0x1d
    80002bc6:	7fe4b483          	ld	s1,2046(s1) # 800203c0 <bcache+0x82b0>
    80002bca:	0001d797          	auipc	a5,0x1d
    80002bce:	7ae78793          	addi	a5,a5,1966 # 80020378 <bcache+0x8268>
    80002bd2:	00f48863          	beq	s1,a5,80002be2 <bread+0x84>
    80002bd6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002bd8:	40bc                	lw	a5,64(s1)
    80002bda:	cb91                	beqz	a5,80002bee <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bdc:	64a4                	ld	s1,72(s1)
    80002bde:	fee49de3          	bne	s1,a4,80002bd8 <bread+0x7a>
  panic("bget: no buffers");
    80002be2:	00004517          	auipc	a0,0x4
    80002be6:	7be50513          	addi	a0,a0,1982 # 800073a0 <etext+0x3a0>
    80002bea:	bf7fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002bee:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002bf2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002bf6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002bfa:	4785                	li	a5,1
    80002bfc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bfe:	00015517          	auipc	a0,0x15
    80002c02:	51250513          	addi	a0,a0,1298 # 80018110 <bcache>
    80002c06:	8a8fe0ef          	jal	80000cae <release>
      acquiresleep(&b->lock);
    80002c0a:	01048513          	addi	a0,s1,16
    80002c0e:	282010ef          	jal	80003e90 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002c12:	409c                	lw	a5,0(s1)
    80002c14:	cb89                	beqz	a5,80002c26 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002c16:	8526                	mv	a0,s1
    80002c18:	70a2                	ld	ra,40(sp)
    80002c1a:	7402                	ld	s0,32(sp)
    80002c1c:	64e2                	ld	s1,24(sp)
    80002c1e:	6942                	ld	s2,16(sp)
    80002c20:	69a2                	ld	s3,8(sp)
    80002c22:	6145                	addi	sp,sp,48
    80002c24:	8082                	ret
    virtio_disk_rw(b, 0);
    80002c26:	4581                	li	a1,0
    80002c28:	8526                	mv	a0,s1
    80002c2a:	2d7020ef          	jal	80005700 <virtio_disk_rw>
    b->valid = 1;
    80002c2e:	4785                	li	a5,1
    80002c30:	c09c                	sw	a5,0(s1)
  return b;
    80002c32:	b7d5                	j	80002c16 <bread+0xb8>

0000000080002c34 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c34:	1101                	addi	sp,sp,-32
    80002c36:	ec06                	sd	ra,24(sp)
    80002c38:	e822                	sd	s0,16(sp)
    80002c3a:	e426                	sd	s1,8(sp)
    80002c3c:	1000                	addi	s0,sp,32
    80002c3e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c40:	0541                	addi	a0,a0,16
    80002c42:	2cc010ef          	jal	80003f0e <holdingsleep>
    80002c46:	c911                	beqz	a0,80002c5a <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002c48:	4585                	li	a1,1
    80002c4a:	8526                	mv	a0,s1
    80002c4c:	2b5020ef          	jal	80005700 <virtio_disk_rw>
}
    80002c50:	60e2                	ld	ra,24(sp)
    80002c52:	6442                	ld	s0,16(sp)
    80002c54:	64a2                	ld	s1,8(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret
    panic("bwrite");
    80002c5a:	00004517          	auipc	a0,0x4
    80002c5e:	75e50513          	addi	a0,a0,1886 # 800073b8 <etext+0x3b8>
    80002c62:	b7ffd0ef          	jal	800007e0 <panic>

0000000080002c66 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	e426                	sd	s1,8(sp)
    80002c6e:	e04a                	sd	s2,0(sp)
    80002c70:	1000                	addi	s0,sp,32
    80002c72:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c74:	01050913          	addi	s2,a0,16
    80002c78:	854a                	mv	a0,s2
    80002c7a:	294010ef          	jal	80003f0e <holdingsleep>
    80002c7e:	c135                	beqz	a0,80002ce2 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002c80:	854a                	mv	a0,s2
    80002c82:	254010ef          	jal	80003ed6 <releasesleep>

  acquire(&bcache.lock);
    80002c86:	00015517          	auipc	a0,0x15
    80002c8a:	48a50513          	addi	a0,a0,1162 # 80018110 <bcache>
    80002c8e:	f89fd0ef          	jal	80000c16 <acquire>
  b->refcnt--;
    80002c92:	40bc                	lw	a5,64(s1)
    80002c94:	37fd                	addiw	a5,a5,-1
    80002c96:	0007871b          	sext.w	a4,a5
    80002c9a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002c9c:	e71d                	bnez	a4,80002cca <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002c9e:	68b8                	ld	a4,80(s1)
    80002ca0:	64bc                	ld	a5,72(s1)
    80002ca2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002ca4:	68b8                	ld	a4,80(s1)
    80002ca6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002ca8:	0001d797          	auipc	a5,0x1d
    80002cac:	46878793          	addi	a5,a5,1128 # 80020110 <bcache+0x8000>
    80002cb0:	2b87b703          	ld	a4,696(a5)
    80002cb4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002cb6:	0001d717          	auipc	a4,0x1d
    80002cba:	6c270713          	addi	a4,a4,1730 # 80020378 <bcache+0x8268>
    80002cbe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002cc0:	2b87b703          	ld	a4,696(a5)
    80002cc4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002cc6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002cca:	00015517          	auipc	a0,0x15
    80002cce:	44650513          	addi	a0,a0,1094 # 80018110 <bcache>
    80002cd2:	fddfd0ef          	jal	80000cae <release>
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6902                	ld	s2,0(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret
    panic("brelse");
    80002ce2:	00004517          	auipc	a0,0x4
    80002ce6:	6de50513          	addi	a0,a0,1758 # 800073c0 <etext+0x3c0>
    80002cea:	af7fd0ef          	jal	800007e0 <panic>

0000000080002cee <bpin>:

void
bpin(struct buf *b) {
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
    80002cf8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002cfa:	00015517          	auipc	a0,0x15
    80002cfe:	41650513          	addi	a0,a0,1046 # 80018110 <bcache>
    80002d02:	f15fd0ef          	jal	80000c16 <acquire>
  b->refcnt++;
    80002d06:	40bc                	lw	a5,64(s1)
    80002d08:	2785                	addiw	a5,a5,1
    80002d0a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d0c:	00015517          	auipc	a0,0x15
    80002d10:	40450513          	addi	a0,a0,1028 # 80018110 <bcache>
    80002d14:	f9bfd0ef          	jal	80000cae <release>
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <bunpin>:

void
bunpin(struct buf *b) {
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	1000                	addi	s0,sp,32
    80002d2c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d2e:	00015517          	auipc	a0,0x15
    80002d32:	3e250513          	addi	a0,a0,994 # 80018110 <bcache>
    80002d36:	ee1fd0ef          	jal	80000c16 <acquire>
  b->refcnt--;
    80002d3a:	40bc                	lw	a5,64(s1)
    80002d3c:	37fd                	addiw	a5,a5,-1
    80002d3e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d40:	00015517          	auipc	a0,0x15
    80002d44:	3d050513          	addi	a0,a0,976 # 80018110 <bcache>
    80002d48:	f67fd0ef          	jal	80000cae <release>
}
    80002d4c:	60e2                	ld	ra,24(sp)
    80002d4e:	6442                	ld	s0,16(sp)
    80002d50:	64a2                	ld	s1,8(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret

0000000080002d56 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	e04a                	sd	s2,0(sp)
    80002d60:	1000                	addi	s0,sp,32
    80002d62:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d64:	00d5d59b          	srliw	a1,a1,0xd
    80002d68:	0001e797          	auipc	a5,0x1e
    80002d6c:	a847a783          	lw	a5,-1404(a5) # 800207ec <sb+0x1c>
    80002d70:	9dbd                	addw	a1,a1,a5
    80002d72:	dedff0ef          	jal	80002b5e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002d76:	0074f713          	andi	a4,s1,7
    80002d7a:	4785                	li	a5,1
    80002d7c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002d80:	14ce                	slli	s1,s1,0x33
    80002d82:	90d9                	srli	s1,s1,0x36
    80002d84:	00950733          	add	a4,a0,s1
    80002d88:	05874703          	lbu	a4,88(a4)
    80002d8c:	00e7f6b3          	and	a3,a5,a4
    80002d90:	c29d                	beqz	a3,80002db6 <bfree+0x60>
    80002d92:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002d94:	94aa                	add	s1,s1,a0
    80002d96:	fff7c793          	not	a5,a5
    80002d9a:	8f7d                	and	a4,a4,a5
    80002d9c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002da0:	7f9000ef          	jal	80003d98 <log_write>
  brelse(bp);
    80002da4:	854a                	mv	a0,s2
    80002da6:	ec1ff0ef          	jal	80002c66 <brelse>
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	64a2                	ld	s1,8(sp)
    80002db0:	6902                	ld	s2,0(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret
    panic("freeing free block");
    80002db6:	00004517          	auipc	a0,0x4
    80002dba:	61250513          	addi	a0,a0,1554 # 800073c8 <etext+0x3c8>
    80002dbe:	a23fd0ef          	jal	800007e0 <panic>

0000000080002dc2 <balloc>:
{
    80002dc2:	711d                	addi	sp,sp,-96
    80002dc4:	ec86                	sd	ra,88(sp)
    80002dc6:	e8a2                	sd	s0,80(sp)
    80002dc8:	e4a6                	sd	s1,72(sp)
    80002dca:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002dcc:	0001e797          	auipc	a5,0x1e
    80002dd0:	a087a783          	lw	a5,-1528(a5) # 800207d4 <sb+0x4>
    80002dd4:	0e078f63          	beqz	a5,80002ed2 <balloc+0x110>
    80002dd8:	e0ca                	sd	s2,64(sp)
    80002dda:	fc4e                	sd	s3,56(sp)
    80002ddc:	f852                	sd	s4,48(sp)
    80002dde:	f456                	sd	s5,40(sp)
    80002de0:	f05a                	sd	s6,32(sp)
    80002de2:	ec5e                	sd	s7,24(sp)
    80002de4:	e862                	sd	s8,16(sp)
    80002de6:	e466                	sd	s9,8(sp)
    80002de8:	8baa                	mv	s7,a0
    80002dea:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002dec:	0001eb17          	auipc	s6,0x1e
    80002df0:	9e4b0b13          	addi	s6,s6,-1564 # 800207d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002df4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002df6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002df8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002dfa:	6c89                	lui	s9,0x2
    80002dfc:	a0b5                	j	80002e68 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002dfe:	97ca                	add	a5,a5,s2
    80002e00:	8e55                	or	a2,a2,a3
    80002e02:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002e06:	854a                	mv	a0,s2
    80002e08:	791000ef          	jal	80003d98 <log_write>
        brelse(bp);
    80002e0c:	854a                	mv	a0,s2
    80002e0e:	e59ff0ef          	jal	80002c66 <brelse>
  bp = bread(dev, bno);
    80002e12:	85a6                	mv	a1,s1
    80002e14:	855e                	mv	a0,s7
    80002e16:	d49ff0ef          	jal	80002b5e <bread>
    80002e1a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002e1c:	40000613          	li	a2,1024
    80002e20:	4581                	li	a1,0
    80002e22:	05850513          	addi	a0,a0,88
    80002e26:	ec5fd0ef          	jal	80000cea <memset>
  log_write(bp);
    80002e2a:	854a                	mv	a0,s2
    80002e2c:	76d000ef          	jal	80003d98 <log_write>
  brelse(bp);
    80002e30:	854a                	mv	a0,s2
    80002e32:	e35ff0ef          	jal	80002c66 <brelse>
}
    80002e36:	6906                	ld	s2,64(sp)
    80002e38:	79e2                	ld	s3,56(sp)
    80002e3a:	7a42                	ld	s4,48(sp)
    80002e3c:	7aa2                	ld	s5,40(sp)
    80002e3e:	7b02                	ld	s6,32(sp)
    80002e40:	6be2                	ld	s7,24(sp)
    80002e42:	6c42                	ld	s8,16(sp)
    80002e44:	6ca2                	ld	s9,8(sp)
}
    80002e46:	8526                	mv	a0,s1
    80002e48:	60e6                	ld	ra,88(sp)
    80002e4a:	6446                	ld	s0,80(sp)
    80002e4c:	64a6                	ld	s1,72(sp)
    80002e4e:	6125                	addi	sp,sp,96
    80002e50:	8082                	ret
    brelse(bp);
    80002e52:	854a                	mv	a0,s2
    80002e54:	e13ff0ef          	jal	80002c66 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e58:	015c87bb          	addw	a5,s9,s5
    80002e5c:	00078a9b          	sext.w	s5,a5
    80002e60:	004b2703          	lw	a4,4(s6)
    80002e64:	04eaff63          	bgeu	s5,a4,80002ec2 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002e68:	41fad79b          	sraiw	a5,s5,0x1f
    80002e6c:	0137d79b          	srliw	a5,a5,0x13
    80002e70:	015787bb          	addw	a5,a5,s5
    80002e74:	40d7d79b          	sraiw	a5,a5,0xd
    80002e78:	01cb2583          	lw	a1,28(s6)
    80002e7c:	9dbd                	addw	a1,a1,a5
    80002e7e:	855e                	mv	a0,s7
    80002e80:	cdfff0ef          	jal	80002b5e <bread>
    80002e84:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e86:	004b2503          	lw	a0,4(s6)
    80002e8a:	000a849b          	sext.w	s1,s5
    80002e8e:	8762                	mv	a4,s8
    80002e90:	fca4f1e3          	bgeu	s1,a0,80002e52 <balloc+0x90>
      m = 1 << (bi % 8);
    80002e94:	00777693          	andi	a3,a4,7
    80002e98:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002e9c:	41f7579b          	sraiw	a5,a4,0x1f
    80002ea0:	01d7d79b          	srliw	a5,a5,0x1d
    80002ea4:	9fb9                	addw	a5,a5,a4
    80002ea6:	4037d79b          	sraiw	a5,a5,0x3
    80002eaa:	00f90633          	add	a2,s2,a5
    80002eae:	05864603          	lbu	a2,88(a2)
    80002eb2:	00c6f5b3          	and	a1,a3,a2
    80002eb6:	d5a1                	beqz	a1,80002dfe <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002eb8:	2705                	addiw	a4,a4,1
    80002eba:	2485                	addiw	s1,s1,1
    80002ebc:	fd471ae3          	bne	a4,s4,80002e90 <balloc+0xce>
    80002ec0:	bf49                	j	80002e52 <balloc+0x90>
    80002ec2:	6906                	ld	s2,64(sp)
    80002ec4:	79e2                	ld	s3,56(sp)
    80002ec6:	7a42                	ld	s4,48(sp)
    80002ec8:	7aa2                	ld	s5,40(sp)
    80002eca:	7b02                	ld	s6,32(sp)
    80002ecc:	6be2                	ld	s7,24(sp)
    80002ece:	6c42                	ld	s8,16(sp)
    80002ed0:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002ed2:	00004517          	auipc	a0,0x4
    80002ed6:	50e50513          	addi	a0,a0,1294 # 800073e0 <etext+0x3e0>
    80002eda:	e20fd0ef          	jal	800004fa <printf>
  return 0;
    80002ede:	4481                	li	s1,0
    80002ee0:	b79d                	j	80002e46 <balloc+0x84>

0000000080002ee2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002ee2:	7179                	addi	sp,sp,-48
    80002ee4:	f406                	sd	ra,40(sp)
    80002ee6:	f022                	sd	s0,32(sp)
    80002ee8:	ec26                	sd	s1,24(sp)
    80002eea:	e84a                	sd	s2,16(sp)
    80002eec:	e44e                	sd	s3,8(sp)
    80002eee:	1800                	addi	s0,sp,48
    80002ef0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002ef2:	47ad                	li	a5,11
    80002ef4:	02b7e663          	bltu	a5,a1,80002f20 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002ef8:	02059793          	slli	a5,a1,0x20
    80002efc:	01e7d593          	srli	a1,a5,0x1e
    80002f00:	00b504b3          	add	s1,a0,a1
    80002f04:	0504a903          	lw	s2,80(s1)
    80002f08:	06091a63          	bnez	s2,80002f7c <bmap+0x9a>
      addr = balloc(ip->dev);
    80002f0c:	4108                	lw	a0,0(a0)
    80002f0e:	eb5ff0ef          	jal	80002dc2 <balloc>
    80002f12:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f16:	06090363          	beqz	s2,80002f7c <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80002f1a:	0524a823          	sw	s2,80(s1)
    80002f1e:	a8b9                	j	80002f7c <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002f20:	ff45849b          	addiw	s1,a1,-12
    80002f24:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002f28:	0ff00793          	li	a5,255
    80002f2c:	06e7ee63          	bltu	a5,a4,80002fa8 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002f30:	08052903          	lw	s2,128(a0)
    80002f34:	00091d63          	bnez	s2,80002f4e <bmap+0x6c>
      addr = balloc(ip->dev);
    80002f38:	4108                	lw	a0,0(a0)
    80002f3a:	e89ff0ef          	jal	80002dc2 <balloc>
    80002f3e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f42:	02090d63          	beqz	s2,80002f7c <bmap+0x9a>
    80002f46:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002f48:	0929a023          	sw	s2,128(s3)
    80002f4c:	a011                	j	80002f50 <bmap+0x6e>
    80002f4e:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80002f50:	85ca                	mv	a1,s2
    80002f52:	0009a503          	lw	a0,0(s3)
    80002f56:	c09ff0ef          	jal	80002b5e <bread>
    80002f5a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f5c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f60:	02049713          	slli	a4,s1,0x20
    80002f64:	01e75593          	srli	a1,a4,0x1e
    80002f68:	00b784b3          	add	s1,a5,a1
    80002f6c:	0004a903          	lw	s2,0(s1)
    80002f70:	00090e63          	beqz	s2,80002f8c <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002f74:	8552                	mv	a0,s4
    80002f76:	cf1ff0ef          	jal	80002c66 <brelse>
    return addr;
    80002f7a:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80002f7c:	854a                	mv	a0,s2
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6942                	ld	s2,16(sp)
    80002f86:	69a2                	ld	s3,8(sp)
    80002f88:	6145                	addi	sp,sp,48
    80002f8a:	8082                	ret
      addr = balloc(ip->dev);
    80002f8c:	0009a503          	lw	a0,0(s3)
    80002f90:	e33ff0ef          	jal	80002dc2 <balloc>
    80002f94:	0005091b          	sext.w	s2,a0
      if(addr){
    80002f98:	fc090ee3          	beqz	s2,80002f74 <bmap+0x92>
        a[bn] = addr;
    80002f9c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002fa0:	8552                	mv	a0,s4
    80002fa2:	5f7000ef          	jal	80003d98 <log_write>
    80002fa6:	b7f9                	j	80002f74 <bmap+0x92>
    80002fa8:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80002faa:	00004517          	auipc	a0,0x4
    80002fae:	44e50513          	addi	a0,a0,1102 # 800073f8 <etext+0x3f8>
    80002fb2:	82ffd0ef          	jal	800007e0 <panic>

0000000080002fb6 <iget>:
{
    80002fb6:	7179                	addi	sp,sp,-48
    80002fb8:	f406                	sd	ra,40(sp)
    80002fba:	f022                	sd	s0,32(sp)
    80002fbc:	ec26                	sd	s1,24(sp)
    80002fbe:	e84a                	sd	s2,16(sp)
    80002fc0:	e44e                	sd	s3,8(sp)
    80002fc2:	e052                	sd	s4,0(sp)
    80002fc4:	1800                	addi	s0,sp,48
    80002fc6:	89aa                	mv	s3,a0
    80002fc8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002fca:	0001e517          	auipc	a0,0x1e
    80002fce:	82650513          	addi	a0,a0,-2010 # 800207f0 <itable>
    80002fd2:	c45fd0ef          	jal	80000c16 <acquire>
  empty = 0;
    80002fd6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002fd8:	0001e497          	auipc	s1,0x1e
    80002fdc:	83048493          	addi	s1,s1,-2000 # 80020808 <itable+0x18>
    80002fe0:	0001f697          	auipc	a3,0x1f
    80002fe4:	2b868693          	addi	a3,a3,696 # 80022298 <log>
    80002fe8:	a039                	j	80002ff6 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002fea:	02090963          	beqz	s2,8000301c <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002fee:	08848493          	addi	s1,s1,136
    80002ff2:	02d48863          	beq	s1,a3,80003022 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002ff6:	449c                	lw	a5,8(s1)
    80002ff8:	fef059e3          	blez	a5,80002fea <iget+0x34>
    80002ffc:	4098                	lw	a4,0(s1)
    80002ffe:	ff3716e3          	bne	a4,s3,80002fea <iget+0x34>
    80003002:	40d8                	lw	a4,4(s1)
    80003004:	ff4713e3          	bne	a4,s4,80002fea <iget+0x34>
      ip->ref++;
    80003008:	2785                	addiw	a5,a5,1
    8000300a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000300c:	0001d517          	auipc	a0,0x1d
    80003010:	7e450513          	addi	a0,a0,2020 # 800207f0 <itable>
    80003014:	c9bfd0ef          	jal	80000cae <release>
      return ip;
    80003018:	8926                	mv	s2,s1
    8000301a:	a02d                	j	80003044 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000301c:	fbe9                	bnez	a5,80002fee <iget+0x38>
      empty = ip;
    8000301e:	8926                	mv	s2,s1
    80003020:	b7f9                	j	80002fee <iget+0x38>
  if(empty == 0)
    80003022:	02090a63          	beqz	s2,80003056 <iget+0xa0>
  ip->dev = dev;
    80003026:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000302a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000302e:	4785                	li	a5,1
    80003030:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003034:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003038:	0001d517          	auipc	a0,0x1d
    8000303c:	7b850513          	addi	a0,a0,1976 # 800207f0 <itable>
    80003040:	c6ffd0ef          	jal	80000cae <release>
}
    80003044:	854a                	mv	a0,s2
    80003046:	70a2                	ld	ra,40(sp)
    80003048:	7402                	ld	s0,32(sp)
    8000304a:	64e2                	ld	s1,24(sp)
    8000304c:	6942                	ld	s2,16(sp)
    8000304e:	69a2                	ld	s3,8(sp)
    80003050:	6a02                	ld	s4,0(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret
    panic("iget: no inodes");
    80003056:	00004517          	auipc	a0,0x4
    8000305a:	3ba50513          	addi	a0,a0,954 # 80007410 <etext+0x410>
    8000305e:	f82fd0ef          	jal	800007e0 <panic>

0000000080003062 <iinit>:
{
    80003062:	7179                	addi	sp,sp,-48
    80003064:	f406                	sd	ra,40(sp)
    80003066:	f022                	sd	s0,32(sp)
    80003068:	ec26                	sd	s1,24(sp)
    8000306a:	e84a                	sd	s2,16(sp)
    8000306c:	e44e                	sd	s3,8(sp)
    8000306e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003070:	00004597          	auipc	a1,0x4
    80003074:	3b058593          	addi	a1,a1,944 # 80007420 <etext+0x420>
    80003078:	0001d517          	auipc	a0,0x1d
    8000307c:	77850513          	addi	a0,a0,1912 # 800207f0 <itable>
    80003080:	b17fd0ef          	jal	80000b96 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003084:	0001d497          	auipc	s1,0x1d
    80003088:	79448493          	addi	s1,s1,1940 # 80020818 <itable+0x28>
    8000308c:	0001f997          	auipc	s3,0x1f
    80003090:	21c98993          	addi	s3,s3,540 # 800222a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003094:	00004917          	auipc	s2,0x4
    80003098:	39490913          	addi	s2,s2,916 # 80007428 <etext+0x428>
    8000309c:	85ca                	mv	a1,s2
    8000309e:	8526                	mv	a0,s1
    800030a0:	5bb000ef          	jal	80003e5a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800030a4:	08848493          	addi	s1,s1,136
    800030a8:	ff349ae3          	bne	s1,s3,8000309c <iinit+0x3a>
}
    800030ac:	70a2                	ld	ra,40(sp)
    800030ae:	7402                	ld	s0,32(sp)
    800030b0:	64e2                	ld	s1,24(sp)
    800030b2:	6942                	ld	s2,16(sp)
    800030b4:	69a2                	ld	s3,8(sp)
    800030b6:	6145                	addi	sp,sp,48
    800030b8:	8082                	ret

00000000800030ba <ialloc>:
{
    800030ba:	7139                	addi	sp,sp,-64
    800030bc:	fc06                	sd	ra,56(sp)
    800030be:	f822                	sd	s0,48(sp)
    800030c0:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800030c2:	0001d717          	auipc	a4,0x1d
    800030c6:	71a72703          	lw	a4,1818(a4) # 800207dc <sb+0xc>
    800030ca:	4785                	li	a5,1
    800030cc:	06e7f063          	bgeu	a5,a4,8000312c <ialloc+0x72>
    800030d0:	f426                	sd	s1,40(sp)
    800030d2:	f04a                	sd	s2,32(sp)
    800030d4:	ec4e                	sd	s3,24(sp)
    800030d6:	e852                	sd	s4,16(sp)
    800030d8:	e456                	sd	s5,8(sp)
    800030da:	e05a                	sd	s6,0(sp)
    800030dc:	8aaa                	mv	s5,a0
    800030de:	8b2e                	mv	s6,a1
    800030e0:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800030e2:	0001da17          	auipc	s4,0x1d
    800030e6:	6eea0a13          	addi	s4,s4,1774 # 800207d0 <sb>
    800030ea:	00495593          	srli	a1,s2,0x4
    800030ee:	018a2783          	lw	a5,24(s4)
    800030f2:	9dbd                	addw	a1,a1,a5
    800030f4:	8556                	mv	a0,s5
    800030f6:	a69ff0ef          	jal	80002b5e <bread>
    800030fa:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800030fc:	05850993          	addi	s3,a0,88
    80003100:	00f97793          	andi	a5,s2,15
    80003104:	079a                	slli	a5,a5,0x6
    80003106:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003108:	00099783          	lh	a5,0(s3)
    8000310c:	cb9d                	beqz	a5,80003142 <ialloc+0x88>
    brelse(bp);
    8000310e:	b59ff0ef          	jal	80002c66 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003112:	0905                	addi	s2,s2,1
    80003114:	00ca2703          	lw	a4,12(s4)
    80003118:	0009079b          	sext.w	a5,s2
    8000311c:	fce7e7e3          	bltu	a5,a4,800030ea <ialloc+0x30>
    80003120:	74a2                	ld	s1,40(sp)
    80003122:	7902                	ld	s2,32(sp)
    80003124:	69e2                	ld	s3,24(sp)
    80003126:	6a42                	ld	s4,16(sp)
    80003128:	6aa2                	ld	s5,8(sp)
    8000312a:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000312c:	00004517          	auipc	a0,0x4
    80003130:	30450513          	addi	a0,a0,772 # 80007430 <etext+0x430>
    80003134:	bc6fd0ef          	jal	800004fa <printf>
  return 0;
    80003138:	4501                	li	a0,0
}
    8000313a:	70e2                	ld	ra,56(sp)
    8000313c:	7442                	ld	s0,48(sp)
    8000313e:	6121                	addi	sp,sp,64
    80003140:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003142:	04000613          	li	a2,64
    80003146:	4581                	li	a1,0
    80003148:	854e                	mv	a0,s3
    8000314a:	ba1fd0ef          	jal	80000cea <memset>
      dip->type = type;
    8000314e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003152:	8526                	mv	a0,s1
    80003154:	445000ef          	jal	80003d98 <log_write>
      brelse(bp);
    80003158:	8526                	mv	a0,s1
    8000315a:	b0dff0ef          	jal	80002c66 <brelse>
      return iget(dev, inum);
    8000315e:	0009059b          	sext.w	a1,s2
    80003162:	8556                	mv	a0,s5
    80003164:	e53ff0ef          	jal	80002fb6 <iget>
    80003168:	74a2                	ld	s1,40(sp)
    8000316a:	7902                	ld	s2,32(sp)
    8000316c:	69e2                	ld	s3,24(sp)
    8000316e:	6a42                	ld	s4,16(sp)
    80003170:	6aa2                	ld	s5,8(sp)
    80003172:	6b02                	ld	s6,0(sp)
    80003174:	b7d9                	j	8000313a <ialloc+0x80>

0000000080003176 <iupdate>:
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	e04a                	sd	s2,0(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003184:	415c                	lw	a5,4(a0)
    80003186:	0047d79b          	srliw	a5,a5,0x4
    8000318a:	0001d597          	auipc	a1,0x1d
    8000318e:	65e5a583          	lw	a1,1630(a1) # 800207e8 <sb+0x18>
    80003192:	9dbd                	addw	a1,a1,a5
    80003194:	4108                	lw	a0,0(a0)
    80003196:	9c9ff0ef          	jal	80002b5e <bread>
    8000319a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000319c:	05850793          	addi	a5,a0,88
    800031a0:	40d8                	lw	a4,4(s1)
    800031a2:	8b3d                	andi	a4,a4,15
    800031a4:	071a                	slli	a4,a4,0x6
    800031a6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800031a8:	04449703          	lh	a4,68(s1)
    800031ac:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800031b0:	04649703          	lh	a4,70(s1)
    800031b4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800031b8:	04849703          	lh	a4,72(s1)
    800031bc:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800031c0:	04a49703          	lh	a4,74(s1)
    800031c4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800031c8:	44f8                	lw	a4,76(s1)
    800031ca:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800031cc:	03400613          	li	a2,52
    800031d0:	05048593          	addi	a1,s1,80
    800031d4:	00c78513          	addi	a0,a5,12
    800031d8:	b6ffd0ef          	jal	80000d46 <memmove>
  log_write(bp);
    800031dc:	854a                	mv	a0,s2
    800031de:	3bb000ef          	jal	80003d98 <log_write>
  brelse(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	a83ff0ef          	jal	80002c66 <brelse>
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6902                	ld	s2,0(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret

00000000800031f4 <idup>:
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	1000                	addi	s0,sp,32
    800031fe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003200:	0001d517          	auipc	a0,0x1d
    80003204:	5f050513          	addi	a0,a0,1520 # 800207f0 <itable>
    80003208:	a0ffd0ef          	jal	80000c16 <acquire>
  ip->ref++;
    8000320c:	449c                	lw	a5,8(s1)
    8000320e:	2785                	addiw	a5,a5,1
    80003210:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003212:	0001d517          	auipc	a0,0x1d
    80003216:	5de50513          	addi	a0,a0,1502 # 800207f0 <itable>
    8000321a:	a95fd0ef          	jal	80000cae <release>
}
    8000321e:	8526                	mv	a0,s1
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret

000000008000322a <ilock>:
{
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	e426                	sd	s1,8(sp)
    80003232:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003234:	cd19                	beqz	a0,80003252 <ilock+0x28>
    80003236:	84aa                	mv	s1,a0
    80003238:	451c                	lw	a5,8(a0)
    8000323a:	00f05c63          	blez	a5,80003252 <ilock+0x28>
  acquiresleep(&ip->lock);
    8000323e:	0541                	addi	a0,a0,16
    80003240:	451000ef          	jal	80003e90 <acquiresleep>
  if(ip->valid == 0){
    80003244:	40bc                	lw	a5,64(s1)
    80003246:	cf89                	beqz	a5,80003260 <ilock+0x36>
}
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	64a2                	ld	s1,8(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret
    80003252:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003254:	00004517          	auipc	a0,0x4
    80003258:	1f450513          	addi	a0,a0,500 # 80007448 <etext+0x448>
    8000325c:	d84fd0ef          	jal	800007e0 <panic>
    80003260:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003262:	40dc                	lw	a5,4(s1)
    80003264:	0047d79b          	srliw	a5,a5,0x4
    80003268:	0001d597          	auipc	a1,0x1d
    8000326c:	5805a583          	lw	a1,1408(a1) # 800207e8 <sb+0x18>
    80003270:	9dbd                	addw	a1,a1,a5
    80003272:	4088                	lw	a0,0(s1)
    80003274:	8ebff0ef          	jal	80002b5e <bread>
    80003278:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000327a:	05850593          	addi	a1,a0,88
    8000327e:	40dc                	lw	a5,4(s1)
    80003280:	8bbd                	andi	a5,a5,15
    80003282:	079a                	slli	a5,a5,0x6
    80003284:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003286:	00059783          	lh	a5,0(a1)
    8000328a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000328e:	00259783          	lh	a5,2(a1)
    80003292:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003296:	00459783          	lh	a5,4(a1)
    8000329a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000329e:	00659783          	lh	a5,6(a1)
    800032a2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800032a6:	459c                	lw	a5,8(a1)
    800032a8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800032aa:	03400613          	li	a2,52
    800032ae:	05b1                	addi	a1,a1,12
    800032b0:	05048513          	addi	a0,s1,80
    800032b4:	a93fd0ef          	jal	80000d46 <memmove>
    brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	9adff0ef          	jal	80002c66 <brelse>
    ip->valid = 1;
    800032be:	4785                	li	a5,1
    800032c0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800032c2:	04449783          	lh	a5,68(s1)
    800032c6:	c399                	beqz	a5,800032cc <ilock+0xa2>
    800032c8:	6902                	ld	s2,0(sp)
    800032ca:	bfbd                	j	80003248 <ilock+0x1e>
      panic("ilock: no type");
    800032cc:	00004517          	auipc	a0,0x4
    800032d0:	18450513          	addi	a0,a0,388 # 80007450 <etext+0x450>
    800032d4:	d0cfd0ef          	jal	800007e0 <panic>

00000000800032d8 <iunlock>:
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	e04a                	sd	s2,0(sp)
    800032e2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800032e4:	c505                	beqz	a0,8000330c <iunlock+0x34>
    800032e6:	84aa                	mv	s1,a0
    800032e8:	01050913          	addi	s2,a0,16
    800032ec:	854a                	mv	a0,s2
    800032ee:	421000ef          	jal	80003f0e <holdingsleep>
    800032f2:	cd09                	beqz	a0,8000330c <iunlock+0x34>
    800032f4:	449c                	lw	a5,8(s1)
    800032f6:	00f05b63          	blez	a5,8000330c <iunlock+0x34>
  releasesleep(&ip->lock);
    800032fa:	854a                	mv	a0,s2
    800032fc:	3db000ef          	jal	80003ed6 <releasesleep>
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret
    panic("iunlock");
    8000330c:	00004517          	auipc	a0,0x4
    80003310:	15450513          	addi	a0,a0,340 # 80007460 <etext+0x460>
    80003314:	cccfd0ef          	jal	800007e0 <panic>

0000000080003318 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003318:	7179                	addi	sp,sp,-48
    8000331a:	f406                	sd	ra,40(sp)
    8000331c:	f022                	sd	s0,32(sp)
    8000331e:	ec26                	sd	s1,24(sp)
    80003320:	e84a                	sd	s2,16(sp)
    80003322:	e44e                	sd	s3,8(sp)
    80003324:	1800                	addi	s0,sp,48
    80003326:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003328:	05050493          	addi	s1,a0,80
    8000332c:	08050913          	addi	s2,a0,128
    80003330:	a021                	j	80003338 <itrunc+0x20>
    80003332:	0491                	addi	s1,s1,4
    80003334:	01248b63          	beq	s1,s2,8000334a <itrunc+0x32>
    if(ip->addrs[i]){
    80003338:	408c                	lw	a1,0(s1)
    8000333a:	dde5                	beqz	a1,80003332 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000333c:	0009a503          	lw	a0,0(s3)
    80003340:	a17ff0ef          	jal	80002d56 <bfree>
      ip->addrs[i] = 0;
    80003344:	0004a023          	sw	zero,0(s1)
    80003348:	b7ed                	j	80003332 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000334a:	0809a583          	lw	a1,128(s3)
    8000334e:	ed89                	bnez	a1,80003368 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003350:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003354:	854e                	mv	a0,s3
    80003356:	e21ff0ef          	jal	80003176 <iupdate>
}
    8000335a:	70a2                	ld	ra,40(sp)
    8000335c:	7402                	ld	s0,32(sp)
    8000335e:	64e2                	ld	s1,24(sp)
    80003360:	6942                	ld	s2,16(sp)
    80003362:	69a2                	ld	s3,8(sp)
    80003364:	6145                	addi	sp,sp,48
    80003366:	8082                	ret
    80003368:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000336a:	0009a503          	lw	a0,0(s3)
    8000336e:	ff0ff0ef          	jal	80002b5e <bread>
    80003372:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003374:	05850493          	addi	s1,a0,88
    80003378:	45850913          	addi	s2,a0,1112
    8000337c:	a021                	j	80003384 <itrunc+0x6c>
    8000337e:	0491                	addi	s1,s1,4
    80003380:	01248963          	beq	s1,s2,80003392 <itrunc+0x7a>
      if(a[j])
    80003384:	408c                	lw	a1,0(s1)
    80003386:	dde5                	beqz	a1,8000337e <itrunc+0x66>
        bfree(ip->dev, a[j]);
    80003388:	0009a503          	lw	a0,0(s3)
    8000338c:	9cbff0ef          	jal	80002d56 <bfree>
    80003390:	b7fd                	j	8000337e <itrunc+0x66>
    brelse(bp);
    80003392:	8552                	mv	a0,s4
    80003394:	8d3ff0ef          	jal	80002c66 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003398:	0809a583          	lw	a1,128(s3)
    8000339c:	0009a503          	lw	a0,0(s3)
    800033a0:	9b7ff0ef          	jal	80002d56 <bfree>
    ip->addrs[NDIRECT] = 0;
    800033a4:	0809a023          	sw	zero,128(s3)
    800033a8:	6a02                	ld	s4,0(sp)
    800033aa:	b75d                	j	80003350 <itrunc+0x38>

00000000800033ac <iput>:
{
    800033ac:	1101                	addi	sp,sp,-32
    800033ae:	ec06                	sd	ra,24(sp)
    800033b0:	e822                	sd	s0,16(sp)
    800033b2:	e426                	sd	s1,8(sp)
    800033b4:	1000                	addi	s0,sp,32
    800033b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033b8:	0001d517          	auipc	a0,0x1d
    800033bc:	43850513          	addi	a0,a0,1080 # 800207f0 <itable>
    800033c0:	857fd0ef          	jal	80000c16 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033c4:	4498                	lw	a4,8(s1)
    800033c6:	4785                	li	a5,1
    800033c8:	02f70063          	beq	a4,a5,800033e8 <iput+0x3c>
  ip->ref--;
    800033cc:	449c                	lw	a5,8(s1)
    800033ce:	37fd                	addiw	a5,a5,-1
    800033d0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033d2:	0001d517          	auipc	a0,0x1d
    800033d6:	41e50513          	addi	a0,a0,1054 # 800207f0 <itable>
    800033da:	8d5fd0ef          	jal	80000cae <release>
}
    800033de:	60e2                	ld	ra,24(sp)
    800033e0:	6442                	ld	s0,16(sp)
    800033e2:	64a2                	ld	s1,8(sp)
    800033e4:	6105                	addi	sp,sp,32
    800033e6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033e8:	40bc                	lw	a5,64(s1)
    800033ea:	d3ed                	beqz	a5,800033cc <iput+0x20>
    800033ec:	04a49783          	lh	a5,74(s1)
    800033f0:	fff1                	bnez	a5,800033cc <iput+0x20>
    800033f2:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    800033f4:	01048913          	addi	s2,s1,16
    800033f8:	854a                	mv	a0,s2
    800033fa:	297000ef          	jal	80003e90 <acquiresleep>
    release(&itable.lock);
    800033fe:	0001d517          	auipc	a0,0x1d
    80003402:	3f250513          	addi	a0,a0,1010 # 800207f0 <itable>
    80003406:	8a9fd0ef          	jal	80000cae <release>
    itrunc(ip);
    8000340a:	8526                	mv	a0,s1
    8000340c:	f0dff0ef          	jal	80003318 <itrunc>
    ip->type = 0;
    80003410:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003414:	8526                	mv	a0,s1
    80003416:	d61ff0ef          	jal	80003176 <iupdate>
    ip->valid = 0;
    8000341a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000341e:	854a                	mv	a0,s2
    80003420:	2b7000ef          	jal	80003ed6 <releasesleep>
    acquire(&itable.lock);
    80003424:	0001d517          	auipc	a0,0x1d
    80003428:	3cc50513          	addi	a0,a0,972 # 800207f0 <itable>
    8000342c:	feafd0ef          	jal	80000c16 <acquire>
    80003430:	6902                	ld	s2,0(sp)
    80003432:	bf69                	j	800033cc <iput+0x20>

0000000080003434 <iunlockput>:
{
    80003434:	1101                	addi	sp,sp,-32
    80003436:	ec06                	sd	ra,24(sp)
    80003438:	e822                	sd	s0,16(sp)
    8000343a:	e426                	sd	s1,8(sp)
    8000343c:	1000                	addi	s0,sp,32
    8000343e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003440:	e99ff0ef          	jal	800032d8 <iunlock>
  iput(ip);
    80003444:	8526                	mv	a0,s1
    80003446:	f67ff0ef          	jal	800033ac <iput>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6105                	addi	sp,sp,32
    80003452:	8082                	ret

0000000080003454 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003454:	0001d717          	auipc	a4,0x1d
    80003458:	38872703          	lw	a4,904(a4) # 800207dc <sb+0xc>
    8000345c:	4785                	li	a5,1
    8000345e:	0ae7ff63          	bgeu	a5,a4,8000351c <ireclaim+0xc8>
{
    80003462:	7139                	addi	sp,sp,-64
    80003464:	fc06                	sd	ra,56(sp)
    80003466:	f822                	sd	s0,48(sp)
    80003468:	f426                	sd	s1,40(sp)
    8000346a:	f04a                	sd	s2,32(sp)
    8000346c:	ec4e                	sd	s3,24(sp)
    8000346e:	e852                	sd	s4,16(sp)
    80003470:	e456                	sd	s5,8(sp)
    80003472:	e05a                	sd	s6,0(sp)
    80003474:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003476:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003478:	00050a1b          	sext.w	s4,a0
    8000347c:	0001da97          	auipc	s5,0x1d
    80003480:	354a8a93          	addi	s5,s5,852 # 800207d0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003484:	00004b17          	auipc	s6,0x4
    80003488:	fe4b0b13          	addi	s6,s6,-28 # 80007468 <etext+0x468>
    8000348c:	a099                	j	800034d2 <ireclaim+0x7e>
    8000348e:	85ce                	mv	a1,s3
    80003490:	855a                	mv	a0,s6
    80003492:	868fd0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    80003496:	85ce                	mv	a1,s3
    80003498:	8552                	mv	a0,s4
    8000349a:	b1dff0ef          	jal	80002fb6 <iget>
    8000349e:	89aa                	mv	s3,a0
    brelse(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	fc4ff0ef          	jal	80002c66 <brelse>
    if (ip) {
    800034a6:	00098f63          	beqz	s3,800034c4 <ireclaim+0x70>
      begin_op();
    800034aa:	76a000ef          	jal	80003c14 <begin_op>
      ilock(ip);
    800034ae:	854e                	mv	a0,s3
    800034b0:	d7bff0ef          	jal	8000322a <ilock>
      iunlock(ip);
    800034b4:	854e                	mv	a0,s3
    800034b6:	e23ff0ef          	jal	800032d8 <iunlock>
      iput(ip);
    800034ba:	854e                	mv	a0,s3
    800034bc:	ef1ff0ef          	jal	800033ac <iput>
      end_op();
    800034c0:	7be000ef          	jal	80003c7e <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034c4:	0485                	addi	s1,s1,1
    800034c6:	00caa703          	lw	a4,12(s5)
    800034ca:	0004879b          	sext.w	a5,s1
    800034ce:	02e7fd63          	bgeu	a5,a4,80003508 <ireclaim+0xb4>
    800034d2:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800034d6:	0044d593          	srli	a1,s1,0x4
    800034da:	018aa783          	lw	a5,24(s5)
    800034de:	9dbd                	addw	a1,a1,a5
    800034e0:	8552                	mv	a0,s4
    800034e2:	e7cff0ef          	jal	80002b5e <bread>
    800034e6:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    800034e8:	05850793          	addi	a5,a0,88
    800034ec:	00f9f713          	andi	a4,s3,15
    800034f0:	071a                	slli	a4,a4,0x6
    800034f2:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    800034f4:	00079703          	lh	a4,0(a5)
    800034f8:	c701                	beqz	a4,80003500 <ireclaim+0xac>
    800034fa:	00679783          	lh	a5,6(a5)
    800034fe:	dbc1                	beqz	a5,8000348e <ireclaim+0x3a>
    brelse(bp);
    80003500:	854a                	mv	a0,s2
    80003502:	f64ff0ef          	jal	80002c66 <brelse>
    if (ip) {
    80003506:	bf7d                	j	800034c4 <ireclaim+0x70>
}
    80003508:	70e2                	ld	ra,56(sp)
    8000350a:	7442                	ld	s0,48(sp)
    8000350c:	74a2                	ld	s1,40(sp)
    8000350e:	7902                	ld	s2,32(sp)
    80003510:	69e2                	ld	s3,24(sp)
    80003512:	6a42                	ld	s4,16(sp)
    80003514:	6aa2                	ld	s5,8(sp)
    80003516:	6b02                	ld	s6,0(sp)
    80003518:	6121                	addi	sp,sp,64
    8000351a:	8082                	ret
    8000351c:	8082                	ret

000000008000351e <fsinit>:
fsinit(int dev) {
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    8000352e:	4585                	li	a1,1
    80003530:	e2eff0ef          	jal	80002b5e <bread>
    80003534:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003536:	0001d997          	auipc	s3,0x1d
    8000353a:	29a98993          	addi	s3,s3,666 # 800207d0 <sb>
    8000353e:	02000613          	li	a2,32
    80003542:	05850593          	addi	a1,a0,88
    80003546:	854e                	mv	a0,s3
    80003548:	ffefd0ef          	jal	80000d46 <memmove>
  brelse(bp);
    8000354c:	854a                	mv	a0,s2
    8000354e:	f18ff0ef          	jal	80002c66 <brelse>
  if(sb.magic != FSMAGIC)
    80003552:	0009a703          	lw	a4,0(s3)
    80003556:	102037b7          	lui	a5,0x10203
    8000355a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000355e:	02f71363          	bne	a4,a5,80003584 <fsinit+0x66>
  initlog(dev, &sb);
    80003562:	0001d597          	auipc	a1,0x1d
    80003566:	26e58593          	addi	a1,a1,622 # 800207d0 <sb>
    8000356a:	8526                	mv	a0,s1
    8000356c:	62a000ef          	jal	80003b96 <initlog>
  ireclaim(dev);
    80003570:	8526                	mv	a0,s1
    80003572:	ee3ff0ef          	jal	80003454 <ireclaim>
}
    80003576:	70a2                	ld	ra,40(sp)
    80003578:	7402                	ld	s0,32(sp)
    8000357a:	64e2                	ld	s1,24(sp)
    8000357c:	6942                	ld	s2,16(sp)
    8000357e:	69a2                	ld	s3,8(sp)
    80003580:	6145                	addi	sp,sp,48
    80003582:	8082                	ret
    panic("invalid file system");
    80003584:	00004517          	auipc	a0,0x4
    80003588:	f0450513          	addi	a0,a0,-252 # 80007488 <etext+0x488>
    8000358c:	a54fd0ef          	jal	800007e0 <panic>

0000000080003590 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003590:	1141                	addi	sp,sp,-16
    80003592:	e422                	sd	s0,8(sp)
    80003594:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003596:	411c                	lw	a5,0(a0)
    80003598:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000359a:	415c                	lw	a5,4(a0)
    8000359c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000359e:	04451783          	lh	a5,68(a0)
    800035a2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800035a6:	04a51783          	lh	a5,74(a0)
    800035aa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800035ae:	04c56783          	lwu	a5,76(a0)
    800035b2:	e99c                	sd	a5,16(a1)
}
    800035b4:	6422                	ld	s0,8(sp)
    800035b6:	0141                	addi	sp,sp,16
    800035b8:	8082                	ret

00000000800035ba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035ba:	457c                	lw	a5,76(a0)
    800035bc:	0ed7eb63          	bltu	a5,a3,800036b2 <readi+0xf8>
{
    800035c0:	7159                	addi	sp,sp,-112
    800035c2:	f486                	sd	ra,104(sp)
    800035c4:	f0a2                	sd	s0,96(sp)
    800035c6:	eca6                	sd	s1,88(sp)
    800035c8:	e0d2                	sd	s4,64(sp)
    800035ca:	fc56                	sd	s5,56(sp)
    800035cc:	f85a                	sd	s6,48(sp)
    800035ce:	f45e                	sd	s7,40(sp)
    800035d0:	1880                	addi	s0,sp,112
    800035d2:	8b2a                	mv	s6,a0
    800035d4:	8bae                	mv	s7,a1
    800035d6:	8a32                	mv	s4,a2
    800035d8:	84b6                	mv	s1,a3
    800035da:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800035dc:	9f35                	addw	a4,a4,a3
    return 0;
    800035de:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800035e0:	0cd76063          	bltu	a4,a3,800036a0 <readi+0xe6>
    800035e4:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800035e6:	00e7f463          	bgeu	a5,a4,800035ee <readi+0x34>
    n = ip->size - off;
    800035ea:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800035ee:	080a8f63          	beqz	s5,8000368c <readi+0xd2>
    800035f2:	e8ca                	sd	s2,80(sp)
    800035f4:	f062                	sd	s8,32(sp)
    800035f6:	ec66                	sd	s9,24(sp)
    800035f8:	e86a                	sd	s10,16(sp)
    800035fa:	e46e                	sd	s11,8(sp)
    800035fc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800035fe:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003602:	5c7d                	li	s8,-1
    80003604:	a80d                	j	80003636 <readi+0x7c>
    80003606:	020d1d93          	slli	s11,s10,0x20
    8000360a:	020ddd93          	srli	s11,s11,0x20
    8000360e:	05890613          	addi	a2,s2,88
    80003612:	86ee                	mv	a3,s11
    80003614:	963a                	add	a2,a2,a4
    80003616:	85d2                	mv	a1,s4
    80003618:	855e                	mv	a0,s7
    8000361a:	c63fe0ef          	jal	8000227c <either_copyout>
    8000361e:	05850763          	beq	a0,s8,8000366c <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003622:	854a                	mv	a0,s2
    80003624:	e42ff0ef          	jal	80002c66 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003628:	013d09bb          	addw	s3,s10,s3
    8000362c:	009d04bb          	addw	s1,s10,s1
    80003630:	9a6e                	add	s4,s4,s11
    80003632:	0559f763          	bgeu	s3,s5,80003680 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003636:	00a4d59b          	srliw	a1,s1,0xa
    8000363a:	855a                	mv	a0,s6
    8000363c:	8a7ff0ef          	jal	80002ee2 <bmap>
    80003640:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003644:	c5b1                	beqz	a1,80003690 <readi+0xd6>
    bp = bread(ip->dev, addr);
    80003646:	000b2503          	lw	a0,0(s6)
    8000364a:	d14ff0ef          	jal	80002b5e <bread>
    8000364e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003650:	3ff4f713          	andi	a4,s1,1023
    80003654:	40ec87bb          	subw	a5,s9,a4
    80003658:	413a86bb          	subw	a3,s5,s3
    8000365c:	8d3e                	mv	s10,a5
    8000365e:	2781                	sext.w	a5,a5
    80003660:	0006861b          	sext.w	a2,a3
    80003664:	faf671e3          	bgeu	a2,a5,80003606 <readi+0x4c>
    80003668:	8d36                	mv	s10,a3
    8000366a:	bf71                	j	80003606 <readi+0x4c>
      brelse(bp);
    8000366c:	854a                	mv	a0,s2
    8000366e:	df8ff0ef          	jal	80002c66 <brelse>
      tot = -1;
    80003672:	59fd                	li	s3,-1
      break;
    80003674:	6946                	ld	s2,80(sp)
    80003676:	7c02                	ld	s8,32(sp)
    80003678:	6ce2                	ld	s9,24(sp)
    8000367a:	6d42                	ld	s10,16(sp)
    8000367c:	6da2                	ld	s11,8(sp)
    8000367e:	a831                	j	8000369a <readi+0xe0>
    80003680:	6946                	ld	s2,80(sp)
    80003682:	7c02                	ld	s8,32(sp)
    80003684:	6ce2                	ld	s9,24(sp)
    80003686:	6d42                	ld	s10,16(sp)
    80003688:	6da2                	ld	s11,8(sp)
    8000368a:	a801                	j	8000369a <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000368c:	89d6                	mv	s3,s5
    8000368e:	a031                	j	8000369a <readi+0xe0>
    80003690:	6946                	ld	s2,80(sp)
    80003692:	7c02                	ld	s8,32(sp)
    80003694:	6ce2                	ld	s9,24(sp)
    80003696:	6d42                	ld	s10,16(sp)
    80003698:	6da2                	ld	s11,8(sp)
  }
  return tot;
    8000369a:	0009851b          	sext.w	a0,s3
    8000369e:	69a6                	ld	s3,72(sp)
}
    800036a0:	70a6                	ld	ra,104(sp)
    800036a2:	7406                	ld	s0,96(sp)
    800036a4:	64e6                	ld	s1,88(sp)
    800036a6:	6a06                	ld	s4,64(sp)
    800036a8:	7ae2                	ld	s5,56(sp)
    800036aa:	7b42                	ld	s6,48(sp)
    800036ac:	7ba2                	ld	s7,40(sp)
    800036ae:	6165                	addi	sp,sp,112
    800036b0:	8082                	ret
    return 0;
    800036b2:	4501                	li	a0,0
}
    800036b4:	8082                	ret

00000000800036b6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036b6:	457c                	lw	a5,76(a0)
    800036b8:	10d7e063          	bltu	a5,a3,800037b8 <writei+0x102>
{
    800036bc:	7159                	addi	sp,sp,-112
    800036be:	f486                	sd	ra,104(sp)
    800036c0:	f0a2                	sd	s0,96(sp)
    800036c2:	e8ca                	sd	s2,80(sp)
    800036c4:	e0d2                	sd	s4,64(sp)
    800036c6:	fc56                	sd	s5,56(sp)
    800036c8:	f85a                	sd	s6,48(sp)
    800036ca:	f45e                	sd	s7,40(sp)
    800036cc:	1880                	addi	s0,sp,112
    800036ce:	8aaa                	mv	s5,a0
    800036d0:	8bae                	mv	s7,a1
    800036d2:	8a32                	mv	s4,a2
    800036d4:	8936                	mv	s2,a3
    800036d6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800036d8:	00e687bb          	addw	a5,a3,a4
    800036dc:	0ed7e063          	bltu	a5,a3,800037bc <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800036e0:	00043737          	lui	a4,0x43
    800036e4:	0cf76e63          	bltu	a4,a5,800037c0 <writei+0x10a>
    800036e8:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800036ea:	0a0b0f63          	beqz	s6,800037a8 <writei+0xf2>
    800036ee:	eca6                	sd	s1,88(sp)
    800036f0:	f062                	sd	s8,32(sp)
    800036f2:	ec66                	sd	s9,24(sp)
    800036f4:	e86a                	sd	s10,16(sp)
    800036f6:	e46e                	sd	s11,8(sp)
    800036f8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800036fa:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800036fe:	5c7d                	li	s8,-1
    80003700:	a825                	j	80003738 <writei+0x82>
    80003702:	020d1d93          	slli	s11,s10,0x20
    80003706:	020ddd93          	srli	s11,s11,0x20
    8000370a:	05848513          	addi	a0,s1,88
    8000370e:	86ee                	mv	a3,s11
    80003710:	8652                	mv	a2,s4
    80003712:	85de                	mv	a1,s7
    80003714:	953a                	add	a0,a0,a4
    80003716:	bb1fe0ef          	jal	800022c6 <either_copyin>
    8000371a:	05850a63          	beq	a0,s8,8000376e <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000371e:	8526                	mv	a0,s1
    80003720:	678000ef          	jal	80003d98 <log_write>
    brelse(bp);
    80003724:	8526                	mv	a0,s1
    80003726:	d40ff0ef          	jal	80002c66 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000372a:	013d09bb          	addw	s3,s10,s3
    8000372e:	012d093b          	addw	s2,s10,s2
    80003732:	9a6e                	add	s4,s4,s11
    80003734:	0569f063          	bgeu	s3,s6,80003774 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003738:	00a9559b          	srliw	a1,s2,0xa
    8000373c:	8556                	mv	a0,s5
    8000373e:	fa4ff0ef          	jal	80002ee2 <bmap>
    80003742:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003746:	c59d                	beqz	a1,80003774 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003748:	000aa503          	lw	a0,0(s5)
    8000374c:	c12ff0ef          	jal	80002b5e <bread>
    80003750:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003752:	3ff97713          	andi	a4,s2,1023
    80003756:	40ec87bb          	subw	a5,s9,a4
    8000375a:	413b06bb          	subw	a3,s6,s3
    8000375e:	8d3e                	mv	s10,a5
    80003760:	2781                	sext.w	a5,a5
    80003762:	0006861b          	sext.w	a2,a3
    80003766:	f8f67ee3          	bgeu	a2,a5,80003702 <writei+0x4c>
    8000376a:	8d36                	mv	s10,a3
    8000376c:	bf59                	j	80003702 <writei+0x4c>
      brelse(bp);
    8000376e:	8526                	mv	a0,s1
    80003770:	cf6ff0ef          	jal	80002c66 <brelse>
  }

  if(off > ip->size)
    80003774:	04caa783          	lw	a5,76(s5)
    80003778:	0327fa63          	bgeu	a5,s2,800037ac <writei+0xf6>
    ip->size = off;
    8000377c:	052aa623          	sw	s2,76(s5)
    80003780:	64e6                	ld	s1,88(sp)
    80003782:	7c02                	ld	s8,32(sp)
    80003784:	6ce2                	ld	s9,24(sp)
    80003786:	6d42                	ld	s10,16(sp)
    80003788:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000378a:	8556                	mv	a0,s5
    8000378c:	9ebff0ef          	jal	80003176 <iupdate>

  return tot;
    80003790:	0009851b          	sext.w	a0,s3
    80003794:	69a6                	ld	s3,72(sp)
}
    80003796:	70a6                	ld	ra,104(sp)
    80003798:	7406                	ld	s0,96(sp)
    8000379a:	6946                	ld	s2,80(sp)
    8000379c:	6a06                	ld	s4,64(sp)
    8000379e:	7ae2                	ld	s5,56(sp)
    800037a0:	7b42                	ld	s6,48(sp)
    800037a2:	7ba2                	ld	s7,40(sp)
    800037a4:	6165                	addi	sp,sp,112
    800037a6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800037a8:	89da                	mv	s3,s6
    800037aa:	b7c5                	j	8000378a <writei+0xd4>
    800037ac:	64e6                	ld	s1,88(sp)
    800037ae:	7c02                	ld	s8,32(sp)
    800037b0:	6ce2                	ld	s9,24(sp)
    800037b2:	6d42                	ld	s10,16(sp)
    800037b4:	6da2                	ld	s11,8(sp)
    800037b6:	bfd1                	j	8000378a <writei+0xd4>
    return -1;
    800037b8:	557d                	li	a0,-1
}
    800037ba:	8082                	ret
    return -1;
    800037bc:	557d                	li	a0,-1
    800037be:	bfe1                	j	80003796 <writei+0xe0>
    return -1;
    800037c0:	557d                	li	a0,-1
    800037c2:	bfd1                	j	80003796 <writei+0xe0>

00000000800037c4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800037c4:	1141                	addi	sp,sp,-16
    800037c6:	e406                	sd	ra,8(sp)
    800037c8:	e022                	sd	s0,0(sp)
    800037ca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800037cc:	4639                	li	a2,14
    800037ce:	de8fd0ef          	jal	80000db6 <strncmp>
}
    800037d2:	60a2                	ld	ra,8(sp)
    800037d4:	6402                	ld	s0,0(sp)
    800037d6:	0141                	addi	sp,sp,16
    800037d8:	8082                	ret

00000000800037da <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800037da:	7139                	addi	sp,sp,-64
    800037dc:	fc06                	sd	ra,56(sp)
    800037de:	f822                	sd	s0,48(sp)
    800037e0:	f426                	sd	s1,40(sp)
    800037e2:	f04a                	sd	s2,32(sp)
    800037e4:	ec4e                	sd	s3,24(sp)
    800037e6:	e852                	sd	s4,16(sp)
    800037e8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800037ea:	04451703          	lh	a4,68(a0)
    800037ee:	4785                	li	a5,1
    800037f0:	00f71a63          	bne	a4,a5,80003804 <dirlookup+0x2a>
    800037f4:	892a                	mv	s2,a0
    800037f6:	89ae                	mv	s3,a1
    800037f8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800037fa:	457c                	lw	a5,76(a0)
    800037fc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800037fe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003800:	e39d                	bnez	a5,80003826 <dirlookup+0x4c>
    80003802:	a095                	j	80003866 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003804:	00004517          	auipc	a0,0x4
    80003808:	c9c50513          	addi	a0,a0,-868 # 800074a0 <etext+0x4a0>
    8000380c:	fd5fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003810:	00004517          	auipc	a0,0x4
    80003814:	ca850513          	addi	a0,a0,-856 # 800074b8 <etext+0x4b8>
    80003818:	fc9fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000381c:	24c1                	addiw	s1,s1,16
    8000381e:	04c92783          	lw	a5,76(s2)
    80003822:	04f4f163          	bgeu	s1,a5,80003864 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003826:	4741                	li	a4,16
    80003828:	86a6                	mv	a3,s1
    8000382a:	fc040613          	addi	a2,s0,-64
    8000382e:	4581                	li	a1,0
    80003830:	854a                	mv	a0,s2
    80003832:	d89ff0ef          	jal	800035ba <readi>
    80003836:	47c1                	li	a5,16
    80003838:	fcf51ce3          	bne	a0,a5,80003810 <dirlookup+0x36>
    if(de.inum == 0)
    8000383c:	fc045783          	lhu	a5,-64(s0)
    80003840:	dff1                	beqz	a5,8000381c <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003842:	fc240593          	addi	a1,s0,-62
    80003846:	854e                	mv	a0,s3
    80003848:	f7dff0ef          	jal	800037c4 <namecmp>
    8000384c:	f961                	bnez	a0,8000381c <dirlookup+0x42>
      if(poff)
    8000384e:	000a0463          	beqz	s4,80003856 <dirlookup+0x7c>
        *poff = off;
    80003852:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003856:	fc045583          	lhu	a1,-64(s0)
    8000385a:	00092503          	lw	a0,0(s2)
    8000385e:	f58ff0ef          	jal	80002fb6 <iget>
    80003862:	a011                	j	80003866 <dirlookup+0x8c>
  return 0;
    80003864:	4501                	li	a0,0
}
    80003866:	70e2                	ld	ra,56(sp)
    80003868:	7442                	ld	s0,48(sp)
    8000386a:	74a2                	ld	s1,40(sp)
    8000386c:	7902                	ld	s2,32(sp)
    8000386e:	69e2                	ld	s3,24(sp)
    80003870:	6a42                	ld	s4,16(sp)
    80003872:	6121                	addi	sp,sp,64
    80003874:	8082                	ret

0000000080003876 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003876:	711d                	addi	sp,sp,-96
    80003878:	ec86                	sd	ra,88(sp)
    8000387a:	e8a2                	sd	s0,80(sp)
    8000387c:	e4a6                	sd	s1,72(sp)
    8000387e:	e0ca                	sd	s2,64(sp)
    80003880:	fc4e                	sd	s3,56(sp)
    80003882:	f852                	sd	s4,48(sp)
    80003884:	f456                	sd	s5,40(sp)
    80003886:	f05a                	sd	s6,32(sp)
    80003888:	ec5e                	sd	s7,24(sp)
    8000388a:	e862                	sd	s8,16(sp)
    8000388c:	e466                	sd	s9,8(sp)
    8000388e:	1080                	addi	s0,sp,96
    80003890:	84aa                	mv	s1,a0
    80003892:	8b2e                	mv	s6,a1
    80003894:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003896:	00054703          	lbu	a4,0(a0)
    8000389a:	02f00793          	li	a5,47
    8000389e:	00f70e63          	beq	a4,a5,800038ba <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800038a2:	874fe0ef          	jal	80001916 <myproc>
    800038a6:	15053503          	ld	a0,336(a0)
    800038aa:	94bff0ef          	jal	800031f4 <idup>
    800038ae:	8a2a                	mv	s4,a0
  while(*path == '/')
    800038b0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800038b4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800038b6:	4b85                	li	s7,1
    800038b8:	a871                	j	80003954 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    800038ba:	4585                	li	a1,1
    800038bc:	4505                	li	a0,1
    800038be:	ef8ff0ef          	jal	80002fb6 <iget>
    800038c2:	8a2a                	mv	s4,a0
    800038c4:	b7f5                	j	800038b0 <namex+0x3a>
      iunlockput(ip);
    800038c6:	8552                	mv	a0,s4
    800038c8:	b6dff0ef          	jal	80003434 <iunlockput>
      return 0;
    800038cc:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800038ce:	8552                	mv	a0,s4
    800038d0:	60e6                	ld	ra,88(sp)
    800038d2:	6446                	ld	s0,80(sp)
    800038d4:	64a6                	ld	s1,72(sp)
    800038d6:	6906                	ld	s2,64(sp)
    800038d8:	79e2                	ld	s3,56(sp)
    800038da:	7a42                	ld	s4,48(sp)
    800038dc:	7aa2                	ld	s5,40(sp)
    800038de:	7b02                	ld	s6,32(sp)
    800038e0:	6be2                	ld	s7,24(sp)
    800038e2:	6c42                	ld	s8,16(sp)
    800038e4:	6ca2                	ld	s9,8(sp)
    800038e6:	6125                	addi	sp,sp,96
    800038e8:	8082                	ret
      iunlock(ip);
    800038ea:	8552                	mv	a0,s4
    800038ec:	9edff0ef          	jal	800032d8 <iunlock>
      return ip;
    800038f0:	bff9                	j	800038ce <namex+0x58>
      iunlockput(ip);
    800038f2:	8552                	mv	a0,s4
    800038f4:	b41ff0ef          	jal	80003434 <iunlockput>
      return 0;
    800038f8:	8a4e                	mv	s4,s3
    800038fa:	bfd1                	j	800038ce <namex+0x58>
  len = path - s;
    800038fc:	40998633          	sub	a2,s3,s1
    80003900:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003904:	099c5063          	bge	s8,s9,80003984 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003908:	4639                	li	a2,14
    8000390a:	85a6                	mv	a1,s1
    8000390c:	8556                	mv	a0,s5
    8000390e:	c38fd0ef          	jal	80000d46 <memmove>
    80003912:	84ce                	mv	s1,s3
  while(*path == '/')
    80003914:	0004c783          	lbu	a5,0(s1)
    80003918:	01279763          	bne	a5,s2,80003926 <namex+0xb0>
    path++;
    8000391c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000391e:	0004c783          	lbu	a5,0(s1)
    80003922:	ff278de3          	beq	a5,s2,8000391c <namex+0xa6>
    ilock(ip);
    80003926:	8552                	mv	a0,s4
    80003928:	903ff0ef          	jal	8000322a <ilock>
    if(ip->type != T_DIR){
    8000392c:	044a1783          	lh	a5,68(s4)
    80003930:	f9779be3          	bne	a5,s7,800038c6 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003934:	000b0563          	beqz	s6,8000393e <namex+0xc8>
    80003938:	0004c783          	lbu	a5,0(s1)
    8000393c:	d7dd                	beqz	a5,800038ea <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000393e:	4601                	li	a2,0
    80003940:	85d6                	mv	a1,s5
    80003942:	8552                	mv	a0,s4
    80003944:	e97ff0ef          	jal	800037da <dirlookup>
    80003948:	89aa                	mv	s3,a0
    8000394a:	d545                	beqz	a0,800038f2 <namex+0x7c>
    iunlockput(ip);
    8000394c:	8552                	mv	a0,s4
    8000394e:	ae7ff0ef          	jal	80003434 <iunlockput>
    ip = next;
    80003952:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003954:	0004c783          	lbu	a5,0(s1)
    80003958:	01279763          	bne	a5,s2,80003966 <namex+0xf0>
    path++;
    8000395c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000395e:	0004c783          	lbu	a5,0(s1)
    80003962:	ff278de3          	beq	a5,s2,8000395c <namex+0xe6>
  if(*path == 0)
    80003966:	cb8d                	beqz	a5,80003998 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003968:	0004c783          	lbu	a5,0(s1)
    8000396c:	89a6                	mv	s3,s1
  len = path - s;
    8000396e:	4c81                	li	s9,0
    80003970:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003972:	01278963          	beq	a5,s2,80003984 <namex+0x10e>
    80003976:	d3d9                	beqz	a5,800038fc <namex+0x86>
    path++;
    80003978:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000397a:	0009c783          	lbu	a5,0(s3)
    8000397e:	ff279ce3          	bne	a5,s2,80003976 <namex+0x100>
    80003982:	bfad                	j	800038fc <namex+0x86>
    memmove(name, s, len);
    80003984:	2601                	sext.w	a2,a2
    80003986:	85a6                	mv	a1,s1
    80003988:	8556                	mv	a0,s5
    8000398a:	bbcfd0ef          	jal	80000d46 <memmove>
    name[len] = 0;
    8000398e:	9cd6                	add	s9,s9,s5
    80003990:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003994:	84ce                	mv	s1,s3
    80003996:	bfbd                	j	80003914 <namex+0x9e>
  if(nameiparent){
    80003998:	f20b0be3          	beqz	s6,800038ce <namex+0x58>
    iput(ip);
    8000399c:	8552                	mv	a0,s4
    8000399e:	a0fff0ef          	jal	800033ac <iput>
    return 0;
    800039a2:	4a01                	li	s4,0
    800039a4:	b72d                	j	800038ce <namex+0x58>

00000000800039a6 <dirlink>:
{
    800039a6:	7139                	addi	sp,sp,-64
    800039a8:	fc06                	sd	ra,56(sp)
    800039aa:	f822                	sd	s0,48(sp)
    800039ac:	f04a                	sd	s2,32(sp)
    800039ae:	ec4e                	sd	s3,24(sp)
    800039b0:	e852                	sd	s4,16(sp)
    800039b2:	0080                	addi	s0,sp,64
    800039b4:	892a                	mv	s2,a0
    800039b6:	8a2e                	mv	s4,a1
    800039b8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800039ba:	4601                	li	a2,0
    800039bc:	e1fff0ef          	jal	800037da <dirlookup>
    800039c0:	e535                	bnez	a0,80003a2c <dirlink+0x86>
    800039c2:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039c4:	04c92483          	lw	s1,76(s2)
    800039c8:	c48d                	beqz	s1,800039f2 <dirlink+0x4c>
    800039ca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039cc:	4741                	li	a4,16
    800039ce:	86a6                	mv	a3,s1
    800039d0:	fc040613          	addi	a2,s0,-64
    800039d4:	4581                	li	a1,0
    800039d6:	854a                	mv	a0,s2
    800039d8:	be3ff0ef          	jal	800035ba <readi>
    800039dc:	47c1                	li	a5,16
    800039de:	04f51b63          	bne	a0,a5,80003a34 <dirlink+0x8e>
    if(de.inum == 0)
    800039e2:	fc045783          	lhu	a5,-64(s0)
    800039e6:	c791                	beqz	a5,800039f2 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039e8:	24c1                	addiw	s1,s1,16
    800039ea:	04c92783          	lw	a5,76(s2)
    800039ee:	fcf4efe3          	bltu	s1,a5,800039cc <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    800039f2:	4639                	li	a2,14
    800039f4:	85d2                	mv	a1,s4
    800039f6:	fc240513          	addi	a0,s0,-62
    800039fa:	bf2fd0ef          	jal	80000dec <strncpy>
  de.inum = inum;
    800039fe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a02:	4741                	li	a4,16
    80003a04:	86a6                	mv	a3,s1
    80003a06:	fc040613          	addi	a2,s0,-64
    80003a0a:	4581                	li	a1,0
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	ca9ff0ef          	jal	800036b6 <writei>
    80003a12:	1541                	addi	a0,a0,-16
    80003a14:	00a03533          	snez	a0,a0
    80003a18:	40a00533          	neg	a0,a0
    80003a1c:	74a2                	ld	s1,40(sp)
}
    80003a1e:	70e2                	ld	ra,56(sp)
    80003a20:	7442                	ld	s0,48(sp)
    80003a22:	7902                	ld	s2,32(sp)
    80003a24:	69e2                	ld	s3,24(sp)
    80003a26:	6a42                	ld	s4,16(sp)
    80003a28:	6121                	addi	sp,sp,64
    80003a2a:	8082                	ret
    iput(ip);
    80003a2c:	981ff0ef          	jal	800033ac <iput>
    return -1;
    80003a30:	557d                	li	a0,-1
    80003a32:	b7f5                	j	80003a1e <dirlink+0x78>
      panic("dirlink read");
    80003a34:	00004517          	auipc	a0,0x4
    80003a38:	a9450513          	addi	a0,a0,-1388 # 800074c8 <etext+0x4c8>
    80003a3c:	da5fc0ef          	jal	800007e0 <panic>

0000000080003a40 <namei>:

struct inode*
namei(char *path)
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003a48:	fe040613          	addi	a2,s0,-32
    80003a4c:	4581                	li	a1,0
    80003a4e:	e29ff0ef          	jal	80003876 <namex>
}
    80003a52:	60e2                	ld	ra,24(sp)
    80003a54:	6442                	ld	s0,16(sp)
    80003a56:	6105                	addi	sp,sp,32
    80003a58:	8082                	ret

0000000080003a5a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003a5a:	1141                	addi	sp,sp,-16
    80003a5c:	e406                	sd	ra,8(sp)
    80003a5e:	e022                	sd	s0,0(sp)
    80003a60:	0800                	addi	s0,sp,16
    80003a62:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003a64:	4585                	li	a1,1
    80003a66:	e11ff0ef          	jal	80003876 <namex>
}
    80003a6a:	60a2                	ld	ra,8(sp)
    80003a6c:	6402                	ld	s0,0(sp)
    80003a6e:	0141                	addi	sp,sp,16
    80003a70:	8082                	ret

0000000080003a72 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	e04a                	sd	s2,0(sp)
    80003a7c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003a7e:	0001f917          	auipc	s2,0x1f
    80003a82:	81a90913          	addi	s2,s2,-2022 # 80022298 <log>
    80003a86:	01892583          	lw	a1,24(s2)
    80003a8a:	02492503          	lw	a0,36(s2)
    80003a8e:	8d0ff0ef          	jal	80002b5e <bread>
    80003a92:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003a94:	02892603          	lw	a2,40(s2)
    80003a98:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003a9a:	00c05f63          	blez	a2,80003ab8 <write_head+0x46>
    80003a9e:	0001f717          	auipc	a4,0x1f
    80003aa2:	82670713          	addi	a4,a4,-2010 # 800222c4 <log+0x2c>
    80003aa6:	87aa                	mv	a5,a0
    80003aa8:	060a                	slli	a2,a2,0x2
    80003aaa:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003aac:	4314                	lw	a3,0(a4)
    80003aae:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003ab0:	0711                	addi	a4,a4,4
    80003ab2:	0791                	addi	a5,a5,4
    80003ab4:	fec79ce3          	bne	a5,a2,80003aac <write_head+0x3a>
  }
  bwrite(buf);
    80003ab8:	8526                	mv	a0,s1
    80003aba:	97aff0ef          	jal	80002c34 <bwrite>
  brelse(buf);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	9a6ff0ef          	jal	80002c66 <brelse>
}
    80003ac4:	60e2                	ld	ra,24(sp)
    80003ac6:	6442                	ld	s0,16(sp)
    80003ac8:	64a2                	ld	s1,8(sp)
    80003aca:	6902                	ld	s2,0(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret

0000000080003ad0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ad0:	0001e797          	auipc	a5,0x1e
    80003ad4:	7f07a783          	lw	a5,2032(a5) # 800222c0 <log+0x28>
    80003ad8:	0af05e63          	blez	a5,80003b94 <install_trans+0xc4>
{
    80003adc:	715d                	addi	sp,sp,-80
    80003ade:	e486                	sd	ra,72(sp)
    80003ae0:	e0a2                	sd	s0,64(sp)
    80003ae2:	fc26                	sd	s1,56(sp)
    80003ae4:	f84a                	sd	s2,48(sp)
    80003ae6:	f44e                	sd	s3,40(sp)
    80003ae8:	f052                	sd	s4,32(sp)
    80003aea:	ec56                	sd	s5,24(sp)
    80003aec:	e85a                	sd	s6,16(sp)
    80003aee:	e45e                	sd	s7,8(sp)
    80003af0:	0880                	addi	s0,sp,80
    80003af2:	8b2a                	mv	s6,a0
    80003af4:	0001ea97          	auipc	s5,0x1e
    80003af8:	7d0a8a93          	addi	s5,s5,2000 # 800222c4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003afc:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003afe:	00004b97          	auipc	s7,0x4
    80003b02:	9dab8b93          	addi	s7,s7,-1574 # 800074d8 <etext+0x4d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b06:	0001ea17          	auipc	s4,0x1e
    80003b0a:	792a0a13          	addi	s4,s4,1938 # 80022298 <log>
    80003b0e:	a025                	j	80003b36 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b10:	000aa603          	lw	a2,0(s5)
    80003b14:	85ce                	mv	a1,s3
    80003b16:	855e                	mv	a0,s7
    80003b18:	9e3fc0ef          	jal	800004fa <printf>
    80003b1c:	a839                	j	80003b3a <install_trans+0x6a>
    brelse(lbuf);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	946ff0ef          	jal	80002c66 <brelse>
    brelse(dbuf);
    80003b24:	8526                	mv	a0,s1
    80003b26:	940ff0ef          	jal	80002c66 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b2a:	2985                	addiw	s3,s3,1
    80003b2c:	0a91                	addi	s5,s5,4
    80003b2e:	028a2783          	lw	a5,40(s4)
    80003b32:	04f9d663          	bge	s3,a5,80003b7e <install_trans+0xae>
    if(recovering) {
    80003b36:	fc0b1de3          	bnez	s6,80003b10 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b3a:	018a2583          	lw	a1,24(s4)
    80003b3e:	013585bb          	addw	a1,a1,s3
    80003b42:	2585                	addiw	a1,a1,1
    80003b44:	024a2503          	lw	a0,36(s4)
    80003b48:	816ff0ef          	jal	80002b5e <bread>
    80003b4c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003b4e:	000aa583          	lw	a1,0(s5)
    80003b52:	024a2503          	lw	a0,36(s4)
    80003b56:	808ff0ef          	jal	80002b5e <bread>
    80003b5a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003b5c:	40000613          	li	a2,1024
    80003b60:	05890593          	addi	a1,s2,88
    80003b64:	05850513          	addi	a0,a0,88
    80003b68:	9defd0ef          	jal	80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	8c6ff0ef          	jal	80002c34 <bwrite>
    if(recovering == 0)
    80003b72:	fa0b16e3          	bnez	s6,80003b1e <install_trans+0x4e>
      bunpin(dbuf);
    80003b76:	8526                	mv	a0,s1
    80003b78:	9aaff0ef          	jal	80002d22 <bunpin>
    80003b7c:	b74d                	j	80003b1e <install_trans+0x4e>
}
    80003b7e:	60a6                	ld	ra,72(sp)
    80003b80:	6406                	ld	s0,64(sp)
    80003b82:	74e2                	ld	s1,56(sp)
    80003b84:	7942                	ld	s2,48(sp)
    80003b86:	79a2                	ld	s3,40(sp)
    80003b88:	7a02                	ld	s4,32(sp)
    80003b8a:	6ae2                	ld	s5,24(sp)
    80003b8c:	6b42                	ld	s6,16(sp)
    80003b8e:	6ba2                	ld	s7,8(sp)
    80003b90:	6161                	addi	sp,sp,80
    80003b92:	8082                	ret
    80003b94:	8082                	ret

0000000080003b96 <initlog>:
{
    80003b96:	7179                	addi	sp,sp,-48
    80003b98:	f406                	sd	ra,40(sp)
    80003b9a:	f022                	sd	s0,32(sp)
    80003b9c:	ec26                	sd	s1,24(sp)
    80003b9e:	e84a                	sd	s2,16(sp)
    80003ba0:	e44e                	sd	s3,8(sp)
    80003ba2:	1800                	addi	s0,sp,48
    80003ba4:	892a                	mv	s2,a0
    80003ba6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ba8:	0001e497          	auipc	s1,0x1e
    80003bac:	6f048493          	addi	s1,s1,1776 # 80022298 <log>
    80003bb0:	00004597          	auipc	a1,0x4
    80003bb4:	94858593          	addi	a1,a1,-1720 # 800074f8 <etext+0x4f8>
    80003bb8:	8526                	mv	a0,s1
    80003bba:	fddfc0ef          	jal	80000b96 <initlock>
  log.start = sb->logstart;
    80003bbe:	0149a583          	lw	a1,20(s3)
    80003bc2:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003bc4:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003bc8:	854a                	mv	a0,s2
    80003bca:	f95fe0ef          	jal	80002b5e <bread>
  log.lh.n = lh->n;
    80003bce:	4d30                	lw	a2,88(a0)
    80003bd0:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003bd2:	00c05f63          	blez	a2,80003bf0 <initlog+0x5a>
    80003bd6:	87aa                	mv	a5,a0
    80003bd8:	0001e717          	auipc	a4,0x1e
    80003bdc:	6ec70713          	addi	a4,a4,1772 # 800222c4 <log+0x2c>
    80003be0:	060a                	slli	a2,a2,0x2
    80003be2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003be4:	4ff4                	lw	a3,92(a5)
    80003be6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003be8:	0791                	addi	a5,a5,4
    80003bea:	0711                	addi	a4,a4,4
    80003bec:	fec79ce3          	bne	a5,a2,80003be4 <initlog+0x4e>
  brelse(buf);
    80003bf0:	876ff0ef          	jal	80002c66 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003bf4:	4505                	li	a0,1
    80003bf6:	edbff0ef          	jal	80003ad0 <install_trans>
  log.lh.n = 0;
    80003bfa:	0001e797          	auipc	a5,0x1e
    80003bfe:	6c07a323          	sw	zero,1734(a5) # 800222c0 <log+0x28>
  write_head(); // clear the log
    80003c02:	e71ff0ef          	jal	80003a72 <write_head>
}
    80003c06:	70a2                	ld	ra,40(sp)
    80003c08:	7402                	ld	s0,32(sp)
    80003c0a:	64e2                	ld	s1,24(sp)
    80003c0c:	6942                	ld	s2,16(sp)
    80003c0e:	69a2                	ld	s3,8(sp)
    80003c10:	6145                	addi	sp,sp,48
    80003c12:	8082                	ret

0000000080003c14 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003c14:	1101                	addi	sp,sp,-32
    80003c16:	ec06                	sd	ra,24(sp)
    80003c18:	e822                	sd	s0,16(sp)
    80003c1a:	e426                	sd	s1,8(sp)
    80003c1c:	e04a                	sd	s2,0(sp)
    80003c1e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003c20:	0001e517          	auipc	a0,0x1e
    80003c24:	67850513          	addi	a0,a0,1656 # 80022298 <log>
    80003c28:	feffc0ef          	jal	80000c16 <acquire>
  while(1){
    if(log.committing){
    80003c2c:	0001e497          	auipc	s1,0x1e
    80003c30:	66c48493          	addi	s1,s1,1644 # 80022298 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c34:	4979                	li	s2,30
    80003c36:	a029                	j	80003c40 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003c38:	85a6                	mv	a1,s1
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	ae4fe0ef          	jal	80001f20 <sleep>
    if(log.committing){
    80003c40:	509c                	lw	a5,32(s1)
    80003c42:	fbfd                	bnez	a5,80003c38 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c44:	4cd8                	lw	a4,28(s1)
    80003c46:	2705                	addiw	a4,a4,1
    80003c48:	0027179b          	slliw	a5,a4,0x2
    80003c4c:	9fb9                	addw	a5,a5,a4
    80003c4e:	0017979b          	slliw	a5,a5,0x1
    80003c52:	5494                	lw	a3,40(s1)
    80003c54:	9fb5                	addw	a5,a5,a3
    80003c56:	00f95763          	bge	s2,a5,80003c64 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003c5a:	85a6                	mv	a1,s1
    80003c5c:	8526                	mv	a0,s1
    80003c5e:	ac2fe0ef          	jal	80001f20 <sleep>
    80003c62:	bff9                	j	80003c40 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003c64:	0001e517          	auipc	a0,0x1e
    80003c68:	63450513          	addi	a0,a0,1588 # 80022298 <log>
    80003c6c:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003c6e:	840fd0ef          	jal	80000cae <release>
      break;
    }
  }
}
    80003c72:	60e2                	ld	ra,24(sp)
    80003c74:	6442                	ld	s0,16(sp)
    80003c76:	64a2                	ld	s1,8(sp)
    80003c78:	6902                	ld	s2,0(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret

0000000080003c7e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003c7e:	7139                	addi	sp,sp,-64
    80003c80:	fc06                	sd	ra,56(sp)
    80003c82:	f822                	sd	s0,48(sp)
    80003c84:	f426                	sd	s1,40(sp)
    80003c86:	f04a                	sd	s2,32(sp)
    80003c88:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003c8a:	0001e497          	auipc	s1,0x1e
    80003c8e:	60e48493          	addi	s1,s1,1550 # 80022298 <log>
    80003c92:	8526                	mv	a0,s1
    80003c94:	f83fc0ef          	jal	80000c16 <acquire>
  log.outstanding -= 1;
    80003c98:	4cdc                	lw	a5,28(s1)
    80003c9a:	37fd                	addiw	a5,a5,-1
    80003c9c:	0007891b          	sext.w	s2,a5
    80003ca0:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003ca2:	509c                	lw	a5,32(s1)
    80003ca4:	ef9d                	bnez	a5,80003ce2 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003ca6:	04091763          	bnez	s2,80003cf4 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003caa:	0001e497          	auipc	s1,0x1e
    80003cae:	5ee48493          	addi	s1,s1,1518 # 80022298 <log>
    80003cb2:	4785                	li	a5,1
    80003cb4:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003cb6:	8526                	mv	a0,s1
    80003cb8:	ff7fc0ef          	jal	80000cae <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003cbc:	549c                	lw	a5,40(s1)
    80003cbe:	04f04b63          	bgtz	a5,80003d14 <end_op+0x96>
    acquire(&log.lock);
    80003cc2:	0001e497          	auipc	s1,0x1e
    80003cc6:	5d648493          	addi	s1,s1,1494 # 80022298 <log>
    80003cca:	8526                	mv	a0,s1
    80003ccc:	f4bfc0ef          	jal	80000c16 <acquire>
    log.committing = 0;
    80003cd0:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	a96fe0ef          	jal	80001f6c <wakeup>
    release(&log.lock);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	fd3fc0ef          	jal	80000cae <release>
}
    80003ce0:	a025                	j	80003d08 <end_op+0x8a>
    80003ce2:	ec4e                	sd	s3,24(sp)
    80003ce4:	e852                	sd	s4,16(sp)
    80003ce6:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003ce8:	00004517          	auipc	a0,0x4
    80003cec:	81850513          	addi	a0,a0,-2024 # 80007500 <etext+0x500>
    80003cf0:	af1fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80003cf4:	0001e497          	auipc	s1,0x1e
    80003cf8:	5a448493          	addi	s1,s1,1444 # 80022298 <log>
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	a6efe0ef          	jal	80001f6c <wakeup>
  release(&log.lock);
    80003d02:	8526                	mv	a0,s1
    80003d04:	fabfc0ef          	jal	80000cae <release>
}
    80003d08:	70e2                	ld	ra,56(sp)
    80003d0a:	7442                	ld	s0,48(sp)
    80003d0c:	74a2                	ld	s1,40(sp)
    80003d0e:	7902                	ld	s2,32(sp)
    80003d10:	6121                	addi	sp,sp,64
    80003d12:	8082                	ret
    80003d14:	ec4e                	sd	s3,24(sp)
    80003d16:	e852                	sd	s4,16(sp)
    80003d18:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d1a:	0001ea97          	auipc	s5,0x1e
    80003d1e:	5aaa8a93          	addi	s5,s5,1450 # 800222c4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003d22:	0001ea17          	auipc	s4,0x1e
    80003d26:	576a0a13          	addi	s4,s4,1398 # 80022298 <log>
    80003d2a:	018a2583          	lw	a1,24(s4)
    80003d2e:	012585bb          	addw	a1,a1,s2
    80003d32:	2585                	addiw	a1,a1,1
    80003d34:	024a2503          	lw	a0,36(s4)
    80003d38:	e27fe0ef          	jal	80002b5e <bread>
    80003d3c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003d3e:	000aa583          	lw	a1,0(s5)
    80003d42:	024a2503          	lw	a0,36(s4)
    80003d46:	e19fe0ef          	jal	80002b5e <bread>
    80003d4a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003d4c:	40000613          	li	a2,1024
    80003d50:	05850593          	addi	a1,a0,88
    80003d54:	05848513          	addi	a0,s1,88
    80003d58:	feffc0ef          	jal	80000d46 <memmove>
    bwrite(to);  // write the log
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	ed7fe0ef          	jal	80002c34 <bwrite>
    brelse(from);
    80003d62:	854e                	mv	a0,s3
    80003d64:	f03fe0ef          	jal	80002c66 <brelse>
    brelse(to);
    80003d68:	8526                	mv	a0,s1
    80003d6a:	efdfe0ef          	jal	80002c66 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d6e:	2905                	addiw	s2,s2,1
    80003d70:	0a91                	addi	s5,s5,4
    80003d72:	028a2783          	lw	a5,40(s4)
    80003d76:	faf94ae3          	blt	s2,a5,80003d2a <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003d7a:	cf9ff0ef          	jal	80003a72 <write_head>
    install_trans(0); // Now install writes to home locations
    80003d7e:	4501                	li	a0,0
    80003d80:	d51ff0ef          	jal	80003ad0 <install_trans>
    log.lh.n = 0;
    80003d84:	0001e797          	auipc	a5,0x1e
    80003d88:	5207ae23          	sw	zero,1340(a5) # 800222c0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003d8c:	ce7ff0ef          	jal	80003a72 <write_head>
    80003d90:	69e2                	ld	s3,24(sp)
    80003d92:	6a42                	ld	s4,16(sp)
    80003d94:	6aa2                	ld	s5,8(sp)
    80003d96:	b735                	j	80003cc2 <end_op+0x44>

0000000080003d98 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	e04a                	sd	s2,0(sp)
    80003da2:	1000                	addi	s0,sp,32
    80003da4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003da6:	0001e917          	auipc	s2,0x1e
    80003daa:	4f290913          	addi	s2,s2,1266 # 80022298 <log>
    80003dae:	854a                	mv	a0,s2
    80003db0:	e67fc0ef          	jal	80000c16 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003db4:	02892603          	lw	a2,40(s2)
    80003db8:	47f5                	li	a5,29
    80003dba:	04c7cc63          	blt	a5,a2,80003e12 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003dbe:	0001e797          	auipc	a5,0x1e
    80003dc2:	4f67a783          	lw	a5,1270(a5) # 800222b4 <log+0x1c>
    80003dc6:	04f05c63          	blez	a5,80003e1e <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003dca:	4781                	li	a5,0
    80003dcc:	04c05f63          	blez	a2,80003e2a <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003dd0:	44cc                	lw	a1,12(s1)
    80003dd2:	0001e717          	auipc	a4,0x1e
    80003dd6:	4f270713          	addi	a4,a4,1266 # 800222c4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003dda:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003ddc:	4314                	lw	a3,0(a4)
    80003dde:	04b68663          	beq	a3,a1,80003e2a <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003de2:	2785                	addiw	a5,a5,1
    80003de4:	0711                	addi	a4,a4,4
    80003de6:	fef61be3          	bne	a2,a5,80003ddc <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003dea:	0621                	addi	a2,a2,8
    80003dec:	060a                	slli	a2,a2,0x2
    80003dee:	0001e797          	auipc	a5,0x1e
    80003df2:	4aa78793          	addi	a5,a5,1194 # 80022298 <log>
    80003df6:	97b2                	add	a5,a5,a2
    80003df8:	44d8                	lw	a4,12(s1)
    80003dfa:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	ef1fe0ef          	jal	80002cee <bpin>
    log.lh.n++;
    80003e02:	0001e717          	auipc	a4,0x1e
    80003e06:	49670713          	addi	a4,a4,1174 # 80022298 <log>
    80003e0a:	571c                	lw	a5,40(a4)
    80003e0c:	2785                	addiw	a5,a5,1
    80003e0e:	d71c                	sw	a5,40(a4)
    80003e10:	a80d                	j	80003e42 <log_write+0xaa>
    panic("too big a transaction");
    80003e12:	00003517          	auipc	a0,0x3
    80003e16:	6fe50513          	addi	a0,a0,1790 # 80007510 <etext+0x510>
    80003e1a:	9c7fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80003e1e:	00003517          	auipc	a0,0x3
    80003e22:	70a50513          	addi	a0,a0,1802 # 80007528 <etext+0x528>
    80003e26:	9bbfc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80003e2a:	00878693          	addi	a3,a5,8
    80003e2e:	068a                	slli	a3,a3,0x2
    80003e30:	0001e717          	auipc	a4,0x1e
    80003e34:	46870713          	addi	a4,a4,1128 # 80022298 <log>
    80003e38:	9736                	add	a4,a4,a3
    80003e3a:	44d4                	lw	a3,12(s1)
    80003e3c:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003e3e:	faf60fe3          	beq	a2,a5,80003dfc <log_write+0x64>
  }
  release(&log.lock);
    80003e42:	0001e517          	auipc	a0,0x1e
    80003e46:	45650513          	addi	a0,a0,1110 # 80022298 <log>
    80003e4a:	e65fc0ef          	jal	80000cae <release>
}
    80003e4e:	60e2                	ld	ra,24(sp)
    80003e50:	6442                	ld	s0,16(sp)
    80003e52:	64a2                	ld	s1,8(sp)
    80003e54:	6902                	ld	s2,0(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003e5a:	1101                	addi	sp,sp,-32
    80003e5c:	ec06                	sd	ra,24(sp)
    80003e5e:	e822                	sd	s0,16(sp)
    80003e60:	e426                	sd	s1,8(sp)
    80003e62:	e04a                	sd	s2,0(sp)
    80003e64:	1000                	addi	s0,sp,32
    80003e66:	84aa                	mv	s1,a0
    80003e68:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003e6a:	00003597          	auipc	a1,0x3
    80003e6e:	6de58593          	addi	a1,a1,1758 # 80007548 <etext+0x548>
    80003e72:	0521                	addi	a0,a0,8
    80003e74:	d23fc0ef          	jal	80000b96 <initlock>
  lk->name = name;
    80003e78:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003e7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003e80:	0204a423          	sw	zero,40(s1)
}
    80003e84:	60e2                	ld	ra,24(sp)
    80003e86:	6442                	ld	s0,16(sp)
    80003e88:	64a2                	ld	s1,8(sp)
    80003e8a:	6902                	ld	s2,0(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret

0000000080003e90 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003e90:	1101                	addi	sp,sp,-32
    80003e92:	ec06                	sd	ra,24(sp)
    80003e94:	e822                	sd	s0,16(sp)
    80003e96:	e426                	sd	s1,8(sp)
    80003e98:	e04a                	sd	s2,0(sp)
    80003e9a:	1000                	addi	s0,sp,32
    80003e9c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003e9e:	00850913          	addi	s2,a0,8
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	d73fc0ef          	jal	80000c16 <acquire>
  while (lk->locked) {
    80003ea8:	409c                	lw	a5,0(s1)
    80003eaa:	c799                	beqz	a5,80003eb8 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003eac:	85ca                	mv	a1,s2
    80003eae:	8526                	mv	a0,s1
    80003eb0:	870fe0ef          	jal	80001f20 <sleep>
  while (lk->locked) {
    80003eb4:	409c                	lw	a5,0(s1)
    80003eb6:	fbfd                	bnez	a5,80003eac <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003eb8:	4785                	li	a5,1
    80003eba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003ebc:	a5bfd0ef          	jal	80001916 <myproc>
    80003ec0:	591c                	lw	a5,48(a0)
    80003ec2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	de9fc0ef          	jal	80000cae <release>
}
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	64a2                	ld	s1,8(sp)
    80003ed0:	6902                	ld	s2,0(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003ed6:	1101                	addi	sp,sp,-32
    80003ed8:	ec06                	sd	ra,24(sp)
    80003eda:	e822                	sd	s0,16(sp)
    80003edc:	e426                	sd	s1,8(sp)
    80003ede:	e04a                	sd	s2,0(sp)
    80003ee0:	1000                	addi	s0,sp,32
    80003ee2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003ee4:	00850913          	addi	s2,a0,8
    80003ee8:	854a                	mv	a0,s2
    80003eea:	d2dfc0ef          	jal	80000c16 <acquire>
  lk->locked = 0;
    80003eee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003ef2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003ef6:	8526                	mv	a0,s1
    80003ef8:	874fe0ef          	jal	80001f6c <wakeup>
  release(&lk->lk);
    80003efc:	854a                	mv	a0,s2
    80003efe:	db1fc0ef          	jal	80000cae <release>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	64a2                	ld	s1,8(sp)
    80003f08:	6902                	ld	s2,0(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003f0e:	7179                	addi	sp,sp,-48
    80003f10:	f406                	sd	ra,40(sp)
    80003f12:	f022                	sd	s0,32(sp)
    80003f14:	ec26                	sd	s1,24(sp)
    80003f16:	e84a                	sd	s2,16(sp)
    80003f18:	1800                	addi	s0,sp,48
    80003f1a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003f1c:	00850913          	addi	s2,a0,8
    80003f20:	854a                	mv	a0,s2
    80003f22:	cf5fc0ef          	jal	80000c16 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f26:	409c                	lw	a5,0(s1)
    80003f28:	ef81                	bnez	a5,80003f40 <holdingsleep+0x32>
    80003f2a:	4481                	li	s1,0
  release(&lk->lk);
    80003f2c:	854a                	mv	a0,s2
    80003f2e:	d81fc0ef          	jal	80000cae <release>
  return r;
}
    80003f32:	8526                	mv	a0,s1
    80003f34:	70a2                	ld	ra,40(sp)
    80003f36:	7402                	ld	s0,32(sp)
    80003f38:	64e2                	ld	s1,24(sp)
    80003f3a:	6942                	ld	s2,16(sp)
    80003f3c:	6145                	addi	sp,sp,48
    80003f3e:	8082                	ret
    80003f40:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f42:	0284a983          	lw	s3,40(s1)
    80003f46:	9d1fd0ef          	jal	80001916 <myproc>
    80003f4a:	5904                	lw	s1,48(a0)
    80003f4c:	413484b3          	sub	s1,s1,s3
    80003f50:	0014b493          	seqz	s1,s1
    80003f54:	69a2                	ld	s3,8(sp)
    80003f56:	bfd9                	j	80003f2c <holdingsleep+0x1e>

0000000080003f58 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003f58:	1141                	addi	sp,sp,-16
    80003f5a:	e406                	sd	ra,8(sp)
    80003f5c:	e022                	sd	s0,0(sp)
    80003f5e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80003f60:	00003597          	auipc	a1,0x3
    80003f64:	5f858593          	addi	a1,a1,1528 # 80007558 <etext+0x558>
    80003f68:	0001e517          	auipc	a0,0x1e
    80003f6c:	47850513          	addi	a0,a0,1144 # 800223e0 <ftable>
    80003f70:	c27fc0ef          	jal	80000b96 <initlock>
}
    80003f74:	60a2                	ld	ra,8(sp)
    80003f76:	6402                	ld	s0,0(sp)
    80003f78:	0141                	addi	sp,sp,16
    80003f7a:	8082                	ret

0000000080003f7c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80003f86:	0001e517          	auipc	a0,0x1e
    80003f8a:	45a50513          	addi	a0,a0,1114 # 800223e0 <ftable>
    80003f8e:	c89fc0ef          	jal	80000c16 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003f92:	0001e497          	auipc	s1,0x1e
    80003f96:	46648493          	addi	s1,s1,1126 # 800223f8 <ftable+0x18>
    80003f9a:	0001f717          	auipc	a4,0x1f
    80003f9e:	3fe70713          	addi	a4,a4,1022 # 80023398 <disk>
    if(f->ref == 0){
    80003fa2:	40dc                	lw	a5,4(s1)
    80003fa4:	cf89                	beqz	a5,80003fbe <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003fa6:	02848493          	addi	s1,s1,40
    80003faa:	fee49ce3          	bne	s1,a4,80003fa2 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80003fae:	0001e517          	auipc	a0,0x1e
    80003fb2:	43250513          	addi	a0,a0,1074 # 800223e0 <ftable>
    80003fb6:	cf9fc0ef          	jal	80000cae <release>
  return 0;
    80003fba:	4481                	li	s1,0
    80003fbc:	a809                	j	80003fce <filealloc+0x52>
      f->ref = 1;
    80003fbe:	4785                	li	a5,1
    80003fc0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80003fc2:	0001e517          	auipc	a0,0x1e
    80003fc6:	41e50513          	addi	a0,a0,1054 # 800223e0 <ftable>
    80003fca:	ce5fc0ef          	jal	80000cae <release>
}
    80003fce:	8526                	mv	a0,s1
    80003fd0:	60e2                	ld	ra,24(sp)
    80003fd2:	6442                	ld	s0,16(sp)
    80003fd4:	64a2                	ld	s1,8(sp)
    80003fd6:	6105                	addi	sp,sp,32
    80003fd8:	8082                	ret

0000000080003fda <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	1000                	addi	s0,sp,32
    80003fe4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80003fe6:	0001e517          	auipc	a0,0x1e
    80003fea:	3fa50513          	addi	a0,a0,1018 # 800223e0 <ftable>
    80003fee:	c29fc0ef          	jal	80000c16 <acquire>
  if(f->ref < 1)
    80003ff2:	40dc                	lw	a5,4(s1)
    80003ff4:	02f05063          	blez	a5,80004014 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80003ff8:	2785                	addiw	a5,a5,1
    80003ffa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80003ffc:	0001e517          	auipc	a0,0x1e
    80004000:	3e450513          	addi	a0,a0,996 # 800223e0 <ftable>
    80004004:	cabfc0ef          	jal	80000cae <release>
  return f;
}
    80004008:	8526                	mv	a0,s1
    8000400a:	60e2                	ld	ra,24(sp)
    8000400c:	6442                	ld	s0,16(sp)
    8000400e:	64a2                	ld	s1,8(sp)
    80004010:	6105                	addi	sp,sp,32
    80004012:	8082                	ret
    panic("filedup");
    80004014:	00003517          	auipc	a0,0x3
    80004018:	54c50513          	addi	a0,a0,1356 # 80007560 <etext+0x560>
    8000401c:	fc4fc0ef          	jal	800007e0 <panic>

0000000080004020 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004020:	7139                	addi	sp,sp,-64
    80004022:	fc06                	sd	ra,56(sp)
    80004024:	f822                	sd	s0,48(sp)
    80004026:	f426                	sd	s1,40(sp)
    80004028:	0080                	addi	s0,sp,64
    8000402a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000402c:	0001e517          	auipc	a0,0x1e
    80004030:	3b450513          	addi	a0,a0,948 # 800223e0 <ftable>
    80004034:	be3fc0ef          	jal	80000c16 <acquire>
  if(f->ref < 1)
    80004038:	40dc                	lw	a5,4(s1)
    8000403a:	04f05a63          	blez	a5,8000408e <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    8000403e:	37fd                	addiw	a5,a5,-1
    80004040:	0007871b          	sext.w	a4,a5
    80004044:	c0dc                	sw	a5,4(s1)
    80004046:	04e04e63          	bgtz	a4,800040a2 <fileclose+0x82>
    8000404a:	f04a                	sd	s2,32(sp)
    8000404c:	ec4e                	sd	s3,24(sp)
    8000404e:	e852                	sd	s4,16(sp)
    80004050:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004052:	0004a903          	lw	s2,0(s1)
    80004056:	0094ca83          	lbu	s5,9(s1)
    8000405a:	0104ba03          	ld	s4,16(s1)
    8000405e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004062:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004066:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000406a:	0001e517          	auipc	a0,0x1e
    8000406e:	37650513          	addi	a0,a0,886 # 800223e0 <ftable>
    80004072:	c3dfc0ef          	jal	80000cae <release>

  if(ff.type == FD_PIPE){
    80004076:	4785                	li	a5,1
    80004078:	04f90063          	beq	s2,a5,800040b8 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000407c:	3979                	addiw	s2,s2,-2
    8000407e:	4785                	li	a5,1
    80004080:	0527f563          	bgeu	a5,s2,800040ca <fileclose+0xaa>
    80004084:	7902                	ld	s2,32(sp)
    80004086:	69e2                	ld	s3,24(sp)
    80004088:	6a42                	ld	s4,16(sp)
    8000408a:	6aa2                	ld	s5,8(sp)
    8000408c:	a00d                	j	800040ae <fileclose+0x8e>
    8000408e:	f04a                	sd	s2,32(sp)
    80004090:	ec4e                	sd	s3,24(sp)
    80004092:	e852                	sd	s4,16(sp)
    80004094:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004096:	00003517          	auipc	a0,0x3
    8000409a:	4d250513          	addi	a0,a0,1234 # 80007568 <etext+0x568>
    8000409e:	f42fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    800040a2:	0001e517          	auipc	a0,0x1e
    800040a6:	33e50513          	addi	a0,a0,830 # 800223e0 <ftable>
    800040aa:	c05fc0ef          	jal	80000cae <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800040ae:	70e2                	ld	ra,56(sp)
    800040b0:	7442                	ld	s0,48(sp)
    800040b2:	74a2                	ld	s1,40(sp)
    800040b4:	6121                	addi	sp,sp,64
    800040b6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800040b8:	85d6                	mv	a1,s5
    800040ba:	8552                	mv	a0,s4
    800040bc:	336000ef          	jal	800043f2 <pipeclose>
    800040c0:	7902                	ld	s2,32(sp)
    800040c2:	69e2                	ld	s3,24(sp)
    800040c4:	6a42                	ld	s4,16(sp)
    800040c6:	6aa2                	ld	s5,8(sp)
    800040c8:	b7dd                	j	800040ae <fileclose+0x8e>
    begin_op();
    800040ca:	b4bff0ef          	jal	80003c14 <begin_op>
    iput(ff.ip);
    800040ce:	854e                	mv	a0,s3
    800040d0:	adcff0ef          	jal	800033ac <iput>
    end_op();
    800040d4:	babff0ef          	jal	80003c7e <end_op>
    800040d8:	7902                	ld	s2,32(sp)
    800040da:	69e2                	ld	s3,24(sp)
    800040dc:	6a42                	ld	s4,16(sp)
    800040de:	6aa2                	ld	s5,8(sp)
    800040e0:	b7f9                	j	800040ae <fileclose+0x8e>

00000000800040e2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800040e2:	715d                	addi	sp,sp,-80
    800040e4:	e486                	sd	ra,72(sp)
    800040e6:	e0a2                	sd	s0,64(sp)
    800040e8:	fc26                	sd	s1,56(sp)
    800040ea:	f44e                	sd	s3,40(sp)
    800040ec:	0880                	addi	s0,sp,80
    800040ee:	84aa                	mv	s1,a0
    800040f0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800040f2:	825fd0ef          	jal	80001916 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800040f6:	409c                	lw	a5,0(s1)
    800040f8:	37f9                	addiw	a5,a5,-2
    800040fa:	4705                	li	a4,1
    800040fc:	04f76063          	bltu	a4,a5,8000413c <filestat+0x5a>
    80004100:	f84a                	sd	s2,48(sp)
    80004102:	892a                	mv	s2,a0
    ilock(f->ip);
    80004104:	6c88                	ld	a0,24(s1)
    80004106:	924ff0ef          	jal	8000322a <ilock>
    stati(f->ip, &st);
    8000410a:	fb840593          	addi	a1,s0,-72
    8000410e:	6c88                	ld	a0,24(s1)
    80004110:	c80ff0ef          	jal	80003590 <stati>
    iunlock(f->ip);
    80004114:	6c88                	ld	a0,24(s1)
    80004116:	9c2ff0ef          	jal	800032d8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000411a:	46e1                	li	a3,24
    8000411c:	fb840613          	addi	a2,s0,-72
    80004120:	85ce                	mv	a1,s3
    80004122:	05093503          	ld	a0,80(s2)
    80004126:	d04fd0ef          	jal	8000162a <copyout>
    8000412a:	41f5551b          	sraiw	a0,a0,0x1f
    8000412e:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004130:	60a6                	ld	ra,72(sp)
    80004132:	6406                	ld	s0,64(sp)
    80004134:	74e2                	ld	s1,56(sp)
    80004136:	79a2                	ld	s3,40(sp)
    80004138:	6161                	addi	sp,sp,80
    8000413a:	8082                	ret
  return -1;
    8000413c:	557d                	li	a0,-1
    8000413e:	bfcd                	j	80004130 <filestat+0x4e>

0000000080004140 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004140:	7179                	addi	sp,sp,-48
    80004142:	f406                	sd	ra,40(sp)
    80004144:	f022                	sd	s0,32(sp)
    80004146:	e84a                	sd	s2,16(sp)
    80004148:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000414a:	00854783          	lbu	a5,8(a0)
    8000414e:	cfd1                	beqz	a5,800041ea <fileread+0xaa>
    80004150:	ec26                	sd	s1,24(sp)
    80004152:	e44e                	sd	s3,8(sp)
    80004154:	84aa                	mv	s1,a0
    80004156:	89ae                	mv	s3,a1
    80004158:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000415a:	411c                	lw	a5,0(a0)
    8000415c:	4705                	li	a4,1
    8000415e:	04e78363          	beq	a5,a4,800041a4 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004162:	470d                	li	a4,3
    80004164:	04e78763          	beq	a5,a4,800041b2 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004168:	4709                	li	a4,2
    8000416a:	06e79a63          	bne	a5,a4,800041de <fileread+0x9e>
    ilock(f->ip);
    8000416e:	6d08                	ld	a0,24(a0)
    80004170:	8baff0ef          	jal	8000322a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004174:	874a                	mv	a4,s2
    80004176:	5094                	lw	a3,32(s1)
    80004178:	864e                	mv	a2,s3
    8000417a:	4585                	li	a1,1
    8000417c:	6c88                	ld	a0,24(s1)
    8000417e:	c3cff0ef          	jal	800035ba <readi>
    80004182:	892a                	mv	s2,a0
    80004184:	00a05563          	blez	a0,8000418e <fileread+0x4e>
      f->off += r;
    80004188:	509c                	lw	a5,32(s1)
    8000418a:	9fa9                	addw	a5,a5,a0
    8000418c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000418e:	6c88                	ld	a0,24(s1)
    80004190:	948ff0ef          	jal	800032d8 <iunlock>
    80004194:	64e2                	ld	s1,24(sp)
    80004196:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004198:	854a                	mv	a0,s2
    8000419a:	70a2                	ld	ra,40(sp)
    8000419c:	7402                	ld	s0,32(sp)
    8000419e:	6942                	ld	s2,16(sp)
    800041a0:	6145                	addi	sp,sp,48
    800041a2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800041a4:	6908                	ld	a0,16(a0)
    800041a6:	388000ef          	jal	8000452e <piperead>
    800041aa:	892a                	mv	s2,a0
    800041ac:	64e2                	ld	s1,24(sp)
    800041ae:	69a2                	ld	s3,8(sp)
    800041b0:	b7e5                	j	80004198 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800041b2:	02451783          	lh	a5,36(a0)
    800041b6:	03079693          	slli	a3,a5,0x30
    800041ba:	92c1                	srli	a3,a3,0x30
    800041bc:	4725                	li	a4,9
    800041be:	02d76863          	bltu	a4,a3,800041ee <fileread+0xae>
    800041c2:	0792                	slli	a5,a5,0x4
    800041c4:	0001e717          	auipc	a4,0x1e
    800041c8:	17c70713          	addi	a4,a4,380 # 80022340 <devsw>
    800041cc:	97ba                	add	a5,a5,a4
    800041ce:	639c                	ld	a5,0(a5)
    800041d0:	c39d                	beqz	a5,800041f6 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    800041d2:	4505                	li	a0,1
    800041d4:	9782                	jalr	a5
    800041d6:	892a                	mv	s2,a0
    800041d8:	64e2                	ld	s1,24(sp)
    800041da:	69a2                	ld	s3,8(sp)
    800041dc:	bf75                	j	80004198 <fileread+0x58>
    panic("fileread");
    800041de:	00003517          	auipc	a0,0x3
    800041e2:	39a50513          	addi	a0,a0,922 # 80007578 <etext+0x578>
    800041e6:	dfafc0ef          	jal	800007e0 <panic>
    return -1;
    800041ea:	597d                	li	s2,-1
    800041ec:	b775                	j	80004198 <fileread+0x58>
      return -1;
    800041ee:	597d                	li	s2,-1
    800041f0:	64e2                	ld	s1,24(sp)
    800041f2:	69a2                	ld	s3,8(sp)
    800041f4:	b755                	j	80004198 <fileread+0x58>
    800041f6:	597d                	li	s2,-1
    800041f8:	64e2                	ld	s1,24(sp)
    800041fa:	69a2                	ld	s3,8(sp)
    800041fc:	bf71                	j	80004198 <fileread+0x58>

00000000800041fe <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800041fe:	00954783          	lbu	a5,9(a0)
    80004202:	10078b63          	beqz	a5,80004318 <filewrite+0x11a>
{
    80004206:	715d                	addi	sp,sp,-80
    80004208:	e486                	sd	ra,72(sp)
    8000420a:	e0a2                	sd	s0,64(sp)
    8000420c:	f84a                	sd	s2,48(sp)
    8000420e:	f052                	sd	s4,32(sp)
    80004210:	e85a                	sd	s6,16(sp)
    80004212:	0880                	addi	s0,sp,80
    80004214:	892a                	mv	s2,a0
    80004216:	8b2e                	mv	s6,a1
    80004218:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000421a:	411c                	lw	a5,0(a0)
    8000421c:	4705                	li	a4,1
    8000421e:	02e78763          	beq	a5,a4,8000424c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004222:	470d                	li	a4,3
    80004224:	02e78863          	beq	a5,a4,80004254 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004228:	4709                	li	a4,2
    8000422a:	0ce79c63          	bne	a5,a4,80004302 <filewrite+0x104>
    8000422e:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004230:	0ac05863          	blez	a2,800042e0 <filewrite+0xe2>
    80004234:	fc26                	sd	s1,56(sp)
    80004236:	ec56                	sd	s5,24(sp)
    80004238:	e45e                	sd	s7,8(sp)
    8000423a:	e062                	sd	s8,0(sp)
    int i = 0;
    8000423c:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    8000423e:	6b85                	lui	s7,0x1
    80004240:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004244:	6c05                	lui	s8,0x1
    80004246:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000424a:	a8b5                	j	800042c6 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    8000424c:	6908                	ld	a0,16(a0)
    8000424e:	1fc000ef          	jal	8000444a <pipewrite>
    80004252:	a04d                	j	800042f4 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004254:	02451783          	lh	a5,36(a0)
    80004258:	03079693          	slli	a3,a5,0x30
    8000425c:	92c1                	srli	a3,a3,0x30
    8000425e:	4725                	li	a4,9
    80004260:	0ad76e63          	bltu	a4,a3,8000431c <filewrite+0x11e>
    80004264:	0792                	slli	a5,a5,0x4
    80004266:	0001e717          	auipc	a4,0x1e
    8000426a:	0da70713          	addi	a4,a4,218 # 80022340 <devsw>
    8000426e:	97ba                	add	a5,a5,a4
    80004270:	679c                	ld	a5,8(a5)
    80004272:	c7dd                	beqz	a5,80004320 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    80004274:	4505                	li	a0,1
    80004276:	9782                	jalr	a5
    80004278:	a8b5                	j	800042f4 <filewrite+0xf6>
      if(n1 > max)
    8000427a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000427e:	997ff0ef          	jal	80003c14 <begin_op>
      ilock(f->ip);
    80004282:	01893503          	ld	a0,24(s2)
    80004286:	fa5fe0ef          	jal	8000322a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000428a:	8756                	mv	a4,s5
    8000428c:	02092683          	lw	a3,32(s2)
    80004290:	01698633          	add	a2,s3,s6
    80004294:	4585                	li	a1,1
    80004296:	01893503          	ld	a0,24(s2)
    8000429a:	c1cff0ef          	jal	800036b6 <writei>
    8000429e:	84aa                	mv	s1,a0
    800042a0:	00a05763          	blez	a0,800042ae <filewrite+0xb0>
        f->off += r;
    800042a4:	02092783          	lw	a5,32(s2)
    800042a8:	9fa9                	addw	a5,a5,a0
    800042aa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800042ae:	01893503          	ld	a0,24(s2)
    800042b2:	826ff0ef          	jal	800032d8 <iunlock>
      end_op();
    800042b6:	9c9ff0ef          	jal	80003c7e <end_op>

      if(r != n1){
    800042ba:	029a9563          	bne	s5,s1,800042e4 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    800042be:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800042c2:	0149da63          	bge	s3,s4,800042d6 <filewrite+0xd8>
      int n1 = n - i;
    800042c6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800042ca:	0004879b          	sext.w	a5,s1
    800042ce:	fafbd6e3          	bge	s7,a5,8000427a <filewrite+0x7c>
    800042d2:	84e2                	mv	s1,s8
    800042d4:	b75d                	j	8000427a <filewrite+0x7c>
    800042d6:	74e2                	ld	s1,56(sp)
    800042d8:	6ae2                	ld	s5,24(sp)
    800042da:	6ba2                	ld	s7,8(sp)
    800042dc:	6c02                	ld	s8,0(sp)
    800042de:	a039                	j	800042ec <filewrite+0xee>
    int i = 0;
    800042e0:	4981                	li	s3,0
    800042e2:	a029                	j	800042ec <filewrite+0xee>
    800042e4:	74e2                	ld	s1,56(sp)
    800042e6:	6ae2                	ld	s5,24(sp)
    800042e8:	6ba2                	ld	s7,8(sp)
    800042ea:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800042ec:	033a1c63          	bne	s4,s3,80004324 <filewrite+0x126>
    800042f0:	8552                	mv	a0,s4
    800042f2:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800042f4:	60a6                	ld	ra,72(sp)
    800042f6:	6406                	ld	s0,64(sp)
    800042f8:	7942                	ld	s2,48(sp)
    800042fa:	7a02                	ld	s4,32(sp)
    800042fc:	6b42                	ld	s6,16(sp)
    800042fe:	6161                	addi	sp,sp,80
    80004300:	8082                	ret
    80004302:	fc26                	sd	s1,56(sp)
    80004304:	f44e                	sd	s3,40(sp)
    80004306:	ec56                	sd	s5,24(sp)
    80004308:	e45e                	sd	s7,8(sp)
    8000430a:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000430c:	00003517          	auipc	a0,0x3
    80004310:	27c50513          	addi	a0,a0,636 # 80007588 <etext+0x588>
    80004314:	cccfc0ef          	jal	800007e0 <panic>
    return -1;
    80004318:	557d                	li	a0,-1
}
    8000431a:	8082                	ret
      return -1;
    8000431c:	557d                	li	a0,-1
    8000431e:	bfd9                	j	800042f4 <filewrite+0xf6>
    80004320:	557d                	li	a0,-1
    80004322:	bfc9                	j	800042f4 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004324:	557d                	li	a0,-1
    80004326:	79a2                	ld	s3,40(sp)
    80004328:	b7f1                	j	800042f4 <filewrite+0xf6>

000000008000432a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000432a:	7179                	addi	sp,sp,-48
    8000432c:	f406                	sd	ra,40(sp)
    8000432e:	f022                	sd	s0,32(sp)
    80004330:	ec26                	sd	s1,24(sp)
    80004332:	e052                	sd	s4,0(sp)
    80004334:	1800                	addi	s0,sp,48
    80004336:	84aa                	mv	s1,a0
    80004338:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000433a:	0005b023          	sd	zero,0(a1)
    8000433e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004342:	c3bff0ef          	jal	80003f7c <filealloc>
    80004346:	e088                	sd	a0,0(s1)
    80004348:	c549                	beqz	a0,800043d2 <pipealloc+0xa8>
    8000434a:	c33ff0ef          	jal	80003f7c <filealloc>
    8000434e:	00aa3023          	sd	a0,0(s4)
    80004352:	cd25                	beqz	a0,800043ca <pipealloc+0xa0>
    80004354:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004356:	fe4fc0ef          	jal	80000b3a <kalloc>
    8000435a:	892a                	mv	s2,a0
    8000435c:	c12d                	beqz	a0,800043be <pipealloc+0x94>
    8000435e:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004360:	4985                	li	s3,1
    80004362:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004366:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000436a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000436e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004372:	00003597          	auipc	a1,0x3
    80004376:	22658593          	addi	a1,a1,550 # 80007598 <etext+0x598>
    8000437a:	81dfc0ef          	jal	80000b96 <initlock>
  (*f0)->type = FD_PIPE;
    8000437e:	609c                	ld	a5,0(s1)
    80004380:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004384:	609c                	ld	a5,0(s1)
    80004386:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000438a:	609c                	ld	a5,0(s1)
    8000438c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004390:	609c                	ld	a5,0(s1)
    80004392:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004396:	000a3783          	ld	a5,0(s4)
    8000439a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000439e:	000a3783          	ld	a5,0(s4)
    800043a2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800043a6:	000a3783          	ld	a5,0(s4)
    800043aa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800043ae:	000a3783          	ld	a5,0(s4)
    800043b2:	0127b823          	sd	s2,16(a5)
  return 0;
    800043b6:	4501                	li	a0,0
    800043b8:	6942                	ld	s2,16(sp)
    800043ba:	69a2                	ld	s3,8(sp)
    800043bc:	a01d                	j	800043e2 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800043be:	6088                	ld	a0,0(s1)
    800043c0:	c119                	beqz	a0,800043c6 <pipealloc+0x9c>
    800043c2:	6942                	ld	s2,16(sp)
    800043c4:	a029                	j	800043ce <pipealloc+0xa4>
    800043c6:	6942                	ld	s2,16(sp)
    800043c8:	a029                	j	800043d2 <pipealloc+0xa8>
    800043ca:	6088                	ld	a0,0(s1)
    800043cc:	c10d                	beqz	a0,800043ee <pipealloc+0xc4>
    fileclose(*f0);
    800043ce:	c53ff0ef          	jal	80004020 <fileclose>
  if(*f1)
    800043d2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800043d6:	557d                	li	a0,-1
  if(*f1)
    800043d8:	c789                	beqz	a5,800043e2 <pipealloc+0xb8>
    fileclose(*f1);
    800043da:	853e                	mv	a0,a5
    800043dc:	c45ff0ef          	jal	80004020 <fileclose>
  return -1;
    800043e0:	557d                	li	a0,-1
}
    800043e2:	70a2                	ld	ra,40(sp)
    800043e4:	7402                	ld	s0,32(sp)
    800043e6:	64e2                	ld	s1,24(sp)
    800043e8:	6a02                	ld	s4,0(sp)
    800043ea:	6145                	addi	sp,sp,48
    800043ec:	8082                	ret
  return -1;
    800043ee:	557d                	li	a0,-1
    800043f0:	bfcd                	j	800043e2 <pipealloc+0xb8>

00000000800043f2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800043f2:	1101                	addi	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	e04a                	sd	s2,0(sp)
    800043fc:	1000                	addi	s0,sp,32
    800043fe:	84aa                	mv	s1,a0
    80004400:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004402:	815fc0ef          	jal	80000c16 <acquire>
  if(writable){
    80004406:	02090763          	beqz	s2,80004434 <pipeclose+0x42>
    pi->writeopen = 0;
    8000440a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000440e:	21848513          	addi	a0,s1,536
    80004412:	b5bfd0ef          	jal	80001f6c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004416:	2204b783          	ld	a5,544(s1)
    8000441a:	e785                	bnez	a5,80004442 <pipeclose+0x50>
    release(&pi->lock);
    8000441c:	8526                	mv	a0,s1
    8000441e:	891fc0ef          	jal	80000cae <release>
    kfree((char*)pi);
    80004422:	8526                	mv	a0,s1
    80004424:	df8fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004428:	60e2                	ld	ra,24(sp)
    8000442a:	6442                	ld	s0,16(sp)
    8000442c:	64a2                	ld	s1,8(sp)
    8000442e:	6902                	ld	s2,0(sp)
    80004430:	6105                	addi	sp,sp,32
    80004432:	8082                	ret
    pi->readopen = 0;
    80004434:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004438:	21c48513          	addi	a0,s1,540
    8000443c:	b31fd0ef          	jal	80001f6c <wakeup>
    80004440:	bfd9                	j	80004416 <pipeclose+0x24>
    release(&pi->lock);
    80004442:	8526                	mv	a0,s1
    80004444:	86bfc0ef          	jal	80000cae <release>
}
    80004448:	b7c5                	j	80004428 <pipeclose+0x36>

000000008000444a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000444a:	711d                	addi	sp,sp,-96
    8000444c:	ec86                	sd	ra,88(sp)
    8000444e:	e8a2                	sd	s0,80(sp)
    80004450:	e4a6                	sd	s1,72(sp)
    80004452:	e0ca                	sd	s2,64(sp)
    80004454:	fc4e                	sd	s3,56(sp)
    80004456:	f852                	sd	s4,48(sp)
    80004458:	f456                	sd	s5,40(sp)
    8000445a:	1080                	addi	s0,sp,96
    8000445c:	84aa                	mv	s1,a0
    8000445e:	8aae                	mv	s5,a1
    80004460:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004462:	cb4fd0ef          	jal	80001916 <myproc>
    80004466:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004468:	8526                	mv	a0,s1
    8000446a:	facfc0ef          	jal	80000c16 <acquire>
  while(i < n){
    8000446e:	0b405a63          	blez	s4,80004522 <pipewrite+0xd8>
    80004472:	f05a                	sd	s6,32(sp)
    80004474:	ec5e                	sd	s7,24(sp)
    80004476:	e862                	sd	s8,16(sp)
  int i = 0;
    80004478:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000447a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000447c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004480:	21c48b93          	addi	s7,s1,540
    80004484:	a81d                	j	800044ba <pipewrite+0x70>
      release(&pi->lock);
    80004486:	8526                	mv	a0,s1
    80004488:	827fc0ef          	jal	80000cae <release>
      return -1;
    8000448c:	597d                	li	s2,-1
    8000448e:	7b02                	ld	s6,32(sp)
    80004490:	6be2                	ld	s7,24(sp)
    80004492:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004494:	854a                	mv	a0,s2
    80004496:	60e6                	ld	ra,88(sp)
    80004498:	6446                	ld	s0,80(sp)
    8000449a:	64a6                	ld	s1,72(sp)
    8000449c:	6906                	ld	s2,64(sp)
    8000449e:	79e2                	ld	s3,56(sp)
    800044a0:	7a42                	ld	s4,48(sp)
    800044a2:	7aa2                	ld	s5,40(sp)
    800044a4:	6125                	addi	sp,sp,96
    800044a6:	8082                	ret
      wakeup(&pi->nread);
    800044a8:	8562                	mv	a0,s8
    800044aa:	ac3fd0ef          	jal	80001f6c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800044ae:	85a6                	mv	a1,s1
    800044b0:	855e                	mv	a0,s7
    800044b2:	a6ffd0ef          	jal	80001f20 <sleep>
  while(i < n){
    800044b6:	05495b63          	bge	s2,s4,8000450c <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    800044ba:	2204a783          	lw	a5,544(s1)
    800044be:	d7e1                	beqz	a5,80004486 <pipewrite+0x3c>
    800044c0:	854e                	mv	a0,s3
    800044c2:	c97fd0ef          	jal	80002158 <killed>
    800044c6:	f161                	bnez	a0,80004486 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800044c8:	2184a783          	lw	a5,536(s1)
    800044cc:	21c4a703          	lw	a4,540(s1)
    800044d0:	2007879b          	addiw	a5,a5,512
    800044d4:	fcf70ae3          	beq	a4,a5,800044a8 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800044d8:	4685                	li	a3,1
    800044da:	01590633          	add	a2,s2,s5
    800044de:	faf40593          	addi	a1,s0,-81
    800044e2:	0509b503          	ld	a0,80(s3)
    800044e6:	a28fd0ef          	jal	8000170e <copyin>
    800044ea:	03650e63          	beq	a0,s6,80004526 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800044ee:	21c4a783          	lw	a5,540(s1)
    800044f2:	0017871b          	addiw	a4,a5,1
    800044f6:	20e4ae23          	sw	a4,540(s1)
    800044fa:	1ff7f793          	andi	a5,a5,511
    800044fe:	97a6                	add	a5,a5,s1
    80004500:	faf44703          	lbu	a4,-81(s0)
    80004504:	00e78c23          	sb	a4,24(a5)
      i++;
    80004508:	2905                	addiw	s2,s2,1
    8000450a:	b775                	j	800044b6 <pipewrite+0x6c>
    8000450c:	7b02                	ld	s6,32(sp)
    8000450e:	6be2                	ld	s7,24(sp)
    80004510:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004512:	21848513          	addi	a0,s1,536
    80004516:	a57fd0ef          	jal	80001f6c <wakeup>
  release(&pi->lock);
    8000451a:	8526                	mv	a0,s1
    8000451c:	f92fc0ef          	jal	80000cae <release>
  return i;
    80004520:	bf95                	j	80004494 <pipewrite+0x4a>
  int i = 0;
    80004522:	4901                	li	s2,0
    80004524:	b7fd                	j	80004512 <pipewrite+0xc8>
    80004526:	7b02                	ld	s6,32(sp)
    80004528:	6be2                	ld	s7,24(sp)
    8000452a:	6c42                	ld	s8,16(sp)
    8000452c:	b7dd                	j	80004512 <pipewrite+0xc8>

000000008000452e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000452e:	715d                	addi	sp,sp,-80
    80004530:	e486                	sd	ra,72(sp)
    80004532:	e0a2                	sd	s0,64(sp)
    80004534:	fc26                	sd	s1,56(sp)
    80004536:	f84a                	sd	s2,48(sp)
    80004538:	f44e                	sd	s3,40(sp)
    8000453a:	f052                	sd	s4,32(sp)
    8000453c:	ec56                	sd	s5,24(sp)
    8000453e:	0880                	addi	s0,sp,80
    80004540:	84aa                	mv	s1,a0
    80004542:	892e                	mv	s2,a1
    80004544:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004546:	bd0fd0ef          	jal	80001916 <myproc>
    8000454a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000454c:	8526                	mv	a0,s1
    8000454e:	ec8fc0ef          	jal	80000c16 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004552:	2184a703          	lw	a4,536(s1)
    80004556:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000455a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000455e:	02f71563          	bne	a4,a5,80004588 <piperead+0x5a>
    80004562:	2244a783          	lw	a5,548(s1)
    80004566:	cb85                	beqz	a5,80004596 <piperead+0x68>
    if(killed(pr)){
    80004568:	8552                	mv	a0,s4
    8000456a:	beffd0ef          	jal	80002158 <killed>
    8000456e:	ed19                	bnez	a0,8000458c <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004570:	85a6                	mv	a1,s1
    80004572:	854e                	mv	a0,s3
    80004574:	9adfd0ef          	jal	80001f20 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004578:	2184a703          	lw	a4,536(s1)
    8000457c:	21c4a783          	lw	a5,540(s1)
    80004580:	fef701e3          	beq	a4,a5,80004562 <piperead+0x34>
    80004584:	e85a                	sd	s6,16(sp)
    80004586:	a809                	j	80004598 <piperead+0x6a>
    80004588:	e85a                	sd	s6,16(sp)
    8000458a:	a039                	j	80004598 <piperead+0x6a>
      release(&pi->lock);
    8000458c:	8526                	mv	a0,s1
    8000458e:	f20fc0ef          	jal	80000cae <release>
      return -1;
    80004592:	59fd                	li	s3,-1
    80004594:	a8b9                	j	800045f2 <piperead+0xc4>
    80004596:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004598:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000459a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000459c:	05505363          	blez	s5,800045e2 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800045a0:	2184a783          	lw	a5,536(s1)
    800045a4:	21c4a703          	lw	a4,540(s1)
    800045a8:	02f70d63          	beq	a4,a5,800045e2 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    800045ac:	1ff7f793          	andi	a5,a5,511
    800045b0:	97a6                	add	a5,a5,s1
    800045b2:	0187c783          	lbu	a5,24(a5)
    800045b6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800045ba:	4685                	li	a3,1
    800045bc:	fbf40613          	addi	a2,s0,-65
    800045c0:	85ca                	mv	a1,s2
    800045c2:	050a3503          	ld	a0,80(s4)
    800045c6:	864fd0ef          	jal	8000162a <copyout>
    800045ca:	03650e63          	beq	a0,s6,80004606 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800045ce:	2184a783          	lw	a5,536(s1)
    800045d2:	2785                	addiw	a5,a5,1
    800045d4:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800045d8:	2985                	addiw	s3,s3,1
    800045da:	0905                	addi	s2,s2,1
    800045dc:	fd3a92e3          	bne	s5,s3,800045a0 <piperead+0x72>
    800045e0:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800045e2:	21c48513          	addi	a0,s1,540
    800045e6:	987fd0ef          	jal	80001f6c <wakeup>
  release(&pi->lock);
    800045ea:	8526                	mv	a0,s1
    800045ec:	ec2fc0ef          	jal	80000cae <release>
    800045f0:	6b42                	ld	s6,16(sp)
  return i;
}
    800045f2:	854e                	mv	a0,s3
    800045f4:	60a6                	ld	ra,72(sp)
    800045f6:	6406                	ld	s0,64(sp)
    800045f8:	74e2                	ld	s1,56(sp)
    800045fa:	7942                	ld	s2,48(sp)
    800045fc:	79a2                	ld	s3,40(sp)
    800045fe:	7a02                	ld	s4,32(sp)
    80004600:	6ae2                	ld	s5,24(sp)
    80004602:	6161                	addi	sp,sp,80
    80004604:	8082                	ret
      if(i == 0)
    80004606:	fc099ee3          	bnez	s3,800045e2 <piperead+0xb4>
        i = -1;
    8000460a:	89aa                	mv	s3,a0
    8000460c:	bfd9                	j	800045e2 <piperead+0xb4>

000000008000460e <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000460e:	1141                	addi	sp,sp,-16
    80004610:	e422                	sd	s0,8(sp)
    80004612:	0800                	addi	s0,sp,16
    80004614:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004616:	8905                	andi	a0,a0,1
    80004618:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000461a:	8b89                	andi	a5,a5,2
    8000461c:	c399                	beqz	a5,80004622 <flags2perm+0x14>
      perm |= PTE_W;
    8000461e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004622:	6422                	ld	s0,8(sp)
    80004624:	0141                	addi	sp,sp,16
    80004626:	8082                	ret

0000000080004628 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004628:	df010113          	addi	sp,sp,-528
    8000462c:	20113423          	sd	ra,520(sp)
    80004630:	20813023          	sd	s0,512(sp)
    80004634:	ffa6                	sd	s1,504(sp)
    80004636:	fbca                	sd	s2,496(sp)
    80004638:	0c00                	addi	s0,sp,528
    8000463a:	892a                	mv	s2,a0
    8000463c:	dea43c23          	sd	a0,-520(s0)
    80004640:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004644:	ad2fd0ef          	jal	80001916 <myproc>
    80004648:	84aa                	mv	s1,a0

  begin_op();
    8000464a:	dcaff0ef          	jal	80003c14 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    8000464e:	854a                	mv	a0,s2
    80004650:	bf0ff0ef          	jal	80003a40 <namei>
    80004654:	c931                	beqz	a0,800046a8 <kexec+0x80>
    80004656:	f3d2                	sd	s4,480(sp)
    80004658:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000465a:	bd1fe0ef          	jal	8000322a <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000465e:	04000713          	li	a4,64
    80004662:	4681                	li	a3,0
    80004664:	e5040613          	addi	a2,s0,-432
    80004668:	4581                	li	a1,0
    8000466a:	8552                	mv	a0,s4
    8000466c:	f4ffe0ef          	jal	800035ba <readi>
    80004670:	04000793          	li	a5,64
    80004674:	00f51a63          	bne	a0,a5,80004688 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004678:	e5042703          	lw	a4,-432(s0)
    8000467c:	464c47b7          	lui	a5,0x464c4
    80004680:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004684:	02f70663          	beq	a4,a5,800046b0 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004688:	8552                	mv	a0,s4
    8000468a:	dabfe0ef          	jal	80003434 <iunlockput>
    end_op();
    8000468e:	df0ff0ef          	jal	80003c7e <end_op>
  }
  return -1;
    80004692:	557d                	li	a0,-1
    80004694:	7a1e                	ld	s4,480(sp)
}
    80004696:	20813083          	ld	ra,520(sp)
    8000469a:	20013403          	ld	s0,512(sp)
    8000469e:	74fe                	ld	s1,504(sp)
    800046a0:	795e                	ld	s2,496(sp)
    800046a2:	21010113          	addi	sp,sp,528
    800046a6:	8082                	ret
    end_op();
    800046a8:	dd6ff0ef          	jal	80003c7e <end_op>
    return -1;
    800046ac:	557d                	li	a0,-1
    800046ae:	b7e5                	j	80004696 <kexec+0x6e>
    800046b0:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800046b2:	8526                	mv	a0,s1
    800046b4:	b68fd0ef          	jal	80001a1c <proc_pagetable>
    800046b8:	8b2a                	mv	s6,a0
    800046ba:	2c050b63          	beqz	a0,80004990 <kexec+0x368>
    800046be:	f7ce                	sd	s3,488(sp)
    800046c0:	efd6                	sd	s5,472(sp)
    800046c2:	e7de                	sd	s7,456(sp)
    800046c4:	e3e2                	sd	s8,448(sp)
    800046c6:	ff66                	sd	s9,440(sp)
    800046c8:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800046ca:	e7042d03          	lw	s10,-400(s0)
    800046ce:	e8845783          	lhu	a5,-376(s0)
    800046d2:	12078963          	beqz	a5,80004804 <kexec+0x1dc>
    800046d6:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800046d8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800046da:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800046dc:	6c85                	lui	s9,0x1
    800046de:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800046e2:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800046e6:	6a85                	lui	s5,0x1
    800046e8:	a085                	j	80004748 <kexec+0x120>
      panic("loadseg: address should exist");
    800046ea:	00003517          	auipc	a0,0x3
    800046ee:	eb650513          	addi	a0,a0,-330 # 800075a0 <etext+0x5a0>
    800046f2:	8eefc0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    800046f6:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800046f8:	8726                	mv	a4,s1
    800046fa:	012c06bb          	addw	a3,s8,s2
    800046fe:	4581                	li	a1,0
    80004700:	8552                	mv	a0,s4
    80004702:	eb9fe0ef          	jal	800035ba <readi>
    80004706:	2501                	sext.w	a0,a0
    80004708:	24a49a63          	bne	s1,a0,8000495c <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    8000470c:	012a893b          	addw	s2,s5,s2
    80004710:	03397363          	bgeu	s2,s3,80004736 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004714:	02091593          	slli	a1,s2,0x20
    80004718:	9181                	srli	a1,a1,0x20
    8000471a:	95de                	add	a1,a1,s7
    8000471c:	855a                	mv	a0,s6
    8000471e:	8dbfc0ef          	jal	80000ff8 <walkaddr>
    80004722:	862a                	mv	a2,a0
    if(pa == 0)
    80004724:	d179                	beqz	a0,800046ea <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004726:	412984bb          	subw	s1,s3,s2
    8000472a:	0004879b          	sext.w	a5,s1
    8000472e:	fcfcf4e3          	bgeu	s9,a5,800046f6 <kexec+0xce>
    80004732:	84d6                	mv	s1,s5
    80004734:	b7c9                	j	800046f6 <kexec+0xce>
    sz = sz1;
    80004736:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000473a:	2d85                	addiw	s11,s11,1
    8000473c:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004740:	e8845783          	lhu	a5,-376(s0)
    80004744:	08fdd063          	bge	s11,a5,800047c4 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004748:	2d01                	sext.w	s10,s10
    8000474a:	03800713          	li	a4,56
    8000474e:	86ea                	mv	a3,s10
    80004750:	e1840613          	addi	a2,s0,-488
    80004754:	4581                	li	a1,0
    80004756:	8552                	mv	a0,s4
    80004758:	e63fe0ef          	jal	800035ba <readi>
    8000475c:	03800793          	li	a5,56
    80004760:	1cf51663          	bne	a0,a5,8000492c <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004764:	e1842783          	lw	a5,-488(s0)
    80004768:	4705                	li	a4,1
    8000476a:	fce798e3          	bne	a5,a4,8000473a <kexec+0x112>
    if(ph.memsz < ph.filesz)
    8000476e:	e4043483          	ld	s1,-448(s0)
    80004772:	e3843783          	ld	a5,-456(s0)
    80004776:	1af4ef63          	bltu	s1,a5,80004934 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000477a:	e2843783          	ld	a5,-472(s0)
    8000477e:	94be                	add	s1,s1,a5
    80004780:	1af4ee63          	bltu	s1,a5,8000493c <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004784:	df043703          	ld	a4,-528(s0)
    80004788:	8ff9                	and	a5,a5,a4
    8000478a:	1a079d63          	bnez	a5,80004944 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000478e:	e1c42503          	lw	a0,-484(s0)
    80004792:	e7dff0ef          	jal	8000460e <flags2perm>
    80004796:	86aa                	mv	a3,a0
    80004798:	8626                	mv	a2,s1
    8000479a:	85ca                	mv	a1,s2
    8000479c:	855a                	mv	a0,s6
    8000479e:	b33fc0ef          	jal	800012d0 <uvmalloc>
    800047a2:	e0a43423          	sd	a0,-504(s0)
    800047a6:	1a050363          	beqz	a0,8000494c <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800047aa:	e2843b83          	ld	s7,-472(s0)
    800047ae:	e2042c03          	lw	s8,-480(s0)
    800047b2:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800047b6:	00098463          	beqz	s3,800047be <kexec+0x196>
    800047ba:	4901                	li	s2,0
    800047bc:	bfa1                	j	80004714 <kexec+0xec>
    sz = sz1;
    800047be:	e0843903          	ld	s2,-504(s0)
    800047c2:	bfa5                	j	8000473a <kexec+0x112>
    800047c4:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800047c6:	8552                	mv	a0,s4
    800047c8:	c6dfe0ef          	jal	80003434 <iunlockput>
  end_op();
    800047cc:	cb2ff0ef          	jal	80003c7e <end_op>
  p = myproc();
    800047d0:	946fd0ef          	jal	80001916 <myproc>
    800047d4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800047d6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800047da:	6985                	lui	s3,0x1
    800047dc:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800047de:	99ca                	add	s3,s3,s2
    800047e0:	77fd                	lui	a5,0xfffff
    800047e2:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800047e6:	4691                	li	a3,4
    800047e8:	6609                	lui	a2,0x2
    800047ea:	964e                	add	a2,a2,s3
    800047ec:	85ce                	mv	a1,s3
    800047ee:	855a                	mv	a0,s6
    800047f0:	ae1fc0ef          	jal	800012d0 <uvmalloc>
    800047f4:	892a                	mv	s2,a0
    800047f6:	e0a43423          	sd	a0,-504(s0)
    800047fa:	e519                	bnez	a0,80004808 <kexec+0x1e0>
  if(pagetable)
    800047fc:	e1343423          	sd	s3,-504(s0)
    80004800:	4a01                	li	s4,0
    80004802:	aab1                	j	8000495e <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004804:	4901                	li	s2,0
    80004806:	b7c1                	j	800047c6 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004808:	75f9                	lui	a1,0xffffe
    8000480a:	95aa                	add	a1,a1,a0
    8000480c:	855a                	mv	a0,s6
    8000480e:	c99fc0ef          	jal	800014a6 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004812:	7bfd                	lui	s7,0xfffff
    80004814:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004816:	e0043783          	ld	a5,-512(s0)
    8000481a:	6388                	ld	a0,0(a5)
    8000481c:	cd39                	beqz	a0,8000487a <kexec+0x252>
    8000481e:	e9040993          	addi	s3,s0,-368
    80004822:	f9040c13          	addi	s8,s0,-112
    80004826:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004828:	e32fc0ef          	jal	80000e5a <strlen>
    8000482c:	0015079b          	addiw	a5,a0,1
    80004830:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004834:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004838:	11796e63          	bltu	s2,s7,80004954 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000483c:	e0043d03          	ld	s10,-512(s0)
    80004840:	000d3a03          	ld	s4,0(s10)
    80004844:	8552                	mv	a0,s4
    80004846:	e14fc0ef          	jal	80000e5a <strlen>
    8000484a:	0015069b          	addiw	a3,a0,1
    8000484e:	8652                	mv	a2,s4
    80004850:	85ca                	mv	a1,s2
    80004852:	855a                	mv	a0,s6
    80004854:	dd7fc0ef          	jal	8000162a <copyout>
    80004858:	10054063          	bltz	a0,80004958 <kexec+0x330>
    ustack[argc] = sp;
    8000485c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004860:	0485                	addi	s1,s1,1
    80004862:	008d0793          	addi	a5,s10,8
    80004866:	e0f43023          	sd	a5,-512(s0)
    8000486a:	008d3503          	ld	a0,8(s10)
    8000486e:	c909                	beqz	a0,80004880 <kexec+0x258>
    if(argc >= MAXARG)
    80004870:	09a1                	addi	s3,s3,8
    80004872:	fb899be3          	bne	s3,s8,80004828 <kexec+0x200>
  ip = 0;
    80004876:	4a01                	li	s4,0
    80004878:	a0dd                	j	8000495e <kexec+0x336>
  sp = sz;
    8000487a:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000487e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004880:	00349793          	slli	a5,s1,0x3
    80004884:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdbab8>
    80004888:	97a2                	add	a5,a5,s0
    8000488a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000488e:	00148693          	addi	a3,s1,1
    80004892:	068e                	slli	a3,a3,0x3
    80004894:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004898:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000489c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800048a0:	f5796ee3          	bltu	s2,s7,800047fc <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800048a4:	e9040613          	addi	a2,s0,-368
    800048a8:	85ca                	mv	a1,s2
    800048aa:	855a                	mv	a0,s6
    800048ac:	d7ffc0ef          	jal	8000162a <copyout>
    800048b0:	0e054263          	bltz	a0,80004994 <kexec+0x36c>
  p->trapframe->a1 = sp;
    800048b4:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800048b8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800048bc:	df843783          	ld	a5,-520(s0)
    800048c0:	0007c703          	lbu	a4,0(a5)
    800048c4:	cf11                	beqz	a4,800048e0 <kexec+0x2b8>
    800048c6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800048c8:	02f00693          	li	a3,47
    800048cc:	a039                	j	800048da <kexec+0x2b2>
      last = s+1;
    800048ce:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800048d2:	0785                	addi	a5,a5,1
    800048d4:	fff7c703          	lbu	a4,-1(a5)
    800048d8:	c701                	beqz	a4,800048e0 <kexec+0x2b8>
    if(*s == '/')
    800048da:	fed71ce3          	bne	a4,a3,800048d2 <kexec+0x2aa>
    800048de:	bfc5                	j	800048ce <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    800048e0:	4641                	li	a2,16
    800048e2:	df843583          	ld	a1,-520(s0)
    800048e6:	158a8513          	addi	a0,s5,344
    800048ea:	d3efc0ef          	jal	80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    800048ee:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800048f2:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800048f6:	e0843783          	ld	a5,-504(s0)
    800048fa:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800048fe:	058ab783          	ld	a5,88(s5)
    80004902:	e6843703          	ld	a4,-408(s0)
    80004906:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004908:	058ab783          	ld	a5,88(s5)
    8000490c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004910:	85e6                	mv	a1,s9
    80004912:	98efd0ef          	jal	80001aa0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004916:	0004851b          	sext.w	a0,s1
    8000491a:	79be                	ld	s3,488(sp)
    8000491c:	7a1e                	ld	s4,480(sp)
    8000491e:	6afe                	ld	s5,472(sp)
    80004920:	6b5e                	ld	s6,464(sp)
    80004922:	6bbe                	ld	s7,456(sp)
    80004924:	6c1e                	ld	s8,448(sp)
    80004926:	7cfa                	ld	s9,440(sp)
    80004928:	7d5a                	ld	s10,432(sp)
    8000492a:	b3b5                	j	80004696 <kexec+0x6e>
    8000492c:	e1243423          	sd	s2,-504(s0)
    80004930:	7dba                	ld	s11,424(sp)
    80004932:	a035                	j	8000495e <kexec+0x336>
    80004934:	e1243423          	sd	s2,-504(s0)
    80004938:	7dba                	ld	s11,424(sp)
    8000493a:	a015                	j	8000495e <kexec+0x336>
    8000493c:	e1243423          	sd	s2,-504(s0)
    80004940:	7dba                	ld	s11,424(sp)
    80004942:	a831                	j	8000495e <kexec+0x336>
    80004944:	e1243423          	sd	s2,-504(s0)
    80004948:	7dba                	ld	s11,424(sp)
    8000494a:	a811                	j	8000495e <kexec+0x336>
    8000494c:	e1243423          	sd	s2,-504(s0)
    80004950:	7dba                	ld	s11,424(sp)
    80004952:	a031                	j	8000495e <kexec+0x336>
  ip = 0;
    80004954:	4a01                	li	s4,0
    80004956:	a021                	j	8000495e <kexec+0x336>
    80004958:	4a01                	li	s4,0
  if(pagetable)
    8000495a:	a011                	j	8000495e <kexec+0x336>
    8000495c:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    8000495e:	e0843583          	ld	a1,-504(s0)
    80004962:	855a                	mv	a0,s6
    80004964:	93cfd0ef          	jal	80001aa0 <proc_freepagetable>
  return -1;
    80004968:	557d                	li	a0,-1
  if(ip){
    8000496a:	000a1b63          	bnez	s4,80004980 <kexec+0x358>
    8000496e:	79be                	ld	s3,488(sp)
    80004970:	7a1e                	ld	s4,480(sp)
    80004972:	6afe                	ld	s5,472(sp)
    80004974:	6b5e                	ld	s6,464(sp)
    80004976:	6bbe                	ld	s7,456(sp)
    80004978:	6c1e                	ld	s8,448(sp)
    8000497a:	7cfa                	ld	s9,440(sp)
    8000497c:	7d5a                	ld	s10,432(sp)
    8000497e:	bb21                	j	80004696 <kexec+0x6e>
    80004980:	79be                	ld	s3,488(sp)
    80004982:	6afe                	ld	s5,472(sp)
    80004984:	6b5e                	ld	s6,464(sp)
    80004986:	6bbe                	ld	s7,456(sp)
    80004988:	6c1e                	ld	s8,448(sp)
    8000498a:	7cfa                	ld	s9,440(sp)
    8000498c:	7d5a                	ld	s10,432(sp)
    8000498e:	b9ed                	j	80004688 <kexec+0x60>
    80004990:	6b5e                	ld	s6,464(sp)
    80004992:	b9dd                	j	80004688 <kexec+0x60>
  sz = sz1;
    80004994:	e0843983          	ld	s3,-504(s0)
    80004998:	b595                	j	800047fc <kexec+0x1d4>

000000008000499a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000499a:	7179                	addi	sp,sp,-48
    8000499c:	f406                	sd	ra,40(sp)
    8000499e:	f022                	sd	s0,32(sp)
    800049a0:	ec26                	sd	s1,24(sp)
    800049a2:	e84a                	sd	s2,16(sp)
    800049a4:	1800                	addi	s0,sp,48
    800049a6:	892e                	mv	s2,a1
    800049a8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800049aa:	fdc40593          	addi	a1,s0,-36
    800049ae:	e77fd0ef          	jal	80002824 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800049b2:	fdc42703          	lw	a4,-36(s0)
    800049b6:	47bd                	li	a5,15
    800049b8:	02e7e963          	bltu	a5,a4,800049ea <argfd+0x50>
    800049bc:	f5bfc0ef          	jal	80001916 <myproc>
    800049c0:	fdc42703          	lw	a4,-36(s0)
    800049c4:	01a70793          	addi	a5,a4,26
    800049c8:	078e                	slli	a5,a5,0x3
    800049ca:	953e                	add	a0,a0,a5
    800049cc:	611c                	ld	a5,0(a0)
    800049ce:	c385                	beqz	a5,800049ee <argfd+0x54>
    return -1;
  if(pfd)
    800049d0:	00090463          	beqz	s2,800049d8 <argfd+0x3e>
    *pfd = fd;
    800049d4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800049d8:	4501                	li	a0,0
  if(pf)
    800049da:	c091                	beqz	s1,800049de <argfd+0x44>
    *pf = f;
    800049dc:	e09c                	sd	a5,0(s1)
}
    800049de:	70a2                	ld	ra,40(sp)
    800049e0:	7402                	ld	s0,32(sp)
    800049e2:	64e2                	ld	s1,24(sp)
    800049e4:	6942                	ld	s2,16(sp)
    800049e6:	6145                	addi	sp,sp,48
    800049e8:	8082                	ret
    return -1;
    800049ea:	557d                	li	a0,-1
    800049ec:	bfcd                	j	800049de <argfd+0x44>
    800049ee:	557d                	li	a0,-1
    800049f0:	b7fd                	j	800049de <argfd+0x44>

00000000800049f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800049f2:	1101                	addi	sp,sp,-32
    800049f4:	ec06                	sd	ra,24(sp)
    800049f6:	e822                	sd	s0,16(sp)
    800049f8:	e426                	sd	s1,8(sp)
    800049fa:	1000                	addi	s0,sp,32
    800049fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800049fe:	f19fc0ef          	jal	80001916 <myproc>
    80004a02:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004a04:	0d050793          	addi	a5,a0,208
    80004a08:	4501                	li	a0,0
    80004a0a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004a0c:	6398                	ld	a4,0(a5)
    80004a0e:	cb19                	beqz	a4,80004a24 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004a10:	2505                	addiw	a0,a0,1
    80004a12:	07a1                	addi	a5,a5,8
    80004a14:	fed51ce3          	bne	a0,a3,80004a0c <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004a18:	557d                	li	a0,-1
}
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6105                	addi	sp,sp,32
    80004a22:	8082                	ret
      p->ofile[fd] = f;
    80004a24:	01a50793          	addi	a5,a0,26
    80004a28:	078e                	slli	a5,a5,0x3
    80004a2a:	963e                	add	a2,a2,a5
    80004a2c:	e204                	sd	s1,0(a2)
      return fd;
    80004a2e:	b7f5                	j	80004a1a <fdalloc+0x28>

0000000080004a30 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004a30:	715d                	addi	sp,sp,-80
    80004a32:	e486                	sd	ra,72(sp)
    80004a34:	e0a2                	sd	s0,64(sp)
    80004a36:	fc26                	sd	s1,56(sp)
    80004a38:	f84a                	sd	s2,48(sp)
    80004a3a:	f44e                	sd	s3,40(sp)
    80004a3c:	ec56                	sd	s5,24(sp)
    80004a3e:	e85a                	sd	s6,16(sp)
    80004a40:	0880                	addi	s0,sp,80
    80004a42:	8b2e                	mv	s6,a1
    80004a44:	89b2                	mv	s3,a2
    80004a46:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004a48:	fb040593          	addi	a1,s0,-80
    80004a4c:	80eff0ef          	jal	80003a5a <nameiparent>
    80004a50:	84aa                	mv	s1,a0
    80004a52:	10050a63          	beqz	a0,80004b66 <create+0x136>
    return 0;

  ilock(dp);
    80004a56:	fd4fe0ef          	jal	8000322a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a5a:	4601                	li	a2,0
    80004a5c:	fb040593          	addi	a1,s0,-80
    80004a60:	8526                	mv	a0,s1
    80004a62:	d79fe0ef          	jal	800037da <dirlookup>
    80004a66:	8aaa                	mv	s5,a0
    80004a68:	c129                	beqz	a0,80004aaa <create+0x7a>
    iunlockput(dp);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	9c9fe0ef          	jal	80003434 <iunlockput>
    ilock(ip);
    80004a70:	8556                	mv	a0,s5
    80004a72:	fb8fe0ef          	jal	8000322a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004a76:	4789                	li	a5,2
    80004a78:	02fb1463          	bne	s6,a5,80004aa0 <create+0x70>
    80004a7c:	044ad783          	lhu	a5,68(s5)
    80004a80:	37f9                	addiw	a5,a5,-2
    80004a82:	17c2                	slli	a5,a5,0x30
    80004a84:	93c1                	srli	a5,a5,0x30
    80004a86:	4705                	li	a4,1
    80004a88:	00f76c63          	bltu	a4,a5,80004aa0 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004a8c:	8556                	mv	a0,s5
    80004a8e:	60a6                	ld	ra,72(sp)
    80004a90:	6406                	ld	s0,64(sp)
    80004a92:	74e2                	ld	s1,56(sp)
    80004a94:	7942                	ld	s2,48(sp)
    80004a96:	79a2                	ld	s3,40(sp)
    80004a98:	6ae2                	ld	s5,24(sp)
    80004a9a:	6b42                	ld	s6,16(sp)
    80004a9c:	6161                	addi	sp,sp,80
    80004a9e:	8082                	ret
    iunlockput(ip);
    80004aa0:	8556                	mv	a0,s5
    80004aa2:	993fe0ef          	jal	80003434 <iunlockput>
    return 0;
    80004aa6:	4a81                	li	s5,0
    80004aa8:	b7d5                	j	80004a8c <create+0x5c>
    80004aaa:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004aac:	85da                	mv	a1,s6
    80004aae:	4088                	lw	a0,0(s1)
    80004ab0:	e0afe0ef          	jal	800030ba <ialloc>
    80004ab4:	8a2a                	mv	s4,a0
    80004ab6:	cd15                	beqz	a0,80004af2 <create+0xc2>
  ilock(ip);
    80004ab8:	f72fe0ef          	jal	8000322a <ilock>
  ip->major = major;
    80004abc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004ac0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004ac4:	4905                	li	s2,1
    80004ac6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004aca:	8552                	mv	a0,s4
    80004acc:	eaafe0ef          	jal	80003176 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004ad0:	032b0763          	beq	s6,s2,80004afe <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ad4:	004a2603          	lw	a2,4(s4)
    80004ad8:	fb040593          	addi	a1,s0,-80
    80004adc:	8526                	mv	a0,s1
    80004ade:	ec9fe0ef          	jal	800039a6 <dirlink>
    80004ae2:	06054563          	bltz	a0,80004b4c <create+0x11c>
  iunlockput(dp);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	94dfe0ef          	jal	80003434 <iunlockput>
  return ip;
    80004aec:	8ad2                	mv	s5,s4
    80004aee:	7a02                	ld	s4,32(sp)
    80004af0:	bf71                	j	80004a8c <create+0x5c>
    iunlockput(dp);
    80004af2:	8526                	mv	a0,s1
    80004af4:	941fe0ef          	jal	80003434 <iunlockput>
    return 0;
    80004af8:	8ad2                	mv	s5,s4
    80004afa:	7a02                	ld	s4,32(sp)
    80004afc:	bf41                	j	80004a8c <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004afe:	004a2603          	lw	a2,4(s4)
    80004b02:	00003597          	auipc	a1,0x3
    80004b06:	abe58593          	addi	a1,a1,-1346 # 800075c0 <etext+0x5c0>
    80004b0a:	8552                	mv	a0,s4
    80004b0c:	e9bfe0ef          	jal	800039a6 <dirlink>
    80004b10:	02054e63          	bltz	a0,80004b4c <create+0x11c>
    80004b14:	40d0                	lw	a2,4(s1)
    80004b16:	00003597          	auipc	a1,0x3
    80004b1a:	ab258593          	addi	a1,a1,-1358 # 800075c8 <etext+0x5c8>
    80004b1e:	8552                	mv	a0,s4
    80004b20:	e87fe0ef          	jal	800039a6 <dirlink>
    80004b24:	02054463          	bltz	a0,80004b4c <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b28:	004a2603          	lw	a2,4(s4)
    80004b2c:	fb040593          	addi	a1,s0,-80
    80004b30:	8526                	mv	a0,s1
    80004b32:	e75fe0ef          	jal	800039a6 <dirlink>
    80004b36:	00054b63          	bltz	a0,80004b4c <create+0x11c>
    dp->nlink++;  // for ".."
    80004b3a:	04a4d783          	lhu	a5,74(s1)
    80004b3e:	2785                	addiw	a5,a5,1
    80004b40:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004b44:	8526                	mv	a0,s1
    80004b46:	e30fe0ef          	jal	80003176 <iupdate>
    80004b4a:	bf71                	j	80004ae6 <create+0xb6>
  ip->nlink = 0;
    80004b4c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004b50:	8552                	mv	a0,s4
    80004b52:	e24fe0ef          	jal	80003176 <iupdate>
  iunlockput(ip);
    80004b56:	8552                	mv	a0,s4
    80004b58:	8ddfe0ef          	jal	80003434 <iunlockput>
  iunlockput(dp);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	8d7fe0ef          	jal	80003434 <iunlockput>
  return 0;
    80004b62:	7a02                	ld	s4,32(sp)
    80004b64:	b725                	j	80004a8c <create+0x5c>
    return 0;
    80004b66:	8aaa                	mv	s5,a0
    80004b68:	b715                	j	80004a8c <create+0x5c>

0000000080004b6a <sys_dup>:
{
    80004b6a:	7179                	addi	sp,sp,-48
    80004b6c:	f406                	sd	ra,40(sp)
    80004b6e:	f022                	sd	s0,32(sp)
    80004b70:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004b72:	fd840613          	addi	a2,s0,-40
    80004b76:	4581                	li	a1,0
    80004b78:	4501                	li	a0,0
    80004b7a:	e21ff0ef          	jal	8000499a <argfd>
    return -1;
    80004b7e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004b80:	02054363          	bltz	a0,80004ba6 <sys_dup+0x3c>
    80004b84:	ec26                	sd	s1,24(sp)
    80004b86:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004b88:	fd843903          	ld	s2,-40(s0)
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	e65ff0ef          	jal	800049f2 <fdalloc>
    80004b92:	84aa                	mv	s1,a0
    return -1;
    80004b94:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004b96:	00054d63          	bltz	a0,80004bb0 <sys_dup+0x46>
  filedup(f);
    80004b9a:	854a                	mv	a0,s2
    80004b9c:	c3eff0ef          	jal	80003fda <filedup>
  return fd;
    80004ba0:	87a6                	mv	a5,s1
    80004ba2:	64e2                	ld	s1,24(sp)
    80004ba4:	6942                	ld	s2,16(sp)
}
    80004ba6:	853e                	mv	a0,a5
    80004ba8:	70a2                	ld	ra,40(sp)
    80004baa:	7402                	ld	s0,32(sp)
    80004bac:	6145                	addi	sp,sp,48
    80004bae:	8082                	ret
    80004bb0:	64e2                	ld	s1,24(sp)
    80004bb2:	6942                	ld	s2,16(sp)
    80004bb4:	bfcd                	j	80004ba6 <sys_dup+0x3c>

0000000080004bb6 <sys_read>:
{
    80004bb6:	7179                	addi	sp,sp,-48
    80004bb8:	f406                	sd	ra,40(sp)
    80004bba:	f022                	sd	s0,32(sp)
    80004bbc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004bbe:	fd840593          	addi	a1,s0,-40
    80004bc2:	4505                	li	a0,1
    80004bc4:	c7dfd0ef          	jal	80002840 <argaddr>
  argint(2, &n);
    80004bc8:	fe440593          	addi	a1,s0,-28
    80004bcc:	4509                	li	a0,2
    80004bce:	c57fd0ef          	jal	80002824 <argint>
  if(argfd(0, 0, &f) < 0)
    80004bd2:	fe840613          	addi	a2,s0,-24
    80004bd6:	4581                	li	a1,0
    80004bd8:	4501                	li	a0,0
    80004bda:	dc1ff0ef          	jal	8000499a <argfd>
    80004bde:	87aa                	mv	a5,a0
    return -1;
    80004be0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004be2:	0007ca63          	bltz	a5,80004bf6 <sys_read+0x40>
  return fileread(f, p, n);
    80004be6:	fe442603          	lw	a2,-28(s0)
    80004bea:	fd843583          	ld	a1,-40(s0)
    80004bee:	fe843503          	ld	a0,-24(s0)
    80004bf2:	d4eff0ef          	jal	80004140 <fileread>
}
    80004bf6:	70a2                	ld	ra,40(sp)
    80004bf8:	7402                	ld	s0,32(sp)
    80004bfa:	6145                	addi	sp,sp,48
    80004bfc:	8082                	ret

0000000080004bfe <sys_write>:
{
    80004bfe:	7179                	addi	sp,sp,-48
    80004c00:	f406                	sd	ra,40(sp)
    80004c02:	f022                	sd	s0,32(sp)
    80004c04:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c06:	fd840593          	addi	a1,s0,-40
    80004c0a:	4505                	li	a0,1
    80004c0c:	c35fd0ef          	jal	80002840 <argaddr>
  argint(2, &n);
    80004c10:	fe440593          	addi	a1,s0,-28
    80004c14:	4509                	li	a0,2
    80004c16:	c0ffd0ef          	jal	80002824 <argint>
  if(argfd(0, 0, &f) < 0)
    80004c1a:	fe840613          	addi	a2,s0,-24
    80004c1e:	4581                	li	a1,0
    80004c20:	4501                	li	a0,0
    80004c22:	d79ff0ef          	jal	8000499a <argfd>
    80004c26:	87aa                	mv	a5,a0
    return -1;
    80004c28:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c2a:	0007ca63          	bltz	a5,80004c3e <sys_write+0x40>
  return filewrite(f, p, n);
    80004c2e:	fe442603          	lw	a2,-28(s0)
    80004c32:	fd843583          	ld	a1,-40(s0)
    80004c36:	fe843503          	ld	a0,-24(s0)
    80004c3a:	dc4ff0ef          	jal	800041fe <filewrite>
}
    80004c3e:	70a2                	ld	ra,40(sp)
    80004c40:	7402                	ld	s0,32(sp)
    80004c42:	6145                	addi	sp,sp,48
    80004c44:	8082                	ret

0000000080004c46 <sys_close>:
{
    80004c46:	1101                	addi	sp,sp,-32
    80004c48:	ec06                	sd	ra,24(sp)
    80004c4a:	e822                	sd	s0,16(sp)
    80004c4c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004c4e:	fe040613          	addi	a2,s0,-32
    80004c52:	fec40593          	addi	a1,s0,-20
    80004c56:	4501                	li	a0,0
    80004c58:	d43ff0ef          	jal	8000499a <argfd>
    return -1;
    80004c5c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004c5e:	02054063          	bltz	a0,80004c7e <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004c62:	cb5fc0ef          	jal	80001916 <myproc>
    80004c66:	fec42783          	lw	a5,-20(s0)
    80004c6a:	07e9                	addi	a5,a5,26
    80004c6c:	078e                	slli	a5,a5,0x3
    80004c6e:	953e                	add	a0,a0,a5
    80004c70:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004c74:	fe043503          	ld	a0,-32(s0)
    80004c78:	ba8ff0ef          	jal	80004020 <fileclose>
  return 0;
    80004c7c:	4781                	li	a5,0
}
    80004c7e:	853e                	mv	a0,a5
    80004c80:	60e2                	ld	ra,24(sp)
    80004c82:	6442                	ld	s0,16(sp)
    80004c84:	6105                	addi	sp,sp,32
    80004c86:	8082                	ret

0000000080004c88 <sys_fstat>:
{
    80004c88:	1101                	addi	sp,sp,-32
    80004c8a:	ec06                	sd	ra,24(sp)
    80004c8c:	e822                	sd	s0,16(sp)
    80004c8e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004c90:	fe040593          	addi	a1,s0,-32
    80004c94:	4505                	li	a0,1
    80004c96:	babfd0ef          	jal	80002840 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004c9a:	fe840613          	addi	a2,s0,-24
    80004c9e:	4581                	li	a1,0
    80004ca0:	4501                	li	a0,0
    80004ca2:	cf9ff0ef          	jal	8000499a <argfd>
    80004ca6:	87aa                	mv	a5,a0
    return -1;
    80004ca8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004caa:	0007c863          	bltz	a5,80004cba <sys_fstat+0x32>
  return filestat(f, st);
    80004cae:	fe043583          	ld	a1,-32(s0)
    80004cb2:	fe843503          	ld	a0,-24(s0)
    80004cb6:	c2cff0ef          	jal	800040e2 <filestat>
}
    80004cba:	60e2                	ld	ra,24(sp)
    80004cbc:	6442                	ld	s0,16(sp)
    80004cbe:	6105                	addi	sp,sp,32
    80004cc0:	8082                	ret

0000000080004cc2 <sys_link>:
{
    80004cc2:	7169                	addi	sp,sp,-304
    80004cc4:	f606                	sd	ra,296(sp)
    80004cc6:	f222                	sd	s0,288(sp)
    80004cc8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004cca:	08000613          	li	a2,128
    80004cce:	ed040593          	addi	a1,s0,-304
    80004cd2:	4501                	li	a0,0
    80004cd4:	b89fd0ef          	jal	8000285c <argstr>
    return -1;
    80004cd8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004cda:	0c054e63          	bltz	a0,80004db6 <sys_link+0xf4>
    80004cde:	08000613          	li	a2,128
    80004ce2:	f5040593          	addi	a1,s0,-176
    80004ce6:	4505                	li	a0,1
    80004ce8:	b75fd0ef          	jal	8000285c <argstr>
    return -1;
    80004cec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004cee:	0c054463          	bltz	a0,80004db6 <sys_link+0xf4>
    80004cf2:	ee26                	sd	s1,280(sp)
  begin_op();
    80004cf4:	f21fe0ef          	jal	80003c14 <begin_op>
  if((ip = namei(old)) == 0){
    80004cf8:	ed040513          	addi	a0,s0,-304
    80004cfc:	d45fe0ef          	jal	80003a40 <namei>
    80004d00:	84aa                	mv	s1,a0
    80004d02:	c53d                	beqz	a0,80004d70 <sys_link+0xae>
  ilock(ip);
    80004d04:	d26fe0ef          	jal	8000322a <ilock>
  if(ip->type == T_DIR){
    80004d08:	04449703          	lh	a4,68(s1)
    80004d0c:	4785                	li	a5,1
    80004d0e:	06f70663          	beq	a4,a5,80004d7a <sys_link+0xb8>
    80004d12:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004d14:	04a4d783          	lhu	a5,74(s1)
    80004d18:	2785                	addiw	a5,a5,1
    80004d1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004d1e:	8526                	mv	a0,s1
    80004d20:	c56fe0ef          	jal	80003176 <iupdate>
  iunlock(ip);
    80004d24:	8526                	mv	a0,s1
    80004d26:	db2fe0ef          	jal	800032d8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004d2a:	fd040593          	addi	a1,s0,-48
    80004d2e:	f5040513          	addi	a0,s0,-176
    80004d32:	d29fe0ef          	jal	80003a5a <nameiparent>
    80004d36:	892a                	mv	s2,a0
    80004d38:	cd21                	beqz	a0,80004d90 <sys_link+0xce>
  ilock(dp);
    80004d3a:	cf0fe0ef          	jal	8000322a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004d3e:	00092703          	lw	a4,0(s2)
    80004d42:	409c                	lw	a5,0(s1)
    80004d44:	04f71363          	bne	a4,a5,80004d8a <sys_link+0xc8>
    80004d48:	40d0                	lw	a2,4(s1)
    80004d4a:	fd040593          	addi	a1,s0,-48
    80004d4e:	854a                	mv	a0,s2
    80004d50:	c57fe0ef          	jal	800039a6 <dirlink>
    80004d54:	02054b63          	bltz	a0,80004d8a <sys_link+0xc8>
  iunlockput(dp);
    80004d58:	854a                	mv	a0,s2
    80004d5a:	edafe0ef          	jal	80003434 <iunlockput>
  iput(ip);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	e4cfe0ef          	jal	800033ac <iput>
  end_op();
    80004d64:	f1bfe0ef          	jal	80003c7e <end_op>
  return 0;
    80004d68:	4781                	li	a5,0
    80004d6a:	64f2                	ld	s1,280(sp)
    80004d6c:	6952                	ld	s2,272(sp)
    80004d6e:	a0a1                	j	80004db6 <sys_link+0xf4>
    end_op();
    80004d70:	f0ffe0ef          	jal	80003c7e <end_op>
    return -1;
    80004d74:	57fd                	li	a5,-1
    80004d76:	64f2                	ld	s1,280(sp)
    80004d78:	a83d                	j	80004db6 <sys_link+0xf4>
    iunlockput(ip);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	eb8fe0ef          	jal	80003434 <iunlockput>
    end_op();
    80004d80:	efffe0ef          	jal	80003c7e <end_op>
    return -1;
    80004d84:	57fd                	li	a5,-1
    80004d86:	64f2                	ld	s1,280(sp)
    80004d88:	a03d                	j	80004db6 <sys_link+0xf4>
    iunlockput(dp);
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	ea8fe0ef          	jal	80003434 <iunlockput>
  ilock(ip);
    80004d90:	8526                	mv	a0,s1
    80004d92:	c98fe0ef          	jal	8000322a <ilock>
  ip->nlink--;
    80004d96:	04a4d783          	lhu	a5,74(s1)
    80004d9a:	37fd                	addiw	a5,a5,-1
    80004d9c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004da0:	8526                	mv	a0,s1
    80004da2:	bd4fe0ef          	jal	80003176 <iupdate>
  iunlockput(ip);
    80004da6:	8526                	mv	a0,s1
    80004da8:	e8cfe0ef          	jal	80003434 <iunlockput>
  end_op();
    80004dac:	ed3fe0ef          	jal	80003c7e <end_op>
  return -1;
    80004db0:	57fd                	li	a5,-1
    80004db2:	64f2                	ld	s1,280(sp)
    80004db4:	6952                	ld	s2,272(sp)
}
    80004db6:	853e                	mv	a0,a5
    80004db8:	70b2                	ld	ra,296(sp)
    80004dba:	7412                	ld	s0,288(sp)
    80004dbc:	6155                	addi	sp,sp,304
    80004dbe:	8082                	ret

0000000080004dc0 <sys_unlink>:
{
    80004dc0:	7151                	addi	sp,sp,-240
    80004dc2:	f586                	sd	ra,232(sp)
    80004dc4:	f1a2                	sd	s0,224(sp)
    80004dc6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004dc8:	08000613          	li	a2,128
    80004dcc:	f3040593          	addi	a1,s0,-208
    80004dd0:	4501                	li	a0,0
    80004dd2:	a8bfd0ef          	jal	8000285c <argstr>
    80004dd6:	16054063          	bltz	a0,80004f36 <sys_unlink+0x176>
    80004dda:	eda6                	sd	s1,216(sp)
  begin_op();
    80004ddc:	e39fe0ef          	jal	80003c14 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004de0:	fb040593          	addi	a1,s0,-80
    80004de4:	f3040513          	addi	a0,s0,-208
    80004de8:	c73fe0ef          	jal	80003a5a <nameiparent>
    80004dec:	84aa                	mv	s1,a0
    80004dee:	c945                	beqz	a0,80004e9e <sys_unlink+0xde>
  ilock(dp);
    80004df0:	c3afe0ef          	jal	8000322a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004df4:	00002597          	auipc	a1,0x2
    80004df8:	7cc58593          	addi	a1,a1,1996 # 800075c0 <etext+0x5c0>
    80004dfc:	fb040513          	addi	a0,s0,-80
    80004e00:	9c5fe0ef          	jal	800037c4 <namecmp>
    80004e04:	10050e63          	beqz	a0,80004f20 <sys_unlink+0x160>
    80004e08:	00002597          	auipc	a1,0x2
    80004e0c:	7c058593          	addi	a1,a1,1984 # 800075c8 <etext+0x5c8>
    80004e10:	fb040513          	addi	a0,s0,-80
    80004e14:	9b1fe0ef          	jal	800037c4 <namecmp>
    80004e18:	10050463          	beqz	a0,80004f20 <sys_unlink+0x160>
    80004e1c:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004e1e:	f2c40613          	addi	a2,s0,-212
    80004e22:	fb040593          	addi	a1,s0,-80
    80004e26:	8526                	mv	a0,s1
    80004e28:	9b3fe0ef          	jal	800037da <dirlookup>
    80004e2c:	892a                	mv	s2,a0
    80004e2e:	0e050863          	beqz	a0,80004f1e <sys_unlink+0x15e>
  ilock(ip);
    80004e32:	bf8fe0ef          	jal	8000322a <ilock>
  if(ip->nlink < 1)
    80004e36:	04a91783          	lh	a5,74(s2)
    80004e3a:	06f05763          	blez	a5,80004ea8 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004e3e:	04491703          	lh	a4,68(s2)
    80004e42:	4785                	li	a5,1
    80004e44:	06f70963          	beq	a4,a5,80004eb6 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004e48:	4641                	li	a2,16
    80004e4a:	4581                	li	a1,0
    80004e4c:	fc040513          	addi	a0,s0,-64
    80004e50:	e9bfb0ef          	jal	80000cea <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e54:	4741                	li	a4,16
    80004e56:	f2c42683          	lw	a3,-212(s0)
    80004e5a:	fc040613          	addi	a2,s0,-64
    80004e5e:	4581                	li	a1,0
    80004e60:	8526                	mv	a0,s1
    80004e62:	855fe0ef          	jal	800036b6 <writei>
    80004e66:	47c1                	li	a5,16
    80004e68:	08f51b63          	bne	a0,a5,80004efe <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004e6c:	04491703          	lh	a4,68(s2)
    80004e70:	4785                	li	a5,1
    80004e72:	08f70d63          	beq	a4,a5,80004f0c <sys_unlink+0x14c>
  iunlockput(dp);
    80004e76:	8526                	mv	a0,s1
    80004e78:	dbcfe0ef          	jal	80003434 <iunlockput>
  ip->nlink--;
    80004e7c:	04a95783          	lhu	a5,74(s2)
    80004e80:	37fd                	addiw	a5,a5,-1
    80004e82:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004e86:	854a                	mv	a0,s2
    80004e88:	aeefe0ef          	jal	80003176 <iupdate>
  iunlockput(ip);
    80004e8c:	854a                	mv	a0,s2
    80004e8e:	da6fe0ef          	jal	80003434 <iunlockput>
  end_op();
    80004e92:	dedfe0ef          	jal	80003c7e <end_op>
  return 0;
    80004e96:	4501                	li	a0,0
    80004e98:	64ee                	ld	s1,216(sp)
    80004e9a:	694e                	ld	s2,208(sp)
    80004e9c:	a849                	j	80004f2e <sys_unlink+0x16e>
    end_op();
    80004e9e:	de1fe0ef          	jal	80003c7e <end_op>
    return -1;
    80004ea2:	557d                	li	a0,-1
    80004ea4:	64ee                	ld	s1,216(sp)
    80004ea6:	a061                	j	80004f2e <sys_unlink+0x16e>
    80004ea8:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004eaa:	00002517          	auipc	a0,0x2
    80004eae:	72650513          	addi	a0,a0,1830 # 800075d0 <etext+0x5d0>
    80004eb2:	92ffb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004eb6:	04c92703          	lw	a4,76(s2)
    80004eba:	02000793          	li	a5,32
    80004ebe:	f8e7f5e3          	bgeu	a5,a4,80004e48 <sys_unlink+0x88>
    80004ec2:	e5ce                	sd	s3,200(sp)
    80004ec4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ec8:	4741                	li	a4,16
    80004eca:	86ce                	mv	a3,s3
    80004ecc:	f1840613          	addi	a2,s0,-232
    80004ed0:	4581                	li	a1,0
    80004ed2:	854a                	mv	a0,s2
    80004ed4:	ee6fe0ef          	jal	800035ba <readi>
    80004ed8:	47c1                	li	a5,16
    80004eda:	00f51c63          	bne	a0,a5,80004ef2 <sys_unlink+0x132>
    if(de.inum != 0)
    80004ede:	f1845783          	lhu	a5,-232(s0)
    80004ee2:	efa1                	bnez	a5,80004f3a <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004ee4:	29c1                	addiw	s3,s3,16
    80004ee6:	04c92783          	lw	a5,76(s2)
    80004eea:	fcf9efe3          	bltu	s3,a5,80004ec8 <sys_unlink+0x108>
    80004eee:	69ae                	ld	s3,200(sp)
    80004ef0:	bfa1                	j	80004e48 <sys_unlink+0x88>
      panic("isdirempty: readi");
    80004ef2:	00002517          	auipc	a0,0x2
    80004ef6:	6f650513          	addi	a0,a0,1782 # 800075e8 <etext+0x5e8>
    80004efa:	8e7fb0ef          	jal	800007e0 <panic>
    80004efe:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80004f00:	00002517          	auipc	a0,0x2
    80004f04:	70050513          	addi	a0,a0,1792 # 80007600 <etext+0x600>
    80004f08:	8d9fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80004f0c:	04a4d783          	lhu	a5,74(s1)
    80004f10:	37fd                	addiw	a5,a5,-1
    80004f12:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004f16:	8526                	mv	a0,s1
    80004f18:	a5efe0ef          	jal	80003176 <iupdate>
    80004f1c:	bfa9                	j	80004e76 <sys_unlink+0xb6>
    80004f1e:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80004f20:	8526                	mv	a0,s1
    80004f22:	d12fe0ef          	jal	80003434 <iunlockput>
  end_op();
    80004f26:	d59fe0ef          	jal	80003c7e <end_op>
  return -1;
    80004f2a:	557d                	li	a0,-1
    80004f2c:	64ee                	ld	s1,216(sp)
}
    80004f2e:	70ae                	ld	ra,232(sp)
    80004f30:	740e                	ld	s0,224(sp)
    80004f32:	616d                	addi	sp,sp,240
    80004f34:	8082                	ret
    return -1;
    80004f36:	557d                	li	a0,-1
    80004f38:	bfdd                	j	80004f2e <sys_unlink+0x16e>
    iunlockput(ip);
    80004f3a:	854a                	mv	a0,s2
    80004f3c:	cf8fe0ef          	jal	80003434 <iunlockput>
    goto bad;
    80004f40:	694e                	ld	s2,208(sp)
    80004f42:	69ae                	ld	s3,200(sp)
    80004f44:	bff1                	j	80004f20 <sys_unlink+0x160>

0000000080004f46 <sys_open>:

uint64
sys_open(void)
{
    80004f46:	7131                	addi	sp,sp,-192
    80004f48:	fd06                	sd	ra,184(sp)
    80004f4a:	f922                	sd	s0,176(sp)
    80004f4c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004f4e:	f4c40593          	addi	a1,s0,-180
    80004f52:	4505                	li	a0,1
    80004f54:	8d1fd0ef          	jal	80002824 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004f58:	08000613          	li	a2,128
    80004f5c:	f5040593          	addi	a1,s0,-176
    80004f60:	4501                	li	a0,0
    80004f62:	8fbfd0ef          	jal	8000285c <argstr>
    80004f66:	87aa                	mv	a5,a0
    return -1;
    80004f68:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004f6a:	0a07c263          	bltz	a5,8000500e <sys_open+0xc8>
    80004f6e:	f526                	sd	s1,168(sp)

  begin_op();
    80004f70:	ca5fe0ef          	jal	80003c14 <begin_op>

  if(omode & O_CREATE){
    80004f74:	f4c42783          	lw	a5,-180(s0)
    80004f78:	2007f793          	andi	a5,a5,512
    80004f7c:	c3d5                	beqz	a5,80005020 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004f7e:	4681                	li	a3,0
    80004f80:	4601                	li	a2,0
    80004f82:	4589                	li	a1,2
    80004f84:	f5040513          	addi	a0,s0,-176
    80004f88:	aa9ff0ef          	jal	80004a30 <create>
    80004f8c:	84aa                	mv	s1,a0
    if(ip == 0){
    80004f8e:	c541                	beqz	a0,80005016 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004f90:	04449703          	lh	a4,68(s1)
    80004f94:	478d                	li	a5,3
    80004f96:	00f71763          	bne	a4,a5,80004fa4 <sys_open+0x5e>
    80004f9a:	0464d703          	lhu	a4,70(s1)
    80004f9e:	47a5                	li	a5,9
    80004fa0:	0ae7ed63          	bltu	a5,a4,8000505a <sys_open+0x114>
    80004fa4:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80004fa6:	fd7fe0ef          	jal	80003f7c <filealloc>
    80004faa:	892a                	mv	s2,a0
    80004fac:	c179                	beqz	a0,80005072 <sys_open+0x12c>
    80004fae:	ed4e                	sd	s3,152(sp)
    80004fb0:	a43ff0ef          	jal	800049f2 <fdalloc>
    80004fb4:	89aa                	mv	s3,a0
    80004fb6:	0a054a63          	bltz	a0,8000506a <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004fba:	04449703          	lh	a4,68(s1)
    80004fbe:	478d                	li	a5,3
    80004fc0:	0cf70263          	beq	a4,a5,80005084 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004fc4:	4789                	li	a5,2
    80004fc6:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80004fca:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80004fce:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80004fd2:	f4c42783          	lw	a5,-180(s0)
    80004fd6:	0017c713          	xori	a4,a5,1
    80004fda:	8b05                	andi	a4,a4,1
    80004fdc:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004fe0:	0037f713          	andi	a4,a5,3
    80004fe4:	00e03733          	snez	a4,a4
    80004fe8:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80004fec:	4007f793          	andi	a5,a5,1024
    80004ff0:	c791                	beqz	a5,80004ffc <sys_open+0xb6>
    80004ff2:	04449703          	lh	a4,68(s1)
    80004ff6:	4789                	li	a5,2
    80004ff8:	08f70d63          	beq	a4,a5,80005092 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80004ffc:	8526                	mv	a0,s1
    80004ffe:	adafe0ef          	jal	800032d8 <iunlock>
  end_op();
    80005002:	c7dfe0ef          	jal	80003c7e <end_op>

  return fd;
    80005006:	854e                	mv	a0,s3
    80005008:	74aa                	ld	s1,168(sp)
    8000500a:	790a                	ld	s2,160(sp)
    8000500c:	69ea                	ld	s3,152(sp)
}
    8000500e:	70ea                	ld	ra,184(sp)
    80005010:	744a                	ld	s0,176(sp)
    80005012:	6129                	addi	sp,sp,192
    80005014:	8082                	ret
      end_op();
    80005016:	c69fe0ef          	jal	80003c7e <end_op>
      return -1;
    8000501a:	557d                	li	a0,-1
    8000501c:	74aa                	ld	s1,168(sp)
    8000501e:	bfc5                	j	8000500e <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80005020:	f5040513          	addi	a0,s0,-176
    80005024:	a1dfe0ef          	jal	80003a40 <namei>
    80005028:	84aa                	mv	s1,a0
    8000502a:	c11d                	beqz	a0,80005050 <sys_open+0x10a>
    ilock(ip);
    8000502c:	9fefe0ef          	jal	8000322a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005030:	04449703          	lh	a4,68(s1)
    80005034:	4785                	li	a5,1
    80005036:	f4f71de3          	bne	a4,a5,80004f90 <sys_open+0x4a>
    8000503a:	f4c42783          	lw	a5,-180(s0)
    8000503e:	d3bd                	beqz	a5,80004fa4 <sys_open+0x5e>
      iunlockput(ip);
    80005040:	8526                	mv	a0,s1
    80005042:	bf2fe0ef          	jal	80003434 <iunlockput>
      end_op();
    80005046:	c39fe0ef          	jal	80003c7e <end_op>
      return -1;
    8000504a:	557d                	li	a0,-1
    8000504c:	74aa                	ld	s1,168(sp)
    8000504e:	b7c1                	j	8000500e <sys_open+0xc8>
      end_op();
    80005050:	c2ffe0ef          	jal	80003c7e <end_op>
      return -1;
    80005054:	557d                	li	a0,-1
    80005056:	74aa                	ld	s1,168(sp)
    80005058:	bf5d                	j	8000500e <sys_open+0xc8>
    iunlockput(ip);
    8000505a:	8526                	mv	a0,s1
    8000505c:	bd8fe0ef          	jal	80003434 <iunlockput>
    end_op();
    80005060:	c1ffe0ef          	jal	80003c7e <end_op>
    return -1;
    80005064:	557d                	li	a0,-1
    80005066:	74aa                	ld	s1,168(sp)
    80005068:	b75d                	j	8000500e <sys_open+0xc8>
      fileclose(f);
    8000506a:	854a                	mv	a0,s2
    8000506c:	fb5fe0ef          	jal	80004020 <fileclose>
    80005070:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005072:	8526                	mv	a0,s1
    80005074:	bc0fe0ef          	jal	80003434 <iunlockput>
    end_op();
    80005078:	c07fe0ef          	jal	80003c7e <end_op>
    return -1;
    8000507c:	557d                	li	a0,-1
    8000507e:	74aa                	ld	s1,168(sp)
    80005080:	790a                	ld	s2,160(sp)
    80005082:	b771                	j	8000500e <sys_open+0xc8>
    f->type = FD_DEVICE;
    80005084:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005088:	04649783          	lh	a5,70(s1)
    8000508c:	02f91223          	sh	a5,36(s2)
    80005090:	bf3d                	j	80004fce <sys_open+0x88>
    itrunc(ip);
    80005092:	8526                	mv	a0,s1
    80005094:	a84fe0ef          	jal	80003318 <itrunc>
    80005098:	b795                	j	80004ffc <sys_open+0xb6>

000000008000509a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000509a:	7175                	addi	sp,sp,-144
    8000509c:	e506                	sd	ra,136(sp)
    8000509e:	e122                	sd	s0,128(sp)
    800050a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800050a2:	b73fe0ef          	jal	80003c14 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800050a6:	08000613          	li	a2,128
    800050aa:	f7040593          	addi	a1,s0,-144
    800050ae:	4501                	li	a0,0
    800050b0:	facfd0ef          	jal	8000285c <argstr>
    800050b4:	02054363          	bltz	a0,800050da <sys_mkdir+0x40>
    800050b8:	4681                	li	a3,0
    800050ba:	4601                	li	a2,0
    800050bc:	4585                	li	a1,1
    800050be:	f7040513          	addi	a0,s0,-144
    800050c2:	96fff0ef          	jal	80004a30 <create>
    800050c6:	c911                	beqz	a0,800050da <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800050c8:	b6cfe0ef          	jal	80003434 <iunlockput>
  end_op();
    800050cc:	bb3fe0ef          	jal	80003c7e <end_op>
  return 0;
    800050d0:	4501                	li	a0,0
}
    800050d2:	60aa                	ld	ra,136(sp)
    800050d4:	640a                	ld	s0,128(sp)
    800050d6:	6149                	addi	sp,sp,144
    800050d8:	8082                	ret
    end_op();
    800050da:	ba5fe0ef          	jal	80003c7e <end_op>
    return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	bfcd                	j	800050d2 <sys_mkdir+0x38>

00000000800050e2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800050e2:	7135                	addi	sp,sp,-160
    800050e4:	ed06                	sd	ra,152(sp)
    800050e6:	e922                	sd	s0,144(sp)
    800050e8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800050ea:	b2bfe0ef          	jal	80003c14 <begin_op>
  argint(1, &major);
    800050ee:	f6c40593          	addi	a1,s0,-148
    800050f2:	4505                	li	a0,1
    800050f4:	f30fd0ef          	jal	80002824 <argint>
  argint(2, &minor);
    800050f8:	f6840593          	addi	a1,s0,-152
    800050fc:	4509                	li	a0,2
    800050fe:	f26fd0ef          	jal	80002824 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005102:	08000613          	li	a2,128
    80005106:	f7040593          	addi	a1,s0,-144
    8000510a:	4501                	li	a0,0
    8000510c:	f50fd0ef          	jal	8000285c <argstr>
    80005110:	02054563          	bltz	a0,8000513a <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005114:	f6841683          	lh	a3,-152(s0)
    80005118:	f6c41603          	lh	a2,-148(s0)
    8000511c:	458d                	li	a1,3
    8000511e:	f7040513          	addi	a0,s0,-144
    80005122:	90fff0ef          	jal	80004a30 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005126:	c911                	beqz	a0,8000513a <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005128:	b0cfe0ef          	jal	80003434 <iunlockput>
  end_op();
    8000512c:	b53fe0ef          	jal	80003c7e <end_op>
  return 0;
    80005130:	4501                	li	a0,0
}
    80005132:	60ea                	ld	ra,152(sp)
    80005134:	644a                	ld	s0,144(sp)
    80005136:	610d                	addi	sp,sp,160
    80005138:	8082                	ret
    end_op();
    8000513a:	b45fe0ef          	jal	80003c7e <end_op>
    return -1;
    8000513e:	557d                	li	a0,-1
    80005140:	bfcd                	j	80005132 <sys_mknod+0x50>

0000000080005142 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005142:	7135                	addi	sp,sp,-160
    80005144:	ed06                	sd	ra,152(sp)
    80005146:	e922                	sd	s0,144(sp)
    80005148:	e14a                	sd	s2,128(sp)
    8000514a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000514c:	fcafc0ef          	jal	80001916 <myproc>
    80005150:	892a                	mv	s2,a0
  
  begin_op();
    80005152:	ac3fe0ef          	jal	80003c14 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005156:	08000613          	li	a2,128
    8000515a:	f6040593          	addi	a1,s0,-160
    8000515e:	4501                	li	a0,0
    80005160:	efcfd0ef          	jal	8000285c <argstr>
    80005164:	04054363          	bltz	a0,800051aa <sys_chdir+0x68>
    80005168:	e526                	sd	s1,136(sp)
    8000516a:	f6040513          	addi	a0,s0,-160
    8000516e:	8d3fe0ef          	jal	80003a40 <namei>
    80005172:	84aa                	mv	s1,a0
    80005174:	c915                	beqz	a0,800051a8 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005176:	8b4fe0ef          	jal	8000322a <ilock>
  if(ip->type != T_DIR){
    8000517a:	04449703          	lh	a4,68(s1)
    8000517e:	4785                	li	a5,1
    80005180:	02f71963          	bne	a4,a5,800051b2 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005184:	8526                	mv	a0,s1
    80005186:	952fe0ef          	jal	800032d8 <iunlock>
  iput(p->cwd);
    8000518a:	15093503          	ld	a0,336(s2)
    8000518e:	a1efe0ef          	jal	800033ac <iput>
  end_op();
    80005192:	aedfe0ef          	jal	80003c7e <end_op>
  p->cwd = ip;
    80005196:	14993823          	sd	s1,336(s2)
  return 0;
    8000519a:	4501                	li	a0,0
    8000519c:	64aa                	ld	s1,136(sp)
}
    8000519e:	60ea                	ld	ra,152(sp)
    800051a0:	644a                	ld	s0,144(sp)
    800051a2:	690a                	ld	s2,128(sp)
    800051a4:	610d                	addi	sp,sp,160
    800051a6:	8082                	ret
    800051a8:	64aa                	ld	s1,136(sp)
    end_op();
    800051aa:	ad5fe0ef          	jal	80003c7e <end_op>
    return -1;
    800051ae:	557d                	li	a0,-1
    800051b0:	b7fd                	j	8000519e <sys_chdir+0x5c>
    iunlockput(ip);
    800051b2:	8526                	mv	a0,s1
    800051b4:	a80fe0ef          	jal	80003434 <iunlockput>
    end_op();
    800051b8:	ac7fe0ef          	jal	80003c7e <end_op>
    return -1;
    800051bc:	557d                	li	a0,-1
    800051be:	64aa                	ld	s1,136(sp)
    800051c0:	bff9                	j	8000519e <sys_chdir+0x5c>

00000000800051c2 <sys_exec>:

uint64
sys_exec(void)
{
    800051c2:	7121                	addi	sp,sp,-448
    800051c4:	ff06                	sd	ra,440(sp)
    800051c6:	fb22                	sd	s0,432(sp)
    800051c8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800051ca:	e4840593          	addi	a1,s0,-440
    800051ce:	4505                	li	a0,1
    800051d0:	e70fd0ef          	jal	80002840 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800051d4:	08000613          	li	a2,128
    800051d8:	f5040593          	addi	a1,s0,-176
    800051dc:	4501                	li	a0,0
    800051de:	e7efd0ef          	jal	8000285c <argstr>
    800051e2:	87aa                	mv	a5,a0
    return -1;
    800051e4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800051e6:	0c07c463          	bltz	a5,800052ae <sys_exec+0xec>
    800051ea:	f726                	sd	s1,424(sp)
    800051ec:	f34a                	sd	s2,416(sp)
    800051ee:	ef4e                	sd	s3,408(sp)
    800051f0:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800051f2:	10000613          	li	a2,256
    800051f6:	4581                	li	a1,0
    800051f8:	e5040513          	addi	a0,s0,-432
    800051fc:	aeffb0ef          	jal	80000cea <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005200:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005204:	89a6                	mv	s3,s1
    80005206:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005208:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000520c:	00391513          	slli	a0,s2,0x3
    80005210:	e4040593          	addi	a1,s0,-448
    80005214:	e4843783          	ld	a5,-440(s0)
    80005218:	953e                	add	a0,a0,a5
    8000521a:	d80fd0ef          	jal	8000279a <fetchaddr>
    8000521e:	02054663          	bltz	a0,8000524a <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80005222:	e4043783          	ld	a5,-448(s0)
    80005226:	c3a9                	beqz	a5,80005268 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005228:	913fb0ef          	jal	80000b3a <kalloc>
    8000522c:	85aa                	mv	a1,a0
    8000522e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005232:	cd01                	beqz	a0,8000524a <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005234:	6605                	lui	a2,0x1
    80005236:	e4043503          	ld	a0,-448(s0)
    8000523a:	daafd0ef          	jal	800027e4 <fetchstr>
    8000523e:	00054663          	bltz	a0,8000524a <sys_exec+0x88>
    if(i >= NELEM(argv)){
    80005242:	0905                	addi	s2,s2,1
    80005244:	09a1                	addi	s3,s3,8
    80005246:	fd4913e3          	bne	s2,s4,8000520c <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000524a:	f5040913          	addi	s2,s0,-176
    8000524e:	6088                	ld	a0,0(s1)
    80005250:	c931                	beqz	a0,800052a4 <sys_exec+0xe2>
    kfree(argv[i]);
    80005252:	fcafb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005256:	04a1                	addi	s1,s1,8
    80005258:	ff249be3          	bne	s1,s2,8000524e <sys_exec+0x8c>
  return -1;
    8000525c:	557d                	li	a0,-1
    8000525e:	74ba                	ld	s1,424(sp)
    80005260:	791a                	ld	s2,416(sp)
    80005262:	69fa                	ld	s3,408(sp)
    80005264:	6a5a                	ld	s4,400(sp)
    80005266:	a0a1                	j	800052ae <sys_exec+0xec>
      argv[i] = 0;
    80005268:	0009079b          	sext.w	a5,s2
    8000526c:	078e                	slli	a5,a5,0x3
    8000526e:	fd078793          	addi	a5,a5,-48
    80005272:	97a2                	add	a5,a5,s0
    80005274:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    80005278:	e5040593          	addi	a1,s0,-432
    8000527c:	f5040513          	addi	a0,s0,-176
    80005280:	ba8ff0ef          	jal	80004628 <kexec>
    80005284:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005286:	f5040993          	addi	s3,s0,-176
    8000528a:	6088                	ld	a0,0(s1)
    8000528c:	c511                	beqz	a0,80005298 <sys_exec+0xd6>
    kfree(argv[i]);
    8000528e:	f8efb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005292:	04a1                	addi	s1,s1,8
    80005294:	ff349be3          	bne	s1,s3,8000528a <sys_exec+0xc8>
  return ret;
    80005298:	854a                	mv	a0,s2
    8000529a:	74ba                	ld	s1,424(sp)
    8000529c:	791a                	ld	s2,416(sp)
    8000529e:	69fa                	ld	s3,408(sp)
    800052a0:	6a5a                	ld	s4,400(sp)
    800052a2:	a031                	j	800052ae <sys_exec+0xec>
  return -1;
    800052a4:	557d                	li	a0,-1
    800052a6:	74ba                	ld	s1,424(sp)
    800052a8:	791a                	ld	s2,416(sp)
    800052aa:	69fa                	ld	s3,408(sp)
    800052ac:	6a5a                	ld	s4,400(sp)
}
    800052ae:	70fa                	ld	ra,440(sp)
    800052b0:	745a                	ld	s0,432(sp)
    800052b2:	6139                	addi	sp,sp,448
    800052b4:	8082                	ret

00000000800052b6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800052b6:	7139                	addi	sp,sp,-64
    800052b8:	fc06                	sd	ra,56(sp)
    800052ba:	f822                	sd	s0,48(sp)
    800052bc:	f426                	sd	s1,40(sp)
    800052be:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800052c0:	e56fc0ef          	jal	80001916 <myproc>
    800052c4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800052c6:	fd840593          	addi	a1,s0,-40
    800052ca:	4501                	li	a0,0
    800052cc:	d74fd0ef          	jal	80002840 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800052d0:	fc840593          	addi	a1,s0,-56
    800052d4:	fd040513          	addi	a0,s0,-48
    800052d8:	852ff0ef          	jal	8000432a <pipealloc>
    return -1;
    800052dc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800052de:	0a054463          	bltz	a0,80005386 <sys_pipe+0xd0>
  fd0 = -1;
    800052e2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800052e6:	fd043503          	ld	a0,-48(s0)
    800052ea:	f08ff0ef          	jal	800049f2 <fdalloc>
    800052ee:	fca42223          	sw	a0,-60(s0)
    800052f2:	08054163          	bltz	a0,80005374 <sys_pipe+0xbe>
    800052f6:	fc843503          	ld	a0,-56(s0)
    800052fa:	ef8ff0ef          	jal	800049f2 <fdalloc>
    800052fe:	fca42023          	sw	a0,-64(s0)
    80005302:	06054063          	bltz	a0,80005362 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005306:	4691                	li	a3,4
    80005308:	fc440613          	addi	a2,s0,-60
    8000530c:	fd843583          	ld	a1,-40(s0)
    80005310:	68a8                	ld	a0,80(s1)
    80005312:	b18fc0ef          	jal	8000162a <copyout>
    80005316:	00054e63          	bltz	a0,80005332 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000531a:	4691                	li	a3,4
    8000531c:	fc040613          	addi	a2,s0,-64
    80005320:	fd843583          	ld	a1,-40(s0)
    80005324:	0591                	addi	a1,a1,4
    80005326:	68a8                	ld	a0,80(s1)
    80005328:	b02fc0ef          	jal	8000162a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000532c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000532e:	04055c63          	bgez	a0,80005386 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005332:	fc442783          	lw	a5,-60(s0)
    80005336:	07e9                	addi	a5,a5,26
    80005338:	078e                	slli	a5,a5,0x3
    8000533a:	97a6                	add	a5,a5,s1
    8000533c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005340:	fc042783          	lw	a5,-64(s0)
    80005344:	07e9                	addi	a5,a5,26
    80005346:	078e                	slli	a5,a5,0x3
    80005348:	94be                	add	s1,s1,a5
    8000534a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000534e:	fd043503          	ld	a0,-48(s0)
    80005352:	ccffe0ef          	jal	80004020 <fileclose>
    fileclose(wf);
    80005356:	fc843503          	ld	a0,-56(s0)
    8000535a:	cc7fe0ef          	jal	80004020 <fileclose>
    return -1;
    8000535e:	57fd                	li	a5,-1
    80005360:	a01d                	j	80005386 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005362:	fc442783          	lw	a5,-60(s0)
    80005366:	0007c763          	bltz	a5,80005374 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000536a:	07e9                	addi	a5,a5,26
    8000536c:	078e                	slli	a5,a5,0x3
    8000536e:	97a6                	add	a5,a5,s1
    80005370:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005374:	fd043503          	ld	a0,-48(s0)
    80005378:	ca9fe0ef          	jal	80004020 <fileclose>
    fileclose(wf);
    8000537c:	fc843503          	ld	a0,-56(s0)
    80005380:	ca1fe0ef          	jal	80004020 <fileclose>
    return -1;
    80005384:	57fd                	li	a5,-1
}
    80005386:	853e                	mv	a0,a5
    80005388:	70e2                	ld	ra,56(sp)
    8000538a:	7442                	ld	s0,48(sp)
    8000538c:	74a2                	ld	s1,40(sp)
    8000538e:	6121                	addi	sp,sp,64
    80005390:	8082                	ret
	...

00000000800053a0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800053a0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800053a2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800053a4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800053a6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800053a8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800053aa:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800053ac:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800053ae:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800053b0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800053b2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800053b4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800053b6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800053b8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800053ba:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800053bc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800053be:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800053c0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800053c2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800053c4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800053c6:	ae4fd0ef          	jal	800026aa <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800053ca:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800053cc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800053ce:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800053d0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800053d2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800053d4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800053d6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800053d8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800053da:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800053dc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800053de:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800053e0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800053e2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800053e4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800053e6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800053e8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800053ea:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800053ec:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800053ee:	10200073          	sret
	...

00000000800053fe <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800053fe:	1141                	addi	sp,sp,-16
    80005400:	e422                	sd	s0,8(sp)
    80005402:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005404:	0c0007b7          	lui	a5,0xc000
    80005408:	4705                	li	a4,1
    8000540a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000540c:	0c0007b7          	lui	a5,0xc000
    80005410:	c3d8                	sw	a4,4(a5)
}
    80005412:	6422                	ld	s0,8(sp)
    80005414:	0141                	addi	sp,sp,16
    80005416:	8082                	ret

0000000080005418 <plicinithart>:

void
plicinithart(void)
{
    80005418:	1141                	addi	sp,sp,-16
    8000541a:	e406                	sd	ra,8(sp)
    8000541c:	e022                	sd	s0,0(sp)
    8000541e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005420:	ccafc0ef          	jal	800018ea <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005424:	0085171b          	slliw	a4,a0,0x8
    80005428:	0c0027b7          	lui	a5,0xc002
    8000542c:	97ba                	add	a5,a5,a4
    8000542e:	40200713          	li	a4,1026
    80005432:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005436:	00d5151b          	slliw	a0,a0,0xd
    8000543a:	0c2017b7          	lui	a5,0xc201
    8000543e:	97aa                	add	a5,a5,a0
    80005440:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005444:	60a2                	ld	ra,8(sp)
    80005446:	6402                	ld	s0,0(sp)
    80005448:	0141                	addi	sp,sp,16
    8000544a:	8082                	ret

000000008000544c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000544c:	1141                	addi	sp,sp,-16
    8000544e:	e406                	sd	ra,8(sp)
    80005450:	e022                	sd	s0,0(sp)
    80005452:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005454:	c96fc0ef          	jal	800018ea <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005458:	00d5151b          	slliw	a0,a0,0xd
    8000545c:	0c2017b7          	lui	a5,0xc201
    80005460:	97aa                	add	a5,a5,a0
  return irq;
}
    80005462:	43c8                	lw	a0,4(a5)
    80005464:	60a2                	ld	ra,8(sp)
    80005466:	6402                	ld	s0,0(sp)
    80005468:	0141                	addi	sp,sp,16
    8000546a:	8082                	ret

000000008000546c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000546c:	1101                	addi	sp,sp,-32
    8000546e:	ec06                	sd	ra,24(sp)
    80005470:	e822                	sd	s0,16(sp)
    80005472:	e426                	sd	s1,8(sp)
    80005474:	1000                	addi	s0,sp,32
    80005476:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005478:	c72fc0ef          	jal	800018ea <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000547c:	00d5151b          	slliw	a0,a0,0xd
    80005480:	0c2017b7          	lui	a5,0xc201
    80005484:	97aa                	add	a5,a5,a0
    80005486:	c3c4                	sw	s1,4(a5)
}
    80005488:	60e2                	ld	ra,24(sp)
    8000548a:	6442                	ld	s0,16(sp)
    8000548c:	64a2                	ld	s1,8(sp)
    8000548e:	6105                	addi	sp,sp,32
    80005490:	8082                	ret

0000000080005492 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005492:	1141                	addi	sp,sp,-16
    80005494:	e406                	sd	ra,8(sp)
    80005496:	e022                	sd	s0,0(sp)
    80005498:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000549a:	479d                	li	a5,7
    8000549c:	04a7ca63          	blt	a5,a0,800054f0 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800054a0:	0001e797          	auipc	a5,0x1e
    800054a4:	ef878793          	addi	a5,a5,-264 # 80023398 <disk>
    800054a8:	97aa                	add	a5,a5,a0
    800054aa:	0187c783          	lbu	a5,24(a5)
    800054ae:	e7b9                	bnez	a5,800054fc <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800054b0:	00451693          	slli	a3,a0,0x4
    800054b4:	0001e797          	auipc	a5,0x1e
    800054b8:	ee478793          	addi	a5,a5,-284 # 80023398 <disk>
    800054bc:	6398                	ld	a4,0(a5)
    800054be:	9736                	add	a4,a4,a3
    800054c0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800054c4:	6398                	ld	a4,0(a5)
    800054c6:	9736                	add	a4,a4,a3
    800054c8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800054cc:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800054d0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800054d4:	97aa                	add	a5,a5,a0
    800054d6:	4705                	li	a4,1
    800054d8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800054dc:	0001e517          	auipc	a0,0x1e
    800054e0:	ed450513          	addi	a0,a0,-300 # 800233b0 <disk+0x18>
    800054e4:	a89fc0ef          	jal	80001f6c <wakeup>
}
    800054e8:	60a2                	ld	ra,8(sp)
    800054ea:	6402                	ld	s0,0(sp)
    800054ec:	0141                	addi	sp,sp,16
    800054ee:	8082                	ret
    panic("free_desc 1");
    800054f0:	00002517          	auipc	a0,0x2
    800054f4:	12050513          	addi	a0,a0,288 # 80007610 <etext+0x610>
    800054f8:	ae8fb0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    800054fc:	00002517          	auipc	a0,0x2
    80005500:	12450513          	addi	a0,a0,292 # 80007620 <etext+0x620>
    80005504:	adcfb0ef          	jal	800007e0 <panic>

0000000080005508 <virtio_disk_init>:
{
    80005508:	1101                	addi	sp,sp,-32
    8000550a:	ec06                	sd	ra,24(sp)
    8000550c:	e822                	sd	s0,16(sp)
    8000550e:	e426                	sd	s1,8(sp)
    80005510:	e04a                	sd	s2,0(sp)
    80005512:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005514:	00002597          	auipc	a1,0x2
    80005518:	11c58593          	addi	a1,a1,284 # 80007630 <etext+0x630>
    8000551c:	0001e517          	auipc	a0,0x1e
    80005520:	fa450513          	addi	a0,a0,-92 # 800234c0 <disk+0x128>
    80005524:	e72fb0ef          	jal	80000b96 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005528:	100017b7          	lui	a5,0x10001
    8000552c:	4398                	lw	a4,0(a5)
    8000552e:	2701                	sext.w	a4,a4
    80005530:	747277b7          	lui	a5,0x74727
    80005534:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005538:	18f71063          	bne	a4,a5,800056b8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000553c:	100017b7          	lui	a5,0x10001
    80005540:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005542:	439c                	lw	a5,0(a5)
    80005544:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005546:	4709                	li	a4,2
    80005548:	16e79863          	bne	a5,a4,800056b8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000554c:	100017b7          	lui	a5,0x10001
    80005550:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005552:	439c                	lw	a5,0(a5)
    80005554:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005556:	16e79163          	bne	a5,a4,800056b8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000555a:	100017b7          	lui	a5,0x10001
    8000555e:	47d8                	lw	a4,12(a5)
    80005560:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005562:	554d47b7          	lui	a5,0x554d4
    80005566:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000556a:	14f71763          	bne	a4,a5,800056b8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000556e:	100017b7          	lui	a5,0x10001
    80005572:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005576:	4705                	li	a4,1
    80005578:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000557a:	470d                	li	a4,3
    8000557c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000557e:	10001737          	lui	a4,0x10001
    80005582:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005584:	c7ffe737          	lui	a4,0xc7ffe
    80005588:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb287>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000558c:	8ef9                	and	a3,a3,a4
    8000558e:	10001737          	lui	a4,0x10001
    80005592:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005594:	472d                	li	a4,11
    80005596:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005598:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000559c:	439c                	lw	a5,0(a5)
    8000559e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800055a2:	8ba1                	andi	a5,a5,8
    800055a4:	12078063          	beqz	a5,800056c4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800055a8:	100017b7          	lui	a5,0x10001
    800055ac:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800055b0:	100017b7          	lui	a5,0x10001
    800055b4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800055b8:	439c                	lw	a5,0(a5)
    800055ba:	2781                	sext.w	a5,a5
    800055bc:	10079a63          	bnez	a5,800056d0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800055c0:	100017b7          	lui	a5,0x10001
    800055c4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800055c8:	439c                	lw	a5,0(a5)
    800055ca:	2781                	sext.w	a5,a5
  if(max == 0)
    800055cc:	10078863          	beqz	a5,800056dc <virtio_disk_init+0x1d4>
  if(max < NUM)
    800055d0:	471d                	li	a4,7
    800055d2:	10f77b63          	bgeu	a4,a5,800056e8 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800055d6:	d64fb0ef          	jal	80000b3a <kalloc>
    800055da:	0001e497          	auipc	s1,0x1e
    800055de:	dbe48493          	addi	s1,s1,-578 # 80023398 <disk>
    800055e2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800055e4:	d56fb0ef          	jal	80000b3a <kalloc>
    800055e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800055ea:	d50fb0ef          	jal	80000b3a <kalloc>
    800055ee:	87aa                	mv	a5,a0
    800055f0:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800055f2:	6088                	ld	a0,0(s1)
    800055f4:	10050063          	beqz	a0,800056f4 <virtio_disk_init+0x1ec>
    800055f8:	0001e717          	auipc	a4,0x1e
    800055fc:	da873703          	ld	a4,-600(a4) # 800233a0 <disk+0x8>
    80005600:	0e070a63          	beqz	a4,800056f4 <virtio_disk_init+0x1ec>
    80005604:	0e078863          	beqz	a5,800056f4 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005608:	6605                	lui	a2,0x1
    8000560a:	4581                	li	a1,0
    8000560c:	edefb0ef          	jal	80000cea <memset>
  memset(disk.avail, 0, PGSIZE);
    80005610:	0001e497          	auipc	s1,0x1e
    80005614:	d8848493          	addi	s1,s1,-632 # 80023398 <disk>
    80005618:	6605                	lui	a2,0x1
    8000561a:	4581                	li	a1,0
    8000561c:	6488                	ld	a0,8(s1)
    8000561e:	eccfb0ef          	jal	80000cea <memset>
  memset(disk.used, 0, PGSIZE);
    80005622:	6605                	lui	a2,0x1
    80005624:	4581                	li	a1,0
    80005626:	6888                	ld	a0,16(s1)
    80005628:	ec2fb0ef          	jal	80000cea <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000562c:	100017b7          	lui	a5,0x10001
    80005630:	4721                	li	a4,8
    80005632:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005634:	4098                	lw	a4,0(s1)
    80005636:	100017b7          	lui	a5,0x10001
    8000563a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000563e:	40d8                	lw	a4,4(s1)
    80005640:	100017b7          	lui	a5,0x10001
    80005644:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005648:	649c                	ld	a5,8(s1)
    8000564a:	0007869b          	sext.w	a3,a5
    8000564e:	10001737          	lui	a4,0x10001
    80005652:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005656:	9781                	srai	a5,a5,0x20
    80005658:	10001737          	lui	a4,0x10001
    8000565c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005660:	689c                	ld	a5,16(s1)
    80005662:	0007869b          	sext.w	a3,a5
    80005666:	10001737          	lui	a4,0x10001
    8000566a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000566e:	9781                	srai	a5,a5,0x20
    80005670:	10001737          	lui	a4,0x10001
    80005674:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005678:	10001737          	lui	a4,0x10001
    8000567c:	4785                	li	a5,1
    8000567e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005680:	00f48c23          	sb	a5,24(s1)
    80005684:	00f48ca3          	sb	a5,25(s1)
    80005688:	00f48d23          	sb	a5,26(s1)
    8000568c:	00f48da3          	sb	a5,27(s1)
    80005690:	00f48e23          	sb	a5,28(s1)
    80005694:	00f48ea3          	sb	a5,29(s1)
    80005698:	00f48f23          	sb	a5,30(s1)
    8000569c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800056a0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800056a4:	100017b7          	lui	a5,0x10001
    800056a8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800056ac:	60e2                	ld	ra,24(sp)
    800056ae:	6442                	ld	s0,16(sp)
    800056b0:	64a2                	ld	s1,8(sp)
    800056b2:	6902                	ld	s2,0(sp)
    800056b4:	6105                	addi	sp,sp,32
    800056b6:	8082                	ret
    panic("could not find virtio disk");
    800056b8:	00002517          	auipc	a0,0x2
    800056bc:	f8850513          	addi	a0,a0,-120 # 80007640 <etext+0x640>
    800056c0:	920fb0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    800056c4:	00002517          	auipc	a0,0x2
    800056c8:	f9c50513          	addi	a0,a0,-100 # 80007660 <etext+0x660>
    800056cc:	914fb0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    800056d0:	00002517          	auipc	a0,0x2
    800056d4:	fb050513          	addi	a0,a0,-80 # 80007680 <etext+0x680>
    800056d8:	908fb0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    800056dc:	00002517          	auipc	a0,0x2
    800056e0:	fc450513          	addi	a0,a0,-60 # 800076a0 <etext+0x6a0>
    800056e4:	8fcfb0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    800056e8:	00002517          	auipc	a0,0x2
    800056ec:	fd850513          	addi	a0,a0,-40 # 800076c0 <etext+0x6c0>
    800056f0:	8f0fb0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    800056f4:	00002517          	auipc	a0,0x2
    800056f8:	fec50513          	addi	a0,a0,-20 # 800076e0 <etext+0x6e0>
    800056fc:	8e4fb0ef          	jal	800007e0 <panic>

0000000080005700 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005700:	7159                	addi	sp,sp,-112
    80005702:	f486                	sd	ra,104(sp)
    80005704:	f0a2                	sd	s0,96(sp)
    80005706:	eca6                	sd	s1,88(sp)
    80005708:	e8ca                	sd	s2,80(sp)
    8000570a:	e4ce                	sd	s3,72(sp)
    8000570c:	e0d2                	sd	s4,64(sp)
    8000570e:	fc56                	sd	s5,56(sp)
    80005710:	f85a                	sd	s6,48(sp)
    80005712:	f45e                	sd	s7,40(sp)
    80005714:	f062                	sd	s8,32(sp)
    80005716:	ec66                	sd	s9,24(sp)
    80005718:	1880                	addi	s0,sp,112
    8000571a:	8a2a                	mv	s4,a0
    8000571c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000571e:	00c52c83          	lw	s9,12(a0)
    80005722:	001c9c9b          	slliw	s9,s9,0x1
    80005726:	1c82                	slli	s9,s9,0x20
    80005728:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000572c:	0001e517          	auipc	a0,0x1e
    80005730:	d9450513          	addi	a0,a0,-620 # 800234c0 <disk+0x128>
    80005734:	ce2fb0ef          	jal	80000c16 <acquire>
  for(int i = 0; i < 3; i++){
    80005738:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000573a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000573c:	0001eb17          	auipc	s6,0x1e
    80005740:	c5cb0b13          	addi	s6,s6,-932 # 80023398 <disk>
  for(int i = 0; i < 3; i++){
    80005744:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005746:	0001ec17          	auipc	s8,0x1e
    8000574a:	d7ac0c13          	addi	s8,s8,-646 # 800234c0 <disk+0x128>
    8000574e:	a8b9                	j	800057ac <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005750:	00fb0733          	add	a4,s6,a5
    80005754:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005758:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000575a:	0207c563          	bltz	a5,80005784 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    8000575e:	2905                	addiw	s2,s2,1
    80005760:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005762:	05590963          	beq	s2,s5,800057b4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005766:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005768:	0001e717          	auipc	a4,0x1e
    8000576c:	c3070713          	addi	a4,a4,-976 # 80023398 <disk>
    80005770:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005772:	01874683          	lbu	a3,24(a4)
    80005776:	fee9                	bnez	a3,80005750 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005778:	2785                	addiw	a5,a5,1
    8000577a:	0705                	addi	a4,a4,1
    8000577c:	fe979be3          	bne	a5,s1,80005772 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005780:	57fd                	li	a5,-1
    80005782:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005784:	01205d63          	blez	s2,8000579e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005788:	f9042503          	lw	a0,-112(s0)
    8000578c:	d07ff0ef          	jal	80005492 <free_desc>
      for(int j = 0; j < i; j++)
    80005790:	4785                	li	a5,1
    80005792:	0127d663          	bge	a5,s2,8000579e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005796:	f9442503          	lw	a0,-108(s0)
    8000579a:	cf9ff0ef          	jal	80005492 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000579e:	85e2                	mv	a1,s8
    800057a0:	0001e517          	auipc	a0,0x1e
    800057a4:	c1050513          	addi	a0,a0,-1008 # 800233b0 <disk+0x18>
    800057a8:	f78fc0ef          	jal	80001f20 <sleep>
  for(int i = 0; i < 3; i++){
    800057ac:	f9040613          	addi	a2,s0,-112
    800057b0:	894e                	mv	s2,s3
    800057b2:	bf55                	j	80005766 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800057b4:	f9042503          	lw	a0,-112(s0)
    800057b8:	00451693          	slli	a3,a0,0x4

  if(write)
    800057bc:	0001e797          	auipc	a5,0x1e
    800057c0:	bdc78793          	addi	a5,a5,-1060 # 80023398 <disk>
    800057c4:	00a50713          	addi	a4,a0,10
    800057c8:	0712                	slli	a4,a4,0x4
    800057ca:	973e                	add	a4,a4,a5
    800057cc:	01703633          	snez	a2,s7
    800057d0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800057d2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800057d6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800057da:	6398                	ld	a4,0(a5)
    800057dc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800057de:	0a868613          	addi	a2,a3,168
    800057e2:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800057e4:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800057e6:	6390                	ld	a2,0(a5)
    800057e8:	00d605b3          	add	a1,a2,a3
    800057ec:	4741                	li	a4,16
    800057ee:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800057f0:	4805                	li	a6,1
    800057f2:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    800057f6:	f9442703          	lw	a4,-108(s0)
    800057fa:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800057fe:	0712                	slli	a4,a4,0x4
    80005800:	963a                	add	a2,a2,a4
    80005802:	058a0593          	addi	a1,s4,88
    80005806:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005808:	0007b883          	ld	a7,0(a5)
    8000580c:	9746                	add	a4,a4,a7
    8000580e:	40000613          	li	a2,1024
    80005812:	c710                	sw	a2,8(a4)
  if(write)
    80005814:	001bb613          	seqz	a2,s7
    80005818:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000581c:	00166613          	ori	a2,a2,1
    80005820:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005824:	f9842583          	lw	a1,-104(s0)
    80005828:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000582c:	00250613          	addi	a2,a0,2
    80005830:	0612                	slli	a2,a2,0x4
    80005832:	963e                	add	a2,a2,a5
    80005834:	577d                	li	a4,-1
    80005836:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000583a:	0592                	slli	a1,a1,0x4
    8000583c:	98ae                	add	a7,a7,a1
    8000583e:	03068713          	addi	a4,a3,48
    80005842:	973e                	add	a4,a4,a5
    80005844:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005848:	6398                	ld	a4,0(a5)
    8000584a:	972e                	add	a4,a4,a1
    8000584c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005850:	4689                	li	a3,2
    80005852:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005856:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000585a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    8000585e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005862:	6794                	ld	a3,8(a5)
    80005864:	0026d703          	lhu	a4,2(a3)
    80005868:	8b1d                	andi	a4,a4,7
    8000586a:	0706                	slli	a4,a4,0x1
    8000586c:	96ba                	add	a3,a3,a4
    8000586e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005872:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005876:	6798                	ld	a4,8(a5)
    80005878:	00275783          	lhu	a5,2(a4)
    8000587c:	2785                	addiw	a5,a5,1
    8000587e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005882:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005886:	100017b7          	lui	a5,0x10001
    8000588a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000588e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005892:	0001e917          	auipc	s2,0x1e
    80005896:	c2e90913          	addi	s2,s2,-978 # 800234c0 <disk+0x128>
  while(b->disk == 1) {
    8000589a:	4485                	li	s1,1
    8000589c:	01079a63          	bne	a5,a6,800058b0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    800058a0:	85ca                	mv	a1,s2
    800058a2:	8552                	mv	a0,s4
    800058a4:	e7cfc0ef          	jal	80001f20 <sleep>
  while(b->disk == 1) {
    800058a8:	004a2783          	lw	a5,4(s4)
    800058ac:	fe978ae3          	beq	a5,s1,800058a0 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    800058b0:	f9042903          	lw	s2,-112(s0)
    800058b4:	00290713          	addi	a4,s2,2
    800058b8:	0712                	slli	a4,a4,0x4
    800058ba:	0001e797          	auipc	a5,0x1e
    800058be:	ade78793          	addi	a5,a5,-1314 # 80023398 <disk>
    800058c2:	97ba                	add	a5,a5,a4
    800058c4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800058c8:	0001e997          	auipc	s3,0x1e
    800058cc:	ad098993          	addi	s3,s3,-1328 # 80023398 <disk>
    800058d0:	00491713          	slli	a4,s2,0x4
    800058d4:	0009b783          	ld	a5,0(s3)
    800058d8:	97ba                	add	a5,a5,a4
    800058da:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800058de:	854a                	mv	a0,s2
    800058e0:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800058e4:	bafff0ef          	jal	80005492 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800058e8:	8885                	andi	s1,s1,1
    800058ea:	f0fd                	bnez	s1,800058d0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800058ec:	0001e517          	auipc	a0,0x1e
    800058f0:	bd450513          	addi	a0,a0,-1068 # 800234c0 <disk+0x128>
    800058f4:	bbafb0ef          	jal	80000cae <release>
}
    800058f8:	70a6                	ld	ra,104(sp)
    800058fa:	7406                	ld	s0,96(sp)
    800058fc:	64e6                	ld	s1,88(sp)
    800058fe:	6946                	ld	s2,80(sp)
    80005900:	69a6                	ld	s3,72(sp)
    80005902:	6a06                	ld	s4,64(sp)
    80005904:	7ae2                	ld	s5,56(sp)
    80005906:	7b42                	ld	s6,48(sp)
    80005908:	7ba2                	ld	s7,40(sp)
    8000590a:	7c02                	ld	s8,32(sp)
    8000590c:	6ce2                	ld	s9,24(sp)
    8000590e:	6165                	addi	sp,sp,112
    80005910:	8082                	ret

0000000080005912 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005912:	1101                	addi	sp,sp,-32
    80005914:	ec06                	sd	ra,24(sp)
    80005916:	e822                	sd	s0,16(sp)
    80005918:	e426                	sd	s1,8(sp)
    8000591a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000591c:	0001e497          	auipc	s1,0x1e
    80005920:	a7c48493          	addi	s1,s1,-1412 # 80023398 <disk>
    80005924:	0001e517          	auipc	a0,0x1e
    80005928:	b9c50513          	addi	a0,a0,-1124 # 800234c0 <disk+0x128>
    8000592c:	aeafb0ef          	jal	80000c16 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005930:	100017b7          	lui	a5,0x10001
    80005934:	53b8                	lw	a4,96(a5)
    80005936:	8b0d                	andi	a4,a4,3
    80005938:	100017b7          	lui	a5,0x10001
    8000593c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    8000593e:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005942:	689c                	ld	a5,16(s1)
    80005944:	0204d703          	lhu	a4,32(s1)
    80005948:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    8000594c:	04f70663          	beq	a4,a5,80005998 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005950:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005954:	6898                	ld	a4,16(s1)
    80005956:	0204d783          	lhu	a5,32(s1)
    8000595a:	8b9d                	andi	a5,a5,7
    8000595c:	078e                	slli	a5,a5,0x3
    8000595e:	97ba                	add	a5,a5,a4
    80005960:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005962:	00278713          	addi	a4,a5,2
    80005966:	0712                	slli	a4,a4,0x4
    80005968:	9726                	add	a4,a4,s1
    8000596a:	01074703          	lbu	a4,16(a4)
    8000596e:	e321                	bnez	a4,800059ae <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005970:	0789                	addi	a5,a5,2
    80005972:	0792                	slli	a5,a5,0x4
    80005974:	97a6                	add	a5,a5,s1
    80005976:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005978:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000597c:	df0fc0ef          	jal	80001f6c <wakeup>

    disk.used_idx += 1;
    80005980:	0204d783          	lhu	a5,32(s1)
    80005984:	2785                	addiw	a5,a5,1
    80005986:	17c2                	slli	a5,a5,0x30
    80005988:	93c1                	srli	a5,a5,0x30
    8000598a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000598e:	6898                	ld	a4,16(s1)
    80005990:	00275703          	lhu	a4,2(a4)
    80005994:	faf71ee3          	bne	a4,a5,80005950 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005998:	0001e517          	auipc	a0,0x1e
    8000599c:	b2850513          	addi	a0,a0,-1240 # 800234c0 <disk+0x128>
    800059a0:	b0efb0ef          	jal	80000cae <release>
}
    800059a4:	60e2                	ld	ra,24(sp)
    800059a6:	6442                	ld	s0,16(sp)
    800059a8:	64a2                	ld	s1,8(sp)
    800059aa:	6105                	addi	sp,sp,32
    800059ac:	8082                	ret
      panic("virtio_disk_intr status");
    800059ae:	00002517          	auipc	a0,0x2
    800059b2:	d4a50513          	addi	a0,a0,-694 # 800076f8 <etext+0x6f8>
    800059b6:	e2bfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
