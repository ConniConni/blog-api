require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let(:article) { create(:article, :published) }

  describe "GET /articles/:article_id/comments" do
    context "正常系" do
      it "指定した記事のコメント一覧が新しい順で取得できること" do
        comment1 = create(:comment, article: article, created_at: 2.days.ago)
        comment2 = create(:comment, article: article, created_at: 1.day.ago)
        other_article = create(:article, :published)
        create(:comment, article: other_article)

        get article_comments_path(article)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json[0]["id"]).to eq(comment2.id)
        expect(json[1]["id"]).to eq(comment1.id)
      end
    end
  end

  describe "POST /articles/:article_id/comments" do
    context "正常系" do
      it "有効なパラメータでコメントが作成できること" do
        valid_params = {
          comment: {
            author_name: "テストユーザー",
            body: "テストコメントです。"
          }
        }

        expect {
          post article_comments_path(article), params: valid_params
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["author_name"]).to eq("テストユーザー")
        expect(json["body"]).to eq("テストコメントです。")
        expect(json["article_id"]).to eq(article.id)
      end
    end

    context "異常系" do
      it "author_nameが空の場合エラーが返ること" do
        invalid_params = {
          comment: {
            author_name: "",
            body: "テストコメントです。"
          }
        }

        expect {
          post article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Author name を入力してください")
      end

      it "bodyが空の場合エラーが返ること" do
        invalid_params = {
          comment: {
            author_name: "テストユーザー",
            body: ""
          }
        }

        expect {
          post article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Body を入力してください")
      end
    end

    context "境界値" do
      it "author_nameが1文字の場合作成できること" do
        valid_params = {
          comment: {
            author_name: "あ",
            body: "テストコメントです。"
          }
        }

        expect {
          post article_comments_path(article), params: valid_params
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "author_nameが50文字の場合作成できること" do
        valid_params = {
          comment: {
            author_name: "あ" * 50,
            body: "テストコメントです。"
          }
        }

        expect {
          post article_comments_path(article), params: valid_params
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "author_nameが51文字の場合エラーが返ること" do
        invalid_params = {
          comment: {
            author_name: "あ" * 51,
            body: "テストコメントです。"
          }
        }

        expect {
          post article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Author name は1文字以上50文字以内で入力してください")
      end
    end
  end

  describe "DELETE /articles/:article_id/comments/:id" do
    context "正常系" do
      it "コメントが削除できること" do
        comment = create(:comment, article: article)

        expect {
          delete article_comment_path(article, comment)
        }.to change(Comment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
