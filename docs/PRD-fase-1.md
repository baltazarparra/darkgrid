# PRD — Fase 1: Grid & Exploration

> **caipora** — Brazilian Folk Horror Roguelike  
> **Fase:** 1 / 5  
> **Status:** 📝 Revisado (pronto para execução)  
> **Document Version:** 1.1  
> **Depende de:** [PRD-fase-0.md](./PRD-fase-0.md) (Setup & Foundation)  

---

## 1. Visão Geral

A Fase 1 introduz a primeira camada de gameplay: a **Caipora explorando a floresta corrompida**. O jogador controla a guardiã em um grid 2D, movendo-se por trilhas tortas entre árvores retorcidas, pisando em terra molhada e sentindo a escuridão da mata fechada. Cada passo é uma escolha. Cada tile desconhecido pode esconder um perigo — ou levar à arena.

**Tom:** A floresta é hostil. Não é um passeio. É uma caçada onde a Caipora pode ser tanto predadora quanto presa.

**Filosofia:** *"A exploração é o ritmo cardíaco do roguelike. Um grid ruim mata a tensão. Um grid bom a alimenta."*

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Movimento Grid** | Caipora se move em passos de 32px, 4 direções, sem ultrapassar paredes |
| 2 | **Mundo Tangível** | TileMap com chão e parede cria uma floresta navegável e reconhecível |
| 3 | **Transição** | Pisar no tile de arena dispara `SignalBus.arena_entered` e muda para tela ARENA |
| 4 | **Atmosfera** | Fog of war / darkness overlay cria claustrofobia e limita visão do jogador |
| 5 | **Câmera** | Câmera segue suavemente a Caipora, limitada aos bounds do mapa |

---

## 3. Requisitos Funcionais

### 3.1 RF-101 — Cena Exploration

**Descrição:** Criar a cena principal de exploração que será a raiz do loop de gameplay.

**Estrutura da Scene Tree:**
```
Exploration (Node2D)
├── TileMap (ground + walls)
├── Caipora (CharacterBody2D) — instância de scenes/exploration/caipora.tscn
├── Camera2D (filho da Caipora)
├── CanvasModulate (escurece todo o mundo)
└── PointLight2D (filho da Caipora — visão)
```

**Artefatos:**
- `scenes/exploration/exploration.tscn`
- `scripts/exploration/exploration_manager.gd`

**Detalhes Técnicos:**
- Root é `Node2D` com script `ExplorationManager` anexado diretamente ao root (não precisa de nó filho separado)
- `ExplorationManager` gerencia o estado da exploração: configura TileMap programaticamente, instancia Caipora, conecta sinais
- Registra `SignalBus.arena_entered` e chama `GameState.change_screen(SignalBus.Screen.ARENA)`
- **Configurar `project.godot`:** Adicionar `run/main_scene="res://scenes/exploration/exploration.tscn"` para que F5 abra diretamente na exploração

**Critério de Aceitação:**
- [ ] `run/main_scene` aponta para `scenes/exploration/exploration.tscn`
- [ ] Cena abre sem erros no Godot (F5)
- [ ] Hierarquia segue a estrutura acima

---

### 3.2 RF-102 — TileMap com Chão e Parede

**Descrição:** TileMap navegável usando os sprites placeholders da Fase 0.

**Detalhes Técnicos:**
- Nó: `TileMap` (Godot 4.6)
- Tile size: `Constants.TILE_SIZE` (32×32)
- TileSet source: `assets/sprites/tile_floor.png` e `assets/sprites/tile_wall.png`
- Mapa hardcoded: grid 20×15 (`Constants.GRID_WIDTH` × `Constants.GRID_HEIGHT`)
- Layout mínimo:
  - Bordas inteiras de parede
  - Caminho central de chão largo 3 tiles
  - 1 tile de arena_trigger no extremo oposto ao spawn
  - Paredes internas esporádicas para criar curvas

