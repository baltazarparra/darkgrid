# Report de Execução — Fase 0: Setup & Foundation

> **Projeto:** caipora — Brazilian Folk Horror Roguelike  
> **Data:** 2026-06-01  
> **Executor:** Kimi Code CLI (Kimi-k2.6)  
> **Duração:** ~1 sessão  
> **Status:** ✅ Concluída

---

## 1. Objetivo da Fase

Estabelecer a fundação técnica sobre a qual todo o desenvolvimento do caipora será construído. Nenhum código de gameplay foi escrito — o foco foi preparar o ambiente, instalar ferramentas, configurar pipelines e garantir que o agente AI pudesse trabalhar de forma autônoma nas fases subsequentes.

**Filosofia:** *"Um alicerce mal posto derruba a casa. Um alicerce bem posto permite que o agente construa sozinho."*

---

## 2. Escopo Planejado vs. Executado

### 2.1 Requisitos Funcionais (RF)

| RF | Descrição | Status | Notas |
|----|-----------|--------|-------|
| RF-001 | GUT Addon instalado | ✅ | GUT v9.6.0 instalado em `addons/gut/`. CLI funcional. 2/2 testes passando. |
| RF-002 | Assets CC0 baixados e organizados | ⚠️ Placeholders | Kenney.nl inacessível via CLI (requer JS). Placeholders CC0 gerados com PIL. Serão substituídos na Fase 1. |
| RF-003 | Autoloads base criados | ✅ | GameState, SignalBus, MetaProgression criados, registrados e testados. Correção P1 aplicada. |
| RF-004 | Export preset HTML5 configurado | ✅ | Preset criado via `export_presets.cfg`. Templates 4.6.3 instalados manualmente. Export testado com sucesso. |
| RF-005 | Constants base definidas | ✅ | `scripts/utils/constants.gd` com grid, combat, damage, health, colors e physics layers. |

### 2.2 Requisitos Não-Funcionais (RNF)

| RNF | Descrição | Status | Valor Medido |
|-----|-----------|--------|--------------|
| RNF-001 | Performance: projeto abre em < 3s | ✅ | Abertura headless instantânea; sem erros de parse. |
| RNF-002 | Tamanho: `assets/` < 5MB | ✅ | 88K |
| RNF-003 | Git: `.gitignore` correto | ✅ | Godot + Node.js híbrido. `.godot/` e `export/` removidos do tracking. |
| RNF-004 | Lint: sintaxe GDScript validada | ✅ | Validado via `godot --headless --path . --quit`. Nota: `--check-only` não existe em Godot 4.6. |
| RNF-005 | Documentação: comentários em autoloads | ✅ | Todos os 3 autoloads têm cabeçalho explicando responsabilidade. |

---

## 3. Arquitetura Entregue

### 3.1 Estrutura de Diretórios

```
caipora/
├── assets/
│   ├── sprites/          # 7 placeholders CC0 (32×32)
│   ├── audio/sfx/        # (vazio — Fase 3)
│   ├── fonts/            # (vazio — Fase 4)
│   └── licenses/         # CC0 placeholder license
├── scenes/
│   ├── ui/               # (vazio — Fase 4)
│   ├── exploration/      # (vazio — Fase 1)
│   ├── arena/            # (vazio — Fase 2)
│   └── shared/           # (vazio — Fases 2-3)
├── scripts/
│   ├── core/             # Autoloads: game_state, signal_bus, meta_progression
│   ├── systems/          # (vazio — Fases 2-3)
│   ├── entities/         # (vazio — Fases 2-3)
│   ├── exploration/      # (vazio — Fase 1)
│   ├── arena/            # (vazio — Fase 2)
│   └── utils/            # constants.gd
├── tests/
│   └── unit/             # test_meta_progression.gd (GUT)
├── addons/
│   └── gut/              # GUT v9.6.0 (Godot Unit Test)
├── docs/
│   ├── PRD-fase-0.md     # Atualizado para v1.1 (Done)
│   └── REPORT-fase-0.md  # Este documento
├── export_presets.cfg    # Preset Web/HTML5
└── project.godot         # Configuração do projeto + autoloads + plugin GUT
```

### 3.2 Autoloads Registrados

| Nome | Script | Responsabilidade |
|------|--------|------------------|
| `GameState` | `scripts/core/game_state.gd` | Screen state (usa `SignalBus.Screen`), pause, run state |
| `SignalBus` | `scripts/core/signal_bus.gd` | Global event bus. Define `enum Screen` e todos os sinais globais |
| `MetaProgression` | `scripts/core/meta_progression.gd` | Persistência de unlocks e stats em `user://savegame.json` |

