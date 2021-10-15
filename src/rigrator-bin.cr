require "log"
require "pg"
require "mysql"
require "sqlite3"

require "./rigrator"

Log.define_formatter Rigrator::CliFormat, "#{message}" \
                                         "#{data(before: " -- ")}#{context(before: " -- ")}#{exception}"
Log.setup(:info, Log::IOBackend.new(formatter: Rigrator::CliFormat))

Rigrator::Cli.run
