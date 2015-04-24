.data
.align 2
planet_data: 	.space 32	#keeps memory stored for the 2 planets
scan_data: 	.space 256	#keeping memory stored the scanner data
counter:	.space 4
flag:		.space 4
max_index:	.space 4
max_index_dots: .space 4
flag_x: 	.space 4
flag_y: 	.space 4
# movement memory-mapped I/O
VELOCITY            = 0xffff0010
ANGLE               = 0xffff0014
ANGLE_CONTROL       = 0xffff0018
PRINT_STRING  = 4
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

#Timer constants
TIMER 		 = 0xffff001c
TIMER_MASK 	 = 0x8000
TIMER_ACK        = 0xffff006c
.text

main:
	li	$t4, SCAN_MASK		# scan interrupt bit
	or 	$t4, $t4, TIMER_MASK	#TIMER_MASK set
	or 	$t4, $t4, ENERGY_MASK   #energy mask set
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)
	#set velocity to 0 until I am finish scanning.
	li	$t0, 0 				#set velocity to be zero
	sw	$t0, VELOCITY		# drive

start:	
	la 	$t0, flag		#set the flag to zero at the start of every looop
	lw	$zero, 0($t0)
	li	$t1, 0 			#t1 will be my counter
	la 	$t3, scan_data		#t3 holds the address of my initial scan_data
	la 	$t5, counter		#t5 holds add
	sw 	$t1, 0($t5)		#store 0 into my counter variable in data memory
	la 	$t5, max_index 		#clear memory for max_index and max_index_dots
	sw 	$t1, 0($t5)	 	#store the max index to be 0 
	la 	$t5, max_index_dots     #store the max_index dots to be 0
	sw 	$t1, 0($t5) 	
	la 	$t5, flag_x		#set the x flag to 0
	lw 	$zero, 0($t5)
	la 	$t5, flag_y		#set the y flag to 0
	lw 	$zero, 0($t5)
#scan_loop:	
#	bge 	$t1, 64, loop		#if I am done with queuing all the interrupts
	sw 	$t1, SCAN_SECTOR	#store sector number into SCAN_SECTOR
	sw 	$t3, SCAN_REQUEST	#store the address of the stack space into SCAN_REQUEST
#	add 	$t1, $t1, 1
#	add 	$t3, $t3, 4		#increment scan_Data and counter.
#	j 	scan_loop
# I'm going to try and implement a timer interrupt here so that the
# system waits for a while before it tries to find the scan location
#	lw 	$t0, TIMER
#	add 	$t0, $t0, 200000
#	sw 	$t0, TIMER
#busy_timer_wait:	
#	la 	$t6, flag
#	lw	$t7, 0($t6)		#load the value of the flag
#	beq	$t7, 1, done_timer_wait	#done with scan
#	j 	busy_timer_wait
#done_timer_wait:
#	la 	$t6, flag		#now that I am done with the initial scan process, 
#	sw	$zero, 0($t6)  		#I am going to reset my flag back to 0 so that I can reuse it

busy_wait_scan:
	la 	$t6, flag
	lw	$t7, 0($t6)		#load the value of the flag
	beq	$t7, 1, done_scan_wait	#done with scan
	j 	busy_wait_scan
done_scan_wait:
	la 	$t6, flag		#now that I am done with the initial scan process, 
	sw	$zero, 0($t6)  		#I am going to reset my flag back to 0 so that I can reuse it
	la 	$t5, max_index          #After scanning, I now have the max_index where the dust is located.
	lw	$t3, 0($t5)		#load the index of max_index into t3
	li 	$t4, 8   		# divide t3 by 8 to get the 
	div 	$t3, $t4		
	mflo    $t6			#stores quotient
	mfhi	$t7			#stores remainder
	add 	$t6, $t6, 1 		#off by 1!
	add 	$t7, $t7, 1 		#off by 1!
	mul 	$t1, $t7, 37		# X coordinate - t1
	mul 	$t2, $t6, 37 		# Y coordinate - t2
	sub 	$t1, $t1, 17		#subtract 17 to get it into the center
	sub 	$t2, $t2, 17
	
