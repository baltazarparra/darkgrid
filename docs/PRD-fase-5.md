# PRD — Fase 5: Export & Publish

> **caipora** — Brazilian Folk Horror Roguelike
> **Fase:** 5 / 5 (final do MVP)
> **Status:** 📝 Revisado (pronto para execução)
> **Document Version:** 1.0
> **Depende de:** [PRD-fase-4.md](./PRD-fase-4.md) (Meta-Progression & UI)

---

## 1. Visão Geral

A Fase 5 leva **caipora** para fora da máquina de desenvolvimento e para dentro do browser.
O jogo está completo (loop MainMenu → Hub → Exploração → Arena → Win/GameOver → Hub, com
combate visceral, IA, progressão persistente e 29/29 testes verdes). Falta o que o ROADMAP
chama de Definition of Done do MVP: **HTML5 export que roda no browser** e **página itch.io
que carrega e joga**.

Não há novas mecânicas aqui. É a fase de **empacotamento, validação e publicação**: finalizar
o preset de export Web, gerar o build, testá-lo em browsers reais, garantir tempo de carga
aceitável e publicar no itch.io de forma jogável.

**Tom:** A floresta finalmente abre para o mundo. Qualquer um, em qualquer aba, pode ser
devorado por ela.

**Filosofia:** *"Um jogo que não roda no browser do jogador não existe. Enviar é a última mecânica."*

---

## 2. Estado de Partida (verificado)

- `export_presets.cfg` já tem o preset **"Web"** (`platform=Web`, `runnable=true`,
  `export_path="export/index.html"`, `export_filter=all_resources`).
- **`variant/thread_support=false`** → build single-thread: **não exige cabeçalhos
  cross-origin (COOP/COEP) nem SharedArrayBuffer**. Isso simplifica drasticamente a hospedagem
  e o itch.io (serve estático puro).
- `html/canvas_resize_policy=2`, `html/focus_canvas_on_start=true`, `html/export_icon=true`.
- Renderer `gl_compatibility` (project.godot) — apropriado para WebGL2/HTML5.
- Templates de export **4.6.3.stable instalados** (`~/.local/share/godot/export_templates/`).
- `export/` já contém um build de baseline (index.html/js/wasm/pck). **`export/` é gitignored**
  → o build não é versionado; o artefato de publicação é um zip gerado.
- Atenção: `index.wasm` ~37MB (descomprimido) → foco em **tempo de carga** (RF-504).

---

## 3. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Build Web Reproduzível** | Export release gera `export/index.html` + assets via CLI, sem erros |
| 2 | **Roda no Browser** | Jogo carrega e o loop completo é jogável em Chrome e Firefox |
| 3 | **Carga Aceitável** | Tempo de carregamento < 10s em conexão típica (com compressão) |
| 4 | **Publicado no itch.io** | Página itch.io carrega o jogo embutido e é jogável end-to-end |
| 5 | **Sem Regressões** | 29/29 testes GUT continuam verdes; nenhum erro no console do browser |

---

## 4. Requisitos Funcionais

### 4.1 RF-501 — Finalizar e Validar o Preset de Export Web

**Descrição:** Garantir que o preset "Web" está correto e otimizado para um MVP single-thread.

**Detalhes Técnicos (validar/ajustar em `export_presets.cfg`):**
- `variant/thread_support=false` — manter (evita exigência de COOP/COEP no host).
- `vram_texture_compression/for_desktop=true` — aceitável; arte é pixel-art pequena.
- `html/canvas_resize_policy=2` (ajusta ao container) + `html/focus_canvas_on_start=true`
  (teclado funciona sem clique extra) — manter.
- `progressive_web_app/enabled=false` — manter (PWA fora de escopo do MVP).
- `script_export_mode` — manter o default do preset.
- Conferir `export_path="export/index.html"`.

**Critério de Aceitação:**
- [ ] Preset "Web" presente, `runnable=true`, single-thread
- [ ] `export_path` aponta para `export/index.html`
- [ ] Sem dependências de recursos que quebrem no HTML5 (áudio `.wav`, `CPUParticles2D`,
      `gl_compatibility` — todos já compatíveis)

