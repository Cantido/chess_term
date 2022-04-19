defmodule ChessTerm.Theme do
  def new do
    %{
      icons: %{
        white_pawn: "♙",
        white_knight: "♘",
        white_bishop: "♗",
        white_rook: "♖",
        white_queen: "♕",
        white_king: "♔",
        black_pawn: "♟",
        black_knight: "♞",
        black_bishop: "♝",
        black_rook: "♜",
        black_queen: "♛",
        black_king: "♚"
      },
      piece_color: :black,
      black_square_color: :blue,
      white_square_color: :white,
      black_square_highlight_color: :green,
      white_square_highlight_color: :yellow,
      show_legend?: true
    }
  end
end
