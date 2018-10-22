
describe Sysinfo::Stat do
  {% for field in {:cpus, :initr, :ctxt, :btime, :processes, :procs_running, :procs_blocked, :softirq } %}

    context %<the "{{ field.id }}" attribute> do
      it "is not empty" do
        Sysinfo::Stat.new.{{field.id}}.empty?.should_not be_true
        Sysinfo::Stat.{{field.id}}.empty?.should_not be_true
      end
    end

  {% end %}
end
