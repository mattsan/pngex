defmodule Pngex.Bitmap do
  @moduledoc false

  import Pngex, only: [bit_depth_to_value: 1]

  @bytes_par_pixel %{
    gray: 1,
    rgb: 3,
    indexed: 1,
    gray_and_alpha: 2,
    rgba: 4
  }

  @spec build(Pngex.t(), Pngex.data()) :: iolist()
  def build(%Pngex{} = pngex, data) when is_bitstring(data) do
    row_size = pngex.width * bit_depth_to_value(pngex) * @bytes_par_pixel[pngex.type]
    padding_size = padding_size_for_byte_boundary(row_size)

    Stream.unfold(data, fn
      <<>> ->
        nil

      <<row::size(row_size), rest::bitstring>> ->
        {<<pngex.scanline_filter, row::size(row_size), 0::size(padding_size)>>, rest}

      row ->
        padding_size = padding_size_for_byte_boundary(bit_size(row))
        {<<pngex.scanline_filter, row::bitstring, 0::size(padding_size)>>, <<>>}
    end)
    |> Enum.to_list()
  end

  def build(%Pngex{} = pngex, data) when is_list(data) do
    data
    |> list_to_pixels(pngex)
    |> Enum.map(&[pngex.scanline_filter | &1])
  end

  @spec list_to_pixels(Pngex.data(), Pngex.t()) :: iolist()
  defp list_to_pixels(data, %Pngex{type: :rgb} = pngex) when is_list(data) do
    data =
      case data do
        [{_r, _g, _b} | _] -> data
        _ -> Stream.chunk_every(data, 3)
      end

    data
    |> Stream.map(&color_to_binary(&1, bit_depth_to_value(pngex)))
    |> Enum.chunk_every(pngex.width)
  end

  defp list_to_pixels(data, %Pngex{type: :rgba} = pngex) do
    data =
      case data do
        [{_r, _g, _b, _a} | _] -> data
        _ -> Stream.chunk_every(data, 4)
      end

    data
    |> Stream.map(&color_to_binary(&1, bit_depth_to_value(pngex)))
    |> Enum.chunk_every(pngex.width)
  end

  defp list_to_pixels(data, %Pngex{type: :gray_and_alpha} = pngex) when is_list(data) do
    depth = bit_depth_to_value(pngex)

    data
    |> Stream.chunk_every(2)
    |> Stream.map(fn [n, a] -> <<n::size(depth), a::size(depth)>> end)
    |> Enum.chunk_every(pngex.width)
  end

  defp list_to_pixels(data, %Pngex{type: type} = pngex)
       when type in [:gray, :indexed] and is_list(data) do
    depth = bit_depth_to_value(pngex)

    cond do
      pngex.depth in [:depth1, :depth2, :depth4] ->
        padding_size = padding_size_for_byte_boundary(pngex.width * depth)

        data
        |> Stream.chunk_every(pngex.width)
        |> Enum.map(fn chunk ->
          pixels = for(n <- chunk, into: <<>>, do: <<n::size(depth)>>)
          <<pixels::bitstring, 0::size(padding_size)>>
        end)

      pngex.depth in [:depth8, :depth16] ->
        data
        |> Enum.chunk_every(pngex.width)
        |> Enum.map(fn chunk ->
          for n <- chunk, into: <<>>, do: <<n::size(depth)>>
        end)
    end
  end

  @spec color_to_binary(
          Pngex.rgb_color() | Pngex.rgba_color() | [non_neg_integer()],
          non_neg_integer()
        ) :: binary()
  defp color_to_binary(color, depth) do
    case color do
      {r, g, b} -> <<r::size(depth), g::size(depth), b::size(depth)>>
      [r, g, b] -> <<r::size(depth), g::size(depth), b::size(depth)>>
      {r, g, b, a} -> <<r::size(depth), g::size(depth), b::size(depth), a::size(depth)>>
      [r, g, b, a] -> <<r::size(depth), g::size(depth), b::size(depth), a::size(depth)>>
    end
  end

  @spec padding_size_for_byte_boundary(non_neg_integer()) :: 0..7
  defp padding_size_for_byte_boundary(n) when is_integer(n) and n >= 0 do
    rem(8 - rem(n, 8), 8)
  end
end
