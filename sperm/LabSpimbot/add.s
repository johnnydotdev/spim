## void
## add_word_to_trie(trie_t *trie, const char *word, int index) {
##     char c = word[index];
##     if (c == 0) {
##         trie->word = word;
##         return;
##     }
## 
##     if (trie->next[c - 'A'] == NULL) {
##         trie->next[c - 'A'] = alloc_trie();
##     }
##     add_word_to_trie(trie->next[c - 'A'], word, index + 1);
## }

.globl add_word_to_trie
add_word_to_trie:
	sub	$sp, $sp, 16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	move	$s0, $a1		# word
	move	$s1, $a2		# index

	add	$t0, $s0, $s1		# &word[index]
	lbu	$t0, 0($t0)		# c = word[index]
	bne	$t0, 0, awtt_search	# !(c == 0)
	sw	$s0, 0($a0)		# trie->word = word
	j	awtt_return

awtt_search:
	sub	$t0, $t0, 'A'		# c - 'A'
	mul	$t0, $t0, 4		# (c - 'A') * 4
	add	$s2, $a0, $t0		# &trie->next[c - 'A'] - 4
	lw	$v0, 4($s2)		# trie->next[c - 'A']
	bne	$v0, 0, awtt_skip	# trie->next[c - 'A'] != NULL
	jal	alloc_trie
	sw	$v0, 4($s2)		# trie->next[c - 'A'] = alloc_trie()

awtt_skip:
	move	$a0, $v0		# trie->next[c - 'A']
	move	$a1, $s0		# word
	add	$a2, $s1, 1		# index + 1
	jal	add_word_to_trie

awtt_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	add	$sp, $sp, 16
	jr	$ra
