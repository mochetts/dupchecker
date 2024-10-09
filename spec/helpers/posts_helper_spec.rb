require 'rails_helper'

RSpec.describe PostsHelper, type: :helper do
  describe '#highlight_phrase_match' do
    let (:file_content) {"
      Content Integrity
      Newsletters
      Do Not Sell My Info
      © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.
      © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.
      The End
    "}

    it "should return HTML intepretation of the duplications" do
      result = helper.highlight_phrase_match(file_content, { file_start: 128, text_start: 10, file_end: 228, text_end: 110 })
      expect(result).to eq "<div class='p-3 bg-gray-50 mb-4 rounded-sm'>...005-2021 Healthline Media a Red Ventures Company. <span class='text-red-500'>All rights reserved. Our website services, content, and products are for informational purposes only.</span> Healthline Media does not provide medical advice,...</div>"
    end

    it "should not add leading and trailing spaces for whole phrase matching" do
      result = helper.highlight_phrase_match(file_content, { file_start: 0, text_start: 0, file_end: file_content.length, text_end: file_content.length })
      expect(result).to eq "<div class='p-3 bg-gray-50 mb-4 rounded-sm'><span class='text-red-500'>\n      Content Integrity\n      Newsletters\n      Do Not Sell My Info\n      © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.\n      © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.\n      The End\n    </span></div>"
    end
  end
end