local FileSystem = require("@lune/fs")
local Task = require("@lune/task")

local DiscordLuau = require("../../DiscordLuau")

local registeredCommands: { [DiscordLuau.CommandBuilder]: (interaction: DiscordLuau.DiscordInteraction) -> () } = {}

local CommandInvoker = { }

function CommandInvoker.registerCommand(command: DiscordLuau.CommandBuilder, callback: (interaction: DiscordLuau.DiscordInteraction) -> ())
    registeredCommands[command] = callback
end

function CommandInvoker.onCommandInvoked(interaction: DiscordLuau.DiscordInteraction)
    for command, commandCallback in registeredCommands do
        if command.commandName ~= interaction.data.name then
            continue
        end

        return commandCallback(interaction)
    end
end

function CommandInvoker.buildCommands()
    for _, commandFile in FileSystem.readDir("Source/Commands") do
        local commandName = commandFile:match("(.+)%.luau")
        local commandUuid = `{commandName}_{os.clock()}.luau`

        local _req = require :: any

        FileSystem.writeFile(`Source/Commands/{commandUuid}`, FileSystem.readFile(`Source/Commands/{commandFile}`))

        _req(`../Commands/{commandUuid}`)

        Task.defer(function()
            FileSystem.removeFile(`Source/Commands/{commandUuid}`)
        end)
    end
end

function CommandInvoker.updateCommands(discordClient: DiscordLuau.DiscordClient)
    local commandObjects: { DiscordLuau.CommandBuilder } = { }

    for commandObject in registeredCommands do
        table.insert(commandObjects, commandObject)
    end

    discordClient.discordApplication:setSlashCommandsAsync(commandObjects):await()
end

return CommandInvoker