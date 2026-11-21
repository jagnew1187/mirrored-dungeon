extends RefCounted
## Read-only projection of existing campaign facts; no quest mutations.
static func entries(model: RefCounted) -> Array[Dictionary]:
	var q: String=model.data.quest
	return [
		{"title":"A word with Mara","area":"Vigil · Mara","body":"Speak to Mara at the refuge before taking Old Mill Road.","done":q!="meet_mara"},
		{"title":"Break the mill patrol","area":"Old Mill Road · marked guards","body":"Defeat the two marked patrol guards. Roaming enemies and the optional Enforcer are separate encounters.","done":model.data.defeated.has("captain") and model.data.defeated.has("escort")},
		{"title":"Recover the flour","area":"Old Mill Road · mill sacks","body":"Collect the flour after defeating the patrol.","done":model.data.get("recovered",false) or q in ["deliver","done"]},
		{"title":"Bread before blades","area":"Bannerfall · Anja's bakery","body":"Take the southeast road to Bannerfall and return Anja's flour. Reward once: 100 XP, 35 coins and a baker's keepsake.","done":q=="done" and model.data.claims.has("bread")}
	]
