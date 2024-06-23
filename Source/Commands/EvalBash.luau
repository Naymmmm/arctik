local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("eval-bash")
    :setDescription("Evaluate the state of bash code in a Bash instance.")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)
    :addOption(
        DiscordLuau.CommandOptionBuilder.new()
            :setName("bash-code")
            :setDescription("The bash code you'd like to evaluate.")
            :setRequired(true)
            :setType(DiscordLuau.CommandOptionBuilder.Type.String)
    )

local function runSourceCode(sourceCode: string)
    local processResponse = Process.spawn("bash", {
        "-c", `{sourceCode}`
    })

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
        :setTitle("Bash Evaluation")
        :setDescription(not didFinish and "The following bash code didn't finish under the 5 second execution limit, the task has been killed." or `The following bash code has completed { sourceResponse.success and "without" or "with" } errors.`)
        :addField({
            name = "Bash sourcecode",
            value = `\`\`\`bash\n{sourceCode}\`\`\``
        })
        :setFooter({
            text = `Execution took '{timeMs}ms'; Status code '{sourceResponse and sourceResponse.code or "?"}'`,
            icon = ""
        })
    
    if didFinish then
        local stdOut = sourceResponse.stdout

        if #stdOut > 1000 then
            stdOut = string.sub(stdOut, 1, 1000)

            stdOut ..= `<TRUNCATED>`
        end

        responseEmbed:addField({
            name = "Bash result",
            value = `\`\`\`bash\n{ not sourceResponse.success and sourceResponse.stderr or stdOut }\`\`\``
        })
    end

    responseMessage:addEmbed(responseEmbed)

    interaction:sendMessageAsync(responseMessage)
end)