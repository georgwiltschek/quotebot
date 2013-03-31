require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'isaac'
require 'database'
require 'yaml'
require 'twitter'
require 'json'
require 'simple-fourchan'

# Extend Isaac
module Isaac
  class Bot
    def clean(event)
      @events[event] = nil
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


on :connect do
  # take stuff from db
  #  join Channel.channels_list unless Channel.all.size==0
  # join "#tl" if Channel.all.length==0
  join $config["config"]["default_channel"] 
end


# randomised erowid
on :channel, /^!trip$/ do
	base_url = "http://www.erowid.org"
	url = "#{base_url}/general/big_chart.shtml"

	doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
	links =  doc.css('td.subname a').map { |link| link['href'] }

	url = "#{base_url}#{links.choice}"

	doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
	desc = doc.css('div.sum-description').text
	msg channel, "#{desc} [#{url}]"
end

# decision helper
on :channel, /^!\? (.*?)$/ do |q|

	q.gsub!("oder","")
	q.gsub!(","," ")
	q.gsub("  ", " ")

	msg channel, "#{q.split(" ").choice}"
end

# magic 8-ball
on :channel, /^!8 (.*?)$/ do |q|
	# ignore q :p
	answers = ["It is certain","It is decidedly so","Without a doubt","Yes – definitely","You may rely on it","As I see it, yes","Most likely","Outlook good","Yes","Signs point to yes","Reply hazy, try again","Ask again later","Better not tell you now","Cannot predict now","Concentrate and ask again","Don't count on it","My reply is no","My sources say no","Outlook not so good","Very doubtful"]

	msg channel, "#{answers.choice}."
end

# random wiki
on :channel, /^!funfact$/ do
	tries	  = 0
	finished  = false
	min_words = 7 
	max_tries = 10

	# try up to max_tries random pages
	while tries < max_tries && !finished do
		randlang = ["de", "en"].choice
		url = "http://#{randlang}.wikipedia.org/wiki/Special:Random"
		
		# get random wikipedia page
		doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
		
		# find all paragraphs of main text, remove citation numbers
		# split into sentences (kind of) and shuffle the array of
		# sentences
		ret = doc.css('div.mw-content-ltr').css('p').text
		ret = ret.gsub(/\[.+?\]/, "").split(/(?:\.|\?|\!)(?= [^a-z]|$)/)
		ret.map!(&:lstrip)
		ret.shuffle!

		# find a sentence that's long enough and finish
		ret.each do |r|
			if r.split(" ").length > min_words then
    			msg channel, "#{r}."
				finished = true
				break	
			end
		end
		
		tries += 1
	end
end

# twitter search
on :channel, /^!smoke (.*?)$/ do |hashtag|
  # searchResults = Twitter.search("test", :count => 1).results
  # msg searchResults.first.text
  # msg "#tl_test","ok"
  hashtag = URI::encode(hashtag)
  response = Net::HTTP.get_response("search.twitter.com","/search.json?q="+hashtag.gsub(" ", "%20"))

  if (response.body == nil) then
	  return
  end

  tweet = JSON.parse(response.body)
 
  if tweet['results'].size == 0 then
    msg channel, "nichts gefunden :("
    return
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

	if ($help.empty?) then
		$help.push("!help              -- obvious :p") 
		$help.push("!version           -- version information") 
		$help.push("!smoke <string>    -- search twitter for <string>.") 
		$help.push("!quote add <quote> -- add quote.") 
		$help.push("!quote             -- return random quote.") 
		$help.push("!quote <string>    -- return random quote containing <string>.")
		$help.push("!quote <user>      -- return random quote added by <username>.") 
		$help.push("!funfact           -- random wikipedia snippet") 
		$help.push("!trip              -- random erowid snippet") 
		$help.push("!? <string>        -- decision helper") 
		$help.push("!8 <string>        -- magic 8 ball")
		$help.push("!habemus           -- ")
		$help.push("!ping              -- ")

	end

	if ($helpop.empty?) then
		$helpop.push("!op                -- get +op.")
		$helpop.push("!op add <username> -- allow <username> to get op with !op.")
	end

	$help.each do |h|
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
  if $settings["greetings"]["goodPeople"].include?(nick) then
    msg channel, $settings["greetings"]["good"].choice
  elsif (rand($settings["greetings"]["badChance"]) == 0) then
    msg channel, $settings["greetings"]["bad"].choice
  elsif (rand($settings["greetings"]["goodChance"]) == 0) then
    msg channel, $settings["greetings"]["good"].choice
  end
end

on :kick do
  sleep rand(5)
  join Channel::channels_list
end

on :channel, /^!quote add (.*?)$/ do |quoted_message|
  quote=Quote::create(:user=>nick,:quote=>quoted_message)
  #should always work #first_or_create
  quote.channel=Channel.first_or_create(:channel=>channel)
  quote.save
  if quote.saved?
  	raw ["NOTICE #{channel} :", "Quote added"].join()
  else
  	raw ["NOTICE #{channel} :", "Quote not added"].join()
  end
end

on :channel, /^\!quote (.*?)$/ do |contains|
  quote = Quote.random_with_custom "%#{contains}%"
  if (quote.nil? or quote.empty? )
  	raw ["NOTICE #{channel} :", "No Quotes :("].join()
  else
    msg channel, quote.first.quote
  end
end

# if the command was not found before, maybe it's defined
# in the config file
on :channel, /^!(.*?)$/ do | c |
	if (ret = $config["commands"][c]) != nil
		msg channel, "#{ret}"
	end
end

