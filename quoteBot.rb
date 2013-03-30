require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'open-uri'
require 'isaac'
require 'database'
require 'yaml'
require 'twitter'
require 'json'

$config  = YAML.load_file("config.yml")
$version = "0.1"
$githash = `git log -1 --pretty=format:%h | head -c 8`
$help    = Array.new()
$helpop  = Array.new()

$simple_commands = YAML.load_file("simplecommands.yml")

configure do |c|
  c.server   = $config["config"]["server"]
  c.port     = $config["config"]["port"]
  c.realname = $config["config"]["realname"]
  c.nick     = $config["config"]["nick"]
end

on :connect do
  # take stuff from db
  #  join Channel.channels_list unless Channel.all.size==0
  # join "#tl" if Channel.all.length==0
  join $config["config"]["default_channel"] 
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
  response = Net::HTTP.get_response("search.twitter.com","/search.json?q="+hashtag.gsub(" ", "%20"))

  if (response.body == nil) then
	  return
  end

  tweet = JSON.parse(response.body)
 
  if tweet['results'].size == 0 then
    msg channel, "nichts gefunden :("
    return
  end

  rtweet = tweet['results'].choice # .sample for ruby >= 1.9.1
  msg channel, "#{rtweet['from_user']}: #{rtweet['text']}"
end

# add opp to current channel
on :channel, /^!op add (.*?)$/ do |newop|
	# caller must already be op (except first caller, 
	# which get automatically added to ops)
	if (!Op.isOp(channel, nick)) then
  		raw ["NOTICE #{channel} :", "only ops can do this"].join()
		return
	end

	# only add once
	if (Op.isOp(channel, newop)) then
  		raw ["NOTICE #{nick} :", "#{newop} is already op"].join()
	else
		n = Op.new
		n.channel = channel
		n.nick = newop
		n.save
  		raw ["NOTICE #{nick} :", "#{newop} added to ops"].join()
	end
end

# request op from bot
on :channel, /^\!op$/ do
	if (Op.isOp(channel, nick)) then
		mode(channel, "op " + nick)
	else
  		raw ["NOTICE #{nick} :", "nope"].join()
	end
end

on :channel, /^\!help$/ do

	if ($help.empty?) then
		$help.push("!help              -- obvious :p") 
		$help.push("!version           -- version information") 
		$help.push("!smoke <string>    -- search twitter for <string>.") 
		$help.push("!quote add <quote> -- add quote.") 
		$help.push("!quote             -- return random quote.") 
		$help.push("!quote <string>    -- return random quote containing <string>.")
		$help.push("!quote <user>      -- return random quote added by <username>.") 
	end

	if ($helpop.empty?) then
		$helpop.push("!op                -- get +op.")
		$helpop.push("!op add <username> -- allow <username> to get op with !op.")
	end

	$help.each do |h|
  		raw ["NOTICE #{nick} :", h].join()
	end

	if (Op.isOp(channel, nick)) then
		$helpop.each do |h|
  			raw ["NOTICE #{nick} :", h].join()
		end
	end
end

on :channel, /^\!version$/ do
	raw ["NOTICE #{nick} :", "#{$version} (#{$githash})"].join()
end

# mostly original quote stuff 
on :channel, /^\!quote$/ do
  quote = Quote.random
  if quote.nil?
  	raw ["NOTICE #{channel} :", "No Quotes :("].join()
  else
    msg channel,quote.first.quote
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

