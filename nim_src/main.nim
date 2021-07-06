import sequtils
import math
import random
import tables
import strutils
import bitops
import strformat




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

proc CheckMasks(sud:Sudoku,this:Masks):bool=
  var set_in_sud =  sud.cnt.filter(proc (x:int):bool= x > 0).len()
  var set_in_sqe =  set_in_sud
  var set_in_row =  set_in_sud
  var set_in_col =  set_in_sud
  for i in 0..this.square.high():
    set_in_sqe = set_in_sqe - countSetBits(this.square[i])
    set_in_col = set_in_col - countSetBits(this.collum[i])
    set_in_row = set_in_row - countSetBits(this.row[i])
  if set_in_col != 0 or set_in_row != 0 or set_in_sqe != 0:
    return false
  return true

proc newMasks(sud:Sudoku):Masks=
  var res:Masks = Masks(square:repeat(0,maxSud),
                        collum:repeat(0,maxSud),
                        row:repeat(0,maxSud))
  for i in 0..sud.cnt.high():
    var tmp = sud.cnt[i]
    if tmp > 0:
      res.square[square_map[i]].setBit(tmp-1)
      res.collum[i mod maxSud].setBit(tmp-1)
      res.row[i div maxSud].setBit(tmp-1)

#  echo "square "
#  for i in 0..res.square.high():
#    echo toBin(res.square[i],9)
#  echo "coll"
#  for i in 0..res.square.high():
#      echo toBin(res.collum[i],9)
#  echo "row"
#  for i in 0..res.square.high():
#      echo toBin(res.row[i],9)
#  for i in 0..<maxSud:
#    echo sud.cnt[(i*maxSud)..<((i+1)*maxSud)]
  return res

proc GetSupPossi(mask:int,taken:int):int=
  for i in (taken+1)..maxSud:
    if not mask.testBit(i-1):
      return i
  return 0


proc FromString(sud:string):Sudoku =
  return Sudoku(cnt:sud.map(proc(a:char):int= Translate(a)))


proc SolveSudoku(input: Sudoku):Sudoku=
  var Repr:Masks = input.newMasks
  var Done = input
  var sud:Sudoku = deepCopy(input)
  var iterations:uint64
  var pos:int= 1
  var mx = sud.cnt.len() + 1
  var CandMask:int
  var Cand:int
  var tmp_pos:int = 0
  var STATE:int = 0
  var old:int
  var old_mask:int

  while pos < mx:

    tmp_pos = abs(pos) - 1
    if Done.cnt[tmp_pos] == sud.cnt[tmp_pos] and Done.cnt[tmp_pos] != 0:
      inc pos
      continue
    else:
      inc iterations
      CandMask = (Repr.row[tmp_pos div 9]).bitor(Repr.collum[tmp_pos mod 9],Repr.square[square_map[tmp_pos]])
      Cand = GetSupPossi(CandMask, sud.cnt[tmp_pos])
      STATE = ((pos>0).int shl 1).bitor((Cand == 0).int)
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
          Repr.row[(pos - 1) div 9] = Repr.row[(pos - 1) div 9].bitor(CandMask)
          Repr.collum[(pos - 1) mod 9] = Repr.collum[(pos - 1) mod 9].bitor(CandMask)
          Repr.square[square_map[(pos - 1)]] = Repr.square[square_map[(pos - 1)]].bitor(CandMask)
          sud.cnt[(pos - 1)] = Cand;
          inc pos
        of JMP_GO_BACK:
          pos = -pos;
          inc pos
        else:
          assert(true,"time to commit self die i guess")
  return sud

proc LoadFromIndex(sud:var Sudoku,ind:int,sq_data:seq[int],sq_side:int)=
  var counter:int=0
  for i in ind..<(sq_side+ind):
    for j in 0..<sq_side:
      sud.cnt[i + j*sq_side*sq_side] = sq_data[counter]
      inc counter

# eithder 9 or 16
proc GenerateSudoku(square_size:int = 9):Sudoku=
  randomize()
  var res:Sudoku
  var full_size:int = square_size * square_size
  var sq:int = pow(square_size.float ,0.5).int
  var diagonal_suare_seed:seq[int] = toSeq(1..square_size)
  res.cnt.setLen(full_size)

  for i in 0..<sq:
    diagonal_suare_seed.shuffle()
    var ind:int= i * (sq ^ 3).int + i*sq
    res.LoadFromIndex(ind,diagonal_suare_seed,sq)
  res = SolveSudoku(res)

  for i in 0..<maxSud:
    echo res.cnt[(i*maxSud)..<((i+1)*maxSud)]

  return res

if isMainModule:
  #var test ="812053649943682175675491283154237896369845721287169534521974368438526917796318452"
  #var test = "800000000003600000070090200050007000000045700000100030001000068008500010090000400"
  #echo SolveSudoku(FromString(test))


  discard GenerateSudoku()


