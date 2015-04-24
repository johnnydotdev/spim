.data
.align 2
planet_data: 	.space 32
scan_data: 	.space 256
extra_space: 	.space 32  
lexicon:	.space 4096
puzzle: 	.space 10000
num_rows: 	.space 4
num_columns: 	.space 4
solution: 	.space 804
energy_flag:	.space 4
field_count:	.space 4
test_str:	.asciiz "PRINT solution\n"
horiz_strncmp_str: .asciiz "In horiz_strncmp\n"
#puzzle: 	.space 4
# movement memory-mapped I/O
VELOCITY            = 0xffff0010
ANGLE               = 0xffff0014
ANGLE_CONTROL       = 0xffff0018
PRINT_STRING	    = 4
# coordinates memory-mapped I/O
BOT_X               = 0xffff0020
BOT_Y               = 0xffff0024
# planet memory-mapped I/O
PLANETS_REQUEST     = 0xffff1014
# scanning memory-mapped I/O
SCAN_REQUEST        = 0xffff1010
SCAN_SECTOR         = 0xffff101c
# gravity memory-mapped I/O
FIELD_STRENGTH      = 0xffff1100
# bot info memory-mapped I/O
SCORES_REQUEST      = 0xffff1018
ENERGY              = 0xffff1104
# debugging memory-mapped I/O
PRINT_INT           = 0xffff0080
# interrupt constants
SCAN_MASK           = 0x2000
SCAN_ACKNOWLEDGE    = 0xffff1204
ENERGY_MASK         = 0x4000
ENERGY_ACKNOWLEDGE  = 0xffff1208  
GET_ENERGY 	=   0xffff1104
SPIMBOT_GET_FIELD_CNT  = 0xffff110c  #store that location into SPIMBOT_GET_FIELD_CNT
# puzzle interface locations 
SPIMBOT_PUZZLE_REQUEST 	= 0xffff1000 
SPIMBOT_SOLVE_REQUEST 	= 0xffff1004 
SPIMBOT_LEXICON_REQUEST = 0xffff1008 
# I/O used in competitive scenario 
INTERFERENCE_MASK = 0x0400 
INTERFERENCE_ACK = 0xffff1304 
SPACESHIP_FIELD_CNT = 0xffff110c 
BONK_MASK = 0x1000
BONK_ACK  = 0xffff0060
TIMER 	 = 0xffff001c
TIMER_MASK = 0x8000
TIMER_ACK = 0xffff006c
# Constant values
CHASE_ITERATIONS = 2048
.text
main:
	# your code goes here
	# for the interrupt-related portions, you'll want to
	# refer closely to example.s - it's probably easiest
	# to copy-paste the relevant portions and then modify them
	# keep in mind that example.s has bugs, as discussed in section
#	lw 	$t1, GET_ENERGY
 #	sw 	$t1, PRINT_INT
 	la 	$t1, energy_flag
 	sw 	$zero, 0($t1)
	li	$t4, SCAN_MASK			# scan interrupt enable bit
	or	$t4, $t4, TIMER_MASK    	# timer interrupt enable bit
	or	$t4, $t4, BONK_MASK		# bonk interrupt enable bit
	or  	$t4, $t4, ENERGY_MASK		# energy interrupt enable bit
	or	$t4, $t4, INTERFERENCE_MASK	# interference mask enable bit (is sent if two bots are intersecting each others fields)
	or  	$t4, $t4, 1			# global interrupt enable
	mtc0	$t4, $12			# set interrupt mask (Status register)	
	li	$a0, 0 				# store velocity 0 into VELOCITY
	sw 	$a0, VELOCITY			# drive
	la	$t0, planet_data 		# load planet's data into $t0
	sw	$t0, PLANETS_REQUEST
restart:
	# lw 	$t1, GET_ENERGY
 # 	sw 	$t1, PRINT_INT
 	# lw 	$t1, GET_ENERGY
 	# bge 	$t1, 40, done_loop




	li	$t2, 0    			# counter
	la	$t1, scan_data			# load scan data
	li      $t5, 0 				# load 0 for flag for scanning
	la	$t3, extra_space		
	sw      $t5, 4($t3)			# store 0 for flag
scan_loop:
	la	$t3, extra_space		
	beq     $t2, 64, infinite		# if scanned all 64 then move on to next process
	li	$t4, 0 				# set flag to 0 again
	sw      $t4, 0($t3)
	sw  	$t2, SCAN_SECTOR		# get next scan 
	sw	$t1, SCAN_REQUEST
	j       loop
loop:
	la	$t3, extra_space
	lw      $t5, 0($t3)	       		# loads flag from extra space
	beq     $t5, 1, scan_loop2		# if flag is then has not finished scanning
	j       loop 				# do a busy wait
scan_loop2:
	la	$t3, extra_space
	mul     $t7, $t2, 4     		# index*4 to get scan_data at particular point
	add     $t7, $t7, $t1			# scan_data = scan_data + 4*index
	lw      $t5, 0($t7)     		# value at scan data
	lw	$t3, 4($t3)     		# max value is loaded
	bge	$t5, $t3, setmax 		# compares scan data value and max data
