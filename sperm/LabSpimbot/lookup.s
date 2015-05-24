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
