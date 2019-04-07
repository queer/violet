defmodule Violet do
  @moduledoc """
  TODO: Fill this out someday...
  """
  require Logger

  @version Mix.Project.config[:version]

  def version, do: @version

  @doc """
  Gets the etcd URL from configs.

  Example: `http://localhost:2379`
  """
  def etcd_url do
    configured = Application.get_env(:violet, :etcd)[:url]
    env = System.get_env "ETCD_URL"
    cond do
      configured != nil ->
        configured
      env != nil ->
        env
      true ->
        raise "No etcd url available (none configured, none in env)"
    end
  end

  @doc """
  etcd API base URL
  """
  def etcd_api do
    etcd_url() <> "/v2"
  end

  @doc """
  etcd API keys base URL
  """
  def etcd_keys do
    etcd_api() <> "/keys"
  end

  @doc """
  Returns whether or not the given etcd API output is an error, ie. if it has
  an `errorCode` field.
  """
  def is_error?(body) do
    not is_nil(body["errorCode"]) or not is_nil(body[:errorCode])
  end

  @doc """
  Returns the version info about the etcd cluster as a map
  """
  def get_version do
    "#{etcd_url()}/version"
    |> HTTPoison.get
    |> decode_response
  end

  @doc """
  Creates the named etcd directory
  """
  def make_dir(dir) do
    "#{etcd_keys()}/#{dir}"
    |> put("dir=true")
    |> decode_response
  end

  @doc """
  Lists the nodes of the named etcd directory.

  Conveniently, each node has both the key AND the value. This data structure
  looks something like

      "nodes": [
        {
          "key": "/foo_dir",
          "dir": true,
          "modifiedIndex": 2,
          "createdIndex": 2
        },
        {
          "key": "/foo",
          "value": "two",
          "modifiedIndex": 1,
          "createdIndex": 1
        }
      ]
  """
  def list_dir(dir) do
    "#{etcd_keys()}/#{dir}"
    |> HTTPoison.get!
    |> decode_response
    |> Access.get("node")
    |> Access.get("nodes")
  end

  @doc """
  Sets the named key to the given value
  """
  def set(key, value) do
    "#{etcd_keys()}/#{key}"
    |> put("value=#{value}")
  end

  @doc """
  Set the named key to the given value in the named dir
  """
  def set(dir, key, value) do
    "#{etcd_keys()}/#{dir}/#{key}"
    |> put("value=#{value}")
  end

  @doc """
  Gets the node info of the named key
  """
  def get(key) do
    "#{etcd_keys()}/#{key}"
    |> HTTPoison.get!
    |> decode_response
  end

  @doc """
  Deletes the named key from etcd. Assumes a / at the start of the key.
  """
  def delete(key) do
    "#{etcd_keys()}#{key}"
    |> HTTPoison.delete!
    |> decode_response
  end

  @doc """
  Convenience method for deleting from a dir.
  """
  def delete(dir, key) do
    "#{etcd_keys()}/#{dir}/#{key}"
    |> HTTPoison.delete!
    |> decode_response
  end

  @doc """
  Recursively delete a dir
  """
  def recursive_delete(dir) do
    "#{etcd_keys()}/#{dir}?recursive=true"
    |> HTTPoison.delete!
    |> decode_response
  end

  @doc """
  Gets the value at the named key. This is NOT the same as `get/1`!
  """
  def get_value(key) do
    key
    |> get
    |> Access.get("node")
    |> Access.get("value")
  end

  defp put(url, data) do
    HTTPoison.put! url, [
      body: data,
      headers: [
        "User-Agent": "violet #{@version} (https://github.com/queer/violet)",
        "Content-Type": "application/x-www-form-urlencoded"
      ]
    ]
  end

  defp decode_response(res) do
    res
    |> decode_response
  end

  @spec stats() :: %{leader: map(), self: map(), store: map()}
  def stats do
    leader =
      "#{etcd_api()}/stats/leader"
      |> HTTPoison.get!
      |> decode_response
    self =
      "#{etcd_api()}/stats/self"
      |> HTTPoison.get!
      |> decode_response
    store =
      "#{etcd_api()}/stats/store"
      |> HTTPoison.get!
      |> decode_response
    %{
      leader: leader,
      self: self,
      store: store,
    }
  end
end
