-- src/ui.lua
local UI = {}
UI.__index = UI

local Game = require "src/game"
local lg   = love.graphics

function UI:mousepressed(x, y, button)
    local w, h = lg.getWidth(), lg.getHeight()
    local GAP    = w * 0.02
    local laneW  = w / 3
    local CARD_W = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.17

    -- Title screen click
    if Game.state == "menu" then
        local bw, bh = w * 0.3, h * 0.1
        local bx, by = (w - bw) / 2, h * 0.5
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            Game:init()
            Game.state = "staging"
        end
        return
    end

    -- allow drag only during staging
    if Game.state == "staging" then
        local p = Game.players[1]
        local handCount = #p.hand
        local totalW    = handCount * CARD_W + (handCount - 1) * GAP
        local hx        = (w - totalW) / 2
        local hy        = (h * 0.15) + (h * 0.55) + GAP -- just below board
        for i, card in ipairs(p.hand) do
            local cx = hx + (i - 1) * (CARD_W + GAP)
            if x >= cx and x <= cx + CARD_W and y >= hy and y <= hy + CARD_H then
                self.dragging = { card = card, originIndex = i }
                table.remove(p.hand, i)
                return
            end
        end
    end

    -- Next button (always active)
    do
        local p1 = Game.players[1]
        local handCount = #p1.hand
        local totalW    = handCount * CARD_W + (handCount - 1) * GAP
        local hx        = (w - totalW) / 2
        local hy        = (h * 0.15) + (h * 0.55) + GAP
        local bw        = CARD_W * 0.8
        local bh        = CARD_H * 0.5
        local nbx       = hx + totalW + GAP
        local nby       = hy + (CARD_H - bh) / 2
        if x >= nbx and x <= nbx + bw and y >= nby and y <= nby + bh then
            Game:nextPhase()
        end
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end
    local p  = Game.players[1]
    local c  = self.dragging.card
    local w, h = lg.getWidth(), lg.getHeight()

    -- only allow drop during staging
    if Game.state ~= "staging" then
        table.insert(p.hand, self.dragging.originIndex, c)
        self.dragging = nil
        return
    end

    local GAP    = w * 0.02
    local laneW  = w / 3
    local CARD_W = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.17
    local laneY  = h * 0.15
    local laneH  = h * 0.55

    for loc = 1, 3 do
        local laneX      = (loc - 1) * laneW
        local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
        local startX     = laneX + (laneW - totalLaneW) / 2
        local slotY      = laneY + laneH - CARD_H
        for slot = 1, Game.board.maxSlots do
            local sx = startX + (slot - 1) * (CARD_W + GAP)
            if x >= sx and x <= sx + CARD_W and y >= slotY and y <= slotY + CARD_H then
                if p:playCard(c, loc, Game.board) then
                    self.dragging = nil
                    return
                end
            end
        end
    end

    table.insert(p.hand, self.dragging.originIndex, c)
    self.dragging = nil
end

