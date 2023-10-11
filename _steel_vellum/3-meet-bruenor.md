---
layout: post
title: "Meet Bruenor"
date: 2023-04-26 14:45 +0200
categories: programming
---
We now have a project, a structure for its code, and a configured test runner. It's time to start coding, which means 
that it's time to start writing actual tests!

### First test, big loop

Following the principle of the **double loop**, we want to start with some kind of outside-in, 
behaviour-describing test. For a proper application, this would be a use case of interacting with the UI; 
but since we're building a library, our "integration" test will consist of actually using the library to fully create a 
character.

As it happens, the Player's Handbook gives an example of a complete character creation. If 
our library is to be both comprehensive and easy to use (almost like a DSL), we should aim 
for code that reads a bit like the English sentences in this example. And we can follow the structure of the 
example for our tests as well.

Let's start with the first part in the character creation. It reads:

> **1. Choose a Race**
> 
> […]
> 
> *Building Bruenor, Step 1*
> 
> Bob is sitting down to create his character. He decides that a gruff mountain dwarf fits the 
> character he wants to play. He notes all the racial traits of dwarves on his character sheet, 
> including his speed of 25 feet and the languages he knows: Common and Dwarvish.

Quite frankly, there is not a lot in here, but we can still extract some expected behaviour: 
it must be possible to choose a race, and said race should provide certain traits, such 
as speed and languages (which, in turn, means that a character should store and return these traits). 

Converted to a test, this section could thus look like this:

  ```ruby?caption=test/creating_bruenor_test.rb
  require "minitest/autorun"
  require "steel_vellum"

  module SteelVellum
    class CreatingBruenorTest < Minitest::Test
      def test_1_choose_a_race
        creation = CharacterCreation.new

        creation.choose_race Races::MountainDwarf

        bruenor = creation.character
        assert_equal 25, bruenor.speed
        assert_includes bruenor.languages, :common
        assert_includes bruenor.languages, :dwarvish
      end
    end
  end
  ```

### The Goldilocks of API design

A few things are interesting here. First of all, unsurprisingly, we are writing tests for things that don't exist yet: 
there is no `CharacterCreation` class, no `#choose_race` method, etc. We are writing the code we wish we had, not the 
code we have (obviously, since we have none).

Second, note that we could have gone with another API. For example, with a block:

  ```ruby
  CharacterCreation.new do |creation|
    creation.choose_race Races::MountainDwarf
    # …
  end
  ```

… or, for even more English-sounding code, something like:

  ```ruby
  Character.create do
    choose_race :mountain_dwarf
    # …
  end
  ```

Ruby makes it easy to hide implementation details – the objects we create and manipulate – behind a friendly DSL, but I 
think that it would be unwise to go this far, at least for now. Yes, we're aiming for a great API, just like we'd be 
aiming for a great UI if we were building an app, but we should try to start with simple things. The block form would 
only be an extra indirection around the creation and subsequent use of a `CharacterCreation` object; the argument-less 
block form would only hide said object behind `instance_eval`‘s, etc. These layers of syntactic sugar would surely taste 
good, but let's focus on the cake before considering the frosting.

