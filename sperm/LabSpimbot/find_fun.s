## void
## find_words(const char** dictionary, int dictionary_size) {
##     for (int i = 0; i < num_rows; i++) {
##         for (int j = 0; j < num_columns; j++) {
##             int start = i * num_columns + j;
##             int end = (i + 1) * num_columns - 1;
## 
##             for (int k = 0; k < dictionary_size; k++) {
##                 const char* word = dictionary[k];
##                 int word_end = horiz_strncmp(word, start, end);
##                 if (word_end > 0) {
##                     record_word(word, start, word_end);
##                 }
## 
##                 word_end = vert_strncmp(word, i, j);
##                 if (word_end > 0) {
##                     record_word(word, start, word_end);
##                 }
## 
##             }
##         }
##     }
## }

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
	mul	$t0, $s7, 4		# k * 4
	add	$t0, $s0, $t0		# &dictionary[k]
	lw	$s8, 0($t0)		# word = dictionary[k]

	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $s6		# end
	jal	horiz_strncmp
	sub	$v0, $v0, 1
	bgezal	$v0, fw_record

fw_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	vert_strncmp
	sub	$v0, $v0, 1
	bgezal	$v0, fw_record

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
