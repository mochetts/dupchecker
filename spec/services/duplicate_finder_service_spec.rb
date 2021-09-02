require 'rails_helper'

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
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 1
      expect(result.first[:file]).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'

      first_match = result.first[:matches].first
      expect(first_match[:phrase]).to eq test_text
      expect(first_match[:indices]).to match_array [2106]
    end

    it "should ignore case and single quotes" do
      test_text = "'ketogenic diets have low long-term tolerability and are not sustainable for many individuals,' researchers wrote"
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 1
      expect(result.first[:file]).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'

      first_match = result.first[:matches].first
      expect(first_match[:phrase]).to eq test_text
      expect(first_match[:indices]).to match_array [3008]
    end

    it "should find multiple instances of the same phrase within one file" do
      test_text = "All rights reserved. Our website services, content, and products are for informational purposes only."
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 2
      expect(result.first[:file]).to eq 'The Ketogenic Diet_ A Detailed Beginner_s Guide to Keto - Healthline.txt'

      first_match = result.first[:matches].first
      expect(first_match[:phrase]).to eq 'Our website services, content, and products are for informational purposes only'
      expect(first_match[:indices]).to match_array [23717, 23975]
    end

    it "should escape regex special characters" do
      test_text = "54. Schnabel, T.G. (1928). AN experience with a (ketogenic) dietary in migraine*. Ann. Intern. Med. 2, 341-347"
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 0
    end

    it "should not detect short phrases" do
      test_text = "AN experience with a ketogenic dietary in"
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 0
    end
  end

end
