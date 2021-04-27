defmodule IndexedPixel do
  def get_palette(%{depth: 8}) do
    Enum.map(0..255, fn n ->
      r = div(n, 16) * 16 + 15
      g = rem(n, 16) * 16 + 15
      b = 255 - max(r, g)
      {r, g, b}
    end)
  end

  def get_palette(%{depth: 4}) do
    Enum.map(0..15, fn n ->
      r = div(n, 4) * 64 + 63
      g = rem(n, 4) * 64 + 63
      b = 255 - max(r, g)
      {r, g, b}
    end)
  end

  def get_palette(%{depth: 2}) do
    [
      {0, 0, 255},
      {0, 255, 0},
      {255, 0, 0},
      {255, 255, 0}
    ]
  end

  def get_palette(%{depth: 1}) do
    [
      {0, 0, 255},
      {255, 255, 0}
    ]
  end

  def get_color(%{depth: 8}, x, y) do
    div(y, 16) * 16 + div(x, 16)
  end

  def get_color(%{depth: 4}, x, y) do
    div(y, 64) * 4 + div(x, 64)
  end

  def get_color(%{depth: 2}, x, y) do
    div(y, 128) * 2 + div(x, 128)
  end

  def get_color(%{depth: 1}, x, y) do
    if x + y < 256 do
      0
    else
      1
    end
  end
end

defmodule PngexGenerateIndexedTest do
  use ExUnit.Case

  @depths [1]
  @sizes 249..256

  setup context do
    pngex =
      Pngex.new(
        type: :indexed,
        depth: String.to_atom("depth#{context.depth}"),
        width: context.width,
        height: context.width
      )

    {:ok, expected} =
      "test/fixtures"
      |> Path.join("indexed/depth#{context.depth}/#{context.width}x#{context.height}.png")
      |> File.read()

    [pngex: pngex, expected: expected]
  end

  @depths
  |> Enum.each(fn depth ->
    describe "generate/2 for Indexed (depth #{depth})" do
      @describetag depth: depth

      @sizes
      |> Enum.map(&{&1, &1, "indexed/depth#{depth}/#{&1}x#{&1}.png"})
      |> Enum.each(fn {width, height, expected_image} ->
        @tag width: width, height: height, expected_image: expected_image
        test "list of integers (#{width}x#{height})", context do
          palette = IndexedPixel.get_palette(context)

          data =
            Enum.flat_map(0..(context.height - 1), fn y ->
              Enum.map(0..(context.width - 1), fn x ->
                IndexedPixel.get_color(context, x, y)
              end)
            end)

          actual =
            context.pngex
            |> Pngex.set_palette(palette)
            |> Pngex.generate(data)
            |> :erlang.iolist_to_binary()

          assert context.expected == actual
        end

        @tag width: width, height: height, expected_image: expected_image
        test "binary (#{width}x#{height})", %{depth: depth} = context do
          palette = IndexedPixel.get_palette(context)

          data =
            for y <- 0..(context.height - 1), into: <<>> do
              for x <- 0..(context.width - 1), into: <<>> do
                <<IndexedPixel.get_color(context, x, y)::size(depth)>>
              end
            end

          actual =
            context.pngex
            |> Pngex.set_palette(palette)
            |> Pngex.generate(data)
            |> :erlang.iolist_to_binary()

          assert context.expected == actual
        end
      end)
    end
  end)
end
