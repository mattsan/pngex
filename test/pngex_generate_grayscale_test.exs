defmodule PngexGenerateGrayscaleTest do
  use ExUnit.Case

  describe "generate/2 for grayscale" do
    setup do
      pngex = Pngex.new(type: :gray, depth: :depth8, width: 256, height: 256)

      {:ok, expected} =
        "test/fixtures"
        |> Path.join("grayscale8.png")
        |> File.read()

      [pngex: pngex, expected: expected]
    end

    test "list of integers", %{pngex: pngex, expected: expected} do
      data =
        Enum.map(0..65535, fn n ->
          rem(rem(n, 256) + div(n, 256), 256)
        end)

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end

    test "binary", %{pngex: pngex, expected: expected} do
      data =
        for n <- 0..65535, into: <<>> do
          <<rem(rem(n, 256) + div(n, 256), 256)>>
        end

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end
  end

  describe "generate/2 for grayscale and alpha" do
    setup do
      pngex = Pngex.new(type: :gray_and_alpha, depth: :depth8, width: 256, height: 256)

      {:ok, expected} =
        "test/fixtures"
        |> Path.join("grayscale_and_alpha8.png")
        |> File.read()

      [pngex: pngex, expected: expected]
    end

    test "list of integers", %{pngex: pngex, expected: expected} do
      data =
        Enum.flat_map(0..65535, fn n ->
          alpha = if rem(n, 256) in 64..191 && div(n, 256) in 64..191, do: 255, else: 0
          [rem(rem(n, 256) + div(n, 256), 256), alpha]
        end)

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end

    test "binary", %{pngex: pngex, expected: expected} do
      data =
        for n <- 0..65535, into: <<>> do
          alpha = if rem(n, 256) in 64..191 && div(n, 256) in 64..191, do: 255, else: 0
          <<rem(rem(n, 256) + div(n, 256), 256), alpha>>
        end

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end
  end
end
