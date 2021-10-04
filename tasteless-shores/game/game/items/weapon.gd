extends "res://game/items/item.gd"

var _model = null
var _distance = 0.1
var _icon

func _init(id: int, model: Spatial, distance: float, icon = null):
	self.id = id
	_model = model
	_distance = distance
	_icon = icon

func icon() -> Texture:
	return _icon

func distance() -> float:
	return _distance

func model() -> Spatial:
	return _model

func attack(collider, from) -> bool:
	return _model.use(collider, from)

func _on_attacked(collider, from):
	if _model.has_method("_on_attacked"):
		_model._on_attacked(collider, from)

func name() -> String:
	return _model.name()
