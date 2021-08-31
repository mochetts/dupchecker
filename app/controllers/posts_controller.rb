class PostsController < ApplicationController

  # GET /posts/new
  def new
    @post = Post.new
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @plain_text = @post.content.to_plain_text
    @dupes = DuplicateFinderService.find_for(@plain_text)
    render :new
  end

  private

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:content)
    end
end
