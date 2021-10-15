require "./spec_helper"

Spectator.describe Rigrator do
  describe "splitting in statements" do
    it "split simple statements" do
      migration = Rigrator::Migration.new(20160101120000, "foo.sql", "\
-- +rigrator Up
CREATE TABLE foo(id INT PRIMARY KEY, name VARCHAR NOT NULL);

-- +rigrator Down
DROP TABLE foo;")

      statements(migration, :forward).should eq([
        "-- +rigrator Up\nCREATE TABLE foo(id INT PRIMARY KEY, name VARCHAR NOT NULL);",
      ])

      statements(migration, :backwards).should eq([
        "-- +rigrator Down\nDROP TABLE foo;",
      ])
    end

    it "splits mixed Up and Down statements" do
      migration = Rigrator::Migration.new(20160101120000, "foo.sql", "\
-- +rigrator Up
CREATE TABLE foo(id INT PRIMARY KEY, name VARCHAR NOT NULL);

-- +rigrator Down
DROP TABLE foo;

-- +rigrator Up
CREATE TABLE bar(id INT PRIMARY KEY);

-- +rigrator Down
DROP TABLE bar;")

      statements(migration, :forward).should eq([
        "-- +rigrator Up\nCREATE TABLE foo(id INT PRIMARY KEY, name VARCHAR NOT NULL);",
        "-- +rigrator Up\nCREATE TABLE bar(id INT PRIMARY KEY);",
      ])

      statements(migration, :backwards).should eq([
        "-- +rigrator Down\nDROP TABLE foo;",
        "-- +rigrator Down\nDROP TABLE bar;",
      ])
    end

    # Some complex PL/psql may have semicolons within them
    # To understand these we need StatementBegin/StatementEnd hints
    it "splits complex statements with user hints" do
      migration = Rigrator::Migration.new(20160101120000, "foo.sql", "\
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
-- +rigrator StatementEnd")

      ret = statements(migration, :forward)

      ret.size.should eq(1)
      ret[0].should eq(migration.source)
    end

    it "allows up and down sections with complex scripts" do
      migration = Rigrator::Migration.new(20160101120000, "foo.sql", "\
-- +rigrator Up
-- +rigrator StatementBegin
foo;
bar;
-- +rigrator StatementEnd

-- +rigrator Down
baz;")

      statements(migration, :forward).should eq([
        "-- +rigrator Up\n-- +rigrator StatementBegin\nfoo;\nbar;\n-- +rigrator StatementEnd",
      ])

      statements(migration, :backwards).should eq([
        "-- +rigrator Down\nbaz;",
      ])
    end
  end
end

def statements(migration, direction)
  migration.statements(direction).map { |stmt| stmt.strip }
end
