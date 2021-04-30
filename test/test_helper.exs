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

  def get_color_index(%{depth: 8}, x, y) do
    div(y, 16) * 16 + div(x, 16)
  end

  def get_color_index(%{depth: 4}, x, y) do
    div(y, 64) * 4 + div(x, 64)
  end

  def get_color_index(%{depth: 2}, x, y) do
    div(y, 128) * 2 + div(x, 128)
  end

  def get_color_index(%{depth: 1}, x, y) do
    if x + y < 256 do
      0
    else
      1
    end
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
