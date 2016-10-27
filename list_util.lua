function list_indexOf(list, value)
    for k,v in ipairs(list) do
        if v == value then
            return k
        end
    end
    return nil
end

function list_drop(list, drop)
    return {select(drop + 1, unpack(list))}
end
