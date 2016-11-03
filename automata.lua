require 'set'
require 'constants'
require 'list_util'
require 'string_util'

local nfa_mt = {}
nfa_mt.__index = nfa_mt

function nfa_mt:link(a, b, symbol)
    if not a then error("attempt to add link to nonexistant node " .. tostring(a)) end
    if not self[a][symbol] then self[a][symbol] = set() end
    self[a][symbol][b] = true
end

function nfa_mt:newNode()
    table.insert(self, {})
    return #self
end

local dfa_mt = {}
dfa_mt.__index = dfa_mt

function dfa_mt:link(a, b, symbol)
    if not a then error("attempt to add link to nonexistant node " .. tostring(a)) end
    self[a][symbol] = b
end

function dfa_mt:newNode()
    table.insert(self, {})
    return #self
end

function dfa_mt:fromNFA(nfa)
    if #self ~= 0 then error("DFA must be uninitialized to inherit from NFA") end

    local superstateToDFAState = {}

    local function getDFAState(superstate)
        local index = list_indexOf(superstateToDFAState, superstate)
        if index then return index end
    end

    local function newDFAStateForSuperstate(superstate)
        local dfastate = {}

        table.insert(superstateToDFAState, superstate)
        table.insert(self, dfastate)

        return #self
    end

    local function epsilonClosure(superstate)
        local supersuperstate = set ()
        supersuperstate:union(superstate)
        for nfaStateId in pairs(superstate) do
            local state = nfa[nfaStateId]
            if state[epsilon] then
                supersuperstate:union(state[epsilon])
            end
        end
        return supersuperstate
    end

    local function createOrGetDFAState(superstate)
        superstate = epsilonClosure(superstate)

        local dfaStateId = getDFAState(superstate)
        if dfaStateId ~= nil then return dfaStateId end

        local dfaStateId = newDFAStateForSuperstate(superstate)

        local tempstate = {}
        for nfaStateId in pairs(superstate) do
            local state = nfa[nfaStateId]
            for symbol, superstateTo in pairs(state) do
                if not tempstate[symbol] then tempstate[symbol] = set () end
                tempstate[symbol]:union(superstateTo) -- can defer epsilon closure here since it will get applied
                  -- when we call createOrGetDFAState(superstateTo) later
            end
        end

        local dfaState = self[dfaStateId]
        for symbol, superstate in pairs(tempstate) do
            dfaState[symbol] = createOrGetDFAState(superstate)
        end

        return dfaStateId
    end

    createOrGetDFAState(set {1}) -- assumes that the first state is the start state! yay.
end

function nfa()
    return setmetatable({}, nfa_mt)
end

function dfa()
    return setmetatable({}, dfa_mt)
end
