extends GutTest

## Trava o esquema de versão alpha-X.Y.Z: a base alpha-X.Y vive no
## config/version do project.godot (fonte única) e o Z (contagem de commits)
## é carimbado por `make export` em scripts/core/build_info.gd (gitignored).
## Se o fallback do editor ou a versão resolvida pelo menu saírem do esquema,
## este teste quebra antes do número errado chegar na tela.

var _alpha_re := RegEx.create_from_string("^alpha-\\d+\\.\\d+")


func test_project_fallback_version_is_alpha() -> void:
	var fallback := str(ProjectSettings.get_setting("application/config/version", ""))
	assert_not_null(
		_alpha_re.search(fallback),
		"config/version deve começar com alpha-X.Y, veio: '%s'" % fallback
	)


func test_resolved_version_is_alpha() -> void:
	var menu := MainMenu.new()
	var version := menu._resolve_version()
	menu.free()
	assert_not_null(
		_alpha_re.search(version),
		"a versão exibida no menu deve começar com alpha-X.Y, veio: '%s'" % version
	)
