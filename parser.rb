class Object
  def metaclass
    class << self; self; end
  end
end

class Language
  attr_accessor :tokens
  attr_accessor :symbol_table
  attr_accessor :root_table
  attr_reader :start

  def initialize
    @token_types = []
    @call_stack = []
    @symbol_table = SymbolTable.new(nil)
    @root_table = @symbol_table
    yield self
  end

  def rule( name, options = {})
    self.metaclass.send(:define_method, name.to_sym) do
      attributes = Attributes.new
      rule_number = 0
      call = "Sorry, this program does not fit the grammar you have defined."
      #print "call stack: #{call_stack.join(' ')}\n"
      options.each do |firsts, calls|
        if (firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym })
          call = calls #firsts.any?{ |t| t.to_sym == tokens.first.string.to_sym } or @token_types & firsts 
          attributes.rule = calls
        elsif (firsts.any?{ |t| t == tokens.first.type })
          call = calls
          attributes.rule = calls
        end
        rule_number += 1
      end
      #p "RULE: #{name} calling: #{call}"
      call_number = 0
      call.split.each do |c|
        attributes.results[call_number] = self.send(c.to_sym) 
        if attributes.results[call_number].is_a? Attributes
          attributes.results[call_number].results = nil
          if !attributes.error.nil?
            error attributes.error
            break
          end
        end
        attributes.last_call = call_number
        yield attributes if block_given?
        call_number += 1
      end
      attributes.after(:all)
      yield attributes if block_given?
      return attributes
    end
  end

  def error(message)
    puts message
    Process.exit
  end

  def start( name, options = {})
    @start = name
    rule(name, options) do |eof|
      yield eof
    end
  end
  
  def EOF
    p "EOF. Parse finished."
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

class Attributes
  attr_accessor :attributes, :rule, :results
  attr_accessor :error
  attr_accessor :last_call

  def initialize
    @error = nil
    @attributes = {}
    @results = []
  end

  def after(call)
    @last_call = call
  end

  def returning(options)
    if options[:rule] == self.rule and options[:call] == self.last_call
      yield 
    elsif options[:rule] == :any and options[:call] == self.last_call
      yield
    end
  end
end

class SymbolEntry
  attr_accessor :string, :datatype, :class, :location
  attr_accessor :argument_count, :argument_types
  attr_accessor :line_number

  def initialize(token)
    @string = token.string
    @line_number = token.line_number
  end

  def ==(symbol)
    string == symbol.string
  end
end

class SymbolTable
  attr_accessor :symbols, :children
  attr_reader :parent

  def initialize(parent)
    @parent = parent
    @symbols = []
    @children = []
  end

  def <<(symbol)
    if include? symbol.string
      puts "Duplicate symbol #{symbol.string} already declared. Duplicate on line #{symbol.line_number}, original on line #{find(symbol.string).line_number}."
      Process.exit 
    end
    @symbols << symbol
  end

  def new_child
    child = SymbolTable.new(self)
    @children << child
    return child
  end

  def include?(string)
    if !parent.nil?
      symbols.map(&:string).include?(string) or parent.include?(string)
    else
      symbols.map(&:string).include?(string)
    end
  end

  def find(string)
    if !parent.nil?
      symbols.select{ |s| s.string == string }.first or parent.find(string)
    else
      symbols.select{ |s| s.string == string }.first
    end
  end
end
