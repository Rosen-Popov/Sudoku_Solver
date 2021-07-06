import sequtils
import tables
import strutils
import bitops

const Cell:int = 3
const maxSud:int = Cell * Cell

const   FOUND_IN_BACKTRACK=0
const   CONTINUE_BACK=1
const   PUSH_FORWARD=2
const   JMP_GO_BACK=3

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

proc CheckMasks(this:Masks):bool=

  return true

proc newMasks(sud:Sudoku):Masks=
  var res:Masks = Masks(square:repeat(0,maxSud),
                        collum:repeat(0,maxSud),
                        row:repeat(0,maxSud))
  for i in 0..sud.cnt.high():
    var tmp = sud.cnt[i] - 1
    res.square[square_map[i]].setBit(tmp)
    res.collum[i mod maxSud].setBit(tmp)
    res.row[i div maxSud].setBit(tmp)
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


proc SolveSudoku(input: Sudoku):Sudoku=
  var Repr:Masks = input.newMasks
  var Done = input
  var sud:Sudoku = deepCopy(input)
  var iterations:uint64
  var pos:int= 0
  var mx = sud.cnt.len() + 1
  var CandMask:int
  var Cand:int
  var tmp_pos:int = 0
  var STATE:int = 0
  var old:int
  var old_mask:int

  while pos < mx:
    tmp_pos = abs(pos) - 1
    # If position is set then do nothing
    if Done.cnt[(abs(pos) - 1)] == sud.cnt[(abs(pos) - 1)] and Done.cnt[(abs(pos) - 1)] != 0:
      inc pos
    else:
      inc iterations
      CandMask = (Repr.row[tmp_pos div 9]).bitor(Repr.collum[tmp_pos mod 9],Repr.square[square_map[tmp_pos]])
      Cand = GetSupPossi(CandMask, sud.cnt[tmp_pos])
      STATE = ((pos>0).int shl 1).bitand((Cand == 0).int)
      case STATE:
        of FOUND_IN_BACKTRACK:
          old = sud.cnt[tmp_pos]
          old_mask = (1 shl (old - 1))
          Repr.row[tmp_pos div 9] = Repr.row[tmp_pos div 9].bitand (not  old_mask)
          Repr.collum[tmp_pos mod 9] = Repr.collum[tmp_pos mod 9].bitand (not old_mask)
          Repr.square[square_map[tmp_pos]] = Repr.square[square_map[tmp_pos]].bitand (not old_mask)

          CandMask = (1 shl (Cand - 1))
          Repr.row[tmp_pos div 9] = Repr.row[tmp_pos div 9].bitor (CandMask)
          Repr.collum[tmp_pos mod 9] = Repr.collum[tmp_pos mod 9].bitor (CandMask)
          Repr.square[square_map[tmp_pos] ] = Repr.square[square_map[tmp_pos]].bitor (CandMask)
          sud.cnt[tmp_pos] = Cand;
          pos = -pos 
          inc pos
        of CONTINUE_BACK:
          Cand = sud.cnt[tmp_pos]
          CandMask = (1 shl (Cand - 1));
          Repr.row[tmp_pos div 9] = Repr.row[tmp_pos div 9].bitand (not CandMask)
          Repr.collum[tmp_pos mod 9] = Repr.collum[tmp_pos mod 9].bitand (not CandMask)
          Repr.square[square_map[tmp_pos]] = Repr.square[square_map[tmp_pos]].bitand (not CandMask)
          sud.cnt[tmp_pos] = 0
          inc pos
        of PUSH_FORWARD:
          CandMask = (1 shl (Cand - 1));
          Repr.row[(pos - 1) div 9] = Repr.row[(pos - 1) div 9].bitor( CandMask)
          Repr.collum[(pos - 1) mod 9] = Repr.collum[(pos - 1) mod 9].bitor(CandMask)
          Repr.square[square_map[(pos - 1)]] = Repr.square[square_map[(pos - 1)]].bitor(CandMask)
          sud.cnt[(pos - 1)] = Cand;
          inc pos
        of JMP_GO_BACK:
          pos = -pos;
          inc pos
          discard
        else:
          assert(true,"time to commit self die i guess")
  return sud

