class_name Palette

# The game's shared colors, sampled from the art so code-drawn UI matches the sprites.
# Use these instead of new Color() literals; add a name here if something new is needed.

# Wooden boards and round buttons
const BOARD := Color(0.68, 0.54, 0.39)          # board face (uiBG1Sprite)
const BOARD_LIGHT := Color(0.83, 0.68, 0.5)     # board rim and button discs
const BOARD_DARK := Color(0.38, 0.25, 0.18)     # board shadow side
const INK := Color(0.16, 0.11, 0.08)            # outlines on every sprite
const WOOD_INK := Color(0.24, 0.13, 0.05)       # softer brown for UI borders and text edges

# Text
const CREAM := Color(1.0, 0.96, 0.86)           # painted board text and light panels
const GOLD := Color(1.0, 0.84, 0.4)             # headings, stars, selected borders
const MUTED := Color(0.6, 0.5, 0.45)            # disabled and "off" states

# Button icons (playButtonSprite, exitButtonSprite)
const GO_GREEN := Color(0.8, 0.83, 0.37)
const STOP_RED := Color(0.75, 0.4, 0.4)

# Text button fills
const ORANGE := Color(0.93, 0.6, 0.35)
const BLUE := Color(0.45, 0.62, 0.85)
const GREEN := Color(0.55, 0.74, 0.43)
const PINK := Color(0.85, 0.5, 0.65)

# Fruit, from each fruit sprite
const STRAWBERRY := Color(0.9, 0.39, 0.39)
const MANGO := Color(0.96, 0.72, 0.42)
const BLUEBERRY := Color(0.4, 0.57, 0.76)
const BANANA := Color(0.98, 0.84, 0.46)
const APPLE := Color(0.96, 0.45, 0.35)

# Feedback popups
const GOOD := Color(0.6, 1.0, 0.6)
const BAD := Color(1.0, 0.55, 0.5)
