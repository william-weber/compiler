require "./token.rb"
require "./lexer.rb"
require "./parser.rb"

parser = Language.new do |p|
  p.terminals [ "int", "void", "if", "while", "return", "else" ]
  p.terminals [ "+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}" ]
  p.token :integer
  p.token :float
  p.token :identifier
  p.start :PGM, [:int, :void] => "TS identifier D DL"
  p.rule :DL, [:int, :void] => "TS identifier D DL", [:EOF] => "EOF"
  p.rule :D, [";", "["] => "VV", ["("] => "( PS ) { LD SL }"
  p.rule :VV, [";"] => ";", ["["] => "[ integer ] ;"
  p.rule :TS, [:int] => "int", [:void] => "void"
  p.rule :PS, [:int] => "int identifier P PL", [:void] => "void PSA"
  p.rule :PSA, [:identifier] => "identifier P PL", [")"] => ""
  p.rule :PL, [","] => ", TS identifier P PL", [")"] => ""
  p.rule :P, ["["] => "[ ]", [",", ")"] => ""
  p.rule :LD, [:int, :void] => "TS identifier VV LD", ["{", :if, :while, :return, ";", :identifier, "(", :integer, "}"] => ""
  p.rule :SL, ["{", :if, :while, :return, ";", :identifier, "(", :integer] => "S SL", ["}"] => ""
  p.rule :S, [";", :identifier, "(", :integer] => "EX", ["{"] => "{ LD SL }", [:if] => "if ( E ) S SS", [:while] => "while ( E ) S", [:return] => "return EX"
  p.rule :EX, [:identifier, "(", :integer] => "E ;", [";"] => ";"
  p.rule :SS, [:else] => "else S", ["{", :if, :while, :return, ";", :identifier, "(", :integer, "}"] => ""
  p.rule :E, [:identifier] => "identifier EA", ["("] => "( E ) T AEA SEA", [:integer] => "integer T AEA SEA"
  p.rule :EA, ["[", "=", "*", "/", "<=", "<", ">", ">=", "==", "!=", "+", "-", ";", "]", ")", ","] => "V EE", ["("] => "( AG ) T AEA SEA"
  p.rule :EE, ["="] => "= E", ["*", "/", "+", "-", "<=", "<", ">", ">=", "==", "!=", ";", "]", ")", ","] => "T AEA SEA"
  p.rule :V, ["["] => "[ E ]", ["=", "*", "/", "<=", "<", ">", ">=", "==", "!=", "+", "-", ";", "]", ")", ","] => ""
  p.rule :SEA, ["<=", "<", ">", ">=", "==", "!="] => "R T AEA", [";", "]", ")", ","] => ""
  p.rule :R, ["<="] => "<=", ["<"] => "<", [">"] => ">", [">="] => ">=", ["=="] => "==", ["!="] => "!="
  p.rule :AEA, ["+", "-"] => "A F T AEA", ["<=", "<", ">", ">=", "==", "!=", ";", "]", ")", ",", :integer] => ""
  p.rule :A, ["+"] => "+", ["-"] => "-"
  p.rule :T, ["*", "/"] => "M F T", ["<=", "<", ">", ">=", "==", "!=", "+", "-", ";", "]", ")", ",", :integer] => ""
  p.rule :M, ["*"] => "*", ["/"] => "/"
  p.rule :F, ["("] => "( E )", [:identifier] => "identifier FA", [:integer] => "integer"
  p.rule :FA, ["[", "*", "/", "<=", "<", ">", ">=", "==", "!=", "+", "-", ";", "]", ")", ","] => "V", ["("] => "( AG )"
  p.rule :AG, [:identifier, "(", :integer] => "E AL", [")"] => ""
  p.rule :AL, [","] => ", E AL", [")"] => ""
end



lexer = Lexer.new("tiny.c")
lexer.parse
parser.tokens = lexer.tokens
parser.tokens.each do |t|
  p "token: #{t.string}"
end
parser.tokens << Token.new(:type => :EOF, :string => "EOF")
parser.parse


