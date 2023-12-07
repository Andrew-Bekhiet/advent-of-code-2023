defmodule Hand do
  alias String.Chars
  @enforce_keys [:cards, :bid]
  defstruct [:cards, :bid]

  def card_strength(card, _joker \\ false)
  def card_strength("A", _joker), do: 14
  def card_strength("K", _joker), do: 13
  def card_strength("Q", _joker), do: 12
  def card_strength("J", false), do: 11
  def card_strength("T", joker), do: maybe_shift_for_joker(10, joker)
  def card_strength("9", joker), do: maybe_shift_for_joker(9, joker)
  def card_strength("8", joker), do: maybe_shift_for_joker(8, joker)
  def card_strength("7", joker), do: maybe_shift_for_joker(7, joker)
  def card_strength("6", joker), do: maybe_shift_for_joker(6, joker)
  def card_strength("5", joker), do: maybe_shift_for_joker(5, joker)
  def card_strength("4", joker), do: maybe_shift_for_joker(4, joker)
  def card_strength("3", joker), do: maybe_shift_for_joker(3, joker)
  def card_strength("2", joker), do: maybe_shift_for_joker(2, joker)
  def card_strength("J", true), do: 1

  defp maybe_shift_for_joker(value, joker), do: value + if(joker, do: 1, else: 0)

  def hand_type(hand, joker \\ false)

  def hand_type(%Hand{cards: cards}, false) do
    hand_type(cards)
  end

  def hand_type(%Hand{cards: cards}, true) do
    unique_cards = MapSet.new(cards)

    if not Enum.member?(unique_cards, "J") do
      hand_type(cards)
    else
      unique_cards_without_j = Enum.reject(unique_cards, &(&1 == "J"))

      element_with_max_occurrences =
        Enum.reduce(unique_cards_without_j, "", fn card, prev_max ->
          card_count = Enum.count(cards, fn x -> card == x end)
          prev_max_count = Enum.count(cards, fn x -> prev_max == x end)

          if card_count > prev_max_count do
            card
          else
            prev_max
          end
        end)

      new_cards =
        Enum.map(cards, fn c ->
          if c == "J" do
            element_with_max_occurrences
          else
            c
          end
        end)

      hand_type(new_cards)
    end
  end

  def hand_type(cards, false) do
    unique_cards = MapSet.new(cards)
    set_size = MapSet.size(unique_cards)

    case set_size do
      1 ->
        {:five_of_a_kind, 7}

      2 ->
        first_card_count = Enum.count(cards, fn x -> x == Enum.at(cards, 0) end)

        if first_card_count == 1 or first_card_count == 4 do
          {:four_of_a_kind, 6}
        else
          {:full_house, 5}
        end

      3 ->
        if Enum.any?(unique_cards, fn card -> Enum.count(cards, fn x -> card == x end) == 3 end) do
          {:three_of_a_kind, 4}
        else
          {:two_pair, 3}
        end

      4 ->
        {:one_pair, 2}

      5 ->
        {:high_card, 1}
    end
  end
end

defmodule Day7 do
  @spec part1(boolean()) :: any
  def part1(useExample) do
    hands = parse_input(useExample)

    # Sort by hand type and then by card values (big endian)
    sorted_hands =
      Enum.sort_by(hands, fn h ->
        {_, hand_value} = Hand.hand_type(h)

        # Big Endian decoding
        cards_values =
          Enum.reverse(h.cards)
          |> Enum.map(&Hand.card_strength/1)
          |> Enum.with_index()
          |> Enum.reduce(0, fn {card, i}, acc ->
            acc + card * 14 ** i
          end)

        hand_value * 14 ** 6 + cards_values
      end)

    sorted_hands
    |> Enum.with_index()
    |> Enum.map(fn {%Hand{bid: bid}, i} -> bid * (i + 1) end)
    |> Enum.reduce(0, &Kernel.+/2)
  end

  @spec part2(boolean()) :: any
  def part2(useExample) do
    hands = parse_input(useExample)

    # Sort by hand type and then by card values (big endian)
    sorted_hands =
      Enum.sort_by(hands, fn h ->
        {_, hand_value} = Hand.hand_type(h, true)

        # Big Endian decoding
        cards_values =
          Enum.reverse(h.cards)
          |> Enum.map(&Hand.card_strength(&1, true))
          |> Enum.with_index()
          |> Enum.reduce(0, fn {card, i}, acc ->
            acc + card * 14 ** i
          end)

        hand_value * 14 ** 6 + cards_values
      end)

    sorted_hands
    |> Enum.with_index()
    |> Enum.map(fn {%Hand{bid: bid}, i} -> bid * (i + 1) end)
    |> Enum.reduce(0, &Kernel.+/2)
  end

  @spec parse_input(boolean()) :: [Race.t()]
  defp parse_input(useExample) do
    if useExample do
      File.read!("example-input.txt")
    else
      File.read!("input.txt")
    end
    |> String.trim()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, " ", trim: true))
    |> Enum.map(fn [cards, bid] ->
      {parsed_bid, _} = Integer.parse(bid)

      %Hand{
        cards: String.graphemes(cards),
        bid: parsed_bid
      }
    end)
  end
end
