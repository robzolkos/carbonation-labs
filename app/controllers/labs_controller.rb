class LabsController < ApplicationController
  LABS = [
    {
      name: "Board Bootstrap",
      slug: "board-bootstrap",
      description: "Describe what you want to manage and AI will suggest the optimal column structure",
      path: :new_board_bootstrap_path
    }
  ].freeze

  def index
    @labs = LABS
  end
end
