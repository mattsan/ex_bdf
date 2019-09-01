defmodule ExBDF.Font do
  defstruct [:code, :width, :height, :bbx, :bitmap]

  alias ExBDF.{Font, Parser}

  def new(code, 0, bbx, bitmap) do
    %Font{code: code, width: 0, height: Enum.count(bitmap), bbx: bbx, bitmap: bitmap}
  end

  def new(code, width, bbx, bdf_bitmap) do
    {bbx_offset_x, bbx_width} =
      if bbx.offset_x >= 0 do
        {bbx.offset_x, div(bbx.width + 7, 8) * 8}
      else
        {0, div(bbx.width - bbx.offset_x + 7, 8) * 8}
      end

    bitmap =
      bdf_bitmap
      |> Enum.map(fn bdf_row ->
        <<row::size(width), _::bitstring>> = <<0::size(bbx_offset_x), bdf_row::size(bbx_width), 0>>
        row
      end)

    height = Enum.count(bitmap)

    %Font{code: code, width: width, height: height, bbx: bbx, bitmap: bitmap}
  end

  def load(filename, opts \\ []) when is_list(opts) do
    File.open(filename, &Parser.parse(&1, opts))
  end

  def bitmap(%Font{} = font, foreground \\ <<1::1>>, background \\ <<0::1>>) do
    width = font.width

    font.bitmap
    |> Enum.map(fn bits ->
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
