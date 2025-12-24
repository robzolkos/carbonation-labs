class LabsController < ApplicationController
  LABS = [
    {
      name: "Board Bootstrap",
      slug: "board-bootstrap",
      description: "Describe what you want to manage and AI will suggest the optimal column structure",
      path: :new_board_bootstrap_path
    },
    {
      name: "Process Extractor",
      slug: "process-extractor",
      description: "Enter a process and AI will research the steps and create a board with cards for each step",
      path: :new_process_extractor_path
    },
    {
      name: "Bulk Board Delete",
      slug: "bulk-board-delete",
      description: "Select multiple boards to delete them in bulk",
      path: :bulk_board_delete_path
    },
    {
      name: "Movie Recommender",
      slug: "movie-recommender",
      description: "Get movie recommendations based on films you love",
      path: :new_movie_recommender_path
    },
    {
      name: "Book Club Generator",
      slug: "book-club-generator",
      description: "Build a reading list from books and genres you enjoy",
      path: :new_book_club_generator_path
    },
    {
      name: "Gift Idea Generator",
      slug: "gift-idea-generator",
      description: "Find perfect gift ideas for anyone",
      path: :new_gift_idea_generator_path
    },
    {
      name: "Restaurant Bucket List",
      slug: "restaurant-bucket-list",
      description: "Discover must-try restaurants in any city",
      path: :new_restaurant_bucket_list_path
    },
    {
      name: "Learning Path Creator",
      slug: "learning-path-creator",
      description: "Create a structured learning plan for any skill",
      path: :new_learning_path_creator_path
    }
  ].freeze

  def index
    @labs = LABS
  end
end
