-- src/ui.lua
local UI = {}
UI.__index = UI

local Game = require "src/game"
local lg   = love.graphics

-- Maximum hand slots (for positioning Next button)
local MAX_HAND = 7

function UI:mousepressed(x, y, button)
    local w, h    = lg.getWidth(), lg.getHeight()
    local laneGap = w * 0.02
    local GAP     = laneGap
    local laneW   = (w - 4 * laneGap) / 3
    local CARD_W  = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
    local CARD_H  = h * 0.2

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

    if Game.state == "staging" then
        local p = Game.players[1]
        -- hand pickup
        local totalW = #p.hand * CARD_W + (#p.hand - 1) * GAP
        local hx, hy = (w - totalW) / 2, h * 0.15 + h * 0.55 + laneGap
        for i, card in ipairs(p.hand) do
            local cx = hx + (i - 1) * (CARD_W + GAP)
            if x >= cx and x <= cx + CARD_W and y >= hy and y <= hy + CARD_H then
                self.dragging = { type = "hand", card = card, originIndex = i }
                table.remove(p.hand, i)
                return
            end
        end

        -- board pickup
        local laneY, laneH = h * 0.15, h * 0.55
        for loc, slots in ipairs(Game.board.slots[1]) do
            local laneX      = laneGap + (loc - 1) * (laneW + laneGap)
            local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
            local startX     = laneX + (laneW - totalLaneW) / 2
            local rowY       = laneY + laneH - CARD_H
            for slotIndex, c in ipairs(slots) do
                local sx = startX + (slotIndex - 1) * (CARD_W + GAP)
                if x >= sx and x <= sx + CARD_W and y >= rowY and y <= rowY + CARD_H then
                    self.dragging = { type = "board", card = c, origin = { loc = loc, slotIndex = slotIndex } }
                    table.remove(slots, slotIndex)
                    return
                end
            end
        end
    end

    -- Next button click
    do
        local totalW = MAX_HAND * CARD_W + (MAX_HAND - 1) * GAP
        local hx, hy = (w - totalW) / 2, h * 0.15 + h * 0.55 + laneGap
        local bw, bh = CARD_W * 0.8, CARD_H * 0.5
        local nbx     = hx + totalW + GAP
        local nby     = hy + (CARD_H - bh) / 2
        if x >= nbx and x <= nbx + bw and y >= nby and y <= nby + bh then
            Game:nextPhase()
        end
    end
end

function UI:mousereleased(x, y, button)
    if not self.dragging then return end
    local p    = Game.players[1]
    local d    = self.dragging
    local c    = d.card
    local w, h = lg.getWidth(), lg.getHeight()

    -- recalc geometry
    local laneGap = w * 0.02
    local GAP     = laneGap
    local laneW   = (w - 4 * laneGap) / 3
    local CARD_W  = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
    local CARD_H  = h * 0.2
    local laneY   = h * 0.15
    local laneH   = h * 0.55

    -- if not staging, revert to original
    if Game.state ~= "staging" then
        if d.type == "hand" then
            table.insert(p.hand, d.originIndex, c)
        elseif d.type == "board" then
            table.insert(Game.board.slots[1][d.origin.loc], c)
        end
        self.dragging = nil
        return
    end

    -- staging: drop back to hand area
    do
        local totalW = #p.hand * CARD_W + (#p.hand - 1) * GAP
        local hx, hy = (w - totalW) / 2, laneY + laneH + laneGap
        if x >= hx and x <= hx + totalW and y >= hy and y <= hy + CARD_H then
            if d.type == "board" then p.mana = p.mana + c.cost end
            table.insert(p.hand, c)
            self.dragging = nil
            return
        end
    end

    -- staging: drop to lanes (play or reposition)
    for loc = 1, 3 do
        local laneX      = laneGap + (loc - 1) * (laneW + laneGap)
        local totalLaneW = Game.board.maxSlots * CARD_W + (Game.board.maxSlots - 1) * GAP
        local startX     = laneX + (laneW - totalLaneW) / 2
        local slotY      = laneY + laneH - CARD_H
        for slot = 1, Game.board.maxSlots do
            local sx = startX + (slot - 1) * (CARD_W + GAP)
            if x >= sx and x <= sx + CARD_W and y >= slotY and y <= slotY + CARD_H then
                if d.type == "hand" then
                    if p:playCard(c, loc, Game.board) then
                        c.faceUp = true
                        self.dragging = nil
                        return
                    end
                elseif d.type == "board" then
                    table.insert(Game.board.slots[1][loc], c)
                    c.faceUp = true
                    self.dragging = nil
                    return
                end
            end
        end
    end

    -- invalid drop: revert without refund
    if d.type == "hand" then
        table.insert(p.hand, d.originIndex, c)
    elseif d.type == "board" then
        table.insert(Game.board.slots[1][d.origin.loc], c)
    end
    self.dragging = nil
