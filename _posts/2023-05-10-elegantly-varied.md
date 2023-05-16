---
layout: post
title: Elegantly varied
date: 2023-05-10 20:27 +0200
category: programming
---

The excellent [Noel Rappin](https://noelrappin.com) led a great experiment on Mastodan yesterday. He asked for the “most elegant way” to do a 
trivial array manipulation in Ruby:

> What’s your most elegant Ruby code that does this:
> 
> * takes an array of strings and a target string
> * if the target string is not in the array, return the array
> * if the target string is in the array, return the array with the target string moved from its position to the end of the array.

I love this question because it's very simple, and yet leaves room for interpretation. What should 
the code do if the target string is found more than once? What if the target in the dreaded `nil`? 
And what does “elegant” mean in the first place? Thanks of this relative vagueness, respondants 
can express their personal taste and creativity, instead of focusing on algorithmic efficiency 
(or start playing [code golf](https://code.golf)).

Noel has [gathered the results](https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8) 
and they show an interesting diversity of styles. Some are very naive, but also easy to understand, 
even without any knowledge of Ruby (I believe). Others are much more cryptic.

Overall, if I was looking for a production-safe solution, I'd go with option 4:

<figure markdown="1">
```ruby
def move_target_to_end(arr, target)
  result = arr.dup
  result.delete(target) ? result.push(target) : result
end
```
<figcaption><a href="https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8#file-ruby_versions-L52">https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8</a></figcaption>
</figure>

It is short and legible, doesn't mutate the array (a nice courtesy), and is a bit more sophisticated than non-idiomatic 
techniques that would rely on `#include?` or `#index`.

However, I have a certain fondness for more showy solutions, like option 8:

<figure markdown="1">
```ruby
def move_target_to_end(arr, target)
  arr.tap { arr.delete(target) && arr.push(target }
end
```
<figcaption><a href="https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8#file-ruby_versions-L77">https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8</a></figcaption>
</figure>

I've seen `#tap` being (in my opinion) misused, but here, combined with the `&&` operator, it is very clever. I love 
this, even if it's basically hiding a conditional (because _shortening_ it with a ternary operator is not enough!)

Do note that _complicated_ is not necessarily _clever_. I find the option 6, for example, hard to read and yet 
pretty naive in its approach – the simplicity of the algorithm is just hidden behind a ternary operator and nested 
method calls:

<figure markdown="1">
```ruby
def move_target_to_end(arr, target)
  arr.include?(target) ? arr.push(arr.delete(target)) : arr
end
```
<figcaption><a href="https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8#file-ruby_versions-L65">https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8</a></figcaption>
</figure>

Overall, my favorite solution is the one submitted by [Henrik Nyh](https://thepugautomatic.com):

<figure markdown="1">
```ruby
def move_target_to_end(arr, target)
  arr.partition { _1 != t }.flatten
end
```
<figcaption><a href="https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8#file-ruby_versions-L97">https://gist.github.com/noelrappin/a046996a3e9e5d5034533f5a37b349b8</a></figcaption>
</figure>

It is everything I love in Ruby: a bit weird and very smart at the same time (because it repurposes a little-used method, 
`#partition`), concise, and yet legible. It makes you scratch your head, but only for a few seconds, and then you admire 
its elegance. Awesome!
