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


return M
