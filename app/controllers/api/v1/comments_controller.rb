module Api
  module V1
    class CommentsController < ApplicationController
      before_action :set_article
      before_action :set_comment, only: %i[destroy]
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      # GET /api/v1/articles/:article_id/comments
      def index
        @comments = @article.comments.order(created_at: :desc)
        render json: @comments
      end

      # POST /api/v1/articles/:article_id/comments
      def create
        @comment = @article.comments.new(comment_params)

        if @comment.save
          render json: @comment, status: :created
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/articles/:article_id/comments/:id
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

      def comment_params
        params.require(:comment).permit(:author_name, :body)
      end

      def render_not_found
        render json: { error: 'Record not found' }, status: :not_found
      end
    end
  end
end
