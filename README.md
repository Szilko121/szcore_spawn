# szcore_spawn

**SzCore Framework 1.4.0-rc1** · by **SzCode**

Spawn selection and saved-position spawning for loaded characters.

## Install
```bash
git clone https://github.com/Szilko121/szcore_spawn.git resources/[szcore]/szcore_spawn
```
Dependencies: `szcore`, `spawnmanager`.

## Role
Listens for the SzCore player-loaded lifecycle event and spawns the selected character at its persisted position, falling back to the core default position. Character persistence remains owned by `szcore`.

See `docs/API.md`, `docs/CONFIGURATION.md`, and the central `SzCore-Framework` documentation.
