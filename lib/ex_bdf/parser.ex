defmodule ExBDF.Parser do
  alias ExBDF.Font
  alias ExBDF.Font.BBX
  alias ExBDF.Parser.Jis2Unicode

  def load(filename, opts \\ []) when is_binary(filename) and is_list(opts) do
    File.open(filename, &parse(&1, opts))
  end

  def load!(filename_or_filenames, opts \\ [])

  def load!(filename, opts) when is_binary(filename) and is_list(opts) do
    {:ok, fonts} = File.open(filename, &parse(&1, opts))
    fonts
  end

  def load!(filenames, opts) when is_list(filenames) and is_list(opts) do
    fonts = Keyword.get(opts, :into, %{})
    filenames
    |> Enum.reduce(fonts, fn filename, fonts ->
      load!(filename, [{:into, fonts} | opts])
    end)
  end

  def parse(io, opts \\ []) when is_list(opts) do
    conversion = Keyword.get(opts, :conversion)
    target = Keyword.get(opts, :into, %{})

    with :ok <- skip_header(io),
         {:ok, font_stream} <- read_all_fonts(io),
         fonts <- stream_to_fonts(font_stream, conversion, target),
         do: fonts
  end

  defp skip_header(io) do
    case IO.read(io, :line) do
      :eof ->
        {:error, :no_fonts}

      <<"CHARS ", _::binary>> ->
        :ok

      _ ->
        skip_header(io)
    end
  end

  defp read_all_fonts(io) do
    font_stream =
      Stream.repeatedly(fn ->
        case read_font(io) do
          %Font{} = font -> font
          _ -> nil
        end
      end)
      |> Stream.take_while(&(&1 != nil))

    {:ok, font_stream}
  end

  defp stream_to_fonts(stream, conversion, target) when is_map(target) do
    code_converter =
      case conversion do
        :jis2unicode ->
          fn %Font{code: code} = font -> {Jis2Unicode.convert(code), font} end

        _ ->
          fn %Font{code: code} = font -> {code, font} end
      end

    Enum.into(stream, target, code_converter)
  end

  defp read_font(io), do: read_font(io, :startchar)

  defp read_font(io, :startchar) do
    case IO.read(io, :line) do
      <<"STARTCHAR ", _::binary>> ->
        read_font(io, {:reading_declarations, %{}})

      error ->
        error
    end
  end

  defp read_font(io, {:reading_declarations, data}) when is_map(data) do
    case IO.read(io, :line) do
      <<"ENCODING ", code_s::binary>> ->
        code =
          code_s
          |> String.trim()
          |> String.to_integer()

        read_font(io, {:reading_declarations, Map.put(data, :code, code)})

      <<"DWIDTH ", width_s::binary>> ->
        width =
          width_s
          |> String.split()
          |> List.first()
          |> String.to_integer()

        read_font(io, {:reading_declarations, Map.put(data, :width, width)})

      <<"BBX ", bounding::binary>> ->
        [width, height, offset_x, offset_y] =
          Regex.run(~r"([\d-]+)\s+([\d-]+)\s+([\d-]+)\s+([\d-]+)", bounding)
          |> Enum.drop(1)
          |> Enum.map(&String.to_integer/1)

        bbx = %BBX{width: width, height: height, offset_x: offset_x, offset_y: offset_y}
        read_font(io, {:reading_declarations, Map.put(data, :bbx, bbx)})

      "BITMAP\n" ->
        case read_bitmap(io, []) do
          {:ok, bitmap} ->
            Font.new(data.code, data.width, data.bbx, bitmap)

          error ->
            error
        end

      line when is_binary(line) ->
        read_font(io, {:reading_declarations, data})

      error ->
        error
    end
  end

  defp read_bitmap(io, acc) do
    case IO.read(io, :line) do
      "ENDCHAR\n" ->
        {:ok, Enum.reverse(acc)}

      hex when is_binary(hex) ->
        n =
          hex
          |> String.trim()
          |> String.to_integer(16)
        read_bitmap(io, [n | acc])

      error ->
        error
    end
  end
end
