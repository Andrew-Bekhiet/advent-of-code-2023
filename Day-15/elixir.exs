defmodule Lens do
  @type t :: %__MODULE__{
          label: String.t(),
          focal_length: integer()
        }
  defstruct [:label, :focal_length, :box_index]
end

defmodule Box do
  @type t :: %__MODULE__{
          lenses: %{String.t() => integer()},
          labels_order: [String.t()],
          box_index: integer()
        }
  defstruct [:lenses, :labels_order, :box_index]
end

defmodule Day15 do
  @spec hash(String.t()) :: integer()
  def hash(input) do
    input
    |> String.to_charlist()
    |> Enum.reduce(0, fn x, acc ->
      rem((acc + x) * 17, 256)
    end)
  end

  def part1(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(&hash(&1))
    |> Enum.sum()
  end

  @spec process_instruction(String.t(), %{integer() => Box.t()}) :: %{integer() => Box.t()}
  def process_instruction(instruction, current_state) do
    if String.ends_with?(instruction, "-") do
      process_remove_op(instruction, current_state)
    else
      process_assign_op(instruction, current_state)
    end
  end

  @spec process_assign_op(String.t(), %{integer() => Box.t()}) :: %{integer() => Box.t()}
  def process_assign_op(instruction, current_state) do
    [label, focal_length_string] = String.split(instruction, "=")
    focal_length = String.to_integer(focal_length_string)

    box_index = hash(label)

    Map.update(
      current_state,
      box_index,
      %Box{box_index: box_index, lenses: %{label => focal_length}, labels_order: [label]},
      fn box ->
        label_exists =
          box.labels_order
          |> Enum.any?(fn l -> l == label end)

        new_lenses = Map.put(box.lenses, label, focal_length)

        new_box =
          box
          |> Map.put(:lenses, new_lenses)

        if label_exists do
          new_box
        else
          new_box
          |> Map.put(:labels_order, [label | box.labels_order])
        end
      end
    )
  end

  @spec process_remove_op(String.t(), %{integer() => Box.t()}) :: %{integer() => Box.t()}
  def process_remove_op(instruction, current_state) do
    label = String.replace_suffix(instruction, "-", "")

    box_index = hash(label)

    Map.update(
      current_state,
      box_index,
      %Box{box_index: box_index, lenses: %{}, labels_order: []},
      fn box ->
        filtered_lenses = Map.filter(box.lenses, fn {l, _} -> l != label end)
        filtered_labels = Enum.filter(box.labels_order, fn l -> l != label end)

        box
        |> Map.put(:lenses, filtered_lenses)
        |> Map.put(:labels_order, filtered_labels)
      end
    )
  end

  def part2(use_example) do
    initial_state = %{}
    instructions = parse_input(use_example)

    instructions
    |> Enum.reduce(initial_state, &process_instruction/2)
    |> Map.filter(fn {_, b} -> not Enum.empty?(b.labels_order) end)
    |> Enum.reduce(0, fn {box_index, %Box{lenses: lenses, labels_order: labels_order}}, acc ->
      focus_power =
        labels_order
        |> Enum.reverse()
        |> Enum.with_index(1)
        |> Enum.reduce(0, fn {label, index}, acc ->
          acc + (box_index + 1) * index * Map.get(lenses, label)
        end)

      IO.puts("#{box_index}, #{inspect(labels_order)}, #{inspect(lenses)}, #{focus_power}")

      acc + focus_power
    end)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ",", trim: true))
    |> List.flatten()
  end
end
