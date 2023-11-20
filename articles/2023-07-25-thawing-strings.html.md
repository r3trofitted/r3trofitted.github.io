---
layout: post
title: Thawing strings
date: 2023-07-25 10:52 +0200
lede: "It's 2023 and we're using Ruby 3.2, do we really need <code>#frozen-string-literal</code>?"
...

As a staunch atheist, I reject all cults (except maybe for Ian Astbury's). And yet, there's one I'm always wary of, for 
fear of inadvertently falling into: the _cargo_ cult.

Cargo cult programming is one of the worst things that can happen to a software person. It's the evil twin of experience, 
when what I've learned turns against you instead of helping you. Having strong opinions and hardcoded knowledge is fine, 
until said opinions and knowledge turn out to be false, or even worse, out-of-date.

Case in point: the `frozen-string-literal` feature in Ruby.

Back in 2015, I learned that Ruby 3 would make `String` objects _frozen_ by default, and as a transitional measure, 
a new magic comment had been introduced: `#frozen_string_literal: true`. Add it to your Ruby 2.3 file, and its 
(non-interpolated) strings would be frozen, as they should eventually be in Ruby 3.

As a diligent rubyist trying to stay on the edge, I started adding this magic comment scrupulously at the top of all my 
files, even though I really didn't like it (because it's noisy). Then Ruby 3 was relesead like a Christmas present 
(litteraly), and I thought that I could stop using this magic comment.

… Except that everybody was keeping it! Why was that? I was quick to blame Rubocop, my nemesis, but honestly I was more 
confused than pissed. Still, I had other things to care about, so I forgot about this – and kept using the magic comment, 
even in my own pet projects.

## Best practices as smell tests

However, there is something smelly in ubiquitous “best practices”, and now that I'm back to coding (and coding for fun!), 
my nose started twitching again.

I trust my tools of choice, and the people who make them. Which means that I trust Ruby to be at its best by default. 
Magic comments are file-specific configuration options; by definition, they are an exception to the defaults. So, if a 
an option like `frozen-string-literal` is that important, why isn't it on by default?

And, by the way, wasn't it supposed to be the case in Ruby 3 in the first place?

## Catching up with the language

So I went back to the [Ruby bug tracker](https://bugs.ruby-lang.org/projects/ruby-master)[^1] and read 
[this](https://bugs.ruby-lang.org/issues/11473#note-53):

> * Status changed from Assigned to Closed
> 
> I consider this for years. I REALLY like the idea but I am sure introducing this could cause HUGE compatibility issue, 
> even bigger than Ruby 1.9. So I officially abandon making frozen-string-literals default (for Ruby3).
> 
> This does not mean we are going to remove the frozen-string-literal feature that can be specified by magic comments.
> 
> Matz.

I had somehow missed the announcement that Ruby 3 had dropped the idea of freezing the strings by default! And for my 
least favorite reason in computer science: retrocompatibility (the weight that drags progress down). So there was 
a reason to systematically use this ugly magic comment, after all.

## Weighting tradeoffs

Or was it? I can understand that Matz would prefer avoiding compatibility issues over performance, but performance 
was Ruby 3's major goal with “Ruby 3x3”. So, how much of a compromise was dropping the freeze-strings-by-default?

I have no idea, and no benchmark, but I stumbled upon [this interesting thread](https://github.com/standardrb/standard/pull/181) 
on Standard's repo. Basically, Justin Sears was pushing back against adding a linter rule to enforce the presence 
of this magic comment (as he should, because he's a smart and tasteful man), and asking for reasons do have it. And 
no other than [Tenderlove](http://tenderlovemaking.com) came to [defend this practice](https://github.com/standardrb/standard/pull/181#issuecomment-635722698):

> I don’t have any good benchmarks, but I can tell you from experience that they really helped us at GitHub.
> 
> […]
> 
> btw I used to be in the “I’ve never seen frozen stings help anything” camp until I actually saw them help.

So, yeah, the `frozen-string-litteral` seems to have a positive effect, which would make the ridiculousness of 
adding the same magic comment to every file worth it… Except that **I don't work on GitHub**.

This is basically the conclusion that closed the PR: freezing the strings might be useful in some situations, but 
this is the exception, not the rule. So Searls doesn't want it in Standard, and more importantly, I don't want it 
in my code base.

## Back from the edge

So, I went from getting into a certain habit in preparation for a change that didn't come, to keeping this habit for no 
good reason, even as had a (correct, if accidentally) hunch that I shouldn't. The good thing is that now, I know 
what to do most of the time, when to do otherwise, and more importantly, why. I'm back to following anchored reason, 
and not blind faith.

---

  [^1]: Every time I go there, I feel an unconfortable mix of nostalgia and discomfort because it's powered by Redmine…
