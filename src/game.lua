-- src/game.lua
local Game = {}
Game.__index = Game

local constants = require "src/constants"
local Player    = require "src/player"
local Board     = require "src/board"

function Game:init()
    -- create players: player 1 = human, 2 = AI
    self.players = {
        Player.new(1, false),
        Player.new(2, true)
    }
    self.board = Board.new()
    self.turn  = 1
    self.state = "staging"
    self.targetScore = constants.TARGET_SCORE

    -- load card images
    for _, def in ipairs(constants.CARD_DEFS) do
        def.image = love.graphics.newImage("assets/images/"..def.id..".png")
    end

    -- deal starting hands & initial mana
    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = 1
    end
end

function Game:submitPlays()
    if self.state ~= "staging" then return end

    -- AI stages randomly
    self.players[2]:stageRandom(self.board)

    -- reveal all cards
    for pid=1,2 do
        for loc=1,3 do
            for _, c in ipairs(self.board.slots[pid][loc]) do
                c:applyTrigger("onReveal", self)
            end
        end
    end

    -- scoring
    for loc=1,3 do
        local p1 = self.board:totalPower(1, loc)
        local p2 = self.board:totalPower(2, loc)
        local diff = math.abs(p1 - p2)
        if p1 > p2 then
            self.players[1].score = self.players[1].score + diff
        elseif p2 > p1 then
            self.players[2].score = self.players[2].score + diff
        else
            -- coin flip on tie
            if math.random() < 0.5 then
                self.players[1].score = self.players[1].score + diff
            else
                self.players[2].score = self.players[2].score + diff
            end
        end
    end

    -- cleanup, draw new card, increment turn & mana
    for _, p in ipairs(self.players) do
        for loc=1,3 do
            for _, c in ipairs(self.board.slots[p.id][loc]) do
                p.deck:discard(c)
            end
            self.board.slots[p.id][loc] = {}
        end
        p:drawTurnCard()
        p.mana = self.turn + 1
    end

    self.turn = self.turn + 1

    -- check win
    for _, p in ipairs(self.players) do
        if p.score >= self.targetScore then
            self.state = "gameover"
        end
    end
end

function Game:update(dt)
    -- barebones: no animations or timers
end

function Game:draw()
    require("src/ui"):draw()
end

return Game
