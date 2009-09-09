# Author: Tad Thorley
# 
# A simple chat server written in response to a challenge
# by David A. Black.  I tried to follow some principles
# advocated by Bob Martin:
# 
# 1. short methods (most 5 lines or less)
# 2. descriptive method names
# 3. keep methods at the same level of abstraction
# 4. tricky lines that deserve a comment can be put in a
#    method with a descriptive name
#

require 'socket'

class ChatServer
  
  EXIT_STRINGS = ["/quit", "/q", "/exit", "/part"]
  HELP_STRINGS = ["/help", "/?"]
  
  def initialize(options={})
    @port        = options[:port] || 7890
    @servname    = options[:servname] || "ChatServ"
    @connections = {}
  end
  
  def start_server
    @server = TCPServer.new(@port)
    while(connection = @server.accept)
      Thread.new(connection) do |conn|
        user = log_in(conn)
        listen_to(user)
        log_off(user)
      end
    end
  end
  
  def log_in(connection)
    user = get_unique_username_for(connection)
    register(user, connection)
    tell(user, "type '/help' for help")
    broadcast(@servname, "#{user} has entered the room.")
    broadcast(@servname, "In this room are: #{room_members.join(', ')}")
    user
  end
  
  def listen_to(user)
    while(message = @connections[user].gets.chomp)
      if EXIT_STRINGS.include?(message)
        break
      elsif HELP_STRINGS.include?(message)
        tell(user, help_message)
      else
        broadcast(user, message)
      end
    end
  end
  
  def log_off(user)
    tell(user, "Goodbye.")
    unregister(user)
    broadcast(@servname, "#{user} has left the room.")
    broadcast(@servname, "In this room are: #{room_members.join(', ')}")
  end

  def tell(user, message)
    @connections[user].puts message
  end
    
  def broadcast(who, message)
    room_members.each {|user| tell(user, "#{who}: " + message) unless who == user}
  end
      
  def get_unique_username_for(connection)
    prompt(connection, "Your username: ")
    while(username = connection.gets.chomp)
      break unless (username == @servname || room_members.include?(username))
      prompt(connection, "'#{username}' is already in use.\nPlease choose a different username: ") 
    end
    username
  end
  
  def help_message
    "type '/exit' to exit"  
  end
  
  def prompt(connection, message)
    connection.print message
  end
  
  def room_members
    @connections.keys
  end
  
  def register(user, connection)
    @connections[user] = connection
  end
  
  def unregister(user)
    @connections[user].close
    @connections.delete(user)
  end
end

if $0 == __FILE__
  server = ChatServer.new
  server.start_server
end