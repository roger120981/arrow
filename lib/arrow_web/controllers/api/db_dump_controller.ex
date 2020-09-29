defmodule ArrowWeb.API.DBDumpController do
  use ArrowWeb, :controller

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _pamas) do
    json(conn, Arrow.DBStructure.dump_data())
  end
end