# going to check if it passses the x and y flag twice. Which indicates the full circle delay.
#I can reuse anything but $t1, $t2


#check if the x_bot - x_blue_planet is less than 60
# wait_too_close:
# 	la	$t0, planet_data	#load the address of planet data
# 	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
# 	lw	$t3, 16($t0)		#holds x coordinate of the enemy planet
# 	sub	$t4, $t1, $t3
# 	bgez	$t4, not_negative
# 	mul 	$t4, $t4, -1
# not_negative:
# 	ble 	$t4, 20,  wait_too_close
# #choose not to wait when to move to the spot where the dust is located
#done_delay:
	li	$a0, 10
	sw	$a0, VELOCITY		# drive
loop_move:
	lw	$t3, BOT_X		#get the BOT's x coordinate
	lw	$t4, BOT_Y 		#get the BOT's y coordinate
	bne	$t3, $t1, x_loop 	
	bne	$t4, $t2, y_loop 
	j 	done_moving
x_loop:
	lw	$t3, BOT_X
	beq	$t3, $t1, y_loop
	blt	$t1, $t3, negative_x
	li	$t5, 0			#set angle to 0
	sw	$t5, ANGLE		
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
negative_x:
	li	$t5, 180		#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
y_loop:
	lw	$t3, BOT_Y
	beq	$t4, $t2, loop_move	#checks if(p_y == y), then go back to loop?
	blt	$t2, $t4, negative_y
	li	$t5, 90		#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move
negative_y:
	li	$t5, 270			#set angle to 0
	sw	$t5, ANGLE	
	li      $t6, 1			#set to absolute
	sw	$t6, ANGLE_CONTROL
	j 	loop_move

done_moving:
	li	$t0, 0
	sw	$t0, VELOCITY		# drive
wait_too_close:
	la 		$t5, flag_x
	lw 		$t5, 0($t5)
	blt 	$t5, 2, loop_checker
	la 		$t5, flag_y
	lw 		$t5, 0($t5)
	blt	 	$t5, 2, loop_checker
	j 		wait_for_preset
loop_checker:
	la		$t0, planet_data	#load the address of planet data
	sw		$t0, PLANETS_REQUEST#store the address of the stack memory in to planet_request
	lw		$t3, 0($t0)			#holds x coordinate of the my planet
	lw		$t4, 4($t0)			#holds y coordinate of my planet
	beq		$t3, 150, increment_x	#checking if I have reached a way point where x = 150. I have to hit two of these
	beq 	$t4, 150, increment_y
	j 		loop_checker
increment_x:
	la 		$t5, flag_x			#load the flag and icnrement it by 1
	lw 		$t7, 0($t5)
	add 	$t7, $t7, 1
	sw 		$t7, 0($t5)	
	j 		wait_too_close
increment_y:
	la 		$t6, flag_y
	lw 		$t7, 0($t6)
	add 	$t7, $t7, 1
	sw 		$t7, 0($t6)	
	j 		wait_too_close

#start this process only when x = 150 or y = 0.
wait_for_preset:
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#holds y coordinate of my planet
	li 	$t5, 150
	beq 	$t3, $t5, wait_too_early
	beq 	$t4, $t5, wait_too_early
	j 	wait_for_preset
#before I set the power for field strength on, I have to check whether or not
#It is useful for me to turn on my power.
#if the dust is in quad 0, I will wait till my planet is in quad 2 or 3 ( y> 150)
#if the dust is in quad 1, I will wait till my planet is in quad 0 or 3
#if the dust is in quad 2, I will wait till my planet is in quad 0 or 1
#if the dust is in quad 3, I will wait till my planet is in quad 1 or 2
wait_too_early:
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#hollds y coordinate of my planet
	lw	$t1, BOT_X
	lw	$t2, BOT_Y
	li 	$t5, 150
	bgt 	$t1, $t5, right_2	#check if bot_x > 150
	bgt 	$t2, $t5, left_down_2
