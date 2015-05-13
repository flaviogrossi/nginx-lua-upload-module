local M = {}


function M.joinpath(a, ...)
    -- just like python's os.path.join

    local path = {a}
    local concatenated_path
    local path_len
    local args = {n = select("#", ...), ...} -- like table.pack(...) in lua 5.2
    local cur_arg
    for i = 1,args.n do
        cur_arg = args[i]
        if cur_arg then
            if cur_arg:sub(1,1) == '/' then
                path = {cur_arg}
            else
                concatenated_path = table.concat(path)
                path_len = concatenated_path:len()
                if concatenated_path == ''
                   or concatenated_path:sub(path_len, path_len) == '/'then
                   table.insert(path, cur_arg)
               else
                   table.insert(path, '/'..cur_arg)
               end
            end
        end
    end
    return table.concat(path)
end


return M
