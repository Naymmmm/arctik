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
    :setName("get-avatar")
    :setDescription("Fetch the avatar of a user!")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
	:addOption(
			(DiscordLuau.CommandOptionBuilder.new() :: any)
				:setType(DiscordLuau.CommandOptionBuilder.Type.User)
				:setChannelTypes(DiscordLuau.CommandOptionBuilder.ChannelType.GuildVoice)
				:setDescription("The user you'd like the image of")
				:setName("target-user")
				:setRequired(true)
		)

return Command.new(commandBuilder, function(interaction)
	local userId = (interaction.data :: any).options["1"].value
	local user = (interaction.data :: any).resolved.users[userId]

	local avatarHash = user.avatar

	local responseEmbed = DiscordLuau.EmbedBuilder.new()
	local responseMessage = DiscordLuau.MessageBuilder.new()

	responseEmbed:setTitle(`{user.username}'s Avatar`)
	responseEmbed:setColor(0x5CD85A)
	responseEmbed:setImage({
		imageUrl = `https://cdn.discordapp.com/avatars/{userId}/{avatarHash}.webp?size=240`,
		width = 240,
		height = 240,
	})

	responseMessage:addEmbed(responseEmbed)

	interaction:sendMessageAsync(responseMessage)
end)