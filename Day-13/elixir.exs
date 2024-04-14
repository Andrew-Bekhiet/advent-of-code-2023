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

  def find_horizontal_reflection_line(_ = %Note{data: data}, remove_smudge \\ false) do
    note_length = length(data)

    line_index =
      1..(note_length - 1)
      |> Enum.filter(fn y ->
        {part1, part2} = Enum.split(data, y)

        min_length = min(length(part1), length(part2))

        part1 =
          part1
          |> Enum.slice(length(part1) - min_length, length(part1))

        part2 = part2 |> Enum.take(min_length) |> Enum.reverse()

        if remove_smudge do
          char_difference_count(part1 |> Enum.join("\n"), part2 |> Enum.join("\n")) == 1
        else
          part1 == part2
        end
      end)
      |> List.first()

    line_index
  end

  def rotate_note_90(_ = %Note{data: data}) do
    height = length(data)
    width = data |> Enum.at(0) |> String.length()

    new_data =
      0..(width - 1)
      |> Enum.map(fn i ->
        0..(height - 1)
        |> Enum.map(fn j ->
          data
          |> Enum.at(j)
          |> String.at(i)
        end)
        |> Enum.join()
      end)

    %Note{data: new_data}
  end

  def find_vertical_reflection_line(note = %Note{}, remove_smudge \\ false) do
    note
    |> rotate_note_90()
    |> find_horizontal_reflection_line(remove_smudge)
  end

  def char_difference_count(str1, str2)
      when is_binary(str1) and is_binary(str2) and str1 == str2 do
    0
  end

  def char_difference_count(str1, str2)
      when is_binary(str1) and is_binary(str2) do
    if String.length(str1) != String.length(str2) do
      abs(length(str1) - length(str2))
    else
      str2_graphemes = str2 |> String.graphemes()

      str1
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(0, fn {char, i}, acc ->
        if str2_graphemes |> Enum.at(i) == char, do: acc, else: acc + 1
      end)
    end
  end

  def part2(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(fn note ->
      h = find_horizontal_reflection_line(note, true)
      v = find_vertical_reflection_line(note, true)

      v_val = if v == nil, do: 0, else: v
      h_val = if v != nil or h == nil, do: 0, else: h * 100

      h_val + v_val
    end)
    |> Enum.sum()
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    File.read!(filename)
    |> String.split("\n\n", trim: true)
    |> Enum.map(&%Note{data: String.split(&1, "\n", trim: true)})
  end
end
