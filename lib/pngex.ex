defmodule Pngex do
  @moduledoc """
  Generates PNG images.
  """

  alias Pngex.{Chunk, Bitmap, Zip}

  @scanline_filter_none 0

  defstruct type: :rgb,
            depth: :depth8,
            width: 0,
            height: 0,
            palette: [],
            scanline_filter: @scanline_filter_none

  @typedoc """
  PNG color type.

  - `:gray` - grayscale
  - `:rgb` - RGB color
  - `:indexed` - palette color
  - `:gray_and_alpha` - grayscale and alpha
  - `:rgba` - RGB color and alpha
  """
  @type color_type :: :gray | :rgb | :indexed | :gray_and_alpha | :rgba

  @typedoc """
  Bit depth.

  - `:depth1` - 1 bits
  - `:depth2` - 2 bits
  - `:depth4` - 4 bits
  - `:depth8` - 8 bits
  - `:depth16` - 16 bits
  """
  @type bit_depth :: :depth1 | :depth2 | :depth4 | :depth8 | :depth16

  @typedoc """
  Positive 32-bit integer.

  It's for width and height.
  """
  @type pos_int32 :: 1..0xFF_FF_FF_FF

  @typedoc """
  Data type of RGB color.

  A tuple of red, green and blue values.
  """
  @type rgb_color :: {r :: pos_integer(), g :: pos_integer(), b :: pos_integer()}

  @typedoc """
  Data type of RGB color and alpha.

  A tuple of red, green, blue and alpha values.
  """
  @type rgba_color ::
          {r :: pos_integer(), g :: pos_integer(), b :: pos_integer(), a :: pos_integer()}

  @typedoc """
  Image data.

  ## RGB

  | type             | example                             |
  |------------------|-------------------------------------|
  | binary           | `<<r0, g0, b0, r1, g1, b1, ...>>`   |
  | list of integers | `[r0, g0, b0, r1, g1, b1, ...]`     |
  | list of tuples   | `[{r0, g0, b0}, {r1, g1, b1}, ...]` |

  ## RGB and Alpha

  | type             | example                                     |
  |------------------|---------------------------------------------|
  | binary           | `<<r0, g0, b0, a0, r1, g1, b1, a1, ...>>`   |
  | list of integers | `[r0, g0, b0, a0, r1, g1, b1, a1, ...]`     |
  | list of tuples   | `[{r0, g0, b0, a0}, {r1, g1, b1, a1}, ...]` |

  ## Grayscale

  | type             | example             |
  |------------------|---------------------|
  | binary           | `<<c0, c1, ...>>`   |
  | list of integers | `[c0, c1, ...]`     |

  ## Grayscale and Alpha

  | type             | example                     |
  |------------------|-----------------------------|
  | binary           | `<<c0, a0, c1, a1, ...>>`   |
  | list of integers | `[c0, a0, c1, a1, ...]`     |

  ## Indexed

  | type             | example             |
  |------------------|---------------------|
  | binary           | `<<c0, c1, ...>>`   |
  | list of integers | `[c0, c1, ...]`     |

  ## Depth of binary

  If you use binaries, you may need to use size options.

  | depth      | example                                                  |
  |------------|----------------------------------------------------------|
  | `:depth1`  | `<<c0::size(1), c1::size(1), ...>>`                      |
  | `:depth2`  | `<<c0::size(2), c1::size(2), ...>>`                      |
  | `:depth4`  | `<<c0::size(4), c1::size(4), ...>>`                      |
  | `:depth8`  | `<<c0, c1, ...>>` or `<<c0::size(8), c1::size(8), ...>>` |
  | `:depth16` | `<<c0::size(16), c1::size(16), ...>>`                    |
  """
  @type data :: binary() | [pos_integer()] | [rgb_color()] | [rgba_color()]

  @typedoc """
  Type of filtering.

  - `0` - None
  - `1` - Sub
  - `2` - Up
  - `3` - Average
  - `4` - Paeth

  see: https://en.wikipedia.org/wiki/Portable_Network_Graphics#Filtering
  """
  @type scanline_filter :: 0 | 1 | 2 | 3 | 4

  @typedoc """
  Configurations for PNG image.
  """
  @type t :: %__MODULE__{
          type: color_type(),
          depth: bit_depth(),
          width: pos_int32(),
          height: pos_int32(),
          palette: [rgb_color()],
          scanline_filter: scanline_filter()
        }

  defguardp is_color_type(type) when type in [:gray, :rgb, :indexed, :gray_and_alpha, :rgba]
  defguardp is_bit_depth(depth) when depth in [:depth1, :depth2, :depth4, :depth8, :depth16]
  defguardp is_pos_int32(value) when is_integer(value) and value > 0 and value < 0x1_00_00_00_00
  defguardp is_uint(n) when is_integer(n) and n >= 0

  @doc false
  @spec color_type_to_value(t()) :: 0 | 2 | 3 | 4 | 6
  def color_type_to_value(%Pngex{type: type}) when is_color_type(type) do
    case type do
      :gray -> 0
      :rgb -> 2
      :indexed -> 3
      :gray_and_alpha -> 4
      :rgba -> 6
    end
  end

  @doc false
  @spec bit_depth_to_value(t()) :: 1 | 2 | 4 | 8 | 16
  def bit_depth_to_value(%Pngex{depth: depth}) do
    case depth do
      :depth1 -> 1
      :depth2 -> 2
      :depth4 -> 4
      :depth8 -> 8
      :depth16 -> 16
    end
  end

  @doc """
  Creates a new Pngex structure.

  ## Options

  - `:type` - color type;
    - `:gray` - grayscale
    - `:rgb` - RGB (default)
    - `:indexed` - palette color
    - `:gray_and_alpha` - grayscale and alpha
    - `:rgba` - RGB and alpha
  - `:depth` - color depth; `:depth2`, `:depth4`, `:depth8` (default) or `:depth16`
  - `:width` - image width; 32-bit integer (1..4,294,967,295)
  - `:height` - image height; 32-bit integer (1..4,294,967,295)
  - `:palette` - palette table; list of RGB color tuples

  ## Examples

  ```elixir
  pngex =
    Pngex.new(
      type: :indexed,
      depth: :depth8,
      width: 640,
      height: 480,
      palette: [{0, 0, 0}, {255, 255, 255}]
    )
  ```
  """
  @spec new(keyword()) :: t() | {:error, keyword()}
  def new(opts \\ []) when is_list(opts) do
    Enum.reduce(opts, %{pngex: %Pngex{}, errors: []}, fn
      {:type, type}, acc when is_color_type(type) ->
        %{acc | pngex: %{acc.pngex | type: type}}

      {:depth, depth}, acc when is_bit_depth(depth) ->
        %{acc | pngex: %{acc.pngex | depth: depth}}

      {:width, width}, acc when is_pos_int32(width) ->
        %{acc | pngex: %{acc.pngex | width: width}}

      {:height, height}, acc when is_pos_int32(height) ->
        %{acc | pngex: %{acc.pngex | height: height}}

      {:palette, palette} = item, acc ->
        if is_valid_palette(palette) do
          %{acc | pngex: %{acc.pngex | palette: palette}}
        else
          %{acc | errors: [item | acc.errors]}
        end

      error, acc ->
        %{acc | errors: [error | acc.errors]}
    end)
    |> case do
      %{pngex: pngex, errors: []} -> pngex
      %{errors: errors} -> {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Sets color type.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_type(:gray)
  %Pngex{type: :gray}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_type(:monotone)
  {:error, invalid_type: :monotone}
  ```
  """
  @spec set_type(Pngex.t(), color_type()) :: Pngex.t() | {:error, invalid_type: any()}
  def set_type(%Pngex{} = pngex, type) when is_color_type(type) do
    %{pngex | type: type}
  end

  def set_type(%Pngex{}, type) do
    {:error, invalid_type: type}
  end

  @doc """
  Sets bit depth.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_depth(:depth16)
  %Pngex{depth: :depth16}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_depth(:depth15)
  {:error, invalid_depth: :depth15}
  ```
  """
  @spec set_depth(Pngex.t(), bit_depth()) :: Pngex.t() | {:error, invalid_depth: any()}
  def set_depth(%Pngex{} = pngex, depth) when is_bit_depth(depth) do
    %{pngex | depth: depth}
  end

  def set_depth(%Pngex{}, depth) do
    {:error, invalid_depth: depth}
  end

  @doc """
  Sets image width.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_width(128)
  %Pngex{width: 128}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_width(0)
  {:error, invalid_width: 0}
  ```
  """
  @spec set_width(t(), pos_int32()) :: t() | {:error, invalid_width: any()}
  def set_width(%Pngex{} = pngex, width) when is_pos_int32(width) do
    %{pngex | width: width}
  end

  def set_width(%Pngex{}, width) do
    {:error, invalid_width: width}
  end

  @doc """
  Sets image hieght.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_height(128)
  %Pngex{height: 128}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_height(0)
  {:error, invalid_height: 0}
  ```
  """
  @spec set_height(t(), pos_int32()) :: t() | {:error, invalid_height: any()}
  def set_height(%Pngex{} = pngex, height) when is_pos_int32(height) do
    %{pngex | height: height}
  end

  def set_height(%Pngex{}, hieght) do
    {:error, invalid_height: hieght}
  end

  @doc """
  Sets image width and height.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_size(640, 480)
  %Pngex{width: 640, height: 480}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_size(0, 480)
  {:error, invalid_size: %{width: 0}}
  ```
  """
  @spec set_size(t(), pos_int32(), pos_int32()) :: t() | {:error, invalid_size: map()}
  def set_size(%Pngex{} = pngex, width, height) do
    case {is_pos_int32(width), is_pos_int32(height)} do
      {true, true} -> %{pngex | width: width, height: height}
      {false, true} -> {:error, invalid_size: %{width: width}}
      {true, false} -> {:error, invalid_size: %{height: height}}
      {false, false} -> {:error, invalid_size: %{width: width, height: height}}
    end
  end

  @doc """
  Sets a palette.

  ## Examples

  ```elixir
  iex> Pngex.new() |> Pngex.set_palette([{0, 0, 0}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}])
  %Pngex{palette: [{0, 0, 0}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}]}
  ```

  ```elixir
  iex> Pngex.new() |> Pngex.set_palette([0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255])
  {:error, invalid_palette: [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255]}
  ```
  """
  @spec set_palette(t(), [rgb_color()]) :: t() | {:error, invalid_palette: any()}
  def set_palette(%Pngex{} = pngex, palette) do
    if is_valid_palette(palette) do
      %{pngex | palette: palette}
    else
      {:error, invalid_palette: palette}
    end
  end

  @magic_number [0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A]
  @compression_method 0
  @filter_method 0
  @interlace_method 0

  @doc """
  Generates a PNG image.

  ## Examples

  ```elixir
  image =
    Pngex.new(type: :rgb, depth: :depth8, width: 16, height: 16)
    |> Pngex.generate(for(c <- 0..255, do: {c, 255 - c, 0}))

  File.write("image.png", image)
  ```
  """
  @spec generate(t(), data()) :: iolist()
  def generate(%Pngex{} = pngex, data) do
    header = <<
      pngex.width::32,
      pngex.height::32,
      bit_depth_to_value(pngex),
      color_type_to_value(pngex),
      @compression_method,
      @filter_method,
      @interlace_method
    >>

    bitmap = Bitmap.build(pngex, data)

    ihdr = Chunk.build("IHDR", header)
    idat = Chunk.build("IDAT", Zip.compress(bitmap))
    iend = Chunk.build("IEND", "")

    case pngex do
      %Pngex{type: :indexed} ->
        plte = Chunk.build("PLTE", for({r, g, b} <- pngex.palette, do: <<r, g, b>>))

        [@magic_number, ihdr, plte, idat, iend]

      _ ->
        [@magic_number, ihdr, idat, iend]
    end
  end

  defp is_valid_palette(palette) do
    case palette do
      [] ->
        true

      [{r, g, b} | rest] when is_uint(r) and is_uint(g) and is_uint(b) ->
        is_valid_palette(rest)

      _ ->
        false
    end
  end
end
