# Class in charge of finding duplicate texts across the source text files.

class DuplicateFinderService
  PUNCTUATIONS = /\.|!|\?|\r\n|\n/
  MIN_WORD_COUNT = 10

  class << self

    # Public: Initializes the class calling the `files` method so that they are already available
    def init
      files
    end

    # Public: Reads the data source files into memory and memoizes the contents
    # so that we avoid IO operations when doing dupe searches.
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
    # state and be able to compare them evenly
    def normalize(text)
      text.
        downcase.
        gsub(/"|'|“|”|\n/, ''). # Remove quotes and new lines
        split(' '). # Remove consequential whitespaces
        join(' ')
    end


    # Public: Finds all files containing duplicates for the given text.
    # Returns a Hash with the following attributes:
    #   name: Name of the file containing the duplicate
    #   original: Original text of the file
    #   normalized: Normalized text of the file
    #   index: Position in which the duplicate was found
    def find_for(text)
      text.split(PUNCTUATIONS).reject { |phrase|
        # Reject phrases that don't have enough words to count as plagiarism
        phrase.split.count < MIN_WORD_COUNT
      }.map { |phrase|
        phrase.strip! # Remove trailing and leading whitespaces
        normalized_phrase = normalize(phrase)
        {
          phrase: phrase,
          found_in: files.map { |file|
            index = file[:normalized].index(normalized_phrase)
            index && { file_name: file[:name], index: index } || nil
          }.compact.presence
        }
      }
    end
  end
end