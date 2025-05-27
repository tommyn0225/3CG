-- src/ui.lua
local UI = {}
UI.__index = UI

local Game = require "src/game"
local lg   = love.graphics

function UI:mousepressed(x, y, button)
    if Game.state ~= "staging" then return end
    local p = Game.players[1]
    local w, h = lg.getWidth(), lg.getHeight()

    -- Dynamic sizing
    local GAP      = w * 0.02
    local laneW    = w / 3
    local CARD_W   = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H   = h * 0.17

    -- Hand positioning
    local handCount = #p.hand
    local totalW    = handCount * CARD_W + (handCount - 1) * GAP
    local hx        = (w - totalW) / 2
    local hy        = h - CARD_H - GAP

    -- Pick up card from hand
    for i, card in ipairs(p.hand) do
        local cx = hx + (i - 1) * (CARD_W + GAP)
        if x >= cx and x <= cx + CARD_W and y >= hy and y <= hy + CARD_H then
            self.dragging = { card = card, originIndex = i }
            table.remove(p.hand, i)
            return
        end
    end

    -- Submit button area (right of hand)
    local bw = CARD_W * 0.8
    local bh = CARD_H * 0.5
    local sbx = hx + totalW + GAP
    local sby = hy + (CARD_H - bh) / 2
    if x >= sbx and x <= sbx + bw and y >= sby and y <= sby + bh then
        Game:submitPlays()
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end
    local card = self.dragging.card
    local dropped = false
    local w, h = lg.getWidth(), lg.getHeight()

    -- Dynamic sizing
    local GAP    = w * 0.02
    local laneW  = w / 3
    local CARD_W = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.17

    -- Lane drop zones (moved up)
    local laneY = h * 0.12
    local laneH = h * 0.68
    for loc = 1, 3 do
        local laneX      = (loc - 1) * laneW
        local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
        local startX     = laneX + (laneW - totalLaneW) / 2
        local slotY      = laneY + laneH - CARD_H
        for slot = 1, Game.board.maxSlots do
            local sx = startX + (slot - 1) * (CARD_W + GAP)
            if x >= sx and x <= sx + CARD_W and y >= slotY and y <= slotY + CARD_H then
                if Game.board:placeCard(1, loc, card) then dropped = true end
            end
        end
    end

    if not dropped then
        table.insert(Game.players[1].hand, self.dragging.originIndex, card)
    end
    self.dragging = nil
end

