## const char *
## lookup_word_in_trie(trie_t *trie, const char *word) {
##     if (trie == NULL) {
##         return NULL;
##     }
## 
##     if (trie->word) {
##         return trie->word;
##     }
## 
##     int c = *word - 'A';
##     if (c < 0 || c >= 26) {
##         return NULL;
##     }
## 
##     trie_t *next_trie = trie->next[c];
##     word ++;
##     return lookup_word_in_trie(next_trie, word);
## }

.globl lookup_word_in_trie
lookup_word_in_trie:
	beq	$a0, 0, lwit_return_null	# trie == NULL
	lw	$v0, 0($a0)			# trie->word
	beq	$v0, 0, lwit_not_word		# !(trie->word)
	jr	$ra

lwit_not_word:
	lbu	$t0, 0($a1)			# *word
	sub	$t0, $t0, 'A'			# c = *word - 'A'
	blt	$t0, 0, lwit_return_null	# c < 0
	bge	$t0, 26, lwit_return_null	# c >= 26

	mul	$t0, $t0, 4			# c * 4
	add	$t0, $a0, $t0			# &trie->next[c] - 4
	lw	$a0, 4($t0)			# next_trie = trie->next[c]
	add	$a1, $a1, 1			# word ++
	j	lookup_word_in_trie

lwit_return_null:
	li	$v0, 0
	jr	$ra
