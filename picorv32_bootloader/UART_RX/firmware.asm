
/home/yuvan66/Documents/picorv32_bootloader(1)/picorv32_bootloader/UART_RX/firmware.elf:     file format elf32-littleriscv


Disassembly of section .text:

10000000 <_start>:
10000000:	10002137          	lui	sp,0x10002
10000004:	ffc10113          	addi	sp,sp,-4 # 10001ffc <_ebss+0x1238>
10000008:	00001517          	auipc	a0,0x1
1000000c:	dbc50513          	addi	a0,a0,-580 # 10000dc4 <_ebss>
10000010:	00001597          	auipc	a1,0x1
10000014:	db458593          	addi	a1,a1,-588 # 10000dc4 <_ebss>
10000018:	00b55863          	bge	a0,a1,10000028 <bss_done>

1000001c <bss_loop>:
1000001c:	00052023          	sw	zero,0(a0)
10000020:	00450513          	addi	a0,a0,4
10000024:	feb54ce3          	blt	a0,a1,1000001c <bss_loop>

10000028 <bss_done>:
10000028:	1e0000ef          	jal	10000208 <main>

1000002c <hang>:
1000002c:	0000006f          	j	1000002c <hang>

10000030 <uart_puts>:
10000030:	00054783          	lbu	a5,0(a0)
10000034:	02078e63          	beqz	a5,10000070 <uart_puts+0x40>
10000038:	20000737          	lui	a4,0x20000
1000003c:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xffff240>
10000040:	00a00593          	li	a1,10
10000044:	20000637          	lui	a2,0x20000
10000048:	00d00813          	li	a6,13
1000004c:	02b78463          	beq	a5,a1,10000074 <uart_puts+0x44>
10000050:	00054683          	lbu	a3,0(a0)
10000054:	00150513          	addi	a0,a0,1
10000058:	00072783          	lw	a5,0(a4)
1000005c:	0017f793          	andi	a5,a5,1
10000060:	fe079ce3          	bnez	a5,10000058 <uart_puts+0x28>
10000064:	00d62023          	sw	a3,0(a2) # 20000000 <_ebss+0xffff23c>
10000068:	00054783          	lbu	a5,0(a0)
1000006c:	fe0790e3          	bnez	a5,1000004c <uart_puts+0x1c>
10000070:	00008067          	ret
10000074:	00072783          	lw	a5,0(a4)
10000078:	0017f793          	andi	a5,a5,1
1000007c:	fe079ce3          	bnez	a5,10000074 <uart_puts+0x44>
10000080:	01062023          	sw	a6,0(a2)
10000084:	fcdff06f          	j	10000050 <uart_puts+0x20>

10000088 <uart_print_hex32>:
10000088:	ff010113          	addi	sp,sp,-16
1000008c:	100007b7          	lui	a5,0x10000
10000090:	00812423          	sw	s0,8(sp)
10000094:	00050413          	mv	s0,a0
10000098:	7c478513          	addi	a0,a5,1988 # 100007c4 <_etext>
1000009c:	00112623          	sw	ra,12(sp)
100000a0:	f91ff0ef          	jal	10000030 <uart_puts>
100000a4:	20000737          	lui	a4,0x20000
100000a8:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xffff240>
100000ac:	01c00693          	li	a3,28
100000b0:	00900893          	li	a7,9
100000b4:	20000837          	lui	a6,0x20000
100000b8:	ffc00513          	li	a0,-4
100000bc:	00d457b3          	srl	a5,s0,a3
100000c0:	00f7f593          	andi	a1,a5,15
100000c4:	03758613          	addi	a2,a1,55
100000c8:	00b8e463          	bltu	a7,a1,100000d0 <uart_print_hex32+0x48>
100000cc:	03058613          	addi	a2,a1,48
100000d0:	00072783          	lw	a5,0(a4)
100000d4:	0017f793          	andi	a5,a5,1
100000d8:	fe079ce3          	bnez	a5,100000d0 <uart_print_hex32+0x48>
100000dc:	00c82023          	sw	a2,0(a6) # 20000000 <_ebss+0xffff23c>
100000e0:	ffc68693          	addi	a3,a3,-4
100000e4:	fca69ce3          	bne	a3,a0,100000bc <uart_print_hex32+0x34>
100000e8:	00c12083          	lw	ra,12(sp)
100000ec:	00812403          	lw	s0,8(sp)
100000f0:	01010113          	addi	sp,sp,16
100000f4:	00008067          	ret

