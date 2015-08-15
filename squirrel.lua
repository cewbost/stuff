-- Copyright 2015- Erik Boström See LICENSE.
-- Squirrel LPeg lexer.

local l = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'lua'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline^0
local line_comment2 = '#' * l.nonnewline^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- Strings.
local d_str = l.delimited_range('"', true)
local v_str = P('@')^-1 * l.delimited_range('"', true)
local sin_c = l.delimited_range("'", true)
local string = token(l.STRING, d_str + v_str)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match{
  'base', 'break', 'case', 'catch', 'class', 'clone',
  'continue', 'const', 'default', 'delete', 'else', 'enum',
  'extends', 'for', 'for_each', 'function', 'if', 'in',
  'local', 'num', 'resume', 'return', 'switch', 'this',
  'throw', 'try', 'typeof', 'while', 'yield', 'constructor',
  'instanceof', 'true', 'false', 'static'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('!=|&<>+-/*%^~{}[].,:;@'))

M._rules = {
  {'whitespace', ws},
  {'keyword', keyword},
  {'identifier', identifier},
  {'string', string},
  {'comment', comment},
  {'number', number},
  {'operator', operator},
}

local function fold_longcomment(text, pos, line, s, match)
  if match == '[' then
    if line:find('^%[=*%[', s) then return 1 end
  elseif match == ']' then
    if line:find('^%]=*%]', s) then return -1 end
  end
  return 0
end

M._foldsymbols = {
  _patterns = {'%l+', '[%({%)}]', '[%[%]]', '%-%-'},
  [l.KEYWORD] = {
    ['if'] = 1, ['do'] = 1, ['function'] = 1, ['end'] = -1, ['repeat'] = 1,
    ['until'] = -1
  },
  [l.COMMENT] = {
    ['['] = fold_longcomment, [']'] = fold_longcomment,
    ['--'] = l.fold_line_comments('--')
  },
  longstring = {['['] = 1, [']'] = -1},
  [l.OPERATOR] = {['('] = 1, ['{'] = 1, [')'] = -1, ['}'] = -1}
}

return M
