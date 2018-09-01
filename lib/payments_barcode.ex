defmodule PaymentsBarcode do
  @moduledoc """
  This lib helps you extract information from some brazillian bank slips.

  There are two main types:
  - Boleto
  - Guia de Arrecadação (here abbreviated as GDA)

  With this library you can extract information from a barcode or written code
  (the code meant to be typed by humans) or you can build a barcode or written
  code from the information itself. So that means you can also use this to
  convert from barcode to written code and back. Also, you can use that to
  validate the codes (this checks for the verifying digits).

  The `PaymentsBarcode.from_code/1` and `PaymentsBarcode.from_written_code/1` can
  be used when you don't know which type of slip you are dealing with.

  If you already know which type it is, you can use
  `PaymentsBarcode.Boleto.from_code/1`,
  `PaymentsBarcode.Boleto.from_written_code/1`,
  `PaymentsBarcode.GDA.from_code/1`,  PaymentsBarcode.GDA.from_written_code/1`
  instead.

  The same is valid for `to_written_code/1` and `to_barcode/1` methods.
  """

  alias __MODULE__.{
    Boleto,
    GDA
  }

  @type t :: Boleto.t() | GDA.t()

  @doc "Try to extract info from a barcode or written code"
  @spec from_code(String.t()) :: {:ok, t} | :error
  def from_code(code) do
    [&from_written_code/1, &from_barcode/1]
    |> try_parse(code)
  end

  @doc "Try to extract info from a written code"
  @spec from_written_code(String.t()) :: {:ok, t} | :error
  def from_written_code(code) do
    [&Boleto.from_written_code/1, &GDA.from_written_code/1]
    |> try_parse(code)
  end

  @doc "Try to extract info from a barcode"
  @spec from_barcode(String.t()) :: {:ok, t} | :error
  def from_barcode(code) do
    [&Boleto.from_barcode/1, &GDA.from_barcode/1]
    |> try_parse(code)
  end

  @doc "Generate barcode from info"
  @spec to_barcode(t) :: String.t()
  def to_barcode(%Boleto{} = data), do: Boleto.to_barcode(data)
  def to_barcode(%GDA{} = data), do: GDA.to_barcode(data)

  @doc "Generate written code from info"
  @spec to_written_code(t) :: String.t()
  def to_written_code(%Boleto{} = data), do: Boleto.to_written_code(data)
  def to_written_code(%GDA{} = data), do: GDA.to_written_code(data)

  defp try_parse(fns, code) do
    fns
    |> Stream.map(& &1.(code))
    |> Stream.filter(&(&1 != :error))
    |> Enum.at(0, :error)
  end
end
