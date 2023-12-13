defmodule Note do
  @type t :: %__MODULE__{
          data: list(String.t())
        }
  defstruct [:data]

  def at(note, {x, y}) do
    note.data
    |> Enum.at(y)
    |> String.graphemes()
    |> Enum.at(x)
  end
end

defmodule Day13 do
  def part1(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(fn note ->
      h = find_horizontal_reflection_line(note)
      v = find_vertical_reflection_line(note)

      v_val = if v == nil, do: 0, else: v
      h_val = if v != nil or h == nil, do: 0, else: h * 100

      h_val + v_val
    end)
    |> Enum.sum()
  end

  def find_horizontal_reflection_line(note) do
    note_length = length(note.data)

    line_index =
      1..(note_length - 1)
      |> Enum.filter(fn y ->
        {part1, part2} = Enum.split(note.data, y)

        min_length = min(length(part1), length(part2))

        part1 =
          part1
          |> Enum.reverse()
          |> Enum.take(min_length)
          |> Enum.reverse()

        part2 = Enum.take(part2, min_length) |> Enum.reverse()

        part1 == part2
      end)
      |> List.first()

    line_index
  end

  def find_vertical_reflection_line(note) do
    note_length = length(note.data)

    line_index =
      note.data
      |> Enum.with_index()
      |> Enum.map(fn {line, y} ->
        line_graphemes = String.graphemes(line)
        line_length = String.length(line)

        1..(line_length - 1)
        |> Enum.filter(fn x ->
          {part1, part2} = String.split_at(line, x)

          min_length = min(String.length(part1), String.length(part2))

          part1 =
            part1
            |> String.reverse()
            |> String.slice(0, min_length)

          part2 = String.slice(part2, 0, min_length)

          part1 == part2
        end)
      end)
      |> List.flatten()
      |> Enum.frequencies()
      |> Map.to_list()
      |> Enum.filter(fn {_, count} ->
        count == note_length
      end)
      |> List.first({nil, 0})
      |> elem(0)

    line_index
  end

  def part2(use_example) do
    input = parse_input(use_example)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n\n", trim: true)
      |> Enum.map(&%Note{data: String.split(&1, "\n", trim: true)})
  end
end
