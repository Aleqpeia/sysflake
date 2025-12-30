# Phase 3: Monitoring Infrastructure
#
# This directory contains the monitoring stack for tracking syscfg
# status across all machines. Run this on one machine (e.g., proxima)
# that acts as the monitoring hub.
#
# Architecture:
#   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
#   │   altair    │     │   proxima   │     │    vega     │
#   │  (NixOS)    │     │  (Fedora)   │     │  (Remote)   │
#   └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
#          │                   │                   │
#          │ status.json       │ status.json       │ status.json
#          │                   │                   │
#          └───────────────────┼───────────────────┘
#                              │
#                              ▼
#                    ┌─────────────────┐
#                    │ Status Receiver │
#                    │    (Go/Python)  │
#                    └────────┬────────┘
#                             │
#                             ▼
#                    ┌─────────────────┐
#                    │   Prometheus    │
#                    └────────┬────────┘
#                             │
#                             ▼
#                    ┌─────────────────┐
#                    │    Grafana      │
#                    └─────────────────┘
#
# Simpler alternative (for personal use):
#   - Just sync status.json files to a shared location
#   - Simple web dashboard reads them directly
#
# Even simpler:
#   - registry.py status --json from each machine
#   - Aggregate manually when needed