scan_loop3: 
	add     $t2, $t2, 1     		# increment index 
	j       scan_loop
setmax:
	la	$t6, extra_space
	move    $t3, $t5
	sw      $t3, 4($t6)   			# stores max number of particles
	sw      $t2, 8($t6)   			# stores max index
	j       scan_loop3
infinite:					# used to calculate coordinate of dust
	la	$t6, extra_space
	la      $t1, extra_space
	lw	$t1, 8($t1)
	move    $t3, $t1
	li      $t4, 8 				# since each row has 8 sectors
	div     $t3, $t4 			# divide the max index by 8 to get location
	mflo	$t3       			# y index
	mfhi    $t4		  		# x index
	mul     $t1, $t4, 38  			# dust coordinates x
	mul     $t2, $t3, 38  			# dust coordinates y
	add 	$t2, $t2, 19
	add	$t1, $t1, 19
	sw      $t1, 20($t6) 			# store dust coordinates in extra_space
	sw 	$t2, 24($t6)	
	li	$a0, 10
	sw	$a0, VELOCITY		# drive
loop_move:
	lw	$t3, BOT_X		#get the BOT's x coordinate
	lw	$t4, BOT_Y 		#get the BOT's y coordinate
	la 	$t6, extra_space
	lw 	$t1, 20($t6)
	lw 	$t2, 24($t6)		# load some shit regarding dust particles
	sub     $t5, $t3, $t1		# x - dust_x
	mul	$t5, $t5, $t5		# x^2
	sub     $t6, $t4, $t2		# y - dust_y
	mul	$t6, $t6, $t6		# y^2
	add	$v0, $t6, $t5		# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0		# float(x^2 + y^2)
	sqrt.s	$f0, $f0		# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0		# int(sqrt(...))
	mfc1	$v0, $f0	
	move 	$t0, $v0
	bne 	$t0, 0, x_loop	 		
	j 	done_moving
#t3 holds bot_x and t4 holds bot_y. t1 holds dust x and t2 hold dust y
#if(dust_x< bot_x)
#	if(dust_y<bot_y)
#		angle = 225
#	else
#		angle = 135
#if(dust_x>bot_x)
#	if(dust_y>bot_y)
#		angle = 45
#	else
#		angle = 315
x_loop:
	lw	$t3, BOT_X		
	bgt	$t1, $t3, moveright 
	bgt	$t2, $t4, moveup
	li	$t5, 225			#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1				#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
moveup:
	li	$t5, 135		#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
moveright:
	lw	$t4, BOT_Y
	beq	$t4, $t2, loop_move	#checks if(p_y == y), then go back to loop?
	blt	$t2, $t4, movedown
	li	$t5, 45		#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
movedown:
	li	$t5, 315			#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
done_moving:
	li      $t5, 4
	sw      $t5, FIELD_STRENGTH	
	li	$t0, 1
	sw	$t0, VELOCITY		# drive
	li 	$t5, 3
	sw 	$t5, FIELD_STRENGTH
	li 	$t0, 3
	sw 	$t0, VELOCITY

planet_loop:
	li 	$a0, 0
	jal 	align_planet
	li 	$a0, 1
	jal 	align_planet

	la 	$t0, planet_data
	sw 	$t0, PLANETS_REQUEST

	# if not aligne3d in x
	lw 	$t1, 0($t0)
	lw 	$t2, BOT_X
	bne 	$t1, $t2, planet_loop

	# if not aligned in y
	lw 	$t1, 4($t0)
	lw 	$t2, BOT_Y
	bne 	$t1, $t2, planet_loop

	add 	$s0, $s0, 1
	blt	$s0, CHASE_ITERATIONS, planet_loop

	li      $t5, 0
	sw      $t5, FIELD_STRENGTH	

# energy_check:
 
# la	$t0, planet_data
# 	sw	$t0, PLANETS_REQUEST
# 	la 	$t0, planet_data	#load address of planet_request into $t0
# 	lw	$t3, 0($t0)		#loads the planet X coord
# 	lw	$t4, 4($t0)		#loads the planet Y coord
# 	lw	$t1, BOT_X
# 	lw	$t2, BOT_Y
# 	sub     $t5, $t3, $t1
# 	mul	$t5, $t5, $t5	# x^2
# 	sub     $t6, $t4, $t2
# 	mul	$t6, $t6, $t6	# y^2
# 	add	$v0, $t6, $t5	# x^2 + y^2
# 	mtc1	$v0, $f0
# 	cvt.s.w	$f0, $f0		# float(x^2 + y^2)
# 	sqrt.s	$f0, $f0		# sqrt(x^2 + y^2)
# 	cvt.w.s	$f0, $f0		# int(sqrt(...))
# 	mfc1	$v0, $f0	
# 	move 	$t0, $v0
# 	la 	$t1, puzzle
# 	sw	$t1, SPIMBOT_PUZZLE_REQUEST
# 	la 	$t1, puzzle
# 	lw 	$t2, 0($t1)		#contains num_rows
# 	la 	$t5, num_rows
# 	sw 	$t2, 0($t5)		#store num_rows
# 	lw	$t2, 4($t1)		#contains num_columns
# 	la 	$t5, num_columns
# 	sw 	$t2, 0($t5)		#store num_columns

