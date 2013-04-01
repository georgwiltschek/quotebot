require 'rubygems'
require 'simple-fourchan'
require 'timers'

class FourchanBuffer
    
  def initialize
    @boards = {}
    @posts = {}
    @threads = {}
    @lastUpdate = {}
  end
    
  # def clean(identifyer)
  #   puts "Cleaning #{identifyer}"
  #   @boards[identifyer] = nil
  #   @posts[identifyer] = nil
  # end
    
  def needs_update(identifyer)
    @lastUpdate[identifyer] == nil || @lastUpdate[identifyer] < Time.now - 600
  end
    
  def thread(identifyer)
    if needs_update(identifyer) then
      puts "one moment..."

      @boards[identifyer] = Fourchan::Board.new identifyer
      # .threads fetches the list... costly
      @threads[identifyer] = @boards[identifyer].threads
      # Lets fetch some fresh new threads full of posts
      @posts[identifyer] = []
      (1..5).each {
        @posts[identifyer].push Fourchan::Post.new identifyer, @threads[identifyer].choice.thread
      }
      
      @lastUpdate[identifyer] = Time.now
    end
  
    @posts[identifyer].choice
  end
  
end