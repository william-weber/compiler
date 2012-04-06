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
      symbol = SymbolEntry.new(after.results[1])
      symbol.class = :function_call
      symbol.datatype = after.results[0].attributes[:type]
      p.symbol_table << symbol
    end
    after.returning :rule => "E identifier C B", :call => 2 do
      if after.results[2].attributes[:class] == :function
#        # check return type
#        if after.results[2].attributes[:type] != after.results[0].attributes[:type]
#          after.error = "Mismatched return type on line #{after.results[1].line_number}."
#          p "return type: #{after.results[2].attributes[:type]} for #{after.results[1].string}"
#        # add to symbol table
#        else
        symbol = p.symbol_table.find after.results[1].string
        symbol.class = :function_call
        symbol.argument_count = after.results[2].attributes[:attribute_count]
        symbol.argument_types = after.results[2].attributes[:attribute_types]
        symbol.datatype = after.results[0].attributes[:type]
#        end
      end
    end
  end

  p.rule :B,    [ :int, :void, :float ] => "E identifier C B", [:EOF] => "EOF" do |after|
    after.returning :rule => "E identifier C B", :call => 1 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.datatype = after.results[0].attributes[:type]
      p.symbol_table << symbol
    end
    after.returning :rule => "E identifier C B", :call => 2 do
      if after.results[2].attributes[:class] == :function
#        # check return type
#        if after.results[2].attributes[:type] != after.results[0].attributes[:type]
#          after.error = "Mismatched return type on line #{after.results[1].line_number}."
#          p "return type: #{after.results[2].attributes[:type]} for #{after.results[1].string}"
#        # add to symbol table
#        else
        symbol = p.symbol_table.find after.results[1].string
        symbol.class = :function_call
        symbol.argument_count = after.results[2].attributes[:attribute_count]
        symbol.argument_types = after.results[2].attributes[:attribute_types]
        symbol.datatype = after.results[0].attributes[:type]
