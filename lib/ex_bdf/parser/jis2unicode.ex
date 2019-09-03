defmodule ExBDF.Parser.Jis2Unicode do
  import String, only: [to_integer: 2]

  # see http://x0213.org/codetable/jisx0213-2004-8bit-std.txt
  @table_file "priv/codetable/jisx0213-2004-8bit-std.txt"
  @table File.open!(@table_file, fn file ->
           Stream.repeatedly(fn ->
             case IO.read(file, :line) do
               :eof ->
                 :eof

               <<"0x", jis::32, "\tU+", unicode::32, _::bits>> ->
                 {to_integer(<<jis::32>>, 16), to_integer(<<unicode::32>>, 16)}

               <<"0x", jis::32, "\tU+", unicode::36, _::bits>> ->
                 {to_integer(<<jis::32>>, 16), to_integer(<<unicode::36>>, 16)}

               s when is_binary(s) ->
                 nil
             end
           end)
           |> Stream.filter(&(&1 != nil))
           |> Stream.take_while(&(&1 != :eof))
           |> Enum.into(%{})
           |> Map.merge(for c <- 0x20..0xFE, into: %{}, do: {c, c})
         end)

  def convert(jis) do
    @table[jis]
  end
end
