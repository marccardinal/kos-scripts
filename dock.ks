@lazyglobal off.

parameter port, manDist to 25, rotation to 0.

runoncepath("lib/libfacediff").
runoncepath("lib/libsasrcsstack").
runoncepath("lib/libvecdraw").

clearVecDraws().
local highlightPort to highlight(port, rgb(0, 1, 1)).
set highlightPort:enabled to true.

local lock tgtDist to manDist.
local lock desiredPosition to port:nodeposition + tgtDist * port:portfacing:vector.

local lastTime to time:seconds.
local lastDist to port:nodeposition:mag.
local lastTopDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:starvector, desiredPosition)). 
local lock lastTopDist to lastTopDistVec:mag.
local lastStarDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:topvector, desiredPosition)). 
local lock lastStarDist to lastStarDistVec:mag.

wait 0.05.

local curTime to time:seconds.
local curDist to port:nodeposition:mag.
local lock distRate to (curDist - lastDist) / (curTime - lastTime).
local curTopDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:starvector, desiredPosition)). 
local lock topVel to (curTopDistVec - lastTopDistVec) / (curTime - lastTime).
local lock curTopDist to curTopDistVec:mag.
local lock topRate to (curTopDist - lastTopDist) / (curTime - lastTime).
local curStarDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:topvector, desiredPosition)). 
local lock starVel to (curStarDistVec - lastStarDistVec) / (curTime - lastTime).
local lock curStarDist to curStarDistVec:mag.
local lock starRate to (curStarDist - lastStarDist) / (curTime - lastTime).

local desPosDraw to vecdraw(port:nodeposition, desiredPosition - port:nodeposition, rgb(1, 0, 0)).
local topDistVecDraw to vecdraw(ship:position, V(0, 0, 0), rgb(0, 1, 0)).
local starDistVecDraw to vecdraw(ship:position, V(0, 0, 0), rgb(0, 0, 1)).
local tgtRotVecDraw to vecdraw(port:nodeposition, 3 * port:rotation:vector, rgb(1, 1, 0)).
local topVecDraw to vecdraw(ship:position, 3 * ship:facing:topvector, rgb(1, 1, 0)).

function dock_updateDists {
  set lastTime to curTime.
  set lastDist to curDist.
  set lastTopDistVec to curTopDistVec.
  set lastStarDistVec to curStarDistVec.

  set curTime to time:seconds.
  set curDist to port:nodeposition:mag.
  set curTopDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:starvector, desiredPosition)). 
  set curStarDistVec to vxcl(ship:facing:vector, vxcl(ship:facing:topvector, desiredPosition)). 
}

function dock_updateVecDraws {
  parameter showDetailVecs.
  updateVecDraw(desPosDraw, port:nodeposition, desiredPosition - port:nodeposition, true).
  updateVecDraw(topDistVecDraw, ship:position, curTopDistVec, showDetailVecs).
  updateVecDraw(starDistVecDraw, ship:position, curStarDistVec, showDetailVecs).
  updateVecDraw(tgtRotVecDraw, port:nodeposition, 3 * port:rotation:vector, showDetailVecs).
  updateVecDraw(topVecDraw, ship:position, 3 * ship:facing:topvector, showDetailVecs).
}

function dock_setFore {
  parameter tgtRate.
  set ship:control:fore to max(-1, min(1, 10 * (distRate -  tgtRate))).
  //print "curDist: " + curDist + " distRate: " + distRate + " tgtRate: " + tgtRate.
}

function dock_setTop {
  parameter tgtTopRate.
  local topScale to max(-1, min(1, 20 * (topRate - tgtTopRate))).
  local topSign to 1.
  if vang(ship:facing:topvector, curTopDistVec) > 90 { set topSign to -1.  }
  print "curTopDist: " + curTopDist + " top rate: " + topRate + " tgtTopRate: " + tgtTopRate + " top: " + (topSign * topScale).
  set ship:control:top to max(-1, min(1, topSign * topScale)).
}

function dock_setStar {
  parameter tgtStarRate.
  local starScale to max(-1, min(1, 20 * (starRate - tgtStarRate))).
  local starSign to 1.
  if vang(ship:facing:starvector, curStarDistVec) > 90 { set starSign to -1.  }
  print "curStarDist: " + curStarDist + " star rate: " + starRate + " tgtStarRate: " + tgtStarRate + " star: " + (starSign * starScale).
  set ship:control:starboard to max(-1, min(1, starSign * starScale)).
}

print "Moving to maneuver distance".
runpath("closeapproach", port, manDist).

pushRCS(true).
pushSAS(false).

print "Facing target".
lock steering to lookdirup(port:nodeposition, angleaxis(rotation, port:nodeposition) * port:rotation:vector).
wait until faceDiff(true) < 0.5.

print "Lining up".
until desiredPosition:mag < 0.5 {
  // move to in front of the target docking port
  dock_updateDists().
  dock_setFore(max(-2, min(2, (tgtDist - curDist) / 20))).
  dock_setTop(-curTopDist / 50).
  dock_setStar(-curStarDist / 50).
  dock_updateVecDraws(true).
  wait 0.05.
}

print "Moving in to dock".
until port:state <> "Ready" {
  // move in to dock
  lock tgtDist to curDist.
  dock_updateDists().
  dock_setFore(-0.2).
  local topStarScale to 50.
  if curDist < 10 { set topStarScale to 200. }
  dock_setTop(-curTopDist / topStarScale).
  dock_setStar(-curStarDist / topStarScale).
  dock_updateVecDraws(true).
  wait 0.05.
}

popRCS().
popSAS().
unlock steering.
set highlightPort:enabled to false.
clearVecDraws().
