# caipora — MVP Roadmap

> Browser-first Brazilian folk horror roguelike.  
> Godot 4.6 + GDScript + HTML5/itch.io.

---

## MVP Definition of Done

O MVP está completo quando:
- [ ] Caipora se move no grid de exploração
- [ ] Arena de combate carrega com transição
- [ ] Timing system funciona (ataque crítico + esquiva)
- [ ] 1 Criatura com telegraph pattern
- [ ] Vitória/derrota funcionam
- [ ] SFX para cada ação
- [ ] Meta-progressão persiste entre runs
- [ ] HTML5 export roda no browser
- [ ] itch.io page carrega e joga

---

## Fase 0: Setup & Foundation ✅

**Objetivo:** Preparar o projeto Godot, instalar ferramentas e baixar assets.

### Tasks
- [x] Instalar GUT addon (Godot Unit Test) — v9.6.0, 2/2 tests passando
- [x] Baixar 1 pack Kenney CC0 para pixel art — placeholders CC0 gerados (Kenney inacessível via CLI)
- [x] Criar autoloads: GameState, SignalBus, MetaProgression — com fix de dependência circular (enum Screen em SignalBus)
- [x] Configurar export preset HTML5 no Godot — templates 4.6.3 instalados manualmente, export testado
- [x] Criar scripts/utils/constants.gd com valores base

### Definition of Done
- Projeto abre sem erros. GUT addon aparece no menu. Export HTML5 gera arquivos.

---

## Fase 1: Grid & Exploration 🔲

**Objetivo:** Caipora explora a floresta corrompida em grid-based movement.

### Tasks
- [ ] Criar cena Exploration com Node2D root
- [ ] Criar TileMapLayer com tiles de chão (grama/terra) e parede (árvore/pedra)
- [ ] Adicionar tile de arena_trigger que dispara combate
- [ ] Criar cena Caipora (CharacterBody2D) com sprite idle do pack Kenney
- [ ] Implementar movimento 4-direcional no grid (move_and_collide)
- [ ] Câmera segue Caipora com Camera2D
- [ ] Adicionar limitação de visibilidade (fog of war ou darkness overlay)

### Definition of Done
- Caipora anda no grid. Câmera segue. Pisar no tile de arena inicia transição.

---

## Fase 2: Arena & Timing 🔲

**Objetivo:** Combate action com timing mechanic funcional.

### Tasks
- [ ] Criar cena Arena com background (TileMap ou ColorRect + tiles)
- [ ] Spawn Caipora na arena via ArenaManager
- [ ] Criar cena Criatura (CharacterBody2D) com sprite do pack Kenney
- [ ] Implementar HealthComponent (vida, dano, morte)
- [ ] Criar TimingCue UI (barra/círculo com janela de acerto)
- [ ] Detectar press de espaço dentro da janela de timing
- [ ] Aplicar dano crítico (2x-3x) no timing de ataque
- [ ] Aplicar esquiva perfeita (0 dano) + contra-ataque no timing de defesa
- [ ] Implementar screenshake básico via FeedbackSystem
- [ ] Adicionar partículas de impacto (Godot CPUParticles2D)

### Definition of Done
- Arena inicia. Espaço no timing certo = crítico ou esquiva. Dano aplica. Screenshake funciona.

---

## Fase 3: Enemy AI & Visceral Feedback 🔲

**Objetivo:** Criatura é ameaçadora. Feedback é brutal e satisfatório.

### Tasks
- [ ] Criar AttackPattern para Criatura: wind-up → telegraph visual → ataque
- [ ] Implementar StateMachine na Criatura (idle → wind-up → attack → cooldown)
- [ ] Criar Boss com pattern diferente (mais rápido ou múltiplos golpes)
- [ ] Adicionar blood particles no hit (vermelho `#8b0000`)
- [ ] Adicionar hit-stop frames (congelar jogo por 2-3 frames no impacto)
- [ ] Implementar death animation (flash + fade + particles)
- [ ] Gerar SFX com jsfxr: attack.wav, hit.wav, dodge.wav, timing_perfect.wav, death.wav, ui_click.wav
- [ ] Conectar SFX aos eventos de SignalBus

### Definition of Done
- Criatura ataca com telegraph visível. Boss tem pattern único. Blood, hit-stop e sons funcionam.

---

## Fase 4: Meta-Progression & UI 🔲

**Objetivo:** Loop completo do jogo com menus e persistência.

### Tasks
- [ ] Criar cena MainMenu (CanvasLayer com título + botão Start)
- [ ] Criar HUD com barra de vida da Caipora (ProgressBar)
- [ ] Criar cena GameOver (derrota) e WinScreen (vitória)
- [ ] Implementar transição entre Exploration → Arena → GameOver/Win → Hub
- [ ] Criar cena Hub entre runs (árvore de upgrades simples)
- [ ] Implementar unlocks: +10 max HP, faster cooldown, etc.
- [ ] Salvar meta-progressão em user://savegame.json
- [ ] Carregar save no início da run

### Definition of Done
- Player pode jogar uma run completa (exploração → combate → vitória/derrota → hub → próxima run).

---

## Fase 5: Export & Publish 🔲

**Objetivo:** Web build jogável no itch.io.

### Tasks
- [ ] Configurar export preset HTML5 no Godot (template web instalado)
- [ ] Exportar para export/index.html
- [ ] Testar no browser local (Chrome/Firefox)
- [ ] Verificar load time < 10s

### Definition of Done
- Carrega e joga. Não crasha. Timing funciona.

---

## Notas para o Agente

- **Uma fase por sessão.** Não misturar tasks de fases diferentes.
- **Commit após cada task completada.**
- **Atualizar este ROADMAP.md** marcando `[x]` nas tasks feitas.
- **Se descobrir um blocker,** documentar em "Known Issues" no final deste arquivo.
- **Nunca suavizar o horror.** A floresta é hostil. A Caipora é perigosa. O sangue é real.

---

## Known Issues

| # | Issue | Fase Descoberta | Impacto | Status |
|---|-------|-----------------|---------|--------|
| KI-001 | **Sprites são placeholders** — Kenney.nl requer JavaScript para download; não acessível via `wget`/`curl`. Placeholders CC0 gerados com PIL serão substituídos por sprites Kenney reais na Fase 1. | Fase 0 | Médio | 🔄 Pendente |
| KI-002 | **`--check-only` não existe no Godot 4.6** — A PRD original mencionava esta flag para lint de GDScript, mas ela não existe. Validação de sintaxe é feita abrindo o projeto em headless. | Fase 0 | Baixo | ✅ Documentado |
| KI-003 | **GUT plugin emite erro `_exit_tree`** — `Invalid assignment of property or key 'menu_manager' with value of type 'Nil'` ocorre ao fechar Godot em headless. Não afeta funcionalidade dos testes. | Fase 0 | Baixo | ✅ Conhecido |
