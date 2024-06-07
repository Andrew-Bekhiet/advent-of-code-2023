defmodule Grid do
  @type t :: %__MODULE__{
          data: [tuple()],
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

  def debug(%Grid{data: data}, counted_locations = %MapSet{}) do
    data
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(fn {row, y} ->
      row
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        if MapSet.member?(counted_locations, {x, y}) do
          "#"
        else
          cell
        end
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end

defmodule Day16 do
  @mirrors ["-", "|", "/", "\\"]
  @directions [:right, :left, :up, :down]

  def get_new_location({x, y}, :right), do: {x + 1, y}
  def get_new_location({x, y}, :left), do: {x - 1, y}
  def get_new_location({x, y}, :up), do: {x, y - 1}
  def get_new_location({x, y}, :down), do: {x, y + 1}

  def get_new_direction(grid = %Grid{}, current_location = {_x, _y}, direction) do
    new_location =
      Grid.at(
        grid,
        get_new_location(current_location, direction)
      )

    case {new_location, direction} do
      {"-", :right} -> :right
      {"-", :left} -> :left
      {"-", _} -> {:right, :left}
      {"|", :up} -> :up
      {"|", :down} -> :down
      {"|", _} -> {:up, :down}
      {"/", :right} -> :up
      {"/", :down} -> :left
      {"/", :up} -> :right
      {"/", :left} -> :down
      {"\\", :right} -> :down
      {"\\", :down} -> :right
      {"\\", :up} -> :left
      {"\\", :left} -> :up
      _ -> direction
    end
  end

  def walk_counting_from(
        %Grid{width: width},
        location = {x, _},
        :right,
        counted_locations = %MapSet{}
      )
      when x + 1 >= width do
    counted_locations |> MapSet.put({location, :right})
  end

  def walk_counting_from(_, location = {x, _}, :left, counted_locations = %MapSet{})
      when x - 1 < 0 do
    counted_locations |> MapSet.put({location, :left})
  end

  def walk_counting_from(
        %Grid{height: height},
        location = {_, y},
        :down,
        counted_locations = %MapSet{}
      )
      when y + 1 >= height do
    counted_locations |> MapSet.put({location, :down})
  end

  def walk_counting_from(_, location = {_, y}, :up, counted_locations = %MapSet{})
      when y - 1 < 0 do
    counted_locations |> MapSet.put({location, :up})
  end

  def walk_counting_from(
        grid = %Grid{},
        location = {x, y},
        direction,
        counted_locations = %MapSet{}
      )
      when direction in @directions do
    if MapSet.member?(counted_locations, {location, direction}) do
      # IO.puts("Already visited #{inspect(location)} from #{inspect(direction)}")

      counted_locations
    else
      new_counted_locations = MapSet.put(counted_locations, {location, direction})
      new_location = get_new_location(location, direction)

      with {dir1, dir2} <-
             get_new_direction(grid, location, direction) do
        # IO.puts("1: Walking from #{inspect(location)} to #{inspect(new_location)}, #{dir1}")

        result1 =
          walk_counting_from(
            grid,
            new_location,
            dir1,
            new_counted_locations
          )

        # IO.puts("2: Walking from #{inspect(location)} to #{inspect(new_location)}, #{dir2}")

        result2 =
          walk_counting_from(
            grid,
            new_location,
            dir2,
            result1
          )

        result2
      else
        new_direction ->
          # IO.puts(
          #   "Walking from #{inspect(location)} to #{inspect(new_location)}, #{new_direction}"
          # )

          walk_counting_from(
            grid,
            new_location,
            new_direction,
            new_counted_locations
          )
      end
    end
  end

  def part1(use_example) do
    input = parse_input(use_example)

    counted_locations =
      walk_counting_from(
        input,
        {-1, 0},
        :right,
        %MapSet{}
      )
      |> MapSet.new(fn {l, _} -> l end)

    # IO.inspect(counted_locations)

    # Grid.debug(input, counted_locations)
    # |> IO.puts()

    (counted_locations |> MapSet.size()) - 1
  end

  def part2(use_example) do
    input = parse_input(use_example)

    %Grid{width: width, height: height} = input

    vertical =
      0..(width - 1)
      |> Enum.map(fn x ->
        down =
          walk_counting_from(
            input,
            {x, -1},
            :down,
            %MapSet{}
          )
          |> MapSet.new(fn {l, _} -> l end)
          |> MapSet.size()

        up =
          walk_counting_from(
            input,
            {x, height},
            :up,
            %MapSet{}
          )
          |> MapSet.new(fn {l, _} -> l end)
          |> MapSet.size()

        max(down - 1, up - 1)
      end)
      |> Enum.max()

    horizontal =
      0..(height - 1)
      |> Enum.map(fn y ->
        right =
          walk_counting_from(
            input,
            {-1, y},
            :right,
            %MapSet{}
          )
          |> MapSet.new(fn {l, _} -> l end)
          |> MapSet.size()

        left =
          walk_counting_from(
            input,
            {width, y},
            :left,
            %MapSet{}
          )
          |> MapSet.new(fn {l, _} -> l end)
          |> MapSet.size()

        max(right - 1, left - 1)
      end)
      |> Enum.max()

    max(vertical, horizontal)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n", trim: true)

    graphemes =
      data
      |> Enum.map(&String.graphemes/1)
      |> Enum.map(&List.to_tuple/1)
      |> List.to_tuple()

    %Grid{
      data: graphemes,
      height: tuple_size(graphemes),
      width: graphemes |> elem(0) |> tuple_size()
    }
  end
end
