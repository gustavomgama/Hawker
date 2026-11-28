# Upgrade Ruby, Rails and gems to latest stable

## Goal
Ruby 3.4.5 -> 4.0.10, Rails 8.0.2.1 -> 8.1.4.1, every gem in Gemfile.lock at its newest release.

## Non-goals
- No new gems, no Node/.node-version changes, no feature work.
- No change to app behaviour beyond what Rails 8.1 defaults require.

## Acceptance checks
- `ruby bin/rails runner "puts Rails.version"` prints `8.1.4.1`
- `bundle outdated --only-explicit` reports no outdated gems
- `bin/rubocop` and `bin/brakeman --no-pager` pass
- `ruby bin/rails zeitwerk:check` reports all files eager load

## Files expected to change
- `.ruby-version`, `Gemfile`, `Gemfile.lock`, `Dockerfile`
- `config/application.rb` plus files touched by `bin/rails app:update`

## Risks
- Ruby 4.0 is new; native gems (pg) must resolve to a binary for x64-mingw-ucrt.
- Rails 8.1 defaults can change behaviour; verified only by boot + static checks (no test suite exists).
