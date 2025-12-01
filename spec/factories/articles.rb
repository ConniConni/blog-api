FactoryBot.define do
  factory :article do
    title { "テスト記事タイトル" }
    body { "テスト記事の本文です。" }
    status { :draft }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :archived do
      status { :archived }
      published_at { 1.month.ago }
    end

    trait :long_title do
      title { "あ" * 100 }
    end
  end
end
