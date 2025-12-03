# Blog API

## プロジェクト概要
個人ブログサイトのバックエンドAPI

### モデル構成
- **User（ユーザー）**: email, encrypted_password（Devise）
- **Article（記事）**: title, body, status, published_at, user_id
- **Comment（コメント）**: article_id, user_id, author_name, body
- **リレーション**:
  - User has_many :articles, has_many :comments
  - Article belongs_to :user, has_many :comments (dependent: :destroy)
  - Comment belongs_to :article, belongs_to :user

### コントローラー構成
- **API::V1::BaseController**: 認証・認可の基底コントローラー
- **API::V1::ArticlesController**: 記事のCRUD操作（認証・認可あり）
- **API::V1::CommentsController**: コメントのCRUD操作（Articlesにネスト、認証・認可あり）

### ルーティング構成
- `/api/v1/articles` - 記事API
- `/api/v1/articles/:article_id/comments` - コメントAPI（ネスト）

## 技術スタック
- Ruby on Rails 7.x (API mode)
- SQLite3（Railsのデフォルト）
- RSpec（テストフレームワーク）
- FactoryBot（テストデータ作成）
- Devise（ユーザー認証）
- devise-jwt（JWT認証）

## 開発ルール

### 一般
- テストは必ず書く（RSpec）
- コミットは日本語で記述

### バリデーション
- エラーメッセージは日本語で記述
- 例: `presence: { message: 'を入力してください' }`
- `full_messages`は「属性名 メッセージ」形式（例: "Title タイトルを入力してください"）

### enum
- integer型で定義し、値は明示的に指定
- 例: `enum status: { draft: 0, published: 1, archived: 2 }`

### カスタムバリデーション
- メソッド名: validate_カラム名_チェック内容
- 例: `validate_published_at_presence`

### APIバージョニング
- `namespace :api` と `namespace :v1` でネスト
- コントローラーは `Api::V1::` モジュールに配置
- 例: `Api::V1::ArticlesController`

### エラーハンドリング
- 401エラー（未認証）: `before_action :authenticate_user!` で自動処理
  - レスポンス: `{ error: 'Unauthorized' }` ステータス: `:unauthorized`
- 403エラー（認可失敗）: カスタムメソッドで処理
  - レスポンス: `{ error: 'Forbidden' }` ステータス: `:forbidden`
- 404エラー: `rescue_from ActiveRecord::RecordNotFound` で処理
  - レスポンス: `{ error: 'Record not found' }` ステータス: `:not_found`
- 422エラー（バリデーションエラー）: コントローラーで処理
  - レスポンス: `{ errors: model.errors.full_messages }` ステータス: `:unprocessable_entity`

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 認証（未認証時の動作確認）
4. 認可（他ユーザーのリソース操作確認）

### ファクトリ
- デフォルトは最小限の有効な状態
- バリエーションはtraitで定義

### テストの実行方法

#### 全テストを実行
```bash
bundle exec rspec
```

#### 特定のファイルを実行
```bash
bundle exec rspec spec/models/article_spec.rb
bundle exec rspec spec/requests/api/v1/articles_spec.rb
```

#### 特定のディレクトリを実行
```bash
bundle exec rspec spec/models/
bundle exec rspec spec/requests/api/v1/
```

### FactoryBotの使い方

#### 基本的な使い方
```ruby
# build: インスタンス作成（保存しない）
article = build(:article)

# create: インスタンス作成して保存
article = create(:article)

# traitの使用
published_article = create(:article, :published)

# 属性のオーバーライド
article = create(:article, title: "カスタムタイトル")

# 関連付けられたデータの作成
article = create(:article, :published)
comment = create(:comment, article: article)
```

#### 認証ヘルパーの使い方
```ruby
# spec/support/auth_helper.rb で定義されたヘルパーメソッド
# JWTトークンを生成してAuthorizationヘッダーを返す

# 認証ありのリクエスト
post api_v1_articles_path, params: valid_params, headers: auth_headers(user)

# 認証なしのリクエスト（401テスト用）
post api_v1_articles_path, params: valid_params

# 他ユーザーで認証（403テスト用）
other_user = create(:user)
patch api_v1_article_path(article), params: update_params, headers: auth_headers(other_user)
```

## 実装詳細

### Phase 1: 認証機能の基盤構築

#### 1.1 Gemの追加
```ruby
# Gemfile
gem 'devise'
gem 'devise-jwt'
```

```bash
bundle install
```

#### 1.2 Deviseのセットアップ
```bash
rails generate devise:install
rails generate devise User
rails db:migrate
```

#### 1.3 devise-jwtの設定
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # 既存の設定...

  config.jwt do |jwt|
    jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
    jwt.dispatch_requests = [
      ['POST', %r{^/users/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/users/sign_out$}]
    ]
    jwt.expiration_time = 1.day.to_i
  end

  # API modeのため、ナビゲーショナルフォーマットを無効化
  config.navigational_formats = []
end
```

#### 1.4 JwtDenylistモデルの作成
```bash
rails generate model JwtDenylist jti:string:index exp:datetime
rails db:migrate
```

```ruby
# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = 'jwt_denylist'
end
```

#### 1.5 Userモデルの設定
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy
end
```

