# TotalRecall [![travis](https://secure.travis-ci.org/eval/total_recall.png?branch=master)](https://secure.travis-ci.org/#!/eval/total_recall)

Turn **any** csv-file into a [Ledger](http://ledger-cli.org/) journal.

## Install

```bash
gem install total_recall
```

## Quickstart

### Generate a sample config

```bash
total_recall sample
# An annotated config 'sample.yml' will be written to the current directory.
```

### Generate a ledger

The sample config contains 2 transactions.  
Let's get 'em in a journal:

```bash
total_recall ledger -c sample.yml > sample.dat
# What account provides these transactions?  |Assets:Checking|
#
# +------------+-----+----------+
# | 03.11.2013 | Foo | 1.638,00 |
# +------------+-----+----------+
# To what account did the money go?
# Expenses:Foo
# +------------+-----+---------+
# | 03.11.2013 | Bar | -492,93 |
# +------------+-----+---------+
# To what account did the money go?
# Expenses:Bar
```
Now verify the ledger file:

```bash
ledger -f sample.dat balance

#         $ -1.145,07  Assets:Checking
#          $ 1.145,07  Expenses
#           $ -492,93    Bar
#          $ 1.638,00    Foo
#--------------------
#                   0
```

### Now what?

May I suggest:
* read `sample.yml`

  It explains what options are available.
* put your own csv in `sample.yml` and adjust the context

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

```
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
git clone git://github.com/eval/total_recall.git
cd total_recall
bundle
bundle exec rake spec
```
## Author

Gert Goet (eval) :: gert@thinkcreate.nl :: @gertgoet

## License

(The MIT license)

Copyright (c) 2014 Gert Goet, ThinkCreate

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

