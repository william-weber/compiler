class Object
  def metaclass
    class << self; self; end
  end
end

class Language
  attr_accessor :tokens
  attr_accessor :call_stack
  attr_accessor :unassigned_type
  attr_reader :start

  def initialize
    @token_types = []
    @call_stack = []
    yield self
  end

  def rule( name, options = {})
    self.metaclass.send(:define_method, name.to_sym) do
      call = "HEY"
      print "call stack: #{call_stack.join(' ')}\n"
      options.each do |firsts, calls|
        if (firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym })
          call = calls #firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym } or @token_types & firsts 
        elsif (firsts.any?{ |t| t == tokens.first.type })
          call = calls
        end
      end
      returns = [].tap do |array|
        call.split.each do |c|
          @call_stack << c
          array << self.send(c.to_sym) 
        end
      end.flatten
      yield returns if block_given?
      call_stack.shift
      return returns
    end
  end

  def start( name, options = {})
    @start = name
    rule(name, options) do |eof|
      yield eof
    end
  end
  
  def EOF
    p "EOF"
  end

  def terminal(string)
    self.metaclass.send(:define_method, string.to_sym) do
      return tokens.shift if tokens.first.string == string
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
      return tokens.shift if tokens.first.type == type
    end
  end

  def parse
    self.send(@start)
    print "ERROR\n" unless tokens.first.type == :EOF
  end
end
