class Lexer
  attr_reader :tokens

  def initialize(file)
    @tokens = []
    @symbol_table = []
    begin
      @f = File.new file
    rescue
      puts "Could not open file."
    end
  end

  def parse
    nesting_depth = 0
    depth = 0
    token = Token.new
    first_token = token
    symbol = ["+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}"]
    @f.each_line do |l|
      l.strip!
      l << " "
      token.reset!
      l.each_char do |c|
        if nesting_depth > 0
          token << c if c == "*" || c == "/"
          if token.end_comment?
            token.reset!
            nesting_depth -= 1
          elsif token.start_comment?
            token.reset!
            nesting_depth += 1
          else
            token.reset!
            token.string = c
          end
        else
          token << c
          if token.line_comment?
            token.reset!
            break
          elsif token.start_comment?
            nesting_depth += 1
            token.reset!
          elsif token.had_match.nil? and symbol.include?(c) || c == " " and !token.string.empty?
            token.next = Token.new(c.strip)
            token = token.next
            token.match
          elsif (token.type.nil? or token.type == :end_comment) and !token.had_match.nil?
            if [:identifier, :keyword, :integer].include?(token.had_match) and symbol.include?(c) || c == " "
              if token.error
                token.next = Token.new(c.strip)
                token = token.next
                token.match
              else
                token.chop!
                token.depth = depth
                @tokens << token
                @symbol_table << token
                token = token.next
                token.match
              end
            elsif token.had_match == :floatnumber and !["-", "+"].include?(c) && (symbol << " ").include?(c)
              if token.error
                token.next = Token.new(c.strip)
                token = token.next
                token.match
              else
                token.chop!
                token.depth = depth
                @tokens << token
                token = token.next
                token.match
              end
            elsif token.had_match == :symbol or token.had_match == :end_comment
              token.chop!
              if ["(", "{"].include?(token.string)
                depth += 1
              elsif [")", "}"].include?(token.string)
                depth -= 1
              end
              token.depth = depth
              @tokens << token
              token = token.next
              token.match
            else
              token.error = true
            end
          end
        end
      end 
    end
  end
end