left_up_2:	
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#hollds y coordinate of my planet
 	ble 	$t4, $t5, left_up_2	#checks if my planet is in quad 0 or 1
 	ble 	$t3, $t5, left_up_2	#checks if my planet is in quad 3
	j 	done_can_field_strength
left_down_2:
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#hollds y coordinate of my planet
 	ble 	$t3, $t5, left_down_2	#checks if my planet is in quad 0 or 3
 	bge 	$t4, $t5, left_down_2 	#checks if my planet is in quad 2
	j 	done_can_field_strength
right_2:	
	bgt 	$t2, $t5, right_down_2
right_up_2:
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#hollds y coordinate of my planet
 	bge 	$t3, $t5, right_up_2	#checks if my planet is in quad 1 or 2
 	ble 	$t4, $t5, right_up_2
	j 	done_can_field_strength
right_down_2:
	la	$t0, planet_data	#load the address of planet data
	sw	$t0, PLANETS_REQUEST	#store the address of the stack memory in to planet_request
	lw	$t3, 0($t0)		#holds x coordinate of the my planet
	lw	$t4, 4($t0)		#hollds y coordinate of my planet
 	bge 	$t4, $t5, right_down_2	#checks if my planet is in quad 2 or 3
 	bge 	$t3, $t5, right_down_2	#checsk if my planet is in quad 1
	j 	done_can_field_strength



done_can_field_strength:
	li 	$t0, 7
	sw 	$t0, FIELD_STRENGTH
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
	li 		$t5, 1
	sw 		$t5, VELOCITY
	#blt 	$t0, $t7, less_than	#the bot is less than the orbital radius away 
	bgt 	$t0, $t7, greater_than 	#the bot is further than the orbiatl radius away 
	j 	move_towards_orbital	#just in case.. Should never hit this statement. Logical Check.
greater_than:
# 	bne 	$t1, $t3, check_for_y_vert
# 	bge 	$t2, $t4, vert_up_x
# 	li		$t5, 270			#set angle to 0
# 	sw		$t5, ANGLE
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	done_equal_check_x	
# vert_up_x:	
# 	li	$t5, 90		#set angle to 0
# 	sw	$t5, ANGLE
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	done_equal_check_x		
# done_equal_check_x:
# 	j 		move_towards_orbital
# check_for_y_vert:
# 	bne 	$t2, $t4, carry_on_with_check
# 	bge 	$t1, $t3, vert_right_y
# 	li	$t5, 0	#set angle to 0
# 	sw	$t5, ANGLE
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	done_equal_check_y	
# vert_right_y:
# 	li	$t5, 180		#set angle to 0
# 	sw	$t5, ANGLE
# 	li  $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	done_equal_check_y	
# done_equal_check_y:
# 	j 		move_towards_orbital

# carry_on_with_check:
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


# less_than:
# 	bgt 	$t1, $t3, right 	#check if bot_x > 150
# 	bgt 	$t2, $t4, left_down
# 	li	$t5, 225		#set angle to 0
# 	sw	$t5, ANGLE		
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	move_towards_orbital
# left_down:
# 	li	$t5, 135		#set angle to 0
# 	sw	$t5, ANGLE		
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	move_towards_orbital
# right:	
# 	bgt 	$t2, $t4, right_down
# 	li	$t5, 315		#set angle to 0
# 	sw	$t5, ANGLE		
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	move_towards_orbital
# right_down:
# 	li	$t5, 45		#set angle to 0
# 	sw	$t5, ANGLE		
# 	li      $t6, 1			#set to absolute
# 	sw	$t6, ANGLE_CONTROL
# 	j 	move_towards_orbital
stop_moving_wait:
#wait till the red planet is on me.
	li 	$t0, 2
	sw 	$t0, FIELD_STRENGTH
	sw 	$zero, VELOCITY #stop the bot and wait for the red planet
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
	li 	$t0, 0
	sw 	$t0, FIELD_STRENGTH	#release them

