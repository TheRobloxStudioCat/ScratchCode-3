local window_img = {
    ["Top"] = {
        ["Left"] = love.graphics.newImage("images/TopCorner.png"),
        ["Right"] = love.graphics.newImage("images/TopCorner2.png"),
        ["Center"] = love.graphics.newImage("images/TopMain.png")
    },

    ["Bottom"] = {
        ["Left"] = love.graphics.newImage("images/BottomCorner.png"),
        ["Right"] = love.graphics.newImage("images/BottomCorner2.png"),
        ["Center"] = love.graphics.newImage("images/BottomMain.png")
    },

    ["Sides"] = {
        ["Left"] = love.graphics.newImage("images/Center.png"),
        ["Right"] = love.graphics.newImage("images/Center2.png")
    },

    ["Hover"] = {
        ["Close"] = love.graphics.newImage("images/close_no.png"),
        ["Minimize"] = love.graphics.newImage("images/hide_no.png"),
        ["Window"] = love.graphics.newImage("images/window_no.png")
    },

    ["Default"] = {
        ["Close"] = love.graphics.newImage("images/close.png"),
        ["Minimize"] = love.graphics.newImage("images/hide.png"),
        ["Window"] = love.graphics.newImage("images/window.png")
    }
}

local window_sizes = {
    ["Top"] = {
        ["Left"] = {x = window_img["Top"]["Left"]:getWidth(), y = window_img["Top"]["Left"]:getHeight()},
        ["Right"] = {x = window_img["Top"]["Right"]:getWidth(), y = window_img["Top"]["Right"]:getHeight()},
        ["Center"] = {x = window_img["Top"]["Center"]:getWidth(), y = window_img["Top"]["Center"]:getHeight()}
    },

    ["Bottom"] = {
        ["Left"] = {x = window_img["Bottom"]["Left"]:getWidth(), y = window_img["Bottom"]["Left"]:getHeight()},
        ["Right"] = {x = window_img["Bottom"]["Right"]:getWidth(), y = window_img["Bottom"]["Right"]:getHeight()},
        ["Center"] = {x = window_img["Bottom"]["Center"]:getWidth(), y = window_img["Bottom"]["Center"]:getHeight()}
    },

    ["Sides"] = {
        ["Left"] = {x = window_img["Sides"]["Left"]:getWidth(), y = window_img["Sides"]["Left"]:getHeight()},
        ["Right"] = {x = window_img["Sides"]["Right"]:getWidth(), y = window_img["Sides"]["Right"]:getHeight()}
    }
}

local button_offsets = {
    ["Hover"] = {
        ["Close"] = {x = 36, y = 9},
        ["Window"] = {x = 67, y = 9},
        ["Minimize"] = {x = 100, y = 9}
    },

    ["Default"] = {
        ["Close"] = {x = 27, y = 13},
        ["Window"] = {x = 58, y = 13},
        ["Minimize"] = {x = 90, y = 13}
    }
}

local button_size = {
    x = 29,
    y = 17
}

local fonts = {
    ["tahoma"] = love.graphics.newFont("fonts/tahoma.ttf"),
    ["tahomanbd"] = love.graphics.newFont("fonts/tahomabd.ttf"),
    ["lucidaconsole"] = love.graphics.newFont("fonts/lucidaconsole.ttf"),
    ["tahoma14"] = love.graphics.newFont("fonts/tahoma.ttf",14),
    ["tahomanbd14"] = love.graphics.newFont("fonts/tahomabd.ttf",14),
    ["lucidaconsole14"] = love.graphics.newFont("fonts/lucidaconsole.ttf",14)
}

local WindowEngine = {}

local l_draw = love.graphics

local hover = require("libraries.collision")

