FactoryBot.define do
  factory :comment do
    association :article
    association :user
    author_name { "テストユーザー" }
    body { "これはテストコメントです。" }
  end
end