---

### 4.2 RF-502 — Gerar o Build Release via CLI

**Descrição:** Exportar o jogo de forma reproduzível por linha de comando (headless).

**Detalhes Técnicos:**
- Comando:
  ```
  godot --headless --export-release "Web" export/index.html
  ```
- Pré-requisito: templates 4.6.3 instalados (✅) e projeto importado (`godot --headless --import`).
- Saída esperada em `export/`: `index.html`, `index.js`, `index.wasm`, `index.pck`,
  `index.png`/ícones, worklets de áudio.
- O export **não deve** emitir erros; warnings de template são toleráveis.

**Critério de Aceitação:**
- [ ] Comando de export conclui com código 0
- [ ] Todos os artefatos esperados presentes em `export/`
- [ ] `index.pck` contém os recursos (cenas, scripts, SFX, save schema)

---

### 4.3 RF-503 — Servir e Testar no Browser Local

**Descrição:** Validar o build em browsers reais (Chrome e Firefox) a partir de um servidor
estático local.

**Detalhes Técnicos:**
- Servir o diretório (single-thread → servidor estático simples basta, sem headers especiais):
  ```
  python3 -m http.server 8060 --directory export
  ```
  Abrir `http://localhost:8060/index.html`.
- Roteiro de validação (loop completo):
  1. Boot cai no **MainMenu**.
  2. Iniciar → **Hub**; comprar um upgrade (Vigor) e ver o nível mudar.
  3. Entrar na Floresta → **Exploração**; mover a Caipora; pisar no trigger.
  4. **Arena**: HUD mostra vida; **timing** de ataque (crítico) e de defesa (esquiva) funcionam;
     screenshake, partículas, hit-stop e **SFX** ocorrem.
  5. Vitória/derrota → tela correspondente → volta ao **Hub**.
  6. HP persiste entre encontros; recupera no Hub.

**Critério de Aceitação:**
- [ ] Carrega sem erros no console (Chrome e Firefox)
- [ ] Loop completo jogável end-to-end nos dois browsers
- [ ] Timing (Espaço) responde corretamente
- [ ] Áudio toca após o primeiro gesto do usuário (ver Risco de autoplay)
- [ ] Não há crash nem travamento durante uma run completa

---

### 4.4 RF-504 — Verificar e Otimizar Tempo de Carga (< 10s)

**Descrição:** O jogo deve carregar em menos de 10 segundos em conexão típica.

**Detalhes Técnicos:**
- Medir o load time (aba Network do DevTools; do request inicial ao primeiro frame jogável).
- O gargalo é `index.wasm` (~37MB) + `index.pck` (~3.4MB). Estratégias:
  - **Compressão de transferência**: servir com gzip/brotli. O itch.io serve os assets com
    gzip automaticamente; para o teste local, o número relevante é o do host de produção.
  - Confirmar que `vram_texture_compression` não inflou desnecessariamente o pck (arte pequena).
  - Garantir que a barra de progresso do shell de loading do Godot aparece (feedback ao jogador).
- Documentar o tempo medido (local descomprimido vs. estimativa itch.io comprimido).

**Critério de Aceitação:**
- [ ] Tempo de carga medido e registrado
- [ ] < 10s na configuração de produção (itch.io, comprimido)
- [ ] Barra de progresso de carregamento visível durante o download

---

### 4.5 RF-505 — Publicar no itch.io

**Descrição:** Publicar o build como jogo HTML5 jogável no browser na página do itch.io.

**Detalhes Técnicos:**
- Empacotar o conteúdo de `export/` em um **zip com `index.html` na raiz** (não dentro de
  subpasta):
  ```
  cd export && zip -r ../caipora-web.zip . && cd ..
  ```
- No itch.io (passo manual do usuário — agente prepara o artefato e o checklist):
  - Kind of project: **HTML**.
  - Upload do `caipora-web.zip`; marcar **"This file will be played in the browser"**.
  - Viewport: **1280 × 720**; habilitar fullscreen button.
  - **SharedArrayBuffer support: desligado** (build é single-thread; ligar quebraria sem os
    headers, então manter desligado).
  - Orientação: paisagem; mobile: fora de escopo do MVP.
