require 'rails_helper'

RSpec.describe PostsHelper, type: :helper do
  describe '#highlight_dupe' do
    it 'should return HTML intepretation of the duplications' do
      result = helper.highlight_dupe(
        '2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.',
        '
        Content Integrity
        Newsletters
        Do Not Sell My Info
        © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.
        © 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.
        The End
        ',
        [157, 423],
        'Our website services, content, and products are for informational purposes only'
      )
      expect(result).to eq "<div class='p-3 bg-gray-50 mb-4 rounded-sm'>... Newsletters\n        Do Not Sell My Info\n        ©<span class='text-red-500'> 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.\n        </span>© 2005-2021 Healthline Media a Red Ventures Compan...</div><div class='p-3 bg-gray-50 mb-4 rounded-sm'>...r treatment. See additional information.\n        ©<span class='text-red-500'> 2005-2021 Healthline Media a Red Ventures Company. All rights reserved. Our website services, content, and products are for informational purposes only. Healthline Media does not provide medical advice, diagnosis, or treatment. See additional information.\n        </span>The End\n        </div>"
    end
  end
end