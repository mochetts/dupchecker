# Class in charge of finding duplicate texts across the source text files.

class DuplicateFinderService
  MIN_WORD_COUNT = 8

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


    # Public: Finds all files containing duplicate phrases for the given text.
    #
    # Returns a Hash with the following attributes:
    #   name: Name of the file containing the duplicate
    #   original: Original text of the file
    #   normalized: Normalized text of the file
    #   index: Position in which the duplicate was found
    def find_for(text)
      phrases = split_phrases(text)

      files.map { |file|

        matches = find_duplicate_phrases_in_file(phrases, file)

        if matches.any?
          {
            file_name: file[:name],
            file_content: file[:original],
            matches: matches,
          }
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
    # Returns an array of
    def find_duplicate_phrases_in_file(phrases, file)
      phrases.map { |phrase|

        # Find all indices of the phrase within the text
        escaped_phrase = Regexp.escape(phrase[:normalized])
        indices = file[:normalized].enum_for(:scan, /(?=#{escaped_phrase})/).map do
          Regexp.last_match.offset(0).first
        end

        if indices.any?
          {
            phrase: phrase[:original],
            indices: indices,
          }
        end
      }.compact
    end

  end
end