100000f8 <uart_print_hex16>:
100000f8:	ff010113          	addi	sp,sp,-16
100000fc:	100007b7          	lui	a5,0x10000
10000100:	00812423          	sw	s0,8(sp)
10000104:	00050413          	mv	s0,a0
10000108:	7c478513          	addi	a0,a5,1988 # 100007c4 <_etext>
1000010c:	00112623          	sw	ra,12(sp)
10000110:	f21ff0ef          	jal	10000030 <uart_puts>
10000114:	20000737          	lui	a4,0x20000
10000118:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xffff240>
1000011c:	00c00693          	li	a3,12
10000120:	00900893          	li	a7,9
10000124:	20000837          	lui	a6,0x20000
10000128:	ffc00513          	li	a0,-4
1000012c:	40d457b3          	sra	a5,s0,a3
10000130:	00f7f593          	andi	a1,a5,15
10000134:	03758613          	addi	a2,a1,55
10000138:	00b8c463          	blt	a7,a1,10000140 <uart_print_hex16+0x48>
1000013c:	03058613          	addi	a2,a1,48
10000140:	00072783          	lw	a5,0(a4)
10000144:	0017f793          	andi	a5,a5,1
10000148:	fe079ce3          	bnez	a5,10000140 <uart_print_hex16+0x48>
1000014c:	00c82023          	sw	a2,0(a6) # 20000000 <_ebss+0xffff23c>
10000150:	ffc68693          	addi	a3,a3,-4
10000154:	fca69ce3          	bne	a3,a0,1000012c <uart_print_hex16+0x34>
10000158:	00c12083          	lw	ra,12(sp)
1000015c:	00812403          	lw	s0,8(sp)
10000160:	01010113          	addi	sp,sp,16
10000164:	00008067          	ret

10000168 <uart_print_dec.part.0>:
10000168:	08050e63          	beqz	a0,10000204 <uart_print_dec.part.0+0x9c>
1000016c:	ff010113          	addi	sp,sp,-16
10000170:	00000313          	li	t1,0
10000174:	00410e13          	addi	t3,sp,4
10000178:	00900893          	li	a7,9
1000017c:	00100813          	li	a6,1
10000180:	fff00593          	li	a1,-1
10000184:	00000613          	li	a2,0
10000188:	01f00713          	li	a4,31
1000018c:	00000793          	li	a5,0
10000190:	00e556b3          	srl	a3,a0,a4
10000194:	0016f693          	andi	a3,a3,1
10000198:	00179793          	slli	a5,a5,0x1
1000019c:	00f6e7b3          	or	a5,a3,a5
100001a0:	00e816b3          	sll	a3,a6,a4
100001a4:	fff70713          	addi	a4,a4,-1
100001a8:	00f8f663          	bgeu	a7,a5,100001b4 <uart_print_dec.part.0+0x4c>
100001ac:	ff678793          	addi	a5,a5,-10
100001b0:	00d66633          	or	a2,a2,a3
100001b4:	fcb71ee3          	bne	a4,a1,10000190 <uart_print_dec.part.0+0x28>
100001b8:	00130313          	addi	t1,t1,1
100001bc:	03078793          	addi	a5,a5,48
100001c0:	006e06b3          	add	a3,t3,t1
100001c4:	fef68fa3          	sb	a5,-1(a3)
100001c8:	00060663          	beqz	a2,100001d4 <uart_print_dec.part.0+0x6c>
100001cc:	00060513          	mv	a0,a2
100001d0:	fb5ff06f          	j	10000184 <uart_print_dec.part.0+0x1c>
100001d4:	20000737          	lui	a4,0x20000
100001d8:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xffff240>
100001dc:	200005b7          	lui	a1,0x20000
100001e0:	fff6c603          	lbu	a2,-1(a3)
100001e4:	00072783          	lw	a5,0(a4)
100001e8:	0017f793          	andi	a5,a5,1
100001ec:	fe079ce3          	bnez	a5,100001e4 <uart_print_dec.part.0+0x7c>
100001f0:	00c5a023          	sw	a2,0(a1) # 20000000 <_ebss+0xffff23c>
100001f4:	fff68693          	addi	a3,a3,-1
100001f8:	fede14e3          	bne	t3,a3,100001e0 <uart_print_dec.part.0+0x78>
100001fc:	01010113          	addi	sp,sp,16
10000200:	00008067          	ret
10000204:	00008067          	ret

