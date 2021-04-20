defmodule PngexGenerateRGBATest do
  use ExUnit.Case

  describe "generate/2 for RGBA-8" do
    setup do
      pngex = Pngex.new(type: :rgba, depth: :depth8, width: 256, height: 256)

      {:ok, expected} =
        "test/fixtures"
        |> Path.join("rgba8.png")
        |> File.read()

      [pngex: pngex, expected: expected]
    end

    test "list of integers", %{pngex: pngex, expected: expected} do
      data =
        Enum.flat_map(0..65535, fn n ->
          r = div(n, 256)
          g = rem(n, 256)
          b = 255 - max(r, g)
          a = if r in 64..191 && g in 64..191, do: 255, else: 0
          [r, g, b, a]
        end)

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end

    test "list of RGB color", %{pngex: pngex, expected: expected} do
      data =
        Enum.map(0..65535, fn n ->
          r = div(n, 256)
          g = rem(n, 256)
          b = 255 - max(r, g)
          a = if r in 64..191 && g in 64..191, do: 255, else: 0
          {r, g, b, a}
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
          r = div(n, 256)
          g = rem(n, 256)
          b = 255 - max(r, g)
          a = if r in 64..191 && g in 64..191, do: 65535, else: 0
          <<r, g, b, a>>
        end

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end
  end

  describe "generate/2 for RGBA-16" do
    setup do
      pngex = Pngex.new(type: :rgba, depth: :depth16, width: 256, height: 256)

      {:ok, expected} =
        "test/fixtures"
        |> Path.join("rgba16.png")
        |> File.read()

      [pngex: pngex, expected: expected]
    end

    test "list of integers", %{pngex: pngex, expected: expected} do
      data =
        Enum.flat_map(0..65535, fn n ->
          r = div(n, 256) * 256
          g = rem(n, 256) * 256
          b = 65535 - max(r, g)
          a = if r in 16384..49151 && g in 16384..49151, do: 65535, else: 0
          [r, g, b, a]
        end)

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end

    test "list of RGBA color", %{pngex: pngex, expected: expected} do
      data =
        Enum.map(0..65535, fn n ->
          r = div(n, 256) * 256
          g = rem(n, 256) * 256
          b = 65535 - max(r, g)
          a = if r in 16384..49151 && g in 16384..49151, do: 65535, else: 0
          {r, g, b, a}
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
          r = div(n, 256) * 256
          g = rem(n, 256) * 256
          b = 65535 - max(r, g)
          a = if r in 16384..49151 && g in 16384..49151, do: 65535, else: 0
          <<r::16, g::16, b::16, a::16>>
        end

      actual =
        pngex
        |> Pngex.generate(data)
        |> :erlang.iolist_to_binary()

      assert expected == actual
    end
  end
end
