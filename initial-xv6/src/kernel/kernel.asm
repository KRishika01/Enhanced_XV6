
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	cf010113          	addi	sp,sp,-784 # 80008cf0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	b5e70713          	addi	a4,a4,-1186 # 80008bb0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	60c78793          	addi	a5,a5,1548 # 80006670 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd6d9f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7a8080e7          	jalr	1960(ra) # 800028d4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	b6650513          	addi	a0,a0,-1178 # 80010cf0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b5648493          	addi	s1,s1,-1194 # 80010cf0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	be690913          	addi	s2,s2,-1050 # 80010d88 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9da080e7          	jalr	-1574(ra) # 80001b9a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	53a080e7          	jalr	1338(ra) # 80002702 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	278080e7          	jalr	632(ra) # 8000244e <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	66c080e7          	jalr	1644(ra) # 8000287e <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	aca50513          	addi	a0,a0,-1334 # 80010cf0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	ab450513          	addi	a0,a0,-1356 # 80010cf0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	b0f72b23          	sw	a5,-1258(a4) # 80010d88 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a2450513          	addi	a0,a0,-1500 # 80010cf0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	638080e7          	jalr	1592(ra) # 8000292a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	9f650513          	addi	a0,a0,-1546 # 80010cf0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9d270713          	addi	a4,a4,-1582 # 80010cf0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	9a878793          	addi	a5,a5,-1624 # 80010cf0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a127a783          	lw	a5,-1518(a5) # 80010d88 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	96670713          	addi	a4,a4,-1690 # 80010cf0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	95648493          	addi	s1,s1,-1706 # 80010cf0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	91a70713          	addi	a4,a4,-1766 # 80010cf0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9af72223          	sw	a5,-1628(a4) # 80010d90 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8de78793          	addi	a5,a5,-1826 # 80010cf0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	94c7ab23          	sw	a2,-1706(a5) # 80010d8c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	94a50513          	addi	a0,a0,-1718 # 80010d88 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	06c080e7          	jalr	108(ra) # 800024b2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	89050513          	addi	a0,a0,-1904 # 80010cf0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00026797          	auipc	a5,0x26
    8000047c:	45078793          	addi	a5,a5,1104 # 800268c8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	8607a323          	sw	zero,-1946(a5) # 80010db0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	08c50513          	addi	a0,a0,140 # 800085f8 <syscalls+0x170>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	5ef72923          	sw	a5,1522(a4) # 80008b70 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	7f6dad83          	lw	s11,2038(s11) # 80010db0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	7a050513          	addi	a0,a0,1952 # 80010d98 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	64250513          	addi	a0,a0,1602 # 80010d98 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	62648493          	addi	s1,s1,1574 # 80010d98 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	5e650513          	addi	a0,a0,1510 # 80010db8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	3727a783          	lw	a5,882(a5) # 80008b70 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	3427b783          	ld	a5,834(a5) # 80008b78 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	34273703          	ld	a4,834(a4) # 80008b80 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	558a0a13          	addi	s4,s4,1368 # 80010db8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	31048493          	addi	s1,s1,784 # 80008b78 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	31098993          	addi	s3,s3,784 # 80008b80 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	c20080e7          	jalr	-992(ra) # 800024b2 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	4ea50513          	addi	a0,a0,1258 # 80010db8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	2927a783          	lw	a5,658(a5) # 80008b70 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	29873703          	ld	a4,664(a4) # 80008b80 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	2887b783          	ld	a5,648(a5) # 80008b78 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	4bc98993          	addi	s3,s3,1212 # 80010db8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	27448493          	addi	s1,s1,628 # 80008b78 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	27490913          	addi	s2,s2,628 # 80008b80 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	b32080e7          	jalr	-1230(ra) # 8000244e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	48648493          	addi	s1,s1,1158 # 80010db8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	22e7bd23          	sd	a4,570(a5) # 80008b80 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	3fc48493          	addi	s1,s1,1020 # 80010db8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00027797          	auipc	a5,0x27
    80000a02:	06278793          	addi	a5,a5,98 # 80027a60 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	3d290913          	addi	s2,s2,978 # 80010df0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	33650513          	addi	a0,a0,822 # 80010df0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00027517          	auipc	a0,0x27
    80000ad2:	f9250513          	addi	a0,a0,-110 # 80027a60 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	30048493          	addi	s1,s1,768 # 80010df0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	2e850513          	addi	a0,a0,744 # 80010df0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	2bc50513          	addi	a0,a0,700 # 80010df0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	00e080e7          	jalr	14(ra) # 80001b7e <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	fdc080e7          	jalr	-36(ra) # 80001b7e <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	fd0080e7          	jalr	-48(ra) # 80001b7e <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	fb8080e7          	jalr	-72(ra) # 80001b7e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	f78080e7          	jalr	-136(ra) # 80001b7e <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f4c080e7          	jalr	-180(ra) # 80001b7e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	cee080e7          	jalr	-786(ra) # 80001b6e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	d0070713          	addi	a4,a4,-768 # 80008b88 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	cd2080e7          	jalr	-814(ra) # 80001b6e <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	dde080e7          	jalr	-546(ra) # 80002c9c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	7ea080e7          	jalr	2026(ra) # 800066b0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	27a080e7          	jalr	634(ra) # 80002148 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	71250513          	addi	a0,a0,1810 # 800085f8 <syscalls+0x170>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	6f250513          	addi	a0,a0,1778 # 800085f8 <syscalls+0x170>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	b8c080e7          	jalr	-1140(ra) # 80001aba <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	d3e080e7          	jalr	-706(ra) # 80002c74 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	d5e080e7          	jalr	-674(ra) # 80002c9c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	754080e7          	jalr	1876(ra) # 8000669a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	762080e7          	jalr	1890(ra) # 800066b0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00003097          	auipc	ra,0x3
    80000f5a:	90a080e7          	jalr	-1782(ra) # 80003860 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	fae080e7          	jalr	-82(ra) # 80003f0c <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	f4c080e7          	jalr	-180(ra) # 80004eb2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	84a080e7          	jalr	-1974(ra) # 800067b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	f4a080e7          	jalr	-182(ra) # 80001ec0 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	c0f72223          	sw	a5,-1020(a4) # 80008b88 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	bf87b783          	ld	a5,-1032(a5) # 80008b90 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	7f6080e7          	jalr	2038(ra) # 80001a24 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	92a7be23          	sd	a0,-1732(a5) # 80008b90 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
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
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <initialisation_queue>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

#ifdef MLFQ
void initialisation_queue() {
    80001836:	1101                	addi	sp,sp,-32
    80001838:	ec22                	sd	s0,24(sp)
    8000183a:	1000                	addi	s0,sp,32
  int priority_queue_ticks[] = {1,4,8,16};
    8000183c:	4785                	li	a5,1
    8000183e:	fef42023          	sw	a5,-32(s0)
    80001842:	4791                	li	a5,4
    80001844:	fef42223          	sw	a5,-28(s0)
    80001848:	47a1                	li	a5,8
    8000184a:	fef42423          	sw	a5,-24(s0)
    8000184e:	47c1                	li	a5,16
    80001850:	fef42623          	sw	a5,-20(s0)
  for(int i=0;i<4;i++) {
    80001854:	fe040693          	addi	a3,s0,-32
    80001858:	0001a717          	auipc	a4,0x1a
    8000185c:	7f870713          	addi	a4,a4,2040 # 8001c050 <queue+0x210>
    80001860:	0001b597          	auipc	a1,0x1b
    80001864:	03058593          	addi	a1,a1,48 # 8001c890 <bcache+0x1f8>
    queue[i].priority_queue_ticks = priority_queue_ticks[i];
    queue[i].head = -1;
    80001868:	567d                	li	a2,-1
    queue[i].priority_queue_ticks = priority_queue_ticks[i];
    8000186a:	429c                	lw	a5,0(a3)
    8000186c:	def72e23          	sw	a5,-516(a4)
    queue[i].head = -1;
    80001870:	dec72823          	sw	a2,-528(a4)
    queue[i].tail = 0;
    80001874:	de072a23          	sw	zero,-524(a4)
    queue[i].length = 0;
    80001878:	de072c23          	sw	zero,-520(a4)
    for(int j=0;j<64;j++) {
    8000187c:	e0070793          	addi	a5,a4,-512
      queue[i].mlfq_queue[j] = 0;
    80001880:	0007b023          	sd	zero,0(a5)
    for(int j=0;j<64;j++) {
    80001884:	07a1                	addi	a5,a5,8
    80001886:	fee79de3          	bne	a5,a4,80001880 <initialisation_queue+0x4a>
  for(int i=0;i<4;i++) {
    8000188a:	0691                	addi	a3,a3,4
    8000188c:	21070713          	addi	a4,a4,528
    80001890:	fcb71de3          	bne	a4,a1,8000186a <initialisation_queue+0x34>
    }
  }
}
    80001894:	6462                	ld	s0,24(sp)
    80001896:	6105                	addi	sp,sp,32
    80001898:	8082                	ret

000000008000189a <mlfq_push>:
void mlfq_push(struct proc *p,int present_queue_number) {
  if(queue[present_queue_number].tail >= NPROC) {
    8000189a:	00559793          	slli	a5,a1,0x5
    8000189e:	97ae                	add	a5,a5,a1
    800018a0:	0792                	slli	a5,a5,0x4
    800018a2:	0001a717          	auipc	a4,0x1a
    800018a6:	59e70713          	addi	a4,a4,1438 # 8001be40 <queue>
    800018aa:	97ba                	add	a5,a5,a4
    800018ac:	43d4                	lw	a3,4(a5)
    800018ae:	03f00793          	li	a5,63
    800018b2:	04d7c663          	blt	a5,a3,800018fe <mlfq_push+0x64>
    // printf("NPROC %d\n",NPROC);
    // printf("Entered\n");
    panic("Invalid parameters passed");
  }
  // int stored_tail_value = queue[present_queue_number].tail;
  queue[present_queue_number].mlfq_queue[queue[present_queue_number].tail] = p;
    800018b6:	0001a617          	auipc	a2,0x1a
    800018ba:	58a60613          	addi	a2,a2,1418 # 8001be40 <queue>
    800018be:	00559713          	slli	a4,a1,0x5
    800018c2:	00b707b3          	add	a5,a4,a1
    800018c6:	0786                	slli	a5,a5,0x1
    800018c8:	97b6                	add	a5,a5,a3
    800018ca:	0789                	addi	a5,a5,2
    800018cc:	078e                	slli	a5,a5,0x3
    800018ce:	97b2                	add	a5,a5,a2
    800018d0:	e388                	sd	a0,0(a5)
  queue[present_queue_number].tail = queue[present_queue_number].tail + 1;
    800018d2:	00b707b3          	add	a5,a4,a1
    800018d6:	0792                	slli	a5,a5,0x4
    800018d8:	97b2                	add	a5,a5,a2
    800018da:	2685                	addiw	a3,a3,1
    800018dc:	c3d4                	sw	a3,4(a5)
  queue[present_queue_number].length = queue[present_queue_number].length + 1;
    800018de:	4794                	lw	a3,8(a5)
    800018e0:	2685                	addiw	a3,a3,1
    800018e2:	c794                	sw	a3,8(a5)
  p->priority_queue_number = present_queue_number;
    800018e4:	28b52a23          	sw	a1,660(a0)
  // stored_tail_value = stored_tail_value + 1;
  p->status_queue = 1;
    800018e8:	4785                	li	a5,1
    800018ea:	2af52023          	sw	a5,672(a0)
  p->number_process = (queue[present_queue_number].tail) - 1; 
    800018ee:	95ba                	add	a1,a1,a4
    800018f0:	0592                	slli	a1,a1,0x4
    800018f2:	95b2                	add	a1,a1,a2
    800018f4:	41dc                	lw	a5,4(a1)
    800018f6:	37fd                	addiw	a5,a5,-1
    800018f8:	2af52223          	sw	a5,676(a0)
    800018fc:	8082                	ret
void mlfq_push(struct proc *p,int present_queue_number) {
    800018fe:	1141                	addi	sp,sp,-16
    80001900:	e406                	sd	ra,8(sp)
    80001902:	e022                	sd	s0,0(sp)
    80001904:	0800                	addi	s0,sp,16
    panic("Invalid parameters passed");
    80001906:	00007517          	auipc	a0,0x7
    8000190a:	8d250513          	addi	a0,a0,-1838 # 800081d8 <digits+0x198>
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>

0000000080001916 <mlfq_push_front>:
  // p->status_queue = 1;
}

void mlfq_push_front(struct proc *p,int queue_number) {
    80001916:	1141                	addi	sp,sp,-16
    80001918:	e422                	sd	s0,8(sp)
    8000191a:	0800                	addi	s0,sp,16
  queue[queue_number].tail++;
    8000191c:	00559793          	slli	a5,a1,0x5
    80001920:	97ae                	add	a5,a5,a1
    80001922:	00479713          	slli	a4,a5,0x4
    80001926:	0001a797          	auipc	a5,0x1a
    8000192a:	51a78793          	addi	a5,a5,1306 # 8001be40 <queue>
    8000192e:	97ba                	add	a5,a5,a4
    80001930:	43d8                	lw	a4,4(a5)
    80001932:	2705                	addiw	a4,a4,1
    80001934:	c3d8                	sw	a4,4(a5)
  queue[queue_number].length++;
    80001936:	4798                	lw	a4,8(a5)
    80001938:	2705                	addiw	a4,a4,1
    8000193a:	c798                	sw	a4,8(a5)
  p->priority_queue_number = 1;
    8000193c:	4705                	li	a4,1
    8000193e:	28e52a23          	sw	a4,660(a0)
  p->status_queue = 1;
    80001942:	2ae52023          	sw	a4,672(a0)
  p->number_process = 0;
    80001946:	2a052223          	sw	zero,676(a0)
  for(int i=queue[queue_number].length-1;i>=0;i--) {
    8000194a:	4794                	lw	a3,8(a5)
    8000194c:	fff6871b          	addiw	a4,a3,-1
    80001950:	02074563          	bltz	a4,8000197a <mlfq_push_front+0x64>
    80001954:	00559793          	slli	a5,a1,0x5
    80001958:	97ae                	add	a5,a5,a1
    8000195a:	0786                	slli	a5,a5,0x1
    8000195c:	97b6                	add	a5,a5,a3
    8000195e:	0785                	addi	a5,a5,1
    80001960:	078e                	slli	a5,a5,0x3
    80001962:	0001a697          	auipc	a3,0x1a
    80001966:	4de68693          	addi	a3,a3,1246 # 8001be40 <queue>
    8000196a:	97b6                	add	a5,a5,a3
    8000196c:	567d                	li	a2,-1
    queue[queue_number].mlfq_queue[i+1] = queue[queue_number].mlfq_queue[i];
    8000196e:	6394                	ld	a3,0(a5)
    80001970:	e794                	sd	a3,8(a5)
  for(int i=queue[queue_number].length-1;i>=0;i--) {
    80001972:	377d                	addiw	a4,a4,-1
    80001974:	17e1                	addi	a5,a5,-8
    80001976:	fec71ce3          	bne	a4,a2,8000196e <mlfq_push_front+0x58>
  }
  queue[queue_number].mlfq_queue[0] = p;
    8000197a:	00559793          	slli	a5,a1,0x5
    8000197e:	95be                	add	a1,a1,a5
    80001980:	0592                	slli	a1,a1,0x4
    80001982:	0001a797          	auipc	a5,0x1a
    80001986:	4be78793          	addi	a5,a5,1214 # 8001be40 <queue>
    8000198a:	95be                	add	a1,a1,a5
    8000198c:	e988                	sd	a0,16(a1)
}
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <pop>:

struct proc *pop(int queue_number) {
  if(queue[queue_number].tail < 0) {
    80001994:	00551793          	slli	a5,a0,0x5
    80001998:	97aa                	add	a5,a5,a0
    8000199a:	0792                	slli	a5,a5,0x4
    8000199c:	0001a717          	auipc	a4,0x1a
    800019a0:	4a470713          	addi	a4,a4,1188 # 8001be40 <queue>
    800019a4:	97ba                	add	a5,a5,a4
    800019a6:	43cc                	lw	a1,4(a5)
    800019a8:	0605c263          	bltz	a1,80001a0c <pop+0x78>
    800019ac:	862a                	mv	a2,a0
    panic("Queue is empty");
  }

  struct proc *mypro;
  mypro = queue[queue_number].mlfq_queue[0];
    800019ae:	0001a697          	auipc	a3,0x1a
    800019b2:	49268693          	addi	a3,a3,1170 # 8001be40 <queue>
    800019b6:	00551793          	slli	a5,a0,0x5
    800019ba:	00a78733          	add	a4,a5,a0
    800019be:	0712                	slli	a4,a4,0x4
    800019c0:	9736                	add	a4,a4,a3
    800019c2:	6b08                	ld	a0,16(a4)
  queue[queue_number].mlfq_queue[0] = 0;
    800019c4:	00073823          	sd	zero,16(a4)

  for(int i=0;i<NPROC-1;i++) {
    800019c8:	97b2                	add	a5,a5,a2
    800019ca:	00479713          	slli	a4,a5,0x4
    800019ce:	01070793          	addi	a5,a4,16
    800019d2:	97b6                	add	a5,a5,a3
    800019d4:	0001a697          	auipc	a3,0x1a
    800019d8:	67468693          	addi	a3,a3,1652 # 8001c048 <queue+0x208>
    800019dc:	96ba                	add	a3,a3,a4
    queue[queue_number].mlfq_queue[i] = queue[queue_number].mlfq_queue[i+1];
    800019de:	6798                	ld	a4,8(a5)
    800019e0:	e398                	sd	a4,0(a5)
  for(int i=0;i<NPROC-1;i++) {
    800019e2:	07a1                	addi	a5,a5,8
    800019e4:	fed79de3          	bne	a5,a3,800019de <pop+0x4a>
  }
  queue[queue_number].tail = queue[queue_number].tail - 1;
    800019e8:	0001a697          	auipc	a3,0x1a
    800019ec:	45868693          	addi	a3,a3,1112 # 8001be40 <queue>
    800019f0:	00561713          	slli	a4,a2,0x5
    800019f4:	00c707b3          	add	a5,a4,a2
    800019f8:	0792                	slli	a5,a5,0x4
    800019fa:	97b6                	add	a5,a5,a3
    800019fc:	35fd                	addiw	a1,a1,-1
    800019fe:	c3cc                	sw	a1,4(a5)
  queue[queue_number].length = queue[queue_number].length - 1;
    80001a00:	4798                	lw	a4,8(a5)
    80001a02:	377d                	addiw	a4,a4,-1
    80001a04:	c798                	sw	a4,8(a5)
  mypro->status_queue = 0;
    80001a06:	2a052023          	sw	zero,672(a0)
  return mypro;
}
    80001a0a:	8082                	ret
struct proc *pop(int queue_number) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e406                	sd	ra,8(sp)
    80001a10:	e022                	sd	s0,0(sp)
    80001a12:	0800                	addi	s0,sp,16
    panic("Queue is empty");
    80001a14:	00006517          	auipc	a0,0x6
    80001a18:	7e450513          	addi	a0,a0,2020 # 800081f8 <digits+0x1b8>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b22080e7          	jalr	-1246(ra) # 8000053e <panic>

0000000080001a24 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a24:	7139                	addi	sp,sp,-64
    80001a26:	fc06                	sd	ra,56(sp)
    80001a28:	f822                	sd	s0,48(sp)
    80001a2a:	f426                	sd	s1,40(sp)
    80001a2c:	f04a                	sd	s2,32(sp)
    80001a2e:	ec4e                	sd	s3,24(sp)
    80001a30:	e852                	sd	s4,16(sp)
    80001a32:	e456                	sd	s5,8(sp)
    80001a34:	e05a                	sd	s6,0(sp)
    80001a36:	0080                	addi	s0,sp,64
    80001a38:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a3a:	00010497          	auipc	s1,0x10
    80001a3e:	80648493          	addi	s1,s1,-2042 # 80011240 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a42:	8b26                	mv	s6,s1
    80001a44:	00006a97          	auipc	s5,0x6
    80001a48:	5bca8a93          	addi	s5,s5,1468 # 80008000 <etext>
    80001a4c:	04000937          	lui	s2,0x4000
    80001a50:	197d                	addi	s2,s2,-1
    80001a52:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a54:	0001aa17          	auipc	s4,0x1a
    80001a58:	3eca0a13          	addi	s4,s4,1004 # 8001be40 <queue>
    char *pa = kalloc();
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	08a080e7          	jalr	138(ra) # 80000ae6 <kalloc>
    80001a64:	862a                	mv	a2,a0
    if (pa == 0)
    80001a66:	c131                	beqz	a0,80001aaa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a68:	416485b3          	sub	a1,s1,s6
    80001a6c:	8591                	srai	a1,a1,0x4
    80001a6e:	000ab783          	ld	a5,0(s5)
    80001a72:	02f585b3          	mul	a1,a1,a5
    80001a76:	2585                	addiw	a1,a1,1
    80001a78:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a7c:	4719                	li	a4,6
    80001a7e:	6685                	lui	a3,0x1
    80001a80:	40b905b3          	sub	a1,s2,a1
    80001a84:	854e                	mv	a0,s3
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	6b8080e7          	jalr	1720(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8e:	2b048493          	addi	s1,s1,688
    80001a92:	fd4495e3          	bne	s1,s4,80001a5c <proc_mapstacks+0x38>
  }
}
    80001a96:	70e2                	ld	ra,56(sp)
    80001a98:	7442                	ld	s0,48(sp)
    80001a9a:	74a2                	ld	s1,40(sp)
    80001a9c:	7902                	ld	s2,32(sp)
    80001a9e:	69e2                	ld	s3,24(sp)
    80001aa0:	6a42                	ld	s4,16(sp)
    80001aa2:	6aa2                	ld	s5,8(sp)
    80001aa4:	6b02                	ld	s6,0(sp)
    80001aa6:	6121                	addi	sp,sp,64
    80001aa8:	8082                	ret
      panic("kalloc");
    80001aaa:	00006517          	auipc	a0,0x6
    80001aae:	75e50513          	addi	a0,a0,1886 # 80008208 <digits+0x1c8>
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>

0000000080001aba <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001aba:	7139                	addi	sp,sp,-64
    80001abc:	fc06                	sd	ra,56(sp)
    80001abe:	f822                	sd	s0,48(sp)
    80001ac0:	f426                	sd	s1,40(sp)
    80001ac2:	f04a                	sd	s2,32(sp)
    80001ac4:	ec4e                	sd	s3,24(sp)
    80001ac6:	e852                	sd	s4,16(sp)
    80001ac8:	e456                	sd	s5,8(sp)
    80001aca:	e05a                	sd	s6,0(sp)
    80001acc:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001ace:	00006597          	auipc	a1,0x6
    80001ad2:	74258593          	addi	a1,a1,1858 # 80008210 <digits+0x1d0>
    80001ad6:	0000f517          	auipc	a0,0xf
    80001ada:	33a50513          	addi	a0,a0,826 # 80010e10 <pid_lock>
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	068080e7          	jalr	104(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ae6:	00006597          	auipc	a1,0x6
    80001aea:	73258593          	addi	a1,a1,1842 # 80008218 <digits+0x1d8>
    80001aee:	0000f517          	auipc	a0,0xf
    80001af2:	33a50513          	addi	a0,a0,826 # 80010e28 <wait_lock>
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	050080e7          	jalr	80(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001afe:	0000f497          	auipc	s1,0xf
    80001b02:	74248493          	addi	s1,s1,1858 # 80011240 <proc>
  {
    initlock(&p->lock, "proc");
    80001b06:	00006b17          	auipc	s6,0x6
    80001b0a:	722b0b13          	addi	s6,s6,1826 # 80008228 <digits+0x1e8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b0e:	8aa6                	mv	s5,s1
    80001b10:	00006a17          	auipc	s4,0x6
    80001b14:	4f0a0a13          	addi	s4,s4,1264 # 80008000 <etext>
    80001b18:	04000937          	lui	s2,0x4000
    80001b1c:	197d                	addi	s2,s2,-1
    80001b1e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b20:	0001a997          	auipc	s3,0x1a
    80001b24:	32098993          	addi	s3,s3,800 # 8001be40 <queue>
    initlock(&p->lock, "proc");
    80001b28:	85da                	mv	a1,s6
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	01a080e7          	jalr	26(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001b34:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b38:	415487b3          	sub	a5,s1,s5
    80001b3c:	8791                	srai	a5,a5,0x4
    80001b3e:	000a3703          	ld	a4,0(s4)
    80001b42:	02e787b3          	mul	a5,a5,a4
    80001b46:	2785                	addiw	a5,a5,1
    80001b48:	00d7979b          	slliw	a5,a5,0xd
    80001b4c:	40f907b3          	sub	a5,s2,a5
    80001b50:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b52:	2b048493          	addi	s1,s1,688
    80001b56:	fd3499e3          	bne	s1,s3,80001b28 <procinit+0x6e>
  }
}
    80001b5a:	70e2                	ld	ra,56(sp)
    80001b5c:	7442                	ld	s0,48(sp)
    80001b5e:	74a2                	ld	s1,40(sp)
    80001b60:	7902                	ld	s2,32(sp)
    80001b62:	69e2                	ld	s3,24(sp)
    80001b64:	6a42                	ld	s4,16(sp)
    80001b66:	6aa2                	ld	s5,8(sp)
    80001b68:	6b02                	ld	s6,0(sp)
    80001b6a:	6121                	addi	sp,sp,64
    80001b6c:	8082                	ret

0000000080001b6e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b6e:	1141                	addi	sp,sp,-16
    80001b70:	e422                	sd	s0,8(sp)
    80001b72:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b74:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b76:	2501                	sext.w	a0,a0
    80001b78:	6422                	ld	s0,8(sp)
    80001b7a:	0141                	addi	sp,sp,16
    80001b7c:	8082                	ret

0000000080001b7e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b7e:	1141                	addi	sp,sp,-16
    80001b80:	e422                	sd	s0,8(sp)
    80001b82:	0800                	addi	s0,sp,16
    80001b84:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b86:	2781                	sext.w	a5,a5
    80001b88:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b8a:	0000f517          	auipc	a0,0xf
    80001b8e:	2b650513          	addi	a0,a0,694 # 80010e40 <cpus>
    80001b92:	953e                	add	a0,a0,a5
    80001b94:	6422                	ld	s0,8(sp)
    80001b96:	0141                	addi	sp,sp,16
    80001b98:	8082                	ret

0000000080001b9a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b9a:	1101                	addi	sp,sp,-32
    80001b9c:	ec06                	sd	ra,24(sp)
    80001b9e:	e822                	sd	s0,16(sp)
    80001ba0:	e426                	sd	s1,8(sp)
    80001ba2:	1000                	addi	s0,sp,32
  push_off();
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	fe6080e7          	jalr	-26(ra) # 80000b8a <push_off>
    80001bac:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bae:	2781                	sext.w	a5,a5
    80001bb0:	079e                	slli	a5,a5,0x7
    80001bb2:	0000f717          	auipc	a4,0xf
    80001bb6:	25e70713          	addi	a4,a4,606 # 80010e10 <pid_lock>
    80001bba:	97ba                	add	a5,a5,a4
    80001bbc:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	06c080e7          	jalr	108(ra) # 80000c2a <pop_off>
  return p;
}
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6105                	addi	sp,sp,32
    80001bd0:	8082                	ret

0000000080001bd2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bd2:	1141                	addi	sp,sp,-16
    80001bd4:	e406                	sd	ra,8(sp)
    80001bd6:	e022                	sd	s0,0(sp)
    80001bd8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	fc0080e7          	jalr	-64(ra) # 80001b9a <myproc>
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>

  if (first)
    80001bea:	00007797          	auipc	a5,0x7
    80001bee:	e567a783          	lw	a5,-426(a5) # 80008a40 <first.1>
    80001bf2:	eb89                	bnez	a5,80001c04 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bf4:	00001097          	auipc	ra,0x1
    80001bf8:	0c0080e7          	jalr	192(ra) # 80002cb4 <usertrapret>
}
    80001bfc:	60a2                	ld	ra,8(sp)
    80001bfe:	6402                	ld	s0,0(sp)
    80001c00:	0141                	addi	sp,sp,16
    80001c02:	8082                	ret
    first = 0;
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	e207ae23          	sw	zero,-452(a5) # 80008a40 <first.1>
    fsinit(ROOTDEV);
    80001c0c:	4505                	li	a0,1
    80001c0e:	00002097          	auipc	ra,0x2
    80001c12:	27e080e7          	jalr	638(ra) # 80003e8c <fsinit>
    80001c16:	bff9                	j	80001bf4 <forkret+0x22>

0000000080001c18 <allocpid>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c24:	0000f917          	auipc	s2,0xf
    80001c28:	1ec90913          	addi	s2,s2,492 # 80010e10 <pid_lock>
    80001c2c:	854a                	mv	a0,s2
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	fa8080e7          	jalr	-88(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001c36:	00007797          	auipc	a5,0x7
    80001c3a:	e1a78793          	addi	a5,a5,-486 # 80008a50 <nextpid>
    80001c3e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c40:	0014871b          	addiw	a4,s1,1
    80001c44:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c46:	854a                	mv	a0,s2
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	042080e7          	jalr	66(ra) # 80000c8a <release>
}
    80001c50:	8526                	mv	a0,s1
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret

0000000080001c5e <proc_pagetable>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	e04a                	sd	s2,0(sp)
    80001c68:	1000                	addi	s0,sp,32
    80001c6a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	6bc080e7          	jalr	1724(ra) # 80001328 <uvmcreate>
    80001c74:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c76:	c121                	beqz	a0,80001cb6 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c78:	4729                	li	a4,10
    80001c7a:	00005697          	auipc	a3,0x5
    80001c7e:	38668693          	addi	a3,a3,902 # 80007000 <_trampoline>
    80001c82:	6605                	lui	a2,0x1
    80001c84:	040005b7          	lui	a1,0x4000
    80001c88:	15fd                	addi	a1,a1,-1
    80001c8a:	05b2                	slli	a1,a1,0xc
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	412080e7          	jalr	1042(ra) # 8000109e <mappages>
    80001c94:	02054863          	bltz	a0,80001cc4 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c98:	4719                	li	a4,6
    80001c9a:	05893683          	ld	a3,88(s2)
    80001c9e:	6605                	lui	a2,0x1
    80001ca0:	020005b7          	lui	a1,0x2000
    80001ca4:	15fd                	addi	a1,a1,-1
    80001ca6:	05b6                	slli	a1,a1,0xd
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	3f4080e7          	jalr	1012(ra) # 8000109e <mappages>
    80001cb2:	02054163          	bltz	a0,80001cd4 <proc_pagetable+0x76>
}
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	60e2                	ld	ra,24(sp)
    80001cba:	6442                	ld	s0,16(sp)
    80001cbc:	64a2                	ld	s1,8(sp)
    80001cbe:	6902                	ld	s2,0(sp)
    80001cc0:	6105                	addi	sp,sp,32
    80001cc2:	8082                	ret
    uvmfree(pagetable, 0);
    80001cc4:	4581                	li	a1,0
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	864080e7          	jalr	-1948(ra) # 8000152c <uvmfree>
    return 0;
    80001cd0:	4481                	li	s1,0
    80001cd2:	b7d5                	j	80001cb6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cd4:	4681                	li	a3,0
    80001cd6:	4605                	li	a2,1
    80001cd8:	040005b7          	lui	a1,0x4000
    80001cdc:	15fd                	addi	a1,a1,-1
    80001cde:	05b2                	slli	a1,a1,0xc
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	582080e7          	jalr	1410(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cea:	4581                	li	a1,0
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	83e080e7          	jalr	-1986(ra) # 8000152c <uvmfree>
    return 0;
    80001cf6:	4481                	li	s1,0
    80001cf8:	bf7d                	j	80001cb6 <proc_pagetable+0x58>

0000000080001cfa <proc_freepagetable>:
{
    80001cfa:	1101                	addi	sp,sp,-32
    80001cfc:	ec06                	sd	ra,24(sp)
    80001cfe:	e822                	sd	s0,16(sp)
    80001d00:	e426                	sd	s1,8(sp)
    80001d02:	e04a                	sd	s2,0(sp)
    80001d04:	1000                	addi	s0,sp,32
    80001d06:	84aa                	mv	s1,a0
    80001d08:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d0a:	4681                	li	a3,0
    80001d0c:	4605                	li	a2,1
    80001d0e:	040005b7          	lui	a1,0x4000
    80001d12:	15fd                	addi	a1,a1,-1
    80001d14:	05b2                	slli	a1,a1,0xc
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	54e080e7          	jalr	1358(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d1e:	4681                	li	a3,0
    80001d20:	4605                	li	a2,1
    80001d22:	020005b7          	lui	a1,0x2000
    80001d26:	15fd                	addi	a1,a1,-1
    80001d28:	05b6                	slli	a1,a1,0xd
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	538080e7          	jalr	1336(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d34:	85ca                	mv	a1,s2
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	7f4080e7          	jalr	2036(ra) # 8000152c <uvmfree>
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret

0000000080001d4c <freeproc>:
{
    80001d4c:	1101                	addi	sp,sp,-32
    80001d4e:	ec06                	sd	ra,24(sp)
    80001d50:	e822                	sd	s0,16(sp)
    80001d52:	e426                	sd	s1,8(sp)
    80001d54:	1000                	addi	s0,sp,32
    80001d56:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d58:	6d28                	ld	a0,88(a0)
    80001d5a:	c509                	beqz	a0,80001d64 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	c8e080e7          	jalr	-882(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001d64:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d68:	68a8                	ld	a0,80(s1)
    80001d6a:	c511                	beqz	a0,80001d76 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d6c:	64ac                	ld	a1,72(s1)
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	f8c080e7          	jalr	-116(ra) # 80001cfa <proc_freepagetable>
  p->pagetable = 0;
    80001d76:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d7a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d7e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d82:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d86:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d8a:	0204b023          	sd	zero,32(s1)
  p->status_queue = 0;
    80001d8e:	2a04a023          	sw	zero,672(s1)
  p->killed = 0;
    80001d92:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d96:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d9a:	0004ac23          	sw	zero,24(s1)
}
    80001d9e:	60e2                	ld	ra,24(sp)
    80001da0:	6442                	ld	s0,16(sp)
    80001da2:	64a2                	ld	s1,8(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <allocproc>:
{
    80001da8:	7179                	addi	sp,sp,-48
    80001daa:	f406                	sd	ra,40(sp)
    80001dac:	f022                	sd	s0,32(sp)
    80001dae:	ec26                	sd	s1,24(sp)
    80001db0:	e84a                	sd	s2,16(sp)
    80001db2:	e44e                	sd	s3,8(sp)
    80001db4:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001db6:	0000f497          	auipc	s1,0xf
    80001dba:	48a48493          	addi	s1,s1,1162 # 80011240 <proc>
    80001dbe:	0001a997          	auipc	s3,0x1a
    80001dc2:	08298993          	addi	s3,s3,130 # 8001be40 <queue>
    acquire(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	e0e080e7          	jalr	-498(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001dd0:	4c9c                	lw	a5,24(s1)
    80001dd2:	cf81                	beqz	a5,80001dea <allocproc+0x42>
      release(&p->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dde:	2b048493          	addi	s1,s1,688
    80001de2:	ff3492e3          	bne	s1,s3,80001dc6 <allocproc+0x1e>
  return 0;
    80001de6:	4481                	li	s1,0
    80001de8:	a861                	j	80001e80 <allocproc+0xd8>
  p->pid = allocpid();
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	e2e080e7          	jalr	-466(ra) # 80001c18 <allocpid>
    80001df2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001df4:	4785                	li	a5,1
    80001df6:	cc9c                	sw	a5,24(s1)
  for(int i=0;i<32;i++) {
    80001df8:	17848793          	addi	a5,s1,376
    80001dfc:	27848713          	addi	a4,s1,632
    p->sysCounter[i] = 0;
    80001e00:	0007b023          	sd	zero,0(a5)
  for(int i=0;i<32;i++) {
    80001e04:	07a1                	addi	a5,a5,8
    80001e06:	fee79de3          	bne	a5,a4,80001e00 <allocproc+0x58>
  p->alarm_status = 0;
    80001e0a:	2804a823          	sw	zero,656(s1)
  p->handling_alarm = 0;
    80001e0e:	2604bc23          	sd	zero,632(s1)
  p->current_ticks = 0;
    80001e12:	2804a223          	sw	zero,644(s1)
  p->trapframe_alarm = 0;
    80001e16:	2804b423          	sd	zero,648(s1)
  p->ticks_of_alarm = 0;
    80001e1a:	2804a023          	sw	zero,640(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	cc8080e7          	jalr	-824(ra) # 80000ae6 <kalloc>
    80001e26:	892a                	mv	s2,a0
    80001e28:	eca8                	sd	a0,88(s1)
    80001e2a:	c13d                	beqz	a0,80001e90 <allocproc+0xe8>
  p->pagetable = proc_pagetable(p);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	e30080e7          	jalr	-464(ra) # 80001c5e <proc_pagetable>
    80001e36:	892a                	mv	s2,a0
    80001e38:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e3a:	c53d                	beqz	a0,80001ea8 <allocproc+0x100>
  memset(&p->context, 0, sizeof(p->context));
    80001e3c:	07000613          	li	a2,112
    80001e40:	4581                	li	a1,0
    80001e42:	06048513          	addi	a0,s1,96
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e8c080e7          	jalr	-372(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e4e:	00000797          	auipc	a5,0x0
    80001e52:	d8478793          	addi	a5,a5,-636 # 80001bd2 <forkret>
    80001e56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e58:	60bc                	ld	a5,64(s1)
    80001e5a:	6705                	lui	a4,0x1
    80001e5c:	97ba                	add	a5,a5,a4
    80001e5e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e60:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e64:	1604a823          	sw	zero,368(s1)
  p->wait_ticks = 0;
    80001e68:	2804ae23          	sw	zero,668(s1)
  p->status_queue = 0;
    80001e6c:	2a04a023          	sw	zero,672(s1)
  p->priority_queue_number = 0;
    80001e70:	2804aa23          	sw	zero,660(s1)
  p->ctime = ticks;
    80001e74:	00007797          	auipc	a5,0x7
    80001e78:	d2c7a783          	lw	a5,-724(a5) # 80008ba0 <ticks>
    80001e7c:	16f4a623          	sw	a5,364(s1)
}
    80001e80:	8526                	mv	a0,s1
    80001e82:	70a2                	ld	ra,40(sp)
    80001e84:	7402                	ld	s0,32(sp)
    80001e86:	64e2                	ld	s1,24(sp)
    80001e88:	6942                	ld	s2,16(sp)
    80001e8a:	69a2                	ld	s3,8(sp)
    80001e8c:	6145                	addi	sp,sp,48
    80001e8e:	8082                	ret
    freeproc(p);
    80001e90:	8526                	mv	a0,s1
    80001e92:	00000097          	auipc	ra,0x0
    80001e96:	eba080e7          	jalr	-326(ra) # 80001d4c <freeproc>
    release(&p->lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dee080e7          	jalr	-530(ra) # 80000c8a <release>
    return 0;
    80001ea4:	84ca                	mv	s1,s2
    80001ea6:	bfe9                	j	80001e80 <allocproc+0xd8>
    freeproc(p);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	00000097          	auipc	ra,0x0
    80001eae:	ea2080e7          	jalr	-350(ra) # 80001d4c <freeproc>
    release(&p->lock);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dd6080e7          	jalr	-554(ra) # 80000c8a <release>
    return 0;
    80001ebc:	84ca                	mv	s1,s2
    80001ebe:	b7c9                	j	80001e80 <allocproc+0xd8>

0000000080001ec0 <userinit>:
{
    80001ec0:	7179                	addi	sp,sp,-48
    80001ec2:	f406                	sd	ra,40(sp)
    80001ec4:	f022                	sd	s0,32(sp)
    80001ec6:	ec26                	sd	s1,24(sp)
    80001ec8:	1800                	addi	s0,sp,48
    int priority_queue_ticks[] = {1,4,8,16};
    80001eca:	4785                	li	a5,1
    80001ecc:	fcf42823          	sw	a5,-48(s0)
    80001ed0:	4791                	li	a5,4
    80001ed2:	fcf42a23          	sw	a5,-44(s0)
    80001ed6:	47a1                	li	a5,8
    80001ed8:	fcf42c23          	sw	a5,-40(s0)
    80001edc:	47c1                	li	a5,16
    80001ede:	fcf42e23          	sw	a5,-36(s0)
    for(int i=0;i<queue_size;i++) {
    80001ee2:	fd040693          	addi	a3,s0,-48
    80001ee6:	0001a717          	auipc	a4,0x1a
    80001eea:	0ea70713          	addi	a4,a4,234 # 8001bfd0 <queue+0x190>
    80001eee:	0001b617          	auipc	a2,0x1b
    80001ef2:	92260613          	addi	a2,a2,-1758 # 8001c810 <bcache+0x178>
      queue[i].priority_queue_ticks = priority_queue_ticks[i];
    80001ef6:	429c                	lw	a5,0(a3)
    80001ef8:	e6f72e23          	sw	a5,-388(a4)
      queue[i].head = 0;
    80001efc:	e6072823          	sw	zero,-400(a4)
      queue[i].tail = 0;
    80001f00:	e6072a23          	sw	zero,-396(a4)
      queue[i].length = 0;
    80001f04:	e6072c23          	sw	zero,-392(a4)
      for(int k=0;k<48;k++) {
    80001f08:	e8070793          	addi	a5,a4,-384
        queue[i].mlfq_queue[k] = 0;
    80001f0c:	0007b023          	sd	zero,0(a5)
      for(int k=0;k<48;k++) {
    80001f10:	07a1                	addi	a5,a5,8
    80001f12:	fee79de3          	bne	a5,a4,80001f0c <userinit+0x4c>
    for(int i=0;i<queue_size;i++) {
    80001f16:	0691                	addi	a3,a3,4
    80001f18:	21070713          	addi	a4,a4,528
    80001f1c:	fcc71de3          	bne	a4,a2,80001ef6 <userinit+0x36>
  p = allocproc();
    80001f20:	00000097          	auipc	ra,0x0
    80001f24:	e88080e7          	jalr	-376(ra) # 80001da8 <allocproc>
    80001f28:	84aa                	mv	s1,a0
  initproc = p;
    80001f2a:	00007797          	auipc	a5,0x7
    80001f2e:	c6a7b723          	sd	a0,-914(a5) # 80008b98 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f32:	03400613          	li	a2,52
    80001f36:	00007597          	auipc	a1,0x7
    80001f3a:	b2a58593          	addi	a1,a1,-1238 # 80008a60 <initcode>
    80001f3e:	6928                	ld	a0,80(a0)
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	416080e7          	jalr	1046(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001f48:	6785                	lui	a5,0x1
    80001f4a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f4c:	6cb8                	ld	a4,88(s1)
    80001f4e:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f52:	6cb8                	ld	a4,88(s1)
    80001f54:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f56:	4641                	li	a2,16
    80001f58:	00006597          	auipc	a1,0x6
    80001f5c:	2d858593          	addi	a1,a1,728 # 80008230 <digits+0x1f0>
    80001f60:	15848513          	addi	a0,s1,344
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	eb8080e7          	jalr	-328(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001f6c:	00006517          	auipc	a0,0x6
    80001f70:	2d450513          	addi	a0,a0,724 # 80008240 <digits+0x200>
    80001f74:	00003097          	auipc	ra,0x3
    80001f78:	93a080e7          	jalr	-1734(ra) # 800048ae <namei>
    80001f7c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f80:	478d                	li	a5,3
    80001f82:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
}
    80001f8e:	70a2                	ld	ra,40(sp)
    80001f90:	7402                	ld	s0,32(sp)
    80001f92:	64e2                	ld	s1,24(sp)
    80001f94:	6145                	addi	sp,sp,48
    80001f96:	8082                	ret

0000000080001f98 <growproc>:
{
    80001f98:	1101                	addi	sp,sp,-32
    80001f9a:	ec06                	sd	ra,24(sp)
    80001f9c:	e822                	sd	s0,16(sp)
    80001f9e:	e426                	sd	s1,8(sp)
    80001fa0:	e04a                	sd	s2,0(sp)
    80001fa2:	1000                	addi	s0,sp,32
    80001fa4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	bf4080e7          	jalr	-1036(ra) # 80001b9a <myproc>
    80001fae:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fb0:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001fb2:	01204c63          	bgtz	s2,80001fca <growproc+0x32>
  else if (n < 0)
    80001fb6:	02094663          	bltz	s2,80001fe2 <growproc+0x4a>
  p->sz = sz;
    80001fba:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fbc:	4501                	li	a0,0
}
    80001fbe:	60e2                	ld	ra,24(sp)
    80001fc0:	6442                	ld	s0,16(sp)
    80001fc2:	64a2                	ld	s1,8(sp)
    80001fc4:	6902                	ld	s2,0(sp)
    80001fc6:	6105                	addi	sp,sp,32
    80001fc8:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fca:	4691                	li	a3,4
    80001fcc:	00b90633          	add	a2,s2,a1
    80001fd0:	6928                	ld	a0,80(a0)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	43e080e7          	jalr	1086(ra) # 80001410 <uvmalloc>
    80001fda:	85aa                	mv	a1,a0
    80001fdc:	fd79                	bnez	a0,80001fba <growproc+0x22>
      return -1;
    80001fde:	557d                	li	a0,-1
    80001fe0:	bff9                	j	80001fbe <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fe2:	00b90633          	add	a2,s2,a1
    80001fe6:	6928                	ld	a0,80(a0)
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	3e0080e7          	jalr	992(ra) # 800013c8 <uvmdealloc>
    80001ff0:	85aa                	mv	a1,a0
    80001ff2:	b7e1                	j	80001fba <growproc+0x22>

0000000080001ff4 <fork>:
{
    80001ff4:	7139                	addi	sp,sp,-64
    80001ff6:	fc06                	sd	ra,56(sp)
    80001ff8:	f822                	sd	s0,48(sp)
    80001ffa:	f426                	sd	s1,40(sp)
    80001ffc:	f04a                	sd	s2,32(sp)
    80001ffe:	ec4e                	sd	s3,24(sp)
    80002000:	e852                	sd	s4,16(sp)
    80002002:	e456                	sd	s5,8(sp)
    80002004:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	b94080e7          	jalr	-1132(ra) # 80001b9a <myproc>
    8000200e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80002010:	00000097          	auipc	ra,0x0
    80002014:	d98080e7          	jalr	-616(ra) # 80001da8 <allocproc>
    80002018:	12050663          	beqz	a0,80002144 <fork+0x150>
    8000201c:	89aa                	mv	s3,a0
    8000201e:	17850793          	addi	a5,a0,376
    80002022:	27850713          	addi	a4,a0,632
    np->sysCounter[i] = 0;  // Initialize syscall counters for the child process
    80002026:	0007b023          	sd	zero,0(a5) # 1000 <_entry-0x7ffff000>
   for (int i = 0; i < 32; i++) {
    8000202a:	07a1                	addi	a5,a5,8
    8000202c:	fee79de3          	bne	a5,a4,80002026 <fork+0x32>
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002030:	048ab603          	ld	a2,72(s5)
    80002034:	0509b583          	ld	a1,80(s3)
    80002038:	050ab503          	ld	a0,80(s5)
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	528080e7          	jalr	1320(ra) # 80001564 <uvmcopy>
    80002044:	04054863          	bltz	a0,80002094 <fork+0xa0>
  np->sz = p->sz;
    80002048:	048ab783          	ld	a5,72(s5)
    8000204c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002050:	058ab683          	ld	a3,88(s5)
    80002054:	87b6                	mv	a5,a3
    80002056:	0589b703          	ld	a4,88(s3)
    8000205a:	12068693          	addi	a3,a3,288
    8000205e:	0007b803          	ld	a6,0(a5)
    80002062:	6788                	ld	a0,8(a5)
    80002064:	6b8c                	ld	a1,16(a5)
    80002066:	6f90                	ld	a2,24(a5)
    80002068:	01073023          	sd	a6,0(a4)
    8000206c:	e708                	sd	a0,8(a4)
    8000206e:	eb0c                	sd	a1,16(a4)
    80002070:	ef10                	sd	a2,24(a4)
    80002072:	02078793          	addi	a5,a5,32
    80002076:	02070713          	addi	a4,a4,32
    8000207a:	fed792e3          	bne	a5,a3,8000205e <fork+0x6a>
  np->trapframe->a0 = 0;
    8000207e:	0589b783          	ld	a5,88(s3)
    80002082:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002086:	0d0a8493          	addi	s1,s5,208
    8000208a:	0d098913          	addi	s2,s3,208
    8000208e:	150a8a13          	addi	s4,s5,336
    80002092:	a00d                	j	800020b4 <fork+0xc0>
    freeproc(np);
    80002094:	854e                	mv	a0,s3
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	cb6080e7          	jalr	-842(ra) # 80001d4c <freeproc>
    release(&np->lock);
    8000209e:	854e                	mv	a0,s3
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	bea080e7          	jalr	-1046(ra) # 80000c8a <release>
    return -1;
    800020a8:	597d                	li	s2,-1
    800020aa:	a059                	j	80002130 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    800020ac:	04a1                	addi	s1,s1,8
    800020ae:	0921                	addi	s2,s2,8
    800020b0:	01448b63          	beq	s1,s4,800020c6 <fork+0xd2>
    if (p->ofile[i])
    800020b4:	6088                	ld	a0,0(s1)
    800020b6:	d97d                	beqz	a0,800020ac <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    800020b8:	00003097          	auipc	ra,0x3
    800020bc:	e8c080e7          	jalr	-372(ra) # 80004f44 <filedup>
    800020c0:	00a93023          	sd	a0,0(s2)
    800020c4:	b7e5                	j	800020ac <fork+0xb8>
  np->cwd = idup(p->cwd);
    800020c6:	150ab503          	ld	a0,336(s5)
    800020ca:	00002097          	auipc	ra,0x2
    800020ce:	000080e7          	jalr	ra # 800040ca <idup>
    800020d2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020d6:	4641                	li	a2,16
    800020d8:	158a8593          	addi	a1,s5,344
    800020dc:	15898513          	addi	a0,s3,344
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	d3c080e7          	jalr	-708(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    800020e8:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    800020ec:	854e                	mv	a0,s3
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	b9c080e7          	jalr	-1124(ra) # 80000c8a <release>
  acquire(&wait_lock);
    800020f6:	0000f497          	auipc	s1,0xf
    800020fa:	d3248493          	addi	s1,s1,-718 # 80010e28 <wait_lock>
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	ad6080e7          	jalr	-1322(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002108:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
  acquire(&np->lock);
    80002116:	854e                	mv	a0,s3
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	abe080e7          	jalr	-1346(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002120:	478d                	li	a5,3
    80002122:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002126:	854e                	mv	a0,s3
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b62080e7          	jalr	-1182(ra) # 80000c8a <release>
}
    80002130:	854a                	mv	a0,s2
    80002132:	70e2                	ld	ra,56(sp)
    80002134:	7442                	ld	s0,48(sp)
    80002136:	74a2                	ld	s1,40(sp)
    80002138:	7902                	ld	s2,32(sp)
    8000213a:	69e2                	ld	s3,24(sp)
    8000213c:	6a42                	ld	s4,16(sp)
    8000213e:	6aa2                	ld	s5,8(sp)
    80002140:	6121                	addi	sp,sp,64
    80002142:	8082                	ret
    return -1;
    80002144:	597d                	li	s2,-1
    80002146:	b7ed                	j	80002130 <fork+0x13c>

0000000080002148 <scheduler>:
{
    80002148:	711d                	addi	sp,sp,-96
    8000214a:	ec86                	sd	ra,88(sp)
    8000214c:	e8a2                	sd	s0,80(sp)
    8000214e:	e4a6                	sd	s1,72(sp)
    80002150:	e0ca                	sd	s2,64(sp)
    80002152:	fc4e                	sd	s3,56(sp)
    80002154:	f852                	sd	s4,48(sp)
    80002156:	f456                	sd	s5,40(sp)
    80002158:	f05a                	sd	s6,32(sp)
    8000215a:	ec5e                	sd	s7,24(sp)
    8000215c:	e862                	sd	s8,16(sp)
    8000215e:	e466                	sd	s9,8(sp)
    80002160:	e06a                	sd	s10,0(sp)
    80002162:	1080                	addi	s0,sp,96
    80002164:	8792                	mv	a5,tp
  int id = r_tp();
    80002166:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002168:	00779a93          	slli	s5,a5,0x7
    8000216c:	0000f717          	auipc	a4,0xf
    80002170:	ca470713          	addi	a4,a4,-860 # 80010e10 <pid_lock>
    80002174:	9756                	add	a4,a4,s5
    80002176:	02073823          	sd	zero,48(a4)
        swtch(&c->context,&current_process_track->context);
    8000217a:	0000f717          	auipc	a4,0xf
    8000217e:	cce70713          	addi	a4,a4,-818 # 80010e48 <cpus+0x8>
    80002182:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE && p->status_queue == 0) {
    80002184:	490d                	li	s2,3
        if(queue[present_queue_number].tail >= 100) {
    80002186:	0001a997          	auipc	s3,0x1a
    8000218a:	cba98993          	addi	s3,s3,-838 # 8001be40 <queue>
    for(p = proc;p < &proc[NPROC];p++) {
    8000218e:	0001aa17          	auipc	s4,0x1a
    80002192:	cb2a0a13          	addi	s4,s4,-846 # 8001be40 <queue>
        c->proc = current_process_track;
    80002196:	079e                	slli	a5,a5,0x7
    80002198:	0000fb17          	auipc	s6,0xf
    8000219c:	c78b0b13          	addi	s6,s6,-904 # 80010e10 <pid_lock>
    800021a0:	9b3e                	add	s6,s6,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021a6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021aa:	10079073          	csrw	sstatus,a5
    for(p = proc;p < &proc[NPROC];p++) {
    800021ae:	0000f797          	auipc	a5,0xf
    800021b2:	09278793          	addi	a5,a5,146 # 80011240 <proc>
        if(queue[present_queue_number].tail >= 100) {
    800021b6:	06300593          	li	a1,99
        p->status_queue = 1;
    800021ba:	4505                	li	a0,1
    800021bc:	a829                	j	800021d6 <scheduler+0x8e>
          panic("Invalid parameters passed");
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	01a50513          	addi	a0,a0,26 # 800081d8 <digits+0x198>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
    for(p = proc;p < &proc[NPROC];p++) {
    800021ce:	2b078793          	addi	a5,a5,688
    800021d2:	05478d63          	beq	a5,s4,8000222c <scheduler+0xe4>
      if(p->state == RUNNABLE && p->status_queue == 0) {
    800021d6:	4f98                	lw	a4,24(a5)
    800021d8:	ff271be3          	bne	a4,s2,800021ce <scheduler+0x86>
    800021dc:	2a07a703          	lw	a4,672(a5)
    800021e0:	f77d                	bnez	a4,800021ce <scheduler+0x86>
        present_queue_number = p->priority_queue_number;
    800021e2:	2947a603          	lw	a2,660(a5)
        if(queue[present_queue_number].tail >= 100) {
    800021e6:	00561713          	slli	a4,a2,0x5
    800021ea:	9732                	add	a4,a4,a2
    800021ec:	0712                	slli	a4,a4,0x4
    800021ee:	974e                	add	a4,a4,s3
    800021f0:	00472803          	lw	a6,4(a4)
    800021f4:	fd05c5e3          	blt	a1,a6,800021be <scheduler+0x76>
        queue[present_queue_number].mlfq_queue[queue[present_queue_number].tail] = p;
    800021f8:	00561693          	slli	a3,a2,0x5
    800021fc:	00c68733          	add	a4,a3,a2
    80002200:	0706                	slli	a4,a4,0x1
    80002202:	9742                	add	a4,a4,a6
    80002204:	0709                	addi	a4,a4,2
    80002206:	070e                	slli	a4,a4,0x3
    80002208:	974e                	add	a4,a4,s3
    8000220a:	e31c                	sd	a5,0(a4)
        queue[present_queue_number].tail = queue[present_queue_number].tail + 1;
    8000220c:	00c68733          	add	a4,a3,a2
    80002210:	0712                	slli	a4,a4,0x4
    80002212:	974e                	add	a4,a4,s3
    80002214:	0018089b          	addiw	a7,a6,1
    80002218:	01172223          	sw	a7,4(a4)
        queue[present_queue_number].length = queue[present_queue_number].length + 1;
    8000221c:	4714                	lw	a3,8(a4)
    8000221e:	2685                	addiw	a3,a3,1
    80002220:	c714                	sw	a3,8(a4)
        p->status_queue = 1;
    80002222:	2aa7a023          	sw	a0,672(a5)
        p->number_process = queue[present_queue_number].tail - 1; 
    80002226:	2b07a223          	sw	a6,676(a5)
        p->status_queue = 1;
    8000222a:	b755                	j	800021ce <scheduler+0x86>
    8000222c:	0001ac17          	auipc	s8,0x1a
    80002230:	c14c0c13          	addi	s8,s8,-1004 # 8001be40 <queue>
    for(int i=0;i<queue_size;i++) {
    80002234:	4b81                	li	s7,0
    80002236:	4c81                	li	s9,0
    80002238:	4d11                	li	s10,4
    8000223a:	a039                	j	80002248 <scheduler+0x100>
    8000223c:	2b85                	addiw	s7,s7,1
    8000223e:	0bab8e63          	beq	s7,s10,800022fa <scheduler+0x1b2>
      if(current_process_track != 0) {
    80002242:	210c0c13          	addi	s8,s8,528
    80002246:	ecc5                	bnez	s1,800022fe <scheduler+0x1b6>
    for(int i=0;i<queue_size;i++) {
    80002248:	84e6                	mv	s1,s9
      while(!(queue[i].tail <= 0)) {
    8000224a:	004c2783          	lw	a5,4(s8)
    8000224e:	fef057e3          	blez	a5,8000223c <scheduler+0xf4>
        current_process_track = pop(i);
    80002252:	855e                	mv	a0,s7
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	740080e7          	jalr	1856(ra) # 80001994 <pop>
    8000225c:	84aa                	mv	s1,a0
        current_process_track->status_queue = 0;
    8000225e:	2a052023          	sw	zero,672(a0)
        if(current_process_track->state == RUNNABLE) {
    80002262:	4d1c                	lw	a5,24(a0)
    80002264:	ff2793e3          	bne	a5,s2,8000224a <scheduler+0x102>
          queue[current_process_track->priority_queue_number].tail = queue[current_process_track->priority_queue_number].tail + 1;
    80002268:	29452683          	lw	a3,660(a0)
    8000226c:	00569793          	slli	a5,a3,0x5
    80002270:	00d78733          	add	a4,a5,a3
    80002274:	0712                	slli	a4,a4,0x4
    80002276:	974e                	add	a4,a4,s3
    80002278:	435c                	lw	a5,4(a4)
    8000227a:	2785                	addiw	a5,a5,1
    8000227c:	c35c                	sw	a5,4(a4)
          queue[current_process_track->priority_queue_number].length = queue[current_process_track->priority_queue_number].length + 1;
    8000227e:	29452683          	lw	a3,660(a0)
    80002282:	00569793          	slli	a5,a3,0x5
    80002286:	00d78733          	add	a4,a5,a3
    8000228a:	0712                	slli	a4,a4,0x4
    8000228c:	974e                	add	a4,a4,s3
    8000228e:	471c                	lw	a5,8(a4)
    80002290:	2785                	addiw	a5,a5,1
    80002292:	c71c                	sw	a5,8(a4)
          current_process_track->status_queue = 1;
    80002294:	4785                	li	a5,1
    80002296:	2af52023          	sw	a5,672(a0)
          current_process_track->number_process = 0;
    8000229a:	2a052223          	sw	zero,676(a0)
          for(int i=queue[current_process_track->priority_queue_number].length-1;i>=0;i--) {
    8000229e:	29452703          	lw	a4,660(a0)
    800022a2:	00571793          	slli	a5,a4,0x5
    800022a6:	97ba                	add	a5,a5,a4
    800022a8:	0792                	slli	a5,a5,0x4
    800022aa:	97ce                	add	a5,a5,s3
    800022ac:	4794                	lw	a3,8(a5)
    800022ae:	36fd                	addiw	a3,a3,-1
    800022b0:	0206cb63          	bltz	a3,800022e6 <scheduler+0x19e>
    800022b4:	557d                	li	a0,-1
            queue[current_process_track->priority_queue_number].mlfq_queue[i+1] = queue[current_process_track->priority_queue_number].mlfq_queue[i];
    800022b6:	2944a603          	lw	a2,660(s1)
    800022ba:	00561793          	slli	a5,a2,0x5
    800022be:	00c78733          	add	a4,a5,a2
    800022c2:	0706                	slli	a4,a4,0x1
    800022c4:	9736                	add	a4,a4,a3
    800022c6:	0709                	addi	a4,a4,2
    800022c8:	070e                	slli	a4,a4,0x3
    800022ca:	974e                	add	a4,a4,s3
    800022cc:	6318                	ld	a4,0(a4)
    800022ce:	0016859b          	addiw	a1,a3,1
    800022d2:	97b2                	add	a5,a5,a2
    800022d4:	0786                	slli	a5,a5,0x1
    800022d6:	97ae                	add	a5,a5,a1
    800022d8:	0789                	addi	a5,a5,2
    800022da:	078e                	slli	a5,a5,0x3
    800022dc:	97ce                	add	a5,a5,s3
    800022de:	e398                	sd	a4,0(a5)
          for(int i=queue[current_process_track->priority_queue_number].length-1;i>=0;i--) {
    800022e0:	36fd                	addiw	a3,a3,-1
    800022e2:	fca69ae3          	bne	a3,a0,800022b6 <scheduler+0x16e>
          queue[current_process_track->priority_queue_number].mlfq_queue[0] = current_process_track;
    800022e6:	2944a703          	lw	a4,660(s1)
    800022ea:	00571793          	slli	a5,a4,0x5
    800022ee:	97ba                	add	a5,a5,a4
    800022f0:	0792                	slli	a5,a5,0x4
    800022f2:	97ce                	add	a5,a5,s3
    800022f4:	eb84                	sd	s1,16(a5)
    for(int i=0;i<queue_size;i++) {
    800022f6:	012b9463          	bne	s7,s2,800022fe <scheduler+0x1b6>
    if(current_process_track != 0) {
    800022fa:	ea0484e3          	beqz	s1,800021a2 <scheduler+0x5a>
      if(current_process_track->state == RUNNABLE) {
    800022fe:	4c9c                	lw	a5,24(s1)
    80002300:	eb2791e3          	bne	a5,s2,800021a2 <scheduler+0x5a>
        acquire(&current_process_track->lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	8d0080e7          	jalr	-1840(ra) # 80000bd6 <acquire>
        current_process_track->state = RUNNING;
    8000230e:	4791                	li	a5,4
    80002310:	cc9c                	sw	a5,24(s1)
        c->proc = current_process_track;
    80002312:	029b3823          	sd	s1,48(s6)
        swtch(&c->context,&current_process_track->context);
    80002316:	06048593          	addi	a1,s1,96
    8000231a:	8556                	mv	a0,s5
    8000231c:	00001097          	auipc	ra,0x1
    80002320:	8ee080e7          	jalr	-1810(ra) # 80002c0a <swtch>
        c->proc = 0;
    80002324:	020b3823          	sd	zero,48(s6)
        release(&current_process_track->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
    80002332:	bd85                	j	800021a2 <scheduler+0x5a>

0000000080002334 <sched>:
{
    80002334:	7179                	addi	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	858080e7          	jalr	-1960(ra) # 80001b9a <myproc>
    8000234a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	810080e7          	jalr	-2032(ra) # 80000b5c <holding>
    80002354:	c93d                	beqz	a0,800023ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002356:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002358:	2781                	sext.w	a5,a5
    8000235a:	079e                	slli	a5,a5,0x7
    8000235c:	0000f717          	auipc	a4,0xf
    80002360:	ab470713          	addi	a4,a4,-1356 # 80010e10 <pid_lock>
    80002364:	97ba                	add	a5,a5,a4
    80002366:	0a87a703          	lw	a4,168(a5)
    8000236a:	4785                	li	a5,1
    8000236c:	06f71763          	bne	a4,a5,800023da <sched+0xa6>
  if (p->state == RUNNING)
    80002370:	4c98                	lw	a4,24(s1)
    80002372:	4791                	li	a5,4
    80002374:	06f70b63          	beq	a4,a5,800023ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002378:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000237c:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000237e:	efb5                	bnez	a5,800023fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002380:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002382:	0000f917          	auipc	s2,0xf
    80002386:	a8e90913          	addi	s2,s2,-1394 # 80010e10 <pid_lock>
    8000238a:	2781                	sext.w	a5,a5
    8000238c:	079e                	slli	a5,a5,0x7
    8000238e:	97ca                	add	a5,a5,s2
    80002390:	0ac7a983          	lw	s3,172(a5)
    80002394:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002396:	2781                	sext.w	a5,a5
    80002398:	079e                	slli	a5,a5,0x7
    8000239a:	0000f597          	auipc	a1,0xf
    8000239e:	aae58593          	addi	a1,a1,-1362 # 80010e48 <cpus+0x8>
    800023a2:	95be                	add	a1,a1,a5
    800023a4:	06048513          	addi	a0,s1,96
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	862080e7          	jalr	-1950(ra) # 80002c0a <swtch>
    800023b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023b2:	2781                	sext.w	a5,a5
    800023b4:	079e                	slli	a5,a5,0x7
    800023b6:	97ca                	add	a5,a5,s2
    800023b8:	0b37a623          	sw	s3,172(a5)
}
    800023bc:	70a2                	ld	ra,40(sp)
    800023be:	7402                	ld	s0,32(sp)
    800023c0:	64e2                	ld	s1,24(sp)
    800023c2:	6942                	ld	s2,16(sp)
    800023c4:	69a2                	ld	s3,8(sp)
    800023c6:	6145                	addi	sp,sp,48
    800023c8:	8082                	ret
    panic("sched p->lock");
    800023ca:	00006517          	auipc	a0,0x6
    800023ce:	e7e50513          	addi	a0,a0,-386 # 80008248 <digits+0x208>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>
    panic("sched locks");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	e7e50513          	addi	a0,a0,-386 # 80008258 <digits+0x218>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>
    panic("sched running");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	e7e50513          	addi	a0,a0,-386 # 80008268 <digits+0x228>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>
    panic("sched interruptible");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	e7e50513          	addi	a0,a0,-386 # 80008278 <digits+0x238>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	13c080e7          	jalr	316(ra) # 8000053e <panic>

000000008000240a <yield>:
{
    8000240a:	1101                	addi	sp,sp,-32
    8000240c:	ec06                	sd	ra,24(sp)
    8000240e:	e822                	sd	s0,16(sp)
    80002410:	e426                	sd	s1,8(sp)
    80002412:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	786080e7          	jalr	1926(ra) # 80001b9a <myproc>
    8000241c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7b8080e7          	jalr	1976(ra) # 80000bd6 <acquire>
  if(p->state != SLEEPING) {
    80002426:	4c98                	lw	a4,24(s1)
    80002428:	4789                	li	a5,2
    8000242a:	00f70463          	beq	a4,a5,80002432 <yield+0x28>
  p->state = RUNNABLE;
    8000242e:	478d                	li	a5,3
    80002430:	cc9c                	sw	a5,24(s1)
  sched();
    80002432:	00000097          	auipc	ra,0x0
    80002436:	f02080e7          	jalr	-254(ra) # 80002334 <sched>
  release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
}
    80002444:	60e2                	ld	ra,24(sp)
    80002446:	6442                	ld	s0,16(sp)
    80002448:	64a2                	ld	s1,8(sp)
    8000244a:	6105                	addi	sp,sp,32
    8000244c:	8082                	ret

000000008000244e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	89aa                	mv	s3,a0
    8000245e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	73a080e7          	jalr	1850(ra) # 80001b9a <myproc>
    80002468:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	76c080e7          	jalr	1900(ra) # 80000bd6 <acquire>
  release(lk);
    80002472:	854a                	mv	a0,s2
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	816080e7          	jalr	-2026(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000247c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002480:	4789                	li	a5,2
    80002482:	cc9c                	sw	a5,24(s1)

  sched();
    80002484:	00000097          	auipc	ra,0x0
    80002488:	eb0080e7          	jalr	-336(ra) # 80002334 <sched>

  // Tidy up.
  p->chan = 0;
    8000248c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	7f8080e7          	jalr	2040(ra) # 80000c8a <release>
  acquire(lk);
    8000249a:	854a                	mv	a0,s2
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	73a080e7          	jalr	1850(ra) # 80000bd6 <acquire>
}
    800024a4:	70a2                	ld	ra,40(sp)
    800024a6:	7402                	ld	s0,32(sp)
    800024a8:	64e2                	ld	s1,24(sp)
    800024aa:	6942                	ld	s2,16(sp)
    800024ac:	69a2                	ld	s3,8(sp)
    800024ae:	6145                	addi	sp,sp,48
    800024b0:	8082                	ret

00000000800024b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024b2:	7139                	addi	sp,sp,-64
    800024b4:	fc06                	sd	ra,56(sp)
    800024b6:	f822                	sd	s0,48(sp)
    800024b8:	f426                	sd	s1,40(sp)
    800024ba:	f04a                	sd	s2,32(sp)
    800024bc:	ec4e                	sd	s3,24(sp)
    800024be:	e852                	sd	s4,16(sp)
    800024c0:	e456                	sd	s5,8(sp)
    800024c2:	0080                	addi	s0,sp,64
    800024c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024c6:	0000f497          	auipc	s1,0xf
    800024ca:	d7a48493          	addi	s1,s1,-646 # 80011240 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800024ce:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800024d0:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800024d2:	0001a917          	auipc	s2,0x1a
    800024d6:	96e90913          	addi	s2,s2,-1682 # 8001be40 <queue>
    800024da:	a811                	j	800024ee <wakeup+0x3c>
        // p->arrival_time = ticks;
      }
      release(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7ac080e7          	jalr	1964(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024e6:	2b048493          	addi	s1,s1,688
    800024ea:	03248663          	beq	s1,s2,80002516 <wakeup+0x64>
    if (p != myproc())
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	6ac080e7          	jalr	1708(ra) # 80001b9a <myproc>
    800024f6:	fea488e3          	beq	s1,a0,800024e6 <wakeup+0x34>
      acquire(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	6da080e7          	jalr	1754(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002504:	4c9c                	lw	a5,24(s1)
    80002506:	fd379be3          	bne	a5,s3,800024dc <wakeup+0x2a>
    8000250a:	709c                	ld	a5,32(s1)
    8000250c:	fd4798e3          	bne	a5,s4,800024dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002510:	0154ac23          	sw	s5,24(s1)
    80002514:	b7e1                	j	800024dc <wakeup+0x2a>
    }
  }
}
    80002516:	70e2                	ld	ra,56(sp)
    80002518:	7442                	ld	s0,48(sp)
    8000251a:	74a2                	ld	s1,40(sp)
    8000251c:	7902                	ld	s2,32(sp)
    8000251e:	69e2                	ld	s3,24(sp)
    80002520:	6a42                	ld	s4,16(sp)
    80002522:	6aa2                	ld	s5,8(sp)
    80002524:	6121                	addi	sp,sp,64
    80002526:	8082                	ret

0000000080002528 <reparent>:
{
    80002528:	7179                	addi	sp,sp,-48
    8000252a:	f406                	sd	ra,40(sp)
    8000252c:	f022                	sd	s0,32(sp)
    8000252e:	ec26                	sd	s1,24(sp)
    80002530:	e84a                	sd	s2,16(sp)
    80002532:	e44e                	sd	s3,8(sp)
    80002534:	e052                	sd	s4,0(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000253a:	0000f497          	auipc	s1,0xf
    8000253e:	d0648493          	addi	s1,s1,-762 # 80011240 <proc>
      pp->parent = initproc;
    80002542:	00006a17          	auipc	s4,0x6
    80002546:	656a0a13          	addi	s4,s4,1622 # 80008b98 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000254a:	0001a997          	auipc	s3,0x1a
    8000254e:	8f698993          	addi	s3,s3,-1802 # 8001be40 <queue>
    80002552:	a029                	j	8000255c <reparent+0x34>
    80002554:	2b048493          	addi	s1,s1,688
    80002558:	01348d63          	beq	s1,s3,80002572 <reparent+0x4a>
    if (pp->parent == p)
    8000255c:	7c9c                	ld	a5,56(s1)
    8000255e:	ff279be3          	bne	a5,s2,80002554 <reparent+0x2c>
      pp->parent = initproc;
    80002562:	000a3503          	ld	a0,0(s4)
    80002566:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	f4a080e7          	jalr	-182(ra) # 800024b2 <wakeup>
    80002570:	b7d5                	j	80002554 <reparent+0x2c>
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6a02                	ld	s4,0(sp)
    8000257e:	6145                	addi	sp,sp,48
    80002580:	8082                	ret

0000000080002582 <exit>:
{
    80002582:	7179                	addi	sp,sp,-48
    80002584:	f406                	sd	ra,40(sp)
    80002586:	f022                	sd	s0,32(sp)
    80002588:	ec26                	sd	s1,24(sp)
    8000258a:	e84a                	sd	s2,16(sp)
    8000258c:	e44e                	sd	s3,8(sp)
    8000258e:	e052                	sd	s4,0(sp)
    80002590:	1800                	addi	s0,sp,48
    80002592:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	606080e7          	jalr	1542(ra) # 80001b9a <myproc>
    8000259c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000259e:	00006797          	auipc	a5,0x6
    800025a2:	5fa7b783          	ld	a5,1530(a5) # 80008b98 <initproc>
    800025a6:	0d050493          	addi	s1,a0,208
    800025aa:	15050913          	addi	s2,a0,336
    800025ae:	02a79363          	bne	a5,a0,800025d4 <exit+0x52>
    panic("init exiting");
    800025b2:	00006517          	auipc	a0,0x6
    800025b6:	cde50513          	addi	a0,a0,-802 # 80008290 <digits+0x250>
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>
      fileclose(f);
    800025c2:	00003097          	auipc	ra,0x3
    800025c6:	9d4080e7          	jalr	-1580(ra) # 80004f96 <fileclose>
      p->ofile[fd] = 0;
    800025ca:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800025ce:	04a1                	addi	s1,s1,8
    800025d0:	01248563          	beq	s1,s2,800025da <exit+0x58>
    if (p->ofile[fd])
    800025d4:	6088                	ld	a0,0(s1)
    800025d6:	f575                	bnez	a0,800025c2 <exit+0x40>
    800025d8:	bfdd                	j	800025ce <exit+0x4c>
  begin_op();
    800025da:	00002097          	auipc	ra,0x2
    800025de:	4f0080e7          	jalr	1264(ra) # 80004aca <begin_op>
  iput(p->cwd);
    800025e2:	1509b503          	ld	a0,336(s3)
    800025e6:	00002097          	auipc	ra,0x2
    800025ea:	cdc080e7          	jalr	-804(ra) # 800042c2 <iput>
  end_op();
    800025ee:	00002097          	auipc	ra,0x2
    800025f2:	55c080e7          	jalr	1372(ra) # 80004b4a <end_op>
  p->cwd = 0;
    800025f6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	82e48493          	addi	s1,s1,-2002 # 80010e28 <wait_lock>
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	5d2080e7          	jalr	1490(ra) # 80000bd6 <acquire>
  reparent(p);
    8000260c:	854e                	mv	a0,s3
    8000260e:	00000097          	auipc	ra,0x0
    80002612:	f1a080e7          	jalr	-230(ra) # 80002528 <reparent>
  wakeup(p->parent);
    80002616:	0389b503          	ld	a0,56(s3)
    8000261a:	00000097          	auipc	ra,0x0
    8000261e:	e98080e7          	jalr	-360(ra) # 800024b2 <wakeup>
  acquire(&p->lock);
    80002622:	854e                	mv	a0,s3
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	5b2080e7          	jalr	1458(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000262c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002630:	4795                	li	a5,5
    80002632:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002636:	00006797          	auipc	a5,0x6
    8000263a:	56a7a783          	lw	a5,1386(a5) # 80008ba0 <ticks>
    8000263e:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	646080e7          	jalr	1606(ra) # 80000c8a <release>
  sched();
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	ce8080e7          	jalr	-792(ra) # 80002334 <sched>
  panic("zombie exit");
    80002654:	00006517          	auipc	a0,0x6
    80002658:	c4c50513          	addi	a0,a0,-948 # 800082a0 <digits+0x260>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>

0000000080002664 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002664:	7179                	addi	sp,sp,-48
    80002666:	f406                	sd	ra,40(sp)
    80002668:	f022                	sd	s0,32(sp)
    8000266a:	ec26                	sd	s1,24(sp)
    8000266c:	e84a                	sd	s2,16(sp)
    8000266e:	e44e                	sd	s3,8(sp)
    80002670:	1800                	addi	s0,sp,48
    80002672:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002674:	0000f497          	auipc	s1,0xf
    80002678:	bcc48493          	addi	s1,s1,-1076 # 80011240 <proc>
    8000267c:	00019997          	auipc	s3,0x19
    80002680:	7c498993          	addi	s3,s3,1988 # 8001be40 <queue>
  {
    acquire(&p->lock);
    80002684:	8526                	mv	a0,s1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	550080e7          	jalr	1360(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    8000268e:	589c                	lw	a5,48(s1)
    80002690:	01278d63          	beq	a5,s2,800026aa <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002694:	8526                	mv	a0,s1
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	5f4080e7          	jalr	1524(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000269e:	2b048493          	addi	s1,s1,688
    800026a2:	ff3491e3          	bne	s1,s3,80002684 <kill+0x20>
  }
  return -1;
    800026a6:	557d                	li	a0,-1
    800026a8:	a829                	j	800026c2 <kill+0x5e>
      p->killed = 1;
    800026aa:	4785                	li	a5,1
    800026ac:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800026ae:	4c98                	lw	a4,24(s1)
    800026b0:	4789                	li	a5,2
    800026b2:	00f70f63          	beq	a4,a5,800026d0 <kill+0x6c>
      release(&p->lock);
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5d2080e7          	jalr	1490(ra) # 80000c8a <release>
      return 0;
    800026c0:	4501                	li	a0,0
}
    800026c2:	70a2                	ld	ra,40(sp)
    800026c4:	7402                	ld	s0,32(sp)
    800026c6:	64e2                	ld	s1,24(sp)
    800026c8:	6942                	ld	s2,16(sp)
    800026ca:	69a2                	ld	s3,8(sp)
    800026cc:	6145                	addi	sp,sp,48
    800026ce:	8082                	ret
        p->state = RUNNABLE;
    800026d0:	478d                	li	a5,3
    800026d2:	cc9c                	sw	a5,24(s1)
    800026d4:	b7cd                	j	800026b6 <kill+0x52>

00000000800026d6 <setkilled>:

void setkilled(struct proc *p)
{
    800026d6:	1101                	addi	sp,sp,-32
    800026d8:	ec06                	sd	ra,24(sp)
    800026da:	e822                	sd	s0,16(sp)
    800026dc:	e426                	sd	s1,8(sp)
    800026de:	1000                	addi	s0,sp,32
    800026e0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	4f4080e7          	jalr	1268(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800026ea:	4785                	li	a5,1
    800026ec:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	59a080e7          	jalr	1434(ra) # 80000c8a <release>
}
    800026f8:	60e2                	ld	ra,24(sp)
    800026fa:	6442                	ld	s0,16(sp)
    800026fc:	64a2                	ld	s1,8(sp)
    800026fe:	6105                	addi	sp,sp,32
    80002700:	8082                	ret

0000000080002702 <killed>:

int killed(struct proc *p)
{
    80002702:	1101                	addi	sp,sp,-32
    80002704:	ec06                	sd	ra,24(sp)
    80002706:	e822                	sd	s0,16(sp)
    80002708:	e426                	sd	s1,8(sp)
    8000270a:	e04a                	sd	s2,0(sp)
    8000270c:	1000                	addi	s0,sp,32
    8000270e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	4c6080e7          	jalr	1222(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002718:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
  return k;
}
    80002726:	854a                	mv	a0,s2
    80002728:	60e2                	ld	ra,24(sp)
    8000272a:	6442                	ld	s0,16(sp)
    8000272c:	64a2                	ld	s1,8(sp)
    8000272e:	6902                	ld	s2,0(sp)
    80002730:	6105                	addi	sp,sp,32
    80002732:	8082                	ret

0000000080002734 <wait>:
{
    80002734:	715d                	addi	sp,sp,-80
    80002736:	e486                	sd	ra,72(sp)
    80002738:	e0a2                	sd	s0,64(sp)
    8000273a:	fc26                	sd	s1,56(sp)
    8000273c:	f84a                	sd	s2,48(sp)
    8000273e:	f44e                	sd	s3,40(sp)
    80002740:	f052                	sd	s4,32(sp)
    80002742:	ec56                	sd	s5,24(sp)
    80002744:	e85a                	sd	s6,16(sp)
    80002746:	e45e                	sd	s7,8(sp)
    80002748:	e062                	sd	s8,0(sp)
    8000274a:	0880                	addi	s0,sp,80
    8000274c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	44c080e7          	jalr	1100(ra) # 80001b9a <myproc>
    80002756:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002758:	0000e517          	auipc	a0,0xe
    8000275c:	6d050513          	addi	a0,a0,1744 # 80010e28 <wait_lock>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	476080e7          	jalr	1142(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002768:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000276a:	4a95                	li	s5,5
        havekids = 1;
    8000276c:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000276e:	00019997          	auipc	s3,0x19
    80002772:	6d298993          	addi	s3,s3,1746 # 8001be40 <queue>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002776:	0000ec17          	auipc	s8,0xe
    8000277a:	6b2c0c13          	addi	s8,s8,1714 # 80010e28 <wait_lock>
    havekids = 0;
    8000277e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002780:	0000f497          	auipc	s1,0xf
    80002784:	ac048493          	addi	s1,s1,-1344 # 80011240 <proc>
    80002788:	a069                	j	80002812 <wait+0xde>
    8000278a:	17890793          	addi	a5,s2,376
    8000278e:	17848693          	addi	a3,s1,376
    80002792:	27890593          	addi	a1,s2,632
            p->sysCounter[i] += pp->sysCounter[i];
    80002796:	6398                	ld	a4,0(a5)
    80002798:	6290                	ld	a2,0(a3)
    8000279a:	9732                	add	a4,a4,a2
    8000279c:	e398                	sd	a4,0(a5)
          for (int i = 0; i < 32; i++) {
    8000279e:	07a1                	addi	a5,a5,8
    800027a0:	06a1                	addi	a3,a3,8
    800027a2:	feb79ae3          	bne	a5,a1,80002796 <wait+0x62>
          pid = pp->pid;
    800027a6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027aa:	000a0e63          	beqz	s4,800027c6 <wait+0x92>
    800027ae:	4691                	li	a3,4
    800027b0:	02c48613          	addi	a2,s1,44
    800027b4:	85d2                	mv	a1,s4
    800027b6:	05093503          	ld	a0,80(s2)
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	eae080e7          	jalr	-338(ra) # 80001668 <copyout>
    800027c2:	02054563          	bltz	a0,800027ec <wait+0xb8>
          freeproc(pp);
    800027c6:	8526                	mv	a0,s1
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	584080e7          	jalr	1412(ra) # 80001d4c <freeproc>
          release(&pp->lock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4b8080e7          	jalr	1208(ra) # 80000c8a <release>
          release(&wait_lock);
    800027da:	0000e517          	auipc	a0,0xe
    800027de:	64e50513          	addi	a0,a0,1614 # 80010e28 <wait_lock>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	4a8080e7          	jalr	1192(ra) # 80000c8a <release>
          return pid;
    800027ea:	a0b5                	j	80002856 <wait+0x122>
            release(&pp->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	49c080e7          	jalr	1180(ra) # 80000c8a <release>
            release(&wait_lock);
    800027f6:	0000e517          	auipc	a0,0xe
    800027fa:	63250513          	addi	a0,a0,1586 # 80010e28 <wait_lock>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	48c080e7          	jalr	1164(ra) # 80000c8a <release>
            return -1;
    80002806:	59fd                	li	s3,-1
    80002808:	a0b9                	j	80002856 <wait+0x122>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000280a:	2b048493          	addi	s1,s1,688
    8000280e:	03348463          	beq	s1,s3,80002836 <wait+0x102>
      if (pp->parent == p)
    80002812:	7c9c                	ld	a5,56(s1)
    80002814:	ff279be3          	bne	a5,s2,8000280a <wait+0xd6>
        acquire(&pp->lock);
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	3bc080e7          	jalr	956(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002822:	4c9c                	lw	a5,24(s1)
    80002824:	f75783e3          	beq	a5,s5,8000278a <wait+0x56>
        release(&pp->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	460080e7          	jalr	1120(ra) # 80000c8a <release>
        havekids = 1;
    80002832:	875a                	mv	a4,s6
    80002834:	bfd9                	j	8000280a <wait+0xd6>
    if (!havekids || killed(p))
    80002836:	c719                	beqz	a4,80002844 <wait+0x110>
    80002838:	854a                	mv	a0,s2
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	ec8080e7          	jalr	-312(ra) # 80002702 <killed>
    80002842:	c51d                	beqz	a0,80002870 <wait+0x13c>
      release(&wait_lock);
    80002844:	0000e517          	auipc	a0,0xe
    80002848:	5e450513          	addi	a0,a0,1508 # 80010e28 <wait_lock>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	43e080e7          	jalr	1086(ra) # 80000c8a <release>
      return -1;
    80002854:	59fd                	li	s3,-1
}
    80002856:	854e                	mv	a0,s3
    80002858:	60a6                	ld	ra,72(sp)
    8000285a:	6406                	ld	s0,64(sp)
    8000285c:	74e2                	ld	s1,56(sp)
    8000285e:	7942                	ld	s2,48(sp)
    80002860:	79a2                	ld	s3,40(sp)
    80002862:	7a02                	ld	s4,32(sp)
    80002864:	6ae2                	ld	s5,24(sp)
    80002866:	6b42                	ld	s6,16(sp)
    80002868:	6ba2                	ld	s7,8(sp)
    8000286a:	6c02                	ld	s8,0(sp)
    8000286c:	6161                	addi	sp,sp,80
    8000286e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002870:	85e2                	mv	a1,s8
    80002872:	854a                	mv	a0,s2
    80002874:	00000097          	auipc	ra,0x0
    80002878:	bda080e7          	jalr	-1062(ra) # 8000244e <sleep>
    havekids = 0;
    8000287c:	b709                	j	8000277e <wait+0x4a>

000000008000287e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000287e:	7179                	addi	sp,sp,-48
    80002880:	f406                	sd	ra,40(sp)
    80002882:	f022                	sd	s0,32(sp)
    80002884:	ec26                	sd	s1,24(sp)
    80002886:	e84a                	sd	s2,16(sp)
    80002888:	e44e                	sd	s3,8(sp)
    8000288a:	e052                	sd	s4,0(sp)
    8000288c:	1800                	addi	s0,sp,48
    8000288e:	84aa                	mv	s1,a0
    80002890:	892e                	mv	s2,a1
    80002892:	89b2                	mv	s3,a2
    80002894:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	304080e7          	jalr	772(ra) # 80001b9a <myproc>
  if (user_dst)
    8000289e:	c08d                	beqz	s1,800028c0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800028a0:	86d2                	mv	a3,s4
    800028a2:	864e                	mv	a2,s3
    800028a4:	85ca                	mv	a1,s2
    800028a6:	6928                	ld	a0,80(a0)
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	dc0080e7          	jalr	-576(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028b0:	70a2                	ld	ra,40(sp)
    800028b2:	7402                	ld	s0,32(sp)
    800028b4:	64e2                	ld	s1,24(sp)
    800028b6:	6942                	ld	s2,16(sp)
    800028b8:	69a2                	ld	s3,8(sp)
    800028ba:	6a02                	ld	s4,0(sp)
    800028bc:	6145                	addi	sp,sp,48
    800028be:	8082                	ret
    memmove((char *)dst, src, len);
    800028c0:	000a061b          	sext.w	a2,s4
    800028c4:	85ce                	mv	a1,s3
    800028c6:	854a                	mv	a0,s2
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	466080e7          	jalr	1126(ra) # 80000d2e <memmove>
    return 0;
    800028d0:	8526                	mv	a0,s1
    800028d2:	bff9                	j	800028b0 <either_copyout+0x32>

00000000800028d4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028d4:	7179                	addi	sp,sp,-48
    800028d6:	f406                	sd	ra,40(sp)
    800028d8:	f022                	sd	s0,32(sp)
    800028da:	ec26                	sd	s1,24(sp)
    800028dc:	e84a                	sd	s2,16(sp)
    800028de:	e44e                	sd	s3,8(sp)
    800028e0:	e052                	sd	s4,0(sp)
    800028e2:	1800                	addi	s0,sp,48
    800028e4:	892a                	mv	s2,a0
    800028e6:	84ae                	mv	s1,a1
    800028e8:	89b2                	mv	s3,a2
    800028ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	2ae080e7          	jalr	686(ra) # 80001b9a <myproc>
  if (user_src)
    800028f4:	c08d                	beqz	s1,80002916 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800028f6:	86d2                	mv	a3,s4
    800028f8:	864e                	mv	a2,s3
    800028fa:	85ca                	mv	a1,s2
    800028fc:	6928                	ld	a0,80(a0)
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	df6080e7          	jalr	-522(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002906:	70a2                	ld	ra,40(sp)
    80002908:	7402                	ld	s0,32(sp)
    8000290a:	64e2                	ld	s1,24(sp)
    8000290c:	6942                	ld	s2,16(sp)
    8000290e:	69a2                	ld	s3,8(sp)
    80002910:	6a02                	ld	s4,0(sp)
    80002912:	6145                	addi	sp,sp,48
    80002914:	8082                	ret
    memmove(dst, (char *)src, len);
    80002916:	000a061b          	sext.w	a2,s4
    8000291a:	85ce                	mv	a1,s3
    8000291c:	854a                	mv	a0,s2
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	410080e7          	jalr	1040(ra) # 80000d2e <memmove>
    return 0;
    80002926:	8526                	mv	a0,s1
    80002928:	bff9                	j	80002906 <either_copyin+0x32>

000000008000292a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000292a:	715d                	addi	sp,sp,-80
    8000292c:	e486                	sd	ra,72(sp)
    8000292e:	e0a2                	sd	s0,64(sp)
    80002930:	fc26                	sd	s1,56(sp)
    80002932:	f84a                	sd	s2,48(sp)
    80002934:	f44e                	sd	s3,40(sp)
    80002936:	f052                	sd	s4,32(sp)
    80002938:	ec56                	sd	s5,24(sp)
    8000293a:	e85a                	sd	s6,16(sp)
    8000293c:	e45e                	sd	s7,8(sp)
    8000293e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002940:	00006517          	auipc	a0,0x6
    80002944:	cb850513          	addi	a0,a0,-840 # 800085f8 <syscalls+0x170>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002950:	0000f497          	auipc	s1,0xf
    80002954:	a4848493          	addi	s1,s1,-1464 # 80011398 <proc+0x158>
    80002958:	00019917          	auipc	s2,0x19
    8000295c:	64090913          	addi	s2,s2,1600 # 8001bf98 <queue+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002960:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002962:	00006997          	auipc	s3,0x6
    80002966:	94e98993          	addi	s3,s3,-1714 # 800082b0 <digits+0x270>
#ifdef MLFQ

  printf("%d %s %s %d Time : %d\n",p->pid,state,p->name,p->number_process,ticks-p->start_time);
    8000296a:	00006a97          	auipc	s5,0x6
    8000296e:	236a8a93          	addi	s5,s5,566 # 80008ba0 <ticks>
    80002972:	00006a17          	auipc	s4,0x6
    80002976:	946a0a13          	addi	s4,s4,-1722 # 800082b8 <digits+0x278>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000297a:	00006b97          	auipc	s7,0x6
    8000297e:	986b8b93          	addi	s7,s7,-1658 # 80008300 <states.0>
    80002982:	a025                	j	800029aa <procdump+0x80>
  printf("%d %s %s %d Time : %d\n",p->pid,state,p->name,p->number_process,ticks-p->start_time);
    80002984:	000aa703          	lw	a4,0(s5)
    80002988:	1406a783          	lw	a5,320(a3)
    8000298c:	40f707bb          	subw	a5,a4,a5
    80002990:	14c6a703          	lw	a4,332(a3)
    80002994:	ed86a583          	lw	a1,-296(a3)
    80002998:	8552                	mv	a0,s4
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bee080e7          	jalr	-1042(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029a2:	2b048493          	addi	s1,s1,688
    800029a6:	03248163          	beq	s1,s2,800029c8 <procdump+0x9e>
    if (p->state == UNUSED)
    800029aa:	86a6                	mv	a3,s1
    800029ac:	ec04a783          	lw	a5,-320(s1)
    800029b0:	dbed                	beqz	a5,800029a2 <procdump+0x78>
      state = "???";
    800029b2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029b4:	fcfb68e3          	bltu	s6,a5,80002984 <procdump+0x5a>
    800029b8:	1782                	slli	a5,a5,0x20
    800029ba:	9381                	srli	a5,a5,0x20
    800029bc:	078e                	slli	a5,a5,0x3
    800029be:	97de                	add	a5,a5,s7
    800029c0:	6390                	ld	a2,0(a5)
    800029c2:	f269                	bnez	a2,80002984 <procdump+0x5a>
      state = "???";
    800029c4:	864e                	mv	a2,s3
    800029c6:	bf7d                	j	80002984 <procdump+0x5a>
#ifdef DEFAULT
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
#endif
  }
}
    800029c8:	60a6                	ld	ra,72(sp)
    800029ca:	6406                	ld	s0,64(sp)
    800029cc:	74e2                	ld	s1,56(sp)
    800029ce:	7942                	ld	s2,48(sp)
    800029d0:	79a2                	ld	s3,40(sp)
    800029d2:	7a02                	ld	s4,32(sp)
    800029d4:	6ae2                	ld	s5,24(sp)
    800029d6:	6b42                	ld	s6,16(sp)
    800029d8:	6ba2                	ld	s7,8(sp)
    800029da:	6161                	addi	sp,sp,80
    800029dc:	8082                	ret

00000000800029de <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800029de:	711d                	addi	sp,sp,-96
    800029e0:	ec86                	sd	ra,88(sp)
    800029e2:	e8a2                	sd	s0,80(sp)
    800029e4:	e4a6                	sd	s1,72(sp)
    800029e6:	e0ca                	sd	s2,64(sp)
    800029e8:	fc4e                	sd	s3,56(sp)
    800029ea:	f852                	sd	s4,48(sp)
    800029ec:	f456                	sd	s5,40(sp)
    800029ee:	f05a                	sd	s6,32(sp)
    800029f0:	ec5e                	sd	s7,24(sp)
    800029f2:	e862                	sd	s8,16(sp)
    800029f4:	e466                	sd	s9,8(sp)
    800029f6:	e06a                	sd	s10,0(sp)
    800029f8:	1080                	addi	s0,sp,96
    800029fa:	8b2a                	mv	s6,a0
    800029fc:	8bae                	mv	s7,a1
    800029fe:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	19a080e7          	jalr	410(ra) # 80001b9a <myproc>
    80002a08:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a0a:	0000e517          	auipc	a0,0xe
    80002a0e:	41e50513          	addi	a0,a0,1054 # 80010e28 <wait_lock>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	1c4080e7          	jalr	452(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002a1a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002a1c:	4a15                	li	s4,5
        havekids = 1;
    80002a1e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002a20:	00019997          	auipc	s3,0x19
    80002a24:	42098993          	addi	s3,s3,1056 # 8001be40 <queue>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a28:	0000ed17          	auipc	s10,0xe
    80002a2c:	400d0d13          	addi	s10,s10,1024 # 80010e28 <wait_lock>
    havekids = 0;
    80002a30:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002a32:	0000f497          	auipc	s1,0xf
    80002a36:	80e48493          	addi	s1,s1,-2034 # 80011240 <proc>
    80002a3a:	a059                	j	80002ac0 <waitx+0xe2>
          pid = np->pid;
    80002a3c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002a40:	1684a703          	lw	a4,360(s1)
    80002a44:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002a48:	16c4a783          	lw	a5,364(s1)
    80002a4c:	9f3d                	addw	a4,a4,a5
    80002a4e:	1704a783          	lw	a5,368(s1)
    80002a52:	9f99                	subw	a5,a5,a4
    80002a54:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002a58:	000b0e63          	beqz	s6,80002a74 <waitx+0x96>
    80002a5c:	4691                	li	a3,4
    80002a5e:	02c48613          	addi	a2,s1,44
    80002a62:	85da                	mv	a1,s6
    80002a64:	05093503          	ld	a0,80(s2)
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	c00080e7          	jalr	-1024(ra) # 80001668 <copyout>
    80002a70:	02054563          	bltz	a0,80002a9a <waitx+0xbc>
          freeproc(np);
    80002a74:	8526                	mv	a0,s1
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	2d6080e7          	jalr	726(ra) # 80001d4c <freeproc>
          release(&np->lock);
    80002a7e:	8526                	mv	a0,s1
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	20a080e7          	jalr	522(ra) # 80000c8a <release>
          release(&wait_lock);
    80002a88:	0000e517          	auipc	a0,0xe
    80002a8c:	3a050513          	addi	a0,a0,928 # 80010e28 <wait_lock>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	1fa080e7          	jalr	506(ra) # 80000c8a <release>
          return pid;
    80002a98:	a09d                	j	80002afe <waitx+0x120>
            release(&np->lock);
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	1ee080e7          	jalr	494(ra) # 80000c8a <release>
            release(&wait_lock);
    80002aa4:	0000e517          	auipc	a0,0xe
    80002aa8:	38450513          	addi	a0,a0,900 # 80010e28 <wait_lock>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	1de080e7          	jalr	478(ra) # 80000c8a <release>
            return -1;
    80002ab4:	59fd                	li	s3,-1
    80002ab6:	a0a1                	j	80002afe <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002ab8:	2b048493          	addi	s1,s1,688
    80002abc:	03348463          	beq	s1,s3,80002ae4 <waitx+0x106>
      if (np->parent == p)
    80002ac0:	7c9c                	ld	a5,56(s1)
    80002ac2:	ff279be3          	bne	a5,s2,80002ab8 <waitx+0xda>
        acquire(&np->lock);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	10e080e7          	jalr	270(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002ad0:	4c9c                	lw	a5,24(s1)
    80002ad2:	f74785e3          	beq	a5,s4,80002a3c <waitx+0x5e>
        release(&np->lock);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	1b2080e7          	jalr	434(ra) # 80000c8a <release>
        havekids = 1;
    80002ae0:	8756                	mv	a4,s5
    80002ae2:	bfd9                	j	80002ab8 <waitx+0xda>
    if (!havekids || p->killed)
    80002ae4:	c701                	beqz	a4,80002aec <waitx+0x10e>
    80002ae6:	02892783          	lw	a5,40(s2)
    80002aea:	cb8d                	beqz	a5,80002b1c <waitx+0x13e>
      release(&wait_lock);
    80002aec:	0000e517          	auipc	a0,0xe
    80002af0:	33c50513          	addi	a0,a0,828 # 80010e28 <wait_lock>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	196080e7          	jalr	406(ra) # 80000c8a <release>
      return -1;
    80002afc:	59fd                	li	s3,-1
  }
}
    80002afe:	854e                	mv	a0,s3
    80002b00:	60e6                	ld	ra,88(sp)
    80002b02:	6446                	ld	s0,80(sp)
    80002b04:	64a6                	ld	s1,72(sp)
    80002b06:	6906                	ld	s2,64(sp)
    80002b08:	79e2                	ld	s3,56(sp)
    80002b0a:	7a42                	ld	s4,48(sp)
    80002b0c:	7aa2                	ld	s5,40(sp)
    80002b0e:	7b02                	ld	s6,32(sp)
    80002b10:	6be2                	ld	s7,24(sp)
    80002b12:	6c42                	ld	s8,16(sp)
    80002b14:	6ca2                	ld	s9,8(sp)
    80002b16:	6d02                	ld	s10,0(sp)
    80002b18:	6125                	addi	sp,sp,96
    80002b1a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b1c:	85ea                	mv	a1,s10
    80002b1e:	854a                	mv	a0,s2
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	92e080e7          	jalr	-1746(ra) # 8000244e <sleep>
    havekids = 0;
    80002b28:	b721                	j	80002a30 <waitx+0x52>

0000000080002b2a <update_time>:

void update_time()
{
    80002b2a:	7179                	addi	sp,sp,-48
    80002b2c:	f406                	sd	ra,40(sp)
    80002b2e:	f022                	sd	s0,32(sp)
    80002b30:	ec26                	sd	s1,24(sp)
    80002b32:	e84a                	sd	s2,16(sp)
    80002b34:	e44e                	sd	s3,8(sp)
    80002b36:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002b38:	0000e497          	auipc	s1,0xe
    80002b3c:	70848493          	addi	s1,s1,1800 # 80011240 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002b40:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002b42:	00019917          	auipc	s2,0x19
    80002b46:	2fe90913          	addi	s2,s2,766 # 8001be40 <queue>
    80002b4a:	a811                	j	80002b5e <update_time+0x34>
    else if(p->state == RUNNING) {
#ifdef MLFQ
      p->wait_ticks = p->wait_ticks + 1;
#endif
    }
    release(&p->lock);
    80002b4c:	8526                	mv	a0,s1
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	13c080e7          	jalr	316(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b56:	2b048493          	addi	s1,s1,688
    80002b5a:	03248563          	beq	s1,s2,80002b84 <update_time+0x5a>
    acquire(&p->lock);
    80002b5e:	8526                	mv	a0,s1
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	076080e7          	jalr	118(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002b68:	4c9c                	lw	a5,24(s1)
    80002b6a:	ff3791e3          	bne	a5,s3,80002b4c <update_time+0x22>
      p->rtime++;
    80002b6e:	1684a783          	lw	a5,360(s1)
    80002b72:	2785                	addiw	a5,a5,1
    80002b74:	16f4a423          	sw	a5,360(s1)
      p->start_time = p->start_time + 1;
    80002b78:	2984a783          	lw	a5,664(s1)
    80002b7c:	2785                	addiw	a5,a5,1
    80002b7e:	28f4ac23          	sw	a5,664(s1)
    80002b82:	b7e9                	j	80002b4c <update_time+0x22>
// 	  		if (p->state == RUNNABLE || p->state == RUNNING)
// 	  			printf("(%d, %d, %d),\n", p->pid, ticks, p->priority_queue_number);
// 	  	}
// 	  }
// #endif
}
    80002b84:	70a2                	ld	ra,40(sp)
    80002b86:	7402                	ld	s0,32(sp)
    80002b88:	64e2                	ld	s1,24(sp)
    80002b8a:	6942                	ld	s2,16(sp)
    80002b8c:	69a2                	ld	s3,8(sp)
    80002b8e:	6145                	addi	sp,sp,48
    80002b90:	8082                	ret

0000000080002b92 <settickets>:

#endif

int 
settickets(int number) {
  if(number < 0) {
    80002b92:	02054463          	bltz	a0,80002bba <settickets+0x28>
settickets(int number) {
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	e426                	sd	s1,8(sp)
    80002b9e:	1000                	addi	s0,sp,32
    80002ba0:	84aa                	mv	s1,a0
    return -1;
  }
  myproc()->tickets = number;
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	ff8080e7          	jalr	-8(ra) # 80001b9a <myproc>
    80002baa:	2a952423          	sw	s1,680(a0)
  return number;
    80002bae:	8526                	mv	a0,s1
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret
    return -1;
    80002bba:	557d                	li	a0,-1
}
    80002bbc:	8082                	ret

0000000080002bbe <srand>:

static unsigned long next = 1;

// Initialize the seed for the random number generator
void srand(unsigned int seed)
{
    80002bbe:	1141                	addi	sp,sp,-16
    80002bc0:	e422                	sd	s0,8(sp)
    80002bc2:	0800                	addi	s0,sp,16
  next = 0xABCDEFd;
    80002bc4:	0abce7b7          	lui	a5,0xabce
    80002bc8:	efd78793          	addi	a5,a5,-259 # abcdefd <_entry-0x75432103>
    80002bcc:	00006717          	auipc	a4,0x6
    80002bd0:	e6f73e23          	sd	a5,-388(a4) # 80008a48 <next>
}
    80002bd4:	6422                	ld	s0,8(sp)
    80002bd6:	0141                	addi	sp,sp,16
    80002bd8:	8082                	ret

0000000080002bda <rand>:


int rand(void)
{
    80002bda:	1141                	addi	sp,sp,-16
    80002bdc:	e422                	sd	s0,8(sp)
    80002bde:	0800                	addi	s0,sp,16
  next = next * 1103515245 + 12345;
    80002be0:	00006717          	auipc	a4,0x6
    80002be4:	e6870713          	addi	a4,a4,-408 # 80008a48 <next>
    80002be8:	6308                	ld	a0,0(a4)
    80002bea:	41c657b7          	lui	a5,0x41c65
    80002bee:	e6d78793          	addi	a5,a5,-403 # 41c64e6d <_entry-0x3e39b193>
    80002bf2:	02f50533          	mul	a0,a0,a5
    80002bf6:	678d                	lui	a5,0x3
    80002bf8:	03978793          	addi	a5,a5,57 # 3039 <_entry-0x7fffcfc7>
    80002bfc:	953e                	add	a0,a0,a5
    80002bfe:	e308                	sd	a0,0(a4)
  return (unsigned int)(next / 65536) % 32768;
    80002c00:	1506                	slli	a0,a0,0x21
    80002c02:	9145                	srli	a0,a0,0x31
    80002c04:	6422                	ld	s0,8(sp)
    80002c06:	0141                	addi	sp,sp,16
    80002c08:	8082                	ret

0000000080002c0a <swtch>:
    80002c0a:	00153023          	sd	ra,0(a0)
    80002c0e:	00253423          	sd	sp,8(a0)
    80002c12:	e900                	sd	s0,16(a0)
    80002c14:	ed04                	sd	s1,24(a0)
    80002c16:	03253023          	sd	s2,32(a0)
    80002c1a:	03353423          	sd	s3,40(a0)
    80002c1e:	03453823          	sd	s4,48(a0)
    80002c22:	03553c23          	sd	s5,56(a0)
    80002c26:	05653023          	sd	s6,64(a0)
    80002c2a:	05753423          	sd	s7,72(a0)
    80002c2e:	05853823          	sd	s8,80(a0)
    80002c32:	05953c23          	sd	s9,88(a0)
    80002c36:	07a53023          	sd	s10,96(a0)
    80002c3a:	07b53423          	sd	s11,104(a0)
    80002c3e:	0005b083          	ld	ra,0(a1)
    80002c42:	0085b103          	ld	sp,8(a1)
    80002c46:	6980                	ld	s0,16(a1)
    80002c48:	6d84                	ld	s1,24(a1)
    80002c4a:	0205b903          	ld	s2,32(a1)
    80002c4e:	0285b983          	ld	s3,40(a1)
    80002c52:	0305ba03          	ld	s4,48(a1)
    80002c56:	0385ba83          	ld	s5,56(a1)
    80002c5a:	0405bb03          	ld	s6,64(a1)
    80002c5e:	0485bb83          	ld	s7,72(a1)
    80002c62:	0505bc03          	ld	s8,80(a1)
    80002c66:	0585bc83          	ld	s9,88(a1)
    80002c6a:	0605bd03          	ld	s10,96(a1)
    80002c6e:	0685bd83          	ld	s11,104(a1)
    80002c72:	8082                	ret

0000000080002c74 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002c74:	1141                	addi	sp,sp,-16
    80002c76:	e406                	sd	ra,8(sp)
    80002c78:	e022                	sd	s0,0(sp)
    80002c7a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c7c:	00005597          	auipc	a1,0x5
    80002c80:	6b458593          	addi	a1,a1,1716 # 80008330 <states.0+0x30>
    80002c84:	0001a517          	auipc	a0,0x1a
    80002c88:	9fc50513          	addi	a0,a0,-1540 # 8001c680 <tickslock>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	eba080e7          	jalr	-326(ra) # 80000b46 <initlock>
}
    80002c94:	60a2                	ld	ra,8(sp)
    80002c96:	6402                	ld	s0,0(sp)
    80002c98:	0141                	addi	sp,sp,16
    80002c9a:	8082                	ret

0000000080002c9c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002c9c:	1141                	addi	sp,sp,-16
    80002c9e:	e422                	sd	s0,8(sp)
    80002ca0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca2:	00004797          	auipc	a5,0x4
    80002ca6:	93e78793          	addi	a5,a5,-1730 # 800065e0 <kernelvec>
    80002caa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cae:	6422                	ld	s0,8(sp)
    80002cb0:	0141                	addi	sp,sp,16
    80002cb2:	8082                	ret

0000000080002cb4 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002cb4:	1141                	addi	sp,sp,-16
    80002cb6:	e406                	sd	ra,8(sp)
    80002cb8:	e022                	sd	s0,0(sp)
    80002cba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	ede080e7          	jalr	-290(ra) # 80001b9a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cc8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cca:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002cce:	00004617          	auipc	a2,0x4
    80002cd2:	33260613          	addi	a2,a2,818 # 80007000 <_trampoline>
    80002cd6:	00004697          	auipc	a3,0x4
    80002cda:	32a68693          	addi	a3,a3,810 # 80007000 <_trampoline>
    80002cde:	8e91                	sub	a3,a3,a2
    80002ce0:	040007b7          	lui	a5,0x4000
    80002ce4:	17fd                	addi	a5,a5,-1
    80002ce6:	07b2                	slli	a5,a5,0xc
    80002ce8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cea:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cee:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cf0:	180026f3          	csrr	a3,satp
    80002cf4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cf6:	6d38                	ld	a4,88(a0)
    80002cf8:	6134                	ld	a3,64(a0)
    80002cfa:	6585                	lui	a1,0x1
    80002cfc:	96ae                	add	a3,a3,a1
    80002cfe:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d00:	6d38                	ld	a4,88(a0)
    80002d02:	00000697          	auipc	a3,0x0
    80002d06:	15e68693          	addi	a3,a3,350 # 80002e60 <usertrap>
    80002d0a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d0c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d0e:	8692                	mv	a3,tp
    80002d10:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d12:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d16:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d1a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d1e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d22:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d24:	6f18                	ld	a4,24(a4)
    80002d26:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d2a:	6928                	ld	a0,80(a0)
    80002d2c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d2e:	00004717          	auipc	a4,0x4
    80002d32:	36e70713          	addi	a4,a4,878 # 8000709c <userret>
    80002d36:	8f11                	sub	a4,a4,a2
    80002d38:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d3a:	577d                	li	a4,-1
    80002d3c:	177e                	slli	a4,a4,0x3f
    80002d3e:	8d59                	or	a0,a0,a4
    80002d40:	9782                	jalr	a5
}
    80002d42:	60a2                	ld	ra,8(sp)
    80002d44:	6402                	ld	s0,0(sp)
    80002d46:	0141                	addi	sp,sp,16
    80002d48:	8082                	ret

0000000080002d4a <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d4a:	1141                	addi	sp,sp,-16
    80002d4c:	e406                	sd	ra,8(sp)
    80002d4e:	e022                	sd	s0,0(sp)
    80002d50:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    80002d52:	0001a517          	auipc	a0,0x1a
    80002d56:	92e50513          	addi	a0,a0,-1746 # 8001c680 <tickslock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	e7c080e7          	jalr	-388(ra) # 80000bd6 <acquire>
  ticks++;
    80002d62:	00006717          	auipc	a4,0x6
    80002d66:	e3e70713          	addi	a4,a4,-450 # 80008ba0 <ticks>
    80002d6a:	431c                	lw	a5,0(a4)
    80002d6c:	2785                	addiw	a5,a5,1
    80002d6e:	c31c                	sw	a5,0(a4)
  update_time();
    80002d70:	00000097          	auipc	ra,0x0
    80002d74:	dba080e7          	jalr	-582(ra) # 80002b2a <update_time>

  struct proc *p = myproc();
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	e22080e7          	jalr	-478(ra) # 80001b9a <myproc>
  if(p && p->state == RUNNING) {
    80002d80:	c509                	beqz	a0,80002d8a <clockintr+0x40>
    80002d82:	4d18                	lw	a4,24(a0)
    80002d84:	4791                	li	a5,4
    80002d86:	02f70663          	beq	a4,a5,80002db2 <clockintr+0x68>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002d8a:	00006517          	auipc	a0,0x6
    80002d8e:	e1650513          	addi	a0,a0,-490 # 80008ba0 <ticks>
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	720080e7          	jalr	1824(ra) # 800024b2 <wakeup>
  release(&tickslock);
    80002d9a:	0001a517          	auipc	a0,0x1a
    80002d9e:	8e650513          	addi	a0,a0,-1818 # 8001c680 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ee8080e7          	jalr	-280(ra) # 80000c8a <release>
}
    80002daa:	60a2                	ld	ra,8(sp)
    80002dac:	6402                	ld	s0,0(sp)
    80002dae:	0141                	addi	sp,sp,16
    80002db0:	8082                	ret
    p->current_ticks++;
    80002db2:	28452783          	lw	a5,644(a0)
    80002db6:	2785                	addiw	a5,a5,1
    80002db8:	28f52223          	sw	a5,644(a0)
    80002dbc:	b7f9                	j	80002d8a <clockintr+0x40>

0000000080002dbe <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	e426                	sd	s1,8(sp)
    80002dc6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002dcc:	00074d63          	bltz	a4,80002de6 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002dd0:	57fd                	li	a5,-1
    80002dd2:	17fe                	slli	a5,a5,0x3f
    80002dd4:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002dd6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002dd8:	06f70363          	beq	a4,a5,80002e3e <devintr+0x80>
  }
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret
      (scause & 0xff) == 9)
    80002de6:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002dea:	46a5                	li	a3,9
    80002dec:	fed792e3          	bne	a5,a3,80002dd0 <devintr+0x12>
    int irq = plic_claim();
    80002df0:	00004097          	auipc	ra,0x4
    80002df4:	8f8080e7          	jalr	-1800(ra) # 800066e8 <plic_claim>
    80002df8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002dfa:	47a9                	li	a5,10
    80002dfc:	02f50763          	beq	a0,a5,80002e2a <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002e00:	4785                	li	a5,1
    80002e02:	02f50963          	beq	a0,a5,80002e34 <devintr+0x76>
    return 1;
    80002e06:	4505                	li	a0,1
    else if (irq)
    80002e08:	d8f1                	beqz	s1,80002ddc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e0a:	85a6                	mv	a1,s1
    80002e0c:	00005517          	auipc	a0,0x5
    80002e10:	52c50513          	addi	a0,a0,1324 # 80008338 <states.0+0x38>
    80002e14:	ffffd097          	auipc	ra,0xffffd
    80002e18:	774080e7          	jalr	1908(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e1c:	8526                	mv	a0,s1
    80002e1e:	00004097          	auipc	ra,0x4
    80002e22:	8ee080e7          	jalr	-1810(ra) # 8000670c <plic_complete>
    return 1;
    80002e26:	4505                	li	a0,1
    80002e28:	bf55                	j	80002ddc <devintr+0x1e>
      uartintr();
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	b70080e7          	jalr	-1168(ra) # 8000099a <uartintr>
    80002e32:	b7ed                	j	80002e1c <devintr+0x5e>
      virtio_disk_intr();
    80002e34:	00004097          	auipc	ra,0x4
    80002e38:	da4080e7          	jalr	-604(ra) # 80006bd8 <virtio_disk_intr>
    80002e3c:	b7c5                	j	80002e1c <devintr+0x5e>
    if (cpuid() == 0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	d30080e7          	jalr	-720(ra) # 80001b6e <cpuid>
    80002e46:	c901                	beqz	a0,80002e56 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e48:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e4e:	14479073          	csrw	sip,a5
    return 2;
    80002e52:	4509                	li	a0,2
    80002e54:	b761                	j	80002ddc <devintr+0x1e>
      clockintr();
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	ef4080e7          	jalr	-268(ra) # 80002d4a <clockintr>
    80002e5e:	b7ed                	j	80002e48 <devintr+0x8a>

0000000080002e60 <usertrap>:
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	e426                	sd	s1,8(sp)
    80002e68:	e04a                	sd	s2,0(sp)
    80002e6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e70:	1007f793          	andi	a5,a5,256
    80002e74:	efb9                	bnez	a5,80002ed2 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e76:	00003797          	auipc	a5,0x3
    80002e7a:	76a78793          	addi	a5,a5,1898 # 800065e0 <kernelvec>
    80002e7e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	d18080e7          	jalr	-744(ra) # 80001b9a <myproc>
    80002e8a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e8c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e8e:	14102773          	csrr	a4,sepc
    80002e92:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e94:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e98:	47a1                	li	a5,8
    80002e9a:	04f70463          	beq	a4,a5,80002ee2 <usertrap+0x82>
  else if ((which_dev = devintr()) != 0)
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	f20080e7          	jalr	-224(ra) # 80002dbe <devintr>
    80002ea6:	892a                	mv	s2,a0
    80002ea8:	c569                	beqz	a0,80002f72 <usertrap+0x112>
    if(which_dev == 2 && p->ticks_of_alarm > 0 && !p->alarm_status) {
    80002eaa:	4789                	li	a5,2
    80002eac:	04f51f63          	bne	a0,a5,80002f0a <usertrap+0xaa>
    80002eb0:	2804a783          	lw	a5,640(s1)
    80002eb4:	04f05b63          	blez	a5,80002f0a <usertrap+0xaa>
    80002eb8:	2904a703          	lw	a4,656(s1)
    80002ebc:	e739                	bnez	a4,80002f0a <usertrap+0xaa>
      p->current_ticks++;
    80002ebe:	2844a703          	lw	a4,644(s1)
    80002ec2:	2705                	addiw	a4,a4,1
    80002ec4:	0007069b          	sext.w	a3,a4
      if(p->current_ticks >= p->ticks_of_alarm) {
    80002ec8:	06f6de63          	bge	a3,a5,80002f44 <usertrap+0xe4>
      p->current_ticks++;
    80002ecc:	28e4a223          	sw	a4,644(s1)
    80002ed0:	a82d                	j	80002f0a <usertrap+0xaa>
    panic("usertrap: not from user mode");
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	48650513          	addi	a0,a0,1158 # 80008358 <states.0+0x58>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    if (killed(p))
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	820080e7          	jalr	-2016(ra) # 80002702 <killed>
    80002eea:	e539                	bnez	a0,80002f38 <usertrap+0xd8>
    p->trapframe->epc += 4;
    80002eec:	6cb8                	ld	a4,88(s1)
    80002eee:	6f1c                	ld	a5,24(a4)
    80002ef0:	0791                	addi	a5,a5,4
    80002ef2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ef8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002efc:	10079073          	csrw	sstatus,a5
    syscall();
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	44a080e7          	jalr	1098(ra) # 8000334a <syscall>
  int which_dev = 0;
    80002f08:	4901                	li	s2,0
  if (killed(p))
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	7f6080e7          	jalr	2038(ra) # 80002702 <killed>
    80002f14:	ed41                	bnez	a0,80002fac <usertrap+0x14c>
  int which_dev = 0;
    80002f16:	0000e797          	auipc	a5,0xe
    80002f1a:	32a78793          	addi	a5,a5,810 # 80011240 <proc>
    if(current_process_track->status_queue == 1 && current_process_track->state == RUNNABLE && current_process_track != 0) {
    80002f1e:	4f05                	li	t5,1
    80002f20:	4f8d                	li	t6,3
      if(current_process_track->wait_ticks >= 48) {
    80002f22:	02f00393          	li	t2,47
        for(newproc = queue[current_process_track->priority_queue_number].mlfq_queue[0];newproc < current_process_track;newproc++) {
    80002f26:	00019297          	auipc	t0,0x19
    80002f2a:	f1a28293          	addi	t0,t0,-230 # 8001be40 <queue>
  for(current_process_track = proc;current_process_track < &proc[NPROC];current_process_track++) {
    80002f2e:	00019e97          	auipc	t4,0x19
    80002f32:	f12e8e93          	addi	t4,t4,-238 # 8001be40 <queue>
    80002f36:	a079                	j	80002fc4 <usertrap+0x164>
      exit(-1);
    80002f38:	557d                	li	a0,-1
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	648080e7          	jalr	1608(ra) # 80002582 <exit>
    80002f42:	b76d                	j	80002eec <usertrap+0x8c>
        p->current_ticks = 0;
    80002f44:	2804a223          	sw	zero,644(s1)
        p->trapframe_alarm = kalloc();
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	b9e080e7          	jalr	-1122(ra) # 80000ae6 <kalloc>
    80002f50:	28a4b423          	sd	a0,648(s1)
        memmove(p->trapframe_alarm,p->trapframe,sizeof(struct trapframe));
    80002f54:	12000613          	li	a2,288
    80002f58:	6cac                	ld	a1,88(s1)
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	dd4080e7          	jalr	-556(ra) # 80000d2e <memmove>
        p->trapframe->epc = p->handling_alarm;
    80002f62:	6cbc                	ld	a5,88(s1)
    80002f64:	2784b703          	ld	a4,632(s1)
    80002f68:	ef98                	sd	a4,24(a5)
        p->alarm_status = 1;
    80002f6a:	4785                	li	a5,1
    80002f6c:	28f4a823          	sw	a5,656(s1)
    80002f70:	bf69                	j	80002f0a <usertrap+0xaa>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f76:	5890                	lw	a2,48(s1)
    80002f78:	00005517          	auipc	a0,0x5
    80002f7c:	40050513          	addi	a0,a0,1024 # 80008378 <states.0+0x78>
    80002f80:	ffffd097          	auipc	ra,0xffffd
    80002f84:	608080e7          	jalr	1544(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f90:	00005517          	auipc	a0,0x5
    80002f94:	41850513          	addi	a0,a0,1048 # 800083a8 <states.0+0xa8>
    80002f98:	ffffd097          	auipc	ra,0xffffd
    80002f9c:	5f0080e7          	jalr	1520(ra) # 80000588 <printf>
    setkilled(p);
    80002fa0:	8526                	mv	a0,s1
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	734080e7          	jalr	1844(ra) # 800026d6 <setkilled>
    80002faa:	b785                	j	80002f0a <usertrap+0xaa>
    exit(-1);
    80002fac:	557d                	li	a0,-1
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	5d4080e7          	jalr	1492(ra) # 80002582 <exit>
    80002fb6:	b785                	j	80002f16 <usertrap+0xb6>
        current_process_track->wait_ticks = 0;
    80002fb8:	2807ae23          	sw	zero,668(a5)
  for(current_process_track = proc;current_process_track < &proc[NPROC];current_process_track++) {
    80002fbc:	2b078793          	addi	a5,a5,688
    80002fc0:	0bd78f63          	beq	a5,t4,8000307e <usertrap+0x21e>
    if(current_process_track->status_queue == 1 && current_process_track->state == RUNNABLE && current_process_track != 0) {
    80002fc4:	2a07a703          	lw	a4,672(a5)
    80002fc8:	ffe71ae3          	bne	a4,t5,80002fbc <usertrap+0x15c>
    80002fcc:	4f98                	lw	a4,24(a5)
    80002fce:	fff717e3          	bne	a4,t6,80002fbc <usertrap+0x15c>
      if(current_process_track->wait_ticks >= 48) {
    80002fd2:	29c7a703          	lw	a4,668(a5)
    80002fd6:	fee3d3e3          	bge	t2,a4,80002fbc <usertrap+0x15c>
        current_process_track->status_queue = 0;
    80002fda:	2a07a023          	sw	zero,672(a5)
        for(newproc = queue[current_process_track->priority_queue_number].mlfq_queue[0];newproc < current_process_track;newproc++) {
    80002fde:	2947a683          	lw	a3,660(a5)
    80002fe2:	00569713          	slli	a4,a3,0x5
    80002fe6:	9736                	add	a4,a4,a3
    80002fe8:	0712                	slli	a4,a4,0x4
    80002fea:	9716                	add	a4,a4,t0
    80002fec:	6b10                	ld	a2,16(a4)
    80002fee:	00f67663          	bgeu	a2,a5,80002ffa <usertrap+0x19a>
    80002ff2:	2b060613          	addi	a2,a2,688
    80002ff6:	fef66ee3          	bltu	a2,a5,80002ff2 <usertrap+0x192>
        newproc = newproc + 1;
    80002ffa:	2b060613          	addi	a2,a2,688
        for(;newproc < queue[current_process_track->priority_queue_number].mlfq_queue[NPROC-1];newproc++) {
    80002ffe:	00569713          	slli	a4,a3,0x5
    80003002:	9736                	add	a4,a4,a3
    80003004:	0712                	slli	a4,a4,0x4
    80003006:	9716                	add	a4,a4,t0
    80003008:	20873703          	ld	a4,520(a4)
    8000300c:	04e67c63          	bgeu	a2,a4,80003064 <usertrap+0x204>
          *(newproc - 1) = *(newproc);
    80003010:	8732                	mv	a4,a2
    80003012:	d5060693          	addi	a3,a2,-688
    80003016:	2a860e13          	addi	t3,a2,680
    8000301a:	00073303          	ld	t1,0(a4)
    8000301e:	00873883          	ld	a7,8(a4)
    80003022:	01073803          	ld	a6,16(a4)
    80003026:	6f08                	ld	a0,24(a4)
    80003028:	730c                	ld	a1,32(a4)
    8000302a:	0066b023          	sd	t1,0(a3)
    8000302e:	0116b423          	sd	a7,8(a3)
    80003032:	0106b823          	sd	a6,16(a3)
    80003036:	ee88                	sd	a0,24(a3)
    80003038:	f28c                	sd	a1,32(a3)
    8000303a:	02870713          	addi	a4,a4,40
    8000303e:	02868693          	addi	a3,a3,40
    80003042:	fdc71ce3          	bne	a4,t3,8000301a <usertrap+0x1ba>
    80003046:	6318                	ld	a4,0(a4)
    80003048:	e298                	sd	a4,0(a3)
        for(;newproc < queue[current_process_track->priority_queue_number].mlfq_queue[NPROC-1];newproc++) {
    8000304a:	2b060613          	addi	a2,a2,688
    8000304e:	2947a683          	lw	a3,660(a5)
    80003052:	00569713          	slli	a4,a3,0x5
    80003056:	9736                	add	a4,a4,a3
    80003058:	0712                	slli	a4,a4,0x4
    8000305a:	9716                	add	a4,a4,t0
    8000305c:	20873703          	ld	a4,520(a4)
    80003060:	fae668e3          	bltu	a2,a4,80003010 <usertrap+0x1b0>
        queue[current_process_track->priority_queue_number].mlfq_queue[NPROC-1] = 0;
    80003064:	00569713          	slli	a4,a3,0x5
    80003068:	9736                	add	a4,a4,a3
    8000306a:	0712                	slli	a4,a4,0x4
    8000306c:	9716                	add	a4,a4,t0
    8000306e:	20073423          	sd	zero,520(a4)
        if(current_process_track->priority_queue_number > 0) {
    80003072:	f4d053e3          	blez	a3,80002fb8 <usertrap+0x158>
          current_process_track->priority_queue_number = current_process_track->priority_queue_number - 1;
    80003076:	36fd                	addiw	a3,a3,-1
    80003078:	28d7aa23          	sw	a3,660(a5)
    8000307c:	bf35                	j	80002fb8 <usertrap+0x158>
  if (which_dev == 2) {
    8000307e:	4789                	li	a5,2
    80003080:	00f90c63          	beq	s2,a5,80003098 <usertrap+0x238>
  usertrapret();
    80003084:	00000097          	auipc	ra,0x0
    80003088:	c30080e7          	jalr	-976(ra) # 80002cb4 <usertrapret>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6902                	ld	s2,0(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret
    if(p->start_time >= queue[p->priority_queue_number].priority_queue_ticks) {
    80003098:	2944a503          	lw	a0,660(s1)
    8000309c:	00551793          	slli	a5,a0,0x5
    800030a0:	97aa                	add	a5,a5,a0
    800030a2:	0792                	slli	a5,a5,0x4
    800030a4:	00019717          	auipc	a4,0x19
    800030a8:	d9c70713          	addi	a4,a4,-612 # 8001be40 <queue>
    800030ac:	97ba                	add	a5,a5,a4
    800030ae:	2984a703          	lw	a4,664(s1)
    800030b2:	47dc                	lw	a5,12(a5)
    800030b4:	02f74a63          	blt	a4,a5,800030e8 <usertrap+0x288>
      if(queue[p->priority_queue_number].tail > 0) {
    800030b8:	00551793          	slli	a5,a0,0x5
    800030bc:	97aa                	add	a5,a5,a0
    800030be:	0792                	slli	a5,a5,0x4
    800030c0:	00019717          	auipc	a4,0x19
    800030c4:	d8070713          	addi	a4,a4,-640 # 8001be40 <queue>
    800030c8:	97ba                	add	a5,a5,a4
    800030ca:	43dc                	lw	a5,4(a5)
    800030cc:	02f04363          	bgtz	a5,800030f2 <usertrap+0x292>
      if(p->priority_queue_number < queue_size-1) {
    800030d0:	2944a783          	lw	a5,660(s1)
    800030d4:	4709                	li	a4,2
    800030d6:	00f74563          	blt	a4,a5,800030e0 <usertrap+0x280>
        p->priority_queue_number = p->priority_queue_number + 1;
    800030da:	2785                	addiw	a5,a5,1
    800030dc:	28f4aa23          	sw	a5,660(s1)
      p->start_time = 0;
    800030e0:	2804ac23          	sw	zero,664(s1)
      p->wait_ticks = 0;
    800030e4:	2804ae23          	sw	zero,668(s1)
    yield();
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	322080e7          	jalr	802(ra) # 8000240a <yield>
    800030f0:	bf51                	j	80003084 <usertrap+0x224>
        pop(p->priority_queue_number);
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	8a2080e7          	jalr	-1886(ra) # 80001994 <pop>
        p->status_queue = 0;
    800030fa:	2a04a023          	sw	zero,672(s1)
    800030fe:	bfc9                	j	800030d0 <usertrap+0x270>

0000000080003100 <kerneltrap>:
{
    80003100:	7179                	addi	sp,sp,-48
    80003102:	f406                	sd	ra,40(sp)
    80003104:	f022                	sd	s0,32(sp)
    80003106:	ec26                	sd	s1,24(sp)
    80003108:	e84a                	sd	s2,16(sp)
    8000310a:	e44e                	sd	s3,8(sp)
    8000310c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000310e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003112:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003116:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    8000311a:	1004f793          	andi	a5,s1,256
    8000311e:	cb85                	beqz	a5,8000314e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003120:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003124:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80003126:	ef85                	bnez	a5,8000315e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	c96080e7          	jalr	-874(ra) # 80002dbe <devintr>
    80003130:	cd1d                	beqz	a0,8000316e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003132:	4789                	li	a5,2
    80003134:	06f50a63          	beq	a0,a5,800031a8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003138:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000313c:	10049073          	csrw	sstatus,s1
}
    80003140:	70a2                	ld	ra,40(sp)
    80003142:	7402                	ld	s0,32(sp)
    80003144:	64e2                	ld	s1,24(sp)
    80003146:	6942                	ld	s2,16(sp)
    80003148:	69a2                	ld	s3,8(sp)
    8000314a:	6145                	addi	sp,sp,48
    8000314c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	27a50513          	addi	a0,a0,634 # 800083c8 <states.0+0xc8>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3e8080e7          	jalr	1000(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	29250513          	addi	a0,a0,658 # 800083f0 <states.0+0xf0>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000316e:	85ce                	mv	a1,s3
    80003170:	00005517          	auipc	a0,0x5
    80003174:	2a050513          	addi	a0,a0,672 # 80008410 <states.0+0x110>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	410080e7          	jalr	1040(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003180:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003184:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	29850513          	addi	a0,a0,664 # 80008420 <states.0+0x120>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3f8080e7          	jalr	1016(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	2a050513          	addi	a0,a0,672 # 80008438 <states.0+0x138>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	39e080e7          	jalr	926(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	9f2080e7          	jalr	-1550(ra) # 80001b9a <myproc>
    800031b0:	d541                	beqz	a0,80003138 <kerneltrap+0x38>
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	9e8080e7          	jalr	-1560(ra) # 80001b9a <myproc>
    800031ba:	4d18                	lw	a4,24(a0)
    800031bc:	4791                	li	a5,4
    800031be:	f6f71de3          	bne	a4,a5,80003138 <kerneltrap+0x38>
    yield();
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	248080e7          	jalr	584(ra) # 8000240a <yield>
    800031ca:	b7bd                	j	80003138 <kerneltrap+0x38>

00000000800031cc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800031cc:	1101                	addi	sp,sp,-32
    800031ce:	ec06                	sd	ra,24(sp)
    800031d0:	e822                	sd	s0,16(sp)
    800031d2:	e426                	sd	s1,8(sp)
    800031d4:	1000                	addi	s0,sp,32
    800031d6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	9c2080e7          	jalr	-1598(ra) # 80001b9a <myproc>
  switch (n) {
    800031e0:	4795                	li	a5,5
    800031e2:	0497e163          	bltu	a5,s1,80003224 <argraw+0x58>
    800031e6:	048a                	slli	s1,s1,0x2
    800031e8:	00005717          	auipc	a4,0x5
    800031ec:	28870713          	addi	a4,a4,648 # 80008470 <states.0+0x170>
    800031f0:	94ba                	add	s1,s1,a4
    800031f2:	409c                	lw	a5,0(s1)
    800031f4:	97ba                	add	a5,a5,a4
    800031f6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031f8:	6d3c                	ld	a5,88(a0)
    800031fa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	64a2                	ld	s1,8(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret
    return p->trapframe->a1;
    80003206:	6d3c                	ld	a5,88(a0)
    80003208:	7fa8                	ld	a0,120(a5)
    8000320a:	bfcd                	j	800031fc <argraw+0x30>
    return p->trapframe->a2;
    8000320c:	6d3c                	ld	a5,88(a0)
    8000320e:	63c8                	ld	a0,128(a5)
    80003210:	b7f5                	j	800031fc <argraw+0x30>
    return p->trapframe->a3;
    80003212:	6d3c                	ld	a5,88(a0)
    80003214:	67c8                	ld	a0,136(a5)
    80003216:	b7dd                	j	800031fc <argraw+0x30>
    return p->trapframe->a4;
    80003218:	6d3c                	ld	a5,88(a0)
    8000321a:	6bc8                	ld	a0,144(a5)
    8000321c:	b7c5                	j	800031fc <argraw+0x30>
    return p->trapframe->a5;
    8000321e:	6d3c                	ld	a5,88(a0)
    80003220:	6fc8                	ld	a0,152(a5)
    80003222:	bfe9                	j	800031fc <argraw+0x30>
  panic("argraw");
    80003224:	00005517          	auipc	a0,0x5
    80003228:	22450513          	addi	a0,a0,548 # 80008448 <states.0+0x148>
    8000322c:	ffffd097          	auipc	ra,0xffffd
    80003230:	312080e7          	jalr	786(ra) # 8000053e <panic>

0000000080003234 <fetchaddr>:
{
    80003234:	1101                	addi	sp,sp,-32
    80003236:	ec06                	sd	ra,24(sp)
    80003238:	e822                	sd	s0,16(sp)
    8000323a:	e426                	sd	s1,8(sp)
    8000323c:	e04a                	sd	s2,0(sp)
    8000323e:	1000                	addi	s0,sp,32
    80003240:	84aa                	mv	s1,a0
    80003242:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	956080e7          	jalr	-1706(ra) # 80001b9a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000324c:	653c                	ld	a5,72(a0)
    8000324e:	02f4f863          	bgeu	s1,a5,8000327e <fetchaddr+0x4a>
    80003252:	00848713          	addi	a4,s1,8
    80003256:	02e7e663          	bltu	a5,a4,80003282 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000325a:	46a1                	li	a3,8
    8000325c:	8626                	mv	a2,s1
    8000325e:	85ca                	mv	a1,s2
    80003260:	6928                	ld	a0,80(a0)
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	492080e7          	jalr	1170(ra) # 800016f4 <copyin>
    8000326a:	00a03533          	snez	a0,a0
    8000326e:	40a00533          	neg	a0,a0
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6902                	ld	s2,0(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret
    return -1;
    8000327e:	557d                	li	a0,-1
    80003280:	bfcd                	j	80003272 <fetchaddr+0x3e>
    80003282:	557d                	li	a0,-1
    80003284:	b7fd                	j	80003272 <fetchaddr+0x3e>

0000000080003286 <fetchstr>:
{
    80003286:	7179                	addi	sp,sp,-48
    80003288:	f406                	sd	ra,40(sp)
    8000328a:	f022                	sd	s0,32(sp)
    8000328c:	ec26                	sd	s1,24(sp)
    8000328e:	e84a                	sd	s2,16(sp)
    80003290:	e44e                	sd	s3,8(sp)
    80003292:	1800                	addi	s0,sp,48
    80003294:	892a                	mv	s2,a0
    80003296:	84ae                	mv	s1,a1
    80003298:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000329a:	fffff097          	auipc	ra,0xfffff
    8000329e:	900080e7          	jalr	-1792(ra) # 80001b9a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800032a2:	86ce                	mv	a3,s3
    800032a4:	864a                	mv	a2,s2
    800032a6:	85a6                	mv	a1,s1
    800032a8:	6928                	ld	a0,80(a0)
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	4d8080e7          	jalr	1240(ra) # 80001782 <copyinstr>
    800032b2:	00054e63          	bltz	a0,800032ce <fetchstr+0x48>
  return strlen(buf);
    800032b6:	8526                	mv	a0,s1
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	b96080e7          	jalr	-1130(ra) # 80000e4e <strlen>
}
    800032c0:	70a2                	ld	ra,40(sp)
    800032c2:	7402                	ld	s0,32(sp)
    800032c4:	64e2                	ld	s1,24(sp)
    800032c6:	6942                	ld	s2,16(sp)
    800032c8:	69a2                	ld	s3,8(sp)
    800032ca:	6145                	addi	sp,sp,48
    800032cc:	8082                	ret
    return -1;
    800032ce:	557d                	li	a0,-1
    800032d0:	bfc5                	j	800032c0 <fetchstr+0x3a>

00000000800032d2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	e426                	sd	s1,8(sp)
    800032da:	1000                	addi	s0,sp,32
    800032dc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	eee080e7          	jalr	-274(ra) # 800031cc <argraw>
    800032e6:	c088                	sw	a0,0(s1)
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	ece080e7          	jalr	-306(ra) # 800031cc <argraw>
    80003306:	e088                	sd	a0,0(s1)
}
    80003308:	60e2                	ld	ra,24(sp)
    8000330a:	6442                	ld	s0,16(sp)
    8000330c:	64a2                	ld	s1,8(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003312:	7179                	addi	sp,sp,-48
    80003314:	f406                	sd	ra,40(sp)
    80003316:	f022                	sd	s0,32(sp)
    80003318:	ec26                	sd	s1,24(sp)
    8000331a:	e84a                	sd	s2,16(sp)
    8000331c:	1800                	addi	s0,sp,48
    8000331e:	84ae                	mv	s1,a1
    80003320:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003322:	fd840593          	addi	a1,s0,-40
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	fcc080e7          	jalr	-52(ra) # 800032f2 <argaddr>
  return fetchstr(addr, buf, max);
    8000332e:	864a                	mv	a2,s2
    80003330:	85a6                	mv	a1,s1
    80003332:	fd843503          	ld	a0,-40(s0)
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	f50080e7          	jalr	-176(ra) # 80003286 <fetchstr>
}
    8000333e:	70a2                	ld	ra,40(sp)
    80003340:	7402                	ld	s0,32(sp)
    80003342:	64e2                	ld	s1,24(sp)
    80003344:	6942                	ld	s2,16(sp)
    80003346:	6145                	addi	sp,sp,48
    80003348:	8082                	ret

000000008000334a <syscall>:
};


void
syscall(void)
{
    8000334a:	7179                	addi	sp,sp,-48
    8000334c:	f406                	sd	ra,40(sp)
    8000334e:	f022                	sd	s0,32(sp)
    80003350:	ec26                	sd	s1,24(sp)
    80003352:	e84a                	sd	s2,16(sp)
    80003354:	e44e                	sd	s3,8(sp)
    80003356:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	842080e7          	jalr	-1982(ra) # 80001b9a <myproc>
    80003360:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80003362:	05853983          	ld	s3,88(a0)
    80003366:	0a89b783          	ld	a5,168(s3)
    8000336a:	0007891b          	sext.w	s2,a5
  // printf("%d\n",num);
  // if(num >= 0 && num < 32) {
  //   p->sysCounter[num]++;
  //   // printf("Syscall number %d incremented. Total count: %d\n", num, p->sysCounter[num]);
  // }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {           
    8000336e:	37fd                	addiw	a5,a5,-1
    80003370:	4765                	li	a4,25
    80003372:	02f76663          	bltu	a4,a5,8000339e <syscall+0x54>
    80003376:	00391713          	slli	a4,s2,0x3
    8000337a:	00005797          	auipc	a5,0x5
    8000337e:	10e78793          	addi	a5,a5,270 # 80008488 <syscalls>
    80003382:	97ba                	add	a5,a5,a4
    80003384:	639c                	ld	a5,0(a5)
    80003386:	cf81                	beqz	a5,8000339e <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    // printf("Syscall %d called by PID %d\n", num, p->pid);
    p->trapframe->a0 = syscalls[num]();
    80003388:	9782                	jalr	a5
    8000338a:	06a9b823          	sd	a0,112(s3)
    p->sysCounter[num]++;
    8000338e:	090e                	slli	s2,s2,0x3
    80003390:	94ca                	add	s1,s1,s2
    80003392:	1784b783          	ld	a5,376(s1)
    80003396:	0785                	addi	a5,a5,1
    80003398:	16f4bc23          	sd	a5,376(s1)
    8000339c:	a005                	j	800033bc <syscall+0x72>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000339e:	86ca                	mv	a3,s2
    800033a0:	15848613          	addi	a2,s1,344
    800033a4:	588c                	lw	a1,48(s1)
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	0aa50513          	addi	a0,a0,170 # 80008450 <states.0+0x150>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	1da080e7          	jalr	474(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800033b6:	6cbc                	ld	a5,88(s1)
    800033b8:	577d                	li	a4,-1
    800033ba:	fbb8                	sd	a4,112(a5)
  }
}
    800033bc:	70a2                	ld	ra,40(sp)
    800033be:	7402                	ld	s0,32(sp)
    800033c0:	64e2                	ld	s1,24(sp)
    800033c2:	6942                	ld	s2,16(sp)
    800033c4:	69a2                	ld	s3,8(sp)
    800033c6:	6145                	addi	sp,sp,48
    800033c8:	8082                	ret

00000000800033ca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800033d2:	fec40593          	addi	a1,s0,-20
    800033d6:	4501                	li	a0,0
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	efa080e7          	jalr	-262(ra) # 800032d2 <argint>
  exit(n);
    800033e0:	fec42503          	lw	a0,-20(s0)
    800033e4:	fffff097          	auipc	ra,0xfffff
    800033e8:	19e080e7          	jalr	414(ra) # 80002582 <exit>
  return 0; // not reached
}
    800033ec:	4501                	li	a0,0
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	6105                	addi	sp,sp,32
    800033f4:	8082                	ret

00000000800033f6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033f6:	1141                	addi	sp,sp,-16
    800033f8:	e406                	sd	ra,8(sp)
    800033fa:	e022                	sd	s0,0(sp)
    800033fc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	79c080e7          	jalr	1948(ra) # 80001b9a <myproc>
}
    80003406:	5908                	lw	a0,48(a0)
    80003408:	60a2                	ld	ra,8(sp)
    8000340a:	6402                	ld	s0,0(sp)
    8000340c:	0141                	addi	sp,sp,16
    8000340e:	8082                	ret

0000000080003410 <sys_fork>:

uint64
sys_fork(void)
{
    80003410:	1141                	addi	sp,sp,-16
    80003412:	e406                	sd	ra,8(sp)
    80003414:	e022                	sd	s0,0(sp)
    80003416:	0800                	addi	s0,sp,16
  return fork();
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	bdc080e7          	jalr	-1060(ra) # 80001ff4 <fork>
}
    80003420:	60a2                	ld	ra,8(sp)
    80003422:	6402                	ld	s0,0(sp)
    80003424:	0141                	addi	sp,sp,16
    80003426:	8082                	ret

0000000080003428 <sys_wait>:

uint64
sys_wait(void)
{
    80003428:	1101                	addi	sp,sp,-32
    8000342a:	ec06                	sd	ra,24(sp)
    8000342c:	e822                	sd	s0,16(sp)
    8000342e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003430:	fe840593          	addi	a1,s0,-24
    80003434:	4501                	li	a0,0
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	ebc080e7          	jalr	-324(ra) # 800032f2 <argaddr>
  return wait(p);
    8000343e:	fe843503          	ld	a0,-24(s0)
    80003442:	fffff097          	auipc	ra,0xfffff
    80003446:	2f2080e7          	jalr	754(ra) # 80002734 <wait>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	6105                	addi	sp,sp,32
    80003450:	8082                	ret

0000000080003452 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	ec26                	sd	s1,24(sp)
    8000345a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000345c:	fdc40593          	addi	a1,s0,-36
    80003460:	4501                	li	a0,0
    80003462:	00000097          	auipc	ra,0x0
    80003466:	e70080e7          	jalr	-400(ra) # 800032d2 <argint>
  addr = myproc()->sz;
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	730080e7          	jalr	1840(ra) # 80001b9a <myproc>
    80003472:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003474:	fdc42503          	lw	a0,-36(s0)
    80003478:	fffff097          	auipc	ra,0xfffff
    8000347c:	b20080e7          	jalr	-1248(ra) # 80001f98 <growproc>
    80003480:	00054863          	bltz	a0,80003490 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003484:	8526                	mv	a0,s1
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6145                	addi	sp,sp,48
    8000348e:	8082                	ret
    return -1;
    80003490:	54fd                	li	s1,-1
    80003492:	bfcd                	j	80003484 <sys_sbrk+0x32>

0000000080003494 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003494:	7139                	addi	sp,sp,-64
    80003496:	fc06                	sd	ra,56(sp)
    80003498:	f822                	sd	s0,48(sp)
    8000349a:	f426                	sd	s1,40(sp)
    8000349c:	f04a                	sd	s2,32(sp)
    8000349e:	ec4e                	sd	s3,24(sp)
    800034a0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800034a2:	fcc40593          	addi	a1,s0,-52
    800034a6:	4501                	li	a0,0
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	e2a080e7          	jalr	-470(ra) # 800032d2 <argint>
  acquire(&tickslock);
    800034b0:	00019517          	auipc	a0,0x19
    800034b4:	1d050513          	addi	a0,a0,464 # 8001c680 <tickslock>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	71e080e7          	jalr	1822(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800034c0:	00005917          	auipc	s2,0x5
    800034c4:	6e092903          	lw	s2,1760(s2) # 80008ba0 <ticks>
  while (ticks - ticks0 < n)
    800034c8:	fcc42783          	lw	a5,-52(s0)
    800034cc:	cf9d                	beqz	a5,8000350a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034ce:	00019997          	auipc	s3,0x19
    800034d2:	1b298993          	addi	s3,s3,434 # 8001c680 <tickslock>
    800034d6:	00005497          	auipc	s1,0x5
    800034da:	6ca48493          	addi	s1,s1,1738 # 80008ba0 <ticks>
    if (killed(myproc()))
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	6bc080e7          	jalr	1724(ra) # 80001b9a <myproc>
    800034e6:	fffff097          	auipc	ra,0xfffff
    800034ea:	21c080e7          	jalr	540(ra) # 80002702 <killed>
    800034ee:	ed15                	bnez	a0,8000352a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800034f0:	85ce                	mv	a1,s3
    800034f2:	8526                	mv	a0,s1
    800034f4:	fffff097          	auipc	ra,0xfffff
    800034f8:	f5a080e7          	jalr	-166(ra) # 8000244e <sleep>
  while (ticks - ticks0 < n)
    800034fc:	409c                	lw	a5,0(s1)
    800034fe:	412787bb          	subw	a5,a5,s2
    80003502:	fcc42703          	lw	a4,-52(s0)
    80003506:	fce7ece3          	bltu	a5,a4,800034de <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000350a:	00019517          	auipc	a0,0x19
    8000350e:	17650513          	addi	a0,a0,374 # 8001c680 <tickslock>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	778080e7          	jalr	1912(ra) # 80000c8a <release>
  return 0;
    8000351a:	4501                	li	a0,0
}
    8000351c:	70e2                	ld	ra,56(sp)
    8000351e:	7442                	ld	s0,48(sp)
    80003520:	74a2                	ld	s1,40(sp)
    80003522:	7902                	ld	s2,32(sp)
    80003524:	69e2                	ld	s3,24(sp)
    80003526:	6121                	addi	sp,sp,64
    80003528:	8082                	ret
      release(&tickslock);
    8000352a:	00019517          	auipc	a0,0x19
    8000352e:	15650513          	addi	a0,a0,342 # 8001c680 <tickslock>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	758080e7          	jalr	1880(ra) # 80000c8a <release>
      return -1;
    8000353a:	557d                	li	a0,-1
    8000353c:	b7c5                	j	8000351c <sys_sleep+0x88>

000000008000353e <sys_kill>:

uint64
sys_kill(void)
{
    8000353e:	1101                	addi	sp,sp,-32
    80003540:	ec06                	sd	ra,24(sp)
    80003542:	e822                	sd	s0,16(sp)
    80003544:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003546:	fec40593          	addi	a1,s0,-20
    8000354a:	4501                	li	a0,0
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	d86080e7          	jalr	-634(ra) # 800032d2 <argint>
  return kill(pid);
    80003554:	fec42503          	lw	a0,-20(s0)
    80003558:	fffff097          	auipc	ra,0xfffff
    8000355c:	10c080e7          	jalr	268(ra) # 80002664 <kill>
}
    80003560:	60e2                	ld	ra,24(sp)
    80003562:	6442                	ld	s0,16(sp)
    80003564:	6105                	addi	sp,sp,32
    80003566:	8082                	ret

0000000080003568 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003568:	1101                	addi	sp,sp,-32
    8000356a:	ec06                	sd	ra,24(sp)
    8000356c:	e822                	sd	s0,16(sp)
    8000356e:	e426                	sd	s1,8(sp)
    80003570:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003572:	00019517          	auipc	a0,0x19
    80003576:	10e50513          	addi	a0,a0,270 # 8001c680 <tickslock>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	65c080e7          	jalr	1628(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003582:	00005497          	auipc	s1,0x5
    80003586:	61e4a483          	lw	s1,1566(s1) # 80008ba0 <ticks>
  release(&tickslock);
    8000358a:	00019517          	auipc	a0,0x19
    8000358e:	0f650513          	addi	a0,a0,246 # 8001c680 <tickslock>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	6f8080e7          	jalr	1784(ra) # 80000c8a <release>
  return xticks;
}
    8000359a:	02049513          	slli	a0,s1,0x20
    8000359e:	9101                	srli	a0,a0,0x20
    800035a0:	60e2                	ld	ra,24(sp)
    800035a2:	6442                	ld	s0,16(sp)
    800035a4:	64a2                	ld	s1,8(sp)
    800035a6:	6105                	addi	sp,sp,32
    800035a8:	8082                	ret

00000000800035aa <sys_waitx>:

uint64
sys_waitx(void)
{
    800035aa:	7139                	addi	sp,sp,-64
    800035ac:	fc06                	sd	ra,56(sp)
    800035ae:	f822                	sd	s0,48(sp)
    800035b0:	f426                	sd	s1,40(sp)
    800035b2:	f04a                	sd	s2,32(sp)
    800035b4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800035b6:	fd840593          	addi	a1,s0,-40
    800035ba:	4501                	li	a0,0
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	d36080e7          	jalr	-714(ra) # 800032f2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800035c4:	fd040593          	addi	a1,s0,-48
    800035c8:	4505                	li	a0,1
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	d28080e7          	jalr	-728(ra) # 800032f2 <argaddr>
  argaddr(2, &addr2);
    800035d2:	fc840593          	addi	a1,s0,-56
    800035d6:	4509                	li	a0,2
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	d1a080e7          	jalr	-742(ra) # 800032f2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800035e0:	fc040613          	addi	a2,s0,-64
    800035e4:	fc440593          	addi	a1,s0,-60
    800035e8:	fd843503          	ld	a0,-40(s0)
    800035ec:	fffff097          	auipc	ra,0xfffff
    800035f0:	3f2080e7          	jalr	1010(ra) # 800029de <waitx>
    800035f4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800035f6:	ffffe097          	auipc	ra,0xffffe
    800035fa:	5a4080e7          	jalr	1444(ra) # 80001b9a <myproc>
    800035fe:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003600:	4691                	li	a3,4
    80003602:	fc440613          	addi	a2,s0,-60
    80003606:	fd043583          	ld	a1,-48(s0)
    8000360a:	6928                	ld	a0,80(a0)
    8000360c:	ffffe097          	auipc	ra,0xffffe
    80003610:	05c080e7          	jalr	92(ra) # 80001668 <copyout>
    return -1;
    80003614:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003616:	00054f63          	bltz	a0,80003634 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000361a:	4691                	li	a3,4
    8000361c:	fc040613          	addi	a2,s0,-64
    80003620:	fc843583          	ld	a1,-56(s0)
    80003624:	68a8                	ld	a0,80(s1)
    80003626:	ffffe097          	auipc	ra,0xffffe
    8000362a:	042080e7          	jalr	66(ra) # 80001668 <copyout>
    8000362e:	00054a63          	bltz	a0,80003642 <sys_waitx+0x98>
    return -1;
  return ret;
    80003632:	87ca                	mv	a5,s2
}
    80003634:	853e                	mv	a0,a5
    80003636:	70e2                	ld	ra,56(sp)
    80003638:	7442                	ld	s0,48(sp)
    8000363a:	74a2                	ld	s1,40(sp)
    8000363c:	7902                	ld	s2,32(sp)
    8000363e:	6121                	addi	sp,sp,64
    80003640:	8082                	ret
    return -1;
    80003642:	57fd                	li	a5,-1
    80003644:	bfc5                	j	80003634 <sys_waitx+0x8a>

0000000080003646 <sys_getSysCount>:

//     return 0;
// }

uint64
sys_getSysCount(void) {
    80003646:	711d                	addi	sp,sp,-96
    80003648:	ec86                	sd	ra,88(sp)
    8000364a:	e8a2                	sd	s0,80(sp)
    8000364c:	e4a6                	sd	s1,72(sp)
    8000364e:	e0ca                	sd	s2,64(sp)
    80003650:	fc4e                	sd	s3,56(sp)
    80003652:	f852                	sd	s4,48(sp)
    80003654:	f456                	sd	s5,40(sp)
    80003656:	f05a                	sd	s6,32(sp)
    80003658:	ec5e                	sd	s7,24(sp)
    8000365a:	e862                	sd	s8,16(sp)
    8000365c:	1080                	addi	s0,sp,96
  // printf("In getsyscount\n");
  int mask;
  struct proc *my_proc = myproc();
    8000365e:	ffffe097          	auipc	ra,0xffffe
    80003662:	53c080e7          	jalr	1340(ra) # 80001b9a <myproc>
    80003666:	89aa                	mv	s3,a0
  argint(0,&mask);
    80003668:	fac40593          	addi	a1,s0,-84
    8000366c:	4501                	li	a0,0
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	c64080e7          	jalr	-924(ra) # 800032d2 <argint>

  int index = 0;
  // int new_mask = mask;
  for(int i=0;i<32;i++) {
    if(mask == (1 << i)) {
    80003676:	fac42683          	lw	a3,-84(s0)
  for(int i=0;i<32;i++) {
    8000367a:	4a81                	li	s5,0
    if(mask == (1 << i)) {
    8000367c:	4705                	li	a4,1
  for(int i=0;i<32;i++) {
    8000367e:	02000613          	li	a2,32
    if(mask == (1 << i)) {
    80003682:	015717bb          	sllw	a5,a4,s5
    80003686:	00d78663          	beq	a5,a3,80003692 <sys_getSysCount+0x4c>
  for(int i=0;i<32;i++) {
    8000368a:	2a85                	addiw	s5,s5,1
    8000368c:	feca9be3          	bne	s5,a2,80003682 <sys_getSysCount+0x3c>
  int index = 0;
    80003690:	4a81                	li	s5,0
      index = i;
      break;
    }
  }

  int counter_in_total = my_proc->sysCounter[index];
    80003692:	02ea8793          	addi	a5,s5,46
    80003696:	078e                	slli	a5,a5,0x3
    80003698:	97ce                	add	a5,a5,s3
    8000369a:	0087ab03          	lw	s6,8(a5)

  printf("Parent process (PID %d) syscall count : %d\n",my_proc->pid,counter_in_total);
    8000369e:	865a                	mv	a2,s6
    800036a0:	0309a583          	lw	a1,48(s3)
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	ebc50513          	addi	a0,a0,-324 # 80008560 <syscalls+0xd8>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	edc080e7          	jalr	-292(ra) # 80000588 <printf>
  acquire(&proc->lock);
    800036b4:	0000e517          	auipc	a0,0xe
    800036b8:	b8c50513          	addi	a0,a0,-1140 # 80011240 <proc>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	51a080e7          	jalr	1306(ra) # 80000bd6 <acquire>
  for(int i=0;i<NPROC;i++) {
    800036c4:	0000e497          	auipc	s1,0xe
    800036c8:	b9448493          	addi	s1,s1,-1132 # 80011258 <proc+0x18>
    800036cc:	02fa8913          	addi	s2,s5,47
    800036d0:	090e                	slli	s2,s2,0x3
    800036d2:	0000e797          	auipc	a5,0xe
    800036d6:	b6e78793          	addi	a5,a5,-1170 # 80011240 <proc>
    800036da:	993e                	add	s2,s2,a5
    800036dc:	00018a17          	auipc	s4,0x18
    800036e0:	77ca0a13          	addi	s4,s4,1916 # 8001be58 <queue+0x18>
    // printf("Entered\n");
    struct proc *child = &proc[i];
    struct proc *child_proc = child;

    if(child_proc->parent == my_proc && child_proc->state == ZOMBIE) {
    800036e4:	4b95                	li	s7,5
      printf("There is a child process with (PID %d) with syscount %d\n",child_proc->pid,child_proc->sysCounter[index]);
    800036e6:	00005c17          	auipc	s8,0x5
    800036ea:	eaac0c13          	addi	s8,s8,-342 # 80008590 <syscalls+0x108>
    800036ee:	a039                	j	800036fc <sys_getSysCount+0xb6>
  for(int i=0;i<NPROC;i++) {
    800036f0:	2b048493          	addi	s1,s1,688
    800036f4:	2b090913          	addi	s2,s2,688
    800036f8:	03448563          	beq	s1,s4,80003722 <sys_getSysCount+0xdc>
    if(child_proc->parent == my_proc && child_proc->state == ZOMBIE) {
    800036fc:	709c                	ld	a5,32(s1)
    800036fe:	ff3799e3          	bne	a5,s3,800036f0 <sys_getSysCount+0xaa>
    80003702:	409c                	lw	a5,0(s1)
    80003704:	ff7796e3          	bne	a5,s7,800036f0 <sys_getSysCount+0xaa>
      printf("There is a child process with (PID %d) with syscount %d\n",child_proc->pid,child_proc->sysCounter[index]);
    80003708:	00093603          	ld	a2,0(s2)
    8000370c:	4c8c                	lw	a1,24(s1)
    8000370e:	8562                	mv	a0,s8
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e78080e7          	jalr	-392(ra) # 80000588 <printf>
      counter_in_total += child_proc->sysCounter[index];
    80003718:	00093783          	ld	a5,0(s2)
    8000371c:	01678b3b          	addw	s6,a5,s6
    80003720:	bfc1                	j	800036f0 <sys_getSysCount+0xaa>
    }
  }

  for(int i=0;i<32;i++) {
    80003722:	17898913          	addi	s2,s3,376
    80003726:	4481                	li	s1,0
    printf("In sysproc.c syscall %d called %d times.\n",i,my_proc->sysCounter[i]);
    80003728:	00005b97          	auipc	s7,0x5
    8000372c:	ea8b8b93          	addi	s7,s7,-344 # 800085d0 <syscalls+0x148>
  for(int i=0;i<32;i++) {
    80003730:	02000a13          	li	s4,32
    printf("In sysproc.c syscall %d called %d times.\n",i,my_proc->sysCounter[i]);
    80003734:	00093603          	ld	a2,0(s2)
    80003738:	85a6                	mv	a1,s1
    8000373a:	855e                	mv	a0,s7
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	e4c080e7          	jalr	-436(ra) # 80000588 <printf>
  for(int i=0;i<32;i++) {
    80003744:	2485                	addiw	s1,s1,1
    80003746:	0921                	addi	s2,s2,8
    80003748:	ff4496e3          	bne	s1,s4,80003734 <sys_getSysCount+0xee>
  }
  release(&proc->lock);
    8000374c:	0000e517          	auipc	a0,0xe
    80003750:	af450513          	addi	a0,a0,-1292 # 80011240 <proc>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	536080e7          	jalr	1334(ra) # 80000c8a <release>
  printf("PID %d called %s %d times.\n",my_proc->pid,syscall_names[index],counter_in_total);
    8000375c:	0a8e                	slli	s5,s5,0x3
    8000375e:	00005797          	auipc	a5,0x5
    80003762:	33a78793          	addi	a5,a5,826 # 80008a98 <syscall_names>
    80003766:	9abe                	add	s5,s5,a5
    80003768:	86da                	mv	a3,s6
    8000376a:	000ab603          	ld	a2,0(s5)
    8000376e:	0309a583          	lw	a1,48(s3)
    80003772:	00005517          	auipc	a0,0x5
    80003776:	e8e50513          	addi	a0,a0,-370 # 80008600 <syscalls+0x178>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	e0e080e7          	jalr	-498(ra) # 80000588 <printf>
  return 0;
}
    80003782:	4501                	li	a0,0
    80003784:	60e6                	ld	ra,88(sp)
    80003786:	6446                	ld	s0,80(sp)
    80003788:	64a6                	ld	s1,72(sp)
    8000378a:	6906                	ld	s2,64(sp)
    8000378c:	79e2                	ld	s3,56(sp)
    8000378e:	7a42                	ld	s4,48(sp)
    80003790:	7aa2                	ld	s5,40(sp)
    80003792:	7b02                	ld	s6,32(sp)
    80003794:	6be2                	ld	s7,24(sp)
    80003796:	6c42                	ld	s8,16(sp)
    80003798:	6125                	addi	sp,sp,96
    8000379a:	8082                	ret

000000008000379c <sys_sigalarm>:

uint64
sys_sigalarm(void) {
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks_sigalarm;

  argint(0,&ticks_sigalarm);
    800037a4:	fe440593          	addi	a1,s0,-28
    800037a8:	4501                	li	a0,0
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	b28080e7          	jalr	-1240(ra) # 800032d2 <argint>
  argaddr(1,&addr);
    800037b2:	fe840593          	addi	a1,s0,-24
    800037b6:	4505                	li	a0,1
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	b3a080e7          	jalr	-1222(ra) # 800032f2 <argaddr>
  struct proc *p = myproc();
    800037c0:	ffffe097          	auipc	ra,0xffffe
    800037c4:	3da080e7          	jalr	986(ra) # 80001b9a <myproc>

  p->ticks_of_alarm = ticks_sigalarm;
    800037c8:	fe442783          	lw	a5,-28(s0)
    800037cc:	28f52023          	sw	a5,640(a0)
  p->handling_alarm = addr;
    800037d0:	fe843703          	ld	a4,-24(s0)
    800037d4:	26e53c23          	sd	a4,632(a0)
  if(ticks_sigalarm == 1) {
    800037d8:	4705                	li	a4,1
    800037da:	00e78763          	beq	a5,a4,800037e8 <sys_sigalarm+0x4c>
    p->ticks_of_alarm = 0;
  }
  // p->ticks_of_alarm = 0;

  return 0;
}
    800037de:	4501                	li	a0,0
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret
    p->ticks_of_alarm = 0;
    800037e8:	28052023          	sw	zero,640(a0)
    800037ec:	bfcd                	j	800037de <sys_sigalarm+0x42>

00000000800037ee <sys_sigreturn>:

uint64
sys_sigreturn(void) {
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800037f8:	ffffe097          	auipc	ra,0xffffe
    800037fc:	3a2080e7          	jalr	930(ra) # 80001b9a <myproc>
  if(p->trapframe_alarm) {
    80003800:	28853583          	ld	a1,648(a0)
    80003804:	c19d                	beqz	a1,8000382a <sys_sigreturn+0x3c>
    80003806:	84aa                	mv	s1,a0
    memmove(p->trapframe,p->trapframe_alarm,sizeof(struct trapframe));
    80003808:	12000613          	li	a2,288
    8000380c:	6d28                	ld	a0,88(a0)
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	520080e7          	jalr	1312(ra) # 80000d2e <memmove>
    kfree(p->trapframe_alarm);
    80003816:	2884b503          	ld	a0,648(s1)
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	1d0080e7          	jalr	464(ra) # 800009ea <kfree>
    p->trapframe_alarm = 0;
    80003822:	2804b423          	sd	zero,648(s1)
    p->alarm_status = 0;
    80003826:	2804a823          	sw	zero,656(s1)
    // p->cur_ticks = 0;
  }
  // p->alarm_on = 0;
  return 0;
}
    8000382a:	4501                	li	a0,0
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret

0000000080003836 <sys_settickets>:

uint64
sys_settickets(void) {
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	1000                	addi	s0,sp,32
  int number;
  argint(0,&number);
    8000383e:	fec40593          	addi	a1,s0,-20
    80003842:	4501                	li	a0,0
    80003844:	00000097          	auipc	ra,0x0
    80003848:	a8e080e7          	jalr	-1394(ra) # 800032d2 <argint>
  return settickets(number);
    8000384c:	fec42503          	lw	a0,-20(s0)
    80003850:	fffff097          	auipc	ra,0xfffff
    80003854:	342080e7          	jalr	834(ra) # 80002b92 <settickets>
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret

0000000080003860 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003860:	7179                	addi	sp,sp,-48
    80003862:	f406                	sd	ra,40(sp)
    80003864:	f022                	sd	s0,32(sp)
    80003866:	ec26                	sd	s1,24(sp)
    80003868:	e84a                	sd	s2,16(sp)
    8000386a:	e44e                	sd	s3,8(sp)
    8000386c:	e052                	sd	s4,0(sp)
    8000386e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003870:	00005597          	auipc	a1,0x5
    80003874:	e9058593          	addi	a1,a1,-368 # 80008700 <syscalls+0x278>
    80003878:	00019517          	auipc	a0,0x19
    8000387c:	e2050513          	addi	a0,a0,-480 # 8001c698 <bcache>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	2c6080e7          	jalr	710(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003888:	00021797          	auipc	a5,0x21
    8000388c:	e1078793          	addi	a5,a5,-496 # 80024698 <bcache+0x8000>
    80003890:	00021717          	auipc	a4,0x21
    80003894:	07070713          	addi	a4,a4,112 # 80024900 <bcache+0x8268>
    80003898:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000389c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038a0:	00019497          	auipc	s1,0x19
    800038a4:	e1048493          	addi	s1,s1,-496 # 8001c6b0 <bcache+0x18>
    b->next = bcache.head.next;
    800038a8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800038aa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800038ac:	00005a17          	auipc	s4,0x5
    800038b0:	e5ca0a13          	addi	s4,s4,-420 # 80008708 <syscalls+0x280>
    b->next = bcache.head.next;
    800038b4:	2b893783          	ld	a5,696(s2)
    800038b8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800038ba:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800038be:	85d2                	mv	a1,s4
    800038c0:	01048513          	addi	a0,s1,16
    800038c4:	00001097          	auipc	ra,0x1
    800038c8:	4c4080e7          	jalr	1220(ra) # 80004d88 <initsleeplock>
    bcache.head.next->prev = b;
    800038cc:	2b893783          	ld	a5,696(s2)
    800038d0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800038d2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038d6:	45848493          	addi	s1,s1,1112
    800038da:	fd349de3          	bne	s1,s3,800038b4 <binit+0x54>
  }
}
    800038de:	70a2                	ld	ra,40(sp)
    800038e0:	7402                	ld	s0,32(sp)
    800038e2:	64e2                	ld	s1,24(sp)
    800038e4:	6942                	ld	s2,16(sp)
    800038e6:	69a2                	ld	s3,8(sp)
    800038e8:	6a02                	ld	s4,0(sp)
    800038ea:	6145                	addi	sp,sp,48
    800038ec:	8082                	ret

00000000800038ee <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	e84a                	sd	s2,16(sp)
    800038f8:	e44e                	sd	s3,8(sp)
    800038fa:	1800                	addi	s0,sp,48
    800038fc:	892a                	mv	s2,a0
    800038fe:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003900:	00019517          	auipc	a0,0x19
    80003904:	d9850513          	addi	a0,a0,-616 # 8001c698 <bcache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	2ce080e7          	jalr	718(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003910:	00021497          	auipc	s1,0x21
    80003914:	0404b483          	ld	s1,64(s1) # 80024950 <bcache+0x82b8>
    80003918:	00021797          	auipc	a5,0x21
    8000391c:	fe878793          	addi	a5,a5,-24 # 80024900 <bcache+0x8268>
    80003920:	02f48f63          	beq	s1,a5,8000395e <bread+0x70>
    80003924:	873e                	mv	a4,a5
    80003926:	a021                	j	8000392e <bread+0x40>
    80003928:	68a4                	ld	s1,80(s1)
    8000392a:	02e48a63          	beq	s1,a4,8000395e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000392e:	449c                	lw	a5,8(s1)
    80003930:	ff279ce3          	bne	a5,s2,80003928 <bread+0x3a>
    80003934:	44dc                	lw	a5,12(s1)
    80003936:	ff3799e3          	bne	a5,s3,80003928 <bread+0x3a>
      b->refcnt++;
    8000393a:	40bc                	lw	a5,64(s1)
    8000393c:	2785                	addiw	a5,a5,1
    8000393e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003940:	00019517          	auipc	a0,0x19
    80003944:	d5850513          	addi	a0,a0,-680 # 8001c698 <bcache>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	342080e7          	jalr	834(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003950:	01048513          	addi	a0,s1,16
    80003954:	00001097          	auipc	ra,0x1
    80003958:	46e080e7          	jalr	1134(ra) # 80004dc2 <acquiresleep>
      return b;
    8000395c:	a8b9                	j	800039ba <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000395e:	00021497          	auipc	s1,0x21
    80003962:	fea4b483          	ld	s1,-22(s1) # 80024948 <bcache+0x82b0>
    80003966:	00021797          	auipc	a5,0x21
    8000396a:	f9a78793          	addi	a5,a5,-102 # 80024900 <bcache+0x8268>
    8000396e:	00f48863          	beq	s1,a5,8000397e <bread+0x90>
    80003972:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003974:	40bc                	lw	a5,64(s1)
    80003976:	cf81                	beqz	a5,8000398e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003978:	64a4                	ld	s1,72(s1)
    8000397a:	fee49de3          	bne	s1,a4,80003974 <bread+0x86>
  panic("bget: no buffers");
    8000397e:	00005517          	auipc	a0,0x5
    80003982:	d9250513          	addi	a0,a0,-622 # 80008710 <syscalls+0x288>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
      b->dev = dev;
    8000398e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003992:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003996:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000399a:	4785                	li	a5,1
    8000399c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000399e:	00019517          	auipc	a0,0x19
    800039a2:	cfa50513          	addi	a0,a0,-774 # 8001c698 <bcache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	2e4080e7          	jalr	740(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800039ae:	01048513          	addi	a0,s1,16
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	410080e7          	jalr	1040(ra) # 80004dc2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800039ba:	409c                	lw	a5,0(s1)
    800039bc:	cb89                	beqz	a5,800039ce <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800039be:	8526                	mv	a0,s1
    800039c0:	70a2                	ld	ra,40(sp)
    800039c2:	7402                	ld	s0,32(sp)
    800039c4:	64e2                	ld	s1,24(sp)
    800039c6:	6942                	ld	s2,16(sp)
    800039c8:	69a2                	ld	s3,8(sp)
    800039ca:	6145                	addi	sp,sp,48
    800039cc:	8082                	ret
    virtio_disk_rw(b, 0);
    800039ce:	4581                	li	a1,0
    800039d0:	8526                	mv	a0,s1
    800039d2:	00003097          	auipc	ra,0x3
    800039d6:	fd2080e7          	jalr	-46(ra) # 800069a4 <virtio_disk_rw>
    b->valid = 1;
    800039da:	4785                	li	a5,1
    800039dc:	c09c                	sw	a5,0(s1)
  return b;
    800039de:	b7c5                	j	800039be <bread+0xd0>

00000000800039e0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	1000                	addi	s0,sp,32
    800039ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039ec:	0541                	addi	a0,a0,16
    800039ee:	00001097          	auipc	ra,0x1
    800039f2:	46e080e7          	jalr	1134(ra) # 80004e5c <holdingsleep>
    800039f6:	cd01                	beqz	a0,80003a0e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800039f8:	4585                	li	a1,1
    800039fa:	8526                	mv	a0,s1
    800039fc:	00003097          	auipc	ra,0x3
    80003a00:	fa8080e7          	jalr	-88(ra) # 800069a4 <virtio_disk_rw>
}
    80003a04:	60e2                	ld	ra,24(sp)
    80003a06:	6442                	ld	s0,16(sp)
    80003a08:	64a2                	ld	s1,8(sp)
    80003a0a:	6105                	addi	sp,sp,32
    80003a0c:	8082                	ret
    panic("bwrite");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	d1a50513          	addi	a0,a0,-742 # 80008728 <syscalls+0x2a0>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080003a1e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a1e:	1101                	addi	sp,sp,-32
    80003a20:	ec06                	sd	ra,24(sp)
    80003a22:	e822                	sd	s0,16(sp)
    80003a24:	e426                	sd	s1,8(sp)
    80003a26:	e04a                	sd	s2,0(sp)
    80003a28:	1000                	addi	s0,sp,32
    80003a2a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a2c:	01050913          	addi	s2,a0,16
    80003a30:	854a                	mv	a0,s2
    80003a32:	00001097          	auipc	ra,0x1
    80003a36:	42a080e7          	jalr	1066(ra) # 80004e5c <holdingsleep>
    80003a3a:	c92d                	beqz	a0,80003aac <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003a3c:	854a                	mv	a0,s2
    80003a3e:	00001097          	auipc	ra,0x1
    80003a42:	3da080e7          	jalr	986(ra) # 80004e18 <releasesleep>

  acquire(&bcache.lock);
    80003a46:	00019517          	auipc	a0,0x19
    80003a4a:	c5250513          	addi	a0,a0,-942 # 8001c698 <bcache>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	188080e7          	jalr	392(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003a56:	40bc                	lw	a5,64(s1)
    80003a58:	37fd                	addiw	a5,a5,-1
    80003a5a:	0007871b          	sext.w	a4,a5
    80003a5e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003a60:	eb05                	bnez	a4,80003a90 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003a62:	68bc                	ld	a5,80(s1)
    80003a64:	64b8                	ld	a4,72(s1)
    80003a66:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003a68:	64bc                	ld	a5,72(s1)
    80003a6a:	68b8                	ld	a4,80(s1)
    80003a6c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003a6e:	00021797          	auipc	a5,0x21
    80003a72:	c2a78793          	addi	a5,a5,-982 # 80024698 <bcache+0x8000>
    80003a76:	2b87b703          	ld	a4,696(a5)
    80003a7a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003a7c:	00021717          	auipc	a4,0x21
    80003a80:	e8470713          	addi	a4,a4,-380 # 80024900 <bcache+0x8268>
    80003a84:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a86:	2b87b703          	ld	a4,696(a5)
    80003a8a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a8c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a90:	00019517          	auipc	a0,0x19
    80003a94:	c0850513          	addi	a0,a0,-1016 # 8001c698 <bcache>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	1f2080e7          	jalr	498(ra) # 80000c8a <release>
}
    80003aa0:	60e2                	ld	ra,24(sp)
    80003aa2:	6442                	ld	s0,16(sp)
    80003aa4:	64a2                	ld	s1,8(sp)
    80003aa6:	6902                	ld	s2,0(sp)
    80003aa8:	6105                	addi	sp,sp,32
    80003aaa:	8082                	ret
    panic("brelse");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	c8450513          	addi	a0,a0,-892 # 80008730 <syscalls+0x2a8>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>

0000000080003abc <bpin>:

void
bpin(struct buf *b) {
    80003abc:	1101                	addi	sp,sp,-32
    80003abe:	ec06                	sd	ra,24(sp)
    80003ac0:	e822                	sd	s0,16(sp)
    80003ac2:	e426                	sd	s1,8(sp)
    80003ac4:	1000                	addi	s0,sp,32
    80003ac6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ac8:	00019517          	auipc	a0,0x19
    80003acc:	bd050513          	addi	a0,a0,-1072 # 8001c698 <bcache>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	106080e7          	jalr	262(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003ad8:	40bc                	lw	a5,64(s1)
    80003ada:	2785                	addiw	a5,a5,1
    80003adc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ade:	00019517          	auipc	a0,0x19
    80003ae2:	bba50513          	addi	a0,a0,-1094 # 8001c698 <bcache>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	1a4080e7          	jalr	420(ra) # 80000c8a <release>
}
    80003aee:	60e2                	ld	ra,24(sp)
    80003af0:	6442                	ld	s0,16(sp)
    80003af2:	64a2                	ld	s1,8(sp)
    80003af4:	6105                	addi	sp,sp,32
    80003af6:	8082                	ret

0000000080003af8 <bunpin>:

void
bunpin(struct buf *b) {
    80003af8:	1101                	addi	sp,sp,-32
    80003afa:	ec06                	sd	ra,24(sp)
    80003afc:	e822                	sd	s0,16(sp)
    80003afe:	e426                	sd	s1,8(sp)
    80003b00:	1000                	addi	s0,sp,32
    80003b02:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b04:	00019517          	auipc	a0,0x19
    80003b08:	b9450513          	addi	a0,a0,-1132 # 8001c698 <bcache>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	0ca080e7          	jalr	202(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003b14:	40bc                	lw	a5,64(s1)
    80003b16:	37fd                	addiw	a5,a5,-1
    80003b18:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b1a:	00019517          	auipc	a0,0x19
    80003b1e:	b7e50513          	addi	a0,a0,-1154 # 8001c698 <bcache>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	168080e7          	jalr	360(ra) # 80000c8a <release>
}
    80003b2a:	60e2                	ld	ra,24(sp)
    80003b2c:	6442                	ld	s0,16(sp)
    80003b2e:	64a2                	ld	s1,8(sp)
    80003b30:	6105                	addi	sp,sp,32
    80003b32:	8082                	ret

0000000080003b34 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b34:	1101                	addi	sp,sp,-32
    80003b36:	ec06                	sd	ra,24(sp)
    80003b38:	e822                	sd	s0,16(sp)
    80003b3a:	e426                	sd	s1,8(sp)
    80003b3c:	e04a                	sd	s2,0(sp)
    80003b3e:	1000                	addi	s0,sp,32
    80003b40:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003b42:	00d5d59b          	srliw	a1,a1,0xd
    80003b46:	00021797          	auipc	a5,0x21
    80003b4a:	22e7a783          	lw	a5,558(a5) # 80024d74 <sb+0x1c>
    80003b4e:	9dbd                	addw	a1,a1,a5
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	d9e080e7          	jalr	-610(ra) # 800038ee <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003b58:	0074f713          	andi	a4,s1,7
    80003b5c:	4785                	li	a5,1
    80003b5e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003b62:	14ce                	slli	s1,s1,0x33
    80003b64:	90d9                	srli	s1,s1,0x36
    80003b66:	00950733          	add	a4,a0,s1
    80003b6a:	05874703          	lbu	a4,88(a4)
    80003b6e:	00e7f6b3          	and	a3,a5,a4
    80003b72:	c69d                	beqz	a3,80003ba0 <bfree+0x6c>
    80003b74:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003b76:	94aa                	add	s1,s1,a0
    80003b78:	fff7c793          	not	a5,a5
    80003b7c:	8ff9                	and	a5,a5,a4
    80003b7e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	120080e7          	jalr	288(ra) # 80004ca2 <log_write>
  brelse(bp);
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	e92080e7          	jalr	-366(ra) # 80003a1e <brelse>
}
    80003b94:	60e2                	ld	ra,24(sp)
    80003b96:	6442                	ld	s0,16(sp)
    80003b98:	64a2                	ld	s1,8(sp)
    80003b9a:	6902                	ld	s2,0(sp)
    80003b9c:	6105                	addi	sp,sp,32
    80003b9e:	8082                	ret
    panic("freeing free block");
    80003ba0:	00005517          	auipc	a0,0x5
    80003ba4:	b9850513          	addi	a0,a0,-1128 # 80008738 <syscalls+0x2b0>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>

0000000080003bb0 <balloc>:
{
    80003bb0:	711d                	addi	sp,sp,-96
    80003bb2:	ec86                	sd	ra,88(sp)
    80003bb4:	e8a2                	sd	s0,80(sp)
    80003bb6:	e4a6                	sd	s1,72(sp)
    80003bb8:	e0ca                	sd	s2,64(sp)
    80003bba:	fc4e                	sd	s3,56(sp)
    80003bbc:	f852                	sd	s4,48(sp)
    80003bbe:	f456                	sd	s5,40(sp)
    80003bc0:	f05a                	sd	s6,32(sp)
    80003bc2:	ec5e                	sd	s7,24(sp)
    80003bc4:	e862                	sd	s8,16(sp)
    80003bc6:	e466                	sd	s9,8(sp)
    80003bc8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003bca:	00021797          	auipc	a5,0x21
    80003bce:	1927a783          	lw	a5,402(a5) # 80024d5c <sb+0x4>
    80003bd2:	10078163          	beqz	a5,80003cd4 <balloc+0x124>
    80003bd6:	8baa                	mv	s7,a0
    80003bd8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003bda:	00021b17          	auipc	s6,0x21
    80003bde:	17eb0b13          	addi	s6,s6,382 # 80024d58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003be2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003be4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003be6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003be8:	6c89                	lui	s9,0x2
    80003bea:	a061                	j	80003c72 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bec:	974a                	add	a4,a4,s2
    80003bee:	8fd5                	or	a5,a5,a3
    80003bf0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	0ac080e7          	jalr	172(ra) # 80004ca2 <log_write>
        brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	e1e080e7          	jalr	-482(ra) # 80003a1e <brelse>
  bp = bread(dev, bno);
    80003c08:	85a6                	mv	a1,s1
    80003c0a:	855e                	mv	a0,s7
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	ce2080e7          	jalr	-798(ra) # 800038ee <bread>
    80003c14:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c16:	40000613          	li	a2,1024
    80003c1a:	4581                	li	a1,0
    80003c1c:	05850513          	addi	a0,a0,88
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	0b2080e7          	jalr	178(ra) # 80000cd2 <memset>
  log_write(bp);
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	078080e7          	jalr	120(ra) # 80004ca2 <log_write>
  brelse(bp);
    80003c32:	854a                	mv	a0,s2
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	dea080e7          	jalr	-534(ra) # 80003a1e <brelse>
}
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	60e6                	ld	ra,88(sp)
    80003c40:	6446                	ld	s0,80(sp)
    80003c42:	64a6                	ld	s1,72(sp)
    80003c44:	6906                	ld	s2,64(sp)
    80003c46:	79e2                	ld	s3,56(sp)
    80003c48:	7a42                	ld	s4,48(sp)
    80003c4a:	7aa2                	ld	s5,40(sp)
    80003c4c:	7b02                	ld	s6,32(sp)
    80003c4e:	6be2                	ld	s7,24(sp)
    80003c50:	6c42                	ld	s8,16(sp)
    80003c52:	6ca2                	ld	s9,8(sp)
    80003c54:	6125                	addi	sp,sp,96
    80003c56:	8082                	ret
    brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	dc4080e7          	jalr	-572(ra) # 80003a1e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003c62:	015c87bb          	addw	a5,s9,s5
    80003c66:	00078a9b          	sext.w	s5,a5
    80003c6a:	004b2703          	lw	a4,4(s6)
    80003c6e:	06eaf363          	bgeu	s5,a4,80003cd4 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003c72:	41fad79b          	sraiw	a5,s5,0x1f
    80003c76:	0137d79b          	srliw	a5,a5,0x13
    80003c7a:	015787bb          	addw	a5,a5,s5
    80003c7e:	40d7d79b          	sraiw	a5,a5,0xd
    80003c82:	01cb2583          	lw	a1,28(s6)
    80003c86:	9dbd                	addw	a1,a1,a5
    80003c88:	855e                	mv	a0,s7
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	c64080e7          	jalr	-924(ra) # 800038ee <bread>
    80003c92:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c94:	004b2503          	lw	a0,4(s6)
    80003c98:	000a849b          	sext.w	s1,s5
    80003c9c:	8662                	mv	a2,s8
    80003c9e:	faa4fde3          	bgeu	s1,a0,80003c58 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003ca2:	41f6579b          	sraiw	a5,a2,0x1f
    80003ca6:	01d7d69b          	srliw	a3,a5,0x1d
    80003caa:	00c6873b          	addw	a4,a3,a2
    80003cae:	00777793          	andi	a5,a4,7
    80003cb2:	9f95                	subw	a5,a5,a3
    80003cb4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003cb8:	4037571b          	sraiw	a4,a4,0x3
    80003cbc:	00e906b3          	add	a3,s2,a4
    80003cc0:	0586c683          	lbu	a3,88(a3)
    80003cc4:	00d7f5b3          	and	a1,a5,a3
    80003cc8:	d195                	beqz	a1,80003bec <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cca:	2605                	addiw	a2,a2,1
    80003ccc:	2485                	addiw	s1,s1,1
    80003cce:	fd4618e3          	bne	a2,s4,80003c9e <balloc+0xee>
    80003cd2:	b759                	j	80003c58 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	a7c50513          	addi	a0,a0,-1412 # 80008750 <syscalls+0x2c8>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	8ac080e7          	jalr	-1876(ra) # 80000588 <printf>
  return 0;
    80003ce4:	4481                	li	s1,0
    80003ce6:	bf99                	j	80003c3c <balloc+0x8c>

0000000080003ce8 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ce8:	7179                	addi	sp,sp,-48
    80003cea:	f406                	sd	ra,40(sp)
    80003cec:	f022                	sd	s0,32(sp)
    80003cee:	ec26                	sd	s1,24(sp)
    80003cf0:	e84a                	sd	s2,16(sp)
    80003cf2:	e44e                	sd	s3,8(sp)
    80003cf4:	e052                	sd	s4,0(sp)
    80003cf6:	1800                	addi	s0,sp,48
    80003cf8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003cfa:	47ad                	li	a5,11
    80003cfc:	02b7e763          	bltu	a5,a1,80003d2a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003d00:	02059493          	slli	s1,a1,0x20
    80003d04:	9081                	srli	s1,s1,0x20
    80003d06:	048a                	slli	s1,s1,0x2
    80003d08:	94aa                	add	s1,s1,a0
    80003d0a:	0504a903          	lw	s2,80(s1)
    80003d0e:	06091e63          	bnez	s2,80003d8a <bmap+0xa2>
      addr = balloc(ip->dev);
    80003d12:	4108                	lw	a0,0(a0)
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	e9c080e7          	jalr	-356(ra) # 80003bb0 <balloc>
    80003d1c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d20:	06090563          	beqz	s2,80003d8a <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003d24:	0524a823          	sw	s2,80(s1)
    80003d28:	a08d                	j	80003d8a <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003d2a:	ff45849b          	addiw	s1,a1,-12
    80003d2e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d32:	0ff00793          	li	a5,255
    80003d36:	08e7e563          	bltu	a5,a4,80003dc0 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003d3a:	08052903          	lw	s2,128(a0)
    80003d3e:	00091d63          	bnez	s2,80003d58 <bmap+0x70>
      addr = balloc(ip->dev);
    80003d42:	4108                	lw	a0,0(a0)
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	e6c080e7          	jalr	-404(ra) # 80003bb0 <balloc>
    80003d4c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d50:	02090d63          	beqz	s2,80003d8a <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003d54:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003d58:	85ca                	mv	a1,s2
    80003d5a:	0009a503          	lw	a0,0(s3)
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	b90080e7          	jalr	-1136(ra) # 800038ee <bread>
    80003d66:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003d68:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003d6c:	02049593          	slli	a1,s1,0x20
    80003d70:	9181                	srli	a1,a1,0x20
    80003d72:	058a                	slli	a1,a1,0x2
    80003d74:	00b784b3          	add	s1,a5,a1
    80003d78:	0004a903          	lw	s2,0(s1)
    80003d7c:	02090063          	beqz	s2,80003d9c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003d80:	8552                	mv	a0,s4
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	c9c080e7          	jalr	-868(ra) # 80003a1e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	70a2                	ld	ra,40(sp)
    80003d8e:	7402                	ld	s0,32(sp)
    80003d90:	64e2                	ld	s1,24(sp)
    80003d92:	6942                	ld	s2,16(sp)
    80003d94:	69a2                	ld	s3,8(sp)
    80003d96:	6a02                	ld	s4,0(sp)
    80003d98:	6145                	addi	sp,sp,48
    80003d9a:	8082                	ret
      addr = balloc(ip->dev);
    80003d9c:	0009a503          	lw	a0,0(s3)
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	e10080e7          	jalr	-496(ra) # 80003bb0 <balloc>
    80003da8:	0005091b          	sext.w	s2,a0
      if(addr){
    80003dac:	fc090ae3          	beqz	s2,80003d80 <bmap+0x98>
        a[bn] = addr;
    80003db0:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003db4:	8552                	mv	a0,s4
    80003db6:	00001097          	auipc	ra,0x1
    80003dba:	eec080e7          	jalr	-276(ra) # 80004ca2 <log_write>
    80003dbe:	b7c9                	j	80003d80 <bmap+0x98>
  panic("bmap: out of range");
    80003dc0:	00005517          	auipc	a0,0x5
    80003dc4:	9a850513          	addi	a0,a0,-1624 # 80008768 <syscalls+0x2e0>
    80003dc8:	ffffc097          	auipc	ra,0xffffc
    80003dcc:	776080e7          	jalr	1910(ra) # 8000053e <panic>

0000000080003dd0 <iget>:
{
    80003dd0:	7179                	addi	sp,sp,-48
    80003dd2:	f406                	sd	ra,40(sp)
    80003dd4:	f022                	sd	s0,32(sp)
    80003dd6:	ec26                	sd	s1,24(sp)
    80003dd8:	e84a                	sd	s2,16(sp)
    80003dda:	e44e                	sd	s3,8(sp)
    80003ddc:	e052                	sd	s4,0(sp)
    80003dde:	1800                	addi	s0,sp,48
    80003de0:	89aa                	mv	s3,a0
    80003de2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003de4:	00021517          	auipc	a0,0x21
    80003de8:	f9450513          	addi	a0,a0,-108 # 80024d78 <itable>
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	dea080e7          	jalr	-534(ra) # 80000bd6 <acquire>
  empty = 0;
    80003df4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003df6:	00021497          	auipc	s1,0x21
    80003dfa:	f9a48493          	addi	s1,s1,-102 # 80024d90 <itable+0x18>
    80003dfe:	00023697          	auipc	a3,0x23
    80003e02:	a2268693          	addi	a3,a3,-1502 # 80026820 <log>
    80003e06:	a039                	j	80003e14 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e08:	02090b63          	beqz	s2,80003e3e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e0c:	08848493          	addi	s1,s1,136
    80003e10:	02d48a63          	beq	s1,a3,80003e44 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e14:	449c                	lw	a5,8(s1)
    80003e16:	fef059e3          	blez	a5,80003e08 <iget+0x38>
    80003e1a:	4098                	lw	a4,0(s1)
    80003e1c:	ff3716e3          	bne	a4,s3,80003e08 <iget+0x38>
    80003e20:	40d8                	lw	a4,4(s1)
    80003e22:	ff4713e3          	bne	a4,s4,80003e08 <iget+0x38>
      ip->ref++;
    80003e26:	2785                	addiw	a5,a5,1
    80003e28:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e2a:	00021517          	auipc	a0,0x21
    80003e2e:	f4e50513          	addi	a0,a0,-178 # 80024d78 <itable>
    80003e32:	ffffd097          	auipc	ra,0xffffd
    80003e36:	e58080e7          	jalr	-424(ra) # 80000c8a <release>
      return ip;
    80003e3a:	8926                	mv	s2,s1
    80003e3c:	a03d                	j	80003e6a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e3e:	f7f9                	bnez	a5,80003e0c <iget+0x3c>
    80003e40:	8926                	mv	s2,s1
    80003e42:	b7e9                	j	80003e0c <iget+0x3c>
  if(empty == 0)
    80003e44:	02090c63          	beqz	s2,80003e7c <iget+0xac>
  ip->dev = dev;
    80003e48:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003e4c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003e50:	4785                	li	a5,1
    80003e52:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003e56:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003e5a:	00021517          	auipc	a0,0x21
    80003e5e:	f1e50513          	addi	a0,a0,-226 # 80024d78 <itable>
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	e28080e7          	jalr	-472(ra) # 80000c8a <release>
}
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	70a2                	ld	ra,40(sp)
    80003e6e:	7402                	ld	s0,32(sp)
    80003e70:	64e2                	ld	s1,24(sp)
    80003e72:	6942                	ld	s2,16(sp)
    80003e74:	69a2                	ld	s3,8(sp)
    80003e76:	6a02                	ld	s4,0(sp)
    80003e78:	6145                	addi	sp,sp,48
    80003e7a:	8082                	ret
    panic("iget: no inodes");
    80003e7c:	00005517          	auipc	a0,0x5
    80003e80:	90450513          	addi	a0,a0,-1788 # 80008780 <syscalls+0x2f8>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6ba080e7          	jalr	1722(ra) # 8000053e <panic>

0000000080003e8c <fsinit>:
fsinit(int dev) {
    80003e8c:	7179                	addi	sp,sp,-48
    80003e8e:	f406                	sd	ra,40(sp)
    80003e90:	f022                	sd	s0,32(sp)
    80003e92:	ec26                	sd	s1,24(sp)
    80003e94:	e84a                	sd	s2,16(sp)
    80003e96:	e44e                	sd	s3,8(sp)
    80003e98:	1800                	addi	s0,sp,48
    80003e9a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e9c:	4585                	li	a1,1
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	a50080e7          	jalr	-1456(ra) # 800038ee <bread>
    80003ea6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ea8:	00021997          	auipc	s3,0x21
    80003eac:	eb098993          	addi	s3,s3,-336 # 80024d58 <sb>
    80003eb0:	02000613          	li	a2,32
    80003eb4:	05850593          	addi	a1,a0,88
    80003eb8:	854e                	mv	a0,s3
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	e74080e7          	jalr	-396(ra) # 80000d2e <memmove>
  brelse(bp);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	b5a080e7          	jalr	-1190(ra) # 80003a1e <brelse>
  if(sb.magic != FSMAGIC)
    80003ecc:	0009a703          	lw	a4,0(s3)
    80003ed0:	102037b7          	lui	a5,0x10203
    80003ed4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ed8:	02f71263          	bne	a4,a5,80003efc <fsinit+0x70>
  initlog(dev, &sb);
    80003edc:	00021597          	auipc	a1,0x21
    80003ee0:	e7c58593          	addi	a1,a1,-388 # 80024d58 <sb>
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	00001097          	auipc	ra,0x1
    80003eea:	b40080e7          	jalr	-1216(ra) # 80004a26 <initlog>
}
    80003eee:	70a2                	ld	ra,40(sp)
    80003ef0:	7402                	ld	s0,32(sp)
    80003ef2:	64e2                	ld	s1,24(sp)
    80003ef4:	6942                	ld	s2,16(sp)
    80003ef6:	69a2                	ld	s3,8(sp)
    80003ef8:	6145                	addi	sp,sp,48
    80003efa:	8082                	ret
    panic("invalid file system");
    80003efc:	00005517          	auipc	a0,0x5
    80003f00:	89450513          	addi	a0,a0,-1900 # 80008790 <syscalls+0x308>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	63a080e7          	jalr	1594(ra) # 8000053e <panic>

0000000080003f0c <iinit>:
{
    80003f0c:	7179                	addi	sp,sp,-48
    80003f0e:	f406                	sd	ra,40(sp)
    80003f10:	f022                	sd	s0,32(sp)
    80003f12:	ec26                	sd	s1,24(sp)
    80003f14:	e84a                	sd	s2,16(sp)
    80003f16:	e44e                	sd	s3,8(sp)
    80003f18:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f1a:	00005597          	auipc	a1,0x5
    80003f1e:	88e58593          	addi	a1,a1,-1906 # 800087a8 <syscalls+0x320>
    80003f22:	00021517          	auipc	a0,0x21
    80003f26:	e5650513          	addi	a0,a0,-426 # 80024d78 <itable>
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	c1c080e7          	jalr	-996(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003f32:	00021497          	auipc	s1,0x21
    80003f36:	e6e48493          	addi	s1,s1,-402 # 80024da0 <itable+0x28>
    80003f3a:	00023997          	auipc	s3,0x23
    80003f3e:	8f698993          	addi	s3,s3,-1802 # 80026830 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003f42:	00005917          	auipc	s2,0x5
    80003f46:	86e90913          	addi	s2,s2,-1938 # 800087b0 <syscalls+0x328>
    80003f4a:	85ca                	mv	a1,s2
    80003f4c:	8526                	mv	a0,s1
    80003f4e:	00001097          	auipc	ra,0x1
    80003f52:	e3a080e7          	jalr	-454(ra) # 80004d88 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003f56:	08848493          	addi	s1,s1,136
    80003f5a:	ff3498e3          	bne	s1,s3,80003f4a <iinit+0x3e>
}
    80003f5e:	70a2                	ld	ra,40(sp)
    80003f60:	7402                	ld	s0,32(sp)
    80003f62:	64e2                	ld	s1,24(sp)
    80003f64:	6942                	ld	s2,16(sp)
    80003f66:	69a2                	ld	s3,8(sp)
    80003f68:	6145                	addi	sp,sp,48
    80003f6a:	8082                	ret

0000000080003f6c <ialloc>:
{
    80003f6c:	715d                	addi	sp,sp,-80
    80003f6e:	e486                	sd	ra,72(sp)
    80003f70:	e0a2                	sd	s0,64(sp)
    80003f72:	fc26                	sd	s1,56(sp)
    80003f74:	f84a                	sd	s2,48(sp)
    80003f76:	f44e                	sd	s3,40(sp)
    80003f78:	f052                	sd	s4,32(sp)
    80003f7a:	ec56                	sd	s5,24(sp)
    80003f7c:	e85a                	sd	s6,16(sp)
    80003f7e:	e45e                	sd	s7,8(sp)
    80003f80:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f82:	00021717          	auipc	a4,0x21
    80003f86:	de272703          	lw	a4,-542(a4) # 80024d64 <sb+0xc>
    80003f8a:	4785                	li	a5,1
    80003f8c:	04e7fa63          	bgeu	a5,a4,80003fe0 <ialloc+0x74>
    80003f90:	8aaa                	mv	s5,a0
    80003f92:	8bae                	mv	s7,a1
    80003f94:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f96:	00021a17          	auipc	s4,0x21
    80003f9a:	dc2a0a13          	addi	s4,s4,-574 # 80024d58 <sb>
    80003f9e:	00048b1b          	sext.w	s6,s1
    80003fa2:	0044d793          	srli	a5,s1,0x4
    80003fa6:	018a2583          	lw	a1,24(s4)
    80003faa:	9dbd                	addw	a1,a1,a5
    80003fac:	8556                	mv	a0,s5
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	940080e7          	jalr	-1728(ra) # 800038ee <bread>
    80003fb6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003fb8:	05850993          	addi	s3,a0,88
    80003fbc:	00f4f793          	andi	a5,s1,15
    80003fc0:	079a                	slli	a5,a5,0x6
    80003fc2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003fc4:	00099783          	lh	a5,0(s3)
    80003fc8:	c3a1                	beqz	a5,80004008 <ialloc+0x9c>
    brelse(bp);
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	a54080e7          	jalr	-1452(ra) # 80003a1e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003fd2:	0485                	addi	s1,s1,1
    80003fd4:	00ca2703          	lw	a4,12(s4)
    80003fd8:	0004879b          	sext.w	a5,s1
    80003fdc:	fce7e1e3          	bltu	a5,a4,80003f9e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003fe0:	00004517          	auipc	a0,0x4
    80003fe4:	7d850513          	addi	a0,a0,2008 # 800087b8 <syscalls+0x330>
    80003fe8:	ffffc097          	auipc	ra,0xffffc
    80003fec:	5a0080e7          	jalr	1440(ra) # 80000588 <printf>
  return 0;
    80003ff0:	4501                	li	a0,0
}
    80003ff2:	60a6                	ld	ra,72(sp)
    80003ff4:	6406                	ld	s0,64(sp)
    80003ff6:	74e2                	ld	s1,56(sp)
    80003ff8:	7942                	ld	s2,48(sp)
    80003ffa:	79a2                	ld	s3,40(sp)
    80003ffc:	7a02                	ld	s4,32(sp)
    80003ffe:	6ae2                	ld	s5,24(sp)
    80004000:	6b42                	ld	s6,16(sp)
    80004002:	6ba2                	ld	s7,8(sp)
    80004004:	6161                	addi	sp,sp,80
    80004006:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004008:	04000613          	li	a2,64
    8000400c:	4581                	li	a1,0
    8000400e:	854e                	mv	a0,s3
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	cc2080e7          	jalr	-830(ra) # 80000cd2 <memset>
      dip->type = type;
    80004018:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000401c:	854a                	mv	a0,s2
    8000401e:	00001097          	auipc	ra,0x1
    80004022:	c84080e7          	jalr	-892(ra) # 80004ca2 <log_write>
      brelse(bp);
    80004026:	854a                	mv	a0,s2
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	9f6080e7          	jalr	-1546(ra) # 80003a1e <brelse>
      return iget(dev, inum);
    80004030:	85da                	mv	a1,s6
    80004032:	8556                	mv	a0,s5
    80004034:	00000097          	auipc	ra,0x0
    80004038:	d9c080e7          	jalr	-612(ra) # 80003dd0 <iget>
    8000403c:	bf5d                	j	80003ff2 <ialloc+0x86>

000000008000403e <iupdate>:
{
    8000403e:	1101                	addi	sp,sp,-32
    80004040:	ec06                	sd	ra,24(sp)
    80004042:	e822                	sd	s0,16(sp)
    80004044:	e426                	sd	s1,8(sp)
    80004046:	e04a                	sd	s2,0(sp)
    80004048:	1000                	addi	s0,sp,32
    8000404a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000404c:	415c                	lw	a5,4(a0)
    8000404e:	0047d79b          	srliw	a5,a5,0x4
    80004052:	00021597          	auipc	a1,0x21
    80004056:	d1e5a583          	lw	a1,-738(a1) # 80024d70 <sb+0x18>
    8000405a:	9dbd                	addw	a1,a1,a5
    8000405c:	4108                	lw	a0,0(a0)
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	890080e7          	jalr	-1904(ra) # 800038ee <bread>
    80004066:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004068:	05850793          	addi	a5,a0,88
    8000406c:	40c8                	lw	a0,4(s1)
    8000406e:	893d                	andi	a0,a0,15
    80004070:	051a                	slli	a0,a0,0x6
    80004072:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004074:	04449703          	lh	a4,68(s1)
    80004078:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000407c:	04649703          	lh	a4,70(s1)
    80004080:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004084:	04849703          	lh	a4,72(s1)
    80004088:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000408c:	04a49703          	lh	a4,74(s1)
    80004090:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004094:	44f8                	lw	a4,76(s1)
    80004096:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004098:	03400613          	li	a2,52
    8000409c:	05048593          	addi	a1,s1,80
    800040a0:	0531                	addi	a0,a0,12
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	c8c080e7          	jalr	-884(ra) # 80000d2e <memmove>
  log_write(bp);
    800040aa:	854a                	mv	a0,s2
    800040ac:	00001097          	auipc	ra,0x1
    800040b0:	bf6080e7          	jalr	-1034(ra) # 80004ca2 <log_write>
  brelse(bp);
    800040b4:	854a                	mv	a0,s2
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	968080e7          	jalr	-1688(ra) # 80003a1e <brelse>
}
    800040be:	60e2                	ld	ra,24(sp)
    800040c0:	6442                	ld	s0,16(sp)
    800040c2:	64a2                	ld	s1,8(sp)
    800040c4:	6902                	ld	s2,0(sp)
    800040c6:	6105                	addi	sp,sp,32
    800040c8:	8082                	ret

00000000800040ca <idup>:
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	e426                	sd	s1,8(sp)
    800040d2:	1000                	addi	s0,sp,32
    800040d4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040d6:	00021517          	auipc	a0,0x21
    800040da:	ca250513          	addi	a0,a0,-862 # 80024d78 <itable>
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	af8080e7          	jalr	-1288(ra) # 80000bd6 <acquire>
  ip->ref++;
    800040e6:	449c                	lw	a5,8(s1)
    800040e8:	2785                	addiw	a5,a5,1
    800040ea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040ec:	00021517          	auipc	a0,0x21
    800040f0:	c8c50513          	addi	a0,a0,-884 # 80024d78 <itable>
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	b96080e7          	jalr	-1130(ra) # 80000c8a <release>
}
    800040fc:	8526                	mv	a0,s1
    800040fe:	60e2                	ld	ra,24(sp)
    80004100:	6442                	ld	s0,16(sp)
    80004102:	64a2                	ld	s1,8(sp)
    80004104:	6105                	addi	sp,sp,32
    80004106:	8082                	ret

0000000080004108 <ilock>:
{
    80004108:	1101                	addi	sp,sp,-32
    8000410a:	ec06                	sd	ra,24(sp)
    8000410c:	e822                	sd	s0,16(sp)
    8000410e:	e426                	sd	s1,8(sp)
    80004110:	e04a                	sd	s2,0(sp)
    80004112:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004114:	c115                	beqz	a0,80004138 <ilock+0x30>
    80004116:	84aa                	mv	s1,a0
    80004118:	451c                	lw	a5,8(a0)
    8000411a:	00f05f63          	blez	a5,80004138 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000411e:	0541                	addi	a0,a0,16
    80004120:	00001097          	auipc	ra,0x1
    80004124:	ca2080e7          	jalr	-862(ra) # 80004dc2 <acquiresleep>
  if(ip->valid == 0){
    80004128:	40bc                	lw	a5,64(s1)
    8000412a:	cf99                	beqz	a5,80004148 <ilock+0x40>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6902                	ld	s2,0(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret
    panic("ilock");
    80004138:	00004517          	auipc	a0,0x4
    8000413c:	69850513          	addi	a0,a0,1688 # 800087d0 <syscalls+0x348>
    80004140:	ffffc097          	auipc	ra,0xffffc
    80004144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004148:	40dc                	lw	a5,4(s1)
    8000414a:	0047d79b          	srliw	a5,a5,0x4
    8000414e:	00021597          	auipc	a1,0x21
    80004152:	c225a583          	lw	a1,-990(a1) # 80024d70 <sb+0x18>
    80004156:	9dbd                	addw	a1,a1,a5
    80004158:	4088                	lw	a0,0(s1)
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	794080e7          	jalr	1940(ra) # 800038ee <bread>
    80004162:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004164:	05850593          	addi	a1,a0,88
    80004168:	40dc                	lw	a5,4(s1)
    8000416a:	8bbd                	andi	a5,a5,15
    8000416c:	079a                	slli	a5,a5,0x6
    8000416e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004170:	00059783          	lh	a5,0(a1)
    80004174:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004178:	00259783          	lh	a5,2(a1)
    8000417c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004180:	00459783          	lh	a5,4(a1)
    80004184:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004188:	00659783          	lh	a5,6(a1)
    8000418c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004190:	459c                	lw	a5,8(a1)
    80004192:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004194:	03400613          	li	a2,52
    80004198:	05b1                	addi	a1,a1,12
    8000419a:	05048513          	addi	a0,s1,80
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	b90080e7          	jalr	-1136(ra) # 80000d2e <memmove>
    brelse(bp);
    800041a6:	854a                	mv	a0,s2
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	876080e7          	jalr	-1930(ra) # 80003a1e <brelse>
    ip->valid = 1;
    800041b0:	4785                	li	a5,1
    800041b2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800041b4:	04449783          	lh	a5,68(s1)
    800041b8:	fbb5                	bnez	a5,8000412c <ilock+0x24>
      panic("ilock: no type");
    800041ba:	00004517          	auipc	a0,0x4
    800041be:	61e50513          	addi	a0,a0,1566 # 800087d8 <syscalls+0x350>
    800041c2:	ffffc097          	auipc	ra,0xffffc
    800041c6:	37c080e7          	jalr	892(ra) # 8000053e <panic>

00000000800041ca <iunlock>:
{
    800041ca:	1101                	addi	sp,sp,-32
    800041cc:	ec06                	sd	ra,24(sp)
    800041ce:	e822                	sd	s0,16(sp)
    800041d0:	e426                	sd	s1,8(sp)
    800041d2:	e04a                	sd	s2,0(sp)
    800041d4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800041d6:	c905                	beqz	a0,80004206 <iunlock+0x3c>
    800041d8:	84aa                	mv	s1,a0
    800041da:	01050913          	addi	s2,a0,16
    800041de:	854a                	mv	a0,s2
    800041e0:	00001097          	auipc	ra,0x1
    800041e4:	c7c080e7          	jalr	-900(ra) # 80004e5c <holdingsleep>
    800041e8:	cd19                	beqz	a0,80004206 <iunlock+0x3c>
    800041ea:	449c                	lw	a5,8(s1)
    800041ec:	00f05d63          	blez	a5,80004206 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800041f0:	854a                	mv	a0,s2
    800041f2:	00001097          	auipc	ra,0x1
    800041f6:	c26080e7          	jalr	-986(ra) # 80004e18 <releasesleep>
}
    800041fa:	60e2                	ld	ra,24(sp)
    800041fc:	6442                	ld	s0,16(sp)
    800041fe:	64a2                	ld	s1,8(sp)
    80004200:	6902                	ld	s2,0(sp)
    80004202:	6105                	addi	sp,sp,32
    80004204:	8082                	ret
    panic("iunlock");
    80004206:	00004517          	auipc	a0,0x4
    8000420a:	5e250513          	addi	a0,a0,1506 # 800087e8 <syscalls+0x360>
    8000420e:	ffffc097          	auipc	ra,0xffffc
    80004212:	330080e7          	jalr	816(ra) # 8000053e <panic>

0000000080004216 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004216:	7179                	addi	sp,sp,-48
    80004218:	f406                	sd	ra,40(sp)
    8000421a:	f022                	sd	s0,32(sp)
    8000421c:	ec26                	sd	s1,24(sp)
    8000421e:	e84a                	sd	s2,16(sp)
    80004220:	e44e                	sd	s3,8(sp)
    80004222:	e052                	sd	s4,0(sp)
    80004224:	1800                	addi	s0,sp,48
    80004226:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004228:	05050493          	addi	s1,a0,80
    8000422c:	08050913          	addi	s2,a0,128
    80004230:	a021                	j	80004238 <itrunc+0x22>
    80004232:	0491                	addi	s1,s1,4
    80004234:	01248d63          	beq	s1,s2,8000424e <itrunc+0x38>
    if(ip->addrs[i]){
    80004238:	408c                	lw	a1,0(s1)
    8000423a:	dde5                	beqz	a1,80004232 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000423c:	0009a503          	lw	a0,0(s3)
    80004240:	00000097          	auipc	ra,0x0
    80004244:	8f4080e7          	jalr	-1804(ra) # 80003b34 <bfree>
      ip->addrs[i] = 0;
    80004248:	0004a023          	sw	zero,0(s1)
    8000424c:	b7dd                	j	80004232 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000424e:	0809a583          	lw	a1,128(s3)
    80004252:	e185                	bnez	a1,80004272 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004254:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	de4080e7          	jalr	-540(ra) # 8000403e <iupdate>
}
    80004262:	70a2                	ld	ra,40(sp)
    80004264:	7402                	ld	s0,32(sp)
    80004266:	64e2                	ld	s1,24(sp)
    80004268:	6942                	ld	s2,16(sp)
    8000426a:	69a2                	ld	s3,8(sp)
    8000426c:	6a02                	ld	s4,0(sp)
    8000426e:	6145                	addi	sp,sp,48
    80004270:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004272:	0009a503          	lw	a0,0(s3)
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	678080e7          	jalr	1656(ra) # 800038ee <bread>
    8000427e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004280:	05850493          	addi	s1,a0,88
    80004284:	45850913          	addi	s2,a0,1112
    80004288:	a021                	j	80004290 <itrunc+0x7a>
    8000428a:	0491                	addi	s1,s1,4
    8000428c:	01248b63          	beq	s1,s2,800042a2 <itrunc+0x8c>
      if(a[j])
    80004290:	408c                	lw	a1,0(s1)
    80004292:	dde5                	beqz	a1,8000428a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004294:	0009a503          	lw	a0,0(s3)
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	89c080e7          	jalr	-1892(ra) # 80003b34 <bfree>
    800042a0:	b7ed                	j	8000428a <itrunc+0x74>
    brelse(bp);
    800042a2:	8552                	mv	a0,s4
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	77a080e7          	jalr	1914(ra) # 80003a1e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800042ac:	0809a583          	lw	a1,128(s3)
    800042b0:	0009a503          	lw	a0,0(s3)
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	880080e7          	jalr	-1920(ra) # 80003b34 <bfree>
    ip->addrs[NDIRECT] = 0;
    800042bc:	0809a023          	sw	zero,128(s3)
    800042c0:	bf51                	j	80004254 <itrunc+0x3e>

00000000800042c2 <iput>:
{
    800042c2:	1101                	addi	sp,sp,-32
    800042c4:	ec06                	sd	ra,24(sp)
    800042c6:	e822                	sd	s0,16(sp)
    800042c8:	e426                	sd	s1,8(sp)
    800042ca:	e04a                	sd	s2,0(sp)
    800042cc:	1000                	addi	s0,sp,32
    800042ce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042d0:	00021517          	auipc	a0,0x21
    800042d4:	aa850513          	addi	a0,a0,-1368 # 80024d78 <itable>
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042e0:	4498                	lw	a4,8(s1)
    800042e2:	4785                	li	a5,1
    800042e4:	02f70363          	beq	a4,a5,8000430a <iput+0x48>
  ip->ref--;
    800042e8:	449c                	lw	a5,8(s1)
    800042ea:	37fd                	addiw	a5,a5,-1
    800042ec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042ee:	00021517          	auipc	a0,0x21
    800042f2:	a8a50513          	addi	a0,a0,-1398 # 80024d78 <itable>
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	994080e7          	jalr	-1644(ra) # 80000c8a <release>
}
    800042fe:	60e2                	ld	ra,24(sp)
    80004300:	6442                	ld	s0,16(sp)
    80004302:	64a2                	ld	s1,8(sp)
    80004304:	6902                	ld	s2,0(sp)
    80004306:	6105                	addi	sp,sp,32
    80004308:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000430a:	40bc                	lw	a5,64(s1)
    8000430c:	dff1                	beqz	a5,800042e8 <iput+0x26>
    8000430e:	04a49783          	lh	a5,74(s1)
    80004312:	fbf9                	bnez	a5,800042e8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004314:	01048913          	addi	s2,s1,16
    80004318:	854a                	mv	a0,s2
    8000431a:	00001097          	auipc	ra,0x1
    8000431e:	aa8080e7          	jalr	-1368(ra) # 80004dc2 <acquiresleep>
    release(&itable.lock);
    80004322:	00021517          	auipc	a0,0x21
    80004326:	a5650513          	addi	a0,a0,-1450 # 80024d78 <itable>
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
    itrunc(ip);
    80004332:	8526                	mv	a0,s1
    80004334:	00000097          	auipc	ra,0x0
    80004338:	ee2080e7          	jalr	-286(ra) # 80004216 <itrunc>
    ip->type = 0;
    8000433c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004340:	8526                	mv	a0,s1
    80004342:	00000097          	auipc	ra,0x0
    80004346:	cfc080e7          	jalr	-772(ra) # 8000403e <iupdate>
    ip->valid = 0;
    8000434a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000434e:	854a                	mv	a0,s2
    80004350:	00001097          	auipc	ra,0x1
    80004354:	ac8080e7          	jalr	-1336(ra) # 80004e18 <releasesleep>
    acquire(&itable.lock);
    80004358:	00021517          	auipc	a0,0x21
    8000435c:	a2050513          	addi	a0,a0,-1504 # 80024d78 <itable>
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	876080e7          	jalr	-1930(ra) # 80000bd6 <acquire>
    80004368:	b741                	j	800042e8 <iput+0x26>

000000008000436a <iunlockput>:
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	1000                	addi	s0,sp,32
    80004374:	84aa                	mv	s1,a0
  iunlock(ip);
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	e54080e7          	jalr	-428(ra) # 800041ca <iunlock>
  iput(ip);
    8000437e:	8526                	mv	a0,s1
    80004380:	00000097          	auipc	ra,0x0
    80004384:	f42080e7          	jalr	-190(ra) # 800042c2 <iput>
}
    80004388:	60e2                	ld	ra,24(sp)
    8000438a:	6442                	ld	s0,16(sp)
    8000438c:	64a2                	ld	s1,8(sp)
    8000438e:	6105                	addi	sp,sp,32
    80004390:	8082                	ret

0000000080004392 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004392:	1141                	addi	sp,sp,-16
    80004394:	e422                	sd	s0,8(sp)
    80004396:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004398:	411c                	lw	a5,0(a0)
    8000439a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000439c:	415c                	lw	a5,4(a0)
    8000439e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800043a0:	04451783          	lh	a5,68(a0)
    800043a4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800043a8:	04a51783          	lh	a5,74(a0)
    800043ac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800043b0:	04c56783          	lwu	a5,76(a0)
    800043b4:	e99c                	sd	a5,16(a1)
}
    800043b6:	6422                	ld	s0,8(sp)
    800043b8:	0141                	addi	sp,sp,16
    800043ba:	8082                	ret

00000000800043bc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043bc:	457c                	lw	a5,76(a0)
    800043be:	0ed7e963          	bltu	a5,a3,800044b0 <readi+0xf4>
{
    800043c2:	7159                	addi	sp,sp,-112
    800043c4:	f486                	sd	ra,104(sp)
    800043c6:	f0a2                	sd	s0,96(sp)
    800043c8:	eca6                	sd	s1,88(sp)
    800043ca:	e8ca                	sd	s2,80(sp)
    800043cc:	e4ce                	sd	s3,72(sp)
    800043ce:	e0d2                	sd	s4,64(sp)
    800043d0:	fc56                	sd	s5,56(sp)
    800043d2:	f85a                	sd	s6,48(sp)
    800043d4:	f45e                	sd	s7,40(sp)
    800043d6:	f062                	sd	s8,32(sp)
    800043d8:	ec66                	sd	s9,24(sp)
    800043da:	e86a                	sd	s10,16(sp)
    800043dc:	e46e                	sd	s11,8(sp)
    800043de:	1880                	addi	s0,sp,112
    800043e0:	8b2a                	mv	s6,a0
    800043e2:	8bae                	mv	s7,a1
    800043e4:	8a32                	mv	s4,a2
    800043e6:	84b6                	mv	s1,a3
    800043e8:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800043ea:	9f35                	addw	a4,a4,a3
    return 0;
    800043ec:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800043ee:	0ad76063          	bltu	a4,a3,8000448e <readi+0xd2>
  if(off + n > ip->size)
    800043f2:	00e7f463          	bgeu	a5,a4,800043fa <readi+0x3e>
    n = ip->size - off;
    800043f6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043fa:	0a0a8963          	beqz	s5,800044ac <readi+0xf0>
    800043fe:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004400:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004404:	5c7d                	li	s8,-1
    80004406:	a82d                	j	80004440 <readi+0x84>
    80004408:	020d1d93          	slli	s11,s10,0x20
    8000440c:	020ddd93          	srli	s11,s11,0x20
    80004410:	05890793          	addi	a5,s2,88
    80004414:	86ee                	mv	a3,s11
    80004416:	963e                	add	a2,a2,a5
    80004418:	85d2                	mv	a1,s4
    8000441a:	855e                	mv	a0,s7
    8000441c:	ffffe097          	auipc	ra,0xffffe
    80004420:	462080e7          	jalr	1122(ra) # 8000287e <either_copyout>
    80004424:	05850d63          	beq	a0,s8,8000447e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004428:	854a                	mv	a0,s2
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	5f4080e7          	jalr	1524(ra) # 80003a1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004432:	013d09bb          	addw	s3,s10,s3
    80004436:	009d04bb          	addw	s1,s10,s1
    8000443a:	9a6e                	add	s4,s4,s11
    8000443c:	0559f763          	bgeu	s3,s5,8000448a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004440:	00a4d59b          	srliw	a1,s1,0xa
    80004444:	855a                	mv	a0,s6
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	8a2080e7          	jalr	-1886(ra) # 80003ce8 <bmap>
    8000444e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004452:	cd85                	beqz	a1,8000448a <readi+0xce>
    bp = bread(ip->dev, addr);
    80004454:	000b2503          	lw	a0,0(s6)
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	496080e7          	jalr	1174(ra) # 800038ee <bread>
    80004460:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004462:	3ff4f613          	andi	a2,s1,1023
    80004466:	40cc87bb          	subw	a5,s9,a2
    8000446a:	413a873b          	subw	a4,s5,s3
    8000446e:	8d3e                	mv	s10,a5
    80004470:	2781                	sext.w	a5,a5
    80004472:	0007069b          	sext.w	a3,a4
    80004476:	f8f6f9e3          	bgeu	a3,a5,80004408 <readi+0x4c>
    8000447a:	8d3a                	mv	s10,a4
    8000447c:	b771                	j	80004408 <readi+0x4c>
      brelse(bp);
    8000447e:	854a                	mv	a0,s2
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	59e080e7          	jalr	1438(ra) # 80003a1e <brelse>
      tot = -1;
    80004488:	59fd                	li	s3,-1
  }
  return tot;
    8000448a:	0009851b          	sext.w	a0,s3
}
    8000448e:	70a6                	ld	ra,104(sp)
    80004490:	7406                	ld	s0,96(sp)
    80004492:	64e6                	ld	s1,88(sp)
    80004494:	6946                	ld	s2,80(sp)
    80004496:	69a6                	ld	s3,72(sp)
    80004498:	6a06                	ld	s4,64(sp)
    8000449a:	7ae2                	ld	s5,56(sp)
    8000449c:	7b42                	ld	s6,48(sp)
    8000449e:	7ba2                	ld	s7,40(sp)
    800044a0:	7c02                	ld	s8,32(sp)
    800044a2:	6ce2                	ld	s9,24(sp)
    800044a4:	6d42                	ld	s10,16(sp)
    800044a6:	6da2                	ld	s11,8(sp)
    800044a8:	6165                	addi	sp,sp,112
    800044aa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044ac:	89d6                	mv	s3,s5
    800044ae:	bff1                	j	8000448a <readi+0xce>
    return 0;
    800044b0:	4501                	li	a0,0
}
    800044b2:	8082                	ret

00000000800044b4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800044b4:	457c                	lw	a5,76(a0)
    800044b6:	10d7e863          	bltu	a5,a3,800045c6 <writei+0x112>
{
    800044ba:	7159                	addi	sp,sp,-112
    800044bc:	f486                	sd	ra,104(sp)
    800044be:	f0a2                	sd	s0,96(sp)
    800044c0:	eca6                	sd	s1,88(sp)
    800044c2:	e8ca                	sd	s2,80(sp)
    800044c4:	e4ce                	sd	s3,72(sp)
    800044c6:	e0d2                	sd	s4,64(sp)
    800044c8:	fc56                	sd	s5,56(sp)
    800044ca:	f85a                	sd	s6,48(sp)
    800044cc:	f45e                	sd	s7,40(sp)
    800044ce:	f062                	sd	s8,32(sp)
    800044d0:	ec66                	sd	s9,24(sp)
    800044d2:	e86a                	sd	s10,16(sp)
    800044d4:	e46e                	sd	s11,8(sp)
    800044d6:	1880                	addi	s0,sp,112
    800044d8:	8aaa                	mv	s5,a0
    800044da:	8bae                	mv	s7,a1
    800044dc:	8a32                	mv	s4,a2
    800044de:	8936                	mv	s2,a3
    800044e0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800044e2:	00e687bb          	addw	a5,a3,a4
    800044e6:	0ed7e263          	bltu	a5,a3,800045ca <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800044ea:	00043737          	lui	a4,0x43
    800044ee:	0ef76063          	bltu	a4,a5,800045ce <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044f2:	0c0b0863          	beqz	s6,800045c2 <writei+0x10e>
    800044f6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800044f8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800044fc:	5c7d                	li	s8,-1
    800044fe:	a091                	j	80004542 <writei+0x8e>
    80004500:	020d1d93          	slli	s11,s10,0x20
    80004504:	020ddd93          	srli	s11,s11,0x20
    80004508:	05848793          	addi	a5,s1,88
    8000450c:	86ee                	mv	a3,s11
    8000450e:	8652                	mv	a2,s4
    80004510:	85de                	mv	a1,s7
    80004512:	953e                	add	a0,a0,a5
    80004514:	ffffe097          	auipc	ra,0xffffe
    80004518:	3c0080e7          	jalr	960(ra) # 800028d4 <either_copyin>
    8000451c:	07850263          	beq	a0,s8,80004580 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004520:	8526                	mv	a0,s1
    80004522:	00000097          	auipc	ra,0x0
    80004526:	780080e7          	jalr	1920(ra) # 80004ca2 <log_write>
    brelse(bp);
    8000452a:	8526                	mv	a0,s1
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	4f2080e7          	jalr	1266(ra) # 80003a1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004534:	013d09bb          	addw	s3,s10,s3
    80004538:	012d093b          	addw	s2,s10,s2
    8000453c:	9a6e                	add	s4,s4,s11
    8000453e:	0569f663          	bgeu	s3,s6,8000458a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004542:	00a9559b          	srliw	a1,s2,0xa
    80004546:	8556                	mv	a0,s5
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	7a0080e7          	jalr	1952(ra) # 80003ce8 <bmap>
    80004550:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004554:	c99d                	beqz	a1,8000458a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004556:	000aa503          	lw	a0,0(s5)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	394080e7          	jalr	916(ra) # 800038ee <bread>
    80004562:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004564:	3ff97513          	andi	a0,s2,1023
    80004568:	40ac87bb          	subw	a5,s9,a0
    8000456c:	413b073b          	subw	a4,s6,s3
    80004570:	8d3e                	mv	s10,a5
    80004572:	2781                	sext.w	a5,a5
    80004574:	0007069b          	sext.w	a3,a4
    80004578:	f8f6f4e3          	bgeu	a3,a5,80004500 <writei+0x4c>
    8000457c:	8d3a                	mv	s10,a4
    8000457e:	b749                	j	80004500 <writei+0x4c>
      brelse(bp);
    80004580:	8526                	mv	a0,s1
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	49c080e7          	jalr	1180(ra) # 80003a1e <brelse>
  }

  if(off > ip->size)
    8000458a:	04caa783          	lw	a5,76(s5)
    8000458e:	0127f463          	bgeu	a5,s2,80004596 <writei+0xe2>
    ip->size = off;
    80004592:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004596:	8556                	mv	a0,s5
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	aa6080e7          	jalr	-1370(ra) # 8000403e <iupdate>

  return tot;
    800045a0:	0009851b          	sext.w	a0,s3
}
    800045a4:	70a6                	ld	ra,104(sp)
    800045a6:	7406                	ld	s0,96(sp)
    800045a8:	64e6                	ld	s1,88(sp)
    800045aa:	6946                	ld	s2,80(sp)
    800045ac:	69a6                	ld	s3,72(sp)
    800045ae:	6a06                	ld	s4,64(sp)
    800045b0:	7ae2                	ld	s5,56(sp)
    800045b2:	7b42                	ld	s6,48(sp)
    800045b4:	7ba2                	ld	s7,40(sp)
    800045b6:	7c02                	ld	s8,32(sp)
    800045b8:	6ce2                	ld	s9,24(sp)
    800045ba:	6d42                	ld	s10,16(sp)
    800045bc:	6da2                	ld	s11,8(sp)
    800045be:	6165                	addi	sp,sp,112
    800045c0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045c2:	89da                	mv	s3,s6
    800045c4:	bfc9                	j	80004596 <writei+0xe2>
    return -1;
    800045c6:	557d                	li	a0,-1
}
    800045c8:	8082                	ret
    return -1;
    800045ca:	557d                	li	a0,-1
    800045cc:	bfe1                	j	800045a4 <writei+0xf0>
    return -1;
    800045ce:	557d                	li	a0,-1
    800045d0:	bfd1                	j	800045a4 <writei+0xf0>

00000000800045d2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800045d2:	1141                	addi	sp,sp,-16
    800045d4:	e406                	sd	ra,8(sp)
    800045d6:	e022                	sd	s0,0(sp)
    800045d8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800045da:	4639                	li	a2,14
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	7c6080e7          	jalr	1990(ra) # 80000da2 <strncmp>
}
    800045e4:	60a2                	ld	ra,8(sp)
    800045e6:	6402                	ld	s0,0(sp)
    800045e8:	0141                	addi	sp,sp,16
    800045ea:	8082                	ret

00000000800045ec <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800045ec:	7139                	addi	sp,sp,-64
    800045ee:	fc06                	sd	ra,56(sp)
    800045f0:	f822                	sd	s0,48(sp)
    800045f2:	f426                	sd	s1,40(sp)
    800045f4:	f04a                	sd	s2,32(sp)
    800045f6:	ec4e                	sd	s3,24(sp)
    800045f8:	e852                	sd	s4,16(sp)
    800045fa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800045fc:	04451703          	lh	a4,68(a0)
    80004600:	4785                	li	a5,1
    80004602:	00f71a63          	bne	a4,a5,80004616 <dirlookup+0x2a>
    80004606:	892a                	mv	s2,a0
    80004608:	89ae                	mv	s3,a1
    8000460a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000460c:	457c                	lw	a5,76(a0)
    8000460e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004610:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004612:	e79d                	bnez	a5,80004640 <dirlookup+0x54>
    80004614:	a8a5                	j	8000468c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	1da50513          	addi	a0,a0,474 # 800087f0 <syscalls+0x368>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	1e250513          	addi	a0,a0,482 # 80008808 <syscalls+0x380>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004636:	24c1                	addiw	s1,s1,16
    80004638:	04c92783          	lw	a5,76(s2)
    8000463c:	04f4f763          	bgeu	s1,a5,8000468a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004640:	4741                	li	a4,16
    80004642:	86a6                	mv	a3,s1
    80004644:	fc040613          	addi	a2,s0,-64
    80004648:	4581                	li	a1,0
    8000464a:	854a                	mv	a0,s2
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	d70080e7          	jalr	-656(ra) # 800043bc <readi>
    80004654:	47c1                	li	a5,16
    80004656:	fcf518e3          	bne	a0,a5,80004626 <dirlookup+0x3a>
    if(de.inum == 0)
    8000465a:	fc045783          	lhu	a5,-64(s0)
    8000465e:	dfe1                	beqz	a5,80004636 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004660:	fc240593          	addi	a1,s0,-62
    80004664:	854e                	mv	a0,s3
    80004666:	00000097          	auipc	ra,0x0
    8000466a:	f6c080e7          	jalr	-148(ra) # 800045d2 <namecmp>
    8000466e:	f561                	bnez	a0,80004636 <dirlookup+0x4a>
      if(poff)
    80004670:	000a0463          	beqz	s4,80004678 <dirlookup+0x8c>
        *poff = off;
    80004674:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004678:	fc045583          	lhu	a1,-64(s0)
    8000467c:	00092503          	lw	a0,0(s2)
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	750080e7          	jalr	1872(ra) # 80003dd0 <iget>
    80004688:	a011                	j	8000468c <dirlookup+0xa0>
  return 0;
    8000468a:	4501                	li	a0,0
}
    8000468c:	70e2                	ld	ra,56(sp)
    8000468e:	7442                	ld	s0,48(sp)
    80004690:	74a2                	ld	s1,40(sp)
    80004692:	7902                	ld	s2,32(sp)
    80004694:	69e2                	ld	s3,24(sp)
    80004696:	6a42                	ld	s4,16(sp)
    80004698:	6121                	addi	sp,sp,64
    8000469a:	8082                	ret

000000008000469c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000469c:	711d                	addi	sp,sp,-96
    8000469e:	ec86                	sd	ra,88(sp)
    800046a0:	e8a2                	sd	s0,80(sp)
    800046a2:	e4a6                	sd	s1,72(sp)
    800046a4:	e0ca                	sd	s2,64(sp)
    800046a6:	fc4e                	sd	s3,56(sp)
    800046a8:	f852                	sd	s4,48(sp)
    800046aa:	f456                	sd	s5,40(sp)
    800046ac:	f05a                	sd	s6,32(sp)
    800046ae:	ec5e                	sd	s7,24(sp)
    800046b0:	e862                	sd	s8,16(sp)
    800046b2:	e466                	sd	s9,8(sp)
    800046b4:	1080                	addi	s0,sp,96
    800046b6:	84aa                	mv	s1,a0
    800046b8:	8aae                	mv	s5,a1
    800046ba:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800046bc:	00054703          	lbu	a4,0(a0)
    800046c0:	02f00793          	li	a5,47
    800046c4:	02f70363          	beq	a4,a5,800046ea <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800046c8:	ffffd097          	auipc	ra,0xffffd
    800046cc:	4d2080e7          	jalr	1234(ra) # 80001b9a <myproc>
    800046d0:	15053503          	ld	a0,336(a0)
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	9f6080e7          	jalr	-1546(ra) # 800040ca <idup>
    800046dc:	89aa                	mv	s3,a0
  while(*path == '/')
    800046de:	02f00913          	li	s2,47
  len = path - s;
    800046e2:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800046e4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800046e6:	4b85                	li	s7,1
    800046e8:	a865                	j	800047a0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800046ea:	4585                	li	a1,1
    800046ec:	4505                	li	a0,1
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	6e2080e7          	jalr	1762(ra) # 80003dd0 <iget>
    800046f6:	89aa                	mv	s3,a0
    800046f8:	b7dd                	j	800046de <namex+0x42>
      iunlockput(ip);
    800046fa:	854e                	mv	a0,s3
    800046fc:	00000097          	auipc	ra,0x0
    80004700:	c6e080e7          	jalr	-914(ra) # 8000436a <iunlockput>
      return 0;
    80004704:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004706:	854e                	mv	a0,s3
    80004708:	60e6                	ld	ra,88(sp)
    8000470a:	6446                	ld	s0,80(sp)
    8000470c:	64a6                	ld	s1,72(sp)
    8000470e:	6906                	ld	s2,64(sp)
    80004710:	79e2                	ld	s3,56(sp)
    80004712:	7a42                	ld	s4,48(sp)
    80004714:	7aa2                	ld	s5,40(sp)
    80004716:	7b02                	ld	s6,32(sp)
    80004718:	6be2                	ld	s7,24(sp)
    8000471a:	6c42                	ld	s8,16(sp)
    8000471c:	6ca2                	ld	s9,8(sp)
    8000471e:	6125                	addi	sp,sp,96
    80004720:	8082                	ret
      iunlock(ip);
    80004722:	854e                	mv	a0,s3
    80004724:	00000097          	auipc	ra,0x0
    80004728:	aa6080e7          	jalr	-1370(ra) # 800041ca <iunlock>
      return ip;
    8000472c:	bfe9                	j	80004706 <namex+0x6a>
      iunlockput(ip);
    8000472e:	854e                	mv	a0,s3
    80004730:	00000097          	auipc	ra,0x0
    80004734:	c3a080e7          	jalr	-966(ra) # 8000436a <iunlockput>
      return 0;
    80004738:	89e6                	mv	s3,s9
    8000473a:	b7f1                	j	80004706 <namex+0x6a>
  len = path - s;
    8000473c:	40b48633          	sub	a2,s1,a1
    80004740:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004744:	099c5463          	bge	s8,s9,800047cc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004748:	4639                	li	a2,14
    8000474a:	8552                	mv	a0,s4
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	5e2080e7          	jalr	1506(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004754:	0004c783          	lbu	a5,0(s1)
    80004758:	01279763          	bne	a5,s2,80004766 <namex+0xca>
    path++;
    8000475c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000475e:	0004c783          	lbu	a5,0(s1)
    80004762:	ff278de3          	beq	a5,s2,8000475c <namex+0xc0>
    ilock(ip);
    80004766:	854e                	mv	a0,s3
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	9a0080e7          	jalr	-1632(ra) # 80004108 <ilock>
    if(ip->type != T_DIR){
    80004770:	04499783          	lh	a5,68(s3)
    80004774:	f97793e3          	bne	a5,s7,800046fa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004778:	000a8563          	beqz	s5,80004782 <namex+0xe6>
    8000477c:	0004c783          	lbu	a5,0(s1)
    80004780:	d3cd                	beqz	a5,80004722 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004782:	865a                	mv	a2,s6
    80004784:	85d2                	mv	a1,s4
    80004786:	854e                	mv	a0,s3
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	e64080e7          	jalr	-412(ra) # 800045ec <dirlookup>
    80004790:	8caa                	mv	s9,a0
    80004792:	dd51                	beqz	a0,8000472e <namex+0x92>
    iunlockput(ip);
    80004794:	854e                	mv	a0,s3
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	bd4080e7          	jalr	-1068(ra) # 8000436a <iunlockput>
    ip = next;
    8000479e:	89e6                	mv	s3,s9
  while(*path == '/')
    800047a0:	0004c783          	lbu	a5,0(s1)
    800047a4:	05279763          	bne	a5,s2,800047f2 <namex+0x156>
    path++;
    800047a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800047aa:	0004c783          	lbu	a5,0(s1)
    800047ae:	ff278de3          	beq	a5,s2,800047a8 <namex+0x10c>
  if(*path == 0)
    800047b2:	c79d                	beqz	a5,800047e0 <namex+0x144>
    path++;
    800047b4:	85a6                	mv	a1,s1
  len = path - s;
    800047b6:	8cda                	mv	s9,s6
    800047b8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800047ba:	01278963          	beq	a5,s2,800047cc <namex+0x130>
    800047be:	dfbd                	beqz	a5,8000473c <namex+0xa0>
    path++;
    800047c0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800047c2:	0004c783          	lbu	a5,0(s1)
    800047c6:	ff279ce3          	bne	a5,s2,800047be <namex+0x122>
    800047ca:	bf8d                	j	8000473c <namex+0xa0>
    memmove(name, s, len);
    800047cc:	2601                	sext.w	a2,a2
    800047ce:	8552                	mv	a0,s4
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	55e080e7          	jalr	1374(ra) # 80000d2e <memmove>
    name[len] = 0;
    800047d8:	9cd2                	add	s9,s9,s4
    800047da:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800047de:	bf9d                	j	80004754 <namex+0xb8>
  if(nameiparent){
    800047e0:	f20a83e3          	beqz	s5,80004706 <namex+0x6a>
    iput(ip);
    800047e4:	854e                	mv	a0,s3
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	adc080e7          	jalr	-1316(ra) # 800042c2 <iput>
    return 0;
    800047ee:	4981                	li	s3,0
    800047f0:	bf19                	j	80004706 <namex+0x6a>
  if(*path == 0)
    800047f2:	d7fd                	beqz	a5,800047e0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800047f4:	0004c783          	lbu	a5,0(s1)
    800047f8:	85a6                	mv	a1,s1
    800047fa:	b7d1                	j	800047be <namex+0x122>

00000000800047fc <dirlink>:
{
    800047fc:	7139                	addi	sp,sp,-64
    800047fe:	fc06                	sd	ra,56(sp)
    80004800:	f822                	sd	s0,48(sp)
    80004802:	f426                	sd	s1,40(sp)
    80004804:	f04a                	sd	s2,32(sp)
    80004806:	ec4e                	sd	s3,24(sp)
    80004808:	e852                	sd	s4,16(sp)
    8000480a:	0080                	addi	s0,sp,64
    8000480c:	892a                	mv	s2,a0
    8000480e:	8a2e                	mv	s4,a1
    80004810:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004812:	4601                	li	a2,0
    80004814:	00000097          	auipc	ra,0x0
    80004818:	dd8080e7          	jalr	-552(ra) # 800045ec <dirlookup>
    8000481c:	e93d                	bnez	a0,80004892 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000481e:	04c92483          	lw	s1,76(s2)
    80004822:	c49d                	beqz	s1,80004850 <dirlink+0x54>
    80004824:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004826:	4741                	li	a4,16
    80004828:	86a6                	mv	a3,s1
    8000482a:	fc040613          	addi	a2,s0,-64
    8000482e:	4581                	li	a1,0
    80004830:	854a                	mv	a0,s2
    80004832:	00000097          	auipc	ra,0x0
    80004836:	b8a080e7          	jalr	-1142(ra) # 800043bc <readi>
    8000483a:	47c1                	li	a5,16
    8000483c:	06f51163          	bne	a0,a5,8000489e <dirlink+0xa2>
    if(de.inum == 0)
    80004840:	fc045783          	lhu	a5,-64(s0)
    80004844:	c791                	beqz	a5,80004850 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004846:	24c1                	addiw	s1,s1,16
    80004848:	04c92783          	lw	a5,76(s2)
    8000484c:	fcf4ede3          	bltu	s1,a5,80004826 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004850:	4639                	li	a2,14
    80004852:	85d2                	mv	a1,s4
    80004854:	fc240513          	addi	a0,s0,-62
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	586080e7          	jalr	1414(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004860:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004864:	4741                	li	a4,16
    80004866:	86a6                	mv	a3,s1
    80004868:	fc040613          	addi	a2,s0,-64
    8000486c:	4581                	li	a1,0
    8000486e:	854a                	mv	a0,s2
    80004870:	00000097          	auipc	ra,0x0
    80004874:	c44080e7          	jalr	-956(ra) # 800044b4 <writei>
    80004878:	1541                	addi	a0,a0,-16
    8000487a:	00a03533          	snez	a0,a0
    8000487e:	40a00533          	neg	a0,a0
}
    80004882:	70e2                	ld	ra,56(sp)
    80004884:	7442                	ld	s0,48(sp)
    80004886:	74a2                	ld	s1,40(sp)
    80004888:	7902                	ld	s2,32(sp)
    8000488a:	69e2                	ld	s3,24(sp)
    8000488c:	6a42                	ld	s4,16(sp)
    8000488e:	6121                	addi	sp,sp,64
    80004890:	8082                	ret
    iput(ip);
    80004892:	00000097          	auipc	ra,0x0
    80004896:	a30080e7          	jalr	-1488(ra) # 800042c2 <iput>
    return -1;
    8000489a:	557d                	li	a0,-1
    8000489c:	b7dd                	j	80004882 <dirlink+0x86>
      panic("dirlink read");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	f7a50513          	addi	a0,a0,-134 # 80008818 <syscalls+0x390>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c98080e7          	jalr	-872(ra) # 8000053e <panic>

00000000800048ae <namei>:

struct inode*
namei(char *path)
{
    800048ae:	1101                	addi	sp,sp,-32
    800048b0:	ec06                	sd	ra,24(sp)
    800048b2:	e822                	sd	s0,16(sp)
    800048b4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800048b6:	fe040613          	addi	a2,s0,-32
    800048ba:	4581                	li	a1,0
    800048bc:	00000097          	auipc	ra,0x0
    800048c0:	de0080e7          	jalr	-544(ra) # 8000469c <namex>
}
    800048c4:	60e2                	ld	ra,24(sp)
    800048c6:	6442                	ld	s0,16(sp)
    800048c8:	6105                	addi	sp,sp,32
    800048ca:	8082                	ret

00000000800048cc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800048cc:	1141                	addi	sp,sp,-16
    800048ce:	e406                	sd	ra,8(sp)
    800048d0:	e022                	sd	s0,0(sp)
    800048d2:	0800                	addi	s0,sp,16
    800048d4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800048d6:	4585                	li	a1,1
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	dc4080e7          	jalr	-572(ra) # 8000469c <namex>
}
    800048e0:	60a2                	ld	ra,8(sp)
    800048e2:	6402                	ld	s0,0(sp)
    800048e4:	0141                	addi	sp,sp,16
    800048e6:	8082                	ret

00000000800048e8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800048e8:	1101                	addi	sp,sp,-32
    800048ea:	ec06                	sd	ra,24(sp)
    800048ec:	e822                	sd	s0,16(sp)
    800048ee:	e426                	sd	s1,8(sp)
    800048f0:	e04a                	sd	s2,0(sp)
    800048f2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048f4:	00022917          	auipc	s2,0x22
    800048f8:	f2c90913          	addi	s2,s2,-212 # 80026820 <log>
    800048fc:	01892583          	lw	a1,24(s2)
    80004900:	02892503          	lw	a0,40(s2)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	fea080e7          	jalr	-22(ra) # 800038ee <bread>
    8000490c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000490e:	02c92683          	lw	a3,44(s2)
    80004912:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004914:	02d05763          	blez	a3,80004942 <write_head+0x5a>
    80004918:	00022797          	auipc	a5,0x22
    8000491c:	f3878793          	addi	a5,a5,-200 # 80026850 <log+0x30>
    80004920:	05c50713          	addi	a4,a0,92
    80004924:	36fd                	addiw	a3,a3,-1
    80004926:	1682                	slli	a3,a3,0x20
    80004928:	9281                	srli	a3,a3,0x20
    8000492a:	068a                	slli	a3,a3,0x2
    8000492c:	00022617          	auipc	a2,0x22
    80004930:	f2860613          	addi	a2,a2,-216 # 80026854 <log+0x34>
    80004934:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004936:	4390                	lw	a2,0(a5)
    80004938:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000493a:	0791                	addi	a5,a5,4
    8000493c:	0711                	addi	a4,a4,4
    8000493e:	fed79ce3          	bne	a5,a3,80004936 <write_head+0x4e>
  }
  bwrite(buf);
    80004942:	8526                	mv	a0,s1
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	09c080e7          	jalr	156(ra) # 800039e0 <bwrite>
  brelse(buf);
    8000494c:	8526                	mv	a0,s1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	0d0080e7          	jalr	208(ra) # 80003a1e <brelse>
}
    80004956:	60e2                	ld	ra,24(sp)
    80004958:	6442                	ld	s0,16(sp)
    8000495a:	64a2                	ld	s1,8(sp)
    8000495c:	6902                	ld	s2,0(sp)
    8000495e:	6105                	addi	sp,sp,32
    80004960:	8082                	ret

0000000080004962 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004962:	00022797          	auipc	a5,0x22
    80004966:	eea7a783          	lw	a5,-278(a5) # 8002684c <log+0x2c>
    8000496a:	0af05d63          	blez	a5,80004a24 <install_trans+0xc2>
{
    8000496e:	7139                	addi	sp,sp,-64
    80004970:	fc06                	sd	ra,56(sp)
    80004972:	f822                	sd	s0,48(sp)
    80004974:	f426                	sd	s1,40(sp)
    80004976:	f04a                	sd	s2,32(sp)
    80004978:	ec4e                	sd	s3,24(sp)
    8000497a:	e852                	sd	s4,16(sp)
    8000497c:	e456                	sd	s5,8(sp)
    8000497e:	e05a                	sd	s6,0(sp)
    80004980:	0080                	addi	s0,sp,64
    80004982:	8b2a                	mv	s6,a0
    80004984:	00022a97          	auipc	s5,0x22
    80004988:	ecca8a93          	addi	s5,s5,-308 # 80026850 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000498c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000498e:	00022997          	auipc	s3,0x22
    80004992:	e9298993          	addi	s3,s3,-366 # 80026820 <log>
    80004996:	a00d                	j	800049b8 <install_trans+0x56>
    brelse(lbuf);
    80004998:	854a                	mv	a0,s2
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	084080e7          	jalr	132(ra) # 80003a1e <brelse>
    brelse(dbuf);
    800049a2:	8526                	mv	a0,s1
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	07a080e7          	jalr	122(ra) # 80003a1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ac:	2a05                	addiw	s4,s4,1
    800049ae:	0a91                	addi	s5,s5,4
    800049b0:	02c9a783          	lw	a5,44(s3)
    800049b4:	04fa5e63          	bge	s4,a5,80004a10 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049b8:	0189a583          	lw	a1,24(s3)
    800049bc:	014585bb          	addw	a1,a1,s4
    800049c0:	2585                	addiw	a1,a1,1
    800049c2:	0289a503          	lw	a0,40(s3)
    800049c6:	fffff097          	auipc	ra,0xfffff
    800049ca:	f28080e7          	jalr	-216(ra) # 800038ee <bread>
    800049ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800049d0:	000aa583          	lw	a1,0(s5)
    800049d4:	0289a503          	lw	a0,40(s3)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	f16080e7          	jalr	-234(ra) # 800038ee <bread>
    800049e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800049e2:	40000613          	li	a2,1024
    800049e6:	05890593          	addi	a1,s2,88
    800049ea:	05850513          	addi	a0,a0,88
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	340080e7          	jalr	832(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800049f6:	8526                	mv	a0,s1
    800049f8:	fffff097          	auipc	ra,0xfffff
    800049fc:	fe8080e7          	jalr	-24(ra) # 800039e0 <bwrite>
    if(recovering == 0)
    80004a00:	f80b1ce3          	bnez	s6,80004998 <install_trans+0x36>
      bunpin(dbuf);
    80004a04:	8526                	mv	a0,s1
    80004a06:	fffff097          	auipc	ra,0xfffff
    80004a0a:	0f2080e7          	jalr	242(ra) # 80003af8 <bunpin>
    80004a0e:	b769                	j	80004998 <install_trans+0x36>
}
    80004a10:	70e2                	ld	ra,56(sp)
    80004a12:	7442                	ld	s0,48(sp)
    80004a14:	74a2                	ld	s1,40(sp)
    80004a16:	7902                	ld	s2,32(sp)
    80004a18:	69e2                	ld	s3,24(sp)
    80004a1a:	6a42                	ld	s4,16(sp)
    80004a1c:	6aa2                	ld	s5,8(sp)
    80004a1e:	6b02                	ld	s6,0(sp)
    80004a20:	6121                	addi	sp,sp,64
    80004a22:	8082                	ret
    80004a24:	8082                	ret

0000000080004a26 <initlog>:
{
    80004a26:	7179                	addi	sp,sp,-48
    80004a28:	f406                	sd	ra,40(sp)
    80004a2a:	f022                	sd	s0,32(sp)
    80004a2c:	ec26                	sd	s1,24(sp)
    80004a2e:	e84a                	sd	s2,16(sp)
    80004a30:	e44e                	sd	s3,8(sp)
    80004a32:	1800                	addi	s0,sp,48
    80004a34:	892a                	mv	s2,a0
    80004a36:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a38:	00022497          	auipc	s1,0x22
    80004a3c:	de848493          	addi	s1,s1,-536 # 80026820 <log>
    80004a40:	00004597          	auipc	a1,0x4
    80004a44:	de858593          	addi	a1,a1,-536 # 80008828 <syscalls+0x3a0>
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	0fc080e7          	jalr	252(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004a52:	0149a583          	lw	a1,20(s3)
    80004a56:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a58:	0109a783          	lw	a5,16(s3)
    80004a5c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a5e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a62:	854a                	mv	a0,s2
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	e8a080e7          	jalr	-374(ra) # 800038ee <bread>
  log.lh.n = lh->n;
    80004a6c:	4d34                	lw	a3,88(a0)
    80004a6e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a70:	02d05563          	blez	a3,80004a9a <initlog+0x74>
    80004a74:	05c50793          	addi	a5,a0,92
    80004a78:	00022717          	auipc	a4,0x22
    80004a7c:	dd870713          	addi	a4,a4,-552 # 80026850 <log+0x30>
    80004a80:	36fd                	addiw	a3,a3,-1
    80004a82:	1682                	slli	a3,a3,0x20
    80004a84:	9281                	srli	a3,a3,0x20
    80004a86:	068a                	slli	a3,a3,0x2
    80004a88:	06050613          	addi	a2,a0,96
    80004a8c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004a8e:	4390                	lw	a2,0(a5)
    80004a90:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a92:	0791                	addi	a5,a5,4
    80004a94:	0711                	addi	a4,a4,4
    80004a96:	fed79ce3          	bne	a5,a3,80004a8e <initlog+0x68>
  brelse(buf);
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	f84080e7          	jalr	-124(ra) # 80003a1e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004aa2:	4505                	li	a0,1
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	ebe080e7          	jalr	-322(ra) # 80004962 <install_trans>
  log.lh.n = 0;
    80004aac:	00022797          	auipc	a5,0x22
    80004ab0:	da07a023          	sw	zero,-608(a5) # 8002684c <log+0x2c>
  write_head(); // clear the log
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	e34080e7          	jalr	-460(ra) # 800048e8 <write_head>
}
    80004abc:	70a2                	ld	ra,40(sp)
    80004abe:	7402                	ld	s0,32(sp)
    80004ac0:	64e2                	ld	s1,24(sp)
    80004ac2:	6942                	ld	s2,16(sp)
    80004ac4:	69a2                	ld	s3,8(sp)
    80004ac6:	6145                	addi	sp,sp,48
    80004ac8:	8082                	ret

0000000080004aca <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004aca:	1101                	addi	sp,sp,-32
    80004acc:	ec06                	sd	ra,24(sp)
    80004ace:	e822                	sd	s0,16(sp)
    80004ad0:	e426                	sd	s1,8(sp)
    80004ad2:	e04a                	sd	s2,0(sp)
    80004ad4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ad6:	00022517          	auipc	a0,0x22
    80004ada:	d4a50513          	addi	a0,a0,-694 # 80026820 <log>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	0f8080e7          	jalr	248(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004ae6:	00022497          	auipc	s1,0x22
    80004aea:	d3a48493          	addi	s1,s1,-710 # 80026820 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004aee:	4979                	li	s2,30
    80004af0:	a039                	j	80004afe <begin_op+0x34>
      sleep(&log, &log.lock);
    80004af2:	85a6                	mv	a1,s1
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	958080e7          	jalr	-1704(ra) # 8000244e <sleep>
    if(log.committing){
    80004afe:	50dc                	lw	a5,36(s1)
    80004b00:	fbed                	bnez	a5,80004af2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b02:	509c                	lw	a5,32(s1)
    80004b04:	0017871b          	addiw	a4,a5,1
    80004b08:	0007069b          	sext.w	a3,a4
    80004b0c:	0027179b          	slliw	a5,a4,0x2
    80004b10:	9fb9                	addw	a5,a5,a4
    80004b12:	0017979b          	slliw	a5,a5,0x1
    80004b16:	54d8                	lw	a4,44(s1)
    80004b18:	9fb9                	addw	a5,a5,a4
    80004b1a:	00f95963          	bge	s2,a5,80004b2c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b1e:	85a6                	mv	a1,s1
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffe097          	auipc	ra,0xffffe
    80004b26:	92c080e7          	jalr	-1748(ra) # 8000244e <sleep>
    80004b2a:	bfd1                	j	80004afe <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b2c:	00022517          	auipc	a0,0x22
    80004b30:	cf450513          	addi	a0,a0,-780 # 80026820 <log>
    80004b34:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	154080e7          	jalr	340(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret

0000000080004b4a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b4a:	7139                	addi	sp,sp,-64
    80004b4c:	fc06                	sd	ra,56(sp)
    80004b4e:	f822                	sd	s0,48(sp)
    80004b50:	f426                	sd	s1,40(sp)
    80004b52:	f04a                	sd	s2,32(sp)
    80004b54:	ec4e                	sd	s3,24(sp)
    80004b56:	e852                	sd	s4,16(sp)
    80004b58:	e456                	sd	s5,8(sp)
    80004b5a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b5c:	00022497          	auipc	s1,0x22
    80004b60:	cc448493          	addi	s1,s1,-828 # 80026820 <log>
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	070080e7          	jalr	112(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004b6e:	509c                	lw	a5,32(s1)
    80004b70:	37fd                	addiw	a5,a5,-1
    80004b72:	0007891b          	sext.w	s2,a5
    80004b76:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b78:	50dc                	lw	a5,36(s1)
    80004b7a:	e7b9                	bnez	a5,80004bc8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b7c:	04091e63          	bnez	s2,80004bd8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b80:	00022497          	auipc	s1,0x22
    80004b84:	ca048493          	addi	s1,s1,-864 # 80026820 <log>
    80004b88:	4785                	li	a5,1
    80004b8a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	0fc080e7          	jalr	252(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b96:	54dc                	lw	a5,44(s1)
    80004b98:	06f04763          	bgtz	a5,80004c06 <end_op+0xbc>
    acquire(&log.lock);
    80004b9c:	00022497          	auipc	s1,0x22
    80004ba0:	c8448493          	addi	s1,s1,-892 # 80026820 <log>
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	030080e7          	jalr	48(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004bae:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffe097          	auipc	ra,0xffffe
    80004bb8:	8fe080e7          	jalr	-1794(ra) # 800024b2 <wakeup>
    release(&log.lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	0cc080e7          	jalr	204(ra) # 80000c8a <release>
}
    80004bc6:	a03d                	j	80004bf4 <end_op+0xaa>
    panic("log.committing");
    80004bc8:	00004517          	auipc	a0,0x4
    80004bcc:	c6850513          	addi	a0,a0,-920 # 80008830 <syscalls+0x3a8>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>
    wakeup(&log);
    80004bd8:	00022497          	auipc	s1,0x22
    80004bdc:	c4848493          	addi	s1,s1,-952 # 80026820 <log>
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffe097          	auipc	ra,0xffffe
    80004be6:	8d0080e7          	jalr	-1840(ra) # 800024b2 <wakeup>
  release(&log.lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	09e080e7          	jalr	158(ra) # 80000c8a <release>
}
    80004bf4:	70e2                	ld	ra,56(sp)
    80004bf6:	7442                	ld	s0,48(sp)
    80004bf8:	74a2                	ld	s1,40(sp)
    80004bfa:	7902                	ld	s2,32(sp)
    80004bfc:	69e2                	ld	s3,24(sp)
    80004bfe:	6a42                	ld	s4,16(sp)
    80004c00:	6aa2                	ld	s5,8(sp)
    80004c02:	6121                	addi	sp,sp,64
    80004c04:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c06:	00022a97          	auipc	s5,0x22
    80004c0a:	c4aa8a93          	addi	s5,s5,-950 # 80026850 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c0e:	00022a17          	auipc	s4,0x22
    80004c12:	c12a0a13          	addi	s4,s4,-1006 # 80026820 <log>
    80004c16:	018a2583          	lw	a1,24(s4)
    80004c1a:	012585bb          	addw	a1,a1,s2
    80004c1e:	2585                	addiw	a1,a1,1
    80004c20:	028a2503          	lw	a0,40(s4)
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	cca080e7          	jalr	-822(ra) # 800038ee <bread>
    80004c2c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c2e:	000aa583          	lw	a1,0(s5)
    80004c32:	028a2503          	lw	a0,40(s4)
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	cb8080e7          	jalr	-840(ra) # 800038ee <bread>
    80004c3e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c40:	40000613          	li	a2,1024
    80004c44:	05850593          	addi	a1,a0,88
    80004c48:	05848513          	addi	a0,s1,88
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	0e2080e7          	jalr	226(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004c54:	8526                	mv	a0,s1
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	d8a080e7          	jalr	-630(ra) # 800039e0 <bwrite>
    brelse(from);
    80004c5e:	854e                	mv	a0,s3
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	dbe080e7          	jalr	-578(ra) # 80003a1e <brelse>
    brelse(to);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	db4080e7          	jalr	-588(ra) # 80003a1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c72:	2905                	addiw	s2,s2,1
    80004c74:	0a91                	addi	s5,s5,4
    80004c76:	02ca2783          	lw	a5,44(s4)
    80004c7a:	f8f94ee3          	blt	s2,a5,80004c16 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	c6a080e7          	jalr	-918(ra) # 800048e8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004c86:	4501                	li	a0,0
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	cda080e7          	jalr	-806(ra) # 80004962 <install_trans>
    log.lh.n = 0;
    80004c90:	00022797          	auipc	a5,0x22
    80004c94:	ba07ae23          	sw	zero,-1092(a5) # 8002684c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c98:	00000097          	auipc	ra,0x0
    80004c9c:	c50080e7          	jalr	-944(ra) # 800048e8 <write_head>
    80004ca0:	bdf5                	j	80004b9c <end_op+0x52>

0000000080004ca2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ca2:	1101                	addi	sp,sp,-32
    80004ca4:	ec06                	sd	ra,24(sp)
    80004ca6:	e822                	sd	s0,16(sp)
    80004ca8:	e426                	sd	s1,8(sp)
    80004caa:	e04a                	sd	s2,0(sp)
    80004cac:	1000                	addi	s0,sp,32
    80004cae:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004cb0:	00022917          	auipc	s2,0x22
    80004cb4:	b7090913          	addi	s2,s2,-1168 # 80026820 <log>
    80004cb8:	854a                	mv	a0,s2
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f1c080e7          	jalr	-228(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004cc2:	02c92603          	lw	a2,44(s2)
    80004cc6:	47f5                	li	a5,29
    80004cc8:	06c7c563          	blt	a5,a2,80004d32 <log_write+0x90>
    80004ccc:	00022797          	auipc	a5,0x22
    80004cd0:	b707a783          	lw	a5,-1168(a5) # 8002683c <log+0x1c>
    80004cd4:	37fd                	addiw	a5,a5,-1
    80004cd6:	04f65e63          	bge	a2,a5,80004d32 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004cda:	00022797          	auipc	a5,0x22
    80004cde:	b667a783          	lw	a5,-1178(a5) # 80026840 <log+0x20>
    80004ce2:	06f05063          	blez	a5,80004d42 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ce6:	4781                	li	a5,0
    80004ce8:	06c05563          	blez	a2,80004d52 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cec:	44cc                	lw	a1,12(s1)
    80004cee:	00022717          	auipc	a4,0x22
    80004cf2:	b6270713          	addi	a4,a4,-1182 # 80026850 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cf6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cf8:	4314                	lw	a3,0(a4)
    80004cfa:	04b68c63          	beq	a3,a1,80004d52 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cfe:	2785                	addiw	a5,a5,1
    80004d00:	0711                	addi	a4,a4,4
    80004d02:	fef61be3          	bne	a2,a5,80004cf8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d06:	0621                	addi	a2,a2,8
    80004d08:	060a                	slli	a2,a2,0x2
    80004d0a:	00022797          	auipc	a5,0x22
    80004d0e:	b1678793          	addi	a5,a5,-1258 # 80026820 <log>
    80004d12:	963e                	add	a2,a2,a5
    80004d14:	44dc                	lw	a5,12(s1)
    80004d16:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	da2080e7          	jalr	-606(ra) # 80003abc <bpin>
    log.lh.n++;
    80004d22:	00022717          	auipc	a4,0x22
    80004d26:	afe70713          	addi	a4,a4,-1282 # 80026820 <log>
    80004d2a:	575c                	lw	a5,44(a4)
    80004d2c:	2785                	addiw	a5,a5,1
    80004d2e:	d75c                	sw	a5,44(a4)
    80004d30:	a835                	j	80004d6c <log_write+0xca>
    panic("too big a transaction");
    80004d32:	00004517          	auipc	a0,0x4
    80004d36:	b0e50513          	addi	a0,a0,-1266 # 80008840 <syscalls+0x3b8>
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004d42:	00004517          	auipc	a0,0x4
    80004d46:	b1650513          	addi	a0,a0,-1258 # 80008858 <syscalls+0x3d0>
    80004d4a:	ffffb097          	auipc	ra,0xffffb
    80004d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004d52:	00878713          	addi	a4,a5,8
    80004d56:	00271693          	slli	a3,a4,0x2
    80004d5a:	00022717          	auipc	a4,0x22
    80004d5e:	ac670713          	addi	a4,a4,-1338 # 80026820 <log>
    80004d62:	9736                	add	a4,a4,a3
    80004d64:	44d4                	lw	a3,12(s1)
    80004d66:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d68:	faf608e3          	beq	a2,a5,80004d18 <log_write+0x76>
  }
  release(&log.lock);
    80004d6c:	00022517          	auipc	a0,0x22
    80004d70:	ab450513          	addi	a0,a0,-1356 # 80026820 <log>
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f16080e7          	jalr	-234(ra) # 80000c8a <release>
}
    80004d7c:	60e2                	ld	ra,24(sp)
    80004d7e:	6442                	ld	s0,16(sp)
    80004d80:	64a2                	ld	s1,8(sp)
    80004d82:	6902                	ld	s2,0(sp)
    80004d84:	6105                	addi	sp,sp,32
    80004d86:	8082                	ret

0000000080004d88 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d88:	1101                	addi	sp,sp,-32
    80004d8a:	ec06                	sd	ra,24(sp)
    80004d8c:	e822                	sd	s0,16(sp)
    80004d8e:	e426                	sd	s1,8(sp)
    80004d90:	e04a                	sd	s2,0(sp)
    80004d92:	1000                	addi	s0,sp,32
    80004d94:	84aa                	mv	s1,a0
    80004d96:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d98:	00004597          	auipc	a1,0x4
    80004d9c:	ae058593          	addi	a1,a1,-1312 # 80008878 <syscalls+0x3f0>
    80004da0:	0521                	addi	a0,a0,8
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	da4080e7          	jalr	-604(ra) # 80000b46 <initlock>
  lk->name = name;
    80004daa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004dae:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004db2:	0204a423          	sw	zero,40(s1)
}
    80004db6:	60e2                	ld	ra,24(sp)
    80004db8:	6442                	ld	s0,16(sp)
    80004dba:	64a2                	ld	s1,8(sp)
    80004dbc:	6902                	ld	s2,0(sp)
    80004dbe:	6105                	addi	sp,sp,32
    80004dc0:	8082                	ret

0000000080004dc2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004dc2:	1101                	addi	sp,sp,-32
    80004dc4:	ec06                	sd	ra,24(sp)
    80004dc6:	e822                	sd	s0,16(sp)
    80004dc8:	e426                	sd	s1,8(sp)
    80004dca:	e04a                	sd	s2,0(sp)
    80004dcc:	1000                	addi	s0,sp,32
    80004dce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004dd0:	00850913          	addi	s2,a0,8
    80004dd4:	854a                	mv	a0,s2
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	e00080e7          	jalr	-512(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004dde:	409c                	lw	a5,0(s1)
    80004de0:	cb89                	beqz	a5,80004df2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004de2:	85ca                	mv	a1,s2
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	668080e7          	jalr	1640(ra) # 8000244e <sleep>
  while (lk->locked) {
    80004dee:	409c                	lw	a5,0(s1)
    80004df0:	fbed                	bnez	a5,80004de2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004df2:	4785                	li	a5,1
    80004df4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	da4080e7          	jalr	-604(ra) # 80001b9a <myproc>
    80004dfe:	591c                	lw	a5,48(a0)
    80004e00:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e02:	854a                	mv	a0,s2
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	e86080e7          	jalr	-378(ra) # 80000c8a <release>
}
    80004e0c:	60e2                	ld	ra,24(sp)
    80004e0e:	6442                	ld	s0,16(sp)
    80004e10:	64a2                	ld	s1,8(sp)
    80004e12:	6902                	ld	s2,0(sp)
    80004e14:	6105                	addi	sp,sp,32
    80004e16:	8082                	ret

0000000080004e18 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e18:	1101                	addi	sp,sp,-32
    80004e1a:	ec06                	sd	ra,24(sp)
    80004e1c:	e822                	sd	s0,16(sp)
    80004e1e:	e426                	sd	s1,8(sp)
    80004e20:	e04a                	sd	s2,0(sp)
    80004e22:	1000                	addi	s0,sp,32
    80004e24:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e26:	00850913          	addi	s2,a0,8
    80004e2a:	854a                	mv	a0,s2
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	daa080e7          	jalr	-598(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004e34:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e38:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	674080e7          	jalr	1652(ra) # 800024b2 <wakeup>
  release(&lk->lk);
    80004e46:	854a                	mv	a0,s2
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
}
    80004e50:	60e2                	ld	ra,24(sp)
    80004e52:	6442                	ld	s0,16(sp)
    80004e54:	64a2                	ld	s1,8(sp)
    80004e56:	6902                	ld	s2,0(sp)
    80004e58:	6105                	addi	sp,sp,32
    80004e5a:	8082                	ret

0000000080004e5c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e5c:	7179                	addi	sp,sp,-48
    80004e5e:	f406                	sd	ra,40(sp)
    80004e60:	f022                	sd	s0,32(sp)
    80004e62:	ec26                	sd	s1,24(sp)
    80004e64:	e84a                	sd	s2,16(sp)
    80004e66:	e44e                	sd	s3,8(sp)
    80004e68:	1800                	addi	s0,sp,48
    80004e6a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e6c:	00850913          	addi	s2,a0,8
    80004e70:	854a                	mv	a0,s2
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e7a:	409c                	lw	a5,0(s1)
    80004e7c:	ef99                	bnez	a5,80004e9a <holdingsleep+0x3e>
    80004e7e:	4481                	li	s1,0
  release(&lk->lk);
    80004e80:	854a                	mv	a0,s2
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
  return r;
}
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	70a2                	ld	ra,40(sp)
    80004e8e:	7402                	ld	s0,32(sp)
    80004e90:	64e2                	ld	s1,24(sp)
    80004e92:	6942                	ld	s2,16(sp)
    80004e94:	69a2                	ld	s3,8(sp)
    80004e96:	6145                	addi	sp,sp,48
    80004e98:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e9a:	0284a983          	lw	s3,40(s1)
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	cfc080e7          	jalr	-772(ra) # 80001b9a <myproc>
    80004ea6:	5904                	lw	s1,48(a0)
    80004ea8:	413484b3          	sub	s1,s1,s3
    80004eac:	0014b493          	seqz	s1,s1
    80004eb0:	bfc1                	j	80004e80 <holdingsleep+0x24>

0000000080004eb2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004eb2:	1141                	addi	sp,sp,-16
    80004eb4:	e406                	sd	ra,8(sp)
    80004eb6:	e022                	sd	s0,0(sp)
    80004eb8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004eba:	00004597          	auipc	a1,0x4
    80004ebe:	9ce58593          	addi	a1,a1,-1586 # 80008888 <syscalls+0x400>
    80004ec2:	00022517          	auipc	a0,0x22
    80004ec6:	aa650513          	addi	a0,a0,-1370 # 80026968 <ftable>
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	c7c080e7          	jalr	-900(ra) # 80000b46 <initlock>
}
    80004ed2:	60a2                	ld	ra,8(sp)
    80004ed4:	6402                	ld	s0,0(sp)
    80004ed6:	0141                	addi	sp,sp,16
    80004ed8:	8082                	ret

0000000080004eda <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004eda:	1101                	addi	sp,sp,-32
    80004edc:	ec06                	sd	ra,24(sp)
    80004ede:	e822                	sd	s0,16(sp)
    80004ee0:	e426                	sd	s1,8(sp)
    80004ee2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ee4:	00022517          	auipc	a0,0x22
    80004ee8:	a8450513          	addi	a0,a0,-1404 # 80026968 <ftable>
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	cea080e7          	jalr	-790(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ef4:	00022497          	auipc	s1,0x22
    80004ef8:	a8c48493          	addi	s1,s1,-1396 # 80026980 <ftable+0x18>
    80004efc:	00023717          	auipc	a4,0x23
    80004f00:	a2470713          	addi	a4,a4,-1500 # 80027920 <disk>
    if(f->ref == 0){
    80004f04:	40dc                	lw	a5,4(s1)
    80004f06:	cf99                	beqz	a5,80004f24 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f08:	02848493          	addi	s1,s1,40
    80004f0c:	fee49ce3          	bne	s1,a4,80004f04 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f10:	00022517          	auipc	a0,0x22
    80004f14:	a5850513          	addi	a0,a0,-1448 # 80026968 <ftable>
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	d72080e7          	jalr	-654(ra) # 80000c8a <release>
  return 0;
    80004f20:	4481                	li	s1,0
    80004f22:	a819                	j	80004f38 <filealloc+0x5e>
      f->ref = 1;
    80004f24:	4785                	li	a5,1
    80004f26:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f28:	00022517          	auipc	a0,0x22
    80004f2c:	a4050513          	addi	a0,a0,-1472 # 80026968 <ftable>
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d5a080e7          	jalr	-678(ra) # 80000c8a <release>
}
    80004f38:	8526                	mv	a0,s1
    80004f3a:	60e2                	ld	ra,24(sp)
    80004f3c:	6442                	ld	s0,16(sp)
    80004f3e:	64a2                	ld	s1,8(sp)
    80004f40:	6105                	addi	sp,sp,32
    80004f42:	8082                	ret

0000000080004f44 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f44:	1101                	addi	sp,sp,-32
    80004f46:	ec06                	sd	ra,24(sp)
    80004f48:	e822                	sd	s0,16(sp)
    80004f4a:	e426                	sd	s1,8(sp)
    80004f4c:	1000                	addi	s0,sp,32
    80004f4e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f50:	00022517          	auipc	a0,0x22
    80004f54:	a1850513          	addi	a0,a0,-1512 # 80026968 <ftable>
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	c7e080e7          	jalr	-898(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004f60:	40dc                	lw	a5,4(s1)
    80004f62:	02f05263          	blez	a5,80004f86 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f66:	2785                	addiw	a5,a5,1
    80004f68:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f6a:	00022517          	auipc	a0,0x22
    80004f6e:	9fe50513          	addi	a0,a0,-1538 # 80026968 <ftable>
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	d18080e7          	jalr	-744(ra) # 80000c8a <release>
  return f;
}
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	60e2                	ld	ra,24(sp)
    80004f7e:	6442                	ld	s0,16(sp)
    80004f80:	64a2                	ld	s1,8(sp)
    80004f82:	6105                	addi	sp,sp,32
    80004f84:	8082                	ret
    panic("filedup");
    80004f86:	00004517          	auipc	a0,0x4
    80004f8a:	90a50513          	addi	a0,a0,-1782 # 80008890 <syscalls+0x408>
    80004f8e:	ffffb097          	auipc	ra,0xffffb
    80004f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>

0000000080004f96 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f96:	7139                	addi	sp,sp,-64
    80004f98:	fc06                	sd	ra,56(sp)
    80004f9a:	f822                	sd	s0,48(sp)
    80004f9c:	f426                	sd	s1,40(sp)
    80004f9e:	f04a                	sd	s2,32(sp)
    80004fa0:	ec4e                	sd	s3,24(sp)
    80004fa2:	e852                	sd	s4,16(sp)
    80004fa4:	e456                	sd	s5,8(sp)
    80004fa6:	0080                	addi	s0,sp,64
    80004fa8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004faa:	00022517          	auipc	a0,0x22
    80004fae:	9be50513          	addi	a0,a0,-1602 # 80026968 <ftable>
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	c24080e7          	jalr	-988(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004fba:	40dc                	lw	a5,4(s1)
    80004fbc:	06f05163          	blez	a5,8000501e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004fc0:	37fd                	addiw	a5,a5,-1
    80004fc2:	0007871b          	sext.w	a4,a5
    80004fc6:	c0dc                	sw	a5,4(s1)
    80004fc8:	06e04363          	bgtz	a4,8000502e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004fcc:	0004a903          	lw	s2,0(s1)
    80004fd0:	0094ca83          	lbu	s5,9(s1)
    80004fd4:	0104ba03          	ld	s4,16(s1)
    80004fd8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004fdc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004fe0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004fe4:	00022517          	auipc	a0,0x22
    80004fe8:	98450513          	addi	a0,a0,-1660 # 80026968 <ftable>
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	c9e080e7          	jalr	-866(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004ff4:	4785                	li	a5,1
    80004ff6:	04f90d63          	beq	s2,a5,80005050 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ffa:	3979                	addiw	s2,s2,-2
    80004ffc:	4785                	li	a5,1
    80004ffe:	0527e063          	bltu	a5,s2,8000503e <fileclose+0xa8>
    begin_op();
    80005002:	00000097          	auipc	ra,0x0
    80005006:	ac8080e7          	jalr	-1336(ra) # 80004aca <begin_op>
    iput(ff.ip);
    8000500a:	854e                	mv	a0,s3
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	2b6080e7          	jalr	694(ra) # 800042c2 <iput>
    end_op();
    80005014:	00000097          	auipc	ra,0x0
    80005018:	b36080e7          	jalr	-1226(ra) # 80004b4a <end_op>
    8000501c:	a00d                	j	8000503e <fileclose+0xa8>
    panic("fileclose");
    8000501e:	00004517          	auipc	a0,0x4
    80005022:	87a50513          	addi	a0,a0,-1926 # 80008898 <syscalls+0x410>
    80005026:	ffffb097          	auipc	ra,0xffffb
    8000502a:	518080e7          	jalr	1304(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000502e:	00022517          	auipc	a0,0x22
    80005032:	93a50513          	addi	a0,a0,-1734 # 80026968 <ftable>
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	c54080e7          	jalr	-940(ra) # 80000c8a <release>
  }
}
    8000503e:	70e2                	ld	ra,56(sp)
    80005040:	7442                	ld	s0,48(sp)
    80005042:	74a2                	ld	s1,40(sp)
    80005044:	7902                	ld	s2,32(sp)
    80005046:	69e2                	ld	s3,24(sp)
    80005048:	6a42                	ld	s4,16(sp)
    8000504a:	6aa2                	ld	s5,8(sp)
    8000504c:	6121                	addi	sp,sp,64
    8000504e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005050:	85d6                	mv	a1,s5
    80005052:	8552                	mv	a0,s4
    80005054:	00000097          	auipc	ra,0x0
    80005058:	34c080e7          	jalr	844(ra) # 800053a0 <pipeclose>
    8000505c:	b7cd                	j	8000503e <fileclose+0xa8>

000000008000505e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000505e:	715d                	addi	sp,sp,-80
    80005060:	e486                	sd	ra,72(sp)
    80005062:	e0a2                	sd	s0,64(sp)
    80005064:	fc26                	sd	s1,56(sp)
    80005066:	f84a                	sd	s2,48(sp)
    80005068:	f44e                	sd	s3,40(sp)
    8000506a:	0880                	addi	s0,sp,80
    8000506c:	84aa                	mv	s1,a0
    8000506e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	b2a080e7          	jalr	-1238(ra) # 80001b9a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005078:	409c                	lw	a5,0(s1)
    8000507a:	37f9                	addiw	a5,a5,-2
    8000507c:	4705                	li	a4,1
    8000507e:	04f76763          	bltu	a4,a5,800050cc <filestat+0x6e>
    80005082:	892a                	mv	s2,a0
    ilock(f->ip);
    80005084:	6c88                	ld	a0,24(s1)
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	082080e7          	jalr	130(ra) # 80004108 <ilock>
    stati(f->ip, &st);
    8000508e:	fb840593          	addi	a1,s0,-72
    80005092:	6c88                	ld	a0,24(s1)
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	2fe080e7          	jalr	766(ra) # 80004392 <stati>
    iunlock(f->ip);
    8000509c:	6c88                	ld	a0,24(s1)
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	12c080e7          	jalr	300(ra) # 800041ca <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800050a6:	46e1                	li	a3,24
    800050a8:	fb840613          	addi	a2,s0,-72
    800050ac:	85ce                	mv	a1,s3
    800050ae:	05093503          	ld	a0,80(s2)
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	5b6080e7          	jalr	1462(ra) # 80001668 <copyout>
    800050ba:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800050be:	60a6                	ld	ra,72(sp)
    800050c0:	6406                	ld	s0,64(sp)
    800050c2:	74e2                	ld	s1,56(sp)
    800050c4:	7942                	ld	s2,48(sp)
    800050c6:	79a2                	ld	s3,40(sp)
    800050c8:	6161                	addi	sp,sp,80
    800050ca:	8082                	ret
  return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	bfc5                	j	800050be <filestat+0x60>

00000000800050d0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800050d0:	7179                	addi	sp,sp,-48
    800050d2:	f406                	sd	ra,40(sp)
    800050d4:	f022                	sd	s0,32(sp)
    800050d6:	ec26                	sd	s1,24(sp)
    800050d8:	e84a                	sd	s2,16(sp)
    800050da:	e44e                	sd	s3,8(sp)
    800050dc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050de:	00854783          	lbu	a5,8(a0)
    800050e2:	c3d5                	beqz	a5,80005186 <fileread+0xb6>
    800050e4:	84aa                	mv	s1,a0
    800050e6:	89ae                	mv	s3,a1
    800050e8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050ea:	411c                	lw	a5,0(a0)
    800050ec:	4705                	li	a4,1
    800050ee:	04e78963          	beq	a5,a4,80005140 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050f2:	470d                	li	a4,3
    800050f4:	04e78d63          	beq	a5,a4,8000514e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050f8:	4709                	li	a4,2
    800050fa:	06e79e63          	bne	a5,a4,80005176 <fileread+0xa6>
    ilock(f->ip);
    800050fe:	6d08                	ld	a0,24(a0)
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	008080e7          	jalr	8(ra) # 80004108 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005108:	874a                	mv	a4,s2
    8000510a:	5094                	lw	a3,32(s1)
    8000510c:	864e                	mv	a2,s3
    8000510e:	4585                	li	a1,1
    80005110:	6c88                	ld	a0,24(s1)
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	2aa080e7          	jalr	682(ra) # 800043bc <readi>
    8000511a:	892a                	mv	s2,a0
    8000511c:	00a05563          	blez	a0,80005126 <fileread+0x56>
      f->off += r;
    80005120:	509c                	lw	a5,32(s1)
    80005122:	9fa9                	addw	a5,a5,a0
    80005124:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005126:	6c88                	ld	a0,24(s1)
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	0a2080e7          	jalr	162(ra) # 800041ca <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005130:	854a                	mv	a0,s2
    80005132:	70a2                	ld	ra,40(sp)
    80005134:	7402                	ld	s0,32(sp)
    80005136:	64e2                	ld	s1,24(sp)
    80005138:	6942                	ld	s2,16(sp)
    8000513a:	69a2                	ld	s3,8(sp)
    8000513c:	6145                	addi	sp,sp,48
    8000513e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005140:	6908                	ld	a0,16(a0)
    80005142:	00000097          	auipc	ra,0x0
    80005146:	3c6080e7          	jalr	966(ra) # 80005508 <piperead>
    8000514a:	892a                	mv	s2,a0
    8000514c:	b7d5                	j	80005130 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000514e:	02451783          	lh	a5,36(a0)
    80005152:	03079693          	slli	a3,a5,0x30
    80005156:	92c1                	srli	a3,a3,0x30
    80005158:	4725                	li	a4,9
    8000515a:	02d76863          	bltu	a4,a3,8000518a <fileread+0xba>
    8000515e:	0792                	slli	a5,a5,0x4
    80005160:	00021717          	auipc	a4,0x21
    80005164:	76870713          	addi	a4,a4,1896 # 800268c8 <devsw>
    80005168:	97ba                	add	a5,a5,a4
    8000516a:	639c                	ld	a5,0(a5)
    8000516c:	c38d                	beqz	a5,8000518e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000516e:	4505                	li	a0,1
    80005170:	9782                	jalr	a5
    80005172:	892a                	mv	s2,a0
    80005174:	bf75                	j	80005130 <fileread+0x60>
    panic("fileread");
    80005176:	00003517          	auipc	a0,0x3
    8000517a:	73250513          	addi	a0,a0,1842 # 800088a8 <syscalls+0x420>
    8000517e:	ffffb097          	auipc	ra,0xffffb
    80005182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>
    return -1;
    80005186:	597d                	li	s2,-1
    80005188:	b765                	j	80005130 <fileread+0x60>
      return -1;
    8000518a:	597d                	li	s2,-1
    8000518c:	b755                	j	80005130 <fileread+0x60>
    8000518e:	597d                	li	s2,-1
    80005190:	b745                	j	80005130 <fileread+0x60>

0000000080005192 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005192:	715d                	addi	sp,sp,-80
    80005194:	e486                	sd	ra,72(sp)
    80005196:	e0a2                	sd	s0,64(sp)
    80005198:	fc26                	sd	s1,56(sp)
    8000519a:	f84a                	sd	s2,48(sp)
    8000519c:	f44e                	sd	s3,40(sp)
    8000519e:	f052                	sd	s4,32(sp)
    800051a0:	ec56                	sd	s5,24(sp)
    800051a2:	e85a                	sd	s6,16(sp)
    800051a4:	e45e                	sd	s7,8(sp)
    800051a6:	e062                	sd	s8,0(sp)
    800051a8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800051aa:	00954783          	lbu	a5,9(a0)
    800051ae:	10078663          	beqz	a5,800052ba <filewrite+0x128>
    800051b2:	892a                	mv	s2,a0
    800051b4:	8aae                	mv	s5,a1
    800051b6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800051b8:	411c                	lw	a5,0(a0)
    800051ba:	4705                	li	a4,1
    800051bc:	02e78263          	beq	a5,a4,800051e0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051c0:	470d                	li	a4,3
    800051c2:	02e78663          	beq	a5,a4,800051ee <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800051c6:	4709                	li	a4,2
    800051c8:	0ee79163          	bne	a5,a4,800052aa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800051cc:	0ac05d63          	blez	a2,80005286 <filewrite+0xf4>
    int i = 0;
    800051d0:	4981                	li	s3,0
    800051d2:	6b05                	lui	s6,0x1
    800051d4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800051d8:	6b85                	lui	s7,0x1
    800051da:	c00b8b9b          	addiw	s7,s7,-1024
    800051de:	a861                	j	80005276 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800051e0:	6908                	ld	a0,16(a0)
    800051e2:	00000097          	auipc	ra,0x0
    800051e6:	22e080e7          	jalr	558(ra) # 80005410 <pipewrite>
    800051ea:	8a2a                	mv	s4,a0
    800051ec:	a045                	j	8000528c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051ee:	02451783          	lh	a5,36(a0)
    800051f2:	03079693          	slli	a3,a5,0x30
    800051f6:	92c1                	srli	a3,a3,0x30
    800051f8:	4725                	li	a4,9
    800051fa:	0cd76263          	bltu	a4,a3,800052be <filewrite+0x12c>
    800051fe:	0792                	slli	a5,a5,0x4
    80005200:	00021717          	auipc	a4,0x21
    80005204:	6c870713          	addi	a4,a4,1736 # 800268c8 <devsw>
    80005208:	97ba                	add	a5,a5,a4
    8000520a:	679c                	ld	a5,8(a5)
    8000520c:	cbdd                	beqz	a5,800052c2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000520e:	4505                	li	a0,1
    80005210:	9782                	jalr	a5
    80005212:	8a2a                	mv	s4,a0
    80005214:	a8a5                	j	8000528c <filewrite+0xfa>
    80005216:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000521a:	00000097          	auipc	ra,0x0
    8000521e:	8b0080e7          	jalr	-1872(ra) # 80004aca <begin_op>
      ilock(f->ip);
    80005222:	01893503          	ld	a0,24(s2)
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	ee2080e7          	jalr	-286(ra) # 80004108 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000522e:	8762                	mv	a4,s8
    80005230:	02092683          	lw	a3,32(s2)
    80005234:	01598633          	add	a2,s3,s5
    80005238:	4585                	li	a1,1
    8000523a:	01893503          	ld	a0,24(s2)
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	276080e7          	jalr	630(ra) # 800044b4 <writei>
    80005246:	84aa                	mv	s1,a0
    80005248:	00a05763          	blez	a0,80005256 <filewrite+0xc4>
        f->off += r;
    8000524c:	02092783          	lw	a5,32(s2)
    80005250:	9fa9                	addw	a5,a5,a0
    80005252:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005256:	01893503          	ld	a0,24(s2)
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	f70080e7          	jalr	-144(ra) # 800041ca <iunlock>
      end_op();
    80005262:	00000097          	auipc	ra,0x0
    80005266:	8e8080e7          	jalr	-1816(ra) # 80004b4a <end_op>

      if(r != n1){
    8000526a:	009c1f63          	bne	s8,s1,80005288 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000526e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005272:	0149db63          	bge	s3,s4,80005288 <filewrite+0xf6>
      int n1 = n - i;
    80005276:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000527a:	84be                	mv	s1,a5
    8000527c:	2781                	sext.w	a5,a5
    8000527e:	f8fb5ce3          	bge	s6,a5,80005216 <filewrite+0x84>
    80005282:	84de                	mv	s1,s7
    80005284:	bf49                	j	80005216 <filewrite+0x84>
    int i = 0;
    80005286:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005288:	013a1f63          	bne	s4,s3,800052a6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000528c:	8552                	mv	a0,s4
    8000528e:	60a6                	ld	ra,72(sp)
    80005290:	6406                	ld	s0,64(sp)
    80005292:	74e2                	ld	s1,56(sp)
    80005294:	7942                	ld	s2,48(sp)
    80005296:	79a2                	ld	s3,40(sp)
    80005298:	7a02                	ld	s4,32(sp)
    8000529a:	6ae2                	ld	s5,24(sp)
    8000529c:	6b42                	ld	s6,16(sp)
    8000529e:	6ba2                	ld	s7,8(sp)
    800052a0:	6c02                	ld	s8,0(sp)
    800052a2:	6161                	addi	sp,sp,80
    800052a4:	8082                	ret
    ret = (i == n ? n : -1);
    800052a6:	5a7d                	li	s4,-1
    800052a8:	b7d5                	j	8000528c <filewrite+0xfa>
    panic("filewrite");
    800052aa:	00003517          	auipc	a0,0x3
    800052ae:	60e50513          	addi	a0,a0,1550 # 800088b8 <syscalls+0x430>
    800052b2:	ffffb097          	auipc	ra,0xffffb
    800052b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
    return -1;
    800052ba:	5a7d                	li	s4,-1
    800052bc:	bfc1                	j	8000528c <filewrite+0xfa>
      return -1;
    800052be:	5a7d                	li	s4,-1
    800052c0:	b7f1                	j	8000528c <filewrite+0xfa>
    800052c2:	5a7d                	li	s4,-1
    800052c4:	b7e1                	j	8000528c <filewrite+0xfa>

00000000800052c6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800052c6:	7179                	addi	sp,sp,-48
    800052c8:	f406                	sd	ra,40(sp)
    800052ca:	f022                	sd	s0,32(sp)
    800052cc:	ec26                	sd	s1,24(sp)
    800052ce:	e84a                	sd	s2,16(sp)
    800052d0:	e44e                	sd	s3,8(sp)
    800052d2:	e052                	sd	s4,0(sp)
    800052d4:	1800                	addi	s0,sp,48
    800052d6:	84aa                	mv	s1,a0
    800052d8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800052da:	0005b023          	sd	zero,0(a1)
    800052de:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800052e2:	00000097          	auipc	ra,0x0
    800052e6:	bf8080e7          	jalr	-1032(ra) # 80004eda <filealloc>
    800052ea:	e088                	sd	a0,0(s1)
    800052ec:	c551                	beqz	a0,80005378 <pipealloc+0xb2>
    800052ee:	00000097          	auipc	ra,0x0
    800052f2:	bec080e7          	jalr	-1044(ra) # 80004eda <filealloc>
    800052f6:	00aa3023          	sd	a0,0(s4)
    800052fa:	c92d                	beqz	a0,8000536c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052fc:	ffffb097          	auipc	ra,0xffffb
    80005300:	7ea080e7          	jalr	2026(ra) # 80000ae6 <kalloc>
    80005304:	892a                	mv	s2,a0
    80005306:	c125                	beqz	a0,80005366 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005308:	4985                	li	s3,1
    8000530a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000530e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005312:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005316:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000531a:	00003597          	auipc	a1,0x3
    8000531e:	32658593          	addi	a1,a1,806 # 80008640 <syscalls+0x1b8>
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	824080e7          	jalr	-2012(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000532a:	609c                	ld	a5,0(s1)
    8000532c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005330:	609c                	ld	a5,0(s1)
    80005332:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005336:	609c                	ld	a5,0(s1)
    80005338:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000533c:	609c                	ld	a5,0(s1)
    8000533e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005342:	000a3783          	ld	a5,0(s4)
    80005346:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000534a:	000a3783          	ld	a5,0(s4)
    8000534e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005352:	000a3783          	ld	a5,0(s4)
    80005356:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000535a:	000a3783          	ld	a5,0(s4)
    8000535e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005362:	4501                	li	a0,0
    80005364:	a025                	j	8000538c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005366:	6088                	ld	a0,0(s1)
    80005368:	e501                	bnez	a0,80005370 <pipealloc+0xaa>
    8000536a:	a039                	j	80005378 <pipealloc+0xb2>
    8000536c:	6088                	ld	a0,0(s1)
    8000536e:	c51d                	beqz	a0,8000539c <pipealloc+0xd6>
    fileclose(*f0);
    80005370:	00000097          	auipc	ra,0x0
    80005374:	c26080e7          	jalr	-986(ra) # 80004f96 <fileclose>
  if(*f1)
    80005378:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000537c:	557d                	li	a0,-1
  if(*f1)
    8000537e:	c799                	beqz	a5,8000538c <pipealloc+0xc6>
    fileclose(*f1);
    80005380:	853e                	mv	a0,a5
    80005382:	00000097          	auipc	ra,0x0
    80005386:	c14080e7          	jalr	-1004(ra) # 80004f96 <fileclose>
  return -1;
    8000538a:	557d                	li	a0,-1
}
    8000538c:	70a2                	ld	ra,40(sp)
    8000538e:	7402                	ld	s0,32(sp)
    80005390:	64e2                	ld	s1,24(sp)
    80005392:	6942                	ld	s2,16(sp)
    80005394:	69a2                	ld	s3,8(sp)
    80005396:	6a02                	ld	s4,0(sp)
    80005398:	6145                	addi	sp,sp,48
    8000539a:	8082                	ret
  return -1;
    8000539c:	557d                	li	a0,-1
    8000539e:	b7fd                	j	8000538c <pipealloc+0xc6>

00000000800053a0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053a0:	1101                	addi	sp,sp,-32
    800053a2:	ec06                	sd	ra,24(sp)
    800053a4:	e822                	sd	s0,16(sp)
    800053a6:	e426                	sd	s1,8(sp)
    800053a8:	e04a                	sd	s2,0(sp)
    800053aa:	1000                	addi	s0,sp,32
    800053ac:	84aa                	mv	s1,a0
    800053ae:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	826080e7          	jalr	-2010(ra) # 80000bd6 <acquire>
  if(writable){
    800053b8:	02090d63          	beqz	s2,800053f2 <pipeclose+0x52>
    pi->writeopen = 0;
    800053bc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800053c0:	21848513          	addi	a0,s1,536
    800053c4:	ffffd097          	auipc	ra,0xffffd
    800053c8:	0ee080e7          	jalr	238(ra) # 800024b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800053cc:	2204b783          	ld	a5,544(s1)
    800053d0:	eb95                	bnez	a5,80005404 <pipeclose+0x64>
    release(&pi->lock);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
    kfree((char*)pi);
    800053dc:	8526                	mv	a0,s1
    800053de:	ffffb097          	auipc	ra,0xffffb
    800053e2:	60c080e7          	jalr	1548(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800053e6:	60e2                	ld	ra,24(sp)
    800053e8:	6442                	ld	s0,16(sp)
    800053ea:	64a2                	ld	s1,8(sp)
    800053ec:	6902                	ld	s2,0(sp)
    800053ee:	6105                	addi	sp,sp,32
    800053f0:	8082                	ret
    pi->readopen = 0;
    800053f2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053f6:	21c48513          	addi	a0,s1,540
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	0b8080e7          	jalr	184(ra) # 800024b2 <wakeup>
    80005402:	b7e9                	j	800053cc <pipeclose+0x2c>
    release(&pi->lock);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffc097          	auipc	ra,0xffffc
    8000540a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
}
    8000540e:	bfe1                	j	800053e6 <pipeclose+0x46>

0000000080005410 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005410:	711d                	addi	sp,sp,-96
    80005412:	ec86                	sd	ra,88(sp)
    80005414:	e8a2                	sd	s0,80(sp)
    80005416:	e4a6                	sd	s1,72(sp)
    80005418:	e0ca                	sd	s2,64(sp)
    8000541a:	fc4e                	sd	s3,56(sp)
    8000541c:	f852                	sd	s4,48(sp)
    8000541e:	f456                	sd	s5,40(sp)
    80005420:	f05a                	sd	s6,32(sp)
    80005422:	ec5e                	sd	s7,24(sp)
    80005424:	e862                	sd	s8,16(sp)
    80005426:	1080                	addi	s0,sp,96
    80005428:	84aa                	mv	s1,a0
    8000542a:	8aae                	mv	s5,a1
    8000542c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	76c080e7          	jalr	1900(ra) # 80001b9a <myproc>
    80005436:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffb097          	auipc	ra,0xffffb
    8000543e:	79c080e7          	jalr	1948(ra) # 80000bd6 <acquire>
  while(i < n){
    80005442:	0b405663          	blez	s4,800054ee <pipewrite+0xde>
  int i = 0;
    80005446:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005448:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000544a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000544e:	21c48b93          	addi	s7,s1,540
    80005452:	a089                	j	80005494 <pipewrite+0x84>
      release(&pi->lock);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	834080e7          	jalr	-1996(ra) # 80000c8a <release>
      return -1;
    8000545e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005460:	854a                	mv	a0,s2
    80005462:	60e6                	ld	ra,88(sp)
    80005464:	6446                	ld	s0,80(sp)
    80005466:	64a6                	ld	s1,72(sp)
    80005468:	6906                	ld	s2,64(sp)
    8000546a:	79e2                	ld	s3,56(sp)
    8000546c:	7a42                	ld	s4,48(sp)
    8000546e:	7aa2                	ld	s5,40(sp)
    80005470:	7b02                	ld	s6,32(sp)
    80005472:	6be2                	ld	s7,24(sp)
    80005474:	6c42                	ld	s8,16(sp)
    80005476:	6125                	addi	sp,sp,96
    80005478:	8082                	ret
      wakeup(&pi->nread);
    8000547a:	8562                	mv	a0,s8
    8000547c:	ffffd097          	auipc	ra,0xffffd
    80005480:	036080e7          	jalr	54(ra) # 800024b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005484:	85a6                	mv	a1,s1
    80005486:	855e                	mv	a0,s7
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	fc6080e7          	jalr	-58(ra) # 8000244e <sleep>
  while(i < n){
    80005490:	07495063          	bge	s2,s4,800054f0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005494:	2204a783          	lw	a5,544(s1)
    80005498:	dfd5                	beqz	a5,80005454 <pipewrite+0x44>
    8000549a:	854e                	mv	a0,s3
    8000549c:	ffffd097          	auipc	ra,0xffffd
    800054a0:	266080e7          	jalr	614(ra) # 80002702 <killed>
    800054a4:	f945                	bnez	a0,80005454 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800054a6:	2184a783          	lw	a5,536(s1)
    800054aa:	21c4a703          	lw	a4,540(s1)
    800054ae:	2007879b          	addiw	a5,a5,512
    800054b2:	fcf704e3          	beq	a4,a5,8000547a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054b6:	4685                	li	a3,1
    800054b8:	01590633          	add	a2,s2,s5
    800054bc:	faf40593          	addi	a1,s0,-81
    800054c0:	0509b503          	ld	a0,80(s3)
    800054c4:	ffffc097          	auipc	ra,0xffffc
    800054c8:	230080e7          	jalr	560(ra) # 800016f4 <copyin>
    800054cc:	03650263          	beq	a0,s6,800054f0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800054d0:	21c4a783          	lw	a5,540(s1)
    800054d4:	0017871b          	addiw	a4,a5,1
    800054d8:	20e4ae23          	sw	a4,540(s1)
    800054dc:	1ff7f793          	andi	a5,a5,511
    800054e0:	97a6                	add	a5,a5,s1
    800054e2:	faf44703          	lbu	a4,-81(s0)
    800054e6:	00e78c23          	sb	a4,24(a5)
      i++;
    800054ea:	2905                	addiw	s2,s2,1
    800054ec:	b755                	j	80005490 <pipewrite+0x80>
  int i = 0;
    800054ee:	4901                	li	s2,0
  wakeup(&pi->nread);
    800054f0:	21848513          	addi	a0,s1,536
    800054f4:	ffffd097          	auipc	ra,0xffffd
    800054f8:	fbe080e7          	jalr	-66(ra) # 800024b2 <wakeup>
  release(&pi->lock);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffb097          	auipc	ra,0xffffb
    80005502:	78c080e7          	jalr	1932(ra) # 80000c8a <release>
  return i;
    80005506:	bfa9                	j	80005460 <pipewrite+0x50>

0000000080005508 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005508:	715d                	addi	sp,sp,-80
    8000550a:	e486                	sd	ra,72(sp)
    8000550c:	e0a2                	sd	s0,64(sp)
    8000550e:	fc26                	sd	s1,56(sp)
    80005510:	f84a                	sd	s2,48(sp)
    80005512:	f44e                	sd	s3,40(sp)
    80005514:	f052                	sd	s4,32(sp)
    80005516:	ec56                	sd	s5,24(sp)
    80005518:	e85a                	sd	s6,16(sp)
    8000551a:	0880                	addi	s0,sp,80
    8000551c:	84aa                	mv	s1,a0
    8000551e:	892e                	mv	s2,a1
    80005520:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005522:	ffffc097          	auipc	ra,0xffffc
    80005526:	678080e7          	jalr	1656(ra) # 80001b9a <myproc>
    8000552a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	6a8080e7          	jalr	1704(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005536:	2184a703          	lw	a4,536(s1)
    8000553a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000553e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005542:	02f71763          	bne	a4,a5,80005570 <piperead+0x68>
    80005546:	2244a783          	lw	a5,548(s1)
    8000554a:	c39d                	beqz	a5,80005570 <piperead+0x68>
    if(killed(pr)){
    8000554c:	8552                	mv	a0,s4
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	1b4080e7          	jalr	436(ra) # 80002702 <killed>
    80005556:	e941                	bnez	a0,800055e6 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005558:	85a6                	mv	a1,s1
    8000555a:	854e                	mv	a0,s3
    8000555c:	ffffd097          	auipc	ra,0xffffd
    80005560:	ef2080e7          	jalr	-270(ra) # 8000244e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005564:	2184a703          	lw	a4,536(s1)
    80005568:	21c4a783          	lw	a5,540(s1)
    8000556c:	fcf70de3          	beq	a4,a5,80005546 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005570:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005572:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005574:	05505363          	blez	s5,800055ba <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005578:	2184a783          	lw	a5,536(s1)
    8000557c:	21c4a703          	lw	a4,540(s1)
    80005580:	02f70d63          	beq	a4,a5,800055ba <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005584:	0017871b          	addiw	a4,a5,1
    80005588:	20e4ac23          	sw	a4,536(s1)
    8000558c:	1ff7f793          	andi	a5,a5,511
    80005590:	97a6                	add	a5,a5,s1
    80005592:	0187c783          	lbu	a5,24(a5)
    80005596:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000559a:	4685                	li	a3,1
    8000559c:	fbf40613          	addi	a2,s0,-65
    800055a0:	85ca                	mv	a1,s2
    800055a2:	050a3503          	ld	a0,80(s4)
    800055a6:	ffffc097          	auipc	ra,0xffffc
    800055aa:	0c2080e7          	jalr	194(ra) # 80001668 <copyout>
    800055ae:	01650663          	beq	a0,s6,800055ba <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055b2:	2985                	addiw	s3,s3,1
    800055b4:	0905                	addi	s2,s2,1
    800055b6:	fd3a91e3          	bne	s5,s3,80005578 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800055ba:	21c48513          	addi	a0,s1,540
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	ef4080e7          	jalr	-268(ra) # 800024b2 <wakeup>
  release(&pi->lock);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffb097          	auipc	ra,0xffffb
    800055cc:	6c2080e7          	jalr	1730(ra) # 80000c8a <release>
  return i;
}
    800055d0:	854e                	mv	a0,s3
    800055d2:	60a6                	ld	ra,72(sp)
    800055d4:	6406                	ld	s0,64(sp)
    800055d6:	74e2                	ld	s1,56(sp)
    800055d8:	7942                	ld	s2,48(sp)
    800055da:	79a2                	ld	s3,40(sp)
    800055dc:	7a02                	ld	s4,32(sp)
    800055de:	6ae2                	ld	s5,24(sp)
    800055e0:	6b42                	ld	s6,16(sp)
    800055e2:	6161                	addi	sp,sp,80
    800055e4:	8082                	ret
      release(&pi->lock);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffb097          	auipc	ra,0xffffb
    800055ec:	6a2080e7          	jalr	1698(ra) # 80000c8a <release>
      return -1;
    800055f0:	59fd                	li	s3,-1
    800055f2:	bff9                	j	800055d0 <piperead+0xc8>

00000000800055f4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800055f4:	1141                	addi	sp,sp,-16
    800055f6:	e422                	sd	s0,8(sp)
    800055f8:	0800                	addi	s0,sp,16
    800055fa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800055fc:	8905                	andi	a0,a0,1
    800055fe:	c111                	beqz	a0,80005602 <flags2perm+0xe>
      perm = PTE_X;
    80005600:	4521                	li	a0,8
    if(flags & 0x2)
    80005602:	8b89                	andi	a5,a5,2
    80005604:	c399                	beqz	a5,8000560a <flags2perm+0x16>
      perm |= PTE_W;
    80005606:	00456513          	ori	a0,a0,4
    return perm;
}
    8000560a:	6422                	ld	s0,8(sp)
    8000560c:	0141                	addi	sp,sp,16
    8000560e:	8082                	ret

0000000080005610 <exec>:

int
exec(char *path, char **argv)
{
    80005610:	de010113          	addi	sp,sp,-544
    80005614:	20113c23          	sd	ra,536(sp)
    80005618:	20813823          	sd	s0,528(sp)
    8000561c:	20913423          	sd	s1,520(sp)
    80005620:	21213023          	sd	s2,512(sp)
    80005624:	ffce                	sd	s3,504(sp)
    80005626:	fbd2                	sd	s4,496(sp)
    80005628:	f7d6                	sd	s5,488(sp)
    8000562a:	f3da                	sd	s6,480(sp)
    8000562c:	efde                	sd	s7,472(sp)
    8000562e:	ebe2                	sd	s8,464(sp)
    80005630:	e7e6                	sd	s9,456(sp)
    80005632:	e3ea                	sd	s10,448(sp)
    80005634:	ff6e                	sd	s11,440(sp)
    80005636:	1400                	addi	s0,sp,544
    80005638:	892a                	mv	s2,a0
    8000563a:	dea43423          	sd	a0,-536(s0)
    8000563e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005642:	ffffc097          	auipc	ra,0xffffc
    80005646:	558080e7          	jalr	1368(ra) # 80001b9a <myproc>
    8000564a:	84aa                	mv	s1,a0

  begin_op();
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	47e080e7          	jalr	1150(ra) # 80004aca <begin_op>

  if((ip = namei(path)) == 0){
    80005654:	854a                	mv	a0,s2
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	258080e7          	jalr	600(ra) # 800048ae <namei>
    8000565e:	c93d                	beqz	a0,800056d4 <exec+0xc4>
    80005660:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	aa6080e7          	jalr	-1370(ra) # 80004108 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000566a:	04000713          	li	a4,64
    8000566e:	4681                	li	a3,0
    80005670:	e5040613          	addi	a2,s0,-432
    80005674:	4581                	li	a1,0
    80005676:	8556                	mv	a0,s5
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	d44080e7          	jalr	-700(ra) # 800043bc <readi>
    80005680:	04000793          	li	a5,64
    80005684:	00f51a63          	bne	a0,a5,80005698 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005688:	e5042703          	lw	a4,-432(s0)
    8000568c:	464c47b7          	lui	a5,0x464c4
    80005690:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005694:	04f70663          	beq	a4,a5,800056e0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005698:	8556                	mv	a0,s5
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	cd0080e7          	jalr	-816(ra) # 8000436a <iunlockput>
    end_op();
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	4a8080e7          	jalr	1192(ra) # 80004b4a <end_op>
  }
  return -1;
    800056aa:	557d                	li	a0,-1
}
    800056ac:	21813083          	ld	ra,536(sp)
    800056b0:	21013403          	ld	s0,528(sp)
    800056b4:	20813483          	ld	s1,520(sp)
    800056b8:	20013903          	ld	s2,512(sp)
    800056bc:	79fe                	ld	s3,504(sp)
    800056be:	7a5e                	ld	s4,496(sp)
    800056c0:	7abe                	ld	s5,488(sp)
    800056c2:	7b1e                	ld	s6,480(sp)
    800056c4:	6bfe                	ld	s7,472(sp)
    800056c6:	6c5e                	ld	s8,464(sp)
    800056c8:	6cbe                	ld	s9,456(sp)
    800056ca:	6d1e                	ld	s10,448(sp)
    800056cc:	7dfa                	ld	s11,440(sp)
    800056ce:	22010113          	addi	sp,sp,544
    800056d2:	8082                	ret
    end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	476080e7          	jalr	1142(ra) # 80004b4a <end_op>
    return -1;
    800056dc:	557d                	li	a0,-1
    800056de:	b7f9                	j	800056ac <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffc097          	auipc	ra,0xffffc
    800056e6:	57c080e7          	jalr	1404(ra) # 80001c5e <proc_pagetable>
    800056ea:	8b2a                	mv	s6,a0
    800056ec:	d555                	beqz	a0,80005698 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056ee:	e7042783          	lw	a5,-400(s0)
    800056f2:	e8845703          	lhu	a4,-376(s0)
    800056f6:	c735                	beqz	a4,80005762 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056f8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056fa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800056fe:	6a05                	lui	s4,0x1
    80005700:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005704:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005708:	6d85                	lui	s11,0x1
    8000570a:	7d7d                	lui	s10,0xfffff
    8000570c:	a481                	j	8000594c <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000570e:	00003517          	auipc	a0,0x3
    80005712:	1ba50513          	addi	a0,a0,442 # 800088c8 <syscalls+0x440>
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000571e:	874a                	mv	a4,s2
    80005720:	009c86bb          	addw	a3,s9,s1
    80005724:	4581                	li	a1,0
    80005726:	8556                	mv	a0,s5
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	c94080e7          	jalr	-876(ra) # 800043bc <readi>
    80005730:	2501                	sext.w	a0,a0
    80005732:	1aa91a63          	bne	s2,a0,800058e6 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005736:	009d84bb          	addw	s1,s11,s1
    8000573a:	013d09bb          	addw	s3,s10,s3
    8000573e:	1f74f763          	bgeu	s1,s7,8000592c <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005742:	02049593          	slli	a1,s1,0x20
    80005746:	9181                	srli	a1,a1,0x20
    80005748:	95e2                	add	a1,a1,s8
    8000574a:	855a                	mv	a0,s6
    8000574c:	ffffc097          	auipc	ra,0xffffc
    80005750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    80005754:	862a                	mv	a2,a0
    if(pa == 0)
    80005756:	dd45                	beqz	a0,8000570e <exec+0xfe>
      n = PGSIZE;
    80005758:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000575a:	fd49f2e3          	bgeu	s3,s4,8000571e <exec+0x10e>
      n = sz - i;
    8000575e:	894e                	mv	s2,s3
    80005760:	bf7d                	j	8000571e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005762:	4901                	li	s2,0
  iunlockput(ip);
    80005764:	8556                	mv	a0,s5
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	c04080e7          	jalr	-1020(ra) # 8000436a <iunlockput>
  end_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	3dc080e7          	jalr	988(ra) # 80004b4a <end_op>
  p = myproc();
    80005776:	ffffc097          	auipc	ra,0xffffc
    8000577a:	424080e7          	jalr	1060(ra) # 80001b9a <myproc>
    8000577e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005780:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005784:	6785                	lui	a5,0x1
    80005786:	17fd                	addi	a5,a5,-1
    80005788:	993e                	add	s2,s2,a5
    8000578a:	77fd                	lui	a5,0xfffff
    8000578c:	00f977b3          	and	a5,s2,a5
    80005790:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005794:	4691                	li	a3,4
    80005796:	6609                	lui	a2,0x2
    80005798:	963e                	add	a2,a2,a5
    8000579a:	85be                	mv	a1,a5
    8000579c:	855a                	mv	a0,s6
    8000579e:	ffffc097          	auipc	ra,0xffffc
    800057a2:	c72080e7          	jalr	-910(ra) # 80001410 <uvmalloc>
    800057a6:	8c2a                	mv	s8,a0
  ip = 0;
    800057a8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800057aa:	12050e63          	beqz	a0,800058e6 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800057ae:	75f9                	lui	a1,0xffffe
    800057b0:	95aa                	add	a1,a1,a0
    800057b2:	855a                	mv	a0,s6
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	e82080e7          	jalr	-382(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800057bc:	7afd                	lui	s5,0xfffff
    800057be:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800057c0:	df043783          	ld	a5,-528(s0)
    800057c4:	6388                	ld	a0,0(a5)
    800057c6:	c925                	beqz	a0,80005836 <exec+0x226>
    800057c8:	e9040993          	addi	s3,s0,-368
    800057cc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800057d0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800057d2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	67a080e7          	jalr	1658(ra) # 80000e4e <strlen>
    800057dc:	0015079b          	addiw	a5,a0,1
    800057e0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800057e4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800057e8:	13596663          	bltu	s2,s5,80005914 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800057ec:	df043d83          	ld	s11,-528(s0)
    800057f0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800057f4:	8552                	mv	a0,s4
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	658080e7          	jalr	1624(ra) # 80000e4e <strlen>
    800057fe:	0015069b          	addiw	a3,a0,1
    80005802:	8652                	mv	a2,s4
    80005804:	85ca                	mv	a1,s2
    80005806:	855a                	mv	a0,s6
    80005808:	ffffc097          	auipc	ra,0xffffc
    8000580c:	e60080e7          	jalr	-416(ra) # 80001668 <copyout>
    80005810:	10054663          	bltz	a0,8000591c <exec+0x30c>
    ustack[argc] = sp;
    80005814:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005818:	0485                	addi	s1,s1,1
    8000581a:	008d8793          	addi	a5,s11,8
    8000581e:	def43823          	sd	a5,-528(s0)
    80005822:	008db503          	ld	a0,8(s11)
    80005826:	c911                	beqz	a0,8000583a <exec+0x22a>
    if(argc >= MAXARG)
    80005828:	09a1                	addi	s3,s3,8
    8000582a:	fb3c95e3          	bne	s9,s3,800057d4 <exec+0x1c4>
  sz = sz1;
    8000582e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005832:	4a81                	li	s5,0
    80005834:	a84d                	j	800058e6 <exec+0x2d6>
  sp = sz;
    80005836:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005838:	4481                	li	s1,0
  ustack[argc] = 0;
    8000583a:	00349793          	slli	a5,s1,0x3
    8000583e:	f9040713          	addi	a4,s0,-112
    80005842:	97ba                	add	a5,a5,a4
    80005844:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd74a0>
  sp -= (argc+1) * sizeof(uint64);
    80005848:	00148693          	addi	a3,s1,1
    8000584c:	068e                	slli	a3,a3,0x3
    8000584e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005852:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005856:	01597663          	bgeu	s2,s5,80005862 <exec+0x252>
  sz = sz1;
    8000585a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000585e:	4a81                	li	s5,0
    80005860:	a059                	j	800058e6 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005862:	e9040613          	addi	a2,s0,-368
    80005866:	85ca                	mv	a1,s2
    80005868:	855a                	mv	a0,s6
    8000586a:	ffffc097          	auipc	ra,0xffffc
    8000586e:	dfe080e7          	jalr	-514(ra) # 80001668 <copyout>
    80005872:	0a054963          	bltz	a0,80005924 <exec+0x314>
  p->trapframe->a1 = sp;
    80005876:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000587a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000587e:	de843783          	ld	a5,-536(s0)
    80005882:	0007c703          	lbu	a4,0(a5)
    80005886:	cf11                	beqz	a4,800058a2 <exec+0x292>
    80005888:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000588a:	02f00693          	li	a3,47
    8000588e:	a039                	j	8000589c <exec+0x28c>
      last = s+1;
    80005890:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005894:	0785                	addi	a5,a5,1
    80005896:	fff7c703          	lbu	a4,-1(a5)
    8000589a:	c701                	beqz	a4,800058a2 <exec+0x292>
    if(*s == '/')
    8000589c:	fed71ce3          	bne	a4,a3,80005894 <exec+0x284>
    800058a0:	bfc5                	j	80005890 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800058a2:	4641                	li	a2,16
    800058a4:	de843583          	ld	a1,-536(s0)
    800058a8:	158b8513          	addi	a0,s7,344
    800058ac:	ffffb097          	auipc	ra,0xffffb
    800058b0:	570080e7          	jalr	1392(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800058b4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800058b8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800058bc:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800058c0:	058bb783          	ld	a5,88(s7)
    800058c4:	e6843703          	ld	a4,-408(s0)
    800058c8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800058ca:	058bb783          	ld	a5,88(s7)
    800058ce:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058d2:	85ea                	mv	a1,s10
    800058d4:	ffffc097          	auipc	ra,0xffffc
    800058d8:	426080e7          	jalr	1062(ra) # 80001cfa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058dc:	0004851b          	sext.w	a0,s1
    800058e0:	b3f1                	j	800056ac <exec+0x9c>
    800058e2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800058e6:	df843583          	ld	a1,-520(s0)
    800058ea:	855a                	mv	a0,s6
    800058ec:	ffffc097          	auipc	ra,0xffffc
    800058f0:	40e080e7          	jalr	1038(ra) # 80001cfa <proc_freepagetable>
  if(ip){
    800058f4:	da0a92e3          	bnez	s5,80005698 <exec+0x88>
  return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	bb4d                	j	800056ac <exec+0x9c>
    800058fc:	df243c23          	sd	s2,-520(s0)
    80005900:	b7dd                	j	800058e6 <exec+0x2d6>
    80005902:	df243c23          	sd	s2,-520(s0)
    80005906:	b7c5                	j	800058e6 <exec+0x2d6>
    80005908:	df243c23          	sd	s2,-520(s0)
    8000590c:	bfe9                	j	800058e6 <exec+0x2d6>
    8000590e:	df243c23          	sd	s2,-520(s0)
    80005912:	bfd1                	j	800058e6 <exec+0x2d6>
  sz = sz1;
    80005914:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005918:	4a81                	li	s5,0
    8000591a:	b7f1                	j	800058e6 <exec+0x2d6>
  sz = sz1;
    8000591c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005920:	4a81                	li	s5,0
    80005922:	b7d1                	j	800058e6 <exec+0x2d6>
  sz = sz1;
    80005924:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005928:	4a81                	li	s5,0
    8000592a:	bf75                	j	800058e6 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000592c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005930:	e0843783          	ld	a5,-504(s0)
    80005934:	0017869b          	addiw	a3,a5,1
    80005938:	e0d43423          	sd	a3,-504(s0)
    8000593c:	e0043783          	ld	a5,-512(s0)
    80005940:	0387879b          	addiw	a5,a5,56
    80005944:	e8845703          	lhu	a4,-376(s0)
    80005948:	e0e6dee3          	bge	a3,a4,80005764 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000594c:	2781                	sext.w	a5,a5
    8000594e:	e0f43023          	sd	a5,-512(s0)
    80005952:	03800713          	li	a4,56
    80005956:	86be                	mv	a3,a5
    80005958:	e1840613          	addi	a2,s0,-488
    8000595c:	4581                	li	a1,0
    8000595e:	8556                	mv	a0,s5
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	a5c080e7          	jalr	-1444(ra) # 800043bc <readi>
    80005968:	03800793          	li	a5,56
    8000596c:	f6f51be3          	bne	a0,a5,800058e2 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005970:	e1842783          	lw	a5,-488(s0)
    80005974:	4705                	li	a4,1
    80005976:	fae79de3          	bne	a5,a4,80005930 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000597a:	e4043483          	ld	s1,-448(s0)
    8000597e:	e3843783          	ld	a5,-456(s0)
    80005982:	f6f4ede3          	bltu	s1,a5,800058fc <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005986:	e2843783          	ld	a5,-472(s0)
    8000598a:	94be                	add	s1,s1,a5
    8000598c:	f6f4ebe3          	bltu	s1,a5,80005902 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005990:	de043703          	ld	a4,-544(s0)
    80005994:	8ff9                	and	a5,a5,a4
    80005996:	fbad                	bnez	a5,80005908 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005998:	e1c42503          	lw	a0,-484(s0)
    8000599c:	00000097          	auipc	ra,0x0
    800059a0:	c58080e7          	jalr	-936(ra) # 800055f4 <flags2perm>
    800059a4:	86aa                	mv	a3,a0
    800059a6:	8626                	mv	a2,s1
    800059a8:	85ca                	mv	a1,s2
    800059aa:	855a                	mv	a0,s6
    800059ac:	ffffc097          	auipc	ra,0xffffc
    800059b0:	a64080e7          	jalr	-1436(ra) # 80001410 <uvmalloc>
    800059b4:	dea43c23          	sd	a0,-520(s0)
    800059b8:	d939                	beqz	a0,8000590e <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800059ba:	e2843c03          	ld	s8,-472(s0)
    800059be:	e2042c83          	lw	s9,-480(s0)
    800059c2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800059c6:	f60b83e3          	beqz	s7,8000592c <exec+0x31c>
    800059ca:	89de                	mv	s3,s7
    800059cc:	4481                	li	s1,0
    800059ce:	bb95                	j	80005742 <exec+0x132>

00000000800059d0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800059d0:	7179                	addi	sp,sp,-48
    800059d2:	f406                	sd	ra,40(sp)
    800059d4:	f022                	sd	s0,32(sp)
    800059d6:	ec26                	sd	s1,24(sp)
    800059d8:	e84a                	sd	s2,16(sp)
    800059da:	1800                	addi	s0,sp,48
    800059dc:	892e                	mv	s2,a1
    800059de:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800059e0:	fdc40593          	addi	a1,s0,-36
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	8ee080e7          	jalr	-1810(ra) # 800032d2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800059ec:	fdc42703          	lw	a4,-36(s0)
    800059f0:	47bd                	li	a5,15
    800059f2:	02e7eb63          	bltu	a5,a4,80005a28 <argfd+0x58>
    800059f6:	ffffc097          	auipc	ra,0xffffc
    800059fa:	1a4080e7          	jalr	420(ra) # 80001b9a <myproc>
    800059fe:	fdc42703          	lw	a4,-36(s0)
    80005a02:	01a70793          	addi	a5,a4,26
    80005a06:	078e                	slli	a5,a5,0x3
    80005a08:	953e                	add	a0,a0,a5
    80005a0a:	611c                	ld	a5,0(a0)
    80005a0c:	c385                	beqz	a5,80005a2c <argfd+0x5c>
    return -1;
  if(pfd)
    80005a0e:	00090463          	beqz	s2,80005a16 <argfd+0x46>
    *pfd = fd;
    80005a12:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a16:	4501                	li	a0,0
  if(pf)
    80005a18:	c091                	beqz	s1,80005a1c <argfd+0x4c>
    *pf = f;
    80005a1a:	e09c                	sd	a5,0(s1)
}
    80005a1c:	70a2                	ld	ra,40(sp)
    80005a1e:	7402                	ld	s0,32(sp)
    80005a20:	64e2                	ld	s1,24(sp)
    80005a22:	6942                	ld	s2,16(sp)
    80005a24:	6145                	addi	sp,sp,48
    80005a26:	8082                	ret
    return -1;
    80005a28:	557d                	li	a0,-1
    80005a2a:	bfcd                	j	80005a1c <argfd+0x4c>
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7fd                	j	80005a1c <argfd+0x4c>

0000000080005a30 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a30:	1101                	addi	sp,sp,-32
    80005a32:	ec06                	sd	ra,24(sp)
    80005a34:	e822                	sd	s0,16(sp)
    80005a36:	e426                	sd	s1,8(sp)
    80005a38:	1000                	addi	s0,sp,32
    80005a3a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a3c:	ffffc097          	auipc	ra,0xffffc
    80005a40:	15e080e7          	jalr	350(ra) # 80001b9a <myproc>
    80005a44:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a46:	0d050793          	addi	a5,a0,208
    80005a4a:	4501                	li	a0,0
    80005a4c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a4e:	6398                	ld	a4,0(a5)
    80005a50:	cb19                	beqz	a4,80005a66 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a52:	2505                	addiw	a0,a0,1
    80005a54:	07a1                	addi	a5,a5,8
    80005a56:	fed51ce3          	bne	a0,a3,80005a4e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a5a:	557d                	li	a0,-1
}
    80005a5c:	60e2                	ld	ra,24(sp)
    80005a5e:	6442                	ld	s0,16(sp)
    80005a60:	64a2                	ld	s1,8(sp)
    80005a62:	6105                	addi	sp,sp,32
    80005a64:	8082                	ret
      p->ofile[fd] = f;
    80005a66:	01a50793          	addi	a5,a0,26
    80005a6a:	078e                	slli	a5,a5,0x3
    80005a6c:	963e                	add	a2,a2,a5
    80005a6e:	e204                	sd	s1,0(a2)
      return fd;
    80005a70:	b7f5                	j	80005a5c <fdalloc+0x2c>

0000000080005a72 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005a72:	715d                	addi	sp,sp,-80
    80005a74:	e486                	sd	ra,72(sp)
    80005a76:	e0a2                	sd	s0,64(sp)
    80005a78:	fc26                	sd	s1,56(sp)
    80005a7a:	f84a                	sd	s2,48(sp)
    80005a7c:	f44e                	sd	s3,40(sp)
    80005a7e:	f052                	sd	s4,32(sp)
    80005a80:	ec56                	sd	s5,24(sp)
    80005a82:	e85a                	sd	s6,16(sp)
    80005a84:	0880                	addi	s0,sp,80
    80005a86:	8b2e                	mv	s6,a1
    80005a88:	89b2                	mv	s3,a2
    80005a8a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005a8c:	fb040593          	addi	a1,s0,-80
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	e3c080e7          	jalr	-452(ra) # 800048cc <nameiparent>
    80005a98:	84aa                	mv	s1,a0
    80005a9a:	14050f63          	beqz	a0,80005bf8 <create+0x186>
    return 0;

  ilock(dp);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	66a080e7          	jalr	1642(ra) # 80004108 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005aa6:	4601                	li	a2,0
    80005aa8:	fb040593          	addi	a1,s0,-80
    80005aac:	8526                	mv	a0,s1
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	b3e080e7          	jalr	-1218(ra) # 800045ec <dirlookup>
    80005ab6:	8aaa                	mv	s5,a0
    80005ab8:	c931                	beqz	a0,80005b0c <create+0x9a>
    iunlockput(dp);
    80005aba:	8526                	mv	a0,s1
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	8ae080e7          	jalr	-1874(ra) # 8000436a <iunlockput>
    ilock(ip);
    80005ac4:	8556                	mv	a0,s5
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	642080e7          	jalr	1602(ra) # 80004108 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005ace:	000b059b          	sext.w	a1,s6
    80005ad2:	4789                	li	a5,2
    80005ad4:	02f59563          	bne	a1,a5,80005afe <create+0x8c>
    80005ad8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd75e4>
    80005adc:	37f9                	addiw	a5,a5,-2
    80005ade:	17c2                	slli	a5,a5,0x30
    80005ae0:	93c1                	srli	a5,a5,0x30
    80005ae2:	4705                	li	a4,1
    80005ae4:	00f76d63          	bltu	a4,a5,80005afe <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005ae8:	8556                	mv	a0,s5
    80005aea:	60a6                	ld	ra,72(sp)
    80005aec:	6406                	ld	s0,64(sp)
    80005aee:	74e2                	ld	s1,56(sp)
    80005af0:	7942                	ld	s2,48(sp)
    80005af2:	79a2                	ld	s3,40(sp)
    80005af4:	7a02                	ld	s4,32(sp)
    80005af6:	6ae2                	ld	s5,24(sp)
    80005af8:	6b42                	ld	s6,16(sp)
    80005afa:	6161                	addi	sp,sp,80
    80005afc:	8082                	ret
    iunlockput(ip);
    80005afe:	8556                	mv	a0,s5
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	86a080e7          	jalr	-1942(ra) # 8000436a <iunlockput>
    return 0;
    80005b08:	4a81                	li	s5,0
    80005b0a:	bff9                	j	80005ae8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005b0c:	85da                	mv	a1,s6
    80005b0e:	4088                	lw	a0,0(s1)
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	45c080e7          	jalr	1116(ra) # 80003f6c <ialloc>
    80005b18:	8a2a                	mv	s4,a0
    80005b1a:	c539                	beqz	a0,80005b68 <create+0xf6>
  ilock(ip);
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	5ec080e7          	jalr	1516(ra) # 80004108 <ilock>
  ip->major = major;
    80005b24:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005b28:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005b2c:	4905                	li	s2,1
    80005b2e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005b32:	8552                	mv	a0,s4
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	50a080e7          	jalr	1290(ra) # 8000403e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b3c:	000b059b          	sext.w	a1,s6
    80005b40:	03258b63          	beq	a1,s2,80005b76 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b44:	004a2603          	lw	a2,4(s4)
    80005b48:	fb040593          	addi	a1,s0,-80
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	cae080e7          	jalr	-850(ra) # 800047fc <dirlink>
    80005b56:	06054f63          	bltz	a0,80005bd4 <create+0x162>
  iunlockput(dp);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	80e080e7          	jalr	-2034(ra) # 8000436a <iunlockput>
  return ip;
    80005b64:	8ad2                	mv	s5,s4
    80005b66:	b749                	j	80005ae8 <create+0x76>
    iunlockput(dp);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	800080e7          	jalr	-2048(ra) # 8000436a <iunlockput>
    return 0;
    80005b72:	8ad2                	mv	s5,s4
    80005b74:	bf95                	j	80005ae8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b76:	004a2603          	lw	a2,4(s4)
    80005b7a:	00003597          	auipc	a1,0x3
    80005b7e:	d6e58593          	addi	a1,a1,-658 # 800088e8 <syscalls+0x460>
    80005b82:	8552                	mv	a0,s4
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	c78080e7          	jalr	-904(ra) # 800047fc <dirlink>
    80005b8c:	04054463          	bltz	a0,80005bd4 <create+0x162>
    80005b90:	40d0                	lw	a2,4(s1)
    80005b92:	00003597          	auipc	a1,0x3
    80005b96:	d5e58593          	addi	a1,a1,-674 # 800088f0 <syscalls+0x468>
    80005b9a:	8552                	mv	a0,s4
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	c60080e7          	jalr	-928(ra) # 800047fc <dirlink>
    80005ba4:	02054863          	bltz	a0,80005bd4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ba8:	004a2603          	lw	a2,4(s4)
    80005bac:	fb040593          	addi	a1,s0,-80
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	c4a080e7          	jalr	-950(ra) # 800047fc <dirlink>
    80005bba:	00054d63          	bltz	a0,80005bd4 <create+0x162>
    dp->nlink++;  // for ".."
    80005bbe:	04a4d783          	lhu	a5,74(s1)
    80005bc2:	2785                	addiw	a5,a5,1
    80005bc4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	474080e7          	jalr	1140(ra) # 8000403e <iupdate>
    80005bd2:	b761                	j	80005b5a <create+0xe8>
  ip->nlink = 0;
    80005bd4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005bd8:	8552                	mv	a0,s4
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	464080e7          	jalr	1124(ra) # 8000403e <iupdate>
  iunlockput(ip);
    80005be2:	8552                	mv	a0,s4
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	786080e7          	jalr	1926(ra) # 8000436a <iunlockput>
  iunlockput(dp);
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	77c080e7          	jalr	1916(ra) # 8000436a <iunlockput>
  return 0;
    80005bf6:	bdcd                	j	80005ae8 <create+0x76>
    return 0;
    80005bf8:	8aaa                	mv	s5,a0
    80005bfa:	b5fd                	j	80005ae8 <create+0x76>

0000000080005bfc <sys_dup>:
{
    80005bfc:	7179                	addi	sp,sp,-48
    80005bfe:	f406                	sd	ra,40(sp)
    80005c00:	f022                	sd	s0,32(sp)
    80005c02:	ec26                	sd	s1,24(sp)
    80005c04:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c06:	fd840613          	addi	a2,s0,-40
    80005c0a:	4581                	li	a1,0
    80005c0c:	4501                	li	a0,0
    80005c0e:	00000097          	auipc	ra,0x0
    80005c12:	dc2080e7          	jalr	-574(ra) # 800059d0 <argfd>
    return -1;
    80005c16:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c18:	02054363          	bltz	a0,80005c3e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005c1c:	fd843503          	ld	a0,-40(s0)
    80005c20:	00000097          	auipc	ra,0x0
    80005c24:	e10080e7          	jalr	-496(ra) # 80005a30 <fdalloc>
    80005c28:	84aa                	mv	s1,a0
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c2c:	00054963          	bltz	a0,80005c3e <sys_dup+0x42>
  filedup(f);
    80005c30:	fd843503          	ld	a0,-40(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	310080e7          	jalr	784(ra) # 80004f44 <filedup>
  return fd;
    80005c3c:	87a6                	mv	a5,s1
}
    80005c3e:	853e                	mv	a0,a5
    80005c40:	70a2                	ld	ra,40(sp)
    80005c42:	7402                	ld	s0,32(sp)
    80005c44:	64e2                	ld	s1,24(sp)
    80005c46:	6145                	addi	sp,sp,48
    80005c48:	8082                	ret

0000000080005c4a <sys_read>:
{
    80005c4a:	7179                	addi	sp,sp,-48
    80005c4c:	f406                	sd	ra,40(sp)
    80005c4e:	f022                	sd	s0,32(sp)
    80005c50:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005c52:	fd840593          	addi	a1,s0,-40
    80005c56:	4505                	li	a0,1
    80005c58:	ffffd097          	auipc	ra,0xffffd
    80005c5c:	69a080e7          	jalr	1690(ra) # 800032f2 <argaddr>
  argint(2, &n);
    80005c60:	fe440593          	addi	a1,s0,-28
    80005c64:	4509                	li	a0,2
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	66c080e7          	jalr	1644(ra) # 800032d2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005c6e:	fe840613          	addi	a2,s0,-24
    80005c72:	4581                	li	a1,0
    80005c74:	4501                	li	a0,0
    80005c76:	00000097          	auipc	ra,0x0
    80005c7a:	d5a080e7          	jalr	-678(ra) # 800059d0 <argfd>
    80005c7e:	87aa                	mv	a5,a0
    return -1;
    80005c80:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c82:	0007cc63          	bltz	a5,80005c9a <sys_read+0x50>
  return fileread(f, p, n);
    80005c86:	fe442603          	lw	a2,-28(s0)
    80005c8a:	fd843583          	ld	a1,-40(s0)
    80005c8e:	fe843503          	ld	a0,-24(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	43e080e7          	jalr	1086(ra) # 800050d0 <fileread>
}
    80005c9a:	70a2                	ld	ra,40(sp)
    80005c9c:	7402                	ld	s0,32(sp)
    80005c9e:	6145                	addi	sp,sp,48
    80005ca0:	8082                	ret

0000000080005ca2 <sys_write>:
{
    80005ca2:	7179                	addi	sp,sp,-48
    80005ca4:	f406                	sd	ra,40(sp)
    80005ca6:	f022                	sd	s0,32(sp)
    80005ca8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005caa:	fd840593          	addi	a1,s0,-40
    80005cae:	4505                	li	a0,1
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	642080e7          	jalr	1602(ra) # 800032f2 <argaddr>
  argint(2, &n);
    80005cb8:	fe440593          	addi	a1,s0,-28
    80005cbc:	4509                	li	a0,2
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	614080e7          	jalr	1556(ra) # 800032d2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005cc6:	fe840613          	addi	a2,s0,-24
    80005cca:	4581                	li	a1,0
    80005ccc:	4501                	li	a0,0
    80005cce:	00000097          	auipc	ra,0x0
    80005cd2:	d02080e7          	jalr	-766(ra) # 800059d0 <argfd>
    80005cd6:	87aa                	mv	a5,a0
    return -1;
    80005cd8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cda:	0007cc63          	bltz	a5,80005cf2 <sys_write+0x50>
  return filewrite(f, p, n);
    80005cde:	fe442603          	lw	a2,-28(s0)
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	fe843503          	ld	a0,-24(s0)
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	4a8080e7          	jalr	1192(ra) # 80005192 <filewrite>
}
    80005cf2:	70a2                	ld	ra,40(sp)
    80005cf4:	7402                	ld	s0,32(sp)
    80005cf6:	6145                	addi	sp,sp,48
    80005cf8:	8082                	ret

0000000080005cfa <sys_close>:
{
    80005cfa:	1101                	addi	sp,sp,-32
    80005cfc:	ec06                	sd	ra,24(sp)
    80005cfe:	e822                	sd	s0,16(sp)
    80005d00:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d02:	fe040613          	addi	a2,s0,-32
    80005d06:	fec40593          	addi	a1,s0,-20
    80005d0a:	4501                	li	a0,0
    80005d0c:	00000097          	auipc	ra,0x0
    80005d10:	cc4080e7          	jalr	-828(ra) # 800059d0 <argfd>
    return -1;
    80005d14:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d16:	02054463          	bltz	a0,80005d3e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d1a:	ffffc097          	auipc	ra,0xffffc
    80005d1e:	e80080e7          	jalr	-384(ra) # 80001b9a <myproc>
    80005d22:	fec42783          	lw	a5,-20(s0)
    80005d26:	07e9                	addi	a5,a5,26
    80005d28:	078e                	slli	a5,a5,0x3
    80005d2a:	97aa                	add	a5,a5,a0
    80005d2c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005d30:	fe043503          	ld	a0,-32(s0)
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	262080e7          	jalr	610(ra) # 80004f96 <fileclose>
  return 0;
    80005d3c:	4781                	li	a5,0
}
    80005d3e:	853e                	mv	a0,a5
    80005d40:	60e2                	ld	ra,24(sp)
    80005d42:	6442                	ld	s0,16(sp)
    80005d44:	6105                	addi	sp,sp,32
    80005d46:	8082                	ret

0000000080005d48 <sys_fstat>:
{
    80005d48:	1101                	addi	sp,sp,-32
    80005d4a:	ec06                	sd	ra,24(sp)
    80005d4c:	e822                	sd	s0,16(sp)
    80005d4e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005d50:	fe040593          	addi	a1,s0,-32
    80005d54:	4505                	li	a0,1
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	59c080e7          	jalr	1436(ra) # 800032f2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005d5e:	fe840613          	addi	a2,s0,-24
    80005d62:	4581                	li	a1,0
    80005d64:	4501                	li	a0,0
    80005d66:	00000097          	auipc	ra,0x0
    80005d6a:	c6a080e7          	jalr	-918(ra) # 800059d0 <argfd>
    80005d6e:	87aa                	mv	a5,a0
    return -1;
    80005d70:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d72:	0007ca63          	bltz	a5,80005d86 <sys_fstat+0x3e>
  return filestat(f, st);
    80005d76:	fe043583          	ld	a1,-32(s0)
    80005d7a:	fe843503          	ld	a0,-24(s0)
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	2e0080e7          	jalr	736(ra) # 8000505e <filestat>
}
    80005d86:	60e2                	ld	ra,24(sp)
    80005d88:	6442                	ld	s0,16(sp)
    80005d8a:	6105                	addi	sp,sp,32
    80005d8c:	8082                	ret

0000000080005d8e <sys_link>:
{
    80005d8e:	7169                	addi	sp,sp,-304
    80005d90:	f606                	sd	ra,296(sp)
    80005d92:	f222                	sd	s0,288(sp)
    80005d94:	ee26                	sd	s1,280(sp)
    80005d96:	ea4a                	sd	s2,272(sp)
    80005d98:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d9a:	08000613          	li	a2,128
    80005d9e:	ed040593          	addi	a1,s0,-304
    80005da2:	4501                	li	a0,0
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	56e080e7          	jalr	1390(ra) # 80003312 <argstr>
    return -1;
    80005dac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005dae:	10054e63          	bltz	a0,80005eca <sys_link+0x13c>
    80005db2:	08000613          	li	a2,128
    80005db6:	f5040593          	addi	a1,s0,-176
    80005dba:	4505                	li	a0,1
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	556080e7          	jalr	1366(ra) # 80003312 <argstr>
    return -1;
    80005dc4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005dc6:	10054263          	bltz	a0,80005eca <sys_link+0x13c>
  begin_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	d00080e7          	jalr	-768(ra) # 80004aca <begin_op>
  if((ip = namei(old)) == 0){
    80005dd2:	ed040513          	addi	a0,s0,-304
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	ad8080e7          	jalr	-1320(ra) # 800048ae <namei>
    80005dde:	84aa                	mv	s1,a0
    80005de0:	c551                	beqz	a0,80005e6c <sys_link+0xde>
  ilock(ip);
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	326080e7          	jalr	806(ra) # 80004108 <ilock>
  if(ip->type == T_DIR){
    80005dea:	04449703          	lh	a4,68(s1)
    80005dee:	4785                	li	a5,1
    80005df0:	08f70463          	beq	a4,a5,80005e78 <sys_link+0xea>
  ip->nlink++;
    80005df4:	04a4d783          	lhu	a5,74(s1)
    80005df8:	2785                	addiw	a5,a5,1
    80005dfa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	23e080e7          	jalr	574(ra) # 8000403e <iupdate>
  iunlock(ip);
    80005e08:	8526                	mv	a0,s1
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	3c0080e7          	jalr	960(ra) # 800041ca <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e12:	fd040593          	addi	a1,s0,-48
    80005e16:	f5040513          	addi	a0,s0,-176
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	ab2080e7          	jalr	-1358(ra) # 800048cc <nameiparent>
    80005e22:	892a                	mv	s2,a0
    80005e24:	c935                	beqz	a0,80005e98 <sys_link+0x10a>
  ilock(dp);
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	2e2080e7          	jalr	738(ra) # 80004108 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e2e:	00092703          	lw	a4,0(s2)
    80005e32:	409c                	lw	a5,0(s1)
    80005e34:	04f71d63          	bne	a4,a5,80005e8e <sys_link+0x100>
    80005e38:	40d0                	lw	a2,4(s1)
    80005e3a:	fd040593          	addi	a1,s0,-48
    80005e3e:	854a                	mv	a0,s2
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	9bc080e7          	jalr	-1604(ra) # 800047fc <dirlink>
    80005e48:	04054363          	bltz	a0,80005e8e <sys_link+0x100>
  iunlockput(dp);
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	51c080e7          	jalr	1308(ra) # 8000436a <iunlockput>
  iput(ip);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	46a080e7          	jalr	1130(ra) # 800042c2 <iput>
  end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	cea080e7          	jalr	-790(ra) # 80004b4a <end_op>
  return 0;
    80005e68:	4781                	li	a5,0
    80005e6a:	a085                	j	80005eca <sys_link+0x13c>
    end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	cde080e7          	jalr	-802(ra) # 80004b4a <end_op>
    return -1;
    80005e74:	57fd                	li	a5,-1
    80005e76:	a891                	j	80005eca <sys_link+0x13c>
    iunlockput(ip);
    80005e78:	8526                	mv	a0,s1
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	4f0080e7          	jalr	1264(ra) # 8000436a <iunlockput>
    end_op();
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	cc8080e7          	jalr	-824(ra) # 80004b4a <end_op>
    return -1;
    80005e8a:	57fd                	li	a5,-1
    80005e8c:	a83d                	j	80005eca <sys_link+0x13c>
    iunlockput(dp);
    80005e8e:	854a                	mv	a0,s2
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	4da080e7          	jalr	1242(ra) # 8000436a <iunlockput>
  ilock(ip);
    80005e98:	8526                	mv	a0,s1
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	26e080e7          	jalr	622(ra) # 80004108 <ilock>
  ip->nlink--;
    80005ea2:	04a4d783          	lhu	a5,74(s1)
    80005ea6:	37fd                	addiw	a5,a5,-1
    80005ea8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005eac:	8526                	mv	a0,s1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	190080e7          	jalr	400(ra) # 8000403e <iupdate>
  iunlockput(ip);
    80005eb6:	8526                	mv	a0,s1
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	4b2080e7          	jalr	1202(ra) # 8000436a <iunlockput>
  end_op();
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	c8a080e7          	jalr	-886(ra) # 80004b4a <end_op>
  return -1;
    80005ec8:	57fd                	li	a5,-1
}
    80005eca:	853e                	mv	a0,a5
    80005ecc:	70b2                	ld	ra,296(sp)
    80005ece:	7412                	ld	s0,288(sp)
    80005ed0:	64f2                	ld	s1,280(sp)
    80005ed2:	6952                	ld	s2,272(sp)
    80005ed4:	6155                	addi	sp,sp,304
    80005ed6:	8082                	ret

0000000080005ed8 <sys_unlink>:
{
    80005ed8:	7151                	addi	sp,sp,-240
    80005eda:	f586                	sd	ra,232(sp)
    80005edc:	f1a2                	sd	s0,224(sp)
    80005ede:	eda6                	sd	s1,216(sp)
    80005ee0:	e9ca                	sd	s2,208(sp)
    80005ee2:	e5ce                	sd	s3,200(sp)
    80005ee4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ee6:	08000613          	li	a2,128
    80005eea:	f3040593          	addi	a1,s0,-208
    80005eee:	4501                	li	a0,0
    80005ef0:	ffffd097          	auipc	ra,0xffffd
    80005ef4:	422080e7          	jalr	1058(ra) # 80003312 <argstr>
    80005ef8:	18054163          	bltz	a0,8000607a <sys_unlink+0x1a2>
  begin_op();
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	bce080e7          	jalr	-1074(ra) # 80004aca <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f04:	fb040593          	addi	a1,s0,-80
    80005f08:	f3040513          	addi	a0,s0,-208
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	9c0080e7          	jalr	-1600(ra) # 800048cc <nameiparent>
    80005f14:	84aa                	mv	s1,a0
    80005f16:	c979                	beqz	a0,80005fec <sys_unlink+0x114>
  ilock(dp);
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	1f0080e7          	jalr	496(ra) # 80004108 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f20:	00003597          	auipc	a1,0x3
    80005f24:	9c858593          	addi	a1,a1,-1592 # 800088e8 <syscalls+0x460>
    80005f28:	fb040513          	addi	a0,s0,-80
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	6a6080e7          	jalr	1702(ra) # 800045d2 <namecmp>
    80005f34:	14050a63          	beqz	a0,80006088 <sys_unlink+0x1b0>
    80005f38:	00003597          	auipc	a1,0x3
    80005f3c:	9b858593          	addi	a1,a1,-1608 # 800088f0 <syscalls+0x468>
    80005f40:	fb040513          	addi	a0,s0,-80
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	68e080e7          	jalr	1678(ra) # 800045d2 <namecmp>
    80005f4c:	12050e63          	beqz	a0,80006088 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f50:	f2c40613          	addi	a2,s0,-212
    80005f54:	fb040593          	addi	a1,s0,-80
    80005f58:	8526                	mv	a0,s1
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	692080e7          	jalr	1682(ra) # 800045ec <dirlookup>
    80005f62:	892a                	mv	s2,a0
    80005f64:	12050263          	beqz	a0,80006088 <sys_unlink+0x1b0>
  ilock(ip);
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	1a0080e7          	jalr	416(ra) # 80004108 <ilock>
  if(ip->nlink < 1)
    80005f70:	04a91783          	lh	a5,74(s2)
    80005f74:	08f05263          	blez	a5,80005ff8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f78:	04491703          	lh	a4,68(s2)
    80005f7c:	4785                	li	a5,1
    80005f7e:	08f70563          	beq	a4,a5,80006008 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f82:	4641                	li	a2,16
    80005f84:	4581                	li	a1,0
    80005f86:	fc040513          	addi	a0,s0,-64
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	d48080e7          	jalr	-696(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f92:	4741                	li	a4,16
    80005f94:	f2c42683          	lw	a3,-212(s0)
    80005f98:	fc040613          	addi	a2,s0,-64
    80005f9c:	4581                	li	a1,0
    80005f9e:	8526                	mv	a0,s1
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	514080e7          	jalr	1300(ra) # 800044b4 <writei>
    80005fa8:	47c1                	li	a5,16
    80005faa:	0af51563          	bne	a0,a5,80006054 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005fae:	04491703          	lh	a4,68(s2)
    80005fb2:	4785                	li	a5,1
    80005fb4:	0af70863          	beq	a4,a5,80006064 <sys_unlink+0x18c>
  iunlockput(dp);
    80005fb8:	8526                	mv	a0,s1
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	3b0080e7          	jalr	944(ra) # 8000436a <iunlockput>
  ip->nlink--;
    80005fc2:	04a95783          	lhu	a5,74(s2)
    80005fc6:	37fd                	addiw	a5,a5,-1
    80005fc8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fcc:	854a                	mv	a0,s2
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	070080e7          	jalr	112(ra) # 8000403e <iupdate>
  iunlockput(ip);
    80005fd6:	854a                	mv	a0,s2
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	392080e7          	jalr	914(ra) # 8000436a <iunlockput>
  end_op();
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	b6a080e7          	jalr	-1174(ra) # 80004b4a <end_op>
  return 0;
    80005fe8:	4501                	li	a0,0
    80005fea:	a84d                	j	8000609c <sys_unlink+0x1c4>
    end_op();
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	b5e080e7          	jalr	-1186(ra) # 80004b4a <end_op>
    return -1;
    80005ff4:	557d                	li	a0,-1
    80005ff6:	a05d                	j	8000609c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ff8:	00003517          	auipc	a0,0x3
    80005ffc:	90050513          	addi	a0,a0,-1792 # 800088f8 <syscalls+0x470>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006008:	04c92703          	lw	a4,76(s2)
    8000600c:	02000793          	li	a5,32
    80006010:	f6e7f9e3          	bgeu	a5,a4,80005f82 <sys_unlink+0xaa>
    80006014:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006018:	4741                	li	a4,16
    8000601a:	86ce                	mv	a3,s3
    8000601c:	f1840613          	addi	a2,s0,-232
    80006020:	4581                	li	a1,0
    80006022:	854a                	mv	a0,s2
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	398080e7          	jalr	920(ra) # 800043bc <readi>
    8000602c:	47c1                	li	a5,16
    8000602e:	00f51b63          	bne	a0,a5,80006044 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006032:	f1845783          	lhu	a5,-232(s0)
    80006036:	e7a1                	bnez	a5,8000607e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006038:	29c1                	addiw	s3,s3,16
    8000603a:	04c92783          	lw	a5,76(s2)
    8000603e:	fcf9ede3          	bltu	s3,a5,80006018 <sys_unlink+0x140>
    80006042:	b781                	j	80005f82 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006044:	00003517          	auipc	a0,0x3
    80006048:	8cc50513          	addi	a0,a0,-1844 # 80008910 <syscalls+0x488>
    8000604c:	ffffa097          	auipc	ra,0xffffa
    80006050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006054:	00003517          	auipc	a0,0x3
    80006058:	8d450513          	addi	a0,a0,-1836 # 80008928 <syscalls+0x4a0>
    8000605c:	ffffa097          	auipc	ra,0xffffa
    80006060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
    dp->nlink--;
    80006064:	04a4d783          	lhu	a5,74(s1)
    80006068:	37fd                	addiw	a5,a5,-1
    8000606a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000606e:	8526                	mv	a0,s1
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	fce080e7          	jalr	-50(ra) # 8000403e <iupdate>
    80006078:	b781                	j	80005fb8 <sys_unlink+0xe0>
    return -1;
    8000607a:	557d                	li	a0,-1
    8000607c:	a005                	j	8000609c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000607e:	854a                	mv	a0,s2
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	2ea080e7          	jalr	746(ra) # 8000436a <iunlockput>
  iunlockput(dp);
    80006088:	8526                	mv	a0,s1
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	2e0080e7          	jalr	736(ra) # 8000436a <iunlockput>
  end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	ab8080e7          	jalr	-1352(ra) # 80004b4a <end_op>
  return -1;
    8000609a:	557d                	li	a0,-1
}
    8000609c:	70ae                	ld	ra,232(sp)
    8000609e:	740e                	ld	s0,224(sp)
    800060a0:	64ee                	ld	s1,216(sp)
    800060a2:	694e                	ld	s2,208(sp)
    800060a4:	69ae                	ld	s3,200(sp)
    800060a6:	616d                	addi	sp,sp,240
    800060a8:	8082                	ret

00000000800060aa <sys_open>:

uint64
sys_open(void)
{
    800060aa:	7131                	addi	sp,sp,-192
    800060ac:	fd06                	sd	ra,184(sp)
    800060ae:	f922                	sd	s0,176(sp)
    800060b0:	f526                	sd	s1,168(sp)
    800060b2:	f14a                	sd	s2,160(sp)
    800060b4:	ed4e                	sd	s3,152(sp)
    800060b6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800060b8:	f4c40593          	addi	a1,s0,-180
    800060bc:	4505                	li	a0,1
    800060be:	ffffd097          	auipc	ra,0xffffd
    800060c2:	214080e7          	jalr	532(ra) # 800032d2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060c6:	08000613          	li	a2,128
    800060ca:	f5040593          	addi	a1,s0,-176
    800060ce:	4501                	li	a0,0
    800060d0:	ffffd097          	auipc	ra,0xffffd
    800060d4:	242080e7          	jalr	578(ra) # 80003312 <argstr>
    800060d8:	87aa                	mv	a5,a0
    return -1;
    800060da:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060dc:	0a07c963          	bltz	a5,8000618e <sys_open+0xe4>
    
  begin_op();
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	9ea080e7          	jalr	-1558(ra) # 80004aca <begin_op>

  if(omode & O_CREATE){
    800060e8:	f4c42783          	lw	a5,-180(s0)
    800060ec:	2007f793          	andi	a5,a5,512
    800060f0:	cfc5                	beqz	a5,800061a8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800060f2:	4681                	li	a3,0
    800060f4:	4601                	li	a2,0
    800060f6:	4589                	li	a1,2
    800060f8:	f5040513          	addi	a0,s0,-176
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	976080e7          	jalr	-1674(ra) # 80005a72 <create>
    80006104:	84aa                	mv	s1,a0
    if(ip == 0){
    80006106:	c959                	beqz	a0,8000619c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006108:	04449703          	lh	a4,68(s1)
    8000610c:	478d                	li	a5,3
    8000610e:	00f71763          	bne	a4,a5,8000611c <sys_open+0x72>
    80006112:	0464d703          	lhu	a4,70(s1)
    80006116:	47a5                	li	a5,9
    80006118:	0ce7ed63          	bltu	a5,a4,800061f2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000611c:	fffff097          	auipc	ra,0xfffff
    80006120:	dbe080e7          	jalr	-578(ra) # 80004eda <filealloc>
    80006124:	89aa                	mv	s3,a0
    80006126:	10050363          	beqz	a0,8000622c <sys_open+0x182>
    8000612a:	00000097          	auipc	ra,0x0
    8000612e:	906080e7          	jalr	-1786(ra) # 80005a30 <fdalloc>
    80006132:	892a                	mv	s2,a0
    80006134:	0e054763          	bltz	a0,80006222 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006138:	04449703          	lh	a4,68(s1)
    8000613c:	478d                	li	a5,3
    8000613e:	0cf70563          	beq	a4,a5,80006208 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006142:	4789                	li	a5,2
    80006144:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006148:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000614c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006150:	f4c42783          	lw	a5,-180(s0)
    80006154:	0017c713          	xori	a4,a5,1
    80006158:	8b05                	andi	a4,a4,1
    8000615a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000615e:	0037f713          	andi	a4,a5,3
    80006162:	00e03733          	snez	a4,a4
    80006166:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000616a:	4007f793          	andi	a5,a5,1024
    8000616e:	c791                	beqz	a5,8000617a <sys_open+0xd0>
    80006170:	04449703          	lh	a4,68(s1)
    80006174:	4789                	li	a5,2
    80006176:	0af70063          	beq	a4,a5,80006216 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000617a:	8526                	mv	a0,s1
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	04e080e7          	jalr	78(ra) # 800041ca <iunlock>
  end_op();
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	9c6080e7          	jalr	-1594(ra) # 80004b4a <end_op>

  return fd;
    8000618c:	854a                	mv	a0,s2
}
    8000618e:	70ea                	ld	ra,184(sp)
    80006190:	744a                	ld	s0,176(sp)
    80006192:	74aa                	ld	s1,168(sp)
    80006194:	790a                	ld	s2,160(sp)
    80006196:	69ea                	ld	s3,152(sp)
    80006198:	6129                	addi	sp,sp,192
    8000619a:	8082                	ret
      end_op();
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	9ae080e7          	jalr	-1618(ra) # 80004b4a <end_op>
      return -1;
    800061a4:	557d                	li	a0,-1
    800061a6:	b7e5                	j	8000618e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800061a8:	f5040513          	addi	a0,s0,-176
    800061ac:	ffffe097          	auipc	ra,0xffffe
    800061b0:	702080e7          	jalr	1794(ra) # 800048ae <namei>
    800061b4:	84aa                	mv	s1,a0
    800061b6:	c905                	beqz	a0,800061e6 <sys_open+0x13c>
    ilock(ip);
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	f50080e7          	jalr	-176(ra) # 80004108 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800061c0:	04449703          	lh	a4,68(s1)
    800061c4:	4785                	li	a5,1
    800061c6:	f4f711e3          	bne	a4,a5,80006108 <sys_open+0x5e>
    800061ca:	f4c42783          	lw	a5,-180(s0)
    800061ce:	d7b9                	beqz	a5,8000611c <sys_open+0x72>
      iunlockput(ip);
    800061d0:	8526                	mv	a0,s1
    800061d2:	ffffe097          	auipc	ra,0xffffe
    800061d6:	198080e7          	jalr	408(ra) # 8000436a <iunlockput>
      end_op();
    800061da:	fffff097          	auipc	ra,0xfffff
    800061de:	970080e7          	jalr	-1680(ra) # 80004b4a <end_op>
      return -1;
    800061e2:	557d                	li	a0,-1
    800061e4:	b76d                	j	8000618e <sys_open+0xe4>
      end_op();
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	964080e7          	jalr	-1692(ra) # 80004b4a <end_op>
      return -1;
    800061ee:	557d                	li	a0,-1
    800061f0:	bf79                	j	8000618e <sys_open+0xe4>
    iunlockput(ip);
    800061f2:	8526                	mv	a0,s1
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	176080e7          	jalr	374(ra) # 8000436a <iunlockput>
    end_op();
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	94e080e7          	jalr	-1714(ra) # 80004b4a <end_op>
    return -1;
    80006204:	557d                	li	a0,-1
    80006206:	b761                	j	8000618e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006208:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000620c:	04649783          	lh	a5,70(s1)
    80006210:	02f99223          	sh	a5,36(s3)
    80006214:	bf25                	j	8000614c <sys_open+0xa2>
    itrunc(ip);
    80006216:	8526                	mv	a0,s1
    80006218:	ffffe097          	auipc	ra,0xffffe
    8000621c:	ffe080e7          	jalr	-2(ra) # 80004216 <itrunc>
    80006220:	bfa9                	j	8000617a <sys_open+0xd0>
      fileclose(f);
    80006222:	854e                	mv	a0,s3
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	d72080e7          	jalr	-654(ra) # 80004f96 <fileclose>
    iunlockput(ip);
    8000622c:	8526                	mv	a0,s1
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	13c080e7          	jalr	316(ra) # 8000436a <iunlockput>
    end_op();
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	914080e7          	jalr	-1772(ra) # 80004b4a <end_op>
    return -1;
    8000623e:	557d                	li	a0,-1
    80006240:	b7b9                	j	8000618e <sys_open+0xe4>

0000000080006242 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006242:	7175                	addi	sp,sp,-144
    80006244:	e506                	sd	ra,136(sp)
    80006246:	e122                	sd	s0,128(sp)
    80006248:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	880080e7          	jalr	-1920(ra) # 80004aca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006252:	08000613          	li	a2,128
    80006256:	f7040593          	addi	a1,s0,-144
    8000625a:	4501                	li	a0,0
    8000625c:	ffffd097          	auipc	ra,0xffffd
    80006260:	0b6080e7          	jalr	182(ra) # 80003312 <argstr>
    80006264:	02054963          	bltz	a0,80006296 <sys_mkdir+0x54>
    80006268:	4681                	li	a3,0
    8000626a:	4601                	li	a2,0
    8000626c:	4585                	li	a1,1
    8000626e:	f7040513          	addi	a0,s0,-144
    80006272:	00000097          	auipc	ra,0x0
    80006276:	800080e7          	jalr	-2048(ra) # 80005a72 <create>
    8000627a:	cd11                	beqz	a0,80006296 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000627c:	ffffe097          	auipc	ra,0xffffe
    80006280:	0ee080e7          	jalr	238(ra) # 8000436a <iunlockput>
  end_op();
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	8c6080e7          	jalr	-1850(ra) # 80004b4a <end_op>
  return 0;
    8000628c:	4501                	li	a0,0
}
    8000628e:	60aa                	ld	ra,136(sp)
    80006290:	640a                	ld	s0,128(sp)
    80006292:	6149                	addi	sp,sp,144
    80006294:	8082                	ret
    end_op();
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	8b4080e7          	jalr	-1868(ra) # 80004b4a <end_op>
    return -1;
    8000629e:	557d                	li	a0,-1
    800062a0:	b7fd                	j	8000628e <sys_mkdir+0x4c>

00000000800062a2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800062a2:	7135                	addi	sp,sp,-160
    800062a4:	ed06                	sd	ra,152(sp)
    800062a6:	e922                	sd	s0,144(sp)
    800062a8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	820080e7          	jalr	-2016(ra) # 80004aca <begin_op>
  argint(1, &major);
    800062b2:	f6c40593          	addi	a1,s0,-148
    800062b6:	4505                	li	a0,1
    800062b8:	ffffd097          	auipc	ra,0xffffd
    800062bc:	01a080e7          	jalr	26(ra) # 800032d2 <argint>
  argint(2, &minor);
    800062c0:	f6840593          	addi	a1,s0,-152
    800062c4:	4509                	li	a0,2
    800062c6:	ffffd097          	auipc	ra,0xffffd
    800062ca:	00c080e7          	jalr	12(ra) # 800032d2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062ce:	08000613          	li	a2,128
    800062d2:	f7040593          	addi	a1,s0,-144
    800062d6:	4501                	li	a0,0
    800062d8:	ffffd097          	auipc	ra,0xffffd
    800062dc:	03a080e7          	jalr	58(ra) # 80003312 <argstr>
    800062e0:	02054b63          	bltz	a0,80006316 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062e4:	f6841683          	lh	a3,-152(s0)
    800062e8:	f6c41603          	lh	a2,-148(s0)
    800062ec:	458d                	li	a1,3
    800062ee:	f7040513          	addi	a0,s0,-144
    800062f2:	fffff097          	auipc	ra,0xfffff
    800062f6:	780080e7          	jalr	1920(ra) # 80005a72 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062fa:	cd11                	beqz	a0,80006316 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062fc:	ffffe097          	auipc	ra,0xffffe
    80006300:	06e080e7          	jalr	110(ra) # 8000436a <iunlockput>
  end_op();
    80006304:	fffff097          	auipc	ra,0xfffff
    80006308:	846080e7          	jalr	-1978(ra) # 80004b4a <end_op>
  return 0;
    8000630c:	4501                	li	a0,0
}
    8000630e:	60ea                	ld	ra,152(sp)
    80006310:	644a                	ld	s0,144(sp)
    80006312:	610d                	addi	sp,sp,160
    80006314:	8082                	ret
    end_op();
    80006316:	fffff097          	auipc	ra,0xfffff
    8000631a:	834080e7          	jalr	-1996(ra) # 80004b4a <end_op>
    return -1;
    8000631e:	557d                	li	a0,-1
    80006320:	b7fd                	j	8000630e <sys_mknod+0x6c>

0000000080006322 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006322:	7135                	addi	sp,sp,-160
    80006324:	ed06                	sd	ra,152(sp)
    80006326:	e922                	sd	s0,144(sp)
    80006328:	e526                	sd	s1,136(sp)
    8000632a:	e14a                	sd	s2,128(sp)
    8000632c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000632e:	ffffc097          	auipc	ra,0xffffc
    80006332:	86c080e7          	jalr	-1940(ra) # 80001b9a <myproc>
    80006336:	892a                	mv	s2,a0
  
  begin_op();
    80006338:	ffffe097          	auipc	ra,0xffffe
    8000633c:	792080e7          	jalr	1938(ra) # 80004aca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006340:	08000613          	li	a2,128
    80006344:	f6040593          	addi	a1,s0,-160
    80006348:	4501                	li	a0,0
    8000634a:	ffffd097          	auipc	ra,0xffffd
    8000634e:	fc8080e7          	jalr	-56(ra) # 80003312 <argstr>
    80006352:	04054b63          	bltz	a0,800063a8 <sys_chdir+0x86>
    80006356:	f6040513          	addi	a0,s0,-160
    8000635a:	ffffe097          	auipc	ra,0xffffe
    8000635e:	554080e7          	jalr	1364(ra) # 800048ae <namei>
    80006362:	84aa                	mv	s1,a0
    80006364:	c131                	beqz	a0,800063a8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006366:	ffffe097          	auipc	ra,0xffffe
    8000636a:	da2080e7          	jalr	-606(ra) # 80004108 <ilock>
  if(ip->type != T_DIR){
    8000636e:	04449703          	lh	a4,68(s1)
    80006372:	4785                	li	a5,1
    80006374:	04f71063          	bne	a4,a5,800063b4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006378:	8526                	mv	a0,s1
    8000637a:	ffffe097          	auipc	ra,0xffffe
    8000637e:	e50080e7          	jalr	-432(ra) # 800041ca <iunlock>
  iput(p->cwd);
    80006382:	15093503          	ld	a0,336(s2)
    80006386:	ffffe097          	auipc	ra,0xffffe
    8000638a:	f3c080e7          	jalr	-196(ra) # 800042c2 <iput>
  end_op();
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	7bc080e7          	jalr	1980(ra) # 80004b4a <end_op>
  p->cwd = ip;
    80006396:	14993823          	sd	s1,336(s2)
  return 0;
    8000639a:	4501                	li	a0,0
}
    8000639c:	60ea                	ld	ra,152(sp)
    8000639e:	644a                	ld	s0,144(sp)
    800063a0:	64aa                	ld	s1,136(sp)
    800063a2:	690a                	ld	s2,128(sp)
    800063a4:	610d                	addi	sp,sp,160
    800063a6:	8082                	ret
    end_op();
    800063a8:	ffffe097          	auipc	ra,0xffffe
    800063ac:	7a2080e7          	jalr	1954(ra) # 80004b4a <end_op>
    return -1;
    800063b0:	557d                	li	a0,-1
    800063b2:	b7ed                	j	8000639c <sys_chdir+0x7a>
    iunlockput(ip);
    800063b4:	8526                	mv	a0,s1
    800063b6:	ffffe097          	auipc	ra,0xffffe
    800063ba:	fb4080e7          	jalr	-76(ra) # 8000436a <iunlockput>
    end_op();
    800063be:	ffffe097          	auipc	ra,0xffffe
    800063c2:	78c080e7          	jalr	1932(ra) # 80004b4a <end_op>
    return -1;
    800063c6:	557d                	li	a0,-1
    800063c8:	bfd1                	j	8000639c <sys_chdir+0x7a>

00000000800063ca <sys_exec>:

uint64
sys_exec(void)
{
    800063ca:	7145                	addi	sp,sp,-464
    800063cc:	e786                	sd	ra,456(sp)
    800063ce:	e3a2                	sd	s0,448(sp)
    800063d0:	ff26                	sd	s1,440(sp)
    800063d2:	fb4a                	sd	s2,432(sp)
    800063d4:	f74e                	sd	s3,424(sp)
    800063d6:	f352                	sd	s4,416(sp)
    800063d8:	ef56                	sd	s5,408(sp)
    800063da:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800063dc:	e3840593          	addi	a1,s0,-456
    800063e0:	4505                	li	a0,1
    800063e2:	ffffd097          	auipc	ra,0xffffd
    800063e6:	f10080e7          	jalr	-240(ra) # 800032f2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800063ea:	08000613          	li	a2,128
    800063ee:	f4040593          	addi	a1,s0,-192
    800063f2:	4501                	li	a0,0
    800063f4:	ffffd097          	auipc	ra,0xffffd
    800063f8:	f1e080e7          	jalr	-226(ra) # 80003312 <argstr>
    800063fc:	87aa                	mv	a5,a0
    return -1;
    800063fe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006400:	0c07c263          	bltz	a5,800064c4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006404:	10000613          	li	a2,256
    80006408:	4581                	li	a1,0
    8000640a:	e4040513          	addi	a0,s0,-448
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	8c4080e7          	jalr	-1852(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006416:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000641a:	89a6                	mv	s3,s1
    8000641c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000641e:	02000a13          	li	s4,32
    80006422:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006426:	00391793          	slli	a5,s2,0x3
    8000642a:	e3040593          	addi	a1,s0,-464
    8000642e:	e3843503          	ld	a0,-456(s0)
    80006432:	953e                	add	a0,a0,a5
    80006434:	ffffd097          	auipc	ra,0xffffd
    80006438:	e00080e7          	jalr	-512(ra) # 80003234 <fetchaddr>
    8000643c:	02054a63          	bltz	a0,80006470 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006440:	e3043783          	ld	a5,-464(s0)
    80006444:	c3b9                	beqz	a5,8000648a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006446:	ffffa097          	auipc	ra,0xffffa
    8000644a:	6a0080e7          	jalr	1696(ra) # 80000ae6 <kalloc>
    8000644e:	85aa                	mv	a1,a0
    80006450:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006454:	cd11                	beqz	a0,80006470 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006456:	6605                	lui	a2,0x1
    80006458:	e3043503          	ld	a0,-464(s0)
    8000645c:	ffffd097          	auipc	ra,0xffffd
    80006460:	e2a080e7          	jalr	-470(ra) # 80003286 <fetchstr>
    80006464:	00054663          	bltz	a0,80006470 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006468:	0905                	addi	s2,s2,1
    8000646a:	09a1                	addi	s3,s3,8
    8000646c:	fb491be3          	bne	s2,s4,80006422 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006470:	10048913          	addi	s2,s1,256
    80006474:	6088                	ld	a0,0(s1)
    80006476:	c531                	beqz	a0,800064c2 <sys_exec+0xf8>
    kfree(argv[i]);
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	572080e7          	jalr	1394(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006480:	04a1                	addi	s1,s1,8
    80006482:	ff2499e3          	bne	s1,s2,80006474 <sys_exec+0xaa>
  return -1;
    80006486:	557d                	li	a0,-1
    80006488:	a835                	j	800064c4 <sys_exec+0xfa>
      argv[i] = 0;
    8000648a:	0a8e                	slli	s5,s5,0x3
    8000648c:	fc040793          	addi	a5,s0,-64
    80006490:	9abe                	add	s5,s5,a5
    80006492:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006496:	e4040593          	addi	a1,s0,-448
    8000649a:	f4040513          	addi	a0,s0,-192
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	172080e7          	jalr	370(ra) # 80005610 <exec>
    800064a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064a8:	10048993          	addi	s3,s1,256
    800064ac:	6088                	ld	a0,0(s1)
    800064ae:	c901                	beqz	a0,800064be <sys_exec+0xf4>
    kfree(argv[i]);
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	53a080e7          	jalr	1338(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064b8:	04a1                	addi	s1,s1,8
    800064ba:	ff3499e3          	bne	s1,s3,800064ac <sys_exec+0xe2>
  return ret;
    800064be:	854a                	mv	a0,s2
    800064c0:	a011                	j	800064c4 <sys_exec+0xfa>
  return -1;
    800064c2:	557d                	li	a0,-1
}
    800064c4:	60be                	ld	ra,456(sp)
    800064c6:	641e                	ld	s0,448(sp)
    800064c8:	74fa                	ld	s1,440(sp)
    800064ca:	795a                	ld	s2,432(sp)
    800064cc:	79ba                	ld	s3,424(sp)
    800064ce:	7a1a                	ld	s4,416(sp)
    800064d0:	6afa                	ld	s5,408(sp)
    800064d2:	6179                	addi	sp,sp,464
    800064d4:	8082                	ret

00000000800064d6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800064d6:	7139                	addi	sp,sp,-64
    800064d8:	fc06                	sd	ra,56(sp)
    800064da:	f822                	sd	s0,48(sp)
    800064dc:	f426                	sd	s1,40(sp)
    800064de:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	6ba080e7          	jalr	1722(ra) # 80001b9a <myproc>
    800064e8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800064ea:	fd840593          	addi	a1,s0,-40
    800064ee:	4501                	li	a0,0
    800064f0:	ffffd097          	auipc	ra,0xffffd
    800064f4:	e02080e7          	jalr	-510(ra) # 800032f2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800064f8:	fc840593          	addi	a1,s0,-56
    800064fc:	fd040513          	addi	a0,s0,-48
    80006500:	fffff097          	auipc	ra,0xfffff
    80006504:	dc6080e7          	jalr	-570(ra) # 800052c6 <pipealloc>
    return -1;
    80006508:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000650a:	0c054463          	bltz	a0,800065d2 <sys_pipe+0xfc>
  fd0 = -1;
    8000650e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006512:	fd043503          	ld	a0,-48(s0)
    80006516:	fffff097          	auipc	ra,0xfffff
    8000651a:	51a080e7          	jalr	1306(ra) # 80005a30 <fdalloc>
    8000651e:	fca42223          	sw	a0,-60(s0)
    80006522:	08054b63          	bltz	a0,800065b8 <sys_pipe+0xe2>
    80006526:	fc843503          	ld	a0,-56(s0)
    8000652a:	fffff097          	auipc	ra,0xfffff
    8000652e:	506080e7          	jalr	1286(ra) # 80005a30 <fdalloc>
    80006532:	fca42023          	sw	a0,-64(s0)
    80006536:	06054863          	bltz	a0,800065a6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000653a:	4691                	li	a3,4
    8000653c:	fc440613          	addi	a2,s0,-60
    80006540:	fd843583          	ld	a1,-40(s0)
    80006544:	68a8                	ld	a0,80(s1)
    80006546:	ffffb097          	auipc	ra,0xffffb
    8000654a:	122080e7          	jalr	290(ra) # 80001668 <copyout>
    8000654e:	02054063          	bltz	a0,8000656e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006552:	4691                	li	a3,4
    80006554:	fc040613          	addi	a2,s0,-64
    80006558:	fd843583          	ld	a1,-40(s0)
    8000655c:	0591                	addi	a1,a1,4
    8000655e:	68a8                	ld	a0,80(s1)
    80006560:	ffffb097          	auipc	ra,0xffffb
    80006564:	108080e7          	jalr	264(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006568:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000656a:	06055463          	bgez	a0,800065d2 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000656e:	fc442783          	lw	a5,-60(s0)
    80006572:	07e9                	addi	a5,a5,26
    80006574:	078e                	slli	a5,a5,0x3
    80006576:	97a6                	add	a5,a5,s1
    80006578:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000657c:	fc042503          	lw	a0,-64(s0)
    80006580:	0569                	addi	a0,a0,26
    80006582:	050e                	slli	a0,a0,0x3
    80006584:	94aa                	add	s1,s1,a0
    80006586:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000658a:	fd043503          	ld	a0,-48(s0)
    8000658e:	fffff097          	auipc	ra,0xfffff
    80006592:	a08080e7          	jalr	-1528(ra) # 80004f96 <fileclose>
    fileclose(wf);
    80006596:	fc843503          	ld	a0,-56(s0)
    8000659a:	fffff097          	auipc	ra,0xfffff
    8000659e:	9fc080e7          	jalr	-1540(ra) # 80004f96 <fileclose>
    return -1;
    800065a2:	57fd                	li	a5,-1
    800065a4:	a03d                	j	800065d2 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800065a6:	fc442783          	lw	a5,-60(s0)
    800065aa:	0007c763          	bltz	a5,800065b8 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800065ae:	07e9                	addi	a5,a5,26
    800065b0:	078e                	slli	a5,a5,0x3
    800065b2:	94be                	add	s1,s1,a5
    800065b4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800065b8:	fd043503          	ld	a0,-48(s0)
    800065bc:	fffff097          	auipc	ra,0xfffff
    800065c0:	9da080e7          	jalr	-1574(ra) # 80004f96 <fileclose>
    fileclose(wf);
    800065c4:	fc843503          	ld	a0,-56(s0)
    800065c8:	fffff097          	auipc	ra,0xfffff
    800065cc:	9ce080e7          	jalr	-1586(ra) # 80004f96 <fileclose>
    return -1;
    800065d0:	57fd                	li	a5,-1
}
    800065d2:	853e                	mv	a0,a5
    800065d4:	70e2                	ld	ra,56(sp)
    800065d6:	7442                	ld	s0,48(sp)
    800065d8:	74a2                	ld	s1,40(sp)
    800065da:	6121                	addi	sp,sp,64
    800065dc:	8082                	ret
	...

00000000800065e0 <kernelvec>:
    800065e0:	7111                	addi	sp,sp,-256
    800065e2:	e006                	sd	ra,0(sp)
    800065e4:	e40a                	sd	sp,8(sp)
    800065e6:	e80e                	sd	gp,16(sp)
    800065e8:	ec12                	sd	tp,24(sp)
    800065ea:	f016                	sd	t0,32(sp)
    800065ec:	f41a                	sd	t1,40(sp)
    800065ee:	f81e                	sd	t2,48(sp)
    800065f0:	fc22                	sd	s0,56(sp)
    800065f2:	e0a6                	sd	s1,64(sp)
    800065f4:	e4aa                	sd	a0,72(sp)
    800065f6:	e8ae                	sd	a1,80(sp)
    800065f8:	ecb2                	sd	a2,88(sp)
    800065fa:	f0b6                	sd	a3,96(sp)
    800065fc:	f4ba                	sd	a4,104(sp)
    800065fe:	f8be                	sd	a5,112(sp)
    80006600:	fcc2                	sd	a6,120(sp)
    80006602:	e146                	sd	a7,128(sp)
    80006604:	e54a                	sd	s2,136(sp)
    80006606:	e94e                	sd	s3,144(sp)
    80006608:	ed52                	sd	s4,152(sp)
    8000660a:	f156                	sd	s5,160(sp)
    8000660c:	f55a                	sd	s6,168(sp)
    8000660e:	f95e                	sd	s7,176(sp)
    80006610:	fd62                	sd	s8,184(sp)
    80006612:	e1e6                	sd	s9,192(sp)
    80006614:	e5ea                	sd	s10,200(sp)
    80006616:	e9ee                	sd	s11,208(sp)
    80006618:	edf2                	sd	t3,216(sp)
    8000661a:	f1f6                	sd	t4,224(sp)
    8000661c:	f5fa                	sd	t5,232(sp)
    8000661e:	f9fe                	sd	t6,240(sp)
    80006620:	ae1fc0ef          	jal	ra,80003100 <kerneltrap>
    80006624:	6082                	ld	ra,0(sp)
    80006626:	6122                	ld	sp,8(sp)
    80006628:	61c2                	ld	gp,16(sp)
    8000662a:	7282                	ld	t0,32(sp)
    8000662c:	7322                	ld	t1,40(sp)
    8000662e:	73c2                	ld	t2,48(sp)
    80006630:	7462                	ld	s0,56(sp)
    80006632:	6486                	ld	s1,64(sp)
    80006634:	6526                	ld	a0,72(sp)
    80006636:	65c6                	ld	a1,80(sp)
    80006638:	6666                	ld	a2,88(sp)
    8000663a:	7686                	ld	a3,96(sp)
    8000663c:	7726                	ld	a4,104(sp)
    8000663e:	77c6                	ld	a5,112(sp)
    80006640:	7866                	ld	a6,120(sp)
    80006642:	688a                	ld	a7,128(sp)
    80006644:	692a                	ld	s2,136(sp)
    80006646:	69ca                	ld	s3,144(sp)
    80006648:	6a6a                	ld	s4,152(sp)
    8000664a:	7a8a                	ld	s5,160(sp)
    8000664c:	7b2a                	ld	s6,168(sp)
    8000664e:	7bca                	ld	s7,176(sp)
    80006650:	7c6a                	ld	s8,184(sp)
    80006652:	6c8e                	ld	s9,192(sp)
    80006654:	6d2e                	ld	s10,200(sp)
    80006656:	6dce                	ld	s11,208(sp)
    80006658:	6e6e                	ld	t3,216(sp)
    8000665a:	7e8e                	ld	t4,224(sp)
    8000665c:	7f2e                	ld	t5,232(sp)
    8000665e:	7fce                	ld	t6,240(sp)
    80006660:	6111                	addi	sp,sp,256
    80006662:	10200073          	sret
    80006666:	00000013          	nop
    8000666a:	00000013          	nop
    8000666e:	0001                	nop

0000000080006670 <timervec>:
    80006670:	34051573          	csrrw	a0,mscratch,a0
    80006674:	e10c                	sd	a1,0(a0)
    80006676:	e510                	sd	a2,8(a0)
    80006678:	e914                	sd	a3,16(a0)
    8000667a:	6d0c                	ld	a1,24(a0)
    8000667c:	7110                	ld	a2,32(a0)
    8000667e:	6194                	ld	a3,0(a1)
    80006680:	96b2                	add	a3,a3,a2
    80006682:	e194                	sd	a3,0(a1)
    80006684:	4589                	li	a1,2
    80006686:	14459073          	csrw	sip,a1
    8000668a:	6914                	ld	a3,16(a0)
    8000668c:	6510                	ld	a2,8(a0)
    8000668e:	610c                	ld	a1,0(a0)
    80006690:	34051573          	csrrw	a0,mscratch,a0
    80006694:	30200073          	mret
	...

000000008000669a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000669a:	1141                	addi	sp,sp,-16
    8000669c:	e422                	sd	s0,8(sp)
    8000669e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800066a0:	0c0007b7          	lui	a5,0xc000
    800066a4:	4705                	li	a4,1
    800066a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800066a8:	c3d8                	sw	a4,4(a5)
}
    800066aa:	6422                	ld	s0,8(sp)
    800066ac:	0141                	addi	sp,sp,16
    800066ae:	8082                	ret

00000000800066b0 <plicinithart>:

void
plicinithart(void)
{
    800066b0:	1141                	addi	sp,sp,-16
    800066b2:	e406                	sd	ra,8(sp)
    800066b4:	e022                	sd	s0,0(sp)
    800066b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066b8:	ffffb097          	auipc	ra,0xffffb
    800066bc:	4b6080e7          	jalr	1206(ra) # 80001b6e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800066c0:	0085171b          	slliw	a4,a0,0x8
    800066c4:	0c0027b7          	lui	a5,0xc002
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	40200713          	li	a4,1026
    800066ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066d2:	00d5151b          	slliw	a0,a0,0xd
    800066d6:	0c2017b7          	lui	a5,0xc201
    800066da:	953e                	add	a0,a0,a5
    800066dc:	00052023          	sw	zero,0(a0)
}
    800066e0:	60a2                	ld	ra,8(sp)
    800066e2:	6402                	ld	s0,0(sp)
    800066e4:	0141                	addi	sp,sp,16
    800066e6:	8082                	ret

00000000800066e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066e8:	1141                	addi	sp,sp,-16
    800066ea:	e406                	sd	ra,8(sp)
    800066ec:	e022                	sd	s0,0(sp)
    800066ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066f0:	ffffb097          	auipc	ra,0xffffb
    800066f4:	47e080e7          	jalr	1150(ra) # 80001b6e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066f8:	00d5179b          	slliw	a5,a0,0xd
    800066fc:	0c201537          	lui	a0,0xc201
    80006700:	953e                	add	a0,a0,a5
  return irq;
}
    80006702:	4148                	lw	a0,4(a0)
    80006704:	60a2                	ld	ra,8(sp)
    80006706:	6402                	ld	s0,0(sp)
    80006708:	0141                	addi	sp,sp,16
    8000670a:	8082                	ret

000000008000670c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000670c:	1101                	addi	sp,sp,-32
    8000670e:	ec06                	sd	ra,24(sp)
    80006710:	e822                	sd	s0,16(sp)
    80006712:	e426                	sd	s1,8(sp)
    80006714:	1000                	addi	s0,sp,32
    80006716:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006718:	ffffb097          	auipc	ra,0xffffb
    8000671c:	456080e7          	jalr	1110(ra) # 80001b6e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006720:	00d5151b          	slliw	a0,a0,0xd
    80006724:	0c2017b7          	lui	a5,0xc201
    80006728:	97aa                	add	a5,a5,a0
    8000672a:	c3c4                	sw	s1,4(a5)
}
    8000672c:	60e2                	ld	ra,24(sp)
    8000672e:	6442                	ld	s0,16(sp)
    80006730:	64a2                	ld	s1,8(sp)
    80006732:	6105                	addi	sp,sp,32
    80006734:	8082                	ret

0000000080006736 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006736:	1141                	addi	sp,sp,-16
    80006738:	e406                	sd	ra,8(sp)
    8000673a:	e022                	sd	s0,0(sp)
    8000673c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000673e:	479d                	li	a5,7
    80006740:	04a7cc63          	blt	a5,a0,80006798 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006744:	00021797          	auipc	a5,0x21
    80006748:	1dc78793          	addi	a5,a5,476 # 80027920 <disk>
    8000674c:	97aa                	add	a5,a5,a0
    8000674e:	0187c783          	lbu	a5,24(a5)
    80006752:	ebb9                	bnez	a5,800067a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006754:	00451613          	slli	a2,a0,0x4
    80006758:	00021797          	auipc	a5,0x21
    8000675c:	1c878793          	addi	a5,a5,456 # 80027920 <disk>
    80006760:	6394                	ld	a3,0(a5)
    80006762:	96b2                	add	a3,a3,a2
    80006764:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006768:	6398                	ld	a4,0(a5)
    8000676a:	9732                	add	a4,a4,a2
    8000676c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006770:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006774:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006778:	953e                	add	a0,a0,a5
    8000677a:	4785                	li	a5,1
    8000677c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006780:	00021517          	auipc	a0,0x21
    80006784:	1b850513          	addi	a0,a0,440 # 80027938 <disk+0x18>
    80006788:	ffffc097          	auipc	ra,0xffffc
    8000678c:	d2a080e7          	jalr	-726(ra) # 800024b2 <wakeup>
}
    80006790:	60a2                	ld	ra,8(sp)
    80006792:	6402                	ld	s0,0(sp)
    80006794:	0141                	addi	sp,sp,16
    80006796:	8082                	ret
    panic("free_desc 1");
    80006798:	00002517          	auipc	a0,0x2
    8000679c:	1a050513          	addi	a0,a0,416 # 80008938 <syscalls+0x4b0>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>
    panic("free_desc 2");
    800067a8:	00002517          	auipc	a0,0x2
    800067ac:	1a050513          	addi	a0,a0,416 # 80008948 <syscalls+0x4c0>
    800067b0:	ffffa097          	auipc	ra,0xffffa
    800067b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>

00000000800067b8 <virtio_disk_init>:
{
    800067b8:	1101                	addi	sp,sp,-32
    800067ba:	ec06                	sd	ra,24(sp)
    800067bc:	e822                	sd	s0,16(sp)
    800067be:	e426                	sd	s1,8(sp)
    800067c0:	e04a                	sd	s2,0(sp)
    800067c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067c4:	00002597          	auipc	a1,0x2
    800067c8:	19458593          	addi	a1,a1,404 # 80008958 <syscalls+0x4d0>
    800067cc:	00021517          	auipc	a0,0x21
    800067d0:	27c50513          	addi	a0,a0,636 # 80027a48 <disk+0x128>
    800067d4:	ffffa097          	auipc	ra,0xffffa
    800067d8:	372080e7          	jalr	882(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067dc:	100017b7          	lui	a5,0x10001
    800067e0:	4398                	lw	a4,0(a5)
    800067e2:	2701                	sext.w	a4,a4
    800067e4:	747277b7          	lui	a5,0x74727
    800067e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067ec:	14f71c63          	bne	a4,a5,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067f0:	100017b7          	lui	a5,0x10001
    800067f4:	43dc                	lw	a5,4(a5)
    800067f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067f8:	4709                	li	a4,2
    800067fa:	14e79563          	bne	a5,a4,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067fe:	100017b7          	lui	a5,0x10001
    80006802:	479c                	lw	a5,8(a5)
    80006804:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006806:	12e79f63          	bne	a5,a4,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000680a:	100017b7          	lui	a5,0x10001
    8000680e:	47d8                	lw	a4,12(a5)
    80006810:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006812:	554d47b7          	lui	a5,0x554d4
    80006816:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000681a:	12f71563          	bne	a4,a5,80006944 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000681e:	100017b7          	lui	a5,0x10001
    80006822:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006826:	4705                	li	a4,1
    80006828:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000682a:	470d                	li	a4,3
    8000682c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000682e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006830:	c7ffe737          	lui	a4,0xc7ffe
    80006834:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6cff>
    80006838:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000683a:	2701                	sext.w	a4,a4
    8000683c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000683e:	472d                	li	a4,11
    80006840:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006842:	5bbc                	lw	a5,112(a5)
    80006844:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006848:	8ba1                	andi	a5,a5,8
    8000684a:	10078563          	beqz	a5,80006954 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000684e:	100017b7          	lui	a5,0x10001
    80006852:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006856:	43fc                	lw	a5,68(a5)
    80006858:	2781                	sext.w	a5,a5
    8000685a:	10079563          	bnez	a5,80006964 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000685e:	100017b7          	lui	a5,0x10001
    80006862:	5bdc                	lw	a5,52(a5)
    80006864:	2781                	sext.w	a5,a5
  if(max == 0)
    80006866:	10078763          	beqz	a5,80006974 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000686a:	471d                	li	a4,7
    8000686c:	10f77c63          	bgeu	a4,a5,80006984 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	276080e7          	jalr	630(ra) # 80000ae6 <kalloc>
    80006878:	00021497          	auipc	s1,0x21
    8000687c:	0a848493          	addi	s1,s1,168 # 80027920 <disk>
    80006880:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	264080e7          	jalr	612(ra) # 80000ae6 <kalloc>
    8000688a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	25a080e7          	jalr	602(ra) # 80000ae6 <kalloc>
    80006894:	87aa                	mv	a5,a0
    80006896:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006898:	6088                	ld	a0,0(s1)
    8000689a:	cd6d                	beqz	a0,80006994 <virtio_disk_init+0x1dc>
    8000689c:	00021717          	auipc	a4,0x21
    800068a0:	08c73703          	ld	a4,140(a4) # 80027928 <disk+0x8>
    800068a4:	cb65                	beqz	a4,80006994 <virtio_disk_init+0x1dc>
    800068a6:	c7fd                	beqz	a5,80006994 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800068a8:	6605                	lui	a2,0x1
    800068aa:	4581                	li	a1,0
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	426080e7          	jalr	1062(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800068b4:	00021497          	auipc	s1,0x21
    800068b8:	06c48493          	addi	s1,s1,108 # 80027920 <disk>
    800068bc:	6605                	lui	a2,0x1
    800068be:	4581                	li	a1,0
    800068c0:	6488                	ld	a0,8(s1)
    800068c2:	ffffa097          	auipc	ra,0xffffa
    800068c6:	410080e7          	jalr	1040(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800068ca:	6605                	lui	a2,0x1
    800068cc:	4581                	li	a1,0
    800068ce:	6888                	ld	a0,16(s1)
    800068d0:	ffffa097          	auipc	ra,0xffffa
    800068d4:	402080e7          	jalr	1026(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068d8:	100017b7          	lui	a5,0x10001
    800068dc:	4721                	li	a4,8
    800068de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800068e0:	4098                	lw	a4,0(s1)
    800068e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800068e6:	40d8                	lw	a4,4(s1)
    800068e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800068ec:	6498                	ld	a4,8(s1)
    800068ee:	0007069b          	sext.w	a3,a4
    800068f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800068f6:	9701                	srai	a4,a4,0x20
    800068f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800068fc:	6898                	ld	a4,16(s1)
    800068fe:	0007069b          	sext.w	a3,a4
    80006902:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006906:	9701                	srai	a4,a4,0x20
    80006908:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000690c:	4705                	li	a4,1
    8000690e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006910:	00e48c23          	sb	a4,24(s1)
    80006914:	00e48ca3          	sb	a4,25(s1)
    80006918:	00e48d23          	sb	a4,26(s1)
    8000691c:	00e48da3          	sb	a4,27(s1)
    80006920:	00e48e23          	sb	a4,28(s1)
    80006924:	00e48ea3          	sb	a4,29(s1)
    80006928:	00e48f23          	sb	a4,30(s1)
    8000692c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006930:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006934:	0727a823          	sw	s2,112(a5)
}
    80006938:	60e2                	ld	ra,24(sp)
    8000693a:	6442                	ld	s0,16(sp)
    8000693c:	64a2                	ld	s1,8(sp)
    8000693e:	6902                	ld	s2,0(sp)
    80006940:	6105                	addi	sp,sp,32
    80006942:	8082                	ret
    panic("could not find virtio disk");
    80006944:	00002517          	auipc	a0,0x2
    80006948:	02450513          	addi	a0,a0,36 # 80008968 <syscalls+0x4e0>
    8000694c:	ffffa097          	auipc	ra,0xffffa
    80006950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006954:	00002517          	auipc	a0,0x2
    80006958:	03450513          	addi	a0,a0,52 # 80008988 <syscalls+0x500>
    8000695c:	ffffa097          	auipc	ra,0xffffa
    80006960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006964:	00002517          	auipc	a0,0x2
    80006968:	04450513          	addi	a0,a0,68 # 800089a8 <syscalls+0x520>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006974:	00002517          	auipc	a0,0x2
    80006978:	05450513          	addi	a0,a0,84 # 800089c8 <syscalls+0x540>
    8000697c:	ffffa097          	auipc	ra,0xffffa
    80006980:	bc2080e7          	jalr	-1086(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006984:	00002517          	auipc	a0,0x2
    80006988:	06450513          	addi	a0,a0,100 # 800089e8 <syscalls+0x560>
    8000698c:	ffffa097          	auipc	ra,0xffffa
    80006990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006994:	00002517          	auipc	a0,0x2
    80006998:	07450513          	addi	a0,a0,116 # 80008a08 <syscalls+0x580>
    8000699c:	ffffa097          	auipc	ra,0xffffa
    800069a0:	ba2080e7          	jalr	-1118(ra) # 8000053e <panic>

00000000800069a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800069a4:	7119                	addi	sp,sp,-128
    800069a6:	fc86                	sd	ra,120(sp)
    800069a8:	f8a2                	sd	s0,112(sp)
    800069aa:	f4a6                	sd	s1,104(sp)
    800069ac:	f0ca                	sd	s2,96(sp)
    800069ae:	ecce                	sd	s3,88(sp)
    800069b0:	e8d2                	sd	s4,80(sp)
    800069b2:	e4d6                	sd	s5,72(sp)
    800069b4:	e0da                	sd	s6,64(sp)
    800069b6:	fc5e                	sd	s7,56(sp)
    800069b8:	f862                	sd	s8,48(sp)
    800069ba:	f466                	sd	s9,40(sp)
    800069bc:	f06a                	sd	s10,32(sp)
    800069be:	ec6e                	sd	s11,24(sp)
    800069c0:	0100                	addi	s0,sp,128
    800069c2:	8aaa                	mv	s5,a0
    800069c4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800069c6:	00c52d03          	lw	s10,12(a0)
    800069ca:	001d1d1b          	slliw	s10,s10,0x1
    800069ce:	1d02                	slli	s10,s10,0x20
    800069d0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800069d4:	00021517          	auipc	a0,0x21
    800069d8:	07450513          	addi	a0,a0,116 # 80027a48 <disk+0x128>
    800069dc:	ffffa097          	auipc	ra,0xffffa
    800069e0:	1fa080e7          	jalr	506(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800069e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800069e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800069e8:	00021b97          	auipc	s7,0x21
    800069ec:	f38b8b93          	addi	s7,s7,-200 # 80027920 <disk>
  for(int i = 0; i < 3; i++){
    800069f0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069f2:	00021c97          	auipc	s9,0x21
    800069f6:	056c8c93          	addi	s9,s9,86 # 80027a48 <disk+0x128>
    800069fa:	a08d                	j	80006a5c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800069fc:	00fb8733          	add	a4,s7,a5
    80006a00:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a04:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006a06:	0207c563          	bltz	a5,80006a30 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006a0a:	2905                	addiw	s2,s2,1
    80006a0c:	0611                	addi	a2,a2,4
    80006a0e:	05690c63          	beq	s2,s6,80006a66 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006a12:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006a14:	00021717          	auipc	a4,0x21
    80006a18:	f0c70713          	addi	a4,a4,-244 # 80027920 <disk>
    80006a1c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006a1e:	01874683          	lbu	a3,24(a4)
    80006a22:	fee9                	bnez	a3,800069fc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006a24:	2785                	addiw	a5,a5,1
    80006a26:	0705                	addi	a4,a4,1
    80006a28:	fe979be3          	bne	a5,s1,80006a1e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006a2c:	57fd                	li	a5,-1
    80006a2e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006a30:	01205d63          	blez	s2,80006a4a <virtio_disk_rw+0xa6>
    80006a34:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006a36:	000a2503          	lw	a0,0(s4)
    80006a3a:	00000097          	auipc	ra,0x0
    80006a3e:	cfc080e7          	jalr	-772(ra) # 80006736 <free_desc>
      for(int j = 0; j < i; j++)
    80006a42:	2d85                	addiw	s11,s11,1
    80006a44:	0a11                	addi	s4,s4,4
    80006a46:	ffb918e3          	bne	s2,s11,80006a36 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a4a:	85e6                	mv	a1,s9
    80006a4c:	00021517          	auipc	a0,0x21
    80006a50:	eec50513          	addi	a0,a0,-276 # 80027938 <disk+0x18>
    80006a54:	ffffc097          	auipc	ra,0xffffc
    80006a58:	9fa080e7          	jalr	-1542(ra) # 8000244e <sleep>
  for(int i = 0; i < 3; i++){
    80006a5c:	f8040a13          	addi	s4,s0,-128
{
    80006a60:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006a62:	894e                	mv	s2,s3
    80006a64:	b77d                	j	80006a12 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a66:	f8042583          	lw	a1,-128(s0)
    80006a6a:	00a58793          	addi	a5,a1,10
    80006a6e:	0792                	slli	a5,a5,0x4

  if(write)
    80006a70:	00021617          	auipc	a2,0x21
    80006a74:	eb060613          	addi	a2,a2,-336 # 80027920 <disk>
    80006a78:	00f60733          	add	a4,a2,a5
    80006a7c:	018036b3          	snez	a3,s8
    80006a80:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a82:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006a86:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a8a:	f6078693          	addi	a3,a5,-160
    80006a8e:	6218                	ld	a4,0(a2)
    80006a90:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a92:	00878513          	addi	a0,a5,8
    80006a96:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a98:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a9a:	6208                	ld	a0,0(a2)
    80006a9c:	96aa                	add	a3,a3,a0
    80006a9e:	4741                	li	a4,16
    80006aa0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006aa2:	4705                	li	a4,1
    80006aa4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006aa8:	f8442703          	lw	a4,-124(s0)
    80006aac:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ab0:	0712                	slli	a4,a4,0x4
    80006ab2:	953a                	add	a0,a0,a4
    80006ab4:	058a8693          	addi	a3,s5,88
    80006ab8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006aba:	6208                	ld	a0,0(a2)
    80006abc:	972a                	add	a4,a4,a0
    80006abe:	40000693          	li	a3,1024
    80006ac2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006ac4:	001c3c13          	seqz	s8,s8
    80006ac8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006aca:	001c6c13          	ori	s8,s8,1
    80006ace:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006ad2:	f8842603          	lw	a2,-120(s0)
    80006ad6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ada:	00021697          	auipc	a3,0x21
    80006ade:	e4668693          	addi	a3,a3,-442 # 80027920 <disk>
    80006ae2:	00258713          	addi	a4,a1,2
    80006ae6:	0712                	slli	a4,a4,0x4
    80006ae8:	9736                	add	a4,a4,a3
    80006aea:	587d                	li	a6,-1
    80006aec:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006af0:	0612                	slli	a2,a2,0x4
    80006af2:	9532                	add	a0,a0,a2
    80006af4:	f9078793          	addi	a5,a5,-112
    80006af8:	97b6                	add	a5,a5,a3
    80006afa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006afc:	629c                	ld	a5,0(a3)
    80006afe:	97b2                	add	a5,a5,a2
    80006b00:	4605                	li	a2,1
    80006b02:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b04:	4509                	li	a0,2
    80006b06:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006b0a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b0e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006b12:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b16:	6698                	ld	a4,8(a3)
    80006b18:	00275783          	lhu	a5,2(a4)
    80006b1c:	8b9d                	andi	a5,a5,7
    80006b1e:	0786                	slli	a5,a5,0x1
    80006b20:	97ba                	add	a5,a5,a4
    80006b22:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006b26:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b2a:	6698                	ld	a4,8(a3)
    80006b2c:	00275783          	lhu	a5,2(a4)
    80006b30:	2785                	addiw	a5,a5,1
    80006b32:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b36:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b3a:	100017b7          	lui	a5,0x10001
    80006b3e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b42:	004aa783          	lw	a5,4(s5)
    80006b46:	02c79163          	bne	a5,a2,80006b68 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006b4a:	00021917          	auipc	s2,0x21
    80006b4e:	efe90913          	addi	s2,s2,-258 # 80027a48 <disk+0x128>
  while(b->disk == 1) {
    80006b52:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006b54:	85ca                	mv	a1,s2
    80006b56:	8556                	mv	a0,s5
    80006b58:	ffffc097          	auipc	ra,0xffffc
    80006b5c:	8f6080e7          	jalr	-1802(ra) # 8000244e <sleep>
  while(b->disk == 1) {
    80006b60:	004aa783          	lw	a5,4(s5)
    80006b64:	fe9788e3          	beq	a5,s1,80006b54 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006b68:	f8042903          	lw	s2,-128(s0)
    80006b6c:	00290793          	addi	a5,s2,2
    80006b70:	00479713          	slli	a4,a5,0x4
    80006b74:	00021797          	auipc	a5,0x21
    80006b78:	dac78793          	addi	a5,a5,-596 # 80027920 <disk>
    80006b7c:	97ba                	add	a5,a5,a4
    80006b7e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006b82:	00021997          	auipc	s3,0x21
    80006b86:	d9e98993          	addi	s3,s3,-610 # 80027920 <disk>
    80006b8a:	00491713          	slli	a4,s2,0x4
    80006b8e:	0009b783          	ld	a5,0(s3)
    80006b92:	97ba                	add	a5,a5,a4
    80006b94:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b98:	854a                	mv	a0,s2
    80006b9a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b9e:	00000097          	auipc	ra,0x0
    80006ba2:	b98080e7          	jalr	-1128(ra) # 80006736 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ba6:	8885                	andi	s1,s1,1
    80006ba8:	f0ed                	bnez	s1,80006b8a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006baa:	00021517          	auipc	a0,0x21
    80006bae:	e9e50513          	addi	a0,a0,-354 # 80027a48 <disk+0x128>
    80006bb2:	ffffa097          	auipc	ra,0xffffa
    80006bb6:	0d8080e7          	jalr	216(ra) # 80000c8a <release>
}
    80006bba:	70e6                	ld	ra,120(sp)
    80006bbc:	7446                	ld	s0,112(sp)
    80006bbe:	74a6                	ld	s1,104(sp)
    80006bc0:	7906                	ld	s2,96(sp)
    80006bc2:	69e6                	ld	s3,88(sp)
    80006bc4:	6a46                	ld	s4,80(sp)
    80006bc6:	6aa6                	ld	s5,72(sp)
    80006bc8:	6b06                	ld	s6,64(sp)
    80006bca:	7be2                	ld	s7,56(sp)
    80006bcc:	7c42                	ld	s8,48(sp)
    80006bce:	7ca2                	ld	s9,40(sp)
    80006bd0:	7d02                	ld	s10,32(sp)
    80006bd2:	6de2                	ld	s11,24(sp)
    80006bd4:	6109                	addi	sp,sp,128
    80006bd6:	8082                	ret

0000000080006bd8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006bd8:	1101                	addi	sp,sp,-32
    80006bda:	ec06                	sd	ra,24(sp)
    80006bdc:	e822                	sd	s0,16(sp)
    80006bde:	e426                	sd	s1,8(sp)
    80006be0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006be2:	00021497          	auipc	s1,0x21
    80006be6:	d3e48493          	addi	s1,s1,-706 # 80027920 <disk>
    80006bea:	00021517          	auipc	a0,0x21
    80006bee:	e5e50513          	addi	a0,a0,-418 # 80027a48 <disk+0x128>
    80006bf2:	ffffa097          	auipc	ra,0xffffa
    80006bf6:	fe4080e7          	jalr	-28(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006bfa:	10001737          	lui	a4,0x10001
    80006bfe:	533c                	lw	a5,96(a4)
    80006c00:	8b8d                	andi	a5,a5,3
    80006c02:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c04:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c08:	689c                	ld	a5,16(s1)
    80006c0a:	0204d703          	lhu	a4,32(s1)
    80006c0e:	0027d783          	lhu	a5,2(a5)
    80006c12:	04f70863          	beq	a4,a5,80006c62 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006c16:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c1a:	6898                	ld	a4,16(s1)
    80006c1c:	0204d783          	lhu	a5,32(s1)
    80006c20:	8b9d                	andi	a5,a5,7
    80006c22:	078e                	slli	a5,a5,0x3
    80006c24:	97ba                	add	a5,a5,a4
    80006c26:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c28:	00278713          	addi	a4,a5,2
    80006c2c:	0712                	slli	a4,a4,0x4
    80006c2e:	9726                	add	a4,a4,s1
    80006c30:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c34:	e721                	bnez	a4,80006c7c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c36:	0789                	addi	a5,a5,2
    80006c38:	0792                	slli	a5,a5,0x4
    80006c3a:	97a6                	add	a5,a5,s1
    80006c3c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006c3e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c42:	ffffc097          	auipc	ra,0xffffc
    80006c46:	870080e7          	jalr	-1936(ra) # 800024b2 <wakeup>

    disk.used_idx += 1;
    80006c4a:	0204d783          	lhu	a5,32(s1)
    80006c4e:	2785                	addiw	a5,a5,1
    80006c50:	17c2                	slli	a5,a5,0x30
    80006c52:	93c1                	srli	a5,a5,0x30
    80006c54:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c58:	6898                	ld	a4,16(s1)
    80006c5a:	00275703          	lhu	a4,2(a4)
    80006c5e:	faf71ce3          	bne	a4,a5,80006c16 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006c62:	00021517          	auipc	a0,0x21
    80006c66:	de650513          	addi	a0,a0,-538 # 80027a48 <disk+0x128>
    80006c6a:	ffffa097          	auipc	ra,0xffffa
    80006c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
}
    80006c72:	60e2                	ld	ra,24(sp)
    80006c74:	6442                	ld	s0,16(sp)
    80006c76:	64a2                	ld	s1,8(sp)
    80006c78:	6105                	addi	sp,sp,32
    80006c7a:	8082                	ret
      panic("virtio_disk_intr status");
    80006c7c:	00002517          	auipc	a0,0x2
    80006c80:	da450513          	addi	a0,a0,-604 # 80008a20 <syscalls+0x598>
    80006c84:	ffffa097          	auipc	ra,0xffffa
    80006c88:	8ba080e7          	jalr	-1862(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
