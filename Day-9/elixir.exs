# defmodule PolynomialFunction do
#   @type t :: %__MODULE__{
#           coeffecient: integer(),
#           power: integer(),
#           next: t | nil
#         }
#   defstruct [:coeffecient, :power, :next]

#   @spec calc(t(), integer()) :: integer()
#   def calc(function, x) do
#     if function.next == nil do
#       if function.power == 0 do
#         function.coeffecient
#       else
#         function.coeffecient * x ** function.power
#       end
#     else
#       if function.power == 0 do
#         function.coeffecient + calc(function.next, x)
#       else
#         function.coeffecient * x ** function.power + calc(function.next, x)
#       end
#     end
#   end

#   def print_fn(function) do
#     if function.next == nil do
#       "#{inspect(function.coeffecient)}x^#{inspect(function.power)}"
#     else
#       "#{inspect(function.coeffecient)}x^#{inspect(function.power)} + #{print_fn(function.next)}"
#     end
#   end
# end

defmodule Day9 do
  # @spec make_function_from_sequence(list(integer()), integer()) :: PolynomialFunction.t()
  # def make_function_from_sequence(sequence, x_offset \\ 0) do
  #   if Enum.all?(sequence, &(&1 == 0)) do
  #     IO.puts(
  #       "#{inspect(sequence)}: Zero function, f(x) = #{inspect(Enum.at(sequence, 0))}, x_offset: #{inspect(x_offset)}"
  #     )

  #     # IO.puts("")

  #     %PolynomialFunction{
  #       coeffecient: 0,
  #       power: 0,
  #       next: nil
  #     }
  #   else
  #     if Enum.all?(sequence, &(&1 == Enum.at(sequence, 0))) do
  #       f = %PolynomialFunction{
  #         coeffecient: Enum.at(sequence, 0),
  #         power: 0,
  #         next: nil
  #       }

  #       IO.puts(
  #         "#{inspect(sequence)}: Constant function, f(x) = #{PolynomialFunction.calc(f, 0)}, x_offset: #{inspect(x_offset)}"
  #       )

  #       f
  #     else
  #       function = make_function_from_sequence(calculate_differences(sequence), x_offset + 0.5)

  #       x = x_offset
  #       y = Enum.at(sequence, 0)

  #       function = integerate(function, {x, y})

  #       IO.puts(
  #         "#{inspect(sequence)}: #{PolynomialFunction.print_fn(function)} f(#{inspect(x)}) = #{inspect(y)}"
  #       )

  #       function
  #     end
  #   end
  # end

  # @spec calculate_differences(list(integer())) :: list(integer())
  # def calculate_differences(ys) do
  #   IO.puts(inspect(ys))

  #   Enum.slice(ys, 1, length(ys) - 1)
  #   |> Enum.with_index()
  #   |> Enum.map(fn {y, i} ->
  #     y - Enum.at(ys, i)
  #   end)
  # end

  # def indefinite_integral(function) do
  #   %PolynomialFunction{
  #     power: function.power + 1,
  #     coeffecient: function.coeffecient / (function.power + 1),
  #     next: if(function.next == nil, do: nil, else: indefinite_integral(function.next))
  #   }
  # end

  # @spec integerate(PolynomialFunction.t(), {integer(), integer()}) :: PolynomialFunction.t()
  # def integerate(function, {x, y}) do
  #   new_fn_without_c = indefinite_integral(function)

  #   calculated_y = PolynomialFunction.calc(new_fn_without_c, x)

  #   if calculated_y == y do
  #     new_fn_without_c
  #   else
  #     f = %PolynomialFunction{
  #       power: new_fn_without_c.power,
  #       coeffecient: new_fn_without_c.coeffecient,
  #       next: %PolynomialFunction{
  #         power: 0,
  #         coeffecient: y - calculated_y,
  #         next: new_fn_without_c.next
  #       }
  #     }

  #     IO.puts("f: #{PolynomialFunction.print_fn(f)}")

  #     f
  #   end
  # end

  def calc_next(sequence) do
    diff = calculate_differences(sequence)

    if Enum.all?(diff, &(&1 == 0)) do
      Enum.at(sequence, 0)
    else
      List.last(sequence) + calc_next(diff)
    end
  end

  def calc_prev(sequence) do
    calc_next(Enum.reverse(sequence))
  end

  @spec part1(boolean()) :: integer()
  def part1(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(fn sequence ->
      calc_next(sequence)
    end)
    |> Enum.sum()
  end

  @spec part2(boolean()) :: any
  def part2(use_example) do
    input = parse_input(use_example)

    input
    |> Enum.map(fn sequence ->
      calc_prev(sequence)
    end)
    |> Enum.sum()
  end

  @spec parse_input(boolean()) :: list(list(String.t()))
  defp parse_input(use_example) do
    filename = if use_example, do: "example-input.txt", else: "input.txt"

    File.read!(filename)
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      String.split(line, " ", trim: true)
      |> Enum.map(&String.to_integer/1)
    end)
  end
end
