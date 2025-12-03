FactoryBot.define do
  factory :comment do
    association :article
    author_name { "テストユーザー" }
    body { "これはテストコメントです。" }
  end
end
