-- src/card.lua
local Card = {}
Card.__index = Card

function Card.new(def)
    local self = setmetatable({}, Card)
    self.def    = def
    self.cost   = def.cost
    self.power  = def.power
    self.text   = def.text
    self.triggers = def.triggers or {}
    self.faceUp = false
    return self
end

function Card:applyTrigger(event, ctx)
    if event == "onReveal" then
        self.faceUp = true
    end
    if self.triggers[event] then
        self.triggers[event](self, ctx)
    end
end

return Card
