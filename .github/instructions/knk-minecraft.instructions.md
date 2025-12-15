---
name: KnK Minecraft Plugin Rules
applyTo: "Repository/knk-plugin-v2/**/*.{java,kt,yml,gradle,kts}"
---

## General
- Follow existing command/event/listener/service patterns in the plugin.
- Do not add heavy dependencies unless required and aligned with existing build setup.

## API integration
- All Web API calls must go through the plugin’s existing API client/communication layer.
- Keep DTOs aligned with the shared contract approach used in this repo (do not invent new DTO schemas).

## Game-specific logic split
- Game-world specific operations (WorldGuard regions, Locations in the Minecraft world, block operations) stay in the plugin.
- Domain data persistence, validation, and CRUD flows should be handled by the Web API + Web App unless explicitly stated.
