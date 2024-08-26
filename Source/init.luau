local DiscordLuau = require("../DiscordLuau")
local Environment = require("../env")
local stdio = require("@lune/stdio")

local CommandInvoker = require("@Singletons/CommandInvoker")

local BOT_TOKEN = Environment.BotToken

local DiscordSetting = DiscordLuau.SettingsBuilder.new(BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSetting)

function ConsoleInfo(type: number, info: string, from: string) -- google gemini clutch (i suck at lua)
    if type == 1 then
        stdio.write(stdio.color("blue"))
        print(string.format("[%s] %s", from, info))
    elseif type == 2 then
        stdio.write(stdio.color("yellow"))
        print(string.format("[%s] %s", from, info))
    elseif type == 3 then
        stdio.write(stdio.color("red"))
        print(string.format("[%s] %s", from, info))
    end
end

DiscordClient.eventManager.onInteraction:connect(function(interaction)
    CommandInvoker.onCommandInvoked(interaction)
end)

DiscordClient:connectAsync():after(function()
    ConsoleInfo(1, "Websocket successfully connected!", "DiscordClient")
    
    DiscordClient.eventManager.onReady:wait()

    ConsoleInfo(1, string.format("Connected to %s successfully! Attempting to update commands.", DiscordClient.discordUser.username), "DiscordClient")

    CommandInvoker.buildCommands()
    CommandInvoker.updateCommands(DiscordClient)

    ConsoleInfo(1, string.format("%s successfully updated application commands!", DiscordClient.discordUser.username), "DiscordClient")
end)

return DiscordClient