
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
of variations on the above; you can see how backslashes

````coffeescript
'helo ${name}'     # gives 'helo Jim'
'helo \$name'      # gives 'helo \$name'
'helo \${name}'    # gives 'helo \${name}'
'helo ${{name}}'   # gives 'helo ${{name}}'
````

````coffeescript
James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B
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

