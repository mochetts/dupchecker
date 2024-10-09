module PostsHelper

  # Public: Provides an HTML that renders the instances of a phrase duplication match within a file.
  #
  # file_content - String - content of the file being iterated on
  # phrase_match - Hash - containting the start and end indices of the match
  #
  # Returns the HTML string
  def highlight_phrase_match(file_content, phrase_match)
    min_index = [0, phrase_match[:file_start] - 50].max
    max_index = [phrase_match[:file_end] + 50, file_content.length].min

    duped_text = file_content[phrase_match[:file_start]..phrase_match[:file_end]]
    trimmed_content = file_content[min_index..max_index]

    leading_dots = min_index > 0 ? '...' : ''
    trailing_dots = max_index < file_content.length ? '...' : ''

    inner_content = leading_dots + trimmed_content.gsub(duped_text, "<span class='text-red-500'>#{duped_text}</span>") + trailing_dots

    "<div class='p-3 bg-gray-50 mb-4 rounded-sm'>#{inner_content}</div>".html_safe
  end
end