Finally, it's interesting to see that our (upcoming) API is used in the [_assertion_ phase](https://www.codewithjason.com/the-four-phases-of-a-test/) 
of the test as much as the [_exercise_ phase](https://thoughtbot.com/blog/four-phase-test). This is a bit unusual, 
but works well here, since our test is also meant to try out the API we're designing.

### More assertions, more discoveries

When the example says “all the racial traits of dwarves”, it skips over the details. If we were to copy all the relevant 
traits on our character sheet, we'd see that there are quite a few of them. Interestingly, one of these traits requires 
the player to make a choice among a list of options, which reveals another requirement of our library, as can be seen 
in the full test, with all the traits asserted for:

  ```ruby?caption=test/creating_bruenor_test.rb
  require "minitest/autorun"
  require "steel_vellum"

  module SteelVellum
    class CreatingBruenorTest < Minitest::Test
      def test_1_choose_a_race
        creation = CharacterCreation.new
    
        creation.choose_race Races::MountainDwarf
        creation.pick_proficiency :smiths_tools, from: :artisans_tools
    
        bruenor = creation.character
    
        assert_equal :medium, bruenor.size
        assert_equal 25, bruenor.speed
        assert_equal 60, bruenor.darkvision
    
        assert_equal 2, bruenor.ability_score_increases[:constitution]
        assert_equal 2, bruenor.ability_score_increases[:strength] # from the subrace
      
        assert bruenor.has_advantage_on_saving_throws_against?(:poison)
        assert bruenor.has_resistance_against?(:poison)
      
        assert bruenor.proficient_with? :battleaxe
        assert bruenor.proficient_with? :handaxe
        assert bruenor.proficient_with? :throwing_hammer
        assert bruenor.proficient_with? :warhammer
        assert bruenor.proficient_with? :smiths_tools
        assert bruenor.proficient_with? :light_armor
        assert bruenor.proficient_with? :medium_armor
      
        assert_includes bruenor.languages, :common
        assert_includes bruenor.languages, :dwarvish
        assert_includes bruenor.special_traits, :stonecunning
      end
    end
  end
  ```

Now we have a complete test of all the things that happen when you choose your character's race, and what objects 
and methods could allow us to either make or check these things:

- The character creation is an object in itself, of class `CharacterCreation`
- The actual choosing of the race is made possible through the method `CharacterCreation#choose_race`
- Races will be represented by classes (or maybe modules?), in their own namespace, such as `Races::MountainDwarf`
- The character itself can be obtained by calling `CharacterCreation#character`.
- We don't know what kind of object the character will be, but we know that it will respond to several calls: 
  `#size`, `#speed`, `#darkvision`, `#ability_score_increases[]`, `#has_advantage_on_saving_throws_against?`, 
  `#has_resistance_against?`, `#proficient_with?`, `#languages` and `#special_traits`; we also know the expected responses
  for these calls.

### From the outside to the inside

With our outer loop now ready, when can start the inner loops – which is to say adding unit tests for each relevant 
error message that we encounter while running the outer loop, then adding the code to make the unit test pass, 
and so on until there are no more errors in the outer loop. Let's start:

  ```console?prompt=𝄢
  𝄢 ruby -Ilib test/creating_bruenor_test.rb
  Run options: --seed 20874
  
  # Running:
  
  E
  
  Finished in 0.000915s, 1092.8962 runs/s, 0.0000 assertions/s.
  
  1) Error:
  SteelVellum::CreatingBruenorTest#test_1_choose_a_race:
  NameError: uninitialized constant SteelVellum::CreatingBruenorTest::CharacterCreation
  test/creating_bruenor_test.rb:7:in `test_1_choose_a_race'
  
  1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
  ```

This is perfectly normal – our test uses objects that don't exist yet. So let's add them; in order to keep our momentum, 
we won't bother with a decent file organisation for now, and simply add the missing class declaration to the 
`lib/steel_vellum.rb` file:

  ```ruby?caption=lib/steel_vellum.rb
  module SteelVellum
    class CharacterCreation
    end
  end
  ```

It is enough to let us move on to a different (albeit similar) error:

  ```console?prompt=𝄢
  𝄢 ruby -Ilib test/creating_bruenor_test.rb
  Run options: --seed 39286

  # Running:

  E

  Finished in 0.000638s, 1567.3982 runs/s, 0.0000 assertions/s.

  1) Error:
  SteelVellum::CreatingBruenorTest#test_1_choose_a_race:
  NameError: uninitialized constant SteelVellum::CreatingBruenorTest::Races
  test/creating_bruenor_test.rb:9:in `test_1_choose_a_race'

  1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
  ```

We'll keep adding the very minimal code needed to go through these `uninitialized constant` errors until we reach 
something new:

  ```console?prompt=𝄢
  𝄢 ruby -Ilib test/creating_bruenor_test.rb
  Run options: --seed 28958

  # Running:

  E

  Finished in 0.000647s, 1545.5955 runs/s, 0.0000 assertions/s.

  1) Error:
  SteelVellum::CreatingBruenorTest#test_1_choose_a_race:
  NoMethodError: undefined method `choose_race' for #<SteelVellum::CharacterCreation:0x000000010705ca00>
  test/creating_bruenor_test.rb:9:in `test_1_choose_a_race'

  1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
  ```

Now, that's an error which will require more than an empty class declaration to fix! Let's add a new test suite for 
the `CharacterCreation` class, with a first test for the `#choose_race` method – or at least a placeholder for it:

  ```ruby?caption=test/character_creation_test.rb
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

  require "steel_vellum/character_creation"

  module SteelVellum
    class CharacterCreationTest < Minitest::Test
      def test_choosing_a_race
        skip
        # what now?
      end
    end
  end
  ```

