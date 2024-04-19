defmodule Day12 do
  # {can_merge, patterns}
  @base_case_memo %{
    "." => [
      {false, [], false}
    ],
    "#" => [
      {true, [1], true}
    ],
    "?" => [
      {false, [], false},
      {true, [1], true}
    ]
  }

  def merge_patterns(left, right, _is_continuous = false, _ \\ nil)
      when is_list(left) and is_list(right) do
    left ++ right
  end

  def merge_patterns([], [], _, _), do: []

  def merge_patterns(left, [], _, _), do: left

  def merge_patterns([], right, _, _), do: right

  def merge_patterns([left], [right], _is_continuous = true, _) do
    [left + right]
  end

  def merge_patterns(left, right, _is_continuous = true, left_length)
      when is_list(left) and is_list(right) and is_integer(left_length) do
    {left_rest, [left_last]} =
      left
      |> Enum.split(left_length - 1)

    {[right_hd], right_rest} =
      right
      |> Enum.split(1)

    left_rest ++ [left_last + right_hd | right_rest]
  end

  @spec merge_patterns(
          binary(),
          binary(),
          list({boolean(), list(pos_integer())}),
          list({boolean(), list(pos_integer())})
        ) :: list({boolean(), list(pos_integer())})
  def merge_patterns(
        left_first_char = <<_char>>,
        right_last_char = <<_char2>>,
        left_patterns,
        right_patterns
      )
      when is_list(left_patterns) and is_list(right_patterns) do
    left_patterns
    |> Enum.map(fn {left_can_merge_from_left, left, left_can_merge} ->
      left_length = length(left)

      right_patterns
      |> Enum.map(fn {right_can_merge, right, right_can_merge_from_right} ->
        {
          left_first_char == "#" or (left_first_char == "?" and left_can_merge_from_left),
          merge_patterns(left, right, left_can_merge and right_can_merge, left_length),
          right_last_char == "#" or (right_last_char == "?" and right_can_merge_from_right)
        }
      end)
    end)
    |> List.flatten()
  end

  def pad_left(list, required_length) do
    list_length = length(list)

    padding_length = required_length - list_length

    (1..padding_length |> Enum.map(fn _ -> 0 end)) ++ list
  end

  def solve_for(sequence, memo \\ @base_case_memo) do
    # IO.puts(sequence)

    sequence_length = String.length(sequence)

    case sequence do
      <<_>> ->
        {memo, memo |> Map.get(sequence)}

      _ ->
        {left, right} = sequence |> String.split_at(Kernel.div(sequence_length, 2))

        left_first_char = left |> String.slice(0, 1)
        right_last_char = right |> String.slice(-1, 1)

        # left_key = {left, left_first_char}

        {memo, left_patterns} =
          if memo |> Map.has_key?(left) do
            IO.puts("got result for left: #{left} from memo")

            {memo, memo |> Map.get(left)}
          else
            solve_for(left, memo)
          end

        {memo, right_patterns} =
          if memo |> Map.has_key?(right) do
            IO.puts("got result for right: #{right} from memo")

            {memo, memo |> Map.get(right)}
          else
            solve_for(right, memo)
          end

        result =
          merge_patterns(
            left_first_char,
            right_last_char,
            left_patterns,
            right_patterns
          )

        {memo |> Map.put(sequence, result), result}

      <<char>> <> rest ->
        # IO.puts("\nchar: #{<<char>>},\trest: #{rest}")

        left_patterns = memo |> Map.get_lazy(<<char>>, fn -> solve_for(<<char>>, memo) end)

        {new_memo, right_patterns} =
          if memo |> Map.has_key?(rest) do
            # IO.puts("got result for #{sequence} from memo")

            {memo, memo |> Map.get(rest)}
          else
            solve_for(rest, memo)
          end

        # IO.puts("solved for #{sequence}")

        # IO.puts(
        #  "result_can_merge: #{result_can_merge},\t\tmerging: #{inspect(left_patterns, pretty: true)}\t\tand #{inspect(right_patterns, pretty: true)}"
        # )

        result =
          merge_patterns(
            <<char>>,
            rest |> String.slice(-1, 1),
            left_patterns,
            right_patterns
          )

        # IO.puts("result: #{inspect(result, pretty: true)}")

        {new_memo |> Map.put(rest, result), result}
    end
  end

  def part1(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(fn {sequence, pattern} ->
      {_, p} = solve_for(sequence)

      count =
        p
        |> Enum.filter(fn {_, p, _} -> p == pattern end)
        |> Enum.count()

      IO.puts("Count for #{sequence}: #{count}")

      count
    end)
    |> Enum.sum()
  end

  def part2(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.reduce({@base_case_memo, 0}, fn {sequence, pattern}, {memo, sum} ->
      IO.puts("\nSolving for #{sequence} #{inspect(pattern, pretty: true)}")

      unfolded_pattern = pattern ++ pattern ++ pattern ++ pattern ++ pattern

      pattern_sum = Enum.sum(pattern)

      left_first_char = sequence |> String.slice(0, 1)
      right_last_char = sequence |> String.slice(-1, 1)

      {memo, patterns_} = solve_for(sequence <> "?", memo)
      {memo, patterns} = solve_for(sequence, memo)

      patterns =
        patterns
        |> Enum.filter(fn {_, p, _} -> pattern_sum == Enum.sum(p) end)

      #   |> Enum.filter(fn {can_merge_left, _, can_merge_right} ->
      #     ((not can_merge_left and left_first_char != "#") or
      #        (can_merge_left and left_first_char != ".")) and
      #       ((not can_merge_right and right_last_char != "#") or
      #          (can_merge_right and right_last_char != "."))
      #   end)

      patterns_ =
        patterns_
        |> Enum.filter(fn {_, p, _} -> pattern_sum == Enum.sum(p) end)

      #   |> Enum.filter(fn {can_merge_left, _, can_merge_right} ->
      #     (not can_merge_left and left_first_char != "#") or
      #       (can_merge_left and left_first_char != ".")
      #   end)
      #   |> Enum.filter(fn {_, p, _} ->
      #     if p == pattern do
      #       true
      #     else
      #       p_length = length(p)
      #       pattern_length = length(pattern)

      #       p_length == pattern_length or
      #         p_length - 1 == pattern_length
      #     end
      #   end)

      # |> Enum.map(fn {_, p, _} -> {false, p} end)

      IO.puts("patterns_ #{inspect(length(patterns_), pretty: true)}")
      IO.puts("Merging patterns")

      patterns_of_2 =
        merge_patterns(
          left_first_char,
          "?",
          patterns_,
          patterns_
        )

      patterns_of_4 =
        merge_patterns(
          left_first_char,
          "?",
          patterns_of_2,
          patterns_of_2
        )

      patterns_of_5 =
        merge_patterns(
          left_first_char,
          right_last_char,
          patterns_of_4,
          patterns
        )

      # IO.puts("patterns#{inspect(patterns, pretty: true)}")
      # IO.puts("patterns_with_seperator#{inspect(patterns_with_seperator, pretty: true)}")
      # IO.puts("patterns_of_2#{inspect(patterns_of_2, pretty: true)}")

      # IO.puts("Solving for 5*#{sequence_with_seperator}")

      # patterns_of_5 =
      #   merge_patterns(
      #     left_first_char,
      #     patterns,
      #     merge_patterns(left_first_char, patterns_of_2, patterns_of_2)
      #   )

      count =
        patterns_of_5
        |> Enum.filter(fn {_, p, _} -> p == unfolded_pattern end)
        |> Enum.count()

      IO.puts(count)

      {memo, sum + count}
    end)
    |> elem(1)
  end

  @spec parse_input(boolean) :: list({String.t(), list(pos_integer())})
  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    filename
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [seq, pattern] = String.split(line, " ", parts: 2)

      parsed_patterns = pattern |> String.split(",") |> Enum.map(&String.to_integer/1)

      {seq, parsed_patterns}
    end)
  end
end
