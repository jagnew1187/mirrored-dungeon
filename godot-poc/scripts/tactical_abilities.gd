extends "res://scripts/abilities.gd"
func activate(index: int) -> bool:
 if index<0 or index>1: return false
 if game.tactical.active and not game.tactical.resolving:
  return game.tactical.skill(index)
 if not game.tactical.active and (game.menu_open or game.fallen or remaining[index]>0 or active>=0): return false
 if not game.tactical.active and DATA[game.selected][index].has("damage") and game.try_tactical(DATA[game.selected][index].range): return true
 return super.activate(index)
