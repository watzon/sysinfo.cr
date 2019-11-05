require "../spec_helper"

describe Sysinfo::Stat do
  context %<the "cpus" attribute> do
    it "is not empty" do
      Sysinfo::Stat.new.cpus.empty?.should_not be_true
      Sysinfo::Stat.cpus.empty?.should_not be_true
    end
  end

  {% for field in {:intr, :softirq} %}

    context %<the "{{ field.id }}" attribute> do
      it "is an array of integers" do
        tdata = Sysinfo::Stat.new.{{field.id}}
        tdata.empty?.should_not be_true
        tdata.should be_a Array(Int64)
        tdata = Sysinfo::Stat.{{field.id}}
        tdata.empty?.should_not be_true
        tdata.should be_a Array(Int64)
      end
    end

  {% end %}
  {% for field in {:ctxt, :btime, :processes, :procs_running, :procs_blocked} %}

  context %<the "{{ field.id }}" attribute> do
    it "is an integer" do
      Sysinfo::Stat.new.{{field.id}}.should be_a(Int64)
      Sysinfo::Stat.{{field.id}}.should be_a(Int64)
    end
  end

  {% end %}
end
