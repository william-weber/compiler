load "./token.rb"
load "./lexer.rb"
load "./parser.rb"

# Create a new Language and define rules for it.
parser = Language.new do |p|
  p.terminals [ "int", "void", "float", "if", "while", "return", "else" ]
  p.terminals [ "+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}" ]
  p.token :integer
  p.token :floatnumber
  p.token :identifier

  # These rules are in the form of [ first, first, first ] => "rules to follow",
  # where "first" is a first (and/or follow) of the grammar rule.
  p.start :A,   [ :int, :void, :float ] => "E identifier C B" do |after|
    after.returning :rule => "E identifier C B", :call => 1 do
      p.symbol_table.add(after.results[1], after.results[0].type)
      p.function_returns = false
    end
    after.returning :rule => "E identifier C B", :call => 2 do
      if after.results[2].class == :function
        # check return type
        # if function returns
        if p.function_returns
          # functions of type void should not return
          if after.results[0].type == :void
            after.error "Functions declared void should not have return values", after.results[1].line_number
          end

        # if function does not return
        else
          # functions with return types other than void should have return
          if after.results[0].type != :void
            after.error "Function needs return value", after.results[1].line_number
          # otherwise, update in symbol table
          end         
        end 
      end
    end
  end

  p.rule :B,    [ :int, :void, :float ] => "E identifier C B", [:EOF] => "EOF" do |after|
    after.returning :rule => "E identifier C B", :call => 1 do
      p.symbol_table.add(after.results[1], after.results[0].type)
      p.function_returns = false
    end
    after.returning :rule => "E identifier C B", :call => 2 do
      if after.results[2].class == :function
        # check return type
        # if function returns
        if p.function_returns
          # functions of type void should not return
          if after.results[0].type == :void
            after.error "Functions declared void should not have return values.", after.results[1].line_number
          end

        # if function does not return
        else
          # functions with return types other than void should have return
          if after.results[0].type != :void
            after.error "Function needs return value", after.results[1].line_number
          end         
        end 
      end
    end
  end

  p.rule :C,    [ ";", "[" ] => "D", [ "(" ] => "( G ) { K L }" do |after|
    after.returning :rule => "D", :call => 0 do
      p.symbol_table.symbols.last.class = after.results[0].class
    end
    # change symbol table scope for local variables
    after.returning :rule => "( G ) { K L }", :call => 0 do
      p.inside_function = p.symbol_table.symbols.last
      p.symbol_table = p.symbol_table.new_child
    end
    after.returning :rule => "( G ) { K L }", :call => 1 do
      p.symbol_table.parent.symbols.last.argument_count = after.results[1].attributes[:argument_count]
      p.symbol_table.parent.symbols.last.argument_types = after.results[1].attributes[:argument_types]
      p.symbol_table.parent.symbols.last.class = :function

      p.code_list.start_function p.inside_function.string, p.inside_function.datatype, p.inside_function.argument_count 
    end
    after.returning :rule => "( G ) { K L }", :call => 6 do
      after.class = :function
      after.type = after.results[5].type
      p.symbol_table = p.symbol_table.parent
      p.code_list.end_function p.symbol_table.symbols.last.string
    end
  end

  p.rule :D,    [ ";" ] => ";", [ "[" ] => "[ integer ] ;" do |after|
    after.returning :rule => ";", :call => 0 do
      after.class = :variable
    end
    after.returning :rule => "[ integer ] ;", :call => 0 do
      after.class = :array
    end
  end

  p.rule :E,    [ "int" ] => "int", [ "void" ] => "void", [ "float" ] => "float" do |after|
    after.returning :rule => "int", :call => 0 do
      after.type = :integer
    end
    after.returning :rule => "void", :call => 0 do
      after.type = :void
    end
    after.returning :rule => "float", :call => 0 do
      after.type = :floatnumber
    end
  end

  p.rule :G,    [ "int" ] => "int identifier I H", [ "float" ] => "float identifier I H", [ "void" ] => "void GA" do |after|
    after.returning :rule => "int identifier I H", :call => 2 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.class = after.results[2].class
      symbol.datatype = :integer
      p.symbol_table << symbol
      p.code_list.function_allocate symbol.string, symbol.datatype
    end
    after.returning :rule => "int identifier I H", :call => 3 do
      after.attributes[:argument_count] = 1
      after.attributes[:argument_count] += after.results[3].attributes[:argument_count] unless after.results[3].nil?
      after.attributes[:argument_types] = [ :integer ]
      after.attributes[:argument_types] += after.results[3].attributes[:argument_types] unless after.results[3].nil?
    end
    after.returning :rule => "float identifier I H", :call => 2 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.class = after.results[2].class
      symbol.datatype = :floatnumber
      p.symbol_table << symbol
      p.code_list.function_allocate symbol.string, symbol.datatype
    end
    after.returning :rule => "float identifier I H", :call => 3 do
      after.attributes[:argument_count] = 1
      after.attributes[:argument_count] += after.results[3].attributes[:argument_count] unless after.results[3].nil?
      after.attributes[:argument_types] = [ :floatnumber ]
      after.attributes[:argument_types] += after.results[3].attributes[:argument_types] unless after.results[3].nil?
    end
    after.returning :rule => "void GA", :call => 1 do
      after.attributes[:argument_count] = after.results[1].attributes[:argument_count]
      after.attributes[:argument_types] = after.results[1].attributes[:argument_types]
    end
  end

  p.rule :GA,   [ :identifier ] => "identifier I H", [ ")" ] => "" do |after|
    after.returning :rule => "identifier I H", :call => 1 do
      symbol = SymbolEntry.new(after.results[0])
      # cannot declare void arrays!
      if after.results[1].class != :variable
        after.error "Function arguments of void can't be arrays", after.results[0].line_number
      end
      symbol.class = :variable
      symbol.datatype = :void
      p.symbol_table << symbol
    end
    after.returning :rule => "identifier I H", :call => 2 do
      after.attributes[:argument_count] = 1
      after.attributes[:argument_count] += after.results[2].attributes[:argument_count] unless after.results[2].nil?
      after.attributes[:argument_types] = [ :void ]
      after.attributes[:argument_types] += after.results[2].attributes[:argument_types] unless after.results[2].nil?
    end
    after.returning :rule => "", :call => :all do
      after.attributes[:argument_count] = 0
      after.attributes[:argument_types] = []
    end
  end

  p.rule :H,    [ "," ] => ", E identifier I H", [ ")" ] => "" do |after|
    after.returning :rule => ", E identifier I H", :call => 3 do
      symbol = SymbolEntry.new(after.results[2])
      symbol.class = after.results[3].class
      symbol.datatype = after.results[1].type
      p.symbol_table << symbol
      p.code_list.function_allocate symbol.string, symbol.datatype
      after.attributes[:argument_count] = 1
      after.attributes[:argument_count] += after.results[4].attributes[:argument_count] unless after.results[4].nil?
      after.attributes[:argument_types] = [ after.results[1].type ]
      after.attributes[:argument_types] += after.results[4].attributes[:argument_types] unless after.results[4].nil?
    end
    after.returning :rule => "", :call => :all do
      after.attributes[:argument_count] = 0
      after.attributes[:argument_types] = []
    end
  end

  p.rule :I,    [ "[" ] => "[ ]", [ ",", ")" ] => "" do |after|
    after.returning :rule => "[ ]", :call => 0 do
      after.class = :array
    end
    after.returning :rule => "", :call => :all do
      after.class = :variable
    end
  end

  p.rule :K,    [ "int", "void", "float" ] => "E identifier D K", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "}" ] => "" do |after|
    after.returning :rule => "E identifier D K", :call => 2 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.datatype = after.results[0].type
      p.symbol_table << symbol

      p.code_list.allocate symbol.string, symbol.datatype
    end
  end

  p.rule :L,    [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return" ] => "M L", [ "}" ] => "" do |after|
    after.returning :rule => "M L", :call => 0 do
      after.type = after.results[0].type 
      p.last_return[:L] = after.type
    end
    after.returning :rule => "", :call => 0 do
      after.type = p.last_return[:L]
    end
  end

  p.rule :M,    [ :identifier, "(", :integer, :floatnumber, ";" ] => "N", [ "{" ] => "{ K L }", [ "if" ] => "if ( R ) M O", [ "while" ] => "while ( R ) M", [ "return" ] => "return Q" do |after|
    after.returning :rule => 'return Q', :call => 0 do
      p.begin_gather_expression
    end
    after.returning :rule => "return Q", :call => 1 do
      after.type = after.results[1].type
      # return type must match type of function
      if p.inside_function.datatype != after.results[1].type
        after.error "Mismatched return type", after.results[0].line_number
      end
      p.function_returns = true
      p.code_list.return p.end_gather_expression
    end
    # change symbol table scope for local variables
    after.returning :rule => "{ K L }", :call => 0 do
      p.symbol_table = p.symbol_table.new_child
      p.code_list.begin_block
    end
    after.returning :rule => "{ K L }", :call => 3 do
      after.type = after.results[2].type
      p.symbol_table = p.symbol_table.parent
      p.code_list.end_block
      p.code_list.end_jump
    end
    after.returning :rule => "while ( R ) M", :call => 1 do
      p.code_list.begin_loop
      p.begin_gather_expression
    end
    after.returning :rule => "while ( R ) M", :call => 2 do
      p.end_gather_expression
    end
  end

  p.rule :N,    [ :identifier, "(", :integer, :floatnumber ] => "R ;", [ ";" ] => ";" do |after|
    after.returning :rule => 'R ;', :call => :before_any do
      p.begin_gather_expression
    end
    after.returning :rule => "R ;", :call => 0 do
      after.type = after.results[0].type
      p.end_gather_expression
    end
  end

  p.rule :O,    [ "else" ] => "else M", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "}" ] => ""

  p.rule :Q,    [ ";" ] => ";", [ :identifier, "(", :integer, :floatnumber ] => "R ;" do |after|
    after.returning :rule => ";", :call => 0 do
      after.type = :pass
    end
    after.returning :rule => "R ;", :call => 0 do
      after.type = after.results[0].type
    end
  end

  p.rule :R,    [ :identifier ] => "identifier P", [ "(" ] => "( R ) X V T", [ :integer ] => "integer X V T", [ :floatnumber ] => "floatnumber X V T" do |after|
    after.returning :rule => "identifier P", :call => 0 do
      # check if identifier is in symbol table
      unless p.symbol_table.include? after.results[0].string
        after.error "Undeclared variable or uninitialized function '#{after.results[0].string}'", after.results[0].line_number
      end
    end
    after.returning :rule => "identifier P", :call => 1 do
      symbol = p.symbol_table.find(after.results[0].string) 
      after.type = symbol.datatype
      # if P is a function call
      if after.results[1].class == :function
        # identifier must be a function
        if symbol.class != :function
          after.error "Expected function call, got #{symbol.class} for #{symbol.string}", after.results[0].line_number
        # check argument types and number
        else
          error = ""
          if symbol.argument_count != after.results[1].attributes[:argument_count]
            error += "Wrong number of arguments given. Expected #{symbol.argument_count} got #{after.results[1].attributes[:argument_count].inspect}. "
          end
          if symbol.argument_types != after.results[1].attributes[:argument_types]
            error += "Mismatched attribute types. Expected #{symbol.argument_types.join(' ')} got #{after.results[1].attributes[:argument_types].inspect}"
          end
          if !error.empty?
            after.error error, after.results[0].line_number
          end
        end
      # if P is an assignment, types must agree
      elsif after.results[1].class == :assignment
        if after.results[1].type != symbol.datatype
          after.error "Cannot assign #{after.results[1].type} to #{symbol.datatype}", after.results[0].line_number
        end
      # if P is a boolean, entire statement is boolean
      elsif after.results[1].type == :boolean
        after.type = :boolean
      # otherwise, P is arithmetic and types must match
      elsif after.results[1].type != symbol.datatype and !after.results[1].type.nil?
        after.error "Type mismatch. #{symbol.string}", after.results[0].line_number
      end
    end
    after.returning :rule => "( R ) X V T", :call => 5 do
      # types of all must match
      if after.results[3..5].push(after.results[1]).map{ |r| r.type }.compact.uniq.length > 1
        after.error "Type mismatch.", after.results[0].line_number
      else
        if after.results[5].type == :boolean
          after.type = :boolean
        else
          after.type = after.results[1].type
        end
      end
    end
    after.returning :rule => "integer X V T", :call => 3 do
      # types of all must match
      unless after.results.all?{ |r| r.type == :integer or r.type == nil }
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = :integer
    end
    after.returning :rule => "floatnumber X V T", :call => 3 do
      # types of all must match
      unless after.results.all?{ |r| r.type == :floatnumber or r.type == nil }
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = :floatnumber
    end
  end

  p.rule :P,    [ "[" ] => "[ R ] S", [ "(" ] => "( F ) X V T", [ "=", "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "S" do |after|
    after.returning :rule => "[ R ] S", :call => 1 do
      # R must not be a float
      if after.results[1].type != :integer
        after.error "Array index must be an integer", after.results[0].line_number
      end
    end
    after.returning :rule => "[ R ] S", :call => 3 do
      if after.results[3].class == :assignment
        after.class = :assignment
      end
      after.type = after.results[3].type
    end
    after.returning :rule => "( F ) X V T", :call => 5 do
      after.class = :function
      after.attributes[:argument_count] = after.results[1].attributes[:argument_count]
      after.attributes[:argument_types] = after.results[1].attributes[:argument_types]
      # types of X V T must match
      if after.results[3..5].map{ |r| r.type }.compact.uniq.length > 1
        after.error "Type mismatch.", after.results[0].line_number
      else
        if after.results[5].type == :boolean
          after.type = :boolean
        else
          after.type = after.results[3].type
        end
      end
    end
    after.returning :rule => "S", :call => 0 do
      if after.results[0].class == :assignment
        after.class = :assignment
      end
      after.type = after.results[0].type
    end
  end

  p.rule :S,    [ "=" ] => "= R", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "X V T" do |after|
    after.returning :rule => "= R", :call => 1 do
      after.class = :assignment
      after.type = after.results[1].type
    end
    after.returning :rule => "X V T", :call => 2 do
      if after.results[0..1].map{ |r| r.type }.compact.uniq.length > 1
        after.error "Type mismatch in rule S. #{after.inspect}"
      else
        if after.results[2].type == :boolean
          after.type = :boolean
        # TODO make test
        elsif !after.results.empty?
          after.type = after.results[0].type
        end
      end
    end
  end

  p.rule :T,    [ ">=", ">", "<", "<=", "==", "!=" ] => "U Z X V T", [ ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "U Z X V T", :call => 4 do
      after.type = after.results[0].type
      p.last_return[:T] = after.results[0].type
      unless after.results[1..3].map{ |r| r.type }.compact.uniq.length == 1
        after.error "Type mismatch.", after.results[0].attributes[:line_number]
      end
    end
    after.returning :rule => "", :call => 0 do
      after.type = p.last_return[:T] == :boolean ? :boolean : nil
    end
  end

  p.rule :U,    [ ">=" ] => ">=", [ ">" ] => ">", [ "<" ] => "<", [ "<=" ] => "<=", [ "==" ] => "==", [ "!=" ] => "!=" do |after|
    after.returning :rule => :any, :call => 0 do
      after.attributes[:line_number] = after.results[0].line_number
      after.type = :boolean
    end
  end

  p.rule :V,    [ "+" ] => "+ Z X V", [ "-" ] => "- Z X V", [ ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "+ Z X V", :call => 3 do
      unless after.results[1..3].map{ |r| r.type }.compact.uniq.length == 1
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = after.results[1].type
    end
    after.returning :rule => "- Z X V", :call => 3 do
      unless after.results[1..3].map{ |r| r.type }.compact.uniq.length == 1
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = after.results[1].type
    end
    after.returning :rule => "", :call => 0 do
      after.type = nil
    end
  end

  p.rule :X,    [ "*" ] => "* Z X", [ "/" ] => "/ Z X", [ "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "* Z X", :call => 2 do
      unless after.results[1..2].map{ |r| r.type }.compact.uniq.length == 1
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = after.results[1].type
    end
    after.returning :rule => "/ Z X", :call => 2 do
      unless after.results[1..2].map{ |r| r.type }.compact.uniq.length == 1
        after.error "Type mismatch.", after.results[0].line_number
      end
      after.type = after.results[1].type
    end
    after.returning :rule => "", :call => 0 do
      after.type = nil
    end
  end

  p.rule :Z,    [ "(" ] => "( R )", [ :identifier ] => "identifier W", [ :integer ] => "integer", [ :floatnumber ] => "floatnumber" do |after|
    after.returning :rule => "( R )", :call => 2 do
      after.type = after.results[1].type
    end
    after.returning :rule => "identifier W", :call => 0 do
      # check if identifier is in symbol table
      if !p.symbol_table.include? after.results[0].string
        after.error "Undeclared variable or uninitialized function '#{after.results[0].string}'", after.results[0].line_number
      end
    end
    after.returning :rule => "identifier W", :call => 1 do
      # check function argument # and type if W is a function call
      symbol = p.symbol_table.find(after.results[0].string) 
      if after.results[1].class == :function
        # identifier must be a function
        if symbol.class != :function
          attributes.error "Expected function call, got #{symbol.class} for #{symbol.string}", after.results[0].line_number
        else
          error = ""
          if symbol.argument_count != after.results[1].argument_count
            error += "Wrong number of arguments given. Expected #{symbol.argument_count} got #{after.results[1].attributes[:argument_count]}. "
          end
          if symbol.argument_types != after.results[1].argument_types
            error += "Mismatched attribute types. Expected #{symbol.argument_types.join(' ')} got #{after.results[1].attributes[:argument_types].join(' ')}. "
          end
          if !error.empty?
            attributes.error error, after.results[0].line_number
          end
        end
      end
      after.type = symbol.datatype
    end
    after.returning :rule => "integer", :call => 0 do
      after.type = :integer
    end
    after.returning :rule => "floatnumber", :call => 0 do
      after.type = :floatnumber
    end
  end

  p.rule :W,    [ "[" ] => "[ R ]", [ "(" ] => "( F )", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "[ R ]", :call => 1 do
      # R must not be a float
      if after.results[1].type != :integer
        after.error "Array index must be an integer", after.results[0].line_number
      end
    end
    after.returning :rule => "( F )", :call => 1 do
      after.class = :function
      after.attributes[:argument_count] = results[1].attributes[:argument_count]
      after.attributes[:argument_types] = results[1].attributes[:argument_types]
    end
  end

  p.rule :F,    [ :identifier, "(", :integer, :floatnumber ] => "R J", [ ")" ] => "" do |after|
    after.returning :rule => "R J", :call => 0 do
      # function argument # and type must match
      # count function arguments and record types in attribute hash
      after.attributes[:argument_count] = 1
      after.attributes[:argument_types] = [ after.results[0].type ]
    end
    after.returning :rule => "R J", :call => 1 do
      # function argument # and type must match
      # count function arguments and record types in attribute hash
      after.attributes[:argument_count] += after.results[1].attributes[:argument_count] unless after.results[1].attributes[:argument_count].nil?
      after.attributes[:argument_types] += after.results[1].attributes[:argument_types] unless after.results[1].attributes[:argument_types].nil?
    end
    after.returning :rule => "", :call => :all do
      after.attributes[:argument_count] = 0
      after.attributes[:argument_types] = []
    end
  end

  p.rule :J,    [ "," ] => ", R J", [ ")" ] => "" do |after|
    after.returning :rule => ", R J", :call => 1 do
      after.attributes[:argument_count] = 1
      after.attributes[:argument_types] = [ after.results[1].type ]
    end
    after.returning :rule => ", R J", :call => 2 do
      after.attributes[:argument_count] += after.results[2].attributes[:argument_count] unless after.results[2].attributes[:argument_count].nil?
      after.attributes[:argument_types] += after.results[2].attributes[:argument_types] unless after.results[2].attributes[:argument_types].nil?
    end
    after.returning :rule => "", :call => :all do
      after.attributes[:argument_count] = 0
      after.attributes[:argument_types] = []
    end
  end
end



# Create a new Lexer with the input file
lexer = Lexer.new(ARGV[0])
lexer.parse
parser.tokens = lexer.tokens
parser.tokens.each do |token|
  token.next = nil
end
eof = Token.new
eof.string = "EOF"
eof.type = :EOF
parser.tokens << eof
parser.parse
i = -1
parser.code_list.lines.each do |line|
  puts "#{i += 1}\t#{line.opcode}\t#{line.operand_1}\t#{line.operand_2}\t#{line.result}"
end
