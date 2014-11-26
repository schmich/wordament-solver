require 'set'
require 'ffi/aspell'

module Wordament
  class Solver
    def initialize
      @speller = FFI::Aspell::Speller.new('en_US')
    end

    def words(letters, min_length: nil, max_length: nil)
      raise if !min_length || !max_length

      @unmarked = true

      @matrix = [
        letters[0..3],
        letters[4..7],
        letters[8..11],
        letters[12..15]
      ]

      suggested = Set.new

      0.upto(3) do |y|
        0.upto(3) do |x|
          strings(min_length, max_length, y, x) do |s|
            if @speller.correct? s
              if suggested.add? s
                yield s
              end
            end
          end
        end
      end
    end

    private

    def mark(marks, y, x)
      bit = 1 << ((y << 2) + x)
      @unmarked = ((marks & bit) == 0)
      marks | bit
    end

    def strings(minlen, maxlen, y, x, path = '', marks = mark(0, y, x), &block)
      acc = path + @matrix[y][x]

      if acc.length >= minlen
        block.call(acc)
      end

      return if acc.length >= maxlen

      n = y - 1
      s = y + 1
      w = x - 1
      e = x + 1

      nok = (n >= 0)
      sok = (s < 4)
      wok = (w >= 0)
      eok = (e < 4)

      if nok
        nmarks = mark(marks, n, x)
        if @unmarked
          strings(minlen, maxlen, n, x, acc, nmarks, &block)

          if wok
            nwmarks = mark(marks, n, w)
            if @unmarked
              strings(minlen, maxlen, n, w, acc, nwmarks, &block)
            end
          end

          if eok
            nemarks = mark(marks, n, e)
            if @unmarked
              strings(minlen, maxlen, n, e, acc, nemarks, &block)
            end
          end
        end
      end

      if sok
        smarks = mark(marks, s, x)
        if @unmarked
          strings(minlen, maxlen, s, x, acc, smarks, &block)

          if wok
            swmarks = mark(marks, s, w)
            if @unmarked
              strings(minlen, maxlen, s, w, acc, swmarks, &block)
            end
          end

          if eok
            semarks = mark(marks, s, e)
            if @unmarked
              strings(minlen, maxlen, s, e, acc, semarks, &block)
            end
          end
        end
      end

      if wok
        wmarks = mark(marks, y, w)
        if @unmarked
          strings(minlen, maxlen, y, w, acc, wmarks, &block)
        end
      end

      if eok
        emarks = mark(marks, y, e)
        if @unmarked
          strings(minlen, maxlen, y, e, acc, emarks, &block)
        end
      end
    end
  end
end

letters = ARGV[0] || 'nkmtisosdaehivrs'

puts 'Enumerating...'

solver = Wordament::Solver.new
solver.words(letters, min_length: 5, max_length: 15) do |word|
  puts word
end