**Configuração Programática do TileSet (em `_ready()` do ExplorationManager):**
```gdscript
func _setup_tilemap() -> void:
    var tileset := TileSet.new()
    tileset.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
    
    # Physics layer 0: walls
    tileset.add_physics_layer(0)
    tileset.set_physics_layer_collision_layer(0, 1 << (Constants.LAYER_WALL - 1))
    tileset.set_physics_layer_collision_mask(0, 1 << (Constants.LAYER_PLAYER - 1))
    
    # Custom data layer: arena trigger
    tileset.add_custom_data_layer()
    tileset.set_custom_data_layer_name(0, "is_arena_trigger")
    tileset.set_custom_data_layer_type(0, TileSet.CustomData.TYPE_BOOL)
    
    # Atlas source: floor
    var floor_tex := preload("res://assets/sprites/tile_floor.png")
    var floor_source := TileSetAtlasSource.new()
    floor_source.texture = floor_tex
    floor_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
    floor_source.create_tile(Vector2i(0, 0))
    tileset.add_source(floor_source, 0)
    
    # Atlas source: wall (com collision)
    var wall_tex := preload("res://assets/sprites/tile_wall.png")
    var wall_source := TileSetAtlasSource.new()
    wall_source.texture = wall_tex
    wall_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
    wall_source.create_tile(Vector2i(0, 0))
    var wall_data := wall_source.get_tile_data(Vector2i(0, 0), 0)
    wall_data.set_collision_polygons_count(0, 1)
    wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
        Vector2(0, 0), Vector2(Constants.TILE_SIZE, 0),
        Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE), Vector2(0, Constants.TILE_SIZE)
    ]))
    tileset.add_source(wall_source, 1)
    
    _tilemap.tile_set = tileset
```

**Mapa hardcoded (20×15):**
```
WWWWWWWWWWWWWWWWWWWW
WFFFFFFFFFFWFFFFFFFW
WFFFFFFFFFFWFFFFFFFW
WFFFFFFFFFFWFFFFFFFW
WFFFFWFFFFFFWFFFFFFW
WFFFFWFFFFFFFFFFFFFW
WFFFFWFFFFFFFFFFFFFW
WFFFFWFFFFFFFFFFFFFW
WFFFFFFFFFFFFWFFFFFW
WFFFFFFFFFFFFWFFFFFW
WFFFFFFFFFFFFWFFFFFW
WFFFFFFFFFFFFWFFFFFW
WFFFFFFFFFFFFTFFFFFW
WFFFFFFFFFFFFFFFFFFW
WWWWWWWWWWWWWWWWWWWW
```
Onde `W` = wall (source_id=1), `F` = floor (source_id=0), `T` = arena trigger (source_id=0 + custom_data)

**Critério de Aceitação:**
- [ ] Mapa renderiza corretamente com floor e wall
- [ ] Paredes têm collision ativa (Caipora não atravessa)
- [ ] Mapa usa constantes de `Constants.gd` (não hardcoded magic numbers)
- [ ] TileSet é configurado programaticamente (não manualmente via editor)

---

### 3.3 RF-103 — Tile de Arena Trigger

**Descrição:** Tile especial que, quando pisado pela Caipora, inicia a transição para combate.

**Detalhes Técnicos:**
- Usar TileSet `custom_data` (layer "is_arena_trigger", tipo bool) — já criado em RF-102
- Tile trigger usa o mesmo atlas de floor (`tile_floor.png`) mas com custom data marcado
- Visual distinto: usar `item_potion.png` como sprite overlay temporário (ou modificar o tile do trigger para usar `item_potion.png` como atlas source separado)
- **Marcando o tile trigger no mapa:**
  ```gdscript
  # Após pintar o tile de floor na posição do trigger:
  var trigger_pos := Vector2i(17, 12)  # coordenadas grid
  var tile_data := _tilemap.get_cell_tile_data(0, trigger_pos)
  if tile_data:
      tile_data.set_custom_data("is_arena_trigger", true)
  ```
- **Detecção (na Caipora, ao completar movimento):**
  ```gdscript
  func _check_arena_trigger() -> void:
      var grid_pos := tilemap.local_to_map(position)
      var tile_data := tilemap.get_cell_tile_data(0, grid_pos)
      if tile_data and tile_data.get_custom_data("is_arena_trigger") == true:
          SignalBus.arena_entered.emit("forest_arena_01")
  ```
- `ExplorationManager` escuta `SignalBus.arena_entered` e chama `GameState.change_screen(SignalBus.Screen.ARENA)`

