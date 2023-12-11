defmodule Universe do
  @type t :: %__MODULE__{
          data: list(String.t())
        }
  defstruct [:data]

  @spec find_galaxies(Universe.t()) :: list({integer(), integer()})
  def find_galaxies(universe_map) do
    universe_map.data
    |> Enum.with_index()
    |> Enum.map(fn {line, y} ->
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {char, x} ->
        if char == "#" do
          {x, y}
        else
          nil
        end
      end)
      |> Enum.filter(fn p -> p != nil end)
    end)
    |> List.flatten()
  end
end

defmodule Day11 do
  def part1(use_example) do
    input = parse_input(use_example)

    galaxies = Universe.find_galaxies(input)

    expanded_map =
      input
      |> expand_horizontally(galaxies)
      |> expand_vertically(galaxies)

    new_galaxies = Universe.find_galaxies(expanded_map)

    galaxies_pairs = galaxies_pairs(new_galaxies)

    galaxies_pairs
    |> Enum.map(fn {{x1, y1}, {x2, y2}} ->
      r = abs(x2 - x1) + abs(y2 - y1)
      IO.puts("{#{x1}, #{y1}} -> {#{x2}, #{y2}}: #{r}")
      r
    end)
    |> Enum.sum()
  end

  def galaxies_pairs(galaxies) do
    if length(galaxies) <= 1 do
      []
    else
      g1 = Enum.at(galaxies, 0)
      galaxies_tail = Enum.slice(galaxies, 1, length(galaxies) - 1)

      pairs =
        galaxies_tail
        |> Enum.map(fn g2 -> {g1, g2} end)

      # IO.puts(inspect(pairs))
      pairs ++ galaxies_pairs(galaxies_tail)
    end
  end

  def expand_horizontally(universe, galaxies, expansion_factor \\ 2) do
    xs = Enum.map(galaxies, fn {x, _} -> x end)

    universe.data
    |> Enum.map(fn line ->
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {char, x} ->
        if Enum.member?(xs, x) do
          char
        else
          String.duplicate(char, expansion_factor)
        end
      end)
      |> Enum.join()
    end)
    |> then(&%Universe{data: &1})
  end

  def expand_vertically(universe, galaxies, expansion_factor \\ 2) do
    ys = Enum.map(galaxies, fn {_, y} -> y end)

    universe.data
    |> Enum.with_index()
    |> Enum.map(fn {line, y} ->
      if Enum.member?(ys, y) do
        [line]
      else
        List.duplicate(line, expansion_factor)
      end
    end)
    |> List.flatten()
    |> then(&%Universe{data: &1})
  end

  def part2(use_example, expansion_factor \\ 1_000_000) do
    input = parse_input(use_example)

    galaxies = Universe.find_galaxies(input)

    galaxies_pairs = galaxies_pairs(galaxies)

    unique_xs = galaxies |> Enum.map(fn {x, _} -> x end) |> Enum.uniq()
    unique_ys = galaxies |> Enum.map(fn {_, y} -> y end) |> Enum.uniq()

    galaxies_pairs
    |> Enum.map(fn {{x1, y1}, {x2, y2}} ->
      g_between_x = Enum.count(unique_xs, fn x -> x > min(x1, x2) and x <= max(x1, x2) end)
      g_between_y = Enum.count(unique_ys, fn y -> y > min(y1, y2) and y <= max(y1, y2) end)

      distance_x = abs(x2 - x1)
      distance_y = abs(y2 - y1)

      r =
        expansion_factor * (distance_x - g_between_x + distance_y - g_between_y) + g_between_x +
          g_between_y

      IO.puts("{#{x1}, #{y1}} -> {#{x2}, #{y2}}: #{r}")

      IO.puts(
        "distance_x: #{distance_x}, g_between_x: #{g_between_x}, distance_y: #{distance_y}, g_between_y: #{g_between_y}"
      )

      r
    end)
    |> Enum.sum()
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n", trim: true)

    %Universe{data: data}
  end
end
