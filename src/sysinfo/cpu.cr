require "json"
require "./cpu/*"

module SysInfo
  class CPU
    include CPU::Linux

    getter last_cpu_percent : LastPercent

    def initialize
      @last_cpu_percent = LastPercent.new(
        times(false),
        times(true)
      )
      init
    end

    def calculate_busy(t1 : TimesStat, t2 : TimesStat)
      t1_all, t1_busy = t1.all_busy
      t2_all, t2_busy = t2.all_busy

      if t2_busy <= t1_busy
        return 0.0
      end

      if t2_all <= t1_all
        return 100.0
      end

      Math.min(100.0, Math.max(0.0, (t2_busy - t1_busy) / (t2_all - t1_all) * 100))
    end

    def calculate_all_busy(t1 : Array(TimesStat), t2 : Array(TimesStat))
      # Make sure the arrays are of the same length
      if t1.size != t2.size
        raise "Received two different CPU counts: #{t1.size} != #{t2.size}"
      end

      t1.zip(t2).reduce([] of Float64) do |acc, (t, o)|
        acc << calculate_busy(t, o)
        acc
      end
    end

    # Calculates the percentage of CPU used, either per CPU or combined.
    # If an interval of 0 is given it will compare the current CPU times against the last call.
    # Returns one value per CPU, or a single value if `per_cpu` is true.
    def percent(interval : Time::Span?, per_cpu = false)
      unless interval
        return percent_used_from_last_call(per_cpu)
      end

      cpu_times1 = times(per_cpu)
      sleep(interval)
      cpu_times2 = times(per_cpu)

      calculate_all_busy(cpu_times1, cpu_times2)
    end

    private def percent_used_from_last_call(per_cpu = false)
      cpu_times = times(per_cpu)
      last_times = nil

      if per_cpu
        last_times = last_cpu_percent.last_per_cpu_times
        last_cpu_percent.last_per_cpu_times = cpu_times
      else
        last_times = last_cpu_percent.last_cpu_times
        last_cpu_percent.last_cpu_times = cpu_times
      end

      if !last_times
        raise "Error getting times for cpu percent. Variable `last_times` was nil."
      end

      calculate_all_busy(last_times, cpu_times)
    end

    record TimesStat,
      cpu : String,
      user : Float64,
      system : Float64,
      idle : Float64,
      nice : Float64,
      iowait : Float64,
      irq : Float64,
      softirq : Float64,
      steal : Float64,
      guest : Float64,
      guest_nice : Float64 do
      include JSON::Serializable

      def total
        [user, system, nice, iowait, irq, softirq, steal, idle].sum
      end

      def all_busy
        busy = [user, system, nice, iowait, irq, softirq, steal].sum
        {busy + idle, busy}
      end
    end

    record InfoStat,
      cpu : Int32 = 0,
      model_name : String? = nil,
      vendor_id : String = "",
      family : String = "",
      model : String = "",
      stepping : Int32 = 0,
      physical_id : String = "",
      core_id : String = "",
      cores : Int32 = 0,
      mhz : Float64 = 0.0,
      cache_size : Int32 = 0,
      flags : Array(String) = [] of String,
      microcode : String = "" do
      include JSON::Serializable
    end

    class LastPercent
      property last_cpu_times : Array(TimesStat)
      property last_per_cpu_times : Array(TimesStat)

      def initialize(@last_cpu_times, @last_per_cpu_times)
      end
    end
  end
end
