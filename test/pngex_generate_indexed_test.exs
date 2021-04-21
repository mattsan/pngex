defmodule PngexGenerateIndexedTest do
  use ExUnit.Case

  describe "generate/2 for Indexed-8" do
    setup do
      pngex = Pngex.new(type: :indexed, depth: :depth8, width: 256, height: 256)

      {:ok, expected} =
        "test/fixtures"
        |> Path.join("indexed8.png")
        |> File.read()

      [pngex: pngex, expected: expected]
    end

    test "list of integers", %{pngex: pngex, expected: expected} do
      palette =
        Enum.map(0..255, fn n ->
          r = div(n, 16) * 16 + 15
          g = rem(n, 16) * 16 + 15
          b = 255 - max(r, g)
          {r, g, b}
        end)

      data =
        Enum.flat_map(0..255, fn y ->
          Enum.map(0..255, fn x ->
            div(y, 16) * 16 + div(x, 16)
          end)
        end)

      actual =
        pngex
        |> Pngex.set_palette(palette)
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end

    test "binary", %{pngex: pngex, expected: expected} do
      palette =
        Enum.map(0..255, fn n ->
          r = div(n, 16) * 16 + 15
          g = rem(n, 16) * 16 + 15
          b = 255 - max(r, g)
          {r, g, b}
        end)

      data =
        for y <- 0..255, into: <<>> do
          for x <- 0..255, into: <<>> do
            <<div(y, 16) * 16 + div(x, 16)>>
          end
        end

      actual =
        pngex
        |> Pngex.set_palette(palette)
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end
  end
end
