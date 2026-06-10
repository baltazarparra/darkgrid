# PLANO — Marca, Loader Inicial, Transição e Tela Inicial AAA

**Data:** 2026-06-10
**Status:** Proposta
**Norte visual:** `docs/CONCEITO-protagonista.md` + `.agents/skills/visual-identity/SKILL.md`
**Escopo:** cadeia completa de primeira impressão — favicon/ícones PWA → loader
HTML → boot splash → fade de abertura → tela inicial (logo + nome) → transições
de cena.

---

## 1. Diagnóstico — por que refazer

A identidade aprovada em 2026-06 ("massa laranja serrilhada, vazio preto, dois
olhos brancos") **não chega ao jogador antes do gameplay**. Hoje a cadeia de
primeira impressão é:

| Ponto de contato | Estado atual | Problema |
|---|---|---|
| `icon.png` + `assets/icons/icon_*.png` (favicon, PWA, og:image) | Emoji de fogo do Twemoji (1f525) | Asset genérico de terceiro; zero Caipora; render suave anti-pixel-art |
| Loader web | Shell padrão do Godot (`html/custom_html_shell=""`) | Barra/spinner genéricos do engine; primeira tela do jogo não tem marca |
| `assets/sprites/boot_splash.png` | Emoji de fogo + "CAIPORA" em vermelho genérico | Mesmo problema; quebra a continuidade visual entre loader e menu |
| `assets/sprites/logo_title.png` (`gen_logo.py`) | Letras de madeira, olhos ÂMBAR no "O" | Pré-rebrand: madeira não é material da marca; olhos âmbar violam a trava "dois olhos brancos PUROS" |
| `scene_transition.gd` | Fade preto + flavor âmbar | Funcional, mas sem assinatura da marca; menu tem fade paralelo próprio (duplicação) |
| Tela inicial ("Horizonte Infernal") | Fogo, treelines, brasas, TitleWalker | **Já on-brand** — a Caipora real atravessa a tela. Só o logo destoa |

A experiência AAA aqui não é adicionar enfeite: é **uma única linguagem visual
contínua, sem costura**, do clique no link até o botão Iniciar.

---

## 2. Princípio do plano

> A primeira leitura de QUALQUER ponto de contato é: mancha laranja serrilhada,
> vazio preto, dois olhos brancos.

Regras herdadas (lei, não preferência):

- Paleta fechada da protagonista: juba `#8b2a00 → #ff4500`, preto `#000000`,
  olhos `#ffffff` puro, sangue `#8b0000`, contorno `#1a120a`, fundo noite
  `#0d1117`. Verde `#00fa9a` NÃO aparece na marca (é âncora exclusiva da Fúria).
- Acabamento chapado: flat fill, 2 tons por material, outline 1px, sem
  gradiente suave, sem blur, sem dither.
- Horror físico: sangue e hostilidade ficam; fofura e mascote, não.
- Todo asset de marca sai de **gerador determinístico** (mesmo pipeline premium
  do `gen_caipora.py`: desenho supersampled → downsample → snap de paleta →
  outline 1px). Nunca PNG editado à mão.

---

## 3. Etapas

### Etapa 0 — `gen_brand.py`: gerador canônico da marca

Novo `scripts/tools/gen_brand.py` (stdlib + Pillow, seed fixa), gerando TODOS
os assets de marca a partir de duas formas-fonte:

**A. A marca ("rosto-marca")** — recorte cabeça da Caipora: juba laranja
serrilhada envolvendo o capuz, vazio preto interno, dois olhos brancos
circulares iguais, pontas dos chifres pretos rompendo a silhueta. Saídas:

- `icon.png` 512×512 (config/icon, og:image via `index.512x512.png` do export)
- `assets/icons/icon_144.png`, `icon_180.png`, `icon_512.png` (PWA)
- variante "olhos fechados" para o blink do loader HTML (ver Etapa 1)

**B. O wordmark "CAIPORA"** — substitui o logo de madeira:

- Letras chunky pixel-art na rampa da juba (`#8b2a00` base + `#ff4500` luz),
  bordas **serrilhadas** como a capa (a palavra É a juba), outline `#1a120a`.
- O "O" vira o rosto-vazio: miolo `#000000` + dois olhos `#ffffff` PUROS
  (corrige o âmbar atual). Frame `logo_title_blink.png` mantém o contrato de
  piscada do menu.
- Sangue `#8b0000` mínimo: escorridos na base, menos do que o logo atual —
  acento, não leitura principal.
- Saída: `assets/sprites/logo_title.png` + `logo_title_blink.png`, ≤512px de
  largura (limite de asset). Se a proporção mudar, atualizar
  `LOGO_BASE_SIZE` em `main_menu.gd`.

**C. O boot splash** — `assets/sprites/boot_splash.png` 1280×720: fundo
`#0d1117`, rosto-marca centrado, wordmark abaixo. **Composição idêntica à do
loader HTML** (mesmas posições relativas) para o handoff loader → splash ser
invisível.

Critérios de aceite:

- Reduzido a 32px, o rosto-marca lê como "mancha laranja de olhos brancos".
- Checklist da skill `visual-identity` §5 passa em todos os assets.
- Twemoji eliminado: remover `assets/licenses/twemoji_LICENSE.txt` se nenhum
  asset 1f525 restar no repo (conferir antes — a licença cita só o fogo).

### Etapa 1 — Loader inicial web premium (custom HTML shell)

Trocar o shell padrão por `html/shell.html` (base: shell oficial do Godot
4.6, preservando toda a lógica de boot/erro do engine) e apontar
`html/custom_html_shell` no `export_presets.cfg`.

- Fundo `#0d1117` ponta a ponta (mesma cor do `boot_splash/bg_color`).
- Rosto-marca central em PNG base64 inline (sem request extra), com
  `image-rendering: pixelated`.
- **Olhos piscam durante o load** via CSS animation alternando os dois frames
  da marca — a mata já olha de volta antes do engine subir.
- Barra de progresso brutal: retângulo de cantos duros, trilho
  quase-preto, preenchimento na rampa `#8b2a00 → #ff4500` em degraus (sem
  gradiente suave — steps de cor chapada), texto de status em `#c9d1d9`.
- Estado de erro em `#8b0000` (sem softening: "a mata rejeitou o carregamento"
  + detalhe técnico).
- Migrar o CSS hoje embutido em `html/head_include` para o shell; manter o
  script de dpr-cap e o `update-notifier.js` (contratos existentes).
- Handoff sem costura: loader → boot splash do Godot (mesma composição) →
  fade-in do menu. Nenhum flash de cor divergente em nenhum passo.

Critérios de aceite:

- Sem flash branco/preto-divergente do clique até o menu, em desktop, Android
  Chrome e iPhone Safari, portrait E landscape (gotcha 10).
- PWA/offline continua funcionando (service worker do export não quebra com
  shell custom).
- Barra reflete progresso real de download do .pck/.wasm.

### Etapa 2 — Tela inicial: novo logo e padronização

A composição "Horizonte Infernal" (DoomFire, treelines, brasas, ground,
TitleWalker) **fica** — já é on-brand e foi tunada para 60fps. Muda:

- `main_menu.gd` passa a carregar o novo wordmark; piscada via
  `_schedule_blink()` mantida (agora olhos brancos). Ajustar `LOGO_BASE_SIZE`
  se necessário; regra de escala inteira (texel uniforme) mantida.
- Fallback de título (RichTextLabel + `title_fire.gdshader`) permanece como
  está — é só fallback de asset ausente.
- Botões padronizados via `assets/fonts/theme.tres`: bordas duras, sem cantos
  arredondados, identidade laranja/preto/branco-sujo; estados de foco/hover
  com contraste alto (leitura "brutal, sem enfeite fofo" da skill). Altura
  mínima 72px mantida (PRD-tela-inicial-v2 R5).
- Sem novos nós via MCP na cena (gotcha 7): tudo que for runtime continua
  montado por código no `_ready()`, como o logo já é hoje.

Critério de aceite: screenshot do menu reduzido a thumbnail ainda lê como a
marca (mancha laranja + olhos brancos sobre breu); em paisagem o menu segue
respeitando os 30% de largura (contrato atual).

### Etapa 3 — Transição padronizada (assinatura da marca)

`scene_transition.gd` vira a ÚNICA linguagem de transição:

- Mantém: fade preto curto, flavor âmbar temático, contrato "entrada em arena
  fica com fade limpo" (a chamada de luta pertence ao ArenaManager).
- Adiciona a assinatura: durante transições temáticas, **dois olhos brancos
  abrem no breu** por um instante atrás do flavor text (2 retângulos/sprites,
  custo zero de partícula) e fecham antes do fade-in. A mesma piscada do
  loader, do logo e do "O" — um único gesto de marca do load ao gameplay.
- Padronizar cores/timings como constantes (alinhadas a `constants.gd`).
- `main_menu.gd::_setup_fade()`/`_on_start_pressed()` deixam de ter fade
  paralelo próprio e passam a usar o SceneTransition (uma implementação a
  menos; curvas idênticas em todo lugar).

Critério de aceite: nenhuma troca de cena com curva/cor diferente das demais;
`tests/unit/test_scene_transition.gd` atualizado e verde.

### Etapa 4 — Testes, gates e build

- Novo `tests/unit/test_brand_assets.gd` (espelho do
  `test_caipora_sprite_assets.gd`): existência, dimensões, alpha limpo e snap
  de paleta dos assets de marca (logo, blink, boot splash, ícones); olhos do
  wordmark são `#ffffff` puro.
- Gotcha 12: após criar script com `class_name` novo, rodar
  `godot --headless --import` antes de `make test` e **conferir que o total de
  testes SUBIU** no sumário do GUT.
- `make gate` antes de cada commit; `/validate-platforms` em toda mudança de
  UI/loader (Etapas 1–3); `make export` + teste real de load no browser ao
  fechar as Etapas 1 e 2 (gotcha 5: tempo de load).
- Orçamento: projeto ≤10MB; shell custom não adiciona requests além do PNG
  inline.

---

## 4. Ordem de execução (uma tarefa por sessão)

| Sessão | Entrega | Gate |
|---|---|---|
| S1 | Etapa 0 — `gen_brand.py` + todos os assets regenerados | `make gate` + teste novo de assets |
| S2 | Etapa 1 — shell HTML custom + export_presets | `make export` + teste de load nos 3 alvos |
| S3 | Etapa 2 — menu com novo logo + theme | `make gate` + `/validate-platforms` |
| S4 | Etapa 3 — transição padronizada | `make gate` + `/validate-platforms` |

Dependências: S2–S4 dependem dos assets de S1. S3 e S4 são independentes entre
si.

---

## 5. Riscos e notas

- **Shell custom desatualiza com upgrade do Godot:** partir SEMPRE do shell
  oficial da versão corrente (4.6.x) e documentar no topo do `shell.html` qual
  versão foi a base.
- **og:image:** `head_include` aponta para `index.512x512.png` gerado pelo
  export a partir do `icon.png` — regenerar o ícone resolve a imagem social
  junto; conferir após `make export`.
- **`export_presets.cfg` enum de orientação** (gotcha 10): não tocar em
  `progressive_web_app/orientation` nesta frente.
- **`.tscn` à mão:** as mudanças de cena são mínimas (logo é montado por
  código); qualquer edição manual de `.tscn` passa por `git diff` cuidadoso —
  nada de MCP `add_node` em cenas com autoloads (gotcha 7).
- **Fora de escopo:** gameplay, arena, exploração, áudio, sprites `player_*`
  (intocáveis fora do `gen_caipora.py`), HUD de combate.
