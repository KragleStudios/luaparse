local set_mt = {
    __sub = function(a, b)
        local c = set()
        for k,v in pairs(a) do
            if b[k] == nil then
                c[k] = true
            end
        end
        return c
    end,
    __add = function(a, b)
        local c = set()
        for k,v in pairs(a) do
            c[k] = true
        end
        for k,v in pairs(b) do
            c[k] = true
        end
        return c
    end,

    __tostring = function(self)
        local l = {}
        for k,v in pairs(self) do
            table.insert(l, k)
        end
        table.sort(l)
        return 'set(' .. table.concat(l, ', ') .. ')'
    end,

    __len = function(self)
        local c = 0
        for k,v in pairs(self) do
            c = c + 1
        end
        return c
    end,

    __index = {
        tolist = function(self)
            local list = {}
            local c = 1
            for k,v in pairs(self) do
                list[c] = k
                c = c + 1
            end
            return list
        end,
        union = function(self, other)
            for k,v in pairs(other) do
                self[k] = true
            end
        end,

        intersect = function(self, other)
            local r = set()
            for k,v in pairs(self, other) do
                if other[k] then
                    r[k] = true
                end
            end
            return r
        end,
    },
}

function set(list)
    local t = {}
    if list then
        for k,v in ipairs(list) do
            t[v] = true
        end
    end
    return setmetatable(t, set_mt)
end
