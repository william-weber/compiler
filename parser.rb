class Object
  def metaclass
    class << self; self; end
  end
end

class Language
  attr_accessor :tokens
  attr_accessor :symbol_table
  attr_accessor :root_table
  attr_accessor :last_return
  attr_accessor :function_returns
  attr_accessor :inside_function
  attr_accessor :code_list
  attr_reader :start

  def initialize
    @token_types = []
    @last_return = {}
    @call_stack = []
    @symbol_table = SymbolTable.new(nil)
    @code_list = IntermediateCodeList.new
    @root_table = @symbol_table
    @gather_expression = false
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
      p "RULE: #{name} calling: #{call.inspect} token: #{tokens.first.string}"
      call_number = 0
      yield attributes if block_given?
      call.split.each do |c|
        attributes.results[call_number] = self.send(c.to_sym) 
        if attributes.results[call_number].is_a? Attributes
          attributes.results[call_number].results = nil
        end
        attributes.last_call = call_number
        yield attributes if block_given?
        call_number += 1
      end
      attributes.after(:all)
      yield attributes if block_given?
      p "attributes after #{name}: #{call} = #{attributes.attributes}"
      return attributes
    end
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
      if @gather_expression
        @code_list.expression << tokens.first.string
      end
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
      if @gather_expression
        @code_list.expression << tokens.first.string
      end
      return tokens.shift if tokens.first.type == type
    end
  end

  def parse
    self.send(@start)
    print "ERROR\n" unless tokens.first.type == :EOF
  end

  def begin_gather_expression
    @gather_expression = true
  end

  def end_gather_expression
    @gather_expression = false
    puts "\t\t\tEXPRESSION: #{@code_list.expression.inspect}"
    @code_list.parse_stored_expression @symbol_table
  end
end

class Attributes
  attr_accessor :attributes, :rule, :results
  attr_accessor :last_call
  attr_accessor :type
  attr_accessor :class

  def initialize
    @attributes = {}
    @results = []
    @last_call = :before_any
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

  def error(message, line_number = 0)
    puts "ERROR on line #{line_number}: #{message}"
    Process.exit
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

  def add(token, type)
    symbol = SymbolEntry.new(token)
    symbol.datatype = type
    self << symbol
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

  def has_and_is_function?(string)
    symbol = find(string)
    symbol.class == :function unless symbol.nil?
  end

  def find(string)
    if !parent.nil?
      symbols.select{ |s| s.string == string }.first or parent.find(string)
    else
      symbols.select{ |s| s.string == string }.first
    end
  end
end

