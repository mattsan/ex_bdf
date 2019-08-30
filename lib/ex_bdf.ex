defmodule ExBDF do
  @moduledoc """
  Documentation for ExBDF.
  """

  @name __MODULE__

  defdelegate get_font(name \\ @name, code), to: ExBDF.Server
  defdelegate bitmap(font, foreground \\ <<1::1>>, background \\ <<0::1>>), to: ExBDF.Font
end
