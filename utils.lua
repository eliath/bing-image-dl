local colorize = require 'async.repl'.colorize

local function _print(prefix, lines, color)
   for _,l in ipairs(lines) do
      print(colorize[color](prefix..' '..l))
   end
end

return {
   printError = function(...)
      _print('[ERROR]',{...},'red')
   end,
   warn = function(...)
      _print('[WARN]',{...},'orange')
   end
}
