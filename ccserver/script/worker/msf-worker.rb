require 'rubygems'
require 'eventmachine'
require "#{RAILS_ROOT}/script/worker/loader"
require "#{RAILS_ROOT}/script/worker/msf_session_event"


module CommandHandler
  
  def initialize
    puts "Initialize Framework..."
    @framework =  Msf::Simple::Framework.create
    puts "done."
    connect_db
    begin
      @framework.db.exploited_hosts.each do |h|
        h.delete
      end
    rescue ::Exception
      puts("An error occurred while deleteing exploited_hosts: #{$!} #{$!.backtrace}")
    end

    handler = MsfSessionEvent.new
    @framework.events.add_session_subscriber(handler)
  end
  
  def notify_readable
    while (cmd = @io.readline)
      parse_command cmd
    end
  rescue EOFError
    detach
  end

  def unbind
    EM.next_tick do
      # socket is detached from the eventloop, but still open
      data = @io.read
    end
  end
  
  def parse_command _cmd
    cmd = _cmd.split
    if commands.has_key? cmd[0].to_s
      send("cmd_#{cmd[0]}".to_sym, cmd[1..-1])
    else
      raise "Unknown Command"
    end
  end

  def commands
    base = {
        "autopwn" => "Starts Autopwning",
        "nmap" => "Starts a Nmap Scan",
        "session_install" => "Install meterpreter on host"
    }
  end
  
  def cmd_autopwn args
    manager = SubnetManager.new @framework, args[0]
    manager.get_sessions
  end
  
  def cmd_nmap args
    manager = SubnetManager.new @framework, args[0]
    manager.run_nmap
  end

  def cmd_session_install args
    if (session = @framework.sessions.get(args[0]))
      if (session.type == "meterpreter")
        puts "Install meterpreter on session."
        install_meterpreter(session)
      else
       puts "Selected session is not a meterpreter session"
      end
    else
      puts "No such session found"
    end
  end
  
  def connect_db
    # set the db driver
    @framework.db.driver = DB_SETTINGS["adapter"]
    # create the options hash
    opts = {}
    opts['adapter'] = DB_SETTINGS["adapter"]
    opts['username'] = DB_SETTINGS["username"]
    opts['password'] = DB_SETTINGS["password"]
    opts['database'] = DB_SETTINGS["database"]
    opts['host'] =  DB_SETTINGS["host"]
    opts['port'] =  DB_SETTINGS["port"]
    opts['socket'] = DB_SETTINGS["socket"]

    # This is an ugly hack for a broken MySQL adapter:
    # http://dev.rubyonrails.org/ticket/3338
    # if (opts['host'].strip.downcase == 'localhost')
    #   opts['host'] = Socket.gethostbyname("localhost")[3].unpack("C*").join(".")
    # end
    puts opts
    puts "connecting to database..."

    begin
      if (not @framework.db.connect(opts))
        raise RuntimeError.new("Failed to connect to the database: #{@framework.db.error}. Did you edit the config.yaml?")
      end
    rescue ::Exception
      puts("An error occurred while connecting to database: #{$!} #{$!.backtrace}")
    end

    puts "connected to database."
  end
end

EventMachine::run do
  puts "start EM"
end
