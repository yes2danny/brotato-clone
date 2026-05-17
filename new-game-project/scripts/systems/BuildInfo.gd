class_name BuildInfo

const GAME_VERSION := "v0.1.0"
const BUILD_ID := "01z"


static func display_text() -> String:
	return "%s • build %s" % [GAME_VERSION, BUILD_ID]