end

function UI:draw()
    local w, h    = lg.getWidth(), lg.getHeight()
    local laneGap = w * 0.02
    local GAP     = laneGap
    local laneW   = (w - 4 * laneGap) / 3
    local CARD_W  = (laneW - (Game.board.maxSlots - 1) * GAP) / Game.board.maxSlots
    local CARD_H  = h * 0.2
    local laneY   = h * 0.15
    local laneH   = h * 0.55

    -- Title Screen
    if Game.state == "menu" then
        lg.setColor(0,0,0); lg.rectangle('fill',0,0,w,h)
        lg.setColor(1,1,1); lg.printf("Mythic Clash",0,h*0.3,w,'center')
        local bw, bh = w*0.3,h*0.1
        local bx, by = (w-bw)/2,h*0.5
        lg.setColor(0.8,0.8,0.8); lg.rectangle('fill',bx,by,bw,bh,10,10)
        lg.setColor(0,0,0); lg.printf("Play",bx,by+(bh-24)/2,bw,'center')
        return
    end

    -- Phase text
    lg.setColor(1,1,1)
    local phase = "Round "..Game.turn..": "..Game:getPhaseText()
    lg.print(phase, w - lg.getFont():getWidth(phase) - 20, 20)

    -- Debug: Enemy hand
    local enemy = Game.players[2]
    if #enemy.hand > 0 then
        local smallW, smallH = CARD_W*0.4, CARD_H*0.4
        local totalEW = #enemy.hand * smallW + (#enemy.hand - 1) * (GAP*0.5)
        local ex = (w - totalEW) / 2
        for i, c in ipairs(enemy.hand) do
            local sx = ex + (i - 1) * (smallW + GAP*0.5)
            lg.setColor(0.2,0.2,0.2); lg.rectangle('fill', sx, GAP, smallW, smallH)
            lg.setColor(1,1,1); lg.printf(c.def.name, sx, GAP+4, smallW, 'center')
            lg.print("C:"..c.cost, sx+2, GAP+smallH-16)
        end
    end

    -- Board lanes
    local laneColors = {{0.6,0.2,0.2,0.35},{0.2,0.6,0.2,0.35},{0.2,0.2,0.6,0.35}}
    for loc = 1,3 do
        local x = laneGap + (loc-1)*(laneW+laneGap)
        lg.setColor(unpack(laneColors[loc]))
        lg.rectangle('fill', x, laneY, laneW, laneH)
    end

    -- Board cards
    lg.setColor(1,1,1)
    for pid=1,2 do
        local rowY = (pid==1) and (laneY+laneH-CARD_H) or laneY
        for loc=1,3 do
            local startX = laneGap + (loc-1)*(laneW+laneGap)
            local totalLaneW = Game.board.maxSlots*CARD_W + (Game.board.maxSlots-1)*GAP
            local laneStart= startX + (laneW-totalLaneW)/2
            for slot=1,Game.board.maxSlots do
                local sx = laneStart + (slot-1)*(CARD_W+GAP)
                lg.setColor(1,1,1); lg.rectangle('line',sx,rowY,CARD_W,CARD_H)
                local card = Game.board.slots[pid][loc][slot]
                if card then
                    if card.faceUp then
                        lg.setColor(0.1,0.1,0.1); lg.rectangle('fill', sx+2, rowY+2, CARD_W-4, CARD_H-4)
                        lg.setColor(1,1,1)
                        lg.printf(card.def.name, sx, rowY+8, CARD_W, 'center')
                        local img = card.def.image
                        local iw, ih = img:getDimensions()
                        local scale = math.min((CARD_W*0.6)/iw, (CARD_H*0.45)/ih)
                        lg.draw(img, sx+(CARD_W-iw*scale)/2, rowY+40, 0, scale, scale)
                        lg.print("C:"..card.cost, sx+10, rowY+CARD_H-90)
                        lg.print("P:"..card.power, sx+CARD_W-40, rowY+CARD_H-90)
                        lg.printf(card.def.text, sx+10, rowY+CARD_H-70, CARD_W-20, 'center')
                    else
                        lg.setColor(0.2,0.2,0.2); lg.rectangle('fill', sx, rowY, CARD_W, CARD_H)
                    end
                end
            end
        end
    end

    -- Player hand
    local p1 = Game.players[1]
    local totalW = #p1.hand*CARD_W + (#p1.hand-1)*GAP
    local hx = (w-totalW)/2
    local hy = laneY+laneH+laneGap
    for i, c in ipairs(p1.hand) do
        local sx = hx + (i-1)*(CARD_W+GAP)
        lg.setColor(1,1,1); lg.rectangle('line',sx,hy,CARD_W,CARD_H)
        lg.printf(c.def.name, sx, hy+8, CARD_W, 'center')
        local img=c.def.image
        local iw,ih=img:getDimensions()
        local scale=math.min((CARD_W*0.6)/iw,(CARD_H*0.45)/ih)
        lg.draw(img,sx+(CARD_W-iw*scale)/2,hy+40,0,scale,scale)
        lg.print("C:"..c.cost,sx+10,hy+CARD_H-90)
        lg.print("P:"..c.power,sx+CARD_W-40,hy+CARD_H-90)
        lg.printf(c.def.text,sx+10,hy+CARD_H-70,CARD_W-20,'center')
    end

    -- Deck and discard
    local pileW,pileH = CARD_W*0.8, CARD_H*0.8
    lg.setColor(0.3,0.3,0.3)
    lg.rectangle('line', laneGap, hy, pileW, pileH)
    lg.printf(#p1.deck.cards, laneGap, hy+pileH+5, pileW, 'center')
    lg.printf('Deck', laneGap, hy-20, pileW, 'center')
    local dx = w-laneGap-pileW
    lg.rectangle('line', dx, hy, pileW, pileH)
    lg.printf(#p1.deck.discardPile, dx, hy+pileH+5, pileW, 'center')
    lg.printf('Discard', dx, hy-20, pileW, 'center')

    -- Next button
    local bw,bh = CARD_W*0.8, CARD_H*0.5
    local sbx = (w - (MAX_HAND*CARD_W + (MAX_HAND-1)*GAP))/2 + (MAX_HAND*CARD_W + GAP*MAX_HAND)
    local sby = hy + (CARD_H - bh)/2
    lg.setColor(0.85,0.85,0.85); lg.rectangle('fill', sbx, sby, bw, bh, 6,6)
    lg.setColor(0,0,0); lg.printf("Next", sbx, sby+(bh-18)/2, bw, 'center')

    -- Mana & Scores
    lg.setColor(1,1,1)
    lg.print("Mana: "..p1.mana, 20, 20)
    lg.print("Score: "..p1.score, 20, 60)
    lg.print("Enemy Score: "..Game.players[2].score, 20, 100)

    -- Drag preview
    if self.dragging then
        local mx,my = love.mouse.getPosition()
        local img = self.dragging.card.def.image
        local iw,ih = img:getDimensions()
        local scale = math.min((CARD_W*1.2)/iw, (CARD_H*1.2)/ih)
        lg.draw(img, mx-(iw*scale)/2, my-(ih*scale)/2, 0, scale, scale)
    end

    -- Game Over
    if Game.state == "gameover" then
        lg.setColor(0,0,0,0.7); lg.rectangle('fill',0,0,w,h)
        lg.setColor(1,0,0); lg.printf("Game Over", 0, h/2-30, w, 'center')
    end
end

return UI
