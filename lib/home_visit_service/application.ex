defmodule HomeVisitService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HomeVisitServiceWeb.Telemetry,
      # Start the Ecto repository
      HomeVisitService.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: HomeVisitService.PubSub},
      # Start Finch
      {Finch, name: HomeVisitService.Finch},
      # Start the Endpoint (http/https)
      HomeVisitServiceWeb.Endpoint
      # Start a worker by calling: HomeVisitService.Worker.start_link(arg)
      # {HomeVisitService.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeVisitService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HomeVisitServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
