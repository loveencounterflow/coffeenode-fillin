
# CoffeeNode FillIn

String Interpolation library; also contains methods to fill in key/value pairs of objects and to iterate over nested facets

## What it does

At its simplest level, CoffeeNode FillIn allows to interpolate keyed (i.e. named or indexed) values into templates. The default syntax for quoted keys uses `$` (dollar sign) as the 'activator', `{}` (curly braces) as the (optional) 'opener' and 'closers', and `\` (backslash) as 'escaper'; all of these can be configured.

An simple example (in CoffeeScript):


````coffeescript
template  = 'helo $name!'
data      =
  'name':   'Jim'

text = FILLIN.fill_in template, data
````

Now `text` has the value `helo Jim!`. Here are some variations that demonstrate the results for a number
of variations on the above; you can see how backslashes are used to escape the activator and the get
removed from the output; also notice that expressions with doubled braces pass through untouched:

````coffeescript
'helo ${name}'     # gives 'helo Jim'
'helo \\$name'     # gives 'helo $name'
'helo \\${name}'   # gives 'helo ${name}'
'helo ${{name}}'   # gives 'helo ${{name}}'
````

It's possible to use a list as datasource; given JavaScript's dynamic and object-oriented nature, it's
possible to mix indexed and named references:

````coffeescript
template  = '$name was captain on $0, $1, and $2'
data      = [ 'NCC-1701', 'NCC-1701-A', 'NCC-1701-B', ]
# now `FILLIN.fill_in template, data` gives
# 'James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B'
````

````coffeescript
````

````coffeescript
````

````coffeescript
````

````coffeescript
````

````coffeescript
````

