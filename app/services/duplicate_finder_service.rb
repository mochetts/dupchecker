# Class in charge of finding duplicate texts across the source text files.

class DuplicateFinderService
  MIN_WORD_COUNT = 8

  attr_reader :text

  delegate :files, :normalize, to: :class

# Auxiliary structures
  # Public
  FileMatch = Struct.new(:file_name, :file_content, :phrase_matches)
  # Public
  IndexMatch = Struct.new(:text_start, :file_start, :text_end, :file_end) do
    # Public: Checks whether a given index match is contained within a set of other comparing matches
    #
    # Returns true if the start/end index match is already contained within the comparing matches
    def contained_in?(comparing_matches)
      comparing_matches.any? { |compared_match|
        file_start >= compared_match.file_start &&
        file_end <= compared_match.file_end
      }
    end
  end
  # Internal: Used as intermediate step when finding all phrases that match within the file
  PhraseMatch = Struct.new(:phrase, :indices)

  class << self
    # Public: Initializes the class calling the `files` method so that they are already available in memory
    # when finding duplicates for the first time.
    def init
      files
    end

    # Public: Reads the data source files into memory and memoizes the contents
    # in order to avoid IO operations when doing duplicate searches.
    def files
      @files ||= Dir.glob("#{Rails.root}/app/data/*").map { |path|
        original_content = File.read(path)
        {
          name: File.basename(path),
          original: original_content,
          normalized: normalize(original_content)
        }
      }
    end

    # Public: Normalizations done in order to bring two texts to the same normalized
    # state and be able to compare them evenly.
    #
    # The normalizaitons done are:
    #  - Downcases the text
    #  - Replaces all types of quotes, accented characters and punctuations for double quotes
    def normalize(text)
      text.
        downcase.
        gsub(/"|'|“|”|[À-ÿ]|[.!?\\-]/, '"')
    end
  end

  def initialize(text)
    @text = text
  end

  # Public: Finds all files containing duplicate phrases for the given text.
  # This algorithm consits of 3 steps:
  #   Step 1) Find all possible duplications for the phrases matching the criteria.
  #   Step 2) Expand matches found in Step 1 so that we don't have consecutive phrases shown as different matches.
  #   Step 3) Merge the results of Step 2 so that we show matches that are contained within other matches or are consecutive as 1 single match.
  #
  # Returns a Hash with the following attributes:
  #   file_name: Name of the file containing the duplicate
  #   file_content: Content of the file
  #   matches: Array of Hashes containing the start/end indices of duplications
  #            for the file input text and the file content
  def perform
    phrases = split_phrases(text)

    files.map { |file|

      # Find matches matching criteria
      matches = find_duplicate_phrases_in_file(phrases, file)

      # Expand matches forward and backwards
      expanded_matches = expand_matches(file[:original], matches)

      # Merge matches that are contained by other matches
      merged_matches = merge_matches(file[:original], expanded_matches)

      if merged_matches.any?
        FileMatch.new(file[:name], file[:original], merged_matches)
      end
    }.compact
  end


private

  # Private: Splits a text by the punctuations and new lines.
  # Excludes phrases that don't have enough words to be considered as plagiarism.
  def split_phrases(text)
    ps = PragmaticSegmenter::Segmenter.new(text: text)
    ps.segment.reject { |phrase|
      phrase.split.count < MIN_WORD_COUNT
    }.uniq.map { |phrase|
      {
        original: phrase.strip! || phrase, # Remove trailing and leading whitespaces
        normalized: normalize(phrase),
      }
    }
  end

  # Private: Iterates all the provided phrases searching for duplicates in the specified file.
  #
  # Returns an array of PhraseMatch
  def find_duplicate_phrases_in_file(phrases, file)
    phrases.map { |phrase|
      # Find all indices of the phrase within the text
      escaped_phrase = Regexp.escape(phrase[:normalized])
      indices = file[:normalized].enum_for(:scan, /(?=#{escaped_phrase})/).map do
        Regexp.last_match.offset(0).first
      end

      if indices.any?
        PhraseMatch.new(phrase[:original], indices)
      end
    }.compact
  end

  # Private: Iterates all the provided matches expanding them one by one
  #
  # Returns an array of IndexMatch
  def expand_matches(file_content, matches)
    matches.flat_map { |match| expand_match(file_content, match) }
  end

  # Private: Expands the matched phrase forwards and backwards until there's no more matching
  # between the text input and the file contents
  #
  # file_content - String - content of the file being iterated on
  # match - Hash - Match data about a phrase
  #
  # Returns an Array with the minimum duplicate start index and the maximum duplicate end index
  # for both the input text and the file content and for each matching index for the matched phrase
  def expand_match(file_content, match)
    duped_phrase = match.phrase
    text_start_index = text.index(duped_phrase)

    # Warning: The below line has a strict requirement:
    # Identical phrases, but with different amount of whitespaces between words, don't match
    text_end_index = text.index(duped_phrase) + duped_phrase.length - 1

    match.indices.map { |index|
      file_start_index = index
      min_start_indices = expand_index_backward(file_content, text_start_index, file_start_index)

      file_end_index = index + duped_phrase.length - 1
      max_end_indices = expand_index_forward(file_content, text_end_index, file_end_index)

      indices = min_start_indices + max_end_indices
      IndexMatch.new(*indices)
    }
  end

  # Private: Finds the minimum duplicate start indices for both the input text and the file content
  # by backward comparing both texts until a difference is found.
  #
  # file_content - String - content of the file being iterated on
  # text_start_index - Integer - initial minimum duplicate index within the input text
  # file_start_index - Integer - initial minimum duplicate index within the file content
  #
  # Returns an Array containing the the minimum start indices for the input text and the file content
  def expand_index_backward(file_content, text_start_index, file_start_index)
    file_go_back = 1
    text_go_back = 1
    while text_start_index >= 0 &&
      file_start_index >= 0 &&
      text[text_start_index]&.downcase == file_content[file_start_index]&.downcase

      file_go_back = 1
      text_go_back = 1
      file_start_index -= 1
      text_start_index -= 1

      while is_new_line_or_whitespace(text[text_start_index])
        text_start_index -= 1
        text_go_back += 1
      end

      while is_new_line_or_whitespace(file_content[file_start_index])
        file_start_index -= 1
        file_go_back += 1
      end
    end
    [text_start_index + text_go_back, file_start_index + file_go_back]
  end

  # Private: Finds the maximum duplicate end indices for both the input text and the file content
  # by forward comparing both texts until a difference is found.
  #
  # file_content - String - content of the file being iterated on
  # text_end_index - Integer - initial maximum duplicate index within the input text
  # file_end_index - Integer - initial maximum duplicate index within the file content
  #
  # Returns an Array containing the the maximum end indices for the input text and the file content
  def expand_index_forward(file_content, text_end_index, file_end_index)
    file_go_forward = 1
    text_go_forward = 1
    while text_end_index <= text.length &&
      file_end_index <= file_content.length &&
      text[text_end_index]&.downcase == file_content[file_end_index]&.downcase

      file_go_forward = 1
      text_go_forward = 1
      file_end_index += 1
      text_end_index += 1

      while is_new_line_or_whitespace(text[text_end_index])
        text_end_index += 1
        text_go_forward += 1
      end

      while is_new_line_or_whitespace(file_content[file_end_index])
        file_end_index += 1
        file_go_forward += 1
      end
    end
    [text_end_index - text_go_forward, file_end_index - file_go_forward]
  end

  # Private: Merges index matches that are included within other index matches and that are consecutive
  #
  # matches - Array of IndexMatch
  #
  # Returns an Array IndexMatch
  def merge_matches(file_content, matches)
    matches.each_with_index.inject([]) { |merged_matches, (match, index)|
      if index == 0 || !match.contained_in?(merged_matches)
        last_match = merged_matches.last
        if last_match && (last_match.file_end == match.file_start || joined_by_whitespaces(last_match, match, file_content))
          last_match.file_end = match.file_end
          last_match.text_end = match.text_end
          merged_matches
        else
          merged_matches << match
        end
      else
        merged_matches
      end
    }
  end

  # Private: Returns true if the character is a newline or a whitespace
  def is_new_line_or_whitespace(char)
    char == "\n" || char == "\n\r" || char == " " || char == "\t" || char&.ord == 160 # nbsp
  end

  def joined_by_whitespaces(first_match, second_match, file_content)
    (first_match.file_end + 1..second_match.file_start - 1).to_a.all? { |char_index| is_new_line_or_whitespace(file_content[char_index]) }
  end
end