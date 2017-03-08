# TotalRecall [![build status](https://gitlab.com/eval/total_recall/badges/master/build.svg)](https://gitlab.com/eval/total_recall/commits/master)

Turn **any** csv-file into a [Ledger](http://ledger-cli.org/) journal.

## Introduction

`total_recall` assumes nothing about the structure of your csv, nor of the ledger-file you want to create.  
Instead, one creates a yaml-config consisting of:
* a [mustache-template](https://github.com/defunkt/mustache) of the ledger-file
* the source (and parse-options) of the csv
* the value of every template-variable via Ruby lambdas

## Example

After installation you run `total_recall init bank` to generate the following file:
```
# file: bank.yml
:total_recall:
  :version: 0.6.0
:template:
  :raw: |-
    ; -*- ledger -*-¬

    {{# transactions}}
    {{date}} {{{description}}}
      {{to}}    EUR {{amount}}
      {{from}}

    {{/ transactions}}

:csv:
  #:file: total_recall.csv
  :raw: |-
    "2013-11-01","Foo","2013-11-02","1.638,00"
    "2013-11-02","Bar","2013-11-03","-492,93"
  :options:
    #:col_sep: ";"
    #:headers: false

:context:
  :transactions:
    :__defaults__:
      :from: !!proc |
        ask_account("What account provides these transactions?", default: 'Assets:Checking')
    :date: !!proc row[0]
    :description: !!proc row[1]
    :amount: !!proc row[3]
    :to: !!proc |
      render_row(columns: [0, 1, 3])
      ask_account("To what account did the money go?")
```

The `template`-section is pretty straightforward: you can add any variable you need using the [mustache-syntax](http://mustache.github.io/mustache.5.html).  
The `csv`-section defines where csv comes from and what parse-options should be used. It's best to start with a csv-snippet in `raw` (and leave `file` commented) in order to test-run the config.

In the `context`-section the actual mapping is done: in this section your should define a key for every variable in the template.  
A key's value is derived from the csv via Ruby. This can be done via a simple mapping: `:date: !!proc row[0]`, via some specific operation: `:data: !!proc Date.parse(row[0]).iso8601` or via one of the [interactive helpers](https://gitlab.com/eval/total_recall/blob/v0.6.0/lib/total_recall.rb#L27-50) as you can see for the `to`-field above.  
Fields can also have default-values: the `from`-field for example is the same for all rows.

As it's all Ruby, you can make the mapping as smart as you like:
```
:context:
  :transactions:
    :description: !!proc row[3]
    :to: !!proc |
      guess = begin
        case self.description # the description-field is defined above
        when /CREDITCARD/ then "Liabilities:MasterCard"
        when /INTERNET/i then "Expenses:Communication"
        end
      end
      ask_account("To what account did the money go?", default: guess)
...
```

See [Extensibility](#extensibility) below for providing your own Ruby module with helpers (i.e. your own self-learning account-guesser!).

Once your config is done, you can give it a spin:
```bash
# the result will be echoed:
$ total_recall ledger -c bank.yml

# to quickly see if the output is actually valid ledger:
$ total_recall ledger -c bank.yml | ledger -f - reg
```

When the output looks good and doesn't make Ledger choke, you can uncomment the file-key in the csv-section and run it against the real csv-data:
```bash
$ total_recall ledger -c bank.yml > bank.dat
```

That's it!

To see an extensive annotated config-file do:
```bash
$ total_recall sample
```

## Install

```bash
gem install total_recall
```

## Usage

```bash
total_recall

# Commands:
#   total_recall help [COMMAND]              # Describe available commands or one specific command
#   total_recall init NAME                   # Generate a minimal config NAME.yml
#   total_recall ledger -c, --config=CONFIG  # Convert CONFIG to a ledger
#   total_recall sample                      # Generate an annotated config
#   total_recall version                     # Show total_recall version

# typically you would do:
total_recall init my-bank

# fiddle with the settings in 'my-bank.yml' and test-run it:
total_recal ledger -c my-bank.yml
# to skip prompts just provide dummy-data:
yes 'Dummy' | total_recal ledger -c my-bank.yml

# export it to a journal:
total_recall ledger -c my-bank.yml > my-bank.dat

# verify correctness with ledger:
ledger -f my-bank.dat bal
```

## Extensibility

You can extend the ledger subcommand by passing a file with additions to it:

```
total_recall ledger -c my-bank.yml -r ./my_extension.rb
```

This makes it possible to add helpers or redefine existing ones:

```ruby
cat my_extension.rb
module MyExtension
  # adding some options to an existing helper:
  def ask_account(question, options = {})
    question.upcase! if options.delete(:scream)
    super
  end

  # a new helper:
  def guess_account(question, options = {})
    guess = Guesser.new.guess
    ask_account(question, default: guess)
  end
end

TotalRecall::SessionHelper.include MyExtension
```

## Develop
    
```bash
git clone https://gitlab.com/eval/total_recall.git
cd total_recall
bundle
bundle exec rake spec
```
## Author

Gert Goet (eval) :: gert@thinkcreate.nl :: @gertgoet

## License

(The MIT license)

Copyright (c) 2017 Gert Goet, ThinkCreate

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

