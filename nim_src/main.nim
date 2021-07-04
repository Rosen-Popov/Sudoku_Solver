

const Sudoku_cell_size:int = 3

proc GenCellMatr(cell_size :int):seq[int]=
  result = newSeq[int](0)
  for i in 0..cell_size-1:
    var r: seq[int]
    for j in 0..cell_size-1:
      var s: seq[int]
      s.setLen(cell_size)
      for k in mitems(s):
        k = i*cell_size + j
        

  return result

