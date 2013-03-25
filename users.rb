# module Users
  
  class UserManager
    
    def self.add_active_user (nick, channel)
      user = User.create(:nick => nick, :channel => channel)
      user.save
    end
    
    def self.rename_user (nick, channel)
      user = User.first(:nick => nick, :channel => channel)
      user.update(:nick => nick) if user
    end
    
    def self.remove_user (nick, channel)
      user = User.first(:nick => nick, :channel => channel)
      user.update(:isActive => true) if user
    end
    
    def self.active_users
      return User.all
    end
    
  end
  
  class User
    include DataMapper::Resource

    property :id, Serial
    property :channel, String
    property :nick, String
    property :isActive, Boolean, :default => true
    
    
  end
  
  class Op < User
    property :password, String
    property :isAuthorized, Boolean

    def self.isOp v1, v2
    	## add first user who tries to be op
    	if all.length == 0 then
    		first = Op.new
    		first.channel = v1
    		first.nick = v2
    		first.save
    		return true
    	end

    	return repository.adapter.select("SELECT * FROM ops where channel = ? and nick = ? ORDER BY RANDOM() LIMIT 1", v1, v2).size() > 0 
    end
  
    def self.activate user, password
      account = Op.first(:nick => user, :password => password)
      if account then
        p account
      end
    end
  
  end
# end