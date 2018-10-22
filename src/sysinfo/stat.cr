module Sysinfo
  # Data read from /proc/stat. See `man 5 proc` on a Linux system.
  class Stat
    property data : String
    def initialize(@data)
    end
    def initialize
        @data = File.read "/proc/stat"
    end
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

    # A chainable method which forces the data to be reread from the file
    # before calling an output method. E.G.:
    #
    # ```
    #   stat = Stat.new
    #   puts stat.processes
    #   puts stat.cpus
    #   loop do
    #     sleep 2.seconds
    #     puts stat.read.processes
    #     #         ^^ forces stats to be reread
    #     puts stat.cpus
    #   end
    # ```
    #
    # this allows refreshing the data without reallocating a new object.
    def read
        @data = File.read "/proc/stat"
    end

    # An array of CPUs from an existing stat instance.
    def cpus
      data = File.read("/proc/stat")
      cpucount = 0
      cpus = [] of CPU
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

    # An array of CPUs from a new stat instance.
    def self.cpus
      new.cpus
    end

    {% for attr in { :initr, :ctxt, :btime, :processes, :procs_running, :procs_blocked, :softirq } %}

    # The text for the "{{ attr.id }}" attribute of an existing stat instance.
    def {{ attr.id }}
        data.scan(/{{ attr.id }}\s(.*)/)[0][1]
    end

    # The text for the "{{ attr.id }}" attribute of a new stat instance.
    def self.{{ attr.id }}
        new.{{ attr.id }}
    end

    {% end  %}

  end
end
