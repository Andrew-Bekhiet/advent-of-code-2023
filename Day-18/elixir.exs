defmodule Instruction do
  @type t :: %__MODULE__{
          direction: String.t(),
          distance: integer(),
          color: integer()
        }

  defstruct [:direction, :distance, :color]
end

defmodule InstructionsSet do
  @type t :: %__MODULE__{
          instructions: list(Instruction.t()),
          vertices: list(tuple()),
          borders: list(tuple()),
          width: integer(),
          height: integer(),
          max: {integer(), integer()},
          min: {integer(), integer()}
        }

  defstruct [
    :instructions,
    :vertices,
    :borders,
    :width,
    :height,
    :max,
    :min
  ]

  def new(instructions) do
    vertices = get_vertices(instructions)

    {min_x, max_x} =
      vertices
      |> Enum.map(fn {x, _y} -> x end)
      |> Enum.min_max()

    {min_y, max_y} =
      vertices
      |> Enum.map(fn {_x, y} -> y end)
      |> Enum.min_max()

    %InstructionsSet{
      instructions: instructions,
      vertices: vertices,
      borders: connect_vertices(vertices),
      width: max_x - min_x + 1,
      height: max_y - min_y + 1,
      max: {max_x, max_y},
      min: {min_x, min_y}
    }
  end

  def get_vertices(instructions) when is_list(instructions) do
    instructions
    |> Enum.reduce({[], {0, 0}}, fn instruction, {acc, {last_x, last_y}} ->
      d = instruction.distance

      next_point =
        case instruction.direction do
          "U" -> {last_x, last_y - d}
          "D" -> {last_x, last_y + d}
          "L" -> {last_x - d, last_y}
          "R" -> {last_x + d, last_y}
        end

      {[next_point | acc], next_point}
    end)
    |> elem(0)
  end

  def connect_vertices(vertices) when is_list(vertices) do
    vertices
    |> Enum.flat_map_reduce(vertices |> List.last(), fn {x, y}, {prev_x, prev_y} ->
      result =
        if x == prev_x do
          direction = if(y - prev_y > 0, do: 1, else: -1)

          prev_y..(y - direction)
          |> Enum.map(fn y -> {x, y} end)
        else
          direction = if(x - prev_x > 0, do: 1, else: -1)

          prev_x..(x - direction)
          |> Enum.map(fn x -> {x, y} end)
        end

      {result, {x, y}}
    end)
    |> elem(0)
  end

  defp border_like?(%MapSet{} = borders, {x1, y1}, {x2, y2}) do
    # Checks p1 is L
    # and p2 is 7
    # or p1 is F
    # and p2 is J
    (MapSet.member?(borders, {x1 + 1, y1}) and MapSet.member?(borders, {x1, y1 - 1}) and
       MapSet.member?(borders, {x2 - 1, y2}) and MapSet.member?(borders, {x2, y2 + 1})) or
      (MapSet.member?(borders, {x1 + 1, y1}) and MapSet.member?(borders, {x1, y1 + 1}) and
         MapSet.member?(borders, {x2 - 1, y2}) and MapSet.member?(borders, {x2, y2 - 1}))
  end

  def calc_area(%InstructionsSet{
        borders: b,
        vertices: v,
        min: {min_x, min_y},
        max: {max_x, max_y}
      }) do
    borders = MapSet.new(b)
    vertices = MapSet.new(v)

    min_y..max_y
    |> Enum.map(fn y ->
      min_x..max_x
      |> Enum.map(fn x -> {x, y} end)
      |> Enum.reduce({0, false, nil}, fn {x, y} = p, {count, is_inside, last_vertex} ->
        cond do
          MapSet.member?(vertices, p) and
              (is_nil(last_vertex) or not border_like?(borders, last_vertex, p)) ->
            {count + 1, not is_inside, p}

          MapSet.member?(borders, p) and not MapSet.member?(borders, {x - 1, y}) and
              not MapSet.member?(borders, {x + 1, y}) ->
            {count + 1, not is_inside, last_vertex}

          MapSet.member?(borders, p) ->
            {count + 1, is_inside, last_vertex}

          is_inside ->
            {count + 1, is_inside, last_vertex}

          true ->
            {count, is_inside, last_vertex}
        end

        # cond do
        #   # MapSet.member?(borders, p) and MapSet.member?(borders, prev_p) ->
        #   #   {sum + 1, true, p}

        #   MapSet.member?(borders, p) and not MapSet.member?(borders, {x + 1, y}) ->
        #     {sum + 1, not is_inside}

        #   MapSet.member?(borders, p) ->
        #     {sum + 1, true}

        #   is_inside ->
        #     {sum + 1, is_inside}

        #   true ->
        #     {sum, is_inside}
        # end
      end)
      |> elem(0)
    end)
    |> dbg()
    |> Enum.sum()
  end

  def debug_area(%InstructionsSet{
        borders: b,
        vertices: v,
        min: {min_x, min_y},
        max: {max_x, max_y}
      }) do
    borders = MapSet.new(b)
    vertices = MapSet.new(v)

    min_y..max_y
    |> Enum.map(fn y ->
      min_x..max_x
      |> Enum.map(fn x -> {x, y} end)
      |> Enum.reduce({"", false, nil}, fn {x, y} = p, {acc, is_inside, last_vertex} ->
        cond do
          MapSet.member?(vertices, p) and
              (is_nil(last_vertex) or not border_like?(borders, last_vertex, p)) ->
            {acc <> "#", not is_inside, p}

          MapSet.member?(borders, p) and not MapSet.member?(borders, {x - 1, y}) and
              not MapSet.member?(borders, {x + 1, y}) ->
            {acc <> "#", not is_inside, last_vertex}

          MapSet.member?(borders, p) ->
            {acc <> "#", is_inside, last_vertex}

          is_inside ->
            {acc <> "#", is_inside, last_vertex}

          true ->
            {acc <> ".", is_inside, last_vertex}
        end
      end)
      |> elem(0)
    end)
    |> dbg()
    |> Enum.join("\n")
  end

  def calc_area_shoelace(%InstructionsSet{vertices: vertices}) do
    double_area =
      vertices
      |> Enum.reduce({List.last(vertices), 0}, fn {x2, y2}, {{x1, y1}, sum} ->
        {{x2, y2}, sum + (x2 + x1) * (y2 - y1 - 1)}
      end)
      |> elem(1)

    abs(double_area) / 2
  end

  def debug(%InstructionsSet{borders: b, min: {min_x, min_y}, max: {max_x, max_y}}) do
    borders = MapSet.new(b)

    min_y..max_y
    |> Enum.map(fn y ->
      min_x..max_x
      |> Enum.map(fn x -> {x, y} end)
      |> Enum.map(fn {x, y} ->
        if MapSet.member?(borders, {x, y}) do
          "#"
        else
          "."
        end
      end)
      |> Enum.join("")
    end)
    |> Enum.join("\n")
  end
