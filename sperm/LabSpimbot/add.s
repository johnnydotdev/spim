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

