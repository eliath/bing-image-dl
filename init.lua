#!/usr/bin/env th
-- Libs
require 'trepl'
require 'sys'
require 'pl'
require 'xlua'
local async = require 'async'
local http = require 'socket.http'
local col = require 'async.repl'.colorize
local json = require 'cjson'
local magick = require 'graphicsmagick'
local util = require 'moses'
util.extend(util, require('./utils'))

-- Argument parser:
local opt = lapp[[
Retrieve Bing images
   -q,--query     (string)                Query. REQUIRED.
   -a,--args      (default {})            Bing extra arguments in json format
   -b,--blacklist (default ./blacklist)   Relative path to a file that returns a blacklist as a lua table
   -c,--crop                              Crop as squares
   --cap          (default 10)            Max nb of transactions to execute
   --maxSize      (default 5000)          Fetch images of at most size
   --minSize      (default 256)           Fetch images of at least size
   -n,--nimages   (default 100)           Nb of images per class
   -o,--output    (default $query)        output dir
   -s,--start     (default 0)             Offset to start from (to resume downloading)
   -v,--verbose                           Verbose download
]]

local keyword = opt.query
print(keyword)
opt.args = json.decode(opt.args)
local formatted_query = opt.query:gsub('%s+', '_'):lower()

-- Resolve Blacklist
local ok, blacklist = pcall(require, opt.blacklist)
if not ok then
   util.warn('✗ Could not resolve blacklist. Continuing without. ['..opt.blacklist..']'..
      opt.blacklist..'"')
   blacklist = {}
else
   print('✔ Using blacklist from '..opt.blacklist)
end

local function blacklisted(...)
   local testStrings = {...}
   for _, word in ipairs(blacklist) do
      for _, str in ipairs(testStrings) do
         if str:lower():find(word:lower()) then
            io.write(' \r') io.flush()
            return true
         end
      end
   end
   return false
end

-- Output Dir?
if opt.output == '$query' then
   opt.output = formatted_query
else
   opt.output = path.abspath(opt.output)
end

local n_saved = 0 -- counter for image count
local n_error = 0 -- counter for http errors
local n_small = 0 -- counter for images that are too small
local n_large = 0 -- counter for images that are too large
local n_black = 0 -- counter for blacklisted images


local function fetchAndSave(url, filename)
   local data, code, header = http.request(url)
   if(code ~= 200) then
      if opt.verbose then
         util.printError('Download failed with code '..code, 'url = '..header.location)
      end
      return false
   end
   local image = magick.Image()
   if not pcall(image.fromString, image, data) then
      if opt.verbose then
         util.printError('Unable to deserialize binary data',
            header.location)
      end
      return false
   end
   local savePath = path.join(opt.output, filename)
   if not pcall(image.save, image, savePath) then
      if opt.verbose then
         util.printError('Unable to save image to disk',
            'Save path: '..savePath)
      end
      return false
   end
   return true
end


local function printStatus()
   -- print job status
   local status = {
      saved = {
         label = col.Green(stringx.rjust(' -- saved: ', 13)),
         count = col.Green(stringx.ljust(tostring(n_saved), 5))
      },
      err = {
         label = col.Red(stringx.rjust(' -- error: ', 13)),
         count = col.Red(stringx.ljust(tostring(n_error), 5))
      },
      small = {
         label = col.Yellow(stringx.rjust(' -- small: ', 13)),
         count = col.Yellow(stringx.ljust(tostring(n_small), 5))
      },
      large = {
         label = col.Yellow(stringx.rjust(' -- large: ', 13)),
         count = col.Yellow(stringx.ljust(tostring(n_large), 5))
      },
      black = {
         label = col.Red(stringx.rjust(' -- black: ', 13)),
         count = col.Red(stringx.ljust(tostring(n_black), 5))
      }
   }
   io.write(
      status.saved.label,  status.saved.count,
      status.err.label,    status.err.count,
      status.black.label,  status.black.count,
      status.small.label,  status.small.count,
      status.large.label,  status.large.count,
      '\r'
   )
   io.flush()
end

local _CONFIG = {
   url = 'https://api.cognitive.microsoft.com/bing/v5.0/images/search',
   headers = { ['Ocp-Apim-Subscription-Key'] = 'd70705762d16402f975ae1f754f168ca' },
   verbose = opt.verbose,
   format = 'json' -- parses the output: json -> Lua table
}

-- MAINLINE
async.fiber(function()
   -- Iterate over pages
   local n_transactions = 0
   local pageSize = math.min(50, opt.nimages)
   local start = opt.start
   while true do
      -- Break?
      if n_saved >= opt.nimages then
         break
      end
      if n_transactions >= opt.cap then
         break
      end

      local query = util.extend({}, {
         q = '"'.. keyword ..'"',
         safeSearch = 'Off',
         offset = start,
         count = pageSize
      }, opt.args)

      -- Retrieve page:
      n_transactions = n_transactions+1
      local res = async.fiber.sync.get(
         util.extend({}, _CONFIG, { query = query }))

      -- validate results
      assert(res._type == 'Images', 'Unexpected response type: "'..tostring(res._type)..'"')
      assert(res.value, 'Unreadable response:\n\n'..tostring(res)..'\n\n')

      -- assumed to be valid
      dir.makepath(opt.output)

      -- download
      for _,data in ipairs(res.value) do
         if n_saved >= opt.nimages then break end

         -- filters
         local smallSize = math.min(data.thumbnail.width, data.thumbnail.height)
         local bigSize = math.max(data.width, data.height)
         if bigSize < opt.minSize then
            n_small = n_small + 1
         elseif bigSize > opt.maxSize then
            n_large = n_large + 1
         elseif blacklisted(data.name, data.contentUrl, data.hostPageDisplayUrl) then
            n_black = n_black + 1
         else
            local filename = data.imageId .. '.' .. data.encodingFormat
            local url = data.contentUrl
            if smallSize >= opt.minSize then
               url = data.thumbnailUrl
            end
            if fetchAndSave(url, filename) then
               n_saved = n_saved + 1
            else
               n_error = n_error + 1
            end
         end
         printStatus()
      end
      -- Next page:
      start = start + pageSize
   end
   print(col.cyan('\n   -- Transactions completed: '..n_transactions))
end)

async.go()
