---
name: roblox-architecture-reference
description: >-
  Comprehensive reference for Roblox DataModel hierarchy, runtime execution contexts, network replication boundaries, services, and game object types. Use when architecting, writing, reviewing, or modifying Roblox Luau scripts, game hierarchies, UI components, character rigs, or network replication workflows.
---

# Roblox Architecture Reference

A practical architectural guide to the Roblox DataModel, client-server execution contexts, storage boundaries, and game object behaviors to consult before implementing or refactoring Roblox systems.

## When to Use

- Architecting or refactoring client-server folder structures and script placement
- Writing network code involving `RemoteEvents`, `RemoteFunctions`, or state replication
- Implementing player lifecycle flows, character spawning, or inventory mechanics
- Designing 2D or 3D user interfaces (`ScreenGui`, `BillboardGui`, `SurfaceGui`, `ViewportFrame`)
- Setting up physics assemblies, constraints, motor joints, or animation rigs

---

## Core Architecture and Execution Rules

### 1. DataModel Storage and Replication Boundaries
Roblox runs on a strict client-server model (`FilteringEnabled`). Placement determines replication and security:

- **`Workspace` (`game.Workspace`)**: The physical 3D world. Simulated by the engine and replicated from server to all clients. Keep parts, terrain, cameras, and character models here.
- **`ReplicatedStorage`**: Accessible and replicated to both server and client. Server has read and write authority; clients have read-only access. Place shared `ModuleScripts`, `RemoteEvents`, `RemoteFunctions`, and configuration tables here.
- **`ServerStorage`**: Server-only accessible. Never replicated to clients. Keep secure assets, backend databases, map templates for cloning, and anti-cheat modules here.
- **`ServerScriptService`**: Server-only container for backend `Script` instances. Code here is never exposed or decompiled on the client.

### 2. Player Lifecycle Containers
- **`StarterPlayerScripts` (`StarterPlayer.StarterPlayerScripts`)**: Cloned into `Player.PlayerScripts` upon joining. Runs once per session on the client. Survives character respawn. Ideal for UI controllers, camera management, and network event listeners.
- **`StarterCharacterScripts` (`StarterPlayer.StarterCharacterScripts`)**: Cloned into `Player.Character` on every spawn. Destroyed upon character death. Ideal for health regen, movement state machines, and ragdoll systems.
- **`StarterGui`**: Cloned into `Player.PlayerGui` upon joining or respawn (unless `ScreenGui.ResetOnSpawn = false`). Always manipulate runtime UI via `LocalPlayer.PlayerGui`, not `StarterGui`.
- **`StarterPack`**: Cloned into `Player.Backpack` upon spawning. Stores default equippable `Tool` items.
- **`leaderstats`**: Standard `Folder` named `"leaderstats"` parented directly to a `Player` instance. Numeric `ValueObject` children automatically populate the default engine leaderboard.

### 3. Script Types and Execution Contexts
- **`Script` (`RunContext.Server` or legacy)**: Runs on the server. Used for game logic, data saving, physics validation, and authority.
- **`LocalScript` / `Script` (`RunContext.Client`)**: Runs on the individual user machine. Used for UI interaction, camera manipulation, particle visuals, and raw user input.
- **`ModuleScript`**: Lazily evaluated reusable Luau code loaded via `require()`. Returns a single value (usually a table or function). Cached per environment (server and client maintain separate module memory caches).
- **`RunContext` Property**: Decouples script execution from traditional folder locations. A `Script` set to `RunContext.Client` inside `ReplicatedStorage` will execute on all connected clients.

### 4. Networking and Communication
- **`RemoteEvent`**: Asynchronous one-way message passing (`FireServer`, `FireClient`, `FireAllClients`). Use for notifications, fire-and-forget actions, and frequent updates.
- **`RemoteFunction`**: Synchronous two-way request-response bridge (`InvokeServer`, `InvokeClient`). Yields execution until a response is returned. Avoid `InvokeClient` from the server because an unresponsive or malicious client can hang the server thread permanently.
- **`BindableEvent` / `BindableFunction`**: Intra-environment messaging (client-to-client or server-to-server) across separate script threads without crossing the network boundary.

