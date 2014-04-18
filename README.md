
# CoffeeNode FillIn

String Interpolation library; also contains methods to fill in key/value pairs of objects and to iterate over nested facets

## What it does

At its simplest level, CoffeeNode FillIn allows to interpolate keyed (i.e. named or indexed) values into templates. The default syntax for quoted keys uses `$` (dollar sign) as the 'activator', `{}` (curly braces) as the (optional) 'opener' and 'closers', and `\` (backslash) as 'escaper'; all of these can be configured.

An simple example (in CoffeeScript):


````coffeescript
FI        = require 'coffeenode-fillin'
template  = 'helo $name!'
data      = 'name': 'Jim'

text = FI.fill_in template, data
````

Now `text` has the value `helo Jim!`. Here are some variations that demonstrate the results for a number
of variations on the above; you can see how backslashes de-activate the activator and then get
removed from the output; also notice that expressions with doubled braces pass through untouched:

````coffeescript
'helo ${name}'     # gives 'helo Jim'
'helo \\$name'     # gives 'helo $name'
'helo \\${name}'   # gives 'helo ${name}'
'helo ${{name}}'   # gives 'helo ${{name}}'
````

It's possible to use a list as datasource, and, given JavaScript's dynamic and object-oriented nature, it's
also possible to mix indexed and named references:

````coffeescript
template  = '$name was captain on $0, $1, and $2'
data      = [ 'NCC-1701', 'NCC-1701-A', 'NCC-1701-B', ]
# now `FI.fill_in template, data` gives
# 'James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B'
````

Dollarsigns as activators and backslashes as escapers are a widespread choice, but, depending on habits
and usecases, not always an optimal choice. Especially backslashes, which are used in JavaScript to write
symbolic characters such as, most frequently, `\n` (newline) and `\t` (tab), have a nasty habit of piling
up in source code (the current regex used by FillIn has no less than 40 of those, although a few could be
optimized away)—whenever you want a backslash to appear in your CoffeeScript, JavaScript or JSON source,
you have to remember to use *two* backslashes to obtain *one*.

For these reasons, it's possible to define your own templating syntax by calling

````coffeescript
matcher = FI.new_matcher activator: '+', opener: '(', closer: ')', escaper: '!'
````

(all unmentioned values are replaced with their standard values, `$`, `{`, `}`, and `\`; there's an
additional parameter `forbidden` that defaults to `{}<>()|*+.,;:!"'$%&/=?\`´#` and which specifies
characters that can not occur in names).

This matcher can now be used as an additional argument when calling `FI.fill_in`:

````coffeescript
template  = 'helo +name!'
data      = name: 'Jim'
FI.fill_in template, data, matcher # gives 'helo Jim!'
````

Escaping has become a tad simpler, as `!` is not a special character in JavaScript, so you can now write
`!+name' instead of `\\$name`. Of course, whether using these

For those


````coffeescript
````

````coffeescript
````

````coffeescript
````

````coffeescript
````

