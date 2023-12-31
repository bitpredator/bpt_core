fx_version 'adamant'
game 'gta5'
description 'bpt_core FiveM RP Framework Core'
author 'bitpredator'

lua54 'yes'
version '1.0.0'

shared_scripts {
	'locale.lua',
	'locales/*.lua',
	'config.lua',
	'config.weapons.lua',
	'dependencies/async/*.lua'
}

server_scripts {
	'@bptmysql/lib/MySQL.lua',
	'server/common.lua',
	'server/classes/player.lua',
	'server/classes/overrides/*.lua',
	'server/functions.lua',
	'server/onesync.lua',
	'server/paycheck.lua',
	'server/main.lua',
	'server/commands.lua',
	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua',
	'dependencies/cron/server/*.lua',
	'dependencies/hardcap/server/*.lua'
}

client_scripts {
	'client/common.lua',
	'client/functions.lua',
	'client/wrapper.lua',
	'client/main.lua',
	'client/modules/death.lua',
	'client/modules/scaleform.lua',
	'client/modules/streaming.lua',
	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua',
	'dependencies/hardcap/client/*.lua'
}

ui_page {
	'html/ui.html'
}

files {
	'imports.lua',
	'locale.js',
	'html/ui.html',
	'html/css/app.css',
	'html/js/mustache.min.js',
	'html/js/wrapper.js',
	'html/js/app.js',
	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf'
}

dependencies {
	'/server:5949',
	'/onesync',
	'bptmysql',
	'spawnmanager',
}