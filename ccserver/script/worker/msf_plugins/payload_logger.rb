# This extends the PacketDispatcher from Rex
# with Logging 
# Original Source is: lib/rex/post/meterpreter/packet_dispatcher.rb
module Rex
module Post
module Meterpreter
module PacketDispatcher

	def send_packet(packet, completion_routine = nil, completion_param = nil)
    Msf::Plugin::FidiusLogger.log_packet(self.sock,packet.to_r,"Meterpreter")
		if (completion_routine)
			add_response_waiter(packet, completion_routine, completion_param)
		end

		bytes = 0
		raw   = packet.to_r

		if (raw)
			begin
				bytes = self.sock.write(raw)
			rescue ::Exception => e
				# Mark the session itself as dead
				self.alive = false
				
				# Indicate that the dispatcher should shut down too
				@finish = true
				
				# Reraise the error to the top-level caller
				raise e		
			end
		end

		return bytes
	end

end
end
end
end

module Msf
  class Plugin::FidiusLogger < Msf::Plugin
    def self.task_id=(id)
      $task_id = id
    end

    def self.log_packet(socket,data,caused_by="")
      puts "log payload #{caused_by} #{data.size} bytes"
      PayloadLog.create(:exploit=>caused_by,:payload=>data,:src_addr=>socket.localhost,:dest_addr=>socket.peerhost,:src_port=>socket.localport,:dest_port=>socket.peerport,:task_id=>$task_id)
    end

    def self.inspect_socket(socket)
      "#{socket.localhost}:#{socket.localport} -> #{socket.peerhost}:#{socket.peerport}"    
    end

	  class MySocketEventHandler
		  include Rex::Socket::Comm::Events

      def initialize

      end

		  def on_before_socket_create(comm, param)
		  end

		  def on_socket_created(comm, sock, param)
  		  sock.extend(SocketLogger::SocketTracer)
			  sock.context = param.context
			  sock.params = param
			  sock.initlog
		  end
	  end

    def initialize(framework, opts)
		  @eh = MySocketEventHandler.new
		  Rex::Socket::Comm::Local.register_event_handler(@eh)
    end

	  def cleanup
		  Rex::Socket::Comm::Local.deregister_event_handler(@eh)
      $fd.close
	  end

		def name
			"FidiusLogger"
		end

	  def desc
		  "Logs Traffic and Meterpreter-Activity"
	  end
  end
end


# This module extends the captured socket instance
# Copied from plugins/socket_logger.rb
module SocketLogger
module SocketTracer

	@@last_id = 0

	attr_accessor :context, :params

	# Hook the write method
	def write(buf, opts = {})
    Msf::Plugin::FidiusLogger.log_packet(self,buf,context['MsfExploit'].fullname)
		super(buf, opts)
	end

	# Hook the read method
	def read(length = nil, opts = {})
		r = super(length, opts)
		return r
	end

	def close(*args)
		super(*args)
	end

	def initlog
	end
end
end