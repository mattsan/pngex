defmodule Pngex.Raster do
  @moduledoc false

  import Pngex, only: [bit_depth_to_value: 1, is_color_type: 1]

  def generate(%Pngex{} = pngex, data) when is_binary(data) do
    row_size = pngex.width * bit_depth_to_value(pngex.depth) * bytes_par_pixel(pngex.type)

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

  def generate(%Pngex{} = pngex, data) when is_list(data) do
    data
    |> list_to_pixels(pngex)
    |> Enum.chunk_every(pngex.width)
    |> Enum.map(&[pngex.scanline_filter | &1])
  end

  defp bytes_par_pixel(type) when is_color_type(type) do
    case type do
      :gray -> 1
      :rgb -> 3
      :indexed -> 1
      :gray_and_alpha -> 2
      :rgba -> 4
    end
  end

  @spec list_to_pixels(Pngex.data(), Pngex.t()) :: iolist()
  defp list_to_pixels([{_r, _g, _b} | _] = data, %Pngex{type: :rgb, depth: depth}) do
    bit_depth = bit_depth_to_value(depth)

    for {r, g, b} <- data do
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :rgb, depth: depth}) when is_list(data) do
    bit_depth = bit_depth_to_value(depth)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [r, g, b | rest] ->
        {<<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels([{_r, _g, _b, _a} | _] = data, %Pngex{type: :rgba, depth: depth}) do
    bit_depth = bit_depth_to_value(depth)

    for {r, g, b, a} <- data do
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth), a::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :rgba, depth: depth}) when is_list(data) do
    bit_depth = bit_depth_to_value(depth)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [r, g, b, a | rest] ->
        {<<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth), a::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels(data, %Pngex{type: :gray, depth: depth}) when is_list(data) do
    bit_depth = bit_depth_to_value(depth)

    for n <- data do
      <<n::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :gray_and_alpha, depth: depth}) when is_list(data) do
    bit_depth = bit_depth_to_value(depth)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [n, a | rest] ->
        {<<n::size(bit_depth), a::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels(data, %Pngex{type: :indexed, depth: depth}) when is_list(data) do
    bit_depth = bit_depth_to_value(depth)

    Enum.map(data, &<<&1::size(bit_depth)>>)
  end
end
