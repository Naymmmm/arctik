local DiscordLuau = require("../DiscordLuau")

local CommandInvoker = require("@Singletons/CommandInvoker")

local BOT_TOKEN = require("../env").BotToken

local DiscordSetting = DiscordLuau.SettingsBuilder.new(BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSetting)

DiscordClient.eventManager.onInteraction:connect(function(interaction)
    CommandInvoker.onCommandInvoked(interaction)
end)

DiscordClient:connectAsync():after(function()
    print(`DiscordClient has connected to the Discord Websocket! Waiting for Ready..`)
    
    DiscordClient.eventManager.onReady:wait()

    print(`DiscordClient "{DiscordClient.discordUser.username}" is Ready! Updating application commands..`)

    CommandInvoker.buildCommands()
    CommandInvoker.updateCommands(DiscordClient)

    print(`DiscordClient "{DiscordClient.discordUser.username}" has updated all Application commands!`)
end)

return DiscordClient