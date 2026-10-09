
app.elf:     file format elf32-littleriscv


Disassembly of section .text:

10000000 <_start>:
10000000:	10002137          	lui	sp,0x10002
10000004:	ffc10113          	addi	sp,sp,-4 # 10001ffc <_ebss+0xc4c>
10000008:	00001517          	auipc	a0,0x1
1000000c:	39050513          	addi	a0,a0,912 # 10001398 <g_trng_words>
10000010:	00001597          	auipc	a1,0x1
10000014:	3a058593          	addi	a1,a1,928 # 100013b0 <_ebss>
10000018:	00b55863          	bge	a0,a1,10000028 <bss_done>

1000001c <bss_loop>:
1000001c:	00052023          	sw	zero,0(a0)
10000020:	00450513          	addi	a0,a0,4
10000024:	feb54ce3          	blt	a0,a1,1000001c <bss_loop>

10000028 <bss_done>:
10000028:	3d1000ef          	jal	10000bf8 <main>

1000002c <hang>:
1000002c:	0000006f          	j	1000002c <hang>

10000030 <str_equal>:
10000030:	00054783          	lbu	a5,0(a0)
10000034:	00079c63          	bnez	a5,1000004c <str_equal+0x1c>
10000038:	0480006f          	j	10000080 <str_equal+0x50>
1000003c:	02f71663          	bne	a4,a5,10000068 <str_equal+0x38>
10000040:	00054783          	lbu	a5,0(a0)
10000044:	02078663          	beqz	a5,10000070 <str_equal+0x40>
10000048:	00068593          	mv	a1,a3
1000004c:	0005c703          	lbu	a4,0(a1)
10000050:	00150513          	addi	a0,a0,1
10000054:	00158693          	addi	a3,a1,1
10000058:	fe0712e3          	bnez	a4,1000003c <str_equal+0xc>
1000005c:	40e78533          	sub	a0,a5,a4
10000060:	00153513          	seqz	a0,a0
10000064:	00008067          	ret
10000068:	00000513          	li	a0,0
1000006c:	00008067          	ret
10000070:	0015c703          	lbu	a4,1(a1)
10000074:	40e78533          	sub	a0,a5,a4
10000078:	00153513          	seqz	a0,a0
1000007c:	00008067          	ret
10000080:	0005c703          	lbu	a4,0(a1)
10000084:	fd9ff06f          	j	1000005c <str_equal+0x2c>

