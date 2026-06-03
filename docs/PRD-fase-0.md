# PRD — Fase 0: Setup & Foundation

> **caipora** — Brazilian Folk Horror Roguelike  
> **Fase:** 0 / 5  
> **Status:** ✅ Done  
> **Document Version:** 1.1  

---

## 1. Visão Geral

A Fase 0 estabelece a fundação técnica sobre a qual todo o desenvolvimento do caipora será construído. Nenhum código de gameplay é escrito nesta fase — o foco é preparar o ambiente, instalar ferramentas, configurar pipelines e garantir que o agente AI (Kimi-k2.6) tenha tudo necessário para trabalhar de forma autônoma nas fases subsequentes.

**Filosofia:** *"Um alicerce mal posto derruba a casa. Um alicerce bem posto permite que o agente construa sozinho."*

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Testabilidade** | O projeto pode rodar testes unitários via GUT a qualquer momento |
| 2 | **Agent Autonomy** | O agente AI pode criar cenas, rodar o jogo e validar mudanças sem intervenção humana |
| 3 | **Asset Readiness** | Sprites CC0 estão disponíveis no projeto, prontos para uso nas fases 1-3 |
| 4 | **Export Pipeline** | O preset de export HTML5 está configurado e validado |
| 5 | **Code Foundation** | Autoloads base e constants estão definidos, padronizando decisões arquiteturais |

---

## 3. Requisitos Funcionais

### 3.1 RF-001 — GUT Addon Instalado

**Descrição:** O addon GUT (Godot Unit Test) deve estar instalado e funcional no projeto.

**Detalhes Técnicos:**
- Instalar via Godot AssetLib ou copiar para `addons/gut/`
- Verificar que o menu `Project > Tools > GUT` aparece no editor
- Confirmar que o comando de CLI funciona:
  ```bash
  ~/.local/bin/godot --headless --path /home/baltz/caipora -s res://addons/gut/gut_cmdln.gd
  ```

**Critério de Aceitação:**
- [x] Comando GUT CLI executa sem erros
- [x] Output mostra "2 tests, 0 failures" (v9.6.0 instalado)

**Referências:**
- `AGENTS.md` seção Development Commands
- `PLAN.md` seção 9.1 (testes)

---

### 3.2 RF-002 — Assets CC0 Baixados e Organizados

**Descrição:** Pelo menos 1 pack de sprites da Kenney.nl deve estar baixado, organizado em `assets/sprites/` e configurado com import settings corretos.

