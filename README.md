# Texter

A Collection of base NLP toolz.

- language detection
- stopword filter

## Installation

Install the gem and add to the application's Gemfile by executing:
```shell
$ bundle add aredotna/texter
```


## API

The `Texter::Content` object:
```ruby
tc = Texter::Content.new(text: 'some longer text')
tc.lang       #=> 'en', language iso code
tc.paragraphs #=> ["some longer text"], splits text on newline, etc
tc.filtered   #=> "longer text", removes stopwords
```


## Development

iunstall dependencies:
```shell
$ bundle install
```
run specs:
```shell
bundle exec rspec
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aredotna/texter.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
