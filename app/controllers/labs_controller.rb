class LabsController < ApplicationController
  CATEGORIES = [
    { key: :board_builders, name: "Board Builders", description: "Turn ideas into structured boards" },
    { key: :board_management, name: "Board Management", description: "Utilities for working with existing boards" },
    { key: :recommendations, name: "Recommendations", description: "Discover and create curated lists" },
    { key: :learning, name: "Learning", description: "Study guides and educational resources" },
    { key: :games, name: "Games", description: "Interactive activities and fun" }
  ].freeze

  LABS = [
    {
      name: "Board Bootstrap",
      slug: "board-bootstrap",
      description: "Describe what you want to manage and get the optimal column structure",
      path: :new_board_bootstrap_path,
      category: :board_builders,
      icon: :columns
    },
    {
      name: "Process Extractor",
      slug: "process-extractor",
      description: "Enter a process to get a board with cards for each step",
      path: :new_process_extractor_path,
      category: :board_builders,
      icon: :workflow
    },
    {
      name: "CSV to Board",
      slug: "csv-to-board",
      description: "Turn spreadsheet data into cards instantly",
      path: :new_csv_to_board_path,
      category: :board_builders,
      icon: :table
    },
    {
      name: "Email to Tasks",
      slug: "email-to-tasks",
      description: "Extract action items from emails and messages",
      path: :new_email_to_tasks_path,
      category: :board_builders,
      icon: :mail
    },
    {
      name: "Board Copier",
      slug: "board-copier",
      description: "Copy all columns and cards from one board to another",
      path: :new_board_copier_path,
      category: :board_management,
      icon: :copy
    },
    {
      name: "Bulk Board Delete",
      slug: "bulk-board-delete",
      description: "Select multiple boards to delete them in bulk",
      path: :bulk_board_delete_path,
      category: :board_management,
      icon: :trash
    },
    {
      name: "Board Merger",
      slug: "board-merger",
      description: "Combine all cards from one board into another",
      path: :new_board_merger_path,
      category: :board_management,
      icon: :merge
    },
    {
      name: "Card Mover",
      slug: "card-mover",
      description: "Copy cards from multiple boards into one",
      path: :new_card_mover_path,
      category: :board_management,
      icon: :move
    },
    {
      name: "Movie Recommender",
      slug: "movie-recommender",
      description: "Get movie recommendations based on films you love",
      path: :new_movie_recommender_path,
      category: :recommendations,
      icon: :film
    },
    {
      name: "Book Club Generator",
      slug: "book-club-generator",
      description: "Build a reading list from books and genres you enjoy",
      path: :new_book_club_generator_path,
      category: :recommendations,
      icon: :book
    },
    {
      name: "Gift Idea Generator",
      slug: "gift-idea-generator",
      description: "Find perfect gift ideas for anyone",
      path: :new_gift_idea_generator_path,
      category: :recommendations,
      icon: :gift
    },
    {
      name: "Restaurant Bucket List",
      slug: "restaurant-bucket-list",
      description: "Discover must-try restaurants in any city",
      path: :new_restaurant_bucket_list_path,
      category: :recommendations,
      icon: :utensils
    },
    {
      name: "Trip Planner",
      slug: "trip-planner",
      description: "Get a day-by-day itinerary for your next adventure",
      path: :new_trip_planner_path,
      category: :recommendations,
      icon: :map_pin
    },
    {
      name: "Homework Coach",
      slug: "homework-coach",
      description: "Get step-by-step help with topics you're struggling with",
      path: :new_homework_coach_path,
      category: :learning,
      icon: :lifebuoy
    },
    {
      name: "Learning Path Creator",
      slug: "learning-path-creator",
      description: "Create a structured learning plan for any skill",
      path: :new_learning_path_creator_path,
      category: :learning,
      icon: :graduation
    },
    {
      name: "Movie Quiz Generator",
      slug: "movie-quiz-generator",
      description: "Generate movie trivia questions with team scoring for quiz night",
      path: :new_movie_quiz_generator_path,
      category: :games,
      icon: :target
    },
    {
      name: "Party Prompts",
      slug: "party-prompts",
      description: "Generate prompts for Charades, Pictionary, or both",
      path: :new_party_prompts_path,
      category: :games,
      icon: :drama
    }
  ].freeze

  def index
    @categories = CATEGORIES
    @labs_by_category = LABS.group_by { |lab| lab[:category] }
  end
end
