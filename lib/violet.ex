defmodule Violet do
  @moduledoc """
  Documentation for Violet.
  """

  @doc """
  Gets the etcd URL from the environment, or just localhost:2379 if `ETCD_URL`
  is not set.
  """
  def etcd_url do
    case System.get_env "ETCD_URL" do
      nil -> "http://localhost:2379"
      _ -> System.get_env "ETCD_URL"
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
    case body[:errorCode] do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Returns the version info about the etcd cluster as a map
  """
  def get_version do
    etcd_res = "#{etcd_url()}/version"
               |> HTTPotion.get
    Poison.decode!(etcd_res.body)
  end

  @doc """
  Creates the named etcd directory
  """
  def make_dir(dir) do
    res = put "#{etcd_keys()}/#{dir}", "dir=true"
    Poison.decode! res.body
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
    res = HTTPotion.get "#{etcd_keys()}/#{dir}"
    (Poison.decode! res.body)["node"]["nodes"]
  end

  @doc """
  Sets the named key to the given value
  """
  def set(key, value) do
    put "#{etcd_keys()}/#{key}", "value=#{value}"
  end

  @doc """
  Set the named key to the given value in the named dir
  """
  def set(dir, key, value) do
    put "#{etcd_keys()}/#{dir}/#{key}", "value=#{value}"
  end

  @doc """
  Gets the node info of the named key
  """
  def get(key) do
    res = HTTPotion.get "#{etcd_keys()}/#{key}"
    Poison.decode! res.body
  end

  @doc """
  Deletes the named key from etcd. Assumes a / at the start of the key.
  """
  def delete(key) do
    res = HTTPotion.delete "#{etcd_keys()}#{key}"
    Poison.decode! res.body
  end

  @doc """
  Convenience method for deleting from a dir.
  """
  def delete(dir, key) do
    res = HTTPotion.delete "#{etcd_keys()}/#{dir}/#{key}"
    Poison.decode! res.body
  end

  @doc """
  Gets the value at the named key. This is NOT the same as `get/1`!
  """
  def get_value(key) do
    get(key)["node"]["value"]
  end

  defp put(url, data) do
    HTTPotion.put url, [body: data, headers: ["User-Agent": "violet", "Content-Type": "application/x-www-form-urlencoded"]]
  end
end
