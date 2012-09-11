require 'puppet'
require 'yaml'

begin
  require 'kestrel'
rescue LoadError => e
  Puppet.info "You need the `kestrel-client` gem to use the kestrel report"
end

Puppet::Reports.register_report(:kestrel) do

  configfile = File.join([File.dirname(Puppet.settings[:config]), "kestrel.yaml"])
  raise(Puppet::ParseError, "kestrel report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  KESTREL_SERVER = config[:kestrel_server] ||= 'localhost'
  KESTREL_PORT = config[:kestrel_port] ||= 22133
  KESTREL_QUEUE = config[:kestrel_queue] ||= 'queue'

  desc <<-DESC
  Send metrics to kestrel.
  DESC

  def process
    Puppet.debug "Sending logs for #{self.host} to kestrel server at #{KESTREL_SERVER}"
    $queue = Kestrel::Client.new("#{KESTREL_SERVER}:#{KESTREL_PORT}")
    self.logs.each do |log|
      event = "#{self.host} #{log}"
      $queue.set(KESTREL_QUEUE, event)
    end
  end
end
