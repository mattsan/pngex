defmodule PngexTest do
  use ExUnit.Case
  doctest Pngex

  describe "valid calling new/1" do
    test "without options" do
      expected = %Pngex{
        type: :rgb,
        depth: :depth8,
        width: 0,
        height: 0,
        palette: []
      }

      assert ^expected = Pngex.new()
    end

    test "set parameters" do
      expected = %Pngex{
        type: :indexed,
        depth: :depth16,
        width: 100,
        height: 200,
        palette: [{1, 2, 3}, {4, 5, 6}]
      }

      assert ^expected =
               Pngex.new(
                 type: :indexed,
                 depth: :depth16,
                 width: 100,
                 height: 200,
                 palette: [{1, 2, 3}, {4, 5, 6}]
               )
    end

    test "the largest width and height" do
      expected = %Pngex{
        type: :rgb,
        depth: :depth8,
        width: 4_294_967_295,
        height: 4_294_967_295
      }

      assert ^expected = Pngex.new(width: 4_294_967_295, height: 4_294_967_295)
    end
  end

  describe "invalid calling new/1" do
    test "negative width and height" do
      assert {:error, [width: -10, height: -20]} = Pngex.new(width: -10, height: -20)
    end

    test "non-integer width and height" do
      assert {:error, [width: 12.34, height: 43.21]} = Pngex.new(width: 12.34, height: 43.21)
    end

    test "too large width and height" do
      assert {:error, [width: 4_294_967_296, height: 4_294_967_296]} =
               Pngex.new(width: 4_294_967_296, height: 4_294_967_296)
    end

    test "invalit type" do
      assert {:error, [type: 9]} = Pngex.new(type: 9)
    end

    test "invalid depth" do
      assert {:error, [depth: 9]} = Pngex.new(depth: 9)
    end

    test "invalid palette" do
      assert {:error, [palette: [{1, 2, 3}, {4, 5, 6}, {7}]]} =
               Pngex.new(palette: [{1, 2, 3}, {4, 5, 6}, {7}])
    end
  end

  describe "set_type/2" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid type: rgb", %{pngex: pngex} do
      assert %Pngex{type: :rgb} = pngex |> Pngex.set_type(:rgb)
    end

    test "valid type: rgba", %{pngex: pngex} do
      assert %Pngex{type: :rgba} = pngex |> Pngex.set_type(:rgba)
    end

    test "valid type: gray", %{pngex: pngex} do
      assert %Pngex{type: :gray} = pngex |> Pngex.set_type(:gray)
    end

    test "valid type: gray_and_alpha", %{pngex: pngex} do
      assert %Pngex{type: :gray_and_alpha} = pngex |> Pngex.set_type(:gray_and_alpha)
    end

    test "valid type: indexed", %{pngex: pngex} do
      assert %Pngex{type: :indexed} = pngex |> Pngex.set_type(:indexed)
    end

    test "invalid type", %{pngex: pngex} do
      assert {:error, invalid_type: :monotone} = pngex |> Pngex.set_type(:monotone)
    end
  end

  describe "set_depth/2" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid depth: depth1", %{pngex: pngex} do
      assert %Pngex{depth: :depth1} = pngex |> Pngex.set_depth(:depth1)
    end

    test "valid depth: depth2", %{pngex: pngex} do
      assert %Pngex{depth: :depth2} = pngex |> Pngex.set_depth(:depth2)
    end

    test "valid depth: depth4", %{pngex: pngex} do
      assert %Pngex{depth: :depth4} = pngex |> Pngex.set_depth(:depth4)
    end

    test "valid depth: depth8", %{pngex: pngex} do
      assert %Pngex{depth: :depth8} = pngex |> Pngex.set_depth(:depth8)
    end

    test "valid depth: depth16", %{pngex: pngex} do
      assert %Pngex{depth: :depth16} = pngex |> Pngex.set_depth(:depth16)
    end

    test "invvalid depth", %{pngex: pngex} do
      assert {:error, invalid_depth: :depth15} = pngex |> Pngex.set_depth(:depth15)
    end
  end

  describe "set_width/2" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid width", %{pngex: pngex} do
      assert %Pngex{width: 123} = pngex |> Pngex.set_width(123)
    end

    test "zero", %{pngex: pngex} do
      assert {:error, invalid_width: 0} = pngex |> Pngex.set_width(0)
    end

    test "negative integer", %{pngex: pngex} do
      assert {:error, invalid_width: -1} = pngex |> Pngex.set_width(-1)
    end

    test "non-integer", %{pngex: pngex} do
      assert {:error, invalid_width: 12.3} = pngex |> Pngex.set_width(12.3)
    end

    test "too large width", %{pngex: pngex} do
      assert {:error, invalid_width: 0x1_00_00_00_00} = pngex |> Pngex.set_width(0x1_00_00_00_00)
    end
  end

  describe "set_height/2" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid height", %{pngex: pngex} do
      assert %Pngex{height: 123} = pngex |> Pngex.set_height(123)
    end

    test "zero", %{pngex: pngex} do
      assert {:error, invalid_height: 0} = pngex |> Pngex.set_height(0)
    end

    test "negative integer", %{pngex: pngex} do
      assert {:error, invalid_height: -1} = pngex |> Pngex.set_height(-1)
    end

    test "non-integer", %{pngex: pngex} do
      assert {:error, invalid_height: 12.3} = pngex |> Pngex.set_height(12.3)
    end

    test "too large height", %{pngex: pngex} do
      assert {:error, invalid_height: 0x1_00_00_00_00} =
               pngex |> Pngex.set_height(0x1_00_00_00_00)
    end
  end

  describe "set_size/3" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid width and height", %{pngex: pngex} do
      assert %Pngex{width: 123, height: 456} = pngex |> Pngex.set_size(123, 456)
    end

    test "invalid width", %{pngex: pngex} do
      assert {:error, invalid_size: %{width: -1}} = pngex |> Pngex.set_size(-1, 456)
    end

    test "invalid height", %{pngex: pngex} do
      assert {:error, invalid_size: %{height: -1}} = pngex |> Pngex.set_size(123, -1)
    end

    test "invalid width and height", %{pngex: pngex} do
      assert {:error, invalid_size: %{width: -1, height: -1}} = pngex |> Pngex.set_size(-1, -1)
    end
  end

  describe "set_palette/2" do
    setup do
      [pngex: Pngex.new()]
    end

    test "valid palette", %{pngex: pngex} do
      assert %Pngex{palette: [{0, 0, 0}, {255, 255, 255}]} =
               pngex |> Pngex.set_palette([{0, 0, 0}, {255, 255, 255}])
    end

    test "invalid palette", %{pngex: pngex} do
      assert {:error, invalid_palette: [{1, 2, 3, 4}]} =
               pngex |> Pngex.set_palette([{1, 2, 3, 4}])
    end
  end
end
