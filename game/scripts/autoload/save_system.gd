extends Node
## Lê e grava o save em user:// (pasta de dados do usuário; tecnico.md §5).
## Substituir o .exe não toca no save. Antes de migrar um save antigo, guarda uma cópia .bak.

const ARQUIVO := "user://save.json"


func existe() -> bool:
	return FileAccess.file_exists(ARQUIVO)


func salvar(dados: GameData) -> bool:
	var f := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if f == null:
		push_error("não foi possível gravar o save")
		return false
	f.store_string(SaveCodec.codificar(dados))
	f.close()
	return true


## Retorna o mesmo dicionário de SaveCodec.decodificar.
func carregar() -> Dictionary:
	if not existe():
		return {"ok": false, "erro": "nenhum save"}
	var texto := FileAccess.get_file_as_string(ARQUIVO)
	var r := SaveCodec.decodificar(texto)
	if r.get("ok", false) and int(r.get("migrado_de", SaveCodec.VERSAO_ATUAL)) < SaveCodec.VERSAO_ATUAL:
		fazer_backup(texto, int(r["migrado_de"]))
	return r


func fazer_backup(texto: String, versao: int) -> void:
	var f := FileAccess.open("user://save.v%d.bak" % versao, FileAccess.WRITE)
	if f:
		f.store_string(texto)
		f.close()
