.text

## int
## vert_strncmp(const char* word, int start_i, int j) {
##     int word_iter = 0;
## 
##     for (int i = start_i; i < num_rows; i++, word_iter++) {
##         if (get_character(i, j) != word[word_iter]) {
##             return 0;
##         }
## 
##         if (word[word_iter + 1] == '\0') {
##             // return ending address within array
##             return i * num_columns + j;
##         }
##     }
## 
##     return 0;
## }

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


## // assumes the word is at least 4 characters
## int
## horiz_strncmp_fast(const char* word) {
##     // treat first 4 chars as an int
##     unsigned x = *(unsigned*)word;
##     unsigned cmp_w[4];
##     // compute different offsets to search
##     cmp_w[0] = x;
##     cmp_w[1] = (x & 0x00ffffff); 
##     cmp_w[2] = (x & 0x0000ffff);
##     cmp_w[3] = (x & 0x000000ff);
## 
##     for (int i = 0; i < num_rows; i++) {
##         // treat the row of chars as a row of ints
##         unsigned* array = (unsigned*)(puzzle + i * num_columns);
##         for (int j = 0; j < num_columns / 4; j++) {
##             unsigned cur_word = array[j];
##             int start = i * num_columns + j * 4;
##             int end = (i + 1) * num_columns - 1;
## 
##             // check each offset of the word
##             for (int k = 0; k < 4; k++) {
##                 // check with the shift of current word
##                 if (cur_word == cmp_w[k]) {
##                     // finish check with regular horiz_strncmp
##                     int ret = horiz_strncmp(word, start + k, end);
##                     if (ret != 0) {
##                         return ret;
##                     }
##                 }
##                 cur_word >>= 8;
##             }
##         }
##     }
##     
##     return 0;
## }

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

	lw	$t0, 0($s0)			# x
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

	lw	$t0, puzzle
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
