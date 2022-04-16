defmodule ChessTerm do
  @behaviour Ratatouille.App

  alias Ratatouille.Runtime.Command
  import Ratatouille.View

  @files %{a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8}

  def init(_context) do
    model = %{
      fen: nil,
      theme: %{
        icons: %{
          black_pawn: "♙",
          black_knight: "♘",
          black_bishop: "♗",
          black_rook: "♖",
          black_queen: "♕",
          black_king: "♔",
          white_pawn: "♟",
          white_knight: "♞",
          white_bishop: "♝",
          white_rook: "♜",
          white_queen: "♛",
          white_king: "♚"
        },
        piece_color: :black,
        black_square_color: :blue,
        white_square_color: :white,
        show_legend?: false
      }
    }


    command =
      Command.new(fn -> stream_pop(LichessElixir.TV.feed()) end, :tv_feed_updated)

    {model, command}
  end

  defp stream_pop(stream) do
    # I'd just do [first | rest] if Streams supported that
    first = Stream.take(stream, 1) |> Enum.to_list() |> Enum.at(0)
    rest = Stream.drop(stream, 1)
    {first, rest}
  end

  def update(model, msg) do
    case msg do
      {:tv_feed_updated, {summary, stream}} ->
        model = Map.put(model, :fen, summary["d"]["fen"])

        {model, Command.new(fn -> stream_pop(stream) end, :tv_feed_updated)}
      _ -> model
    end
  end

  def render(model) do
    view do
      panel(title: "chess-term") do
        canvas(height: 9, width: 18) do
          if fen = model[:fen] do
            board(fen: fen, theme: model[:theme])
          else
            board(theme: model[:theme])
          end
        end
      end
    end
  end

  defp board(opts) do
    theme = Keyword.fetch!(opts, :theme)
    board =
      if fen = Keyword.get(opts, :fen) do
        parse_fen(fen)
      else
        %{}
      end

    squares =
      for rank <- 1..8, file <- ~w[a b c d e f g h]a do
        square_coords = to_string(file) <> to_string(rank)

        if Map.has_key?(board, square_coords) do
          piece = Map.fetch!(board, square_coords)
          square(file: file, rank: rank, piece: piece, theme: theme)
        else
          square(file: file, rank: rank, theme: theme)
        end
      end

    if theme.show_legend? do
      [rank_legend(), file_legend()] ++ squares
    else
      squares
    end
  end

  defp parse_fen(fen) do
    String.split(fen, " ")
    |> List.first()
    |> String.split("/")
    |> Enum.with_index(1)
    |> Enum.map(fn {rankfen, rank} -> parse_rankfen(rankfen, rank) end)
    |> Enum.reduce(%{}, fn rank_pieces, board -> Map.merge(board, rank_pieces) end)
  end

  def parse_rankfen(rankfen, rank) do
    {pieces, file_count} =
      Enum.reduce(String.graphemes(rankfen), {%{}, 0}, fn piece_letter, {pieces, current_file} ->
        file_letter = Enum.at(~w[a b c d e f g h], current_file)
        coords = to_string(file_letter) <> to_string(rank)

        case piece_letter do
          "p" -> {Map.put(pieces, coords, :black_pawn), current_file + 1}
          "n" -> {Map.put(pieces, coords, :black_knight), current_file + 1}
          "b" -> {Map.put(pieces, coords, :black_bishop), current_file + 1}
          "r" -> {Map.put(pieces, coords, :black_rook), current_file + 1}
          "q" -> {Map.put(pieces, coords, :black_queen), current_file + 1}
          "k" -> {Map.put(pieces, coords, :black_king), current_file + 1}
          "P" -> {Map.put(pieces, coords, :white_pawn), current_file + 1}
          "N" -> {Map.put(pieces, coords, :white_knight), current_file + 1}
          "B" -> {Map.put(pieces, coords, :white_bishop), current_file + 1}
          "R" -> {Map.put(pieces, coords, :white_rook), current_file + 1}
          "Q" -> {Map.put(pieces, coords, :white_queen), current_file + 1}
          "K" -> {Map.put(pieces, coords, :white_king), current_file + 1}
          n ->
            empty_count = String.to_integer(n)
            {pieces, current_file + empty_count}
        end
      end)

    if file_count != 8 do
      raise "invalid FEN for rank #{rank}: #{rankfen}"
    end

    pieces
  end

  defp rank_legend() do
    for rank <- 1..8 do
      canvas_cell(x: 0, y: 8 - rank, char: to_string(rank))
    end
  end

  defp file_legend() do
    for {letter, file} <- @files do
      canvas_cell(x: file * 2, y: 8, char: to_string(letter))
    end
  end

  defp square(opts) do
    file = Keyword.fetch!(opts, :file)
    rank = Keyword.fetch!(opts, :rank)
    theme = Keyword.fetch!(opts, :theme)

    icon =
      if Keyword.has_key?(opts, :piece) do
        theme.icons[Keyword.fetch!(opts, :piece)]
      else
        " "
      end

    background =
      case square_color(file, rank) do
        :white -> theme.white_square_color
        :black -> theme.black_square_color
      end

    [
      canvas_cell(x: @files[file] * 2, y: 8 - rank, char: icon, color: theme.piece_color, background: background),
      canvas_cell(x: @files[file] * 2 + 1, y: 8 - rank, char: " ", color: theme.piece_color, background: background)
    ]
  end

  defp square_color(file, rank) when file in [:a, :c, :e, :g] and rank in [1, 3, 5, 7], do: :black
  defp square_color(file, rank) when file in [:b, :d, :f, :h] and rank in [2, 4, 6, 8], do: :black
  defp square_color(_, _), do: :white
end
