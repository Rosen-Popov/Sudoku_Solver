#include <stdint.h>
#define sud_size 82

#define DET_STATE(POS, CAND) ((POS > 0) << 1 | (!CAND))

#define FULL_CELL 511

#define JMP_FOUND_IN_BACKTRACK 0
#define JMP_CONTINUE_BACK 1

#define JMP_PUSH_FORWARD 2
#define JMP_GO_BACK 3
int8_t generate_from_array(int* arr, int length, char* target);

int32_t commit_sudoku(char* sudoku_map);
