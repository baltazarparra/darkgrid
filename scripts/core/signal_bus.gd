extends Node

# Global event bus. All systems emit and listen here.
# Keeps decoupling between gameplay modules.

# ─── Enums ─────────────────────────────────────────
enum Screen { MAIN_MENU, EXPLORATION, ARENA, GAME_OVER, WIN, HUB, EXPLORATION_PHASE2, ARENA_PHASE2 }

# ─── Signals ───────────────────────────────────────
signal screen_changed(new_screen: Screen)
signal arena_entered(arena_id: String)
signal arena_exited(won: bool)

# Reservados p/ Fase 4 (HUD / GameOver) — ainda sem emissor no MVP atual.
signal caipora_died
signal caipora_health_changed(new_health: float, max_health: float)
signal enemy_health_changed(new_health: float, max_health: float)
signal fragment_gained(total: float, amount: float)
signal chest_opened

# ─── Diálogo pré-boss ──────────────────────────────
signal boss_intro_started
signal dialogue_finished
