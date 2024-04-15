defmodule Grid do
  @type t :: %__MODULE__{
          data: list(String.t())
        }
  defstruct [:data]

  def at(grid, {x, y}) do
    grid.data
    |> Enum.at(y)
    |> String.graphemes()
    |> Enum.at(x)
  end

  def rotate_90(_ = %Grid{data: data}) do
    height = length(data)
    width = data |> Enum.at(0) |> String.length()

    new_data =
      (width - 1)..0
      |> Enum.map(fn i ->
        0..(height - 1)
        |> Enum.map(fn j ->
          data
          |> Enum.at(j)
          |> String.at(i)
        end)
        |> Enum.join()
      end)

    %Grid{data: new_data}
  end

  def print(_ = %Grid{data: data}) do
    data
    |> Enum.join("\n")
    |> IO.puts()

    IO.puts("\n")
  end

  @spec tilt(Grid.t(), :north | :south | :east | :west) :: Grid.t()

  # up
  def tilt(grid = %Grid{}, dir) when is_atom(dir) and dir == :north do
    grid
    |> rotate_90()
    |> tilt(:west)
    |> rotate_90()
    |> rotate_90()
    |> rotate_90()
  end

  # down
  def tilt(grid = %Grid{}, dir) when is_atom(dir) and dir == :south do
    grid
    |> rotate_90()
    |> rotate_90()
    |> rotate_90()
    |> tilt(:west)
    |> rotate_90()
  end

  # right
  def tilt(grid = %Grid{}, dir) when is_atom(dir) and dir == :east do
    grid
    |> rotate_90()
    |> rotate_90()
    |> tilt(:west)
    |> rotate_90()
    |> rotate_90()
  end

  # left
  def tilt(_ = %Grid{data: data}, dir) when is_atom(dir) and dir == :west do
    # print(grid)

    new_data =
      data
      |> Enum.map(fn line ->
        line
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.reduce({-1, []}, fn {char, i}, {rock_index, acc} ->
          cond do
            char == "#" ->
              {i, [char | acc]}

            char == "O" and rock_index + 1 == i ->
              {i, [char | acc]}

            char == "O" ->
              {rock_index + 1,
               [
                 "."
                 | acc
                   |> Enum.reverse()
                   |> List.replace_at(rock_index + 1, char)
                   |> Enum.reverse()
               ]}

            true ->
              {rock_index, [char | acc]}
          end
        end)
      end)
      |> Enum.map(fn {_, chars} ->
        chars
        |> Enum.reverse()
        |> Enum.join()
      end)

    %Grid{data: new_data}
  end
end

defmodule Day14 do
  def calc_load(_ = %Grid{data: data}) do
    height = length(data)

    data
    |> Enum.with_index()
    |> Enum.map(fn {line, i} ->
      line
      |> String.graphemes()
      |> Enum.count(&(&1 == "O"))
      |> Kernel.*(height - i)
    end)
    |> Enum.sum()
  end

  def part1(use_example) do
    input = parse_input(use_example)

    input
    |> Grid.tilt(:north)
    |> calc_load()
  end

  def part2(use_example) do
    input = parse_input(use_example)

    cycles = 1_000_000_000

    grid =
      1..cycles
      |> Enum.reduce_while({input, %{input => 0}}, fn i, {grid, memo} ->
        new_grid =
          grid
          |> Grid.tilt(:north)
          |> Grid.tilt(:west)
          |> Grid.tilt(:south)
          |> Grid.tilt(:east)

        if memo |> Map.has_key?(new_grid) do
          base_index = memo |> Map.fetch!(new_grid)
          multiplier = i - base_index

          normalized_target = cycles - base_index
          memo_index = rem(normalized_target, multiplier) + base_index

          # IO.puts(inspect({i, base_index, multiplier, normalized_target, memo_index}))

          {final_grid, _} =
            memo
            |> Map.filter(fn {_, v} -> v == memo_index end)
            |> Map.to_list()
            |> List.first()

          {:halt, final_grid}
        else
          {:cont, {new_grid, memo |> Map.put_new(new_grid, i)}}
        end
      end)

    grid |> calc_load()
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    %Grid{
      data:
        File.read!(filename)
        |> String.split("\n", trim: true)
    }
  end
end