# 	la 	$t1, lexicon
# 	sw 	$t1, SPIMBOT_LEXICON_REQUEST
# 	lw 	$a1, 0($t1)		#load word into a1 the lexicon_size
# 	add 	$t1, $t1, 4
# 	move	$a0, $t1		#load the char ** dictionary)
# 	jal 	find_words
# #	lw 	$t1, GET_ENERGY
# #	sw 	$t1, PRINT_INT
# solver:
# 	la 	$t1, solution
# 	sw 	$t1, SPIMBOT_SOLVE_REQUEST
# #	lw 	$t1, GET_ENERGY
#  #	sw 	$t1, PRINT_INT
# #	lw 	$t1, solution_count
# #	sw 	$t1, PRINT_INT
# 	move 	$t2, $zero
# # print_loop:
# # 	bge	$t2, $t1, done_loop
# # 	li	$v0, PRINT_STRING			# Unhandled interrupt types
# # 	la	$a0, test_str
# # 	la 	$t3, solution_arr
# # 	mul	$t4, $t2, 8
# # 	add 	$t4, $t4, $t3
# # 	lw 	$t1, 0($t4)
# # 	sw 	$t1, PRINT_INT
# # 	lw 	$t1, 4($t4)
# # 	sw 	$t1, PRINT_INT
# # 	add 	$t2, $t2, 1
# # 	j 	print_loop
# done_loop:
# 	la 	$t1, solution 		#reste solution here
# 	sw 	$zero, 0($t1) 


# no_energy_interrupt:
	
# 	done_can_field_strength:
# 	li 	$t0, 2
# 	sw 	$t0, FIELD_STRENGTH
#I'm going to implememtn a check to see if I'm too close to the planenet to start with, then I'll wait it to come back the next time

move_towards_orbital:
	
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t7, 8($t0)		#loads the planet's orbital radius
	#lw	$t3, 0($t0)		#holds x coordinate of the my planet
	#lw	$t4, 4($t0)		#hollds y coordinate of my planet
	li	$t3, 150 		#load x and y coord with that of the sun (center)
	li 	$t4, 150
	lw	$t1, BOT_X
	lw	$t2, BOT_Y
	sub     $t5, $t3, $t1
	mul	$t5, $t5, $t5	# x^2
	sub     $t6, $t4, $t2
	mul	$t6, $t6, $t6	# y^2
	add	$v0, $t6, $t5	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0	
	move 	$t0, $v0
#t0 now contains the eucledian distance
#if the distance != orbital radius, I am going to move towards the orbital radius point. 
	
	ble 	$t0, $t7, stop_moving_wait
#now to check if the distance is greater than or less than the orbital radius
	li 	$t5, 4
	sw 	$t5, VELOCITY
	#blt 	$t0, $t7, less_than	#the bot is less than the orbital radius away 
	bgt 	$t0, $t7, greater_than 	#the bot is further than the orbiatl radius away 
	j 	move_towards_orbital	#just in case.. Should never hit this statement. Logical Check.
greater_than:
	bgt 	$t1, $t3, right_1	#check if bot_x > 150
	bgt 	$t2, $t4, left_down_1
	li	$t5, 45			#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	move_towards_orbital
left_down_1:
	li	$t5, 315		#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	move_towards_orbital
right_1:	
	bgt 	$t2, $t4, right_down_1
	li	$t5, 135		#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	move_towards_orbital
right_down_1:
	li	$t5, 225		#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	move_towards_orbital

stop_moving_wait:
#wait till the red planet is on me.

	li 	$t0, 2
	sw 	$t0, FIELD_STRENGTH
	sw 	$zero, VELOCITY #stop the bot and wait for the red planet
energy_check:
 
	la	$t0, planet_data
	sw	$t0, PLANETS_REQUEST
	la 	$t0, planet_data	#load address of planet_request into $t0
	lw	$t3, 0($t0)		#loads the planet X coord
	lw	$t4, 4($t0)		#loads the planet Y coord
	lw	$t1, BOT_X
	lw	$t2, BOT_Y
	sub     $t5, $t3, $t1
	mul	$t5, $t5, $t5	# x^2
	sub     $t6, $t4, $t2
	mul	$t6, $t6, $t6	# y^2
	add	$v0, $t6, $t5	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0		# float(x^2 + y^2)
	sqrt.s	$f0, $f0		# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0		# int(sqrt(...))
	mfc1	$v0, $f0	
	move 	$t0, $v0
	blt	$t0, 90, no_energy_interrupt

	la 	$t1, puzzle
	sw	$t1, SPIMBOT_PUZZLE_REQUEST
	la 	$t1, puzzle
	lw 	$t2, 0($t1)		#contains num_rows
	la 	$t5, num_rows
	sw 	$t2, 0($t5)		#store num_rows
	lw	$t2, 4($t1)		#contains num_columns
	la 	$t5, num_columns
	sw 	$t2, 0($t5)		#store num_columns

	la 	$t1, lexicon
	sw 	$t1, SPIMBOT_LEXICON_REQUEST
	lw 	$a1, 0($t1)		#load word into a1 the lexicon_size
	add 	$t1, $t1, 4
	move	$a0, $t1		#load the char ** dictionary)
	jal 	find_words
