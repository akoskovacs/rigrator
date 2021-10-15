require "./spec_helper"

Spectator.describe Rigrator::Cli do
  mock File do
    stub self.delete(path : Path | String) { nil }
  end

  double :fake_db do
    stub exec(query) { DB::ExecResult.new(0, 0) }
  end

  before_each { FAKE_DB.clear; FAKE_DB << double(:fake_db) }

  mock Rigrator::DB do
    stub self.connect() { yield FAKE_DB.first }
  end

  describe "#drop_database" do
    context "sqlite3" do
      it "deletes the file" do
        Rigrator::DB.connection_url = "sqlite3:myfile"
        Rigrator::Cli.drop_database
        expect(File).to have_received(:delete).with("myfile")
      end
    end

    context "postgres" do
      it "calls drop database" do
        Rigrator::DB.connection_url = "postgres://user:pswd@host:5432/database"
        Rigrator::Cli.drop_database
        expect(Rigrator::DB).to have_received(:connect)
      end
    end
  end

  describe "#create_database" do
    context "sqlite3" do
      it "doesn't call connect" do
        Rigrator::DB.connection_url = "sqlite3:myfile"
        Rigrator::Cli.create_database
        expect(Rigrator::DB).not_to have_received(:connect)
      end
    end

    context "postgres" do
      it "calls connect" do
        Rigrator::DB.connection_url = "postgres://user:pswd@host:5432/database"
        Rigrator::Cli.create_database
        expect(Rigrator::DB).to have_received(:connect)
      end
    end
  end
end
