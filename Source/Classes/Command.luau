local DiscordLuau = require("../../DiscordLuau")

local CommandInvoker = require("@Singletons/CommandInvoker")

local Command = {}

Command.Interface = {}

function Command.Interface.new(command: DiscordLuau.CommandBuilder, callback: (interaction: DiscordLuau.DiscordInteraction) -> ())
    CommandInvoker.registerCommand(command, function(interaction: DiscordLuau.DiscordInteraction)
        -- if (interaction.data :: any).type == 1 then
        --     return -- todo: support PING requests.
        -- end
    
        return callback(interaction)
    end)

    return command
end

return Command.Interface