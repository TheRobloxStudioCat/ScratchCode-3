local data, file_header = ...

local console_thread = love.thread.getChannel("ConsoleChannel")

local stack = 0

local variables = {}

local functions = {}

local if_stack = {}

local opcode_cmds = {
    [1] = function (args)
        local print_args = {}

        for _,v in ipairs(args) do
            table.insert(print_args, tostring(v))
        end

        console_thread:push("[LOG]: " .. table.concat(print_args, " "))

        --print(table.concat(args, " next argument, pls wait.. "))
    end,

    [2] = function (args)
        local print_args = {}

        for _,v in ipairs(args) do
            table.insert(print_args, tostring(v))
        end

        console_thread:push("[WARN]: " .. table.concat(print_args, " "))
    end,

    [3] = function (args)
        local print_args = {}

        for _,v in ipairs(args) do
            table.insert(print_args, tostring(v))
        end

        error("[ERROR]: " .. table.concat(print_args, " ").."\nStack trace: Line "..tostring(stack))
    end,

    [4] = function (args)
        love.timer.sleep(args[1])
    end,

    [5] = function (args)
        local function_to_run = functions[args[1]]

        print(function_to_run)

        if function_to_run then
            RunData(1,function_to_run)
        else
            error("[ERROR]: Not valid function!".."\nStack trace: Line "..tostring(stack))
        end
    end,

    [6] = function (args)
        variables[args[1]] = args[2]
    end,
}

--print(vm_pos)

require("love.timer")

function RunData(start_pos, run_dat)
    local vm_pos = start_pos

    while vm_pos <= #run_dat do
        local opcode = run_dat:byte(vm_pos)

        if not opcode or opcode == 0 then
            vm_pos = vm_pos + 1
        else
            --print(opcode)

            vm_pos = vm_pos + 1

            stack = stack + 1

            local arg_hash = run_dat:byte(vm_pos)

            local over_limit = vm_pos > #run_dat

            if over_limit then
                break
            end

            vm_pos = vm_pos + 1

            --print(type(arg_hash))

            local args = {}

            local function_to_run = opcode_cmds[opcode]

            for i = 1, arg_hash do
                --print("Line "..tostring(stack))

                local arg_type = run_dat:byte(vm_pos)
                local arg_len_big = run_dat:byte(vm_pos + 1)
                local arg_len_lower = run_dat:byte(vm_pos + 2)

                --print(arg_len_big, arg_len_lower)
                --print(arg_len_big == nil, arg_len_lower == nil)

                --local arg_len = arg_len_lower + (arg_len_big * 256)
                local arg_len = arg_len_big + (arg_len_lower * 256)

                --print(arg_len)

                --print(arg_len)

                local arg_data = run_dat:sub(vm_pos + 3, vm_pos + 2 + arg_len)

                local arg = arg_data

                if arg_type == 1 then
                    arg = arg_data
                elseif arg_type == 2 then
                    arg = tonumber(arg_data)
                elseif arg_type == 3 then
                    arg = variables[arg_data] or error("[ERROR]: Variables does not exist!".."\nStack trace: Line "..tostring(stack))
                elseif arg_type == 4 then
                    local op1_len = arg_data:byte(1)
                    local op1 = arg_data:sub(2,op1_len + 1)

                    local op2_len = arg_data:byte(op1_len + 2)
                    local op2 = arg_data:sub(op1_len + 3, op1_len + 2 + op2_len)

                    local oper = arg_data:byte(op1_len + 3 + op2_len)

                    local Op1 = variables[op1] or tonumber(op1)
                    local Op2 = variables[op2] or tonumber(op2)

                    local math_lookup = {
                        Op1 + Op2,
                        Op1 - Op2,
                        Op1 / Op2,
                        Op1 * Op2,
                    }

                    local final = math_lookup[oper]

                    arg = final
                elseif arg_type == 5 then
                    if arg_data == "t" then
                        arg = true
                    else
                        arg = false
                    end
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

    --print(lines)

    func_pos = func_pos + 4

    functions[name_func] = data:sub(func_pos, func_pos + lines)
    
    func_pos = func_pos + lines

    func_num = func_num + 1

    --print(func_pos)
end

RunData(func_pos, data)