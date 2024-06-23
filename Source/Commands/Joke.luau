local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("get-joke")
    :setDescription("Fetch a funny joke to share on Discord")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)

return Command.new(commandBuilder, function(interaction)
    interaction:deferAsync():await()

	local responseEmbed = DiscordLuau.EmbedBuilder.new()
	local responseMessage = DiscordLuau.MessageBuilder.new()
	local request = Net.request({
		url = "https://v2.jokeapi.dev/joke/Any?safe-mode&type=single&format=json",
		method = "GET"
	})

	if not request.ok then
		responseEmbed:setTitle("Failed to fetch a Joke")
		responseEmbed:setDescription(`Error: '{request.statusMessage}'`)
		responseEmbed:setFooter({ text = "Request to fetch joke failed..", icon = "" })
		responseEmbed:setColor(0xFF0000)
	else
		local requestBodyJsonDecoded = Net.jsonDecode(request.body)

		responseEmbed:setTitle(`Successfully fetched a Joke`)
		responseEmbed:setFooter({ text = "Thank you v2.jokeapi.dev!", icon = "" })
		responseEmbed:setColor(0x5CD85A)
		responseEmbed:setDescription(requestBodyJsonDecoded.joke)
	end

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)