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
    :setName("get-catto")
    :setDescription("Fetch a Cat from a repository of cat photos!")
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
		url = "https://api.thecatapi.com/v1/images/search?format=json",
		method = "GET"
	})

	if not request.ok then
		responseEmbed:setTitle("Failed to fetch a Cat image.")
		responseEmbed:setDescription(`Error: '{request.statusMessage}'`)
		responseEmbed:setFooter({ text = "Request to fetch cat image failed..", icon = "" })
		responseEmbed:setColor(0xff0000)
	else
		local requestBodyJsonDecoded = Net.jsonDecode(request.body)

		responseEmbed:setTitle(`Successfully fetched a Cat image.`)
		responseEmbed:setFooter({ text = "Thank you api.thecatapi.com!", icon = "" })
		responseEmbed:setColor(0x5CD85A)
		responseEmbed:setImage({
			imageUrl = requestBodyJsonDecoded[1].url,
			width = requestBodyJsonDecoded[1].width,
			height = requestBodyJsonDecoded[1].height
		})
	end

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)