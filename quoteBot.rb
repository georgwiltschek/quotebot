require 'rubygems'
require 'isaac'
require 'database'
require 'yaml'
require 'twitter'
require 'json'
require 'simple-fourchan'

# Extend Isaac
module Isaac
  class Bot
    attr_accessor :params
    
    def clean(event)
      @events[event] = nil
    end
    
    # we need this patch for the params to track nick changes
    def dispatch(event, msg=nil)
      if msg
        @nick, @user, @host, @channel, @error, @message, @params = 
          msg.nick, msg.user, msg.host, msg.channel, msg.error, msg.message, msg.params
      end

      if handler = find(event, message)
        regexp, block = *handler
        self.match = message.match(regexp).captures
        invoke block
      end
    end
  end
end

$config  = YAML.load_file("config.yml")
$version = "0.2"
$githash = `git log -1 --pretty=format:%h | head -c 8`
# $help    = Array.new()
# $helpop  = Array.new()

# this settings will get reloaded
$settings = YAML.load_file("settings.yml")

configure do |c|
  c.server   = $config["config"]["server"]
  c.port     = $config["config"]["port"]
  c.realname = $config["config"]["realname"]
  c.nick     = $config["config"]["nick"]
end

def loadConfigs
  $settings = YAML.load_file("settings.yml")
  load 'commands.rb'
  @commands = Commands.new
  
  clean :channel
  @commands.each do |command|
    p command
    on :channel, command.regex, &command.cmd
  end
end

on :private, /^!reload/ do
  loadConfigs
end

on :connect do
  # take stuff from db
  #  join Channel.channels_list unless Channel.all.size==0
  # join "#tl" if Channel.all.length==0
  loadConfigs
  join $config["config"]["default_channel"] 
end

# private for the moment...
on :private, /^\!help$/ do

  help = []
  @commands.each do |command|
    help.push command.help
  end

  # if ($helpop.empty?) then
  #   $helpop.push("!op                -- get +op.")
  #   $helpop.push("!op add <username> -- allow <username> to get op with !op.")
  # end

	help.each do |h|
  		raw ["NOTICE #{nick} :", h].join()
	end

  # if (Op.isOp(channel, nick)) then
  #   $helpop.each do |h|
  #         raw ["NOTICE #{nick} :", h].join()
  #   end
  # end
end

on :private, /^!register (.*?)$/ do |password|
  op = Op.create(:nick=>nick, :password=>password)
  op.save
  
  Op.activate(nick,password)
end

on :join do
  # adding active user
  UserManager.add_active_user nick,channel
  puts "active users"
  p UserManager.active_users
  
  p $settings
  if $settings["greetings"]["goodPeople"].include?(nick) then
    msg channel, $settings["greetings"]["good"].choice
  elsif (rand($settings["greetings"]["badChance"]) == 0) then
    msg channel, $settings["greetings"]["bad"].choice
  elsif (rand($settings["greetings"]["goodChance"]) == 0) then
    msg channel, $settings["greetings"]["good"].choice
  end
end

on :nick do
  puts "woah " + nick + " became " + params[0]
  UserManager.rename_user nick, params[0]
end

on :kick do
  sleep rand(5)
  join Channel::channels_list
end
