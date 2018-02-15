module Sysinfo
  class Meminfo
    class MeminfoException < Exception; end

    ATTRIBUTES = {
      "memtotal"          => "MemTotal",
      "memfree"           => "MemFree",
      "memavailable"      => "MemAvailable",
      "buffers"           => "Buffers",
      "cached"            => "Cached",
      "swapcached"        => "SwapCached",
      "active"            => "Active",
      "inactive"          => "Inactive",
      "active_anon"       => "Active\(anon\)",
      "inactive_anon"     => "Inactive\(anon\)",
      "active_file"       => "Active\(file\)",
      "inactive_file"     => "Inactive\(file\)",
      "unevictable"       => "Unevictable",
      "mlocked"           => "Mlocked",
      "swaptotal"         => "SwapTotal",
      "swapfree"          => "SwapFree",
      "dirty"             => "Dirty",
      "writeback"         => "Writeback",
      "anonpages"         => "AnonPages",
      "mapped"            => "Mapped",
      "shmem"             => "Shmem",
      "slab"              => "Slab",
      "sreclaimable"      => "SReclaimable",
      "sunreclaim"        => "SUnreclaim",
      "kernelstack"       => "KernelStack",
      "pagetables"        => "PageTables",
      "nfs_unstable"      => "NFS_Unstable",
      "bounce"            => "Bounce",
      "writebacktmp"      => "WritebackTmp",
      "commitlimit"       => "CommitLimit",
      "committed_as"      => "Committed_AS",
      "vmalloctotal"      => "VmallocTotal",
      "vmallocused"       => "VmallocUsed",
      "vmallocchunk"      => "VmallocChunk",
      "hardwarecorrupted" => "HardwareCorrupted",
      "anonhugepages"     => "AnonHugePages",
      "directmap4k"       => "DirectMap4k",
      "directmap2m"       => "DirectMap2M",
      "directmap1g"       => "DirectMap1G"
    }

    {% for attribute in ATTRIBUTES %}
      def self.{{ attribute.id }}
        data = File.read("/proc/meminfo")
        regex_match({{ attribute }}, data)
      rescue exception
        raise MeminfoException.new exception.message
      end
    {% end %}

    private def self.regex_match(attribute, data)
      regex = Regex.new("#{ATTRIBUTES[attribute]}:\\s*(.*?)\\s")
      if match = regex.match(data)
        return match[1].to_i if match.size > 0
      end
      nil
    end
  end
end
