defmodule Part do
  @type t :: %__MODULE__{
          x: integer(),
          m: integer(),
          a: integer(),
          s: integer()
        }

  defstruct [:x, :m, :a, :s]

  def parse(line) when is_binary(line) do
    [_, body] = Regex.compile!("{(.+)}") |> Regex.run(line)

    [x, m, a, s] =
      body
      |> String.split(",")
      |> Enum.map(fn p ->
        p
        |> String.slice(2..-1//1)
        |> String.to_integer()
      end)

    %Part{x: x, m: m, a: a, s: s}
  end
end

defmodule Rule do
  @type t :: %__MODULE__{
          category: String.t(),
          op: atom(),
          val: integer(),
          then: String.t()
        }
  defstruct [:category, :op, :val, :then]

  def parse(line) when is_binary(line) do
    if not String.contains?(line, ":") do
      %Rule{then: line}
    else
      [rest, then] = String.split(line, ":", parts: 2)

      category = rest |> String.at(0)

      op =
        rest
        |> String.at(1)
        |> String.to_atom()

      val =
        rest
        |> String.slice(2..-1//1)
        |> String.to_integer()

      %Rule{category: category, op: op, val: val, then: then}
    end
  end

  def evaluate(%Rule{op: op, then: then}, %Part{}) when is_nil(op), do: then

  def evaluate(%Rule{category: category, op: op, val: val, then: then}, %Part{} = part) do
    category_value = Map.get(part, category |> String.to_existing_atom())

    case op do
      :< when category_value < val -> then
      :> when category_value > val -> then
      _ -> false
    end
  end
end

defmodule Workflow do
  @type t :: %__MODULE__{
          name: String.t(),
          rules: list(Rule.t())
        }
  defstruct [:name, :rules]

  def parse(line) when is_binary(line) do
    [_, name, rules] =
      Regex.compile!("(.+){(.+)}")
      |> Regex.run(line)

    rules =
      rules
      |> String.split(",")
      |> Enum.map(&Rule.parse/1)

    %Workflow{name: name, rules: rules}
  end

  def evaluate(%Workflow{name: name, rules: rules}, %Part{} = part) do
    rules
    |> Enum.find_value(fn rule ->
      rule |> Rule.evaluate(part)
    end)
  end
end

defmodule Day19 do
  def run_through_workflows(workflows, %Part{} = part, workflow_name \\ "in")
      when is_map(workflows) do
    case workflows
         |> Map.get(workflow_name)
         |> Workflow.evaluate(part) do
      "R" -> "R"
      "A" -> "A"
      w -> run_through_workflows(workflows, part, w)
    end
  end

  def part1(use_example) do
    {workflows, parts} = parse_input(use_example)

    parts
    |> Enum.filter(fn part ->
      run_through_workflows(workflows, part) == "A"
    end)
    |> Enum.map(fn %Part{x: x, m: m, a: a, s: s} ->
      x + m + a + s
    end)
    |> Enum.sum()
  end

  def part2(use_example) do
    {workflows, _} = parse_input(use_example)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    [workflows, parts] =
      File.read!(filename)
      |> String.split("\n\n", trim: true, parts: 2)

    workflows =
      workflows
      |> String.split("\n", trim: true)
      |> Enum.map(&Workflow.parse/1)
      |> Map.new(fn workflow -> {workflow.name, workflow} end)

    parts =
      parts
      |> String.split("\n", trim: true)
      |> Enum.map(&Part.parse/1)

    {workflows, parts}
  end
end
