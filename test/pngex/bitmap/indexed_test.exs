defmodule Pngex.Bitmap.IndexedTest do
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
          palette = TestPixel.Palette.get(context)

          data =
            Enum.flat_map(0..(context.height - 1), fn y ->
              Enum.map(0..(context.width - 1), fn x ->
                TestPixel.ColorIndex.get(context, x, y)
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
          palette = TestPixel.Palette.get(context)

          data =
            for y <- 0..(context.height - 1), into: <<>> do
              for x <- 0..(context.width - 1), into: <<>> do
                <<TestPixel.ColorIndex.get(context, x, y)::size(depth)>>
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
