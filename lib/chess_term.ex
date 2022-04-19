defmodule ChessTerm do
  @behaviour Ratatouille.App

  alias ChessTerm.Model
  alias Ratatouille.Runtime.Command
  alias Ratatouille.Runtime.Subscription
  import Ratatouille.View
  use Timex
  require Logger

  @files %{a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8}

  def init(_context) do
    Logger.debug("initializing chess_term")
    model = Model.new()

    command =
      Command.new(fn -> stream_pop(LichessElixir.TV.feed()) end, :tv_feed_updated)

    {model, command}
  end

  def subscribe(_model) do
    Subscription.interval(100, :update_clocks)
  end

  defp stream_pop(stream) do
    # I'd just do [first | rest] if Streams supported that
    first = Stream.take(stream, 1) |> Enum.at(0)
    Logger.debug("Popped from stream: #{inspect first}")
    rest = Stream.drop(stream, 1)

    {first, rest}
  end

  def update(model, msg) do
    case msg do
      {:tv_feed_updated, {summary, stream}} ->
        Logger.debug("Updating from TV feed with message: #{inspect(summary)}")

        model = Model.update_from_tv(model, summary, Timex.now())

        {model, Command.new(fn -> stream_pop(stream) end, :tv_feed_updated)}
      :update_clocks ->
        Model.update_clocks(model, Timex.now())
      _ -> model
    end
  end


  def render(model) do
    view do
      row do
        column(size: 6) do
          canvas(height: 9, width: 18) do
            if model[:last_move] do
              board(board: model[:board], theme: model[:theme], highlight: Tuple.to_list(model[:last_move]))
            else
              board(board: model[:board], theme: model[:theme])
            end
          end
        end
        column(size: 6) do
          label()
          label do
            time(duration: model.clock.black, active: model.current_player == :black)
          end
          label(content: model.players.black)
          label()
          label()
          label do
            time(duration: model.clock.white, active: model.current_player == :white)
          end
          label(content: model.players.white)
          label()
        end
        column(size: 8)
      end
    end
  end

  defp time(opts) do
    duration = Keyword.fetch!(opts, :duration)
    active? = Keyword.get(opts, :active, false)

    total_seconds = Duration.to_seconds(duration, truncate: true)
    minutes = div(total_seconds, 60) |> to_string() |> String.pad_leading(2, "0")
    seconds = rem(total_seconds, 60) |> to_string() |> String.pad_leading(2, "0")

    content = minutes <> ":" <> seconds

    if active? do
      text(content: content, background: :white, color: :black)
    else
      text(content: content)
    end
  end

  defp board(opts) do
    theme = Keyword.fetch!(opts, :theme)
    board = Keyword.get(opts, :board, %{})
    highlight = Keyword.get(opts, :highlight, [])

    squares =
      for rank <- 1..8, file <- ~w[a b c d e f g h]a do
        square_coords = to_string(file) <> to_string(rank)
        highlight? = square_coords in highlight

        if Map.has_key?(board, square_coords) do
          piece = Map.fetch!(board, square_coords)
          square(file: file, rank: rank, piece: piece, theme: theme, highlight: highlight?)
        else
          square(file: file, rank: rank, theme: theme, highlight: highlight?)
        end
      end

    if theme.show_legend? do
      [rank_legend(), file_legend()] ++ squares
    else
      squares
    end
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
    highlight? = Keyword.get(opts, :highlight, false)

    icon =
      if Keyword.has_key?(opts, :piece) do
        theme.icons[Keyword.fetch!(opts, :piece)]
      else
        " "
      end

    background =
      case {square_color(file, rank), highlight?} do
        {:white, false} -> theme.white_square_color
        {:white, true} -> theme.white_square_highlight_color
        {:black, false} -> theme.black_square_color
        {:black, true} -> theme.black_square_highlight_color
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