10000088 <emit_new_challenge>:
10000088:	fe010113          	addi	sp,sp,-32
1000008c:	01312623          	sw	s3,12(sp)
10000090:	100019b7          	lui	s3,0x10001
10000094:	00912a23          	sw	s1,20(sp)
10000098:	39898493          	addi	s1,s3,920 # 10001398 <g_trng_words>
1000009c:	00812c23          	sw	s0,24(sp)
100000a0:	01212823          	sw	s2,16(sp)
100000a4:	39898413          	addi	s0,s3,920
100000a8:	00112e23          	sw	ra,28(sp)
100000ac:	01412423          	sw	s4,8(sp)
100000b0:	01512223          	sw	s5,4(sp)
100000b4:	01048913          	addi	s2,s1,16
100000b8:	39898993          	addi	s3,s3,920
100000bc:	31d000ef          	jal	10000bd8 <trng_read>
100000c0:	00a9a023          	sw	a0,0(s3)
100000c4:	00498993          	addi	s3,s3,4
100000c8:	ff391ae3          	bne	s2,s3,100000bc <emit_new_challenge+0x34>
100000cc:	00042503          	lw	a0,0(s0)
100000d0:	00442803          	lw	a6,4(s0)
100000d4:	0f205637          	lui	a2,0xf205
100000d8:	8ab9e8b7          	lui	a7,0x8ab9e
100000dc:	efa88893          	addi	a7,a7,-262 # 8ab9defa <_ebss+0x7ab9cb4a>
100000e0:	76360613          	addi	a2,a2,1891 # f205763 <_start-0xdfa89d>
100000e4:	e7cec6b7          	lui	a3,0xe7cec
100000e8:	00c84633          	xor	a2,a6,a2
100000ec:	01154fb3          	xor	t6,a0,a7
100000f0:	f8e68693          	addi	a3,a3,-114 # e7cebf8e <_ebss+0xd7ceabde>
100000f4:	6d5a25b7          	lui	a1,0x6d5a2
100000f8:	00d606b3          	add	a3,a2,a3
100000fc:	01061793          	slli	a5,a2,0x10
10000100:	010fd313          	srli	t1,t6,0x10
10000104:	20258593          	addi	a1,a1,514 # 6d5a2202 <_ebss+0x5d5a0e52>
10000108:	00c6b733          	sltu	a4,a3,a2
1000010c:	00bf85b3          	add	a1,t6,a1
10000110:	01065893          	srli	a7,a2,0x10
10000114:	010f9e13          	slli	t3,t6,0x10
10000118:	00f36333          	or	t1,t1,a5
1000011c:	0cfff7b7          	lui	a5,0xcfff
10000120:	0066c6b3          	xor	a3,a3,t1
10000124:	00b70733          	add	a4,a4,a1
10000128:	0fc78793          	addi	a5,a5,252 # cfff0fc <_start-0x3000f04>
1000012c:	01c8e5b3          	or	a1,a7,t3
10000130:	017578b7          	lui	a7,0x1757
10000134:	12090e37          	lui	t3,0x12090
10000138:	00f687b3          	add	a5,a3,a5
1000013c:	00b74733          	xor	a4,a4,a1
10000140:	4cf88893          	addi	a7,a7,1231 # 17574cf <_start-0xe8a8b31>
10000144:	e33af2b7          	lui	t0,0xe33af
10000148:	617e0e13          	addi	t3,t3,1559 # 12090617 <_ebss+0x208f267>
1000014c:	01160eb3          	add	t4,a2,a7
10000150:	01c70e33          	add	t3,a4,t3
10000154:	00d7b333          	sltu	t1,a5,a3
10000158:	01571393          	slli	t2,a4,0x15
1000015c:	5fd28293          	addi	t0,t0,1533 # e33af5fd <_ebss+0xd33ae24d>
10000160:	00b6d593          	srli	a1,a3,0xb
10000164:	00b75713          	srli	a4,a4,0xb
10000168:	01569693          	slli	a3,a3,0x15
1000016c:	005f88b3          	add	a7,t6,t0
10000170:	00ceb633          	sltu	a2,t4,a2
10000174:	00d76733          	or	a4,a4,a3
10000178:	6a82ff37          	lui	t5,0x6a82f
1000017c:	00e7c733          	xor	a4,a5,a4
10000180:	011606b3          	add	a3,a2,a7
10000184:	01c30333          	add	t1,t1,t3
10000188:	0075e5b3          	or	a1,a1,t2
1000018c:	a7f43e37          	lui	t3,0xa7f43
10000190:	bc1f0f13          	addi	t5,t5,-1087 # 6a82ebc1 <_ebss+0x5a82d811>
10000194:	01eecf33          	xor	t5,t4,t5
10000198:	00b345b3          	xor	a1,t1,a1
1000019c:	34de0613          	addi	a2,t3,845 # a7f4334d <_ebss+0x97f41f9d>
100001a0:	00d70e33          	add	t3,a4,a3
100001a4:	01e78fb3          	add	t6,a5,t5
100001a8:	00c6c6b3          	xor	a3,a3,a2
100001ac:	01d588b3          	add	a7,a1,t4
100001b0:	01071293          	slli	t0,a4,0x10
100001b4:	00ee3eb3          	sltu	t4,t3,a4
100001b8:	0105d613          	srli	a2,a1,0x10
100001bc:	00d30333          	add	t1,t1,a3
100001c0:	011e8eb3          	add	t4,t4,a7
100001c4:	00ffb7b3          	sltu	a5,t6,a5
100001c8:	00df1893          	slli	a7,t5,0xd
100001cc:	01059593          	slli	a1,a1,0x10
100001d0:	00566633          	or	a2,a2,t0
100001d4:	01075713          	srli	a4,a4,0x10
100001d8:	0136d293          	srli	t0,a3,0x13
100001dc:	00ce4633          	xor	a2,t3,a2
100001e0:	006787b3          	add	a5,a5,t1
100001e4:	00b76733          	or	a4,a4,a1
100001e8:	0112e333          	or	t1,t0,a7
100001ec:	00d69693          	slli	a3,a3,0xd
100001f0:	013f5593          	srli	a1,t5,0x13
100001f4:	006fc333          	xor	t1,t6,t1
100001f8:	00c78f33          	add	t5,a5,a2
100001fc:	00eec733          	xor	a4,t4,a4
10000200:	00d5e5b3          	or	a1,a1,a3
10000204:	01c30e33          	add	t3,t1,t3
10000208:	00ef8fb3          	add	t6,t6,a4
1000020c:	00ff32b3          	sltu	t0,t5,a5
10000210:	01571393          	slli	t2,a4,0x15
10000214:	00b7c7b3          	xor	a5,a5,a1
10000218:	01561893          	slli	a7,a2,0x15
1000021c:	00c42583          	lw	a1,12(s0)
10000220:	00b65693          	srli	a3,a2,0xb
10000224:	00b75713          	srli	a4,a4,0xb
10000228:	00842603          	lw	a2,8(s0)
1000022c:	01f282b3          	add	t0,t0,t6
10000230:	01d78eb3          	add	t4,a5,t4
10000234:	0076e6b3          	or	a3,a3,t2
10000238:	01176733          	or	a4,a4,a7
1000023c:	01179393          	slli	t2,a5,0x11
10000240:	006e38b3          	sltu	a7,t3,t1
10000244:	00f35f93          	srli	t6,t1,0xf
10000248:	00f7d793          	srli	a5,a5,0xf
1000024c:	01131313          	slli	t1,t1,0x11
10000250:	01d888b3          	add	a7,a7,t4
10000254:	00d2c6b3          	xor	a3,t0,a3
10000258:	00ef4733          	xor	a4,t5,a4
1000025c:	007fefb3          	or	t6,t6,t2
10000260:	0067e7b3          	or	a5,a5,t1
10000264:	00e5c733          	xor	a4,a1,a4
10000268:	00d646b3          	xor	a3,a2,a3
1000026c:	01f8cfb3          	xor	t6,a7,t6
10000270:	00fe47b3          	xor	a5,t3,a5
10000274:	01e84833          	xor	a6,a6,t5
10000278:	01078833          	add	a6,a5,a6
1000027c:	00e88f33          	add	t5,a7,a4
10000280:	00554eb3          	xor	t4,a0,t0
10000284:	01071413          	slli	s0,a4,0x10
10000288:	00d79393          	slli	t2,a5,0xd
1000028c:	0106d313          	srli	t1,a3,0x10
10000290:	013fd513          	srli	a0,t6,0x13
10000294:	00de02b3          	add	t0,t3,a3
10000298:	01df8eb3          	add	t4,t6,t4
1000029c:	00f83e33          	sltu	t3,a6,a5
100002a0:	011f38b3          	sltu	a7,t5,a7
100002a4:	01069693          	slli	a3,a3,0x10
100002a8:	00836333          	or	t1,t1,s0
100002ac:	00df9f93          	slli	t6,t6,0xd
100002b0:	00756533          	or	a0,a0,t2
100002b4:	01075713          	srli	a4,a4,0x10
100002b8:	0137d793          	srli	a5,a5,0x13
100002bc:	01de0e33          	add	t3,t3,t4
100002c0:	006f4333          	xor	t1,t5,t1
100002c4:	00a84533          	xor	a0,a6,a0
100002c8:	005888b3          	add	a7,a7,t0
100002cc:	00d76733          	or	a4,a4,a3
100002d0:	01f7e7b3          	or	a5,a5,t6
100002d4:	006e06b3          	add	a3,t3,t1
100002d8:	00e8c733          	xor	a4,a7,a4
100002dc:	00fe47b3          	xor	a5,t3,a5
100002e0:	01e50f33          	add	t5,a0,t5
100002e4:	00af32b3          	sltu	t0,t5,a0
100002e8:	00e80833          	add	a6,a6,a4
100002ec:	01c6bfb3          	sltu	t6,a3,t3
100002f0:	011788b3          	add	a7,a5,a7
100002f4:	01571413          	slli	s0,a4,0x15
100002f8:	01531e93          	slli	t4,t1,0x15
100002fc:	01179393          	slli	t2,a5,0x11
10000300:	00b35e13          	srli	t3,t1,0xb
10000304:	00b75713          	srli	a4,a4,0xb
10000308:	00f55313          	srli	t1,a0,0xf
1000030c:	00f7d793          	srli	a5,a5,0xf
10000310:	01151513          	slli	a0,a0,0x11
10000314:	010f8fb3          	add	t6,t6,a6
10000318:	008e6e33          	or	t3,t3,s0
1000031c:	01128833          	add	a6,t0,a7
10000320:	01d76733          	or	a4,a4,t4
10000324:	007368b3          	or	a7,t1,t2
10000328:	00a7e7b3          	or	a5,a5,a0
1000032c:	00e6c733          	xor	a4,a3,a4
10000330:	01cfce33          	xor	t3,t6,t3
10000334:	01184533          	xor	a0,a6,a7
10000338:	00ff47b3          	xor	a5,t5,a5
1000033c:	00f68eb3          	add	t4,a3,a5
10000340:	01070833          	add	a6,a4,a6
10000344:	01071413          	slli	s0,a4,0x10
10000348:	00d79393          	slli	t2,a5,0xd
1000034c:	010e5313          	srli	t1,t3,0x10
10000350:	01355893          	srli	a7,a0,0x13
10000354:	00e832b3          	sltu	t0,a6,a4
10000358:	00af8fb3          	add	t6,t6,a0
1000035c:	01ee0f33          	add	t5,t3,t5
10000360:	00deb6b3          	sltu	a3,t4,a3
10000364:	010e1e13          	slli	t3,t3,0x10
10000368:	00836333          	or	t1,t1,s0
1000036c:	00d51513          	slli	a0,a0,0xd
10000370:	0078e8b3          	or	a7,a7,t2
10000374:	01075713          	srli	a4,a4,0x10
10000378:	0137d793          	srli	a5,a5,0x13
1000037c:	01f686b3          	add	a3,a3,t6
10000380:	00684333          	xor	t1,a6,t1
10000384:	011ec8b3          	xor	a7,t4,a7
10000388:	01e28f33          	add	t5,t0,t5
1000038c:	01c76733          	or	a4,a4,t3
10000390:	00a7e7b3          	or	a5,a5,a0
10000394:	00ef4733          	xor	a4,t5,a4
10000398:	00668e33          	add	t3,a3,t1
1000039c:	00f6c7b3          	xor	a5,a3,a5
100003a0:	01088833          	add	a6,a7,a6
100003a4:	00de3533          	sltu	a0,t3,a3
100003a8:	011833b3          	sltu	t2,a6,a7
100003ac:	00ee8fb3          	add	t6,t4,a4
100003b0:	01e78f33          	add	t5,a5,t5
100003b4:	01531e93          	slli	t4,t1,0x15
100003b8:	01179293          	slli	t0,a5,0x11
100003bc:	01571413          	slli	s0,a4,0x15
100003c0:	00b75693          	srli	a3,a4,0xb
100003c4:	00f7d793          	srli	a5,a5,0xf
100003c8:	00b35713          	srli	a4,t1,0xb
100003cc:	00f8d313          	srli	t1,a7,0xf
100003d0:	01189893          	slli	a7,a7,0x11
100003d4:	01f50fb3          	add	t6,a0,t6
100003d8:	01d6e6b3          	or	a3,a3,t4
100003dc:	01e38533          	add	a0,t2,t5
100003e0:	00536333          	or	t1,t1,t0
100003e4:	0117e7b3          	or	a5,a5,a7
100003e8:	00876733          	or	a4,a4,s0
100003ec:	00f847b3          	xor	a5,a6,a5
100003f0:	00654333          	xor	t1,a0,t1
100003f4:	01c5c5b3          	xor	a1,a1,t3
100003f8:	00efc733          	xor	a4,t6,a4
100003fc:	00de4e33          	xor	t3,t3,a3
10000400:	100006b7          	lui	a3,0x10000
10000404:	00d74733          	xor	a4,a4,a3
10000408:	01c50eb3          	add	t4,a0,t3
1000040c:	00b785b3          	add	a1,a5,a1
10000410:	00d79393          	slli	t2,a5,0xd
10000414:	01f64633          	xor	a2,a2,t6
10000418:	01335893          	srli	a7,t1,0x13
1000041c:	00f5b2b3          	sltu	t0,a1,a5
10000420:	00e80833          	add	a6,a6,a4
10000424:	00c30633          	add	a2,t1,a2
10000428:	01071f93          	slli	t6,a4,0x10
1000042c:	00aeb533          	sltu	a0,t4,a0
10000430:	010e5f13          	srli	t5,t3,0x10
10000434:	00d31313          	slli	t1,t1,0xd
10000438:	010e1e13          	slli	t3,t3,0x10
1000043c:	0078e8b3          	or	a7,a7,t2
10000440:	01075713          	srli	a4,a4,0x10
10000444:	0137d793          	srli	a5,a5,0x13
10000448:	0115c8b3          	xor	a7,a1,a7
1000044c:	01050533          	add	a0,a0,a6
10000450:	01ff6f33          	or	t5,t5,t6
10000454:	00c28833          	add	a6,t0,a2
10000458:	01c76733          	or	a4,a4,t3
1000045c:	0067e7b3          	or	a5,a5,t1
10000460:	00eec733          	xor	a4,t4,a4
10000464:	00f847b3          	xor	a5,a6,a5
10000468:	01d88eb3          	add	t4,a7,t4
1000046c:	01e54f33          	xor	t5,a0,t5
10000470:	00e80633          	add	a2,a6,a4
10000474:	00a78333          	add	t1,a5,a0
10000478:	011ebfb3          	sltu	t6,t4,a7
1000047c:	01571393          	slli	t2,a4,0x15
10000480:	01179293          	slli	t0,a5,0x11
10000484:	00f8de13          	srli	t3,a7,0xf
10000488:	00bf5513          	srli	a0,t5,0xb
1000048c:	01189893          	slli	a7,a7,0x11
10000490:	00f7d793          	srli	a5,a5,0xf
10000494:	006f8fb3          	add	t6,t6,t1
10000498:	01e585b3          	add	a1,a1,t5
1000049c:	005e6333          	or	t1,t3,t0
100004a0:	01063833          	sltu	a6,a2,a6
100004a4:	015f1f13          	slli	t5,t5,0x15
100004a8:	00756533          	or	a0,a0,t2
100004ac:	0117e7b3          	or	a5,a5,a7
100004b0:	00b75713          	srli	a4,a4,0xb
100004b4:	00a64533          	xor	a0,a2,a0
100004b8:	00fec7b3          	xor	a5,t4,a5
100004bc:	00b80833          	add	a6,a6,a1
100004c0:	006fc333          	xor	t1,t6,t1
100004c4:	01e76733          	or	a4,a4,t5
100004c8:	01f505b3          	add	a1,a0,t6
100004cc:	00e84733          	xor	a4,a6,a4
100004d0:	00f60e33          	add	t3,a2,a5
100004d4:	00d79393          	slli	t2,a5,0xd
100004d8:	01335f93          	srli	t6,t1,0x13
100004dc:	01d70f33          	add	t5,a4,t4
100004e0:	00680833          	add	a6,a6,t1
100004e4:	00a5beb3          	sltu	t4,a1,a0
100004e8:	01071293          	slli	t0,a4,0x10
100004ec:	01055893          	srli	a7,a0,0x10
100004f0:	00ce3633          	sltu	a2,t3,a2
100004f4:	01051513          	slli	a0,a0,0x10
100004f8:	00d31313          	slli	t1,t1,0xd
100004fc:	007fefb3          	or	t6,t6,t2
10000500:	01075713          	srli	a4,a4,0x10
10000504:	0137d793          	srli	a5,a5,0x13
10000508:	01060633          	add	a2,a2,a6
1000050c:	01ee8eb3          	add	t4,t4,t5
10000510:	0058e833          	or	a6,a7,t0
10000514:	00a76733          	or	a4,a4,a0
10000518:	01fe48b3          	xor	a7,t3,t6
1000051c:	0067e7b3          	or	a5,a5,t1
10000520:	010ec833          	xor	a6,t4,a6
10000524:	00e5c733          	xor	a4,a1,a4
10000528:	00f647b3          	xor	a5,a2,a5
1000052c:	00b885b3          	add	a1,a7,a1
10000530:	00e60333          	add	t1,a2,a4
10000534:	0115bf33          	sltu	t5,a1,a7
10000538:	01571f93          	slli	t6,a4,0x15
1000053c:	00b85513          	srli	a0,a6,0xb
10000540:	01d78eb3          	add	t4,a5,t4
10000544:	010e0e33          	add	t3,t3,a6
10000548:	01df0eb3          	add	t4,t5,t4
1000054c:	00c33633          	sltu	a2,t1,a2
10000550:	00f8df13          	srli	t5,a7,0xf
10000554:	01581813          	slli	a6,a6,0x15
10000558:	01f56533          	or	a0,a0,t6
1000055c:	01189893          	slli	a7,a7,0x11
10000560:	01179f93          	slli	t6,a5,0x11
10000564:	00b75713          	srli	a4,a4,0xb
10000568:	00f7d793          	srli	a5,a5,0xf
1000056c:	00a34533          	xor	a0,t1,a0
10000570:	01c60633          	add	a2,a2,t3
10000574:	01076733          	or	a4,a4,a6
10000578:	0ffece13          	xori	t3,t4,255
1000057c:	01ff6833          	or	a6,t5,t6
10000580:	0117e7b3          	or	a5,a5,a7
10000584:	00f5c7b3          	xor	a5,a1,a5
10000588:	01c508b3          	add	a7,a0,t3
1000058c:	00e64733          	xor	a4,a2,a4
10000590:	010eceb3          	xor	t4,t4,a6
10000594:	00678333          	add	t1,a5,t1
10000598:	00b705b3          	add	a1,a4,a1
1000059c:	00a8be33          	sltu	t3,a7,a0
100005a0:	01071f93          	slli	t6,a4,0x10
100005a4:	00d79f13          	slli	t5,a5,0xd
100005a8:	00d64633          	xor	a2,a2,a3
100005ac:	01055813          	srli	a6,a0,0x10
100005b0:	01051693          	slli	a3,a0,0x10
100005b4:	01075713          	srli	a4,a4,0x10
100005b8:	013ed513          	srli	a0,t4,0x13
100005bc:	00be0e33          	add	t3,t3,a1
100005c0:	00ce8633          	add	a2,t4,a2
100005c4:	00f335b3          	sltu	a1,t1,a5
100005c8:	01f86833          	or	a6,a6,t6
100005cc:	00d76733          	or	a4,a4,a3
100005d0:	00de9e93          	slli	t4,t4,0xd
100005d4:	01e56533          	or	a0,a0,t5
100005d8:	0137d793          	srli	a5,a5,0x13
100005dc:	00c586b3          	add	a3,a1,a2
100005e0:	00a34533          	xor	a0,t1,a0
100005e4:	010e4833          	xor	a6,t3,a6
100005e8:	00e8c733          	xor	a4,a7,a4
100005ec:	01d7e7b3          	or	a5,a5,t4
100005f0:	00e68633          	add	a2,a3,a4
100005f4:	01150eb3          	add	t4,a0,a7
100005f8:	00f6c7b3          	xor	a5,a3,a5
100005fc:	01571f13          	slli	t5,a4,0x15
10000600:	00b85593          	srli	a1,a6,0xb
10000604:	00d638b3          	sltu	a7,a2,a3
10000608:	01030333          	add	t1,t1,a6
1000060c:	01c78e33          	add	t3,a5,t3
10000610:	00aeb6b3          	sltu	a3,t4,a0
10000614:	01179293          	slli	t0,a5,0x11
10000618:	00f55f93          	srli	t6,a0,0xf
1000061c:	01581813          	slli	a6,a6,0x15
10000620:	01e5e5b3          	or	a1,a1,t5
10000624:	01151513          	slli	a0,a0,0x11
10000628:	00b75713          	srli	a4,a4,0xb
1000062c:	00f7d793          	srli	a5,a5,0xf
10000630:	00688f33          	add	t5,a7,t1
10000634:	00b645b3          	xor	a1,a2,a1
10000638:	01c686b3          	add	a3,a3,t3
1000063c:	01076733          	or	a4,a4,a6
10000640:	00a7e7b3          	or	a5,a5,a0
10000644:	005fe833          	or	a6,t6,t0
10000648:	00d58533          	add	a0,a1,a3
1000064c:	00ef4733          	xor	a4,t5,a4
10000650:	00fec7b3          	xor	a5,t4,a5
10000654:	0106c6b3          	xor	a3,a3,a6
10000658:	00f60333          	add	t1,a2,a5
1000065c:	01d70eb3          	add	t4,a4,t4
10000660:	00b53e33          	sltu	t3,a0,a1
10000664:	01071293          	slli	t0,a4,0x10
10000668:	00d79f93          	slli	t6,a5,0xd
1000066c:	0105d893          	srli	a7,a1,0x10
10000670:	0136d813          	srli	a6,a3,0x13
10000674:	01059593          	slli	a1,a1,0x10
10000678:	01075713          	srli	a4,a4,0x10
1000067c:	01de0e33          	add	t3,t3,t4
10000680:	00c33633          	sltu	a2,t1,a2
10000684:	00df0eb3          	add	t4,t5,a3
10000688:	0058e8b3          	or	a7,a7,t0
1000068c:	00b76733          	or	a4,a4,a1
10000690:	00d69693          	slli	a3,a3,0xd
10000694:	01f86833          	or	a6,a6,t6
10000698:	0137d793          	srli	a5,a5,0x13
1000069c:	01034833          	xor	a6,t1,a6
100006a0:	01d60633          	add	a2,a2,t4
100006a4:	011e48b3          	xor	a7,t3,a7
100006a8:	00e54733          	xor	a4,a0,a4
100006ac:	00d7e7b3          	or	a5,a5,a3
100006b0:	00a80f33          	add	t5,a6,a0
100006b4:	00e606b3          	add	a3,a2,a4
100006b8:	00f647b3          	xor	a5,a2,a5
100006bc:	01571e93          	slli	t4,a4,0x15
100006c0:	00b8d513          	srli	a0,a7,0xb
100006c4:	01130333          	add	t1,t1,a7
100006c8:	01c78e33          	add	t3,a5,t3
100006cc:	010f35b3          	sltu	a1,t5,a6
100006d0:	01179f93          	slli	t6,a5,0x11
100006d4:	00c6b633          	sltu	a2,a3,a2
100006d8:	01589893          	slli	a7,a7,0x15
100006dc:	01d56533          	or	a0,a0,t4
100006e0:	00b75713          	srli	a4,a4,0xb
100006e4:	00f85e93          	srli	t4,a6,0xf
100006e8:	00f7d793          	srli	a5,a5,0xf
100006ec:	01181813          	slli	a6,a6,0x11
100006f0:	00a6c533          	xor	a0,a3,a0
100006f4:	00660633          	add	a2,a2,t1
100006f8:	01c585b3          	add	a1,a1,t3
100006fc:	01176733          	or	a4,a4,a7
10000700:	0107e7b3          	or	a5,a5,a6
10000704:	01fee8b3          	or	a7,t4,t6
10000708:	00e64733          	xor	a4,a2,a4
1000070c:	00b50eb3          	add	t4,a0,a1
10000710:	00ff47b3          	xor	a5,t5,a5
10000714:	0115c5b3          	xor	a1,a1,a7
10000718:	00f68e33          	add	t3,a3,a5
1000071c:	01e708b3          	add	a7,a4,t5
10000720:	00aeb2b3          	sltu	t0,t4,a0
10000724:	01071f93          	slli	t6,a4,0x10
10000728:	00d79f13          	slli	t5,a5,0xd
1000072c:	01055813          	srli	a6,a0,0x10
10000730:	0135d313          	srli	t1,a1,0x13
10000734:	01051513          	slli	a0,a0,0x10
10000738:	01075713          	srli	a4,a4,0x10
1000073c:	011288b3          	add	a7,t0,a7
10000740:	00b60633          	add	a2,a2,a1
10000744:	00de36b3          	sltu	a3,t3,a3
10000748:	01f86833          	or	a6,a6,t6
1000074c:	00a76733          	or	a4,a4,a0
10000750:	00d59593          	slli	a1,a1,0xd
10000754:	01e36333          	or	t1,t1,t5
10000758:	0137d793          	srli	a5,a5,0x13
1000075c:	006e4333          	xor	t1,t3,t1
10000760:	00c686b3          	add	a3,a3,a2
10000764:	0108c833          	xor	a6,a7,a6
10000768:	00eec733          	xor	a4,t4,a4
1000076c:	00b7e7b3          	or	a5,a5,a1
10000770:	01d30eb3          	add	t4,t1,t4
10000774:	00e685b3          	add	a1,a3,a4
10000778:	00f6c7b3          	xor	a5,a3,a5
1000077c:	01571f93          	slli	t6,a4,0x15
10000780:	00b85513          	srli	a0,a6,0xb
10000784:	00d5b633          	sltu	a2,a1,a3
10000788:	01178f33          	add	t5,a5,a7
1000078c:	006eb6b3          	sltu	a3,t4,t1
10000790:	010e0e33          	add	t3,t3,a6
10000794:	01f56533          	or	a0,a0,t6
10000798:	01581813          	slli	a6,a6,0x15
1000079c:	01131f93          	slli	t6,t1,0x11
100007a0:	00f7d893          	srli	a7,a5,0xf
100007a4:	00b75713          	srli	a4,a4,0xb
100007a8:	00a5c533          	xor	a0,a1,a0
100007ac:	01c60e33          	add	t3,a2,t3
100007b0:	01e686b3          	add	a3,a3,t5
100007b4:	01076733          	or	a4,a4,a6
100007b8:	00f35313          	srli	t1,t1,0xf
100007bc:	01f8e8b3          	or	a7,a7,t6
100007c0:	01179793          	slli	a5,a5,0x11
100007c4:	00d50833          	add	a6,a0,a3
100007c8:	00ee4733          	xor	a4,t3,a4
100007cc:	00f367b3          	or	a5,t1,a5
100007d0:	011ec8b3          	xor	a7,t4,a7
100007d4:	00a83f33          	sltu	t5,a6,a0
100007d8:	00f6c6b3          	xor	a3,a3,a5
100007dc:	01d70333          	add	t1,a4,t4
100007e0:	01071f93          	slli	t6,a4,0x10
100007e4:	01158eb3          	add	t4,a1,a7
100007e8:	01075793          	srli	a5,a4,0x10
100007ec:	01055613          	srli	a2,a0,0x10
100007f0:	01051513          	slli	a0,a0,0x10
100007f4:	006f0333          	add	t1,t5,t1
100007f8:	00de0e33          	add	t3,t3,a3
100007fc:	00beb733          	sltu	a4,t4,a1
10000800:	00d69f13          	slli	t5,a3,0xd
10000804:	0138d593          	srli	a1,a7,0x13
10000808:	00a7e7b3          	or	a5,a5,a0
1000080c:	00d89893          	slli	a7,a7,0xd
10000810:	0136d693          	srli	a3,a3,0x13
10000814:	01f66633          	or	a2,a2,t6
10000818:	01e5e5b3          	or	a1,a1,t5
1000081c:	00f847b3          	xor	a5,a6,a5
10000820:	01c70733          	add	a4,a4,t3
10000824:	0116e6b3          	or	a3,a3,a7
10000828:	00c34633          	xor	a2,t1,a2
1000082c:	00dec6b3          	xor	a3,t4,a3
10000830:	00b74733          	xor	a4,a4,a1
10000834:	01579793          	slli	a5,a5,0x15
10000838:	00b65613          	srli	a2,a2,0xb
1000083c:	00f75593          	srli	a1,a4,0xf
10000840:	00f66633          	or	a2,a2,a5
10000844:	01169513          	slli	a0,a3,0x11
10000848:	010687b3          	add	a5,a3,a6
1000084c:	00670733          	add	a4,a4,t1
10000850:	00f64633          	xor	a2,a2,a5
10000854:	00d7b7b3          	sltu	a5,a5,a3
10000858:	00a5e6b3          	or	a3,a1,a0
1000085c:	00e787b3          	add	a5,a5,a4
10000860:	00d64633          	xor	a2,a2,a3
10000864:	00f64633          	xor	a2,a2,a5
10000868:	00161613          	slli	a2,a2,0x1
1000086c:	000f45b7          	lui	a1,0xf4
10000870:	fff0c837          	lui	a6,0xfff0c
10000874:	00165613          	srli	a2,a2,0x1
10000878:	23f58593          	addi	a1,a1,575 # f423f <_start-0xff0bdc1>
1000087c:	dc080813          	addi	a6,a6,-576 # fff0bdc0 <_ebss+0xeff0aa10>
10000880:	01f00713          	li	a4,31
10000884:	00000793          	li	a5,0
10000888:	fff00513          	li	a0,-1
1000088c:	00e656b3          	srl	a3,a2,a4
10000890:	00179793          	slli	a5,a5,0x1
10000894:	0016f693          	andi	a3,a3,1
10000898:	00f6e7b3          	or	a5,a3,a5
1000089c:	fff70713          	addi	a4,a4,-1
100008a0:	00f5f463          	bgeu	a1,a5,100008a8 <emit_new_challenge+0x820>
100008a4:	010787b3          	add	a5,a5,a6
100008a8:	fea712e3          	bne	a4,a0,1000088c <emit_new_challenge+0x804>
100008ac:	10001537          	lui	a0,0x10001
100008b0:	10001737          	lui	a4,0x10001
100008b4:	12450513          	addi	a0,a0,292 # 10001124 <_etext>
100008b8:	3af72623          	sw	a5,940(a4) # 100013ac <g_expected_pin>
100008bc:	00900a93          	li	s5,9
100008c0:	0f0000ef          	jal	100009b0 <uart_puts>
100008c4:	ffc00a13          	li	s4,-4
100008c8:	0004a983          	lw	s3,0(s1)
100008cc:	01c00413          	li	s0,28
100008d0:	0089d7b3          	srl	a5,s3,s0
100008d4:	00f7f713          	andi	a4,a5,15
100008d8:	03770513          	addi	a0,a4,55
100008dc:	00eae463          	bltu	s5,a4,100008e4 <emit_new_challenge+0x85c>
100008e0:	03070513          	addi	a0,a4,48
100008e4:	ffc40413          	addi	s0,s0,-4
100008e8:	0a8000ef          	jal	10000990 <uart_putc>
100008ec:	ff4412e3          	bne	s0,s4,100008d0 <emit_new_challenge+0x848>
100008f0:	00448493          	addi	s1,s1,4
100008f4:	fc991ae3          	bne	s2,s1,100008c8 <emit_new_challenge+0x840>
100008f8:	01812403          	lw	s0,24(sp)
100008fc:	01c12083          	lw	ra,28(sp)
10000900:	01412483          	lw	s1,20(sp)
10000904:	01012903          	lw	s2,16(sp)
10000908:	00c12983          	lw	s3,12(sp)
1000090c:	00812a03          	lw	s4,8(sp)
10000910:	00412a83          	lw	s5,4(sp)
10000914:	10001537          	lui	a0,0x10001
10000918:	13050513          	addi	a0,a0,304 # 10001130 <_etext+0xc>
1000091c:	02010113          	addi	sp,sp,32
10000920:	0900006f          	j	100009b0 <uart_puts>

