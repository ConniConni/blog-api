require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe '正常系' do
    it '有効な属性で作成できること' do
      comment = build(:comment)
      expect(comment).to be_valid
    end
  end

  describe '異常系' do
    describe 'バリデーション' do
      it 'author_nameが空の場合無効' do
        comment = build(:comment, author_name: '')
        expect(comment).to be_invalid
        expect(comment.errors[:author_name]).to include('を入力してください')
      end

      it 'author_nameが51文字以上の場合無効' do
        comment = build(:comment, author_name: 'あ' * 51)
        expect(comment).to be_invalid
        expect(comment.errors[:author_name]).to include('は1文字以上50文字以内で入力してください')
      end

      it 'bodyが空の場合無効' do
        comment = build(:comment, body: '')
        expect(comment).to be_invalid
        expect(comment.errors[:body]).to include('を入力してください')
      end

      it 'articleが存在しない場合無効' do
        comment = build(:comment, article: nil)
        expect(comment).to be_invalid
      end
    end
  end

  describe '境界値' do
    it 'author_nameが1文字の場合有効' do
      comment = build(:comment, author_name: 'あ')
      expect(comment).to be_valid
    end

    it 'author_nameが50文字の場合有効' do
      comment = build(:comment, author_name: 'あ' * 50)
      expect(comment).to be_valid
    end
  end

  describe 'リレーション' do
    it 'articleに属していること' do
      association = described_class.reflect_on_association(:article)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
