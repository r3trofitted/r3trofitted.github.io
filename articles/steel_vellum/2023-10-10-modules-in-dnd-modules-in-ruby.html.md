---
title: "Modules in D&D, modules in Ruby"
date: 2023-10-10 21:50 +0200
series: "Steel Vellum"
part: 4
...

We left our project with an integration test that doesn't pass (yet), and a unit test for the first piece of business 
logic revealed by this integration test: the character races as “types” for our `Character` objects. It is now time to 
make the unit test pass, which should drive us to an implementation of the `Race` class, and then move on to the next 
encounter in our integration test.

## Ancestry shenanigans

Our unit test, at the moment, looks like this:

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
      
      character = creation.character
      assert_kind_of race, character
    end
  end
end
```

And, as expected, it fails. More precisely, once we add a placeholder `Race` class to satisfy the `require` instruction, 
it fails with this interesting error: `class or module required`.

```ruby?caption=lib/steel_vellum/race.rb
module SteelVellum
  class Race
  end
end
```

```console?prompt=𝄢
𝄢 ruby -Ilib test/character_creation_test.rb

# Running tests with run options --seed 26591:

E

Finished tests in 0.000418s, 2392.3449 tests/s, 0.0000 assertions/s.


Error:
SteelVellum::CharacterCreationTest#test_choosing_a_race:
TypeError: class or module required
    test/character_creation_test.rb:13:in `test_choosing_a_race'

1 tests, 0 assertions, 0 failures, 1 errors, 0 skips
```

Back in the previous chapter, I said that a true mockist would probably not use the `Race` class in the example, but 
instead something simpler, like `Object`. Well, this wasn't completely accurate. Because we want whatever object
is passed to `#choose_race` to define what a `Character` object _“is”_, this object has to be either a class or a module, 
as the error message tells us.

Let's pause for a second. Our test is driving our design. Writing it, we discovered that we want characters races 
to be _instances_ of some kind of `Race` class (`race=Race.new`). But, at the same time, our test lead us to a design 
where these instances must be classes or modules themselves (`assert_kind_of race`, with `assert_kind_of` expecting 
a class or a module). Can an instance also be a class (or a module)?

Of course it can! This is one of the great (and elegant, and almost magical) things about Ruby: classes are instances, 
too – namely, instances of the `Class` class. By the same principle, modules are instances of the `Module` class, or a 
subclass of it. Therefore, we can move on to the next failure in our test by ensuring that `Race.new` returns either a 
class or a module. The simplest way to do that would to make `Race` _inherit_ from either one – except that Ruby doesn't 
allow subclassing `Class`, so the only option left is to have `Race` inherit from `Module`, so that `Race.new` _returns_ 
a (new) module.

```ruby?caption=lib/steel_vellum/race.rb
module SteelVellum
  class Race < Module
  end
end
```

```console?prompt=𝄢
𝄢 ruby -Ilib test/character_creation_test.rb
  
# Running tests with run options --seed 60990:

F

Finished tests in 0.000311s, 3215.4337 tests/s, 3215.4337 assertions/s.


Failure:
SteelVellum::CharacterCreationTest#test_choosing_a_race [test/character_creation_test.rb:13]
Minitest::Assertion: Expected #<SteelVellum::Character:0x0000000103d0a490> to be a kind of #<SteelVellum::Race:0x00000001039a0700>, not SteelVellum::Character.

1 tests, 1 assertions, 1 failures, 0 errors, 0 skips
```

We've successfully failed – meaning that we've successfully moved on to a different failure. But this one is a bit cryptic.
And how could our object be both “a kind of” `Character` and “a kind of” `Race`? Object in Ruby can only be of a single 
class, right?

