module Api
  module V1
    class ArticlesController < ApplicationController
      before_action :authenticate_user!, only: %i[create update destroy]
      before_action :set_article, only: %i[show update destroy]
      before_action :authorize_user!, only: %i[update destroy]
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      # GET /api/v1/articles
      def index
        @articles = Article.where(status: :published).order(published_at: :desc)
        render json: @articles
      end

      # GET /api/v1/articles/:id
      def show
        render json: @article
      end

      # POST /api/v1/articles
      def create
        @article = current_user.articles.new(article_params)

        if @article.save
          render json: @article, status: :created
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/articles/:id
      def update
        if @article.update(article_params)
          render json: @article
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/articles/:id
      def destroy
        @article.destroy
        head :no_content
      end

      private

      def set_article
        @article = Article.find(params[:id])
      end

      def article_params
        params.require(:article).permit(:title, :body, :status, :published_at)
      end

      def authorize_user!
        unless @article.user_id == current_user.id
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end

      def render_not_found
        render json: { error: 'Record not found' }, status: :not_found
      end
    end
  end
end
