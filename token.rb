class Token
  # types: line_comment, start_comment, end_comment, keyword, symbol,
  # identifier, integer, float
  attr_accessor :string, :type, :next, :had_match, :error, :depth
  attr_accessor :attributes

  def initialize(string = "")
    @symbol = ["+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "=", ";", ",", "(", ")", "[", "]", "{", "}"]
    @string = string
    @had_match = nil
    @error = false
    @depth = 0
    @attributes = {}
  end

  def <<(char)
    return string if char == " " && string.empty?
    string << char
    self.match
  end

  def chop!
    @next = Token.new @string[-1, 1]
    @next.string.strip!
    @string.chop!
    self.match
  end

  def ==(str)
    str == @string
  end

  def type=(t)
    @type = t
    @error = false unless t.nil?
  end

  def reset!
    @string = ""
    @type = nil
    @had_match = nil
    @error = false
  end

  def match
    case string
    when "//"
      self.type = :line_comment
      @had_match = :line_comment
    when "/*"
      self.type = :start_comment
      @had_match = :start_comment
    when "*/"
      self.type = :end_comment
      @had_match = :end_comment
    when /\Aelse\Z/i, /\Aif\Z/i, /\Aint\Z/i, /\Afloat\Z/i, /\Areturn\Z/i, /\Avoid\Z/i, /\Awhile\Z/i
      self.type = :keyword
      @had_match = :keyword
    when *@symbol
      self.type = :symbol
      @had_match = :symbol
    when /\A[A-Za-z][A-Za-z0-9]{0,7}\Z/
      self.type = :identifier
      @had_match = :identifier
    when /\A[0-9]+\Z/
      self.type = :integer
      @had_match = :integer
    when /\A(\+|-)?(\d)\.(\d)+(E(\+|-)?(\d)+)?\Z/i
      self.type = :floatnumber
      @had_match = :floatnumber
    else
      self.type = nil
    end
  end
  
  def matches(symbol)
    if [:integer, :floatnumber, :identifier].include?(symbol)
      return true if symbol == type
    else
      return true if symbol.to_s == string
    end
    false
  end

  def line_comment?
    @type == :line_comment
  end

  def start_comment?
    @type == :start_comment
  end

  def end_comment?
    @type == :end_comment
  end
end