**Critério de Aceitação:**
- [ ] Tile trigger é visualmente distinto no mapa
- [ ] Pisar no trigger emite `arena_entered` com ID correto
- [ ] `GameState.current_screen` muda para `ARENA`

---

### 3.4 RF-104 — Cena Caipora (Player)

**Descrição:** Entidade jogável com sprite, collision e componentes de exploração.

**Estrutura da Scene Tree:**
```
Caipora (CharacterBody2D)
├── AnimatedSprite2D — SpriteFrames com idle, walk_1, walk_2
├── CollisionShape2D — RectangleShape2D 32×32
├── PointLight2D — visão da Caipora (ver RF-107)
└── script: scripts/entities/caipora.gd
```

**Artefatos:**
- `scenes/exploration/caipora.tscn`
- `scripts/entities/caipora.gd`

**Detalhes Técnicos:**
- `class_name Caipora extends CharacterBody2D`
- `collision_layer = Constants.LAYER_PLAYER`
- `collision_mask = Constants.LAYER_WALL` (para colidir com paredes)
- `@export var tilemap: TileMap` — referência ao TileMap, assignada no editor ou em `_ready()` pelo ExplorationManager. Evita `get_parent().get_node()`.
- Posição inicial no mapa: `(1, 1)` em coordenadas de grid → `(32, 32)` em pixels
- `AnimatedSprite2D` com `SpriteFrames` resource contendo 3 animações:
  - `idle`: 1 frame (`player_idle.png`), loop
  - `walk`: 2 frames (`player_walk_1.png`, `player_walk_2.png`), 8 FPS, loop

**Critério de Aceitação:**
- [ ] Cena instanciável sem erros
- [ ] AnimatedSprite2D visível e pixel-perfect (Nearest filter)
- [ ] CollisionShape2D cobre todo o tile 32×32
- [ ] `tilemap` export está assignado na cena Exploration

---

### 3.5 RF-105 — Movimento 4-Direcional no Grid

**Descrição:** Movimento baseado em input (WASD / setas) em passos discretos de 32px.

**Detalhes Técnicos:**
- Input actions Godot: `ui_up`, `ui_down`, `ui_left`, `ui_right` (padrão)
- Movimento **tween-based**: verificação de collision ANTES de mover, tween de 0.15s para o target
- Cooldown entre passos: `_move_duration = 0.15s` (tween duração = cooldown)
- Animação: `AnimatedSprite2D.play("walk")` durante movimento, `"idle"` ao parar
- Flip horizontal: `animated_sprite.flip_h = true` quando move para esquerda
- **Não usar `move_and_collide`** — verificar collision via TileMap `get_cell_tile_data` antes de iniciar o tween

**Pseudocódigo:**
```gdscript
# ─── State ─────────────────────────────────────────
var _is_moving: bool = false
@export var move_duration: float = 0.15

# ─── Lifecycle ─────────────────────────────────────
func _process(_delta: float) -> void:
    if _is_moving:
        return
    var input_dir := _get_cardinal_input()
    if input_dir != Vector2.ZERO:
        _try_move(input_dir)

func _get_cardinal_input() -> Vector2:
    var x := int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
    var y := int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
    return Vector2(x, y)

func _try_move(dir: Vector2) -> void:
    var target := position + dir * Constants.TILE_SIZE
    
    # Verificar collision ANTES de mover (via TileMap custom data)
    if _would_collide(target):
        return
    
    _is_moving = true
    _animated_sprite.flip_h = dir.x < 0
    _animated_sprite.play("walk")
    
    var tween := create_tween()
    tween.tween_property(self, "position", target, move_duration)
    tween.tween_callback(_on_move_finished)

func _would_collide(target: Vector2) -> bool:
    var grid_pos := tilemap.local_to_map(target)
    var tile_data := tilemap.get_cell_tile_data(0, grid_pos)
    if tile_data == null:
        return true  # fora do mapa = parede
    # Paredes são do source_id 1 (wall); floor é source_id 0
    return tile_data.tile_set_source_id == 1

func _on_move_finished() -> void:
    _is_moving = false
    _animated_sprite.play("idle")
    _check_arena_trigger()
```

