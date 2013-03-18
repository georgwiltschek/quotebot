require 'rubygems'
require 'simple-fourchan'
require 'timers'

class FourchanBuffer
    
  def initialize
    @boards = {}
    @invalidationTimer = {}
  end
    
  def board(identifyer)
    if @boards[identifyer] == nil then
      
      #reset the buffer after a while
      @invalidationTimer[identifyer] = 
            Timers.new.after(30) { @boards[identifyer] = nil }
      @boards[identifyer] = Fourchan::Board.new "b"
    end
  end
  
end