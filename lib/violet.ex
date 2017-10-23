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
    etcd_res = etcd_url() <> "/version"
               |> HTTPotion.get
    Poison.decode!(etcd_res.body)
  end

  @doc """
  Creates the named etcd directory
  """
  def make_dir(dir) do
    res = HTTPotion.put etcd_api() <> "/keys/" <> dir, [body: "dir=true"]
    Poison.decode! res.body
  end

  @doc """
  Lists the nodes of the named etcd directory
  """
  def list_dir(dir) do
    res = HTTPotion.get etcd_api() <> "/keys/" <> dir
    Poison.decode! res.body
  end

  defp handle_encode(data) do
    unless is_binary data do
      Poison.encode! data
    else
      data
    end
  end

  @doc """
  Sets the named key to the given value
  """
  def set(key, value) do
    HTTPotion.put etcd_api() <> "/keys/" <> key, [body: "value=#{inspect handle_encode(value)}"]
  end

  @doc """
  Gets the node info of the named key
  """
  def get(key) do
    res = HTTPotion.get etcd_api() <> "/keys/" <> key
    Poison.decode! res.body
  end

  @doc """
  Gets the value at the named key. This is NOT the same as `get/1`!
  """
  def get_value(key) do
    get(key)["node"]["value"]
  end
end