#	lw 	$t1, GET_ENERGY
#	sw 	$t1, PRINT_INT
solver:
	la 	$t1, solution
	sw 	$t1, SPIMBOT_SOLVE_REQUEST
#	lw 	$t1, GET_ENERGY
 #	sw 	$t1, PRINT_INT
#	lw 	$t1, solution_count
#	sw 	$t1, PRINT_INT
#	move 	$t2, $zero
# print_loop:
# 	bge	$t2, $t1, done_loop
# 	li	$v0, PRINT_STRING			# Unhandled interrupt types
# 	la	$a0, test_str
# 	la 	$t3, solution_arr
# 	mul	$t4, $t2, 8
# 	add 	$t4, $t4, $t3
# 	lw 	$t1, 0($t4)
# 	sw 	$t1, PRINT_INT
# 	lw 	$t1, 4($t4)
# 	sw 	$t1, PRINT_INT
# 	add 	$t2, $t2, 1
# 	j 	print_loop
done_loop:
	la 	$t1, solution 		#reste solution here
	sw 	$zero, 0($t1) 


no_energy_interrupt:
	
	done_can_field_strength:
	li 	$t0, 2
	sw 	$t0, FIELD_STRENGTH

align_planet:
	mul	$t0, $a0, 90		# base angle (0 for X, 90 for Y)
	mul	$a0, $a0, 4		# addressing int arrays

ap_loop:
	la	$t1, planet_data
	sw	$t1, PLANETS_REQUEST	# get updated coordinates
	lw	$t1, planet_data($a0)	# planet coordinate
	lw	$t2, BOT_X($a0)		# bot coordinate
	beq	$t1, $t2, ap_done

	slt	$t1, $t1, $t2		# planet above or to the left
	mul	$t1, $t1, 180		# flip bot if needed
	add	$t1, $t0, $t1
	sw	$t1, ANGLE
	li	$t1, 1
	sw	$t1, ANGLE_CONTROL
	j	ap_loop

ap_done:
	jr	$ra


	# li 	$t0, 2
	# sw 	$t0, FIELD_STRENGTH
	# sw 	$zero, VELOCITY #stop the bot and wait for the red planet
	la	$t0, planet_data
	sw	$t0, PLANETS_REQUEST
	la 	$t0, planet_data	#load address of planet_request into $t0
	lw	$t3, 0($t0)		#loads the planet X coord
	lw	$t4, 4($t0)		#loads the planet Y coord
	lw 	$t7, 12($t0) 		#hill sphere radius. If the diff is the hill sphere radius, then I will relase.
check_if_planet_bot_align:
	la	$t0, planet_data
	sw	$t0, PLANETS_REQUEST
	la 	$t0, planet_data	#load address of planet_request into $t0
	lw	$t3, 0($t0)		#loads the planet X coord
	lw	$t4, 4($t0)		#loads the planet Y coord
	lw	$t1, BOT_X
	lw	$t2, BOT_Y
	sub     $t5, $t3, $t1
	mul	$t5, $t5, $t5	# x^2
	sub     $t6, $t4, $t2
	mul	$t6, $t6, $t6	# y^2
	add	$v0, $t6, $t5	# x^2 + y^2

	ble 	$v0, $t7, planet_reached
	j 	check_if_planet_bot_align

planet_reached:
	

# loop_start:
# 	la 	$t2, field_count
# 	sw 	$t2, SPIMBOT_GET_FIELD_CNT
# 	lw 	$t2, 0($t2)
# 	beq	$t2, $zero, done_waiting
# 	j 	loop_start
done_waiting:
	li 	$t0, 0
	sw 	$t0, FIELD_STRENGTH	#release them
	la	$t0, planet_data
	sw	$t0, PLANETS_REQUEST
	la 	$t0, planet_data	#load address of planet_request into $t0
	lw	$t3, 0($t0)		#loads the planet X coord
	lw	$t4, 4($t0)		#loads the planet Y coord
	lw	$t1, BOT_X
	lw	$t2, BOT_Y
	sub     $t5, $t3, $t1
	mul	$t5, $t5, $t5	# x^2
	sub     $t6, $t4, $t2
	mul	$t6, $t6, $t6	# y^2
	add	$v0, $t6, $t5	# x^2 + y^2
	bge 	$v0, 150, _restart
	j 	done_waiting

_restart:
	j 	restart

.globl find_words
find_words:
	sub	$sp, $sp, 40
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)
	sw	$s8, 36($sp)
	move	$s0, $a0		# dictionary
	move	$s1, $a1		# dictionary_size
	lw	$s2, num_columns
	li	$s3, 0			# i = 0
