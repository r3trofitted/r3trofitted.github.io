---
layout: post
title: You don't need services (whatever this word means)
date: 2023-11-06 13:27 +0100
category: programming
---

Last Sunday, I had the pleasure to attend one of [Jason Swett](https://www.codewithjason.com)'s online meetups. This 
time, Jason had put his consultant hat on, and was helping a cheerful developer, Duncan, fix his app. Having played 
the role of the consultant myself quite often, watching someone else's approach was really interesting, so thank you 
Jason for this opportunity.

However, even more interesting was Duncan's problem, and tentative solution. The Rails app he works on has become a 
bit too big, convoluted, a suffers from performance issues. To remedy this, Duncan and his teammates have started 
extracting pieces of this monoliths to services.

If you know me, you know that I tend to starting ranting when I hear the word _service_. Years of misplaced hype have 
drained it of all meaning, but it is still everywhere – and, to me, its simple use is often a red flag. I'll keep the 
rant for another post, but let's take a moment to consider that, in Duncan's case like in many others, “introducing 
services to a Rails app” meant two different things:

*   Extracting pieces of logic from controllers and/or models[^1] to another category of objects. 
*   Extracting whole features to other applications.

In my opinion, you very rarely need to do either one of these things, let alone both. Whatever your problem is, 
introducing services is probably not the solution; in fact, it could make things even worse, while distracting you from 
fixing the _real_ issues you're facing.

## Services as a category of objects

Rails' decision to organize files by their role in the MVC pattern was already critized by people 
smarter than me [11 years ago](https://youtu.be/WpkDN78P884), but honestly I'm personally fine with the layout 
of the `/app` directory. However, I do believe that it trips newcomers up, by giving the impression that an object's 
role in the system is extremely significant, and by conflating _role_ and _type_. It makes you think in terms of 
_place in the filesystem_, instead of _responsibilities in the running system_. The folder in which the source file 
for an object doesn't matter; what matters is what the object does, and what it is in charge of. It's like job titles: 
they mean little, so don't obsess over them.

As an app grows, it does more and more, which means that there are more and more responsibilities to hand over to the 
objects in its system. The natural tendency is to hand these extra responsibilities to the current objects in the 
architecture, but then they become bigger, and so do their files. We tell developers to keep their controllers 
thin, so they feed the extra stuff to the models – but then we tell them that the models should be thin, too. It's a 
conundrum when the only two directories reasonably available are `app/controllers` and `app/models`; the natural solution 
is to add a new directory, for a new role: `app/services`. And now you can have bloated objects with fuzzy 
responsibilities, but feel good about it.

The problem here is not that a new directory is added; it's that the underlying issue is not solved, only hidden behind 
a small indirection. And now you have an hybrid architecture, an MSVC chimera that goes against the conventions of 
a Rails app. Which is morally fine, but throws away the benefits of the convention-over-configuration principle. You 
don't _have_ to stay on the rails, but if you don't, you'd better know what you're doing; and if you're blindly going for 
services, you probably don't.

Now, there are other justifications for introducing “service objects” into a Rails codebase, but I'll ignore them since 
I'm already three paragraphs in, and my advice is still the same for all of them: **consider your object a simple model**. 
Not all models in a Rails app have to be ActiveRecord models; the definition of model has nothing to do with the 
persistence in a database. In fact, by default, everything _is_ a model. If your new object has no responsibility 
related to the rendering, the routing, or the processing of an incoming request for a resource, then it is a model. Plain 
and simple. Sometimes models need to store their data, sometimes they don't, but as long as they are in charge of 
some business domain, they're models.

Keeping in mind that everything is a model unless it's a view or a controller[^2] is not (only) nitpicking on semantics; 
it avoids the trap of letting a file's name skew the role we give to the object it defines. If anything is a model, 
then an object being a model doesn't give you, the developer, any misleading hint on the responsibilities to give it. 
You cannot just cram in random procedural code and feel confident in your architecture because your new object implements 
a `.call` method.

In other words: keeping controllers and models _thin_ is a shortcut for _keeping them focused on a single responsibility_, 
which is a shortcut for _keeping them focused on exposing or embodying a single resource_. When controllers and/or models 
get fat, it usually means that somewhere, a new resource is trying to emerge; displacing the extra weight to a service 
object alleviates the symptom but prevents this new resource to emerge.

## Services as splinters of a monolith

When I don't hear teams talking about “service” as in _service layer_, it is usually in “_micro-service_”[^3]. The idea 
here is to remove a whole functionality of the application and reimplement it in a different application, which will be 
called instead. Basically, it's trading complexity within a single application for complexity within a whole system, 
with all the complications that come with replacing methods calls by HTTP requests.

Interestingly, the initial rationale for this expensive design choice is performance, or rather _scalability_. The idea 
is that, if your application is split into autonomous services, then the computing resources of the whole system could 
be allocated more efficiently. If users suffer bad performance when authenticating but none after that, then you can 
add more servers to the authentication service. This makes perfect sense – but it is a much rarer kind of issue than you 
think, and you'll probably never encounter it. And even if you can pinpoint performance-drowning features in your 
Rails monolith, but cannot fix the issue through code, I'm confident that you can afford to scale vertically the 
whole app anyways.

In my experience – and in Duncan's presentation of the design choices – the rationale for services quickly shifts once 
the decision has been made to introduce them. It's less about performance, and more about cooperation and onboarding. 
Splitting the architecture leads to splitting the codebase, and smaller codebases are easier to comprehend, especially 
for newcomers. Which, once again, is technically true, but comes with at a significant cost. Because, most of the times, 
you need every developer to understand the whole system anyways – especially if you didn't manage to put correct 
boundaries between the services. Yes, the codebase any given person will be working on at any given time will be 
smaller, but the cognitive load will probably not be reduced by much, because _other_ codebases will have to be kept 
in mind. This is certainly not true for very large teams working on very large applications, but chances are that you're 
not that big. And even then, [you don't need to split your Rails monolith](https://stackshare.io/shopify/shopify).

However, there is a third benefit that a team can gain from splitting a Rails monolith to services. Not performance, 
and not comprehensibility: comfort. Developers are people, and people have preferences – strong preferences, sometimes. 
Extracting a feature to a service opens the door to replacing a tech stack with another, piece by piece. Once again, 
this is paying a very high cost, but this time what you're buying is basically HR. Is this wise? Is this viable? I would 
say “probably not”, but then again, I'm not trying to hire developers or keep them from switching ship on a tech ocean 
where the winds of hype blow strong.

## Railways have no service (areas)

I may be wrong, but listening to Duncan, I felt like this third motivation for introducing services – a certain 
discomfort with Rails – was bigger than he himself realized. And, quite frankly, this would be the best reason 
for going this route, considering that this is a volunteers project. It's hard to work on something when you 
don't especially like it, or the tools you have to use, and it's even more true when you're not payed to do so. But, still: 
when it comes to Rails, if you enjoy it, then you'll probably enjoy it even more if you restrain from introducing 
services, be it as a layer or as a system architecture.

---

[^1]: In the code that Duncan showed us, it was from a controller, but I've often seen services built from models.
[^2]: Or a job, a channel, a mailer or a mailbox… Let's stick to the M, V and C, ok?
[^3]: More and more, it is in “_macro-service_”; please don't get me started on this.