function UI:draw()
    local w, h = lg.getWidth(), lg.getHeight()

    -- Title screen
    if Game.state == "menu" then
        lg.setColor(0,0,0)
        lg.rectangle('fill', 0, 0, w, h)
        lg.setColor(1,1,1)
        lg.printf("Mythic Clash", 0, h * 0.3, w, 'center')
        local bw, bh = w * 0.3, h * 0.1
        local bx, by = (w - bw) / 2, h * 0.5
        lg.setColor(0.8,0.8,0.8)
        lg.rectangle('fill', bx, by, bw, bh, 10, 10)
        lg.setColor(0,0,0)
        lg.printf("Play", bx, by + (bh - 24) / 2, bw, 'center')
        return
    end

    -- Phase text (top-right, with round)
    lg.setColor(1,1,1)
    local phase = "Round "..Game.turn..": "..Game:getPhaseText()
    local fw = lg.getFont():getWidth(phase)
    local px = w - fw - 20
    local py = 20
    lg.print(phase, px, py)

    -- Debug: show enemy hand (small + cost)
    local p2 = Game.players[2]
    local GAP    = w * 0.02
    local laneW  = w / 3
    local CARD_W = (laneW - 3 * GAP) / Game.board.maxSlots
    local CARD_H = h * 0.17
    local smallW = CARD_W * 0.4
    local smallH = CARD_H * 0.4
    local eh    = #p2.hand
    if eh > 0 then
        local totalEW = eh * smallW + (eh - 1) * (GAP * 0.5)
        local ex      = (w - totalEW) / 2
        local ey      = GAP
        for i, c in ipairs(p2.hand) do
            local sx = ex + (i - 1) * (smallW + GAP * 0.5)
            lg.setColor(0.2,0.2,0.2)
            lg.rectangle('fill', sx, ey, smallW, smallH)
            lg.setColor(1,1,1)
            lg.printf(c.def.name, sx, ey + 4, smallW, 'center')
            lg.print("C:"..c.cost, sx + 2, ey + smallH - 16)
        end
    end

    -- Draw board lanes and cards
    local laneY = h * 0.15
    local laneH = h * 0.55
    local laneColors = {{0.6,0.2,0.2,0.35},{0.2,0.6,0.2,0.35},{0.2,0.2,0.6,0.35}}
    for loc = 1, 3 do
        lg.setColor(unpack(laneColors[loc]))
        lg.rectangle('fill', (loc - 1) * laneW, laneY, laneW, laneH)
    end
    lg.setColor(1,1,1)
    for pid = 1,2 do
        local rowY = (pid == 1) and (laneY + laneH - CARD_H) or laneY
        for loc=1,3 do
            local laneX      = (loc-1)*laneW
            local totalLaneW = Game.board.maxSlots*CARD_W + (Game.board.maxSlots-1)*GAP
            local startX     = laneX + (laneW - totalLaneW)/2
            for slot=1,Game.board.maxSlots do
                local sx = startX + (slot-1)*(CARD_W+GAP)
                lg.setColor(1,1,1); lg.rectangle('line',sx,rowY,CARD_W,CARD_H)
                local c = Game.board.slots[pid][loc][slot]
                if c then
                    if c.faceUp then
                        lg.setColor(0.1,0.1,0.1)
                        lg.rectangle('fill', sx+2, rowY+2, CARD_W-4, CARD_H-4)
                        lg.setColor(1,1,1)
                        lg.printf(c.def.name, sx, rowY+8, CARD_W,'center')
                        lg.draw(c.def.image, sx+(CARD_W-c.def.image:getWidth())/2, rowY+40)
                        lg.print("C:"..c.cost, sx+10, rowY+CARD_H-70)
                        lg.print("P:"..c.power, sx+CARD_W-40, rowY+CARD_H-70)
                        lg.printf(c.def.text, sx+10, rowY+CARD_H-50, CARD_W-20,'center')
                    else
                        lg.setColor(0.3,0.3,0.3)
                        lg.rectangle('fill',sx+CARD_W*0.08,rowY+CARD_H*0.08,CARD_W*0.84,CARD_H*0.84)
                        lg.setColor(1,1,1)
                    end
                end
            end
        end
    end

    -- Draw player hand and piles
    local p1 = Game.players[1]
    local handCount = #p1.hand
    local totalW    = handCount*CARD_W + (handCount-1)*GAP
    local hx = (w-totalW)/2
    local hy = laneY + laneH + GAP
    for i,c in ipairs(p1.hand) do
        local sx = hx + (i-1)*(CARD_W+GAP)
        lg.setColor(1,1,1); lg.rectangle('line',sx,hy,CARD_W,CARD_H)
        lg.printf(c.def.name,sx,hy+8,CARD_W,'center')
        lg.draw(c.def.image,sx+(CARD_W-c.def.image:getWidth())/2,hy+40)
        lg.print("C:"..c.cost,sx+10,hy+CARD_H-70)
        lg.print("P:"..c.power,sx+CARD_W-40,hy+CARD_H-70)
        lg.printf(c.def.text,sx+10,hy+CARD_H-50,CARD_W-20,'center')
    end
    -- deck & discard
    local pileW,pileH = CARD_W*0.8, CARD_H*0.8
    lg.setColor(0.3,0.3,0.3)
    lg.rectangle('line', GAP, hy, pileW, pileH)
    lg.printf(#p1.deck.cards, GAP, hy+pileH+5, pileW,'center')
    lg.printf('Deck', GAP, hy-20, pileW,'center')
    local dx = w - GAP - pileW
    lg.rectangle('line', dx, hy, pileW, pileH)
    lg.printf(#p1.deck.discardPile, dx, hy+pileH+5, pileW,'center')
    lg.printf('Discard', dx, hy-20, pileW,'center')

    -- Next button
    local bw,bh = CARD_W*0.8,CARD_H*0.5
    local sbx,sby = hx+totalW+GAP, hy+(CARD_H-bh)/2
    lg.setColor(0.85,0.85,0.85)
    lg.rectangle('fill',sbx,sby,bw,bh,6,6)
    lg.setColor(0,0,0)
    lg.printf("Next", sbx, sby+(bh-18)/2, bw,'center')

    -- Mana & Scores
    lg.setColor(1,1,1)
    lg.print("Mana: "..p1.mana,20,20)
    lg.print("Score: "..p1.score,20,60)
    lg.print("Enemy Score: "..Game.players[2].score,20,100)

    -- Drag preview
    if self.dragging then
        local mx,my=love.mouse.getPosition()
        local c=self.dragging.card
        lg.draw(c.def.image,mx-c.def.image:getWidth()/2,my-c.def.image:getHeight()/2)
    end

    -- Game Over overlay
    if Game.state=="gameover" then
        lg.setColor(0,0,0,0.7)
        lg.rectangle('fill',0,0,w,h)
        lg.setColor(1,0,0)
        lg.printf("Game Over",0,h/2-30,w,'center')
    end
end

return UI
