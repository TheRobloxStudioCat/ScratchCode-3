local data, file_header = ...

local console_thread = love.thread.getChannel("ConsoleChannel")

local stack = 0

local variables = {}

local functions = {}

local opcode_cmds = {
    [1] = function (args)
        console_thread:push("[LOG]: " .. table.concat(args, " "))
    end,

    [2] = function (args)
        console_thread:push("[WARN]: " .. table.concat(args, " "))
    end,

    [3] = function (args)
        error("[ERROR]: " .. table.concat(args, " "))
    end,

    [4] = function (args)
        love.timer.sleep(args[1])
    end,

    [5] = function (args)
        variables[args[1]] = args[2]
    end,

    [6] = function (args)
        local data_to_run = functions[args[1]]

        if not data_to_run then
            error("[ERROR]: Not valid function!")
        end

        RunData(1, data_to_run)
    end,
}

--print(vm_pos)

require("love.timer")

function RunData(start_pos, run_dat)
    local vm_pos = start_pos

    while vm_pos <= #data do
        local opcode = run_dat:byte(vm_pos)

        if not opcode or opcode == 0 then
            vm_pos = vm_pos + 1
        else
            --print(opcode)

            vm_pos = vm_pos + 1

            stack = stack + 1

            local arg_hash = run_dat:byte(vm_pos)
            vm_pos = vm_pos + 1

            local args = {}

            local function_to_run = opcode_cmds[opcode]

            for i = 1, arg_hash do
                --print("Line "..tostring(stack))

                local arg_type = run_dat:byte(vm_pos)
                local arg_len_big = run_dat:byte(vm_pos + 2)
                local arg_len_lower = run_dat:byte(vm_pos + 1)

                --local arg_len = arg_len_lower + (arg_len_big * 256)
                local arg_len = arg_len_big + (arg_len_lower * 256)

                --print(arg_len)

                local arg_data = run_dat:sub(vm_pos + 3, vm_pos + 2 + arg_len)

                local arg = arg_data

                if arg_type == 1 then
                    arg = arg_data
                elseif arg_type == 2 then
                    arg = tonumber(arg_data)
                else
                    arg = variables[arg_data]
                end

                table.insert(args,arg)

                --print("shi")
                --print(arg_len)

                vm_pos = vm_pos + 3 + arg_len
            end

            if function_to_run then
                function_to_run(args)
            else
                error("[VM]: Not valid function.".."\nStack trace: Line "..tostring(stack).."\n\nFunction opcode: "..tostring(opcode).."\n")
            end
        end
    end
end

local lowest_func = data:byte(#file_header + 1)
local low_func = data:byte(#file_header + 2)
local high_func = data:byte(#file_header + 3)
local highest_func = data:byte(#file_header + 4)

local funcs_num = lowest_func + (low_func * 256) + (high_func * 65536) + (highest_func * 16777216)

local func_pos = #file_header + 5

local func_num = 0

local last_pos = 0

while func_num < funcs_num do
    local name_len = data:byte(func_pos)

    func_pos = func_pos + 1

    local name_func = data:sub(func_pos, func_pos + name_len - 1)

    func_pos = func_pos + name_len

    local lowest_func = data:byte(func_pos)
    local low_func = data:byte(func_pos + 1)
    local high_func = data:byte(func_pos + 2)
    local highest_func = data:byte(func_pos + 3)

    local lines = lowest_func + (low_func * 256) + (high_func * 65536) + (highest_func * 16777216)

    print(lines)

    func_pos = func_pos + 4

    functions[name_func] = data:sub(func_pos, func_pos + lines)
    
    func_pos = func_pos + lines

    func_num = func_num + 1

    --print(func_pos)
end

RunData(func_pos, data)