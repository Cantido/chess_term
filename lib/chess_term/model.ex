defmodule ChessTerm.Model do
  alias ChessTerm.Theme
  use Timex

  def new do
    %{
      fen: nil,
      players: %{
        black: "",
        white: ""
      },
      clock: %{
        black: Duration.zero(),
        white: Duration.zero(),
        since: Timex.now()
      },
      board: %{},
      last_move: nil,
      current_player: :white,
      game_status: "created",
      theme: Theme.new()
    }
  end

  # example message:
  # %{
  #   "t" => "featured",
  #   "d" => %{
  #     "fen" => "6k1/1p3pp1/p1q1p2p/2N1Q3/nP1P4/P5PP/5P1K/8",
  #     "id" => "x3BZnTWt",
  #     "orientation" => "black",
  #     "players" => [
  #       %{"color" => "white", "rating" => 2966, "seconds" => 60, "user" => %{"id" => "yottabyte97", "name" => "Yottabyte97"}},
  #       %{"color" => "black", "rating" => 2974, "seconds" => 60, "user" => %{"id" => "vincentkeymer2004", "name" => "VincentKeymer2004", "title" => "GM"}}
  #     ]
  #   }
  # }
  def update_from_tv(model, %{"t" => "featured"} = summary, now) do
    black = Enum.find(summary["d"]["players"], fn player -> player["color"] == "black" end)
    white = Enum.find(summary["d"]["players"], fn player -> player["color"] == "white" end)

    model
    |> Map.put(:board, parse_fen(summary["d"]["fen"]))
    |> Map.put(:current_player, String.to_existing_atom(summary["d"]["orientation"]))
    |> Map.put(:players, %{
      black: full_player_name(black),
      white: full_player_name(white)
    })
    |> Map.put(:clock, %{
      black: Duration.from_milliseconds(black["seconds"] * 1000),
      white: Duration.from_milliseconds(white["seconds"] * 1000),
      since: now
    })
  end

  # example message:
  # %{
  #   "t" => "fen",
  #   "d" => %{
  #     "wc" => 57,
  #     "bc" => 54,
  #     "fen" => "r1bq1rk1/1ppnppbp/2n3p1/p7/2Pp4/3P1NP1/PPN1PPBP/R1BQ1RK1 w",
  #     "lm" => "a6a5"
  #   }
  # }
  def update_from_tv(model, %{"t" => "fen"} = summary, now) do
    model = Map.put(model, :fen, summary["d"]["fen"])

    current_player =
      summary["d"]["fen"]
      |> String.split(" ")
      |> Enum.at(-1)
      |> case do
        "w" -> :white
        "b" -> :black
      end

    model
    |> Map.put(:board, parse_fen(summary["d"]["fen"]))
    |> Map.put(:current_player, current_player)
    |> Map.put(:last_move, String.split_at(summary["d"]["lm"], 2))
    |> Map.put(:clock, %{
      black: Duration.from_milliseconds(summary["d"]["bc"] * 1000),
      white: Duration.from_milliseconds(summary["d"]["wc"] * 1000),
      since: now
    })
  end

  def update_from_tv(model, _summary, _now) do
    model
  end

  defp full_player_name(player) do
    title =
      if is_nil(player["user"]["title"]) or player["user"]["title"] == ""  do
        ""
      else
        "[" <> player["user"]["title"] <> "] "
      end

    title <> player["user"]["name"] <> " (" <> to_string(player["rating"]) <> ")"
  end


  defp parse_fen(fen) do
    String.split(fen, " ")
    |> List.first()
    |> String.split("/")
    |> Enum.with_index()
    |> Enum.map(fn {rankfen, reverse_rank_index} -> parse_rankfen(rankfen, 8 - reverse_rank_index) end)
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

  def update_clocks(model, now) do
    since_last_update = Timex.diff(now, model.clock.since, :milliseconds) |> Duration.from_milliseconds()

    clock =
      model.clock
      |> Map.update!(model.current_player, &duration_floor(Duration.sub(&1, since_last_update)))
      |> Map.put(:since, now)

    Map.put(model, :clock, clock)
  end

  defp duration_floor(duration) do
    if Duration.to_milliseconds(duration) <= 0 do
      Duration.zero()
    else
      duration
    end
  end
end
