class_name Tips

# Shown after losing or finishing a day short of three stars

const ALL := [
	"Pack the blender: a full one pays up to 7 times more than a nearly empty one.",
	"Match the order's percentages closely. Accuracy multiplies every smoothie's score.",
	"Every fruit in the order has to be in the cup, or the customer won't pay.",
	"Right click to turn a piece before you drop it in.",
	"Pieces can come back out of the blender if they don't fit your plan.",
	"Serve customers while they're smiling. Happy customers give back more health.",
	"Each customer who walks out costs health, so serve the longest waiting first.",
	"RUSH customers leave fast but pay double. VIPs pay triple.",
	"Work one order per blender so you're never scrambling for the last one.",
]

static func random() -> String:
	return "Tip: " + ALL.pick_random()
