local epsilon = 'EPSILON'

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function hasvalue(list, value)
    for k,v in ipairs(list) do
        if v == value then return k end
    end
    return false
end

local function unique(list)
    local function u_h(a, b, ...)
        if a == nil then return end
        if a ~= b then
            return a, u_h(b, ...)
        else
            return u_h(a, ...)
        end
    end
    table.sort(list)
    return {u_h(unpack(list))}
end

local function setunion(...)
    local r = {}
    local function u_h(a, ...)
        if a == nil then return end
        for k,v in ipairs(a) do
            table.insert(r, v)
        end
        u_h(...)
    end
    u_h(...)
    return unique(r)
end

local function setdiff(a, b)
    local r = {}
    local t = {}
    for k,v in ipairs(b) do
        t[v] = true
    end
    for k,v in ipairs(a) do
        if not t[v] then
            table.insert(r, v)
        end
    end
    return r
end

local function listsub(list, a, b)
    local r = {}
    for i = a, b or #list do
        if list[a] then
            table.insert(r, list[a])
        end
    end
    return r
end

function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        else
            print(formatting .. v)
        end
    end
end

function tprintpredictions(predictions)
    for symbol, predictions in pairs(predictions) do
        for terminal, production in pairs(predictions) do
            print('T[' .. symbol .. ',' .. terminal .. '] = ' .. symbol .. ' -> ' .. table.concat(production, ' '))
        end
    end
end

local grammar_mt = {}
grammar_mt.__index = grammar_mt

function grammar(list)
    local rules = {}

    local nonterm
    for k, production in ipairs(list) do
        local start, stop = string.find(production , '%->')
        if not start then
            start, stop = string.find(production, '|')
        end

        if start ~= nil then
            local match = string.sub(production, start, stop)
            if match == '->' then
                nonterm = trim(string.sub(production, 1, start - 1))
                rules[nonterm] = {}
            elseif match == '|' then
                if not nonterm then error ("not currently in a nonterminal. Bad grammar definition.") end
            end

            local rule = {}
            for var in string.gmatch(trim(string.sub(production, stop + 1)), "%S+") do
                table.insert(rule, var)
            end
            if #rule == 0 then
                table.insert(rules[nonterm], epsilon)
            else
                table.insert(rules[nonterm], rule)
            end
        end
    end

    setmetatable(rules, grammar_mt)

    return rules
end

function grammar_mt:first(productionOrSymbol, firsts)
    if type(productionOrSymbol) == 'string' then
        if not self[productionOrSymbol] then return {productionOrSymbol} end

        if firsts and firsts[productionOrSymbol] then return firsts[productionOrSymbol] end
        local toUnion = {}
        for k,v in ipairs(self[productionOrSymbol]) do
            local r = self:first(v, firsts)
            table.insert(toUnion, r)
        end
        local firstset = setunion(unpack(toUnion))
        if firsts and firsts then firsts[productionOrSymbol] = firstset end
        return firstset
    else
        local production = productionOrSymbol

        local firstSetAggregate = {}
        for i = 1, #production do
            local fi = self:first(production[i], firsts)
            table.insert(firstSetAggregate, setdiff(fi, {epsilon}))
            if not hasvalue(fi, epsilon) then
                break
            end
            if i == #production then
                table.insert(firstSetAggregate, {epsilon})
            end
        end
        local firstset = setunion(unpack(firstSetAggregate))
        return firstset
    end
end

function grammar_mt:follow(nonterm, follows, firsts)
    if not self[nonterm] then error "attempt to take follow of something that isn't a nonterminal" end
    if follows and follows[nonterm] then return follows[nonterm] end

    local agg = {}
    if nonterm == 'S' then
        table.insert(agg, {'$'})
    end

    local _nonterm = nonterm
    for nonterm, productions in pairs(self) do
        for k, production in ipairs(productions) do
            local index = hasvalue(production, _nonterm)
            if index then
                local follows = listsub(production, index + 1)

                -- If there is a production A → aB, then everything in FOLLOW(A) is in FOLLOW(B)
                -- If there is a production A → aBb, where FIRST(b) contains ε, then everything in FOLLOW(A) is in FOLLOW(B)
                if _nonterm ~= nonterm then
                    if #follows == 0 or hasvalue(self:first(follows, firsts), epsilon) then
                        table.insert(agg, self:follow(nonterm))
                    end
                end

                -- If there is a production A → aBb, (where a can be a whole string) then everything in FIRST(b) except for ε is placed in FOLLOW(B).
                for i = index + 1, #production do
                    local f = self:first(production[i])
                    table.insert(agg, setdiff(f, {epsilon}))
                    if not hasvalue(f, epsilon) then
                        break
                    end
                end
            end
        end
    end

    local follow = setunion(unpack(agg))
    if follows then
        follows[nonterm] = follow
    end
    return follow
end

function grammar_mt:predictions(symbol, predicttable, first, follow)
    if predicttable and predicttable[symbol] then return predicttable[symbol] end

    if not first then
        first = {}
    end
    if not follow then
        follow = {}
    end

    local predictions = {}
    for k, production in ipairs(self[symbol]) do
        local fp = self:first(production, firsts)
        if hasvalue(fp, epsilon) then
            for _, t in ipairs(self:follow(symbol, follow, first)) do
                if predictions[t] then
                    error("grammar not LL(1) conflict on production " .. symbol .. ' -> EPSILON ')
                end
                predictions[t] = production
            end
        end

        for k,t in ipairs(fp) do
            if t ~= epsilon then
                if predictions[t] then
                    error("grammar not LL(1) conflict on production " .. symbol .. ' -> ' .. table.concat(production, ' '))
                end
                predictions[t] = production
            end
        end
    end
    if predicttable then
        predicttable[symbol] = predictions
    end
    return predictions
end


--[[
README!
 'S' is a special state allways assumed to be the start state
]]
local g = grammar {
    "S -> E",
    "E -> T E'",
    "E' -> + T E'",
    "    | EPSILON",
    "T -> F T'",
    "T' -> * F T'",
    "    | EPSILON",
    "F  -> id",
    "    | ( id )",
}

local json = grammar {
    "S -> Item",
    "Array -> [ List ]",
    "List -> Item List'",
    "      | EPSILON",
    "List' -> , Item List'",
    "      | EPSILON",
    "Item -> Array",
    "      | Dictionary",
    "      | value",
    "Dictionary -> { KVPairs }",
    "KVPairs -> KVPair KVPairs'",
    "         | EPSILON",
    "KVPairs' -> KVPair , KVPairs'",
    "         | EPSILON",
    "KVPair -> key : Item",
}

g = json

local firsts = {}
for nonterm in pairs(g) do
    g:first(nonterm, firsts)
end

local follows = {}
for nonterm in pairs(g) do
    g:follow(nonterm, follows, firsts)
end

local predictions = {}
for nonterm in pairs(g) do
    g:predictions(nonterm, predictions, firsts, follows)
end

print("\nFIRSTS")
tprint(firsts)
print("\nFOLLOWS")
tprint(follows)
print("\nPREDICTIONS")
tprintpredictions(predictions)
