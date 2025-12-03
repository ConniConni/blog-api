# Blog API

## プロジェクト概要
個人ブログサイトのバックエンドAPI

### モデル構成
- **Article（記事）**: title, body, status, published_at
- **Comment（コメント）**: article_id, author_name, body
- **リレーション**: Article has_many :comments (dependent: :destroy) / Comment belongs_to :article

### コントローラー構成
- **API::V1::ArticlesController**: 記事のCRUD操作
- **API::V1::CommentsController**: コメントのCRUD操作（Articlesにネスト）

### ルーティング構成
- `/api/v1/articles` - 記事API
- `/api/v1/articles/:article_id/comments` - コメントAPI（ネスト）

## 技術スタック
- Ruby on Rails 7.x (API mode)
- SQLite3（Railsのデフォルト）
- RSpec（テストフレームワーク）
- FactoryBot（テストデータ作成）

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
- 404エラーは `rescue_from ActiveRecord::RecordNotFound` で処理
- 404レスポンス: `{ error: 'Record not found' }` ステータス: `:not_found`
- バリデーションエラー: `{ errors: model.errors.full_messages }` ステータス: `:unprocessable_entity`

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 境界値（制限値付近のケース）

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
