local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("compile-luau")
    :setDescription("Compile Luau into bytecode")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("luau-code")
            :setDescription("The Luau code you'd like to compiled into bytecode.")
            :setRequired(true)
            :setType(DiscordLuau.CommandOptionBuilder.Type.Attachment)
    )
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("optimization-level")
            :setDescription("The Luau optimization-level of the compiled bytecode")
            :setRequired(false)
            :setType(DiscordLuau.CommandOptionBuilder.Type.Integer)
            :addChoice("No Optimization", 0)
            :addChoice("Partial Optimizations", 1)
            :addChoice("Full Optimization", 2)
    )
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("debug-level")
            :setDescription("The Luau debug-level of the compiled bytecode")
            :setRequired(false)
            :setType(DiscordLuau.CommandOptionBuilder.Type.Integer)
            :addChoice("No Debugging", 0)
            :addChoice("Line Info & Function Names Debugging", 1)
            :addChoice("Full Debugging", 2)
    )
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("coverage-level")
            :setDescription("The Luau coverage-level of the compiled bytecode")
            :setRequired(false)
            :setType(DiscordLuau.CommandOptionBuilder.Type.Integer)
            :addChoice("No Coverage", 0)
            :addChoice("Statement Coverage", 1)
            :addChoice("Statement & Expression Coverage", 2)
    )

return Command.new(commandBuilder, function(interaction)
    local attachmentId = (interaction.data :: any).options["1"].value
    local attachment = (interaction.data :: any).resolved.attachments[attachmentId]

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

        local optimisationLevel = (interaction.data :: any).options["2"] and (interaction.data :: any).options["2"].value or 1
        local debugLevel = (interaction.data :: any).options["3"] and (interaction.data :: any).options["3"].value or 1
        local coverageLevel = (interaction.data :: any).options["4"] and (interaction.data :: any).options["4"].value or 0
    
        local osStart = os.clock()
    
        local success, bytecode = pcall(Luau.compile, sourceCode, {
            optimisationLevel = optimisationLevel,
            debugLevel = debugLevel,
            coverageLevel = coverageLevel
        })

        if success then
            local clockTime = os.clock() - osStart
            local timeMs = math.round(clockTime * 100)
        
            local responseMessage = DiscordLuau.MessageBuilder.new()
            local responseEmbed = DiscordLuau.EmbedBuilder.new()
                :setColor(0x5CD85A)
                :setTitle("Lua Compilation")
                :setDescription(`The following luau code has been compiled successfully.`)
                :addField({
                    name = "Luau sourcecode",
                    value = `> [Linked Source]({attachment.url})`
                })
                :addField({
                    name = "Luau settings",
                    value = `\`\`\`json\n\{\n\t"optimisationLevel": {optimisationLevel},\n\t"debugLevel": {debugLevel},\n\t"coverageLevel": {coverageLevel}\n}\`\`\``
                })
                :setFooter({
                    text = `Execution took '{timeMs}ms''`,
                    icon = ""
                })
            local responseAttachment = DiscordLuau.AttachmentBuilder.new()
                :setDescription("The compiled Luau bytecode")
                :setName("Bytecode.luauc")
                :setData(bytecode)
        
            responseMessage:addFile(responseAttachment)
            responseMessage:addEmbed(responseEmbed)
        
            interaction:sendMessageAsync(responseMessage)
        else
            local clockTime = os.clock() - osStart
            local timeMs = math.round(clockTime * 100)
        
            local responseMessage = DiscordLuau.MessageBuilder.new()
            local responseEmbed = DiscordLuau.EmbedBuilder.new()
                :setColor(0xFF0000)
                :setTitle("Lua Compilation")
                :setDescription(`The following luau code has failed to be compiled into bytecode.`)
                :addField({
                    name = "Luau sourcecode",
                    value = `> [Linked Source]({attachment.url})`
                })
                :addField({
                    name = "Error message",
                    value = `\`\`\`{bytecode}\`\`\``
                })
                :addField({
                    name = "Luau settings",
                    value = `\`\`\`json\n\{\n\t"optimisationLevel": {optimisationLevel},\n\t"debugLevel": {debugLevel},\n\t"coverageLevel": {coverageLevel}\n}\`\`\``
                })
                :setFooter({
                    text = `Execution took '{timeMs}ms''`,
                    icon = ""
                })

            responseMessage:addEmbed(responseEmbed)
        
            interaction:sendMessageAsync(responseMessage)
        end
    end
end)