import sequtils
import tables
import strutils
import bitops

const Cell:int = 3
const maxSud:int = Cell * Cell

type 
  State {.pure.}= enum
    FOUND_IN_BACKTRACK,
    CONTINUE_BACK,
    PUSH_FORWARD,
    JMP_GO_BACK,

proc Translate(inp:char):int =
  case inp:
    of '0'..'9':
      return inp.int - '0'.int
    of 'a'..'g':
      return inp.int - 'a'.int + 10
    of 'A'..'G':
      return inp.int - 'A'.int + 10
    else:
      return -1

proc Translate(inp:int):char =
  case inp:
    of 0..9:
      return ('0'.int + inp).char
    of 10..16:
      return ('A'.int + inp - 10 ).char
    else:
      return ' '

#echo toSeq(0..16).map(Translate) something to test


proc GenCellMatr(cell_size :int):seq[int]=
  result = newSeq[int](0) # result is implicit return value there is no need for the return statemnet
  for i in 0..<cell_size:
    var tmp = newSeq[int](0)
    for j in 0..<cell_size:
      tmp = tmp & repeat(i*cell_size + j,cell_size)
    for j in 0..<cell_size:
      result = result & tmp
  return result

const square_map = GenCellMatr(Cell)

type
  Masks = object
    square:seq[int]
    collum:seq[int]
    row:seq[int]

type
  Sudoku = object
    cnt:seq[int]


proc newMasks(sud:Sudoku):Masks=
  var res:Masks = Masks(square:repeat(0,maxSud),
                        collum:repeat(0,maxSud),
                        row:repeat(0,maxSud))
  for i in 0..sud.cnt.high():
    var tmp = sud.cnt[i] - 1
    res.square[square_map[i]].setBit(tmp)
    res.collum[i mod maxSud].setBit(tmp)
    res.row[(i/maxSud).int].setBit(tmp)
  return res
#echo ""
#for i in 0..<maxSud:
#  echo square_map[(i*maxSud)..<((i+1)*maxSud)]

proc GetSupPossi(mask:int,taken:int):int=
  for i in (taken+1)..maxSud:
    if not mask.testBit(i-1):
      return i
  return 0

# GetSupPossi(0b0101_0101,1) == 2 for tests 

proc FromString(sud:string):Sudoku =
  return Sudoku(cnt:sud.map(proc(a:char):int= Translate(a)))


proc SolveSudoku(sud:Sudoku):Sudoku=
  
  discard 

