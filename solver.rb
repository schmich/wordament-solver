require 'set'
require 'ffi/aspell'

MIN_WORD_SIZE = 4
MAX_WORD_SIZE = 16

speller = FFI::Aspell::Speller.new('en_US')

def letters_prompt
  print 'Letters: '
  letters = gets.strip
end

#letters = letters_prompt
letters = 'nkmtisosdaehivrs'

puts 'Enumerating...'

matrix = [
  letters[0...4],
  letters[4...8],
  letters[8...12],
  letters[12...16]
]

$unmarked = true

def mark(marks, y, x)
  bit = 1 << (y * 4 + x)
  $unmarked = ((marks & bit) == 0)
  marks | bit
end

def strings(matrix, minlen, maxlen, y, x, path = '', marks = mark(0, y, x))
  acc = path + matrix[y][x]

  if acc.length >= minlen
    yield acc
  end

  if acc.length < maxlen
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
      if $unmarked
        strings(matrix, minlen, maxlen, n, x, acc, nmarks) { |s| yield s }

        if wok
          nwmarks = mark(marks, n, w)
          if $unmarked
            strings(matrix, minlen, maxlen, n, w, acc, nwmarks) { |s| yield s }
          end
        end

        if eok
          nemarks = mark(marks, n, e)
          if $unmarked
            strings(matrix, minlen, maxlen, n, e, acc, nemarks) { |s| yield s }
          end
        end
      end
    end

    if sok
      smarks = mark(marks, s, x)
      if $unmarked
        strings(matrix, minlen, maxlen, s, x, acc, smarks) { |s| yield s }

        if wok
          swmarks = mark(marks, s, w)
          if $unmarked
            strings(matrix, minlen, maxlen, s, w, acc, swmarks) { |s| yield s }
          end
        end

        if eok
          semarks = mark(marks, s, e)
          if $unmarked
            strings(matrix, minlen, maxlen, s, e, acc, semarks) { |s| yield s }
          end
        end
      end
    end

    if wok
      wmarks = mark(marks, y, w)
      if $unmarked
        strings(matrix, minlen, maxlen, y, w, acc, wmarks) { |s| yield s }
      end
    end

    if eok
      emarks = mark(marks, y, e)
      if $unmarked
        strings(matrix, minlen, maxlen, y, e, acc, emarks) { |s| yield s }
      end
    end
  end
end

def words(matrix, speller, minlen, maxlen)
  suggested = Set.new

  0.upto(3) { |y|
    0.upto(3) { |x|
      strings(matrix, minlen, maxlen, y, x) { |s|
        if speller.correct? s
          if suggested.add? s
            yield s
          end
        end
      }
    }
  }
end

# TODO: Put code in class, modularize.
# -> Wordament.new(MIN_WORD_SIZE, MAX_WORD_SIZE).words(board) { |word| puts word }

words(matrix, speller, MIN_WORD_SIZE, MAX_WORD_SIZE) { |word|
  puts word
}