10000924 <led_set>:
10000924:	300007b7          	lui	a5,0x30000
10000928:	00a7a023          	sw	a0,0(a5) # 30000000 <_ebss+0x1fffec50>
1000092c:	00008067          	ret

10000930 <led_toggle>:
10000930:	300007b7          	lui	a5,0x30000
10000934:	0007a703          	lw	a4,0(a5) # 30000000 <_ebss+0x1fffec50>
10000938:	00e54533          	xor	a0,a0,a4
1000093c:	00a7a023          	sw	a0,0(a5)
10000940:	00008067          	ret

10000944 <led_set_bit>:
10000944:	00f00793          	li	a5,15
10000948:	00a7ee63          	bltu	a5,a0,10000964 <led_set_bit+0x20>
1000094c:	30000737          	lui	a4,0x30000
10000950:	00072683          	lw	a3,0(a4) # 30000000 <_ebss+0x1fffec50>
10000954:	00100793          	li	a5,1
10000958:	00a797b3          	sll	a5,a5,a0
1000095c:	00d7e7b3          	or	a5,a5,a3
10000960:	00f72023          	sw	a5,0(a4)
10000964:	00008067          	ret

10000968 <led_clear_bit>:
10000968:	00f00793          	li	a5,15
1000096c:	02a7e063          	bltu	a5,a0,1000098c <led_clear_bit+0x24>
10000970:	30000737          	lui	a4,0x30000
10000974:	00072683          	lw	a3,0(a4) # 30000000 <_ebss+0x1fffec50>
10000978:	00100793          	li	a5,1
1000097c:	00a797b3          	sll	a5,a5,a0
10000980:	fff7c793          	not	a5,a5
10000984:	00d7f7b3          	and	a5,a5,a3
10000988:	00f72023          	sw	a5,0(a4)
1000098c:	00008067          	ret

