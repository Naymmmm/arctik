local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local HEADS_IMAGE_URL = "https://i.ibb.co/cNLMgZd/HEAD.png"
local TAILS_IMAGE_URL = "https://i.ibb.co/9ZxVV2X/TAILS.png"

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("get-doggo")
    :setDescription("Fetch a Dog from a repository of dog photos!")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)

return Command.new(commandBuilder, function(interaction)
	interaction:deferAsync()

	local responseEmbed = DiscordLuau.EmbedBuilder.new()
	local responseMessage = DiscordLuau.MessageBuilder.new()
	local request = Net.request({
		url = "https://dog.ceo/api/breeds/image/random",
		method = "GET"
	})

	if not request.ok then
		responseEmbed:setTitle("Failed to fetch a Dog image.")
		responseEmbed:setDescription(`Error: '{request.statusMessage}'`)
		responseEmbed:setFooter({ text = "Request to fetch dog image failed..", icon = "" })
		responseEmbed:setColor(0xff0000)
	else
		local requestBodyJsonDecoded = Net.jsonDecode(request.body)

		responseEmbed:setTitle(`Successfully fetched a Dog image.`)
		responseEmbed:setFooter({ text = "Thank you dog.ceo!", icon = "" })
		responseEmbed:setColor(0x5CD85A)
		responseEmbed:setImage({
			imageUrl = requestBodyJsonDecoded.message,
			width = 512,
			height = 512
		})
	end

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)