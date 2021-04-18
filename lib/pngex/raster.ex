defmodule Pngex.Raster do
  import Pngex, only: [bit_depth_to_value: 1]

  def generate(%Pngex{} = pngex, data) when is_list(data) do
    data
    |> list_to_pixels(pngex)
    |> Enum.chunk_every(pngex.width)
    |> Enum.map(&[pngex.scanline_filter | &1])
  end

  def generate(%Pngex{} = pngex, data) when is_binary(data) do
    row_size = pngex.width * bit_depth_to_value(pngex.depth) * 3

    Stream.unfold(data, fn
      <<row::size(row_size), rest::binary>> ->
        {<<pngex.scanline_filter, row::size(row_size)>>, rest}

      <<row>> ->
        {<<pngex.scanline_filter, row>>, <<>>}

      <<>> ->
        nil
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels([], _) do
    []
  end

  defp list_to_pixels([{r, g, b} | rest], %Pngex{depth: depth} = pngex) do
    color_depth = bit_depth_to_value(depth)
    pixel = <<r::size(color_depth), g::size(color_depth), b::size(color_depth)>>

    [pixel | list_to_pixels(rest, pngex)]
  end

  defp list_to_pixels([r, g, b | rest], %Pngex{depth: depth} = pngex) do
    color_depth = bit_depth_to_value(depth)
    pixel = <<r::size(color_depth), g::size(color_depth), b::size(color_depth)>>

    [pixel | list_to_pixels(rest, pngex)]
  end
end
