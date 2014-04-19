

- [CoffeeNode Fillin](#coffeenode-fillin)
- [Using Fillin with Strings](#using-fillin-with-strings)
	- [Basic Usage](#basic-usage)
	- [Routes as Keys](#routes-as-keys)
	- [Indexes as Keys and Multiple Interpolations](#indexes-as-keys-and-multiple-interpolations)
	- [Nested Interpolations](#nested-interpolations)
	- [Chained (Recursive) Interpolations](#chained-recursive-interpolations)
	- [Circular Interpolations](#circular-interpolations)
- [Using Fillin with containers](#using-fillin-with-containers)
	- [Simple Example](#simple-example)
	- [Advanced Example](#advanced-example)
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

Escaping has just become a tad simpler, as `!` is not a special character in JavaScript strings, so you can
now write `!+name` instead of `\\$name`. Of course, whether using these particular characters is a good idea
will depend a lot on your data.

Finally, to make working with custom syntaxes even simpler, you can use
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
expandable (if that reminds you of the way TeX works, it's not a coincidence), and if so, try and perform
the required substitution. This process is repeated over and over, until all expressions have been resolved.


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
crafted exception:

````
detected circular references in 'i have $count apples':
'i have $count apples'
'i have $some apples'
'i have $more apples'
'i have $three apples'
'i have $some apples'
````
The reason we go to these lengths in reporting the source of the error is that can be quite easy
to commit a recursive blunder but much harder to figure out the exact chain of events—in this case, the
process looks like this:

![](https://github.com/loveencounterflow/coffeenode-fillin/raw/master/art/Screen%20Shot%202014-04-19%20at%2015.10.19.png)
> thx to [regexper](http://www.regexper.com) for the graphics

as becomes obvious from the replacements listing.

## Using Fillin with containers

The primary use case for CND Fillin is not so much single string interpolation or, beware, HTML templating,
but, rather, options compilation.

> HTML templating (which has a long pedigree that includes stuff like PHP and JSP) has recently (again) come
> under fire. I have no intents to make CND Fillin do more than simple, purely declarative stuff—there will
> never be conditions (well, maybe except for an existential operator), branching, or looping. It feels
> wrong to me to write yet another language just for templating when we have much more powerful idioms with
> well-documented properties (personally, i prefer to build my HTML pages in
> [Teacup](https://github.com/goodeggs/teacup), which is just CoffeeScript).

### Simple Example

We've already seen how `data` objects are used to act as a data source for a template string. But TND Fillin
does more if you let it—you can have it fill out values inside a collection (lists or Plain Old
Dictionaries):

````coffeescript
template  = [ '$protocol', '://', '$host', ':', '$port', ]
# or, equivalently:
template  = [ '${/protocol}', '://', '${/host}', ':', '${/port}', ]
data      =
  'protocol':   'http'
  'host':       'example.com'
  'port':       '8080'
  FI.fill_in_container template, data             # gives [ 'http', '://', 'example.com', ':', '8080' ]
  ( FI.fill_in_container template, data ).join '' # gives 'http://example.com:8080'
````

In this example, we use one 'target' or 'template' object (which happens to be a list) and another object
used as data source to supply a number of (configurable) named values to build a URL string. Imagine
you did `data = require '../options'` and you see where this goes (of course, using a string as template
would've worked just as well in this case—it's just an example).

You can also use the *same* object as both the target *and* the source:

````coffeescript
data =
  translations:
    'dutch':
      'full':         [ 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag', ]
      'abbreviated':  [ 'ma', 'di', 'wo', 'do', 'vr', 'za', 'zo', ]
    'english':
      'full':         [ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', ]
      'abbreviated':  [ 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su', ]
  language:   'dutch'
  days:       '${/translations/$language/abbreviated}'
  day:        '${/translations/$language/full/3}'
````
With this setup, `FI.fill_in_container data` will give you

````json
{
  "translations": {
    "dutch": {
      "full": [
        "maandag",
        "dinsdag",
        ...
      ],
      "abbreviated": [
        "ma",
        "di",
        ...
      ]
    },
    "english": {
      "full": [
        "Monday",
        "Tuesday",
        ...
      ],
      "abbreviated": [
        "Mo",
        "Tu",
        ...
      ]
    }
  },
  "language": "dutch",
  "days": "[ 'ma', 'di', 'wo', 'do', 'vr', 'za', 'zo' ]",
  "day": "donderdag"
}
````

<strike>Notice that the result of `${/translations/$language/abbreviated}` is probably *not* what you wanted—it's
the *serialization* of that value, *not* the value itself. I consider this a feature as far as some use
cases are considered (putting the representation of a complex value inside a string) and as a bug as far as
other use cases go (where you want to copy entire subtrees to a new location). I've yet to decide how to
resolve this issue; one way would be to check whether the template string that is responsible for the
replacement has any material around it—in other words, `'$foo'` will have to be replaced by the *value* of
`data[ 'foo' ]`, but `'xx $foo xx'` will have to be replaced by the *representation* of that same value.</strike>

### Advanced Example

Just as with string expansion, you can also apply multiple expansion to object values. For example:

````coffeescript
data =
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
FI.fill_in data
````
will make `data[ 'deep' ][ 'down' ][ 'in' ][ 'a' ][ 'box' ] == 'a pill'`. Again, circular substitutions
and substitutions where a named target can not be found will result in errors.

<!--
## Bonus Methods


````coffeescript
@walk_containers_crumbs_and_values = ( value, handler ) ->
@container_and_facet_from_locator = ( container, locator ) ->
@container_and_facet_from_crumbs = ( container, crumbs ) ->
@set = ( container, locator_or_crumbs, value ) ->
````
 -->

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

