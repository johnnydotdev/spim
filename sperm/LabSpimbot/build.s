## trie_t *
## build_trie(const char **wordlist, int num_words) {
##     trie_t *root = alloc_trie();
## 
##     for (int i = 0 ; i < num_words ; i ++) {
##         // start at first letter of each word
##         add_word_to_trie(root, wordlist[i], 0);
##     }
## 
##     return root;
## }

.globl build_trie
build_trie:
	sub	$sp, $sp, 16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	move	$s0, $a0		# wordlist

	mul	$t0, $a1, 4		# num_words * 4
	add	$s1, $s0, $t0		# &wordlist[num_words]
	jal	alloc_trie
	move	$s2, $v0		# root

bt_loop:
	beq	$s0, $s1, bt_done	# loop till end of array
	move	$a0, $s2		# root
	lw	$a1, 0($s0)		# wordlist[i]
	li	$a2, 0
	jal	add_word_to_trie
	add	$s0, $s0, 4		# next word
	j	bt_loop

bt_done:
	move	$v0, $s2		# root
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	add	$sp, $sp, 16
	jr	$ra
