require "test_helper"

class KnowledgeArticleTest < ActiveSupport::TestCase
  def setup
    @article = KnowledgeArticle.new(
      title: "How to Reset Your Password",
      content: "Step-by-step guide for password reset.",
      category: "account",
      status: "published"
    )
  end

  # ── Validity ──────────────────────────────────────────────────────────────
  test "should be valid with valid attributes" do
    assert @article.valid?
  end

  # ── Presence validations ──────────────────────────────────────────────────
  test "should require title" do
    @article.title = nil
    assert_not @article.valid?
    assert_includes @article.errors[:title], "can't be blank"
  end

  # ── Inclusion validations ─────────────────────────────────────────────────
  test "should reject invalid status" do
    @article.status = "hidden"
    assert_not @article.valid?
    assert_includes @article.errors[:status], "is not included in the list"
  end

  test "should accept all valid statuses" do
    %w[draft published archived].each do |s|
      @article.status = s
      assert @article.valid?, "#{s} should be valid"
    end
  end

  # ── Scopes ────────────────────────────────────────────────────────────────
  test "published scope returns published articles" do
    @article.status = "published"
    @article.save!
    draft = KnowledgeArticle.create!(title: "Draft Article", status: "draft")
    assert_includes KnowledgeArticle.published, @article
    assert_not_includes KnowledgeArticle.published, draft
  end

  test "draft scope returns draft articles" do
    @article.status = "draft"
    @article.save!
    assert_includes KnowledgeArticle.draft, @article
  end

  test "archived scope returns archived articles" do
    @article.status = "archived"
    @article.save!
    assert_includes KnowledgeArticle.archived, @article
  end

  test "by_category scope filters by category" do
    @article.save!
    other = KnowledgeArticle.create!(title: "Network Guide", category: "network", status: "published")
    assert_includes KnowledgeArticle.by_category("account"), @article
    assert_not_includes KnowledgeArticle.by_category("account"), other
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  test "tags_list returns empty array when blank" do
    @article.tags = nil
    assert_equal [], @article.tags_list
  end

  test "tags_list parses comma-separated tags" do
    @article.tags = "account, password, security"
    @article.save!
    assert_includes @article.tags_list, "account"
    assert_includes @article.tags_list, "password"
    assert_equal 3, @article.tags_list.length
  end

  test "tags_list parses JSON array tags" do
    @article.tags = '["account", "password"]'
    @article.save!
    assert_equal %w[account password], @article.tags_list
  end

  test "tags_list= stores comma-separated string for arrays" do
    @article.tags_list = %w[vip urgent]
    assert_equal "vip, urgent", @article.tags
  end

  test "increment_views! increments the views counter" do
    @article.save!
    initial = @article.views.to_i
    @article.increment_views!
    assert_equal initial + 1, @article.reload.views.to_i
  end

  test "increment_helpful! increments the helpful counter" do
    @article.save!
    initial = @article.helpful.to_i
    @article.increment_helpful!
    assert_equal initial + 1, @article.reload.helpful.to_i
  end

  test "last_updated_display returns formatted date" do
    @article.save!
    assert_not_nil @article.last_updated_display
    assert_match(/\A\w+ \d{1,2}, \d{4}\z/, @article.last_updated_display)
  end

  # ── Callback: updates last_updated on content change ─────────────────────
  test "updates last_updated when content changes" do
    @article.save!
    old_last_updated = @article.last_updated
    @article.update!(content: "Updated content here.")
    assert_not_nil @article.reload.last_updated
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────
  test "should create knowledge article" do
    assert_difference("KnowledgeArticle.count") { @article.save! }
  end

  test "should update knowledge article" do
    @article.save!
    @article.update!(title: "Updated Guide")
    assert_equal "Updated Guide", @article.reload.title
  end

  test "should destroy knowledge article" do
    @article.save!
    assert_difference("KnowledgeArticle.count", -1) { @article.destroy }
  end
end
