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
      {x + 1, y},
      {x, y + 1},
      {x - 1, y},
      {x, y - 1}
    ]
    |> Enum.filter(fn {x, y} ->
      x >= 0 and y >= 0 and x < width and
        y < height
    end)
  end

  @spec debug(t(), MapSet.t()) :: String.t()
  def debug(%Grid{data: data}, visited_locations = %{}) do
    data
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(fn {row, y} ->
      row
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        if Map.has_key?(visited_locations, {x, y}) do
          case visited_locations |> Map.get({x, y}) do
            :up -> "↑"
            :down -> "↓"
            :left -> "←"
            :right -> "→"
            _ -> "▪"
          end
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

  def new_dir({x1, y1}, {x2, y2}) when x2 - x1 == 0 and y2 - y1 == 1, do: :down
  def new_dir({x1, y1}, {x2, y2}) when x2 - x1 == 0 and y2 - y1 == -1, do: :up
  def new_dir({x1, y1}, {x2, y2}) when x2 - x1 == 1 and y2 - y1 == 0, do: :right
  def new_dir({x1, y1}, {x2, y2}) when x2 - x1 == -1 and y2 - y1 == 0, do: :left

  @spec dijkstra(Grid.t(), :gb_sets.set(tuple()), tuple(), map()) :: tuple()
  def dijkstra(
        grid = %Grid{},
        locations_costs,
        goal,
        visited_locations \\ %{}
      ) do
    {{hl, dir_len, dir, start, prev}, locations_costs} = :gb_sets.take_smallest(locations_costs)

    visited_locations =
      visited_locations
      |> Map.update(start, {prev, dir, hl}, fn
        {_, _, old_hl} = old when old_hl < hl -> old
        _ -> {prev, dir, hl}
      end)

    path = reconstruct_path(visited_locations, {start, dir, hl}, :infinity)
    IO.puts(grid |> Grid.debug(path))

    dbg(
      {hl,
       path
       |> Map.keys()
       |> Enum.reject(fn
         k when is_nil(k) -> true
         {x, y} -> x == 0 and y == 0
       end)
       |> Enum.map(fn l -> grid |> Grid.at(l) end)
       |> Enum.sum()}
    )

    IO.puts("")
    # path = [start | path]

    # path_length = length(path)

    # if Kernel.rem(path_length, 20) == 0 do
    #   IO.puts(grid |> Grid.debug(path |> MapSet.new()))
    #   IO.puts("")
    # end

    if start == goal do
      {hl, {start, dir, hl}, visited_locations}
    else
      # last_4_steps = path |> Enum.take(4)
      # last_4_steps_len = length(last_4_steps)

      adjacent_locations =
        grid
        |> Grid.get_adjacent_locations(start)
        |> Enum.reject(fn location ->
          # dir_len >= 4 or
          Map.has_key?(visited_locations, location) or
            (dir_len == 3 and new_dir(start, location) == dir)
        end)

      new_locations_costs =
        adjacent_locations
        |> Enum.reduce(locations_costs, fn location, new_locations_costs ->
          if location == {2, 1} and hl == 6 do
            dbg(location_hl = grid |> Grid.at(location))
            dbg(location_hl + hl)
            dbg(new_dir(start, location))
          end

          location_hl = grid |> Grid.at(location)
          new_hl = location_hl + hl

          new_dir = new_dir(start, location)

          # :gb_sets.filter(fn
          #   new_locations_costs)

          :gb_sets.add(
            {new_hl, if(new_dir == dir, do: dir_len + 1, else: 1), new_dir, location, start},
            new_locations_costs
          )
        end)

      dijkstra(grid, new_locations_costs, goal, visited_locations)
    end
  end

  def reconstruct_path(locations_costs, {start, dir, _}, :infinity) do
    with prev when not is_nil(prev) <- locations_costs |> Map.get(start) do
      Map.merge(reconstruct_path(locations_costs, prev, :infinity), %{start => dir})
    else
      nil -> %{start => dir}
    end
  end

  def reconstruct_path(locations_costs, {start, dir, _}, 0), do: []

  def reconstruct_path(locations_costs, {start, dir, _}, n) when is_integer(n) do
    with prev when n > 0 <- locations_costs |> Map.get(start) do
      Map.merge(reconstruct_path(locations_costs, prev, n - 1), %{start => dir})
    else
      nil -> %{start => dir}
    end
  end

  def part1(use_example) do
    %Grid{width: w, height: h} = input = parse_input(use_example)

    {hl, start, visited} =
      dijkstra(
        input,
        :gb_sets.from_list([{0, 0, nil, {0, 0}, nil}]),
        {w - 1, h - 1}
      )

    path = reconstruct_path(visited, start, :infinity)

    IO.puts(inspect(path, pretty: true))
    IO.puts(input |> Grid.debug(path))

    IO.puts(
      path
      |> Map.keys()
      |> Enum.reject(fn
        k when is_nil(k) -> true
        {x, y} -> x == 0 and y == 0
      end)
      |> Enum.map(fn l -> input |> Grid.at(l) end)
      |> Enum.sum()
    )

    hl
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
