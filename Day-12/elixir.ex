defmodule Day12 do
  @spec compute_possibilities(String.t()) :: list(String.t())
  def compute_possibilities(seq) when is_binary(seq) do
    cond do
      not (seq |> String.contains?("?")) ->
        [seq]

      true ->
        [a, b] = String.split(seq, "?", parts: 2)

        compute_possibilities(a <> "." <> b) ++ compute_possibilities(a <> "#" <> b)
    end
  end

  # @spec compute_valid_possibilities(String.t(), list(pos_integer())) :: list(String.t())
  # def compute_valid_possibilities(seq, patterns) when is_binary(seq) and is_list(patterns) do
  #   damaged_count = patterns |> Enum.sum()

  #   cond do
  #     not (seq |> String.contains?("?")) ->
  #       if is_seq_valid(seq, damaged_count, patterns) do
  #         [seq]
  #       else
  #         []
  #       end

  #     true ->
  #       [a, b] = String.split(seq, "?", parts: 2)

  #       [a <> "." <> b, a <> "#" <> b]
  #       |> Enum.map(fn seq -> seq |> compute_valid_possibilities(patterns) end)
  #       |> List.flatten()
  #   end
  # end

  @spec compute_valid_possibilities(String.t(), list(pos_integer()), map()) ::
          {map(), list(String.t())}
  def compute_valid_possibilities(seq, damaged_counts, memo)
      when is_binary(seq) and is_list(damaged_counts) and is_map(memo) do
    actual_damaged_count = damaged_counts |> Enum.sum()

    # 3 -> 3
    seq_damaged_count = seq |> String.graphemes() |> Enum.count(&(&1 == "#"))

    # 3 -> 2
    seq_unknowns_count = seq |> String.graphemes() |> Enum.count(&(&1 == "?"))

    {final_memo, result} =
      compute_valid_possibilities(
        seq,
        actual_damaged_count,
        seq_damaged_count,
        seq_unknowns_count,
        damaged_counts,
        memo
      )

    # IO.puts(inspect(final_memo, pretty: true))
    IO.puts(length(result))

    {final_memo, result}
  end

  @spec compute_valid_possibilities(
          String.t(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          list(pos_integer()),
          map()
        ) :: {map(), list(String.t())}
  def compute_valid_possibilities(
        seq,
        actual_damaged_count,
        seq_damaged_count,
        seq_unknowns_count,
        damaged_counts,
        memo
      )
      # actual_damaged_count = damaged_counts |> Enum.sum()
      when is_binary(seq) and is_integer(actual_damaged_count) and is_integer(seq_damaged_count) and
             is_integer(seq_damaged_count) and is_list(damaged_counts) and is_map(memo) do
    # Damaged count with unknown position
    unknown_damaged_count = actual_damaged_count - seq_damaged_count
    # Operational count with unknown position
    unknown_operational_count = seq_unknowns_count - unknown_damaged_count

    memo_key = {
      seq,
      # actual_damaged_count,
      # seq_damaged_count,
      # seq_unknowns_count
      # damaged_counts,
      unknown_operational_count,
      unknown_damaged_count
    }

    computation_result =
      memo
      |> Map.get_lazy(memo_key, fn ->
        {inner_memo, result} =
          case {unknown_operational_count > 0, unknown_damaged_count > 0} do
            {true, true} ->
              [a, b] = String.split(seq, "?", parts: 2)

              {operational_memo, operational_result} =
                compute_valid_possibilities(
                  a <> "." <> b,
                  actual_damaged_count,
                  seq_damaged_count,
                  seq_unknowns_count - 1,
                  damaged_counts,
                  memo
                )

              merged_memo =
                Map.merge(memo, operational_memo, fn key, val1, val2 ->
                  MapSet.new(val1 ++ val2) |> MapSet.to_list()
                end)

              {damaged_memo, damaged_result} =
                compute_valid_possibilities(
                  a <> "#" <> b,
                  actual_damaged_count,
                  seq_damaged_count + 1,
                  seq_unknowns_count - 1,
                  damaged_counts,
                  merged_memo
                )

              merged_memo =
                Map.merge(merged_memo, damaged_memo, fn key, val1, val2 ->
                  MapSet.new(val1 ++ val2) |> MapSet.to_list()
                end)

              {
                merged_memo,
                operational_result ++ damaged_result
              }

            {false, true} ->
              [a, b] = String.split(seq, "?", parts: 2)

              compute_valid_possibilities(
                a <> "#" <> b,
                actual_damaged_count,
                seq_damaged_count + 1,
                seq_unknowns_count - 1,
                damaged_counts,
                memo
              )

            {true, false} ->
              [a, b] = String.split(seq, "?", parts: 2)

              compute_valid_possibilities(
                a <> "." <> b,
                actual_damaged_count,
                seq_damaged_count,
                seq_unknowns_count - 1,
                damaged_counts,
                memo
              )

            _ ->
              if is_seq_valid(seq, actual_damaged_count, damaged_counts) do
                {memo, [seq]}
              else
                {memo, []}
              end
          end

        new_memo =
          inner_memo
          |> Map.put(memo_key, result)

        {new_memo, result}
      end)

    if is_tuple(computation_result) do
      computation_result
    else
      IO.puts("result from memo")
      {memo, computation_result}
    end
  end

  # def compute_valid_possibilities(seq, max_damaged_count, max_operational_count)
  #     when is_binary(seq) and is_integer(max_damaged_count) and is_integer(max_operational_count) do
  #   cond do
  #     not (seq |> String.contains?("?")) ->
  #       if is_seq_valid(seq, damaged_count, patterns) do
  #         [seq]
  #       else
  #         []
  #       end

  #     true ->
  #       [a, b] = String.split(seq, "?", parts: 2)

  #       [a <> "." <> b, a <> "#" <> b]

  #       compute_valid_possibilities(a <> "." <> b, max_damaged_count, max_operational_count - 1) <>
  #         compute_valid_possibilities(a <> "#" <> b, max_damaged_count - 1, max_operational_count)
  #   end
  # end

  @spec find_valid_sequences(list(String.t()), list(pos_integer())) :: list(String.t())
  def find_valid_sequences(sequences, patterns) when is_list(sequences) and is_list(patterns) do
    damaged_count = patterns |> Enum.sum()

    sequences
    |> Enum.filter(fn seq ->
      is_seq_valid(seq, damaged_count, patterns)
    end)
  end

  def is_seq_valid(seq, damaged_count, patterns) do
    seq
    |> String.graphemes()
    |> Enum.count(&(&1 == "#")) == damaged_count and
      seq
      |> count_first_contiguous() == patterns
  end

  def count_first_contiguous(seq, char \\ "#") when is_binary(seq) and is_binary(char) do
    {count, next_index} =
      seq
      |> String.graphemes()
      |> Enum.reduce({0, 0, char}, fn
        ^char, {count, index, ^char} ->
          {count + 1, index + 1, char}

        _, {count, index, _} when count == 0 ->
          {count, index + 1, char}

        current_char, {count, index, char} ->
          {count, index, "  "}
      end)
      |> Tuple.delete_at(2)

    {_, rest} = seq |> String.split_at(next_index)

    if rest |> String.contains?(char) do
      [count | count_first_contiguous(rest, char)]
    else
      [count]
    end
  end

  def part1(use_example) do
    input = parse_input(use_example)

    {memo, sum} =
      input
      |> Enum.reduce({%{}, 0}, fn {seq, counts}, {memo, acc} ->
        {new_memo, list} = seq |> compute_valid_possibilities(counts, memo)

        {
          new_memo,
          acc + length(list)
        }
      end)

    sum
  end

  def part2(use_example) do
    input = parse_input(use_example)

    {memo, sum} =
      input
      |> Enum.reduce({%{}, 0}, fn {seq, counts}, {memo, acc} ->
        new_seq = seq <> "?" <> seq <> "?" <> seq <> "?" <> seq <> "?" <> seq
        new_counts = counts ++ counts ++ counts ++ counts ++ counts

        {new_memo, list} = seq |> compute_valid_possibilities(new_counts, memo)

        {
          new_memo,
          acc + length(list)
        }
      end)

    sum
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
