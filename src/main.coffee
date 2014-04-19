

############################################################################################################
# njs_util                  = require 'util'
# njs_fs                    = require 'fs'
# njs_path                  = require 'path'
#...........................................................................................................
BAP                       = require 'coffeenode-bitsnpieces'
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


#===========================================================================================================
# WALKING OVER FACETS IN CONTAINERS
#-----------------------------------------------------------------------------------------------------------
@walk_containers_crumbs_and_values = ( value, handler ) ->
  ### Given a `value` and a `handler` with the signature `( error, container, crumbs, value )`, this method
  will call `handler null, container, crumbs, value` for each 'primitive' sub-value ('leaf value') that is
  found inside of `value`, where `container` is the list or POD that contains `value`, and `crumbs` is a
  (possibly empty) list of names that, when transformed as `'/' + crumbs.join '/'`, spells out the locator
  where `value` was found. When `crumbs` is not empty, its last element will be the index (in case of a
  list) or the name (in case of a POD) where `value` was found.

  When iteration is done, the method will make one additional call with all arguments set to `null`;
  consumers are able to detect that iteration has terminated by testing for `crumbs is null`.

  An **example** will show better what's happening:

  ````coffee
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

  BAP.walk_containers_crumbs_and_values d, ( error, container, crumbs, value ) ->
    throw error if error?
    if crumbs is null
      log 'over'
      return
    locator           = '/' + crumbs.join '/'
    # in case you want to mutate values in a container, use:
    [ head..., key, ] = crumbs
    log "#{locator}:", rpr value
  ````

  Output:

  ````
  /meaningless/0: 42
  /meaningless/1: 43
  /meaningless/2/foo: 1
  /meaningless/2/bar: 2
  /meaningless/2/nested/0: 'a'
  /meaningless/2/nested/1: 'b'
  /meaningless/3: 45
  /deep/down/in/a/drawer: 'a pen'
  /deep/down/in/a/cupboard: 'a pot'
  /deep/down/in/a/box: 'a pill'
  over
  ````

  As can be seen, there are no callbacks made for values that are lists or PODs, only for primitive values
  (or objects that are no lists and no PODs). Keep in mind that some JavaScript objects may *look* like PODs
  or lists, but are really something different. As the primary use case for this method is analysis of
  nested configurations read from a JSON file, such complexities have not been considered in the design of
  this method.

  You may pass a single primitive value to `@walk_containers_crumbs_and_values`; this will result in a
  callback where `crumbs` is an empty list and `value` is the value you passed in.

  **Caveats:**

  Because of the way iteration happens in CoffeeScript and JavaScript, it's not a good idea to modify the
  containers you're currently iterating over.
  [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for...in#Description)
  has the following to say:

  > If a property is modified in one iteration and then visited at a later time, its value in the loop is
  > its value at that later time. A property that is deleted before it has been visited will not be visited
  > later. Properties added to the object over which iteration is occurring may either be visited or omitted
  > from iteration. **In general it is best not to add, modify or remove properties from the object during
  > iteration, other than the property currently being visited.** There is no guarantee whether or not an
  > added property will be visited, whether a modified property (other than the current one) will be visited
  > before or after it is modified, or whether a deleted property will be visited before it is deleted.

  **Therefore, if deeper modifications are necessary, you may want to do those on a copy of the object
  you're inspecting, or else keep a log of intended changes and execute those changes when iteration has
  stopped.**

  The `crumbs` list in the callback is always the same object, so in case you want to use the values
  elsewhere—and especially when used in an asynchronous fashion—you may want to make a copy of that list.

  The method currently makes no effort to respect bad naming choices in any way, which means that you may
  get faulty or troublesome locators in case names are empty, consist of single or double periods, or
  contain slashes, asterisks or other meta-characters.

  ###
  container = null
  crumbs    = []
  @_walk_containers_crumbs_and_values container, crumbs, value, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@_walk_containers_crumbs_and_values = ( container, crumbs, value, handler ) ->
  ### ( used by @[`walk_containers_crumbs_and_values`](#this.walk_containers_crumbs_and_values)) ###
  TYPES   = require 'coffeenode-types'
  if      TYPES.isa_pod  value then return @_walk_pod_crumbs_and_values  container, crumbs, value, handler
  else if TYPES.isa_list value then return @_walk_list_crumbs_and_values container, crumbs, value, handler
  handler null, container, crumbs, value
  handler null, null, null, null if crumbs.length is 0
  return null

#-----------------------------------------------------------------------------------------------------------
@_walk_list_crumbs_and_values = ( container, crumbs, list, handler ) ->
  ### ( used by @[`walk_containers_crumbs_and_values`](#this.walk_containers_crumbs_and_values)) ###
  for value, idx in list
    crumbs.push idx
    @_walk_containers_crumbs_and_values list, crumbs, value, handler
    crumbs.pop()
  #.........................................................................................................
  handler null, null, null, null if crumbs.length is 0
  return null

#-----------------------------------------------------------------------------------------------------------
@_walk_pod_crumbs_and_values = ( container, crumbs, pod, handler ) ->
  ### ( used by @[`walk_containers_crumbs_and_values`](#this.walk_containers_crumbs_and_values)) ###
  for name, value of pod
    crumbs.push name
    @_walk_containers_crumbs_and_values pod, crumbs, value, handler
    crumbs.pop()
  #.........................................................................................................
  handler null, null, null, null if crumbs.length is 0

#-----------------------------------------------------------------------------------------------------------
@get = ( container, locator_or_crumbs, fallback ) ->
  R = ( @get_container_and_facet container, locator_or_crumbs )[ 2 ]
  if R is undefined
    return fallback unless fallback is undefined
    throw new Error "unable to resolve #{rpr locator_or_crumbs}"
  return R

#-----------------------------------------------------------------------------------------------------------
@get_container_and_facet = ( container, locator_or_crumbs ) ->
  return @container_and_facet_from_crumbs   container, locator_or_crumbs if TYPES.isa_list locator_or_crumbs
  return @container_and_facet_from_locator  container, locator_or_crumbs

#-----------------------------------------------------------------------------------------------------------
@container_and_facet_from_locator = ( container, locator ) ->
  ### The inverse to @[`walk_containers_crumbs_and_values`](#this.walk_containers_crumbs_and_values), this
  method uses a `locator` to drill down into `container`, recursively applying the 'crumbs' (parts) of
  the `locator` until all of the locator has been consumed; it will then return a triplet `[ sub_container,
  key, value, ]`.

  The locator must either be the string `/` (which denotes the `container` itself) or else a string that
  starts with but does not end with a `/`. ###
  rpr = ( require 'util' ).inspect
  if locator is '/'
    return [ null, null, container, ]
  else
    unless /^\/.*?[^\/]$/.test locator
      throw new Error "locator must start with but not end with a slash, got #{rpr locator}"
    ( crumbs = locator.split '/' ).shift()
  return @_container_and_facet_from_crumbs container, locator, crumbs, 0

#-----------------------------------------------------------------------------------------------------------
@container_and_facet_from_crumbs = ( container, crumbs ) ->
  ### Same as @[`container_and_facet_from_locator`](#this.container_and_facet_from_locator), but accepting
  a list of crumbs instead of a locator. ###
  if crumbs is null or crumbs.length is 0
    return [ null, null, container, ]
  locator = '/' + crumbs.join '/'
  return @_container_and_facet_from_crumbs container, locator, crumbs, 0

#-----------------------------------------------------------------------------------------------------------
@_container_and_facet_from_crumbs = ( container, locator, crumbs, idx ) ->
  ### (used by @[`container_and_facet_from_locator`](#this.container_and_facet_from_locator) and
  @[`container_and_facet_from_crumbs`](#this.container_and_facet_from_crumbs))
  ###
  rpr = ( require 'util' ).inspect
  key = crumbs[ idx ]
  throw new Error "unable to get crumb #{idx} from locator #rpr locator" unless key?
  #.........................................................................................................
  try
    value = container[ key ]
  catch error
    value = undefined
  #.........................................................................................................
  if value is undefined
    # debug '### container:', container
    # debug '### key:', key
    throw new Error "unable to resolve key #{rpr key} in locator #{rpr locator}"
  #.........................................................................................................
  return [ container, key, value ] if idx == crumbs.length - 1
  return @_container_and_facet_from_crumbs value, locator, crumbs, idx + 1
  return null

#-----------------------------------------------------------------------------------------------------------
@set = ( container, locator_or_crumbs, value ) ->
  TYPES = require 'coffeenode-types'
  if TYPES.isa_list locator_or_crumbs then  method_name = 'container_and_facet_from_crumbs'
  else                                      method_name = 'container_and_facet_from_locator'
  [ container
    key
    old_value ]     = @[ method_name ] container, locator_or_crumbs
  container[ key ]  = value
  return [ container, key, old_value, ]


#===========================================================================================================
# STRING INTERPOLATION
#-----------------------------------------------------------------------------------------------------------
@new_method = ( matcher_hint ) ->
  matcher = if TYPES.isa_jsregex matcher_hint then matcher else @new_matcher matcher_hint
  R = ( template, data, other_matcher ) =>
    return @fill_in template, data, ( other_matcher ? matcher )
  return R.bind @

#-----------------------------------------------------------------------------------------------------------
### TAINT use options argument ###
@new_matcher = ( options ) ->
  options    ?= {}
  activator   = options[ 'activator'  ] ? '$'
  opener      = options[ 'opener'     ] ? '{'
  closer      = options[ 'closer'     ] ? '}'
  escaper     = options[ 'escaper'    ] ? '\\'
  forbidden   = options[ 'forbidden'  ] ? """{}<>()|*+.,;:!"'$%&/=?`´#"""
  #.........................................................................................................
  forbidden   = TEXT.list_of_unique_chrs activator + opener + closer + escaper + forbidden
  forbidden   = ( BAP.escape_regex forbidden.join '' ) + '\\s'
  #.........................................................................................................
  activator   = BAP.escape_regex activator
  opener      = BAP.escape_regex opener
  closer      = BAP.escape_regex closer
  escaper     = BAP.escape_regex escaper
  #.........................................................................................................
  R = ///
    ( ^ | #{escaper}#{escaper} | [^#{escaper}] )
    (
      #{activator}
      (?:
        ( [^ #{forbidden} ]+ )
        |
        #{opener}
        ( (?:
                  #{escaper}#{activator}
                  |
                  #{escaper}#{opener}
                  |
                  #{escaper}#{closer}
                  |
                  [^ #{activator}#{opener}#{closer} ] )+ ) #{closer}
          )
      )
      ( (?: \\\$ | [^ #{activator} ] )* ) $
    ///
  #.........................................................................................................
  R[ 'remover' ] = /// #{escaper} ( #{activator} | #{opener} | #{closer} | #{escaper} )  ///g
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@fill_in = ( template_or_container, data, matcher ) ->
  if TYPES.isa_text template_or_container
    return @fill_in_template  template_or_container, data, matcher
  return @fill_in_container template_or_container, data, matcher

#-----------------------------------------------------------------------------------------------------------
@fill_in_template = ( template, data, matcher ) ->
  return @_fill_in_template template, ( @_get_data_and_matcher data, matcher )...

#-----------------------------------------------------------------------------------------------------------
@_fill_in_template = ( template, data, matcher, serialize = yes ) ->
  seen      = {}
  R         = template
  seen[ R ] = 1
  #.........................................................................................................
  loop
    #.......................................................................................................
    return R unless TYPES.isa_text R
    #.......................................................................................................
    [ has_matched
      R           ] = @_fill_in_template_once R, data, matcher, serialize
    #.......................................................................................................
    return R.replace matcher.remover, '$1' unless has_matched
    #.......................................................................................................
    if seen[ R ]?
      # seen[ R ] = 1
      seen      = [ ( rpr result for result of seen )..., rpr R ]
      seen      = seen.join '\n'
      throw new Error """
        detected circular references in #{rpr template}:
        #{seen}"""
    #.......................................................................................................
    seen[ R ] = 1

#-----------------------------------------------------------------------------------------------------------
@_fill_in_template_once = ( template, data, matcher, serialize = yes ) ->
  R = template
  [ position
    head
    markup
    name
    tail ]    = @_analyze_template template, matcher
  return [ false, template, ] unless position?
  is_full_length_name = head.length is 0 and tail.length is 0
  name                = '/' + name unless name[ 0 ] is '/'
  [ container
    key
    new_value ] = @container_and_facet_from_locator data, name
  #.........................................................................................................
  if is_full_length_name and not serialize
    R = new_value
  else
    R = head + ( if TYPES.isa_text new_value then new_value else rpr new_value ) + tail
  #.........................................................................................................
  return [ true, R, ]

#-----------------------------------------------------------------------------------------------------------
@_analyze_template = ( template, matcher ) ->
  #---------------------------------------------------------------------------------------------------------
  match = template.match matcher
  return [] unless match?
  [ ignored
    prefix
    markup
    bare
    bracketed
    tail      ] = match
  position      = match.index + prefix.length
  name          = bare ? bracketed
  head          = template[ ... position ]
  return [ position, head, markup, name, tail, ]

#-----------------------------------------------------------------------------------------------------------
@fill_in_container = ( container, data, matcher ) ->
  [ data, matcher, ] = @_get_data_and_matcher data, matcher
  data   ?= container
  # debug '>>> container:', container
  # debug '>>> data:', data
  # debug '>>> matcher:', matcher
  errors    = null
  serialize = no
  #.........................................................................................................
  fill_in = ( matcher, sub_container, crumbs, old_value  ) =>
    does_match  = matcher.test old_value
    new_value   = @_fill_in_template old_value, data, matcher, serialize
    if does_match
      if old_value is new_value
        locator   = '/' + crumbs.join '/'
        message   = "* unable to resolve #{locator}: #{rpr old_value} (circular reference?)"
        ( errors  = errors ? {} )[ message ] = 1
      else
        [ ..., key, ]         = crumbs
        sub_container[ key ]  = new_value
        change_count += 1
  #.........................................................................................................
  loop
    change_count = 0
    #-------------------------------------------------------------------------------------------------------
    @walk_containers_crumbs_and_values container, ( error, sub_container, crumbs, old_value ) =>
      throw error if error?
      return if crumbs is null
      return unless TYPES.isa_text old_value
      fill_in matcher, sub_container, crumbs, old_value
    #-------------------------------------------------------------------------------------------------------
    break if change_count is 0
  #.........................................................................................................
  if errors?
    error = new Error '\nerrors have occurred:\n' + ( ( m for m of errors ).sort().join '\n' ) + '\n'
    throw error
  #.........................................................................................................
  return container
# @fill_in.container = @fill_in.container.bind @


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_get_data_and_matcher = ( data, matcher ) ->
  return [ data, matcher, ] if matcher?
  return [ data, @default_matcher, ]

#-----------------------------------------------------------------------------------------------------------
@default_matcher = @new_matcher()

