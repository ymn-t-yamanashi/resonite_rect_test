defmodule Rect02 do
  # Boxをランダムで1000個作る
  use WebSockex
  require Logger

  @port 55497
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
    Enum.each(1..1000, fn _ -> box(pid) end)
    Process.sleep(1000)
  end

  def box(pid) do
    id = :rand.uniform(1_000_0000)
    add_slot(pid, id)
    add_box_mesh(pid, id)
    add_pbs_metallic(pid, id)
    add_mesh_renderer(pid, id)
    update_mesh_renderer(pid, id)
    update_mesh_renderer(pid, id)
  end

  def send_text(msg, pid) do
    WebSockex.cast(pid, {:send_text, msg})
    # Process.sleep(1000)
  end

  def add_slot(pid, id) do
    """
    {
      "$type" : "addSlot",
      "data" : {
          "id" : "ymn_1_#{id}",
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
                  "x" : #{Enum.random(1..20)},
                  "y" : #{Enum.random(1..20)},
                  "z" : #{Enum.random(1..20)}
              }
          }
      }
    }
    """
    |> send_text(pid)
  end

  def add_box_mesh(pid, id) do
    """
    {
      "$type" : "addComponent",
      "containerSlotId" : "ymn_1_#{id}",
      "data" : {
          "id" : "ymn_2_#{id}",
          "componentType" : "[FrooxEngine]FrooxEngine.BoxMesh"
      }
    }
    """
    |> send_text(pid)
  end

  def add_pbs_metallic(pid, id) do
    """
    {
        "$type" : "addComponent",
        "containerSlotId" : "ymn_1_#{id}",
        "data" : {
            "id" : "ymn_3_#{id}",
            "componentType" : "[FrooxEngine]FrooxEngine.PBS_Metallic"
        }
    }
    """
    |> send_text(pid)
  end

  def add_mesh_renderer(pid, id) do
    """
    {
        "$type" : "addComponent",
        "containerSlotId" : "ymn_1_#{id}",
        "data" : {
            "id" : "ymn_4_#{id}",
            "componentType" : "[FrooxEngine]FrooxEngine.MeshRenderer",
            "members": {
                "Mesh": {
                    "$type": "reference",
                    "targetId": "ymn_2_#{id}"
                }
            }
        }
    }
    """
    |> send_text(pid)
  end

  def update_mesh_renderer(pid, id) do
    """
    {
        "$type" : "updateComponent",
        "data" : {
            "id" : "ymn_4_#{id}",
            "members" : {
                "Materials": {
                    "$type": "list",
                    "elements": [
                        {
                            "$type": "reference",
                            "targetId": "ymn_3_#{id}"
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
