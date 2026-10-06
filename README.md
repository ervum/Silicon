# ✨ Silicon

[![Main Programming Language](https://img.shields.io/badge/python-3.9%20|%203.10%20|%203.11-0078d7.svg?color=%23fff\&logo=Python\&logoColor=%23fff\&style=for-the-badge)](https://en.wikipedia.org/wiki/Python_%28programming_language%29) ![Secondary Programming Language](https://img.shields.io/badge/luau-0.676-white.svg?logo=lua&logoColor=white&style=for-the-badge)

[![Operating System](https://img.shields.io/badge/platform-Windows%20|%20Mac%20|%20Linux-0078d7.svg?color=%23fff\&logo=Windows\&logoColor=%23fff\&style=for-the-badge)](https://en.wikipedia.org/wiki/Operating_system) [![Architecture](https://img.shields.io/badge/architecture-x86%20|%20x64%20|%20x32-%23fff.svg?color=%23fff\&logo=Aurelia\&logoColor=%23fff\&style=for-the-badge)](https://en.wikipedia.org/wiki/Instruction_set_architecture)

## 🚀 Getting Started

### Prerequisites

> Make sure Python 3.9 – 3.11 is installed on your system.

> Get Silicon's [official Roblox Plugin](https://create.roblox.com/store/asset/130303466729127).

### Windows

> * Launch Command Prompt:
>
>   1. Press `Windows + R`, type `CMD`, then press Enter.

> * Run the command:

```batch
curl -L -o python-installer.exe https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe && python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_launcher=0 && del python-installer.exe && python -m ensurepip && python -m pip install requests pyyaml
```

### Mac

> * Open Terminal:
>
>   1. Press `Command + Space`, type `Terminal`, then press Enter.

> * Run the command:

```bash
curl -L -o python-installer.pkg https://www.python.org/ftp/python/3.11.0/python-3.11.0-macos11.pkg && sudo installer -pkg python-installer.pkg -target / && rm python-installer.pkg && python3 -m ensurepip && python3 -m pip install requests pyyaml
```

### Linux

> * Open Terminal:
>
>   1. Press `Ctrl + Alt + T`.

> * Run the command:

```bash
sudo apt-get update && sudo apt-get install python3 python3-pip && python3 -m pip install requests pyyaml
```

---

## ⚙️ Usage

### 1. Start the CLI Server

Run `Silicon.py` (or `Silicon.bat` from `bin/`) with your desired synchronization mode:

```bash
python Silicon.py <Command> [options]
```

> **Available Commands:**
>
> * `Bidirectional`: Continuously synchronizes scripts and hierarchy bidirectionally between Roblox Studio and the local IDE directory with instant reactivity and Recycle Bin safety.
> * `BidirectionalFromRoblox`: Starts bidirectional synchronization with an initial export from Roblox Studio to the local IDE directory.
> * `BidirectionalFromIDE`: Starts bidirectional synchronization with an initial import from the local IDE directory to Roblox Studio.
> * `AllDescendants`: Continuously synchronizes **ALL** descendants of `game` (scripts, folders, models, UI, etc.) bidirectionally between Roblox Studio and the local IDE directory.
> * `Export`: One-time export of place scripts and their ancestry to the local IDE directory.
> * `Import`: One-time import of scripts from the local IDE directory into Roblox Studio.
> * `ExportSynchronize`: One-way live synchronization from IDE to Roblox Studio upon file changes.
> * `ImportSynchronize`: One-way live synchronization from Roblox Studio to IDE upon editing scripts.
> * `Server`: Runs the background HTTP long-polling synchronization server.

> **Command Options:**
>
> * `--Target`, `-p`: Target directory where game files are stored (defaults to `Silicon/Game`).
> * `--Settings`, `-s`: Custom path to `Settings.yaml` configuration file.
> * `--Host`, `-H`: Web host address (defaults to `localhost`).
> * `--Port`, `-P`: Port number (defaults to `6969`).
> * `--Script`, `-S`: Filter processing to a specific script and its ancestry.

### 2. Connect via Roblox Studio

Open Roblox Studio and use the **Silicon** toolbar buttons:

> Interact with the toolbar buttons (`Bidirectional`, `Bidirectional from Roblox`, `Bidirectional from IDE`, `All Descendants`, `Export`, `Import`, etc.) to initiate live or one-shot synchronization directly within Studio.

---

## 📁 Architecture & Organization

Silicon structures synchronized Roblox hierarchies into an intuitive, modular on-disk representation:

1. **Uniform Instance Folders**: Every in-game object (services, folders, scripts, GUI elements, parts) is represented as a folder matching its instance name.
2. **Properties File (`Properties.yaml` / `Properties.json`)**: Every instance folder contains a `Properties.yaml` (default) or `Properties.json` file preserving:
   * Engine properties (`ClassName`, `Color`, `Size`, `CFrame`, `Anchored`, etc.).
   * Custom attributes under `__Attributes__`.
   * CollectionService tags under `__Tags__`.
3. **Script Source (`Source.[Type].luau`)**: Scripts additionally contain a source file indicating their runtime context:
   * `Source.server.luau` (Server scripts)
   * `Source.client.luau` (Client / LocalScripts)
   * `Source.shared.luau` (ModuleScripts)
4. **Selective Hierarchy**: By default, empty folders are only created if they are part of the direct ancestry of a script. To synchronize every instance in the game, run the `AllDescendants` command.

---

## 🛡️ Non-Destructive Safety & Recycle Bin

* **Studio Recycle Bin**: Deletions triggered by the IDE move instances to `ReplicatedStorage/Silicon/Recycle Bin` in Roblox Studio rather than permanently destroying them.
* **System Recycle Bin**: Files deleted or pruned from the local workspace are safely sent to the operating system's Recycle Bin / Trash (`SendToRecycleBin`).
* **Isolated Plugin Storage**: The running plugin installs and maintains a clean local copy at `ReplicatedStorage/Silicon/Silicon` (configurable via `RootFolderName` and `PluginFolderName` in `Settings.yaml`) that is strictly excluded from export to avoid self-referential clutter while allowing `ReplicatedStorage/Silicon/Recycle Bin` to sync smoothly.

---

## 🧪 Key Features

1. **Instant Reactive Synchronization**
   * Roblox Studio uses `ScriptEditorService` to stream live edits to disk without requiring document close.
   * Local file modifications immediately patch live Studio script instances without resetting cursor position or editor state.
2. **Zero-Latency Event Streaming**
   * Custom long-polling HTTP architecture (`/changes` endpoint) ensures instant delivery of changes without polling bottlenecks.
3. **Cross-Platform Compatibility**
   * Native support for Windows, macOS, and Linux.
4. **Global CLI Integration**
   * Add `Silicon/bin` to your `PATH` or invoke `bin/Silicon.bat` to synchronize any project from anywhere.

---

## 📦 Dependencies

Python dependencies:

```
requests
pyyaml
```

Built-in modules utilized: `traceback`, `threading`, `argparse`, `http.server`, `socketserver`, `hashlib`, `shutil`, `ctypes`, `gzip`, `json`, `time`, `sys`, `io`, `os`.

Roblox Plugin dependencies:
* `ScriptEditorService`
* `HttpService`
* `APIService` (included)

---

## 💡 Tip

Bind `Silicon.bat Bidirectional` to a startup task or terminal tab in your IDE workspace. Whenever you launch development, your local files and Studio session will synchronize seamlessly and safely.
