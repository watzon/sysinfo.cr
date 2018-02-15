module Sysinfo
  class Process

    STAT_KEYS = [
      "pid", "tcomm", "state", "ppid", "pgrp", "sid", "tty_nr", "tty_pgrp", "flags",
      "min_flt", "cmin_flt", "maj_flt", "cmaj_flt", "utime", "stime", "cutime",
      "cstime", "priority", "nice", "num_threads", "it_real_value", "start_time",
      "vsize", "rss", "rsslim", "start_code", "end_code", "start_stack", "esp",
      "eip", "pending", "blocked", "sigign", "sigcatch", 0, 0, 0, "exit_signal",
      "task_cpu", "rt_priority", "policy", "blkio_ticks", "gtime", "cgtime",
      "start_data", "end_data", "start_brk", "arg_start",  "arg_end",
      "env_start", "env_end", "exit_code"
    ]

    def initialize(@pid : Int32)
      if !Dir.exists?("/proc/" + @pid.to_s)
        raise "The process with pid##{@pid} doesn't exist."
      end
    end

    def autogroup
      read_file("autogroup")
    end

    def auxv(raw = false)
      str = read_file("auxv")
      return str if raw
      str.each_byte.map { |b| b.to_s(16) }
    end

    def cgroup(raw = false)
      str = read_file("cgroup")
      return str if raw
      lines = str.strip.split("\n")
      group = {} of Int32 => Hash(String, String)
      lines.each do |line|
        parts = line.split(":")
        group[parts[0].to_i] = {
          "controller_list" => parts[1],
          "cgroup_path" => parts[2]
        }
      end
      group
    end

    def cmdline
      read_file("cmdline")
    end

    def comm
      read_file("comm")
    end

    def coredump_filter
      read_file("coredump_filter")
    end

    def cpuset
      read_file("cpuset")
    end

    def environ
      read_file("environ")
    end

    def smaps(raw = false)
      data = read_file("smaps")
      return data if raw
      {
        size: get_smap_sum(data, "Size"),
        kernel_page_size: get_smap_sum(data, "KernelPageSize"),
        mmu_page_size: get_smap_sum(data, "MMUPageSize"),
        rss: get_smap_sum(data, "Rss"),
        pss: get_smap_sum(data, "Pss"),
        shared_clean: get_smap_sum(data, "Shared_Clean"),
        shared_dirty: get_smap_sum(data, "Shared_Dirty"),
        private_clean: get_smap_sum(data, "Private_Clean"),
        private_dirty: get_smap_sum(data, "Private_Dirty"),
        referenced: get_smap_sum(data, "Referenced"),
        anonymous: get_smap_sum(data, "Anonymous"),
        lazy_free: get_smap_sum(data, "LazyFree"),
        anon_huge_pages: get_smap_sum(data, "AnonHugePages"),
        shmem_pmd_mapped: get_smap_sum(data, "ShmemPmdMapped"),
        shared_hugetlb: get_smap_sum(data, "Private_Hugetlb"),
        private_hugetlb: get_smap_sum(data, "Private_Hugetlb"),
        swap: get_smap_sum(data, "Swap"),
        swap_pss: get_smap_sum(data, "SwapPss"),
        locked: get_smap_sum(data, "Locked")
      }
    end

    def stat(raw = false)
      data = read_file("stat")
      return data if raw
      stat = STAT_KEYS.zip(data.split(/\s+/)).to_h
      stat.delete(0)
      stat
    end

    private def get_smap_sum(data, key)
      sum = 0
      if matches = data.scan(Regex.new("#{key}:\\s+(\\d+).*"))
        matches.each { |match| sum += match[1].to_i }
      end
      sum
    end

    private def read_file(filename : String)
      File.read(File.join("/proc", @pid.to_s, filename)).strip
    end

  end
end
