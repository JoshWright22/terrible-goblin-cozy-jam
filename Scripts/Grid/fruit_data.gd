extends Resource
class_name FruitData

# Define an Enum for clear string classification in your combination script
enum FruitType { BANANA, STRAWBERRY, BLUEBERRY, WATERMELON, PINEAPPLE, ORANGE, GRAPE }

@export var fruit_name: FruitType = FruitType.STRAWBERRY
@export var texture: Texture2D
@export var layout: Array[Vector2] = [Vector2(0,0)]