#### 1.6 環境変数の設定
```bash
# 秘密鍵の生成
rails secret

# .env ファイルに追加（gitignoreに追加すること）
DEVISE_JWT_SECRET_KEY=生成された秘密鍵
```

### Phase 2: 認証・認可の実装

#### 2.1 API用BaseControllerの作成
```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      private

      def record_not_found
        render json: { error: 'Record not found' }, status: :not_found
      end
    end
  end
end
```

#### 2.2 ArticlesControllerの認証・認可実装
```ruby
# app/controllers/api/v1/articles_controller.rb
class Api::V1::ArticlesController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_article, only: [:show, :update, :destroy]
  before_action :authorize_user!, only: [:update, :destroy]

  # index, show は認証不要
  def index
    articles = Article.published.order(published_at: :desc)
    render json: articles
  end

  def show
    render json: @article
  end

  # create, update, destroy は認証必須
  def create
    article = current_user.articles.build(article_params)
    if article.save
      render json: article, status: :created
    else
      render json: { errors: article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @article.update(article_params)
      render json: @article
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    head :no_content
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def authorize_user!
    unless @article.user == current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def article_params
    params.require(:article).permit(:title, :body, :status)
  end
end
```

#### 2.3 CommentsControllerの認証・認可実装
```ruby
# app/controllers/api/v1/comments_controller.rb
class Api::V1::CommentsController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :set_article
  before_action :set_comment, only: [:destroy]
  before_action :authorize_user!, only: [:destroy]

  def index
    comments = @article.comments.order(created_at: :desc)
    render json: comments
  end

  def create
    comment = @article.comments.build(comment_params)
    comment.user = current_user
    if comment.save
      render json: comment, status: :created
    else
      render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    head :no_content
  end

  private

  def set_article
    @article = Article.find(params[:article_id])
  end

  def set_comment
    @comment = @article.comments.find(params[:id])
  end

  def authorize_user!
    unless @comment.user == current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def comment_params
    params.require(:comment).permit(:author_name, :body)
  end
end
```

### Phase 3: モデルの関連付け

#### 3.1 Articleモデルへのuser_id追加
```bash
rails generate migration AddUserIdToArticles user:references
rails db:migrate
```

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :title, presence: { message: 'タイトルを入力してください' }
  validates :body, presence: { message: '本文を入力してください' }
  validates :status, presence: true

  enum status: { draft: 0, published: 1, archived: 2 }

  validate :validate_published_at_presence

  before_save :set_published_at

  scope :published, -> { where(status: :published) }

  private

  def validate_published_at_presence
    if published? && published_at.blank?
      errors.add(:published_at, '公開日時を入力してください')
    end
  end

  def set_published_at
    if status_changed? && published? && published_at.blank?
      self.published_at = Time.current
    end
  end
end
```

#### 3.2 Commentモデルへのuser_id追加
```bash
rails generate migration AddUserIdToComments user:references
rails db:migrate
```

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :user

  validates :author_name, presence: { message: 'を入力してください' },
                          length: { in: 1..50, message: 'は1文字以上50文字以内で入力してください' }
  validates :body, presence: { message: 'を入力してください' }
end
```

### Phase 4: テスト実装

#### 4.1 Support Moduleの作成
```ruby
# spec/support/auth_helper.rb
module AuthHelper
  def auth_headers(user)
    token = JWT.encode(
      { sub: user.id, scp: 'user', exp: 24.hours.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY']
    )
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
```

#### 4.2 rails_helper.rbの設定
```ruby
# spec/rails_helper.rb
# 以下の行のコメントを解除
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }
```

#### 4.3 Factoryの更新
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
  end
end

# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    association :user
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
  end
end

# spec/factories/comments.rb
FactoryBot.define do
  factory :comment do
    association :article
    association :user
    author_name { "テストユーザー" }
    body { "これはテストコメントです。" }
  end
end
```

#### 4.4 Request Specのテストパターン

```ruby
# 認証テスト（401 Unauthorized）
context "認証" do
  it "未認証の場合は401を返すこと" do
    post api_v1_articles_path, params: valid_params
    expect(response).to have_http_status(:unauthorized)

    json = JSON.parse(response.body)
    expect(json["error"]).to eq("Unauthorized")
  end
end

# 認可テスト（403 Forbidden）
context "認可" do
  it "他ユーザーの記事を更新しようとすると403を返すこと" do
    other_user = create(:user)

    patch api_v1_article_path(article),
          params: update_params,
          headers: auth_headers(other_user)

    expect(response).to have_http_status(:forbidden)

    json = JSON.parse(response.body)
    expect(json["error"]).to eq("Forbidden")
  end
end

# 正常系（認証あり）
context "正常系" do
  let(:user) { create(:user) }

  it "認証ありで記事が作成できること" do
    expect {
      post api_v1_articles_path,
           params: valid_params,
           headers: auth_headers(user)
    }.to change(Article, :count).by(1)

    expect(response).to have_http_status(:created)

    json = JSON.parse(response.body)
    expect(json["user_id"]).to eq(user.id)
  end
end
```
