defmodule Rect do
  use WebSockex
  require Logger

  @url "ws://127.0.0.1:32253"

  def start_link(_opts \\ []) do
    # 400エラー対策としてヘッダーを明示的に追加
    WebSockex.start_link(@url, __MODULE__, :no_state,
      extra_headers: [
        {"Host", "127.0.0.1:32253"}
      ]
    )
  end

  def handle_connect(_conn, state) do
    Logger.info("ResoniteLinkに接続成功！")
    {:ok, state}
  end

  def start() do
    {:ok, pid} = start_link()
    make(pid)
  end

  def make(pid) do
    msg = """
    {
        "$type" : "addSlot",
        "data" : {
            "id" : "ymn_1B",
            "parent" : {
                "$type" : "reference",
                "targetId" : "Root"
            },
            "name" : {
                "$type" : "string",
                "value" : "YMN_Box"
            },
            "position" : {
                "$type" : "float3",
                "value" : {
                    "x" : 0,
                    "y" : 1.5,
                    "z" : 10
                }
            }
        }
    }
    """

    WebSockex.cast(pid, {:send_text, msg})
  end

  # キャスト（非同期送信）の処理
  def handle_cast({:send_text, msg}, state) do
    {:reply, {:text, msg}, state}
  end

  def handle_frame({:text, msg}, state) do
    Logger.info("受信データ: #{msg}")
    {:ok, state}
  end
end
