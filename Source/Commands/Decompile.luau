local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local LuauDecompile = require("@Functions/LuauDecompile")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("decompile-luau")
    :setDescription("Decompile Luau bytecode into some sort of human-readable format")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("luau-code")
            :setDescription("The Luau bytecode code you'd like decompiled into a human readable format.")
            :setRequired(true)
            :setType(DiscordLuau.CommandOptionBuilder.Type.Attachment)
    )

return Command.new(commandBuilder, function(interaction)
    local attachmentId = (interaction.data :: any).options["1"].value
    local attachment = (interaction.data :: any).resolved.attachments[attachmentId]

    local osStart = os.clock()

    interaction:deferAsync()

    local request = Net.request({
        url = attachment.url,
        method = "GET"
    })

    if not request.ok then
        local responseMessage = DiscordLuau.MessageBuilder.new()
        local responseEmbed = DiscordLuau.EmbedBuilder.new()
            :setColor(0xFF0000)
            :setTitle("Lua Compilation")
            :setDescription(`Request to discords CDN has failed;`)
            :addField({
                name = "CDN error;",
                value = `\`\`\`json\n\{\n\t"statusMessage":{request.statusMessage},\n\t"statusCode": {request.statusCode}\n}\`\`\``
            })

        return interaction:sendMessageAsync(responseMessage)
    else
        local sourceCode = request.body
        local success, decompiledSourceCode = pcall(LuauDecompile, sourceCode)

        if success then
            local clockTime = os.clock() - osStart
            local timeMs = math.round(clockTime * 100)
        
            local responseMessage = DiscordLuau.MessageBuilder.new()
            local responseEmbed = DiscordLuau.EmbedBuilder.new()
                :setColor(0x5CD85A)
                :setTitle("Lua Decompilation")
                :setDescription(`The following luau code has been decompiled successfully.`)
                :addField({
                    name = "Luau sourcecode",
                    value = `> [Linked Source]({attachment.url})`
                })
                :addField({
                    name = "Luau decompiled",
                    value = #decompiledSourceCode > 1000 and "See attachments" or `\`\`\`json\n{decompiledSourceCode}\`\`\``
                })
                :setFooter({
                    text = `Execution took '{timeMs}ms'`,
                    icon = ""
                })
            
            local responseAttachment = DiscordLuau.AttachmentBuilder.new()
                :setDescription("The decompiled Luau")
                :setName("Bytecode.luauc.s")
                :setData(decompiledSourceCode)
            
            responseMessage:addFile(responseAttachment)

            responseMessage:addEmbed(responseEmbed)
        
            interaction:sendMessageAsync(responseMessage)
        else
            local clockTime = os.clock() - osStart
            local timeMs = math.round(clockTime * 100)
        
            local responseMessage = DiscordLuau.MessageBuilder.new()
            local responseEmbed = DiscordLuau.EmbedBuilder.new()
                :setColor(0xFF0000)
                :setTitle("Lua Decompilation")
                :setDescription(`The following luau code has failed to be decompiled.`)
                :addField({
                    name = "Luau sourcecode",
                    value = `> [Linked Source]({attachment.url})`
                })
                :addField({
                    name = "Error message",
                    value = `\`\`\`{decompiledSourceCode}\`\`\``
                })
                :setFooter({
                    text = `Execution took '{timeMs}ms'`,
                    icon = ""
                })

            responseMessage:addEmbed(responseEmbed)
        
            interaction:sendMessageAsync(responseMessage)
        end
    end
end)