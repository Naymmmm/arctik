local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local GetColorName = require("@Functions/GetColorName")
local PNG = require("@Dependencies/PNG")

local Command = require("@Classes/Command")

local COLOR_PNG_SIZE = 512

local HexToBinaryMap = {
    ['0']='0000', ['1']='0001', ['2']='0010', ['3']='0011',
    ['4']='0100', ['5']='0101', ['6']='0110', ['7']='0111',
    ['8']='1000', ['9']='1001', ['a']='1010', ['b']='1011',
    ['c']='1100', ['d']='1101', ['e']='1110', ['f']='1111'
}

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("get-color")
    :setDescription("Fetch either a random color, or optionally a specific color from hex.")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("color-code")
            :setDescription("Optional hex color code")
            :setRequired(false)
            :setType(DiscordLuau.CommandOptionBuilder.Type.String)
    )

local function randomHexColor()
    return string.format("%x", math.random(16777215))
end

local function hexToRgb(hex: string)
    return tonumber(`0x{string.sub(hex, 1,2)}`) :: number, tonumber(`0x{string.sub(hex, 3,4)}`) :: number, tonumber(`0x{string.sub(hex, 5,6)}`) :: number
end

return Command.new(commandBuilder, function(interaction)
    local hexString = (interaction.data :: any).options and (interaction.data :: any).options["1"].value or randomHexColor()
    local hexColor = string.gsub(hexString, "#", "")
    local hexColorCode = tonumber(hexColor, 16)

    local osStart = os.clock()

    if hexColorCode then
        local clockTime = os.clock() - osStart
        local timeMs = math.round(clockTime * 100)
        local hexSplit = string.split(hexColor, "")

        local binary = ""

        for index, char in hexSplit do
            binary ..= `{HexToBinaryMap[char]}{index == #hexSplit and "" or " "}`
        end

        local pngBinaryData = table.create(COLOR_PNG_SIZE * COLOR_PNG_SIZE)
        local r, g, b = hexToRgb(hexColor)

        for index = 1, (COLOR_PNG_SIZE * COLOR_PNG_SIZE) do
            table.insert(pngBinaryData, r / 255)
            table.insert(pngBinaryData, g / 255)
            table.insert(pngBinaryData, b / 255)
            table.insert(pngBinaryData, 1)
        end

        local pngBinary = PNG.new({ X = COLOR_PNG_SIZE, Y = COLOR_PNG_SIZE }, pngBinaryData)

        local responseMessage = DiscordLuau.MessageBuilder.new()
        local responseAttachment = DiscordLuau.AttachmentBuilder.new()
        local responseEmbed = DiscordLuau.EmbedBuilder.new()
            :setColor(hexColorCode)
            :setTitle("Color Code")
            :setDescription(`The following is information about a specific color.`)
            :addField({
                name = "Color name",
                value = `#{hexColor} is called '{GetColorName(hexColor) or "Unknown"}'`
            })
            :addField({
                name = "Color decimal",
                value = `#{hexColor} is \`{hexColorCode}\` in decimal!`
            })
            :addField({
                name = "Color binary",
                value = `#{hexColor} is \`{binary}\` in binary!`
            })
            :setFooter({
                text = `Execution took '{timeMs}ms''`,
                icon = ""
            })
            :setImage({
                imageUrl = "attachment://color.png",
                height = COLOR_PNG_SIZE,
                width = COLOR_PNG_SIZE,
            })

        responseAttachment:setData(pngBinary:ToString())
        responseAttachment:setName("color.png")
        responseAttachment:setDescription("The color chosen.")

        responseMessage:addEmbed(responseEmbed)
        responseMessage:addFile(responseAttachment)
    
        interaction:sendMessageAsync(responseMessage)
    else
        local clockTime = os.clock() - osStart
        local timeMs = math.round(clockTime * 100)
    
        local responseMessage = DiscordLuau.MessageBuilder.new()
        local responseEmbed = DiscordLuau.EmbedBuilder.new()
            :setColor(0xFF0000)
            :setTitle("Color Code")
            :setDescription(`The passed in color code was invalid.`)
            :setFooter({
                text = `Execution took '{timeMs}ms''`,
                icon = ""
            })

        responseMessage:addEmbed(responseEmbed)
    
        interaction:sendMessageAsync(responseMessage)
    end
end)