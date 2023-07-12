---
layout: no_milk_no_sugar
title: 'No milk, no sugar #5'
date: 2023-07-12 16:23 +0200
categories: programming
---

## [minitest-focus](https://github.com/minitest/minitest-focus)

One of the only things I miss from RSpec when using Minitest is the [`:focus`](http://rspec.info/features/3-12/rspec-core/filtering/inclusion-filters) 
metadata. You get used to filtering tests through command-line arguments, but it's still a bit cumbersome, and lacks 
the elegance you can expect from such a Ruby-like tool as Minitest. So, of course there has to be a solution, and I 
was simply unaware of it. But, more importantly, `minitest-focus` is a example of clean, smart-but-not-too-smart 
code. Just look at the way the “indirect approach” is implemented in the [main file](https://github.com/minitest/minitest-focus/blob/02cbbc41519c04bf46b1bf14042e2a0ceddb7763/lib/minitest/focus.rb). 
It's chef's-kiss-emoji-level.

## [The AI help button is very good but it links to a feature that should not exist](https://github.com/mdn/yari/issues/9230)

So, it looks like [MDN Web Docs](https://developer.mozilla.org/en-US/) is trying out leveraging LLMs to enrich what is 
probably the best documentation site on the web. (And which will hopefully keep being so.) Well, color me surprised, 
but it doesn't seem to work out so well. In any case, this issue is a really fun and interesting read – and, I think, a 
great way to raise and articulate concerns – and to circumvent overly zealous (or thickheaded) moderators.

## [Garbage Collection in Ruby](https://blog.peterzhu.ca/notes-on-ruby-gc/)

The internals of Ruby used to scare me – the only things I know about C, I learned by 
[falling asleep to some German ASMR YouTuber](https://youtube.com/playlist?list=PLPt8EM4KxGEVdozTFQ_taOdS6OFlNU7ki). Not 
so much nowadays, and this kind of blog post is exactly the reason why. It's well written, friendly, and makes complex 
topics seem simple.

## [a simple hash table in C](https://theleo.zone/posts/hashmap-in-c/)

Another nice article about complicated things, explained clearly. In a website with great “early web” vibes <3.
