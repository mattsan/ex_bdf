defmodule ExBDFParser.Server do
  use GenServer

  @name ExBDFParser

  def start_link(opts) do
    font_files = Keyword.get(opts, :fonts, [])
    conversion = Keyword.get(opts, :conversion, :jis2unicode)
    name = Keyword.get(opts, :name, @name)

    state = %{
      font_files: font_files,
      conversion: conversion
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def get_font(name \\ @name, code) do
    GenServer.call(name, {:get_font, code})
  end

  def init(state) do
    GenServer.cast(@name, :load_fonts)

    {:ok, state}
  end

  def handle_cast(:load_fonts, state) do
    fonts =
      state.font_files
      |> Enum.reduce(%{}, fn filename, fonts ->
        {:ok, new_fonts} = ExBDFParser.load(filename, conversion: state.conversion, into: fonts)
        new_fonts
      end)

    {:noreply, Map.put(state, :fonts, fonts)}
  end

  def handle_call({:get_font, code}, _from, state) do
    {:reply, state.fonts[code], state}
  end
end
