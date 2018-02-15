require "./sysinfo/*"

# TODO: Write documentation for `Stat`
module Sysinfo

  def self.cgroups
    CGroups
  end

  def self.meminfo
    Meminfo
  end

  def self.cmdline
    read_file("/proc/cmdline").split(/\s+/)
  end

  def self.stat
    Stat
  end

  def self.uptime
    uptimes = read_file("uptime").split(/\s+/).map(&.to_f64)
    ["uptime", "idle"].zip(uptimes).to_h
  end

  def self.process(pid : Int32)
    Process.new(pid)
  end

  private def self.read_file(filename : String)
    File.read(File.join("/proc", filename)).strip
  end

end
