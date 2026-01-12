defmodule Rect01 do
  use WebSockex
  require Logger

  @port 57374
  @host "127.0.0.1"

  def start_link(_opts \\ []) do
    WebSockex.start_link("ws://#{@host}:#{@port}", __MODULE__, :no_state,
      extra_headers: [
        {"Host", "#{@host}:#{@port}"}
      ]
    )
  end

  def handle_connect(_conn, state) do
    Logger.info("ResoniteLinkに接続成功！")
    {:ok, state}
  end

  def start() do
    {:ok, pid} = start_link()
    add_slot(pid)
    add_box_mesh(pid)
    add_pbs_metallic(pid)
    add_mesh_renderer(pid)
    update_mesh_renderer(pid)
    update_mesh_renderer(pid)
  end

  def send_text(msg, pid) do
    WebSockex.cast(pid, {:send_text, msg})
    #Process.sleep(1000)
  end

  def add_slot(pid) do
    """
    {
      "$type" : "addSlot",
      "data" : {
          "id" : "ymn_1",
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
    |> send_text(pid)
  end

  def add_box_mesh(pid) do
    """
    {
      "$type" : "addComponent",
      "containerSlotId" : "ymn_1",
      "data" : {
          "id" : "ymn_2",
          "componentType" : "[FrooxEngine]FrooxEngine.BoxMesh"
      }
    }
    """
    |> send_text(pid)
  end

  def add_pbs_metallic(pid) do
    """
    {
        "$type" : "addComponent",
        "containerSlotId" : "ymn_1",
        "data" : {
            "id" : "ymn_3",
            "componentType" : "[FrooxEngine]FrooxEngine.PBS_Metallic"
        }
    }
    """
    |> send_text(pid)
  end

  def add_mesh_renderer(pid) do
    """
    {
        "$type" : "addComponent",
        "containerSlotId" : "ymn_1",
        "data" : {
            "id" : "ymn_4",
            "componentType" : "[FrooxEngine]FrooxEngine.MeshRenderer",
            "members": {
                "Mesh": {
                    "$type": "reference",
                    "targetId": "ymn_2"
                }
            }
        }
    }
    """
    |> send_text(pid)
  end

  def update_mesh_renderer(pid) do
    """
    {
        "$type" : "updateComponent",
        "data" : {
            "id" : "ymn_4",
            "members" : {
                "Materials": {
                    "$type": "list",
                    "elements": [
                        {
                            "$type": "reference",
                            "targetId": "ymn_3"
                        }
                    ]
                }
            }
        }
    }
    """
    |> send_text(pid)
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
