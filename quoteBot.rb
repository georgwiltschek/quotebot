require 'rubygems'
require 'isaac'
require 'database'


configure do |c|
  c.server		= "irc.server.com"
  c.port		= 6667
  c.realname	= "quotebot"
  c.nick		= "quotebot"
end

on :connect do
  # take stuff from db
  #  join Channel.channels_list unless Channel.all.size==0
  # join "#tl" if Channel.all.length==0
  join "#testchannelquotebot123"
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

