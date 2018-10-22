abstract class Info
  # the path that is being read
  abstract def location : String
  # the data read from `#location`
  property data : String
  def initialize(@data)
  end
  def initialize
    @data = File.read location
  end
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
    @data = File.read location
    self
  end
end
