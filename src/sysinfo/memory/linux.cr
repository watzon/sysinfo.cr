module SysInfo
  class Memory
    module Linux
      def virtual_memory
        filename = File.join(Common::HOST_PROC, "meminfo")
        file = File.read(filename)
        hash = file.strip
          .split(/\n/)
          .map(&.split(/:\s+/))
          .to_h
          .transform_values { |v| v.split(' ')[0].to_u64 * 1024 }

        memavail = !!hash["MemAvailable"]?
        active_file = !!hash["Active"]?
        inactive_file = !!hash["Inactive"]?
        s_reclaimable = !!hash["sReclaimable"]?

        used = hash["MemTotal"] - hash["MemFree"] - hash["Buffers"] - hash["Cached"]
        VirtualMemoryStat.new(
          total: hash["MemTotal"],
          free: hash["MemFree"],
          buffers: hash["Buffers"],
          cached: hash["Cached"],
          active: hash["Active"],
          inactive: hash["Inactive"],
          writeback: hash["Writeback"],
          writeback_tmp: hash["WritebackTmp"],
          dirty: hash["Dirty"],
          shared: hash["Shmem"],
          slab: hash["Slab"],
          s_reclaimable: hash["SReclaimable"],
          s_unreclaim: hash["SUnreclaim"],
          page_tables: hash["PageTables"],
          swap_cached: hash["SwapCached"],
          commit_limit: hash["CommitLimit"],
          committed_as: hash["Committed_AS"],
          hight_total: hash["HighTotal"]? || 0_u64,
          high_free: hash["HighFree"]? || 0_u64,
          low_total: hash["LowTotal"]? || 0_u64,
          low_free: hash["LowFree"]? || 0_u64,
          swap_total: hash["SwapTotal"]? || 0_u64,
          swap_free: hash["SwapFree"]? || 0_u64,
          mapped: hash["Mapped"],
          v_malloc_total: hash["VMallocTotal"]? || 0_u64,
          v_malloc_used: hash["VMallocUsed"]? || 0_u64,
          v_malloc_chunk: hash["VMallocChunk"]? || 0_u64,
          huge_pages_total: hash["HugePages_Total"]? || 0_u64,
          huge_pages_free: hash["HugePages_Free"]? || 0_u64,
          huge_pages_size: hash["HugePagessize"]? || 0_u64,
          available: !memavail ? (
            active_file &&
            inactive_file &&
            s_reclaimable ? calculate_available_vmem(hash) : hash["Cached"] + hash["Free"]
          ) : 0_u64,
          used: used,
          used_percent: used / hash["MemTotal"] * 100.0
        )
      end

      private def calculate_available_vmem(hash)
        fn = File.join(Common::HOST_PROC, "zoneinfo")

        begin
          lines = File.read_lines(fn)
        rescue e
          # Fallback under kernel 2.6.13
          return hash["Free"] + hash["Cached"]
        end

        pagesize = C.getpagesize

        watermark_low = lines.reduce(0) do |i, line|
          fields = line.split(/\s+/)
          if fields[0].starts_with?("low")
            low_value = fields[1].to_u64? || 0_u64
            i += low_value
          end
          i
        end

        watermark_low *= pagesize

        avail_memory = hash["MemFree"] - watermark_low
        page_cache = hash["Active(file)"] + hash["Inactive(file)"]
        page_cache -= Math.min(page_cache / 2, watermark_low).floor
        avail_memory += page_cache
        avail_memory += hash["SReclaimable"] - Math.min(hash["SReclaimable"] / 2, watermark_low)

        if avail_memory < 0
          avail_memory = 0
        end

        avail_memory.to_u64
      end

      def swap_memory
        sysinfo = Common.sysinfo
        
        total = sysinfo.totalswap * sysinfo.mem_unit
        free  = sysinfo.freeswap * sysinfo.mem_unit
        used  = total - free

        pp sysinfo
        
        # Check infinity
        if total != 0
          used_percent = (total - free) / total * 100.0
        else
          used_percent = 0.0
        end

        filename = File.join(Common::HOST_PROC, "vmstat")
        file = File.read(filename)

        hash = file.strip
          .split(/\n/)
          .map(&.split(/\s+/))
          .to_h
          .transform_values { |v| v.split(' ')[0].to_u64 * 4 * 1024 }

        sin     = hash.fetch("pswpin", 0_u64)
        sout    = hash.fetch("pswpout", 0_u64)
        pgin    = hash.fetch("pgpgin", 0_u64)
        pgout   = hash.fetch("pgpgout", 0_u64)
        pgfault = hash.fetch("pgfault", 0_u64)

        SwapMemoryStat.new(
          total: total,
          free: free,
          used: used,
          used_percent: used_percent,
          sin: sin,
          sout: sout,
          pgin: pgin,
          pgout: pgout,
          pgfault: pgfault
        )
      end
      
      record VirtualMemoryExStat,
        active_file : UInt64 = 0_u64,
        inactive_file : UInt64 = 0_u64
    end
  end
end
