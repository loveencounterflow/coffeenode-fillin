
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
badge                     = 'FILLIN/tests'
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
@test_argument_retrieval = ->
  handler = ->
  data    = 'foo': 'bar'
  matcher = /.*/
  probes  = [
    [ [ data, ], [ data, FILLIN.default_matcher, ], ]
    [ [ data, matcher, ], [ data, matcher, ], ]
    ]
  assert.notEqual FILLIN.default_matcher, undefined
  for [ parameters, expected, ] in probes
    result = FILLIN._get_data_and_matcher parameters...
    # log ( TRM.green 'test_argument_retrieval' ), ( TRM.grey parameters ), ( TRM.gold result )
    assert.deepEqual result, expected

#-----------------------------------------------------------------------------------------------------------
@test_standard_syntax_1 = ->
  templates_and_expectations = [
    [ 'helo name',          'helo name', ]
    [ '$name',              'Jim', ]
    [ 'helo ${name}',       'helo Jim', ]
    [ 'helo ${name} \\$ {n2}...',       'helo Jim $ {n2}...', ]
    [ 'helo \\\\${name}',   'helo \\Jim', ]
    [ 'helo \\$name',       'helo $name', ]
    [ 'helo \\${name}',     'helo ${name}', ]
    [ 'helo ${{name}}',     'helo ${{name}}', ]
    [ 'helo $name!',        'helo Jim!', ]
    [ 'helo +name!',        'helo +name!', ]
    [ 'helo !+name!',       'helo !+name!', ]
    ]
  #.........................................................................................................
  data =
    'name':   'Jim'
  #.........................................................................................................
  for [ template, expected ] in templates_and_expectations
    result = FILLIN.fill_in template, data
    log ( TRM.green 'test_standard_syntax_1' ), ( TRM.grey template ), ( TRM.gold result )
    assert.equal result, expected

#-----------------------------------------------------------------------------------------------------------
@test_data_lists = ->
  templates_and_expectations = [
    [ '$name was captain on $0, $1, and $2',      'James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B', ]
    ]
  #.........................................................................................................
  data = [ 'NCC-1701', 'NCC-1701-A', 'NCC-1701-B', ]
  data[ 'name' ] = 'James T. Kirk'
  #.........................................................................................................
  for [ template, expected ] in templates_and_expectations
    result = FILLIN.fill_in template, data
    log ( TRM.green 'test_data_lists' ), ( TRM.grey template ), ( TRM.gold result )
    assert.equal result, expected

#-----------------------------------------------------------------------------------------------------------
@test_recursive_expansions = ->
  templates_and_expectations = [
    [ 'i have 2 apples',        'i have 2 apples', ]
    [ 'i have $two apples',     'i have 2 apples', ]
    [ 'i have $some apples',    'i have 2 apples', ]
    [ 'i have ${more} apples',  'i have 3 apples', ]
    [ 'i have ${/more} apples', 'i have 3 apples', ]
    ]
  #.........................................................................................................
  data =
    'some':  '$two'
    'more':  '$three'
    'two':   '2'
    'three': '3'
  #.........................................................................................................
  matcher = FILLIN.default_matcher
  #.........................................................................................................
  for [ template, expected ] in templates_and_expectations
    result_1 = FILLIN.fill_in_template template, data, matcher
    result_2 = FILLIN.fill_in_template template, data
    assert.equal result_1, result_2
    assert.equal result_1, expected

#-----------------------------------------------------------------------------------------------------------
@test_cycle_detection = ->
  templates_and_expectations = [
    [ 'i have $some apples',    'i have 2 apples', ]
    ]
  #.........................................................................................................
  data =
    'some':  '$more'
    'more':  '$three'
    'three': '$some'
  #.........................................................................................................
  for [ template, expected ] in templates_and_expectations
    assert.throws ( -> FILLIN.fill_in_template template, data ), /detected circular references/

#-----------------------------------------------------------------------------------------------------------
@test_custom_syntax_1 = ->
  templates_and_expectations = [
    [ 'helo name',        'helo name', ]
    [ 'helo ${name}',     'helo ${name}', ]
    [ 'helo \\$name',     'helo \\$name', ]
    [ 'helo \\${name}',   'helo \\${name}', ]
    [ 'helo ${{name}}',   'helo ${{name}}', ]
    [ 'helo $name!',      'helo $name!', ]
    [ 'helo +name!',      'helo Jim!', ]
    [ 'helo !+name!',     'helo +name!', ]
    [ 'helo !!+name!',     'helo !Jim!', ]
    [ 'helo +(name)!',    'helo Jim!', ]
    ]
  #.........................................................................................................
  data =
    'name':   'Jim'
  matcher = FILLIN.new_matcher activator: '+', opener: '(', closer: ')', escaper: '!'
  #.........................................................................................................
  for [ template, expected ] in templates_and_expectations
    result = FILLIN.fill_in template, data, matcher
    log ( TRM.green 'test_custom_syntax_1' ), ( TRM.grey template ), ( TRM.gold result )
    assert.equal result, expected

