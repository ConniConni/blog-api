require 'rails_helper'

RSpec.describe "Api::V1::Comments", type: :request do
  let(:article) { create(:article, :published) }

  describe "GET /api/v1/articles/:article_id/comments" do
    context "正常系" do
      it "特定の記事に紐づくコメント一覧が取得できること" do
        comment1 = create(:comment, article: article, created_at: 2.days.ago)
        comment2 = create(:comment, article: article, created_at: 1.day.ago)
        other_article = create(:article, :published)
        create(:comment, article: other_article)

        get api_v1_article_comments_path(article)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json[0]["id"]).to eq(comment2.id)
        expect(json[1]["id"]).to eq(comment1.id)
      end

      it "コメントがない場合は空の配列を返すこと" do
        get api_v1_article_comments_path(article)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to eq([])
      end

      it "コメントのJSONレスポンスに必要な情報が含まれていること" do
        comment = create(:comment, article: article, author_name: "テストユーザー", body: "テストコメント")

        get api_v1_article_comments_path(article)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json[0]["id"]).to eq(comment.id)
        expect(json[0]["author_name"]).to eq("テストユーザー")
        expect(json[0]["body"]).to eq("テストコメント")
        expect(json[0]["article_id"]).to eq(article.id)
      end
    end

    context "異常系" do
      it "存在しない記事IDの場合は404を返すこと" do
        get api_v1_article_comments_path(article_id: 99999)
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Record not found")
      end
    end
  end

  describe "POST /api/v1/articles/:article_id/comments" do
    context "正常系" do
      it "コメントを作成できること" do
        valid_params = {
          comment: {
            author_name: "テストユーザー",
            body: "テストコメントです。"
          }
        }

        expect {
          post api_v1_article_comments_path(article), params: valid_params
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["author_name"]).to eq("テストユーザー")
        expect(json["body"]).to eq("テストコメントです。")
        expect(json["article_id"]).to eq(article.id)
      end

      it "作成したコメントが記事に紐づいていること" do
        valid_params = {
          comment: {
            author_name: "テストユーザー",
            body: "テストコメントです。"
          }
        }

        post api_v1_article_comments_path(article), params: valid_params
        expect(response).to have_http_status(:created)

        article.reload
        expect(article.comments.count).to eq(1)
        expect(article.comments.first.author_name).to eq("テストユーザー")
      end
    end

    context "異常系" do
      it "不正なパラメータでは422を返すこと" do
        invalid_params = {
          comment: {
            author_name: "",
            body: ""
          }
        }

        expect {
          post api_v1_article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "author_nameが空の場合エラーが返ること" do
        invalid_params = {
          comment: {
            author_name: "",
            body: "テストコメントです。"
          }
        }

        expect {
          post api_v1_article_comments_path(article), params: invalid_params
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
          post api_v1_article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Body を入力してください")
      end

      it "author_nameが51文字以上の場合エラーが返ること" do
        invalid_params = {
          comment: {
            author_name: "あ" * 51,
            body: "テストコメントです。"
          }
        }

        expect {
          post api_v1_article_comments_path(article), params: invalid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Author name は1文字以上50文字以内で入力してください")
      end

      it "存在しない記事IDの場合は404を返すこと" do
        valid_params = {
          comment: {
            author_name: "テストユーザー",
            body: "テストコメントです。"
          }
        }

        post api_v1_article_comments_path(article_id: 99999), params: valid_params
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Record not found")
      end
    end
  end

  describe "DELETE /api/v1/articles/:article_id/comments/:id" do
    context "正常系" do
      it "コメントを削除できること" do
        comment = create(:comment, article: article)

        expect {
          delete api_v1_article_comment_path(article, comment)
        }.to change(Comment, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "削除後にコメントが存在しないこと" do
        comment = create(:comment, article: article)

        delete api_v1_article_comment_path(article, comment)
        expect(response).to have_http_status(:no_content)

        expect(Comment.exists?(comment.id)).to be false
      end
    end

    context "異常系" do
      it "存在しないコメントIDの場合は404を返すこと" do
        delete api_v1_article_comment_path(article, id: 99999)
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Record not found")
      end

      it "存在しない記事IDの場合は404を返すこと" do
        comment = create(:comment, article: article)

        delete api_v1_article_comment_path(article_id: 99999, id: comment.id)
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Record not found")
      end

      it "他の記事のコメントを削除しようとした場合は404を返すこと" do
        other_article = create(:article, :published)
        other_comment = create(:comment, article: other_article)

        delete api_v1_article_comment_path(article, other_comment)
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Record not found")
      end
    end
  end
end