**Critério de Aceitação:**
- [ ] WASD / setas movem a Caipora em passos de 32px
- [ ] Não atravessa paredes (collision verificada antes do tween)
- [ ] Cooldown entre passos impede movimento turbo (tween = 0.15s)
- [ ] AnimatedSprite2D troca para "walk" durante movimento e "idle" ao parar
- [ ] Flip horizontal funciona para esquerda/direita

---

### 3.6 RF-106 — Câmera Segue Caipora

**Descrição:** Camera2D suavemente limitada aos bounds do mapa.

**Detalhes Técnicos:**
- Camera2D é filha direta da Caipora na cena
- `position_smoothing_enabled = true`
- `position_smoothing_speed = 10.0`
- `limit_left = 0`
- `limit_top = 0`
- `limit_right = Constants.GRID_WIDTH * Constants.TILE_SIZE`
- `limit_bottom = Constants.GRID_HEIGHT * Constants.TILE_SIZE`
- `limit_smoothed = true`

**Critério de Aceitação:**
- [ ] Câmera segue suavemente a Caipora
- [ ] Câmera nunca mostra área fora do mapa (limites funcionam)
- [ ] Sem jitter ou snapping brusco

---

### 3.7 RF-107 — Fog of War / Darkness Overlay

**Descrição:** Limitação de visão que cria atmosfera de horror e oculta o mapa além do alcance da Caipora.

**Abordagem (Godot 4):**
1. `CanvasModulate` na raiz da cena Exploration com `color = Constants.COLOR_NIGHT` (quase preto)
2. `PointLight2D` filho da Caipora com:
   - `texture`: gradiente circular suave (criar proceduralmente ou usar `GradientTexture2D`)
   - `color = Color.WHITE`
   - `energy = 1.5`
   - `blend_mode = PointLight2D.BLEND_MODE_MIX`
   - `range_item_cull_mask = 1` (afeta apenas o tilemap)
   - `shadow_enabled = true` (opcional, para parede bloquear luz)
3. Raio de visão: `96` pixels (3 tiles de raio)

**Artefato adicional:**
- `scripts/exploration/vision_controller.gd` (opcional — se lógica extra for necessária)

**Fallback (se PointLight2D não funcionar em HTML5 / gl_compatibility):**
1. Remover `CanvasModulate` e `PointLight2D`
2. Adicionar `CanvasLayer` com dois nós filhos:
   - `ColorRect` preto semi-transparente cobrindo toda a tela (`color = Color(0, 0, 0, 0.85)`)
   - `TextureRect` com gradiente radial (centro transparente, borda preta) posicionado na tela na posição do player
3. Atualizar posição do TextureRect a cada frame no `_process` do player:
   ```gdscript
   _vision_mask.position = get_global_transform_with_canvas().origin - _vision_mask.size / 2
   ```

**Critério de Aceitação:**
- [ ] Mundo fora do raio de visão está escuro (COLOR_NIGHT)
- [ ] Área ao redor da Caipora é iluminada
- [ ] Paredes bloqueiam parcialmente a luz (shadow opcional)
- [ ] Efeito é suave, não um círculo pixelado duro
- [ ] Fallback funciona se abordagem principal falhar em HTML5

---

## 4. Requisitos Não-Funcionais

| # | Requisito | Especificação |
|---|-----------|---------------|
| RNF-101 | **Performance** | Movimento deve manter 60 FPS em HTML5. Nenhum `_process` pesado. |
| RNF-102 | **Input** | Suporte a WASD e setas simultaneamente. Não usar ações customizadas ainda (MVP usa `ui_*`). |
| RNF-103 | **Código** | Todo script com `class_name`, `extends`, static typing. Nenhum número mágico. |
| RNF-104 | **Testes** | Pelo menos 1 teste GUT para movimento (direção → posição esperada). |
| RNF-105 | **Decoupling** | ExplorationManager não referencia Arena diretamente — usa apenas SignalBus. |

---

## 5. Especificações de Teste

### 5.1 Testes de Fumaça (Smoke Tests)

