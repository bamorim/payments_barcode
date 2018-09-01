defmodule PaymentsBarcode.GDA do
  @moduledoc false

  alias __MODULE__
  alias PaymentsBarcode.Shared

  import Shared, only: [is_string_with_len: 2]

  defstruct [
    :segment_id,
    :verification_method,
    :value_type,
    :value,
    :company_id,
    :free_field
  ]

  @type t :: %GDA{
          segment_id: String.t(),
          verification_method: :mod10 | :mod11,
          value_type: :effective | :reference,
          value: integer,
          company_id: String.t(),
          free_field: String.t()
        }

  @spec from_written_code(String.t()) :: {:ok, t} | :error
  def from_written_code(code) when is_string_with_len(code, 48) do
    with true <- Shared.all_numbers(code),
         barcode <- String.replace(code, ~r/(\d{11})\d/, "\\g{1}"),
         {:ok, info} <- from_barcode(barcode),
         ^code <- to_written_code(info) do
      {:ok, info}
    else
      _ -> :error
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
    info
    |> to_barcode()
    |> add_written_verifying_digits(info.verification_method)
  end

  @spec to_barcode(t) :: String.t()
  def to_barcode(info) do
    [
      "8",
      info.segment_id,
      value_type_for(info.verification_method, info.value_type),
      info.value
      |> to_string()
      |> String.pad_leading(11, "0"),
      info.company_id,
      info.free_field
    ]
    |> Enum.join("")
    |> add_global_verifying_digit(info.verification_method)
  end

  defp do_from_barcode(barcode) do
    case Shared.extract(extractor_config(), barcode) do
      :error ->
        :error

      result ->
        {:ok, result}
    end
  end

  defp value_type_for(method, type) do
    case {method, type} do
      {:mod10, :effective} ->
        "6"

      {:mod10, :reference} ->
        "7"

      {:mod11, :effective} ->
        "8"

      {:mod11, :reference} ->
        "9"
    end
  end

  defp add_written_verifying_digits(code, mod) do
    for <<part::binary-11 <- code>> do
      part <> digit(part, mod)
    end
    |> Enum.join("")
  end

  defp add_global_verifying_digit(code, mod) do
    [
      String.slice(code, 0..2),
      digit(code, mod),
      String.slice(code, 3..42)
    ]
    |> Enum.join("")
  end

  defp digit(code, :mod10), do: Shared.digit(code, 10, "0")
  defp digit(code, :mod11), do: Shared.digit(code, 11, "0")

  defp extractor_config do
    value_type_infos = %{
      "6" => {:mod10, :effective},
      "7" => {:mod10, :reference},
      "8" => {:mod11, :effective},
      "9" => {:mod11, :reference}
    }

    segment_for = &String.at(&1, 1)
    value_type_info = &Map.get(value_type_infos, String.at(&1, 2))

    verification_method = fn code ->
      case value_type_info.(code) do
        {method, _} ->
          method

        _ ->
          :error
      end
    end

    value_type = fn code ->
      case value_type_info.(code) do
        {_, type} ->
          type

        _ ->
          :error
      end
    end

    value = fn code ->
      code
      |> String.slice(4..14)
      |> String.to_integer()
    end

    company_id = fn code ->
      case segment_for.(code) do
        "6" ->
          String.slice(code, 15..22)

        _ ->
          String.slice(code, 15..18)
      end
    end

    free_field = fn code ->
      case segment_for.(code) do
        "6" ->
          String.slice(code, 23..43)

        _ ->
          String.slice(code, 19..43)
      end
    end

    %GDA{
      segment_id: segment_for,
      verification_method: verification_method,
      value_type: value_type,
      value: value,
      company_id: company_id,
      free_field: free_field
    }
  end
end