#-----------------------------------------------------------------------------------------------------------
@test_walk_containers_crumbs_and_values = ->
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
            drawer:   'a pen'
            cupboard: 'a pot'
            box:      'a pill'
  #.........................................................................................................
  result = []
  FILLIN.walk_containers_crumbs_and_values d, ( error, container, crumbs, value ) ->
    throw error if error?
    if crumbs is null
      return
    result.push container: container, crumbs: ( crumb for crumb in crumbs ), value: value
  # echo JSON.stringify result#, null, '  '
  assert.deepEqual result, [{"container":[42,43,{"foo":1,"bar":2,"nested":["a","b"]},45],"crumbs":["meaningless",0],"value":42},{"container":[42,43,{"foo":1,"bar":2,"nested":["a","b"]},45],"crumbs":["meaningless",1],"value":43},{"container":{"foo":1,"bar":2,"nested":["a","b"]},"crumbs":["meaningless",2,"foo"],"value":1},{"container":{"foo":1,"bar":2,"nested":["a","b"]},"crumbs":["meaningless",2,"bar"],"value":2},{"container":["a","b"],"crumbs":["meaningless",2,"nested",0],"value":"a"},{"container":["a","b"],"crumbs":["meaningless",2,"nested",1],"value":"b"},{"container":[42,43,{"foo":1,"bar":2,"nested":["a","b"]},45],"crumbs":["meaningless",3],"value":45},{"container":{"drawer":"a pen","cupboard":"a pot","box":"a pill"},"crumbs":["deep","down","in","a","drawer"],"value":"a pen"},{"container":{"drawer":"a pen","cupboard":"a pot","box":"a pill"},"crumbs":["deep","down","in","a","cupboard"],"value":"a pot"},{"container":{"drawer":"a pen","cupboard":"a pot","box":"a pill"},"crumbs":["deep","down","in","a","box"],"value":"a pill"}]

#-----------------------------------------------------------------------------------------------------------
@test_fill_in_container_1 = ->
  d =
    ping1:      '${/ping4}'
    ping2:      '${/ping3}'
    ping3:      '${/ping2}'
    ping4:      '${/ping1}'
    pong:       '${/ping1}'
  #.........................................................................................................
  assert.throws ( -> FILLIN.fill_in d ), /detected circular references/

#-----------------------------------------------------------------------------------------------------------
@test_fill_in_container_2 = ->
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
  #.........................................................................................................
  # debug JSON.stringify ( FILLIN.fill_in d )#, null, '  '
  assert.deepEqual ( FILLIN.fill_in d ), {"meaningless":[42,43,{"foo":1,"bar":2,"nested":["a","b"]},45],"deep":{"down":{"in":{"a":{"drawer":"a pen","cupboard":"a pot","box":"a pill"}}}},"my-things":{"pen":"a pen","pot":"a pot","pill":"a pill","variable":"a pill"},"locations":{"for-things":"/my-things"}}

#-----------------------------------------------------------------------------------------------------------
@_test_fill_in_container_3 = ->
  d =
    foo:
      bar:
        'baz'
      gnu:
        '${bar}'
  #.........................................................................................................
  # debug JSON.stringify ( FILLIN.fill_in d )#, null, '  '
  assert.deepEqual ( FILLIN.fill_in d ), {"foo":{"bar":"baz","gnu":"baz"}}

# #-----------------------------------------------------------------------------------------------------------
# @test_fill_in_container_4 = ->
#   d =
#     weekdays:
#       'dutch':
#         'full':         [ 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag', ]
#         'abbreviated':  [ 'ma', 'di', 'wo', 'do', 'vr', 'za', 'zo', ]
#       'english':
#         'full':         [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', ]
#         'abbreviated':  [ 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su', ]
#     days: [
#       language:
#         'english'
#       '${${/days/0/language}/full/0}': "Go to work"
#       ]
#   #.........................................................................................................
#   # debug JSON.stringify ( FILLIN.fill_in d ), null, '  '


#-----------------------------------------------------------------------------------------------------------
@main = ->
  for method_name of @
    continue if method_name is 'main'
    continue if method_name[ 0 ] is '_'
    warn method_name
    @[ method_name ].apply this
  # @test_argument_retrieval()
  # @test_standard_syntax_1()
  # @test_data_lists()
  # @test_recursive_expansions()
  # @test_cycle_detection()
  # @test_custom_syntax_1()
  # @test_walk_containers_crumbs_and_values()
  # @test_fill_in_container_1()
  # @test_fill_in_container_2()
  # @test_fill_in_container_3()
  # @test_fill_in_container_4()


############################################################################################################
do @main

debug FILLIN.default_matcher.source


