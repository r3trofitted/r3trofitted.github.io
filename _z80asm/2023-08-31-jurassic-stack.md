---
layout: post
title: Jurassic Stack
date: 2023-08-31 14:02 +0200
categories: programming
---

## Coding high and low

Ruby is a great language. It is my favorite. It is also considered a _high-level_ language which, if you're curious, 
may beg the question: what is a _low-level_ language? How different would it be to code in such a thing?

To compare Ruby with a low-level language, we first need to pick one. This is not as easy as it sounds, because programming 
languages are not like, say, [cliffs from which Norwegian singers can jump](): their elevation is not absolute, but relative. 
The debate as to wether C is a high- or low-level language is [still occasionally reignited](). Yet, one thing is certain: you 
cannot go lower than machine language. Here is an extract of a program in machine code:

```
3E 48 CD 5A BB 3E 65 CD 5A BB 3E 6C CD 5A BB 3E 6C CD 5A BB 3E 6F CD 5A BB
```

Even though people did write programs like this, this is a bit too low-level for me (and my sanity). One level of abstraction 
above is the **assembly** (and _abstraction_ is a big word here). Here is the same piece of program, in assembly:

```
LD    A,&48
CALL  &BB5A
LD    A,&65
CALL  &BB5A
LD    A,&6C
CALL  &BB5A
LD    A,&6C
CALL  &BB5A
LD    A,&6F
CALL  &BB5A
```

With a bit of formatting, you can see how similar to the machine language it is:

```
3E    48
CD    5A BB
3E    65
CD    5A BB
3E    6C
CD    5A BB
3E    6C
CD    5A BB
3E    6F
CD    5A BB
```

Sure, the `&`'s have been removed, and some character pairs have been switched, but you can see how the word-like stuff 
in the assembly version maps to specific numbers in the machine language version. That's because assembly is basically 
the transposition of the machine code _instructions_ in character sequences (called _mnemonics_). That's indisputably 
low-level.

In fact, assembly is so low-level that there is no single, uniform assembly language. Instead, each microprocessor 
architecture has its own assembly language, because each microprocessor architecture has its own set of code instructions. 
So if we are to write a program in assembly, we must first chose "an" assembly – or rather, a target microprocessor.

Modern processors are insanely sophisticated, so much that I don't even want to imagine how difficult writing assembly 
for them must be. Besides, I have a score to settle with a much older processor: the Z80.

The Z80 was an 8-bit microprocessor, made by the US company Zylog and introduced in 1976. From the late 1970s 
to the mid-1980s, it was ubiquitous, powering arcade games, game consoles, calculators, and more importantly for me, 
home computers.

This variety of devices is important because, even though an assembly program is technically compatible with anything 
that uses the relevant processor, in reality, it also depends on the general architecture of the system, which can 
greatly vary. For example, a Sega MasterSystem and a Pac-Man arcade have different amount of memory, with different 
layouts, etc. So for our experiment with assembly, we'll need to target a specific machine, and it will be the 
Amstrad CPC.

## LOAD 1987

Amstrad was a British electronics company; its first computer, the Amstrad CPC 464, was introduced in 1984 and was a 
great success in Europe (especially in France), as was its successors, the CPC 6128[^1], the later being 
released in 1985.

As it happens, the Amstrad CPC 6128 was also my first computer, and the best Christmas gift of 1987, as you can see:

[photo]

(If you're not too distracted by the swag of my velvet pants, you'll notice that mother, always mindful of the important 
things in life, had sneaked in the presents an educational game for me to practice my German.)

This is the computer on which I learned to program[^2]; but back then, once you had mastered BASIC, assembly was the 
only next step available, and the gap between the two was too large for me – especially when there were all those 
cool games I could play instead. But nothing is ever too late!

One of the things that made assembly so hard to grasp for me in 1987, I think, is how depend on the hardware it is. To 
program in assembly you need to learn how the computer works – what memory actually is, how a processor works, what 
buses and interrupts are, etc. This is probably why so many learning resources, even today, start with theoretical 
exposes on registers, binary arithmetics, or addressing techniques. In this series, I'll try to dive into the code 
as soon as possible, and take technical detours when necessary. But I will also skip over things that were ubiquitous then 
but rarely used now, such as hex notation; hopefully they will not deter you as they deterred me when I was a kid.

---

[^1]: I'm skipping over the CPC 664, which was only on the market for a few months.

[^2]: _Technically_, I had previously dabbled in programming on [TO7]() computers at my town's computer club, if you 
consider Logo a real programming language.    