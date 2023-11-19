# On this Jekyll site, I want GFM fencesd code blocks to be rendered within <figure> elements, 
# with an optional <figcaption> child element, said caption being passed in the fenced code's 
# info string. Besides, I want the caption to be parsed as Markdown text itself (so that I could 
# include a link, for example.)
#
# To do so, a custom Rouge formatter is necessary to wrap the highlighted code in a <figure> 
# element; the native Rouge HTMLLegacy formatter (which Kramdown uses) must be patched to 
# use the custom formatter; a custom Kramdown converter must be used to extract the info string 
# and extract the caption; finally, a custom Kramdown parser must be used to parse the caption
# as "inline" Markdown.

require "kramdown"
require "rouge"
require "cgi"
module Rouge
  module Formatters
    # Decorates a formatter to wrap its result in a <figure> element, with an optional coption 
    # in a <figcaption> child element.
    class HTMLWithFigure < Formatter
      def initialize(inner, caption)
        @inner, @caption = inner, caption
      end
    
      def stream(...)
        yield "<figure>"
        @inner.stream(...)
        yield "<figcaption>#{@caption}</figcaption>" if @caption
        yield "</figure>"
      end
    end
  end
end
# Monkey-patch the HTMLLegacy formatter to decorate the formatter with HTMLWithFigure if a block is hightlighted
Rouge::Formatters::HTMLLegacy.prepend Module.new {
  def initialize(opts={})
    super(opts)
  
    if opts.fetch(:wrap, true)
      @formatter = Rouge::Formatters::HTMLWithFigure.new(@formatter, opts[:caption])
    end
  end
}

require "kramdown/converter/syntax_highlighter/rouge"
module RougeWithCaption
  def self.call(converter, text, lang, type, call_opts)
    opts = Kramdown::Converter::SyntaxHighlighter::Rouge.options(converter, type)

    # extracting and parsing the :caption option from the "lang" (actually the fence string) for the formatter
    opts[:caption] = /caption=([^&]*)/.match(lang) do |md|
      Kramdown::Document.new(md.captures.first, input: 'FigcaptionKramdown').to_html
    end
  
    call_opts[:default_lang] = opts[:default_lang]
    return nil unless lang || opts[:default_lang] || opts[:guess_lang]
  
    lexer = ::Rouge::Lexer.find_fancy(lang || opts[:default_lang], text)
    return nil if opts[:disable] || !lexer || (lexer.tag == "plaintext" && !opts[:guess_lang])
  
    opts[:css_class] ||= 'highlight' # For backward compatibility when using Rouge 2.0
    formatter = Kramdown::Converter::SyntaxHighlighter::Rouge.formatter_class(opts).new(opts)
    formatter.format(lexer.lex(text))
  end
end
Kramdown::Converter.add_syntax_highlighter :rouge_with_caption, RougeWithCaption

# https://stackoverflow.com/a/30468100
require "kramdown/parser/kramdown"
class Kramdown::Parser::FigcaptionKramdown < Kramdown::Parser::Kramdown
  def initialize(source, options)
    super
    @block_parsers = []
  end
end
