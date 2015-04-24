# syscall constants
SBRK = 9

.data
words:
	.word 0

words_end:
	.word words

.text

get_character:
	lw	$t0, num_columns
	mul	$t0, $a0, $t0		# i * num_columns
	add	$t0, $t0, $a1		# i * num_columns + j
	lw	$t1, puzzle
	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
	jr	$ra


.globl horiz_strncmp
horiz_strncmp:
	li	$t0, 0			# word_iter = 0
	lw	$t1, puzzle

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
	li	$v0, 0

vs_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra


.globl record_word
record_word:
	move	$t0, $a0
	li	$v0, SBRK
	li	$a0, 16
	syscall
	sw	$t0, 0($v0)
	sw	$a1, 4($v0)
	sw	$a2, 8($v0)
	sw	$zero, 12($v0)
	lw	$t0, words_end
	sw	$v0, 0($t0)
	la	$t0, 12($v0)
	sw	$t0, words_end
	jr	$ra


main:
	sub	$sp, $sp, 8
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)

	la	$t0, puzzle_1
	sw	$t0, puzzle
	li	$t0, 16
	sw	$t0, num_rows
	sw	$t0, num_columns

	la	$a0, english
	lw	$a1, english_size
	jal	find_words

	lw	$s0, words

main_loop:
	beq	$s0, 0, main_end
	lw	$a0, 0($s0)
	jal	print_string_and_space
	lw	$a0, 4($s0)
	jal	print_int_and_space
	lw	$a0, 8($s0)
	jal	print_int_and_newline
	lw	$s0, 12($s0)
	j	main_loop

main_end:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	add	$sp, $sp, 8
	jr	$ra
