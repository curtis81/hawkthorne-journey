local core   = require 'hawk/core'
local middle = require 'hawk/middleclass'

local Level = require 'level'
local window = require 'window'
local fonts = require 'fonts'
local background = require 'selectbackground'
local sound = require 'vendor/TEsound'
local Character = require 'character'
local characters = Character.characters
local controls = require 'controls'

local character_selections = {}
character_selections[1] = {} -- main characters
character_selections[1][0] = {} -- left
character_selections[1][1] = {} -- right
character_selections[1][1][0] = characters['troy']
character_selections[1][1][1] = characters['shirley']
character_selections[1][1][2] = characters['pierce']
character_selections[1][0][0] = characters['jeff']
character_selections[1][0][1] = characters['britta']
character_selections[1][0][2] = characters['abed']
character_selections[1][0][3] = characters['annie']

character_selections[2] = {} -- page 2
character_selections[2][0] = {} -- left
character_selections[2][1] = {} -- right
character_selections[2][1][0] = characters['chang']
character_selections[2][1][1] = characters['fatneil']
character_selections[2][1][2] = characters['vicedean']
character_selections[2][0][0] = characters['dean']
character_selections[2][0][1] = characters['guzman']
character_selections[2][0][2] = characters['buddy']
character_selections[2][0][3] = characters['leonard']

character_selections[3] = {} -- page 3
character_selections[3][0] = {} -- left
character_selections[3][1] = {} -- right
character_selections[3][1][0] = characters['ian']
character_selections[3][1][1] = characters['rich']
character_selections[3][1][2] = characters['vicki']
character_selections[3][0][0] = characters['vaughn']
character_selections[3][0][1] = characters['kevin']
character_selections[3][0][2] = characters['garrett']


local current_page = 1
local selections = character_selections[current_page]

local Selection = middle.class('Selection', core.Scene)

function Selection:initialize(app)
  self.app = app
    self.side = 0 -- 0 for left, 1 for right
    self.level = 0 -- 0 through 3 for characters

    background.init()
    self.chartext = ""
    self.costtext = ""
    self.randomtext = ""
end

function Selection:show()
    fonts.set( 'big' )
    self.music = sound.playMusic( "opening" )
    background.enter()
    background.setSelected( self.side, self.level )

    self.chartext = "PRESS " .. controls.getKey('JUMP') .. " TO CHOOSE CHARACTER" 
    self.costtext = "PRESS " .. controls.getKey('ATTACK') .. " or " ..controls.getKey('INTERACT') .. " TO CHANGE COSTUME"
    self.randomtext = "PRESS " .. controls.getKey('SELECT') .. " TO GET A RANDOM COSTUME"
end

function Selection:character()
    return selections[self.side][self.level]
end

function Selection:buttonpressed(button)
    if button == "START" then
      self.app:redirect("/title")
      return true
    end

    -- If any input is received while sliding, speed up
    if background.slideIn or background.slideOut then
        background.speed = 10
        return
    end

    local level = self.level
    local options = 4

    if button == 'LEFT' or button == 'RIGHT' then
        self.side = (self.side - 1) % 2
        sound.playSfx('click')
    elseif button == 'UP' then
        level = (self.level - 1) % options
        sound.playSfx('click')
    elseif button == 'DOWN' then
        level = (self.level + 1) % options
        sound.playSfx('click')
    elseif button == 'ATTACK' then
        if self.level == 3 and self.side == 1 then
            return
        else
            local c = self:character()
            if c then
                c.count = (c.count + 1)
                if c.count == (#c.costumes + 1) then
                    c.count = 1
                end
                c.costume = c.costumes[c.count].sheet
                sound.playSfx('click')
            end
        end
        return
    elseif button == 'INTERACT' then
        if self.level == 3 and self.side == 1 then
            return
        else
            local c = self:character()
            if c then
                c.count = (c.count - 1)
                if c.count == 0 then
                    c.count = #c.costumes
                end
                c.costume = c.costumes[c.count].sheet
                sound.playSfx('click')
            end
        end
        return
    elseif button == 'SELECT' then
        local c = self:character()
        if c then
            c.count = math.random(#c.costumes)
            c.costume = c.costumes[c.count].sheet
            sound.playSfx('click')
        end
    end

    self.level = level

    if ( button == 'JUMP' ) and self.level == 3 and self.side == 1 then
        current_page = current_page % #character_selections + 1
        selections = character_selections[current_page]
        sound.playSfx('confirm')
    elseif button == 'JUMP' then
        if self:character() then
            -- Tell the background to transition out before changing scenes
            background.slideOut = true
        end
        sound.playSfx('confirm')
    end
    
    background.setSelected( self.side, self.level )
end

function Selection:hide()
    fonts.reset()
end

function Selection:update(dt)
    -- The background returns 'true' when the slide-out transition is complete
    if background.update(dt) then
        -- set the selected character and costume
        Character:setCharacter( self:character().name )
        Character:setCostume( self:character().costumes[self:character().count].sheet )
        Character.changed = true
        
        love.graphics.setColor(255, 255, 255, 255)
        self.app:redirect('/flyin')
    end
end

function Selection:draw()
    background.draw()

    -- Only draw the details on the screen when the background is up
    if not background.slideIn then
        local name = ""

        if self:character() then
            name = self:character().costumes[self:character().count].name
        end

        love.graphics.printf(self.chartext, 0,
            window.height - 75, window.width, 'center')
        love.graphics.printf(self.costtext, 0,
            window.height - 55, window.width, 'center')
        love.graphics.printf(self.randomtext, 0,
            window.height - 35, window.width, 'center')

        love.graphics.printf(name, 0,
            23, window.width, 'center')

        local x, y = background.getPosition(1, 3)
        love.graphics.setColor(255, 255, 255, 200)
        love.graphics.print("INSUFFICIENT", x, y + 5, 0, 0.5, 0.5, 12, -6)
        love.graphics.print(  "FRIENDS"   , x, y + 5, 0, 0.5, 0.5, -12, -32)
        love.graphics.print( current_page .. ' / ' .. #character_selections, x + 60, y + 15, 0, 0.5, 0.5 )
        love.graphics.setColor(255, 255, 255, 255)
    end

    for i=0,1,1 do
        for j=0,3,1 do
            local character = selections[i][j]
            local x, y = background.getPosition(i, j)
            if character then
                if i == 0 then
                    love.graphics.drawq( Character:getSheet(character.name, character.costumes[character.count].sheet ), character.mask , x, y, 0, -1, 1 )
                else
                    love.graphics.drawq( Character:getSheet(character.name, character.costumes[character.count].sheet ), character.mask , x, y )
                end
            end
        end
    end
end

return Selection