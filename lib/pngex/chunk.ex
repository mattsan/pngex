defmodule Pngex.Chunk do
  @moduledoc false

  @spec build(String.t(), iolist() | binary()) :: iolist()
  def build(type, data) do
    length = :erlang.iolist_size(data)
    crc = :erlang.crc32([type, data])

    [
      <<length::big-size(32)>>,
      type,
      data,
      <<crc::big-size(32)>>
    ]
  end
end
