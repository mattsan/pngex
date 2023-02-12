import Bitwise

defmodule TestPixel do
  defmodule RGB do
    def get(%{width: width, height: height, depth: 8}, n) do
      r = div(n, width)
      g = rem(n, height)
      b = 0xFF - max(r, g)
      {r, g, b}
    end

    def get(%{width: width, height: height, depth: 16}, n) do
      r = div(n, width) <<< 8
      g = rem(n, height) <<< 8
      b = 0xFFFF - max(r, g)
      {r, g, b}
    end
  end

  defmodule Grayscale do
    def get(%{width: width, height: height, depth: 16}, n) do
      rem((rem(n, width) <<< 8) + 0xFF + (div(n, height) <<< 8) + 0xFF, 1 <<< 16)
    end

    def get(%{width: width, height: height, depth: depth}, n) when depth in [1, 2, 4, 8] do
      rem(rem(n, width) + div(n, height), 1 <<< depth)
    end
  end

  defmodule Palette do
    def get(%{depth: 8}) do
      Enum.map(0..0xFF, fn n ->
        r = div(n, 0x10) <<< (4 + 0x0F)
        g = rem(n, 0x10) <<< (4 + 0x0F)
        b = 0xFF - max(r, g)
        {r, g, b}
      end)
    end

    def get(%{depth: 4}) do
      Enum.map(0..0x0F, fn n ->
        r = div(n, 0x04) <<< (6 + 0x3F)
        g = rem(n, 0x04) <<< (6 + 0x3F)
        b = 0xFF - max(r, g)
        {r, g, b}
      end)
    end

    def get(%{depth: 2}) do
      [
        {0x00, 0x00, 0xFF},
        {0x00, 0xFF, 0x00},
        {0xFF, 0x00, 0x00},
        {0xFF, 0xFF, 0x00}
      ]
    end

    def get(%{depth: 1}) do
      [
        {0x00, 0x00, 0xFF},
        {0xFF, 0xFF, 0x00}
      ]
    end
  end

  defmodule ColorIndex do
    def get(%{depth: 8}, x, y) do
      div(y, 0x10) <<< (16 + div(x, 0x10))
    end

    def get(%{depth: 4}, x, y) do
      div(y, 0x40) <<< (2 + div(x, 0x40))
    end

    def get(%{depth: 2}, x, y) do
      div(y, 0x80) <<< (1 + div(x, 0x80))
    end

    def get(%{depth: 1}, x, y) do
      if x + y < 0x100 do
        0
      else
        1
      end
    end
  end

  defmodule Alpha do
    def get(%{width: width, height: height, depth: depth}, n) when depth in [8, 16] do
      x = rem(n, width) / width
      y = div(n, width) / height

      if 0.25 <= x && x < 0.75 && 0.25 <= y && y < 0.75 do
        (1 <<< depth) - 1
      else
        0
      end
    end
  end
end

ExUnit.start()
