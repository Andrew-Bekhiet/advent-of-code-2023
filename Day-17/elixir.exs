defmodule Heap do
  defstruct data: nil, size: 0, comparator: nil

  @moduledoc """
  A heap is a special tree data structure. Good for sorting and other magic.

  See also: [Heap (data structure) on Wikipedia](https://en.wikipedia.org/wiki/Heap_(data_structure)).
  """

  @type t :: %Heap{
          data: tuple() | nil,
          size: non_neg_integer(),
          comparator: :> | :< | (any(), any() -> boolean())
        }

  @doc """
  Create an empty min `Heap`.

  A min heap is a heap tree which always has the smallest value at the root.

  ## Examples

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.min())
      ...>   |> Heap.root()
      1
  """
  @spec min :: t
  def min, do: Heap.new(:<)

  @doc """
  Create an empty max `Heap`.

  A max heap is a heap tree which always has the largest value at the root.

  ## Examples

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.max())
      ...>   |> Heap.root()
      10
  """
  @spec max :: t
  def max, do: Heap.new(:>)

  @doc """
  Create an empty `Heap` with the default comparator (`<`).

  Defaults to `>`.

  ## Examples

      iex> Heap.new()
      ...>   |> Heap.comparator()
      :<
  """
  @spec new :: t
  def new, do: %Heap{comparator: :<}

  @doc """
  Create an empty heap with a specific comparator.

  Provide a `comparator` option, which can be `:<`, `:>` to indicate
  that the `Heap` should use Elixir's normal `<` or `>` comparison functions
  or a custom comparator function.

    ## Examples

        iex> Heap.new(:<)
        ...>   |> Heap.comparator()
        :<

  If given a function it should compare two arguments, and return `true` if
  the first argument precedes the second one.

    ## Examples

        iex> 1..10
        ...>   |> Enum.shuffle()
        ...>   |> Enum.into(Heap.new(&(&1 > &2)))
        ...>   |> Enum.to_list()
        [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

        iex> Heap.new(&(Date.compare(elem(&1, 0), elem(&2, 0)) == :gt))
        ...>   |> Heap.push({~D[2017-11-20], :jam})
        ...>   |> Heap.push({~D[2017-11-21], :milk})
        ...>   |> Heap.push({~D[2017-10-21], :bread})
        ...>   |> Heap.push({~D[2017-10-20], :eggs})
        ...>   |> Enum.map(fn {_, what} -> what end)
        [:milk, :jam, :bread, :eggs]
  """
  @spec new(:> | :< | (any, any -> boolean)) :: t
  def new(:>), do: %Heap{comparator: :>}
  def new(:<), do: %Heap{comparator: :<}
  def new(fun) when is_function(fun, 2), do: %Heap{comparator: fun}

  @doc """
  Test if `heap` is empty.

  ## Examples

      iex> Heap.new()
      ...>   |> Heap.empty?()
      true

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.empty?()
      false
  """
  @spec empty?(t) :: boolean()
  def empty?(%Heap{data: nil, size: 0}), do: true
  def empty?(%Heap{}), do: false

  @doc """
  Test if the `heap` contains the element `value`.

  ## Examples

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.member?(11)
      false

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.member?(7)
      true
  """
  @spec member?(t, any()) :: boolean()
  def member?(%Heap{} = heap, value) do
    root = Heap.root(heap)
    heap = Heap.pop(heap)
    has_member?(heap, root, value)
  end

  @doc """
  Push a new `value` into `heap`.

  ## Examples

      iex> Heap.new()
      ...>   |> Heap.push(13)
      ...>   |> Heap.root()
      13
  """
  @spec push(t, any()) :: t
  def push(%Heap{data: h, size: n, comparator: d}, value),
    do: %Heap{data: meld(h, {value, []}, d), size: n + 1, comparator: d}

  @doc """
  Pop the root element off `heap` and discard it.

  ## Examples

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.pop()
      ...>   |> Heap.root()
      2
  """
  @spec pop(t) :: t | nil
  def pop(%Heap{data: nil, size: 0} = _heap), do: nil

  def pop(%Heap{data: {_, q}, size: n, comparator: d} = _heap),
    do: %Heap{data: pair(q, d), size: n - 1, comparator: d}

  @doc """
  Return the element at the root of `heap`.

  ## Examples

      iex> Heap.new()
      ...>   |> Heap.root()
      nil

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.root()
      1
  """
  @spec root(t) :: any()
  def root(%Heap{data: {v, _}} = _heap), do: v
  def root(%Heap{data: nil, size: 0} = _heap), do: nil

  @doc """
  Return the number of elements in `heap`.

  ## Examples

      iex> 1..10
      ...>   |> Enum.shuffle()
      ...>   |> Enum.into(Heap.new())
      ...>   |> Heap.size()
      10
  """
  @spec size(t) :: non_neg_integer()
  def size(%Heap{size: n}), do: n

  @doc """
  Return the comparator `heap` is using for insert comparisons.

  ## Examples

      iex> Heap.new(:<)
      ...>   |> Heap.comparator()
      :<
  """
  @spec comparator(t) :: :< | :> | (any, any -> boolean)
  def comparator(%Heap{comparator: d}), do: d

  @doc """
  Return the root element and the rest of the heap in one operation.

  ## Examples

      iex> heap = 1..10 |> Enum.into(Heap.min())
      ...> rest = Heap.pop(heap)
      ...> {1, rest} == Heap.split(heap)
      true
  """
  @spec split(t) :: {any, t}
  def split(%Heap{} = heap), do: {Heap.root(heap), Heap.pop(heap)}

  defp meld(nil, queue, _), do: queue
  defp meld(queue, nil, _), do: queue

  defp meld({k0, l0}, {k1, _} = r, :<) when k0 < k1, do: {k0, [r | l0]}
  defp meld({_, _} = l, {k1, r0}, :<), do: {k1, [l | r0]}

  defp meld({k0, l0}, {k1, _} = r, :>) when k0 > k1, do: {k0, [r | l0]}
  defp meld({_, _} = l, {k1, r0}, :>), do: {k1, [l | r0]}

  defp meld({k0, l0} = l, {k1, r0} = r, fun) when is_function(fun, 2) do
    case fun.(k0, k1) do
      true -> {k0, [r | l0]}
      false -> {k1, [l | r0]}
      err -> raise("Comparator should return boolean, but returned '#{err}'.")
    end
  end

  defp pair([], _), do: nil
  defp pair([q], _), do: q

  defp pair([q0, q1 | q], d) do
    q2 = meld(q0, q1, d)
    meld(q2, pair(q, d), d)
  end

  defp has_member?(_, previous, compare) when previous == compare, do: true
  defp has_member?(nil, _, _), do: false

  defp has_member?(heap, _, compare) do
    {previous, heap} = Heap.split(heap)
    has_member?(heap, previous, compare)
  end
