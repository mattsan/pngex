defmodule Pngex.Raster do
  @moduledoc false

  import Pngex, only: [bit_depth_to_value: 1]

  def generate(%Pngex{} = pngex, data) when is_bitstring(data) do
    row_size = pngex.width * bit_depth_to_value(pngex) * bytes_par_pixel(pngex)
    padding_size = rem(8 - rem(row_size, 8), 8)

    Stream.unfold(data, fn
      <<>> ->
        nil

      <<row::size(row_size), rest::bitstring>> ->
        {<<pngex.scanline_filter, row::size(row_size), 0::size(padding_size)>>, rest}

      row ->
        padding_size = rem(8 - rem(bit_size(row), 8), 8)
        {<<pngex.scanline_filter, row::bitstring, 0::size(padding_size)>>, <<>>}
    end)
    |> Enum.to_list()
  end

  def generate(%Pngex{} = pngex, data) when is_list(data) do
    width =
      case pngex.depth do
        :depth1 -> div(pngex.width + 7, 8)
        :depth2 -> div(pngex.width + 3, 4)
        :depth4 -> div(pngex.width + 1, 2)
        _ -> pngex.width
      end

    data
    |> list_to_pixels(pngex)
    |> Enum.chunk_every(width)
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
    |> Stream.chunk_every(3)
    |> Enum.map(fn [r, g, b] ->
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth)>>
    end)
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
    |> Stream.chunk_every(4)
    |> Enum.map(fn [r, g, b, a] ->
      <<r::size(bit_depth), g::size(bit_depth), b::size(bit_depth), a::size(bit_depth)>>
    end)
  end

  defp list_to_pixels(data, %Pngex{type: type, width: width} = pngex)
       when type in [:gray, :indexed] and is_list(data) do
    case bit_depth_to_value(pngex) do
      1 ->
        data
        |> Stream.chunk_every(width)
        |> Enum.flat_map(fn chunk ->
          chunk
          |> Stream.chunk_every(8)
          |> Enum.map(fn
            [n0, n1, n2, n3, n4, n5, n6, n7] ->
              <<n0::1, n1::1, n2::1, n3::1, n4::1, n5::1, n6::1, n7::1>>

            [n0, n1, n2, n3, n4, n5, n6] ->
              <<n0::1, n1::1, n2::1, n3::1, n4::1, n5::1, n6::1, 0::1>>

            [n0, n1, n2, n3, n4, n5] ->
              <<n0::1, n1::1, n2::1, n3::1, n4::1, n5::1, 0::2>>

            [n0, n1, n2, n3, n4] ->
              <<n0::1, n1::1, n2::1, n3::1, n4::1, 0::3>>

            [n0, n1, n2, n3] ->
              <<n0::1, n1::1, n2::1, n3::1, 0::4>>

            [n0, n1, n2] ->
              <<n0::1, n1::1, n2::1, 0::5>>

            [n0, n1] ->
              <<n0::1, n1::1, 0::6>>

            [n0] ->
              <<n0::1, 0::7>>
          end)
        end)

      2 ->
        data
        |> Stream.chunk_every(width)
        |> Enum.flat_map(fn chunk ->
          chunk
          |> Stream.chunk_every(4)
          |> Enum.map(fn
            [n0, n1, n2, n3] -> <<n0::2, n1::2, n2::2, n3::2>>
            [n0, n1, n2] -> <<n0::2, n1::2, n2::2, 0::2>>
            [n0, n1] -> <<n0::2, n1::2, 0::4>>
            [n0] -> <<n0::2, 0::6>>
          end)
        end)

      4 ->
        data
        |> Stream.chunk_every(width)
        |> Enum.flat_map(fn chunk ->
          chunk
          |> Stream.chunk_every(2)
          |> Enum.map(fn
            [n0, n1] -> <<n0::4, n1::4>>
            [n0] -> <<n0::4, 0::4>>
          end)
        end)

      bit_depth ->
        for(n <- data, do: <<n::size(bit_depth)>>)
    end
  end

  defp list_to_pixels(data, %Pngex{type: :gray_and_alpha} = pngex) when is_list(data) do
    bit_depth = bit_depth_to_value(pngex)

    data
    |> Stream.chunk_every(2)
    |> Enum.map(fn [n, a] ->
      <<n::size(bit_depth), a::size(bit_depth)>>
    end)
    |> Enum.to_list()
  end
end