fw_i:
	lw	$t0, num_rows
	bge	$s3, $t0, fw_done	# !(i < num_rows)
	li	$s4, 0			# j = 0
fw_j:
	bge	$s4, $s2, fw_i_next	# !(j < num_columns)
	mul	$t0, $s3, $s2		# i * num_columns
	add	$s5, $t0, $s4		# start = i * num_columns + j
	add	$t0, $t0, $s2		# equivalent to (i + 1) * num_columns
	sub	$s6, $t0, 1		# end = (i + 1) * num_columns - 1
	li	$s7, 0			# k = 0
fw_k:
	bge	$s7, $s1, fw_j_next	# !(k < dictionary_size)
#	li	$v0, PRINT_STRING			# Unhandled interrupt types
 #	la	$a0, horiz_strncmp_str
	mul	$t0, $s7, 4		# k * 4
	add	$t0, $s0, $t0		# &dictionary[k]
	lw	$s8, 0($t0)		# word = dictionary[k]
	move	$a0, $s8		# word
#don't use s8. s3. s4, t0, s7, 
	move 	$t1, $s8 	#t1 contains the address of the word you are loading into horiz_strcmp
	# I am going to calcualte the length of this word using a for loop
	li 		$t3, 0 		#t3 is going to be my counter for length of word
# count_loop:
# 	lbu 	$t2, 0($t1)
# 	beq		$t2, $zero, done_count
# 	add 	$t1, $t1, 1
# 	add 	$t3, $t3, 1 		#incrment counter and address
# 	j 	    count_loop
# done_count:
# 	sw 	$t3, PRINT_INT
	move	$a1, $s5		# start
#	sw 	$a1, PRINT_INT
	move	$a2, $s6		# end
#	sw 	$a2, PRINT_INT
	# bge 	$t3, 4, fast
	jal	horiz_strncmp
	# j 	record_next
# fast:
	# la 	$a0, 0($a0)
	# jal   horiz_strncmp_fast
record_next:
	sub	$t0, $v0, 1
	bgezal	$t0, fw_record
fw_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	vert_strncmp
	sub	$t0, $v0, 1
	bgezal	$t0, fw_record
fw_k_next:
	add	$s7, $s7, 1		# k++
	j	fw_k
fw_j_next:
	add	$s4, $s4, 1		# j++
	j	fw_j
fw_i_next:
	add	$s3, $s3, 1		# i++
	j	fw_i
fw_done:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)	
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	lw	$s8, 36($sp)
	add	$sp, $sp, 40
	jr	$ra
fw_record:
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	j	record_word
.globl vert_strncmp
vert_strncmp:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	move	$s0, $a0		# word
	move	$s1, $a1		# i = start_i
	move	$s2, $a2		# j
	li	$s3, 0			# word_iter
	lw	$s4, num_rows
vs_for:
	bge	$s1, $s4, vs_nope	# !(i < num_rows)
	move	$a0, $s1
	move	$a1, $s2
	jal	get_character		# get_character(i, j)
	add	$t0, $s0, $s3		# &word[word_iter]
	lbu	$t1, 0($t0)		# word[word_iter]
	bne	$v0, $t1, vs_nope
	lbu	$t1, 1($t0)		# word[word_iter + 1]
	bne	$t1, 0, vs_next
	lw	$v0, num_columns
	mul	$v0, $s1, $v0		# i * num_columns
	add	$v0, $v0, $s2		# i * num_columns + j
	j	vs_return
vs_next:
	add	$s1, $s1, 1		# i++
	add	$s3, $s3, 1		# word_iter++
	j	vs_for
vs_nope:
	li	$v0, 0			# return 0 (data flow)
vs_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra

.globl horiz_strncmp
horiz_strncmp:
	li	$t0, 0			# word_iter = 0
	la 	$t1, puzzle
	add $t1, $t1, 8
#	lw	$t1, 8($t1)
hs_while:
	bgt	$a1, $a2, hs_end	# !(start <= end)
	add	$t2, $t1, $a1		# &puzzle[start]
	lbu	$t2, 0($t2)		# puzzle[start]
	add	$t3, $a0, $t0		# &word[word_iter]
	lbu	$t4, 0($t3)		# word[word_iter]
	beq	$t2, $t4, hs_same	# !(puzzle[start] != word[word_iter])
	li	$v0, 0			# return 0
	jr	$ra
hs_same:
	lbu	$t4, 1($t3)		# word[word_iter + 1]
	bne	$t4, 0, hs_next		# !(word[word_iter + 1] == '\0')
	move	$v0, $a1		# return start
	jr	$ra
hs_next:
	add	$a1, $a1, 1		# start++
	add	$t0, $t0, 1		# word_iter++
	j	hs_while
hs_end:
	li	$v0, 0			# return 0
	jr	$ra

