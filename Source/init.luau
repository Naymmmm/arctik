local DiscordLuau = require("../DiscordLuau")
local Environment = require("../env")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local CommandInvoker = require("@Singletons/CommandInvoker")

local BOT_TOKEN = Environment.BotToken

local DiscordSetting = DiscordLuau.SettingsBuilder.new(BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSetting)
local PresenceBuilder = DiscordLuau.PresenceBuilder
local ActivityBuilder = DiscordLuau.ActivityBuilder

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

DiscordClient.eventManager.onMessage:connect(function(msg)
    local nahBuild = DiscordLuau.MessageBuilder.new()
    nahBuild:setContent("yuh, i don't support talkin to ya in dms, sorry")
    if not msg.guildId then
        msg:replyAsync(nahBuild)
    end
end)

DiscordClient.eventManager.onGuildCreate:connect(function(guild)

end)



DiscordClient:connectAsync():after(function()
    local Thingo = PresenceBuilder.new()
    Thingo:addActivity(ActivityBuilder.new():setActivityName("what is the wecommended amount of dedocwated wam"))
    ConsoleInfo(1, "Websocket successfully connected!", "DiscordClient")
    
    DiscordClient.eventManager.onReady:wait()

    ConsoleInfo(1, string.format("Connected to %s successfully! Attempting to update commands.", DiscordClient.discordUser.username), "DiscordClient")

    CommandInvoker.buildCommands()
    CommandInvoker.updateCommands(DiscordClient)

    ConsoleInfo(1, string.format("%s successfully updated application commands!", DiscordClient.discordUser.username), "DiscordClient")
    DiscordClient:updatePresenceAsync(Thingo)
end)

while true do
    task.wait(5)
    local Fentanyl = {"what is the wecommended amount of dedocwated wam", "serious tacos", "this bot is open source!", "discordluau is tasty", "luau-lsp has terrible types"}
    local Thingo = PresenceBuilder.new()
    Thingo:addActivity(ActivityBuilder.new():setActivityName(Fentanyl[math.random(1, #Fentanyl)]))
    DiscordClient:updatePresenceAsync(Thingo)
end

return DiscordClient