end

defmodule Day18 do
  def part1(use_example) do
    instructions = parse_input1(use_example)

    output = InstructionsSet.debug_area(instructions)

    IO.puts(instructions |> InstructionsSet.calc_area())

    if use_example do
      IO.puts(output)
    else
      File.write!("output.txt", output)

      instructions
    end
  end

  def part2(use_example) do
    instructions = parse_input2(use_example)

    # output = InstructionsSet.debug_area(instructions)

    IO.puts(instructions |> InstructionsSet.calc_area())

    # if use_example do
    #   IO.puts(output)
    # else
    #   File.write!("output.txt", output)

    #   instructions
    # end
  end

  def parse_input1(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [direction, distance, hex_color] = String.split(line, " ", parts: 3, trim: true)

      color = hex_color |> String.slice(2..7) |> String.to_integer(16)

      %Instruction{
        direction: direction,
        distance: String.to_integer(distance),
        color: color
      }
    end)
    |> InstructionsSet.new()
  end

  def parse_input2(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [_direction, _distance, hex_code] = String.split(line, " ", parts: 3, trim: true)

      distance = hex_code |> String.slice(2..6) |> String.to_integer(16)

      direction =
        case hex_code |> String.at(7) do
          "0" -> "R"
          "1" -> "D"
          "2" -> "L"
          "3" -> "U"
        end

      %Instruction{
        direction: direction,
        distance: distance,
        color: 0
      }
    end)
    |> InstructionsSet.new()
  end
end
