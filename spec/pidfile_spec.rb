require "spec_helper"

describe Emque::Consuming::Pidfile do
  describe "#initialize" do
    it "creates a directory to hold the pidfile if it doesn't exist" do
      path = "spec/dummy/tmp/testingpidpath"
      pidfile = File.join(path, "pidfile.pid")
      expect(Dir.exists?(path)).to eq(false)
      Emque::Consuming::Pidfile.new(pidfile)
      expect(Dir.exists?(path)).to eq(true)
      FileUtils.rm_rf(path)
    end

    it "loads the pid from the pidfile if it already exists" do
      path = "spec/dummy/tmp/testingpidpath"
      pidfile = File.join(path, "pidfile.pid")
      Emque::Consuming::Pidfile.new(pidfile)
      File.open(pidfile, "w") do |f|
        f.write("1000000")
      end
      pf = Emque::Consuming::Pidfile.new(pidfile)
      expect(pf.to_i).to eq(1000000)
      FileUtils.rm_rf(path)
    end
  end

  describe "#running?" do
    describe "when the pidfile exists" do
      describe "and the pid is not a valid process" do
        it "deletes the pidfile and returns false" do
          path = "spec/dummy/tmp/testingpidpath"
          pidfile = File.join(path, "pidfile.pid")
          Emque::Consuming::Pidfile.new(pidfile)
          File.open(pidfile, "w") do |f|
            f.write("10000000")
          end
          pf = Emque::Consuming::Pidfile.new(pidfile)
          expect(File.exists?(pidfile)).to eq(true)
          expect(pf.running?).to eq(false)
          expect(File.exists?(pidfile)).to eq(false)
          FileUtils.rm_rf(path)
        end
      end

      describe "and the pid is a valid process" do
        it "returns true" do
          path = "spec/dummy/tmp/testingpidpath"
          pidfile = File.join(path, "pidfile.pid")
          Emque::Consuming::Pidfile.new(pidfile)
          File.open(pidfile, "w") do |f|
            f.write(Process.pid)
          end
          pf = Emque::Consuming::Pidfile.new(pidfile)
          expect(File.exists?(pidfile)).to eq(true)
          expect(pf.running?).to eq(true)
          FileUtils.rm_rf(path)
        end
      end
    end
  end

  describe "#write" do
    it "writes the current process's pid to the pidfile" do
      path = "spec/dummy/tmp/testingpidpath"
      pidfile = File.join(path, "pidfile.pid")
      pf = Emque::Consuming::Pidfile.new(pidfile)
      expect(File.exists?(pidfile)).to eq(false)
      pf.write
      expect(File.exists?(pidfile)).to eq(true)
      expect(File.read(pidfile).chomp).to eq(Process.pid.to_s)
      FileUtils.rm_rf(path)
    end
  end
end
