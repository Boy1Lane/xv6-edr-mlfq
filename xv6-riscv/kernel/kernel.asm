
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
    80000112:	3e6020ef          	jal	800024f8 <either_copyin>
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
    800001bc:	1ce020ef          	jal	8000238a <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	789010ef          	jal	8000214e <sleep>
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
    8000020a:	2a4020ef          	jal	800024ae <either_copyout>
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
    800002d8:	26a020ef          	jal	80002542 <procdump>
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
    8000041e:	581010ef          	jal	8000219e <wakeup>
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
    800008ea:	065010ef          	jal	8000214e <sleep>
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
    80000a00:	79e010ef          	jal	8000219e <wakeup>
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
    80000e72:	08b010ef          	jal	800026fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	313040ef          	jal	80005988 <plicinithart>
  }

  scheduler();        
    80000e7a:	020010ef          	jal	80001e9a <scheduler>
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
    80000eba:	01f010ef          	jal	800026d8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	03f010ef          	jal	800026fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	2ad040ef          	jal	8000596e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	2c3040ef          	jal	80005988 <plicinithart>
    binit();         // buffer cache
    80000eca:	17e020ef          	jal	80003048 <binit>
    iinit();         // inode table
    80000ece:	704020ef          	jal	800035d2 <iinit>
    fileinit();      // file table
    80000ed2:	5f6030ef          	jal	800044c8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	3a3040ef          	jal	80005a78 <virtio_disk_init>
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
    8000191e:	170020ef          	jal	80003a8e <fsinit>

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
    80001942:	256030ef          	jal	80004b98 <kexec>
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
    80001954:	5c1000ef          	jal	80002714 <prepare_return>
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
    80001c20:	c4a7ba23          	sd	a0,-940(a5) # 80007870 <initproc>
  p->cwd = namei("/");
    80001c24:	00005517          	auipc	a0,0x5
    80001c28:	56c50513          	addi	a0,a0,1388 # 80007190 <etext+0x190>
    80001c2c:	384020ef          	jal	80003fb0 <namei>
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
    80001d48:	003020ef          	jal	8000454a <filedup>
    80001d4c:	00a93023          	sd	a0,0(s2)
    80001d50:	b7f5                	j	80001d3c <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d52:	150ab503          	ld	a0,336(s5)
    80001d56:	20f010ef          	jal	80003764 <idup>
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
    80001df8:	fb448493          	addi	s1,s1,-76 # 8000fda8 <proc>
  int count = 0;
    80001dfc:	4a01                	li	s4,0
  for(p = proc; p < &proc[NPROC]; p++){
    80001dfe:	00015917          	auipc	s2,0x15
    80001e02:	1aa90913          	addi	s2,s2,426 # 80016fa8 <tickslock>
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
    80001e38:	7179                	addi	sp,sp,-48
    80001e3a:	f406                	sd	ra,40(sp)
    80001e3c:	f022                	sd	s0,32(sp)
    80001e3e:	ec26                	sd	s1,24(sp)
    80001e40:	e84a                	sd	s2,16(sp)
    80001e42:	e44e                	sd	s3,8(sp)
    80001e44:	e052                	sd	s4,0(sp)
    80001e46:	1800                	addi	s0,sp,48
    80001e48:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80001e4a:	0000e497          	auipc	s1,0xe
    80001e4e:	f5e48493          	addi	s1,s1,-162 # 8000fda8 <proc>
      p->is_sandboxed = 2; // QUARANTINED
    80001e52:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++){
    80001e54:	00015917          	auipc	s2,0x15
    80001e58:	15490913          	addi	s2,s2,340 # 80016fa8 <tickslock>
    80001e5c:	a029                	j	80001e66 <propagate_sandbox+0x2e>
    80001e5e:	1c848493          	addi	s1,s1,456
    80001e62:	03248463          	beq	s1,s2,80001e8a <propagate_sandbox+0x52>
    if(p->state != UNUSED && p != root && is_descendant(p, root)){
    80001e66:	4c9c                	lw	a5,24(s1)
    80001e68:	dbfd                	beqz	a5,80001e5e <propagate_sandbox+0x26>
    80001e6a:	fe998ae3          	beq	s3,s1,80001e5e <propagate_sandbox+0x26>
    80001e6e:	85ce                	mv	a1,s3
    80001e70:	8526                	mv	a0,s1
    80001e72:	f47ff0ef          	jal	80001db8 <is_descendant>
    80001e76:	d565                	beqz	a0,80001e5e <propagate_sandbox+0x26>
      acquire(&p->lock);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	d55fe0ef          	jal	80000bce <acquire>
      p->is_sandboxed = 2; // QUARANTINED
    80001e7e:	1b448823          	sb	s4,432(s1)
      release(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	de3fe0ef          	jal	80000c66 <release>
    80001e88:	bfd9                	j	80001e5e <propagate_sandbox+0x26>
}
    80001e8a:	70a2                	ld	ra,40(sp)
    80001e8c:	7402                	ld	s0,32(sp)
    80001e8e:	64e2                	ld	s1,24(sp)
    80001e90:	6942                	ld	s2,16(sp)
    80001e92:	69a2                	ld	s3,8(sp)
    80001e94:	6a02                	ld	s4,0(sp)
    80001e96:	6145                	addi	sp,sp,48
    80001e98:	8082                	ret

0000000080001e9a <scheduler>:
{
    80001e9a:	7119                	addi	sp,sp,-128
    80001e9c:	fc86                	sd	ra,120(sp)
    80001e9e:	f8a2                	sd	s0,112(sp)
    80001ea0:	f4a6                	sd	s1,104(sp)
    80001ea2:	f0ca                	sd	s2,96(sp)
    80001ea4:	ecce                	sd	s3,88(sp)
    80001ea6:	e8d2                	sd	s4,80(sp)
    80001ea8:	e4d6                	sd	s5,72(sp)
    80001eaa:	e0da                	sd	s6,64(sp)
    80001eac:	fc5e                	sd	s7,56(sp)
    80001eae:	f862                	sd	s8,48(sp)
    80001eb0:	f466                	sd	s9,40(sp)
    80001eb2:	f06a                	sd	s10,32(sp)
    80001eb4:	ec6e                	sd	s11,24(sp)
    80001eb6:	0100                	addi	s0,sp,128
    80001eb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ebc:	00779693          	slli	a3,a5,0x7
    80001ec0:	0000e717          	auipc	a4,0xe
    80001ec4:	ab870713          	addi	a4,a4,-1352 # 8000f978 <pid_lock>
    80001ec8:	9736                	add	a4,a4,a3
    80001eca:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001ece:	0000e717          	auipc	a4,0xe
    80001ed2:	ae270713          	addi	a4,a4,-1310 # 8000f9b0 <cpus+0x8>
    80001ed6:	9736                	add	a4,a4,a3
    80001ed8:	f8e43423          	sd	a4,-120(s0)
        p = &proc[idx];
    80001edc:	0000eb17          	auipc	s6,0xe
    80001ee0:	eccb0b13          	addi	s6,s6,-308 # 8000fda8 <proc>
      for(int i = 0; i < NPROC; i++) {
    80001ee4:	04000d13          	li	s10,64
          c->proc = p;
    80001ee8:	0000e717          	auipc	a4,0xe
    80001eec:	a9070713          	addi	a4,a4,-1392 # 8000f978 <pid_lock>
    80001ef0:	00d707b3          	add	a5,a4,a3
    80001ef4:	f8f43023          	sd	a5,-128(s0)
    80001ef8:	a235                	j	80002024 <scheduler+0x18a>
      if (__sync_lock_test_and_set(&edr_lock, 1) == 0) {
    80001efa:	00006717          	auipc	a4,0x6
    80001efe:	96a70713          	addi	a4,a4,-1686 # 80007864 <edr_lock>
    80001f02:	4785                	li	a5,1
    80001f04:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
    80001f08:	2781                	sext.w	a5,a5
    80001f0a:	12079963          	bnez	a5,8000203c <scheduler+0x1a2>
        if (edr_work_pending) {
    80001f0e:	00006797          	auipc	a5,0x6
    80001f12:	95a7a783          	lw	a5,-1702(a5) # 80007868 <edr_work_pending>
    80001f16:	eb91                	bnez	a5,80001f2a <scheduler+0x90>
        __sync_lock_release(&edr_lock);
    80001f18:	00006797          	auipc	a5,0x6
    80001f1c:	94c78793          	addi	a5,a5,-1716 # 80007864 <edr_lock>
    80001f20:	0f50000f          	fence	iorw,ow
    80001f24:	0807a02f          	amoswap.w	zero,zero,(a5)
    80001f28:	aa11                	j	8000203c <scheduler+0x1a2>
          edr_work_pending = 0;
    80001f2a:	00006797          	auipc	a5,0x6
    80001f2e:	9207af23          	sw	zero,-1730(a5) # 80007868 <edr_work_pending>
          acquire(&wait_lock);
    80001f32:	0000e517          	auipc	a0,0xe
    80001f36:	a5e50513          	addi	a0,a0,-1442 # 8000f990 <wait_lock>
    80001f3a:	c95fe0ef          	jal	80000bce <acquire>
          for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80001f3e:	0000e497          	auipc	s1,0xe
    80001f42:	e6a48493          	addi	s1,s1,-406 # 8000fda8 <proc>
              if (count >= EDR_TREE_VOLUME_THRESHOLD) {
    80001f46:	4a3d                	li	s4,15
                pp->is_sandboxed = 2;
    80001f48:	4a89                	li	s5,2
          for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80001f4a:	00015997          	auipc	s3,0x15
    80001f4e:	05e98993          	addi	s3,s3,94 # 80016fa8 <tickslock>
    80001f52:	a029                	j	80001f5c <scheduler+0xc2>
    80001f54:	1c848493          	addi	s1,s1,456
    80001f58:	03348f63          	beq	s1,s3,80001f96 <scheduler+0xfc>
            acquire(&pp->lock);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	c71fe0ef          	jal	80000bce <acquire>
            int need_prop = pp->need_propagation;
    80001f62:	1c04c903          	lbu	s2,448(s1)
            pp->need_propagation = 0;
    80001f66:	1c048023          	sb	zero,448(s1)
            release(&pp->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	cfbfe0ef          	jal	80000c66 <release>
            if (need_prop) {
    80001f70:	fe0902e3          	beqz	s2,80001f54 <scheduler+0xba>
              int count = count_live_descendants(pp);
    80001f74:	8526                	mv	a0,s1
    80001f76:	e6dff0ef          	jal	80001de2 <count_live_descendants>
              if (count >= EDR_TREE_VOLUME_THRESHOLD) {
    80001f7a:	fcaa5de3          	bge	s4,a0,80001f54 <scheduler+0xba>
                acquire(&pp->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	c4ffe0ef          	jal	80000bce <acquire>
                pp->is_sandboxed = 2;
    80001f84:	1b548823          	sb	s5,432(s1)
                release(&pp->lock);
    80001f88:	8526                	mv	a0,s1
    80001f8a:	cddfe0ef          	jal	80000c66 <release>
                propagate_sandbox(pp);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	ea9ff0ef          	jal	80001e38 <propagate_sandbox>
    80001f94:	b7c1                	j	80001f54 <scheduler+0xba>
          release(&wait_lock);
    80001f96:	0000e517          	auipc	a0,0xe
    80001f9a:	9fa50513          	addi	a0,a0,-1542 # 8000f990 <wait_lock>
    80001f9e:	cc9fe0ef          	jal	80000c66 <release>
    80001fa2:	bf9d                	j	80001f18 <scheduler+0x7e>
        release(&p->lock);
    80001fa4:	854a                	mv	a0,s2
    80001fa6:	cc1fe0ef          	jal	80000c66 <release>
      for(int i = 0; i < NPROC; i++) {
    80001faa:	2985                	addiw	s3,s3,1
    80001fac:	0ba98763          	beq	s3,s10,8000205a <scheduler+0x1c0>
        int idx = (last_idx + 1 + i) % NPROC;
    80001fb0:	000ca483          	lw	s1,0(s9)
    80001fb4:	2485                	addiw	s1,s1,1
    80001fb6:	013484bb          	addw	s1,s1,s3
    80001fba:	41f4d79b          	sraiw	a5,s1,0x1f
    80001fbe:	01a7d79b          	srliw	a5,a5,0x1a
    80001fc2:	9cbd                	addw	s1,s1,a5
    80001fc4:	03f4f493          	andi	s1,s1,63
    80001fc8:	9c9d                	subw	s1,s1,a5
    80001fca:	00048a1b          	sext.w	s4,s1
        p = &proc[idx];
    80001fce:	037a0ab3          	mul	s5,s4,s7
    80001fd2:	016a8933          	add	s2,s5,s6
        acquire(&p->lock);
    80001fd6:	854a                	mv	a0,s2
    80001fd8:	bf7fe0ef          	jal	80000bce <acquire>
        if(p->state == RUNNABLE && p->priority == pr) {
    80001fdc:	01892783          	lw	a5,24(s2)
    80001fe0:	fd8792e3          	bne	a5,s8,80001fa4 <scheduler+0x10a>
    80001fe4:	16892783          	lw	a5,360(s2)
    80001fe8:	fbb79ee3          	bne	a5,s11,80001fa4 <scheduler+0x10a>
          p->state = RUNNING;
    80001fec:	1c800793          	li	a5,456
    80001ff0:	02fa0a33          	mul	s4,s4,a5
    80001ff4:	9a5a                	add	s4,s4,s6
    80001ff6:	4791                	li	a5,4
    80001ff8:	00fa2c23          	sw	a5,24(s4)
          c->proc = p;
    80001ffc:	f8043983          	ld	s3,-128(s0)
    80002000:	0329b823          	sd	s2,48(s3)
          last_idx = idx;
    80002004:	00006797          	auipc	a5,0x6
    80002008:	8497ae23          	sw	s1,-1956(a5) # 80007860 <last_idx.2>
          swtch(&c->context, &p->context);
    8000200c:	060a8593          	addi	a1,s5,96
    80002010:	95da                	add	a1,a1,s6
    80002012:	f8843503          	ld	a0,-120(s0)
    80002016:	658000ef          	jal	8000266e <swtch>
          c->proc = 0;
    8000201a:	0209b823          	sd	zero,48(s3)
          release(&p->lock);
    8000201e:	854a                	mv	a0,s2
    80002020:	c47fe0ef          	jal	80000c66 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002024:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002028:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000202c:	10079073          	csrw	sstatus,a5
    if (edr_work_pending) {
    80002030:	00006797          	auipc	a5,0x6
    80002034:	8387a783          	lw	a5,-1992(a5) # 80007868 <edr_work_pending>
    80002038:	ec0791e3          	bnez	a5,80001efa <scheduler+0x60>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002040:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002042:	10079073          	csrw	sstatus,a5
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    80002046:	4d81                	li	s11,0
        int idx = (last_idx + 1 + i) % NPROC;
    80002048:	00006c97          	auipc	s9,0x6
    8000204c:	818c8c93          	addi	s9,s9,-2024 # 80007860 <last_idx.2>
    80002050:	1c800b93          	li	s7,456
      for(int i = 0; i < NPROC; i++) {
    80002054:	4981                	li	s3,0
        if(p->state == RUNNABLE && p->priority == pr) {
    80002056:	4c0d                	li	s8,3
    80002058:	bfa1                	j	80001fb0 <scheduler+0x116>
    for(int pr = 0; pr < MLFQ_LEVELS; pr++){
    8000205a:	2d85                	addiw	s11,s11,1
    8000205c:	478d                	li	a5,3
    8000205e:	fefd9be3          	bne	s11,a5,80002054 <scheduler+0x1ba>
      asm volatile("wfi");
    80002062:	10500073          	wfi
    80002066:	bf7d                	j	80002024 <scheduler+0x18a>

0000000080002068 <sched>:
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002076:	859ff0ef          	jal	800018ce <myproc>
    8000207a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000207c:	ae9fe0ef          	jal	80000b64 <holding>
    80002080:	c92d                	beqz	a0,800020f2 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002082:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	0000e717          	auipc	a4,0xe
    8000208c:	8f070713          	addi	a4,a4,-1808 # 8000f978 <pid_lock>
    80002090:	97ba                	add	a5,a5,a4
    80002092:	0a87a703          	lw	a4,168(a5)
    80002096:	4785                	li	a5,1
    80002098:	06f71363          	bne	a4,a5,800020fe <sched+0x96>
  if(p->state == RUNNING)
    8000209c:	4c98                	lw	a4,24(s1)
    8000209e:	4791                	li	a5,4
    800020a0:	06f70563          	beq	a4,a5,8000210a <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020a8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020aa:	e7b5                	bnez	a5,80002116 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ae:	0000e917          	auipc	s2,0xe
    800020b2:	8ca90913          	addi	s2,s2,-1846 # 8000f978 <pid_lock>
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	97ca                	add	a5,a5,s2
    800020bc:	0ac7a983          	lw	s3,172(a5)
    800020c0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	0000e597          	auipc	a1,0xe
    800020ca:	8ea58593          	addi	a1,a1,-1814 # 8000f9b0 <cpus+0x8>
    800020ce:	95be                	add	a1,a1,a5
    800020d0:	06048513          	addi	a0,s1,96
    800020d4:	59a000ef          	jal	8000266e <swtch>
    800020d8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020da:	2781                	sext.w	a5,a5
    800020dc:	079e                	slli	a5,a5,0x7
    800020de:	993e                	add	s2,s2,a5
    800020e0:	0b392623          	sw	s3,172(s2)
}
    800020e4:	70a2                	ld	ra,40(sp)
    800020e6:	7402                	ld	s0,32(sp)
    800020e8:	64e2                	ld	s1,24(sp)
    800020ea:	6942                	ld	s2,16(sp)
    800020ec:	69a2                	ld	s3,8(sp)
    800020ee:	6145                	addi	sp,sp,48
    800020f0:	8082                	ret
    panic("sched p->lock");
    800020f2:	00005517          	auipc	a0,0x5
    800020f6:	0a650513          	addi	a0,a0,166 # 80007198 <etext+0x198>
    800020fa:	ee6fe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    800020fe:	00005517          	auipc	a0,0x5
    80002102:	0aa50513          	addi	a0,a0,170 # 800071a8 <etext+0x1a8>
    80002106:	edafe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    8000210a:	00005517          	auipc	a0,0x5
    8000210e:	0ae50513          	addi	a0,a0,174 # 800071b8 <etext+0x1b8>
    80002112:	ecefe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80002116:	00005517          	auipc	a0,0x5
    8000211a:	0b250513          	addi	a0,a0,178 # 800071c8 <etext+0x1c8>
    8000211e:	ec2fe0ef          	jal	800007e0 <panic>

0000000080002122 <yield>:
{
    80002122:	1101                	addi	sp,sp,-32
    80002124:	ec06                	sd	ra,24(sp)
    80002126:	e822                	sd	s0,16(sp)
    80002128:	e426                	sd	s1,8(sp)
    8000212a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000212c:	fa2ff0ef          	jal	800018ce <myproc>
    80002130:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002132:	a9dfe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80002136:	478d                	li	a5,3
    80002138:	cc9c                	sw	a5,24(s1)
  sched();
    8000213a:	f2fff0ef          	jal	80002068 <sched>
  release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	b27fe0ef          	jal	80000c66 <release>
}
    80002144:	60e2                	ld	ra,24(sp)
    80002146:	6442                	ld	s0,16(sp)
    80002148:	64a2                	ld	s1,8(sp)
    8000214a:	6105                	addi	sp,sp,32
    8000214c:	8082                	ret

000000008000214e <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000214e:	7179                	addi	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	1800                	addi	s0,sp,48
    8000215c:	89aa                	mv	s3,a0
    8000215e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002160:	f6eff0ef          	jal	800018ce <myproc>
    80002164:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002166:	a69fe0ef          	jal	80000bce <acquire>
  release(lk);
    8000216a:	854a                	mv	a0,s2
    8000216c:	afbfe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80002170:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002174:	4789                	li	a5,2
    80002176:	cc9c                	sw	a5,24(s1)
  p->ticks_used = 0; // Đặt lại để khi thức dậy có quantum đầy đủ
    80002178:	1604a623          	sw	zero,364(s1)

  sched();
    8000217c:	eedff0ef          	jal	80002068 <sched>

  // Tidy up.
  p->chan = 0;
    80002180:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	ae1fe0ef          	jal	80000c66 <release>
  acquire(lk);
    8000218a:	854a                	mv	a0,s2
    8000218c:	a43fe0ef          	jal	80000bce <acquire>
}
    80002190:	70a2                	ld	ra,40(sp)
    80002192:	7402                	ld	s0,32(sp)
    80002194:	64e2                	ld	s1,24(sp)
    80002196:	6942                	ld	s2,16(sp)
    80002198:	69a2                	ld	s3,8(sp)
    8000219a:	6145                	addi	sp,sp,48
    8000219c:	8082                	ret

000000008000219e <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    8000219e:	7139                	addi	sp,sp,-64
    800021a0:	fc06                	sd	ra,56(sp)
    800021a2:	f822                	sd	s0,48(sp)
    800021a4:	f426                	sd	s1,40(sp)
    800021a6:	f04a                	sd	s2,32(sp)
    800021a8:	ec4e                	sd	s3,24(sp)
    800021aa:	e852                	sd	s4,16(sp)
    800021ac:	e456                	sd	s5,8(sp)
    800021ae:	0080                	addi	s0,sp,64
    800021b0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021b2:	0000e497          	auipc	s1,0xe
    800021b6:	bf648493          	addi	s1,s1,-1034 # 8000fda8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021ba:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021bc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021be:	00015917          	auipc	s2,0x15
    800021c2:	dea90913          	addi	s2,s2,-534 # 80016fa8 <tickslock>
    800021c6:	a801                	j	800021d6 <wakeup+0x38>
      }
      release(&p->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	a9dfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ce:	1c848493          	addi	s1,s1,456
    800021d2:	03248263          	beq	s1,s2,800021f6 <wakeup+0x58>
    if(p != myproc()){
    800021d6:	ef8ff0ef          	jal	800018ce <myproc>
    800021da:	fea48ae3          	beq	s1,a0,800021ce <wakeup+0x30>
      acquire(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	9effe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021e4:	4c9c                	lw	a5,24(s1)
    800021e6:	ff3791e3          	bne	a5,s3,800021c8 <wakeup+0x2a>
    800021ea:	709c                	ld	a5,32(s1)
    800021ec:	fd479ee3          	bne	a5,s4,800021c8 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021f0:	0154ac23          	sw	s5,24(s1)
    800021f4:	bfd1                	j	800021c8 <wakeup+0x2a>
    }
  }
}
    800021f6:	70e2                	ld	ra,56(sp)
    800021f8:	7442                	ld	s0,48(sp)
    800021fa:	74a2                	ld	s1,40(sp)
    800021fc:	7902                	ld	s2,32(sp)
    800021fe:	69e2                	ld	s3,24(sp)
    80002200:	6a42                	ld	s4,16(sp)
    80002202:	6aa2                	ld	s5,8(sp)
    80002204:	6121                	addi	sp,sp,64
    80002206:	8082                	ret

0000000080002208 <reparent>:
{
    80002208:	7179                	addi	sp,sp,-48
    8000220a:	f406                	sd	ra,40(sp)
    8000220c:	f022                	sd	s0,32(sp)
    8000220e:	ec26                	sd	s1,24(sp)
    80002210:	e84a                	sd	s2,16(sp)
    80002212:	e44e                	sd	s3,8(sp)
    80002214:	e052                	sd	s4,0(sp)
    80002216:	1800                	addi	s0,sp,48
    80002218:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221a:	0000e497          	auipc	s1,0xe
    8000221e:	b8e48493          	addi	s1,s1,-1138 # 8000fda8 <proc>
      pp->parent = initproc;
    80002222:	00005a17          	auipc	s4,0x5
    80002226:	64ea0a13          	addi	s4,s4,1614 # 80007870 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222a:	00015997          	auipc	s3,0x15
    8000222e:	d7e98993          	addi	s3,s3,-642 # 80016fa8 <tickslock>
    80002232:	a029                	j	8000223c <reparent+0x34>
    80002234:	1c848493          	addi	s1,s1,456
    80002238:	01348b63          	beq	s1,s3,8000224e <reparent+0x46>
    if(pp->parent == p){
    8000223c:	7c9c                	ld	a5,56(s1)
    8000223e:	ff279be3          	bne	a5,s2,80002234 <reparent+0x2c>
      pp->parent = initproc;
    80002242:	000a3503          	ld	a0,0(s4)
    80002246:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002248:	f57ff0ef          	jal	8000219e <wakeup>
    8000224c:	b7e5                	j	80002234 <reparent+0x2c>
}
    8000224e:	70a2                	ld	ra,40(sp)
    80002250:	7402                	ld	s0,32(sp)
    80002252:	64e2                	ld	s1,24(sp)
    80002254:	6942                	ld	s2,16(sp)
    80002256:	69a2                	ld	s3,8(sp)
    80002258:	6a02                	ld	s4,0(sp)
    8000225a:	6145                	addi	sp,sp,48
    8000225c:	8082                	ret

000000008000225e <kexit>:
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	e052                	sd	s4,0(sp)
    8000226c:	1800                	addi	s0,sp,48
    8000226e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002270:	e5eff0ef          	jal	800018ce <myproc>
    80002274:	89aa                	mv	s3,a0
  if(p == initproc)
    80002276:	00005797          	auipc	a5,0x5
    8000227a:	5fa7b783          	ld	a5,1530(a5) # 80007870 <initproc>
    8000227e:	0d050493          	addi	s1,a0,208
    80002282:	15050913          	addi	s2,a0,336
    80002286:	00a79f63          	bne	a5,a0,800022a4 <kexit+0x46>
    panic("init exiting");
    8000228a:	00005517          	auipc	a0,0x5
    8000228e:	f5650513          	addi	a0,a0,-170 # 800071e0 <etext+0x1e0>
    80002292:	d4efe0ef          	jal	800007e0 <panic>
      fileclose(f);
    80002296:	2fa020ef          	jal	80004590 <fileclose>
      p->ofile[fd] = 0;
    8000229a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000229e:	04a1                	addi	s1,s1,8
    800022a0:	01248563          	beq	s1,s2,800022aa <kexit+0x4c>
    if(p->ofile[fd]){
    800022a4:	6088                	ld	a0,0(s1)
    800022a6:	f965                	bnez	a0,80002296 <kexit+0x38>
    800022a8:	bfdd                	j	8000229e <kexit+0x40>
  begin_op();
    800022aa:	6db010ef          	jal	80004184 <begin_op>
  iput(p->cwd);
    800022ae:	1509b503          	ld	a0,336(s3)
    800022b2:	66a010ef          	jal	8000391c <iput>
  end_op();
    800022b6:	739010ef          	jal	800041ee <end_op>
  p->cwd = 0;
    800022ba:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022be:	0000d497          	auipc	s1,0xd
    800022c2:	6d248493          	addi	s1,s1,1746 # 8000f990 <wait_lock>
    800022c6:	8526                	mv	a0,s1
    800022c8:	907fe0ef          	jal	80000bce <acquire>
  reparent(p);
    800022cc:	854e                	mv	a0,s3
    800022ce:	f3bff0ef          	jal	80002208 <reparent>
  wakeup(p->parent);
    800022d2:	0389b503          	ld	a0,56(s3)
    800022d6:	ec9ff0ef          	jal	8000219e <wakeup>
  acquire(&p->lock);
    800022da:	854e                	mv	a0,s3
    800022dc:	8f3fe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    800022e0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022e4:	4795                	li	a5,5
    800022e6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	97bfe0ef          	jal	80000c66 <release>
  sched();
    800022f0:	d79ff0ef          	jal	80002068 <sched>
  panic("zombie exit");
    800022f4:	00005517          	auipc	a0,0x5
    800022f8:	efc50513          	addi	a0,a0,-260 # 800071f0 <etext+0x1f0>
    800022fc:	ce4fe0ef          	jal	800007e0 <panic>

0000000080002300 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002300:	7179                	addi	sp,sp,-48
    80002302:	f406                	sd	ra,40(sp)
    80002304:	f022                	sd	s0,32(sp)
    80002306:	ec26                	sd	s1,24(sp)
    80002308:	e84a                	sd	s2,16(sp)
    8000230a:	e44e                	sd	s3,8(sp)
    8000230c:	1800                	addi	s0,sp,48
    8000230e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002310:	0000e497          	auipc	s1,0xe
    80002314:	a9848493          	addi	s1,s1,-1384 # 8000fda8 <proc>
    80002318:	00015997          	auipc	s3,0x15
    8000231c:	c9098993          	addi	s3,s3,-880 # 80016fa8 <tickslock>
    acquire(&p->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	8adfe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    80002326:	589c                	lw	a5,48(s1)
    80002328:	01278b63          	beq	a5,s2,8000233e <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	939fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002332:	1c848493          	addi	s1,s1,456
    80002336:	ff3495e3          	bne	s1,s3,80002320 <kkill+0x20>
  }
  return -1;
    8000233a:	557d                	li	a0,-1
    8000233c:	a819                	j	80002352 <kkill+0x52>
      p->killed = 1;
    8000233e:	4785                	li	a5,1
    80002340:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002342:	4c98                	lw	a4,24(s1)
    80002344:	4789                	li	a5,2
    80002346:	00f70d63          	beq	a4,a5,80002360 <kkill+0x60>
      release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	91bfe0ef          	jal	80000c66 <release>
      return 0;
    80002350:	4501                	li	a0,0
}
    80002352:	70a2                	ld	ra,40(sp)
    80002354:	7402                	ld	s0,32(sp)
    80002356:	64e2                	ld	s1,24(sp)
    80002358:	6942                	ld	s2,16(sp)
    8000235a:	69a2                	ld	s3,8(sp)
    8000235c:	6145                	addi	sp,sp,48
    8000235e:	8082                	ret
        p->state = RUNNABLE;
    80002360:	478d                	li	a5,3
    80002362:	cc9c                	sw	a5,24(s1)
    80002364:	b7dd                	j	8000234a <kkill+0x4a>

0000000080002366 <setkilled>:

void
setkilled(struct proc *p)
{
    80002366:	1101                	addi	sp,sp,-32
    80002368:	ec06                	sd	ra,24(sp)
    8000236a:	e822                	sd	s0,16(sp)
    8000236c:	e426                	sd	s1,8(sp)
    8000236e:	1000                	addi	s0,sp,32
    80002370:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002372:	85dfe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    80002376:	4785                	li	a5,1
    80002378:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	8ebfe0ef          	jal	80000c66 <release>
}
    80002380:	60e2                	ld	ra,24(sp)
    80002382:	6442                	ld	s0,16(sp)
    80002384:	64a2                	ld	s1,8(sp)
    80002386:	6105                	addi	sp,sp,32
    80002388:	8082                	ret

000000008000238a <killed>:

int
killed(struct proc *p)
{
    8000238a:	1101                	addi	sp,sp,-32
    8000238c:	ec06                	sd	ra,24(sp)
    8000238e:	e822                	sd	s0,16(sp)
    80002390:	e426                	sd	s1,8(sp)
    80002392:	e04a                	sd	s2,0(sp)
    80002394:	1000                	addi	s0,sp,32
    80002396:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002398:	837fe0ef          	jal	80000bce <acquire>
  k = p->killed;
    8000239c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	8c5fe0ef          	jal	80000c66 <release>
  return k;
}
    800023a6:	854a                	mv	a0,s2
    800023a8:	60e2                	ld	ra,24(sp)
    800023aa:	6442                	ld	s0,16(sp)
    800023ac:	64a2                	ld	s1,8(sp)
    800023ae:	6902                	ld	s2,0(sp)
    800023b0:	6105                	addi	sp,sp,32
    800023b2:	8082                	ret

00000000800023b4 <kwait>:
{
    800023b4:	715d                	addi	sp,sp,-80
    800023b6:	e486                	sd	ra,72(sp)
    800023b8:	e0a2                	sd	s0,64(sp)
    800023ba:	fc26                	sd	s1,56(sp)
    800023bc:	f84a                	sd	s2,48(sp)
    800023be:	f44e                	sd	s3,40(sp)
    800023c0:	f052                	sd	s4,32(sp)
    800023c2:	ec56                	sd	s5,24(sp)
    800023c4:	e85a                	sd	s6,16(sp)
    800023c6:	e45e                	sd	s7,8(sp)
    800023c8:	e062                	sd	s8,0(sp)
    800023ca:	0880                	addi	s0,sp,80
    800023cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ce:	d00ff0ef          	jal	800018ce <myproc>
    800023d2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023d4:	0000d517          	auipc	a0,0xd
    800023d8:	5bc50513          	addi	a0,a0,1468 # 8000f990 <wait_lock>
    800023dc:	ff2fe0ef          	jal	80000bce <acquire>
    havekids = 0;
    800023e0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023e2:	4a15                	li	s4,5
        havekids = 1;
    800023e4:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e6:	00015997          	auipc	s3,0x15
    800023ea:	bc298993          	addi	s3,s3,-1086 # 80016fa8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023ee:	0000dc17          	auipc	s8,0xd
    800023f2:	5a2c0c13          	addi	s8,s8,1442 # 8000f990 <wait_lock>
    800023f6:	a871                	j	80002492 <kwait+0xde>
          pid = pp->pid;
    800023f8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023fc:	000b0c63          	beqz	s6,80002414 <kwait+0x60>
    80002400:	4691                	li	a3,4
    80002402:	02c48613          	addi	a2,s1,44
    80002406:	85da                	mv	a1,s6
    80002408:	05093503          	ld	a0,80(s2)
    8000240c:	9d6ff0ef          	jal	800015e2 <copyout>
    80002410:	02054b63          	bltz	a0,80002446 <kwait+0x92>
          freeproc(pp);
    80002414:	8526                	mv	a0,s1
    80002416:	e88ff0ef          	jal	80001a9e <freeproc>
          release(&pp->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	84bfe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    80002420:	0000d517          	auipc	a0,0xd
    80002424:	57050513          	addi	a0,a0,1392 # 8000f990 <wait_lock>
    80002428:	83ffe0ef          	jal	80000c66 <release>
}
    8000242c:	854e                	mv	a0,s3
    8000242e:	60a6                	ld	ra,72(sp)
    80002430:	6406                	ld	s0,64(sp)
    80002432:	74e2                	ld	s1,56(sp)
    80002434:	7942                	ld	s2,48(sp)
    80002436:	79a2                	ld	s3,40(sp)
    80002438:	7a02                	ld	s4,32(sp)
    8000243a:	6ae2                	ld	s5,24(sp)
    8000243c:	6b42                	ld	s6,16(sp)
    8000243e:	6ba2                	ld	s7,8(sp)
    80002440:	6c02                	ld	s8,0(sp)
    80002442:	6161                	addi	sp,sp,80
    80002444:	8082                	ret
            release(&pp->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	81ffe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    8000244c:	0000d517          	auipc	a0,0xd
    80002450:	54450513          	addi	a0,a0,1348 # 8000f990 <wait_lock>
    80002454:	813fe0ef          	jal	80000c66 <release>
            return -1;
    80002458:	59fd                	li	s3,-1
    8000245a:	bfc9                	j	8000242c <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245c:	1c848493          	addi	s1,s1,456
    80002460:	03348063          	beq	s1,s3,80002480 <kwait+0xcc>
      if(pp->parent == p){
    80002464:	7c9c                	ld	a5,56(s1)
    80002466:	ff279be3          	bne	a5,s2,8000245c <kwait+0xa8>
        acquire(&pp->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	f62fe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    80002470:	4c9c                	lw	a5,24(s1)
    80002472:	f94783e3          	beq	a5,s4,800023f8 <kwait+0x44>
        release(&pp->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	feefe0ef          	jal	80000c66 <release>
        havekids = 1;
    8000247c:	8756                	mv	a4,s5
    8000247e:	bff9                	j	8000245c <kwait+0xa8>
    if(!havekids || killed(p)){
    80002480:	cf19                	beqz	a4,8000249e <kwait+0xea>
    80002482:	854a                	mv	a0,s2
    80002484:	f07ff0ef          	jal	8000238a <killed>
    80002488:	e919                	bnez	a0,8000249e <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000248a:	85e2                	mv	a1,s8
    8000248c:	854a                	mv	a0,s2
    8000248e:	cc1ff0ef          	jal	8000214e <sleep>
    havekids = 0;
    80002492:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002494:	0000e497          	auipc	s1,0xe
    80002498:	91448493          	addi	s1,s1,-1772 # 8000fda8 <proc>
    8000249c:	b7e1                	j	80002464 <kwait+0xb0>
      release(&wait_lock);
    8000249e:	0000d517          	auipc	a0,0xd
    800024a2:	4f250513          	addi	a0,a0,1266 # 8000f990 <wait_lock>
    800024a6:	fc0fe0ef          	jal	80000c66 <release>
      return -1;
    800024aa:	59fd                	li	s3,-1
    800024ac:	b741                	j	8000242c <kwait+0x78>

00000000800024ae <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	84aa                	mv	s1,a0
    800024c0:	892e                	mv	s2,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	c08ff0ef          	jal	800018ce <myproc>
  if(user_dst){
    800024ca:	cc99                	beqz	s1,800024e8 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	90eff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d8:	70a2                	ld	ra,40(sp)
    800024da:	7402                	ld	s0,32(sp)
    800024dc:	64e2                	ld	s1,24(sp)
    800024de:	6942                	ld	s2,16(sp)
    800024e0:	69a2                	ld	s3,8(sp)
    800024e2:	6a02                	ld	s4,0(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret
    memmove((char *)dst, src, len);
    800024e8:	000a061b          	sext.w	a2,s4
    800024ec:	85ce                	mv	a1,s3
    800024ee:	854a                	mv	a0,s2
    800024f0:	80ffe0ef          	jal	80000cfe <memmove>
    return 0;
    800024f4:	8526                	mv	a0,s1
    800024f6:	b7cd                	j	800024d8 <either_copyout+0x2a>

00000000800024f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
    8000250a:	84ae                	mv	s1,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	bbeff0ef          	jal	800018ce <myproc>
  if(user_src){
    80002514:	cc99                	beqz	s1,80002532 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	9a8ff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002522:	70a2                	ld	ra,40(sp)
    80002524:	7402                	ld	s0,32(sp)
    80002526:	64e2                	ld	s1,24(sp)
    80002528:	6942                	ld	s2,16(sp)
    8000252a:	69a2                	ld	s3,8(sp)
    8000252c:	6a02                	ld	s4,0(sp)
    8000252e:	6145                	addi	sp,sp,48
    80002530:	8082                	ret
    memmove(dst, (char*)src, len);
    80002532:	000a061b          	sext.w	a2,s4
    80002536:	85ce                	mv	a1,s3
    80002538:	854a                	mv	a0,s2
    8000253a:	fc4fe0ef          	jal	80000cfe <memmove>
    return 0;
    8000253e:	8526                	mv	a0,s1
    80002540:	b7cd                	j	80002522 <either_copyin+0x2a>

0000000080002542 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002542:	715d                	addi	sp,sp,-80
    80002544:	e486                	sd	ra,72(sp)
    80002546:	e0a2                	sd	s0,64(sp)
    80002548:	fc26                	sd	s1,56(sp)
    8000254a:	f84a                	sd	s2,48(sp)
    8000254c:	f44e                	sd	s3,40(sp)
    8000254e:	f052                	sd	s4,32(sp)
    80002550:	ec56                	sd	s5,24(sp)
    80002552:	e85a                	sd	s6,16(sp)
    80002554:	e45e                	sd	s7,8(sp)
    80002556:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002558:	00005517          	auipc	a0,0x5
    8000255c:	b2050513          	addi	a0,a0,-1248 # 80007078 <etext+0x78>
    80002560:	f9bfd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002564:	0000e497          	auipc	s1,0xe
    80002568:	99c48493          	addi	s1,s1,-1636 # 8000ff00 <proc+0x158>
    8000256c:	00015917          	auipc	s2,0x15
    80002570:	b9490913          	addi	s2,s2,-1132 # 80017100 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002574:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002576:	00005997          	auipc	s3,0x5
    8000257a:	c8a98993          	addi	s3,s3,-886 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    8000257e:	00005a97          	auipc	s5,0x5
    80002582:	c8aa8a93          	addi	s5,s5,-886 # 80007208 <etext+0x208>
    printf("\n");
    80002586:	00005a17          	auipc	s4,0x5
    8000258a:	af2a0a13          	addi	s4,s4,-1294 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	00005b97          	auipc	s7,0x5
    80002592:	19ab8b93          	addi	s7,s7,410 # 80007728 <states.0>
    80002596:	a829                	j	800025b0 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002598:	ed86a583          	lw	a1,-296(a3)
    8000259c:	8556                	mv	a0,s5
    8000259e:	f5dfd0ef          	jal	800004fa <printf>
    printf("\n");
    800025a2:	8552                	mv	a0,s4
    800025a4:	f57fd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a8:	1c848493          	addi	s1,s1,456
    800025ac:	03248263          	beq	s1,s2,800025d0 <procdump+0x8e>
    if(p->state == UNUSED)
    800025b0:	86a6                	mv	a3,s1
    800025b2:	ec04a783          	lw	a5,-320(s1)
    800025b6:	dbed                	beqz	a5,800025a8 <procdump+0x66>
      state = "???";
    800025b8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	fcfb6fe3          	bltu	s6,a5,80002598 <procdump+0x56>
    800025be:	02079713          	slli	a4,a5,0x20
    800025c2:	01d75793          	srli	a5,a4,0x1d
    800025c6:	97de                	add	a5,a5,s7
    800025c8:	6390                	ld	a2,0(a5)
    800025ca:	f679                	bnez	a2,80002598 <procdump+0x56>
      state = "???";
    800025cc:	864e                	mv	a2,s3
    800025ce:	b7e9                	j	80002598 <procdump+0x56>
  }
}
    800025d0:	60a6                	ld	ra,72(sp)
    800025d2:	6406                	ld	s0,64(sp)
    800025d4:	74e2                	ld	s1,56(sp)
    800025d6:	7942                	ld	s2,48(sp)
    800025d8:	79a2                	ld	s3,40(sp)
    800025da:	7a02                	ld	s4,32(sp)
    800025dc:	6ae2                	ld	s5,24(sp)
    800025de:	6b42                	ld	s6,16(sp)
    800025e0:	6ba2                	ld	s7,8(sp)
    800025e2:	6161                	addi	sp,sp,80
    800025e4:	8082                	ret

00000000800025e6 <promote_all>:


// Promote all processes to highest priority level (0)
void promote_all(void){
    800025e6:	1101                	addi	sp,sp,-32
    800025e8:	ec06                	sd	ra,24(sp)
    800025ea:	e822                	sd	s0,16(sp)
    800025ec:	e426                	sd	s1,8(sp)
    800025ee:	e04a                	sd	s2,0(sp)
    800025f0:	1000                	addi	s0,sp,32
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	0000d497          	auipc	s1,0xd
    800025f6:	7b648493          	addi	s1,s1,1974 # 8000fda8 <proc>
    800025fa:	00015917          	auipc	s2,0x15
    800025fe:	9ae90913          	addi	s2,s2,-1618 # 80016fa8 <tickslock>
    80002602:	a801                	j	80002612 <promote_all+0x2c>
    acquire(&p->lock);
    if(p->state != UNUSED){
        p->priority = 0;
        p->ticks_used = 0;
    }
    release(&p->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	e60fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000260a:	1c848493          	addi	s1,s1,456
    8000260e:	01248c63          	beq	s1,s2,80002626 <promote_all+0x40>
    acquire(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	dbafe0ef          	jal	80000bce <acquire>
    if(p->state != UNUSED){
    80002618:	4c9c                	lw	a5,24(s1)
    8000261a:	d7ed                	beqz	a5,80002604 <promote_all+0x1e>
        p->priority = 0;
    8000261c:	1604a423          	sw	zero,360(s1)
        p->ticks_used = 0;
    80002620:	1604a623          	sw	zero,364(s1)
    80002624:	b7c5                	j	80002604 <promote_all+0x1e>
  }
}
    80002626:	60e2                	ld	ra,24(sp)
    80002628:	6442                	ld	s0,16(sp)
    8000262a:	64a2                	ld	s1,8(sp)
    8000262c:	6902                	ld	s2,0(sp)
    8000262e:	6105                	addi	sp,sp,32
    80002630:	8082                	ret

0000000080002632 <has_higher_priority>:

// Check if there is any runnable process with higher priority
int has_higher_priority(int priority) {
    80002632:	1141                	addi	sp,sp,-16
    80002634:	e422                	sd	s0,8(sp)
    80002636:	0800                	addi	s0,sp,16
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    80002638:	0000d797          	auipc	a5,0xd
    8000263c:	77078793          	addi	a5,a5,1904 # 8000fda8 <proc>
    if(p->state == RUNNABLE && p->priority < priority){
    80002640:	468d                	li	a3,3
  for(p = proc; p < &proc[NPROC]; p++){
    80002642:	00015617          	auipc	a2,0x15
    80002646:	96660613          	addi	a2,a2,-1690 # 80016fa8 <tickslock>
    8000264a:	a029                	j	80002654 <has_higher_priority+0x22>
    8000264c:	1c878793          	addi	a5,a5,456
    80002650:	00c78d63          	beq	a5,a2,8000266a <has_higher_priority+0x38>
    if(p->state == RUNNABLE && p->priority < priority){
    80002654:	4f98                	lw	a4,24(a5)
    80002656:	fed71be3          	bne	a4,a3,8000264c <has_higher_priority+0x1a>
    8000265a:	1687a703          	lw	a4,360(a5)
    8000265e:	fea757e3          	bge	a4,a0,8000264c <has_higher_priority+0x1a>
      return 1;
    80002662:	4505                	li	a0,1
    }
  }
  return 0;
    80002664:	6422                	ld	s0,8(sp)
    80002666:	0141                	addi	sp,sp,16
    80002668:	8082                	ret
  return 0;
    8000266a:	4501                	li	a0,0
    8000266c:	bfe5                	j	80002664 <has_higher_priority+0x32>

000000008000266e <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    8000266e:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002672:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002676:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002678:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    8000267a:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    8000267e:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002682:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002686:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    8000268a:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    8000268e:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002692:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002696:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    8000269a:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    8000269e:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800026a2:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800026a6:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800026aa:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800026ac:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800026ae:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800026b2:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    800026b6:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800026ba:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800026be:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800026c2:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800026c6:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800026ca:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800026ce:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800026d2:	0685bd83          	ld	s11,104(a1)
        
        ret
    800026d6:	8082                	ret

00000000800026d8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d8:	1141                	addi	sp,sp,-16
    800026da:	e406                	sd	ra,8(sp)
    800026dc:	e022                	sd	s0,0(sp)
    800026de:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026e0:	00005597          	auipc	a1,0x5
    800026e4:	b6858593          	addi	a1,a1,-1176 # 80007248 <etext+0x248>
    800026e8:	00015517          	auipc	a0,0x15
    800026ec:	8c050513          	addi	a0,a0,-1856 # 80016fa8 <tickslock>
    800026f0:	c5efe0ef          	jal	80000b4e <initlock>
}
    800026f4:	60a2                	ld	ra,8(sp)
    800026f6:	6402                	ld	s0,0(sp)
    800026f8:	0141                	addi	sp,sp,16
    800026fa:	8082                	ret

00000000800026fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fc:	1141                	addi	sp,sp,-16
    800026fe:	e422                	sd	s0,8(sp)
    80002700:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002702:	00003797          	auipc	a5,0x3
    80002706:	20e78793          	addi	a5,a5,526 # 80005910 <kernelvec>
    8000270a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270e:	6422                	ld	s0,8(sp)
    80002710:	0141                	addi	sp,sp,16
    80002712:	8082                	ret

0000000080002714 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002714:	1141                	addi	sp,sp,-16
    80002716:	e406                	sd	ra,8(sp)
    80002718:	e022                	sd	s0,0(sp)
    8000271a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271c:	9b2ff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002720:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002724:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002726:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272a:	04000737          	lui	a4,0x4000
    8000272e:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80002730:	0732                	slli	a4,a4,0xc
    80002732:	00004797          	auipc	a5,0x4
    80002736:	8ce78793          	addi	a5,a5,-1842 # 80006000 <_trampoline>
    8000273a:	00004697          	auipc	a3,0x4
    8000273e:	8c668693          	addi	a3,a3,-1850 # 80006000 <_trampoline>
    80002742:	8f95                	sub	a5,a5,a3
    80002744:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002746:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274c:	18002773          	csrr	a4,satp
    80002750:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002752:	6d38                	ld	a4,88(a0)
    80002754:	613c                	ld	a5,64(a0)
    80002756:	6685                	lui	a3,0x1
    80002758:	97b6                	add	a5,a5,a3
    8000275a:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275c:	6d3c                	ld	a5,88(a0)
    8000275e:	00000717          	auipc	a4,0x0
    80002762:	13870713          	addi	a4,a4,312 # 80002896 <usertrap>
    80002766:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002768:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276a:	8712                	mv	a4,tp
    8000276c:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276e:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002772:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002776:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277a:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002780:	6f9c                	ld	a5,24(a5)
    80002782:	14179073          	csrw	sepc,a5
}
    80002786:	60a2                	ld	ra,8(sp)
    80002788:	6402                	ld	s0,0(sp)
    8000278a:	0141                	addi	sp,sp,16
    8000278c:	8082                	ret

000000008000278e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000278e:	1101                	addi	sp,sp,-32
    80002790:	ec06                	sd	ra,24(sp)
    80002792:	e822                	sd	s0,16(sp)
    80002794:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002796:	90cff0ef          	jal	800018a2 <cpuid>
    8000279a:	c131                	beqz	a0,800027de <clockintr+0x50>
    wakeup(&ticks);
    release(&tickslock);
  }

  // --- EDR Tier-1 Rate-based Detector ---
  struct proc *p = myproc();
    8000279c:	932ff0ef          	jal	800018ce <myproc>
  if(p && p->fork_times[p->fork_times_idx] != 0){
    800027a0:	c115                	beqz	a0,800027c4 <clockintr+0x36>
    800027a2:	1a856783          	lwu	a5,424(a0)
    800027a6:	02e78793          	addi	a5,a5,46
    800027aa:	078e                	slli	a5,a5,0x3
    800027ac:	97aa                	add	a5,a5,a0
    800027ae:	679c                	ld	a5,8(a5)
    800027b0:	cb91                	beqz	a5,800027c4 <clockintr+0x36>
    uint64 oldest = p->fork_times[p->fork_times_idx];
    if(ticks - oldest <= EDR_FORK_RATE_WINDOW_TICKS){
    800027b2:	00005717          	auipc	a4,0x5
    800027b6:	0c676703          	lwu	a4,198(a4) # 80007878 <ticks>
    800027ba:	40f707b3          	sub	a5,a4,a5
    800027be:	4729                	li	a4,10
    800027c0:	04f77563          	bgeu	a4,a5,8000280a <clockintr+0x7c>
  asm volatile("csrr %0, time" : "=r" (x) );
    800027c4:	c01027f3          	rdtime	a5
  // --------------------------------------

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800027c8:	000f4737          	lui	a4,0xf4
    800027cc:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800027d0:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800027d2:	14d79073          	csrw	stimecmp,a5
}
    800027d6:	60e2                	ld	ra,24(sp)
    800027d8:	6442                	ld	s0,16(sp)
    800027da:	6105                	addi	sp,sp,32
    800027dc:	8082                	ret
    800027de:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    800027e0:	00014497          	auipc	s1,0x14
    800027e4:	7c848493          	addi	s1,s1,1992 # 80016fa8 <tickslock>
    800027e8:	8526                	mv	a0,s1
    800027ea:	be4fe0ef          	jal	80000bce <acquire>
    ticks++;
    800027ee:	00005517          	auipc	a0,0x5
    800027f2:	08a50513          	addi	a0,a0,138 # 80007878 <ticks>
    800027f6:	411c                	lw	a5,0(a0)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800027fc:	9a3ff0ef          	jal	8000219e <wakeup>
    release(&tickslock);
    80002800:	8526                	mv	a0,s1
    80002802:	c64fe0ef          	jal	80000c66 <release>
    80002806:	64a2                	ld	s1,8(sp)
    80002808:	bf51                	j	8000279c <clockintr+0xe>
      p->is_sandboxed = 1;
    8000280a:	4785                	li	a5,1
    8000280c:	1af50823          	sb	a5,432(a0)
      p->need_propagation = 1;
    80002810:	1cf50023          	sb	a5,448(a0)
      __sync_synchronize();
    80002814:	0ff0000f          	fence
      edr_work_pending = 1;
    80002818:	00005717          	auipc	a4,0x5
    8000281c:	04f72823          	sw	a5,80(a4) # 80007868 <edr_work_pending>
    80002820:	b755                	j	800027c4 <clockintr+0x36>

0000000080002822 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002822:	1101                	addi	sp,sp,-32
    80002824:	ec06                	sd	ra,24(sp)
    80002826:	e822                	sd	s0,16(sp)
    80002828:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000282a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    8000282e:	57fd                	li	a5,-1
    80002830:	17fe                	slli	a5,a5,0x3f
    80002832:	07a5                	addi	a5,a5,9
    80002834:	00f70c63          	beq	a4,a5,8000284c <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002838:	57fd                	li	a5,-1
    8000283a:	17fe                	slli	a5,a5,0x3f
    8000283c:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    8000283e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002840:	04f70763          	beq	a4,a5,8000288e <devintr+0x6c>
  }
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	6105                	addi	sp,sp,32
    8000284a:	8082                	ret
    8000284c:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    8000284e:	16e030ef          	jal	800059bc <plic_claim>
    80002852:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002854:	47a9                	li	a5,10
    80002856:	00f50963          	beq	a0,a5,80002868 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    8000285a:	4785                	li	a5,1
    8000285c:	00f50963          	beq	a0,a5,8000286e <devintr+0x4c>
    return 1;
    80002860:	4505                	li	a0,1
    } else if(irq){
    80002862:	e889                	bnez	s1,80002874 <devintr+0x52>
    80002864:	64a2                	ld	s1,8(sp)
    80002866:	bff9                	j	80002844 <devintr+0x22>
      uartintr();
    80002868:	948fe0ef          	jal	800009b0 <uartintr>
    if(irq)
    8000286c:	a819                	j	80002882 <devintr+0x60>
      virtio_disk_intr();
    8000286e:	614030ef          	jal	80005e82 <virtio_disk_intr>
    if(irq)
    80002872:	a801                	j	80002882 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    80002874:	85a6                	mv	a1,s1
    80002876:	00005517          	auipc	a0,0x5
    8000287a:	9da50513          	addi	a0,a0,-1574 # 80007250 <etext+0x250>
    8000287e:	c7dfd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    80002882:	8526                	mv	a0,s1
    80002884:	158030ef          	jal	800059dc <plic_complete>
    return 1;
    80002888:	4505                	li	a0,1
    8000288a:	64a2                	ld	s1,8(sp)
    8000288c:	bf65                	j	80002844 <devintr+0x22>
    clockintr();
    8000288e:	f01ff0ef          	jal	8000278e <clockintr>
    return 2;
    80002892:	4509                	li	a0,2
    80002894:	bf45                	j	80002844 <devintr+0x22>

0000000080002896 <usertrap>:
{
    80002896:	1101                	addi	sp,sp,-32
    80002898:	ec06                	sd	ra,24(sp)
    8000289a:	e822                	sd	s0,16(sp)
    8000289c:	e426                	sd	s1,8(sp)
    8000289e:	e04a                	sd	s2,0(sp)
    800028a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a6:	1007f793          	andi	a5,a5,256
    800028aa:	eba5                	bnez	a5,8000291a <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ac:	00003797          	auipc	a5,0x3
    800028b0:	06478793          	addi	a5,a5,100 # 80005910 <kernelvec>
    800028b4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b8:	816ff0ef          	jal	800018ce <myproc>
    800028bc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028be:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c0:	14102773          	csrr	a4,sepc
    800028c4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ca:	47a1                	li	a5,8
    800028cc:	04f70d63          	beq	a4,a5,80002926 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800028d0:	f53ff0ef          	jal	80002822 <devintr>
    800028d4:	892a                	mv	s2,a0
    800028d6:	e945                	bnez	a0,80002986 <usertrap+0xf0>
    800028d8:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800028dc:	47bd                	li	a5,15
    800028de:	08f70863          	beq	a4,a5,8000296e <usertrap+0xd8>
    800028e2:	14202773          	csrr	a4,scause
    800028e6:	47b5                	li	a5,13
    800028e8:	08f70363          	beq	a4,a5,8000296e <usertrap+0xd8>
    800028ec:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800028f0:	5890                	lw	a2,48(s1)
    800028f2:	00005517          	auipc	a0,0x5
    800028f6:	99e50513          	addi	a0,a0,-1634 # 80007290 <etext+0x290>
    800028fa:	c01fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002902:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002906:	00005517          	auipc	a0,0x5
    8000290a:	9ba50513          	addi	a0,a0,-1606 # 800072c0 <etext+0x2c0>
    8000290e:	bedfd0ef          	jal	800004fa <printf>
    setkilled(p);
    80002912:	8526                	mv	a0,s1
    80002914:	a53ff0ef          	jal	80002366 <setkilled>
    80002918:	a035                	j	80002944 <usertrap+0xae>
    panic("usertrap: not from user mode");
    8000291a:	00005517          	auipc	a0,0x5
    8000291e:	95650513          	addi	a0,a0,-1706 # 80007270 <etext+0x270>
    80002922:	ebffd0ef          	jal	800007e0 <panic>
    if(killed(p))
    80002926:	a65ff0ef          	jal	8000238a <killed>
    8000292a:	ed15                	bnez	a0,80002966 <usertrap+0xd0>
    p->trapframe->epc += 4;
    8000292c:	6cb8                	ld	a4,88(s1)
    8000292e:	6f1c                	ld	a5,24(a4)
    80002930:	0791                	addi	a5,a5,4
    80002932:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002934:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002938:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000293c:	10079073          	csrw	sstatus,a5
    syscall();
    80002940:	3aa000ef          	jal	80002cea <syscall>
  if(killed(p))
    80002944:	8526                	mv	a0,s1
    80002946:	a45ff0ef          	jal	8000238a <killed>
    8000294a:	e139                	bnez	a0,80002990 <usertrap+0xfa>
  prepare_return();
    8000294c:	dc9ff0ef          	jal	80002714 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80002950:	68a8                	ld	a0,80(s1)
    80002952:	8131                	srli	a0,a0,0xc
    80002954:	57fd                	li	a5,-1
    80002956:	17fe                	slli	a5,a5,0x3f
    80002958:	8d5d                	or	a0,a0,a5
}
    8000295a:	60e2                	ld	ra,24(sp)
    8000295c:	6442                	ld	s0,16(sp)
    8000295e:	64a2                	ld	s1,8(sp)
    80002960:	6902                	ld	s2,0(sp)
    80002962:	6105                	addi	sp,sp,32
    80002964:	8082                	ret
      kexit(-1);
    80002966:	557d                	li	a0,-1
    80002968:	8f7ff0ef          	jal	8000225e <kexit>
    8000296c:	b7c1                	j	8000292c <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296e:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002972:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002976:	164d                	addi	a2,a2,-13
    80002978:	00163613          	seqz	a2,a2
    8000297c:	68a8                	ld	a0,80(s1)
    8000297e:	be3fe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002982:	f169                	bnez	a0,80002944 <usertrap+0xae>
    80002984:	b7a5                	j	800028ec <usertrap+0x56>
  if(killed(p))
    80002986:	8526                	mv	a0,s1
    80002988:	a03ff0ef          	jal	8000238a <killed>
    8000298c:	c511                	beqz	a0,80002998 <usertrap+0x102>
    8000298e:	a011                	j	80002992 <usertrap+0xfc>
    80002990:	4901                	li	s2,0
    kexit(-1);
    80002992:	557d                	li	a0,-1
    80002994:	8cbff0ef          	jal	8000225e <kexit>
  if(which_dev == 2)
    80002998:	4789                	li	a5,2
    8000299a:	faf919e3          	bne	s2,a5,8000294c <usertrap+0xb6>
    struct proc *p = myproc();
    8000299e:	f31fe0ef          	jal	800018ce <myproc>
    if(p){
    800029a2:	c52d                	beqz	a0,80002a0c <usertrap+0x176>
      p->ticks_used++;
    800029a4:	16c52783          	lw	a5,364(a0)
    800029a8:	2785                	addiw	a5,a5,1
    800029aa:	0007871b          	sext.w	a4,a5
    800029ae:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    800029b2:	17452783          	lw	a5,372(a0)
    800029b6:	2785                	addiw	a5,a5,1
    800029b8:	16f52a23          	sw	a5,372(a0)
      p->cumulative_run_time++;
    800029bc:	1ac52783          	lw	a5,428(a0)
    800029c0:	2785                	addiw	a5,a5,1
    800029c2:	1af52623          	sw	a5,428(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    800029c6:	16852783          	lw	a5,360(a0)
    800029ca:	cfa1                	beqz	a5,80002a22 <usertrap+0x18c>
      else if(p->priority == 1) quantum = QUANTUM_1;
    800029cc:	4685                	li	a3,1
    800029ce:	06d78d63          	beq	a5,a3,80002a48 <usertrap+0x1b2>
      if(p->ticks_used >= quantum){
    800029d2:	469d                	li	a3,7
    800029d4:	04e6da63          	bge	a3,a4,80002a28 <usertrap+0x192>
        if(p->priority < 2)
    800029d8:	4705                	li	a4,1
    800029da:	02f75563          	bge	a4,a5,80002a04 <usertrap+0x16e>
        p->ticks_used = 0;
    800029de:	16052623          	sw	zero,364(a0)
        p->cumulative_run_time = 0;
    800029e2:	1a052623          	sw	zero,428(a0)
    if(ticks % AGING_INTERVAL == 0){
    800029e6:	00005797          	auipc	a5,0x5
    800029ea:	e927a783          	lw	a5,-366(a5) # 80007878 <ticks>
    800029ee:	06400713          	li	a4,100
    800029f2:	02e7f7bb          	remuw	a5,a5,a4
    800029f6:	2781                	sext.w	a5,a5
    800029f8:	e399                	bnez	a5,800029fe <usertrap+0x168>
      promote_all();
    800029fa:	bedff0ef          	jal	800025e6 <promote_all>
      yield();
    800029fe:	f24ff0ef          	jal	80002122 <yield>
    80002a02:	b7a9                	j	8000294c <usertrap+0xb6>
          p->priority++;
    80002a04:	2785                	addiw	a5,a5,1
    80002a06:	16f52423          	sw	a5,360(a0)
    80002a0a:	bfd1                	j	800029de <usertrap+0x148>
    if(ticks % AGING_INTERVAL == 0){
    80002a0c:	00005797          	auipc	a5,0x5
    80002a10:	e6c7a783          	lw	a5,-404(a5) # 80007878 <ticks>
    80002a14:	06400713          	li	a4,100
    80002a18:	02e7f7bb          	remuw	a5,a5,a4
    80002a1c:	2781                	sext.w	a5,a5
    80002a1e:	f79d                	bnez	a5,8000294c <usertrap+0xb6>
    80002a20:	bfe9                	j	800029fa <usertrap+0x164>
      if(p->priority == 0) quantum = QUANTUM_0;
    80002a22:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    80002a24:	fed750e3          	bge	a4,a3,80002a04 <usertrap+0x16e>
      } else if(has_higher_priority(p->priority)){
    80002a28:	853e                	mv	a0,a5
    80002a2a:	c09ff0ef          	jal	80002632 <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002a2e:	00005797          	auipc	a5,0x5
    80002a32:	e4a7a783          	lw	a5,-438(a5) # 80007878 <ticks>
    80002a36:	06400713          	li	a4,100
    80002a3a:	02e7f7bb          	remuw	a5,a5,a4
    80002a3e:	2781                	sext.w	a5,a5
    80002a40:	dfcd                	beqz	a5,800029fa <usertrap+0x164>
    if(need_yield){
    80002a42:	f00505e3          	beqz	a0,8000294c <usertrap+0xb6>
    80002a46:	bf65                	j	800029fe <usertrap+0x168>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002a48:	4691                	li	a3,4
    80002a4a:	bfe9                	j	80002a24 <usertrap+0x18e>

0000000080002a4c <kerneltrap>:
{
    80002a4c:	7179                	addi	sp,sp,-48
    80002a4e:	f406                	sd	ra,40(sp)
    80002a50:	f022                	sd	s0,32(sp)
    80002a52:	ec26                	sd	s1,24(sp)
    80002a54:	e84a                	sd	s2,16(sp)
    80002a56:	e44e                	sd	s3,8(sp)
    80002a58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a66:	1004f793          	andi	a5,s1,256
    80002a6a:	c795                	beqz	a5,80002a96 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a72:	eb85                	bnez	a5,80002aa2 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002a74:	dafff0ef          	jal	80002822 <devintr>
    80002a78:	c91d                	beqz	a0,80002aae <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0){
    80002a7a:	4789                	li	a5,2
    80002a7c:	04f50a63          	beq	a0,a5,80002ad0 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a80:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a84:	10049073          	csrw	sstatus,s1
}
    80002a88:	70a2                	ld	ra,40(sp)
    80002a8a:	7402                	ld	s0,32(sp)
    80002a8c:	64e2                	ld	s1,24(sp)
    80002a8e:	6942                	ld	s2,16(sp)
    80002a90:	69a2                	ld	s3,8(sp)
    80002a92:	6145                	addi	sp,sp,48
    80002a94:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a96:	00005517          	auipc	a0,0x5
    80002a9a:	85250513          	addi	a0,a0,-1966 # 800072e8 <etext+0x2e8>
    80002a9e:	d43fd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aa2:	00005517          	auipc	a0,0x5
    80002aa6:	86e50513          	addi	a0,a0,-1938 # 80007310 <etext+0x310>
    80002aaa:	d37fd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab2:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002ab6:	85ce                	mv	a1,s3
    80002ab8:	00005517          	auipc	a0,0x5
    80002abc:	87850513          	addi	a0,a0,-1928 # 80007330 <etext+0x330>
    80002ac0:	a3bfd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    80002ac4:	00005517          	auipc	a0,0x5
    80002ac8:	89450513          	addi	a0,a0,-1900 # 80007358 <etext+0x358>
    80002acc:	d15fd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0){
    80002ad0:	dfffe0ef          	jal	800018ce <myproc>
    80002ad4:	d555                	beqz	a0,80002a80 <kerneltrap+0x34>
    struct proc *p = myproc();
    80002ad6:	df9fe0ef          	jal	800018ce <myproc>
    if(p){
    80002ada:	c52d                	beqz	a0,80002b44 <kerneltrap+0xf8>
      p->ticks_used++;
    80002adc:	16c52783          	lw	a5,364(a0)
    80002ae0:	2785                	addiw	a5,a5,1
    80002ae2:	0007871b          	sext.w	a4,a5
    80002ae6:	16f52623          	sw	a5,364(a0)
      p->total_runtime++;
    80002aea:	17452783          	lw	a5,372(a0)
    80002aee:	2785                	addiw	a5,a5,1
    80002af0:	16f52a23          	sw	a5,372(a0)
      p->cumulative_run_time++;
    80002af4:	1ac52783          	lw	a5,428(a0)
    80002af8:	2785                	addiw	a5,a5,1
    80002afa:	1af52623          	sw	a5,428(a0)
      if(p->priority == 0) quantum = QUANTUM_0;
    80002afe:	16852783          	lw	a5,360(a0)
    80002b02:	cfa1                	beqz	a5,80002b5a <kerneltrap+0x10e>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002b04:	4685                	li	a3,1
    80002b06:	06d78d63          	beq	a5,a3,80002b80 <kerneltrap+0x134>
      if(p->ticks_used >= quantum){
    80002b0a:	469d                	li	a3,7
    80002b0c:	04e6da63          	bge	a3,a4,80002b60 <kerneltrap+0x114>
        if(p->priority < 2)
    80002b10:	4705                	li	a4,1
    80002b12:	02f75563          	bge	a4,a5,80002b3c <kerneltrap+0xf0>
        p->ticks_used = 0;
    80002b16:	16052623          	sw	zero,364(a0)
        p->cumulative_run_time = 0;
    80002b1a:	1a052623          	sw	zero,428(a0)
    if(ticks % AGING_INTERVAL == 0){
    80002b1e:	00005797          	auipc	a5,0x5
    80002b22:	d5a7a783          	lw	a5,-678(a5) # 80007878 <ticks>
    80002b26:	06400713          	li	a4,100
    80002b2a:	02e7f7bb          	remuw	a5,a5,a4
    80002b2e:	2781                	sext.w	a5,a5
    80002b30:	e399                	bnez	a5,80002b36 <kerneltrap+0xea>
      promote_all();
    80002b32:	ab5ff0ef          	jal	800025e6 <promote_all>
      yield();
    80002b36:	decff0ef          	jal	80002122 <yield>
    80002b3a:	b799                	j	80002a80 <kerneltrap+0x34>
          p->priority++;
    80002b3c:	2785                	addiw	a5,a5,1
    80002b3e:	16f52423          	sw	a5,360(a0)
    80002b42:	bfd1                	j	80002b16 <kerneltrap+0xca>
    if(ticks % AGING_INTERVAL == 0){
    80002b44:	00005797          	auipc	a5,0x5
    80002b48:	d347a783          	lw	a5,-716(a5) # 80007878 <ticks>
    80002b4c:	06400713          	li	a4,100
    80002b50:	02e7f7bb          	remuw	a5,a5,a4
    80002b54:	2781                	sext.w	a5,a5
    80002b56:	f78d                	bnez	a5,80002a80 <kerneltrap+0x34>
    80002b58:	bfe9                	j	80002b32 <kerneltrap+0xe6>
      if(p->priority == 0) quantum = QUANTUM_0;
    80002b5a:	4685                	li	a3,1
      if(p->ticks_used >= quantum){
    80002b5c:	fed750e3          	bge	a4,a3,80002b3c <kerneltrap+0xf0>
      } else if(has_higher_priority(p->priority)){
    80002b60:	853e                	mv	a0,a5
    80002b62:	ad1ff0ef          	jal	80002632 <has_higher_priority>
    if(ticks % AGING_INTERVAL == 0){
    80002b66:	00005797          	auipc	a5,0x5
    80002b6a:	d127a783          	lw	a5,-750(a5) # 80007878 <ticks>
    80002b6e:	06400713          	li	a4,100
    80002b72:	02e7f7bb          	remuw	a5,a5,a4
    80002b76:	2781                	sext.w	a5,a5
    80002b78:	dfcd                	beqz	a5,80002b32 <kerneltrap+0xe6>
    if(need_yield){
    80002b7a:	f00503e3          	beqz	a0,80002a80 <kerneltrap+0x34>
    80002b7e:	bf65                	j	80002b36 <kerneltrap+0xea>
      else if(p->priority == 1) quantum = QUANTUM_1;
    80002b80:	4691                	li	a3,4
    80002b82:	bfe9                	j	80002b5c <kerneltrap+0x110>

0000000080002b84 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	1000                	addi	s0,sp,32
    80002b8e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b90:	d3ffe0ef          	jal	800018ce <myproc>
  switch (n) {
    80002b94:	4795                	li	a5,5
    80002b96:	0497e163          	bltu	a5,s1,80002bd8 <argraw+0x54>
    80002b9a:	048a                	slli	s1,s1,0x2
    80002b9c:	00005717          	auipc	a4,0x5
    80002ba0:	bbc70713          	addi	a4,a4,-1092 # 80007758 <states.0+0x30>
    80002ba4:	94ba                	add	s1,s1,a4
    80002ba6:	409c                	lw	a5,0(s1)
    80002ba8:	97ba                	add	a5,a5,a4
    80002baa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bac:	6d3c                	ld	a5,88(a0)
    80002bae:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret
    return p->trapframe->a1;
    80002bba:	6d3c                	ld	a5,88(a0)
    80002bbc:	7fa8                	ld	a0,120(a5)
    80002bbe:	bfcd                	j	80002bb0 <argraw+0x2c>
    return p->trapframe->a2;
    80002bc0:	6d3c                	ld	a5,88(a0)
    80002bc2:	63c8                	ld	a0,128(a5)
    80002bc4:	b7f5                	j	80002bb0 <argraw+0x2c>
    return p->trapframe->a3;
    80002bc6:	6d3c                	ld	a5,88(a0)
    80002bc8:	67c8                	ld	a0,136(a5)
    80002bca:	b7dd                	j	80002bb0 <argraw+0x2c>
    return p->trapframe->a4;
    80002bcc:	6d3c                	ld	a5,88(a0)
    80002bce:	6bc8                	ld	a0,144(a5)
    80002bd0:	b7c5                	j	80002bb0 <argraw+0x2c>
    return p->trapframe->a5;
    80002bd2:	6d3c                	ld	a5,88(a0)
    80002bd4:	6fc8                	ld	a0,152(a5)
    80002bd6:	bfe9                	j	80002bb0 <argraw+0x2c>
  panic("argraw");
    80002bd8:	00004517          	auipc	a0,0x4
    80002bdc:	79050513          	addi	a0,a0,1936 # 80007368 <etext+0x368>
    80002be0:	c01fd0ef          	jal	800007e0 <panic>

0000000080002be4 <fetchaddr>:
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	e04a                	sd	s2,0(sp)
    80002bee:	1000                	addi	s0,sp,32
    80002bf0:	84aa                	mv	s1,a0
    80002bf2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bf4:	cdbfe0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002bf8:	653c                	ld	a5,72(a0)
    80002bfa:	02f4f663          	bgeu	s1,a5,80002c26 <fetchaddr+0x42>
    80002bfe:	00848713          	addi	a4,s1,8
    80002c02:	02e7e463          	bltu	a5,a4,80002c2a <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c06:	46a1                	li	a3,8
    80002c08:	8626                	mv	a2,s1
    80002c0a:	85ca                	mv	a1,s2
    80002c0c:	6928                	ld	a0,80(a0)
    80002c0e:	ab9fe0ef          	jal	800016c6 <copyin>
    80002c12:	00a03533          	snez	a0,a0
    80002c16:	40a00533          	neg	a0,a0
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6902                	ld	s2,0(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    return -1;
    80002c26:	557d                	li	a0,-1
    80002c28:	bfcd                	j	80002c1a <fetchaddr+0x36>
    80002c2a:	557d                	li	a0,-1
    80002c2c:	b7fd                	j	80002c1a <fetchaddr+0x36>

0000000080002c2e <fetchstr>:
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	e84a                	sd	s2,16(sp)
    80002c38:	e44e                	sd	s3,8(sp)
    80002c3a:	1800                	addi	s0,sp,48
    80002c3c:	892a                	mv	s2,a0
    80002c3e:	84ae                	mv	s1,a1
    80002c40:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c42:	c8dfe0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c46:	86ce                	mv	a3,s3
    80002c48:	864a                	mv	a2,s2
    80002c4a:	85a6                	mv	a1,s1
    80002c4c:	6928                	ld	a0,80(a0)
    80002c4e:	83bfe0ef          	jal	80001488 <copyinstr>
    80002c52:	00054c63          	bltz	a0,80002c6a <fetchstr+0x3c>
  return strlen(buf);
    80002c56:	8526                	mv	a0,s1
    80002c58:	9bafe0ef          	jal	80000e12 <strlen>
}
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6942                	ld	s2,16(sp)
    80002c64:	69a2                	ld	s3,8(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    return -1;
    80002c6a:	557d                	li	a0,-1
    80002c6c:	bfc5                	j	80002c5c <fetchstr+0x2e>

0000000080002c6e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7a:	f0bff0ef          	jal	80002b84 <argraw>
    80002c7e:	c088                	sw	a0,0(s1)
}
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	64a2                	ld	s1,8(sp)
    80002c86:	6105                	addi	sp,sp,32
    80002c88:	8082                	ret

0000000080002c8a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	1000                	addi	s0,sp,32
    80002c94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c96:	eefff0ef          	jal	80002b84 <argraw>
    80002c9a:	e088                	sd	a0,0(s1)
  struct proc *p = myproc();
    80002c9c:	c33fe0ef          	jal	800018ce <myproc>
  // Kiểm tra xem địa chỉ có hợp lệ trong page table không
  if(walkaddr(p->pagetable, *ip) == 0)
    80002ca0:	608c                	ld	a1,0(s1)
    80002ca2:	6928                	ld	a0,80(a0)
    80002ca4:	b0cfe0ef          	jal	80000fb0 <walkaddr>
    80002ca8:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
    80002cac:	40a00533          	neg	a0,a0
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	64a2                	ld	s1,8(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cba:	7179                	addi	sp,sp,-48
    80002cbc:	f406                	sd	ra,40(sp)
    80002cbe:	f022                	sd	s0,32(sp)
    80002cc0:	ec26                	sd	s1,24(sp)
    80002cc2:	e84a                	sd	s2,16(sp)
    80002cc4:	1800                	addi	s0,sp,48
    80002cc6:	84ae                	mv	s1,a1
    80002cc8:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cca:	fd840593          	addi	a1,s0,-40
    80002cce:	fbdff0ef          	jal	80002c8a <argaddr>
  return fetchstr(addr, buf, max);
    80002cd2:	864a                	mv	a2,s2
    80002cd4:	85a6                	mv	a1,s1
    80002cd6:	fd843503          	ld	a0,-40(s0)
    80002cda:	f55ff0ef          	jal	80002c2e <fetchstr>
}
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6942                	ld	s2,16(sp)
    80002ce6:	6145                	addi	sp,sp,48
    80002ce8:	8082                	ret

0000000080002cea <syscall>:
[SYS_proc_info]   sys_proc_info,
};

void
syscall(void)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	e04a                	sd	s2,0(sp)
    80002cf4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cf6:	bd9fe0ef          	jal	800018ce <myproc>
    80002cfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cfc:	05853903          	ld	s2,88(a0)
    80002d00:	0a893783          	ld	a5,168(s2)
    80002d04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d08:	37fd                	addiw	a5,a5,-1
    80002d0a:	4755                	li	a4,21
    80002d0c:	00f76f63          	bltu	a4,a5,80002d2a <syscall+0x40>
    80002d10:	00369713          	slli	a4,a3,0x3
    80002d14:	00005797          	auipc	a5,0x5
    80002d18:	a5c78793          	addi	a5,a5,-1444 # 80007770 <syscalls>
    80002d1c:	97ba                	add	a5,a5,a4
    80002d1e:	639c                	ld	a5,0(a5)
    80002d20:	c789                	beqz	a5,80002d2a <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d22:	9782                	jalr	a5
    80002d24:	06a93823          	sd	a0,112(s2)
    80002d28:	a829                	j	80002d42 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d2a:	15848613          	addi	a2,s1,344
    80002d2e:	588c                	lw	a1,48(s1)
    80002d30:	00004517          	auipc	a0,0x4
    80002d34:	64050513          	addi	a0,a0,1600 # 80007370 <etext+0x370>
    80002d38:	fc2fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d3c:	6cbc                	ld	a5,88(s1)
    80002d3e:	577d                	li	a4,-1
    80002d40:	fbb8                	sd	a4,112(a5)
  }
}
    80002d42:	60e2                	ld	ra,24(sp)
    80002d44:	6442                	ld	s0,16(sp)
    80002d46:	64a2                	ld	s1,8(sp)
    80002d48:	6902                	ld	s2,0(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_exit>:
int argaddr(int, uint64 *);
extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d56:	fec40593          	addi	a1,s0,-20
    80002d5a:	4501                	li	a0,0
    80002d5c:	f13ff0ef          	jal	80002c6e <argint>
  kexit(n);
    80002d60:	fec42503          	lw	a0,-20(s0)
    80002d64:	cfaff0ef          	jal	8000225e <kexit>
  return 0;  // not reached
}
    80002d68:	4501                	li	a0,0
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d72:	1141                	addi	sp,sp,-16
    80002d74:	e406                	sd	ra,8(sp)
    80002d76:	e022                	sd	s0,0(sp)
    80002d78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d7a:	b55fe0ef          	jal	800018ce <myproc>
}
    80002d7e:	5908                	lw	a0,48(a0)
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_fork>:

uint64
sys_fork(void)
{
    80002d88:	7179                	addi	sp,sp,-48
    80002d8a:	f406                	sd	ra,40(sp)
    80002d8c:	f022                	sd	s0,32(sp)
    80002d8e:	ec26                	sd	s1,24(sp)
    80002d90:	1800                	addi	s0,sp,48
  int npid = kfork();
    80002d92:	f19fe0ef          	jal	80001caa <kfork>
    80002d96:	84aa                	mv	s1,a0
  if(npid > 0){
    80002d98:	00a04863          	bgtz	a0,80002da8 <sys_fork+0x20>
    p->fork_times[p->fork_times_idx] = current_tick;
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    release(&p->lock);
  }
  return npid;
}
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	70a2                	ld	ra,40(sp)
    80002da0:	7402                	ld	s0,32(sp)
    80002da2:	64e2                	ld	s1,24(sp)
    80002da4:	6145                	addi	sp,sp,48
    80002da6:	8082                	ret
    80002da8:	e84a                	sd	s2,16(sp)
    80002daa:	e44e                	sd	s3,8(sp)
    struct proc *p = myproc();
    80002dac:	b23fe0ef          	jal	800018ce <myproc>
    80002db0:	892a                	mv	s2,a0
    acquire(&tickslock);
    80002db2:	00014517          	auipc	a0,0x14
    80002db6:	1f650513          	addi	a0,a0,502 # 80016fa8 <tickslock>
    80002dba:	e15fd0ef          	jal	80000bce <acquire>
    current_tick = ticks;
    80002dbe:	00005997          	auipc	s3,0x5
    80002dc2:	aba9a983          	lw	s3,-1350(s3) # 80007878 <ticks>
    release(&tickslock);
    80002dc6:	00014517          	auipc	a0,0x14
    80002dca:	1e250513          	addi	a0,a0,482 # 80016fa8 <tickslock>
    80002dce:	e99fd0ef          	jal	80000c66 <release>
    acquire(&p->lock);
    80002dd2:	854a                	mv	a0,s2
    80002dd4:	dfbfd0ef          	jal	80000bce <acquire>
    p->fork_times[p->fork_times_idx] = current_tick;
    80002dd8:	1a892783          	lw	a5,424(s2)
    80002ddc:	02079693          	slli	a3,a5,0x20
    80002de0:	01d6d713          	srli	a4,a3,0x1d
    80002de4:	974a                	add	a4,a4,s2
    80002de6:	1982                	slli	s3,s3,0x20
    80002de8:	0209d993          	srli	s3,s3,0x20
    80002dec:	17373c23          	sd	s3,376(a4)
    p->fork_times_idx = (p->fork_times_idx + 1) % EDR_FORK_SAMPLE;
    80002df0:	2785                	addiw	a5,a5,1
    80002df2:	4719                	li	a4,6
    80002df4:	02e7f7bb          	remuw	a5,a5,a4
    80002df8:	1af92423          	sw	a5,424(s2)
    release(&p->lock);
    80002dfc:	854a                	mv	a0,s2
    80002dfe:	e69fd0ef          	jal	80000c66 <release>
    80002e02:	6942                	ld	s2,16(sp)
    80002e04:	69a2                	ld	s3,8(sp)
    80002e06:	bf59                	j	80002d9c <sys_fork+0x14>

0000000080002e08 <sys_wait>:

uint64
sys_wait(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e10:	fe840593          	addi	a1,s0,-24
    80002e14:	4501                	li	a0,0
    80002e16:	e75ff0ef          	jal	80002c8a <argaddr>
  return kwait(p);
    80002e1a:	fe843503          	ld	a0,-24(s0)
    80002e1e:	d96ff0ef          	jal	800023b4 <kwait>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002e34:	fd840593          	addi	a1,s0,-40
    80002e38:	4501                	li	a0,0
    80002e3a:	e35ff0ef          	jal	80002c6e <argint>
  argint(1, &t);
    80002e3e:	fdc40593          	addi	a1,s0,-36
    80002e42:	4505                	li	a0,1
    80002e44:	e2bff0ef          	jal	80002c6e <argint>
  addr = myproc()->sz;
    80002e48:	a87fe0ef          	jal	800018ce <myproc>
    80002e4c:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002e4e:	fdc42703          	lw	a4,-36(s0)
    80002e52:	4785                	li	a5,1
    80002e54:	02f70763          	beq	a4,a5,80002e82 <sys_sbrk+0x58>
    80002e58:	fd842783          	lw	a5,-40(s0)
    80002e5c:	0207c363          	bltz	a5,80002e82 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002e60:	97a6                	add	a5,a5,s1
    80002e62:	0297ee63          	bltu	a5,s1,80002e9e <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002e66:	02000737          	lui	a4,0x2000
    80002e6a:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002e6c:	0736                	slli	a4,a4,0xd
    80002e6e:	02f76a63          	bltu	a4,a5,80002ea2 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002e72:	a5dfe0ef          	jal	800018ce <myproc>
    80002e76:	fd842703          	lw	a4,-40(s0)
    80002e7a:	653c                	ld	a5,72(a0)
    80002e7c:	97ba                	add	a5,a5,a4
    80002e7e:	e53c                	sd	a5,72(a0)
    80002e80:	a039                	j	80002e8e <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002e82:	fd842503          	lw	a0,-40(s0)
    80002e86:	dc3fe0ef          	jal	80001c48 <growproc>
    80002e8a:	00054863          	bltz	a0,80002e9a <sys_sbrk+0x70>
  }
  return addr;
}
    80002e8e:	8526                	mv	a0,s1
    80002e90:	70a2                	ld	ra,40(sp)
    80002e92:	7402                	ld	s0,32(sp)
    80002e94:	64e2                	ld	s1,24(sp)
    80002e96:	6145                	addi	sp,sp,48
    80002e98:	8082                	ret
      return -1;
    80002e9a:	54fd                	li	s1,-1
    80002e9c:	bfcd                	j	80002e8e <sys_sbrk+0x64>
      return -1;
    80002e9e:	54fd                	li	s1,-1
    80002ea0:	b7fd                	j	80002e8e <sys_sbrk+0x64>
      return -1;
    80002ea2:	54fd                	li	s1,-1
    80002ea4:	b7ed                	j	80002e8e <sys_sbrk+0x64>

0000000080002ea6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea6:	7139                	addi	sp,sp,-64
    80002ea8:	fc06                	sd	ra,56(sp)
    80002eaa:	f822                	sd	s0,48(sp)
    80002eac:	f04a                	sd	s2,32(sp)
    80002eae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002eb0:	fcc40593          	addi	a1,s0,-52
    80002eb4:	4501                	li	a0,0
    80002eb6:	db9ff0ef          	jal	80002c6e <argint>
  if(n < 0)
    80002eba:	fcc42783          	lw	a5,-52(s0)
    80002ebe:	0607c763          	bltz	a5,80002f2c <sys_sleep+0x86>
    n = 0;
  acquire(&tickslock);
    80002ec2:	00014517          	auipc	a0,0x14
    80002ec6:	0e650513          	addi	a0,a0,230 # 80016fa8 <tickslock>
    80002eca:	d05fd0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002ece:	00005917          	auipc	s2,0x5
    80002ed2:	9aa92903          	lw	s2,-1622(s2) # 80007878 <ticks>
  while(ticks - ticks0 < n){
    80002ed6:	fcc42783          	lw	a5,-52(s0)
    80002eda:	cf8d                	beqz	a5,80002f14 <sys_sleep+0x6e>
    80002edc:	f426                	sd	s1,40(sp)
    80002ede:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ee0:	00014997          	auipc	s3,0x14
    80002ee4:	0c898993          	addi	s3,s3,200 # 80016fa8 <tickslock>
    80002ee8:	00005497          	auipc	s1,0x5
    80002eec:	99048493          	addi	s1,s1,-1648 # 80007878 <ticks>
    if(killed(myproc())){
    80002ef0:	9dffe0ef          	jal	800018ce <myproc>
    80002ef4:	c96ff0ef          	jal	8000238a <killed>
    80002ef8:	ed0d                	bnez	a0,80002f32 <sys_sleep+0x8c>
    sleep(&ticks, &tickslock);
    80002efa:	85ce                	mv	a1,s3
    80002efc:	8526                	mv	a0,s1
    80002efe:	a50ff0ef          	jal	8000214e <sleep>
  while(ticks - ticks0 < n){
    80002f02:	409c                	lw	a5,0(s1)
    80002f04:	412787bb          	subw	a5,a5,s2
    80002f08:	fcc42703          	lw	a4,-52(s0)
    80002f0c:	fee7e2e3          	bltu	a5,a4,80002ef0 <sys_sleep+0x4a>
    80002f10:	74a2                	ld	s1,40(sp)
    80002f12:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002f14:	00014517          	auipc	a0,0x14
    80002f18:	09450513          	addi	a0,a0,148 # 80016fa8 <tickslock>
    80002f1c:	d4bfd0ef          	jal	80000c66 <release>
  return 0;
    80002f20:	4501                	li	a0,0
}
    80002f22:	70e2                	ld	ra,56(sp)
    80002f24:	7442                	ld	s0,48(sp)
    80002f26:	7902                	ld	s2,32(sp)
    80002f28:	6121                	addi	sp,sp,64
    80002f2a:	8082                	ret
    n = 0;
    80002f2c:	fc042623          	sw	zero,-52(s0)
    80002f30:	bf49                	j	80002ec2 <sys_sleep+0x1c>
      release(&tickslock);
    80002f32:	00014517          	auipc	a0,0x14
    80002f36:	07650513          	addi	a0,a0,118 # 80016fa8 <tickslock>
    80002f3a:	d2dfd0ef          	jal	80000c66 <release>
      return -1;
    80002f3e:	557d                	li	a0,-1
    80002f40:	74a2                	ld	s1,40(sp)
    80002f42:	69e2                	ld	s3,24(sp)
    80002f44:	bff9                	j	80002f22 <sys_sleep+0x7c>

0000000080002f46 <sys_kill>:

uint64
sys_kill(void)
{
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f4e:	fec40593          	addi	a1,s0,-20
    80002f52:	4501                	li	a0,0
    80002f54:	d1bff0ef          	jal	80002c6e <argint>
  return kkill(pid);
    80002f58:	fec42503          	lw	a0,-20(s0)
    80002f5c:	ba4ff0ef          	jal	80002300 <kkill>
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret

0000000080002f68 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f68:	1101                	addi	sp,sp,-32
    80002f6a:	ec06                	sd	ra,24(sp)
    80002f6c:	e822                	sd	s0,16(sp)
    80002f6e:	e426                	sd	s1,8(sp)
    80002f70:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f72:	00014517          	auipc	a0,0x14
    80002f76:	03650513          	addi	a0,a0,54 # 80016fa8 <tickslock>
    80002f7a:	c55fd0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002f7e:	00005497          	auipc	s1,0x5
    80002f82:	8fa4a483          	lw	s1,-1798(s1) # 80007878 <ticks>
  release(&tickslock);
    80002f86:	00014517          	auipc	a0,0x14
    80002f8a:	02250513          	addi	a0,a0,34 # 80016fa8 <tickslock>
    80002f8e:	cd9fd0ef          	jal	80000c66 <release>
  return xticks;
}
    80002f92:	02049513          	slli	a0,s1,0x20
    80002f96:	9101                	srli	a0,a0,0x20
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret

0000000080002fa2 <sys_proc_info>:

uint64
sys_proc_info(void)
{
    80002fa2:	bc010113          	addi	sp,sp,-1088
    80002fa6:	42113c23          	sd	ra,1080(sp)
    80002faa:	42813823          	sd	s0,1072(sp)
    80002fae:	44010413          	addi	s0,sp,1088
  uint64 addr;
  struct p_info pinfo;
  struct proc *p;

  // Lấy địa chỉ con trỏ từ user space truyền vào
  if(argaddr(0, &addr) < 0)
    80002fb2:	fc840593          	addi	a1,s0,-56
    80002fb6:	4501                	li	a0,0
    80002fb8:	cd3ff0ef          	jal	80002c8a <argaddr>
    80002fbc:	08054463          	bltz	a0,80003044 <sys_proc_info+0xa2>
    80002fc0:	42913423          	sd	s1,1064(sp)
    80002fc4:	43213023          	sd	s2,1056(sp)
    80002fc8:	41313c23          	sd	s3,1048(sp)
    80002fcc:	bc840913          	addi	s2,s0,-1080
    return -1;

  // Duyệt qua bảng tiến trình
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    80002fd0:	0000d497          	auipc	s1,0xd
    80002fd4:	dd848493          	addi	s1,s1,-552 # 8000fda8 <proc>
    80002fd8:	00014997          	auipc	s3,0x14
    80002fdc:	fd098993          	addi	s3,s3,-48 # 80016fa8 <tickslock>
    // Cần giữ lock khi đọc dữ liệu để tránh race condition (tuỳ chọn nhưng nên làm)
    acquire(&p->lock);
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	bedfd0ef          	jal	80000bce <acquire>
    
    pinfo.pid[i] = p->pid;
    80002fe6:	589c                	lw	a5,48(s1)
    80002fe8:	00f92023          	sw	a5,0(s2)
    pinfo.state[i] = p->state;
    80002fec:	4c9c                	lw	a5,24(s1)
    80002fee:	30f92023          	sw	a5,768(s2)
    pinfo.priority[i] = p->priority;    
    80002ff2:	1684a783          	lw	a5,360(s1)
    80002ff6:	10f92023          	sw	a5,256(s2)
    pinfo.ticks_used[i] = p->ticks_used;
    80002ffa:	16c4a783          	lw	a5,364(s1)
    80002ffe:	20f92023          	sw	a5,512(s2)
    
    release(&p->lock);
    80003002:	8526                	mv	a0,s1
    80003004:	c63fd0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003008:	1c848493          	addi	s1,s1,456
    8000300c:	0911                	addi	s2,s2,4
    8000300e:	fd3499e3          	bne	s1,s3,80002fe0 <sys_proc_info+0x3e>
    i++;
  }

  // Copy dữ liệu từ kernel space ra user space
  // Lưu ý: copyout trả về -1 nếu lỗi, 0 nếu thành công
  if(copyout(myproc()->pagetable, addr, (char *)&pinfo, sizeof(pinfo)) < 0)
    80003012:	8bdfe0ef          	jal	800018ce <myproc>
    80003016:	40000693          	li	a3,1024
    8000301a:	bc840613          	addi	a2,s0,-1080
    8000301e:	fc843583          	ld	a1,-56(s0)
    80003022:	6928                	ld	a0,80(a0)
    80003024:	dbefe0ef          	jal	800015e2 <copyout>
    80003028:	957d                	srai	a0,a0,0x3f
    8000302a:	42813483          	ld	s1,1064(sp)
    8000302e:	42013903          	ld	s2,1056(sp)
    80003032:	41813983          	ld	s3,1048(sp)
    return -1;

  return 0;
}
    80003036:	43813083          	ld	ra,1080(sp)
    8000303a:	43013403          	ld	s0,1072(sp)
    8000303e:	44010113          	addi	sp,sp,1088
    80003042:	8082                	ret
    return -1;
    80003044:	557d                	li	a0,-1
    80003046:	bfc5                	j	80003036 <sys_proc_info+0x94>

0000000080003048 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003048:	7179                	addi	sp,sp,-48
    8000304a:	f406                	sd	ra,40(sp)
    8000304c:	f022                	sd	s0,32(sp)
    8000304e:	ec26                	sd	s1,24(sp)
    80003050:	e84a                	sd	s2,16(sp)
    80003052:	e44e                	sd	s3,8(sp)
    80003054:	e052                	sd	s4,0(sp)
    80003056:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003058:	00004597          	auipc	a1,0x4
    8000305c:	33858593          	addi	a1,a1,824 # 80007390 <etext+0x390>
    80003060:	00014517          	auipc	a0,0x14
    80003064:	f6050513          	addi	a0,a0,-160 # 80016fc0 <bcache>
    80003068:	ae7fd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000306c:	0001c797          	auipc	a5,0x1c
    80003070:	f5478793          	addi	a5,a5,-172 # 8001efc0 <bcache+0x8000>
    80003074:	0001c717          	auipc	a4,0x1c
    80003078:	1b470713          	addi	a4,a4,436 # 8001f228 <bcache+0x8268>
    8000307c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003080:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003084:	00014497          	auipc	s1,0x14
    80003088:	f5448493          	addi	s1,s1,-172 # 80016fd8 <bcache+0x18>
    b->next = bcache.head.next;
    8000308c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003090:	00004a17          	auipc	s4,0x4
    80003094:	308a0a13          	addi	s4,s4,776 # 80007398 <etext+0x398>
    b->next = bcache.head.next;
    80003098:	2b893783          	ld	a5,696(s2)
    8000309c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030a2:	85d2                	mv	a1,s4
    800030a4:	01048513          	addi	a0,s1,16
    800030a8:	322010ef          	jal	800043ca <initsleeplock>
    bcache.head.next->prev = b;
    800030ac:	2b893783          	ld	a5,696(s2)
    800030b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b6:	45848493          	addi	s1,s1,1112
    800030ba:	fd349fe3          	bne	s1,s3,80003098 <binit+0x50>
  }
}
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6a02                	ld	s4,0(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ce:	7179                	addi	sp,sp,-48
    800030d0:	f406                	sd	ra,40(sp)
    800030d2:	f022                	sd	s0,32(sp)
    800030d4:	ec26                	sd	s1,24(sp)
    800030d6:	e84a                	sd	s2,16(sp)
    800030d8:	e44e                	sd	s3,8(sp)
    800030da:	1800                	addi	s0,sp,48
    800030dc:	892a                	mv	s2,a0
    800030de:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030e0:	00014517          	auipc	a0,0x14
    800030e4:	ee050513          	addi	a0,a0,-288 # 80016fc0 <bcache>
    800030e8:	ae7fd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030ec:	0001c497          	auipc	s1,0x1c
    800030f0:	18c4b483          	ld	s1,396(s1) # 8001f278 <bcache+0x82b8>
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	13478793          	addi	a5,a5,308 # 8001f228 <bcache+0x8268>
    800030fc:	02f48b63          	beq	s1,a5,80003132 <bread+0x64>
    80003100:	873e                	mv	a4,a5
    80003102:	a021                	j	8000310a <bread+0x3c>
    80003104:	68a4                	ld	s1,80(s1)
    80003106:	02e48663          	beq	s1,a4,80003132 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    8000310a:	449c                	lw	a5,8(s1)
    8000310c:	ff279ce3          	bne	a5,s2,80003104 <bread+0x36>
    80003110:	44dc                	lw	a5,12(s1)
    80003112:	ff3799e3          	bne	a5,s3,80003104 <bread+0x36>
      b->refcnt++;
    80003116:	40bc                	lw	a5,64(s1)
    80003118:	2785                	addiw	a5,a5,1
    8000311a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000311c:	00014517          	auipc	a0,0x14
    80003120:	ea450513          	addi	a0,a0,-348 # 80016fc0 <bcache>
    80003124:	b43fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80003128:	01048513          	addi	a0,s1,16
    8000312c:	2d4010ef          	jal	80004400 <acquiresleep>
      return b;
    80003130:	a889                	j	80003182 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003132:	0001c497          	auipc	s1,0x1c
    80003136:	13e4b483          	ld	s1,318(s1) # 8001f270 <bcache+0x82b0>
    8000313a:	0001c797          	auipc	a5,0x1c
    8000313e:	0ee78793          	addi	a5,a5,238 # 8001f228 <bcache+0x8268>
    80003142:	00f48863          	beq	s1,a5,80003152 <bread+0x84>
    80003146:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	cb91                	beqz	a5,8000315e <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314c:	64a4                	ld	s1,72(s1)
    8000314e:	fee49de3          	bne	s1,a4,80003148 <bread+0x7a>
  panic("bget: no buffers");
    80003152:	00004517          	auipc	a0,0x4
    80003156:	24e50513          	addi	a0,a0,590 # 800073a0 <etext+0x3a0>
    8000315a:	e86fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    8000315e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003162:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003166:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000316a:	4785                	li	a5,1
    8000316c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	e5250513          	addi	a0,a0,-430 # 80016fc0 <bcache>
    80003176:	af1fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    8000317a:	01048513          	addi	a0,s1,16
    8000317e:	282010ef          	jal	80004400 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003182:	409c                	lw	a5,0(s1)
    80003184:	cb89                	beqz	a5,80003196 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003186:	8526                	mv	a0,s1
    80003188:	70a2                	ld	ra,40(sp)
    8000318a:	7402                	ld	s0,32(sp)
    8000318c:	64e2                	ld	s1,24(sp)
    8000318e:	6942                	ld	s2,16(sp)
    80003190:	69a2                	ld	s3,8(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret
    virtio_disk_rw(b, 0);
    80003196:	4581                	li	a1,0
    80003198:	8526                	mv	a0,s1
    8000319a:	2d7020ef          	jal	80005c70 <virtio_disk_rw>
    b->valid = 1;
    8000319e:	4785                	li	a5,1
    800031a0:	c09c                	sw	a5,0(s1)
  return b;
    800031a2:	b7d5                	j	80003186 <bread+0xb8>

00000000800031a4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	e426                	sd	s1,8(sp)
    800031ac:	1000                	addi	s0,sp,32
    800031ae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b0:	0541                	addi	a0,a0,16
    800031b2:	2cc010ef          	jal	8000447e <holdingsleep>
    800031b6:	c911                	beqz	a0,800031ca <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031b8:	4585                	li	a1,1
    800031ba:	8526                	mv	a0,s1
    800031bc:	2b5020ef          	jal	80005c70 <virtio_disk_rw>
}
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret
    panic("bwrite");
    800031ca:	00004517          	auipc	a0,0x4
    800031ce:	1ee50513          	addi	a0,a0,494 # 800073b8 <etext+0x3b8>
    800031d2:	e0efd0ef          	jal	800007e0 <panic>

00000000800031d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031d6:	1101                	addi	sp,sp,-32
    800031d8:	ec06                	sd	ra,24(sp)
    800031da:	e822                	sd	s0,16(sp)
    800031dc:	e426                	sd	s1,8(sp)
    800031de:	e04a                	sd	s2,0(sp)
    800031e0:	1000                	addi	s0,sp,32
    800031e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e4:	01050913          	addi	s2,a0,16
    800031e8:	854a                	mv	a0,s2
    800031ea:	294010ef          	jal	8000447e <holdingsleep>
    800031ee:	c135                	beqz	a0,80003252 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    800031f0:	854a                	mv	a0,s2
    800031f2:	254010ef          	jal	80004446 <releasesleep>

  acquire(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	dca50513          	addi	a0,a0,-566 # 80016fc0 <bcache>
    800031fe:	9d1fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	37fd                	addiw	a5,a5,-1
    80003206:	0007871b          	sext.w	a4,a5
    8000320a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000320c:	e71d                	bnez	a4,8000323a <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000320e:	68b8                	ld	a4,80(s1)
    80003210:	64bc                	ld	a5,72(s1)
    80003212:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003214:	68b8                	ld	a4,80(s1)
    80003216:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003218:	0001c797          	auipc	a5,0x1c
    8000321c:	da878793          	addi	a5,a5,-600 # 8001efc0 <bcache+0x8000>
    80003220:	2b87b703          	ld	a4,696(a5)
    80003224:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003226:	0001c717          	auipc	a4,0x1c
    8000322a:	00270713          	addi	a4,a4,2 # 8001f228 <bcache+0x8268>
    8000322e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003230:	2b87b703          	ld	a4,696(a5)
    80003234:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003236:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000323a:	00014517          	auipc	a0,0x14
    8000323e:	d8650513          	addi	a0,a0,-634 # 80016fc0 <bcache>
    80003242:	a25fd0ef          	jal	80000c66 <release>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6902                	ld	s2,0(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret
    panic("brelse");
    80003252:	00004517          	auipc	a0,0x4
    80003256:	16e50513          	addi	a0,a0,366 # 800073c0 <etext+0x3c0>
    8000325a:	d86fd0ef          	jal	800007e0 <panic>

000000008000325e <bpin>:

void
bpin(struct buf *b) {
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	e426                	sd	s1,8(sp)
    80003266:	1000                	addi	s0,sp,32
    80003268:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000326a:	00014517          	auipc	a0,0x14
    8000326e:	d5650513          	addi	a0,a0,-682 # 80016fc0 <bcache>
    80003272:	95dfd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80003276:	40bc                	lw	a5,64(s1)
    80003278:	2785                	addiw	a5,a5,1
    8000327a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	d4450513          	addi	a0,a0,-700 # 80016fc0 <bcache>
    80003284:	9e3fd0ef          	jal	80000c66 <release>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret

0000000080003292 <bunpin>:

void
bunpin(struct buf *b) {
    80003292:	1101                	addi	sp,sp,-32
    80003294:	ec06                	sd	ra,24(sp)
    80003296:	e822                	sd	s0,16(sp)
    80003298:	e426                	sd	s1,8(sp)
    8000329a:	1000                	addi	s0,sp,32
    8000329c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329e:	00014517          	auipc	a0,0x14
    800032a2:	d2250513          	addi	a0,a0,-734 # 80016fc0 <bcache>
    800032a6:	929fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    800032aa:	40bc                	lw	a5,64(s1)
    800032ac:	37fd                	addiw	a5,a5,-1
    800032ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b0:	00014517          	auipc	a0,0x14
    800032b4:	d1050513          	addi	a0,a0,-752 # 80016fc0 <bcache>
    800032b8:	9affd0ef          	jal	80000c66 <release>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret

00000000800032c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032c6:	1101                	addi	sp,sp,-32
    800032c8:	ec06                	sd	ra,24(sp)
    800032ca:	e822                	sd	s0,16(sp)
    800032cc:	e426                	sd	s1,8(sp)
    800032ce:	e04a                	sd	s2,0(sp)
    800032d0:	1000                	addi	s0,sp,32
    800032d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032d4:	00d5d59b          	srliw	a1,a1,0xd
    800032d8:	0001c797          	auipc	a5,0x1c
    800032dc:	3c47a783          	lw	a5,964(a5) # 8001f69c <sb+0x1c>
    800032e0:	9dbd                	addw	a1,a1,a5
    800032e2:	dedff0ef          	jal	800030ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032e6:	0074f713          	andi	a4,s1,7
    800032ea:	4785                	li	a5,1
    800032ec:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032f0:	14ce                	slli	s1,s1,0x33
    800032f2:	90d9                	srli	s1,s1,0x36
    800032f4:	00950733          	add	a4,a0,s1
    800032f8:	05874703          	lbu	a4,88(a4)
    800032fc:	00e7f6b3          	and	a3,a5,a4
    80003300:	c29d                	beqz	a3,80003326 <bfree+0x60>
    80003302:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003304:	94aa                	add	s1,s1,a0
    80003306:	fff7c793          	not	a5,a5
    8000330a:	8f7d                	and	a4,a4,a5
    8000330c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003310:	7f9000ef          	jal	80004308 <log_write>
  brelse(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	ec1ff0ef          	jal	800031d6 <brelse>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret
    panic("freeing free block");
    80003326:	00004517          	auipc	a0,0x4
    8000332a:	0a250513          	addi	a0,a0,162 # 800073c8 <etext+0x3c8>
    8000332e:	cb2fd0ef          	jal	800007e0 <panic>

0000000080003332 <balloc>:
{
    80003332:	711d                	addi	sp,sp,-96
    80003334:	ec86                	sd	ra,88(sp)
    80003336:	e8a2                	sd	s0,80(sp)
    80003338:	e4a6                	sd	s1,72(sp)
    8000333a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000333c:	0001c797          	auipc	a5,0x1c
    80003340:	3487a783          	lw	a5,840(a5) # 8001f684 <sb+0x4>
    80003344:	0e078f63          	beqz	a5,80003442 <balloc+0x110>
    80003348:	e0ca                	sd	s2,64(sp)
    8000334a:	fc4e                	sd	s3,56(sp)
    8000334c:	f852                	sd	s4,48(sp)
    8000334e:	f456                	sd	s5,40(sp)
    80003350:	f05a                	sd	s6,32(sp)
    80003352:	ec5e                	sd	s7,24(sp)
    80003354:	e862                	sd	s8,16(sp)
    80003356:	e466                	sd	s9,8(sp)
    80003358:	8baa                	mv	s7,a0
    8000335a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000335c:	0001cb17          	auipc	s6,0x1c
    80003360:	324b0b13          	addi	s6,s6,804 # 8001f680 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003364:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003366:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003368:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000336a:	6c89                	lui	s9,0x2
    8000336c:	a0b5                	j	800033d8 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000336e:	97ca                	add	a5,a5,s2
    80003370:	8e55                	or	a2,a2,a3
    80003372:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003376:	854a                	mv	a0,s2
    80003378:	791000ef          	jal	80004308 <log_write>
        brelse(bp);
    8000337c:	854a                	mv	a0,s2
    8000337e:	e59ff0ef          	jal	800031d6 <brelse>
  bp = bread(dev, bno);
    80003382:	85a6                	mv	a1,s1
    80003384:	855e                	mv	a0,s7
    80003386:	d49ff0ef          	jal	800030ce <bread>
    8000338a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000338c:	40000613          	li	a2,1024
    80003390:	4581                	li	a1,0
    80003392:	05850513          	addi	a0,a0,88
    80003396:	90dfd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    8000339a:	854a                	mv	a0,s2
    8000339c:	76d000ef          	jal	80004308 <log_write>
  brelse(bp);
    800033a0:	854a                	mv	a0,s2
    800033a2:	e35ff0ef          	jal	800031d6 <brelse>
}
    800033a6:	6906                	ld	s2,64(sp)
    800033a8:	79e2                	ld	s3,56(sp)
    800033aa:	7a42                	ld	s4,48(sp)
    800033ac:	7aa2                	ld	s5,40(sp)
    800033ae:	7b02                	ld	s6,32(sp)
    800033b0:	6be2                	ld	s7,24(sp)
    800033b2:	6c42                	ld	s8,16(sp)
    800033b4:	6ca2                	ld	s9,8(sp)
}
    800033b6:	8526                	mv	a0,s1
    800033b8:	60e6                	ld	ra,88(sp)
    800033ba:	6446                	ld	s0,80(sp)
    800033bc:	64a6                	ld	s1,72(sp)
    800033be:	6125                	addi	sp,sp,96
    800033c0:	8082                	ret
    brelse(bp);
    800033c2:	854a                	mv	a0,s2
    800033c4:	e13ff0ef          	jal	800031d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033c8:	015c87bb          	addw	a5,s9,s5
    800033cc:	00078a9b          	sext.w	s5,a5
    800033d0:	004b2703          	lw	a4,4(s6)
    800033d4:	04eaff63          	bgeu	s5,a4,80003432 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    800033d8:	41fad79b          	sraiw	a5,s5,0x1f
    800033dc:	0137d79b          	srliw	a5,a5,0x13
    800033e0:	015787bb          	addw	a5,a5,s5
    800033e4:	40d7d79b          	sraiw	a5,a5,0xd
    800033e8:	01cb2583          	lw	a1,28(s6)
    800033ec:	9dbd                	addw	a1,a1,a5
    800033ee:	855e                	mv	a0,s7
    800033f0:	cdfff0ef          	jal	800030ce <bread>
    800033f4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f6:	004b2503          	lw	a0,4(s6)
    800033fa:	000a849b          	sext.w	s1,s5
    800033fe:	8762                	mv	a4,s8
    80003400:	fca4f1e3          	bgeu	s1,a0,800033c2 <balloc+0x90>
      m = 1 << (bi % 8);
    80003404:	00777693          	andi	a3,a4,7
    80003408:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000340c:	41f7579b          	sraiw	a5,a4,0x1f
    80003410:	01d7d79b          	srliw	a5,a5,0x1d
    80003414:	9fb9                	addw	a5,a5,a4
    80003416:	4037d79b          	sraiw	a5,a5,0x3
    8000341a:	00f90633          	add	a2,s2,a5
    8000341e:	05864603          	lbu	a2,88(a2)
    80003422:	00c6f5b3          	and	a1,a3,a2
    80003426:	d5a1                	beqz	a1,8000336e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003428:	2705                	addiw	a4,a4,1
    8000342a:	2485                	addiw	s1,s1,1
    8000342c:	fd471ae3          	bne	a4,s4,80003400 <balloc+0xce>
    80003430:	bf49                	j	800033c2 <balloc+0x90>
    80003432:	6906                	ld	s2,64(sp)
    80003434:	79e2                	ld	s3,56(sp)
    80003436:	7a42                	ld	s4,48(sp)
    80003438:	7aa2                	ld	s5,40(sp)
    8000343a:	7b02                	ld	s6,32(sp)
    8000343c:	6be2                	ld	s7,24(sp)
    8000343e:	6c42                	ld	s8,16(sp)
    80003440:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003442:	00004517          	auipc	a0,0x4
    80003446:	f9e50513          	addi	a0,a0,-98 # 800073e0 <etext+0x3e0>
    8000344a:	8b0fd0ef          	jal	800004fa <printf>
  return 0;
    8000344e:	4481                	li	s1,0
    80003450:	b79d                	j	800033b6 <balloc+0x84>

0000000080003452 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	ec26                	sd	s1,24(sp)
    8000345a:	e84a                	sd	s2,16(sp)
    8000345c:	e44e                	sd	s3,8(sp)
    8000345e:	1800                	addi	s0,sp,48
    80003460:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003462:	47ad                	li	a5,11
    80003464:	02b7e663          	bltu	a5,a1,80003490 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003468:	02059793          	slli	a5,a1,0x20
    8000346c:	01e7d593          	srli	a1,a5,0x1e
    80003470:	00b504b3          	add	s1,a0,a1
    80003474:	0504a903          	lw	s2,80(s1)
    80003478:	06091a63          	bnez	s2,800034ec <bmap+0x9a>
      addr = balloc(ip->dev);
    8000347c:	4108                	lw	a0,0(a0)
    8000347e:	eb5ff0ef          	jal	80003332 <balloc>
    80003482:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003486:	06090363          	beqz	s2,800034ec <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    8000348a:	0524a823          	sw	s2,80(s1)
    8000348e:	a8b9                	j	800034ec <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003490:	ff45849b          	addiw	s1,a1,-12
    80003494:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003498:	0ff00793          	li	a5,255
    8000349c:	06e7ee63          	bltu	a5,a4,80003518 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034a0:	08052903          	lw	s2,128(a0)
    800034a4:	00091d63          	bnez	s2,800034be <bmap+0x6c>
      addr = balloc(ip->dev);
    800034a8:	4108                	lw	a0,0(a0)
    800034aa:	e89ff0ef          	jal	80003332 <balloc>
    800034ae:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034b2:	02090d63          	beqz	s2,800034ec <bmap+0x9a>
    800034b6:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034b8:	0929a023          	sw	s2,128(s3)
    800034bc:	a011                	j	800034c0 <bmap+0x6e>
    800034be:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800034c0:	85ca                	mv	a1,s2
    800034c2:	0009a503          	lw	a0,0(s3)
    800034c6:	c09ff0ef          	jal	800030ce <bread>
    800034ca:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034cc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034d0:	02049713          	slli	a4,s1,0x20
    800034d4:	01e75593          	srli	a1,a4,0x1e
    800034d8:	00b784b3          	add	s1,a5,a1
    800034dc:	0004a903          	lw	s2,0(s1)
    800034e0:	00090e63          	beqz	s2,800034fc <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034e4:	8552                	mv	a0,s4
    800034e6:	cf1ff0ef          	jal	800031d6 <brelse>
    return addr;
    800034ea:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800034ec:	854a                	mv	a0,s2
    800034ee:	70a2                	ld	ra,40(sp)
    800034f0:	7402                	ld	s0,32(sp)
    800034f2:	64e2                	ld	s1,24(sp)
    800034f4:	6942                	ld	s2,16(sp)
    800034f6:	69a2                	ld	s3,8(sp)
    800034f8:	6145                	addi	sp,sp,48
    800034fa:	8082                	ret
      addr = balloc(ip->dev);
    800034fc:	0009a503          	lw	a0,0(s3)
    80003500:	e33ff0ef          	jal	80003332 <balloc>
    80003504:	0005091b          	sext.w	s2,a0
      if(addr){
    80003508:	fc090ee3          	beqz	s2,800034e4 <bmap+0x92>
        a[bn] = addr;
    8000350c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003510:	8552                	mv	a0,s4
    80003512:	5f7000ef          	jal	80004308 <log_write>
    80003516:	b7f9                	j	800034e4 <bmap+0x92>
    80003518:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    8000351a:	00004517          	auipc	a0,0x4
    8000351e:	ede50513          	addi	a0,a0,-290 # 800073f8 <etext+0x3f8>
    80003522:	abefd0ef          	jal	800007e0 <panic>

0000000080003526 <iget>:
{
    80003526:	7179                	addi	sp,sp,-48
    80003528:	f406                	sd	ra,40(sp)
    8000352a:	f022                	sd	s0,32(sp)
    8000352c:	ec26                	sd	s1,24(sp)
    8000352e:	e84a                	sd	s2,16(sp)
    80003530:	e44e                	sd	s3,8(sp)
    80003532:	e052                	sd	s4,0(sp)
    80003534:	1800                	addi	s0,sp,48
    80003536:	89aa                	mv	s3,a0
    80003538:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000353a:	0001c517          	auipc	a0,0x1c
    8000353e:	16650513          	addi	a0,a0,358 # 8001f6a0 <itable>
    80003542:	e8cfd0ef          	jal	80000bce <acquire>
  empty = 0;
    80003546:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003548:	0001c497          	auipc	s1,0x1c
    8000354c:	17048493          	addi	s1,s1,368 # 8001f6b8 <itable+0x18>
    80003550:	0001e697          	auipc	a3,0x1e
    80003554:	bf868693          	addi	a3,a3,-1032 # 80021148 <log>
    80003558:	a039                	j	80003566 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000355a:	02090963          	beqz	s2,8000358c <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000355e:	08848493          	addi	s1,s1,136
    80003562:	02d48863          	beq	s1,a3,80003592 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003566:	449c                	lw	a5,8(s1)
    80003568:	fef059e3          	blez	a5,8000355a <iget+0x34>
    8000356c:	4098                	lw	a4,0(s1)
    8000356e:	ff3716e3          	bne	a4,s3,8000355a <iget+0x34>
    80003572:	40d8                	lw	a4,4(s1)
    80003574:	ff4713e3          	bne	a4,s4,8000355a <iget+0x34>
      ip->ref++;
    80003578:	2785                	addiw	a5,a5,1
    8000357a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000357c:	0001c517          	auipc	a0,0x1c
    80003580:	12450513          	addi	a0,a0,292 # 8001f6a0 <itable>
    80003584:	ee2fd0ef          	jal	80000c66 <release>
      return ip;
    80003588:	8926                	mv	s2,s1
    8000358a:	a02d                	j	800035b4 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358c:	fbe9                	bnez	a5,8000355e <iget+0x38>
      empty = ip;
    8000358e:	8926                	mv	s2,s1
    80003590:	b7f9                	j	8000355e <iget+0x38>
  if(empty == 0)
    80003592:	02090a63          	beqz	s2,800035c6 <iget+0xa0>
  ip->dev = dev;
    80003596:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000359a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359e:	4785                	li	a5,1
    800035a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035a8:	0001c517          	auipc	a0,0x1c
    800035ac:	0f850513          	addi	a0,a0,248 # 8001f6a0 <itable>
    800035b0:	eb6fd0ef          	jal	80000c66 <release>
}
    800035b4:	854a                	mv	a0,s2
    800035b6:	70a2                	ld	ra,40(sp)
    800035b8:	7402                	ld	s0,32(sp)
    800035ba:	64e2                	ld	s1,24(sp)
    800035bc:	6942                	ld	s2,16(sp)
    800035be:	69a2                	ld	s3,8(sp)
    800035c0:	6a02                	ld	s4,0(sp)
    800035c2:	6145                	addi	sp,sp,48
    800035c4:	8082                	ret
    panic("iget: no inodes");
    800035c6:	00004517          	auipc	a0,0x4
    800035ca:	e4a50513          	addi	a0,a0,-438 # 80007410 <etext+0x410>
    800035ce:	a12fd0ef          	jal	800007e0 <panic>

00000000800035d2 <iinit>:
{
    800035d2:	7179                	addi	sp,sp,-48
    800035d4:	f406                	sd	ra,40(sp)
    800035d6:	f022                	sd	s0,32(sp)
    800035d8:	ec26                	sd	s1,24(sp)
    800035da:	e84a                	sd	s2,16(sp)
    800035dc:	e44e                	sd	s3,8(sp)
    800035de:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e0:	00004597          	auipc	a1,0x4
    800035e4:	e4058593          	addi	a1,a1,-448 # 80007420 <etext+0x420>
    800035e8:	0001c517          	auipc	a0,0x1c
    800035ec:	0b850513          	addi	a0,a0,184 # 8001f6a0 <itable>
    800035f0:	d5efd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f4:	0001c497          	auipc	s1,0x1c
    800035f8:	0d448493          	addi	s1,s1,212 # 8001f6c8 <itable+0x28>
    800035fc:	0001e997          	auipc	s3,0x1e
    80003600:	b5c98993          	addi	s3,s3,-1188 # 80021158 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003604:	00004917          	auipc	s2,0x4
    80003608:	e2490913          	addi	s2,s2,-476 # 80007428 <etext+0x428>
    8000360c:	85ca                	mv	a1,s2
    8000360e:	8526                	mv	a0,s1
    80003610:	5bb000ef          	jal	800043ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003614:	08848493          	addi	s1,s1,136
    80003618:	ff349ae3          	bne	s1,s3,8000360c <iinit+0x3a>
}
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6145                	addi	sp,sp,48
    80003628:	8082                	ret

000000008000362a <ialloc>:
{
    8000362a:	7139                	addi	sp,sp,-64
    8000362c:	fc06                	sd	ra,56(sp)
    8000362e:	f822                	sd	s0,48(sp)
    80003630:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003632:	0001c717          	auipc	a4,0x1c
    80003636:	05a72703          	lw	a4,90(a4) # 8001f68c <sb+0xc>
    8000363a:	4785                	li	a5,1
    8000363c:	06e7f063          	bgeu	a5,a4,8000369c <ialloc+0x72>
    80003640:	f426                	sd	s1,40(sp)
    80003642:	f04a                	sd	s2,32(sp)
    80003644:	ec4e                	sd	s3,24(sp)
    80003646:	e852                	sd	s4,16(sp)
    80003648:	e456                	sd	s5,8(sp)
    8000364a:	e05a                	sd	s6,0(sp)
    8000364c:	8aaa                	mv	s5,a0
    8000364e:	8b2e                	mv	s6,a1
    80003650:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003652:	0001ca17          	auipc	s4,0x1c
    80003656:	02ea0a13          	addi	s4,s4,46 # 8001f680 <sb>
    8000365a:	00495593          	srli	a1,s2,0x4
    8000365e:	018a2783          	lw	a5,24(s4)
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	8556                	mv	a0,s5
    80003666:	a69ff0ef          	jal	800030ce <bread>
    8000366a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000366c:	05850993          	addi	s3,a0,88
    80003670:	00f97793          	andi	a5,s2,15
    80003674:	079a                	slli	a5,a5,0x6
    80003676:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003678:	00099783          	lh	a5,0(s3)
    8000367c:	cb9d                	beqz	a5,800036b2 <ialloc+0x88>
    brelse(bp);
    8000367e:	b59ff0ef          	jal	800031d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003682:	0905                	addi	s2,s2,1
    80003684:	00ca2703          	lw	a4,12(s4)
    80003688:	0009079b          	sext.w	a5,s2
    8000368c:	fce7e7e3          	bltu	a5,a4,8000365a <ialloc+0x30>
    80003690:	74a2                	ld	s1,40(sp)
    80003692:	7902                	ld	s2,32(sp)
    80003694:	69e2                	ld	s3,24(sp)
    80003696:	6a42                	ld	s4,16(sp)
    80003698:	6aa2                	ld	s5,8(sp)
    8000369a:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000369c:	00004517          	auipc	a0,0x4
    800036a0:	d9450513          	addi	a0,a0,-620 # 80007430 <etext+0x430>
    800036a4:	e57fc0ef          	jal	800004fa <printf>
  return 0;
    800036a8:	4501                	li	a0,0
}
    800036aa:	70e2                	ld	ra,56(sp)
    800036ac:	7442                	ld	s0,48(sp)
    800036ae:	6121                	addi	sp,sp,64
    800036b0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036b2:	04000613          	li	a2,64
    800036b6:	4581                	li	a1,0
    800036b8:	854e                	mv	a0,s3
    800036ba:	de8fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    800036be:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c2:	8526                	mv	a0,s1
    800036c4:	445000ef          	jal	80004308 <log_write>
      brelse(bp);
    800036c8:	8526                	mv	a0,s1
    800036ca:	b0dff0ef          	jal	800031d6 <brelse>
      return iget(dev, inum);
    800036ce:	0009059b          	sext.w	a1,s2
    800036d2:	8556                	mv	a0,s5
    800036d4:	e53ff0ef          	jal	80003526 <iget>
    800036d8:	74a2                	ld	s1,40(sp)
    800036da:	7902                	ld	s2,32(sp)
    800036dc:	69e2                	ld	s3,24(sp)
    800036de:	6a42                	ld	s4,16(sp)
    800036e0:	6aa2                	ld	s5,8(sp)
    800036e2:	6b02                	ld	s6,0(sp)
    800036e4:	b7d9                	j	800036aa <ialloc+0x80>

00000000800036e6 <iupdate>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	e04a                	sd	s2,0(sp)
    800036f0:	1000                	addi	s0,sp,32
    800036f2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f4:	415c                	lw	a5,4(a0)
    800036f6:	0047d79b          	srliw	a5,a5,0x4
    800036fa:	0001c597          	auipc	a1,0x1c
    800036fe:	f9e5a583          	lw	a1,-98(a1) # 8001f698 <sb+0x18>
    80003702:	9dbd                	addw	a1,a1,a5
    80003704:	4108                	lw	a0,0(a0)
    80003706:	9c9ff0ef          	jal	800030ce <bread>
    8000370a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000370c:	05850793          	addi	a5,a0,88
    80003710:	40d8                	lw	a4,4(s1)
    80003712:	8b3d                	andi	a4,a4,15
    80003714:	071a                	slli	a4,a4,0x6
    80003716:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003718:	04449703          	lh	a4,68(s1)
    8000371c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003720:	04649703          	lh	a4,70(s1)
    80003724:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003728:	04849703          	lh	a4,72(s1)
    8000372c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003730:	04a49703          	lh	a4,74(s1)
    80003734:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003738:	44f8                	lw	a4,76(s1)
    8000373a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000373c:	03400613          	li	a2,52
    80003740:	05048593          	addi	a1,s1,80
    80003744:	00c78513          	addi	a0,a5,12
    80003748:	db6fd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    8000374c:	854a                	mv	a0,s2
    8000374e:	3bb000ef          	jal	80004308 <log_write>
  brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	a83ff0ef          	jal	800031d6 <brelse>
}
    80003758:	60e2                	ld	ra,24(sp)
    8000375a:	6442                	ld	s0,16(sp)
    8000375c:	64a2                	ld	s1,8(sp)
    8000375e:	6902                	ld	s2,0(sp)
    80003760:	6105                	addi	sp,sp,32
    80003762:	8082                	ret

0000000080003764 <idup>:
{
    80003764:	1101                	addi	sp,sp,-32
    80003766:	ec06                	sd	ra,24(sp)
    80003768:	e822                	sd	s0,16(sp)
    8000376a:	e426                	sd	s1,8(sp)
    8000376c:	1000                	addi	s0,sp,32
    8000376e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003770:	0001c517          	auipc	a0,0x1c
    80003774:	f3050513          	addi	a0,a0,-208 # 8001f6a0 <itable>
    80003778:	c56fd0ef          	jal	80000bce <acquire>
  ip->ref++;
    8000377c:	449c                	lw	a5,8(s1)
    8000377e:	2785                	addiw	a5,a5,1
    80003780:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003782:	0001c517          	auipc	a0,0x1c
    80003786:	f1e50513          	addi	a0,a0,-226 # 8001f6a0 <itable>
    8000378a:	cdcfd0ef          	jal	80000c66 <release>
}
    8000378e:	8526                	mv	a0,s1
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6105                	addi	sp,sp,32
    80003798:	8082                	ret

000000008000379a <ilock>:
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a4:	cd19                	beqz	a0,800037c2 <ilock+0x28>
    800037a6:	84aa                	mv	s1,a0
    800037a8:	451c                	lw	a5,8(a0)
    800037aa:	00f05c63          	blez	a5,800037c2 <ilock+0x28>
  acquiresleep(&ip->lock);
    800037ae:	0541                	addi	a0,a0,16
    800037b0:	451000ef          	jal	80004400 <acquiresleep>
  if(ip->valid == 0){
    800037b4:	40bc                	lw	a5,64(s1)
    800037b6:	cf89                	beqz	a5,800037d0 <ilock+0x36>
}
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
    800037c2:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800037c4:	00004517          	auipc	a0,0x4
    800037c8:	c8450513          	addi	a0,a0,-892 # 80007448 <etext+0x448>
    800037cc:	814fd0ef          	jal	800007e0 <panic>
    800037d0:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d2:	40dc                	lw	a5,4(s1)
    800037d4:	0047d79b          	srliw	a5,a5,0x4
    800037d8:	0001c597          	auipc	a1,0x1c
    800037dc:	ec05a583          	lw	a1,-320(a1) # 8001f698 <sb+0x18>
    800037e0:	9dbd                	addw	a1,a1,a5
    800037e2:	4088                	lw	a0,0(s1)
    800037e4:	8ebff0ef          	jal	800030ce <bread>
    800037e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ea:	05850593          	addi	a1,a0,88
    800037ee:	40dc                	lw	a5,4(s1)
    800037f0:	8bbd                	andi	a5,a5,15
    800037f2:	079a                	slli	a5,a5,0x6
    800037f4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037f6:	00059783          	lh	a5,0(a1)
    800037fa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037fe:	00259783          	lh	a5,2(a1)
    80003802:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003806:	00459783          	lh	a5,4(a1)
    8000380a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000380e:	00659783          	lh	a5,6(a1)
    80003812:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003816:	459c                	lw	a5,8(a1)
    80003818:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000381a:	03400613          	li	a2,52
    8000381e:	05b1                	addi	a1,a1,12
    80003820:	05048513          	addi	a0,s1,80
    80003824:	cdafd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	9adff0ef          	jal	800031d6 <brelse>
    ip->valid = 1;
    8000382e:	4785                	li	a5,1
    80003830:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003832:	04449783          	lh	a5,68(s1)
    80003836:	c399                	beqz	a5,8000383c <ilock+0xa2>
    80003838:	6902                	ld	s2,0(sp)
    8000383a:	bfbd                	j	800037b8 <ilock+0x1e>
      panic("ilock: no type");
    8000383c:	00004517          	auipc	a0,0x4
    80003840:	c1450513          	addi	a0,a0,-1004 # 80007450 <etext+0x450>
    80003844:	f9dfc0ef          	jal	800007e0 <panic>

0000000080003848 <iunlock>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	e04a                	sd	s2,0(sp)
    80003852:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003854:	c505                	beqz	a0,8000387c <iunlock+0x34>
    80003856:	84aa                	mv	s1,a0
    80003858:	01050913          	addi	s2,a0,16
    8000385c:	854a                	mv	a0,s2
    8000385e:	421000ef          	jal	8000447e <holdingsleep>
    80003862:	cd09                	beqz	a0,8000387c <iunlock+0x34>
    80003864:	449c                	lw	a5,8(s1)
    80003866:	00f05b63          	blez	a5,8000387c <iunlock+0x34>
  releasesleep(&ip->lock);
    8000386a:	854a                	mv	a0,s2
    8000386c:	3db000ef          	jal	80004446 <releasesleep>
}
    80003870:	60e2                	ld	ra,24(sp)
    80003872:	6442                	ld	s0,16(sp)
    80003874:	64a2                	ld	s1,8(sp)
    80003876:	6902                	ld	s2,0(sp)
    80003878:	6105                	addi	sp,sp,32
    8000387a:	8082                	ret
    panic("iunlock");
    8000387c:	00004517          	auipc	a0,0x4
    80003880:	be450513          	addi	a0,a0,-1052 # 80007460 <etext+0x460>
    80003884:	f5dfc0ef          	jal	800007e0 <panic>

0000000080003888 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003888:	7179                	addi	sp,sp,-48
    8000388a:	f406                	sd	ra,40(sp)
    8000388c:	f022                	sd	s0,32(sp)
    8000388e:	ec26                	sd	s1,24(sp)
    80003890:	e84a                	sd	s2,16(sp)
    80003892:	e44e                	sd	s3,8(sp)
    80003894:	1800                	addi	s0,sp,48
    80003896:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003898:	05050493          	addi	s1,a0,80
    8000389c:	08050913          	addi	s2,a0,128
    800038a0:	a021                	j	800038a8 <itrunc+0x20>
    800038a2:	0491                	addi	s1,s1,4
    800038a4:	01248b63          	beq	s1,s2,800038ba <itrunc+0x32>
    if(ip->addrs[i]){
    800038a8:	408c                	lw	a1,0(s1)
    800038aa:	dde5                	beqz	a1,800038a2 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	a17ff0ef          	jal	800032c6 <bfree>
      ip->addrs[i] = 0;
    800038b4:	0004a023          	sw	zero,0(s1)
    800038b8:	b7ed                	j	800038a2 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ba:	0809a583          	lw	a1,128(s3)
    800038be:	ed89                	bnez	a1,800038d8 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c4:	854e                	mv	a0,s3
    800038c6:	e21ff0ef          	jal	800036e6 <iupdate>
}
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret
    800038d8:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038da:	0009a503          	lw	a0,0(s3)
    800038de:	ff0ff0ef          	jal	800030ce <bread>
    800038e2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e4:	05850493          	addi	s1,a0,88
    800038e8:	45850913          	addi	s2,a0,1112
    800038ec:	a021                	j	800038f4 <itrunc+0x6c>
    800038ee:	0491                	addi	s1,s1,4
    800038f0:	01248963          	beq	s1,s2,80003902 <itrunc+0x7a>
      if(a[j])
    800038f4:	408c                	lw	a1,0(s1)
    800038f6:	dde5                	beqz	a1,800038ee <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800038f8:	0009a503          	lw	a0,0(s3)
    800038fc:	9cbff0ef          	jal	800032c6 <bfree>
    80003900:	b7fd                	j	800038ee <itrunc+0x66>
    brelse(bp);
    80003902:	8552                	mv	a0,s4
    80003904:	8d3ff0ef          	jal	800031d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003908:	0809a583          	lw	a1,128(s3)
    8000390c:	0009a503          	lw	a0,0(s3)
    80003910:	9b7ff0ef          	jal	800032c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003914:	0809a023          	sw	zero,128(s3)
    80003918:	6a02                	ld	s4,0(sp)
    8000391a:	b75d                	j	800038c0 <itrunc+0x38>

000000008000391c <iput>:
{
    8000391c:	1101                	addi	sp,sp,-32
    8000391e:	ec06                	sd	ra,24(sp)
    80003920:	e822                	sd	s0,16(sp)
    80003922:	e426                	sd	s1,8(sp)
    80003924:	1000                	addi	s0,sp,32
    80003926:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003928:	0001c517          	auipc	a0,0x1c
    8000392c:	d7850513          	addi	a0,a0,-648 # 8001f6a0 <itable>
    80003930:	a9efd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003934:	4498                	lw	a4,8(s1)
    80003936:	4785                	li	a5,1
    80003938:	02f70063          	beq	a4,a5,80003958 <iput+0x3c>
  ip->ref--;
    8000393c:	449c                	lw	a5,8(s1)
    8000393e:	37fd                	addiw	a5,a5,-1
    80003940:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003942:	0001c517          	auipc	a0,0x1c
    80003946:	d5e50513          	addi	a0,a0,-674 # 8001f6a0 <itable>
    8000394a:	b1cfd0ef          	jal	80000c66 <release>
}
    8000394e:	60e2                	ld	ra,24(sp)
    80003950:	6442                	ld	s0,16(sp)
    80003952:	64a2                	ld	s1,8(sp)
    80003954:	6105                	addi	sp,sp,32
    80003956:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003958:	40bc                	lw	a5,64(s1)
    8000395a:	d3ed                	beqz	a5,8000393c <iput+0x20>
    8000395c:	04a49783          	lh	a5,74(s1)
    80003960:	fff1                	bnez	a5,8000393c <iput+0x20>
    80003962:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003964:	01048913          	addi	s2,s1,16
    80003968:	854a                	mv	a0,s2
    8000396a:	297000ef          	jal	80004400 <acquiresleep>
    release(&itable.lock);
    8000396e:	0001c517          	auipc	a0,0x1c
    80003972:	d3250513          	addi	a0,a0,-718 # 8001f6a0 <itable>
    80003976:	af0fd0ef          	jal	80000c66 <release>
    itrunc(ip);
    8000397a:	8526                	mv	a0,s1
    8000397c:	f0dff0ef          	jal	80003888 <itrunc>
    ip->type = 0;
    80003980:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003984:	8526                	mv	a0,s1
    80003986:	d61ff0ef          	jal	800036e6 <iupdate>
    ip->valid = 0;
    8000398a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000398e:	854a                	mv	a0,s2
    80003990:	2b7000ef          	jal	80004446 <releasesleep>
    acquire(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	d0c50513          	addi	a0,a0,-756 # 8001f6a0 <itable>
    8000399c:	a32fd0ef          	jal	80000bce <acquire>
    800039a0:	6902                	ld	s2,0(sp)
    800039a2:	bf69                	j	8000393c <iput+0x20>

00000000800039a4 <iunlockput>:
{
    800039a4:	1101                	addi	sp,sp,-32
    800039a6:	ec06                	sd	ra,24(sp)
    800039a8:	e822                	sd	s0,16(sp)
    800039aa:	e426                	sd	s1,8(sp)
    800039ac:	1000                	addi	s0,sp,32
    800039ae:	84aa                	mv	s1,a0
  iunlock(ip);
    800039b0:	e99ff0ef          	jal	80003848 <iunlock>
  iput(ip);
    800039b4:	8526                	mv	a0,s1
    800039b6:	f67ff0ef          	jal	8000391c <iput>
}
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	64a2                	ld	s1,8(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret

00000000800039c4 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800039c4:	0001c717          	auipc	a4,0x1c
    800039c8:	cc872703          	lw	a4,-824(a4) # 8001f68c <sb+0xc>
    800039cc:	4785                	li	a5,1
    800039ce:	0ae7ff63          	bgeu	a5,a4,80003a8c <ireclaim+0xc8>
{
    800039d2:	7139                	addi	sp,sp,-64
    800039d4:	fc06                	sd	ra,56(sp)
    800039d6:	f822                	sd	s0,48(sp)
    800039d8:	f426                	sd	s1,40(sp)
    800039da:	f04a                	sd	s2,32(sp)
    800039dc:	ec4e                	sd	s3,24(sp)
    800039de:	e852                	sd	s4,16(sp)
    800039e0:	e456                	sd	s5,8(sp)
    800039e2:	e05a                	sd	s6,0(sp)
    800039e4:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800039e6:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800039e8:	00050a1b          	sext.w	s4,a0
    800039ec:	0001ca97          	auipc	s5,0x1c
    800039f0:	c94a8a93          	addi	s5,s5,-876 # 8001f680 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800039f4:	00004b17          	auipc	s6,0x4
    800039f8:	a74b0b13          	addi	s6,s6,-1420 # 80007468 <etext+0x468>
    800039fc:	a099                	j	80003a42 <ireclaim+0x7e>
    800039fe:	85ce                	mv	a1,s3
    80003a00:	855a                	mv	a0,s6
    80003a02:	af9fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    80003a06:	85ce                	mv	a1,s3
    80003a08:	8552                	mv	a0,s4
    80003a0a:	b1dff0ef          	jal	80003526 <iget>
    80003a0e:	89aa                	mv	s3,a0
    brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	fc4ff0ef          	jal	800031d6 <brelse>
    if (ip) {
    80003a16:	00098f63          	beqz	s3,80003a34 <ireclaim+0x70>
      begin_op();
    80003a1a:	76a000ef          	jal	80004184 <begin_op>
      ilock(ip);
    80003a1e:	854e                	mv	a0,s3
    80003a20:	d7bff0ef          	jal	8000379a <ilock>
      iunlock(ip);
    80003a24:	854e                	mv	a0,s3
    80003a26:	e23ff0ef          	jal	80003848 <iunlock>
      iput(ip);
    80003a2a:	854e                	mv	a0,s3
    80003a2c:	ef1ff0ef          	jal	8000391c <iput>
      end_op();
    80003a30:	7be000ef          	jal	800041ee <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003a34:	0485                	addi	s1,s1,1
    80003a36:	00caa703          	lw	a4,12(s5)
    80003a3a:	0004879b          	sext.w	a5,s1
    80003a3e:	02e7fd63          	bgeu	a5,a4,80003a78 <ireclaim+0xb4>
    80003a42:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003a46:	0044d593          	srli	a1,s1,0x4
    80003a4a:	018aa783          	lw	a5,24(s5)
    80003a4e:	9dbd                	addw	a1,a1,a5
    80003a50:	8552                	mv	a0,s4
    80003a52:	e7cff0ef          	jal	800030ce <bread>
    80003a56:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003a58:	05850793          	addi	a5,a0,88
    80003a5c:	00f9f713          	andi	a4,s3,15
    80003a60:	071a                	slli	a4,a4,0x6
    80003a62:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003a64:	00079703          	lh	a4,0(a5)
    80003a68:	c701                	beqz	a4,80003a70 <ireclaim+0xac>
    80003a6a:	00679783          	lh	a5,6(a5)
    80003a6e:	dbc1                	beqz	a5,800039fe <ireclaim+0x3a>
    brelse(bp);
    80003a70:	854a                	mv	a0,s2
    80003a72:	f64ff0ef          	jal	800031d6 <brelse>
    if (ip) {
    80003a76:	bf7d                	j	80003a34 <ireclaim+0x70>
}
    80003a78:	70e2                	ld	ra,56(sp)
    80003a7a:	7442                	ld	s0,48(sp)
    80003a7c:	74a2                	ld	s1,40(sp)
    80003a7e:	7902                	ld	s2,32(sp)
    80003a80:	69e2                	ld	s3,24(sp)
    80003a82:	6a42                	ld	s4,16(sp)
    80003a84:	6aa2                	ld	s5,8(sp)
    80003a86:	6b02                	ld	s6,0(sp)
    80003a88:	6121                	addi	sp,sp,64
    80003a8a:	8082                	ret
    80003a8c:	8082                	ret

0000000080003a8e <fsinit>:
fsinit(int dev) {
    80003a8e:	7179                	addi	sp,sp,-48
    80003a90:	f406                	sd	ra,40(sp)
    80003a92:	f022                	sd	s0,32(sp)
    80003a94:	ec26                	sd	s1,24(sp)
    80003a96:	e84a                	sd	s2,16(sp)
    80003a98:	e44e                	sd	s3,8(sp)
    80003a9a:	1800                	addi	s0,sp,48
    80003a9c:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003a9e:	4585                	li	a1,1
    80003aa0:	e2eff0ef          	jal	800030ce <bread>
    80003aa4:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003aa6:	0001c997          	auipc	s3,0x1c
    80003aaa:	bda98993          	addi	s3,s3,-1062 # 8001f680 <sb>
    80003aae:	02000613          	li	a2,32
    80003ab2:	05850593          	addi	a1,a0,88
    80003ab6:	854e                	mv	a0,s3
    80003ab8:	a46fd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    80003abc:	854a                	mv	a0,s2
    80003abe:	f18ff0ef          	jal	800031d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003ac2:	0009a703          	lw	a4,0(s3)
    80003ac6:	102037b7          	lui	a5,0x10203
    80003aca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ace:	02f71363          	bne	a4,a5,80003af4 <fsinit+0x66>
  initlog(dev, &sb);
    80003ad2:	0001c597          	auipc	a1,0x1c
    80003ad6:	bae58593          	addi	a1,a1,-1106 # 8001f680 <sb>
    80003ada:	8526                	mv	a0,s1
    80003adc:	62a000ef          	jal	80004106 <initlog>
  ireclaim(dev);
    80003ae0:	8526                	mv	a0,s1
    80003ae2:	ee3ff0ef          	jal	800039c4 <ireclaim>
}
    80003ae6:	70a2                	ld	ra,40(sp)
    80003ae8:	7402                	ld	s0,32(sp)
    80003aea:	64e2                	ld	s1,24(sp)
    80003aec:	6942                	ld	s2,16(sp)
    80003aee:	69a2                	ld	s3,8(sp)
    80003af0:	6145                	addi	sp,sp,48
    80003af2:	8082                	ret
    panic("invalid file system");
    80003af4:	00004517          	auipc	a0,0x4
    80003af8:	99450513          	addi	a0,a0,-1644 # 80007488 <etext+0x488>
    80003afc:	ce5fc0ef          	jal	800007e0 <panic>

0000000080003b00 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b00:	1141                	addi	sp,sp,-16
    80003b02:	e422                	sd	s0,8(sp)
    80003b04:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b06:	411c                	lw	a5,0(a0)
    80003b08:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b0a:	415c                	lw	a5,4(a0)
    80003b0c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b0e:	04451783          	lh	a5,68(a0)
    80003b12:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b16:	04a51783          	lh	a5,74(a0)
    80003b1a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b1e:	04c56783          	lwu	a5,76(a0)
    80003b22:	e99c                	sd	a5,16(a1)
}
    80003b24:	6422                	ld	s0,8(sp)
    80003b26:	0141                	addi	sp,sp,16
    80003b28:	8082                	ret

0000000080003b2a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b2a:	457c                	lw	a5,76(a0)
    80003b2c:	0ed7eb63          	bltu	a5,a3,80003c22 <readi+0xf8>
{
    80003b30:	7159                	addi	sp,sp,-112
    80003b32:	f486                	sd	ra,104(sp)
    80003b34:	f0a2                	sd	s0,96(sp)
    80003b36:	eca6                	sd	s1,88(sp)
    80003b38:	e0d2                	sd	s4,64(sp)
    80003b3a:	fc56                	sd	s5,56(sp)
    80003b3c:	f85a                	sd	s6,48(sp)
    80003b3e:	f45e                	sd	s7,40(sp)
    80003b40:	1880                	addi	s0,sp,112
    80003b42:	8b2a                	mv	s6,a0
    80003b44:	8bae                	mv	s7,a1
    80003b46:	8a32                	mv	s4,a2
    80003b48:	84b6                	mv	s1,a3
    80003b4a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b50:	0cd76063          	bltu	a4,a3,80003c10 <readi+0xe6>
    80003b54:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003b56:	00e7f463          	bgeu	a5,a4,80003b5e <readi+0x34>
    n = ip->size - off;
    80003b5a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5e:	080a8f63          	beqz	s5,80003bfc <readi+0xd2>
    80003b62:	e8ca                	sd	s2,80(sp)
    80003b64:	f062                	sd	s8,32(sp)
    80003b66:	ec66                	sd	s9,24(sp)
    80003b68:	e86a                	sd	s10,16(sp)
    80003b6a:	e46e                	sd	s11,8(sp)
    80003b6c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b72:	5c7d                	li	s8,-1
    80003b74:	a80d                	j	80003ba6 <readi+0x7c>
    80003b76:	020d1d93          	slli	s11,s10,0x20
    80003b7a:	020ddd93          	srli	s11,s11,0x20
    80003b7e:	05890613          	addi	a2,s2,88
    80003b82:	86ee                	mv	a3,s11
    80003b84:	963a                	add	a2,a2,a4
    80003b86:	85d2                	mv	a1,s4
    80003b88:	855e                	mv	a0,s7
    80003b8a:	925fe0ef          	jal	800024ae <either_copyout>
    80003b8e:	05850763          	beq	a0,s8,80003bdc <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	e42ff0ef          	jal	800031d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b98:	013d09bb          	addw	s3,s10,s3
    80003b9c:	009d04bb          	addw	s1,s10,s1
    80003ba0:	9a6e                	add	s4,s4,s11
    80003ba2:	0559f763          	bgeu	s3,s5,80003bf0 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003ba6:	00a4d59b          	srliw	a1,s1,0xa
    80003baa:	855a                	mv	a0,s6
    80003bac:	8a7ff0ef          	jal	80003452 <bmap>
    80003bb0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bb4:	c5b1                	beqz	a1,80003c00 <readi+0xd6>
    bp = bread(ip->dev, addr);
    80003bb6:	000b2503          	lw	a0,0(s6)
    80003bba:	d14ff0ef          	jal	800030ce <bread>
    80003bbe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc0:	3ff4f713          	andi	a4,s1,1023
    80003bc4:	40ec87bb          	subw	a5,s9,a4
    80003bc8:	413a86bb          	subw	a3,s5,s3
    80003bcc:	8d3e                	mv	s10,a5
    80003bce:	2781                	sext.w	a5,a5
    80003bd0:	0006861b          	sext.w	a2,a3
    80003bd4:	faf671e3          	bgeu	a2,a5,80003b76 <readi+0x4c>
    80003bd8:	8d36                	mv	s10,a3
    80003bda:	bf71                	j	80003b76 <readi+0x4c>
      brelse(bp);
    80003bdc:	854a                	mv	a0,s2
    80003bde:	df8ff0ef          	jal	800031d6 <brelse>
      tot = -1;
    80003be2:	59fd                	li	s3,-1
      break;
    80003be4:	6946                	ld	s2,80(sp)
    80003be6:	7c02                	ld	s8,32(sp)
    80003be8:	6ce2                	ld	s9,24(sp)
    80003bea:	6d42                	ld	s10,16(sp)
    80003bec:	6da2                	ld	s11,8(sp)
    80003bee:	a831                	j	80003c0a <readi+0xe0>
    80003bf0:	6946                	ld	s2,80(sp)
    80003bf2:	7c02                	ld	s8,32(sp)
    80003bf4:	6ce2                	ld	s9,24(sp)
    80003bf6:	6d42                	ld	s10,16(sp)
    80003bf8:	6da2                	ld	s11,8(sp)
    80003bfa:	a801                	j	80003c0a <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfc:	89d6                	mv	s3,s5
    80003bfe:	a031                	j	80003c0a <readi+0xe0>
    80003c00:	6946                	ld	s2,80(sp)
    80003c02:	7c02                	ld	s8,32(sp)
    80003c04:	6ce2                	ld	s9,24(sp)
    80003c06:	6d42                	ld	s10,16(sp)
    80003c08:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003c0a:	0009851b          	sext.w	a0,s3
    80003c0e:	69a6                	ld	s3,72(sp)
}
    80003c10:	70a6                	ld	ra,104(sp)
    80003c12:	7406                	ld	s0,96(sp)
    80003c14:	64e6                	ld	s1,88(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	6165                	addi	sp,sp,112
    80003c20:	8082                	ret
    return 0;
    80003c22:	4501                	li	a0,0
}
    80003c24:	8082                	ret

0000000080003c26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c26:	457c                	lw	a5,76(a0)
    80003c28:	10d7e063          	bltu	a5,a3,80003d28 <writei+0x102>
{
    80003c2c:	7159                	addi	sp,sp,-112
    80003c2e:	f486                	sd	ra,104(sp)
    80003c30:	f0a2                	sd	s0,96(sp)
    80003c32:	e8ca                	sd	s2,80(sp)
    80003c34:	e0d2                	sd	s4,64(sp)
    80003c36:	fc56                	sd	s5,56(sp)
    80003c38:	f85a                	sd	s6,48(sp)
    80003c3a:	f45e                	sd	s7,40(sp)
    80003c3c:	1880                	addi	s0,sp,112
    80003c3e:	8aaa                	mv	s5,a0
    80003c40:	8bae                	mv	s7,a1
    80003c42:	8a32                	mv	s4,a2
    80003c44:	8936                	mv	s2,a3
    80003c46:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c48:	00e687bb          	addw	a5,a3,a4
    80003c4c:	0ed7e063          	bltu	a5,a3,80003d2c <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c50:	00043737          	lui	a4,0x43
    80003c54:	0cf76e63          	bltu	a4,a5,80003d30 <writei+0x10a>
    80003c58:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c5a:	0a0b0f63          	beqz	s6,80003d18 <writei+0xf2>
    80003c5e:	eca6                	sd	s1,88(sp)
    80003c60:	f062                	sd	s8,32(sp)
    80003c62:	ec66                	sd	s9,24(sp)
    80003c64:	e86a                	sd	s10,16(sp)
    80003c66:	e46e                	sd	s11,8(sp)
    80003c68:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c6e:	5c7d                	li	s8,-1
    80003c70:	a825                	j	80003ca8 <writei+0x82>
    80003c72:	020d1d93          	slli	s11,s10,0x20
    80003c76:	020ddd93          	srli	s11,s11,0x20
    80003c7a:	05848513          	addi	a0,s1,88
    80003c7e:	86ee                	mv	a3,s11
    80003c80:	8652                	mv	a2,s4
    80003c82:	85de                	mv	a1,s7
    80003c84:	953a                	add	a0,a0,a4
    80003c86:	873fe0ef          	jal	800024f8 <either_copyin>
    80003c8a:	05850a63          	beq	a0,s8,80003cde <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c8e:	8526                	mv	a0,s1
    80003c90:	678000ef          	jal	80004308 <log_write>
    brelse(bp);
    80003c94:	8526                	mv	a0,s1
    80003c96:	d40ff0ef          	jal	800031d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9a:	013d09bb          	addw	s3,s10,s3
    80003c9e:	012d093b          	addw	s2,s10,s2
    80003ca2:	9a6e                	add	s4,s4,s11
    80003ca4:	0569f063          	bgeu	s3,s6,80003ce4 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003ca8:	00a9559b          	srliw	a1,s2,0xa
    80003cac:	8556                	mv	a0,s5
    80003cae:	fa4ff0ef          	jal	80003452 <bmap>
    80003cb2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cb6:	c59d                	beqz	a1,80003ce4 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003cb8:	000aa503          	lw	a0,0(s5)
    80003cbc:	c12ff0ef          	jal	800030ce <bread>
    80003cc0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc2:	3ff97713          	andi	a4,s2,1023
    80003cc6:	40ec87bb          	subw	a5,s9,a4
    80003cca:	413b06bb          	subw	a3,s6,s3
    80003cce:	8d3e                	mv	s10,a5
    80003cd0:	2781                	sext.w	a5,a5
    80003cd2:	0006861b          	sext.w	a2,a3
    80003cd6:	f8f67ee3          	bgeu	a2,a5,80003c72 <writei+0x4c>
    80003cda:	8d36                	mv	s10,a3
    80003cdc:	bf59                	j	80003c72 <writei+0x4c>
      brelse(bp);
    80003cde:	8526                	mv	a0,s1
    80003ce0:	cf6ff0ef          	jal	800031d6 <brelse>
  }

  if(off > ip->size)
    80003ce4:	04caa783          	lw	a5,76(s5)
    80003ce8:	0327fa63          	bgeu	a5,s2,80003d1c <writei+0xf6>
    ip->size = off;
    80003cec:	052aa623          	sw	s2,76(s5)
    80003cf0:	64e6                	ld	s1,88(sp)
    80003cf2:	7c02                	ld	s8,32(sp)
    80003cf4:	6ce2                	ld	s9,24(sp)
    80003cf6:	6d42                	ld	s10,16(sp)
    80003cf8:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cfa:	8556                	mv	a0,s5
    80003cfc:	9ebff0ef          	jal	800036e6 <iupdate>

  return tot;
    80003d00:	0009851b          	sext.w	a0,s3
    80003d04:	69a6                	ld	s3,72(sp)
}
    80003d06:	70a6                	ld	ra,104(sp)
    80003d08:	7406                	ld	s0,96(sp)
    80003d0a:	6946                	ld	s2,80(sp)
    80003d0c:	6a06                	ld	s4,64(sp)
    80003d0e:	7ae2                	ld	s5,56(sp)
    80003d10:	7b42                	ld	s6,48(sp)
    80003d12:	7ba2                	ld	s7,40(sp)
    80003d14:	6165                	addi	sp,sp,112
    80003d16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d18:	89da                	mv	s3,s6
    80003d1a:	b7c5                	j	80003cfa <writei+0xd4>
    80003d1c:	64e6                	ld	s1,88(sp)
    80003d1e:	7c02                	ld	s8,32(sp)
    80003d20:	6ce2                	ld	s9,24(sp)
    80003d22:	6d42                	ld	s10,16(sp)
    80003d24:	6da2                	ld	s11,8(sp)
    80003d26:	bfd1                	j	80003cfa <writei+0xd4>
    return -1;
    80003d28:	557d                	li	a0,-1
}
    80003d2a:	8082                	ret
    return -1;
    80003d2c:	557d                	li	a0,-1
    80003d2e:	bfe1                	j	80003d06 <writei+0xe0>
    return -1;
    80003d30:	557d                	li	a0,-1
    80003d32:	bfd1                	j	80003d06 <writei+0xe0>

0000000080003d34 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d34:	1141                	addi	sp,sp,-16
    80003d36:	e406                	sd	ra,8(sp)
    80003d38:	e022                	sd	s0,0(sp)
    80003d3a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d3c:	4639                	li	a2,14
    80003d3e:	830fd0ef          	jal	80000d6e <strncmp>
}
    80003d42:	60a2                	ld	ra,8(sp)
    80003d44:	6402                	ld	s0,0(sp)
    80003d46:	0141                	addi	sp,sp,16
    80003d48:	8082                	ret

0000000080003d4a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d4a:	7139                	addi	sp,sp,-64
    80003d4c:	fc06                	sd	ra,56(sp)
    80003d4e:	f822                	sd	s0,48(sp)
    80003d50:	f426                	sd	s1,40(sp)
    80003d52:	f04a                	sd	s2,32(sp)
    80003d54:	ec4e                	sd	s3,24(sp)
    80003d56:	e852                	sd	s4,16(sp)
    80003d58:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d5a:	04451703          	lh	a4,68(a0)
    80003d5e:	4785                	li	a5,1
    80003d60:	00f71a63          	bne	a4,a5,80003d74 <dirlookup+0x2a>
    80003d64:	892a                	mv	s2,a0
    80003d66:	89ae                	mv	s3,a1
    80003d68:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6a:	457c                	lw	a5,76(a0)
    80003d6c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d6e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d70:	e39d                	bnez	a5,80003d96 <dirlookup+0x4c>
    80003d72:	a095                	j	80003dd6 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003d74:	00003517          	auipc	a0,0x3
    80003d78:	72c50513          	addi	a0,a0,1836 # 800074a0 <etext+0x4a0>
    80003d7c:	a65fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003d80:	00003517          	auipc	a0,0x3
    80003d84:	73850513          	addi	a0,a0,1848 # 800074b8 <etext+0x4b8>
    80003d88:	a59fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8c:	24c1                	addiw	s1,s1,16
    80003d8e:	04c92783          	lw	a5,76(s2)
    80003d92:	04f4f163          	bgeu	s1,a5,80003dd4 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d96:	4741                	li	a4,16
    80003d98:	86a6                	mv	a3,s1
    80003d9a:	fc040613          	addi	a2,s0,-64
    80003d9e:	4581                	li	a1,0
    80003da0:	854a                	mv	a0,s2
    80003da2:	d89ff0ef          	jal	80003b2a <readi>
    80003da6:	47c1                	li	a5,16
    80003da8:	fcf51ce3          	bne	a0,a5,80003d80 <dirlookup+0x36>
    if(de.inum == 0)
    80003dac:	fc045783          	lhu	a5,-64(s0)
    80003db0:	dff1                	beqz	a5,80003d8c <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003db2:	fc240593          	addi	a1,s0,-62
    80003db6:	854e                	mv	a0,s3
    80003db8:	f7dff0ef          	jal	80003d34 <namecmp>
    80003dbc:	f961                	bnez	a0,80003d8c <dirlookup+0x42>
      if(poff)
    80003dbe:	000a0463          	beqz	s4,80003dc6 <dirlookup+0x7c>
        *poff = off;
    80003dc2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc6:	fc045583          	lhu	a1,-64(s0)
    80003dca:	00092503          	lw	a0,0(s2)
    80003dce:	f58ff0ef          	jal	80003526 <iget>
    80003dd2:	a011                	j	80003dd6 <dirlookup+0x8c>
  return 0;
    80003dd4:	4501                	li	a0,0
}
    80003dd6:	70e2                	ld	ra,56(sp)
    80003dd8:	7442                	ld	s0,48(sp)
    80003dda:	74a2                	ld	s1,40(sp)
    80003ddc:	7902                	ld	s2,32(sp)
    80003dde:	69e2                	ld	s3,24(sp)
    80003de0:	6a42                	ld	s4,16(sp)
    80003de2:	6121                	addi	sp,sp,64
    80003de4:	8082                	ret

0000000080003de6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de6:	711d                	addi	sp,sp,-96
    80003de8:	ec86                	sd	ra,88(sp)
    80003dea:	e8a2                	sd	s0,80(sp)
    80003dec:	e4a6                	sd	s1,72(sp)
    80003dee:	e0ca                	sd	s2,64(sp)
    80003df0:	fc4e                	sd	s3,56(sp)
    80003df2:	f852                	sd	s4,48(sp)
    80003df4:	f456                	sd	s5,40(sp)
    80003df6:	f05a                	sd	s6,32(sp)
    80003df8:	ec5e                	sd	s7,24(sp)
    80003dfa:	e862                	sd	s8,16(sp)
    80003dfc:	e466                	sd	s9,8(sp)
    80003dfe:	1080                	addi	s0,sp,96
    80003e00:	84aa                	mv	s1,a0
    80003e02:	8b2e                	mv	s6,a1
    80003e04:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e06:	00054703          	lbu	a4,0(a0)
    80003e0a:	02f00793          	li	a5,47
    80003e0e:	00f70e63          	beq	a4,a5,80003e2a <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e12:	abdfd0ef          	jal	800018ce <myproc>
    80003e16:	15053503          	ld	a0,336(a0)
    80003e1a:	94bff0ef          	jal	80003764 <idup>
    80003e1e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e20:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e24:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e26:	4b85                	li	s7,1
    80003e28:	a871                	j	80003ec4 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003e2a:	4585                	li	a1,1
    80003e2c:	4505                	li	a0,1
    80003e2e:	ef8ff0ef          	jal	80003526 <iget>
    80003e32:	8a2a                	mv	s4,a0
    80003e34:	b7f5                	j	80003e20 <namex+0x3a>
      iunlockput(ip);
    80003e36:	8552                	mv	a0,s4
    80003e38:	b6dff0ef          	jal	800039a4 <iunlockput>
      return 0;
    80003e3c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e3e:	8552                	mv	a0,s4
    80003e40:	60e6                	ld	ra,88(sp)
    80003e42:	6446                	ld	s0,80(sp)
    80003e44:	64a6                	ld	s1,72(sp)
    80003e46:	6906                	ld	s2,64(sp)
    80003e48:	79e2                	ld	s3,56(sp)
    80003e4a:	7a42                	ld	s4,48(sp)
    80003e4c:	7aa2                	ld	s5,40(sp)
    80003e4e:	7b02                	ld	s6,32(sp)
    80003e50:	6be2                	ld	s7,24(sp)
    80003e52:	6c42                	ld	s8,16(sp)
    80003e54:	6ca2                	ld	s9,8(sp)
    80003e56:	6125                	addi	sp,sp,96
    80003e58:	8082                	ret
      iunlock(ip);
    80003e5a:	8552                	mv	a0,s4
    80003e5c:	9edff0ef          	jal	80003848 <iunlock>
      return ip;
    80003e60:	bff9                	j	80003e3e <namex+0x58>
      iunlockput(ip);
    80003e62:	8552                	mv	a0,s4
    80003e64:	b41ff0ef          	jal	800039a4 <iunlockput>
      return 0;
    80003e68:	8a4e                	mv	s4,s3
    80003e6a:	bfd1                	j	80003e3e <namex+0x58>
  len = path - s;
    80003e6c:	40998633          	sub	a2,s3,s1
    80003e70:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e74:	099c5063          	bge	s8,s9,80003ef4 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003e78:	4639                	li	a2,14
    80003e7a:	85a6                	mv	a1,s1
    80003e7c:	8556                	mv	a0,s5
    80003e7e:	e81fc0ef          	jal	80000cfe <memmove>
    80003e82:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e84:	0004c783          	lbu	a5,0(s1)
    80003e88:	01279763          	bne	a5,s2,80003e96 <namex+0xb0>
    path++;
    80003e8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8e:	0004c783          	lbu	a5,0(s1)
    80003e92:	ff278de3          	beq	a5,s2,80003e8c <namex+0xa6>
    ilock(ip);
    80003e96:	8552                	mv	a0,s4
    80003e98:	903ff0ef          	jal	8000379a <ilock>
    if(ip->type != T_DIR){
    80003e9c:	044a1783          	lh	a5,68(s4)
    80003ea0:	f9779be3          	bne	a5,s7,80003e36 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003ea4:	000b0563          	beqz	s6,80003eae <namex+0xc8>
    80003ea8:	0004c783          	lbu	a5,0(s1)
    80003eac:	d7dd                	beqz	a5,80003e5a <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eae:	4601                	li	a2,0
    80003eb0:	85d6                	mv	a1,s5
    80003eb2:	8552                	mv	a0,s4
    80003eb4:	e97ff0ef          	jal	80003d4a <dirlookup>
    80003eb8:	89aa                	mv	s3,a0
    80003eba:	d545                	beqz	a0,80003e62 <namex+0x7c>
    iunlockput(ip);
    80003ebc:	8552                	mv	a0,s4
    80003ebe:	ae7ff0ef          	jal	800039a4 <iunlockput>
    ip = next;
    80003ec2:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ec4:	0004c783          	lbu	a5,0(s1)
    80003ec8:	01279763          	bne	a5,s2,80003ed6 <namex+0xf0>
    path++;
    80003ecc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ece:	0004c783          	lbu	a5,0(s1)
    80003ed2:	ff278de3          	beq	a5,s2,80003ecc <namex+0xe6>
  if(*path == 0)
    80003ed6:	cb8d                	beqz	a5,80003f08 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003ed8:	0004c783          	lbu	a5,0(s1)
    80003edc:	89a6                	mv	s3,s1
  len = path - s;
    80003ede:	4c81                	li	s9,0
    80003ee0:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ee2:	01278963          	beq	a5,s2,80003ef4 <namex+0x10e>
    80003ee6:	d3d9                	beqz	a5,80003e6c <namex+0x86>
    path++;
    80003ee8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003eea:	0009c783          	lbu	a5,0(s3)
    80003eee:	ff279ce3          	bne	a5,s2,80003ee6 <namex+0x100>
    80003ef2:	bfad                	j	80003e6c <namex+0x86>
    memmove(name, s, len);
    80003ef4:	2601                	sext.w	a2,a2
    80003ef6:	85a6                	mv	a1,s1
    80003ef8:	8556                	mv	a0,s5
    80003efa:	e05fc0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003efe:	9cd6                	add	s9,s9,s5
    80003f00:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f04:	84ce                	mv	s1,s3
    80003f06:	bfbd                	j	80003e84 <namex+0x9e>
  if(nameiparent){
    80003f08:	f20b0be3          	beqz	s6,80003e3e <namex+0x58>
    iput(ip);
    80003f0c:	8552                	mv	a0,s4
    80003f0e:	a0fff0ef          	jal	8000391c <iput>
    return 0;
    80003f12:	4a01                	li	s4,0
    80003f14:	b72d                	j	80003e3e <namex+0x58>

0000000080003f16 <dirlink>:
{
    80003f16:	7139                	addi	sp,sp,-64
    80003f18:	fc06                	sd	ra,56(sp)
    80003f1a:	f822                	sd	s0,48(sp)
    80003f1c:	f04a                	sd	s2,32(sp)
    80003f1e:	ec4e                	sd	s3,24(sp)
    80003f20:	e852                	sd	s4,16(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	892a                	mv	s2,a0
    80003f26:	8a2e                	mv	s4,a1
    80003f28:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f2a:	4601                	li	a2,0
    80003f2c:	e1fff0ef          	jal	80003d4a <dirlookup>
    80003f30:	e535                	bnez	a0,80003f9c <dirlink+0x86>
    80003f32:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f34:	04c92483          	lw	s1,76(s2)
    80003f38:	c48d                	beqz	s1,80003f62 <dirlink+0x4c>
    80003f3a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3c:	4741                	li	a4,16
    80003f3e:	86a6                	mv	a3,s1
    80003f40:	fc040613          	addi	a2,s0,-64
    80003f44:	4581                	li	a1,0
    80003f46:	854a                	mv	a0,s2
    80003f48:	be3ff0ef          	jal	80003b2a <readi>
    80003f4c:	47c1                	li	a5,16
    80003f4e:	04f51b63          	bne	a0,a5,80003fa4 <dirlink+0x8e>
    if(de.inum == 0)
    80003f52:	fc045783          	lhu	a5,-64(s0)
    80003f56:	c791                	beqz	a5,80003f62 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f58:	24c1                	addiw	s1,s1,16
    80003f5a:	04c92783          	lw	a5,76(s2)
    80003f5e:	fcf4efe3          	bltu	s1,a5,80003f3c <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003f62:	4639                	li	a2,14
    80003f64:	85d2                	mv	a1,s4
    80003f66:	fc240513          	addi	a0,s0,-62
    80003f6a:	e3bfc0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003f6e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f72:	4741                	li	a4,16
    80003f74:	86a6                	mv	a3,s1
    80003f76:	fc040613          	addi	a2,s0,-64
    80003f7a:	4581                	li	a1,0
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	ca9ff0ef          	jal	80003c26 <writei>
    80003f82:	1541                	addi	a0,a0,-16
    80003f84:	00a03533          	snez	a0,a0
    80003f88:	40a00533          	neg	a0,a0
    80003f8c:	74a2                	ld	s1,40(sp)
}
    80003f8e:	70e2                	ld	ra,56(sp)
    80003f90:	7442                	ld	s0,48(sp)
    80003f92:	7902                	ld	s2,32(sp)
    80003f94:	69e2                	ld	s3,24(sp)
    80003f96:	6a42                	ld	s4,16(sp)
    80003f98:	6121                	addi	sp,sp,64
    80003f9a:	8082                	ret
    iput(ip);
    80003f9c:	981ff0ef          	jal	8000391c <iput>
    return -1;
    80003fa0:	557d                	li	a0,-1
    80003fa2:	b7f5                	j	80003f8e <dirlink+0x78>
      panic("dirlink read");
    80003fa4:	00003517          	auipc	a0,0x3
    80003fa8:	52450513          	addi	a0,a0,1316 # 800074c8 <etext+0x4c8>
    80003fac:	835fc0ef          	jal	800007e0 <panic>

0000000080003fb0 <namei>:

struct inode*
namei(char *path)
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fb8:	fe040613          	addi	a2,s0,-32
    80003fbc:	4581                	li	a1,0
    80003fbe:	e29ff0ef          	jal	80003de6 <namex>
}
    80003fc2:	60e2                	ld	ra,24(sp)
    80003fc4:	6442                	ld	s0,16(sp)
    80003fc6:	6105                	addi	sp,sp,32
    80003fc8:	8082                	ret

0000000080003fca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fca:	1141                	addi	sp,sp,-16
    80003fcc:	e406                	sd	ra,8(sp)
    80003fce:	e022                	sd	s0,0(sp)
    80003fd0:	0800                	addi	s0,sp,16
    80003fd2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fd4:	4585                	li	a1,1
    80003fd6:	e11ff0ef          	jal	80003de6 <namex>
}
    80003fda:	60a2                	ld	ra,8(sp)
    80003fdc:	6402                	ld	s0,0(sp)
    80003fde:	0141                	addi	sp,sp,16
    80003fe0:	8082                	ret

0000000080003fe2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fe2:	1101                	addi	sp,sp,-32
    80003fe4:	ec06                	sd	ra,24(sp)
    80003fe6:	e822                	sd	s0,16(sp)
    80003fe8:	e426                	sd	s1,8(sp)
    80003fea:	e04a                	sd	s2,0(sp)
    80003fec:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fee:	0001d917          	auipc	s2,0x1d
    80003ff2:	15a90913          	addi	s2,s2,346 # 80021148 <log>
    80003ff6:	01892583          	lw	a1,24(s2)
    80003ffa:	02492503          	lw	a0,36(s2)
    80003ffe:	8d0ff0ef          	jal	800030ce <bread>
    80004002:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004004:	02892603          	lw	a2,40(s2)
    80004008:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000400a:	00c05f63          	blez	a2,80004028 <write_head+0x46>
    8000400e:	0001d717          	auipc	a4,0x1d
    80004012:	16670713          	addi	a4,a4,358 # 80021174 <log+0x2c>
    80004016:	87aa                	mv	a5,a0
    80004018:	060a                	slli	a2,a2,0x2
    8000401a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000401c:	4314                	lw	a3,0(a4)
    8000401e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004020:	0711                	addi	a4,a4,4
    80004022:	0791                	addi	a5,a5,4
    80004024:	fec79ce3          	bne	a5,a2,8000401c <write_head+0x3a>
  }
  bwrite(buf);
    80004028:	8526                	mv	a0,s1
    8000402a:	97aff0ef          	jal	800031a4 <bwrite>
  brelse(buf);
    8000402e:	8526                	mv	a0,s1
    80004030:	9a6ff0ef          	jal	800031d6 <brelse>
}
    80004034:	60e2                	ld	ra,24(sp)
    80004036:	6442                	ld	s0,16(sp)
    80004038:	64a2                	ld	s1,8(sp)
    8000403a:	6902                	ld	s2,0(sp)
    8000403c:	6105                	addi	sp,sp,32
    8000403e:	8082                	ret

0000000080004040 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004040:	0001d797          	auipc	a5,0x1d
    80004044:	1307a783          	lw	a5,304(a5) # 80021170 <log+0x28>
    80004048:	0af05e63          	blez	a5,80004104 <install_trans+0xc4>
{
    8000404c:	715d                	addi	sp,sp,-80
    8000404e:	e486                	sd	ra,72(sp)
    80004050:	e0a2                	sd	s0,64(sp)
    80004052:	fc26                	sd	s1,56(sp)
    80004054:	f84a                	sd	s2,48(sp)
    80004056:	f44e                	sd	s3,40(sp)
    80004058:	f052                	sd	s4,32(sp)
    8000405a:	ec56                	sd	s5,24(sp)
    8000405c:	e85a                	sd	s6,16(sp)
    8000405e:	e45e                	sd	s7,8(sp)
    80004060:	0880                	addi	s0,sp,80
    80004062:	8b2a                	mv	s6,a0
    80004064:	0001da97          	auipc	s5,0x1d
    80004068:	110a8a93          	addi	s5,s5,272 # 80021174 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000406c:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    8000406e:	00003b97          	auipc	s7,0x3
    80004072:	46ab8b93          	addi	s7,s7,1130 # 800074d8 <etext+0x4d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004076:	0001da17          	auipc	s4,0x1d
    8000407a:	0d2a0a13          	addi	s4,s4,210 # 80021148 <log>
    8000407e:	a025                	j	800040a6 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80004080:	000aa603          	lw	a2,0(s5)
    80004084:	85ce                	mv	a1,s3
    80004086:	855e                	mv	a0,s7
    80004088:	c72fc0ef          	jal	800004fa <printf>
    8000408c:	a839                	j	800040aa <install_trans+0x6a>
    brelse(lbuf);
    8000408e:	854a                	mv	a0,s2
    80004090:	946ff0ef          	jal	800031d6 <brelse>
    brelse(dbuf);
    80004094:	8526                	mv	a0,s1
    80004096:	940ff0ef          	jal	800031d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409a:	2985                	addiw	s3,s3,1
    8000409c:	0a91                	addi	s5,s5,4
    8000409e:	028a2783          	lw	a5,40(s4)
    800040a2:	04f9d663          	bge	s3,a5,800040ee <install_trans+0xae>
    if(recovering) {
    800040a6:	fc0b1de3          	bnez	s6,80004080 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040aa:	018a2583          	lw	a1,24(s4)
    800040ae:	013585bb          	addw	a1,a1,s3
    800040b2:	2585                	addiw	a1,a1,1
    800040b4:	024a2503          	lw	a0,36(s4)
    800040b8:	816ff0ef          	jal	800030ce <bread>
    800040bc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040be:	000aa583          	lw	a1,0(s5)
    800040c2:	024a2503          	lw	a0,36(s4)
    800040c6:	808ff0ef          	jal	800030ce <bread>
    800040ca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040cc:	40000613          	li	a2,1024
    800040d0:	05890593          	addi	a1,s2,88
    800040d4:	05850513          	addi	a0,a0,88
    800040d8:	c27fc0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    800040dc:	8526                	mv	a0,s1
    800040de:	8c6ff0ef          	jal	800031a4 <bwrite>
    if(recovering == 0)
    800040e2:	fa0b16e3          	bnez	s6,8000408e <install_trans+0x4e>
      bunpin(dbuf);
    800040e6:	8526                	mv	a0,s1
    800040e8:	9aaff0ef          	jal	80003292 <bunpin>
    800040ec:	b74d                	j	8000408e <install_trans+0x4e>
}
    800040ee:	60a6                	ld	ra,72(sp)
    800040f0:	6406                	ld	s0,64(sp)
    800040f2:	74e2                	ld	s1,56(sp)
    800040f4:	7942                	ld	s2,48(sp)
    800040f6:	79a2                	ld	s3,40(sp)
    800040f8:	7a02                	ld	s4,32(sp)
    800040fa:	6ae2                	ld	s5,24(sp)
    800040fc:	6b42                	ld	s6,16(sp)
    800040fe:	6ba2                	ld	s7,8(sp)
    80004100:	6161                	addi	sp,sp,80
    80004102:	8082                	ret
    80004104:	8082                	ret

0000000080004106 <initlog>:
{
    80004106:	7179                	addi	sp,sp,-48
    80004108:	f406                	sd	ra,40(sp)
    8000410a:	f022                	sd	s0,32(sp)
    8000410c:	ec26                	sd	s1,24(sp)
    8000410e:	e84a                	sd	s2,16(sp)
    80004110:	e44e                	sd	s3,8(sp)
    80004112:	1800                	addi	s0,sp,48
    80004114:	892a                	mv	s2,a0
    80004116:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004118:	0001d497          	auipc	s1,0x1d
    8000411c:	03048493          	addi	s1,s1,48 # 80021148 <log>
    80004120:	00003597          	auipc	a1,0x3
    80004124:	3d858593          	addi	a1,a1,984 # 800074f8 <etext+0x4f8>
    80004128:	8526                	mv	a0,s1
    8000412a:	a25fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    8000412e:	0149a583          	lw	a1,20(s3)
    80004132:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80004134:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004138:	854a                	mv	a0,s2
    8000413a:	f95fe0ef          	jal	800030ce <bread>
  log.lh.n = lh->n;
    8000413e:	4d30                	lw	a2,88(a0)
    80004140:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	00c05f63          	blez	a2,80004160 <initlog+0x5a>
    80004146:	87aa                	mv	a5,a0
    80004148:	0001d717          	auipc	a4,0x1d
    8000414c:	02c70713          	addi	a4,a4,44 # 80021174 <log+0x2c>
    80004150:	060a                	slli	a2,a2,0x2
    80004152:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004154:	4ff4                	lw	a3,92(a5)
    80004156:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004158:	0791                	addi	a5,a5,4
    8000415a:	0711                	addi	a4,a4,4
    8000415c:	fec79ce3          	bne	a5,a2,80004154 <initlog+0x4e>
  brelse(buf);
    80004160:	876ff0ef          	jal	800031d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004164:	4505                	li	a0,1
    80004166:	edbff0ef          	jal	80004040 <install_trans>
  log.lh.n = 0;
    8000416a:	0001d797          	auipc	a5,0x1d
    8000416e:	0007a323          	sw	zero,6(a5) # 80021170 <log+0x28>
  write_head(); // clear the log
    80004172:	e71ff0ef          	jal	80003fe2 <write_head>
}
    80004176:	70a2                	ld	ra,40(sp)
    80004178:	7402                	ld	s0,32(sp)
    8000417a:	64e2                	ld	s1,24(sp)
    8000417c:	6942                	ld	s2,16(sp)
    8000417e:	69a2                	ld	s3,8(sp)
    80004180:	6145                	addi	sp,sp,48
    80004182:	8082                	ret

0000000080004184 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004184:	1101                	addi	sp,sp,-32
    80004186:	ec06                	sd	ra,24(sp)
    80004188:	e822                	sd	s0,16(sp)
    8000418a:	e426                	sd	s1,8(sp)
    8000418c:	e04a                	sd	s2,0(sp)
    8000418e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004190:	0001d517          	auipc	a0,0x1d
    80004194:	fb850513          	addi	a0,a0,-72 # 80021148 <log>
    80004198:	a37fc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    8000419c:	0001d497          	auipc	s1,0x1d
    800041a0:	fac48493          	addi	s1,s1,-84 # 80021148 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    800041a4:	4979                	li	s2,30
    800041a6:	a029                	j	800041b0 <begin_op+0x2c>
      sleep(&log, &log.lock);
    800041a8:	85a6                	mv	a1,s1
    800041aa:	8526                	mv	a0,s1
    800041ac:	fa3fd0ef          	jal	8000214e <sleep>
    if(log.committing){
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	fbfd                	bnez	a5,800041a8 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    800041b4:	4cd8                	lw	a4,28(s1)
    800041b6:	2705                	addiw	a4,a4,1
    800041b8:	0027179b          	slliw	a5,a4,0x2
    800041bc:	9fb9                	addw	a5,a5,a4
    800041be:	0017979b          	slliw	a5,a5,0x1
    800041c2:	5494                	lw	a3,40(s1)
    800041c4:	9fb5                	addw	a5,a5,a3
    800041c6:	00f95763          	bge	s2,a5,800041d4 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ca:	85a6                	mv	a1,s1
    800041cc:	8526                	mv	a0,s1
    800041ce:	f81fd0ef          	jal	8000214e <sleep>
    800041d2:	bff9                	j	800041b0 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    800041d4:	0001d517          	auipc	a0,0x1d
    800041d8:	f7450513          	addi	a0,a0,-140 # 80021148 <log>
    800041dc:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    800041de:	a89fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    800041e2:	60e2                	ld	ra,24(sp)
    800041e4:	6442                	ld	s0,16(sp)
    800041e6:	64a2                	ld	s1,8(sp)
    800041e8:	6902                	ld	s2,0(sp)
    800041ea:	6105                	addi	sp,sp,32
    800041ec:	8082                	ret

00000000800041ee <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041ee:	7139                	addi	sp,sp,-64
    800041f0:	fc06                	sd	ra,56(sp)
    800041f2:	f822                	sd	s0,48(sp)
    800041f4:	f426                	sd	s1,40(sp)
    800041f6:	f04a                	sd	s2,32(sp)
    800041f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	f4e48493          	addi	s1,s1,-178 # 80021148 <log>
    80004202:	8526                	mv	a0,s1
    80004204:	9cbfc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80004208:	4cdc                	lw	a5,28(s1)
    8000420a:	37fd                	addiw	a5,a5,-1
    8000420c:	0007891b          	sext.w	s2,a5
    80004210:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80004212:	509c                	lw	a5,32(s1)
    80004214:	ef9d                	bnez	a5,80004252 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80004216:	04091763          	bnez	s2,80004264 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    8000421a:	0001d497          	auipc	s1,0x1d
    8000421e:	f2e48493          	addi	s1,s1,-210 # 80021148 <log>
    80004222:	4785                	li	a5,1
    80004224:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004226:	8526                	mv	a0,s1
    80004228:	a3ffc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000422c:	549c                	lw	a5,40(s1)
    8000422e:	04f04b63          	bgtz	a5,80004284 <end_op+0x96>
    acquire(&log.lock);
    80004232:	0001d497          	auipc	s1,0x1d
    80004236:	f1648493          	addi	s1,s1,-234 # 80021148 <log>
    8000423a:	8526                	mv	a0,s1
    8000423c:	993fc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80004240:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80004244:	8526                	mv	a0,s1
    80004246:	f59fd0ef          	jal	8000219e <wakeup>
    release(&log.lock);
    8000424a:	8526                	mv	a0,s1
    8000424c:	a1bfc0ef          	jal	80000c66 <release>
}
    80004250:	a025                	j	80004278 <end_op+0x8a>
    80004252:	ec4e                	sd	s3,24(sp)
    80004254:	e852                	sd	s4,16(sp)
    80004256:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004258:	00003517          	auipc	a0,0x3
    8000425c:	2a850513          	addi	a0,a0,680 # 80007500 <etext+0x500>
    80004260:	d80fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80004264:	0001d497          	auipc	s1,0x1d
    80004268:	ee448493          	addi	s1,s1,-284 # 80021148 <log>
    8000426c:	8526                	mv	a0,s1
    8000426e:	f31fd0ef          	jal	8000219e <wakeup>
  release(&log.lock);
    80004272:	8526                	mv	a0,s1
    80004274:	9f3fc0ef          	jal	80000c66 <release>
}
    80004278:	70e2                	ld	ra,56(sp)
    8000427a:	7442                	ld	s0,48(sp)
    8000427c:	74a2                	ld	s1,40(sp)
    8000427e:	7902                	ld	s2,32(sp)
    80004280:	6121                	addi	sp,sp,64
    80004282:	8082                	ret
    80004284:	ec4e                	sd	s3,24(sp)
    80004286:	e852                	sd	s4,16(sp)
    80004288:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428a:	0001da97          	auipc	s5,0x1d
    8000428e:	eeaa8a93          	addi	s5,s5,-278 # 80021174 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004292:	0001da17          	auipc	s4,0x1d
    80004296:	eb6a0a13          	addi	s4,s4,-330 # 80021148 <log>
    8000429a:	018a2583          	lw	a1,24(s4)
    8000429e:	012585bb          	addw	a1,a1,s2
    800042a2:	2585                	addiw	a1,a1,1
    800042a4:	024a2503          	lw	a0,36(s4)
    800042a8:	e27fe0ef          	jal	800030ce <bread>
    800042ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ae:	000aa583          	lw	a1,0(s5)
    800042b2:	024a2503          	lw	a0,36(s4)
    800042b6:	e19fe0ef          	jal	800030ce <bread>
    800042ba:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042bc:	40000613          	li	a2,1024
    800042c0:	05850593          	addi	a1,a0,88
    800042c4:	05848513          	addi	a0,s1,88
    800042c8:	a37fc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    800042cc:	8526                	mv	a0,s1
    800042ce:	ed7fe0ef          	jal	800031a4 <bwrite>
    brelse(from);
    800042d2:	854e                	mv	a0,s3
    800042d4:	f03fe0ef          	jal	800031d6 <brelse>
    brelse(to);
    800042d8:	8526                	mv	a0,s1
    800042da:	efdfe0ef          	jal	800031d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042de:	2905                	addiw	s2,s2,1
    800042e0:	0a91                	addi	s5,s5,4
    800042e2:	028a2783          	lw	a5,40(s4)
    800042e6:	faf94ae3          	blt	s2,a5,8000429a <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ea:	cf9ff0ef          	jal	80003fe2 <write_head>
    install_trans(0); // Now install writes to home locations
    800042ee:	4501                	li	a0,0
    800042f0:	d51ff0ef          	jal	80004040 <install_trans>
    log.lh.n = 0;
    800042f4:	0001d797          	auipc	a5,0x1d
    800042f8:	e607ae23          	sw	zero,-388(a5) # 80021170 <log+0x28>
    write_head();    // Erase the transaction from the log
    800042fc:	ce7ff0ef          	jal	80003fe2 <write_head>
    80004300:	69e2                	ld	s3,24(sp)
    80004302:	6a42                	ld	s4,16(sp)
    80004304:	6aa2                	ld	s5,8(sp)
    80004306:	b735                	j	80004232 <end_op+0x44>

0000000080004308 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
    80004314:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004316:	0001d917          	auipc	s2,0x1d
    8000431a:	e3290913          	addi	s2,s2,-462 # 80021148 <log>
    8000431e:	854a                	mv	a0,s2
    80004320:	8affc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80004324:	02892603          	lw	a2,40(s2)
    80004328:	47f5                	li	a5,29
    8000432a:	04c7cc63          	blt	a5,a2,80004382 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000432e:	0001d797          	auipc	a5,0x1d
    80004332:	e367a783          	lw	a5,-458(a5) # 80021164 <log+0x1c>
    80004336:	04f05c63          	blez	a5,8000438e <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000433a:	4781                	li	a5,0
    8000433c:	04c05f63          	blez	a2,8000439a <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004340:	44cc                	lw	a1,12(s1)
    80004342:	0001d717          	auipc	a4,0x1d
    80004346:	e3270713          	addi	a4,a4,-462 # 80021174 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    8000434a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000434c:	4314                	lw	a3,0(a4)
    8000434e:	04b68663          	beq	a3,a1,8000439a <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80004352:	2785                	addiw	a5,a5,1
    80004354:	0711                	addi	a4,a4,4
    80004356:	fef61be3          	bne	a2,a5,8000434c <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000435a:	0621                	addi	a2,a2,8
    8000435c:	060a                	slli	a2,a2,0x2
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	dea78793          	addi	a5,a5,-534 # 80021148 <log>
    80004366:	97b2                	add	a5,a5,a2
    80004368:	44d8                	lw	a4,12(s1)
    8000436a:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000436c:	8526                	mv	a0,s1
    8000436e:	ef1fe0ef          	jal	8000325e <bpin>
    log.lh.n++;
    80004372:	0001d717          	auipc	a4,0x1d
    80004376:	dd670713          	addi	a4,a4,-554 # 80021148 <log>
    8000437a:	571c                	lw	a5,40(a4)
    8000437c:	2785                	addiw	a5,a5,1
    8000437e:	d71c                	sw	a5,40(a4)
    80004380:	a80d                	j	800043b2 <log_write+0xaa>
    panic("too big a transaction");
    80004382:	00003517          	auipc	a0,0x3
    80004386:	18e50513          	addi	a0,a0,398 # 80007510 <etext+0x510>
    8000438a:	c56fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    8000438e:	00003517          	auipc	a0,0x3
    80004392:	19a50513          	addi	a0,a0,410 # 80007528 <etext+0x528>
    80004396:	c4afc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    8000439a:	00878693          	addi	a3,a5,8
    8000439e:	068a                	slli	a3,a3,0x2
    800043a0:	0001d717          	auipc	a4,0x1d
    800043a4:	da870713          	addi	a4,a4,-600 # 80021148 <log>
    800043a8:	9736                	add	a4,a4,a3
    800043aa:	44d4                	lw	a3,12(s1)
    800043ac:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043ae:	faf60fe3          	beq	a2,a5,8000436c <log_write+0x64>
  }
  release(&log.lock);
    800043b2:	0001d517          	auipc	a0,0x1d
    800043b6:	d9650513          	addi	a0,a0,-618 # 80021148 <log>
    800043ba:	8adfc0ef          	jal	80000c66 <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
    800043d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043da:	00003597          	auipc	a1,0x3
    800043de:	16e58593          	addi	a1,a1,366 # 80007548 <etext+0x548>
    800043e2:	0521                	addi	a0,a0,8
    800043e4:	f6afc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    800043e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f0:	0204a423          	sw	zero,40(s1)
}
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	64a2                	ld	s1,8(sp)
    800043fa:	6902                	ld	s2,0(sp)
    800043fc:	6105                	addi	sp,sp,32
    800043fe:	8082                	ret

0000000080004400 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004400:	1101                	addi	sp,sp,-32
    80004402:	ec06                	sd	ra,24(sp)
    80004404:	e822                	sd	s0,16(sp)
    80004406:	e426                	sd	s1,8(sp)
    80004408:	e04a                	sd	s2,0(sp)
    8000440a:	1000                	addi	s0,sp,32
    8000440c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000440e:	00850913          	addi	s2,a0,8
    80004412:	854a                	mv	a0,s2
    80004414:	fbafc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80004418:	409c                	lw	a5,0(s1)
    8000441a:	c799                	beqz	a5,80004428 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    8000441c:	85ca                	mv	a1,s2
    8000441e:	8526                	mv	a0,s1
    80004420:	d2ffd0ef          	jal	8000214e <sleep>
  while (lk->locked) {
    80004424:	409c                	lw	a5,0(s1)
    80004426:	fbfd                	bnez	a5,8000441c <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004428:	4785                	li	a5,1
    8000442a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000442c:	ca2fd0ef          	jal	800018ce <myproc>
    80004430:	591c                	lw	a5,48(a0)
    80004432:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004434:	854a                	mv	a0,s2
    80004436:	831fc0ef          	jal	80000c66 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	f74fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    8000445e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004462:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004466:	8526                	mv	a0,s1
    80004468:	d37fd0ef          	jal	8000219e <wakeup>
  release(&lk->lk);
    8000446c:	854a                	mv	a0,s2
    8000446e:	ff8fc0ef          	jal	80000c66 <release>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000447e:	7179                	addi	sp,sp,-48
    80004480:	f406                	sd	ra,40(sp)
    80004482:	f022                	sd	s0,32(sp)
    80004484:	ec26                	sd	s1,24(sp)
    80004486:	e84a                	sd	s2,16(sp)
    80004488:	1800                	addi	s0,sp,48
    8000448a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000448c:	00850913          	addi	s2,a0,8
    80004490:	854a                	mv	a0,s2
    80004492:	f3cfc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004496:	409c                	lw	a5,0(s1)
    80004498:	ef81                	bnez	a5,800044b0 <holdingsleep+0x32>
    8000449a:	4481                	li	s1,0
  release(&lk->lk);
    8000449c:	854a                	mv	a0,s2
    8000449e:	fc8fc0ef          	jal	80000c66 <release>
  return r;
}
    800044a2:	8526                	mv	a0,s1
    800044a4:	70a2                	ld	ra,40(sp)
    800044a6:	7402                	ld	s0,32(sp)
    800044a8:	64e2                	ld	s1,24(sp)
    800044aa:	6942                	ld	s2,16(sp)
    800044ac:	6145                	addi	sp,sp,48
    800044ae:	8082                	ret
    800044b0:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b2:	0284a983          	lw	s3,40(s1)
    800044b6:	c18fd0ef          	jal	800018ce <myproc>
    800044ba:	5904                	lw	s1,48(a0)
    800044bc:	413484b3          	sub	s1,s1,s3
    800044c0:	0014b493          	seqz	s1,s1
    800044c4:	69a2                	ld	s3,8(sp)
    800044c6:	bfd9                	j	8000449c <holdingsleep+0x1e>

00000000800044c8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044c8:	1141                	addi	sp,sp,-16
    800044ca:	e406                	sd	ra,8(sp)
    800044cc:	e022                	sd	s0,0(sp)
    800044ce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044d0:	00003597          	auipc	a1,0x3
    800044d4:	08858593          	addi	a1,a1,136 # 80007558 <etext+0x558>
    800044d8:	0001d517          	auipc	a0,0x1d
    800044dc:	db850513          	addi	a0,a0,-584 # 80021290 <ftable>
    800044e0:	e6efc0ef          	jal	80000b4e <initlock>
}
    800044e4:	60a2                	ld	ra,8(sp)
    800044e6:	6402                	ld	s0,0(sp)
    800044e8:	0141                	addi	sp,sp,16
    800044ea:	8082                	ret

00000000800044ec <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	d9a50513          	addi	a0,a0,-614 # 80021290 <ftable>
    800044fe:	ed0fc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004502:	0001d497          	auipc	s1,0x1d
    80004506:	da648493          	addi	s1,s1,-602 # 800212a8 <ftable+0x18>
    8000450a:	0001e717          	auipc	a4,0x1e
    8000450e:	d3e70713          	addi	a4,a4,-706 # 80022248 <disk>
    if(f->ref == 0){
    80004512:	40dc                	lw	a5,4(s1)
    80004514:	cf89                	beqz	a5,8000452e <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004516:	02848493          	addi	s1,s1,40
    8000451a:	fee49ce3          	bne	s1,a4,80004512 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000451e:	0001d517          	auipc	a0,0x1d
    80004522:	d7250513          	addi	a0,a0,-654 # 80021290 <ftable>
    80004526:	f40fc0ef          	jal	80000c66 <release>
  return 0;
    8000452a:	4481                	li	s1,0
    8000452c:	a809                	j	8000453e <filealloc+0x52>
      f->ref = 1;
    8000452e:	4785                	li	a5,1
    80004530:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	d5e50513          	addi	a0,a0,-674 # 80021290 <ftable>
    8000453a:	f2cfc0ef          	jal	80000c66 <release>
}
    8000453e:	8526                	mv	a0,s1
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	1000                	addi	s0,sp,32
    80004554:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004556:	0001d517          	auipc	a0,0x1d
    8000455a:	d3a50513          	addi	a0,a0,-710 # 80021290 <ftable>
    8000455e:	e70fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004562:	40dc                	lw	a5,4(s1)
    80004564:	02f05063          	blez	a5,80004584 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80004568:	2785                	addiw	a5,a5,1
    8000456a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	d2450513          	addi	a0,a0,-732 # 80021290 <ftable>
    80004574:	ef2fc0ef          	jal	80000c66 <release>
  return f;
}
    80004578:	8526                	mv	a0,s1
    8000457a:	60e2                	ld	ra,24(sp)
    8000457c:	6442                	ld	s0,16(sp)
    8000457e:	64a2                	ld	s1,8(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret
    panic("filedup");
    80004584:	00003517          	auipc	a0,0x3
    80004588:	fdc50513          	addi	a0,a0,-36 # 80007560 <etext+0x560>
    8000458c:	a54fc0ef          	jal	800007e0 <panic>

0000000080004590 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004590:	7139                	addi	sp,sp,-64
    80004592:	fc06                	sd	ra,56(sp)
    80004594:	f822                	sd	s0,48(sp)
    80004596:	f426                	sd	s1,40(sp)
    80004598:	0080                	addi	s0,sp,64
    8000459a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000459c:	0001d517          	auipc	a0,0x1d
    800045a0:	cf450513          	addi	a0,a0,-780 # 80021290 <ftable>
    800045a4:	e2afc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    800045a8:	40dc                	lw	a5,4(s1)
    800045aa:	04f05a63          	blez	a5,800045fe <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    800045ae:	37fd                	addiw	a5,a5,-1
    800045b0:	0007871b          	sext.w	a4,a5
    800045b4:	c0dc                	sw	a5,4(s1)
    800045b6:	04e04e63          	bgtz	a4,80004612 <fileclose+0x82>
    800045ba:	f04a                	sd	s2,32(sp)
    800045bc:	ec4e                	sd	s3,24(sp)
    800045be:	e852                	sd	s4,16(sp)
    800045c0:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045c2:	0004a903          	lw	s2,0(s1)
    800045c6:	0094ca83          	lbu	s5,9(s1)
    800045ca:	0104ba03          	ld	s4,16(s1)
    800045ce:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045d2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045d6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	cb650513          	addi	a0,a0,-842 # 80021290 <ftable>
    800045e2:	e84fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    800045e6:	4785                	li	a5,1
    800045e8:	04f90063          	beq	s2,a5,80004628 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045ec:	3979                	addiw	s2,s2,-2
    800045ee:	4785                	li	a5,1
    800045f0:	0527f563          	bgeu	a5,s2,8000463a <fileclose+0xaa>
    800045f4:	7902                	ld	s2,32(sp)
    800045f6:	69e2                	ld	s3,24(sp)
    800045f8:	6a42                	ld	s4,16(sp)
    800045fa:	6aa2                	ld	s5,8(sp)
    800045fc:	a00d                	j	8000461e <fileclose+0x8e>
    800045fe:	f04a                	sd	s2,32(sp)
    80004600:	ec4e                	sd	s3,24(sp)
    80004602:	e852                	sd	s4,16(sp)
    80004604:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004606:	00003517          	auipc	a0,0x3
    8000460a:	f6250513          	addi	a0,a0,-158 # 80007568 <etext+0x568>
    8000460e:	9d2fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	c7e50513          	addi	a0,a0,-898 # 80021290 <ftable>
    8000461a:	e4cfc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    8000461e:	70e2                	ld	ra,56(sp)
    80004620:	7442                	ld	s0,48(sp)
    80004622:	74a2                	ld	s1,40(sp)
    80004624:	6121                	addi	sp,sp,64
    80004626:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004628:	85d6                	mv	a1,s5
    8000462a:	8552                	mv	a0,s4
    8000462c:	336000ef          	jal	80004962 <pipeclose>
    80004630:	7902                	ld	s2,32(sp)
    80004632:	69e2                	ld	s3,24(sp)
    80004634:	6a42                	ld	s4,16(sp)
    80004636:	6aa2                	ld	s5,8(sp)
    80004638:	b7dd                	j	8000461e <fileclose+0x8e>
    begin_op();
    8000463a:	b4bff0ef          	jal	80004184 <begin_op>
    iput(ff.ip);
    8000463e:	854e                	mv	a0,s3
    80004640:	adcff0ef          	jal	8000391c <iput>
    end_op();
    80004644:	babff0ef          	jal	800041ee <end_op>
    80004648:	7902                	ld	s2,32(sp)
    8000464a:	69e2                	ld	s3,24(sp)
    8000464c:	6a42                	ld	s4,16(sp)
    8000464e:	6aa2                	ld	s5,8(sp)
    80004650:	b7f9                	j	8000461e <fileclose+0x8e>

0000000080004652 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004652:	715d                	addi	sp,sp,-80
    80004654:	e486                	sd	ra,72(sp)
    80004656:	e0a2                	sd	s0,64(sp)
    80004658:	fc26                	sd	s1,56(sp)
    8000465a:	f44e                	sd	s3,40(sp)
    8000465c:	0880                	addi	s0,sp,80
    8000465e:	84aa                	mv	s1,a0
    80004660:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004662:	a6cfd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004666:	409c                	lw	a5,0(s1)
    80004668:	37f9                	addiw	a5,a5,-2
    8000466a:	4705                	li	a4,1
    8000466c:	04f76063          	bltu	a4,a5,800046ac <filestat+0x5a>
    80004670:	f84a                	sd	s2,48(sp)
    80004672:	892a                	mv	s2,a0
    ilock(f->ip);
    80004674:	6c88                	ld	a0,24(s1)
    80004676:	924ff0ef          	jal	8000379a <ilock>
    stati(f->ip, &st);
    8000467a:	fb840593          	addi	a1,s0,-72
    8000467e:	6c88                	ld	a0,24(s1)
    80004680:	c80ff0ef          	jal	80003b00 <stati>
    iunlock(f->ip);
    80004684:	6c88                	ld	a0,24(s1)
    80004686:	9c2ff0ef          	jal	80003848 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000468a:	46e1                	li	a3,24
    8000468c:	fb840613          	addi	a2,s0,-72
    80004690:	85ce                	mv	a1,s3
    80004692:	05093503          	ld	a0,80(s2)
    80004696:	f4dfc0ef          	jal	800015e2 <copyout>
    8000469a:	41f5551b          	sraiw	a0,a0,0x1f
    8000469e:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800046a0:	60a6                	ld	ra,72(sp)
    800046a2:	6406                	ld	s0,64(sp)
    800046a4:	74e2                	ld	s1,56(sp)
    800046a6:	79a2                	ld	s3,40(sp)
    800046a8:	6161                	addi	sp,sp,80
    800046aa:	8082                	ret
  return -1;
    800046ac:	557d                	li	a0,-1
    800046ae:	bfcd                	j	800046a0 <filestat+0x4e>

00000000800046b0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046b0:	7179                	addi	sp,sp,-48
    800046b2:	f406                	sd	ra,40(sp)
    800046b4:	f022                	sd	s0,32(sp)
    800046b6:	e84a                	sd	s2,16(sp)
    800046b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046ba:	00854783          	lbu	a5,8(a0)
    800046be:	cfd1                	beqz	a5,8000475a <fileread+0xaa>
    800046c0:	ec26                	sd	s1,24(sp)
    800046c2:	e44e                	sd	s3,8(sp)
    800046c4:	84aa                	mv	s1,a0
    800046c6:	89ae                	mv	s3,a1
    800046c8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ca:	411c                	lw	a5,0(a0)
    800046cc:	4705                	li	a4,1
    800046ce:	04e78363          	beq	a5,a4,80004714 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d2:	470d                	li	a4,3
    800046d4:	04e78763          	beq	a5,a4,80004722 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046d8:	4709                	li	a4,2
    800046da:	06e79a63          	bne	a5,a4,8000474e <fileread+0x9e>
    ilock(f->ip);
    800046de:	6d08                	ld	a0,24(a0)
    800046e0:	8baff0ef          	jal	8000379a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046e4:	874a                	mv	a4,s2
    800046e6:	5094                	lw	a3,32(s1)
    800046e8:	864e                	mv	a2,s3
    800046ea:	4585                	li	a1,1
    800046ec:	6c88                	ld	a0,24(s1)
    800046ee:	c3cff0ef          	jal	80003b2a <readi>
    800046f2:	892a                	mv	s2,a0
    800046f4:	00a05563          	blez	a0,800046fe <fileread+0x4e>
      f->off += r;
    800046f8:	509c                	lw	a5,32(s1)
    800046fa:	9fa9                	addw	a5,a5,a0
    800046fc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046fe:	6c88                	ld	a0,24(s1)
    80004700:	948ff0ef          	jal	80003848 <iunlock>
    80004704:	64e2                	ld	s1,24(sp)
    80004706:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004708:	854a                	mv	a0,s2
    8000470a:	70a2                	ld	ra,40(sp)
    8000470c:	7402                	ld	s0,32(sp)
    8000470e:	6942                	ld	s2,16(sp)
    80004710:	6145                	addi	sp,sp,48
    80004712:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004714:	6908                	ld	a0,16(a0)
    80004716:	388000ef          	jal	80004a9e <piperead>
    8000471a:	892a                	mv	s2,a0
    8000471c:	64e2                	ld	s1,24(sp)
    8000471e:	69a2                	ld	s3,8(sp)
    80004720:	b7e5                	j	80004708 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004722:	02451783          	lh	a5,36(a0)
    80004726:	03079693          	slli	a3,a5,0x30
    8000472a:	92c1                	srli	a3,a3,0x30
    8000472c:	4725                	li	a4,9
    8000472e:	02d76863          	bltu	a4,a3,8000475e <fileread+0xae>
    80004732:	0792                	slli	a5,a5,0x4
    80004734:	0001d717          	auipc	a4,0x1d
    80004738:	abc70713          	addi	a4,a4,-1348 # 800211f0 <devsw>
    8000473c:	97ba                	add	a5,a5,a4
    8000473e:	639c                	ld	a5,0(a5)
    80004740:	c39d                	beqz	a5,80004766 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80004742:	4505                	li	a0,1
    80004744:	9782                	jalr	a5
    80004746:	892a                	mv	s2,a0
    80004748:	64e2                	ld	s1,24(sp)
    8000474a:	69a2                	ld	s3,8(sp)
    8000474c:	bf75                	j	80004708 <fileread+0x58>
    panic("fileread");
    8000474e:	00003517          	auipc	a0,0x3
    80004752:	e2a50513          	addi	a0,a0,-470 # 80007578 <etext+0x578>
    80004756:	88afc0ef          	jal	800007e0 <panic>
    return -1;
    8000475a:	597d                	li	s2,-1
    8000475c:	b775                	j	80004708 <fileread+0x58>
      return -1;
    8000475e:	597d                	li	s2,-1
    80004760:	64e2                	ld	s1,24(sp)
    80004762:	69a2                	ld	s3,8(sp)
    80004764:	b755                	j	80004708 <fileread+0x58>
    80004766:	597d                	li	s2,-1
    80004768:	64e2                	ld	s1,24(sp)
    8000476a:	69a2                	ld	s3,8(sp)
    8000476c:	bf71                	j	80004708 <fileread+0x58>

000000008000476e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000476e:	00954783          	lbu	a5,9(a0)
    80004772:	10078b63          	beqz	a5,80004888 <filewrite+0x11a>
{
    80004776:	715d                	addi	sp,sp,-80
    80004778:	e486                	sd	ra,72(sp)
    8000477a:	e0a2                	sd	s0,64(sp)
    8000477c:	f84a                	sd	s2,48(sp)
    8000477e:	f052                	sd	s4,32(sp)
    80004780:	e85a                	sd	s6,16(sp)
    80004782:	0880                	addi	s0,sp,80
    80004784:	892a                	mv	s2,a0
    80004786:	8b2e                	mv	s6,a1
    80004788:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000478a:	411c                	lw	a5,0(a0)
    8000478c:	4705                	li	a4,1
    8000478e:	02e78763          	beq	a5,a4,800047bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004792:	470d                	li	a4,3
    80004794:	02e78863          	beq	a5,a4,800047c4 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004798:	4709                	li	a4,2
    8000479a:	0ce79c63          	bne	a5,a4,80004872 <filewrite+0x104>
    8000479e:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047a0:	0ac05863          	blez	a2,80004850 <filewrite+0xe2>
    800047a4:	fc26                	sd	s1,56(sp)
    800047a6:	ec56                	sd	s5,24(sp)
    800047a8:	e45e                	sd	s7,8(sp)
    800047aa:	e062                	sd	s8,0(sp)
    int i = 0;
    800047ac:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047ae:	6b85                	lui	s7,0x1
    800047b0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047b4:	6c05                	lui	s8,0x1
    800047b6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047ba:	a8b5                	j	80004836 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    800047bc:	6908                	ld	a0,16(a0)
    800047be:	1fc000ef          	jal	800049ba <pipewrite>
    800047c2:	a04d                	j	80004864 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047c4:	02451783          	lh	a5,36(a0)
    800047c8:	03079693          	slli	a3,a5,0x30
    800047cc:	92c1                	srli	a3,a3,0x30
    800047ce:	4725                	li	a4,9
    800047d0:	0ad76e63          	bltu	a4,a3,8000488c <filewrite+0x11e>
    800047d4:	0792                	slli	a5,a5,0x4
    800047d6:	0001d717          	auipc	a4,0x1d
    800047da:	a1a70713          	addi	a4,a4,-1510 # 800211f0 <devsw>
    800047de:	97ba                	add	a5,a5,a4
    800047e0:	679c                	ld	a5,8(a5)
    800047e2:	c7dd                	beqz	a5,80004890 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    800047e4:	4505                	li	a0,1
    800047e6:	9782                	jalr	a5
    800047e8:	a8b5                	j	80004864 <filewrite+0xf6>
      if(n1 > max)
    800047ea:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800047ee:	997ff0ef          	jal	80004184 <begin_op>
      ilock(f->ip);
    800047f2:	01893503          	ld	a0,24(s2)
    800047f6:	fa5fe0ef          	jal	8000379a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047fa:	8756                	mv	a4,s5
    800047fc:	02092683          	lw	a3,32(s2)
    80004800:	01698633          	add	a2,s3,s6
    80004804:	4585                	li	a1,1
    80004806:	01893503          	ld	a0,24(s2)
    8000480a:	c1cff0ef          	jal	80003c26 <writei>
    8000480e:	84aa                	mv	s1,a0
    80004810:	00a05763          	blez	a0,8000481e <filewrite+0xb0>
        f->off += r;
    80004814:	02092783          	lw	a5,32(s2)
    80004818:	9fa9                	addw	a5,a5,a0
    8000481a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000481e:	01893503          	ld	a0,24(s2)
    80004822:	826ff0ef          	jal	80003848 <iunlock>
      end_op();
    80004826:	9c9ff0ef          	jal	800041ee <end_op>

      if(r != n1){
    8000482a:	029a9563          	bne	s5,s1,80004854 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    8000482e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004832:	0149da63          	bge	s3,s4,80004846 <filewrite+0xd8>
      int n1 = n - i;
    80004836:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000483a:	0004879b          	sext.w	a5,s1
    8000483e:	fafbd6e3          	bge	s7,a5,800047ea <filewrite+0x7c>
    80004842:	84e2                	mv	s1,s8
    80004844:	b75d                	j	800047ea <filewrite+0x7c>
    80004846:	74e2                	ld	s1,56(sp)
    80004848:	6ae2                	ld	s5,24(sp)
    8000484a:	6ba2                	ld	s7,8(sp)
    8000484c:	6c02                	ld	s8,0(sp)
    8000484e:	a039                	j	8000485c <filewrite+0xee>
    int i = 0;
    80004850:	4981                	li	s3,0
    80004852:	a029                	j	8000485c <filewrite+0xee>
    80004854:	74e2                	ld	s1,56(sp)
    80004856:	6ae2                	ld	s5,24(sp)
    80004858:	6ba2                	ld	s7,8(sp)
    8000485a:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    8000485c:	033a1c63          	bne	s4,s3,80004894 <filewrite+0x126>
    80004860:	8552                	mv	a0,s4
    80004862:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004864:	60a6                	ld	ra,72(sp)
    80004866:	6406                	ld	s0,64(sp)
    80004868:	7942                	ld	s2,48(sp)
    8000486a:	7a02                	ld	s4,32(sp)
    8000486c:	6b42                	ld	s6,16(sp)
    8000486e:	6161                	addi	sp,sp,80
    80004870:	8082                	ret
    80004872:	fc26                	sd	s1,56(sp)
    80004874:	f44e                	sd	s3,40(sp)
    80004876:	ec56                	sd	s5,24(sp)
    80004878:	e45e                	sd	s7,8(sp)
    8000487a:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000487c:	00003517          	auipc	a0,0x3
    80004880:	d0c50513          	addi	a0,a0,-756 # 80007588 <etext+0x588>
    80004884:	f5dfb0ef          	jal	800007e0 <panic>
    return -1;
    80004888:	557d                	li	a0,-1
}
    8000488a:	8082                	ret
      return -1;
    8000488c:	557d                	li	a0,-1
    8000488e:	bfd9                	j	80004864 <filewrite+0xf6>
    80004890:	557d                	li	a0,-1
    80004892:	bfc9                	j	80004864 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004894:	557d                	li	a0,-1
    80004896:	79a2                	ld	s3,40(sp)
    80004898:	b7f1                	j	80004864 <filewrite+0xf6>

000000008000489a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000489a:	7179                	addi	sp,sp,-48
    8000489c:	f406                	sd	ra,40(sp)
    8000489e:	f022                	sd	s0,32(sp)
    800048a0:	ec26                	sd	s1,24(sp)
    800048a2:	e052                	sd	s4,0(sp)
    800048a4:	1800                	addi	s0,sp,48
    800048a6:	84aa                	mv	s1,a0
    800048a8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048aa:	0005b023          	sd	zero,0(a1)
    800048ae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048b2:	c3bff0ef          	jal	800044ec <filealloc>
    800048b6:	e088                	sd	a0,0(s1)
    800048b8:	c549                	beqz	a0,80004942 <pipealloc+0xa8>
    800048ba:	c33ff0ef          	jal	800044ec <filealloc>
    800048be:	00aa3023          	sd	a0,0(s4)
    800048c2:	cd25                	beqz	a0,8000493a <pipealloc+0xa0>
    800048c4:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048c6:	a38fc0ef          	jal	80000afe <kalloc>
    800048ca:	892a                	mv	s2,a0
    800048cc:	c12d                	beqz	a0,8000492e <pipealloc+0x94>
    800048ce:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800048d0:	4985                	li	s3,1
    800048d2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048d6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048da:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048de:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048e2:	00003597          	auipc	a1,0x3
    800048e6:	cb658593          	addi	a1,a1,-842 # 80007598 <etext+0x598>
    800048ea:	a64fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800048ee:	609c                	ld	a5,0(s1)
    800048f0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048f4:	609c                	ld	a5,0(s1)
    800048f6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048fa:	609c                	ld	a5,0(s1)
    800048fc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004900:	609c                	ld	a5,0(s1)
    80004902:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004906:	000a3783          	ld	a5,0(s4)
    8000490a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000490e:	000a3783          	ld	a5,0(s4)
    80004912:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004916:	000a3783          	ld	a5,0(s4)
    8000491a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000491e:	000a3783          	ld	a5,0(s4)
    80004922:	0127b823          	sd	s2,16(a5)
  return 0;
    80004926:	4501                	li	a0,0
    80004928:	6942                	ld	s2,16(sp)
    8000492a:	69a2                	ld	s3,8(sp)
    8000492c:	a01d                	j	80004952 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000492e:	6088                	ld	a0,0(s1)
    80004930:	c119                	beqz	a0,80004936 <pipealloc+0x9c>
    80004932:	6942                	ld	s2,16(sp)
    80004934:	a029                	j	8000493e <pipealloc+0xa4>
    80004936:	6942                	ld	s2,16(sp)
    80004938:	a029                	j	80004942 <pipealloc+0xa8>
    8000493a:	6088                	ld	a0,0(s1)
    8000493c:	c10d                	beqz	a0,8000495e <pipealloc+0xc4>
    fileclose(*f0);
    8000493e:	c53ff0ef          	jal	80004590 <fileclose>
  if(*f1)
    80004942:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004946:	557d                	li	a0,-1
  if(*f1)
    80004948:	c789                	beqz	a5,80004952 <pipealloc+0xb8>
    fileclose(*f1);
    8000494a:	853e                	mv	a0,a5
    8000494c:	c45ff0ef          	jal	80004590 <fileclose>
  return -1;
    80004950:	557d                	li	a0,-1
}
    80004952:	70a2                	ld	ra,40(sp)
    80004954:	7402                	ld	s0,32(sp)
    80004956:	64e2                	ld	s1,24(sp)
    80004958:	6a02                	ld	s4,0(sp)
    8000495a:	6145                	addi	sp,sp,48
    8000495c:	8082                	ret
  return -1;
    8000495e:	557d                	li	a0,-1
    80004960:	bfcd                	j	80004952 <pipealloc+0xb8>

0000000080004962 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004962:	1101                	addi	sp,sp,-32
    80004964:	ec06                	sd	ra,24(sp)
    80004966:	e822                	sd	s0,16(sp)
    80004968:	e426                	sd	s1,8(sp)
    8000496a:	e04a                	sd	s2,0(sp)
    8000496c:	1000                	addi	s0,sp,32
    8000496e:	84aa                	mv	s1,a0
    80004970:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004972:	a5cfc0ef          	jal	80000bce <acquire>
  if(writable){
    80004976:	02090763          	beqz	s2,800049a4 <pipeclose+0x42>
    pi->writeopen = 0;
    8000497a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000497e:	21848513          	addi	a0,s1,536
    80004982:	81dfd0ef          	jal	8000219e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004986:	2204b783          	ld	a5,544(s1)
    8000498a:	e785                	bnez	a5,800049b2 <pipeclose+0x50>
    release(&pi->lock);
    8000498c:	8526                	mv	a0,s1
    8000498e:	ad8fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    80004992:	8526                	mv	a0,s1
    80004994:	888fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6902                	ld	s2,0(sp)
    800049a0:	6105                	addi	sp,sp,32
    800049a2:	8082                	ret
    pi->readopen = 0;
    800049a4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049a8:	21c48513          	addi	a0,s1,540
    800049ac:	ff2fd0ef          	jal	8000219e <wakeup>
    800049b0:	bfd9                	j	80004986 <pipeclose+0x24>
    release(&pi->lock);
    800049b2:	8526                	mv	a0,s1
    800049b4:	ab2fc0ef          	jal	80000c66 <release>
}
    800049b8:	b7c5                	j	80004998 <pipeclose+0x36>

00000000800049ba <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049ba:	711d                	addi	sp,sp,-96
    800049bc:	ec86                	sd	ra,88(sp)
    800049be:	e8a2                	sd	s0,80(sp)
    800049c0:	e4a6                	sd	s1,72(sp)
    800049c2:	e0ca                	sd	s2,64(sp)
    800049c4:	fc4e                	sd	s3,56(sp)
    800049c6:	f852                	sd	s4,48(sp)
    800049c8:	f456                	sd	s5,40(sp)
    800049ca:	1080                	addi	s0,sp,96
    800049cc:	84aa                	mv	s1,a0
    800049ce:	8aae                	mv	s5,a1
    800049d0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049d2:	efdfc0ef          	jal	800018ce <myproc>
    800049d6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	9f4fc0ef          	jal	80000bce <acquire>
  while(i < n){
    800049de:	0b405a63          	blez	s4,80004a92 <pipewrite+0xd8>
    800049e2:	f05a                	sd	s6,32(sp)
    800049e4:	ec5e                	sd	s7,24(sp)
    800049e6:	e862                	sd	s8,16(sp)
  int i = 0;
    800049e8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ea:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ec:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f0:	21c48b93          	addi	s7,s1,540
    800049f4:	a81d                	j	80004a2a <pipewrite+0x70>
      release(&pi->lock);
    800049f6:	8526                	mv	a0,s1
    800049f8:	a6efc0ef          	jal	80000c66 <release>
      return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	7b02                	ld	s6,32(sp)
    80004a00:	6be2                	ld	s7,24(sp)
    80004a02:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a04:	854a                	mv	a0,s2
    80004a06:	60e6                	ld	ra,88(sp)
    80004a08:	6446                	ld	s0,80(sp)
    80004a0a:	64a6                	ld	s1,72(sp)
    80004a0c:	6906                	ld	s2,64(sp)
    80004a0e:	79e2                	ld	s3,56(sp)
    80004a10:	7a42                	ld	s4,48(sp)
    80004a12:	7aa2                	ld	s5,40(sp)
    80004a14:	6125                	addi	sp,sp,96
    80004a16:	8082                	ret
      wakeup(&pi->nread);
    80004a18:	8562                	mv	a0,s8
    80004a1a:	f84fd0ef          	jal	8000219e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a1e:	85a6                	mv	a1,s1
    80004a20:	855e                	mv	a0,s7
    80004a22:	f2cfd0ef          	jal	8000214e <sleep>
  while(i < n){
    80004a26:	05495b63          	bge	s2,s4,80004a7c <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    80004a2a:	2204a783          	lw	a5,544(s1)
    80004a2e:	d7e1                	beqz	a5,800049f6 <pipewrite+0x3c>
    80004a30:	854e                	mv	a0,s3
    80004a32:	959fd0ef          	jal	8000238a <killed>
    80004a36:	f161                	bnez	a0,800049f6 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a38:	2184a783          	lw	a5,536(s1)
    80004a3c:	21c4a703          	lw	a4,540(s1)
    80004a40:	2007879b          	addiw	a5,a5,512
    80004a44:	fcf70ae3          	beq	a4,a5,80004a18 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a48:	4685                	li	a3,1
    80004a4a:	01590633          	add	a2,s2,s5
    80004a4e:	faf40593          	addi	a1,s0,-81
    80004a52:	0509b503          	ld	a0,80(s3)
    80004a56:	c71fc0ef          	jal	800016c6 <copyin>
    80004a5a:	03650e63          	beq	a0,s6,80004a96 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a5e:	21c4a783          	lw	a5,540(s1)
    80004a62:	0017871b          	addiw	a4,a5,1
    80004a66:	20e4ae23          	sw	a4,540(s1)
    80004a6a:	1ff7f793          	andi	a5,a5,511
    80004a6e:	97a6                	add	a5,a5,s1
    80004a70:	faf44703          	lbu	a4,-81(s0)
    80004a74:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a78:	2905                	addiw	s2,s2,1
    80004a7a:	b775                	j	80004a26 <pipewrite+0x6c>
    80004a7c:	7b02                	ld	s6,32(sp)
    80004a7e:	6be2                	ld	s7,24(sp)
    80004a80:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004a82:	21848513          	addi	a0,s1,536
    80004a86:	f18fd0ef          	jal	8000219e <wakeup>
  release(&pi->lock);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	9dafc0ef          	jal	80000c66 <release>
  return i;
    80004a90:	bf95                	j	80004a04 <pipewrite+0x4a>
  int i = 0;
    80004a92:	4901                	li	s2,0
    80004a94:	b7fd                	j	80004a82 <pipewrite+0xc8>
    80004a96:	7b02                	ld	s6,32(sp)
    80004a98:	6be2                	ld	s7,24(sp)
    80004a9a:	6c42                	ld	s8,16(sp)
    80004a9c:	b7dd                	j	80004a82 <pipewrite+0xc8>

0000000080004a9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a9e:	715d                	addi	sp,sp,-80
    80004aa0:	e486                	sd	ra,72(sp)
    80004aa2:	e0a2                	sd	s0,64(sp)
    80004aa4:	fc26                	sd	s1,56(sp)
    80004aa6:	f84a                	sd	s2,48(sp)
    80004aa8:	f44e                	sd	s3,40(sp)
    80004aaa:	f052                	sd	s4,32(sp)
    80004aac:	ec56                	sd	s5,24(sp)
    80004aae:	0880                	addi	s0,sp,80
    80004ab0:	84aa                	mv	s1,a0
    80004ab2:	892e                	mv	s2,a1
    80004ab4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ab6:	e19fc0ef          	jal	800018ce <myproc>
    80004aba:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	910fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ac2:	2184a703          	lw	a4,536(s1)
    80004ac6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aca:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ace:	02f71563          	bne	a4,a5,80004af8 <piperead+0x5a>
    80004ad2:	2244a783          	lw	a5,548(s1)
    80004ad6:	cb85                	beqz	a5,80004b06 <piperead+0x68>
    if(killed(pr)){
    80004ad8:	8552                	mv	a0,s4
    80004ada:	8b1fd0ef          	jal	8000238a <killed>
    80004ade:	ed19                	bnez	a0,80004afc <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ae0:	85a6                	mv	a1,s1
    80004ae2:	854e                	mv	a0,s3
    80004ae4:	e6afd0ef          	jal	8000214e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae8:	2184a703          	lw	a4,536(s1)
    80004aec:	21c4a783          	lw	a5,540(s1)
    80004af0:	fef701e3          	beq	a4,a5,80004ad2 <piperead+0x34>
    80004af4:	e85a                	sd	s6,16(sp)
    80004af6:	a809                	j	80004b08 <piperead+0x6a>
    80004af8:	e85a                	sd	s6,16(sp)
    80004afa:	a039                	j	80004b08 <piperead+0x6a>
      release(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	968fc0ef          	jal	80000c66 <release>
      return -1;
    80004b02:	59fd                	li	s3,-1
    80004b04:	a8b9                	j	80004b62 <piperead+0xc4>
    80004b06:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b08:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004b0a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b0c:	05505363          	blez	s5,80004b52 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b10:	2184a783          	lw	a5,536(s1)
    80004b14:	21c4a703          	lw	a4,540(s1)
    80004b18:	02f70d63          	beq	a4,a5,80004b52 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004b1c:	1ff7f793          	andi	a5,a5,511
    80004b20:	97a6                	add	a5,a5,s1
    80004b22:	0187c783          	lbu	a5,24(a5)
    80004b26:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004b2a:	4685                	li	a3,1
    80004b2c:	fbf40613          	addi	a2,s0,-65
    80004b30:	85ca                	mv	a1,s2
    80004b32:	050a3503          	ld	a0,80(s4)
    80004b36:	aadfc0ef          	jal	800015e2 <copyout>
    80004b3a:	03650e63          	beq	a0,s6,80004b76 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004b3e:	2184a783          	lw	a5,536(s1)
    80004b42:	2785                	addiw	a5,a5,1
    80004b44:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b48:	2985                	addiw	s3,s3,1
    80004b4a:	0905                	addi	s2,s2,1
    80004b4c:	fd3a92e3          	bne	s5,s3,80004b10 <piperead+0x72>
    80004b50:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b52:	21c48513          	addi	a0,s1,540
    80004b56:	e48fd0ef          	jal	8000219e <wakeup>
  release(&pi->lock);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	90afc0ef          	jal	80000c66 <release>
    80004b60:	6b42                	ld	s6,16(sp)
  return i;
}
    80004b62:	854e                	mv	a0,s3
    80004b64:	60a6                	ld	ra,72(sp)
    80004b66:	6406                	ld	s0,64(sp)
    80004b68:	74e2                	ld	s1,56(sp)
    80004b6a:	7942                	ld	s2,48(sp)
    80004b6c:	79a2                	ld	s3,40(sp)
    80004b6e:	7a02                	ld	s4,32(sp)
    80004b70:	6ae2                	ld	s5,24(sp)
    80004b72:	6161                	addi	sp,sp,80
    80004b74:	8082                	ret
      if(i == 0)
    80004b76:	fc099ee3          	bnez	s3,80004b52 <piperead+0xb4>
        i = -1;
    80004b7a:	89aa                	mv	s3,a0
    80004b7c:	bfd9                	j	80004b52 <piperead+0xb4>

0000000080004b7e <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004b7e:	1141                	addi	sp,sp,-16
    80004b80:	e422                	sd	s0,8(sp)
    80004b82:	0800                	addi	s0,sp,16
    80004b84:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b86:	8905                	andi	a0,a0,1
    80004b88:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b8a:	8b89                	andi	a5,a5,2
    80004b8c:	c399                	beqz	a5,80004b92 <flags2perm+0x14>
      perm |= PTE_W;
    80004b8e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004b92:	6422                	ld	s0,8(sp)
    80004b94:	0141                	addi	sp,sp,16
    80004b96:	8082                	ret

0000000080004b98 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004b98:	df010113          	addi	sp,sp,-528
    80004b9c:	20113423          	sd	ra,520(sp)
    80004ba0:	20813023          	sd	s0,512(sp)
    80004ba4:	ffa6                	sd	s1,504(sp)
    80004ba6:	fbca                	sd	s2,496(sp)
    80004ba8:	0c00                	addi	s0,sp,528
    80004baa:	892a                	mv	s2,a0
    80004bac:	dea43c23          	sd	a0,-520(s0)
    80004bb0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bb4:	d1bfc0ef          	jal	800018ce <myproc>
    80004bb8:	84aa                	mv	s1,a0

  begin_op();
    80004bba:	dcaff0ef          	jal	80004184 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004bbe:	854a                	mv	a0,s2
    80004bc0:	bf0ff0ef          	jal	80003fb0 <namei>
    80004bc4:	c931                	beqz	a0,80004c18 <kexec+0x80>
    80004bc6:	f3d2                	sd	s4,480(sp)
    80004bc8:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bca:	bd1fe0ef          	jal	8000379a <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bce:	04000713          	li	a4,64
    80004bd2:	4681                	li	a3,0
    80004bd4:	e5040613          	addi	a2,s0,-432
    80004bd8:	4581                	li	a1,0
    80004bda:	8552                	mv	a0,s4
    80004bdc:	f4ffe0ef          	jal	80003b2a <readi>
    80004be0:	04000793          	li	a5,64
    80004be4:	00f51a63          	bne	a0,a5,80004bf8 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80004be8:	e5042703          	lw	a4,-432(s0)
    80004bec:	464c47b7          	lui	a5,0x464c4
    80004bf0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bf4:	02f70663          	beq	a4,a5,80004c20 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bf8:	8552                	mv	a0,s4
    80004bfa:	dabfe0ef          	jal	800039a4 <iunlockput>
    end_op();
    80004bfe:	df0ff0ef          	jal	800041ee <end_op>
  }
  return -1;
    80004c02:	557d                	li	a0,-1
    80004c04:	7a1e                	ld	s4,480(sp)
}
    80004c06:	20813083          	ld	ra,520(sp)
    80004c0a:	20013403          	ld	s0,512(sp)
    80004c0e:	74fe                	ld	s1,504(sp)
    80004c10:	795e                	ld	s2,496(sp)
    80004c12:	21010113          	addi	sp,sp,528
    80004c16:	8082                	ret
    end_op();
    80004c18:	dd6ff0ef          	jal	800041ee <end_op>
    return -1;
    80004c1c:	557d                	li	a0,-1
    80004c1e:	b7e5                	j	80004c06 <kexec+0x6e>
    80004c20:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004c22:	8526                	mv	a0,s1
    80004c24:	db1fc0ef          	jal	800019d4 <proc_pagetable>
    80004c28:	8b2a                	mv	s6,a0
    80004c2a:	2c050b63          	beqz	a0,80004f00 <kexec+0x368>
    80004c2e:	f7ce                	sd	s3,488(sp)
    80004c30:	efd6                	sd	s5,472(sp)
    80004c32:	e7de                	sd	s7,456(sp)
    80004c34:	e3e2                	sd	s8,448(sp)
    80004c36:	ff66                	sd	s9,440(sp)
    80004c38:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c3a:	e7042d03          	lw	s10,-400(s0)
    80004c3e:	e8845783          	lhu	a5,-376(s0)
    80004c42:	12078963          	beqz	a5,80004d74 <kexec+0x1dc>
    80004c46:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c48:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c4a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004c4c:	6c85                	lui	s9,0x1
    80004c4e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c52:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004c56:	6a85                	lui	s5,0x1
    80004c58:	a085                	j	80004cb8 <kexec+0x120>
      panic("loadseg: address should exist");
    80004c5a:	00003517          	auipc	a0,0x3
    80004c5e:	94650513          	addi	a0,a0,-1722 # 800075a0 <etext+0x5a0>
    80004c62:	b7ffb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004c66:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c68:	8726                	mv	a4,s1
    80004c6a:	012c06bb          	addw	a3,s8,s2
    80004c6e:	4581                	li	a1,0
    80004c70:	8552                	mv	a0,s4
    80004c72:	eb9fe0ef          	jal	80003b2a <readi>
    80004c76:	2501                	sext.w	a0,a0
    80004c78:	24a49a63          	bne	s1,a0,80004ecc <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004c7c:	012a893b          	addw	s2,s5,s2
    80004c80:	03397363          	bgeu	s2,s3,80004ca6 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004c84:	02091593          	slli	a1,s2,0x20
    80004c88:	9181                	srli	a1,a1,0x20
    80004c8a:	95de                	add	a1,a1,s7
    80004c8c:	855a                	mv	a0,s6
    80004c8e:	b22fc0ef          	jal	80000fb0 <walkaddr>
    80004c92:	862a                	mv	a2,a0
    if(pa == 0)
    80004c94:	d179                	beqz	a0,80004c5a <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004c96:	412984bb          	subw	s1,s3,s2
    80004c9a:	0004879b          	sext.w	a5,s1
    80004c9e:	fcfcf4e3          	bgeu	s9,a5,80004c66 <kexec+0xce>
    80004ca2:	84d6                	mv	s1,s5
    80004ca4:	b7c9                	j	80004c66 <kexec+0xce>
    sz = sz1;
    80004ca6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004caa:	2d85                	addiw	s11,s11,1
    80004cac:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004cb0:	e8845783          	lhu	a5,-376(s0)
    80004cb4:	08fdd063          	bge	s11,a5,80004d34 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004cb8:	2d01                	sext.w	s10,s10
    80004cba:	03800713          	li	a4,56
    80004cbe:	86ea                	mv	a3,s10
    80004cc0:	e1840613          	addi	a2,s0,-488
    80004cc4:	4581                	li	a1,0
    80004cc6:	8552                	mv	a0,s4
    80004cc8:	e63fe0ef          	jal	80003b2a <readi>
    80004ccc:	03800793          	li	a5,56
    80004cd0:	1cf51663          	bne	a0,a5,80004e9c <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004cd4:	e1842783          	lw	a5,-488(s0)
    80004cd8:	4705                	li	a4,1
    80004cda:	fce798e3          	bne	a5,a4,80004caa <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004cde:	e4043483          	ld	s1,-448(s0)
    80004ce2:	e3843783          	ld	a5,-456(s0)
    80004ce6:	1af4ef63          	bltu	s1,a5,80004ea4 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004cea:	e2843783          	ld	a5,-472(s0)
    80004cee:	94be                	add	s1,s1,a5
    80004cf0:	1af4ee63          	bltu	s1,a5,80004eac <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004cf4:	df043703          	ld	a4,-528(s0)
    80004cf8:	8ff9                	and	a5,a5,a4
    80004cfa:	1a079d63          	bnez	a5,80004eb4 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004cfe:	e1c42503          	lw	a0,-484(s0)
    80004d02:	e7dff0ef          	jal	80004b7e <flags2perm>
    80004d06:	86aa                	mv	a3,a0
    80004d08:	8626                	mv	a2,s1
    80004d0a:	85ca                	mv	a1,s2
    80004d0c:	855a                	mv	a0,s6
    80004d0e:	d7afc0ef          	jal	80001288 <uvmalloc>
    80004d12:	e0a43423          	sd	a0,-504(s0)
    80004d16:	1a050363          	beqz	a0,80004ebc <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004d1a:	e2843b83          	ld	s7,-472(s0)
    80004d1e:	e2042c03          	lw	s8,-480(s0)
    80004d22:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004d26:	00098463          	beqz	s3,80004d2e <kexec+0x196>
    80004d2a:	4901                	li	s2,0
    80004d2c:	bfa1                	j	80004c84 <kexec+0xec>
    sz = sz1;
    80004d2e:	e0843903          	ld	s2,-504(s0)
    80004d32:	bfa5                	j	80004caa <kexec+0x112>
    80004d34:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004d36:	8552                	mv	a0,s4
    80004d38:	c6dfe0ef          	jal	800039a4 <iunlockput>
  end_op();
    80004d3c:	cb2ff0ef          	jal	800041ee <end_op>
  p = myproc();
    80004d40:	b8ffc0ef          	jal	800018ce <myproc>
    80004d44:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d46:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004d4a:	6985                	lui	s3,0x1
    80004d4c:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004d4e:	99ca                	add	s3,s3,s2
    80004d50:	77fd                	lui	a5,0xfffff
    80004d52:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004d56:	4691                	li	a3,4
    80004d58:	6609                	lui	a2,0x2
    80004d5a:	964e                	add	a2,a2,s3
    80004d5c:	85ce                	mv	a1,s3
    80004d5e:	855a                	mv	a0,s6
    80004d60:	d28fc0ef          	jal	80001288 <uvmalloc>
    80004d64:	892a                	mv	s2,a0
    80004d66:	e0a43423          	sd	a0,-504(s0)
    80004d6a:	e519                	bnez	a0,80004d78 <kexec+0x1e0>
  if(pagetable)
    80004d6c:	e1343423          	sd	s3,-504(s0)
    80004d70:	4a01                	li	s4,0
    80004d72:	aab1                	j	80004ece <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d74:	4901                	li	s2,0
    80004d76:	b7c1                	j	80004d36 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004d78:	75f9                	lui	a1,0xffffe
    80004d7a:	95aa                	add	a1,a1,a0
    80004d7c:	855a                	mv	a0,s6
    80004d7e:	ee0fc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004d82:	7bfd                	lui	s7,0xfffff
    80004d84:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004d86:	e0043783          	ld	a5,-512(s0)
    80004d8a:	6388                	ld	a0,0(a5)
    80004d8c:	cd39                	beqz	a0,80004dea <kexec+0x252>
    80004d8e:	e9040993          	addi	s3,s0,-368
    80004d92:	f9040c13          	addi	s8,s0,-112
    80004d96:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d98:	87afc0ef          	jal	80000e12 <strlen>
    80004d9c:	0015079b          	addiw	a5,a0,1
    80004da0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004da4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004da8:	11796e63          	bltu	s2,s7,80004ec4 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dac:	e0043d03          	ld	s10,-512(s0)
    80004db0:	000d3a03          	ld	s4,0(s10)
    80004db4:	8552                	mv	a0,s4
    80004db6:	85cfc0ef          	jal	80000e12 <strlen>
    80004dba:	0015069b          	addiw	a3,a0,1
    80004dbe:	8652                	mv	a2,s4
    80004dc0:	85ca                	mv	a1,s2
    80004dc2:	855a                	mv	a0,s6
    80004dc4:	81ffc0ef          	jal	800015e2 <copyout>
    80004dc8:	10054063          	bltz	a0,80004ec8 <kexec+0x330>
    ustack[argc] = sp;
    80004dcc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dd0:	0485                	addi	s1,s1,1
    80004dd2:	008d0793          	addi	a5,s10,8
    80004dd6:	e0f43023          	sd	a5,-512(s0)
    80004dda:	008d3503          	ld	a0,8(s10)
    80004dde:	c909                	beqz	a0,80004df0 <kexec+0x258>
    if(argc >= MAXARG)
    80004de0:	09a1                	addi	s3,s3,8
    80004de2:	fb899be3          	bne	s3,s8,80004d98 <kexec+0x200>
  ip = 0;
    80004de6:	4a01                	li	s4,0
    80004de8:	a0dd                	j	80004ece <kexec+0x336>
  sp = sz;
    80004dea:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004dee:	4481                	li	s1,0
  ustack[argc] = 0;
    80004df0:	00349793          	slli	a5,s1,0x3
    80004df4:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcc08>
    80004df8:	97a2                	add	a5,a5,s0
    80004dfa:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dfe:	00148693          	addi	a3,s1,1
    80004e02:	068e                	slli	a3,a3,0x3
    80004e04:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e08:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004e0c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004e10:	f5796ee3          	bltu	s2,s7,80004d6c <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e14:	e9040613          	addi	a2,s0,-368
    80004e18:	85ca                	mv	a1,s2
    80004e1a:	855a                	mv	a0,s6
    80004e1c:	fc6fc0ef          	jal	800015e2 <copyout>
    80004e20:	0e054263          	bltz	a0,80004f04 <kexec+0x36c>
  p->trapframe->a1 = sp;
    80004e24:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004e28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e2c:	df843783          	ld	a5,-520(s0)
    80004e30:	0007c703          	lbu	a4,0(a5)
    80004e34:	cf11                	beqz	a4,80004e50 <kexec+0x2b8>
    80004e36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e38:	02f00693          	li	a3,47
    80004e3c:	a039                	j	80004e4a <kexec+0x2b2>
      last = s+1;
    80004e3e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e42:	0785                	addi	a5,a5,1
    80004e44:	fff7c703          	lbu	a4,-1(a5)
    80004e48:	c701                	beqz	a4,80004e50 <kexec+0x2b8>
    if(*s == '/')
    80004e4a:	fed71ce3          	bne	a4,a3,80004e42 <kexec+0x2aa>
    80004e4e:	bfc5                	j	80004e3e <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e50:	4641                	li	a2,16
    80004e52:	df843583          	ld	a1,-520(s0)
    80004e56:	158a8513          	addi	a0,s5,344
    80004e5a:	f87fb0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e5e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e62:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004e66:	e0843783          	ld	a5,-504(s0)
    80004e6a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004e6e:	058ab783          	ld	a5,88(s5)
    80004e72:	e6843703          	ld	a4,-408(s0)
    80004e76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e78:	058ab783          	ld	a5,88(s5)
    80004e7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e80:	85e6                	mv	a1,s9
    80004e82:	bd7fc0ef          	jal	80001a58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e86:	0004851b          	sext.w	a0,s1
    80004e8a:	79be                	ld	s3,488(sp)
    80004e8c:	7a1e                	ld	s4,480(sp)
    80004e8e:	6afe                	ld	s5,472(sp)
    80004e90:	6b5e                	ld	s6,464(sp)
    80004e92:	6bbe                	ld	s7,456(sp)
    80004e94:	6c1e                	ld	s8,448(sp)
    80004e96:	7cfa                	ld	s9,440(sp)
    80004e98:	7d5a                	ld	s10,432(sp)
    80004e9a:	b3b5                	j	80004c06 <kexec+0x6e>
    80004e9c:	e1243423          	sd	s2,-504(s0)
    80004ea0:	7dba                	ld	s11,424(sp)
    80004ea2:	a035                	j	80004ece <kexec+0x336>
    80004ea4:	e1243423          	sd	s2,-504(s0)
    80004ea8:	7dba                	ld	s11,424(sp)
    80004eaa:	a015                	j	80004ece <kexec+0x336>
    80004eac:	e1243423          	sd	s2,-504(s0)
    80004eb0:	7dba                	ld	s11,424(sp)
    80004eb2:	a831                	j	80004ece <kexec+0x336>
    80004eb4:	e1243423          	sd	s2,-504(s0)
    80004eb8:	7dba                	ld	s11,424(sp)
    80004eba:	a811                	j	80004ece <kexec+0x336>
    80004ebc:	e1243423          	sd	s2,-504(s0)
    80004ec0:	7dba                	ld	s11,424(sp)
    80004ec2:	a031                	j	80004ece <kexec+0x336>
  ip = 0;
    80004ec4:	4a01                	li	s4,0
    80004ec6:	a021                	j	80004ece <kexec+0x336>
    80004ec8:	4a01                	li	s4,0
  if(pagetable)
    80004eca:	a011                	j	80004ece <kexec+0x336>
    80004ecc:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004ece:	e0843583          	ld	a1,-504(s0)
    80004ed2:	855a                	mv	a0,s6
    80004ed4:	b85fc0ef          	jal	80001a58 <proc_freepagetable>
  return -1;
    80004ed8:	557d                	li	a0,-1
  if(ip){
    80004eda:	000a1b63          	bnez	s4,80004ef0 <kexec+0x358>
    80004ede:	79be                	ld	s3,488(sp)
    80004ee0:	7a1e                	ld	s4,480(sp)
    80004ee2:	6afe                	ld	s5,472(sp)
    80004ee4:	6b5e                	ld	s6,464(sp)
    80004ee6:	6bbe                	ld	s7,456(sp)
    80004ee8:	6c1e                	ld	s8,448(sp)
    80004eea:	7cfa                	ld	s9,440(sp)
    80004eec:	7d5a                	ld	s10,432(sp)
    80004eee:	bb21                	j	80004c06 <kexec+0x6e>
    80004ef0:	79be                	ld	s3,488(sp)
    80004ef2:	6afe                	ld	s5,472(sp)
    80004ef4:	6b5e                	ld	s6,464(sp)
    80004ef6:	6bbe                	ld	s7,456(sp)
    80004ef8:	6c1e                	ld	s8,448(sp)
    80004efa:	7cfa                	ld	s9,440(sp)
    80004efc:	7d5a                	ld	s10,432(sp)
    80004efe:	b9ed                	j	80004bf8 <kexec+0x60>
    80004f00:	6b5e                	ld	s6,464(sp)
    80004f02:	b9dd                	j	80004bf8 <kexec+0x60>
  sz = sz1;
    80004f04:	e0843983          	ld	s3,-504(s0)
    80004f08:	b595                	j	80004d6c <kexec+0x1d4>

0000000080004f0a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f0a:	7179                	addi	sp,sp,-48
    80004f0c:	f406                	sd	ra,40(sp)
    80004f0e:	f022                	sd	s0,32(sp)
    80004f10:	ec26                	sd	s1,24(sp)
    80004f12:	e84a                	sd	s2,16(sp)
    80004f14:	1800                	addi	s0,sp,48
    80004f16:	892e                	mv	s2,a1
    80004f18:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f1a:	fdc40593          	addi	a1,s0,-36
    80004f1e:	d51fd0ef          	jal	80002c6e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f22:	fdc42703          	lw	a4,-36(s0)
    80004f26:	47bd                	li	a5,15
    80004f28:	02e7e963          	bltu	a5,a4,80004f5a <argfd+0x50>
    80004f2c:	9a3fc0ef          	jal	800018ce <myproc>
    80004f30:	fdc42703          	lw	a4,-36(s0)
    80004f34:	01a70793          	addi	a5,a4,26
    80004f38:	078e                	slli	a5,a5,0x3
    80004f3a:	953e                	add	a0,a0,a5
    80004f3c:	611c                	ld	a5,0(a0)
    80004f3e:	c385                	beqz	a5,80004f5e <argfd+0x54>
    return -1;
  if(pfd)
    80004f40:	00090463          	beqz	s2,80004f48 <argfd+0x3e>
    *pfd = fd;
    80004f44:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f48:	4501                	li	a0,0
  if(pf)
    80004f4a:	c091                	beqz	s1,80004f4e <argfd+0x44>
    *pf = f;
    80004f4c:	e09c                	sd	a5,0(s1)
}
    80004f4e:	70a2                	ld	ra,40(sp)
    80004f50:	7402                	ld	s0,32(sp)
    80004f52:	64e2                	ld	s1,24(sp)
    80004f54:	6942                	ld	s2,16(sp)
    80004f56:	6145                	addi	sp,sp,48
    80004f58:	8082                	ret
    return -1;
    80004f5a:	557d                	li	a0,-1
    80004f5c:	bfcd                	j	80004f4e <argfd+0x44>
    80004f5e:	557d                	li	a0,-1
    80004f60:	b7fd                	j	80004f4e <argfd+0x44>

0000000080004f62 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f62:	1101                	addi	sp,sp,-32
    80004f64:	ec06                	sd	ra,24(sp)
    80004f66:	e822                	sd	s0,16(sp)
    80004f68:	e426                	sd	s1,8(sp)
    80004f6a:	1000                	addi	s0,sp,32
    80004f6c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f6e:	961fc0ef          	jal	800018ce <myproc>
    80004f72:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f74:	0d050793          	addi	a5,a0,208
    80004f78:	4501                	li	a0,0
    80004f7a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f7c:	6398                	ld	a4,0(a5)
    80004f7e:	cb19                	beqz	a4,80004f94 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004f80:	2505                	addiw	a0,a0,1
    80004f82:	07a1                	addi	a5,a5,8
    80004f84:	fed51ce3          	bne	a0,a3,80004f7c <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f88:	557d                	li	a0,-1
}
    80004f8a:	60e2                	ld	ra,24(sp)
    80004f8c:	6442                	ld	s0,16(sp)
    80004f8e:	64a2                	ld	s1,8(sp)
    80004f90:	6105                	addi	sp,sp,32
    80004f92:	8082                	ret
      p->ofile[fd] = f;
    80004f94:	01a50793          	addi	a5,a0,26
    80004f98:	078e                	slli	a5,a5,0x3
    80004f9a:	963e                	add	a2,a2,a5
    80004f9c:	e204                	sd	s1,0(a2)
      return fd;
    80004f9e:	b7f5                	j	80004f8a <fdalloc+0x28>

0000000080004fa0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fa0:	715d                	addi	sp,sp,-80
    80004fa2:	e486                	sd	ra,72(sp)
    80004fa4:	e0a2                	sd	s0,64(sp)
    80004fa6:	fc26                	sd	s1,56(sp)
    80004fa8:	f84a                	sd	s2,48(sp)
    80004faa:	f44e                	sd	s3,40(sp)
    80004fac:	ec56                	sd	s5,24(sp)
    80004fae:	e85a                	sd	s6,16(sp)
    80004fb0:	0880                	addi	s0,sp,80
    80004fb2:	8b2e                	mv	s6,a1
    80004fb4:	89b2                	mv	s3,a2
    80004fb6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fb8:	fb040593          	addi	a1,s0,-80
    80004fbc:	80eff0ef          	jal	80003fca <nameiparent>
    80004fc0:	84aa                	mv	s1,a0
    80004fc2:	10050a63          	beqz	a0,800050d6 <create+0x136>
    return 0;

  ilock(dp);
    80004fc6:	fd4fe0ef          	jal	8000379a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fca:	4601                	li	a2,0
    80004fcc:	fb040593          	addi	a1,s0,-80
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	d79fe0ef          	jal	80003d4a <dirlookup>
    80004fd6:	8aaa                	mv	s5,a0
    80004fd8:	c129                	beqz	a0,8000501a <create+0x7a>
    iunlockput(dp);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	9c9fe0ef          	jal	800039a4 <iunlockput>
    ilock(ip);
    80004fe0:	8556                	mv	a0,s5
    80004fe2:	fb8fe0ef          	jal	8000379a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fe6:	4789                	li	a5,2
    80004fe8:	02fb1463          	bne	s6,a5,80005010 <create+0x70>
    80004fec:	044ad783          	lhu	a5,68(s5)
    80004ff0:	37f9                	addiw	a5,a5,-2
    80004ff2:	17c2                	slli	a5,a5,0x30
    80004ff4:	93c1                	srli	a5,a5,0x30
    80004ff6:	4705                	li	a4,1
    80004ff8:	00f76c63          	bltu	a4,a5,80005010 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004ffc:	8556                	mv	a0,s5
    80004ffe:	60a6                	ld	ra,72(sp)
    80005000:	6406                	ld	s0,64(sp)
    80005002:	74e2                	ld	s1,56(sp)
    80005004:	7942                	ld	s2,48(sp)
    80005006:	79a2                	ld	s3,40(sp)
    80005008:	6ae2                	ld	s5,24(sp)
    8000500a:	6b42                	ld	s6,16(sp)
    8000500c:	6161                	addi	sp,sp,80
    8000500e:	8082                	ret
    iunlockput(ip);
    80005010:	8556                	mv	a0,s5
    80005012:	993fe0ef          	jal	800039a4 <iunlockput>
    return 0;
    80005016:	4a81                	li	s5,0
    80005018:	b7d5                	j	80004ffc <create+0x5c>
    8000501a:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    8000501c:	85da                	mv	a1,s6
    8000501e:	4088                	lw	a0,0(s1)
    80005020:	e0afe0ef          	jal	8000362a <ialloc>
    80005024:	8a2a                	mv	s4,a0
    80005026:	cd15                	beqz	a0,80005062 <create+0xc2>
  ilock(ip);
    80005028:	f72fe0ef          	jal	8000379a <ilock>
  ip->major = major;
    8000502c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005030:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005034:	4905                	li	s2,1
    80005036:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000503a:	8552                	mv	a0,s4
    8000503c:	eaafe0ef          	jal	800036e6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005040:	032b0763          	beq	s6,s2,8000506e <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80005044:	004a2603          	lw	a2,4(s4)
    80005048:	fb040593          	addi	a1,s0,-80
    8000504c:	8526                	mv	a0,s1
    8000504e:	ec9fe0ef          	jal	80003f16 <dirlink>
    80005052:	06054563          	bltz	a0,800050bc <create+0x11c>
  iunlockput(dp);
    80005056:	8526                	mv	a0,s1
    80005058:	94dfe0ef          	jal	800039a4 <iunlockput>
  return ip;
    8000505c:	8ad2                	mv	s5,s4
    8000505e:	7a02                	ld	s4,32(sp)
    80005060:	bf71                	j	80004ffc <create+0x5c>
    iunlockput(dp);
    80005062:	8526                	mv	a0,s1
    80005064:	941fe0ef          	jal	800039a4 <iunlockput>
    return 0;
    80005068:	8ad2                	mv	s5,s4
    8000506a:	7a02                	ld	s4,32(sp)
    8000506c:	bf41                	j	80004ffc <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000506e:	004a2603          	lw	a2,4(s4)
    80005072:	00002597          	auipc	a1,0x2
    80005076:	54e58593          	addi	a1,a1,1358 # 800075c0 <etext+0x5c0>
    8000507a:	8552                	mv	a0,s4
    8000507c:	e9bfe0ef          	jal	80003f16 <dirlink>
    80005080:	02054e63          	bltz	a0,800050bc <create+0x11c>
    80005084:	40d0                	lw	a2,4(s1)
    80005086:	00002597          	auipc	a1,0x2
    8000508a:	54258593          	addi	a1,a1,1346 # 800075c8 <etext+0x5c8>
    8000508e:	8552                	mv	a0,s4
    80005090:	e87fe0ef          	jal	80003f16 <dirlink>
    80005094:	02054463          	bltz	a0,800050bc <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005098:	004a2603          	lw	a2,4(s4)
    8000509c:	fb040593          	addi	a1,s0,-80
    800050a0:	8526                	mv	a0,s1
    800050a2:	e75fe0ef          	jal	80003f16 <dirlink>
    800050a6:	00054b63          	bltz	a0,800050bc <create+0x11c>
    dp->nlink++;  // for ".."
    800050aa:	04a4d783          	lhu	a5,74(s1)
    800050ae:	2785                	addiw	a5,a5,1
    800050b0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800050b4:	8526                	mv	a0,s1
    800050b6:	e30fe0ef          	jal	800036e6 <iupdate>
    800050ba:	bf71                	j	80005056 <create+0xb6>
  ip->nlink = 0;
    800050bc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800050c0:	8552                	mv	a0,s4
    800050c2:	e24fe0ef          	jal	800036e6 <iupdate>
  iunlockput(ip);
    800050c6:	8552                	mv	a0,s4
    800050c8:	8ddfe0ef          	jal	800039a4 <iunlockput>
  iunlockput(dp);
    800050cc:	8526                	mv	a0,s1
    800050ce:	8d7fe0ef          	jal	800039a4 <iunlockput>
  return 0;
    800050d2:	7a02                	ld	s4,32(sp)
    800050d4:	b725                	j	80004ffc <create+0x5c>
    return 0;
    800050d6:	8aaa                	mv	s5,a0
    800050d8:	b715                	j	80004ffc <create+0x5c>

00000000800050da <sys_dup>:
{
    800050da:	7179                	addi	sp,sp,-48
    800050dc:	f406                	sd	ra,40(sp)
    800050de:	f022                	sd	s0,32(sp)
    800050e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050e2:	fd840613          	addi	a2,s0,-40
    800050e6:	4581                	li	a1,0
    800050e8:	4501                	li	a0,0
    800050ea:	e21ff0ef          	jal	80004f0a <argfd>
    return -1;
    800050ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050f0:	02054363          	bltz	a0,80005116 <sys_dup+0x3c>
    800050f4:	ec26                	sd	s1,24(sp)
    800050f6:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    800050f8:	fd843903          	ld	s2,-40(s0)
    800050fc:	854a                	mv	a0,s2
    800050fe:	e65ff0ef          	jal	80004f62 <fdalloc>
    80005102:	84aa                	mv	s1,a0
    return -1;
    80005104:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005106:	00054d63          	bltz	a0,80005120 <sys_dup+0x46>
  filedup(f);
    8000510a:	854a                	mv	a0,s2
    8000510c:	c3eff0ef          	jal	8000454a <filedup>
  return fd;
    80005110:	87a6                	mv	a5,s1
    80005112:	64e2                	ld	s1,24(sp)
    80005114:	6942                	ld	s2,16(sp)
}
    80005116:	853e                	mv	a0,a5
    80005118:	70a2                	ld	ra,40(sp)
    8000511a:	7402                	ld	s0,32(sp)
    8000511c:	6145                	addi	sp,sp,48
    8000511e:	8082                	ret
    80005120:	64e2                	ld	s1,24(sp)
    80005122:	6942                	ld	s2,16(sp)
    80005124:	bfcd                	j	80005116 <sys_dup+0x3c>

0000000080005126 <sys_read>:
{
    80005126:	7179                	addi	sp,sp,-48
    80005128:	f406                	sd	ra,40(sp)
    8000512a:	f022                	sd	s0,32(sp)
    8000512c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000512e:	fd840593          	addi	a1,s0,-40
    80005132:	4505                	li	a0,1
    80005134:	b57fd0ef          	jal	80002c8a <argaddr>
  argint(2, &n);
    80005138:	fe440593          	addi	a1,s0,-28
    8000513c:	4509                	li	a0,2
    8000513e:	b31fd0ef          	jal	80002c6e <argint>
  if(argfd(0, 0, &f) < 0)
    80005142:	fe840613          	addi	a2,s0,-24
    80005146:	4581                	li	a1,0
    80005148:	4501                	li	a0,0
    8000514a:	dc1ff0ef          	jal	80004f0a <argfd>
    8000514e:	87aa                	mv	a5,a0
    return -1;
    80005150:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005152:	0007ca63          	bltz	a5,80005166 <sys_read+0x40>
  return fileread(f, p, n);
    80005156:	fe442603          	lw	a2,-28(s0)
    8000515a:	fd843583          	ld	a1,-40(s0)
    8000515e:	fe843503          	ld	a0,-24(s0)
    80005162:	d4eff0ef          	jal	800046b0 <fileread>
}
    80005166:	70a2                	ld	ra,40(sp)
    80005168:	7402                	ld	s0,32(sp)
    8000516a:	6145                	addi	sp,sp,48
    8000516c:	8082                	ret

000000008000516e <sys_write>:
{
    8000516e:	7179                	addi	sp,sp,-48
    80005170:	f406                	sd	ra,40(sp)
    80005172:	f022                	sd	s0,32(sp)
    80005174:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005176:	fd840593          	addi	a1,s0,-40
    8000517a:	4505                	li	a0,1
    8000517c:	b0ffd0ef          	jal	80002c8a <argaddr>
  argint(2, &n);
    80005180:	fe440593          	addi	a1,s0,-28
    80005184:	4509                	li	a0,2
    80005186:	ae9fd0ef          	jal	80002c6e <argint>
  if(argfd(0, 0, &f) < 0)
    8000518a:	fe840613          	addi	a2,s0,-24
    8000518e:	4581                	li	a1,0
    80005190:	4501                	li	a0,0
    80005192:	d79ff0ef          	jal	80004f0a <argfd>
    80005196:	87aa                	mv	a5,a0
    return -1;
    80005198:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000519a:	0007ca63          	bltz	a5,800051ae <sys_write+0x40>
  return filewrite(f, p, n);
    8000519e:	fe442603          	lw	a2,-28(s0)
    800051a2:	fd843583          	ld	a1,-40(s0)
    800051a6:	fe843503          	ld	a0,-24(s0)
    800051aa:	dc4ff0ef          	jal	8000476e <filewrite>
}
    800051ae:	70a2                	ld	ra,40(sp)
    800051b0:	7402                	ld	s0,32(sp)
    800051b2:	6145                	addi	sp,sp,48
    800051b4:	8082                	ret

00000000800051b6 <sys_close>:
{
    800051b6:	1101                	addi	sp,sp,-32
    800051b8:	ec06                	sd	ra,24(sp)
    800051ba:	e822                	sd	s0,16(sp)
    800051bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051be:	fe040613          	addi	a2,s0,-32
    800051c2:	fec40593          	addi	a1,s0,-20
    800051c6:	4501                	li	a0,0
    800051c8:	d43ff0ef          	jal	80004f0a <argfd>
    return -1;
    800051cc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051ce:	02054063          	bltz	a0,800051ee <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    800051d2:	efcfc0ef          	jal	800018ce <myproc>
    800051d6:	fec42783          	lw	a5,-20(s0)
    800051da:	07e9                	addi	a5,a5,26
    800051dc:	078e                	slli	a5,a5,0x3
    800051de:	953e                	add	a0,a0,a5
    800051e0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800051e4:	fe043503          	ld	a0,-32(s0)
    800051e8:	ba8ff0ef          	jal	80004590 <fileclose>
  return 0;
    800051ec:	4781                	li	a5,0
}
    800051ee:	853e                	mv	a0,a5
    800051f0:	60e2                	ld	ra,24(sp)
    800051f2:	6442                	ld	s0,16(sp)
    800051f4:	6105                	addi	sp,sp,32
    800051f6:	8082                	ret

00000000800051f8 <sys_fstat>:
{
    800051f8:	1101                	addi	sp,sp,-32
    800051fa:	ec06                	sd	ra,24(sp)
    800051fc:	e822                	sd	s0,16(sp)
    800051fe:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005200:	fe040593          	addi	a1,s0,-32
    80005204:	4505                	li	a0,1
    80005206:	a85fd0ef          	jal	80002c8a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000520a:	fe840613          	addi	a2,s0,-24
    8000520e:	4581                	li	a1,0
    80005210:	4501                	li	a0,0
    80005212:	cf9ff0ef          	jal	80004f0a <argfd>
    80005216:	87aa                	mv	a5,a0
    return -1;
    80005218:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000521a:	0007c863          	bltz	a5,8000522a <sys_fstat+0x32>
  return filestat(f, st);
    8000521e:	fe043583          	ld	a1,-32(s0)
    80005222:	fe843503          	ld	a0,-24(s0)
    80005226:	c2cff0ef          	jal	80004652 <filestat>
}
    8000522a:	60e2                	ld	ra,24(sp)
    8000522c:	6442                	ld	s0,16(sp)
    8000522e:	6105                	addi	sp,sp,32
    80005230:	8082                	ret

0000000080005232 <sys_link>:
{
    80005232:	7169                	addi	sp,sp,-304
    80005234:	f606                	sd	ra,296(sp)
    80005236:	f222                	sd	s0,288(sp)
    80005238:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000523a:	08000613          	li	a2,128
    8000523e:	ed040593          	addi	a1,s0,-304
    80005242:	4501                	li	a0,0
    80005244:	a77fd0ef          	jal	80002cba <argstr>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000524a:	0c054e63          	bltz	a0,80005326 <sys_link+0xf4>
    8000524e:	08000613          	li	a2,128
    80005252:	f5040593          	addi	a1,s0,-176
    80005256:	4505                	li	a0,1
    80005258:	a63fd0ef          	jal	80002cba <argstr>
    return -1;
    8000525c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000525e:	0c054463          	bltz	a0,80005326 <sys_link+0xf4>
    80005262:	ee26                	sd	s1,280(sp)
  begin_op();
    80005264:	f21fe0ef          	jal	80004184 <begin_op>
  if((ip = namei(old)) == 0){
    80005268:	ed040513          	addi	a0,s0,-304
    8000526c:	d45fe0ef          	jal	80003fb0 <namei>
    80005270:	84aa                	mv	s1,a0
    80005272:	c53d                	beqz	a0,800052e0 <sys_link+0xae>
  ilock(ip);
    80005274:	d26fe0ef          	jal	8000379a <ilock>
  if(ip->type == T_DIR){
    80005278:	04449703          	lh	a4,68(s1)
    8000527c:	4785                	li	a5,1
    8000527e:	06f70663          	beq	a4,a5,800052ea <sys_link+0xb8>
    80005282:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005284:	04a4d783          	lhu	a5,74(s1)
    80005288:	2785                	addiw	a5,a5,1
    8000528a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000528e:	8526                	mv	a0,s1
    80005290:	c56fe0ef          	jal	800036e6 <iupdate>
  iunlock(ip);
    80005294:	8526                	mv	a0,s1
    80005296:	db2fe0ef          	jal	80003848 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000529a:	fd040593          	addi	a1,s0,-48
    8000529e:	f5040513          	addi	a0,s0,-176
    800052a2:	d29fe0ef          	jal	80003fca <nameiparent>
    800052a6:	892a                	mv	s2,a0
    800052a8:	cd21                	beqz	a0,80005300 <sys_link+0xce>
  ilock(dp);
    800052aa:	cf0fe0ef          	jal	8000379a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052ae:	00092703          	lw	a4,0(s2)
    800052b2:	409c                	lw	a5,0(s1)
    800052b4:	04f71363          	bne	a4,a5,800052fa <sys_link+0xc8>
    800052b8:	40d0                	lw	a2,4(s1)
    800052ba:	fd040593          	addi	a1,s0,-48
    800052be:	854a                	mv	a0,s2
    800052c0:	c57fe0ef          	jal	80003f16 <dirlink>
    800052c4:	02054b63          	bltz	a0,800052fa <sys_link+0xc8>
  iunlockput(dp);
    800052c8:	854a                	mv	a0,s2
    800052ca:	edafe0ef          	jal	800039a4 <iunlockput>
  iput(ip);
    800052ce:	8526                	mv	a0,s1
    800052d0:	e4cfe0ef          	jal	8000391c <iput>
  end_op();
    800052d4:	f1bfe0ef          	jal	800041ee <end_op>
  return 0;
    800052d8:	4781                	li	a5,0
    800052da:	64f2                	ld	s1,280(sp)
    800052dc:	6952                	ld	s2,272(sp)
    800052de:	a0a1                	j	80005326 <sys_link+0xf4>
    end_op();
    800052e0:	f0ffe0ef          	jal	800041ee <end_op>
    return -1;
    800052e4:	57fd                	li	a5,-1
    800052e6:	64f2                	ld	s1,280(sp)
    800052e8:	a83d                	j	80005326 <sys_link+0xf4>
    iunlockput(ip);
    800052ea:	8526                	mv	a0,s1
    800052ec:	eb8fe0ef          	jal	800039a4 <iunlockput>
    end_op();
    800052f0:	efffe0ef          	jal	800041ee <end_op>
    return -1;
    800052f4:	57fd                	li	a5,-1
    800052f6:	64f2                	ld	s1,280(sp)
    800052f8:	a03d                	j	80005326 <sys_link+0xf4>
    iunlockput(dp);
    800052fa:	854a                	mv	a0,s2
    800052fc:	ea8fe0ef          	jal	800039a4 <iunlockput>
  ilock(ip);
    80005300:	8526                	mv	a0,s1
    80005302:	c98fe0ef          	jal	8000379a <ilock>
  ip->nlink--;
    80005306:	04a4d783          	lhu	a5,74(s1)
    8000530a:	37fd                	addiw	a5,a5,-1
    8000530c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	bd4fe0ef          	jal	800036e6 <iupdate>
  iunlockput(ip);
    80005316:	8526                	mv	a0,s1
    80005318:	e8cfe0ef          	jal	800039a4 <iunlockput>
  end_op();
    8000531c:	ed3fe0ef          	jal	800041ee <end_op>
  return -1;
    80005320:	57fd                	li	a5,-1
    80005322:	64f2                	ld	s1,280(sp)
    80005324:	6952                	ld	s2,272(sp)
}
    80005326:	853e                	mv	a0,a5
    80005328:	70b2                	ld	ra,296(sp)
    8000532a:	7412                	ld	s0,288(sp)
    8000532c:	6155                	addi	sp,sp,304
    8000532e:	8082                	ret

0000000080005330 <sys_unlink>:
{
    80005330:	7151                	addi	sp,sp,-240
    80005332:	f586                	sd	ra,232(sp)
    80005334:	f1a2                	sd	s0,224(sp)
    80005336:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005338:	08000613          	li	a2,128
    8000533c:	f3040593          	addi	a1,s0,-208
    80005340:	4501                	li	a0,0
    80005342:	979fd0ef          	jal	80002cba <argstr>
    80005346:	16054063          	bltz	a0,800054a6 <sys_unlink+0x176>
    8000534a:	eda6                	sd	s1,216(sp)
  begin_op();
    8000534c:	e39fe0ef          	jal	80004184 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005350:	fb040593          	addi	a1,s0,-80
    80005354:	f3040513          	addi	a0,s0,-208
    80005358:	c73fe0ef          	jal	80003fca <nameiparent>
    8000535c:	84aa                	mv	s1,a0
    8000535e:	c945                	beqz	a0,8000540e <sys_unlink+0xde>
  ilock(dp);
    80005360:	c3afe0ef          	jal	8000379a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005364:	00002597          	auipc	a1,0x2
    80005368:	25c58593          	addi	a1,a1,604 # 800075c0 <etext+0x5c0>
    8000536c:	fb040513          	addi	a0,s0,-80
    80005370:	9c5fe0ef          	jal	80003d34 <namecmp>
    80005374:	10050e63          	beqz	a0,80005490 <sys_unlink+0x160>
    80005378:	00002597          	auipc	a1,0x2
    8000537c:	25058593          	addi	a1,a1,592 # 800075c8 <etext+0x5c8>
    80005380:	fb040513          	addi	a0,s0,-80
    80005384:	9b1fe0ef          	jal	80003d34 <namecmp>
    80005388:	10050463          	beqz	a0,80005490 <sys_unlink+0x160>
    8000538c:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000538e:	f2c40613          	addi	a2,s0,-212
    80005392:	fb040593          	addi	a1,s0,-80
    80005396:	8526                	mv	a0,s1
    80005398:	9b3fe0ef          	jal	80003d4a <dirlookup>
    8000539c:	892a                	mv	s2,a0
    8000539e:	0e050863          	beqz	a0,8000548e <sys_unlink+0x15e>
  ilock(ip);
    800053a2:	bf8fe0ef          	jal	8000379a <ilock>
  if(ip->nlink < 1)
    800053a6:	04a91783          	lh	a5,74(s2)
    800053aa:	06f05763          	blez	a5,80005418 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800053ae:	04491703          	lh	a4,68(s2)
    800053b2:	4785                	li	a5,1
    800053b4:	06f70963          	beq	a4,a5,80005426 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    800053b8:	4641                	li	a2,16
    800053ba:	4581                	li	a1,0
    800053bc:	fc040513          	addi	a0,s0,-64
    800053c0:	8e3fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800053c4:	4741                	li	a4,16
    800053c6:	f2c42683          	lw	a3,-212(s0)
    800053ca:	fc040613          	addi	a2,s0,-64
    800053ce:	4581                	li	a1,0
    800053d0:	8526                	mv	a0,s1
    800053d2:	855fe0ef          	jal	80003c26 <writei>
    800053d6:	47c1                	li	a5,16
    800053d8:	08f51b63          	bne	a0,a5,8000546e <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    800053dc:	04491703          	lh	a4,68(s2)
    800053e0:	4785                	li	a5,1
    800053e2:	08f70d63          	beq	a4,a5,8000547c <sys_unlink+0x14c>
  iunlockput(dp);
    800053e6:	8526                	mv	a0,s1
    800053e8:	dbcfe0ef          	jal	800039a4 <iunlockput>
  ip->nlink--;
    800053ec:	04a95783          	lhu	a5,74(s2)
    800053f0:	37fd                	addiw	a5,a5,-1
    800053f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800053f6:	854a                	mv	a0,s2
    800053f8:	aeefe0ef          	jal	800036e6 <iupdate>
  iunlockput(ip);
    800053fc:	854a                	mv	a0,s2
    800053fe:	da6fe0ef          	jal	800039a4 <iunlockput>
  end_op();
    80005402:	dedfe0ef          	jal	800041ee <end_op>
  return 0;
    80005406:	4501                	li	a0,0
    80005408:	64ee                	ld	s1,216(sp)
    8000540a:	694e                	ld	s2,208(sp)
    8000540c:	a849                	j	8000549e <sys_unlink+0x16e>
    end_op();
    8000540e:	de1fe0ef          	jal	800041ee <end_op>
    return -1;
    80005412:	557d                	li	a0,-1
    80005414:	64ee                	ld	s1,216(sp)
    80005416:	a061                	j	8000549e <sys_unlink+0x16e>
    80005418:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    8000541a:	00002517          	auipc	a0,0x2
    8000541e:	1b650513          	addi	a0,a0,438 # 800075d0 <etext+0x5d0>
    80005422:	bbefb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005426:	04c92703          	lw	a4,76(s2)
    8000542a:	02000793          	li	a5,32
    8000542e:	f8e7f5e3          	bgeu	a5,a4,800053b8 <sys_unlink+0x88>
    80005432:	e5ce                	sd	s3,200(sp)
    80005434:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005438:	4741                	li	a4,16
    8000543a:	86ce                	mv	a3,s3
    8000543c:	f1840613          	addi	a2,s0,-232
    80005440:	4581                	li	a1,0
    80005442:	854a                	mv	a0,s2
    80005444:	ee6fe0ef          	jal	80003b2a <readi>
    80005448:	47c1                	li	a5,16
    8000544a:	00f51c63          	bne	a0,a5,80005462 <sys_unlink+0x132>
    if(de.inum != 0)
    8000544e:	f1845783          	lhu	a5,-232(s0)
    80005452:	efa1                	bnez	a5,800054aa <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005454:	29c1                	addiw	s3,s3,16
    80005456:	04c92783          	lw	a5,76(s2)
    8000545a:	fcf9efe3          	bltu	s3,a5,80005438 <sys_unlink+0x108>
    8000545e:	69ae                	ld	s3,200(sp)
    80005460:	bfa1                	j	800053b8 <sys_unlink+0x88>
      panic("isdirempty: readi");
    80005462:	00002517          	auipc	a0,0x2
    80005466:	18650513          	addi	a0,a0,390 # 800075e8 <etext+0x5e8>
    8000546a:	b76fb0ef          	jal	800007e0 <panic>
    8000546e:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005470:	00002517          	auipc	a0,0x2
    80005474:	19050513          	addi	a0,a0,400 # 80007600 <etext+0x600>
    80005478:	b68fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    8000547c:	04a4d783          	lhu	a5,74(s1)
    80005480:	37fd                	addiw	a5,a5,-1
    80005482:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005486:	8526                	mv	a0,s1
    80005488:	a5efe0ef          	jal	800036e6 <iupdate>
    8000548c:	bfa9                	j	800053e6 <sys_unlink+0xb6>
    8000548e:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005490:	8526                	mv	a0,s1
    80005492:	d12fe0ef          	jal	800039a4 <iunlockput>
  end_op();
    80005496:	d59fe0ef          	jal	800041ee <end_op>
  return -1;
    8000549a:	557d                	li	a0,-1
    8000549c:	64ee                	ld	s1,216(sp)
}
    8000549e:	70ae                	ld	ra,232(sp)
    800054a0:	740e                	ld	s0,224(sp)
    800054a2:	616d                	addi	sp,sp,240
    800054a4:	8082                	ret
    return -1;
    800054a6:	557d                	li	a0,-1
    800054a8:	bfdd                	j	8000549e <sys_unlink+0x16e>
    iunlockput(ip);
    800054aa:	854a                	mv	a0,s2
    800054ac:	cf8fe0ef          	jal	800039a4 <iunlockput>
    goto bad;
    800054b0:	694e                	ld	s2,208(sp)
    800054b2:	69ae                	ld	s3,200(sp)
    800054b4:	bff1                	j	80005490 <sys_unlink+0x160>

00000000800054b6 <sys_open>:

uint64
sys_open(void)
{
    800054b6:	7131                	addi	sp,sp,-192
    800054b8:	fd06                	sd	ra,184(sp)
    800054ba:	f922                	sd	s0,176(sp)
    800054bc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800054be:	f4c40593          	addi	a1,s0,-180
    800054c2:	4505                	li	a0,1
    800054c4:	faafd0ef          	jal	80002c6e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800054c8:	08000613          	li	a2,128
    800054cc:	f5040593          	addi	a1,s0,-176
    800054d0:	4501                	li	a0,0
    800054d2:	fe8fd0ef          	jal	80002cba <argstr>
    800054d6:	87aa                	mv	a5,a0
    return -1;
    800054d8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800054da:	0a07c263          	bltz	a5,8000557e <sys_open+0xc8>
    800054de:	f526                	sd	s1,168(sp)

  begin_op();
    800054e0:	ca5fe0ef          	jal	80004184 <begin_op>

  if(omode & O_CREATE){
    800054e4:	f4c42783          	lw	a5,-180(s0)
    800054e8:	2007f793          	andi	a5,a5,512
    800054ec:	c3d5                	beqz	a5,80005590 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800054ee:	4681                	li	a3,0
    800054f0:	4601                	li	a2,0
    800054f2:	4589                	li	a1,2
    800054f4:	f5040513          	addi	a0,s0,-176
    800054f8:	aa9ff0ef          	jal	80004fa0 <create>
    800054fc:	84aa                	mv	s1,a0
    if(ip == 0){
    800054fe:	c541                	beqz	a0,80005586 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005500:	04449703          	lh	a4,68(s1)
    80005504:	478d                	li	a5,3
    80005506:	00f71763          	bne	a4,a5,80005514 <sys_open+0x5e>
    8000550a:	0464d703          	lhu	a4,70(s1)
    8000550e:	47a5                	li	a5,9
    80005510:	0ae7ed63          	bltu	a5,a4,800055ca <sys_open+0x114>
    80005514:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005516:	fd7fe0ef          	jal	800044ec <filealloc>
    8000551a:	892a                	mv	s2,a0
    8000551c:	c179                	beqz	a0,800055e2 <sys_open+0x12c>
    8000551e:	ed4e                	sd	s3,152(sp)
    80005520:	a43ff0ef          	jal	80004f62 <fdalloc>
    80005524:	89aa                	mv	s3,a0
    80005526:	0a054a63          	bltz	a0,800055da <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000552a:	04449703          	lh	a4,68(s1)
    8000552e:	478d                	li	a5,3
    80005530:	0cf70263          	beq	a4,a5,800055f4 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005534:	4789                	li	a5,2
    80005536:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000553a:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000553e:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005542:	f4c42783          	lw	a5,-180(s0)
    80005546:	0017c713          	xori	a4,a5,1
    8000554a:	8b05                	andi	a4,a4,1
    8000554c:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005550:	0037f713          	andi	a4,a5,3
    80005554:	00e03733          	snez	a4,a4
    80005558:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000555c:	4007f793          	andi	a5,a5,1024
    80005560:	c791                	beqz	a5,8000556c <sys_open+0xb6>
    80005562:	04449703          	lh	a4,68(s1)
    80005566:	4789                	li	a5,2
    80005568:	08f70d63          	beq	a4,a5,80005602 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	adafe0ef          	jal	80003848 <iunlock>
  end_op();
    80005572:	c7dfe0ef          	jal	800041ee <end_op>

  return fd;
    80005576:	854e                	mv	a0,s3
    80005578:	74aa                	ld	s1,168(sp)
    8000557a:	790a                	ld	s2,160(sp)
    8000557c:	69ea                	ld	s3,152(sp)
}
    8000557e:	70ea                	ld	ra,184(sp)
    80005580:	744a                	ld	s0,176(sp)
    80005582:	6129                	addi	sp,sp,192
    80005584:	8082                	ret
      end_op();
    80005586:	c69fe0ef          	jal	800041ee <end_op>
      return -1;
    8000558a:	557d                	li	a0,-1
    8000558c:	74aa                	ld	s1,168(sp)
    8000558e:	bfc5                	j	8000557e <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80005590:	f5040513          	addi	a0,s0,-176
    80005594:	a1dfe0ef          	jal	80003fb0 <namei>
    80005598:	84aa                	mv	s1,a0
    8000559a:	c11d                	beqz	a0,800055c0 <sys_open+0x10a>
    ilock(ip);
    8000559c:	9fefe0ef          	jal	8000379a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800055a0:	04449703          	lh	a4,68(s1)
    800055a4:	4785                	li	a5,1
    800055a6:	f4f71de3          	bne	a4,a5,80005500 <sys_open+0x4a>
    800055aa:	f4c42783          	lw	a5,-180(s0)
    800055ae:	d3bd                	beqz	a5,80005514 <sys_open+0x5e>
      iunlockput(ip);
    800055b0:	8526                	mv	a0,s1
    800055b2:	bf2fe0ef          	jal	800039a4 <iunlockput>
      end_op();
    800055b6:	c39fe0ef          	jal	800041ee <end_op>
      return -1;
    800055ba:	557d                	li	a0,-1
    800055bc:	74aa                	ld	s1,168(sp)
    800055be:	b7c1                	j	8000557e <sys_open+0xc8>
      end_op();
    800055c0:	c2ffe0ef          	jal	800041ee <end_op>
      return -1;
    800055c4:	557d                	li	a0,-1
    800055c6:	74aa                	ld	s1,168(sp)
    800055c8:	bf5d                	j	8000557e <sys_open+0xc8>
    iunlockput(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	bd8fe0ef          	jal	800039a4 <iunlockput>
    end_op();
    800055d0:	c1ffe0ef          	jal	800041ee <end_op>
    return -1;
    800055d4:	557d                	li	a0,-1
    800055d6:	74aa                	ld	s1,168(sp)
    800055d8:	b75d                	j	8000557e <sys_open+0xc8>
      fileclose(f);
    800055da:	854a                	mv	a0,s2
    800055dc:	fb5fe0ef          	jal	80004590 <fileclose>
    800055e0:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800055e2:	8526                	mv	a0,s1
    800055e4:	bc0fe0ef          	jal	800039a4 <iunlockput>
    end_op();
    800055e8:	c07fe0ef          	jal	800041ee <end_op>
    return -1;
    800055ec:	557d                	li	a0,-1
    800055ee:	74aa                	ld	s1,168(sp)
    800055f0:	790a                	ld	s2,160(sp)
    800055f2:	b771                	j	8000557e <sys_open+0xc8>
    f->type = FD_DEVICE;
    800055f4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800055f8:	04649783          	lh	a5,70(s1)
    800055fc:	02f91223          	sh	a5,36(s2)
    80005600:	bf3d                	j	8000553e <sys_open+0x88>
    itrunc(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	a84fe0ef          	jal	80003888 <itrunc>
    80005608:	b795                	j	8000556c <sys_open+0xb6>

000000008000560a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000560a:	7175                	addi	sp,sp,-144
    8000560c:	e506                	sd	ra,136(sp)
    8000560e:	e122                	sd	s0,128(sp)
    80005610:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005612:	b73fe0ef          	jal	80004184 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005616:	08000613          	li	a2,128
    8000561a:	f7040593          	addi	a1,s0,-144
    8000561e:	4501                	li	a0,0
    80005620:	e9afd0ef          	jal	80002cba <argstr>
    80005624:	02054363          	bltz	a0,8000564a <sys_mkdir+0x40>
    80005628:	4681                	li	a3,0
    8000562a:	4601                	li	a2,0
    8000562c:	4585                	li	a1,1
    8000562e:	f7040513          	addi	a0,s0,-144
    80005632:	96fff0ef          	jal	80004fa0 <create>
    80005636:	c911                	beqz	a0,8000564a <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005638:	b6cfe0ef          	jal	800039a4 <iunlockput>
  end_op();
    8000563c:	bb3fe0ef          	jal	800041ee <end_op>
  return 0;
    80005640:	4501                	li	a0,0
}
    80005642:	60aa                	ld	ra,136(sp)
    80005644:	640a                	ld	s0,128(sp)
    80005646:	6149                	addi	sp,sp,144
    80005648:	8082                	ret
    end_op();
    8000564a:	ba5fe0ef          	jal	800041ee <end_op>
    return -1;
    8000564e:	557d                	li	a0,-1
    80005650:	bfcd                	j	80005642 <sys_mkdir+0x38>

0000000080005652 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005652:	7135                	addi	sp,sp,-160
    80005654:	ed06                	sd	ra,152(sp)
    80005656:	e922                	sd	s0,144(sp)
    80005658:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000565a:	b2bfe0ef          	jal	80004184 <begin_op>
  argint(1, &major);
    8000565e:	f6c40593          	addi	a1,s0,-148
    80005662:	4505                	li	a0,1
    80005664:	e0afd0ef          	jal	80002c6e <argint>
  argint(2, &minor);
    80005668:	f6840593          	addi	a1,s0,-152
    8000566c:	4509                	li	a0,2
    8000566e:	e00fd0ef          	jal	80002c6e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005672:	08000613          	li	a2,128
    80005676:	f7040593          	addi	a1,s0,-144
    8000567a:	4501                	li	a0,0
    8000567c:	e3efd0ef          	jal	80002cba <argstr>
    80005680:	02054563          	bltz	a0,800056aa <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005684:	f6841683          	lh	a3,-152(s0)
    80005688:	f6c41603          	lh	a2,-148(s0)
    8000568c:	458d                	li	a1,3
    8000568e:	f7040513          	addi	a0,s0,-144
    80005692:	90fff0ef          	jal	80004fa0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005696:	c911                	beqz	a0,800056aa <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005698:	b0cfe0ef          	jal	800039a4 <iunlockput>
  end_op();
    8000569c:	b53fe0ef          	jal	800041ee <end_op>
  return 0;
    800056a0:	4501                	li	a0,0
}
    800056a2:	60ea                	ld	ra,152(sp)
    800056a4:	644a                	ld	s0,144(sp)
    800056a6:	610d                	addi	sp,sp,160
    800056a8:	8082                	ret
    end_op();
    800056aa:	b45fe0ef          	jal	800041ee <end_op>
    return -1;
    800056ae:	557d                	li	a0,-1
    800056b0:	bfcd                	j	800056a2 <sys_mknod+0x50>

00000000800056b2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800056b2:	7135                	addi	sp,sp,-160
    800056b4:	ed06                	sd	ra,152(sp)
    800056b6:	e922                	sd	s0,144(sp)
    800056b8:	e14a                	sd	s2,128(sp)
    800056ba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800056bc:	a12fc0ef          	jal	800018ce <myproc>
    800056c0:	892a                	mv	s2,a0
  
  begin_op();
    800056c2:	ac3fe0ef          	jal	80004184 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800056c6:	08000613          	li	a2,128
    800056ca:	f6040593          	addi	a1,s0,-160
    800056ce:	4501                	li	a0,0
    800056d0:	deafd0ef          	jal	80002cba <argstr>
    800056d4:	04054363          	bltz	a0,8000571a <sys_chdir+0x68>
    800056d8:	e526                	sd	s1,136(sp)
    800056da:	f6040513          	addi	a0,s0,-160
    800056de:	8d3fe0ef          	jal	80003fb0 <namei>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	c915                	beqz	a0,80005718 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800056e6:	8b4fe0ef          	jal	8000379a <ilock>
  if(ip->type != T_DIR){
    800056ea:	04449703          	lh	a4,68(s1)
    800056ee:	4785                	li	a5,1
    800056f0:	02f71963          	bne	a4,a5,80005722 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800056f4:	8526                	mv	a0,s1
    800056f6:	952fe0ef          	jal	80003848 <iunlock>
  iput(p->cwd);
    800056fa:	15093503          	ld	a0,336(s2)
    800056fe:	a1efe0ef          	jal	8000391c <iput>
  end_op();
    80005702:	aedfe0ef          	jal	800041ee <end_op>
  p->cwd = ip;
    80005706:	14993823          	sd	s1,336(s2)
  return 0;
    8000570a:	4501                	li	a0,0
    8000570c:	64aa                	ld	s1,136(sp)
}
    8000570e:	60ea                	ld	ra,152(sp)
    80005710:	644a                	ld	s0,144(sp)
    80005712:	690a                	ld	s2,128(sp)
    80005714:	610d                	addi	sp,sp,160
    80005716:	8082                	ret
    80005718:	64aa                	ld	s1,136(sp)
    end_op();
    8000571a:	ad5fe0ef          	jal	800041ee <end_op>
    return -1;
    8000571e:	557d                	li	a0,-1
    80005720:	b7fd                	j	8000570e <sys_chdir+0x5c>
    iunlockput(ip);
    80005722:	8526                	mv	a0,s1
    80005724:	a80fe0ef          	jal	800039a4 <iunlockput>
    end_op();
    80005728:	ac7fe0ef          	jal	800041ee <end_op>
    return -1;
    8000572c:	557d                	li	a0,-1
    8000572e:	64aa                	ld	s1,136(sp)
    80005730:	bff9                	j	8000570e <sys_chdir+0x5c>

0000000080005732 <sys_exec>:

uint64
sys_exec(void)
{
    80005732:	7121                	addi	sp,sp,-448
    80005734:	ff06                	sd	ra,440(sp)
    80005736:	fb22                	sd	s0,432(sp)
    80005738:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000573a:	e4840593          	addi	a1,s0,-440
    8000573e:	4505                	li	a0,1
    80005740:	d4afd0ef          	jal	80002c8a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005744:	08000613          	li	a2,128
    80005748:	f5040593          	addi	a1,s0,-176
    8000574c:	4501                	li	a0,0
    8000574e:	d6cfd0ef          	jal	80002cba <argstr>
    80005752:	87aa                	mv	a5,a0
    return -1;
    80005754:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005756:	0c07c463          	bltz	a5,8000581e <sys_exec+0xec>
    8000575a:	f726                	sd	s1,424(sp)
    8000575c:	f34a                	sd	s2,416(sp)
    8000575e:	ef4e                	sd	s3,408(sp)
    80005760:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005762:	10000613          	li	a2,256
    80005766:	4581                	li	a1,0
    80005768:	e5040513          	addi	a0,s0,-432
    8000576c:	d36fb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005770:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005774:	89a6                	mv	s3,s1
    80005776:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005778:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000577c:	00391513          	slli	a0,s2,0x3
    80005780:	e4040593          	addi	a1,s0,-448
    80005784:	e4843783          	ld	a5,-440(s0)
    80005788:	953e                	add	a0,a0,a5
    8000578a:	c5afd0ef          	jal	80002be4 <fetchaddr>
    8000578e:	02054663          	bltz	a0,800057ba <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80005792:	e4043783          	ld	a5,-448(s0)
    80005796:	c3a9                	beqz	a5,800057d8 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005798:	b66fb0ef          	jal	80000afe <kalloc>
    8000579c:	85aa                	mv	a1,a0
    8000579e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800057a2:	cd01                	beqz	a0,800057ba <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800057a4:	6605                	lui	a2,0x1
    800057a6:	e4043503          	ld	a0,-448(s0)
    800057aa:	c84fd0ef          	jal	80002c2e <fetchstr>
    800057ae:	00054663          	bltz	a0,800057ba <sys_exec+0x88>
    if(i >= NELEM(argv)){
    800057b2:	0905                	addi	s2,s2,1
    800057b4:	09a1                	addi	s3,s3,8
    800057b6:	fd4913e3          	bne	s2,s4,8000577c <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800057ba:	f5040913          	addi	s2,s0,-176
    800057be:	6088                	ld	a0,0(s1)
    800057c0:	c931                	beqz	a0,80005814 <sys_exec+0xe2>
    kfree(argv[i]);
    800057c2:	a5afb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800057c6:	04a1                	addi	s1,s1,8
    800057c8:	ff249be3          	bne	s1,s2,800057be <sys_exec+0x8c>
  return -1;
    800057cc:	557d                	li	a0,-1
    800057ce:	74ba                	ld	s1,424(sp)
    800057d0:	791a                	ld	s2,416(sp)
    800057d2:	69fa                	ld	s3,408(sp)
    800057d4:	6a5a                	ld	s4,400(sp)
    800057d6:	a0a1                	j	8000581e <sys_exec+0xec>
      argv[i] = 0;
    800057d8:	0009079b          	sext.w	a5,s2
    800057dc:	078e                	slli	a5,a5,0x3
    800057de:	fd078793          	addi	a5,a5,-48
    800057e2:	97a2                	add	a5,a5,s0
    800057e4:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    800057e8:	e5040593          	addi	a1,s0,-432
    800057ec:	f5040513          	addi	a0,s0,-176
    800057f0:	ba8ff0ef          	jal	80004b98 <kexec>
    800057f4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800057f6:	f5040993          	addi	s3,s0,-176
    800057fa:	6088                	ld	a0,0(s1)
    800057fc:	c511                	beqz	a0,80005808 <sys_exec+0xd6>
    kfree(argv[i]);
    800057fe:	a1efb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005802:	04a1                	addi	s1,s1,8
    80005804:	ff349be3          	bne	s1,s3,800057fa <sys_exec+0xc8>
  return ret;
    80005808:	854a                	mv	a0,s2
    8000580a:	74ba                	ld	s1,424(sp)
    8000580c:	791a                	ld	s2,416(sp)
    8000580e:	69fa                	ld	s3,408(sp)
    80005810:	6a5a                	ld	s4,400(sp)
    80005812:	a031                	j	8000581e <sys_exec+0xec>
  return -1;
    80005814:	557d                	li	a0,-1
    80005816:	74ba                	ld	s1,424(sp)
    80005818:	791a                	ld	s2,416(sp)
    8000581a:	69fa                	ld	s3,408(sp)
    8000581c:	6a5a                	ld	s4,400(sp)
}
    8000581e:	70fa                	ld	ra,440(sp)
    80005820:	745a                	ld	s0,432(sp)
    80005822:	6139                	addi	sp,sp,448
    80005824:	8082                	ret

0000000080005826 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005826:	7139                	addi	sp,sp,-64
    80005828:	fc06                	sd	ra,56(sp)
    8000582a:	f822                	sd	s0,48(sp)
    8000582c:	f426                	sd	s1,40(sp)
    8000582e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005830:	89efc0ef          	jal	800018ce <myproc>
    80005834:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005836:	fd840593          	addi	a1,s0,-40
    8000583a:	4501                	li	a0,0
    8000583c:	c4efd0ef          	jal	80002c8a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005840:	fc840593          	addi	a1,s0,-56
    80005844:	fd040513          	addi	a0,s0,-48
    80005848:	852ff0ef          	jal	8000489a <pipealloc>
    return -1;
    8000584c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000584e:	0a054463          	bltz	a0,800058f6 <sys_pipe+0xd0>
  fd0 = -1;
    80005852:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005856:	fd043503          	ld	a0,-48(s0)
    8000585a:	f08ff0ef          	jal	80004f62 <fdalloc>
    8000585e:	fca42223          	sw	a0,-60(s0)
    80005862:	08054163          	bltz	a0,800058e4 <sys_pipe+0xbe>
    80005866:	fc843503          	ld	a0,-56(s0)
    8000586a:	ef8ff0ef          	jal	80004f62 <fdalloc>
    8000586e:	fca42023          	sw	a0,-64(s0)
    80005872:	06054063          	bltz	a0,800058d2 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005876:	4691                	li	a3,4
    80005878:	fc440613          	addi	a2,s0,-60
    8000587c:	fd843583          	ld	a1,-40(s0)
    80005880:	68a8                	ld	a0,80(s1)
    80005882:	d61fb0ef          	jal	800015e2 <copyout>
    80005886:	00054e63          	bltz	a0,800058a2 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000588a:	4691                	li	a3,4
    8000588c:	fc040613          	addi	a2,s0,-64
    80005890:	fd843583          	ld	a1,-40(s0)
    80005894:	0591                	addi	a1,a1,4
    80005896:	68a8                	ld	a0,80(s1)
    80005898:	d4bfb0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000589c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000589e:	04055c63          	bgez	a0,800058f6 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800058a2:	fc442783          	lw	a5,-60(s0)
    800058a6:	07e9                	addi	a5,a5,26
    800058a8:	078e                	slli	a5,a5,0x3
    800058aa:	97a6                	add	a5,a5,s1
    800058ac:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800058b0:	fc042783          	lw	a5,-64(s0)
    800058b4:	07e9                	addi	a5,a5,26
    800058b6:	078e                	slli	a5,a5,0x3
    800058b8:	94be                	add	s1,s1,a5
    800058ba:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800058be:	fd043503          	ld	a0,-48(s0)
    800058c2:	ccffe0ef          	jal	80004590 <fileclose>
    fileclose(wf);
    800058c6:	fc843503          	ld	a0,-56(s0)
    800058ca:	cc7fe0ef          	jal	80004590 <fileclose>
    return -1;
    800058ce:	57fd                	li	a5,-1
    800058d0:	a01d                	j	800058f6 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800058d2:	fc442783          	lw	a5,-60(s0)
    800058d6:	0007c763          	bltz	a5,800058e4 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800058da:	07e9                	addi	a5,a5,26
    800058dc:	078e                	slli	a5,a5,0x3
    800058de:	97a6                	add	a5,a5,s1
    800058e0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800058e4:	fd043503          	ld	a0,-48(s0)
    800058e8:	ca9fe0ef          	jal	80004590 <fileclose>
    fileclose(wf);
    800058ec:	fc843503          	ld	a0,-56(s0)
    800058f0:	ca1fe0ef          	jal	80004590 <fileclose>
    return -1;
    800058f4:	57fd                	li	a5,-1
}
    800058f6:	853e                	mv	a0,a5
    800058f8:	70e2                	ld	ra,56(sp)
    800058fa:	7442                	ld	s0,48(sp)
    800058fc:	74a2                	ld	s1,40(sp)
    800058fe:	6121                	addi	sp,sp,64
    80005900:	8082                	ret
	...

0000000080005910 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005910:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005912:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005914:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005916:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005918:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000591a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000591c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000591e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005920:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005922:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005924:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005926:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005928:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000592a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000592c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000592e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005930:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005932:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005934:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005936:	916fd0ef          	jal	80002a4c <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000593a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000593c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000593e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005940:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005942:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005944:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005946:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005948:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000594a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000594c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000594e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005950:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005952:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005954:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005956:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005958:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000595a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000595c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000595e:	10200073          	sret
	...

000000008000596e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000596e:	1141                	addi	sp,sp,-16
    80005970:	e422                	sd	s0,8(sp)
    80005972:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005974:	0c0007b7          	lui	a5,0xc000
    80005978:	4705                	li	a4,1
    8000597a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000597c:	0c0007b7          	lui	a5,0xc000
    80005980:	c3d8                	sw	a4,4(a5)
}
    80005982:	6422                	ld	s0,8(sp)
    80005984:	0141                	addi	sp,sp,16
    80005986:	8082                	ret

0000000080005988 <plicinithart>:

void
plicinithart(void)
{
    80005988:	1141                	addi	sp,sp,-16
    8000598a:	e406                	sd	ra,8(sp)
    8000598c:	e022                	sd	s0,0(sp)
    8000598e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005990:	f13fb0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005994:	0085171b          	slliw	a4,a0,0x8
    80005998:	0c0027b7          	lui	a5,0xc002
    8000599c:	97ba                	add	a5,a5,a4
    8000599e:	40200713          	li	a4,1026
    800059a2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800059a6:	00d5151b          	slliw	a0,a0,0xd
    800059aa:	0c2017b7          	lui	a5,0xc201
    800059ae:	97aa                	add	a5,a5,a0
    800059b0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800059b4:	60a2                	ld	ra,8(sp)
    800059b6:	6402                	ld	s0,0(sp)
    800059b8:	0141                	addi	sp,sp,16
    800059ba:	8082                	ret

00000000800059bc <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800059bc:	1141                	addi	sp,sp,-16
    800059be:	e406                	sd	ra,8(sp)
    800059c0:	e022                	sd	s0,0(sp)
    800059c2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800059c4:	edffb0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800059c8:	00d5151b          	slliw	a0,a0,0xd
    800059cc:	0c2017b7          	lui	a5,0xc201
    800059d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800059d2:	43c8                	lw	a0,4(a5)
    800059d4:	60a2                	ld	ra,8(sp)
    800059d6:	6402                	ld	s0,0(sp)
    800059d8:	0141                	addi	sp,sp,16
    800059da:	8082                	ret

00000000800059dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800059dc:	1101                	addi	sp,sp,-32
    800059de:	ec06                	sd	ra,24(sp)
    800059e0:	e822                	sd	s0,16(sp)
    800059e2:	e426                	sd	s1,8(sp)
    800059e4:	1000                	addi	s0,sp,32
    800059e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800059e8:	ebbfb0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800059ec:	00d5151b          	slliw	a0,a0,0xd
    800059f0:	0c2017b7          	lui	a5,0xc201
    800059f4:	97aa                	add	a5,a5,a0
    800059f6:	c3c4                	sw	s1,4(a5)
}
    800059f8:	60e2                	ld	ra,24(sp)
    800059fa:	6442                	ld	s0,16(sp)
    800059fc:	64a2                	ld	s1,8(sp)
    800059fe:	6105                	addi	sp,sp,32
    80005a00:	8082                	ret

0000000080005a02 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005a02:	1141                	addi	sp,sp,-16
    80005a04:	e406                	sd	ra,8(sp)
    80005a06:	e022                	sd	s0,0(sp)
    80005a08:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005a0a:	479d                	li	a5,7
    80005a0c:	04a7ca63          	blt	a5,a0,80005a60 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005a10:	0001d797          	auipc	a5,0x1d
    80005a14:	83878793          	addi	a5,a5,-1992 # 80022248 <disk>
    80005a18:	97aa                	add	a5,a5,a0
    80005a1a:	0187c783          	lbu	a5,24(a5)
    80005a1e:	e7b9                	bnez	a5,80005a6c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005a20:	00451693          	slli	a3,a0,0x4
    80005a24:	0001d797          	auipc	a5,0x1d
    80005a28:	82478793          	addi	a5,a5,-2012 # 80022248 <disk>
    80005a2c:	6398                	ld	a4,0(a5)
    80005a2e:	9736                	add	a4,a4,a3
    80005a30:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005a34:	6398                	ld	a4,0(a5)
    80005a36:	9736                	add	a4,a4,a3
    80005a38:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005a3c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005a40:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005a44:	97aa                	add	a5,a5,a0
    80005a46:	4705                	li	a4,1
    80005a48:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005a4c:	0001d517          	auipc	a0,0x1d
    80005a50:	81450513          	addi	a0,a0,-2028 # 80022260 <disk+0x18>
    80005a54:	f4afc0ef          	jal	8000219e <wakeup>
}
    80005a58:	60a2                	ld	ra,8(sp)
    80005a5a:	6402                	ld	s0,0(sp)
    80005a5c:	0141                	addi	sp,sp,16
    80005a5e:	8082                	ret
    panic("free_desc 1");
    80005a60:	00002517          	auipc	a0,0x2
    80005a64:	bb050513          	addi	a0,a0,-1104 # 80007610 <etext+0x610>
    80005a68:	d79fa0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    80005a6c:	00002517          	auipc	a0,0x2
    80005a70:	bb450513          	addi	a0,a0,-1100 # 80007620 <etext+0x620>
    80005a74:	d6dfa0ef          	jal	800007e0 <panic>

0000000080005a78 <virtio_disk_init>:
{
    80005a78:	1101                	addi	sp,sp,-32
    80005a7a:	ec06                	sd	ra,24(sp)
    80005a7c:	e822                	sd	s0,16(sp)
    80005a7e:	e426                	sd	s1,8(sp)
    80005a80:	e04a                	sd	s2,0(sp)
    80005a82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005a84:	00002597          	auipc	a1,0x2
    80005a88:	bac58593          	addi	a1,a1,-1108 # 80007630 <etext+0x630>
    80005a8c:	0001d517          	auipc	a0,0x1d
    80005a90:	8e450513          	addi	a0,a0,-1820 # 80022370 <disk+0x128>
    80005a94:	8bafb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005a98:	100017b7          	lui	a5,0x10001
    80005a9c:	4398                	lw	a4,0(a5)
    80005a9e:	2701                	sext.w	a4,a4
    80005aa0:	747277b7          	lui	a5,0x74727
    80005aa4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005aa8:	18f71063          	bne	a4,a5,80005c28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005aac:	100017b7          	lui	a5,0x10001
    80005ab0:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005ab2:	439c                	lw	a5,0(a5)
    80005ab4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ab6:	4709                	li	a4,2
    80005ab8:	16e79863          	bne	a5,a4,80005c28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005abc:	100017b7          	lui	a5,0x10001
    80005ac0:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005ac2:	439c                	lw	a5,0(a5)
    80005ac4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ac6:	16e79163          	bne	a5,a4,80005c28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005aca:	100017b7          	lui	a5,0x10001
    80005ace:	47d8                	lw	a4,12(a5)
    80005ad0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ad2:	554d47b7          	lui	a5,0x554d4
    80005ad6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ada:	14f71763          	bne	a4,a5,80005c28 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ade:	100017b7          	lui	a5,0x10001
    80005ae2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ae6:	4705                	li	a4,1
    80005ae8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005aea:	470d                	li	a4,3
    80005aec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005aee:	10001737          	lui	a4,0x10001
    80005af2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005af4:	c7ffe737          	lui	a4,0xc7ffe
    80005af8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc3d7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005afc:	8ef9                	and	a3,a3,a4
    80005afe:	10001737          	lui	a4,0x10001
    80005b02:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b04:	472d                	li	a4,11
    80005b06:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005b08:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80005b0c:	439c                	lw	a5,0(a5)
    80005b0e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005b12:	8ba1                	andi	a5,a5,8
    80005b14:	12078063          	beqz	a5,80005c34 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005b18:	100017b7          	lui	a5,0x10001
    80005b1c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005b20:	100017b7          	lui	a5,0x10001
    80005b24:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005b28:	439c                	lw	a5,0(a5)
    80005b2a:	2781                	sext.w	a5,a5
    80005b2c:	10079a63          	bnez	a5,80005c40 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005b30:	100017b7          	lui	a5,0x10001
    80005b34:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005b38:	439c                	lw	a5,0(a5)
    80005b3a:	2781                	sext.w	a5,a5
  if(max == 0)
    80005b3c:	10078863          	beqz	a5,80005c4c <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005b40:	471d                	li	a4,7
    80005b42:	10f77b63          	bgeu	a4,a5,80005c58 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005b46:	fb9fa0ef          	jal	80000afe <kalloc>
    80005b4a:	0001c497          	auipc	s1,0x1c
    80005b4e:	6fe48493          	addi	s1,s1,1790 # 80022248 <disk>
    80005b52:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005b54:	fabfa0ef          	jal	80000afe <kalloc>
    80005b58:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005b5a:	fa5fa0ef          	jal	80000afe <kalloc>
    80005b5e:	87aa                	mv	a5,a0
    80005b60:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005b62:	6088                	ld	a0,0(s1)
    80005b64:	10050063          	beqz	a0,80005c64 <virtio_disk_init+0x1ec>
    80005b68:	0001c717          	auipc	a4,0x1c
    80005b6c:	6e873703          	ld	a4,1768(a4) # 80022250 <disk+0x8>
    80005b70:	0e070a63          	beqz	a4,80005c64 <virtio_disk_init+0x1ec>
    80005b74:	0e078863          	beqz	a5,80005c64 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005b78:	6605                	lui	a2,0x1
    80005b7a:	4581                	li	a1,0
    80005b7c:	926fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005b80:	0001c497          	auipc	s1,0x1c
    80005b84:	6c848493          	addi	s1,s1,1736 # 80022248 <disk>
    80005b88:	6605                	lui	a2,0x1
    80005b8a:	4581                	li	a1,0
    80005b8c:	6488                	ld	a0,8(s1)
    80005b8e:	914fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005b92:	6605                	lui	a2,0x1
    80005b94:	4581                	li	a1,0
    80005b96:	6888                	ld	a0,16(s1)
    80005b98:	90afb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005b9c:	100017b7          	lui	a5,0x10001
    80005ba0:	4721                	li	a4,8
    80005ba2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005ba4:	4098                	lw	a4,0(s1)
    80005ba6:	100017b7          	lui	a5,0x10001
    80005baa:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005bae:	40d8                	lw	a4,4(s1)
    80005bb0:	100017b7          	lui	a5,0x10001
    80005bb4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005bb8:	649c                	ld	a5,8(s1)
    80005bba:	0007869b          	sext.w	a3,a5
    80005bbe:	10001737          	lui	a4,0x10001
    80005bc2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005bc6:	9781                	srai	a5,a5,0x20
    80005bc8:	10001737          	lui	a4,0x10001
    80005bcc:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005bd0:	689c                	ld	a5,16(s1)
    80005bd2:	0007869b          	sext.w	a3,a5
    80005bd6:	10001737          	lui	a4,0x10001
    80005bda:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005bde:	9781                	srai	a5,a5,0x20
    80005be0:	10001737          	lui	a4,0x10001
    80005be4:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005be8:	10001737          	lui	a4,0x10001
    80005bec:	4785                	li	a5,1
    80005bee:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005bf0:	00f48c23          	sb	a5,24(s1)
    80005bf4:	00f48ca3          	sb	a5,25(s1)
    80005bf8:	00f48d23          	sb	a5,26(s1)
    80005bfc:	00f48da3          	sb	a5,27(s1)
    80005c00:	00f48e23          	sb	a5,28(s1)
    80005c04:	00f48ea3          	sb	a5,29(s1)
    80005c08:	00f48f23          	sb	a5,30(s1)
    80005c0c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005c10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005c14:	100017b7          	lui	a5,0x10001
    80005c18:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80005c1c:	60e2                	ld	ra,24(sp)
    80005c1e:	6442                	ld	s0,16(sp)
    80005c20:	64a2                	ld	s1,8(sp)
    80005c22:	6902                	ld	s2,0(sp)
    80005c24:	6105                	addi	sp,sp,32
    80005c26:	8082                	ret
    panic("could not find virtio disk");
    80005c28:	00002517          	auipc	a0,0x2
    80005c2c:	a1850513          	addi	a0,a0,-1512 # 80007640 <etext+0x640>
    80005c30:	bb1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005c34:	00002517          	auipc	a0,0x2
    80005c38:	a2c50513          	addi	a0,a0,-1492 # 80007660 <etext+0x660>
    80005c3c:	ba5fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005c40:	00002517          	auipc	a0,0x2
    80005c44:	a4050513          	addi	a0,a0,-1472 # 80007680 <etext+0x680>
    80005c48:	b99fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80005c4c:	00002517          	auipc	a0,0x2
    80005c50:	a5450513          	addi	a0,a0,-1452 # 800076a0 <etext+0x6a0>
    80005c54:	b8dfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005c58:	00002517          	auipc	a0,0x2
    80005c5c:	a6850513          	addi	a0,a0,-1432 # 800076c0 <etext+0x6c0>
    80005c60:	b81fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005c64:	00002517          	auipc	a0,0x2
    80005c68:	a7c50513          	addi	a0,a0,-1412 # 800076e0 <etext+0x6e0>
    80005c6c:	b75fa0ef          	jal	800007e0 <panic>

0000000080005c70 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005c70:	7159                	addi	sp,sp,-112
    80005c72:	f486                	sd	ra,104(sp)
    80005c74:	f0a2                	sd	s0,96(sp)
    80005c76:	eca6                	sd	s1,88(sp)
    80005c78:	e8ca                	sd	s2,80(sp)
    80005c7a:	e4ce                	sd	s3,72(sp)
    80005c7c:	e0d2                	sd	s4,64(sp)
    80005c7e:	fc56                	sd	s5,56(sp)
    80005c80:	f85a                	sd	s6,48(sp)
    80005c82:	f45e                	sd	s7,40(sp)
    80005c84:	f062                	sd	s8,32(sp)
    80005c86:	ec66                	sd	s9,24(sp)
    80005c88:	1880                	addi	s0,sp,112
    80005c8a:	8a2a                	mv	s4,a0
    80005c8c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005c8e:	00c52c83          	lw	s9,12(a0)
    80005c92:	001c9c9b          	slliw	s9,s9,0x1
    80005c96:	1c82                	slli	s9,s9,0x20
    80005c98:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005c9c:	0001c517          	auipc	a0,0x1c
    80005ca0:	6d450513          	addi	a0,a0,1748 # 80022370 <disk+0x128>
    80005ca4:	f2bfa0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005ca8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005caa:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005cac:	0001cb17          	auipc	s6,0x1c
    80005cb0:	59cb0b13          	addi	s6,s6,1436 # 80022248 <disk>
  for(int i = 0; i < 3; i++){
    80005cb4:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005cb6:	0001cc17          	auipc	s8,0x1c
    80005cba:	6bac0c13          	addi	s8,s8,1722 # 80022370 <disk+0x128>
    80005cbe:	a8b9                	j	80005d1c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005cc0:	00fb0733          	add	a4,s6,a5
    80005cc4:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005cc8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005cca:	0207c563          	bltz	a5,80005cf4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005cce:	2905                	addiw	s2,s2,1
    80005cd0:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005cd2:	05590963          	beq	s2,s5,80005d24 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005cd6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005cd8:	0001c717          	auipc	a4,0x1c
    80005cdc:	57070713          	addi	a4,a4,1392 # 80022248 <disk>
    80005ce0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ce2:	01874683          	lbu	a3,24(a4)
    80005ce6:	fee9                	bnez	a3,80005cc0 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005ce8:	2785                	addiw	a5,a5,1
    80005cea:	0705                	addi	a4,a4,1
    80005cec:	fe979be3          	bne	a5,s1,80005ce2 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005cf0:	57fd                	li	a5,-1
    80005cf2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005cf4:	01205d63          	blez	s2,80005d0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005cf8:	f9042503          	lw	a0,-112(s0)
    80005cfc:	d07ff0ef          	jal	80005a02 <free_desc>
      for(int j = 0; j < i; j++)
    80005d00:	4785                	li	a5,1
    80005d02:	0127d663          	bge	a5,s2,80005d0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005d06:	f9442503          	lw	a0,-108(s0)
    80005d0a:	cf9ff0ef          	jal	80005a02 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005d0e:	85e2                	mv	a1,s8
    80005d10:	0001c517          	auipc	a0,0x1c
    80005d14:	55050513          	addi	a0,a0,1360 # 80022260 <disk+0x18>
    80005d18:	c36fc0ef          	jal	8000214e <sleep>
  for(int i = 0; i < 3; i++){
    80005d1c:	f9040613          	addi	a2,s0,-112
    80005d20:	894e                	mv	s2,s3
    80005d22:	bf55                	j	80005cd6 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005d24:	f9042503          	lw	a0,-112(s0)
    80005d28:	00451693          	slli	a3,a0,0x4

  if(write)
    80005d2c:	0001c797          	auipc	a5,0x1c
    80005d30:	51c78793          	addi	a5,a5,1308 # 80022248 <disk>
    80005d34:	00a50713          	addi	a4,a0,10
    80005d38:	0712                	slli	a4,a4,0x4
    80005d3a:	973e                	add	a4,a4,a5
    80005d3c:	01703633          	snez	a2,s7
    80005d40:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005d42:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005d46:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005d4a:	6398                	ld	a4,0(a5)
    80005d4c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005d4e:	0a868613          	addi	a2,a3,168
    80005d52:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005d54:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005d56:	6390                	ld	a2,0(a5)
    80005d58:	00d605b3          	add	a1,a2,a3
    80005d5c:	4741                	li	a4,16
    80005d5e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005d60:	4805                	li	a6,1
    80005d62:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005d66:	f9442703          	lw	a4,-108(s0)
    80005d6a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005d6e:	0712                	slli	a4,a4,0x4
    80005d70:	963a                	add	a2,a2,a4
    80005d72:	058a0593          	addi	a1,s4,88
    80005d76:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005d78:	0007b883          	ld	a7,0(a5)
    80005d7c:	9746                	add	a4,a4,a7
    80005d7e:	40000613          	li	a2,1024
    80005d82:	c710                	sw	a2,8(a4)
  if(write)
    80005d84:	001bb613          	seqz	a2,s7
    80005d88:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005d8c:	00166613          	ori	a2,a2,1
    80005d90:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005d94:	f9842583          	lw	a1,-104(s0)
    80005d98:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005d9c:	00250613          	addi	a2,a0,2
    80005da0:	0612                	slli	a2,a2,0x4
    80005da2:	963e                	add	a2,a2,a5
    80005da4:	577d                	li	a4,-1
    80005da6:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005daa:	0592                	slli	a1,a1,0x4
    80005dac:	98ae                	add	a7,a7,a1
    80005dae:	03068713          	addi	a4,a3,48
    80005db2:	973e                	add	a4,a4,a5
    80005db4:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005db8:	6398                	ld	a4,0(a5)
    80005dba:	972e                	add	a4,a4,a1
    80005dbc:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005dc0:	4689                	li	a3,2
    80005dc2:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005dc6:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005dca:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005dce:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005dd2:	6794                	ld	a3,8(a5)
    80005dd4:	0026d703          	lhu	a4,2(a3)
    80005dd8:	8b1d                	andi	a4,a4,7
    80005dda:	0706                	slli	a4,a4,0x1
    80005ddc:	96ba                	add	a3,a3,a4
    80005dde:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005de2:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005de6:	6798                	ld	a4,8(a5)
    80005de8:	00275783          	lhu	a5,2(a4)
    80005dec:	2785                	addiw	a5,a5,1
    80005dee:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005df2:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005df6:	100017b7          	lui	a5,0x10001
    80005dfa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005dfe:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005e02:	0001c917          	auipc	s2,0x1c
    80005e06:	56e90913          	addi	s2,s2,1390 # 80022370 <disk+0x128>
  while(b->disk == 1) {
    80005e0a:	4485                	li	s1,1
    80005e0c:	01079a63          	bne	a5,a6,80005e20 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005e10:	85ca                	mv	a1,s2
    80005e12:	8552                	mv	a0,s4
    80005e14:	b3afc0ef          	jal	8000214e <sleep>
  while(b->disk == 1) {
    80005e18:	004a2783          	lw	a5,4(s4)
    80005e1c:	fe978ae3          	beq	a5,s1,80005e10 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005e20:	f9042903          	lw	s2,-112(s0)
    80005e24:	00290713          	addi	a4,s2,2
    80005e28:	0712                	slli	a4,a4,0x4
    80005e2a:	0001c797          	auipc	a5,0x1c
    80005e2e:	41e78793          	addi	a5,a5,1054 # 80022248 <disk>
    80005e32:	97ba                	add	a5,a5,a4
    80005e34:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005e38:	0001c997          	auipc	s3,0x1c
    80005e3c:	41098993          	addi	s3,s3,1040 # 80022248 <disk>
    80005e40:	00491713          	slli	a4,s2,0x4
    80005e44:	0009b783          	ld	a5,0(s3)
    80005e48:	97ba                	add	a5,a5,a4
    80005e4a:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005e4e:	854a                	mv	a0,s2
    80005e50:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005e54:	bafff0ef          	jal	80005a02 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005e58:	8885                	andi	s1,s1,1
    80005e5a:	f0fd                	bnez	s1,80005e40 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005e5c:	0001c517          	auipc	a0,0x1c
    80005e60:	51450513          	addi	a0,a0,1300 # 80022370 <disk+0x128>
    80005e64:	e03fa0ef          	jal	80000c66 <release>
}
    80005e68:	70a6                	ld	ra,104(sp)
    80005e6a:	7406                	ld	s0,96(sp)
    80005e6c:	64e6                	ld	s1,88(sp)
    80005e6e:	6946                	ld	s2,80(sp)
    80005e70:	69a6                	ld	s3,72(sp)
    80005e72:	6a06                	ld	s4,64(sp)
    80005e74:	7ae2                	ld	s5,56(sp)
    80005e76:	7b42                	ld	s6,48(sp)
    80005e78:	7ba2                	ld	s7,40(sp)
    80005e7a:	7c02                	ld	s8,32(sp)
    80005e7c:	6ce2                	ld	s9,24(sp)
    80005e7e:	6165                	addi	sp,sp,112
    80005e80:	8082                	ret

0000000080005e82 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005e82:	1101                	addi	sp,sp,-32
    80005e84:	ec06                	sd	ra,24(sp)
    80005e86:	e822                	sd	s0,16(sp)
    80005e88:	e426                	sd	s1,8(sp)
    80005e8a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005e8c:	0001c497          	auipc	s1,0x1c
    80005e90:	3bc48493          	addi	s1,s1,956 # 80022248 <disk>
    80005e94:	0001c517          	auipc	a0,0x1c
    80005e98:	4dc50513          	addi	a0,a0,1244 # 80022370 <disk+0x128>
    80005e9c:	d33fa0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	53b8                	lw	a4,96(a5)
    80005ea6:	8b0d                	andi	a4,a4,3
    80005ea8:	100017b7          	lui	a5,0x10001
    80005eac:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005eae:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005eb2:	689c                	ld	a5,16(s1)
    80005eb4:	0204d703          	lhu	a4,32(s1)
    80005eb8:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005ebc:	04f70663          	beq	a4,a5,80005f08 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005ec0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005ec4:	6898                	ld	a4,16(s1)
    80005ec6:	0204d783          	lhu	a5,32(s1)
    80005eca:	8b9d                	andi	a5,a5,7
    80005ecc:	078e                	slli	a5,a5,0x3
    80005ece:	97ba                	add	a5,a5,a4
    80005ed0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005ed2:	00278713          	addi	a4,a5,2
    80005ed6:	0712                	slli	a4,a4,0x4
    80005ed8:	9726                	add	a4,a4,s1
    80005eda:	01074703          	lbu	a4,16(a4)
    80005ede:	e321                	bnez	a4,80005f1e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005ee0:	0789                	addi	a5,a5,2
    80005ee2:	0792                	slli	a5,a5,0x4
    80005ee4:	97a6                	add	a5,a5,s1
    80005ee6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005ee8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005eec:	ab2fc0ef          	jal	8000219e <wakeup>

    disk.used_idx += 1;
    80005ef0:	0204d783          	lhu	a5,32(s1)
    80005ef4:	2785                	addiw	a5,a5,1
    80005ef6:	17c2                	slli	a5,a5,0x30
    80005ef8:	93c1                	srli	a5,a5,0x30
    80005efa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005efe:	6898                	ld	a4,16(s1)
    80005f00:	00275703          	lhu	a4,2(a4)
    80005f04:	faf71ee3          	bne	a4,a5,80005ec0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005f08:	0001c517          	auipc	a0,0x1c
    80005f0c:	46850513          	addi	a0,a0,1128 # 80022370 <disk+0x128>
    80005f10:	d57fa0ef          	jal	80000c66 <release>
}
    80005f14:	60e2                	ld	ra,24(sp)
    80005f16:	6442                	ld	s0,16(sp)
    80005f18:	64a2                	ld	s1,8(sp)
    80005f1a:	6105                	addi	sp,sp,32
    80005f1c:	8082                	ret
      panic("virtio_disk_intr status");
    80005f1e:	00001517          	auipc	a0,0x1
    80005f22:	7da50513          	addi	a0,a0,2010 # 800076f8 <etext+0x6f8>
    80005f26:	8bbfa0ef          	jal	800007e0 <panic>
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
