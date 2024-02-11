defmodule RangeTransformer do
  @type t :: %RangeTransformer{
          range: Range.t(),
          offset: integer()
        }
  defstruct range: 0..-1//1, offset: 0

  @spec parse(String.t()) :: RangeTransformer.t()
  def parse(line) do
    [dst, src, length] = String.split(line, " ", parts: 3, trim: true)

    {
      src_int,
      dst_int,
      length_int
    } =
      {
        String.to_integer(src),
        String.to_integer(dst),
        String.to_integer(length)
      }

    %RangeTransformer{
      range: src_int..(src_int + length_int - 1),
      offset: dst_int - src_int
    }
  end

  @spec contains(RangeTransformer.t(), integer()) :: boolean()
  def contains(%RangeTransformer{range: range}, value) when is_integer(value) do
    value in range
  end

  @spec apply(RangeTransformer.t(), integer()) :: integer()
  def apply(%RangeTransformer{offset: offset} = t, value) when is_integer(value) do
    cond do
      t |> contains(value) ->
        value + offset

      true ->
        value
    end
  end

  # Range:      [--------------------------]
  # Transformer:  [-----]
  # Result:     [][-----][-----------------]
  @spec apply(RangeTransformer.t(), Range.t()) :: [
          ok: Range.t() | nil,
          noop: list(Range.t())
        ]
  def apply(
        %RangeTransformer{
          range: t_from..t_to = t_range,
          offset: offset
        },
        from..to = range
      ) do
    cond do
      Range.disjoint?(t_range, range) ->
        [ok: nil, noop: [range]]

      # Range:      [-----------]     or    [-----]  or   [--]     or   [--]       or      [---]
      # Transformer:  [-----]         or    [-----]  or  [-----]   or    [-----]   or  [-----]
      true ->
        {left, rest} =
          case t_from - from do
            split when split >= 0 ->
              range
              |> Range.split(split)

            _ ->
              {0..-1//1, range}
          end

        {middle, right} =
          case t_to - to do
            split when split < 0 ->
              rest
              |> Range.split(split)

            _ ->
              {rest, 0..-1//1}
          end

        noop =
          [left, right]
          |> Enum.reject(&(Range.size(&1) == 0))

        result = middle |> Range.shift(offset)

        if result |> Range.size() == 0 do
          [ok: [], noop: noop]
        else
          [ok: result, noop: noop]
        end
    end
  end
end

defmodule MultiRangeTransformer do
  @type t :: %MultiRangeTransformer{
          transformers: list(RangeTransformer.t())
        }
  defstruct transformers: []

  @spec parse(String.t()) :: MultiRangeTransformer.t()
  def parse(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&RangeTransformer.parse/1)
    |> then(&%MultiRangeTransformer{transformers: &1})
  end

  @spec contains(MultiRangeTransformer.t(), integer()) :: boolean()
  def contains(%MultiRangeTransformer{transformers: transformers}, value)
      when is_integer(value) do
    transformers |> Enum.any?(&RangeTransformer.contains(&1, value))
  end

  @spec apply(MultiRangeTransformer.t(), integer()) :: integer()
  def apply(%MultiRangeTransformer{transformers: transformers}, value) when is_integer(value) do
    transformers
    |> Enum.find(&RangeTransformer.contains(&1, value))
    |> case do
      nil -> value
      transformer -> RangeTransformer.apply(transformer, value)
    end
  end

  # Range:      [--------------------------]
  # Transformer:  [-----]      [-----]   [-]
  # Result:     [][-----][----][-----][-][-]
  @spec apply(MultiRangeTransformer.t(), Range.t()) :: list(Range.t())
  def apply(%MultiRangeTransformer{transformers: transformers}, _.._ = range) do
    transformers
    |> Enum.reduce(
      [ok: [], noop: [range]],
      fn t, acc ->
        rslt =
          acc
          |> Keyword.get_values(:noop)
          |> List.flatten()
          |> Enum.reduce(
            acc,
            fn
              r, [ok: ok, noop: noop] ->
                [ok: new_ok, noop: new_noop] = RangeTransformer.apply(t, r)

                new_ok = if new_ok == nil, do: ok, else: [new_ok | ok]
                new_noop = if new_noop == nil, do: noop, else: new_noop

                [ok: new_ok, noop: new_noop]
            end
          )

        rslt
      end
    )
    |> then(fn rslt ->
      (rslt
       |> Keyword.get_values(:ok)
       |> List.flatten()) ++
        (rslt
         |> Keyword.get_values(:noop)
         |> List.flatten())
    end)
    |> Enum.sort_by(fn from.._ -> from end)
  end
end

defmodule Almanc do
  @type t :: %Almanc{
          transformers: list(RangeTransformer.t())
        }

  defstruct transformers: []

  @spec apply(Almanc.t(), integer()) :: integer()
  def apply(%Almanc{transformers: transformers}, value) when is_integer(value) do
    transformers
    |> Enum.reduce(value, &MultiRangeTransformer.apply/2)
  end

  @spec apply(Almanc.t(), Range.t()) :: Range.t()
  def apply(%Almanc{transformers: transformers}, _.._ = range) do
    transformers
    |> Enum.reduce([range], fn t, acc ->
      rslt =
        acc
        |> Enum.map(&MultiRangeTransformer.apply(t, &1))
        |> List.flatten()

      rslt
    end)
    |> Enum.uniq()
  end
end

defmodule Day5 do
  def part1(use_example) do
    {seeds, almanc} = parse_input(use_example)

    seeds
    |> Enum.map(&Almanc.apply(almanc, &1))
    |> Enum.min()
  end

  def part2(use_example) do
    {seeds, almanc} = parse_input(use_example)

    seed_ranges =
      seeds
      |> Enum.chunk_every(2)
      |> Enum.map(fn [from, length] -> from..(from + length - 1) end)

    seed_ranges
    |> Enum.map(&Almanc.apply(almanc, &1))
    |> List.flatten()
    |> Enum.map(fn from.._ -> from end)
    |> Enum.min()
  end

  @spec parse_input(boolean()) :: {String.t(), Almanc.t()}
  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    sections =
      filename
      |> File.read!()
      |> String.split("\n\n", trim: true)

    transformers =
      sections
      |> Enum.drop(1)
      |> Enum.map(fn line ->
        line
        |> String.split(":", trim: true, parts: 2)
        |> Enum.at(1)
      end)
      |> Enum.map(&MultiRangeTransformer.parse/1)

    seeds =
      sections
      |> Enum.at(0)
      |> String.split(":", trim: true)
      |> Enum.at(1)
      |> String.split(" ", trim: true)
      |> Enum.map(&String.to_integer/1)

    {seeds, %Almanc{transformers: transformers}}
  end
end
