
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
    80000004:	89010113          	addi	sp,sp,-1904 # 80007890 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc467>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
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
    80000112:	436020ef          	jal	80002548 <either_copyin>
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
    8000018c:	0000f517          	auipc	a0,0xf
    80000190:	70450513          	addi	a0,a0,1796 # 8000f890 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	0000f497          	auipc	s1,0xf
    8000019c:	6f848493          	addi	s1,s1,1784 # 8000f890 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	0000f917          	auipc	s2,0xf
    800001a4:	78890913          	addi	s2,s2,1928 # 8000f928 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	716010ef          	jal	800018ce <myproc>
    800001bc:	21e020ef          	jal	800023da <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	7d9010ef          	jal	8000219e <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	0000f717          	auipc	a4,0xf
    800001dc:	6b870713          	addi	a4,a4,1720 # 8000f890 <cons>
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
    8000020a:	2f4020ef          	jal	800024fe <either_copyout>
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
    80000222:	0000f517          	auipc	a0,0xf
    80000226:	66e50513          	addi	a0,a0,1646 # 8000f890 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
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
    8000024c:	0000f717          	auipc	a4,0xf
    80000250:	6cf72e23          	sw	a5,1756(a4) # 8000f928 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	0000f517          	auipc	a0,0xf
    80000266:	62e50513          	addi	a0,a0,1582 # 8000f890 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
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
    800002b6:	0000f517          	auipc	a0,0xf
    800002ba:	5da50513          	addi	a0,a0,1498 # 8000f890 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

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
    800002d8:	2ba020ef          	jal	80002592 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	0000f517          	auipc	a0,0xf
    800002e0:	5b450513          	addi	a0,a0,1460 # 8000f890 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
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
    800002fa:	0000f717          	auipc	a4,0xf
    800002fe:	59670713          	addi	a4,a4,1430 # 8000f890 <cons>
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
    80000320:	0000f797          	auipc	a5,0xf
    80000324:	57078793          	addi	a5,a5,1392 # 8000f890 <cons>
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
    8000034e:	0000f797          	auipc	a5,0xf
    80000352:	5da7a783          	lw	a5,1498(a5) # 8000f928 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	0000f717          	auipc	a4,0xf
    80000368:	52c70713          	addi	a4,a4,1324 # 8000f890 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	0000f497          	auipc	s1,0xf
    80000378:	51c48493          	addi	s1,s1,1308 # 8000f890 <cons>
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
    800003b6:	0000f717          	auipc	a4,0xf
    800003ba:	4da70713          	addi	a4,a4,1242 # 8000f890 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	0000f717          	auipc	a4,0xf
    800003d0:	56f72223          	sw	a5,1380(a4) # 8000f930 <cons+0xa0>
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
    800003ea:	0000f797          	auipc	a5,0xf
    800003ee:	4a678793          	addi	a5,a5,1190 # 8000f890 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	0000f797          	auipc	a5,0xf
    80000412:	50c7af23          	sw	a2,1310(a5) # 8000f92c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	0000f517          	auipc	a0,0xf
    8000041a:	51250513          	addi	a0,a0,1298 # 8000f928 <cons+0x98>
    8000041e:	5d1010ef          	jal	800021ee <wakeup>
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
    80000434:	0000f517          	auipc	a0,0xf
    80000438:	45c50513          	addi	a0,a0,1116 # 8000f890 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00021797          	auipc	a5,0x21
    80000448:	dbc78793          	addi	a5,a5,-580 # 80021200 <devsw>
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
    80000482:	2a260613          	addi	a2,a2,674 # 80007720 <digits>
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
    80000518:	00007797          	auipc	a5,0x7
    8000051c:	33c7a783          	lw	a5,828(a5) # 80007854 <panicking>
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
    80000560:	0000f517          	auipc	a0,0xf
    80000564:	3d850513          	addi	a0,a0,984 # 8000f938 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
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
    8000072c:	ff8b8b93          	addi	s7,s7,-8 # 80007720 <digits>
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
    800007bc:	00007797          	auipc	a5,0x7
    800007c0:	0987a783          	lw	a5,152(a5) # 80007854 <panicking>
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
    800007d2:	0000f517          	auipc	a0,0xf
    800007d6:	16650513          	addi	a0,a0,358 # 8000f938 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
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
    800007f0:	00007797          	auipc	a5,0x7
    800007f4:	0727a223          	sw	s2,100(a5) # 80007854 <panicking>
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
    80000812:	00007797          	auipc	a5,0x7
    80000816:	0327af23          	sw	s2,62(a5) # 80007850 <panicked>
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
    8000082c:	0000f517          	auipc	a0,0xf
    80000830:	10c50513          	addi	a0,a0,268 # 8000f938 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
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
    80000884:	0000f517          	auipc	a0,0xf
    80000888:	0cc50513          	addi	a0,a0,204 # 8000f950 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
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
    800008a8:	0000f517          	auipc	a0,0xf
    800008ac:	0a850513          	addi	a0,a0,168 # 8000f950 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

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
    800008c6:	00007497          	auipc	s1,0x7
    800008ca:	f9648493          	addi	s1,s1,-106 # 8000785c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	0000f997          	auipc	s3,0xf
    800008d2:	08298993          	addi	s3,s3,130 # 8000f950 <tx_lock>
    800008d6:	00007917          	auipc	s2,0x7
    800008da:	f8290913          	addi	s2,s2,-126 # 80007858 <tx_chan>
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
    800008ea:	0b5010ef          	jal	8000219e <sleep>
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
    80000914:	0000f517          	auipc	a0,0xf
    80000918:	03c50513          	addi	a0,a0,60 # 8000f950 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
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
    80000938:	00007797          	auipc	a5,0x7
    8000093c:	f1c7a783          	lw	a5,-228(a5) # 80007854 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	00007797          	auipc	a5,0x7
    80000946:	f0e7a783          	lw	a5,-242(a5) # 80007850 <panicked>
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
    80000968:	00007797          	auipc	a5,0x7
    8000096c:	eec7a783          	lw	a5,-276(a5) # 80007854 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
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
    800009c4:	0000f517          	auipc	a0,0xf
    800009c8:	f8c50513          	addi	a0,a0,-116 # 8000f950 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
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
    800009e0:	0000f517          	auipc	a0,0xf
    800009e4:	f7050513          	addi	a0,a0,-144 # 8000f950 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	00007797          	auipc	a5,0x7
    800009f4:	e607a623          	sw	zero,-404(a5) # 8000785c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	00007517          	auipc	a0,0x7
    800009fc:	e6050513          	addi	a0,a0,-416 # 80007858 <tx_chan>
    80000a00:	7ee010ef          	jal	800021ee <wakeup>
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
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00022797          	auipc	a5,0x22
    80000a34:	96878793          	addi	a5,a5,-1688 # 80022398 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	0000f917          	auipc	s2,0xf
    80000a50:	f1c90913          	addi	s2,s2,-228 # 8000f968 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	0000f517          	auipc	a0,0xf
    80000ade:	e8e50513          	addi	a0,a0,-370 # 8000f968 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00022517          	auipc	a0,0x22
    80000aee:	8ae50513          	addi	a0,a0,-1874 # 80022398 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
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
    80000b08:	0000f497          	auipc	s1,0xf
    80000b0c:	e6048493          	addi	s1,s1,-416 # 8000f968 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	0000f517          	auipc	a0,0xf
    80000b20:	e4c50513          	addi	a0,a0,-436 # 8000f968 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	0000f517          	auipc	a0,0xf
    80000b44:	e2850513          	addi	a0,a0,-472 # 8000f968 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	53b000ef          	jal	800018b2 <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	50d000ef          	jal	800018b2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	505000ef          	jal	800018b2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	4f1000ef          	jal	800018b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf6:	4bd000ef          	jal	800018b2 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00006517          	auipc	a0,0x6
    80000c0a:	44250513          	addi	a0,a0,1090 # 80007048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	499000ef          	jal	800018b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	40250513          	addi	a0,a0,1026 # 80007050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00006517          	auipc	a0,0x6
    80000c5e:	40e50513          	addi	a0,a0,1038 # 80007068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c80:	0f50000f          	fence	iorw,ow
    80000c84:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3da50513          	addi	a0,a0,986 # 80007070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcc69>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	25f000ef          	jal	800018a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	00007717          	auipc	a4,0x7
    80000e4c:	a1870713          	addi	a4,a4,-1512 # 80007860 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e5c:	247000ef          	jal	800018a2 <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00006517          	auipc	a0,0x6
    80000e66:	23650513          	addi	a0,a0,566 # 80007098 <etext+0x98>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	080000ef          	jal	80000eee <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	103010ef          	jal	80002774 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	383040ef          	jal	800059f8 <plicinithart>
  }

  scheduler();        
    80000e7a:	038010ef          	jal	80001eb2 <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00006517          	auipc	a0,0x6
    80000e8a:	1f250513          	addi	a0,a0,498 # 80007078 <etext+0x78>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00006517          	auipc	a0,0x6
    80000e96:	1ee50513          	addi	a0,a0,494 # 80007080 <etext+0x80>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00006517          	auipc	a0,0x6
    80000ea2:	1da50513          	addi	a0,a0,474 # 80007078 <etext+0x78>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2ca000ef          	jal	80001178 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	03c000ef          	jal	80000eee <kvminithart>
    procinit();      // process table
    80000eb6:	137000ef          	jal	800017ec <procinit>
    trapinit();      // trap vectors
    80000eba:	097010ef          	jal	80002750 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	0b7010ef          	jal	80002774 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	31d040ef          	jal	800059de <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	333040ef          	jal	800059f8 <plicinithart>
    binit();         // buffer cache
    80000eca:	1fa020ef          	jal	800030c4 <binit>
    iinit();         // inode table
    80000ece:	780020ef          	jal	8000364e <iinit>
    fileinit();      // file table
    80000ed2:	672030ef          	jal	80004544 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	413040ef          	jal	80005ae8 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	533000ef          	jal	80001c0c <userinit>
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00007717          	auipc	a4,0x7
    80000ee8:	96f72e23          	sw	a5,-1668(a4) # 80007860 <started>
    80000eec:	b779                	j	80000e7a <main+0x3e>

0000000080000eee <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ef4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ef8:	00007797          	auipc	a5,0x7
    80000efc:	9707b783          	ld	a5,-1680(a5) # 80007868 <kernel_pagetable>
    80000f00:	83b1                	srli	a5,a5,0xc
    80000f02:	577d                	li	a4,-1
    80000f04:	177e                	slli	a4,a4,0x3f
    80000f06:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f08:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f16:	7139                	addi	sp,sp,-64
    80000f18:	fc06                	sd	ra,56(sp)
    80000f1a:	f822                	sd	s0,48(sp)
    80000f1c:	f426                	sd	s1,40(sp)
    80000f1e:	f04a                	sd	s2,32(sp)
    80000f20:	ec4e                	sd	s3,24(sp)
    80000f22:	e852                	sd	s4,16(sp)
    80000f24:	e456                	sd	s5,8(sp)
    80000f26:	e05a                	sd	s6,0(sp)
    80000f28:	0080                	addi	s0,sp,64
    80000f2a:	84aa                	mv	s1,a0
    80000f2c:	89ae                	mv	s3,a1
    80000f2e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f30:	57fd                	li	a5,-1
    80000f32:	83e9                	srli	a5,a5,0x1a
    80000f34:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f36:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f38:	02b7fc63          	bgeu	a5,a1,80000f70 <walk+0x5a>
    panic("walk");
    80000f3c:	00006517          	auipc	a0,0x6
    80000f40:	17450513          	addi	a0,a0,372 # 800070b0 <etext+0xb0>
    80000f44:	89dff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f48:	060a8263          	beqz	s5,80000fac <walk+0x96>
    80000f4c:	bb3ff0ef          	jal	80000afe <kalloc>
    80000f50:	84aa                	mv	s1,a0
    80000f52:	c139                	beqz	a0,80000f98 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f54:	6605                	lui	a2,0x1
    80000f56:	4581                	li	a1,0
    80000f58:	d4bff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f5c:	00c4d793          	srli	a5,s1,0xc
    80000f60:	07aa                	slli	a5,a5,0xa
    80000f62:	0017e793          	ori	a5,a5,1
    80000f66:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcc5f>
    80000f6c:	036a0063          	beq	s4,s6,80000f8c <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f70:	0149d933          	srl	s2,s3,s4
    80000f74:	1ff97913          	andi	s2,s2,511
    80000f78:	090e                	slli	s2,s2,0x3
    80000f7a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f7c:	00093483          	ld	s1,0(s2)
    80000f80:	0014f793          	andi	a5,s1,1
    80000f84:	d3f1                	beqz	a5,80000f48 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f86:	80a9                	srli	s1,s1,0xa
    80000f88:	04b2                	slli	s1,s1,0xc
    80000f8a:	b7c5                	j	80000f6a <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f8c:	00c9d513          	srli	a0,s3,0xc
    80000f90:	1ff57513          	andi	a0,a0,511
    80000f94:	050e                	slli	a0,a0,0x3
    80000f96:	9526                	add	a0,a0,s1
}
    80000f98:	70e2                	ld	ra,56(sp)
    80000f9a:	7442                	ld	s0,48(sp)
    80000f9c:	74a2                	ld	s1,40(sp)
    80000f9e:	7902                	ld	s2,32(sp)
    80000fa0:	69e2                	ld	s3,24(sp)
    80000fa2:	6a42                	ld	s4,16(sp)
    80000fa4:	6aa2                	ld	s5,8(sp)
    80000fa6:	6b02                	ld	s6,0(sp)
    80000fa8:	6121                	addi	sp,sp,64
    80000faa:	8082                	ret
        return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7ed                	j	80000f98 <walk+0x82>

0000000080000fb0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fb0:	57fd                	li	a5,-1
    80000fb2:	83e9                	srli	a5,a5,0x1a
    80000fb4:	00b7f463          	bgeu	a5,a1,80000fbc <walkaddr+0xc>
    return 0;
    80000fb8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fba:	8082                	ret
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fc4:	4601                	li	a2,0
    80000fc6:	f51ff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    80000fca:	c105                	beqz	a0,80000fea <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fcc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fce:	0117f693          	andi	a3,a5,17
    80000fd2:	4745                	li	a4,17
    return 0;
    80000fd4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fd6:	00e68663          	beq	a3,a4,80000fe2 <walkaddr+0x32>
}
    80000fda:	60a2                	ld	ra,8(sp)
    80000fdc:	6402                	ld	s0,0(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fe2:	83a9                	srli	a5,a5,0xa
    80000fe4:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000fe8:	bfcd                	j	80000fda <walkaddr+0x2a>
    return 0;
    80000fea:	4501                	li	a0,0
    80000fec:	b7fd                	j	80000fda <walkaddr+0x2a>

0000000080000fee <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000fee:	715d                	addi	sp,sp,-80
    80000ff0:	e486                	sd	ra,72(sp)
    80000ff2:	e0a2                	sd	s0,64(sp)
    80000ff4:	fc26                	sd	s1,56(sp)
    80000ff6:	f84a                	sd	s2,48(sp)
    80000ff8:	f44e                	sd	s3,40(sp)
    80000ffa:	f052                	sd	s4,32(sp)
    80000ffc:	ec56                	sd	s5,24(sp)
    80000ffe:	e85a                	sd	s6,16(sp)
    80001000:	e45e                	sd	s7,8(sp)
    80001002:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001004:	03459793          	slli	a5,a1,0x34
    80001008:	e7a9                	bnez	a5,80001052 <mappages+0x64>
    8000100a:	8aaa                	mv	s5,a0
    8000100c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000100e:	03461793          	slli	a5,a2,0x34
    80001012:	e7b1                	bnez	a5,8000105e <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001014:	ca39                	beqz	a2,8000106a <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001016:	77fd                	lui	a5,0xfffff
    80001018:	963e                	add	a2,a2,a5
    8000101a:	00b609b3          	add	s3,a2,a1
  a = va;
    8000101e:	892e                	mv	s2,a1
    80001020:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001024:	6b85                	lui	s7,0x1
    80001026:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000102a:	4605                	li	a2,1
    8000102c:	85ca                	mv	a1,s2
    8000102e:	8556                	mv	a0,s5
    80001030:	ee7ff0ef          	jal	80000f16 <walk>
    80001034:	c539                	beqz	a0,80001082 <mappages+0x94>
    if(*pte & PTE_V)
    80001036:	611c                	ld	a5,0(a0)
    80001038:	8b85                	andi	a5,a5,1
    8000103a:	ef95                	bnez	a5,80001076 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000103c:	80b1                	srli	s1,s1,0xc
    8000103e:	04aa                	slli	s1,s1,0xa
    80001040:	0164e4b3          	or	s1,s1,s6
    80001044:	0014e493          	ori	s1,s1,1
    80001048:	e104                	sd	s1,0(a0)
    if(a == last)
    8000104a:	05390863          	beq	s2,s3,8000109a <mappages+0xac>
    a += PGSIZE;
    8000104e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001050:	bfd9                	j	80001026 <mappages+0x38>
    panic("mappages: va not aligned");
    80001052:	00006517          	auipc	a0,0x6
    80001056:	06650513          	addi	a0,a0,102 # 800070b8 <etext+0xb8>
    8000105a:	f86ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    8000105e:	00006517          	auipc	a0,0x6
    80001062:	07a50513          	addi	a0,a0,122 # 800070d8 <etext+0xd8>
    80001066:	f7aff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    8000106a:	00006517          	auipc	a0,0x6
    8000106e:	08e50513          	addi	a0,a0,142 # 800070f8 <etext+0xf8>
    80001072:	f6eff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    80001076:	00006517          	auipc	a0,0x6
    8000107a:	09250513          	addi	a0,a0,146 # 80007108 <etext+0x108>
    8000107e:	f62ff0ef          	jal	800007e0 <panic>
      return -1;
    80001082:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001084:	60a6                	ld	ra,72(sp)
    80001086:	6406                	ld	s0,64(sp)
    80001088:	74e2                	ld	s1,56(sp)
    8000108a:	7942                	ld	s2,48(sp)
    8000108c:	79a2                	ld	s3,40(sp)
    8000108e:	7a02                	ld	s4,32(sp)
    80001090:	6ae2                	ld	s5,24(sp)
    80001092:	6b42                	ld	s6,16(sp)
    80001094:	6ba2                	ld	s7,8(sp)
    80001096:	6161                	addi	sp,sp,80
    80001098:	8082                	ret
  return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7e5                	j	80001084 <mappages+0x96>

000000008000109e <kvmmap>:
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
    800010a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010a8:	86b2                	mv	a3,a2
    800010aa:	863e                	mv	a2,a5
    800010ac:	f43ff0ef          	jal	80000fee <mappages>
    800010b0:	e509                	bnez	a0,800010ba <kvmmap+0x1c>
}
    800010b2:	60a2                	ld	ra,8(sp)
    800010b4:	6402                	ld	s0,0(sp)
    800010b6:	0141                	addi	sp,sp,16
    800010b8:	8082                	ret
    panic("kvmmap");
    800010ba:	00006517          	auipc	a0,0x6
    800010be:	05e50513          	addi	a0,a0,94 # 80007118 <etext+0x118>
    800010c2:	f1eff0ef          	jal	800007e0 <panic>

00000000800010c6 <kvmmake>:
{
    800010c6:	1101                	addi	sp,sp,-32
    800010c8:	ec06                	sd	ra,24(sp)
    800010ca:	e822                	sd	s0,16(sp)
    800010cc:	e426                	sd	s1,8(sp)
    800010ce:	e04a                	sd	s2,0(sp)
    800010d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010d2:	a2dff0ef          	jal	80000afe <kalloc>
    800010d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010d8:	6605                	lui	a2,0x1
    800010da:	4581                	li	a1,0
    800010dc:	bc7ff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010e0:	4719                	li	a4,6
    800010e2:	6685                	lui	a3,0x1
    800010e4:	10000637          	lui	a2,0x10000
    800010e8:	100005b7          	lui	a1,0x10000
    800010ec:	8526                	mv	a0,s1
    800010ee:	fb1ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4719                	li	a4,6
    800010f4:	6685                	lui	a3,0x1
    800010f6:	10001637          	lui	a2,0x10001
    800010fa:	100015b7          	lui	a1,0x10001
    800010fe:	8526                	mv	a0,s1
    80001100:	f9fff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001104:	4719                	li	a4,6
    80001106:	040006b7          	lui	a3,0x4000
    8000110a:	0c000637          	lui	a2,0xc000
    8000110e:	0c0005b7          	lui	a1,0xc000
    80001112:	8526                	mv	a0,s1
    80001114:	f8bff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001118:	00006917          	auipc	s2,0x6
    8000111c:	ee890913          	addi	s2,s2,-280 # 80007000 <etext>
    80001120:	4729                	li	a4,10
    80001122:	80006697          	auipc	a3,0x80006
    80001126:	ede68693          	addi	a3,a3,-290 # 7000 <_entry-0x7fff9000>
    8000112a:	4605                	li	a2,1
    8000112c:	067e                	slli	a2,a2,0x1f
    8000112e:	85b2                	mv	a1,a2
    80001130:	8526                	mv	a0,s1
    80001132:	f6dff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001136:	46c5                	li	a3,17
    80001138:	06ee                	slli	a3,a3,0x1b
    8000113a:	4719                	li	a4,6
    8000113c:	412686b3          	sub	a3,a3,s2
    80001140:	864a                	mv	a2,s2
    80001142:	85ca                	mv	a1,s2
    80001144:	8526                	mv	a0,s1
    80001146:	f59ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000114a:	4729                	li	a4,10
    8000114c:	6685                	lui	a3,0x1
    8000114e:	00005617          	auipc	a2,0x5
    80001152:	eb260613          	addi	a2,a2,-334 # 80006000 <_trampoline>
    80001156:	040005b7          	lui	a1,0x4000
    8000115a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000115c:	05b2                	slli	a1,a1,0xc
    8000115e:	8526                	mv	a0,s1
    80001160:	f3fff0ef          	jal	8000109e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001164:	8526                	mv	a0,s1
    80001166:	5ee000ef          	jal	80001754 <proc_mapstacks>
}
    8000116a:	8526                	mv	a0,s1
    8000116c:	60e2                	ld	ra,24(sp)
    8000116e:	6442                	ld	s0,16(sp)
    80001170:	64a2                	ld	s1,8(sp)
    80001172:	6902                	ld	s2,0(sp)
    80001174:	6105                	addi	sp,sp,32
    80001176:	8082                	ret

0000000080001178 <kvminit>:
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001180:	f47ff0ef          	jal	800010c6 <kvmmake>
    80001184:	00006797          	auipc	a5,0x6
    80001188:	6ea7b223          	sd	a0,1764(a5) # 80007868 <kernel_pagetable>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret

0000000080001194 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001194:	1101                	addi	sp,sp,-32
    80001196:	ec06                	sd	ra,24(sp)
    80001198:	e822                	sd	s0,16(sp)
    8000119a:	e426                	sd	s1,8(sp)
    8000119c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000119e:	961ff0ef          	jal	80000afe <kalloc>
    800011a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011a4:	c509                	beqz	a0,800011ae <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	af9ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011ba:	7139                	addi	sp,sp,-64
    800011bc:	fc06                	sd	ra,56(sp)
    800011be:	f822                	sd	s0,48(sp)
    800011c0:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011c2:	03459793          	slli	a5,a1,0x34
    800011c6:	e38d                	bnez	a5,800011e8 <uvmunmap+0x2e>
    800011c8:	f04a                	sd	s2,32(sp)
    800011ca:	ec4e                	sd	s3,24(sp)
    800011cc:	e852                	sd	s4,16(sp)
    800011ce:	e456                	sd	s5,8(sp)
    800011d0:	e05a                	sd	s6,0(sp)
    800011d2:	8a2a                	mv	s4,a0
    800011d4:	892e                	mv	s2,a1
    800011d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011d8:	0632                	slli	a2,a2,0xc
    800011da:	00b609b3          	add	s3,a2,a1
    800011de:	6b05                	lui	s6,0x1
    800011e0:	0535f963          	bgeu	a1,s3,80001232 <uvmunmap+0x78>
    800011e4:	f426                	sd	s1,40(sp)
    800011e6:	a015                	j	8000120a <uvmunmap+0x50>
    800011e8:	f426                	sd	s1,40(sp)
    800011ea:	f04a                	sd	s2,32(sp)
    800011ec:	ec4e                	sd	s3,24(sp)
    800011ee:	e852                	sd	s4,16(sp)
    800011f0:	e456                	sd	s5,8(sp)
    800011f2:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800011f4:	00006517          	auipc	a0,0x6
    800011f8:	f2c50513          	addi	a0,a0,-212 # 80007120 <etext+0x120>
    800011fc:	de4ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001200:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001204:	995a                	add	s2,s2,s6
    80001206:	03397563          	bgeu	s2,s3,80001230 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000120a:	4601                	li	a2,0
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8552                	mv	a0,s4
    80001210:	d07ff0ef          	jal	80000f16 <walk>
    80001214:	84aa                	mv	s1,a0
    80001216:	d57d                	beqz	a0,80001204 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	0017f713          	andi	a4,a5,1
    8000121e:	d37d                	beqz	a4,80001204 <uvmunmap+0x4a>
    if(do_free){
    80001220:	fe0a80e3          	beqz	s5,80001200 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001224:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001226:	00c79513          	slli	a0,a5,0xc
    8000122a:	ff2ff0ef          	jal	80000a1c <kfree>
    8000122e:	bfc9                	j	80001200 <uvmunmap+0x46>
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret

0000000080001244 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001244:	1101                	addi	sp,sp,-32
    80001246:	ec06                	sd	ra,24(sp)
    80001248:	e822                	sd	s0,16(sp)
    8000124a:	e426                	sd	s1,8(sp)
    8000124c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000124e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001250:	00b67d63          	bgeu	a2,a1,8000126a <uvmdealloc+0x26>
    80001254:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001256:	6785                	lui	a5,0x1
    80001258:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000125a:	00f60733          	add	a4,a2,a5
    8000125e:	76fd                	lui	a3,0xfffff
    80001260:	8f75                	and	a4,a4,a3
    80001262:	97ae                	add	a5,a5,a1
    80001264:	8ff5                	and	a5,a5,a3
    80001266:	00f76863          	bltu	a4,a5,80001276 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000126a:	8526                	mv	a0,s1
    8000126c:	60e2                	ld	ra,24(sp)
    8000126e:	6442                	ld	s0,16(sp)
    80001270:	64a2                	ld	s1,8(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001276:	8f99                	sub	a5,a5,a4
    80001278:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000127a:	4685                	li	a3,1
    8000127c:	0007861b          	sext.w	a2,a5
    80001280:	85ba                	mv	a1,a4
    80001282:	f39ff0ef          	jal	800011ba <uvmunmap>
    80001286:	b7d5                	j	8000126a <uvmdealloc+0x26>

0000000080001288 <uvmalloc>:
  if(newsz < oldsz)
    80001288:	08b66f63          	bltu	a2,a1,80001326 <uvmalloc+0x9e>
{
    8000128c:	7139                	addi	sp,sp,-64
    8000128e:	fc06                	sd	ra,56(sp)
    80001290:	f822                	sd	s0,48(sp)
    80001292:	ec4e                	sd	s3,24(sp)
    80001294:	e852                	sd	s4,16(sp)
    80001296:	e456                	sd	s5,8(sp)
    80001298:	0080                	addi	s0,sp,64
    8000129a:	8aaa                	mv	s5,a0
    8000129c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	95be                	add	a1,a1,a5
    800012a4:	77fd                	lui	a5,0xfffff
    800012a6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012aa:	08c9f063          	bgeu	s3,a2,8000132a <uvmalloc+0xa2>
    800012ae:	f426                	sd	s1,40(sp)
    800012b0:	f04a                	sd	s2,32(sp)
    800012b2:	e05a                	sd	s6,0(sp)
    800012b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012ba:	845ff0ef          	jal	80000afe <kalloc>
    800012be:	84aa                	mv	s1,a0
    if(mem == 0){
    800012c0:	c515                	beqz	a0,800012ec <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	9ddff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ca:	875a                	mv	a4,s6
    800012cc:	86a6                	mv	a3,s1
    800012ce:	6605                	lui	a2,0x1
    800012d0:	85ca                	mv	a1,s2
    800012d2:	8556                	mv	a0,s5
    800012d4:	d1bff0ef          	jal	80000fee <mappages>
    800012d8:	e915                	bnez	a0,8000130c <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012da:	6785                	lui	a5,0x1
    800012dc:	993e                	add	s2,s2,a5
    800012de:	fd496ee3          	bltu	s2,s4,800012ba <uvmalloc+0x32>
  return newsz;
    800012e2:	8552                	mv	a0,s4
    800012e4:	74a2                	ld	s1,40(sp)
    800012e6:	7902                	ld	s2,32(sp)
    800012e8:	6b02                	ld	s6,0(sp)
    800012ea:	a811                	j	800012fe <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8556                	mv	a0,s5
    800012f2:	f53ff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	74a2                	ld	s1,40(sp)
    800012fa:	7902                	ld	s2,32(sp)
    800012fc:	6b02                	ld	s6,0(sp)
}
    800012fe:	70e2                	ld	ra,56(sp)
    80001300:	7442                	ld	s0,48(sp)
    80001302:	69e2                	ld	s3,24(sp)
    80001304:	6a42                	ld	s4,16(sp)
    80001306:	6aa2                	ld	s5,8(sp)
    80001308:	6121                	addi	sp,sp,64
    8000130a:	8082                	ret
      kfree(mem);
    8000130c:	8526                	mv	a0,s1
    8000130e:	f0eff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001312:	864e                	mv	a2,s3
    80001314:	85ca                	mv	a1,s2
    80001316:	8556                	mv	a0,s5
    80001318:	f2dff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    8000131c:	4501                	li	a0,0
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	bfe9                	j	800012fe <uvmalloc+0x76>
    return oldsz;
    80001326:	852e                	mv	a0,a1
}
    80001328:	8082                	ret
  return newsz;
    8000132a:	8532                	mv	a0,a2
    8000132c:	bfc9                	j	800012fe <uvmalloc+0x76>

000000008000132e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
    8000133e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001340:	84aa                	mv	s1,a0
    80001342:	6905                	lui	s2,0x1
    80001344:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001346:	4985                	li	s3,1
    80001348:	a819                	j	8000135e <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fdfff0ef          	jal	8000132e <freewalk>
      pagetable[i] = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001358:	04a1                	addi	s1,s1,8
    8000135a:	01248f63          	beq	s1,s2,80001378 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    8000135e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001360:	00f7f713          	andi	a4,a5,15
    80001364:	ff3703e3          	beq	a4,s3,8000134a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001368:	8b85                	andi	a5,a5,1
    8000136a:	d7fd                	beqz	a5,80001358 <freewalk+0x2a>
      panic("freewalk: leaf");
    8000136c:	00006517          	auipc	a0,0x6
    80001370:	dcc50513          	addi	a0,a0,-564 # 80007138 <etext+0x138>
    80001374:	c6cff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001378:	8552                	mv	a0,s4
    8000137a:	ea2ff0ef          	jal	80000a1c <kfree>
}
    8000137e:	70a2                	ld	ra,40(sp)
    80001380:	7402                	ld	s0,32(sp)
    80001382:	64e2                	ld	s1,24(sp)
    80001384:	6942                	ld	s2,16(sp)
    80001386:	69a2                	ld	s3,8(sp)
    80001388:	6a02                	ld	s4,0(sp)
    8000138a:	6145                	addi	sp,sp,48
    8000138c:	8082                	ret

000000008000138e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
    80001398:	84aa                	mv	s1,a0
  if(sz > 0)
    8000139a:	e989                	bnez	a1,800013ac <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000139c:	8526                	mv	a0,s1
    8000139e:	f91ff0ef          	jal	8000132e <freewalk>
}
    800013a2:	60e2                	ld	ra,24(sp)
    800013a4:	6442                	ld	s0,16(sp)
    800013a6:	64a2                	ld	s1,8(sp)
    800013a8:	6105                	addi	sp,sp,32
    800013aa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ac:	6785                	lui	a5,0x1
    800013ae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013b0:	95be                	add	a1,a1,a5
    800013b2:	4685                	li	a3,1
    800013b4:	00c5d613          	srli	a2,a1,0xc
    800013b8:	4581                	li	a1,0
    800013ba:	e01ff0ef          	jal	800011ba <uvmunmap>
    800013be:	bff9                	j	8000139c <uvmfree+0xe>

00000000800013c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013c0:	ce49                	beqz	a2,8000145a <uvmcopy+0x9a>
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8aaa                	mv	s5,a0
    800013da:	8b2e                	mv	s6,a1
    800013dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800013de:	4481                	li	s1,0
    800013e0:	a029                	j	800013ea <uvmcopy+0x2a>
    800013e2:	6785                	lui	a5,0x1
    800013e4:	94be                	add	s1,s1,a5
    800013e6:	0544fe63          	bgeu	s1,s4,80001442 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    800013ea:	4601                	li	a2,0
    800013ec:	85a6                	mv	a1,s1
    800013ee:	8556                	mv	a0,s5
    800013f0:	b27ff0ef          	jal	80000f16 <walk>
    800013f4:	d57d                	beqz	a0,800013e2 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    800013f6:	6118                	ld	a4,0(a0)
    800013f8:	00177793          	andi	a5,a4,1
    800013fc:	d3fd                	beqz	a5,800013e2 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    800013fe:	00a75593          	srli	a1,a4,0xa
    80001402:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001406:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000140a:	ef4ff0ef          	jal	80000afe <kalloc>
    8000140e:	89aa                	mv	s3,a0
    80001410:	c105                	beqz	a0,80001430 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	85de                	mv	a1,s7
    80001416:	8e9ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000141a:	874a                	mv	a4,s2
    8000141c:	86ce                	mv	a3,s3
    8000141e:	6605                	lui	a2,0x1
    80001420:	85a6                	mv	a1,s1
    80001422:	855a                	mv	a0,s6
    80001424:	bcbff0ef          	jal	80000fee <mappages>
    80001428:	dd4d                	beqz	a0,800013e2 <uvmcopy+0x22>
      kfree(mem);
    8000142a:	854e                	mv	a0,s3
    8000142c:	df0ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001430:	4685                	li	a3,1
    80001432:	00c4d613          	srli	a2,s1,0xc
    80001436:	4581                	li	a1,0
    80001438:	855a                	mv	a0,s6
    8000143a:	d81ff0ef          	jal	800011ba <uvmunmap>
  return -1;
    8000143e:	557d                	li	a0,-1
    80001440:	a011                	j	80001444 <uvmcopy+0x84>
  return 0;
    80001442:	4501                	li	a0,0
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
  return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	8082                	ret

000000008000145e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000145e:	1141                	addi	sp,sp,-16
    80001460:	e406                	sd	ra,8(sp)
    80001462:	e022                	sd	s0,0(sp)
    80001464:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001466:	4601                	li	a2,0
    80001468:	aafff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    8000146c:	c901                	beqz	a0,8000147c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146e:	611c                	ld	a5,0(a0)
    80001470:	9bbd                	andi	a5,a5,-17
    80001472:	e11c                	sd	a5,0(a0)
}
    80001474:	60a2                	ld	ra,8(sp)
    80001476:	6402                	ld	s0,0(sp)
    80001478:	0141                	addi	sp,sp,16
    8000147a:	8082                	ret
    panic("uvmclear");
    8000147c:	00006517          	auipc	a0,0x6
    80001480:	ccc50513          	addi	a0,a0,-820 # 80007148 <etext+0x148>
    80001484:	b5cff0ef          	jal	800007e0 <panic>

0000000080001488 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001488:	c6dd                	beqz	a3,80001536 <copyinstr+0xae>
{
    8000148a:	715d                	addi	sp,sp,-80
    8000148c:	e486                	sd	ra,72(sp)
    8000148e:	e0a2                	sd	s0,64(sp)
    80001490:	fc26                	sd	s1,56(sp)
    80001492:	f84a                	sd	s2,48(sp)
    80001494:	f44e                	sd	s3,40(sp)
    80001496:	f052                	sd	s4,32(sp)
    80001498:	ec56                	sd	s5,24(sp)
    8000149a:	e85a                	sd	s6,16(sp)
    8000149c:	e45e                	sd	s7,8(sp)
    8000149e:	0880                	addi	s0,sp,80
    800014a0:	8a2a                	mv	s4,a0
    800014a2:	8b2e                	mv	s6,a1
    800014a4:	8bb2                	mv	s7,a2
    800014a6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	a825                	j	800014e4 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014b4:	37fd                	addiw	a5,a5,-1
    800014b6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6161                	addi	sp,sp,80
    800014ce:	8082                	ret
    800014d0:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014d4:	9742                	add	a4,a4,a6
      --max;
    800014d6:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800014da:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800014de:	04e58463          	beq	a1,a4,80001526 <copyinstr+0x9e>
{
    800014e2:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800014e4:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	ac5ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0)
    800014f0:	cd0d                	beqz	a0,8000152a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800014f2:	417486b3          	sub	a3,s1,s7
    800014f6:	96ce                	add	a3,a3,s3
    if(n > max)
    800014f8:	00d97363          	bgeu	s2,a3,800014fe <copyinstr+0x76>
    800014fc:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800014fe:	955e                	add	a0,a0,s7
    80001500:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001502:	c695                	beqz	a3,8000152e <copyinstr+0xa6>
    80001504:	87da                	mv	a5,s6
    80001506:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001508:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000150c:	96da                	add	a3,a3,s6
    8000150e:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	00074703          	lbu	a4,0(a4)
    80001518:	db59                	beqz	a4,800014ae <copyinstr+0x26>
        *dst = *p;
    8000151a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000151e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001520:	fed797e3          	bne	a5,a3,8000150e <copyinstr+0x86>
    80001524:	b775                	j	800014d0 <copyinstr+0x48>
    80001526:	4781                	li	a5,0
    80001528:	b771                	j	800014b4 <copyinstr+0x2c>
      return -1;
    8000152a:	557d                	li	a0,-1
    8000152c:	b779                	j	800014ba <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000152e:	6b85                	lui	s7,0x1
    80001530:	9ba6                	add	s7,s7,s1
    80001532:	87da                	mv	a5,s6
    80001534:	b77d                	j	800014e2 <copyinstr+0x5a>
  int got_null = 0;
    80001536:	4781                	li	a5,0
  if(got_null){
    80001538:	37fd                	addiw	a5,a5,-1
    8000153a:	0007851b          	sext.w	a0,a5
}
    8000153e:	8082                	ret

0000000080001540 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001540:	1141                	addi	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001548:	4601                	li	a2,0
    8000154a:	9cdff0ef          	jal	80000f16 <walk>
  if (pte == 0) {
    8000154e:	c519                	beqz	a0,8000155c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001550:	6108                	ld	a0,0(a0)
    80001552:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001554:	60a2                	ld	ra,8(sp)
    80001556:	6402                	ld	s0,0(sp)
    80001558:	0141                	addi	sp,sp,16
    8000155a:	8082                	ret
    return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfdd                	j	80001554 <ismapped+0x14>

0000000080001560 <vmfault>:
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e44e                	sd	s3,8(sp)
    8000156a:	1800                	addi	s0,sp,48
    8000156c:	89aa                	mv	s3,a0
    8000156e:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001570:	35e000ef          	jal	800018ce <myproc>
  if (va >= p->sz)
    80001574:	653c                	ld	a5,72(a0)
    80001576:	00f4ea63          	bltu	s1,a5,8000158a <vmfault+0x2a>
    return 0;
    8000157a:	4981                	li	s3,0
}
    8000157c:	854e                	mv	a0,s3
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    8000158a:	e84a                	sd	s2,16(sp)
    8000158c:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000158e:	77fd                	lui	a5,0xfffff
    80001590:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80001592:	85a6                	mv	a1,s1
    80001594:	854e                	mv	a0,s3
    80001596:	fabff0ef          	jal	80001540 <ismapped>
    return 0;
    8000159a:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    8000159c:	c119                	beqz	a0,800015a2 <vmfault+0x42>
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	bff1                	j	8000157c <vmfault+0x1c>
    800015a2:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015a4:	d5aff0ef          	jal	80000afe <kalloc>
    800015a8:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015aa:	c90d                	beqz	a0,800015dc <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ac:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	4581                	li	a1,0
    800015b2:	ef0ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015b6:	4759                	li	a4,22
    800015b8:	86d2                	mv	a3,s4
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85a6                	mv	a1,s1
    800015be:	05093503          	ld	a0,80(s2)
    800015c2:	a2dff0ef          	jal	80000fee <mappages>
    800015c6:	e501                	bnez	a0,800015ce <vmfault+0x6e>
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	6a02                	ld	s4,0(sp)
    800015cc:	bf45                	j	8000157c <vmfault+0x1c>
    kfree((void *)mem);
    800015ce:	8552                	mv	a0,s4
    800015d0:	c4cff0ef          	jal	80000a1c <kfree>
    return 0;
    800015d4:	4981                	li	s3,0
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	b74d                	j	8000157c <vmfault+0x1c>
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	bf71                	j	8000157c <vmfault+0x1c>

00000000800015e2 <copyout>:
  while(len > 0){
    800015e2:	c2cd                	beqz	a3,80001684 <copyout+0xa2>
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	f852                	sd	s4,48(sp)
    800015ee:	f05a                	sd	s6,32(sp)
    800015f0:	ec5e                	sd	s7,24(sp)
    800015f2:	e862                	sd	s8,16(sp)
    800015f4:	1080                	addi	s0,sp,96
    800015f6:	8c2a                	mv	s8,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8bb2                	mv	s7,a2
    800015fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015fe:	74fd                	lui	s1,0xfffff
    80001600:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001602:	57fd                	li	a5,-1
    80001604:	83e9                	srli	a5,a5,0x1a
    80001606:	0897e163          	bltu	a5,s1,80001688 <copyout+0xa6>
    8000160a:	e0ca                	sd	s2,64(sp)
    8000160c:	fc4e                	sd	s3,56(sp)
    8000160e:	f456                	sd	s5,40(sp)
    80001610:	e466                	sd	s9,8(sp)
    80001612:	e06a                	sd	s10,0(sp)
    80001614:	6d05                	lui	s10,0x1
    80001616:	8cbe                	mv	s9,a5
    80001618:	a015                	j	8000163c <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161a:	409b0533          	sub	a0,s6,s1
    8000161e:	0009861b          	sext.w	a2,s3
    80001622:	85de                	mv	a1,s7
    80001624:	954a                	add	a0,a0,s2
    80001626:	ed8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000162a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000162e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001630:	040a0363          	beqz	s4,80001676 <copyout+0x94>
    if(va0 >= MAXVA)
    80001634:	055cec63          	bltu	s9,s5,8000168c <copyout+0xaa>
    80001638:	84d6                	mv	s1,s5
    8000163a:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8562                	mv	a0,s8
    80001640:	971ff0ef          	jal	80000fb0 <walkaddr>
    80001644:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001646:	e901                	bnez	a0,80001656 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001648:	4601                	li	a2,0
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8562                	mv	a0,s8
    8000164e:	f13ff0ef          	jal	80001560 <vmfault>
    80001652:	892a                	mv	s2,a0
    80001654:	c139                	beqz	a0,8000169a <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85a6                	mv	a1,s1
    8000165a:	8562                	mv	a0,s8
    8000165c:	8bbff0ef          	jal	80000f16 <walk>
    if((*pte & PTE_W) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	8b91                	andi	a5,a5,4
    80001664:	c3b1                	beqz	a5,800016a8 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    80001666:	01a48ab3          	add	s5,s1,s10
    8000166a:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    8000166e:	fb3a76e3          	bgeu	s4,s3,8000161a <copyout+0x38>
    80001672:	89d2                	mv	s3,s4
    80001674:	b75d                	j	8000161a <copyout+0x38>
  return 0;
    80001676:	4501                	li	a0,0
    80001678:	6906                	ld	s2,64(sp)
    8000167a:	79e2                	ld	s3,56(sp)
    8000167c:	7aa2                	ld	s5,40(sp)
    8000167e:	6ca2                	ld	s9,8(sp)
    80001680:	6d02                	ld	s10,0(sp)
    80001682:	a80d                	j	800016b4 <copyout+0xd2>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
    8000168a:	a02d                	j	800016b4 <copyout+0xd2>
    8000168c:	557d                	li	a0,-1
    8000168e:	6906                	ld	s2,64(sp)
    80001690:	79e2                	ld	s3,56(sp)
    80001692:	7aa2                	ld	s5,40(sp)
    80001694:	6ca2                	ld	s9,8(sp)
    80001696:	6d02                	ld	s10,0(sp)
    80001698:	a831                	j	800016b4 <copyout+0xd2>
        return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	6906                	ld	s2,64(sp)
    8000169e:	79e2                	ld	s3,56(sp)
    800016a0:	7aa2                	ld	s5,40(sp)
    800016a2:	6ca2                	ld	s9,8(sp)
    800016a4:	6d02                	ld	s10,0(sp)
    800016a6:	a039                	j	800016b4 <copyout+0xd2>
      return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	6906                	ld	s2,64(sp)
    800016ac:	79e2                	ld	s3,56(sp)
    800016ae:	7aa2                	ld	s5,40(sp)
    800016b0:	6ca2                	ld	s9,8(sp)
    800016b2:	6d02                	ld	s10,0(sp)
}
    800016b4:	60e6                	ld	ra,88(sp)
    800016b6:	6446                	ld	s0,80(sp)
    800016b8:	64a6                	ld	s1,72(sp)
    800016ba:	7a42                	ld	s4,48(sp)
    800016bc:	7b02                	ld	s6,32(sp)
    800016be:	6be2                	ld	s7,24(sp)
    800016c0:	6c42                	ld	s8,16(sp)
    800016c2:	6125                	addi	sp,sp,96
    800016c4:	8082                	ret

00000000800016c6 <copyin>:
  while(len > 0){
    800016c6:	c6c9                	beqz	a3,80001750 <copyin+0x8a>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8baa                	mv	s7,a0
    800016e2:	8aae                	mv	s5,a1
    800016e4:	8932                	mv	s2,a2
    800016e6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016e8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016ea:	6b05                	lui	s6,0x1
    800016ec:	a035                	j	80001718 <copyin+0x52>
    800016ee:	412984b3          	sub	s1,s3,s2
    800016f2:	94da                	add	s1,s1,s6
    if(n > len)
    800016f4:	009a7363          	bgeu	s4,s1,800016fa <copyin+0x34>
    800016f8:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	413905b3          	sub	a1,s2,s3
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	95aa                	add	a1,a1,a0
    80001704:	8556                	mv	a0,s5
    80001706:	df8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000170a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000170e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001710:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001714:	020a0163          	beqz	s4,80001736 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001718:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000171c:	85ce                	mv	a1,s3
    8000171e:	855e                	mv	a0,s7
    80001720:	891ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0) {
    80001724:	f569                	bnez	a0,800016ee <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001726:	4601                	li	a2,0
    80001728:	85ce                	mv	a1,s3
    8000172a:	855e                	mv	a0,s7
    8000172c:	e35ff0ef          	jal	80001560 <vmfault>
    80001730:	fd5d                	bnez	a0,800016ee <copyin+0x28>
        return -1;
    80001732:	557d                	li	a0,-1
    80001734:	a011                	j	80001738 <copyin+0x72>
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret
  return 0;
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret

0000000080001754 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001754:	7139                	addi	sp,sp,-64
    80001756:	fc06                	sd	ra,56(sp)
    80001758:	f822                	sd	s0,48(sp)
    8000175a:	f426                	sd	s1,40(sp)
    8000175c:	f04a                	sd	s2,32(sp)
    8000175e:	ec4e                	sd	s3,24(sp)
    80001760:	e852                	sd	s4,16(sp)
    80001762:	e456                	sd	s5,8(sp)
    80001764:	e05a                	sd	s6,0(sp)
    80001766:	0080                	addi	s0,sp,64
    80001768:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176a:	0000e497          	auipc	s1,0xe
    8000176e:	64e48493          	addi	s1,s1,1614 # 8000fdb8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	ff048937          	lui	s2,0xff048
    80001778:	dc190913          	addi	s2,s2,-575 # ffffffffff047dc1 <end+0xffffffff7f025a29>
    8000177c:	0932                	slli	s2,s2,0xc
    8000177e:	1f790913          	addi	s2,s2,503
    80001782:	093e                	slli	s2,s2,0xf
    80001784:	23f90913          	addi	s2,s2,575
    80001788:	0932                	slli	s2,s2,0xc
    8000178a:	e0990913          	addi	s2,s2,-503
    8000178e:	040009b7          	lui	s3,0x4000
    80001792:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001794:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001796:	00016a97          	auipc	s5,0x16
    8000179a:	822a8a93          	addi	s5,s5,-2014 # 80016fb8 <tickslock>
    char *pa = kalloc();
    8000179e:	b60ff0ef          	jal	80000afe <kalloc>
    800017a2:	862a                	mv	a2,a0
    if(pa == 0)
    800017a4:	cd15                	beqz	a0,800017e0 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017a6:	416485b3          	sub	a1,s1,s6
    800017aa:	858d                	srai	a1,a1,0x3
    800017ac:	032585b3          	mul	a1,a1,s2
    800017b0:	2585                	addiw	a1,a1,1
    800017b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017b6:	4719                	li	a4,6
    800017b8:	6685                	lui	a3,0x1
    800017ba:	40b985b3          	sub	a1,s3,a1
    800017be:	8552                	mv	a0,s4
    800017c0:	8dfff0ef          	jal	8000109e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017c4:	1c848493          	addi	s1,s1,456
    800017c8:	fd549be3          	bne	s1,s5,8000179e <proc_mapstacks+0x4a>
  }
}
    800017cc:	70e2                	ld	ra,56(sp)
    800017ce:	7442                	ld	s0,48(sp)
    800017d0:	74a2                	ld	s1,40(sp)
    800017d2:	7902                	ld	s2,32(sp)
    800017d4:	69e2                	ld	s3,24(sp)
    800017d6:	6a42                	ld	s4,16(sp)
    800017d8:	6aa2                	ld	s5,8(sp)
    800017da:	6b02                	ld	s6,0(sp)
    800017dc:	6121                	addi	sp,sp,64
    800017de:	8082                	ret
      panic("kalloc");
    800017e0:	00006517          	auipc	a0,0x6
    800017e4:	97850513          	addi	a0,a0,-1672 # 80007158 <etext+0x158>
    800017e8:	ff9fe0ef          	jal	800007e0 <panic>

00000000800017ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	e05a                	sd	s6,0(sp)
    800017fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001800:	00006597          	auipc	a1,0x6
    80001804:	96058593          	addi	a1,a1,-1696 # 80007160 <etext+0x160>
    80001808:	0000e517          	auipc	a0,0xe
    8000180c:	18050513          	addi	a0,a0,384 # 8000f988 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	95458593          	addi	a1,a1,-1708 # 80007168 <etext+0x168>
    8000181c:	0000e517          	auipc	a0,0xe
    80001820:	18450513          	addi	a0,a0,388 # 8000f9a0 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001828:	0000e497          	auipc	s1,0xe
    8000182c:	59048493          	addi	s1,s1,1424 # 8000fdb8 <proc>
      initlock(&p->lock, "proc");
    80001830:	00006b17          	auipc	s6,0x6
    80001834:	948b0b13          	addi	s6,s6,-1720 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001838:	8aa6                	mv	s5,s1
    8000183a:	ff048937          	lui	s2,0xff048
    8000183e:	dc190913          	addi	s2,s2,-575 # ffffffffff047dc1 <end+0xffffffff7f025a29>
    80001842:	0932                	slli	s2,s2,0xc
    80001844:	1f790913          	addi	s2,s2,503
    80001848:	093e                	slli	s2,s2,0xf
    8000184a:	23f90913          	addi	s2,s2,575
    8000184e:	0932                	slli	s2,s2,0xc
    80001850:	e0990913          	addi	s2,s2,-503
    80001854:	040009b7          	lui	s3,0x4000
    80001858:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000185a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00015a17          	auipc	s4,0x15
    80001860:	75ca0a13          	addi	s4,s4,1884 # 80016fb8 <tickslock>
      initlock(&p->lock, "proc");
    80001864:	85da                	mv	a1,s6
    80001866:	8526                	mv	a0,s1
    80001868:	ae6ff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    8000186c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001870:	415487b3          	sub	a5,s1,s5
    80001874:	878d                	srai	a5,a5,0x3
    80001876:	032787b3          	mul	a5,a5,s2
    8000187a:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdcc69>
    8000187c:	00d7979b          	slliw	a5,a5,0xd
    80001880:	40f987b3          	sub	a5,s3,a5
    80001884:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	1c848493          	addi	s1,s1,456
    8000188a:	fd449de3          	bne	s1,s4,80001864 <procinit+0x78>
  }
}
    8000188e:	70e2                	ld	ra,56(sp)
    80001890:	7442                	ld	s0,48(sp)
    80001892:	74a2                	ld	s1,40(sp)
    80001894:	7902                	ld	s2,32(sp)
    80001896:	69e2                	ld	s3,24(sp)
    80001898:	6a42                	ld	s4,16(sp)
    8000189a:	6aa2                	ld	s5,8(sp)
    8000189c:	6b02                	ld	s6,0(sp)
    8000189e:	6121                	addi	sp,sp,64
    800018a0:	8082                	ret

00000000800018a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018a2:	1141                	addi	sp,sp,-16
    800018a4:	e422                	sd	s0,8(sp)
    800018a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018aa:	2501                	sext.w	a0,a0
    800018ac:	6422                	ld	s0,8(sp)
    800018ae:	0141                	addi	sp,sp,16
    800018b0:	8082                	ret

00000000800018b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018b2:	1141                	addi	sp,sp,-16
    800018b4:	e422                	sd	s0,8(sp)
    800018b6:	0800                	addi	s0,sp,16
    800018b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ba:	2781                	sext.w	a5,a5
    800018bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800018be:	0000e517          	auipc	a0,0xe
    800018c2:	0fa50513          	addi	a0,a0,250 # 8000f9b8 <cpus>
    800018c6:	953e                	add	a0,a0,a5
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	1000                	addi	s0,sp,32
  push_off();
    800018d8:	ab6ff0ef          	jal	80000b8e <push_off>
    800018dc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018de:	2781                	sext.w	a5,a5
    800018e0:	079e                	slli	a5,a5,0x7
    800018e2:	0000e717          	auipc	a4,0xe
    800018e6:	0a670713          	addi	a4,a4,166 # 8000f988 <pid_lock>
    800018ea:	97ba                	add	a5,a5,a4
    800018ec:	7b84                	ld	s1,48(a5)
  pop_off();
    800018ee:	b24ff0ef          	jal	80000c12 <pop_off>
  return p;
}
    800018f2:	8526                	mv	a0,s1
    800018f4:	60e2                	ld	ra,24(sp)
    800018f6:	6442                	ld	s0,16(sp)
    800018f8:	64a2                	ld	s1,8(sp)
    800018fa:	6105                	addi	sp,sp,32
    800018fc:	8082                	ret

00000000800018fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018fe:	7179                	addi	sp,sp,-48
    80001900:	f406                	sd	ra,40(sp)
    80001902:	f022                	sd	s0,32(sp)
    80001904:	ec26                	sd	s1,24(sp)
    80001906:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001908:	fc7ff0ef          	jal	800018ce <myproc>
    8000190c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000190e:	b58ff0ef          	jal	80000c66 <release>

  if (first) {
    80001912:	00006797          	auipc	a5,0x6
    80001916:	f2e7a783          	lw	a5,-210(a5) # 80007840 <first.1>
    8000191a:	cf8d                	beqz	a5,80001954 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000191c:	4505                	li	a0,1
    8000191e:	1ec020ef          	jal	80003b0a <fsinit>

    first = 0;
    80001922:	00006797          	auipc	a5,0x6
    80001926:	f007af23          	sw	zero,-226(a5) # 80007840 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000192a:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000192e:	00006517          	auipc	a0,0x6
    80001932:	85250513          	addi	a0,a0,-1966 # 80007180 <etext+0x180>
    80001936:	fca43823          	sd	a0,-48(s0)
    8000193a:	fc043c23          	sd	zero,-40(s0)
    8000193e:	fd040593          	addi	a1,s0,-48
    80001942:	2d2030ef          	jal	80004c14 <kexec>
    80001946:	6cbc                	ld	a5,88(s1)
    80001948:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000194a:	6cbc                	ld	a5,88(s1)
    8000194c:	7bb8                	ld	a4,112(a5)
    8000194e:	57fd                	li	a5,-1
    80001950:	02f70d63          	beq	a4,a5,8000198a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001954:	639000ef          	jal	8000278c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001958:	68a8                	ld	a0,80(s1)
    8000195a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000195c:	04000737          	lui	a4,0x4000
    80001960:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001962:	0732                	slli	a4,a4,0xc
    80001964:	00004797          	auipc	a5,0x4
    80001968:	73878793          	addi	a5,a5,1848 # 8000609c <userret>
    8000196c:	00004697          	auipc	a3,0x4
    80001970:	69468693          	addi	a3,a3,1684 # 80006000 <_trampoline>
    80001974:	8f95                	sub	a5,a5,a3
    80001976:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001978:	577d                	li	a4,-1
    8000197a:	177e                	slli	a4,a4,0x3f
    8000197c:	8d59                	or	a0,a0,a4
    8000197e:	9782                	jalr	a5
}
    80001980:	70a2                	ld	ra,40(sp)
    80001982:	7402                	ld	s0,32(sp)
    80001984:	64e2                	ld	s1,24(sp)
    80001986:	6145                	addi	sp,sp,48
    80001988:	8082                	ret
      panic("exec");
    8000198a:	00005517          	auipc	a0,0x5
    8000198e:	7fe50513          	addi	a0,a0,2046 # 80007188 <etext+0x188>
    80001992:	e4ffe0ef          	jal	800007e0 <panic>

0000000080001996 <allocpid>:
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	e04a                	sd	s2,0(sp)
    800019a0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019a2:	0000e917          	auipc	s2,0xe
    800019a6:	fe690913          	addi	s2,s2,-26 # 8000f988 <pid_lock>
    800019aa:	854a                	mv	a0,s2
    800019ac:	a22ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019b0:	00006797          	auipc	a5,0x6
    800019b4:	e9478793          	addi	a5,a5,-364 # 80007844 <nextpid>
    800019b8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019ba:	0014871b          	addiw	a4,s1,1
    800019be:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019c0:	854a                	mv	a0,s2
    800019c2:	aa4ff0ef          	jal	80000c66 <release>
}
    800019c6:	8526                	mv	a0,s1
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <proc_pagetable>:
{
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	e04a                	sd	s2,0(sp)
    800019de:	1000                	addi	s0,sp,32
    800019e0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019e2:	fb2ff0ef          	jal	80001194 <uvmcreate>
    800019e6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019e8:	cd05                	beqz	a0,80001a20 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019ea:	4729                	li	a4,10
    800019ec:	00004697          	auipc	a3,0x4
    800019f0:	61468693          	addi	a3,a3,1556 # 80006000 <_trampoline>
    800019f4:	6605                	lui	a2,0x1
    800019f6:	040005b7          	lui	a1,0x4000
    800019fa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800019fc:	05b2                	slli	a1,a1,0xc
    800019fe:	df0ff0ef          	jal	80000fee <mappages>
    80001a02:	02054663          	bltz	a0,80001a2e <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a06:	4719                	li	a4,6
    80001a08:	05893683          	ld	a3,88(s2)
    80001a0c:	6605                	lui	a2,0x1
    80001a0e:	020005b7          	lui	a1,0x2000
    80001a12:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a14:	05b6                	slli	a1,a1,0xd
    80001a16:	8526                	mv	a0,s1
    80001a18:	dd6ff0ef          	jal	80000fee <mappages>
    80001a1c:	00054f63          	bltz	a0,80001a3a <proc_pagetable+0x66>
}
    80001a20:	8526                	mv	a0,s1
    80001a22:	60e2                	ld	ra,24(sp)
    80001a24:	6442                	ld	s0,16(sp)
    80001a26:	64a2                	ld	s1,8(sp)
    80001a28:	6902                	ld	s2,0(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001a2e:	4581                	li	a1,0
    80001a30:	8526                	mv	a0,s1
    80001a32:	95dff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a36:	4481                	li	s1,0
    80001a38:	b7e5                	j	80001a20 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a3a:	4681                	li	a3,0
    80001a3c:	4605                	li	a2,1
    80001a3e:	040005b7          	lui	a1,0x4000
    80001a42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a44:	05b2                	slli	a1,a1,0xc
    80001a46:	8526                	mv	a0,s1
    80001a48:	f72ff0ef          	jal	800011ba <uvmunmap>
    uvmfree(pagetable, 0);
    80001a4c:	4581                	li	a1,0
    80001a4e:	8526                	mv	a0,s1
    80001a50:	93fff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a54:	4481                	li	s1,0
    80001a56:	b7e9                	j	80001a20 <proc_pagetable+0x4c>

0000000080001a58 <proc_freepagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	84aa                	mv	s1,a0
    80001a66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a68:	4681                	li	a3,0
    80001a6a:	4605                	li	a2,1
    80001a6c:	040005b7          	lui	a1,0x4000
    80001a70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a72:	05b2                	slli	a1,a1,0xc
    80001a74:	f46ff0ef          	jal	800011ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a78:	4681                	li	a3,0
    80001a7a:	4605                	li	a2,1
    80001a7c:	020005b7          	lui	a1,0x2000
    80001a80:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a82:	05b6                	slli	a1,a1,0xd
    80001a84:	8526                	mv	a0,s1
    80001a86:	f34ff0ef          	jal	800011ba <uvmunmap>
  uvmfree(pagetable, sz);
    80001a8a:	85ca                	mv	a1,s2
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	901ff0ef          	jal	8000138e <uvmfree>
}
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6902                	ld	s2,0(sp)
    80001a9a:	6105                	addi	sp,sp,32
    80001a9c:	8082                	ret

0000000080001a9e <freeproc>:
{
    80001a9e:	1101                	addi	sp,sp,-32
    80001aa0:	ec06                	sd	ra,24(sp)
    80001aa2:	e822                	sd	s0,16(sp)
    80001aa4:	e426                	sd	s1,8(sp)
    80001aa6:	1000                	addi	s0,sp,32
    80001aa8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001aaa:	6d28                	ld	a0,88(a0)
    80001aac:	c119                	beqz	a0,80001ab2 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001aae:	f6ffe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001ab2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ab6:	68a8                	ld	a0,80(s1)
    80001ab8:	c501                	beqz	a0,80001ac0 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001aba:	64ac                	ld	a1,72(s1)
    80001abc:	f9dff0ef          	jal	80001a58 <proc_freepagetable>
  p->pagetable = 0;
    80001ac0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ac4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ac8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001acc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ad0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ad4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ad8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001adc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ae0:	0004ac23          	sw	zero,24(s1)
  for(int i = 0; i < EDR_FORK_SAMPLE; i++) p->fork_times[i] = 0;
    80001ae4:	1604bc23          	sd	zero,376(s1)
    80001ae8:	1804b023          	sd	zero,384(s1)
    80001aec:	1804b423          	sd	zero,392(s1)
    80001af0:	1804b823          	sd	zero,400(s1)
    80001af4:	1804bc23          	sd	zero,408(s1)
    80001af8:	1a04b023          	sd	zero,416(s1)
  p->fork_times_idx = 0;
    80001afc:	1a04a423          	sw	zero,424(s1)
  p->cumulative_run_time = 0;
    80001b00:	1a04a623          	sw	zero,428(s1)
  p->is_sandboxed = 0;
    80001b04:	1a048823          	sb	zero,432(s1)
  p->sandbox_reason = 0;
    80001b08:	1a0488a3          	sb	zero,433(s1)
  p->quarantine_tick = 0;
    80001b0c:	1a04bc23          	sd	zero,440(s1)
  p->need_propagation = 0;
    80001b10:	1c048023          	sb	zero,448(s1)
  p->edr_trusted = 0;
    80001b14:	1c0480a3          	sb	zero,449(s1)
}
    80001b18:	60e2                	ld	ra,24(sp)
    80001b1a:	6442                	ld	s0,16(sp)
    80001b1c:	64a2                	ld	s1,8(sp)
    80001b1e:	6105                	addi	sp,sp,32
    80001b20:	8082                	ret

0000000080001b22 <allocproc>:
{
    80001b22:	1101                	addi	sp,sp,-32
    80001b24:	ec06                	sd	ra,24(sp)
    80001b26:	e822                	sd	s0,16(sp)
    80001b28:	e426                	sd	s1,8(sp)
    80001b2a:	e04a                	sd	s2,0(sp)
    80001b2c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2e:	0000e497          	auipc	s1,0xe
    80001b32:	28a48493          	addi	s1,s1,650 # 8000fdb8 <proc>
    80001b36:	00015917          	auipc	s2,0x15
    80001b3a:	48290913          	addi	s2,s2,1154 # 80016fb8 <tickslock>
    acquire(&p->lock);
    80001b3e:	8526                	mv	a0,s1
    80001b40:	88eff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b44:	4c9c                	lw	a5,24(s1)
    80001b46:	cb91                	beqz	a5,80001b5a <allocproc+0x38>
      release(&p->lock);
    80001b48:	8526                	mv	a0,s1
    80001b4a:	91cff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b4e:	1c848493          	addi	s1,s1,456
    80001b52:	ff2496e3          	bne	s1,s2,80001b3e <allocproc+0x1c>
  return 0;
    80001b56:	4481                	li	s1,0
    80001b58:	a059                	j	80001bde <allocproc+0xbc>
  p->pid = allocpid();
    80001b5a:	e3dff0ef          	jal	80001996 <allocpid>
    80001b5e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b60:	4785                	li	a5,1
    80001b62:	cc9c                	sw	a5,24(s1)
  p->priority = 0;        // process mới luôn ở queue cao nhất
    80001b64:	1604a423          	sw	zero,360(s1)
  p->ticks_used = 0;
    80001b68:	1604a623          	sw	zero,364(s1)
  p->wait_time = 0;
    80001b6c:	1604a823          	sw	zero,368(s1)
  p->total_runtime = 0;
    80001b70:	1604aa23          	sw	zero,372(s1)
  for(int i = 0; i < EDR_FORK_SAMPLE; i++) p->fork_times[i] = 0;
    80001b74:	1604bc23          	sd	zero,376(s1)
    80001b78:	1804b023          	sd	zero,384(s1)
    80001b7c:	1804b423          	sd	zero,392(s1)
    80001b80:	1804b823          	sd	zero,400(s1)
    80001b84:	1804bc23          	sd	zero,408(s1)
    80001b88:	1a04b023          	sd	zero,416(s1)
  p->fork_times_idx = 0;
    80001b8c:	1a04a423          	sw	zero,424(s1)
  p->cumulative_run_time = 0;
    80001b90:	1a04a623          	sw	zero,428(s1)
  p->is_sandboxed = 0;
    80001b94:	1a048823          	sb	zero,432(s1)
  p->sandbox_reason = 0;
    80001b98:	1a0488a3          	sb	zero,433(s1)
  p->quarantine_tick = 0;
    80001b9c:	1a04bc23          	sd	zero,440(s1)
  p->need_propagation = 0;
    80001ba0:	1c048023          	sb	zero,448(s1)
  p->edr_trusted = 0;
    80001ba4:	1c0480a3          	sb	zero,449(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ba8:	f57fe0ef          	jal	80000afe <kalloc>
    80001bac:	892a                	mv	s2,a0
    80001bae:	eca8                	sd	a0,88(s1)
    80001bb0:	cd15                	beqz	a0,80001bec <allocproc+0xca>
  p->pagetable = proc_pagetable(p);
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	e21ff0ef          	jal	800019d4 <proc_pagetable>
    80001bb8:	892a                	mv	s2,a0
    80001bba:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bbc:	c121                	beqz	a0,80001bfc <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001bbe:	07000613          	li	a2,112
    80001bc2:	4581                	li	a1,0
    80001bc4:	06048513          	addi	a0,s1,96
    80001bc8:	8daff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001bcc:	00000797          	auipc	a5,0x0
    80001bd0:	d3278793          	addi	a5,a5,-718 # 800018fe <forkret>
    80001bd4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bd6:	60bc                	ld	a5,64(s1)
    80001bd8:	6705                	lui	a4,0x1
    80001bda:	97ba                	add	a5,a5,a4
    80001bdc:	f4bc                	sd	a5,104(s1)
}
    80001bde:	8526                	mv	a0,s1
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6902                	ld	s2,0(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret
    freeproc(p);
    80001bec:	8526                	mv	a0,s1
    80001bee:	eb1ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	872ff0ef          	jal	80000c66 <release>
    return 0;
    80001bf8:	84ca                	mv	s1,s2
    80001bfa:	b7d5                	j	80001bde <allocproc+0xbc>
    freeproc(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	ea1ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	862ff0ef          	jal	80000c66 <release>
    return 0;
    80001c08:	84ca                	mv	s1,s2
    80001c0a:	bfd1                	j	80001bde <allocproc+0xbc>

0000000080001c0c <userinit>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c16:	f0dff0ef          	jal	80001b22 <allocproc>
    80001c1a:	84aa                	mv	s1,a0
  initproc = p;
    80001c1c:	00006797          	auipc	a5,0x6
    80001c20:	c6a7b223          	sd	a0,-924(a5) # 80007880 <initproc>
  p->cwd = namei("/");
    80001c24:	00005517          	auipc	a0,0x5
    80001c28:	56c50513          	addi	a0,a0,1388 # 80007190 <etext+0x190>
    80001c2c:	400020ef          	jal	8000402c <namei>
    80001c30:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c34:	478d                	li	a5,3
    80001c36:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	82cff0ef          	jal	80000c66 <release>
}
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6105                	addi	sp,sp,32
    80001c46:	8082                	ret

0000000080001c48 <growproc>:
{
    80001c48:	1101                	addi	sp,sp,-32
    80001c4a:	ec06                	sd	ra,24(sp)
    80001c4c:	e822                	sd	s0,16(sp)
    80001c4e:	e426                	sd	s1,8(sp)
    80001c50:	e04a                	sd	s2,0(sp)
    80001c52:	1000                	addi	s0,sp,32
    80001c54:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c56:	c79ff0ef          	jal	800018ce <myproc>
    80001c5a:	892a                	mv	s2,a0
  sz = p->sz;
    80001c5c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c5e:	02905963          	blez	s1,80001c90 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c62:	00b48633          	add	a2,s1,a1
    80001c66:	020007b7          	lui	a5,0x2000
    80001c6a:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c6c:	07b6                	slli	a5,a5,0xd
    80001c6e:	02c7ea63          	bltu	a5,a2,80001ca2 <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c72:	4691                	li	a3,4
    80001c74:	6928                	ld	a0,80(a0)
    80001c76:	e12ff0ef          	jal	80001288 <uvmalloc>
    80001c7a:	85aa                	mv	a1,a0
    80001c7c:	c50d                	beqz	a0,80001ca6 <growproc+0x5e>
  p->sz = sz;
    80001c7e:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c82:	4501                	li	a0,0
}
    80001c84:	60e2                	ld	ra,24(sp)
    80001c86:	6442                	ld	s0,16(sp)
    80001c88:	64a2                	ld	s1,8(sp)
    80001c8a:	6902                	ld	s2,0(sp)
    80001c8c:	6105                	addi	sp,sp,32
    80001c8e:	8082                	ret
  } else if(n < 0){
    80001c90:	fe04d7e3          	bgez	s1,80001c7e <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c94:	00b48633          	add	a2,s1,a1
    80001c98:	6928                	ld	a0,80(a0)
    80001c9a:	daaff0ef          	jal	80001244 <uvmdealloc>
    80001c9e:	85aa                	mv	a1,a0
    80001ca0:	bff9                	j	80001c7e <growproc+0x36>
      return -1;
    80001ca2:	557d                	li	a0,-1
    80001ca4:	b7c5                	j	80001c84 <growproc+0x3c>
      return -1;
    80001ca6:	557d                	li	a0,-1
    80001ca8:	bff1                	j	80001c84 <growproc+0x3c>

0000000080001caa <kfork>:
{
    80001caa:	7139                	addi	sp,sp,-64
    80001cac:	fc06                	sd	ra,56(sp)
    80001cae:	f822                	sd	s0,48(sp)
    80001cb0:	f04a                	sd	s2,32(sp)
    80001cb2:	e456                	sd	s5,8(sp)
    80001cb4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001cb6:	c19ff0ef          	jal	800018ce <myproc>
    80001cba:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001cbc:	e67ff0ef          	jal	80001b22 <allocproc>
    80001cc0:	0e050a63          	beqz	a0,80001db4 <kfork+0x10a>
    80001cc4:	e852                	sd	s4,16(sp)
    80001cc6:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001cc8:	048ab603          	ld	a2,72(s5)
    80001ccc:	692c                	ld	a1,80(a0)
    80001cce:	050ab503          	ld	a0,80(s5)
    80001cd2:	eeeff0ef          	jal	800013c0 <uvmcopy>
    80001cd6:	04054a63          	bltz	a0,80001d2a <kfork+0x80>
    80001cda:	f426                	sd	s1,40(sp)
    80001cdc:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001cde:	048ab783          	ld	a5,72(s5)
    80001ce2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ce6:	058ab683          	ld	a3,88(s5)
    80001cea:	87b6                	mv	a5,a3
    80001cec:	058a3703          	ld	a4,88(s4)
    80001cf0:	12068693          	addi	a3,a3,288
    80001cf4:	0007b803          	ld	a6,0(a5)
    80001cf8:	6788                	ld	a0,8(a5)
    80001cfa:	6b8c                	ld	a1,16(a5)
    80001cfc:	6f90                	ld	a2,24(a5)
    80001cfe:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001d02:	e708                	sd	a0,8(a4)
    80001d04:	eb0c                	sd	a1,16(a4)
    80001d06:	ef10                	sd	a2,24(a4)
    80001d08:	02078793          	addi	a5,a5,32
    80001d0c:	02070713          	addi	a4,a4,32
    80001d10:	fed792e3          	bne	a5,a3,80001cf4 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001d14:	058a3783          	ld	a5,88(s4)
    80001d18:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001d1c:	0d0a8493          	addi	s1,s5,208
    80001d20:	0d0a0913          	addi	s2,s4,208
    80001d24:	150a8993          	addi	s3,s5,336
    80001d28:	a831                	j	80001d44 <kfork+0x9a>
    freeproc(np);
    80001d2a:	8552                	mv	a0,s4
    80001d2c:	d73ff0ef          	jal	80001a9e <freeproc>
    release(&np->lock);
    80001d30:	8552                	mv	a0,s4
    80001d32:	f35fe0ef          	jal	80000c66 <release>
    return -1;
    80001d36:	597d                	li	s2,-1
    80001d38:	6a42                	ld	s4,16(sp)
    80001d3a:	a0b5                	j	80001da6 <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001d3c:	04a1                	addi	s1,s1,8
    80001d3e:	0921                	addi	s2,s2,8
    80001d40:	01348963          	beq	s1,s3,80001d52 <kfork+0xa8>
    if(p->ofile[i])
    80001d44:	6088                	ld	a0,0(s1)
    80001d46:	d97d                	beqz	a0,80001d3c <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d48:	07f020ef          	jal	800045c6 <filedup>
    80001d4c:	00a93023          	sd	a0,0(s2)
    80001d50:	b7f5                	j	80001d3c <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d52:	150ab503          	ld	a0,336(s5)
    80001d56:	28b010ef          	jal	800037e0 <idup>
    80001d5a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d5e:	4641                	li	a2,16
    80001d60:	158a8593          	addi	a1,s5,344
    80001d64:	158a0513          	addi	a0,s4,344
    80001d68:	878ff0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001d6c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001d70:	8552                	mv	a0,s4
    80001d72:	ef5fe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001d76:	0000e497          	auipc	s1,0xe
    80001d7a:	c2a48493          	addi	s1,s1,-982 # 8000f9a0 <wait_lock>
    80001d7e:	8526                	mv	a0,s1
    80001d80:	e4ffe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001d84:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	eddfe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001d8e:	8552                	mv	a0,s4
    80001d90:	e3ffe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d9a:	8552                	mv	a0,s4
    80001d9c:	ecbfe0ef          	jal	80000c66 <release>
  return pid;
    80001da0:	74a2                	ld	s1,40(sp)
    80001da2:	69e2                	ld	s3,24(sp)
    80001da4:	6a42                	ld	s4,16(sp)
}
    80001da6:	854a                	mv	a0,s2
    80001da8:	70e2                	ld	ra,56(sp)
    80001daa:	7442                	ld	s0,48(sp)
    80001dac:	7902                	ld	s2,32(sp)
    80001dae:	6aa2                	ld	s5,8(sp)
    80001db0:	6121                	addi	sp,sp,64
    80001db2:	8082                	ret
    return -1;
    80001db4:	597d                	li	s2,-1
    80001db6:	bfc5                	j	80001da6 <kfork+0xfc>

0000000080001db8 <is_descendant>:
{
    80001db8:	1141                	addi	sp,sp,-16
    80001dba:	e422                	sd	s0,8(sp)
    80001dbc:	0800                	addi	s0,sp,16
  struct proc *curr = child->parent;
    80001dbe:	7d1c                	ld	a5,56(a0)
  while(curr){
    80001dc0:	cf89                	beqz	a5,80001dda <is_descendant+0x22>
    if(curr == root) return 1;
    80001dc2:	00b78e63          	beq	a5,a1,80001dde <is_descendant+0x26>
    curr = curr->parent;
    80001dc6:	7f9c                	ld	a5,56(a5)
  while(curr){
    80001dc8:	c789                	beqz	a5,80001dd2 <is_descendant+0x1a>
    if(curr == root) return 1;
    80001dca:	fef59ee3          	bne	a1,a5,80001dc6 <is_descendant+0xe>
    80001dce:	4505                	li	a0,1
    80001dd0:	a011                	j	80001dd4 <is_descendant+0x1c>
  return 0;
    80001dd2:	4501                	li	a0,0
}
    80001dd4:	6422                	ld	s0,8(sp)
    80001dd6:	0141                	addi	sp,sp,16
    80001dd8:	8082                	ret
  return 0;
    80001dda:	4501                	li	a0,0
    80001ddc:	bfe5                	j	80001dd4 <is_descendant+0x1c>
    if(curr == root) return 1;
    80001dde:	4505                	li	a0,1
    80001de0:	bfd5                	j	80001dd4 <is_descendant+0x1c>

0000000080001de2 <count_live_descendants>:
{
    80001de2:	7179                	addi	sp,sp,-48
    80001de4:	f406                	sd	ra,40(sp)
    80001de6:	f022                	sd	s0,32(sp)
    80001de8:	ec26                	sd	s1,24(sp)
    80001dea:	e84a                	sd	s2,16(sp)
    80001dec:	e44e                	sd	s3,8(sp)
    80001dee:	e052                	sd	s4,0(sp)
    80001df0:	1800                	addi	s0,sp,48
    80001df2:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80001df4:	0000e497          	auipc	s1,0xe
    80001df8:	fc448493          	addi	s1,s1,-60 # 8000fdb8 <proc>
  int count = 0;
    80001dfc:	4a01                	li	s4,0
  for(p = proc; p < &proc[NPROC]; p++){
    80001dfe:	00015917          	auipc	s2,0x15
    80001e02:	1ba90913          	addi	s2,s2,442 # 80016fb8 <tickslock>
    80001e06:	a029                	j	80001e10 <count_live_descendants+0x2e>
    80001e08:	1c848493          	addi	s1,s1,456
    80001e0c:	01248d63          	beq	s1,s2,80001e26 <count_live_descendants+0x44>
    if(p->state != UNUSED && p != root && is_descendant(p, root)){
    80001e10:	4c9c                	lw	a5,24(s1)
    80001e12:	dbfd                	beqz	a5,80001e08 <count_live_descendants+0x26>
    80001e14:	fe998ae3          	beq	s3,s1,80001e08 <count_live_descendants+0x26>
    80001e18:	85ce                	mv	a1,s3
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	f9dff0ef          	jal	80001db8 <is_descendant>
    80001e20:	d565                	beqz	a0,80001e08 <count_live_descendants+0x26>
      count++;
    80001e22:	2a05                	addiw	s4,s4,1
    80001e24:	b7d5                	j	80001e08 <count_live_descendants+0x26>
}
    80001e26:	8552                	mv	a0,s4
    80001e28:	70a2                	ld	ra,40(sp)
    80001e2a:	7402                	ld	s0,32(sp)
    80001e2c:	64e2                	ld	s1,24(sp)
    80001e2e:	6942                	ld	s2,16(sp)
    80001e30:	69a2                	ld	s3,8(sp)
    80001e32:	6a02                	ld	s4,0(sp)
    80001e34:	6145                	addi	sp,sp,48
    80001e36:	8082                	ret

0000000080001e38 <propagate_sandbox>:
{
    80001e38:	7139                	addi	sp,sp,-64
    80001e3a:	fc06                	sd	ra,56(sp)
    80001e3c:	f822                	sd	s0,48(sp)
    80001e3e:	f426                	sd	s1,40(sp)
    80001e40:	f04a                	sd	s2,32(sp)
    80001e42:	ec4e                	sd	s3,24(sp)
    80001e44:	e852                	sd	s4,16(sp)
    80001e46:	e456                	sd	s5,8(sp)
    80001e48:	0080                	addi	s0,sp,64
    80001e4a:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80001e4c:	0000e497          	auipc	s1,0xe
    80001e50:	f6c48493          	addi	s1,s1,-148 # 8000fdb8 <proc>
      p->is_sandboxed = 2; // QUARANTINED
    80001e54:	4a09                	li	s4,2
      p->quarantine_tick = ticks;
    80001e56:	00006a97          	auipc	s5,0x6
    80001e5a:	a32a8a93          	addi	s5,s5,-1486 # 80007888 <ticks>
  for(p = proc; p < &proc[NPROC]; p++){
    80001e5e:	00015917          	auipc	s2,0x15
    80001e62:	15a90913          	addi	s2,s2,346 # 80016fb8 <tickslock>
    80001e66:	a029                	j	80001e70 <propagate_sandbox+0x38>
    80001e68:	1c848493          	addi	s1,s1,456
    80001e6c:	03248a63          	beq	s1,s2,80001ea0 <propagate_sandbox+0x68>
    if(p->state != UNUSED && p != root && is_descendant(p, root)){
    80001e70:	4c9c                	lw	a5,24(s1)
    80001e72:	dbfd                	beqz	a5,80001e68 <propagate_sandbox+0x30>
    80001e74:	fe998ae3          	beq	s3,s1,80001e68 <propagate_sandbox+0x30>
    80001e78:	85ce                	mv	a1,s3
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	f3dff0ef          	jal	80001db8 <is_descendant>
    80001e80:	d565                	beqz	a0,80001e68 <propagate_sandbox+0x30>
      acquire(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	d4bfe0ef          	jal	80000bce <acquire>
      p->is_sandboxed = 2; // QUARANTINED
    80001e88:	1b448823          	sb	s4,432(s1)
      p->sandbox_reason = 2; // EDR_REASON_VOLUME
    80001e8c:	1b4488a3          	sb	s4,433(s1)
      p->quarantine_tick = ticks;
    80001e90:	000ae783          	lwu	a5,0(s5)
    80001e94:	1af4bc23          	sd	a5,440(s1)
      release(&p->lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	dcdfe0ef          	jal	80000c66 <release>
    80001e9e:	b7e9                	j	80001e68 <propagate_sandbox+0x30>
}
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret

0000000080001eb2 <scheduler>:
{
    80001eb2:	7119                	addi	sp,sp,-128
    80001eb4:	fc86                	sd	ra,120(sp)
    80001eb6:	f8a2                	sd	s0,112(sp)
    80001eb8:	f4a6                	sd	s1,104(sp)
    80001eba:	f0ca                	sd	s2,96(sp)
    80001ebc:	ecce                	sd	s3,88(sp)
    80001ebe:	e8d2                	sd	s4,80(sp)
    80001ec0:	e4d6                	sd	s5,72(sp)
    80001ec2:	e0da                	sd	s6,64(sp)
    80001ec4:	fc5e                	sd	s7,56(sp)
    80001ec6:	f862                	sd	s8,48(sp)
    80001ec8:	f466                	sd	s9,40(sp)
    80001eca:	f06a                	sd	s10,32(sp)
    80001ecc:	ec6e                	sd	s11,24(sp)
    80001ece:	0100                	addi	s0,sp,128
    80001ed0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed4:	00779693          	slli	a3,a5,0x7
    80001ed8:	0000e717          	auipc	a4,0xe
    80001edc:	ab070713          	addi	a4,a4,-1360 # 8000f988 <pid_lock>
    80001ee0:	9736                	add	a4,a4,a3
    80001ee2:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001ee6:	0000e717          	auipc	a4,0xe
    80001eea:	ada70713          	addi	a4,a4,-1318 # 8000f9c0 <cpus+0x8>
    80001eee:	9736                	add	a4,a4,a3
    80001ef0:	f8e43423          	sd	a4,-120(s0)
        p = &proc[idx];
    80001ef4:	0000eb17          	auipc	s6,0xe
    80001ef8:	ec4b0b13          	addi	s6,s6,-316 # 8000fdb8 <proc>
          c->proc = p;
    80001efc:	0000e717          	auipc	a4,0xe
    80001f00:	a8c70713          	addi	a4,a4,-1396 # 8000f988 <pid_lock>
    80001f04:	00d707b3          	add	a5,a4,a3
    80001f08:	f8f43023          	sd	a5,-128(s0)
    80001f0c:	a285                	j	8000206c <scheduler+0x1ba>
      if (__sync_lock_test_and_set(&edr_lock, 1) == 0) {
    80001f0e:	00006717          	auipc	a4,0x6
    80001f12:	96670713          	addi	a4,a4,-1690 # 80007874 <edr_lock>
    80001f16:	4785                	li	a5,1
    80001f18:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
    80001f1c:	2781                	sext.w	a5,a5
    80001f1e:	16079563          	bnez	a5,80002088 <scheduler+0x1d6>
        if (edr_work_pending) {
    80001f22:	00006797          	auipc	a5,0x6
    80001f26:	95678793          	addi	a5,a5,-1706 # 80007878 <edr_work_pending>
    80001f2a:	439c                	lw	a5,0(a5)
    80001f2c:	2781                	sext.w	a5,a5
    80001f2e:	eb91                	bnez	a5,80001f42 <scheduler+0x90>
        __sync_lock_release(&edr_lock);
    80001f30:	00006797          	auipc	a5,0x6
    80001f34:	94478793          	addi	a5,a5,-1724 # 80007874 <edr_lock>
    80001f38:	0f50000f          	fence	iorw,ow
    80001f3c:	0807a02f          	amoswap.w	zero,zero,(a5)
    80001f40:	a2a1                	j	80002088 <scheduler+0x1d6>
          edr_work_pending = 0;
    80001f42:	00006797          	auipc	a5,0x6
    80001f46:	93678793          	addi	a5,a5,-1738 # 80007878 <edr_work_pending>
    80001f4a:	0007a023          	sw	zero,0(a5)
          acquire(&wait_lock);
    80001f4e:	0000e517          	auipc	a0,0xe
    80001f52:	a5250513          	addi	a0,a0,-1454 # 8000f9a0 <wait_lock>
    80001f56:	c79fe0ef          	jal	80000bce <acquire>
          for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80001f5a:	0000e497          	auipc	s1,0xe
    80001f5e:	e5e48493          	addi	s1,s1,-418 # 8000fdb8 <proc>
              if (count >= EDR_TREE_VOLUME_THRESHOLD) {
    80001f62:	4a3d                	li	s4,15
                pp->is_sandboxed = 2;
    80001f64:	4a89                	li	s5,2
                pp->quarantine_tick = ticks;
    80001f66:	00006b97          	auipc	s7,0x6
    80001f6a:	922b8b93          	addi	s7,s7,-1758 # 80007888 <ticks>
          for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80001f6e:	00015997          	auipc	s3,0x15
    80001f72:	04a98993          	addi	s3,s3,74 # 80016fb8 <tickslock>
    80001f76:	a029                	j	80001f80 <scheduler+0xce>
    80001f78:	1c848493          	addi	s1,s1,456
    80001f7c:	05348563          	beq	s1,s3,80001fc6 <scheduler+0x114>
            acquire(&pp->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	c4dfe0ef          	jal	80000bce <acquire>
            int need_prop = pp->need_propagation;
    80001f86:	1c04c903          	lbu	s2,448(s1)
            pp->need_propagation = 0;
    80001f8a:	1c048023          	sb	zero,448(s1)
            release(&pp->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	cd7fe0ef          	jal	80000c66 <release>
            if (need_prop) {
    80001f94:	fe0902e3          	beqz	s2,80001f78 <scheduler+0xc6>
              int count = count_live_descendants(pp);
    80001f98:	8526                	mv	a0,s1
    80001f9a:	e49ff0ef          	jal	80001de2 <count_live_descendants>
              if (count >= EDR_TREE_VOLUME_THRESHOLD) {
    80001f9e:	fcaa5de3          	bge	s4,a0,80001f78 <scheduler+0xc6>
                acquire(&pp->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	c2bfe0ef          	jal	80000bce <acquire>
                pp->is_sandboxed = 2;
    80001fa8:	1b548823          	sb	s5,432(s1)
                pp->sandbox_reason = 2; // EDR_REASON_VOLUME
    80001fac:	1b5488a3          	sb	s5,433(s1)
                pp->quarantine_tick = ticks;
    80001fb0:	000be783          	lwu	a5,0(s7)
    80001fb4:	1af4bc23          	sd	a5,440(s1)
                release(&pp->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	cadfe0ef          	jal	80000c66 <release>
                propagate_sandbox(pp);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	e79ff0ef          	jal	80001e38 <propagate_sandbox>
    80001fc4:	bf55                	j	80001f78 <scheduler+0xc6>
          release(&wait_lock);
    80001fc6:	0000e517          	auipc	a0,0xe
    80001fca:	9da50513          	addi	a0,a0,-1574 # 8000f9a0 <wait_lock>
    80001fce:	c99fe0ef          	jal	80000c66 <release>
    80001fd2:	bfb9                	j	80001f30 <scheduler+0x7e>
            release(&p->lock);
    80001fd4:	854a                	mv	a0,s2
    80001fd6:	c91fe0ef          	jal	80000c66 <release>
            continue;
    80001fda:	a021                	j	80001fe2 <scheduler+0x130>
        release(&p->lock);
    80001fdc:	854a                	mv	a0,s2
    80001fde:	c89fe0ef          	jal	80000c66 <release>
      for(int i = 0; i < NPROC; i++) {
    80001fe2:	2985                	addiw	s3,s3,1
    80001fe4:	0da98363          	beq	s3,s10,800020aa <scheduler+0x1f8>
        int idx = (last_idx + 1 + i) % NPROC;
    80001fe8:	000c2483          	lw	s1,0(s8) # fffffffffffff000 <end+0xffffffff7ffdcc68>
    80001fec:	2485                	addiw	s1,s1,1
    80001fee:	013484bb          	addw	s1,s1,s3
    80001ff2:	41f4d79b          	sraiw	a5,s1,0x1f
    80001ff6:	01a7d79b          	srliw	a5,a5,0x1a
    80001ffa:	9cbd                	addw	s1,s1,a5
    80001ffc:	03f4f493          	andi	s1,s1,63
    80002000:	9c9d                	subw	s1,s1,a5
    80002002:	00048a1b          	sext.w	s4,s1
        p = &proc[idx];
    80002006:	037a0ab3          	mul	s5,s4,s7
    8000200a:	016a8933          	add	s2,s5,s6
        acquire(&p->lock);
    8000200e:	854a                	mv	a0,s2
    80002010:	bbffe0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE && p->priority == pr) {
    80002014:	01892783          	lw	a5,24(s2)
    80002018:	fd9792e3          	bne	a5,s9,80001fdc <scheduler+0x12a>
    8000201c:	16892783          	lw	a5,360(s2)
    80002020:	fbb79ee3          	bne	a5,s11,80001fdc <scheduler+0x12a>
          if (p->is_sandboxed == 2 && p->killed == 0) {
    80002024:	1b094783          	lbu	a5,432(s2)
    80002028:	4709                	li	a4,2
    8000202a:	00e79563          	bne	a5,a4,80002034 <scheduler+0x182>
    8000202e:	02892783          	lw	a5,40(s2)
    80002032:	d3cd                	beqz	a5,80001fd4 <scheduler+0x122>
          p->state = RUNNING;
    80002034:	1c800793          	li	a5,456
    80002038:	02fa0a33          	mul	s4,s4,a5
    8000203c:	9a5a                	add	s4,s4,s6
    8000203e:	4791                	li	a5,4
    80002040:	00fa2c23          	sw	a5,24(s4)
          c->proc = p;
    80002044:	f8043983          	ld	s3,-128(s0)
    80002048:	0329b823          	sd	s2,48(s3)
          last_idx = idx;
    8000204c:	00006797          	auipc	a5,0x6
    80002050:	8297a223          	sw	s1,-2012(a5) # 80007870 <last_idx.2>
          swtch(&c->context, &p->context);
    80002054:	060a8593          	addi	a1,s5,96
    80002058:	95da                	add	a1,a1,s6
    8000205a:	f8843503          	ld	a0,-120(s0)
    8000205e:	688000ef          	jal	800026e6 <swtch>
          c->proc = 0;
    80002062:	0209b823          	sd	zero,48(s3)
          release(&p->lock);
    80002066:	854a                	mv	a0,s2
    80002068:	bfffe0ef          	jal	80000c66 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002070:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002074:	10079073          	csrw	sstatus,a5
    if (edr_work_pending) {
    80002078:	00006797          	auipc	a5,0x6
    8000207c:	80078793          	addi	a5,a5,-2048 # 80007878 <edr_work_pending>
    80002080:	439c                	lw	a5,0(a5)
    80002082:	2781                	sext.w	a5,a5
    80002084:	e80795e3          	bnez	a5,80001f0e <scheduler+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000208c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000208e:	10079073          	csrw	sstatus,a5
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    80002092:	4d81                	li	s11,0
        int idx = (last_idx + 1 + i) % NPROC;
    80002094:	00005c17          	auipc	s8,0x5
    80002098:	7dcc0c13          	addi	s8,s8,2012 # 80007870 <last_idx.2>
    8000209c:	1c800b93          	li	s7,456
      for(int i = 0; i < NPROC; i++) {
    800020a0:	4981                	li	s3,0
        if(p->state == RUNNABLE && p->priority == pr) {
    800020a2:	4c8d                	li	s9,3
      for(int i = 0; i < NPROC; i++) {
    800020a4:	04000d13          	li	s10,64
    800020a8:	b781                	j	80001fe8 <scheduler+0x136>
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    800020aa:	2d85                	addiw	s11,s11,1
    800020ac:	478d                	li	a5,3
    800020ae:	fefd99e3          	bne	s11,a5,800020a0 <scheduler+0x1ee>
      asm volatile("wfi");
    800020b2:	10500073          	wfi
    800020b6:	bf5d                	j	8000206c <scheduler+0x1ba>

00000000800020b8 <sched>:
{
    800020b8:	7179                	addi	sp,sp,-48
    800020ba:	f406                	sd	ra,40(sp)
    800020bc:	f022                	sd	s0,32(sp)
    800020be:	ec26                	sd	s1,24(sp)
    800020c0:	e84a                	sd	s2,16(sp)
    800020c2:	e44e                	sd	s3,8(sp)
    800020c4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c6:	809ff0ef          	jal	800018ce <myproc>
    800020ca:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020cc:	a99fe0ef          	jal	80000b64 <holding>
    800020d0:	c92d                	beqz	a0,80002142 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020d4:	2781                	sext.w	a5,a5
    800020d6:	079e                	slli	a5,a5,0x7
    800020d8:	0000e717          	auipc	a4,0xe
    800020dc:	8b070713          	addi	a4,a4,-1872 # 8000f988 <pid_lock>
    800020e0:	97ba                	add	a5,a5,a4
    800020e2:	0a87a703          	lw	a4,168(a5)
    800020e6:	4785                	li	a5,1
    800020e8:	06f71363          	bne	a4,a5,8000214e <sched+0x96>
  if(p->state == RUNNING)
    800020ec:	4c98                	lw	a4,24(s1)
    800020ee:	4791                	li	a5,4
    800020f0:	06f70563          	beq	a4,a5,8000215a <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020fa:	e7b5                	bnez	a5,80002166 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020fe:	0000e917          	auipc	s2,0xe
    80002102:	88a90913          	addi	s2,s2,-1910 # 8000f988 <pid_lock>
    80002106:	2781                	sext.w	a5,a5
    80002108:	079e                	slli	a5,a5,0x7
    8000210a:	97ca                	add	a5,a5,s2
    8000210c:	0ac7a983          	lw	s3,172(a5)
    80002110:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002112:	2781                	sext.w	a5,a5
    80002114:	079e                	slli	a5,a5,0x7
    80002116:	0000e597          	auipc	a1,0xe
    8000211a:	8aa58593          	addi	a1,a1,-1878 # 8000f9c0 <cpus+0x8>
    8000211e:	95be                	add	a1,a1,a5
    80002120:	06048513          	addi	a0,s1,96
    80002124:	5c2000ef          	jal	800026e6 <swtch>
    80002128:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000212a:	2781                	sext.w	a5,a5
    8000212c:	079e                	slli	a5,a5,0x7
    8000212e:	993e                	add	s2,s2,a5
    80002130:	0b392623          	sw	s3,172(s2)
}
    80002134:	70a2                	ld	ra,40(sp)
    80002136:	7402                	ld	s0,32(sp)
    80002138:	64e2                	ld	s1,24(sp)
    8000213a:	6942                	ld	s2,16(sp)
    8000213c:	69a2                	ld	s3,8(sp)
    8000213e:	6145                	addi	sp,sp,48
    80002140:	8082                	ret
    panic("sched p->lock");
    80002142:	00005517          	auipc	a0,0x5
    80002146:	05650513          	addi	a0,a0,86 # 80007198 <etext+0x198>
    8000214a:	e96fe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    8000214e:	00005517          	auipc	a0,0x5
    80002152:	05a50513          	addi	a0,a0,90 # 800071a8 <etext+0x1a8>
    80002156:	e8afe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    8000215a:	00005517          	auipc	a0,0x5
    8000215e:	05e50513          	addi	a0,a0,94 # 800071b8 <etext+0x1b8>
    80002162:	e7efe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80002166:	00005517          	auipc	a0,0x5
    8000216a:	06250513          	addi	a0,a0,98 # 800071c8 <etext+0x1c8>
    8000216e:	e72fe0ef          	jal	800007e0 <panic>

0000000080002172 <yield>:
{
    80002172:	1101                	addi	sp,sp,-32
    80002174:	ec06                	sd	ra,24(sp)
    80002176:	e822                	sd	s0,16(sp)
    80002178:	e426                	sd	s1,8(sp)
    8000217a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000217c:	f52ff0ef          	jal	800018ce <myproc>
    80002180:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002182:	a4dfe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80002186:	478d                	li	a5,3
    80002188:	cc9c                	sw	a5,24(s1)
  sched();
    8000218a:	f2fff0ef          	jal	800020b8 <sched>
  release(&p->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	ad7fe0ef          	jal	80000c66 <release>
}
    80002194:	60e2                	ld	ra,24(sp)
    80002196:	6442                	ld	s0,16(sp)
    80002198:	64a2                	ld	s1,8(sp)
    8000219a:	6105                	addi	sp,sp,32
    8000219c:	8082                	ret

000000008000219e <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	89aa                	mv	s3,a0
    800021ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021b0:	f1eff0ef          	jal	800018ce <myproc>
    800021b4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021b6:	a19fe0ef          	jal	80000bce <acquire>
  release(lk);
    800021ba:	854a                	mv	a0,s2
    800021bc:	aabfe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    800021c0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021c4:	4789                	li	a5,2
    800021c6:	cc9c                	sw	a5,24(s1)
  p->ticks_used = 0; // Đặt lại để khi thức dậy có quantum đầy đủ
    800021c8:	1604a623          	sw	zero,364(s1)

  sched();
    800021cc:	eedff0ef          	jal	800020b8 <sched>

  // Tidy up.
  p->chan = 0;
    800021d0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	a91fe0ef          	jal	80000c66 <release>
  acquire(lk);
    800021da:	854a                	mv	a0,s2
    800021dc:	9f3fe0ef          	jal	80000bce <acquire>
}
    800021e0:	70a2                	ld	ra,40(sp)
    800021e2:	7402                	ld	s0,32(sp)
    800021e4:	64e2                	ld	s1,24(sp)
    800021e6:	6942                	ld	s2,16(sp)
    800021e8:	69a2                	ld	s3,8(sp)
    800021ea:	6145                	addi	sp,sp,48
    800021ec:	8082                	ret

00000000800021ee <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    800021ee:	7139                	addi	sp,sp,-64
    800021f0:	fc06                	sd	ra,56(sp)
    800021f2:	f822                	sd	s0,48(sp)
    800021f4:	f426                	sd	s1,40(sp)
    800021f6:	f04a                	sd	s2,32(sp)
    800021f8:	ec4e                	sd	s3,24(sp)
    800021fa:	e852                	sd	s4,16(sp)
    800021fc:	e456                	sd	s5,8(sp)
    800021fe:	0080                	addi	s0,sp,64
    80002200:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	0000e497          	auipc	s1,0xe
    80002206:	bb648493          	addi	s1,s1,-1098 # 8000fdb8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000220a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000220c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000220e:	00015917          	auipc	s2,0x15
    80002212:	daa90913          	addi	s2,s2,-598 # 80016fb8 <tickslock>
    80002216:	a801                	j	80002226 <wakeup+0x38>
      }
      release(&p->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	a4dfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221e:	1c848493          	addi	s1,s1,456
    80002222:	03248263          	beq	s1,s2,80002246 <wakeup+0x58>
    if(p != myproc()){
    80002226:	ea8ff0ef          	jal	800018ce <myproc>
    8000222a:	fea48ae3          	beq	s1,a0,8000221e <wakeup+0x30>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	99ffe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	ff3791e3          	bne	a5,s3,80002218 <wakeup+0x2a>
    8000223a:	709c                	ld	a5,32(s1)
    8000223c:	fd479ee3          	bne	a5,s4,80002218 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002240:	0154ac23          	sw	s5,24(s1)
    80002244:	bfd1                	j	80002218 <wakeup+0x2a>
    }
  }
}
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	7902                	ld	s2,32(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
    80002252:	6aa2                	ld	s5,8(sp)
    80002254:	6121                	addi	sp,sp,64
    80002256:	8082                	ret

0000000080002258 <reparent>:
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	e052                	sd	s4,0(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	0000e497          	auipc	s1,0xe
    8000226e:	b4e48493          	addi	s1,s1,-1202 # 8000fdb8 <proc>
      pp->parent = initproc;
    80002272:	00005a17          	auipc	s4,0x5
    80002276:	60ea0a13          	addi	s4,s4,1550 # 80007880 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	00015997          	auipc	s3,0x15
    8000227e:	d3e98993          	addi	s3,s3,-706 # 80016fb8 <tickslock>
    80002282:	a029                	j	8000228c <reparent+0x34>
    80002284:	1c848493          	addi	s1,s1,456
    80002288:	01348b63          	beq	s1,s3,8000229e <reparent+0x46>
    if(pp->parent == p){
    8000228c:	7c9c                	ld	a5,56(s1)
    8000228e:	ff279be3          	bne	a5,s2,80002284 <reparent+0x2c>
      pp->parent = initproc;
    80002292:	000a3503          	ld	a0,0(s4)
    80002296:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002298:	f57ff0ef          	jal	800021ee <wakeup>
    8000229c:	b7e5                	j	80002284 <reparent+0x2c>
}
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	64e2                	ld	s1,24(sp)
    800022a4:	6942                	ld	s2,16(sp)
    800022a6:	69a2                	ld	s3,8(sp)
    800022a8:	6a02                	ld	s4,0(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret

00000000800022ae <kexit>:
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	e052                	sd	s4,0(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c0:	e0eff0ef          	jal	800018ce <myproc>
    800022c4:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c6:	00005797          	auipc	a5,0x5
    800022ca:	5ba7b783          	ld	a5,1466(a5) # 80007880 <initproc>
    800022ce:	0d050493          	addi	s1,a0,208
    800022d2:	15050913          	addi	s2,a0,336
    800022d6:	00a79f63          	bne	a5,a0,800022f4 <kexit+0x46>
    panic("init exiting");
    800022da:	00005517          	auipc	a0,0x5
    800022de:	f0650513          	addi	a0,a0,-250 # 800071e0 <etext+0x1e0>
    800022e2:	cfefe0ef          	jal	800007e0 <panic>
      fileclose(f);
    800022e6:	326020ef          	jal	8000460c <fileclose>
      p->ofile[fd] = 0;
    800022ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022ee:	04a1                	addi	s1,s1,8
    800022f0:	01248563          	beq	s1,s2,800022fa <kexit+0x4c>
    if(p->ofile[fd]){
    800022f4:	6088                	ld	a0,0(s1)
    800022f6:	f965                	bnez	a0,800022e6 <kexit+0x38>
    800022f8:	bfdd                	j	800022ee <kexit+0x40>
  begin_op();
    800022fa:	707010ef          	jal	80004200 <begin_op>
  iput(p->cwd);
    800022fe:	1509b503          	ld	a0,336(s3)
    80002302:	696010ef          	jal	80003998 <iput>
  end_op();
    80002306:	765010ef          	jal	8000426a <end_op>
  p->cwd = 0;
    8000230a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000230e:	0000d497          	auipc	s1,0xd
    80002312:	69248493          	addi	s1,s1,1682 # 8000f9a0 <wait_lock>
    80002316:	8526                	mv	a0,s1
    80002318:	8b7fe0ef          	jal	80000bce <acquire>
  reparent(p);
    8000231c:	854e                	mv	a0,s3
    8000231e:	f3bff0ef          	jal	80002258 <reparent>
  wakeup(p->parent);
    80002322:	0389b503          	ld	a0,56(s3)
    80002326:	ec9ff0ef          	jal	800021ee <wakeup>
  acquire(&p->lock);
    8000232a:	854e                	mv	a0,s3
    8000232c:	8a3fe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    80002330:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002334:	4795                	li	a5,5
    80002336:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	92bfe0ef          	jal	80000c66 <release>
  sched();
    80002340:	d79ff0ef          	jal	800020b8 <sched>
  panic("zombie exit");
    80002344:	00005517          	auipc	a0,0x5
    80002348:	eac50513          	addi	a0,a0,-340 # 800071f0 <etext+0x1f0>
    8000234c:	c94fe0ef          	jal	800007e0 <panic>

0000000080002350 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002350:	7179                	addi	sp,sp,-48
    80002352:	f406                	sd	ra,40(sp)
    80002354:	f022                	sd	s0,32(sp)
    80002356:	ec26                	sd	s1,24(sp)
    80002358:	e84a                	sd	s2,16(sp)
    8000235a:	e44e                	sd	s3,8(sp)
    8000235c:	1800                	addi	s0,sp,48
    8000235e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002360:	0000e497          	auipc	s1,0xe
    80002364:	a5848493          	addi	s1,s1,-1448 # 8000fdb8 <proc>
    80002368:	00015997          	auipc	s3,0x15
    8000236c:	c5098993          	addi	s3,s3,-944 # 80016fb8 <tickslock>
    acquire(&p->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	85dfe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    80002376:	589c                	lw	a5,48(s1)
    80002378:	01278b63          	beq	a5,s2,8000238e <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	8e9fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002382:	1c848493          	addi	s1,s1,456
    80002386:	ff3495e3          	bne	s1,s3,80002370 <kkill+0x20>
  }
  return -1;
    8000238a:	557d                	li	a0,-1
    8000238c:	a819                	j	800023a2 <kkill+0x52>
      p->killed = 1;
    8000238e:	4785                	li	a5,1
    80002390:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002392:	4c98                	lw	a4,24(s1)
    80002394:	4789                	li	a5,2
    80002396:	00f70d63          	beq	a4,a5,800023b0 <kkill+0x60>
      release(&p->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	8cbfe0ef          	jal	80000c66 <release>
      return 0;
    800023a0:	4501                	li	a0,0
}
    800023a2:	70a2                	ld	ra,40(sp)
    800023a4:	7402                	ld	s0,32(sp)
    800023a6:	64e2                	ld	s1,24(sp)
    800023a8:	6942                	ld	s2,16(sp)
    800023aa:	69a2                	ld	s3,8(sp)
    800023ac:	6145                	addi	sp,sp,48
    800023ae:	8082                	ret
        p->state = RUNNABLE;
    800023b0:	478d                	li	a5,3
    800023b2:	cc9c                	sw	a5,24(s1)
    800023b4:	b7dd                	j	8000239a <kkill+0x4a>

00000000800023b6 <setkilled>:

void
setkilled(struct proc *p)
{
    800023b6:	1101                	addi	sp,sp,-32
    800023b8:	ec06                	sd	ra,24(sp)
    800023ba:	e822                	sd	s0,16(sp)
    800023bc:	e426                	sd	s1,8(sp)
    800023be:	1000                	addi	s0,sp,32
    800023c0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023c2:	80dfe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    800023c6:	4785                	li	a5,1
    800023c8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	89bfe0ef          	jal	80000c66 <release>
}
    800023d0:	60e2                	ld	ra,24(sp)
    800023d2:	6442                	ld	s0,16(sp)
    800023d4:	64a2                	ld	s1,8(sp)
    800023d6:	6105                	addi	sp,sp,32
    800023d8:	8082                	ret

00000000800023da <killed>:

int
killed(struct proc *p)
{
    800023da:	1101                	addi	sp,sp,-32
    800023dc:	ec06                	sd	ra,24(sp)
    800023de:	e822                	sd	s0,16(sp)
    800023e0:	e426                	sd	s1,8(sp)
    800023e2:	e04a                	sd	s2,0(sp)
    800023e4:	1000                	addi	s0,sp,32
    800023e6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023e8:	fe6fe0ef          	jal	80000bce <acquire>
  k = p->killed;
    800023ec:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	875fe0ef          	jal	80000c66 <release>
  return k;
}
    800023f6:	854a                	mv	a0,s2
    800023f8:	60e2                	ld	ra,24(sp)
    800023fa:	6442                	ld	s0,16(sp)
    800023fc:	64a2                	ld	s1,8(sp)
    800023fe:	6902                	ld	s2,0(sp)
    80002400:	6105                	addi	sp,sp,32
    80002402:	8082                	ret

0000000080002404 <kwait>:
{
    80002404:	715d                	addi	sp,sp,-80
    80002406:	e486                	sd	ra,72(sp)
    80002408:	e0a2                	sd	s0,64(sp)
    8000240a:	fc26                	sd	s1,56(sp)
    8000240c:	f84a                	sd	s2,48(sp)
    8000240e:	f44e                	sd	s3,40(sp)
    80002410:	f052                	sd	s4,32(sp)
    80002412:	ec56                	sd	s5,24(sp)
    80002414:	e85a                	sd	s6,16(sp)
    80002416:	e45e                	sd	s7,8(sp)
    80002418:	e062                	sd	s8,0(sp)
    8000241a:	0880                	addi	s0,sp,80
    8000241c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000241e:	cb0ff0ef          	jal	800018ce <myproc>
    80002422:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002424:	0000d517          	auipc	a0,0xd
    80002428:	57c50513          	addi	a0,a0,1404 # 8000f9a0 <wait_lock>
    8000242c:	fa2fe0ef          	jal	80000bce <acquire>
    havekids = 0;
    80002430:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002432:	4a15                	li	s4,5
        havekids = 1;
    80002434:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002436:	00015997          	auipc	s3,0x15
    8000243a:	b8298993          	addi	s3,s3,-1150 # 80016fb8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243e:	0000dc17          	auipc	s8,0xd
    80002442:	562c0c13          	addi	s8,s8,1378 # 8000f9a0 <wait_lock>
    80002446:	a871                	j	800024e2 <kwait+0xde>
          pid = pp->pid;
    80002448:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000244c:	000b0c63          	beqz	s6,80002464 <kwait+0x60>
    80002450:	4691                	li	a3,4
    80002452:	02c48613          	addi	a2,s1,44
    80002456:	85da                	mv	a1,s6
    80002458:	05093503          	ld	a0,80(s2)
    8000245c:	986ff0ef          	jal	800015e2 <copyout>
    80002460:	02054b63          	bltz	a0,80002496 <kwait+0x92>
          freeproc(pp);
    80002464:	8526                	mv	a0,s1
    80002466:	e38ff0ef          	jal	80001a9e <freeproc>
          release(&pp->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffafe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    80002470:	0000d517          	auipc	a0,0xd
    80002474:	53050513          	addi	a0,a0,1328 # 8000f9a0 <wait_lock>
    80002478:	feefe0ef          	jal	80000c66 <release>
}
    8000247c:	854e                	mv	a0,s3
    8000247e:	60a6                	ld	ra,72(sp)
    80002480:	6406                	ld	s0,64(sp)
    80002482:	74e2                	ld	s1,56(sp)
    80002484:	7942                	ld	s2,48(sp)
    80002486:	79a2                	ld	s3,40(sp)
    80002488:	7a02                	ld	s4,32(sp)
    8000248a:	6ae2                	ld	s5,24(sp)
    8000248c:	6b42                	ld	s6,16(sp)
    8000248e:	6ba2                	ld	s7,8(sp)
    80002490:	6c02                	ld	s8,0(sp)
    80002492:	6161                	addi	sp,sp,80
    80002494:	8082                	ret
            release(&pp->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fcefe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    8000249c:	0000d517          	auipc	a0,0xd
    800024a0:	50450513          	addi	a0,a0,1284 # 8000f9a0 <wait_lock>
    800024a4:	fc2fe0ef          	jal	80000c66 <release>
            return -1;
    800024a8:	59fd                	li	s3,-1
    800024aa:	bfc9                	j	8000247c <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ac:	1c848493          	addi	s1,s1,456
    800024b0:	03348063          	beq	s1,s3,800024d0 <kwait+0xcc>
      if(pp->parent == p){
    800024b4:	7c9c                	ld	a5,56(s1)
    800024b6:	ff279be3          	bne	a5,s2,800024ac <kwait+0xa8>
        acquire(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	f12fe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800024c0:	4c9c                	lw	a5,24(s1)
    800024c2:	f94783e3          	beq	a5,s4,80002448 <kwait+0x44>
        release(&pp->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	f9efe0ef          	jal	80000c66 <release>
        havekids = 1;
    800024cc:	8756                	mv	a4,s5
    800024ce:	bff9                	j	800024ac <kwait+0xa8>
    if(!havekids || killed(p)){
    800024d0:	cf19                	beqz	a4,800024ee <kwait+0xea>
    800024d2:	854a                	mv	a0,s2
    800024d4:	f07ff0ef          	jal	800023da <killed>
    800024d8:	e919                	bnez	a0,800024ee <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024da:	85e2                	mv	a1,s8
    800024dc:	854a                	mv	a0,s2
    800024de:	cc1ff0ef          	jal	8000219e <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000e497          	auipc	s1,0xe
    800024e8:	8d448493          	addi	s1,s1,-1836 # 8000fdb8 <proc>
    800024ec:	b7e1                	j	800024b4 <kwait+0xb0>
      release(&wait_lock);
    800024ee:	0000d517          	auipc	a0,0xd
    800024f2:	4b250513          	addi	a0,a0,1202 # 8000f9a0 <wait_lock>
    800024f6:	f70fe0ef          	jal	80000c66 <release>
      return -1;
    800024fa:	59fd                	li	s3,-1
    800024fc:	b741                	j	8000247c <kwait+0x78>

00000000800024fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	84aa                	mv	s1,a0
    80002510:	892e                	mv	s2,a1
    80002512:	89b2                	mv	s3,a2
    80002514:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002516:	bb8ff0ef          	jal	800018ce <myproc>
  if(user_dst){
    8000251a:	cc99                	beqz	s1,80002538 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000251c:	86d2                	mv	a3,s4
    8000251e:	864e                	mv	a2,s3
    80002520:	85ca                	mv	a1,s2
    80002522:	6928                	ld	a0,80(a0)
    80002524:	8beff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002528:	70a2                	ld	ra,40(sp)
    8000252a:	7402                	ld	s0,32(sp)
    8000252c:	64e2                	ld	s1,24(sp)
    8000252e:	6942                	ld	s2,16(sp)
    80002530:	69a2                	ld	s3,8(sp)
    80002532:	6a02                	ld	s4,0(sp)
    80002534:	6145                	addi	sp,sp,48
    80002536:	8082                	ret
    memmove((char *)dst, src, len);
    80002538:	000a061b          	sext.w	a2,s4
    8000253c:	85ce                	mv	a1,s3
    8000253e:	854a                	mv	a0,s2
    80002540:	fbefe0ef          	jal	80000cfe <memmove>
    return 0;
    80002544:	8526                	mv	a0,s1
    80002546:	b7cd                	j	80002528 <either_copyout+0x2a>

0000000080002548 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	892a                	mv	s2,a0
    8000255a:	84ae                	mv	s1,a1
    8000255c:	89b2                	mv	s3,a2
    8000255e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002560:	b6eff0ef          	jal	800018ce <myproc>
  if(user_src){
    80002564:	cc99                	beqz	s1,80002582 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002566:	86d2                	mv	a3,s4
    80002568:	864e                	mv	a2,s3
    8000256a:	85ca                	mv	a1,s2
    8000256c:	6928                	ld	a0,80(a0)
    8000256e:	958ff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6a02                	ld	s4,0(sp)
    8000257e:	6145                	addi	sp,sp,48
    80002580:	8082                	ret
    memmove(dst, (char*)src, len);
    80002582:	000a061b          	sext.w	a2,s4
    80002586:	85ce                	mv	a1,s3
    80002588:	854a                	mv	a0,s2
    8000258a:	f74fe0ef          	jal	80000cfe <memmove>
    return 0;
    8000258e:	8526                	mv	a0,s1
    80002590:	b7cd                	j	80002572 <either_copyin+0x2a>

0000000080002592 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002592:	711d                	addi	sp,sp,-96
    80002594:	ec86                	sd	ra,88(sp)
    80002596:	e8a2                	sd	s0,80(sp)
    80002598:	e4a6                	sd	s1,72(sp)
    8000259a:	e0ca                	sd	s2,64(sp)
    8000259c:	fc4e                	sd	s3,56(sp)
    8000259e:	f852                	sd	s4,48(sp)
    800025a0:	f456                	sd	s5,40(sp)
    800025a2:	f05a                	sd	s6,32(sp)
    800025a4:	ec5e                	sd	s7,24(sp)
    800025a6:	e862                	sd	s8,16(sp)
    800025a8:	e466                	sd	s9,8(sp)
    800025aa:	e06a                	sd	s10,0(sp)
    800025ac:	1080                	addi	s0,sp,96
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ae:	00005517          	auipc	a0,0x5
    800025b2:	aca50513          	addi	a0,a0,-1334 # 80007078 <etext+0x78>
    800025b6:	f45fd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ba:	0000e497          	auipc	s1,0xe
    800025be:	95648493          	addi	s1,s1,-1706 # 8000ff10 <proc+0x158>
    800025c2:	00015997          	auipc	s3,0x15
    800025c6:	b4e98993          	addi	s3,s3,-1202 # 80017110 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ca:	4c15                	li	s8,5
      state = states[p->state];
    else
      state = "???";
    800025cc:	00005a17          	auipc	s4,0x5
    800025d0:	c34a0a13          	addi	s4,s4,-972 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    800025d4:	00005b97          	auipc	s7,0x5
    800025d8:	c34b8b93          	addi	s7,s7,-972 # 80007208 <etext+0x208>
    if(p->is_sandboxed == 2)
    800025dc:	4b09                	li	s6,2
      printf(" (quarantined)");
    printf("\n");
    800025de:	00005a97          	auipc	s5,0x5
    800025e2:	a9aa8a93          	addi	s5,s5,-1382 # 80007078 <etext+0x78>
      printf(" (quarantined)");
    800025e6:	00005d17          	auipc	s10,0x5
    800025ea:	c32d0d13          	addi	s10,s10,-974 # 80007218 <etext+0x218>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	00005c97          	auipc	s9,0x5
    800025f2:	14ac8c93          	addi	s9,s9,330 # 80007738 <states.0>
    800025f6:	a015                	j	8000261a <procdump+0x88>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	86ca                	mv	a3,s2
    800025fa:	ed892583          	lw	a1,-296(s2)
    800025fe:	855e                	mv	a0,s7
    80002600:	efbfd0ef          	jal	800004fa <printf>
    if(p->is_sandboxed == 2)
    80002604:	05894783          	lbu	a5,88(s2)
    80002608:	03678963          	beq	a5,s6,8000263a <procdump+0xa8>
    printf("\n");
    8000260c:	8556                	mv	a0,s5
    8000260e:	eedfd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	1c848493          	addi	s1,s1,456
    80002616:	03348663          	beq	s1,s3,80002642 <procdump+0xb0>
    if(p->state == UNUSED)
    8000261a:	8926                	mv	s2,s1
    8000261c:	ec04a783          	lw	a5,-320(s1)
    80002620:	dbed                	beqz	a5,80002612 <procdump+0x80>
      state = "???";
    80002622:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	fcfc6ae3          	bltu	s8,a5,800025f8 <procdump+0x66>
    80002628:	02079713          	slli	a4,a5,0x20
    8000262c:	01d75793          	srli	a5,a4,0x1d
    80002630:	97e6                	add	a5,a5,s9
    80002632:	6390                	ld	a2,0(a5)
    80002634:	f271                	bnez	a2,800025f8 <procdump+0x66>
      state = "???";
    80002636:	8652                	mv	a2,s4
    80002638:	b7c1                	j	800025f8 <procdump+0x66>
      printf(" (quarantined)");
    8000263a:	856a                	mv	a0,s10
    8000263c:	ebffd0ef          	jal	800004fa <printf>
    80002640:	b7f1                	j	8000260c <procdump+0x7a>
  }
}
    80002642:	60e6                	ld	ra,88(sp)
    80002644:	6446                	ld	s0,80(sp)
    80002646:	64a6                	ld	s1,72(sp)
    80002648:	6906                	ld	s2,64(sp)
    8000264a:	79e2                	ld	s3,56(sp)
    8000264c:	7a42                	ld	s4,48(sp)
    8000264e:	7aa2                	ld	s5,40(sp)
    80002650:	7b02                	ld	s6,32(sp)
    80002652:	6be2                	ld	s7,24(sp)
    80002654:	6c42                	ld	s8,16(sp)
    80002656:	6ca2                	ld	s9,8(sp)
    80002658:	6d02                	ld	s10,0(sp)
    8000265a:	6125                	addi	sp,sp,96
    8000265c:	8082                	ret

000000008000265e <promote_all>:


// Promote all processes to highest priority level (0)
void promote_all(void){
    8000265e:	1101                	addi	sp,sp,-32
    80002660:	ec06                	sd	ra,24(sp)
    80002662:	e822                	sd	s0,16(sp)
    80002664:	e426                	sd	s1,8(sp)
    80002666:	e04a                	sd	s2,0(sp)
    80002668:	1000                	addi	s0,sp,32
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    8000266a:	0000d497          	auipc	s1,0xd
    8000266e:	74e48493          	addi	s1,s1,1870 # 8000fdb8 <proc>
    80002672:	00015917          	auipc	s2,0x15
    80002676:	94690913          	addi	s2,s2,-1722 # 80016fb8 <tickslock>
    8000267a:	a801                	j	8000268a <promote_all+0x2c>
    acquire(&p->lock);
    if(p->state != UNUSED){
        p->priority = 0;
        p->ticks_used = 0;
    }
    release(&p->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	de8fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002682:	1c848493          	addi	s1,s1,456
    80002686:	01248c63          	beq	s1,s2,8000269e <promote_all+0x40>
    acquire(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	d42fe0ef          	jal	80000bce <acquire>
    if(p->state != UNUSED){
    80002690:	4c9c                	lw	a5,24(s1)
    80002692:	d7ed                	beqz	a5,8000267c <promote_all+0x1e>
        p->priority = 0;
    80002694:	1604a423          	sw	zero,360(s1)
        p->ticks_used = 0;
    80002698:	1604a623          	sw	zero,364(s1)
    8000269c:	b7c5                	j	8000267c <promote_all+0x1e>
  }
}
    8000269e:	60e2                	ld	ra,24(sp)
    800026a0:	6442                	ld	s0,16(sp)
    800026a2:	64a2                	ld	s1,8(sp)
    800026a4:	6902                	ld	s2,0(sp)
    800026a6:	6105                	addi	sp,sp,32
    800026a8:	8082                	ret

00000000800026aa <has_higher_priority>:

// Check if there is any runnable process with higher priority
int has_higher_priority(int priority) {
    800026aa:	1141                	addi	sp,sp,-16
    800026ac:	e422                	sd	s0,8(sp)
    800026ae:	0800                	addi	s0,sp,16
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800026b0:	0000d797          	auipc	a5,0xd
    800026b4:	70878793          	addi	a5,a5,1800 # 8000fdb8 <proc>
    if(p->state == RUNNABLE && p->priority < priority){
    800026b8:	468d                	li	a3,3
  for(p = proc; p < &proc[NPROC]; p++){
    800026ba:	00015617          	auipc	a2,0x15
    800026be:	8fe60613          	addi	a2,a2,-1794 # 80016fb8 <tickslock>
    800026c2:	a029                	j	800026cc <has_higher_priority+0x22>
    800026c4:	1c878793          	addi	a5,a5,456
    800026c8:	00c78d63          	beq	a5,a2,800026e2 <has_higher_priority+0x38>
    if(p->state == RUNNABLE && p->priority < priority){
    800026cc:	4f98                	lw	a4,24(a5)
    800026ce:	fed71be3          	bne	a4,a3,800026c4 <has_higher_priority+0x1a>
    800026d2:	1687a703          	lw	a4,360(a5)
    800026d6:	fea757e3          	bge	a4,a0,800026c4 <has_higher_priority+0x1a>
      return 1;
    800026da:	4505                	li	a0,1
    }
  }
  return 0;
    800026dc:	6422                	ld	s0,8(sp)
    800026de:	0141                	addi	sp,sp,16
    800026e0:	8082                	ret
  return 0;
    800026e2:	4501                	li	a0,0
    800026e4:	bfe5                	j	800026dc <has_higher_priority+0x32>

00000000800026e6 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800026e6:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800026ea:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800026ee:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800026f0:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800026f2:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800026f6:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800026fa:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800026fe:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002702:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002706:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    8000270a:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    8000270e:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002712:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002716:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    8000271a:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000271e:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002722:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002724:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002726:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    8000272a:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000272e:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002732:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002736:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    8000273a:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    8000273e:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002742:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002746:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    8000274a:	0685bd83          	ld	s11,104(a1)
        
        ret
    8000274e:	8082                	ret

0000000080002750 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002750:	1141                	addi	sp,sp,-16
    80002752:	e406                	sd	ra,8(sp)
    80002754:	e022                	sd	s0,0(sp)
    80002756:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002758:	00005597          	auipc	a1,0x5
    8000275c:	b0058593          	addi	a1,a1,-1280 # 80007258 <etext+0x258>
    80002760:	00015517          	auipc	a0,0x15
    80002764:	85850513          	addi	a0,a0,-1960 # 80016fb8 <tickslock>
    80002768:	be6fe0ef          	jal	80000b4e <initlock>
}
    8000276c:	60a2                	ld	ra,8(sp)
    8000276e:	6402                	ld	s0,0(sp)
    80002770:	0141                	addi	sp,sp,16
    80002772:	8082                	ret

0000000080002774 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002774:	1141                	addi	sp,sp,-16
    80002776:	e422                	sd	s0,8(sp)
    80002778:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277a:	00003797          	auipc	a5,0x3
    8000277e:	20678793          	addi	a5,a5,518 # 80005980 <kernelvec>
    80002782:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002786:	6422                	ld	s0,8(sp)
    80002788:	0141                	addi	sp,sp,16
    8000278a:	8082                	ret

000000008000278c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000278c:	1141                	addi	sp,sp,-16
    8000278e:	e406                	sd	ra,8(sp)
    80002790:	e022                	sd	s0,0(sp)
    80002792:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002794:	93aff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002798:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000279c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027a2:	04000737          	lui	a4,0x4000
    800027a6:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800027a8:	0732                	slli	a4,a4,0xc
    800027aa:	00004797          	auipc	a5,0x4
    800027ae:	85678793          	addi	a5,a5,-1962 # 80006000 <_trampoline>
    800027b2:	00004697          	auipc	a3,0x4
    800027b6:	84e68693          	addi	a3,a3,-1970 # 80006000 <_trampoline>
    800027ba:	8f95                	sub	a5,a5,a3
    800027bc:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027be:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c4:	18002773          	csrr	a4,satp
    800027c8:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027ca:	6d38                	ld	a4,88(a0)
    800027cc:	613c                	ld	a5,64(a0)
    800027ce:	6685                	lui	a3,0x1
    800027d0:	97b6                	add	a5,a5,a3
    800027d2:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d4:	6d3c                	ld	a5,88(a0)
    800027d6:	00000717          	auipc	a4,0x0
    800027da:	13c70713          	addi	a4,a4,316 # 80002912 <usertrap>
    800027de:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027e0:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e2:	8712                	mv	a4,tp
    800027e4:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ea:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ee:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f2:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027f8:	6f9c                	ld	a5,24(a5)
    800027fa:	14179073          	csrw	sepc,a5
}
    800027fe:	60a2                	ld	ra,8(sp)
    80002800:	6402                	ld	s0,0(sp)
    80002802:	0141                	addi	sp,sp,16
    80002804:	8082                	ret

0000000080002806 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002806:	1101                	addi	sp,sp,-32
    80002808:	ec06                	sd	ra,24(sp)
    8000280a:	e822                	sd	s0,16(sp)
    8000280c:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000280e:	894ff0ef          	jal	800018a2 <cpuid>
    80002812:	c131                	beqz	a0,80002856 <clockintr+0x50>
    wakeup(&ticks);
    release(&tickslock);
  }

  // --- EDR Tier-1 Rate-based Detector ---
  struct proc *p = myproc();
    80002814:	8baff0ef          	jal	800018ce <myproc>
  if(p && p->fork_times[p->fork_times_idx] != 0){
    80002818:	c115                	beqz	a0,8000283c <clockintr+0x36>
    8000281a:	1a856783          	lwu	a5,424(a0)
    8000281e:	02e78793          	addi	a5,a5,46
    80002822:	078e                	slli	a5,a5,0x3
    80002824:	97aa                	add	a5,a5,a0
    80002826:	679c                	ld	a5,8(a5)
    80002828:	cb91                	beqz	a5,8000283c <clockintr+0x36>
    uint64 oldest = p->fork_times[p->fork_times_idx];
    if(ticks - oldest <= EDR_FORK_RATE_WINDOW_TICKS){
    8000282a:	00005717          	auipc	a4,0x5
    8000282e:	05e76703          	lwu	a4,94(a4) # 80007888 <ticks>
    80002832:	40f707b3          	sub	a5,a4,a5
    80002836:	4729                	li	a4,10
    80002838:	04f77563          	bgeu	a4,a5,80002882 <clockintr+0x7c>
  asm volatile("csrr %0, time" : "=r" (x) );
    8000283c:	c01027f3          	rdtime	a5
  // --------------------------------------

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002840:	000f4737          	lui	a4,0xf4
    80002844:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002848:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    8000284a:	14d79073          	csrw	stimecmp,a5
}
    8000284e:	60e2                	ld	ra,24(sp)
    80002850:	6442                	ld	s0,16(sp)
    80002852:	6105                	addi	sp,sp,32
    80002854:	8082                	ret
    80002856:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002858:	00014497          	auipc	s1,0x14
    8000285c:	76048493          	addi	s1,s1,1888 # 80016fb8 <tickslock>
    80002860:	8526                	mv	a0,s1
    80002862:	b6cfe0ef          	jal	80000bce <acquire>
    ticks++;
    80002866:	00005517          	auipc	a0,0x5
    8000286a:	02250513          	addi	a0,a0,34 # 80007888 <ticks>
    8000286e:	411c                	lw	a5,0(a0)
    80002870:	2785                	addiw	a5,a5,1
    80002872:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002874:	97bff0ef          	jal	800021ee <wakeup>
    release(&tickslock);
    80002878:	8526                	mv	a0,s1
    8000287a:	becfe0ef          	jal	80000c66 <release>
    8000287e:	64a2                	ld	s1,8(sp)
    80002880:	bf51                	j	80002814 <clockintr+0xe>
      p->is_sandboxed = 1;
    80002882:	4785                	li	a5,1
    80002884:	1af50823          	sb	a5,432(a0)
      p->sandbox_reason = 1; // EDR_REASON_RATE
    80002888:	1af508a3          	sb	a5,433(a0)
      p->need_propagation = 1;
    8000288c:	1cf50023          	sb	a5,448(a0)
      __sync_synchronize();
    80002890:	0ff0000f          	fence
      edr_work_pending = 1;
    80002894:	00005717          	auipc	a4,0x5
    80002898:	fef72223          	sw	a5,-28(a4) # 80007878 <edr_work_pending>
    8000289c:	b745                	j	8000283c <clockintr+0x36>

000000008000289e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000289e:	1101                	addi	sp,sp,-32
    800028a0:	ec06                	sd	ra,24(sp)
    800028a2:	e822                	sd	s0,16(sp)
    800028a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800028aa:	57fd                	li	a5,-1
    800028ac:	17fe                	slli	a5,a5,0x3f
    800028ae:	07a5                	addi	a5,a5,9
    800028b0:	00f70c63          	beq	a4,a5,800028c8 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800028b4:	57fd                	li	a5,-1
    800028b6:	17fe                	slli	a5,a5,0x3f
    800028b8:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800028ba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800028bc:	04f70763          	beq	a4,a5,8000290a <devintr+0x6c>
  }
}
    800028c0:	60e2                	ld	ra,24(sp)
    800028c2:	6442                	ld	s0,16(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret
    800028c8:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800028ca:	162030ef          	jal	80005a2c <plic_claim>
    800028ce:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028d0:	47a9                	li	a5,10
    800028d2:	00f50963          	beq	a0,a5,800028e4 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800028d6:	4785                	li	a5,1
    800028d8:	00f50963          	beq	a0,a5,800028ea <devintr+0x4c>
    return 1;
    800028dc:	4505                	li	a0,1
    } else if(irq){
    800028de:	e889                	bnez	s1,800028f0 <devintr+0x52>
    800028e0:	64a2                	ld	s1,8(sp)
    800028e2:	bff9                	j	800028c0 <devintr+0x22>
      uartintr();
    800028e4:	8ccfe0ef          	jal	800009b0 <uartintr>
    if(irq)
    800028e8:	a819                	j	800028fe <devintr+0x60>
      virtio_disk_intr();
    800028ea:	608030ef          	jal	80005ef2 <virtio_disk_intr>
    if(irq)
    800028ee:	a801                	j	800028fe <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f0:	85a6                	mv	a1,s1
    800028f2:	00005517          	auipc	a0,0x5
    800028f6:	96e50513          	addi	a0,a0,-1682 # 80007260 <etext+0x260>
    800028fa:	c01fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    800028fe:	8526                	mv	a0,s1
    80002900:	14c030ef          	jal	80005a4c <plic_complete>
    return 1;
    80002904:	4505                	li	a0,1
    80002906:	64a2                	ld	s1,8(sp)
    80002908:	bf65                	j	800028c0 <devintr+0x22>
    clockintr();
    8000290a:	efdff0ef          	jal	80002806 <clockintr>
    return 2;
    8000290e:	4509                	li	a0,2
    80002910:	bf45                	j	800028c0 <devintr+0x22>

0000000080002912 <usertrap>:
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	e04a                	sd	s2,0(sp)
    8000291c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002922:	1007f793          	andi	a5,a5,256
    80002926:	eba5                	bnez	a5,80002996 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002928:	00003797          	auipc	a5,0x3
    8000292c:	05878793          	addi	a5,a5,88 # 80005980 <kernelvec>
    80002930:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002934:	f9bfe0ef          	jal	800018ce <myproc>
    80002938:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000293a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293c:	14102773          	csrr	a4,sepc
    80002940:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002946:	47a1                	li	a5,8
    80002948:	04f70d63          	beq	a4,a5,800029a2 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000294c:	f53ff0ef          	jal	8000289e <devintr>
    80002950:	892a                	mv	s2,a0
    80002952:	e945                	bnez	a0,80002a02 <usertrap+0xf0>
    80002954:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002958:	47bd                	li	a5,15
    8000295a:	08f70863          	beq	a4,a5,800029ea <usertrap+0xd8>
    8000295e:	14202773          	csrr	a4,scause
    80002962:	47b5                	li	a5,13
    80002964:	08f70363          	beq	a4,a5,800029ea <usertrap+0xd8>
    80002968:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000296c:	5890                	lw	a2,48(s1)
    8000296e:	00005517          	auipc	a0,0x5
    80002972:	93250513          	addi	a0,a0,-1742 # 800072a0 <etext+0x2a0>
    80002976:	b85fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297e:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002982:	00005517          	auipc	a0,0x5
    80002986:	94e50513          	addi	a0,a0,-1714 # 800072d0 <etext+0x2d0>
    8000298a:	b71fd0ef          	jal	800004fa <printf>
    setkilled(p);
    8000298e:	8526                	mv	a0,s1
    80002990:	a27ff0ef          	jal	800023b6 <setkilled>
    80002994:	a035                	j	800029c0 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002996:	00005517          	auipc	a0,0x5
    8000299a:	8ea50513          	addi	a0,a0,-1814 # 80007280 <etext+0x280>
    8000299e:	e43fd0ef          	jal	800007e0 <panic>
    if(killed(p))
    800029a2:	a39ff0ef          	jal	800023da <killed>
    800029a6:	ed15                	bnez	a0,800029e2 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800029a8:	6cb8                	ld	a4,88(s1)
    800029aa:	6f1c                	ld	a5,24(a4)
    800029ac:	0791                	addi	a5,a5,4
    800029ae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10079073          	csrw	sstatus,a5
    syscall();
    800029bc:	3aa000ef          	jal	80002d66 <syscall>
  if(killed(p))
    800029c0:	8526                	mv	a0,s1
    800029c2:	a19ff0ef          	jal	800023da <killed>
    800029c6:	e139                	bnez	a0,80002a0c <usertrap+0xfa>
  prepare_return();
    800029c8:	dc5ff0ef          	jal	8000278c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800029cc:	68a8                	ld	a0,80(s1)
    800029ce:	8131                	srli	a0,a0,0xc
    800029d0:	57fd                	li	a5,-1
    800029d2:	17fe                	slli	a5,a5,0x3f
    800029d4:	8d5d                	or	a0,a0,a5
}
    800029d6:	60e2                	ld	ra,24(sp)
    800029d8:	6442                	ld	s0,16(sp)
    800029da:	64a2                	ld	s1,8(sp)
    800029dc:	6902                	ld	s2,0(sp)
    800029de:	6105                	addi	sp,sp,32
    800029e0:	8082                	ret
      kexit(-1);
    800029e2:	557d                	li	a0,-1
    800029e4:	8cbff0ef          	jal	800022ae <kexit>
    800029e8:	b7c1                	j	800029a8 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ea:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ee:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800029f2:	164d                	addi	a2,a2,-13
    800029f4:	00163613          	seqz	a2,a2
    800029f8:	68a8                	ld	a0,80(s1)
    800029fa:	b67fe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800029fe:	f169                	bnez	a0,800029c0 <usertrap+0xae>
    80002a00:	b7a5                	j	80002968 <usertrap+0x56>
  if(killed(p))
    80002a02:	8526                	mv	a0,s1
    80002a04:	9d7ff0ef          	jal	800023da <killed>
    80002a08:	c511                	beqz	a0,80002a14 <usertrap+0x102>
    80002a0a:	a011                	j	80002a0e <usertrap+0xfc>
    80002a0c:	4901                	li	s2,0
    kexit(-1);
    80002a0e:	557d                	li	a0,-1
    80002a10:	89fff0ef          	jal	800022ae <kexit>
  if(which_dev == 2)
    80002a14:	4789                	li	a5,2
    80002a16:	faf919e3          	bne	s2,a5,800029c8 <usertrap+0xb6>
    struct proc *p = myproc();
    80002a1a:	eb5fe0ef          	jal	800018ce <myproc>
    if(p){
    80002a1e:	c52d                	beqz	a0,80002a88 <usertrap+0x176>
      p->ticks_used++;
    80002a20:	16c52783          	lw	a5,364(a0)
    80002a24:	2785                	addiw	a5,a5,1
    80002a26:	0007871b          	sext.w	a4,a5
    80002a2a:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    80002a2e:	17452783          	lw	a5,372(a0)
    80002a32:	2785                	addiw	a5,a5,1
    80002a34:	16f52a23          	sw	a5,372(a0)
      p->cumulative_run_time++;
    80002a38:	1ac52783          	lw	a5,428(a0)
    80002a3c:	2785                	addiw	a5,a5,1
    80002a3e:	1af52623          	sw	a5,428(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    80002a42:	16852783          	lw	a5,360(a0)
    80002a46:	cfa1                	beqz	a5,80002a9e <usertrap+0x18c>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002a48:	4685                	li	a3,1
    80002a4a:	06d78d63          	beq	a5,a3,80002ac4 <usertrap+0x1b2>
      if(p->ticks_used >= quantum){
    80002a4e:	469d                	li	a3,7
    80002a50:	04e6da63          	bge	a3,a4,80002aa4 <usertrap+0x192>
        if(p->priority < 2)
    80002a54:	4705                	li	a4,1
    80002a56:	02f75563          	bge	a4,a5,80002a80 <usertrap+0x16e>
        p->ticks_used = 0;
    80002a5a:	16052623          	sw	zero,364(a0)
        p->cumulative_run_time = 0;
    80002a5e:	1a052623          	sw	zero,428(a0)
    if(ticks % AGING_INTERVAL == 0){
    80002a62:	00005797          	auipc	a5,0x5
    80002a66:	e267a783          	lw	a5,-474(a5) # 80007888 <ticks>
    80002a6a:	06400713          	li	a4,100
    80002a6e:	02e7f7bb          	remuw	a5,a5,a4
    80002a72:	2781                	sext.w	a5,a5
    80002a74:	e399                	bnez	a5,80002a7a <usertrap+0x168>
      promote_all();
    80002a76:	be9ff0ef          	jal	8000265e <promote_all>
      yield();
    80002a7a:	ef8ff0ef          	jal	80002172 <yield>
    80002a7e:	b7a9                	j	800029c8 <usertrap+0xb6>
          p->priority++;
    80002a80:	2785                	addiw	a5,a5,1
    80002a82:	16f52423          	sw	a5,360(a0)
    80002a86:	bfd1                	j	80002a5a <usertrap+0x148>
    if(ticks % AGING_INTERVAL == 0){
    80002a88:	00005797          	auipc	a5,0x5
    80002a8c:	e007a783          	lw	a5,-512(a5) # 80007888 <ticks>
    80002a90:	06400713          	li	a4,100
    80002a94:	02e7f7bb          	remuw	a5,a5,a4
    80002a98:	2781                	sext.w	a5,a5
    80002a9a:	f79d                	bnez	a5,800029c8 <usertrap+0xb6>
    80002a9c:	bfe9                	j	80002a76 <usertrap+0x164>
      if(p->priority == 0) quantum = QUANTUM_0;
    80002a9e:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    80002aa0:	fed750e3          	bge	a4,a3,80002a80 <usertrap+0x16e>
      } else if(has_higher_priority(p->priority)){
    80002aa4:	853e                	mv	a0,a5
    80002aa6:	c05ff0ef          	jal	800026aa <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002aaa:	00005797          	auipc	a5,0x5
    80002aae:	dde7a783          	lw	a5,-546(a5) # 80007888 <ticks>
    80002ab2:	06400713          	li	a4,100
    80002ab6:	02e7f7bb          	remuw	a5,a5,a4
    80002aba:	2781                	sext.w	a5,a5
    80002abc:	dfcd                	beqz	a5,80002a76 <usertrap+0x164>
    if(need_yield){
    80002abe:	f00505e3          	beqz	a0,800029c8 <usertrap+0xb6>
    80002ac2:	bf65                	j	80002a7a <usertrap+0x168>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002ac4:	4691                	li	a3,4
    80002ac6:	bfe9                	j	80002aa0 <usertrap+0x18e>

0000000080002ac8 <kerneltrap>:
{
    80002ac8:	7179                	addi	sp,sp,-48
    80002aca:	f406                	sd	ra,40(sp)
    80002acc:	f022                	sd	s0,32(sp)
    80002ace:	ec26                	sd	s1,24(sp)
    80002ad0:	e84a                	sd	s2,16(sp)
    80002ad2:	e44e                	sd	s3,8(sp)
    80002ad4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ade:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ae2:	1004f793          	andi	a5,s1,256
    80002ae6:	c795                	beqz	a5,80002b12 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aec:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aee:	eb85                	bnez	a5,80002b1e <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002af0:	dafff0ef          	jal	8000289e <devintr>
    80002af4:	c91d                	beqz	a0,80002b2a <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    80002af6:	4789                	li	a5,2
    80002af8:	04f50a63          	beq	a0,a5,80002b4c <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002afc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b00:	10049073          	csrw	sstatus,s1
}
    80002b04:	70a2                	ld	ra,40(sp)
    80002b06:	7402                	ld	s0,32(sp)
    80002b08:	64e2                	ld	s1,24(sp)
    80002b0a:	6942                	ld	s2,16(sp)
    80002b0c:	69a2                	ld	s3,8(sp)
    80002b0e:	6145                	addi	sp,sp,48
    80002b10:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b12:	00004517          	auipc	a0,0x4
    80002b16:	7e650513          	addi	a0,a0,2022 # 800072f8 <etext+0x2f8>
    80002b1a:	cc7fd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b1e:	00005517          	auipc	a0,0x5
    80002b22:	80250513          	addi	a0,a0,-2046 # 80007320 <etext+0x320>
    80002b26:	cbbfd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2a:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b2e:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002b32:	85ce                	mv	a1,s3
    80002b34:	00005517          	auipc	a0,0x5
    80002b38:	80c50513          	addi	a0,a0,-2036 # 80007340 <etext+0x340>
    80002b3c:	9bffd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    80002b40:	00005517          	auipc	a0,0x5
    80002b44:	82850513          	addi	a0,a0,-2008 # 80007368 <etext+0x368>
    80002b48:	c99fd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0){
    80002b4c:	d83fe0ef          	jal	800018ce <myproc>
    80002b50:	d555                	beqz	a0,80002afc <kerneltrap+0x34>
    struct proc *p = myproc();
    80002b52:	d7dfe0ef          	jal	800018ce <myproc>
    if(p){
    80002b56:	c52d                	beqz	a0,80002bc0 <kerneltrap+0xf8>
      p->ticks_used++;
    80002b58:	16c52783          	lw	a5,364(a0)
    80002b5c:	2785                	addiw	a5,a5,1
    80002b5e:	0007871b          	sext.w	a4,a5
    80002b62:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    80002b66:	17452783          	lw	a5,372(a0)
    80002b6a:	2785                	addiw	a5,a5,1
    80002b6c:	16f52a23          	sw	a5,372(a0)
      p->cumulative_run_time++;
    80002b70:	1ac52783          	lw	a5,428(a0)
    80002b74:	2785                	addiw	a5,a5,1
    80002b76:	1af52623          	sw	a5,428(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    80002b7a:	16852783          	lw	a5,360(a0)
    80002b7e:	cfa1                	beqz	a5,80002bd6 <kerneltrap+0x10e>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002b80:	4685                	li	a3,1
    80002b82:	06d78d63          	beq	a5,a3,80002bfc <kerneltrap+0x134>
      if(p->ticks_used >= quantum){
    80002b86:	469d                	li	a3,7
    80002b88:	04e6da63          	bge	a3,a4,80002bdc <kerneltrap+0x114>
        if(p->priority < 2)
    80002b8c:	4705                	li	a4,1
    80002b8e:	02f75563          	bge	a4,a5,80002bb8 <kerneltrap+0xf0>
        p->ticks_used = 0;
    80002b92:	16052623          	sw	zero,364(a0)
        p->cumulative_run_time = 0;
    80002b96:	1a052623          	sw	zero,428(a0)
    if(ticks % AGING_INTERVAL == 0){
    80002b9a:	00005797          	auipc	a5,0x5
    80002b9e:	cee7a783          	lw	a5,-786(a5) # 80007888 <ticks>
    80002ba2:	06400713          	li	a4,100
    80002ba6:	02e7f7bb          	remuw	a5,a5,a4
    80002baa:	2781                	sext.w	a5,a5
    80002bac:	e399                	bnez	a5,80002bb2 <kerneltrap+0xea>
      promote_all();
    80002bae:	ab1ff0ef          	jal	8000265e <promote_all>
      yield();
    80002bb2:	dc0ff0ef          	jal	80002172 <yield>
    80002bb6:	b799                	j	80002afc <kerneltrap+0x34>
          p->priority++;
    80002bb8:	2785                	addiw	a5,a5,1
    80002bba:	16f52423          	sw	a5,360(a0)
    80002bbe:	bfd1                	j	80002b92 <kerneltrap+0xca>
    if(ticks % AGING_INTERVAL == 0){
    80002bc0:	00005797          	auipc	a5,0x5
    80002bc4:	cc87a783          	lw	a5,-824(a5) # 80007888 <ticks>
    80002bc8:	06400713          	li	a4,100
    80002bcc:	02e7f7bb          	remuw	a5,a5,a4
    80002bd0:	2781                	sext.w	a5,a5
    80002bd2:	f78d                	bnez	a5,80002afc <kerneltrap+0x34>
    80002bd4:	bfe9                	j	80002bae <kerneltrap+0xe6>
      if(p->priority == 0) quantum = QUANTUM_0;
    80002bd6:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    80002bd8:	fed750e3          	bge	a4,a3,80002bb8 <kerneltrap+0xf0>
      } else if(has_higher_priority(p->priority)){
    80002bdc:	853e                	mv	a0,a5
    80002bde:	acdff0ef          	jal	800026aa <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002be2:	00005797          	auipc	a5,0x5
    80002be6:	ca67a783          	lw	a5,-858(a5) # 80007888 <ticks>
    80002bea:	06400713          	li	a4,100
    80002bee:	02e7f7bb          	remuw	a5,a5,a4
    80002bf2:	2781                	sext.w	a5,a5
    80002bf4:	dfcd                	beqz	a5,80002bae <kerneltrap+0xe6>
    if(need_yield){
    80002bf6:	f00503e3          	beqz	a0,80002afc <kerneltrap+0x34>
    80002bfa:	bf65                	j	80002bb2 <kerneltrap+0xea>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002bfc:	4691                	li	a3,4
    80002bfe:	bfe9                	j	80002bd8 <kerneltrap+0x110>

0000000080002c00 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c0c:	cc3fe0ef          	jal	800018ce <myproc>
  switch (n) {
    80002c10:	4795                	li	a5,5
    80002c12:	0497e163          	bltu	a5,s1,80002c54 <argraw+0x54>
    80002c16:	048a                	slli	s1,s1,0x2
    80002c18:	00005717          	auipc	a4,0x5
    80002c1c:	b5070713          	addi	a4,a4,-1200 # 80007768 <states.0+0x30>
    80002c20:	94ba                	add	s1,s1,a4
    80002c22:	409c                	lw	a5,0(s1)
    80002c24:	97ba                	add	a5,a5,a4
    80002c26:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c28:	6d3c                	ld	a5,88(a0)
    80002c2a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret
    return p->trapframe->a1;
    80002c36:	6d3c                	ld	a5,88(a0)
    80002c38:	7fa8                	ld	a0,120(a5)
    80002c3a:	bfcd                	j	80002c2c <argraw+0x2c>
    return p->trapframe->a2;
    80002c3c:	6d3c                	ld	a5,88(a0)
    80002c3e:	63c8                	ld	a0,128(a5)
    80002c40:	b7f5                	j	80002c2c <argraw+0x2c>
    return p->trapframe->a3;
    80002c42:	6d3c                	ld	a5,88(a0)
    80002c44:	67c8                	ld	a0,136(a5)
    80002c46:	b7dd                	j	80002c2c <argraw+0x2c>
    return p->trapframe->a4;
    80002c48:	6d3c                	ld	a5,88(a0)
    80002c4a:	6bc8                	ld	a0,144(a5)
    80002c4c:	b7c5                	j	80002c2c <argraw+0x2c>
    return p->trapframe->a5;
    80002c4e:	6d3c                	ld	a5,88(a0)
    80002c50:	6fc8                	ld	a0,152(a5)
    80002c52:	bfe9                	j	80002c2c <argraw+0x2c>
  panic("argraw");
    80002c54:	00004517          	auipc	a0,0x4
    80002c58:	72450513          	addi	a0,a0,1828 # 80007378 <etext+0x378>
    80002c5c:	b85fd0ef          	jal	800007e0 <panic>

0000000080002c60 <fetchaddr>:
{
    80002c60:	1101                	addi	sp,sp,-32
    80002c62:	ec06                	sd	ra,24(sp)
    80002c64:	e822                	sd	s0,16(sp)
    80002c66:	e426                	sd	s1,8(sp)
    80002c68:	e04a                	sd	s2,0(sp)
    80002c6a:	1000                	addi	s0,sp,32
    80002c6c:	84aa                	mv	s1,a0
    80002c6e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c70:	c5ffe0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c74:	653c                	ld	a5,72(a0)
    80002c76:	02f4f663          	bgeu	s1,a5,80002ca2 <fetchaddr+0x42>
    80002c7a:	00848713          	addi	a4,s1,8
    80002c7e:	02e7e463          	bltu	a5,a4,80002ca6 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c82:	46a1                	li	a3,8
    80002c84:	8626                	mv	a2,s1
    80002c86:	85ca                	mv	a1,s2
    80002c88:	6928                	ld	a0,80(a0)
    80002c8a:	a3dfe0ef          	jal	800016c6 <copyin>
    80002c8e:	00a03533          	snez	a0,a0
    80002c92:	40a00533          	neg	a0,a0
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6902                	ld	s2,0(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret
    return -1;
    80002ca2:	557d                	li	a0,-1
    80002ca4:	bfcd                	j	80002c96 <fetchaddr+0x36>
    80002ca6:	557d                	li	a0,-1
    80002ca8:	b7fd                	j	80002c96 <fetchaddr+0x36>

0000000080002caa <fetchstr>:
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	e84a                	sd	s2,16(sp)
    80002cb4:	e44e                	sd	s3,8(sp)
    80002cb6:	1800                	addi	s0,sp,48
    80002cb8:	892a                	mv	s2,a0
    80002cba:	84ae                	mv	s1,a1
    80002cbc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cbe:	c11fe0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cc2:	86ce                	mv	a3,s3
    80002cc4:	864a                	mv	a2,s2
    80002cc6:	85a6                	mv	a1,s1
    80002cc8:	6928                	ld	a0,80(a0)
    80002cca:	fbefe0ef          	jal	80001488 <copyinstr>
    80002cce:	00054c63          	bltz	a0,80002ce6 <fetchstr+0x3c>
  return strlen(buf);
    80002cd2:	8526                	mv	a0,s1
    80002cd4:	93efe0ef          	jal	80000e12 <strlen>
}
    80002cd8:	70a2                	ld	ra,40(sp)
    80002cda:	7402                	ld	s0,32(sp)
    80002cdc:	64e2                	ld	s1,24(sp)
    80002cde:	6942                	ld	s2,16(sp)
    80002ce0:	69a2                	ld	s3,8(sp)
    80002ce2:	6145                	addi	sp,sp,48
    80002ce4:	8082                	ret
    return -1;
    80002ce6:	557d                	li	a0,-1
    80002ce8:	bfc5                	j	80002cd8 <fetchstr+0x2e>

0000000080002cea <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	1000                	addi	s0,sp,32
    80002cf4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf6:	f0bff0ef          	jal	80002c00 <argraw>
    80002cfa:	c088                	sw	a0,0(s1)
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret

0000000080002d06 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	e426                	sd	s1,8(sp)
    80002d0e:	1000                	addi	s0,sp,32
    80002d10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d12:	eefff0ef          	jal	80002c00 <argraw>
    80002d16:	e088                	sd	a0,0(s1)
  struct proc *p = myproc();
    80002d18:	bb7fe0ef          	jal	800018ce <myproc>
  // Kiểm tra xem địa chỉ có hợp lệ trong page table không
  if(walkaddr(p->pagetable, *ip) == 0)
    80002d1c:	608c                	ld	a1,0(s1)
    80002d1e:	6928                	ld	a0,80(a0)
    80002d20:	a90fe0ef          	jal	80000fb0 <walkaddr>
    80002d24:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
    80002d28:	40a00533          	neg	a0,a0
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6105                	addi	sp,sp,32
    80002d34:	8082                	ret

0000000080002d36 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d36:	7179                	addi	sp,sp,-48
    80002d38:	f406                	sd	ra,40(sp)
    80002d3a:	f022                	sd	s0,32(sp)
    80002d3c:	ec26                	sd	s1,24(sp)
    80002d3e:	e84a                	sd	s2,16(sp)
    80002d40:	1800                	addi	s0,sp,48
    80002d42:	84ae                	mv	s1,a1
    80002d44:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d46:	fd840593          	addi	a1,s0,-40
    80002d4a:	fbdff0ef          	jal	80002d06 <argaddr>
  return fetchstr(addr, buf, max);
    80002d4e:	864a                	mv	a2,s2
    80002d50:	85a6                	mv	a1,s1
    80002d52:	fd843503          	ld	a0,-40(s0)
    80002d56:	f55ff0ef          	jal	80002caa <fetchstr>
}
    80002d5a:	70a2                	ld	ra,40(sp)
    80002d5c:	7402                	ld	s0,32(sp)
    80002d5e:	64e2                	ld	s1,24(sp)
    80002d60:	6942                	ld	s2,16(sp)
    80002d62:	6145                	addi	sp,sp,48
    80002d64:	8082                	ret

0000000080002d66 <syscall>:
[SYS_proc_info]   sys_proc_info,
};

void
syscall(void)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	e04a                	sd	s2,0(sp)
    80002d70:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d72:	b5dfe0ef          	jal	800018ce <myproc>
    80002d76:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d78:	05853903          	ld	s2,88(a0)
    80002d7c:	0a893783          	ld	a5,168(s2)
    80002d80:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d84:	37fd                	addiw	a5,a5,-1
    80002d86:	4755                	li	a4,21
    80002d88:	00f76f63          	bltu	a4,a5,80002da6 <syscall+0x40>
    80002d8c:	00369713          	slli	a4,a3,0x3
    80002d90:	00005797          	auipc	a5,0x5
    80002d94:	9f078793          	addi	a5,a5,-1552 # 80007780 <syscalls>
    80002d98:	97ba                	add	a5,a5,a4
    80002d9a:	639c                	ld	a5,0(a5)
    80002d9c:	c789                	beqz	a5,80002da6 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d9e:	9782                	jalr	a5
    80002da0:	06a93823          	sd	a0,112(s2)
    80002da4:	a829                	j	80002dbe <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002da6:	15848613          	addi	a2,s1,344
    80002daa:	588c                	lw	a1,48(s1)
    80002dac:	00004517          	auipc	a0,0x4
    80002db0:	5d450513          	addi	a0,a0,1492 # 80007380 <etext+0x380>
    80002db4:	f46fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002db8:	6cbc                	ld	a5,88(s1)
    80002dba:	577d                	li	a4,-1
    80002dbc:	fbb8                	sd	a4,112(a5)
  }
}
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	64a2                	ld	s1,8(sp)
    80002dc4:	6902                	ld	s2,0(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_exit>:
int argaddr(int, uint64 *);
extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dd2:	fec40593          	addi	a1,s0,-20
    80002dd6:	4501                	li	a0,0
    80002dd8:	f13ff0ef          	jal	80002cea <argint>
  kexit(n);
    80002ddc:	fec42503          	lw	a0,-20(s0)
    80002de0:	cceff0ef          	jal	800022ae <kexit>
  return 0;  // not reached
}
    80002de4:	4501                	li	a0,0
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dee:	1141                	addi	sp,sp,-16
    80002df0:	e406                	sd	ra,8(sp)
    80002df2:	e022                	sd	s0,0(sp)
    80002df4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002df6:	ad9fe0ef          	jal	800018ce <myproc>
}
    80002dfa:	5908                	lw	a0,48(a0)
    80002dfc:	60a2                	ld	ra,8(sp)
    80002dfe:	6402                	ld	s0,0(sp)
    80002e00:	0141                	addi	sp,sp,16
    80002e02:	8082                	ret

0000000080002e04 <sys_fork>:

uint64
sys_fork(void)
{
    80002e04:	7179                	addi	sp,sp,-48
    80002e06:	f406                	sd	ra,40(sp)
    80002e08:	f022                	sd	s0,32(sp)
    80002e0a:	ec26                	sd	s1,24(sp)
    80002e0c:	1800                	addi	s0,sp,48
  int npid = kfork();
    80002e0e:	e9dfe0ef          	jal	80001caa <kfork>
    80002e12:	84aa                	mv	s1,a0
  if(npid > 0){
    80002e14:	00a04863          	bgtz	a0,80002e24 <sys_fork+0x20>
    p->fork_times[p->fork_times_idx] = current_tick;
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    release(&p->lock);
  }
  return npid;
}
    80002e18:	8526                	mv	a0,s1
    80002e1a:	70a2                	ld	ra,40(sp)
    80002e1c:	7402                	ld	s0,32(sp)
    80002e1e:	64e2                	ld	s1,24(sp)
    80002e20:	6145                	addi	sp,sp,48
    80002e22:	8082                	ret
    80002e24:	e84a                	sd	s2,16(sp)
    80002e26:	e44e                	sd	s3,8(sp)
    struct proc *p = myproc();
    80002e28:	aa7fe0ef          	jal	800018ce <myproc>
    80002e2c:	892a                	mv	s2,a0
    acquire(&tickslock);
    80002e2e:	00014517          	auipc	a0,0x14
    80002e32:	18a50513          	addi	a0,a0,394 # 80016fb8 <tickslock>
    80002e36:	d99fd0ef          	jal	80000bce <acquire>
    current_tick = ticks;
    80002e3a:	00005997          	auipc	s3,0x5
    80002e3e:	a4e9a983          	lw	s3,-1458(s3) # 80007888 <ticks>
    release(&tickslock);
    80002e42:	00014517          	auipc	a0,0x14
    80002e46:	17650513          	addi	a0,a0,374 # 80016fb8 <tickslock>
    80002e4a:	e1dfd0ef          	jal	80000c66 <release>
    acquire(&p->lock);
    80002e4e:	854a                	mv	a0,s2
    80002e50:	d7ffd0ef          	jal	80000bce <acquire>
    p->fork_times[p->fork_times_idx] = current_tick;
    80002e54:	1a892783          	lw	a5,424(s2)
    80002e58:	02079693          	slli	a3,a5,0x20
    80002e5c:	01d6d713          	srli	a4,a3,0x1d
    80002e60:	974a                	add	a4,a4,s2
    80002e62:	1982                	slli	s3,s3,0x20
    80002e64:	0209d993          	srli	s3,s3,0x20
    80002e68:	17373c23          	sd	s3,376(a4)
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    80002e6c:	2785                	addiw	a5,a5,1
    80002e6e:	4719                	li	a4,6
    80002e70:	02e7f7bb          	remuw	a5,a5,a4
    80002e74:	1af92423          	sw	a5,424(s2)
    release(&p->lock);
    80002e78:	854a                	mv	a0,s2
    80002e7a:	dedfd0ef          	jal	80000c66 <release>
    80002e7e:	6942                	ld	s2,16(sp)
    80002e80:	69a2                	ld	s3,8(sp)
    80002e82:	bf59                	j	80002e18 <sys_fork+0x14>

0000000080002e84 <sys_wait>:

uint64
sys_wait(void)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e8c:	fe840593          	addi	a1,s0,-24
    80002e90:	4501                	li	a0,0
    80002e92:	e75ff0ef          	jal	80002d06 <argaddr>
  return kwait(p);
    80002e96:	fe843503          	ld	a0,-24(s0)
    80002e9a:	d6aff0ef          	jal	80002404 <kwait>
}
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ea6:	7179                	addi	sp,sp,-48
    80002ea8:	f406                	sd	ra,40(sp)
    80002eaa:	f022                	sd	s0,32(sp)
    80002eac:	ec26                	sd	s1,24(sp)
    80002eae:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002eb0:	fd840593          	addi	a1,s0,-40
    80002eb4:	4501                	li	a0,0
    80002eb6:	e35ff0ef          	jal	80002cea <argint>
  argint(1, &t);
    80002eba:	fdc40593          	addi	a1,s0,-36
    80002ebe:	4505                	li	a0,1
    80002ec0:	e2bff0ef          	jal	80002cea <argint>
  addr = myproc()->sz;
    80002ec4:	a0bfe0ef          	jal	800018ce <myproc>
    80002ec8:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002eca:	fdc42703          	lw	a4,-36(s0)
    80002ece:	4785                	li	a5,1
    80002ed0:	02f70763          	beq	a4,a5,80002efe <sys_sbrk+0x58>
    80002ed4:	fd842783          	lw	a5,-40(s0)
    80002ed8:	0207c363          	bltz	a5,80002efe <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002edc:	97a6                	add	a5,a5,s1
    80002ede:	0297ee63          	bltu	a5,s1,80002f1a <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002ee2:	02000737          	lui	a4,0x2000
    80002ee6:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002ee8:	0736                	slli	a4,a4,0xd
    80002eea:	02f76a63          	bltu	a4,a5,80002f1e <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002eee:	9e1fe0ef          	jal	800018ce <myproc>
    80002ef2:	fd842703          	lw	a4,-40(s0)
    80002ef6:	653c                	ld	a5,72(a0)
    80002ef8:	97ba                	add	a5,a5,a4
    80002efa:	e53c                	sd	a5,72(a0)
    80002efc:	a039                	j	80002f0a <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002efe:	fd842503          	lw	a0,-40(s0)
    80002f02:	d47fe0ef          	jal	80001c48 <growproc>
    80002f06:	00054863          	bltz	a0,80002f16 <sys_sbrk+0x70>
  }
  return addr;
}
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	70a2                	ld	ra,40(sp)
    80002f0e:	7402                	ld	s0,32(sp)
    80002f10:	64e2                	ld	s1,24(sp)
    80002f12:	6145                	addi	sp,sp,48
    80002f14:	8082                	ret
      return -1;
    80002f16:	54fd                	li	s1,-1
    80002f18:	bfcd                	j	80002f0a <sys_sbrk+0x64>
      return -1;
    80002f1a:	54fd                	li	s1,-1
    80002f1c:	b7fd                	j	80002f0a <sys_sbrk+0x64>
      return -1;
    80002f1e:	54fd                	li	s1,-1
    80002f20:	b7ed                	j	80002f0a <sys_sbrk+0x64>

0000000080002f22 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f22:	7139                	addi	sp,sp,-64
    80002f24:	fc06                	sd	ra,56(sp)
    80002f26:	f822                	sd	s0,48(sp)
    80002f28:	f04a                	sd	s2,32(sp)
    80002f2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f2c:	fcc40593          	addi	a1,s0,-52
    80002f30:	4501                	li	a0,0
    80002f32:	db9ff0ef          	jal	80002cea <argint>
  if(n < 0)
    80002f36:	fcc42783          	lw	a5,-52(s0)
    80002f3a:	0607c763          	bltz	a5,80002fa8 <sys_sleep+0x86>
    n = 0;
  acquire(&tickslock);
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	07a50513          	addi	a0,a0,122 # 80016fb8 <tickslock>
    80002f46:	c89fd0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002f4a:	00005917          	auipc	s2,0x5
    80002f4e:	93e92903          	lw	s2,-1730(s2) # 80007888 <ticks>
  while(ticks - ticks0 < n){
    80002f52:	fcc42783          	lw	a5,-52(s0)
    80002f56:	cf8d                	beqz	a5,80002f90 <sys_sleep+0x6e>
    80002f58:	f426                	sd	s1,40(sp)
    80002f5a:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f5c:	00014997          	auipc	s3,0x14
    80002f60:	05c98993          	addi	s3,s3,92 # 80016fb8 <tickslock>
    80002f64:	00005497          	auipc	s1,0x5
    80002f68:	92448493          	addi	s1,s1,-1756 # 80007888 <ticks>
    if(killed(myproc())){
    80002f6c:	963fe0ef          	jal	800018ce <myproc>
    80002f70:	c6aff0ef          	jal	800023da <killed>
    80002f74:	ed0d                	bnez	a0,80002fae <sys_sleep+0x8c>
    sleep(&ticks, &tickslock);
    80002f76:	85ce                	mv	a1,s3
    80002f78:	8526                	mv	a0,s1
    80002f7a:	a24ff0ef          	jal	8000219e <sleep>
  while(ticks - ticks0 < n){
    80002f7e:	409c                	lw	a5,0(s1)
    80002f80:	412787bb          	subw	a5,a5,s2
    80002f84:	fcc42703          	lw	a4,-52(s0)
    80002f88:	fee7e2e3          	bltu	a5,a4,80002f6c <sys_sleep+0x4a>
    80002f8c:	74a2                	ld	s1,40(sp)
    80002f8e:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	02850513          	addi	a0,a0,40 # 80016fb8 <tickslock>
    80002f98:	ccffd0ef          	jal	80000c66 <release>
  return 0;
    80002f9c:	4501                	li	a0,0
}
    80002f9e:	70e2                	ld	ra,56(sp)
    80002fa0:	7442                	ld	s0,48(sp)
    80002fa2:	7902                	ld	s2,32(sp)
    80002fa4:	6121                	addi	sp,sp,64
    80002fa6:	8082                	ret
    n = 0;
    80002fa8:	fc042623          	sw	zero,-52(s0)
    80002fac:	bf49                	j	80002f3e <sys_sleep+0x1c>
      release(&tickslock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	00a50513          	addi	a0,a0,10 # 80016fb8 <tickslock>
    80002fb6:	cb1fd0ef          	jal	80000c66 <release>
      return -1;
    80002fba:	557d                	li	a0,-1
    80002fbc:	74a2                	ld	s1,40(sp)
    80002fbe:	69e2                	ld	s3,24(sp)
    80002fc0:	bff9                	j	80002f9e <sys_sleep+0x7c>

0000000080002fc2 <sys_kill>:

uint64
sys_kill(void)
{
    80002fc2:	1101                	addi	sp,sp,-32
    80002fc4:	ec06                	sd	ra,24(sp)
    80002fc6:	e822                	sd	s0,16(sp)
    80002fc8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002fca:	fec40593          	addi	a1,s0,-20
    80002fce:	4501                	li	a0,0
    80002fd0:	d1bff0ef          	jal	80002cea <argint>
  return kkill(pid);
    80002fd4:	fec42503          	lw	a0,-20(s0)
    80002fd8:	b78ff0ef          	jal	80002350 <kkill>
}
    80002fdc:	60e2                	ld	ra,24(sp)
    80002fde:	6442                	ld	s0,16(sp)
    80002fe0:	6105                	addi	sp,sp,32
    80002fe2:	8082                	ret

0000000080002fe4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fe4:	1101                	addi	sp,sp,-32
    80002fe6:	ec06                	sd	ra,24(sp)
    80002fe8:	e822                	sd	s0,16(sp)
    80002fea:	e426                	sd	s1,8(sp)
    80002fec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	fca50513          	addi	a0,a0,-54 # 80016fb8 <tickslock>
    80002ff6:	bd9fd0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002ffa:	00005497          	auipc	s1,0x5
    80002ffe:	88e4a483          	lw	s1,-1906(s1) # 80007888 <ticks>
  release(&tickslock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	fb650513          	addi	a0,a0,-74 # 80016fb8 <tickslock>
    8000300a:	c5dfd0ef          	jal	80000c66 <release>
  return xticks;
}
    8000300e:	02049513          	slli	a0,s1,0x20
    80003012:	9101                	srli	a0,a0,0x20
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret

000000008000301e <sys_proc_info>:

uint64
sys_proc_info(void)
{
    8000301e:	bc010113          	addi	sp,sp,-1088
    80003022:	42113c23          	sd	ra,1080(sp)
    80003026:	42813823          	sd	s0,1072(sp)
    8000302a:	44010413          	addi	s0,sp,1088
  uint64 addr;
  struct p_info pinfo;
  struct proc *p;

  // Lấy địa chỉ con trỏ từ user space truyền vào
  if(argaddr(0, &addr) < 0)
    8000302e:	fc840593          	addi	a1,s0,-56
    80003032:	4501                	li	a0,0
    80003034:	cd3ff0ef          	jal	80002d06 <argaddr>
    80003038:	08054463          	bltz	a0,800030c0 <sys_proc_info+0xa2>
    8000303c:	42913423          	sd	s1,1064(sp)
    80003040:	43213023          	sd	s2,1056(sp)
    80003044:	41313c23          	sd	s3,1048(sp)
    80003048:	bc840913          	addi	s2,s0,-1080
    return -1;

  // Duyệt qua bảng tiến trình
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    8000304c:	0000d497          	auipc	s1,0xd
    80003050:	d6c48493          	addi	s1,s1,-660 # 8000fdb8 <proc>
    80003054:	00014997          	auipc	s3,0x14
    80003058:	f6498993          	addi	s3,s3,-156 # 80016fb8 <tickslock>
    // Cần giữ lock khi đọc dữ liệu để tránh race condition (tuỳ chọn nhưng nên làm)
    acquire(&p->lock);
    8000305c:	8526                	mv	a0,s1
    8000305e:	b71fd0ef          	jal	80000bce <acquire>
    
    pinfo.pid[i] = p->pid;
    80003062:	589c                	lw	a5,48(s1)
    80003064:	00f92023          	sw	a5,0(s2)
    pinfo.state[i] = p->state;
    80003068:	4c9c                	lw	a5,24(s1)
    8000306a:	30f92023          	sw	a5,768(s2)
    pinfo.priority[i] = p->priority;    
    8000306e:	1684a783          	lw	a5,360(s1)
    80003072:	10f92023          	sw	a5,256(s2)
    pinfo.ticks_used[i] = p->ticks_used;
    80003076:	16c4a783          	lw	a5,364(s1)
    8000307a:	20f92023          	sw	a5,512(s2)
    
    release(&p->lock);
    8000307e:	8526                	mv	a0,s1
    80003080:	be7fd0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003084:	1c848493          	addi	s1,s1,456
    80003088:	0911                	addi	s2,s2,4
    8000308a:	fd3499e3          	bne	s1,s3,8000305c <sys_proc_info+0x3e>
    i++;
  }

  // Copy dữ liệu từ kernel space ra user space
  // Lưu ý: copyout trả về -1 nếu lỗi, 0 nếu thành công
  if(copyout(myproc()->pagetable, addr, (char *)&pinfo, sizeof(pinfo)) < 0)
    8000308e:	841fe0ef          	jal	800018ce <myproc>
    80003092:	40000693          	li	a3,1024
    80003096:	bc840613          	addi	a2,s0,-1080
    8000309a:	fc843583          	ld	a1,-56(s0)
    8000309e:	6928                	ld	a0,80(a0)
    800030a0:	d42fe0ef          	jal	800015e2 <copyout>
    800030a4:	957d                	srai	a0,a0,0x3f
    800030a6:	42813483          	ld	s1,1064(sp)
    800030aa:	42013903          	ld	s2,1056(sp)
    800030ae:	41813983          	ld	s3,1048(sp)
    return -1;

  return 0;
}
    800030b2:	43813083          	ld	ra,1080(sp)
    800030b6:	43013403          	ld	s0,1072(sp)
    800030ba:	44010113          	addi	sp,sp,1088
    800030be:	8082                	ret
    return -1;
    800030c0:	557d                	li	a0,-1
    800030c2:	bfc5                	j	800030b2 <sys_proc_info+0x94>

00000000800030c4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030c4:	7179                	addi	sp,sp,-48
    800030c6:	f406                	sd	ra,40(sp)
    800030c8:	f022                	sd	s0,32(sp)
    800030ca:	ec26                	sd	s1,24(sp)
    800030cc:	e84a                	sd	s2,16(sp)
    800030ce:	e44e                	sd	s3,8(sp)
    800030d0:	e052                	sd	s4,0(sp)
    800030d2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030d4:	00004597          	auipc	a1,0x4
    800030d8:	2cc58593          	addi	a1,a1,716 # 800073a0 <etext+0x3a0>
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	ef450513          	addi	a0,a0,-268 # 80016fd0 <bcache>
    800030e4:	a6bfd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	ee878793          	addi	a5,a5,-280 # 8001efd0 <bcache+0x8000>
    800030f0:	0001c717          	auipc	a4,0x1c
    800030f4:	14870713          	addi	a4,a4,328 # 8001f238 <bcache+0x8268>
    800030f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003100:	00014497          	auipc	s1,0x14
    80003104:	ee848493          	addi	s1,s1,-280 # 80016fe8 <bcache+0x18>
    b->next = bcache.head.next;
    80003108:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000310a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000310c:	00004a17          	auipc	s4,0x4
    80003110:	29ca0a13          	addi	s4,s4,668 # 800073a8 <etext+0x3a8>
    b->next = bcache.head.next;
    80003114:	2b893783          	ld	a5,696(s2)
    80003118:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000311a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000311e:	85d2                	mv	a1,s4
    80003120:	01048513          	addi	a0,s1,16
    80003124:	322010ef          	jal	80004446 <initsleeplock>
    bcache.head.next->prev = b;
    80003128:	2b893783          	ld	a5,696(s2)
    8000312c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000312e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003132:	45848493          	addi	s1,s1,1112
    80003136:	fd349fe3          	bne	s1,s3,80003114 <binit+0x50>
  }
}
    8000313a:	70a2                	ld	ra,40(sp)
    8000313c:	7402                	ld	s0,32(sp)
    8000313e:	64e2                	ld	s1,24(sp)
    80003140:	6942                	ld	s2,16(sp)
    80003142:	69a2                	ld	s3,8(sp)
    80003144:	6a02                	ld	s4,0(sp)
    80003146:	6145                	addi	sp,sp,48
    80003148:	8082                	ret

000000008000314a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	e84a                	sd	s2,16(sp)
    80003154:	e44e                	sd	s3,8(sp)
    80003156:	1800                	addi	s0,sp,48
    80003158:	892a                	mv	s2,a0
    8000315a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	e7450513          	addi	a0,a0,-396 # 80016fd0 <bcache>
    80003164:	a6bfd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003168:	0001c497          	auipc	s1,0x1c
    8000316c:	1204b483          	ld	s1,288(s1) # 8001f288 <bcache+0x82b8>
    80003170:	0001c797          	auipc	a5,0x1c
    80003174:	0c878793          	addi	a5,a5,200 # 8001f238 <bcache+0x8268>
    80003178:	02f48b63          	beq	s1,a5,800031ae <bread+0x64>
    8000317c:	873e                	mv	a4,a5
    8000317e:	a021                	j	80003186 <bread+0x3c>
    80003180:	68a4                	ld	s1,80(s1)
    80003182:	02e48663          	beq	s1,a4,800031ae <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80003186:	449c                	lw	a5,8(s1)
    80003188:	ff279ce3          	bne	a5,s2,80003180 <bread+0x36>
    8000318c:	44dc                	lw	a5,12(s1)
    8000318e:	ff3799e3          	bne	a5,s3,80003180 <bread+0x36>
      b->refcnt++;
    80003192:	40bc                	lw	a5,64(s1)
    80003194:	2785                	addiw	a5,a5,1
    80003196:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	e3850513          	addi	a0,a0,-456 # 80016fd0 <bcache>
    800031a0:	ac7fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    800031a4:	01048513          	addi	a0,s1,16
    800031a8:	2d4010ef          	jal	8000447c <acquiresleep>
      return b;
    800031ac:	a889                	j	800031fe <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ae:	0001c497          	auipc	s1,0x1c
    800031b2:	0d24b483          	ld	s1,210(s1) # 8001f280 <bcache+0x82b0>
    800031b6:	0001c797          	auipc	a5,0x1c
    800031ba:	08278793          	addi	a5,a5,130 # 8001f238 <bcache+0x8268>
    800031be:	00f48863          	beq	s1,a5,800031ce <bread+0x84>
    800031c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031c4:	40bc                	lw	a5,64(s1)
    800031c6:	cb91                	beqz	a5,800031da <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031c8:	64a4                	ld	s1,72(s1)
    800031ca:	fee49de3          	bne	s1,a4,800031c4 <bread+0x7a>
  panic("bget: no buffers");
    800031ce:	00004517          	auipc	a0,0x4
    800031d2:	1e250513          	addi	a0,a0,482 # 800073b0 <etext+0x3b0>
    800031d6:	e0afd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    800031da:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031de:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031e2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031e6:	4785                	li	a5,1
    800031e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	de650513          	addi	a0,a0,-538 # 80016fd0 <bcache>
    800031f2:	a75fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    800031f6:	01048513          	addi	a0,s1,16
    800031fa:	282010ef          	jal	8000447c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031fe:	409c                	lw	a5,0(s1)
    80003200:	cb89                	beqz	a5,80003212 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003202:	8526                	mv	a0,s1
    80003204:	70a2                	ld	ra,40(sp)
    80003206:	7402                	ld	s0,32(sp)
    80003208:	64e2                	ld	s1,24(sp)
    8000320a:	6942                	ld	s2,16(sp)
    8000320c:	69a2                	ld	s3,8(sp)
    8000320e:	6145                	addi	sp,sp,48
    80003210:	8082                	ret
    virtio_disk_rw(b, 0);
    80003212:	4581                	li	a1,0
    80003214:	8526                	mv	a0,s1
    80003216:	2cb020ef          	jal	80005ce0 <virtio_disk_rw>
    b->valid = 1;
    8000321a:	4785                	li	a5,1
    8000321c:	c09c                	sw	a5,0(s1)
  return b;
    8000321e:	b7d5                	j	80003202 <bread+0xb8>

0000000080003220 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	addi	s0,sp,32
    8000322a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000322c:	0541                	addi	a0,a0,16
    8000322e:	2cc010ef          	jal	800044fa <holdingsleep>
    80003232:	c911                	beqz	a0,80003246 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003234:	4585                	li	a1,1
    80003236:	8526                	mv	a0,s1
    80003238:	2a9020ef          	jal	80005ce0 <virtio_disk_rw>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret
    panic("bwrite");
    80003246:	00004517          	auipc	a0,0x4
    8000324a:	18250513          	addi	a0,a0,386 # 800073c8 <etext+0x3c8>
    8000324e:	d92fd0ef          	jal	800007e0 <panic>

0000000080003252 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	e04a                	sd	s2,0(sp)
    8000325c:	1000                	addi	s0,sp,32
    8000325e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003260:	01050913          	addi	s2,a0,16
    80003264:	854a                	mv	a0,s2
    80003266:	294010ef          	jal	800044fa <holdingsleep>
    8000326a:	c135                	beqz	a0,800032ce <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    8000326c:	854a                	mv	a0,s2
    8000326e:	254010ef          	jal	800044c2 <releasesleep>

  acquire(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	d5e50513          	addi	a0,a0,-674 # 80016fd0 <bcache>
    8000327a:	955fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    8000327e:	40bc                	lw	a5,64(s1)
    80003280:	37fd                	addiw	a5,a5,-1
    80003282:	0007871b          	sext.w	a4,a5
    80003286:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003288:	e71d                	bnez	a4,800032b6 <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000328a:	68b8                	ld	a4,80(s1)
    8000328c:	64bc                	ld	a5,72(s1)
    8000328e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003290:	68b8                	ld	a4,80(s1)
    80003292:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003294:	0001c797          	auipc	a5,0x1c
    80003298:	d3c78793          	addi	a5,a5,-708 # 8001efd0 <bcache+0x8000>
    8000329c:	2b87b703          	ld	a4,696(a5)
    800032a0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032a2:	0001c717          	auipc	a4,0x1c
    800032a6:	f9670713          	addi	a4,a4,-106 # 8001f238 <bcache+0x8268>
    800032aa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ac:	2b87b703          	ld	a4,696(a5)
    800032b0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032b2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032b6:	00014517          	auipc	a0,0x14
    800032ba:	d1a50513          	addi	a0,a0,-742 # 80016fd0 <bcache>
    800032be:	9a9fd0ef          	jal	80000c66 <release>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6902                	ld	s2,0(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret
    panic("brelse");
    800032ce:	00004517          	auipc	a0,0x4
    800032d2:	10250513          	addi	a0,a0,258 # 800073d0 <etext+0x3d0>
    800032d6:	d0afd0ef          	jal	800007e0 <panic>

00000000800032da <bpin>:

void
bpin(struct buf *b) {
    800032da:	1101                	addi	sp,sp,-32
    800032dc:	ec06                	sd	ra,24(sp)
    800032de:	e822                	sd	s0,16(sp)
    800032e0:	e426                	sd	s1,8(sp)
    800032e2:	1000                	addi	s0,sp,32
    800032e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	cea50513          	addi	a0,a0,-790 # 80016fd0 <bcache>
    800032ee:	8e1fd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    800032f2:	40bc                	lw	a5,64(s1)
    800032f4:	2785                	addiw	a5,a5,1
    800032f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	cd850513          	addi	a0,a0,-808 # 80016fd0 <bcache>
    80003300:	967fd0ef          	jal	80000c66 <release>
}
    80003304:	60e2                	ld	ra,24(sp)
    80003306:	6442                	ld	s0,16(sp)
    80003308:	64a2                	ld	s1,8(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret

000000008000330e <bunpin>:

void
bunpin(struct buf *b) {
    8000330e:	1101                	addi	sp,sp,-32
    80003310:	ec06                	sd	ra,24(sp)
    80003312:	e822                	sd	s0,16(sp)
    80003314:	e426                	sd	s1,8(sp)
    80003316:	1000                	addi	s0,sp,32
    80003318:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000331a:	00014517          	auipc	a0,0x14
    8000331e:	cb650513          	addi	a0,a0,-842 # 80016fd0 <bcache>
    80003322:	8adfd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80003326:	40bc                	lw	a5,64(s1)
    80003328:	37fd                	addiw	a5,a5,-1
    8000332a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000332c:	00014517          	auipc	a0,0x14
    80003330:	ca450513          	addi	a0,a0,-860 # 80016fd0 <bcache>
    80003334:	933fd0ef          	jal	80000c66 <release>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret

0000000080003342 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	e426                	sd	s1,8(sp)
    8000334a:	e04a                	sd	s2,0(sp)
    8000334c:	1000                	addi	s0,sp,32
    8000334e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003350:	00d5d59b          	srliw	a1,a1,0xd
    80003354:	0001c797          	auipc	a5,0x1c
    80003358:	3587a783          	lw	a5,856(a5) # 8001f6ac <sb+0x1c>
    8000335c:	9dbd                	addw	a1,a1,a5
    8000335e:	dedff0ef          	jal	8000314a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003362:	0074f713          	andi	a4,s1,7
    80003366:	4785                	li	a5,1
    80003368:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000336c:	14ce                	slli	s1,s1,0x33
    8000336e:	90d9                	srli	s1,s1,0x36
    80003370:	00950733          	add	a4,a0,s1
    80003374:	05874703          	lbu	a4,88(a4)
    80003378:	00e7f6b3          	and	a3,a5,a4
    8000337c:	c29d                	beqz	a3,800033a2 <bfree+0x60>
    8000337e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003380:	94aa                	add	s1,s1,a0
    80003382:	fff7c793          	not	a5,a5
    80003386:	8f7d                	and	a4,a4,a5
    80003388:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000338c:	7f9000ef          	jal	80004384 <log_write>
  brelse(bp);
    80003390:	854a                	mv	a0,s2
    80003392:	ec1ff0ef          	jal	80003252 <brelse>
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6902                	ld	s2,0(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret
    panic("freeing free block");
    800033a2:	00004517          	auipc	a0,0x4
    800033a6:	03650513          	addi	a0,a0,54 # 800073d8 <etext+0x3d8>
    800033aa:	c36fd0ef          	jal	800007e0 <panic>

00000000800033ae <balloc>:
{
    800033ae:	711d                	addi	sp,sp,-96
    800033b0:	ec86                	sd	ra,88(sp)
    800033b2:	e8a2                	sd	s0,80(sp)
    800033b4:	e4a6                	sd	s1,72(sp)
    800033b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033b8:	0001c797          	auipc	a5,0x1c
    800033bc:	2dc7a783          	lw	a5,732(a5) # 8001f694 <sb+0x4>
    800033c0:	0e078f63          	beqz	a5,800034be <balloc+0x110>
    800033c4:	e0ca                	sd	s2,64(sp)
    800033c6:	fc4e                	sd	s3,56(sp)
    800033c8:	f852                	sd	s4,48(sp)
    800033ca:	f456                	sd	s5,40(sp)
    800033cc:	f05a                	sd	s6,32(sp)
    800033ce:	ec5e                	sd	s7,24(sp)
    800033d0:	e862                	sd	s8,16(sp)
    800033d2:	e466                	sd	s9,8(sp)
    800033d4:	8baa                	mv	s7,a0
    800033d6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033d8:	0001cb17          	auipc	s6,0x1c
    800033dc:	2b8b0b13          	addi	s6,s6,696 # 8001f690 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033e2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033e6:	6c89                	lui	s9,0x2
    800033e8:	a0b5                	j	80003454 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ea:	97ca                	add	a5,a5,s2
    800033ec:	8e55                	or	a2,a2,a3
    800033ee:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033f2:	854a                	mv	a0,s2
    800033f4:	791000ef          	jal	80004384 <log_write>
        brelse(bp);
    800033f8:	854a                	mv	a0,s2
    800033fa:	e59ff0ef          	jal	80003252 <brelse>
  bp = bread(dev, bno);
    800033fe:	85a6                	mv	a1,s1
    80003400:	855e                	mv	a0,s7
    80003402:	d49ff0ef          	jal	8000314a <bread>
    80003406:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003408:	40000613          	li	a2,1024
    8000340c:	4581                	li	a1,0
    8000340e:	05850513          	addi	a0,a0,88
    80003412:	891fd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    80003416:	854a                	mv	a0,s2
    80003418:	76d000ef          	jal	80004384 <log_write>
  brelse(bp);
    8000341c:	854a                	mv	a0,s2
    8000341e:	e35ff0ef          	jal	80003252 <brelse>
}
    80003422:	6906                	ld	s2,64(sp)
    80003424:	79e2                	ld	s3,56(sp)
    80003426:	7a42                	ld	s4,48(sp)
    80003428:	7aa2                	ld	s5,40(sp)
    8000342a:	7b02                	ld	s6,32(sp)
    8000342c:	6be2                	ld	s7,24(sp)
    8000342e:	6c42                	ld	s8,16(sp)
    80003430:	6ca2                	ld	s9,8(sp)
}
    80003432:	8526                	mv	a0,s1
    80003434:	60e6                	ld	ra,88(sp)
    80003436:	6446                	ld	s0,80(sp)
    80003438:	64a6                	ld	s1,72(sp)
    8000343a:	6125                	addi	sp,sp,96
    8000343c:	8082                	ret
    brelse(bp);
    8000343e:	854a                	mv	a0,s2
    80003440:	e13ff0ef          	jal	80003252 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003444:	015c87bb          	addw	a5,s9,s5
    80003448:	00078a9b          	sext.w	s5,a5
    8000344c:	004b2703          	lw	a4,4(s6)
    80003450:	04eaff63          	bgeu	s5,a4,800034ae <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80003454:	41fad79b          	sraiw	a5,s5,0x1f
    80003458:	0137d79b          	srliw	a5,a5,0x13
    8000345c:	015787bb          	addw	a5,a5,s5
    80003460:	40d7d79b          	sraiw	a5,a5,0xd
    80003464:	01cb2583          	lw	a1,28(s6)
    80003468:	9dbd                	addw	a1,a1,a5
    8000346a:	855e                	mv	a0,s7
    8000346c:	cdfff0ef          	jal	8000314a <bread>
    80003470:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	004b2503          	lw	a0,4(s6)
    80003476:	000a849b          	sext.w	s1,s5
    8000347a:	8762                	mv	a4,s8
    8000347c:	fca4f1e3          	bgeu	s1,a0,8000343e <balloc+0x90>
      m = 1 << (bi % 8);
    80003480:	00777693          	andi	a3,a4,7
    80003484:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003488:	41f7579b          	sraiw	a5,a4,0x1f
    8000348c:	01d7d79b          	srliw	a5,a5,0x1d
    80003490:	9fb9                	addw	a5,a5,a4
    80003492:	4037d79b          	sraiw	a5,a5,0x3
    80003496:	00f90633          	add	a2,s2,a5
    8000349a:	05864603          	lbu	a2,88(a2)
    8000349e:	00c6f5b3          	and	a1,a3,a2
    800034a2:	d5a1                	beqz	a1,800033ea <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a4:	2705                	addiw	a4,a4,1
    800034a6:	2485                	addiw	s1,s1,1
    800034a8:	fd471ae3          	bne	a4,s4,8000347c <balloc+0xce>
    800034ac:	bf49                	j	8000343e <balloc+0x90>
    800034ae:	6906                	ld	s2,64(sp)
    800034b0:	79e2                	ld	s3,56(sp)
    800034b2:	7a42                	ld	s4,48(sp)
    800034b4:	7aa2                	ld	s5,40(sp)
    800034b6:	7b02                	ld	s6,32(sp)
    800034b8:	6be2                	ld	s7,24(sp)
    800034ba:	6c42                	ld	s8,16(sp)
    800034bc:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    800034be:	00004517          	auipc	a0,0x4
    800034c2:	f3250513          	addi	a0,a0,-206 # 800073f0 <etext+0x3f0>
    800034c6:	834fd0ef          	jal	800004fa <printf>
  return 0;
    800034ca:	4481                	li	s1,0
    800034cc:	b79d                	j	80003432 <balloc+0x84>

00000000800034ce <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ce:	7179                	addi	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	e84a                	sd	s2,16(sp)
    800034d8:	e44e                	sd	s3,8(sp)
    800034da:	1800                	addi	s0,sp,48
    800034dc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034de:	47ad                	li	a5,11
    800034e0:	02b7e663          	bltu	a5,a1,8000350c <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    800034e4:	02059793          	slli	a5,a1,0x20
    800034e8:	01e7d593          	srli	a1,a5,0x1e
    800034ec:	00b504b3          	add	s1,a0,a1
    800034f0:	0504a903          	lw	s2,80(s1)
    800034f4:	06091a63          	bnez	s2,80003568 <bmap+0x9a>
      addr = balloc(ip->dev);
    800034f8:	4108                	lw	a0,0(a0)
    800034fa:	eb5ff0ef          	jal	800033ae <balloc>
    800034fe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003502:	06090363          	beqz	s2,80003568 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80003506:	0524a823          	sw	s2,80(s1)
    8000350a:	a8b9                	j	80003568 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000350c:	ff45849b          	addiw	s1,a1,-12
    80003510:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003514:	0ff00793          	li	a5,255
    80003518:	06e7ee63          	bltu	a5,a4,80003594 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000351c:	08052903          	lw	s2,128(a0)
    80003520:	00091d63          	bnez	s2,8000353a <bmap+0x6c>
      addr = balloc(ip->dev);
    80003524:	4108                	lw	a0,0(a0)
    80003526:	e89ff0ef          	jal	800033ae <balloc>
    8000352a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000352e:	02090d63          	beqz	s2,80003568 <bmap+0x9a>
    80003532:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003534:	0929a023          	sw	s2,128(s3)
    80003538:	a011                	j	8000353c <bmap+0x6e>
    8000353a:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    8000353c:	85ca                	mv	a1,s2
    8000353e:	0009a503          	lw	a0,0(s3)
    80003542:	c09ff0ef          	jal	8000314a <bread>
    80003546:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003548:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000354c:	02049713          	slli	a4,s1,0x20
    80003550:	01e75593          	srli	a1,a4,0x1e
    80003554:	00b784b3          	add	s1,a5,a1
    80003558:	0004a903          	lw	s2,0(s1)
    8000355c:	00090e63          	beqz	s2,80003578 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003560:	8552                	mv	a0,s4
    80003562:	cf1ff0ef          	jal	80003252 <brelse>
    return addr;
    80003566:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003568:	854a                	mv	a0,s2
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret
      addr = balloc(ip->dev);
    80003578:	0009a503          	lw	a0,0(s3)
    8000357c:	e33ff0ef          	jal	800033ae <balloc>
    80003580:	0005091b          	sext.w	s2,a0
      if(addr){
    80003584:	fc090ee3          	beqz	s2,80003560 <bmap+0x92>
        a[bn] = addr;
    80003588:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000358c:	8552                	mv	a0,s4
    8000358e:	5f7000ef          	jal	80004384 <log_write>
    80003592:	b7f9                	j	80003560 <bmap+0x92>
    80003594:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003596:	00004517          	auipc	a0,0x4
    8000359a:	e7250513          	addi	a0,a0,-398 # 80007408 <etext+0x408>
    8000359e:	a42fd0ef          	jal	800007e0 <panic>

00000000800035a2 <iget>:
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	e052                	sd	s4,0(sp)
    800035b0:	1800                	addi	s0,sp,48
    800035b2:	89aa                	mv	s3,a0
    800035b4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035b6:	0001c517          	auipc	a0,0x1c
    800035ba:	0fa50513          	addi	a0,a0,250 # 8001f6b0 <itable>
    800035be:	e10fd0ef          	jal	80000bce <acquire>
  empty = 0;
    800035c2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c4:	0001c497          	auipc	s1,0x1c
    800035c8:	10448493          	addi	s1,s1,260 # 8001f6c8 <itable+0x18>
    800035cc:	0001e697          	auipc	a3,0x1e
    800035d0:	b8c68693          	addi	a3,a3,-1140 # 80021158 <log>
    800035d4:	a039                	j	800035e2 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d6:	02090963          	beqz	s2,80003608 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035da:	08848493          	addi	s1,s1,136
    800035de:	02d48863          	beq	s1,a3,8000360e <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035e2:	449c                	lw	a5,8(s1)
    800035e4:	fef059e3          	blez	a5,800035d6 <iget+0x34>
    800035e8:	4098                	lw	a4,0(s1)
    800035ea:	ff3716e3          	bne	a4,s3,800035d6 <iget+0x34>
    800035ee:	40d8                	lw	a4,4(s1)
    800035f0:	ff4713e3          	bne	a4,s4,800035d6 <iget+0x34>
      ip->ref++;
    800035f4:	2785                	addiw	a5,a5,1
    800035f6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035f8:	0001c517          	auipc	a0,0x1c
    800035fc:	0b850513          	addi	a0,a0,184 # 8001f6b0 <itable>
    80003600:	e66fd0ef          	jal	80000c66 <release>
      return ip;
    80003604:	8926                	mv	s2,s1
    80003606:	a02d                	j	80003630 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003608:	fbe9                	bnez	a5,800035da <iget+0x38>
      empty = ip;
    8000360a:	8926                	mv	s2,s1
    8000360c:	b7f9                	j	800035da <iget+0x38>
  if(empty == 0)
    8000360e:	02090a63          	beqz	s2,80003642 <iget+0xa0>
  ip->dev = dev;
    80003612:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003616:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000361a:	4785                	li	a5,1
    8000361c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003620:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003624:	0001c517          	auipc	a0,0x1c
    80003628:	08c50513          	addi	a0,a0,140 # 8001f6b0 <itable>
    8000362c:	e3afd0ef          	jal	80000c66 <release>
}
    80003630:	854a                	mv	a0,s2
    80003632:	70a2                	ld	ra,40(sp)
    80003634:	7402                	ld	s0,32(sp)
    80003636:	64e2                	ld	s1,24(sp)
    80003638:	6942                	ld	s2,16(sp)
    8000363a:	69a2                	ld	s3,8(sp)
    8000363c:	6a02                	ld	s4,0(sp)
    8000363e:	6145                	addi	sp,sp,48
    80003640:	8082                	ret
    panic("iget: no inodes");
    80003642:	00004517          	auipc	a0,0x4
    80003646:	dde50513          	addi	a0,a0,-546 # 80007420 <etext+0x420>
    8000364a:	996fd0ef          	jal	800007e0 <panic>

000000008000364e <iinit>:
{
    8000364e:	7179                	addi	sp,sp,-48
    80003650:	f406                	sd	ra,40(sp)
    80003652:	f022                	sd	s0,32(sp)
    80003654:	ec26                	sd	s1,24(sp)
    80003656:	e84a                	sd	s2,16(sp)
    80003658:	e44e                	sd	s3,8(sp)
    8000365a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000365c:	00004597          	auipc	a1,0x4
    80003660:	dd458593          	addi	a1,a1,-556 # 80007430 <etext+0x430>
    80003664:	0001c517          	auipc	a0,0x1c
    80003668:	04c50513          	addi	a0,a0,76 # 8001f6b0 <itable>
    8000366c:	ce2fd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003670:	0001c497          	auipc	s1,0x1c
    80003674:	06848493          	addi	s1,s1,104 # 8001f6d8 <itable+0x28>
    80003678:	0001e997          	auipc	s3,0x1e
    8000367c:	af098993          	addi	s3,s3,-1296 # 80021168 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003680:	00004917          	auipc	s2,0x4
    80003684:	db890913          	addi	s2,s2,-584 # 80007438 <etext+0x438>
    80003688:	85ca                	mv	a1,s2
    8000368a:	8526                	mv	a0,s1
    8000368c:	5bb000ef          	jal	80004446 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003690:	08848493          	addi	s1,s1,136
    80003694:	ff349ae3          	bne	s1,s3,80003688 <iinit+0x3a>
}
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6145                	addi	sp,sp,48
    800036a4:	8082                	ret

00000000800036a6 <ialloc>:
{
    800036a6:	7139                	addi	sp,sp,-64
    800036a8:	fc06                	sd	ra,56(sp)
    800036aa:	f822                	sd	s0,48(sp)
    800036ac:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ae:	0001c717          	auipc	a4,0x1c
    800036b2:	fee72703          	lw	a4,-18(a4) # 8001f69c <sb+0xc>
    800036b6:	4785                	li	a5,1
    800036b8:	06e7f063          	bgeu	a5,a4,80003718 <ialloc+0x72>
    800036bc:	f426                	sd	s1,40(sp)
    800036be:	f04a                	sd	s2,32(sp)
    800036c0:	ec4e                	sd	s3,24(sp)
    800036c2:	e852                	sd	s4,16(sp)
    800036c4:	e456                	sd	s5,8(sp)
    800036c6:	e05a                	sd	s6,0(sp)
    800036c8:	8aaa                	mv	s5,a0
    800036ca:	8b2e                	mv	s6,a1
    800036cc:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036ce:	0001ca17          	auipc	s4,0x1c
    800036d2:	fc2a0a13          	addi	s4,s4,-62 # 8001f690 <sb>
    800036d6:	00495593          	srli	a1,s2,0x4
    800036da:	018a2783          	lw	a5,24(s4)
    800036de:	9dbd                	addw	a1,a1,a5
    800036e0:	8556                	mv	a0,s5
    800036e2:	a69ff0ef          	jal	8000314a <bread>
    800036e6:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036e8:	05850993          	addi	s3,a0,88
    800036ec:	00f97793          	andi	a5,s2,15
    800036f0:	079a                	slli	a5,a5,0x6
    800036f2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036f4:	00099783          	lh	a5,0(s3)
    800036f8:	cb9d                	beqz	a5,8000372e <ialloc+0x88>
    brelse(bp);
    800036fa:	b59ff0ef          	jal	80003252 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036fe:	0905                	addi	s2,s2,1
    80003700:	00ca2703          	lw	a4,12(s4)
    80003704:	0009079b          	sext.w	a5,s2
    80003708:	fce7e7e3          	bltu	a5,a4,800036d6 <ialloc+0x30>
    8000370c:	74a2                	ld	s1,40(sp)
    8000370e:	7902                	ld	s2,32(sp)
    80003710:	69e2                	ld	s3,24(sp)
    80003712:	6a42                	ld	s4,16(sp)
    80003714:	6aa2                	ld	s5,8(sp)
    80003716:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003718:	00004517          	auipc	a0,0x4
    8000371c:	d2850513          	addi	a0,a0,-728 # 80007440 <etext+0x440>
    80003720:	ddbfc0ef          	jal	800004fa <printf>
  return 0;
    80003724:	4501                	li	a0,0
}
    80003726:	70e2                	ld	ra,56(sp)
    80003728:	7442                	ld	s0,48(sp)
    8000372a:	6121                	addi	sp,sp,64
    8000372c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000372e:	04000613          	li	a2,64
    80003732:	4581                	li	a1,0
    80003734:	854e                	mv	a0,s3
    80003736:	d6cfd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    8000373a:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000373e:	8526                	mv	a0,s1
    80003740:	445000ef          	jal	80004384 <log_write>
      brelse(bp);
    80003744:	8526                	mv	a0,s1
    80003746:	b0dff0ef          	jal	80003252 <brelse>
      return iget(dev, inum);
    8000374a:	0009059b          	sext.w	a1,s2
    8000374e:	8556                	mv	a0,s5
    80003750:	e53ff0ef          	jal	800035a2 <iget>
    80003754:	74a2                	ld	s1,40(sp)
    80003756:	7902                	ld	s2,32(sp)
    80003758:	69e2                	ld	s3,24(sp)
    8000375a:	6a42                	ld	s4,16(sp)
    8000375c:	6aa2                	ld	s5,8(sp)
    8000375e:	6b02                	ld	s6,0(sp)
    80003760:	b7d9                	j	80003726 <ialloc+0x80>

0000000080003762 <iupdate>:
{
    80003762:	1101                	addi	sp,sp,-32
    80003764:	ec06                	sd	ra,24(sp)
    80003766:	e822                	sd	s0,16(sp)
    80003768:	e426                	sd	s1,8(sp)
    8000376a:	e04a                	sd	s2,0(sp)
    8000376c:	1000                	addi	s0,sp,32
    8000376e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003770:	415c                	lw	a5,4(a0)
    80003772:	0047d79b          	srliw	a5,a5,0x4
    80003776:	0001c597          	auipc	a1,0x1c
    8000377a:	f325a583          	lw	a1,-206(a1) # 8001f6a8 <sb+0x18>
    8000377e:	9dbd                	addw	a1,a1,a5
    80003780:	4108                	lw	a0,0(a0)
    80003782:	9c9ff0ef          	jal	8000314a <bread>
    80003786:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003788:	05850793          	addi	a5,a0,88
    8000378c:	40d8                	lw	a4,4(s1)
    8000378e:	8b3d                	andi	a4,a4,15
    80003790:	071a                	slli	a4,a4,0x6
    80003792:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003794:	04449703          	lh	a4,68(s1)
    80003798:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000379c:	04649703          	lh	a4,70(s1)
    800037a0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800037a4:	04849703          	lh	a4,72(s1)
    800037a8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800037ac:	04a49703          	lh	a4,74(s1)
    800037b0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037b4:	44f8                	lw	a4,76(s1)
    800037b6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b8:	03400613          	li	a2,52
    800037bc:	05048593          	addi	a1,s1,80
    800037c0:	00c78513          	addi	a0,a5,12
    800037c4:	d3afd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	3bb000ef          	jal	80004384 <log_write>
  brelse(bp);
    800037ce:	854a                	mv	a0,s2
    800037d0:	a83ff0ef          	jal	80003252 <brelse>
}
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6902                	ld	s2,0(sp)
    800037dc:	6105                	addi	sp,sp,32
    800037de:	8082                	ret

00000000800037e0 <idup>:
{
    800037e0:	1101                	addi	sp,sp,-32
    800037e2:	ec06                	sd	ra,24(sp)
    800037e4:	e822                	sd	s0,16(sp)
    800037e6:	e426                	sd	s1,8(sp)
    800037e8:	1000                	addi	s0,sp,32
    800037ea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037ec:	0001c517          	auipc	a0,0x1c
    800037f0:	ec450513          	addi	a0,a0,-316 # 8001f6b0 <itable>
    800037f4:	bdafd0ef          	jal	80000bce <acquire>
  ip->ref++;
    800037f8:	449c                	lw	a5,8(s1)
    800037fa:	2785                	addiw	a5,a5,1
    800037fc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037fe:	0001c517          	auipc	a0,0x1c
    80003802:	eb250513          	addi	a0,a0,-334 # 8001f6b0 <itable>
    80003806:	c60fd0ef          	jal	80000c66 <release>
}
    8000380a:	8526                	mv	a0,s1
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <ilock>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003820:	cd19                	beqz	a0,8000383e <ilock+0x28>
    80003822:	84aa                	mv	s1,a0
    80003824:	451c                	lw	a5,8(a0)
    80003826:	00f05c63          	blez	a5,8000383e <ilock+0x28>
  acquiresleep(&ip->lock);
    8000382a:	0541                	addi	a0,a0,16
    8000382c:	451000ef          	jal	8000447c <acquiresleep>
  if(ip->valid == 0){
    80003830:	40bc                	lw	a5,64(s1)
    80003832:	cf89                	beqz	a5,8000384c <ilock+0x36>
}
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret
    8000383e:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003840:	00004517          	auipc	a0,0x4
    80003844:	c1850513          	addi	a0,a0,-1000 # 80007458 <etext+0x458>
    80003848:	f99fc0ef          	jal	800007e0 <panic>
    8000384c:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000384e:	40dc                	lw	a5,4(s1)
    80003850:	0047d79b          	srliw	a5,a5,0x4
    80003854:	0001c597          	auipc	a1,0x1c
    80003858:	e545a583          	lw	a1,-428(a1) # 8001f6a8 <sb+0x18>
    8000385c:	9dbd                	addw	a1,a1,a5
    8000385e:	4088                	lw	a0,0(s1)
    80003860:	8ebff0ef          	jal	8000314a <bread>
    80003864:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003866:	05850593          	addi	a1,a0,88
    8000386a:	40dc                	lw	a5,4(s1)
    8000386c:	8bbd                	andi	a5,a5,15
    8000386e:	079a                	slli	a5,a5,0x6
    80003870:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003872:	00059783          	lh	a5,0(a1)
    80003876:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000387a:	00259783          	lh	a5,2(a1)
    8000387e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003882:	00459783          	lh	a5,4(a1)
    80003886:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000388a:	00659783          	lh	a5,6(a1)
    8000388e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003892:	459c                	lw	a5,8(a1)
    80003894:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003896:	03400613          	li	a2,52
    8000389a:	05b1                	addi	a1,a1,12
    8000389c:	05048513          	addi	a0,s1,80
    800038a0:	c5efd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	9adff0ef          	jal	80003252 <brelse>
    ip->valid = 1;
    800038aa:	4785                	li	a5,1
    800038ac:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ae:	04449783          	lh	a5,68(s1)
    800038b2:	c399                	beqz	a5,800038b8 <ilock+0xa2>
    800038b4:	6902                	ld	s2,0(sp)
    800038b6:	bfbd                	j	80003834 <ilock+0x1e>
      panic("ilock: no type");
    800038b8:	00004517          	auipc	a0,0x4
    800038bc:	ba850513          	addi	a0,a0,-1112 # 80007460 <etext+0x460>
    800038c0:	f21fc0ef          	jal	800007e0 <panic>

00000000800038c4 <iunlock>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038d0:	c505                	beqz	a0,800038f8 <iunlock+0x34>
    800038d2:	84aa                	mv	s1,a0
    800038d4:	01050913          	addi	s2,a0,16
    800038d8:	854a                	mv	a0,s2
    800038da:	421000ef          	jal	800044fa <holdingsleep>
    800038de:	cd09                	beqz	a0,800038f8 <iunlock+0x34>
    800038e0:	449c                	lw	a5,8(s1)
    800038e2:	00f05b63          	blez	a5,800038f8 <iunlock+0x34>
  releasesleep(&ip->lock);
    800038e6:	854a                	mv	a0,s2
    800038e8:	3db000ef          	jal	800044c2 <releasesleep>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	64a2                	ld	s1,8(sp)
    800038f2:	6902                	ld	s2,0(sp)
    800038f4:	6105                	addi	sp,sp,32
    800038f6:	8082                	ret
    panic("iunlock");
    800038f8:	00004517          	auipc	a0,0x4
    800038fc:	b7850513          	addi	a0,a0,-1160 # 80007470 <etext+0x470>
    80003900:	ee1fc0ef          	jal	800007e0 <panic>

0000000080003904 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003904:	7179                	addi	sp,sp,-48
    80003906:	f406                	sd	ra,40(sp)
    80003908:	f022                	sd	s0,32(sp)
    8000390a:	ec26                	sd	s1,24(sp)
    8000390c:	e84a                	sd	s2,16(sp)
    8000390e:	e44e                	sd	s3,8(sp)
    80003910:	1800                	addi	s0,sp,48
    80003912:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003914:	05050493          	addi	s1,a0,80
    80003918:	08050913          	addi	s2,a0,128
    8000391c:	a021                	j	80003924 <itrunc+0x20>
    8000391e:	0491                	addi	s1,s1,4
    80003920:	01248b63          	beq	s1,s2,80003936 <itrunc+0x32>
    if(ip->addrs[i]){
    80003924:	408c                	lw	a1,0(s1)
    80003926:	dde5                	beqz	a1,8000391e <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003928:	0009a503          	lw	a0,0(s3)
    8000392c:	a17ff0ef          	jal	80003342 <bfree>
      ip->addrs[i] = 0;
    80003930:	0004a023          	sw	zero,0(s1)
    80003934:	b7ed                	j	8000391e <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003936:	0809a583          	lw	a1,128(s3)
    8000393a:	ed89                	bnez	a1,80003954 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000393c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003940:	854e                	mv	a0,s3
    80003942:	e21ff0ef          	jal	80003762 <iupdate>
}
    80003946:	70a2                	ld	ra,40(sp)
    80003948:	7402                	ld	s0,32(sp)
    8000394a:	64e2                	ld	s1,24(sp)
    8000394c:	6942                	ld	s2,16(sp)
    8000394e:	69a2                	ld	s3,8(sp)
    80003950:	6145                	addi	sp,sp,48
    80003952:	8082                	ret
    80003954:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003956:	0009a503          	lw	a0,0(s3)
    8000395a:	ff0ff0ef          	jal	8000314a <bread>
    8000395e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003960:	05850493          	addi	s1,a0,88
    80003964:	45850913          	addi	s2,a0,1112
    80003968:	a021                	j	80003970 <itrunc+0x6c>
    8000396a:	0491                	addi	s1,s1,4
    8000396c:	01248963          	beq	s1,s2,8000397e <itrunc+0x7a>
      if(a[j])
    80003970:	408c                	lw	a1,0(s1)
    80003972:	dde5                	beqz	a1,8000396a <itrunc+0x66>
        bfree(ip->dev, a[j]);
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	9cbff0ef          	jal	80003342 <bfree>
    8000397c:	b7fd                	j	8000396a <itrunc+0x66>
    brelse(bp);
    8000397e:	8552                	mv	a0,s4
    80003980:	8d3ff0ef          	jal	80003252 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003984:	0809a583          	lw	a1,128(s3)
    80003988:	0009a503          	lw	a0,0(s3)
    8000398c:	9b7ff0ef          	jal	80003342 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003990:	0809a023          	sw	zero,128(s3)
    80003994:	6a02                	ld	s4,0(sp)
    80003996:	b75d                	j	8000393c <itrunc+0x38>

0000000080003998 <iput>:
{
    80003998:	1101                	addi	sp,sp,-32
    8000399a:	ec06                	sd	ra,24(sp)
    8000399c:	e822                	sd	s0,16(sp)
    8000399e:	e426                	sd	s1,8(sp)
    800039a0:	1000                	addi	s0,sp,32
    800039a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039a4:	0001c517          	auipc	a0,0x1c
    800039a8:	d0c50513          	addi	a0,a0,-756 # 8001f6b0 <itable>
    800039ac:	a22fd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b0:	4498                	lw	a4,8(s1)
    800039b2:	4785                	li	a5,1
    800039b4:	02f70063          	beq	a4,a5,800039d4 <iput+0x3c>
  ip->ref--;
    800039b8:	449c                	lw	a5,8(s1)
    800039ba:	37fd                	addiw	a5,a5,-1
    800039bc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039be:	0001c517          	auipc	a0,0x1c
    800039c2:	cf250513          	addi	a0,a0,-782 # 8001f6b0 <itable>
    800039c6:	aa0fd0ef          	jal	80000c66 <release>
}
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6105                	addi	sp,sp,32
    800039d2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d4:	40bc                	lw	a5,64(s1)
    800039d6:	d3ed                	beqz	a5,800039b8 <iput+0x20>
    800039d8:	04a49783          	lh	a5,74(s1)
    800039dc:	fff1                	bnez	a5,800039b8 <iput+0x20>
    800039de:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    800039e0:	01048913          	addi	s2,s1,16
    800039e4:	854a                	mv	a0,s2
    800039e6:	297000ef          	jal	8000447c <acquiresleep>
    release(&itable.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	cc650513          	addi	a0,a0,-826 # 8001f6b0 <itable>
    800039f2:	a74fd0ef          	jal	80000c66 <release>
    itrunc(ip);
    800039f6:	8526                	mv	a0,s1
    800039f8:	f0dff0ef          	jal	80003904 <itrunc>
    ip->type = 0;
    800039fc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a00:	8526                	mv	a0,s1
    80003a02:	d61ff0ef          	jal	80003762 <iupdate>
    ip->valid = 0;
    80003a06:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	2b7000ef          	jal	800044c2 <releasesleep>
    acquire(&itable.lock);
    80003a10:	0001c517          	auipc	a0,0x1c
    80003a14:	ca050513          	addi	a0,a0,-864 # 8001f6b0 <itable>
    80003a18:	9b6fd0ef          	jal	80000bce <acquire>
    80003a1c:	6902                	ld	s2,0(sp)
    80003a1e:	bf69                	j	800039b8 <iput+0x20>

0000000080003a20 <iunlockput>:
{
    80003a20:	1101                	addi	sp,sp,-32
    80003a22:	ec06                	sd	ra,24(sp)
    80003a24:	e822                	sd	s0,16(sp)
    80003a26:	e426                	sd	s1,8(sp)
    80003a28:	1000                	addi	s0,sp,32
    80003a2a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a2c:	e99ff0ef          	jal	800038c4 <iunlock>
  iput(ip);
    80003a30:	8526                	mv	a0,s1
    80003a32:	f67ff0ef          	jal	80003998 <iput>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003a40:	0001c717          	auipc	a4,0x1c
    80003a44:	c5c72703          	lw	a4,-932(a4) # 8001f69c <sb+0xc>
    80003a48:	4785                	li	a5,1
    80003a4a:	0ae7ff63          	bgeu	a5,a4,80003b08 <ireclaim+0xc8>
{
    80003a4e:	7139                	addi	sp,sp,-64
    80003a50:	fc06                	sd	ra,56(sp)
    80003a52:	f822                	sd	s0,48(sp)
    80003a54:	f426                	sd	s1,40(sp)
    80003a56:	f04a                	sd	s2,32(sp)
    80003a58:	ec4e                	sd	s3,24(sp)
    80003a5a:	e852                	sd	s4,16(sp)
    80003a5c:	e456                	sd	s5,8(sp)
    80003a5e:	e05a                	sd	s6,0(sp)
    80003a60:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003a62:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003a64:	00050a1b          	sext.w	s4,a0
    80003a68:	0001ca97          	auipc	s5,0x1c
    80003a6c:	c28a8a93          	addi	s5,s5,-984 # 8001f690 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003a70:	00004b17          	auipc	s6,0x4
    80003a74:	a08b0b13          	addi	s6,s6,-1528 # 80007478 <etext+0x478>
    80003a78:	a099                	j	80003abe <ireclaim+0x7e>
    80003a7a:	85ce                	mv	a1,s3
    80003a7c:	855a                	mv	a0,s6
    80003a7e:	a7dfc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    80003a82:	85ce                	mv	a1,s3
    80003a84:	8552                	mv	a0,s4
    80003a86:	b1dff0ef          	jal	800035a2 <iget>
    80003a8a:	89aa                	mv	s3,a0
    brelse(bp);
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	fc4ff0ef          	jal	80003252 <brelse>
    if (ip) {
    80003a92:	00098f63          	beqz	s3,80003ab0 <ireclaim+0x70>
      begin_op();
    80003a96:	76a000ef          	jal	80004200 <begin_op>
      ilock(ip);
    80003a9a:	854e                	mv	a0,s3
    80003a9c:	d7bff0ef          	jal	80003816 <ilock>
      iunlock(ip);
    80003aa0:	854e                	mv	a0,s3
    80003aa2:	e23ff0ef          	jal	800038c4 <iunlock>
      iput(ip);
    80003aa6:	854e                	mv	a0,s3
    80003aa8:	ef1ff0ef          	jal	80003998 <iput>
      end_op();
    80003aac:	7be000ef          	jal	8000426a <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003ab0:	0485                	addi	s1,s1,1
    80003ab2:	00caa703          	lw	a4,12(s5)
    80003ab6:	0004879b          	sext.w	a5,s1
    80003aba:	02e7fd63          	bgeu	a5,a4,80003af4 <ireclaim+0xb4>
    80003abe:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003ac2:	0044d593          	srli	a1,s1,0x4
    80003ac6:	018aa783          	lw	a5,24(s5)
    80003aca:	9dbd                	addw	a1,a1,a5
    80003acc:	8552                	mv	a0,s4
    80003ace:	e7cff0ef          	jal	8000314a <bread>
    80003ad2:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003ad4:	05850793          	addi	a5,a0,88
    80003ad8:	00f9f713          	andi	a4,s3,15
    80003adc:	071a                	slli	a4,a4,0x6
    80003ade:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003ae0:	00079703          	lh	a4,0(a5)
    80003ae4:	c701                	beqz	a4,80003aec <ireclaim+0xac>
    80003ae6:	00679783          	lh	a5,6(a5)
    80003aea:	dbc1                	beqz	a5,80003a7a <ireclaim+0x3a>
    brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	f64ff0ef          	jal	80003252 <brelse>
    if (ip) {
    80003af2:	bf7d                	j	80003ab0 <ireclaim+0x70>
}
    80003af4:	70e2                	ld	ra,56(sp)
    80003af6:	7442                	ld	s0,48(sp)
    80003af8:	74a2                	ld	s1,40(sp)
    80003afa:	7902                	ld	s2,32(sp)
    80003afc:	69e2                	ld	s3,24(sp)
    80003afe:	6a42                	ld	s4,16(sp)
    80003b00:	6aa2                	ld	s5,8(sp)
    80003b02:	6b02                	ld	s6,0(sp)
    80003b04:	6121                	addi	sp,sp,64
    80003b06:	8082                	ret
    80003b08:	8082                	ret

0000000080003b0a <fsinit>:
fsinit(int dev) {
    80003b0a:	7179                	addi	sp,sp,-48
    80003b0c:	f406                	sd	ra,40(sp)
    80003b0e:	f022                	sd	s0,32(sp)
    80003b10:	ec26                	sd	s1,24(sp)
    80003b12:	e84a                	sd	s2,16(sp)
    80003b14:	e44e                	sd	s3,8(sp)
    80003b16:	1800                	addi	s0,sp,48
    80003b18:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003b1a:	4585                	li	a1,1
    80003b1c:	e2eff0ef          	jal	8000314a <bread>
    80003b20:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b22:	0001c997          	auipc	s3,0x1c
    80003b26:	b6e98993          	addi	s3,s3,-1170 # 8001f690 <sb>
    80003b2a:	02000613          	li	a2,32
    80003b2e:	05850593          	addi	a1,a0,88
    80003b32:	854e                	mv	a0,s3
    80003b34:	9cafd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	f18ff0ef          	jal	80003252 <brelse>
  if(sb.magic != FSMAGIC)
    80003b3e:	0009a703          	lw	a4,0(s3)
    80003b42:	102037b7          	lui	a5,0x10203
    80003b46:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b4a:	02f71363          	bne	a4,a5,80003b70 <fsinit+0x66>
  initlog(dev, &sb);
    80003b4e:	0001c597          	auipc	a1,0x1c
    80003b52:	b4258593          	addi	a1,a1,-1214 # 8001f690 <sb>
    80003b56:	8526                	mv	a0,s1
    80003b58:	62a000ef          	jal	80004182 <initlog>
  ireclaim(dev);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	ee3ff0ef          	jal	80003a40 <ireclaim>
}
    80003b62:	70a2                	ld	ra,40(sp)
    80003b64:	7402                	ld	s0,32(sp)
    80003b66:	64e2                	ld	s1,24(sp)
    80003b68:	6942                	ld	s2,16(sp)
    80003b6a:	69a2                	ld	s3,8(sp)
    80003b6c:	6145                	addi	sp,sp,48
    80003b6e:	8082                	ret
    panic("invalid file system");
    80003b70:	00004517          	auipc	a0,0x4
    80003b74:	92850513          	addi	a0,a0,-1752 # 80007498 <etext+0x498>
    80003b78:	c69fc0ef          	jal	800007e0 <panic>

0000000080003b7c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b7c:	1141                	addi	sp,sp,-16
    80003b7e:	e422                	sd	s0,8(sp)
    80003b80:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b82:	411c                	lw	a5,0(a0)
    80003b84:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b86:	415c                	lw	a5,4(a0)
    80003b88:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b8a:	04451783          	lh	a5,68(a0)
    80003b8e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b92:	04a51783          	lh	a5,74(a0)
    80003b96:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b9a:	04c56783          	lwu	a5,76(a0)
    80003b9e:	e99c                	sd	a5,16(a1)
}
    80003ba0:	6422                	ld	s0,8(sp)
    80003ba2:	0141                	addi	sp,sp,16
    80003ba4:	8082                	ret

0000000080003ba6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba6:	457c                	lw	a5,76(a0)
    80003ba8:	0ed7eb63          	bltu	a5,a3,80003c9e <readi+0xf8>
{
    80003bac:	7159                	addi	sp,sp,-112
    80003bae:	f486                	sd	ra,104(sp)
    80003bb0:	f0a2                	sd	s0,96(sp)
    80003bb2:	eca6                	sd	s1,88(sp)
    80003bb4:	e0d2                	sd	s4,64(sp)
    80003bb6:	fc56                	sd	s5,56(sp)
    80003bb8:	f85a                	sd	s6,48(sp)
    80003bba:	f45e                	sd	s7,40(sp)
    80003bbc:	1880                	addi	s0,sp,112
    80003bbe:	8b2a                	mv	s6,a0
    80003bc0:	8bae                	mv	s7,a1
    80003bc2:	8a32                	mv	s4,a2
    80003bc4:	84b6                	mv	s1,a3
    80003bc6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bc8:	9f35                	addw	a4,a4,a3
    return 0;
    80003bca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bcc:	0cd76063          	bltu	a4,a3,80003c8c <readi+0xe6>
    80003bd0:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003bd2:	00e7f463          	bgeu	a5,a4,80003bda <readi+0x34>
    n = ip->size - off;
    80003bd6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bda:	080a8f63          	beqz	s5,80003c78 <readi+0xd2>
    80003bde:	e8ca                	sd	s2,80(sp)
    80003be0:	f062                	sd	s8,32(sp)
    80003be2:	ec66                	sd	s9,24(sp)
    80003be4:	e86a                	sd	s10,16(sp)
    80003be6:	e46e                	sd	s11,8(sp)
    80003be8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bee:	5c7d                	li	s8,-1
    80003bf0:	a80d                	j	80003c22 <readi+0x7c>
    80003bf2:	020d1d93          	slli	s11,s10,0x20
    80003bf6:	020ddd93          	srli	s11,s11,0x20
    80003bfa:	05890613          	addi	a2,s2,88
    80003bfe:	86ee                	mv	a3,s11
    80003c00:	963a                	add	a2,a2,a4
    80003c02:	85d2                	mv	a1,s4
    80003c04:	855e                	mv	a0,s7
    80003c06:	8f9fe0ef          	jal	800024fe <either_copyout>
    80003c0a:	05850763          	beq	a0,s8,80003c58 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	e42ff0ef          	jal	80003252 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c14:	013d09bb          	addw	s3,s10,s3
    80003c18:	009d04bb          	addw	s1,s10,s1
    80003c1c:	9a6e                	add	s4,s4,s11
    80003c1e:	0559f763          	bgeu	s3,s5,80003c6c <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003c22:	00a4d59b          	srliw	a1,s1,0xa
    80003c26:	855a                	mv	a0,s6
    80003c28:	8a7ff0ef          	jal	800034ce <bmap>
    80003c2c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c30:	c5b1                	beqz	a1,80003c7c <readi+0xd6>
    bp = bread(ip->dev, addr);
    80003c32:	000b2503          	lw	a0,0(s6)
    80003c36:	d14ff0ef          	jal	8000314a <bread>
    80003c3a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3c:	3ff4f713          	andi	a4,s1,1023
    80003c40:	40ec87bb          	subw	a5,s9,a4
    80003c44:	413a86bb          	subw	a3,s5,s3
    80003c48:	8d3e                	mv	s10,a5
    80003c4a:	2781                	sext.w	a5,a5
    80003c4c:	0006861b          	sext.w	a2,a3
    80003c50:	faf671e3          	bgeu	a2,a5,80003bf2 <readi+0x4c>
    80003c54:	8d36                	mv	s10,a3
    80003c56:	bf71                	j	80003bf2 <readi+0x4c>
      brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	df8ff0ef          	jal	80003252 <brelse>
      tot = -1;
    80003c5e:	59fd                	li	s3,-1
      break;
    80003c60:	6946                	ld	s2,80(sp)
    80003c62:	7c02                	ld	s8,32(sp)
    80003c64:	6ce2                	ld	s9,24(sp)
    80003c66:	6d42                	ld	s10,16(sp)
    80003c68:	6da2                	ld	s11,8(sp)
    80003c6a:	a831                	j	80003c86 <readi+0xe0>
    80003c6c:	6946                	ld	s2,80(sp)
    80003c6e:	7c02                	ld	s8,32(sp)
    80003c70:	6ce2                	ld	s9,24(sp)
    80003c72:	6d42                	ld	s10,16(sp)
    80003c74:	6da2                	ld	s11,8(sp)
    80003c76:	a801                	j	80003c86 <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c78:	89d6                	mv	s3,s5
    80003c7a:	a031                	j	80003c86 <readi+0xe0>
    80003c7c:	6946                	ld	s2,80(sp)
    80003c7e:	7c02                	ld	s8,32(sp)
    80003c80:	6ce2                	ld	s9,24(sp)
    80003c82:	6d42                	ld	s10,16(sp)
    80003c84:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003c86:	0009851b          	sext.w	a0,s3
    80003c8a:	69a6                	ld	s3,72(sp)
}
    80003c8c:	70a6                	ld	ra,104(sp)
    80003c8e:	7406                	ld	s0,96(sp)
    80003c90:	64e6                	ld	s1,88(sp)
    80003c92:	6a06                	ld	s4,64(sp)
    80003c94:	7ae2                	ld	s5,56(sp)
    80003c96:	7b42                	ld	s6,48(sp)
    80003c98:	7ba2                	ld	s7,40(sp)
    80003c9a:	6165                	addi	sp,sp,112
    80003c9c:	8082                	ret
    return 0;
    80003c9e:	4501                	li	a0,0
}
    80003ca0:	8082                	ret

0000000080003ca2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ca2:	457c                	lw	a5,76(a0)
    80003ca4:	10d7e063          	bltu	a5,a3,80003da4 <writei+0x102>
{
    80003ca8:	7159                	addi	sp,sp,-112
    80003caa:	f486                	sd	ra,104(sp)
    80003cac:	f0a2                	sd	s0,96(sp)
    80003cae:	e8ca                	sd	s2,80(sp)
    80003cb0:	e0d2                	sd	s4,64(sp)
    80003cb2:	fc56                	sd	s5,56(sp)
    80003cb4:	f85a                	sd	s6,48(sp)
    80003cb6:	f45e                	sd	s7,40(sp)
    80003cb8:	1880                	addi	s0,sp,112
    80003cba:	8aaa                	mv	s5,a0
    80003cbc:	8bae                	mv	s7,a1
    80003cbe:	8a32                	mv	s4,a2
    80003cc0:	8936                	mv	s2,a3
    80003cc2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cc4:	00e687bb          	addw	a5,a3,a4
    80003cc8:	0ed7e063          	bltu	a5,a3,80003da8 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ccc:	00043737          	lui	a4,0x43
    80003cd0:	0cf76e63          	bltu	a4,a5,80003dac <writei+0x10a>
    80003cd4:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd6:	0a0b0f63          	beqz	s6,80003d94 <writei+0xf2>
    80003cda:	eca6                	sd	s1,88(sp)
    80003cdc:	f062                	sd	s8,32(sp)
    80003cde:	ec66                	sd	s9,24(sp)
    80003ce0:	e86a                	sd	s10,16(sp)
    80003ce2:	e46e                	sd	s11,8(sp)
    80003ce4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cea:	5c7d                	li	s8,-1
    80003cec:	a825                	j	80003d24 <writei+0x82>
    80003cee:	020d1d93          	slli	s11,s10,0x20
    80003cf2:	020ddd93          	srli	s11,s11,0x20
    80003cf6:	05848513          	addi	a0,s1,88
    80003cfa:	86ee                	mv	a3,s11
    80003cfc:	8652                	mv	a2,s4
    80003cfe:	85de                	mv	a1,s7
    80003d00:	953a                	add	a0,a0,a4
    80003d02:	847fe0ef          	jal	80002548 <either_copyin>
    80003d06:	05850a63          	beq	a0,s8,80003d5a <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d0a:	8526                	mv	a0,s1
    80003d0c:	678000ef          	jal	80004384 <log_write>
    brelse(bp);
    80003d10:	8526                	mv	a0,s1
    80003d12:	d40ff0ef          	jal	80003252 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d16:	013d09bb          	addw	s3,s10,s3
    80003d1a:	012d093b          	addw	s2,s10,s2
    80003d1e:	9a6e                	add	s4,s4,s11
    80003d20:	0569f063          	bgeu	s3,s6,80003d60 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003d24:	00a9559b          	srliw	a1,s2,0xa
    80003d28:	8556                	mv	a0,s5
    80003d2a:	fa4ff0ef          	jal	800034ce <bmap>
    80003d2e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d32:	c59d                	beqz	a1,80003d60 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003d34:	000aa503          	lw	a0,0(s5)
    80003d38:	c12ff0ef          	jal	8000314a <bread>
    80003d3c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3e:	3ff97713          	andi	a4,s2,1023
    80003d42:	40ec87bb          	subw	a5,s9,a4
    80003d46:	413b06bb          	subw	a3,s6,s3
    80003d4a:	8d3e                	mv	s10,a5
    80003d4c:	2781                	sext.w	a5,a5
    80003d4e:	0006861b          	sext.w	a2,a3
    80003d52:	f8f67ee3          	bgeu	a2,a5,80003cee <writei+0x4c>
    80003d56:	8d36                	mv	s10,a3
    80003d58:	bf59                	j	80003cee <writei+0x4c>
      brelse(bp);
    80003d5a:	8526                	mv	a0,s1
    80003d5c:	cf6ff0ef          	jal	80003252 <brelse>
  }

  if(off > ip->size)
    80003d60:	04caa783          	lw	a5,76(s5)
    80003d64:	0327fa63          	bgeu	a5,s2,80003d98 <writei+0xf6>
    ip->size = off;
    80003d68:	052aa623          	sw	s2,76(s5)
    80003d6c:	64e6                	ld	s1,88(sp)
    80003d6e:	7c02                	ld	s8,32(sp)
    80003d70:	6ce2                	ld	s9,24(sp)
    80003d72:	6d42                	ld	s10,16(sp)
    80003d74:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d76:	8556                	mv	a0,s5
    80003d78:	9ebff0ef          	jal	80003762 <iupdate>

  return tot;
    80003d7c:	0009851b          	sext.w	a0,s3
    80003d80:	69a6                	ld	s3,72(sp)
}
    80003d82:	70a6                	ld	ra,104(sp)
    80003d84:	7406                	ld	s0,96(sp)
    80003d86:	6946                	ld	s2,80(sp)
    80003d88:	6a06                	ld	s4,64(sp)
    80003d8a:	7ae2                	ld	s5,56(sp)
    80003d8c:	7b42                	ld	s6,48(sp)
    80003d8e:	7ba2                	ld	s7,40(sp)
    80003d90:	6165                	addi	sp,sp,112
    80003d92:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d94:	89da                	mv	s3,s6
    80003d96:	b7c5                	j	80003d76 <writei+0xd4>
    80003d98:	64e6                	ld	s1,88(sp)
    80003d9a:	7c02                	ld	s8,32(sp)
    80003d9c:	6ce2                	ld	s9,24(sp)
    80003d9e:	6d42                	ld	s10,16(sp)
    80003da0:	6da2                	ld	s11,8(sp)
    80003da2:	bfd1                	j	80003d76 <writei+0xd4>
    return -1;
    80003da4:	557d                	li	a0,-1
}
    80003da6:	8082                	ret
    return -1;
    80003da8:	557d                	li	a0,-1
    80003daa:	bfe1                	j	80003d82 <writei+0xe0>
    return -1;
    80003dac:	557d                	li	a0,-1
    80003dae:	bfd1                	j	80003d82 <writei+0xe0>

0000000080003db0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003db0:	1141                	addi	sp,sp,-16
    80003db2:	e406                	sd	ra,8(sp)
    80003db4:	e022                	sd	s0,0(sp)
    80003db6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db8:	4639                	li	a2,14
    80003dba:	fb5fc0ef          	jal	80000d6e <strncmp>
}
    80003dbe:	60a2                	ld	ra,8(sp)
    80003dc0:	6402                	ld	s0,0(sp)
    80003dc2:	0141                	addi	sp,sp,16
    80003dc4:	8082                	ret

0000000080003dc6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc6:	7139                	addi	sp,sp,-64
    80003dc8:	fc06                	sd	ra,56(sp)
    80003dca:	f822                	sd	s0,48(sp)
    80003dcc:	f426                	sd	s1,40(sp)
    80003dce:	f04a                	sd	s2,32(sp)
    80003dd0:	ec4e                	sd	s3,24(sp)
    80003dd2:	e852                	sd	s4,16(sp)
    80003dd4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd6:	04451703          	lh	a4,68(a0)
    80003dda:	4785                	li	a5,1
    80003ddc:	00f71a63          	bne	a4,a5,80003df0 <dirlookup+0x2a>
    80003de0:	892a                	mv	s2,a0
    80003de2:	89ae                	mv	s3,a1
    80003de4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de6:	457c                	lw	a5,76(a0)
    80003de8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dea:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dec:	e39d                	bnez	a5,80003e12 <dirlookup+0x4c>
    80003dee:	a095                	j	80003e52 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003df0:	00003517          	auipc	a0,0x3
    80003df4:	6c050513          	addi	a0,a0,1728 # 800074b0 <etext+0x4b0>
    80003df8:	9e9fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003dfc:	00003517          	auipc	a0,0x3
    80003e00:	6cc50513          	addi	a0,a0,1740 # 800074c8 <etext+0x4c8>
    80003e04:	9ddfc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e08:	24c1                	addiw	s1,s1,16
    80003e0a:	04c92783          	lw	a5,76(s2)
    80003e0e:	04f4f163          	bgeu	s1,a5,80003e50 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e12:	4741                	li	a4,16
    80003e14:	86a6                	mv	a3,s1
    80003e16:	fc040613          	addi	a2,s0,-64
    80003e1a:	4581                	li	a1,0
    80003e1c:	854a                	mv	a0,s2
    80003e1e:	d89ff0ef          	jal	80003ba6 <readi>
    80003e22:	47c1                	li	a5,16
    80003e24:	fcf51ce3          	bne	a0,a5,80003dfc <dirlookup+0x36>
    if(de.inum == 0)
    80003e28:	fc045783          	lhu	a5,-64(s0)
    80003e2c:	dff1                	beqz	a5,80003e08 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003e2e:	fc240593          	addi	a1,s0,-62
    80003e32:	854e                	mv	a0,s3
    80003e34:	f7dff0ef          	jal	80003db0 <namecmp>
    80003e38:	f961                	bnez	a0,80003e08 <dirlookup+0x42>
      if(poff)
    80003e3a:	000a0463          	beqz	s4,80003e42 <dirlookup+0x7c>
        *poff = off;
    80003e3e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e42:	fc045583          	lhu	a1,-64(s0)
    80003e46:	00092503          	lw	a0,0(s2)
    80003e4a:	f58ff0ef          	jal	800035a2 <iget>
    80003e4e:	a011                	j	80003e52 <dirlookup+0x8c>
  return 0;
    80003e50:	4501                	li	a0,0
}
    80003e52:	70e2                	ld	ra,56(sp)
    80003e54:	7442                	ld	s0,48(sp)
    80003e56:	74a2                	ld	s1,40(sp)
    80003e58:	7902                	ld	s2,32(sp)
    80003e5a:	69e2                	ld	s3,24(sp)
    80003e5c:	6a42                	ld	s4,16(sp)
    80003e5e:	6121                	addi	sp,sp,64
    80003e60:	8082                	ret

0000000080003e62 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e62:	711d                	addi	sp,sp,-96
    80003e64:	ec86                	sd	ra,88(sp)
    80003e66:	e8a2                	sd	s0,80(sp)
    80003e68:	e4a6                	sd	s1,72(sp)
    80003e6a:	e0ca                	sd	s2,64(sp)
    80003e6c:	fc4e                	sd	s3,56(sp)
    80003e6e:	f852                	sd	s4,48(sp)
    80003e70:	f456                	sd	s5,40(sp)
    80003e72:	f05a                	sd	s6,32(sp)
    80003e74:	ec5e                	sd	s7,24(sp)
    80003e76:	e862                	sd	s8,16(sp)
    80003e78:	e466                	sd	s9,8(sp)
    80003e7a:	1080                	addi	s0,sp,96
    80003e7c:	84aa                	mv	s1,a0
    80003e7e:	8b2e                	mv	s6,a1
    80003e80:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e82:	00054703          	lbu	a4,0(a0)
    80003e86:	02f00793          	li	a5,47
    80003e8a:	00f70e63          	beq	a4,a5,80003ea6 <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e8e:	a41fd0ef          	jal	800018ce <myproc>
    80003e92:	15053503          	ld	a0,336(a0)
    80003e96:	94bff0ef          	jal	800037e0 <idup>
    80003e9a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e9c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ea0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ea2:	4b85                	li	s7,1
    80003ea4:	a871                	j	80003f40 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003ea6:	4585                	li	a1,1
    80003ea8:	4505                	li	a0,1
    80003eaa:	ef8ff0ef          	jal	800035a2 <iget>
    80003eae:	8a2a                	mv	s4,a0
    80003eb0:	b7f5                	j	80003e9c <namex+0x3a>
      iunlockput(ip);
    80003eb2:	8552                	mv	a0,s4
    80003eb4:	b6dff0ef          	jal	80003a20 <iunlockput>
      return 0;
    80003eb8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eba:	8552                	mv	a0,s4
    80003ebc:	60e6                	ld	ra,88(sp)
    80003ebe:	6446                	ld	s0,80(sp)
    80003ec0:	64a6                	ld	s1,72(sp)
    80003ec2:	6906                	ld	s2,64(sp)
    80003ec4:	79e2                	ld	s3,56(sp)
    80003ec6:	7a42                	ld	s4,48(sp)
    80003ec8:	7aa2                	ld	s5,40(sp)
    80003eca:	7b02                	ld	s6,32(sp)
    80003ecc:	6be2                	ld	s7,24(sp)
    80003ece:	6c42                	ld	s8,16(sp)
    80003ed0:	6ca2                	ld	s9,8(sp)
    80003ed2:	6125                	addi	sp,sp,96
    80003ed4:	8082                	ret
      iunlock(ip);
    80003ed6:	8552                	mv	a0,s4
    80003ed8:	9edff0ef          	jal	800038c4 <iunlock>
      return ip;
    80003edc:	bff9                	j	80003eba <namex+0x58>
      iunlockput(ip);
    80003ede:	8552                	mv	a0,s4
    80003ee0:	b41ff0ef          	jal	80003a20 <iunlockput>
      return 0;
    80003ee4:	8a4e                	mv	s4,s3
    80003ee6:	bfd1                	j	80003eba <namex+0x58>
  len = path - s;
    80003ee8:	40998633          	sub	a2,s3,s1
    80003eec:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ef0:	099c5063          	bge	s8,s9,80003f70 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003ef4:	4639                	li	a2,14
    80003ef6:	85a6                	mv	a1,s1
    80003ef8:	8556                	mv	a0,s5
    80003efa:	e05fc0ef          	jal	80000cfe <memmove>
    80003efe:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f00:	0004c783          	lbu	a5,0(s1)
    80003f04:	01279763          	bne	a5,s2,80003f12 <namex+0xb0>
    path++;
    80003f08:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0a:	0004c783          	lbu	a5,0(s1)
    80003f0e:	ff278de3          	beq	a5,s2,80003f08 <namex+0xa6>
    ilock(ip);
    80003f12:	8552                	mv	a0,s4
    80003f14:	903ff0ef          	jal	80003816 <ilock>
    if(ip->type != T_DIR){
    80003f18:	044a1783          	lh	a5,68(s4)
    80003f1c:	f9779be3          	bne	a5,s7,80003eb2 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003f20:	000b0563          	beqz	s6,80003f2a <namex+0xc8>
    80003f24:	0004c783          	lbu	a5,0(s1)
    80003f28:	d7dd                	beqz	a5,80003ed6 <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f2a:	4601                	li	a2,0
    80003f2c:	85d6                	mv	a1,s5
    80003f2e:	8552                	mv	a0,s4
    80003f30:	e97ff0ef          	jal	80003dc6 <dirlookup>
    80003f34:	89aa                	mv	s3,a0
    80003f36:	d545                	beqz	a0,80003ede <namex+0x7c>
    iunlockput(ip);
    80003f38:	8552                	mv	a0,s4
    80003f3a:	ae7ff0ef          	jal	80003a20 <iunlockput>
    ip = next;
    80003f3e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	01279763          	bne	a5,s2,80003f52 <namex+0xf0>
    path++;
    80003f48:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f4a:	0004c783          	lbu	a5,0(s1)
    80003f4e:	ff278de3          	beq	a5,s2,80003f48 <namex+0xe6>
  if(*path == 0)
    80003f52:	cb8d                	beqz	a5,80003f84 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003f54:	0004c783          	lbu	a5,0(s1)
    80003f58:	89a6                	mv	s3,s1
  len = path - s;
    80003f5a:	4c81                	li	s9,0
    80003f5c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003f5e:	01278963          	beq	a5,s2,80003f70 <namex+0x10e>
    80003f62:	d3d9                	beqz	a5,80003ee8 <namex+0x86>
    path++;
    80003f64:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f66:	0009c783          	lbu	a5,0(s3)
    80003f6a:	ff279ce3          	bne	a5,s2,80003f62 <namex+0x100>
    80003f6e:	bfad                	j	80003ee8 <namex+0x86>
    memmove(name, s, len);
    80003f70:	2601                	sext.w	a2,a2
    80003f72:	85a6                	mv	a1,s1
    80003f74:	8556                	mv	a0,s5
    80003f76:	d89fc0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003f7a:	9cd6                	add	s9,s9,s5
    80003f7c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f80:	84ce                	mv	s1,s3
    80003f82:	bfbd                	j	80003f00 <namex+0x9e>
  if(nameiparent){
    80003f84:	f20b0be3          	beqz	s6,80003eba <namex+0x58>
    iput(ip);
    80003f88:	8552                	mv	a0,s4
    80003f8a:	a0fff0ef          	jal	80003998 <iput>
    return 0;
    80003f8e:	4a01                	li	s4,0
    80003f90:	b72d                	j	80003eba <namex+0x58>

0000000080003f92 <dirlink>:
{
    80003f92:	7139                	addi	sp,sp,-64
    80003f94:	fc06                	sd	ra,56(sp)
    80003f96:	f822                	sd	s0,48(sp)
    80003f98:	f04a                	sd	s2,32(sp)
    80003f9a:	ec4e                	sd	s3,24(sp)
    80003f9c:	e852                	sd	s4,16(sp)
    80003f9e:	0080                	addi	s0,sp,64
    80003fa0:	892a                	mv	s2,a0
    80003fa2:	8a2e                	mv	s4,a1
    80003fa4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fa6:	4601                	li	a2,0
    80003fa8:	e1fff0ef          	jal	80003dc6 <dirlookup>
    80003fac:	e535                	bnez	a0,80004018 <dirlink+0x86>
    80003fae:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb0:	04c92483          	lw	s1,76(s2)
    80003fb4:	c48d                	beqz	s1,80003fde <dirlink+0x4c>
    80003fb6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb8:	4741                	li	a4,16
    80003fba:	86a6                	mv	a3,s1
    80003fbc:	fc040613          	addi	a2,s0,-64
    80003fc0:	4581                	li	a1,0
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	be3ff0ef          	jal	80003ba6 <readi>
    80003fc8:	47c1                	li	a5,16
    80003fca:	04f51b63          	bne	a0,a5,80004020 <dirlink+0x8e>
    if(de.inum == 0)
    80003fce:	fc045783          	lhu	a5,-64(s0)
    80003fd2:	c791                	beqz	a5,80003fde <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd4:	24c1                	addiw	s1,s1,16
    80003fd6:	04c92783          	lw	a5,76(s2)
    80003fda:	fcf4efe3          	bltu	s1,a5,80003fb8 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003fde:	4639                	li	a2,14
    80003fe0:	85d2                	mv	a1,s4
    80003fe2:	fc240513          	addi	a0,s0,-62
    80003fe6:	dbffc0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003fea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fee:	4741                	li	a4,16
    80003ff0:	86a6                	mv	a3,s1
    80003ff2:	fc040613          	addi	a2,s0,-64
    80003ff6:	4581                	li	a1,0
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	ca9ff0ef          	jal	80003ca2 <writei>
    80003ffe:	1541                	addi	a0,a0,-16
    80004000:	00a03533          	snez	a0,a0
    80004004:	40a00533          	neg	a0,a0
    80004008:	74a2                	ld	s1,40(sp)
}
    8000400a:	70e2                	ld	ra,56(sp)
    8000400c:	7442                	ld	s0,48(sp)
    8000400e:	7902                	ld	s2,32(sp)
    80004010:	69e2                	ld	s3,24(sp)
    80004012:	6a42                	ld	s4,16(sp)
    80004014:	6121                	addi	sp,sp,64
    80004016:	8082                	ret
    iput(ip);
    80004018:	981ff0ef          	jal	80003998 <iput>
    return -1;
    8000401c:	557d                	li	a0,-1
    8000401e:	b7f5                	j	8000400a <dirlink+0x78>
      panic("dirlink read");
    80004020:	00003517          	auipc	a0,0x3
    80004024:	4b850513          	addi	a0,a0,1208 # 800074d8 <etext+0x4d8>
    80004028:	fb8fc0ef          	jal	800007e0 <panic>

000000008000402c <namei>:

struct inode*
namei(char *path)
{
    8000402c:	1101                	addi	sp,sp,-32
    8000402e:	ec06                	sd	ra,24(sp)
    80004030:	e822                	sd	s0,16(sp)
    80004032:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004034:	fe040613          	addi	a2,s0,-32
    80004038:	4581                	li	a1,0
    8000403a:	e29ff0ef          	jal	80003e62 <namex>
}
    8000403e:	60e2                	ld	ra,24(sp)
    80004040:	6442                	ld	s0,16(sp)
    80004042:	6105                	addi	sp,sp,32
    80004044:	8082                	ret

0000000080004046 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004046:	1141                	addi	sp,sp,-16
    80004048:	e406                	sd	ra,8(sp)
    8000404a:	e022                	sd	s0,0(sp)
    8000404c:	0800                	addi	s0,sp,16
    8000404e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004050:	4585                	li	a1,1
    80004052:	e11ff0ef          	jal	80003e62 <namex>
}
    80004056:	60a2                	ld	ra,8(sp)
    80004058:	6402                	ld	s0,0(sp)
    8000405a:	0141                	addi	sp,sp,16
    8000405c:	8082                	ret

000000008000405e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000405e:	1101                	addi	sp,sp,-32
    80004060:	ec06                	sd	ra,24(sp)
    80004062:	e822                	sd	s0,16(sp)
    80004064:	e426                	sd	s1,8(sp)
    80004066:	e04a                	sd	s2,0(sp)
    80004068:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000406a:	0001d917          	auipc	s2,0x1d
    8000406e:	0ee90913          	addi	s2,s2,238 # 80021158 <log>
    80004072:	01892583          	lw	a1,24(s2)
    80004076:	02492503          	lw	a0,36(s2)
    8000407a:	8d0ff0ef          	jal	8000314a <bread>
    8000407e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004080:	02892603          	lw	a2,40(s2)
    80004084:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004086:	00c05f63          	blez	a2,800040a4 <write_head+0x46>
    8000408a:	0001d717          	auipc	a4,0x1d
    8000408e:	0fa70713          	addi	a4,a4,250 # 80021184 <log+0x2c>
    80004092:	87aa                	mv	a5,a0
    80004094:	060a                	slli	a2,a2,0x2
    80004096:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004098:	4314                	lw	a3,0(a4)
    8000409a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000409c:	0711                	addi	a4,a4,4
    8000409e:	0791                	addi	a5,a5,4
    800040a0:	fec79ce3          	bne	a5,a2,80004098 <write_head+0x3a>
  }
  bwrite(buf);
    800040a4:	8526                	mv	a0,s1
    800040a6:	97aff0ef          	jal	80003220 <bwrite>
  brelse(buf);
    800040aa:	8526                	mv	a0,s1
    800040ac:	9a6ff0ef          	jal	80003252 <brelse>
}
    800040b0:	60e2                	ld	ra,24(sp)
    800040b2:	6442                	ld	s0,16(sp)
    800040b4:	64a2                	ld	s1,8(sp)
    800040b6:	6902                	ld	s2,0(sp)
    800040b8:	6105                	addi	sp,sp,32
    800040ba:	8082                	ret

00000000800040bc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040bc:	0001d797          	auipc	a5,0x1d
    800040c0:	0c47a783          	lw	a5,196(a5) # 80021180 <log+0x28>
    800040c4:	0af05e63          	blez	a5,80004180 <install_trans+0xc4>
{
    800040c8:	715d                	addi	sp,sp,-80
    800040ca:	e486                	sd	ra,72(sp)
    800040cc:	e0a2                	sd	s0,64(sp)
    800040ce:	fc26                	sd	s1,56(sp)
    800040d0:	f84a                	sd	s2,48(sp)
    800040d2:	f44e                	sd	s3,40(sp)
    800040d4:	f052                	sd	s4,32(sp)
    800040d6:	ec56                	sd	s5,24(sp)
    800040d8:	e85a                	sd	s6,16(sp)
    800040da:	e45e                	sd	s7,8(sp)
    800040dc:	0880                	addi	s0,sp,80
    800040de:	8b2a                	mv	s6,a0
    800040e0:	0001da97          	auipc	s5,0x1d
    800040e4:	0a4a8a93          	addi	s5,s5,164 # 80021184 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e8:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800040ea:	00003b97          	auipc	s7,0x3
    800040ee:	3feb8b93          	addi	s7,s7,1022 # 800074e8 <etext+0x4e8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f2:	0001da17          	auipc	s4,0x1d
    800040f6:	066a0a13          	addi	s4,s4,102 # 80021158 <log>
    800040fa:	a025                	j	80004122 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    800040fc:	000aa603          	lw	a2,0(s5)
    80004100:	85ce                	mv	a1,s3
    80004102:	855e                	mv	a0,s7
    80004104:	bf6fc0ef          	jal	800004fa <printf>
    80004108:	a839                	j	80004126 <install_trans+0x6a>
    brelse(lbuf);
    8000410a:	854a                	mv	a0,s2
    8000410c:	946ff0ef          	jal	80003252 <brelse>
    brelse(dbuf);
    80004110:	8526                	mv	a0,s1
    80004112:	940ff0ef          	jal	80003252 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004116:	2985                	addiw	s3,s3,1
    80004118:	0a91                	addi	s5,s5,4
    8000411a:	028a2783          	lw	a5,40(s4)
    8000411e:	04f9d663          	bge	s3,a5,8000416a <install_trans+0xae>
    if(recovering) {
    80004122:	fc0b1de3          	bnez	s6,800040fc <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004126:	018a2583          	lw	a1,24(s4)
    8000412a:	013585bb          	addw	a1,a1,s3
    8000412e:	2585                	addiw	a1,a1,1
    80004130:	024a2503          	lw	a0,36(s4)
    80004134:	816ff0ef          	jal	8000314a <bread>
    80004138:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000413a:	000aa583          	lw	a1,0(s5)
    8000413e:	024a2503          	lw	a0,36(s4)
    80004142:	808ff0ef          	jal	8000314a <bread>
    80004146:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004148:	40000613          	li	a2,1024
    8000414c:	05890593          	addi	a1,s2,88
    80004150:	05850513          	addi	a0,a0,88
    80004154:	babfc0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80004158:	8526                	mv	a0,s1
    8000415a:	8c6ff0ef          	jal	80003220 <bwrite>
    if(recovering == 0)
    8000415e:	fa0b16e3          	bnez	s6,8000410a <install_trans+0x4e>
      bunpin(dbuf);
    80004162:	8526                	mv	a0,s1
    80004164:	9aaff0ef          	jal	8000330e <bunpin>
    80004168:	b74d                	j	8000410a <install_trans+0x4e>
}
    8000416a:	60a6                	ld	ra,72(sp)
    8000416c:	6406                	ld	s0,64(sp)
    8000416e:	74e2                	ld	s1,56(sp)
    80004170:	7942                	ld	s2,48(sp)
    80004172:	79a2                	ld	s3,40(sp)
    80004174:	7a02                	ld	s4,32(sp)
    80004176:	6ae2                	ld	s5,24(sp)
    80004178:	6b42                	ld	s6,16(sp)
    8000417a:	6ba2                	ld	s7,8(sp)
    8000417c:	6161                	addi	sp,sp,80
    8000417e:	8082                	ret
    80004180:	8082                	ret

0000000080004182 <initlog>:
{
    80004182:	7179                	addi	sp,sp,-48
    80004184:	f406                	sd	ra,40(sp)
    80004186:	f022                	sd	s0,32(sp)
    80004188:	ec26                	sd	s1,24(sp)
    8000418a:	e84a                	sd	s2,16(sp)
    8000418c:	e44e                	sd	s3,8(sp)
    8000418e:	1800                	addi	s0,sp,48
    80004190:	892a                	mv	s2,a0
    80004192:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004194:	0001d497          	auipc	s1,0x1d
    80004198:	fc448493          	addi	s1,s1,-60 # 80021158 <log>
    8000419c:	00003597          	auipc	a1,0x3
    800041a0:	36c58593          	addi	a1,a1,876 # 80007508 <etext+0x508>
    800041a4:	8526                	mv	a0,s1
    800041a6:	9a9fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    800041aa:	0149a583          	lw	a1,20(s3)
    800041ae:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    800041b0:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041b4:	854a                	mv	a0,s2
    800041b6:	f95fe0ef          	jal	8000314a <bread>
  log.lh.n = lh->n;
    800041ba:	4d30                	lw	a2,88(a0)
    800041bc:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041be:	00c05f63          	blez	a2,800041dc <initlog+0x5a>
    800041c2:	87aa                	mv	a5,a0
    800041c4:	0001d717          	auipc	a4,0x1d
    800041c8:	fc070713          	addi	a4,a4,-64 # 80021184 <log+0x2c>
    800041cc:	060a                	slli	a2,a2,0x2
    800041ce:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800041d0:	4ff4                	lw	a3,92(a5)
    800041d2:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d4:	0791                	addi	a5,a5,4
    800041d6:	0711                	addi	a4,a4,4
    800041d8:	fec79ce3          	bne	a5,a2,800041d0 <initlog+0x4e>
  brelse(buf);
    800041dc:	876ff0ef          	jal	80003252 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041e0:	4505                	li	a0,1
    800041e2:	edbff0ef          	jal	800040bc <install_trans>
  log.lh.n = 0;
    800041e6:	0001d797          	auipc	a5,0x1d
    800041ea:	f807ad23          	sw	zero,-102(a5) # 80021180 <log+0x28>
  write_head(); // clear the log
    800041ee:	e71ff0ef          	jal	8000405e <write_head>
}
    800041f2:	70a2                	ld	ra,40(sp)
    800041f4:	7402                	ld	s0,32(sp)
    800041f6:	64e2                	ld	s1,24(sp)
    800041f8:	6942                	ld	s2,16(sp)
    800041fa:	69a2                	ld	s3,8(sp)
    800041fc:	6145                	addi	sp,sp,48
    800041fe:	8082                	ret

0000000080004200 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	e04a                	sd	s2,0(sp)
    8000420a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000420c:	0001d517          	auipc	a0,0x1d
    80004210:	f4c50513          	addi	a0,a0,-180 # 80021158 <log>
    80004214:	9bbfc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80004218:	0001d497          	auipc	s1,0x1d
    8000421c:	f4048493          	addi	s1,s1,-192 # 80021158 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004220:	4979                	li	s2,30
    80004222:	a029                	j	8000422c <begin_op+0x2c>
      sleep(&log, &log.lock);
    80004224:	85a6                	mv	a1,s1
    80004226:	8526                	mv	a0,s1
    80004228:	f77fd0ef          	jal	8000219e <sleep>
    if(log.committing){
    8000422c:	509c                	lw	a5,32(s1)
    8000422e:	fbfd                	bnez	a5,80004224 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80004230:	4cd8                	lw	a4,28(s1)
    80004232:	2705                	addiw	a4,a4,1
    80004234:	0027179b          	slliw	a5,a4,0x2
    80004238:	9fb9                	addw	a5,a5,a4
    8000423a:	0017979b          	slliw	a5,a5,0x1
    8000423e:	5494                	lw	a3,40(s1)
    80004240:	9fb5                	addw	a5,a5,a3
    80004242:	00f95763          	bge	s2,a5,80004250 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004246:	85a6                	mv	a1,s1
    80004248:	8526                	mv	a0,s1
    8000424a:	f55fd0ef          	jal	8000219e <sleep>
    8000424e:	bff9                	j	8000422c <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80004250:	0001d517          	auipc	a0,0x1d
    80004254:	f0850513          	addi	a0,a0,-248 # 80021158 <log>
    80004258:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    8000425a:	a0dfc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    8000425e:	60e2                	ld	ra,24(sp)
    80004260:	6442                	ld	s0,16(sp)
    80004262:	64a2                	ld	s1,8(sp)
    80004264:	6902                	ld	s2,0(sp)
    80004266:	6105                	addi	sp,sp,32
    80004268:	8082                	ret

000000008000426a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000426a:	7139                	addi	sp,sp,-64
    8000426c:	fc06                	sd	ra,56(sp)
    8000426e:	f822                	sd	s0,48(sp)
    80004270:	f426                	sd	s1,40(sp)
    80004272:	f04a                	sd	s2,32(sp)
    80004274:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004276:	0001d497          	auipc	s1,0x1d
    8000427a:	ee248493          	addi	s1,s1,-286 # 80021158 <log>
    8000427e:	8526                	mv	a0,s1
    80004280:	94ffc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80004284:	4cdc                	lw	a5,28(s1)
    80004286:	37fd                	addiw	a5,a5,-1
    80004288:	0007891b          	sext.w	s2,a5
    8000428c:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    8000428e:	509c                	lw	a5,32(s1)
    80004290:	ef9d                	bnez	a5,800042ce <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80004292:	04091763          	bnez	s2,800042e0 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80004296:	0001d497          	auipc	s1,0x1d
    8000429a:	ec248493          	addi	s1,s1,-318 # 80021158 <log>
    8000429e:	4785                	li	a5,1
    800042a0:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a2:	8526                	mv	a0,s1
    800042a4:	9c3fc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042a8:	549c                	lw	a5,40(s1)
    800042aa:	04f04b63          	bgtz	a5,80004300 <end_op+0x96>
    acquire(&log.lock);
    800042ae:	0001d497          	auipc	s1,0x1d
    800042b2:	eaa48493          	addi	s1,s1,-342 # 80021158 <log>
    800042b6:	8526                	mv	a0,s1
    800042b8:	917fc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    800042bc:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    800042c0:	8526                	mv	a0,s1
    800042c2:	f2dfd0ef          	jal	800021ee <wakeup>
    release(&log.lock);
    800042c6:	8526                	mv	a0,s1
    800042c8:	99ffc0ef          	jal	80000c66 <release>
}
    800042cc:	a025                	j	800042f4 <end_op+0x8a>
    800042ce:	ec4e                	sd	s3,24(sp)
    800042d0:	e852                	sd	s4,16(sp)
    800042d2:	e456                	sd	s5,8(sp)
    panic("log.committing");
    800042d4:	00003517          	auipc	a0,0x3
    800042d8:	23c50513          	addi	a0,a0,572 # 80007510 <etext+0x510>
    800042dc:	d04fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    800042e0:	0001d497          	auipc	s1,0x1d
    800042e4:	e7848493          	addi	s1,s1,-392 # 80021158 <log>
    800042e8:	8526                	mv	a0,s1
    800042ea:	f05fd0ef          	jal	800021ee <wakeup>
  release(&log.lock);
    800042ee:	8526                	mv	a0,s1
    800042f0:	977fc0ef          	jal	80000c66 <release>
}
    800042f4:	70e2                	ld	ra,56(sp)
    800042f6:	7442                	ld	s0,48(sp)
    800042f8:	74a2                	ld	s1,40(sp)
    800042fa:	7902                	ld	s2,32(sp)
    800042fc:	6121                	addi	sp,sp,64
    800042fe:	8082                	ret
    80004300:	ec4e                	sd	s3,24(sp)
    80004302:	e852                	sd	s4,16(sp)
    80004304:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004306:	0001da97          	auipc	s5,0x1d
    8000430a:	e7ea8a93          	addi	s5,s5,-386 # 80021184 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000430e:	0001da17          	auipc	s4,0x1d
    80004312:	e4aa0a13          	addi	s4,s4,-438 # 80021158 <log>
    80004316:	018a2583          	lw	a1,24(s4)
    8000431a:	012585bb          	addw	a1,a1,s2
    8000431e:	2585                	addiw	a1,a1,1
    80004320:	024a2503          	lw	a0,36(s4)
    80004324:	e27fe0ef          	jal	8000314a <bread>
    80004328:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000432a:	000aa583          	lw	a1,0(s5)
    8000432e:	024a2503          	lw	a0,36(s4)
    80004332:	e19fe0ef          	jal	8000314a <bread>
    80004336:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004338:	40000613          	li	a2,1024
    8000433c:	05850593          	addi	a1,a0,88
    80004340:	05848513          	addi	a0,s1,88
    80004344:	9bbfc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    80004348:	8526                	mv	a0,s1
    8000434a:	ed7fe0ef          	jal	80003220 <bwrite>
    brelse(from);
    8000434e:	854e                	mv	a0,s3
    80004350:	f03fe0ef          	jal	80003252 <brelse>
    brelse(to);
    80004354:	8526                	mv	a0,s1
    80004356:	efdfe0ef          	jal	80003252 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000435a:	2905                	addiw	s2,s2,1
    8000435c:	0a91                	addi	s5,s5,4
    8000435e:	028a2783          	lw	a5,40(s4)
    80004362:	faf94ae3          	blt	s2,a5,80004316 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004366:	cf9ff0ef          	jal	8000405e <write_head>
    install_trans(0); // Now install writes to home locations
    8000436a:	4501                	li	a0,0
    8000436c:	d51ff0ef          	jal	800040bc <install_trans>
    log.lh.n = 0;
    80004370:	0001d797          	auipc	a5,0x1d
    80004374:	e007a823          	sw	zero,-496(a5) # 80021180 <log+0x28>
    write_head();    // Erase the transaction from the log
    80004378:	ce7ff0ef          	jal	8000405e <write_head>
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	b735                	j	800042ae <end_op+0x44>

0000000080004384 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004384:	1101                	addi	sp,sp,-32
    80004386:	ec06                	sd	ra,24(sp)
    80004388:	e822                	sd	s0,16(sp)
    8000438a:	e426                	sd	s1,8(sp)
    8000438c:	e04a                	sd	s2,0(sp)
    8000438e:	1000                	addi	s0,sp,32
    80004390:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004392:	0001d917          	auipc	s2,0x1d
    80004396:	dc690913          	addi	s2,s2,-570 # 80021158 <log>
    8000439a:	854a                	mv	a0,s2
    8000439c:	833fc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    800043a0:	02892603          	lw	a2,40(s2)
    800043a4:	47f5                	li	a5,29
    800043a6:	04c7cc63          	blt	a5,a2,800043fe <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043aa:	0001d797          	auipc	a5,0x1d
    800043ae:	dca7a783          	lw	a5,-566(a5) # 80021174 <log+0x1c>
    800043b2:	04f05c63          	blez	a5,8000440a <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043b6:	4781                	li	a5,0
    800043b8:	04c05f63          	blez	a2,80004416 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043bc:	44cc                	lw	a1,12(s1)
    800043be:	0001d717          	auipc	a4,0x1d
    800043c2:	dc670713          	addi	a4,a4,-570 # 80021184 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c8:	4314                	lw	a3,0(a4)
    800043ca:	04b68663          	beq	a3,a1,80004416 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	2785                	addiw	a5,a5,1
    800043d0:	0711                	addi	a4,a4,4
    800043d2:	fef61be3          	bne	a2,a5,800043c8 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043d6:	0621                	addi	a2,a2,8
    800043d8:	060a                	slli	a2,a2,0x2
    800043da:	0001d797          	auipc	a5,0x1d
    800043de:	d7e78793          	addi	a5,a5,-642 # 80021158 <log>
    800043e2:	97b2                	add	a5,a5,a2
    800043e4:	44d8                	lw	a4,12(s1)
    800043e6:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043e8:	8526                	mv	a0,s1
    800043ea:	ef1fe0ef          	jal	800032da <bpin>
    log.lh.n++;
    800043ee:	0001d717          	auipc	a4,0x1d
    800043f2:	d6a70713          	addi	a4,a4,-662 # 80021158 <log>
    800043f6:	571c                	lw	a5,40(a4)
    800043f8:	2785                	addiw	a5,a5,1
    800043fa:	d71c                	sw	a5,40(a4)
    800043fc:	a80d                	j	8000442e <log_write+0xaa>
    panic("too big a transaction");
    800043fe:	00003517          	auipc	a0,0x3
    80004402:	12250513          	addi	a0,a0,290 # 80007520 <etext+0x520>
    80004406:	bdafc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    8000440a:	00003517          	auipc	a0,0x3
    8000440e:	12e50513          	addi	a0,a0,302 # 80007538 <etext+0x538>
    80004412:	bcefc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80004416:	00878693          	addi	a3,a5,8
    8000441a:	068a                	slli	a3,a3,0x2
    8000441c:	0001d717          	auipc	a4,0x1d
    80004420:	d3c70713          	addi	a4,a4,-708 # 80021158 <log>
    80004424:	9736                	add	a4,a4,a3
    80004426:	44d4                	lw	a3,12(s1)
    80004428:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442a:	faf60fe3          	beq	a2,a5,800043e8 <log_write+0x64>
  }
  release(&log.lock);
    8000442e:	0001d517          	auipc	a0,0x1d
    80004432:	d2a50513          	addi	a0,a0,-726 # 80021158 <log>
    80004436:	831fc0ef          	jal	80000c66 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
    80004454:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004456:	00003597          	auipc	a1,0x3
    8000445a:	10258593          	addi	a1,a1,258 # 80007558 <etext+0x558>
    8000445e:	0521                	addi	a0,a0,8
    80004460:	eeefc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    80004464:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004468:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446c:	0204a423          	sw	zero,40(s1)
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	e04a                	sd	s2,0(sp)
    80004486:	1000                	addi	s0,sp,32
    80004488:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448a:	00850913          	addi	s2,a0,8
    8000448e:	854a                	mv	a0,s2
    80004490:	f3efc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80004494:	409c                	lw	a5,0(s1)
    80004496:	c799                	beqz	a5,800044a4 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004498:	85ca                	mv	a1,s2
    8000449a:	8526                	mv	a0,s1
    8000449c:	d03fd0ef          	jal	8000219e <sleep>
  while (lk->locked) {
    800044a0:	409c                	lw	a5,0(s1)
    800044a2:	fbfd                	bnez	a5,80004498 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    800044a4:	4785                	li	a5,1
    800044a6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a8:	c26fd0ef          	jal	800018ce <myproc>
    800044ac:	591c                	lw	a5,48(a0)
    800044ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b0:	854a                	mv	a0,s2
    800044b2:	fb4fc0ef          	jal	80000c66 <release>
}
    800044b6:	60e2                	ld	ra,24(sp)
    800044b8:	6442                	ld	s0,16(sp)
    800044ba:	64a2                	ld	s1,8(sp)
    800044bc:	6902                	ld	s2,0(sp)
    800044be:	6105                	addi	sp,sp,32
    800044c0:	8082                	ret

00000000800044c2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c2:	1101                	addi	sp,sp,-32
    800044c4:	ec06                	sd	ra,24(sp)
    800044c6:	e822                	sd	s0,16(sp)
    800044c8:	e426                	sd	s1,8(sp)
    800044ca:	e04a                	sd	s2,0(sp)
    800044cc:	1000                	addi	s0,sp,32
    800044ce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d0:	00850913          	addi	s2,a0,8
    800044d4:	854a                	mv	a0,s2
    800044d6:	ef8fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e2:	8526                	mv	a0,s1
    800044e4:	d0bfd0ef          	jal	800021ee <wakeup>
  release(&lk->lk);
    800044e8:	854a                	mv	a0,s2
    800044ea:	f7cfc0ef          	jal	80000c66 <release>
}
    800044ee:	60e2                	ld	ra,24(sp)
    800044f0:	6442                	ld	s0,16(sp)
    800044f2:	64a2                	ld	s1,8(sp)
    800044f4:	6902                	ld	s2,0(sp)
    800044f6:	6105                	addi	sp,sp,32
    800044f8:	8082                	ret

00000000800044fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044fa:	7179                	addi	sp,sp,-48
    800044fc:	f406                	sd	ra,40(sp)
    800044fe:	f022                	sd	s0,32(sp)
    80004500:	ec26                	sd	s1,24(sp)
    80004502:	e84a                	sd	s2,16(sp)
    80004504:	1800                	addi	s0,sp,48
    80004506:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004508:	00850913          	addi	s2,a0,8
    8000450c:	854a                	mv	a0,s2
    8000450e:	ec0fc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004512:	409c                	lw	a5,0(s1)
    80004514:	ef81                	bnez	a5,8000452c <holdingsleep+0x32>
    80004516:	4481                	li	s1,0
  release(&lk->lk);
    80004518:	854a                	mv	a0,s2
    8000451a:	f4cfc0ef          	jal	80000c66 <release>
  return r;
}
    8000451e:	8526                	mv	a0,s1
    80004520:	70a2                	ld	ra,40(sp)
    80004522:	7402                	ld	s0,32(sp)
    80004524:	64e2                	ld	s1,24(sp)
    80004526:	6942                	ld	s2,16(sp)
    80004528:	6145                	addi	sp,sp,48
    8000452a:	8082                	ret
    8000452c:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452e:	0284a983          	lw	s3,40(s1)
    80004532:	b9cfd0ef          	jal	800018ce <myproc>
    80004536:	5904                	lw	s1,48(a0)
    80004538:	413484b3          	sub	s1,s1,s3
    8000453c:	0014b493          	seqz	s1,s1
    80004540:	69a2                	ld	s3,8(sp)
    80004542:	bfd9                	j	80004518 <holdingsleep+0x1e>

0000000080004544 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004544:	1141                	addi	sp,sp,-16
    80004546:	e406                	sd	ra,8(sp)
    80004548:	e022                	sd	s0,0(sp)
    8000454a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000454c:	00003597          	auipc	a1,0x3
    80004550:	01c58593          	addi	a1,a1,28 # 80007568 <etext+0x568>
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	d4c50513          	addi	a0,a0,-692 # 800212a0 <ftable>
    8000455c:	df2fc0ef          	jal	80000b4e <initlock>
}
    80004560:	60a2                	ld	ra,8(sp)
    80004562:	6402                	ld	s0,0(sp)
    80004564:	0141                	addi	sp,sp,16
    80004566:	8082                	ret

0000000080004568 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	d2e50513          	addi	a0,a0,-722 # 800212a0 <ftable>
    8000457a:	e54fc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457e:	0001d497          	auipc	s1,0x1d
    80004582:	d3a48493          	addi	s1,s1,-710 # 800212b8 <ftable+0x18>
    80004586:	0001e717          	auipc	a4,0x1e
    8000458a:	cd270713          	addi	a4,a4,-814 # 80022258 <disk>
    if(f->ref == 0){
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	cf89                	beqz	a5,800045aa <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004592:	02848493          	addi	s1,s1,40
    80004596:	fee49ce3          	bne	s1,a4,8000458e <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	d0650513          	addi	a0,a0,-762 # 800212a0 <ftable>
    800045a2:	ec4fc0ef          	jal	80000c66 <release>
  return 0;
    800045a6:	4481                	li	s1,0
    800045a8:	a809                	j	800045ba <filealloc+0x52>
      f->ref = 1;
    800045aa:	4785                	li	a5,1
    800045ac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ae:	0001d517          	auipc	a0,0x1d
    800045b2:	cf250513          	addi	a0,a0,-782 # 800212a0 <ftable>
    800045b6:	eb0fc0ef          	jal	80000c66 <release>
}
    800045ba:	8526                	mv	a0,s1
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret

00000000800045c6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	1000                	addi	s0,sp,32
    800045d0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045d2:	0001d517          	auipc	a0,0x1d
    800045d6:	cce50513          	addi	a0,a0,-818 # 800212a0 <ftable>
    800045da:	df4fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800045de:	40dc                	lw	a5,4(s1)
    800045e0:	02f05063          	blez	a5,80004600 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    800045e4:	2785                	addiw	a5,a5,1
    800045e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045e8:	0001d517          	auipc	a0,0x1d
    800045ec:	cb850513          	addi	a0,a0,-840 # 800212a0 <ftable>
    800045f0:	e76fc0ef          	jal	80000c66 <release>
  return f;
}
    800045f4:	8526                	mv	a0,s1
    800045f6:	60e2                	ld	ra,24(sp)
    800045f8:	6442                	ld	s0,16(sp)
    800045fa:	64a2                	ld	s1,8(sp)
    800045fc:	6105                	addi	sp,sp,32
    800045fe:	8082                	ret
    panic("filedup");
    80004600:	00003517          	auipc	a0,0x3
    80004604:	f7050513          	addi	a0,a0,-144 # 80007570 <etext+0x570>
    80004608:	9d8fc0ef          	jal	800007e0 <panic>

000000008000460c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000460c:	7139                	addi	sp,sp,-64
    8000460e:	fc06                	sd	ra,56(sp)
    80004610:	f822                	sd	s0,48(sp)
    80004612:	f426                	sd	s1,40(sp)
    80004614:	0080                	addi	s0,sp,64
    80004616:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	c8850513          	addi	a0,a0,-888 # 800212a0 <ftable>
    80004620:	daefc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004624:	40dc                	lw	a5,4(s1)
    80004626:	04f05a63          	blez	a5,8000467a <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    8000462a:	37fd                	addiw	a5,a5,-1
    8000462c:	0007871b          	sext.w	a4,a5
    80004630:	c0dc                	sw	a5,4(s1)
    80004632:	04e04e63          	bgtz	a4,8000468e <fileclose+0x82>
    80004636:	f04a                	sd	s2,32(sp)
    80004638:	ec4e                	sd	s3,24(sp)
    8000463a:	e852                	sd	s4,16(sp)
    8000463c:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000463e:	0004a903          	lw	s2,0(s1)
    80004642:	0094ca83          	lbu	s5,9(s1)
    80004646:	0104ba03          	ld	s4,16(s1)
    8000464a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000464e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004652:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004656:	0001d517          	auipc	a0,0x1d
    8000465a:	c4a50513          	addi	a0,a0,-950 # 800212a0 <ftable>
    8000465e:	e08fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    80004662:	4785                	li	a5,1
    80004664:	04f90063          	beq	s2,a5,800046a4 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004668:	3979                	addiw	s2,s2,-2
    8000466a:	4785                	li	a5,1
    8000466c:	0527f563          	bgeu	a5,s2,800046b6 <fileclose+0xaa>
    80004670:	7902                	ld	s2,32(sp)
    80004672:	69e2                	ld	s3,24(sp)
    80004674:	6a42                	ld	s4,16(sp)
    80004676:	6aa2                	ld	s5,8(sp)
    80004678:	a00d                	j	8000469a <fileclose+0x8e>
    8000467a:	f04a                	sd	s2,32(sp)
    8000467c:	ec4e                	sd	s3,24(sp)
    8000467e:	e852                	sd	s4,16(sp)
    80004680:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004682:	00003517          	auipc	a0,0x3
    80004686:	ef650513          	addi	a0,a0,-266 # 80007578 <etext+0x578>
    8000468a:	956fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    8000468e:	0001d517          	auipc	a0,0x1d
    80004692:	c1250513          	addi	a0,a0,-1006 # 800212a0 <ftable>
    80004696:	dd0fc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    8000469a:	70e2                	ld	ra,56(sp)
    8000469c:	7442                	ld	s0,48(sp)
    8000469e:	74a2                	ld	s1,40(sp)
    800046a0:	6121                	addi	sp,sp,64
    800046a2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046a4:	85d6                	mv	a1,s5
    800046a6:	8552                	mv	a0,s4
    800046a8:	336000ef          	jal	800049de <pipeclose>
    800046ac:	7902                	ld	s2,32(sp)
    800046ae:	69e2                	ld	s3,24(sp)
    800046b0:	6a42                	ld	s4,16(sp)
    800046b2:	6aa2                	ld	s5,8(sp)
    800046b4:	b7dd                	j	8000469a <fileclose+0x8e>
    begin_op();
    800046b6:	b4bff0ef          	jal	80004200 <begin_op>
    iput(ff.ip);
    800046ba:	854e                	mv	a0,s3
    800046bc:	adcff0ef          	jal	80003998 <iput>
    end_op();
    800046c0:	babff0ef          	jal	8000426a <end_op>
    800046c4:	7902                	ld	s2,32(sp)
    800046c6:	69e2                	ld	s3,24(sp)
    800046c8:	6a42                	ld	s4,16(sp)
    800046ca:	6aa2                	ld	s5,8(sp)
    800046cc:	b7f9                	j	8000469a <fileclose+0x8e>

00000000800046ce <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ce:	715d                	addi	sp,sp,-80
    800046d0:	e486                	sd	ra,72(sp)
    800046d2:	e0a2                	sd	s0,64(sp)
    800046d4:	fc26                	sd	s1,56(sp)
    800046d6:	f44e                	sd	s3,40(sp)
    800046d8:	0880                	addi	s0,sp,80
    800046da:	84aa                	mv	s1,a0
    800046dc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046de:	9f0fd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046e2:	409c                	lw	a5,0(s1)
    800046e4:	37f9                	addiw	a5,a5,-2
    800046e6:	4705                	li	a4,1
    800046e8:	04f76063          	bltu	a4,a5,80004728 <filestat+0x5a>
    800046ec:	f84a                	sd	s2,48(sp)
    800046ee:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f0:	6c88                	ld	a0,24(s1)
    800046f2:	924ff0ef          	jal	80003816 <ilock>
    stati(f->ip, &st);
    800046f6:	fb840593          	addi	a1,s0,-72
    800046fa:	6c88                	ld	a0,24(s1)
    800046fc:	c80ff0ef          	jal	80003b7c <stati>
    iunlock(f->ip);
    80004700:	6c88                	ld	a0,24(s1)
    80004702:	9c2ff0ef          	jal	800038c4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004706:	46e1                	li	a3,24
    80004708:	fb840613          	addi	a2,s0,-72
    8000470c:	85ce                	mv	a1,s3
    8000470e:	05093503          	ld	a0,80(s2)
    80004712:	ed1fc0ef          	jal	800015e2 <copyout>
    80004716:	41f5551b          	sraiw	a0,a0,0x1f
    8000471a:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    8000471c:	60a6                	ld	ra,72(sp)
    8000471e:	6406                	ld	s0,64(sp)
    80004720:	74e2                	ld	s1,56(sp)
    80004722:	79a2                	ld	s3,40(sp)
    80004724:	6161                	addi	sp,sp,80
    80004726:	8082                	ret
  return -1;
    80004728:	557d                	li	a0,-1
    8000472a:	bfcd                	j	8000471c <filestat+0x4e>

000000008000472c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000472c:	7179                	addi	sp,sp,-48
    8000472e:	f406                	sd	ra,40(sp)
    80004730:	f022                	sd	s0,32(sp)
    80004732:	e84a                	sd	s2,16(sp)
    80004734:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004736:	00854783          	lbu	a5,8(a0)
    8000473a:	cfd1                	beqz	a5,800047d6 <fileread+0xaa>
    8000473c:	ec26                	sd	s1,24(sp)
    8000473e:	e44e                	sd	s3,8(sp)
    80004740:	84aa                	mv	s1,a0
    80004742:	89ae                	mv	s3,a1
    80004744:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004746:	411c                	lw	a5,0(a0)
    80004748:	4705                	li	a4,1
    8000474a:	04e78363          	beq	a5,a4,80004790 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000474e:	470d                	li	a4,3
    80004750:	04e78763          	beq	a5,a4,8000479e <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004754:	4709                	li	a4,2
    80004756:	06e79a63          	bne	a5,a4,800047ca <fileread+0x9e>
    ilock(f->ip);
    8000475a:	6d08                	ld	a0,24(a0)
    8000475c:	8baff0ef          	jal	80003816 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004760:	874a                	mv	a4,s2
    80004762:	5094                	lw	a3,32(s1)
    80004764:	864e                	mv	a2,s3
    80004766:	4585                	li	a1,1
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	c3cff0ef          	jal	80003ba6 <readi>
    8000476e:	892a                	mv	s2,a0
    80004770:	00a05563          	blez	a0,8000477a <fileread+0x4e>
      f->off += r;
    80004774:	509c                	lw	a5,32(s1)
    80004776:	9fa9                	addw	a5,a5,a0
    80004778:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000477a:	6c88                	ld	a0,24(s1)
    8000477c:	948ff0ef          	jal	800038c4 <iunlock>
    80004780:	64e2                	ld	s1,24(sp)
    80004782:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004784:	854a                	mv	a0,s2
    80004786:	70a2                	ld	ra,40(sp)
    80004788:	7402                	ld	s0,32(sp)
    8000478a:	6942                	ld	s2,16(sp)
    8000478c:	6145                	addi	sp,sp,48
    8000478e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004790:	6908                	ld	a0,16(a0)
    80004792:	388000ef          	jal	80004b1a <piperead>
    80004796:	892a                	mv	s2,a0
    80004798:	64e2                	ld	s1,24(sp)
    8000479a:	69a2                	ld	s3,8(sp)
    8000479c:	b7e5                	j	80004784 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000479e:	02451783          	lh	a5,36(a0)
    800047a2:	03079693          	slli	a3,a5,0x30
    800047a6:	92c1                	srli	a3,a3,0x30
    800047a8:	4725                	li	a4,9
    800047aa:	02d76863          	bltu	a4,a3,800047da <fileread+0xae>
    800047ae:	0792                	slli	a5,a5,0x4
    800047b0:	0001d717          	auipc	a4,0x1d
    800047b4:	a5070713          	addi	a4,a4,-1456 # 80021200 <devsw>
    800047b8:	97ba                	add	a5,a5,a4
    800047ba:	639c                	ld	a5,0(a5)
    800047bc:	c39d                	beqz	a5,800047e2 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    800047be:	4505                	li	a0,1
    800047c0:	9782                	jalr	a5
    800047c2:	892a                	mv	s2,a0
    800047c4:	64e2                	ld	s1,24(sp)
    800047c6:	69a2                	ld	s3,8(sp)
    800047c8:	bf75                	j	80004784 <fileread+0x58>
    panic("fileread");
    800047ca:	00003517          	auipc	a0,0x3
    800047ce:	dbe50513          	addi	a0,a0,-578 # 80007588 <etext+0x588>
    800047d2:	80efc0ef          	jal	800007e0 <panic>
    return -1;
    800047d6:	597d                	li	s2,-1
    800047d8:	b775                	j	80004784 <fileread+0x58>
      return -1;
    800047da:	597d                	li	s2,-1
    800047dc:	64e2                	ld	s1,24(sp)
    800047de:	69a2                	ld	s3,8(sp)
    800047e0:	b755                	j	80004784 <fileread+0x58>
    800047e2:	597d                	li	s2,-1
    800047e4:	64e2                	ld	s1,24(sp)
    800047e6:	69a2                	ld	s3,8(sp)
    800047e8:	bf71                	j	80004784 <fileread+0x58>

00000000800047ea <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047ea:	00954783          	lbu	a5,9(a0)
    800047ee:	10078b63          	beqz	a5,80004904 <filewrite+0x11a>
{
    800047f2:	715d                	addi	sp,sp,-80
    800047f4:	e486                	sd	ra,72(sp)
    800047f6:	e0a2                	sd	s0,64(sp)
    800047f8:	f84a                	sd	s2,48(sp)
    800047fa:	f052                	sd	s4,32(sp)
    800047fc:	e85a                	sd	s6,16(sp)
    800047fe:	0880                	addi	s0,sp,80
    80004800:	892a                	mv	s2,a0
    80004802:	8b2e                	mv	s6,a1
    80004804:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004806:	411c                	lw	a5,0(a0)
    80004808:	4705                	li	a4,1
    8000480a:	02e78763          	beq	a5,a4,80004838 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480e:	470d                	li	a4,3
    80004810:	02e78863          	beq	a5,a4,80004840 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004814:	4709                	li	a4,2
    80004816:	0ce79c63          	bne	a5,a4,800048ee <filewrite+0x104>
    8000481a:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000481c:	0ac05863          	blez	a2,800048cc <filewrite+0xe2>
    80004820:	fc26                	sd	s1,56(sp)
    80004822:	ec56                	sd	s5,24(sp)
    80004824:	e45e                	sd	s7,8(sp)
    80004826:	e062                	sd	s8,0(sp)
    int i = 0;
    80004828:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    8000482a:	6b85                	lui	s7,0x1
    8000482c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004830:	6c05                	lui	s8,0x1
    80004832:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004836:	a8b5                	j	800048b2 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    80004838:	6908                	ld	a0,16(a0)
    8000483a:	1fc000ef          	jal	80004a36 <pipewrite>
    8000483e:	a04d                	j	800048e0 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004840:	02451783          	lh	a5,36(a0)
    80004844:	03079693          	slli	a3,a5,0x30
    80004848:	92c1                	srli	a3,a3,0x30
    8000484a:	4725                	li	a4,9
    8000484c:	0ad76e63          	bltu	a4,a3,80004908 <filewrite+0x11e>
    80004850:	0792                	slli	a5,a5,0x4
    80004852:	0001d717          	auipc	a4,0x1d
    80004856:	9ae70713          	addi	a4,a4,-1618 # 80021200 <devsw>
    8000485a:	97ba                	add	a5,a5,a4
    8000485c:	679c                	ld	a5,8(a5)
    8000485e:	c7dd                	beqz	a5,8000490c <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    80004860:	4505                	li	a0,1
    80004862:	9782                	jalr	a5
    80004864:	a8b5                	j	800048e0 <filewrite+0xf6>
      if(n1 > max)
    80004866:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000486a:	997ff0ef          	jal	80004200 <begin_op>
      ilock(f->ip);
    8000486e:	01893503          	ld	a0,24(s2)
    80004872:	fa5fe0ef          	jal	80003816 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004876:	8756                	mv	a4,s5
    80004878:	02092683          	lw	a3,32(s2)
    8000487c:	01698633          	add	a2,s3,s6
    80004880:	4585                	li	a1,1
    80004882:	01893503          	ld	a0,24(s2)
    80004886:	c1cff0ef          	jal	80003ca2 <writei>
    8000488a:	84aa                	mv	s1,a0
    8000488c:	00a05763          	blez	a0,8000489a <filewrite+0xb0>
        f->off += r;
    80004890:	02092783          	lw	a5,32(s2)
    80004894:	9fa9                	addw	a5,a5,a0
    80004896:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000489a:	01893503          	ld	a0,24(s2)
    8000489e:	826ff0ef          	jal	800038c4 <iunlock>
      end_op();
    800048a2:	9c9ff0ef          	jal	8000426a <end_op>

      if(r != n1){
    800048a6:	029a9563          	bne	s5,s1,800048d0 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    800048aa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048ae:	0149da63          	bge	s3,s4,800048c2 <filewrite+0xd8>
      int n1 = n - i;
    800048b2:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800048b6:	0004879b          	sext.w	a5,s1
    800048ba:	fafbd6e3          	bge	s7,a5,80004866 <filewrite+0x7c>
    800048be:	84e2                	mv	s1,s8
    800048c0:	b75d                	j	80004866 <filewrite+0x7c>
    800048c2:	74e2                	ld	s1,56(sp)
    800048c4:	6ae2                	ld	s5,24(sp)
    800048c6:	6ba2                	ld	s7,8(sp)
    800048c8:	6c02                	ld	s8,0(sp)
    800048ca:	a039                	j	800048d8 <filewrite+0xee>
    int i = 0;
    800048cc:	4981                	li	s3,0
    800048ce:	a029                	j	800048d8 <filewrite+0xee>
    800048d0:	74e2                	ld	s1,56(sp)
    800048d2:	6ae2                	ld	s5,24(sp)
    800048d4:	6ba2                	ld	s7,8(sp)
    800048d6:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800048d8:	033a1c63          	bne	s4,s3,80004910 <filewrite+0x126>
    800048dc:	8552                	mv	a0,s4
    800048de:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048e0:	60a6                	ld	ra,72(sp)
    800048e2:	6406                	ld	s0,64(sp)
    800048e4:	7942                	ld	s2,48(sp)
    800048e6:	7a02                	ld	s4,32(sp)
    800048e8:	6b42                	ld	s6,16(sp)
    800048ea:	6161                	addi	sp,sp,80
    800048ec:	8082                	ret
    800048ee:	fc26                	sd	s1,56(sp)
    800048f0:	f44e                	sd	s3,40(sp)
    800048f2:	ec56                	sd	s5,24(sp)
    800048f4:	e45e                	sd	s7,8(sp)
    800048f6:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800048f8:	00003517          	auipc	a0,0x3
    800048fc:	ca050513          	addi	a0,a0,-864 # 80007598 <etext+0x598>
    80004900:	ee1fb0ef          	jal	800007e0 <panic>
    return -1;
    80004904:	557d                	li	a0,-1
}
    80004906:	8082                	ret
      return -1;
    80004908:	557d                	li	a0,-1
    8000490a:	bfd9                	j	800048e0 <filewrite+0xf6>
    8000490c:	557d                	li	a0,-1
    8000490e:	bfc9                	j	800048e0 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004910:	557d                	li	a0,-1
    80004912:	79a2                	ld	s3,40(sp)
    80004914:	b7f1                	j	800048e0 <filewrite+0xf6>

0000000080004916 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004916:	7179                	addi	sp,sp,-48
    80004918:	f406                	sd	ra,40(sp)
    8000491a:	f022                	sd	s0,32(sp)
    8000491c:	ec26                	sd	s1,24(sp)
    8000491e:	e052                	sd	s4,0(sp)
    80004920:	1800                	addi	s0,sp,48
    80004922:	84aa                	mv	s1,a0
    80004924:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004926:	0005b023          	sd	zero,0(a1)
    8000492a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000492e:	c3bff0ef          	jal	80004568 <filealloc>
    80004932:	e088                	sd	a0,0(s1)
    80004934:	c549                	beqz	a0,800049be <pipealloc+0xa8>
    80004936:	c33ff0ef          	jal	80004568 <filealloc>
    8000493a:	00aa3023          	sd	a0,0(s4)
    8000493e:	cd25                	beqz	a0,800049b6 <pipealloc+0xa0>
    80004940:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004942:	9bcfc0ef          	jal	80000afe <kalloc>
    80004946:	892a                	mv	s2,a0
    80004948:	c12d                	beqz	a0,800049aa <pipealloc+0x94>
    8000494a:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    8000494c:	4985                	li	s3,1
    8000494e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004952:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004956:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000495a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000495e:	00003597          	auipc	a1,0x3
    80004962:	c4a58593          	addi	a1,a1,-950 # 800075a8 <etext+0x5a8>
    80004966:	9e8fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    8000496a:	609c                	ld	a5,0(s1)
    8000496c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004970:	609c                	ld	a5,0(s1)
    80004972:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004976:	609c                	ld	a5,0(s1)
    80004978:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000497c:	609c                	ld	a5,0(s1)
    8000497e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004982:	000a3783          	ld	a5,0(s4)
    80004986:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000498a:	000a3783          	ld	a5,0(s4)
    8000498e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a2:	4501                	li	a0,0
    800049a4:	6942                	ld	s2,16(sp)
    800049a6:	69a2                	ld	s3,8(sp)
    800049a8:	a01d                	j	800049ce <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049aa:	6088                	ld	a0,0(s1)
    800049ac:	c119                	beqz	a0,800049b2 <pipealloc+0x9c>
    800049ae:	6942                	ld	s2,16(sp)
    800049b0:	a029                	j	800049ba <pipealloc+0xa4>
    800049b2:	6942                	ld	s2,16(sp)
    800049b4:	a029                	j	800049be <pipealloc+0xa8>
    800049b6:	6088                	ld	a0,0(s1)
    800049b8:	c10d                	beqz	a0,800049da <pipealloc+0xc4>
    fileclose(*f0);
    800049ba:	c53ff0ef          	jal	8000460c <fileclose>
  if(*f1)
    800049be:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049c2:	557d                	li	a0,-1
  if(*f1)
    800049c4:	c789                	beqz	a5,800049ce <pipealloc+0xb8>
    fileclose(*f1);
    800049c6:	853e                	mv	a0,a5
    800049c8:	c45ff0ef          	jal	8000460c <fileclose>
  return -1;
    800049cc:	557d                	li	a0,-1
}
    800049ce:	70a2                	ld	ra,40(sp)
    800049d0:	7402                	ld	s0,32(sp)
    800049d2:	64e2                	ld	s1,24(sp)
    800049d4:	6a02                	ld	s4,0(sp)
    800049d6:	6145                	addi	sp,sp,48
    800049d8:	8082                	ret
  return -1;
    800049da:	557d                	li	a0,-1
    800049dc:	bfcd                	j	800049ce <pipealloc+0xb8>

00000000800049de <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049de:	1101                	addi	sp,sp,-32
    800049e0:	ec06                	sd	ra,24(sp)
    800049e2:	e822                	sd	s0,16(sp)
    800049e4:	e426                	sd	s1,8(sp)
    800049e6:	e04a                	sd	s2,0(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
    800049ec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049ee:	9e0fc0ef          	jal	80000bce <acquire>
  if(writable){
    800049f2:	02090763          	beqz	s2,80004a20 <pipeclose+0x42>
    pi->writeopen = 0;
    800049f6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049fa:	21848513          	addi	a0,s1,536
    800049fe:	ff0fd0ef          	jal	800021ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a02:	2204b783          	ld	a5,544(s1)
    80004a06:	e785                	bnez	a5,80004a2e <pipeclose+0x50>
    release(&pi->lock);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	a5cfc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    80004a0e:	8526                	mv	a0,s1
    80004a10:	80cfc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004a14:	60e2                	ld	ra,24(sp)
    80004a16:	6442                	ld	s0,16(sp)
    80004a18:	64a2                	ld	s1,8(sp)
    80004a1a:	6902                	ld	s2,0(sp)
    80004a1c:	6105                	addi	sp,sp,32
    80004a1e:	8082                	ret
    pi->readopen = 0;
    80004a20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a24:	21c48513          	addi	a0,s1,540
    80004a28:	fc6fd0ef          	jal	800021ee <wakeup>
    80004a2c:	bfd9                	j	80004a02 <pipeclose+0x24>
    release(&pi->lock);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	a36fc0ef          	jal	80000c66 <release>
}
    80004a34:	b7c5                	j	80004a14 <pipeclose+0x36>

0000000080004a36 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a36:	711d                	addi	sp,sp,-96
    80004a38:	ec86                	sd	ra,88(sp)
    80004a3a:	e8a2                	sd	s0,80(sp)
    80004a3c:	e4a6                	sd	s1,72(sp)
    80004a3e:	e0ca                	sd	s2,64(sp)
    80004a40:	fc4e                	sd	s3,56(sp)
    80004a42:	f852                	sd	s4,48(sp)
    80004a44:	f456                	sd	s5,40(sp)
    80004a46:	1080                	addi	s0,sp,96
    80004a48:	84aa                	mv	s1,a0
    80004a4a:	8aae                	mv	s5,a1
    80004a4c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a4e:	e81fc0ef          	jal	800018ce <myproc>
    80004a52:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a54:	8526                	mv	a0,s1
    80004a56:	978fc0ef          	jal	80000bce <acquire>
  while(i < n){
    80004a5a:	0b405a63          	blez	s4,80004b0e <pipewrite+0xd8>
    80004a5e:	f05a                	sd	s6,32(sp)
    80004a60:	ec5e                	sd	s7,24(sp)
    80004a62:	e862                	sd	s8,16(sp)
  int i = 0;
    80004a64:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a66:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a68:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6c:	21c48b93          	addi	s7,s1,540
    80004a70:	a81d                	j	80004aa6 <pipewrite+0x70>
      release(&pi->lock);
    80004a72:	8526                	mv	a0,s1
    80004a74:	9f2fc0ef          	jal	80000c66 <release>
      return -1;
    80004a78:	597d                	li	s2,-1
    80004a7a:	7b02                	ld	s6,32(sp)
    80004a7c:	6be2                	ld	s7,24(sp)
    80004a7e:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a80:	854a                	mv	a0,s2
    80004a82:	60e6                	ld	ra,88(sp)
    80004a84:	6446                	ld	s0,80(sp)
    80004a86:	64a6                	ld	s1,72(sp)
    80004a88:	6906                	ld	s2,64(sp)
    80004a8a:	79e2                	ld	s3,56(sp)
    80004a8c:	7a42                	ld	s4,48(sp)
    80004a8e:	7aa2                	ld	s5,40(sp)
    80004a90:	6125                	addi	sp,sp,96
    80004a92:	8082                	ret
      wakeup(&pi->nread);
    80004a94:	8562                	mv	a0,s8
    80004a96:	f58fd0ef          	jal	800021ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a9a:	85a6                	mv	a1,s1
    80004a9c:	855e                	mv	a0,s7
    80004a9e:	f00fd0ef          	jal	8000219e <sleep>
  while(i < n){
    80004aa2:	05495b63          	bge	s2,s4,80004af8 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    80004aa6:	2204a783          	lw	a5,544(s1)
    80004aaa:	d7e1                	beqz	a5,80004a72 <pipewrite+0x3c>
    80004aac:	854e                	mv	a0,s3
    80004aae:	92dfd0ef          	jal	800023da <killed>
    80004ab2:	f161                	bnez	a0,80004a72 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ab4:	2184a783          	lw	a5,536(s1)
    80004ab8:	21c4a703          	lw	a4,540(s1)
    80004abc:	2007879b          	addiw	a5,a5,512
    80004ac0:	fcf70ae3          	beq	a4,a5,80004a94 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ac4:	4685                	li	a3,1
    80004ac6:	01590633          	add	a2,s2,s5
    80004aca:	faf40593          	addi	a1,s0,-81
    80004ace:	0509b503          	ld	a0,80(s3)
    80004ad2:	bf5fc0ef          	jal	800016c6 <copyin>
    80004ad6:	03650e63          	beq	a0,s6,80004b12 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ada:	21c4a783          	lw	a5,540(s1)
    80004ade:	0017871b          	addiw	a4,a5,1
    80004ae2:	20e4ae23          	sw	a4,540(s1)
    80004ae6:	1ff7f793          	andi	a5,a5,511
    80004aea:	97a6                	add	a5,a5,s1
    80004aec:	faf44703          	lbu	a4,-81(s0)
    80004af0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af4:	2905                	addiw	s2,s2,1
    80004af6:	b775                	j	80004aa2 <pipewrite+0x6c>
    80004af8:	7b02                	ld	s6,32(sp)
    80004afa:	6be2                	ld	s7,24(sp)
    80004afc:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004afe:	21848513          	addi	a0,s1,536
    80004b02:	eecfd0ef          	jal	800021ee <wakeup>
  release(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	95efc0ef          	jal	80000c66 <release>
  return i;
    80004b0c:	bf95                	j	80004a80 <pipewrite+0x4a>
  int i = 0;
    80004b0e:	4901                	li	s2,0
    80004b10:	b7fd                	j	80004afe <pipewrite+0xc8>
    80004b12:	7b02                	ld	s6,32(sp)
    80004b14:	6be2                	ld	s7,24(sp)
    80004b16:	6c42                	ld	s8,16(sp)
    80004b18:	b7dd                	j	80004afe <pipewrite+0xc8>

0000000080004b1a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b1a:	715d                	addi	sp,sp,-80
    80004b1c:	e486                	sd	ra,72(sp)
    80004b1e:	e0a2                	sd	s0,64(sp)
    80004b20:	fc26                	sd	s1,56(sp)
    80004b22:	f84a                	sd	s2,48(sp)
    80004b24:	f44e                	sd	s3,40(sp)
    80004b26:	f052                	sd	s4,32(sp)
    80004b28:	ec56                	sd	s5,24(sp)
    80004b2a:	0880                	addi	s0,sp,80
    80004b2c:	84aa                	mv	s1,a0
    80004b2e:	892e                	mv	s2,a1
    80004b30:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b32:	d9dfc0ef          	jal	800018ce <myproc>
    80004b36:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	894fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3e:	2184a703          	lw	a4,536(s1)
    80004b42:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4a:	02f71563          	bne	a4,a5,80004b74 <piperead+0x5a>
    80004b4e:	2244a783          	lw	a5,548(s1)
    80004b52:	cb85                	beqz	a5,80004b82 <piperead+0x68>
    if(killed(pr)){
    80004b54:	8552                	mv	a0,s4
    80004b56:	885fd0ef          	jal	800023da <killed>
    80004b5a:	ed19                	bnez	a0,80004b78 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b5c:	85a6                	mv	a1,s1
    80004b5e:	854e                	mv	a0,s3
    80004b60:	e3efd0ef          	jal	8000219e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b64:	2184a703          	lw	a4,536(s1)
    80004b68:	21c4a783          	lw	a5,540(s1)
    80004b6c:	fef701e3          	beq	a4,a5,80004b4e <piperead+0x34>
    80004b70:	e85a                	sd	s6,16(sp)
    80004b72:	a809                	j	80004b84 <piperead+0x6a>
    80004b74:	e85a                	sd	s6,16(sp)
    80004b76:	a039                	j	80004b84 <piperead+0x6a>
      release(&pi->lock);
    80004b78:	8526                	mv	a0,s1
    80004b7a:	8ecfc0ef          	jal	80000c66 <release>
      return -1;
    80004b7e:	59fd                	li	s3,-1
    80004b80:	a8b9                	j	80004bde <piperead+0xc4>
    80004b82:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004b86:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b88:	05505363          	blez	s5,80004bce <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b8c:	2184a783          	lw	a5,536(s1)
    80004b90:	21c4a703          	lw	a4,540(s1)
    80004b94:	02f70d63          	beq	a4,a5,80004bce <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004b98:	1ff7f793          	andi	a5,a5,511
    80004b9c:	97a6                	add	a5,a5,s1
    80004b9e:	0187c783          	lbu	a5,24(a5)
    80004ba2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004ba6:	4685                	li	a3,1
    80004ba8:	fbf40613          	addi	a2,s0,-65
    80004bac:	85ca                	mv	a1,s2
    80004bae:	050a3503          	ld	a0,80(s4)
    80004bb2:	a31fc0ef          	jal	800015e2 <copyout>
    80004bb6:	03650e63          	beq	a0,s6,80004bf2 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004bba:	2184a783          	lw	a5,536(s1)
    80004bbe:	2785                	addiw	a5,a5,1
    80004bc0:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc4:	2985                	addiw	s3,s3,1
    80004bc6:	0905                	addi	s2,s2,1
    80004bc8:	fd3a92e3          	bne	s5,s3,80004b8c <piperead+0x72>
    80004bcc:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bce:	21c48513          	addi	a0,s1,540
    80004bd2:	e1cfd0ef          	jal	800021ee <wakeup>
  release(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	88efc0ef          	jal	80000c66 <release>
    80004bdc:	6b42                	ld	s6,16(sp)
  return i;
}
    80004bde:	854e                	mv	a0,s3
    80004be0:	60a6                	ld	ra,72(sp)
    80004be2:	6406                	ld	s0,64(sp)
    80004be4:	74e2                	ld	s1,56(sp)
    80004be6:	7942                	ld	s2,48(sp)
    80004be8:	79a2                	ld	s3,40(sp)
    80004bea:	7a02                	ld	s4,32(sp)
    80004bec:	6ae2                	ld	s5,24(sp)
    80004bee:	6161                	addi	sp,sp,80
    80004bf0:	8082                	ret
      if(i == 0)
    80004bf2:	fc099ee3          	bnez	s3,80004bce <piperead+0xb4>
        i = -1;
    80004bf6:	89aa                	mv	s3,a0
    80004bf8:	bfd9                	j	80004bce <piperead+0xb4>

0000000080004bfa <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004bfa:	1141                	addi	sp,sp,-16
    80004bfc:	e422                	sd	s0,8(sp)
    80004bfe:	0800                	addi	s0,sp,16
    80004c00:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c02:	8905                	andi	a0,a0,1
    80004c04:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c06:	8b89                	andi	a5,a5,2
    80004c08:	c399                	beqz	a5,80004c0e <flags2perm+0x14>
      perm |= PTE_W;
    80004c0a:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c0e:	6422                	ld	s0,8(sp)
    80004c10:	0141                	addi	sp,sp,16
    80004c12:	8082                	ret

0000000080004c14 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004c14:	df010113          	addi	sp,sp,-528
    80004c18:	20113423          	sd	ra,520(sp)
    80004c1c:	20813023          	sd	s0,512(sp)
    80004c20:	ffa6                	sd	s1,504(sp)
    80004c22:	fbca                	sd	s2,496(sp)
    80004c24:	0c00                	addi	s0,sp,528
    80004c26:	892a                	mv	s2,a0
    80004c28:	dea43c23          	sd	a0,-520(s0)
    80004c2c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c30:	c9ffc0ef          	jal	800018ce <myproc>
    80004c34:	84aa                	mv	s1,a0

  begin_op();
    80004c36:	dcaff0ef          	jal	80004200 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	bf0ff0ef          	jal	8000402c <namei>
    80004c40:	c931                	beqz	a0,80004c94 <kexec+0x80>
    80004c42:	f3d2                	sd	s4,480(sp)
    80004c44:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c46:	bd1fe0ef          	jal	80003816 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c4a:	04000713          	li	a4,64
    80004c4e:	4681                	li	a3,0
    80004c50:	e5040613          	addi	a2,s0,-432
    80004c54:	4581                	li	a1,0
    80004c56:	8552                	mv	a0,s4
    80004c58:	f4ffe0ef          	jal	80003ba6 <readi>
    80004c5c:	04000793          	li	a5,64
    80004c60:	00f51a63          	bne	a0,a5,80004c74 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004c64:	e5042703          	lw	a4,-432(s0)
    80004c68:	464c47b7          	lui	a5,0x464c4
    80004c6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c70:	02f70663          	beq	a4,a5,80004c9c <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c74:	8552                	mv	a0,s4
    80004c76:	dabfe0ef          	jal	80003a20 <iunlockput>
    end_op();
    80004c7a:	df0ff0ef          	jal	8000426a <end_op>
  }
  return -1;
    80004c7e:	557d                	li	a0,-1
    80004c80:	7a1e                	ld	s4,480(sp)
}
    80004c82:	20813083          	ld	ra,520(sp)
    80004c86:	20013403          	ld	s0,512(sp)
    80004c8a:	74fe                	ld	s1,504(sp)
    80004c8c:	795e                	ld	s2,496(sp)
    80004c8e:	21010113          	addi	sp,sp,528
    80004c92:	8082                	ret
    end_op();
    80004c94:	dd6ff0ef          	jal	8000426a <end_op>
    return -1;
    80004c98:	557d                	li	a0,-1
    80004c9a:	b7e5                	j	80004c82 <kexec+0x6e>
    80004c9c:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	d35fc0ef          	jal	800019d4 <proc_pagetable>
    80004ca4:	8b2a                	mv	s6,a0
    80004ca6:	2c050b63          	beqz	a0,80004f7c <kexec+0x368>
    80004caa:	f7ce                	sd	s3,488(sp)
    80004cac:	efd6                	sd	s5,472(sp)
    80004cae:	e7de                	sd	s7,456(sp)
    80004cb0:	e3e2                	sd	s8,448(sp)
    80004cb2:	ff66                	sd	s9,440(sp)
    80004cb4:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cb6:	e7042d03          	lw	s10,-400(s0)
    80004cba:	e8845783          	lhu	a5,-376(s0)
    80004cbe:	12078963          	beqz	a5,80004df0 <kexec+0x1dc>
    80004cc2:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cc4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc6:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cc8:	6c85                	lui	s9,0x1
    80004cca:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cce:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004cd2:	6a85                	lui	s5,0x1
    80004cd4:	a085                	j	80004d34 <kexec+0x120>
      panic("loadseg: address should exist");
    80004cd6:	00003517          	auipc	a0,0x3
    80004cda:	8da50513          	addi	a0,a0,-1830 # 800075b0 <etext+0x5b0>
    80004cde:	b03fb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004ce2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ce4:	8726                	mv	a4,s1
    80004ce6:	012c06bb          	addw	a3,s8,s2
    80004cea:	4581                	li	a1,0
    80004cec:	8552                	mv	a0,s4
    80004cee:	eb9fe0ef          	jal	80003ba6 <readi>
    80004cf2:	2501                	sext.w	a0,a0
    80004cf4:	24a49a63          	bne	s1,a0,80004f48 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004cf8:	012a893b          	addw	s2,s5,s2
    80004cfc:	03397363          	bgeu	s2,s3,80004d22 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004d00:	02091593          	slli	a1,s2,0x20
    80004d04:	9181                	srli	a1,a1,0x20
    80004d06:	95de                	add	a1,a1,s7
    80004d08:	855a                	mv	a0,s6
    80004d0a:	aa6fc0ef          	jal	80000fb0 <walkaddr>
    80004d0e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d10:	d179                	beqz	a0,80004cd6 <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004d12:	412984bb          	subw	s1,s3,s2
    80004d16:	0004879b          	sext.w	a5,s1
    80004d1a:	fcfcf4e3          	bgeu	s9,a5,80004ce2 <kexec+0xce>
    80004d1e:	84d6                	mv	s1,s5
    80004d20:	b7c9                	j	80004ce2 <kexec+0xce>
    sz = sz1;
    80004d22:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d26:	2d85                	addiw	s11,s11,1
    80004d28:	038d0d1b          	addiw	s10,s10,56
    80004d2c:	e8845783          	lhu	a5,-376(s0)
    80004d30:	08fdd063          	bge	s11,a5,80004db0 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d34:	2d01                	sext.w	s10,s10
    80004d36:	03800713          	li	a4,56
    80004d3a:	86ea                	mv	a3,s10
    80004d3c:	e1840613          	addi	a2,s0,-488
    80004d40:	4581                	li	a1,0
    80004d42:	8552                	mv	a0,s4
    80004d44:	e63fe0ef          	jal	80003ba6 <readi>
    80004d48:	03800793          	li	a5,56
    80004d4c:	1cf51663          	bne	a0,a5,80004f18 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004d50:	e1842783          	lw	a5,-488(s0)
    80004d54:	4705                	li	a4,1
    80004d56:	fce798e3          	bne	a5,a4,80004d26 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004d5a:	e4043483          	ld	s1,-448(s0)
    80004d5e:	e3843783          	ld	a5,-456(s0)
    80004d62:	1af4ef63          	bltu	s1,a5,80004f20 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004d66:	e2843783          	ld	a5,-472(s0)
    80004d6a:	94be                	add	s1,s1,a5
    80004d6c:	1af4ee63          	bltu	s1,a5,80004f28 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004d70:	df043703          	ld	a4,-528(s0)
    80004d74:	8ff9                	and	a5,a5,a4
    80004d76:	1a079d63          	bnez	a5,80004f30 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d7a:	e1c42503          	lw	a0,-484(s0)
    80004d7e:	e7dff0ef          	jal	80004bfa <flags2perm>
    80004d82:	86aa                	mv	a3,a0
    80004d84:	8626                	mv	a2,s1
    80004d86:	85ca                	mv	a1,s2
    80004d88:	855a                	mv	a0,s6
    80004d8a:	cfefc0ef          	jal	80001288 <uvmalloc>
    80004d8e:	e0a43423          	sd	a0,-504(s0)
    80004d92:	1a050363          	beqz	a0,80004f38 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004d96:	e2843b83          	ld	s7,-472(s0)
    80004d9a:	e2042c03          	lw	s8,-480(s0)
    80004d9e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004da2:	00098463          	beqz	s3,80004daa <kexec+0x196>
    80004da6:	4901                	li	s2,0
    80004da8:	bfa1                	j	80004d00 <kexec+0xec>
    sz = sz1;
    80004daa:	e0843903          	ld	s2,-504(s0)
    80004dae:	bfa5                	j	80004d26 <kexec+0x112>
    80004db0:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004db2:	8552                	mv	a0,s4
    80004db4:	c6dfe0ef          	jal	80003a20 <iunlockput>
  end_op();
    80004db8:	cb2ff0ef          	jal	8000426a <end_op>
  p = myproc();
    80004dbc:	b13fc0ef          	jal	800018ce <myproc>
    80004dc0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dc2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004dc6:	6985                	lui	s3,0x1
    80004dc8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004dca:	99ca                	add	s3,s3,s2
    80004dcc:	77fd                	lui	a5,0xfffff
    80004dce:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004dd2:	4691                	li	a3,4
    80004dd4:	6609                	lui	a2,0x2
    80004dd6:	964e                	add	a2,a2,s3
    80004dd8:	85ce                	mv	a1,s3
    80004dda:	855a                	mv	a0,s6
    80004ddc:	cacfc0ef          	jal	80001288 <uvmalloc>
    80004de0:	892a                	mv	s2,a0
    80004de2:	e0a43423          	sd	a0,-504(s0)
    80004de6:	e519                	bnez	a0,80004df4 <kexec+0x1e0>
  if(pagetable)
    80004de8:	e1343423          	sd	s3,-504(s0)
    80004dec:	4a01                	li	s4,0
    80004dee:	aab1                	j	80004f4a <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df0:	4901                	li	s2,0
    80004df2:	b7c1                	j	80004db2 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004df4:	75f9                	lui	a1,0xffffe
    80004df6:	95aa                	add	a1,a1,a0
    80004df8:	855a                	mv	a0,s6
    80004dfa:	e64fc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004dfe:	7bfd                	lui	s7,0xfffff
    80004e00:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e02:	e0043783          	ld	a5,-512(s0)
    80004e06:	6388                	ld	a0,0(a5)
    80004e08:	cd39                	beqz	a0,80004e66 <kexec+0x252>
    80004e0a:	e9040993          	addi	s3,s0,-368
    80004e0e:	f9040c13          	addi	s8,s0,-112
    80004e12:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e14:	ffffb0ef          	jal	80000e12 <strlen>
    80004e18:	0015079b          	addiw	a5,a0,1
    80004e1c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e20:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e24:	11796e63          	bltu	s2,s7,80004f40 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e28:	e0043d03          	ld	s10,-512(s0)
    80004e2c:	000d3a03          	ld	s4,0(s10)
    80004e30:	8552                	mv	a0,s4
    80004e32:	fe1fb0ef          	jal	80000e12 <strlen>
    80004e36:	0015069b          	addiw	a3,a0,1
    80004e3a:	8652                	mv	a2,s4
    80004e3c:	85ca                	mv	a1,s2
    80004e3e:	855a                	mv	a0,s6
    80004e40:	fa2fc0ef          	jal	800015e2 <copyout>
    80004e44:	10054063          	bltz	a0,80004f44 <kexec+0x330>
    ustack[argc] = sp;
    80004e48:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e4c:	0485                	addi	s1,s1,1
    80004e4e:	008d0793          	addi	a5,s10,8
    80004e52:	e0f43023          	sd	a5,-512(s0)
    80004e56:	008d3503          	ld	a0,8(s10)
    80004e5a:	c909                	beqz	a0,80004e6c <kexec+0x258>
    if(argc >= MAXARG)
    80004e5c:	09a1                	addi	s3,s3,8
    80004e5e:	fb899be3          	bne	s3,s8,80004e14 <kexec+0x200>
  ip = 0;
    80004e62:	4a01                	li	s4,0
    80004e64:	a0dd                	j	80004f4a <kexec+0x336>
  sp = sz;
    80004e66:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e6c:	00349793          	slli	a5,s1,0x3
    80004e70:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcbf8>
    80004e74:	97a2                	add	a5,a5,s0
    80004e76:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e7a:	00148693          	addi	a3,s1,1
    80004e7e:	068e                	slli	a3,a3,0x3
    80004e80:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e84:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004e88:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004e8c:	f5796ee3          	bltu	s2,s7,80004de8 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e90:	e9040613          	addi	a2,s0,-368
    80004e94:	85ca                	mv	a1,s2
    80004e96:	855a                	mv	a0,s6
    80004e98:	f4afc0ef          	jal	800015e2 <copyout>
    80004e9c:	0e054263          	bltz	a0,80004f80 <kexec+0x36c>
  p->trapframe->a1 = sp;
    80004ea0:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004ea4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ea8:	df843783          	ld	a5,-520(s0)
    80004eac:	0007c703          	lbu	a4,0(a5)
    80004eb0:	cf11                	beqz	a4,80004ecc <kexec+0x2b8>
    80004eb2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb4:	02f00693          	li	a3,47
    80004eb8:	a039                	j	80004ec6 <kexec+0x2b2>
      last = s+1;
    80004eba:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ebe:	0785                	addi	a5,a5,1
    80004ec0:	fff7c703          	lbu	a4,-1(a5)
    80004ec4:	c701                	beqz	a4,80004ecc <kexec+0x2b8>
    if(*s == '/')
    80004ec6:	fed71ce3          	bne	a4,a3,80004ebe <kexec+0x2aa>
    80004eca:	bfc5                	j	80004eba <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ecc:	4641                	li	a2,16
    80004ece:	df843583          	ld	a1,-520(s0)
    80004ed2:	158a8513          	addi	a0,s5,344
    80004ed6:	f0bfb0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eda:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ede:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004ee2:	e0843783          	ld	a5,-504(s0)
    80004ee6:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004eea:	058ab783          	ld	a5,88(s5)
    80004eee:	e6843703          	ld	a4,-408(s0)
    80004ef2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef4:	058ab783          	ld	a5,88(s5)
    80004ef8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004efc:	85e6                	mv	a1,s9
    80004efe:	b5bfc0ef          	jal	80001a58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f02:	0004851b          	sext.w	a0,s1
    80004f06:	79be                	ld	s3,488(sp)
    80004f08:	7a1e                	ld	s4,480(sp)
    80004f0a:	6afe                	ld	s5,472(sp)
    80004f0c:	6b5e                	ld	s6,464(sp)
    80004f0e:	6bbe                	ld	s7,456(sp)
    80004f10:	6c1e                	ld	s8,448(sp)
    80004f12:	7cfa                	ld	s9,440(sp)
    80004f14:	7d5a                	ld	s10,432(sp)
    80004f16:	b3b5                	j	80004c82 <kexec+0x6e>
    80004f18:	e1243423          	sd	s2,-504(s0)
    80004f1c:	7dba                	ld	s11,424(sp)
    80004f1e:	a035                	j	80004f4a <kexec+0x336>
    80004f20:	e1243423          	sd	s2,-504(s0)
    80004f24:	7dba                	ld	s11,424(sp)
    80004f26:	a015                	j	80004f4a <kexec+0x336>
    80004f28:	e1243423          	sd	s2,-504(s0)
    80004f2c:	7dba                	ld	s11,424(sp)
    80004f2e:	a831                	j	80004f4a <kexec+0x336>
    80004f30:	e1243423          	sd	s2,-504(s0)
    80004f34:	7dba                	ld	s11,424(sp)
    80004f36:	a811                	j	80004f4a <kexec+0x336>
    80004f38:	e1243423          	sd	s2,-504(s0)
    80004f3c:	7dba                	ld	s11,424(sp)
    80004f3e:	a031                	j	80004f4a <kexec+0x336>
  ip = 0;
    80004f40:	4a01                	li	s4,0
    80004f42:	a021                	j	80004f4a <kexec+0x336>
    80004f44:	4a01                	li	s4,0
  if(pagetable)
    80004f46:	a011                	j	80004f4a <kexec+0x336>
    80004f48:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004f4a:	e0843583          	ld	a1,-504(s0)
    80004f4e:	855a                	mv	a0,s6
    80004f50:	b09fc0ef          	jal	80001a58 <proc_freepagetable>
  return -1;
    80004f54:	557d                	li	a0,-1
  if(ip){
    80004f56:	000a1b63          	bnez	s4,80004f6c <kexec+0x358>
    80004f5a:	79be                	ld	s3,488(sp)
    80004f5c:	7a1e                	ld	s4,480(sp)
    80004f5e:	6afe                	ld	s5,472(sp)
    80004f60:	6b5e                	ld	s6,464(sp)
    80004f62:	6bbe                	ld	s7,456(sp)
    80004f64:	6c1e                	ld	s8,448(sp)
    80004f66:	7cfa                	ld	s9,440(sp)
    80004f68:	7d5a                	ld	s10,432(sp)
    80004f6a:	bb21                	j	80004c82 <kexec+0x6e>
    80004f6c:	79be                	ld	s3,488(sp)
    80004f6e:	6afe                	ld	s5,472(sp)
    80004f70:	6b5e                	ld	s6,464(sp)
    80004f72:	6bbe                	ld	s7,456(sp)
    80004f74:	6c1e                	ld	s8,448(sp)
    80004f76:	7cfa                	ld	s9,440(sp)
    80004f78:	7d5a                	ld	s10,432(sp)
    80004f7a:	b9ed                	j	80004c74 <kexec+0x60>
    80004f7c:	6b5e                	ld	s6,464(sp)
    80004f7e:	b9dd                	j	80004c74 <kexec+0x60>
  sz = sz1;
    80004f80:	e0843983          	ld	s3,-504(s0)
    80004f84:	b595                	j	80004de8 <kexec+0x1d4>

0000000080004f86 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f86:	7179                	addi	sp,sp,-48
    80004f88:	f406                	sd	ra,40(sp)
    80004f8a:	f022                	sd	s0,32(sp)
    80004f8c:	ec26                	sd	s1,24(sp)
    80004f8e:	e84a                	sd	s2,16(sp)
    80004f90:	1800                	addi	s0,sp,48
    80004f92:	892e                	mv	s2,a1
    80004f94:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f96:	fdc40593          	addi	a1,s0,-36
    80004f9a:	d51fd0ef          	jal	80002cea <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f9e:	fdc42703          	lw	a4,-36(s0)
    80004fa2:	47bd                	li	a5,15
    80004fa4:	02e7e963          	bltu	a5,a4,80004fd6 <argfd+0x50>
    80004fa8:	927fc0ef          	jal	800018ce <myproc>
    80004fac:	fdc42703          	lw	a4,-36(s0)
    80004fb0:	01a70793          	addi	a5,a4,26
    80004fb4:	078e                	slli	a5,a5,0x3
    80004fb6:	953e                	add	a0,a0,a5
    80004fb8:	611c                	ld	a5,0(a0)
    80004fba:	c385                	beqz	a5,80004fda <argfd+0x54>
    return -1;
  if(pfd)
    80004fbc:	00090463          	beqz	s2,80004fc4 <argfd+0x3e>
    *pfd = fd;
    80004fc0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fc4:	4501                	li	a0,0
  if(pf)
    80004fc6:	c091                	beqz	s1,80004fca <argfd+0x44>
    *pf = f;
    80004fc8:	e09c                	sd	a5,0(s1)
}
    80004fca:	70a2                	ld	ra,40(sp)
    80004fcc:	7402                	ld	s0,32(sp)
    80004fce:	64e2                	ld	s1,24(sp)
    80004fd0:	6942                	ld	s2,16(sp)
    80004fd2:	6145                	addi	sp,sp,48
    80004fd4:	8082                	ret
    return -1;
    80004fd6:	557d                	li	a0,-1
    80004fd8:	bfcd                	j	80004fca <argfd+0x44>
    80004fda:	557d                	li	a0,-1
    80004fdc:	b7fd                	j	80004fca <argfd+0x44>

0000000080004fde <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fde:	1101                	addi	sp,sp,-32
    80004fe0:	ec06                	sd	ra,24(sp)
    80004fe2:	e822                	sd	s0,16(sp)
    80004fe4:	e426                	sd	s1,8(sp)
    80004fe6:	1000                	addi	s0,sp,32
    80004fe8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fea:	8e5fc0ef          	jal	800018ce <myproc>
    80004fee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ff0:	0d050793          	addi	a5,a0,208
    80004ff4:	4501                	li	a0,0
    80004ff6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ff8:	6398                	ld	a4,0(a5)
    80004ffa:	cb19                	beqz	a4,80005010 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004ffc:	2505                	addiw	a0,a0,1
    80004ffe:	07a1                	addi	a5,a5,8
    80005000:	fed51ce3          	bne	a0,a3,80004ff8 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005004:	557d                	li	a0,-1
}
    80005006:	60e2                	ld	ra,24(sp)
    80005008:	6442                	ld	s0,16(sp)
    8000500a:	64a2                	ld	s1,8(sp)
    8000500c:	6105                	addi	sp,sp,32
    8000500e:	8082                	ret
      p->ofile[fd] = f;
    80005010:	01a50793          	addi	a5,a0,26
    80005014:	078e                	slli	a5,a5,0x3
    80005016:	963e                	add	a2,a2,a5
    80005018:	e204                	sd	s1,0(a2)
      return fd;
    8000501a:	b7f5                	j	80005006 <fdalloc+0x28>

000000008000501c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000501c:	715d                	addi	sp,sp,-80
    8000501e:	e486                	sd	ra,72(sp)
    80005020:	e0a2                	sd	s0,64(sp)
    80005022:	fc26                	sd	s1,56(sp)
    80005024:	f84a                	sd	s2,48(sp)
    80005026:	f44e                	sd	s3,40(sp)
    80005028:	ec56                	sd	s5,24(sp)
    8000502a:	e85a                	sd	s6,16(sp)
    8000502c:	0880                	addi	s0,sp,80
    8000502e:	8b2e                	mv	s6,a1
    80005030:	89b2                	mv	s3,a2
    80005032:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005034:	fb040593          	addi	a1,s0,-80
    80005038:	80eff0ef          	jal	80004046 <nameiparent>
    8000503c:	84aa                	mv	s1,a0
    8000503e:	10050a63          	beqz	a0,80005152 <create+0x136>
    return 0;

  ilock(dp);
    80005042:	fd4fe0ef          	jal	80003816 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005046:	4601                	li	a2,0
    80005048:	fb040593          	addi	a1,s0,-80
    8000504c:	8526                	mv	a0,s1
    8000504e:	d79fe0ef          	jal	80003dc6 <dirlookup>
    80005052:	8aaa                	mv	s5,a0
    80005054:	c129                	beqz	a0,80005096 <create+0x7a>
    iunlockput(dp);
    80005056:	8526                	mv	a0,s1
    80005058:	9c9fe0ef          	jal	80003a20 <iunlockput>
    ilock(ip);
    8000505c:	8556                	mv	a0,s5
    8000505e:	fb8fe0ef          	jal	80003816 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005062:	4789                	li	a5,2
    80005064:	02fb1463          	bne	s6,a5,8000508c <create+0x70>
    80005068:	044ad783          	lhu	a5,68(s5)
    8000506c:	37f9                	addiw	a5,a5,-2
    8000506e:	17c2                	slli	a5,a5,0x30
    80005070:	93c1                	srli	a5,a5,0x30
    80005072:	4705                	li	a4,1
    80005074:	00f76c63          	bltu	a4,a5,8000508c <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005078:	8556                	mv	a0,s5
    8000507a:	60a6                	ld	ra,72(sp)
    8000507c:	6406                	ld	s0,64(sp)
    8000507e:	74e2                	ld	s1,56(sp)
    80005080:	7942                	ld	s2,48(sp)
    80005082:	79a2                	ld	s3,40(sp)
    80005084:	6ae2                	ld	s5,24(sp)
    80005086:	6b42                	ld	s6,16(sp)
    80005088:	6161                	addi	sp,sp,80
    8000508a:	8082                	ret
    iunlockput(ip);
    8000508c:	8556                	mv	a0,s5
    8000508e:	993fe0ef          	jal	80003a20 <iunlockput>
    return 0;
    80005092:	4a81                	li	s5,0
    80005094:	b7d5                	j	80005078 <create+0x5c>
    80005096:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005098:	85da                	mv	a1,s6
    8000509a:	4088                	lw	a0,0(s1)
    8000509c:	e0afe0ef          	jal	800036a6 <ialloc>
    800050a0:	8a2a                	mv	s4,a0
    800050a2:	cd15                	beqz	a0,800050de <create+0xc2>
  ilock(ip);
    800050a4:	f72fe0ef          	jal	80003816 <ilock>
  ip->major = major;
    800050a8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050ac:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050b0:	4905                	li	s2,1
    800050b2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050b6:	8552                	mv	a0,s4
    800050b8:	eaafe0ef          	jal	80003762 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050bc:	032b0763          	beq	s6,s2,800050ea <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    800050c0:	004a2603          	lw	a2,4(s4)
    800050c4:	fb040593          	addi	a1,s0,-80
    800050c8:	8526                	mv	a0,s1
    800050ca:	ec9fe0ef          	jal	80003f92 <dirlink>
    800050ce:	06054563          	bltz	a0,80005138 <create+0x11c>
  iunlockput(dp);
    800050d2:	8526                	mv	a0,s1
    800050d4:	94dfe0ef          	jal	80003a20 <iunlockput>
  return ip;
    800050d8:	8ad2                	mv	s5,s4
    800050da:	7a02                	ld	s4,32(sp)
    800050dc:	bf71                	j	80005078 <create+0x5c>
    iunlockput(dp);
    800050de:	8526                	mv	a0,s1
    800050e0:	941fe0ef          	jal	80003a20 <iunlockput>
    return 0;
    800050e4:	8ad2                	mv	s5,s4
    800050e6:	7a02                	ld	s4,32(sp)
    800050e8:	bf41                	j	80005078 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050ea:	004a2603          	lw	a2,4(s4)
    800050ee:	00002597          	auipc	a1,0x2
    800050f2:	4e258593          	addi	a1,a1,1250 # 800075d0 <etext+0x5d0>
    800050f6:	8552                	mv	a0,s4
    800050f8:	e9bfe0ef          	jal	80003f92 <dirlink>
    800050fc:	02054e63          	bltz	a0,80005138 <create+0x11c>
    80005100:	40d0                	lw	a2,4(s1)
    80005102:	00002597          	auipc	a1,0x2
    80005106:	4d658593          	addi	a1,a1,1238 # 800075d8 <etext+0x5d8>
    8000510a:	8552                	mv	a0,s4
    8000510c:	e87fe0ef          	jal	80003f92 <dirlink>
    80005110:	02054463          	bltz	a0,80005138 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005114:	004a2603          	lw	a2,4(s4)
    80005118:	fb040593          	addi	a1,s0,-80
    8000511c:	8526                	mv	a0,s1
    8000511e:	e75fe0ef          	jal	80003f92 <dirlink>
    80005122:	00054b63          	bltz	a0,80005138 <create+0x11c>
    dp->nlink++;  // for ".."
    80005126:	04a4d783          	lhu	a5,74(s1)
    8000512a:	2785                	addiw	a5,a5,1
    8000512c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005130:	8526                	mv	a0,s1
    80005132:	e30fe0ef          	jal	80003762 <iupdate>
    80005136:	bf71                	j	800050d2 <create+0xb6>
  ip->nlink = 0;
    80005138:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000513c:	8552                	mv	a0,s4
    8000513e:	e24fe0ef          	jal	80003762 <iupdate>
  iunlockput(ip);
    80005142:	8552                	mv	a0,s4
    80005144:	8ddfe0ef          	jal	80003a20 <iunlockput>
  iunlockput(dp);
    80005148:	8526                	mv	a0,s1
    8000514a:	8d7fe0ef          	jal	80003a20 <iunlockput>
  return 0;
    8000514e:	7a02                	ld	s4,32(sp)
    80005150:	b725                	j	80005078 <create+0x5c>
    return 0;
    80005152:	8aaa                	mv	s5,a0
    80005154:	b715                	j	80005078 <create+0x5c>

0000000080005156 <sys_dup>:
{
    80005156:	7179                	addi	sp,sp,-48
    80005158:	f406                	sd	ra,40(sp)
    8000515a:	f022                	sd	s0,32(sp)
    8000515c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000515e:	fd840613          	addi	a2,s0,-40
    80005162:	4581                	li	a1,0
    80005164:	4501                	li	a0,0
    80005166:	e21ff0ef          	jal	80004f86 <argfd>
    return -1;
    8000516a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000516c:	02054363          	bltz	a0,80005192 <sys_dup+0x3c>
    80005170:	ec26                	sd	s1,24(sp)
    80005172:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005174:	fd843903          	ld	s2,-40(s0)
    80005178:	854a                	mv	a0,s2
    8000517a:	e65ff0ef          	jal	80004fde <fdalloc>
    8000517e:	84aa                	mv	s1,a0
    return -1;
    80005180:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005182:	00054d63          	bltz	a0,8000519c <sys_dup+0x46>
  filedup(f);
    80005186:	854a                	mv	a0,s2
    80005188:	c3eff0ef          	jal	800045c6 <filedup>
  return fd;
    8000518c:	87a6                	mv	a5,s1
    8000518e:	64e2                	ld	s1,24(sp)
    80005190:	6942                	ld	s2,16(sp)
}
    80005192:	853e                	mv	a0,a5
    80005194:	70a2                	ld	ra,40(sp)
    80005196:	7402                	ld	s0,32(sp)
    80005198:	6145                	addi	sp,sp,48
    8000519a:	8082                	ret
    8000519c:	64e2                	ld	s1,24(sp)
    8000519e:	6942                	ld	s2,16(sp)
    800051a0:	bfcd                	j	80005192 <sys_dup+0x3c>

00000000800051a2 <sys_read>:
{
    800051a2:	7179                	addi	sp,sp,-48
    800051a4:	f406                	sd	ra,40(sp)
    800051a6:	f022                	sd	s0,32(sp)
    800051a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051aa:	fd840593          	addi	a1,s0,-40
    800051ae:	4505                	li	a0,1
    800051b0:	b57fd0ef          	jal	80002d06 <argaddr>
  argint(2, &n);
    800051b4:	fe440593          	addi	a1,s0,-28
    800051b8:	4509                	li	a0,2
    800051ba:	b31fd0ef          	jal	80002cea <argint>
  if(argfd(0, 0, &f) < 0)
    800051be:	fe840613          	addi	a2,s0,-24
    800051c2:	4581                	li	a1,0
    800051c4:	4501                	li	a0,0
    800051c6:	dc1ff0ef          	jal	80004f86 <argfd>
    800051ca:	87aa                	mv	a5,a0
    return -1;
    800051cc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051ce:	0007ca63          	bltz	a5,800051e2 <sys_read+0x40>
  return fileread(f, p, n);
    800051d2:	fe442603          	lw	a2,-28(s0)
    800051d6:	fd843583          	ld	a1,-40(s0)
    800051da:	fe843503          	ld	a0,-24(s0)
    800051de:	d4eff0ef          	jal	8000472c <fileread>
}
    800051e2:	70a2                	ld	ra,40(sp)
    800051e4:	7402                	ld	s0,32(sp)
    800051e6:	6145                	addi	sp,sp,48
    800051e8:	8082                	ret

00000000800051ea <sys_write>:
{
    800051ea:	7179                	addi	sp,sp,-48
    800051ec:	f406                	sd	ra,40(sp)
    800051ee:	f022                	sd	s0,32(sp)
    800051f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051f2:	fd840593          	addi	a1,s0,-40
    800051f6:	4505                	li	a0,1
    800051f8:	b0ffd0ef          	jal	80002d06 <argaddr>
  argint(2, &n);
    800051fc:	fe440593          	addi	a1,s0,-28
    80005200:	4509                	li	a0,2
    80005202:	ae9fd0ef          	jal	80002cea <argint>
  if(argfd(0, 0, &f) < 0)
    80005206:	fe840613          	addi	a2,s0,-24
    8000520a:	4581                	li	a1,0
    8000520c:	4501                	li	a0,0
    8000520e:	d79ff0ef          	jal	80004f86 <argfd>
    80005212:	87aa                	mv	a5,a0
    return -1;
    80005214:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005216:	0007ca63          	bltz	a5,8000522a <sys_write+0x40>
  return filewrite(f, p, n);
    8000521a:	fe442603          	lw	a2,-28(s0)
    8000521e:	fd843583          	ld	a1,-40(s0)
    80005222:	fe843503          	ld	a0,-24(s0)
    80005226:	dc4ff0ef          	jal	800047ea <filewrite>
}
    8000522a:	70a2                	ld	ra,40(sp)
    8000522c:	7402                	ld	s0,32(sp)
    8000522e:	6145                	addi	sp,sp,48
    80005230:	8082                	ret

0000000080005232 <sys_close>:
{
    80005232:	1101                	addi	sp,sp,-32
    80005234:	ec06                	sd	ra,24(sp)
    80005236:	e822                	sd	s0,16(sp)
    80005238:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000523a:	fe040613          	addi	a2,s0,-32
    8000523e:	fec40593          	addi	a1,s0,-20
    80005242:	4501                	li	a0,0
    80005244:	d43ff0ef          	jal	80004f86 <argfd>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000524a:	02054063          	bltz	a0,8000526a <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    8000524e:	e80fc0ef          	jal	800018ce <myproc>
    80005252:	fec42783          	lw	a5,-20(s0)
    80005256:	07e9                	addi	a5,a5,26
    80005258:	078e                	slli	a5,a5,0x3
    8000525a:	953e                	add	a0,a0,a5
    8000525c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005260:	fe043503          	ld	a0,-32(s0)
    80005264:	ba8ff0ef          	jal	8000460c <fileclose>
  return 0;
    80005268:	4781                	li	a5,0
}
    8000526a:	853e                	mv	a0,a5
    8000526c:	60e2                	ld	ra,24(sp)
    8000526e:	6442                	ld	s0,16(sp)
    80005270:	6105                	addi	sp,sp,32
    80005272:	8082                	ret

0000000080005274 <sys_fstat>:
{
    80005274:	1101                	addi	sp,sp,-32
    80005276:	ec06                	sd	ra,24(sp)
    80005278:	e822                	sd	s0,16(sp)
    8000527a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000527c:	fe040593          	addi	a1,s0,-32
    80005280:	4505                	li	a0,1
    80005282:	a85fd0ef          	jal	80002d06 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005286:	fe840613          	addi	a2,s0,-24
    8000528a:	4581                	li	a1,0
    8000528c:	4501                	li	a0,0
    8000528e:	cf9ff0ef          	jal	80004f86 <argfd>
    80005292:	87aa                	mv	a5,a0
    return -1;
    80005294:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005296:	0007c863          	bltz	a5,800052a6 <sys_fstat+0x32>
  return filestat(f, st);
    8000529a:	fe043583          	ld	a1,-32(s0)
    8000529e:	fe843503          	ld	a0,-24(s0)
    800052a2:	c2cff0ef          	jal	800046ce <filestat>
}
    800052a6:	60e2                	ld	ra,24(sp)
    800052a8:	6442                	ld	s0,16(sp)
    800052aa:	6105                	addi	sp,sp,32
    800052ac:	8082                	ret

00000000800052ae <sys_link>:
{
    800052ae:	7169                	addi	sp,sp,-304
    800052b0:	f606                	sd	ra,296(sp)
    800052b2:	f222                	sd	s0,288(sp)
    800052b4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b6:	08000613          	li	a2,128
    800052ba:	ed040593          	addi	a1,s0,-304
    800052be:	4501                	li	a0,0
    800052c0:	a77fd0ef          	jal	80002d36 <argstr>
    return -1;
    800052c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052c6:	0c054e63          	bltz	a0,800053a2 <sys_link+0xf4>
    800052ca:	08000613          	li	a2,128
    800052ce:	f5040593          	addi	a1,s0,-176
    800052d2:	4505                	li	a0,1
    800052d4:	a63fd0ef          	jal	80002d36 <argstr>
    return -1;
    800052d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052da:	0c054463          	bltz	a0,800053a2 <sys_link+0xf4>
    800052de:	ee26                	sd	s1,280(sp)
  begin_op();
    800052e0:	f21fe0ef          	jal	80004200 <begin_op>
  if((ip = namei(old)) == 0){
    800052e4:	ed040513          	addi	a0,s0,-304
    800052e8:	d45fe0ef          	jal	8000402c <namei>
    800052ec:	84aa                	mv	s1,a0
    800052ee:	c53d                	beqz	a0,8000535c <sys_link+0xae>
  ilock(ip);
    800052f0:	d26fe0ef          	jal	80003816 <ilock>
  if(ip->type == T_DIR){
    800052f4:	04449703          	lh	a4,68(s1)
    800052f8:	4785                	li	a5,1
    800052fa:	06f70663          	beq	a4,a5,80005366 <sys_link+0xb8>
    800052fe:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005300:	04a4d783          	lhu	a5,74(s1)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000530a:	8526                	mv	a0,s1
    8000530c:	c56fe0ef          	jal	80003762 <iupdate>
  iunlock(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	db2fe0ef          	jal	800038c4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005316:	fd040593          	addi	a1,s0,-48
    8000531a:	f5040513          	addi	a0,s0,-176
    8000531e:	d29fe0ef          	jal	80004046 <nameiparent>
    80005322:	892a                	mv	s2,a0
    80005324:	cd21                	beqz	a0,8000537c <sys_link+0xce>
  ilock(dp);
    80005326:	cf0fe0ef          	jal	80003816 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000532a:	00092703          	lw	a4,0(s2)
    8000532e:	409c                	lw	a5,0(s1)
    80005330:	04f71363          	bne	a4,a5,80005376 <sys_link+0xc8>
    80005334:	40d0                	lw	a2,4(s1)
    80005336:	fd040593          	addi	a1,s0,-48
    8000533a:	854a                	mv	a0,s2
    8000533c:	c57fe0ef          	jal	80003f92 <dirlink>
    80005340:	02054b63          	bltz	a0,80005376 <sys_link+0xc8>
  iunlockput(dp);
    80005344:	854a                	mv	a0,s2
    80005346:	edafe0ef          	jal	80003a20 <iunlockput>
  iput(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	e4cfe0ef          	jal	80003998 <iput>
  end_op();
    80005350:	f1bfe0ef          	jal	8000426a <end_op>
  return 0;
    80005354:	4781                	li	a5,0
    80005356:	64f2                	ld	s1,280(sp)
    80005358:	6952                	ld	s2,272(sp)
    8000535a:	a0a1                	j	800053a2 <sys_link+0xf4>
    end_op();
    8000535c:	f0ffe0ef          	jal	8000426a <end_op>
    return -1;
    80005360:	57fd                	li	a5,-1
    80005362:	64f2                	ld	s1,280(sp)
    80005364:	a83d                	j	800053a2 <sys_link+0xf4>
    iunlockput(ip);
    80005366:	8526                	mv	a0,s1
    80005368:	eb8fe0ef          	jal	80003a20 <iunlockput>
    end_op();
    8000536c:	efffe0ef          	jal	8000426a <end_op>
    return -1;
    80005370:	57fd                	li	a5,-1
    80005372:	64f2                	ld	s1,280(sp)
    80005374:	a03d                	j	800053a2 <sys_link+0xf4>
    iunlockput(dp);
    80005376:	854a                	mv	a0,s2
    80005378:	ea8fe0ef          	jal	80003a20 <iunlockput>
  ilock(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	c98fe0ef          	jal	80003816 <ilock>
  ip->nlink--;
    80005382:	04a4d783          	lhu	a5,74(s1)
    80005386:	37fd                	addiw	a5,a5,-1
    80005388:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000538c:	8526                	mv	a0,s1
    8000538e:	bd4fe0ef          	jal	80003762 <iupdate>
  iunlockput(ip);
    80005392:	8526                	mv	a0,s1
    80005394:	e8cfe0ef          	jal	80003a20 <iunlockput>
  end_op();
    80005398:	ed3fe0ef          	jal	8000426a <end_op>
  return -1;
    8000539c:	57fd                	li	a5,-1
    8000539e:	64f2                	ld	s1,280(sp)
    800053a0:	6952                	ld	s2,272(sp)
}
    800053a2:	853e                	mv	a0,a5
    800053a4:	70b2                	ld	ra,296(sp)
    800053a6:	7412                	ld	s0,288(sp)
    800053a8:	6155                	addi	sp,sp,304
    800053aa:	8082                	ret

00000000800053ac <sys_unlink>:
{
    800053ac:	7151                	addi	sp,sp,-240
    800053ae:	f586                	sd	ra,232(sp)
    800053b0:	f1a2                	sd	s0,224(sp)
    800053b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b4:	08000613          	li	a2,128
    800053b8:	f3040593          	addi	a1,s0,-208
    800053bc:	4501                	li	a0,0
    800053be:	979fd0ef          	jal	80002d36 <argstr>
    800053c2:	16054063          	bltz	a0,80005522 <sys_unlink+0x176>
    800053c6:	eda6                	sd	s1,216(sp)
  begin_op();
    800053c8:	e39fe0ef          	jal	80004200 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053cc:	fb040593          	addi	a1,s0,-80
    800053d0:	f3040513          	addi	a0,s0,-208
    800053d4:	c73fe0ef          	jal	80004046 <nameiparent>
    800053d8:	84aa                	mv	s1,a0
    800053da:	c945                	beqz	a0,8000548a <sys_unlink+0xde>
  ilock(dp);
    800053dc:	c3afe0ef          	jal	80003816 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053e0:	00002597          	auipc	a1,0x2
    800053e4:	1f058593          	addi	a1,a1,496 # 800075d0 <etext+0x5d0>
    800053e8:	fb040513          	addi	a0,s0,-80
    800053ec:	9c5fe0ef          	jal	80003db0 <namecmp>
    800053f0:	10050e63          	beqz	a0,8000550c <sys_unlink+0x160>
    800053f4:	00002597          	auipc	a1,0x2
    800053f8:	1e458593          	addi	a1,a1,484 # 800075d8 <etext+0x5d8>
    800053fc:	fb040513          	addi	a0,s0,-80
    80005400:	9b1fe0ef          	jal	80003db0 <namecmp>
    80005404:	10050463          	beqz	a0,8000550c <sys_unlink+0x160>
    80005408:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000540a:	f2c40613          	addi	a2,s0,-212
    8000540e:	fb040593          	addi	a1,s0,-80
    80005412:	8526                	mv	a0,s1
    80005414:	9b3fe0ef          	jal	80003dc6 <dirlookup>
    80005418:	892a                	mv	s2,a0
    8000541a:	0e050863          	beqz	a0,8000550a <sys_unlink+0x15e>
  ilock(ip);
    8000541e:	bf8fe0ef          	jal	80003816 <ilock>
  if(ip->nlink < 1)
    80005422:	04a91783          	lh	a5,74(s2)
    80005426:	06f05763          	blez	a5,80005494 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000542a:	04491703          	lh	a4,68(s2)
    8000542e:	4785                	li	a5,1
    80005430:	06f70963          	beq	a4,a5,800054a2 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80005434:	4641                	li	a2,16
    80005436:	4581                	li	a1,0
    80005438:	fc040513          	addi	a0,s0,-64
    8000543c:	867fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005440:	4741                	li	a4,16
    80005442:	f2c42683          	lw	a3,-212(s0)
    80005446:	fc040613          	addi	a2,s0,-64
    8000544a:	4581                	li	a1,0
    8000544c:	8526                	mv	a0,s1
    8000544e:	855fe0ef          	jal	80003ca2 <writei>
    80005452:	47c1                	li	a5,16
    80005454:	08f51b63          	bne	a0,a5,800054ea <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80005458:	04491703          	lh	a4,68(s2)
    8000545c:	4785                	li	a5,1
    8000545e:	08f70d63          	beq	a4,a5,800054f8 <sys_unlink+0x14c>
  iunlockput(dp);
    80005462:	8526                	mv	a0,s1
    80005464:	dbcfe0ef          	jal	80003a20 <iunlockput>
  ip->nlink--;
    80005468:	04a95783          	lhu	a5,74(s2)
    8000546c:	37fd                	addiw	a5,a5,-1
    8000546e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005472:	854a                	mv	a0,s2
    80005474:	aeefe0ef          	jal	80003762 <iupdate>
  iunlockput(ip);
    80005478:	854a                	mv	a0,s2
    8000547a:	da6fe0ef          	jal	80003a20 <iunlockput>
  end_op();
    8000547e:	dedfe0ef          	jal	8000426a <end_op>
  return 0;
    80005482:	4501                	li	a0,0
    80005484:	64ee                	ld	s1,216(sp)
    80005486:	694e                	ld	s2,208(sp)
    80005488:	a849                	j	8000551a <sys_unlink+0x16e>
    end_op();
    8000548a:	de1fe0ef          	jal	8000426a <end_op>
    return -1;
    8000548e:	557d                	li	a0,-1
    80005490:	64ee                	ld	s1,216(sp)
    80005492:	a061                	j	8000551a <sys_unlink+0x16e>
    80005494:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005496:	00002517          	auipc	a0,0x2
    8000549a:	14a50513          	addi	a0,a0,330 # 800075e0 <etext+0x5e0>
    8000549e:	b42fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054a2:	04c92703          	lw	a4,76(s2)
    800054a6:	02000793          	li	a5,32
    800054aa:	f8e7f5e3          	bgeu	a5,a4,80005434 <sys_unlink+0x88>
    800054ae:	e5ce                	sd	s3,200(sp)
    800054b0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054b4:	4741                	li	a4,16
    800054b6:	86ce                	mv	a3,s3
    800054b8:	f1840613          	addi	a2,s0,-232
    800054bc:	4581                	li	a1,0
    800054be:	854a                	mv	a0,s2
    800054c0:	ee6fe0ef          	jal	80003ba6 <readi>
    800054c4:	47c1                	li	a5,16
    800054c6:	00f51c63          	bne	a0,a5,800054de <sys_unlink+0x132>
    if(de.inum != 0)
    800054ca:	f1845783          	lhu	a5,-232(s0)
    800054ce:	efa1                	bnez	a5,80005526 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054d0:	29c1                	addiw	s3,s3,16
    800054d2:	04c92783          	lw	a5,76(s2)
    800054d6:	fcf9efe3          	bltu	s3,a5,800054b4 <sys_unlink+0x108>
    800054da:	69ae                	ld	s3,200(sp)
    800054dc:	bfa1                	j	80005434 <sys_unlink+0x88>
      panic("isdirempty: readi");
    800054de:	00002517          	auipc	a0,0x2
    800054e2:	11a50513          	addi	a0,a0,282 # 800075f8 <etext+0x5f8>
    800054e6:	afafb0ef          	jal	800007e0 <panic>
    800054ea:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    800054ec:	00002517          	auipc	a0,0x2
    800054f0:	12450513          	addi	a0,a0,292 # 80007610 <etext+0x610>
    800054f4:	aecfb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    800054f8:	04a4d783          	lhu	a5,74(s1)
    800054fc:	37fd                	addiw	a5,a5,-1
    800054fe:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005502:	8526                	mv	a0,s1
    80005504:	a5efe0ef          	jal	80003762 <iupdate>
    80005508:	bfa9                	j	80005462 <sys_unlink+0xb6>
    8000550a:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    8000550c:	8526                	mv	a0,s1
    8000550e:	d12fe0ef          	jal	80003a20 <iunlockput>
  end_op();
    80005512:	d59fe0ef          	jal	8000426a <end_op>
  return -1;
    80005516:	557d                	li	a0,-1
    80005518:	64ee                	ld	s1,216(sp)
}
    8000551a:	70ae                	ld	ra,232(sp)
    8000551c:	740e                	ld	s0,224(sp)
    8000551e:	616d                	addi	sp,sp,240
    80005520:	8082                	ret
    return -1;
    80005522:	557d                	li	a0,-1
    80005524:	bfdd                	j	8000551a <sys_unlink+0x16e>
    iunlockput(ip);
    80005526:	854a                	mv	a0,s2
    80005528:	cf8fe0ef          	jal	80003a20 <iunlockput>
    goto bad;
    8000552c:	694e                	ld	s2,208(sp)
    8000552e:	69ae                	ld	s3,200(sp)
    80005530:	bff1                	j	8000550c <sys_unlink+0x160>

0000000080005532 <sys_open>:

uint64
sys_open(void)
{
    80005532:	7131                	addi	sp,sp,-192
    80005534:	fd06                	sd	ra,184(sp)
    80005536:	f922                	sd	s0,176(sp)
    80005538:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000553a:	f4c40593          	addi	a1,s0,-180
    8000553e:	4505                	li	a0,1
    80005540:	faafd0ef          	jal	80002cea <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005544:	08000613          	li	a2,128
    80005548:	f5040593          	addi	a1,s0,-176
    8000554c:	4501                	li	a0,0
    8000554e:	fe8fd0ef          	jal	80002d36 <argstr>
    80005552:	87aa                	mv	a5,a0
    return -1;
    80005554:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005556:	0a07c263          	bltz	a5,800055fa <sys_open+0xc8>
    8000555a:	f526                	sd	s1,168(sp)

  begin_op();
    8000555c:	ca5fe0ef          	jal	80004200 <begin_op>

  if(omode & O_CREATE){
    80005560:	f4c42783          	lw	a5,-180(s0)
    80005564:	2007f793          	andi	a5,a5,512
    80005568:	c3d5                	beqz	a5,8000560c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    8000556a:	4681                	li	a3,0
    8000556c:	4601                	li	a2,0
    8000556e:	4589                	li	a1,2
    80005570:	f5040513          	addi	a0,s0,-176
    80005574:	aa9ff0ef          	jal	8000501c <create>
    80005578:	84aa                	mv	s1,a0
    if(ip == 0){
    8000557a:	c541                	beqz	a0,80005602 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000557c:	04449703          	lh	a4,68(s1)
    80005580:	478d                	li	a5,3
    80005582:	00f71763          	bne	a4,a5,80005590 <sys_open+0x5e>
    80005586:	0464d703          	lhu	a4,70(s1)
    8000558a:	47a5                	li	a5,9
    8000558c:	0ae7ed63          	bltu	a5,a4,80005646 <sys_open+0x114>
    80005590:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005592:	fd7fe0ef          	jal	80004568 <filealloc>
    80005596:	892a                	mv	s2,a0
    80005598:	c179                	beqz	a0,8000565e <sys_open+0x12c>
    8000559a:	ed4e                	sd	s3,152(sp)
    8000559c:	a43ff0ef          	jal	80004fde <fdalloc>
    800055a0:	89aa                	mv	s3,a0
    800055a2:	0a054a63          	bltz	a0,80005656 <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055a6:	04449703          	lh	a4,68(s1)
    800055aa:	478d                	li	a5,3
    800055ac:	0cf70263          	beq	a4,a5,80005670 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055b0:	4789                	li	a5,2
    800055b2:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800055b6:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800055ba:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800055be:	f4c42783          	lw	a5,-180(s0)
    800055c2:	0017c713          	xori	a4,a5,1
    800055c6:	8b05                	andi	a4,a4,1
    800055c8:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800055cc:	0037f713          	andi	a4,a5,3
    800055d0:	00e03733          	snez	a4,a4
    800055d4:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800055d8:	4007f793          	andi	a5,a5,1024
    800055dc:	c791                	beqz	a5,800055e8 <sys_open+0xb6>
    800055de:	04449703          	lh	a4,68(s1)
    800055e2:	4789                	li	a5,2
    800055e4:	08f70d63          	beq	a4,a5,8000567e <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	adafe0ef          	jal	800038c4 <iunlock>
  end_op();
    800055ee:	c7dfe0ef          	jal	8000426a <end_op>

  return fd;
    800055f2:	854e                	mv	a0,s3
    800055f4:	74aa                	ld	s1,168(sp)
    800055f6:	790a                	ld	s2,160(sp)
    800055f8:	69ea                	ld	s3,152(sp)
}
    800055fa:	70ea                	ld	ra,184(sp)
    800055fc:	744a                	ld	s0,176(sp)
    800055fe:	6129                	addi	sp,sp,192
    80005600:	8082                	ret
      end_op();
    80005602:	c69fe0ef          	jal	8000426a <end_op>
      return -1;
    80005606:	557d                	li	a0,-1
    80005608:	74aa                	ld	s1,168(sp)
    8000560a:	bfc5                	j	800055fa <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    8000560c:	f5040513          	addi	a0,s0,-176
    80005610:	a1dfe0ef          	jal	8000402c <namei>
    80005614:	84aa                	mv	s1,a0
    80005616:	c11d                	beqz	a0,8000563c <sys_open+0x10a>
    ilock(ip);
    80005618:	9fefe0ef          	jal	80003816 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000561c:	04449703          	lh	a4,68(s1)
    80005620:	4785                	li	a5,1
    80005622:	f4f71de3          	bne	a4,a5,8000557c <sys_open+0x4a>
    80005626:	f4c42783          	lw	a5,-180(s0)
    8000562a:	d3bd                	beqz	a5,80005590 <sys_open+0x5e>
      iunlockput(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	bf2fe0ef          	jal	80003a20 <iunlockput>
      end_op();
    80005632:	c39fe0ef          	jal	8000426a <end_op>
      return -1;
    80005636:	557d                	li	a0,-1
    80005638:	74aa                	ld	s1,168(sp)
    8000563a:	b7c1                	j	800055fa <sys_open+0xc8>
      end_op();
    8000563c:	c2ffe0ef          	jal	8000426a <end_op>
      return -1;
    80005640:	557d                	li	a0,-1
    80005642:	74aa                	ld	s1,168(sp)
    80005644:	bf5d                	j	800055fa <sys_open+0xc8>
    iunlockput(ip);
    80005646:	8526                	mv	a0,s1
    80005648:	bd8fe0ef          	jal	80003a20 <iunlockput>
    end_op();
    8000564c:	c1ffe0ef          	jal	8000426a <end_op>
    return -1;
    80005650:	557d                	li	a0,-1
    80005652:	74aa                	ld	s1,168(sp)
    80005654:	b75d                	j	800055fa <sys_open+0xc8>
      fileclose(f);
    80005656:	854a                	mv	a0,s2
    80005658:	fb5fe0ef          	jal	8000460c <fileclose>
    8000565c:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    8000565e:	8526                	mv	a0,s1
    80005660:	bc0fe0ef          	jal	80003a20 <iunlockput>
    end_op();
    80005664:	c07fe0ef          	jal	8000426a <end_op>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	74aa                	ld	s1,168(sp)
    8000566c:	790a                	ld	s2,160(sp)
    8000566e:	b771                	j	800055fa <sys_open+0xc8>
    f->type = FD_DEVICE;
    80005670:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005674:	04649783          	lh	a5,70(s1)
    80005678:	02f91223          	sh	a5,36(s2)
    8000567c:	bf3d                	j	800055ba <sys_open+0x88>
    itrunc(ip);
    8000567e:	8526                	mv	a0,s1
    80005680:	a84fe0ef          	jal	80003904 <itrunc>
    80005684:	b795                	j	800055e8 <sys_open+0xb6>

0000000080005686 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005686:	7175                	addi	sp,sp,-144
    80005688:	e506                	sd	ra,136(sp)
    8000568a:	e122                	sd	s0,128(sp)
    8000568c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000568e:	b73fe0ef          	jal	80004200 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005692:	08000613          	li	a2,128
    80005696:	f7040593          	addi	a1,s0,-144
    8000569a:	4501                	li	a0,0
    8000569c:	e9afd0ef          	jal	80002d36 <argstr>
    800056a0:	02054363          	bltz	a0,800056c6 <sys_mkdir+0x40>
    800056a4:	4681                	li	a3,0
    800056a6:	4601                	li	a2,0
    800056a8:	4585                	li	a1,1
    800056aa:	f7040513          	addi	a0,s0,-144
    800056ae:	96fff0ef          	jal	8000501c <create>
    800056b2:	c911                	beqz	a0,800056c6 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800056b4:	b6cfe0ef          	jal	80003a20 <iunlockput>
  end_op();
    800056b8:	bb3fe0ef          	jal	8000426a <end_op>
  return 0;
    800056bc:	4501                	li	a0,0
}
    800056be:	60aa                	ld	ra,136(sp)
    800056c0:	640a                	ld	s0,128(sp)
    800056c2:	6149                	addi	sp,sp,144
    800056c4:	8082                	ret
    end_op();
    800056c6:	ba5fe0ef          	jal	8000426a <end_op>
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	bfcd                	j	800056be <sys_mkdir+0x38>

00000000800056ce <sys_mknod>:

uint64
sys_mknod(void)
{
    800056ce:	7135                	addi	sp,sp,-160
    800056d0:	ed06                	sd	ra,152(sp)
    800056d2:	e922                	sd	s0,144(sp)
    800056d4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800056d6:	b2bfe0ef          	jal	80004200 <begin_op>
  argint(1, &major);
    800056da:	f6c40593          	addi	a1,s0,-148
    800056de:	4505                	li	a0,1
    800056e0:	e0afd0ef          	jal	80002cea <argint>
  argint(2, &minor);
    800056e4:	f6840593          	addi	a1,s0,-152
    800056e8:	4509                	li	a0,2
    800056ea:	e00fd0ef          	jal	80002cea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800056ee:	08000613          	li	a2,128
    800056f2:	f7040593          	addi	a1,s0,-144
    800056f6:	4501                	li	a0,0
    800056f8:	e3efd0ef          	jal	80002d36 <argstr>
    800056fc:	02054563          	bltz	a0,80005726 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005700:	f6841683          	lh	a3,-152(s0)
    80005704:	f6c41603          	lh	a2,-148(s0)
    80005708:	458d                	li	a1,3
    8000570a:	f7040513          	addi	a0,s0,-144
    8000570e:	90fff0ef          	jal	8000501c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005712:	c911                	beqz	a0,80005726 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005714:	b0cfe0ef          	jal	80003a20 <iunlockput>
  end_op();
    80005718:	b53fe0ef          	jal	8000426a <end_op>
  return 0;
    8000571c:	4501                	li	a0,0
}
    8000571e:	60ea                	ld	ra,152(sp)
    80005720:	644a                	ld	s0,144(sp)
    80005722:	610d                	addi	sp,sp,160
    80005724:	8082                	ret
    end_op();
    80005726:	b45fe0ef          	jal	8000426a <end_op>
    return -1;
    8000572a:	557d                	li	a0,-1
    8000572c:	bfcd                	j	8000571e <sys_mknod+0x50>

000000008000572e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000572e:	7135                	addi	sp,sp,-160
    80005730:	ed06                	sd	ra,152(sp)
    80005732:	e922                	sd	s0,144(sp)
    80005734:	e14a                	sd	s2,128(sp)
    80005736:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005738:	996fc0ef          	jal	800018ce <myproc>
    8000573c:	892a                	mv	s2,a0
  
  begin_op();
    8000573e:	ac3fe0ef          	jal	80004200 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005742:	08000613          	li	a2,128
    80005746:	f6040593          	addi	a1,s0,-160
    8000574a:	4501                	li	a0,0
    8000574c:	deafd0ef          	jal	80002d36 <argstr>
    80005750:	04054363          	bltz	a0,80005796 <sys_chdir+0x68>
    80005754:	e526                	sd	s1,136(sp)
    80005756:	f6040513          	addi	a0,s0,-160
    8000575a:	8d3fe0ef          	jal	8000402c <namei>
    8000575e:	84aa                	mv	s1,a0
    80005760:	c915                	beqz	a0,80005794 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005762:	8b4fe0ef          	jal	80003816 <ilock>
  if(ip->type != T_DIR){
    80005766:	04449703          	lh	a4,68(s1)
    8000576a:	4785                	li	a5,1
    8000576c:	02f71963          	bne	a4,a5,8000579e <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005770:	8526                	mv	a0,s1
    80005772:	952fe0ef          	jal	800038c4 <iunlock>
  iput(p->cwd);
    80005776:	15093503          	ld	a0,336(s2)
    8000577a:	a1efe0ef          	jal	80003998 <iput>
  end_op();
    8000577e:	aedfe0ef          	jal	8000426a <end_op>
  p->cwd = ip;
    80005782:	14993823          	sd	s1,336(s2)
  return 0;
    80005786:	4501                	li	a0,0
    80005788:	64aa                	ld	s1,136(sp)
}
    8000578a:	60ea                	ld	ra,152(sp)
    8000578c:	644a                	ld	s0,144(sp)
    8000578e:	690a                	ld	s2,128(sp)
    80005790:	610d                	addi	sp,sp,160
    80005792:	8082                	ret
    80005794:	64aa                	ld	s1,136(sp)
    end_op();
    80005796:	ad5fe0ef          	jal	8000426a <end_op>
    return -1;
    8000579a:	557d                	li	a0,-1
    8000579c:	b7fd                	j	8000578a <sys_chdir+0x5c>
    iunlockput(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	a80fe0ef          	jal	80003a20 <iunlockput>
    end_op();
    800057a4:	ac7fe0ef          	jal	8000426a <end_op>
    return -1;
    800057a8:	557d                	li	a0,-1
    800057aa:	64aa                	ld	s1,136(sp)
    800057ac:	bff9                	j	8000578a <sys_chdir+0x5c>

00000000800057ae <sys_exec>:

uint64
sys_exec(void)
{
    800057ae:	7121                	addi	sp,sp,-448
    800057b0:	ff06                	sd	ra,440(sp)
    800057b2:	fb22                	sd	s0,432(sp)
    800057b4:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800057b6:	e4840593          	addi	a1,s0,-440
    800057ba:	4505                	li	a0,1
    800057bc:	d4afd0ef          	jal	80002d06 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800057c0:	08000613          	li	a2,128
    800057c4:	f5040593          	addi	a1,s0,-176
    800057c8:	4501                	li	a0,0
    800057ca:	d6cfd0ef          	jal	80002d36 <argstr>
    800057ce:	87aa                	mv	a5,a0
    return -1;
    800057d0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800057d2:	0c07c463          	bltz	a5,8000589a <sys_exec+0xec>
    800057d6:	f726                	sd	s1,424(sp)
    800057d8:	f34a                	sd	s2,416(sp)
    800057da:	ef4e                	sd	s3,408(sp)
    800057dc:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800057de:	10000613          	li	a2,256
    800057e2:	4581                	li	a1,0
    800057e4:	e5040513          	addi	a0,s0,-432
    800057e8:	cbafb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800057ec:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800057f0:	89a6                	mv	s3,s1
    800057f2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800057f4:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800057f8:	00391513          	slli	a0,s2,0x3
    800057fc:	e4040593          	addi	a1,s0,-448
    80005800:	e4843783          	ld	a5,-440(s0)
    80005804:	953e                	add	a0,a0,a5
    80005806:	c5afd0ef          	jal	80002c60 <fetchaddr>
    8000580a:	02054663          	bltz	a0,80005836 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    8000580e:	e4043783          	ld	a5,-448(s0)
    80005812:	c3a9                	beqz	a5,80005854 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005814:	aeafb0ef          	jal	80000afe <kalloc>
    80005818:	85aa                	mv	a1,a0
    8000581a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000581e:	cd01                	beqz	a0,80005836 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005820:	6605                	lui	a2,0x1
    80005822:	e4043503          	ld	a0,-448(s0)
    80005826:	c84fd0ef          	jal	80002caa <fetchstr>
    8000582a:	00054663          	bltz	a0,80005836 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    8000582e:	0905                	addi	s2,s2,1
    80005830:	09a1                	addi	s3,s3,8
    80005832:	fd4913e3          	bne	s2,s4,800057f8 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005836:	f5040913          	addi	s2,s0,-176
    8000583a:	6088                	ld	a0,0(s1)
    8000583c:	c931                	beqz	a0,80005890 <sys_exec+0xe2>
    kfree(argv[i]);
    8000583e:	9defb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005842:	04a1                	addi	s1,s1,8
    80005844:	ff249be3          	bne	s1,s2,8000583a <sys_exec+0x8c>
  return -1;
    80005848:	557d                	li	a0,-1
    8000584a:	74ba                	ld	s1,424(sp)
    8000584c:	791a                	ld	s2,416(sp)
    8000584e:	69fa                	ld	s3,408(sp)
    80005850:	6a5a                	ld	s4,400(sp)
    80005852:	a0a1                	j	8000589a <sys_exec+0xec>
      argv[i] = 0;
    80005854:	0009079b          	sext.w	a5,s2
    80005858:	078e                	slli	a5,a5,0x3
    8000585a:	fd078793          	addi	a5,a5,-48
    8000585e:	97a2                	add	a5,a5,s0
    80005860:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    80005864:	e5040593          	addi	a1,s0,-432
    80005868:	f5040513          	addi	a0,s0,-176
    8000586c:	ba8ff0ef          	jal	80004c14 <kexec>
    80005870:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005872:	f5040993          	addi	s3,s0,-176
    80005876:	6088                	ld	a0,0(s1)
    80005878:	c511                	beqz	a0,80005884 <sys_exec+0xd6>
    kfree(argv[i]);
    8000587a:	9a2fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000587e:	04a1                	addi	s1,s1,8
    80005880:	ff349be3          	bne	s1,s3,80005876 <sys_exec+0xc8>
  return ret;
    80005884:	854a                	mv	a0,s2
    80005886:	74ba                	ld	s1,424(sp)
    80005888:	791a                	ld	s2,416(sp)
    8000588a:	69fa                	ld	s3,408(sp)
    8000588c:	6a5a                	ld	s4,400(sp)
    8000588e:	a031                	j	8000589a <sys_exec+0xec>
  return -1;
    80005890:	557d                	li	a0,-1
    80005892:	74ba                	ld	s1,424(sp)
    80005894:	791a                	ld	s2,416(sp)
    80005896:	69fa                	ld	s3,408(sp)
    80005898:	6a5a                	ld	s4,400(sp)
}
    8000589a:	70fa                	ld	ra,440(sp)
    8000589c:	745a                	ld	s0,432(sp)
    8000589e:	6139                	addi	sp,sp,448
    800058a0:	8082                	ret

00000000800058a2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800058a2:	7139                	addi	sp,sp,-64
    800058a4:	fc06                	sd	ra,56(sp)
    800058a6:	f822                	sd	s0,48(sp)
    800058a8:	f426                	sd	s1,40(sp)
    800058aa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800058ac:	822fc0ef          	jal	800018ce <myproc>
    800058b0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800058b2:	fd840593          	addi	a1,s0,-40
    800058b6:	4501                	li	a0,0
    800058b8:	c4efd0ef          	jal	80002d06 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800058bc:	fc840593          	addi	a1,s0,-56
    800058c0:	fd040513          	addi	a0,s0,-48
    800058c4:	852ff0ef          	jal	80004916 <pipealloc>
    return -1;
    800058c8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800058ca:	0a054463          	bltz	a0,80005972 <sys_pipe+0xd0>
  fd0 = -1;
    800058ce:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800058d2:	fd043503          	ld	a0,-48(s0)
    800058d6:	f08ff0ef          	jal	80004fde <fdalloc>
    800058da:	fca42223          	sw	a0,-60(s0)
    800058de:	08054163          	bltz	a0,80005960 <sys_pipe+0xbe>
    800058e2:	fc843503          	ld	a0,-56(s0)
    800058e6:	ef8ff0ef          	jal	80004fde <fdalloc>
    800058ea:	fca42023          	sw	a0,-64(s0)
    800058ee:	06054063          	bltz	a0,8000594e <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800058f2:	4691                	li	a3,4
    800058f4:	fc440613          	addi	a2,s0,-60
    800058f8:	fd843583          	ld	a1,-40(s0)
    800058fc:	68a8                	ld	a0,80(s1)
    800058fe:	ce5fb0ef          	jal	800015e2 <copyout>
    80005902:	00054e63          	bltz	a0,8000591e <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005906:	4691                	li	a3,4
    80005908:	fc040613          	addi	a2,s0,-64
    8000590c:	fd843583          	ld	a1,-40(s0)
    80005910:	0591                	addi	a1,a1,4
    80005912:	68a8                	ld	a0,80(s1)
    80005914:	ccffb0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005918:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000591a:	04055c63          	bgez	a0,80005972 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000591e:	fc442783          	lw	a5,-60(s0)
    80005922:	07e9                	addi	a5,a5,26
    80005924:	078e                	slli	a5,a5,0x3
    80005926:	97a6                	add	a5,a5,s1
    80005928:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000592c:	fc042783          	lw	a5,-64(s0)
    80005930:	07e9                	addi	a5,a5,26
    80005932:	078e                	slli	a5,a5,0x3
    80005934:	94be                	add	s1,s1,a5
    80005936:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000593a:	fd043503          	ld	a0,-48(s0)
    8000593e:	ccffe0ef          	jal	8000460c <fileclose>
    fileclose(wf);
    80005942:	fc843503          	ld	a0,-56(s0)
    80005946:	cc7fe0ef          	jal	8000460c <fileclose>
    return -1;
    8000594a:	57fd                	li	a5,-1
    8000594c:	a01d                	j	80005972 <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000594e:	fc442783          	lw	a5,-60(s0)
    80005952:	0007c763          	bltz	a5,80005960 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005956:	07e9                	addi	a5,a5,26
    80005958:	078e                	slli	a5,a5,0x3
    8000595a:	97a6                	add	a5,a5,s1
    8000595c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005960:	fd043503          	ld	a0,-48(s0)
    80005964:	ca9fe0ef          	jal	8000460c <fileclose>
    fileclose(wf);
    80005968:	fc843503          	ld	a0,-56(s0)
    8000596c:	ca1fe0ef          	jal	8000460c <fileclose>
    return -1;
    80005970:	57fd                	li	a5,-1
}
    80005972:	853e                	mv	a0,a5
    80005974:	70e2                	ld	ra,56(sp)
    80005976:	7442                	ld	s0,48(sp)
    80005978:	74a2                	ld	s1,40(sp)
    8000597a:	6121                	addi	sp,sp,64
    8000597c:	8082                	ret
	...

0000000080005980 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005980:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005982:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005984:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005986:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005988:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000598a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000598c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000598e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005990:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005992:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005994:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005996:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005998:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000599a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000599c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000599e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800059a0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800059a2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800059a4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800059a6:	922fd0ef          	jal	80002ac8 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800059aa:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800059ac:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800059ae:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800059b0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800059b2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800059b4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800059b6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800059b8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800059ba:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800059bc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800059be:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800059c0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800059c2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800059c4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800059c6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800059c8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800059ca:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800059cc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800059ce:	10200073          	sret
	...

00000000800059de <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800059de:	1141                	addi	sp,sp,-16
    800059e0:	e422                	sd	s0,8(sp)
    800059e2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800059e4:	0c0007b7          	lui	a5,0xc000
    800059e8:	4705                	li	a4,1
    800059ea:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800059ec:	0c0007b7          	lui	a5,0xc000
    800059f0:	c3d8                	sw	a4,4(a5)
}
    800059f2:	6422                	ld	s0,8(sp)
    800059f4:	0141                	addi	sp,sp,16
    800059f6:	8082                	ret

00000000800059f8 <plicinithart>:

void
plicinithart(void)
{
    800059f8:	1141                	addi	sp,sp,-16
    800059fa:	e406                	sd	ra,8(sp)
    800059fc:	e022                	sd	s0,0(sp)
    800059fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005a00:	ea3fb0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005a04:	0085171b          	slliw	a4,a0,0x8
    80005a08:	0c0027b7          	lui	a5,0xc002
    80005a0c:	97ba                	add	a5,a5,a4
    80005a0e:	40200713          	li	a4,1026
    80005a12:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005a16:	00d5151b          	slliw	a0,a0,0xd
    80005a1a:	0c2017b7          	lui	a5,0xc201
    80005a1e:	97aa                	add	a5,a5,a0
    80005a20:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005a24:	60a2                	ld	ra,8(sp)
    80005a26:	6402                	ld	s0,0(sp)
    80005a28:	0141                	addi	sp,sp,16
    80005a2a:	8082                	ret

0000000080005a2c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005a2c:	1141                	addi	sp,sp,-16
    80005a2e:	e406                	sd	ra,8(sp)
    80005a30:	e022                	sd	s0,0(sp)
    80005a32:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005a34:	e6ffb0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005a38:	00d5151b          	slliw	a0,a0,0xd
    80005a3c:	0c2017b7          	lui	a5,0xc201
    80005a40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005a42:	43c8                	lw	a0,4(a5)
    80005a44:	60a2                	ld	ra,8(sp)
    80005a46:	6402                	ld	s0,0(sp)
    80005a48:	0141                	addi	sp,sp,16
    80005a4a:	8082                	ret

0000000080005a4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005a4c:	1101                	addi	sp,sp,-32
    80005a4e:	ec06                	sd	ra,24(sp)
    80005a50:	e822                	sd	s0,16(sp)
    80005a52:	e426                	sd	s1,8(sp)
    80005a54:	1000                	addi	s0,sp,32
    80005a56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005a58:	e4bfb0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005a5c:	00d5151b          	slliw	a0,a0,0xd
    80005a60:	0c2017b7          	lui	a5,0xc201
    80005a64:	97aa                	add	a5,a5,a0
    80005a66:	c3c4                	sw	s1,4(a5)
}
    80005a68:	60e2                	ld	ra,24(sp)
    80005a6a:	6442                	ld	s0,16(sp)
    80005a6c:	64a2                	ld	s1,8(sp)
    80005a6e:	6105                	addi	sp,sp,32
    80005a70:	8082                	ret

0000000080005a72 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005a72:	1141                	addi	sp,sp,-16
    80005a74:	e406                	sd	ra,8(sp)
    80005a76:	e022                	sd	s0,0(sp)
    80005a78:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005a7a:	479d                	li	a5,7
    80005a7c:	04a7ca63          	blt	a5,a0,80005ad0 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005a80:	0001c797          	auipc	a5,0x1c
    80005a84:	7d878793          	addi	a5,a5,2008 # 80022258 <disk>
    80005a88:	97aa                	add	a5,a5,a0
    80005a8a:	0187c783          	lbu	a5,24(a5)
    80005a8e:	e7b9                	bnez	a5,80005adc <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005a90:	00451693          	slli	a3,a0,0x4
    80005a94:	0001c797          	auipc	a5,0x1c
    80005a98:	7c478793          	addi	a5,a5,1988 # 80022258 <disk>
    80005a9c:	6398                	ld	a4,0(a5)
    80005a9e:	9736                	add	a4,a4,a3
    80005aa0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005aa4:	6398                	ld	a4,0(a5)
    80005aa6:	9736                	add	a4,a4,a3
    80005aa8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005aac:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ab0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ab4:	97aa                	add	a5,a5,a0
    80005ab6:	4705                	li	a4,1
    80005ab8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005abc:	0001c517          	auipc	a0,0x1c
    80005ac0:	7b450513          	addi	a0,a0,1972 # 80022270 <disk+0x18>
    80005ac4:	f2afc0ef          	jal	800021ee <wakeup>
}
    80005ac8:	60a2                	ld	ra,8(sp)
    80005aca:	6402                	ld	s0,0(sp)
    80005acc:	0141                	addi	sp,sp,16
    80005ace:	8082                	ret
    panic("free_desc 1");
    80005ad0:	00002517          	auipc	a0,0x2
    80005ad4:	b5050513          	addi	a0,a0,-1200 # 80007620 <etext+0x620>
    80005ad8:	d09fa0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    80005adc:	00002517          	auipc	a0,0x2
    80005ae0:	b5450513          	addi	a0,a0,-1196 # 80007630 <etext+0x630>
    80005ae4:	cfdfa0ef          	jal	800007e0 <panic>

0000000080005ae8 <virtio_disk_init>:
{
    80005ae8:	1101                	addi	sp,sp,-32
    80005aea:	ec06                	sd	ra,24(sp)
    80005aec:	e822                	sd	s0,16(sp)
    80005aee:	e426                	sd	s1,8(sp)
    80005af0:	e04a                	sd	s2,0(sp)
    80005af2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005af4:	00002597          	auipc	a1,0x2
    80005af8:	b4c58593          	addi	a1,a1,-1204 # 80007640 <etext+0x640>
    80005afc:	0001d517          	auipc	a0,0x1d
    80005b00:	88450513          	addi	a0,a0,-1916 # 80022380 <disk+0x128>
    80005b04:	84afb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005b08:	100017b7          	lui	a5,0x10001
    80005b0c:	4398                	lw	a4,0(a5)
    80005b0e:	2701                	sext.w	a4,a4
    80005b10:	747277b7          	lui	a5,0x74727
    80005b14:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005b18:	18f71063          	bne	a4,a5,80005c98 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005b1c:	100017b7          	lui	a5,0x10001
    80005b20:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005b22:	439c                	lw	a5,0(a5)
    80005b24:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005b26:	4709                	li	a4,2
    80005b28:	16e79863          	bne	a5,a4,80005c98 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005b2c:	100017b7          	lui	a5,0x10001
    80005b30:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005b32:	439c                	lw	a5,0(a5)
    80005b34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005b36:	16e79163          	bne	a5,a4,80005c98 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005b3a:	100017b7          	lui	a5,0x10001
    80005b3e:	47d8                	lw	a4,12(a5)
    80005b40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005b42:	554d47b7          	lui	a5,0x554d4
    80005b46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005b4a:	14f71763          	bne	a4,a5,80005c98 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b4e:	100017b7          	lui	a5,0x10001
    80005b52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b56:	4705                	li	a4,1
    80005b58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b5a:	470d                	li	a4,3
    80005b5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005b5e:	10001737          	lui	a4,0x10001
    80005b62:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005b64:	c7ffe737          	lui	a4,0xc7ffe
    80005b68:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3c7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005b6c:	8ef9                	and	a3,a3,a4
    80005b6e:	10001737          	lui	a4,0x10001
    80005b72:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b74:	472d                	li	a4,11
    80005b76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b78:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80005b7c:	439c                	lw	a5,0(a5)
    80005b7e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005b82:	8ba1                	andi	a5,a5,8
    80005b84:	12078063          	beqz	a5,80005ca4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005b88:	100017b7          	lui	a5,0x10001
    80005b8c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005b90:	100017b7          	lui	a5,0x10001
    80005b94:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005b98:	439c                	lw	a5,0(a5)
    80005b9a:	2781                	sext.w	a5,a5
    80005b9c:	10079a63          	bnez	a5,80005cb0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ba0:	100017b7          	lui	a5,0x10001
    80005ba4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005ba8:	439c                	lw	a5,0(a5)
    80005baa:	2781                	sext.w	a5,a5
  if(max == 0)
    80005bac:	10078863          	beqz	a5,80005cbc <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005bb0:	471d                	li	a4,7
    80005bb2:	10f77b63          	bgeu	a4,a5,80005cc8 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005bb6:	f49fa0ef          	jal	80000afe <kalloc>
    80005bba:	0001c497          	auipc	s1,0x1c
    80005bbe:	69e48493          	addi	s1,s1,1694 # 80022258 <disk>
    80005bc2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005bc4:	f3bfa0ef          	jal	80000afe <kalloc>
    80005bc8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005bca:	f35fa0ef          	jal	80000afe <kalloc>
    80005bce:	87aa                	mv	a5,a0
    80005bd0:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005bd2:	6088                	ld	a0,0(s1)
    80005bd4:	10050063          	beqz	a0,80005cd4 <virtio_disk_init+0x1ec>
    80005bd8:	0001c717          	auipc	a4,0x1c
    80005bdc:	68873703          	ld	a4,1672(a4) # 80022260 <disk+0x8>
    80005be0:	0e070a63          	beqz	a4,80005cd4 <virtio_disk_init+0x1ec>
    80005be4:	0e078863          	beqz	a5,80005cd4 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005be8:	6605                	lui	a2,0x1
    80005bea:	4581                	li	a1,0
    80005bec:	8b6fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005bf0:	0001c497          	auipc	s1,0x1c
    80005bf4:	66848493          	addi	s1,s1,1640 # 80022258 <disk>
    80005bf8:	6605                	lui	a2,0x1
    80005bfa:	4581                	li	a1,0
    80005bfc:	6488                	ld	a0,8(s1)
    80005bfe:	8a4fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005c02:	6605                	lui	a2,0x1
    80005c04:	4581                	li	a1,0
    80005c06:	6888                	ld	a0,16(s1)
    80005c08:	89afb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005c0c:	100017b7          	lui	a5,0x10001
    80005c10:	4721                	li	a4,8
    80005c12:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005c14:	4098                	lw	a4,0(s1)
    80005c16:	100017b7          	lui	a5,0x10001
    80005c1a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005c1e:	40d8                	lw	a4,4(s1)
    80005c20:	100017b7          	lui	a5,0x10001
    80005c24:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005c28:	649c                	ld	a5,8(s1)
    80005c2a:	0007869b          	sext.w	a3,a5
    80005c2e:	10001737          	lui	a4,0x10001
    80005c32:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005c36:	9781                	srai	a5,a5,0x20
    80005c38:	10001737          	lui	a4,0x10001
    80005c3c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005c40:	689c                	ld	a5,16(s1)
    80005c42:	0007869b          	sext.w	a3,a5
    80005c46:	10001737          	lui	a4,0x10001
    80005c4a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005c4e:	9781                	srai	a5,a5,0x20
    80005c50:	10001737          	lui	a4,0x10001
    80005c54:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005c58:	10001737          	lui	a4,0x10001
    80005c5c:	4785                	li	a5,1
    80005c5e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005c60:	00f48c23          	sb	a5,24(s1)
    80005c64:	00f48ca3          	sb	a5,25(s1)
    80005c68:	00f48d23          	sb	a5,26(s1)
    80005c6c:	00f48da3          	sb	a5,27(s1)
    80005c70:	00f48e23          	sb	a5,28(s1)
    80005c74:	00f48ea3          	sb	a5,29(s1)
    80005c78:	00f48f23          	sb	a5,30(s1)
    80005c7c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005c80:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c84:	100017b7          	lui	a5,0x10001
    80005c88:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80005c8c:	60e2                	ld	ra,24(sp)
    80005c8e:	6442                	ld	s0,16(sp)
    80005c90:	64a2                	ld	s1,8(sp)
    80005c92:	6902                	ld	s2,0(sp)
    80005c94:	6105                	addi	sp,sp,32
    80005c96:	8082                	ret
    panic("could not find virtio disk");
    80005c98:	00002517          	auipc	a0,0x2
    80005c9c:	9b850513          	addi	a0,a0,-1608 # 80007650 <etext+0x650>
    80005ca0:	b41fa0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ca4:	00002517          	auipc	a0,0x2
    80005ca8:	9cc50513          	addi	a0,a0,-1588 # 80007670 <etext+0x670>
    80005cac:	b35fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005cb0:	00002517          	auipc	a0,0x2
    80005cb4:	9e050513          	addi	a0,a0,-1568 # 80007690 <etext+0x690>
    80005cb8:	b29fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80005cbc:	00002517          	auipc	a0,0x2
    80005cc0:	9f450513          	addi	a0,a0,-1548 # 800076b0 <etext+0x6b0>
    80005cc4:	b1dfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005cc8:	00002517          	auipc	a0,0x2
    80005ccc:	a0850513          	addi	a0,a0,-1528 # 800076d0 <etext+0x6d0>
    80005cd0:	b11fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005cd4:	00002517          	auipc	a0,0x2
    80005cd8:	a1c50513          	addi	a0,a0,-1508 # 800076f0 <etext+0x6f0>
    80005cdc:	b05fa0ef          	jal	800007e0 <panic>

0000000080005ce0 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ce0:	7159                	addi	sp,sp,-112
    80005ce2:	f486                	sd	ra,104(sp)
    80005ce4:	f0a2                	sd	s0,96(sp)
    80005ce6:	eca6                	sd	s1,88(sp)
    80005ce8:	e8ca                	sd	s2,80(sp)
    80005cea:	e4ce                	sd	s3,72(sp)
    80005cec:	e0d2                	sd	s4,64(sp)
    80005cee:	fc56                	sd	s5,56(sp)
    80005cf0:	f85a                	sd	s6,48(sp)
    80005cf2:	f45e                	sd	s7,40(sp)
    80005cf4:	f062                	sd	s8,32(sp)
    80005cf6:	ec66                	sd	s9,24(sp)
    80005cf8:	1880                	addi	s0,sp,112
    80005cfa:	8a2a                	mv	s4,a0
    80005cfc:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005cfe:	00c52c83          	lw	s9,12(a0)
    80005d02:	001c9c9b          	slliw	s9,s9,0x1
    80005d06:	1c82                	slli	s9,s9,0x20
    80005d08:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005d0c:	0001c517          	auipc	a0,0x1c
    80005d10:	67450513          	addi	a0,a0,1652 # 80022380 <disk+0x128>
    80005d14:	ebbfa0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005d18:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005d1a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005d1c:	0001cb17          	auipc	s6,0x1c
    80005d20:	53cb0b13          	addi	s6,s6,1340 # 80022258 <disk>
  for(int i = 0; i < 3; i++){
    80005d24:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005d26:	0001cc17          	auipc	s8,0x1c
    80005d2a:	65ac0c13          	addi	s8,s8,1626 # 80022380 <disk+0x128>
    80005d2e:	a8b9                	j	80005d8c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005d30:	00fb0733          	add	a4,s6,a5
    80005d34:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005d38:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005d3a:	0207c563          	bltz	a5,80005d64 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005d3e:	2905                	addiw	s2,s2,1
    80005d40:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005d42:	05590963          	beq	s2,s5,80005d94 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005d46:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005d48:	0001c717          	auipc	a4,0x1c
    80005d4c:	51070713          	addi	a4,a4,1296 # 80022258 <disk>
    80005d50:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005d52:	01874683          	lbu	a3,24(a4)
    80005d56:	fee9                	bnez	a3,80005d30 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005d58:	2785                	addiw	a5,a5,1
    80005d5a:	0705                	addi	a4,a4,1
    80005d5c:	fe979be3          	bne	a5,s1,80005d52 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005d60:	57fd                	li	a5,-1
    80005d62:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005d64:	01205d63          	blez	s2,80005d7e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005d68:	f9042503          	lw	a0,-112(s0)
    80005d6c:	d07ff0ef          	jal	80005a72 <free_desc>
      for(int j = 0; j < i; j++)
    80005d70:	4785                	li	a5,1
    80005d72:	0127d663          	bge	a5,s2,80005d7e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005d76:	f9442503          	lw	a0,-108(s0)
    80005d7a:	cf9ff0ef          	jal	80005a72 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005d7e:	85e2                	mv	a1,s8
    80005d80:	0001c517          	auipc	a0,0x1c
    80005d84:	4f050513          	addi	a0,a0,1264 # 80022270 <disk+0x18>
    80005d88:	c16fc0ef          	jal	8000219e <sleep>
  for(int i = 0; i < 3; i++){
    80005d8c:	f9040613          	addi	a2,s0,-112
    80005d90:	894e                	mv	s2,s3
    80005d92:	bf55                	j	80005d46 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005d94:	f9042503          	lw	a0,-112(s0)
    80005d98:	00451693          	slli	a3,a0,0x4

  if(write)
    80005d9c:	0001c797          	auipc	a5,0x1c
    80005da0:	4bc78793          	addi	a5,a5,1212 # 80022258 <disk>
    80005da4:	00a50713          	addi	a4,a0,10
    80005da8:	0712                	slli	a4,a4,0x4
    80005daa:	973e                	add	a4,a4,a5
    80005dac:	01703633          	snez	a2,s7
    80005db0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005db2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005db6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005dba:	6398                	ld	a4,0(a5)
    80005dbc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005dbe:	0a868613          	addi	a2,a3,168
    80005dc2:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005dc4:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005dc6:	6390                	ld	a2,0(a5)
    80005dc8:	00d605b3          	add	a1,a2,a3
    80005dcc:	4741                	li	a4,16
    80005dce:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005dd0:	4805                	li	a6,1
    80005dd2:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005dd6:	f9442703          	lw	a4,-108(s0)
    80005dda:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005dde:	0712                	slli	a4,a4,0x4
    80005de0:	963a                	add	a2,a2,a4
    80005de2:	058a0593          	addi	a1,s4,88
    80005de6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005de8:	0007b883          	ld	a7,0(a5)
    80005dec:	9746                	add	a4,a4,a7
    80005dee:	40000613          	li	a2,1024
    80005df2:	c710                	sw	a2,8(a4)
  if(write)
    80005df4:	001bb613          	seqz	a2,s7
    80005df8:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005dfc:	00166613          	ori	a2,a2,1
    80005e00:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005e04:	f9842583          	lw	a1,-104(s0)
    80005e08:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005e0c:	00250613          	addi	a2,a0,2
    80005e10:	0612                	slli	a2,a2,0x4
    80005e12:	963e                	add	a2,a2,a5
    80005e14:	577d                	li	a4,-1
    80005e16:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005e1a:	0592                	slli	a1,a1,0x4
    80005e1c:	98ae                	add	a7,a7,a1
    80005e1e:	03068713          	addi	a4,a3,48
    80005e22:	973e                	add	a4,a4,a5
    80005e24:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005e28:	6398                	ld	a4,0(a5)
    80005e2a:	972e                	add	a4,a4,a1
    80005e2c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005e30:	4689                	li	a3,2
    80005e32:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005e36:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005e3a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005e3e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005e42:	6794                	ld	a3,8(a5)
    80005e44:	0026d703          	lhu	a4,2(a3)
    80005e48:	8b1d                	andi	a4,a4,7
    80005e4a:	0706                	slli	a4,a4,0x1
    80005e4c:	96ba                	add	a3,a3,a4
    80005e4e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005e52:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005e56:	6798                	ld	a4,8(a5)
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
    80005e6e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005e72:	0001c917          	auipc	s2,0x1c
    80005e76:	50e90913          	addi	s2,s2,1294 # 80022380 <disk+0x128>
  while(b->disk == 1) {
    80005e7a:	4485                	li	s1,1
    80005e7c:	01079a63          	bne	a5,a6,80005e90 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005e80:	85ca                	mv	a1,s2
    80005e82:	8552                	mv	a0,s4
    80005e84:	b1afc0ef          	jal	8000219e <sleep>
  while(b->disk == 1) {
    80005e88:	004a2783          	lw	a5,4(s4)
    80005e8c:	fe978ae3          	beq	a5,s1,80005e80 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005e90:	f9042903          	lw	s2,-112(s0)
    80005e94:	00290713          	addi	a4,s2,2
    80005e98:	0712                	slli	a4,a4,0x4
    80005e9a:	0001c797          	auipc	a5,0x1c
    80005e9e:	3be78793          	addi	a5,a5,958 # 80022258 <disk>
    80005ea2:	97ba                	add	a5,a5,a4
    80005ea4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005ea8:	0001c997          	auipc	s3,0x1c
    80005eac:	3b098993          	addi	s3,s3,944 # 80022258 <disk>
    80005eb0:	00491713          	slli	a4,s2,0x4
    80005eb4:	0009b783          	ld	a5,0(s3)
    80005eb8:	97ba                	add	a5,a5,a4
    80005eba:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005ec4:	bafff0ef          	jal	80005a72 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005ec8:	8885                	andi	s1,s1,1
    80005eca:	f0fd                	bnez	s1,80005eb0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005ecc:	0001c517          	auipc	a0,0x1c
    80005ed0:	4b450513          	addi	a0,a0,1204 # 80022380 <disk+0x128>
    80005ed4:	d93fa0ef          	jal	80000c66 <release>
}
    80005ed8:	70a6                	ld	ra,104(sp)
    80005eda:	7406                	ld	s0,96(sp)
    80005edc:	64e6                	ld	s1,88(sp)
    80005ede:	6946                	ld	s2,80(sp)
    80005ee0:	69a6                	ld	s3,72(sp)
    80005ee2:	6a06                	ld	s4,64(sp)
    80005ee4:	7ae2                	ld	s5,56(sp)
    80005ee6:	7b42                	ld	s6,48(sp)
    80005ee8:	7ba2                	ld	s7,40(sp)
    80005eea:	7c02                	ld	s8,32(sp)
    80005eec:	6ce2                	ld	s9,24(sp)
    80005eee:	6165                	addi	sp,sp,112
    80005ef0:	8082                	ret

0000000080005ef2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005efc:	0001c497          	auipc	s1,0x1c
    80005f00:	35c48493          	addi	s1,s1,860 # 80022258 <disk>
    80005f04:	0001c517          	auipc	a0,0x1c
    80005f08:	47c50513          	addi	a0,a0,1148 # 80022380 <disk+0x128>
    80005f0c:	cc3fa0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	53b8                	lw	a4,96(a5)
    80005f16:	8b0d                	andi	a4,a4,3
    80005f18:	100017b7          	lui	a5,0x10001
    80005f1c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005f1e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005f22:	689c                	ld	a5,16(s1)
    80005f24:	0204d703          	lhu	a4,32(s1)
    80005f28:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005f2c:	04f70663          	beq	a4,a5,80005f78 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005f30:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005f34:	6898                	ld	a4,16(s1)
    80005f36:	0204d783          	lhu	a5,32(s1)
    80005f3a:	8b9d                	andi	a5,a5,7
    80005f3c:	078e                	slli	a5,a5,0x3
    80005f3e:	97ba                	add	a5,a5,a4
    80005f40:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005f42:	00278713          	addi	a4,a5,2
    80005f46:	0712                	slli	a4,a4,0x4
    80005f48:	9726                	add	a4,a4,s1
    80005f4a:	01074703          	lbu	a4,16(a4)
    80005f4e:	e321                	bnez	a4,80005f8e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005f50:	0789                	addi	a5,a5,2
    80005f52:	0792                	slli	a5,a5,0x4
    80005f54:	97a6                	add	a5,a5,s1
    80005f56:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005f58:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005f5c:	a92fc0ef          	jal	800021ee <wakeup>

    disk.used_idx += 1;
    80005f60:	0204d783          	lhu	a5,32(s1)
    80005f64:	2785                	addiw	a5,a5,1
    80005f66:	17c2                	slli	a5,a5,0x30
    80005f68:	93c1                	srli	a5,a5,0x30
    80005f6a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005f6e:	6898                	ld	a4,16(s1)
    80005f70:	00275703          	lhu	a4,2(a4)
    80005f74:	faf71ee3          	bne	a4,a5,80005f30 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005f78:	0001c517          	auipc	a0,0x1c
    80005f7c:	40850513          	addi	a0,a0,1032 # 80022380 <disk+0x128>
    80005f80:	ce7fa0ef          	jal	80000c66 <release>
}
    80005f84:	60e2                	ld	ra,24(sp)
    80005f86:	6442                	ld	s0,16(sp)
    80005f88:	64a2                	ld	s1,8(sp)
    80005f8a:	6105                	addi	sp,sp,32
    80005f8c:	8082                	ret
      panic("virtio_disk_intr status");
    80005f8e:	00001517          	auipc	a0,0x1
    80005f92:	77a50513          	addi	a0,a0,1914 # 80007708 <etext+0x708>
    80005f96:	84bfa0ef          	jal	800007e0 <panic>
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
