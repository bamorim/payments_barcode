defmodule PaymentsBarcode.Shared do
  @moduledoc false

  defguard is_string_with_len(str, len)
           when is_binary(str) and byte_size(str) == len

  def all_numbers(code), do: Regex.match?(~r/^\d+$/, code)

  def digit(input, 10, default) do
    value = 10 - digit_remainder(input, [2, 1], 10, true)
    if value > 9, do: to_string(default), else: to_string(value)
  end

  def digit(input, 11, default) do
    value = 11 - digit_remainder(input, 2..9, 11, false)
    if value > 9, do: to_string(default), else: to_string(value)
  end

  def digit_remainder(input, sequence, mod, sum_digits) do
    input
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.reverse()
    |> Enum.zip(Stream.cycle(Enum.to_list(sequence)))
    |> Enum.flat_map(fn {v, d} ->
      if sum_digits do
        Integer.digits(v * d)
      else
        [v * d]
      end
    end)
    |> Enum.reduce(0, &(&1 + &2))
    |> rem(mod)
  end

  def extract(struct, input) do
    struct
    |> Map.keys()
    |> Enum.reduce(struct, fn key, acc -> extract_field(acc, key, input) end)
  end

  defp extract_field(:error, _, _), do: :error

  defp extract_field(struct, key, code) do
    value = Map.get(struct, key)

    if is_function(value) do
      case value.(code) do
        :error ->
          :error

        result ->
          Map.put(struct, key, result)
      end
    else
      struct
    end
  end
end
