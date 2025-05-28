-- src/game.lua
local Game = {}
Game.__index = Game

local constants = require "src/constants"
local Player    = require "src/player"
local Board     = require "src/board"
local AI        = require "src/ai"

function Game:init()
    self.players     = { Player.new(1, false), Player.new(2, true) }
    self.board       = Board.new()
    self.turn        = 1
    self.state       = "staging"
    self.targetScore = constants.TARGET_SCORE

    -- preload all card images
    for _, def in ipairs(constants.CARD_DEFS) do
        def.image = love.graphics.newImage("src/assets/images/" .. def.id .. ".png")
    end

    -- deal starting hands, set initial mana
    for _, p in ipairs(self.players) do
        p:drawStartingHand()
        p.mana = self.turn
    end
end

function Game:getPhaseText()
    local texts = {
        staging  = "Your Turn",
        enemy    = "Enemy Turn",
        reveal   = "Reveal Cards",
        scoring  = "Scoring",
        gameover = "Game Over"
    }
    return texts[self.state] or ""
end

function Game:nextPhase()
    if self.state == "staging" then
        -- AI stages its play
        self.state = "enemy"
        AI.stageRandom(self.players[2], self.board)

    elseif self.state == "enemy" then
        -- Reveal all cards
        self.state = "reveal"
        for pid = 1, 2 do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[pid][loc]) do
                    c:applyTrigger("onReveal", self)
                end
            end
        end

    elseif self.state == "reveal" then
        -- Scoring
        self.state = "scoring"
        for loc = 1, 3 do
            local p1 = self.board:totalPower(1, loc)
            local p2 = self.board:totalPower(2, loc)
            local diff = math.abs(p1 - p2)
            if     p1 > p2 then self.players[1].score = self.players[1].score + diff
            elseif p2 > p1 then self.players[2].score = self.players[2].score + diff
            else  -- tie, coin flip
                if math.random() < 0.5 then
                    self.players[1].score = self.players[1].score + diff
                else
                    self.players[2].score = self.players[2].score + diff
                end
            end
        end

    elseif self.state == "scoring" then
        -- Cleanup: discard all cards, prepare next turn
        for _, p in ipairs(self.players) do
            for loc = 1, 3 do
                for _, c in ipairs(self.board.slots[p.id][loc]) do
                    p.deck:discard(c)
                end
                self.board.slots[p.id][loc] = {}
            end
            p:drawTurnCard()
        end

        self.turn = self.turn + 1
        for _, p in ipairs(self.players) do
            p.mana = self.turn
        end

        -- Check win
        for _, p in ipairs(self.players) do
            if p.score >= self.targetScore then
                self.state = "gameover"
                return
            end
        end

        self.state = "staging"
    end
end

function Game:update(dt)
    -- no per-frame logic for now
end

function Game:draw()
    require("src/ui"):draw()
end

return Game
