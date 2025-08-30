fx_version 'cerulean'
game 'gta5'

name 'corex-blackmarket'
description 'Advanced Black Market System for QBCore'
author 'Oskydoki'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/assets/*.otf',
    'html/assets/sounds/*.mp3',
    'html/assets/sounds/*.wav'
}

dependencies {
    'qb-core',
}

