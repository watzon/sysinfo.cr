module Sysinfo
  # Data read from /proc/stat. See `man 5 proc` on a Linux system.
  class Stat < Info
    getter location : String = "/proc/stat"

    alias CPU = NamedTuple(
      user: Int64,
      nice: Int64,
      system: Int64,
      idle: Int64,
      iowait: Int64,
      irq: Int64,
      softirq: Int64,
      steal: Int64,
      guest: Int64,
      guest_nice: Int64)

    # An array of CPUs from an existing stat instance.
    def cpus
      data = File.read("/proc/stat")
      cpus = [] of CPU
      data.scan(/cpu\d\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) do |matches|
        cpu = {
          user:       matches[1].to_i64,
          nice:       matches[2].to_i64,
          system:     matches[3].to_i64,
          idle:       matches[4].to_i64,
          iowait:     matches[4].to_i64,
          irq:        matches[5].to_i64,
          softirq:    matches[6].to_i64,
          steal:      matches[7].to_i64,
          guest:      matches[9].to_i64,
          guest_nice: matches[10].to_i64,
        }
        cpus << cpu
      end
      cpus
    end

    # An array of CPUs from a new stat instance.
    def self.cpus
      new.cpus
    end

    {% for attr in {:intr, :softirq} %}

    # The text for the "{{ attr.id }}" attribute of an existing stat instance.
    def {{ attr.id }}
      data.scan(/{{ attr.id }}\s(.*)/)[0][1].split.map &.to_i64
    end

    # The text for the "{{ attr.id }}" attribute of a new stat instance.
    def self.{{ attr.id }}
      new.{{ attr.id }}
    end

    {% end %}
    {% for attr in {:ctxt, :btime, :processes, :procs_running, :procs_blocked} %}

    # The text for the "{{ attr.id }}" attribute of an existing stat instance.
    def {{ attr.id }}
      data.scan(/{{ attr.id }}\s(.*)/)[0][1].to_i64
    end

    # The text for the "{{ attr.id }}" attribute of a new stat instance.
    def self.{{ attr.id }}
      new.{{ attr.id }}
    end

    {% end %}
  end
end
