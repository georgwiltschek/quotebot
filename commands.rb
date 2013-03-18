require 'FourchanBuffer'

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
    @fcBuffer = FourchanBuffer.new
    
    #w titter search
    cmd = Command.new
    cmd.help = "!smoke <string>           -- posts a random tweet about <string>"
    cmd.regex = /^\!smoke (.*?)$/
    cmd.cmd = Proc.new do |hashtag|
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
    cmd = Command.new
    cmd.help = "!dare           -- i dare you to klick this link. i double dare you motherfucker!"
    cmd.regex = /^\!dare/
    cmd.cmd = Proc.new do
      
      board = FourchanBuffer.new.board("b")
      thread = board.threads.choice
      posts = Fourchan::Post.new "b", thread.thread
      post = posts.all.choice

      if post.image then
        msg channel, post.image
      else
        msg channel, post.com
      end
      # msg channel, "LOL"
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