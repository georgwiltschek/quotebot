require 'rubygems'
require 'isaac'
require 'database'
require 'yaml'
require 'twitter'
require 'json'

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

on :private, /^!reload/ do
  $settings = YAML.load_file("settings.yml")
  load 'commands.rb'
  @commands = Commands.new
  
  clean :channel
  @commands.each do |command|
    p command
    on :channel, command.regex, &command.cmd
  end
end

on :connect do
  # take stuff from db
  #  join Channel.channels_list unless Channel.all.size==0
  # join "#tl" if Channel.all.length==0
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

on :join do
  p $settings
  if (rand($settings["greetings"]["badChance"]) == 0) then
    msg channel, $settings["greetings"]["bad"].choice
  elsif (rand($settings["greetings"]["goodChance"]) == 0) then
    msg channel, $settings["greetings"]["good"].choice
  end
end

on :kick do
  sleep rand(5)
  join Channel::channels_list
end
