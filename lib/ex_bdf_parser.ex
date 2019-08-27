defmodule ExBDFParser do
  @moduledoc """
  Documentation for ExBDFParser.
  """

  alias ExBDFParser.Parser

  def load(filename, conversion \\ nil) do
    File.open(filename, &Parser.parse(&1, conversion))
  end

  def show_bitmap_image(fonts, code) do
    fonts[code]
    |> IO.inspect()

    fonts[code].bitmap
    |> Enum.each(fn bitmap ->
      bitmap
      |> Integer.to_string(2)
      |> String.pad_leading(16, "0")
      |> String.replace("0", "  ")
      |> String.replace("1", "[]")
      |> IO.puts()
    end)
  end
end
