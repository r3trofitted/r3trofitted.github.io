---
layout: post
title: 'Better practices by example: RSpec'
date: 2023-11-14 23:03 +0100
category: programming
---

Some time ago, I stumbled upon [an interesting technical test]({% link _posts/2023-11-02-humility-check.md %}). However, 
the more I looked at the provided Rails app, the more issues I found with it, to the point that I find it good material 
for an educational (hopefully) piece. But before I start, two disclaimers:

*   **This is not a rebuttal of the test itself.** And I'm certainly not trying to explain away my poor performance. The 
    test was fair and fine; it provided realistic and functioning[^1] code, similar to a lot of things I've seen in 
    actual applications. It just happens that the code, especially the specs, left room for improvement.
*   **The shortcomings in the code may be intentional**. It is an assessment app, after all. Maybe its code is 
    suboptimal because making it better wasn't worth the effort. Or maybe the shortcomings are deliberate, to better 
    assess the candidates. But that's not important.

What matters is not really where the following code comes from; the important thing is that it is a good example of 
something that _works_ but isn't quite _right_. And making it right is important in real life. (And fun, too.)

## The app and its tests ([`code here`](https://github.com/r3trofitted/pokebeep/tree/0_start_here))

You can find the repo [here](https://github.com/r3trofitted/pokebeep). To avoid spoiling the original test, I've changed 
the app description and the names of the models, controllers and other resources; I've also re-created the application 
instead of starting from the initial codebase. But apart from that, everything is the same, especially the tests.

And the tests are what I will focus on in this article. The application code doesn't matter, and could be anything, as 
long as it makes the tests pass. The latter are made of two specs files, plus a support file: 

*   `/specs/api_spec.rb` contains specs for the two endpoints of the app's API, `POST /beeps` and 
    `GET /summaries/{id}/{from}/{to}`.
*   `/specs/api_validation.rb` contains specs specific to the expected response when wrong parameters are sent to the API.
*   `/specs/public_api.rb` contains a collection of helpers for the specs above.

(Obviously, the testing framework used here is RSpec.)

Overall, these specs work, in that they break if the implementation is wrong and pass when it is right (except for a 
couple), but I have several issues with them nonetheless. Poor naming, poor organization, lack of idioms… None of these 
issues is deal-breaking in itself, but taken all together, they are a bit much. If I was reviewing these specs in a pull 
request, for example, I'd ask for a series of fixes[^2]:

## 1. That's how you get ants ([`code here`](https://github.com/r3trofitted/pokebeep/tree/1_ants))

RSpec is very polite and never _demands_ you to do anything (I believe that it is because its original author is Canadian). 
This is especially true when it comes to organizing your spec files: by default, RSpec only asks for files ending in `_spec.rb` 
in a `spec` directory, and even this [can be configured differently](http://rspec.info/documentation/3.12/rspec-core/RSpec/Core/Configuration.html).

`rspec-rails` is a little bit more structuring and suggests a canonical directory structure, in which files are placed 
according to the type of spec they contain: `/spec/models` for model specs, `/spec/system` for system specs, etc. Even 
if this organization is not mandatory[^3], it has at least two benefits. Being conventional, it makes the specs 
easier to contextualize and the suite easier to navigate. Also, it removes the need for some metadata, since RSpec can 
infer them from the layout.

And so, we'll start by moving the files around. Both `api_spec.rb` and `api_validation_spec.rb` contain 
[**request specs**](http://rspec.info/features/6-0/rspec-rails/request-specs/request-spec/): specs that use the whole 
stack, making actual[^4] HTTP requests that go through the router, controllers, etc. (The only difference with system 
specs is that the responses are not run by a browser, but asserted against as they are received.) The canonical place 
for such specs is thus `/spec/requests/`, and because the configuration option `infer_spec_type_from_file_location!` is 
on, we can remove the explicit declaration of the spec type by metadata, like so:

```ruby?caption=/spec/api_spec.rb (before)
# …
RSpec.describe 'public api', type: :request do
  # …
end
```

```ruby?caption=/spec/requests/api_spec.rb (after)
# …
RSpec.describe 'public api' do
  # …
end
```

As for the helpers file, I would prefer to put it in a dedicated directory, too. Once again, this is not mandated by 
RSpec, but by tradition support files go into a `/spec/support` directory, so this is where we'll 
place the `public_api.rb` file. And while we're at it, we'll rename it `api_helpers`, which is more fitting.

Having done so, we'd better rename the module defined within this file `ApiHelpers` instead of `PublicApi`. But instead 
of updating both the `api_spec.rb` and `api_validation_spec.rb` accordingly, we'll update RSpec's configuration.

Because the helper module is used by both specs groups, and both groups are made of request specs, we can configure RSpec 
to always include the module in any request spec. This is done by adding a line in the `rails_helper.rb` file, in 
the configuration block:

```ruby?caption=/spec/rails_helper.rb
# …
RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  # …
end
```

However, for this module to be available, the file `support/api_helpers.rb` must first be required. The easiest way to do so
 is to tell RSpec to preemptively require all the files in the `/spec/support` directory, which is as easy as uncommenting 
a line in the generated `rails_helper.rb` file:

```ruby?caption=/spec/rails_helper.rb
# …
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
# …
```

And now, instead of updating the `require` and the `include` instructions in the spec files, we can remove them 
altogether. For example, `api_spec.rb` now looks like this:

```ruby?caption=/spec/requests/api_spec.rb
require 'rails_helper'

RSpec.describe 'public api' do
  # …
end
```

Functionally, we haven't changed anything, but our `/spec` directory is much more idiomatic now, and we've trimmed 
a little bit of boilerplate from our spec files. Besides, keeping things neat and tidy prevents all kinds of bugs.

## 2. Phrasing! ([`code here`](https://github.com/r3trofitted/pokebeep/tree/2_phrasing))

The main benefit of RSpec is arguably the ability to express your tests as _specifications_. I mean, it's in the name! You 
don't _have_ to give your tests meaningful titles, as if each one was the description of a notable part of the system, 
but you lose half the value of RSpec if you don't. Which is why I love to run the suite with the option  
`--format=documentation`. When the specs are well named, you get a good understanding of the system; if they're not, you see it right away. 
Unfortunately, it is the case with the current output:

```console
> bin/rspec -fd

public api
  generates summary based on beeps
  rounds presence hours to two decimal places
  discovers problematic date when there is no leave beep
  discovers problematic date when there is skip day beep

api validation
  when posting beep with wrong request params
    returns 400 status code
    returns 400 status code
    returns 400 status code
    returns 400 status code
    returns 400 status code
    returns 400 status code
    returns 400 status code
  when getting summary with wrong request params
    returns 400 status code
    returns 400 status code
    returns 400 status code

Finished in 0.04608 seconds (files took 0.35083 seconds to load)
14 examples, 0 failures
```

The first part, about the public API, is not too bad; at least it reads properly. The part 
on the API validation, though, tells very little. Or rather, it tells very little _directly_. 
Indirectly, it hints that these tests were probably an after-thought, and because they read 
more like the truncated descriptions of unit tests, rather than integration tests, they sound 
like code smell. (Yes, programming can lead to synesthesia.)

Without changing their code, let's rename the specs so that the output reads better, and 
actually describes the behavior of the application, as a good specification document would.

When it comes to APIs, the best way to describe them is usually to go endpoint by endpoint. So 
let's start by grouping the examples by the endpoint they cover:

```ruby?caption=/spec/api_spec.rb (before)
RSpec.describe 'public api' do
  let(:first_pokemon) { 1 }
  let(:second_pokemon) { 2 }

  it 'generates summary based on beeps' do
    # …
  end

  it 'rounds presence hours to two decimal places' do
    # …
  end
end
```

```ruby?caption=/spec/api_spec.rb (after)
RSpec.describe 'public api' do
  let(:first_pokemon) { 1 }
  let(:second_pokemon) { 2 }
  
  describe 'GET /summaries/{pokemon_id}/{from}/{to}' do
    it 'generates summary based on beeps' do
      # …
    end
  
    it 'rounds presence hours to two decimal places' do
      # …
    end
  end
end
```

```ruby?caption=/spec/api_validation_spec.rb (before)
RSpec.describe 'api validation' do
  let(:now) { Time.now.to_i }

  context 'when posting beep with wrong request params' do
    it 'returns 400 status code' do
      # …
    end
    
    # …
  end
  
  context 'when getting summary with wrong request params' do
    it 'returns 400 status code' do
      # …
    end

    # …
  end
end
```

```ruby?caption=/spec/api_validation_spec.rb (after)
RSpec.describe 'api validation' do
  let(:now) { Time.now.to_i }
  
  describe 'POST /beeps' do
    context 'when posting beep with wrong request params' do
      it 'returns 400 status code' do
        # …
      end
      
      # …
    end
  end
  
  describe 'GET /summaries/{pokemon_id}/{from}/{to}' do
    context 'when getting summary with wrong request params' do
      it 'returns 400 status code' do
        # …
      end
    
      # …
    end
  end
end
```

A very small change, really, but it does improve the output:

```console
> bin/rspec -fd

public api
  GET /summaries/{pokemon_id}/{from}/{to}
    generates summary based on beeps
    rounds presence hours to two decimal places
    discovers problematic date when there is no leave beep
    discovers problematic date when there is skip day beep

api validation
  POST /beeps
    when posting beep with wrong request params
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
  GET /summaries/{pokemon_id}/{from}/{to}
    when getting summary with wrong request params
      returns 400 status code
      returns 400 status code
      returns 400 status code

Finished in 0.04671 seconds (files took 0.51821 seconds to load)
14 examples, 0 failures
```

Not only is this output closer to a decent specification, it also points out that our suite is not very well organized, 
since two different endpoints are featured in the same example group. More importantly, it also highlights holes in our 
test coverage: two endpoints are covered for validations, but only one when it comes to actual behavior. In other words: 
when we read these specs, we learn nothing about how the `POST /beeps` endpoint is supposed to work. And we have no 
reason to believe that it is tested.

To fix the first of these issues, let's move the examples around and replace the `api_spec.rb` and `api_validation_spec.rb` 
with two new ones, one per endpoint: `beeps_api_spec.rb` and `summaries_api_spec.rb`:

```ruby?caption=/spec/beeps_api_spec.rb
require 'rails_helper'

RSpec.describe 'Beeps API' do
  let(:now) { Time.now.to_i }

  describe 'POST /beeps' do
    context 'when posting beep with wrong request params' do
      # …
    end
  end
end
```

```ruby?caption=/spec/summaries_api_spec.rb
RSpec.describe 'Summaries API' do
  describe 'GET /summaries/{pokemon_id}/{from}/{to}' do
    let(:first_pokemon) { 1 }
    let(:second_pokemon) { 2 }
  
    it 'generates summary based on beeps' do
      # …
    end
  
    # …
    
    context 'when getting summary with wrong request params' do
      it 'returns 400 status code' do
        # …
      end
      
      # …
    end
  end
end
```

Once again, we've just moved code around, but once again the output is improved:

```console
> bin/rspec -fd

Summaries API
  GET /summaries/{pokemon_id}/{from}/{to}
    generates summary based on beeps
    rounds presence hours to two decimal places
    discovers problematic date when there is no leave beep
    discovers problematic date when there is skip day beep
    when getting summary with wrong request params
      returns 400 status code
      returns 400 status code
      returns 400 status code

Beeps API
  POST /beeps
    when posting beep with wrong request params
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code
      returns 400 status code

Finished in 0.04657 seconds (files took 0.53198 seconds to load)
14 examples, 0 failures
```

We'll deal with the absence (or not?) of tests for the `POST /beeps` endpoint a bit later; for now, let's get rid of 
the meaningless “returns 400 status code” repetition. The tests behind this sentence are useful; the issue is 
with their naming, because it doesn't explain what “wrong” means in each case. But this is easy to change, and thanks 
to the `#specify` alias for `#it`, the code can still read nicely, too:

```ruby?caption=/spec/summaries_api_spec.rb
RSpec.describe 'Summaries API' do
  describe 'GET /summaries/{pokemon_id}/{from}/{to}' do  
    # …
    
    describe 'validations' do
      specify 'passing an invalid {from} parameter returns a 400 status code ' do
        # …
      end
      
      specify 'passing an invalid {to} parameter returns a 400 status code' do
        # …
      end
      
      specify 'passing an invalid {pokemon_id} parameter returns a 400 status code' do
        # …
      end
    end
  end
end
```

```console
> bin/rspec spec/requests/summaries_api_spec.rb -fd --order=random

Randomized with seed 32383

Summaries API
  GET /summaries/{pokemon_id}/{from}/{to}
    rounds presence hours to two decimal places
    discovers problematic date when there is no leave beep
    generates summary based on beeps
    discovers problematic date when there is skip day beep
    validations
      passing an invalid {pokemon_id} parameter returns a 400 status code
      passing an invalid {to} parameter returns a 400 status code
      passing an invalid {from} parameter returns a 400 status code

Finished in 0.04017 seconds (files took 0.52537 seconds to load)
7 examples, 0 failures

Randomized with seed 32383
```

(Quick aside: note that I've kept a common group for the tests about validation, aptly named “validations”, even if it 
doesn't add much to the complete specification. That is because, otherwise, the validations specs could end up mixed up 
with the other specs in the output when the suite is run in random order[^5], and that wouldn't read well.)

Always work from the outside to the inside: now that everything is well organized and well labeled, we can start improving the code itself.

## 3. Danger Zone ([`code here`](https://github.com/r3trofitted/pokebeep/tree/3_danger_zone))

At its core, a test is made up of 4 phases: setup, execution, assertion and teardown. (The names may vary but the 
idea is always the same.) The setup and/or teardown phases are often skipped or hidden away, but a test without clear 
execution and assertion phases is a strong code smell. At best, it is probably a case of excessive abstraction; at 
worst, it is a case of excessive abstraction which hides an error in the test.

Looking at the specs for the Beeps API, this is exactly what we see: they have no setup, no teardown, but above all no 
assertion phase. In code terms, there is no call to `#expect`:

```ruby?caption=/spec/requests/beeps_api_spec.rb
require 'rails_helper'

RSpec.describe 'Beeps API' do
  let(:now) { Time.now.to_i }

  describe 'POST /beeps' do
    specify 'posting without any parameter returns a 400 status code' do
      post_beep({})
    end

    specify 'posting without a :pokemon_id parameter returns a 400 status code' do
      post_beep({ pokemon_id: nil, kind: :in, timestamp: now })
    end

    specify 'posting without a :kind parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: nil, timestamp: now })
    end

    specify 'posting without a :timestamp parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: :in, timestamp: nil })
    end

    specify 'posting with an invalid :pokemon_id parameter returns a 400 status code' do
      post_beep({ pokemon_id: 'bad', kind: :in, timestamp: now })
    end

    specify 'posting with an invalid :kind parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: 'bad', timestamp: now })
    end

    specify 'posting with an invalid :timestamp parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: :in, timestamp: 'bad' })
    end
  end
end
```

At first, the specs may seem to work, because there is no action in the controller, which triggers an error, so the tests 
are red. But even an rigged implementation of `BeepsController#save` would be enough to make the specs pass, when they 
shouldn't:

```ruby?caption=/app/controllers/beeps_controller.rb
class BeepsController < ApplicationController
  def save = head(:ok) # SLIME
end
```

```console
> bin/rspec spec/requests/beeps_api_spec.rb
.......

Finished in 0.02176 seconds (files took 0.35128 seconds to load)
7 examples, 0 failures
```

We need to add proper assertions to ensure that we are actually testing what we claim to be testing:

```ruby?caption=/spec/request/beeps_api_spec.rb
require 'rails_helper'

RSpec.describe 'Beeps API' do
  let(:now) { Time.now.to_i }

  describe 'POST /beeps' do
    specify 'posting without any parameter returns a 400 status code' do
      post_beep({})
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :pokemon_id parameter returns a 400 status code' do
      post_beep({ pokemon_id: nil, kind: :in, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :kind parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: nil, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :timestamp parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: :in, timestamp: nil })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :pokemon_id parameter returns a 400 status code' do
      post_beep({ pokemon_id: 'bad', kind: :in, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :kind parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: 'bad', timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :timestamp parameter returns a 400 status code' do
      post_beep({ pokemon_id: 1, kind: :in, timestamp: 'bad' })
      expect(response).to have_http_status(:bad_request)
    end
  end
end
```

Now the specs fail, and we can replace our slime with a proper implementation. (I won't show any here, since we're 
focusing on the tests.)

## 4. I swear to God, I had something for this. ([`code here`](https://github.com/r3trofitted/pokebeep/tree/4_i_had_something))

At this point, we've dealt with the strongest code smells or messiness. But I'd like to see if we can _remove_ 
code, especially if we are to _add_ some later. (After all, by tidying up, we've apparently revealed missing specs 
for the Beeps API). Helpers are good candidates for such trimming, because, as a codebase evolves, they can easily stop 
being used, and yet they're rarely removed. Let's look at those we have.

*   `#post_beep` makes a call to the `POST /beeps` endpoint.
*   `#get_summary` makes a call to the `GET /summaries` endpoint.
*   `#summary` makes a call to the `GET /summaries` endpoint, makes an assertion against the response, and parses the 
    received payload.
*   `#given_beep` makes a call to the `POST /beeps` endpoint, and makes an assertion against the response.

The single responsibility principle doesn't always apply to functions, but it's still a good rule of thumb. On this 
account, `#summary` and `#given_beep` are suspicious; let's put them aside for later and consider the simpler `#post_beep` 
and `#get_summary` helpers instead.

Interestingly, these methods do very little; but at the same time, _what_ they do is rather significant, since calling 
the API is usually the heart of the “execution” phase of an API test. For these two reasons, I'd like to get rid of 
them: they don't bring anything, but add a layer of indirection to our tests, and they do it in the exception phase, 
were clarity is the most important.

Because these helpers do so little, removing them is very easy:

```ruby?caption=/spec/requests/beeps_api_spec.rb (before)
# …
specify 'posting without any parameter returns a 400 status code' do
  post_beep({})
  expect(response).to have_http_status(:bad_request)
end
# …
```

```ruby?caption=/spec/requests/beeps_api_spec.rb (after)
# …
specify 'posting without any parameter returns a 400 status code' do
  post('/beeps', params: {})
  expect(response).to have_http_status(:bad_request)
end
# …
```

```ruby?caption=/spec/requests/summaries_api_spec.rb (before)
# …
specify 'passing an invalid {from} parameter returns a 400 status code ' do
  get_summary(1, 'bad', '2019-01-01')
  expect(response.status).to eq(400)
end
# …
```

```ruby?caption=/spec/requests/summaries_api_spec.rb (after)
# …
specify 'passing an invalid {from} parameter returns a 400 status code ' do
  get('/summaries/1/bad/2019-01-01')
  expect(response.status).to eq(400)
end
# …
```

To be fair, one could argue that the code that calls the Summaries API is a bit _less_ legible than when going through 
the `get_summary` helper, because the parameters stand out less when put inside the URL. It is a rather subjective 
tradeoff, and I could understand how a team would prefer the indirection of helper. However, _I_ prefer to get rid of it. 
Less code, less indirection, less chance of a bug.

## 5. The cumulative hangover will kill me. ([`code here`](https://github.com/r3trofitted/pokebeep/tree/5_hangover))

Now that we've dealt with the easy helpers, let's look at the two suspicious ones – those that do more than one single 
thing, `#summary` and `#given_beep`.

The problem with both is that, among their multiple responsibilities, they do assertions. It's actually a double issue:

-   Like with the expectations in the preceding helpers, the assertions are so central to a test that they shouldn't be 
    hidden away in a helper.
-   These assertions are mixed with other things, are thus executed outside of the assertion phase.

You could argue that the 4-phases structure is too rigid, or that adding _extra_ assertions when doing something is like 
a freebie, a bonus protection against regressions. I disagree, especially with the later. Having assertions outside of 
the assertion phase, or unrelated to whatever the test is about, makes the test harder to understand. And because they 
are so fundamental to the longevity of a system, tests need to be very easy to understand. That is true as soon as the 
test is run; a failure message unrelated to the test case is perplexing and breaks the flow. Compare for example these 
two failures on the same test:

```console
> bin/rspec spec/requests/summaries_api_spec.rb:24 -fd
Run options: include {:locations=>{"./spec/requests/summaries_api_spec.rb"=>[24]}}

Summaries API
  GET /summaries/{pokemon_id}/{from}/{to}
    rounds presence hours to two decimal places (FAILED - 1)

Failures:

  1) Summaries API GET /summaries/{pokemon_id}/{from}/{to} rounds presence hours to two decimal places
     Failure/Error: expect(summary[:presence_hours]).to eq(7.83)
     
       expected: 7.83
            got: 7.833611111111111
     
       (compared using ==)
     # ./spec/requests/summaries_api_spec.rb:30:in `block (3 levels) in <top (required)>'

Finished in 0.03138 seconds (files took 0.49168 seconds to load)
1 example, 1 failure
```

```console
> bin/rspec spec/requests/summaries_api_spec.rb:24 -fd
Run options: include {:locations=>{"./spec/requests/summaries_api_spec.rb"=>[24]}}

Summaries API
  GET /summaries/{pokemon_id}/{from}/{to}
    rounds presence hours to two decimal places (FAILED - 1)

Failures:

  1) Summaries API GET /summaries/{pokemon_id}/{from}/{to} rounds presence hours to two decimal places
     Failure/Error: expect(response.status).to eq(200)
     
       expected: 200
            got: 400
     
       (compared using ==)
     # ./spec/support/api_helpers.rb:5:in `given_beep'
     # ./spec/requests/summaries_api_spec.rb:25:in `block (3 levels) in <top (required)>'

Finished in 0.03106 seconds (files took 0.48556 seconds to load)
1 example, 1 failure
```

In the first case, there is a direct relation between the expected result (“rounds presence hours”) and the error 
(“expected 7.83, got 7.833611111111111”); in the second, the failure is at the HTTP response level, not the rounding 
of a value.

The `#given_beep` method is meant to be used to set up the test, preparing the necessary data in the setup phase. So 
let's remove anything that is not related to this. In fact, since we **don't** want to test the API during this phase, 
there is no need to even use it. We can create the data directly instead.

```ruby?caption=/spec/support/api_helpers.rb (before)
module ApiHelpers
  def given_beep(pokemon_id: 1, timestamp: Time.zone.now, kind: :in)
    t = to_unix(timestamp)
    post('/beeps', params: { pokemon_id:, timestamp: t, kind: })
    expect(response.status).to eq(200)
  end
  # …
end
```

```ruby?caption=/spec/support/api_helpers.rb (after)
module ApiHelpers
  def given_beep(pokemon_id: 1, timestamp: Time.zone.now, kind: :in)
    Beep.create! pokemon_id:, kind:, timestamp: to_unix(timestamp)
  end
  # …
end
```

Following the same principle, the `#summary` helper can be stripped of its call to `#expect`. However, there is a 
difference with `#given_beep`: `#summary` is used in the execution phase, and as we've seen above, it can be better to 
avoid hiding away the job done during this phase behind an indirection. Like with the `#get_summary` helper, it's hard 
for me to be very categorical; both styles have advantages. However, one thing is certain: if my team opted to keep the 
helper, I would require it to have a better name that explicitly conveys the idea that the endpoint is called and its 
response parsed. So here would be the two options:

```ruby?caption=removing the helper
it 'rounds presence hours to two decimal places' do
  given_beep(pokemon_id: first_pokemon, timestamp: '2019-05-01 08:10:00:050', kind: :in)
  given_beep(pokemon_id: first_pokemon, timestamp: '2019-05-01 16:00:01:070', kind: :out)

  get("/summaries/#{pokemon_id}/2019-05-01/2019-05-01")
  summary = JSON.parse(response.body).symbolize_keys

  expect(summary[:presence_hours]).to eq(7.83)
end
```

```ruby?caption=keeping the helper
it 'rounds presence hours to two decimal places' do
  given_beep(pokemon_id: first_pokemon, timestamp: '2019-05-01 08:10:00:050', kind: :in)
  given_beep(pokemon_id: first_pokemon, timestamp: '2019-05-01 16:00:01:070', kind: :out)

  summary = parsed_summary_from_api(pokemon_id: first_pokemon, from: '2019-05-01', to: '2019-05-01')

  expect(summary[:presence_hours]).to eq(7.83)
end
```

Personally, I chose to go with the former. (In part because I couldn't find the helper's name clear enough.)

## 6. Rampage! ([`code here`](https://github.com/r3trofitted/pokebeep/tree/6_rampage))

We've reorganized the tests (files included), removed cruft and boilerplate, and fixed conceptual errors in some of 
the tests. Before taking a step back and looking at our renovated suite, let's clean up a bit:

-   The `#to_unix` helper is only used once now, so it can be removed and it's relevant code used directly instead.
-   Since `#given_beep` is the only helper method left, and it only used in a single group, it can be moved there, and 
    the whole support file can be deleted. (To be honest, we could also get rid of the helper altogether.)
-   In the specs for the Summaries API, all the test use the same value for the `pokemon_id` parameter, so none of 
    the two `let` calls (`let(:first_pokemon` and `let(:second_pokemon`) are of any use and can be deleted, too.
-   Some of the specs for the Summaries API are about a portion only of the summary, so there is no need to 
    make assertions against the whole JSON object.
-   The canonical file structure of RSpec Rails allows the `/requests` directory to be named `/api` instead, which 
    is fitting here, so we'll rename it.

In the end, we're back to a vanilla RSpec configuration and a suite composed of two files, one for each endpoint:

```ruby?caption=/spec/api/beeps_api_spec.rb
require 'rails_helper'

RSpec.describe 'Beeps API' do
  let(:now) { Time.now.to_i }

  describe 'POST /beeps' do
    specify 'posting without any parameter returns a 400 status code' do
      post('/beeps', params: {})
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :pokemon_id parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: nil, kind: :in, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :kind parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: 1, kind: nil, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting without a :timestamp parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: 1, kind: :in, timestamp: nil })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :pokemon_id parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: 'bad', kind: :in, timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :kind parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: 1, kind: 'bad', timestamp: now })
      expect(response).to have_http_status(:bad_request)
    end

    specify 'posting with an invalid :timestamp parameter returns a 400 status code' do
      post('/beeps', params: { pokemon_id: 1, kind: :in, timestamp: 'bad' })
      expect(response).to have_http_status(:bad_request)
    end
  end
end
```

```ruby?caption=/spec/api/summaries_api_spec.rb
require 'rails_helper'

RSpec.describe 'Summaries API' do
  def given_beep(pokemon_id: 1, timestamp: Time.zone.now, kind: :in)
    Beep.create! pokemon_id:, kind:, timestamp: Time.parse(timestamp).to_i
  end
  
  describe 'GET /summaries/{pokemon_id}/{from}/{to}' do
    it 'generates summary based on beeps' do
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 08:00', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 16:00', kind: :out)
      given_beep(pokemon_id: 1, timestamp: '2019-05-02 08:00', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-02 16:00', kind: :out)
  
      get("/summaries/1/2019-05-01/2019-05-30")
      summary = JSON.parse(response.body).symbolize_keys
  
      expect(summary).to include({
                                  pokemon_id: 1,
                                  from: '2019-05-01', to: '2019-05-30',
                                  presence_hours: 16.0,
                                  problematic_dates: []
                                })
    end
  
    it 'rounds presence hours to two decimal places' do
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 08:10:00:050', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 16:00:01:070', kind: :out)
  
      get("/summaries/1/2019-05-01/2019-05-01")
      summary = JSON.parse(response.body).symbolize_keys
  
      expect(summary[:presence_hours]).to eq(7.83)
    end
  
    it 'discovers problematic date when there is no leave beep' do
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 08:00', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-02 08:00', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-02 16:00', kind: :out)
      
      get("/summaries/1/2019-05-01/2019-05-30")
      summary = JSON.parse(response.body).symbolize_keys
  
      expect(summary).to include(presence_hours: 8.0, problematic_dates: ['2019-05-01'])
    end
  
    it 'discovers problematic date when there is skip day beep' do
      given_beep(pokemon_id: 1, timestamp: '2019-05-01 08:00', kind: :in)
      given_beep(pokemon_id: 1, timestamp: '2019-05-02 16:00', kind: :out)
  
      get("/summaries/1/2019-05-01/2019-05-30")
      summary = JSON.parse(response.body).symbolize_keys
  
      expect(summary).to include(presence_hours: 0.0, problematic_dates: ['2019-05-01', '2019-05-02'])
    end
    
    describe "validations" do
      specify 'passing an invalid {from} parameter returns a 400 status code ' do
        get('/summaries/1/bad/2019-01-01')
        expect(response.status).to eq(400)
      end
    
      specify 'passing an invalid {to} parameter returns a 400 status code' do
        get('/summaries/1/2019-01-01/bad')
        expect(response.status).to eq(400)
      end
    
      specify 'passing an invalid {pokemon_id} parameter returns a 400 status code' do
        get('/summaries/bad/2019-01-01/2019-02-02')
        expect(response.status).to eq(400)
      end
    end
  end
end
```

Running the specs, we have a nice specification of the API:

```console
> bin/rspec -fd

Beeps API
  POST /beeps
    posting without any parameter returns a 400 status code
    posting without a :pokemon_id parameter returns a 400 status code
    posting without a :kind parameter returns a 400 status code
    posting without a :timestamp parameter returns a 400 status code
    posting with an invalid :pokemon_id parameter returns a 400 status code
    posting with an invalid :kind parameter returns a 400 status code
    posting with an invalid :timestamp parameter returns a 400 status code

Summaries API
  GET /summaries/{pokemon_id}/{from}/{to}
    generates summary based on beeps
    rounds presence hours to two decimal places
    discovers problematic date when there is no leave beep
    discovers problematic date when there is skip day beep
    validations
      passing an invalid {from} parameter returns a 400 status code
      passing an invalid {to} parameter returns a 400 status code
      passing an invalid {pokemon_id} parameter returns a 400 status code

Finished in 0.04601 seconds (files took 0.53933 seconds to load)
14 examples, 0 failures
```

Overall, I'd say that this we've done a pretty good job at turning something that just worked into something that 
is right. However, there is one last thing that we can do, and that is adding missing tests.

## 7. You're not my supervisor! ([`code here`](https://github.com/r3trofitted/pokebeep/tree/7_supervisor))

The specs for the Summaries API cover both its correct use (including edge cases) and its incorrect use, under the 
umbrella of “validations”. This is good. These specs are technically high-level integration tests, so I would advice 
to stick to testing the happy path, but because there are no low-level unit tests for the other cases, doing a bit 
more is fine. However, the specs for the Beeps API only cover the incorrect uses – no happy path, only the sad ones.

It wasn't _that_ bad so far because the happy path was sort of tested accidentally, through the misplaced assertion in 
the `#given_beep` helper. Now that we've remove this, there are no guardrails to prevent us from breaking the API 
and not realizing it. But adding such a spec is very easy:

```ruby?caption=/spec/api/beeps_api_spec.rb
require 'rails_helper'

RSpec.describe 'Beeps API' do
  let(:now) { Time.now.to_i }

  describe 'POST /beeps' do
    it 'creates a Beep' do
      expect {
        post('/beeps', params: { pokemon_id: 1, kind: :in, timestamp: now })
      }.to change { Beep.count }.by(1)
      expect(response).to have_http_status(:ok)
    end
    
    describe 'validations' do
      specify 'posting without any parameter returns a 400 status code' do
        post('/beeps', params: {})
        expect(response).to have_http_status(:bad_request)
      end
      # …
    end
  end
end
```

Apart from wrapping the validation specs in a `describe` block for readability's sake when running the suite in random 
order, we've added a single test for the API's happy path. Note the unusual look of this test; because we're using 
the [`#change` matcher](http://rspec.info/features/3-12/rspec-expectations/built-in-matchers/change/), the code for the 
execution phase is somehow sandwiched between assertions, but there are still two distinct phases.

This test is also notable for another thing: even though it is technically high-level, we're making a low-level 
assertion, checking directly the database instead of going only through the API. I find this infringement of the 
Orthodoxy of the Test Pyramid justified here, since we have no lower-level tests anyway. YMMV.

And that's a wrap! Polishing is fun and we could keep doing it (for example by introducing unit tests to reduce the 
surface area of the request specs), but good enough if fine, and in real life, our time would probably be best spent 
somewhere else. So let's move on, and enjoy our descriptive, exhaustive and yet lean specs!

---

[^1]: With one exception.
[^2]: Or kindly lead the PR author towards these fixes without directly _asking_ for them. 
[^3]: _"RSpec Rails provides thoughtfully selected features to encourage good testing practices, but there’s no “right” 
      way to do it. Ultimately, it’s up to you to decide how your test suite will be composed."_  
      ([https://github.com/rspec/rspec-rails#what-tests-should-i-write](https://github.com/rspec/rspec-rails#what-tests-should-i-write))

[^4]: Well, _kinda_. No data will go through the network, but the application will behave exactly as if.
[^5]: Which should always be the case, by the way.
