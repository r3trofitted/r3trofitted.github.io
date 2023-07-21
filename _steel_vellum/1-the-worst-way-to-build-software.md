---
layout: post
title: "The worst way to build software"
date: 2023-04-15 14:45 +0200
categories: programming
---
Sometimes, I just want to code something – anything. Like many (if not all) developpers, I have a 
virtual drawer full of half-finished apps, repos left untouched for years whose last commit message 
is an unhelpful "WIP", and domain names still parked long after their initial pun stopped making sense. 
Today, I'd like to pick one of those unfinished projects and revisit it.

Back around 2016, I started a Rails app cryptically named _Ankran Nembo_; it was supposedly 
a character creation app for the D&D campaign I had started, but more importantly, it was a toy 
project to try out the brand new version of Rails at the time – Rails 5.0. I have good memories of working 
on this application and experimenting with different techniques, but I don't feel like salvaging 
any of it (except for one thing). So instead, let's start over from scratch, but in the same 
spirit.

However, there is one problem – if we were to build _an application_, we wouldn't be able to 
start coding _right now_. Doing things properly would mean thinking about user interactions, 
UI, and probably spend some time in HTML+CSS land first. And I want to code _now_, not later! So, 
instead of a full application, let's focus on coding some kind of character creation engine – 
a library with which to build a full app later.

**A word of warning!** In real life, I would strongly advise against such an approach. Building the 
things you think you'll need before even knowing what it is you actually want to do is a sure way 
to fail – or, at best, to build a working but irrelevant piece of software. I guess that there are 
situations where such a bottom-up approach makes sense, but unless you're a very large and fragmented 
company, or work in a very constrained industry, this is the kind of things only 
[Architecture Astronauts](https://www.joelonsoftware.com/2001/04/21/dont-let-architecture-astronauts-scare-you/) do. 
And please, don't be an Architecture Astronaut.

Still, let's pretent that we have very good reasons for going for a library instead of an application. A "library" 
can be as simple as a `require`’d Ruby file, but the most common way to package and distribute a librairy is by 
organizing it into a [gem](https://rubygems.org). So let's do that – let's build a gem, which will provide 
a character creation engine for Dungeons & Dragons, 5th edition. It will give us Ruby classes and methods to create a 
new character, set its game characteristics (such as race, class, attributes, etc.), and maybe even handle game 
mechanics such as dice rolls or experience points.

As an exercice, we'll also try to have a radical use of [BDD](https://dannorth.net/introducing-bdd/) and 
[TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html), in a "[London school](https://blog.devgenius.io/detroit-and-london-schools-of-test-driven-development-3d2f8dca71e5)" 
way – albeit with little to no mocking, if possible (because I don't like mocks that much anymore). This is 
the part from the Ankran Nembo app that I want to cannibalize: a long "integration test" that provided a 
nice example of _the code we wish we had_. We can use it as our "outside in" entry point, and let it 
drive the design of our library's API.

So let's get to it! First, we'll need to set up our workspace: the gem files and directories layout, and the test runner. 
Then, we'll start BDD-ing our way to a full-fledged D&D5 character creation library.