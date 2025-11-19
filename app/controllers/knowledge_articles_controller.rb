class KnowledgeArticlesController < ApplicationController
  before_action :set_article, only: [ :show, :update, :destroy ]

  def index
    @articles = KnowledgeArticle.all

    # Apply filters
    @articles = @articles.by_category(params[:category]) if params[:category].present?
    @articles = @articles.where(status: params[:status]) if params[:status].present?

    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @articles = @articles.where("title ILIKE ? OR content ILIKE ?", search_term, search_term)
    end

    render json: @articles.as_json(
      methods: [ :tags_list, :last_updated_display ]
    )
  end

  def show
    @article.increment_views! unless params[:skip_view_increment] == "true"
    render json: @article.as_json(
      methods: [ :tags_list, :last_updated_display ]
    )
  end

  def create
    @article = KnowledgeArticle.new(article_params)
    if @article.save
      render json: @article.as_json(
        methods: [ :tags_list, :last_updated_display ]
      ), status: :created
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @article.update(article_params)
      render json: @article.as_json(
        methods: [ :tags_list, :last_updated_display ]
      )
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
    @article = KnowledgeArticle.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Article not found" }, status: :not_found
  end

  def article_params
    params.require(:knowledge_article).permit(:title, :content, :category, :author, :status, tags: [])
  end
end
