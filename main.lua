local scr_code = require("libraries.scratchcode.main")

local window_eng = require("libraries.graphics")

local console_thread = love.thread.getChannel("ConsoleChannel")

local is_dragging = false
local offset_x, offset_y = 0, 0
local window_pos = {x = 0, y = 0} -- Начальная позиция окна

local utf8 = require("utf8")

local is_minimaze = false
local is_window = false
local is_close = false

local cursor_img = love.mouse.newCursor("images/cursor.png")

local history = {}
local history_v = 0

local title = "ScratchCode 3.0 VM and Compiler toolkit"

local graphics_mode = false

local function to_string(str)
    local str_symbol = str:sub(0,1)

    if str_symbol == "'" or str_symbol == '"' then
        local is_string = str:sub(0,1) == str_symbol and str:sub(#str,#str) == str_symbol

        print(str:sub(0,1), str:sub(#str,#str))

        if is_string then
            return str:sub(2,#str - 1)
        else
            return nil
        end
    else
        return nil
    end
end

local console_font = love.graphics.newFont("fonts/lucidaconsole.ttf")

local console = "ScratchCode 3.0 VM and Compiler console\nType 'help' to see all of the commands.\n"

local cursor = "_"

local current_command = ""

local header = "> /"

local blink_time = 0

local annyoed_bird = 0

local credits_song = love.audio.newSource("credits.mp3","stream")

local current_dir = ""

local char_pos = 0

local function addChar(char)
    local byte_offset = utf8.offset(current_command, char_pos + 1) or (#current_command + 1)
    
    local part1 = string.sub(current_command, 1, byte_offset - 1)
    local part2 = string.sub(current_command, byte_offset)
    
    current_command = part1 .. char .. part2
    
    char_pos = char_pos + utf8.len(char)
end

local function removeChar()
    if char_pos > 0 then
        local byte_start = utf8.offset(current_command, char_pos)
        
        local byte_next = utf8.offset(current_command, char_pos + 1) or (#current_command + 1)

        if byte_start then
            local part1 = string.sub(current_command, 1, byte_start - 1)
            local part2 = string.sub(current_command, byte_next)
            
            current_command = part1 .. part2
            
            char_pos = char_pos - 1
        end
    end
end

local commands = {
    ["echo"] = function (args)
        cons_print(args)
    end,

    ["about"] = function ()
        cons_print("ScratchCode 3.0\n\nMemory usage: %f\n\nScratchCode isn`t related to the Scratch programming language.\nThis software is open-source.")
    end,

    ["help"] = function ()
        cons_print("\nScratchCode 3.0 Console\n\n... - means that the argument count is unlimited.\n\nCommands:\n\nABOUT - Prints everything bout the current program\nECHO - Prints all of the arguments given to it. Arguments: ...\nHELP - Shows this. Arguments: None\nCLEAR - Clears the console. Arguments: None\nCOMPILE - Compiles code using the ScratchCode compiler. Arguments: filename, to\nRUN_CLASS - Runs a ScratchCode Class file. Arguments: filename\nDIR - Shows the contents of the current directory. Arguments: None\nCD - Moves to the directory you specified. Arguments: folder")
    end,

    ["credits"] = function ()
        credits_song:play()

        console = ""

        cons_print("Made by TheDreamingCat with love and silliness! :3\n\nIf you see this, pls check out my github!: https://github.com/TheRobloxStudioCat\nMy own site!: http://dreamingstudio.atwebpages.com")
    end,

    ["set_mode"] = function (args)
        if not args[1] then cons_print("[ERROR]: Not enough arguments! Need 1, got "..tostring(#args)) return nil end

        print("Idk how to implement this, i wanna make it restart the program with an argument..")
    end,

    ["run_demo"] = function (args)
        if not args[1] then cons_print("[ERROR]: Not enough arguments! Need 1, got "..tostring(#args)) return nil end

        if args[1] == "funcs" then
            cons_print("Running funcs demo...", false)

            love.filesystem.write("demo_funcs.result", scr_code.compile({
                "@func demo_Func",
                "print 'Fiddlesticks... Now here comes the 256 characters string!  EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'",
                "warn 'Demo?'",
                "@end_func",
                "@func DemoFunc2",
                "print 'Demo???'",
                "@end_func",
                "print 'Outside.'",
                "demo_Func",
                "var = 'smart!'",
                "print var",
                "DemoFunc2"
            }))

            scr_code.createVM(love.filesystem.read("demo_funcs.result"))
        elseif args[1] == "math" then
            cons_print("Running math demo...", false)

            love.filesystem.write("demo_math.result", scr_code.compile({
                "Cookies = 12",
                "ToTake = 4",
                "Taken = Cookies - ToTake",
                "print Taken"
            }))

            scr_code.createVM(love.filesystem.read("demo_math.result"))
        elseif args[1] == "bool" then
            cons_print("Running bool demo...", false)

            love.filesystem.write("demo_boolean.result", scr_code.compile({
                "print true"
            }))

            scr_code.createVM(love.filesystem.read("demo_boolean.result"))
        elseif args[1] == "error" then
            cons_print("Running error demo...", false)

            love.filesystem.write("demo_error.result", scr_code.compile({
                "error 12 / 2"
            }))

            scr_code.createVM(love.filesystem.read("demo_error.result"))
        elseif args[1] == "check" then
            cons_print("Running check demo...", false)

            love.filesystem.write("demo_check.result", scr_code.compile({
                "hasTreats = false",
                "@if hasTreats",
                "print 'Imma steal ya treats.'",
                "@end_if"
            }))

            scr_code.createVM(love.filesystem.read("demo_check.result"))
        end
    end,

    ["clear"] = function ()
        console = ""
    end,

    ["edit"] = function (args)
        
    end,

    ["compile"] = function (args)
        if not (args[1] and args[2]) then cons_print("[ERROR]: Not enough arguments! Need 2, got "..tostring(#args)) return nil end

        cons_print("Compiling with header: SCC\nCompiling file: "..args[1], false)

        local file_exists = love.filesystem.getInfo("/"..current_dir..args[1])

        if file_exists then
            local processed_tbl = {}

            for line in love.filesystem.lines("/"..current_dir..args[1]) do
                local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")

                if #trimmed > 0 then
                    table.insert(processed_tbl,line)
                end
            end

            local success, result = pcall(scr_code.compile, processed_tbl)

            if success then
                cons_print("Successfully compiled file!", true)

                love.filesystem.write("/"..current_dir..args[2], result)
            end
        else
            cons_print("[ERROR]: File does not exist!",true)
        end
    end,

    ["run_class"] = function (args)
        if not args[1] then cons_print("[ERROR]: Not enough arguments! Need 1, got "..tostring(#args)) return nil end

        local success, err = pcall(scr_code.createVM, love.filesystem.read("/"..current_dir..args[1]))

        cons_print("Trying to create a VM...")

        if success then
            cons_print("Succesfully ran VM!", true)
        else
            cons_print("[ERROR]: Can`t run!: "..err, true)
        end
    end,

    ["dir"] = function()
        cons_print("Directory listing of /" .. current_dir .. ": ")
        
        local files = love.filesystem.getDirectoryItems(current_dir)
        local save = love.filesystem.getSaveDirectory()

        local fetched = {}

        for _, v in ipairs(files) do
            local full_path = current_dir .. v

            local real_path = love.filesystem.getRealDirectory(full_path)

            if real_path == save then
                local info = love.filesystem.getInfo(full_path)
                local suffix = (info and info.type == "directory") and "/" or ""

                table.insert(fetched, v .. suffix)
            end
        end

        cons_print(table.concat(fetched, "\n"), true)
    end,


    ["cd"] = function(args)
        if not args[1] then cons_print("[ERROR]: Not enough arguments! Need 1, got "..tostring(#args)) return nil end

        cons_print("")

        local target = args[1]
        
        if target == ".." then
            current_dir = current_dir:match("(.-)[^/]+/?$") or ""
        elseif target == "/" or target == "\\" then
            current_dir = ""
        elseif target ~= "" then
            local new_path = current_dir .. target .. "/"
            if love.filesystem.getInfo(new_path, "directory") then
                current_dir = new_path
            else
                cons_print("[ERROR]: Directory not found: " .. target, true)
            end
        end

        header = "> /" .. current_dir .. " "
    end,

    -- You can re-add the birb!

    --[[

    ["birb_guy"] = function ()
        local if_nest = love.filesystem.getInfo("/nest/")

        if if_nest then
            if annyoed_bird == 0 then
                cons_print("Please, get out, this is my nest, you scared my birbs.")
            elseif annyoed_bird == -1 then
                cons_print("Yay my house is back!\nNOW GET OUT!")

                annyoed_bird = 1
            elseif annyoed_bird == 1 then
                cons_print("Hey, i told you to get out, please stop bothering me.")
            elseif annyoed_bird == 2 then
                cons_print("Bruh.")
            elseif annyoed_bird == 3 then
                cons_print("If you continue doing this, i WILL steal your Roblox account.")
            elseif annyoed_bird == 4 then
                cons_print("STOP.")
                cons_print("JUST STOP.", true)
            elseif annyoed_bird == 5 then
                cons_print("I AM AT MY BREAKPOINT, STOP RIGHT NOW.")
            elseif annyoed_bird == 6 then
                cons_print("THATS IT!")

                cons_print("DIE!",true)

                while true do
                    cons_print("DIE!",true)
                end
            end
        else
            cons_print("Why did you delete my home? :(")

            annyoed_bird = -2
        end

        annyoed_bird = annyoed_bird + 1
    end

    --]]
}

local icons = {
    ["def"] = love.graphics.newImage("icon.png"),
    ["inprogram"] = love.graphics.newImage("appicon.png")
}

local curr_icon = "def"

local function parseCMD(str)
    local args = {}

    local current = ""
    local in_quotes = false

    local quote_char = ""

    for i = 1, #str do
        local c = str:sub(i, i)
        
        if (c == "'" or c == '"') then
            if not in_quotes then
                in_quotes = true

                quote_char = c
                current = current .. c
            elseif c == quote_char then
                in_quotes = false
                current = current .. c
            else
                current = current .. c
            end
        elseif c == " " and not in_quotes then
            if #current > 0 then
                table.insert(args, current)

                current = ""
            end
        else
            current = current .. c
        end
    end
    
    if #current > 0 then table.insert(args, current) end

    return args
end

-- Returns the number limited to the range of x to y.
function math.limit(obj,x,y)
    local isBigger = obj > y
    local isSmaller = obj < x

    if isBigger then
        return y
    elseif isSmaller then
        return x
    end

    return obj
end

function cons_print(object, dont_print, no_nl)
    if type(object) == "table" then
        if dont_print then
            if no_nl then
                console = console..table.concat(object,", ").."\n"
            else
                console = console.."\n"..table.concat(object,", ").."\n\n"
            end
        else
            console = console..header..current_command.."\n"..table.concat(object,", ").."\n\n"
        end
    else
        if dont_print then
            if no_nl then
                console = console..tostring(object).."\n"
            else
                console = console.."\n"..tostring(object).."\n\n"
            end
        else
            console = console..header..current_command.."\n"..tostring(object).."\n\n"
        end
    end
end

function loadFile(filename)
    local obj = io.open(filename,"rb")

    title = filename

    curr_icon = "inprogram"

    if obj then
        local ret = obj:read("*a")

        obj:close()

        return ret
    else
        error("Error while parsing argument: "..filename)
    end
end

function love.load(arg)
    local graphics = arg[1] == "--graphics"

    print(#arg)

    if graphics then
        local load = arg[2]

        print(arg[2])

        if load then
            local file  = loadFile(load)

            graphics_mode = true

            scr_code.createVM(file)
        else
            error("Didn`t provide any Class file!")
        end
    else
        local load = arg[1]

        if load then
            local file  = loadFile(load)

            scr_code.createVM(file)
        end
    end

    --print(table.concat(full_arg, ", "))

    love.keyboard.setKeyRepeat(true)

    love.mouse.setCursor(cursor_img)
end

function love.update(dt)
    char_pos = math.limit(char_pos, 0, utf8.len(current_command))
    
    --print(char_pos)

    blink_time = blink_time + dt

    local channel_got = console_thread:pop()

    while channel_got do
        --print(channel_got)

        cons_print(channel_got, true, true)

        channel_got = console_thread:pop()
    end

    if blink_time > 1 then
        if cursor == "_" then
            cursor = " "
        else
            cursor = "_"
        end

        blink_time = 0
    end

    local mx, my = love.mouse.getPosition()

    local win_x, win_y = love.window.getPosition()

    if love.mouse.isDown(1) then
        if not is_dragging then
            if my < 30 then
                is_dragging = true

                offset_x = mx
                offset_y = my
            end
        else
            love.window.setPosition(win_x + (mx - offset_x), win_y + (my - offset_y))
        end
    else
        is_dragging = false
    end
end

function love.draw()
    is_close, is_window, is_minimaze = window_eng.drawWindow(0,0,800,600, title, icons[curr_icon], function ()
        if not graphics_mode then
            local byte_offset = utf8.offset(current_command, char_pos + 1) or (#current_command + 1)
            local part1 = string.sub(current_command, 1, byte_offset - 1)
            local part2 = string.sub(current_command, byte_offset)

            local full_command = part1..cursor..part2

            local text = console..header..full_command

            love.graphics.setColor(0,0,0)

            love.graphics.rectangle("fill",0,0,784,562)

            love.graphics.setColor(1,1,1)

            love.graphics.setFont(console_font)

            --print(console..header..full_command)

            love.graphics.printf(text,4,4,778,"left")

            local _, lines = console_font:getWrap(text, 778)

            if #lines > 46 then
                console = console:match("\n(.*)")
            end
        end
    end)
end

function love.textinput(text)
    if text == "'" then
        addChar(text)
        addChar(text)

        char_pos = char_pos - 1
    elseif text == '"' then
        addChar(text)
        addChar(text)

        char_pos = char_pos - 1
    else
        addChar(text)
    end

    blink_time = 0

    cursor = "_"
end

local function runCommand(str)
    if str ~= "" then
        local parsed_str = parseCMD(str)

        local function_to_run = commands[parsed_str[1]:lower()]

        for i,v in ipairs(parsed_str) do
            if i > 1 then
                if tonumber(v) then
                    v = tonumber(v)
                else
                    local str = to_string(v)

                    print(str)

                    if not str then
                        cons_print("Argument error!")

                        return nil
                    else
                        parsed_str[i] = str
                    end
                end
            end
        end

        if function_to_run then
            table.remove(parsed_str,1)

            function_to_run(parsed_str)
        else
            cons_print("Does not exist!")
        end
    else
        cons_print("Nothing has been given!")
    end
end

function love.keypressed(key)
    if key == "backspace" then
        removeChar()
    end

    if key == "return" then
        runCommand(current_command)

        table.insert(history, current_command)

        history_v = #history + 1

        current_command = ""
    end

    if key == "left" then
        char_pos = char_pos - 1
    end

    if key == "right" then
        char_pos = char_pos + 1
    end

    if key == "up" then
        local history_m = math.limit(history_v - 1,1,#history)

        history_v = history_m

        current_command = history[history_v]

        char_pos = utf8.len(current_command)
    end

    if key == "down" then
        local history_m = math.limit(history_v + 1,1,#history)

        history_v = history_m

        current_command = history[history_v]

        char_pos = utf8.len(current_command)
    end
end

function love.mousereleased()
    if is_close then
        love.event.quit()
    end

    if is_minimaze then
        love.window.minimize()
    end
end

function love.threaderror(thread, errorstr)
    cons_print("An error occured in a VM:\n\n"..errorstr, true, true)
end