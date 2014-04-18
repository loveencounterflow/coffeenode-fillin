
# CoffeeNode FillIn

String Interpolation library; also contains methods to fill in key/value pairs of objects and to iterate over nested facets

## What it does

At its simplest level, CoffeeNode FillIn allows to interpolate keyed (i.e. named or indexed) values into templates. The default syntax for quoted keys uses `$` (dollar sign) as the 'activator', `{}` (curly braces) as the (optional) 'opener' and 'closers', and `\` (backslash) as 'escaper'; all of these can be configured.

An example:

````coffeescript
$key
````

````coffeescript
James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B
````

````coffeescript
````

````coffeescript
data =
  'name':   'Jim'

template = 'helo $name!'

FILLIN.fill_in template, data
````

   'helo ${name}'     # gives 'helo Jim'
   'helo \\$name'     # gives 'helo \\$name'
   'helo \\${name}'   # gives 'helo \\${name}'
   'helo ${{name}}'   # gives 'helo ${{name}}'
   'helo $name!'      # gives 'helo Jim!'
