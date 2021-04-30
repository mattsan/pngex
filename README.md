# Pngex

A library for generating PNG images.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pngex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pngex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pngex](https://hexdocs.pm/pngex).

## Generates images

### Pixel data

Use binary, list of integers or list of tuples to express pixel data of the image.

#### Binary

| type              | example                                   |
|-------------------|-------------------------------------------|
| `:rgb`            | `<<r0, g0, b0, r1, g1, b1, ...>>`         |
| `:rgba`           | `<<r0, g0, b0, a0, r1, g1, b1, a1, ...>>` |
| `:gray`           | `<<c0, c1, ...>`                          |
| `:gray_and_alpha` | `<<c0, a0, c1, a1, ...>>`                 |
| `:indexed`        | `<<c0, c1, ...>`                          |

#### List of integers

| type              | example                                 |
|-------------------|-----------------------------------------|
| `:rgb`            | `[r0, g0, b0, r1, g1, b1, ...]`         |
| `:rgba`           | `[r0, g0, b0, a0, r1, g1, b1, a1, ...]` |
| `:gray`           | `[c0, c1, ...]`                         |
| `:gray_and_alpha` | `[c0, a0, c1, a1, ...]`                 |
| `:indexed`        | `[c0, c1, ...]`                         |

#### List of tuples

| type    | example                                     |
|---------|---------------------------------------------|
| `:rgb`  | `[{r0, g0, b0}, {r1, g1, b1}, ...]`         |
| `:rgba` | `[{r0, g0, b0, a0}, {r1, g1, b1, a1}, ...]` |

### Examples

#### RGB

##### Prepare bitmap image data

```elixir
bitmap =
  for n <- 0..65535 do
    r = div(n, 256)
    g = rem(n, 256)
    b = 255 - max(r, g)
    {r, g, b}
  end
```

##### Generate PNG image

```elixir
pngex =
  Pngex.new()
  |> Pngex.set_type(:rgb)
  |> Pngex.set_depth(:depth8)
  |> Pngex.set_size(256, 256)

image = Pngex.generate(pngex, bitmap)

File.write("rgb8_256x256.png", image)
```

or

```elixir
image =
  Pngex.new(
    type: :rgb,
    depth: :depth8,
    width: 256,
    height: 256
  )
  |> Pngex.generate(bitmap)

File.write("rgb8_256x256.png", image)
```

#### Indexed (Palette)

##### Prepare palette colors

```elixir
palette = for n <- 0..255, do: {n, 255, 255 - n}
```

##### Prepare bitmap image data

```elixir
bitmap = for n <- 0..65535, do: rem(n, 256)
```

##### Generate PNG image

```elixir
image =
  Pngex.new(
    type: :indexed,
    depth: :depth8,
    width: 256,
    height: 256,
    palette: palette
  )
  |> Pngex.generate(bitmap)

File.write("indexed8_256x256.png", image)
```

#### Grayscale

##### Prepare bitmap image data

```elixir
bitmap = for n <- 0..65535, do: rem(n, 256)
```

##### Generate PNG image

```elixir
image =
  Pngex.new(
    type: :gray,
    depth: :depth8,
    width: 256,
    height: 256
  )
  |> Pngex.generate(bitmap)

File.write("gray8_256x256.png", image)
```

## Avaiable formats

| type \ depth           | `:depth1` | `:depth2` | `:depth4` | `:depth8` | `:depth16` |
|------------------------|:---------:|:---------:|:---------:|:---------:|:----------:|
| `:indexed`             | v         | v         | v         | v         |            |
| `:grayscale`           | v         | v         | v         | v         | v          |
| `:grayscale_and_alpha` |           |           |           | v         | v          |
| `:rgb`                 |           |           |           | v         | v          |
| `:rgba`                |           |           |           | v         | v          |
