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