class IntermediateCodeList
  attr_accessor :lines
  attr_accessor :expression

  def initialize
    @lines = []
    @jumps = []
    @expression = []
    @backpatches = []
    @function_allocations = []
    @num_temps = 0
  end

  def start_function(name, return_type, arguments)
    add_line("func", name, return_type, arguments )
    if arguments > 0
      add_line("param")
      @lines += @function_allocations
      @function_allocations = []
    end
  end

  def end_function(name)
    add_line("end", 'func', name)
  end

  def function_allocate(name, type)
    @function_allocations << CodeLine.new('alloc', 4, nil, name)
  end

  def allocate(name, type)
    add_line("alloc", 4, nil, name)
  end

  def add_line(opcode, operand_1 = nil, operand_2 = nil, result = nil)
    @lines << CodeLine.new(opcode.to_s, operand_1.to_s, operand_2.to_s, result.to_s)
    puts "\t\t\tLINE ADDED: #{@lines.last.inspect}"
  end

  def begin_loop
    @backpatches.push @lines.length
    puts "\t\t\tLOOP STARTED: #{@backpatches.last.inspect}"
  end

  def begin_jump
    @jumps.push @lines.length
  end

  def end_jump
    unless @jumps.empty?
      @lines[@jumps.pop + 1].result = @lines.length
    end
  end

  def begin_block
    add_line 'block'
  end

  def return(result)
    add_line 'return', '', '', result
  end

  def end_block
    add_line 'end', 'block'
    unless @backpatches.empty?
      add_line 'br', '', '', @backpatches.pop
    end
  end

  def opcode(index, expression)
    opcodes = { '*' => 'mul', '/' => 'div', '+' => 'add', '-' => 'sub',
                '>=' => 'brlt', '>' => 'brleq', '<=' => 'brgt', '<' => 'brgeq', '==' => 'breq', '!=' => 'brneq' }
    opcodes[expression[index]]
  end

  def parse_stored_expression(symbol_table)
    @expression.pop if @expression.last == ';'
    result = parse_expression(@expression, symbol_table)
    @expression = []
    result
  end

  def parse_expression(expression, symbol_table)
    arg_count = 0
    until expression.length <= 1
      sleep 1
      is_function_call = false
      p expression
      # find first open paren
      open = first_open_paren expression
      # find last close paren
      close = last_close_paren expression
      # if there is expression between them, parse it
      unless open.nil?
        expression[open] = parse_expression(expression[open + 1..close - 1], symbol_table)
        expression.slice! open + 1..close
      end
      # otherwise, parse and replace with temp variable
      # replace parens with temp variable
      index = first_operator expression
      temp = next_temp_variable 
      # if no more operators, look for comparator
      if index.nil?
        index = first_comparator expression
        if index.nil?
          index = first_function_call(expression, symbol_table)
          if index.nil?
            index = last_assignment expression
            if index.nil?
              is_function_call = true
              index = first_comma expression
              unless index.nil?
                until expression.length < 1
                  p expression
                  p "hi"
                  index = first_comma expression
                  if index.nil?
                    add_line 'arg', '', '', expression.first
                    expression = []
                  else
                    add_line 'arg', '', '', expression[index - 1]
                    expression.delete_at(index - 1)
                    expression.delete_at(index - 1)
                  end
                  arg_count += 1
                end
                return arg_count
              end
            else
              is_function_call = true
              add_line 'assign', expression[index + 1], '', expression[index - 1]
              expression.delete_at(index)
              expression.delete_at(index)
            end
          else
            is_function_call = true
            add_line 'call', expression[index], expression[index + 1], temp
            expression[index] = temp
            expression.delete_at(index + 1)
          end
        else
          begin_jump
          add_line 'comp', expression[index -1], expression[index + 1], temp
          add_line opcode(index, expression), temp, '', ''
        end
      else
        add_line opcode(index, expression), expression[index -1], expression[index + 1], temp
      end
      unless index.nil? or is_function_call
        expression[index] = temp
        expression.delete_at(index - 1)
        expression.delete_at(index)
      end
    end
    expression.first
  end

  def next_temp_variable
    "_t#{@num_temps += 1}"
  end

  def first_open_paren(expression)
    expression.index{ |s| s == '(' }
  end

  def first_comma(expression)
    expression.index{ |s| s == ',' }
  end

  def first_function_call(expression, table)
    expression.index{ |s| table.has_and_is_function? s }
  end

  def last_close_paren(expression)
    index = expression.reverse.index{ |s| s == ')' } 
    unless index.nil?
      return expression.length - index - 1
    end
  end

  def first_operator(expression)
    index = nil
    index = expression.index{ |s| s == '/' }
    index ||= expression.index{ |s| s == '*' }
    index ||= expression.index{ |s| s == '+' or s == '-' }
    index
  end

  def first_comparator(expression)
    expression.index{ |s| [ '>=', '>', '<=', '<', '==', '!=' ].include? s }
  end

  def first_assignment(expression)
    expression.index{ |s| s == '=' }
  end

  def last_assignment(expression)
    index = expression.reverse.index{ |s| s == '=' } 
    unless index.nil?
      return expression.length - index - 1
    end
  end
end

class CodeLine
  attr_accessor :opcode, :operand_1, :operand_2, :result

  def initialize(opcode, operand_1, operand_2, result)
    @opcode = opcode
    @operand_1 = operand_1
    @operand_2 = operand_2
    @result = result
  end
end
