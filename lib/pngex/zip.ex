defmodule Pngex.Zip do
  @moduledoc false

  @spec compress(iodata()) :: iolist()
  def compress(data) do
    zip = :zlib.open()
    :ok = :zlib.deflateInit(zip)
    compressed = :zlib.deflate(zip, data, :finish)
    :ok = :zlib.deflateEnd(zip)
    :ok = :zlib.close(zip)

    compressed
  end

  @spec decompress(iodata()) :: iolist()
  def decompress(data) do
    zip = :zlib.open()
    :ok = :zlib.inflateInit(zip)
    decompressed = :zlib.inflate(zip, data)
    :ok = :zlib.inflateEnd(zip)
    :ok = :zlib.close(zip)

    decompressed
  end
end
