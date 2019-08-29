defmodule ExBDF.Parser do
  alias ExBDF.{Font, Jis2Unicode}
  alias ExBDF.Font.BBX

  def parse(io, opts \\ []) when is_list(opts) do
    conversion = Keyword.get(opts, :conversion)
    target = Keyword.get(opts, :into, %{})

    with :ok <- read_header(io),
         {:ok, font_stream} <- read_all_fonts(io),
         fonts <- stream_to_fonts(font_stream, conversion, target),
         do: fonts
  end

  def stream_to_fonts(stream, conversion, target) when is_map(target) do
    conv =
      case conversion do
        :jis2unicode ->
          fn %Font{code: code} = font ->
            {Jis2Unicode.convert(code), font}
          end

        _ ->
          fn %Font{code: code} = font ->
            {code, font}
          end
      end

    Enum.into(stream, target, conv)
  end

  def read_header(io) do
    case IO.read(io, :line) do
      :eof -> {:error, :no_fonts}
      <<"CHARS ", _::binary>> -> :ok
      _ -> read_header(io)
    end
  end

  def read_all_fonts(io) do
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

  def read_font(io) do
    with :ok <- read_startchar(io),
         {:ok, code} <- read_encoding(io),
         {:ok, width} <- read_dwidth(io),
         {:ok, bbx} <- read_bbx(io),
         {:ok, bitmap} <- read_bitmap(io),
         do: %Font{code: code, width: width, height: Enum.count(bitmap), bbx: bbx, bitmap: bitmap}
  end

  defp read_startchar(io) do
    case IO.read(io, :line) do
      <<"STARTCHAR ", _::binary>> ->
        :ok

      error ->
        error
    end
  end

  defp read_encoding(io) do
    case IO.read(io, :line) do
      <<"ENCODING ", code::binary>> ->
        {:ok, code |> String.trim() |> String.to_integer()}

      error ->
        error
    end
  end

  defp read_dwidth(io) do
    case IO.read(io, :line) do
      <<"DWIDTH ", width::binary>> ->
        {:ok, width |> String.split() |> List.first() |> String.to_integer()}

      line when is_binary(line) ->
        read_dwidth(io)

      error ->
        error
    end
  end

  defp read_bbx(io) do
    case IO.read(io, :line) do
      <<"BBX ", bounding::binary>> ->
        [width, height, offset_x, offset_y] =
          Regex.run(~r"([\d-]+)\s+([\d-]+)\s+([\d-]+)\s+([\d-]+)", bounding)
          |> Enum.drop(1)
          |> Enum.map(&String.to_integer/1)
        {:ok, %BBX{width: width, height: height, offset_x: offset_x, offset_y: offset_y}}

      line when is_binary(line) ->
        read_bbx(io)

      error ->
        error
    end
  end

  defp read_bitmap(io) do
    case IO.read(io, :line) do
      "BITMAP\n" ->
        bitmap =
          Stream.repeatedly(fn ->
            case IO.read(io, :line) do
              "ENDCHAR\n" ->
                nil

              :eof ->
                nil

              {:error, _} ->
                nil

              hex ->
                hex
                |> String.trim()
                |> String.to_integer(16)
            end
          end)
          |> Stream.take_while(&(&1 != nil))
          |> Enum.to_list()

        {:ok, bitmap}

      line when is_binary(line) ->
        read_bitmap(io)

      error ->
        error
    end
  end
end
