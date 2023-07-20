# frozen_string_literal: true
# encoding: UTF-8
#--
# This file is automatically generated. Do not modify it.
# Generated by: oedipus_lex version 2.6.1.
# Source: lib/nokogiri/css/tokenizer.rex
#++


##
# The generated lexer Nokogiri::CSS::Tokenizer

class Nokogiri::CSS::Tokenizer
  require 'strscan'

  # :stopdoc:
  NL       = /\n|\r\n|\r|\f/
  W        = /[\s]*/
  NONASCII = /[^\0-\177]/
  NUM      = /-?([0-9]+|[0-9]*\.[0-9]+)/
  UNICODE  = /\\[0-9A-Fa-f]{1,6}(\r\n|[\s])?/
  ESCAPE   = /#{UNICODE}|\\[^\n\r\f0-9A-Fa-f]/
  NMCHAR   = /[_A-Za-z0-9-]|#{NONASCII}|#{ESCAPE}/
  NMSTART  = /[_A-Za-z]|#{NONASCII}|#{ESCAPE}/
  IDENT    = /-?(#{NMSTART})(#{NMCHAR})*/
  NAME     = /(#{NMCHAR})+/
  STRING1  = /"([^\n\r\f"]|#{NL}|#{NONASCII}|#{ESCAPE})*(?<!\\)(?:\\{2})*"/
  STRING2  = /'([^\n\r\f']|#{NL}|#{NONASCII}|#{ESCAPE})*(?<!\\)(?:\\{2})*'/
  STRING   = /#{STRING1}|#{STRING2}/
  # :startdoc:
  # :stopdoc:
  class LexerError < StandardError ; end
  class ScanError < LexerError ; end
  # :startdoc:

  ##
  # The current line number.

  attr_accessor :lineno
  ##
  # The file name / path

  attr_accessor :filename

  ##
  # The StringScanner for this lexer.

  attr_accessor :ss

  ##
  # The current lexical state.

  attr_accessor :state

  alias :match :ss

  ##
  # The match groups for the current scan.

  def matches
    m = (1..9).map { |i| ss[i] }
    m.pop until m[-1] or m.empty?
    m
  end

  ##
  # Yields on the current action.

  def action
    yield
  end

  ##
  # The previous position. Only available if the :column option is on.

  attr_accessor :old_pos

  ##
  # The position of the start of the current line. Only available if the
  # :column option is on.

  attr_accessor :start_of_current_line_pos

  ##
  # The current column, starting at 0. Only available if the
  # :column option is on.
  def column
    old_pos - start_of_current_line_pos
  end


  ##
  # The current scanner class. Must be overridden in subclasses.

  def scanner_class
    StringScanner
  end unless instance_methods(false).map(&:to_s).include?("scanner_class")

  ##
  # Parse the given string.

  def parse str
    self.ss     = scanner_class.new str
    self.lineno = 1
    self.start_of_current_line_pos = 0
    self.state  ||= nil

    do_parse
  end

  ##
  # Read in and parse the file at +path+.

  def parse_file path
    self.filename = path
    open path do |f|
      parse f.read
    end
  end

  ##
  # The current location in the parse.

  def location
    [
      (filename || "<input>"),
      lineno,
      column,
    ].compact.join(":")
  end

  ##
  # Lex the next token.

  def next_token

    token = nil

    until ss.eos? or token do
      if ss.check(/\n/) then
        self.lineno += 1
        # line starts 1 position after the newline
        self.start_of_current_line_pos = ss.pos + 1
      end
      self.old_pos = ss.pos
      token =
        case state
        when nil then
          case
          when text = ss.scan(/has\(#{W}/) then
            action { [:HAS, text] }
          when text = ss.scan(/#{NUM}/) then
            action { [:NUMBER, text] }
          when text = ss.scan(/#{IDENT}\(#{W}/) then
            action { [:FUNCTION, text] }
          when text = ss.scan(/#{IDENT}/) then
            action { [:IDENT, text] }
          when text = ss.scan(/##{NAME}/) then
            action { [:HASH, text] }
          when text = ss.scan(/#{W}\~=#{W}/) then
            action { [:INCLUDES, text] }
          when text = ss.scan(/#{W}\|=#{W}/) then
            action { [:DASHMATCH, text] }
          when text = ss.scan(/#{W}\^=#{W}/) then
            action { [:PREFIXMATCH, text] }
          when text = ss.scan(/#{W}\$=#{W}/) then
            action { [:SUFFIXMATCH, text] }
          when text = ss.scan(/#{W}\*=#{W}/) then
            action { [:SUBSTRINGMATCH, text] }
          when text = ss.scan(/#{W}!=#{W}/) then
            action { [:NOT_EQUAL, text] }
          when text = ss.scan(/#{W}=#{W}/) then
            action { [:EQUAL, text] }
          when text = ss.scan(/#{W}\)/) then
            action { [:RPAREN, text] }
          when text = ss.scan(/\[#{W}/) then
            action { [:LSQUARE, text] }
          when text = ss.scan(/#{W}\]/) then
            action { [:RSQUARE, text] }
          when text = ss.scan(/#{W}\+#{W}/) then
            action { [:PLUS, text] }
          when text = ss.scan(/#{W}>#{W}/) then
            action { [:GREATER, text] }
          when text = ss.scan(/#{W},#{W}/) then
            action { [:COMMA, text] }
          when text = ss.scan(/#{W}~#{W}/) then
            action { [:TILDE, text] }
          when text = ss.scan(/:not\(#{W}/) then
            action { [:NOT, text] }
          when text = ss.scan(/#{W}\/\/#{W}/) then
            action { [:DOUBLESLASH, text] }
          when text = ss.scan(/#{W}\/#{W}/) then
            action { [:SLASH, text] }
          when text = ss.scan(/U\+[0-9a-f?]{1,6}(-[0-9a-f]{1,6})?/) then
            action {[:UNICODE_RANGE, text] }
          when text = ss.scan(/[\s]+/) then
            action { [:S, text] }
          when text = ss.scan(/#{STRING}/) then
            action { [:STRING, text] }
          when text = ss.scan(/./) then
            action { [text, text] }
          else
            text = ss.string[ss.pos .. -1]
            raise ScanError, "can not match (#{state.inspect}) at #{location}: '#{text}'"
          end
        else
          raise ScanError, "undefined state at #{location}: '#{state}'"
        end # token = case state

      next unless token # allow functions to trigger redo w/ nil
    end # while

    raise LexerError, "bad lexical result at #{location}: #{token.inspect}" unless
      token.nil? || (Array === token && token.size >= 2)

    # auto-switch state
    self.state = token.last if token && token.first == :state

    token
  end # def next_token
    def do_parse
    end
end # class
