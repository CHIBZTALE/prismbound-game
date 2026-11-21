# PRISMBOUND — Godot 4 prototype

PRISMBOUND is an original three-lane 3D rift-runner prototype. Swipe left/right (or use A/D / arrow keys) to shift lanes, collect amber energy shards, and avoid crimson rift blocks. The prototype runs offline.

## Open and run
1. Install Godot 4.3 or newer on a desktop computer.
2. Import this folder using project.godot.
3. Press F6/F5 or the Play button.

## Android direction
This is a Godot project, not an APK yet. To export:
1. Install Godot export templates matching your Godot version.
2. Configure Android SDK, JDK 17, and Android build tools in Editor Settings.
3. Add an Android export preset and export a debug APK.
4. Test on multiple Android screen sizes and performance tiers.

## Prototype scope
- Procedural 3D track, lighting, reflective materials and glow
- Three-lane swipe / keyboard movement
- Endless obstacle and shard spawning
- Collision, score, shard counter, retry
- Offline play

## Production milestones
- Replace primitive meshes with original authored 3D assets and VFX
- Add sound, music, haptics, tutorial and progression
- Add local save data and accessibility settings
- Add secure online accounts, cloud saves and leaderboards
- Profile and optimize on target Android devices

This repository contains an early playable prototype. It has not yet been validated in the Godot editor or exported as an Android APK.