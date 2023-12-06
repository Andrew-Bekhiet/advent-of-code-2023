defmodule Race do
  @enforce_keys [:minDistance, :maxTime]
  defstruct [:minDistance, :maxTime]

  def solve_for_hold_time(race) do
    a = -1
    b = race.maxTime
    c = -race.minDistance

    discriminant = b * b - 4 * a * c

    case discriminant do
      x when x < 0 ->
        nil

      discriminant ->
        sqrtDiscriminant = :math.sqrt(discriminant)

        {(-b + sqrtDiscriminant) / (2 * a), (-b - sqrtDiscriminant) / (2 * a)}
    end
  end
end

defmodule Day6 do
  @spec part1(boolean()) :: any
  def part1(useExample) do
    races = parse_input(useExample)

    nOfSolutions = solve_race_hold_times(races)

    Enum.reduce(nOfSolutions, &Kernel.*/2)
  end

  @spec part2(boolean()) :: any
  def part2(useExample) do
    race =
      parse_input(useExample)
      |> Enum.reduce(fn e, acc ->
        %Race{
          minDistance:
            String.to_integer(
              Integer.to_string(acc.minDistance) <> Integer.to_string(e.minDistance)
            ),
          maxTime:
            String.to_integer(Integer.to_string(acc.maxTime) <> Integer.to_string(e.maxTime))
        }
      end)

    nOfSolutions = solve_race_hold_times([race])

    Enum.reduce(nOfSolutions, &Kernel.*/2)
  end

  @spec parse_input(boolean()) :: [Race.t()]
  defp parse_input(useExample) do
    [timesString, distancesString] =
      if useExample do
        File.read!("example-input.txt")
      else
        File.read!("input.txt")
      end
      |> String.trim()
      |> String.split("\n", trim: true, parts: 2)
      |> Enum.map(&Enum.at(String.split(&1, ":", trim: true), 1))

    [times, distances] =
      [timesString, distancesString]
      |> Enum.map(&String.split(&1, " ", trim: true))

    Enum.with_index(times)
    |> Enum.map(fn {t, i} ->
      %Race{
        maxTime: String.to_integer(t),
        minDistance: String.to_integer(Enum.at(distances, i))
      }
    end)
  end

  @spec solve_race_hold_times([Race.t()]) :: [integer()]
  defp solve_race_hold_times(races) do
    Enum.map(races, &Race.solve_for_hold_time/1)
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.map(fn {r1, r2} ->
      r1 =
        if round(r1) - r1 == 0 do
          r1 + 1
        else
          :math.ceil(r1)
        end

      r2 =
        if round(r2) - r2 == 0 do
          r2 - 1
        else
          :math.floor(r2)
        end

      abs(r1 - r2) + 1
    end)
  end
end
