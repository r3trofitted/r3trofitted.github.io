---
layout: post
title: "Arranging atoms by hand"
date: 2023-04-22 14:45 +0200
categories: programming
---
Gems are cool. They are shiny, colorful, and worth up to 5000 gold pieces each, according to the Game Master's Guide. 
In the Ruby world, though, gems are sometimes a bit mysterious – they are magical pieces of software 
that do stuff for you once you've invoked them. To make things even more complicated, nowadays we 
don't even handle gems directly – most of the time, we let another tool, [Bundler](https://bundler.io), 
do it for us. It's a shame, because understanding Ruby gems is also worth a lot. So, before we go on our journey, 
let's take a detour to see how gems work and how to build one ourselves.

### How gems work
`RubyGems`, first released in 2004, is "just" a Ruby library. But it is such an important one that it has been bundled 
with Ruby since 2007 (and Ruby 1.9) When you install Ruby on a computer, RubyGems is installed, too; and when you run a 
run a Ruby script or a REPL, RubyGems is automatically required for you.

And when it is required, RubyGems "hijacks" the native `Kernel#require` method so that files are looked for in more places 
than normal – including certain directories that RubyGems knows about, and where it can install specifically packaged 
Ruby libraries, called _gems_.

RubyGems also comes with an executable, `gem`, that can (among other things) fetch, unpack, and install gems in those 
directories. Gems installed by the `gem` command will be found by the hijacked `require` method, and _voilà_: Ruby 
programmers can enjoy a very easy way to distribute and integrate libraries in their Ruby programs.

