
############################################################################################################
# njs_util                  = require 'util'
# njs_fs                    = require 'fs'
# njs_path                  = require 'path'
#...........................................................................................................
# BAP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'
TEXT                      = require 'coffeenode-text'
TRM                       = require 'coffeenode-trm'
# FS                        = require 'coffeenode-fs'
rpr                       = TRM.rpr.bind TRM
badge                     = 'FILLIN'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
assert                    = require 'assert'
FILLIN                    = require './main'


#-----------------------------------------------------------------------------------------------------------
@main = ->
  @test_string_interpolation

############################################################################################################
templates = [
  "helo name"
  "helo ${name}"
  "helo \\${name}"
  "helo ${{name}}"
  "helo ${name:quoted}"
  "helo $name:quoted"
  "helo $name!"
  "helo +name!"
  "helo +(name:quoted)!"
  "helo !+name!"
  "helo !+(name:quoted)!"
  ]

@test_string_interpolation = ->

data =
  'name':   'Jim'
formats =
  'quoted': ( text ) -> return '"' + text + '"'

for template in templates
  log ( TRM.green 'A' ), ( TRM.grey template ), ( TRM.gold @fill_in template, data, formats )

custom_fill_in = @fill_in.create null, '+', '(', ')', '~', '!'
for template in templates
  log ( TRM.red 'B' ), ( TRM.grey template ), ( TRM.gold custom_fill_in template, data, formats )






    # echo """\\begin{textblock*}{15mm}[1,0.5](130mm,#{y_position})\\flushright —\\end{textblock*}"""

    #   # TEX.push rows, multicolumn [ 3, 'l', [ month_tex, year, ], ]
    #   TEX.push rows, multicolumn [ 3, 'l', TEX.new_container [ month_tex, ' ', year, ] ]
    #   TEX.push rows, next_cell
    #   TEX.push rows, 'H'
    #   TEX.push rows, next_cell
    #   TEX.push rows, multicolumn [ 1, 'r', 'L', ]
    #   TEX.push rows, next_cell
    #   TEX.push rows, next_line
    #   TEX.push rows, hline
    # #.......................................................................................................
    # if ( height = trc[ 'hi-water-height' ] )?
    #   hi_dots.push [ row_idx, height, ]
    # #.......................................................................................................
    # if ( height = trc[ 'lo-water-height' ] )?
    #   lo_dots.push [ row_idx, height, ]
    # #.......................................................................................................
    # if moon_quarter?
    #   trc[ 'moon-quarter' ] = moon_quarter
    #   moon_quarter                = null
    # #.......................................................................................................
    # if last_day is trc[ 'date' ][ 2 ]
    #   trc[ 'is-new-day' ]   = no
    #   trc[ 'date' ]         = null
    #   trc[ 'weekday-idx' ]  = null
    #   #.....................................................................................................
    #   if trc[ 'moon-quarter' ]?
    #     moon_quarter                = trc[ 'moon-quarter' ]
    #     trc[ 'moon-quarter' ] = null
    #   #.....................................................................................................
    #   else
    #     moon_quarter                = null
    # #.......................................................................................................
    # else
    #   trc[ 'is-new-day' ]   = yes
    #   last_day                    = trc[ 'date' ][ 2 ]
    # #.......................................................................................................
    # TEX.push rows, @new_row trc

############################################################################################################
# @main() unless module.parent?


# OPTIONS = require 'coffeenode-options'
# TRM.dir OPTIONS

# info OPTIONS.get_app_info()
# info OPTIONS.get_app_options()

# BAP                       = require 'coffeenode-bitsnpieces'

# d =
#   'flowers': [ 'roses', 'dandelion', 'tulip', ]
#   'foo':    42
#   'bar':    108
#   'deep':
#     'one':    1
#     'two':    2
#     'three':
#       'four':   4


# debug d
# info BAP.container_and_facet_from_locator d, '/foo'
# info BAP.container_and_facet_from_locator d, '/bar'
# info BAP.container_and_facet_from_locator d, '/deep'
# info BAP.container_and_facet_from_locator d, '/deep/one'
# info BAP.container_and_facet_from_locator d, '/deep/two'
# info BAP.container_and_facet_from_locator d, '/deep/three'
# info BAP.container_and_facet_from_locator d, '/deep/three/four'
# try
#   info BAP.container_and_facet_from_locator d, '/deep/three/four/bar'
#   throw new Error "missing error"
# catch error
#   log TRM.green error[ 'message' ]
#   log TRM.green 'OK'
# try
#   info BAP.container_and_facet_from_locator d, '/deep/four/bar'
#   throw new Error "missing error"
# catch error
#   log TRM.green error[ 'message' ]
#   log TRM.green 'OK'




# # d = CJSON.load njs_path.join BAP.get_app_home(), 'options.json'
# options = require njs_path.join BAP.get_app_home(), 'options.json'
# debug options
# info BAP.walk_containers_crumbs_and_values options, ( error, container, crumbs, value ) ->
#   throw error if error?
#   if crumbs is null
#     log 'over'
#     return
#   log '',
#     ( TRM.gold '/' + ( crumbs.join '/' ) )
#     # ( TRM.grey container )
#     ( TRM.lime rpr value )

