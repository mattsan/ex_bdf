defmodule ExBDF.Font do
  defstruct [:code, :width, :height, :bbx, :bitmap]

  alias ExBDF.{Font, Parser}

  def load(filename, opts \\ []) when is_list(opts) do
    File.open(filename, &Parser.parse(&1, opts))
  end

  def bitmap(%Font{} = font, foreground \\ <<1::1>>, background \\ <<0::1>>) do
    width = font.width
    row_width = ceil(width / 8) * 8

    font.bitmap
    |> Enum.map(fn row ->
      <<bits::size(width), _::bitstring>> = <<row::size(row_width)>>
      for <<bit::1 <- <<bits::size(width)>> >>, into: "" do
        case bit do
          0 -> background
          1 -> foreground
        end
      end
    end)
  end

  def show_bitmap_image(%Font{} = font) do
    font
    |> IO.inspect()

    bitmap(font, "[]", " .")
    |> Enum.each(&IO.puts/1)
  end
end
