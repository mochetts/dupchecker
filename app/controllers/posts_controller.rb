class PostsController < ApplicationController

  # GET /posts/new
  def new
    @post = Post.new
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @dupes = DuplicateFinderService.new(@post.content.to_plain_text).perform
    render :new
  end

  private

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:content)
    end
end