10000990 <uart_putc>:
10000990:	20000737          	lui	a4,0x20000
10000994:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
10000998:	200006b7          	lui	a3,0x20000
1000099c:	00072783          	lw	a5,0(a4)
100009a0:	0017f793          	andi	a5,a5,1
100009a4:	fe079ce3          	bnez	a5,1000099c <uart_putc+0xc>
100009a8:	00a6a023          	sw	a0,0(a3) # 20000000 <_ebss+0xfffec50>
100009ac:	00008067          	ret

100009b0 <uart_puts>:
100009b0:	00054783          	lbu	a5,0(a0)
100009b4:	02078e63          	beqz	a5,100009f0 <uart_puts+0x40>
100009b8:	20000737          	lui	a4,0x20000
100009bc:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
100009c0:	00a00593          	li	a1,10
100009c4:	20000637          	lui	a2,0x20000
100009c8:	00d00813          	li	a6,13
100009cc:	02b78463          	beq	a5,a1,100009f4 <uart_puts+0x44>
100009d0:	00054683          	lbu	a3,0(a0)
100009d4:	00150513          	addi	a0,a0,1
100009d8:	00072783          	lw	a5,0(a4)
100009dc:	0017f793          	andi	a5,a5,1
100009e0:	fe079ce3          	bnez	a5,100009d8 <uart_puts+0x28>
100009e4:	00d62023          	sw	a3,0(a2) # 20000000 <_ebss+0xfffec50>
100009e8:	00054783          	lbu	a5,0(a0)
100009ec:	fe0790e3          	bnez	a5,100009cc <uart_puts+0x1c>
100009f0:	00008067          	ret
100009f4:	00072783          	lw	a5,0(a4)
100009f8:	0017f793          	andi	a5,a5,1
100009fc:	fe079ce3          	bnez	a5,100009f4 <uart_puts+0x44>
10000a00:	01062023          	sw	a6,0(a2)
10000a04:	fcdff06f          	j	100009d0 <uart_puts+0x20>

