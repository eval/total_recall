# 0.7.0 / unreleased

* modernize for Ruby 3.3+

  - target Ruby >= 3.3.0, test on 3.3 and 3.4
  - update all dependencies (thor 1.x, terminal-table 3.x, highline 3.x)
  - use `YAML.unsafe_load_file` (required since Ruby 3.1 for custom YAML types)
  - add frozen_string_literal to all Ruby files

* switch to GitHub Actions CI with release workflow

  - add `.github/workflows/main.yml` for CI
  - add `.github/workflows/release.yml` for automated gem publishing on tag push
  - remove `.gitlab-ci.yml`

* add mise.toml for Ruby version management

* '--version' and '-v' handled by version-subcommand

* pass csv-file to ledger-subcommand:

    ```bash
    $ total_recall ledger -c bank.yml --csv ~/Downloads/bank.csv
    ```

* init-subcommand skips yml-extension if provided

* remove duplicate `exe/total_recall.rb`


# 0.6.0 / 2017-03-08

* move repository to GitLab

* upgrade dependencies

* added option to use only transaction-section from template

    This makes adding transactions to an existing ledger-file easier.

    ```bash
    $ total_recall ledger -c bank.yml --transactions-only >> bank.dat
    ```

# 0.5.0 / 2014-06-11

* extend the ledger subcommand by passing it a file with customizations

    ```ruby
    $ cat my_extension.rb
    module MyExtension
      def ask_account(*args)
        # some custom stuff
        super
      end
    end
    TotalRecall::SessionHelper.include MyExtension

    $ total_recall ledger -c sample.yml -r ./my_extension.rb
    ```

* add version subcommand

* add default-helper

    Let's you point to the default-value of an attribute:

    ```yaml
    :context:
      :transactions:
        :__defaults__:
          :a: 1
        :a: !!proc |
          ask("What value has a?", default: default)
    ```

* add transaction-helper

    This allows you to use already set attributes of the transaction:

    ```yaml
    :context:
      :transactions:
        :a: 1
        :b: !!proc |
          transaction.a.succ
    ```

# 0.4.0 / 2014-06-04

* Add yaml-config.
