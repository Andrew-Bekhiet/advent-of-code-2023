defmodule TreeNode do
  @type t :: %__MODULE__{
          right: t | nil,
          left: t | nil,
          data: any()
        }

  defstruct [:right, :left, :data]

  @spec traverse_with_distance(map(), t(), list(String.t()), integer(), integer()) :: integer()
  def traverse_with_distance(
        tree_map,
        current_node,
        instructions,
        instructions_length,
        current_distance \\ 0
      ) do
    if String.at(current_node.data, 2) == "Z" do
      current_distance
    else
      current_instruction =
        get_current_instruction(instructions, instructions_length, current_distance)

      traverse_with_distance(
        tree_map,
        traverse_one(tree_map, current_node, current_instruction),
        instructions,
        instructions_length,
        current_distance + 1
      )
    end
  end

  @spec get_current_instruction(list(String.t()), integer(), integer()) :: String.t()
  defp get_current_instruction(instructions, instructions_length, current_distance) do
    Enum.at(instructions, rem(current_distance, instructions_length))
  end

  @spec traverse_one(map(), t(), String.t()) :: t()
  defp traverse_one(tree_map, current_node, current_instruction) do
    if current_instruction == "R" do
      Map.get(tree_map, current_node.right)
    else
      Map.get(tree_map, current_node.left)
    end
  end
end

defmodule Day8 do
  @spec part1(boolean()) :: integer()
  def part1(use_example) do
    {instructions, tree_map} = parse_input(use_example)

    first_node = Map.get(tree_map, "AAA")

    TreeNode.traverse_with_distance(tree_map, first_node, instructions, length(instructions))
  end

  @spec part2(boolean()) :: any
  def part2(use_example) do
    {instructions, tree_map} = parse_input(use_example)

    nodes_ending_in_A =
      Map.to_list(tree_map)
      |> Enum.filter(fn {key, value} -> String.at(key, 2) == "A" end)
      |> Enum.map(fn {_, value} ->
        TreeNode.traverse_with_distance(tree_map, value, instructions, length(instructions))
      end)
      |> Enum.reduce(&lcm/2)
  end

  @spec parse_input(boolean()) :: {list(String.t()), map()}
  defp parse_input(use_example) do
    [instructions, tree_string] =
      if use_example do
        File.read!("example-input.txt")
      else
        File.read!("input.txt")
      end
      |> String.split("\n\n", trim: true, parts: 2)

    tree =
      tree_string
      |> String.split("\n", trim: true)
      |> Enum.map(fn line ->
        [current, children] = String.split(line, "=", trim: true)

        [left, right] =
          String.split(children, ",", trim: true)
          |> Enum.map(fn child ->
            String.replace(child, ~r"\(|\)", "")
          end)

        %TreeNode{data: String.trim(current), left: String.trim(left), right: String.trim(right)}
      end)

    instructions = String.graphemes(instructions)
    tree_map = Map.new(tree, fn node -> {node.data, node} end)

    {instructions, tree_map}
  end

  def gcd(a, b) do
    if b == 0 do
      a
    else
      gcd(b, rem(a, b))
    end
  end

  def lcm(a, b) do
    if a > b do
      div(a, gcd(a, b)) * b
    else
      div(b, gcd(a, b)) * a
    end
  end
end