function UI:draw()
    local w, h = lg.getWidth(), lg.getHeight()

    -- Dynamic sizing
    local GAP    = w * 0.02
    local laneW  = w / 3
    local CARD_W = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.17

    -- Draw lanes (moved up and slightly shrunk)
    local laneY = h * 0.12
    local laneH = h * 0.68
    local laneColors = { {0.6,0.2,0.2,0.35}, {0.2,0.6,0.2,0.35}, {0.2,0.2,0.6,0.35} }
    for loc = 1, 3 do
        lg.setColor(unpack(laneColors[loc]))
        lg.rectangle('fill', (loc - 1) * laneW, laneY, laneW, laneH)
    end
    lg.setColor(1,1,1)

    -- Draw board slots & cards
    for pid = 1, 2 do
        local rowY = (pid == 1) and (laneY + laneH - CARD_H) or laneY
        for loc = 1, 3 do
            local laneX      = (loc - 1) * laneW
            local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
            local startX     = laneX + (laneW - totalLaneW) / 2
            for slot = 1, Game.board.maxSlots do
                local sx = startX + (slot - 1) * (CARD_W + GAP)
                lg.setColor(1,1,1)
                lg.rectangle('line', sx, rowY, CARD_W, CARD_H)
                local c = Game.board.slots[pid][loc][slot]
                if c then
                    if c.faceUp then
                        lg.setColor(0.1,0.1,0.1)
                        lg.rectangle('fill', sx+2, rowY+2, CARD_W-4, CARD_H-4)
                        lg.setColor(1,1,1)
                        lg.printf(c.def.name, sx, rowY+8, CARD_W, 'center')
                        local img = c.def.image
                        local ix  = sx + (CARD_W - img:getWidth()) / 2
                        lg.draw(img, ix, rowY+40)
                        lg.print("C:"..c.cost, sx+10, rowY+CARD_H-70)
                        lg.print("P:"..c.power, sx+CARD_W-40, rowY+CARD_H-70)
                        lg.printf(c.def.text, sx+10, rowY+CARD_H-50, CARD_W-20, 'center')
                    else
                        lg.setColor(0.3,0.3,0.3)
                        lg.rectangle('fill', sx + CARD_W * 0.08, rowY + CARD_H * 0.08,
                                     CARD_W * 0.84, CARD_H * 0.84)
                        lg.setColor(1,1,1)
                    end
                end
            end
        end
    end

    -- Draw hand (at bottom center)
    local p = Game.players[1]
    local handCount = #p.hand
    local totalW    = handCount * CARD_W + (handCount - 1) * GAP
    local hx        = (w - totalW) / 2
    local hy        = h - CARD_H - GAP
    for i, c in ipairs(p.hand) do
        local sx = hx + (i - 1) * (CARD_W + GAP)
        lg.setColor(1,1,1)
        lg.rectangle('line', sx, hy, CARD_W, CARD_H)
        lg.printf(c.def.name, sx, hy+8, CARD_W, 'center')
        local ix = sx + (CARD_W - c.def.image:getWidth()) / 2
        lg.draw(c.def.image, ix, hy+40)
        lg.print("C:"..c.cost, sx+10, hy+CARD_H-70)
        lg.print("P:"..c.power, sx+CARD_W-40, hy+CARD_H-70)
        lg.printf(c.def.text, sx+10, hy+CARD_H-50, CARD_W-20, 'center')
    end

    -- Draw deck & discard
    local pileW, pileH = CARD_W * 0.8, CARD_H * 0.8
    lg.setColor(0.3,0.3,0.3)
    lg.rectangle('line', GAP, hy, pileW, pileH)
    lg.printf(#Game.players[1].deck.cards, GAP, hy + pileH + 5, pileW, 'center')
    lg.printf('Deck', GAP, hy - 20, pileW, 'center')
    local dx = w - GAP - pileW
    lg.rectangle('line', dx, hy, pileW, pileH)
    lg.printf(#Game.players[1].deck.discardPile, dx, hy + pileH + 5, pileW, 'center')
    lg.printf('Discard', dx, hy - 20, pileW, 'center')

    -- Draw submit (to right of hand)
    local bw = CARD_W * 0.8
    local bh = CARD_H * 0.5
    local sbx = hx + totalW + GAP
    local sby = hy + (CARD_H - bh) / 2
    lg.setColor(0.85,0.85,0.85)
    lg.rectangle('fill', sbx, sby, bw, bh, 6, 6)
    lg.setColor(0,0,0)
    lg.printf("Submit", sbx, sby + (bh - 18) / 2, bw, 'center')

    -- Draw Mana & Score
    lg.setColor(1,1,1)
    lg.print("Mana: "..p.mana, 20, 20)
    lg.print("Score: "..p.score, 20, 60)

    -- Dragging preview
    if self.dragging then
        local mx, my = love.mouse.getPosition()
        local card = self.dragging.card
        lg.draw(card.def.image,
                mx - card.def.image:getWidth()/2,
                my - card.def.image:getHeight()/2)
    end

    -- Game over
    if Game.state == "gameover" then
        lg.setColor(0,0,0,0.7)
        lg.rectangle('fill', 0, 0, w, h)
        lg.setColor(1,0,0)
        lg.printf("Game Over", 0, h/2 - 30, w, 'center')
    end
end

return UI
