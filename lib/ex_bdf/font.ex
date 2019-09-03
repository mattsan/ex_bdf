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
        <<row::size(width), _::bitstring>> =
          <<0::size(bbx_offset_x), bdf_row::size(bbx_width), 0>>

        row
      end)

    height = Enum.count(bitmap)

    %Font{code: code, width: width, height: height, bbx: bbx, bitmap: bitmap}
  end

  def bitmap(%Font{} = font, foreground \\ <<1::1>>, background \\ <<0::1>>)
      when is_binary(foreground) and is_binary(background) do
    width = font.width

    font.bitmap
    |> Enum.map(fn bits ->
      for <<(bit::1 <- <<bits::size(width)>>)>>, into: "" do
        case bit do
          0 -> background
          1 -> foreground
        end
      end
    end)
  end

  def string_to_bitmap(str, foreground \\ <<1::1>>, background \\ <<0::1>>)
      when is_binary(str) and is_binary(foreground) and is_binary(background) do
    fonts =
      str
      |> String.to_charlist()
      |> Enum.map(&ExBDF.get_font/1)
      |> Enum.filter(&(not is_nil(&1)))

    {bottom, top} =
      fonts
      |> Enum.reduce({0, 0}, fn font, {bottom, top} ->
        {
          Enum.min([bottom, font.bbx.offset_y]),
          Enum.max([top, font.bbx.height + font.bbx.offset_y - 1])
        }
      end)

    fonts
    |> Enum.map(fn font ->
      width = font.width
      padding_bottom = font.bbx.offset_y - bottom
      padding_top = top - (font.bbx.height + font.bbx.offset_y - 1)

      (List.duplicate(0, padding_top) ++ font.bitmap ++ List.duplicate(0, padding_bottom))
      |> Enum.map(&<<&1::size(width)>>)
    end)
    |> Enum.zip()
    |> Enum.map(fn row ->
      line =
        row
        |> Tuple.to_list()
        |> Enum.into("")

      for <<bit::1 <- line>>, into: "" do
        case bit do
          1 -> foreground
          0 -> background
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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @font_files Keyword.get(opts, :fonts, [])
      @conversion Keyword.get(opts, :conversion)
      @fonts Parser.load!(@font_files, conversion: @conversion)

      def font_files, do: @font_files
      def conversion, do: @conversion
      def fonts, do: @fonts
    end
  end
end