.globl record_word
record_word:
	move	$t0, $a1 		#t0 contains start
	move 	$t1, $a2		#t1 contains end
	la 	$t3, solution
	lw 	$t5, 0($t3) 		# contains solution count
	add 	$t3, $t3, 4
	mul	$t6, $t5 ,8			# get int pointer offset
	add 	$t3, $t3, $t6		#t3 now holds address of the first coordinate
	sw 	$t0, 0($t3)
	sw 	$t1, 4($t3)
	add 	$t5, $t5 ,1
	la 	$t3, solution
	sw 	$t5, 0($t3)
	bge 	$t5, 4, too_many
	jr	$ra
too_many:
	j 	solver
.globl get_character
get_character:
	lw	$t0, num_columns
	mul	$t0, $a0, $t0		# i * num_columns
	add	$t0, $t0, $a1		# i * num_columns + j
	la 	$t1, puzzle
	add	$t1, $t1, 8
#	lw		$t1, puzzle
	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
	jr	$ra


.globl horiz_strncmp_fast
horiz_strncmp_fast:
	sub	$sp, $sp, 56
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)
	sw	$s8, 36($sp)
	# cmp_w is on offsets 40 through 55

	move	$s0, $a0			# word
	lw	$s1, num_columns

	lw	$t0, 0($s0)				# x
	sw	$t0, 40($sp)			# cmp_w[0]
	and	$t1, $t0, 0x00ffffff		# x & 0x00ffffff
	sw	$t1, 44($sp)			# cmp_w[1]
	and	$t1, $t0, 0x0000ffff		# x & 0x0000ffff
	sw	$t1, 48($sp)			# cmp_w[2]
	and	$t1, $t0, 0x000000ff		# x & 0x000000ff
	sw	$t1, 52($sp)			# cmp_w[3]

	li	$s2, 0				# i = 0

hsf_for_i:
	lw	$t0, num_rows
	bge	$s2, $t0, hsf_return_0		# !(i < num_rows)

	la	$t0, puzzle
	add $t0, $t0, 8
	mul	$t1, $s2, $s1			# i * num_columns
	add	$s3, $t0, $t1			# array = puzzle + i * num_columns

	li	$s4, 0				# j = 0

hsf_for_j:
	div	$t0, $s1, 4			# num_columns / 4
	bge	$s4, $t0, hsf_for_i_next	# !(j < num_columns / 4)

	mul	$t0, $s4, 4			# j * 4
	add	$t1, $s3, $t0			# &array[j]
	lw	$s5, 0($t1)			# cur_word = array[j]
	mul	$t1, $s2, $s1			# i * num_columns
	add	$s6, $t1, $t0			# start = i * num_columns + j * 4
	add	$t1, $t1, $s1			# equivalent to (i + 1) * num_columns
	sub	$s7, $t1, 1			# end = (i + 1) * num_columns - 1

	li	$s8, 0				# k = 0

hsf_for_k:
	mul	$t0, $s8, 4			# k * 4
	add	$t0, $sp, $t0			# &cmp_w[k] - 40
	lw	$t0, 40($t0)			# cmp_w[k]
	bne	$s5, $t0, hsf_for_k_next	# !(cur_word == cmp_w[k])

	move	$a0, $s0			# word
	add	$a1, $s6, $s8			# start + k
	move	$a2, $s7			# end
	jal	horiz_strncmp
	bne	$v0, 0, hsf_return		# ret != 0

hsf_for_k_next:
	srl	$s5, $s5, 8			# cur_word >>= 8
	add	$s8, $s8, 1			# k++
	blt	$s8, 4, hsf_for_k		# k < 4

	add	$s4, $s4, 1			# j++
	j	hsf_for_j

hsf_for_i_next:
	add	$s2, $s2, 1			# i++
	j	hsf_for_i

hsf_return_0:
	li	$v0, 0				# return 0 (data flow)

hsf_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	lw	$s8, 36($sp)
	add	$sp, $sp, 56
	jr	$ra


.kdata							# interrupt handler data (separated just for readability)
chunkIH:	.space 40				# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"
unhandled_str1:	.asciiz "Scan interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at				# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)				# Get some free registers                  
	sw	$a1, 4($k0)				# by storing them to a global variable     
	sw	$t0, 8($k0)
	sw	$t2, 12($k0)
	sw 	$t5, 16($k0)					
	sw 	$v0, 20($k0)
	sw 	$t1, 24($k0)
	la  	$t5, extra_space	
	mfc0	$k0, $13				# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf				# ExcCode field                            
	bne	$a0, 0, non_intrpt        
interrupt_dispatch:					# Interrupt:    	                          
	mfc0	$k0, $13				# Get Cause register, again                 
	beq	$k0, 0, done				# handled all outstanding interrupts     
	and	$a0, $k0, SCAN_MASK			# is there a scan interrupt?                
	bne	$a0, 0, scan_interrupt   
	
	and	$a0, $k0, TIMER_MASK			# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt 		# add dispatch for other interrupt types here.
	and 	$a0, $k0, INTERFERENCE_MASK
	bne 	$a0, 0, interference_interrupt
	and	$a0, $k0, ENERGY_MASK			# is there a timer interrupt?
	bne	$a0, 0, energy_interrupt	
	and	$a0, $k0, BONK_MASK			# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   
	li	$v0, PRINT_STRING			# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done
