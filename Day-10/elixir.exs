defmodule PipeMap do
  @type t :: %__MODULE__{
          data: list(String.t())
        }
  defstruct [:data]

  def at(pipes, {x, y}) do
    Enum.at(pipes.data, y)
    |> String.at(x)
  end

  def east(pipes, {x, y}) do
    at(pipes, {x + 1, y})
  end

  def west(pipes, {x, y}) do
    at(pipes, {x - 1, y})
  end

  def north(pipes, {x, y}) do
    at(pipes, {x, y - 1})
  end

  def south(pipes, {x, y}) do
    at(pipes, {x, y + 1})
  end

  @spec find_start_point(PipeMap.t()) :: {integer(), integer()}
  def find_start_point(%PipeMap{data: data}) do
    y =
      data
      |> Enum.find_index(fn l -> String.contains?(l, "S") end)

    x = find_start_point(Enum.at(data, y))

    {x, y}
  end

  @spec find_start_point(String.t()) :: integer()
  def find_start_point(line) do
    String.graphemes(line)
    |> Enum.find_index(fn char -> char == "S" end)
  end

  def can_go_east(pipes, {x, y}) do
    x + 1 < String.length(Enum.at(pipes.data, y)) and
      ["-", "J", "7", "S"]
      |> Enum.member?(east(pipes, {x, y})) and
      ["-", "L", "F", "S"]
      |> Enum.member?(at(pipes, {x, y}))
  end

  def can_go_west(pipes, {x, y}) do
    x - 1 >= 0 and
      ["-", "L", "F", "S"]
      |> Enum.member?(west(pipes, {x, y})) and
      ["-", "J", "7", "S"]
      |> Enum.member?(at(pipes, {x, y}))
  end

  def can_go_north(pipes, {x, y}) do
    y - 1 >= 0 and
      ["|", "F", "7", "S"]
      |> Enum.member?(north(pipes, {x, y})) and
      ["|", "J", "L", "S"]
      |> Enum.member?(at(pipes, {x, y}))
  end

  def can_go_south(pipes, {x, y}) do
    y + 1 < length(pipes.data) and
      ["|", "J", "L", "S"]
      |> Enum.member?(south(pipes, {x, y})) and
      ["|", "F", "7", "S"]
      |> Enum.member?(at(pipes, {x, y}))
  end
end

defmodule Day10 do
  def part1(use_example) do
    input = parse_input(use_example)

    {x, y} = PipeMap.find_start_point(input)

    loop = trace_single_giant_loop(input, {x, y}, {x, y}, true)

    div(Enum.count(loop), 2)
  end

  def trace_single_giant_loop(
        %PipeMap{data: data} = pipes,
        {x, y} = from,
        {px, py} = prev,
        first_call \\ false
      ) do
    if not first_call and PipeMap.at(pipes, from) == "S" do
      []
    else
      tail =
        cond do
          {x + 1, y} != prev and PipeMap.can_go_east(pipes, from) ->
            IO.puts("Going east (#{x}, #{y})")
            trace_single_giant_loop(pipes, {x + 1, y}, from)

          {x, y + 1} != prev and PipeMap.can_go_south(pipes, from) ->
            IO.puts("Going south (#{x}, #{y})")
            trace_single_giant_loop(pipes, {x, y + 1}, from)

          {x - 1, y} != prev and PipeMap.can_go_west(pipes, from) ->
            IO.puts("Going west (#{x}, #{y})")
            trace_single_giant_loop(pipes, {x - 1, y}, from)

          {x, y - 1} != prev and PipeMap.can_go_north(pipes, from) ->
            IO.puts("Going north (#{x}, #{y})")
            trace_single_giant_loop(pipes, {x, y - 1}, from)
        end

      [from | tail]
    end
  end

  def part2(use_example) do
    input = parse_input(use_example)

    {x, y} = PipeMap.find_start_point(input)

    loop = trace_single_giant_loop(input, {x, y}, {x, y}, true)

    input.data
    |> Enum.with_index()
    |> Enum.reduce(0, fn {line, y}, acc ->
      xs_on_line =
        loop
        |> Enum.filter(fn {_, py} -> py == y end)
        |> Enum.map(fn {x, _} -> x end)
        |> Enum.sort()

      count = count_inner_tiles(line, xs_on_line)

      IO.puts("Line #{y} has #{count}")

      acc + count
    end)
  end

  @spec count_inner_tiles(String.t(), list(integer())) :: integer()
  def count_inner_tiles(line, xs_on_line) do
    {count, _, _} =
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce({0, false, nil}, fn {char, x}, {count, is_inside, last_boundary} ->
        # IO.puts("is_inside: #{is_inside}, char: #{char}, x: #{x}, count: #{count}")

        cond do
          is_boundary(char) and
            Enum.member?(xs_on_line, x) and
              (x < 1 or
                 not form_boundary?(last_boundary, char)) ->
            # IO.puts("Found boundary at #{x}")
            {count, not is_inside, char}

          is_inside and
              not Enum.member?(xs_on_line, x) ->
            # IO.puts("Found inner tile at #{x}")
            {count + 1, is_inside, last_boundary}

          true ->
            {count, is_inside, last_boundary}
        end
      end)

    count
  end

  def is_boundary(char) do
    ["|", "J", "L", "F", "7", "S"]
    |> Enum.member?(char)
  end

  def form_boundary?(char1, char2) do
    (char1 == "L" and char2 == "7") or
      (char1 == "F" and char2 == "J") or
      (char1 == "S" and char2 == "J")
  end

  def print_clean_map(map, loop) do
    map.data
    |> Enum.with_index()
    |> Enum.each(fn {line, y} ->
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.each(fn {char, x} ->
        if Enum.member?(loop, {x, y}) do
          IO.write(char)
        else
          IO.write(" ")
        end
      end)

      IO.write("\n")
    end)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n", trim: true)

    %PipeMap{data: data}
  end
end