In order for RubyGems to be able to install it, a gem must follow certain specifications. They are rather light, and 
well documented [in the RubyGems guides](https://guides.rubygems.org/what-is-a-gem/). The minimal setup for a gem is:

*    A `lib/` directory, which will contain the gem's code – at the very least, in a single file, which by convention is named after the gem.
*    A _gemspec_ file, also named after the gem (but with the `.gemspec` extension)

So, two files and one directory are enough for RubyGems to package everything into a single archive, or more importantly, 
to unpack said archive and install the library's code in the right place.

### Creating our gem
Several tools can generate a scaffolding for a new gem (such as [Bundler](bundler.io) or [Gemsmith](https://alchemists.io/projects/gemsmith)), 
but we'll do it from scratch, both as a learning exercice and to keep things minimal. And the first step in creating our 
gem is to name it.

Finding a good name is hard. The RubyGems guides provide [great advice on naming a gem](https://guides.rubygems.org/name-your-gem/), 
but they are more about conventions to follow (which we will!) than naming ideas. I like whimsical and colorful names, 
so something boring like `dnd_character_creator` is out of the question. Instead, let's use our imagination. What 
"builds character", in a fantasy world? Conan would probably say that it's action and combat - or more poetically, 
[steel](https://youtu.be/MKMG-FdCGtM). And we'll eventually write our character down on a character sheet – a piece of 
paper, or in a fantasy world, vellum. So let's name our gem *Steel Vellum* – or rather, `steel_vellum`. It sounds D&D-y 
enough for me.

Now that we have a name, we can create the files and folder that we need:

  ```console?prompt=𝄢
  𝄢 mkdir -p steel_vellum/lib
  𝄢 touch steel_vellum/lib/steel_vellum.rb
  𝄢 touch steel_vellum/steel_vellum.gemspec
  ```

According to [the documentation](https://guides.rubygems.org/specification-reference/), the gemspec file must contain 
the gem's specifications – a lot of them can be defined, but only 5 are required: a name, a version number, the list 
of files that constitute the library, a short description and a list of authors. So let's add these to the 
`steel_vellum.gemspec` file.

  ```ruby?caption=steel_vellum.gemspec
  Gem::Specification.new do |s|
    s.name    = "steel_vellum"
    s.version = "0.1.0"
    s.files   = ["lib/steel_vellum.rb"]
    s.summary = "A D&D 5e character creation library"
    s.authors = ["Ronan Limon Duparcmeur"]
  end
  ```

As for the code of the libary itself, let's do the very bare minimum for now, and only provide a module. We could leave 
it empty, but let's also add a version number in the form of a constant – just to have something to try out the gem with:

  ```ruby?caption=lib/steel_vellum.rb
  module SteelVellum
    VERSION = "0.1.0"
  end
  ```

It is enough? Will it work? Let's see if we can build the gem – i.e. package it into a `.gem` file – and install it.

  ```console?prompt=𝄢
  𝄢 cd steel_vellum
  𝄢 gem build
  
  WARNING:  licenses is empty, but is recommended.  Use a license identifier from
  http://spdx.org/licenses or 'Nonstandard' for a nonstandard license.
  WARNING:  no homepage specified
  WARNING:  See https://guides.rubygems.org/specification-reference/ for help
    Successfully built RubyGem
    Name: steel_vellum
    Version: 0.1.0
    File: steel_vellum-0.1.0.gem

  $ gem install steel_vellum-0.1.0.gem

  Successfully installed steel_vellum-0.1.0
  1 gem installed
  ```

RubyGems gave us a few warnings when it built the gem (and we'll address them later), but so far, everything seems fine. 
Let's check it out in a Ruby console:

  ```irb
  >> require "steel_vellum"
  => true
  >> SteelVellum::VERSION
  => "0.1.0"
  ```

It works! And we can see that the metadata we've added to our gem is indeed used:

  ```console?prompt=𝄢
  𝄢 gem info steel_vellum

  *** LOCAL GEMS ***

  steel_vellum (0.1.0)
      Author: Ronan Limon Duparcmeur
      Installed at: /Users/ronan/.gem/ruby/3.2.2

      A D&D 5e character creation library
  ```

(Note that the actual installation path will vary according to your Ruby installation.)

### Test setup
We now have the right foundations for our gem, and we could start adding code to the `lib/steel_vellum.rb` file. But we've 
decided to go tests-first as much as possible, so let's setup our project so that we can indeed write and run tests.

RSpec is a popular and extremely complete testing framework, but I prefer [Minitest](https://rubygems.org/gems/minitest) 
– it's lean and fast, and does everything you need but nothing more, which means that it's hard to shoot yourself in 
the foot (by abusing mocks or [over-DRYing](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction), for example), 
even if you can miss the syntactic sugar, sometimes. Plus, like RubyGems, Minitest comes bundled with Ruby.

However, even though Minitest doesn't need to be _installed_ (normally), it still needs to be declared as a _dependency_ of 
our gem. This is done through the gemspec file:

  ```ruby?caption=steel_vellum.gemspec
  Gem::Specification.new do |s|
    s.name    = "steel_vellum"
    s.version = "0.1.0"
    s.files   = ["lib/steel_vellum.rb"]
    s.summary = "A D&D 5e character creation library"
    s.authors = ["Ronan Limon Duparcmeur"]
    
    s.add_development_dependency "minitest"
  end
  ```

  ```console?prompt=𝄢
  𝄢 mkdir test
  𝄢 touch test/steel_vellum_test.rb
  ```

The file itself only needs to require Minitest, but we'll add a placeholder test to ensure that everything works well:

  ```ruby?caption=test/steel_vellum_test.rb
  require "minitest/autorun"
  require "steel_vellum"
  
  class SteelVellumTest < Minitest::Test
    def test_it_works
      assert_equal "0.1.0", SteelVellum::VERSION
    end
  end
  ```

To run the test, when only need to run this file – but we need to make sure that the `lib/` directory will be included 
in [Ruby's `$LOAD_PATH`](https://docs.ruby-lang.org/en/master/Kernel.html#method-i-load).

  ```console?prompt=𝄢
  𝄢 ruby -Ilib test/steel_vellum_test.rb
  Run options: --seed 11645

  # Running:

  .

  Finished in 0.001717s, 582.4112 runs/s, 582.4112 assertions/s.

  1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
  ```

Our test suite – with its single test – runs fine. But typing the name of every single test file to run will eventually 
become tedious, so ([as suggested in the documentation](http://docs.seattlerb.org/minitest/README_rdoc.html#label-Running+Your+Tests)), 
let's add a Rake task to run the whole suite for us. This is very easy, since Minitest provides one for us – we only need 
to set it as the default Rake task for our project. And because we've stuck to the conventions when namimg files and 
directories, we need almost nothing: 

  ```ruby?caption=Rakefile
  require "minitest/test_task"
  
  Minitest::TestTask.create
  task :default => :test
  ```

And that's it! Now, executing `rake` without specifying a Rake task will run the whole test suite:

  ```console?prompt=𝄢
  𝄢 rake
  Run options: --seed 36531

  # Running:

  .

  Finished in 0.000540s, 1851.8521 runs/s, 1851.8521 assertions/s.

  1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
  ```

### Final touches
And so, we have the basis for our Steel Vellum library, written with its tests and distributable as a gem. Let's wrap 
things up by smoothing the rough edges of this scaffold. We have a few warnings to fix, and our test runner could 
benefit from a more colorful output. More importantly, the gem's version number is currently written twice, which 
means extra maintenance – or potential inconsitencies. Let's fix all that by removing the `VERSION` declaration from 
the main library file……

  ```ruby?caption=lib/steel_vellum.rb
  module SteelVellum
  end
  ```

… and placing it in its own file…

  ```ruby?caption=lib/steel_vellum/version.rb
  module SteelVellum
    VERSION = "0.1.0"
  end
  ```

… which can then be required directly in the gemspec file:

  ```ruby?caption=steel_vellum.gemspec
  require_relative "lib/steel_vellum/version"
  
  Gem::Specification.new do |s|
    s.name     = "steel_vellum"
    s.version  = SteelVellum::VERSION
    s.summary  = "A D&D 5e character creation library"
    s.authors  = ["Ronan Limon Duparcmeur"]
    s.files    = Dir["lib/**/*.rb"]
    s.license  = "MIT"
    s.homepage = "https://github.com/r3trofitted/steel_vellum"
    
    s.add_development_dependency "minitest"
    s.add_development_dependency "minitest-reporters"
  end
  ```

Note that said gemspec file features new declarations, including a 
[globbing approach](https://ruby-doc.org/3.2.2/Dir.html#method-c-glob) to list files, and a development dependency on 
[minitest-reporters](https://github.com/minitest-reporters/minitest-reporters), a Minitest plugin that improves the 
tests output, even when sticking to the defaults, like so:

  ```ruby?caption=test/steel_vellum_test.rb
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
  
  class SteelVellumTest < Minitest::Test
    # Let's add some!
  end
  ```

And _now_, we're [good to go](https://music.apple.com/fr/album/good-to-go/520098624)! Our detour is over and we're 
back on the road – see you in part 3!
