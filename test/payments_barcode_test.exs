defmodule PaymentsBarcodeTest do
  use ExUnit.Case
  doctest PaymentsBarcode

  use ExUnit.Case

  import PaymentsBarcode

  alias PaymentsBarcode.{
    Boleto,
    GDA
  }

  @boleto_barcode_right "34192739500000536011090343851820934251919000"
  @boleto_barcode_wrong "34193739500000536011090343851820934251919000"
  @boleto_written_code_right "34191090324385182093642519190005273950000053601"
  @boleto_written_code_wrong "34191090334385182093642519190005273950000053601"
  @gda_barcode_right "83660000001191000531077337928261110007433982"
  @gda_barcode_wrong "83650000001191000531077337928261110007433982"

  @gda_cnpj_mod11 %GDA{
    segment_id: "6",
    verification_method: :mod11,
    value: 10,
    value_type: :reference,
    company_id: "12345678",
    free_field: "123456789012345678901"
  }

  @gda_reference_barcode "81750000000469036592018020731018010018369021"
  @gda_written_code_right "836600000019191000531076733792826113100074339829"
  @gda_written_code_wrong "836600000018191000531076733792826113100074339829"

  describe "Info for GDA payment code" do
    test "Can extract GDA data from barcode" do
      assert {:ok, %GDA{}} = from_code(@gda_barcode_right)
    end

    test "Can extract GDA data from written code" do
      assert {:ok, %GDA{}} = from_code(@gda_written_code_right)
    end

    test "It verifies barcode digit" do
      assert :error = from_code(@gda_barcode_wrong)
    end

    test "It verifies written code digit" do
      assert :error = from_code(@gda_written_code_wrong)
    end

    test "Can build barcode from GDA data" do
      {:ok, d} = from_code(@gda_barcode_right)
      assert @gda_barcode_right == to_barcode(d)
    end

    test "Can build written code from GDA data" do
      {:ok, d} = from_code(@gda_written_code_right)
      assert @gda_written_code_right == to_written_code(d)
    end

    test "Output is correct for reference values" do
      assert {:ok, %GDA{value_type: :reference}} = from_code(@gda_reference_barcode)
    end

    test "it can generate barcode from info for mod11 with cnpj" do
      barcode = to_barcode(@gda_cnpj_mod11)
      assert "12345678" = String.slice(barcode, 15..22)
      assert "9" = String.at(barcode, 2)
      assert {:ok, @gda_cnpj_mod11} == from_barcode(barcode)
    end
  end

  describe "code for boleto payment" do
    test "Can extract Boleto data from barcode" do
      assert {:ok, %Boleto{}} = from_code(@boleto_barcode_right)
    end

    test "Can extract Boleto data from written code" do
      assert {:ok, %Boleto{}} = from_code(@boleto_written_code_right)
    end

    test "It verifies barcode digit" do
      assert :error = from_code(@boleto_barcode_wrong)
    end

    test "It verifies written code digit" do
      assert :error = from_code(@boleto_written_code_wrong)
    end

    test "Can build barcode from Boleto data" do
      {:ok, d} = from_code(@boleto_barcode_right)
      assert @boleto_barcode_right == to_barcode(d)
    end

    test "Can build written code from Boleto data" do
      {:ok, d} = from_code(@boleto_written_code_right)
      assert @boleto_written_code_right == to_written_code(d)
    end
  end

  describe "Convertion from barcode to written_code" do
    test "when the code is a Barcode" do
      assert from_barcode_to_written_code(@boleto_barcode_right) == @boleto_written_code_right
    end

    test "when the code is a GDA" do
      assert from_barcode_to_written_code(@gda_barcode_right) == @gda_written_code_right
    end

    test "when convertion fails" do
      assert from_barcode_to_written_code(@boleto_barcode_wrong) == :error
      assert from_barcode_to_written_code(@gda_barcode_wrong) == :error
    end
  end

  describe "Convertion from written_code to barcode" do
    test "when the code is a Barcode" do
      assert from_written_code_to_barcode(@boleto_written_code_right) == @boleto_barcode_right
    end

    test "when the code is a GDA" do
      assert from_written_code_to_barcode(@gda_written_code_right) == @gda_barcode_right
    end

    test "when convertion fails" do
      assert from_written_code_to_barcode(@boleto_written_code_wrong) == :error
      assert from_written_code_to_barcode(@gda_written_code_wrong) == :error
    end
  end

  test "it doesnt crash with non-binary values" do
    assert :error = from_code(1234)
  end
end
