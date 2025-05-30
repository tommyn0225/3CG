-- src/card.lua
local Card = {}
Card.__index = Card

local abilities = require "src/abilities"

function Card.new(def)
    local self = setmetatable({}, Card)
    self.def = def
    self.power = def.power
    self.cost = def.cost
    self.faceUp = false
    self.ownerId = nil
    self.powerChange = 0  -- Track power changes
    self.manaChange = 0   -- Track mana changes
    self.powerSetThisReveal = false -- Track if power was set by an ability this reveal
    return self
end

function Card:flip(faceUp)
    self.faceUp = faceUp
end

function Card:applyTrigger(trigger, game, context)
    if trigger == "onReveal" and self.def.ability then
        local abilityFn = abilities[self.def.ability]
        if abilityFn then
            local sourcePlayer = game.players[self.ownerId]
            local targetPlayer = game.players[self.ownerId == 1 and 2 or 1]
            abilityFn(game, sourcePlayer, targetPlayer, self, context or {})
        end
    end
end

function Card:addPower(amount)
    self.power = self.power + amount
    self.powerChange = self.powerChange + amount
end

function Card:addMana(amount)
    if self.ownerId then
        local player = game.players[self.ownerId]
        if player then
            player.mana = player.mana + amount
            self.manaChange = self.manaChange + amount
        end
    end
end

function Card:setPower(newPower)
    self.power = newPower
    self.powerSetThisReveal = true
end

return Card
