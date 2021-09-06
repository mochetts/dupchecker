require "rails_helper"

RSpec.describe DuplicateFinderService do

  describe "#normalize_text" do
    it "should downcase" do
      test_text = 'This Is Some Text'
      result = DuplicateFinderService.normalize(test_text)
      expect(result).to eq "this is some text"
    end

    it "should replace all types of quotes by double quotes" do
      test_text = '“This” "Is Some" \'Text\''
      result = DuplicateFinderService.normalize(test_text)
      expect(result).to eq '"this" "is some" "text"'
    end

    it "should replace all accented characters by double quotes" do
      test_text = 'áàâéèêíîóúüû'
      result = DuplicateFinderService.normalize(test_text)
      expect(result).to eq '""""""""""""'
    end

    it "should replace all punctuations by double quotes" do
      test_text = '!!..??--'
      result = DuplicateFinderService.normalize(test_text)
      expect(result).to eq '""""""""'
    end
  end

  describe "#files" do
    it "should memoize the files content" do
      expect(Dir).to receive(:glob).and_call_original
      DuplicateFinderService.files
      expect(Dir).not_to receive(:glob)
      DuplicateFinderService.files
    end

    it "should load the files" do
      files = Dir.glob("#{Rails.root}/app/data/*").map { |path|
        original_content = File.read(path)
        {
          name: File.basename(path),
          original: original_content,
          normalized: DuplicateFinderService.normalize(original_content)
        }
      }
      expect(DuplicateFinderService.files).to match_array files
    end
  end

  describe "#find_for" do
    it "should find duplicates" do
      test_text = 'becomes dicier as the focus on low-carbohydrate foods typically steers dieters in the direction of cancer-causing foods and those linked to many of the other conditions it claims to help or eliminate: heart disease, cancer'
      result = DuplicateFinderService.new(test_text).perform
      expect(result.count).to eq 1
      expect(result.first.file_name).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'

      first_match = result.first.phrase_matches.first
      expect(first_match.text_start).to eq 0
      expect(first_match.file_start).to eq 2106
      expect(first_match.text_end).to eq 221
      expect(first_match.file_end).to eq 2327
    end

    it "should ignore case and single quotes" do
      test_text = "'ketogenic diets have low long-term tolerability and are not sustainable for many individuals,' researchers wrote"
      result = DuplicateFinderService.new(test_text).perform
      expect(result.count).to eq 1
      expect(result.first.file_name).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'

      first_match = result.first.phrase_matches.first
      expect(first_match.text_start).to eq 1
      expect(first_match.file_start).to eq 3009
      expect(first_match.text_end).to eq 112
      expect(first_match.file_end).to eq 3120
    end

    it "should find multiple instances of the same phrase within one file" do
      test_text = "All rights reserved. Our website services, content, and products are for informational purposes only."
      result = DuplicateFinderService.new(test_text).perform
      expect(result.count).to eq 2
      expect(result.first.file_name).to eq 'The Ketogenic Diet_ A Detailed Beginner_s Guide to Keto - Healthline.txt'

      first_match = result.first.phrase_matches.first
      expect(first_match.text_start).to eq 0
      expect(first_match.file_start).to eq 23696
      expect(first_match.text_end).to eq 100
      expect(first_match.file_end).to eq 23796
    end

    it "should escape regex special characters" do
      test_text = "54. Schnabel, T.G. (1928). AN experience with a (ketogenic) dietary in migraine*. Ann. Intern. Med. 2, 341-347"
      result = DuplicateFinderService.new(test_text).perform
      expect(result.count).to eq 0
    end

    it "should not detect short phrases" do
      test_text = "AN experience with a ketogenic dietary in"
      result = DuplicateFinderService.new(test_text).perform
      expect(result.count).to eq 0
    end

    it "should expand and merge phrases" do
      file_name = "The Ketogenic Diet_ A Detailed Beginner_s Guide to Keto - Healthline.txt"
      file_contents = File.read("#{Rails.root}/app/data/#{file_name}")
      start_index = file_contents.index('Medical Affairs')
      end_index = file_contents.length
      test_text = file_contents[start_index..end_index]

      result = DuplicateFinderService.new(test_text).perform

      # Assert files
      expect(result.count).to eq 2
      file_match = result.first
      expect(file_match.file_name).to eq file_name

      # Assert phrases
      expect(file_match.phrase_matches.count).to eq 1
      phrase_mach = file_match.phrase_matches.first
      expect(phrase_mach.text_start).to eq 0
      expect(phrase_mach.file_start).to eq 23577
      expect(phrase_mach.text_end).to eq 581
      expect(phrase_mach.file_end).to eq 24158
    end

    it "should merge consecutive matches" do
      file_name = "The Ketogenic Diet_ A Detailed Beginner_s Guide to Keto - Healthline.txt"
      file_contents = File.read("#{Rails.root}/app/data/#{file_name}")
      start_index = file_contents.index("© 2005-2021")
      end_index = file_contents.index("See additional information.") + "See additional information.".length - 1
      test_text = file_contents[start_index..end_index]

      result = DuplicateFinderService.new(test_text).perform

      # Assert files
      expect(result.count).to eq 2
      file_match = result.first
      expect(file_match.file_name).to eq file_name

      # Assert phrases
      expect(file_match.phrase_matches.count).to eq 1
      phrase_mach = file_match.phrase_matches.first
      expect(phrase_mach.text_start).to eq 0
      expect(phrase_mach.file_start).to eq 23643
      expect(phrase_mach.text_end).to eq 257
      expect(phrase_mach.file_end).to eq 24158
    end

    it "should ignore whitespaces and newlines in the input text" do
      test_text = '© 2005-2021 Healthline Media a Red Ventures Company.

      All rights reserved.

      Our website services, content, and products are for informational purposes only.

      Healthline Media does not provide medical

      advice, diagnosis, or treatment.

      See additional information.'

      result = DuplicateFinderService.new(test_text).perform

      # Assert files
      expect(result.count).to eq 2
      file_match = result.first
      expect(file_match.file_name).to eq "The Ketogenic Diet_ A Detailed Beginner_s Guide to Keto - Healthline.txt"

      # Assert phrases
      expect(file_match.phrase_matches.count).to eq 1
      phrase_mach = file_match.phrase_matches.first
      expect(phrase_mach.text_start).to eq 0
      expect(phrase_mach.file_start).to eq 23643
      expect(phrase_mach.text_end).to eq 292
      expect(phrase_mach.file_end).to eq 24158
    end
  end

end
