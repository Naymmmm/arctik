local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("eval-luau")
    :setDescription("Evaluate the state of luau code in a separate Lune instance.")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("luau-code")
            :setDescription("The Luau code you'd like to evaluate.")
            :setRequired(true)
            :setType(DiscordLuau.CommandOptionBuilder.Type.String)
    )

local function runSourceCode(sourceCode: string)
    local sourceFile = `Eval_{os.clock()}.luau`

    FileSystem.writeFile(`/tmp/{sourceFile}`, sourceCode)

    local processResponse = Process.spawn("lune", {
        "run", `/tmp/{sourceFile}`
    })

    FileSystem.removeFile(`/tmp/{sourceFile}`)

    return {
        stderr = processResponse.stderr,
        stdout = processResponse.stdout,
        code = processResponse.code,
        success = processResponse.ok,
    }
end

return Command.new(commandBuilder, function(interaction)
    local sourceCode = (interaction.data :: any).options["1"].value
    local totalTimeYielding = 0
    local sourceResponse

    local osStart = os.clock()

    local slaveThread = Task.spawn(function()
        sourceResponse = runSourceCode(sourceCode)
    end)

    interaction:deferAsync()

    while not sourceResponse do
        totalTimeYielding += Task.wait()

        if totalTimeYielding > 5 then
            Task.cancel(slaveThread)

            break
        end
    end

    local didFinish = sourceResponse ~= nil
    local clockTime = os.clock() - osStart
    local timeMs = math.round(clockTime * 100)

    local responseMessage = DiscordLuau.MessageBuilder.new()
    local responseEmbed = DiscordLuau.EmbedBuilder.new()
        :setColor(if not didFinish then 0xFF0000 elseif not sourceResponse.success then 0xFFA500 else 0x5CD85A)
        :setTitle("Lua Evaluation")
        :setDescription(not didFinish and "The following luau code didn't finish under the 5 second execution limit, the task has been killed." or `The following luau code has completed { sourceResponse.success and "without" or "with" } errors.`)
        :addField({
            name = "Luau sourcecode",
            value = `\`\`\`lua\n{sourceCode}\`\`\``
        })
        :setFooter({
            text = `Execution took '{timeMs}ms'; Status code '{sourceResponse and sourceResponse.code or "?"}'`,
            icon = ""
        })
    
    if didFinish then
        responseEmbed:addField({
            name = "Luau result",
            value = `\`\`\`bash\n{ not sourceResponse.success and sourceResponse.stderr or sourceResponse.stdout }\`\`\``
        })
    end

    responseMessage:addEmbed(responseEmbed)

    interaction:sendMessageAsync(responseMessage)
end)