#        end
      end
    end
  end

  p.rule :C,    [ ";", "[" ] => "D", [ "(" ] => "( G ) { K L }" do |after|
    after.returning :rule => "D", :call => 0 do
      after.attributes[:class] = after.results[0].attributes[:class]
    end
    # change symbol table scope for local variables
    after.returning :rule => "( G ) { K L }", :call => 0 do
      p.symbol_table = p.symbol_table.new_child
    end
    after.returning :rule => "( G ) { K L }", :call => 1 do
      # pass up argument counts and types
      after.attributes[:attribute_count] = after.results[1].attributes[:attribute_count]
      after.attributes[:attribute_types] = after.results[1].attributes[:attribute_types]
      after.attributes[:class] = :function
    end
    after.returning :rule => "( G ) { K L }", :call => 6 do
      after.attributes[:type] = after.results[5].attributes[:type]
      p.symbol_table = p.symbol_table.parent
    end
  end

  p.rule :D,    [ ";" ] => ";", [ "[" ] => "[ integer ] ;" do |after|
    after.returning :rule => ";", :call => 0 do
      after.attributes[:class] = :variable
    end
    after.returning :rule => "[ integer ] ;", :call => 0 do
      after.attributes[:class] = :array
    end
  end

  p.rule :E,    [ "int" ] => "int", [ "void" ] => "void", [ "float" ] => "float" do |after|
    after.returning :rule => "int", :call => 0 do
      after.attributes[:type] = :integer
    end
    after.returning :rule => "void", :call => 0 do
      after.attributes[:type] = :void
    end
    after.returning :rule => "float", :call => 0 do
      after.attributes[:type] = :floatnumber
    end
  end

  p.rule :G,    [ "int" ] => "int identifier I H", [ "float" ] => "float identifier I H", [ "void" ] => "void GA" do |after|
    after.returning :rule => "int identifier I H", :call => 2 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.class = after.results[2].attributes[:class]
      symbol.datatype = :integer
      p.symbol_table << symbol
      after.attributes[:attribute_count] = 1
      after.attributes[:attribute_count] += after.results[3].attributes[:attribute_count] unless after.results[3].nil?
      after.attributes[:attribute_types] = [ :integer ]
      after.attributes[:attribute_types] += after.results[3].attributes[:attribute_types] unless after.results[3].nil?
    end
    after.returning :rule => "float identifier I H", :call => 2 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.class = after.results[2].attributes[:class]
      symbol.datatype = :floatnumber
      p.symbol_table << symbol
      after.attributes[:attribute_count] = 1
      after.attributes[:attribute_count] += after.results[3].attributes[:attribute_count] unless after.results[3].nil?
      after.attributes[:attribute_types] = [ :floatnumber ]
      after.attributes[:attribute_types] += after.results[3].attributes[:attribute_types] unless after.results[3].nil?
    end
  end

  p.rule :GA,   [ :identifier ] => "identifier I H", [ ")" ] => ""

  p.rule :H,    [ "," ] => ", E identifier I H", [ ")" ] => "" do |after|
    after.returning :rule => ", E identifier I H", :call => 3 do
      symbol = SymbolEntry.new(after.results[2])
      symbol.class = after.results[3].attributes[:class]
      symbol.datatype = after.results[1].attributes[:type]
      p.symbol_table << symbol
      after.attributes[:attribute_count] = 1
      after.attributes[:attribute_count] += after.results[4].attributes[:attribute_count] unless after.results[4].nil?
      after.attributes[:attribute_types] = [ after.results[1].attributes[:type] ]
      after.attributes[:attribute_types] += after.results[4].attributes[:attribute_types] unless after.results[4].nil?
    end
  end

  p.rule :I,    [ "[" ] => "[ ]", [ ",", ")" ] => "" do |after|
    after.returning :rule => "[ ]", :call => 0 do
      after.attributes[:class] = :array
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:class] = :variable
    end
  end

  p.rule :K,    [ "int", "void", "float" ] => "E identifier D K", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "}" ] => "" do |after|
    after.returning :rule => "E identifier D K", :call => 1 do
      symbol = SymbolEntry.new(after.results[1])
      symbol.datatype = after.results[0].attributes[:type]
      p.symbol_table << symbol
    end
  end

  p.rule :L,    [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return" ] => "M L", [ "}" ] => "" do |after|
    after.returning :rule => "M L", :call => 0 do
      after.attributes[:type] = after.results[0].attributes[:type] unless after.results[0].nil?
    end
  end

  p.rule :M,    [ :identifier, "(", :integer, :floatnumber, ";" ] => "N", [ "{" ] => "{ K L }", [ "if" ] => "if ( R ) M O", [ "while" ] => "while ( R ) M", [ "return" ] => "return Q" do |after|
    after.returning :rule => "return Q", :call => 1 do
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    # change symbol table scope for local variables
    after.returning :rule => "{ K L }", :call => 0 do
      p.symbol_table = p.symbol_table.new_child
    end
    after.returning :rule => "{ K L }", :call => 3 do
      after.attributes[:type] = after.results[2].attributes[:type]
      p.symbol_table = p.symbol_table.parent
    end
  end

  p.rule :N,    [ :identifier, "(", :integer, :floatnumber ] => "R ;", [ ";" ] => ";"
  p.rule :O,    [ "else" ] => "else M", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "else", "}" ] => ""

  p.rule :Q,    [ ";" ] => ";", [ :identifier, "(", :integer, :floatnumber ] => "R ;" do |after|
    after.returning :rule => ";", :call => 0 do
      after.attributes[:type] = :pass
    end
    after.returning :rule => "R ;", :call => 0 do
      after.attributes[:type] = after.results[0].attributes[:type]
    end
  end

  p.rule :R,    [ :identifier ] => "identifier P", [ "(" ] => "( R ) X V T", [ :integer ] => "integer X V T", [ :floatnumber ] => "floatnumber X V T" do |after|
    after.returning :rule => "identifier P", :call => 0 do
      # check if identifier is in symbol table
      unless p.symbol_table.include? after.results[0].string
        after.error = "Undeclared variable or uninitialized function '#{after.results[0].string}' on line #{after.results[0].line_number}"
      end
    end
    after.returning :rule => "identifier P", :call => 1 do
      # check function argument # and type if P is a function call
      symbol = p.symbol_table.find(after.results[0].string) 
      if after.results[1].attributes[:class] == :function_call
        # identifier must be a function
        if symbol.class != :function_call
          after.error = "Expected function call, got #{symbol.class} on line #{symbol.line_number}."
        else
          error = ""
          if symbol.argument_count != after.results[1].attributes[:attribute_count]
            error += "Wrong number of arguments given. Expected #{symbol.argument_count} got #{after.results[1].attributes[:attribute_count]}. "
          end
          if symbol.argument_types != after.results[1].attributes[:attribute_types]
            error += "Mismatched attribute types. Expected #{symbol.argument_types.join(' ')}"
          end
          if !error.empty?
            error += "[line #{symbol.line_number}]"
            after.error = error
          end
        end
      elsif after.results[1].attributes[:class] == :assignment
        if after.results[1].attributes[:type] != symbol.datatype
          after.error = "Cannot assign #{after.results[1].attributes[:type]} to #{symbol.datatype} on line #{symbol.line_number}."
        end
      else
        after.error = "Type mismatch on line #{symbol.line_number}."
      end
      after.attributes[:type] = symbol.datatype
    end
    after.returning :rule => "( R ) X V T", :call => 5 do
      # types of all must match
      if after.results[3..5].push(after.results[1]).map{ |r| r.attributes[:type] }.compact.uniq.length >= 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      else
        if after.results[5].attributes[:type] == :boolean
          after.attributes[:type] = :boolean
        else
          after.attributes[:type] = after.results[1].attributes[:type]
        end
      end
    end
    after.returning :rule => "integer X V T", :call => 3 do
      # types of all must match
      unless after.results.all{ |r| r.type == :integer or r.type == nil }
        after.error = "Type mismatch on line #{after.results[0].line_number}"
      end
    end
    after.returning :rule => "floatnumber X V T", :call => 3 do
      # types of all must match
      unless after.results.all{ |r| r.type == :floatnumber or r.type == nil }
        after.error = "Type mismatch on line #{after.results[0].line_number}"
      end
    end
  end

  p.rule :P,    [ "[" ] => "[ R ] S", [ "(" ] => "( F ) X V T", [ "=", "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "S" do |after|
    after.returning :rule => "[ R ] S", :call => 1 do
      # R must not be a float
      if after.results[1].attributes[:type] != :integer
        after.error = "Array index must be an integer. Line #{after.results[0].line_number}"
      end
    end
    after.returning :rule => "[ R ] S", :call => 3 do
      if after.results[3].attributes[:class] == :assignment
        after.attributes[:class] = :assignment
      end
      after.attributes[:type] = after.results[3].attributes[:type]
    end
    after.returning :rule => "( F ) X V T", :call => 5 do
      after.attributes[:class] = :function_call
      after.attributes[:attribute_count] = after.results[1].attributes[:attribute_count]
      after.attributes[:attribute_types] = after.results[1].attributes[:attribute_types]
      # types of X V T must match
      if after.results[3..5].map{ |r| r.attributes[:type] }.compact.uniq.length >= 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      else
        if after.results[5].attributes[:type] == :boolean
          after.attributes[:type] = :boolean
        else
          after.attributes[:type] = after.results[3].attributes[:type]
        end
      end
    end
    after.returning :rule => "S", :call => 0 do
      if after.results[0].attributes[:class] == :assignment
        after.attributes[:class] = :assignment
      end
      after.attributes[:type] = after.results[0].attributes[:type]
    end
  end

  p.rule :S,    [ "=" ] => "= R", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "X V T" do |after|
    after.returning :rule => "= R", :call => 1 do
      after.attributes[:class] = :assignment
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "X V T", :call => 2 do
      if after.results[0..2].map{ |r| r.attributes[:type] }.compact.uniq.length > 1
        after.error = "Type mismatch."
      else
        if after.results[2].attributes[:type] == :boolean
          after.attributes[:type] = :boolean
        # TODO make test
        elsif !after.results.empty?
          after.attributes[:type] = after.results[0].attributes[:type]
        end
      end
    end
  end

  p.rule :T,    [ ">=", ">", "<", "<=", "==", "!=" ] => "U Z X V T", [ ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "U Z X V T", :call => 4 do
      after.attributes[:type] = :boolean
      unless after.results[1..3].map{ |r| r.attributes[:type] }.compact.uniq.length == 1
        after.error = "Type mismatch on line #{after.results[0].attributes[:line_number]}."
      end
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:type] = nil
    end
  end

  p.rule :U,    [ ">=" ] => ">=", [ ">" ] => ">", [ "<" ] => "<", [ "<=" ] => "<=", [ "==" ] => "==", [ "!=" ] => "!=" do |after|
    after.returning :rule => :all, :call => 0 do
      after.attributes[:line_number] = after.results[0].line_number
    end
  end

  p.rule :V,    [ "+" ] => "+ Z X V", [ "-" ] => "- Z X V", [ ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "+ Z X V", :call => 3 do
      unless after.results[1..3].map{ |r| r.attributes[:type] }.compact.uniq.length == 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      end
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "- Z X V", :call => 3 do
      unless after.results[1..3].map{ |r| r.attributes[:type] }.compact.uniq.length == 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      end
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:type] = nil
    end
  end

  p.rule :X,    [ "*" ] => "* Z X", [ "/" ] => "/ Z X", [ "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "* Z X", :call => 2 do
      unless after.results[1..2].map{ |r| r.attributes[:type] }.compact.uniq.length == 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      end
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "/ Z X", :call => 2 do
      unless after.results[1..2].map{ |r| r.attributes[:type] }.compact.uniq.length == 1
        after.error = "Type mismatch on line #{after.results[0].line_number}."
      end
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:type] = nil
    end
  end

  p.rule :Z,    [ "(" ] => "( R )", [ :identifier ] => "identifier W", [ :integer ] => "integer", [ :floatnumber ] => "floatnumber" do |after|
    after.returning :rule => "( R )", :call => 2 do
      after.attributes[:type] = after.results[1].attributes[:type]
    end
    after.returning :rule => "identifier W", :call => 0 do
      # check if identifier is in symbol table
      if !p.symbol_table.include? after.results[0].string
        after.error = "Undeclared variable or uninitialized function '#{after.results[0].string}' on line #{after.results[0].line_number}"
      end
    end
    after.returning :rule => "identifier W", :call => 1 do
      # check function argument # and type if W is a function call
      symbol = p.symbol_table.find(after.results[0].string) 
      if after.results[1].attributes[:class] == :function_call
        # identifier must be a function
        if symbol.class != :function_call
          attributes.error = "Expected function call, got #{symbol.class} on line #{symbol.line_number}."
        else
          error = ""
          if symbol.attribute_count != after.results[1].attribute_count
            error += "Wrong number of arguments given. Expected #{symbol.attribute_count} got #{after.results[1].attribute_count}. "
          end
          if symbol.attribute_types != after.results[1].attribute_types
            error += "Mismatched attribute types. Expected #{symbol.attribute_types.join(' ')} got #{after.results[1].attribute_types.join(' ')}. "
          end
          if !error.empty?
            error += "[line #{symbol.line_number}]"
            attributes.error = error
          end
        end
      end
      after.attributes[:type] = symbol.datatype
    end
    after.returning :rule => "integer", :call => 0 do
      after.attributes[:type] = :integer
    end
    after.returning :rule => "floatnumber", :call => 0 do
      after.attributes[:type] = :floatnumber
    end
  end

  p.rule :W,    [ "[" ] => "[ R ]", [ "(" ] => "( F )", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |after|
    after.returning :rule => "[ R ]", :call => 1 do
      # R must not be a float
      if after.results[1].attributes[:type] != :integer
        after.error = "Array index must be an integer. Line #{after.results[0].line_number}"
      end
    end
    after.returning :rule => "( F )", :call => 1 do
      after.attributes[:class] = :function_call
      after.attributes[:attribute_count] = results[1].attributes[:attribute_count]
      after.attributes[:attribute_types] = results[1].attributes[:attribute_types]
    end
  end

  p.rule :F,    [ :identifier, "(", :integer, :floatnumber ] => "R J", [ ")" ] => "" do |after|
    after.returning :rule => "R J", :call => 1 do
      # function argument # and type must match
      # count function arguments and record types in attribute hash
      after.attributes[:attribute_count] = 1
      after.attributes[:attribute_count] += after.results[2].attributes[:attribute_count] unless after.results[2].nil?
      after.attributes[:attribute_types] = [ after.results[1].attributes[:type] ]
      after.attributes[:attribute_types] += after.results[2].attributes[:attribute_types] unless after.results[2].nil?
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:attribute_count] = 0
      after.attributes[:attribute_types] = []
    end
  end

  p.rule :J,    [ "," ] => ", R J", [ ")" ] => "" do |after|
    after.returning :rule => ", R J", :call => 2 do
      # count function arguments and record types in attribute hash
      after.attributes[:attribute_count] = 1
      after.attributes[:attribute_count] += after.results[2].attributes[:attribute_count] unless after.results[2].attributes[:attribute_count].nil?
      after.attributes[:attribute_types] = [ after.results[1].attributes[:type] ]
      after.attributes[:attribute_types] += after.results[2].attributes[:attribute_types] unless after.results[2].attributes[:attribute_types].nil?
    end
    after.returning :rule => "", :call => 0 do
      after.attributes[:attribute_count] = 0
      after.attributes[:attribute_types] = []
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
