.text

## char
## get_character(int i, int j) {
##     return puzzle[i * num_columns + j];
## }

.globl get_character
get_character:
	lw	$t0, num_columns
	mul	$t0, $a0, $t0		# i * num_columns
	add	$t0, $t0, $a1		# i * num_columns + j
	lw	$t1, puzzle
	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
	jr	$ra


## int
## horiz_strncmp(const char* word, int start, int end) {
##     int word_iter = 0;
## 
##     while (start <= end) {
##         if (puzzle[start] != word[word_iter]) {
##             return 0;
##         }
## 
##         if (word[word_iter + 1] == '\0') {
##             return start;
##         }
## 
##         start++;
##         word_iter++;
##     }
##     
##     return 0;
## }

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