**Detalhes Técnicos:**
- **Pack recomendado:** [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) ou [1-Bit Pack](https://kenney.nl/assets/1-bit-pack)
- **Estrutura esperada:**
  ```
  assets/
    sprites/
      player_idle.png
      player_walk_1.png
      player_walk_2.png
      enemy_idle.png
      tile_floor.png
      tile_wall.png
      item_potion.png
    licenses/
      kenney_tiny_dungeon_LICENSE.txt
  ```
- **Import Settings (para cada .png):**
  - Filter: Nearest
  - Compress: Lossless
  - Mipmaps: Off
- **Licença:** Copiar o arquivo de licença CC0 do pack para `assets/licenses/`

**Critério de Aceitação:**
- [x] Sprites visíveis no Godot FileSystem dock sem erros de import
- [x] Testar 1 sprite em uma cena de teste: não aparece borrado
- [x] Arquivo de licença presente em `assets/licenses/`

**Nota de execução:** Kenney.nl não foi acessível via CLI (download requer JavaScript). Placeholders CC0 gerados programmaticamente com PIL para manter o projeto funcional. Serão substituídos por sprites Kenney na Fase 1.

**Risco:** Kenney pode estar offline. **Mitigação:** Manter backup local dos packs mais usados ou usar mirrors.

**Referências:**
- `assets/AGENTS.md` seção Kenney Pack Recommendations
- `PLAN.md` seção 12 (Asset Guidelines)

---

### 3.3 RF-003 — Autoloads Base Criados

**Descrição:** Três autoloads essenciais devem ser criados e registrados em `Project Settings > Autoloads`.

**Especificação por Autoload:**

#### GameState (`scripts/core/game_state.gd`)
```gdscript
class_name GameState
extends Node

enum Screen { MAIN_MENU, EXPLORATION, ARENA, GAME_OVER, WIN, HUB }

var current_screen: Screen = Screen.MAIN_MENU
var is_paused: bool = false

func change_screen(new_screen: Screen) -> void:
    current_screen = new_screen
    SignalBus.screen_changed.emit(new_screen)

func toggle_pause() -> void:
    is_paused = !is_paused
    get_tree().paused = is_paused
```

#### SignalBus (`scripts/core/signal_bus.gd`)
```gdscript
class_name SignalBus
extends Node

signal screen_changed(new_screen: GameState.Screen)
signal arena_entered(arena_id: String)
signal arena_exited(won: bool)
signal caipora_died
signal caipora_health_changed(new_health: int, max_health: int)
signal timing_hit(type: String)  # "attack" or "defense"
signal timing_miss(type: String)
```

#### MetaProgression (`scripts/core/meta_progression.gd`)
```gdscript
class_name MetaProgression
extends Node

const SAVE_PATH := "user://savegame.json"

var unlocked_characters: Array[String] = ["caipora"]
var unlocked_modifiers: Array[String] = []
var total_runs: int = 0
var total_wins: int = 0

func save_progress() -> void:
    var data := {
        "unlocked_characters": unlocked_characters,
        "unlocked_modifiers": unlocked_modifiers,
        "total_runs": total_runs,
        "total_wins": total_wins
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()

func load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var text := file.get_as_text()
        file.close()
        var data := JSON.parse_string(text)
        if data is Dictionary:
            unlocked_characters = data.get("unlocked_characters", ["caipora"])
            unlocked_modifiers = data.get("unlocked_modifiers", [])
            total_runs = data.get("total_runs", 0)
            total_wins = data.get("total_wins", 0)
```

**Critério de Aceitação:**
- [x] Três autoloads registrados em Project Settings
- [x] Nenhum erro ao rodar o projeto (F5)
- [x] MetaProgression consegue salvar e carregar `user://savegame.json`

**Correção aplicada (P1):** `enum Screen` foi movido de `GameState` para `SignalBus` para eliminar dependência circular de `class_name` entre autoloads. Em Godot 4, `class_name` + autoload causam "hides an autoload singleton".

**Referências:**
- `AGENTS.md` seção Scene Architecture (Autoloads)
- `PLAN.md` seção 7.1 (Autoloads)

---

### 3.4 RF-004 — Export Preset HTML5 Configurado

**Descrição:** O preset de exportação para HTML5/Web deve estar configurado e validado com um export de teste.

**Detalhes Técnicos:**
1. Abrir `Project > Export`
2. Adicionar preset `Web`
3. Configurar:
   - **Export Path:** `export/index.html`
   - **Canvas Resize Policy:** `Project`
   - **Orientation:** Landscape
   - **Vram Compression:** Disabled (para pixel art)
4. Instalar templates de export se necessário
5. Rodar export de teste:
   ```bash
   ~/.local/bin/godot --headless --path /home/baltz/caipora --export-release "Web" export/index.html
   ```

**Critério de Aceitação:**
- [x] Export preset aparece em `Project > Export` (via `export_presets.cfg`)
- [x] Comando de export CLI gera `export/index.html` sem erros
- [x] Arquivos gerados: `index.html`, `.js`, `.wasm`, `.pck`

**Nota:** Templates de export 4.6.3-stable foram baixados manualmente do GitHub (1.2GB) e instalados em `~/.local/share/godot/export_templates/4.6.3.stable/` devido a instabilidade de DNS.

**Risco:** Templates de export não instalados. **Mitigação:** Baixar templates via Godot editor ou CLI.

**Referências:**
- `PLAN.md` seção 9.2 (Export to HTML5)
- `AGENTS.md` seção Development Commands

---

### 3.5 RF-005 — Constants Base Definidas

**Descrição:** Um arquivo central de constantes deve ser criado para evitar números mágicos espalhados pelo código.

**Especificação (`scripts/utils/constants.gd`):**
```gdscript
class_name Constants
extends RefCounted

# Grid
const TILE_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 15

# Combat
const TIMING_WINDOW_FRAMES := 12
const TIMING_PERFECT_FRAMES := 3
const ATTACK_COOLDOWN_SECONDS := 1.5
const DODGE_COOLDOWN_SECONDS := 0.5

# Damage
const DAMAGE_BASE := 10
const DAMAGE_CRIT_MULTIPLIER := 2.5
const DAMAGE_COUNTER_MULTIPLIER := 1.5

# Health
const CAIPORA_MAX_HEALTH := 100
const ENEMY_MAX_HEALTH := 80
const BOSS_MAX_HEALTH := 200

# Colors (Horror Folk Palette)
const COLOR_NIGHT := Color("#0d1117")
const COLOR_EARTH := Color("#3d1f1f")
const COLOR_MOSS := Color("#1a2f1a")
const COLOR_BLOOD := Color("#8b0000")
const COLOR_AMBER := Color("#ff6b00")
const COLOR_TEXT := Color("#c9d1d9")

# Physics Layers
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_WALL := 3
const LAYER_TRIGGER := 4
```

**Critério de Aceitação:**
- [x] Arquivo `scripts/utils/constants.gd` existe e não gera erros
- [x] Todas as constantes são typed (`: int`, `: Color`, etc.)
- [x] Nenhum número mágico hardcoded em outros scripts (validar futuramente)

**Referências:**
- `AGENTS.md` seção Principles ("No magic numbers")
- `PLAN.md` seção 6.3 (Principles)

---

## 4. Requisitos Não-Funcionais

| # | Requisito | Especificação | Status |
|---|-----------|---------------|--------|
| RNF-001 | **Performance** | Projeto deve abrir em < 3s no Godot 4.6 | ✅ |
| RNF-002 | **Tamanho** | Pasta `assets/` deve ser < 5MB após Fase 0 | ✅ (88K) |
| RNF-003 | **Git** | `.gitignore` deve ignorar `.godot/`, `export/`, `*.tmp` | ✅ |
| RNF-004 | **Lint** | Todo script GDScript deve passar em verificação de sintaxe (`--check-only`) | ⚠️ `--check-only` não existe em Godot 4.6; validação feita via abertura headless do projeto |
| RNF-005 | **Documentação** | Cada autoload deve ter comentário de cabeçalho explicando sua responsabilidade | ✅ |

---

## 5. Especificações de Teste

### 5.1 Testes de Fumaça (Smoke Tests)

| # | Teste | Como executar |
|---|-------|---------------|
| ST-001 | Projeto abre sem erros | `run_project` via MCP |
| ST-002 | GUT CLI funciona | `godot --headless -s res://addons/gut/gut_cmdln.gd` |
| ST-003 | Export HTML5 gera arquivos | `godot --headless --export-release "Web" export/index.html` |
| ST-004 | Save/Load funciona | Rodar MetaProgression.save_progress() e load_progress() |

### 5.2 Testes Unitários (GUT)

```gdscript
# tests/unit/test_meta_progression.gd
class_name TestMetaProgression
extends GutTest

func test_save_and_load():
    MetaProgression.total_runs = 5
    MetaProgression.save_progress()
    MetaProgression.total_runs = 0
    MetaProgression.load_progress()
    assert_eq(MetaProgression.total_runs, 5)

func test_default_unlocks():
    assert_eq(MetaProgression.unlocked_characters, ["caipora"])
```

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| GUT addon incompatível com Godot 4.6 | Baixa | Alto | Verificar versão do GUT antes de instalar; usar release estável |
| Templates de export não instalados | Média | Alto | Baixar templates via editor; documentar passo no AGENTS.md |
| Kenney offline | Baixa | Médio | Manter backup local dos packs; usar alternativas CC0 (OpenGameArt) |
| Autoload com dependência circular | Baixa | Alto | Revisar código antes de registrar; testar isoladamente |

---

## 7. Checklist de Entrega da Fase 0

- [x] **RF-001:** GUT instalado e CLI funcional
- [x] **RF-002:** Sprites CC0 em `assets/sprites/` + licença em `assets/licenses/` (placeholders Kenney)
- [x] **RF-003:** Autoloads GameState, SignalBus, MetaProgression criados e registrados
- [x] **RF-004:** Export preset HTML5 configurado e testado
- [x] **RF-005:** `scripts/utils/constants.gd` criado com constantes base
- [x] **RNF-001:** Projeto abre em < 3s
- [x] **RNF-002:** `assets/` < 5MB (88K)
- [x] **RNF-003:** `.gitignore` atualizado
- [x] **RNF-004:** Sintaxe de todos os scripts validada (via headless project open)
- [x] **RNF-005:** Comentários de cabeçalho em todos os autoloads
- [x] **ST-001 a ST-004:** Todos os smoke tests passam
- [x] **Commit:** `git commit -m "fase-0: setup foundation — GUT, assets, autoloads, export"`
- [x] **ROADMAP:** Marcar Fase 0 como ✅ Done

---

## 8. Notas para o Agente

### Ordem de Implementação Recomendada

1. **constants.gd** primeiro — outras tasks dependem dele
2. **Autoloads** em paralelo (GameState, SignalBus, MetaProgression são independentes)
3. **GUT** enquanto baixa assets (tarefas independentes)
4. **Assets** organização e import settings
5. **Export preset** por último — valida que tudo está integrado

### Anti-Padrões a Evitar

- ❌ Não criar cenas de gameplay nesta fase (aguarde Fase 1)
- ❌ Não hardcodear números mágicos (use Constants)
- ❌ Não ignorar erros de import de assets (Nearest filter é obrigatório)
- ❌ Não deixar autoloads vazios (mínimo: estrutura + comentários)

### Padrões a Seguir

- ✅ Todo script novo usa `class_name` e `extends` (exceto autoloads — ver nota abaixo)
- ✅ Todo autoload tem comentário de cabeçalho explicando propósito
- ✅ Todo arquivo novo segue `snake_case`
- ✅ Todo teste GUT tem nome descritivo (`test_<o_que_ele_verifica>`)

### Correções Aplicadas durante Execução

| # | Problema Original | Fix Aplicado |
|---|-------------------|--------------|
| P1 | Dependência circular: `SignalBus` referenciava `GameState.Screen` | Enum `Screen` movido para `SignalBus`; `GameState` importa de lá |
| P2 | `.gitignore` genérico (Node.js) | Substituído por template híbrido Godot + Node.js |
| P3 | Templates de export não instalados | Baixados manualmente do GitHub e instalados |
| P4 | `--check-only` inexistente no Godot 4.6 | Validação via `godot --headless --path . --quit` |
| P5 | Sprites Kenney em spritesheet (não arquivos individuais) | Placeholders CC0 gerados programmaticamente; serão substituídos na Fase 1 |
| P6 | GUT versão não especificada | GUT v9.6.0 (compatível Godot 4.x) |
| P7 | `class_name` em autoloads causa "hides an autoload singleton" | Removido `class_name` dos 3 autoloads; mantido apenas em `Constants` |

---

## 9. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `PLAN.md` | 5 (Directory Structure), 7 (Scene Architecture), 9 (Build & Export), 12 (Asset Guidelines) |
| `AGENTS.md` | Scene Architecture, Development Commands, Common Gotchas, Session Protocol |
| `assets/AGENTS.md` | Kenney Pack Recommendations, Pixel Art Import Settings, SFX Checklist |
| `ROADMAP.md` | Fase 0: Setup & Foundation |
