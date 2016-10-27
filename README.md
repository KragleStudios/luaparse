# luaparse
Implementation of various parsing algorithms for LL(1), LR(0) and LR(1) grammars in Lua.

## Project Goals
 - include a lexer that supports formal regex operations
    - union, concatenation, klene closure, complement
 - include a parser that generates !!FAST!! LL(1) recursive descent parsers for simple grammars
 - include a parser that generates more powerful LR(1) bottom up parser capable of parsing the grammar for lua
 - include an example project that parses JSON
 - include an example project that parses the Lua language and shortens variable names 

## Currently Implemented 
 - initial version of LL(1) recursive descent parser with prediction table generation but no parsing 
