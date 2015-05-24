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
