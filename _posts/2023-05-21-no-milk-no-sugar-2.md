---
layout: no_milk_no_sugar
title: 'No milk, no sugar #2'
date: 2023-05-21 20:48 +0200
category: programming
---

## [Zenspider/warnings double loads and fixes](https://github.com/rouge-ruby/rouge/pull/1962)

Ryan Davis, one of my personal gurus, has submitted a PR to Rouge, a project 
[I've been tinkering with recently]({% post_url 2023-05-01-markdown-the-pits-of-madness %}). As I've 
[said on Mastodon](https://ruby.social/@r3trofitted/110378427091452264), this is a perfect example of what I consider a 
great pull request: the description is concise and considerate, but only comments on the _request_ – the changes 
themselves can easily be understood by simply reading the commits in order. It's really great – and the discussion that 
it started should be interesting.

## [man caffeinate](https://ruby.social/@Antitrust/110373900234007530)

Speaking of Mastodon, this is where I learnt about `caffeinate`, an [Apple-provided OSS tool](https://github.com/apple-oss-distributions/PowerManagement/tree/f7a2211e9886d9deb6793aa36547aadd8e70e9b0/caffeinate) 
to prevent a Mac from sleeping. So far, I've been using [KeepingYouAwake](https://keepingyouawake.app), but as 
it happens it's been banned by our IT department recently. Good to know there's a bare metal alternative available, if 
need be. (Granted, since I'll be leaving the company in two weeks, it doesn't matter a lot for now.)

## [https://rubyapi.org](https://rubyapi.org)

Interesting alternative to the official doc. I'm a very happy user of [Dash](https://kapeli.com/dash), and I like to 
refer to the official version of any kind of documentation in general, but I must say that I've had issues with Ruby's 
doc in the past couple of months. Could this good-looking alternative be better?

## [WebKit Features in Safari 16.5](https://webkit.org/blog/14154/webkit-features-in-safari-16-5/)

I'm intrigued by the introduction of CSS Nesting. It's the only thing I miss from Sass, but it does seem to still have 
rough edges. I'd love to try it out, though.

## [ActiveRecord::Base::normalizes in Rails 7.1](https://github.com/rails/rails/pull/43945)

Also found via [a blog post](https://blog.kiprosh.com/rails-7-1-activerecord-adds-normalizes-api/) shared on 
[ruby.social](https://ruby.social), this is the kind of quality-of-life, very well thought-out feature that gets me hyped 
with every new release of Rails. Adding normalization on assignement is so trivial that it's easy to overlook, but doing 
it _right_, in a way that pleases everyone – or at least pushes through the different sensibilities – is not that simple, 
as the conversation in the PR shows. Plus, having the _finder_ methods take the normalization into account is the chef's 
kiss. Love it.