10000a08 <uart_available>:
10000a08:	200007b7          	lui	a5,0x20000
10000a0c:	0047a503          	lw	a0,4(a5) # 20000004 <_ebss+0xfffec54>
10000a10:	00155513          	srli	a0,a0,0x1
10000a14:	00157513          	andi	a0,a0,1
10000a18:	00008067          	ret

10000a1c <uart_getc>:
10000a1c:	20000737          	lui	a4,0x20000
10000a20:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
10000a24:	200006b7          	lui	a3,0x20000
10000a28:	00072783          	lw	a5,0(a4)
10000a2c:	0027f793          	andi	a5,a5,2
10000a30:	fe078ce3          	beqz	a5,10000a28 <uart_getc+0xc>
10000a34:	0006a503          	lw	a0,0(a3) # 20000000 <_ebss+0xfffec50>
10000a38:	0ff57513          	zext.b	a0,a0
10000a3c:	00008067          	ret

10000a40 <uart_print_hex32>:
10000a40:	ff010113          	addi	sp,sp,-16
10000a44:	100017b7          	lui	a5,0x10001
10000a48:	00812423          	sw	s0,8(sp)
10000a4c:	00050413          	mv	s0,a0
10000a50:	39478513          	addi	a0,a5,916 # 10001394 <_etext+0x270>
10000a54:	00112623          	sw	ra,12(sp)
10000a58:	f59ff0ef          	jal	100009b0 <uart_puts>
10000a5c:	20000737          	lui	a4,0x20000
10000a60:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
10000a64:	01c00693          	li	a3,28
10000a68:	00900893          	li	a7,9
10000a6c:	20000837          	lui	a6,0x20000
10000a70:	ffc00513          	li	a0,-4
10000a74:	00d457b3          	srl	a5,s0,a3
10000a78:	00f7f593          	andi	a1,a5,15
10000a7c:	03758613          	addi	a2,a1,55
10000a80:	00b8e463          	bltu	a7,a1,10000a88 <uart_print_hex32+0x48>
10000a84:	03058613          	addi	a2,a1,48
10000a88:	00072783          	lw	a5,0(a4)
10000a8c:	0017f793          	andi	a5,a5,1
10000a90:	fe079ce3          	bnez	a5,10000a88 <uart_print_hex32+0x48>
10000a94:	00c82023          	sw	a2,0(a6) # 20000000 <_ebss+0xfffec50>
10000a98:	ffc68693          	addi	a3,a3,-4
10000a9c:	fca69ce3          	bne	a3,a0,10000a74 <uart_print_hex32+0x34>
10000aa0:	00c12083          	lw	ra,12(sp)
10000aa4:	00812403          	lw	s0,8(sp)
10000aa8:	01010113          	addi	sp,sp,16
10000aac:	00008067          	ret

10000ab0 <uart_print_dec>:
10000ab0:	08050e63          	beqz	a0,10000b4c <uart_print_dec+0x9c>
10000ab4:	ff010113          	addi	sp,sp,-16
10000ab8:	00000313          	li	t1,0
10000abc:	00410e13          	addi	t3,sp,4
10000ac0:	00900893          	li	a7,9
10000ac4:	00100813          	li	a6,1
10000ac8:	fff00593          	li	a1,-1
10000acc:	01f00713          	li	a4,31
10000ad0:	00000793          	li	a5,0
10000ad4:	00000613          	li	a2,0
10000ad8:	00e556b3          	srl	a3,a0,a4
10000adc:	0016f693          	andi	a3,a3,1
10000ae0:	00179793          	slli	a5,a5,0x1
10000ae4:	00f6e7b3          	or	a5,a3,a5
10000ae8:	00e816b3          	sll	a3,a6,a4
10000aec:	fff70713          	addi	a4,a4,-1
10000af0:	00f8f663          	bgeu	a7,a5,10000afc <uart_print_dec+0x4c>
10000af4:	ff678793          	addi	a5,a5,-10
10000af8:	00d66633          	or	a2,a2,a3
10000afc:	fcb71ee3          	bne	a4,a1,10000ad8 <uart_print_dec+0x28>
10000b00:	00130313          	addi	t1,t1,1
10000b04:	03078793          	addi	a5,a5,48
10000b08:	006e06b3          	add	a3,t3,t1
10000b0c:	fef68fa3          	sb	a5,-1(a3)
10000b10:	00060663          	beqz	a2,10000b1c <uart_print_dec+0x6c>
10000b14:	00060513          	mv	a0,a2
10000b18:	fb5ff06f          	j	10000acc <uart_print_dec+0x1c>
10000b1c:	20000737          	lui	a4,0x20000
10000b20:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
10000b24:	200005b7          	lui	a1,0x20000
10000b28:	fff6c603          	lbu	a2,-1(a3)
10000b2c:	00072783          	lw	a5,0(a4)
10000b30:	0017f793          	andi	a5,a5,1
10000b34:	fe079ce3          	bnez	a5,10000b2c <uart_print_dec+0x7c>
10000b38:	00c5a023          	sw	a2,0(a1) # 20000000 <_ebss+0xfffec50>
10000b3c:	fff68693          	addi	a3,a3,-1
10000b40:	fede14e3          	bne	t3,a3,10000b28 <uart_print_dec+0x78>
10000b44:	01010113          	addi	sp,sp,16
10000b48:	00008067          	ret
10000b4c:	20000737          	lui	a4,0x20000
10000b50:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xfffec54>
10000b54:	200006b7          	lui	a3,0x20000
10000b58:	00072783          	lw	a5,0(a4)
10000b5c:	0017f793          	andi	a5,a5,1
10000b60:	fe079ce3          	bnez	a5,10000b58 <uart_print_dec+0xa8>
10000b64:	03000793          	li	a5,48
10000b68:	00f6a023          	sw	a5,0(a3) # 20000000 <_ebss+0xfffec50>
10000b6c:	00008067          	ret