scan_interrupt:
	sw 	$a1, SCAN_ACKNOWLEDGE	
	li 	$t2, 1
	sw 	$t2, 0($t5)
	j 	interrupt_dispatch
energy_interrupt:
	sw      $a1, ENERGY_ACKNOWLEDGE	
	la 	$t1, energy_flag
	li 	$t2, 1
	sw 	$t2, 0($t1)
	# la 	$t1, puzzle
	# sw	$t1, SPIMBOT_PUZZLE_REQUEST
#	la 	$t2, puzzle
#	sw 	$t2, 8($t1)
	# la 	$t1, puzzle
	# lw 	$t2, 0($t1)		#contains num_rows
	# la 	$t5, num_rows
	# sw 	$t2, 0($t5)		#store num_rows
	# lw	$t2, 4($t1)		#contains num_columns
	# la 	$t5, num_columns
	# sw 	$t2, 0($t5)		#store num_columns
	# la 	$t1, lexicon
	# sw 	$t1, SPIMBOT_LEXICON_REQUEST
	# lw 	$a1, 0($t1)		#load word into a1 the lexicon_size
	# add 	$t1, $t1, 4
	# move	$a0, $t1		#load the char ** dictionary)
	# jal 	find_words
	# lw 	$t1, GET_ENERGY
 # 	sw 	$t1, PRINT_INT
	# la 	$t1, solution_count
	# sw 	$zero, PRINT_INT
	# sw 	$zero, PRINT_INT

	# sw 	$zero, PRINT_INT
	# sw 	$zero, PRINT_INT

	# sw 	$t1, SPIMBOT_SOLVE_REQUEST
	# lw 	$t1, GET_ENERGY
 # 	sw 	$t1, PRINT_INT
	# la 	$t1, solution_count
	j       interrupt_dispatch		
timer_interrupt:
	sw	$a1, TIMER_ACK				# acknowledge interrupt
	li      $t2, 1
	sw      $t2, 16($t5)
	j	interrupt_dispatch			# see if other interrupts are waiting
bonk_interrupt:		
	sw	$a1, BONK_ACK				# acknowledge interrupt	
	li	$t2, 225			
	sw	$t2, ANGLE	
	li	$t2, 0	
	sw	$t2, ANGLE_CONTROL	
	j	interrupt_dispatch			# see if other interrupts are waiting
interference_interrupt:
	sw 	$a1, INTERFERENCE_ACK	
	j 	interrupt_dispatch	
non_intrpt:						# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall						# print out an error message
done:							# fall through to done	
	la	$k0, chunkIH
	lw	$a0, 0($k0)				# Restore saved registers
	lw	$a1, 4($k0)
	lw	$t0, 8($k0)
	lw	$t2, 12($k0)		
	lw 	$t5, 16($k0)					
	lw	$v0, 20($k0)
	lw 	$t1, 24($k0)
			
.set noat
	move	$at, $k1				# Restore $at
.set at 
	eret	

