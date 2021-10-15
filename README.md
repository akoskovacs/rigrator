# rigrator

Rigrator is a database migration tool written in Crystal.

It is inspired by [goose](https://bitbucket.org/liamstask/goose/). Some code was ported from there too, so check it out.

Rigrator currently supports migrations for Postgres, Mysql and SQLite3, but it should be easy to add support for any other database engine with an existing [crystal-db API](https://github.com/crystal-lang/crystal-db) driver.

## Command line

To install the standalone binary tool check out the releases page, or use homebrew:

```
$ brew tap amberframework/rigrator
$ brew install rigrator
```

Execute `rigrator help` for usage instructions. Rigrator will connect to the database specified by the `DATABASE_URL` environment variable.

To create a new migration use the `scaffold` subcommand. For example, `rigrator scaffold add_users_table` will create a new SQL migration file with a name such as `db/migrations/20160524162446_add_users_table.sql` that looks like this:

```sql
-- +rigrator Up
-- SQL in section 'Up' is executed when this migration is applied


-- +rigrator Down
-- SQL section 'Down' is executed when this migration is rolled back
```

Comments that start with `+rigrator` are interpreted by rigrator when running your migrations. In this case, the `Up` and `Down` directives are used to indicate which SQL statements must be run when applying or reverting a migration. You can now go along and write your migration like this:

```sql
-- +rigrator Up
CREATE TABLE users(id INT PRIMARY KEY, email VARCHAR NOT NULL);

-- +rigrator Down
DROP TABLE users;
```
Now run it using `rigrator up`. This command will execute all pending migrations:

```
$ rigrator up
Migrating db, current version: 0, target: 20160524162947
OK   20160524162446_add_users_table.sql

$ rigrator dbversion # at any time you can find out the current version of the database
20160524162446
```

If you ever need to roll back the last migration, you can do so by executing `rigrator down`. There's also `rigrator redo` which rolls back the last migration and applies it again. Last but not least: use `rigrator status` to find out the state of each migration:

```
$ rigrator status
Applied At                  Migration
=======================================
2016-05-24 16:31:07 UTC  -- 20160524162446_add_users_table.sql
Pending                  -- 20160524163425_add_address_to_users.sql
```

If using complex statements that might contain semicolons, you must give rigrator a hint on how to split the script into separate statements. You can do this with `StatementBegin` and `StatementEnd` directives: (thanks [goose](https://bitbucket.org/liamstask/goose/) for this!)

```
-- +rigrator Up
-- +rigrator StatementBegin
CREATE OR REPLACE FUNCTION histories_partition_creation( DATE, DATE )
returns void AS $$
DECLARE
  create_query text;
BEGIN
  FOR create_query IN SELECT
      'CREATE TABLE IF NOT EXISTS histories_'
      || TO_CHAR( d, 'YYYY_MM' )
      || ' ( CHECK( created_at >= timestamp '''
      || TO_CHAR( d, 'YYYY-MM-DD 00:00:00' )
      || ''' AND created_at < timestamp '''
      || TO_CHAR( d + INTERVAL '1 month', 'YYYY-MM-DD 00:00:00' )
      || ''' ) ) inherits ( histories );'
    FROM generate_series( $1, $2, '1 month' ) AS d
  LOOP
    EXECUTE create_query;
  END LOOP;  -- LOOP END
END;         -- FUNCTION END
$$
language plpgsql;
-- +rigrator StatementEnd
```

## API

To use the Crystal API, add this to your application's `shard.yml`:

```yaml
dependencies:
  rigrator:
    github: akoskovacs/rigrator
```

This allows you to programatically use rigrator's features. You'll see the `Rigrator` module has an equivalent for every CLI command. If you need to use rigrator's CLI without installing the tool (which could be convenient in a CI environment), you can write a runner script as follows:

```crystal
#! /usr/bin/env crystal
#
# To build a standalone command line client, require the
# driver you wish to use and use `Rigrator::Cli`.
#

require "rigrator"
require "pg"

Rigrator::DB.connection_url = "postgresql://..."
Rigrator::Cli.run
```

## Contributing

1. Fork it ( https://github.com/akoskovacs/rigrator/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [juanedi](https://github.com/juanedi)  - creator, maintainer of rigrator which is rigrator was forked from
- [akoskovacs](https://github.com/akoskovacs)  - creator, maintainer of rigrator
