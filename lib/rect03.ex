defmodule Rect03 do
  # AIで生成する(失敗作)
  use WebSockex
  require Logger

  @port 17831
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

    run_ollama()
    |> Enum.each(fn [x, y, z] -> box(pid, x, y, z) end)

    Process.sleep(1000)
  end

  def box(pid, x, y, z) do
    id = :rand.uniform(1_000_0000)
    add_slot(pid, id, x, y, z)
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

  def add_slot(pid, id, x, y, z) do
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
                  "x" : #{x},
                  "y" : #{y},
                  "z" : #{z}
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

  def run_ollama() do
    text =
      """
        指示: 星の形状を構成する3D座標データを作成してください。

        厳守ルール:

        出力は [[x, y, z], [x, y, z], ...] という形式の多次元配列のみとすること。

        自然言語による解説、部位の説明、挨拶、コードブロックのラベル（```json 等）は一切禁止します。

        最初の文字は [ で始め、最後の文字は ] で終わること。
        座標は整数値で1〜50は許可
        座標点数は80点以上出してください

      """

    client = Ollama.init(receive_timeout: 300_000)

    Ollama.completion(client,
      model: "gpt-oss:20b",
      prompt: text,
      stream: false
    )
    |> elem(1)
    |> Map.get("response")
    |> Jason.decode!()
    |> IO.inspect()
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
