#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#define  sud_size 82

char sudoku_mask[sud_size] = "000111222000111222000111222333444555333444555333444555666777888666777888666777888";

int get_sup_possi(int num, int taken) {
    for (int i = (taken + 1); i <= 9; i++) {
        if (((num >> (i - 1)) & 1) == 0) {
            return i;
        }
    }
    return 0;
}

int32_t commit_sudokuMk2(char* sudoku_map) {
    int row_pos[9] = {0};
    int col_pos[9] = {0};
    int sqe_pos[9] = {0};
    int i=0; // iterator
    // we need this to fill the sets
    for (i = 0; i < sud_size-1; i++) {
        if (sudoku_map[i] != '0') {
            int poss = 1;
            poss = poss << (sudoku_map[i] - '1');
            row_pos[i / 9] = row_pos[i / 9] | poss;
            col_pos[i % 9] = col_pos[i % 9] | poss;
            sqe_pos[sudoku_mask[i] - '0'] = sqe_pos[sudoku_mask[i] - '0'] | poss;
        }
    }
    int pos = 1;
    int new_number = 0;
    int cand_mask;
    int cand;
    int iterations = 0;
    int old;
    int old_mask;
    char sudoku[sud_size];
    strcpy(sudoku, sudoku_map);
    char ent;
    while (pos < sud_size) {
        if ((sudoku_map[(abs(pos) - 1)] == sudoku[(abs(pos) - 1)]) && (sudoku_map[(abs(pos) - 1)] != '0')) {
            pos++;
        } else {
            iterations++;
            if (pos < 0) {
                cand_mask = ((row_pos[(abs(pos) - 1) / 9]) | (col_pos[(abs(pos) - 1) % 9]) | (sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0']));
                cand = get_sup_possi(cand_mask, (int)(sudoku[(abs(pos) - 1)] - '0'));

                if (cand) {
                    // if there is a possible candidate,
                    // 1) remove old one,
                    // 2) edit the masks
                    // 3) put the new one in and
                    // 4) edit the mask for it
                    // 5) reverse counter & iterate
                    old = sudoku[(abs(pos) - 1)] - '0';
                    old_mask = (1 << (old - 1));
                    row_pos[(abs(pos) - 1) / 9] = row_pos[(abs(pos) - 1) / 9] & (~old_mask);
                    col_pos[(abs(pos) - 1) % 9] = col_pos[(abs(pos) - 1) % 9] & (~old_mask);
                    sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] = sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] & (~old_mask);

                    cand_mask = (1 << (cand - 1));
                    row_pos[(abs(pos) - 1) / 9] = row_pos[(abs(pos) - 1) / 9] | cand_mask;
                    col_pos[(abs(pos) - 1) % 9] = col_pos[(abs(pos) - 1) % 9] | cand_mask;
                    sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] = sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] | cand_mask;
                    sudoku[(abs(pos) - 1)] = '0' + cand;
                    pos = -pos;
                    pos++;
                } else {

                    // if there isn't a new candidate
                    // 1) edit the masks
                    // 2) remove current and put a zero there
                    // 3) iterate
                    cand = sudoku[(abs(pos) - 1)] - '0';
                    cand_mask = (1 << (cand - 1));
                    row_pos[(abs(pos) - 1) / 9] = row_pos[(abs(pos) - 1) / 9] & (~cand_mask);
                    col_pos[(abs(pos) - 1) % 9] = col_pos[(abs(pos) - 1) % 9] & (~cand_mask);
                    sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] = sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] & (~cand_mask);
                    sudoku[(abs(pos) - 1)] = '0';
                    pos++;
                }
            } else {
                cand_mask = ((row_pos[(abs(pos) - 1) / 9]) | (col_pos[(abs(pos) - 1) % 9]) | (sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0']));
                cand = get_sup_possi(cand_mask, 0);

                if (cand) {
                    // put new number in the cell and walk forward in sudoku array
                    // edit sudoku
                    // 4) edit the mask for it
                    // 5) reverse counter masks to accomodate new num
                    cand_mask = (1 << (cand - 1));
                    row_pos[(pos - 1) / 9] = row_pos[(pos - 1) / 9] | cand_mask;
                    col_pos[(pos - 1) % 9] = col_pos[(pos - 1) % 9] | cand_mask;
                    sqe_pos[sudoku_mask[(pos - 1)] - '0'] = sqe_pos[sudoku_mask[(pos - 1)] - '0'] | cand_mask;
                    sudoku[(pos - 1)] = '0' + cand;
                    pos++;
                } else {
                    // walk backwards in sudoku array
                    pos = -pos;
                    pos++;
                }
            }
        }
    }
    for (i = 0; i < 9; i++) {
        if ((row_pos[i] & sqe_pos[i] & col_pos[i]) != 511) {
            return 1;
        }
    }
    //free(sudoku);
    //printf("\n\nsolved in :%d\n", iterations);
    return 0;
}


int main (void){
    
    char *sud = (char *)malloc(sud_size);
    strcpy(sud, "800000000003600000070090200050007000000045700000100030001000068008500010090000400");
    clock_t begin = clock();
    commit_sudokuMk2(sud);
    printf("speed %lf\n",(double)(clock() - begin)/ CLOCKS_PER_SEC);
}
