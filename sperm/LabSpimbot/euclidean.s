.data
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0
	
.text

# -----------------------------------------------------------------------
# sb_arctan - computes the arctangent of y / x
# $a0 - x
# $a1 - y
# returns the arctangent
# -----------------------------------------------------------------------

sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90	  

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;      
	move	$a0, $t0	# x = temp;    
	li	$v0, 90		# angle = 90;  

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0) 
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1
	
	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 5.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 3.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra
	

# -----------------------------------------------------------------------
# euclidean_dist - computes sqrt(x^2 + y^2)
# $a0 - x
# $a1 - y
# returns the distance
# -----------------------------------------------------------------------

euclidean_dist:
	mul	$a0, $a0, $a0	# x^2
	mul	$a1, $a1, $a1	# y^2
	add	$v0, $a0, $a1	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0
	jr	$ra


# -----------------------------------------------------------------------
# Test code for Arctangent infinite series approximation example
# -----------------------------------------------------------------------

# This test code calls the sb_arctan code with some constants.  With
# an X value that is twice the Y value, the approximate algorithm
# computes 26 degrees (an exact algorithm would have gotten 26.56
# degrees).

.data
thirty:	 .word 30
sixty:	 .word 60
hundred: .word 100
endl:	 .asciiz "\n"
xequals: .asciiz "x="
yequals: .asciiz ", y="
expect:	.asciiz ".  Expected: "
yougot:	.asciiz ", got: "
ystring:
	.word	30	52	30	5	-2	-170	-35	0
xstring:
	.word	60	30	-30	-30	-30	-30	30	30
answers:
	.word	26	60	131	171	183	260	312	0

PRINT_INT = 0xffff0080

.text
main:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)		# save return address on stack

	li	$s0, 0
testloop:				# calls user procedure eight times, twice for each quadrant
	move	$a0, $s0
	jal	test2
	add	$s0, $s0, 1
	bne	$s0, 8, testloop

	jal	test_euclidean_dist

	lw	$ra, 0($sp)		# restore return address
	add	$sp, $sp, 4		# fixup stack
	jr	$ra			# return

test2:
	sub	$sp, $sp, 12	#calling conventions
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	mul	$t0, $a0, 4	#calculate argument array offset
	
	la	$t2, xstring
	add	$t2, $t2, $t0
	lw	$s0, 0($t2)	#load x
	
	la	$t2, ystring
	add	$t2, $t2, $t0
	lw	$s1, 0($t2)	#load y
	
	la	$a0, xequals	#print "x="
	li	$v0, 4
	syscall

	move	$a0, $s0	#print x
	li	$v0, 1
	syscall
	
	la	$a0, yequals	#print "y="
	li	$v0, 4
	syscall

	move	$a0, $s1	#print y
	li	$v0, 1
	syscall
	
	la	$a0, expect	
	li	$v0, 4
	syscall

	la	$t2, answers	#print reference answer
	add	$t2, $t2, $t0
	lw	$a0, 0($t2)
	li	$v0, 1
	syscall
		
	la	$a0, yougot
	li	$v0, 4
	syscall

	move	$a0, $s0	#call user procedure
	move	$a1, $s1
	jal	sb_arctan
	move	$a0, $v0
	li	$v0, 1
	syscall			#print calculated answer
	
	la	$a0, endl	#print newline
	li	$v0, 4
	syscall
	
	lw	$s0, 4($sp)	#restore stack
	lw	$ra, 0($sp)
	add	$sp, $sp, 12
	jr	$ra

test_euclidean_dist:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)

	li	$a0, 3
	li	$a1, 4
	jal	euclidean_dist
	sw	$v0, PRINT_INT	# should print 5

	li	$a0, -5
	li	$a1, -12
	jal	euclidean_dist
	sw	$v0, PRINT_INT	# should print 13

	li	$a0, 32
	li	$a1, -64
	jal	euclidean_dist
	sw	$v0, PRINT_INT	# should print 71

	li	$a0, -150
	li	$a1, 150
	jal	euclidean_dist
	sw	$v0, PRINT_INT	# should print 212

	lw	$ra, 0($sp)
	jr	$ra