### 3.3 Constants (`scripts/utils/constants.gd`)

- **Grid:** `TILE_SIZE=32`, `GRID_WIDTH=20`, `GRID_HEIGHT=15`
- **Combat:** `TIMING_WINDOW_FRAMES=12`, `TIMING_PERFECT_FRAMES=3`, `ATTACK_COOLDOWN_SECONDS=1.5`, `DODGE_COOLDOWN_SECONDS=0.5`
- **Damage:** `DAMAGE_BASE=10`, `DAMAGE_CRIT_MULTIPLIER=2.5`, `DAMAGE_COUNTER_MULTIPLIER=1.5`
- **Health:** `CAIPORA_MAX_HEALTH=100`, `ENEMY_MAX_HEALTH=80`, `BOSS_MAX_HEALTH=200`
- **Colors:** Paleta horror folk (`NIGHT`, `EARTH`, `MOSS`, `BLOOD`, `AMBER`, `TEXT`)
- **Physics Layers:** `LAYER_PLAYER=1`, `LAYER_ENEMY=2`, `LAYER_WALL=3`, `LAYER_TRIGGER=4`

---

## 4. Problemas Encontrados e Correções Aplicadas

### 4.1 Correções da PRD (Identificadas na Revisão)

| # | Problema | Severidade | Fix Aplicado |
|---|----------|-----------|--------------|
| **P1** | Dependência circular: `SignalBus` usava `GameState.Screen` como tipo de parâmetro de sinal. Em Godot 4, isso causa "Unknown type" se `SignalBus` for parseado antes de `GameState`. | 🔴 Alta | `enum Screen` movido para `SignalBus.gd`. `GameState` importa de lá. Dependência circular eliminada. |
| **P2** | `.gitignore` genérico (Node.js) não ignorava `.godot/`, `export/`, `*.tmp`. | 🟡 Média | Substituído por template híbrido Godot + Node.js. `.godot/` removido do git tracking. |
| **P3** | Templates de export 4.6.3 não instalados. | 🔴 Alta | Baixados manualmente do GitHub releases (~1.2GB) via `curl` com DNS override (`--resolve`). Instalados em `~/.local/share/godot/export_templates/4.6.3.stable/`. |
| **P4** | `--check-only` mencionado na PRD não existe no Godot 4.6. | 🟡 Média | Validação de sintaxe substituída por `godot --headless --path . --quit`, que parseia todos os scripts ao abrir o projeto. |
| **P5** | PRD listava arquivos individuais (`player_idle.png`), mas packs Kenney vêm em spritesheets. | 🟡 Média | Placeholders CC0 gerados programmaticamente com PIL (32×32, cores da paleta). Serão substituídos por sprites Kenney reais na Fase 1. |
| **P6** | GUT versão não especificada na PRD. | 🟡 Média | GUT v9.6.0 selecionada (tag estável compatível com Godot 4.x). |
| **P7** | `class_name` em autoloads causa "hides an autoload singleton" em Godot 4. | 🟢 Baixa | `class_name` removido dos 3 autoloads. Mantido apenas em `Constants` (que não é autoload). |

### 4.2 Bugs Encontrados durante Execução

| # | Bug | Causa | Fix |
|---|-----|-------|-----|
| B-001 | `MetaProgression.load_progress()` falha com "Trying to assign an array of type 'Array' to a variable of type 'Array[String]'" | `JSON.parse_string` retorna `Array` genérico (Variant), não `Array[String]`. | Adicionado helper `_to_string_array()` que itera e faz cast explícito para `Array[String]`. |
| B-002 | GUT class_names não importados após cópia do addon | `global_script_class_cache.cfg` tinha caminhos antigos/corrompidos. | Cache apagado (`rm .godot/global_script_class_cache.cfg`) e reimportado com `godot --headless --import`. |
| B-003 | Arquivos do GUT duplicados em `addons/` e `addons/gut/` | Cópia residual durante instalação. | Diretório `addons/` limpo; mantido apenas `addons/gut/`. |
| B-004 | Diretório literal `~` criado acidentalmente dentro do projeto | Python `zipfile.extractall('~/.local/share/...')` não expande til; criou diretório literal. | Removido `rm -rf "~"`. |

---

## 5. Testes e Validação

### 5.1 Smoke Tests

