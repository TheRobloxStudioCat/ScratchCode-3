local file_header = "SCC" -- Change this to something you want!

local opcodes = {
    ["print"] = 1,
    ["warn"] = 2,
    ["error"] = 3,
    ["wait"] = 4,
}

local custom_opcodes = {
    ["var"] = 5,
    ["func_run"] = 6
}

--local type_comp = "8Bits"

local ScratchCode = {}

local function syntaxGet(text) -- Self explanitory
    local saved_table = {}
    local saved_value = ""

    local inString = false

    local splitStr = " "

    for i = 1, #text do
        local char = text:sub(i, i)

        -- Toggle string mode
        if char == "'" or char == '"' then
            inString = not inString

            saved_value = saved_value .. char
        elseif char == splitStr and not inString then
            local trimmed = saved_value:match("^%s*(.-)%s*$")

            if trimmed ~= "" then
                table.insert(saved_table, trimmed)
            end
            
            saved_value = ""

            splitStr = ","
        else
            saved_value = saved_value .. char
        end

        if i == #text then
            local trimmed = saved_value:match("^%s*(.-)%s*$")

            if trimmed ~= "" then
                table.insert(saved_table, trimmed)
            end
        end
    end

    return saved_table
end

local function int_to_bytes(num, size)
    local res = {}

    for i = 1, size do
        local byte = num % 256

        table.insert(res, string.char(byte))
        num = math.floor(num / 256)
    end

    return table.concat(res)
end

local function compileSyntaxAdd(text)
    local var_name, equals_sign, expression = text:match("^(%S+)%s*(=)%s*(.*%S*)%s*$")

    if var_name and equals_sign and expression then
        return {custom_opcodes["var"],'"'..var_name..'"',expression}
    else
        return syntaxGet(text)
    end
end

local function getType(object_orig)
    local object = object_orig

    local is_string = object:sub(1,1) == "'" or object:sub(1,1) == '"'
    local is_number = tonumber(object)

    local lenght = #object

    if lenght > 65535 then
        print("[COMPILER]: Warning! One object goes over the limits. The object will now be cut off.")

        object = object:sub(1,65535)

        return 1,object
    end

    if is_string then
        return 1, object:gsub("^(['\"])(.*)%1$", "%2")
    elseif is_number then
        return 2, is_number
    else
        return 3, object
    end
end


local function compileOneLine(tbl,trace,not_chk_func)
    local buffer = {}

    local table_give = tbl

    if not not_chk_func then
        for i,v in ipairs(table_give) do
            if i == 1 then
                local current_oper = opcodes[v]

                if v == custom_opcodes["var"] then
                    --print("Variable")

                    table.insert(buffer,string.char(custom_opcodes["var"]))
                else
                    if current_oper then
                        table.insert(buffer,string.char(current_oper))
                    else
                        print("Using custom function...\nStack trace: Line "..tostring(trace))
                        
                        table.insert(buffer,string.char(custom_opcodes["func_run"]))

                        table.insert(buffer,string.char(1))

                        table.insert(buffer, int_to_bytes(#tbl[1],2))
                        table.insert(buffer,tbl[1])
                    end
                end
            end
        end
    end

    table.insert(buffer,string.char(#table_give - 1))

    for i = 1, #table_give do
        if i > 1 then
            local str = tostring(table_give[i])

            local type, clean_obj = getType(str)

            local len = int_to_bytes(#tostring(clean_obj),2)

            table.insert(buffer, string.char(type))

            table.insert(buffer, len)
            table.insert(buffer, clean_obj)
        end
    end

    return table.concat(buffer)
end

local function getCompiledList(table_main, title)
    cons_print("Assembling: "..title , true)

    local ret_list = {}

    for i,v in ipairs(table_main) do
        --print(v)

        local synt = compileSyntaxAdd(v)

        --print(#synt)

        table.insert(ret_list,compileOneLine(synt,i))
    end

    cons_print("Done.", true)

    cons_print("File header:"..file_header, true)

    cons_print("Compilation finised at:"..os.time(), true)

    return ret_list
end

function ScratchCode.compile(table_main)
    local ret_table = {}

    local func_saved = {}

    local current_func_pos = {}

    local current_func_name = {}

    local saved_func_cur = {}

    for i,v in ipairs(table_main) do
        local full = syntaxGet(v)

        if full[1] == "@func" then
            table.insert(current_func_name,full[2])
            table.insert(current_func_pos,i)
        elseif full[1] == "@end_func" then
            local compiled_ret = {}

            for i2 = 1,(i - current_func_pos[#current_func_pos] - 1) do
                local v2 = table_main[i2 + current_func_pos[#current_func_pos]]

                table.insert(compiled_ret,v2)
            end

            func_saved[current_func_name[#current_func_name]] = compiled_ret

            table.remove(current_func_name,#current_func_name)
            table.remove(current_func_pos,#current_func_pos)
        elseif not current_func_pos[1] then
            table.insert(ret_table,v)
        end
    end

    for k,v in pairs(func_saved) do
        print("Function: "..k.."\n"..table.concat(v,"\n"))
    end

    print("Main function:\n"..table.concat(ret_table,"\n"))
    
    local compiled_funcs = {}

    for k,v in pairs(func_saved) do
        local comp = table.concat(getCompiledList(v,"Function: "..k), string.char(0))

        table.insert(compiled_funcs,string.char(#k)..k..int_to_bytes(#comp,4)..comp)
    end

    local function_block = int_to_bytes(#compiled_funcs,4)..table.concat(compiled_funcs)

    local main_function_block = getCompiledList(ret_table,"main function")

    return file_header..function_block..table.concat(main_function_block,string.char(0))
end

function ScratchCode.createVM(data)
    local has_header = data:sub(1,#file_header) == file_header

    local stack = 0

    if has_header then
        local thread = love.thread.newThread("libraries/scratchcode/vm.lua")

        thread:start(data,file_header)
    else
        print("Compiled file isn`t valid, or compiled for another ScratchCode fork or version")
    end
end

return ScratchCode