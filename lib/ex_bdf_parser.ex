defmodule ExBDFParser do
  @moduledoc """
  Documentation for ExBDFParser.
  """

  alias ExBDFParser.FontImage

  def load(filename) do
    File.open(filename, &parse/1)
  end

  def parse(file) do
    with :ok <- read_header(file),
         {:ok, fonts} <- read_all_fonts(file),
         do: fonts
  end

  def read_header(file) do
    case IO.read(file, :line) do
      :eof -> {:error, :no_fonts}
      <<"CHARS ", _::binary>> -> :ok
      _ -> read_header(file)
    end
  end

  def read_all_fonts(file) do
    Stream.unfold(file, fn file ->
      case read_font(file) do
        %FontImage{} = font -> {font, file}
        _ -> nil
      end
    end)
    |> Enum.into(%{}, fn %FontImage{code: code} = font -> {code, font} end)
  end

  def read_font(file) do
    with :ok <- read_startchar(file),
         {:ok, code} <- read_encoding(file),
         {:ok, width} <- read_dwidth(file),
         {:ok, bitmap} <- read_bitmap(file),
         do: %FontImage{code: code, width: width, height: Enum.count(bitmap), bitmap: bitmap}
  end

  defp read_startchar(file) do
    case IO.read(file, :line) do
      <<"STARTCHAR ", _::binary>> ->
        :ok

      error ->
        error
    end
  end

  defp read_encoding(file) do
    case IO.read(file, :line) do
      <<"ENCODING ", code::binary>> ->
        {:ok, code |> String.trim() |> String.to_integer()}

      error ->
        error
    end
  end

  defp read_dwidth(file) do
    case IO.read(file, :line) do
      <<"DWIDTH ", width::binary>> ->
        {:ok, width |> String.split() |> List.first() |> String.to_integer()}

      line when is_binary(line) ->
        read_dwidth(file)

      error ->
        error
    end
  end

  defp read_bitmap(file) do
    case IO.read(file, :line) do
      "BITMAP\n" ->
        bitmap =
          Stream.unfold(file, fn file ->
            case IO.read(file, :line) do
              "ENDCHAR\n" ->
                nil

              :eof ->
                nil

              {:error, _} ->
                nil

              hex ->
                {hex |> String.trim() |> String.to_integer(16), file}
            end
          end)
          |> Enum.to_list()

        {:ok, bitmap}

      line when is_binary(line) ->
        read_bitmap(file)

      error ->
        error
    end
  end
end
