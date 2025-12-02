require 'rails_helper'

RSpec.describe "Articles", type: :request do
  describe "GET /articles" do
    context "正常系" do
      it "公開済み記事のみが新しい順で取得できること" do
        published_article1 = create(:article, :published, published_at: 2.days.ago)
        published_article2 = create(:article, :published, published_at: 1.day.ago)
        create(:article, status: :draft)
        create(:article, :archived)

        get articles_path
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json[0]["id"]).to eq(published_article2.id)
        expect(json[1]["id"]).to eq(published_article1.id)
      end
    end
  end

  describe "GET /articles/:id" do
    context "正常系" do
      it "指定した記事の詳細が取得できること" do
        article = create(:article, :published)

        get article_path(article)
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["id"]).to eq(article.id)
        expect(json["title"]).to eq(article.title)
        expect(json["body"]).to eq(article.body)
      end
    end
  end

  describe "POST /articles" do
    context "正常系" do
      it "有効なパラメータで記事が作成できること" do
        valid_params = {
          article: {
            title: "新規記事",
            body: "新規記事の本文",
            status: "draft"
          }
        }

        expect {
          post articles_path, params: valid_params
        }.to change(Article, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["title"]).to eq("新規記事")
        expect(json["body"]).to eq("新規記事の本文")
        expect(json["status"]).to eq("draft")
      end

      it "published状態で作成するとpublished_atが自動設定されること" do
        valid_params = {
          article: {
            title: "公開記事",
            body: "公開記事の本文",
            status: "published"
          }
        }

        post articles_path, params: valid_params
        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["published_at"]).not_to be_nil
      end
    end

    context "異常系" do
      it "タイトルが空の場合エラーが返ること" do
        invalid_params = {
          article: {
            title: "",
            body: "本文",
            status: "draft"
          }
        }

        expect {
          post articles_path, params: invalid_params
        }.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("タイトルを入力してください")
      end

      it "本文が空の場合エラーが返ること" do
        invalid_params = {
          article: {
            title: "タイトル",
            body: "",
            status: "draft"
          }
        }

        expect {
          post articles_path, params: invalid_params
        }.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("本文を入力してください")
      end
    end

    context "境界値" do
      it "タイトルが100文字の場合作成できること" do
        valid_params = {
          article: {
            title: "あ" * 100,
            body: "本文",
            status: "draft"
          }
        }

        expect {
          post articles_path, params: valid_params
        }.to change(Article, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "タイトルが101文字の場合エラーが返ること" do
        invalid_params = {
          article: {
            title: "あ" * 101,
            body: "本文",
            status: "draft"
          }
        }

        expect {
          post articles_path, params: invalid_params
        }.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("タイトルは100文字以内で入力してください")
      end
    end
  end

  describe "PATCH /articles/:id" do
    let(:article) { create(:article) }

    context "正常系" do
      it "記事が更新できること" do
        update_params = {
          article: {
            title: "更新後タイトル",
            body: "更新後本文"
          }
        }

        patch article_path(article), params: update_params
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["title"]).to eq("更新後タイトル")
        expect(json["body"]).to eq("更新後本文")

        article.reload
        expect(article.title).to eq("更新後タイトル")
        expect(article.body).to eq("更新後本文")
      end

      it "ステータスをpublishedに更新するとpublished_atが設定されること" do
        update_params = {
          article: {
            status: "published"
          }
        }

        patch article_path(article), params: update_params
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("published")
        expect(json["published_at"]).not_to be_nil
      end
    end

    context "異常系" do
      it "タイトルを空にするとエラーが返ること" do
        update_params = {
          article: {
            title: ""
          }
        }

        patch article_path(article), params: update_params
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("タイトルを入力してください")

        article.reload
        expect(article.title).not_to eq("")
      end
    end
  end

  describe "DELETE /articles/:id" do
    context "正常系" do
      it "記事が削除できること" do
        article = create(:article)

        expect {
          delete article_path(article)
        }.to change(Article, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
