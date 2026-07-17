
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
    80000004:	88010113          	addi	sp,sp,-1920 # 80007880 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc477>
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
    80000112:	24e020ef          	jal	80002360 <either_copyin>
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
    80000190:	6f450513          	addi	a0,a0,1780 # 8000f880 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	0000f497          	auipc	s1,0xf
    8000019c:	6e848493          	addi	s1,s1,1768 # 8000f880 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	0000f917          	auipc	s2,0xf
    800001a4:	77890913          	addi	s2,s2,1912 # 8000f918 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	716010ef          	jal	800018ce <myproc>
    800001bc:	036020ef          	jal	800021f2 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	5f1010ef          	jal	80001fb6 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	0000f717          	auipc	a4,0xf
    800001dc:	6a870713          	addi	a4,a4,1704 # 8000f880 <cons>
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
    8000020a:	10c020ef          	jal	80002316 <either_copyout>
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
    80000226:	65e50513          	addi	a0,a0,1630 # 8000f880 <cons>
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
    80000250:	6cf72623          	sw	a5,1740(a4) # 8000f918 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	0000f517          	auipc	a0,0xf
    80000266:	61e50513          	addi	a0,a0,1566 # 8000f880 <cons>
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
    800002ba:	5ca50513          	addi	a0,a0,1482 # 8000f880 <cons>
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
    800002d8:	0d2020ef          	jal	800023aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	0000f517          	auipc	a0,0xf
    800002e0:	5a450513          	addi	a0,a0,1444 # 8000f880 <cons>
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
    800002fe:	58670713          	addi	a4,a4,1414 # 8000f880 <cons>
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
    80000324:	56078793          	addi	a5,a5,1376 # 8000f880 <cons>
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
    80000352:	5ca7a783          	lw	a5,1482(a5) # 8000f918 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	0000f717          	auipc	a4,0xf
    80000368:	51c70713          	addi	a4,a4,1308 # 8000f880 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	0000f497          	auipc	s1,0xf
    80000378:	50c48493          	addi	s1,s1,1292 # 8000f880 <cons>
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
    800003ba:	4ca70713          	addi	a4,a4,1226 # 8000f880 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	0000f717          	auipc	a4,0xf
    800003d0:	54f72a23          	sw	a5,1364(a4) # 8000f920 <cons+0xa0>
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
    800003ee:	49678793          	addi	a5,a5,1174 # 8000f880 <cons>
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
    80000412:	50c7a723          	sw	a2,1294(a5) # 8000f91c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	0000f517          	auipc	a0,0xf
    8000041a:	50250513          	addi	a0,a0,1282 # 8000f918 <cons+0x98>
    8000041e:	3e9010ef          	jal	80002006 <wakeup>
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
    80000438:	44c50513          	addi	a0,a0,1100 # 8000f880 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00021797          	auipc	a5,0x21
    80000448:	dac78793          	addi	a5,a5,-596 # 800211f0 <devsw>
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
    80000518:	00007797          	auipc	a5,0x7
    8000051c:	32c7a783          	lw	a5,812(a5) # 80007844 <panicking>
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
    80000564:	3c850513          	addi	a0,a0,968 # 8000f928 <pr>
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
    800007bc:	00007797          	auipc	a5,0x7
    800007c0:	0887a783          	lw	a5,136(a5) # 80007844 <panicking>
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
    800007d6:	15650513          	addi	a0,a0,342 # 8000f928 <pr>
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
    800007f4:	0527aa23          	sw	s2,84(a5) # 80007844 <panicking>
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
    80000816:	0327a723          	sw	s2,46(a5) # 80007840 <panicked>
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
    80000830:	0fc50513          	addi	a0,a0,252 # 8000f928 <pr>
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
    80000888:	0bc50513          	addi	a0,a0,188 # 8000f940 <tx_lock>
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
    800008ac:	09850513          	addi	a0,a0,152 # 8000f940 <tx_lock>
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
    800008ca:	f8648493          	addi	s1,s1,-122 # 8000784c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	0000f997          	auipc	s3,0xf
    800008d2:	07298993          	addi	s3,s3,114 # 8000f940 <tx_lock>
    800008d6:	00007917          	auipc	s2,0x7
    800008da:	f7290913          	addi	s2,s2,-142 # 80007848 <tx_chan>
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
    800008ea:	6cc010ef          	jal	80001fb6 <sleep>
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
    80000918:	02c50513          	addi	a0,a0,44 # 8000f940 <tx_lock>
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
    8000093c:	f0c7a783          	lw	a5,-244(a5) # 80007844 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	00007797          	auipc	a5,0x7
    80000946:	efe7a783          	lw	a5,-258(a5) # 80007840 <panicked>
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
    8000096c:	edc7a783          	lw	a5,-292(a5) # 80007844 <panicking>
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
    800009c8:	f7c50513          	addi	a0,a0,-132 # 8000f940 <tx_lock>
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
    800009e4:	f6050513          	addi	a0,a0,-160 # 8000f940 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	00007797          	auipc	a5,0x7
    800009f4:	e407ae23          	sw	zero,-420(a5) # 8000784c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	00007517          	auipc	a0,0x7
    800009fc:	e5050513          	addi	a0,a0,-432 # 80007848 <tx_chan>
    80000a00:	606010ef          	jal	80002006 <wakeup>
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
    80000a34:	95878793          	addi	a5,a5,-1704 # 80022388 <end>
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
    80000a50:	f0c90913          	addi	s2,s2,-244 # 8000f958 <kmem>
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
    80000ade:	e7e50513          	addi	a0,a0,-386 # 8000f958 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00022517          	auipc	a0,0x22
    80000aee:	89e50513          	addi	a0,a0,-1890 # 80022388 <end>
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
    80000b0c:	e5048493          	addi	s1,s1,-432 # 8000f958 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	0000f517          	auipc	a0,0xf
    80000b20:	e3c50513          	addi	a0,a0,-452 # 8000f958 <kmem>
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
    80000b44:	e1850513          	addi	a0,a0,-488 # 8000f958 <kmem>
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
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcc79>
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
    80000e4c:	a0870713          	addi	a4,a4,-1528 # 80007850 <started>
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
    80000e72:	6f2010ef          	jal	80002564 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	113040ef          	jal	80005788 <plicinithart>
  }

  scheduler();        
    80000e7a:	73f000ef          	jal	80001db8 <scheduler>
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
    80000eba:	686010ef          	jal	80002540 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	6a6010ef          	jal	80002564 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	0ad040ef          	jal	8000576e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	0c3040ef          	jal	80005788 <plicinithart>
    binit();         // buffer cache
    80000eca:	78b010ef          	jal	80002e54 <binit>
    iinit();         // inode table
    80000ece:	510020ef          	jal	800033de <iinit>
    fileinit();      // file table
    80000ed2:	402030ef          	jal	800042d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	1a3040ef          	jal	80005878 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	533000ef          	jal	80001c0c <userinit>
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00007717          	auipc	a4,0x7
    80000ee8:	96f72623          	sw	a5,-1684(a4) # 80007850 <started>
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
    80000efc:	9607b783          	ld	a5,-1696(a5) # 80007858 <kernel_pagetable>
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
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcc6f>
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
    80001188:	6ca7ba23          	sd	a0,1748(a5) # 80007858 <kernel_pagetable>
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
    8000176e:	63e48493          	addi	s1,s1,1598 # 8000fda8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	ff048937          	lui	s2,0xff048
    80001778:	dc190913          	addi	s2,s2,-575 # ffffffffff047dc1 <end+0xffffffff7f025a39>
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
    8000179a:	812a8a93          	addi	s5,s5,-2030 # 80016fa8 <tickslock>
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
    8000180c:	17050513          	addi	a0,a0,368 # 8000f978 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	95458593          	addi	a1,a1,-1708 # 80007168 <etext+0x168>
    8000181c:	0000e517          	auipc	a0,0xe
    80001820:	17450513          	addi	a0,a0,372 # 8000f990 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001828:	0000e497          	auipc	s1,0xe
    8000182c:	58048493          	addi	s1,s1,1408 # 8000fda8 <proc>
      initlock(&p->lock, "proc");
    80001830:	00006b17          	auipc	s6,0x6
    80001834:	948b0b13          	addi	s6,s6,-1720 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001838:	8aa6                	mv	s5,s1
    8000183a:	ff048937          	lui	s2,0xff048
    8000183e:	dc190913          	addi	s2,s2,-575 # ffffffffff047dc1 <end+0xffffffff7f025a39>
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
    80001860:	74ca0a13          	addi	s4,s4,1868 # 80016fa8 <tickslock>
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
    8000187a:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdcc79>
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
    800018c2:	0ea50513          	addi	a0,a0,234 # 8000f9a8 <cpus>
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
    800018e6:	09670713          	addi	a4,a4,150 # 8000f978 <pid_lock>
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
    80001916:	f1e7a783          	lw	a5,-226(a5) # 80007830 <first.1>
    8000191a:	cf8d                	beqz	a5,80001954 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000191c:	4505                	li	a0,1
    8000191e:	77d010ef          	jal	8000389a <fsinit>

    first = 0;
    80001922:	00006797          	auipc	a5,0x6
    80001926:	f007a723          	sw	zero,-242(a5) # 80007830 <first.1>
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
    80001942:	062030ef          	jal	800049a4 <kexec>
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
    80001954:	429000ef          	jal	8000257c <prepare_return>
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
    800019a6:	fd690913          	addi	s2,s2,-42 # 8000f978 <pid_lock>
    800019aa:	854a                	mv	a0,s2
    800019ac:	a22ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019b0:	00006797          	auipc	a5,0x6
    800019b4:	e8478793          	addi	a5,a5,-380 # 80007834 <nextpid>
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
    80001b32:	27a48493          	addi	s1,s1,634 # 8000fda8 <proc>
    80001b36:	00015917          	auipc	s2,0x15
    80001b3a:	47290913          	addi	s2,s2,1138 # 80016fa8 <tickslock>
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
    80001c20:	c4a7b623          	sd	a0,-948(a5) # 80007868 <initproc>
  p->cwd = namei("/");
    80001c24:	00005517          	auipc	a0,0x5
    80001c28:	56c50513          	addi	a0,a0,1388 # 80007190 <etext+0x190>
    80001c2c:	190020ef          	jal	80003dbc <namei>
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
    80001d48:	60e020ef          	jal	80004356 <filedup>
    80001d4c:	00a93023          	sd	a0,0(s2)
    80001d50:	b7f5                	j	80001d3c <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d52:	150ab503          	ld	a0,336(s5)
    80001d56:	01b010ef          	jal	80003570 <idup>
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
    80001d7a:	c1a48493          	addi	s1,s1,-998 # 8000f990 <wait_lock>
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

0000000080001db8 <scheduler>:
{
    80001db8:	7119                	addi	sp,sp,-128
    80001dba:	fc86                	sd	ra,120(sp)
    80001dbc:	f8a2                	sd	s0,112(sp)
    80001dbe:	f4a6                	sd	s1,104(sp)
    80001dc0:	f0ca                	sd	s2,96(sp)
    80001dc2:	ecce                	sd	s3,88(sp)
    80001dc4:	e8d2                	sd	s4,80(sp)
    80001dc6:	e4d6                	sd	s5,72(sp)
    80001dc8:	e0da                	sd	s6,64(sp)
    80001dca:	fc5e                	sd	s7,56(sp)
    80001dcc:	f862                	sd	s8,48(sp)
    80001dce:	f466                	sd	s9,40(sp)
    80001dd0:	f06a                	sd	s10,32(sp)
    80001dd2:	ec6e                	sd	s11,24(sp)
    80001dd4:	0100                	addi	s0,sp,128
    80001dd6:	8792                	mv	a5,tp
  int id = r_tp();
    80001dd8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001dda:	00779693          	slli	a3,a5,0x7
    80001dde:	0000e717          	auipc	a4,0xe
    80001de2:	b9a70713          	addi	a4,a4,-1126 # 8000f978 <pid_lock>
    80001de6:	9736                	add	a4,a4,a3
    80001de8:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001dec:	0000e717          	auipc	a4,0xe
    80001df0:	bc470713          	addi	a4,a4,-1084 # 8000f9b0 <cpus+0x8>
    80001df4:	9736                	add	a4,a4,a3
    80001df6:	f8e43423          	sd	a4,-120(s0)
        p = &proc[idx];
    80001dfa:	0000eb17          	auipc	s6,0xe
    80001dfe:	faeb0b13          	addi	s6,s6,-82 # 8000fda8 <proc>
          c->proc = p;
    80001e02:	0000e717          	auipc	a4,0xe
    80001e06:	b7670713          	addi	a4,a4,-1162 # 8000f978 <pid_lock>
    80001e0a:	00d707b3          	add	a5,a4,a3
    80001e0e:	f8f43023          	sd	a5,-128(s0)
    80001e12:	a865                	j	80001eca <scheduler+0x112>
        release(&p->lock);
    80001e14:	854a                	mv	a0,s2
    80001e16:	e51fe0ef          	jal	80000c66 <release>
      for(int i = 0; i < NPROC; i++) {
    80001e1a:	2985                	addiw	s3,s3,1
    80001e1c:	0ba98163          	beq	s3,s10,80001ebe <scheduler+0x106>
        int idx = (last_idx + 1 + i) % NPROC;
    80001e20:	000ca483          	lw	s1,0(s9)
    80001e24:	2485                	addiw	s1,s1,1
    80001e26:	013484bb          	addw	s1,s1,s3
    80001e2a:	41f4d79b          	sraiw	a5,s1,0x1f
    80001e2e:	01a7d79b          	srliw	a5,a5,0x1a
    80001e32:	9cbd                	addw	s1,s1,a5
    80001e34:	03f4f493          	andi	s1,s1,63
    80001e38:	9c9d                	subw	s1,s1,a5
    80001e3a:	00048a1b          	sext.w	s4,s1
        p = &proc[idx];
    80001e3e:	037a0ab3          	mul	s5,s4,s7
    80001e42:	016a8933          	add	s2,s5,s6
        acquire(&p->lock);
    80001e46:	854a                	mv	a0,s2
    80001e48:	d87fe0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE && p->priority == pr) {
    80001e4c:	01892783          	lw	a5,24(s2)
    80001e50:	fd8792e3          	bne	a5,s8,80001e14 <scheduler+0x5c>
    80001e54:	16892783          	lw	a5,360(s2)
    80001e58:	fbb79ee3          	bne	a5,s11,80001e14 <scheduler+0x5c>
          p->state = RUNNING;
    80001e5c:	1c800793          	li	a5,456
    80001e60:	02fa0a33          	mul	s4,s4,a5
    80001e64:	9a5a                	add	s4,s4,s6
    80001e66:	4791                	li	a5,4
    80001e68:	00fa2c23          	sw	a5,24(s4)
          c->proc = p;
    80001e6c:	f8043983          	ld	s3,-128(s0)
    80001e70:	0329b823          	sd	s2,48(s3)
          last_idx = idx;
    80001e74:	00006797          	auipc	a5,0x6
    80001e78:	9e97a623          	sw	s1,-1556(a5) # 80007860 <last_idx.2>
          swtch(&c->context, &p->context);
    80001e7c:	060a8593          	addi	a1,s5,96
    80001e80:	95da                	add	a1,a1,s6
    80001e82:	f8843503          	ld	a0,-120(s0)
    80001e86:	650000ef          	jal	800024d6 <swtch>
          c->proc = 0;
    80001e8a:	0209b823          	sd	zero,48(s3)
          release(&p->lock);
    80001e8e:	854a                	mv	a0,s2
    80001e90:	dd7fe0ef          	jal	80000c66 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e9c:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ea0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001ea4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ea6:	10079073          	csrw	sstatus,a5
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    80001eaa:	4d81                	li	s11,0
        int idx = (last_idx + 1 + i) % NPROC;
    80001eac:	00006c97          	auipc	s9,0x6
    80001eb0:	9b4c8c93          	addi	s9,s9,-1612 # 80007860 <last_idx.2>
    80001eb4:	1c800b93          	li	s7,456
      for(int i = 0; i < NPROC; i++) {
    80001eb8:	4981                	li	s3,0
        if(p->state == RUNNABLE && p->priority == pr) {
    80001eba:	4c0d                	li	s8,3
    80001ebc:	b795                	j	80001e20 <scheduler+0x68>
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    80001ebe:	2d85                	addiw	s11,s11,1
    80001ec0:	478d                	li	a5,3
    80001ec2:	fefd9be3          	bne	s11,a5,80001eb8 <scheduler+0x100>
      asm volatile("wfi");
    80001ec6:	10500073          	wfi
      for(int i = 0; i < NPROC; i++) {
    80001eca:	04000d13          	li	s10,64
    80001ece:	b7d9                	j	80001e94 <scheduler+0xdc>

0000000080001ed0 <sched>:
{
    80001ed0:	7179                	addi	sp,sp,-48
    80001ed2:	f406                	sd	ra,40(sp)
    80001ed4:	f022                	sd	s0,32(sp)
    80001ed6:	ec26                	sd	s1,24(sp)
    80001ed8:	e84a                	sd	s2,16(sp)
    80001eda:	e44e                	sd	s3,8(sp)
    80001edc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ede:	9f1ff0ef          	jal	800018ce <myproc>
    80001ee2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ee4:	c81fe0ef          	jal	80000b64 <holding>
    80001ee8:	c92d                	beqz	a0,80001f5a <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001eea:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001eec:	2781                	sext.w	a5,a5
    80001eee:	079e                	slli	a5,a5,0x7
    80001ef0:	0000e717          	auipc	a4,0xe
    80001ef4:	a8870713          	addi	a4,a4,-1400 # 8000f978 <pid_lock>
    80001ef8:	97ba                	add	a5,a5,a4
    80001efa:	0a87a703          	lw	a4,168(a5)
    80001efe:	4785                	li	a5,1
    80001f00:	06f71363          	bne	a4,a5,80001f66 <sched+0x96>
  if(p->state == RUNNING)
    80001f04:	4c98                	lw	a4,24(s1)
    80001f06:	4791                	li	a5,4
    80001f08:	06f70563          	beq	a4,a5,80001f72 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f10:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f12:	e7b5                	bnez	a5,80001f7e <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f14:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f16:	0000e917          	auipc	s2,0xe
    80001f1a:	a6290913          	addi	s2,s2,-1438 # 8000f978 <pid_lock>
    80001f1e:	2781                	sext.w	a5,a5
    80001f20:	079e                	slli	a5,a5,0x7
    80001f22:	97ca                	add	a5,a5,s2
    80001f24:	0ac7a983          	lw	s3,172(a5)
    80001f28:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f2a:	2781                	sext.w	a5,a5
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	0000e597          	auipc	a1,0xe
    80001f32:	a8258593          	addi	a1,a1,-1406 # 8000f9b0 <cpus+0x8>
    80001f36:	95be                	add	a1,a1,a5
    80001f38:	06048513          	addi	a0,s1,96
    80001f3c:	59a000ef          	jal	800024d6 <swtch>
    80001f40:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f42:	2781                	sext.w	a5,a5
    80001f44:	079e                	slli	a5,a5,0x7
    80001f46:	993e                	add	s2,s2,a5
    80001f48:	0b392623          	sw	s3,172(s2)
}
    80001f4c:	70a2                	ld	ra,40(sp)
    80001f4e:	7402                	ld	s0,32(sp)
    80001f50:	64e2                	ld	s1,24(sp)
    80001f52:	6942                	ld	s2,16(sp)
    80001f54:	69a2                	ld	s3,8(sp)
    80001f56:	6145                	addi	sp,sp,48
    80001f58:	8082                	ret
    panic("sched p->lock");
    80001f5a:	00005517          	auipc	a0,0x5
    80001f5e:	23e50513          	addi	a0,a0,574 # 80007198 <etext+0x198>
    80001f62:	87ffe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001f66:	00005517          	auipc	a0,0x5
    80001f6a:	24250513          	addi	a0,a0,578 # 800071a8 <etext+0x1a8>
    80001f6e:	873fe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001f72:	00005517          	auipc	a0,0x5
    80001f76:	24650513          	addi	a0,a0,582 # 800071b8 <etext+0x1b8>
    80001f7a:	867fe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f7e:	00005517          	auipc	a0,0x5
    80001f82:	24a50513          	addi	a0,a0,586 # 800071c8 <etext+0x1c8>
    80001f86:	85bfe0ef          	jal	800007e0 <panic>

0000000080001f8a <yield>:
{
    80001f8a:	1101                	addi	sp,sp,-32
    80001f8c:	ec06                	sd	ra,24(sp)
    80001f8e:	e822                	sd	s0,16(sp)
    80001f90:	e426                	sd	s1,8(sp)
    80001f92:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f94:	93bff0ef          	jal	800018ce <myproc>
    80001f98:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f9a:	c35fe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80001f9e:	478d                	li	a5,3
    80001fa0:	cc9c                	sw	a5,24(s1)
  sched();
    80001fa2:	f2fff0ef          	jal	80001ed0 <sched>
  release(&p->lock);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	cbffe0ef          	jal	80000c66 <release>
}
    80001fac:	60e2                	ld	ra,24(sp)
    80001fae:	6442                	ld	s0,16(sp)
    80001fb0:	64a2                	ld	s1,8(sp)
    80001fb2:	6105                	addi	sp,sp,32
    80001fb4:	8082                	ret

0000000080001fb6 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001fb6:	7179                	addi	sp,sp,-48
    80001fb8:	f406                	sd	ra,40(sp)
    80001fba:	f022                	sd	s0,32(sp)
    80001fbc:	ec26                	sd	s1,24(sp)
    80001fbe:	e84a                	sd	s2,16(sp)
    80001fc0:	e44e                	sd	s3,8(sp)
    80001fc2:	1800                	addi	s0,sp,48
    80001fc4:	89aa                	mv	s3,a0
    80001fc6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fc8:	907ff0ef          	jal	800018ce <myproc>
    80001fcc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001fce:	c01fe0ef          	jal	80000bce <acquire>
  release(lk);
    80001fd2:	854a                	mv	a0,s2
    80001fd4:	c93fe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80001fd8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001fdc:	4789                	li	a5,2
    80001fde:	cc9c                	sw	a5,24(s1)
  p->ticks_used = 0; // Đặt lại để khi thức dậy có quantum đầy đủ
    80001fe0:	1604a623          	sw	zero,364(s1)

  sched();
    80001fe4:	eedff0ef          	jal	80001ed0 <sched>

  // Tidy up.
  p->chan = 0;
    80001fe8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001fec:	8526                	mv	a0,s1
    80001fee:	c79fe0ef          	jal	80000c66 <release>
  acquire(lk);
    80001ff2:	854a                	mv	a0,s2
    80001ff4:	bdbfe0ef          	jal	80000bce <acquire>
}
    80001ff8:	70a2                	ld	ra,40(sp)
    80001ffa:	7402                	ld	s0,32(sp)
    80001ffc:	64e2                	ld	s1,24(sp)
    80001ffe:	6942                	ld	s2,16(sp)
    80002000:	69a2                	ld	s3,8(sp)
    80002002:	6145                	addi	sp,sp,48
    80002004:	8082                	ret

0000000080002006 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80002006:	7139                	addi	sp,sp,-64
    80002008:	fc06                	sd	ra,56(sp)
    8000200a:	f822                	sd	s0,48(sp)
    8000200c:	f426                	sd	s1,40(sp)
    8000200e:	f04a                	sd	s2,32(sp)
    80002010:	ec4e                	sd	s3,24(sp)
    80002012:	e852                	sd	s4,16(sp)
    80002014:	e456                	sd	s5,8(sp)
    80002016:	0080                	addi	s0,sp,64
    80002018:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000201a:	0000e497          	auipc	s1,0xe
    8000201e:	d8e48493          	addi	s1,s1,-626 # 8000fda8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002022:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002024:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002026:	00015917          	auipc	s2,0x15
    8000202a:	f8290913          	addi	s2,s2,-126 # 80016fa8 <tickslock>
    8000202e:	a801                	j	8000203e <wakeup+0x38>
      }
      release(&p->lock);
    80002030:	8526                	mv	a0,s1
    80002032:	c35fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	1c848493          	addi	s1,s1,456
    8000203a:	03248263          	beq	s1,s2,8000205e <wakeup+0x58>
    if(p != myproc()){
    8000203e:	891ff0ef          	jal	800018ce <myproc>
    80002042:	fea48ae3          	beq	s1,a0,80002036 <wakeup+0x30>
      acquire(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	b87fe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000204c:	4c9c                	lw	a5,24(s1)
    8000204e:	ff3791e3          	bne	a5,s3,80002030 <wakeup+0x2a>
    80002052:	709c                	ld	a5,32(s1)
    80002054:	fd479ee3          	bne	a5,s4,80002030 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002058:	0154ac23          	sw	s5,24(s1)
    8000205c:	bfd1                	j	80002030 <wakeup+0x2a>
    }
  }
}
    8000205e:	70e2                	ld	ra,56(sp)
    80002060:	7442                	ld	s0,48(sp)
    80002062:	74a2                	ld	s1,40(sp)
    80002064:	7902                	ld	s2,32(sp)
    80002066:	69e2                	ld	s3,24(sp)
    80002068:	6a42                	ld	s4,16(sp)
    8000206a:	6aa2                	ld	s5,8(sp)
    8000206c:	6121                	addi	sp,sp,64
    8000206e:	8082                	ret

0000000080002070 <reparent>:
{
    80002070:	7179                	addi	sp,sp,-48
    80002072:	f406                	sd	ra,40(sp)
    80002074:	f022                	sd	s0,32(sp)
    80002076:	ec26                	sd	s1,24(sp)
    80002078:	e84a                	sd	s2,16(sp)
    8000207a:	e44e                	sd	s3,8(sp)
    8000207c:	e052                	sd	s4,0(sp)
    8000207e:	1800                	addi	s0,sp,48
    80002080:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002082:	0000e497          	auipc	s1,0xe
    80002086:	d2648493          	addi	s1,s1,-730 # 8000fda8 <proc>
      pp->parent = initproc;
    8000208a:	00005a17          	auipc	s4,0x5
    8000208e:	7dea0a13          	addi	s4,s4,2014 # 80007868 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002092:	00015997          	auipc	s3,0x15
    80002096:	f1698993          	addi	s3,s3,-234 # 80016fa8 <tickslock>
    8000209a:	a029                	j	800020a4 <reparent+0x34>
    8000209c:	1c848493          	addi	s1,s1,456
    800020a0:	01348b63          	beq	s1,s3,800020b6 <reparent+0x46>
    if(pp->parent == p){
    800020a4:	7c9c                	ld	a5,56(s1)
    800020a6:	ff279be3          	bne	a5,s2,8000209c <reparent+0x2c>
      pp->parent = initproc;
    800020aa:	000a3503          	ld	a0,0(s4)
    800020ae:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800020b0:	f57ff0ef          	jal	80002006 <wakeup>
    800020b4:	b7e5                	j	8000209c <reparent+0x2c>
}
    800020b6:	70a2                	ld	ra,40(sp)
    800020b8:	7402                	ld	s0,32(sp)
    800020ba:	64e2                	ld	s1,24(sp)
    800020bc:	6942                	ld	s2,16(sp)
    800020be:	69a2                	ld	s3,8(sp)
    800020c0:	6a02                	ld	s4,0(sp)
    800020c2:	6145                	addi	sp,sp,48
    800020c4:	8082                	ret

00000000800020c6 <kexit>:
{
    800020c6:	7179                	addi	sp,sp,-48
    800020c8:	f406                	sd	ra,40(sp)
    800020ca:	f022                	sd	s0,32(sp)
    800020cc:	ec26                	sd	s1,24(sp)
    800020ce:	e84a                	sd	s2,16(sp)
    800020d0:	e44e                	sd	s3,8(sp)
    800020d2:	e052                	sd	s4,0(sp)
    800020d4:	1800                	addi	s0,sp,48
    800020d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020d8:	ff6ff0ef          	jal	800018ce <myproc>
    800020dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800020de:	00005797          	auipc	a5,0x5
    800020e2:	78a7b783          	ld	a5,1930(a5) # 80007868 <initproc>
    800020e6:	0d050493          	addi	s1,a0,208
    800020ea:	15050913          	addi	s2,a0,336
    800020ee:	00a79f63          	bne	a5,a0,8000210c <kexit+0x46>
    panic("init exiting");
    800020f2:	00005517          	auipc	a0,0x5
    800020f6:	0ee50513          	addi	a0,a0,238 # 800071e0 <etext+0x1e0>
    800020fa:	ee6fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    800020fe:	29e020ef          	jal	8000439c <fileclose>
      p->ofile[fd] = 0;
    80002102:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002106:	04a1                	addi	s1,s1,8
    80002108:	01248563          	beq	s1,s2,80002112 <kexit+0x4c>
    if(p->ofile[fd]){
    8000210c:	6088                	ld	a0,0(s1)
    8000210e:	f965                	bnez	a0,800020fe <kexit+0x38>
    80002110:	bfdd                	j	80002106 <kexit+0x40>
  begin_op();
    80002112:	67f010ef          	jal	80003f90 <begin_op>
  iput(p->cwd);
    80002116:	1509b503          	ld	a0,336(s3)
    8000211a:	60e010ef          	jal	80003728 <iput>
  end_op();
    8000211e:	6dd010ef          	jal	80003ffa <end_op>
  p->cwd = 0;
    80002122:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002126:	0000e497          	auipc	s1,0xe
    8000212a:	86a48493          	addi	s1,s1,-1942 # 8000f990 <wait_lock>
    8000212e:	8526                	mv	a0,s1
    80002130:	a9ffe0ef          	jal	80000bce <acquire>
  reparent(p);
    80002134:	854e                	mv	a0,s3
    80002136:	f3bff0ef          	jal	80002070 <reparent>
  wakeup(p->parent);
    8000213a:	0389b503          	ld	a0,56(s3)
    8000213e:	ec9ff0ef          	jal	80002006 <wakeup>
  acquire(&p->lock);
    80002142:	854e                	mv	a0,s3
    80002144:	a8bfe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    80002148:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000214c:	4795                	li	a5,5
    8000214e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002152:	8526                	mv	a0,s1
    80002154:	b13fe0ef          	jal	80000c66 <release>
  sched();
    80002158:	d79ff0ef          	jal	80001ed0 <sched>
  panic("zombie exit");
    8000215c:	00005517          	auipc	a0,0x5
    80002160:	09450513          	addi	a0,a0,148 # 800071f0 <etext+0x1f0>
    80002164:	e7cfe0ef          	jal	800007e0 <panic>

0000000080002168 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	1800                	addi	s0,sp,48
    80002176:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002178:	0000e497          	auipc	s1,0xe
    8000217c:	c3048493          	addi	s1,s1,-976 # 8000fda8 <proc>
    80002180:	00015997          	auipc	s3,0x15
    80002184:	e2898993          	addi	s3,s3,-472 # 80016fa8 <tickslock>
    acquire(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	a45fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    8000218e:	589c                	lw	a5,48(s1)
    80002190:	01278b63          	beq	a5,s2,800021a6 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	ad1fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000219a:	1c848493          	addi	s1,s1,456
    8000219e:	ff3495e3          	bne	s1,s3,80002188 <kkill+0x20>
  }
  return -1;
    800021a2:	557d                	li	a0,-1
    800021a4:	a819                	j	800021ba <kkill+0x52>
      p->killed = 1;
    800021a6:	4785                	li	a5,1
    800021a8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800021aa:	4c98                	lw	a4,24(s1)
    800021ac:	4789                	li	a5,2
    800021ae:	00f70d63          	beq	a4,a5,800021c8 <kkill+0x60>
      release(&p->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	ab3fe0ef          	jal	80000c66 <release>
      return 0;
    800021b8:	4501                	li	a0,0
}
    800021ba:	70a2                	ld	ra,40(sp)
    800021bc:	7402                	ld	s0,32(sp)
    800021be:	64e2                	ld	s1,24(sp)
    800021c0:	6942                	ld	s2,16(sp)
    800021c2:	69a2                	ld	s3,8(sp)
    800021c4:	6145                	addi	sp,sp,48
    800021c6:	8082                	ret
        p->state = RUNNABLE;
    800021c8:	478d                	li	a5,3
    800021ca:	cc9c                	sw	a5,24(s1)
    800021cc:	b7dd                	j	800021b2 <kkill+0x4a>

00000000800021ce <setkilled>:

void
setkilled(struct proc *p)
{
    800021ce:	1101                	addi	sp,sp,-32
    800021d0:	ec06                	sd	ra,24(sp)
    800021d2:	e822                	sd	s0,16(sp)
    800021d4:	e426                	sd	s1,8(sp)
    800021d6:	1000                	addi	s0,sp,32
    800021d8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021da:	9f5fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    800021de:	4785                	li	a5,1
    800021e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	a83fe0ef          	jal	80000c66 <release>
}
    800021e8:	60e2                	ld	ra,24(sp)
    800021ea:	6442                	ld	s0,16(sp)
    800021ec:	64a2                	ld	s1,8(sp)
    800021ee:	6105                	addi	sp,sp,32
    800021f0:	8082                	ret

00000000800021f2 <killed>:

int
killed(struct proc *p)
{
    800021f2:	1101                	addi	sp,sp,-32
    800021f4:	ec06                	sd	ra,24(sp)
    800021f6:	e822                	sd	s0,16(sp)
    800021f8:	e426                	sd	s1,8(sp)
    800021fa:	e04a                	sd	s2,0(sp)
    800021fc:	1000                	addi	s0,sp,32
    800021fe:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002200:	9cffe0ef          	jal	80000bce <acquire>
  k = p->killed;
    80002204:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	a5dfe0ef          	jal	80000c66 <release>
  return k;
}
    8000220e:	854a                	mv	a0,s2
    80002210:	60e2                	ld	ra,24(sp)
    80002212:	6442                	ld	s0,16(sp)
    80002214:	64a2                	ld	s1,8(sp)
    80002216:	6902                	ld	s2,0(sp)
    80002218:	6105                	addi	sp,sp,32
    8000221a:	8082                	ret

000000008000221c <kwait>:
{
    8000221c:	715d                	addi	sp,sp,-80
    8000221e:	e486                	sd	ra,72(sp)
    80002220:	e0a2                	sd	s0,64(sp)
    80002222:	fc26                	sd	s1,56(sp)
    80002224:	f84a                	sd	s2,48(sp)
    80002226:	f44e                	sd	s3,40(sp)
    80002228:	f052                	sd	s4,32(sp)
    8000222a:	ec56                	sd	s5,24(sp)
    8000222c:	e85a                	sd	s6,16(sp)
    8000222e:	e45e                	sd	s7,8(sp)
    80002230:	e062                	sd	s8,0(sp)
    80002232:	0880                	addi	s0,sp,80
    80002234:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002236:	e98ff0ef          	jal	800018ce <myproc>
    8000223a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000223c:	0000d517          	auipc	a0,0xd
    80002240:	75450513          	addi	a0,a0,1876 # 8000f990 <wait_lock>
    80002244:	98bfe0ef          	jal	80000bce <acquire>
    havekids = 0;
    80002248:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000224a:	4a15                	li	s4,5
        havekids = 1;
    8000224c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000224e:	00015997          	auipc	s3,0x15
    80002252:	d5a98993          	addi	s3,s3,-678 # 80016fa8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002256:	0000dc17          	auipc	s8,0xd
    8000225a:	73ac0c13          	addi	s8,s8,1850 # 8000f990 <wait_lock>
    8000225e:	a871                	j	800022fa <kwait+0xde>
          pid = pp->pid;
    80002260:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002264:	000b0c63          	beqz	s6,8000227c <kwait+0x60>
    80002268:	4691                	li	a3,4
    8000226a:	02c48613          	addi	a2,s1,44
    8000226e:	85da                	mv	a1,s6
    80002270:	05093503          	ld	a0,80(s2)
    80002274:	b6eff0ef          	jal	800015e2 <copyout>
    80002278:	02054b63          	bltz	a0,800022ae <kwait+0x92>
          freeproc(pp);
    8000227c:	8526                	mv	a0,s1
    8000227e:	821ff0ef          	jal	80001a9e <freeproc>
          release(&pp->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	9e3fe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    80002288:	0000d517          	auipc	a0,0xd
    8000228c:	70850513          	addi	a0,a0,1800 # 8000f990 <wait_lock>
    80002290:	9d7fe0ef          	jal	80000c66 <release>
}
    80002294:	854e                	mv	a0,s3
    80002296:	60a6                	ld	ra,72(sp)
    80002298:	6406                	ld	s0,64(sp)
    8000229a:	74e2                	ld	s1,56(sp)
    8000229c:	7942                	ld	s2,48(sp)
    8000229e:	79a2                	ld	s3,40(sp)
    800022a0:	7a02                	ld	s4,32(sp)
    800022a2:	6ae2                	ld	s5,24(sp)
    800022a4:	6b42                	ld	s6,16(sp)
    800022a6:	6ba2                	ld	s7,8(sp)
    800022a8:	6c02                	ld	s8,0(sp)
    800022aa:	6161                	addi	sp,sp,80
    800022ac:	8082                	ret
            release(&pp->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	9b7fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    800022b4:	0000d517          	auipc	a0,0xd
    800022b8:	6dc50513          	addi	a0,a0,1756 # 8000f990 <wait_lock>
    800022bc:	9abfe0ef          	jal	80000c66 <release>
            return -1;
    800022c0:	59fd                	li	s3,-1
    800022c2:	bfc9                	j	80002294 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c4:	1c848493          	addi	s1,s1,456
    800022c8:	03348063          	beq	s1,s3,800022e8 <kwait+0xcc>
      if(pp->parent == p){
    800022cc:	7c9c                	ld	a5,56(s1)
    800022ce:	ff279be3          	bne	a5,s2,800022c4 <kwait+0xa8>
        acquire(&pp->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	8fbfe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800022d8:	4c9c                	lw	a5,24(s1)
    800022da:	f94783e3          	beq	a5,s4,80002260 <kwait+0x44>
        release(&pp->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	987fe0ef          	jal	80000c66 <release>
        havekids = 1;
    800022e4:	8756                	mv	a4,s5
    800022e6:	bff9                	j	800022c4 <kwait+0xa8>
    if(!havekids || killed(p)){
    800022e8:	cf19                	beqz	a4,80002306 <kwait+0xea>
    800022ea:	854a                	mv	a0,s2
    800022ec:	f07ff0ef          	jal	800021f2 <killed>
    800022f0:	e919                	bnez	a0,80002306 <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f2:	85e2                	mv	a1,s8
    800022f4:	854a                	mv	a0,s2
    800022f6:	cc1ff0ef          	jal	80001fb6 <sleep>
    havekids = 0;
    800022fa:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022fc:	0000e497          	auipc	s1,0xe
    80002300:	aac48493          	addi	s1,s1,-1364 # 8000fda8 <proc>
    80002304:	b7e1                	j	800022cc <kwait+0xb0>
      release(&wait_lock);
    80002306:	0000d517          	auipc	a0,0xd
    8000230a:	68a50513          	addi	a0,a0,1674 # 8000f990 <wait_lock>
    8000230e:	959fe0ef          	jal	80000c66 <release>
      return -1;
    80002312:	59fd                	li	s3,-1
    80002314:	b741                	j	80002294 <kwait+0x78>

0000000080002316 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002316:	7179                	addi	sp,sp,-48
    80002318:	f406                	sd	ra,40(sp)
    8000231a:	f022                	sd	s0,32(sp)
    8000231c:	ec26                	sd	s1,24(sp)
    8000231e:	e84a                	sd	s2,16(sp)
    80002320:	e44e                	sd	s3,8(sp)
    80002322:	e052                	sd	s4,0(sp)
    80002324:	1800                	addi	s0,sp,48
    80002326:	84aa                	mv	s1,a0
    80002328:	892e                	mv	s2,a1
    8000232a:	89b2                	mv	s3,a2
    8000232c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000232e:	da0ff0ef          	jal	800018ce <myproc>
  if(user_dst){
    80002332:	cc99                	beqz	s1,80002350 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002334:	86d2                	mv	a3,s4
    80002336:	864e                	mv	a2,s3
    80002338:	85ca                	mv	a1,s2
    8000233a:	6928                	ld	a0,80(a0)
    8000233c:	aa6ff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002340:	70a2                	ld	ra,40(sp)
    80002342:	7402                	ld	s0,32(sp)
    80002344:	64e2                	ld	s1,24(sp)
    80002346:	6942                	ld	s2,16(sp)
    80002348:	69a2                	ld	s3,8(sp)
    8000234a:	6a02                	ld	s4,0(sp)
    8000234c:	6145                	addi	sp,sp,48
    8000234e:	8082                	ret
    memmove((char *)dst, src, len);
    80002350:	000a061b          	sext.w	a2,s4
    80002354:	85ce                	mv	a1,s3
    80002356:	854a                	mv	a0,s2
    80002358:	9a7fe0ef          	jal	80000cfe <memmove>
    return 0;
    8000235c:	8526                	mv	a0,s1
    8000235e:	b7cd                	j	80002340 <either_copyout+0x2a>

0000000080002360 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002360:	7179                	addi	sp,sp,-48
    80002362:	f406                	sd	ra,40(sp)
    80002364:	f022                	sd	s0,32(sp)
    80002366:	ec26                	sd	s1,24(sp)
    80002368:	e84a                	sd	s2,16(sp)
    8000236a:	e44e                	sd	s3,8(sp)
    8000236c:	e052                	sd	s4,0(sp)
    8000236e:	1800                	addi	s0,sp,48
    80002370:	892a                	mv	s2,a0
    80002372:	84ae                	mv	s1,a1
    80002374:	89b2                	mv	s3,a2
    80002376:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002378:	d56ff0ef          	jal	800018ce <myproc>
  if(user_src){
    8000237c:	cc99                	beqz	s1,8000239a <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    8000237e:	86d2                	mv	a3,s4
    80002380:	864e                	mv	a2,s3
    80002382:	85ca                	mv	a1,s2
    80002384:	6928                	ld	a0,80(a0)
    80002386:	b40ff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000238a:	70a2                	ld	ra,40(sp)
    8000238c:	7402                	ld	s0,32(sp)
    8000238e:	64e2                	ld	s1,24(sp)
    80002390:	6942                	ld	s2,16(sp)
    80002392:	69a2                	ld	s3,8(sp)
    80002394:	6a02                	ld	s4,0(sp)
    80002396:	6145                	addi	sp,sp,48
    80002398:	8082                	ret
    memmove(dst, (char*)src, len);
    8000239a:	000a061b          	sext.w	a2,s4
    8000239e:	85ce                	mv	a1,s3
    800023a0:	854a                	mv	a0,s2
    800023a2:	95dfe0ef          	jal	80000cfe <memmove>
    return 0;
    800023a6:	8526                	mv	a0,s1
    800023a8:	b7cd                	j	8000238a <either_copyin+0x2a>

00000000800023aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023aa:	715d                	addi	sp,sp,-80
    800023ac:	e486                	sd	ra,72(sp)
    800023ae:	e0a2                	sd	s0,64(sp)
    800023b0:	fc26                	sd	s1,56(sp)
    800023b2:	f84a                	sd	s2,48(sp)
    800023b4:	f44e                	sd	s3,40(sp)
    800023b6:	f052                	sd	s4,32(sp)
    800023b8:	ec56                	sd	s5,24(sp)
    800023ba:	e85a                	sd	s6,16(sp)
    800023bc:	e45e                	sd	s7,8(sp)
    800023be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800023c0:	00005517          	auipc	a0,0x5
    800023c4:	cb850513          	addi	a0,a0,-840 # 80007078 <etext+0x78>
    800023c8:	932fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023cc:	0000e497          	auipc	s1,0xe
    800023d0:	b3448493          	addi	s1,s1,-1228 # 8000ff00 <proc+0x158>
    800023d4:	00015917          	auipc	s2,0x15
    800023d8:	d2c90913          	addi	s2,s2,-724 # 80017100 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800023de:	00005997          	auipc	s3,0x5
    800023e2:	e2298993          	addi	s3,s3,-478 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    800023e6:	00005a97          	auipc	s5,0x5
    800023ea:	e22a8a93          	addi	s5,s5,-478 # 80007208 <etext+0x208>
    printf("\n");
    800023ee:	00005a17          	auipc	s4,0x5
    800023f2:	c8aa0a13          	addi	s4,s4,-886 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023f6:	00005b97          	auipc	s7,0x5
    800023fa:	332b8b93          	addi	s7,s7,818 # 80007728 <states.0>
    800023fe:	a829                	j	80002418 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002400:	ed86a583          	lw	a1,-296(a3)
    80002404:	8556                	mv	a0,s5
    80002406:	8f4fe0ef          	jal	800004fa <printf>
    printf("\n");
    8000240a:	8552                	mv	a0,s4
    8000240c:	8eefe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002410:	1c848493          	addi	s1,s1,456
    80002414:	03248263          	beq	s1,s2,80002438 <procdump+0x8e>
    if(p->state == UNUSED)
    80002418:	86a6                	mv	a3,s1
    8000241a:	ec04a783          	lw	a5,-320(s1)
    8000241e:	dbed                	beqz	a5,80002410 <procdump+0x66>
      state = "???";
    80002420:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002422:	fcfb6fe3          	bltu	s6,a5,80002400 <procdump+0x56>
    80002426:	02079713          	slli	a4,a5,0x20
    8000242a:	01d75793          	srli	a5,a4,0x1d
    8000242e:	97de                	add	a5,a5,s7
    80002430:	6390                	ld	a2,0(a5)
    80002432:	f679                	bnez	a2,80002400 <procdump+0x56>
      state = "???";
    80002434:	864e                	mv	a2,s3
    80002436:	b7e9                	j	80002400 <procdump+0x56>
  }
}
    80002438:	60a6                	ld	ra,72(sp)
    8000243a:	6406                	ld	s0,64(sp)
    8000243c:	74e2                	ld	s1,56(sp)
    8000243e:	7942                	ld	s2,48(sp)
    80002440:	79a2                	ld	s3,40(sp)
    80002442:	7a02                	ld	s4,32(sp)
    80002444:	6ae2                	ld	s5,24(sp)
    80002446:	6b42                	ld	s6,16(sp)
    80002448:	6ba2                	ld	s7,8(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret

000000008000244e <promote_all>:


// Promote all processes to highest priority level (0)
void promote_all(void){
    8000244e:	1101                	addi	sp,sp,-32
    80002450:	ec06                	sd	ra,24(sp)
    80002452:	e822                	sd	s0,16(sp)
    80002454:	e426                	sd	s1,8(sp)
    80002456:	e04a                	sd	s2,0(sp)
    80002458:	1000                	addi	s0,sp,32
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    8000245a:	0000e497          	auipc	s1,0xe
    8000245e:	94e48493          	addi	s1,s1,-1714 # 8000fda8 <proc>
    80002462:	00015917          	auipc	s2,0x15
    80002466:	b4690913          	addi	s2,s2,-1210 # 80016fa8 <tickslock>
    8000246a:	a801                	j	8000247a <promote_all+0x2c>
    acquire(&p->lock);
    if(p->state != UNUSED){
        p->priority = 0;
        p->ticks_used = 0;
    }
    release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	ff8fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002472:	1c848493          	addi	s1,s1,456
    80002476:	01248c63          	beq	s1,s2,8000248e <promote_all+0x40>
    acquire(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	f52fe0ef          	jal	80000bce <acquire>
    if(p->state != UNUSED){
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	d7ed                	beqz	a5,8000246c <promote_all+0x1e>
        p->priority = 0;
    80002484:	1604a423          	sw	zero,360(s1)
        p->ticks_used = 0;
    80002488:	1604a623          	sw	zero,364(s1)
    8000248c:	b7c5                	j	8000246c <promote_all+0x1e>
  }
}
    8000248e:	60e2                	ld	ra,24(sp)
    80002490:	6442                	ld	s0,16(sp)
    80002492:	64a2                	ld	s1,8(sp)
    80002494:	6902                	ld	s2,0(sp)
    80002496:	6105                	addi	sp,sp,32
    80002498:	8082                	ret

000000008000249a <has_higher_priority>:

// Check if there is any runnable process with higher priority
int has_higher_priority(int priority) {
    8000249a:	1141                	addi	sp,sp,-16
    8000249c:	e422                	sd	s0,8(sp)
    8000249e:	0800                	addi	s0,sp,16
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800024a0:	0000e797          	auipc	a5,0xe
    800024a4:	90878793          	addi	a5,a5,-1784 # 8000fda8 <proc>
    if(p->state == RUNNABLE && p->priority < priority){
    800024a8:	468d                	li	a3,3
  for(p = proc; p < &proc[NPROC]; p++){
    800024aa:	00015617          	auipc	a2,0x15
    800024ae:	afe60613          	addi	a2,a2,-1282 # 80016fa8 <tickslock>
    800024b2:	a029                	j	800024bc <has_higher_priority+0x22>
    800024b4:	1c878793          	addi	a5,a5,456
    800024b8:	00c78d63          	beq	a5,a2,800024d2 <has_higher_priority+0x38>
    if(p->state == RUNNABLE && p->priority < priority){
    800024bc:	4f98                	lw	a4,24(a5)
    800024be:	fed71be3          	bne	a4,a3,800024b4 <has_higher_priority+0x1a>
    800024c2:	1687a703          	lw	a4,360(a5)
    800024c6:	fea757e3          	bge	a4,a0,800024b4 <has_higher_priority+0x1a>
      return 1;
    800024ca:	4505                	li	a0,1
    }
  }
  return 0;
    800024cc:	6422                	ld	s0,8(sp)
    800024ce:	0141                	addi	sp,sp,16
    800024d0:	8082                	ret
  return 0;
    800024d2:	4501                	li	a0,0
    800024d4:	bfe5                	j	800024cc <has_higher_priority+0x32>

00000000800024d6 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800024d6:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800024da:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800024de:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800024e0:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800024e2:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800024e6:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800024ea:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800024ee:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800024f2:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800024f6:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800024fa:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800024fe:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002502:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002506:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    8000250a:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000250e:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002512:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002514:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002516:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    8000251a:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000251e:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002522:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002526:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    8000252a:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    8000252e:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002532:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002536:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    8000253a:	0685bd83          	ld	s11,104(a1)
        
        ret
    8000253e:	8082                	ret

0000000080002540 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002540:	1141                	addi	sp,sp,-16
    80002542:	e406                	sd	ra,8(sp)
    80002544:	e022                	sd	s0,0(sp)
    80002546:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002548:	00005597          	auipc	a1,0x5
    8000254c:	d0058593          	addi	a1,a1,-768 # 80007248 <etext+0x248>
    80002550:	00015517          	auipc	a0,0x15
    80002554:	a5850513          	addi	a0,a0,-1448 # 80016fa8 <tickslock>
    80002558:	df6fe0ef          	jal	80000b4e <initlock>
}
    8000255c:	60a2                	ld	ra,8(sp)
    8000255e:	6402                	ld	s0,0(sp)
    80002560:	0141                	addi	sp,sp,16
    80002562:	8082                	ret

0000000080002564 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002564:	1141                	addi	sp,sp,-16
    80002566:	e422                	sd	s0,8(sp)
    80002568:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000256a:	00003797          	auipc	a5,0x3
    8000256e:	1a678793          	addi	a5,a5,422 # 80005710 <kernelvec>
    80002572:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002576:	6422                	ld	s0,8(sp)
    80002578:	0141                	addi	sp,sp,16
    8000257a:	8082                	ret

000000008000257c <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000257c:	1141                	addi	sp,sp,-16
    8000257e:	e406                	sd	ra,8(sp)
    80002580:	e022                	sd	s0,0(sp)
    80002582:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002584:	b4aff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002588:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000258c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000258e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002592:	04000737          	lui	a4,0x4000
    80002596:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80002598:	0732                	slli	a4,a4,0xc
    8000259a:	00004797          	auipc	a5,0x4
    8000259e:	a6678793          	addi	a5,a5,-1434 # 80006000 <_trampoline>
    800025a2:	00004697          	auipc	a3,0x4
    800025a6:	a5e68693          	addi	a3,a3,-1442 # 80006000 <_trampoline>
    800025aa:	8f95                	sub	a5,a5,a3
    800025ac:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025ae:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800025b2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800025b4:	18002773          	csrr	a4,satp
    800025b8:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800025ba:	6d38                	ld	a4,88(a0)
    800025bc:	613c                	ld	a5,64(a0)
    800025be:	6685                	lui	a3,0x1
    800025c0:	97b6                	add	a5,a5,a3
    800025c2:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800025c4:	6d3c                	ld	a5,88(a0)
    800025c6:	00000717          	auipc	a4,0x0
    800025ca:	0f870713          	addi	a4,a4,248 # 800026be <usertrap>
    800025ce:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800025d0:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800025d2:	8712                	mv	a4,tp
    800025d4:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025d6:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800025da:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800025de:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025e2:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800025e6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800025e8:	6f9c                	ld	a5,24(a5)
    800025ea:	14179073          	csrw	sepc,a5
}
    800025ee:	60a2                	ld	ra,8(sp)
    800025f0:	6402                	ld	s0,0(sp)
    800025f2:	0141                	addi	sp,sp,16
    800025f4:	8082                	ret

00000000800025f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800025f6:	1101                	addi	sp,sp,-32
    800025f8:	ec06                	sd	ra,24(sp)
    800025fa:	e822                	sd	s0,16(sp)
    800025fc:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800025fe:	aa4ff0ef          	jal	800018a2 <cpuid>
    80002602:	cd11                	beqz	a0,8000261e <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002604:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002608:	000f4737          	lui	a4,0xf4
    8000260c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002610:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002612:	14d79073          	csrw	stimecmp,a5
}
    80002616:	60e2                	ld	ra,24(sp)
    80002618:	6442                	ld	s0,16(sp)
    8000261a:	6105                	addi	sp,sp,32
    8000261c:	8082                	ret
    8000261e:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002620:	00015497          	auipc	s1,0x15
    80002624:	98848493          	addi	s1,s1,-1656 # 80016fa8 <tickslock>
    80002628:	8526                	mv	a0,s1
    8000262a:	da4fe0ef          	jal	80000bce <acquire>
    ticks++;
    8000262e:	00005517          	auipc	a0,0x5
    80002632:	24250513          	addi	a0,a0,578 # 80007870 <ticks>
    80002636:	411c                	lw	a5,0(a0)
    80002638:	2785                	addiw	a5,a5,1
    8000263a:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    8000263c:	9cbff0ef          	jal	80002006 <wakeup>
    release(&tickslock);
    80002640:	8526                	mv	a0,s1
    80002642:	e24fe0ef          	jal	80000c66 <release>
    80002646:	64a2                	ld	s1,8(sp)
    80002648:	bf75                	j	80002604 <clockintr+0xe>

000000008000264a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000264a:	1101                	addi	sp,sp,-32
    8000264c:	ec06                	sd	ra,24(sp)
    8000264e:	e822                	sd	s0,16(sp)
    80002650:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002652:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002656:	57fd                	li	a5,-1
    80002658:	17fe                	slli	a5,a5,0x3f
    8000265a:	07a5                	addi	a5,a5,9
    8000265c:	00f70c63          	beq	a4,a5,80002674 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002660:	57fd                	li	a5,-1
    80002662:	17fe                	slli	a5,a5,0x3f
    80002664:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002666:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002668:	04f70763          	beq	a4,a5,800026b6 <devintr+0x6c>
  }
}
    8000266c:	60e2                	ld	ra,24(sp)
    8000266e:	6442                	ld	s0,16(sp)
    80002670:	6105                	addi	sp,sp,32
    80002672:	8082                	ret
    80002674:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002676:	146030ef          	jal	800057bc <plic_claim>
    8000267a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000267c:	47a9                	li	a5,10
    8000267e:	00f50963          	beq	a0,a5,80002690 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80002682:	4785                	li	a5,1
    80002684:	00f50963          	beq	a0,a5,80002696 <devintr+0x4c>
    return 1;
    80002688:	4505                	li	a0,1
    } else if(irq){
    8000268a:	e889                	bnez	s1,8000269c <devintr+0x52>
    8000268c:	64a2                	ld	s1,8(sp)
    8000268e:	bff9                	j	8000266c <devintr+0x22>
      uartintr();
    80002690:	b20fe0ef          	jal	800009b0 <uartintr>
    if(irq)
    80002694:	a819                	j	800026aa <devintr+0x60>
      virtio_disk_intr();
    80002696:	5ec030ef          	jal	80005c82 <virtio_disk_intr>
    if(irq)
    8000269a:	a801                	j	800026aa <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    8000269c:	85a6                	mv	a1,s1
    8000269e:	00005517          	auipc	a0,0x5
    800026a2:	bb250513          	addi	a0,a0,-1102 # 80007250 <etext+0x250>
    800026a6:	e55fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    800026aa:	8526                	mv	a0,s1
    800026ac:	130030ef          	jal	800057dc <plic_complete>
    return 1;
    800026b0:	4505                	li	a0,1
    800026b2:	64a2                	ld	s1,8(sp)
    800026b4:	bf65                	j	8000266c <devintr+0x22>
    clockintr();
    800026b6:	f41ff0ef          	jal	800025f6 <clockintr>
    return 2;
    800026ba:	4509                	li	a0,2
    800026bc:	bf45                	j	8000266c <devintr+0x22>

00000000800026be <usertrap>:
{
    800026be:	1101                	addi	sp,sp,-32
    800026c0:	ec06                	sd	ra,24(sp)
    800026c2:	e822                	sd	s0,16(sp)
    800026c4:	e426                	sd	s1,8(sp)
    800026c6:	e04a                	sd	s2,0(sp)
    800026c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800026ce:	1007f793          	andi	a5,a5,256
    800026d2:	eba5                	bnez	a5,80002742 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d4:	00003797          	auipc	a5,0x3
    800026d8:	03c78793          	addi	a5,a5,60 # 80005710 <kernelvec>
    800026dc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800026e0:	9eeff0ef          	jal	800018ce <myproc>
    800026e4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800026e6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026e8:	14102773          	csrr	a4,sepc
    800026ec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026ee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800026f2:	47a1                	li	a5,8
    800026f4:	04f70d63          	beq	a4,a5,8000274e <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800026f8:	f53ff0ef          	jal	8000264a <devintr>
    800026fc:	892a                	mv	s2,a0
    800026fe:	e945                	bnez	a0,800027ae <usertrap+0xf0>
    80002700:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002704:	47bd                	li	a5,15
    80002706:	08f70863          	beq	a4,a5,80002796 <usertrap+0xd8>
    8000270a:	14202773          	csrr	a4,scause
    8000270e:	47b5                	li	a5,13
    80002710:	08f70363          	beq	a4,a5,80002796 <usertrap+0xd8>
    80002714:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002718:	5890                	lw	a2,48(s1)
    8000271a:	00005517          	auipc	a0,0x5
    8000271e:	b7650513          	addi	a0,a0,-1162 # 80007290 <etext+0x290>
    80002722:	dd9fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002726:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000272a:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    8000272e:	00005517          	auipc	a0,0x5
    80002732:	b9250513          	addi	a0,a0,-1134 # 800072c0 <etext+0x2c0>
    80002736:	dc5fd0ef          	jal	800004fa <printf>
    setkilled(p);
    8000273a:	8526                	mv	a0,s1
    8000273c:	a93ff0ef          	jal	800021ce <setkilled>
    80002740:	a035                	j	8000276c <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002742:	00005517          	auipc	a0,0x5
    80002746:	b2e50513          	addi	a0,a0,-1234 # 80007270 <etext+0x270>
    8000274a:	896fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    8000274e:	aa5ff0ef          	jal	800021f2 <killed>
    80002752:	ed15                	bnez	a0,8000278e <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002754:	6cb8                	ld	a4,88(s1)
    80002756:	6f1c                	ld	a5,24(a4)
    80002758:	0791                	addi	a5,a5,4
    8000275a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002760:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002764:	10079073          	csrw	sstatus,a5
    syscall();
    80002768:	38e000ef          	jal	80002af6 <syscall>
  if(killed(p))
    8000276c:	8526                	mv	a0,s1
    8000276e:	a85ff0ef          	jal	800021f2 <killed>
    80002772:	e139                	bnez	a0,800027b8 <usertrap+0xfa>
  prepare_return();
    80002774:	e09ff0ef          	jal	8000257c <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002778:	68a8                	ld	a0,80(s1)
    8000277a:	8131                	srli	a0,a0,0xc
    8000277c:	57fd                	li	a5,-1
    8000277e:	17fe                	slli	a5,a5,0x3f
    80002780:	8d5d                	or	a0,a0,a5
}
    80002782:	60e2                	ld	ra,24(sp)
    80002784:	6442                	ld	s0,16(sp)
    80002786:	64a2                	ld	s1,8(sp)
    80002788:	6902                	ld	s2,0(sp)
    8000278a:	6105                	addi	sp,sp,32
    8000278c:	8082                	ret
      kexit(-1);
    8000278e:	557d                	li	a0,-1
    80002790:	937ff0ef          	jal	800020c6 <kexit>
    80002794:	b7c1                	j	80002754 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002796:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279a:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    8000279e:	164d                	addi	a2,a2,-13
    800027a0:	00163613          	seqz	a2,a2
    800027a4:	68a8                	ld	a0,80(s1)
    800027a6:	dbbfe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800027aa:	f169                	bnez	a0,8000276c <usertrap+0xae>
    800027ac:	b7a5                	j	80002714 <usertrap+0x56>
  if(killed(p))
    800027ae:	8526                	mv	a0,s1
    800027b0:	a43ff0ef          	jal	800021f2 <killed>
    800027b4:	c511                	beqz	a0,800027c0 <usertrap+0x102>
    800027b6:	a011                	j	800027ba <usertrap+0xfc>
    800027b8:	4901                	li	s2,0
    kexit(-1);
    800027ba:	557d                	li	a0,-1
    800027bc:	90bff0ef          	jal	800020c6 <kexit>
  if(which_dev == 2)
    800027c0:	4789                	li	a5,2
    800027c2:	faf919e3          	bne	s2,a5,80002774 <usertrap+0xb6>
    struct proc *p = myproc();
    800027c6:	908ff0ef          	jal	800018ce <myproc>
    if(p){
    800027ca:	cd31                	beqz	a0,80002826 <usertrap+0x168>
      p->ticks_used++;
    800027cc:	16c52783          	lw	a5,364(a0)
    800027d0:	2785                	addiw	a5,a5,1
    800027d2:	0007871b          	sext.w	a4,a5
    800027d6:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    800027da:	17452783          	lw	a5,372(a0)
    800027de:	2785                	addiw	a5,a5,1
    800027e0:	16f52a23          	sw	a5,372(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    800027e4:	16852783          	lw	a5,360(a0)
    800027e8:	cbb1                	beqz	a5,8000283c <usertrap+0x17e>
      else if(p->priority == 1) quantum = QUANTUM_1;
    800027ea:	4685                	li	a3,1
    800027ec:	06d78b63          	beq	a5,a3,80002862 <usertrap+0x1a4>
      if(p->ticks_used >= quantum){
    800027f0:	469d                	li	a3,7
    800027f2:	04e6d863          	bge	a3,a4,80002842 <usertrap+0x184>
        if(p->priority < 2)
    800027f6:	4705                	li	a4,1
    800027f8:	02f75363          	bge	a4,a5,8000281e <usertrap+0x160>
        p->ticks_used = 0;
    800027fc:	16052623          	sw	zero,364(a0)
    if(ticks % AGING_INTERVAL == 0){
    80002800:	00005797          	auipc	a5,0x5
    80002804:	0707a783          	lw	a5,112(a5) # 80007870 <ticks>
    80002808:	06400713          	li	a4,100
    8000280c:	02e7f7bb          	remuw	a5,a5,a4
    80002810:	2781                	sext.w	a5,a5
    80002812:	e399                	bnez	a5,80002818 <usertrap+0x15a>
      promote_all();
    80002814:	c3bff0ef          	jal	8000244e <promote_all>
      yield();
    80002818:	f72ff0ef          	jal	80001f8a <yield>
    8000281c:	bfa1                	j	80002774 <usertrap+0xb6>
          p->priority++;
    8000281e:	2785                	addiw	a5,a5,1
    80002820:	16f52423          	sw	a5,360(a0)
    80002824:	bfe1                	j	800027fc <usertrap+0x13e>
    if(ticks % AGING_INTERVAL == 0){
    80002826:	00005797          	auipc	a5,0x5
    8000282a:	04a7a783          	lw	a5,74(a5) # 80007870 <ticks>
    8000282e:	06400713          	li	a4,100
    80002832:	02e7f7bb          	remuw	a5,a5,a4
    80002836:	2781                	sext.w	a5,a5
    80002838:	ff95                	bnez	a5,80002774 <usertrap+0xb6>
    8000283a:	bfe9                	j	80002814 <usertrap+0x156>
      if(p->priority == 0) quantum = QUANTUM_0;
    8000283c:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    8000283e:	fed750e3          	bge	a4,a3,8000281e <usertrap+0x160>
      } else if(has_higher_priority(p->priority)){
    80002842:	853e                	mv	a0,a5
    80002844:	c57ff0ef          	jal	8000249a <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002848:	00005797          	auipc	a5,0x5
    8000284c:	0287a783          	lw	a5,40(a5) # 80007870 <ticks>
    80002850:	06400713          	li	a4,100
    80002854:	02e7f7bb          	remuw	a5,a5,a4
    80002858:	2781                	sext.w	a5,a5
    8000285a:	dfcd                	beqz	a5,80002814 <usertrap+0x156>
    if(need_yield){
    8000285c:	f0050ce3          	beqz	a0,80002774 <usertrap+0xb6>
    80002860:	bf65                	j	80002818 <usertrap+0x15a>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002862:	4691                	li	a3,4
    80002864:	bfe9                	j	8000283e <usertrap+0x180>

0000000080002866 <kerneltrap>:
{
    80002866:	7179                	addi	sp,sp,-48
    80002868:	f406                	sd	ra,40(sp)
    8000286a:	f022                	sd	s0,32(sp)
    8000286c:	ec26                	sd	s1,24(sp)
    8000286e:	e84a                	sd	s2,16(sp)
    80002870:	e44e                	sd	s3,8(sp)
    80002872:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002874:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002878:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002880:	1004f793          	andi	a5,s1,256
    80002884:	c795                	beqz	a5,800028b0 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002886:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000288a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000288c:	eb85                	bnez	a5,800028bc <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000288e:	dbdff0ef          	jal	8000264a <devintr>
    80002892:	c91d                	beqz	a0,800028c8 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    80002894:	4789                	li	a5,2
    80002896:	04f50a63          	beq	a0,a5,800028ea <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289e:	10049073          	csrw	sstatus,s1
}
    800028a2:	70a2                	ld	ra,40(sp)
    800028a4:	7402                	ld	s0,32(sp)
    800028a6:	64e2                	ld	s1,24(sp)
    800028a8:	6942                	ld	s2,16(sp)
    800028aa:	69a2                	ld	s3,8(sp)
    800028ac:	6145                	addi	sp,sp,48
    800028ae:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028b0:	00005517          	auipc	a0,0x5
    800028b4:	a3850513          	addi	a0,a0,-1480 # 800072e8 <etext+0x2e8>
    800028b8:	f29fd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    800028bc:	00005517          	auipc	a0,0x5
    800028c0:	a5450513          	addi	a0,a0,-1452 # 80007310 <etext+0x310>
    800028c4:	f1dfd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c8:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028cc:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800028d0:	85ce                	mv	a1,s3
    800028d2:	00005517          	auipc	a0,0x5
    800028d6:	a5e50513          	addi	a0,a0,-1442 # 80007330 <etext+0x330>
    800028da:	c21fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800028de:	00005517          	auipc	a0,0x5
    800028e2:	a7a50513          	addi	a0,a0,-1414 # 80007358 <etext+0x358>
    800028e6:	efbfd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0){
    800028ea:	fe5fe0ef          	jal	800018ce <myproc>
    800028ee:	d555                	beqz	a0,8000289a <kerneltrap+0x34>
    struct proc *p = myproc();
    800028f0:	fdffe0ef          	jal	800018ce <myproc>
    if(p){
    800028f4:	cd31                	beqz	a0,80002950 <kerneltrap+0xea>
      p->ticks_used++;
    800028f6:	16c52783          	lw	a5,364(a0)
    800028fa:	2785                	addiw	a5,a5,1
    800028fc:	0007871b          	sext.w	a4,a5
    80002900:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    80002904:	17452783          	lw	a5,372(a0)
    80002908:	2785                	addiw	a5,a5,1
    8000290a:	16f52a23          	sw	a5,372(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    8000290e:	16852783          	lw	a5,360(a0)
    80002912:	cbb1                	beqz	a5,80002966 <kerneltrap+0x100>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002914:	4685                	li	a3,1
    80002916:	06d78b63          	beq	a5,a3,8000298c <kerneltrap+0x126>
      if(p->ticks_used >= quantum){
    8000291a:	469d                	li	a3,7
    8000291c:	04e6d863          	bge	a3,a4,8000296c <kerneltrap+0x106>
        if(p->priority < 2)
    80002920:	4705                	li	a4,1
    80002922:	02f75363          	bge	a4,a5,80002948 <kerneltrap+0xe2>
        p->ticks_used = 0;
    80002926:	16052623          	sw	zero,364(a0)
    if(ticks % AGING_INTERVAL == 0){
    8000292a:	00005797          	auipc	a5,0x5
    8000292e:	f467a783          	lw	a5,-186(a5) # 80007870 <ticks>
    80002932:	06400713          	li	a4,100
    80002936:	02e7f7bb          	remuw	a5,a5,a4
    8000293a:	2781                	sext.w	a5,a5
    8000293c:	e399                	bnez	a5,80002942 <kerneltrap+0xdc>
      promote_all();
    8000293e:	b11ff0ef          	jal	8000244e <promote_all>
      yield();
    80002942:	e48ff0ef          	jal	80001f8a <yield>
    80002946:	bf91                	j	8000289a <kerneltrap+0x34>
          p->priority++;
    80002948:	2785                	addiw	a5,a5,1
    8000294a:	16f52423          	sw	a5,360(a0)
    8000294e:	bfe1                	j	80002926 <kerneltrap+0xc0>
    if(ticks % AGING_INTERVAL == 0){
    80002950:	00005797          	auipc	a5,0x5
    80002954:	f207a783          	lw	a5,-224(a5) # 80007870 <ticks>
    80002958:	06400713          	li	a4,100
    8000295c:	02e7f7bb          	remuw	a5,a5,a4
    80002960:	2781                	sext.w	a5,a5
    80002962:	ff85                	bnez	a5,8000289a <kerneltrap+0x34>
    80002964:	bfe9                	j	8000293e <kerneltrap+0xd8>
      if(p->priority == 0) quantum = QUANTUM_0;
    80002966:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    80002968:	fed750e3          	bge	a4,a3,80002948 <kerneltrap+0xe2>
      } else if(has_higher_priority(p->priority)){
    8000296c:	853e                	mv	a0,a5
    8000296e:	b2dff0ef          	jal	8000249a <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002972:	00005797          	auipc	a5,0x5
    80002976:	efe7a783          	lw	a5,-258(a5) # 80007870 <ticks>
    8000297a:	06400713          	li	a4,100
    8000297e:	02e7f7bb          	remuw	a5,a5,a4
    80002982:	2781                	sext.w	a5,a5
    80002984:	dfcd                	beqz	a5,8000293e <kerneltrap+0xd8>
    if(need_yield){
    80002986:	f0050ae3          	beqz	a0,8000289a <kerneltrap+0x34>
    8000298a:	bf65                	j	80002942 <kerneltrap+0xdc>
      else if(p->priority == 1) quantum = QUANTUM_1;
    8000298c:	4691                	li	a3,4
    8000298e:	bfe9                	j	80002968 <kerneltrap+0x102>

0000000080002990 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002990:	1101                	addi	sp,sp,-32
    80002992:	ec06                	sd	ra,24(sp)
    80002994:	e822                	sd	s0,16(sp)
    80002996:	e426                	sd	s1,8(sp)
    80002998:	1000                	addi	s0,sp,32
    8000299a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000299c:	f33fe0ef          	jal	800018ce <myproc>
  switch (n) {
    800029a0:	4795                	li	a5,5
    800029a2:	0497e163          	bltu	a5,s1,800029e4 <argraw+0x54>
    800029a6:	048a                	slli	s1,s1,0x2
    800029a8:	00005717          	auipc	a4,0x5
    800029ac:	db070713          	addi	a4,a4,-592 # 80007758 <states.0+0x30>
    800029b0:	94ba                	add	s1,s1,a4
    800029b2:	409c                	lw	a5,0(s1)
    800029b4:	97ba                	add	a5,a5,a4
    800029b6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029b8:	6d3c                	ld	a5,88(a0)
    800029ba:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029bc:	60e2                	ld	ra,24(sp)
    800029be:	6442                	ld	s0,16(sp)
    800029c0:	64a2                	ld	s1,8(sp)
    800029c2:	6105                	addi	sp,sp,32
    800029c4:	8082                	ret
    return p->trapframe->a1;
    800029c6:	6d3c                	ld	a5,88(a0)
    800029c8:	7fa8                	ld	a0,120(a5)
    800029ca:	bfcd                	j	800029bc <argraw+0x2c>
    return p->trapframe->a2;
    800029cc:	6d3c                	ld	a5,88(a0)
    800029ce:	63c8                	ld	a0,128(a5)
    800029d0:	b7f5                	j	800029bc <argraw+0x2c>
    return p->trapframe->a3;
    800029d2:	6d3c                	ld	a5,88(a0)
    800029d4:	67c8                	ld	a0,136(a5)
    800029d6:	b7dd                	j	800029bc <argraw+0x2c>
    return p->trapframe->a4;
    800029d8:	6d3c                	ld	a5,88(a0)
    800029da:	6bc8                	ld	a0,144(a5)
    800029dc:	b7c5                	j	800029bc <argraw+0x2c>
    return p->trapframe->a5;
    800029de:	6d3c                	ld	a5,88(a0)
    800029e0:	6fc8                	ld	a0,152(a5)
    800029e2:	bfe9                	j	800029bc <argraw+0x2c>
  panic("argraw");
    800029e4:	00005517          	auipc	a0,0x5
    800029e8:	98450513          	addi	a0,a0,-1660 # 80007368 <etext+0x368>
    800029ec:	df5fd0ef          	jal	800007e0 <panic>

00000000800029f0 <fetchaddr>:
{
    800029f0:	1101                	addi	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	addi	s0,sp,32
    800029fc:	84aa                	mv	s1,a0
    800029fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a00:	ecffe0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a04:	653c                	ld	a5,72(a0)
    80002a06:	02f4f663          	bgeu	s1,a5,80002a32 <fetchaddr+0x42>
    80002a0a:	00848713          	addi	a4,s1,8
    80002a0e:	02e7e463          	bltu	a5,a4,80002a36 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a12:	46a1                	li	a3,8
    80002a14:	8626                	mv	a2,s1
    80002a16:	85ca                	mv	a1,s2
    80002a18:	6928                	ld	a0,80(a0)
    80002a1a:	cadfe0ef          	jal	800016c6 <copyin>
    80002a1e:	00a03533          	snez	a0,a0
    80002a22:	40a00533          	neg	a0,a0
}
    80002a26:	60e2                	ld	ra,24(sp)
    80002a28:	6442                	ld	s0,16(sp)
    80002a2a:	64a2                	ld	s1,8(sp)
    80002a2c:	6902                	ld	s2,0(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret
    return -1;
    80002a32:	557d                	li	a0,-1
    80002a34:	bfcd                	j	80002a26 <fetchaddr+0x36>
    80002a36:	557d                	li	a0,-1
    80002a38:	b7fd                	j	80002a26 <fetchaddr+0x36>

0000000080002a3a <fetchstr>:
{
    80002a3a:	7179                	addi	sp,sp,-48
    80002a3c:	f406                	sd	ra,40(sp)
    80002a3e:	f022                	sd	s0,32(sp)
    80002a40:	ec26                	sd	s1,24(sp)
    80002a42:	e84a                	sd	s2,16(sp)
    80002a44:	e44e                	sd	s3,8(sp)
    80002a46:	1800                	addi	s0,sp,48
    80002a48:	892a                	mv	s2,a0
    80002a4a:	84ae                	mv	s1,a1
    80002a4c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a4e:	e81fe0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a52:	86ce                	mv	a3,s3
    80002a54:	864a                	mv	a2,s2
    80002a56:	85a6                	mv	a1,s1
    80002a58:	6928                	ld	a0,80(a0)
    80002a5a:	a2ffe0ef          	jal	80001488 <copyinstr>
    80002a5e:	00054c63          	bltz	a0,80002a76 <fetchstr+0x3c>
  return strlen(buf);
    80002a62:	8526                	mv	a0,s1
    80002a64:	baefe0ef          	jal	80000e12 <strlen>
}
    80002a68:	70a2                	ld	ra,40(sp)
    80002a6a:	7402                	ld	s0,32(sp)
    80002a6c:	64e2                	ld	s1,24(sp)
    80002a6e:	6942                	ld	s2,16(sp)
    80002a70:	69a2                	ld	s3,8(sp)
    80002a72:	6145                	addi	sp,sp,48
    80002a74:	8082                	ret
    return -1;
    80002a76:	557d                	li	a0,-1
    80002a78:	bfc5                	j	80002a68 <fetchstr+0x2e>

0000000080002a7a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002a7a:	1101                	addi	sp,sp,-32
    80002a7c:	ec06                	sd	ra,24(sp)
    80002a7e:	e822                	sd	s0,16(sp)
    80002a80:	e426                	sd	s1,8(sp)
    80002a82:	1000                	addi	s0,sp,32
    80002a84:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a86:	f0bff0ef          	jal	80002990 <argraw>
    80002a8a:	c088                	sw	a0,0(s1)
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
    80002aa0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa2:	eefff0ef          	jal	80002990 <argraw>
    80002aa6:	e088                	sd	a0,0(s1)
  struct proc *p = myproc();
    80002aa8:	e27fe0ef          	jal	800018ce <myproc>
  // Kiểm tra xem địa chỉ có hợp lệ trong page table không
  if(walkaddr(p->pagetable, *ip) == 0)
    80002aac:	608c                	ld	a1,0(s1)
    80002aae:	6928                	ld	a0,80(a0)
    80002ab0:	d00fe0ef          	jal	80000fb0 <walkaddr>
    80002ab4:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
    80002ab8:	40a00533          	neg	a0,a0
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	64a2                	ld	s1,8(sp)
    80002ac2:	6105                	addi	sp,sp,32
    80002ac4:	8082                	ret

0000000080002ac6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ac6:	7179                	addi	sp,sp,-48
    80002ac8:	f406                	sd	ra,40(sp)
    80002aca:	f022                	sd	s0,32(sp)
    80002acc:	ec26                	sd	s1,24(sp)
    80002ace:	e84a                	sd	s2,16(sp)
    80002ad0:	1800                	addi	s0,sp,48
    80002ad2:	84ae                	mv	s1,a1
    80002ad4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ad6:	fd840593          	addi	a1,s0,-40
    80002ada:	fbdff0ef          	jal	80002a96 <argaddr>
  return fetchstr(addr, buf, max);
    80002ade:	864a                	mv	a2,s2
    80002ae0:	85a6                	mv	a1,s1
    80002ae2:	fd843503          	ld	a0,-40(s0)
    80002ae6:	f55ff0ef          	jal	80002a3a <fetchstr>
}
    80002aea:	70a2                	ld	ra,40(sp)
    80002aec:	7402                	ld	s0,32(sp)
    80002aee:	64e2                	ld	s1,24(sp)
    80002af0:	6942                	ld	s2,16(sp)
    80002af2:	6145                	addi	sp,sp,48
    80002af4:	8082                	ret

0000000080002af6 <syscall>:
[SYS_proc_info]   sys_proc_info,
};

void
syscall(void)
{
    80002af6:	1101                	addi	sp,sp,-32
    80002af8:	ec06                	sd	ra,24(sp)
    80002afa:	e822                	sd	s0,16(sp)
    80002afc:	e426                	sd	s1,8(sp)
    80002afe:	e04a                	sd	s2,0(sp)
    80002b00:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b02:	dcdfe0ef          	jal	800018ce <myproc>
    80002b06:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b08:	05853903          	ld	s2,88(a0)
    80002b0c:	0a893783          	ld	a5,168(s2)
    80002b10:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b14:	37fd                	addiw	a5,a5,-1
    80002b16:	4755                	li	a4,21
    80002b18:	00f76f63          	bltu	a4,a5,80002b36 <syscall+0x40>
    80002b1c:	00369713          	slli	a4,a3,0x3
    80002b20:	00005797          	auipc	a5,0x5
    80002b24:	c5078793          	addi	a5,a5,-944 # 80007770 <syscalls>
    80002b28:	97ba                	add	a5,a5,a4
    80002b2a:	639c                	ld	a5,0(a5)
    80002b2c:	c789                	beqz	a5,80002b36 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b2e:	9782                	jalr	a5
    80002b30:	06a93823          	sd	a0,112(s2)
    80002b34:	a829                	j	80002b4e <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b36:	15848613          	addi	a2,s1,344
    80002b3a:	588c                	lw	a1,48(s1)
    80002b3c:	00005517          	auipc	a0,0x5
    80002b40:	83450513          	addi	a0,a0,-1996 # 80007370 <etext+0x370>
    80002b44:	9b7fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b48:	6cbc                	ld	a5,88(s1)
    80002b4a:	577d                	li	a4,-1
    80002b4c:	fbb8                	sd	a4,112(a5)
  }
}
    80002b4e:	60e2                	ld	ra,24(sp)
    80002b50:	6442                	ld	s0,16(sp)
    80002b52:	64a2                	ld	s1,8(sp)
    80002b54:	6902                	ld	s2,0(sp)
    80002b56:	6105                	addi	sp,sp,32
    80002b58:	8082                	ret

0000000080002b5a <sys_exit>:
int argaddr(int, uint64 *);
extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002b62:	fec40593          	addi	a1,s0,-20
    80002b66:	4501                	li	a0,0
    80002b68:	f13ff0ef          	jal	80002a7a <argint>
  kexit(n);
    80002b6c:	fec42503          	lw	a0,-20(s0)
    80002b70:	d56ff0ef          	jal	800020c6 <kexit>
  return 0;  // not reached
}
    80002b74:	4501                	li	a0,0
    80002b76:	60e2                	ld	ra,24(sp)
    80002b78:	6442                	ld	s0,16(sp)
    80002b7a:	6105                	addi	sp,sp,32
    80002b7c:	8082                	ret

0000000080002b7e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b7e:	1141                	addi	sp,sp,-16
    80002b80:	e406                	sd	ra,8(sp)
    80002b82:	e022                	sd	s0,0(sp)
    80002b84:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b86:	d49fe0ef          	jal	800018ce <myproc>
}
    80002b8a:	5908                	lw	a0,48(a0)
    80002b8c:	60a2                	ld	ra,8(sp)
    80002b8e:	6402                	ld	s0,0(sp)
    80002b90:	0141                	addi	sp,sp,16
    80002b92:	8082                	ret

0000000080002b94 <sys_fork>:

uint64
sys_fork(void)
{
    80002b94:	7179                	addi	sp,sp,-48
    80002b96:	f406                	sd	ra,40(sp)
    80002b98:	f022                	sd	s0,32(sp)
    80002b9a:	ec26                	sd	s1,24(sp)
    80002b9c:	1800                	addi	s0,sp,48
  int npid = kfork();
    80002b9e:	90cff0ef          	jal	80001caa <kfork>
    80002ba2:	84aa                	mv	s1,a0
  if(npid > 0){
    80002ba4:	00a04863          	bgtz	a0,80002bb4 <sys_fork+0x20>
    p->fork_times[p->fork_times_idx] = current_tick;
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    release(&p->lock);
  }
  return npid;
}
    80002ba8:	8526                	mv	a0,s1
    80002baa:	70a2                	ld	ra,40(sp)
    80002bac:	7402                	ld	s0,32(sp)
    80002bae:	64e2                	ld	s1,24(sp)
    80002bb0:	6145                	addi	sp,sp,48
    80002bb2:	8082                	ret
    80002bb4:	e84a                	sd	s2,16(sp)
    80002bb6:	e44e                	sd	s3,8(sp)
    struct proc *p = myproc();
    80002bb8:	d17fe0ef          	jal	800018ce <myproc>
    80002bbc:	892a                	mv	s2,a0
    acquire(&tickslock);
    80002bbe:	00014517          	auipc	a0,0x14
    80002bc2:	3ea50513          	addi	a0,a0,1002 # 80016fa8 <tickslock>
    80002bc6:	808fe0ef          	jal	80000bce <acquire>
    current_tick = ticks;
    80002bca:	00005997          	auipc	s3,0x5
    80002bce:	ca69a983          	lw	s3,-858(s3) # 80007870 <ticks>
    release(&tickslock);
    80002bd2:	00014517          	auipc	a0,0x14
    80002bd6:	3d650513          	addi	a0,a0,982 # 80016fa8 <tickslock>
    80002bda:	88cfe0ef          	jal	80000c66 <release>
    acquire(&p->lock);
    80002bde:	854a                	mv	a0,s2
    80002be0:	feffd0ef          	jal	80000bce <acquire>
    p->fork_times[p->fork_times_idx] = current_tick;
    80002be4:	1a892783          	lw	a5,424(s2)
    80002be8:	02079693          	slli	a3,a5,0x20
    80002bec:	01d6d713          	srli	a4,a3,0x1d
    80002bf0:	974a                	add	a4,a4,s2
    80002bf2:	1982                	slli	s3,s3,0x20
    80002bf4:	0209d993          	srli	s3,s3,0x20
    80002bf8:	17373c23          	sd	s3,376(a4)
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    80002bfc:	2785                	addiw	a5,a5,1
    80002bfe:	4719                	li	a4,6
    80002c00:	02e7f7bb          	remuw	a5,a5,a4
    80002c04:	1af92423          	sw	a5,424(s2)
    release(&p->lock);
    80002c08:	854a                	mv	a0,s2
    80002c0a:	85cfe0ef          	jal	80000c66 <release>
    80002c0e:	6942                	ld	s2,16(sp)
    80002c10:	69a2                	ld	s3,8(sp)
    80002c12:	bf59                	j	80002ba8 <sys_fork+0x14>

0000000080002c14 <sys_wait>:

uint64
sys_wait(void)
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c1c:	fe840593          	addi	a1,s0,-24
    80002c20:	4501                	li	a0,0
    80002c22:	e75ff0ef          	jal	80002a96 <argaddr>
  return kwait(p);
    80002c26:	fe843503          	ld	a0,-24(s0)
    80002c2a:	df2ff0ef          	jal	8000221c <kwait>
}
    80002c2e:	60e2                	ld	ra,24(sp)
    80002c30:	6442                	ld	s0,16(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret

0000000080002c36 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c36:	7179                	addi	sp,sp,-48
    80002c38:	f406                	sd	ra,40(sp)
    80002c3a:	f022                	sd	s0,32(sp)
    80002c3c:	ec26                	sd	s1,24(sp)
    80002c3e:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002c40:	fd840593          	addi	a1,s0,-40
    80002c44:	4501                	li	a0,0
    80002c46:	e35ff0ef          	jal	80002a7a <argint>
  argint(1, &t);
    80002c4a:	fdc40593          	addi	a1,s0,-36
    80002c4e:	4505                	li	a0,1
    80002c50:	e2bff0ef          	jal	80002a7a <argint>
  addr = myproc()->sz;
    80002c54:	c7bfe0ef          	jal	800018ce <myproc>
    80002c58:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002c5a:	fdc42703          	lw	a4,-36(s0)
    80002c5e:	4785                	li	a5,1
    80002c60:	02f70763          	beq	a4,a5,80002c8e <sys_sbrk+0x58>
    80002c64:	fd842783          	lw	a5,-40(s0)
    80002c68:	0207c363          	bltz	a5,80002c8e <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002c6c:	97a6                	add	a5,a5,s1
    80002c6e:	0297ee63          	bltu	a5,s1,80002caa <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002c72:	02000737          	lui	a4,0x2000
    80002c76:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002c78:	0736                	slli	a4,a4,0xd
    80002c7a:	02f76a63          	bltu	a4,a5,80002cae <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002c7e:	c51fe0ef          	jal	800018ce <myproc>
    80002c82:	fd842703          	lw	a4,-40(s0)
    80002c86:	653c                	ld	a5,72(a0)
    80002c88:	97ba                	add	a5,a5,a4
    80002c8a:	e53c                	sd	a5,72(a0)
    80002c8c:	a039                	j	80002c9a <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002c8e:	fd842503          	lw	a0,-40(s0)
    80002c92:	fb7fe0ef          	jal	80001c48 <growproc>
    80002c96:	00054863          	bltz	a0,80002ca6 <sys_sbrk+0x70>
  }
  return addr;
}
    80002c9a:	8526                	mv	a0,s1
    80002c9c:	70a2                	ld	ra,40(sp)
    80002c9e:	7402                	ld	s0,32(sp)
    80002ca0:	64e2                	ld	s1,24(sp)
    80002ca2:	6145                	addi	sp,sp,48
    80002ca4:	8082                	ret
      return -1;
    80002ca6:	54fd                	li	s1,-1
    80002ca8:	bfcd                	j	80002c9a <sys_sbrk+0x64>
      return -1;
    80002caa:	54fd                	li	s1,-1
    80002cac:	b7fd                	j	80002c9a <sys_sbrk+0x64>
      return -1;
    80002cae:	54fd                	li	s1,-1
    80002cb0:	b7ed                	j	80002c9a <sys_sbrk+0x64>

0000000080002cb2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cb2:	7139                	addi	sp,sp,-64
    80002cb4:	fc06                	sd	ra,56(sp)
    80002cb6:	f822                	sd	s0,48(sp)
    80002cb8:	f04a                	sd	s2,32(sp)
    80002cba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cbc:	fcc40593          	addi	a1,s0,-52
    80002cc0:	4501                	li	a0,0
    80002cc2:	db9ff0ef          	jal	80002a7a <argint>
  if(n < 0)
    80002cc6:	fcc42783          	lw	a5,-52(s0)
    80002cca:	0607c763          	bltz	a5,80002d38 <sys_sleep+0x86>
    n = 0;
  acquire(&tickslock);
    80002cce:	00014517          	auipc	a0,0x14
    80002cd2:	2da50513          	addi	a0,a0,730 # 80016fa8 <tickslock>
    80002cd6:	ef9fd0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002cda:	00005917          	auipc	s2,0x5
    80002cde:	b9692903          	lw	s2,-1130(s2) # 80007870 <ticks>
  while(ticks - ticks0 < n){
    80002ce2:	fcc42783          	lw	a5,-52(s0)
    80002ce6:	cf8d                	beqz	a5,80002d20 <sys_sleep+0x6e>
    80002ce8:	f426                	sd	s1,40(sp)
    80002cea:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cec:	00014997          	auipc	s3,0x14
    80002cf0:	2bc98993          	addi	s3,s3,700 # 80016fa8 <tickslock>
    80002cf4:	00005497          	auipc	s1,0x5
    80002cf8:	b7c48493          	addi	s1,s1,-1156 # 80007870 <ticks>
    if(killed(myproc())){
    80002cfc:	bd3fe0ef          	jal	800018ce <myproc>
    80002d00:	cf2ff0ef          	jal	800021f2 <killed>
    80002d04:	ed0d                	bnez	a0,80002d3e <sys_sleep+0x8c>
    sleep(&ticks, &tickslock);
    80002d06:	85ce                	mv	a1,s3
    80002d08:	8526                	mv	a0,s1
    80002d0a:	aacff0ef          	jal	80001fb6 <sleep>
  while(ticks - ticks0 < n){
    80002d0e:	409c                	lw	a5,0(s1)
    80002d10:	412787bb          	subw	a5,a5,s2
    80002d14:	fcc42703          	lw	a4,-52(s0)
    80002d18:	fee7e2e3          	bltu	a5,a4,80002cfc <sys_sleep+0x4a>
    80002d1c:	74a2                	ld	s1,40(sp)
    80002d1e:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002d20:	00014517          	auipc	a0,0x14
    80002d24:	28850513          	addi	a0,a0,648 # 80016fa8 <tickslock>
    80002d28:	f3ffd0ef          	jal	80000c66 <release>
  return 0;
    80002d2c:	4501                	li	a0,0
}
    80002d2e:	70e2                	ld	ra,56(sp)
    80002d30:	7442                	ld	s0,48(sp)
    80002d32:	7902                	ld	s2,32(sp)
    80002d34:	6121                	addi	sp,sp,64
    80002d36:	8082                	ret
    n = 0;
    80002d38:	fc042623          	sw	zero,-52(s0)
    80002d3c:	bf49                	j	80002cce <sys_sleep+0x1c>
      release(&tickslock);
    80002d3e:	00014517          	auipc	a0,0x14
    80002d42:	26a50513          	addi	a0,a0,618 # 80016fa8 <tickslock>
    80002d46:	f21fd0ef          	jal	80000c66 <release>
      return -1;
    80002d4a:	557d                	li	a0,-1
    80002d4c:	74a2                	ld	s1,40(sp)
    80002d4e:	69e2                	ld	s3,24(sp)
    80002d50:	bff9                	j	80002d2e <sys_sleep+0x7c>

0000000080002d52 <sys_kill>:

uint64
sys_kill(void)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d5a:	fec40593          	addi	a1,s0,-20
    80002d5e:	4501                	li	a0,0
    80002d60:	d1bff0ef          	jal	80002a7a <argint>
  return kkill(pid);
    80002d64:	fec42503          	lw	a0,-20(s0)
    80002d68:	c00ff0ef          	jal	80002168 <kkill>
}
    80002d6c:	60e2                	ld	ra,24(sp)
    80002d6e:	6442                	ld	s0,16(sp)
    80002d70:	6105                	addi	sp,sp,32
    80002d72:	8082                	ret

0000000080002d74 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	e426                	sd	s1,8(sp)
    80002d7c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d7e:	00014517          	auipc	a0,0x14
    80002d82:	22a50513          	addi	a0,a0,554 # 80016fa8 <tickslock>
    80002d86:	e49fd0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002d8a:	00005497          	auipc	s1,0x5
    80002d8e:	ae64a483          	lw	s1,-1306(s1) # 80007870 <ticks>
  release(&tickslock);
    80002d92:	00014517          	auipc	a0,0x14
    80002d96:	21650513          	addi	a0,a0,534 # 80016fa8 <tickslock>
    80002d9a:	ecdfd0ef          	jal	80000c66 <release>
  return xticks;
}
    80002d9e:	02049513          	slli	a0,s1,0x20
    80002da2:	9101                	srli	a0,a0,0x20
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	64a2                	ld	s1,8(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <sys_proc_info>:

uint64
sys_proc_info(void)
{
    80002dae:	bc010113          	addi	sp,sp,-1088
    80002db2:	42113c23          	sd	ra,1080(sp)
    80002db6:	42813823          	sd	s0,1072(sp)
    80002dba:	44010413          	addi	s0,sp,1088
  uint64 addr;
  struct p_info pinfo;
  struct proc *p;

  // Lấy địa chỉ con trỏ từ user space truyền vào
  if(argaddr(0, &addr) < 0)
    80002dbe:	fc840593          	addi	a1,s0,-56
    80002dc2:	4501                	li	a0,0
    80002dc4:	cd3ff0ef          	jal	80002a96 <argaddr>
    80002dc8:	08054463          	bltz	a0,80002e50 <sys_proc_info+0xa2>
    80002dcc:	42913423          	sd	s1,1064(sp)
    80002dd0:	43213023          	sd	s2,1056(sp)
    80002dd4:	41313c23          	sd	s3,1048(sp)
    80002dd8:	bc840913          	addi	s2,s0,-1080
    return -1;

  // Duyệt qua bảng tiến trình
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    80002ddc:	0000d497          	auipc	s1,0xd
    80002de0:	fcc48493          	addi	s1,s1,-52 # 8000fda8 <proc>
    80002de4:	00014997          	auipc	s3,0x14
    80002de8:	1c498993          	addi	s3,s3,452 # 80016fa8 <tickslock>
    // Cần giữ lock khi đọc dữ liệu để tránh race condition (tuỳ chọn nhưng nên làm)
    acquire(&p->lock);
    80002dec:	8526                	mv	a0,s1
    80002dee:	de1fd0ef          	jal	80000bce <acquire>
    
    pinfo.pid[i] = p->pid;
    80002df2:	589c                	lw	a5,48(s1)
    80002df4:	00f92023          	sw	a5,0(s2)
    pinfo.state[i] = p->state;
    80002df8:	4c9c                	lw	a5,24(s1)
    80002dfa:	30f92023          	sw	a5,768(s2)
    pinfo.priority[i] = p->priority;    
    80002dfe:	1684a783          	lw	a5,360(s1)
    80002e02:	10f92023          	sw	a5,256(s2)
    pinfo.ticks_used[i] = p->ticks_used;
    80002e06:	16c4a783          	lw	a5,364(s1)
    80002e0a:	20f92023          	sw	a5,512(s2)
    
    release(&p->lock);
    80002e0e:	8526                	mv	a0,s1
    80002e10:	e57fd0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e14:	1c848493          	addi	s1,s1,456
    80002e18:	0911                	addi	s2,s2,4
    80002e1a:	fd3499e3          	bne	s1,s3,80002dec <sys_proc_info+0x3e>
    i++;
  }

  // Copy dữ liệu từ kernel space ra user space
  // Lưu ý: copyout trả về -1 nếu lỗi, 0 nếu thành công
  if(copyout(myproc()->pagetable, addr, (char *)&pinfo, sizeof(pinfo)) < 0)
    80002e1e:	ab1fe0ef          	jal	800018ce <myproc>
    80002e22:	40000693          	li	a3,1024
    80002e26:	bc840613          	addi	a2,s0,-1080
    80002e2a:	fc843583          	ld	a1,-56(s0)
    80002e2e:	6928                	ld	a0,80(a0)
    80002e30:	fb2fe0ef          	jal	800015e2 <copyout>
    80002e34:	957d                	srai	a0,a0,0x3f
    80002e36:	42813483          	ld	s1,1064(sp)
    80002e3a:	42013903          	ld	s2,1056(sp)
    80002e3e:	41813983          	ld	s3,1048(sp)
    return -1;

  return 0;
}
    80002e42:	43813083          	ld	ra,1080(sp)
    80002e46:	43013403          	ld	s0,1072(sp)
    80002e4a:	44010113          	addi	sp,sp,1088
    80002e4e:	8082                	ret
    return -1;
    80002e50:	557d                	li	a0,-1
    80002e52:	bfc5                	j	80002e42 <sys_proc_info+0x94>

0000000080002e54 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e54:	7179                	addi	sp,sp,-48
    80002e56:	f406                	sd	ra,40(sp)
    80002e58:	f022                	sd	s0,32(sp)
    80002e5a:	ec26                	sd	s1,24(sp)
    80002e5c:	e84a                	sd	s2,16(sp)
    80002e5e:	e44e                	sd	s3,8(sp)
    80002e60:	e052                	sd	s4,0(sp)
    80002e62:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e64:	00004597          	auipc	a1,0x4
    80002e68:	52c58593          	addi	a1,a1,1324 # 80007390 <etext+0x390>
    80002e6c:	00014517          	auipc	a0,0x14
    80002e70:	15450513          	addi	a0,a0,340 # 80016fc0 <bcache>
    80002e74:	cdbfd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e78:	0001c797          	auipc	a5,0x1c
    80002e7c:	14878793          	addi	a5,a5,328 # 8001efc0 <bcache+0x8000>
    80002e80:	0001c717          	auipc	a4,0x1c
    80002e84:	3a870713          	addi	a4,a4,936 # 8001f228 <bcache+0x8268>
    80002e88:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e8c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e90:	00014497          	auipc	s1,0x14
    80002e94:	14848493          	addi	s1,s1,328 # 80016fd8 <bcache+0x18>
    b->next = bcache.head.next;
    80002e98:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e9a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e9c:	00004a17          	auipc	s4,0x4
    80002ea0:	4fca0a13          	addi	s4,s4,1276 # 80007398 <etext+0x398>
    b->next = bcache.head.next;
    80002ea4:	2b893783          	ld	a5,696(s2)
    80002ea8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eaa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eae:	85d2                	mv	a1,s4
    80002eb0:	01048513          	addi	a0,s1,16
    80002eb4:	322010ef          	jal	800041d6 <initsleeplock>
    bcache.head.next->prev = b;
    80002eb8:	2b893783          	ld	a5,696(s2)
    80002ebc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ebe:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ec2:	45848493          	addi	s1,s1,1112
    80002ec6:	fd349fe3          	bne	s1,s3,80002ea4 <binit+0x50>
  }
}
    80002eca:	70a2                	ld	ra,40(sp)
    80002ecc:	7402                	ld	s0,32(sp)
    80002ece:	64e2                	ld	s1,24(sp)
    80002ed0:	6942                	ld	s2,16(sp)
    80002ed2:	69a2                	ld	s3,8(sp)
    80002ed4:	6a02                	ld	s4,0(sp)
    80002ed6:	6145                	addi	sp,sp,48
    80002ed8:	8082                	ret

0000000080002eda <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eda:	7179                	addi	sp,sp,-48
    80002edc:	f406                	sd	ra,40(sp)
    80002ede:	f022                	sd	s0,32(sp)
    80002ee0:	ec26                	sd	s1,24(sp)
    80002ee2:	e84a                	sd	s2,16(sp)
    80002ee4:	e44e                	sd	s3,8(sp)
    80002ee6:	1800                	addi	s0,sp,48
    80002ee8:	892a                	mv	s2,a0
    80002eea:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002eec:	00014517          	auipc	a0,0x14
    80002ef0:	0d450513          	addi	a0,a0,212 # 80016fc0 <bcache>
    80002ef4:	cdbfd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ef8:	0001c497          	auipc	s1,0x1c
    80002efc:	3804b483          	ld	s1,896(s1) # 8001f278 <bcache+0x82b8>
    80002f00:	0001c797          	auipc	a5,0x1c
    80002f04:	32878793          	addi	a5,a5,808 # 8001f228 <bcache+0x8268>
    80002f08:	02f48b63          	beq	s1,a5,80002f3e <bread+0x64>
    80002f0c:	873e                	mv	a4,a5
    80002f0e:	a021                	j	80002f16 <bread+0x3c>
    80002f10:	68a4                	ld	s1,80(s1)
    80002f12:	02e48663          	beq	s1,a4,80002f3e <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002f16:	449c                	lw	a5,8(s1)
    80002f18:	ff279ce3          	bne	a5,s2,80002f10 <bread+0x36>
    80002f1c:	44dc                	lw	a5,12(s1)
    80002f1e:	ff3799e3          	bne	a5,s3,80002f10 <bread+0x36>
      b->refcnt++;
    80002f22:	40bc                	lw	a5,64(s1)
    80002f24:	2785                	addiw	a5,a5,1
    80002f26:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f28:	00014517          	auipc	a0,0x14
    80002f2c:	09850513          	addi	a0,a0,152 # 80016fc0 <bcache>
    80002f30:	d37fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002f34:	01048513          	addi	a0,s1,16
    80002f38:	2d4010ef          	jal	8000420c <acquiresleep>
      return b;
    80002f3c:	a889                	j	80002f8e <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f3e:	0001c497          	auipc	s1,0x1c
    80002f42:	3324b483          	ld	s1,818(s1) # 8001f270 <bcache+0x82b0>
    80002f46:	0001c797          	auipc	a5,0x1c
    80002f4a:	2e278793          	addi	a5,a5,738 # 8001f228 <bcache+0x8268>
    80002f4e:	00f48863          	beq	s1,a5,80002f5e <bread+0x84>
    80002f52:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f54:	40bc                	lw	a5,64(s1)
    80002f56:	cb91                	beqz	a5,80002f6a <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f58:	64a4                	ld	s1,72(s1)
    80002f5a:	fee49de3          	bne	s1,a4,80002f54 <bread+0x7a>
  panic("bget: no buffers");
    80002f5e:	00004517          	auipc	a0,0x4
    80002f62:	44250513          	addi	a0,a0,1090 # 800073a0 <etext+0x3a0>
    80002f66:	87bfd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002f6a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f6e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f72:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f76:	4785                	li	a5,1
    80002f78:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f7a:	00014517          	auipc	a0,0x14
    80002f7e:	04650513          	addi	a0,a0,70 # 80016fc0 <bcache>
    80002f82:	ce5fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	282010ef          	jal	8000420c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f8e:	409c                	lw	a5,0(s1)
    80002f90:	cb89                	beqz	a5,80002fa2 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f92:	8526                	mv	a0,s1
    80002f94:	70a2                	ld	ra,40(sp)
    80002f96:	7402                	ld	s0,32(sp)
    80002f98:	64e2                	ld	s1,24(sp)
    80002f9a:	6942                	ld	s2,16(sp)
    80002f9c:	69a2                	ld	s3,8(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fa2:	4581                	li	a1,0
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	2cb020ef          	jal	80005a70 <virtio_disk_rw>
    b->valid = 1;
    80002faa:	4785                	li	a5,1
    80002fac:	c09c                	sw	a5,0(s1)
  return b;
    80002fae:	b7d5                	j	80002f92 <bread+0xb8>

0000000080002fb0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	1000                	addi	s0,sp,32
    80002fba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fbc:	0541                	addi	a0,a0,16
    80002fbe:	2cc010ef          	jal	8000428a <holdingsleep>
    80002fc2:	c911                	beqz	a0,80002fd6 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fc4:	4585                	li	a1,1
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	2a9020ef          	jal	80005a70 <virtio_disk_rw>
}
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret
    panic("bwrite");
    80002fd6:	00004517          	auipc	a0,0x4
    80002fda:	3e250513          	addi	a0,a0,994 # 800073b8 <etext+0x3b8>
    80002fde:	803fd0ef          	jal	800007e0 <panic>

0000000080002fe2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	e04a                	sd	s2,0(sp)
    80002fec:	1000                	addi	s0,sp,32
    80002fee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ff0:	01050913          	addi	s2,a0,16
    80002ff4:	854a                	mv	a0,s2
    80002ff6:	294010ef          	jal	8000428a <holdingsleep>
    80002ffa:	c135                	beqz	a0,8000305e <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002ffc:	854a                	mv	a0,s2
    80002ffe:	254010ef          	jal	80004252 <releasesleep>

  acquire(&bcache.lock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	fbe50513          	addi	a0,a0,-66 # 80016fc0 <bcache>
    8000300a:	bc5fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    8000300e:	40bc                	lw	a5,64(s1)
    80003010:	37fd                	addiw	a5,a5,-1
    80003012:	0007871b          	sext.w	a4,a5
    80003016:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003018:	e71d                	bnez	a4,80003046 <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000301a:	68b8                	ld	a4,80(s1)
    8000301c:	64bc                	ld	a5,72(s1)
    8000301e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003020:	68b8                	ld	a4,80(s1)
    80003022:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003024:	0001c797          	auipc	a5,0x1c
    80003028:	f9c78793          	addi	a5,a5,-100 # 8001efc0 <bcache+0x8000>
    8000302c:	2b87b703          	ld	a4,696(a5)
    80003030:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003032:	0001c717          	auipc	a4,0x1c
    80003036:	1f670713          	addi	a4,a4,502 # 8001f228 <bcache+0x8268>
    8000303a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000303c:	2b87b703          	ld	a4,696(a5)
    80003040:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003042:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	f7a50513          	addi	a0,a0,-134 # 80016fc0 <bcache>
    8000304e:	c19fd0ef          	jal	80000c66 <release>
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	64a2                	ld	s1,8(sp)
    80003058:	6902                	ld	s2,0(sp)
    8000305a:	6105                	addi	sp,sp,32
    8000305c:	8082                	ret
    panic("brelse");
    8000305e:	00004517          	auipc	a0,0x4
    80003062:	36250513          	addi	a0,a0,866 # 800073c0 <etext+0x3c0>
    80003066:	f7afd0ef          	jal	800007e0 <panic>

000000008000306a <bpin>:

void
bpin(struct buf *b) {
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	f4a50513          	addi	a0,a0,-182 # 80016fc0 <bcache>
    8000307e:	b51fd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80003082:	40bc                	lw	a5,64(s1)
    80003084:	2785                	addiw	a5,a5,1
    80003086:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	f3850513          	addi	a0,a0,-200 # 80016fc0 <bcache>
    80003090:	bd7fd0ef          	jal	80000c66 <release>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret

000000008000309e <bunpin>:

void
bunpin(struct buf *b) {
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	1000                	addi	s0,sp,32
    800030a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	f1650513          	addi	a0,a0,-234 # 80016fc0 <bcache>
    800030b2:	b1dfd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    800030b6:	40bc                	lw	a5,64(s1)
    800030b8:	37fd                	addiw	a5,a5,-1
    800030ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	f0450513          	addi	a0,a0,-252 # 80016fc0 <bcache>
    800030c4:	ba3fd0ef          	jal	80000c66 <release>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	e04a                	sd	s2,0(sp)
    800030dc:	1000                	addi	s0,sp,32
    800030de:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030e0:	00d5d59b          	srliw	a1,a1,0xd
    800030e4:	0001c797          	auipc	a5,0x1c
    800030e8:	5b87a783          	lw	a5,1464(a5) # 8001f69c <sb+0x1c>
    800030ec:	9dbd                	addw	a1,a1,a5
    800030ee:	dedff0ef          	jal	80002eda <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030f2:	0074f713          	andi	a4,s1,7
    800030f6:	4785                	li	a5,1
    800030f8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030fc:	14ce                	slli	s1,s1,0x33
    800030fe:	90d9                	srli	s1,s1,0x36
    80003100:	00950733          	add	a4,a0,s1
    80003104:	05874703          	lbu	a4,88(a4)
    80003108:	00e7f6b3          	and	a3,a5,a4
    8000310c:	c29d                	beqz	a3,80003132 <bfree+0x60>
    8000310e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003110:	94aa                	add	s1,s1,a0
    80003112:	fff7c793          	not	a5,a5
    80003116:	8f7d                	and	a4,a4,a5
    80003118:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000311c:	7f9000ef          	jal	80004114 <log_write>
  brelse(bp);
    80003120:	854a                	mv	a0,s2
    80003122:	ec1ff0ef          	jal	80002fe2 <brelse>
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6902                	ld	s2,0(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret
    panic("freeing free block");
    80003132:	00004517          	auipc	a0,0x4
    80003136:	29650513          	addi	a0,a0,662 # 800073c8 <etext+0x3c8>
    8000313a:	ea6fd0ef          	jal	800007e0 <panic>

000000008000313e <balloc>:
{
    8000313e:	711d                	addi	sp,sp,-96
    80003140:	ec86                	sd	ra,88(sp)
    80003142:	e8a2                	sd	s0,80(sp)
    80003144:	e4a6                	sd	s1,72(sp)
    80003146:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003148:	0001c797          	auipc	a5,0x1c
    8000314c:	53c7a783          	lw	a5,1340(a5) # 8001f684 <sb+0x4>
    80003150:	0e078f63          	beqz	a5,8000324e <balloc+0x110>
    80003154:	e0ca                	sd	s2,64(sp)
    80003156:	fc4e                	sd	s3,56(sp)
    80003158:	f852                	sd	s4,48(sp)
    8000315a:	f456                	sd	s5,40(sp)
    8000315c:	f05a                	sd	s6,32(sp)
    8000315e:	ec5e                	sd	s7,24(sp)
    80003160:	e862                	sd	s8,16(sp)
    80003162:	e466                	sd	s9,8(sp)
    80003164:	8baa                	mv	s7,a0
    80003166:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003168:	0001cb17          	auipc	s6,0x1c
    8000316c:	518b0b13          	addi	s6,s6,1304 # 8001f680 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003170:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003172:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003174:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003176:	6c89                	lui	s9,0x2
    80003178:	a0b5                	j	800031e4 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000317a:	97ca                	add	a5,a5,s2
    8000317c:	8e55                	or	a2,a2,a3
    8000317e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	791000ef          	jal	80004114 <log_write>
        brelse(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	e59ff0ef          	jal	80002fe2 <brelse>
  bp = bread(dev, bno);
    8000318e:	85a6                	mv	a1,s1
    80003190:	855e                	mv	a0,s7
    80003192:	d49ff0ef          	jal	80002eda <bread>
    80003196:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003198:	40000613          	li	a2,1024
    8000319c:	4581                	li	a1,0
    8000319e:	05850513          	addi	a0,a0,88
    800031a2:	b01fd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    800031a6:	854a                	mv	a0,s2
    800031a8:	76d000ef          	jal	80004114 <log_write>
  brelse(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	e35ff0ef          	jal	80002fe2 <brelse>
}
    800031b2:	6906                	ld	s2,64(sp)
    800031b4:	79e2                	ld	s3,56(sp)
    800031b6:	7a42                	ld	s4,48(sp)
    800031b8:	7aa2                	ld	s5,40(sp)
    800031ba:	7b02                	ld	s6,32(sp)
    800031bc:	6be2                	ld	s7,24(sp)
    800031be:	6c42                	ld	s8,16(sp)
    800031c0:	6ca2                	ld	s9,8(sp)
}
    800031c2:	8526                	mv	a0,s1
    800031c4:	60e6                	ld	ra,88(sp)
    800031c6:	6446                	ld	s0,80(sp)
    800031c8:	64a6                	ld	s1,72(sp)
    800031ca:	6125                	addi	sp,sp,96
    800031cc:	8082                	ret
    brelse(bp);
    800031ce:	854a                	mv	a0,s2
    800031d0:	e13ff0ef          	jal	80002fe2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031d4:	015c87bb          	addw	a5,s9,s5
    800031d8:	00078a9b          	sext.w	s5,a5
    800031dc:	004b2703          	lw	a4,4(s6)
    800031e0:	04eaff63          	bgeu	s5,a4,8000323e <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    800031e4:	41fad79b          	sraiw	a5,s5,0x1f
    800031e8:	0137d79b          	srliw	a5,a5,0x13
    800031ec:	015787bb          	addw	a5,a5,s5
    800031f0:	40d7d79b          	sraiw	a5,a5,0xd
    800031f4:	01cb2583          	lw	a1,28(s6)
    800031f8:	9dbd                	addw	a1,a1,a5
    800031fa:	855e                	mv	a0,s7
    800031fc:	cdfff0ef          	jal	80002eda <bread>
    80003200:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003202:	004b2503          	lw	a0,4(s6)
    80003206:	000a849b          	sext.w	s1,s5
    8000320a:	8762                	mv	a4,s8
    8000320c:	fca4f1e3          	bgeu	s1,a0,800031ce <balloc+0x90>
      m = 1 << (bi % 8);
    80003210:	00777693          	andi	a3,a4,7
    80003214:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003218:	41f7579b          	sraiw	a5,a4,0x1f
    8000321c:	01d7d79b          	srliw	a5,a5,0x1d
    80003220:	9fb9                	addw	a5,a5,a4
    80003222:	4037d79b          	sraiw	a5,a5,0x3
    80003226:	00f90633          	add	a2,s2,a5
    8000322a:	05864603          	lbu	a2,88(a2)
    8000322e:	00c6f5b3          	and	a1,a3,a2
    80003232:	d5a1                	beqz	a1,8000317a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003234:	2705                	addiw	a4,a4,1
    80003236:	2485                	addiw	s1,s1,1
    80003238:	fd471ae3          	bne	a4,s4,8000320c <balloc+0xce>
    8000323c:	bf49                	j	800031ce <balloc+0x90>
    8000323e:	6906                	ld	s2,64(sp)
    80003240:	79e2                	ld	s3,56(sp)
    80003242:	7a42                	ld	s4,48(sp)
    80003244:	7aa2                	ld	s5,40(sp)
    80003246:	7b02                	ld	s6,32(sp)
    80003248:	6be2                	ld	s7,24(sp)
    8000324a:	6c42                	ld	s8,16(sp)
    8000324c:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    8000324e:	00004517          	auipc	a0,0x4
    80003252:	19250513          	addi	a0,a0,402 # 800073e0 <etext+0x3e0>
    80003256:	aa4fd0ef          	jal	800004fa <printf>
  return 0;
    8000325a:	4481                	li	s1,0
    8000325c:	b79d                	j	800031c2 <balloc+0x84>

000000008000325e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000325e:	7179                	addi	sp,sp,-48
    80003260:	f406                	sd	ra,40(sp)
    80003262:	f022                	sd	s0,32(sp)
    80003264:	ec26                	sd	s1,24(sp)
    80003266:	e84a                	sd	s2,16(sp)
    80003268:	e44e                	sd	s3,8(sp)
    8000326a:	1800                	addi	s0,sp,48
    8000326c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000326e:	47ad                	li	a5,11
    80003270:	02b7e663          	bltu	a5,a1,8000329c <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003274:	02059793          	slli	a5,a1,0x20
    80003278:	01e7d593          	srli	a1,a5,0x1e
    8000327c:	00b504b3          	add	s1,a0,a1
    80003280:	0504a903          	lw	s2,80(s1)
    80003284:	06091a63          	bnez	s2,800032f8 <bmap+0x9a>
      addr = balloc(ip->dev);
    80003288:	4108                	lw	a0,0(a0)
    8000328a:	eb5ff0ef          	jal	8000313e <balloc>
    8000328e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003292:	06090363          	beqz	s2,800032f8 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80003296:	0524a823          	sw	s2,80(s1)
    8000329a:	a8b9                	j	800032f8 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000329c:	ff45849b          	addiw	s1,a1,-12
    800032a0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032a4:	0ff00793          	li	a5,255
    800032a8:	06e7ee63          	bltu	a5,a4,80003324 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032ac:	08052903          	lw	s2,128(a0)
    800032b0:	00091d63          	bnez	s2,800032ca <bmap+0x6c>
      addr = balloc(ip->dev);
    800032b4:	4108                	lw	a0,0(a0)
    800032b6:	e89ff0ef          	jal	8000313e <balloc>
    800032ba:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032be:	02090d63          	beqz	s2,800032f8 <bmap+0x9a>
    800032c2:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032c4:	0929a023          	sw	s2,128(s3)
    800032c8:	a011                	j	800032cc <bmap+0x6e>
    800032ca:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800032cc:	85ca                	mv	a1,s2
    800032ce:	0009a503          	lw	a0,0(s3)
    800032d2:	c09ff0ef          	jal	80002eda <bread>
    800032d6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032d8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032dc:	02049713          	slli	a4,s1,0x20
    800032e0:	01e75593          	srli	a1,a4,0x1e
    800032e4:	00b784b3          	add	s1,a5,a1
    800032e8:	0004a903          	lw	s2,0(s1)
    800032ec:	00090e63          	beqz	s2,80003308 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032f0:	8552                	mv	a0,s4
    800032f2:	cf1ff0ef          	jal	80002fe2 <brelse>
    return addr;
    800032f6:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800032f8:	854a                	mv	a0,s2
    800032fa:	70a2                	ld	ra,40(sp)
    800032fc:	7402                	ld	s0,32(sp)
    800032fe:	64e2                	ld	s1,24(sp)
    80003300:	6942                	ld	s2,16(sp)
    80003302:	69a2                	ld	s3,8(sp)
    80003304:	6145                	addi	sp,sp,48
    80003306:	8082                	ret
      addr = balloc(ip->dev);
    80003308:	0009a503          	lw	a0,0(s3)
    8000330c:	e33ff0ef          	jal	8000313e <balloc>
    80003310:	0005091b          	sext.w	s2,a0
      if(addr){
    80003314:	fc090ee3          	beqz	s2,800032f0 <bmap+0x92>
        a[bn] = addr;
    80003318:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000331c:	8552                	mv	a0,s4
    8000331e:	5f7000ef          	jal	80004114 <log_write>
    80003322:	b7f9                	j	800032f0 <bmap+0x92>
    80003324:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003326:	00004517          	auipc	a0,0x4
    8000332a:	0d250513          	addi	a0,a0,210 # 800073f8 <etext+0x3f8>
    8000332e:	cb2fd0ef          	jal	800007e0 <panic>

0000000080003332 <iget>:
{
    80003332:	7179                	addi	sp,sp,-48
    80003334:	f406                	sd	ra,40(sp)
    80003336:	f022                	sd	s0,32(sp)
    80003338:	ec26                	sd	s1,24(sp)
    8000333a:	e84a                	sd	s2,16(sp)
    8000333c:	e44e                	sd	s3,8(sp)
    8000333e:	e052                	sd	s4,0(sp)
    80003340:	1800                	addi	s0,sp,48
    80003342:	89aa                	mv	s3,a0
    80003344:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003346:	0001c517          	auipc	a0,0x1c
    8000334a:	35a50513          	addi	a0,a0,858 # 8001f6a0 <itable>
    8000334e:	881fd0ef          	jal	80000bce <acquire>
  empty = 0;
    80003352:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003354:	0001c497          	auipc	s1,0x1c
    80003358:	36448493          	addi	s1,s1,868 # 8001f6b8 <itable+0x18>
    8000335c:	0001e697          	auipc	a3,0x1e
    80003360:	dec68693          	addi	a3,a3,-532 # 80021148 <log>
    80003364:	a039                	j	80003372 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003366:	02090963          	beqz	s2,80003398 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000336a:	08848493          	addi	s1,s1,136
    8000336e:	02d48863          	beq	s1,a3,8000339e <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003372:	449c                	lw	a5,8(s1)
    80003374:	fef059e3          	blez	a5,80003366 <iget+0x34>
    80003378:	4098                	lw	a4,0(s1)
    8000337a:	ff3716e3          	bne	a4,s3,80003366 <iget+0x34>
    8000337e:	40d8                	lw	a4,4(s1)
    80003380:	ff4713e3          	bne	a4,s4,80003366 <iget+0x34>
      ip->ref++;
    80003384:	2785                	addiw	a5,a5,1
    80003386:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003388:	0001c517          	auipc	a0,0x1c
    8000338c:	31850513          	addi	a0,a0,792 # 8001f6a0 <itable>
    80003390:	8d7fd0ef          	jal	80000c66 <release>
      return ip;
    80003394:	8926                	mv	s2,s1
    80003396:	a02d                	j	800033c0 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003398:	fbe9                	bnez	a5,8000336a <iget+0x38>
      empty = ip;
    8000339a:	8926                	mv	s2,s1
    8000339c:	b7f9                	j	8000336a <iget+0x38>
  if(empty == 0)
    8000339e:	02090a63          	beqz	s2,800033d2 <iget+0xa0>
  ip->dev = dev;
    800033a2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033a6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033aa:	4785                	li	a5,1
    800033ac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033b0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033b4:	0001c517          	auipc	a0,0x1c
    800033b8:	2ec50513          	addi	a0,a0,748 # 8001f6a0 <itable>
    800033bc:	8abfd0ef          	jal	80000c66 <release>
}
    800033c0:	854a                	mv	a0,s2
    800033c2:	70a2                	ld	ra,40(sp)
    800033c4:	7402                	ld	s0,32(sp)
    800033c6:	64e2                	ld	s1,24(sp)
    800033c8:	6942                	ld	s2,16(sp)
    800033ca:	69a2                	ld	s3,8(sp)
    800033cc:	6a02                	ld	s4,0(sp)
    800033ce:	6145                	addi	sp,sp,48
    800033d0:	8082                	ret
    panic("iget: no inodes");
    800033d2:	00004517          	auipc	a0,0x4
    800033d6:	03e50513          	addi	a0,a0,62 # 80007410 <etext+0x410>
    800033da:	c06fd0ef          	jal	800007e0 <panic>

00000000800033de <iinit>:
{
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033ec:	00004597          	auipc	a1,0x4
    800033f0:	03458593          	addi	a1,a1,52 # 80007420 <etext+0x420>
    800033f4:	0001c517          	auipc	a0,0x1c
    800033f8:	2ac50513          	addi	a0,a0,684 # 8001f6a0 <itable>
    800033fc:	f52fd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003400:	0001c497          	auipc	s1,0x1c
    80003404:	2c848493          	addi	s1,s1,712 # 8001f6c8 <itable+0x28>
    80003408:	0001e997          	auipc	s3,0x1e
    8000340c:	d5098993          	addi	s3,s3,-688 # 80021158 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003410:	00004917          	auipc	s2,0x4
    80003414:	01890913          	addi	s2,s2,24 # 80007428 <etext+0x428>
    80003418:	85ca                	mv	a1,s2
    8000341a:	8526                	mv	a0,s1
    8000341c:	5bb000ef          	jal	800041d6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003420:	08848493          	addi	s1,s1,136
    80003424:	ff349ae3          	bne	s1,s3,80003418 <iinit+0x3a>
}
    80003428:	70a2                	ld	ra,40(sp)
    8000342a:	7402                	ld	s0,32(sp)
    8000342c:	64e2                	ld	s1,24(sp)
    8000342e:	6942                	ld	s2,16(sp)
    80003430:	69a2                	ld	s3,8(sp)
    80003432:	6145                	addi	sp,sp,48
    80003434:	8082                	ret

0000000080003436 <ialloc>:
{
    80003436:	7139                	addi	sp,sp,-64
    80003438:	fc06                	sd	ra,56(sp)
    8000343a:	f822                	sd	s0,48(sp)
    8000343c:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000343e:	0001c717          	auipc	a4,0x1c
    80003442:	24e72703          	lw	a4,590(a4) # 8001f68c <sb+0xc>
    80003446:	4785                	li	a5,1
    80003448:	06e7f063          	bgeu	a5,a4,800034a8 <ialloc+0x72>
    8000344c:	f426                	sd	s1,40(sp)
    8000344e:	f04a                	sd	s2,32(sp)
    80003450:	ec4e                	sd	s3,24(sp)
    80003452:	e852                	sd	s4,16(sp)
    80003454:	e456                	sd	s5,8(sp)
    80003456:	e05a                	sd	s6,0(sp)
    80003458:	8aaa                	mv	s5,a0
    8000345a:	8b2e                	mv	s6,a1
    8000345c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000345e:	0001ca17          	auipc	s4,0x1c
    80003462:	222a0a13          	addi	s4,s4,546 # 8001f680 <sb>
    80003466:	00495593          	srli	a1,s2,0x4
    8000346a:	018a2783          	lw	a5,24(s4)
    8000346e:	9dbd                	addw	a1,a1,a5
    80003470:	8556                	mv	a0,s5
    80003472:	a69ff0ef          	jal	80002eda <bread>
    80003476:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003478:	05850993          	addi	s3,a0,88
    8000347c:	00f97793          	andi	a5,s2,15
    80003480:	079a                	slli	a5,a5,0x6
    80003482:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003484:	00099783          	lh	a5,0(s3)
    80003488:	cb9d                	beqz	a5,800034be <ialloc+0x88>
    brelse(bp);
    8000348a:	b59ff0ef          	jal	80002fe2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000348e:	0905                	addi	s2,s2,1
    80003490:	00ca2703          	lw	a4,12(s4)
    80003494:	0009079b          	sext.w	a5,s2
    80003498:	fce7e7e3          	bltu	a5,a4,80003466 <ialloc+0x30>
    8000349c:	74a2                	ld	s1,40(sp)
    8000349e:	7902                	ld	s2,32(sp)
    800034a0:	69e2                	ld	s3,24(sp)
    800034a2:	6a42                	ld	s4,16(sp)
    800034a4:	6aa2                	ld	s5,8(sp)
    800034a6:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800034a8:	00004517          	auipc	a0,0x4
    800034ac:	f8850513          	addi	a0,a0,-120 # 80007430 <etext+0x430>
    800034b0:	84afd0ef          	jal	800004fa <printf>
  return 0;
    800034b4:	4501                	li	a0,0
}
    800034b6:	70e2                	ld	ra,56(sp)
    800034b8:	7442                	ld	s0,48(sp)
    800034ba:	6121                	addi	sp,sp,64
    800034bc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800034be:	04000613          	li	a2,64
    800034c2:	4581                	li	a1,0
    800034c4:	854e                	mv	a0,s3
    800034c6:	fdcfd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    800034ca:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034ce:	8526                	mv	a0,s1
    800034d0:	445000ef          	jal	80004114 <log_write>
      brelse(bp);
    800034d4:	8526                	mv	a0,s1
    800034d6:	b0dff0ef          	jal	80002fe2 <brelse>
      return iget(dev, inum);
    800034da:	0009059b          	sext.w	a1,s2
    800034de:	8556                	mv	a0,s5
    800034e0:	e53ff0ef          	jal	80003332 <iget>
    800034e4:	74a2                	ld	s1,40(sp)
    800034e6:	7902                	ld	s2,32(sp)
    800034e8:	69e2                	ld	s3,24(sp)
    800034ea:	6a42                	ld	s4,16(sp)
    800034ec:	6aa2                	ld	s5,8(sp)
    800034ee:	6b02                	ld	s6,0(sp)
    800034f0:	b7d9                	j	800034b6 <ialloc+0x80>

00000000800034f2 <iupdate>:
{
    800034f2:	1101                	addi	sp,sp,-32
    800034f4:	ec06                	sd	ra,24(sp)
    800034f6:	e822                	sd	s0,16(sp)
    800034f8:	e426                	sd	s1,8(sp)
    800034fa:	e04a                	sd	s2,0(sp)
    800034fc:	1000                	addi	s0,sp,32
    800034fe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003500:	415c                	lw	a5,4(a0)
    80003502:	0047d79b          	srliw	a5,a5,0x4
    80003506:	0001c597          	auipc	a1,0x1c
    8000350a:	1925a583          	lw	a1,402(a1) # 8001f698 <sb+0x18>
    8000350e:	9dbd                	addw	a1,a1,a5
    80003510:	4108                	lw	a0,0(a0)
    80003512:	9c9ff0ef          	jal	80002eda <bread>
    80003516:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003518:	05850793          	addi	a5,a0,88
    8000351c:	40d8                	lw	a4,4(s1)
    8000351e:	8b3d                	andi	a4,a4,15
    80003520:	071a                	slli	a4,a4,0x6
    80003522:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003524:	04449703          	lh	a4,68(s1)
    80003528:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000352c:	04649703          	lh	a4,70(s1)
    80003530:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003534:	04849703          	lh	a4,72(s1)
    80003538:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000353c:	04a49703          	lh	a4,74(s1)
    80003540:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003544:	44f8                	lw	a4,76(s1)
    80003546:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003548:	03400613          	li	a2,52
    8000354c:	05048593          	addi	a1,s1,80
    80003550:	00c78513          	addi	a0,a5,12
    80003554:	faafd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    80003558:	854a                	mv	a0,s2
    8000355a:	3bb000ef          	jal	80004114 <log_write>
  brelse(bp);
    8000355e:	854a                	mv	a0,s2
    80003560:	a83ff0ef          	jal	80002fe2 <brelse>
}
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	64a2                	ld	s1,8(sp)
    8000356a:	6902                	ld	s2,0(sp)
    8000356c:	6105                	addi	sp,sp,32
    8000356e:	8082                	ret

0000000080003570 <idup>:
{
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	1000                	addi	s0,sp,32
    8000357a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000357c:	0001c517          	auipc	a0,0x1c
    80003580:	12450513          	addi	a0,a0,292 # 8001f6a0 <itable>
    80003584:	e4afd0ef          	jal	80000bce <acquire>
  ip->ref++;
    80003588:	449c                	lw	a5,8(s1)
    8000358a:	2785                	addiw	a5,a5,1
    8000358c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000358e:	0001c517          	auipc	a0,0x1c
    80003592:	11250513          	addi	a0,a0,274 # 8001f6a0 <itable>
    80003596:	ed0fd0ef          	jal	80000c66 <release>
}
    8000359a:	8526                	mv	a0,s1
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	64a2                	ld	s1,8(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret

00000000800035a6 <ilock>:
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	e426                	sd	s1,8(sp)
    800035ae:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035b0:	cd19                	beqz	a0,800035ce <ilock+0x28>
    800035b2:	84aa                	mv	s1,a0
    800035b4:	451c                	lw	a5,8(a0)
    800035b6:	00f05c63          	blez	a5,800035ce <ilock+0x28>
  acquiresleep(&ip->lock);
    800035ba:	0541                	addi	a0,a0,16
    800035bc:	451000ef          	jal	8000420c <acquiresleep>
  if(ip->valid == 0){
    800035c0:	40bc                	lw	a5,64(s1)
    800035c2:	cf89                	beqz	a5,800035dc <ilock+0x36>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6105                	addi	sp,sp,32
    800035cc:	8082                	ret
    800035ce:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800035d0:	00004517          	auipc	a0,0x4
    800035d4:	e7850513          	addi	a0,a0,-392 # 80007448 <etext+0x448>
    800035d8:	a08fd0ef          	jal	800007e0 <panic>
    800035dc:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035de:	40dc                	lw	a5,4(s1)
    800035e0:	0047d79b          	srliw	a5,a5,0x4
    800035e4:	0001c597          	auipc	a1,0x1c
    800035e8:	0b45a583          	lw	a1,180(a1) # 8001f698 <sb+0x18>
    800035ec:	9dbd                	addw	a1,a1,a5
    800035ee:	4088                	lw	a0,0(s1)
    800035f0:	8ebff0ef          	jal	80002eda <bread>
    800035f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035f6:	05850593          	addi	a1,a0,88
    800035fa:	40dc                	lw	a5,4(s1)
    800035fc:	8bbd                	andi	a5,a5,15
    800035fe:	079a                	slli	a5,a5,0x6
    80003600:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003602:	00059783          	lh	a5,0(a1)
    80003606:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000360a:	00259783          	lh	a5,2(a1)
    8000360e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003612:	00459783          	lh	a5,4(a1)
    80003616:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000361a:	00659783          	lh	a5,6(a1)
    8000361e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003622:	459c                	lw	a5,8(a1)
    80003624:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003626:	03400613          	li	a2,52
    8000362a:	05b1                	addi	a1,a1,12
    8000362c:	05048513          	addi	a0,s1,80
    80003630:	ecefd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    80003634:	854a                	mv	a0,s2
    80003636:	9adff0ef          	jal	80002fe2 <brelse>
    ip->valid = 1;
    8000363a:	4785                	li	a5,1
    8000363c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000363e:	04449783          	lh	a5,68(s1)
    80003642:	c399                	beqz	a5,80003648 <ilock+0xa2>
    80003644:	6902                	ld	s2,0(sp)
    80003646:	bfbd                	j	800035c4 <ilock+0x1e>
      panic("ilock: no type");
    80003648:	00004517          	auipc	a0,0x4
    8000364c:	e0850513          	addi	a0,a0,-504 # 80007450 <etext+0x450>
    80003650:	990fd0ef          	jal	800007e0 <panic>

0000000080003654 <iunlock>:
{
    80003654:	1101                	addi	sp,sp,-32
    80003656:	ec06                	sd	ra,24(sp)
    80003658:	e822                	sd	s0,16(sp)
    8000365a:	e426                	sd	s1,8(sp)
    8000365c:	e04a                	sd	s2,0(sp)
    8000365e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003660:	c505                	beqz	a0,80003688 <iunlock+0x34>
    80003662:	84aa                	mv	s1,a0
    80003664:	01050913          	addi	s2,a0,16
    80003668:	854a                	mv	a0,s2
    8000366a:	421000ef          	jal	8000428a <holdingsleep>
    8000366e:	cd09                	beqz	a0,80003688 <iunlock+0x34>
    80003670:	449c                	lw	a5,8(s1)
    80003672:	00f05b63          	blez	a5,80003688 <iunlock+0x34>
  releasesleep(&ip->lock);
    80003676:	854a                	mv	a0,s2
    80003678:	3db000ef          	jal	80004252 <releasesleep>
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6902                	ld	s2,0(sp)
    80003684:	6105                	addi	sp,sp,32
    80003686:	8082                	ret
    panic("iunlock");
    80003688:	00004517          	auipc	a0,0x4
    8000368c:	dd850513          	addi	a0,a0,-552 # 80007460 <etext+0x460>
    80003690:	950fd0ef          	jal	800007e0 <panic>

0000000080003694 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003694:	7179                	addi	sp,sp,-48
    80003696:	f406                	sd	ra,40(sp)
    80003698:	f022                	sd	s0,32(sp)
    8000369a:	ec26                	sd	s1,24(sp)
    8000369c:	e84a                	sd	s2,16(sp)
    8000369e:	e44e                	sd	s3,8(sp)
    800036a0:	1800                	addi	s0,sp,48
    800036a2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036a4:	05050493          	addi	s1,a0,80
    800036a8:	08050913          	addi	s2,a0,128
    800036ac:	a021                	j	800036b4 <itrunc+0x20>
    800036ae:	0491                	addi	s1,s1,4
    800036b0:	01248b63          	beq	s1,s2,800036c6 <itrunc+0x32>
    if(ip->addrs[i]){
    800036b4:	408c                	lw	a1,0(s1)
    800036b6:	dde5                	beqz	a1,800036ae <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800036b8:	0009a503          	lw	a0,0(s3)
    800036bc:	a17ff0ef          	jal	800030d2 <bfree>
      ip->addrs[i] = 0;
    800036c0:	0004a023          	sw	zero,0(s1)
    800036c4:	b7ed                	j	800036ae <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800036c6:	0809a583          	lw	a1,128(s3)
    800036ca:	ed89                	bnez	a1,800036e4 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800036cc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800036d0:	854e                	mv	a0,s3
    800036d2:	e21ff0ef          	jal	800034f2 <iupdate>
}
    800036d6:	70a2                	ld	ra,40(sp)
    800036d8:	7402                	ld	s0,32(sp)
    800036da:	64e2                	ld	s1,24(sp)
    800036dc:	6942                	ld	s2,16(sp)
    800036de:	69a2                	ld	s3,8(sp)
    800036e0:	6145                	addi	sp,sp,48
    800036e2:	8082                	ret
    800036e4:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800036e6:	0009a503          	lw	a0,0(s3)
    800036ea:	ff0ff0ef          	jal	80002eda <bread>
    800036ee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800036f0:	05850493          	addi	s1,a0,88
    800036f4:	45850913          	addi	s2,a0,1112
    800036f8:	a021                	j	80003700 <itrunc+0x6c>
    800036fa:	0491                	addi	s1,s1,4
    800036fc:	01248963          	beq	s1,s2,8000370e <itrunc+0x7a>
      if(a[j])
    80003700:	408c                	lw	a1,0(s1)
    80003702:	dde5                	beqz	a1,800036fa <itrunc+0x66>
        bfree(ip->dev, a[j]);
    80003704:	0009a503          	lw	a0,0(s3)
    80003708:	9cbff0ef          	jal	800030d2 <bfree>
    8000370c:	b7fd                	j	800036fa <itrunc+0x66>
    brelse(bp);
    8000370e:	8552                	mv	a0,s4
    80003710:	8d3ff0ef          	jal	80002fe2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003714:	0809a583          	lw	a1,128(s3)
    80003718:	0009a503          	lw	a0,0(s3)
    8000371c:	9b7ff0ef          	jal	800030d2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003720:	0809a023          	sw	zero,128(s3)
    80003724:	6a02                	ld	s4,0(sp)
    80003726:	b75d                	j	800036cc <itrunc+0x38>

0000000080003728 <iput>:
{
    80003728:	1101                	addi	sp,sp,-32
    8000372a:	ec06                	sd	ra,24(sp)
    8000372c:	e822                	sd	s0,16(sp)
    8000372e:	e426                	sd	s1,8(sp)
    80003730:	1000                	addi	s0,sp,32
    80003732:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003734:	0001c517          	auipc	a0,0x1c
    80003738:	f6c50513          	addi	a0,a0,-148 # 8001f6a0 <itable>
    8000373c:	c92fd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003740:	4498                	lw	a4,8(s1)
    80003742:	4785                	li	a5,1
    80003744:	02f70063          	beq	a4,a5,80003764 <iput+0x3c>
  ip->ref--;
    80003748:	449c                	lw	a5,8(s1)
    8000374a:	37fd                	addiw	a5,a5,-1
    8000374c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000374e:	0001c517          	auipc	a0,0x1c
    80003752:	f5250513          	addi	a0,a0,-174 # 8001f6a0 <itable>
    80003756:	d10fd0ef          	jal	80000c66 <release>
}
    8000375a:	60e2                	ld	ra,24(sp)
    8000375c:	6442                	ld	s0,16(sp)
    8000375e:	64a2                	ld	s1,8(sp)
    80003760:	6105                	addi	sp,sp,32
    80003762:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003764:	40bc                	lw	a5,64(s1)
    80003766:	d3ed                	beqz	a5,80003748 <iput+0x20>
    80003768:	04a49783          	lh	a5,74(s1)
    8000376c:	fff1                	bnez	a5,80003748 <iput+0x20>
    8000376e:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003770:	01048913          	addi	s2,s1,16
    80003774:	854a                	mv	a0,s2
    80003776:	297000ef          	jal	8000420c <acquiresleep>
    release(&itable.lock);
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	f2650513          	addi	a0,a0,-218 # 8001f6a0 <itable>
    80003782:	ce4fd0ef          	jal	80000c66 <release>
    itrunc(ip);
    80003786:	8526                	mv	a0,s1
    80003788:	f0dff0ef          	jal	80003694 <itrunc>
    ip->type = 0;
    8000378c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003790:	8526                	mv	a0,s1
    80003792:	d61ff0ef          	jal	800034f2 <iupdate>
    ip->valid = 0;
    80003796:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000379a:	854a                	mv	a0,s2
    8000379c:	2b7000ef          	jal	80004252 <releasesleep>
    acquire(&itable.lock);
    800037a0:	0001c517          	auipc	a0,0x1c
    800037a4:	f0050513          	addi	a0,a0,-256 # 8001f6a0 <itable>
    800037a8:	c26fd0ef          	jal	80000bce <acquire>
    800037ac:	6902                	ld	s2,0(sp)
    800037ae:	bf69                	j	80003748 <iput+0x20>

00000000800037b0 <iunlockput>:
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  iunlock(ip);
    800037bc:	e99ff0ef          	jal	80003654 <iunlock>
  iput(ip);
    800037c0:	8526                	mv	a0,s1
    800037c2:	f67ff0ef          	jal	80003728 <iput>
}
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6105                	addi	sp,sp,32
    800037ce:	8082                	ret

00000000800037d0 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037d0:	0001c717          	auipc	a4,0x1c
    800037d4:	ebc72703          	lw	a4,-324(a4) # 8001f68c <sb+0xc>
    800037d8:	4785                	li	a5,1
    800037da:	0ae7ff63          	bgeu	a5,a4,80003898 <ireclaim+0xc8>
{
    800037de:	7139                	addi	sp,sp,-64
    800037e0:	fc06                	sd	ra,56(sp)
    800037e2:	f822                	sd	s0,48(sp)
    800037e4:	f426                	sd	s1,40(sp)
    800037e6:	f04a                	sd	s2,32(sp)
    800037e8:	ec4e                	sd	s3,24(sp)
    800037ea:	e852                	sd	s4,16(sp)
    800037ec:	e456                	sd	s5,8(sp)
    800037ee:	e05a                	sd	s6,0(sp)
    800037f0:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037f2:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800037f4:	00050a1b          	sext.w	s4,a0
    800037f8:	0001ca97          	auipc	s5,0x1c
    800037fc:	e88a8a93          	addi	s5,s5,-376 # 8001f680 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003800:	00004b17          	auipc	s6,0x4
    80003804:	c68b0b13          	addi	s6,s6,-920 # 80007468 <etext+0x468>
    80003808:	a099                	j	8000384e <ireclaim+0x7e>
    8000380a:	85ce                	mv	a1,s3
    8000380c:	855a                	mv	a0,s6
    8000380e:	cedfc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    80003812:	85ce                	mv	a1,s3
    80003814:	8552                	mv	a0,s4
    80003816:	b1dff0ef          	jal	80003332 <iget>
    8000381a:	89aa                	mv	s3,a0
    brelse(bp);
    8000381c:	854a                	mv	a0,s2
    8000381e:	fc4ff0ef          	jal	80002fe2 <brelse>
    if (ip) {
    80003822:	00098f63          	beqz	s3,80003840 <ireclaim+0x70>
      begin_op();
    80003826:	76a000ef          	jal	80003f90 <begin_op>
      ilock(ip);
    8000382a:	854e                	mv	a0,s3
    8000382c:	d7bff0ef          	jal	800035a6 <ilock>
      iunlock(ip);
    80003830:	854e                	mv	a0,s3
    80003832:	e23ff0ef          	jal	80003654 <iunlock>
      iput(ip);
    80003836:	854e                	mv	a0,s3
    80003838:	ef1ff0ef          	jal	80003728 <iput>
      end_op();
    8000383c:	7be000ef          	jal	80003ffa <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003840:	0485                	addi	s1,s1,1
    80003842:	00caa703          	lw	a4,12(s5)
    80003846:	0004879b          	sext.w	a5,s1
    8000384a:	02e7fd63          	bgeu	a5,a4,80003884 <ireclaim+0xb4>
    8000384e:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003852:	0044d593          	srli	a1,s1,0x4
    80003856:	018aa783          	lw	a5,24(s5)
    8000385a:	9dbd                	addw	a1,a1,a5
    8000385c:	8552                	mv	a0,s4
    8000385e:	e7cff0ef          	jal	80002eda <bread>
    80003862:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003864:	05850793          	addi	a5,a0,88
    80003868:	00f9f713          	andi	a4,s3,15
    8000386c:	071a                	slli	a4,a4,0x6
    8000386e:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003870:	00079703          	lh	a4,0(a5)
    80003874:	c701                	beqz	a4,8000387c <ireclaim+0xac>
    80003876:	00679783          	lh	a5,6(a5)
    8000387a:	dbc1                	beqz	a5,8000380a <ireclaim+0x3a>
    brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	f64ff0ef          	jal	80002fe2 <brelse>
    if (ip) {
    80003882:	bf7d                	j	80003840 <ireclaim+0x70>
}
    80003884:	70e2                	ld	ra,56(sp)
    80003886:	7442                	ld	s0,48(sp)
    80003888:	74a2                	ld	s1,40(sp)
    8000388a:	7902                	ld	s2,32(sp)
    8000388c:	69e2                	ld	s3,24(sp)
    8000388e:	6a42                	ld	s4,16(sp)
    80003890:	6aa2                	ld	s5,8(sp)
    80003892:	6b02                	ld	s6,0(sp)
    80003894:	6121                	addi	sp,sp,64
    80003896:	8082                	ret
    80003898:	8082                	ret

000000008000389a <fsinit>:
fsinit(int dev) {
    8000389a:	7179                	addi	sp,sp,-48
    8000389c:	f406                	sd	ra,40(sp)
    8000389e:	f022                	sd	s0,32(sp)
    800038a0:	ec26                	sd	s1,24(sp)
    800038a2:	e84a                	sd	s2,16(sp)
    800038a4:	e44e                	sd	s3,8(sp)
    800038a6:	1800                	addi	s0,sp,48
    800038a8:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800038aa:	4585                	li	a1,1
    800038ac:	e2eff0ef          	jal	80002eda <bread>
    800038b0:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038b2:	0001c997          	auipc	s3,0x1c
    800038b6:	dce98993          	addi	s3,s3,-562 # 8001f680 <sb>
    800038ba:	02000613          	li	a2,32
    800038be:	05850593          	addi	a1,a0,88
    800038c2:	854e                	mv	a0,s3
    800038c4:	c3afd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	f18ff0ef          	jal	80002fe2 <brelse>
  if(sb.magic != FSMAGIC)
    800038ce:	0009a703          	lw	a4,0(s3)
    800038d2:	102037b7          	lui	a5,0x10203
    800038d6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038da:	02f71363          	bne	a4,a5,80003900 <fsinit+0x66>
  initlog(dev, &sb);
    800038de:	0001c597          	auipc	a1,0x1c
    800038e2:	da258593          	addi	a1,a1,-606 # 8001f680 <sb>
    800038e6:	8526                	mv	a0,s1
    800038e8:	62a000ef          	jal	80003f12 <initlog>
  ireclaim(dev);
    800038ec:	8526                	mv	a0,s1
    800038ee:	ee3ff0ef          	jal	800037d0 <ireclaim>
}
    800038f2:	70a2                	ld	ra,40(sp)
    800038f4:	7402                	ld	s0,32(sp)
    800038f6:	64e2                	ld	s1,24(sp)
    800038f8:	6942                	ld	s2,16(sp)
    800038fa:	69a2                	ld	s3,8(sp)
    800038fc:	6145                	addi	sp,sp,48
    800038fe:	8082                	ret
    panic("invalid file system");
    80003900:	00004517          	auipc	a0,0x4
    80003904:	b8850513          	addi	a0,a0,-1144 # 80007488 <etext+0x488>
    80003908:	ed9fc0ef          	jal	800007e0 <panic>

000000008000390c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000390c:	1141                	addi	sp,sp,-16
    8000390e:	e422                	sd	s0,8(sp)
    80003910:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003912:	411c                	lw	a5,0(a0)
    80003914:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003916:	415c                	lw	a5,4(a0)
    80003918:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000391a:	04451783          	lh	a5,68(a0)
    8000391e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003922:	04a51783          	lh	a5,74(a0)
    80003926:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000392a:	04c56783          	lwu	a5,76(a0)
    8000392e:	e99c                	sd	a5,16(a1)
}
    80003930:	6422                	ld	s0,8(sp)
    80003932:	0141                	addi	sp,sp,16
    80003934:	8082                	ret

0000000080003936 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003936:	457c                	lw	a5,76(a0)
    80003938:	0ed7eb63          	bltu	a5,a3,80003a2e <readi+0xf8>
{
    8000393c:	7159                	addi	sp,sp,-112
    8000393e:	f486                	sd	ra,104(sp)
    80003940:	f0a2                	sd	s0,96(sp)
    80003942:	eca6                	sd	s1,88(sp)
    80003944:	e0d2                	sd	s4,64(sp)
    80003946:	fc56                	sd	s5,56(sp)
    80003948:	f85a                	sd	s6,48(sp)
    8000394a:	f45e                	sd	s7,40(sp)
    8000394c:	1880                	addi	s0,sp,112
    8000394e:	8b2a                	mv	s6,a0
    80003950:	8bae                	mv	s7,a1
    80003952:	8a32                	mv	s4,a2
    80003954:	84b6                	mv	s1,a3
    80003956:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003958:	9f35                	addw	a4,a4,a3
    return 0;
    8000395a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000395c:	0cd76063          	bltu	a4,a3,80003a1c <readi+0xe6>
    80003960:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003962:	00e7f463          	bgeu	a5,a4,8000396a <readi+0x34>
    n = ip->size - off;
    80003966:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000396a:	080a8f63          	beqz	s5,80003a08 <readi+0xd2>
    8000396e:	e8ca                	sd	s2,80(sp)
    80003970:	f062                	sd	s8,32(sp)
    80003972:	ec66                	sd	s9,24(sp)
    80003974:	e86a                	sd	s10,16(sp)
    80003976:	e46e                	sd	s11,8(sp)
    80003978:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000397a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000397e:	5c7d                	li	s8,-1
    80003980:	a80d                	j	800039b2 <readi+0x7c>
    80003982:	020d1d93          	slli	s11,s10,0x20
    80003986:	020ddd93          	srli	s11,s11,0x20
    8000398a:	05890613          	addi	a2,s2,88
    8000398e:	86ee                	mv	a3,s11
    80003990:	963a                	add	a2,a2,a4
    80003992:	85d2                	mv	a1,s4
    80003994:	855e                	mv	a0,s7
    80003996:	981fe0ef          	jal	80002316 <either_copyout>
    8000399a:	05850763          	beq	a0,s8,800039e8 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000399e:	854a                	mv	a0,s2
    800039a0:	e42ff0ef          	jal	80002fe2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a4:	013d09bb          	addw	s3,s10,s3
    800039a8:	009d04bb          	addw	s1,s10,s1
    800039ac:	9a6e                	add	s4,s4,s11
    800039ae:	0559f763          	bgeu	s3,s5,800039fc <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    800039b2:	00a4d59b          	srliw	a1,s1,0xa
    800039b6:	855a                	mv	a0,s6
    800039b8:	8a7ff0ef          	jal	8000325e <bmap>
    800039bc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039c0:	c5b1                	beqz	a1,80003a0c <readi+0xd6>
    bp = bread(ip->dev, addr);
    800039c2:	000b2503          	lw	a0,0(s6)
    800039c6:	d14ff0ef          	jal	80002eda <bread>
    800039ca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039cc:	3ff4f713          	andi	a4,s1,1023
    800039d0:	40ec87bb          	subw	a5,s9,a4
    800039d4:	413a86bb          	subw	a3,s5,s3
    800039d8:	8d3e                	mv	s10,a5
    800039da:	2781                	sext.w	a5,a5
    800039dc:	0006861b          	sext.w	a2,a3
    800039e0:	faf671e3          	bgeu	a2,a5,80003982 <readi+0x4c>
    800039e4:	8d36                	mv	s10,a3
    800039e6:	bf71                	j	80003982 <readi+0x4c>
      brelse(bp);
    800039e8:	854a                	mv	a0,s2
    800039ea:	df8ff0ef          	jal	80002fe2 <brelse>
      tot = -1;
    800039ee:	59fd                	li	s3,-1
      break;
    800039f0:	6946                	ld	s2,80(sp)
    800039f2:	7c02                	ld	s8,32(sp)
    800039f4:	6ce2                	ld	s9,24(sp)
    800039f6:	6d42                	ld	s10,16(sp)
    800039f8:	6da2                	ld	s11,8(sp)
    800039fa:	a831                	j	80003a16 <readi+0xe0>
    800039fc:	6946                	ld	s2,80(sp)
    800039fe:	7c02                	ld	s8,32(sp)
    80003a00:	6ce2                	ld	s9,24(sp)
    80003a02:	6d42                	ld	s10,16(sp)
    80003a04:	6da2                	ld	s11,8(sp)
    80003a06:	a801                	j	80003a16 <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a08:	89d6                	mv	s3,s5
    80003a0a:	a031                	j	80003a16 <readi+0xe0>
    80003a0c:	6946                	ld	s2,80(sp)
    80003a0e:	7c02                	ld	s8,32(sp)
    80003a10:	6ce2                	ld	s9,24(sp)
    80003a12:	6d42                	ld	s10,16(sp)
    80003a14:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003a16:	0009851b          	sext.w	a0,s3
    80003a1a:	69a6                	ld	s3,72(sp)
}
    80003a1c:	70a6                	ld	ra,104(sp)
    80003a1e:	7406                	ld	s0,96(sp)
    80003a20:	64e6                	ld	s1,88(sp)
    80003a22:	6a06                	ld	s4,64(sp)
    80003a24:	7ae2                	ld	s5,56(sp)
    80003a26:	7b42                	ld	s6,48(sp)
    80003a28:	7ba2                	ld	s7,40(sp)
    80003a2a:	6165                	addi	sp,sp,112
    80003a2c:	8082                	ret
    return 0;
    80003a2e:	4501                	li	a0,0
}
    80003a30:	8082                	ret

0000000080003a32 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a32:	457c                	lw	a5,76(a0)
    80003a34:	10d7e063          	bltu	a5,a3,80003b34 <writei+0x102>
{
    80003a38:	7159                	addi	sp,sp,-112
    80003a3a:	f486                	sd	ra,104(sp)
    80003a3c:	f0a2                	sd	s0,96(sp)
    80003a3e:	e8ca                	sd	s2,80(sp)
    80003a40:	e0d2                	sd	s4,64(sp)
    80003a42:	fc56                	sd	s5,56(sp)
    80003a44:	f85a                	sd	s6,48(sp)
    80003a46:	f45e                	sd	s7,40(sp)
    80003a48:	1880                	addi	s0,sp,112
    80003a4a:	8aaa                	mv	s5,a0
    80003a4c:	8bae                	mv	s7,a1
    80003a4e:	8a32                	mv	s4,a2
    80003a50:	8936                	mv	s2,a3
    80003a52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a54:	00e687bb          	addw	a5,a3,a4
    80003a58:	0ed7e063          	bltu	a5,a3,80003b38 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a5c:	00043737          	lui	a4,0x43
    80003a60:	0cf76e63          	bltu	a4,a5,80003b3c <writei+0x10a>
    80003a64:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a66:	0a0b0f63          	beqz	s6,80003b24 <writei+0xf2>
    80003a6a:	eca6                	sd	s1,88(sp)
    80003a6c:	f062                	sd	s8,32(sp)
    80003a6e:	ec66                	sd	s9,24(sp)
    80003a70:	e86a                	sd	s10,16(sp)
    80003a72:	e46e                	sd	s11,8(sp)
    80003a74:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a76:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a7a:	5c7d                	li	s8,-1
    80003a7c:	a825                	j	80003ab4 <writei+0x82>
    80003a7e:	020d1d93          	slli	s11,s10,0x20
    80003a82:	020ddd93          	srli	s11,s11,0x20
    80003a86:	05848513          	addi	a0,s1,88
    80003a8a:	86ee                	mv	a3,s11
    80003a8c:	8652                	mv	a2,s4
    80003a8e:	85de                	mv	a1,s7
    80003a90:	953a                	add	a0,a0,a4
    80003a92:	8cffe0ef          	jal	80002360 <either_copyin>
    80003a96:	05850a63          	beq	a0,s8,80003aea <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a9a:	8526                	mv	a0,s1
    80003a9c:	678000ef          	jal	80004114 <log_write>
    brelse(bp);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	d40ff0ef          	jal	80002fe2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa6:	013d09bb          	addw	s3,s10,s3
    80003aaa:	012d093b          	addw	s2,s10,s2
    80003aae:	9a6e                	add	s4,s4,s11
    80003ab0:	0569f063          	bgeu	s3,s6,80003af0 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003ab4:	00a9559b          	srliw	a1,s2,0xa
    80003ab8:	8556                	mv	a0,s5
    80003aba:	fa4ff0ef          	jal	8000325e <bmap>
    80003abe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ac2:	c59d                	beqz	a1,80003af0 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003ac4:	000aa503          	lw	a0,0(s5)
    80003ac8:	c12ff0ef          	jal	80002eda <bread>
    80003acc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ace:	3ff97713          	andi	a4,s2,1023
    80003ad2:	40ec87bb          	subw	a5,s9,a4
    80003ad6:	413b06bb          	subw	a3,s6,s3
    80003ada:	8d3e                	mv	s10,a5
    80003adc:	2781                	sext.w	a5,a5
    80003ade:	0006861b          	sext.w	a2,a3
    80003ae2:	f8f67ee3          	bgeu	a2,a5,80003a7e <writei+0x4c>
    80003ae6:	8d36                	mv	s10,a3
    80003ae8:	bf59                	j	80003a7e <writei+0x4c>
      brelse(bp);
    80003aea:	8526                	mv	a0,s1
    80003aec:	cf6ff0ef          	jal	80002fe2 <brelse>
  }

  if(off > ip->size)
    80003af0:	04caa783          	lw	a5,76(s5)
    80003af4:	0327fa63          	bgeu	a5,s2,80003b28 <writei+0xf6>
    ip->size = off;
    80003af8:	052aa623          	sw	s2,76(s5)
    80003afc:	64e6                	ld	s1,88(sp)
    80003afe:	7c02                	ld	s8,32(sp)
    80003b00:	6ce2                	ld	s9,24(sp)
    80003b02:	6d42                	ld	s10,16(sp)
    80003b04:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b06:	8556                	mv	a0,s5
    80003b08:	9ebff0ef          	jal	800034f2 <iupdate>

  return tot;
    80003b0c:	0009851b          	sext.w	a0,s3
    80003b10:	69a6                	ld	s3,72(sp)
}
    80003b12:	70a6                	ld	ra,104(sp)
    80003b14:	7406                	ld	s0,96(sp)
    80003b16:	6946                	ld	s2,80(sp)
    80003b18:	6a06                	ld	s4,64(sp)
    80003b1a:	7ae2                	ld	s5,56(sp)
    80003b1c:	7b42                	ld	s6,48(sp)
    80003b1e:	7ba2                	ld	s7,40(sp)
    80003b20:	6165                	addi	sp,sp,112
    80003b22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b24:	89da                	mv	s3,s6
    80003b26:	b7c5                	j	80003b06 <writei+0xd4>
    80003b28:	64e6                	ld	s1,88(sp)
    80003b2a:	7c02                	ld	s8,32(sp)
    80003b2c:	6ce2                	ld	s9,24(sp)
    80003b2e:	6d42                	ld	s10,16(sp)
    80003b30:	6da2                	ld	s11,8(sp)
    80003b32:	bfd1                	j	80003b06 <writei+0xd4>
    return -1;
    80003b34:	557d                	li	a0,-1
}
    80003b36:	8082                	ret
    return -1;
    80003b38:	557d                	li	a0,-1
    80003b3a:	bfe1                	j	80003b12 <writei+0xe0>
    return -1;
    80003b3c:	557d                	li	a0,-1
    80003b3e:	bfd1                	j	80003b12 <writei+0xe0>

0000000080003b40 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b40:	1141                	addi	sp,sp,-16
    80003b42:	e406                	sd	ra,8(sp)
    80003b44:	e022                	sd	s0,0(sp)
    80003b46:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b48:	4639                	li	a2,14
    80003b4a:	a24fd0ef          	jal	80000d6e <strncmp>
}
    80003b4e:	60a2                	ld	ra,8(sp)
    80003b50:	6402                	ld	s0,0(sp)
    80003b52:	0141                	addi	sp,sp,16
    80003b54:	8082                	ret

0000000080003b56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b56:	7139                	addi	sp,sp,-64
    80003b58:	fc06                	sd	ra,56(sp)
    80003b5a:	f822                	sd	s0,48(sp)
    80003b5c:	f426                	sd	s1,40(sp)
    80003b5e:	f04a                	sd	s2,32(sp)
    80003b60:	ec4e                	sd	s3,24(sp)
    80003b62:	e852                	sd	s4,16(sp)
    80003b64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b66:	04451703          	lh	a4,68(a0)
    80003b6a:	4785                	li	a5,1
    80003b6c:	00f71a63          	bne	a4,a5,80003b80 <dirlookup+0x2a>
    80003b70:	892a                	mv	s2,a0
    80003b72:	89ae                	mv	s3,a1
    80003b74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b76:	457c                	lw	a5,76(a0)
    80003b78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7c:	e39d                	bnez	a5,80003ba2 <dirlookup+0x4c>
    80003b7e:	a095                	j	80003be2 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003b80:	00004517          	auipc	a0,0x4
    80003b84:	92050513          	addi	a0,a0,-1760 # 800074a0 <etext+0x4a0>
    80003b88:	c59fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003b8c:	00004517          	auipc	a0,0x4
    80003b90:	92c50513          	addi	a0,a0,-1748 # 800074b8 <etext+0x4b8>
    80003b94:	c4dfc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b98:	24c1                	addiw	s1,s1,16
    80003b9a:	04c92783          	lw	a5,76(s2)
    80003b9e:	04f4f163          	bgeu	s1,a5,80003be0 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ba2:	4741                	li	a4,16
    80003ba4:	86a6                	mv	a3,s1
    80003ba6:	fc040613          	addi	a2,s0,-64
    80003baa:	4581                	li	a1,0
    80003bac:	854a                	mv	a0,s2
    80003bae:	d89ff0ef          	jal	80003936 <readi>
    80003bb2:	47c1                	li	a5,16
    80003bb4:	fcf51ce3          	bne	a0,a5,80003b8c <dirlookup+0x36>
    if(de.inum == 0)
    80003bb8:	fc045783          	lhu	a5,-64(s0)
    80003bbc:	dff1                	beqz	a5,80003b98 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003bbe:	fc240593          	addi	a1,s0,-62
    80003bc2:	854e                	mv	a0,s3
    80003bc4:	f7dff0ef          	jal	80003b40 <namecmp>
    80003bc8:	f961                	bnez	a0,80003b98 <dirlookup+0x42>
      if(poff)
    80003bca:	000a0463          	beqz	s4,80003bd2 <dirlookup+0x7c>
        *poff = off;
    80003bce:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bd2:	fc045583          	lhu	a1,-64(s0)
    80003bd6:	00092503          	lw	a0,0(s2)
    80003bda:	f58ff0ef          	jal	80003332 <iget>
    80003bde:	a011                	j	80003be2 <dirlookup+0x8c>
  return 0;
    80003be0:	4501                	li	a0,0
}
    80003be2:	70e2                	ld	ra,56(sp)
    80003be4:	7442                	ld	s0,48(sp)
    80003be6:	74a2                	ld	s1,40(sp)
    80003be8:	7902                	ld	s2,32(sp)
    80003bea:	69e2                	ld	s3,24(sp)
    80003bec:	6a42                	ld	s4,16(sp)
    80003bee:	6121                	addi	sp,sp,64
    80003bf0:	8082                	ret

0000000080003bf2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bf2:	711d                	addi	sp,sp,-96
    80003bf4:	ec86                	sd	ra,88(sp)
    80003bf6:	e8a2                	sd	s0,80(sp)
    80003bf8:	e4a6                	sd	s1,72(sp)
    80003bfa:	e0ca                	sd	s2,64(sp)
    80003bfc:	fc4e                	sd	s3,56(sp)
    80003bfe:	f852                	sd	s4,48(sp)
    80003c00:	f456                	sd	s5,40(sp)
    80003c02:	f05a                	sd	s6,32(sp)
    80003c04:	ec5e                	sd	s7,24(sp)
    80003c06:	e862                	sd	s8,16(sp)
    80003c08:	e466                	sd	s9,8(sp)
    80003c0a:	1080                	addi	s0,sp,96
    80003c0c:	84aa                	mv	s1,a0
    80003c0e:	8b2e                	mv	s6,a1
    80003c10:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c12:	00054703          	lbu	a4,0(a0)
    80003c16:	02f00793          	li	a5,47
    80003c1a:	00f70e63          	beq	a4,a5,80003c36 <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c1e:	cb1fd0ef          	jal	800018ce <myproc>
    80003c22:	15053503          	ld	a0,336(a0)
    80003c26:	94bff0ef          	jal	80003570 <idup>
    80003c2a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c2c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c30:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c32:	4b85                	li	s7,1
    80003c34:	a871                	j	80003cd0 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003c36:	4585                	li	a1,1
    80003c38:	4505                	li	a0,1
    80003c3a:	ef8ff0ef          	jal	80003332 <iget>
    80003c3e:	8a2a                	mv	s4,a0
    80003c40:	b7f5                	j	80003c2c <namex+0x3a>
      iunlockput(ip);
    80003c42:	8552                	mv	a0,s4
    80003c44:	b6dff0ef          	jal	800037b0 <iunlockput>
      return 0;
    80003c48:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4a:	8552                	mv	a0,s4
    80003c4c:	60e6                	ld	ra,88(sp)
    80003c4e:	6446                	ld	s0,80(sp)
    80003c50:	64a6                	ld	s1,72(sp)
    80003c52:	6906                	ld	s2,64(sp)
    80003c54:	79e2                	ld	s3,56(sp)
    80003c56:	7a42                	ld	s4,48(sp)
    80003c58:	7aa2                	ld	s5,40(sp)
    80003c5a:	7b02                	ld	s6,32(sp)
    80003c5c:	6be2                	ld	s7,24(sp)
    80003c5e:	6c42                	ld	s8,16(sp)
    80003c60:	6ca2                	ld	s9,8(sp)
    80003c62:	6125                	addi	sp,sp,96
    80003c64:	8082                	ret
      iunlock(ip);
    80003c66:	8552                	mv	a0,s4
    80003c68:	9edff0ef          	jal	80003654 <iunlock>
      return ip;
    80003c6c:	bff9                	j	80003c4a <namex+0x58>
      iunlockput(ip);
    80003c6e:	8552                	mv	a0,s4
    80003c70:	b41ff0ef          	jal	800037b0 <iunlockput>
      return 0;
    80003c74:	8a4e                	mv	s4,s3
    80003c76:	bfd1                	j	80003c4a <namex+0x58>
  len = path - s;
    80003c78:	40998633          	sub	a2,s3,s1
    80003c7c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c80:	099c5063          	bge	s8,s9,80003d00 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003c84:	4639                	li	a2,14
    80003c86:	85a6                	mv	a1,s1
    80003c88:	8556                	mv	a0,s5
    80003c8a:	874fd0ef          	jal	80000cfe <memmove>
    80003c8e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c90:	0004c783          	lbu	a5,0(s1)
    80003c94:	01279763          	bne	a5,s2,80003ca2 <namex+0xb0>
    path++;
    80003c98:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c9a:	0004c783          	lbu	a5,0(s1)
    80003c9e:	ff278de3          	beq	a5,s2,80003c98 <namex+0xa6>
    ilock(ip);
    80003ca2:	8552                	mv	a0,s4
    80003ca4:	903ff0ef          	jal	800035a6 <ilock>
    if(ip->type != T_DIR){
    80003ca8:	044a1783          	lh	a5,68(s4)
    80003cac:	f9779be3          	bne	a5,s7,80003c42 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003cb0:	000b0563          	beqz	s6,80003cba <namex+0xc8>
    80003cb4:	0004c783          	lbu	a5,0(s1)
    80003cb8:	d7dd                	beqz	a5,80003c66 <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cba:	4601                	li	a2,0
    80003cbc:	85d6                	mv	a1,s5
    80003cbe:	8552                	mv	a0,s4
    80003cc0:	e97ff0ef          	jal	80003b56 <dirlookup>
    80003cc4:	89aa                	mv	s3,a0
    80003cc6:	d545                	beqz	a0,80003c6e <namex+0x7c>
    iunlockput(ip);
    80003cc8:	8552                	mv	a0,s4
    80003cca:	ae7ff0ef          	jal	800037b0 <iunlockput>
    ip = next;
    80003cce:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cd0:	0004c783          	lbu	a5,0(s1)
    80003cd4:	01279763          	bne	a5,s2,80003ce2 <namex+0xf0>
    path++;
    80003cd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cda:	0004c783          	lbu	a5,0(s1)
    80003cde:	ff278de3          	beq	a5,s2,80003cd8 <namex+0xe6>
  if(*path == 0)
    80003ce2:	cb8d                	beqz	a5,80003d14 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	89a6                	mv	s3,s1
  len = path - s;
    80003cea:	4c81                	li	s9,0
    80003cec:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003cee:	01278963          	beq	a5,s2,80003d00 <namex+0x10e>
    80003cf2:	d3d9                	beqz	a5,80003c78 <namex+0x86>
    path++;
    80003cf4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003cf6:	0009c783          	lbu	a5,0(s3)
    80003cfa:	ff279ce3          	bne	a5,s2,80003cf2 <namex+0x100>
    80003cfe:	bfad                	j	80003c78 <namex+0x86>
    memmove(name, s, len);
    80003d00:	2601                	sext.w	a2,a2
    80003d02:	85a6                	mv	a1,s1
    80003d04:	8556                	mv	a0,s5
    80003d06:	ff9fc0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003d0a:	9cd6                	add	s9,s9,s5
    80003d0c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d10:	84ce                	mv	s1,s3
    80003d12:	bfbd                	j	80003c90 <namex+0x9e>
  if(nameiparent){
    80003d14:	f20b0be3          	beqz	s6,80003c4a <namex+0x58>
    iput(ip);
    80003d18:	8552                	mv	a0,s4
    80003d1a:	a0fff0ef          	jal	80003728 <iput>
    return 0;
    80003d1e:	4a01                	li	s4,0
    80003d20:	b72d                	j	80003c4a <namex+0x58>

0000000080003d22 <dirlink>:
{
    80003d22:	7139                	addi	sp,sp,-64
    80003d24:	fc06                	sd	ra,56(sp)
    80003d26:	f822                	sd	s0,48(sp)
    80003d28:	f04a                	sd	s2,32(sp)
    80003d2a:	ec4e                	sd	s3,24(sp)
    80003d2c:	e852                	sd	s4,16(sp)
    80003d2e:	0080                	addi	s0,sp,64
    80003d30:	892a                	mv	s2,a0
    80003d32:	8a2e                	mv	s4,a1
    80003d34:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d36:	4601                	li	a2,0
    80003d38:	e1fff0ef          	jal	80003b56 <dirlookup>
    80003d3c:	e535                	bnez	a0,80003da8 <dirlink+0x86>
    80003d3e:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d40:	04c92483          	lw	s1,76(s2)
    80003d44:	c48d                	beqz	s1,80003d6e <dirlink+0x4c>
    80003d46:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d48:	4741                	li	a4,16
    80003d4a:	86a6                	mv	a3,s1
    80003d4c:	fc040613          	addi	a2,s0,-64
    80003d50:	4581                	li	a1,0
    80003d52:	854a                	mv	a0,s2
    80003d54:	be3ff0ef          	jal	80003936 <readi>
    80003d58:	47c1                	li	a5,16
    80003d5a:	04f51b63          	bne	a0,a5,80003db0 <dirlink+0x8e>
    if(de.inum == 0)
    80003d5e:	fc045783          	lhu	a5,-64(s0)
    80003d62:	c791                	beqz	a5,80003d6e <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d64:	24c1                	addiw	s1,s1,16
    80003d66:	04c92783          	lw	a5,76(s2)
    80003d6a:	fcf4efe3          	bltu	s1,a5,80003d48 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003d6e:	4639                	li	a2,14
    80003d70:	85d2                	mv	a1,s4
    80003d72:	fc240513          	addi	a0,s0,-62
    80003d76:	82efd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003d7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7e:	4741                	li	a4,16
    80003d80:	86a6                	mv	a3,s1
    80003d82:	fc040613          	addi	a2,s0,-64
    80003d86:	4581                	li	a1,0
    80003d88:	854a                	mv	a0,s2
    80003d8a:	ca9ff0ef          	jal	80003a32 <writei>
    80003d8e:	1541                	addi	a0,a0,-16
    80003d90:	00a03533          	snez	a0,a0
    80003d94:	40a00533          	neg	a0,a0
    80003d98:	74a2                	ld	s1,40(sp)
}
    80003d9a:	70e2                	ld	ra,56(sp)
    80003d9c:	7442                	ld	s0,48(sp)
    80003d9e:	7902                	ld	s2,32(sp)
    80003da0:	69e2                	ld	s3,24(sp)
    80003da2:	6a42                	ld	s4,16(sp)
    80003da4:	6121                	addi	sp,sp,64
    80003da6:	8082                	ret
    iput(ip);
    80003da8:	981ff0ef          	jal	80003728 <iput>
    return -1;
    80003dac:	557d                	li	a0,-1
    80003dae:	b7f5                	j	80003d9a <dirlink+0x78>
      panic("dirlink read");
    80003db0:	00003517          	auipc	a0,0x3
    80003db4:	71850513          	addi	a0,a0,1816 # 800074c8 <etext+0x4c8>
    80003db8:	a29fc0ef          	jal	800007e0 <panic>

0000000080003dbc <namei>:

struct inode*
namei(char *path)
{
    80003dbc:	1101                	addi	sp,sp,-32
    80003dbe:	ec06                	sd	ra,24(sp)
    80003dc0:	e822                	sd	s0,16(sp)
    80003dc2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dc4:	fe040613          	addi	a2,s0,-32
    80003dc8:	4581                	li	a1,0
    80003dca:	e29ff0ef          	jal	80003bf2 <namex>
}
    80003dce:	60e2                	ld	ra,24(sp)
    80003dd0:	6442                	ld	s0,16(sp)
    80003dd2:	6105                	addi	sp,sp,32
    80003dd4:	8082                	ret

0000000080003dd6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dd6:	1141                	addi	sp,sp,-16
    80003dd8:	e406                	sd	ra,8(sp)
    80003dda:	e022                	sd	s0,0(sp)
    80003ddc:	0800                	addi	s0,sp,16
    80003dde:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003de0:	4585                	li	a1,1
    80003de2:	e11ff0ef          	jal	80003bf2 <namex>
}
    80003de6:	60a2                	ld	ra,8(sp)
    80003de8:	6402                	ld	s0,0(sp)
    80003dea:	0141                	addi	sp,sp,16
    80003dec:	8082                	ret

0000000080003dee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	e04a                	sd	s2,0(sp)
    80003df8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dfa:	0001d917          	auipc	s2,0x1d
    80003dfe:	34e90913          	addi	s2,s2,846 # 80021148 <log>
    80003e02:	01892583          	lw	a1,24(s2)
    80003e06:	02492503          	lw	a0,36(s2)
    80003e0a:	8d0ff0ef          	jal	80002eda <bread>
    80003e0e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e10:	02892603          	lw	a2,40(s2)
    80003e14:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e16:	00c05f63          	blez	a2,80003e34 <write_head+0x46>
    80003e1a:	0001d717          	auipc	a4,0x1d
    80003e1e:	35a70713          	addi	a4,a4,858 # 80021174 <log+0x2c>
    80003e22:	87aa                	mv	a5,a0
    80003e24:	060a                	slli	a2,a2,0x2
    80003e26:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003e28:	4314                	lw	a3,0(a4)
    80003e2a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003e2c:	0711                	addi	a4,a4,4
    80003e2e:	0791                	addi	a5,a5,4
    80003e30:	fec79ce3          	bne	a5,a2,80003e28 <write_head+0x3a>
  }
  bwrite(buf);
    80003e34:	8526                	mv	a0,s1
    80003e36:	97aff0ef          	jal	80002fb0 <bwrite>
  brelse(buf);
    80003e3a:	8526                	mv	a0,s1
    80003e3c:	9a6ff0ef          	jal	80002fe2 <brelse>
}
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6902                	ld	s2,0(sp)
    80003e48:	6105                	addi	sp,sp,32
    80003e4a:	8082                	ret

0000000080003e4c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e4c:	0001d797          	auipc	a5,0x1d
    80003e50:	3247a783          	lw	a5,804(a5) # 80021170 <log+0x28>
    80003e54:	0af05e63          	blez	a5,80003f10 <install_trans+0xc4>
{
    80003e58:	715d                	addi	sp,sp,-80
    80003e5a:	e486                	sd	ra,72(sp)
    80003e5c:	e0a2                	sd	s0,64(sp)
    80003e5e:	fc26                	sd	s1,56(sp)
    80003e60:	f84a                	sd	s2,48(sp)
    80003e62:	f44e                	sd	s3,40(sp)
    80003e64:	f052                	sd	s4,32(sp)
    80003e66:	ec56                	sd	s5,24(sp)
    80003e68:	e85a                	sd	s6,16(sp)
    80003e6a:	e45e                	sd	s7,8(sp)
    80003e6c:	0880                	addi	s0,sp,80
    80003e6e:	8b2a                	mv	s6,a0
    80003e70:	0001da97          	auipc	s5,0x1d
    80003e74:	304a8a93          	addi	s5,s5,772 # 80021174 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e78:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e7a:	00003b97          	auipc	s7,0x3
    80003e7e:	65eb8b93          	addi	s7,s7,1630 # 800074d8 <etext+0x4d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e82:	0001da17          	auipc	s4,0x1d
    80003e86:	2c6a0a13          	addi	s4,s4,710 # 80021148 <log>
    80003e8a:	a025                	j	80003eb2 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e8c:	000aa603          	lw	a2,0(s5)
    80003e90:	85ce                	mv	a1,s3
    80003e92:	855e                	mv	a0,s7
    80003e94:	e66fc0ef          	jal	800004fa <printf>
    80003e98:	a839                	j	80003eb6 <install_trans+0x6a>
    brelse(lbuf);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	946ff0ef          	jal	80002fe2 <brelse>
    brelse(dbuf);
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	940ff0ef          	jal	80002fe2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea6:	2985                	addiw	s3,s3,1
    80003ea8:	0a91                	addi	s5,s5,4
    80003eaa:	028a2783          	lw	a5,40(s4)
    80003eae:	04f9d663          	bge	s3,a5,80003efa <install_trans+0xae>
    if(recovering) {
    80003eb2:	fc0b1de3          	bnez	s6,80003e8c <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eb6:	018a2583          	lw	a1,24(s4)
    80003eba:	013585bb          	addw	a1,a1,s3
    80003ebe:	2585                	addiw	a1,a1,1
    80003ec0:	024a2503          	lw	a0,36(s4)
    80003ec4:	816ff0ef          	jal	80002eda <bread>
    80003ec8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003eca:	000aa583          	lw	a1,0(s5)
    80003ece:	024a2503          	lw	a0,36(s4)
    80003ed2:	808ff0ef          	jal	80002eda <bread>
    80003ed6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ed8:	40000613          	li	a2,1024
    80003edc:	05890593          	addi	a1,s2,88
    80003ee0:	05850513          	addi	a0,a0,88
    80003ee4:	e1bfc0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ee8:	8526                	mv	a0,s1
    80003eea:	8c6ff0ef          	jal	80002fb0 <bwrite>
    if(recovering == 0)
    80003eee:	fa0b16e3          	bnez	s6,80003e9a <install_trans+0x4e>
      bunpin(dbuf);
    80003ef2:	8526                	mv	a0,s1
    80003ef4:	9aaff0ef          	jal	8000309e <bunpin>
    80003ef8:	b74d                	j	80003e9a <install_trans+0x4e>
}
    80003efa:	60a6                	ld	ra,72(sp)
    80003efc:	6406                	ld	s0,64(sp)
    80003efe:	74e2                	ld	s1,56(sp)
    80003f00:	7942                	ld	s2,48(sp)
    80003f02:	79a2                	ld	s3,40(sp)
    80003f04:	7a02                	ld	s4,32(sp)
    80003f06:	6ae2                	ld	s5,24(sp)
    80003f08:	6b42                	ld	s6,16(sp)
    80003f0a:	6ba2                	ld	s7,8(sp)
    80003f0c:	6161                	addi	sp,sp,80
    80003f0e:	8082                	ret
    80003f10:	8082                	ret

0000000080003f12 <initlog>:
{
    80003f12:	7179                	addi	sp,sp,-48
    80003f14:	f406                	sd	ra,40(sp)
    80003f16:	f022                	sd	s0,32(sp)
    80003f18:	ec26                	sd	s1,24(sp)
    80003f1a:	e84a                	sd	s2,16(sp)
    80003f1c:	e44e                	sd	s3,8(sp)
    80003f1e:	1800                	addi	s0,sp,48
    80003f20:	892a                	mv	s2,a0
    80003f22:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f24:	0001d497          	auipc	s1,0x1d
    80003f28:	22448493          	addi	s1,s1,548 # 80021148 <log>
    80003f2c:	00003597          	auipc	a1,0x3
    80003f30:	5cc58593          	addi	a1,a1,1484 # 800074f8 <etext+0x4f8>
    80003f34:	8526                	mv	a0,s1
    80003f36:	c19fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003f3a:	0149a583          	lw	a1,20(s3)
    80003f3e:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003f40:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f44:	854a                	mv	a0,s2
    80003f46:	f95fe0ef          	jal	80002eda <bread>
  log.lh.n = lh->n;
    80003f4a:	4d30                	lw	a2,88(a0)
    80003f4c:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f4e:	00c05f63          	blez	a2,80003f6c <initlog+0x5a>
    80003f52:	87aa                	mv	a5,a0
    80003f54:	0001d717          	auipc	a4,0x1d
    80003f58:	22070713          	addi	a4,a4,544 # 80021174 <log+0x2c>
    80003f5c:	060a                	slli	a2,a2,0x2
    80003f5e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f60:	4ff4                	lw	a3,92(a5)
    80003f62:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f64:	0791                	addi	a5,a5,4
    80003f66:	0711                	addi	a4,a4,4
    80003f68:	fec79ce3          	bne	a5,a2,80003f60 <initlog+0x4e>
  brelse(buf);
    80003f6c:	876ff0ef          	jal	80002fe2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f70:	4505                	li	a0,1
    80003f72:	edbff0ef          	jal	80003e4c <install_trans>
  log.lh.n = 0;
    80003f76:	0001d797          	auipc	a5,0x1d
    80003f7a:	1e07ad23          	sw	zero,506(a5) # 80021170 <log+0x28>
  write_head(); // clear the log
    80003f7e:	e71ff0ef          	jal	80003dee <write_head>
}
    80003f82:	70a2                	ld	ra,40(sp)
    80003f84:	7402                	ld	s0,32(sp)
    80003f86:	64e2                	ld	s1,24(sp)
    80003f88:	6942                	ld	s2,16(sp)
    80003f8a:	69a2                	ld	s3,8(sp)
    80003f8c:	6145                	addi	sp,sp,48
    80003f8e:	8082                	ret

0000000080003f90 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	e04a                	sd	s2,0(sp)
    80003f9a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f9c:	0001d517          	auipc	a0,0x1d
    80003fa0:	1ac50513          	addi	a0,a0,428 # 80021148 <log>
    80003fa4:	c2bfc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003fa8:	0001d497          	auipc	s1,0x1d
    80003fac:	1a048493          	addi	s1,s1,416 # 80021148 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003fb0:	4979                	li	s2,30
    80003fb2:	a029                	j	80003fbc <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003fb4:	85a6                	mv	a1,s1
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	ffffd0ef          	jal	80001fb6 <sleep>
    if(log.committing){
    80003fbc:	509c                	lw	a5,32(s1)
    80003fbe:	fbfd                	bnez	a5,80003fb4 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003fc0:	4cd8                	lw	a4,28(s1)
    80003fc2:	2705                	addiw	a4,a4,1
    80003fc4:	0027179b          	slliw	a5,a4,0x2
    80003fc8:	9fb9                	addw	a5,a5,a4
    80003fca:	0017979b          	slliw	a5,a5,0x1
    80003fce:	5494                	lw	a3,40(s1)
    80003fd0:	9fb5                	addw	a5,a5,a3
    80003fd2:	00f95763          	bge	s2,a5,80003fe0 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003fd6:	85a6                	mv	a1,s1
    80003fd8:	8526                	mv	a0,s1
    80003fda:	fddfd0ef          	jal	80001fb6 <sleep>
    80003fde:	bff9                	j	80003fbc <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003fe0:	0001d517          	auipc	a0,0x1d
    80003fe4:	16850513          	addi	a0,a0,360 # 80021148 <log>
    80003fe8:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003fea:	c7dfc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003fee:	60e2                	ld	ra,24(sp)
    80003ff0:	6442                	ld	s0,16(sp)
    80003ff2:	64a2                	ld	s1,8(sp)
    80003ff4:	6902                	ld	s2,0(sp)
    80003ff6:	6105                	addi	sp,sp,32
    80003ff8:	8082                	ret

0000000080003ffa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003ffa:	7139                	addi	sp,sp,-64
    80003ffc:	fc06                	sd	ra,56(sp)
    80003ffe:	f822                	sd	s0,48(sp)
    80004000:	f426                	sd	s1,40(sp)
    80004002:	f04a                	sd	s2,32(sp)
    80004004:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004006:	0001d497          	auipc	s1,0x1d
    8000400a:	14248493          	addi	s1,s1,322 # 80021148 <log>
    8000400e:	8526                	mv	a0,s1
    80004010:	bbffc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80004014:	4cdc                	lw	a5,28(s1)
    80004016:	37fd                	addiw	a5,a5,-1
    80004018:	0007891b          	sext.w	s2,a5
    8000401c:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    8000401e:	509c                	lw	a5,32(s1)
    80004020:	ef9d                	bnez	a5,8000405e <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80004022:	04091763          	bnez	s2,80004070 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80004026:	0001d497          	auipc	s1,0x1d
    8000402a:	12248493          	addi	s1,s1,290 # 80021148 <log>
    8000402e:	4785                	li	a5,1
    80004030:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004032:	8526                	mv	a0,s1
    80004034:	c33fc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004038:	549c                	lw	a5,40(s1)
    8000403a:	04f04b63          	bgtz	a5,80004090 <end_op+0x96>
    acquire(&log.lock);
    8000403e:	0001d497          	auipc	s1,0x1d
    80004042:	10a48493          	addi	s1,s1,266 # 80021148 <log>
    80004046:	8526                	mv	a0,s1
    80004048:	b87fc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    8000404c:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80004050:	8526                	mv	a0,s1
    80004052:	fb5fd0ef          	jal	80002006 <wakeup>
    release(&log.lock);
    80004056:	8526                	mv	a0,s1
    80004058:	c0ffc0ef          	jal	80000c66 <release>
}
    8000405c:	a025                	j	80004084 <end_op+0x8a>
    8000405e:	ec4e                	sd	s3,24(sp)
    80004060:	e852                	sd	s4,16(sp)
    80004062:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004064:	00003517          	auipc	a0,0x3
    80004068:	49c50513          	addi	a0,a0,1180 # 80007500 <etext+0x500>
    8000406c:	f74fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80004070:	0001d497          	auipc	s1,0x1d
    80004074:	0d848493          	addi	s1,s1,216 # 80021148 <log>
    80004078:	8526                	mv	a0,s1
    8000407a:	f8dfd0ef          	jal	80002006 <wakeup>
  release(&log.lock);
    8000407e:	8526                	mv	a0,s1
    80004080:	be7fc0ef          	jal	80000c66 <release>
}
    80004084:	70e2                	ld	ra,56(sp)
    80004086:	7442                	ld	s0,48(sp)
    80004088:	74a2                	ld	s1,40(sp)
    8000408a:	7902                	ld	s2,32(sp)
    8000408c:	6121                	addi	sp,sp,64
    8000408e:	8082                	ret
    80004090:	ec4e                	sd	s3,24(sp)
    80004092:	e852                	sd	s4,16(sp)
    80004094:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004096:	0001da97          	auipc	s5,0x1d
    8000409a:	0dea8a93          	addi	s5,s5,222 # 80021174 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000409e:	0001da17          	auipc	s4,0x1d
    800040a2:	0aaa0a13          	addi	s4,s4,170 # 80021148 <log>
    800040a6:	018a2583          	lw	a1,24(s4)
    800040aa:	012585bb          	addw	a1,a1,s2
    800040ae:	2585                	addiw	a1,a1,1
    800040b0:	024a2503          	lw	a0,36(s4)
    800040b4:	e27fe0ef          	jal	80002eda <bread>
    800040b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800040ba:	000aa583          	lw	a1,0(s5)
    800040be:	024a2503          	lw	a0,36(s4)
    800040c2:	e19fe0ef          	jal	80002eda <bread>
    800040c6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800040c8:	40000613          	li	a2,1024
    800040cc:	05850593          	addi	a1,a0,88
    800040d0:	05848513          	addi	a0,s1,88
    800040d4:	c2bfc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    800040d8:	8526                	mv	a0,s1
    800040da:	ed7fe0ef          	jal	80002fb0 <bwrite>
    brelse(from);
    800040de:	854e                	mv	a0,s3
    800040e0:	f03fe0ef          	jal	80002fe2 <brelse>
    brelse(to);
    800040e4:	8526                	mv	a0,s1
    800040e6:	efdfe0ef          	jal	80002fe2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ea:	2905                	addiw	s2,s2,1
    800040ec:	0a91                	addi	s5,s5,4
    800040ee:	028a2783          	lw	a5,40(s4)
    800040f2:	faf94ae3          	blt	s2,a5,800040a6 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800040f6:	cf9ff0ef          	jal	80003dee <write_head>
    install_trans(0); // Now install writes to home locations
    800040fa:	4501                	li	a0,0
    800040fc:	d51ff0ef          	jal	80003e4c <install_trans>
    log.lh.n = 0;
    80004100:	0001d797          	auipc	a5,0x1d
    80004104:	0607a823          	sw	zero,112(a5) # 80021170 <log+0x28>
    write_head();    // Erase the transaction from the log
    80004108:	ce7ff0ef          	jal	80003dee <write_head>
    8000410c:	69e2                	ld	s3,24(sp)
    8000410e:	6a42                	ld	s4,16(sp)
    80004110:	6aa2                	ld	s5,8(sp)
    80004112:	b735                	j	8000403e <end_op+0x44>

0000000080004114 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004114:	1101                	addi	sp,sp,-32
    80004116:	ec06                	sd	ra,24(sp)
    80004118:	e822                	sd	s0,16(sp)
    8000411a:	e426                	sd	s1,8(sp)
    8000411c:	e04a                	sd	s2,0(sp)
    8000411e:	1000                	addi	s0,sp,32
    80004120:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004122:	0001d917          	auipc	s2,0x1d
    80004126:	02690913          	addi	s2,s2,38 # 80021148 <log>
    8000412a:	854a                	mv	a0,s2
    8000412c:	aa3fc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80004130:	02892603          	lw	a2,40(s2)
    80004134:	47f5                	li	a5,29
    80004136:	04c7cc63          	blt	a5,a2,8000418e <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000413a:	0001d797          	auipc	a5,0x1d
    8000413e:	02a7a783          	lw	a5,42(a5) # 80021164 <log+0x1c>
    80004142:	04f05c63          	blez	a5,8000419a <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004146:	4781                	li	a5,0
    80004148:	04c05f63          	blez	a2,800041a6 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000414c:	44cc                	lw	a1,12(s1)
    8000414e:	0001d717          	auipc	a4,0x1d
    80004152:	02670713          	addi	a4,a4,38 # 80021174 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80004156:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004158:	4314                	lw	a3,0(a4)
    8000415a:	04b68663          	beq	a3,a1,800041a6 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    8000415e:	2785                	addiw	a5,a5,1
    80004160:	0711                	addi	a4,a4,4
    80004162:	fef61be3          	bne	a2,a5,80004158 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004166:	0621                	addi	a2,a2,8
    80004168:	060a                	slli	a2,a2,0x2
    8000416a:	0001d797          	auipc	a5,0x1d
    8000416e:	fde78793          	addi	a5,a5,-34 # 80021148 <log>
    80004172:	97b2                	add	a5,a5,a2
    80004174:	44d8                	lw	a4,12(s1)
    80004176:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004178:	8526                	mv	a0,s1
    8000417a:	ef1fe0ef          	jal	8000306a <bpin>
    log.lh.n++;
    8000417e:	0001d717          	auipc	a4,0x1d
    80004182:	fca70713          	addi	a4,a4,-54 # 80021148 <log>
    80004186:	571c                	lw	a5,40(a4)
    80004188:	2785                	addiw	a5,a5,1
    8000418a:	d71c                	sw	a5,40(a4)
    8000418c:	a80d                	j	800041be <log_write+0xaa>
    panic("too big a transaction");
    8000418e:	00003517          	auipc	a0,0x3
    80004192:	38250513          	addi	a0,a0,898 # 80007510 <etext+0x510>
    80004196:	e4afc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    8000419a:	00003517          	auipc	a0,0x3
    8000419e:	38e50513          	addi	a0,a0,910 # 80007528 <etext+0x528>
    800041a2:	e3efc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    800041a6:	00878693          	addi	a3,a5,8
    800041aa:	068a                	slli	a3,a3,0x2
    800041ac:	0001d717          	auipc	a4,0x1d
    800041b0:	f9c70713          	addi	a4,a4,-100 # 80021148 <log>
    800041b4:	9736                	add	a4,a4,a3
    800041b6:	44d4                	lw	a3,12(s1)
    800041b8:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800041ba:	faf60fe3          	beq	a2,a5,80004178 <log_write+0x64>
  }
  release(&log.lock);
    800041be:	0001d517          	auipc	a0,0x1d
    800041c2:	f8a50513          	addi	a0,a0,-118 # 80021148 <log>
    800041c6:	aa1fc0ef          	jal	80000c66 <release>
}
    800041ca:	60e2                	ld	ra,24(sp)
    800041cc:	6442                	ld	s0,16(sp)
    800041ce:	64a2                	ld	s1,8(sp)
    800041d0:	6902                	ld	s2,0(sp)
    800041d2:	6105                	addi	sp,sp,32
    800041d4:	8082                	ret

00000000800041d6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800041d6:	1101                	addi	sp,sp,-32
    800041d8:	ec06                	sd	ra,24(sp)
    800041da:	e822                	sd	s0,16(sp)
    800041dc:	e426                	sd	s1,8(sp)
    800041de:	e04a                	sd	s2,0(sp)
    800041e0:	1000                	addi	s0,sp,32
    800041e2:	84aa                	mv	s1,a0
    800041e4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800041e6:	00003597          	auipc	a1,0x3
    800041ea:	36258593          	addi	a1,a1,866 # 80007548 <etext+0x548>
    800041ee:	0521                	addi	a0,a0,8
    800041f0:	95ffc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    800041f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800041f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800041fc:	0204a423          	sw	zero,40(s1)
}
    80004200:	60e2                	ld	ra,24(sp)
    80004202:	6442                	ld	s0,16(sp)
    80004204:	64a2                	ld	s1,8(sp)
    80004206:	6902                	ld	s2,0(sp)
    80004208:	6105                	addi	sp,sp,32
    8000420a:	8082                	ret

000000008000420c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000420c:	1101                	addi	sp,sp,-32
    8000420e:	ec06                	sd	ra,24(sp)
    80004210:	e822                	sd	s0,16(sp)
    80004212:	e426                	sd	s1,8(sp)
    80004214:	e04a                	sd	s2,0(sp)
    80004216:	1000                	addi	s0,sp,32
    80004218:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000421a:	00850913          	addi	s2,a0,8
    8000421e:	854a                	mv	a0,s2
    80004220:	9affc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80004224:	409c                	lw	a5,0(s1)
    80004226:	c799                	beqz	a5,80004234 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004228:	85ca                	mv	a1,s2
    8000422a:	8526                	mv	a0,s1
    8000422c:	d8bfd0ef          	jal	80001fb6 <sleep>
  while (lk->locked) {
    80004230:	409c                	lw	a5,0(s1)
    80004232:	fbfd                	bnez	a5,80004228 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004234:	4785                	li	a5,1
    80004236:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004238:	e96fd0ef          	jal	800018ce <myproc>
    8000423c:	591c                	lw	a5,48(a0)
    8000423e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004240:	854a                	mv	a0,s2
    80004242:	a25fc0ef          	jal	80000c66 <release>
}
    80004246:	60e2                	ld	ra,24(sp)
    80004248:	6442                	ld	s0,16(sp)
    8000424a:	64a2                	ld	s1,8(sp)
    8000424c:	6902                	ld	s2,0(sp)
    8000424e:	6105                	addi	sp,sp,32
    80004250:	8082                	ret

0000000080004252 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004252:	1101                	addi	sp,sp,-32
    80004254:	ec06                	sd	ra,24(sp)
    80004256:	e822                	sd	s0,16(sp)
    80004258:	e426                	sd	s1,8(sp)
    8000425a:	e04a                	sd	s2,0(sp)
    8000425c:	1000                	addi	s0,sp,32
    8000425e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004260:	00850913          	addi	s2,a0,8
    80004264:	854a                	mv	a0,s2
    80004266:	969fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    8000426a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000426e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004272:	8526                	mv	a0,s1
    80004274:	d93fd0ef          	jal	80002006 <wakeup>
  release(&lk->lk);
    80004278:	854a                	mv	a0,s2
    8000427a:	9edfc0ef          	jal	80000c66 <release>
}
    8000427e:	60e2                	ld	ra,24(sp)
    80004280:	6442                	ld	s0,16(sp)
    80004282:	64a2                	ld	s1,8(sp)
    80004284:	6902                	ld	s2,0(sp)
    80004286:	6105                	addi	sp,sp,32
    80004288:	8082                	ret

000000008000428a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000428a:	7179                	addi	sp,sp,-48
    8000428c:	f406                	sd	ra,40(sp)
    8000428e:	f022                	sd	s0,32(sp)
    80004290:	ec26                	sd	s1,24(sp)
    80004292:	e84a                	sd	s2,16(sp)
    80004294:	1800                	addi	s0,sp,48
    80004296:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004298:	00850913          	addi	s2,a0,8
    8000429c:	854a                	mv	a0,s2
    8000429e:	931fc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800042a2:	409c                	lw	a5,0(s1)
    800042a4:	ef81                	bnez	a5,800042bc <holdingsleep+0x32>
    800042a6:	4481                	li	s1,0
  release(&lk->lk);
    800042a8:	854a                	mv	a0,s2
    800042aa:	9bdfc0ef          	jal	80000c66 <release>
  return r;
}
    800042ae:	8526                	mv	a0,s1
    800042b0:	70a2                	ld	ra,40(sp)
    800042b2:	7402                	ld	s0,32(sp)
    800042b4:	64e2                	ld	s1,24(sp)
    800042b6:	6942                	ld	s2,16(sp)
    800042b8:	6145                	addi	sp,sp,48
    800042ba:	8082                	ret
    800042bc:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    800042be:	0284a983          	lw	s3,40(s1)
    800042c2:	e0cfd0ef          	jal	800018ce <myproc>
    800042c6:	5904                	lw	s1,48(a0)
    800042c8:	413484b3          	sub	s1,s1,s3
    800042cc:	0014b493          	seqz	s1,s1
    800042d0:	69a2                	ld	s3,8(sp)
    800042d2:	bfd9                	j	800042a8 <holdingsleep+0x1e>

00000000800042d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800042d4:	1141                	addi	sp,sp,-16
    800042d6:	e406                	sd	ra,8(sp)
    800042d8:	e022                	sd	s0,0(sp)
    800042da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800042dc:	00003597          	auipc	a1,0x3
    800042e0:	27c58593          	addi	a1,a1,636 # 80007558 <etext+0x558>
    800042e4:	0001d517          	auipc	a0,0x1d
    800042e8:	fac50513          	addi	a0,a0,-84 # 80021290 <ftable>
    800042ec:	863fc0ef          	jal	80000b4e <initlock>
}
    800042f0:	60a2                	ld	ra,8(sp)
    800042f2:	6402                	ld	s0,0(sp)
    800042f4:	0141                	addi	sp,sp,16
    800042f6:	8082                	ret

00000000800042f8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800042f8:	1101                	addi	sp,sp,-32
    800042fa:	ec06                	sd	ra,24(sp)
    800042fc:	e822                	sd	s0,16(sp)
    800042fe:	e426                	sd	s1,8(sp)
    80004300:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004302:	0001d517          	auipc	a0,0x1d
    80004306:	f8e50513          	addi	a0,a0,-114 # 80021290 <ftable>
    8000430a:	8c5fc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000430e:	0001d497          	auipc	s1,0x1d
    80004312:	f9a48493          	addi	s1,s1,-102 # 800212a8 <ftable+0x18>
    80004316:	0001e717          	auipc	a4,0x1e
    8000431a:	f3270713          	addi	a4,a4,-206 # 80022248 <disk>
    if(f->ref == 0){
    8000431e:	40dc                	lw	a5,4(s1)
    80004320:	cf89                	beqz	a5,8000433a <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004322:	02848493          	addi	s1,s1,40
    80004326:	fee49ce3          	bne	s1,a4,8000431e <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000432a:	0001d517          	auipc	a0,0x1d
    8000432e:	f6650513          	addi	a0,a0,-154 # 80021290 <ftable>
    80004332:	935fc0ef          	jal	80000c66 <release>
  return 0;
    80004336:	4481                	li	s1,0
    80004338:	a809                	j	8000434a <filealloc+0x52>
      f->ref = 1;
    8000433a:	4785                	li	a5,1
    8000433c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000433e:	0001d517          	auipc	a0,0x1d
    80004342:	f5250513          	addi	a0,a0,-174 # 80021290 <ftable>
    80004346:	921fc0ef          	jal	80000c66 <release>
}
    8000434a:	8526                	mv	a0,s1
    8000434c:	60e2                	ld	ra,24(sp)
    8000434e:	6442                	ld	s0,16(sp)
    80004350:	64a2                	ld	s1,8(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004356:	1101                	addi	sp,sp,-32
    80004358:	ec06                	sd	ra,24(sp)
    8000435a:	e822                	sd	s0,16(sp)
    8000435c:	e426                	sd	s1,8(sp)
    8000435e:	1000                	addi	s0,sp,32
    80004360:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004362:	0001d517          	auipc	a0,0x1d
    80004366:	f2e50513          	addi	a0,a0,-210 # 80021290 <ftable>
    8000436a:	865fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    8000436e:	40dc                	lw	a5,4(s1)
    80004370:	02f05063          	blez	a5,80004390 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80004374:	2785                	addiw	a5,a5,1
    80004376:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004378:	0001d517          	auipc	a0,0x1d
    8000437c:	f1850513          	addi	a0,a0,-232 # 80021290 <ftable>
    80004380:	8e7fc0ef          	jal	80000c66 <release>
  return f;
}
    80004384:	8526                	mv	a0,s1
    80004386:	60e2                	ld	ra,24(sp)
    80004388:	6442                	ld	s0,16(sp)
    8000438a:	64a2                	ld	s1,8(sp)
    8000438c:	6105                	addi	sp,sp,32
    8000438e:	8082                	ret
    panic("filedup");
    80004390:	00003517          	auipc	a0,0x3
    80004394:	1d050513          	addi	a0,a0,464 # 80007560 <etext+0x560>
    80004398:	c48fc0ef          	jal	800007e0 <panic>

000000008000439c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000439c:	7139                	addi	sp,sp,-64
    8000439e:	fc06                	sd	ra,56(sp)
    800043a0:	f822                	sd	s0,48(sp)
    800043a2:	f426                	sd	s1,40(sp)
    800043a4:	0080                	addi	s0,sp,64
    800043a6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800043a8:	0001d517          	auipc	a0,0x1d
    800043ac:	ee850513          	addi	a0,a0,-280 # 80021290 <ftable>
    800043b0:	81ffc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800043b4:	40dc                	lw	a5,4(s1)
    800043b6:	04f05a63          	blez	a5,8000440a <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    800043ba:	37fd                	addiw	a5,a5,-1
    800043bc:	0007871b          	sext.w	a4,a5
    800043c0:	c0dc                	sw	a5,4(s1)
    800043c2:	04e04e63          	bgtz	a4,8000441e <fileclose+0x82>
    800043c6:	f04a                	sd	s2,32(sp)
    800043c8:	ec4e                	sd	s3,24(sp)
    800043ca:	e852                	sd	s4,16(sp)
    800043cc:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800043ce:	0004a903          	lw	s2,0(s1)
    800043d2:	0094ca83          	lbu	s5,9(s1)
    800043d6:	0104ba03          	ld	s4,16(s1)
    800043da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800043de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800043e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800043e6:	0001d517          	auipc	a0,0x1d
    800043ea:	eaa50513          	addi	a0,a0,-342 # 80021290 <ftable>
    800043ee:	879fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    800043f2:	4785                	li	a5,1
    800043f4:	04f90063          	beq	s2,a5,80004434 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800043f8:	3979                	addiw	s2,s2,-2
    800043fa:	4785                	li	a5,1
    800043fc:	0527f563          	bgeu	a5,s2,80004446 <fileclose+0xaa>
    80004400:	7902                	ld	s2,32(sp)
    80004402:	69e2                	ld	s3,24(sp)
    80004404:	6a42                	ld	s4,16(sp)
    80004406:	6aa2                	ld	s5,8(sp)
    80004408:	a00d                	j	8000442a <fileclose+0x8e>
    8000440a:	f04a                	sd	s2,32(sp)
    8000440c:	ec4e                	sd	s3,24(sp)
    8000440e:	e852                	sd	s4,16(sp)
    80004410:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004412:	00003517          	auipc	a0,0x3
    80004416:	15650513          	addi	a0,a0,342 # 80007568 <etext+0x568>
    8000441a:	bc6fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    8000441e:	0001d517          	auipc	a0,0x1d
    80004422:	e7250513          	addi	a0,a0,-398 # 80021290 <ftable>
    80004426:	841fc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    8000442a:	70e2                	ld	ra,56(sp)
    8000442c:	7442                	ld	s0,48(sp)
    8000442e:	74a2                	ld	s1,40(sp)
    80004430:	6121                	addi	sp,sp,64
    80004432:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004434:	85d6                	mv	a1,s5
    80004436:	8552                	mv	a0,s4
    80004438:	336000ef          	jal	8000476e <pipeclose>
    8000443c:	7902                	ld	s2,32(sp)
    8000443e:	69e2                	ld	s3,24(sp)
    80004440:	6a42                	ld	s4,16(sp)
    80004442:	6aa2                	ld	s5,8(sp)
    80004444:	b7dd                	j	8000442a <fileclose+0x8e>
    begin_op();
    80004446:	b4bff0ef          	jal	80003f90 <begin_op>
    iput(ff.ip);
    8000444a:	854e                	mv	a0,s3
    8000444c:	adcff0ef          	jal	80003728 <iput>
    end_op();
    80004450:	babff0ef          	jal	80003ffa <end_op>
    80004454:	7902                	ld	s2,32(sp)
    80004456:	69e2                	ld	s3,24(sp)
    80004458:	6a42                	ld	s4,16(sp)
    8000445a:	6aa2                	ld	s5,8(sp)
    8000445c:	b7f9                	j	8000442a <fileclose+0x8e>

000000008000445e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000445e:	715d                	addi	sp,sp,-80
    80004460:	e486                	sd	ra,72(sp)
    80004462:	e0a2                	sd	s0,64(sp)
    80004464:	fc26                	sd	s1,56(sp)
    80004466:	f44e                	sd	s3,40(sp)
    80004468:	0880                	addi	s0,sp,80
    8000446a:	84aa                	mv	s1,a0
    8000446c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000446e:	c60fd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004472:	409c                	lw	a5,0(s1)
    80004474:	37f9                	addiw	a5,a5,-2
    80004476:	4705                	li	a4,1
    80004478:	04f76063          	bltu	a4,a5,800044b8 <filestat+0x5a>
    8000447c:	f84a                	sd	s2,48(sp)
    8000447e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004480:	6c88                	ld	a0,24(s1)
    80004482:	924ff0ef          	jal	800035a6 <ilock>
    stati(f->ip, &st);
    80004486:	fb840593          	addi	a1,s0,-72
    8000448a:	6c88                	ld	a0,24(s1)
    8000448c:	c80ff0ef          	jal	8000390c <stati>
    iunlock(f->ip);
    80004490:	6c88                	ld	a0,24(s1)
    80004492:	9c2ff0ef          	jal	80003654 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004496:	46e1                	li	a3,24
    80004498:	fb840613          	addi	a2,s0,-72
    8000449c:	85ce                	mv	a1,s3
    8000449e:	05093503          	ld	a0,80(s2)
    800044a2:	940fd0ef          	jal	800015e2 <copyout>
    800044a6:	41f5551b          	sraiw	a0,a0,0x1f
    800044aa:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800044ac:	60a6                	ld	ra,72(sp)
    800044ae:	6406                	ld	s0,64(sp)
    800044b0:	74e2                	ld	s1,56(sp)
    800044b2:	79a2                	ld	s3,40(sp)
    800044b4:	6161                	addi	sp,sp,80
    800044b6:	8082                	ret
  return -1;
    800044b8:	557d                	li	a0,-1
    800044ba:	bfcd                	j	800044ac <filestat+0x4e>

00000000800044bc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800044bc:	7179                	addi	sp,sp,-48
    800044be:	f406                	sd	ra,40(sp)
    800044c0:	f022                	sd	s0,32(sp)
    800044c2:	e84a                	sd	s2,16(sp)
    800044c4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800044c6:	00854783          	lbu	a5,8(a0)
    800044ca:	cfd1                	beqz	a5,80004566 <fileread+0xaa>
    800044cc:	ec26                	sd	s1,24(sp)
    800044ce:	e44e                	sd	s3,8(sp)
    800044d0:	84aa                	mv	s1,a0
    800044d2:	89ae                	mv	s3,a1
    800044d4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800044d6:	411c                	lw	a5,0(a0)
    800044d8:	4705                	li	a4,1
    800044da:	04e78363          	beq	a5,a4,80004520 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800044de:	470d                	li	a4,3
    800044e0:	04e78763          	beq	a5,a4,8000452e <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800044e4:	4709                	li	a4,2
    800044e6:	06e79a63          	bne	a5,a4,8000455a <fileread+0x9e>
    ilock(f->ip);
    800044ea:	6d08                	ld	a0,24(a0)
    800044ec:	8baff0ef          	jal	800035a6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800044f0:	874a                	mv	a4,s2
    800044f2:	5094                	lw	a3,32(s1)
    800044f4:	864e                	mv	a2,s3
    800044f6:	4585                	li	a1,1
    800044f8:	6c88                	ld	a0,24(s1)
    800044fa:	c3cff0ef          	jal	80003936 <readi>
    800044fe:	892a                	mv	s2,a0
    80004500:	00a05563          	blez	a0,8000450a <fileread+0x4e>
      f->off += r;
    80004504:	509c                	lw	a5,32(s1)
    80004506:	9fa9                	addw	a5,a5,a0
    80004508:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000450a:	6c88                	ld	a0,24(s1)
    8000450c:	948ff0ef          	jal	80003654 <iunlock>
    80004510:	64e2                	ld	s1,24(sp)
    80004512:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004514:	854a                	mv	a0,s2
    80004516:	70a2                	ld	ra,40(sp)
    80004518:	7402                	ld	s0,32(sp)
    8000451a:	6942                	ld	s2,16(sp)
    8000451c:	6145                	addi	sp,sp,48
    8000451e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004520:	6908                	ld	a0,16(a0)
    80004522:	388000ef          	jal	800048aa <piperead>
    80004526:	892a                	mv	s2,a0
    80004528:	64e2                	ld	s1,24(sp)
    8000452a:	69a2                	ld	s3,8(sp)
    8000452c:	b7e5                	j	80004514 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000452e:	02451783          	lh	a5,36(a0)
    80004532:	03079693          	slli	a3,a5,0x30
    80004536:	92c1                	srli	a3,a3,0x30
    80004538:	4725                	li	a4,9
    8000453a:	02d76863          	bltu	a4,a3,8000456a <fileread+0xae>
    8000453e:	0792                	slli	a5,a5,0x4
    80004540:	0001d717          	auipc	a4,0x1d
    80004544:	cb070713          	addi	a4,a4,-848 # 800211f0 <devsw>
    80004548:	97ba                	add	a5,a5,a4
    8000454a:	639c                	ld	a5,0(a5)
    8000454c:	c39d                	beqz	a5,80004572 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    8000454e:	4505                	li	a0,1
    80004550:	9782                	jalr	a5
    80004552:	892a                	mv	s2,a0
    80004554:	64e2                	ld	s1,24(sp)
    80004556:	69a2                	ld	s3,8(sp)
    80004558:	bf75                	j	80004514 <fileread+0x58>
    panic("fileread");
    8000455a:	00003517          	auipc	a0,0x3
    8000455e:	01e50513          	addi	a0,a0,30 # 80007578 <etext+0x578>
    80004562:	a7efc0ef          	jal	800007e0 <panic>
    return -1;
    80004566:	597d                	li	s2,-1
    80004568:	b775                	j	80004514 <fileread+0x58>
      return -1;
    8000456a:	597d                	li	s2,-1
    8000456c:	64e2                	ld	s1,24(sp)
    8000456e:	69a2                	ld	s3,8(sp)
    80004570:	b755                	j	80004514 <fileread+0x58>
    80004572:	597d                	li	s2,-1
    80004574:	64e2                	ld	s1,24(sp)
    80004576:	69a2                	ld	s3,8(sp)
    80004578:	bf71                	j	80004514 <fileread+0x58>

000000008000457a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000457a:	00954783          	lbu	a5,9(a0)
    8000457e:	10078b63          	beqz	a5,80004694 <filewrite+0x11a>
{
    80004582:	715d                	addi	sp,sp,-80
    80004584:	e486                	sd	ra,72(sp)
    80004586:	e0a2                	sd	s0,64(sp)
    80004588:	f84a                	sd	s2,48(sp)
    8000458a:	f052                	sd	s4,32(sp)
    8000458c:	e85a                	sd	s6,16(sp)
    8000458e:	0880                	addi	s0,sp,80
    80004590:	892a                	mv	s2,a0
    80004592:	8b2e                	mv	s6,a1
    80004594:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004596:	411c                	lw	a5,0(a0)
    80004598:	4705                	li	a4,1
    8000459a:	02e78763          	beq	a5,a4,800045c8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000459e:	470d                	li	a4,3
    800045a0:	02e78863          	beq	a5,a4,800045d0 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800045a4:	4709                	li	a4,2
    800045a6:	0ce79c63          	bne	a5,a4,8000467e <filewrite+0x104>
    800045aa:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800045ac:	0ac05863          	blez	a2,8000465c <filewrite+0xe2>
    800045b0:	fc26                	sd	s1,56(sp)
    800045b2:	ec56                	sd	s5,24(sp)
    800045b4:	e45e                	sd	s7,8(sp)
    800045b6:	e062                	sd	s8,0(sp)
    int i = 0;
    800045b8:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800045ba:	6b85                	lui	s7,0x1
    800045bc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800045c0:	6c05                	lui	s8,0x1
    800045c2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800045c6:	a8b5                	j	80004642 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    800045c8:	6908                	ld	a0,16(a0)
    800045ca:	1fc000ef          	jal	800047c6 <pipewrite>
    800045ce:	a04d                	j	80004670 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800045d0:	02451783          	lh	a5,36(a0)
    800045d4:	03079693          	slli	a3,a5,0x30
    800045d8:	92c1                	srli	a3,a3,0x30
    800045da:	4725                	li	a4,9
    800045dc:	0ad76e63          	bltu	a4,a3,80004698 <filewrite+0x11e>
    800045e0:	0792                	slli	a5,a5,0x4
    800045e2:	0001d717          	auipc	a4,0x1d
    800045e6:	c0e70713          	addi	a4,a4,-1010 # 800211f0 <devsw>
    800045ea:	97ba                	add	a5,a5,a4
    800045ec:	679c                	ld	a5,8(a5)
    800045ee:	c7dd                	beqz	a5,8000469c <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    800045f0:	4505                	li	a0,1
    800045f2:	9782                	jalr	a5
    800045f4:	a8b5                	j	80004670 <filewrite+0xf6>
      if(n1 > max)
    800045f6:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800045fa:	997ff0ef          	jal	80003f90 <begin_op>
      ilock(f->ip);
    800045fe:	01893503          	ld	a0,24(s2)
    80004602:	fa5fe0ef          	jal	800035a6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004606:	8756                	mv	a4,s5
    80004608:	02092683          	lw	a3,32(s2)
    8000460c:	01698633          	add	a2,s3,s6
    80004610:	4585                	li	a1,1
    80004612:	01893503          	ld	a0,24(s2)
    80004616:	c1cff0ef          	jal	80003a32 <writei>
    8000461a:	84aa                	mv	s1,a0
    8000461c:	00a05763          	blez	a0,8000462a <filewrite+0xb0>
        f->off += r;
    80004620:	02092783          	lw	a5,32(s2)
    80004624:	9fa9                	addw	a5,a5,a0
    80004626:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000462a:	01893503          	ld	a0,24(s2)
    8000462e:	826ff0ef          	jal	80003654 <iunlock>
      end_op();
    80004632:	9c9ff0ef          	jal	80003ffa <end_op>

      if(r != n1){
    80004636:	029a9563          	bne	s5,s1,80004660 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    8000463a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000463e:	0149da63          	bge	s3,s4,80004652 <filewrite+0xd8>
      int n1 = n - i;
    80004642:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004646:	0004879b          	sext.w	a5,s1
    8000464a:	fafbd6e3          	bge	s7,a5,800045f6 <filewrite+0x7c>
    8000464e:	84e2                	mv	s1,s8
    80004650:	b75d                	j	800045f6 <filewrite+0x7c>
    80004652:	74e2                	ld	s1,56(sp)
    80004654:	6ae2                	ld	s5,24(sp)
    80004656:	6ba2                	ld	s7,8(sp)
    80004658:	6c02                	ld	s8,0(sp)
    8000465a:	a039                	j	80004668 <filewrite+0xee>
    int i = 0;
    8000465c:	4981                	li	s3,0
    8000465e:	a029                	j	80004668 <filewrite+0xee>
    80004660:	74e2                	ld	s1,56(sp)
    80004662:	6ae2                	ld	s5,24(sp)
    80004664:	6ba2                	ld	s7,8(sp)
    80004666:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80004668:	033a1c63          	bne	s4,s3,800046a0 <filewrite+0x126>
    8000466c:	8552                	mv	a0,s4
    8000466e:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004670:	60a6                	ld	ra,72(sp)
    80004672:	6406                	ld	s0,64(sp)
    80004674:	7942                	ld	s2,48(sp)
    80004676:	7a02                	ld	s4,32(sp)
    80004678:	6b42                	ld	s6,16(sp)
    8000467a:	6161                	addi	sp,sp,80
    8000467c:	8082                	ret
    8000467e:	fc26                	sd	s1,56(sp)
    80004680:	f44e                	sd	s3,40(sp)
    80004682:	ec56                	sd	s5,24(sp)
    80004684:	e45e                	sd	s7,8(sp)
    80004686:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004688:	00003517          	auipc	a0,0x3
    8000468c:	f0050513          	addi	a0,a0,-256 # 80007588 <etext+0x588>
    80004690:	950fc0ef          	jal	800007e0 <panic>
    return -1;
    80004694:	557d                	li	a0,-1
}
    80004696:	8082                	ret
      return -1;
    80004698:	557d                	li	a0,-1
    8000469a:	bfd9                	j	80004670 <filewrite+0xf6>
    8000469c:	557d                	li	a0,-1
    8000469e:	bfc9                	j	80004670 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    800046a0:	557d                	li	a0,-1
    800046a2:	79a2                	ld	s3,40(sp)
    800046a4:	b7f1                	j	80004670 <filewrite+0xf6>

00000000800046a6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800046a6:	7179                	addi	sp,sp,-48
    800046a8:	f406                	sd	ra,40(sp)
    800046aa:	f022                	sd	s0,32(sp)
    800046ac:	ec26                	sd	s1,24(sp)
    800046ae:	e052                	sd	s4,0(sp)
    800046b0:	1800                	addi	s0,sp,48
    800046b2:	84aa                	mv	s1,a0
    800046b4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800046b6:	0005b023          	sd	zero,0(a1)
    800046ba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800046be:	c3bff0ef          	jal	800042f8 <filealloc>
    800046c2:	e088                	sd	a0,0(s1)
    800046c4:	c549                	beqz	a0,8000474e <pipealloc+0xa8>
    800046c6:	c33ff0ef          	jal	800042f8 <filealloc>
    800046ca:	00aa3023          	sd	a0,0(s4)
    800046ce:	cd25                	beqz	a0,80004746 <pipealloc+0xa0>
    800046d0:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800046d2:	c2cfc0ef          	jal	80000afe <kalloc>
    800046d6:	892a                	mv	s2,a0
    800046d8:	c12d                	beqz	a0,8000473a <pipealloc+0x94>
    800046da:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800046dc:	4985                	li	s3,1
    800046de:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800046e2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800046e6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800046ea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800046ee:	00003597          	auipc	a1,0x3
    800046f2:	eaa58593          	addi	a1,a1,-342 # 80007598 <etext+0x598>
    800046f6:	c58fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800046fa:	609c                	ld	a5,0(s1)
    800046fc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004700:	609c                	ld	a5,0(s1)
    80004702:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004706:	609c                	ld	a5,0(s1)
    80004708:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000470c:	609c                	ld	a5,0(s1)
    8000470e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004712:	000a3783          	ld	a5,0(s4)
    80004716:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000471a:	000a3783          	ld	a5,0(s4)
    8000471e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004722:	000a3783          	ld	a5,0(s4)
    80004726:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000472a:	000a3783          	ld	a5,0(s4)
    8000472e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004732:	4501                	li	a0,0
    80004734:	6942                	ld	s2,16(sp)
    80004736:	69a2                	ld	s3,8(sp)
    80004738:	a01d                	j	8000475e <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000473a:	6088                	ld	a0,0(s1)
    8000473c:	c119                	beqz	a0,80004742 <pipealloc+0x9c>
    8000473e:	6942                	ld	s2,16(sp)
    80004740:	a029                	j	8000474a <pipealloc+0xa4>
    80004742:	6942                	ld	s2,16(sp)
    80004744:	a029                	j	8000474e <pipealloc+0xa8>
    80004746:	6088                	ld	a0,0(s1)
    80004748:	c10d                	beqz	a0,8000476a <pipealloc+0xc4>
    fileclose(*f0);
    8000474a:	c53ff0ef          	jal	8000439c <fileclose>
  if(*f1)
    8000474e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004752:	557d                	li	a0,-1
  if(*f1)
    80004754:	c789                	beqz	a5,8000475e <pipealloc+0xb8>
    fileclose(*f1);
    80004756:	853e                	mv	a0,a5
    80004758:	c45ff0ef          	jal	8000439c <fileclose>
  return -1;
    8000475c:	557d                	li	a0,-1
}
    8000475e:	70a2                	ld	ra,40(sp)
    80004760:	7402                	ld	s0,32(sp)
    80004762:	64e2                	ld	s1,24(sp)
    80004764:	6a02                	ld	s4,0(sp)
    80004766:	6145                	addi	sp,sp,48
    80004768:	8082                	ret
  return -1;
    8000476a:	557d                	li	a0,-1
    8000476c:	bfcd                	j	8000475e <pipealloc+0xb8>

000000008000476e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000476e:	1101                	addi	sp,sp,-32
    80004770:	ec06                	sd	ra,24(sp)
    80004772:	e822                	sd	s0,16(sp)
    80004774:	e426                	sd	s1,8(sp)
    80004776:	e04a                	sd	s2,0(sp)
    80004778:	1000                	addi	s0,sp,32
    8000477a:	84aa                	mv	s1,a0
    8000477c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000477e:	c50fc0ef          	jal	80000bce <acquire>
  if(writable){
    80004782:	02090763          	beqz	s2,800047b0 <pipeclose+0x42>
    pi->writeopen = 0;
    80004786:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000478a:	21848513          	addi	a0,s1,536
    8000478e:	879fd0ef          	jal	80002006 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004792:	2204b783          	ld	a5,544(s1)
    80004796:	e785                	bnez	a5,800047be <pipeclose+0x50>
    release(&pi->lock);
    80004798:	8526                	mv	a0,s1
    8000479a:	cccfc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    8000479e:	8526                	mv	a0,s1
    800047a0:	a7cfc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    800047a4:	60e2                	ld	ra,24(sp)
    800047a6:	6442                	ld	s0,16(sp)
    800047a8:	64a2                	ld	s1,8(sp)
    800047aa:	6902                	ld	s2,0(sp)
    800047ac:	6105                	addi	sp,sp,32
    800047ae:	8082                	ret
    pi->readopen = 0;
    800047b0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800047b4:	21c48513          	addi	a0,s1,540
    800047b8:	84ffd0ef          	jal	80002006 <wakeup>
    800047bc:	bfd9                	j	80004792 <pipeclose+0x24>
    release(&pi->lock);
    800047be:	8526                	mv	a0,s1
    800047c0:	ca6fc0ef          	jal	80000c66 <release>
}
    800047c4:	b7c5                	j	800047a4 <pipeclose+0x36>

00000000800047c6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800047c6:	711d                	addi	sp,sp,-96
    800047c8:	ec86                	sd	ra,88(sp)
    800047ca:	e8a2                	sd	s0,80(sp)
    800047cc:	e4a6                	sd	s1,72(sp)
    800047ce:	e0ca                	sd	s2,64(sp)
    800047d0:	fc4e                	sd	s3,56(sp)
    800047d2:	f852                	sd	s4,48(sp)
    800047d4:	f456                	sd	s5,40(sp)
    800047d6:	1080                	addi	s0,sp,96
    800047d8:	84aa                	mv	s1,a0
    800047da:	8aae                	mv	s5,a1
    800047dc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800047de:	8f0fd0ef          	jal	800018ce <myproc>
    800047e2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800047e4:	8526                	mv	a0,s1
    800047e6:	be8fc0ef          	jal	80000bce <acquire>
  while(i < n){
    800047ea:	0b405a63          	blez	s4,8000489e <pipewrite+0xd8>
    800047ee:	f05a                	sd	s6,32(sp)
    800047f0:	ec5e                	sd	s7,24(sp)
    800047f2:	e862                	sd	s8,16(sp)
  int i = 0;
    800047f4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800047f6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800047f8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800047fc:	21c48b93          	addi	s7,s1,540
    80004800:	a81d                	j	80004836 <pipewrite+0x70>
      release(&pi->lock);
    80004802:	8526                	mv	a0,s1
    80004804:	c62fc0ef          	jal	80000c66 <release>
      return -1;
    80004808:	597d                	li	s2,-1
    8000480a:	7b02                	ld	s6,32(sp)
    8000480c:	6be2                	ld	s7,24(sp)
    8000480e:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004810:	854a                	mv	a0,s2
    80004812:	60e6                	ld	ra,88(sp)
    80004814:	6446                	ld	s0,80(sp)
    80004816:	64a6                	ld	s1,72(sp)
    80004818:	6906                	ld	s2,64(sp)
    8000481a:	79e2                	ld	s3,56(sp)
    8000481c:	7a42                	ld	s4,48(sp)
    8000481e:	7aa2                	ld	s5,40(sp)
    80004820:	6125                	addi	sp,sp,96
    80004822:	8082                	ret
      wakeup(&pi->nread);
    80004824:	8562                	mv	a0,s8
    80004826:	fe0fd0ef          	jal	80002006 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000482a:	85a6                	mv	a1,s1
    8000482c:	855e                	mv	a0,s7
    8000482e:	f88fd0ef          	jal	80001fb6 <sleep>
  while(i < n){
    80004832:	05495b63          	bge	s2,s4,80004888 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    80004836:	2204a783          	lw	a5,544(s1)
    8000483a:	d7e1                	beqz	a5,80004802 <pipewrite+0x3c>
    8000483c:	854e                	mv	a0,s3
    8000483e:	9b5fd0ef          	jal	800021f2 <killed>
    80004842:	f161                	bnez	a0,80004802 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004844:	2184a783          	lw	a5,536(s1)
    80004848:	21c4a703          	lw	a4,540(s1)
    8000484c:	2007879b          	addiw	a5,a5,512
    80004850:	fcf70ae3          	beq	a4,a5,80004824 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004854:	4685                	li	a3,1
    80004856:	01590633          	add	a2,s2,s5
    8000485a:	faf40593          	addi	a1,s0,-81
    8000485e:	0509b503          	ld	a0,80(s3)
    80004862:	e65fc0ef          	jal	800016c6 <copyin>
    80004866:	03650e63          	beq	a0,s6,800048a2 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000486a:	21c4a783          	lw	a5,540(s1)
    8000486e:	0017871b          	addiw	a4,a5,1
    80004872:	20e4ae23          	sw	a4,540(s1)
    80004876:	1ff7f793          	andi	a5,a5,511
    8000487a:	97a6                	add	a5,a5,s1
    8000487c:	faf44703          	lbu	a4,-81(s0)
    80004880:	00e78c23          	sb	a4,24(a5)
      i++;
    80004884:	2905                	addiw	s2,s2,1
    80004886:	b775                	j	80004832 <pipewrite+0x6c>
    80004888:	7b02                	ld	s6,32(sp)
    8000488a:	6be2                	ld	s7,24(sp)
    8000488c:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    8000488e:	21848513          	addi	a0,s1,536
    80004892:	f74fd0ef          	jal	80002006 <wakeup>
  release(&pi->lock);
    80004896:	8526                	mv	a0,s1
    80004898:	bcefc0ef          	jal	80000c66 <release>
  return i;
    8000489c:	bf95                	j	80004810 <pipewrite+0x4a>
  int i = 0;
    8000489e:	4901                	li	s2,0
    800048a0:	b7fd                	j	8000488e <pipewrite+0xc8>
    800048a2:	7b02                	ld	s6,32(sp)
    800048a4:	6be2                	ld	s7,24(sp)
    800048a6:	6c42                	ld	s8,16(sp)
    800048a8:	b7dd                	j	8000488e <pipewrite+0xc8>

00000000800048aa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800048aa:	715d                	addi	sp,sp,-80
    800048ac:	e486                	sd	ra,72(sp)
    800048ae:	e0a2                	sd	s0,64(sp)
    800048b0:	fc26                	sd	s1,56(sp)
    800048b2:	f84a                	sd	s2,48(sp)
    800048b4:	f44e                	sd	s3,40(sp)
    800048b6:	f052                	sd	s4,32(sp)
    800048b8:	ec56                	sd	s5,24(sp)
    800048ba:	0880                	addi	s0,sp,80
    800048bc:	84aa                	mv	s1,a0
    800048be:	892e                	mv	s2,a1
    800048c0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800048c2:	80cfd0ef          	jal	800018ce <myproc>
    800048c6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800048c8:	8526                	mv	a0,s1
    800048ca:	b04fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048ce:	2184a703          	lw	a4,536(s1)
    800048d2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800048d6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048da:	02f71563          	bne	a4,a5,80004904 <piperead+0x5a>
    800048de:	2244a783          	lw	a5,548(s1)
    800048e2:	cb85                	beqz	a5,80004912 <piperead+0x68>
    if(killed(pr)){
    800048e4:	8552                	mv	a0,s4
    800048e6:	90dfd0ef          	jal	800021f2 <killed>
    800048ea:	ed19                	bnez	a0,80004908 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800048ec:	85a6                	mv	a1,s1
    800048ee:	854e                	mv	a0,s3
    800048f0:	ec6fd0ef          	jal	80001fb6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048f4:	2184a703          	lw	a4,536(s1)
    800048f8:	21c4a783          	lw	a5,540(s1)
    800048fc:	fef701e3          	beq	a4,a5,800048de <piperead+0x34>
    80004900:	e85a                	sd	s6,16(sp)
    80004902:	a809                	j	80004914 <piperead+0x6a>
    80004904:	e85a                	sd	s6,16(sp)
    80004906:	a039                	j	80004914 <piperead+0x6a>
      release(&pi->lock);
    80004908:	8526                	mv	a0,s1
    8000490a:	b5cfc0ef          	jal	80000c66 <release>
      return -1;
    8000490e:	59fd                	li	s3,-1
    80004910:	a8b9                	j	8000496e <piperead+0xc4>
    80004912:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004914:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004916:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004918:	05505363          	blez	s5,8000495e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000491c:	2184a783          	lw	a5,536(s1)
    80004920:	21c4a703          	lw	a4,540(s1)
    80004924:	02f70d63          	beq	a4,a5,8000495e <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004928:	1ff7f793          	andi	a5,a5,511
    8000492c:	97a6                	add	a5,a5,s1
    8000492e:	0187c783          	lbu	a5,24(a5)
    80004932:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004936:	4685                	li	a3,1
    80004938:	fbf40613          	addi	a2,s0,-65
    8000493c:	85ca                	mv	a1,s2
    8000493e:	050a3503          	ld	a0,80(s4)
    80004942:	ca1fc0ef          	jal	800015e2 <copyout>
    80004946:	03650e63          	beq	a0,s6,80004982 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    8000494a:	2184a783          	lw	a5,536(s1)
    8000494e:	2785                	addiw	a5,a5,1
    80004950:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004954:	2985                	addiw	s3,s3,1
    80004956:	0905                	addi	s2,s2,1
    80004958:	fd3a92e3          	bne	s5,s3,8000491c <piperead+0x72>
    8000495c:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000495e:	21c48513          	addi	a0,s1,540
    80004962:	ea4fd0ef          	jal	80002006 <wakeup>
  release(&pi->lock);
    80004966:	8526                	mv	a0,s1
    80004968:	afefc0ef          	jal	80000c66 <release>
    8000496c:	6b42                	ld	s6,16(sp)
  return i;
}
    8000496e:	854e                	mv	a0,s3
    80004970:	60a6                	ld	ra,72(sp)
    80004972:	6406                	ld	s0,64(sp)
    80004974:	74e2                	ld	s1,56(sp)
    80004976:	7942                	ld	s2,48(sp)
    80004978:	79a2                	ld	s3,40(sp)
    8000497a:	7a02                	ld	s4,32(sp)
    8000497c:	6ae2                	ld	s5,24(sp)
    8000497e:	6161                	addi	sp,sp,80
    80004980:	8082                	ret
      if(i == 0)
    80004982:	fc099ee3          	bnez	s3,8000495e <piperead+0xb4>
        i = -1;
    80004986:	89aa                	mv	s3,a0
    80004988:	bfd9                	j	8000495e <piperead+0xb4>

000000008000498a <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000498a:	1141                	addi	sp,sp,-16
    8000498c:	e422                	sd	s0,8(sp)
    8000498e:	0800                	addi	s0,sp,16
    80004990:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004992:	8905                	andi	a0,a0,1
    80004994:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004996:	8b89                	andi	a5,a5,2
    80004998:	c399                	beqz	a5,8000499e <flags2perm+0x14>
      perm |= PTE_W;
    8000499a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000499e:	6422                	ld	s0,8(sp)
    800049a0:	0141                	addi	sp,sp,16
    800049a2:	8082                	ret

00000000800049a4 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    800049a4:	df010113          	addi	sp,sp,-528
    800049a8:	20113423          	sd	ra,520(sp)
    800049ac:	20813023          	sd	s0,512(sp)
    800049b0:	ffa6                	sd	s1,504(sp)
    800049b2:	fbca                	sd	s2,496(sp)
    800049b4:	0c00                	addi	s0,sp,528
    800049b6:	892a                	mv	s2,a0
    800049b8:	dea43c23          	sd	a0,-520(s0)
    800049bc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800049c0:	f0ffc0ef          	jal	800018ce <myproc>
    800049c4:	84aa                	mv	s1,a0

  begin_op();
    800049c6:	dcaff0ef          	jal	80003f90 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800049ca:	854a                	mv	a0,s2
    800049cc:	bf0ff0ef          	jal	80003dbc <namei>
    800049d0:	c931                	beqz	a0,80004a24 <kexec+0x80>
    800049d2:	f3d2                	sd	s4,480(sp)
    800049d4:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800049d6:	bd1fe0ef          	jal	800035a6 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800049da:	04000713          	li	a4,64
    800049de:	4681                	li	a3,0
    800049e0:	e5040613          	addi	a2,s0,-432
    800049e4:	4581                	li	a1,0
    800049e6:	8552                	mv	a0,s4
    800049e8:	f4ffe0ef          	jal	80003936 <readi>
    800049ec:	04000793          	li	a5,64
    800049f0:	00f51a63          	bne	a0,a5,80004a04 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800049f4:	e5042703          	lw	a4,-432(s0)
    800049f8:	464c47b7          	lui	a5,0x464c4
    800049fc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004a00:	02f70663          	beq	a4,a5,80004a2c <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004a04:	8552                	mv	a0,s4
    80004a06:	dabfe0ef          	jal	800037b0 <iunlockput>
    end_op();
    80004a0a:	df0ff0ef          	jal	80003ffa <end_op>
  }
  return -1;
    80004a0e:	557d                	li	a0,-1
    80004a10:	7a1e                	ld	s4,480(sp)
}
    80004a12:	20813083          	ld	ra,520(sp)
    80004a16:	20013403          	ld	s0,512(sp)
    80004a1a:	74fe                	ld	s1,504(sp)
    80004a1c:	795e                	ld	s2,496(sp)
    80004a1e:	21010113          	addi	sp,sp,528
    80004a22:	8082                	ret
    end_op();
    80004a24:	dd6ff0ef          	jal	80003ffa <end_op>
    return -1;
    80004a28:	557d                	li	a0,-1
    80004a2a:	b7e5                	j	80004a12 <kexec+0x6e>
    80004a2c:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004a2e:	8526                	mv	a0,s1
    80004a30:	fa5fc0ef          	jal	800019d4 <proc_pagetable>
    80004a34:	8b2a                	mv	s6,a0
    80004a36:	2c050b63          	beqz	a0,80004d0c <kexec+0x368>
    80004a3a:	f7ce                	sd	s3,488(sp)
    80004a3c:	efd6                	sd	s5,472(sp)
    80004a3e:	e7de                	sd	s7,456(sp)
    80004a40:	e3e2                	sd	s8,448(sp)
    80004a42:	ff66                	sd	s9,440(sp)
    80004a44:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a46:	e7042d03          	lw	s10,-400(s0)
    80004a4a:	e8845783          	lhu	a5,-376(s0)
    80004a4e:	12078963          	beqz	a5,80004b80 <kexec+0x1dc>
    80004a52:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004a54:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a56:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004a58:	6c85                	lui	s9,0x1
    80004a5a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004a5e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004a62:	6a85                	lui	s5,0x1
    80004a64:	a085                	j	80004ac4 <kexec+0x120>
      panic("loadseg: address should exist");
    80004a66:	00003517          	auipc	a0,0x3
    80004a6a:	b3a50513          	addi	a0,a0,-1222 # 800075a0 <etext+0x5a0>
    80004a6e:	d73fb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004a72:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004a74:	8726                	mv	a4,s1
    80004a76:	012c06bb          	addw	a3,s8,s2
    80004a7a:	4581                	li	a1,0
    80004a7c:	8552                	mv	a0,s4
    80004a7e:	eb9fe0ef          	jal	80003936 <readi>
    80004a82:	2501                	sext.w	a0,a0
    80004a84:	24a49a63          	bne	s1,a0,80004cd8 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004a88:	012a893b          	addw	s2,s5,s2
    80004a8c:	03397363          	bgeu	s2,s3,80004ab2 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004a90:	02091593          	slli	a1,s2,0x20
    80004a94:	9181                	srli	a1,a1,0x20
    80004a96:	95de                	add	a1,a1,s7
    80004a98:	855a                	mv	a0,s6
    80004a9a:	d16fc0ef          	jal	80000fb0 <walkaddr>
    80004a9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004aa0:	d179                	beqz	a0,80004a66 <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004aa2:	412984bb          	subw	s1,s3,s2
    80004aa6:	0004879b          	sext.w	a5,s1
    80004aaa:	fcfcf4e3          	bgeu	s9,a5,80004a72 <kexec+0xce>
    80004aae:	84d6                	mv	s1,s5
    80004ab0:	b7c9                	j	80004a72 <kexec+0xce>
    sz = sz1;
    80004ab2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ab6:	2d85                	addiw	s11,s11,1
    80004ab8:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004abc:	e8845783          	lhu	a5,-376(s0)
    80004ac0:	08fdd063          	bge	s11,a5,80004b40 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ac4:	2d01                	sext.w	s10,s10
    80004ac6:	03800713          	li	a4,56
    80004aca:	86ea                	mv	a3,s10
    80004acc:	e1840613          	addi	a2,s0,-488
    80004ad0:	4581                	li	a1,0
    80004ad2:	8552                	mv	a0,s4
    80004ad4:	e63fe0ef          	jal	80003936 <readi>
    80004ad8:	03800793          	li	a5,56
    80004adc:	1cf51663          	bne	a0,a5,80004ca8 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004ae0:	e1842783          	lw	a5,-488(s0)
    80004ae4:	4705                	li	a4,1
    80004ae6:	fce798e3          	bne	a5,a4,80004ab6 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004aea:	e4043483          	ld	s1,-448(s0)
    80004aee:	e3843783          	ld	a5,-456(s0)
    80004af2:	1af4ef63          	bltu	s1,a5,80004cb0 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004af6:	e2843783          	ld	a5,-472(s0)
    80004afa:	94be                	add	s1,s1,a5
    80004afc:	1af4ee63          	bltu	s1,a5,80004cb8 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004b00:	df043703          	ld	a4,-528(s0)
    80004b04:	8ff9                	and	a5,a5,a4
    80004b06:	1a079d63          	bnez	a5,80004cc0 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b0a:	e1c42503          	lw	a0,-484(s0)
    80004b0e:	e7dff0ef          	jal	8000498a <flags2perm>
    80004b12:	86aa                	mv	a3,a0
    80004b14:	8626                	mv	a2,s1
    80004b16:	85ca                	mv	a1,s2
    80004b18:	855a                	mv	a0,s6
    80004b1a:	f6efc0ef          	jal	80001288 <uvmalloc>
    80004b1e:	e0a43423          	sd	a0,-504(s0)
    80004b22:	1a050363          	beqz	a0,80004cc8 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004b26:	e2843b83          	ld	s7,-472(s0)
    80004b2a:	e2042c03          	lw	s8,-480(s0)
    80004b2e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004b32:	00098463          	beqz	s3,80004b3a <kexec+0x196>
    80004b36:	4901                	li	s2,0
    80004b38:	bfa1                	j	80004a90 <kexec+0xec>
    sz = sz1;
    80004b3a:	e0843903          	ld	s2,-504(s0)
    80004b3e:	bfa5                	j	80004ab6 <kexec+0x112>
    80004b40:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004b42:	8552                	mv	a0,s4
    80004b44:	c6dfe0ef          	jal	800037b0 <iunlockput>
  end_op();
    80004b48:	cb2ff0ef          	jal	80003ffa <end_op>
  p = myproc();
    80004b4c:	d83fc0ef          	jal	800018ce <myproc>
    80004b50:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004b52:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004b56:	6985                	lui	s3,0x1
    80004b58:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004b5a:	99ca                	add	s3,s3,s2
    80004b5c:	77fd                	lui	a5,0xfffff
    80004b5e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004b62:	4691                	li	a3,4
    80004b64:	6609                	lui	a2,0x2
    80004b66:	964e                	add	a2,a2,s3
    80004b68:	85ce                	mv	a1,s3
    80004b6a:	855a                	mv	a0,s6
    80004b6c:	f1cfc0ef          	jal	80001288 <uvmalloc>
    80004b70:	892a                	mv	s2,a0
    80004b72:	e0a43423          	sd	a0,-504(s0)
    80004b76:	e519                	bnez	a0,80004b84 <kexec+0x1e0>
  if(pagetable)
    80004b78:	e1343423          	sd	s3,-504(s0)
    80004b7c:	4a01                	li	s4,0
    80004b7e:	aab1                	j	80004cda <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004b80:	4901                	li	s2,0
    80004b82:	b7c1                	j	80004b42 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004b84:	75f9                	lui	a1,0xffffe
    80004b86:	95aa                	add	a1,a1,a0
    80004b88:	855a                	mv	a0,s6
    80004b8a:	8d5fc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004b8e:	7bfd                	lui	s7,0xfffff
    80004b90:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004b92:	e0043783          	ld	a5,-512(s0)
    80004b96:	6388                	ld	a0,0(a5)
    80004b98:	cd39                	beqz	a0,80004bf6 <kexec+0x252>
    80004b9a:	e9040993          	addi	s3,s0,-368
    80004b9e:	f9040c13          	addi	s8,s0,-112
    80004ba2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ba4:	a6efc0ef          	jal	80000e12 <strlen>
    80004ba8:	0015079b          	addiw	a5,a0,1
    80004bac:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004bb0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004bb4:	11796e63          	bltu	s2,s7,80004cd0 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004bb8:	e0043d03          	ld	s10,-512(s0)
    80004bbc:	000d3a03          	ld	s4,0(s10)
    80004bc0:	8552                	mv	a0,s4
    80004bc2:	a50fc0ef          	jal	80000e12 <strlen>
    80004bc6:	0015069b          	addiw	a3,a0,1
    80004bca:	8652                	mv	a2,s4
    80004bcc:	85ca                	mv	a1,s2
    80004bce:	855a                	mv	a0,s6
    80004bd0:	a13fc0ef          	jal	800015e2 <copyout>
    80004bd4:	10054063          	bltz	a0,80004cd4 <kexec+0x330>
    ustack[argc] = sp;
    80004bd8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004bdc:	0485                	addi	s1,s1,1
    80004bde:	008d0793          	addi	a5,s10,8
    80004be2:	e0f43023          	sd	a5,-512(s0)
    80004be6:	008d3503          	ld	a0,8(s10)
    80004bea:	c909                	beqz	a0,80004bfc <kexec+0x258>
    if(argc >= MAXARG)
    80004bec:	09a1                	addi	s3,s3,8
    80004bee:	fb899be3          	bne	s3,s8,80004ba4 <kexec+0x200>
  ip = 0;
    80004bf2:	4a01                	li	s4,0
    80004bf4:	a0dd                	j	80004cda <kexec+0x336>
  sp = sz;
    80004bf6:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004bfa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004bfc:	00349793          	slli	a5,s1,0x3
    80004c00:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcc08>
    80004c04:	97a2                	add	a5,a5,s0
    80004c06:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004c0a:	00148693          	addi	a3,s1,1
    80004c0e:	068e                	slli	a3,a3,0x3
    80004c10:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004c14:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004c18:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004c1c:	f5796ee3          	bltu	s2,s7,80004b78 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004c20:	e9040613          	addi	a2,s0,-368
    80004c24:	85ca                	mv	a1,s2
    80004c26:	855a                	mv	a0,s6
    80004c28:	9bbfc0ef          	jal	800015e2 <copyout>
    80004c2c:	0e054263          	bltz	a0,80004d10 <kexec+0x36c>
  p->trapframe->a1 = sp;
    80004c30:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004c34:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004c38:	df843783          	ld	a5,-520(s0)
    80004c3c:	0007c703          	lbu	a4,0(a5)
    80004c40:	cf11                	beqz	a4,80004c5c <kexec+0x2b8>
    80004c42:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004c44:	02f00693          	li	a3,47
    80004c48:	a039                	j	80004c56 <kexec+0x2b2>
      last = s+1;
    80004c4a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004c4e:	0785                	addi	a5,a5,1
    80004c50:	fff7c703          	lbu	a4,-1(a5)
    80004c54:	c701                	beqz	a4,80004c5c <kexec+0x2b8>
    if(*s == '/')
    80004c56:	fed71ce3          	bne	a4,a3,80004c4e <kexec+0x2aa>
    80004c5a:	bfc5                	j	80004c4a <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004c5c:	4641                	li	a2,16
    80004c5e:	df843583          	ld	a1,-520(s0)
    80004c62:	158a8513          	addi	a0,s5,344
    80004c66:	97afc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004c6a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004c6e:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004c72:	e0843783          	ld	a5,-504(s0)
    80004c76:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004c7a:	058ab783          	ld	a5,88(s5)
    80004c7e:	e6843703          	ld	a4,-408(s0)
    80004c82:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004c84:	058ab783          	ld	a5,88(s5)
    80004c88:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004c8c:	85e6                	mv	a1,s9
    80004c8e:	dcbfc0ef          	jal	80001a58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004c92:	0004851b          	sext.w	a0,s1
    80004c96:	79be                	ld	s3,488(sp)
    80004c98:	7a1e                	ld	s4,480(sp)
    80004c9a:	6afe                	ld	s5,472(sp)
    80004c9c:	6b5e                	ld	s6,464(sp)
    80004c9e:	6bbe                	ld	s7,456(sp)
    80004ca0:	6c1e                	ld	s8,448(sp)
    80004ca2:	7cfa                	ld	s9,440(sp)
    80004ca4:	7d5a                	ld	s10,432(sp)
    80004ca6:	b3b5                	j	80004a12 <kexec+0x6e>
    80004ca8:	e1243423          	sd	s2,-504(s0)
    80004cac:	7dba                	ld	s11,424(sp)
    80004cae:	a035                	j	80004cda <kexec+0x336>
    80004cb0:	e1243423          	sd	s2,-504(s0)
    80004cb4:	7dba                	ld	s11,424(sp)
    80004cb6:	a015                	j	80004cda <kexec+0x336>
    80004cb8:	e1243423          	sd	s2,-504(s0)
    80004cbc:	7dba                	ld	s11,424(sp)
    80004cbe:	a831                	j	80004cda <kexec+0x336>
    80004cc0:	e1243423          	sd	s2,-504(s0)
    80004cc4:	7dba                	ld	s11,424(sp)
    80004cc6:	a811                	j	80004cda <kexec+0x336>
    80004cc8:	e1243423          	sd	s2,-504(s0)
    80004ccc:	7dba                	ld	s11,424(sp)
    80004cce:	a031                	j	80004cda <kexec+0x336>
  ip = 0;
    80004cd0:	4a01                	li	s4,0
    80004cd2:	a021                	j	80004cda <kexec+0x336>
    80004cd4:	4a01                	li	s4,0
  if(pagetable)
    80004cd6:	a011                	j	80004cda <kexec+0x336>
    80004cd8:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004cda:	e0843583          	ld	a1,-504(s0)
    80004cde:	855a                	mv	a0,s6
    80004ce0:	d79fc0ef          	jal	80001a58 <proc_freepagetable>
  return -1;
    80004ce4:	557d                	li	a0,-1
  if(ip){
    80004ce6:	000a1b63          	bnez	s4,80004cfc <kexec+0x358>
    80004cea:	79be                	ld	s3,488(sp)
    80004cec:	7a1e                	ld	s4,480(sp)
    80004cee:	6afe                	ld	s5,472(sp)
    80004cf0:	6b5e                	ld	s6,464(sp)
    80004cf2:	6bbe                	ld	s7,456(sp)
    80004cf4:	6c1e                	ld	s8,448(sp)
    80004cf6:	7cfa                	ld	s9,440(sp)
    80004cf8:	7d5a                	ld	s10,432(sp)
    80004cfa:	bb21                	j	80004a12 <kexec+0x6e>
    80004cfc:	79be                	ld	s3,488(sp)
    80004cfe:	6afe                	ld	s5,472(sp)
    80004d00:	6b5e                	ld	s6,464(sp)
    80004d02:	6bbe                	ld	s7,456(sp)
    80004d04:	6c1e                	ld	s8,448(sp)
    80004d06:	7cfa                	ld	s9,440(sp)
    80004d08:	7d5a                	ld	s10,432(sp)
    80004d0a:	b9ed                	j	80004a04 <kexec+0x60>
    80004d0c:	6b5e                	ld	s6,464(sp)
    80004d0e:	b9dd                	j	80004a04 <kexec+0x60>
  sz = sz1;
    80004d10:	e0843983          	ld	s3,-504(s0)
    80004d14:	b595                	j	80004b78 <kexec+0x1d4>

0000000080004d16 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004d16:	7179                	addi	sp,sp,-48
    80004d18:	f406                	sd	ra,40(sp)
    80004d1a:	f022                	sd	s0,32(sp)
    80004d1c:	ec26                	sd	s1,24(sp)
    80004d1e:	e84a                	sd	s2,16(sp)
    80004d20:	1800                	addi	s0,sp,48
    80004d22:	892e                	mv	s2,a1
    80004d24:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004d26:	fdc40593          	addi	a1,s0,-36
    80004d2a:	d51fd0ef          	jal	80002a7a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004d2e:	fdc42703          	lw	a4,-36(s0)
    80004d32:	47bd                	li	a5,15
    80004d34:	02e7e963          	bltu	a5,a4,80004d66 <argfd+0x50>
    80004d38:	b97fc0ef          	jal	800018ce <myproc>
    80004d3c:	fdc42703          	lw	a4,-36(s0)
    80004d40:	01a70793          	addi	a5,a4,26
    80004d44:	078e                	slli	a5,a5,0x3
    80004d46:	953e                	add	a0,a0,a5
    80004d48:	611c                	ld	a5,0(a0)
    80004d4a:	c385                	beqz	a5,80004d6a <argfd+0x54>
    return -1;
  if(pfd)
    80004d4c:	00090463          	beqz	s2,80004d54 <argfd+0x3e>
    *pfd = fd;
    80004d50:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004d54:	4501                	li	a0,0
  if(pf)
    80004d56:	c091                	beqz	s1,80004d5a <argfd+0x44>
    *pf = f;
    80004d58:	e09c                	sd	a5,0(s1)
}
    80004d5a:	70a2                	ld	ra,40(sp)
    80004d5c:	7402                	ld	s0,32(sp)
    80004d5e:	64e2                	ld	s1,24(sp)
    80004d60:	6942                	ld	s2,16(sp)
    80004d62:	6145                	addi	sp,sp,48
    80004d64:	8082                	ret
    return -1;
    80004d66:	557d                	li	a0,-1
    80004d68:	bfcd                	j	80004d5a <argfd+0x44>
    80004d6a:	557d                	li	a0,-1
    80004d6c:	b7fd                	j	80004d5a <argfd+0x44>

0000000080004d6e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004d6e:	1101                	addi	sp,sp,-32
    80004d70:	ec06                	sd	ra,24(sp)
    80004d72:	e822                	sd	s0,16(sp)
    80004d74:	e426                	sd	s1,8(sp)
    80004d76:	1000                	addi	s0,sp,32
    80004d78:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004d7a:	b55fc0ef          	jal	800018ce <myproc>
    80004d7e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004d80:	0d050793          	addi	a5,a0,208
    80004d84:	4501                	li	a0,0
    80004d86:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004d88:	6398                	ld	a4,0(a5)
    80004d8a:	cb19                	beqz	a4,80004da0 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004d8c:	2505                	addiw	a0,a0,1
    80004d8e:	07a1                	addi	a5,a5,8
    80004d90:	fed51ce3          	bne	a0,a3,80004d88 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004d94:	557d                	li	a0,-1
}
    80004d96:	60e2                	ld	ra,24(sp)
    80004d98:	6442                	ld	s0,16(sp)
    80004d9a:	64a2                	ld	s1,8(sp)
    80004d9c:	6105                	addi	sp,sp,32
    80004d9e:	8082                	ret
      p->ofile[fd] = f;
    80004da0:	01a50793          	addi	a5,a0,26
    80004da4:	078e                	slli	a5,a5,0x3
    80004da6:	963e                	add	a2,a2,a5
    80004da8:	e204                	sd	s1,0(a2)
      return fd;
    80004daa:	b7f5                	j	80004d96 <fdalloc+0x28>

0000000080004dac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004dac:	715d                	addi	sp,sp,-80
    80004dae:	e486                	sd	ra,72(sp)
    80004db0:	e0a2                	sd	s0,64(sp)
    80004db2:	fc26                	sd	s1,56(sp)
    80004db4:	f84a                	sd	s2,48(sp)
    80004db6:	f44e                	sd	s3,40(sp)
    80004db8:	ec56                	sd	s5,24(sp)
    80004dba:	e85a                	sd	s6,16(sp)
    80004dbc:	0880                	addi	s0,sp,80
    80004dbe:	8b2e                	mv	s6,a1
    80004dc0:	89b2                	mv	s3,a2
    80004dc2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004dc4:	fb040593          	addi	a1,s0,-80
    80004dc8:	80eff0ef          	jal	80003dd6 <nameiparent>
    80004dcc:	84aa                	mv	s1,a0
    80004dce:	10050a63          	beqz	a0,80004ee2 <create+0x136>
    return 0;

  ilock(dp);
    80004dd2:	fd4fe0ef          	jal	800035a6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004dd6:	4601                	li	a2,0
    80004dd8:	fb040593          	addi	a1,s0,-80
    80004ddc:	8526                	mv	a0,s1
    80004dde:	d79fe0ef          	jal	80003b56 <dirlookup>
    80004de2:	8aaa                	mv	s5,a0
    80004de4:	c129                	beqz	a0,80004e26 <create+0x7a>
    iunlockput(dp);
    80004de6:	8526                	mv	a0,s1
    80004de8:	9c9fe0ef          	jal	800037b0 <iunlockput>
    ilock(ip);
    80004dec:	8556                	mv	a0,s5
    80004dee:	fb8fe0ef          	jal	800035a6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004df2:	4789                	li	a5,2
    80004df4:	02fb1463          	bne	s6,a5,80004e1c <create+0x70>
    80004df8:	044ad783          	lhu	a5,68(s5)
    80004dfc:	37f9                	addiw	a5,a5,-2
    80004dfe:	17c2                	slli	a5,a5,0x30
    80004e00:	93c1                	srli	a5,a5,0x30
    80004e02:	4705                	li	a4,1
    80004e04:	00f76c63          	bltu	a4,a5,80004e1c <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004e08:	8556                	mv	a0,s5
    80004e0a:	60a6                	ld	ra,72(sp)
    80004e0c:	6406                	ld	s0,64(sp)
    80004e0e:	74e2                	ld	s1,56(sp)
    80004e10:	7942                	ld	s2,48(sp)
    80004e12:	79a2                	ld	s3,40(sp)
    80004e14:	6ae2                	ld	s5,24(sp)
    80004e16:	6b42                	ld	s6,16(sp)
    80004e18:	6161                	addi	sp,sp,80
    80004e1a:	8082                	ret
    iunlockput(ip);
    80004e1c:	8556                	mv	a0,s5
    80004e1e:	993fe0ef          	jal	800037b0 <iunlockput>
    return 0;
    80004e22:	4a81                	li	s5,0
    80004e24:	b7d5                	j	80004e08 <create+0x5c>
    80004e26:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004e28:	85da                	mv	a1,s6
    80004e2a:	4088                	lw	a0,0(s1)
    80004e2c:	e0afe0ef          	jal	80003436 <ialloc>
    80004e30:	8a2a                	mv	s4,a0
    80004e32:	cd15                	beqz	a0,80004e6e <create+0xc2>
  ilock(ip);
    80004e34:	f72fe0ef          	jal	800035a6 <ilock>
  ip->major = major;
    80004e38:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004e3c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004e40:	4905                	li	s2,1
    80004e42:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004e46:	8552                	mv	a0,s4
    80004e48:	eaafe0ef          	jal	800034f2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004e4c:	032b0763          	beq	s6,s2,80004e7a <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004e50:	004a2603          	lw	a2,4(s4)
    80004e54:	fb040593          	addi	a1,s0,-80
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ec9fe0ef          	jal	80003d22 <dirlink>
    80004e5e:	06054563          	bltz	a0,80004ec8 <create+0x11c>
  iunlockput(dp);
    80004e62:	8526                	mv	a0,s1
    80004e64:	94dfe0ef          	jal	800037b0 <iunlockput>
  return ip;
    80004e68:	8ad2                	mv	s5,s4
    80004e6a:	7a02                	ld	s4,32(sp)
    80004e6c:	bf71                	j	80004e08 <create+0x5c>
    iunlockput(dp);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	941fe0ef          	jal	800037b0 <iunlockput>
    return 0;
    80004e74:	8ad2                	mv	s5,s4
    80004e76:	7a02                	ld	s4,32(sp)
    80004e78:	bf41                	j	80004e08 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004e7a:	004a2603          	lw	a2,4(s4)
    80004e7e:	00002597          	auipc	a1,0x2
    80004e82:	74258593          	addi	a1,a1,1858 # 800075c0 <etext+0x5c0>
    80004e86:	8552                	mv	a0,s4
    80004e88:	e9bfe0ef          	jal	80003d22 <dirlink>
    80004e8c:	02054e63          	bltz	a0,80004ec8 <create+0x11c>
    80004e90:	40d0                	lw	a2,4(s1)
    80004e92:	00002597          	auipc	a1,0x2
    80004e96:	73658593          	addi	a1,a1,1846 # 800075c8 <etext+0x5c8>
    80004e9a:	8552                	mv	a0,s4
    80004e9c:	e87fe0ef          	jal	80003d22 <dirlink>
    80004ea0:	02054463          	bltz	a0,80004ec8 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ea4:	004a2603          	lw	a2,4(s4)
    80004ea8:	fb040593          	addi	a1,s0,-80
    80004eac:	8526                	mv	a0,s1
    80004eae:	e75fe0ef          	jal	80003d22 <dirlink>
    80004eb2:	00054b63          	bltz	a0,80004ec8 <create+0x11c>
    dp->nlink++;  // for ".."
    80004eb6:	04a4d783          	lhu	a5,74(s1)
    80004eba:	2785                	addiw	a5,a5,1
    80004ebc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	e30fe0ef          	jal	800034f2 <iupdate>
    80004ec6:	bf71                	j	80004e62 <create+0xb6>
  ip->nlink = 0;
    80004ec8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004ecc:	8552                	mv	a0,s4
    80004ece:	e24fe0ef          	jal	800034f2 <iupdate>
  iunlockput(ip);
    80004ed2:	8552                	mv	a0,s4
    80004ed4:	8ddfe0ef          	jal	800037b0 <iunlockput>
  iunlockput(dp);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	8d7fe0ef          	jal	800037b0 <iunlockput>
  return 0;
    80004ede:	7a02                	ld	s4,32(sp)
    80004ee0:	b725                	j	80004e08 <create+0x5c>
    return 0;
    80004ee2:	8aaa                	mv	s5,a0
    80004ee4:	b715                	j	80004e08 <create+0x5c>

0000000080004ee6 <sys_dup>:
{
    80004ee6:	7179                	addi	sp,sp,-48
    80004ee8:	f406                	sd	ra,40(sp)
    80004eea:	f022                	sd	s0,32(sp)
    80004eec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004eee:	fd840613          	addi	a2,s0,-40
    80004ef2:	4581                	li	a1,0
    80004ef4:	4501                	li	a0,0
    80004ef6:	e21ff0ef          	jal	80004d16 <argfd>
    return -1;
    80004efa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004efc:	02054363          	bltz	a0,80004f22 <sys_dup+0x3c>
    80004f00:	ec26                	sd	s1,24(sp)
    80004f02:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004f04:	fd843903          	ld	s2,-40(s0)
    80004f08:	854a                	mv	a0,s2
    80004f0a:	e65ff0ef          	jal	80004d6e <fdalloc>
    80004f0e:	84aa                	mv	s1,a0
    return -1;
    80004f10:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004f12:	00054d63          	bltz	a0,80004f2c <sys_dup+0x46>
  filedup(f);
    80004f16:	854a                	mv	a0,s2
    80004f18:	c3eff0ef          	jal	80004356 <filedup>
  return fd;
    80004f1c:	87a6                	mv	a5,s1
    80004f1e:	64e2                	ld	s1,24(sp)
    80004f20:	6942                	ld	s2,16(sp)
}
    80004f22:	853e                	mv	a0,a5
    80004f24:	70a2                	ld	ra,40(sp)
    80004f26:	7402                	ld	s0,32(sp)
    80004f28:	6145                	addi	sp,sp,48
    80004f2a:	8082                	ret
    80004f2c:	64e2                	ld	s1,24(sp)
    80004f2e:	6942                	ld	s2,16(sp)
    80004f30:	bfcd                	j	80004f22 <sys_dup+0x3c>

0000000080004f32 <sys_read>:
{
    80004f32:	7179                	addi	sp,sp,-48
    80004f34:	f406                	sd	ra,40(sp)
    80004f36:	f022                	sd	s0,32(sp)
    80004f38:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004f3a:	fd840593          	addi	a1,s0,-40
    80004f3e:	4505                	li	a0,1
    80004f40:	b57fd0ef          	jal	80002a96 <argaddr>
  argint(2, &n);
    80004f44:	fe440593          	addi	a1,s0,-28
    80004f48:	4509                	li	a0,2
    80004f4a:	b31fd0ef          	jal	80002a7a <argint>
  if(argfd(0, 0, &f) < 0)
    80004f4e:	fe840613          	addi	a2,s0,-24
    80004f52:	4581                	li	a1,0
    80004f54:	4501                	li	a0,0
    80004f56:	dc1ff0ef          	jal	80004d16 <argfd>
    80004f5a:	87aa                	mv	a5,a0
    return -1;
    80004f5c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004f5e:	0007ca63          	bltz	a5,80004f72 <sys_read+0x40>
  return fileread(f, p, n);
    80004f62:	fe442603          	lw	a2,-28(s0)
    80004f66:	fd843583          	ld	a1,-40(s0)
    80004f6a:	fe843503          	ld	a0,-24(s0)
    80004f6e:	d4eff0ef          	jal	800044bc <fileread>
}
    80004f72:	70a2                	ld	ra,40(sp)
    80004f74:	7402                	ld	s0,32(sp)
    80004f76:	6145                	addi	sp,sp,48
    80004f78:	8082                	ret

0000000080004f7a <sys_write>:
{
    80004f7a:	7179                	addi	sp,sp,-48
    80004f7c:	f406                	sd	ra,40(sp)
    80004f7e:	f022                	sd	s0,32(sp)
    80004f80:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004f82:	fd840593          	addi	a1,s0,-40
    80004f86:	4505                	li	a0,1
    80004f88:	b0ffd0ef          	jal	80002a96 <argaddr>
  argint(2, &n);
    80004f8c:	fe440593          	addi	a1,s0,-28
    80004f90:	4509                	li	a0,2
    80004f92:	ae9fd0ef          	jal	80002a7a <argint>
  if(argfd(0, 0, &f) < 0)
    80004f96:	fe840613          	addi	a2,s0,-24
    80004f9a:	4581                	li	a1,0
    80004f9c:	4501                	li	a0,0
    80004f9e:	d79ff0ef          	jal	80004d16 <argfd>
    80004fa2:	87aa                	mv	a5,a0
    return -1;
    80004fa4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004fa6:	0007ca63          	bltz	a5,80004fba <sys_write+0x40>
  return filewrite(f, p, n);
    80004faa:	fe442603          	lw	a2,-28(s0)
    80004fae:	fd843583          	ld	a1,-40(s0)
    80004fb2:	fe843503          	ld	a0,-24(s0)
    80004fb6:	dc4ff0ef          	jal	8000457a <filewrite>
}
    80004fba:	70a2                	ld	ra,40(sp)
    80004fbc:	7402                	ld	s0,32(sp)
    80004fbe:	6145                	addi	sp,sp,48
    80004fc0:	8082                	ret

0000000080004fc2 <sys_close>:
{
    80004fc2:	1101                	addi	sp,sp,-32
    80004fc4:	ec06                	sd	ra,24(sp)
    80004fc6:	e822                	sd	s0,16(sp)
    80004fc8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004fca:	fe040613          	addi	a2,s0,-32
    80004fce:	fec40593          	addi	a1,s0,-20
    80004fd2:	4501                	li	a0,0
    80004fd4:	d43ff0ef          	jal	80004d16 <argfd>
    return -1;
    80004fd8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004fda:	02054063          	bltz	a0,80004ffa <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004fde:	8f1fc0ef          	jal	800018ce <myproc>
    80004fe2:	fec42783          	lw	a5,-20(s0)
    80004fe6:	07e9                	addi	a5,a5,26
    80004fe8:	078e                	slli	a5,a5,0x3
    80004fea:	953e                	add	a0,a0,a5
    80004fec:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004ff0:	fe043503          	ld	a0,-32(s0)
    80004ff4:	ba8ff0ef          	jal	8000439c <fileclose>
  return 0;
    80004ff8:	4781                	li	a5,0
}
    80004ffa:	853e                	mv	a0,a5
    80004ffc:	60e2                	ld	ra,24(sp)
    80004ffe:	6442                	ld	s0,16(sp)
    80005000:	6105                	addi	sp,sp,32
    80005002:	8082                	ret

0000000080005004 <sys_fstat>:
{
    80005004:	1101                	addi	sp,sp,-32
    80005006:	ec06                	sd	ra,24(sp)
    80005008:	e822                	sd	s0,16(sp)
    8000500a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000500c:	fe040593          	addi	a1,s0,-32
    80005010:	4505                	li	a0,1
    80005012:	a85fd0ef          	jal	80002a96 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005016:	fe840613          	addi	a2,s0,-24
    8000501a:	4581                	li	a1,0
    8000501c:	4501                	li	a0,0
    8000501e:	cf9ff0ef          	jal	80004d16 <argfd>
    80005022:	87aa                	mv	a5,a0
    return -1;
    80005024:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005026:	0007c863          	bltz	a5,80005036 <sys_fstat+0x32>
  return filestat(f, st);
    8000502a:	fe043583          	ld	a1,-32(s0)
    8000502e:	fe843503          	ld	a0,-24(s0)
    80005032:	c2cff0ef          	jal	8000445e <filestat>
}
    80005036:	60e2                	ld	ra,24(sp)
    80005038:	6442                	ld	s0,16(sp)
    8000503a:	6105                	addi	sp,sp,32
    8000503c:	8082                	ret

000000008000503e <sys_link>:
{
    8000503e:	7169                	addi	sp,sp,-304
    80005040:	f606                	sd	ra,296(sp)
    80005042:	f222                	sd	s0,288(sp)
    80005044:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005046:	08000613          	li	a2,128
    8000504a:	ed040593          	addi	a1,s0,-304
    8000504e:	4501                	li	a0,0
    80005050:	a77fd0ef          	jal	80002ac6 <argstr>
    return -1;
    80005054:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005056:	0c054e63          	bltz	a0,80005132 <sys_link+0xf4>
    8000505a:	08000613          	li	a2,128
    8000505e:	f5040593          	addi	a1,s0,-176
    80005062:	4505                	li	a0,1
    80005064:	a63fd0ef          	jal	80002ac6 <argstr>
    return -1;
    80005068:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000506a:	0c054463          	bltz	a0,80005132 <sys_link+0xf4>
    8000506e:	ee26                	sd	s1,280(sp)
  begin_op();
    80005070:	f21fe0ef          	jal	80003f90 <begin_op>
  if((ip = namei(old)) == 0){
    80005074:	ed040513          	addi	a0,s0,-304
    80005078:	d45fe0ef          	jal	80003dbc <namei>
    8000507c:	84aa                	mv	s1,a0
    8000507e:	c53d                	beqz	a0,800050ec <sys_link+0xae>
  ilock(ip);
    80005080:	d26fe0ef          	jal	800035a6 <ilock>
  if(ip->type == T_DIR){
    80005084:	04449703          	lh	a4,68(s1)
    80005088:	4785                	li	a5,1
    8000508a:	06f70663          	beq	a4,a5,800050f6 <sys_link+0xb8>
    8000508e:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005090:	04a4d783          	lhu	a5,74(s1)
    80005094:	2785                	addiw	a5,a5,1
    80005096:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000509a:	8526                	mv	a0,s1
    8000509c:	c56fe0ef          	jal	800034f2 <iupdate>
  iunlock(ip);
    800050a0:	8526                	mv	a0,s1
    800050a2:	db2fe0ef          	jal	80003654 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800050a6:	fd040593          	addi	a1,s0,-48
    800050aa:	f5040513          	addi	a0,s0,-176
    800050ae:	d29fe0ef          	jal	80003dd6 <nameiparent>
    800050b2:	892a                	mv	s2,a0
    800050b4:	cd21                	beqz	a0,8000510c <sys_link+0xce>
  ilock(dp);
    800050b6:	cf0fe0ef          	jal	800035a6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800050ba:	00092703          	lw	a4,0(s2)
    800050be:	409c                	lw	a5,0(s1)
    800050c0:	04f71363          	bne	a4,a5,80005106 <sys_link+0xc8>
    800050c4:	40d0                	lw	a2,4(s1)
    800050c6:	fd040593          	addi	a1,s0,-48
    800050ca:	854a                	mv	a0,s2
    800050cc:	c57fe0ef          	jal	80003d22 <dirlink>
    800050d0:	02054b63          	bltz	a0,80005106 <sys_link+0xc8>
  iunlockput(dp);
    800050d4:	854a                	mv	a0,s2
    800050d6:	edafe0ef          	jal	800037b0 <iunlockput>
  iput(ip);
    800050da:	8526                	mv	a0,s1
    800050dc:	e4cfe0ef          	jal	80003728 <iput>
  end_op();
    800050e0:	f1bfe0ef          	jal	80003ffa <end_op>
  return 0;
    800050e4:	4781                	li	a5,0
    800050e6:	64f2                	ld	s1,280(sp)
    800050e8:	6952                	ld	s2,272(sp)
    800050ea:	a0a1                	j	80005132 <sys_link+0xf4>
    end_op();
    800050ec:	f0ffe0ef          	jal	80003ffa <end_op>
    return -1;
    800050f0:	57fd                	li	a5,-1
    800050f2:	64f2                	ld	s1,280(sp)
    800050f4:	a83d                	j	80005132 <sys_link+0xf4>
    iunlockput(ip);
    800050f6:	8526                	mv	a0,s1
    800050f8:	eb8fe0ef          	jal	800037b0 <iunlockput>
    end_op();
    800050fc:	efffe0ef          	jal	80003ffa <end_op>
    return -1;
    80005100:	57fd                	li	a5,-1
    80005102:	64f2                	ld	s1,280(sp)
    80005104:	a03d                	j	80005132 <sys_link+0xf4>
    iunlockput(dp);
    80005106:	854a                	mv	a0,s2
    80005108:	ea8fe0ef          	jal	800037b0 <iunlockput>
  ilock(ip);
    8000510c:	8526                	mv	a0,s1
    8000510e:	c98fe0ef          	jal	800035a6 <ilock>
  ip->nlink--;
    80005112:	04a4d783          	lhu	a5,74(s1)
    80005116:	37fd                	addiw	a5,a5,-1
    80005118:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000511c:	8526                	mv	a0,s1
    8000511e:	bd4fe0ef          	jal	800034f2 <iupdate>
  iunlockput(ip);
    80005122:	8526                	mv	a0,s1
    80005124:	e8cfe0ef          	jal	800037b0 <iunlockput>
  end_op();
    80005128:	ed3fe0ef          	jal	80003ffa <end_op>
  return -1;
    8000512c:	57fd                	li	a5,-1
    8000512e:	64f2                	ld	s1,280(sp)
    80005130:	6952                	ld	s2,272(sp)
}
    80005132:	853e                	mv	a0,a5
    80005134:	70b2                	ld	ra,296(sp)
    80005136:	7412                	ld	s0,288(sp)
    80005138:	6155                	addi	sp,sp,304
    8000513a:	8082                	ret

000000008000513c <sys_unlink>:
{
    8000513c:	7151                	addi	sp,sp,-240
    8000513e:	f586                	sd	ra,232(sp)
    80005140:	f1a2                	sd	s0,224(sp)
    80005142:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005144:	08000613          	li	a2,128
    80005148:	f3040593          	addi	a1,s0,-208
    8000514c:	4501                	li	a0,0
    8000514e:	979fd0ef          	jal	80002ac6 <argstr>
    80005152:	16054063          	bltz	a0,800052b2 <sys_unlink+0x176>
    80005156:	eda6                	sd	s1,216(sp)
  begin_op();
    80005158:	e39fe0ef          	jal	80003f90 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000515c:	fb040593          	addi	a1,s0,-80
    80005160:	f3040513          	addi	a0,s0,-208
    80005164:	c73fe0ef          	jal	80003dd6 <nameiparent>
    80005168:	84aa                	mv	s1,a0
    8000516a:	c945                	beqz	a0,8000521a <sys_unlink+0xde>
  ilock(dp);
    8000516c:	c3afe0ef          	jal	800035a6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005170:	00002597          	auipc	a1,0x2
    80005174:	45058593          	addi	a1,a1,1104 # 800075c0 <etext+0x5c0>
    80005178:	fb040513          	addi	a0,s0,-80
    8000517c:	9c5fe0ef          	jal	80003b40 <namecmp>
    80005180:	10050e63          	beqz	a0,8000529c <sys_unlink+0x160>
    80005184:	00002597          	auipc	a1,0x2
    80005188:	44458593          	addi	a1,a1,1092 # 800075c8 <etext+0x5c8>
    8000518c:	fb040513          	addi	a0,s0,-80
    80005190:	9b1fe0ef          	jal	80003b40 <namecmp>
    80005194:	10050463          	beqz	a0,8000529c <sys_unlink+0x160>
    80005198:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000519a:	f2c40613          	addi	a2,s0,-212
    8000519e:	fb040593          	addi	a1,s0,-80
    800051a2:	8526                	mv	a0,s1
    800051a4:	9b3fe0ef          	jal	80003b56 <dirlookup>
    800051a8:	892a                	mv	s2,a0
    800051aa:	0e050863          	beqz	a0,8000529a <sys_unlink+0x15e>
  ilock(ip);
    800051ae:	bf8fe0ef          	jal	800035a6 <ilock>
  if(ip->nlink < 1)
    800051b2:	04a91783          	lh	a5,74(s2)
    800051b6:	06f05763          	blez	a5,80005224 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800051ba:	04491703          	lh	a4,68(s2)
    800051be:	4785                	li	a5,1
    800051c0:	06f70963          	beq	a4,a5,80005232 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    800051c4:	4641                	li	a2,16
    800051c6:	4581                	li	a1,0
    800051c8:	fc040513          	addi	a0,s0,-64
    800051cc:	ad7fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800051d0:	4741                	li	a4,16
    800051d2:	f2c42683          	lw	a3,-212(s0)
    800051d6:	fc040613          	addi	a2,s0,-64
    800051da:	4581                	li	a1,0
    800051dc:	8526                	mv	a0,s1
    800051de:	855fe0ef          	jal	80003a32 <writei>
    800051e2:	47c1                	li	a5,16
    800051e4:	08f51b63          	bne	a0,a5,8000527a <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    800051e8:	04491703          	lh	a4,68(s2)
    800051ec:	4785                	li	a5,1
    800051ee:	08f70d63          	beq	a4,a5,80005288 <sys_unlink+0x14c>
  iunlockput(dp);
    800051f2:	8526                	mv	a0,s1
    800051f4:	dbcfe0ef          	jal	800037b0 <iunlockput>
  ip->nlink--;
    800051f8:	04a95783          	lhu	a5,74(s2)
    800051fc:	37fd                	addiw	a5,a5,-1
    800051fe:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005202:	854a                	mv	a0,s2
    80005204:	aeefe0ef          	jal	800034f2 <iupdate>
  iunlockput(ip);
    80005208:	854a                	mv	a0,s2
    8000520a:	da6fe0ef          	jal	800037b0 <iunlockput>
  end_op();
    8000520e:	dedfe0ef          	jal	80003ffa <end_op>
  return 0;
    80005212:	4501                	li	a0,0
    80005214:	64ee                	ld	s1,216(sp)
    80005216:	694e                	ld	s2,208(sp)
    80005218:	a849                	j	800052aa <sys_unlink+0x16e>
    end_op();
    8000521a:	de1fe0ef          	jal	80003ffa <end_op>
    return -1;
    8000521e:	557d                	li	a0,-1
    80005220:	64ee                	ld	s1,216(sp)
    80005222:	a061                	j	800052aa <sys_unlink+0x16e>
    80005224:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005226:	00002517          	auipc	a0,0x2
    8000522a:	3aa50513          	addi	a0,a0,938 # 800075d0 <etext+0x5d0>
    8000522e:	db2fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005232:	04c92703          	lw	a4,76(s2)
    80005236:	02000793          	li	a5,32
    8000523a:	f8e7f5e3          	bgeu	a5,a4,800051c4 <sys_unlink+0x88>
    8000523e:	e5ce                	sd	s3,200(sp)
    80005240:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005244:	4741                	li	a4,16
    80005246:	86ce                	mv	a3,s3
    80005248:	f1840613          	addi	a2,s0,-232
    8000524c:	4581                	li	a1,0
    8000524e:	854a                	mv	a0,s2
    80005250:	ee6fe0ef          	jal	80003936 <readi>
    80005254:	47c1                	li	a5,16
    80005256:	00f51c63          	bne	a0,a5,8000526e <sys_unlink+0x132>
    if(de.inum != 0)
    8000525a:	f1845783          	lhu	a5,-232(s0)
    8000525e:	efa1                	bnez	a5,800052b6 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005260:	29c1                	addiw	s3,s3,16
    80005262:	04c92783          	lw	a5,76(s2)
    80005266:	fcf9efe3          	bltu	s3,a5,80005244 <sys_unlink+0x108>
    8000526a:	69ae                	ld	s3,200(sp)
    8000526c:	bfa1                	j	800051c4 <sys_unlink+0x88>
      panic("isdirempty: readi");
    8000526e:	00002517          	auipc	a0,0x2
    80005272:	37a50513          	addi	a0,a0,890 # 800075e8 <etext+0x5e8>
    80005276:	d6afb0ef          	jal	800007e0 <panic>
    8000527a:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    8000527c:	00002517          	auipc	a0,0x2
    80005280:	38450513          	addi	a0,a0,900 # 80007600 <etext+0x600>
    80005284:	d5cfb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80005288:	04a4d783          	lhu	a5,74(s1)
    8000528c:	37fd                	addiw	a5,a5,-1
    8000528e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005292:	8526                	mv	a0,s1
    80005294:	a5efe0ef          	jal	800034f2 <iupdate>
    80005298:	bfa9                	j	800051f2 <sys_unlink+0xb6>
    8000529a:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    8000529c:	8526                	mv	a0,s1
    8000529e:	d12fe0ef          	jal	800037b0 <iunlockput>
  end_op();
    800052a2:	d59fe0ef          	jal	80003ffa <end_op>
  return -1;
    800052a6:	557d                	li	a0,-1
    800052a8:	64ee                	ld	s1,216(sp)
}
    800052aa:	70ae                	ld	ra,232(sp)
    800052ac:	740e                	ld	s0,224(sp)
    800052ae:	616d                	addi	sp,sp,240
    800052b0:	8082                	ret
    return -1;
    800052b2:	557d                	li	a0,-1
    800052b4:	bfdd                	j	800052aa <sys_unlink+0x16e>
    iunlockput(ip);
    800052b6:	854a                	mv	a0,s2
    800052b8:	cf8fe0ef          	jal	800037b0 <iunlockput>
    goto bad;
    800052bc:	694e                	ld	s2,208(sp)
    800052be:	69ae                	ld	s3,200(sp)
    800052c0:	bff1                	j	8000529c <sys_unlink+0x160>

00000000800052c2 <sys_open>:

uint64
sys_open(void)
{
    800052c2:	7131                	addi	sp,sp,-192
    800052c4:	fd06                	sd	ra,184(sp)
    800052c6:	f922                	sd	s0,176(sp)
    800052c8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800052ca:	f4c40593          	addi	a1,s0,-180
    800052ce:	4505                	li	a0,1
    800052d0:	faafd0ef          	jal	80002a7a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052d4:	08000613          	li	a2,128
    800052d8:	f5040593          	addi	a1,s0,-176
    800052dc:	4501                	li	a0,0
    800052de:	fe8fd0ef          	jal	80002ac6 <argstr>
    800052e2:	87aa                	mv	a5,a0
    return -1;
    800052e4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052e6:	0a07c263          	bltz	a5,8000538a <sys_open+0xc8>
    800052ea:	f526                	sd	s1,168(sp)

  begin_op();
    800052ec:	ca5fe0ef          	jal	80003f90 <begin_op>

  if(omode & O_CREATE){
    800052f0:	f4c42783          	lw	a5,-180(s0)
    800052f4:	2007f793          	andi	a5,a5,512
    800052f8:	c3d5                	beqz	a5,8000539c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800052fa:	4681                	li	a3,0
    800052fc:	4601                	li	a2,0
    800052fe:	4589                	li	a1,2
    80005300:	f5040513          	addi	a0,s0,-176
    80005304:	aa9ff0ef          	jal	80004dac <create>
    80005308:	84aa                	mv	s1,a0
    if(ip == 0){
    8000530a:	c541                	beqz	a0,80005392 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000530c:	04449703          	lh	a4,68(s1)
    80005310:	478d                	li	a5,3
    80005312:	00f71763          	bne	a4,a5,80005320 <sys_open+0x5e>
    80005316:	0464d703          	lhu	a4,70(s1)
    8000531a:	47a5                	li	a5,9
    8000531c:	0ae7ed63          	bltu	a5,a4,800053d6 <sys_open+0x114>
    80005320:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005322:	fd7fe0ef          	jal	800042f8 <filealloc>
    80005326:	892a                	mv	s2,a0
    80005328:	c179                	beqz	a0,800053ee <sys_open+0x12c>
    8000532a:	ed4e                	sd	s3,152(sp)
    8000532c:	a43ff0ef          	jal	80004d6e <fdalloc>
    80005330:	89aa                	mv	s3,a0
    80005332:	0a054a63          	bltz	a0,800053e6 <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005336:	04449703          	lh	a4,68(s1)
    8000533a:	478d                	li	a5,3
    8000533c:	0cf70263          	beq	a4,a5,80005400 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005340:	4789                	li	a5,2
    80005342:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005346:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000534a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000534e:	f4c42783          	lw	a5,-180(s0)
    80005352:	0017c713          	xori	a4,a5,1
    80005356:	8b05                	andi	a4,a4,1
    80005358:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000535c:	0037f713          	andi	a4,a5,3
    80005360:	00e03733          	snez	a4,a4
    80005364:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005368:	4007f793          	andi	a5,a5,1024
    8000536c:	c791                	beqz	a5,80005378 <sys_open+0xb6>
    8000536e:	04449703          	lh	a4,68(s1)
    80005372:	4789                	li	a5,2
    80005374:	08f70d63          	beq	a4,a5,8000540e <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	adafe0ef          	jal	80003654 <iunlock>
  end_op();
    8000537e:	c7dfe0ef          	jal	80003ffa <end_op>

  return fd;
    80005382:	854e                	mv	a0,s3
    80005384:	74aa                	ld	s1,168(sp)
    80005386:	790a                	ld	s2,160(sp)
    80005388:	69ea                	ld	s3,152(sp)
}
    8000538a:	70ea                	ld	ra,184(sp)
    8000538c:	744a                	ld	s0,176(sp)
    8000538e:	6129                	addi	sp,sp,192
    80005390:	8082                	ret
      end_op();
    80005392:	c69fe0ef          	jal	80003ffa <end_op>
      return -1;
    80005396:	557d                	li	a0,-1
    80005398:	74aa                	ld	s1,168(sp)
    8000539a:	bfc5                	j	8000538a <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    8000539c:	f5040513          	addi	a0,s0,-176
    800053a0:	a1dfe0ef          	jal	80003dbc <namei>
    800053a4:	84aa                	mv	s1,a0
    800053a6:	c11d                	beqz	a0,800053cc <sys_open+0x10a>
    ilock(ip);
    800053a8:	9fefe0ef          	jal	800035a6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800053ac:	04449703          	lh	a4,68(s1)
    800053b0:	4785                	li	a5,1
    800053b2:	f4f71de3          	bne	a4,a5,8000530c <sys_open+0x4a>
    800053b6:	f4c42783          	lw	a5,-180(s0)
    800053ba:	d3bd                	beqz	a5,80005320 <sys_open+0x5e>
      iunlockput(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	bf2fe0ef          	jal	800037b0 <iunlockput>
      end_op();
    800053c2:	c39fe0ef          	jal	80003ffa <end_op>
      return -1;
    800053c6:	557d                	li	a0,-1
    800053c8:	74aa                	ld	s1,168(sp)
    800053ca:	b7c1                	j	8000538a <sys_open+0xc8>
      end_op();
    800053cc:	c2ffe0ef          	jal	80003ffa <end_op>
      return -1;
    800053d0:	557d                	li	a0,-1
    800053d2:	74aa                	ld	s1,168(sp)
    800053d4:	bf5d                	j	8000538a <sys_open+0xc8>
    iunlockput(ip);
    800053d6:	8526                	mv	a0,s1
    800053d8:	bd8fe0ef          	jal	800037b0 <iunlockput>
    end_op();
    800053dc:	c1ffe0ef          	jal	80003ffa <end_op>
    return -1;
    800053e0:	557d                	li	a0,-1
    800053e2:	74aa                	ld	s1,168(sp)
    800053e4:	b75d                	j	8000538a <sys_open+0xc8>
      fileclose(f);
    800053e6:	854a                	mv	a0,s2
    800053e8:	fb5fe0ef          	jal	8000439c <fileclose>
    800053ec:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800053ee:	8526                	mv	a0,s1
    800053f0:	bc0fe0ef          	jal	800037b0 <iunlockput>
    end_op();
    800053f4:	c07fe0ef          	jal	80003ffa <end_op>
    return -1;
    800053f8:	557d                	li	a0,-1
    800053fa:	74aa                	ld	s1,168(sp)
    800053fc:	790a                	ld	s2,160(sp)
    800053fe:	b771                	j	8000538a <sys_open+0xc8>
    f->type = FD_DEVICE;
    80005400:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005404:	04649783          	lh	a5,70(s1)
    80005408:	02f91223          	sh	a5,36(s2)
    8000540c:	bf3d                	j	8000534a <sys_open+0x88>
    itrunc(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	a84fe0ef          	jal	80003694 <itrunc>
    80005414:	b795                	j	80005378 <sys_open+0xb6>

0000000080005416 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005416:	7175                	addi	sp,sp,-144
    80005418:	e506                	sd	ra,136(sp)
    8000541a:	e122                	sd	s0,128(sp)
    8000541c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000541e:	b73fe0ef          	jal	80003f90 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005422:	08000613          	li	a2,128
    80005426:	f7040593          	addi	a1,s0,-144
    8000542a:	4501                	li	a0,0
    8000542c:	e9afd0ef          	jal	80002ac6 <argstr>
    80005430:	02054363          	bltz	a0,80005456 <sys_mkdir+0x40>
    80005434:	4681                	li	a3,0
    80005436:	4601                	li	a2,0
    80005438:	4585                	li	a1,1
    8000543a:	f7040513          	addi	a0,s0,-144
    8000543e:	96fff0ef          	jal	80004dac <create>
    80005442:	c911                	beqz	a0,80005456 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005444:	b6cfe0ef          	jal	800037b0 <iunlockput>
  end_op();
    80005448:	bb3fe0ef          	jal	80003ffa <end_op>
  return 0;
    8000544c:	4501                	li	a0,0
}
    8000544e:	60aa                	ld	ra,136(sp)
    80005450:	640a                	ld	s0,128(sp)
    80005452:	6149                	addi	sp,sp,144
    80005454:	8082                	ret
    end_op();
    80005456:	ba5fe0ef          	jal	80003ffa <end_op>
    return -1;
    8000545a:	557d                	li	a0,-1
    8000545c:	bfcd                	j	8000544e <sys_mkdir+0x38>

000000008000545e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000545e:	7135                	addi	sp,sp,-160
    80005460:	ed06                	sd	ra,152(sp)
    80005462:	e922                	sd	s0,144(sp)
    80005464:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005466:	b2bfe0ef          	jal	80003f90 <begin_op>
  argint(1, &major);
    8000546a:	f6c40593          	addi	a1,s0,-148
    8000546e:	4505                	li	a0,1
    80005470:	e0afd0ef          	jal	80002a7a <argint>
  argint(2, &minor);
    80005474:	f6840593          	addi	a1,s0,-152
    80005478:	4509                	li	a0,2
    8000547a:	e00fd0ef          	jal	80002a7a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000547e:	08000613          	li	a2,128
    80005482:	f7040593          	addi	a1,s0,-144
    80005486:	4501                	li	a0,0
    80005488:	e3efd0ef          	jal	80002ac6 <argstr>
    8000548c:	02054563          	bltz	a0,800054b6 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005490:	f6841683          	lh	a3,-152(s0)
    80005494:	f6c41603          	lh	a2,-148(s0)
    80005498:	458d                	li	a1,3
    8000549a:	f7040513          	addi	a0,s0,-144
    8000549e:	90fff0ef          	jal	80004dac <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800054a2:	c911                	beqz	a0,800054b6 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800054a4:	b0cfe0ef          	jal	800037b0 <iunlockput>
  end_op();
    800054a8:	b53fe0ef          	jal	80003ffa <end_op>
  return 0;
    800054ac:	4501                	li	a0,0
}
    800054ae:	60ea                	ld	ra,152(sp)
    800054b0:	644a                	ld	s0,144(sp)
    800054b2:	610d                	addi	sp,sp,160
    800054b4:	8082                	ret
    end_op();
    800054b6:	b45fe0ef          	jal	80003ffa <end_op>
    return -1;
    800054ba:	557d                	li	a0,-1
    800054bc:	bfcd                	j	800054ae <sys_mknod+0x50>

00000000800054be <sys_chdir>:

uint64
sys_chdir(void)
{
    800054be:	7135                	addi	sp,sp,-160
    800054c0:	ed06                	sd	ra,152(sp)
    800054c2:	e922                	sd	s0,144(sp)
    800054c4:	e14a                	sd	s2,128(sp)
    800054c6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800054c8:	c06fc0ef          	jal	800018ce <myproc>
    800054cc:	892a                	mv	s2,a0
  
  begin_op();
    800054ce:	ac3fe0ef          	jal	80003f90 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800054d2:	08000613          	li	a2,128
    800054d6:	f6040593          	addi	a1,s0,-160
    800054da:	4501                	li	a0,0
    800054dc:	deafd0ef          	jal	80002ac6 <argstr>
    800054e0:	04054363          	bltz	a0,80005526 <sys_chdir+0x68>
    800054e4:	e526                	sd	s1,136(sp)
    800054e6:	f6040513          	addi	a0,s0,-160
    800054ea:	8d3fe0ef          	jal	80003dbc <namei>
    800054ee:	84aa                	mv	s1,a0
    800054f0:	c915                	beqz	a0,80005524 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800054f2:	8b4fe0ef          	jal	800035a6 <ilock>
  if(ip->type != T_DIR){
    800054f6:	04449703          	lh	a4,68(s1)
    800054fa:	4785                	li	a5,1
    800054fc:	02f71963          	bne	a4,a5,8000552e <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	952fe0ef          	jal	80003654 <iunlock>
  iput(p->cwd);
    80005506:	15093503          	ld	a0,336(s2)
    8000550a:	a1efe0ef          	jal	80003728 <iput>
  end_op();
    8000550e:	aedfe0ef          	jal	80003ffa <end_op>
  p->cwd = ip;
    80005512:	14993823          	sd	s1,336(s2)
  return 0;
    80005516:	4501                	li	a0,0
    80005518:	64aa                	ld	s1,136(sp)
}
    8000551a:	60ea                	ld	ra,152(sp)
    8000551c:	644a                	ld	s0,144(sp)
    8000551e:	690a                	ld	s2,128(sp)
    80005520:	610d                	addi	sp,sp,160
    80005522:	8082                	ret
    80005524:	64aa                	ld	s1,136(sp)
    end_op();
    80005526:	ad5fe0ef          	jal	80003ffa <end_op>
    return -1;
    8000552a:	557d                	li	a0,-1
    8000552c:	b7fd                	j	8000551a <sys_chdir+0x5c>
    iunlockput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	a80fe0ef          	jal	800037b0 <iunlockput>
    end_op();
    80005534:	ac7fe0ef          	jal	80003ffa <end_op>
    return -1;
    80005538:	557d                	li	a0,-1
    8000553a:	64aa                	ld	s1,136(sp)
    8000553c:	bff9                	j	8000551a <sys_chdir+0x5c>

000000008000553e <sys_exec>:

uint64
sys_exec(void)
{
    8000553e:	7121                	addi	sp,sp,-448
    80005540:	ff06                	sd	ra,440(sp)
    80005542:	fb22                	sd	s0,432(sp)
    80005544:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005546:	e4840593          	addi	a1,s0,-440
    8000554a:	4505                	li	a0,1
    8000554c:	d4afd0ef          	jal	80002a96 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005550:	08000613          	li	a2,128
    80005554:	f5040593          	addi	a1,s0,-176
    80005558:	4501                	li	a0,0
    8000555a:	d6cfd0ef          	jal	80002ac6 <argstr>
    8000555e:	87aa                	mv	a5,a0
    return -1;
    80005560:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005562:	0c07c463          	bltz	a5,8000562a <sys_exec+0xec>
    80005566:	f726                	sd	s1,424(sp)
    80005568:	f34a                	sd	s2,416(sp)
    8000556a:	ef4e                	sd	s3,408(sp)
    8000556c:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    8000556e:	10000613          	li	a2,256
    80005572:	4581                	li	a1,0
    80005574:	e5040513          	addi	a0,s0,-432
    80005578:	f2afb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000557c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005580:	89a6                	mv	s3,s1
    80005582:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005584:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005588:	00391513          	slli	a0,s2,0x3
    8000558c:	e4040593          	addi	a1,s0,-448
    80005590:	e4843783          	ld	a5,-440(s0)
    80005594:	953e                	add	a0,a0,a5
    80005596:	c5afd0ef          	jal	800029f0 <fetchaddr>
    8000559a:	02054663          	bltz	a0,800055c6 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    8000559e:	e4043783          	ld	a5,-448(s0)
    800055a2:	c3a9                	beqz	a5,800055e4 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800055a4:	d5afb0ef          	jal	80000afe <kalloc>
    800055a8:	85aa                	mv	a1,a0
    800055aa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800055ae:	cd01                	beqz	a0,800055c6 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800055b0:	6605                	lui	a2,0x1
    800055b2:	e4043503          	ld	a0,-448(s0)
    800055b6:	c84fd0ef          	jal	80002a3a <fetchstr>
    800055ba:	00054663          	bltz	a0,800055c6 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    800055be:	0905                	addi	s2,s2,1
    800055c0:	09a1                	addi	s3,s3,8
    800055c2:	fd4913e3          	bne	s2,s4,80005588 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055c6:	f5040913          	addi	s2,s0,-176
    800055ca:	6088                	ld	a0,0(s1)
    800055cc:	c931                	beqz	a0,80005620 <sys_exec+0xe2>
    kfree(argv[i]);
    800055ce:	c4efb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055d2:	04a1                	addi	s1,s1,8
    800055d4:	ff249be3          	bne	s1,s2,800055ca <sys_exec+0x8c>
  return -1;
    800055d8:	557d                	li	a0,-1
    800055da:	74ba                	ld	s1,424(sp)
    800055dc:	791a                	ld	s2,416(sp)
    800055de:	69fa                	ld	s3,408(sp)
    800055e0:	6a5a                	ld	s4,400(sp)
    800055e2:	a0a1                	j	8000562a <sys_exec+0xec>
      argv[i] = 0;
    800055e4:	0009079b          	sext.w	a5,s2
    800055e8:	078e                	slli	a5,a5,0x3
    800055ea:	fd078793          	addi	a5,a5,-48
    800055ee:	97a2                	add	a5,a5,s0
    800055f0:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    800055f4:	e5040593          	addi	a1,s0,-432
    800055f8:	f5040513          	addi	a0,s0,-176
    800055fc:	ba8ff0ef          	jal	800049a4 <kexec>
    80005600:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005602:	f5040993          	addi	s3,s0,-176
    80005606:	6088                	ld	a0,0(s1)
    80005608:	c511                	beqz	a0,80005614 <sys_exec+0xd6>
    kfree(argv[i]);
    8000560a:	c12fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000560e:	04a1                	addi	s1,s1,8
    80005610:	ff349be3          	bne	s1,s3,80005606 <sys_exec+0xc8>
  return ret;
    80005614:	854a                	mv	a0,s2
    80005616:	74ba                	ld	s1,424(sp)
    80005618:	791a                	ld	s2,416(sp)
    8000561a:	69fa                	ld	s3,408(sp)
    8000561c:	6a5a                	ld	s4,400(sp)
    8000561e:	a031                	j	8000562a <sys_exec+0xec>
  return -1;
    80005620:	557d                	li	a0,-1
    80005622:	74ba                	ld	s1,424(sp)
    80005624:	791a                	ld	s2,416(sp)
    80005626:	69fa                	ld	s3,408(sp)
    80005628:	6a5a                	ld	s4,400(sp)
}
    8000562a:	70fa                	ld	ra,440(sp)
    8000562c:	745a                	ld	s0,432(sp)
    8000562e:	6139                	addi	sp,sp,448
    80005630:	8082                	ret

0000000080005632 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005632:	7139                	addi	sp,sp,-64
    80005634:	fc06                	sd	ra,56(sp)
    80005636:	f822                	sd	s0,48(sp)
    80005638:	f426                	sd	s1,40(sp)
    8000563a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000563c:	a92fc0ef          	jal	800018ce <myproc>
    80005640:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005642:	fd840593          	addi	a1,s0,-40
    80005646:	4501                	li	a0,0
    80005648:	c4efd0ef          	jal	80002a96 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000564c:	fc840593          	addi	a1,s0,-56
    80005650:	fd040513          	addi	a0,s0,-48
    80005654:	852ff0ef          	jal	800046a6 <pipealloc>
    return -1;
    80005658:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000565a:	0a054463          	bltz	a0,80005702 <sys_pipe+0xd0>
  fd0 = -1;
    8000565e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005662:	fd043503          	ld	a0,-48(s0)
    80005666:	f08ff0ef          	jal	80004d6e <fdalloc>
    8000566a:	fca42223          	sw	a0,-60(s0)
    8000566e:	08054163          	bltz	a0,800056f0 <sys_pipe+0xbe>
    80005672:	fc843503          	ld	a0,-56(s0)
    80005676:	ef8ff0ef          	jal	80004d6e <fdalloc>
    8000567a:	fca42023          	sw	a0,-64(s0)
    8000567e:	06054063          	bltz	a0,800056de <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005682:	4691                	li	a3,4
    80005684:	fc440613          	addi	a2,s0,-60
    80005688:	fd843583          	ld	a1,-40(s0)
    8000568c:	68a8                	ld	a0,80(s1)
    8000568e:	f55fb0ef          	jal	800015e2 <copyout>
    80005692:	00054e63          	bltz	a0,800056ae <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005696:	4691                	li	a3,4
    80005698:	fc040613          	addi	a2,s0,-64
    8000569c:	fd843583          	ld	a1,-40(s0)
    800056a0:	0591                	addi	a1,a1,4
    800056a2:	68a8                	ld	a0,80(s1)
    800056a4:	f3ffb0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800056a8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800056aa:	04055c63          	bgez	a0,80005702 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800056ae:	fc442783          	lw	a5,-60(s0)
    800056b2:	07e9                	addi	a5,a5,26
    800056b4:	078e                	slli	a5,a5,0x3
    800056b6:	97a6                	add	a5,a5,s1
    800056b8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800056bc:	fc042783          	lw	a5,-64(s0)
    800056c0:	07e9                	addi	a5,a5,26
    800056c2:	078e                	slli	a5,a5,0x3
    800056c4:	94be                	add	s1,s1,a5
    800056c6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800056ca:	fd043503          	ld	a0,-48(s0)
    800056ce:	ccffe0ef          	jal	8000439c <fileclose>
    fileclose(wf);
    800056d2:	fc843503          	ld	a0,-56(s0)
    800056d6:	cc7fe0ef          	jal	8000439c <fileclose>
    return -1;
    800056da:	57fd                	li	a5,-1
    800056dc:	a01d                	j	80005702 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800056de:	fc442783          	lw	a5,-60(s0)
    800056e2:	0007c763          	bltz	a5,800056f0 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800056e6:	07e9                	addi	a5,a5,26
    800056e8:	078e                	slli	a5,a5,0x3
    800056ea:	97a6                	add	a5,a5,s1
    800056ec:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800056f0:	fd043503          	ld	a0,-48(s0)
    800056f4:	ca9fe0ef          	jal	8000439c <fileclose>
    fileclose(wf);
    800056f8:	fc843503          	ld	a0,-56(s0)
    800056fc:	ca1fe0ef          	jal	8000439c <fileclose>
    return -1;
    80005700:	57fd                	li	a5,-1
}
    80005702:	853e                	mv	a0,a5
    80005704:	70e2                	ld	ra,56(sp)
    80005706:	7442                	ld	s0,48(sp)
    80005708:	74a2                	ld	s1,40(sp)
    8000570a:	6121                	addi	sp,sp,64
    8000570c:	8082                	ret
	...

0000000080005710 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005710:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005712:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005714:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005716:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005718:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000571a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000571c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000571e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005720:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005722:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005724:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005726:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005728:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000572a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000572c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000572e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005730:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005732:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005734:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005736:	930fd0ef          	jal	80002866 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000573a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000573c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000573e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005740:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005742:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005744:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005746:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005748:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000574a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000574c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000574e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005750:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005752:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005754:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005756:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005758:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000575a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000575c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000575e:	10200073          	sret
	...

000000008000576e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000576e:	1141                	addi	sp,sp,-16
    80005770:	e422                	sd	s0,8(sp)
    80005772:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005774:	0c0007b7          	lui	a5,0xc000
    80005778:	4705                	li	a4,1
    8000577a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000577c:	0c0007b7          	lui	a5,0xc000
    80005780:	c3d8                	sw	a4,4(a5)
}
    80005782:	6422                	ld	s0,8(sp)
    80005784:	0141                	addi	sp,sp,16
    80005786:	8082                	ret

0000000080005788 <plicinithart>:

void
plicinithart(void)
{
    80005788:	1141                	addi	sp,sp,-16
    8000578a:	e406                	sd	ra,8(sp)
    8000578c:	e022                	sd	s0,0(sp)
    8000578e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005790:	912fc0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005794:	0085171b          	slliw	a4,a0,0x8
    80005798:	0c0027b7          	lui	a5,0xc002
    8000579c:	97ba                	add	a5,a5,a4
    8000579e:	40200713          	li	a4,1026
    800057a2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800057a6:	00d5151b          	slliw	a0,a0,0xd
    800057aa:	0c2017b7          	lui	a5,0xc201
    800057ae:	97aa                	add	a5,a5,a0
    800057b0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800057b4:	60a2                	ld	ra,8(sp)
    800057b6:	6402                	ld	s0,0(sp)
    800057b8:	0141                	addi	sp,sp,16
    800057ba:	8082                	ret

00000000800057bc <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800057bc:	1141                	addi	sp,sp,-16
    800057be:	e406                	sd	ra,8(sp)
    800057c0:	e022                	sd	s0,0(sp)
    800057c2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800057c4:	8defc0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800057c8:	00d5151b          	slliw	a0,a0,0xd
    800057cc:	0c2017b7          	lui	a5,0xc201
    800057d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800057d2:	43c8                	lw	a0,4(a5)
    800057d4:	60a2                	ld	ra,8(sp)
    800057d6:	6402                	ld	s0,0(sp)
    800057d8:	0141                	addi	sp,sp,16
    800057da:	8082                	ret

00000000800057dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800057dc:	1101                	addi	sp,sp,-32
    800057de:	ec06                	sd	ra,24(sp)
    800057e0:	e822                	sd	s0,16(sp)
    800057e2:	e426                	sd	s1,8(sp)
    800057e4:	1000                	addi	s0,sp,32
    800057e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800057e8:	8bafc0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800057ec:	00d5151b          	slliw	a0,a0,0xd
    800057f0:	0c2017b7          	lui	a5,0xc201
    800057f4:	97aa                	add	a5,a5,a0
    800057f6:	c3c4                	sw	s1,4(a5)
}
    800057f8:	60e2                	ld	ra,24(sp)
    800057fa:	6442                	ld	s0,16(sp)
    800057fc:	64a2                	ld	s1,8(sp)
    800057fe:	6105                	addi	sp,sp,32
    80005800:	8082                	ret

0000000080005802 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005802:	1141                	addi	sp,sp,-16
    80005804:	e406                	sd	ra,8(sp)
    80005806:	e022                	sd	s0,0(sp)
    80005808:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000580a:	479d                	li	a5,7
    8000580c:	04a7ca63          	blt	a5,a0,80005860 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005810:	0001d797          	auipc	a5,0x1d
    80005814:	a3878793          	addi	a5,a5,-1480 # 80022248 <disk>
    80005818:	97aa                	add	a5,a5,a0
    8000581a:	0187c783          	lbu	a5,24(a5)
    8000581e:	e7b9                	bnez	a5,8000586c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005820:	00451693          	slli	a3,a0,0x4
    80005824:	0001d797          	auipc	a5,0x1d
    80005828:	a2478793          	addi	a5,a5,-1500 # 80022248 <disk>
    8000582c:	6398                	ld	a4,0(a5)
    8000582e:	9736                	add	a4,a4,a3
    80005830:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005834:	6398                	ld	a4,0(a5)
    80005836:	9736                	add	a4,a4,a3
    80005838:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000583c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005840:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005844:	97aa                	add	a5,a5,a0
    80005846:	4705                	li	a4,1
    80005848:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    8000584c:	0001d517          	auipc	a0,0x1d
    80005850:	a1450513          	addi	a0,a0,-1516 # 80022260 <disk+0x18>
    80005854:	fb2fc0ef          	jal	80002006 <wakeup>
}
    80005858:	60a2                	ld	ra,8(sp)
    8000585a:	6402                	ld	s0,0(sp)
    8000585c:	0141                	addi	sp,sp,16
    8000585e:	8082                	ret
    panic("free_desc 1");
    80005860:	00002517          	auipc	a0,0x2
    80005864:	db050513          	addi	a0,a0,-592 # 80007610 <etext+0x610>
    80005868:	f79fa0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    8000586c:	00002517          	auipc	a0,0x2
    80005870:	db450513          	addi	a0,a0,-588 # 80007620 <etext+0x620>
    80005874:	f6dfa0ef          	jal	800007e0 <panic>

0000000080005878 <virtio_disk_init>:
{
    80005878:	1101                	addi	sp,sp,-32
    8000587a:	ec06                	sd	ra,24(sp)
    8000587c:	e822                	sd	s0,16(sp)
    8000587e:	e426                	sd	s1,8(sp)
    80005880:	e04a                	sd	s2,0(sp)
    80005882:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005884:	00002597          	auipc	a1,0x2
    80005888:	dac58593          	addi	a1,a1,-596 # 80007630 <etext+0x630>
    8000588c:	0001d517          	auipc	a0,0x1d
    80005890:	ae450513          	addi	a0,a0,-1308 # 80022370 <disk+0x128>
    80005894:	abafb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005898:	100017b7          	lui	a5,0x10001
    8000589c:	4398                	lw	a4,0(a5)
    8000589e:	2701                	sext.w	a4,a4
    800058a0:	747277b7          	lui	a5,0x74727
    800058a4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800058a8:	18f71063          	bne	a4,a5,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800058ac:	100017b7          	lui	a5,0x10001
    800058b0:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800058b2:	439c                	lw	a5,0(a5)
    800058b4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800058b6:	4709                	li	a4,2
    800058b8:	16e79863          	bne	a5,a4,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800058bc:	100017b7          	lui	a5,0x10001
    800058c0:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800058c2:	439c                	lw	a5,0(a5)
    800058c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800058c6:	16e79163          	bne	a5,a4,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800058ca:	100017b7          	lui	a5,0x10001
    800058ce:	47d8                	lw	a4,12(a5)
    800058d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800058d2:	554d47b7          	lui	a5,0x554d4
    800058d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800058da:	14f71763          	bne	a4,a5,80005a28 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058de:	100017b7          	lui	a5,0x10001
    800058e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058e6:	4705                	li	a4,1
    800058e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800058ea:	470d                	li	a4,3
    800058ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800058ee:	10001737          	lui	a4,0x10001
    800058f2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800058f4:	c7ffe737          	lui	a4,0xc7ffe
    800058f8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3d7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800058fc:	8ef9                	and	a3,a3,a4
    800058fe:	10001737          	lui	a4,0x10001
    80005902:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005904:	472d                	li	a4,11
    80005906:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005908:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000590c:	439c                	lw	a5,0(a5)
    8000590e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005912:	8ba1                	andi	a5,a5,8
    80005914:	12078063          	beqz	a5,80005a34 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005918:	100017b7          	lui	a5,0x10001
    8000591c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005920:	100017b7          	lui	a5,0x10001
    80005924:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005928:	439c                	lw	a5,0(a5)
    8000592a:	2781                	sext.w	a5,a5
    8000592c:	10079a63          	bnez	a5,80005a40 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005930:	100017b7          	lui	a5,0x10001
    80005934:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005938:	439c                	lw	a5,0(a5)
    8000593a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000593c:	10078863          	beqz	a5,80005a4c <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005940:	471d                	li	a4,7
    80005942:	10f77b63          	bgeu	a4,a5,80005a58 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005946:	9b8fb0ef          	jal	80000afe <kalloc>
    8000594a:	0001d497          	auipc	s1,0x1d
    8000594e:	8fe48493          	addi	s1,s1,-1794 # 80022248 <disk>
    80005952:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005954:	9aafb0ef          	jal	80000afe <kalloc>
    80005958:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000595a:	9a4fb0ef          	jal	80000afe <kalloc>
    8000595e:	87aa                	mv	a5,a0
    80005960:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005962:	6088                	ld	a0,0(s1)
    80005964:	10050063          	beqz	a0,80005a64 <virtio_disk_init+0x1ec>
    80005968:	0001d717          	auipc	a4,0x1d
    8000596c:	8e873703          	ld	a4,-1816(a4) # 80022250 <disk+0x8>
    80005970:	0e070a63          	beqz	a4,80005a64 <virtio_disk_init+0x1ec>
    80005974:	0e078863          	beqz	a5,80005a64 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005978:	6605                	lui	a2,0x1
    8000597a:	4581                	li	a1,0
    8000597c:	b26fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005980:	0001d497          	auipc	s1,0x1d
    80005984:	8c848493          	addi	s1,s1,-1848 # 80022248 <disk>
    80005988:	6605                	lui	a2,0x1
    8000598a:	4581                	li	a1,0
    8000598c:	6488                	ld	a0,8(s1)
    8000598e:	b14fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005992:	6605                	lui	a2,0x1
    80005994:	4581                	li	a1,0
    80005996:	6888                	ld	a0,16(s1)
    80005998:	b0afb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000599c:	100017b7          	lui	a5,0x10001
    800059a0:	4721                	li	a4,8
    800059a2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800059a4:	4098                	lw	a4,0(s1)
    800059a6:	100017b7          	lui	a5,0x10001
    800059aa:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800059ae:	40d8                	lw	a4,4(s1)
    800059b0:	100017b7          	lui	a5,0x10001
    800059b4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800059b8:	649c                	ld	a5,8(s1)
    800059ba:	0007869b          	sext.w	a3,a5
    800059be:	10001737          	lui	a4,0x10001
    800059c2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800059c6:	9781                	srai	a5,a5,0x20
    800059c8:	10001737          	lui	a4,0x10001
    800059cc:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800059d0:	689c                	ld	a5,16(s1)
    800059d2:	0007869b          	sext.w	a3,a5
    800059d6:	10001737          	lui	a4,0x10001
    800059da:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800059de:	9781                	srai	a5,a5,0x20
    800059e0:	10001737          	lui	a4,0x10001
    800059e4:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800059e8:	10001737          	lui	a4,0x10001
    800059ec:	4785                	li	a5,1
    800059ee:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800059f0:	00f48c23          	sb	a5,24(s1)
    800059f4:	00f48ca3          	sb	a5,25(s1)
    800059f8:	00f48d23          	sb	a5,26(s1)
    800059fc:	00f48da3          	sb	a5,27(s1)
    80005a00:	00f48e23          	sb	a5,28(s1)
    80005a04:	00f48ea3          	sb	a5,29(s1)
    80005a08:	00f48f23          	sb	a5,30(s1)
    80005a0c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005a10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005a14:	100017b7          	lui	a5,0x10001
    80005a18:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80005a1c:	60e2                	ld	ra,24(sp)
    80005a1e:	6442                	ld	s0,16(sp)
    80005a20:	64a2                	ld	s1,8(sp)
    80005a22:	6902                	ld	s2,0(sp)
    80005a24:	6105                	addi	sp,sp,32
    80005a26:	8082                	ret
    panic("could not find virtio disk");
    80005a28:	00002517          	auipc	a0,0x2
    80005a2c:	c1850513          	addi	a0,a0,-1000 # 80007640 <etext+0x640>
    80005a30:	db1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005a34:	00002517          	auipc	a0,0x2
    80005a38:	c2c50513          	addi	a0,a0,-980 # 80007660 <etext+0x660>
    80005a3c:	da5fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005a40:	00002517          	auipc	a0,0x2
    80005a44:	c4050513          	addi	a0,a0,-960 # 80007680 <etext+0x680>
    80005a48:	d99fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80005a4c:	00002517          	auipc	a0,0x2
    80005a50:	c5450513          	addi	a0,a0,-940 # 800076a0 <etext+0x6a0>
    80005a54:	d8dfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005a58:	00002517          	auipc	a0,0x2
    80005a5c:	c6850513          	addi	a0,a0,-920 # 800076c0 <etext+0x6c0>
    80005a60:	d81fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005a64:	00002517          	auipc	a0,0x2
    80005a68:	c7c50513          	addi	a0,a0,-900 # 800076e0 <etext+0x6e0>
    80005a6c:	d75fa0ef          	jal	800007e0 <panic>

0000000080005a70 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005a70:	7159                	addi	sp,sp,-112
    80005a72:	f486                	sd	ra,104(sp)
    80005a74:	f0a2                	sd	s0,96(sp)
    80005a76:	eca6                	sd	s1,88(sp)
    80005a78:	e8ca                	sd	s2,80(sp)
    80005a7a:	e4ce                	sd	s3,72(sp)
    80005a7c:	e0d2                	sd	s4,64(sp)
    80005a7e:	fc56                	sd	s5,56(sp)
    80005a80:	f85a                	sd	s6,48(sp)
    80005a82:	f45e                	sd	s7,40(sp)
    80005a84:	f062                	sd	s8,32(sp)
    80005a86:	ec66                	sd	s9,24(sp)
    80005a88:	1880                	addi	s0,sp,112
    80005a8a:	8a2a                	mv	s4,a0
    80005a8c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005a8e:	00c52c83          	lw	s9,12(a0)
    80005a92:	001c9c9b          	slliw	s9,s9,0x1
    80005a96:	1c82                	slli	s9,s9,0x20
    80005a98:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005a9c:	0001d517          	auipc	a0,0x1d
    80005aa0:	8d450513          	addi	a0,a0,-1836 # 80022370 <disk+0x128>
    80005aa4:	92afb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005aa8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005aaa:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005aac:	0001cb17          	auipc	s6,0x1c
    80005ab0:	79cb0b13          	addi	s6,s6,1948 # 80022248 <disk>
  for(int i = 0; i < 3; i++){
    80005ab4:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ab6:	0001dc17          	auipc	s8,0x1d
    80005aba:	8bac0c13          	addi	s8,s8,-1862 # 80022370 <disk+0x128>
    80005abe:	a8b9                	j	80005b1c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005ac0:	00fb0733          	add	a4,s6,a5
    80005ac4:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005ac8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005aca:	0207c563          	bltz	a5,80005af4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005ace:	2905                	addiw	s2,s2,1
    80005ad0:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005ad2:	05590963          	beq	s2,s5,80005b24 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005ad6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ad8:	0001c717          	auipc	a4,0x1c
    80005adc:	77070713          	addi	a4,a4,1904 # 80022248 <disk>
    80005ae0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ae2:	01874683          	lbu	a3,24(a4)
    80005ae6:	fee9                	bnez	a3,80005ac0 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005ae8:	2785                	addiw	a5,a5,1
    80005aea:	0705                	addi	a4,a4,1
    80005aec:	fe979be3          	bne	a5,s1,80005ae2 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005af0:	57fd                	li	a5,-1
    80005af2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005af4:	01205d63          	blez	s2,80005b0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005af8:	f9042503          	lw	a0,-112(s0)
    80005afc:	d07ff0ef          	jal	80005802 <free_desc>
      for(int j = 0; j < i; j++)
    80005b00:	4785                	li	a5,1
    80005b02:	0127d663          	bge	a5,s2,80005b0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005b06:	f9442503          	lw	a0,-108(s0)
    80005b0a:	cf9ff0ef          	jal	80005802 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005b0e:	85e2                	mv	a1,s8
    80005b10:	0001c517          	auipc	a0,0x1c
    80005b14:	75050513          	addi	a0,a0,1872 # 80022260 <disk+0x18>
    80005b18:	c9efc0ef          	jal	80001fb6 <sleep>
  for(int i = 0; i < 3; i++){
    80005b1c:	f9040613          	addi	a2,s0,-112
    80005b20:	894e                	mv	s2,s3
    80005b22:	bf55                	j	80005ad6 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005b24:	f9042503          	lw	a0,-112(s0)
    80005b28:	00451693          	slli	a3,a0,0x4

  if(write)
    80005b2c:	0001c797          	auipc	a5,0x1c
    80005b30:	71c78793          	addi	a5,a5,1820 # 80022248 <disk>
    80005b34:	00a50713          	addi	a4,a0,10
    80005b38:	0712                	slli	a4,a4,0x4
    80005b3a:	973e                	add	a4,a4,a5
    80005b3c:	01703633          	snez	a2,s7
    80005b40:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005b42:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005b46:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b4a:	6398                	ld	a4,0(a5)
    80005b4c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005b4e:	0a868613          	addi	a2,a3,168
    80005b52:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b54:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005b56:	6390                	ld	a2,0(a5)
    80005b58:	00d605b3          	add	a1,a2,a3
    80005b5c:	4741                	li	a4,16
    80005b5e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005b60:	4805                	li	a6,1
    80005b62:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005b66:	f9442703          	lw	a4,-108(s0)
    80005b6a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005b6e:	0712                	slli	a4,a4,0x4
    80005b70:	963a                	add	a2,a2,a4
    80005b72:	058a0593          	addi	a1,s4,88
    80005b76:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005b78:	0007b883          	ld	a7,0(a5)
    80005b7c:	9746                	add	a4,a4,a7
    80005b7e:	40000613          	li	a2,1024
    80005b82:	c710                	sw	a2,8(a4)
  if(write)
    80005b84:	001bb613          	seqz	a2,s7
    80005b88:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005b8c:	00166613          	ori	a2,a2,1
    80005b90:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005b94:	f9842583          	lw	a1,-104(s0)
    80005b98:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005b9c:	00250613          	addi	a2,a0,2
    80005ba0:	0612                	slli	a2,a2,0x4
    80005ba2:	963e                	add	a2,a2,a5
    80005ba4:	577d                	li	a4,-1
    80005ba6:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005baa:	0592                	slli	a1,a1,0x4
    80005bac:	98ae                	add	a7,a7,a1
    80005bae:	03068713          	addi	a4,a3,48
    80005bb2:	973e                	add	a4,a4,a5
    80005bb4:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005bb8:	6398                	ld	a4,0(a5)
    80005bba:	972e                	add	a4,a4,a1
    80005bbc:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005bc0:	4689                	li	a3,2
    80005bc2:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005bc6:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005bca:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005bce:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005bd2:	6794                	ld	a3,8(a5)
    80005bd4:	0026d703          	lhu	a4,2(a3)
    80005bd8:	8b1d                	andi	a4,a4,7
    80005bda:	0706                	slli	a4,a4,0x1
    80005bdc:	96ba                	add	a3,a3,a4
    80005bde:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005be2:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005be6:	6798                	ld	a4,8(a5)
    80005be8:	00275783          	lhu	a5,2(a4)
    80005bec:	2785                	addiw	a5,a5,1
    80005bee:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005bf2:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005bf6:	100017b7          	lui	a5,0x10001
    80005bfa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005bfe:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005c02:	0001c917          	auipc	s2,0x1c
    80005c06:	76e90913          	addi	s2,s2,1902 # 80022370 <disk+0x128>
  while(b->disk == 1) {
    80005c0a:	4485                	li	s1,1
    80005c0c:	01079a63          	bne	a5,a6,80005c20 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005c10:	85ca                	mv	a1,s2
    80005c12:	8552                	mv	a0,s4
    80005c14:	ba2fc0ef          	jal	80001fb6 <sleep>
  while(b->disk == 1) {
    80005c18:	004a2783          	lw	a5,4(s4)
    80005c1c:	fe978ae3          	beq	a5,s1,80005c10 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005c20:	f9042903          	lw	s2,-112(s0)
    80005c24:	00290713          	addi	a4,s2,2
    80005c28:	0712                	slli	a4,a4,0x4
    80005c2a:	0001c797          	auipc	a5,0x1c
    80005c2e:	61e78793          	addi	a5,a5,1566 # 80022248 <disk>
    80005c32:	97ba                	add	a5,a5,a4
    80005c34:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005c38:	0001c997          	auipc	s3,0x1c
    80005c3c:	61098993          	addi	s3,s3,1552 # 80022248 <disk>
    80005c40:	00491713          	slli	a4,s2,0x4
    80005c44:	0009b783          	ld	a5,0(s3)
    80005c48:	97ba                	add	a5,a5,a4
    80005c4a:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005c4e:	854a                	mv	a0,s2
    80005c50:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005c54:	bafff0ef          	jal	80005802 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005c58:	8885                	andi	s1,s1,1
    80005c5a:	f0fd                	bnez	s1,80005c40 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005c5c:	0001c517          	auipc	a0,0x1c
    80005c60:	71450513          	addi	a0,a0,1812 # 80022370 <disk+0x128>
    80005c64:	802fb0ef          	jal	80000c66 <release>
}
    80005c68:	70a6                	ld	ra,104(sp)
    80005c6a:	7406                	ld	s0,96(sp)
    80005c6c:	64e6                	ld	s1,88(sp)
    80005c6e:	6946                	ld	s2,80(sp)
    80005c70:	69a6                	ld	s3,72(sp)
    80005c72:	6a06                	ld	s4,64(sp)
    80005c74:	7ae2                	ld	s5,56(sp)
    80005c76:	7b42                	ld	s6,48(sp)
    80005c78:	7ba2                	ld	s7,40(sp)
    80005c7a:	7c02                	ld	s8,32(sp)
    80005c7c:	6ce2                	ld	s9,24(sp)
    80005c7e:	6165                	addi	sp,sp,112
    80005c80:	8082                	ret

0000000080005c82 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005c82:	1101                	addi	sp,sp,-32
    80005c84:	ec06                	sd	ra,24(sp)
    80005c86:	e822                	sd	s0,16(sp)
    80005c88:	e426                	sd	s1,8(sp)
    80005c8a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005c8c:	0001c497          	auipc	s1,0x1c
    80005c90:	5bc48493          	addi	s1,s1,1468 # 80022248 <disk>
    80005c94:	0001c517          	auipc	a0,0x1c
    80005c98:	6dc50513          	addi	a0,a0,1756 # 80022370 <disk+0x128>
    80005c9c:	f33fa0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005ca0:	100017b7          	lui	a5,0x10001
    80005ca4:	53b8                	lw	a4,96(a5)
    80005ca6:	8b0d                	andi	a4,a4,3
    80005ca8:	100017b7          	lui	a5,0x10001
    80005cac:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005cae:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005cb2:	689c                	ld	a5,16(s1)
    80005cb4:	0204d703          	lhu	a4,32(s1)
    80005cb8:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005cbc:	04f70663          	beq	a4,a5,80005d08 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005cc0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005cc4:	6898                	ld	a4,16(s1)
    80005cc6:	0204d783          	lhu	a5,32(s1)
    80005cca:	8b9d                	andi	a5,a5,7
    80005ccc:	078e                	slli	a5,a5,0x3
    80005cce:	97ba                	add	a5,a5,a4
    80005cd0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005cd2:	00278713          	addi	a4,a5,2
    80005cd6:	0712                	slli	a4,a4,0x4
    80005cd8:	9726                	add	a4,a4,s1
    80005cda:	01074703          	lbu	a4,16(a4)
    80005cde:	e321                	bnez	a4,80005d1e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005ce0:	0789                	addi	a5,a5,2
    80005ce2:	0792                	slli	a5,a5,0x4
    80005ce4:	97a6                	add	a5,a5,s1
    80005ce6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005ce8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005cec:	b1afc0ef          	jal	80002006 <wakeup>

    disk.used_idx += 1;
    80005cf0:	0204d783          	lhu	a5,32(s1)
    80005cf4:	2785                	addiw	a5,a5,1
    80005cf6:	17c2                	slli	a5,a5,0x30
    80005cf8:	93c1                	srli	a5,a5,0x30
    80005cfa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005cfe:	6898                	ld	a4,16(s1)
    80005d00:	00275703          	lhu	a4,2(a4)
    80005d04:	faf71ee3          	bne	a4,a5,80005cc0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005d08:	0001c517          	auipc	a0,0x1c
    80005d0c:	66850513          	addi	a0,a0,1640 # 80022370 <disk+0x128>
    80005d10:	f57fa0ef          	jal	80000c66 <release>
}
    80005d14:	60e2                	ld	ra,24(sp)
    80005d16:	6442                	ld	s0,16(sp)
    80005d18:	64a2                	ld	s1,8(sp)
    80005d1a:	6105                	addi	sp,sp,32
    80005d1c:	8082                	ret
      panic("virtio_disk_intr status");
    80005d1e:	00002517          	auipc	a0,0x2
    80005d22:	9da50513          	addi	a0,a0,-1574 # 800076f8 <etext+0x6f8>
    80005d26:	abbfa0ef          	jal	800007e0 <panic>
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
