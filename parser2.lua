require 'set'
require 'string_util'
require 'list_util'

epsilon = 'epsilon'
epsilonSet = set {epsilon}


local grammar_mt = {}
grammar_mt.__index = grammar_mt
grammar_mt.__tostring = function(self)
    table.sort(self.productions, function(a, b)
        return a.nonterm < b.nonterm
    end)

    local t = {}
    for k,v in ipairs(self.productions) do
        table.insert(t, tostring(v))
    end

    return table.concat(t, '\n')
end

local production_mt = {}
production_mt.__index = production_mt
production_mt.__tostring = function(self)
    return self.nonterm .. ' -> ' .. table.concat(self.produces, ' ')
end

local function iterateWithFilter(list, filter)
    local i = 0
    local len = #list
    return function()
        while i < len do
            i = i + 1
            if filter(list[i]) then return list[i] end
        end
        return nil
    end
end

function production(nonterminal, rule)
    local produces = {}
    for match in string.gmatch(rule, "%S+") do
        produces[#produces + 1] = match
    end


    return setmetatable({
        nonterm = nonterminal,
        produces = produces
    }, production_mt)
end


function grammar_mt:productionsForSymbol(symbol, filter)
    return iterateWithFilter(self.productions, function(production)
        return production.nonterm == symbol
    end)
end

function grammar(rules)
    local productions = {}

    local nonterminals = set()

    for line in string.gmatch(rules, "[^\n]*") do
        local start, stop = string.find(line, '->')
        if start then
            local nonterm = trim(string.sub(line, 1, start - 1))
            local rule = trim(string.sub(line, stop + 1))
            productions[#productions + 1] = production(nonterm, rule)
            nonterminals[nonterm] = true
        end
    end

    return setmetatable({
        productions = productions,
        nonterminals = nonterminals,
    }, grammar_mt)
end

function grammar_mt:first(production)
    if not self.firstset then self.firstset = {} end

    if getmetatable(production) == production_mt then
        local firstSet = set()
        for k, var in ipairs(production.produces) do
            local fvar = self:first(var)
            firstSet:union(fvar - epsilonSet)
            if not fvar[epsilon] then
                break
            end
            if k == #production.produces then
                firstSet:union(epsilonSet)
            end
        end
        return firstSet
    elseif self.firstset[production] then
        return self.firstset[production]
    elseif type(production) == 'string' then
        if not self.nonterminals[production] then
            self.firstset[production] = set {production}
            return self.firstset[production]
        end

        local firstSet = set()
        self.firstset[production] = firstSet

        for p in self:productionsForSymbol(production) do
            firstSet:union(self:first(p))
        end

        return firstSet
    end
    error("no valid matches " .. tostring(production))
end

function grammar_mt:follow(symbol)
    assert(self.nonterminals[symbol], "symbol is not a nonterminal")

    if not self.followset then
        self.followset = {}
    end

    if self.followset[symbol] then return self.followset[symbol] end

    local followSet = set()
    if self.productions[1].nonterm == symbol then
        followSet['$'] = true
    end

    for k, production in ipairs(self.productions) do
        local adding = false
        for k,var in ipairs(production.produces) do
            if var == symbol then
                adding = true
            elseif adding then
                local f = self:first(var)
                local toAdd = f - epsilonSet
                assert(#followSet:intersect(toAdd) == 0, "conflict on " .. tostring(var))
                followSet:union(toAdd)
                if not f[epsilon] then
                    adding = false
                end
            end
        end
        if adding and production.nonterm ~= symbol then
            local toAdd = self:follow(production.nonterm)
            assert(#followSet:intersect(toAdd) == 0, "conflict")
            followSet:union(toAdd)
        end
    end
    self.followset[symbol] = followSet
    return followSet
end

function grammar_mt:parsetable()
    for nonterm in pairs(self.nonterminals) do
        -- TODO !
    end
end

local g = grammar([[
  A -> B C
  B -> a
  C -> c B
]])
print('follow of B: ' .. tostring(g:follow('B')))