# d =
#   meaningless: [
#     42
#     43
#     { foo: 1, bar: 2, nested: [ 'a', 'b', ] }
#     45 ]
#   deep:
#     down:
#       in:
#         a:
#           drawer:   'a pen'
#           cupboard: 'a pot'
#           box:      'a pill'

# BAP.walk_containers_crumbs_and_values d, ( error, container, crumbs, value ) ->
#   throw error if error?
#   if crumbs is null
#     log 'over'
#     return
#   locator           = '/' + crumbs.join '/'
#   # in case you want to mutate values in a container, use:
#   [ head..., key, ] = crumbs
#   log "#{locator}:", rpr value
#   # debug rpr key
#   if key is 'box'
#     container[ 'addition' ] = 'yes!'
#     debug container

# info d

# locators = [
#   '/meaningless/0'
#   '/meaningless/1'
#   '/meaningless/2/foo'
#   '/meaningless/2/bar'
#   '/meaningless/2/nested/0'
#   '/meaningless/2/nested/1'
#   '/meaningless/3'
#   '/deep/down/in/a/drawer'
#   '/deep/down/in/a/cupboard'
#   '/deep/down/in/a/box'
# ]

# for locator in locators
#   [ container
#     key
#     value     ] = BAP.container_and_facet_from_locator d, locator
#   info locator, ( TRM.grey locator ), ( TRM.gold key ), rpr value

# # log BAP.container_and_facet_from_locator 42, '/'

# #-----------------------------------------------------------------------------------------------------------
# compile_options = ( options ) ->
#   #---------------------------------------------------------------------------------------------------------
#   BAP.walk_containers_crumbs_and_values options, ( error, container, crumbs, value ) =>
#     throw error if error?
#     if crumbs is null
#       log 'over'
#       return
#     locator           = '/' + crumbs.join '/'
#     [ ..., key ]      = crumbs
#     return null unless TYPES.isa_text value
#     #-------------------------------------------------------------------------------------------------------
#     TEXT.fill_in value, ( error, fill_in_key, format ) =>
#       throw error if error?
#       return null unless key?
#       debug locator, key, value, fill_in_key, format

# info options
# compile_options options

# matcher = TEXT.fill_in.get_matcher()
# templates = [
#   'foo bar baz'
#   'foo $bar baz'
#   'foo ${bar} baz'
#   'foo ${bar/x/y} baz'
#   'foo ${bar/x/y} $month baz'
#   'foo ${bar/x/y/$month}  baz'
#   '$foo bar baz'
#   ]

# for template in templates
#   match = template.match matcher
#   if match?
#     [ ignored
#       prefix
#       markup
#       bare
#       bracketed
#       tail      ] = match
#     ### TAINT not correct ###
#     activator_length = 1
#     #.......................................................................................................
#     if bare?
#       name          = bare
#       ### TAINT not correct ###
#       opener_length = 1
#       closer_length = 1
#     else
#       name          = bracketed
#       opener_length = 0
#       closer_length = 0
#     #.......................................................................................................
#     log TRM.gold template
#     log TRM.plum template.replace matcher, ( ignored, prefix, markup, bare, bracketed, tail ) ->
#       return prefix + ( ( new Array markup.length + 1 ).join '_' ) + tail
#     log TRM.red TEXT.fill_in template, {}
#     info match[ 1 .. ]
#   else
#     whisper template

d =
  meaningless: [
    42
    43
    { foo: 1, bar: 2, nested: [ 'a', 'b', ] }
    45 ]
  deep:
    down:
      in:
        a:
          drawer:   '${/my-things/pen}'
          cupboard: '${/my-things/pot}'
          box:      '${${locations/for-things}/variable}'
  'my-things':
    pen:      'a pen'
    pot:      'a pot'
    pill:     'a pill'
    variable: '${/my-things/pill}'
  locations:
    'for-things':   '/my-things'
  ping1:      '${/ping4}'
  ping2:      '${/ping3}'
  ping3:      '${/ping2}'
  ping4:      '${/ping1}'
  pong:       '${/ping1}'

#   '/meaningless/3'
#   '/deep/down/in/a/drawer'


# TEXT.fill_in.container d
# debug d



############################################################################################################
# @options = CJSON.load njs_path.join BAP.get_app_home(), 'options.json'
# info BAP.compile_options @options

# info '$foo'.match BAP.compile_options.name_re

# options =
#   'columns': []
#   'moon-symbols':
#     'unicode': [ '⬤', '◐', '◯', '◑', ]
#     'tex':    [
#       '\\newmoon'
#       '\\rightmoon'
#       '\\fullmoon'
#       '\\leftmoon' ]
#   'weekday-names':
#     'dutch':
#       'full':         [ 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag', ]
#       'abbreviated':  [ 'ma', 'di', 'wo', 'do', 'vr', 'za', 'zo', ]
#   'month-names':
#     'dutch':
#       'full':         [ 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
#                         'juli', 'augustus', 'september', 'oktober', 'november', 'december', ]
#       'abbreviated':  [ 'jan', 'feb', 'maart', 'apr', 'mei', 'juni',
#                         'juli', 'aug', 'sept', 'oct', 'nov', 'dec', ]


# echo JSON.stringify options, null, '  '

# debug JSON.parse """{ "foo": "bar", "deep": [ { "zero": true }, 1,2,3] }""", ( key, value ) ->
#   info @, key#, value
#   return value




############################################################################################################
do @main



