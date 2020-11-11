#include "sudoku.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static char sudoku_mask[sud_size] = "000111222000111222000111222333444555333444555333444555666777888666777888666777888";

static int get_sup_possi(int num, int taken)
{
    for (int i = (taken + 1); i <= 9; i++) {
        if (((num >> (i - 1)) & 1) == 0) {
            return i;
        }
    }
    return 0;
}

int8_t generate_from_array(int* arr, int length, char* target)
{
    int i = 0;
    if (length < 81 || arr == NULL)
        return 0;

    if (target != NULL)
        free(target);

    target = (char*)malloc(sud_size);

    for (i = 0; i < 81; i++) {
        if (0 <= arr[i] && arr[i] <= 9)
            target[i] = arr[i] + '0';
        else {
            free(target);
            return 0;
        }
    }
    return 1;
}

int32_t commit_sudoku(char* sudoku_map)
{
    int row_pos[9] = { 0 };
    int col_pos[9] = { 0 };
    int sqe_pos[9] = { 0 };
    int i = 0; // iterator
    // we need this to fill the sets
    int poss = 1;
    for (i = 0; i < sud_size - 1; i++) {
        if (sudoku_map[i] != '0') {
            poss = 1 << (sudoku_map[i] - '1');
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
            cand_mask = ((row_pos[(abs(pos) - 1) / 9]) | (col_pos[(abs(pos) - 1) % 9]) | (sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0']));
            cand = get_sup_possi(cand_mask, (int)(sudoku[(abs(pos) - 1)] - '0'));

            switch (DET_STATE(pos, cand)) {
            case JMP_FOUND_IN_BACKTRACK:
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
                break;
            case JMP_CONTINUE_BACK:
                cand = sudoku[(abs(pos) - 1)] - '0';
                cand_mask = (1 << (cand - 1));
                row_pos[(abs(pos) - 1) / 9] = row_pos[(abs(pos) - 1) / 9] & (~cand_mask);
                col_pos[(abs(pos) - 1) % 9] = col_pos[(abs(pos) - 1) % 9] & (~cand_mask);
                sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] = sqe_pos[sudoku_mask[(abs(pos) - 1)] - '0'] & (~cand_mask);
                sudoku[(abs(pos) - 1)] = '0';
                pos++;
                break;
            case JMP_PUSH_FORWARD:
                cand_mask = (1 << (cand - 1));
                row_pos[(pos - 1) / 9] = row_pos[(pos - 1) / 9] | cand_mask;
                col_pos[(pos - 1) % 9] = col_pos[(pos - 1) % 9] | cand_mask;
                sqe_pos[sudoku_mask[(pos - 1)] - '0'] = sqe_pos[sudoku_mask[(pos - 1)] - '0'] | cand_mask;
                sudoku[(pos - 1)] = '0' + cand;
                pos++;
                break;
            case JMP_GO_BACK:
                pos = -pos;
                pos++;
                break;
            }
        }
    }
    for (i = 0; i < 9; i++) {
        if ((row_pos[i] & sqe_pos[i] & col_pos[i]) != FULL_CELL)
            return 1;
    }
    return 0;
}

int main(void)
{
    char* sud = (char*)malloc(sud_size);
    strcpy(sud, "800000000003600000070090200050007000000045700000100030001000068008500010090000400");
    clock_t begin = clock();
    commit_sudoku(sud);
    printf("speed %lf\n", (double)(clock() - begin) / CLOCKS_PER_SEC);
}
