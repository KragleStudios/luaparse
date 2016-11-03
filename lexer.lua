require 'automata'

local characters = {
    ' ', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}

local grammar = [[
S -> expr
expr -> expr1
expr1 -> expr2
expr1 -> expr2 | expr1
expr2 -> factor expr2
factor -> '(' expr ')'
factor -> char
]]


function regexToDFA(expr)

    local n = nfa()
    local start = n:newNode()

    local p_next
    local p_expr
    local p_kleene
    local p_union

    local index = #expr

    local function p_expr()
        local c = expr:sub(index, index)

        local _n_end_of_expr = n:newNode()
        local _n_next = _n_end_of_expr

        index = index - 1
        if c == ')' then
            local _n_tmp = n:newNode()
            local temp:link()
        end

    end

end
