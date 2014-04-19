

- [CoffeeNode Fillin](#coffeenode-fillin)
- [Using Fillin with Strings](#using-fillin-with-strings)
	- [Basic Usage](#basic-usage)
	- [Routes as Keys](#routes-as-keys)
	- [Indexes as Keys and Multiple Interpolations](#indexes-as-keys-and-multiple-interpolations)
	- [Nested Interpolations](#nested-interpolations)
	- [Chained (Recursive) Interpolations](#chained-recursive-interpolations)
	- [Circular Interpolations](#circular-interpolations)
- [Using Fillin with containers](#using-fillin-with-containers)
- [Bonus Methods](#bonus-methods)
- [Implementation Details](#implementation-details)
	- [The RegEx](#the-regex)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


## CoffeeNode Fillin

CoffeeNode Fillin is a String Interpolation library; also contains methods to fill in key/value pairs of
objects and to iterate over nested facets. It may be used e.g. to produce texts with variable contents
or to compile configuration objects.

## Using Fillin with Strings

### Basic Usage

At its simplest level, CoffeeNode Fillin allows to interpolate keyed (i.e. named or indexed) values into templates. The default syntax for quoted keys uses `$` (dollar sign) as the 'activator', `{}` (curly braces) as the (optional) 'opener' and 'closers', and `\` (backslash) as 'escaper'; all of these can be configured.

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

Dollar signs as activators and backslashes as escapers are a widespread choice, but, depending on habits
and usecases, not always an optimal choice. Especially backslashes have a nasty habit of piling
up in source code (the RegEx used by CND Fillin has no less than 40 of those, although a few could be
optimized away)—whenever you want a backslash to appear in your CoffeeScript, JavaScript or JSON source,
you have to remember to use *two* backslashes to obtain *one*.

For these reasons, it's possible to define your own templating syntax by calling

````coffeescript
matcher = FI.new_matcher activator: '+', opener: '(', closer: ')', escaper: '!'
````

> (all unmentioned values are replaced with their standard values, `$`, `{`, `}`, and `\`; there's an
> additional parameter `forbidden` that defaults to ``{}<>()|*+.,;:!"'$%&/=?`´#`` and which specifies
> characters that can not occur in names; it will always be made to include the 'active' charcters of the
> pattern).

This matcher can now be used as an additional argument when calling `FI.fill_in`:

````coffeescript
template  = 'helo +name!'
data      = name: 'Jim'
FI.fill_in template, data, matcher # gives 'helo Jim!'
````

Escaping has just become a tad simpler, as `!` is not a special character in JavaScript, so you can now write
`!+name` instead of `\\$name`. Of course, whether using these particular characters is a good idea will
depend a lot on your data.

Finally, to make work with custom syntaxes even simpler, you can use
````coffeescript
fill_in = FI.new_method matcher
````
or, say,
````coffeescript
fill_in = FI.new_method escaper: '^'
````
to define a `fill_in` method using your custom syntax; RegExes are used as-is, and options are passed
through to `FI.new_matcher`.

> Be warned that writing your own RegExes (rather than having FI compile them
> for you) is probably not such a good idea (although chances are you're better in Regexology than me).
> RegExes that work for FI must satisfy quite a number of requirements:
> they must have exactly five groups that match (1) what comes before the activator, (2) the portion of the
> string to be replaced, (3) an unparenthized name, if any, (4) a parenthized name, if any, and (5) the
> rest of the string; furthermore, they are required to match only the *last* occurrence of candidates
> for expansion, plus they must have an attribute `matcher.remover` which is used to purge the template
> of escaped active characters. See below for a railroad diagram of that beast.

### Routes as Keys

The previous examples all used 'simple' keys, but in fact, you can use routes (a.k.a. locators or paths) as
keys:

````coffeescript
template  = "i have a ${/deep/down/in/a/drawer}."
data      =
  deep:
    down:
      in:
        a:
          drawer:   'pen'
          cupboard: 'pot'
          box:      'pill'
FI.fill_in template, data # gives 'I have a pen.'
````

### Indexes as Keys and Multiple Interpolations

Let's show off two more (unrelated) features of CND Fillin: **(1)** A template can have more than a single
interpolation, and **(2)** it's possible to use a list as datasource and refer to items numerically (and,
given JavaScript's dynamic and object-oriented nature, it's also possible to mix indexed and named
references):

````coffeescript
template        = '$name was captain on $0, $1, and $2'
data            = [ 'NCC-1701', 'NCC-1701-A', 'NCC-1701-B', ]
data[ 'name' ]  = 'James T. Kirk'
FI.fill_in template, data` # gives 'James T. Kirk was captain on NCC-1701, NCC-1701-A, and NCC-1701-B'
````

Under the hood, Fillin will replace keys in the template by their values *starting from the right-hand side*
of the template; in other words, the order of replaced keys in the above example is `$2`, `$1`, `$0`, and
`$name`. This is important to keep in mind when it comes to the next feature up here, Nested Interpolations.

### Nested Interpolations

Nested interpolations occur when there is an interpolation inside of another interpolation. For example:

````coffeescript
template  = 'i have ${/amounts/$count} apples'
data      =
  'count':      'some'
  'amounts':
    'some':     '2'
    'more':     '3'

FI.fill_in_template template, data # gives 'i have 2 apples'
````
Above, we said that interpolations are performed from the right-end of the template; therefore, the first
replacement that happens here will replace the `$count` in `i have ${/amounts/$count} apples` with the
value of `data[ 'count' ]`, which is `some`. This replacement yields `i have ${/amounts/some} apples`, with
one replacement left; accordingly, the next step replaces `${/amounts/some}` with `data[ 'amounts' ][ 'some' ]`,
which is `2`.

The reason we proceed from right to left now becomes obvious: due to the way the overall syntax has been
conceived, a given interpolation may affect other interpolations to the *left* of it, but not to the *right*
of it.

### Chained (Recursive) Interpolations

Related to nested interpolations—which are interpolations that involve more than one replacement steps—are
chained (or recursive) interpolations. Consider the following setup:

````coffeescript
template  = 'i have $count apples'
data      =
  'count':    '${/amounts/some}'
  'amounts':
    'some':     '2'
    'more':     '3'

FI.fill_in_template template, data # gives 'i have 2 apples'
````
As can be seen, the template sports an unpretending `$count` expression. A closer look, however, reveals
that `data[ 'count' ]` resolves to `${/amounts/some}`, which in itself is an interpolation expression.

After CND Fillin has performed the first step, it will test another time whether the result is final or
expendable (if that reminds you of the way TeX works, it's not a coincidence), and if so, try and perform
the required substitution.

### Circular Interpolations

Programmers know about both the power and the pitfalls of recursive programs, and chained interpolations are
no exception: while they allow you to do significantly more abstract stuff, they also can easily go wrong.
Luckily, CND Fillin will check for symptoms of circularity and refuse to get stuck in an infinite loop.
You can test that behavior with a simple setup:

````coffeescript
template  = 'i have $some apples'
data      =
  'count':    '${/amounts/some}'
  'amounts':
    'some':     '$more'
    'more':     '$three'
    'three':    '$some'
````
Given these conditions, an attempt to `FI.fill_in_template template, data` will fail with a carefully
cafted exception:

````
test_cycle_detection
detected circular references in 'i have $some apples':
'i have $more apples'
'i have $three apples'
'i have $some apples'
````

## Using Fillin with containers

## Bonus Methods


````coffeescript
@walk_containers_crumbs_and_values = ( value, handler ) ->
@container_and_facet_from_locator = ( container, locator ) ->
@container_and_facet_from_crumbs = ( container, crumbs ) ->
@set = ( container, locator_or_crumbs, value ) ->
````

````coffeescript
````


## Implementation Details

### The RegEx

It took me quite a while to figure out the details of the RegEx that drives the interpolation step of CND
Fillin. Here it is in CoffeeScript HeRegEx syntax (with variable names to be interpolated, which is so...
meta):

````
///
    ( ^ | #{escaper}#{escaper} | [^#{escaper}] )
    (
      #{activator}
      (?:
        ( [^ #{forbidden} ]+ )
        |
        #{opener}
        (
          #{escaper}#{activator}
          |
          #{escaper}#{opener}
          |
          #{escaper}#{closer}
          |
          [^ #{activator}#{opener}#{closer} ]+ ) #{closer}
          )
      )
      ( (?: \\\$ | [^ #{activator} ] )* ) $
    ///
````
In its more common (and less readable) form, that expression becomes:
````regex
/(^|\\\\|[^\\])(\$(?:([^\$\{\}\\<>\(\)\|\*\+\.\,;:!"'%&\/=\?`´\#\s]+)|\{(\\\$|\\\{|\\\}|[^\$\{\}]+)\}))((?:\\\$|[^\$])*)$/
````
As i remarked above, there are a few backslashes that could be elided from the source, notably things like
escapes in character classes à la `[\+]`, which are really equivalent to `[+]` and so on. Notwithstanding,
it's still quite complex and hard to read. During debugging, i was surprised and glad to find
two websites that offer free RegEx-to-Diagram conversion, [debuggex](https://www.debuggex.com/) and
[regexper](http://www.regexper.com/#%28^|\\\\|[^\\]%29%28\%24%28%3F%3A%28[^\%24\{\}\\%3C%3E\%28\%29\|\*\%2B\.\%2C%3B%3A!%22%27%25%26\%2F%3D\%3F%60%C2%B4\%23\s]%2B%29|\{%28\\\%24|\\\{|\\\}|[^\%24\{\}]%2B%29\}%29%29%28%28%3F%3A\\\%24|[^\%24]%29*%29%24). This screenshot is taken from the latter website:

![](https://github.com/loveencounterflow/coffeenode-fillin/raw/master/art/Screenshot%202014-04-19%2002.33.48.png)

> **Note**
> I've shortened group 3 in the above image considerably to make it more readable. Also, the link to the
> [regexper site](http://www.regexper.com/#%28^|\\\\|[^\\]%29%28\%24%28%3F%3A%28[^\%24\{\}\\%3C%3E\%28\%29\|\*\%2B\.\%2C%3B%3A!%22%27%25%26\%2F%3D\%3F%60%C2%B4\%23\s]%2B%29|\{%28\\\%24|\\\{|\\\}|[^\%24\{\}]%2B%29\}%29%29%28%28%3F%3A\\\%24|[^\%24]%29*%29%24). should display the Railroad diagram (as [this link](http://www.regexper.com/#abc%2Bdef)), but doesn't. Copy and paste the above regular expression and hit the 'Display' button on that site.

The diagrams helped me to reason about the working of the RegEx and to weed out some bugs, so i can say they're valuable tools.

