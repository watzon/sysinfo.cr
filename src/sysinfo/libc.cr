lib C
  struct SysInfo
    uptime    : LibC::UInt64T
    loads     : LibC::UInt64T
    totalram  : LibC::UInt64T
    freeram   : LibC::UInt64T
    sharedram : LibC::UInt64T
    bufferram : LibC::UInt64T
    totalswap : LibC::UInt64T
    freeswap  : LibC::UInt64T
    procs     : LibC::UInt64T
    totalhigh : LibC::UInt64T
    freehigh  : LibC::UInt64T
    mem_unit  : LibC::UInt64T
    pad       : LibC::UInt64T
  end

  fun sysinfo(sysinfo : SysInfo*) : LibC::Int
  fun getpagesize : LibC::Int
end
