# PLAN.md

# Browser Roguelike — Initial Plan

## 1. Product Vision

Create a small classic roguelike that runs directly in the browser and is published on itch.io.

The game should be lightweight, fast to load, easy to understand, and fun within the first few seconds. The player moves on a grid, one tile per action. After each player action, enemies take their turns.

This is a browser-first game, not a desktop game ported to the web.

## 2. Target Platform

Primary target:

- Web / HTML5
- Published on itch.io
- Playable directly in the browser

Out of scope for the initial version:

- Steam
- Desktop builds
- Mobile builds
- Gamepad support
- Multiplayer
- Native plugins
- Cloud save
- Achievements
- Leaderboards

## 3. Recommended Stack

Engine:

- Godot 4.x

Language:

- GDScript

Rendering:

- 2D only

Distribution:

- itch.io HTML5/Web build

Art style:

- Lightweight pixel art
- Small tiles
- Minimal animation

Audio:

- Minimal sound effects
- No heavy music files in the first version

Version control:

- GitHub

## 4. Core Game Concept

A classic turn-based grid roguelike where:

- The player moves one tile at a time.
- Each player action consumes one turn.
- After the player acts, all enemies act.
- Moving into an enemy performs a melee attack.
- Enemies can move toward and attack the player.
- The player has HP.
- Enemies have HP.
- Death ends the run.
- Restart is immediate.

## 5. Design Principles

### 5.1 Browser-first

The game must:

- Load quickly.
- Avoid heavy assets.
- Avoid native plugins.
- Avoid multithreading unless absolutely necessary.
- Avoid complex shaders.
- Avoid large audio files.
- Work well embedded inside an itch.io page.

### 5.2 Simple rules, clear feedback

The player should always understand:

- Where they can move.
- When they attacked.
- When they were attacked.
- How much HP they have.
- Why they died.
- How to restart.
