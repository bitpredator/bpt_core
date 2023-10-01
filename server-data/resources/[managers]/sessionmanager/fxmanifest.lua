-- This resource is part of the default Cfx.re asset pack (cfx-server-data)
-- Altering or recreating for local use only is strongly discouraged.

version '1.0.0'
author 'bitpredator'
description 'Handles the "host lock" for non-OneSync servers. Do not disable.'

fx_version 'cerulean'
games {'gta5' }

server_script 'server/host_lock.lua'
client_script 'client/empty.lua'