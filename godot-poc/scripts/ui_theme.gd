extends RefCounted
## Original iron/bronze palette. Shared theme; no external game artwork.
const INK=Color("171a20")
const PAPER=Color("e6ddc6")
const MUTED=Color("a5a496")
const GOLD=Color("b79a60")
static var cached: Theme
static var icons: Dictionary={}
static func panel(color: Color=INK, margin:=14, edge: Color=GOLD) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=edge;s.set_border_width_all(2)
	s.content_margin_left=margin;s.content_margin_right=margin;s.content_margin_top=margin;s.content_margin_bottom=margin
	s.shadow_color=Color(0,0,0,.45);s.shadow_size=4
	return s
static func rarity(value: String) -> Color:
	return {"Common":PAPER,"Uncommon":Color("8ec5a6"),"Improved":Color("8ec5a6"),"Rare":Color("85bfff"),"Epic":Color("cc9afa"),"Legendary":Color("ffc075")}.get(value,PAPER)
static func item_icon(id: String) -> Texture2D:
	var key: String="item:"+id
	if not icons.has(key):
		var index: int=preload("res://scripts/items.gd").ITEMS[id].icon
		var texture:=AtlasTexture.new();texture.atlas=load("res://assets/pass10/gear-atlas.png");texture.region=Rect2(index%10*64,index/10*64,64,64);icons[key]=texture
	return icons[key]
static func icon(category: String) -> Texture2D:
	var key: String={"sword":"weapon","focus":"focus","dagger":"dagger","cloth":"armor","light armor":"armor","charm":"accessory","clasp":"accessory","consumable":"tonic"}.get(category,category)
	if not icons.has(key): icons[key]=load("res://assets/pass09/"+key+".svg")
	return icons[key]
static func build() -> Theme:
	if cached: return cached
	cached=Theme.new();cached.default_font_size=17
	for type in ["Label","Button","CheckButton","LineEdit","OptionButton"]: cached.set_color("font_color",type,PAPER)
	for type in ["Button","OptionButton"]:
		cached.set_stylebox("normal",type,panel(Color("282b30"),10,Color("625b49")))
		cached.set_stylebox("hover",type,panel(Color("3b3d40"),10,GOLD))
		cached.set_stylebox("pressed",type,panel(Color("4d4535"),10,GOLD))
		cached.set_stylebox("disabled",type,panel(Color("1c1e22"),10,Color("454641")))
		var focus:=panel(Color(0,0,0,0),0,Color("f1cf85"));focus.set_border_width_all(3);cached.set_stylebox("focus",type,focus)
		cached.set_color("font_disabled_color",type,Color("8e9089"))
	cached.set_stylebox("panel","PanelContainer",panel())
	cached.set_stylebox("normal","LineEdit",panel(Color("101318"),10))
	cached.set_stylebox("background","ProgressBar",panel(Color("101318"),0,Color("544e40")))
	cached.set_stylebox("fill","ProgressBar",panel(Color("9e4442"),0,Color("b75b51")))
	cached.set_constant("separation","VBoxContainer",10);cached.set_constant("separation","HBoxContainer",12)
	return cached
