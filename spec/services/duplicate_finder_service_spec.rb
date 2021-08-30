require 'rails_helper'

RSpec.describe DuplicateFinderService do

  describe "#normalize_text" do
    it "should downcase" do
      test_text = 'This Is Some Text'
      result = DuplicateFinderService.normalize(test_text)
      assert_equal result, "this is some text"
    end

    it "should remove all tyep of quotes" do
      test_text = '“This” "Is Some" \'Text\''
      result = DuplicateFinderService.normalize(test_text)
      assert_equal result, "this is some text"
    end

    it "should ignore newlines" do
      test_text = "This Is \n Some Text"
      result = DuplicateFinderService.normalize(test_text)
      assert_equal result, "this is some text"
    end

    it "should remove consequential whitespaces" do
      test_text = "This Is     Some Text"
      result = DuplicateFinderService.normalize(test_text)
      assert_equal result, "this is some text"
    end
  end

  describe "#find_for" do
    it "should find duplicates" do
      test_text = 'becomes dicier as the focus on low-carbohydrate foods typically steers dieters in the direction of cancer-causing foods and those linked to many of the other conditions it claims to help or eliminate: heart disease, cancer'
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 1
      expect(result.first[:phrase]).to eq test_text
      expect(result.first[:found_in].first[:file_name]).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'
      expect(result.first[:found_in].first[:index]).to eq 2085
    end

    it "should ignore case and single quotes" do
      test_text = "'ketogenic diets have low long-term tolerability and are not sustainable for many individuals,' researchers wrote"
      result = DuplicateFinderService.find_for(test_text)
      expect(result.count).to eq 1
      expect(result.first[:phrase]).to eq test_text
      expect(result.first[:found_in].first[:file_name]).to eq 'Keto diet _a recipe for bad health,_ study warns.txt'
      expect(result.first[:found_in].first[:index]).to eq 2982
    end
  end

end
