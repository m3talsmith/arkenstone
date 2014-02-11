# Arkenstone

Arkenstone is a replacement for [ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Base.html) that "saves" models over RESTful services.

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

    my_user = User.new
    my_user.name = 'Thorin'
    my_user.age = 195
    my_user.gender = 'M'
    my_user.bearded = true
    my_user.save

This will make a `POST` to `http://example.com/users/`. If json data is returned from the server, it will be applied to the attributes of the object.

more tk.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
