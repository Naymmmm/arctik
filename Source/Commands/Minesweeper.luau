local Process = require("@lune/process")
local FileSystem = require("@lune/fs")
local Task = require("@lune/task")
local Luau = require("@lune/luau")
local Net = require("@lune/net")

local DiscordLuau = require("../../DiscordLuau")

local Command = require("@Classes/Command")

local emojiMap = {
    [0] = ":zero:",
    [1] = ":one:",
	[2] = ":two:",
	[3] = ":three:",
	[4] = ":four:",
	[5] = ":five:",
	[6] = ":six:",
	[7] = ":seven:",
	[8] = ":eight:",
	[9] = ":nine:",
	[10] = ":ten:",
}

local commandBuilder = DiscordLuau.CommandBuilder.new()
    :setName("minesweeper")
    :setDescription("Create a minesweeper game")
    :setType(DiscordLuau.CommandBuilder.Type.ChatInput)
    :addContext(DiscordLuau.CommandBuilder.Context.BotDM)
    :addContext(DiscordLuau.CommandBuilder.Context.Guild)
    :addContext(DiscordLuau.CommandBuilder.Context.PrivateChannel)
    :addIntegration(DiscordLuau.CommandBuilder.IntegrationType.UserCommand)

return Command.new(commandBuilder, function(interaction)
    local minesweeperMatrix = {}
    local gridSize = 9
    local bombCount = gridSize

    local function evaluateNode(nodeX: number, nodeY: number)
        local evaluation = 0
        local transformations = {
            {-1, 0}, {1, 0},
            {0, -1}, {0, 1},

            {-1, -1}, {-1, 1},
            {1, -1}, {1, 1},
        }

        for _, transformation in transformations do
            if not minesweeperMatrix[nodeX + transformation[1]] then
                continue
            end

            if not minesweeperMatrix[nodeX + transformation[1]][nodeY + transformation[2]] then
                continue
            end

            evaluation += 1
        end

        return evaluation
    end

    for x = 1, gridSize do
        for y = 1, gridSize do
            if not minesweeperMatrix[x] then
                minesweeperMatrix[x] = {}
            end

            minesweeperMatrix[x][y] = false
        end
    end

    for index = 1, bombCount do
        minesweeperMatrix[math.random(gridSize)][math.random(gridSize)] = true
    end

    local message = ""

    for x = 1, gridSize do
        for y = 1, gridSize do
            if minesweeperMatrix[x][y] then
                message ..= `||:bomb:||`
            else
                local evaluation = evaluateNode(x, y)
                local emoji = `||{emojiMap[evaluation]}||`

                message ..= `{emoji}`
            end
        end

        message ..= "\n"
    end

    interaction:sendMessageAsync(DiscordLuau.MessageBuilder.new():setContent(message))
end)