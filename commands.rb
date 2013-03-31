# require 'FourchanBuffer'

class Commands < Array
  
  class Command
    attr_accessor :cmd, :help, :regex
  end


  def initialize
    # cmd = Command.new
    # cmd.help = "!smoke <string>           -- posts a random tweet about <string>"
    # cmd.regex = /^!smoke (.*?)$/
    # cmd.cmd = Proc.new do
    #   puts "nice " + cmd.help
    # end
    # self.push cmd
    # @fcBuffer = FourchanBuffer.new
    
    #w titter search
    cmd = Command.new
    cmd.help = "!smoke <string>           -- posts a random tweet about <string>"
    cmd.regex = /^\!smoke (.*?)$/
    cmd.cmd = Proc.new do |hashtag|
      hashtag = URI::encode(hashtag)
      response = Net::HTTP.get_response("search.twitter.com","/search.json?q="+hashtag.gsub(" ", "%20"))

      if (response.body == nil) then
    	  return
      end

      tweet = JSON.parse(response.body)
      if tweet['error']
      	return
      end
        
      if tweet['results'].size == 0 then
        msg channel, "nichts gefunden :("
        return
      end

      rtweet = tweet['results'].choice # .sample for ruby >= 1.9.1
      msg channel, "#{rtweet['from_user']}: #{rtweet['text']}"
    end
    self.push cmd

    #op testing
    cmd = Command.new
    cmd.help = "op testing"
    cmd.regex = /^\!god/
    cmd.cmd = Proc.new do
    	if (Op.isOp(channel, nick)) then
        msg channel, "Yup"
      else
        msg channel, "Nope"
      end
      puts "optest"
    end
    self.push cmd
    
    # add opp to current channel
    cmd = Command.new
    cmd.help = "!op add <username> -- allow <username> to get op with !op."
    cmd.regex = /^!op add (.*?)$/
    cmd.cmd = Proc.new do |newop|
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
    self.push cmd
    
    # request op from bot
    cmd = Command.new    
    cmd.help = "!op                -- get +op."
    cmd.regex = /^\!op$/
    cmd.cmd = Proc.new do
      if (Op.isOp(channel, nick)) then
        mode(channel, "op " + nick)
      else
          raw ["NOTICE #{nick} :", "nope"].join()
      end
    end
    self.push cmd
    
    # version
    cmd = Command.new
    cmd.help = "!version           -- version information"
    cmd.regex = /^\!version$/
    cmd.cmd = Proc.new do
      raw ["NOTICE #{nick} :", "#{$version} (#{$githash})"].join()
      puts "version"
    end
    self.push cmd

    # # mostly original quote stuff 
    cmd = Command.new
    cmd.help = "!quote             -- return random quote."
    cmd.regex = /^\!quote$/
    cmd.cmd = Proc.new do
      quote = Quote.random
      if quote.nil?
        raw ["NOTICE #{channel} :", "No Quotes :("].join()
      else
        msg channel,quote.first.quote
      end
    end
    self.push cmd
    
    # quote add
    cmd = Command.new
    cmd.help = "!quote add <quote> -- add quote."
    cmd.regex = /^!quote add (.*?)$/
    cmd.cmd = Proc.new do |quoted_message|
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
    self.push cmd
    
    # quote
    cmd = Command.new
    cmd.help = "!quote <string>    -- return random quote containing <string>."
    cmd.regex = /^\!quote (.*?)$/
    cmd.cmd = Proc.new do |contains|
      quote = Quote.random_with_custom "%#{contains}%"
      if (quote.nil? or quote.empty? )
        raw ["NOTICE #{channel} :", "No Quotes :("].join()
      else
        msg channel, quote.first.quote
      end
    end
    self.push cmd
    
    # suicide
    cmd = Command.new
    cmd.help = "!suicide           -- get yourself kicked"
    cmd.regex = /^\!suicide/
    cmd.cmd = Proc.new do
      puts "kicking " + nick
      kick(channel,nick)
    end
    self.push cmd
    
    # 4chan dare
    # Disabled until improved
    #
    # cmd = Command.new 
    # cmd.help = "!dare           -- i dare you to klick this link. i double dare you motherfucker!"
    # cmd.regex = /^\!dare/
    # cmd.cmd = Proc.new do
    #   
    #   board = FourchanBuffer.new.board("b")
    #   thread = board.threads.choice
    #   posts = Fourchan::Post.new "b", thread.thread
    #   post = posts.all.choice
    # 
    #   if post.image then
    #     msg channel, post.image
    #   else
    #     msg channel, post.com
    #   end
    #   # msg channel, "LOL"
    # end
    # self.push cmd
    
    # randomised erowid
    cmd = Command.new
    cmd.help = "!trip              -- random erowid snippet"
    cmd.regex = /^!trip$/
    cmd.cmd = Proc.new do
    	base_url = "http://www.erowid.org"
    	url = "#{base_url}/general/big_chart.shtml"

    	doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
    	links =  doc.css('td.subname a').map { |link| link['href'] }

    	url = "#{base_url}#{links.choice}"

    	doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))
    	desc = doc.css('div.sum-description').text
    	msg channel, "#{desc} [#{url}]"
    end
    self.push cmd
    
    # decision helper
    cmd = Command.new
    cmd.help = "!? <string>        -- decision helper"
    cmd.regex = /^!\? (.*?)$/
    cmd.cmd = Proc.new do |q|
    	q.gsub!("oder","")
    	q.gsub!(","," ")
    	q.gsub("  ", " ")

    	msg channel, "#{q.split(" ").choice}"
    end
    self.push cmd
    
    # magic 8-ball
    cmd = Command.new
    cmd.help = "!8 <string>        -- magic 8 ball"
    cmd.regex = /^!8 (.*?)$/
    cmd.cmd = Proc.new do |q|
    	# ignore q :p
    	answers = ["It is certain","It is decidedly so","Without a doubt","Yes – definitely","You may rely on it","As I see it, yes","Most likely","Outlook good","Yes","Signs point to yes","Reply hazy, try again","Ask again later","Better not tell you now","Cannot predict now","Concentrate and ask again","Don't count on it","My reply is no","My sources say no","Outlook not so good","Very doubtful"]

    	msg channel, "#{answers.choice}."
    end
    self.push cmd
    
    # random wiki
    cmd = Command.new
    cmd.help = "!funfact           -- random wikipedia snippet"
    cmd.regex = /^!funfact$/
    cmd.cmd = Proc.new do
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
    self.push cmd
    
    # if the command was not found before, maybe it's defined
    # in the config file
    cmd = Command.new
    cmd.help = "---"
    cmd.regex = /^!(.*?)$/
    cmd.cmd = Proc.new do |c|
    	if (ret = $config["commands"][c]) != nil
    		msg channel, "#{ret}"
    	end
    end
    self.push cmd
    
    # testing
    cmd = Command.new
    cmd.help = "---"
    cmd.regex = /lolno/
    cmd.cmd = Proc.new do
        msg channel, "Yup"
    end
    self.push cmd
    
    
    puts "done"
    
  end
  

  
end