- Atualizar o link em `README.md` ("link coming soon" → URL da página).

**Critério de Aceitação:**
- [ ] `caipora-web.zip` gerado com `index.html` na raiz
- [ ] Página itch.io carrega o jogo embutido
- [ ] Jogável end-to-end no widget do itch.io
- [ ] README aponta para a URL publicada

---

### 4.6 RF-506 — Matriz de QA no Browser

**Descrição:** Checklist de smoke/QA cobrindo as particularidades do ambiente browser.

**Itens:**
| Item | Esperado |
|------|----------|
| Input de teclado (setas + Espaço) | Funciona sem clicar no canvas (focus_canvas_on_start) |
| Áudio | Toca após o primeiro gesto do usuário (clique/tecla no MainMenu) |
| Persistência de save | `user://savegame.json` sobrevive a reload (IndexedDB do browser) |
| Resize / fullscreen | Canvas ajusta sem distorcer (canvas_resize_policy=2) |
| Console | Sem erros vermelhos durante uma run completa |
| Chrome e Firefox | Comportamento consistente nos dois |

**Critério de Aceitação:**
- [ ] Todos os itens da matriz verificados em Chrome e Firefox
- [ ] Save persiste entre sessões do browser (fechar aba e reabrir)

---

## 5. Requisitos Não-Funcionais

| # | Requisito | Especificação |
|---|-----------|---------------|
| RNF-501 | **Performance** | 60 FPS estável durante combate no browser; sem stutter perceptível no hit-stop. |
| RNF-502 | **Carga** | < 10s em produção (itch.io, comprimido). Barra de progresso visível. |
| RNF-503 | **Compatibilidade** | Chrome e Firefox desktop atuais. Single-thread (sem COOP/COEP). WebGL2 via gl_compatibility. |
| RNF-504 | **Sem regressão** | 29/29 testes GUT verdes antes do export. Nenhum erro no console do browser. |
| RNF-505 | **Reprodutibilidade** | Build gerável por um único comando CLI; passos de publicação documentados. |
| RNF-506 | **Tamanho** | Artefato de publicação dentro dos limites do itch.io (< 1GB; o build ~40MB está folgado). |

---

## 6. Especificações de Teste

### 6.1 Pré-Export (automatizado)
- `godot --headless --import` sem erros de parse.
- Suíte GUT completa: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
  → **29/29 passando**.

### 6.2 Pós-Export (manual, no browser)
- ST-501: Boot no MainMenu (Chrome e Firefox).
- ST-502: Loop completo jogável (Hub → run → win/gameover → Hub).
- ST-503: Timing de ataque e defesa respondem ao Espaço.
- ST-504: SFX após gesto; screenshake/partículas/hit-stop visíveis.
- ST-505: Save persiste após reload (comprar upgrade, recarregar, upgrade mantido).
- ST-506: Load time medido < 10s (produção).
- ST-507: Sem erros no console durante uma run.

> Observação: a Fase 5 é majoritariamente **validação manual no browser** — não há lógica nova
> a testar via GUT, mas a suíte deve permanecer verde como gate de regressão antes do export.

---

## 7. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| `index.wasm` ~37MB → carga lenta | Média | Médio | Compressão gzip/brotli no host (itch.io faz automático). Medir em produção, não local. |
| Áudio não toca antes de gesto (autoplay policy) | Alta | Baixo | Esperado; o primeiro som só ocorre após clique no MainMenu/Espaço — o AudioContext resume naturalmente. Documentar, não "consertar". |
| itch.io com SharedArrayBuffer ligado quebra o build single-thread | Média | Alto | **Manter SharedArrayBuffer desligado** no itch.io (build não usa threads). |
| Zip com `index.html` em subpasta → itch.io não acha o entrypoint | Média | Médio | Zipar a partir de dentro de `export/` (index.html na raiz do zip). |
| Save (IndexedDB) não persistir em modo privado/3rd-party | Baixa | Baixo | Documentar; comportamento esperado de browser. Fora do controle do jogo. |
| Foco do canvas perde input após fullscreen | Baixa | Baixo | `focus_canvas_on_start=true`; testar fullscreen na matriz de QA. |
| `export/` gitignored → build "some" entre máquinas | Baixa | Baixo | Build é artefato; gerar sob demanda via CLI. Não versionar binários. |

