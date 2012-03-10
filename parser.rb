class Object
  def metaclass
    class << self; self; end
  end
end

class Language
  attr_accessor :tokens
  attr_reader :start

  def initialize
    @token_types = []
    yield self
  end

  def accept(type)
    p "ACCEPT"
    return tokens.shift if tokens.first.type == type
  end

  def rule( name, options = {})
    self.metaclass.send(:define_method, name.to_sym) do
      p "RULE NAME: #{name} token: #{tokens.first.string}"
      call = "HEY"
      options.each do |firsts, calls|
        if (firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym })
          call = calls #firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym } or @token_types & firsts 
        elsif (firsts.any?{ |t| t == tokens.first.type })
          p "calling type #{tokens.first.type}"
          call = calls
        end
      end
      p "CALL: #{call}"
      call.split.each do |c|
        self.send(c.to_sym) 
      end
    end
  end

  def start( name, options = {})
    @start = name
    rule(name, options)
  end
  
  def EOF
    p "EOF"
  end

  def terminal(string)
    self.metaclass.send(:define_method, string.to_sym) do
      p "TERMINAL name #{string}"
      p tokens.first.string
      return tokens.shift if tokens.first.string == string
      return ""
    end
  end

  def terminals(array)
    array.each do |term|
      self.terminal(term)
    end
  end

  def token(type)
    @token_types << type.to_s
    self.metaclass.send(:define_method, type.to_sym) do
      accept(type)
      p "accepted..."
      p tokens.first.string unless tokens.empty?
    end
  end

  def parse
    self.send(@start)
    print "ERROR\n" unless tokens.empty?
  end
end
