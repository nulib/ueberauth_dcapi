defmodule MockAPI do
  @moduledoc """
  Mock responses for DC API tests
  """
  alias Req.{Request, Response}

  @test_base Application.compile_env(:ueberauth, Ueberauth)
             |> get_in([:providers, :dcapi, Access.elem(1), :base_url])
  @whoami URI.parse(@test_base) |> URI.merge("auth/whoami")

  def run(request), do: {request, response(request)}

  def response(%Request{url: @whoami, options: %{auth: {:bearer, token}}}), do: whoami(token)
  def response(_), do: Response.new(status: 500, body: "Unexpected Request")

  def whoami("valid-token") do
    Response.new(
      status: 200,
      body:
        Jason.encode!(%{
          iss: @test_base,
          exp: 1_696_050_451,
          iat: 1_696_007_251,
          isLoggedIn: true,
          sub: "abc123",
          name: "Archie B. Charles",
          email: "archie.charles@example.edu"
        })
    )
    |> Response.put_header("content-type", "application/json; charset=UTF-8")
  end

  def whoami("not-a-valid-token") do
    Response.new(
      status: 200,
      body:
        Jason.encode!(%{
          iss: @test_base,
          exp: 1_696_060_752,
          iat: 1_696_017_552,
          isLoggedIn: false
        })
    )
    |> Response.put_header("content-type", "application/json; charset=UTF-8")
  end

  def whoami("server-error"), do: Response.new(status: 500, body: ~s'"Server Error"')

  def whoami("network-error"), do: Mint.TransportError.exception(reason: :nxdomain)
end
