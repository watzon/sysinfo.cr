module SysInfo
  module Common
    HOST_PROC = ENV.fetch("HOST_PROC", "/proc")
    HOST_SYS  = ENV.fetch("HOST_SYS", "/sys")
    HOST_ETC  = ENV.fetch("HOST_ETC", "/etc")
    HOST_VAR  = ENV.fetch("HOST_VAR", "/var")
    HOST_RUN  = ENV.fetch("HOST_RUN", "/run")

    # Searches the path for the given executable, returning its
    # fully qualified path.
    def self.which(cmd)
      exts = ENV["PATHEXT"]? ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(':').each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe)
        end
      end
      nil
    end

    # Call a shell command and get its output, raising an exception
    # if an error is returned.
    def self.command(cmd, *args)
      output = IO::Memory.new
      error = IO::Memory.new

      Process.run(cmd, args, shell: true, output: output, error: error)
      output.rewind
      error.rewind

      if !error.empty?
        raise error.gets_to_end
      end

      output.gets_to_end
    end

    def self.sysinfo
      sysinfo_ptr = Pointer(C::SysInfo).malloc(sizeof(C::SysInfo))
      C.sysinfo(sysinfo_ptr)
      sysinfo_ptr.value
    end

    def self.read_ints(filename)
      lines = File.read_lines(filename)
      lines.map(&.strip.to_i64)
    end
  end
end
