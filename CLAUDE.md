# Blog API

## プロジェクト概要
個人ブログサイトのバックエンドAPI

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

### enum
- integer型で定義し、値は明示的に指定
- 例: `enum status: { draft: 0, published: 1, archived: 2 }`

### カスタムバリデーション
- メソッド名: validate_カラム名_チェック内容
- 例: `validate_published_at_presence`

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 境界値（制限値付近のケース）

### ファクトリ
- デフォルトは最小限の有効な状態
- バリエーションはtraitで定義
