class Article < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :title, presence: { message: 'タイトルを入力してください' },
                    length: { minimum: 1, maximum: 100,
                             too_short: 'タイトルは1文字以上で入力してください',
                             too_long: 'タイトルは100文字以内で入力してください' }

  validates :body, presence: { message: '本文を入力してください' }

  validates :status, presence: { message: 'を入力してください' }

  before_validation :set_published_at_on_publish, if: :will_save_change_to_status?

  validate :validate_published_at_presence

  def publish!
    return false if published?
    update!(status: :published, published_at: Time.current)
  end

  def unpublish!
    return false unless published?
    update!(status: :draft)
  end

  def archive!
    return false if archived?
    update!(status: :archived)
  end

  private

  def validate_published_at_presence
    if published? && published_at.nil?
      errors.add(:published_at, 'は公開状態の場合必須です')
    end
  end

  def set_published_at_on_publish
    if published? && published_at.nil?
      self.published_at = Time.current
    end
  end
end
