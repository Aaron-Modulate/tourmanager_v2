#!/bin/bash
cd "$(dirname "$0")/.." && mix ecto.migrate && mix ecto.gen.erd --output-path docs/schema.mmd
