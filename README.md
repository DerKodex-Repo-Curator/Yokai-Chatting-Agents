# Yokai-2.0 AI Village Walking Simulator - Vertical Slice

A first-person observational walking simulator where 2 AI NPCs live in a small village with persistent backstories and daily routines.

## Features Implemented

### Core Systems
- ✅ **First-Person Player Controller** - WASD movement, mouse look, running with Shift
- ✅ **Village Environment** - Placeholder objects (houses, well, shop, benches, trees)
- ✅ **NPC System** - Two colored cube NPCs with movement and routines
- ✅ **20-Minute Daily Routines** - NPCs follow scheduled activities
- ✅ **AI Backstory System** - Procedurally generated personalities and secrets
- ✅ **LM Studio Integration** - Real-time AI conversations via HTTP API
- ✅ **Weather System** - Dynamic weather affecting NPC behavior
- ✅ **Persistence System** - Save/load backstories and game state
- ✅ **Dev Tools** - Debug UI for monitoring systems

## Controls

### Player Movement
- **WASD** or **Arrow Keys** - Move around
- **Shift** - Run
- **Space** - Jump
- **Mouse** - Look around
- **Escape** - Toggle mouse capture

### Developer Tools
- **F1** - Toggle dev tools panel
- **P** - Pause/unpause game
- **F2** - Refresh backstories (when dev tools open)
- **F3** - Refresh diagnostics (when dev tools open)

## Setup Instructions

### Prerequisites
1. **Godot 4.5** - Download from [godotengine.org](https://godotengine.org/)
2. **LM Studio** - Download from [lmstudio.ai](https://lmstudio.ai/)

### LM Studio Setup
1. Install and launch LM Studio
2. Download a language model (recommended: Llama 3.2 3B or similar small model)
3. Load the model and start the local server
4. Ensure the server is running on `localhost:1234` (default)

### Running the Game
1. Open the project in Godot 4.5
2. Press **F5** or click "Play" to run the game
3. The game will automatically test the LM Studio connection on startup

## How It Works

### NPC Behavior
- Each NPC has a unique **backstory** with personality traits, secrets, and relationship dynamics
- NPCs follow **20-minute daily routines** with 7 phases:
  1. Wake up at home (0-2 min)
  2. Morning walk to well (2-5 min)
  3. Visit shop area (5-8 min)
  4. Social time - seek conversations (8-12 min)
  5. Rest at bench (12-15 min)
  6. Evening walk (15-18 min)
  7. Return home (18-20 min)

### AI Conversations
- NPCs generate conversations based on:
  - Their backstory and personality
  - Current weather conditions
  - Location and nearby objects
  - Proximity to other NPCs
  - Current routine phase
- Conversations are sent to LM Studio API and displayed in the UI

### Weather System
- Weather changes every 5 minutes (randomized)
- Types: Sunny, Cloudy, Rainy, Windy
- NPCs react to weather changes in their conversations
- Visual effects include lighting changes and rain particles

## Development Tools

Press **F1** to open the dev tools panel which shows:

### Backstory Panel
- Current NPC personalities, secrets, and relationships
- Recent conversation history
- Refresh button to update display

### Diagnostics Panel
- System status (AI, Weather, NPCs)
- Performance metrics (FPS, memory)
- Active requests and queue status
- Control buttons for clearing history

### Weather Controls
- Manual weather control buttons
- Random weather trigger
- NPC conversation triggers

## File Structure

```
yokai-2.0/
├── Main.tscn                    # Main scene
├── scripts/
│   ├── GameManager.gd           # Core game controller
│   ├── PlayerController.gd      # First-person movement
│   ├── NPCController.gd         # NPC behavior and routines
│   ├── BackstoryManager.gd      # AI personality generation
│   ├── AISystem.gd              # LM Studio API integration
│   ├── WeatherSystem.gd         # Weather control and effects
│   ├── DevTools.gd              # Debug interface
│   └── PersistenceManager.gd    # Save/load system
├── project.godot                # Project settings
└── DESIGN_DOCUMENT.md           # Complete design specification
```

## Troubleshooting

### LM Studio Connection Issues
- Ensure LM Studio is running and a model is loaded
- Check that the server is on `localhost:1234`
- Look for connection status in the dev tools diagnostics panel
- If connection fails, NPCs will use fallback responses

### Performance Issues
- The game targets 60+ FPS on RTX 4080
- Use dev tools to monitor performance metrics
- Reduce AI conversation frequency if needed

### Save/Load Issues
- Game auto-saves every 5 minutes
- Save files are stored in `user://yokai_save.json`
- Use dev tools to clear conversation history if needed

## Next Steps

This vertical slice demonstrates all core systems working together. Future development phases would include:

1. **Enhanced Visuals** - Replace placeholder cubes with proper 3D models
2. **More NPCs** - Expand to larger village population
3. **Advanced AI** - More sophisticated conversation patterns
4. **Interactive Elements** - Player interaction with environment
5. **Audio System** - Voice synthesis and ambient sounds

## Technical Notes

- Built with Godot 4.5 using GDScript
- HTTP requests to LM Studio API (localhost:1234)
- JSON-based save system with automatic backups
- Modular architecture for easy expansion
- Performance optimized for real-time AI conversations
