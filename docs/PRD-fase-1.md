# PRD — Fase 1: Grid & Exploration

> **caipora** — Brazilian Folk Horror Roguelike  
> **Fase:** 1 / 5  
> **Status:** 🔲 Not Started  
> **Document Version:** 1.0  
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
- Root é `Node2D` (não precisa de physics world inteiro, apenas grid)
- `ExplorationManager` gerencia o estado da exploração (mapa atual, posição do trigger)
- Registra `SignalBus.arena_entered` e chama `GameState.change_screen(SignalBus.Screen.ARENA)`

**Critério de Aceitação:**
- [ ] Cena abre sem erros no Godot
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

**Physics Layers:**
- Floor: sem collision
- Wall: collision layer `Constants.LAYER_WALL`, mask `Constants.LAYER_PLAYER`

**Critério de Aceitação:**
- [ ] Mapa renderiza corretamente com floor e wall
- [ ] Paredes têm collision ativa (Caipora não atravessa)
- [ ] Mapa usa constantes de `Constants.gd` (não hardcoded magic numbers)

---

### 3.3 RF-103 — Tile de Arena Trigger

**Descrição:** Tile especial que, quando pisado pela Caipora, inicia a transição para combate.

**Detalhes Técnicos:**
- Tile atlas alternativo ou custom data no TileSet
- Custom data boolean: `is_arena_trigger = true`
- Visual: reutilizar `item_potion.png` temporariamente (ou criar overlay vermelho)
- Detecção: `Area2D` da Caipora (ou posição grid comparada) verifica custom data do tile sob ela
- Ao detectar trigger:
  ```gdscript
  SignalBus.arena_entered.emit("forest_arena_01")
  GameState.change_screen(SignalBus.Screen.ARENA)
  ```

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
├── Sprite2D — texture: player_idle.png
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
- Posição inicial no mapa: `(1, 1)` em coordenadas de grid → `(32, 32)` em pixels

**Critério de Aceitação:**
- [ ] Cena instanciável sem erros
- [ ] Sprite visível e pixel-perfect (Nearest filter)
- [ ] CollisionShape2D cobre todo o tile 32×32

---

### 3.5 RF-105 — Movimento 4-Direcional no Grid

**Descrição:** Movimento baseado em input (WASD / setas) em passos discretos de 32px.

**Detalhes Técnicos:**
- Input actions Godot: `ui_up`, `ui_down`, `ui_left`, `ui_right` (padrão)
- Movimento snap-to-grid: `position += direction * Constants.TILE_SIZE`
- Cooldown entre passos: `0.15s` (evita movimento instantâneo contínuo)
- Animação: troca sprite para `player_walk_1.png` / `player_walk_2.png` durante movimento
- Colisão: usa `move_and_collide()` do CharacterBody2D para respeitar paredes
- Ao parar: volta para `player_idle.png`
- Flip sprite horizontal: `sprite.flip_h = true` quando move para esquerda

**Pseudocódigo:**
```gdscript
func _process(delta: float) -> void:
    if _is_moving:
        return
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if input_dir != Vector2.ZERO:
        _try_move(input_dir)

func _try_move(dir: Vector2) -> void:
    var target := position + dir * Constants.TILE_SIZE
    velocity = dir * (Constants.TILE_SIZE / _move_duration)
    var collision := move_and_collide(velocity * _move_duration)
    if collision:
        position -= velocity * _move_duration  # rollback
    else:
        position = target.snapped(Vector2.ONE * Constants.TILE_SIZE)
        _check_arena_trigger()
```

**Critério de Aceitação:**
- [ ] WASD / setas movem a Caipora em passos de 32px
- [ ] Não atravessa paredes (collision funciona)
- [ ] Cooldown entre passos impede movimento turbo
- [ ] Sprite troca para walk durante movimento e idle ao parar
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

**Critério de Aceitação:**
- [ ] Mundo fora do raio de visão está escuro (COLOR_NIGHT)
- [ ] Área ao redor da Caipora é iluminada
- [ ] Paredes bloqueiam parcialmente a luz (shadow opcional)
- [ ] Efeito é suave, não um círculo pixelado duro

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

func test_move_right_increases_x():
    var caipora := Caipora.new()
    caipora.position = Vector2(32, 32)
    caipora._try_move(Vector2.RIGHT)
    assert_eq(caipora.position.x, 64)
    assert_eq(caipora.position.y, 32)
    caipora.free()

func test_move_up_decreases_y():
    var caipora := Caipora.new()
    caipora.position = Vector2(32, 32)
    caipora._try_move(Vector2.UP)
    assert_eq(caipora.position.x, 32)
    assert_eq(caipora.position.y, 0)
    caipora.free()
```

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| TileMap collision não funciona com grid snap | Baixa | Alto | Testar `move_and_collide` vs `move_and_slide`. Fallback: verificar tile custom data antes de mover. |
| PointLight2D não funciona bem em HTML5 | Baixa | Médio | Fallback: CanvasLayer com ColorRect + mask shader simples. |
| Camera limit com smoothing causa jitter | Baixa | Médio | Desativar smoothing se necessário; testar em HTML5. |
| Input simultâneo diagonal (W+D) quebra grid | Média | Médio | Normalizar input para 4 direções cardinais apenas (`sign()`). |

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
- [ ] **RNF-104:** Pelo menos 1 teste GUT para movimento
- [ ] **ST-101 a ST-105:** Smoke tests passam
- [ ] **Commit:** `git commit -m "fase-1: grid exploration — tilemap, movement, camera, fog"`
- [ ] **ROADMAP:** Marcar Fase 1 como ✅ Done
- [ ] **PRD:** Atualizar este documento para v1.1 (Done)

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

- ❌ Não usar `move_and_slide` para grid-based (é para platformers)
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

### 9.1 Grid Movement vs. Physics

**Decisão:** Usar `CharacterBody2D` + `move_and_collide()` com snap-to-grid manual.

**Por quê:** `CharacterBody2D` dá collision nativa com TileMap. `move_and_collide` permite movimento determinístico (passo único) em vez de contínuo. O snap manual garante que a Caipora **sempre** fique alinhada ao grid, evitando posições como `(33.2, 31.8)` que quebrariam a lógica de tile.

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