Why put a placeholder and stop now? Because, before writing the test, I'd like us to take a short break and clean up the 
code organization. Our new test suite is about the `CharacterCreation` class, and ideally, we shouldn't need any other 
class to run it. By specifically requiring a `steel_vellum/character_creation` file, instead of loading the whole library 
or relying on an autoloader, we ensure that dependencies will be obvious, should they arise – because we would then 
need to add new `require` directives. But for this to work, we need to actually move the `CharacterCreation` class 
definition to its own file.

  ```ruby?caption=lib/steel_vellum/character_creation.rb
  module SteelVellum
    class CharacterCreation
      def choose_race(race)
      end
    end
  end
  ```

  ```ruby?caption=lib/steel_vellum.rb
  require_relative "steel_vellum/character_creation"
  require_relative "steel_vellum/version"

  module SteelVellum
    module Races
      class MountainDwarf
      end
    end
  end
  ```

### Semantic pedantry and API whims

Now that this is done, we can think about what we want from the `#choose_race` method. Since there is no game logic yet, 
“choosing the character's race” could be nothing more than writing a simple value to a variable instance – just like 
writing down “Mountain Dwarf” on a character sheet. And instead of a class or module, we could use a simpler object, 
for example a symbol. Our test would then look like this:

  ```ruby
  def test_choosing_a_race
    creation = CharacterCreation.new
    creation.choose_race :mountain_dwarf
    assert_equal :mountain_dwarf, creation.character.race
  end
  ```

This would probably work, but here's the thing: I would love to be able to say that my character _is_ a Mountain Dwarf, 
not that it _has_ a race, which happens to be “Mountain Dwarf”. In other words, I'd love to be able to write this 
test instead:

  ```ruby
  def test_choosing_a_race
    creation = CharacterCreation.new
    creation.choose_race Races::MountainDwarf
    assert_kind_of Races::MountainDwarf, creation.character
  end
  ```

Is this excessive and capricious? Certainly. Does it have significant repercussion on our overall architecture? Definitely[^1]. 
Will we still do it, because it's more fun? You bet.

However, as written above, our unit test would still be a little too much coupled to implementation details – or, rather, 
to the details of the library's ”business logic”.

As much as I like my integration tests to be as realistic as possible, with plausible or even actual data, rules, classes, 
etc., I like my unit tests to be as abstract as possible – only caring about the bare minimum, and using as little of 
the actual application (or, in this case, library) as possible.

Concretely, in this example, using a specific race class (`Races::MountainDwarf`) seems a little _too_ specific. We want 
our character creation object to be able to handle anything that represents a character race, so the more generic, the 
better. Let's see how the test could look like with a generic `Race` class instead of a specific one.

  ```ruby?caption=test/character_creation_test.rb
  require_relative "test_helper"
  require "./lib/steel_vellum/character_creation"
  require "./lib/steel_vellum/race"
  
  module SteelVellum
    class CharacterCreationTest < Minitest::Test
      def test_choosing_a_race
        creation = CharacterCreation.new
        race     = Race.new
        
        creation.choose_race race
        
        assert_kind_of race, creation.character
      end
    end
  end
  ```

Now, we could go even further and use a _stub_ instead of a `Race` instance – something like `Object.new` instead of 
`Race.new` for example[^2]. This would be closer to the ”London school” of testing, but honestly, in such as situation, 
I would find stubbing overkill. It's a matter of balance: using a stub would reduce the coupling (as hinted by the 
necessary of adding a `require` at the top of the file), but also add an extra layer of abstraction between the test and 
the implementation. 

And if for some reason we'd eventually add constraints to the argument expected by the `Race#choose_race` method, then 
our stub would have to respect them – in other words, it would have to [quack like a duck](http://wiki.c2.com/?DuckTyping). 
Given how central to the library I expect the `Race` class to be, I anticipate a lot of quacking and a lot of stubbing, 
if we were to go this route. So, instead, let's use the actual class – even if it doesn't exist yet and would have 
to be _slimed_[^3].

### Wrapping it up

The real value of BDD and TDD is not the tests, it's the _driving of the design by the tests_. So far, we have written 
two tests: an integration test for the ”big loop”, which drove the design of the library's API, and a unit test for 
the first ”small loop”, which drove the design of a specific part of the library's architecture (namely, the relationship 
between character objects and race objects). Let's end this part here, and move on the part 4 for the first actual 
business code of this project!

---

[^1]: If you know your OOP, you'll recognize a case of favoring inheritance over composition, which is often a mistake.
[^2]: Vigilant readers would spot a problem with using `Object.new` here – but let's ignore it for now, we'll come back 
      to this in the next part…
[^3]: _Sliming_ is a term I've borrowed from [Gary Bernhardt](https://www.destroyallsoftware.com), and basically means 
      ”cheating temporarily by writing whatever implementation makes the test pass”.