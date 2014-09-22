# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
fs = require 'fs'
path = require 'path'
# include alinex modules
{string} = require 'alinex-util'


# Collecting sensor classes
# -------------------------------------------------
for file in fs.readdirSync path.join __dirname, 'type'
  if path.extname(file) is '.js'
    type = path.basename file, path.extname file
    module.exports[string.ucFirst type] = require "./type/#{type}"
