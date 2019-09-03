defmodule ExBDF.Server do
  use GenServer

  alias ExBDF.Parser

  @name ExBDF

  def start_link(opts) do
    font_files = Keyword.get(opts, :fonts, [])
    conversion = Keyword.get(opts, :conversion)
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

  def load_fonts(name \\ @name, font_files, opts) when is_list(font_files) and is_list(opts) do
    GenServer.cast(name, {:load_fonts, font_files, opts})
  end

  def init(state) do
    GenServer.cast(self(), :load_fonts)

    {:ok, state}
  end

  def handle_cast(:load_fonts, %{font_files: font_files, conversion: conversion} = state) when is_list(font_files) do
    fonts = Parser.load!(font_files, conversion: conversion)

    {:noreply, Map.put(state, :fonts, fonts)}
  end

  def handle_cast(:load_fonts, %{font_files: font_module} = state) when is_atom(font_module) do
    fonts = apply(font_module, :fonts, [])
    font_files = apply(font_module, :font_files, [])
    conversion = apply(font_module, :conversion, [])

    {:noreply, Map.merge(state, %{fonts: fonts, font_files: font_files, conversion: conversion, font_module: font_module})}
  end

  def handle_cast({:load_fonts, font_files, opts}, state) do
    conversion = Keyword.get(opts, :conversion)
    GenServer.cast(self(), :load_fonts)

    {:noreply, %{state | font_files: font_files, conversion: conversion}}
  end

  def handle_call({:get_font, code}, _from, state) do
    {:reply, state.fonts[code], state}
  end
end
