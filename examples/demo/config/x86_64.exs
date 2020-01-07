use Mix.Config

config :nerves, :firmware, fwup_conf: "config/fwup-x86_64.conf"

config :nerves, :erlinit, ctty: "ttyS0"