10000b70 <timer_init>:
10000b70:	400007b7          	lui	a5,0x40000
10000b74:	00100713          	li	a4,1
10000b78:	00e7a423          	sw	a4,8(a5) # 40000008 <_ebss+0x2fffec58>
10000b7c:	00008067          	ret

10000b80 <timer_get_cycles>:
10000b80:	400007b7          	lui	a5,0x40000
10000b84:	0007a503          	lw	a0,0(a5) # 40000000 <_ebss+0x2fffec50>
10000b88:	00008067          	ret

10000b8c <timer_delay_cycles>:
10000b8c:	40000737          	lui	a4,0x40000
10000b90:	00072683          	lw	a3,0(a4) # 40000000 <_ebss+0x2fffec50>
10000b94:	00072783          	lw	a5,0(a4)
10000b98:	40d787b3          	sub	a5,a5,a3
10000b9c:	fea7ece3          	bltu	a5,a0,10000b94 <timer_delay_cycles+0x8>
10000ba0:	00008067          	ret

10000ba4 <trng_init>:
10000ba4:	500007b7          	lui	a5,0x50000
10000ba8:	00300713          	li	a4,3
10000bac:	00e7a423          	sw	a4,8(a5) # 50000008 <_ebss+0x3fffec58>
10000bb0:	00008067          	ret

10000bb4 <trng_is_warm>:
10000bb4:	500007b7          	lui	a5,0x50000
10000bb8:	0047a503          	lw	a0,4(a5) # 50000004 <_ebss+0x3fffec54>
10000bbc:	00455513          	srli	a0,a0,0x4
10000bc0:	00157513          	andi	a0,a0,1
10000bc4:	00008067          	ret

10000bc8 <trng_has_data>:
10000bc8:	500007b7          	lui	a5,0x50000
10000bcc:	0047a503          	lw	a0,4(a5) # 50000004 <_ebss+0x3fffec54>
10000bd0:	00157513          	andi	a0,a0,1
10000bd4:	00008067          	ret

10000bd8 <trng_read>:
10000bd8:	50000737          	lui	a4,0x50000
10000bdc:	00470713          	addi	a4,a4,4 # 50000004 <_ebss+0x3fffec54>
10000be0:	500006b7          	lui	a3,0x50000
10000be4:	00072783          	lw	a5,0(a4)
10000be8:	0017f793          	andi	a5,a5,1
10000bec:	fe078ce3          	beqz	a5,10000be4 <trng_read+0xc>
10000bf0:	0006a503          	lw	a0,0(a3) # 50000000 <_ebss+0x3fffec50>
10000bf4:	00008067          	ret

