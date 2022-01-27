defmodule PaymentsBarcode.Boleto do
  @moduledoc """
  Represents a
  """

  alias PaymentsBarcode.{
    Boleto,
    Shared
  }

  import Shared, only: [is_string_with_len: 2]

  defstruct [
    :bank_code,
    :currency_code,
    :value,
    :due_date,
    :free_field
  ]

  @type t :: %Boleto{
          bank_code: String.t(),
          currency_code: String.t(),
          value: integer,
          due_date: Date.t() | nil,
          free_field: String.t()
        }

  @base_date ~D[1997-10-07]

  @spec from_written_code(String.t()) :: {:ok, t} | :error
  def from_written_code(code) when is_string_with_len(code, 47) do
    with true <- Shared.all_numbers(code),
         {:ok, info} <- do_from_written_code(code),
         ^code <- to_written_code(info) do
      {:ok, info}
    else
      _ ->
        :error
    end
  end

  def from_written_code(_), do: :error

  @spec from_barcode(String.t()) :: {:ok, t} | :error
  def from_barcode(barcode) when is_string_with_len(barcode, 44) do
    with true <- Shared.all_numbers(barcode),
         {:ok, info} <- do_from_barcode(barcode),
         ^barcode <- to_barcode(info) do
      {:ok, info}
    else
      _ -> :error
    end
  end

  def from_barcode(_), do: :error

  @spec to_written_code(t) :: String.t()
  def to_written_code(info) do
    [
      [
        info.bank_code,
        info.currency_code,
        String.slice(info.free_field, 0..4)
      ]
      |> Enum.join("")
      |> add_field_digit(),
      info.free_field |> String.slice(5..14) |> add_field_digit(),
      info.free_field |> String.slice(15..24) |> add_field_digit(),
      barcode_digit(info),
      due_date_factor(info.due_date),
      format_value(info.value)
    ]
    |> Enum.join("")
  end

  @spec to_barcode(t) :: String.t()
  def to_barcode(info) do
    info
    |> barcode_fields()
    |> List.insert_at(2, barcode_digit(info))
    |> Enum.join("")
  end

  defp do_from_written_code(code) do
    case Shared.extract(written_code_extractor_config(), code) do
      :error ->
        :error

      result ->
        {:ok, result}
    end
  end

  defp do_from_barcode(barcode) do
    case Shared.extract(barcode_extractor_config(), barcode) do
      :error ->
        :error

      result ->
        {:ok, result}
    end
  end

  # Helpers

  defp add_field_digit(code), do: code <> Shared.digit(code, 10, "0")

  defp barcode_digit(%Boleto{} = info) do
    info
    |> barcode_fields()
    |> Enum.join("")
    |> Shared.digit(11, "1")
  end

  defp barcode_fields(info) do
    [
      info.bank_code,
      info.currency_code,
      due_date_factor(info.due_date),
      format_value(info.value),
      info.free_field
    ]
  end

  defp barcode_extractor_config, do: extractor_config(5..8, 9..18, [19..43])

  defp written_code_extractor_config do
    extractor_config(33..36, 37..46, [
      04..08,
      10..19,
      21..30
    ])
  end

  defp extractor_config(due_date_range, value_range, free_field_ranges) do
    %Boleto{
      bank_code: &String.slice(&1, 0..2),
      currency_code: &String.at(&1, 3),
      due_date: &(&1 |> String.slice(due_date_range) |> String.to_integer() |> due_date),
      value: fn code ->
        code
        |> String.slice(value_range)
        |> String.to_integer()
      end,
      free_field: fn code ->
        free_field_ranges
        |> Enum.map(fn range -> String.slice(code, range) end)
        |> Enum.join("")
      end
    }
  end

  defp format_value(val) do
    val
    |> to_string()
    |> String.pad_leading(10, "0")
  end

  defp due_date(0), do: nil
  defp due_date(days), do: Date.add(@base_date, days)

  defp due_date_factor(%Date{} = date) do
    date
    |> Date.diff(@base_date)
    |> to_string()
    |> String.pad_leading(4, "0")
  end

  defp due_date_factor(_), do: "0000"
end
