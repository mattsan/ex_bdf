defmodule ExBDF do
  @moduledoc """
  Documentation for ExBDF.
  """

  alias ExBDF.{Parser, Font}

  def load(filename, opts \\ []) when is_list(opts) do
    File.open(filename, &Parser.parse(&1, opts))
  end

  def show_bitmap_image(fonts, code) do
    case fonts[code] do
      nil ->
        IO.puts("#{code} (#{Integer.to_string(code, 16)}h) is not defined")

      font ->
        show_bitmap_image(font)
    end
  end

  def show_bitmap_image(%Font{} = font) do
    font
    |> IO.inspect()

    font.bitmap
    |> Enum.each(fn bitmap ->
      bitmap
      |> Integer.to_string(2)
      |> String.pad_leading(ceil(font.bbx.width / 8) * 8, "0")
      |> String.pad_trailing(ceil(font.width / 8) * 8, "0")
      |> String.slice(0, font.width)
      |> String.replace("0", " .")
      |> String.replace("1", "[]")
      |> IO.puts()
    end)
  end
end