| # | Teste | Como executar |
|---|-------|---------------|
| ST-101 | Projeto abre com Exploration como main scene | `run_project` via MCP ou `godot --path .` |
| ST-102 | Movimento WASD funciona | Rodar jogo, pressionar teclas, verificar posição |
| ST-103 | Colisão com parede funciona | Tentar andar em parede, verificar que não move |
| ST-104 | Trigger de arena emite sinal | Pisar no trigger, verificar `arena_entered` no output |
| ST-105 | Câmera limita aos bounds | Andar até borda, verificar que câmera para |

### 5.2 Testes Unitários (GUT)

```gdscript
# tests/unit/test_caipora_movement.gd
class_name TestCaiporaMovement
extends GutTest

var _caipora: Caipora

func before_each():
    _caipora = preload("res://scenes/exploration/caipora.tscn").instantiate()
    _caipora.position = Vector2(32, 32)
    # Mock tilemap: cria TileMap simples sem paredes no caminho do teste
    var tilemap := TileMap.new()
    var tileset := TileSet.new()
    tileset.tile_size = Vector2i(32, 32)
    tileset.add_physics_layer(0)
    var source := TileSetAtlasSource.new()
    source.texture = preload("res://assets/sprites/tile_floor.png")
    source.texture_region_size = Vector2i(32, 32)
    source.create_tile(Vector2i(0, 0))
    tileset.add_source(source, 0)
    tilemap.tile_set = tileset
    # Pintar chão nas posições dos testes
    tilemap.set_cell(0, Vector2i(1, 1), 0, Vector2i(0, 0))  # spawn
    tilemap.set_cell(0, Vector2i(2, 1), 0, Vector2i(0, 0))  # direita
    tilemap.set_cell(0, Vector2i(1, 0), 0, Vector2i(0, 0))  # cima
    _caipora.tilemap = tilemap
    add_child_autofree(tilemap)
    add_child_autofree(_caipora)

func test_move_right_increases_x():
    _caipora._try_move(Vector2.RIGHT)
    assert_eq(_caipora.position.x, 64)
    assert_eq(_caipora.position.y, 32)

func test_move_up_decreases_y():
    _caipora._try_move(Vector2.UP)
    assert_eq(_caipora.position.x, 32)
    assert_eq(_caipora.position.y, 0)

func test_wall_blocks_move():
    # Pintar parede em (3, 1)
    var wall_source := TileSetAtlasSource.new()
    wall_source.texture = preload("res://assets/sprites/tile_wall.png")
    wall_source.texture_region_size = Vector2i(32, 32)
    wall_source.create_tile(Vector2i(0, 0))
    var wall_data := wall_source.get_tile_data(Vector2i(0, 0), 0)
    wall_data.set_collision_polygons_count(0, 1)
    wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
        Vector2(0, 0), Vector2(32, 0), Vector2(32, 32), Vector2(0, 32)
    ]))
    _caipora.tilemap.tile_set.add_source(wall_source, 1)
    _caipora.tilemap.set_cell(0, Vector2i(3, 1), 1, Vector2i(0, 0))
    
    _caipora.position = Vector2(64, 32)
    _caipora._try_move(Vector2.RIGHT)
    assert_eq(_caipora.position.x, 64)  # não moveu
    assert_eq(_caipora.position.y, 32)
```

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| TileMap `get_cell_tile_data` retorna null em tiles vazios | Baixa | Alto | Tratar null como parede (fora do mapa = bloqueado). Verificado nos testes. |
| PointLight2D não funciona bem em HTML5 / gl_compatibility | Baixa | Médio | Fallback implementado: CanvasLayer + ColorRect + TextureRect mask. Testar export HTML5. |
| Camera limit com smoothing causa jitter | Baixa | Médio | Desativar `position_smoothing_enabled` se necessário; testar em HTML5. |
| Input simultâneo diagonal (W+D) quebra grid | Baixa | Baixo | `_get_cardinal_input()` usa eixos separados (`int(is_pressed) - int(is_pressed)`), nunca diagonal. |

---

## 7. Checklist de Entrega da Fase 1

