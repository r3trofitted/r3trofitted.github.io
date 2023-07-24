---
layout: post
title: De Vermis Mysteriis — solvuntur
category: programming
date: 2023-06-24 21:42 +0200
---
I have previously [told of my adventures]({% post_url 2023-05-01-markdown-the-pits-of-madness %}) trying to enrich 
Jekyll's Markdown parsing abilities to allow for the wrapping of code samples in `<figure>` element. My first attempt 
built upon [Rouge](https://github.com/rouge-ruby/rouge) and [Kramdown](https://kramdown.gettalong.org) and was going well, 
until I hit a roadblock I couldn't figure out. Fortunately, a fresh eye was all it took to realise my mistakes and 
finish the work — as useless as it may be now.

### The situation where I left it

When Jekyll publishes a post, it calls upon Kramdown to _convert_ the Markdown to HTML, and Kramdown in turn calls upon 
Rouge to _highlight_ (i.e. replace with complex HTML) the code samples it encounters. Rouge offers different _formatters_ 
to be used, depending on the kind of syntax highlighting needed. 

The original formatter used by Kramdown is `Rouge::Formatters::HTMLLegacy`, but actually it is more of a 
[facade](https://en.wikipedia.org/wiki/Facade_pattern) in front of four different formatters: `HTML`, `HTMLInline`, 
`HTMLTable` and `HTMLPygments`.

To wrap the Rouge-generated HTML in `<figure>` elements, I had decided to write a custom _formatter_ for Rouge. My 
formatter inherited from `HTML`, ignoring the other three:

  ```ruby
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

Unfortunately, this formatter didn't render the HTML code I was expecting: the `<figure>` and `<figcaption>` elements 
were there, as was the highlighted code, but the later was not wrapped in `<pre>` and `<code>` elements, as it should 
have.

This issue didn't happen with the `HTMLLegacy` formatter, so I took a quick look at its code:

  ```ruby?caption=rouge/lib/rouge/formatters/html_legacy.rb
  module Rouge
    module Formatters
      class HTMLLegacy < Formatter
        # @option opts [String] :css_class ('highlight')
        # @option opts [true/false] :line_numbers (false)
        # @option opts [Rouge::CSSTheme] :inline_theme (nil)
        # @option opts [true/false] :wrap (true)
        #
        # Initialize with options.
        #
        # If `:inline_theme` is given, then instead of rendering the
        # tokens as <span> tags with CSS classes, the styles according to
        # the given theme will be inlined in "style" attributes.  This is
        # useful for formats in which stylesheets are not available.
        #
        # Content will be wrapped in a tag (`div` if tableized, `pre` if
        # not) with the given `:css_class` unless `:wrap` is set to `false`.
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

My first mistake was to skip over the comments (rookie mistake) and focus on the first line of the initializer, 
leading me to believe that, indeed, `HTML` would be the formatter used in normal cases. Looking at their names, 
`HTMLInline` was obviously for inline code samples, `HTMLTable` for the complex rendering with line numbers (as 
hinted at by the conditional `if opts[:line_numbers]`), while `HTMLPygments` probably had something to do with a 
legacy fallback for users of [Pygments](https://github.com/pygments/pygments.rb), the precursor to Rouge.

I then tried to add the missing elements to my custom formatter, even though I couldn't quite understand why they 
were missing in the first place. In retrospect, was my second mistake — I was trying to stumble my way to a solution 
without taking the time to figure out the problem first.

  ```ruby
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
code spans – and those should _not_ be wrapped in a `<pre>` element, only a `<code>` one.

Faced with this problem, I made yet a third mistake: I concluded that, since the `HTML` formatter was not adding the 
`<pre>` and `<code>` elements, they were under the responsibility of the Markdown converter (i.e. Kramdown), and not 
the syntax highlighter. So I went looking for their handling in Kramdown's code, a code spelunking session that led 
me nowhere; in part because Kramdown's source was only part of the actual code involved, especially when it comes to 
code blocks (Jekyll also loads up [kramwdown-parser-gfm](https://github.com/kramdown/parser-gfm)), but mostly because 
there is no such code in the first place!

### Solving the mystery

Lost in a dead end, I gave up and tried a different approach, with a different Markdown converter. But what had I missed 
back then?

Contrary to my initial, half-backed conclusion, Kramdown _does_ rely on Rouge to wrap the syntax-highlighted code in a 
`<code>` and, if needed, a `<pre>` elements. Outputting the options passed from Kramdown to the formatter gave me a clue:

  ```ruby
  class HTMLWithFigure < HTML
    def initialize(opts = {})
      puts opts
      @caption = opts[:caption]
    end
  end
  ```

  ```console?prompt=𝄢
  𝄢 jekyll build -q
  {:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :wrap=>false, :caption=>nil, :css_class=>"highlight"}
  {:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :caption=>nil, :css_class=>"highlight"}
  {:formatter=>"HTMLWithFigure", :default_lang=>"plaintext", :guess_lang=>true, :wrap=>false, :caption=>"lorem ipsum dolor", :css_class=>"highlight"}
  ```

Along the expected options — including the caption — is one named `:wrap`. I remembered having seen it in the `HTMLLegacy` 
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

Could it be that this `HTMLPygments` was not just a legacy formatter for obscure backward-compatiblity edge cases? I had 
a look:

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

So there it was. In spite of its name, `HTMLPygments` is the real deal. (Interestingly, this piece of code shows a 
different pattern than subclassing `Rouge::Formatters::HTML`, as [the README suggests](https://github.com/rouge-ruby/rouge#writing-your-own-html-formatter); 
instead, `HTMLPygments` is a [decorator](https://en.wikipedia.org/wiki/Decorator_pattern) of the selected base formatter.)

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
Rouge are passed down to the `HTMLLegacy` initializer. Furthermore, these options can be specified twice: once for the 
rendering of a code `block` and once for the rendering of a code `span`. This is a lot of behavior to preserve.

-   We could move the facade logic of `HTMLLegacy` to the converter, and have it chose the right formater (including our 
    custom one) based on the options passed, while respecting the configuration syntax (i.e. the differents options for 
    `span` and `block`).
-   We could copy-paste this facade logic from `HTMLLegacy` to our custom formatter. That would leave it behind should 
    `HTMLLegacy` evolve in a future Rouge upgrade, but this eventuality seems unlikely.
-   We could re-open or extend `HTMLLegacy` so that an extra decorator was added to the formatter used when a caption 
    is present (or, alternatively, every time a _block_ is renderer).

The last option would be the least intrusive, and also the most acrobatic, since it would involve monkey-patching Rouge. 
It could look like this:

  ```ruby
  require "rouge"
  require "cgi"
  
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
converting a Markdown code block to HTML, the code should always end up wrapped in a `<pre>` and `<code>` elements, 
even if there is no code highlighting being done.

In fact, this is exactly was Kramdown does _when there is no highlighting_:

  ```ruby?caption=kramdown/lib/kramdown/converter/html.rb
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

If the code has been highlighted, it is wrapped in a `<div>`; if not, it is wrapped in the mandatory `<pre>` and `<code>` 
elements.
  
I can only speculate as to why Kramdown behaves so — my guess is that Rouge initially took upon itself to do the wrapping 
in `<pre>` and `<code>` elements, and Kramdown then had to take this over-zealous behaviour into account, and stay like 
this even after Rouge fixed its rendering, probably because other systems now depend on it.

In any case, we could either use a custom converter for Kramdown (one that would _not_ rely on Rouge for the wrapping), 
or change the way its `Converter::HMTL` converter works. Both options seem daunting.

Kramdown is very modular and configurable, but has no mechanism to allow the swapping of converters – Kramdown relies 
on metaprogramming to require the relevant converter based on the name of the method called for the conversion, so that 
`#to_html` instantiates a `Converter::Html` converter, and so on. To use a different HTML converter, we would have to 
either pretend that it converts to a different format (and somehome have Jekyll call `#to_custom_html` instead…) or 
hijack Kramdown's converter-instantiating logic. Both options are way more intrusive than monkey-patching Rouge's 
`HTMLLegacy` formatter.

### The intricacy of open source

But if relying on the syntax highlight to add the `<pre>` and `<code>`elements is a mistake in the first place, why not 
contribute to Kramdown and submit a fix? In short: because I'm not too fond of Kramdown as a project.

I love contributing to open source – in fact, I consider that is it a privilege to be able to do so, and a duty to 
actually contribute if you can. However, I also consider that any contribution, even the smallest, is a form of commitment 
to the project.

Open source maintainers deserve respect; they (usually) welcome contributions, but in my opinion, the least one can 
do when contributing is to have regard for the the maintainers' leadership, opinions, choices, and the overall direction 
they want to give their project. In other words: when contributing to Rome, do as the Roman senators do.

I may be overly cautious, but I'm not too fond of opening a PR without being confident that it would be useful to the 
project, and not only to me, and that it would be in line with whatever the project maintainers have in mind. In other 
words, projects have a vibe, and I want to be in sync with it.

This probably sounds like a lot of overthinking, or possibly an excuse not to contribute, but it's not. It's basically 
a complicated way to say that I don't want to contribute to projects whose philosophy or leadership I don't feel good 
about, and that is exactly the case here.

I've complained about the complexity of Kramdown's code base (and yes, I know how easy it is to criticise), but in itself 
this would not be enough to keep me from opening a small PR. However, to get a feel of the project, I took a look at 
the other PRs and the conversations around them, and didn't really like what I saw. No major red flag, just a tone 
not to my liking.

And so, since neither the technical nor human aspects of this project vibe with me, I'd rather not get involved. It's 
as simple as that.

### Done beats perfect

I enjoy pursuing the best solution to a given problem – within reason. From my perspective – and I may well be wrong! – 
the _best_ solution would be to move the responsibility of wrapping code blocks in `<pre>` and `<code>` elements 
from the syntax highligher (Rouge) to the converter (Kramdown), and while we're at it to _also_ make the converter 
be responsible for adding the `<figure>` elements around the converted code block. However, this would require working 
on Kramdown, which is something I don't want to do.

And so, the second-best approach is the one I'll go with – keep the wrapping of the highlighted code in `<figure>`, 
`<pre>` and `<code>` elements under the responsibility of Rouge, implemented through a small monkey-patch. It may not 
be ideal or perfect, but it will work, for a reasonable cost.

