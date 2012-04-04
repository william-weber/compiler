require "./token.rb"
require "./lexer.rb"
require "./parser.rb"

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
    #after.returned :rule => 0, :call => "C" do
      # check C's type against type of first 2 returns
      # if C called D[1], type will be "okay", passing
    #end
  end
  p.rule :B,    [ :int, :void, :float ] => "E identifier C B", [:EOF] => "EOF" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :C,    [ ";", "[" ] => "D", [ "(" ] => "( G ) { K L }" do |returns|
    p "RULE: C"
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :D,    [ ";" ] => ";", [ "[" ] => "[ integer ] ;" do |returns|
    p "RULE: D"
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :E,    [ "int" ] => "int", [ "void" ] => "void", [ "float" ] => "float" do |returns|
    p "RULE: E"
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :G,    [ "int" ] => "int identifier I H", [ "float" ] => "float identifier I H", [ "void" ] => "void GA" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :GA,   [ :identifier ] => "identifier I H", [ ")" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :H,    [ "," ] => ", E identifier I H", [ ")" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :I,    [ "[" ] => "[ ]", [ ",", ")" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :K,    [ "int", "void", "float" ] => "E identifier D K", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "}" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :L,    [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return" ] => "M L", [ "}" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :M,    [ :identifier, "(", :integer, :floatnumber, ";" ] => "N", [ "{" ] => "{ K L }", [ "if" ] => "if ( R ) M O", [ "while" ] => "while ( R ) M", [ "return" ] => "return Q" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :N,    [ :identifier, "(", :integer, :floatnumber ] => "R ;", [ ";" ] => ";" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :O,    [ "else" ] => "else M", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "else", "}" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :Q,    [ ";" ] => ";", [ :identifier, "(", :integer, :floatnumber ] => "R ;" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :R,    [ :identifier ] => "identifier P", [ "(" ] => "( R ) X V T", [ :integer ] => "integer X V T", [ :floatnumber ] => "floatnumber X V T" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :P,    [ "[" ] => "[ R ] S", [ "(" ] => "( F ) X V T", [ "=", "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "S" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :S,    [ "=" ] => "= R", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "X V T" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :T,    [ ">=", ">", "<", "<=", "==", "!=" ] => " U Z X V T", [ ")", ";", "]", "," ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :U,    [ ">=" ] => ">=", [ ">" ] => ">", [ "<" ] => "<", [ "<=" ] => "<=", [ "==" ] => "==", [ "!=" ] => "!=" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :V,    [ "+" ] => "+ Z X V", [ "-" ] => "- Z X V", [ ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :X,    [ "*" ] => "* Z X", [ "/" ] => "/ Z X", [ "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :Z,    [ "(" ] => "( R )", [ :identifier ] => "identifier W", [ :integer ] => "integer", [ :floatnumber ] => "floatnumber" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :W,    [ "[" ] => "[ R ]", [ "(" ] => "( F )", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :F,    [ :identifier, "(", :integer, :floatnumber ] => "R J", [ ")" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
  p.rule :J,    [ "," ] => ", R J", [ ")" ] => "" do |returns|
    returns.each do |token|
      print " #{token.string} " unless token.nil?
    end
    print "\n"
  end
end



# Create a new Lexer with the input file
lexer = Lexer.new("tiny.c")
lexer.parse
parser.tokens = lexer.tokens
eof = Token.new
eof.string = "EOF"
eof.type = :EOF
parser.tokens << eof
parser.parse


