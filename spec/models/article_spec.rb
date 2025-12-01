require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '正常系' do
    it '有効な属性で作成できること' do
      article = build(:article)
      expect(article).to be_valid
    end

    it 'デフォルトでdraft状態であること' do
      article = create(:article)
      expect(article.status).to eq('draft')
    end
  end

  describe '異常系' do
    describe 'バリデーション' do
      it 'titleが空の場合無効' do
        article = build(:article, title: '')
        expect(article).to be_invalid
        expect(article.errors[:title]).to include('を入力してください')
      end

      it 'titleが101文字以上の場合無効' do
        article = build(:article, title: 'あ' * 101)
        expect(article).to be_invalid
        expect(article.errors[:title]).to include('は100文字以内で入力してください')
      end

      it 'bodyが空の場合無効' do
        article = build(:article, body: '')
        expect(article).to be_invalid
        expect(article.errors[:body]).to include('を入力してください')
      end

      it 'published状態でpublished_atがnilの場合無効' do
        article = create(:article, :published)
        article.update_column(:published_at, nil)
        article.valid?
        expect(article).to be_invalid
        expect(article.errors[:published_at]).to include('は公開状態の場合必須です')
      end
    end
  end

  describe '境界値' do
    it 'titleが1文字の場合有効' do
      article = build(:article, title: 'あ')
      expect(article).to be_valid
    end

    it 'titleが100文字の場合有効' do
      article = build(:article, :long_title)
      expect(article).to be_valid
    end
  end

  describe 'メソッド' do
    describe '#publish!' do
      let(:article) { create(:article) }

      it 'statusがpublishedになること' do
        article.publish!
        expect(article.status).to eq('published')
      end

      it 'published_atが設定されること' do
        expect { article.publish! }.to change { article.published_at }.from(nil)
        expect(article.published_at).to be_present
      end

      it '既にpublished状態の場合falseを返すこと' do
        article.publish!
        expect(article.publish!).to eq(false)
      end
    end

    describe '#unpublish!' do
      let(:article) { create(:article, :published) }

      it 'statusがdraftになること' do
        article.unpublish!
        expect(article.status).to eq('draft')
      end

      it 'published_atは保持されること' do
        original_published_at = article.published_at
        article.unpublish!
        expect(article.published_at).to eq(original_published_at)
      end

      it 'draft状態の場合falseを返すこと' do
        article.unpublish!
        expect(article.unpublish!).to eq(false)
      end
    end

    describe '#archive!' do
      let(:article) { create(:article, :published) }

      it 'statusがarchivedになること' do
        article.archive!
        expect(article.status).to eq('archived')
      end

      it '既にarchived状態の場合falseを返すこと' do
        article.archive!
        expect(article.archive!).to eq(false)
      end
    end

    describe 'コールバック: published_atの自動設定' do
      it 'statusをpublishedに直接更新した場合もpublished_atが設定されること' do
        article = create(:article)
        article.update(status: :published)
        expect(article.published_at).to be_present
      end
    end
  end
end
