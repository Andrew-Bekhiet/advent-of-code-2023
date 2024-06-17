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

  def manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  def subtract_dir({x, y}, :up), do: {x, y + 1}
  def subtract_dir({x, y}, :down), do: {x, y - 1}
  def subtract_dir({x, y}, :left), do: {x + 1, y}
  def subtract_dir({x, y}, :right), do: {x - 1, y}
  def subtract_dir({x, y}, _), do: {x, y}

  def rotate180(:up), do: :down
  def rotate180(:down), do: :up
  def rotate180(:left), do: :right
  def rotate180(:right), do: :left
  def rotate180(d), do: d

  @spec dijkstra(Grid.t(), :gb_sets.set(tuple()), tuple(), map()) :: tuple()
  def dijkstra(
        grid = %Grid{},
        pq,
        goal,
        is_part1 \\ true,
        seen \\ MapSet.new()
      ) do
    {{hl, start, same_dir_count, prev_dir}, pq} =
      :gb_sets.take_smallest(pq)

    cond do
      start == goal and (is_part1 or (same_dir_count >= 4 and same_dir_count <= 10)) ->
        {hl, start}

      true ->
        {pq, seen} =
          grid
          |> Grid.get_adjacent_locations(start)
          |> Enum.map(fn l -> {l, new_dir(start, l)} end)
          # |> dbg()
          |> Enum.reject(fn {to, new_dir} ->
            rotate180(new_dir) == prev_dir or
              (new_dir == prev_dir and
                 if(is_part1, do: same_dir_count >= 3, else: same_dir_count >= 11)) or
              seen
              |> MapSet.member?(
                {to, if(new_dir == prev_dir, do: same_dir_count + 1, else: 1), new_dir}
              )
          end)
          |> Enum.reduce({pq, seen}, fn {to, new_dir}, {pq, seen} ->
            new_hl = hl + Grid.at(grid, to)

            cond do
              new_dir == prev_dir ->
                {
                  :gb_sets.insert(
                    {new_hl, to, same_dir_count + 1, new_dir},
                    pq
                  ),
                  seen |> MapSet.put({to, same_dir_count + 1, new_dir})
                }

              is_part1 or (same_dir_count == 0 or (same_dir_count >= 4 and same_dir_count <= 10)) ->
                {
                  :gb_sets.insert({new_hl, to, 1, new_dir}, pq),
                  seen |> MapSet.put({to, 1, new_dir})
                }

              true ->
                {pq, seen}
            end
          end)

        dijkstra(grid, pq, goal, is_part1, seen)
    end
  end

  def reconstruct_path(locations_costs, {start, dir, _}, :infinity) do
    with prev when not is_nil(prev) <- locations_costs |> Map.get(start) do
      Map.merge(reconstruct_path(locations_costs, prev, :infinity), %{start => dir})
    else
      nil -> %{start => dir}
    end
  end

  def reconstruct_path(locations_costs, {start, dir, _}, 0), do: %{}

  def reconstruct_path(locations_costs, {start, dir, _}, n) when is_integer(n) do
    with prev when n > 0 and not is_nil(prev) <- locations_costs |> Map.get(start) do
      Map.merge(reconstruct_path(locations_costs, prev, n - 1), %{start => dir})
    else
      nil -> %{start => dir}
    end
  end

  def part1(use_example) do
    %Grid{width: w, height: h} = grid = parse_input(use_example)

    {hl, _} =
      grid
      |> dijkstra(
        # {hl, start, same_dir_count, prev_dir}
        :gb_sets.singleton({0, {0, 0}, 0, nil}),
        {w - 1, h - 1},
        true
      )

    hl
  end

  def part2(use_example) do
    %Grid{width: w, height: h} = grid = parse_input(use_example)

    {hl, _} =
      grid
      |> dijkstra(
        # {hl, start, same_dir_count, prev_dir}
        :gb_sets.singleton({0, {0, 0}, 0, nil}),
        {w - 1, h - 1},
        false
      )

    hl
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
