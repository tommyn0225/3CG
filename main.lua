-- main.lua
local constants = require "src/constants"
local utils     = require "src/utils"
local Card      = require "src/card"
local Deck      = require "src/deck"
local Player    = require "src/player"
local Board     = require "src/board"
local UI        = require "src/ui"
local Game      = require "src/game"

function love.load()
    -- bump up the window size for more breathing room
    love.window.setMode(0, 0, {resizable = true, fullscreen = false})
    math.randomseed(os.time())
    Game:init()
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end

function love.mousepressed(x, y, button)
    UI:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end
