fx_version 'cerulean'
game 'gta5'

author 'COII'
description 'meow'
version '1.0.0'

dependency 'es_extended'

shared_script 'config.lua'
client_scripts {
    'client/theme.lua',
    'client/alert-theme.lua',
    'client/minimap.lua',
    'client/quick-menu.lua',
    'client/native-check.lua'
}
server_script 'server/main.lua'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/styles.css',
    'web/app.js',
    'web/theme.js',
    'web/quick-menu.js',
    'web/quick-menu.css',
    'web/logo.png',
    'web/fonts/BarlowSemiCondensed-ExtraBoldItalic.ttf',
    'web/fonts/BarlowSemiCondensed-Medium.ttf',
    'assets/pause-lines.png',
    'assets/radar-mask.png'
}

exports {
    'SetMinimapVisible',
    'RefreshMinimapLayout'
}
