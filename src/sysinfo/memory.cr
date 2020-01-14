require "json"
require "./memory/*"

module SysInfo
  class Memory
    include Memory::Linux
    
    record VirtualMemoryStat,
           # Total amount of RAM on this system
           total : UInt64 = 0_u64,

           # RAM available for programs to allocate
           available : UInt64 = 0_u64,

           # RAM used  by programs
           used : UInt64 = 0_u64,

           # Percentage of RAM used by programs
           used_percent : Float64 = 0.0,

           # This is the kernel's notion of free memory. For a usable
           # free memory value you probably want `available`
           free : UInt64 = 0_u64,

           # OS X / BSD specific numbers
           # http://www.macyourself.com/2010/02/17/what-is-free-wired-active-and-inactive-system-memory-ram/
           active : UInt64 = 0_u64,
           inactive : UInt64 = 0_u64,
           wired : UInt64 = 0_u64,

           # FreeBSD specific numbers
           # https://reviews.freebsd.org/D8467
           laundry : UInt64 = 0_u64,

           # Linux specific numbers
           # https://www.centos.org/docs/5/html/5.1/Deployment_Guide/s2-proc-meminfo.html
           # https://www.kernel.org/doc/Documentation/filesystems/proc.txt
	   # https://www.kernel.org/doc/Documentation/vm/overcommit-accounting
           buffers : UInt64 = 0_u64,
           cached : UInt64 = 0_u64,
           writeback : UInt64 = 0_u64,
           dirty : UInt64 = 0_u64,
           writeback_tmp : UInt64 = 0_u64,
           shared : UInt64 = 0_u64,
           slab : UInt64 = 0_u64,
           s_reclaimable : UInt64 = 0_u64,
           s_unreclaim : UInt64 = 0_u64,
           page_tables : UInt64 = 0_u64,
           swap_cached : UInt64 = 0_u64,
           commit_limit : UInt64 = 0_u64,
           committed_as : UInt64 = 0_u64,
           hight_total : UInt64 = 0_u64,
           high_free : UInt64 = 0_u64,
           low_total : UInt64 = 0_u64,
           low_free : UInt64 = 0_u64,
           swap_total : UInt64 = 0_u64,
           swap_free : UInt64 = 0_u64,
           mapped : UInt64 = 0_u64,
           v_malloc_total : UInt64 = 0_u64,
           v_malloc_used : UInt64 = 0_u64,
           v_malloc_chunk : UInt64 = 0_u64,
           huge_pages_total : UInt64 = 0_u64,
           huge_pages_free : UInt64 = 0_u64,
           huge_pages_size : UInt64 = 0_u64 do
      include JSON::Serializable
    end

    record SwapMemoryStat,
           total : UInt64 = 0_u64,
           used : UInt64 = 0_u64,
           free : UInt64 = 0_u64,
           used_percent : Float64 = 0.0,
           sin : UInt64 = 0_u64,
           sout : UInt64 = 0_u64,
           pgin : UInt64 = 0_u64,
           pgout : UInt64 = 0_u64,
           pgfault : UInt64 = 0_u64 do
      include JSON::Serializable
    end
  end
end
