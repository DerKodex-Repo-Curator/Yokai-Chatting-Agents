# Yokai 2.0 - AI Village Walking Simulator

A first-person walking simulator featuring AI-driven NPCs with persistent backstories and dynamic conversations in a small village environment.

## Features

- **First-Person Exploration** - WASD movement with mouse look
- **AI NPCs** - Two NPCs with unique personalities and 20-minute daily routines
- **Dynamic Conversations** - Real-time AI responses via LM Studio integration
- **Weather System** - Dynamic weather affecting NPC behavior
- **Persistence** - Auto-save backstories and game state
- **Dev Tools** - Debug interface for monitoring systems

## Quick Start

### Prerequisites
- [Godot 4.5](https://godotengine.org/)
- [LM Studio](https://lmstudio.ai/) with a loaded language model (and server running)

### Setup
1. Start LM Studio with a model loaded on `localhost:1234`
2. Open project in Godot 4.5
3. Press **F5** to run

## Controls

**Movement:** WASD/Arrow Keys, Shift (run), Space (jump), Mouse (look)  
**Dev Tools:** F1 (toggle panel), P (pause), F2/F3 (refresh data)

## How It Works

NPCs follow scheduled 20-minute routines through 7 phases (wake → well → shop → social → rest → walk → home). They generate contextual conversations based on their backstories, current weather, location, and nearby NPCs using the LM Studio API.

## Architecture

```
scripts/
├── GameManager.gd           # Core game controller
├── PlayerController.gd      # First-person movement
├── NPCController.gd         # NPC behavior and routines
├── BackstoryManager.gd      # AI personality generation
├── AISystem.gd              # LM Studio API integration
├── WeatherSystem.gd         # Weather system
├── DevTools.gd              # Debug interface
└── PersistenceManager.gd    # Save/load system
```

## Troubleshooting

- **No AI responses:** Ensure LM Studio is running with a model loaded
- **Performance issues:** Check dev tools (F1) for metrics
- **Save issues:** Game auto-saves every 5 minutes to `user://yokai_save.json`

Built with Godot 4.5 and GDScript. See `DESIGN_DOCUMENT.md` for complete technical specifications.