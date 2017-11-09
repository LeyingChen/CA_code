#include <asm.h>
#include <regdef.h>
#include <ucas_cde.h>

#define TEST_NUM 68

##s0, number
##s1, number adress 
##s2, exception use
##s3, score

	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
	j	locate
	nop

##avoid "j locate" not taken
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
    nop

##avoid cpu run error
.org 0x0ec
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
.org 0x100
test_finish:
    addiu t0, t0, 1
    b test_finish
    nop
##avoid cpu run error
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
/*
 *  exception handle
 */
.org 0x380
1:  
    mtc0  zero, $9    
    mfc0  k0, $13

    andi  k1, k0, 0x4000
    bnez  k1, set_int
    nop
    andi  k1, k0, 0x2000
    bnez  k1, sec_int
    nop
    andi  k1, k0, 0x1000
    bnez  k1, min_int
    nop
    andi  k1, k0, 0x0800
    bnez  k1, hour_int
    nop
    andi  k1, k0, 0x8000
    bnez  k1, clk_int
    nop
    
    .set mips32
    ERET
    .set mips0

set_int:

    li    t7, 6000000
10:
    addi  t7, t7, -1
    bnez  t7, 10b
    nop

    bnez  s6, set_ret
    nop
    addi  s6, s6, 1

    li    t0, 0x10407801
    mtc0  t0, $12
2: 
    nop
    nop
    nop
    b 2b
    nop

set_ret:
    li    s6, 0
    li    t0, 0x1040c001
    mtc0  t0, $12
    
    .set mips32
    ERET
    .set mips0
    
    
sec_int:
    li    t7, 6000000
10:
    addi  t7, t7, -1
    bnez  t7, 10b
    nop

    LI (s1, NUM_ADDR)
    lw  t0, 0(s1)
    andi  t1, t0, 0x000000ff   #sec
    li    t3, 0xffffff00
    and   t0, t0, t3
    
    li    t7, 1000


    addi  t1, t1, 1            #sec+1
    andi  t4, t1, 0x000f   #fetch last 4 bits
    li    t5, 0x0a         #if "a", carryout, +6
    bne   t4, t5, 3f               
    nop
    addi  t1, t1, 0x6 
    
3:   
    li    t6, 0x60             #sec60->0
    bne   t1, t6, fix_ret
    nop          
    li    t1, 0x0

fix_ret:
    or    t0, t0, t1
    sw    t0, 0(s1)
    .set mips32
    ERET
    .set mips0
    
min_int:
    li    t7, 6000000
10:
    addi  t7, t7, -1
    bnez  t7, 10b
    nop
 
   LI (s1, NUM_ADDR)
    lw  t0, 0(s1)
    andi  t1, t0, 0x00ff00   #min
    li    t3, 0xffff00ff
    and   t0, t0, t3

    addi  t1, t1, 0x0100        #min+1
    andi  t4, t1, 0x0f00   #fetch min's last 4 bits
    li    t5, 0x0a00       #if "a", carryout, +6
    bne   t4, t5, 5f               
    nop
    addi  t1, t1, 0x600 
    
5:   
    li    t6, 0x6000             #min60->0
    bne   t1, t6, fix_ret
    nop          
    li    t1, 0x0
    b     fix_ret
    nop

hour_int:   
    li    t7, 6000000
10:
    addi  t7, t7, -1
    bnez  t7, 10b
    nop

    LI (s1, NUM_ADDR)
    lw    t0, 0(s1)
    lui   t5, 0x00ff
    and   t1, t0, t5
    li    t3, 0xff00ffff
    and   t0, t0, t3

#    addi  t1, t1, 0x00010000      #hour+1
    li    t5, 0x0
    lui   t5, 0x0001
    add   t1, t1, t5
#    andi  t4, t1, 0x000f0000   #fetch hour's last 4 bits
    li    t5, 0x0
    lui   t5, 0x000f
    and   t4, t1, t5    
#    xori  t4, t4, 0x000a0000     #if "a", carryout, +6
    li    t5, 0x0
    lui   t5, 0x000a
    xor   t4, t4, t5
    
    bnez  t4, 6f
    nop               
    li    t5, 0x0
    lui   t5, 0x0006
    add   t1, t1, t5
    
6:   
    li    t6, 0x240000             #hour24->0
    bne   t1, t6, fix_ret
    nop          
    li    t1, 0x0
    b     fix_ret
    nop

clk_int:
    LI (s1, NUM_ADDR)
    lw  t0, 0(s1)
    andi  t1, t0, 0x000000ff   #sec
    andi  t2, t0, 0x0000ff00   #min
#    andi  t3, t0, 0x00ff0000   #hour
    lui   t5, 0x00ff
    and   t3, t0, t5

    addi  t1, t1, 1            #sec+1
    andi  t4, t1, 0x000f   #fetch last 4 bits
    li    t5, 0x0a         #if "a", carryout, +6
    bne   t4, t5, 2f               
    nop
    addi  t1, t1, 0x6 

2:
    li    t6, 0x60             #sec->min
    bne   t1, t6, 3f
    nop          
    li    t1, 0x0
    addi  t2, t2, 0x0100        #min+1
    andi  t4, t2, 0x0f00   #fetch min's last 4 bits
    li    t5, 0x0a00       #if "a", carryout, +6
    bne   t4, t5, 4f               
    nop
    addi  t2, t2, 0x600 

4:
    LI    t6, 0x6000           #min->hour
    bne   t2, t6, 3f          
    nop
    li    t2, 0x0
    li    t5, 0x0
    lui   t5, 0x0001
    add   t3, t3, t5
    li    t5, 0x0
    lui   t5, 0x000f
    and   t4, t3, t5    
    li    t5, 0x0
    lui   t5, 0x000a
    xor   t4, t4, t5
    
    bnez  t4, 5f
    nop               
    li    t5, 0x0
    lui   t5, 0x0006
    add   t3, t3, t5
    

5:
    li    t6, 0x240000
    bne   t3, t6, 3f 
    nop         
    li    t3, 0x0

3:
    or    t1, t1, t2           #write num_data
    or    t1, t1, t3
    sw    t1, 0(s1)

    li    t0, 25000000             #clear interrupt
    mtc0  t0, $11
#    mtc0  zero, $9    
    .set mips32
    ERET
    .set mips0

locate:
	.set noreorder
    
    LI (t1, 0x0002)
    LI (t0, LED_RG1_ADDR)
    sw t1, 0(t0)

    LI (t1, 0x0001)
    LI (t0, LED_RG0_ADDR)
    sw t1, 0(t0)

    LI (t1, 0x0000ffff)
    LI (t0, LED_ADDR)
    sw t1, 0(t0)

    LI (s1, NUM_ADDR)
    li s3, 0x0
    sw s3, 0(s1)
    
    li    s6, 0x0
    li    t1, 25000000
    mtc0  t1, $11
    mtc0  zero, $9

    li   t0, 0x1040c001
    mtc0  t0, $12 

1: 
    nop
    nop
    nop
    b 1b
    nop
