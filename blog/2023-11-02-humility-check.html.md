---
layout: post
title: Humility check
date: 2023-11-05 21:12 +0100
categories: programming
...

I consider myself a solid developer, especially with Ruby and Rails. After all, I've been writing code and 
building systems for more than twenty years now. However, I'm weary of becoming complacent, or even worse, 
overestimating abilities that would be declining without me realizing it. That is why I keep practicing and 
always welcome a challenge or an assessment.

And such a test is exactly what I took a couple of days ago, partially to find new consulting opportunities, 
but mostly to see how I measured. Well, let's just say that it was a learning, and humbling, experience.

## The test

Frankly, it was a good test. Technical tests are not that easy to write. They must be realistic, and yet not require 
knowledge of a specific business domain. They should cover high- and low-level stuff, and yet be focused. They should 
look like actual application code, and yet keep the boilerplate to a minimum. It's a tricky balance, and I found this 
test well-balanced.

Sign of the times, the test's setup was “Rails as a back-end for a REST API”. So, very realistic, but also a bit 
sad, since it's basically misusing my favorite framework. Still, the use case was very clear, coherent, and well laid 
out. The test came with a skeleton app and some integration specs; the goal was mostly to fill in the blanks in the code 
to make the specs pass.

I would love to complain about the non-RESTful nature of the app's resources, its choice of RSpec over Minitest, or 
the insistence on using some kind of service layer, and blame my poor performance on these, but that would be dishonest. 
For better or worse, this structure is extremely common in 2023, and as I've said, good tests are realistic.[^1]

## My performance

I failed miserably. Or rather: I eventually came up with a solution that I find pretty good, but it took me way longer 
than the allocated time. So what did I do wrong?

First of all, what I did _not_ do wrong: I didn't waste time setting up my environment, and I didn't waste time 
looking stuff up online, basically filling in holes in my knowledge with Stack Overflow snippets. I mention these things 
because they are among the obvious red flags that I look for when I am the one doing the evaluation. At least my basics 
were covered. So what took me so long?

First of all, I **didn't study the code enough before diving in**. Now that I think about it, this is the kind of 
common advice that I was given when I was a student – or that I could give my son now. Don't rush, and read carefully 
the wording of the problem. And the code you start with is part of this wording! But because I didn't do that, I 
stumbled upon stupid things that broke my flow – things like not looking at the `schema.rb` file to see that a given 
attribute that is passed as a string is actually stored as an integer, and therefore the model should declare an `enum`. 
To be honest, I cursed every time I lost 20 seconds on what felt like unfair traps, but in retrospect, these are part of 
the game, and something you should always do in real life anyway. So, this recurring loss of footing is on me.

Secondly, I couldn't help myself **coding with my ego**, and obsessing too much and too early on _making it right_, 
instead of ensuring that I had _made it work_ everywhere first. It's a weakness I know well, now, and yet once again 
it was stronger than me. This was especially true on the algorithmic part of the test. I'm not very good when it comes to 
core CS stuff, and I felt an extra impulse to **show off** and try to do something clever, which took me a very 
long time to come up with, instead of brute-forcing my way through the problem. Now, in my defense, one of my motivations 
for taking this test was to have fun and try new things, and I had never had a good reason to use `Array#slice_when` 
before. I did have fun, and I did learn new things, but it was unwise and it is the main reason why I lost so much time.

But, in truth, I could still have pulled it off in time if I had been more familiar with the expected architecture. 
The app was technically using Rails, but not following the Rails Ways™, and the seemingly incoherent requirements that 
ensued from this architecture **got me confused**. It became a puzzle I could not figure out – I got the objects 
that the solution wanted, and the responsibilities they had to have, but couldn't find a way to dispatch the latter 
among the former as the test wanted me to. Or not in a way that made sense to me, anyway. I eventually came up with 
something that worked, but it didn't feel _right_. And yet, coming up with it took me a very long time – in fact, I 
had to start again from scratch, doing things “my way”, and then backtracking to something that would satisfy the 
requirements of the test.

## What was revealed?

This mismatch between what I think was expected of the candidates, and the way I usually build a Rails app, gives 
me pause. I certainly don't want to put my failing on the test itself or look for excuses. I made mistakes because 
of my own shortcomings, there's no denying that. And yet, if indeed I reversed-engineered properly the test (which is 
a big _if_), I wonder if I should make a big deal out of this poor performance. I couldn't come up with a solution 
that I would advise against anyway, in a classic case of misusing a framework that I (supposedly) know how to use well. 
Should I stick to my guns, ignore these perversions, and feel fine about my own lack of awareness, or should I step 
down from my pedestal, go with the flow, and become familiar with these misguided but common approaches to “a Rails 
backend”?

---

[^1]: Still, the more I thought about this test, the more issues I had with it, as an example of poor practices. I'll 
      certainly come back to this in future posts.
