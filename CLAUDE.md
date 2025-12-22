# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Carbonation Labs is a Rails 8 application for experiments with Fizzy (fizzy.do) kanban board integration. Each experiment ("lab") lives in its own controller and uses LLM-powered features via OpenRouter.

## Commands

```bash
# Run all tests
mise exec -- bin/rails test

# Run a single test file
mise exec -- bin/rails test test/controllers/board_bootstrap_controller_test.rb

# Run a specific test by line number
mise exec -- bin/rails test test/models/board_bootstrap_test.rb:21

# Start development server
mise exec -- bin/rails server

# Linting
mise exec -- bin/rubocop
mise exec -- bin/brakeman
```

## Environment Setup

Copy `.env.example` to `.env` and fill in:
- `FIZZY_API_TOKEN` and `FIZZY_ACCOUNT_SLUG` - from https://fizzy.do/settings/api
- `OPENROUTER_API_KEY` - from https://openrouter.ai/keys

Tests use stub values for all API credentials (set in `test/test_helper.rb`).

## Architecture

### Labs Pattern
Labs are listed in `LabsController::LABS` constant. Each lab:
- Has its own controller (`app/controllers/{lab}_controller.rb`)
- Uses singular resource routes with explicit controller: `resource :board_bootstrap, controller: "board_bootstrap"`
- May have a non-ActiveRecord model for form handling and business logic

### External Integrations
- **Fizzy API**: `FizzyApiClient::Client` for creating boards/columns. Returns Hashes, not objects (use `board["id"]` not `board.id`).
- **LLM**: `RubyLLM.chat(model: "anthropic/claude-sonnet-4.5", provider: :openrouter)` for AI features.

### Multi-step Form Flows
For Turbo-compatible multi-step flows, store intermediate state in `session` and redirect between steps rather than rendering directly after POST.

## Code Style

Follow the conventions in [STYLE.md](STYLE.md) (from Fizzy/37signals). Key points:
- Prefer expanded conditionals over guard clauses
- Order methods by invocation order
- Indent private methods under `private` with no newline after the modifier
- Model endpoints as CRUD on resources; introduce new resources instead of custom actions
- Thin controllers with rich domain models (vanilla Rails)