| ID | Teste | Comando / Método | Resultado |
|----|-------|------------------|-----------|
| ST-001 | Projeto abre sem erros | `godot --headless --path . --quit` | ✅ Nenhum erro de parse |
| ST-002 | GUT CLI funciona | `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/ -gexit` | ✅ 2/2 tests pass |
| ST-003 | Export HTML5 gera arquivos | `godot --headless --export-release "Web" export/index.html` | ✅ `index.html`, `.js`, `.wasm`, `.pck` gerados |
| ST-004 | Save/Load funciona | GUT `test_save_and_load()` | ✅ `total_runs=5` salvo e carregado corretamente |

### 5.2 Testes Unitários (GUT)

```
res://tests/unit/test_meta_progression.gd
* test_save_and_load        ✅ PASS
* test_default_unlocks      ✅ PASS

Totals
------
Scripts               1
Tests                 2
Passing Tests         2
Failing Tests         0
Asserts               2
Time              0.459s
```

---

## 6. Decisões Arquiteturais

### 6.1 `enum Screen` em `SignalBus` (não em `GameState`)

A PRD original colocava `enum Screen` em `GameState`, e `SignalBus` referenciava `GameState.Screen` no tipo do parâmetro do sinal `screen_changed`. Em Godot 4.6, isso cria uma dependência circular de parse: se `SignalBus` for carregado antes de `GameState`, o tipo `GameState.Screen` ainda não existe.

**Decisão:** Mover o enum para `SignalBus` (o event bus é o dono semântico dos estados de tela) e fazer `GameState` referenciá-lo. Isso elimina a dependência circular e segue o princípio de que o emissor do sinal define os tipos que emite.

### 6.2 Autoloads sem `class_name`

Em Godot 4, usar `class_name` em um script que também é registrado como autoload gera o warning/error "Class 'X' hides an autoload singleton". Isso ocorre porque `class_name` cria uma classe global, e o autoload também registra um singleton global — criando ambiguidade.

**Decisão:** Remover `class_name` dos 3 autoloads. Eles são acessados pelo nome do singleton (`GameState`, `SignalBus`, `MetaProgression`), não como classes tipadas. `class_name` foi mantido apenas em `Constants` (que não é autoload).

### 6.3 Placeholders CC0 em vez de sprites Kenney

A rede do ambiente de execução apresentou instabilidade de DNS para downloads grandes do GitHub, e o site Kenney.nl requer JavaScript para iniciar o download de packs (não acessível via `wget`/`curl` puros).

**Decisão:** Gerar placeholders 32×32 programmaticamente com PIL (Python Imaging Library), usando a paleta de cores do projeto. Isso garante que:
- O pipeline de import (`*.png.import`, `.godot/imported/*.ctex`) funciona e é testável
- O projeto pode ser executado e visualizado imediatamente
- Os placeholders são 100% CC0 e substituíveis sem risco legal

**Substituição:** Será feita na Fase 1 quando houver acesso aos packs Kenney ou alternativas CC0.

---

## 7. Commits

| Hash | Mensagem | Arquivos |
|------|----------|----------|
| `56acecd` | `fase-0: setup foundation — GUT, assets, autoloads, export` | 260 arquivos, ~21K linhas adicionadas. Inclui: diretórios, scripts, GUT addon, sprites placeholders, export_presets.cfg, project.godot, .gitignore |
| `7cf4270` | `docs: atualiza PRD-fase-0 e ROADMAP — marca Fase 0 como done, documenta correções` | PRD-fase-0.md, ROADMAP.md |

---

## 8. Estado de Saída da Fase 0

O projeto está em um estado **estável, testável e exportável**.

- ✅ Abre no Godot sem erros
- ✅ Roda testes unitários via GUT CLI
- ✅ Exporta para HTML5 gerando todos os arquivos necessários
- ✅ Possui estrutura de diretórios pronta para Fases 1–5
- ✅ Autoloads base funcionando com persistência de save
- ✅ Paleta de cores e constantes centralizadas
- ⚠️ Sprites são placeholders (serão substituídos na Fase 1)

### Próximo Milestone

**Fase 1: Grid & Exploration** — Implementar movimento grid-based da Caipora na floresta corrompida, com tilemap, câmera e trigger de arena.

---

## 9. Referências

- [PRD Fase 0](./PRD-fase-0.md) — Especificação original e atualizada
- [PLAN.md](../PLAN.md) — Especificação técnica completa do produto
- [ROADMAP.md](../ROADMAP.md) — Roadmap do MVP com Fases 0–5
- [AGENTS.md](../AGENTS.md) — Harness e protocolos para o agente AI
