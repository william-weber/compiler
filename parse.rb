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
  p.start :A,   [ :int, :void, :float ] => "E identifier C B"
  p.rule :B,    [ :int, :void, :float ] => "E identifier C B", [:EOF] => "EOF"
  p.rule :C,    [ ";", "[" ] => "D", [ "(" ] => "( G ) { K L }"
  p.rule :D,    [ ";" ] => ";", [ "[" ] => "[ integer ] ;"
  p.rule :E,    [ "int" ] => "int", [ "void" ] => "void", [ "float" ] => "float"
  p.rule :G,    [ "int" ] => "int identifier I H", [ "float" ] => "float identifier I H", [ "void" ] => "void GA"
  p.rule :GA,   [ :identifier ] => "identifier I H", [ ")" ] => ""
  p.rule :H,    [ "," ] => ", E identifier I H", [ ")" ] => ""
  p.rule :I,    [ "[" ] => "[ ]", [ ",", ")" ] => ""
  p.rule :K,    [ "int", "void", "float" ] => "E identifier D K", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "}" ] => ""
  p.rule :L,    [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return" ] => "M L", [ "}" ] => ""
  p.rule :M,    [ :identifier, "(", :integer, :floatnumber, ";" ] => "N", [ "{" ] => "{ K L }", [ "if" ] => "if ( R ) M O", [ "while" ] => "while ( R ) M", [ "return" ] => "return Q"
  p.rule :N,    [ :identifier, "(", :integer, :floatnumber ] => "R ;", [ ";" ] => ";"
  p.rule :O,    [ "else" ] => "else M", [ :identifier, "(", :integer, :floatnumber, ";", "{", "if", "while", "return", "else", "}" ] => ""
  p.rule :Q,    [ ";" ] => ";", [ :identifier, "(", :integer, :floatnumber ] => "R ;"
  p.rule :R,    [ :identifier ] => "identifier P", [ "(" ] => "( R ) X V T", [ :integer ] => "integer X V T", [ :floatnumber ] => "floatnumber X V T"
  p.rule :P,    [ "[" ] => "[ R ] S", [ "(" ] => "( F ) X V T", [ "=", "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "S"
  p.rule :S,    [ "=" ] => "= R", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => "X V T"
  p.rule :T,    [ ">=", ">", "<", "<=", "==", "!=" ] => " U Z X V T", [ ")", ";", "]", "," ] => ""
  p.rule :U,    [ ">=" ] => ">=", [ ">" ] => ">", [ "<" ] => "<", [ "<=" ] => "<=", [ "==" ] => "==", [ "!=" ] => "!="
  p.rule :V,    [ "+" ] => "+ Z X V", [ "-" ] => "- Z X V", [ ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => ""
  p.rule :X,    [ "*" ] => "* Z X", [ "/" ] => "/ Z X", [ "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => ""
  p.rule :Z,    [ "(" ] => "( R )", [ :identifier ] => "identifier W", [ :integer ] => "integer", [ :floatnumber ] => "floatnumber"
  p.rule :W,    [ "[" ] => "[ R ]", [ "(" ] => "( F )", [ "*", "/", "+", "-", ">=", ">", "<", "<=", "==", "!=", ")", ";", "]", "," ] => ""
  p.rule :F,    [ :identifier, "(", :integer, :floatnumber ] => "R J", [ ")" ] => ""
  p.rule :J,    [ "," ] => ", R J", [ ")" ] => ""
end



# Create a new Lexer with the input file
lexer = Lexer.new("tiny.c")
lexer.parse
parser.tokens = lexer.tokens
parser.tokens.each do |t|
  p "token: #{t.string}"
end
parser.tokens << Token.new(:type => :EOF, :string => "EOF")
parser.parse


