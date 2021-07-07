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

const square_map_global:Table[int,seq[int]] = [(9, GenCellMatr(3)),(16,GenCellMatr(3))].toTable

type
  Masks = object
    square:seq[int]
    collum:seq[int]
    row:seq[int]

type
  Sudoku = object
    cnt:seq[int]

proc GetKind(this:Sudoku):int=
  return pow(this.cnt.len().float , 0.5 ).int


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
  var square_map = square_map_global[sud.GetKind()]
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

proc GetSupPossi(mask:int,taken:int,size:int):int=
  for i in (taken+1)..size:
    if not mask.testBit(i-1):
      return i
  return 0

# not exactly working ? 
proc RandomPossi(mask:int,taken:int,size:int):int=
  var counter:int = countSetBits(not mask)
  if counter == 0:
    return 0
  counter = rand(counter-1)
  # TODO make it so its not a compile time parameter
  for i in 1..size:
    if not mask.testBit(i-1) and counter == 0:
      return i
    dec counter
  return 0

proc FromString(sud:string):Sudoku =
  return Sudoku(cnt:sud.map(proc(a:char):int= Translate(a)))

#
# Solves sudoku by brute force
#
#
proc SolveSudoku(input: Sudoku,RandomSolve:bool = false):Sudoku=
  var Repr:Masks = input.newMasks
  var SudokuKind:int = input.GetKind()
  var square_map = square_map_global[SudokuKind]
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
  var GetPossi: (proc (mask:int,taken:int,size:int):int) = GetSupPossi

  if RandomSolve:
    GetPossi = RandomPossi

  while pos < mx:

    tmp_pos = abs(pos) - 1
    if Done.cnt[tmp_pos] == sud.cnt[tmp_pos] and Done.cnt[tmp_pos] != 0:
      inc pos
    else:
      inc iterations
      CandMask = (Repr.row[tmp_pos div 9]).bitor(Repr.collum[tmp_pos mod 9],Repr.square[square_map[tmp_pos]])
      Cand = GetPossi(CandMask, sud.cnt[tmp_pos],SudokuKind)
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

#
#
# Solves sudoku the naiive way, i use it check will make a hybrid solver later, 
# that uses that approach to nail sure solutions and brute forces the rest
#
#

proc NaiiveSolver(input:Sudoku):(bool,Sudoku ){.discardable.}=  
  var Repr:Masks = input.newMasks
  var SudokuKind:int = input.GetKind()
  var square_map = square_map_global[SudokuKind]
  var Done = input
  var sud:Sudoku = deepCopy(input)
  var CandMask:int
  var Cand:int
  var IsSolved:bool = false

  while IsSolved == false:
    IsSolved = true
    for pos in 0..sud.cnt.high():
      if Done.cnt[pos] == sud.cnt[pos] and Done.cnt[pos] != 0:
        continue
      else:
        CandMask = (Repr.row[pos div 9]).bitor(Repr.collum[pos mod 9],Repr.square[square_map[pos]])
        if countSetBits(CandMask) == SudokuKind - 1:
          Is_Solved = false
          Cand = GetSupPossi(CandMask,0,SudokuKind)
          CandMask = (not CandMask)
          Repr.row[pos  div 9] = Repr.row[pos div 9].bitor(CandMask)
          Repr.collum[pos mod 9] = Repr.collum[pos mod 9].bitor(CandMask)
          Repr.square[square_map[pos]] = Repr.square[square_map[pos]].bitor(CandMask)
          sud.cnt[pos] = Cand;
  if sud.cnt.contains(0):
    return (false,sud)
  return (true,sud)

proc LoadFromIndex(sud:var Sudoku,ind:int,sq_data:seq[int],sq_side:int)=
  var counter:int=0
  for i in ind..<(sq_side+ind):
    for j in 0..<sq_side:
      sud.cnt[i + j*sq_side*sq_side] = sq_data[counter]
      inc counter

proc SolvableWithoutIndex(input:var Sudoku,ind:int):bool=
  var store:int = input.cnt[ind]
  input.cnt[ind] = 0
  var solvable:bool
  var res:Sudoku
  (solvable,res) = NaiiveSolver(input)
  if not solvable :
    input.cnt[ind] = store
  return solvable 


proc GenerateSudoku(square_size:int = 9):Sudoku=
  randomize()
  var res:Sudoku
  var full_size:int = square_size * square_size
  var sq:int = pow(square_size.float ,0.5).int
  var diagonal_suare_seed:seq[int] = toSeq(1..square_size)
  var random_order_remove:seq[int] = toSeq(0..<81)
  var removed:int = 0
  diagonal_suare_seed.shuffle()
  random_order_remove.shuffle()
  res.cnt.setLen(full_size)
  # fill sudoku's diagonal
  for i in 0..<sq:
    diagonal_suare_seed.shuffle()
    var ind:int= i * (sq ^ 3).int + i*sq
    res.LoadFromIndex(ind,diagonal_suare_seed,sq)
  # solve the sudoku so it fills the rest <100,000 iterations for 9x9, so nothing basically nothing
  res = SolveSudoku(res)

  for i in items(random_order_remove):
    echo i , " ", res.SolvableWithoutIndex(i).int
    removed = removed + res.SolvableWithoutIndex(i).int

  echo "removed ",removed

  for i in 0..<maxSud:
    echo res.cnt[(i*maxSud)..<((i+1)*maxSud)]

  return res

if isMainModule:
  #var test ="812003649943680175675491283154207896369840701287069034521074368438506917796018052"
  #var test = "800000000003600000070090200050007000000045700000100030001000068008500010090000400"
  #echo SolveSudoku(FromString(test))
  #var res:Sudoku
  #var tmp:bool
  #(tmp , res) = NaiiveSolver(FromString(test))

  #for i in 0..<maxSud:
  #  echo res.cnt[(i*maxSud)..<((i+1)*maxSud)]

  discard GenerateSudoku()


