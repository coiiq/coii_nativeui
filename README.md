# COII Native UI

A free FiveM resource for ESX with a custom pause menu, full-screen map, redesigned settings and key bindings, themed alerts, and a circular minimap.

## Screenshots

<p align="center">
  <img src="https://i.imgur.com/79gcYl7.jpeg" width="48%" alt="Minimap">
  <img src="https://i.imgur.com/xBGuMyt.jpeg" width="48%" alt="Pause Menu">
  <img src="https://i.imgur.com/CrcaMPE.jpeg" width="48%" alt="Map">
  <img src="https://i.imgur.com/l0IRrAR.jpeg" width="48%" alt="Settings">
  <img src="https://i.imgur.com/S4oovmj.png" width="48%" alt="Alert">
</p>

## Installation

1. Put the resource in your server's `resources` folder, named `coii_nativeui`.
2. Edit `config.lua` and replace `web/logo.png` with your server logo.
3. Add these lines to `server.cfg` in this order:

```cfg
ensure es_extended
ensure coii_nativeui
```

Fully close and reopen FiveM after installing or updating the streamed UI files.

## Configuration

- `ServerName` and `ServerLogo`: server branding.
- `AccentColour` and `BackgroundColour`: six-digit hex colours.
- `MinimapEnabled`: set to `false` to disable minimap. Menus and the full-screen map stay enabled.
- `QuickMenu.website`: HTTPS link, or leave empty to disable the button.
- `SetHudVisible`: call your HUD export here to hide it while menus are open and restore it afterwards.

Restart the resource after changing configuration. Keep `Debug = false` for normal use.

## Client exports

Hide the radar and minimap overlay:

```lua
exports['coii_nativeui']:SetMinimapVisible(false)
```

Use `true` to show when gameplay allows, or `nil` to restore automatic visibility. These exports cannot enable a minimap disabled in config.

To refresh its position and size:

```lua
exports['coii_nativeui']:RefreshMinimapLayout()
```

## Compatibility

Other resources replacing the same pause-menu, alert, or minimap files can conflict. Test alongside your HUD and map resources.

More details: [installation](docs/INSTALLATION.md).
