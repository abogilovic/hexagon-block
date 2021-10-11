extends Node

var level = 1

func getLevel():
	return level

func getSkin():
	return 1
	
func onGameReady():
	print("Event onGameReady")
	print("GAME")

func onLevelComplete(isLevelSuccess, coins=0):
	print("Event onLevelComplete:", isLevelSuccess)
	print("GAME")
	if isLevelSuccess:
		level+=1
	get_tree().get_current_scene().playLevel(getLevel())

func BuyInGameItem(price,itemName = "item"):
	return true