Without diving too deep in the (marvellous) object model of Ruby, let's make a slight detour. The `assert_kind_of` 
matcher relies on [`Object#kind_of?`](https://docs.ruby-lang.org/en/3.2/Object.html#method-i-kind_of-3F), which is defined 
like so: 

> **kind_of?(class) → true or false**
> 
> Returns `true` if _class_ is the class of _obj_, or if _class_ is one of the superclasses of _obj_ or modules 
> included in _obj_.

This is very accurate but maybe a bit obscure, if you're not familiar with the way classes, modules and instances 
work in Ruby. Another way to define `kind_of?` could be:

> Returns `true` is _class_ is among the ancestors of _obj_'s [singleton] class.

Let's ignore the word in brackets for now. In Ruby, we know that each object has a class; this class, like all 
classes, _inherits_ from another class, which itself inherits from another class, and so on until this chain of 
_ancestors_ reaches `BasicObject`, [“the parent class of all classes in Ruby”](https://docs.ruby-lang.org/en/3.2/BasicObject.html#:~:text=BasicObject-,BasicObject,Ruby). 
We can check this out by looking at the ancestors of the class of the `character` object in our test. We know 
that this object's class is `SteelVellum::Character`, so we can do it like this:

```console?prompt=𝄢
𝄢 ruby -I lib -r steel_vellum/character_creation.rb -e "print SteelVellum::Character.ancestors"
[SteelVellum::Character, Object, Kernel, BasicObject]
```

Ignoring the first item in this array (which is the interrogated class itself), we see the list of classes[^1] from 
which `Character` inherits: `Object`, `Kernel` and, eventually, `BasicObject`. For our test to pass, and 
our assertion `assert_kind_of race, character.character` to be true, we need to somehow add `race` to this list of 
ancestors.

We cannot do that by making our `race` object a parent of the `Character` class – first because it would make no sense 
from a business logic perspective (characters are not character races), but more importantly because we've already 
established that `race` is a `Module`, and modules cannot be inherited from.

However, like classes, Ruby modules can be part of the ancestors chain of a class – in fact, in the ancestors list 
above, `Kernel` is actually a [module](https://docs.ruby-lang.org/en/3.2/Kernel.html), not a class. As explained in 
the definition of `Object#kind_of?`, _included modules_ also count as ancestors. But how could we include this `race` 
module in the class of our `character` object?

## A single-use class

Once again, the `character` object is an instance of `Character`. So, a naive way to have it also be “a kind of” `race` 
would be to call `Character.include race`. But then, _all_ instances of `Character` would also have `race` in their ancestors. 
All characters would be of the same race, which is not what we want.[^2]

What we want is for this `race` module to be included in the class of our `character` instance, **but only for this 
instance**. And we can do that thanks to `Module#extend` and the elegant magic of the _singleton class_.

By _extending the instance_ with the module instead of _including the module in the class_, we'll have what we want. To 
see this in action, let's temporarily hack our test:

```ruby?caption=test/character_creation_test.rb (excerpt)
def test_choosing_a_race
  creation = CharacterCreation.new
  race     = Race.new
  
  creation.choose_race race
  
  character = creation.character
  character.extend race
  
  assert_kind_of race, character
end
```

```console?prompt=𝄢
𝄢 ruby -Ilib test/character_creation_test.rb

# Running tests with run options --seed 19004:

.

Finished tests in 0.000345s, 2898.5521 tests/s, 2898.5521 assertions/s.


1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
```

Or test passes! But how come?

When we called `character.extend race`, Ruby did something clever. It created a _new_ class, anonymous, and had it 
inherit from `Character`. It also included `race` into this new class, and then had `character` inherit from it. Because 
it inherits from `Character`, this anonymous class behaves exactly as `Character`, but it is specific to the `character` 
object. (And it includes `race`, which is the whole point.)

There is no formal name for this kind of object-specific, anonymous class. Some used to call it “eigenclass”, others 
“ghost class”, but nowadays, it is most often named _singleton class_[^3]. In fact, this class can be reached (and 
created on-the-fly, if necessary) by calling [`Object#singleton_class`](https://docs.ruby-lang.org/en/3.2/Object.html#method-i-singleton_class). 
Let's launch an IRB console and compare the ancestors of this singleton class, for a given `Character` instance, before 
and after extending a `Race` module:

```irb
>> Dir[__dir__ + "/lib/steel_vellum/**/*.rb"].each { |f| require f }; include SteelVellum;
>> 
>> c = Character.new
=> #<SteelVellum::Character:0x0000000109f1e320>
>> c.singleton_class.ancestors
=> 
[#<Class:#<SteelVellum::Character:0x0000000109f1e320>>,
 SteelVellum::Character,
 Object,
 SteelVellum,
 Kernel,
 BasicObject]
>> c.extend Race.new
=> #<SteelVellum::Character:0x0000000109f1e320>
>> c.singleton_class.ancestors
=> 
[#<Class:#<SteelVellum::Character:0x0000000109f1e320>>,
 #<SteelVellum::Race:0x000000010abb3860>,
 SteelVellum::Character,
 Object,
 SteelVellum,
 Kernel,
 BasicObject]
```

So, there you have it. Even though Ruby objects can only be instances of a single class, they can inherit traits from 
any number of modules, and don't have to share these inheritances with any other object, thanks to the existence of a 
singleton class.

Now that we know how to have characters _be_ of a given race, and why this is even possible in the first place, let's 
remove the hack from our test and implement things properly:

```ruby?caption=lib/steel_vellum/character_creation.rb
require_relative "character"

module SteelVellum
  class CharacterCreation
    def choose_race(race)
      @race = race
    end
    
    def character
      Character.new.tap do |c|
        c.extend @race
      end
    end
  end
end
```

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
      
      character = creation.character
      assert_kind_of race, character
    end
  end
end
```

```console?prompt=𝄢
𝄢 ruby -Ilib test/character_creation_test.rb

# Running tests with run options --seed 60242:

.

Finished tests in 0.000328s, 3048.7789 tests/s, 3048.7789 assertions/s.


1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
```

## Back to the outer loop…

Our unit test now passes – we've closed the small loop. Let's go back to the big loop (the integration test) and 
see where the next failure leads us.

```console?prompt=𝄢
𝄢 ruby -Ilib test/creating_bruenor_test.rb

# Running tests with run options --seed 19079:

E

Finished tests in 0.000429s, 2331.0023 tests/s, 0.0000 assertions/s.


Error:
SteelVellum::CreatingBruenorTest#test_1_choose_a_race:
TypeError: wrong argument type Class (expected Module)
    /Users/ronan/Dev/steel_vellum/lib/steel_vellum/character_creation.rb:14:in `extend'
    /Users/ronan/Dev/steel_vellum/lib/steel_vellum/character_creation.rb:14:in `block in character'
    <internal:kernel>:90:in `tap'
    /Users/ronan/Dev/steel_vellum/lib/steel_vellum/character_creation.rb:13:in `character'
    test/creating_bruenor_test.rb:17:in `test_1_choose_a_race'

1 tests, 0 assertions, 0 failures, 1 errors, 0 skips
```

This was to be expected – `CharacterCreation#choose_race` must be passed a module now, but `MountainDwarf` is still a 
slimed class. Let's change that.

```ruby?caption=lib/steel_vellum/races/mountain_dwarf.rb
require_relative "../race"

module SteelVellum
  module Races
    MountainDwarf = Race.new
  end
end
```

Moving on, we can rerun the integration test and figure out what other missing piece of our library we should build now.

```console?prompt=𝄢
𝄢 ruby -Ilib test/creating_bruenor_test.rb

# Running tests with run options --seed 52522:

F

Finished tests in 0.000367s, 2724.7956 tests/s, 5449.5913 assertions/s.


Failure:
SteelVellum::CreatingBruenorTest#test_1_choose_a_race [test/creating_bruenor_test.rb:19]
Minitest::Assertion: Expected: :medium
  Actual: nil

1 tests, 0 assertions, 0 failures, 1 errors, 0 skips
```

This is a more interesting failure! According to the test, making Bruenor a Mountain Dwarf should automatically give him 
a `:medium` size, but at the moment, `Character#size` always returns `nil` (since we didn't bother actually implementing 
the method's body). Let's remedy that.

Because this failure reveals a missing piece of business logic, we must start a new small loop, and design the 
implementation of this unitary feature through one or more unit tests.

## Hooks in you

For a start, let's simply isolate the failing assertion from the integration test into an unit test:

```ruby?caption=test/races/mountain_dwarf_test.rb
require_relative "../test_helper"
require "./lib/steel_vellum/character"
require "./lib/steel_vellum/races/mountain_dwarf"

module SteelVellum
  class Races::MountainDwarfTest < Minitest::Test
    def test_a_mountain_dwarf_character_has_a_medium_size
      character = Character.new
      
      assert_nil character.size
      character.extend Races::MountainDwarf
      
      assert_equal :medium, character.size
    end
  end
end
```

Covered by our unit test, let's think about a way to make it pass. The test tells us that, once a `Character` instance 
is extended by the `MountainDwarf` module, its `#size` method should return `:medium` instead of `nil`. When a module 
extends an object, the methods defined inside this module are added to the instance methods of the object's singleton 
class, so one way to make our test pass would be to redefine `#size` in the `MountainDwarf` module:

```ruby?caption=lib/steel_vellum/races/mountain_dwarf.rb
require_relative "../race"
  
module SteelVellum
  module Races
    MountainDwarf = Race.new do
      def size
        25
      end
    end
  end
end
```

However, while perfectly fine in general, I'm not too fond of this approach in this specific situation. That is because 
a character's size is more _data_ than _behavior_. I'd rather store this information in an instance variable than have 
it being returned by a method[^4].

Thankfully, Ruby gives us another trick to reach our goals: _hook methods_. These are methods that, if defined, 
get called we certain events happen in an object's lifetime. For example, `#method_missing` is a well-known hook 
method that is called when an object (or rather: a module or a class) receives a call to a method that neither 
it not any of its ancestors define. In our case, we'll make use of the [`#extended`](https://docs.ruby-lang.org/en/3.2/Module.html#method-i-extended) 
hook method.

This method is called whenever a module extends an object. We can use it to change the value of the character's `@size` 
instance variable – in practice, giving it a default value, which the `Character` instance will then be free to change, 
if need be. (After all, our Dwarf could one day drink a magical potion and grow a size or two.) This is what using 
the `#extended` hook looks like:

```ruby?caption=lib/steel_vellum/races/mountain_dwarf.fr
require_relative "../race"

module SteelVellum
  module Races
    MountainDwarf = Race.new do
      def self.extended(character)
        character.size = :medium
      end
    end
  end
end
```

Of course, for the `character.size = :medium` instruction to work, we need to give accessors to the `@size` instance 
variable of `Character`:

```ruby?caption=lib/steel_vellum/character.rb
module SteelVellum
  class Character
    attr_accessor :size
    
    # TODO: is this method really useful? It won't be used once the character creation is done
    def ability_score_increases
    end
    
    def speed
    end
    
    def darkvision
    end
    
    def languages
    end
    
    def has_advantage_on_saving_throws_against?(type)
    end
    
    def has_resistance_against?(type)
    end
    
    def proficient_with?(proficiency)
    end
    
    def special_traits
    end
  end
end
```

Now our test passes. We can close this small loop and go back, once again, to the big one by running (yet again) the 
integration test. It now fails because of the next character trait that a race is supposed to give a default 
value to:

```console?prompt=𝄢
𝄢 ruby -Ilib test/creating_bruenor_test.rb

# Running tests with run options --seed 15813:

F

Finished tests in 0.000413s, 2421.3068 tests/s, 4842.6136 assertions/s.


Failure:
SteelVellum::CreatingBruenorTest#test_1_choose_a_race [test/creating_bruenor_test.rb:20]
Minitest::Assertion: Expected: 25
  Actual: nil

1 tests, 2 assertions, 1 failures, 0 errors, 0 skips
```

This time, it is `Character#speed` that doesn't return the expected value. We'll proceed as exactly like we have with 
`#size` – adding a unit test, watching it fail, making it pass, and then moving back to the integration test. And after 
that, we'll have `Character.darkvision` to fix. In the end, this is what our `MountainDwarf` class and its tests will be:

```ruby?caption=lib/steel_vellum/races/mountain_dwarf.fr
require_relative "../race"

module SteelVellum
  module Races
    MountainDwarf = Race.new do
      def self.extended(character)
        character.size       = :medium
        character.speed      = 25
        character.darkvision = 60
      end
    end
  end
end
```

```ruby?caption=test/races/mountain_dwarf_test.rb
require_relative "../test_helper"
require "./lib/steel_vellum/character"
require "./lib/steel_vellum/races/mountain_dwarf"

module SteelVellum
  class Races::MountainDwarfTest < Minitest::Test
    def test_a_mountain_dwarf_character_has_a_medium_size
      character = Character.new
      
      assert_nil character.size
      character.extend Races::MountainDwarf
      
      assert_equal :medium, character.size
    end
    
    def test_a_mountain_dwarf_character_has_a_speed_of_25
      character = Character.new
      
      assert_nil character.speed
      character.extend Races::MountainDwarf
      
      assert_equal 25, character.speed
    end
    
    def test_a_mountain_dwarf_character_has_darkvision_up_to_60_feet
      character = Character.new
      
      assert_nil character.darkvision
      character.extend Races::MountainDwarf
      
      assert_equal 60, character.darkvision
    end
  end
end
```

## Stepping away from BDD

Normally, keeping with our back-and-forths between the integration tests and the unit tests, our next step should probably be 
have to do with `ability_score_increases`. However, once again, I'd like to take a step back and consider 
our recent work.

We've implemented the behavior of the `Races::MountainDwarf` instanciated modules, because this is what our tests have 
covered. But we know that other races will eventually be covered by the library, and we know that they, too, will 
assign a size, a speed and a darkvision range to the characters. So, even though we don't have any test to _lead_ us 
there yet, we can safely assume that making this piece of business logic a bit more generic is valuable.

In practice, this means that _any_ subclass of `Race` should be able to assign values to a `Character`'s `@size`, `@speed` 
and `@darkvision` instance variables, and the assigned values would depend on the subclass itself. This is rather easy 
to write tests for.

First, we need to be able to define the values that a race will assign:

```ruby?caption=test/race_test.rb
require_relative "test_helper"
require "./lib/steel_vellum/race"
require "./lib/steel_vellum/character"

module SteelVellum
  class RaceTest < Minitest::Test
    def test_race_initialization
      race = Race.new(speed: 30, size: :small, darkvision: 5)
      
      assert_equal 30, race.speed
      assert_equal :small, race.size
      assert_equal 5, race.darkvision
    end
  end
end
```

Then, we need to ensure that using the race to extend a `Character` assigns these values. We can simply cannibalize 
the tests for `MountainDwarf`; but for the sake of conciseness, we'll squash the 3 tests into a single one with 
multiple assertions:

```ruby?caption=test/race_test.rb
require_relative "test_helper"
require "./lib/steel_vellum/race"
require "./lib/steel_vellum/character"

module SteelVellum
  class RaceTest < Minitest::Test
    def test_race_initialization
      race = Race.new(speed: 30, size: :small, darkvision: 5)
      
      assert_equal 30, race.speed
      assert_equal :small, race.size
      assert_equal 5, race.darkvision
    end
    
    def test_extending_a_character_sets_default_for_their_traits
      race      = Race.new(speed: 25, size: :medium, darkvision: 60)
      character = Character.new
      
      assert_nil character.speed
      assert_nil character.size
      assert_nil character.darkvision
      
      character.extend race
      
      assert_equal 25,      character.speed
      assert_equal :medium, character.size
      assert_equal 60,      character.darkvision
    end
  end
end
```

The implementation is pretty straightforward too, except for one subtlety:

```ruby?caption=lbi/steel_vellum/race.rb
module SteelVellum
  # TODO: maybe add a DSL for defining races (e.g. +Race.new { size :medium }+)
  class Race < Module
    attr_accessor :speed, :size, :darkvision
    
    def initialize(speed: 30, size: :medium, darkvision: 0)
      @speed, @size, @darkvision = speed, size, darkvision
    end
    
    def extended(character)
      character.size       = @size
      character.speed      = @speed
      character.darkvision = @darkvision
    end
  end
end
```

The `#extended` hook method must be defined in the _class_ (singleton or not) of the object on which it will be called. 
This is why, when its definition was in the `MountainDwarf` class, it was sent to `self`. (In other words: `.extended` 
was defined as a _class method_ of `MountainDwarf`). However, since we're moving this definition up to the 
_class_ of all races modules, the `#extended` must now be defined as an _instance_ method[^5] of `Race`.

(Note also that we've also added default values in the initializer, even though we didn't write tests for that, and therefore 
have no idea if this is legitimate design or not – we're freewheeling! 🤘)

## Hidden edge cases

Here is a secret about BDD: since it's about letting the _expected behavior_ drive the design, edge cases – in other 
words: _unexpected_ behavior – can slip through. Which is why it is important to consider these edge cases when working 
at the unit test level, where they are easier to think about.

In our case, even though we've kept saying that a character's race gives it _default_ values for some traits, we haven't 
tested for the (unlikely) situation where some would have already been defined _before_ the race was assigned. So let's 
add that. And while we're at it, let's cover another edge case: using a race module to extend an object which is not 
an instance of the `Character` class.

```ruby?caption=test/race_test.rb (excerpt)
def test_extending_a_character_doesnt_change_existing_traits
  race      = Race.new(speed: 25)
  character = Character.new
  
  character.speed = 30
  character.extend race
  
  assert_equal 30, character.speed # hasn't changed to 25
end

def test_extending_an_irrelevant_class_does_nothing
  race = Race.new
  obj  = Object.new

  obj.extend race # should not raise nor do anything
end
```

The final implementation is quite easy:

```ruby?caption=lib/steel_vellum/race.rb
module SteelVellum
  # TODO: maybe add a DSL for defining races (e.g. +Race.new { size :medium }+)
  class Race < Module
    attr_accessor :speed, :size, :darkvision
    
    def initialize(speed: 30, size: :medium, darkvision: 0)
      @speed, @size, @darkvision = speed, size, darkvision
    end
    
    def extended(o)
      assign_traits(o) if o.kind_of? Character
    end
    
    private
    
    def assign_traits(character)
      character.size       ||= @size
      character.speed      ||= @speed
      character.darkvision ||= @darkvision
    end
  end
end
```

## Final cleanup

Now that the logic for assigning default values to a character's racial traits is moved up to the `Race` class from 
which `MountainDwarf` inherits, we can clean up our previous work, by deleting the now redundant unit tests in 
`MountainDwarfTest`, and the logic from `MountainDwarf`:

```ruby?caption=lib/steel_vellum/races/mountain_dwarf.rb
require_relative "../race"

module SteelVellum
  module Races
    MountainDwarf = Race.new(size: :medium, speed: 25, darkvision: 60)
  end
end
```

And this is it (for now)! We've successfully implemented the first actual piece of logic in our library, which is 
actually quite a lot:

- We can define a character race, or at least 3 of its traits for now.
- These traits are automatically assigned to a character when their race is chosen during character creation.
- For developers who'll eventually use our library, assigning a `Race` to a `Character` object gives it some kind 
  of “type”, which is probably a false good idea, but fun nonetheless.

We can now return to our big loop, once again, and see what the DM of BDDing has for us in the next installment of 
this series!

---

[^1]: Roughly speaking.

[^2]: Feel free to try this out in an IRB console: create 2 instances of `Character`, create a new `Race`, include it 
      in `Character` with `Character.include the_new_race` and see that both the instances now “are” also of this race.

[^3]: Don't be mistaken, this class has nothing to do with the [singleton design pattern](https://archive.org/details/designpatternsel00gamm/page/126/mode/2up), or the [Singleton](https://docs.ruby-lang.org/en/3.2/Singleton.html) module!

[^4]: Technically, even if store in an instance variable, the value will be returned by a method (namely, a reader accessor), but hopefully you see what I mean.

[^5]: As an exercice, can you guess what would happen, and why, if within the `Race` class we'd write `def self.extended`?