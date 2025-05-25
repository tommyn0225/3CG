-- src/ui.lua
local UI = {}
UI.__index = UI

local Game = require "src/game"

function UI:mousepressed(x, y, button)
    if Game.state ~= "staging" then return end

    local p = Game.players[1]
    -- pick up from hand
    local hx, hy = 20, love.graphics.getHeight() - 120
    for i, card in ipairs(p.hand) do
        local cx = hx + (i-1)*110
        if x >= cx and x <= cx+100 and y >= hy and y <= hy+100 then
            self.dragging = { card = card, originIndex = i }
            table.remove(p.hand, i)
            return
        end
    end

    -- submit button
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local bw, bh = 100, 30
    local bx, by = w/2 - bw/2, h - 40
    if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
        Game:submitPlays()
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end

    local card = self.dragging.card
    local dropped = false
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local slotY = h - 300
    for loc = 1, 3 do
        local baseX = loc*(w/4) - (Game.board.maxSlots/2)*110 + 55
        for slot = 1, Game.board.maxSlots do
            local sx = baseX + (slot-1)*110
            if x >= sx and x <= sx+100 and y >= slotY and y <= slotY+100 then
                if Game.board:placeCard(1, loc, card) then
                    dropped = true
                end
            end
        end
    end

    if not dropped then
        -- return to hand
        table.insert(Game.players[1].hand, self.dragging.originIndex, card)
    end

    self.dragging = nil
end

function UI:draw()
    local lg = love.graphics
    local w, h = lg.getWidth(), lg.getHeight()

    -- draw board slots & cards
    for pid = 1, 2 do
        local y = (pid == 1) and (h - 300) or 100
        for loc = 1, 3 do
            local baseX = loc*(w/4) - (Game.board.maxSlots/2)*110 + 55
            for slot = 1, Game.board.maxSlots do
                local sx = baseX + (slot-1)*110
                lg.setColor(1,1,1)
                lg.rectangle('line', sx, y, 100, 100)
                local c = Game.board.slots[pid][loc][slot]
                if c then
                    if c.faceUp then
                        lg.draw(c.def.image, sx, y)
                        lg.print(c.power, sx+5, y+5)
                    else
                        lg.rectangle('fill', sx+10, y+10, 80, 80)
                    end
                end
            end
        end
    end

    -- draw player hand
    local hand = Game.players[1].hand
    local hx, hy = 20, h - 120
    for i, c in ipairs(hand) do
        local cx = hx + (i-1)*110
        lg.setColor(1,1,1)
        lg.rectangle('line', cx, hy, 100, 100)
        lg.draw(c.def.image, cx, hy)
        lg.print(c.cost, cx+5, hy+5)
        lg.print(c.power, cx+5, hy+25)
    end

    -- submit button
    local bw, bh = 100, 30
    local bx, by = w/2 - bw/2, h - 40
    lg.rectangle('line', bx, by, bw, bh)
    lg.print("Submit", bx+20, by+5)

    -- mana & score
    local p = Game.players[1]
    lg.print("Mana: "..p.mana, 20, h-160)
    lg.print("Score: "..p.score, 20, h-180)

    -- dragging preview
    if self.dragging then
        local mx, my = lg.getMousePosition()
        lg.draw(self.dragging.card.def.image, mx-50, my-50)
    end

    -- game over
    if Game.state == "gameover" then
        lg.printf("Game Over", 0, h/2, w, 'center')
    end
end

return UI