loop_start:
	j 	start

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 40	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"
scan_str:  .asciiz "Entered my scan handler\n"
timer_str:  .asciiz "Entered my timer handler\n"
.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     
	sw	$t0, 8($k0)
	sw	$t1, 12($k0)
	sw 	$t2, 16($k0)
	sw 	$t3, 20($k0)
	sw 	$t4, 24($k0)
	sw 	$t5, 28($k0)
	sw 	$t6, 32($k0)
	sw 	$v0, 36($k0)
	#li	$v0, PRINT_STRING
	#la	$a0, scan_str
	#syscall	



	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         
interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, SCAN_MASK	# is there a scan interrupt?                
	bne	$a0, 0, scan_interrupt   
	# add dispatch for other interrupt types here.
	and	$a0, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt

	and 	$a0, $k0, ENERGY_MASK  	# is there an energy_interrupt
	bne	$a0, 0, energy_interrupt

	li	$t0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done
energy_interrupt:
	sw 	$a1, ENERGY_ACKNOWLEDGE
	sw 	$zero, FIELD_STRENGTH
	#sw 	$zero, VELOCITY

	j 	interrupt_dispatch

timer_interrupt:
	li	$v0, PRINT_STRING
	la	$a0, timer_str
	syscall
	sw	$a1, TIMER_ACK
	#li	$t0, PRINT_STRING	# Unhandled interrupt types
	#la	$a0, unhandled_str
	#syscall 
	la 	$t2, flag
	li 	$t3, 1
	sw 	$t3, 0($t2)
	j	interrupt_dispatch

scan_interrupt:
	sw 	$a1, SCAN_ACKNOWLEDGE	#SCAN_ACKNOWLEDGE 
	la 	$t4, counter		#load address of the counter
	lw	$t4, 0($t4) 		# load the counter into t4
	la 	$t3, scan_data 		# load address of the data to write into
	la 	$t5, max_index_dots	#load address of max.
	lw 	$t5, 0($t5)		#t5 now contains the max index dots
	
	mul 	$t2, $t4, 4 		#multiply my current counter by 4
	add 	$t2, $t3, $t2 		#get to the right adderss.load the number of dots
	lw 	$t2, 0($t2)		#load it.
	bge	$t5, $t2, continue 	#check if max_index_dots > current_dots.
	la 	$t6, max_index
	sw 	$t4, 0($t6)		#store new max index
	la 	$t6, max_index_dots
	sw 	$t2, 0($t6) 		#store the value of t2, the new max_index_dots

continue:	 
	add 	$t4, $t4, 1		# increment my counter by 1
	bge	$t4, 64, done_scan 	# check if counter is >= 64. If that is so, we have processed all the scans
	la 	$t2, counter		#store the counter value back into the data memeory
	sw 	$t4, 0($t2)	
	sw 	$t4, SCAN_SECTOR	# store the incremented new sector number into SCAN_SECTOR
	sw 	$t3, SCAN_REQUEST	# use the same address of scan_Data as the address 
	j 	interrupt_dispatch	# call interrupt_dispatch
done_scan:
	la 	$t2, flag		# set flag to done.
	li 	$t3, 1
	sw 	$t3, 0($t2)
	j 	interrupt_dispatch	#jump back up the loop


non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done


done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
	lw	$t0, 8($k0)
	lw	$t1, 12($k0)
	lw 	$t2, 16($k0)
	lw 	$t3, 20($k0)
	lw 	$t4, 24($k0)
	lw 	$t5, 28($k0)
	lw 	$t6, 32($k0)
	lw 	$v0, 36($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret