# PRD — Tela Inicial v2: Cobertura Full-Viewport, Dark Fire no Título e UX

**Data:** 2026-06-03  
**Status:** Proposta  
**Escopo:** `main_menu.tscn`, `doom_fire.gd`, `main_menu.gd`

---

## Contexto

A tela inicial apresenta três bugs visuais críticos e dois pedidos de melhoria de UX que afetam a primeira impressão do jogo em todas as plataformas alvo.

---

## Problemas Identificados

### P1 — DoomFire não cobre 100% da largura em PWA paisagem

**Raiz técnica:** `DoomFire` renderiza um `Sprite2D` de tamanho fixo `160 × 90` pixels, escalado por `SCALE = 8`, resultando em `1280 × 720` px. O viewport base do projeto é `1280 × 720` com stretch `canvas_items / expand`. Em telas com proporção wider que 16:9 (ex.: Android em paisagem com barra de status, ou tablets), o viewport lógico expande além de 1280 px de largura e a textura do fogo não acompanha — fica centralizada com faixas pretas nas laterais.

**Evidência:** comportamento visível em PWA Android Chrome em landscape quando o viewport real excede 1280 px de largura.

---

### P2 — Safari iPhone retrato: cena no topo, vão enorme abaixo

**Raiz técnica:** O projeto está configurado como paisagem (`handheld/orientation = 4`). No Safari iOS, o canvas HTML é posicionado como um elemento `display: block` sem nenhuma lógica de centralização vertical ou `height: 100dvh`. O `PortraitGuard` só atua dentro do Godot (layer 128), mas o **canvas HTML em si** fica colado ao topo do body, com o restante da tela exposta como fundo preto do `body`. O resultado é: metade superior = jogo, metade inferior = fundo preto vazio.

Além disso, a tela do Godot em portrait é renderizada com proporção 16:9 comprimida na largura de 393 px, produzindo uma janela minúscula no topo.

**Nota:** O PortraitGuard já instrui o usuário a girar o dispositivo. O problema é que o canvas HTML não preenche o viewport enquanto a orientação está errada — a experiência parece quebrada antes mesmo de o usuário ler a mensagem.

---

### P3 — Animação do título "CAIPORA" é genérica

O título usa um `Label` com pulso simples de `modulate:a`. Não há conexão visual com o fogo. O nome precisa de uma animação que evoque chamas escuras.

---

## Requisitos

### R1 — DoomFire cobre 100% do viewport dinamicamente

- `doom_fire.gd` deve calcular `COLS` e `ROWS` com base no tamanho real do viewport em `_ready()`, não em constantes.
- O `Sprite2D` deve ser reposicionado e reescalado a cada resize do viewport.
- Conectar `get_viewport().size_changed` → recalcular dimensões e recriar a grade/imagem.
- Manter `SCALE = 8` como pixel-size mínimo; o número de colunas e linhas varia.
- A textura deve preencher exatamente o viewport sem buracos nas laterais nem no topo.

**Critério de aceite:** Em qualquer proporção de tela (4:3, 16:9, 19:9, 21:9), o fogo cobre o viewport de borda a borda.

---

### R2 — Canvas HTML preenche 100% do viewport em portrait no Safari

No `index.html`, o `#canvas` deve usar:

```css
#canvas {
  display: block;
  width: 100%;
  height: 100dvh; /* fallback: 100vh */
  object-fit: contain;
}

body {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

- O canvas não deve deixar vão abaixo de si em nenhuma orientação.
- O fundo preto do `body` sempre cobre o restante da tela (já é o default).
- O `PortraitGuard` continua sendo a instrução dentro do jogo — o fix no HTML é apenas para eliminar o layout quebrado.

**Critério de aceite:** No iPhone Safari portrait (393 × 852 px), o canvas ocupa a área visível inteira sem vão; o overlay "Gire o dispositivo" do PortraitGuard é legível e centralizado.

---

### R3 — Animação "dark fire" no título CAIPORA

Substituir o pulso simples de alpha por um efeito de chamas escuras no texto:

- **Técnica:** shader de vertex noise no `Label` ou substituição por `RichTextLabel` com BBCode `[wave]`/custom shader.
- **Comportamento:**
  - As letras oscilam verticalmente em frequências levemente diferentes (efeito de chama por letra).
  - A cor transita ciclicamente entre `Color(0.55, 0, 0)` (carmesim profundo) e `Color(1.0, 0.18, 0.05)` (brasa viva), passando por `Color(0.8, 0.05, 0)`.
  - A amplitude vertical é pequena (±3–5 px) para não quebrar o layout.
  - A transição de cor é suave, com período ~1.4 s, dessincronizada por letra.
- **Remover:** o tween de `modulate:a` atual em `_animate_title()`.

**Critério de aceite:** O título parece estar pegando fogo; as letras dançam de forma orgânica. Legibilidade preservada.

---

### R4 — Remover o subtítulo "a floresta tem fome"

- Deletar o nó `Subtitle` (`Label`) de `main_menu.tscn`.
- Remover qualquer referência a ele em `main_menu.gd` (nenhuma existe atualmente, mas verificar).
- O `VBox` deve contrair naturalmente.

**Critério de aceite:** Nenhum subtítulo visível na tela.

---

### R5 — Dobrar a altura do botão Iniciar

- No nó `StartButton`, adicionar `custom_minimum_size = Vector2(0, 72)` (altura atual implícita ~36 px → 72 px).
- Manter `font_size = 18`.
- Aplicar o mesmo a `QuitButton` para consistência visual.

**Critério de aceite:** O botão Iniciar tem altura mínima de 72 px e é facilmente tocável com o polegar em mobile.

---

## Ordem de Implementação

1. **R4** — Remover subtitle (trivial, zero risco).  
2. **R5** — Aumentar altura dos botões (trivial).  
3. **R2** — Fix CSS no `index.html` (HTML puro, sem rebuild Godot).  
4. **R1** — DoomFire dinâmico (requer rebuild + export).  
5. **R3** — Animação dark fire no título (requer rebuild + export).

---

## Fora de Escopo

- Novos assets de fonte ou spritesheet para o título.
- Mudança no comportamento de fade-in/out.
- Alterações no `PortraitGuard`.
- Qualquer mudança em gameplay, arena ou exploração.

---

## Arquivos Afetados

| Arquivo | Tipo de mudança |
|---|---|
| `scripts/ui/doom_fire.gd` | Refactor: dimensões dinâmicas |
| `scripts/ui/main_menu.gd` | Refactor: troca animação título |
| `scenes/ui/main_menu.tscn` | Edit: remove Subtitle, aumenta botões, adiciona shader/RichText no título |
| `export/index.html` | Edit: CSS canvas full-viewport |

---

## Notas de Implementação

### DoomFire dinâmico

```gdscript
func _ready() -> void:
    layer = -10
    get_viewport().size_changed.connect(_rebuild)
    _rebuild()

func _rebuild() -> void:
    var vp_size := get_viewport().get_visible_rect().size
    COLS = int(ceil(vp_size.x / SCALE))
    ROWS = int(ceil(vp_size.y / SCALE))
    # reinicializar _grid, _image, _texture, _sprite
```

`COLS` e `ROWS` deixam de ser `const` e viram `var`.

### CSS canvas

Substituir o bloco `#canvas` atual em `index.html`:

```css
html, body {
    margin: 0; padding: 0; border: 0;
    width: 100%; height: 100%;
}
body {
    background-color: black;
    overflow: hidden;
    touch-action: none;
    display: flex;
    align-items: center;
    justify-content: center;
}
#canvas {
    display: block;
    width: 100%;
    height: 100dvh;
}
```

### Animação dark fire (GDScript puro, sem shader)

Usar `_process` em `main_menu.gd` com noise por letra via Array de tweens independentes ou loop manual de `sin(time * freq + offset_por_letra)` aplicado em cada caractere via `RichTextLabel` com `push_color` e `push_font_size` dinâmico — ou, mais simples: um tween por-letra em `Label` dividido em `CharacterBody2D` dummies.

**Recomendação:** Substituir `Label` por `RichTextLabel` com BBCode `[wave amp=3 freq=2]CAIPORA[/wave]` e adicionar um `AnimationPlayer` ou tween que cicla a `modulate` entre as cores de brasa. Isso entrega o efeito com mínimo de código.
