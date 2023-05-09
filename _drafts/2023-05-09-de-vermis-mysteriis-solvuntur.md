---
layout: post
title: De Vermis Mysteriis — solvuntur
category: programming
---
I have previously [told of my adventures]({% post_url 2023-05-01-markdown-the-pits-of-madness %}) trying to enrich 
Jekyll's Markdown parsing abilities to allow for the wrapping of code samples in `<figure>` element. My first attempt 
built upon [Rouge]() and [Kramdown]() and was going well, until I hit a roadblock I couldn't figure out. Fortunately, 
a fresh eye was all it took to realize my mistakes and finish the work — as useless as it is now.

### The situation where I left it

I had decided to write a custom _formatter_ for Rouge. (In this library, the formatter is the component that generates 
HTML from a series of _tokens_, themselves extracted from the code sample to be highlighted.) The original formatter used 
by Kramdown is `Rouge::Formatters::HTMLLegacy`, but this formatter is more of a [facade](https://en.wikipedia.org/wiki/Facade_pattern) 
in front of 4 different formatters: `HTML`, `HTMLInline`, `HTMLTable` and `HTMLPygments`.

The custom formatter that I wrote inherited from `HTML`, ignoring the other 3 formatters:

<figure markdown="1">
```ruby
# frozen_string_literal: true

require "rouge"
module Rouge
  module Formatters
    class HTMLWithFigure < HTML
      def initialize(opts = {})
        @caption = opts[:caption]
      end
  
      def stream(tokens, &block)
        yield "<figure>"
        super
        yield "<figcaption>#{escape_special_html_chars @caption}</figcaption>" if @caption
        yield "</figure>"
      end
    end
  end
end
```
</figure>

Unfortunately, this formatter didn't render the HTML code I was expecting: the `<figure>` and `<figcaption>` elements 
were there, as was the highlighted code, but the later was not wrapped in `<pre>` and `<code>` elements.

Since this issue didn't happen with the `HTMLLegacy` formatter, I took a quick look at its code:

<figure markdown="1">
```ruby
module Rouge
  module Formatters
    class HTMLLegacy < Formatter
      def initialize(opts={})
        @formatter = opts[:inline_theme] ? HTMLInline.new(opts[:inline_theme])
                   : HTML.new


        @formatter = HTMLTable.new(@formatter, opts) if opts[:line_numbers]

        if opts.fetch(:wrap, true)
          @formatter = HTMLPygments.new(@formatter, opts.fetch(:css_class, 'codehilite'))
        end
      end
    end
  end
end
```
<figcaption>rouge/lib/rouge/formatters/html_legacy.rb (extract)</figcaption>
</figure>

My first mistake was to skip over the comments (not included above) and focus on the first line of the initializer, 
leading me to believe that, indeed, `HTML` would be the formatter used in normal cases. Looking at their names, 
`HTMLInline` was obviously for inline code samples, `HTMLTable` for the complex rendering with line numbers (as 
hinted at by the conditional `if opts[:line_numbers]`), while `HTMLPygments` probably had something to do with a 
legacy fallback for users of [Pygments](https://github.com/pygments/pygments.rb), the precursor to Rouge.

I then tried to add the missing elements to my custom formatter, even though I couldn't quite understand why they 
were missing in the first place. In retrospect, was my second mistake — I was trying to stumble my way to a solution 
without taking the time to figure out the problem first.

```ruby
# frozen_string_literal: true

require "rouge"
module Rouge
  module Formatters
    class HTMLWithFigure < HTML
      def initialize(opts = {})
        @caption = opts[:caption]
      end
  
      def stream(tokens, &block)
        yield "<figure>"
        yield %Q{<pre class="highlight"><code>#{super}</code></pre>}
        yield "<figcaption>#{escape_special_html_chars @caption}</figcaption>" if @caption
        yield "</figure>"
      end
    end
  end
end
```

Unsurprisingly, this didn't work. Yes, the code was preformatted thanks to the extra HTML elements, but so were simple 
code spans – those should _not_ be wrapped in a `<pre>` element, only a `<code>` one.

Faced with this problem, I made yet another mistake: I concluded that, since the `HTML` formatter was not adding the 
`<pre>` and `<code>` elements, they were under the responsibility of the Markdown converter (i.e. Kramdown), and not 
the syntax highlighter. So I went looking for their handling in Kramdown's code, a code spelunking session that led 
me nowhere; in part because Kramdown's source was only part of the actual code involved, especially when it comes to 
code blocks (Jekyll also loads up [kramwdown-parser-gfm](https://github.com/kramdown/parser-gfm)), but mostly because 
there is no such code in the first place!

### Solving the mystery

Lost in a dead end, I gave up and tried a different approach, with a different Markdown converter. But what had I missed 
then?

In fact, Kramdown does rely on Rouge to wrap the syntax-highlighted code in a `<code>` and, if needed, a `<pre>` 
elements. Outputting the options passed from Kramdown to the formatter gives us a clue:

```ruby
class HTMLWithFigure < HTML
  def initialize(opts = {})
    puts opts
    @caption = opts[:caption]
  end
end
```

```console
$ jekyll build -q
{:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :wrap=>false, :caption=>nil, :css_class=>"highlight"}
{:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :caption=>nil, :css_class=>"highlight"}
{:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :wrap=>false, :caption=>"lorem ipsum dolor", :css_class=>"highlight"}
```

Along the expected options — including the caption — is one named `:wrap`. You may remember having seen it in the `HTMLLegacy` 
initializer:

```ruby
def initialize(opts={})
  @formatter = opts[:inline_theme] ? HTMLInline.new(opts[:inline_theme]) : HTML.new
  # …
  if opts.fetch(:wrap, true)
    @formatter = HTMLPygments.new(@formatter, opts.fetch(:css_class, 'codehilite'))
  end
end
```

Could it be that this `HTMLPygments` was not just a legacy formatter for obscure backward-compatiblity edge cases? Let's 
have a look:

```ruby
module Rouge
  module Formatters
    class HTMLPygments < Formatter
      def initialize(inner, css_class='codehilite')
        @inner = inner
        @css_class = css_class
      end

      def stream(tokens, &b)
        yield %(<div class="highlight"><pre class="#{@css_class}"><code>)
        @inner.stream(tokens, &b)
        yield "</code></pre></div>"
      end
    end
  end
end
```

So there it is. In spite of its name, `HTMLPygments` is the real deal. (Interestingly, this piece of code shows a 
different pattern than subclassing `Rouge::Formatters::HTML`, as [the README suggests](); instead, `HTMLPygments` and `HTMLTable` are 
[decorators](https://en.wikipedia.org/wiki/Decorator_pattern) of the selected base formatter.)

### Searching for a proper solution

Let's recap. Kramdown's converter calls up Rouge to turn a code block into a collection of specifically-crafted `<span>` 
elements. Because the expected result can vary, Rouge offers several formatters to craft these elements, and optionnally 
wrap them in containing HTML elements such as `<pre>` and `<code>`. However, Kramdown's converter doesn't really care 
about chosing the right formatter; instead, it defers to a special one, `HTMLLegacy`, which does the selection for it, 
based on a few options, such as `:wrap`.

We want to use a custom formatter, but _only when expecting certain results_ (namely: the rendering of a code _block_). 
Ideally, we would like to keep Kramdown's normal behavior untouched, except for this addition of a `<figure>` element when 
rendering a code block. So what is Kramdown's normal behavior?

It is hidden behind quite a bit of indirection, but basically, all options defined in Kramdown's configuration for 
Rouge are passed to the `HTMLLegacy` initializer. Furthermore, different options can be specified for the `block` and 
`span` strategies. This is a lot of behavior to preserve.

-   We could move the facade logic of `HTMLLegacy` to the converter, and have it chose the right formater (including our 
    custom one) based on the options passed, while respecting the configuration syntax (i.e. the differents options for 
    `span` and `block`).
-   We could copy-paste this facade logic from `HTMLLegacy` to our custom formatter. That would leave it behind should 
    `HTMLLegacy` evolve in a future Rouge upgrade, but this eventuality seems unlikely.
-   We could re-open or extend `HTMLLegacy` so that an extra decorator was added to the formatter used when a caption 
    is present.

The last option would be the least intrusive, and also the most acrobatic, since it would involve monkey-patching Rouge. 
It could look like this:

```ruby
# frozen_string_literal: true

require "rouge", "cgi"
module Rouge
  module Formatters
    class HTMLWithFigure < Formatter
      def initialize(inner, caption)
        @inner, @caption = inner, caption
      end
      
      def stream(...)
        yield "<figure>"
        @inner.stream(...)
        yield "<figcaption>#{CGI.escape_html @caption}</figcaption>" if @caption
        yield "</figure>"
      end
    end
  end
end

Rouge::Formatters::HTMLLegacy.prepend Module.new {
  def initialize(opts={})
    super(opts)
    
    if caption = opts[:caption]
      @formatter = Rouge::Formatters::HTMLWithFigure.new(@formatter, caption)
    end
  end
}
```

I admit, I like this approach — but this is mostly my ego speaking. I don't get to use `Module#prepend` and anynomous module 
that often, and monkey-patching is a bit exhilarating. Plus, it is indeed the least intrusive approach – it leaves the 
inner workings of Rouge as they are, and the custom Kramdown syntax highlighter required is mostly a carbon copy of the 
original (including the use of `HTMLLegacy`). However, monkey-patching is always risky, and more importantly, it 
doesn't fix the underlying issue: `HTMLLegacy`, as its name implies, is a _legacy_ formatter, introduced for 
backward-compatibility with Rouge 1.x. It would be better if Kramdown wasn't using it in the first place.

(Note that Jekyll, for its `highlight` Liquid tag, does the right thing and instantiates the right formatter directly, 
instead of relying on this transitional prop.)

### The subtleties of software design

Instead, let's consider the other two options. The first one makes the Markdown converter responsible for adding the 
`<pre>` and `<code>` tags, while the second keeps this responsibility at the syntax highlighter level. As it happens, 
the Markdown specification is quite explicit as to how code blocks should be _converted_:

> Rather than forming normal paragraphs, the lines of a code block are interpreted literally. 
> Markdown wraps a code block in both <pre> and <code> tags.

So, relying on the syntax highlighter do the wrapping seems like a mistake in the first place. Put differently, when 
converting a Markdown code block to HTML, the code should always end up wrapped in a `<pre>` and `<code>` elements — and, 
in our case, said elements should themselves be wrapped in a `<figure>` —, even if there is no code highlighting being 
done.

In fact, this is exactly was Kramdown does:

<figure markdown="1">
```ruby
def convert_codeblock(el, indent)
  # …
  highlighted_code = highlight_code(el.value, el.options[:lang] || lang, :block, hl_opts)

  if highlighted_code
    add_syntax_highlighter_to_class_attr(attr, lang || hl_opts[:default_lang])
    "#{' ' * indent}<div#{html_attributes(attr)}>#{highlighted_code}#{' ' * indent}</div>\n"
  else
    result = escape_html(el.value)
    # …
    "#{' ' * indent}<pre#{html_attributes(attr)}>" \
      "<code#{html_attributes(code_attr)}>#{result}\n</code></pre>\n"
  end
end
```
<figcaption>kramdown/lib/kramdown/converter/html.rb (extract)</figcaption>
</figure>

If the code has been highlighted, it is wrapped in a `<div>`; _if not, it is wrapped in the mandatory <pre> and <code> elements._
  
I can only speculate as to why Kramdown behaves so — my guess is that Rouge initially introduced this over-zealous behavior, 
which Kramdown then had to take into account, and this adjustment was not removed even after Rouge fixed its rendering, 
probably because _other_ systems now depend on it.

In any case, we could either use a custon converter for Kramdown, or change its `Converter::HMTL` converter. Both 
options seem daunting.

Kramdown is very modular and configurable, but has no mechanism to allow the swapping of a converter for a given 
output – Kramdown relies on metaprogramming to require the relevant converter based on the name of the method 
called for the conversion, so that `#to_html` would use a `Converter::Html` converter, and so on. To use a different 
HTML converter, we would have to either pretend that it converter to a different format (and somehome have Jekyll 
call `#to_custom_html` instead…) or hijack Kramdown's converter-fetch logic. Both options are way more mad-scientisty 
than monkey-patching Rouge's `HTMLLegacy` formatter.

### The intricacy of open source

If relying on the syntax highlight to add the `<pre>` and `<code>`elements is indeed a mistake, why not contribute to 
Kramdown and submit a fix? 
