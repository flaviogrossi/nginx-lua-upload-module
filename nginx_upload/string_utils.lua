local M = {}


function M.split(s, sSeparator, nMax, bRegexp)
    -- split the string s using the separator s. Returns the list of splits
    -- code inspired by http://lua-users.org/wiki/StringRecipes
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    if s == '' then
        return {''}
    end

    local aRecord = {}

    if s:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField=1 nStart=1
        local nFirst,nLast = s:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = s:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = s:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = s:sub(nStart)
    end

    return aRecord
end


function M.strip(s)
    -- strip leading and trailing whitespaces from s
    -- code taken from http://lua-users.org/wiki/StringRecipes
  return s:match "^%s*(.-)%s*$"
end


function M.enumerate_from_string_range(s)
    -- enumerate a sequence of numbers expressed as a list or range
    -- e.g.: enumerate_from_string_range('10,20,30-32') will return
    --   { ['10'] = true, ['20'] = true,
    --     ['30']: true, ['31']: true, ['32']: true }
    -- the format of the output table is chosen to easily test for membership:
    --   if t['10] then ... end

    local res = {}
    local range
    local start
    local stop

    for _, v in ipairs(M.split(s, ',')) do
        range = M.split(v, '-')
        if (#range == 1) then
            if tonumber(range[1]) then
                res[tonumber(range[1])] = true
            end
        elseif (#range == 2) then
            start = tonumber(range[1])
            stop = tonumber(range[2])
            if start and stop and stop >= start then
                for i=start,stop do
                    res[i] = true
                end
            end
        end
    end
    return res
end


return M
