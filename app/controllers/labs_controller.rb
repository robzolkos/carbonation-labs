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
    }
  ].freeze

  def index
    @labs = LABS
  end
end
