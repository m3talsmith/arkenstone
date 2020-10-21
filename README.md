# Arkenstone [![Build Status](https://travis-ci.org/RevSpringPhoenix/arkenstone.png?branch=master)](https://travis-ci.org/RevSpringPhoenix/arkenstone) [![Code Climate](https://codeclimate.com/github/RevSpringPhoenix/arkenstone.png)](https://codeclimate.com/github/RevSpringPhoenix/arkenstone)

Arkenstone is a replacement for [ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) that uses RESTful services to get and store data.

## Installation

Add this line to your application's Gemfile:

    gem 'arkenstone'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install arkenstone

## Usage

Include the `Arkenstone::Document` module in your class, set the `url` and `attributes` and away you go.

    class User
      include Arkenstone::Document

      url 'http://example.com/users/'
      attributes :name, :age, :gender
    end

`User` instances will have accessor properties for `:name`, `:age`, and `:gender`. You can also `save`, and `update_attributes` as well:

    my_user = User.create(name: 'Thorin', age: 195, gender: 'M', bearded: true)

This will make a `POST` to `http://example.com/users/`. If json data is returned from the server, it will be applied to the attributes of the object.

How about updating?

    # Assuming Thorin has an id of 1
    thorin = User.find(1)

    # Thorin lost a bet and shaved... well you know how bets go!
    thorin.update_attribute :bearded, false

This does a `PUT` to `http://example.com/users/1`. Again, returning json is translated back into a usable Thorin.

You can also change attributes using `#update_attributes` or setting them at a field level and saving.

    # Thorin didn't shave for a day
    thorin = User.find(1)
    thorin.bearded = true
    thorin.save

`Arkenstone` knows if you're a new object or not and properly uses `POST` or `PUT` where needed.

Here is a list of `RESTful` expectations that come with the library:

```ruby
Model.find(1)                                                               # => GET http://example.com/1
Model.all                                                                   # => GET http://example.com
Model.new.save                                                              # => POST http://example.com
Model.find(1).save                                                          # => PUT http://example.com/1
Model.find(1).update_attribute(:attribute, 'value')                         # => PUT http://example.com/1
Model.find(1).update_attributes(attribute1: 'value1', attribute2: 'value2') # => PUT http://example.com/1
Model.find(1).destroy                                                       # => DELETE http://example.com/1
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The MIT License (MIT)

Arkenstone: a lightweight json active model like framework.

Copyright (C) 2020 Michael Christenson II

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
