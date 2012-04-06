class Lexer
  attr_reader :tokens

  def initialize(file)
    @symbols = ["+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}"]
    @tokens = []
    begin
      @file = File.new file
    rescue
      puts "Could not open file."
    end
  end

  def parse
    comment_nesting_depth = 0
    block_nesting_depth = 0
    line_number = 0
    token = Token.new
    first_token = token
    @file.each_line do |l|
      line_number += 1
      l.strip!
      l << " "
      token.reset!
      l.each_char do |c|
        if comment_nesting_depth > 0
          token << c if c == "*" || c == "/"
          if token.end_comment?
            token.reset!
            comment_nesting_depth -= 1
          elsif token.start_comment?
            token.reset!
            comment_nesting_depth += 1
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
            comment_nesting_depth += 1
            token.reset!
          elsif token.had_match.nil? and is_separator?(c) and !token.string.empty?
            token.next = Token.new(c.strip)
            token = token.next
            token.match
          elsif (token.type.nil? or token.type == :end_comment) and !token.had_match.nil?
            if [:identifier, :keyword, :integer].include?(token.had_match) and is_separator?(c)
              if token.error
                token.next = Token.new(c.strip)
                token = token.next
                token.match
              else
                token.chop!
                token.depth = block_nesting_depth
                token.line_number = line_number
                @tokens << token
                token = token.next
                token.match
              end
            elsif token.had_match == :floatnumber and !["-", "+"].include?(c) && is_separator?(c)
              if token.error
                token.next = Token.new(c.strip)
                token = token.next
                token.match
              else
                token.chop!
                token.depth = block_nesting_depth
                token.line_number = line_number
                @tokens << token
                token = token.next
                token.match
              end
            elsif token.had_match == :symbol or token.had_match == :end_comment
              token.chop!
              if ["(", "{"].include?(token.string)
                block_nesting_depth += 1
              elsif [")", "}"].include?(token.string)
                block_nesting_depth -= 1
              end
              token.depth = block_nesting_depth
              token.line_number = line_number
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

  def is_separator?( character )
    @symbols.include?( character ) or character == " "
  end
end
