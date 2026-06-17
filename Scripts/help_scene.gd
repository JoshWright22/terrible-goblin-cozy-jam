extends Node2D

var maxPage = 4

@onready var page1 = $pg1
@onready var page2 = $pg2
@onready var page3 = $pg3
@onready var page4 = $pg4

var page : int = 1


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func changePage(pages):
	match pages:
		1:
			page1.visible = true
			page2.visible = false
			page3.visible = false
			page4.visible = false
		2:
			page1.visible = false
			page2.visible = true
			page3.visible = false
			page4.visible = false
		3:
			page1.visible = false
			page2.visible = false
			page3.visible = true
			page4.visible = false
		4:
			page1.visible = false
			page2.visible = false
			page3.visible = false
			page4.visible = true

func _on_button_2_button_down() -> void:
	page = page + 1 
	page = clamp(page, 1, maxPage)
	changePage(page)


func _on_button_button_down() -> void:
	page = page - 1
	page = clamp(page, 1, maxPage)
	changePage(page)
