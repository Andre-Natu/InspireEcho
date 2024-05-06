defmodule Citacoes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CitacoesWeb.Telemetry,
      Citacoes.Repo,
      {DNSCluster, query: Application.get_env(:citacoes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Citacoes.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Citacoes.Finch},
      # Start a worker by calling: Citacoes.Worker.start_link(arg)
      # {Citacoes.Worker, arg},
      # Start to serve requests, typically the last entry
      CitacoesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Citacoes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CitacoesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