- [ ] **RF-101:** Cena Exploration criada e funcional
- [ ] **RF-102:** TileMap com floor/wall navegável
- [ ] **RF-103:** Tile de arena_trigger detecta pisada e emite sinal
- [ ] **RF-104:** Cena Caipora com sprite e collision
- [ ] **RF-105:** Movimento 4-direcional com animação e colisão
- [ ] **RF-106:** Camera2D segue com limites suaves
- [ ] **RF-107:** Fog of war funcional (CanvasModulate + PointLight2D)
- [ ] **RNF-101:** 60 FPS mantido
- [ ] **RNF-103:** Static typing em todos os scripts
- [ ] **RNF-104:** Pelo menos 1 teste GUT para movimento + 1 teste para wall blocking
- [ ] **ST-101 a ST-105:** Smoke tests passam
- [ ] **Commit:** `git commit -m "fase-1: grid exploration — tilemap, movement, camera, fog"`
- [ ] **ROADMAP:** Marcar Fase 1 como ✅ Done
- [ ] **PRD:** Atualizado para v1.1 (correções aplicadas)

---

## 8. Notas para o Agente

### Ordem de Implementação Recomendada

1. **RF-104 (Caipora cena)** — base para todo o resto
2. **RF-102 (TileMap)** — mundo onde Caipora existe
3. **RF-101 (Exploration scene)** — junta TileMap + Caipora + Camera
4. **RF-105 (Movimento)** — dá vida à Caipora
5. **RF-106 (Câmera)** — polimento visual
6. **RF-103 (Arena trigger)** — integração com Fase 2
7. **RF-107 (Fog)** — atmosfera final

### Anti-Padrões a Evitar

- ❌ Não usar `move_and_slide` nem `move_and_collide` para grid-based (são para platformers / movimento contínuo)
- ❌ Não hardcodear `32` — sempre usar `Constants.TILE_SIZE`
- ❌ Não criar TileMapLayer como nó separado (Godot 4 usa `TileMap` principal)
- ❌ Não referenciar `ArenaManager` diretamente de `ExplorationManager` — use SignalBus
- ❌ Não esquecer `.free()` em testes GUT ao instanciar nós

### Padrões a Seguir

- ✅ `class_name` em todos os scripts de entidade (Caipora, etc.)
- ✅ `snapped(Vector2.ONE * Constants.TILE_SIZE)` para garantir alinhamento grid
- ✅ `@onready var` para cache de referências de nó filho
- ✅ Signals para comunicação entre sistemas (nunca referência direta cruzada)

---

## 9. Decisões Arquiteturais Específicas

### 9.1 Grid Movement: Tween-based com Verificação Prévia

**Decisão:** Usar `CharacterBody2D` com tween + verificação de collision ANTES de mover (via `TileMap.get_cell_tile_data`). Não usar `move_and_collide`.

**Por quê:**
- `move_and_collide` foi projetado para movimento contínuo baseado em `delta`. Para grid-based discreto, é overkill e propenso a drift de posição.
- Verificação prévia via TileMap é determinística: sabemos EXATAMENTE se o tile target é parede antes de iniciar qualquer movimento.
- Tween garante suavidade visual sem depender de physics engine.
- Posição final é sempre múltiplo exato de `TILE_SIZE` — nunca há drift.

### 9.2 Arena Trigger: Tile Custom Data vs. Area2D

**Decisão:** Usar TileSet `custom_data` para marcar o tile trigger.

**Por quê:** É o método mais idiomático do Godot 4. A Caipora verifica `tilemap.get_cell_tile_data()` na posição grid atual. Isso evita criar centenas de `Area2D` nodes para um mapa grande. Se o mapa for gerado proceduralmente no futuro, custom data escala melhor.

### 9.3 Fog: PointLight2D vs. Shader

**Decisão:** `CanvasModulate` + `PointLight2D`.

**Por quê:** É a solução mais simples e performática para 2D pixel art. Não requer shader custom. `shadow_enabled` opcional nas paredes adiciona profundidade. Se houver problemas de performance em HTML5, o fallback é um shader simples ou um `Sprite2D` grande com mask circular.

---

## 10. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `PLAN.md` | 4.1 (Loop de Gameplay), 4.3 (Estrutura de Entidades), 7.2 (Padrões de Scene Tree) |
| `AGENTS.md` | Scene Architecture, Code Standards, Session Protocol |
| `PRD-fase-0.md` | RF-003 (Autoloads), RF-005 (Constants), decisões arquiteturais |
| `ROADMAP.md` | Fase 1: Grid & Exploration |
