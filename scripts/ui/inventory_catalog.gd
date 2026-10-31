class_name InventoryCatalog
extends RefCounted
const ITEMS := {
	"lanterna":["Lanterna","Ferramentas","flashlight","Lanterna de mão. Ajuda a explorar áreas escuras; não elimina o perigo."],
	"fusivel":["Fusível","Missão","fuse","Cartucho elétrico. Encaixa em um painel compatível."],
	"cartao":["Cartão de segurança","Missão","security_card","Credencial da instalação. Use em um leitor compatível energizado."],
	"chave_oficina":["Chave enferrujada","Chaves","key","Uma chave antiga de metal. Procure uma fechadura correspondente."],
	"tutorial_key":["Chave de treino","Chaves","key","Chave emprestada da sala de preparação. Não será levada ao complexo."],
	"tutorial_mark":["Selo de inspeção","Missão","security_card","Selo encontrado com a lanterna. Material de treino."],
	"throwables":["Sucata para arremesso","Recursos","can","Objetos metálicos para distrair. O impacto produz ruído na posição em que caem."]
}
static func data(id: String) -> Dictionary:
	if id.begins_with("held:") and is_instance_valid(Game.player) and is_instance_valid(Game.player.manipulator.held):
		var profile: ObjectPhysicsProfile = Game.player.manipulator.held.profile
		var model: String = {"tool":"wrench","fragile_crate":"crate","small_crate":"crate"}.get(profile.id,profile.id)
		return {"name":profile.title,"category":"Nas mãos","model":model,"description":"Objeto físico nas mãos. Soltar mantém o objeto real no mundo.","quantity":1,"essential":false}
	var values: Array = ITEMS.get(id,[id,"Missão","mechanical_part","Objeto coletado na instalação."])
	return {"name":values[0],"category":values[1],"model":values[2],"description":values[3],"quantity":int(Game.world.get("throwables",0)) if id=="throwables" else 1,"essential":id!="throwables"}
static func owned() -> Array[String]:
	var result: Array[String] = []
	for id in Game.inventory: result.append(id)
	if int(Game.world.get("throwables",0))>0: result.append("throwables")
	if is_instance_valid(Game.player) and is_instance_valid(Game.player.manipulator.held): result.append("held:"+Game.player.manipulator.held.item_id)
	return result
static func image(id: String) -> Texture2D:
	var path := "res://assets/ui/items/"+str(data(id).model)+".png"
	return load(path) if ResourceLoader.exists(path) else null
