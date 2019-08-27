defmodule ExBDFParser do
  @moduledoc """
  Documentation for ExBDFParser.
  """

  alias ExBDFParser.Parser

  def load(filename, conversion \\ nil) do
    File.open(filename, &Parser.parse(&1, conversion))
  end
end
