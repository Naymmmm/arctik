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
    :setName("flip-coin")
    :setDescription("Flip a coin!")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)

return Command.new(commandBuilder, function(interaction)
	local responseEmbed = DiscordLuau.EmbedBuilder.new()
	local responseMessage = DiscordLuau.MessageBuilder.new()
	local isHeads = math.random() > 0.5

	responseEmbed:setTitle(`Successfully flipped a coin.`)
	responseEmbed:setDescription(`You got a '{isHeads and "HEADS" or "TAILS"}'!`)
	responseEmbed:setColor(0x5CD85A)
	responseEmbed:setImage({
		imageUrl = isHeads and HEADS_IMAGE_URL or TAILS_IMAGE_URL,
		width = 512,
		height = 512
	})

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)