10000bf8 <main>:
10000bf8:	f6010113          	addi	sp,sp,-160
10000bfc:	08112e23          	sw	ra,156(sp)
10000c00:	08812c23          	sw	s0,152(sp)
10000c04:	08912a23          	sw	s1,148(sp)
10000c08:	09212823          	sw	s2,144(sp)
10000c0c:	09312623          	sw	s3,140(sp)
10000c10:	09412423          	sw	s4,136(sp)
10000c14:	09512223          	sw	s5,132(sp)
10000c18:	09612023          	sw	s6,128(sp)
10000c1c:	07712e23          	sw	s7,124(sp)
10000c20:	07812c23          	sw	s8,120(sp)
10000c24:	07912a23          	sw	s9,116(sp)
10000c28:	07a12823          	sw	s10,112(sp)
10000c2c:	07b12623          	sw	s11,108(sp)
10000c30:	f41ff0ef          	jal	10000b70 <timer_init>
10000c34:	f71ff0ef          	jal	10000ba4 <trng_init>
10000c38:	00100513          	li	a0,1
10000c3c:	ce9ff0ef          	jal	10000924 <led_set>
10000c40:	f75ff0ef          	jal	10000bb4 <trng_is_warm>
10000c44:	fe050ee3          	beqz	a0,10000c40 <main+0x48>
10000c48:	100017b7          	lui	a5,0x10001
10000c4c:	13078513          	addi	a0,a5,304 # 10001130 <_etext+0xc>
10000c50:	d61ff0ef          	jal	100009b0 <uart_puts>
10000c54:	10001437          	lui	s0,0x10001
10000c58:	16440513          	addi	a0,s0,356 # 10001164 <_etext+0x40>
10000c5c:	d55ff0ef          	jal	100009b0 <uart_puts>
10000c60:	10001537          	lui	a0,0x10001
10000c64:	1a850513          	addi	a0,a0,424 # 100011a8 <_etext+0x84>
10000c68:	d49ff0ef          	jal	100009b0 <uart_puts>
10000c6c:	16440513          	addi	a0,s0,356
10000c70:	d41ff0ef          	jal	100009b0 <uart_puts>
10000c74:	c14ff0ef          	jal	10000088 <emit_new_challenge>
10000c78:	100017b7          	lui	a5,0x10001
10000c7c:	15478793          	addi	a5,a5,340 # 10001154 <_etext+0x30>
10000c80:	10001a37          	lui	s4,0x10001
10000c84:	10001737          	lui	a4,0x10001
10000c88:	00f12623          	sw	a5,12(sp)
10000c8c:	3a8a2783          	lw	a5,936(s4) # 100013a8 <g_is_unlocked>
10000c90:	15c70713          	addi	a4,a4,348 # 1000115c <_etext+0x38>
10000c94:	10001c37          	lui	s8,0x10001
10000c98:	10001d37          	lui	s10,0x10001
10000c9c:	10001db7          	lui	s11,0x10001
10000ca0:	006ad937          	lui	s2,0x6ad
10000ca4:	00e12423          	sw	a4,8(sp)
10000ca8:	134c0c13          	addi	s8,s8,308 # 10001134 <_etext+0x10>
10000cac:	144d0d13          	addi	s10,s10,324 # 10001144 <_etext+0x20>
10000cb0:	14cd8d93          	addi	s11,s11,332 # 1000114c <_etext+0x28>
10000cb4:	fbf90913          	addi	s2,s2,-65 # 6acfbf <_start-0xf953041>
10000cb8:	00100993          	li	s3,1
10000cbc:	10001cb7          	lui	s9,0x10001
10000cc0:	00d00a93          	li	s5,13
10000cc4:	00a00b13          	li	s6,10
10000cc8:	03f00b93          	li	s7,63
10000ccc:	0c078063          	beqz	a5,10000d8c <main+0x194>
10000cd0:	d39ff0ef          	jal	10000a08 <uart_available>
10000cd4:	08050a63          	beqz	a0,10000d68 <main+0x170>
10000cd8:	d45ff0ef          	jal	10000a1c <uart_getc>
10000cdc:	ff550ee3          	beq	a0,s5,10000cd8 <main+0xe0>
10000ce0:	00000793          	li	a5,0
10000ce4:	05078713          	addi	a4,a5,80
10000ce8:	01010693          	addi	a3,sp,16
10000cec:	00d70733          	add	a4,a4,a3
10000cf0:	00178413          	addi	s0,a5,1
10000cf4:	0d650263          	beq	a0,s6,10000db8 <main+0x1c0>
10000cf8:	fca70023          	sb	a0,-64(a4)
10000cfc:	19740a63          	beq	s0,s7,10000e90 <main+0x298>
10000d00:	d1dff0ef          	jal	10000a1c <uart_getc>
10000d04:	00040793          	mv	a5,s0
10000d08:	fd551ee3          	bne	a0,s5,10000ce4 <main+0xec>
10000d0c:	002787b3          	add	a5,a5,sp
10000d10:	02078023          	sb	zero,32(a5)
10000d14:	02014503          	lbu	a0,32(sp)
10000d18:	0a050a63          	beqz	a0,10000dcc <main+0x1d4>
10000d1c:	00050793          	mv	a5,a0
10000d20:	000c0613          	mv	a2,s8
10000d24:	02010713          	addi	a4,sp,32
10000d28:	05200693          	li	a3,82
10000d2c:	00170713          	addi	a4,a4,1
10000d30:	12d79063          	bne	a5,a3,10000e50 <main+0x258>
10000d34:	00074783          	lbu	a5,0(a4)
10000d38:	00164683          	lbu	a3,1(a2)
10000d3c:	00160593          	addi	a1,a2,1
10000d40:	00078663          	beqz	a5,10000d4c <main+0x154>
10000d44:	00058613          	mv	a2,a1
10000d48:	fe0692e3          	bnez	a3,10000d2c <main+0x134>
10000d4c:	10d79263          	bne	a5,a3,10000e50 <main+0x258>
10000d50:	00000513          	li	a0,0
10000d54:	3a0a2423          	sw	zero,936(s4)
10000d58:	bcdff0ef          	jal	10000924 <led_set>
10000d5c:	1ecc8513          	addi	a0,s9,492 # 100011ec <_etext+0xc8>
10000d60:	c51ff0ef          	jal	100009b0 <uart_puts>
10000d64:	b24ff0ef          	jal	10000088 <emit_new_challenge>
10000d68:	e19ff0ef          	jal	10000b80 <timer_get_cycles>
10000d6c:	002dc437          	lui	s0,0x2dc
10000d70:	00050493          	mv	s1,a0
10000d74:	6bf40413          	addi	s0,s0,1727 # 2dc6bf <_start-0xfd23941>
10000d78:	e09ff0ef          	jal	10000b80 <timer_get_cycles>
10000d7c:	40950533          	sub	a0,a0,s1
10000d80:	fea47ce3          	bgeu	s0,a0,10000d78 <main+0x180>
10000d84:	3a8a2783          	lw	a5,936(s4)
10000d88:	f40794e3          	bnez	a5,10000cd0 <main+0xd8>
10000d8c:	00098513          	mv	a0,s3
10000d90:	b95ff0ef          	jal	10000924 <led_set>
10000d94:	00199793          	slli	a5,s3,0x1
10000d98:	01079713          	slli	a4,a5,0x10
10000d9c:	01175713          	srli	a4,a4,0x11
10000da0:	00078993          	mv	s3,a5
10000da4:	00071463          	bnez	a4,10000dac <main+0x1b4>
10000da8:	00100993          	li	s3,1
10000dac:	01099993          	slli	s3,s3,0x10
10000db0:	0109d993          	srli	s3,s3,0x10
10000db4:	f1dff06f          	j	10000cd0 <main+0xd8>
10000db8:	f20780e3          	beqz	a5,10000cd8 <main+0xe0>
10000dbc:	002787b3          	add	a5,a5,sp
10000dc0:	02078023          	sb	zero,32(a5)
10000dc4:	02014503          	lbu	a0,32(sp)
10000dc8:	f4051ae3          	bnez	a0,10000d1c <main+0x124>
10000dcc:	000d8713          	mv	a4,s11
10000dd0:	02010793          	addi	a5,sp,32
10000dd4:	05000693          	li	a3,80
10000dd8:	00c0006f          	j	10000de4 <main+0x1ec>
10000ddc:	00074683          	lbu	a3,0(a4)
10000de0:	0a068c63          	beqz	a3,10000e98 <main+0x2a0>
10000de4:	0007c603          	lbu	a2,0(a5)
10000de8:	00170713          	addi	a4,a4,1
10000dec:	00178793          	addi	a5,a5,1
10000df0:	fed606e3          	beq	a2,a3,10000ddc <main+0x1e4>
10000df4:	fd050793          	addi	a5,a0,-48
10000df8:	0ff7f793          	zext.b	a5,a5
10000dfc:	00900713          	li	a4,9
10000e00:	08f77c63          	bgeu	a4,a5,10000e98 <main+0x2a0>
10000e04:	3a8a2783          	lw	a5,936(s4)
10000e08:	18078063          	beqz	a5,10000f88 <main+0x390>
10000e0c:	00c12783          	lw	a5,12(sp)
10000e10:	02010713          	addi	a4,sp,32
10000e14:	00051c63          	bnez	a0,10000e2c <main+0x234>
10000e18:	1980006f          	j	10000fb0 <main+0x3b8>
10000e1c:	18a69a63          	bne	a3,a0,10000fb0 <main+0x3b8>
10000e20:	00074503          	lbu	a0,0(a4)
10000e24:	00178793          	addi	a5,a5,1
10000e28:	00050863          	beqz	a0,10000e38 <main+0x240>
10000e2c:	0007c683          	lbu	a3,0(a5)
10000e30:	00170713          	addi	a4,a4,1
10000e34:	fe0694e3          	bnez	a3,10000e1c <main+0x224>
10000e38:	0007c783          	lbu	a5,0(a5)
10000e3c:	16a79a63          	bne	a5,a0,10000fb0 <main+0x3b8>
10000e40:	100017b7          	lui	a5,0x10001
10000e44:	2c878513          	addi	a0,a5,712 # 100012c8 <_etext+0x1a4>
10000e48:	b69ff0ef          	jal	100009b0 <uart_puts>
10000e4c:	f1dff06f          	j	10000d68 <main+0x170>
10000e50:	00050713          	mv	a4,a0
10000e54:	000d0693          	mv	a3,s10
10000e58:	02010793          	addi	a5,sp,32
10000e5c:	05200613          	li	a2,82
10000e60:	00178793          	addi	a5,a5,1
10000e64:	f6c714e3          	bne	a4,a2,10000dcc <main+0x1d4>
10000e68:	0007c703          	lbu	a4,0(a5)
10000e6c:	00168593          	addi	a1,a3,1
10000e70:	00070a63          	beqz	a4,10000e84 <main+0x28c>
10000e74:	0016c603          	lbu	a2,1(a3)
10000e78:	00058693          	mv	a3,a1
10000e7c:	fe0612e3          	bnez	a2,10000e60 <main+0x268>
10000e80:	f4dff06f          	j	10000dcc <main+0x1d4>
10000e84:	0016c783          	lbu	a5,1(a3)
10000e88:	ec0784e3          	beqz	a5,10000d50 <main+0x158>
10000e8c:	f41ff06f          	j	10000dcc <main+0x1d4>
10000e90:	000b8793          	mv	a5,s7
10000e94:	e79ff06f          	j	10000d0c <main+0x114>
10000e98:	000d8713          	mv	a4,s11
10000e9c:	05000693          	li	a3,80
10000ea0:	02010793          	addi	a5,sp,32
10000ea4:	00c0006f          	j	10000eb0 <main+0x2b8>
10000ea8:	00074683          	lbu	a3,0(a4)
10000eac:	0e068c63          	beqz	a3,10000fa4 <main+0x3ac>
10000eb0:	0007c603          	lbu	a2,0(a5)
10000eb4:	00170713          	addi	a4,a4,1
10000eb8:	00178793          	addi	a5,a5,1
10000ebc:	fed606e3          	beq	a2,a3,10000ea8 <main+0x2b0>
10000ec0:	02010613          	addi	a2,sp,32
10000ec4:	fd050793          	addi	a5,a0,-48
10000ec8:	0ff7f793          	zext.b	a5,a5
10000ecc:	00900693          	li	a3,9
10000ed0:	04f6e663          	bltu	a3,a5,10000f1c <main+0x324>
10000ed4:	00000713          	li	a4,0
10000ed8:	00000413          	li	s0,0
10000edc:	00241793          	slli	a5,s0,0x2
10000ee0:	008787b3          	add	a5,a5,s0
10000ee4:	00170713          	addi	a4,a4,1
10000ee8:	00179793          	slli	a5,a5,0x1
10000eec:	00e605b3          	add	a1,a2,a4
10000ef0:	00a787b3          	add	a5,a5,a0
10000ef4:	0005c503          	lbu	a0,0(a1)
10000ef8:	fd078413          	addi	s0,a5,-48
10000efc:	fd050793          	addi	a5,a0,-48
10000f00:	0ff7f793          	zext.b	a5,a5
10000f04:	fcf6fce3          	bgeu	a3,a5,10000edc <main+0x2e4>
10000f08:	00600793          	li	a5,6
10000f0c:	00f71863          	bne	a4,a5,10000f1c <main+0x324>
10000f10:	100017b7          	lui	a5,0x10001
10000f14:	3ac7a783          	lw	a5,940(a5) # 100013ac <g_expected_pin>
10000f18:	12878063          	beq	a5,s0,10001038 <main+0x440>
10000f1c:	100017b7          	lui	a5,0x10001
10000f20:	28478513          	addi	a0,a5,644 # 10001284 <_etext+0x160>
10000f24:	3a0a2423          	sw	zero,936(s4)
10000f28:	a89ff0ef          	jal	100009b0 <uart_puts>
10000f2c:	100017b7          	lui	a5,0x10001
10000f30:	29c78513          	addi	a0,a5,668 # 1000129c <_etext+0x178>
10000f34:	a7dff0ef          	jal	100009b0 <uart_puts>
10000f38:	00300493          	li	s1,3
10000f3c:	0000b537          	lui	a0,0xb
10000f40:	aaa50513          	addi	a0,a0,-1366 # aaaa <_start-0xfff5556>
10000f44:	9e1ff0ef          	jal	10000924 <led_set>
10000f48:	c39ff0ef          	jal	10000b80 <timer_get_cycles>
10000f4c:	00050413          	mv	s0,a0
10000f50:	c31ff0ef          	jal	10000b80 <timer_get_cycles>
10000f54:	40850533          	sub	a0,a0,s0
10000f58:	fea97ce3          	bgeu	s2,a0,10000f50 <main+0x358>
10000f5c:	00000513          	li	a0,0
10000f60:	9c5ff0ef          	jal	10000924 <led_set>
10000f64:	c1dff0ef          	jal	10000b80 <timer_get_cycles>
10000f68:	00050413          	mv	s0,a0
10000f6c:	c15ff0ef          	jal	10000b80 <timer_get_cycles>
10000f70:	40850533          	sub	a0,a0,s0
10000f74:	fea97ce3          	bgeu	s2,a0,10000f6c <main+0x374>
10000f78:	fff48493          	addi	s1,s1,-1
10000f7c:	fc0490e3          	bnez	s1,10000f3c <main+0x344>
10000f80:	908ff0ef          	jal	10000088 <emit_new_challenge>
10000f84:	de5ff06f          	j	10000d68 <main+0x170>
10000f88:	100017b7          	lui	a5,0x10001
10000f8c:	2fc78513          	addi	a0,a5,764 # 100012fc <_etext+0x1d8>
10000f90:	a21ff0ef          	jal	100009b0 <uart_puts>
10000f94:	100017b7          	lui	a5,0x10001
10000f98:	33c78513          	addi	a0,a5,828 # 1000133c <_etext+0x218>
10000f9c:	a15ff0ef          	jal	100009b0 <uart_puts>
10000fa0:	dc9ff06f          	j	10000d68 <main+0x170>
10000fa4:	02414503          	lbu	a0,36(sp)
10000fa8:	02410613          	addi	a2,sp,36
10000fac:	f19ff06f          	j	10000ec4 <main+0x2cc>
10000fb0:	00812683          	lw	a3,8(sp)
10000fb4:	04c00713          	li	a4,76
10000fb8:	02010793          	addi	a5,sp,32
10000fbc:	00c0006f          	j	10000fc8 <main+0x3d0>
10000fc0:	0006c703          	lbu	a4,0(a3)
10000fc4:	04070e63          	beqz	a4,10001020 <main+0x428>
10000fc8:	0007c603          	lbu	a2,0(a5)
10000fcc:	00168693          	addi	a3,a3,1
10000fd0:	00178793          	addi	a5,a5,1
10000fd4:	fee606e3          	beq	a2,a4,10000fc0 <main+0x3c8>
10000fd8:	100017b7          	lui	a5,0x10001
10000fdc:	38c78593          	addi	a1,a5,908 # 1000138c <_etext+0x268>
10000fe0:	02010513          	addi	a0,sp,32
10000fe4:	84cff0ef          	jal	10000030 <str_equal>
10000fe8:	0e051a63          	bnez	a0,100010dc <main+0x4e4>
10000fec:	100017b7          	lui	a5,0x10001
10000ff0:	2f478593          	addi	a1,a5,756 # 100012f4 <_etext+0x1d0>
10000ff4:	02010513          	addi	a0,sp,32
10000ff8:	838ff0ef          	jal	10000030 <str_equal>
10000ffc:	10050263          	beqz	a0,10001100 <main+0x508>
10001000:	100017b7          	lui	a5,0x10001
10001004:	2fc78513          	addi	a0,a5,764 # 100012fc <_etext+0x1d8>
10001008:	3a0a2423          	sw	zero,936(s4)
1000100c:	9a5ff0ef          	jal	100009b0 <uart_puts>
10001010:	100017b7          	lui	a5,0x10001
10001014:	30c78513          	addi	a0,a5,780 # 1000130c <_etext+0x1e8>
10001018:	999ff0ef          	jal	100009b0 <uart_puts>
1000101c:	f65ff06f          	j	10000f80 <main+0x388>
10001020:	0ff00513          	li	a0,255
10001024:	901ff0ef          	jal	10000924 <led_set>
10001028:	100017b7          	lui	a5,0x10001
1000102c:	37078513          	addi	a0,a5,880 # 10001370 <_etext+0x24c>
10001030:	981ff0ef          	jal	100009b0 <uart_puts>
10001034:	d35ff06f          	j	10000d68 <main+0x170>
10001038:	100017b7          	lui	a5,0x10001
1000103c:	21878513          	addi	a0,a5,536 # 10001218 <_etext+0xf4>
10001040:	00100493          	li	s1,1
10001044:	3a9a2423          	sw	s1,936(s4)
10001048:	969ff0ef          	jal	100009b0 <uart_puts>
1000104c:	100017b7          	lui	a5,0x10001
10001050:	23078513          	addi	a0,a5,560 # 10001230 <_etext+0x10c>
10001054:	95dff0ef          	jal	100009b0 <uart_puts>
10001058:	01810813          	addi	a6,sp,24
1000105c:	00010f23          	sb	zero,30(sp)
10001060:	00900513          	li	a0,9
10001064:	fff00593          	li	a1,-1
10001068:	00000613          	li	a2,0
1000106c:	01f00713          	li	a4,31
10001070:	00000793          	li	a5,0
10001074:	00e456b3          	srl	a3,s0,a4
10001078:	0016f693          	andi	a3,a3,1
1000107c:	00179793          	slli	a5,a5,0x1
10001080:	00f6e7b3          	or	a5,a3,a5
10001084:	00e496b3          	sll	a3,s1,a4
10001088:	fff70713          	addi	a4,a4,-1
1000108c:	00f57663          	bgeu	a0,a5,10001098 <main+0x4a0>
10001090:	ff678793          	addi	a5,a5,-10
10001094:	00d66633          	or	a2,a2,a3
10001098:	fcb71ee3          	bne	a4,a1,10001074 <main+0x47c>
1000109c:	03078793          	addi	a5,a5,48
100010a0:	00f802a3          	sb	a5,5(a6)
100010a4:	fff80813          	addi	a6,a6,-1
100010a8:	01210793          	addi	a5,sp,18
100010ac:	01078663          	beq	a5,a6,100010b8 <main+0x4c0>
100010b0:	00060413          	mv	s0,a2
100010b4:	fb5ff06f          	j	10001068 <main+0x470>
100010b8:	01810513          	addi	a0,sp,24
100010bc:	8f5ff0ef          	jal	100009b0 <uart_puts>
100010c0:	100017b7          	lui	a5,0x10001
100010c4:	25878513          	addi	a0,a5,600 # 10001258 <_etext+0x134>
100010c8:	8e9ff0ef          	jal	100009b0 <uart_puts>
100010cc:	00010537          	lui	a0,0x10
100010d0:	fff50513          	addi	a0,a0,-1 # ffff <_start-0xfff0001>
100010d4:	851ff0ef          	jal	10000924 <led_set>
100010d8:	c91ff06f          	j	10000d68 <main+0x170>
100010dc:	100017b7          	lui	a5,0x10001
100010e0:	2d078513          	addi	a0,a5,720 # 100012d0 <_etext+0x1ac>
100010e4:	8cdff0ef          	jal	100009b0 <uart_puts>
100010e8:	a99ff0ef          	jal	10000b80 <timer_get_cycles>
100010ec:	9c5ff0ef          	jal	10000ab0 <uart_print_dec>
100010f0:	100017b7          	lui	a5,0x10001
100010f4:	2e078513          	addi	a0,a5,736 # 100012e0 <_etext+0x1bc>
100010f8:	8b9ff0ef          	jal	100009b0 <uart_puts>
100010fc:	c6dff06f          	j	10000d68 <main+0x170>
10001100:	100017b7          	lui	a5,0x10001
10001104:	33478513          	addi	a0,a5,820 # 10001334 <_etext+0x210>
10001108:	8a9ff0ef          	jal	100009b0 <uart_puts>
1000110c:	02010513          	addi	a0,sp,32
10001110:	8a1ff0ef          	jal	100009b0 <uart_puts>
10001114:	100017b7          	lui	a5,0x10001
10001118:	13078513          	addi	a0,a5,304 # 10001130 <_etext+0xc>
1000111c:	895ff0ef          	jal	100009b0 <uart_puts>
10001120:	c49ff06f          	j	10000d68 <main+0x170>