### 5. Essential Engine Services
- **`Players`**: Tracks connected player instances and provides connection lifecycle hooks (`PlayerAdded`, `PlayerRemoving`).
- **`RunService`**: Controls frame execution pipelines:
  - `RenderStepped`: Client only, runs before frame renders. Use only for camera positioning and character visual alignment.
  - `Stepped`: Runs before physics simulation steps.
  - `Heartbeat`: Runs after physics simulation steps. Preferred for general frame-by-frame updates and timers.
- **`UserInputService` & `ContextActionService`**: Capture client hardware inputs (mouse, keyboard, gamepad, mobile touch). `ContextActionService` allows action binding, unbinding, and automatic mobile button generation.
- **`TweenService`**: Interpolates instance properties smoothly on server or client.
- **`DataStoreService` & `MemoryStoreService`**: Persistent cloud databases (`DataStore`) and high-throughput ephemeral cross-server memory caches (`MemoryStore`).
- **`CollectionService`**: Implements tag-based programming (`AddTag`, `GetTagged`, `HasTag`). Preferred over rigid tree hierarchy traversal.
- **`PathfindingService`**: Computes navigation meshes and dynamic paths (`Path`) for AI entities and NPCs around obstacles.
- **`ProximityPromptService`**: Centralized event listener for `ProximityPrompt` world interactions.
- **`SoundService`**: Controls global audio properties, listener positions, and audio bus mixing through `SoundGroup` hierarchies.

### 6. Common Object Types and Assemblies
- **Spatial & Assemblies**:
  - `Model`: Group of parts. Requires `PrimaryPart` to enable bulk transformation using `:PivotTo()` and `:GetPivot()`.
  - `Folder`: Zero-overhead organizational container without spatial physics calculations.
  - `Attachment`: 3D coordinate point inside a part for constraints, particles, and audio emitters.
  - `Motor6D`: Skeletal rig joint connecting character limbs.
  - `Bone`: Skinning bone for deforming skinned meshes.
  - `IKControl`: Real-time inverse kinematics solver for foot planting and procedural weapon aiming.
- **User Interface**:
  - `ScreenGui`: 2D viewport overlay.
  - `BillboardGui`: 3D world-space GUI oriented toward the camera.
  - `SurfaceGui`: 2D GUI mapped flat onto a 3D part surface.
  - `ViewportFrame`: 2D GUI canvas capable of rendering live 3D objects and scenes inside UI.
  - `Modifiers`: `UIListLayout`, `UIGridLayout`, `UIPadding`, `UICorner`, `UIStroke`, `UIAspectRatioConstraint`, `UIScale`.
- **Interactions & Modifiers**:
  - `ProximityPrompt`: Interaction prompt attached to parts or attachments.
  - `Seat` / `VehicleSeat`: Controls character sitting states and transmits directional input vectors.
  - `Highlight`: Post-processing silhouette outline and interior fill applied to models.
  - `PathfindingModifier`: Navmesh modifier to alter traversal cost or passability.

---

## Architectural Gotchas & Anti-Patterns

1. **Modifying `StarterGui` at Runtime**: Editing `StarterGui` from a `LocalScript` will not update the player's active screen. Always edit `Player.PlayerGui`.
2. **Infinite Server Yields with `InvokeClient`**: Never call `RemoteFunction:InvokeClient()` from the server. If the client errors or exploits, the server thread hangs forever. Use `RemoteEvent:FireClient()` combined with a return `RemoteEvent:FireServer()` instead.
3. **Client Trust and Physics Authority**: Never trust client inputs for health, currency, cooldowns, or position checks. Validate all network requests on the server.
4. **Missing `PrimaryPart` on Models**: Calling `:PivotTo()` on a `Model` without a properly configured `PrimaryPart` can lead to unpredictable rotations or performance degradation.
5. **ModuleScript Caching**: A `ModuleScript` required by the server maintains its own state independent of the client. Requiring the same module on both sides does not share memory across the network.
6. **`ResetOnSpawn` UI Loss**: Remember to set `ScreenGui.ResetOnSpawn = false` for persistent UI (inventories, hotbars, settings menus) so state is not reset upon character death.
