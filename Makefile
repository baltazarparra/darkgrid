# caipora — harness commands (single source of truth)
# Override the Godot binary with: make test GODOT=/path/to/godot
GODOT   ?= $(HOME)/.local/bin/godot
PROJECT := .

.PHONY: help smoke test export gate

help: ## list available targets
	@grep -hE '^[a-z]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t-/' | sort

smoke: ## boot the game headless for ~50 frames and exit (smoke test)
	timeout 60 $(GODOT) --headless --path $(PROJECT) --quit-after 50

test: ## run the GUT regression gate
	$(GODOT) --headless --path $(PROJECT) -s res://addons/gut/gut_cmdln.gd \
		-gdir=res://tests/unit -gprefix=test_ -gsuffix=.gd -gexit

export: ## build the reproducible HTML5 release
	mkdir -p export
	$(GODOT) --headless --path $(PROJECT) --export-release "Web" export/index.html

gate: smoke test ## full verification before commit
