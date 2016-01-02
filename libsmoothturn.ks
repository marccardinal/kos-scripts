@lazyglobal off.

function smoothScalarBasedTurn {
  // TODO: allow endVal < startVal
  // (e.g. start a high altitude, finish at low altitude)
  parameter curVal, startVal, endVal, startVec, endVec, upVec.

  if curVal < startVal {
    return lookdirup(startVec, upVec).
  } else if curVal > endVal {
    return lookdirup(endVec, upVec).
  } else {
    local frac to (curVal - startVal) / (endVal - startVal).
    local pointVec to frac * endVec + (1 - frac) * startVec.
    return lookdirup(pointVec, upVec).
  }
}