10000208 <main>:
10000208:	fa010113          	addi	sp,sp,-96
1000020c:	00003737          	lui	a4,0x3
10000210:	04112e23          	sw	ra,92(sp)
10000214:	04812c23          	sw	s0,88(sp)
10000218:	04912a23          	sw	s1,84(sp)
1000021c:	05212823          	sw	s2,80(sp)
10000220:	05312623          	sw	s3,76(sp)
10000224:	05412423          	sw	s4,72(sp)
10000228:	05512223          	sw	s5,68(sp)
1000022c:	05612023          	sw	s6,64(sp)
10000230:	03712e23          	sw	s7,60(sp)
10000234:	03812c23          	sw	s8,56(sp)
10000238:	03912a23          	sw	s9,52(sp)
1000023c:	03a12823          	sw	s10,48(sp)
10000240:	03b12623          	sw	s11,44(sp)
10000244:	edf70713          	addi	a4,a4,-289 # 2edf <_start-0xfffd121>
10000248:	00000693          	li	a3,0
1000024c:	00100513          	li	a0,1
10000250:	300005b7          	lui	a1,0x30000
10000254:	01000613          	li	a2,16
10000258:	00d517b3          	sll	a5,a0,a3
1000025c:	00f5a023          	sw	a5,0(a1) # 30000000 <_ebss+0x1ffff23c>
10000260:	00012823          	sw	zero,16(sp)
10000264:	01012783          	lw	a5,16(sp)
10000268:	00f74c63          	blt	a4,a5,10000280 <main+0x78>
1000026c:	01012783          	lw	a5,16(sp)
10000270:	00178793          	addi	a5,a5,1
10000274:	00f12823          	sw	a5,16(sp)
10000278:	01012783          	lw	a5,16(sp)
1000027c:	fef758e3          	bge	a4,a5,1000026c <main+0x64>
10000280:	00168693          	addi	a3,a3,1
10000284:	fcc69ae3          	bne	a3,a2,10000258 <main+0x50>
10000288:	000107b7          	lui	a5,0x10
1000028c:	fff78793          	addi	a5,a5,-1 # ffff <_start-0xfff0001>
10000290:	30000737          	lui	a4,0x30000
10000294:	00f72023          	sw	a5,0(a4) # 30000000 <_ebss+0x1ffff23c>
10000298:	00012c23          	sw	zero,24(sp)
1000029c:	01812783          	lw	a5,24(sp)
100002a0:	00007737          	lui	a4,0x7
100002a4:	52f70713          	addi	a4,a4,1327 # 752f <_start-0xfff8ad1>
100002a8:	00f74c63          	blt	a4,a5,100002c0 <main+0xb8>
100002ac:	01812783          	lw	a5,24(sp)
100002b0:	00178793          	addi	a5,a5,1
100002b4:	00f12c23          	sw	a5,24(sp)
100002b8:	01812783          	lw	a5,24(sp)
100002bc:	fef758e3          	bge	a4,a5,100002ac <main+0xa4>
100002c0:	300007b7          	lui	a5,0x30000
100002c4:	10000537          	lui	a0,0x10000
100002c8:	0007a023          	sw	zero,0(a5) # 30000000 <_ebss+0x1ffff23c>
100002cc:	7c850513          	addi	a0,a0,1992 # 100007c8 <_etext+0x4>
100002d0:	d61ff0ef          	jal	10000030 <uart_puts>
100002d4:	10000b37          	lui	s6,0x10000
100002d8:	7d0b0513          	addi	a0,s6,2000 # 100007d0 <_etext+0xc>
100002dc:	d55ff0ef          	jal	10000030 <uart_puts>
100002e0:	10001537          	lui	a0,0x10001
100002e4:	80c50513          	addi	a0,a0,-2036 # 1000080c <_etext+0x48>
100002e8:	d49ff0ef          	jal	10000030 <uart_puts>
100002ec:	10001537          	lui	a0,0x10001
100002f0:	84850513          	addi	a0,a0,-1976 # 10000848 <_etext+0x84>
100002f4:	d3dff0ef          	jal	10000030 <uart_puts>
100002f8:	7d0b0513          	addi	a0,s6,2000
100002fc:	d35ff0ef          	jal	10000030 <uart_puts>
10000300:	10001537          	lui	a0,0x10001
10000304:	88450513          	addi	a0,a0,-1916 # 10000884 <_etext+0xc0>
10000308:	d29ff0ef          	jal	10000030 <uart_puts>
1000030c:	10001537          	lui	a0,0x10001
10000310:	8c050513          	addi	a0,a0,-1856 # 100008c0 <_etext+0xfc>
10000314:	d1dff0ef          	jal	10000030 <uart_puts>
10000318:	10001537          	lui	a0,0x10001
1000031c:	8fc50513          	addi	a0,a0,-1796 # 100008fc <_etext+0x138>
10000320:	d11ff0ef          	jal	10000030 <uart_puts>
10000324:	10001bb7          	lui	s7,0x10001
10000328:	938b8513          	addi	a0,s7,-1736 # 10000938 <_etext+0x174>
1000032c:	d05ff0ef          	jal	10000030 <uart_puts>
10000330:	10001537          	lui	a0,0x10001
10000334:	97850513          	addi	a0,a0,-1672 # 10000978 <_etext+0x1b4>
10000338:	cf9ff0ef          	jal	10000030 <uart_puts>
1000033c:	400007b7          	lui	a5,0x40000
10000340:	0007a483          	lw	s1,0(a5) # 40000000 <_ebss+0x2ffff23c>
10000344:	00012a23          	sw	zero,20(sp)
10000348:	01412783          	lw	a5,20(sp)
1000034c:	0000c737          	lui	a4,0xc
10000350:	34f70713          	addi	a4,a4,847 # c34f <_start-0xfff3cb1>
10000354:	00f74c63          	blt	a4,a5,1000036c <main+0x164>
10000358:	01412783          	lw	a5,20(sp)
1000035c:	00178793          	addi	a5,a5,1
10000360:	00f12a23          	sw	a5,20(sp)
10000364:	01412783          	lw	a5,20(sp)
10000368:	fef758e3          	bge	a4,a5,10000358 <main+0x150>
1000036c:	10001537          	lui	a0,0x10001
10000370:	400007b7          	lui	a5,0x40000
10000374:	9b450513          	addi	a0,a0,-1612 # 100009b4 <_etext+0x1f0>
10000378:	0007a403          	lw	s0,0(a5) # 40000000 <_ebss+0x2ffff23c>
1000037c:	cb5ff0ef          	jal	10000030 <uart_puts>
10000380:	00048513          	mv	a0,s1
10000384:	d05ff0ef          	jal	10000088 <uart_print_hex32>
10000388:	10001537          	lui	a0,0x10001
1000038c:	9cc50513          	addi	a0,a0,-1588 # 100009cc <_etext+0x208>
10000390:	ca1ff0ef          	jal	10000030 <uart_puts>
10000394:	00040513          	mv	a0,s0
10000398:	cf1ff0ef          	jal	10000088 <uart_print_hex32>
1000039c:	10001537          	lui	a0,0x10001
100003a0:	40940933          	sub	s2,s0,s1
100003a4:	9e850513          	addi	a0,a0,-1560 # 100009e8 <_etext+0x224>
100003a8:	c89ff0ef          	jal	10000030 <uart_puts>
100003ac:	3a090e63          	beqz	s2,10000768 <main+0x560>
100003b0:	00090513          	mv	a0,s2
100003b4:	db5ff0ef          	jal	10000168 <uart_print_dec.part.0>
100003b8:	10001537          	lui	a0,0x10001
100003bc:	a0450513          	addi	a0,a0,-1532 # 10000a04 <_etext+0x240>
100003c0:	c71ff0ef          	jal	10000030 <uart_puts>
100003c4:	10001537          	lui	a0,0x10001
100003c8:	a4850513          	addi	a0,a0,-1464 # 10000a48 <_etext+0x284>
100003cc:	c65ff0ef          	jal	10000030 <uart_puts>
100003d0:	10001537          	lui	a0,0x10001
100003d4:	a7c50513          	addi	a0,a0,-1412 # 10000a7c <_etext+0x2b8>
100003d8:	c59ff0ef          	jal	10000030 <uart_puts>
100003dc:	009896b7          	lui	a3,0x989
100003e0:	40000737          	lui	a4,0x40000
100003e4:	68068693          	addi	a3,a3,1664 # 989680 <_start-0xf676980>
100003e8:	00d72223          	sw	a3,4(a4) # 40000004 <_ebss+0x2ffff240>
100003ec:	00070793          	mv	a5,a4
100003f0:	00300713          	li	a4,3
100003f4:	00e7a423          	sw	a4,8(a5)
100003f8:	00012e23          	sw	zero,28(sp)
100003fc:	01c12783          	lw	a5,28(sp)
10000400:	00031737          	lui	a4,0x31
10000404:	d3f70713          	addi	a4,a4,-705 # 30d3f <_start-0xffcf2c1>
10000408:	00f74c63          	blt	a4,a5,10000420 <main+0x218>
1000040c:	01c12783          	lw	a5,28(sp)
10000410:	00178793          	addi	a5,a5,1
10000414:	00f12e23          	sw	a5,28(sp)
10000418:	01c12783          	lw	a5,28(sp)
1000041c:	fef758e3          	bge	a4,a5,1000040c <main+0x204>
10000420:	400004b7          	lui	s1,0x40000
10000424:	0084a403          	lw	s0,8(s1) # 40000008 <_ebss+0x2ffff244>
10000428:	10001537          	lui	a0,0x10001
1000042c:	ab850513          	addi	a0,a0,-1352 # 10000ab8 <_etext+0x2f4>
10000430:	c01ff0ef          	jal	10000030 <uart_puts>
10000434:	00040513          	mv	a0,s0
10000438:	00447413          	andi	s0,s0,4
1000043c:	00848493          	addi	s1,s1,8
10000440:	c49ff0ef          	jal	10000088 <uart_print_hex32>
10000444:	2e040263          	beqz	s0,10000728 <main+0x520>
10000448:	10001537          	lui	a0,0x10001
1000044c:	ad050513          	addi	a0,a0,-1328 # 10000ad0 <_etext+0x30c>
10000450:	be1ff0ef          	jal	10000030 <uart_puts>
10000454:	00300793          	li	a5,3
10000458:	00f4a023          	sw	a5,0(s1)
1000045c:	10001537          	lui	a0,0x10001
10000460:	b3850513          	addi	a0,a0,-1224 # 10000b38 <_etext+0x374>
10000464:	bcdff0ef          	jal	10000030 <uart_puts>
10000468:	10001537          	lui	a0,0x10001
1000046c:	b6c50513          	addi	a0,a0,-1172 # 10000b6c <_etext+0x3a8>
10000470:	bc1ff0ef          	jal	10000030 <uart_puts>
10000474:	500007b7          	lui	a5,0x50000
10000478:	00300713          	li	a4,3
1000047c:	10001537          	lui	a0,0x10001
10000480:	00e7a423          	sw	a4,8(a5) # 50000008 <_ebss+0x3ffff244>
10000484:	bac50513          	addi	a0,a0,-1108 # 10000bac <_etext+0x3e8>
10000488:	ba9ff0ef          	jal	10000030 <uart_puts>
1000048c:	000f47b7          	lui	a5,0xf4
10000490:	500006b7          	lui	a3,0x50000
10000494:	24078793          	addi	a5,a5,576 # f4240 <_start-0xff0bdc0>
10000498:	00468693          	addi	a3,a3,4 # 50000004 <_ebss+0x3ffff240>
1000049c:	0080006f          	j	100004a4 <main+0x29c>
100004a0:	28078c63          	beqz	a5,10000738 <main+0x530>
100004a4:	0006a403          	lw	s0,0(a3)
100004a8:	fff78793          	addi	a5,a5,-1
100004ac:	01047713          	andi	a4,s0,16
100004b0:	fe0708e3          	beqz	a4,100004a0 <main+0x298>
100004b4:	10001537          	lui	a0,0x10001
100004b8:	bdc50513          	addi	a0,a0,-1060 # 10000bdc <_etext+0x418>
100004bc:	b75ff0ef          	jal	10000030 <uart_puts>
100004c0:	00040513          	mv	a0,s0
100004c4:	bc5ff0ef          	jal	10000088 <uart_print_hex32>
100004c8:	10001ab7          	lui	s5,0x10001
100004cc:	bf0a8513          	addi	a0,s5,-1040 # 10000bf0 <_etext+0x42c>
100004d0:	b61ff0ef          	jal	10000030 <uart_puts>
100004d4:	10001537          	lui	a0,0x10001
100004d8:	bf450513          	addi	a0,a0,-1036 # 10000bf4 <_etext+0x430>
100004dc:	b55ff0ef          	jal	10000030 <uart_puts>
100004e0:	00247793          	andi	a5,s0,2
100004e4:	2c079063          	bnez	a5,100007a4 <main+0x59c>
100004e8:	10001537          	lui	a0,0x10001
100004ec:	c9050513          	addi	a0,a0,-880 # 10000c90 <_etext+0x4cc>
100004f0:	50000c37          	lui	s8,0x50000
100004f4:	b3dff0ef          	jal	10000030 <uart_puts>
100004f8:	004c0c13          	addi	s8,s8,4 # 50000004 <_ebss+0x3ffff240>
100004fc:	00100413          	li	s0,1
10000500:	10001a37          	lui	s4,0x10001
10000504:	100019b7          	lui	s3,0x10001
10000508:	50000937          	lui	s2,0x50000
1000050c:	00600493          	li	s1,6
10000510:	0007a737          	lui	a4,0x7a
10000514:	12070713          	addi	a4,a4,288 # 7a120 <_start-0xff85ee0>
10000518:	0080006f          	j	10000520 <main+0x318>
1000051c:	00070a63          	beqz	a4,10000530 <main+0x328>
10000520:	000c2783          	lw	a5,0(s8)
10000524:	fff70713          	addi	a4,a4,-1
10000528:	0017f793          	andi	a5,a5,1
1000052c:	fe0788e3          	beqz	a5,1000051c <main+0x314>
10000530:	cb0a0513          	addi	a0,s4,-848 # 10000cb0 <_etext+0x4ec>
10000534:	00092c83          	lw	s9,0(s2) # 50000000 <_ebss+0x3ffff23c>
10000538:	af9ff0ef          	jal	10000030 <uart_puts>
1000053c:	00040513          	mv	a0,s0
10000540:	c29ff0ef          	jal	10000168 <uart_print_dec.part.0>
10000544:	cc498513          	addi	a0,s3,-828 # 10000cc4 <_etext+0x500>
10000548:	ae9ff0ef          	jal	10000030 <uart_puts>
1000054c:	000c8513          	mv	a0,s9
10000550:	b39ff0ef          	jal	10000088 <uart_print_hex32>
10000554:	bf0a8513          	addi	a0,s5,-1040
10000558:	00140413          	addi	s0,s0,1
1000055c:	ad5ff0ef          	jal	10000030 <uart_puts>
10000560:	fa9418e3          	bne	s0,s1,10000510 <main+0x308>
10000564:	10001537          	lui	a0,0x10001
10000568:	cc850513          	addi	a0,a0,-824 # 10000cc8 <_etext+0x504>
1000056c:	ac5ff0ef          	jal	10000030 <uart_puts>
10000570:	7d0b0513          	addi	a0,s6,2000
10000574:	abdff0ef          	jal	10000030 <uart_puts>
10000578:	10001537          	lui	a0,0x10001
1000057c:	cf850513          	addi	a0,a0,-776 # 10000cf8 <_etext+0x534>
10000580:	ab1ff0ef          	jal	10000030 <uart_puts>
10000584:	10001537          	lui	a0,0x10001
10000588:	d3450513          	addi	a0,a0,-716 # 10000d34 <_etext+0x570>
1000058c:	aa5ff0ef          	jal	10000030 <uart_puts>
10000590:	938b8513          	addi	a0,s7,-1736
10000594:	a9dff0ef          	jal	10000030 <uart_puts>
10000598:	20000737          	lui	a4,0x20000
1000059c:	50000b37          	lui	s6,0x50000
100005a0:	004b0b13          	addi	s6,s6,4 # 50000004 <_ebss+0x3ffff240>
100005a4:	00470b93          	addi	s7,a4,4 # 20000004 <_ebss+0xffff240>
100005a8:	00000413          	li	s0,0
100005ac:	10001db7          	lui	s11,0x10001
100005b0:	10001d37          	lui	s10,0x10001
100005b4:	10001cb7          	lui	s9,0x10001
100005b8:	10001c37          	lui	s8,0x10001
100005bc:	00070a13          	mv	s4,a4
100005c0:	400007b7          	lui	a5,0x40000
100005c4:	0007a983          	lw	s3,0(a5) # 40000000 <_ebss+0x2ffff23c>
100005c8:	000b2783          	lw	a5,0(s6)
100005cc:	00140413          	addi	s0,s0,1
100005d0:	0017f793          	andi	a5,a5,1
100005d4:	14078263          	beqz	a5,10000718 <main+0x510>
100005d8:	500007b7          	lui	a5,0x50000
100005dc:	0007a903          	lw	s2,0(a5) # 50000000 <_ebss+0x3ffff23c>
100005e0:	12090c63          	beqz	s2,10000718 <main+0x510>
100005e4:	01091493          	slli	s1,s2,0x10
100005e8:	0104d493          	srli	s1,s1,0x10
100005ec:	300007b7          	lui	a5,0x30000
100005f0:	0097a023          	sw	s1,0(a5) # 30000000 <_ebss+0x1ffff23c>
100005f4:	d70d8513          	addi	a0,s11,-656 # 10000d70 <_etext+0x5ac>
100005f8:	a39ff0ef          	jal	10000030 <uart_puts>
100005fc:	0e040263          	beqz	s0,100006e0 <main+0x4d8>
10000600:	00040513          	mv	a0,s0
10000604:	b65ff0ef          	jal	10000168 <uart_print_dec.part.0>
10000608:	d7cd0513          	addi	a0,s10,-644 # 10000d7c <_etext+0x5b8>
1000060c:	a25ff0ef          	jal	10000030 <uart_puts>
10000610:	0e098863          	beqz	s3,10000700 <main+0x4f8>
10000614:	00098513          	mv	a0,s3
10000618:	b51ff0ef          	jal	10000168 <uart_print_dec.part.0>
1000061c:	d88c8513          	addi	a0,s9,-632 # 10000d88 <_etext+0x5c4>
10000620:	a11ff0ef          	jal	10000030 <uart_puts>
10000624:	00090513          	mv	a0,s2
10000628:	a61ff0ef          	jal	10000088 <uart_print_hex32>
1000062c:	d94c0513          	addi	a0,s8,-620 # 10000d94 <_etext+0x5d0>
10000630:	a01ff0ef          	jal	10000030 <uart_puts>
10000634:	00048513          	mv	a0,s1
10000638:	ac1ff0ef          	jal	100000f8 <uart_print_hex16>
1000063c:	bf0a8513          	addi	a0,s5,-1040
10000640:	9f1ff0ef          	jal	10000030 <uart_puts>
10000644:	00012623          	sw	zero,12(sp)
10000648:	00c12683          	lw	a3,12(sp)
1000064c:	000497b7          	lui	a5,0x49
10000650:	3df78793          	addi	a5,a5,991 # 493df <_start-0xffb6c21>
10000654:	f6d7c6e3          	blt	a5,a3,100005c0 <main+0x3b8>
10000658:	00078913          	mv	s2,a5
1000065c:	000ba783          	lw	a5,0(s7)
10000660:	0027f793          	andi	a5,a5,2
10000664:	02079263          	bnez	a5,10000688 <main+0x480>
10000668:	00c12783          	lw	a5,12(sp)
1000066c:	00178793          	addi	a5,a5,1
10000670:	00f12623          	sw	a5,12(sp)
10000674:	00c12783          	lw	a5,12(sp)
10000678:	f4f944e3          	blt	s2,a5,100005c0 <main+0x3b8>
1000067c:	000ba783          	lw	a5,0(s7)
10000680:	0027f793          	andi	a5,a5,2
10000684:	fe0782e3          	beqz	a5,10000668 <main+0x460>
10000688:	000ba783          	lw	a5,0(s7)
1000068c:	0027f793          	andi	a5,a5,2
10000690:	fe078ce3          	beqz	a5,10000688 <main+0x480>
10000694:	000a2983          	lw	s3,0(s4)
10000698:	100017b7          	lui	a5,0x10001
1000069c:	da078513          	addi	a0,a5,-608 # 10000da0 <_etext+0x5dc>
100006a0:	0ff9f493          	zext.b	s1,s3
100006a4:	98dff0ef          	jal	10000030 <uart_puts>
100006a8:	000ba783          	lw	a5,0(s7)
100006ac:	0017f793          	andi	a5,a5,1
100006b0:	fe079ce3          	bnez	a5,100006a8 <main+0x4a0>
100006b4:	100017b7          	lui	a5,0x10001
100006b8:	0ff9f993          	zext.b	s3,s3
100006bc:	db878513          	addi	a0,a5,-584 # 10000db8 <_etext+0x5f4>
100006c0:	013a2023          	sw	s3,0(s4)
100006c4:	96dff0ef          	jal	10000030 <uart_puts>
100006c8:	00048513          	mv	a0,s1
100006cc:	a2dff0ef          	jal	100000f8 <uart_print_hex16>
100006d0:	100017b7          	lui	a5,0x10001
100006d4:	dc078513          	addi	a0,a5,-576 # 10000dc0 <_etext+0x5fc>
100006d8:	959ff0ef          	jal	10000030 <uart_puts>
100006dc:	f8dff06f          	j	10000668 <main+0x460>
100006e0:	000ba783          	lw	a5,0(s7)
100006e4:	0017f793          	andi	a5,a5,1
100006e8:	fe079ce3          	bnez	a5,100006e0 <main+0x4d8>
100006ec:	03000793          	li	a5,48
100006f0:	00fa2023          	sw	a5,0(s4)
100006f4:	d7cd0513          	addi	a0,s10,-644
100006f8:	939ff0ef          	jal	10000030 <uart_puts>
100006fc:	f0099ce3          	bnez	s3,10000614 <main+0x40c>
10000700:	000ba783          	lw	a5,0(s7)
10000704:	0017f793          	andi	a5,a5,1
10000708:	fe079ce3          	bnez	a5,10000700 <main+0x4f8>
1000070c:	03000793          	li	a5,48
10000710:	00fa2023          	sw	a5,0(s4)
10000714:	f09ff06f          	j	1000061c <main+0x414>
10000718:	01041493          	slli	s1,s0,0x10
1000071c:	0104d493          	srli	s1,s1,0x10
10000720:	00000913          	li	s2,0
10000724:	ec9ff06f          	j	100005ec <main+0x3e4>
10000728:	10001537          	lui	a0,0x10001
1000072c:	b1450513          	addi	a0,a0,-1260 # 10000b14 <_etext+0x350>
10000730:	901ff0ef          	jal	10000030 <uart_puts>
10000734:	d29ff06f          	j	1000045c <main+0x254>
10000738:	10001537          	lui	a0,0x10001
1000073c:	bdc50513          	addi	a0,a0,-1060 # 10000bdc <_etext+0x418>
10000740:	8f1ff0ef          	jal	10000030 <uart_puts>
10000744:	00040513          	mv	a0,s0
10000748:	941ff0ef          	jal	10000088 <uart_print_hex32>
1000074c:	10001ab7          	lui	s5,0x10001
10000750:	bf0a8513          	addi	a0,s5,-1040 # 10000bf0 <_etext+0x42c>
10000754:	8ddff0ef          	jal	10000030 <uart_puts>
10000758:	10001537          	lui	a0,0x10001
1000075c:	c2450513          	addi	a0,a0,-988 # 10000c24 <_etext+0x460>
10000760:	8d1ff0ef          	jal	10000030 <uart_puts>
10000764:	d7dff06f          	j	100004e0 <main+0x2d8>
10000768:	20000737          	lui	a4,0x20000
1000076c:	00470713          	addi	a4,a4,4 # 20000004 <_ebss+0xffff240>
10000770:	200006b7          	lui	a3,0x20000
10000774:	00072783          	lw	a5,0(a4)
10000778:	0017f793          	andi	a5,a5,1
1000077c:	fe079ce3          	bnez	a5,10000774 <main+0x56c>
10000780:	03000793          	li	a5,48
10000784:	10001537          	lui	a0,0x10001
10000788:	00f6a023          	sw	a5,0(a3) # 20000000 <_ebss+0xffff23c>
1000078c:	a0450513          	addi	a0,a0,-1532 # 10000a04 <_etext+0x240>
10000790:	8a1ff0ef          	jal	10000030 <uart_puts>
10000794:	10001537          	lui	a0,0x10001
10000798:	a1050513          	addi	a0,a0,-1520 # 10000a10 <_etext+0x24c>
1000079c:	895ff0ef          	jal	10000030 <uart_puts>
100007a0:	c31ff06f          	j	100003d0 <main+0x1c8>
100007a4:	10001537          	lui	a0,0x10001
100007a8:	c5850513          	addi	a0,a0,-936 # 10000c58 <_etext+0x494>
100007ac:	885ff0ef          	jal	10000030 <uart_puts>
100007b0:	00040513          	mv	a0,s0
100007b4:	8d5ff0ef          	jal	10000088 <uart_print_hex32>
100007b8:	bf0a8513          	addi	a0,s5,-1040
100007bc:	875ff0ef          	jal	10000030 <uart_puts>
100007c0:	d29ff06f          	j	100004e8 <main+0x2e0>
