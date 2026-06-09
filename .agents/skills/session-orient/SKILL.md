---
name: session-orient
description: Orienta o início de sessão no projeto caipora — lê PLAN.md, verifica baseline, seleciona a task mais prioritária
disable-model-invocation: true
---
Executa o Session Protocol do projeto caipora:

1. Ler `PLAN.md` — identificar o milestone atual e o item mais prioritário incompleto
2. Checar `git status` — verificar estado do repositório
3. Rodar `make smoke` — abortar se falhar (não tocar em nada com smoke quebrado)
4. Selecionar **UMA task** (a mais prioritária incompleta do milestone atual em PLAN.md)
5. Reportar: task selecionada + resultado do smoke + próximo passo

**Regras:**
- Uma task por sessão. Não bata múltiplas mudanças não relacionadas.
- Commitar após cada task bem-sucedida.
- Se descobrir um bug não relacionado, documentar em PLAN.md → "Known Issues" antes de continuar.
- Atualizar `AGENTS.md` se descobrir um novo gotcha.
- **Nunca suavize o horror.** A floresta é hostil. A Caipora é perigosa. O sangue é real.
