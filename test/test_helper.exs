import Bitwise

defmodule TestPixel do
  def get_rgb(%{width: width, height: height, depth: 8}, n) do
    r = div(n, width)
    g = rem(n, height)
    b = 255 - max(r, g)
    {r, g, b}
  end

  def get_rgb(%{width: width, height: height, depth: 16}, n) do
    r = div(n, width) * 256
    g = rem(n, height) * 256
    b = 65535 - max(r, g)
    {r, g, b}
  end

  def get_grayscale(%{width: width, height: height, depth: 16}, n) do
    rem(rem(n, width) * 256 + 255 + div(n, height) * 256 + 255, 1 <<< 16)
  end

  def get_grayscale(%{width: width, height: height, depth: depth}, n) do
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
