require IEx

defmodule Grid do
  @type t :: %__MODULE__{
          data: [[integer()]],
          height: integer(),
          width: integer()
        }
  defstruct [:data, :height, :width]

  @spec at(t(), {integer(), integer()}) :: String.t()
  def at(grid, {x, y}) do
    grid.data
    |> elem(y)
    |> elem(x)
  end

  @spec get_adjacent_locations(t(), {integer(), integer()}) :: [{integer(), integer()}]
  def get_adjacent_locations(%Grid{width: width, height: height}, {x, y}) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.filter(fn {x, y} ->
      x >= 0 and y >= 0 and x < height and y < width
    end)
  end

  @spec debug(t(), MapSet.t()) :: String.t()
  def debug(%Grid{data: data}, visited_locations = %MapSet{}) do
    data
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(fn {row, y} ->
      row
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        if MapSet.member?(visited_locations, {x, y}) do
          "▪"
        else
          cell
        end
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end

defmodule Day17 do
  def is_straight_line?([{x1, y1} | [{x2, y2}]]) do
    abs(x1 - x2) + abs(y1 - y2) == 1
  end

  def is_straight_line?(path) when is_list(path) do
    {x1, y1} = path |> List.first()
    {xl, yl} = path |> List.last()

    l = length(path)

    (x1 == xl and abs(y1 - yl) == l - 1) or
      (y1 == yl and abs(x1 - xl) == l - 1)
  end

  @spec dijkstra(Grid.t(), tuple(), tuple(), map(), MapSet.t()) :: nil | map()
  def dijkstra(
        grid = %Grid{},
        start,
        goal,
        locations_costs \\ %{},
        visited_locations \\ %MapSet{}
      ) do
    # dbg()
    visited_locations = visited_locations |> MapSet.put(start)

    case do_dijkstra(grid, start, goal, locations_costs, visited_locations) do
      {false, locations_costs} ->
        IO.puts("{false, locations_costs}")
        # dbg()

        {min_start, _} =
          locations_costs
          |> Enum.reject(fn {l, _} -> MapSet.member?(visited_locations, l) end)
          |> Enum.sort_by(fn {_, {hl, _}} -> hl end)
          |> Enum.at(1)

        IO.puts(inspect(min_start, pretty: true))

        if is_nil(min_start) do
          IO.puts("min start is nil")
          nil
        else
          dijkstra(grid, min_start, goal, locations_costs, visited_locations)
        end

      {true, locations_costs} ->
        IO.puts("{true, locations_costs}")
        locations_costs

      new_locations_costs ->
        IO.puts(
          grid
          |> Grid.debug(reconstruct_path(new_locations_costs, start, :infinity) |> MapSet.new())
        )

        IO.puts("")

        # IO.puts(inspect({visited_locations, new_locations_costs}, pretty: true))

        {min_start, _} =
          new_locations_costs
          |> Enum.reject(fn {l, _} -> MapSet.member?(visited_locations, l) end)
          |> Enum.min_by(fn {_, {hl, _}} -> hl end, fn -> {nil, {nil, nil}} end)

        IO.puts(inspect(min_start, pretty: true))

        if is_nil(min_start) do
          IO.puts("min start is nil")
          nil
        else
          dijkstra(grid, min_start, goal, new_locations_costs, visited_locations)
        end
    end
  end

  @spec do_dijkstra(Grid.t(), tuple(), tuple(), map(), MapSet.t()) :: {true, map()}

  def do_dijkstra(
        grid = %Grid{},
        start,
        goal,
        locations_costs = %{},
        visited_locations = %MapSet{}
      ) do
    if start == goal do
      {true, locations_costs}
    else
      last_3_steps = reconstruct_path(locations_costs, start, 3)

      adjacent_locations =
        grid
        |> Grid.get_adjacent_locations(start)
        |> Enum.reject(fn l -> MapSet.member?(visited_locations, l) end)
        |> Enum.reject(fn l ->
          Enum.count(last_3_steps) >= 3 and [l | last_3_steps] |> is_straight_line?()
        end)

      # |> dbg()

      if Enum.empty?(adjacent_locations) do
        {false, locations_costs}
      else
        adjacent_locations
        |> Enum.reduce(locations_costs, fn l, locations_costs ->
          hl = Grid.at(grid, l)

          {start_hl, _} = locations_costs |> Map.get(start, {0, nil})

          new_hl = hl + start_hl

          locations_costs
          |> Map.update(l, {new_hl, start}, fn
            {old, _} when new_hl < old -> {new_hl, start}
            old -> old
          end)
        end)
      end
    end
  end

  def reconstruct_path(locations_costs, start, :infinity) do
    with {_, prev} <- locations_costs |> Map.get(start) do
      [start | reconstruct_path(locations_costs, prev, :infinity)]
    else
      nil -> [start]
    end
  end

  def reconstruct_path(locations_costs, start, 0), do: []

  def reconstruct_path(locations_costs, start, n) when is_integer(n) do
    with {_, prev} when n > 0 <- locations_costs |> Map.get(start) do
      [start | reconstruct_path(locations_costs, prev, n - 1)]
    else
      nil -> [start]
    end
  end

  def part1(use_example) do
    # dbg()
    %Grid{width: w, height: h} = input = parse_input(use_example)

    result = dijkstra(input, {0, 0}, {w - 1, h - 1})

    # dbg()
    path = reconstruct_path(result, {w - 1, h - 1}, :infinity)

    IO.puts(inspect(result, pretty: true))
    IO.puts(input |> Grid.debug(path |> MapSet.new()))
    IO.puts(inspect(path))

    result |> Map.get({w - 1, h - 1})
  end

  def part2(use_example) do
    _input = parse_input(use_example)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n", trim: true)

    graphemes =
      data
      |> Enum.map(fn x ->
        x
        |> String.graphemes()
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end)
      |> List.to_tuple()

    %Grid{
      data: graphemes,
      height: tuple_size(graphemes),
      width: graphemes |> elem(0) |> tuple_size()
    }
  end
end

# IEx.pry()
# IEx.break!(Day17, :part1, 1)
# Day17.part1(true)

# Day17.part1(true) |> dbg()
