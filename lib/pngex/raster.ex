defmodule Pngex.Raster do
  @moduledoc false

  import Pngex, only: [bit_depth_to_value: 1]

  def generate(%Pngex{} = pngex, data) when is_binary(data) do
    row_size = pngex.width * bit_depth_to_value(pngex) * bytes_par_pixel(pngex)

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

  defp bytes_par_pixel(%Pngex{type: type}) do
    case type do
      :gray -> 1
      :rgb -> 3
      :indexed -> 1
      :gray_and_alpha -> 2
      :rgba -> 4
    end
  end

  @spec list_to_pixels(Pngex.data(), Pngex.t()) :: iolist()
  defp list_to_pixels([{_r, _g, _b} | _] = data, %Pngex{type: :rgb} = pngex) do
    bit_depth = bit_depth_to_value(pngex)

    for {r, g, b} <- data do
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :rgb} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [r, g, b | rest] ->
        {<<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels([{_r, _g, _b, _a} | _] = data, %Pngex{type: :rgba} = pngex) do
    bit_depth = bit_depth_to_value(pngex)

    for {r, g, b, a} <- data do
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth), a::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :rgba} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [r, g, b, a | rest] ->
        {<<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth), a::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels(data, %Pngex{type: :gray} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    for n <- data do
      <<n::size(bit_depth)>>
    end
  end

  defp list_to_pixels(data, %Pngex{type: :gray_and_alpha} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    data
    |> Stream.unfold(fn
      [] ->
        nil

      [n, a | rest] ->
        {<<n::size(bit_depth), a::size(bit_depth)>>, rest}
    end)
    |> Enum.to_list()
  end

  defp list_to_pixels(data, %Pngex{type: :indexed} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    Enum.map(data, &<<&1::size(bit_depth)>>)
  end
end
