local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("get-ping")
    :setDescription("Get the average time it takes for all discord shards to communicate to the Discord WebSocket!")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)

return Command.new(commandBuilder, function(interaction)
	local responseEmbed = DiscordLuau.EmbedBuilder.new()
	local responseMessage = DiscordLuau.MessageBuilder.new()

	responseEmbed:setTitle(`Average Shard Pings`)
	responseEmbed:setColor(0x5CD85A)

	for shardId, shard in interaction.discordClient.discordShards do
		responseEmbed:addField({
			name = `Shard '{shardId}'`,
			value = `{shard.heartbeatPing}ms`
		})
	end

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)