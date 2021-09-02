module PostsHelper

  # Public: Provides an HTML that renders the instances of duplication for a single phrase within a file.
  #
  # plain_text - String - text the user provided as input
  # file_content - String - content of the file being iterated on
  # index - Integer - initial minimum duplicate index provided by the DuplicateFinderService.
  # duped_phrase - String - initial duplicated phrase that was provided by the DuplicateFinderService
  #
  # Returns the HTML string
  def highlight_dupe(plain_text, file_content, indices, duped_phrase)
    matched_text_class = 'p-3 bg-gray-50 mb-4 rounded-sm'

    inner_content = indices.map { |index|
      dupe_start = find_dupe_start(plain_text, file_content, index, duped_phrase)
      dupe_end = find_dupe_end(plain_text, file_content, index, duped_phrase)

      min_index = [0, dupe_start - 50].max
      max_index = [dupe_end + 50, file_content.length].min

      duped_text = file_content[dupe_start..dupe_end]
      trimmed_content = file_content[min_index..max_index]

      leading_dots = min_index > 0 ? '...' : ''
      trailing_dots = max_index < file_content.length ? '...' : ''

      leading_dots + trimmed_content.gsub(duped_text, "<span class='text-red-500'>#{duped_text}</span>") + trailing_dots
    }.join("</div><div class='#{matched_text_class}'>")

    "<div class='#{matched_text_class}'>#{inner_content}</div>".html_safe
  end

private

  # Private: Finds the minimum duplicate start by backwards comparing
  # the input text and the file content until a difference is found.
  #
  # plain_text - String - text the user provided as input
  # file_content - String - content of the file being iterated on
  # index - Integer - initial minimum duplicate index provided by the DuplicateFinderService.
  # duped_phrase - String - initial duplicated phrase that was provided by the DuplicateFinderService
  #
  # Returns the minimum duplicate start index
  def find_dupe_start(plain_text, file_content, index, duped_phrase)
    plain_text_start_index = plain_text.index(duped_phrase)
    start_index = index

    while plain_text_start_index >= 0 &&
      start_index >= 0 &&
      plain_text[plain_text_start_index]&.downcase == file_content[start_index]&.downcase

      start_index -= 1
      plain_text_start_index -= 1

      while is_new_line_or_whitespace(plain_text[plain_text_start_index])
        plain_text_start_index -= 1
      end

      while is_new_line_or_whitespace(file_content[start_index])
        start_index -= 1
      end
    end

    start_index + 1
  end

  # Private: Finds the maximum duplicate end by forward comparing
  # the input text and the file content until a difference is found.
  #
  # plain_text - String - text the user provided as input
  # file_content - String - content of the file being iterated on
  # index - Integer - initial minimum duplicate index provided by the DuplicateFinderService.
  # duped_phrase - String - initial duplicated phrase that was provided by the DuplicateFinderService
  #
  # Returns the maximum duplicate end index
  def find_dupe_end(plain_text, file_content, index, duped_phrase)
    plain_text_end_index = plain_text.index(duped_phrase) + duped_phrase.length
    end_index = index + duped_phrase.length

    while plain_text_end_index <= plain_text.length &&
      end_index <= file_content.length &&
      plain_text[plain_text_end_index]&.downcase == file_content[end_index]&.downcase

      end_index += 1
      plain_text_end_index += 1

      while is_new_line_or_whitespace(plain_text[plain_text_end_index])
        plain_text_end_index += 1
      end

      while is_new_line_or_whitespace(file_content[end_index])
        end_index += 1
      end
    end

    end_index - 1
  end

  # Private: Returns true if the character is a newline or a whitespace
  def is_new_line_or_whitespace(char)
    char == "\n" || char == "\n\r" || char == " " || char == "\t" || char&.ord == 160 # nbsp
  end
end