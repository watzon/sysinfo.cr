
describe Sysinfo::Stat do
  {% for field in {:cpus, :initr, :softirq } %}

    context %<the "{{ field.id }}" attribute> do
      it "is not empty" do
        Sysinfo::Stat.new.{{field.id}}.empty?.should_not be_true
        Sysinfo::Stat.{{field.id}}.empty?.should_not be_true
      end
    end

  {% end %}
  {% for field in { :ctxt, :btime, :processes, :procs_running, :procs_blocked } %}

  context %<the "{{ field.id }}" attribute> do
    it "is an integer" do
      Sysinfo::Stat.new.{{field.id}}.should be_a(Int32)
      Sysinfo::Stat.{{field.id}}.should be_a(Int32)
    end
  end

  {% end %}

end
