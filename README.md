# luaparse
Implementation of various parsing algorithms for LL(1), LR(0) and LR(1) grammars in Lua


want to make a JSON parser? (not all of this is implemented yet but it is coming...)

```Lua
local json = grammar {
    "S -> Item", function(item) return item end,
    "Array -> [ List ]", function(_1, list, _2)
        return list
    end,
    "List -> Item List'", function(item, listPrime)
        table.insert(listPrime, item) -- because of limitations of LL(1) this will make items appear in reverse order sadness
        return listPrime
    end,
    "      | EPSILON", function() return {} end,
    "List' -> , Item List'", function(item, listPrime)
        table.insert(listPrime, item)
        return listPrime
    end,
    "      | EPSILON", function() return {} end,
    "Item -> Array", function(array) return array end,
    "      | Dictionary", function(dict) return dict end,
    "      | value", function(value) return tostring(value) end, -- since this is a token
    "Dictionary -> { KVPairs }", function(_1, kvpairs, _2)
        return kvpairs
    end,
    "KVPairs -> Item : Item KVPairs'", function(key, value, kvpairs)
        kvpairs[key] = value
    end,
    "         | EPSILON", function() return {} end,
    "KVPairs' -> Item : Item , KVPairs'", function(key, value, kvpairs)
        kvpairs[key] = value
    end,
    "         | EPSILON", function() return {} end,
}
```
would define the entire parser. want to parse some json?
```
json.parse(jsonlexer.lex([[
[
   "item1",
   "item2",
   "item3",
]))
