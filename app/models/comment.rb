class Comment < ApplicationRecord
  belongs_to :article

  validates :author_name, presence: { message: 'を入力してください' },
                          length: { minimum: 1, maximum: 50, message: 'は1文字以上50文字以内で入力してください' }
  validates :body, presence: { message: 'を入力してください' }
end
