# RSpec::EventMachine

This library provides some extensions to RSpec that make testing
EventMachine-based applications easier. It includes functionality for running
asynchronous code in tests, and for stubbing out the EventMachine timer methods.


## Installation

```
$ gem install rspec-eventmachine
```


## Usage

The library includes two main modules: `AsyncSteps` facilities the writing of
tests with async logic, and `FakeClock` stubs out timer methods.


### `AsyncSteps`

To keep async tests clean, it helps to implement all the separate logical steps
in them as separate functions. Using `AsyncSteps`, you write a module
containing definitions of all your test steps, where each method takes a
callback. You then mix this module into your tests, and you can use the methods
without callbacks to write terse, flat tests.

```rb
require "rspec/em"

MathSteps = RSpec::EM.async_steps do
  def add(x, y, &callback)
    EM.add_timer 0.1 do
      @result = x + y
      callback.call
    end
  end

  def multiply(f, &callback)
    EM.add_timer 0.2 do
      @result = @result * f
      callback.call
    end
  end

  def check_result(n, &callback)
    expect(@result).to eq(n)
    callback.call
  end
end

describe "Math" do
  include MathSteps

  it "adds and multiplies" do
    add 3, 4
    multiply 5
    check_result 35
  end
end
```

Note that you must put all the logic in the async steps module. The method calls
in your `before`, `after` and `it` blocks are really just adding the named
methods and arguments to a queue, which `AsyncSteps` executes sequentially by
calling each method when the previous one invokes its callback. `AsyncSteps`
also makes sure that the reactor is running for the duration of each test, and
catches and reports any errors or failures that happen during the test.


### `FakeClock`

The `FakeClock` module lets you freeze time and move it forward by hand, to test
code that uses the EventMachine `add_timer` and `add_periodic_timer` methods.

```rb
require "rspec/em"

describe "Math" do
  include RSpec::EM::FakeClock

  before { clock.stub }
  after { clock.reset }

  it "adds and multiplies" do
    value = 0
    EM.add_timer(1) { value += 3 }
    EM.add_timer(3) { value *= 2 }

    clock.tick(2)
    expect(value).to eq(3)
    clock.tick(2)
    expect(value).to eq(6)
  end
end
```


## License

Copyright (c) 2011-2013 James Coglan

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

