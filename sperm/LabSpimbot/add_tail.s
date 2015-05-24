## void
## add_word_to_trie(trie_t *trie, const char *word, int index) {
##     char c;
##     while ((c = word[index]) != 0) {
##         if (trie->next[c - 'A'] == NULL) {
##             trie->next[c - 'A'] = alloc_trie();
##         }
##         trie = trie->next[c - 'A'];
##         index ++;
##     }
## 
##     trie->word = word;
## }
