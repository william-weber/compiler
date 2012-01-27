require "token"

begin
  f = File.new ARGV[0]
  nesting_depth = 0
  depth = 0
  token = Token.new
  first_token = token
  tokens = []
  symbol = ["+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}"]
  f.each_line do |l|
    l.strip!
    l << " "
    print "\nLINE: #{l}\n"
    token.reset!
    l.each_char do |c|
      if nesting_depth > 0
        token << c if c == "*" || c == "/"
        if token.end_comment?
          print "end comment found.\n"
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
          print "Line comment, skipping rest of line.\n"
          token.reset!
          break
        elsif token.start_comment?
          print "Start comment found... \n"
          nesting_depth += 1
          token.reset!
        elsif token.end_comment?
          print "ERROR stray end comment: #{token.string}"
        elsif token.had_match.nil? and symbol.include?(c) || c == " " and !token.string.empty?
          print "TOKEN: #{token.string.chop}\n\tTYPE: ERROR\n"
          token.next = Token.new(c.strip)
          token = token.next
          token.match
        elsif token.type.nil? and !token.had_match.nil?
          if [:identifier, :keyword, :integer].include?(token.had_match) and symbol.include?(c) || c == " "
            if token.error
              print "TOKEN: #{token.string.chop}\n\tTYPE: ERROR\n"
              token.next = Token.new(c.strip)
              token = token.next
              token.match
            else
              token.chop!
              token.depth = depth
              tokens << token
              print "TOKEN: #{token.string}\n\tTYPE: #{token.type.to_s}\n"
              print "\tDEPTH: #{depth}\n" if token.type == :identifier
              token = token.next
              token.match
            end
          elsif token.had_match == :float and !["-", "+"].include?(c) && (symbol << " ").include?(c)
            if token.error
              print "TOKEN: #{token.string.chop}\n\tTYPE: ERROR\n"
              token.next = Token.new(c.strip)
              token = token.next
              token.match
            else
              token.chop!
              token.depth = depth
              tokens << token
              print "TOKEN: #{token.string}\n\tTYPE: #{token.type.to_s}\n"
              token = token.next
              token.match
            end
          elsif token.had_match == :symbol
            token.chop!
            if ["(", "{"].include?(token.string)
              depth += 1
            elsif [")", "}"].include?(token.string)
              depth -= 1
            end
            print "TOKEN: #{token.string}\n\tTYPE: #{token.type.to_s}\n"
            token.depth = depth
            tokens << token
            token = token.next
            token.match
          else
            token.error = true
          end
        end
      end
    end 
  end

  puts "SYMBOL TABLE"
  tokens.map do |t|
    print "#{t.string.to_s.rjust(12)}\t#{t.type.to_s.rjust(10)}\t#{t.depth.to_s.rjust(3)}\n"
  end
rescue
  puts "Could not open file."
end
