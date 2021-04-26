defmodule PngexGenerateRGBTest do
  use ExUnit.Case

  @depths [8, 16]
  @sizes 249..256

  setup context do
    pngex =
      Pngex.new(
        type: context.type,
        depth: String.to_atom("depth#{context.depth}"),
        width: context.width,
        height: context.height
      )

    {:ok, expected} =
      "test/fixtures"
      |> Path.join(context.expected_image)
      |> File.read()

    [pngex: pngex, expected: expected]
  end

  @depths
  |> Enum.each(fn depth ->
    describe "generate/2 for RGB #{depth}" do
      @describetag type: :rgb, depth: depth

      @sizes
      |> Enum.map(&{&1, &1, "rgb/depth#{depth}/#{&1}x#{&1}.png"})
      |> Enum.each(fn {width, height, expected_image} ->
        @tag width: width, height: height, expected_image: expected_image
        test "list of integers (#{width}x#{height})", context do
          data =
            Enum.flat_map(0..(context.width * context.height - 1), fn n ->
              {r, g, b} = TestPixel.get_rgb(context, n)
              [r, g, b]
            end)

          actual =
            context.pngex
            |> Pngex.generate(data)
            |> :erlang.iolist_to_binary()

          assert context.expected == actual
        end

        @tag width: width, height: height, expected_image: expected_image
        test "list of RGB color (#{width}x#{height})", context do
          data =
            Enum.map(0..(context.width * context.height - 1), fn n ->
              TestPixel.get_rgb(context, n)
            end)

          actual =
            context.pngex
            |> Pngex.generate(data)
            |> :erlang.iolist_to_binary()

          assert context.expected == actual
        end

        @tag width: width, height: height, expected_image: expected_image
        test "binary (#{width}x#{height})", %{depth: depth} = context do
          data =
            for n <- 0..(context.width * context.height - 1), into: <<>> do
              {r, g, b} = TestPixel.get_rgb(context, n)
              <<r::size(depth), g::size(depth), b::size(depth)>>
            end

          actual =
            context.pngex
            |> Pngex.generate(data)
            |> :erlang.iolist_to_binary()

          assert context.expected == actual
        end
      end)
    end
  end)
end
