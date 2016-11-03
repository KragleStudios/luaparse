function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table"  then
            print(formatting)
            tprint(v, indent+1)
        else
            print(formatting .. tostring(v))
        end
    end
end
