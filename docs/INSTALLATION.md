# COII Native UI — Installation

## Requirements

- FiveM server using ESX
- `es_extended` started before this resource
- A full FiveM client restart after installing or updating streamed pause-menu files

## Install

1. Copy the `coii_nativeui` folder into your server's `resources` directory.
2. Configure `config.lua` and replace `web/logo.png` with your server logo.
3. Add `ensure coii_nativeui` after `ensure es_extended` in `server.cfg`.
4. Fully close and reopen FiveM before testing. A resource restart can leave an older frontend movie cached.

## Important configuration

- `ServerName` and `ServerLogo` control pause-menu branding.
- `AccentColour` and `BackgroundColour` accept six-digit hex colours.
- `QuickMenu.website` must be a public HTTPS URL. Leave it empty to disable Website.
- `MinimapEnabled = false` disables this resource's gameplay minimap while keeping the pause menu, Settings, and full-screen Map available.
- `SetHudVisible` can call a third-party HUD export when pause interfaces open or close.
- `Debug` should remain `false` on production servers.

## Client exports

```lua
exports['coii_nativeui']:SetMinimapVisible(false) -- hide radar and overlay immediately
exports['coii_nativeui']:SetMinimapVisible(true)  -- show when gameplay guards allow it
exports['coii_nativeui']:SetMinimapVisible(nil)   -- restore automatic visibility rules
exports['coii_nativeui']:RefreshMinimapLayout()   -- remeasure/reapply the minimap layout
```

These are client exports. `SetMinimapVisible` cannot enable the minimap when `Config.MinimapEnabled` is `false`.

## Compatibility

Only one resource should replace a given GTA pause-menu Scaleform. Resources that stream the same `pause_menu_*.gfx`, `popup_warning.gfx`, `minimap.gfx`, or `minimap.ytd` files can conflict with this resource.

The supplied native presentation targets the tested GTA/FiveM frontend build. Test again after major game-build changes.