# .globl find_words
# find_words:
# 	sub	$sp, $sp, 40
# 	sw	$ra, 0($sp)
# 	sw	$s0, 4($sp)
# 	sw	$s1, 8($sp)
# 	sw	$s2, 12($sp)
# 	sw	$s3, 16($sp)
# 	sw	$s4, 20($sp)
# 	sw	$s5, 24($sp)
# 	sw	$s6, 28($sp)
# 	sw	$s7, 32($sp)
# 	sw	$s8, 36($sp)
# 	move	$s0, $a0		# dictionary
# 	move	$s1, $a1		# dictionary_size
# 	lw	$s2, num_columns
# 	li	$s3, 0			# i = 0
# fw_i:
# 	lw	$t0, num_rows
# 	bge	$s3, $t0, fw_done	# !(i < num_rows)
# 	li	$s4, 0			# j = 0
# fw_j:
# 	bge	$s4, $s2, fw_i_next	# !(j < num_columns)
# 	mul	$t0, $s3, $s2		# i * num_columns
# 	add	$s5, $t0, $s4		# start = i * num_columns + j
# 	add	$t0, $t0, $s2		# equivalent to (i + 1) * num_columns
# 	sub	$s6, $t0, 1		# end = (i + 1) * num_columns - 1
# 	li	$s7, 0			# k = 0
# fw_k:
# 	bge	$s7, $s1, fw_j_next	# !(k < dictionary_size)
# 	mul	$t0, $s7, 4		# k * 4
# 	add	$t0, $s0, $t0		# &dictionary[k]
# 	lw	$s8, 0($t0)		# word = dictionary[k]
# 	move	$a0, $s8		# word
# 	move	$a1, $s5		# start
# 	move	$a2, $s6		# end
# 	jal	horiz_strncmp
# 	sub	$v0, $v0, 1
# 	bgezal	$v0, fw_record
# fw_vert:
# 	move	$a0, $s8		# word
# 	move	$a1, $s3		# i
# 	move	$a2, $s4		# j
# 	jal	vert_strncmp
# 	sub	$v0, $v0, 1
# 	bgezal	$v0, fw_record
# fw_k_next:
# 	add	$s7, $s7, 1		# k++
# 	j	fw_k
# fw_j_next:
# 	add	$s4, $s4, 1		# j++
# 	j	fw_j
# fw_i_next:
# 	add	$s3, $s3, 1		# i++
# 	j	fw_i
# fw_done:
# 	lw	$ra, 0($sp)
# 	lw	$s0, 4($sp)
# 	lw	$s1, 8($sp)
# 	lw	$s2, 12($sp)
# 	lw	$s3, 16($sp)
# 	lw	$s4, 20($sp)
# 	lw	$s5, 24($sp)
# 	lw	$s6, 28($sp)
# 	lw	$s7, 32($sp)
# 	lw	$s8, 36($sp)
# 	add	$sp, $sp, 40
# 	jr	$ra
# fw_record:
# 	move	$a0, $s8		# word
# 	move	$a1, $s5		# start
# 	move	$a2, $v0		# word_end
# 	j	record_word
# .globl vert_strncmp
# vert_strncmp:
# 	sub	$sp, $sp, 24
# 	sw	$ra, 0($sp)
# 	sw	$s0, 4($sp)
# 	sw	$s1, 8($sp)
# 	sw	$s2, 12($sp)
# 	sw	$s3, 16($sp)
# 	sw	$s4, 20($sp)
# 	move	$s0, $a0		# word
# 	move	$s1, $a1		# i = start_i
# 	move	$s2, $a2		# j
# 	li	$s3, 0			# word_iter
# 	lw	$s4, num_rows
# vs_for:
# 	bge	$s1, $s4, vs_nope	# !(i < num_rows)
# 	move	$a0, $s1
# 	move	$a1, $s2
# 	jal	get_character		# get_character(i, j)
# 	add	$t0, $s0, $s3		# &word[word_iter]
# 	lbu	$t1, 0($t0)		# word[word_iter]
# 	bne	$v0, $t1, vs_nope
# 	lbu	$t1, 1($t0)		# word[word_iter + 1]
# 	bne	$t1, 0, vs_next
# 	lw	$v0, num_columns
# 	mul	$v0, $s1, $v0		# i * num_columns
# 	add	$v0, $v0, $s2		# i * num_columns + j
# 	j	vs_return
# vs_next:
# 	add	$s1, $s1, 1		# i++
# 	add	$s3, $s3, 1		# word_iter++
# 	j	vs_for
# vs_nope:
# 	li	$v0, 0			# return 0 (data flow)
# vs_return:
# 	lw	$ra, 0($sp)
# 	lw	$s0, 4($sp)
# 	lw	$s1, 8($sp)
# 	lw	$s2, 12($sp)
# 	lw	$s3, 16($sp)
# 	lw	$s4, 20($sp)
# 	add	$sp, $sp, 24
# 	jr	$ra
# .globl horiz_strncmp
# horiz_strncmp:
# 	li	$t0, 0			# word_iter = 0
# 	la 	$t1, puzzle
# 	add 	$t1, $t1, 8
# #	lw	$t1, 8($t1)
# hs_while:
# 	bgt	$a1, $a2, hs_end	# !(start <= end)
# 	add	$t2, $t1, $a1		# &puzzle[start]
# 	lbu	$t2, 0($t2)		# puzzle[start]
# 	add	$t3, $a0, $t0		# &word[word_iter]
# 	lbu	$t4, 0($t3)		# word[word_iter]
# 	beq	$t2, $t4, hs_same	# !(puzzle[start] != word[word_iter])
# 	li	$v0, 0			# return 0
# 	jr	$ra
# hs_same:
# 	lbu	$t4, 1($t3)		# word[word_iter + 1]
# 	bne	$t4, 0, hs_next		# !(word[word_iter + 1] == '\0')
# 	move	$v0, $a1		# return start
# 	jr	$ra
# hs_next:
# 	add	$a1, $a1, 1		# start++
# 	add	$t0, $t0, 1		# word_iter++
# 	j	hs_while
# hs_end:
# 	li	$v0, 0			# return 0
# 	jr	$ra
# .globl record_word
# record_word:
# 	move	$t0, $a1 		#t0 contains start
# 	move 	$t1, $a2		#t1 contains end
# 	la 	$t3, solution_arr
# 	la	$t4, solution_count
# 	lw 	$t5, 0($t4) 		# contains solution count
# 	mul	$t6, $t5 ,8			# get int pointer offset
# 	add 	$t3, $t3, $t6		#t3 now holds address of the first coordinate
# 	sw 	$t0, 0($t3)
# 	sw 	$t1, 4($t3)
# 	add 	$t5, $t5 ,1
# 	sw 	$t5, 0($t4)

# 	jr	$ra
# .globl get_character
# get_character:
# 	lw	$t0, num_columns
# 	mul	$t0, $a0, $t0		# i * num_columns
# 	add	$t0, $t0, $a1		# i * num_columns + j
# 	la 	$t1, puzzle
# 	add	$t1, $t1, 8
# #	lw		$t1, puzzle
# 	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
# 	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
# 	jr	$ra