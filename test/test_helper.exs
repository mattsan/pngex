import Bitwise

defmodule GrayscalePixel do
  def get_color(%{width: width, height: height, depth: 16}, n) do
    rem(rem(n, width) * 256 + 255 + div(n, height) * 256 + 255, 1 <<< 16)
  end

  def get_color(%{width: width, height: height, depth: depth}, n) do
    rem(rem(n, width) + div(n, height), 1 <<< depth)
  end

  def get_alpha(%{width: width, height: height, depth: 16}, n) do
    x = rem(n, width) / width
    y = div(n, width) / height

    if 0.25 <= x && x < 0.75 && 0.25 <= y && y < 0.75 do
      (1 <<< 16) - 1
    else
      0
    end
  end

  def get_alpha(%{width: width, height: height, depth: depth}, n) do
    x = rem(n, width) / width
    y = div(n, width) / height

    if 0.25 <= x && x < 0.75 && 0.25 <= y && y < 0.75 do
      (1 <<< depth) - 1
    else
      0
    end
  end
end

ExUnit.start()