function WindowEngine.drawWindow(x,y,xs,ys, title, icon, draw_func)
    love.graphics.rectangle("fill",x + window_sizes["Top"]["Left"].x,y,xs - (window_sizes["Top"]["Left"].x + window_sizes["Top"]["Right"].x),ys)

    --Top Drawing code.

    l_draw.draw(window_img["Top"]["Left"],x,y)
    l_draw.draw(window_img["Top"]["Right"],x + (xs - window_sizes["Top"]["Right"].x),y)
    l_draw.draw(window_img["Top"]["Center"],x + window_sizes["Top"]["Left"].x,y,0,(xs - (window_sizes["Top"]["Right"].x + window_sizes["Top"]["Left"].x)) / window_sizes["Top"]["Center"].x,1)

    --Bottom Drawing code.

    l_draw.draw(window_img["Bottom"]["Left"],x,y + (ys - window_sizes["Bottom"]["Center"].y))
    l_draw.draw(window_img["Bottom"]["Right"],x + (xs - window_sizes["Bottom"]["Right"].x),y + (ys - window_sizes["Bottom"]["Center"].y))
    l_draw.draw(window_img["Bottom"]["Center"],x + window_sizes["Bottom"]["Left"].x,y + (ys - window_sizes["Bottom"]["Center"].y),0,(xs - (window_sizes["Bottom"]["Right"].x + window_sizes["Bottom"]["Left"].x)) / window_sizes["Bottom"]["Center"].x,1)

    -- Center Drawing code.

    l_draw.draw(window_img["Sides"]["Left"],x,y + window_sizes["Top"]["Left"].y,0,1,(ys - (window_sizes["Top"]["Left"].y + window_sizes["Bottom"]["Left"].y)) / window_sizes["Sides"]["Left"].y)
    l_draw.draw(window_img["Sides"]["Right"],x + (xs - window_sizes["Sides"]["Right"].x),y + window_sizes["Top"]["Right"].y,0,1,(ys - (window_sizes["Top"]["Right"].y + window_sizes["Bottom"]["Right"].y)) / window_sizes["Sides"]["Right"].y)

    -- Window decoration Drawing code.

    l_draw.setFont(fonts["tahomanbd"])

    l_draw.setColor(0,0,0)

    l_draw.printf(title or "unknown", x,y + 10,xs,"center")

    l_draw.setColor(1,1,1)

    local m_x, m_y = love.mouse.getX(), love.mouse.getY()

    local hover1 = hover.IsTouching(m_x, m_y, x + (xs - button_offsets["Hover"]["Close"].x), y + button_offsets["Hover"]["Close"].y, button_size.x, button_size.y)
    local hover2 = hover.IsTouching(m_x, m_y, x + (xs - button_offsets["Hover"]["Window"].x), y + button_offsets["Hover"]["Window"].y, button_size.x, button_size.y)
    local hover3 = hover.IsTouching(m_x, m_y, x + (xs - button_offsets["Hover"]["Minimize"].x), y + button_offsets["Hover"]["Minimize"].y, button_size.x, button_size.y)

    if hover1 then
        l_draw.draw(window_img["Hover"]["Close"],x + (xs - button_offsets["Hover"]["Close"].x),y + button_offsets["Hover"]["Close"].y)
    else
        l_draw.draw(window_img["Default"]["Close"],x + (xs - button_offsets["Default"]["Close"].x),y + button_offsets["Default"]["Close"].y)
    end

    if hover2 then
        l_draw.draw(window_img["Hover"]["Window"],x + (xs - button_offsets["Hover"]["Window"].x),y + button_offsets["Hover"]["Window"].y)
    else
        l_draw.draw(window_img["Default"]["Window"],x + (xs - button_offsets["Default"]["Window"].x),y + button_offsets["Default"]["Window"].y)
    end

    if hover3 then
        l_draw.draw(window_img["Hover"]["Minimize"],x + (xs - button_offsets["Hover"]["Minimize"].x),y + button_offsets["Hover"]["Minimize"].y)
    else
        l_draw.draw(window_img["Default"]["Minimize"],x + (xs - button_offsets["Default"]["Minimize"].x),y + button_offsets["Default"]["Minimize"].y)
    end

    if icon then
        l_draw.draw(icon,x + 9,y + 9)
    end

    -- Main window Drawing code.

    l_draw.setScissor(x + window_sizes["Top"]["Left"].x,y + window_sizes["Top"]["Left"].y,xs - (window_sizes["Top"]["Left"].x + window_sizes["Top"]["Right"].x),ys - (window_sizes["Top"]["Left"].y + window_sizes["Bottom"]["Left"].y))

    l_draw.push()

    l_draw.translate(x + window_sizes["Top"]["Left"].x,y + window_sizes["Top"]["Left"].y)

    draw_func()

    l_draw.pop()

    love.graphics.setColor(1, 1, 1)

    l_draw.setScissor()

    return hover1, hover2, hover3
end

return WindowEngine