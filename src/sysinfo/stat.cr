module Sysinfo
  class Stat

    alias CPU = NamedTuple(
      user: Int32,
      nice: Int32,
      system: Int32,
      idle: Int32,
      iowait: Int32,
      irq: Int32,
      softirq: Int32,
      steal: Int32,
      guest: Int32,
      guest_nice: Int32
    )

    def self.cpus
      data = File.read("/proc/stat")
      cpucount = 0
      cpus = {} of Int32 => CPU
      data.scan(/cpu\d\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) do |matches|
        cpu = {
          user: matches[1].to_i,
          nice: matches[2].to_i,
          system: matches[3].to_i,
          idle: matches[4].to_i,
          iowait: matches[4].to_i,
          irq: matches[5].to_i,
          softirq: matches[6].to_i,
          steal: matches[7].to_i,
          guest: matches[9].to_i,
          guest_nice: matches[10].to_i,
        }
        cpus[cpucount] = cpu
        cpucount += 1
      end
      cpus
    end

    def self.initr
      data = File.read("/proc/stat")
      data.scan(/intr\s(.*)/)[0][1]
    end

    def self.ctxt
      data = File.read("/proc/stat")
      data.scan(/ctxt\s(.*)/)[0][1].to_i
    end

    def self.btime
      data = File.read("/proc/stat")
      data.scan(/btime\s(.*)/)[0][1].to_i
    end

    def self.processes
      data = File.read("/proc/stat")
      data.scan(/processes\s(.*)/)[0][1].to_i
    end

    def self.procs_running
      data = File.read("/proc/stat")
      data.scan(/procs_running\s(.*)/)[0][1].to_i
    end

    def self.procs_blocked
      data = File.read("/proc/stat")
      data.scan(/procs_blocked\s(.*)/)[0][1].to_i
    end

    def self.softirq
      data = File.read("/proc/stat")
      data.scan(/softirq\s(.*)/)[0][1]
    end

  end
end