end

defmodule Grid do
  @type t :: %__MODULE__{
          data: [[integer()]],
          height: integer(),
          width: integer()
        }
  defstruct [:data, :height, :width]

  @spec at(t(), {integer(), integer()}) :: String.t()
  def at(grid, {x, y}) do
    grid.data
    |> elem(y)
    |> elem(x)
  end

  @spec get_adjacent_locations(t(), {integer(), integer()}) :: [{integer(), integer()}]
  def get_adjacent_locations(%Grid{width: width, height: height}, {x, y}) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.filter(fn {x, y} ->
      x >= 0 and y >= 0 and x < height and y < width
    end)
  end

  @spec debug(t(), MapSet.t()) :: String.t()
  def debug(%Grid{data: data}, visited_locations = %MapSet{}) do
    data
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.map(fn {row, y} ->
      row
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        if MapSet.member?(visited_locations, {x, y}) do
          "▪"
        else
          cell
        end
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end

defmodule Day17 do
  def reconstruct_path(result = %{}, last, n \\ :infinity) do
    with {{prev, _}, _} when n > 0 <- Map.pop(result, last) do
      [prev | reconstruct_path(result, prev, if(n == :infinity, do: n, else: n - 1))]
    else
      _ -> []
    end
  end

  def validate_path(result, to) do
    {head, tail} =
      [to | result |> reconstruct_path(to)]
      |> Enum.split(5)

    # IO.puts("Validating path head: #{inspect(head)}, tail: #{inspect(tail)}")
    # Check that there are at most 4 consecutive steps in same direction
    is_invalid =
      tail
      |> Enum.reduce_while(head |> Enum.reverse(), fn {x, y}, acc ->
        {from_x, from_y} = acc |> List.first()

        is_invalid =
          case {x, y} do
            {x, y} when from_x < x ->
              [{from_x - 1, y}, {from_x - 2, y}, {from_x - 3, y}, {from_x - 4, y}]

            {x, y} when from_y < y ->
              [{x, from_y - 1}, {x, from_y - 2}, {x, from_y - 3}, {x, from_y - 4}]

            {x, y} when from_x > x ->
              [{from_x + 1, y}, {from_x + 2, y}, {from_x + 3, y}, {from_x + 4, y}]

            {x, y} when from_y > y ->
              [{x, from_y + 1}, {x, from_y + 2}, {x, from_y + 3}, {x, from_y + 4}]
          end
          |> Enum.all?(fn l -> acc |> Enum.member?(l) end)

        if is_invalid do
          # IO.puts("Is valid?? #{false}")
          {:halt, false}
        else
          {:cont, [{x, y} | acc |> Enum.slice(0, 4)]}
        end
      end)

    # IO.puts("Is valid? #{is_invalid != false}")

    is_invalid != false
  end

  @spec dijkstra(Grid.t(), tuple(), tuple(), Map.t(), MapSet.t()) :: Map.t()
  def dijkstra(grid, from, to, locations_costs \\ %{}, explored \\ %MapSet{})

  # def dijkstra(%Grid{} = grid, from, to, _locations_costs) when from == to do
  #   location_heat_loss = Grid.at(grid, to)

  #   {_, from_heat_loss} = acc |> Map.get(from, {nil, 0})
  #   new_heat_loss = from_heat_loss + location_heat_loss

  #   acc
  #   |> Map.update({x, y}, new_heat_loss, fn
  #     {_, old} when new_heat_loss < old -> {from, new_heat_loss}
  #     old -> old
  #   end)
  # end

  def dijkstra(
        %Grid{} = grid,
        {from_x, from_y} = from,
        to,
        locations_costs,
        explored
      ) do
    IO.puts("Exploring #{inspect(from)}")
    IO.puts(grid |> Grid.debug(locations_costs |> reconstruct_path(from) |> MapSet.new()))

    IO.puts(
      inspect(locations_costs |> Enum.sort_by(fn {_, {_, heat_loss}} -> heat_loss end),
        pretty: true
      ) <> "\n"
    )

    IO.puts(
      inspect(
        locations_costs
        |> Enum.reject(fn l -> MapSet.member?(explored, l) end)
        |> Enum.sort_by(fn {_, {_, heat_loss}} -> heat_loss end),
        pretty: true
      ) <> "\n"
    )

    adjacent_nodes =
      grid
      |> Grid.get_adjacent_locations(from)
      |> Enum.reject(fn l ->
        # IO.puts(
        #   "Branching from #{inspect(from)}, #{inspect(l)} is #{if(MapSet.member?(explored, l), do: "visited", else: "not visited")}"
        # )

        MapSet.member?(explored, l)
      end)

    # |> Enum.reject(fn {x, y} ->
    #   case {x, y} do
    #     {x, y} when from_x < x ->
    #       [{from_x - 1, y}, {from_x - 2, y}, {from_x - 3, y}]

    #     {x, y} when from_y < y ->
    #       [{x, from_y - 1}, {x, from_y - 2}, {x, from_y - 3}]

    #     {x, y} when from_x > x ->
    #       [{from_x + 1, y}, {from_x + 2, y}, {from_x + 3, y}]

    #     {x, y} when from_y > y ->
    #       [{x, from_y + 1}, {x, from_y + 2}, {x, from_y + 3}]
    #   end
    #   |> Enum.all?(fn l -> explored |> MapSet.member?(l) end)
    # end)

    IO.puts("Adjacent nodes: #{inspect(adjacent_nodes, pretty: true)}")

    new_locations_costs =
      adjacent_nodes
      |> Enum.reduce(
        locations_costs,
        fn {x, y} = location, acc ->
          recent_steps = reconstruct_path(acc, from, 5)

          is_invalid =
            case {x, y} do
              {x, y} when from_x < x ->
                [{from_x - 1, y}, {from_x - 2, y}, {from_x - 3, y}]

              {x, y} when from_y < y ->
                [{x, from_y - 1}, {x, from_y - 2}, {x, from_y - 3}]

              {x, y} when from_x > x ->
                [{from_x + 1, y}, {from_x + 2, y}, {from_x + 3, y}]

              {x, y} when from_y > y ->
                [{x, from_y + 1}, {x, from_y + 2}, {x, from_y + 3}]
            end
            |> Enum.all?(fn l -> recent_steps |> Enum.member?(l) end)

          if is_invalid do
            acc
          else
            location_heat_loss = Grid.at(grid, location)

            {_, from_heat_loss} = acc |> Map.get(from, {nil, 0})

            new_heat_loss = from_heat_loss + location_heat_loss

            acc
            |> Map.update(location, {from, new_heat_loss}, fn
              {_, old} when new_heat_loss < old -> {from, new_heat_loss}
              old -> old
            end)
          end
        end
      )

    new_explored = explored |> MapSet.put(from)

    with {location, _} <-
           new_locations_costs
           |> Enum.reject(fn {location, _} -> MapSet.member?(explored, location) end)
           |> Enum.sort_by(fn {_, {_, heat_loss}} -> heat_loss end)
           |> Enum.at(0) do
      with {true, result} <- dijkstra(grid, location, to, new_locations_costs, new_explored) do
        {true, result}
      else
        new_acc -> dijkstra(grid, location, to, new_acc, new_explored)
      end
    else
      _ -> new_locations_costs
    end

    # |> Enum.reduce_while(new_locations_costs, fn
    #   {location, _}, acc when location == to ->
    #     # if validate_path(acc, to) do
    #     IO.puts("Found")
    #     {:halt, {true, acc}}

    #   # else
    #   #   IO.puts(grid |> Grid.debug(acc |> reconstruct_path(to) |> MapSet.new()))
    #   #   {:cont, acc}
    #   # end

    #   {^from, _}, acc ->
    #     {:cont, acc}

    #   {location, _}, acc ->
    #     # IO.puts("\n\nExpanding from #{inspect(from)} to #{inspect(location)}")

    #     with false <- MapSet.member?(explored, location),
    #          {true, result} <- dijkstra(grid, location, to, acc, new_explored) do
    #       {:halt, {true, result}}
    #     else
    #       b when b in [true, false] -> {:cont, acc}
    #       new_acc -> {:cont, new_acc}
    #     end
    # end)
  end

  def part1(use_example) do
    %Grid{width: w, height: h} = input = parse_input(use_example)

    {true, result} = dijkstra(input, {0, 0}, {w - 1, h - 1}, %{}, MapSet.new([{0, 0}]))

    max_location = {w - 1, h - 1}

    path = [max_location | result |> reconstruct_path(max_location)]

    input
    |> Grid.debug(MapSet.new(path))
    |> IO.puts()

    minimum_heat_loss = result |> Map.get(max_location)

    {
      path |> Enum.reverse(),
      minimum_heat_loss,
      max_location
    }
  end

  def part2(use_example) do
    _input = parse_input(use_example)
  end

  def parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    data =
      File.read!(filename)
      |> String.split("\n", trim: true)

    graphemes =
      data
      |> Enum.map(fn x ->
        x
        |> String.graphemes()
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end)
      |> List.to_tuple()

    %Grid{
      data: graphemes,
      height: tuple_size(graphemes),
      width: graphemes |> elem(0) |> tuple_size()
    }
  end
end