---

## 8. Checklist de Entrega da Fase 5

- [ ] **RF-501:** Preset Web validado (single-thread, export_path correto)
- [ ] **RF-502:** Build release gerado via CLI sem erros
- [ ] **RF-503:** Loop completo jogável em Chrome e Firefox (servidor local)
- [ ] **RF-504:** Load time medido e < 10s em produção
- [ ] **RF-505:** `caipora-web.zip` publicado e jogável no itch.io; README atualizado
- [ ] **RF-506:** Matriz de QA verificada nos dois browsers
- [ ] **RNF-504:** 29/29 testes GUT verdes antes do export; console sem erros
- [ ] **ROADMAP:** Marcar tasks da Fase 5 ✅ e fechar o **Definition of Done do MVP**
- [ ] **Commit:** `git commit -m "fase-5: export & publish — html5 build + itch.io"`

---

## 9. Notas para o Agente

### Ordem de Implementação Recomendada
1. **Gate de regressão**: rodar GUT (29/29) e `--import` limpos.
2. **RF-501**: revisar `export_presets.cfg`.
3. **RF-502**: gerar o build via CLI.
4. **RF-503/504/506**: validação no browser local (o usuário roda o servidor e os browsers;
   o agente fornece comandos e o roteiro). Sugerir ao usuário `! python3 -m http.server ...`.
5. **RF-505**: gerar o zip e fornecer o passo-a-passo do itch.io (upload é manual do usuário).
6. Atualizar README + ROADMAP; commit.

### Limites de Automação (o que o agente NÃO faz sozinho)
- ❌ Abrir browsers e "ver" o jogo — validação visual é do usuário (pode usar MCP godot
  `run_project` para um smoke no editor, mas o teste de browser é manual).
- ❌ Fazer upload no itch.io — passo manual com a conta do usuário; o agente entrega o zip e o checklist.
- ❌ Versionar o conteúdo de `export/` (gitignored por design).

### Anti-Padrões a Evitar
- ❌ Ligar `thread_support`/SharedArrayBuffer sem prover COOP/COEP (quebra no itch.io)
- ❌ Medir load time só local descomprimido e concluir que "passou/falhou" (medir em produção)
- ❌ Commitar `.wasm`/`.pck` no git
- ❌ Introduzir mecânica nova nesta fase (é empacotamento/validação)

---

## 10. Decisões Arquiteturais Específicas

### 10.1 Build Single-Thread
**Decisão:** Manter `variant/thread_support=false`.
**Por quê:** Threads no Godot Web exigem isolamento cross-origin (COOP/COEP) e SharedArrayBuffer,
o que complica hospedagem e o embed do itch.io. O MVP não precisa de threads — single-thread
roda em qualquer host estático e no widget do itch.io sem configuração especial.

### 10.2 Build como Artefato (não versionado)
**Decisão:** `export/` permanece gitignored; o build é gerado sob demanda e publicado como zip.
**Por quê:** Binários grandes (wasm ~37MB) não pertencem ao git. A reprodutibilidade vem do
comando de export + templates fixados (4.6.3), não do commit do binário.

### 10.3 Publicação Manual no itch.io
**Decisão:** O agente prepara o zip e o checklist; o upload/configuração é feito pelo usuário.
**Por quê:** Publicar envolve credenciais e uma ação externa irreversível (página pública). O
agente entrega o artefato pronto e instruções precisas; a publicação é decisão do usuário.

---

## 11. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `ROADMAP.md` | Fase 5: Export & Publish; Definition of Done do MVP |
| `REPORT-fase-4.md` | Estado de saída (loop completo, 29/29 testes) |
| `PRD-fase-0.md` / `REPORT-fase-0.md` | Instalação dos templates 4.6.3, primeiro export de baseline |
| `README.md` | Tech stack, link itch.io a atualizar |
| `export_presets.cfg` | Preset "Web" a validar |
