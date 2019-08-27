defmodule ExBDFParser do
  @moduledoc """
  Documentation for ExBDFParser.
  """

  alias ExBDFParser.Parser

  def load(filename) do
    File.open(filename, &Parser.parse/1)
  end
end
