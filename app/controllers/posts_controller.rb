class PostsController < ApplicationController

  # GET /posts/new
  def new
    @post = Post.new
  end

  # POST /posts
  def create
    dupes = DuplicateFinderService.find_for(post_params[:content])
  end

  private

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:content)
    end
end
